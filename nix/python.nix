# Nix expression for Python sandbox environment
{ pkgs ? import <nixpkgs> {} }:

pkgs.runCommand "sandbox-python-execution" {
  buildInputs = with pkgs; [
    python3
    python3Packages.pip
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
  
  # Set up Python environment
  export HOME=$out/sandbox
  export PATH=${pkgs.lib.makeBinPath (with pkgs; [ python3 python3Packages.pip coreutils bash ])}
  
  # Execute the Python program
  if [ -f "main.py" ]; then
    timeout 60 python3 main.py > output.txt 2>&1 || echo "Python execution failed or timed out" >> output.txt
  else
    echo "No main.py file found" > output.txt
  fi
  
  # Ensure output file exists
  touch output.txt
''