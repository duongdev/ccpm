# Jira Operations Subagent - Implementation Plan

**Part of**: PSN-31 - Phase 3: Token Efficiency
**Author**: Backend Architect Agent
**Date**: 2025-11-21
**Status**: Implementation Plan
**Version**: 1.0

---

## 1. Overview

The Jira Operations Subagent provides centralized, optimized access to all Jira operations with session-level caching and intelligent batching.

**Expected Impact**:
- **Token reduction**: 55-65% for Jira-heavy operations
- **API call reduction**: 70-75%
- **Cache hit rate**: 85-90% for metadata
- **Performance**: <100ms cached, <600ms uncached

---

## 2. Operation Catalog

### 2.1 Issue Operations (6 operations)

#### get_issue
**Purpose**: Retrieve single issue with optional expansions

**Input Contract**:
```yaml
operation: get_issue
params:
  issue_key: "TRAIN-123"           # Required (key or ID)
  expand:                          # Optional array
    - "changelog"
    - "comments"
    - "attachments"
  include_links: true              # Optional, default: true
context:
  command: "planning:plan"
```

**Output Contract**:
```yaml
success: true
data:
  id: "10234"
  key: "TRAIN-123"
  self: "https://site.atlassian.net/rest/api/3/issue/10234"
  fields:
    summary: "Implement JWT authentication"
    description: "Full description..."
    issuetype:
      id: "10001"
      name: "Task"
      iconUrl: "..."
    status:
      id: "1"
      name: "To Do"
      statusCategory:
        key: "new"
        name: "To Do"
    priority:
      id: "3"
      name: "High"
    assignee:
      accountId: "abc123"
      displayName: "John Doe"
      emailAddress: "john@example.com"
    reporter: { ... }
    created: "2025-01-15T10:00:00.000Z"
    updated: "2025-01-16T14:30:00.000Z"
    labels: ["backend", "security"]
    components: [...]
    customfield_10001: "custom value"
  changelog:         # If expand includes "changelog"
    histories: [...]
  comments:          # If expand includes "comments"
    comments: [...]
  issuelinks: [...]  # If include_links: true
metadata:
  cached: false
  duration_ms: 450
  mcp_calls: 1
  expansions_requested: ["changelog", "comments"]
```

**Implementation Logic**:
```javascript
async function get_issue(params) {
  const startTime = Date.now();

  // Step 1: Validate issue key format
  if (!isValidIssueKey(params.issue_key)) {
    return error("INVALID_ISSUE_KEY", "Invalid format");
  }

  // Step 2: Call Jira MCP
  try {
    const issue = await mcp__atlassian__getJiraIssue({
      cloudId: getCloudId(),
      issueIdOrKey: params.issue_key,
      expand: params.expand?.join(','),
      fields: "*all"  // Get all fields
    });

    // Step 3: Transform response
    const transformed = transformJiraIssue(issue);

    // Step 4: Optionally populate cache for referenced entities
    if (issue.fields.project) {
      cacheProject(issue.fields.project);
    }
    if (issue.fields.issuetype) {
      cacheIssueType(issue.fields.project.key, issue.fields.issuetype);
    }

    return {
      success: true,
      data: transformed,
      metadata: {
        cached: false,
        duration_ms: Date.now() - startTime,
        mcp_calls: 1,
        expansions_requested: params.expand || []
      }
    };
  } catch (error) {
    return handleJiraError(error, params);
  }
}
```

---

#### create_issue
**Purpose**: Create new Jira issue with validation and automatic resolution

