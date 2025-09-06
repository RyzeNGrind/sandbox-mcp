#!/usr/bin/env bash
# Build script for sandbox-mcp
set -euo pipefail

# Build configuration
BUILD_DIR="${BUILD_DIR:-./bin}"
VERSION="${VERSION:-dev}"
COMMIT_SHA="${COMMIT_SHA:-unknown}"

# Create build directory
mkdir -p "$BUILD_DIR"

# Build flags
LDFLAGS=(
    "-s" "-w"
    "-X github.com/pottekkat/sandbox-mcp/internal/version.Version=$VERSION"
    "-X github.com/pottekkat/sandbox-mcp/internal/version.CommitSHA=$COMMIT_SHA"
)

echo "Building sandbox-mcp..."
echo "Version: $VERSION"
echo "Commit: $COMMIT_SHA"
echo "Output: $BUILD_DIR/sandbox-mcp"

# Build the application
go build -ldflags "${LDFLAGS[*]}" -o "$BUILD_DIR/sandbox-mcp" ./cmd/sandbox-mcp

echo "Build completed successfully!"
echo "Run: $BUILD_DIR/sandbox-mcp --help"