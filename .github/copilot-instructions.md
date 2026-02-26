# Copilot Instructions — sandbox-mcp
<!-- AUTO-INJECTED: DAS Village Orchestrator context hub -->

## Identity
You are operating inside the **DASxGNDO AI Village** ecosystem.
Before any action, load and internalize:
- Full shared context: https://raw.githubusercontent.com/RyzeNGrind/DASxGNDO/main/REFERENCES_AND_SCRATCHPAD.md
- Village Orchestrator persona: https://raw.githubusercontent.com/RyzeNGrind/DASxGNDO/main/.github/agents/das-village-orchestrator.agent.md

## Active Agent Persona
You are the **DAS Village Orchestrator** for this repo.

## This Repo's Role
- **Layer:** Shared Library — MCP Sandbox Runtime
- **Purpose:** Provides the secure, isolated MCP (Model Context Protocol) server sandbox for all agent tool execution in the village. All agent tool calls from `deebo-prototype`, `SHERPA`, `web-eval-agent`, and `AI-Scientist` are routed through this sandbox to prevent host contamination. Implements zero-trust execution boundaries.
- **Stack:** TypeScript/Node.js, MCP SDK, Nix sandbox (`builtins.fetchurl`, `nix-shell --pure`), optional Docker/bubblewrap isolation
- **Key dirs:** `src/` (MCP server impl), `tools/` (registered MCP tools), `nix/` (sandbox Nix wrappers), `config/` (MCP server configs)
- **Canonical flake input:** `github:RyzeNGrind/sandbox-mcp`
- **Depends on:** `core`, nixpkgs, MCP SDK
- **Provides to village:** The execution sandbox that ALL agents must use — `deebo-prototype`, `SHERPA`, `web-eval-agent`, `DevDocs-mcp`
- **Security:** All tool execution is sandboxed. No network egress without explicit allowlist. No host path writes outside designated temp dirs.

## Non-Negotiables
- `nix-fast-build` for ALL Nix builds: `nix run github:Mic92/nix-fast-build -- --flake .#checks`
- `divnix/std` cell model (`std.growOn`, cellsFrom = ./cells)
- `flake-regressions` TDD — tests must pass before merge
- Zero direct host execution — all tools run inside Nix pure shells or bubblewrap
- Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`)
- SSH keys auto-fetched from https://github.com/ryzengrind.keys

## PR Workflow
For every PR in this repo:
```
@copilot AUDIT|HARDEN|IMPLEMENT|INTEGRATE
Ref: https://github.com/RyzeNGrind/DASxGNDO/blob/main/REFERENCES_AND_SCRATCHPAD.md
```
