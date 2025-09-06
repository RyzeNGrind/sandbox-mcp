{
  description = "Nix-native MCP server sandbox for secure code execution";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, mcp-servers-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Build the sandbox-mcp Go application
        sandbox-mcp = pkgs.buildGoModule {
          pname = "sandbox-mcp";
          version = "0.1.0";
          src = ./.;
          vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Update this when building: use `nix build` and update with actual hash
          
          ldflags = [
            "-X github.com/pottekkat/sandbox-mcp/internal/version.Version=${self.rev or "dev"}"
            "-X github.com/pottekkat/sandbox-mcp/internal/version.CommitSHA=${self.shortRev or "unknown"}"
          ];

          meta = with pkgs.lib; {
            description = "MCP server for executing code in isolated sandbox environments";
            homepage = "https://github.com/RyzeNGrind/sandbox-mcp";
            license = licenses.mit;
            maintainers = [ ];
            mainProgram = "sandbox-mcp";
          };
        };

        # Example configuration showing how sandbox-mcp can be integrated
        # with mcp-servers-nix framework via custom servers configuration
        example-mcp-config = mcp-servers-nix.lib.mkConfig pkgs {
          # Configure built-in framework modules
          programs = {
            filesystem = {
              enable = true;
              args = [ "/tmp/workspace" ];
            };
            fetch.enable = true;
          };
          
          # Add our custom sandbox-mcp server
          settings.servers = {
            sandbox-mcp = {
              command = "${sandbox-mcp}/bin/sandbox-mcp";
              args = [
                "--config"
                "/etc/sandbox-mcp/config.json"
              ];
              env = {
                NIX_PATH = "nixpkgs=${nixpkgs}";
              };
            };
          };
        };

      in
      {
        packages = {
          default = sandbox-mcp;
          sandbox-mcp = sandbox-mcp;
          example-config = example-mcp-config;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
            gotools
            go-tools
            nix
            git
          ];
          
          shellHook = ''
            echo "Nix-native sandbox-mcp development environment"
            echo "Available commands:"
            echo "  go build ./cmd/sandbox-mcp     - Build the application"
            echo "  nix build                      - Build with Nix"
            echo "  nix develop                    - Enter development shell"
            echo "  nix build .#example-config     - Build example MCP configuration"
          '';
        };

        apps.default = flake-utils.lib.mkApp {
          drv = sandbox-mcp;
        };

        # NixOS module for sandbox-mcp
        nixosModules.default = { config, lib, pkgs, ... }:
          let
            cfg = config.services.sandbox-mcp;
          in
          {
            options.services.sandbox-mcp = {
              enable = lib.mkEnableOption "sandbox-mcp MCP server";
              
              package = lib.mkPackageOption pkgs "sandbox-mcp" { };
              
              configFile = lib.mkOption {
                type = lib.types.path;
                description = "Path to the sandbox-mcp configuration file";
              };
              
              user = lib.mkOption {
                type = lib.types.str;
                default = "sandbox-mcp";
                description = "User account under which sandbox-mcp runs";
              };
              
              group = lib.mkOption {
                type = lib.types.str;
                default = "sandbox-mcp";
                description = "Group under which sandbox-mcp runs";
              };
            };

            config = lib.mkIf cfg.enable {
              users.users.${cfg.user} = {
                isSystemUser = true;
                group = cfg.group;
                description = "sandbox-mcp service user";
              };

              users.groups.${cfg.group} = { };

              systemd.services.sandbox-mcp = {
                description = "sandbox-mcp MCP server";
                wantedBy = [ "multi-user.target" ];
                after = [ "network.target" ];
                
                serviceConfig = {
                  Type = "simple";
                  User = cfg.user;
                  Group = cfg.group;
                  ExecStart = "${cfg.package}/bin/sandbox-mcp --config ${cfg.configFile}";
                  Restart = "on-failure";
                  RestartSec = 5;
                  
                  # Security hardening
                  NoNewPrivileges = true;
                  PrivateTmp = true;
                  ProtectHome = true;
                  ProtectSystem = "strict";
                  ReadWritePaths = [ "/tmp" "/var/lib/sandbox-mcp" ];
                };
                
                environment = {
                  NIX_PATH = "nixpkgs=${nixpkgs}";
                };
              };
            };
          };

        # Home Manager module for sandbox-mcp  
        homeManagerModules.default = { config, lib, pkgs, ... }:
          let
            cfg = config.programs.sandbox-mcp;
          in
          {
            options.programs.sandbox-mcp = {
              enable = lib.mkEnableOption "sandbox-mcp MCP server integration";
              
              package = lib.mkPackageOption pkgs "sandbox-mcp" { };
              
              settings = lib.mkOption {
                type = lib.types.attrs;
                default = { };
                description = "Configuration for sandbox-mcp";
              };
            };

            config = lib.mkIf cfg.enable {
              home.packages = [ cfg.package ];
              
              xdg.configFile."claude/claude_desktop_config.json".text = builtins.toJSON {
                mcpServers.sandbox-mcp = {
                  command = "${cfg.package}/bin/sandbox-mcp";
                  args = [ "--config" "${config.xdg.configHome}/sandbox-mcp/config.json" ];
                  env = {
                    NIX_PATH = "nixpkgs=${nixpkgs}";
                  };
                };
              };
              
              xdg.configFile."sandbox-mcp/config.json".text = builtins.toJSON cfg.settings;
            };
          };
      }
    );
}