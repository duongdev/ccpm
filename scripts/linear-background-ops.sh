#!/bin/bash
# linear-background-ops.sh - Fire-and-forget Linear operations for non-critical tasks
#
# This script queues Linear operations to run in background without blocking the main flow.
# Ideal for: comments, status updates, label changes, and other non-blocking operations.
#
# Usage:
#   ./linear-background-ops.sh queue <operation> <params_json>
#   ./linear-background-ops.sh status [operation_id]
#   ./linear-background-ops.sh process
#   ./linear-background-ops.sh cleanup [--older-than <hours>]
#
# Examples:
#   ./linear-background-ops.sh queue create_comment '{"issueId":"PSN-123","body":"Progress update"}'
#   ./linear-background-ops.sh queue update_issue '{"id":"PSN-123","state":"In Progress"}'
#   ./linear-background-ops.sh status op-abc12345
#   ./linear-background-ops.sh process  # Process all queued operations

set -euo pipefail

# Configuration
QUEUE_DIR="${CCPM_QUEUE_DIR:-/tmp/ccpm-linear-queue}"
LOG_DIR="${CCPM_LOG_DIR:-/tmp/ccpm-linear-logs}"
MAX_CONCURRENT=${LINEAR_MAX_CONCURRENT:-3}
RETRY_WRAPPER="${BASH_SOURCE[0]%/*}/linear-retry-wrapper.sh"

# Ensure directories exist
mkdir -p "$QUEUE_DIR" "$LOG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Generate operation ID
generate_op_id() {
  echo "op-$(date +%s%N | sha256sum | head -c 8)"
}

# Queue an operation for background execution
queue_operation() {
  local operation="$1"
  local params="$2"
  local priority="${3:-normal}"  # normal, high, low

  local op_id=$(generate_op_id)
  local timestamp=$(date -Iseconds)
  local queue_file="$QUEUE_DIR/${op_id}.json"

  # Determine priority prefix for sorting
  local priority_prefix="5"
  case $priority in
    high) priority_prefix="1" ;;
    normal) priority_prefix="5" ;;
    low) priority_prefix="9" ;;
  esac

  # Create queue entry
  cat > "$queue_file" <<EOF
{
  "id": "$op_id",
  "operation": "$operation",
  "params": $params,
  "priority": "$priority",
  "priority_prefix": "$priority_prefix",
  "queued_at": "$timestamp",
  "status": "queued",
  "attempts": 0
}
EOF

  echo -e "${GREEN}Queued${NC} operation: $operation ($op_id)"
  echo "{\"queued\": true, \"operation_id\": \"$op_id\", \"operation\": \"$operation\"}"

  # Auto-process if no processor running
  if ! pgrep -f "linear-background-ops.sh process" > /dev/null 2>&1; then
    # Start background processor
    nohup "$0" process >> "$LOG_DIR/processor.log" 2>&1 &
    echo -e "${BLUE}Started${NC} background processor (pid: $!)"
  fi
}

# Check status of an operation
check_status() {
  local op_id="$1"

  # Check queue
  local queue_file="$QUEUE_DIR/${op_id}.json"
  if [[ -f "$queue_file" ]]; then
    cat "$queue_file"
    return 0
  fi

  # Check completed
  local completed_file="$LOG_DIR/completed-${op_id}.json"
  if [[ -f "$completed_file" ]]; then
    cat "$completed_file"
    return 0
  fi

  echo '{"status": "not_found", "operation_id": "'"$op_id"'"}'
  return 1
}

