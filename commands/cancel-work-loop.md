---
description: Cancel active work loop and clean up state
allowed-tools: [Bash]
---

# /ccpm:cancel-work-loop - Cancel Work Loop

Stop an active work loop and clean up the state file.

## Usage

```bash
/ccpm:cancel-work-loop
```

## Behavior

1. Checks for active work loop state file
2. Displays current loop status before cancellation
3. Removes state file to stop the loop
4. Shows next steps

## Implementation

```bash
STATE_FILE=".claude/ccpm-work-loop.local.md"

# Check if loop is active
if [[ ! -f "$STATE_FILE" ]]; then
  echo "No active work loop to cancel."
  exit 0
fi

# Read current state for summary
ISSUE_ID=$(grep -E "^issue_id:" "$STATE_FILE" | sed 's/issue_id: "\(.*\)"/\1/')
ITERATION=$(grep -E "^iteration:" "$STATE_FILE" | sed 's/iteration: //')
MAX_ITERATIONS=$(grep -E "^max_iterations:" "$STATE_FILE" | sed 's/max_iterations: //')
STARTED_AT=$(grep -E "^started_at:" "$STATE_FILE" | sed 's/started_at: "\(.*\)"/\1/')

echo "Cancelling work loop..."
echo ""
echo "Loop Summary:"
echo "  Issue: ${ISSUE_ID}"
echo "  Iterations: ${ITERATION} of ${MAX_ITERATIONS}"
echo "  Started: ${STARTED_AT}"
echo ""

# Remove state file
rm -f "$STATE_FILE"

echo "Work loop cancelled."
echo ""
echo "Next Steps:"
echo "  - Review uncommitted changes with: git status"
echo "  - Sync progress manually with: /ccpm:sync"
echo "  - Continue interactively with: /ccpm:work ${ISSUE_ID}"
echo "  - Restart loop with: /ccpm:work:loop ${ISSUE_ID}"
```

## Example

```bash
/ccpm:cancel-work-loop

# Output:
# Cancelling work loop...
#
# Loop Summary:
#   Issue: WORK-26
#   Iterations: 5 of 30
#   Started: 2026-01-12T10:00:00Z
#
# Work loop cancelled.
#
# Next Steps:
#   - Review uncommitted changes with: git status
#   - Sync progress manually with: /ccpm:sync
#   - Continue interactively with: /ccpm:work WORK-26
#   - Restart loop with: /ccpm:work:loop WORK-26
```

## When to Cancel

- **Implementation approach needs changing**: Cancel to discuss with user
- **Wrong issue**: Started loop on wrong issue
- **Need manual control**: Prefer interactive `/ccpm:work` instead
- **Unexpected behavior**: Loop not behaving as expected

## Notes

- Cancelling does NOT revert any changes made during the loop
- Uncommitted changes remain in git working directory
- Linear progress updates already synced remain in place
- You can restart the loop anytime with `/ccpm:work:loop`
