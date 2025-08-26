# Complete example: Sandbox MCP with filesystem and GitHub integration
{
  pkgs ? import <nixpkgs> { },
}:
let
  # Import the mcp-servers-nix framework
  mcp-servers = import (builtins.fetchTarball {
    url = "https://github.com/natsukium/mcp-servers-nix/archive/main.tar.gz";
    # TODO: Update with actual hash after framework stabilizes
    sha256 = "0000000000000000000000000000000000000000000000000000";
  }) { inherit pkgs; };
  
  # Import our sandbox-mcp package
  sandbox-mcp = pkgs.callPackage ../default.nix { };
in
mcp-servers.lib.mkConfig pkgs {
  # Import our custom module for sandbox-mcp
  imports = [
    ../nix/module.nix
  ];
  
  # Configure output format and file
  format = "json";
  fileName = "claude_desktop_config.json";
  
  programs = {
    # File system access for workspace management
    filesystem = {
      enable = true;
      args = [ 
        "/tmp/mcp-workspace"  # Safe workspace directory
        "/home/user/projects" # Your projects directory (adjust as needed)
      ];
    };
    
    # GitHub integration for repository operations
    github = {
      enable = true;
      # Security: Use environment file for GitHub token
      envFile = ./github-token.env;
      # Alternative: Use password command for dynamic token retrieval
      # passwordCommand = {
      #   GITHUB_TOKEN = [ "pass" "show" "github/mcp-token" ];
      # };
    };
    
    # Web content fetching
    fetch = {
      enable = true;
    };
    
    # Memory/context management
    memory = {
      enable = true;
    };
    
    # Our sandbox execution environment
    sandbox-mcp = {
      enable = true;
      package = sandbox-mcp;
      
      # Sandbox configuration
      sandboxTimeout = 180;        # 3 minutes for complex operations
      maxMemory = "2G";           # Generous memory for compilation
      maxCpuCores = 4;            # Multiple cores for parallel builds
      
      # Enable comprehensive language support
      enabledSandboxes = [
        "shell"       # Shell scripting and system commands
        "go"          # Go development and execution
        "python"      # Python with pip package support
        "javascript"  # Node.js and npm
        "rust"        # Rust with Cargo
        "java"        # Java compilation and execution
        "network-tools" # Network debugging and testing
      ];
      
      # Nix configuration for reproducible environments
      nixPath = "nixpkgs=channel:nixos-unstable";
      
      # Security: Use environment file for any sensitive configuration
      envFile = ./sandbox-env.env;
      
      # Custom environment variables
      env = {
        SANDBOX_MODE = "production";
        LOG_LEVEL = "info";
      };
      
      # Additional command line arguments
      args = [
        "--nix-native"           # Force Nix-native mode
        "--enable-networking"    # Allow network access in sandboxes
        "--workspace-persist"    # Persist workspace between executions
      ];
    };
  };
  
  # Custom settings that will be merged with generated configuration
  settings = {
    # Global MCP client settings
    globalSettings = {
      timeout = 300;  # 5 minute global timeout
      logging = {
        level = "info";
        format = "json";
      };
    };
    
    # Custom server configurations not covered by modules
    servers = {
      # Example: Add custom MCP server
      # custom-server = {
      #   command = "/path/to/custom-mcp-server";
      #   args = [ "--config" "/path/to/config" ];
      #   env = {
      #     CUSTOM_API_KEY = "from-env-file";
      #   };
      # };
    };
  };
}