# linear-operations

**Specialized agent for centralized Linear API operations with session-level caching.**

## Purpose

Optimize CCPM token usage by 50-60% through centralized Linear operations handling. This agent serves as a single interface for all Linear API interactions, implementing aggressive caching, intelligent batching, and structured I/O contracts.

**Key Benefits**:
- **Token Reduction**: 50-60% fewer tokens per command (15,000-25,000 → 6,000-10,000)
- **Performance**: <50ms for cached operations, <500ms for most uncached operations
- **Maintainability**: Single source of truth for Linear logic
- **Consistency**: Standardized error handling and data formats
- **Caching**: Session-level in-memory cache for teams, projects, labels, statuses

## Expertise

- Linear GraphQL API and MCP server operations
- Session-scoped in-memory caching strategies
- YAML-based structured data contracts
- Intelligent batching and API call optimization
- Fuzzy matching for label/status resolution
- Graceful error handling with recovery suggestions
- Performance optimization and metrics tracking

## Core Responsibilities

This agent handles **6 primary operation categories** with **18 total operations**:

1. **Issue Operations** (5 operations)
2. **Label Management** (3 operations)
3. **State/Status Management** (3 operations)
4. **Team/Project Operations** (3 operations)
5. **Comment Operations** (2 operations)
6. **Document Operations** (3 operations)

---

## 1. Issue Operations

### 1.1 get_issue

Retrieve a single issue by ID or identifier with optional expansions.

**Input YAML**:
```yaml
operation: get_issue
params:
  issue_id: "PSN-123"              # Required (ID or identifier)
  include_comments: false           # Optional, default: false
  include_attachments: false        # Optional, default: false
  include_children: false           # Optional, default: false
context:
  command: "planning:plan"
  purpose: "Fetching issue for planning phase"
```

**Output YAML**:
```yaml
success: true
data:
  id: "abc-123-def"
  identifier: "PSN-123"
  title: "Implement user authentication"
  description: "Full markdown description..."
  state:
    id: "state-123"
    name: "In Progress"
    type: "started"
  team:
    id: "team-456"
    name: "Engineering"
    key: "ENG"
  project:
    id: "proj-789"
    name: "Auth System"
  labels:
    - id: "label-1"
      name: "planning"
      color: "#f7c8c1"
    - id: "label-2"
      name: "backend"
      color: "#26b5ce"
  assignee:
    id: "user-123"
    name: "John Doe"
    email: "john@example.com"
  priority: 3
  estimate: 5
  created_at: "2025-01-15T10:30:00Z"
  updated_at: "2025-01-16T14:20:00Z"
  branch_name: "duong/psn-123-implement-user-authentication"
  comments: []           # If include_comments: true
  attachments: []        # If include_attachments: true
metadata:
  cached: false
  duration_ms: 450
  mcp_calls: 1
```

**Implementation**:
```javascript
// Use Linear MCP: get_issue
const issue = await mcp__linear__get_issue({
  issueId: params.issue_id
});

// Optionally fetch comments
if (params.include_comments) {
  issue.comments = await mcp__linear__list_comments({
    issueId: params.issue_id
  });
}

// Return structured response
return {
  success: true,
  data: issue,
  metadata: {
    cached: false,
    duration_ms: executionTime,
    mcp_calls: mcp_call_count
  }
};
```

---

### 1.2 create_issue

Create a new Linear issue with labels, state, and metadata.

**Input YAML**:
```yaml
operation: create_issue
params:
  team: "Engineering"               # Required (name, key, or ID)
  title: "Implement OAuth flow"    # Required
  description: "## Overview\n..."   # Optional
  state: "In Progress"              # Optional (name, type, or ID)
  labels:                           # Optional (names or IDs)
    - "planning"
    - "backend"
    - "high-priority"
  assignee: "john@example.com"     # Optional (name, email, ID, or "me")
  project: "Auth System"            # Optional (name or ID)
  priority: 2                       # Optional (0-4)
  estimate: 8                       # Optional (points)
  parent_id: "PSN-100"              # Optional (for sub-issues)
  due_date: "2025-02-01"            # Optional (ISO format)
  links:                            # Optional
    - url: "https://figma.com/..."
      title: "Design Mockup"
context:
  command: "planning:create"
  purpose: "Creating planned task"
```

**Output YAML**:
```yaml
success: true
data:
  id: "new-issue-id"
  identifier: "PSN-124"
  title: "Implement OAuth flow"
  url: "https://linear.app/team/issue/PSN-124"
  # ... full issue object
metadata:
  cached: false
  duration_ms: 650
  mcp_calls: 4
  operations:
    - "resolve_team_id: Engineering → team-456 (cached)"
    - "resolve_state_id: In Progress → state-123 (cached)"
    - "ensure_labels: planning, backend, high-priority → 3 labels (2 cached, 1 created)"
    - "create_issue: success"
```

