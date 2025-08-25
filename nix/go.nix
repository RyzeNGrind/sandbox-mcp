# Nix expression for Go sandbox environment
{ pkgs ? import <nixpkgs> {} }:

pkgs.runCommand "sandbox-go-execution" {
  buildInputs = with pkgs; [
    go
    git
    coreutils
    bash
  ];
  
  # Enable Nix sandbox for isolation
  allowSubstitutes = false;
  preferLocalBuild = true;
} ''
  # Create sandbox environment
  mkdir -p $out/sandbox/src
  cd $out/sandbox/src
  
  # Copy input files if provided
  if [ -n "$inputFiles" ]; then
    cp -r $inputFiles/* .
  fi
  
  # Set up Go environment
  export HOME=$out/sandbox
  export GOPATH=$out/sandbox
  export GOCACHE=$out/sandbox/.cache
  export PATH=${pkgs.lib.makeBinPath (with pkgs; [ go git coreutils bash ])}
  
  # Initialize go.mod if it doesn't exist
  if [ ! -f "go.mod" ]; then
    go mod init sandbox
  fi
  
  # Execute the Go program
  if [ -f "main.go" ]; then
    timeout 60 go run main.go > ../output.txt 2>&1 || echo "Go execution failed or timed out" >> ../output.txt
  else
    echo "No main.go file found" > ../output.txt
  fi
  
  # Ensure output file exists
  touch $out/sandbox/output.txt
''