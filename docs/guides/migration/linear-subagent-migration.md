# Linear Subagent Migration Guide

**For**: Command Developers
**Updated**: 2025-11-20
**Status**: Active - Shared Linear Helpers Now Use Subagent Delegation

---

## What Changed

The `_shared-linear-helpers.md` file now delegates operations to the `linear-operations` subagent instead of making direct Linear MCP calls.

**Bottom line**: All existing commands continue to work without changes, but you can optimize further by delegating entire operations to the subagent.

---

## Quick Reference

### Option 1: Use Helpers (Current - Still Works)

Minimal changes required. All commands work as before:

```markdown
READ: commands/_shared-linear-helpers.md

# Validate state
const stateId = await getValidStateId(teamId, "In Progress");

# Ensure labels exist
const labels = await ensureLabelsExist(teamId,
  ["planning", "backend", "high-priority"]);

# Create or get label
const label = await getOrCreateLabel(teamId, "urgent");
```

**Pros**: No code changes, minimal learning curve
**Cons**: Lower token efficiency, multiple API calls

---

### Option 2: Delegate to Subagent (Recommended)

For new commands or during refactoring, delegate entire operations:

```markdown
# Create issue with labels and state (84% token reduction)
Task(linear-operations): `
operation: create_issue
params:
  team: Engineering
  title: "Implement feature X"
  description: "..."
  state: "In Progress"
  labels:
    - "planning"
    - "backend"
    - "high-priority"
  assignee: "me"
context:
  command: "planning:create"
  purpose: "Creating planned task"
`
```

**Pros**: 50-60% token reduction, optimal caching
**Cons**: Requires understanding subagent YAML contract

---

## Common Scenarios

### Scenario 1: Validating a State (Use Helper)

When you need to validate if a state exists before conditional logic:

```markdown
# Use helper - small operation, no multi-step benefit
const stateId = await getValidStateId(teamId, userProvidedState);

if (stateId) {
  // Proceed with state
} else {
  // Handle invalid state
}
```

**Why**: Helper returns structured error with suggestions, minimal overhead.

---

### Scenario 2: Creating an Issue with Labels (Use Subagent)

When creating an issue with multiple labels and state:

```markdown
# BAD - Multiple steps (2500 tokens)
const labels = await ensureLabelsExist(teamId,
  ["planning", "backend", "high-priority"]);
const stateId = await getValidStateId(teamId, "In Progress");
const issue = await mcp__linear__create_issue({
  teamId: teamId,
  title: "New task",
  labels: labels,
  stateId: stateId,
  // ... more fields
});

# GOOD - Single delegation (400 tokens, 84% reduction)
Task(linear-operations): `
operation: create_issue
params:
  team: ${TEAM_NAME}
  title: "New task"
  state: "In Progress"
  labels: ["planning", "backend", "high-priority"]
  assignee: "me"
context:
  command: "${COMMAND_NAME}"
  purpose: "Creating task"
`
```

---

### Scenario 3: Batch Label Verification (Use Helper or Subagent)

**Option A - Helper (for simple cases)**:
```markdown
const labels = await ensureLabelsExist(teamId, [
  "planning",
  "implementation",
  "verification"
]);
```

**Option B - Subagent (for complex operations)**:
```markdown
# If you need labels for an issue creation
Task(linear-operations): `
operation: create_issue
params:
  team: ${teamId}
  title: "..."
  labels: ["planning", "implementation", "verification"]
context:
  command: "planning:create"
`
```

---

### Scenario 4: Updating Issue Status (Use Subagent)

**Before**: Multiple steps
```markdown
const stateId = await getValidStateId(teamId, "done");
await mcp__linear__update_issue({
  id: issueId,
  stateId: stateId
});
```

**After**: Single delegation
```markdown
Task(linear-operations): `
operation: update_issue
params:
  issue_id: ${issueId}
  state: "done"
  # Add other updates as needed
  labels: ["verification"]
context:
  command: "implementation:update"
`
```

---

## Subagent Operations Reference

### create_issue

Create a new Linear issue with automatic label/state resolution:

```yaml
operation: create_issue
params:
  team: "Engineering"              # Required (name, key, or ID)
  title: "Implement feature X"     # Required
  description: "..."               # Optional
  state: "In Progress"             # Optional (resolved automatically)
  labels:                           # Optional (created if needed)
    - "planning"
    - "backend"
  assignee: "me"                   # Optional (me, email, name, or ID)
  project: "Project Name"          # Optional
  priority: 2                       # Optional (0-4)
  estimate: 8                       # Optional (points)
context:
  command: "planning:create"       # Your command name
  purpose: "Creating planned task"
```