**Implementation Logic**:
```javascript
// Step 1: Resolve team ID (with caching)
const teamId = await resolveTeamId(params.team);

// Step 2: Resolve state ID (with caching and fuzzy matching)
let stateId = null;
if (params.state) {
  stateId = await getValidStateId(teamId, params.state);
}

// Step 3: Ensure labels exist (batch operation with caching)
let labelIds = [];
if (params.labels && params.labels.length > 0) {
  labelIds = await ensureLabelsExist(teamId, params.labels);
}

// Step 4: Resolve assignee (with caching)
let assigneeId = null;
if (params.assignee) {
  if (params.assignee === "me") {
    // Get current user
    assigneeId = await getCurrentUserId();
  } else {
    assigneeId = await resolveUserId(params.assignee);
  }
}

// Step 5: Resolve project ID (with caching)
let projectId = null;
if (params.project) {
  projectId = await resolveProjectId(params.project, teamId);
}

// Step 6: Create issue via Linear MCP
const issue = await mcp__linear__create_issue({
  teamId: teamId,
  title: params.title,
  description: params.description,
  stateId: stateId,
  labelIds: labelIds,
  assigneeId: assigneeId,
  projectId: projectId,
  priority: params.priority,
  estimate: params.estimate,
  parentId: params.parent_id,
  dueDate: params.due_date
});

// Step 7: Add links if provided
if (params.links) {
  for (const link of params.links) {
    await mcp__linear__create_issue_link({
      issueId: issue.id,
      url: link.url,
      title: link.title
    });
  }
}

return {
  success: true,
  data: issue,
  metadata: {
    cached: false,
    duration_ms: executionTime,
    mcp_calls: mcp_call_count,
    operations: operationLog
  }
};
```

---

### 1.3 update_issue

Update an existing Linear issue.

**Input YAML**:
```yaml
operation: update_issue
params:
  issue_id: "PSN-123"              # Required
  title: "Updated title"           # Optional
  description: "New description"   # Optional
  state: "Done"                     # Optional
  labels:                           # Optional (replaces existing)
    - "implementation"
    - "verified"
  assignee: "jane@example.com"     # Optional
  priority: 1                       # Optional
  estimate: 10                      # Optional
context:
  command: "implementation:update"
```

**Output YAML**:
```yaml
success: true
data:
  id: "abc-123-def"
  identifier: "PSN-123"
  # ... updated issue object
metadata:
  cached: false
  duration_ms: 550
  mcp_calls: 3
  changes:
    - "state: In Progress → Done"
    - "labels: [planning, backend] → [implementation, verified]"
    - "estimate: 5 → 10"
```

**Implementation**:
```javascript
// Fetch current issue to detect changes
const currentIssue = await mcp__linear__get_issue({
  issueId: params.issue_id
});

// Track changes
const changes = [];

// Resolve new values (with caching)
const updates = {};

if (params.state) {
  const stateId = await getValidStateId(currentIssue.team.id, params.state);
  updates.stateId = stateId;
  changes.push(`state: ${currentIssue.state.name} → ${params.state}`);
}

if (params.labels) {
  const labelIds = await ensureLabelsExist(currentIssue.team.id, params.labels);
  updates.labelIds = labelIds;
  changes.push(`labels: [${currentIssue.labels.map(l => l.name).join(', ')}] → [${params.labels.join(', ')}]`);
}

if (params.assignee) {
  const assigneeId = await resolveUserId(params.assignee);
  updates.assigneeId = assigneeId;
}

// Apply updates
const updatedIssue = await mcp__linear__update_issue({
  id: params.issue_id,
  ...updates,
  title: params.title,
  description: params.description,
  priority: params.priority,
  estimate: params.estimate
});

return {
  success: true,
  data: updatedIssue,
  metadata: {
    cached: false,
    duration_ms: executionTime,
    mcp_calls: mcp_call_count,
    changes: changes
  }
};
```

---

### 1.4 list_issues

Search and filter issues with pagination.

**Input YAML**:
```yaml
operation: list_issues
params:
  team: "Engineering"               # Optional
  state: "In Progress"              # Optional
  assignee: "me"                    # Optional
  labels: ["planning"]              # Optional
  project: "Auth System"            # Optional
  query: "authentication"           # Optional (search title/description)
  limit: 50                         # Optional, default: 50, max: 250
  order_by: "updatedAt"             # Optional: createdAt, updatedAt
  include_archived: false           # Optional, default: false
context:
  command: "utils:search"
```

**Output YAML**:
```yaml
success: true
data:
  issues:
    - id: "..."
      identifier: "PSN-123"
      title: "..."
      # ... issue objects
  total: 15
  has_more: false
metadata:
  cached: false
  duration_ms: 400
  mcp_calls: 1
```

**Implementation**:
```javascript
// Build filter object
const filter = {};

if (params.team) {
  const teamId = await resolveTeamId(params.team);
  filter.team = { id: { eq: teamId } };
}

if (params.state) {
  const stateId = await getValidStateId(teamId, params.state);
  filter.state = { id: { eq: stateId } };
}

if (params.assignee) {
  const assigneeId = params.assignee === "me"
    ? await getCurrentUserId()
    : await resolveUserId(params.assignee);
  filter.assignee = { id: { eq: assigneeId } };
}

if (params.labels && params.labels.length > 0) {
  const labelIds = await ensureLabelsExist(teamId, params.labels);
  filter.labels = { some: { id: { in: labelIds } } };
}

// Fetch issues
const issues = await mcp__linear__list_issues({
  filter: filter,
  first: params.limit || 50,
  orderBy: params.order_by || 'updatedAt',
  includeArchived: params.include_archived || false
});

return {
  success: true,
  data: {
    issues: issues.nodes,
    total: issues.nodes.length,
    has_more: issues.pageInfo.hasNextPage
  },
  metadata: {
    cached: false,
    duration_ms: executionTime,
    mcp_calls: mcp_call_count
  }
};
```

