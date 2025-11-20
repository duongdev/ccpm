#!/bin/bash
# figma-cache-manager.sh - Cache Figma design data in Linear comments
# Part of CCPM Figma MCP integration (PSN-25) - Phase 2

set -euo pipefail

# Constants
readonly CACHE_MARKER_START="<!-- FIGMA_CACHE:START -->"
readonly CACHE_MARKER_END="<!-- FIGMA_CACHE:END -->"
readonly DEFAULT_TTL=3600  # 1 hour

# Function: get_cache_ttl
# Get configured cache TTL for a project
get_cache_ttl() {
    local project_id="${1:-}"

    if [ -n "$project_id" ] && [ -f ~/.claude/ccpm-config.yaml ]; then
        local ttl=$(yq eval ".projects.\"$project_id\".figma.cache.ttl // $DEFAULT_TTL" ~/.claude/ccpm-config.yaml 2>/dev/null || echo "$DEFAULT_TTL")
        echo "$ttl"
    else
        echo "$DEFAULT_TTL"
    fi
}

# Function: create_cache_entry
# Create a cache entry with metadata
create_cache_entry() {
    local file_id="$1"
    local file_name="$2"
    local url="$3"
    local server="$4"
    local data="$5"
    local ttl="${6:-$DEFAULT_TTL}"

    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local expires_at=$(date -u -v+${ttl}S +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+${ttl} seconds" +"%Y-%m-%dT%H:%M:%SZ")

    jq -n \
        --arg file_id "$file_id" \
        --arg file_name "$file_name" \
        --arg url "$url" \
        --arg server "$server" \
        --argjson data "$data" \
        --arg cached_at "$now" \
        --arg expires_at "$expires_at" \
        --argjson ttl "$ttl" \
        '{
            file_id: $file_id,
            file_name: $file_name,
            url: $url,
            server: $server,
            cached_at: $cached_at,
            expires_at: $expires_at,
            ttl: $ttl,
            data: $data
        }'
}

