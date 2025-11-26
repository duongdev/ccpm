# Linear Background Operations Helper

This helper provides patterns for executing Linear operations in background (fire-and-forget) mode. Use this for non-critical operations that shouldn't block the main workflow.

## When to Use Background Operations

### Use Background (Fire-and-Forget)

| Operation | Background? | Reason |
|-----------|-------------|--------|
| `create_comment` | ✅ Yes | User doesn't wait for comments |
| `update_issue` (status) | ✅ Yes | Non-blocking status change |
| `update_issue` (labels) | ✅ Yes | Non-blocking label change |
| `update_issue_description` | ⚠️ Sometimes | Background if not displaying result |

### Use Blocking (Synchronous)

| Operation | Background? | Reason |
|-----------|-------------|--------|
| `get_issue` | ❌ No | Need data to continue |
| `create_issue` | ❌ No | Need issue ID |
| `update_checklist_items` | ❌ No | Need progress % for display |

## Helper Functions

### Queue Background Comment

Use this pattern for progress comments, status updates, and notifications:

```markdown
## Post Progress Comment (Background)

**🚀 Fire-and-forget - returns immediately:**

Bash: `
./scripts/linear-background-ops.sh queue create_comment '{
  "issueId": "${issueId}",
  "body": "🔄 **Progress Update**\n\n${summary}"
}'
`

Display: "📝 Comment queued (posting in background)"

# Continue immediately - don't wait for comment
```

### Quick Commands

Simplified shortcuts for common operations:

```bash
# Quick comment (fire-and-forget)
./scripts/linear-background-ops.sh comment ${issueId} "${body}"

# Quick status update (fire-and-forget)
./scripts/linear-background-ops.sh update-status ${issueId} "In Progress"
./scripts/linear-background-ops.sh update-status ${issueId} "Done"
```

## Command-Specific Patterns

### /ccpm:work - Start/Resume Work

**Background operations:**
- Update status to "In Progress" ✅
- Post START/RESUME comment ✅

```markdown
## Step X: Update Linear Status (Background)

### A) Update status (fire-and-forget)
Bash: `./scripts/linear-background-ops.sh update-status ${issueId} "In Progress"`

### B) Post start comment (fire-and-forget)
Bash: `./scripts/linear-background-ops.sh comment ${issueId} "🚀 **Started Work**\n\nBranch: ${branch}"`

Display: "📝 Linear updates queued (background)"

# Continue immediately with implementation
```

### /ccpm:sync - Save Progress

**Background operations:**
- Post progress comment ✅

**Blocking operations:**
- Get issue (need checklist data)
- Update checklist items (need progress %)

```markdown
## Step X: Post Progress Comment (Background)

After checklist update completes (blocking), post comment in background:

Bash: `./scripts/linear-background-ops.sh comment ${issueId} '${syncComment}'`

Display: "📝 Progress comment queued"
```

### /ccpm:done - Finalize Task

**Background operations:**
- Update status to "Done" ✅
- Post completion comment ✅

**Blocking operations:**
- Get issue (need checklist/status)

```markdown
## Step X: Update Linear to Done (Background)

### A) Update status (fire-and-forget)
Bash: `./scripts/linear-background-ops.sh update-status ${issueId} "Done"`

### B) Post completion comment (fire-and-forget)
Bash: `./scripts/linear-background-ops.sh comment ${issueId} "🎉 **Task Completed**\n\nPR: ${prUrl}"`

Display: "✅ Task marked as Done"

# PR creation and user notification complete instantly
```

### /ccpm:verify - Run Verification

**Background operations:**
- Post success/failure comment ✅
- Update labels ✅

**Blocking operations:**
- Get issue (need checklist)
- Update checklist items (need progress)

```markdown
## Step X: Update Linear with Results (Background)

### If PASSED:
Bash: `
./scripts/linear-background-ops.sh queue update_issue '{"id":"${issueId}","labels":["verified"]}'
./scripts/linear-background-ops.sh comment ${issueId} "✅ **Verification Passed**\n\nAll checks green!"
`

### If FAILED:
Bash: `
./scripts/linear-background-ops.sh queue update_issue '{"id":"${issueId}","labels":["blocked","needs-revision"]}'
./scripts/linear-background-ops.sh comment ${issueId} "❌ **Verification Failed**\n\n${failureReason}"
`

Display: "📝 Linear updated"
```

