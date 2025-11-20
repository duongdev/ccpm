#!/bin/bash
# figma-data-extractor.sh - Extract design data from Figma via MCP gateway
# Part of CCPM Figma MCP integration (PSN-25) - Phase 2

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/figma-utils.sh" 2>/dev/null || true

# Constants
readonly MAX_RETRIES=3
readonly BACKOFF_BASE=2

# Function: get_mcp_server_type
# Determine the type of Figma MCP server
get_mcp_server_type() {
    local server_name="$1"

    # Check server name patterns
    if echo "$server_name" | grep -qi "official"; then
        echo "official"
    elif echo "$server_name" | grep -qi "glips"; then
        echo "glips"
    elif echo "$server_name" | grep -qi "timholden"; then
        echo "timholden"
    else
        # Auto-detect by checking available tools
        # For now, default to glips (most common)
        echo "glips"
    fi
}

# Function: call_mcp_gateway
# Call MCP gateway with proper error handling
call_mcp_gateway() {
    local server="$1"
    local tool="$2"
    local args="$3"

    # This would be called by Claude Code's MCP integration
    # For now, return a placeholder that indicates MCP call is needed
    jq -n \
        --arg server "$server" \
        --arg tool "$tool" \
        --argjson args "$args" \
        '{
            mcp_call: true,
            server: $server,
            tool: $tool,
            args: $args,
            instruction: "Use mcp__agent-mcp-gateway__execute_tool to call this"
        }'
}

# Function: extract_figma_file_official
# Extract file data using official Figma MCP server
extract_figma_file_official() {
    local file_id="$1"
    local node_id="${2:-}"
    local server="$3"

    if [ -n "$node_id" ]; then
        # Get specific node
        call_mcp_gateway "$server" "getNode" "{\"fileId\": \"$file_id\", \"nodeId\": \"$node_id\"}"
    else
        # Get full file
        call_mcp_gateway "$server" "getFile" "{\"fileId\": \"$file_id\"}"
    fi
}

# Function: extract_figma_file_glips
# Extract file data using GLips community MCP server
extract_figma_file_glips() {
    local file_id="$1"
    local node_id="${2:-}"
    local server="$3"

    local url="https://www.figma.com/file/$file_id"
    if [ -n "$node_id" ]; then
        url="$url?node-id=$node_id"
    fi

    call_mcp_gateway "$server" "getDesignContext" "{\"url\": \"$url\"}"
}

# Function: extract_figma_file_timholden
# Extract file data using TimHolden community MCP server
extract_figma_file_timholden() {
    local file_id="$1"
    local server="$2"

    # TimHolden doesn't support node-specific queries
    call_mcp_gateway "$server" "get-file" "{\"fileKey\": \"$file_id\"}"
}

# Function: extract_figma_data
# Main extraction function with server auto-detection
extract_figma_data() {
    local file_id="$1"
    local server="$2"
    local node_id="${3:-}"

    local server_type=$(get_mcp_server_type "$server")

    case "$server_type" in
        official)
            extract_figma_file_official "$file_id" "$node_id" "$server"
            ;;
        glips)
            extract_figma_file_glips "$file_id" "$node_id" "$server"
            ;;
        timholden)
            extract_figma_file_timholden "$file_id" "$server"
            ;;
        *)
            echo "{\"error\": \"Unknown server type: $server_type\"}" >&2
            return 1
            ;;
    esac
}

# Function: extract_with_retry
# Extract with exponential backoff retry logic
extract_with_retry() {
    local file_id="$1"
    local server="$2"
    local node_id="${3:-}"
    local attempt=1

    while [ $attempt -le $MAX_RETRIES ]; do
        # Call extraction
        result=$(extract_figma_data "$file_id" "$server" "$node_id" 2>&1)
        exit_code=$?

        if [ $exit_code -eq 0 ]; then
            echo "$result"
            return 0
        fi

        # Check error type
        if echo "$result" | grep -qi "rate.limit"; then
            echo "{\"error\": \"rate_limit\", \"message\": \"Rate limit exceeded\", \"server\": \"$server\"}" >&2
            return 1
        elif echo "$result" | grep -qi "not.found"; then
            echo "{\"error\": \"not_found\", \"message\": \"File not found: $file_id\", \"server\": \"$server\"}" >&2
            return 1
        elif echo "$result" | grep -qi "unauthorized\|forbidden"; then
            echo "{\"error\": \"auth_failed\", \"message\": \"Authentication failed\", \"server\": \"$server\"}" >&2
            return 1
        fi

        # Retry with backoff
        if [ $attempt -lt $MAX_RETRIES ]; then
            sleep_time=$((BACKOFF_BASE ** attempt))
            echo "Attempt $attempt failed, retrying in ${sleep_time}s..." >&2
            sleep $sleep_time
        fi

        attempt=$((attempt + 1))
    done

    echo "{\"error\": \"max_retries\", \"message\": \"Failed after $MAX_RETRIES attempts\", \"server\": \"$server\"}" >&2
    return 1
}

