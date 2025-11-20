#!/bin/bash
# audit-log.sh
# Security audit logging for CCPM external operations
# Part of CCPM security audit recommendations
#
# Usage:
#   source "$SCRIPTS_DIR/audit-log.sh"
#   audit_log_action "JIRA_UPDATE" "TRAIN-123" "USER_CONFIRMED" "Updated status to Done"
#   audit_log_action "CONFLUENCE_CREATE" "Page Title" "USER_DENIED" "User cancelled operation"

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

AUDIT_LOG_DIR="$HOME/.claude/ccpm-logs"
AUDIT_LOG_FILE="$AUDIT_LOG_DIR/audit.log"
AUDIT_LOG_JSON="$AUDIT_LOG_DIR/audit.jsonl"
MAX_LOG_SIZE=$((10 * 1024 * 1024))  # 10MB

# Create log directory if it doesn't exist
mkdir -p "$AUDIT_LOG_DIR"
chmod 700 "$AUDIT_LOG_DIR"  # Restrict to owner only

# ============================================================================
# Logging Functions
# ============================================================================

# Log an action to audit log
# Args: action, target, result, details (optional)
audit_log_action() {
    local action="$1"
    local target="$2"
    local result="$3"
    local details="${4:-}"

    # Timestamp in ISO 8601 format
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # User information
    local username="${USER:-unknown}"
    local hostname="${HOSTNAME:-$(hostname)}"

    # Working directory
    local cwd="$PWD"

    # Log entry (human-readable)
    local log_entry="$timestamp | $username@$hostname | $action | $target | $result"
    if [[ -n "$details" ]]; then
        log_entry="$log_entry | $details"
    fi

    # Append to text log
    echo "$log_entry" >> "$AUDIT_LOG_FILE"

    # JSON log entry (structured)
    local json_entry
    json_entry=$(jq -n \
        --arg timestamp "$timestamp" \
        --arg username "$username" \
        --arg hostname "$hostname" \
        --arg cwd "$cwd" \
        --arg action "$action" \
        --arg target "$target" \
        --arg result "$result" \
        --arg details "$details" \
        '{
            timestamp: $timestamp,
            user: {
                username: $username,
                hostname: $hostname
            },
            cwd: $cwd,
            action: $action,
            target: $target,
            result: $result,
            details: $details
        }')

    # Append to JSON log
    echo "$json_entry" >> "$AUDIT_LOG_JSON"

    # Rotate logs if too large
    rotate_logs_if_needed
}

# Log external system operation
# Args: system, operation, target, result, details (optional)
audit_log_external() {
    local system="$1"
    local operation="$2"
    local target="$3"
    local result="$4"
    local details="${5:-}"

    local action="${system}_${operation}"
    audit_log_action "$action" "$target" "$result" "$details"
}

# Log user confirmation
# Args: operation, target, confirmed (true/false), reason (optional)
audit_log_confirmation() {
    local operation="$1"
    local target="$2"
    local confirmed="$3"
    local reason="${4:-}"

    local result
    if [[ "$confirmed" == "true" ]]; then
        result="USER_CONFIRMED"
    else
        result="USER_DENIED"
    fi

    audit_log_action "CONFIRMATION_${operation}" "$target" "$result" "$reason"
}

# Log safety rule check
# Args: rule, target, passed (true/false), details (optional)
audit_log_safety_check() {
    local rule="$1"
    local target="$2"
    local passed="$3"
    local details="${4:-}"

    local result
    if [[ "$passed" == "true" ]]; then
        result="PASSED"
    else
        result="FAILED"
    fi

    audit_log_action "SAFETY_CHECK_${rule}" "$target" "$result" "$details"
}

# Log configuration change
# Args: config_key, old_value, new_value
audit_log_config_change() {
    local config_key="$1"
    local old_value="$2"
    local new_value="$3"

    local details="Changed from '$old_value' to '$new_value'"
    audit_log_action "CONFIG_CHANGE" "$config_key" "SUCCESS" "$details"
}