**Input Contract**:
```yaml
operation: create_issue
params:
  project: "TRAIN"                 # Required (key or ID)
  issue_type: "Task"               # Required (name or ID)
  summary: "Implement feature X"   # Required
  description: |                   # Optional (Markdown → Jira format)
    ## Overview
    Implementation details...
  assignee: "john@example.com"    # Optional (email, name, accountId, or "me")
  reporter: "me"                   # Optional, default: current user
  priority: "High"                 # Optional (name or ID)
  labels: ["backend", "security"]  # Optional
  components: ["API"]              # Optional (names or IDs)
  parent: "TRAIN-100"              # Optional (for subtasks)
  epic_link: "TRAIN-50"            # Optional
  story_points: 8                  # Optional (custom field)
  sprint: "Sprint 23"              # Optional (name or ID)
  custom_fields:                   # Optional
    customfield_10001: "value"
    customfield_10002: 5
  links:                           # Optional
    - type: "relates to"
      issue_key: "TRAIN-99"
context:
  command: "planning:create"
  purpose: "Creating Jira issue from Linear task"
```

**Output Contract**:
```yaml
success: true
data:
  id: "10234"
  key: "TRAIN-124"
  self: "https://site.atlassian.net/rest/api/3/issue/10234"
  fields: { ... }  # Full issue object
metadata:
  cached: false
  duration_ms: 650
  mcp_calls: 5
  operations:
    - "resolve_project: TRAIN → 10045 (cached)"
    - "resolve_issue_type: Task → 10001 (cached)"
    - "resolve_priority: High → 3 (cached)"
    - "resolve_assignee: john@example.com → abc123 (cached)"
    - "transform_description: Markdown → Jira ADF"
    - "create_issue: success"
```

**Implementation Logic**:
```javascript
async function create_issue(params) {
  const startTime = Date.now();
  const operations = [];
  let mcpCalls = 0;

  // Step 1: Resolve project ID (with caching)
  const { projectId, cached: projectCached } = await resolveProjectId(params.project);
  operations.push(`resolve_project: ${params.project} → ${projectId} (${projectCached ? 'cached' : 'fetched'})`);
  if (!projectCached) mcpCalls++;

  // Step 2: Resolve issue type ID (with caching)
  const { issueTypeId, cached: typeCached } = await resolveIssueTypeId(projectId, params.issue_type);
  operations.push(`resolve_issue_type: ${params.issue_type} → ${issueTypeId} (${typeCached ? 'cached' : 'fetched'})`);
  if (!typeCached) mcpCalls++;

  // Step 3: Resolve priority (optional, with caching)
  let priorityId = null;
  if (params.priority) {
    const { id, cached } = await resolvePriorityId(params.priority);
    priorityId = id;
    operations.push(`resolve_priority: ${params.priority} → ${id} (${cached ? 'cached' : 'fetched'})`);
    if (!cached) mcpCalls++;
  }

  // Step 4: Resolve assignee (optional, with caching)
  let assigneeId = null;
  if (params.assignee) {
    if (params.assignee === "me") {
      assigneeId = await getCurrentUserAccountId();
    } else {
      const { accountId, cached } = await resolveUserAccountId(params.assignee);
      assigneeId = accountId;
      operations.push(`resolve_assignee: ${params.assignee} → ${accountId} (${cached ? 'cached' : 'fetched'})`);
      if (!cached) mcpCalls++;
    }
  }

  // Step 5: Transform description (Markdown → Jira ADF)
  let descriptionAdf = null;
  if (params.description) {
    descriptionAdf = markdownToJiraAdf(params.description);
    operations.push("transform_description: Markdown → Jira ADF");
  }

  // Step 6: Build issue fields
  const fields = {
    project: { id: projectId },
    issuetype: { id: issueTypeId },
    summary: params.summary,
    description: descriptionAdf
  };

  if (priorityId) fields.priority = { id: priorityId };
  if (assigneeId) fields.assignee = { accountId: assigneeId };
  if (params.labels) fields.labels = params.labels;
  if (params.components) {
    fields.components = await resolveComponentIds(projectId, params.components);
  }
  if (params.parent) {
    fields.parent = { key: params.parent };
  }

  // Add custom fields
  if (params.custom_fields) {
    Object.assign(fields, params.custom_fields);
  }

  // Step 7: Create issue via Jira MCP
  try {
    const issue = await mcp__atlassian__createJiraIssue({
      cloudId: getCloudId(),
      projectKey: params.project,
      issueTypeName: params.issue_type,
      summary: params.summary,
      description: params.description,
      assignee_account_id: assigneeId,
      additional_fields: {
        priority: priorityId ? { id: priorityId } : undefined,
        labels: params.labels,
        components: fields.components
      }
    });

    mcpCalls++;
    operations.push("create_issue: success");

    // Step 8: Add issue links if specified
    if (params.links) {
      for (const link of params.links) {
        await linkIssues(issue.key, link.issue_key, link.type);
        mcpCalls++;
      }
    }

    return {
      success: true,
      data: issue,
      metadata: {
        cached: false,
        duration_ms: Date.now() - startTime,
        mcp_calls: mcpCalls,
        operations
      }
    };
  } catch (error) {
    return handleJiraError(error, params);
  }
}
```