# Function: format_cache_comment
# Format cache entry as Linear comment
format_cache_comment() {
    local cache_entry="$1"

    cat <<COMMENT
$CACHE_MARKER_START
\`\`\`json
$cache_entry
\`\`\`
$CACHE_MARKER_END

## 🎨 Figma Design Cache

**File**: $(echo "$cache_entry" | jq -r '.file_name')
**URL**: $(echo "$cache_entry" | jq -r '.url')
**MCP Server**: $(echo "$cache_entry" | jq -r '.server')
**Cached**: $(echo "$cache_entry" | jq -r '.cached_at')
**Expires**: $(echo "$cache_entry" | jq -r '.expires_at')

### Design Summary

$(echo "$cache_entry" | jq -r '.data.summary |
    "📱 Frames: " + (.frame_count | tostring) + "\n" +
    "📝 Texts: " + (.text_count | tostring) + "\n" +
    "🎨 Colors: " + (.color_count | tostring) + "\n" +
    "🔤 Fonts: " + (.font_families | join(", "))'
)

---
*Cached automatically by CCPM (PSN-25)*
*Refresh with: \`/ccpm:utils:figma-refresh <issue-id>\`*
COMMENT
}

# Function: store_cache
# Store cache entry in Linear comment
# NOTE: This returns the instruction for Linear MCP call
store_cache() {
    local issue_id="$1"
    local file_id="$2"
    local file_name="$3"
    local url="$4"
    local server="$5"
    local data="$6"
    local project_id="${7:-}"

    local ttl=$(get_cache_ttl "$project_id")
    local cache_entry=$(create_cache_entry "$file_id" "$file_name" "$url" "$server" "$data" "$ttl")
    local comment=$(format_cache_comment "$cache_entry")

    # Return Linear MCP instruction
    jq -n \
        --arg issue_id "$issue_id" \
        --arg body "$comment" \
        '{
            linear_call: true,
            tool: "create_comment",
            args: {
                issueId: $issue_id,
                body: $body
            },
            instruction: "Use Linear MCP to create this comment"
        }'
}

# Function: get_issue_comments
# Get all comments for an issue
# NOTE: This returns the instruction for Linear MCP call
get_issue_comments() {
    local issue_id="$1"

    jq -n \
        --arg issue_id "$issue_id" \
        '{
            linear_call: true,
            tool: "get_comments",
            args: {
                issueId: $issue_id
            },
            instruction: "Use Linear MCP to get comments"
        }'
}

# Function: extract_cache_from_comment
# Extract cache entry from a Linear comment
extract_cache_from_comment() {
    local comment_body="$1"

    # Check if comment contains cache marker
    if ! echo "$comment_body" | grep -q "$CACHE_MARKER_START"; then
        echo ""
        return 0
    fi

    # Extract JSON between markers
    echo "$comment_body" | sed -n "/$CACHE_MARKER_START/,/$CACHE_MARKER_END/p" | \
        sed -e "/$CACHE_MARKER_START/d" -e "/$CACHE_MARKER_END/d" | \
        sed -e '/^```json$/d' -e '/^```$/d' | \
        jq -c '.'
}

# Function: find_cache_entry
# Find cache entry for a specific file_id from comments
find_cache_entry() {
    local comments="$1"
    local file_id="$2"

    # Parse comments and find matching cache
    echo "$comments" | jq -r '.[]?.body // empty' | while IFS= read -r comment_body; do
        cache=$(extract_cache_from_comment "$comment_body" 2>/dev/null || echo "")
        if [ -n "$cache" ]; then
            cached_file_id=$(echo "$cache" | jq -r '.file_id // empty')
            if [ "$cached_file_id" = "$file_id" ]; then
                echo "$cache"
                return 0
            fi
        fi
    done
}

# Function: is_cache_valid
# Check if cache entry is still valid (not expired)
is_cache_valid() {
    local cache_entry="$1"

    local expires_at=$(echo "$cache_entry" | jq -r '.expires_at')
    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [[ "$now" < "$expires_at" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Function: get_cache_age
# Get cache age in seconds
get_cache_age() {
    local cache_entry="$1"

    local cached_at=$(echo "$cache_entry" | jq -r '.cached_at')
    local now=$(date -u +%s)
    local cached_timestamp=$(date -u -d "$cached_at" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$cached_at" +%s)

    echo $((now - cached_timestamp))
}

# Function: get_cached_data
# Get cached data for a file_id if valid
get_cached_data() {
    local issue_id="$1"
    local file_id="$2"
    local allow_stale="${3:-false}"

    # NOTE: In actual usage, this would need to:
    # 1. Call Linear MCP to get comments
    # 2. Parse comments to find cache
    # 3. Validate cache
    # 4. Return data or empty

    # For now, return instruction
    jq -n \
        --arg issue_id "$issue_id" \
        --arg file_id "$file_id" \
        --arg allow_stale "$allow_stale" \
        '{
            operation: "get_cached_data",
            issue_id: $issue_id,
            file_id: $file_id,
            allow_stale: ($allow_stale == "true"),
            instructions: [
                "1. Call Linear MCP get_comments for issue",
                "2. Extract cache entries from comments",
                "3. Find entry matching file_id",
                "4. Check if cache is valid (not expired)",
                "5. Return cache.data if valid, or null if expired/not found"
            ]
        }'
}

# Function: invalidate_cache
# Mark cache as expired (force refresh on next access)
invalidate_cache() {
    local issue_id="$1"
    local file_id="$2"

    jq -n \
        --arg issue_id "$issue_id" \
        --arg file_id "$file_id" \
        '{
            operation: "invalidate_cache",
            issue_id: $issue_id,
            file_id: $file_id,
            instruction: "Add comment noting cache invalidation for this file_id"
        }'
}

# Function: create_cache_summary
# Create summary of all cached Figma files for an issue
create_cache_summary() {
    local comments="$1"

    local cache_entries=()

    echo "$comments" | jq -r '.[]?.body // empty' | while IFS= read -r comment_body; do
        cache=$(extract_cache_from_comment "$comment_body" 2>/dev/null || echo "")
        if [ -n "$cache" ]; then
            is_valid=$(is_cache_valid "$cache")
            age=$(get_cache_age "$cache")

            echo "$cache" | jq --arg is_valid "$is_valid" --argjson age "$age" '. + {
                is_valid: ($is_valid == "true"),
                age_seconds: $age
            }'
        fi
    done | jq -s '.'
}

# CLI Interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    command="${1:-help}"

    case "$command" in
        store)
            [ -z "${2:-}" ] && { echo "Error: Missing issue_id" >&2; exit 1; }
            [ -z "${3:-}" ] && { echo "Error: Missing file_id" >&2; exit 1; }
            [ -z "${4:-}" ] && { echo "Error: Missing file_name" >&2; exit 1; }
            [ -z "${5:-}" ] && { echo "Error: Missing url" >&2; exit 1; }
            [ -z "${6:-}" ] && { echo "Error: Missing server" >&2; exit 1; }
            [ -z "${7:-}" ] && { echo "Error: Missing data (JSON)" >&2; exit 1; }
            store_cache "$2" "$3" "$4" "$5" "$6" "$7" "${8:-}"
            ;;
        get)
            [ -z "${2:-}" ] && { echo "Error: Missing issue_id" >&2; exit 1; }
            [ -z "${3:-}" ] && { echo "Error: Missing file_id" >&2; exit 1; }
            get_cached_data "$2" "$3" "${4:-false}"
            ;;
        invalidate)
            [ -z "${2:-}" ] && { echo "Error: Missing issue_id" >&2; exit 1; }
            [ -z "${3:-}" ] && { echo "Error: Missing file_id" >&2; exit 1; }
            invalidate_cache "$2" "$3"
            ;;
        extract)
            [ -z "${2:-}" ] && { echo "Error: Missing comment_body" >&2; exit 1; }
            extract_cache_from_comment "$2"
            ;;
        find)
            [ -z "${2:-}" ] && { echo "Error: Missing comments (JSON)" >&2; exit 1; }
            [ -z "${3:-}" ] && { echo "Error: Missing file_id" >&2; exit 1; }
            find_cache_entry "$2" "$3"
            ;;
        valid)
            [ -z "${2:-}" ] && { echo "Error: Missing cache_entry (JSON)" >&2; exit 1; }
            is_cache_valid "$2"
            ;;
        age)
            [ -z "${2:-}" ] && { echo "Error: Missing cache_entry (JSON)" >&2; exit 1; }
            get_cache_age "$2"
            ;;
        summary)
            [ -z "${2:-}" ] && { echo "Error: Missing comments (JSON)" >&2; exit 1; }
            create_cache_summary "$2"
            ;;
        help|*)
            cat <<HELP
Figma Cache Manager - Manage Figma design cache in Linear comments

Usage: \$0 <command> [arguments]

Commands:
  store <issue> <file_id> <name> <url> <server> <data> [project]
        Store cache entry in Linear comment

  get <issue> <file_id> [allow_stale]
        Get cached data if valid

  invalidate <issue> <file_id>
        Invalidate cache (force refresh)

  extract <comment_body>
        Extract cache entry from comment text

  find <comments_json> <file_id>
        Find cache entry for file_id from comments

  valid <cache_entry>
        Check if cache is still valid

  age <cache_entry>
        Get cache age in seconds

  summary <comments_json>
        Create summary of all cached files

Examples:
  \$0 store "PSN-25" "ABC123" "Design" "https://..." "figma-repeat" '{...}'
  \$0 get "PSN-25" "ABC123"
  \$0 invalidate "PSN-25" "ABC123"

Cache Storage:
  - Stored as Linear comments with JSON data
  - Markers: $CACHE_MARKER_START and $CACHE_MARKER_END
  - TTL: Configurable per project (default: ${DEFAULT_TTL}s / 1 hour)
  - Validation: Automatic expiry check based on timestamp

Note: Store and get commands return Linear MCP call instructions.
Actual caching requires Linear MCP integration.
HELP
            ;;
    esac
fi
