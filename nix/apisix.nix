# Nix expression for APISIX sandbox environment
{ pkgs ? import <nixpkgs> {} }:

pkgs.runCommand "sandbox-apisix-execution" {
  buildInputs = with pkgs; [
    bash
    coreutils
    curl
    # Note: For a full APISIX implementation, we'd need the actual APISIX package
    # This is a simplified version that focuses on the testing capabilities
  ];
  
  # Enable Nix sandbox for isolation (but allow network access)
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
  
  # Set up APISIX simulation environment
  export HOME=$out/sandbox
  export PATH=${pkgs.lib.makeBinPath (with pkgs; [ bash coreutils curl ])}
  
  # Create a mock APISIX configuration directory
  mkdir -p /tmp/mock-apisix/conf
  
  # Execute the APISIX testing script
  if [ -f "main.sh" ] && [ -f "apisix.yaml" ]; then
    # Simulate APISIX configuration copy
    cp apisix.yaml /tmp/mock-apisix/conf/ || true
    
    chmod +x main.sh
    timeout 60 sh -c 'sleep 2 && sh main.sh' > output.txt 2>&1 || echo "APISIX execution failed or timed out" >> output.txt
  else
    echo "No main.sh or apisix.yaml file found" > output.txt
  fi
  
  # Ensure output file exists
  touch output.txt
''