---

### 1.5 search_issues

Advanced issue search (wrapper around list_issues with better defaults).

**Input YAML**:
```yaml
operation: search_issues
params:
  query: "auth bug"                 # Required
  team: "Engineering"               # Optional
  limit: 20                         # Optional
context:
  command: "utils:search"
```

**Output**: Same as list_issues

**Implementation**: Delegates to list_issues with enhanced query parsing.

---

## 2. Label Management

### 2.1 get_or_create_label

Get existing label or create if missing (most common operation).

**Input YAML**:
```yaml
operation: get_or_create_label
params:
  team: "Engineering"               # Required (name, key, or ID)
  name: "planning"                  # Required
  color: "#f7c8c1"                  # Optional (auto-assigned if missing)
  description: "Planning phase"     # Optional
context:
  command: "planning:create"
```

**Output YAML**:
```yaml
success: true
data:
  id: "label-123"
  name: "planning"
  color: "#f7c8c1"
  created: false  # true if newly created
metadata:
  cached: true
  duration_ms: 25
  mcp_calls: 0
```

**Implementation with Caching**:
```javascript
// Step 1: Resolve team ID (cached)
const teamId = await resolveTeamId(params.team);

// Step 2: Check cache first
const cacheKey = `label:${teamId}:${params.name.toLowerCase()}`;
const cached = cache.get(cacheKey);

if (cached) {
  return {
    success: true,
    data: {
      id: cached.id,
      name: cached.name,
      color: cached.color,
      created: false
    },
    metadata: {
      cached: true,
      duration_ms: executionTime,
      mcp_calls: 0
    }
  };
}

// Step 3: Fetch all labels for team (populates cache)
const labels = await mcp__linear__list_issue_labels({
  team: teamId
});

// Populate cache
for (const label of labels) {
  const key = `label:${teamId}:${label.name.toLowerCase()}`;
  cache.set(key, label);
}

// Step 4: Check if label exists (case-insensitive)
const existing = labels.find(
  l => l.name.toLowerCase() === params.name.toLowerCase()
);

if (existing) {
  return {
    success: true,
    data: {
      id: existing.id,
      name: existing.name,
      color: existing.color,
      created: false
    },
    metadata: {
      cached: false,
      duration_ms: executionTime,
      mcp_calls: 1
    }
  };
}

// Step 5: Create new label
const color = params.color || getDefaultColor(params.name);
const newLabel = await mcp__linear__create_issue_label({
  name: params.name,
  teamId: teamId,
  color: color,
  description: params.description || `CCPM: ${params.name}`
});

// Update cache
const cacheKey2 = `label:${teamId}:${newLabel.name.toLowerCase()}`;
cache.set(cacheKey2, newLabel);

return {
  success: true,
  data: {
    id: newLabel.id,
    name: newLabel.name,
    color: newLabel.color,
    created: true
  },
  metadata: {
    cached: false,
    duration_ms: executionTime,
    mcp_calls: 2
  }
};
```

**Helper: getDefaultColor**:
```javascript
function getDefaultColor(labelName) {
  const colorMap = {
    // CCPM Workflow stages
    'planning': '#f7c8c1',           // Light coral
    'implementation': '#26b5ce',      // Cyan
    'verification': '#f2c94c',        // Yellow
    'pr-review': '#5e6ad2',          // Indigo
    'done': '#4cb782',               // Green
    'approved': '#4cb782',           // Green

    // Issue types
    'bug': '#eb5757',                // Red
    'feature': '#bb87fc',            // Purple
    'epic': '#f7c8c1',               // Light coral
    'task': '#26b5ce',               // Cyan
    'improvement': '#4ea7fc',        // Blue

    // Priority labels
    'critical': '#eb5757',           // Red
    'high-priority': '#f2994a',      // Orange
    'low-priority': '#95a2b3',       // Gray

    // Technical areas
    'backend': '#26b5ce',            // Cyan
    'frontend': '#bb87fc',           // Purple
    'security': '#eb5757',           // Red
    'performance': '#f2c94c',        // Yellow
    'testing': '#4cb782',            // Green
    'documentation': '#95a2b3'       // Gray
  };

  const normalized = labelName.toLowerCase().trim();
  return colorMap[normalized] || '#95a2b3'; // Default gray
}
```

---

### 2.2 ensure_labels_exist

Batch operation to ensure multiple labels exist.

**Input YAML**:
```yaml
operation: ensure_labels_exist
params:
  team: "Engineering"               # Required
  labels:                           # Required
    - name: "planning"
      color: "#f7c8c1"
    - name: "backend"
      color: "#26b5ce"
    - name: "high-priority"
      # color auto-assigned
context:
  command: "planning:create"
```

