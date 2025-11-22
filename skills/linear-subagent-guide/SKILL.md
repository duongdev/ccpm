---
name: linear-subagent-guide
description: Guides optimal Linear operations usage with caching, performance patterns, and error handling. Auto-activates when implementing CCPM commands that interact with Linear. Prevents usage of non-existent Linear MCP tools.
allowed-tools: [Task]
---

# Linear Subagent Guide

## Overview

The **Linear subagent** (`ccpm:linear-operations`) is a dedicated MCP handler that optimizes all Linear API operations in CCPM. Rather than making direct Linear MCP calls, commands should delegate to this subagent, which provides:

- **50-60% token reduction** (15k-25k → 8k-12k per workflow)
- **Session-level caching** with 85-95% hit rates
- **Performance**: <50ms for cached operations (vs 400-600ms direct)
- **Structured error handling** with actionable suggestions
- **Centralized logic** for Linear operations consistency

## When to Use the Linear Subagent

**Use the subagent for:**
- Reading issues, projects, teams, statuses
- Creating or updating issues, projects
- Managing labels and comments
- Fetching documents and cycles
- Searching Linear documentation

**Never use the subagent for:**
- Local file operations
- Git commands
- External API calls (except Linear)

---

## Available Linear MCP Tools (Validated List)

CCPM validates all Linear MCP operations against this complete list of **23 tools**. Using tools outside this list will fail.

### Comments (2 tools)
- `list_comments` - List comments on an issue or document
- `create_comment` - Add a comment to an issue or document

### Cycles (1 tool)
- `list_cycles` - List all cycles in a team

### Documents (2 tools)
- `get_document` - Fetch a Linear document by ID
- `list_documents` - List documents in a project or team

### Issues (4 tools)
- `get_issue` - Fetch an issue by ID or key
- `list_issues` - Search and list issues (supports filtering)
- `create_issue` - Create a new issue
- `update_issue` - Update issue fields (status, labels, assignee, etc.)

### Issue Statuses (2 tools)
- `list_issue_statuses` - List all statuses in a team
- `get_issue_status` - Get a specific status by ID

### Labels (3 tools)
- `list_issue_labels` - List labels in a team
- `create_issue_label` - Create a new label
- `list_project_labels` - List labels in a project

### Projects (4 tools)
- `list_projects` - List projects in a team
- `get_project` - Fetch a project by ID
- `create_project` - Create a new project
- `update_project` - Update project details

### Teams (2 tools)
- `list_teams` - List all accessible teams
- `get_team` - Fetch a team by ID

### Users (2 tools)
- `list_users` - List users in a team or workspace
- `get_user` - Fetch a user by ID or email

### Documentation (1 tool)
- `search_documentation` - Search Linear documentation (for help queries)

---

## Tool Validation: Critical Rules

### Only Use Validated Tools

**RULE: Every Linear operation MUST use a tool from the validated list above.**

**Examples of INVALID tool names that will fail:**
- ❌ `get_issues` (correct: `list_issues`)
- ❌ `update_comment` (correct: create new comment instead)
- ❌ `delete_issue` (not supported)
- ❌ `list_issue_statuses` (correct tool, but check args)

### Before Using a Tool

1. Check the validated list above
2. Verify the exact tool name matches
3. If unsure, use `list_*` variants which are widely available
4. Never assume tool names—verify first

### Error Prevention Strategy

```javascript
// ✅ CORRECT: Use only validated tools
Task(ccpm:linear-operations): `
operation: get_issue
params:
  issueId: PSN-29
context:
  cache: true
`

// ❌ INCORRECT: Non-existent tool
Task(ccpm:linear-operations): `
operation: fetch_issue  // This tool doesn't exist!
params:
  issueId: PSN-29
`

// ❌ INCORRECT: Assuming delete exists
Task(ccpm:linear-operations): `
operation: delete_issue  // Linear MCP doesn't support deletion
params:
  issueId: PSN-29
`
```

---

## Using the Linear Subagent

### ⚠️ IMPORTANT: Command File Invocation Format

When writing **CCPM command files** (files in `commands/`), you MUST use explicit execution instructions, NOT the YAML template format shown in the examples below.

**Command files must use this format:**

```markdown
**Use the Task tool to fetch the issue from Linear:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: get_issue
  params:
    issueId: "{the issue ID from previous step}"
  context:
    cache: true
    command: "work"
  ```