# ============================================================================
# Log Rotation
# ============================================================================

# Rotate logs if they exceed max size
rotate_logs_if_needed() {
    # Check text log size
    if [[ -f "$AUDIT_LOG_FILE" ]]; then
        local log_size
        log_size=$(stat -f%z "$AUDIT_LOG_FILE" 2>/dev/null || stat -c%s "$AUDIT_LOG_FILE" 2>/dev/null || echo 0)

        if [[ $log_size -gt $MAX_LOG_SIZE ]]; then
            local timestamp
            timestamp=$(date +"%Y%m%d-%H%M%S")
            mv "$AUDIT_LOG_FILE" "$AUDIT_LOG_FILE.$timestamp"
            gzip "$AUDIT_LOG_FILE.$timestamp" &
        fi
    fi

    # Check JSON log size
    if [[ -f "$AUDIT_LOG_JSON" ]]; then
        local json_log_size
        json_log_size=$(stat -f%z "$AUDIT_LOG_JSON" 2>/dev/null || stat -c%s "$AUDIT_LOG_JSON" 2>/dev/null || echo 0)

        if [[ $json_log_size -gt $MAX_LOG_SIZE ]]; then
            local timestamp
            timestamp=$(date +"%Y%m%d-%H%M%S")
            mv "$AUDIT_LOG_JSON" "$AUDIT_LOG_JSON.$timestamp"
            gzip "$AUDIT_LOG_JSON.$timestamp" &
        fi
    fi
}

# ============================================================================
# Log Query Functions
# ============================================================================

# Get recent audit log entries
# Args: count (default: 20)
audit_log_recent() {
    local count="${1:-20}"

    if [[ ! -f "$AUDIT_LOG_FILE" ]]; then
        echo "No audit log found"
        return
    fi

    tail -n "$count" "$AUDIT_LOG_FILE"
}

# Search audit log
# Args: pattern
audit_log_search() {
    local pattern="$1"

    if [[ ! -f "$AUDIT_LOG_FILE" ]]; then
        echo "No audit log found"
        return
    fi

    grep -i "$pattern" "$AUDIT_LOG_FILE"
}

# Get audit log for specific action type
# Args: action_type
audit_log_by_action() {
    local action_type="$1"

    if [[ ! -f "$AUDIT_LOG_FILE" ]]; then
        echo "No audit log found"
        return
    fi

    grep " | $action_type | " "$AUDIT_LOG_FILE"
}

# Get audit log for specific date
# Args: date (YYYY-MM-DD)
audit_log_by_date() {
    local date="$1"

    if [[ ! -f "$AUDIT_LOG_FILE" ]]; then
        echo "No audit log found"
        return
    fi

    grep "^$date" "$AUDIT_LOG_FILE"
}

# Get JSON audit log entries
# Args: filter (jq filter expression)
audit_log_json_query() {
    local filter="${1:-.}"

    if [[ ! -f "$AUDIT_LOG_JSON" ]]; then
        echo "[]"
        return
    fi

    # Read JSONL and apply filter
    jq -s "$filter" "$AUDIT_LOG_JSON"
}

# ============================================================================
# Statistics Functions
# ============================================================================

# Get audit log statistics
audit_log_stats() {
    if [[ ! -f "$AUDIT_LOG_FILE" ]]; then
        echo "No audit log found"
        return
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "CCPM Audit Log Statistics"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Total entries
    local total_entries
    total_entries=$(wc -l < "$AUDIT_LOG_FILE")
    echo "Total entries: $total_entries"
    echo ""

    # Actions by type
    echo "Actions by type:"
    awk -F' \\| ' '{print $3}' "$AUDIT_LOG_FILE" | sort | uniq -c | sort -rn | head -10
    echo ""

    # Results
    echo "Results:"
    awk -F' \\| ' '{print $5}' "$AUDIT_LOG_FILE" | sort | uniq -c | sort -rn
    echo ""

    # Recent activity (last 7 days)
    local seven_days_ago
    seven_days_ago=$(date -u -v-7d +"%Y-%m-%d" 2>/dev/null || date -u -d "7 days ago" +"%Y-%m-%d" 2>/dev/null || echo "")

    if [[ -n "$seven_days_ago" ]]; then
        echo "Activity last 7 days:"
        grep "^$seven_days_ago" "$AUDIT_LOG_FILE" | wc -l | xargs echo "  Entries:"
    fi
}