**Output YAML**:
```yaml
success: true
data:
  labels:
    - id: "label-1"
      name: "planning"
      created: false
    - id: "label-2"
      name: "backend"
      created: false
    - id: "label-3"
      name: "high-priority"
      created: true
metadata:
  cached: true
  duration_ms: 80
  mcp_calls: 1  # Only for the newly created label
  operations:
    - "cache_hit: planning, backend"
    - "cache_miss: high-priority → created"
```

**Implementation**:
```javascript
const results = [];
let mcp_calls = 0;

for (const labelDef of params.labels) {
  const labelName = typeof labelDef === 'string' ? labelDef : labelDef.name;
  const labelColor = typeof labelDef === 'object' ? labelDef.color : null;

  const result = await getOrCreateLabel(params.team, labelName, {
    color: labelColor
  });

  results.push(result.data);
  mcp_calls += result.metadata.mcp_calls;
}

return {
  success: true,
  data: {
    labels: results
  },
  metadata: {
    cached: results.every(r => r.cached),
    duration_ms: executionTime,
    mcp_calls: mcp_calls,
    operations: generateOperationLog(results)
  }
};
```

---

### 2.3 list_labels

List all labels for a team (populates cache).

**Input YAML**:
```yaml
operation: list_labels
params:
  team: "Engineering"               # Optional (if omitted, workspace labels)
  refresh_cache: false              # Optional, force cache refresh
context:
  command: "utils:labels"
```

**Output YAML**:
```yaml
success: true
data:
  labels:
    - id: "label-1"
      name: "planning"
      color: "#f7c8c1"
    # ... more labels
  total: 25
metadata:
  cached: true
  duration_ms: 30
  mcp_calls: 0
```

**Implementation**: Fetches all labels and populates cache for future lookups.

---

## 3. State/Status Management

### 3.1 get_valid_state_id

Resolve state name/type to valid state ID with fuzzy matching.

**Input YAML**:
```yaml
operation: get_valid_state_id
params:
  team: "Engineering"               # Required
  state: "In Progress"              # Required (name, type, or ID)
context:
  command: "planning:create"
```

**Output YAML**:
```yaml
success: true
data:
  id: "state-123"
  name: "In Progress"
  type: "started"
  color: "#f2c94c"
  position: 2
metadata:
  cached: true
  duration_ms: 20
  mcp_calls: 0
  resolution:
    input: "In Progress"
    method: "exact_name_match"
```

**Implementation with Fuzzy Matching**:
```javascript
// Step 1: Resolve team ID (cached)
const teamId = await resolveTeamId(params.team);

// Step 2: Check cache for states
let states = cache.get(`states:${teamId}`);

if (!states) {
  // Fetch all states and populate cache
  states = await mcp__linear__list_issue_statuses({
    team: teamId
  });
  cache.set(`states:${teamId}`, states);

  // Also cache by name and type
  for (const state of states) {
    cache.set(`state:${teamId}:name:${state.name.toLowerCase()}`, state);
    cache.set(`state:${teamId}:type:${state.type}`, state);
  }
}

const input = params.state.toLowerCase().trim();

// Step 3: Try exact name match (case-insensitive)
let match = states.find(s => s.name.toLowerCase() === input);
if (match) {
  return {
    success: true,
    data: match,
    metadata: {
      cached: true,
      duration_ms: executionTime,
      mcp_calls: 0,
      resolution: {
        input: params.state,
        method: "exact_name_match"
      }
    }
  };
}

// Step 4: Try type match
match = states.find(s => s.type.toLowerCase() === input);
if (match) {
  return successResponse(match, "type_match");
}

// Step 5: Try fallback mapping for common aliases
const fallbackMap = {
  'backlog': 'backlog',
  'todo': 'unstarted',
  'planning': 'unstarted',
  'ready': 'unstarted',
  'in progress': 'started',
  'in review': 'started',
  'testing': 'started',
  'done': 'completed',
  'finished': 'completed',
  'canceled': 'canceled',
  'blocked': 'canceled'
};

const mappedType = fallbackMap[input];
if (mappedType) {
  match = states.find(s => s.type.toLowerCase() === mappedType);
  if (match) {
    return successResponse(match, "alias_match");
  }
}

// Step 6: Try partial name match (contains)
match = states.find(s => s.name.toLowerCase().includes(input));
if (match) {
  return successResponse(match, "partial_match");
}

// Step 7: No match found - return helpful error
const availableStates = states.map(s => ({
  name: s.name,
  type: s.type
}));

return {
  success: false,
  error: {
    code: "STATUS_NOT_FOUND",
    message: `Status '${params.state}' not found for team '${params.team}'`,
    details: {
      input: params.state,
      team: params.team,
      available_statuses: availableStates
    },
    suggestions: [
      "Use exact status name from the list above",
      "Use status type: 'started', 'completed', 'unstarted', etc.",
      "Use common alias: 'todo', 'in progress', 'done'",
      "Run /ccpm:utils:statuses to see all available statuses"
    ]
  },
  metadata: {
    duration_ms: executionTime,
    mcp_calls: 1
  }
};
```

---

### 3.2 list_statuses

List all workflow states for a team (populates cache).

**Input YAML**:
```yaml
operation: list_statuses
params:
  team: "Engineering"               # Required
  refresh_cache: false              # Optional
context:
  command: "utils:statuses"
```

