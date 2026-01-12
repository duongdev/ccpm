#!/bin/bash
# work-loop-stop-hook.sh - Stop hook for CCPM work loop (ralph-wiggum pattern)
# Intercepts session exit and re-feeds prompt until completion or max iterations

# State file location (relative to project root)
STATE_FILE=".claude/ccpm-work-loop.local.md"

# Read hook input from stdin
INPUT=$(cat)

# Check if work-loop is active
if [[ ! -f "$STATE_FILE" ]]; then
  # No active loop, allow normal exit
  echo '{"decision": "approve"}'
  exit 0
fi

# Extract transcript file path from input (Claude passes this in hook context)
TRANSCRIPT_FILE=$(echo "$INPUT" | jq -r '.transcript_file // empty' 2>/dev/null || echo "")

# Parse state frontmatter using sed (portable across macOS/Linux)
extract_field() {
  local field="$1"
  sed -n "s/^${field}: \"\{0,1\}\([^\"]*\)\"\{0,1\}$/\1/p" "$STATE_FILE" | head -1
}

ISSUE_ID=$(extract_field "issue_id")
ITERATION=$(extract_field "iteration")
MAX_ITERATIONS=$(extract_field "max_iterations")
COMPLETION_PROMISE=$(extract_field "completion_promise")
BRANCH=$(extract_field "branch")

# Validate parsed values (defensive programming)
if [[ -z "$ITERATION" || ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  ITERATION=1
fi
if [[ -z "$MAX_ITERATIONS" || ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  MAX_ITERATIONS=30
fi
if [[ -z "$COMPLETION_PROMISE" ]]; then
  COMPLETION_PROMISE="ALL_ITEMS_COMPLETE"
fi

# Check max iterations limit
if [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Work loop: Max iterations ($MAX_ITERATIONS) reached" >&2
  rm -f "$STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

# Check for completion promise in transcript
# The transcript file contains the conversation history in JSONL format
if [[ -n "$TRANSCRIPT_FILE" && -f "$TRANSCRIPT_FILE" ]]; then
  # Extract last few assistant messages and check for completion promise
  LAST_MESSAGES=$(tail -20 "$TRANSCRIPT_FILE" 2>/dev/null || echo "")

  if echo "$LAST_MESSAGES" | grep -q "<promise>$COMPLETION_PROMISE</promise>"; then
    echo "Work loop: Completion promise detected!" >&2
    rm -f "$STATE_FILE"
    echo '{"decision": "approve"}'
    exit 0
  fi

  # Check for blocker signal - pause loop for user input
  if echo "$LAST_MESSAGES" | grep -qE "Status:\s*(Blocked|BLOCKED)"; then
    echo "Work loop: Blocker detected - pausing for user input" >&2
    # Don't remove state file - user can resume with --resume
    echo '{"decision": "approve"}'
    exit 0
  fi
fi

# Also check environment for completion (fallback)
if [[ -n "$CCPM_WORK_LOOP_COMPLETE" ]]; then
  echo "Work loop: Complete signal received via environment" >&2
  rm -f "$STATE_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

# Continue loop - increment iteration
NEW_ITERATION=$((ITERATION + 1))

# Update state file with new iteration count (portable sed)
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS
  sed -i '' "s/^iteration: .*/iteration: ${NEW_ITERATION}/" "$STATE_FILE"
  sed -i '' "s/^last_sync_at: .*/last_sync_at: \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"/" "$STATE_FILE"
else
  # Linux
  sed -i "s/^iteration: .*/iteration: ${NEW_ITERATION}/" "$STATE_FILE"
  sed -i "s/^last_sync_at: .*/last_sync_at: \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"/" "$STATE_FILE"
fi

# Build continuation prompt
PROMPT=$(cat << PROMPT_END
## Continue Work Loop

**Iteration**: ${NEW_ITERATION} of ${MAX_ITERATIONS}
**Issue**: ${ISSUE_ID}
**Branch**: ${BRANCH}

Continue implementing the next uncompleted checklist item.

**Instructions**:
1. Check current checklist progress in Linear (use ccpm:linear-operations agent)
2. Find the next uncompleted item
3. Delegate implementation to appropriate specialized agent
4. Sync progress to Linear after completion
5. Move to next item

**When ALL items are genuinely complete**, output:
<promise>${COMPLETION_PROMISE}</promise>

**If blocked**, output: Status: Blocked

**Important**:
- Do NOT output the completion promise unless ALL checklist items are truly done
- Check Linear to verify completion status before outputting promise
- Each iteration should complete at least one checklist item
PROMPT_END
)

# Escape the prompt for JSON
ESCAPED_PROMPT=$(echo "$PROMPT" | jq -Rs .)

# Output block decision with continuation prompt
cat << EOF
{
  "decision": "block",
  "prompt": ${ESCAPED_PROMPT}
}
EOF

exit 0
