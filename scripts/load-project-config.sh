#!/usr/bin/env bash
#
# CCPM Project Configuration Loader
#
# This script loads and validates CCPM project configuration from .ccpm/project.yaml
# Usage: ./scripts/load-project-config.sh [--validate-only] [--get KEY]
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration paths (in order of precedence)
CONFIG_PATHS=(
  ".ccpm/project.yaml"
  ".ccpm/project.yml"
  "project.yaml"
  "project.yml"
)

# Find configuration file
find_config_file() {
  local current_dir="$PWD"

  # Search up the directory tree
  while [[ "$current_dir" != "/" ]]; do
    for config_path in "${CONFIG_PATHS[@]}"; do
      if [[ -f "$current_dir/$config_path" ]]; then
        echo "$current_dir/$config_path"
        return 0
      fi
    done
    current_dir="$(dirname "$current_dir")"
  done

  return 1
}

# Validate YAML syntax
validate_yaml() {
  local config_file="$1"

  if ! command -v yq &> /dev/null; then
    echo -e "${YELLOW}Warning: 'yq' not found. YAML validation skipped.${NC}" >&2
    echo -e "${YELLOW}Install yq: brew install yq${NC}" >&2
    return 0
  fi

  if ! yq eval '.' "$config_file" > /dev/null 2>&1; then
    echo -e "${RED}Error: Invalid YAML syntax in $config_file${NC}" >&2
    return 1
  fi

  echo -e "${GREEN}✓ YAML syntax valid${NC}" >&2
  return 0
}

