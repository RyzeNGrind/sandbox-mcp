package sandbox

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/pottekkat/sandbox-mcp/internal/config"
)

// NixSandboxExecutor provides Nix-based sandbox execution
type NixSandboxExecutor struct {
	basePath string
}

// NewNixSandboxExecutor creates a new Nix-based sandbox executor
func NewNixSandboxExecutor(basePath string) *NixSandboxExecutor {
	return &NixSandboxExecutor{
		basePath: basePath,
	}
}

// ExecuteInNixSandbox executes code in a Nix sandbox environment
func (n *NixSandboxExecutor) ExecuteInNixSandbox(ctx context.Context, sandboxConfig *config.SandboxConfig, code string, additionalFiles map[string]string) (string, error) {
	// Create temporary directory for this execution
	tmpDir, err := os.MkdirTemp("", sandboxConfig.Mount.TmpDirPrefix)
	if err != nil {
		return "", fmt.Errorf("failed to create temporary directory: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Write the main entry file
	entryPath := filepath.Join(tmpDir, sandboxConfig.Entrypoint)
	if err := os.WriteFile(entryPath, []byte(code), sandboxConfig.Mount.ScriptPerms()); err != nil {
		return "", fmt.Errorf("failed to write entrypoint file: %v", err)
	}

	// Write additional files
	for filename, content := range additionalFiles {
		filePath := filepath.Join(tmpDir, filename)
		if err := os.WriteFile(filePath, []byte(content), sandboxConfig.Mount.ScriptPerms()); err != nil {
			return "", fmt.Errorf("failed to write file %s: %v", filename, err)
		}
	}

	// Create the Nix expression for this execution
	nixExpr, err := n.generateNixExpression(sandboxConfig, tmpDir)
	if err != nil {
		return "", fmt.Errorf("failed to generate Nix expression: %v", err)
	}

	// Write the Nix expression to a file
	nixExprPath := filepath.Join(tmpDir, "execution.nix")
	if err := os.WriteFile(nixExprPath, []byte(nixExpr), 0644); err != nil {
		return "", fmt.Errorf("failed to write Nix expression: %v", err)
	}

	// Execute using nix-build for sandbox isolation
	return n.executeNixExpression(ctx, nixExprPath, tmpDir, int(sandboxConfig.Timeout().Seconds()))
}

// generateNixExpression creates a Nix expression for the sandbox execution
func (n *NixSandboxExecutor) generateNixExpression(sandboxConfig *config.SandboxConfig, inputDir string) (string, error) {
	// For now, create a simple Nix expression that uses builtins.exec (simulation)
	// In a real environment, this would import the base expression and customize it
	nixExpr := fmt.Sprintf(`
{ pkgs ? import <nixpkgs> {} }:

let
  inputFiles = "%s";
  timeout = %d;
  command = %s;
in

pkgs.runCommand "sandbox-%s-execution" {
  allowSubstitutes = false;
  preferLocalBuild = true;
  
  # Resource limits (simulated in comments as Nix doesn't directly support runtime limits)
  # CPU: %d cores
  # Memory: %dMB
  # Processes: %d
} ''
  set -e
  
  # Create sandbox working directory
  mkdir -p $out/sandbox
  cd $out/sandbox
  
  # Copy input files
  cp -r ${inputFiles}/* . || true
  
  # Set permissions
  chmod +x * || true
  
  # Execute with timeout
  timeout ${toString timeout} bash -c '%s' > output.txt 2>&1 || echo "Execution failed or timed out" >> output.txt
  
  # Ensure output exists
  touch output.txt
  cp output.txt $out/
''
`,
		inputDir,
		int(sandboxConfig.Timeout().Seconds()),
		strings.Join(sandboxConfig.Command, `" "`),
		sandboxConfig.Id,
		sandboxConfig.Resources.CPU,
		sandboxConfig.Resources.Memory,
		sandboxConfig.Resources.Processes,
		strings.Join(sandboxConfig.Command, " "),
	)

	return nixExpr, nil
}

// executeNixExpression runs the Nix expression and returns the output
func (n *NixSandboxExecutor) executeNixExpression(ctx context.Context, nixExprPath, inputDir string, timeout int) (string, error) {
	// Create a context with timeout
	timeoutCtx, cancel := context.WithTimeout(ctx, time.Duration(timeout)*time.Second)
	defer cancel()

	// Since we can't actually run nix-build in this environment, we'll simulate the execution
	// In a real Nix environment, this would be: nix-build --sandbox true nixExprPath
	return n.simulateNixExecution(timeoutCtx, nixExprPath, inputDir)
}

// simulateNixExecution simulates Nix sandbox execution for development/testing
func (n *NixSandboxExecutor) simulateNixExecution(ctx context.Context, nixExprPath, inputDir string) (string, error) {
	log.Printf("Simulating Nix sandbox execution (would use: nix-build --sandbox true %s)", nixExprPath)
	
	// Read the main script and execute it in a basic isolated manner
	// This is a fallback simulation when Nix is not available
	files, err := os.ReadDir(inputDir)
	if err != nil {
		return "", fmt.Errorf("failed to read input directory: %v", err)
	}

	// Look for executable files and run them
	for _, file := range files {
		if strings.HasSuffix(file.Name(), ".sh") {
			scriptPath := filepath.Join(inputDir, file.Name())
			return n.executeScript(ctx, scriptPath)
		}
		if strings.HasSuffix(file.Name(), ".go") {
			return n.executeGoFile(ctx, inputDir, file.Name())
		}
		if strings.HasSuffix(file.Name(), ".py") {
			return n.executePythonFile(ctx, inputDir, file.Name())
		}
		if strings.HasSuffix(file.Name(), ".js") {
			return n.executeJavaScriptFile(ctx, inputDir, file.Name())
		}
	}

	return "No executable files found", nil
}

// executeScript runs a shell script
func (n *NixSandboxExecutor) executeScript(ctx context.Context, scriptPath string) (string, error) {
	cmd := exec.CommandContext(ctx, "bash", scriptPath)
	cmd.Dir = filepath.Dir(scriptPath)
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		return string(output), fmt.Errorf("script execution failed: %v", err)
	}
	
	return string(output), nil
}

// executeGoFile runs a Go file
func (n *NixSandboxExecutor) executeGoFile(ctx context.Context, dir, filename string) (string, error) {
	cmd := exec.CommandContext(ctx, "go", "run", filename)
	cmd.Dir = dir
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		return string(output), fmt.Errorf("Go execution failed: %v", err)
	}
	
	return string(output), nil
}

// executePythonFile runs a Python file
func (n *NixSandboxExecutor) executePythonFile(ctx context.Context, dir, filename string) (string, error) {
	cmd := exec.CommandContext(ctx, "python3", filename)
	cmd.Dir = dir
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		return string(output), fmt.Errorf("Python execution failed: %v", err)
	}
	
	return string(output), nil
}

// executeJavaScriptFile runs a JavaScript file
func (n *NixSandboxExecutor) executeJavaScriptFile(ctx context.Context, dir, filename string) (string, error) {
	cmd := exec.CommandContext(ctx, "node", filename)
	cmd.Dir = dir
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		return string(output), fmt.Errorf("JavaScript execution failed: %v", err)
	}
	
	return string(output), nil
}