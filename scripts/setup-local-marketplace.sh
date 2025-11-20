#!/bin/bash

#######################################
# Local Marketplace Testing Setup
#
# Registers CCPM as a local marketplace plugin
# for testing before publishing to marketplace
#
# Usage:
#   ./scripts/setup-local-marketplace.sh --install
#   ./scripts/setup-local-marketplace.sh --uninstall
#   ./scripts/setup-local-marketplace.sh --verify
#######################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PLUGIN_DIR="$PROJECT_ROOT/.claude-plugin"
PLUGIN_JSON="$PLUGIN_DIR/plugin.json"

# Claude Code directories
CLAUDE_HOME="${CLAUDE_HOME:-.claude}"
PLUGINS_REGISTRY_DIR="$HOME/$CLAUDE_HOME/plugins"
LOCAL_PLUGIN_SYMLINK="$PLUGINS_REGISTRY_DIR/ccpm-local"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

check_plugin_structure() {
    log_info "Checking plugin structure..."

    if [[ ! -f "$PLUGIN_JSON" ]]; then
        log_error "Missing $PLUGIN_JSON"
        return 1
    fi

    # Validate JSON
    if ! jq empty "$PLUGIN_JSON" 2>/dev/null; then
        log_error "Invalid JSON in plugin.json"
        return 1
    fi

    log_success "Plugin structure is valid"
    return 0
}

install_local_plugin() {
    log_info "Installing local CCPM plugin..."

    # Create plugins directory if it doesn't exist
    if [[ ! -d "$PLUGINS_REGISTRY_DIR" ]]; then
        log_info "Creating $PLUGINS_REGISTRY_DIR..."
        mkdir -p "$PLUGINS_REGISTRY_DIR"
    fi

    # Remove existing symlink if present
    if [[ -L "$LOCAL_PLUGIN_SYMLINK" ]]; then
        log_warn "Removing existing symlink: $LOCAL_PLUGIN_SYMLINK"
        rm "$LOCAL_PLUGIN_SYMLINK"
    fi

    # Create symlink to local plugin
    log_info "Creating symlink: $PLUGIN_DIR -> $LOCAL_PLUGIN_SYMLINK"
    ln -s "$PLUGIN_DIR" "$LOCAL_PLUGIN_SYMLINK"

    log_success "Symlink created successfully"

    # Verify installation
    if verify_installation; then
        log_success "Local marketplace plugin installed"
        return 0
    else
        log_error "Plugin installation verification failed"
        return 1
    fi
}

uninstall_local_plugin() {
    log_info "Uninstalling local CCPM plugin..."

    if [[ ! -L "$LOCAL_PLUGIN_SYMLINK" ]]; then
        log_warn "Local plugin symlink not found at $LOCAL_PLUGIN_SYMLINK"
        return 0
    fi

    log_info "Removing symlink: $LOCAL_PLUGIN_SYMLINK"
    rm "$LOCAL_PLUGIN_SYMLINK"

    log_success "Local plugin uninstalled"
    return 0
}

verify_installation() {
    log_info "Verifying plugin installation..."

    # Check symlink exists
    if [[ ! -L "$LOCAL_PLUGIN_SYMLINK" ]]; then
        log_error "Plugin symlink not found"
        return 1
    fi

    # Check symlink points to correct location
    local target=$(readlink "$LOCAL_PLUGIN_SYMLINK")
    if [[ "$target" != "$PLUGIN_DIR" ]]; then
        log_error "Plugin symlink points to wrong location: $target"
        return 1
    fi

    log_success "Symlink is correct: $LOCAL_PLUGIN_SYMLINK -> $target"

    # Check plugin files are accessible
    local plugin_name=$(jq -r '.name' "$PLUGIN_JSON")
    local commands_dir=$(jq -r '.commands' "$PLUGIN_JSON")
    local commands_path="$PLUGIN_DIR/$commands_dir"

    if [[ ! -d "$commands_path" ]]; then
        log_error "Commands directory not found: $commands_path"
        return 1
    fi

    local command_count=$(find "$commands_path" -name "*.md" | wc -l)
    log_success "Commands discoverable: $command_count commands found"

    # Check agents if defined
    if jq -e '.agents' "$PLUGIN_JSON" >/dev/null 2>&1; then
        local agent_count=$(jq '.agents | length' "$PLUGIN_JSON")
        log_success "Agents defined: $agent_count agents"
    fi

    log_success "Plugin verification successful"
    return 0
}

