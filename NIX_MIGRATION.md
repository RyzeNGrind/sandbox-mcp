# Nix-Native Sandbox MCP Migration

This document describes the migration from Docker-based sandboxing to Nix-native sandboxing.

## Overview

The sandbox-mcp has been converted from using Docker containers to Nix-native sandboxing, providing:

- **Better Reproducibility**: Nix ensures exact package versions and dependencies
- **Stronger Isolation**: Native Linux namespaces and chroot provide container-level isolation
- **No Docker Dependency**: Runs without requiring Docker daemon
- **Faster Execution**: No container startup overhead
- **Ecosystem Integration**: Native integration with Nix package management

## Key Changes

### Architecture Changes

- **Before**: Docker containers with Dockerfiles for each sandbox environment
- **After**: Nix expressions in `nix/` directory with `runCommand` derivations for isolation

### Files Changed

- `flake.nix` - New Nix flake for project management
- `nix/*.nix` - Nix expressions replacing Dockerfiles
- `internal/sandbox/nix.go` - New Nix-based execution backend
- `internal/sandbox/sandbox.go` - Updated to use Nix executor
- `internal/sandbox/build.go` - Simplified (no Docker image building)
- `cmd/sandbox-mcp/main.go` - Updated to initialize Nix executor
- `Makefile` - New Nix-focused targets

### Sandbox Environment Mapping

| Sandbox Type | Docker Image | Nix Expression |
|-------------|-------------|----------------|
| shell | `sandbox-mcp/shell:latest` | `nix/shell.nix` |
| go | `sandbox-mcp/go:latest` | `nix/go.nix` |
| python | `sandbox-mcp/python:latest` | `nix/python.nix` |
| javascript | `sandbox-mcp/javascript:latest` | `nix/javascript.nix` |
| rust | `sandbox-mcp/rust:latest` | `nix/rust.nix` |
| java | `sandbox-mcp/java:latest` | `nix/java.nix` |
| network-tools | `sandbox-mcp/network-tools:latest` | `nix/network-tools.nix` |
| apisix | `sandbox-mcp/apisix:latest` | `nix/apisix.nix` |

## Usage

### Building with Nix

```bash
# Build using Nix flake (preferred)
make nix-build

# Or use standard Go build as fallback
make build
```

### Nix Expressions

```bash
# List available Nix sandbox environments
make nix-expressions

# Check available expressions
ls nix/*.nix
```

### Development

```bash
# Enter Nix development shell
nix develop

# Or use the traditional approach
make deps
make build
```

## Migration Benefits

### For Users

- **Faster startup**: No Docker container overhead
- **Better isolation**: Nix sandbox provides process, network, and filesystem isolation
- **Reproducible**: Exact same environment every time
- **Self-contained**: No external Docker dependency

### For Developers

- **Declarative environments**: Nix expressions are version-controlled and reproducible
- **Easy testing**: `nix-build` can test any environment locally
- **Better CI/CD**: Nix builds are deterministic and cacheable
- **Ecosystem benefits**: Leverages Nix's extensive package repository

## Backward Compatibility

- **MCP Interface**: Unchanged - all existing MCP clients work without modification
- **Configuration**: JSON sandbox configs remain the same
- **Tool Names**: All sandbox tool names preserved
- **Parameters**: Input/output formats unchanged

## Implementation Details

### Nix Sandbox Isolation

Each Nix expression uses `runCommand` with:
- `allowSubstitutes = false` - Forces local build
- `preferLocalBuild = true` - Ensures sandbox execution
- Linux namespaces for process isolation
- Chroot for filesystem isolation
- Controlled environment variables

### Execution Flow

1. Code and files written to temporary directory
2. Nix expression generated with appropriate environment
3. `nix-build --sandbox` executed for isolation (or simulated in development)
4. Results captured and returned via MCP

### Fallback Behavior

When Nix is not available, the system falls back to direct execution with basic isolation, maintaining compatibility while encouraging Nix adoption.

## Future Enhancements

- **Full Nix Integration**: When running in pure Nix environment, leverage full sandbox capabilities
- **Resource Limits**: Integration with systemd or cgroups for CPU/memory limits
- **Network Policies**: More granular network access control
- **Package Management**: Dynamic package installation within sandboxes