---

#### update_issue
**Purpose**: Update existing Jira issue fields

**Input Contract**:
```yaml
operation: update_issue
params:
  issue_key: "TRAIN-123"           # Required
  summary: "Updated summary"       # Optional
  description: "..."               # Optional (Markdown → Jira ADF)
  assignee: "jane@example.com"    # Optional
  priority: "Critical"             # Optional
  labels: ["backend", "urgent"]    # Optional (replaces existing)
  add_labels: ["hotfix"]           # Optional (adds to existing)
  remove_labels: ["low-priority"]  # Optional (removes from existing)
  custom_fields:                   # Optional
    customfield_10001: "new value"
context:
  command: "implementation:update"
```

**Output Contract**:
```yaml
success: true
data:
  id: "10234"
  key: "TRAIN-123"
  fields: { ... }  # Updated issue
metadata:
  cached: false
  duration_ms: 550
  mcp_calls: 3
  changes:
    - "priority: High → Critical"
    - "labels: [backend, security] → [backend, urgent, hotfix]"
    - "assignee: John Doe → Jane Smith"
```

---

#### transition_issue
**Purpose**: Change issue status/workflow state

**Input Contract**:
```yaml
operation: transition_issue
params:
  issue_key: "TRAIN-123"           # Required
  transition: "Done"               # Required (name or ID)
  resolution: "Fixed"              # Optional (for done transitions)
  comment: "Implementation complete"  # Optional
  assignee: "unassigned"           # Optional (change during transition)
  fields:                          # Optional (update fields during transition)
    customfield_10001: "value"
context:
  command: "verification:verify"
  purpose: "Marking task as complete"
```

**Output Contract**:
```yaml
success: true
data:
  issue_key: "TRAIN-123"
  previous_status: "In Progress"
  new_status: "Done"
  transition_id: "31"
  transition_name: "Done"
metadata:
  cached: false
  duration_ms: 450
  mcp_calls: 2
  operations:
    - "get_available_transitions (cached)"
    - "resolve_transition: Done → 31"
    - "execute_transition: success"
```

**Implementation Logic**:
```javascript
async function transition_issue(params) {
  // Step 1: Get available transitions (cached)
  const transitions = await getAvailableTransitions(params.issue_key);

  // Step 2: Find matching transition (fuzzy match)
  const transition = findTransition(transitions, params.transition);

  if (!transition) {
    return error("INVALID_TRANSITION", {
      message: `Transition '${params.transition}' not available`,
      available_transitions: transitions.map(t => ({ id: t.id, name: t.name })),
      suggestions: [
        "Use one of the available transitions listed above",
        "Check workflow configuration",
        `Run /ccpm:utils:jira-transitions ${params.issue_key}`
      ]
    });
  }

  // Step 3: Build transition request
  const transitionRequest = {
    transition: { id: transition.id }
  };

  if (params.resolution) {
    transitionRequest.fields = {
      resolution: { name: params.resolution }
    };
  }

  if (params.fields) {
    transitionRequest.fields = {
      ...transitionRequest.fields,
      ...params.fields
    };
  }

  // Step 4: Execute transition
  await mcp__atlassian__transitionJiraIssue({
    cloudId: getCloudId(),
    issueIdOrKey: params.issue_key,
    transition: transitionRequest.transition,
    fields: transitionRequest.fields
  });

  // Step 5: Add comment if provided
  if (params.comment) {
    await addComment(params.issue_key, params.comment);
  }

  return {
    success: true,
    data: {
      issue_key: params.issue_key,
      transition_id: transition.id,
      transition_name: transition.name
    }
  };
}
```

