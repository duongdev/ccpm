# Subagent Usage Patterns

## Overview

This guide documents patterns for using specialized subagents in CCPM commands, using the Linear subagent as the primary example.

## Linear Operations Subagent

**Location**: `/Users/duongdev/personal/ccpm/agents/linear-operations.md`
**Purpose**: Centralized Linear API operations with session-level caching

### When to Use

Use the linear-operations subagent for:
- **Linear API read operations** (get_issue, list_issues, search_issues)
- **Workfow state detection** (detectStaleSync, checkTaskCompletion)
- **Batch label operations** (ensure_labels_exist, list_labels)
- **Status management** (get_valid_state_id, list_statuses)
- **Team/project lookups** (get_team, get_project, list_projects)

### Basic Pattern

```javascript
// Step 1: Invoke subagent with structured YAML request
const result = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "PSN-123"
  include_comments: true
context:
  command: "planning:plan"
  purpose: "Fetching issue for planning phase"
`);

// Step 2: Check success flag
if (!result.success) {
  // Handle error
  console.error(result.error);
  return safeDefault;
}

// Step 3: Extract data and process locally
const issue = result.data;
const processedData = localProcessing(issue);
```

### Common Operations

#### 1. Get Single Issue (with comments)

```javascript
const linearResult = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: true
  include_attachments: false
context:
  command: "workflow:detect-stale"
  purpose: "Checking if sync comments are stale"
`);

const issue = linearResult.data;
const comments = issue.comments || [];
```

#### 2. Get Single Issue (description only)

```javascript
const linearResult = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: false
  include_attachments: false
context:
  command: "workflow:check-completion"
  purpose: "Parsing checklist from description"
`);

const issue = linearResult.data;
const description = issue.description;
```

#### 3. Create Issue with Labels

```javascript
const linearResult = await Task('linear-operations', `
operation: create_issue
params:
  team: "Engineering"
  title: "Implement feature X"
  description: |
    ## Overview
    ${DESCRIPTION_TEXT}
  state: "In Progress"
  labels:
    - "planning"
    - "backend"
  assignee: "me"
context:
  command: "planning:create"
  purpose: "Creating new planned task"
`);

const newIssue = linearResult.data;
const issueId = newIssue.identifier;
```

#### 4. Search/List Issues

```javascript
const linearResult = await Task('linear-operations', `
operation: list_issues
params:
  team: "Engineering"
  state: "In Progress"
  assignee: "me"
  labels: ["planning"]
  limit: 50
context:
  command: "utils:search"
  purpose: "Finding active tasks"
`);

const issues = linearResult.data.issues;
const total = linearResult.data.total;
```

#### 5. Ensure Labels Exist

```javascript
const linearResult = await Task('linear-operations', `
operation: ensure_labels_exist
params:
  team: "Engineering"
  labels:
    - name: "planning"
      color: "#f7c8c1"
    - name: "implementation"
      color: "#26b5ce"
context:
  command: "planning:create"
  purpose: "Ensuring CCPM workflow labels exist"
`);

const labels = linearResult.data.labels;
```

### Error Handling

#### Pattern 1: Graceful Degradation (Recommended for State Detection)

```javascript
const linearResult = await Task('linear-operations', `...`);

if (!linearResult.success) {
  return {
    isStale: false,  // Safe default
    error: linearResult.error?.message
  };
}

// Continue processing
```

#### Pattern 2: User Error (Recommended for Operations)

```javascript
const linearResult = await Task('linear-operations', `...`);

if (!linearResult.success) {
  console.error('Failed to fetch issue:', linearResult.error);
  return {
    success: false,
    error: {
      code: linearResult.error?.code,
      message: linearResult.error?.message,
      suggestions: linearResult.error?.suggestions
    }
  };
}

// Continue processing
```

### Response Structure

All subagent operations return a structured response:

```javascript
{
  success: true|false,
  data: { /* operation-specific data */ },
  error?: {
    code: "ERROR_CODE",
    message: "Human-readable message",
    details: { /* context-specific details */ },
    suggestions: ["Suggestion 1", "Suggestion 2"]
  },
  metadata: {
    cached: true|false,
    duration_ms: 150,
    mcp_calls: 1,
    // ... operation-specific metadata
  }
}
```

### Caching Behavior

The linear-operations subagent provides automatic session-level caching:

```javascript
// First call: 400-500ms (uncached)
let result1 = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "PSN-123"
  include_comments: true
context: ...
`);
// result1.metadata.cached = false
// result1.metadata.duration_ms = 450

// Second call: <50ms (cached)
let result2 = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "PSN-123"
  include_comments: true
context: ...
`);
// result2.metadata.cached = true
// result2.metadata.duration_ms = 25

