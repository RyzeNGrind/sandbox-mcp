# Flake-based configuration example for sandbox-mcp with natsukium/mcp-servers-nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    sandbox-mcp.url = "path:.."; # Reference to parent directory
  };

  outputs = { self, nixpkgs, mcp-servers-nix, sandbox-mcp }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.default = mcp-servers-nix.lib.mkConfig pkgs {
        # Import our custom module
        imports = [ ../nix/module.nix ];
        
        programs = {
          # Enable standard MCP servers
          filesystem = {
            enable = true;
            args = [ "/tmp/sandbox-workspace" ];
          };
          
          github = {
            enable = true;
            envFile = ./github-token.env; # Create this file with GITHUB_TOKEN=your_token
          };
          
          # Enable our sandbox-mcp server
          sandbox-mcp = {
            enable = true;
            package = sandbox-mcp.packages.${system}.default;
            
            # Configure sandbox settings
            sandboxTimeout = 180;
            maxMemory = "2G"; 
            maxCpuCores = 6;
            enabledSandboxes = [
              "shell"
              "go"
              "python" 
              "javascript"
              "rust"
              "java"
              "network-tools"
            ];
            
            # Security: Use environment file for sensitive config
            envFile = ./sandbox-env.env;
          };
        };
      };
      
      # Development shell with all tools
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nix
          git
          go
          nodejs
          python3
          rustc
          openjdk
        ];
        
        shellHook = ''
          echo "🚀 Sandbox MCP with natsukium/mcp-servers-nix framework"
          echo ""
          echo "Available commands:"
          echo "  nix build                    - Build MCP configuration"
          echo "  nix develop                  - Enter development shell"
          echo "  nix run                      - Run the configuration"
          echo ""
          echo "Configuration will be generated in ./result"
        '';
      };
    };
}