---

#### search_issues
**Purpose**: Search issues using JQL

**Input Contract**:
```yaml
operation: search_issues
params:
  jql: 'project = TRAIN AND status = "In Progress"'  # Required
  max_results: 50                  # Optional, default: 50
  start_at: 0                      # Optional (pagination)
  fields: ["summary", "status"]    # Optional (default: all)
  expand: []                       # Optional
context:
  command: "utils:search"
```

**Output Contract**:
```yaml
success: true
data:
  issues:
    - key: "TRAIN-123"
      fields: { ... }
    # ... more issues
  total: 142
  max_results: 50
  start_at: 0
metadata:
  cached: false
  duration_ms: 520
  mcp_calls: 1
  jql_query: 'project = TRAIN AND status = "In Progress"'
```

---

#### link_issues
**Purpose**: Create link between two issues

**Input Contract**:
```yaml
operation: link_issues
params:
  inward_issue: "TRAIN-123"        # Required
  outward_issue: "TRAIN-124"       # Required
  link_type: "relates to"          # Required (name or ID)
context:
  command: "planning:plan"
```

---

### 2.2 Comment Operations (2 operations)

#### add_comment
**Purpose**: Add comment to issue

**Input Contract**:
```yaml
operation: add_comment
params:
  issue_key: "TRAIN-123"           # Required
  body: |                          # Required (Markdown → Jira ADF)
    ## Update
    Implementation progress...
  visibility:                      # Optional (restrict visibility)
    type: "role"                   # "role" or "group"
    value: "Developers"
context:
  command: "implementation:sync"
```

---

#### get_comments
**Purpose**: Retrieve issue comments

**Input Contract**:
```yaml
operation: get_comments
params:
  issue_key: "TRAIN-123"           # Required
  start_at: 0                      # Optional (pagination)
  max_results: 50                  # Optional
  order_by: "created"              # Optional: "created", "-created"
context:
  command: "planning:plan"
```

---

### 2.3 Metadata Operations (4 operations)

#### get_project
**Purpose**: Get project details (heavily cached)

**Input Contract**:
```yaml
operation: get_project
params:
  project: "TRAIN"                 # Required (key or ID)
  expand: ["description", "lead"]  # Optional
context:
  command: "planning:create"
```

**Output Contract**:
```yaml
success: true
data:
  id: "10045"
  key: "TRAIN"
  name: "Training Project"
  projectTypeKey: "software"
  lead:
    accountId: "abc123"
    displayName: "Jane Doe"
  description: "..."
  url: "https://site.atlassian.net/projects/TRAIN"
metadata:
  cached: true
  duration_ms: 25
  mcp_calls: 0
```

---

#### get_issue_types
**Purpose**: Get available issue types for project

**Input Contract**:
```yaml
operation: get_issue_types
params:
  project: "TRAIN"                 # Required
context:
  command: "planning:create"
```

**Output Contract**:
```yaml
success: true
data:
  issue_types:
    - id: "10001"
      name: "Task"
      description: "A task that needs to be done"
      iconUrl: "..."
      subtask: false
    - id: "10002"
      name: "Bug"
      iconUrl: "..."
      subtask: false
    - id: "10003"
      name: "Sub-task"
      subtask: true
  total: 5
metadata:
  cached: true
  duration_ms: 30
  mcp_calls: 0
```

