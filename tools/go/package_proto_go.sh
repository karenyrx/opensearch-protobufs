#!/bin/bash
# Script to package generated Go proto files into a tarball
set -e

# Configuration
ROOT_DIR="`dirname "$(realpath $0)"`/../.."
OUTPUT_DIR_ROOT="$ROOT_DIR/generated"
OUTPUT_DIR_GO="$OUTPUT_DIR_ROOT/go"

# Parameters
function usage() {
    echo "Usage: $0 [args]"
    echo ""
    echo "Arguments:"
    echo -e "-c CLEAN_GENERATED\t[Optional] default to 'false', set to 'true' will remove existing generated files"
    echo -e "-h help"
}

CLEAN_GENERATED='false'

while getopts "c:h" opt; do
  case $opt in
    h)
      usage
      exit 1
      ;;
    c)
      CLEAN_GENERATED="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ "$CLEAN_GENERATED" = "true" ]; then
    echo "Cleanup $OUTPUT_DIR_ROOT"
    rm -rf "$OUTPUT_DIR_ROOT"
fi

# Create output directories
mkdir -p "$OUTPUT_DIR_GO/opensearchpb"
mkdir -p "$OUTPUT_DIR_GO/services"

echo "Building Go protos with Bazel..."
cd "$ROOT_DIR"
bazel build //:go_protos_all

echo "Copying generated Go files..."
# Copy schema proto files (opensearchpb package)
find bazel-bin/protos/schemas -name "*.pb.go" -path "*_go_proto_*" -not -name "*_grpc.pb.go" -exec cp {} "$OUTPUT_DIR_GO/opensearchpb/" \;

# Copy service proto files (services package)
find bazel-bin/protos/services -name "*.pb.go" -path "*_go_proto_*" -not -name "*_grpc.pb.go" -exec cp {} "$OUTPUT_DIR_GO/services/" \;
find bazel-bin/protos/services -name "*_grpc.pb.go" -path "*_go_proto_*" -exec cp {} "$OUTPUT_DIR_GO/services/" \;

echo "Fixing import paths..."
# Fix import paths in opensearchpb package files
# For files in opensearchpb, we need to remove imports of the same package and remove the alias prefix
for file in "$OUTPUT_DIR_GO/opensearchpb"/*.pb.go; do
    # First replace the bazel-style import paths with the proper module paths
    sed -i \
        -e 's|protos/schemas/common_go_proto|github.com/opensearch-project/opensearch-protobufs/go/opensearchpb|g' \
        -e 's|protos/schemas/document_go_proto|github.com/opensearch-project/opensearch-protobufs/go/opensearchpb|g' \
        -e 's|protos/schemas/search_go_proto|github.com/opensearch-project/opensearch-protobufs/go/opensearchpb|g' \
        "$file"

    # Remove import lines for the same package (these create import cycles)
    # These must be removed AFTER path replacement
    sed -i '/common_go_proto "github.com\/opensearch-project\/opensearch-protobufs\/go\/opensearchpb"/d' "$file"
    sed -i '/document_go_proto "github.com\/opensearch-project\/opensearch-protobufs\/go\/opensearchpb"/d' "$file"
    sed -i '/search_go_proto "github.com\/opensearch-project\/opensearch-protobufs\/go\/opensearchpb"/d' "$file"

    # Remove the alias prefix from type references within the same package
    sed -i \
        -e 's|common_go_proto\.||g' \
        -e 's|document_go_proto\.||g' \
        -e 's|search_go_proto\.||g' \
        "$file"
done

# Fix import paths in services package files
for file in "$OUTPUT_DIR_GO/services"/*.pb.go; do
    sed -i \
        -e 's|protos/schemas/common_go_proto|github.com/opensearch-project/opensearch-protobufs/go/opensearchpb|g' \
        -e 's|protos/schemas/document_go_proto|github.com/opensearch-project/opensearch-protobufs/go/opensearchpb|g' \
        -e 's|protos/schemas/search_go_proto|github.com/opensearch-project/opensearch-protobufs/go/opensearchpb|g' \
        -e 's|protos/services/document_service_go_proto|github.com/opensearch-project/opensearch-protobufs/go/services|g' \
        -e 's|protos/services/search_service_go_proto|github.com/opensearch-project/opensearch-protobufs/go/services|g' \
        "$file"

    # Update the import aliases to use proper names
    sed -i \
        -e 's|common_go_proto "github.com/opensearch-project/opensearch-protobufs/go/opensearchpb"|opensearchpb "github.com/opensearch-project/opensearch-protobufs/go/opensearchpb"|g' \
        -e 's|document_go_proto "github.com/opensearch-project/opensearch-protobufs/go/opensearchpb"|opensearchpb "github.com/opensearch-project/opensearch-protobufs/go/opensearchpb"|g' \
        -e 's|search_go_proto "github.com/opensearch-project/opensearch-protobufs/go/opensearchpb"|opensearchpb "github.com/opensearch-project/opensearch-protobufs/go/opensearchpb"|g' \
        "$file"

    # Update type references to use the proper alias
    sed -i \
        -e 's|common_go_proto\.|opensearchpb.|g' \
        -e 's|document_go_proto\.|opensearchpb.|g' \
        -e 's|search_go_proto\.|opensearchpb.|g' \
        "$file"
done

echo "Creating go.mod file..."
# Read version from version.properties
VERSION=$(cat "$ROOT_DIR/version.properties")

cat > "$OUTPUT_DIR_GO/go.mod" <<EOF
module github.com/opensearch-project/opensearch-protobufs/go

go 1.19

require (
	google.golang.org/protobuf v1.31.0
	google.golang.org/grpc v1.58.0
)
EOF

echo "Creating README.md..."
cat > "$OUTPUT_DIR_GO/README.md" <<EOF
# OpenSearch Protocol Buffers - Go

This package contains the Go client libraries generated from OpenSearch Protocol Buffer definitions.

## Version

$VERSION

## Installation

\`\`\`bash
go get github.com/opensearch-project/opensearch-protobufs/go@v$VERSION
\`\`\`

## Usage

\`\`\`go
import (
    "github.com/opensearch-project/opensearch-protobufs/go/opensearchpb"
    "github.com/opensearch-project/opensearch-protobufs/go/services"
)

// Use generated message types
request := &opensearchpb.SearchRequest{
    Query: "elasticsearch",
    Size:  10,
}

// Use generated gRPC clients
client := services.NewSearchServiceClient(conn)
response, err := client.Search(ctx, request)
\`\`\`

## Documentation

For more information, see the [OpenSearch Protobufs repository](https://github.com/opensearch-project/opensearch-protobufs).

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.
EOF

# Copy LICENSE
if [ -f "$ROOT_DIR/LICENSE.txt" ]; then
    cp "$ROOT_DIR/LICENSE.txt" "$OUTPUT_DIR_GO/LICENSE"
fi

# Copy NOTICE
if [ -f "$ROOT_DIR/NOTICE.txt" ]; then
    cp "$ROOT_DIR/NOTICE.txt" "$OUTPUT_DIR_GO/NOTICE"
fi

echo "Validating Go code..."
cd "$OUTPUT_DIR_GO"
go mod tidy
go build ./...

echo "Go proto packaging complete!"
echo "Output directory: $OUTPUT_DIR_GO"

# List generated files
echo ""
echo "Generated files:"
find "$OUTPUT_DIR_GO" -type f | sort
