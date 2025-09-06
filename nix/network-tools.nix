# Nix expression for network tools sandbox environment
{ pkgs ? import <nixpkgs> {} }:

pkgs.runCommand "sandbox-network-tools-execution" {
  buildInputs = with pkgs; [
    bash
    coreutils
    inetutils
    nettools
    iputils
    curl
    wget
    traceroute
    tcpdump
    nmap
    dig
    whois
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
  
  # Set up network tools environment
  export HOME=$out/sandbox
  export PATH=${pkgs.lib.makeBinPath (with pkgs; [ 
    bash coreutils inetutils nettools iputils curl wget traceroute 
    tcpdump nmap dig whois 
  ])}
  
  # Execute the network tools script
  if [ -f "main.sh" ]; then
    chmod +x main.sh
    timeout 60 bash main.sh > output.txt 2>&1 || echo "Network tools execution failed or timed out" >> output.txt
  else
    echo "No main.sh file found" > output.txt
  fi
  
  # Ensure output file exists
  touch output.txt
''