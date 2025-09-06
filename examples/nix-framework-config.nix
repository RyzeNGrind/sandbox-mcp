# Example configuration using natsukium/mcp-servers-nix framework
{
  pkgs ? import <nixpkgs> { },
}:
let
  # Import the mcp-servers-nix framework
  mcp-servers = import (builtins.fetchTarball {
    url = "https://github.com/natsukium/mcp-servers-nix/archive/main.tar.gz";
    sha256 = "0000000000000000000000000000000000000000000000000000"; # Update with actual hash
  }) { inherit pkgs; };
  
  # Import our sandbox-mcp package
  sandbox-mcp = pkgs.callPackage ../. { };
in
mcp-servers.lib.mkConfig pkgs {
  # Use the framework's module system
  imports = [
    # Import our custom sandbox-mcp module
    ../nix/module.nix
  ];
  
  programs = {
    # Configure built-in servers from natsukium framework
    filesystem = {
      enable = true;
      args = [ "/tmp/sandbox-workdir" ];
    };
    
    fetch = {
      enable = true;
    };
    
    # Configure our sandbox-mcp server
    sandbox-mcp = {
      enable = true;
      package = sandbox-mcp;
      
      # Custom configuration options
      sandboxTimeout = 120;
      maxMemory = "1G";
      maxCpuCores = 4;
      enabledSandboxes = [ 
        "shell" 
        "go" 
        "python" 
        "javascript" 
        "rust" 
        "java" 
      ];
      
      # Environment variables
      env = {
        SANDBOX_LOG_LEVEL = "info";
      };
      
      # Additional arguments
      args = [
        "--bind"
        "127.0.0.1:8080"
      ];
    };
  };
}