**Output YAML**:
```yaml
success: true
data:
  statuses:
    - id: "state-1"
      name: "Backlog"
      type: "backlog"
      color: "#95a2b3"
      position: 0
    - id: "state-2"
      name: "Todo"
      type: "unstarted"
      color: "#e2e2e2"
      position: 1
    # ... more states
  total: 6
metadata:
  cached: true
  duration_ms: 25
  mcp_calls: 0
```

---

### 3.3 validate_state

Validate a state exists and return detailed info (alias for get_valid_state_id).

---

## 4. Team/Project Operations

### 4.1 get_team

Retrieve team details by name, key, or ID.

**Input YAML**:
```yaml
operation: get_team
params:
  team: "Engineering"               # Required (name, key, or ID)
context:
  command: "planning:create"
```

**Output YAML**:
```yaml
success: true
data:
  id: "team-456"
  name: "Engineering"
  key: "ENG"
  description: "Engineering team"
metadata:
  cached: true
  duration_ms: 15
  mcp_calls: 0
```

**Implementation with Caching**:
```javascript
// Check if input is UUID (team ID)
if (isUUID(params.team)) {
  // Check cache by ID
  let team = cache.get(`team:id:${params.team}`);
  if (team) {
    return successResponse(team, cached: true);
  }

  // Fetch by ID
  team = await mcp__linear__get_team({ id: params.team });
  cacheTeam(team);
  return successResponse(team, cached: false);
}

// Try name/key lookup from cache
const byName = cache.get(`team:name:${params.team.toLowerCase()}`);
if (byName) {
  return successResponse(byName, cached: true);
}

const byKey = cache.get(`team:key:${params.team.toUpperCase()}`);
if (byKey) {
  return successResponse(byKey, cached: true);
}

// Fetch all teams and populate cache
const teams = await mcp__linear__list_teams();
for (const team of teams) {
  cacheTeam(team);
}

// Try again after cache population
const match = teams.find(
  t => t.name.toLowerCase() === params.team.toLowerCase() ||
       t.key.toUpperCase() === params.team.toUpperCase()
);

if (match) {
  return successResponse(match, cached: false);
}

// Not found error
return {
  success: false,
  error: {
    code: "TEAM_NOT_FOUND",
    message: `Team '${params.team}' not found`,
    details: {
      input: params.team,
      available_teams: teams.map(t => ({
        name: t.name,
        key: t.key
      }))
    },
    suggestions: [
      "Use exact team name or key",
      "Run /ccpm:utils:teams to list all teams"
    ]
  }
};

function cacheTeam(team) {
  cache.set(`team:id:${team.id}`, team);
  cache.set(`team:name:${team.name.toLowerCase()}`, team);
  cache.set(`team:key:${team.key.toUpperCase()}`, team);
}
```

---

### 4.2 get_project

Retrieve project details by name or ID.

**Input YAML**:
```yaml
operation: get_project
params:
  project: "Auth System"            # Required (name or ID)
  team: "Engineering"               # Optional (for scoped lookup)
context:
  command: "planning:create"
```

**Output YAML**:
```yaml
success: true
data:
  id: "proj-789"
  name: "Auth System"
  description: "Authentication system..."
  state: "planned"
  team:
    id: "team-456"
    name: "Engineering"
metadata:
  cached: true
  duration_ms: 20
  mcp_calls: 0
```

**Implementation**: Similar caching pattern as get_team.

---

### 4.3 list_projects

List projects with filtering (populates cache).

**Input YAML**:
```yaml
operation: list_projects
params:
  team: "Engineering"               # Optional
  state: "planned"                  # Optional
  limit: 50                         # Optional
context:
  command: "utils:projects"
```

**Output**: List of projects with metadata.

---

## 5. Comment Operations

### 5.1 create_comment

Add a comment to an issue.

**Input YAML**:
```yaml
operation: create_comment
params:
  issue_id: "PSN-123"               # Required
  body: "## Update\n..."            # Required (Markdown)
  parent_id: "comment-456"          # Optional (for replies)
context:
  command: "implementation:sync"
```

**Output YAML**:
```yaml
success: true
data:
  id: "comment-789"
  body: "## Update\n..."
  created_at: "2025-01-16T15:30:00Z"
  user:
    id: "user-123"
    name: "John Doe"
metadata:
  cached: false
  duration_ms: 400
  mcp_calls: 1
```

---

### 5.2 list_comments

Retrieve comments for an issue.

**Input YAML**:
```yaml
operation: list_comments
params:
  issue_id: "PSN-123"               # Required
context:
  command: "planning:plan"
```

**Output**: List of comments with metadata.

---

## 6. Document Operations

### 6.1 get_document

Retrieve a Linear document by ID or slug.

**Input YAML**:
```yaml
operation: get_document
params:
  document_id: "doc-abc-123"        # Required (ID or slug)
context:
  command: "spec:write"
```

**Output**: Document object with content.

---

### 6.2 list_documents

List documents with filtering.

**Input YAML**:
```yaml
operation: list_documents
params:
  project_id: "proj-789"            # Optional
  query: "authentication"           # Optional
  limit: 50                         # Optional
context:
  command: "spec:list"
```

**Output**: List of documents.

---