# List all queued/running operations
list_operations() {
  echo -e "${BLUE}Queued Operations:${NC}"

  local count=0
  shopt -s nullglob
  for file in "$QUEUE_DIR"/*.json; do
    if [[ -f "$file" ]]; then
      local op_id
      local operation
      local status
      local queued_at
      op_id=$(jq -r '.id' "$file")
      operation=$(jq -r '.operation' "$file")
      status=$(jq -r '.status' "$file")
      queued_at=$(jq -r '.queued_at' "$file")

      echo "  - $op_id: $operation ($status) - queued: $queued_at"
      count=$((count + 1))
    fi
  done
  shopt -u nullglob

  if [[ $count -eq 0 ]]; then
    echo "  (no queued operations)"
  fi

  echo ""
  echo -e "${BLUE}Queue Count:${NC} $count"
}

# Process a single queued operation
process_operation() {
  local queue_file="$1"

  if [[ ! -f "$queue_file" ]]; then
    return 1
  fi

  local op_id=$(jq -r '.id' "$queue_file")
  local operation=$(jq -r '.operation' "$queue_file")
  local params=$(jq -r '.params' "$queue_file")
  local attempts=$(jq -r '.attempts // 0' "$queue_file")

  # Update status to processing
  jq '.status = "processing" | .started_at = "'"$(date -Iseconds)"'" | .attempts = '"$((attempts + 1))" "$queue_file" > "${queue_file}.tmp"
  mv "${queue_file}.tmp" "$queue_file"

  echo "[$(date '+%H:%M:%S')] Processing: $operation ($op_id)"

  # Execute the operation using retry wrapper
  local result
  local exit_code=0

  if [[ -x "$RETRY_WRAPPER" ]]; then
    result=$("$RETRY_WRAPPER" "$operation" "$params" --timeout 120 2>&1) || exit_code=$?
  else
    echo "Warning: Retry wrapper not found at $RETRY_WRAPPER"
    exit_code=1
    result='{"error": "Retry wrapper not found"}'
  fi

  # Record completion
  local completed_file="$LOG_DIR/completed-${op_id}.json"

  if [[ $exit_code -eq 0 ]]; then
    # Success
    cat > "$completed_file" <<EOF
{
  "id": "$op_id",
  "operation": "$operation",
  "status": "completed",
  "completed_at": "$(date -Iseconds)",
  "attempts": $((attempts + 1)),
  "result": $result
}
EOF
    echo "[$(date '+%H:%M:%S')] Completed: $operation ($op_id)"

    # Remove from queue
    rm -f "$queue_file"
  else
    # Failed
    if [[ $attempts -ge 3 ]]; then
      # Max retries reached, move to failed
      cat > "$completed_file" <<EOF
{
  "id": "$op_id",
  "operation": "$operation",
  "status": "failed",
  "completed_at": "$(date -Iseconds)",
  "attempts": $((attempts + 1)),
  "error": $result
}
EOF
      echo "[$(date '+%H:%M:%S')] Failed (max retries): $operation ($op_id)"
      rm -f "$queue_file"
    else
      # Queue for retry
      jq '.status = "queued" | .last_error = "'"${result//\"/\\\"}"'"' "$queue_file" > "${queue_file}.tmp"
      mv "${queue_file}.tmp" "$queue_file"
      echo "[$(date '+%H:%M:%S')] Queued for retry: $operation ($op_id)"
    fi
  fi
}

# Process all queued operations
process_all() {
  echo "[$(date '+%H:%M:%S')] Background processor started"

  local processed=0
  local max_iterations=100  # Prevent infinite loop

  while [[ $max_iterations -gt 0 ]]; do
    # Get queued operations sorted by priority
    local queue_files=()
    while IFS= read -r file; do
      if [[ -f "$file" ]]; then
        local status=$(jq -r '.status' "$file" 2>/dev/null || echo "unknown")
        if [[ "$status" == "queued" ]]; then
          queue_files+=("$file")
        fi
      fi
    done < <(find "$QUEUE_DIR" -name "*.json" -type f 2>/dev/null | head -n 50)

    # No more operations to process
    if [[ ${#queue_files[@]} -eq 0 ]]; then
      break
    fi

    # Process up to MAX_CONCURRENT operations
    local running=0
    for queue_file in "${queue_files[@]}"; do
      if [[ $running -ge $MAX_CONCURRENT ]]; then
        break
      fi

      process_operation "$queue_file" &
      running=$((running + 1))
      processed=$((processed + 1))
    done

    # Wait for batch to complete
    wait

    max_iterations=$((max_iterations - 1))
    sleep 1
  done

  echo "[$(date '+%H:%M:%S')] Background processor finished. Processed: $processed operations"
}

# Cleanup old completed operations
cleanup() {
  local hours="${1:-24}"
  local cutoff
  cutoff=$(date -d "-${hours} hours" +%s 2>/dev/null || date -v-${hours}H +%s 2>/dev/null || echo "0")

  echo "Cleaning up operations older than $hours hours..."

  local removed=0
  shopt -s nullglob
  for file in "$LOG_DIR"/completed-*.json; do
    if [[ -f "$file" ]]; then
      local completed_at
      completed_at=$(jq -r '.completed_at // empty' "$file" 2>/dev/null || echo "")
      if [[ -n "$completed_at" ]]; then
        local file_time
        file_time=$(date -d "$completed_at" +%s 2>/dev/null || date -jf "%Y-%m-%dT%H:%M:%S" "$completed_at" +%s 2>/dev/null || echo "0")
        if [[ $file_time -lt $cutoff ]]; then
          rm -f "$file"
          removed=$((removed + 1))
        fi
      fi
    fi
  done
  shopt -u nullglob

  echo "Removed $removed old completion records"
}

# Quick operation shortcuts
quick_comment() {
  local issue_id="$1"
  local body="$2"
  queue_operation "create_comment" "{\"issueId\": \"$issue_id\", \"body\": \"$body\"}" "normal"
}

quick_status() {
  local issue_id="$1"
  local status="$2"
  queue_operation "update_issue" "{\"id\": \"$issue_id\", \"state\": \"$status\"}" "high"
}

# Main command dispatcher
main() {
  local command="${1:-help}"
  shift || true

  case "$command" in
    queue)
      queue_operation "$@"
      ;;
    status)
      check_status "$@"
      ;;
    list)
      list_operations
      ;;
    process)
      process_all
      ;;
    cleanup)
      local hours="${1:-24}"
      cleanup "$hours"
      ;;
    comment)
      quick_comment "$@"
      ;;
    update-status)
      quick_status "$@"
      ;;
    help|--help|-h)
      echo "linear-background-ops.sh - Fire-and-forget Linear operations"
      echo ""
      echo "Commands:"
      echo "  queue <operation> <params_json>  Queue an operation for background execution"
      echo "  status <operation_id>            Check status of an operation"
      echo "  list                             List all queued operations"
      echo "  process                          Process all queued operations"
      echo "  cleanup [hours]                  Remove completed records older than N hours"
      echo ""
      echo "Quick Commands:"
      echo "  comment <issue_id> <body>        Quick comment shortcut"
      echo "  update-status <issue_id> <state> Quick status update shortcut"
      echo ""
      echo "Examples:"
      echo "  $0 queue create_comment '{\"issueId\":\"PSN-123\",\"body\":\"Progress\"}'"
      echo "  $0 comment PSN-123 'Making progress on auth module'"
      echo "  $0 update-status PSN-123 'In Progress'"
      echo "  $0 list"
      echo "  $0 status op-abc12345"
      ;;
    *)
      echo "Unknown command: $command"
      echo "Use '$0 help' for usage information"
      exit 1
      ;;
  esac
}

main "$@"
