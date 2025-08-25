.PHONY: build clean deps nix-build test

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
	rm -rf dist/sandbox-mcp

# Build with Nix (replaces Docker-based images)
nix-build:
	@echo "Building with Nix flake..."
	@if command -v nix >/dev/null 2>&1; then \
		nix build; \
	else \
		echo "Nix not found. Using standard Go build as fallback."; \
		$(MAKE) build; \
	fi

# Generate Nix expressions for sandbox environments (replaces Docker images)
nix-expressions:
	@echo "Nix expressions are already available in the nix/ directory"
	@echo "Available sandbox environments:"
	@ls -1 nix/*.nix | sed 's/nix\///g' | sed 's/\.nix//g' | sed 's/^/  - /'

# Legacy Docker images target (deprecated - use nix-expressions instead)
images:
	@echo "WARNING: Docker-based images are deprecated. Use 'make nix-expressions' instead."
	@echo "Nix-native sandboxing provides better isolation and reproducibility."