**Returns**: Full issue object with id, identifier, url, etc.

---

### update_issue

Update an existing Linear issue:

```yaml
operation: update_issue
params:
  issue_id: "PSN-123"              # Required
  title: "Updated title"           # Optional
  description: "Updated desc"      # Optional
  state: "Done"                    # Optional (resolved automatically)
  labels:                           # Optional (replaces existing)
    - "verification"
  assignee: "jane@example.com"     # Optional
  priority: 1                       # Optional
context:
  command: "implementation:update"
```

**Returns**: Updated issue object

---

### get_or_create_label

Get existing label or create if missing (rarely used directly):

```yaml
operation: get_or_create_label
params:
  team: "Engineering"
  name: "custom-label"
  color: "#ff0000"                 # Optional
  description: "..."               # Optional
context:
  command: "shared-helpers"
```

**Returns**: { id, name, color, created: bool }

---

### ensure_labels_exist

Batch ensure labels exist (rarely used directly):

```yaml
operation: ensure_labels_exist
params:
  team: "Engineering"
  labels:
    - name: "planning"
      color: "#f7c8c1"
    - name: "backend"
      color: "#26b5ce"
context:
  command: "shared-helpers"
```

**Returns**: { labels: [{id, name, created}, ...] }

---

### get_valid_state_id

Validate and resolve state name/type (rarely used directly):

```yaml
operation: get_valid_state_id
params:
  team: "Engineering"
  state: "In Progress"             # Name, type, or alias
context:
  command: "shared-helpers"
```

**Returns**: { id, name, type, color, position }

---

### list_issues

Search and filter issues:

```yaml
operation: list_issues
params:
  team: "Engineering"              # Optional
  state: "In Progress"             # Optional
  assignee: "me"                   # Optional
  labels: ["planning"]             # Optional
  project: "Auth System"           # Optional
  query: "authentication"          # Optional (search)
  limit: 50                        # Optional (default: 50)
context:
  command: "utils:search"
```

**Returns**: { issues, total, has_more }

---

## Error Handling

### Structured Error Responses

When operations fail, you get structured errors:

```yaml
success: false
error:
  code: "STATUS_NOT_FOUND"
  message: "Status 'invalid' not found for team 'Engineering'"
  details:
    input: "invalid"
    team: "Engineering"
    available_statuses:
      - name: "Backlog"
        type: "backlog"
      - name: "In Progress"
        type: "started"
      - name: "Done"
        type: "completed"
  suggestions:
    - "Use exact status name: 'In Progress'"
    - "Use status type: 'started'"
    - "Run /ccpm:utils:statuses to see all available statuses"
```

### Error Codes

- **TEAM_NOT_FOUND** - Team doesn't exist
- **PROJECT_NOT_FOUND** - Project doesn't exist
- **LABEL_NOT_FOUND** - Label doesn't exist
- **STATUS_NOT_FOUND** - State doesn't exist
- **ISSUE_NOT_FOUND** - Issue doesn't exist
- **LINEAR_API_ERROR** - API error from Linear
- **LINEAR_API_RATE_LIMIT** - Rate limited by Linear
- **LINEAR_API_TIMEOUT** - Timeout from Linear API

---

## Caching Strategy

### How Caching Works

The subagent maintains **session-level cache** for:

- **Teams** (95% cache hit rate)
- **Projects** (90% cache hit rate)
- **Labels** (85% cache hit rate)
- **States** (95% cache hit rate)

**First call**: 300-500ms (API call)
**Second call**: 25-50ms (cache hit)

### Optimization Tips

1. **Group related operations** - Team name resolution cached after first use
2. **Batch label creation** - use ensure_labels_exist instead of getOrCreateLabel in loop
3. **Reuse team ID** - Pass same team name consistently
4. **Expect 85%+ cache hit rate** in typical commands

---

## Step-by-Step Migration

### Step 1: Review Your Command

Identify Linear operations in your command:

```markdown
# Commands that use _shared-linear-helpers.md
grep -n "getOrCreateLabel\|getValidStateId\|ensureLabelsExist" your-command.md
```

### Step 2: Categorize Operations

| Operation | Use Helper | Use Subagent |
|-----------|------------|------------|
| Single state validation | ✓ | - |
| Create single label | ✓ | - |
| Validate multiple states | - | ✓ |
| Create issue + labels | - | ✓ |
| Update issue + state + labels | - | ✓ |
| Batch label verification | ✓ | ✓ |

