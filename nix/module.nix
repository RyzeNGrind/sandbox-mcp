# Nix module for sandbox-mcp using mcp-servers-nix framework
{ config, pkgs, lib, mkServerModule, ... }:
let
  cfg = config.programs.sandbox-mcp;
in
{
  imports = [
    (mkServerModule {
      name = "sandbox-mcp";
      packageName = "sandbox-mcp";
    })
  ];

  # Define custom options specific to sandbox-mcp
  options.programs.sandbox-mcp = {
    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to the sandbox-mcp configuration file.
        If not specified, a default configuration will be used.
      '';
    };
    
    nixPath = lib.mkOption {
      type = lib.types.str;
      default = "nixpkgs=<nixpkgs>";
      description = ''
        NIX_PATH environment variable for sandbox execution.
        This determines which nixpkgs version to use for sandbox environments.
      '';
    };
    
    enabledSandboxes = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [
        "shell"
        "go" 
        "python"
        "javascript"
        "rust"
        "java"
        "network-tools"
        "apisix"
      ]);
      default = [ "shell" "go" "python" "javascript" "rust" "java" ];
      description = ''
        List of sandbox environments to enable.
        Each enabled sandbox will have corresponding Nix expressions available.
      '';
    };
    
    sandboxTimeout = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = ''
        Default timeout in seconds for sandbox execution.
      '';
    };
    
    maxMemory = lib.mkOption {
      type = lib.types.str;
      default = "512M";
      description = ''
        Maximum memory limit for sandbox execution.
      '';
    };
    
    maxCpuCores = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = ''
        Maximum number of CPU cores for sandbox execution.
      '';
    };
  };

  # Configure the server with custom options
  config.settings.servers = lib.mkIf cfg.enable {
    sandbox-mcp = {
      args = lib.flatten [
        (lib.optionals (cfg.configFile != null) [ "--config" cfg.configFile ])
        [ "--nix-native" ]
        [ "--timeout" (toString cfg.sandboxTimeout) ]
        [ "--max-memory" cfg.maxMemory ]
        [ "--max-cpu-cores" (toString cfg.maxCpuCores) ]
        (lib.concatMap (sandbox: [ "--enable-sandbox" sandbox ]) cfg.enabledSandboxes)
      ];
      
      env = {
        NIX_PATH = cfg.nixPath;
        SANDBOX_MCP_NIX_MODE = "true";
      };
    };
  };
}