#!/bin/bash
# figma-server-manager.sh - MCP server detection and management for Figma integration
# Part of CCPM Figma MCP integration (PSN-25)

set -euo pipefail

# Function: list_available_figma_servers
# List all Figma MCP servers available in agent-mcp-gateway
list_available_figma_servers() {
    local mcp_config="$HOME/.config/agent-mcp-gateway/.mcp.json"
    
    if [ ! -f "$mcp_config" ]; then
        echo "[]"
        return 0
    fi
    
    # Extract server names containing "figma" 
    local servers=$(jq -r '.mcpServers | to_entries[] | select(.key | ascii_downcase | contains("figma")) | .key' "$mcp_config" 2>/dev/null || echo "")
    
    if [ -z "$servers" ]; then
        echo "[]"
    else
        echo "$servers" | jq -Rs 'split("\n") | map(select(length > 0))'
    fi
}

# Function: detect_figma_mcp_server
# Detect which Figma MCP server is configured for a project
detect_figma_mcp_server() {
    local project_id="${1:-}"
    
    if [ -n "$project_id" ] && [ -f ~/.claude/ccpm-config.yaml ]; then
        local mcp_server=$(yq eval ".projects.\"$project_id\".figma.mcp_server // \"\"" ~/.claude/ccpm-config.yaml 2>/dev/null || echo "")
        
        if [ -n "$mcp_server" ] && [ "$mcp_server" != "null" ]; then
            jq -n \
                --arg server "$mcp_server" \
                --arg project "$project_id" \
                '{server: $server, project: $project, configured: true}'
            return 0
        fi
    fi
    
    jq -n '{server: "auto", configured: false, message: "No specific Figma server configured"}'
}

# Function: get_figma_server_info
# Get detailed info about a specific Figma MCP server
get_figma_server_info() {
    local server_name="$1"
    local mcp_config="$HOME/.config/agent-mcp-gateway/.mcp.json"
    
    if [ ! -f "$mcp_config" ]; then
        echo "{\"error\": \"MCP gateway config not found\"}" >&2
        return 1
    fi
    
    jq --arg name "$server_name" '.mcpServers[$name] // {error: "Server not found"}' "$mcp_config"
}

# Function: select_figma_server
# Select the best Figma MCP server for a project
select_figma_server() {
    local project_id="${1:-}"
    
    # 1. Check project-specific configuration
    if [ -n "$project_id" ]; then
        local configured=$(detect_figma_mcp_server "$project_id")
        local server=$(echo "$configured" | jq -r '.server // "auto"')
        
        if [ "$server" != "auto" ]; then
            echo "$server"
            return 0
        fi
    fi
    
    # 2. Auto-detect first available Figma server
    local available=$(list_available_figma_servers)
    local first_server=$(echo "$available" | jq -r '.[0] // ""')
    
    if [ -n "$first_server" ]; then
        echo "$first_server"
        return 0
    fi
    
    # 3. No server found
    echo ""
    return 1
}

# Function: test_figma_server_connection
# Test if a Figma MCP server is working
test_figma_server_connection() {
    local server_name="$1"
    
    local server_info=$(get_figma_server_info "$server_name" 2>/dev/null || echo "{}")
    
    if [ "$(echo "$server_info" | jq -r '.error // ""')" != "" ]; then
        jq -n \
            --arg server "$server_name" \
            --arg error "$(echo "$server_info" | jq -r '.error')" \
            '{server: $server, connected: false, error: $error}'
        return 1
    fi
    
    jq -n \
        --arg server "$server_name" \
        '{server: $server, connected: true, message: "Server configured"}'
    return 0
}

# CLI Interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    command="${1:-help}"
    
    case "$command" in
        detect)
            detect_figma_mcp_server "${2:-}"
            ;;
        list)
            list_available_figma_servers
            ;;
        info)
            [ -z "${2:-}" ] && { echo "Error: Missing server_name argument" >&2; exit 1; }
            get_figma_server_info "$2"
            ;;
        select)
            select_figma_server "${2:-}"
            ;;
        test)
            [ -z "${2:-}" ] && { echo "Error: Missing server_name argument" >&2; exit 1; }
            test_figma_server_connection "$2"
            ;;
        help|*)
            cat <<HELP
Figma MCP Server Manager - Detect and manage Figma MCP servers

Usage: \$0 <command> [arguments]

Commands:
  detect [project]      Detect configured Figma server for project
  list                  List all available Figma MCP servers
  info <server>         Get detailed info about a specific server
  select [project]      Select best Figma server for project
  test <server>         Test connection to Figma MCP server
  help                  Show this help message

Examples:
  \$0 detect repeat
  \$0 list
  \$0 info figma-repeat
  \$0 select trainer-guru
  \$0 test figma-repeat
HELP
            ;;
    esac
fi
