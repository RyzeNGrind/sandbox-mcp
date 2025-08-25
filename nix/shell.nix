# Nix expression for shell sandbox environment
{ pkgs ? import <nixpkgs> {} }:

pkgs.runCommand "sandbox-shell-execution" {
  buildInputs = with pkgs; [
    bash
    coreutils
    findutils
    grep
    sed
    awk
  ];
  
  # Enable Nix sandbox for isolation
  # This provides process, network, and filesystem isolation
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
  
  # Set up environment
  export HOME=$out/sandbox
  export PATH=${pkgs.lib.makeBinPath (with pkgs; [ bash coreutils findutils grep sed awk ])}
  
  # Execute the command
  if [ -f "main.sh" ]; then
    chmod +x main.sh
    timeout 60 bash main.sh > output.txt 2>&1 || echo "Command failed or timed out" >> output.txt
  else
    echo "No main.sh file found" > output.txt
  fi
  
  # Ensure output file exists
  touch output.txt
''