---

#### get_transitions
**Purpose**: Get available transitions for issue

**Input Contract**:
```yaml
operation: get_transitions
params:
  issue_key: "TRAIN-123"           # Required
context:
  command: "implementation:update"
```

**Output Contract**:
```yaml
success: true
data:
  transitions:
    - id: "21"
      name: "In Review"
      to:
        id: "3"
        name: "In Review"
    - id: "31"
      name: "Done"
      to:
        id: "6"
        name: "Done"
  total: 4
metadata:
  cached: true   # Cached per issue status
  duration_ms: 40
  mcp_calls: 0
```

---

#### get_priorities
**Purpose**: Get priority list (heavily cached)

**Input Contract**:
```yaml
operation: get_priorities
params: {}
context:
  command: "planning:create"
```

**Output Contract**:
```yaml
success: true
data:
  priorities:
    - id: "1"
      name: "Critical"
      iconUrl: "..."
    - id: "2"
      name: "High"
    - id: "3"
      name: "Medium"
    - id: "4"
      name: "Low"
  total: 5
metadata:
  cached: true
  duration_ms: 20
  mcp_calls: 0
```

---

## 3. Caching Implementation

### 3.1 Cache Structure

```javascript
const jiraCache = {
  // Projects (by key and ID)
  projects: {
    byKey: new Map(),      // "TRAIN" → ProjectObject
    byId: new Map()        // "10045" → ProjectObject
  },

  // Issue types (by project)
  issueTypes: {
    byProject: new Map()   // "TRAIN" → [IssueTypeArray]
  },

  // Priorities (global)
  priorities: {
    byId: new Map(),       // "3" → PriorityObject
    byName: new Map(),     // "High" → PriorityObject
    all: null              // Cached priority list
  },

  // Statuses (by project)
  statuses: {
    byProject: new Map()   // "TRAIN" → [StatusArray]
  },

  // Transitions (by issue status)
  transitions: {
    byIssueStatus: new Map()  // "TRAIN-123:In Progress" → [TransitionArray]
  },

  // Users (by accountId, email, name)
  users: {
    byAccountId: new Map(),
    byEmail: new Map(),
    byName: new Map()
  },

  // Components (by project)
  components: {
    byProject: new Map()   // "TRAIN" → [ComponentArray]
  }
};
```

### 3.2 Cache Population Strategy

**Projects**:
- **First access**: Fetch via MCP, cache by key and ID
- **Batch loading**: Not needed (projects accessed individually)
- **Hit rate target**: 95%

**Issue Types**:
- **First access per project**: Fetch all types for project
- **Cache key**: Project key
- **Hit rate target**: 90%

**Priorities**:
- **First access**: Fetch all priorities (global)
- **Never expires**: Priorities rarely change
- **Hit rate target**: 95%

**Users**:
- **First access**: Search user by email/name via MCP
- **Cache by**: accountId, email, name
- **Hit rate target**: 75%

### 3.3 Helper Functions