```

**Why?** Claude Code interprets command markdown files as **executable prompts**, not documentation. YAML template syntax appears as an **example** rather than an instruction to execute. Explicit instructions (e.g., "Use the Task tool to...") are unambiguous execution directives that ensure Claude invokes the subagent correctly.

### Basic Syntax (For Documentation/Examples Only)

The examples below use YAML template format for readability. **Do NOT use this format in command files**—use the explicit format shown above instead.

```markdown
Task(ccpm:linear-operations): `
operation: <tool_name>
params:
  <param1>: <value1>
  <param2>: <value2>
context:
  cache: true
  command: "planning:plan"
`
```

### Enabling Caching (Recommended)

For **read operations**, always enable caching to achieve 85-95% hit rates:

```markdown
Task(ccpm:linear-operations): `
operation: get_issue
params:
  issueId: PSN-123
context:
  cache: true  # Enable session-level caching
  command: "planning:plan"
`
```

### Providing Context for Better Errors

Include context to improve error messages and debugging:

```markdown
Task(ccpm:linear-operations): `
operation: update_issue
params:
  issueId: PSN-29
  state: "In Progress"
context:
  cache: false  # Skip cache for writes
  command: "implementation:start"  # Which command triggered this
  purpose: "Marking task as started"  # Why we're doing this
`
```

---

## Shared Helpers

The `_shared-linear-helpers.md` file provides convenience functions that **delegate to the subagent**. Use these for common operations:

### getOrCreateLabel(teamId, labelName)
Smart label management with automatic creation if missing:

```markdown
// Use this instead of manual list + create
const label = await getOrCreateLabel(teamId, "feature-request");
```

**Benefits:**
- Deduplicates label creation logic
- Handles caching automatically
- Returns label ID or creates new one

### getValidStateId(teamId, stateNameOrId)
Fuzzy state matching with suggestions on errors:

```markdown
// Handles "In Progress" → actual state ID
const stateId = await getValidStateId(teamId, "In Progress");
```

**Benefits:**
- Case-insensitive matching
- Fuzzy matching for typos
- Suggests available states on error

### ensureLabelsExist(teamId, labelNames)
Batch create labels if missing:

```markdown
// Create multiple labels in one call
const labels = await ensureLabelsExist(teamId, [
  "planning",
  "implementation",
  "review"
]);
```

---

## Performance Optimization

### Caching Strategy

**Read Operations**: Always enable caching
- `get_issue`, `list_issues`, `list_projects`
- Cache hits: 85-95%
- Performance: <50ms

**Write Operations**: Disable caching
- `create_issue`, `update_issue`, `create_comment`
- Always fetch fresh data

```markdown
// READ: Cache enabled
Task(ccpm:linear-operations): `
operation: get_issue
params:
  issueId: PSN-29
context:
  cache: true  # ✅ Cached reads
`

// WRITE: Cache disabled
Task(ccpm:linear-operations): `
operation: update_issue
params:
  issueId: PSN-29
  state: "Done"
context:
  cache: false  # ❌ Never cache writes
`
```

### Batching Operations

When possible, batch related operations:

```markdown
// ✅ GOOD: Get all needed data in one context
Task(ccpm:linear-operations): `
operation: get_issue
params:
  issueId: PSN-29
context:
  cache: true
  batchId: "planning-workflow"
`

// Then use Team, Project, Status in sequence
// Subsequent calls reuse cached Team/Project data
```

### Token Reduction Comparison

| Operation | Direct MCP | Via Subagent | Savings |
|-----------|-----------|--------------|---------|
| Get issue | 400ms, 2.5k tokens | <50ms, 0.8k tokens | 68% |
| Update issue | 600ms, 3.2k tokens | <50ms, 1.2k tokens | 62% |
| Create comment | 500ms, 2.8k tokens | <50ms, 1.0k tokens | 64% |
| **Workflow average** | **500ms, 15k tokens** | **<50ms, 8k tokens** | **-47%** |

---

## Error Handling

The Linear subagent provides **structured errors** with actionable suggestions.

### Common Error Scenarios

#### STATE_NOT_FOUND
When updating an issue to a non-existent status:

```yaml
error:
  code: STATE_NOT_FOUND
  message: "State 'In Review' not found in team"
  params:
    requestedState: "In Review"
    teamId: "psn123"
  suggestions:
    - "Use 'In Progress' (exact match required)"
    - "Available states: Backlog, Todo, In Progress, Done, Blocked"
    - "Check team configuration in Linear"
```

**Fix**: Use exact state name or `getValidStateId()` helper

#### LABEL_NOT_FOUND
When assigning a non-existent label:

```yaml
error:
  code: LABEL_NOT_FOUND
  message: "Label 'feature' not found"
  params:
    requestedLabel: "feature"
    teamId: "psn123"
  suggestions:
    - "Label will be created automatically"
    - "Use 'ensureLabelsExist()' to batch create"
    - "Available labels: bug, feature-request, documentation"
```

**Fix**: Use `getOrCreateLabel()` or `ensureLabelsExist()` helpers

#### ISSUE_NOT_FOUND
When accessing a non-existent issue:

```yaml
error:
  code: ISSUE_NOT_FOUND
  message: "Issue PSN-9999 not found"
  params:
    issueId: "PSN-9999"
  suggestions:
    - "Verify issue ID is correct (use Linear UI)"
    - "Check team/project context"
    - "Issue may have been archived"
