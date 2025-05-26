#!/bin/bash
# set -vex 

# Check for required tools
check_requirements() {
  echo "Checking for required tools..."
  
  # Check for grpcurl
  if ! command -v grpcurl &> /dev/null; then
    echo "grpcurl is not installed. Please install it with the following command:"
    echo "curl -sSL \"https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_linux_x86_64.tar.gz\" | sudo tar -xz -C /usr/local/bin"
    exit 1
  fi
  
  echo "All required tools are installed."
  echo "----------------------------------------"
}

# Function to run a single trial and record results
run_trial() {
  version=$1
  trial_num=$2
  
  echo "Running trial $trial_num for version: $version"
  
  # Start timing
  start_time=$(date +"%T.%N")
  
  # Run the grpcurl command
  grpcurl -import-path ~/OpenSearch -d '{"size": 10000, "request_body":{"query":{"match_all":{}}}}' \
    -proto ~/OpenSearch/protos/services/search_service.proto -plaintext \
    localhost:9400 org.opensearch.protobufs.services.SearchService/Search > "out_${version}_${trial_num}.txt"
  
  # End timing
  end_time=$(date +"%T.%N")
  
  # Record the times
  echo "$start_time" > "time_${version}_${trial_num}_start.txt"
  echo "$end_time" > "time_${version}_${trial_num}_end.txt"
  
  # Calculate and display duration
  start_seconds=$(date -d "$start_time" +%s.%N)
  end_seconds=$(date -d "$end_time" +%s.%N)
  duration=$(awk "BEGIN {print $end_seconds - $start_seconds}")
  echo "Duration for $version trial $trial_num: $duration seconds"
  echo "$duration" > "duration_${version}_${trial_num}.txt"
  
  echo "Trial $trial_num for $version completed"
  echo "----------------------------------------"
}

