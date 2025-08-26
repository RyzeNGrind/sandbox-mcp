# Integration with natsukium/mcp-servers-nix

This document explains how sandbox-mcp integrates with the [natsukium/mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix) framework to provide a robust, modular, and secure MCP server configuration system.

## Overview

Rather than maintaining our own custom Nix implementation, sandbox-mcp now leverages the mature natsukium/mcp-servers-nix framework, which provides:

- **Modular configuration system** with consistent interfaces
- **Security features** for handling credentials safely via `envFile` and `passwordCommand`
- **NixOS and Home Manager integration**
- **Package management** for MCP servers
- **Reproducible builds** and version pinning

## Benefits of Integration

### 1. Reduced Maintenance Burden
- Leverage battle-tested framework instead of custom implementation
- Automatic updates and security patches from upstream
- Community-maintained modules and best practices

### 2. Enhanced Security
- Safe credential handling with `envFile` and `passwordCommand`
- No hardcoded secrets in Nix store
- Proper environment variable management

### 3. Better Ecosystem Integration
- Works seamlessly with other MCP servers in the framework
- NixOS module for system-wide deployment
- Home Manager module for user-specific setups

### 4. Simplified Configuration
- Declarative configuration with consistent options
- Modular approach for enabling/disabling features
- Type-safe configuration validation

## Usage Examples

### Basic Configuration

```nix
# config.nix
let
  pkgs = import <nixpkgs> {};
  mcp-servers = import (builtins.fetchTarball "https://github.com/natsukium/mcp-servers-nix/archive/main.tar.gz") { inherit pkgs; };
in
mcp-servers.lib.mkConfig pkgs {
  programs = {
    sandbox-mcp = {
      enable = true;
      sandboxTimeout = 120;
      enabledSandboxes = [ "shell" "go" "python" "javascript" ];
    };
  };
}
```

### Flake-based Configuration

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    sandbox-mcp.url = "github:RyzeNGrind/sandbox-mcp";
  };

  outputs = { nixpkgs, mcp-servers-nix, sandbox-mcp, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.default = mcp-servers-nix.lib.mkConfig pkgs {
        programs = {
          sandbox-mcp = {
            enable = true;
            package = sandbox-mcp.packages.${system}.default;
            sandboxTimeout = 180;
            maxMemory = "2G";
            enabledSandboxes = [ "shell" "go" "python" "javascript" "rust" "java" ];
          };
        };
      };
    };
}
```

### Combined with Other MCP Servers

```nix
mcp-servers.lib.mkConfig pkgs {
  programs = {
    # File system access
    filesystem = {
      enable = true;
      args = [ "/tmp/workspace" ];
    };
    
    # GitHub integration
    github = {
      enable = true;
      envFile = ./github-token.env;
    };
    
    # Our sandbox execution
    sandbox-mcp = {
      enable = true;
      sandboxTimeout = 120;
      enabledSandboxes = [ "shell" "go" "python" "javascript" ];
      
      # Security: use environment file for any sensitive config
      envFile = ./sandbox-env.env;
    };
  };
}
```

## Configuration Options

### Sandbox-Specific Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sandboxTimeout` | int | 60 | Default timeout in seconds for sandbox execution |
| `maxMemory` | string | "512M" | Maximum memory limit for sandbox execution |
| `maxCpuCores` | int | 2 | Maximum number of CPU cores for sandbox execution |
| `enabledSandboxes` | list | `["shell", "go", "python", "javascript", "rust", "java"]` | List of sandbox environments to enable |
| `configFile` | path | null | Path to sandbox-mcp configuration file |
| `nixPath` | string | "nixpkgs=<nixpkgs>" | NIX_PATH for sandbox execution |

### Standard Framework Options

All options from the natsukium framework are available:

- `enable` - Enable the server
- `package` - Package to use
- `args` - Command line arguments
- `env` - Environment variables  
- `envFile` - Environment file for secrets
- `passwordCommand` - Command to retrieve secrets

## Security Best Practices

### 1. Use Environment Files for Secrets

```nix
programs.sandbox-mcp = {
  enable = true;
  envFile = ./secrets.env; # Never commit this file
};
```

### 2. Use Password Commands for Dynamic Secrets

```nix
programs.sandbox-mcp = {
  enable = true;
  passwordCommand = {
    API_KEY = [ "pass" "show" "mcp/api-key" ];
    TOKEN = [ "vault" "kv" "get" "-field=token" "mcp/config" ];
  };
};
```

### 3. Restrict File System Access

```nix
programs = {
  filesystem = {
    enable = true;
    args = [ "/tmp/safe-workspace" ]; # Restrict to specific directory
  };
  
  sandbox-mcp = {
    enable = true;
    # Sandbox execution is already isolated via Nix
  };
};
```

## NixOS Integration

### System-wide Deployment

```nix
# configuration.nix
{ config, pkgs, ... }:
{
  imports = [ (fetchTarball "https://github.com/RyzeNGrind/sandbox-mcp/archive/main.tar.gz")/flake.nix ];
  
  services.sandbox-mcp = {
    enable = true;
    configFile = pkgs.writeText "sandbox-config.json" (builtins.toJSON {
      # Your configuration here
    });
  };
}
```

### Home Manager Integration

```nix
# home.nix
{ config, pkgs, ... }:
{
  programs.sandbox-mcp = {
    enable = true;
    settings = {
      timeout = 120;
      enabledSandboxes = [ "shell" "python" "javascript" ];
    };
  };
}
```

## Migration from Custom Implementation

If you were using the previous custom Nix implementation:

1. **Replace flake inputs** - Add `mcp-servers-nix` input
2. **Update configuration** - Use `mcp-servers.lib.mkConfig` instead of custom expressions  
3. **Move secrets** - Use `envFile` or `passwordCommand` instead of hardcoded env vars
4. **Simplify modules** - Remove custom Nix expressions in favor of framework options

### Before (Custom Implementation)

```nix
# Old approach
{
  packages.sandbox-python = pkgs.buildEnv {
    name = "sandbox-python";
    paths = with pkgs; [ python3 python3Packages.pip ];
  };
}
```

### After (Framework Integration)

```nix
# New approach
mcp-servers.lib.mkConfig pkgs {
  programs.sandbox-mcp = {
    enable = true;
    enabledSandboxes = [ "python" ];
  };
}
```

## Testing and Validation

Build and test your configuration:

```bash
# Build configuration
nix build

# Validate JSON output
cat result | jq '.'

# Test with Claude Desktop
cp result ~/.config/claude/claude_desktop_config.json
```

## Contributing

To add new sandbox types or enhance the integration:

1. **Follow framework patterns** - Use `mkServerModule` for consistency
2. **Add proper documentation** - Include examples and security notes
3. **Test thoroughly** - Ensure integration works with various MCP clients
4. **Submit upstream** - Consider contributing improvements back to natsukium framework

For more details, see the [examples/](../examples/) directory for complete working configurations.