```

**Fix**: Validate issue ID before using

---

## Examples

### Example 1: Get Issue with Caching

```markdown
Task(ccpm:linear-operations): `
operation: get_issue
params:
  issueId: PSN-29
context:
  cache: true
  command: "planning:plan"
  purpose: "Fetch task details for planning"
`
```

**Performance**: <50ms (cached)
**Token cost**: ~0.8k
**Result**: Issue object with title, description, status, labels, assignee

### Example 2: Update Issue Status and Labels

```markdown
Task(ccpm:linear-operations): `
operation: update_issue
params:
  issueId: PSN-29
  state: "In Progress"
  labels: ["planning", "implementation"]
context:
  cache: false
  command: "implementation:start"
  purpose: "Mark task as started with relevant labels"
`
```

**Performance**: 100-200ms (no cache)
**Token cost**: ~1.2k
**Result**: Updated issue with new status and labels

### Example 3: Create Comment with Context

```markdown
Task(ccpm:linear-operations): `
operation: create_comment
params:
  issueId: PSN-29
  body: |
    Progress update:
    - Implemented JWT authentication
    - 2 unit tests passing
    - Need to fix Redis integration

    Blockers:
    - Redis library compatibility
context:
  cache: false
  command: "implementation:sync"
  purpose: "Log implementation progress"
`
```

**Performance**: 150-300ms
**Token cost**: ~1.5k
**Result**: Comment added to issue with timestamp

### Example 4: Using Shared Helpers

```markdown
// Get or create label (delegates to subagent with caching)
const label = await getOrCreateLabel(teamId, "feature-request");

// Get valid state ID (fuzzy matching with suggestions)
const stateId = await getValidStateId(teamId, "In Progress");

// Ensure multiple labels exist
const labels = await ensureLabelsExist(teamId, [
  "planning",
  "implementation",
  "blocked"
]);

// Now use the results
Task(ccpm:linear-operations): `
operation: update_issue
params:
  issueId: PSN-29
  state: ${stateId}
  labels: ${labels.map(l => l.id)}
context:
  cache: false
  purpose: "Apply validated status and labels"
`
```

**Performance**: <100ms total (mostly cached lookups)
**Token cost**: ~1.8k
**Result**: Reliable label/status application with error prevention

### Example 5: Error Handling

```markdown
// PATTERN: Try operation, handle structured errors

Task(ccpm:linear-operations): `
operation: update_issue
params:
  issueId: PSN-29
  state: "Review"  // Might not exist
context:
  cache: false
  command: "implementation:sync"
`

// If error:
// {
//   code: "STATE_NOT_FOUND",
//   suggestions: ["Available states: Backlog, Todo, In Progress, Done"]
// }

// RECOVERY: Use helper or ask user
const stateId = await getValidStateId(teamId, "Review");
// Or ask user: "Which status should I use?"
```

**Pattern**: Structured errors guide user or helper selection

---

## Migration from Direct MCP

### Before: Direct MCP Call (Inefficient)

```markdown
// Direct call - no caching, higher token cost
Task(linear-operations): `
List issues in PSN project where status = "Todo"
`

// Result: ~2.5k tokens, 400ms, no future cache hits
```

### After: Via Subagent (Optimized)

```markdown
// Via subagent - automatic caching
Task(ccpm:linear-operations): `
operation: list_issues
params:
  projectId: "PSN"
  filter: {status: "Todo"}
context:
  cache: true
  command: "planning:plan"
`

// Result: ~0.9k tokens, <50ms, 85-95% cache hits next time
```

### Common Pitfalls to Avoid

```javascript
// ❌ DON'T: Forget caching
Task(ccpm:linear-operations): `
operation: get_issue
params:
  issueId: PSN-29
// Missing: context: cache: true
`

// ❌ DON'T: Use non-existent tools
Task(ccpm:linear-operations): `
operation: fetch_issue_details  // This doesn't exist
params:
  issueId: PSN-29
`

// ❌ DON'T: Cache writes
Task(ccpm:linear-operations): `
operation: update_issue
params:
  issueId: PSN-29
context:
  cache: true  // WRONG! Never cache writes
`

// ✅ DO: Follow patterns
Task(ccpm:linear-operations): `
operation: get_issue
params:
  issueId: PSN-29
context:
  cache: true  // ✅ Cache reads
  command: "planning:plan"
`
```

---

## Best Practices Summary

| Practice | Reason |
|----------|--------|
| Always use subagent for Linear ops | 50-60% token reduction |
| Enable caching on reads | 85-95% hit rate, <50ms performance |
| Disable caching on writes | Avoid stale data |
| Use shared helpers | Reduces duplication, better error handling |
| Validate tools against list | Prevent failures with non-existent tools |
| Provide context object | Better error messages and debugging |
| Handle structured errors | Graceful degradation and user guidance |

---

## References

- **Subagent Location**: `agents/linear-operations.md`
- **Shared Helpers**: `agents/_shared-linear-helpers.md`
- **Architecture Guide**: `docs/architecture/linear-subagent-architecture.md`
- **Migration Guide**: `docs/guides/migration/linear-subagent-migration.md`
- **Linear MCP Docs**: Available via `search_documentation` tool
