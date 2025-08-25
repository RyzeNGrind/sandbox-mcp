package sandbox

import (
	"context"
	"log"

	"github.com/pottekkat/sandbox-mcp/internal/config"
)

// BuildImage is a placeholder for Nix expression generation (Docker replacement)
func BuildImage(ctx context.Context, sandboxConfig *config.SandboxConfig, basePath string) error {
	log.Printf("Nix-native sandbox %s is ready (no image building required)", sandboxConfig.Id)
	return nil
}
