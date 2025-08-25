{
  description = "Nix-native MCP server sandbox for secure code execution";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Build the sandbox-mcp Go application
        sandbox-mcp = pkgs.buildGoModule {
          pname = "sandbox-mcp";
          version = "0.1.0";
          src = ./.;
          vendorHash = null; # Will need to be updated when building with Nix: use `nix build` and update with actual hash
          
          ldflags = [
            "-X github.com/pottekkat/sandbox-mcp/internal/version.Version=${self.rev or "dev"}"
            "-X github.com/pottekkat/sandbox-mcp/internal/version.CommitSHA=${self.shortRev or "unknown"}"
          ];
        };

        # Sandbox environments using Nix instead of Docker
        sandboxEnvironments = {
          shell = pkgs.buildEnv {
            name = "sandbox-shell";
            paths = with pkgs; [ 
              bash 
              coreutils 
              findutils 
              grep 
              sed 
              awk 
            ];
          };
          
          go = pkgs.buildEnv {
            name = "sandbox-go";
            paths = with pkgs; [ 
              go 
              git 
              coreutils 
              bash 
            ];
          };
          
          python = pkgs.buildEnv {
            name = "sandbox-python";
            paths = with pkgs; [ 
              python3 
              python3Packages.pip 
              coreutils 
              bash 
            ];
          };
          
          javascript = pkgs.buildEnv {
            name = "sandbox-javascript";
            paths = with pkgs; [ 
              nodejs 
              nodePackages.npm 
              coreutils 
              bash 
            ];
          };
          
          rust = pkgs.buildEnv {
            name = "sandbox-rust";
            paths = with pkgs; [ 
              rustc 
              cargo 
              gcc 
              coreutils 
              bash 
            ];
          };
          
          java = pkgs.buildEnv {
            name = "sandbox-java";
            paths = with pkgs; [ 
              openjdk 
              coreutils 
              bash 
            ];
          };
        };

        # Helper function to create a sandboxed execution environment
        mkSandboxRunner = { environment, command, workdir ? "/sandbox" }: pkgs.writeShellScript "sandbox-runner" ''
          export PATH="${environment}/bin:$PATH"
          export HOME="${workdir}"
          cd "${workdir}"
          exec ${builtins.concatStringsSep " " command}
        '';

      in
      {
        packages = {
          default = sandbox-mcp;
          sandbox-mcp = sandbox-mcp;
        } // sandboxEnvironments;

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
          '';
        };

        apps.default = flake-utils.lib.mkApp {
          drv = sandbox-mcp;
        };
      }
    );
}