show_plugin_info() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                 Local Plugin Information                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Read plugin metadata
    local name=$(jq -r '.name' "$PLUGIN_JSON")
    local version=$(jq -r '.version' "$PLUGIN_JSON")
    local description=$(jq -r '.description' "$PLUGIN_JSON" | head -c 60)
    local commands_dir=$(jq -r '.commands' "$PLUGIN_JSON")

    echo -e "Name:           ${GREEN}$name${NC}"
    echo -e "Version:        ${GREEN}$version${NC}"
    echo -e "Description:    ${GREEN}$description...${NC}"
    echo -e "Location:       ${GREEN}$PLUGIN_DIR${NC}"
    echo -e "Symlink:        ${GREEN}$LOCAL_PLUGIN_SYMLINK${NC}"
    echo ""

    # Count components
    local command_count=$(find "$PLUGIN_DIR/$commands_dir" -name "*.md" 2>/dev/null | wc -l || echo 0)
    local agent_count=$(find "$PLUGIN_DIR/agents" -name "*.md" 2>/dev/null | wc -l || echo 0)
    local skill_count=$(find "$PLUGIN_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l || echo 0)
    local hook_count=$(find "$PLUGIN_DIR/hooks" -name "*.prompt" -o -name "*.sh" 2>/dev/null | wc -l || echo 0)

    echo -e "Components:"
    echo -e "  Commands:       ${BLUE}$command_count${NC}"
    echo -e "  Agents:         ${BLUE}$agent_count${NC}"
    echo -e "  Skills:         ${BLUE}$skill_count${NC}"
    echo -e "  Hooks:          ${BLUE}$hook_count${NC}"
    echo ""

    # Claude Code version
    if command -v claude &> /dev/null; then
        local claude_version=$(claude --version 2>/dev/null | head -1 || echo "unknown")
        echo -e "Claude Code:    ${BLUE}$claude_version${NC}"
    else
        echo -e "Claude Code:    ${YELLOW}not found in PATH${NC}"
    fi

    echo ""
}

test_plugin_loading() {
    log_info "Testing plugin loading..."

    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        return 1
    fi

    # Test that all referenced files exist
    local errors=0

    # Check commands path (can be absolute or relative)
    local commands_path=$(jq -r '.commands' "$PLUGIN_JSON")
    local commands_full_path="$PLUGIN_DIR/$commands_path"

    # Handle relative paths
    if [[ ! "$commands_path" = /* ]]; then
        commands_full_path="$PLUGIN_DIR/$commands_path"
    else
        commands_full_path="$commands_path"
    fi

    if [[ ! -d "$commands_full_path" ]]; then
        # Also try just the commands_path in case it's documented differently
        if [[ -d "$PLUGIN_DIR/commands" ]]; then
            log_success "Commands path accessible (found at ./commands)"
        else
            log_error "Commands path not found: $commands_path"
            ((errors++))
        fi
    else
        log_success "Commands path accessible"
    fi

    # Check agents if referenced
    if jq -e '.agents' "$PLUGIN_JSON" >/dev/null 2>&1; then
        local agents=$(jq -r '.agents[]' "$PLUGIN_JSON")
        local agent_errors=0
        while IFS= read -r agent; do
            if [[ ! -f "$PLUGIN_DIR/$agent" ]]; then
                # Try without the ./agents prefix
                if [[ -f "$PLUGIN_DIR/agents/$(basename "$agent")" ]]; then
                    log_success "Agent file found: $(basename "$agent")"
                else
                    log_error "Agent file not found: $agent"
                    ((agent_errors++))
                fi
            else
                log_success "Agent file found: $agent"
            fi
        done <<< "$agents"
        ((errors = errors + agent_errors))
    fi

    return $([[ $errors -eq 0 ]] && echo 0 || echo 1)
}

show_usage() {
    cat << 'EOF'
Local Marketplace Testing Setup

Usage: ./scripts/setup-local-marketplace.sh [COMMAND]

Commands:
  --install       Install plugin as local marketplace plugin (default)
  --uninstall     Remove local marketplace plugin
  --verify        Verify plugin installation
  --info          Show plugin information
  --test          Test plugin loading
  --help          Show this help message

Examples:
  # Install for local testing
  ./scripts/setup-local-marketplace.sh --install

  # Verify installation
  ./scripts/setup-local-marketplace.sh --verify

  # Show plugin info
  ./scripts/setup-local-marketplace.sh --info

  # Clean up after testing
  ./scripts/setup-local-marketplace.sh --uninstall

Environment Variables:
  CLAUDE_HOME     Claude Code configuration directory (default: .claude)

Notes:
  - Creates a symlink to the plugin directory
  - No files are copied, just symlinked
  - Safe to run multiple times
  - Can be uninstalled cleanly

EOF
}

# Main
main() {
    local command="${1:-install}"

    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          Local Marketplace Testing Setup                     ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Always check plugin structure first
    if ! check_plugin_structure; then
        exit 1
    fi
    echo ""

    case "$command" in
        --install)
            install_local_plugin
            show_plugin_info
            ;;
        --uninstall)
            uninstall_local_plugin
            ;;
        --verify)
            verify_installation
            show_plugin_info
            ;;
        --info)
            show_plugin_info
            ;;
        --test)
            test_plugin_loading
            ;;
        --help)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