### 6.3 link_document

Link a document to an issue (for spec management).

**Input YAML**:
```yaml
operation: link_document
params:
  issue_id: "PSN-123"               # Required
  document_id: "doc-abc-123"        # Required
context:
  command: "spec:create"
```

**Output**: Confirmation of link creation.

---

## Caching Implementation

### Session-Level Cache Structure

```javascript
// Conceptual cache structure (in-memory for session)
const sessionCache = {
  teams: {
    byId: new Map(),      // teamId → team object
    byName: new Map(),    // name.toLowerCase() → teamId
    byKey: new Map()      // key.toUpperCase() → teamId
  },
  projects: {
    byId: new Map(),      // projectId → project object
    byName: new Map()     // `${teamId}:${name.toLowerCase()}` → projectId
  },
  labels: {
    byId: new Map(),      // labelId → label object
    byName: new Map()     // `${teamId}:${name.toLowerCase()}` → labelId
  },
  statuses: {
    byId: new Map(),      // statusId → status object
    byName: new Map(),    // `${teamId}:${name.toLowerCase()}` → statusId
    byType: new Map(),    // `${teamId}:${type}` → statusId
    byTeam: new Map()     // teamId → [status objects]
  },
  users: {
    byId: new Map(),      // userId → user object
    byEmail: new Map(),   // email → userId
    byName: new Map()     // name → userId
  }
};
```

### Cache Population Strategy

**Lazy Loading**: Cache populated on first request for each entity type.

**Batch Loading**: When listing operations occur (list_labels, list_statuses), entire result set populates cache.

**Cache Invalidation**: No explicit invalidation - session-scoped cache cleared when command execution completes.

**Manual Refresh**: `refresh_cache: true` parameter forces cache bypass and refresh.

---

## Error Handling

### Error Code Taxonomy

#### Entity Not Found Errors (1000-1099)
- `TEAM_NOT_FOUND` (1001)
- `PROJECT_NOT_FOUND` (1002)
- `LABEL_NOT_FOUND` (1003)
- `STATUS_NOT_FOUND` (1004)
- `ISSUE_NOT_FOUND` (1005)
- `USER_NOT_FOUND` (1006)
- `DOCUMENT_NOT_FOUND` (1007)

#### Validation Errors (1100-1199)
- `INVALID_TEAM_IDENTIFIER` (1101)
- `INVALID_STATE_NAME` (1102)
- `INVALID_LABEL_NAME` (1103)
- `MISSING_REQUIRED_PARAM` (1106)

#### Creation Errors (1200-1299)
- `LABEL_CREATION_FAILED` (1201)
- `ISSUE_CREATION_FAILED` (1202)
- `COMMENT_CREATION_FAILED` (1203)

#### API Errors (1400-1499)
- `LINEAR_API_ERROR` (1401)
- `LINEAR_API_RATE_LIMIT` (1402)
- `LINEAR_API_TIMEOUT` (1403)

### Error Response Format

```yaml
success: false
error:
  code: STATUS_NOT_FOUND
  message: "Status 'Invalid State' not found for team 'Engineering'"
  details:
    input: "Invalid State"
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
    - "Use common alias: 'todo' maps to 'unstarted'"
    - "Run /ccpm:utils:statuses to see all available statuses"
metadata:
  duration_ms: 180
  mcp_calls: 1
```

---

## Integration Examples

### Example 1: Command Creating Issue with Labels

**Before (Direct MCP - 2500 tokens)**:
```markdown
## Step 1: Resolve Team ID
Use Linear MCP to get team by name: ${TEAM_NAME}
Store team ID.

## Step 2: Ensure Labels Exist
For each label in [planning, backend, high-priority]:
  - Check if label exists in team
  - If not, create label with default color
  - Store label ID

## Step 3: Resolve State ID
List all workflow states for team.
Find state matching "In Progress" (fuzzy match).
Store state ID.

## Step 4: Create Issue
Use Linear MCP to create issue with resolved IDs.
```

**After (Subagent - 400 tokens)**:
```markdown
## Step 1: Create Issue with Labels

Task(linear-operations): `
operation: create_issue
params:
  team: ${TEAM_NAME}
  title: "${ISSUE_TITLE}"
  description: |
    ## Overview
    ${ISSUE_DESCRIPTION}
  state: "In Progress"
  labels:
    - "planning"
    - "backend"
    - "high-priority"
  assignee: "me"
context:
  command: "planning:create"
  purpose: "Creating planned task with workflow labels"
`
```

**Token Reduction**: 84% (2500 → 400 tokens)

---

### Example 2: Batch Label Verification

**Before (1200 tokens)**:
```markdown
## Ensure CCPM Workflow Labels Exist

Use Linear MCP:
For each label in [planning, implementation, verification, pr-review, done]:
  1. Search for label in team
  2. If exists, skip
  3. If not exists, create with color
```

**After (350 tokens)**:
```markdown
## Ensure CCPM Workflow Labels Exist

Task(linear-operations): `
operation: ensure_labels_exist
params:
  team: ${TEAM_NAME}
  labels:
    - name: "planning"
      color: "#f7c8c1"
    - name: "implementation"
      color: "#26b5ce"
    - name: "verification"
      color: "#f2c94c"
