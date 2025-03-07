# opensearch-protobufs
# Prerequisites
Install protoc v25.1
```
PB_REL="https://github.com/protocolbuffers/protobuf/releases"
curl -LO $PB_REL/download/v25.1/protoc-25.1-linux-x86_64.zip
unzip protoc-25.1-linux-x86_64.zip -d $HOME/.local
export PATH="$PATH:$HOME/.local/bin"
```

The follow command should output `v25.1`:
```
protoc --version
```
# Compile protos
```
bazel build //...
<!-- bazel build :protos_java -->
```
# Proto generated code
## Java
### Generate Java Code
Delete generated folder:
```
rm -rf generated
```
1. Run the provided script to generate Java files from proto files:

```bash
./tools/java/generate_java.sh
```

This script will:
- Build the Java proto library using Bazel
- Find all source JAR files containing generated Java code
- Extract the Java files to the `generated/java` directory

2. You can find the generated Java files in the `generated/java` directory:
```bash
find generated/java -name "*.java" | sort
```

### Packaging as a Maven/Gradle dependency

To package the generated Java files into a Maven-compatible JAR that can be used as a Gradle dependency:

1. Run the provided script:
```bash
./tools/java/package_proto_jar.sh
```

This script will:
- Generate Java files from proto files (if not already done)
- Download the protobuf-java dependency
- Compile the Java files
- Create a Maven-compatible JAR file
- Install the JAR to your local Maven repository

2. To use the JAR in a Gradle project, add the following to your build.gradle:
```groovy
repositories {
    mavenLocal()
}

dependencies {
    implementation 'org.opensearch.protobuf:opensearch-protobuf:1.0.0'
}
```


## Python

### Generate Python Code
TODO: The script uses a raw protoc command right now. Ideally, it should use bazel in the future.

Run the provided script to generate Python files from proto files:
```bash
./tools/python/generate_python.sh
```

This script will:
- Use protoc to generate Python code from proto files
- Create the necessary directory structure with __init__.py files
- Organize the generated files in the `generated/python` directory

You can import the generated code in Python with:
```python
from org.opensearch.protobuf import common_pb2, document_pb2
from org.opensearch.protobuf.services import document_service_pb2
```

## Go

### Generate Go Code
TODO: The script uses a raw protoc command right now. Ideally, it should use bazel in the future.

Run the provided script to generate Go files from proto files:
```bash
./tools/go/generate_go.sh
```

This script will:
- Use protoc to generate Go code from proto files
- Create the necessary directory structure
- Create a go.mod file for the generated code
- Place the generated files in the `generated/go` directory

You can import the generated code in Go with:
```go
import "github.com/opensearch/proto"
import "github.com/opensearch/proto/services"
```

# Ignored files

All generated files are excluded from version control via the `.gitignore` file. This includes:
- Bazel generated files (bazel-*)
- Generated files (generated/)
- Compiled class files (*.class)
- Package files (*.jar)
