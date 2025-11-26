#!/bin/bash
# linear-retry-wrapper.sh - Retry wrapper for Linear MCP operations
# Handles cold start latency and transient failures with exponential backoff
#
# Usage:
#   ./linear-retry-wrapper.sh <operation> <params_json> [--background] [--timeout <seconds>]
#
# Examples:
#   ./linear-retry-wrapper.sh get_issue '{"id":"PSN-123"}'
#   ./linear-retry-wrapper.sh create_comment '{"issueId":"PSN-123","body":"Test"}' --background
#   ./linear-retry-wrapper.sh update_issue '{"id":"PSN-123","state":"In Progress"}' --timeout 60

set -euo pipefail

# Configuration
MAX_RETRIES=${LINEAR_MAX_RETRIES:-3}
INITIAL_BACKOFF=${LINEAR_INITIAL_BACKOFF:-2}  # seconds
MAX_BACKOFF=${LINEAR_MAX_BACKOFF:-30}         # seconds
DEFAULT_TIMEOUT=${LINEAR_DEFAULT_TIMEOUT:-120} # seconds (2 minutes)
LOG_DIR="${CCPM_LOG_DIR:-/tmp/ccpm-linear-logs}"
METRICS_FILE="${LOG_DIR}/linear-metrics.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
OPERATION=""
PARAMS=""
BACKGROUND=false
TIMEOUT=$DEFAULT_TIMEOUT

while [[ $# -gt 0 ]]; do
  case $1 in
    --background|-b)
      BACKGROUND=true
      shift
      ;;
    --timeout|-t)
      TIMEOUT="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 <operation> <params_json> [--background] [--timeout <seconds>]"
      echo ""
      echo "Operations: get_issue, create_issue, update_issue, create_comment, list_issues, etc."
      echo ""
      echo "Options:"
      echo "  --background, -b   Run in background (fire-and-forget for non-critical ops)"
      echo "  --timeout, -t      Timeout in seconds (default: 120)"
      echo ""
      echo "Environment Variables:"
      echo "  LINEAR_MAX_RETRIES       Max retry attempts (default: 3)"
      echo "  LINEAR_INITIAL_BACKOFF   Initial backoff in seconds (default: 2)"
      echo "  LINEAR_MAX_BACKOFF       Max backoff in seconds (default: 30)"
      echo "  LINEAR_DEFAULT_TIMEOUT   Default timeout in seconds (default: 120)"
      echo "  CCPM_LOG_DIR             Log directory (default: /tmp/ccpm-linear-logs)"
      exit 0
      ;;
    *)
      if [[ -z "$OPERATION" ]]; then
        OPERATION="$1"
      elif [[ -z "$PARAMS" ]]; then
        PARAMS="$1"
      fi
      shift
      ;;
  esac
done

# Validate arguments
if [[ -z "$OPERATION" ]] || [[ -z "$PARAMS" ]]; then
  echo -e "${RED}Error: Missing required arguments${NC}" >&2
  echo "Usage: $0 <operation> <params_json> [--background] [--timeout <seconds>]" >&2
  exit 1
fi

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Generate unique ID for this operation
OP_ID="$(date +%s%N | sha256sum | head -c 8)"
OP_LOG="${LOG_DIR}/op-${OP_ID}.log"

# Log function
log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
  echo "[$timestamp] [$level] [$OP_ID] $message" >> "$OP_LOG"

  if [[ "$BACKGROUND" != "true" ]]; then
    case $level in
      INFO)  echo -e "${BLUE}[$timestamp]${NC} $message" ;;
      WARN)  echo -e "${YELLOW}[$timestamp]${NC} $message" ;;
      ERROR) echo -e "${RED}[$timestamp]${NC} $message" ;;
      SUCCESS) echo -e "${GREEN}[$timestamp]${NC} $message" ;;
    esac
  fi
}

# Record metrics
record_metric() {
  local operation="$1"
  local attempt="$2"
  local duration_ms="$3"
  local status="$4"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "$timestamp,$operation,$attempt,$duration_ms,$status" >> "$METRICS_FILE"
}

