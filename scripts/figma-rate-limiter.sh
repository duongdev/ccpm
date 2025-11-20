#!/bin/bash
# figma-rate-limiter.sh - Rate limit tracking for Figma MCP servers
# Part of CCPM Figma MCP integration (PSN-25) - Phase 2

set -euo pipefail

# Constants
readonly RATE_LIMIT_DIR="/tmp/ccpm-figma-rate-limits"
readonly OFFICIAL_FREE_LIMIT=6        # 6 calls per month (!)
readonly OFFICIAL_FREE_WINDOW=2592000 # 30 days in seconds
readonly STANDARD_LIMIT=60            # 60 calls per hour for community servers
readonly STANDARD_WINDOW=3600         # 1 hour in seconds

# Ensure rate limit directory exists
mkdir -p "$RATE_LIMIT_DIR"

# Function: get_server_limits
# Get rate limit configuration for a server
get_server_limits() {
    local server="$1"

    # Check if server is official (has very low limits)
    if echo "$server" | grep -qi "official"; then
        echo "$OFFICIAL_FREE_LIMIT $OFFICIAL_FREE_WINDOW"
    else
        # Community servers use standard Figma API limits
        echo "$STANDARD_LIMIT $STANDARD_WINDOW"
    fi
}

# Function: get_rate_limit_file
# Get path to rate limit tracking file for a server
get_rate_limit_file() {
    local server="$1"
    echo "$RATE_LIMIT_DIR/${server}.json"
}

# Function: initialize_rate_limit
# Initialize rate limit tracking for a server
initialize_rate_limit() {
    local server="$1"
    local file=$(get_rate_limit_file "$server")

    read -r limit window < <(get_server_limits "$server")

    local now=$(date +%s)

    jq -n \
        --arg server "$server" \
        --argjson limit "$limit" \
        --argjson window "$window" \
        --argjson now "$now" \
        '{
            server: $server,
            limit: $limit,
            window: $window,
            calls: [],
            initialized_at: $now,
            last_reset: $now
        }' > "$file"

    echo "$file"
}

# Function: get_rate_limit_state
# Get current rate limit state for a server
get_rate_limit_state() {
    local server="$1"
    local file=$(get_rate_limit_file "$server")

    if [ ! -f "$file" ]; then
        initialize_rate_limit "$server" >/dev/null
    fi

    cat "$file"
}

# Function: clean_old_calls
# Remove calls outside the current window
clean_old_calls() {
    local state="$1"
    local now=$(date +%s)

    echo "$state" | jq \
        --argjson now "$now" \
        '. as $parent | .calls = [.calls[] | select(($now - .timestamp) < $parent.window)] |
         .last_reset = $now'
}