# Function: normalize_response
# Normalize different server responses to common format
normalize_response() {
    local response="$1"
    local server_type="$2"
    local file_id="$3"

    case "$server_type" in
        official)
            # Official server returns full Figma API response
            echo "$response" | jq '{
                file_id: .document.id,
                file_name: .name,
                last_modified: .lastModified,
                version: .version,
                frames: [.document.children[]? | select(.type == "CANVAS") | .children[]? | select(.type == "FRAME")],
                pages: [.document.children[]? | select(.type == "CANVAS")],
                server: "official"
            }'
            ;;
        glips)
            # GLips returns AI-optimized context
            echo "$response" | jq --arg file_id "$file_id" '{
                file_id: $file_id,
                file_name: .fileName // .name,
                frames: .frames // [],
                context: .designContext // .context,
                server: "glips"
            }'
            ;;
        timholden)
            # TimHolden returns basic file structure
            echo "$response" | jq '{
                file_id: .document.id,
                file_name: .name,
                frames: [.document.children[]? | recurse(.children[]?) | select(.type == "FRAME")],
                server: "timholden"
            }'
            ;;
        *)
            echo "$response"
            ;;
    esac
}

# Function: analyze_frames
# Extract frame metadata from design data
analyze_frames() {
    local data="$1"

    echo "$data" | jq '[.frames[]? | {
        id: .id,
        name: .name,
        type: .type,
        width: .absoluteBoundingBox.width,
        height: .absoluteBoundingBox.height,
        x: .absoluteBoundingBox.x // 0,
        y: .absoluteBoundingBox.y // 0,
        background_color: .backgroundColor,
        has_prototype: (.transitionNodeID != null)
    }]'
}

# Function: extract_text_content
# Extract all text content from design
extract_text_content() {
    local data="$1"

    echo "$data" | jq '[
        .. |
        objects |
        select(.type == "TEXT") |
        {
            content: .characters,
            font_family: .style.fontFamily,
            font_size: .style.fontSize,
            font_weight: .style.fontWeight,
            color: .fills[0].color
        }
    ] | unique'
}

# Function: extract_colors
# Extract color palette from design
extract_colors() {
    local data="$1"

    echo "$data" | jq '[
        .. |
        objects |
        select(.fills != null) |
        .fills[]? |
        select(.type == "SOLID") |
        .color |
        {
            r: .r,
            g: .g,
            b: .b,
            a: (.a // 1)
        }
    ] | unique | map({
        rgb: "rgb(\(.r * 255 | floor), \(.g * 255 | floor), \(.b * 255 | floor))",
        rgba: "rgba(\(.r * 255 | floor), \(.g * 255 | floor), \(.b * 255 | floor), \(.a))",
        hex: "#" + (
            [.r, .g, .b] |
            map(. * 255 | floor | tostring | tonumber) |
            map(if . < 16 then "0" + ([.]|@text) else ([.]|@text) end) |
            join("")
        )
    })'
}

# Function: extract_fonts
# Extract font families and styles
extract_fonts() {
    local data="$1"

    echo "$data" | jq '[
        .. |
        objects |
        select(.style != null) |
        {
            family: .style.fontFamily,
            weight: .style.fontWeight,
            size: .style.fontSize
        }
    ] | unique | group_by(.family) | map({
        family: .[0].family,
        weights: [.[].weight] | unique,
        sizes: [.[].size] | unique | sort
    })'
}

# Function: extract_spacing
# Extract spacing patterns
extract_spacing() {
    local data="$1"

    echo "$data" | jq '[
        .. |
        objects |
        select(.paddingLeft != null or .paddingTop != null or .itemSpacing != null) |
        [.paddingLeft, .paddingTop, .paddingRight, .paddingBottom, .itemSpacing] |
        map(select(. != null))
    ] | flatten | unique | sort'
}