```javascript
// Resolve project ID with caching
async function resolveProjectId(projectKeyOrId) {
  // Check if UUID (project ID)
  if (isUUID(projectKeyOrId)) {
    let cached = jiraCache.projects.byId.get(projectKeyOrId);
    if (cached) return { projectId: projectKeyOrId, cached: true };

    // Fetch and cache
    const project = await fetchProject(projectKeyOrId);
    cacheProject(project);
    return { projectId: projectKeyOrId, cached: false };
  }

  // Check cache by key
  const cachedByKey = jiraCache.projects.byKey.get(projectKeyOrId);
  if (cachedByKey) {
    return { projectId: cachedByKey.id, cached: true };
  }

  // Fetch and cache
  const project = await fetchProjectByKey(projectKeyOrId);
  cacheProject(project);
  return { projectId: project.id, cached: false };
}

function cacheProject(project) {
  jiraCache.projects.byId.set(project.id, project);
  jiraCache.projects.byKey.set(project.key, project);
}

// Resolve issue type ID with caching
async function resolveIssueTypeId(projectKey, issueTypeName) {
  // Check cache for project's issue types
  let issueTypes = jiraCache.issueTypes.byProject.get(projectKey);

  if (!issueTypes) {
    // Fetch all issue types for project
    issueTypes = await fetchIssueTypesForProject(projectKey);
    jiraCache.issueTypes.byProject.set(projectKey, issueTypes);
  }

  // Find matching type (case-insensitive)
  const match = issueTypes.find(
    t => t.name.toLowerCase() === issueTypeName.toLowerCase()
  );

  if (match) {
    return { issueTypeId: match.id, cached: issueTypes !== null };
  }

  // Not found error
  return error("ISSUE_TYPE_NOT_FOUND", {
    message: `Issue type '${issueTypeName}' not found in project '${projectKey}'`,
    available_types: issueTypes.map(t => t.name),
    suggestions: [
      "Use exact issue type name from the list above",
      `Run /ccpm:utils:jira-issue-types ${projectKey}`
    ]
  });
}
```

---

## 4. Error Handling

### 4.1 Error Code Taxonomy

```yaml
# Entity Not Found (2000-2099)
2001: PROJECT_NOT_FOUND
2002: ISSUE_TYPE_NOT_FOUND
2003: ISSUE_NOT_FOUND
2004: USER_NOT_FOUND
2005: COMPONENT_NOT_FOUND
2006: VERSION_NOT_FOUND
2007: PRIORITY_NOT_FOUND

# Validation Errors (2100-2199)
2101: INVALID_ISSUE_KEY
2102: INVALID_TRANSITION
2103: REQUIRED_FIELD_MISSING
2104: INVALID_FIELD_VALUE
2105: PERMISSION_DENIED
2106: WORKFLOW_VALIDATION_ERROR

# API Errors (2400-2499)
2401: JIRA_API_ERROR
2402: JIRA_API_RATE_LIMIT
2403: JIRA_API_TIMEOUT
2404: JIRA_API_UNAUTHORIZED
```

### 4.2 Error Response Examples

**INVALID_TRANSITION**:
```yaml
success: false
error:
  code: INVALID_TRANSITION
  message: "Cannot transition TRAIN-123 to 'Done' - invalid workflow state"
  details:
    issue_key: "TRAIN-123"
    current_status: "To Do"
    requested_transition: "Done"
    available_transitions:
      - id: "11"
        name: "Start Progress"
        to: "In Progress"
      - id: "21"
        name: "Block"
        to: "Blocked"
  suggestions:
    - "Transition to 'In Progress' first"
    - "Check project workflow configuration"
    - "Run /ccpm:utils:jira-transitions TRAIN-123"
metadata:
  duration_ms: 280
  mcp_calls: 1
```

**REQUIRED_FIELD_MISSING**:
```yaml
success: false
error:
  code: REQUIRED_FIELD_MISSING
  message: "Cannot create issue - required field 'Story Points' is missing"
  details:
    project: "TRAIN"
    issue_type: "Story"
    missing_fields:
      - field_id: "customfield_10016"
        field_name: "Story Points"
        field_type: "number"
        required: true
  suggestions:
    - "Add story_points: 8 to params"
    - "Or use custom_fields: { customfield_10016: 8 }"
    - "Run /ccpm:utils:jira-issue-types TRAIN for field requirements"
```

---

## 5. Performance Benchmarks

### 5.1 Target Metrics