# Function to build and deploy a version
build_and_deploy() {
  version=$1
  
  echo "Building version: $version"
  
  # Clean and build
  # Uncomment the following lines if you need to build from source
  cd ~/opensearch-protobufs
  rm -rf generated
  bazel build //...  > bazel-build-${version}.log
  ./tools/java/package_proto_jar.sh > package_proto_jar-${version}.log
  
  # Copy to OpenSearch folder
  # mkdir -p ~/OpenSearch/
  cp generated/maven/protobufs-0.4.0-SNAPSHOT.jar ~/OpenSearch/protobufs-${version}.jar
  
  # Copy proto schema and service folders to ~/OpenSearch
  mkdir -p ~/OpenSearch/protos/schemas/ ~/OpenSearch/protos/services/
  cp -r protos/schemas/* ~/OpenSearch/protos/schemas/
  cp -r protos/services/* ~/OpenSearch/protos/services/
  
  echo "Built and deployed version: $version"
  echo "----------------------------------------"
}

# Function to prepare for testing and ingest data
prepare_and_ingest() {
  version=$1
  
  echo "Preparing for testing with version: $version"
  
  # Copy the appropriate jar to the expected location
  cp ~/OpenSearch/protobufs-${version}.jar ~/OpenSearch/protobufs-0.4.0-SNAPSHOT.jar
  
  echo "Please start OpenSearch manually in a separate terminal with the following command:"
  echo "cd ~/OpenSearch && export JAVA_HOME=/opt/jvm/jdk-21 && export PATH=\$JAVA_HOME/bin:\$PATH && ./gradlew run -PinstalledPlugins=\"['transport-grpc']\" -Dtests.opensearch.aux.transport.types=\"[experimental-transport-grpc]\""
  read -p "Press Enter once OpenSearch is started and ready..."
  
  # Ingest data
  echo "Ingesting data..."
  pwd
  cd ../../OpenSearch && curl -H 'Content-type: application/x-ndjson' -XPOST 'http://localhost:9200/_bulk' --data-binary @ingest4.json > "ingestoutput_${version}.txt" && cd ../opensearch-protobufs/protobuf_performance_results/
  
  # Wait for ingestion to complete
  echo "Waiting for ingestion to complete..."
  # Note: Adjust the sleep duration as needed based on your data size
  sleep 15
  
  echo "Data ingested for version: $version"
  echo "----------------------------------------"
}

# Function to prompt user to stop OpenSearch
prompt_stop_opensearch() {
  version=$1
  
  echo "Please manually stop the OpenSearch instance in the terminal before continuing."
  read -p "Press Enter when OpenSearch has been stopped..."
  echo "Continuing with tests..."
  echo "----------------------------------------"
}

# Main testing function
run_tests() {
  version=$1
  
  echo "Starting tests for version: $version"
  
  # Prepare and ingest data
  prepare_and_ingest $version
  
  # Run 5 trials
  for i in {1..5}; do
    run_trial $version $i
    sleep 5  # Brief pause between trials
  done
  
  # Prompt to stop OpenSearch
  prompt_stop_opensearch $version
  
  echo "Completed tests for version: $version"
  echo "=========================================="
}

# Function to analyze results and write to file
analyze_results() {
  # Create a results file
  results_file="performance_comparison_results.txt"
  echo "Writing results to $results_file"
  
  # Function to write to both console and file
  write_output() {
    echo "$1"
    echo "$1" >> "$results_file"
  }
  
  write_output "===== Performance Comparison Summary ====="
  write_output "$(date)"
  write_output ""
  
  # Calculate average duration for each version
  write_output "Calculating average durations..."
  
  # For "after" version
  after_total=0
  after_count=0
  for file in duration_after_*.txt; do
    if [ -f "$file" ]; then
      duration=$(cat "$file")
      after_total=$(awk "BEGIN {print $after_total + $duration}")
      after_count=$((after_count + 1))
    fi
  done
  
  if [ $after_count -gt 0 ]; then
    after_avg=$(awk "BEGIN {printf \"%.6f\", $after_total / $after_count}")
    write_output "Average duration for AFTER version: $after_avg seconds"
  else
    write_output "No data found for AFTER version"
  fi
  
  # For "before" version
  before_total=0
  before_count=0
  for file in duration_before_*.txt; do
    if [ -f "$file" ]; then
      duration=$(cat "$file")
      before_total=$(awk "BEGIN {print $before_total + $duration}")
      before_count=$((before_count + 1))
    fi
  done
  
  if [ $before_count -gt 0 ]; then
    before_avg=$(awk "BEGIN {printf \"%.6f\", $before_total / $before_count}")
    write_output "Average duration for BEFORE version: $before_avg seconds"
  else
    write_output "No data found for BEFORE version"
  fi
  
  # Compare if both versions have data
  if [ $after_count -gt 0 ] && [ $before_count -gt 0 ]; then
    diff=$(awk "BEGIN {print $before_avg - $after_avg}")
    percent=$(awk "BEGIN {printf \"%.2f\", ($diff / $before_avg) * 100}")
    
    if (( $(awk "BEGIN {print ($diff > 0) ? 1 : 0}") )); then
      write_output "The AFTER version is faster by $diff seconds ($percent% improvement)"
    elif (( $(awk "BEGIN {print ($diff < 0) ? 1 : 0}") )); then
      abs_diff=$(awk "BEGIN {print -1 * $diff}")
      abs_percent=$(awk "BEGIN {print -1 * $percent}")
      write_output "The BEFORE version is faster by $abs_diff seconds ($abs_percent% better)"
    else
      write_output "Both versions have the same performance"
    fi
  fi
  
  write_output "----------------------------------------"
  write_output "Individual trial results:"
  write_output "BEFORE version:"
  for i in {1..5}; do
    if [ -f "duration_before_$i.txt" ]; then
      duration=$(cat "duration_before_$i.txt")
      write_output "  Trial $i: $duration seconds"
    fi
  done
  
  write_output "AFTER version:"
  for i in {1..5}; do
    if [ -f "duration_after_$i.txt" ]; then
      duration=$(cat "duration_after_$i.txt")
      write_output "  Trial $i: $duration seconds"
    fi
  done
  
  write_output "=========================================="
  
  echo "Results written to $results_file"
}

# Main script execution

# Check for required tools
check_requirements

# Create results directory
mkdir -p protobuf_performance_results
cd protobuf_performance_results

# Build and test the "after" version (with your changes)
cd ..
echo "===== Testing AFTER version (with your changes) ====="
build_and_deploy "after"
cd protobuf_performance_results
run_tests "after"

# Build and test the "before" version (without your changes)
echo "===== Testing BEFORE version (without your chqanges) ====="
# git revert -n 5520c0dfac16c4ae97115827c05f7c4f41c60593 # remove objectmap
# git revert -n 2cbaac24e91c88ddac76e951379ae7a2f9b1baa9 # change objectmap to bytes
git revert -n f1c4cdc3f137bd4ac4c5dd1a0a1001c9ea9f2638 # simplify score oneof
# git revert -n eb259089cbb15377560a12cba60288e8685e04ef # shard as int

build_and_deploy "before"
cd protobuf_performance_results
run_tests "before"

# Restore to original state
cd ..
git reset --HEAD~
git stash 
git stash drop

# Analyze and summarize results
cd protobuf_performance_results
analyze_results

echo "Testing completed. Results are in the protobuf_performance_results directory."