# Validate required fields
validate_required_fields() {
  local config_file="$1"
  local required_fields=(
    ".project.id"
    ".project.name"
    ".linear.team"
    ".linear.project"
  )

  local missing_fields=()

  for field in "${required_fields[@]}"; do
    if ! yq eval "$field" "$config_file" > /dev/null 2>&1 || \
       [[ "$(yq eval "$field" "$config_file")" == "null" ]]; then
      missing_fields+=("$field")
    fi
  done

  if [[ ${#missing_fields[@]} -gt 0 ]]; then
    echo -e "${RED}Error: Missing required fields:${NC}" >&2
    for field in "${missing_fields[@]}"; do
      echo -e "${RED}  - $field${NC}" >&2
    done
    return 1
  fi

  echo -e "${GREEN}✓ All required fields present${NC}" >&2
  return 0
}

# Get configuration value
get_config_value() {
  local config_file="$1"
  local key="$2"
  local default="${3:-}"

  if ! command -v yq &> /dev/null; then
    echo -e "${RED}Error: 'yq' is required to read configuration${NC}" >&2
    echo -e "${YELLOW}Install yq: brew install yq${NC}" >&2
    exit 1
  fi

  local value
  value="$(yq eval ".$key" "$config_file" 2>/dev/null || echo "null")"

  if [[ "$value" == "null" ]] || [[ -z "$value" ]]; then
    if [[ -n "$default" ]]; then
      echo "$default"
    else
      echo "null"
    fi
  else
    echo "$value"
  fi
}

# Display project configuration summary
display_config() {
  local config_file="$1"

  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}CCPM Project Configuration${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${GREEN}Configuration File:${NC} $config_file"
  echo ""

  # Project info
  echo -e "${GREEN}Project:${NC}"
  echo "  ID:          $(get_config_value "$config_file" "project.id")"
  echo "  Name:        $(get_config_value "$config_file" "project.name")"
  echo "  Description: $(get_config_value "$config_file" "project.description" "N/A")"
  echo ""

  # Linear config
  echo -e "${GREEN}Linear:${NC}"
  echo "  Team:        $(get_config_value "$config_file" "linear.team")"
  echo "  Project:     $(get_config_value "$config_file" "linear.project")"
  echo ""

  # External PM
  local pm_enabled=$(get_config_value "$config_file" "external_pm.enabled" "false")
  local pm_type=$(get_config_value "$config_file" "external_pm.type" "none")
  echo -e "${GREEN}External PM:${NC}"
  echo "  Enabled:     $pm_enabled"
  if [[ "$pm_enabled" == "true" ]]; then
    echo "  Type:        $pm_type"

    if [[ "$pm_type" == "jira" ]]; then
      local jira_enabled=$(get_config_value "$config_file" "external_pm.jira.enabled" "false")
      if [[ "$jira_enabled" == "true" ]]; then
        echo "  Jira Project: $(get_config_value "$config_file" "external_pm.jira.project_key")"
      fi
    fi
  fi
  echo ""

  # Code repository
  local repo_type=$(get_config_value "$config_file" "code_repository.type" "N/A")
  echo -e "${GREEN}Code Repository:${NC}"
  echo "  Type:        $repo_type"
  if [[ "$repo_type" == "bitbucket" ]]; then
    echo "  Workspace:   $(get_config_value "$config_file" "code_repository.bitbucket.workspace")"
    echo "  Repo:        $(get_config_value "$config_file" "code_repository.bitbucket.repo_slug")"
  elif [[ "$repo_type" == "github" ]]; then
    echo "  Owner:       $(get_config_value "$config_file" "code_repository.github.owner")"
    echo "  Repo:        $(get_config_value "$config_file" "code_repository.github.repo")"
  fi
  echo ""

  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Generate JSON output for MCP consumption
generate_json_output() {
  local config_file="$1"

  if ! command -v yq &> /dev/null; then
    echo '{"error": "yq not installed"}' | jq .
    exit 1
  fi

  yq eval -o=json '.' "$config_file" | jq .
}

# Main function
main() {
  local validate_only=false
  local get_key=""
  local output_format="summary"  # summary, json, value

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --validate-only)
        validate_only=true
        shift
        ;;
      --get)
        get_key="$2"
        output_format="value"
        shift 2
        ;;
      --json)
        output_format="json"
        shift
        ;;
      --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --validate-only     Only validate configuration, don't display"
        echo "  --get KEY           Get specific configuration value"
        echo "  --json              Output configuration as JSON"
        echo "  --help, -h          Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                                  # Display configuration summary"
        echo "  $0 --validate-only                 # Only validate"
        echo "  $0 --get project.id                # Get project ID"
        echo "  $0 --get linear.team               # Get Linear team"
        echo "  $0 --json                          # Output as JSON"
        exit 0
        ;;
      *)
        echo -e "${RED}Unknown option: $1${NC}" >&2
        exit 1
        ;;
    esac
  done

  # Find configuration file
  local config_file
  if ! config_file=$(find_config_file); then
    echo -e "${RED}Error: No CCPM project configuration found${NC}" >&2
    echo -e "${YELLOW}Searched for:${NC}" >&2
    for path in "${CONFIG_PATHS[@]}"; do
      echo -e "${YELLOW}  - $path${NC}" >&2
    done
    echo "" >&2
    echo -e "${YELLOW}Create a configuration file:${NC}" >&2
    echo -e "${YELLOW}  mkdir -p .ccpm${NC}" >&2
    echo -e "${YELLOW}  cp $(dirname "$0")/../project.example.yaml .ccpm/project.yaml${NC}" >&2
    exit 1
  fi

  # Validate configuration
  if ! validate_yaml "$config_file"; then
    exit 1
  fi

  if ! validate_required_fields "$config_file"; then
    exit 1
  fi

  if [[ "$validate_only" == true ]]; then
    echo -e "${GREEN}✓ Configuration valid${NC}"
    exit 0
  fi

  # Output based on format
  case "$output_format" in
    summary)
      display_config "$config_file"
      ;;
    json)
      generate_json_output "$config_file"
      ;;
    value)
      if [[ -z "$get_key" ]]; then
        echo -e "${RED}Error: --get requires a KEY argument${NC}" >&2
        exit 1
      fi
      get_config_value "$config_file" "$get_key"
      ;;
  esac
}

# Run main function
main "$@"
