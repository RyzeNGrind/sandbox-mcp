# Nix expression for Rust sandbox environment
{ pkgs ? import <nixpkgs> {} }:

pkgs.runCommand "sandbox-rust-execution" {
  buildInputs = with pkgs; [
    rustc
    cargo
    gcc
    coreutils
    bash
  ];
  
  # Enable Nix sandbox for isolation
  allowSubstitutes = false;
  preferLocalBuild = true;
} ''
  # Create sandbox environment
  mkdir -p $out/sandbox
  cd $out/sandbox
  
  # Copy input files if provided
  if [ -n "$inputFiles" ]; then
    cp -r $inputFiles/* .
  fi
  
  # Set up Rust environment
  export HOME=$out/sandbox
  export CARGO_HOME=$out/sandbox/.cargo
  export PATH=${pkgs.lib.makeBinPath (with pkgs; [ rustc cargo gcc coreutils bash ])}
  
  # Execute the Rust program
  if [ -f "main.rs" ]; then
    timeout 60 sh -c 'rustc -o main main.rs && ./main' > output.txt 2>&1 || echo "Rust execution failed or timed out" >> output.txt
  else
    echo "No main.rs file found" > output.txt
  fi
  
  # Ensure output file exists
  touch output.txt
''