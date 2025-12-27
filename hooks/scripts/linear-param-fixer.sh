#!/bin/bash
# Linear Parameter Fixer - PreToolUse hook to fix common parameter mistakes
# This intercepts Linear MCP calls and fixes issueId -> id transformation

set -euo pipefail

# Hook logging function
HOOK_LOG_FILE="/tmp/ccpm-hooks.log"
hook_log() {
    local hook_name="$1"
    local message="$2"
    local timestamp=$(date +"%H:%M:%S")
    echo "${timestamp} [${hook_name}] ${message}" >> "$HOOK_LOG_FILE"
    echo "${timestamp} [${hook_name}] ${message}" >&2
}

# Read the tool call JSON from stdin
INPUT=$(cat)

# Extract tool name and arguments
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // "{}"')

# Only process mcp__agent-mcp-gateway__execute_tool calls to Linear
if [[ "$TOOL_NAME" != "mcp__agent-mcp-gateway__execute_tool" ]]; then
  exit 0
fi

# Extract server and tool from args
SERVER=$(echo "$TOOL_INPUT" | jq -r '.server // ""')
LINEAR_TOOL=$(echo "$TOOL_INPUT" | jq -r '.tool // ""')
ARGS=$(echo "$TOOL_INPUT" | jq -r '.args // "{}"')

# Only process Linear server calls
if [[ "$SERVER" != "linear" ]]; then
  exit 0
fi

# Check if this is a tool that needs id instead of issueId
case "$LINEAR_TOOL" in
  get_issue|update_issue)
    # Check if args has issueId but not id
    HAS_ISSUE_ID=$(echo "$ARGS" | jq 'has("issueId")')
    HAS_ID=$(echo "$ARGS" | jq 'has("id")')

    if [[ "$HAS_ISSUE_ID" == "true" && "$HAS_ID" == "false" ]]; then
      # Log the fix
      hook_log "linear-param-fixer" "⚠ Fixed: $LINEAR_TOOL uses 'id' not 'issueId'"
      # Output warning and fix suggestion
      cat <<EOF
⚠️ **Linear Parameter Fix Required**

The tool \`$LINEAR_TOOL\` expects parameter \`id\`, not \`issueId\`.

**Current (WRONG):**
\`\`\`json
$(echo "$ARGS" | jq -c .)
\`\`\`

**Should be:**
\`\`\`json
$(echo "$ARGS" | jq '{id: .issueId} + del(.issueId)')
\`\`\`

**Quick Reference:**
| Tool | Parameter |
|------|-----------|
| \`get_issue\` | \`id\` |
| \`update_issue\` | \`id\` |
| \`create_comment\` | \`issueId\` |
| \`list_comments\` | \`issueId\` |

Please retry with the correct parameter name.
EOF
      exit 0
    fi
    ;;
  create_comment|list_comments)
    # Check if args has id but not issueId
    HAS_ISSUE_ID=$(echo "$ARGS" | jq 'has("issueId")')
    HAS_ID=$(echo "$ARGS" | jq 'has("id")')

    if [[ "$HAS_ID" == "true" && "$HAS_ISSUE_ID" == "false" ]]; then
      # Log the fix
      hook_log "linear-param-fixer" "⚠ Fixed: $LINEAR_TOOL uses 'issueId' not 'id'"
      cat <<EOF
⚠️ **Linear Parameter Fix Required**

The tool \`$LINEAR_TOOL\` expects parameter \`issueId\`, not \`id\`.

**Current (WRONG):**
\`\`\`json
$(echo "$ARGS" | jq -c .)
\`\`\`

**Should be:**
\`\`\`json
$(echo "$ARGS" | jq '{issueId: .id} + del(.id)')
\`\`\`

Please retry with the correct parameter name.
EOF
      exit 0
    fi
    ;;
esac

# No issues found, allow the call
exit 0