# Get external operation statistics
audit_log_external_stats() {
    if [[ ! -f "$AUDIT_LOG_FILE" ]]; then
        echo "No audit log found"
        return
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "External Operations Statistics"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Jira operations
    local jira_count
    jira_count=$(grep -c " | JIRA_" "$AUDIT_LOG_FILE" || echo 0)
    echo "Jira operations: $jira_count"

    # Confluence operations
    local confluence_count
    confluence_count=$(grep -c " | CONFLUENCE_" "$AUDIT_LOG_FILE" || echo 0)
    echo "Confluence operations: $confluence_count"

    # Slack operations
    local slack_count
    slack_count=$(grep -c " | SLACK_" "$AUDIT_LOG_FILE" || echo 0)
    echo "Slack operations: $slack_count"

    # BitBucket operations
    local bitbucket_count
    bitbucket_count=$(grep -c " | BITBUCKET_" "$AUDIT_LOG_FILE" || echo 0)
    echo "BitBucket operations: $bitbucket_count"

    echo ""

    # User confirmations
    echo "User Confirmations:"
    local confirmed_count
    confirmed_count=$(grep -c " | USER_CONFIRMED" "$AUDIT_LOG_FILE" || echo 0)
    echo "  Confirmed: $confirmed_count"

    local denied_count
    denied_count=$(grep -c " | USER_DENIED" "$AUDIT_LOG_FILE" || echo 0)
    echo "  Denied: $denied_count"
}

# ============================================================================
# Export Functions
# ============================================================================

# Export audit log to CSV
# Args: output_file
audit_log_export_csv() {
    local output_file="$1"

    if [[ ! -f "$AUDIT_LOG_FILE" ]]; then
        echo "No audit log found"
        return 1
    fi

    # CSV header
    echo "Timestamp,User,Hostname,Action,Target,Result,Details" > "$output_file"

    # Parse log entries
    awk -F' \\| ' '{
        gsub(/@/, ",", $2);
        print $1 "," $2 "," $3 "," $4 "," $5 "," $6
    }' "$AUDIT_LOG_FILE" >> "$output_file"

    echo "Exported to: $output_file"
}

# Export audit log to JSON
# Args: output_file
audit_log_export_json() {
    local output_file="$1"

    if [[ ! -f "$AUDIT_LOG_JSON" ]]; then
        echo "No JSON audit log found"
        return 1
    fi

    # Combine JSONL to JSON array
    jq -s '.' "$AUDIT_LOG_JSON" > "$output_file"

    echo "Exported to: $output_file"
}

# ============================================================================
# Maintenance Functions
# ============================================================================

# Clean old audit logs
# Args: days_to_keep (default: 90)
audit_log_clean_old() {
    local days_to_keep="${1:-90}"

    echo "Cleaning audit logs older than $days_to_keep days..."

    # Find and remove old archived logs
    find "$AUDIT_LOG_DIR" -name "audit.log.*.gz" -mtime +"$days_to_keep" -delete
    find "$AUDIT_LOG_DIR" -name "audit.jsonl.*.gz" -mtime +"$days_to_keep" -delete

    echo "Cleanup complete"
}

# ============================================================================
# Example Usage
# ============================================================================

# Uncomment to test:
# audit_log_action "TEST_ACTION" "test-target" "SUCCESS" "This is a test"
# audit_log_external "JIRA" "UPDATE" "TRAIN-123" "USER_CONFIRMED" "Updated status"
# audit_log_confirmation "JIRA_UPDATE" "TRAIN-123" "true" "User approved"
# audit_log_stats
