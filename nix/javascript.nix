# Nix expression for JavaScript sandbox environment
{ pkgs ? import <nixpkgs> {} }:

pkgs.runCommand "sandbox-javascript-execution" {
  buildInputs = with pkgs; [
    nodejs
    nodePackages.npm
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
  
  # Set up Node.js environment
  export HOME=$out/sandbox
  export NODE_ENV=production
  export NODE_OPTIONS="--no-warnings"
  export PATH=${pkgs.lib.makeBinPath (with pkgs; [ nodejs nodePackages.npm coreutils bash ])}
  
  # Execute the JavaScript program
  if [ -f "main.js" ]; then
    timeout 60 node main.js > output.txt 2>&1 || echo "JavaScript execution failed or timed out" >> output.txt
  else
    echo "No main.js file found" > output.txt
  fi
  
  # Ensure output file exists
  touch output.txt
''