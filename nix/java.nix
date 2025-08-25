# Nix expression for Java sandbox environment
{ pkgs ? import <nixpkgs> {} }:

pkgs.runCommand "sandbox-java-execution" {
  buildInputs = with pkgs; [
    openjdk
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
  
  # Set up Java environment
  export HOME=$out/sandbox
  export PATH=${pkgs.lib.makeBinPath (with pkgs; [ openjdk coreutils bash ])}
  export JAVA_HOME=${pkgs.openjdk}
  
  # Execute the Java program
  if [ -f "main.java" ]; then
    timeout 60 java --enable-preview main.java > output.txt 2>&1 || echo "Java execution failed or timed out" >> output.txt
  else
    echo "No main.java file found" > output.txt
  fi
  
  # Ensure output file exists
  touch output.txt
''