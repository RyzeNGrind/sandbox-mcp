# Production-Ready Nix Flake Architecture

This document describes the refactored, production-ready structure of the sandbox-mcp Nix flake.

## Architecture Overview

### Script Organization

All shell logic has been extracted from the main flake.nix into dedicated script files in the `scripts/` directory:

- `scripts/dev-shell-hook.sh` - Development shell initialization
- `scripts/sandbox-setup.sh` - Sandbox environment setup and cleanup
- `scripts/build.sh` - Application build script with version injection

### Flake Structure

The flake now uses `writeShellScript` derivations for all shell operations, ensuring:

- **Syntax Safety**: No embedded shell commands in Nix expressions
- **Reproducibility**: Scripts are part of the Nix store
- **Modularity**: Logic is separated and reusable
- **Testing**: Scripts can be tested independently

### Key Improvements

1. **Separated Concerns**
   - Shell logic → separate script files
   - Nix expressions → pure functional declarations
   - Build configuration → dedicated build script

2. **Enhanced Security**
   - No shell injection vulnerabilities
   - Proper escaping in all string interpolations
   - Isolated script execution environments

3. **Better Maintainability**
   - Scripts can be edited independently
   - Clear separation of responsibilities
   - Easy to add new utility scripts

4. **Production Readiness**
   - Consistent `vendorHash = null` for Go modules
   - Proper dependency management
   - Clean package definitions

## Usage

### Development
```bash
nix develop                    # Enter development shell
nix build .#build-script       # Build the build script
nix build .#setup-script       # Build the setup script
```

### Building
```bash
nix build                      # Build sandbox-mcp
nix build .#example-config     # Build MCP configuration
```

### Scripts
```bash
# Use scripts directly from packages
$(nix build .#setup-script --print-out-paths) setup shell /tmp/my-sandbox
$(nix build .#build-script --print-out-paths)
```

## Framework Integration

The flake properly integrates with natsukium/mcp-servers-nix using:

- `settings.servers.sandbox-mcp` configuration pattern
- Compatible package definitions
- Proper module structure for NixOS and Home Manager

## Validation

The structure has been designed to pass `nix flake check` by:

- Removing all embedded shell syntax from Nix expressions
- Using proper Nix string interpolation
- Ensuring consistent Go module handling
- Validating all derivations are well-formed