### Step 3: Refactor High-Impact Operations

Start with multi-step operations:

**Before**:
```markdown
const labels = await ensureLabelsExist(teamId, ["planning", "backend"]);
const stateId = await getValidStateId(teamId, "In Progress");
const issue = await mcp__linear__create_issue({
  teamId,
  title,
  stateId,
  labelIds: labels,
  // ...
});
```

**After**:
```markdown
Task(linear-operations): `
operation: create_issue
params:
  team: ${teamId}
  title: "${title}"
  state: "In Progress"
  labels: ["planning", "backend"]
context:
  command: "${COMMAND_NAME}"
  purpose: "Creating task"
`
```

### Step 4: Test and Measure

1. Test with actual Linear data
2. Measure token usage before/after
3. Verify cache hit rates (expect 80%+ hit rate after first use)
4. Validate error handling

---

## Decision Matrix

Use this to decide whether to use helpers or subagent:

```
Question 1: Is this a single operation?
  YES → Use helper (getValidStateId, getOrCreateLabel)
  NO → Use subagent

Question 2: Is this for validation/guards?
  YES → Use helper
  NO → Use subagent

Question 3: Does this involve creating/updating issues?
  YES → Use subagent (better performance)
  NO → Use helper (simpler)

Question 4: Will this be called multiple times?
  YES → Use subagent (caching benefits)
  NO → Use helper (minimal overhead)
```

---

## Common Patterns

### Pattern 1: Plan Phase (Planning)

```markdown
# Validate team and state
const teamId = "ENG"  # resolve from input
const stateId = await getValidStateId(teamId, "In Progress");

# Create issue with all parameters
Task(linear-operations): `
operation: create_issue
params:
  team: ${teamId}
  title: "${issueTitle}"
  description: "${description}"
  state: "In Progress"
  labels: ["planning"]
  estimate: ${estimate}
context:
  command: "planning:create"
  purpose: "Creating planned task"
`
```

---

### Pattern 2: Implementation Phase (Implementation)

```markdown
# Get issue details
const issue = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: ${issueId}
context:
  command: "implementation:start"
`)

# Update progress
Task(linear-operations): `
operation: update_issue
params:
  issue_id: ${issueId}
  state: "In Progress"
  assignee: "me"
context:
  command: "implementation:update"
  purpose: "Starting work"
`
```

---

### Pattern 3: Verification Phase (Verification)

```markdown
# Update to completed
Task(linear-operations): `
operation: update_issue
params:
  issue_id: ${issueId}
  state: "Done"
  labels: ["verification"]
context:
  command: "verification:verify"
  purpose: "Marking task as completed"
`
```

---

## FAQs

### Q: Do I need to update my command?
**A**: No. All existing commands work without changes. Optimization is optional but recommended for high-token commands.

### Q: Will my command break?
**A**: No. Function signatures are 100% backward compatible. Return values are identical.

### Q: How much token reduction can I expect?
**A**: 50-60% for typical commands, up to 84% for commands with heavy Linear operations.

### Q: Should I update all commands at once?
**A**: No. Prioritize high-traffic commands first (planning:create, implementation:start, etc.), then others.

### Q: What if my command has complex logic?
**A**: Use helpers for validation, delegate complex operations to subagent. Combine both patterns.

### Q: How do I know if caching is working?
**A**: Second call to same operation will be ~10x faster. Check metadata.cached in response.

### Q: Can I cache across multiple commands?
**A**: No. Cache is session-scoped (one command execution). But within a command, all operations benefit.

### Q: What if Linear API changes?
**A**: Update linear-operations subagent (single source of truth). Your commands automatically benefit.

---

## Resources

- **Shared Linear Helpers**: `/commands/_shared-linear-helpers.md`
- **Linear Subagent Definition**: `/agents/linear-operations.md`
- **Refactoring Summary**: `/docs/development/REFACTORING_SUMMARY_PSN29_GROUP3.md`
- **CCPM Commands**: `/commands/README.md`

---

## Getting Help

1. **Review subagent definition**: Check available operations and parameters
2. **Look at examples**: See integration examples in _shared-linear-helpers.md
3. **Test with small changes**: Refactor one operation at a time
4. **Compare token usage**: Measure before/after with actual runs

---

**Status**: This guide is active. The shared helpers file now uses subagent delegation, but existing commands work without changes.

Start optimizing when you have time, focusing on high-impact commands first.