context:
  command: "utils:ensure-labels"
`
```

**Token Reduction**: 71% (1200 → 350 tokens)

---

## Performance Targets

| Operation Type | Cached | Uncached | Cache Hit Rate (Expected) |
|---------------|--------|----------|---------------------------|
| Team lookup | <50ms | 300-500ms | 95% |
| Project lookup | <50ms | 300-500ms | 90% |
| Label lookup | <50ms | 300-500ms | 85% |
| Status lookup | <50ms | 300-500ms | 95% |
| User lookup | <50ms | 300-500ms | 80% |
| Issue get | N/A | 400-600ms | N/A (not cached) |
| Issue create | N/A | 600-800ms | N/A (not cached) |

---

## Migration Guide

### Phased Approach

**Phase 1**: Migrate high-traffic commands
- `planning:plan` (5000+ tokens → 2000 tokens)
- `planning:create` (4000+ tokens → 1600 tokens)
- `implementation:start` (3500+ tokens → 1400 tokens)

**Phase 2**: Migrate helper functions from `_shared-linear-helpers.md`

**Phase 3**: Update remaining commands

### Migration Pattern

**Before**:
```markdown
Use Linear MCP to:
1. Fetch team details
2. List labels
3. Create missing labels
4. Create issue
```

**After**:
```markdown
Task(linear-operations): `
operation: create_issue
params:
  team: ${TEAM_NAME}
  title: "${TITLE}"
  labels: ["planning", "backend"]
`
```

---

## Usage in Commands

Commands invoke this agent using the Task tool with YAML-formatted requests:

```markdown
# In a CCPM command

Task(linear-operations): `
operation: create_issue
params:
  team: Engineering
  title: "Implement feature X"
  state: "In Progress"
  labels: ["planning", "backend"]
  assignee: "me"
context:
  command: "planning:create"
  purpose: "Creating new planned task"
`

# Agent returns structured YAML response
# Parse response and use data
```

---

## Best Practices

1. **Always use structured YAML input** - Clear, parseable contracts
2. **Leverage caching** - Second lookups are 90% faster
3. **Batch operations** - Use `ensure_labels_exist` over individual calls
4. **Handle errors gracefully** - Check success field, display suggestions
5. **Log operations** - Use context field for tracing
6. **Optimize for common paths** - Cache hit rate targets: 85-95%
7. **Monitor performance** - Track metrics in metadata field

---

## Telemetry & Monitoring

### Session-Level Metrics

Track performance and cache effectiveness throughout the session:

```javascript
// Telemetry tracking structure
const sessionTelemetry = {
  startTime: Date.now(),
  operations: {
    total: 0,
    byType: {
      issue_operations: 0,
      label_operations: 0,
      state_operations: 0,
      team_operations: 0,
      comment_operations: 0,
      document_operations: 0
    }
  },
  cache: {
    hits: 0,
    misses: 0,
    hitRate: 0.0,
    byOperationType: {
      team: { hits: 0, misses: 0, hitRate: 0.0 },
      project: { hits: 0, misses: 0, hitRate: 0.0 },
      label: { hits: 0, misses: 0, hitRate: 0.0 },
      status: { hits: 0, misses: 0, hitRate: 0.0 },
      user: { hits: 0, misses: 0, hitRate: 0.0 }
    }
  },
  performance: {
    totalDurationMs: 0,
    averageDurationMs: 0,
    byOperationType: {
      get_issue: { count: 0, totalMs: 0, avgMs: 0 },
      create_issue: { count: 0, totalMs: 0, avgMs: 0 },
      update_issue: { count: 0, totalMs: 0, avgMs: 0 },
      get_or_create_label: { count: 0, totalMs: 0, avgMs: 0 },
      get_valid_state_id: { count: 0, totalMs: 0, avgMs: 0 },
      get_team: { count: 0, totalMs: 0, avgMs: 0 }
      // ... other operations
    }
  },
  mcp: {
    totalCalls: 0,
    avgCallsPerOperation: 0.0,
    byOperationType: {
      get_issue: { count: 0, totalCalls: 0, avgCalls: 0.0 },
      create_issue: { count: 0, totalCalls: 0, avgCalls: 0.0 }
      // ... other operations
    }
  },
  tokens: {
    totalEstimated: 0,
    saved: 0,
    byOperationType: {
      // Estimates based on with/without caching
      get_or_create_label: { withCache: 150, withoutCache: 850, savings: 700 }
      // ... other operations
    }
  }
};
```

### Tracking Implementation

**On each operation:**

