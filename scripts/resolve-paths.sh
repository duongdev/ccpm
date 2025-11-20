#!/bin/bash
################################################################################
# CCPM Path Resolution Helper Script
#
# Purpose: Dynamically resolve all CCPM path variables for portability
# Usage:   source resolve-paths.sh [--export]
#          resolve_ccpm_paths [--export]
#
# Environment Variables Set:
#   CCPM_PLUGIN_DIR          - Plugin installation root
#   CCPM_COMMANDS_DIR        - Commands directory
#   CCPM_AGENTS_DIR          - Agents directory
#   CCPM_HOOKS_DIR           - Hooks directory
#   CCPM_SKILLS_DIR          - Skills directory
#   CCPM_SCRIPTS_DIR         - Scripts directory
#   CCPM_DOCS_DIR            - Documentation directory
#   CLAUDE_HOME              - User's ~/.claude directory
#   CCPM_CONFIG_FILE         - CCPM configuration file
#   CLAUDE_SETTINGS          - Claude Code settings.json
#   CLAUDE_PLUGINS           - Claude Code plugins directory
#   CLAUDE_LOGS              - Claude Code logs directory
#   CLAUDE_BACKUPS           - Claude Code backups directory
#
# Exit Codes:
#   0 - Success
#   1 - Plugin not found
#   2 - Invalid environment
#   3 - Missing required tools
################################################################################

set -euo pipefail

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
# Handle both sourced and executed contexts
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
  # When sourced, try to find the script directory
  readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

################################################################################
# Utility Functions
################################################################################

# Print colored output
print_status() {
  local status=$1
  local message=$2
  case "$status" in
    success) echo -e "${GREEN}✓${NC} $message" ;;
    error)   echo -e "${RED}✗${NC} $message" >&2 ;;
    warn)    echo -e "${YELLOW}⚠${NC} $message" ;;
    info)    echo -e "${BLUE}ℹ${NC} $message" ;;
  esac
}

# Check if directory exists
dir_exists() {
  [ -d "$1" ] && return 0 || return 1
}

# Check if file exists
file_exists() {
  [ -f "$1" ] && return 0 || return 1
}

# Resolve home directory safely
get_home_dir() {
  if [ -n "${HOME:-}" ]; then
    echo "$HOME"
  elif [ -n "${USERPROFILE:-}" ]; then
    # Windows
    echo "$USERPROFILE"
  else
    print_status error "Cannot determine home directory"
    return 2
  fi
}

################################################################################
# Path Resolution Functions
################################################################################

# Find CCPM plugin installation directory
find_ccpm_plugin() {
  local home_dir
  home_dir=$(get_home_dir) || return 2

  # Check explicit environment variable first
  if [ -n "${CCPM_PLUGIN_DIR:-}" ]; then
    if dir_exists "$CCPM_PLUGIN_DIR"; then
      echo "$CCPM_PLUGIN_DIR"
      return 0
    else
      print_status warn "CCPM_PLUGIN_DIR=$CCPM_PLUGIN_DIR does not exist"
    fi
  fi

  # Check if we're running from within the plugin directory
  local script_dir="$SCRIPT_DIR"
  local plugin_candidate="$(dirname "$script_dir")"
  if [ -d "$plugin_candidate/commands" ] && [ -d "$plugin_candidate/agents" ]; then
    echo "$plugin_candidate"
    return 0
  fi

  # Check standard installation location
  if dir_exists "$home_dir/.claude/plugins/ccpm"; then
    echo "$home_dir/.claude/plugins/ccpm"
    return 0
  fi

  # Check alternative locations
  if dir_exists "$home_dir/.claude/plugins/CCPM"; then
    echo "$home_dir/.claude/plugins/CCPM"
    return 0
  fi

  # Plugin not found
  print_status error "CCPM plugin not found"
  print_status info "Expected location: $home_dir/.claude/plugins/ccpm"
  print_status info "Set CCPM_PLUGIN_DIR environment variable to override"
  return 1
}

