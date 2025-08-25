package sandbox

import (
	"context"
	"fmt"
	"strings"

	"github.com/mark3labs/mcp-go/mcp"
	"github.com/pottekkat/sandbox-mcp/internal/config"
)

// Global Nix executor instance
var nixExecutor *NixSandboxExecutor

// InitializeNixExecutor initializes the Nix sandbox executor
func InitializeNixExecutor(basePath string) {
	nixExecutor = NewNixSandboxExecutor(basePath)
}

// NewSandboxTool creates a sandbox tool from a config
func NewSandboxTool(sandboxConfig *config.SandboxConfig) mcp.Tool {
	options := []mcp.ToolOption{
		// All tools have a description and an entrypoint
		mcp.WithDescription(generateSandboxDescription(sandboxConfig)),
		withEntrypoint(sandboxConfig.ParamEntrypoint(), fmt.Sprintf("Code to be stored in a file named `%s` and executed with the command `%s`.",
			sandboxConfig.Entrypoint,
			strings.Join(sandboxConfig.Command, " "))),

		mcp.WithTitleAnnotation(sandboxConfig.Name()),
		mcp.WithReadOnlyHintAnnotation(sandboxConfig.Hints.IsReadOnly(sandboxConfig.Mount.ReadOnly, sandboxConfig.Security.ReadOnly)),
		mcp.WithDestructiveHintAnnotation(sandboxConfig.Hints.IsDestructive()),
		mcp.WithIdempotentHintAnnotation(sandboxConfig.Hints.IsIdempotent()),
		mcp.WithOpenWorldHintAnnotation(sandboxConfig.Hints.IsExternalInteraction(sandboxConfig.Security.Network)),
	}

	// Add any specific additional files if provided in the config
	for _, file := range sandboxConfig.Parameters.Files {
		options = append(options, withFile(file.ParamName(), file.Description, true))
	}

	// Allow adding more files if enabled
	if sandboxConfig.Parameters.AdditionalFiles {
		options = append(options, withAdditionalFiles())
	}

	// Return a new tool with the tool name and provided options
	return mcp.NewTool(sandboxConfig.Id, options...)
}

// NewSandboxToolHandler creates a handler function for a sandbox tool using Nix
func NewSandboxToolHandler(sandboxConfig *config.SandboxConfig) func(context.Context, mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	// Return the handler function that will be run when the tool is called
	return func(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		// Ensure Nix executor is initialized
		if nixExecutor == nil {
			return nil, fmt.Errorf("Nix executor not initialized")
		}

		// withEntrypoint ToolOption
		// Get the contents of the entrypoint file from the request
		entrypointFile := config.SandboxFile{Name: sandboxConfig.Entrypoint}
		entrypointParam := entrypointFile.ParamName()
		entrypointContent, ok := request.Params.Arguments[entrypointParam].(string)
		if !ok || entrypointContent == "" {
			return nil, fmt.Errorf("%s file is required", sandboxConfig.Entrypoint)
		}

		// Collect additional files
		additionalFiles := make(map[string]string)

		// withFile ToolOption
		// Get the contents of the required files from the request
		for _, file := range sandboxConfig.Parameters.Files {
			paramName := file.ParamName()
			content, ok := request.Params.Arguments[paramName].(string)
			if !ok || content == "" {
				return nil, fmt.Errorf("%s file is required", file.Name)
			}
			additionalFiles[file.Name] = content
		}

		// withAdditionalFiles ToolOption
		// Handle additional files if provided
		if files, ok := request.Params.Arguments["files"].([]any); ok {
			for _, file := range files {
				if fileMap, ok := file.(map[string]any); ok {
					filename := fileMap["filename"].(string)
					content := fileMap["content"].(string)
					additionalFiles[filename] = content
				}
			}
		}

		// Execute in Nix sandbox
		output, err := nixExecutor.ExecuteInNixSandbox(ctx, sandboxConfig, entrypointContent, additionalFiles)
		if err != nil {
			return mcp.NewToolResultError(fmt.Sprintf("Nix sandbox execution failed: %v", err)), nil
		}

		return mcp.NewToolResultText(output), nil
	}
}

// generateSandboxDescription creates a comprehensive description of the sandbox environment
func generateSandboxDescription(sandboxConfig *config.SandboxConfig) string {
	// Start with the base description from the config
	description := sandboxConfig.Description

	// Ensure the base description ends with a period if it doesn't already
	if !strings.HasSuffix(description, ".") {
		description += "."
	}

	// Add a space after the description
	description += " "

	// Create a more natural description of the sandbox environment with inline pluralization
	coreText := "cores"
	if sandboxConfig.Resources.CPU == 1 {
		coreText = "core"
	}

	description += fmt.Sprintf("This sandbox uses Nix-native isolation with %d CPU %s, %d MB RAM, and %d processes.",
		sandboxConfig.Resources.CPU,
		coreText,
		sandboxConfig.Resources.Memory,
		sandboxConfig.Resources.Processes)

	// Add network and filesystem information
	if sandboxConfig.Security.Network == "none" {
		description += " It has no network access"
	} else {
		description += fmt.Sprintf(" It has %s network access", sandboxConfig.Security.Network)
	}

	if sandboxConfig.Mount.ReadOnly || sandboxConfig.Security.ReadOnly {
		description += " and read-only filesystem permissions."
	} else {
		description += " and read-write filesystem permissions."
	}

	// Add information about required files
	if len(sandboxConfig.Parameters.Files) > 0 {
		if len(sandboxConfig.Parameters.Files) == 1 {
			file := sandboxConfig.Parameters.Files[0]
			description += fmt.Sprintf(" It requires a `%s` file", file.Name)
			if file.Description != "" {
				description += fmt.Sprintf(" (%s)", file.Description)
			}
		} else {
			description += " It requires the following files:"
			for i, file := range sandboxConfig.Parameters.Files {
				if i > 0 {
					if i == len(sandboxConfig.Parameters.Files)-1 {
						description += " and"
					} else {
						description += ","
					}
				}
				description += fmt.Sprintf(" `%s`", file.Name)
				if file.Description != "" {
					description += fmt.Sprintf(" (%s)", file.Description)
				}
			}
		}

		if sandboxConfig.Parameters.AdditionalFiles {
			description += " and supports uploading additional files."
		} else {
			description += "."
		}
	} else if sandboxConfig.Parameters.AdditionalFiles {
		description += " It supports uploading additional files."
	}

	// Add timeout information
	description += fmt.Sprintf(" The execution is limited to %d seconds.", sandboxConfig.TimeoutRaw)

	return description
}