```javascript
function recordOperation(operation, result) {
  const duration = result.metadata.duration_ms;
  const mcpCalls = result.metadata.mcp_calls;
  const cached = result.metadata.cached || false;

  // Increment operation count
  sessionTelemetry.operations.total++;
  const category = getOperationCategory(operation);
  sessionTelemetry.operations.byType[category]++;

  // Track cache performance
  if (isCacheable(operation)) {
    if (cached) {
      sessionTelemetry.cache.hits++;
      const cacheType = getCacheType(operation);
      sessionTelemetry.cache.byOperationType[cacheType].hits++;
    } else {
      sessionTelemetry.cache.misses++;
      const cacheType = getCacheType(operation);
      sessionTelemetry.cache.byOperationType[cacheType].misses++;
    }

    // Calculate hit rate
    const total = sessionTelemetry.cache.hits + sessionTelemetry.cache.misses;
    sessionTelemetry.cache.hitRate = (sessionTelemetry.cache.hits / total * 100).toFixed(2);
  }

  // Track performance
  sessionTelemetry.performance.totalDurationMs += duration;
  if (!sessionTelemetry.performance.byOperationType[operation]) {
    sessionTelemetry.performance.byOperationType[operation] = {
      count: 0,
      totalMs: 0,
      avgMs: 0
    };
  }
  const opStats = sessionTelemetry.performance.byOperationType[operation];
  opStats.count++;
  opStats.totalMs += duration;
  opStats.avgMs = Math.round(opStats.totalMs / opStats.count);

  // Track MCP calls
  sessionTelemetry.mcp.totalCalls += mcpCalls;
  if (!sessionTelemetry.mcp.byOperationType[operation]) {
    sessionTelemetry.mcp.byOperationType[operation] = {
      count: 0,
      totalCalls: 0,
      avgCalls: 0.0
    };
  }
  const mcpStats = sessionTelemetry.mcp.byOperationType[operation];
  mcpStats.count++;
  mcpStats.totalCalls += mcpCalls;
  mcpStats.avgCalls = (mcpStats.totalCalls / mcpStats.count).toFixed(2);

  // Update overall averages
  sessionTelemetry.performance.averageDurationMs = Math.round(
    sessionTelemetry.performance.totalDurationMs / sessionTelemetry.operations.total
  );
  sessionTelemetry.mcp.avgCallsPerOperation = (
    sessionTelemetry.mcp.totalCalls / sessionTelemetry.operations.total
  ).toFixed(2);
}
```

### Telemetry Output

Include telemetry summary in metadata for high-volume commands:

```yaml
# Example: After planning:plan command with 10+ operations
metadata:
  session_telemetry:
    operations: 12
    cache_hit_rate: 91.67%
    cache_breakdown:
      team: 100% (3/3 hits)
      label: 87.5% (7/8 hits)
      status: 100% (2/2 hits)
    performance:
      avg_duration: 125ms
      total_duration: 1.5s
    mcp_efficiency:
      total_calls: 5
      avg_per_operation: 0.42
      token_savings: ~18,000 (estimated)
```

### Example Telemetry Report

At end of session or on-demand via `/ccpm:utils:telemetry`:

```markdown
## Linear Operations Telemetry Report

**Session Duration:** 8m 42s
**Commands Executed:** 4 (planning:plan, implementation:start, implementation:sync, verification:verify)

### Operations Summary
- **Total Operations:** 47
- **Issue Operations:** 15 (32%)
- **Label Operations:** 18 (38%)
- **State Operations:** 8 (17%)
- **Team/Project Operations:** 6 (13%)

### Cache Performance
- **Overall Hit Rate:** 89.47% (34/38 cacheable operations)
- **Cache Breakdown:**
  - Team lookups: 100% (6/6 hits) - Avg: 22ms
  - Label lookups: 88.9% (16/18 hits) - Avg: 31ms
  - Status lookups: 87.5% (7/8 hits) - Avg: 28ms
  - Project lookups: 100% (5/5 hits) - Avg: 25ms

### Performance Metrics
- **Total Time:** 6.8s
- **Average Operation:** 145ms
- **Fastest Operation:** get_team (cached) - 18ms
- **Slowest Operation:** create_issue (with label creation) - 680ms

### MCP Efficiency
- **Total MCP Calls:** 23
- **Average per Operation:** 0.49 calls
- **Savings:** ~42 calls avoided via caching (65% reduction)

### Token Optimization
- **Estimated Tokens Used:** ~8,200
- **Without Caching:** ~22,500 (estimated)
- **Tokens Saved:** ~14,300 (64% reduction)

### Recommendations
- ✅ Cache hit rate excellent (89.47% vs 85% target)
- ✅ Performance within targets (<50ms cached, <500ms uncached)
- ⚠️  Label operations have 11% miss rate - consider pre-warming cache
```

### Telemetry Benefits

1. **Performance Monitoring**: Track actual vs target performance
2. **Cache Optimization**: Identify cache miss patterns
3. **Token Savings Validation**: Prove 50-60% reduction claims
4. **Debugging**: Diagnose slow operations or cache issues
5. **Reporting**: Show stakeholders measurable improvements

---

## Maintenance Notes

- Cache invalidation is session-scoped (no manual invalidation needed)
- Add new operations following existing patterns
- Update error codes in centralized taxonomy
- Keep performance targets documented
- Log cache hit rates for optimization
- Test caching behavior across operations
- Validate all operations against Linear MCP schema changes
- **Monitor telemetry**: Review cache hit rates and performance metrics regularly
- **Track token savings**: Validate optimization goals are being met
- **Tune cache strategy**: Adjust based on real-world usage patterns

---

## Related Documentation

- [Architecture Document](../docs/architecture/linear-subagent-architecture.md)
- [Shared Linear Helpers](../commands/_shared-linear-helpers.md) (being deprecated)
- [CCPM Commands Reference](../commands/README.md)