# Resolve all CCPM paths
resolve_ccpm_paths() {
  local export_flag=0

  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --export) export_flag=1 ;;
      --help)   show_help; return 0 ;;
      *)        print_status error "Unknown option: $1"; return 1 ;;
    esac
    shift
  done

  # Find plugin directory
  local plugin_dir
  if ! plugin_dir=$(find_ccpm_plugin); then
    print_status error "Failed to resolve CCPM plugin directory"
    return 1
  fi

  # Get home directory
  local home_dir
  if ! home_dir=$(get_home_dir); then
    return 2
  fi

  # Resolve all paths
  local ccpm_commands_dir="$plugin_dir/commands"
  local ccpm_agents_dir="$plugin_dir/agents"
  local ccpm_hooks_dir="$plugin_dir/hooks"
  local ccpm_skills_dir="$plugin_dir/skills"
  local ccpm_scripts_dir="$plugin_dir/scripts"
  local ccpm_docs_dir="$plugin_dir/docs"
  local claude_home="$home_dir/.claude"
  local ccpm_config_file="$claude_home/ccpm-config.yaml"
  local claude_settings="$claude_home/settings.json"
  local claude_plugins="$claude_home/plugins"
  local claude_logs="$claude_home/logs"
  local claude_backups="$claude_home/backups"

  # Verify critical directories exist
  local errors=0
  local checks=(
    "$plugin_dir:CCPM plugin directory"
    "$ccpm_commands_dir:Commands directory"
    "$ccpm_scripts_dir:Scripts directory"
    "$claude_home:Claude home directory"
  )

  for check in "${checks[@]}"; do
    local path="${check%%:*}"
    local name="${check##*:}"
    if ! dir_exists "$path"; then
      print_status error "Missing $name: $path"
      ((errors++))
    fi
  done

  if [ $errors -gt 0 ]; then
    print_status error "Failed to verify all required directories ($errors missing)"
    return 1
  fi

  # Set environment variables
  if [ $export_flag -eq 1 ]; then
    export CCPM_PLUGIN_DIR="$plugin_dir"
    export CCPM_COMMANDS_DIR="$ccpm_commands_dir"
    export CCPM_AGENTS_DIR="$ccpm_agents_dir"
    export CCPM_HOOKS_DIR="$ccpm_hooks_dir"
    export CCPM_SKILLS_DIR="$ccpm_skills_dir"
    export CCPM_SCRIPTS_DIR="$ccpm_scripts_dir"
    export CCPM_DOCS_DIR="$ccpm_docs_dir"
    export CLAUDE_HOME="$claude_home"
    export CCPM_CONFIG_FILE="$ccpm_config_file"
    export CLAUDE_SETTINGS="$claude_settings"
    export CLAUDE_PLUGINS="$claude_plugins"
    export CLAUDE_LOGS="$claude_logs"
    export CLAUDE_BACKUPS="$claude_backups"
  else
    # Just output the values
    declare -p \
      plugin_dir ccpm_commands_dir ccpm_agents_dir ccpm_hooks_dir \
      ccpm_skills_dir ccpm_scripts_dir ccpm_docs_dir claude_home \
      ccpm_config_file claude_settings claude_plugins claude_logs claude_backups
  fi

  return 0
}

################################################################################
# Verification Functions
################################################################################

# Verify all paths exist
verify_paths() {
  local plugin_dir="${CCPM_PLUGIN_DIR:-}"
  local commands_dir="${CCPM_COMMANDS_DIR:-}"
  local agents_dir="${CCPM_AGENTS_DIR:-}"
  local hooks_dir="${CCPM_HOOKS_DIR:-}"
  local scripts_dir="${CCPM_SCRIPTS_DIR:-}"
  local docs_dir="${CCPM_DOCS_DIR:-}"

  local all_ok=true

  echo ""
  print_status info "Verifying CCPM paths..."
  echo ""

  local checks=(
    "$plugin_dir:Plugin root"
    "$commands_dir:Commands"
    "$agents_dir:Agents"
    "$hooks_dir:Hooks"
    "$scripts_dir:Scripts"
    "$docs_dir:Documentation"
  )

  for check in "${checks[@]}"; do
    local path="${check%%:*}"
    local name="${check##*:}"

    if [ -z "$path" ]; then
      print_status error "$name: NOT SET"
      all_ok=false
    elif dir_exists "$path"; then
      print_status success "$name: $path"
    else
      print_status error "$name: $path (NOT FOUND)"
      all_ok=false
    fi
  done

  echo ""

  if [ "$all_ok" = true ]; then
    print_status success "All paths verified successfully"
    return 0
  else
    print_status error "Some paths are missing or invalid"
    return 1
  fi
}