### /ccpm:plan - Create/Plan Tasks

**Background operations:**
- Update status/labels after planning ✅
- Post planning comment (in UPDATE mode) ✅

**Blocking operations:**
- Create issue (need ID)
- Get issue (need data)
- Update description (need to show plan)

```markdown
## Step X: Update Status After Planning (Background)

After plan is confirmed and description updated (blocking):

Bash: `./scripts/linear-background-ops.sh update-status ${issueId} "Planned"`

Display: "✅ Planning complete - ready to implement"
```

## Performance Comparison

| Workflow | Before (Blocking) | After (Background) | Savings |
|----------|-------------------|-------------------|---------|
| `/ccpm:work` start | ~4 min | ~2 min | 50% |
| `/ccpm:sync` | ~4 min | ~2.5 min | 37% |
| `/ccpm:done` | ~6 min | ~3 min | 50% |
| `/ccpm:verify` | ~5 min | ~3 min | 40% |

**Why?** Background operations return in ~0ms vs ~2 minutes for cold-start MCP calls.

## Error Handling

Background operations have their own error handling:

1. **Automatic retry** - 3 attempts with exponential backoff
2. **Queue persistence** - Operations survive process termination
3. **Status tracking** - Check status with `./scripts/linear-background-ops.sh status <op-id>`
4. **Logging** - All operations logged to `/tmp/ccpm-linear-logs/`

### Checking Background Status

```bash
# List all queued operations
./scripts/linear-background-ops.sh list

# Check specific operation
./scripts/linear-background-ops.sh status op-abc12345

# View logs
tail -f /tmp/ccpm-linear-logs/processor.log
```

### Handling Failures

Background operations fail silently (by design). For critical operations:

1. **Use blocking mode** - Don't use background for must-succeed operations
2. **Check status later** - Verify with `./scripts/linear-background-ops.sh list`
3. **Manual retry** - Use direct MCP call if background failed

## Integration Checklist

When updating a command to use background operations:

1. ✅ Identify non-blocking operations (see table above)
2. ✅ Replace `Task(linear-operations)` with background script
3. ✅ Add "queued (background)" message to user
4. ✅ Keep blocking operations for data-dependent steps
5. ✅ Test with `./scripts/linear-background-ops.sh list`

## Example: Full Work Flow with Background Ops

```markdown
## /ccpm:work Implementation

### Step 1: Get Issue (BLOCKING - need data)
Use Task(linear-operations) to get_issue

### Step 2: Display Issue Info
Show issue title, status, checklist

### Step 3: Update Status (BACKGROUND - fire-and-forget)
Bash: `./scripts/linear-background-ops.sh update-status ${issueId} "In Progress"`

### Step 4: Post Start Comment (BACKGROUND - fire-and-forget)
Bash: `./scripts/linear-background-ops.sh comment ${issueId} "🚀 Started work"`

### Step 5: Continue with Implementation
User continues working immediately - no wait for Linear updates

### Step 6: After AI Implementation (BACKGROUND - fire-and-forget)
Bash: `./scripts/linear-background-ops.sh comment ${issueId} "✅ Completed: ${taskSummary}"`

# Total blocking time: ~2 min (just get_issue)
# vs ~6 min before (get_issue + 2x updates + 2x comments)
```

## Notes

1. **Script location**: `./scripts/linear-background-ops.sh`
2. **Queue directory**: `/tmp/ccpm-linear-queue/`
3. **Log directory**: `/tmp/ccpm-linear-logs/`
4. **Max concurrent**: 3 operations (configurable via `LINEAR_MAX_CONCURRENT`)
5. **Retry attempts**: 3 (configurable via `LINEAR_MAX_RETRIES`)

## Related Files

- `scripts/linear-background-ops.sh` - Background queue script
- `scripts/linear-retry-wrapper.sh` - Retry wrapper for critical ops
- `helpers/linear-direct.md` - Direct MCP call patterns
- `agents/linear-operations.md` - Full subagent documentation