# Function: analyze_design
# Comprehensive design analysis
analyze_design() {
    local data="$1"

    local frames=$(analyze_frames "$data")
    local texts=$(extract_text_content "$data")
    local colors=$(extract_colors "$data")
    local fonts=$(extract_fonts "$data")
    local spacing=$(extract_spacing "$data")

    jq -n \
        --argjson frames "$frames" \
        --argjson texts "$texts" \
        --argjson colors "$colors" \
        --argjson fonts "$fonts" \
        --argjson spacing "$spacing" \
        '{
            frames: $frames,
            texts: $texts,
            styles: {
                colors: $colors,
                fonts: $fonts,
                spacing: $spacing
            },
            summary: {
                frame_count: ($frames | length),
                text_count: ($texts | length),
                color_count: ($colors | length),
                font_families: ($fonts | map(.family)),
                spacing_values: $spacing
            }
        }'
}

# Function: create_design_summary
# Create human-readable design summary
create_design_summary() {
    local analysis="$1"

    cat <<SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎨 Design Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📱 Frames: $(echo "$analysis" | jq -r '.summary.frame_count')
📝 Text Elements: $(echo "$analysis" | jq -r '.summary.text_count')
🎨 Colors: $(echo "$analysis" | jq -r '.summary.color_count')
🔤 Fonts: $(echo "$analysis" | jq -r '.summary.font_families | join(", ")')
📏 Spacing: $(echo "$analysis" | jq -r '.summary.spacing_values | map(tostring) | join(", ")' | head -c 50)...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUMMARY
}

# CLI Interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    command="${1:-help}"

    case "$command" in
        extract)
            [ -z "${2:-}" ] && { echo "Error: Missing file_id argument" >&2; exit 1; }
            [ -z "${3:-}" ] && { echo "Error: Missing server argument" >&2; exit 1; }
            extract_with_retry "$2" "$3" "${4:-}"
            ;;
        normalize)
            [ -z "${2:-}" ] && { echo "Error: Missing response argument" >&2; exit 1; }
            [ -z "${3:-}" ] && { echo "Error: Missing server_type argument" >&2; exit 1; }
            [ -z "${4:-}" ] && { echo "Error: Missing file_id argument" >&2; exit 1; }
            normalize_response "$2" "$3" "$4"
            ;;
        analyze)
            [ -z "${2:-}" ] && { echo "Error: Missing data argument" >&2; exit 1; }
            analyze_design "$2"
            ;;
        frames)
            [ -z "${2:-}" ] && { echo "Error: Missing data argument" >&2; exit 1; }
            analyze_frames "$2"
            ;;
        text)
            [ -z "${2:-}" ] && { echo "Error: Missing data argument" >&2; exit 1; }
            extract_text_content "$2"
            ;;
        colors)
            [ -z "${2:-}" ] && { echo "Error: Missing data argument" >&2; exit 1; }
            extract_colors "$2"
            ;;
        fonts)
            [ -z "${2:-}" ] && { echo "Error: Missing data argument" >&2; exit 1; }
            extract_fonts "$2"
            ;;
        spacing)
            [ -z "${2:-}" ] && { echo "Error: Missing data argument" >&2; exit 1; }
            extract_spacing "$2"
            ;;
        summary)
            [ -z "${2:-}" ] && { echo "Error: Missing analysis argument" >&2; exit 1; }
            create_design_summary "$2"
            ;;
        help|*)
            cat <<HELP
Figma Data Extractor - Extract and analyze Figma designs via MCP

Usage: \$0 <command> [arguments]

Commands:
  extract <file_id> <server> [node_id]  Extract design data with retry
  normalize <response> <type> <file_id> Normalize server response
  analyze <data>                        Comprehensive design analysis
  frames <data>                         Extract frame metadata
  text <data>                           Extract text content
  colors <data>                         Extract color palette
  fonts <data>                          Extract font families
  spacing <data>                        Extract spacing values
  summary <analysis>                    Create human-readable summary

Server Types:
  official  - Official Figma MCP server
  glips     - GLips community server
  timholden - TimHolden community server

Examples:
  \$0 extract "ABC123" "figma-repeat"
  \$0 analyze "\$design_data"
  \$0 summary "\$analysis_result"

Note: This script requires MCP gateway integration.
The 'extract' command returns MCP call instructions that
should be executed by Claude Code using the MCP gateway.
HELP
            ;;
    esac
fi