# Display resolved paths
show_paths() {
  echo ""
  echo "CCPM Path Resolution Status"
  echo "============================"
  echo ""
  echo "Plugin Directory:"
  echo "  CCPM_PLUGIN_DIR=$CCPM_PLUGIN_DIR"
  echo ""
  echo "Plugin Subdirectories:"
  echo "  CCPM_COMMANDS_DIR=$CCPM_COMMANDS_DIR"
  echo "  CCPM_AGENTS_DIR=$CCPM_AGENTS_DIR"
  echo "  CCPM_HOOKS_DIR=$CCPM_HOOKS_DIR"
  echo "  CCPM_SKILLS_DIR=$CCPM_SKILLS_DIR"
  echo "  CCPM_SCRIPTS_DIR=$CCPM_SCRIPTS_DIR"
  echo "  CCPM_DOCS_DIR=$CCPM_DOCS_DIR"
  echo ""
  echo "Claude Code Directories:"
  echo "  CLAUDE_HOME=$CLAUDE_HOME"
  echo "  CLAUDE_SETTINGS=$CLAUDE_SETTINGS"
  echo "  CLAUDE_PLUGINS=$CLAUDE_PLUGINS"
  echo "  CLAUDE_LOGS=$CLAUDE_LOGS"
  echo "  CLAUDE_BACKUPS=$CLAUDE_BACKUPS"
  echo ""
  echo "CCPM Configuration:"
  echo "  CCPM_CONFIG_FILE=$CCPM_CONFIG_FILE"
  echo ""
}

# Show help message
show_help() {
  cat << 'EOF'
CCPM Path Resolution Helper
===========================

Usage: resolve-paths.sh [COMMAND] [OPTIONS]

Commands:
  help              Show this help message
  verify            Verify all resolved paths exist
  show              Display all resolved paths
  export            Export paths as environment variables (default)

Options:
  --export          Export variables (can be used with other commands)
  --help            Show this help message

Examples:
  # Resolve and export paths
  source resolve-paths.sh

  # Resolve and export, then verify
  source resolve-paths.sh && verify_paths

  # Verify paths are correct
  ./resolve-paths.sh verify

  # Show resolved paths
  ./resolve-paths.sh show

Environment Variables (OUTPUT):
  CCPM_PLUGIN_DIR           Plugin installation root directory
  CCPM_COMMANDS_DIR         Commands directory ($CCPM_PLUGIN_DIR/commands)
  CCPM_AGENTS_DIR           Agents directory ($CCPM_PLUGIN_DIR/agents)
  CCPM_HOOKS_DIR            Hooks directory ($CCPM_PLUGIN_DIR/hooks)
  CCPM_SKILLS_DIR           Skills directory ($CCPM_PLUGIN_DIR/skills)
  CCPM_SCRIPTS_DIR          Scripts directory ($CCPM_PLUGIN_DIR/scripts)
  CCPM_DOCS_DIR             Documentation directory ($CCPM_PLUGIN_DIR/docs)
  CLAUDE_HOME               User's Claude Code home (~/.claude)
  CCPM_CONFIG_FILE          CCPM config file ($CLAUDE_HOME/ccpm-config.yaml)
  CLAUDE_SETTINGS           Claude settings ($CLAUDE_HOME/settings.json)
  CLAUDE_PLUGINS            Plugins directory ($CLAUDE_HOME/plugins)
  CLAUDE_LOGS               Logs directory ($CLAUDE_HOME/logs)
  CLAUDE_BACKUPS            Backups directory ($CLAUDE_HOME/backups)

Environment Variables (INPUT):
  CCPM_PLUGIN_DIR           Override plugin directory detection
  HOME                      User home directory

Exit Codes:
  0                         Success
  1                         Plugin not found or verification failed
  2                         Environment error (HOME not set)
  3                         Missing required tools

For more information, visit:
  https://github.com/duongdev/ccpm

EOF
}

################################################################################
# Main Entry Point
################################################################################

main() {
  # Determine if we're being sourced or executed
  if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    # Being sourced - resolve and export paths
    resolve_ccpm_paths --export || return $?
    return 0
  fi

  # Being executed directly
  case "${1:-export}" in
    help)
      show_help
      exit 0
      ;;
    verify)
      resolve_ccpm_paths --export || exit $?
      verify_paths || exit $?
      exit 0
      ;;
    show)
      resolve_ccpm_paths --export || exit $?
      show_paths
      exit 0
      ;;
    export|"")
      resolve_ccpm_paths --export || exit $?
      show_paths
      exit 0
      ;;
    *)
      print_status error "Unknown command: $1"
      echo "Use '$SCRIPT_NAME help' for usage information"
      exit 1
      ;;
  esac
}

# Run main function
main "$@"
