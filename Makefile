.PHONY: build clean deps nix-build nix-config nix-dev test examples

# Install dependencies
deps:
	go mod tidy 

test:
	chmod +x test/run_tests.sh
	TOOL=$(TOOL) ./test/run_tests.sh

# Build the application
build:
	mkdir -p dist
	go build -ldflags="-X 'github.com/pottekkat/sandbox-mcp/internal/version.Version=$$(git describe --tags)' -X 'github.com/pottekkat/sandbox-mcp/internal/version.CommitSHA=$$(git rev-parse --short HEAD)'" -o dist/sandbox-mcp ./cmd/sandbox-mcp/main.go

# Install the application
install:
	go install -ldflags="-X 'github.com/pottekkat/sandbox-mcp/internal/version.Version=$$(git describe --tags)' -X 'github.com/pottekkat/sandbox-mcp/internal/version.CommitSHA=$$(git rev-parse --short HEAD)'" ./cmd/sandbox-mcp

# Clean build artifacts
clean:
	rm -rf dist/sandbox-mcp result*

# Build with Nix flake
nix-build:
	@echo "Building sandbox-mcp with Nix..."
	@if command -v nix >/dev/null 2>&1; then \
		nix build; \
		echo "Built successfully! Binary available at ./result/bin/sandbox-mcp"; \
	else \
		echo "Error: Nix not found. Please install Nix or use 'make build' for Go fallback."; \
		exit 1; \
	fi

# Build MCP configuration using natsukium framework
nix-config:
	@echo "Building MCP configuration with natsukium/mcp-servers-nix..."
	@if command -v nix >/dev/null 2>&1; then \
		cd examples && nix-build complete-config.nix; \
		echo "Configuration built! Check examples/result for Claude Desktop config."; \
	else \
		echo "Error: Nix not found. Please install Nix first."; \
		exit 1; \
	fi

# Enter Nix development shell
nix-dev:
	@echo "Entering Nix development environment..."
	@if command -v nix >/dev/null 2>&1; then \
		nix develop; \
	else \
		echo "Error: Nix not found. Please install Nix first."; \
		exit 1; \
	fi

# Test all example configurations
examples:
	@echo "Testing example configurations..."
	@for example in examples/*.nix; do \
		echo "Testing $$example..."; \
		if command -v nix >/dev/null 2>&1; then \
			nix-instantiate --eval $$example >/dev/null && echo "✓ $$example validates" || echo "✗ $$example has errors"; \
		else \
			echo "Skipping $$example (Nix not available)"; \
		fi; \
	done

# Generate Nix expressions for sandbox environments
nix-expressions:
	@echo "Available Nix sandbox environments:"
	@ls -1 nix/*.nix | sed 's/nix\///g' | sed 's/\.nix//g' | sed 's/^/  - /' | grep -v module
	@echo ""
	@echo "Module configuration: nix/module.nix"
	@echo "Usage examples: examples/"

# Show migration information for Docker users
docker-migration:
	@echo "🚀 Migrating from Docker to Nix-native sandboxing"
	@echo ""
	@echo "Old Docker commands → New Nix commands:"
	@echo "  make images     → make nix-expressions" 
	@echo "  docker build    → nix build"
	@echo "  docker run      → nix-build (automatic sandboxing)"
	@echo ""
	@echo "Benefits of Nix:"
	@echo "  ✓ No Docker dependency"
	@echo "  ✓ Faster execution (no container overhead)" 
	@echo "  ✓ Better isolation (native Linux namespaces)"
	@echo "  ✓ Reproducible environments"
	@echo "  ✓ Declarative configuration"
	@echo ""
	@echo "See NIX_FRAMEWORK_INTEGRATION.md for detailed migration guide."

# Legacy Docker images target (deprecated - show migration info)
images:
	@echo "⚠️  WARNING: Docker-based images are deprecated"
	@echo ""
	@$(MAKE) docker-migration

# Help target
help:
	@echo "Sandbox MCP - Nix-native Build Commands"
	@echo ""
	@echo "Core Commands:"
	@echo "  build         - Build with Go (local development)"
	@echo "  nix-build     - Build with Nix (recommended)"
	@echo "  nix-config    - Build MCP configuration with framework"
	@echo "  nix-dev       - Enter Nix development shell"
	@echo "  test          - Run tests"
	@echo "  clean         - Clean build artifacts"
	@echo ""
	@echo "Nix Commands:"
	@echo "  nix-expressions - List available sandbox environments"
	@echo "  examples        - Test example configurations"
	@echo "  docker-migration - Show Docker → Nix migration info"
	@echo ""
	@echo "Legacy:"
	@echo "  images        - (deprecated) Show migration guidance"