# Function: track_call
# Track a new API call
track_call() {
    local server="$1"
    local file=$(get_rate_limit_file "$server")

    local state=$(get_rate_limit_state "$server")
    local now=$(date +%s)

    # Clean old calls and add new one
    local new_state=$(echo "$state" | jq \
        --argjson now "$now" \
        '. as $parent | .calls = [.calls[] | select(($now - .timestamp) < $parent.window)] |
         .calls += [{timestamp: $now}] |
         .last_call = $now')

    echo "$new_state" > "$file"
    echo "$new_state"
}

# Function: get_call_count
# Get number of calls in current window
get_call_count() {
    local server="$1"

    local state=$(get_rate_limit_state "$server")
    local state_cleaned=$(clean_old_calls "$state")

    echo "$state_cleaned" | jq '.calls | length'
}

# Function: get_remaining_calls
# Get number of remaining calls in current window
get_remaining_calls() {
    local server="$1"

    local state=$(get_rate_limit_state "$server")
    local state_cleaned=$(clean_old_calls "$state")

    echo "$state_cleaned" | jq '.limit - (.calls | length)'
}

# Function: check_rate_limit
# Check if rate limit would be exceeded
check_rate_limit() {
    local server="$1"
    local calls_needed="${2:-1}"

    local remaining=$(get_remaining_calls "$server")

    if [ "$remaining" -ge "$calls_needed" ]; then
        echo "OK"
        return 0
    else
        echo "RATE_LIMITED"
        return 1
    fi
}

# Function: get_reset_time
# Get when rate limit will reset (oldest call expires)
get_reset_time() {
    local server="$1"

    local state=$(get_rate_limit_state "$server")
    local state_cleaned=$(clean_old_calls "$state")

    # Find oldest call timestamp
    local oldest=$(echo "$state_cleaned" | jq -r '
        if (.calls | length) > 0 then
            .calls | map(.timestamp) | min
        else
            0
        end
    ')

    if [ "$oldest" -eq 0 ]; then
        echo "0"
        return 0
    fi

    local window=$(echo "$state_cleaned" | jq -r '.window')
    local reset_time=$((oldest + window))

    echo "$reset_time"
}

# Function: get_time_until_reset
# Get seconds until rate limit resets
get_time_until_reset() {
    local server="$1"

    local reset_time=$(get_reset_time "$server")
    local now=$(date +%s)

    local until_reset=$((reset_time - now))

    if [ "$until_reset" -lt 0 ]; then
        echo "0"
    else
        echo "$until_reset"
    fi
}

# Function: format_time_remaining
# Format seconds as human-readable duration
format_time_remaining() {
    local seconds="$1"

    if [ "$seconds" -lt 60 ]; then
        echo "${seconds}s"
    elif [ "$seconds" -lt 3600 ]; then
        echo "$((seconds / 60))m $((seconds % 60))s"
    elif [ "$seconds" -lt 86400 ]; then
        echo "$((seconds / 3600))h $((seconds % 3600 / 60))m"
    else
        echo "$((seconds / 86400))d $((seconds % 86400 / 3600))h"
    fi
}

# Function: get_rate_limit_status
# Get comprehensive rate limit status
get_rate_limit_status() {
    local server="$1"

    local state=$(get_rate_limit_state "$server")
    local state_cleaned=$(clean_old_calls "$state")

    local call_count=$(echo "$state_cleaned" | jq '.calls | length')
    local limit=$(echo "$state_cleaned" | jq -r '.limit')
    local remaining=$((limit - call_count))
    local reset_time=$(get_reset_time "$server")
    local time_until_reset=$(get_time_until_reset "$server")
    local reset_formatted=$(format_time_remaining "$time_until_reset")

    jq -n \
        --arg server "$server" \
        --argjson used "$call_count" \
        --argjson limit "$limit" \
        --argjson remaining "$remaining" \
        --argjson reset_time "$reset_time" \
        --argjson until_reset "$time_until_reset" \
        --arg reset_formatted "$reset_formatted" \
        '{
            server: $server,
            used: $used,
            limit: $limit,
            remaining: $remaining,
            percentage_used: (($used / $limit) * 100 | floor),
            reset_timestamp: $reset_time,
            time_until_reset: $until_reset,
            reset_in: $reset_formatted,
            status: (if $remaining > 0 then "OK" else "RATE_LIMITED" end)
        }'
}

# Function: reset_rate_limit
# Manually reset rate limit for a server
reset_rate_limit() {
    local server="$1"
    local file=$(get_rate_limit_file "$server")

    if [ -f "$file" ]; then
        rm "$file"
    fi

    initialize_rate_limit "$server"
    echo "Rate limit reset for $server"
}

# Function: create_rate_limit_report
# Create report for all tracked servers
create_rate_limit_report() {
    local servers=()

    for file in "$RATE_LIMIT_DIR"/*.json; do
        if [ -f "$file" ]; then
            local server=$(basename "$file" .json)
            servers+=("$server")
        fi
    done

    if [ ${#servers[@]} -eq 0 ]; then
        echo "No rate limits tracked"
        return 0
    fi

    cat <<REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Figma MCP Rate Limit Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REPORT

    for server in "${servers[@]}"; do
        local status=$(get_rate_limit_status "$server")

        cat <<SERVER_REPORT
🔧 Server: $(echo "$status" | jq -r '.server')
   Used: $(echo "$status" | jq -r '.used')/$(echo "$status" | jq -r '.limit') ($(echo "$status" | jq -r '.percentage_used')%)
   Remaining: $(echo "$status" | jq -r '.remaining')
   Status: $(echo "$status" | jq -r '.status')
   Reset in: $(echo "$status" | jq -r '.reset_in')

SERVER_REPORT
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# CLI Interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    command="${1:-help}"

    case "$command" in
        track)
            [ -z "${2:-}" ] && { echo "Error: Missing server argument" >&2; exit 1; }
            track_call "$2" | jq .
            ;;
        check)
            [ -z "${2:-}" ] && { echo "Error: Missing server argument" >&2; exit 1; }
            check_rate_limit "$2" "${3:-1}"
            ;;
        count)
            [ -z "${2:-}" ] && { echo "Error: Missing server argument" >&2; exit 1; }
            get_call_count "$2"
            ;;
        remaining)
            [ -z "${2:-}" ] && { echo "Error: Missing server argument" >&2; exit 1; }
            get_remaining_calls "$2"
            ;;
        status)
            [ -z "${2:-}" ] && { echo "Error: Missing server argument" >&2; exit 1; }
            get_rate_limit_status "$2"
            ;;
        reset-time)
            [ -z "${2:-}" ] && { echo "Error: Missing server argument" >&2; exit 1; }
            get_time_until_reset "$2" | xargs -I {} bash -c 'echo $('"$(declare -f format_time_remaining)"'; format_time_remaining {})'
            ;;
        reset)
            [ -z "${2:-}" ] && { echo "Error: Missing server argument" >&2; exit 1; }
            reset_rate_limit "$2"
            ;;
        report)
            create_rate_limit_report
            ;;
        help|*)
            cat <<HELP
Figma Rate Limiter - Track and enforce API rate limits

Usage: \$0 <command> [arguments]

Commands:
  track <server>              Track a new API call
  check <server> [count]      Check if rate limit allows N calls
  count <server>              Get current call count
  remaining <server>          Get remaining calls in window
  status <server>             Get comprehensive status
  reset-time <server>         Get time until reset (human-readable)
  reset <server>              Manually reset rate limit
  report                      Show status for all servers

Rate Limits:
  Official (free):  $OFFICIAL_FREE_LIMIT calls per month
  Community:        $STANDARD_LIMIT calls per hour

Storage:
  Location: $RATE_LIMIT_DIR
  Format: JSON state file per server

Examples:
  \$0 track "figma-repeat"
  \$0 check "figma-repeat" 5
  \$0 status "figma-repeat"
  \$0 report

Workflow:
  1. Before MCP call: check if limit allows
  2. If OK: make call, then track it
  3. If RATE_LIMITED: use cache or fail gracefully
  4. Monitor status with report command
HELP
            ;;
    esac
fi
