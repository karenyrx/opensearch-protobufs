#!/bin/bash
# Script to generate Python files from proto files using protoc

# Set up variables
OUTPUT_DIR="generated/python"

# Clean up existing output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Create __init__.py files to make the generated code importable
touch "$OUTPUT_DIR/__init__.py"
mkdir -p "$OUTPUT_DIR/opensearch"
touch "$OUTPUT_DIR/opensearch/__init__.py"
mkdir -p "$OUTPUT_DIR/opensearch/proto"
touch "$OUTPUT_DIR/opensearch/proto/__init__.py"
mkdir -p "$OUTPUT_DIR/opensearch/proto/services"
touch "$OUTPUT_DIR/opensearch/proto/services/__init__.py"

# Generate Python code from proto files
echo "Generating Python files from proto files..."
protoc --proto_path=. \
       --python_out="$OUTPUT_DIR" \
       protos/schemas/common.proto \
       protos/schemas/document.proto \
       protos/document_service.proto

# Move the generated files to the correct directories
echo "Organizing generated files..."
mv "$OUTPUT_DIR/protos/schemas/common_pb2.py" "$OUTPUT_DIR/opensearch/proto/"
mv "$OUTPUT_DIR/protos/schemas/document_pb2.py" "$OUTPUT_DIR/opensearch/proto/"
mv "$OUTPUT_DIR/protos/document_service_pb2.py" "$OUTPUT_DIR/opensearch/proto/services/"

# Clean up temporary directories
rm -rf "$OUTPUT_DIR/protos"

echo "Done! Generated Python files are in $OUTPUT_DIR"
echo "You can import the generated code in Python with:"
echo "from opensearch.proto import common_pb2, document_pb2"
echo "from opensearch.proto.services import document_service_pb2"
