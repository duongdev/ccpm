#!/bin/bash
# figma-utils.sh - Figma link detection and URL parsing utilities
# Part of CCPM Figma MCP integration (PSN-25)

set -euo pipefail

readonly FIGMA_URL_REGEX='https://([a-z]+\.)?figma\.com/(file|design|proto)/([A-Za-z0-9]+)'

detect_figma_links() {
    local text="$1"
    local links="[]"

    while IFS= read -r url; do
        if [ -n "$url" ]; then
            links=$(echo "$links" | jq --arg url "$url" '. += [$url]')
        fi
    done < <(echo "$text" | grep -oE "$FIGMA_URL_REGEX[^ )\"<>]*" || true)

    echo "$links"
}

parse_figma_url() {
    local url="$1"

    if ! echo "$url" | grep -qE "$FIGMA_URL_REGEX"; then
        echo "{\"error\": \"Invalid Figma URL format\"}" >&2
        return 1
    fi

    # Use awk for parsing (more portable than sed -E on macOS)
    local file_type=$(echo "$url" | awk -F'/' '{for(i=1;i<=NF;i++) if($i=="file"||$i=="design"||$i=="proto") print $i}')
    local file_id=$(echo "$url" | awk -F'/' '{for(i=1;i<=NF;i++) if($i=="file"||$i=="design"||$i=="proto") print $(i+1)}' | cut -d'?' -f1)
    local file_name=$(echo "$url" | awk -F'/' '{for(i=1;i<=NF;i++) if($i=="file"||$i=="design"||$i=="proto") print $(i+2)}' | cut -d'?' -f1 | sed 's/-/ /g')
    local node_id=$(echo "$url" | grep -oE 'node-id=[^&]*' | cut -d= -f2 || echo "")

    jq -n \
        --arg url "$url" \
        --arg type "$file_type" \
        --arg file_id "$file_id" \
        --arg file_name "$file_name" \
        --arg node_id "$node_id" \
        '{url: $url, type: $type, file_id: $file_id, file_name: $file_name, node_id: ($node_id // null), is_valid: true}'
}

validate_figma_url() {
    local url="$1"
    if echo "$url" | grep -qE "$FIGMA_URL_REGEX"; then
        echo "true"
    else
        echo "false"
    fi
}

extract_figma_links_from_markdown() {
    local markdown="$1"
    local links="[]"

    # Extract from markdown links: [text](url)
    while IFS= read -r url; do
        if [ -n "$url" ]; then
            local parsed=$(parse_figma_url "$url" 2>/dev/null || echo "{}")
            if [ "$(echo "$parsed" | jq -r '.is_valid // false')" = "true" ]; then
                links=$(echo "$links" | jq --argjson obj "$parsed" '. += [$obj]')
            fi
        fi
    done < <(echo "$markdown" | grep -oE '\[.*\]\((https://([a-z]+\.)?figma\.com/[^)]+)\)' | sed -E 's/.*\((.*)\)/\1/' || true)

    # Extract bare URLs
    while IFS= read -r url; do
        if [ -n "$url" ]; then
            local parsed=$(parse_figma_url "$url" 2>/dev/null || echo "{}")
            if [ "$(echo "$parsed" | jq -r '.is_valid // false')" = "true" ]; then
                local exists=$(echo "$links" | jq --arg url "$url" 'any(.url == $url)')
                if [ "$exists" = "false" ]; then
                    links=$(echo "$links" | jq --argjson obj "$parsed" '. += [$obj]')
                fi
            fi
        fi
    done < <(detect_figma_links "$markdown" | jq -r '.[]')

    echo "$links"
}

get_figma_file_url() {
    local url="$1"
    local parsed=$(parse_figma_url "$url" 2>/dev/null || echo "{}")

    if [ "$(echo "$parsed" | jq -r '.is_valid // false')" = "true" ]; then
        local file_type=$(echo "$parsed" | jq -r '.type')
        local file_id=$(echo "$parsed" | jq -r '.file_id')
        echo "https://www.figma.com/$file_type/$file_id"
    else
        echo ""
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    command="${1:-help}"
    case "$command" in
        detect)
            [ -z "${2:-}" ] && { echo "Error: Missing text argument" >&2; exit 1; }
            detect_figma_links "$2"
            ;;
        parse)
            [ -z "${2:-}" ] && { echo "Error: Missing URL argument" >&2; exit 1; }
            parse_figma_url "$2"
            ;;
        validate)
            [ -z "${2:-}" ] && { echo "Error: Missing URL argument" >&2; exit 1; }
            validate_figma_url "$2"
            ;;
        extract-markdown)
            [ -z "${2:-}" ] && { echo "Error: Missing markdown argument" >&2; exit 1; }
            extract_figma_links_from_markdown "$2"
            ;;
        canonical)
            [ -z "${2:-}" ] && { echo "Error: Missing URL argument" >&2; exit 1; }
            get_figma_file_url "$2"
            ;;
        help|*)
            cat <<HELP_EOF
Figma Utilities - Link detection and URL parsing

Usage: \$0 <command> [arguments]

Commands:
  detect <text>           Detect all Figma links in text
  parse <url>             Parse Figma URL into components
  validate <url>          Check if URL is valid Figma link
  extract-markdown <md>   Extract Figma links from markdown
  canonical <url>         Get canonical file URL without query params
HELP_EOF
            ;;
    esac
fi
