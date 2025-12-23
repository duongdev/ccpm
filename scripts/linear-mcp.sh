#!/bin/bash
# Linear MCP Helper - Wraps Linear MCP calls with correct parameter names
# Usage: ./linear-mcp.sh <operation> <args_json>
#
# This helper handles the confusing parameter naming:
# - get_issue/update_issue use "id"
# - create_comment/list_comments use "issueId"
#
# Examples:
#   ./linear-mcp.sh get WORK-26
#   ./linear-mcp.sh update WORK-26 '{"state": "In Progress"}'
#   ./linear-mcp.sh comment WORK-26 "Progress update"
#   ./linear-mcp.sh comments WORK-26

set -euo pipefail

OPERATION="${1:-}"
ISSUE_ID="${2:-}"
EXTRA="${3:-}"

if [[ -z "$OPERATION" ]]; then
  cat <<EOF
Linear MCP Helper - Handles parameter naming automatically

Usage:
  ./linear-mcp.sh get <issue-id>              # Get issue details
  ./linear-mcp.sh update <issue-id> '<json>'  # Update issue (state, labels, etc.)
  ./linear-mcp.sh comment <issue-id> "text"   # Create comment
  ./linear-mcp.sh comments <issue-id>         # List comments
  ./linear-mcp.sh list [filters-json]         # List issues

Parameter Reference (handled automatically by this script):
  get_issue, update_issue → uses "id" parameter
  create_comment, list_comments → uses "issueId" parameter

Examples:
  ./linear-mcp.sh get WORK-26
  ./linear-mcp.sh update WORK-26 '{"state": "In Progress", "labels": ["planning"]}'
  ./linear-mcp.sh comment WORK-26 "Completed initial setup"

EOF
  exit 1
fi

# Helper to make MCP call via gateway
mcp_call() {
  local server="$1"
  local tool="$2"
  local args="$3"

  # Using Claude's MCP gateway
  echo "Executing: mcp__agent-mcp-gateway__execute_tool"
  echo "Server: $server"
  echo "Tool: $tool"
  echo "Args: $args"
  echo "---"

  # Output the correct format for Claude to execute
  cat <<EOF
mcp__agent-mcp-gateway__execute_tool({
  server: "$server",
  tool: "$tool",
  args: $args
})
EOF
}

case "$OPERATION" in
  get)
    if [[ -z "$ISSUE_ID" ]]; then
      echo "Error: issue-id required"
      echo "Usage: ./linear-mcp.sh get <issue-id>"
      exit 1
    fi
    # get_issue uses "id" (NOT issueId!)
    mcp_call "linear" "get_issue" "{\"id\": \"$ISSUE_ID\"}"
    ;;

  update)
    if [[ -z "$ISSUE_ID" ]]; then
      echo "Error: issue-id required"
      echo "Usage: ./linear-mcp.sh update <issue-id> '<json>'"
      exit 1
    fi
    # update_issue uses "id" (NOT issueId!)
    if [[ -n "$EXTRA" ]]; then
      # Merge id with extra args
      MERGED=$(echo "$EXTRA" | jq --arg id "$ISSUE_ID" '. + {id: $id}')
      mcp_call "linear" "update_issue" "$MERGED"
    else
      mcp_call "linear" "update_issue" "{\"id\": \"$ISSUE_ID\"}"
    fi
    ;;

  comment)
    if [[ -z "$ISSUE_ID" ]]; then
      echo "Error: issue-id required"
      echo "Usage: ./linear-mcp.sh comment <issue-id> 'comment text'"
      exit 1
    fi
    # create_comment uses "issueId" (correct!)
    BODY="${EXTRA:-Progress update}"
    # Escape the body for JSON
    ESCAPED_BODY=$(echo "$BODY" | jq -Rs .)
    mcp_call "linear" "create_comment" "{\"issueId\": \"$ISSUE_ID\", \"body\": $ESCAPED_BODY}"
    ;;

  comments)
    if [[ -z "$ISSUE_ID" ]]; then
      echo "Error: issue-id required"
      echo "Usage: ./linear-mcp.sh comments <issue-id>"
      exit 1
    fi
    # list_comments uses "issueId" (correct!)
    mcp_call "linear" "list_comments" "{\"issueId\": \"$ISSUE_ID\"}"
    ;;

  list)
    # list_issues - pass through filters
    FILTERS="${ISSUE_ID:-{}}"
    mcp_call "linear" "list_issues" "$FILTERS"
    ;;

  *)
    echo "Unknown operation: $OPERATION"
    echo "Valid operations: get, update, comment, comments, list"
    exit 1
    ;;
esac
