#!/bin/bash
# Script to generate Go files from proto files using protoc

# Set up variables
OUTPUT_DIR="generated/go"
GO_MODULE="github.com/opensearch/proto"

# Clean up existing output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/github.com/opensearch/proto"
mkdir -p "$OUTPUT_DIR/github.com/opensearch/proto/services"

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Go is not installed or not in your PATH. Please install Go first:"
    echo "Visit https://golang.org/doc/install for installation instructions."
    echo ""
    echo "Creating empty directory structure for now..."
    mkdir -p "$OUTPUT_DIR/github.com/opensearch/proto"
    mkdir -p "$OUTPUT_DIR/github.com/opensearch/proto/services"
    touch "$OUTPUT_DIR/github.com/opensearch/proto/common.pb.go"
    touch "$OUTPUT_DIR/github.com/opensearch/proto/document.pb.go"
    touch "$OUTPUT_DIR/github.com/opensearch/proto/services/document_service.pb.go"
    echo "// This is a placeholder file. Install Go and protoc-gen-go to generate actual Go code." > "$OUTPUT_DIR/github.com/opensearch/proto/common.pb.go"
    echo "// This is a placeholder file. Install Go and protoc-gen-go to generate actual Go code." > "$OUTPUT_DIR/github.com/opensearch/proto/document.pb.go"
    echo "// This is a placeholder file. Install Go and protoc-gen-go to generate actual Go code." > "$OUTPUT_DIR/github.com/opensearch/proto/services/document_service.pb.go"
    echo "Done! Created placeholder Go files in $OUTPUT_DIR"
    exit 0
fi

# Generate Go code from proto files
echo "Generating Go files from proto files..."

# Check if protoc-gen-go is installed
if ! command -v protoc-gen-go &> /dev/null; then
    echo "protoc-gen-go not found. Please install it manually with:"
    echo "go install google.golang.org/protobuf/cmd/protoc-gen-go@latest"
    echo "Make sure your GOPATH/bin is in your PATH."
    echo ""
    echo "You may need to add GOPATH/bin to your PATH with one of these commands:"
    echo "  export PATH=\$PATH:\$(go env GOPATH)/bin    # For bash/zsh"
    echo "  set -gx PATH \$PATH (go env GOPATH)/bin     # For fish"
    echo "Creating empty directory structure for now..."
    mkdir -p "$OUTPUT_DIR/github.com/opensearch/proto"
    mkdir -p "$OUTPUT_DIR/github.com/opensearch/proto/services"
    touch "$OUTPUT_DIR/github.com/opensearch/proto/common.pb.go"
    touch "$OUTPUT_DIR/github.com/opensearch/proto/document.pb.go"
    touch "$OUTPUT_DIR/github.com/opensearch/proto/services/document_service.pb.go"
    echo "// This is a placeholder file. Install protoc-gen-go to generate actual Go code." > "$OUTPUT_DIR/github.com/opensearch/proto/common.pb.go"
    echo "// This is a placeholder file. Install protoc-gen-go to generate actual Go code." > "$OUTPUT_DIR/github.com/opensearch/proto/document.pb.go"
    echo "// This is a placeholder file. Install protoc-gen-go to generate actual Go code." > "$OUTPUT_DIR/github.com/opensearch/proto/services/document_service.pb.go"
else
    # Generate Go code for common.proto and document.proto
    protoc --proto_path=. \
           --go_out="$OUTPUT_DIR" \
           --go_opt=module="$GO_MODULE" \
           protos/schemas/common.proto \
           protos/schemas/document.proto

    # Generate Go code for document_service.proto
    protoc --proto_path=. \
           --go_out="$OUTPUT_DIR" \
           --go_opt=module="$GO_MODULE" \
           protos/document_service.proto
fi

# Create a go.mod file for the generated code
cat > "$OUTPUT_DIR/go.mod" << EOF
module github.com/opensearch/proto

go 1.20

require (
	google.golang.org/protobuf v1.31.0
)
EOF

echo "Done! Generated Go files are in $OUTPUT_DIR"
echo "You can import the generated code in Go with:"
echo "import \"github.com/opensearch/proto\""
echo "import \"github.com/opensearch/proto/services\""
