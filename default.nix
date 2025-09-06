# Nix package definition for sandbox-mcp
{ lib
, buildGoModule
, fetchFromGitHub
, nix
, git
, makeWrapper
}:

buildGoModule rec {
  pname = "sandbox-mcp";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Update this when dependencies are added

  nativeBuildInputs = [ makeWrapper ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/pottekkat/sandbox-mcp/internal/version.Version=${version}"
    "-X github.com/pottekkat/sandbox-mcp/internal/version.CommitSHA=${src.rev or "unknown"}"
  ];

  # Wrap the binary to ensure Nix and other tools are available
  postInstall = ''
    wrapProgram $out/bin/sandbox-mcp \
      --prefix PATH : ${lib.makeBinPath [ nix git ]}
  '';

  # Include Nix expressions as resources
  postBuild = ''
    mkdir -p $out/share/sandbox-mcp/nix
    cp -r nix/* $out/share/sandbox-mcp/nix/
  '';

  meta = with lib; {
    description = "MCP server for executing code in isolated Nix sandbox environments";
    longDescription = ''
      Sandbox MCP is a Model Context Protocol (MCP) server that enables LLMs to
      run code in secure, isolated Nix sandbox environments. It provides strong
      isolation guarantees, reproducible builds, and eliminates Docker dependency
      while maintaining backward compatibility with existing MCP clients.
    '';
    homepage = "https://github.com/RyzeNGrind/sandbox-mcp";
    license = licenses.mit;
    maintainers = with maintainers; [ ]; # Add maintainers here
    mainProgram = "sandbox-mcp";
    platforms = platforms.unix;
  };
}