// Cached data is identical
assert(result1.data === result2.data);
```

**Cache Scope**: Session-level (cleared at end of command execution)

**Cache Control**: Use `refresh_cache: true` parameter to bypass cache for specific operations.

### YAML Format Guidelines

#### Parameters Format

Use YAML parameter format (not JSON):

**Correct**:
```yaml
params:
  issue_id: "PSN-123"
  include_comments: true
  labels:
    - "planning"
    - "backend"
```

**Incorrect**:
```javascript
params: {
  "issue_id": "PSN-123",
  "include_comments": true,
  "labels": ["planning", "backend"]
}
```

#### String Interpolation

Use double quotes for string templates:

```javascript
await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  description: "Description: ${description}"
`);
```

#### Multiline Text

Use pipe (`|`) for multiline descriptions:

```yaml
operation: create_issue
params:
  title: "Issue Title"
  description: |
    ## Section 1
    Some text here.

    ## Section 2
    More text.
```

### Performance Considerations

#### Token Usage

- **Per-operation overhead**: ~200-300 tokens
- **Subagent base load**: ~100-150 tokens
- **Data transfer**: ~50-100 tokens per field

**Example**:
- Direct MCP call: 2500 tokens
- Via subagent: 400 tokens (84% reduction)

#### Execution Time

- **Cached**: <50ms
- **Uncached**: 400-600ms depending on operation
- **Network latency**: Generally 200-300ms of above

#### Optimization Tips

1. **Enable caching** - Don't use `refresh_cache: true` unless necessary
2. **Batch operations** - Use `ensure_labels_exist` instead of multiple calls
3. **Request only needed data** - Set `include_comments: false` if not needed
4. **Reuse results** - Store responses locally instead of making duplicate requests

### Common Patterns

#### Pattern 1: Check and Create

```javascript
// Check if issue exists
const getResult = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
context:
  command: "check:exist"
`);

if (!getResult.success && getResult.error.code === 'ISSUE_NOT_FOUND') {
  // Create if doesn't exist
  const createResult = await Task('linear-operations', `
operation: create_issue
params:
  team: "Engineering"
  title: "New Issue"
context:
  command: "create:new"
`);

  return createResult.data;
}

return getResult.data;
```

#### Pattern 2: Batch with Error Handling

```javascript
// Create multiple issues
const issueIds = ['PSN-1', 'PSN-2', 'PSN-3'];
const results = [];

for (const issueId of issueIds) {
  const result = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
context:
  command: "batch:fetch"
`);

  if (result.success) {
    results.push(result.data);
  } else {
    console.warn(`Failed to fetch ${issueId}:`, result.error);
  }
}

return results;
```

#### Pattern 3: Conditional Processing

```javascript
const linearResult = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: true
context:
  command: "analyze:sync-status"
`);

if (!linearResult.success) {
  return handleError(linearResult.error);
}

const issue = linearResult.data;

if (issue.state.type === 'completed') {
  return handleCompleted(issue);
}

if (issue.comments.length === 0) {
  return handleNoComments(issue);
}

return handleNormal(issue);
```

## Integration Checklist

When adding subagent usage to a command:

- [ ] **Import/require**: No imports needed (Task function provided by runtime)
- [ ] **YAML format**: Verify YAML is valid (test with parser)
- [ ] **Operation name**: Check subagent docs for correct operation name
- [ ] **Parameters**: Verify all required params are provided
- [ ] **Context**: Include command and purpose for logging
- [ ] **Error handling**: Check `success` flag before accessing `data`
- [ ] **Default values**: Provide safe defaults for errors
- [ ] **Local processing**: Keep business logic local
- [ ] **Testing**: Mock `Task()` in unit tests
- [ ] **Documentation**: Update command docs if adding new operations

## Troubleshooting

### Operation Not Found

**Error**: `{ success: false, error: { code: "OPERATION_NOT_FOUND" } }`

**Fix**: Check spelling of operation name against subagent docs.

### Invalid Parameters

**Error**: `{ success: false, error: { code: "INVALID_PARAM" } }`

**Fix**: Verify parameter names and types match subagent schema.

### Performance Issues

**Issue**: Commands running slow
**Check**:
1. Is cache being used? (Check `metadata.cached`)
2. Are you bypassing cache with `refresh_cache: true`?
3. Are multiple requests being made for same data?
4. Are operations running in sequence that could be parallel?

### YAML Parsing Errors

**Issue**: Subagent not parsing request
**Fix**:
1. Validate YAML syntax (use online validator)
2. Check quote usage (double quotes for strings)
3. Verify indentation (2-space standard)
4. Test string interpolation separately

## Related Documentation

- [Linear Operations Subagent](../../agents/linear-operations.md)
- [Workflow State Refactoring](./psn-29-workflow-state-refactoring.md)
- [CCPM Architecture](./architecture-overview.md)
