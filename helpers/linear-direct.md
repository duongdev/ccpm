# Direct Linear MCP Calls (Fast Path)

This helper provides patterns for making direct MCP calls to Linear, bypassing the subagent overhead. Use this for simple operations where you don't need caching, validation, or error handling from the subagent.

## ⛔ EXACT LINEAR MCP PARAMETERS (from get_server_tools)

**COPY THESE EXACTLY. Verified against actual MCP schema.**

```javascript
// GET ISSUE - uses "id"
mcp__agent-mcp-gateway__execute_tool({
  server: "linear",
  tool: "get_issue",
  args: { id: "WORK-26" }  // ← "id" NOT "issueId"
})

// UPDATE ISSUE - uses "id"
mcp__agent-mcp-gateway__execute_tool({
  server: "linear",
  tool: "update_issue",
  args: {
    id: "WORK-26",          // ← "id" NOT "issueId"
    description: "...",
    state: "In Progress"
  }
})

// CREATE COMMENT - uses "issueId"
mcp__agent-mcp-gateway__execute_tool({
  server: "linear",
  tool: "create_comment",
  args: {
    issueId: "WORK-26",     // ← "issueId" for comments
    body: "Comment text"
  }
})

// LIST COMMENTS - uses "issueId"
mcp__agent-mcp-gateway__execute_tool({
  server: "linear",
  tool: "list_comments",
  args: { issueId: "WORK-26" }  // ← "issueId" for comments
})
```

| Tool | Param | NOT |
|------|-------|-----|
| `get_issue` | **`id`** | ~~issueId~~ |
| `update_issue` | **`id`** | ~~issueId~~ |
| `create_comment` | **`issueId`** | ~~id~~ |
| `list_comments` | **`issueId`** | ~~id~~ |

---

## When to Use Direct Calls vs Subagent

| Use Direct Calls | Use Subagent |
|-----------------|--------------|
| Simple get/update operations | Complex multi-step operations |
| When you know exact IDs | When you need name→ID resolution |
| Time-critical paths | When caching benefits apply |
| Single operations | Batch operations |

## Performance Comparison

| Approach | Latency | Token Usage |
|----------|---------|-------------|
| Direct MCP call | 400-800ms (depends on MCP server) | ~100 tokens |
| Via subagent | 400-800ms + agent overhead | ~500-1000 tokens |
| Background queue | ~0ms (returns immediately) | ~50 tokens |

## Direct Call Patterns

### Get Issue

```javascript
// Direct MCP call - no subagent
mcp__agent-mcp-gateway__execute_tool({
  server: "linear",
  tool: "get_issue",
  args: { id: "PSN-123" }
})

// Returns issue object directly
```

### Update Issue

```javascript
// Direct MCP call for status update
mcp__agent-mcp-gateway__execute_tool({
  server: "linear",
  tool: "update_issue",
  args: {
    id: "PSN-123",
    state: "In Progress"  // Linear MCP accepts state names directly
  }
})
```

### Create Comment

```javascript
// Direct MCP call for comment
mcp__agent-mcp-gateway__execute_tool({
  server: "linear",
  tool: "create_comment",
  args: {
    issueId: "PSN-123",
    body: "Progress update: completed initial setup"
  }
})
```

### List Issues

```javascript
// Direct MCP call with filters
mcp__agent-mcp-gateway__execute_tool({
  server: "linear",
  tool: "list_issues",
  args: {
    team: "Engineering",  // Name or ID
    state: "In Progress",
    assignee: "me",
    limit: 10
  }
})
```

## Background Execution (Fastest Path)

For operations where you don't need the result immediately, use the background queue:

### Queue Comment (Fire-and-Forget)

```bash
# Returns immediately, comment posts in background
./scripts/linear-background-ops.sh queue create_comment '{"issueId":"PSN-123","body":"Progress update"}'

# Or quick command
./scripts/linear-background-ops.sh comment PSN-123 "Progress update"
```

### Queue Status Update

```bash
# Returns immediately, status updates in background
./scripts/linear-background-ops.sh queue update_issue '{"id":"PSN-123","state":"In Progress"}'

# Or quick command
./scripts/linear-background-ops.sh update-status PSN-123 "In Progress"
```

## Error Handling for Direct Calls

Direct MCP calls return errors differently than the subagent:

```javascript
// Direct call error handling
const result = mcp__agent-mcp-gateway__execute_tool({
  server: "linear",
  tool: "get_issue",
  args: { id: "INVALID-123" }
});

// Check for errors in result
if (result.error) {
  console.log("Error:", result.error);
  // Handle error - no automatic suggestions like subagent provides
}
```

## Hybrid Approach (Recommended)

Combine direct calls with background queue for optimal performance:

```markdown
## Example: Start Work Flow

### Step 1: Get issue (blocking - need the data)
Direct MCP call to get_issue with id="${issueId}"

### Step 2: Update status (background - non-blocking)
Background queue: update_issue with state="In Progress"

### Step 3: Post comment (background - non-blocking)
Background queue: create_comment with body="Started work"

### Step 4: Continue with implementation
[Workflow continues without waiting for steps 2-3]
```

## When to Still Use Subagent

The subagent (`ccpm:linear-operations`) is still valuable for:

1. **Name resolution** - Converting team/project/label names to IDs
2. **Caching** - Repeated lookups within a session
3. **Validation** - State name fuzzy matching
4. **Batch operations** - `ensure_labels_exist` creates multiple labels efficiently
5. **Complex operations** - `update_checklist_items` with parsing logic

## Command Migration Guide

**Before (all via subagent):**
```markdown
Task(linear-operations): `
operation: get_issue
params:
  issueId: PSN-123
context:
  command: "work"
`

Task(linear-operations): `
operation: update_issue
params:
  issueId: PSN-123
  state: "In Progress"
`

Task(linear-operations): `
operation: create_comment
params:
  issueId: PSN-123
  body: "Started work"
`
```

**After (hybrid approach):**
```markdown
# Get issue - direct call (blocking, need data)
mcp__agent-mcp-gateway__execute_tool({
  server: "linear",
  tool: "get_issue",
  args: { id: "PSN-123" }
})

# Update status - background (non-blocking)
Bash(background=true): `./scripts/linear-background-ops.sh update-status PSN-123 "In Progress"`

# Post comment - background (non-blocking)
Bash(background=true): `./scripts/linear-background-ops.sh comment PSN-123 "Started work"`
```

**Performance improvement:** ~4+ minutes → ~1 minute (blocking) + ~0ms (background)

## Notes

1. **MCP server name** - Always use `"linear"` (not `"linear-operations"`)
2. **ID formats** - Linear MCP accepts both UUIDs and identifiers (PSN-123)
3. **State names** - Linear MCP accepts state names directly, no ID lookup needed
4. **Background processing** - Check `./scripts/linear-background-ops.sh list` for queue status
5. **Cold start** - First call may still be slow due to MCP server cold start
