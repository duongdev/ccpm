#!/bin/bash
################################################################################
# CCPM Path Configuration Helper
#
# Purpose: Centralized path resolution for all CCPM scripts
# Usage:   source scripts/.ccpm-paths.sh
#
# This file is sourced by other scripts to provide consistent path resolution
# across the plugin, eliminating hardcoded absolute paths.
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
################################################################################

# Get script's directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve plugin directory - try multiple methods for maximum compatibility
resolve_plugin_dir() {
  # Method 1: Explicit environment variable
  if [ -n "${CCPM_PLUGIN_DIR:-}" ] && [ -d "$CCPM_PLUGIN_DIR" ]; then
    echo "$CCPM_PLUGIN_DIR"
    return 0
  fi

  # Method 2: Running from within plugin (parent of scripts dir)
  local parent_dir="$(dirname "$SCRIPT_DIR")"
  if [ -d "$parent_dir/commands" ] && [ -d "$parent_dir/agents" ]; then
    echo "$parent_dir"
    return 0
  fi

  # Method 3: Standard installation location
  if [ -d "$HOME/.claude/plugins/ccpm" ]; then
    echo "$HOME/.claude/plugins/ccpm"
    return 0
  fi

  # Method 4: Alternative capitalization
  if [ -d "$HOME/.claude/plugins/CCPM" ]; then
    echo "$HOME/.claude/plugins/CCPM"
    return 0
  fi

  # Not found
  return 1
}

# Get home directory safely
get_home_dir() {
  if [ -n "${HOME:-}" ]; then
    echo "$HOME"
  elif [ -n "${USERPROFILE:-}" ]; then
    # Windows
    echo "$USERPROFILE"
  else
    return 1
  fi
}

# Resolve all paths
_resolve_paths() {
  # Find plugin directory
  local plugin_dir
  if ! plugin_dir=$(resolve_plugin_dir); then
    echo "Error: Cannot find CCPM plugin directory" >&2
    return 1
  fi

  # Get home directory
  local home_dir
  if ! home_dir=$(get_home_dir); then
    echo "Error: Cannot determine home directory" >&2
    return 1
  fi

  # Export all path variables
  export CCPM_PLUGIN_DIR="$plugin_dir"
  export CCPM_COMMANDS_DIR="$plugin_dir/commands"
  export CCPM_AGENTS_DIR="$plugin_dir/agents"
  export CCPM_HOOKS_DIR="$plugin_dir/hooks"
  export CCPM_SKILLS_DIR="$plugin_dir/skills"
  export CCPM_SCRIPTS_DIR="$plugin_dir/scripts"
  export CCPM_DOCS_DIR="$plugin_dir/docs"
  export CLAUDE_HOME="$home_dir/.claude"
  export CCPM_CONFIG_FILE="$home_dir/.claude/ccpm-config.yaml"
  export CLAUDE_SETTINGS="$home_dir/.claude/settings.json"
  export CLAUDE_PLUGINS="$home_dir/.claude/plugins"
  export CLAUDE_LOGS="$home_dir/.claude/logs"
  export CLAUDE_BACKUPS="$home_dir/.claude/backups"

  return 0
}

# Initialize paths
_resolve_paths