# Execute MCP operation via Claude Code's MCP gateway
execute_mcp_operation() {
  local operation="$1"
  local params="$2"
  local timeout="$3"

  # Create a temporary file for the response
  local response_file=$(mktemp)
  local start_time=$(date +%s%3N)

  # Build the MCP call command
  # Note: This uses the claude CLI's MCP execution capability
  # The actual implementation depends on how Claude Code exposes MCP calls externally

  # For now, we use a JSON-RPC style call that can be processed
  local mcp_request=$(cat <<EOF
{
  "server": "linear",
  "tool": "$operation",
  "args": $params
}
EOF
)

  # Try to execute via claude mcp command or direct node execution
  # Fallback chain: claude mcp -> npx @anthropic-ai/mcp-linear -> direct API

  local exit_code=0
  local result=""

  # Method 1: Try using claude code's MCP infrastructure
  if command -v claude &> /dev/null; then
    # Execute through Claude Code's MCP system
    echo "$mcp_request" | timeout "$timeout" claude mcp execute 2>/dev/null > "$response_file" && exit_code=0 || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
      result=$(cat "$response_file")
    fi
  fi

  # Method 2: Direct node execution if claude mcp not available
  if [[ $exit_code -ne 0 ]] || [[ -z "$result" ]]; then
    # Use node to call the Linear SDK directly
    # This is a fallback that requires LINEAR_API_KEY to be set
    if [[ -n "${LINEAR_API_KEY:-}" ]]; then
      result=$(timeout "$timeout" node -e "
const { LinearClient } = require('@linear/sdk');
const client = new LinearClient({ apiKey: process.env.LINEAR_API_KEY });

async function run() {
  const operation = '$operation';
  const params = $params;

  try {
    let result;
    switch(operation) {
      case 'get_issue':
        result = await client.issue(params.id);
        break;
      case 'create_comment':
        result = await client.createComment(params);
        break;
      case 'update_issue':
        const issue = await client.issue(params.id);
        result = await issue.update(params);
        break;
      case 'list_issues':
        result = await client.issues(params);
        break;
      default:
        throw new Error('Unsupported operation: ' + operation);
    }
    console.log(JSON.stringify({ success: true, data: result }));
  } catch (error) {
    console.log(JSON.stringify({ success: false, error: error.message }));
    process.exit(1);
  }
}

run();
" 2>/dev/null) && exit_code=0 || exit_code=$?
    fi
  fi

  local end_time=$(date +%s%3N)
  local duration_ms=$((end_time - start_time))

  rm -f "$response_file"

  # Return result and timing
  echo "{\"result\": $result, \"duration_ms\": $duration_ms, \"exit_code\": $exit_code}"
}

# Main retry loop with exponential backoff
run_with_retry() {
  local operation="$1"
  local params="$2"
  local timeout="$3"

  local attempt=0
  local backoff=$INITIAL_BACKOFF
  local total_start=$(date +%s%3N)

  log "INFO" "Starting operation: $operation (timeout: ${timeout}s, max_retries: $MAX_RETRIES)"

  while [[ $attempt -lt $MAX_RETRIES ]]; do
    attempt=$((attempt + 1))
    log "INFO" "Attempt $attempt/$MAX_RETRIES"

    local start_time=$(date +%s%3N)

    # Execute the operation
    local response
    response=$(execute_mcp_operation "$operation" "$params" "$timeout" 2>&1)
    local exit_code=$?

    local end_time=$(date +%s%3N)
    local duration_ms=$((end_time - start_time))

    # Parse the response
    local result_exit_code=$(echo "$response" | jq -r '.exit_code // 1' 2>/dev/null || echo "1")
    local result_data=$(echo "$response" | jq -r '.result // empty' 2>/dev/null || echo "")

    if [[ "$result_exit_code" == "0" ]] && [[ -n "$result_data" ]]; then
      # Success!
      log "SUCCESS" "Operation completed in ${duration_ms}ms (attempt $attempt)"
      record_metric "$operation" "$attempt" "$duration_ms" "success"

      # Output the result
      echo "$result_data"
      return 0
    fi

    # Check if we should retry
    if [[ $attempt -lt $MAX_RETRIES ]]; then
      log "WARN" "Attempt $attempt failed after ${duration_ms}ms. Retrying in ${backoff}s..."
      record_metric "$operation" "$attempt" "$duration_ms" "retry"

      sleep "$backoff"

      # Exponential backoff with cap
      backoff=$((backoff * 2))
      if [[ $backoff -gt $MAX_BACKOFF ]]; then
        backoff=$MAX_BACKOFF
      fi
    else
      log "ERROR" "All $MAX_RETRIES attempts failed"
      record_metric "$operation" "$attempt" "$duration_ms" "failed"
    fi
  done

  local total_end=$(date +%s%3N)
  local total_duration=$((total_end - total_start))

  # Return error response
  echo "{\"success\": false, \"error\": \"All retry attempts failed\", \"attempts\": $attempt, \"total_duration_ms\": $total_duration}"
  return 1
}

# Background execution wrapper
run_background() {
  local operation="$1"
  local params="$2"
  local timeout="$3"

  log "INFO" "Starting background operation: $operation"

  # Create a status file
  local status_file="${LOG_DIR}/status-${OP_ID}.json"
  echo '{"status": "running", "operation": "'"$operation"'", "started": "'"$(date -Iseconds)"'"}' > "$status_file"

  # Run in background
  (
    local result
    result=$(run_with_retry "$operation" "$params" "$timeout" 2>&1)
    local exit_code=$?

    # Update status file with result
    if [[ $exit_code -eq 0 ]]; then
      echo "{\"status\": \"completed\", \"operation\": \"$operation\", \"completed\": \"$(date -Iseconds)\", \"result\": $result}" > "$status_file"
    else
      echo "{\"status\": \"failed\", \"operation\": \"$operation\", \"completed\": \"$(date -Iseconds)\", \"error\": \"$result\"}" > "$status_file"
    fi
  ) &

  local bg_pid=$!

  # Return immediately with operation ID
  echo "{\"background\": true, \"operation_id\": \"$OP_ID\", \"pid\": $bg_pid, \"status_file\": \"$status_file\"}"
  return 0
}

# Check status of background operation
check_status() {
  local op_id="$1"
  local status_file="${LOG_DIR}/status-${op_id}.json"

  if [[ -f "$status_file" ]]; then
    cat "$status_file"
  else
    echo '{"status": "not_found", "operation_id": "'"$op_id"'"}'
  fi
}

# Main execution
main() {
  # Check for status check mode
  if [[ "$OPERATION" == "--status" ]]; then
    check_status "$PARAMS"
    exit 0
  fi

  if [[ "$BACKGROUND" == "true" ]]; then
    run_background "$OPERATION" "$PARAMS" "$TIMEOUT"
  else
    run_with_retry "$OPERATION" "$PARAMS" "$TIMEOUT"
  fi
}

# Run main
main
