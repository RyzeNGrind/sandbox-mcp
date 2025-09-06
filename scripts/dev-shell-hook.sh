#!/usr/bin/env bash
# Development shell initialization script for sandbox-mcp

echo "Nix-native sandbox-mcp development environment"
echo "Available commands:"
echo "  go build ./cmd/sandbox-mcp     - Build the application"
echo "  nix build                      - Build with Nix"
echo "  nix develop                    - Enter development shell"
echo "  nix build .#example-config     - Build example MCP configuration"