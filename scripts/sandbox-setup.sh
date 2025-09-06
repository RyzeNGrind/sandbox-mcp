#!/usr/bin/env bash
# Sandbox setup script for secure code execution
set -euo pipefail

# Setup isolated sandbox environment
setup_sandbox() {
    local sandbox_type="$1"
    local working_dir="$2"
    
    # Create isolated environment
    mkdir -p "$working_dir/logs" "$working_dir/results"
    
    # Set proper permissions
    chmod 755 "$working_dir"
    chmod 700 "$working_dir/logs" "$working_dir/results"
    
    echo "Sandbox environment ready at: $working_dir"
}

# Cleanup sandbox after execution
cleanup_sandbox() {
    local working_dir="$1"
    
    # Remove temporary files but preserve logs
    if [[ -d "$working_dir" ]]; then
        find "$working_dir" -type f -name "*.tmp" -delete || true
        echo "Sandbox cleanup completed"
    fi
}

# Main execution
case "${1:-}" in
    setup)
        setup_sandbox "${2:-shell}" "${3:-/tmp/sandbox}"
        ;;
    cleanup)
        cleanup_sandbox "${2:-/tmp/sandbox}"
        ;;
    *)
        echo "Usage: $0 {setup|cleanup} [sandbox_type] [working_dir]"
        exit 1
        ;;
esac