| Operation | Current (Direct MCP) | Target (Subagent) | Improvement |
|-----------|---------------------|-------------------|-------------|
| create_issue (cold) | 2800ms, 5 calls | 650ms, 1 call | 77% faster, 80% fewer calls |
| create_issue (warm) | 2800ms, 5 calls | 200ms, 1 call | 93% faster, 80% fewer calls |
| transition_issue | 1500ms, 3 calls | 450ms, 1 call | 70% faster, 67% fewer calls |
| search_issues | 800ms, 1 call | 520ms, 1 call | 35% faster (batching) |

### 5.2 Cache Performance

| Cache Type | Hit Rate | Cached Latency | Uncached Latency |
|------------|----------|----------------|------------------|
| Projects | 95% | 25ms | 400ms |
| Issue Types | 90% | 30ms | 350ms |
| Priorities | 95% | 20ms | 300ms |
| Users | 75% | 35ms | 400ms |
| Transitions | 60% | 40ms | 380ms |

---

## 6. Testing Strategy

### 6.1 Unit Tests

```javascript
// Test: resolveProjectId with caching
test('resolveProjectId caches correctly', async () => {
  // First call - cache miss
  const result1 = await resolveProjectId('TRAIN');
  expect(result1.cached).toBe(false);
  expect(result1.projectId).toBe('10045');

  // Second call - cache hit
  const result2 = await resolveProjectId('TRAIN');
  expect(result2.cached).toBe(true);
  expect(result2.projectId).toBe('10045');
});

// Test: create_issue with all parameters
test('create_issue handles all parameters', async () => {
  const result = await create_issue({
    project: 'TRAIN',
    issue_type: 'Task',
    summary: 'Test task',
    description: '## Test\nDescription',
    assignee: 'john@example.com',
    priority: 'High',
    labels: ['test']
  });

  expect(result.success).toBe(true);
  expect(result.data.key).toMatch(/TRAIN-\d+/);
  expect(result.metadata.operations).toContain('resolve_project: TRAIN');
});

// Test: transition_issue error handling
test('transition_issue validates transitions', async () => {
  const result = await transition_issue({
    issue_key: 'TRAIN-123',
    transition: 'Invalid Transition'
  });

  expect(result.success).toBe(false);
  expect(result.error.code).toBe('INVALID_TRANSITION');
  expect(result.error.suggestions).toBeDefined();
});
```

### 6.2 Integration Tests

```markdown
# Test: Full workflow (create → transition → comment)

1. Create issue
   - Verify issue created
   - Check metadata shows cached lookups
   - Validate token usage < 800 tokens

2. Transition issue
   - Verify transition succeeded
   - Check new status
   - Validate token usage < 400 tokens

3. Add comment
   - Verify comment added
   - Check comment body
   - Validate token usage < 300 tokens

Total token usage: < 1500 tokens (vs 3500 before)
```

---

## 7. Migration Checklist

### 7.1 Implementation Tasks

- [ ] Create `agents/jira-operations.md` scaffold
- [ ] Implement cache structure
- [ ] Implement all 12 operations
- [ ] Add error handling for all error codes
- [ ] Write unit tests (>90% coverage)
- [ ] Write integration tests
- [ ] Document all operations
- [ ] Create migration guide

### 7.2 Command Migration Tasks

- [ ] Migrate `planning:plan` (highest token usage)
- [ ] Migrate `planning:create`
- [ ] Migrate `verification:verify`
- [ ] Migrate remaining commands
- [ ] Update documentation

### 7.3 Validation Tasks

- [ ] Benchmark token usage (target: 55-65% reduction)
- [ ] Measure cache hit rates (target: 85%+)
- [ ] Validate error handling
- [ ] Test backward compatibility
- [ ] Performance testing

---

## 8. Next Steps

1. **Review and approve this implementation plan**
2. **Create agent file scaffold**
3. **Implement cache layer first**
4. **Add operations incrementally**
5. **Test each operation thoroughly**
6. **Migrate highest-traffic commands**
7. **Monitor performance and optimize**

---

**Document Version**: 1.0
**Last Updated**: 2025-11-21
**Ready for**: Implementation
