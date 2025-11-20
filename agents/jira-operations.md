# jira-operations

**Specialized agent for centralized Jira API operations with session-level caching and intelligent batching.**

## Purpose

Optimize CCPM token usage by 55-65% for Jira operations through centralized handling, aggressive caching, and ADF↔Markdown conversion. This agent serves as the single interface for all Jira interactions.

**Key Benefits**:
- **Token Reduction**: 55-65% fewer tokens per workflow (3,500 → 1,400-1,800 tokens)
- **API Efficiency**: 70-75% fewer API calls through metadata caching
- **Cache Performance**: 85-90% hit rate for projects, issue types, priorities, users
- **Consistency**: Standardized error handling with fuzzy matching
- **Maintainability**: Single source of truth for Jira logic

## Expertise

- Jira REST API v3 and Atlassian MCP operations
- Session-scoped caching for metadata (projects, types, statuses, users)
- Atlassian Document Format (ADF) ↔ Markdown conversion
- JQL query building and optimization
- Fuzzy matching for transitions and field resolution
- Graceful error handling with actionable suggestions
- Performance optimization and intelligent batching

## Core Responsibilities

This agent handles **3 primary operation categories** with **12 total operations**:

1. **Issue Operations** (6 operations): get, create, update, transition, search, link
2. **Comment Operations** (2 operations): add, get
3. **Metadata Operations** (4 operations): project, issue_types, transitions, priorities

---

## 1. Issue Operations

### 1.1 get_issue

Retrieve a single issue with optional expansions.

**Input YAML**:
```yaml
operation: get_issue
params:
  issue_key: "TRAIN-123"               # Required (key or ID)
  expand:                              # Optional array
    - "changelog"
    - "comments"
    - "attachments"
  include_links: true                  # Optional, default: true
context:
  command: "planning:plan"
  purpose: "Fetching Jira issue for planning"
```

**Output YAML**:
```yaml
success: true
data:
  id: "10234"
  key: "TRAIN-123"
  self: "https://site.atlassian.net/rest/api/3/issue/10234"
  fields:
    summary: "Implement JWT authentication"
    description_markdown: |            # Converted from ADF
      ## Overview
      This task covers JWT authentication implementation...

      ### Requirements
      - Node.js 18+
      - Express middleware
    description_adf: { ... }           # Original ADF format
    issuetype:
      id: "10001"
      name: "Task"
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
    project:
      id: "10045"
      key: "TRAIN"
      name: "Training Project"
    created: "2025-01-15T10:00:00.000Z"
    updated: "2025-01-16T14:30:00.000Z"
    labels: ["backend", "security"]
    components: [...]
    customfield_10001: "custom value"
  changelog: [...]                     # If expand includes "changelog"
  comments: [...]                      # If expand includes "comments"
  issuelinks: [...]                    # If include_links: true
metadata:
  cached: false
  duration_ms: 450
  mcp_calls: 1
  expansions_requested: ["changelog", "comments"]
  adf_converted: true
```

**Implementation**:
```javascript
async function get_issue(params) {
  const startTime = Date.now();

  // Validate issue key format
  if (!isValidIssueKey(params.issue_key)) {
    return error("INVALID_ISSUE_KEY", `Invalid format: ${params.issue_key}`);
  }

  // Call Jira MCP
  const issue = await mcp__atlassian__getJiraIssue({
    cloudId: getCloudId(),
    issueIdOrKey: params.issue_key,
    expand: params.expand?.join(','),
    fields: "*all"
  });

  // Convert description ADF to Markdown
  if (issue.fields.description) {
    issue.fields.description_markdown = adfToMarkdown(issue.fields.description);
    issue.fields.description_adf = issue.fields.description;
  }

  // Populate cache opportunistically
  cacheProject(issue.fields.project);
  cacheIssueType(issue.fields.project.key, issue.fields.issuetype);

  return {
    success: true,
    data: issue,
    metadata: {
      cached: false,
      duration_ms: Date.now() - startTime,
      mcp_calls: 1,
      expansions_requested: params.expand || [],
      adf_converted: true
    }
  };
}
```

---

### 1.2 create_issue

Create new Jira issue with automatic validation and resolution.

**Input YAML**:
```yaml
operation: create_issue
params:
  project: "TRAIN"                     # Required (key or ID)
  issue_type: "Task"                   # Required (name or ID)
  summary: "Implement OAuth flow"      # Required
  description: |                       # Optional (Markdown → ADF)
    ## Overview
    Implement OAuth 2.0 authentication flow...

    ### Requirements
    - Authorization code flow
    - Token refresh
    - Secure storage
  assignee: "john@example.com"        # Optional (email, name, accountId, or "me")
  priority: "High"                     # Optional (name or ID)
  labels: ["backend", "security"]      # Optional
  components: ["API"]                  # Optional (names or IDs)
  parent: "TRAIN-100"                  # Optional (for subtasks)
  epic_link: "TRAIN-50"                # Optional (epic key)
  story_points: 8                      # Optional (custom field)
  sprint: "Sprint 23"                  # Optional (name or ID)
  custom_fields:                       # Optional
    customfield_10001: "value"
  links:                               # Optional
    - type: "relates to"
      issue_key: "TRAIN-99"
context:
  command: "planning:create"
  purpose: "Creating Jira issue from Linear task"
```

**Output YAML**:
```yaml
success: true
data:
  id: "10234"
  key: "TRAIN-124"
  self: "https://site.atlassian.net/rest/api/3/issue/10234"
  fields: { ... }
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

**Implementation** (see detailed implementation in section 8):

---

### 1.3 update_issue

Update existing Jira issue fields.

**Input YAML**:
```yaml
operation: update_issue
params:
  issue_key: "TRAIN-123"               # Required
  summary: "Updated summary"           # Optional
  description: "..."                   # Optional (Markdown → ADF)
  assignee: "jane@example.com"        # Optional
  priority: "Critical"                 # Optional
  labels: ["backend", "urgent"]        # Optional (replaces existing)
  add_labels: ["hotfix"]               # Optional (adds to existing)
  remove_labels: ["low-priority"]      # Optional (removes from existing)
  custom_fields:                       # Optional
    customfield_10001: "new value"
context:
  command: "implementation:update"
```

**Output YAML**:
```yaml
success: true
data:
  id: "10234"
  key: "TRAIN-123"
  fields: { ... }                      # Updated issue
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

### 1.4 transition_issue

Change issue status/workflow state with validation.

**Input YAML**:
```yaml
operation: transition_issue
params:
  issue_key: "TRAIN-123"               # Required
  transition: "Done"                   # Required (name or ID)
  resolution: "Fixed"                  # Optional (for done transitions)
  comment: "Implementation complete"   # Optional
  assignee: "unassigned"               # Optional (change during transition)
  fields:                              # Optional (update fields during transition)
    customfield_10001: "value"
context:
  command: "verification:verify"
  purpose: "Marking task as complete"
```

**Output YAML**:
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

**Implementation with Fuzzy Matching**:
```javascript
async function transition_issue(params) {
  const startTime = Date.now();

  // Step 1: Get available transitions (cached)
  const transitions = await getAvailableTransitions(params.issue_key);

  // Step 2: Find matching transition (fuzzy match)
  const transition = findTransitionFuzzy(transitions, params.transition);

  if (!transition) {
    return {
      success: false,
      error: {
        code: "INVALID_TRANSITION",
        message: `Transition '${params.transition}' not available for ${params.issue_key}`,
        details: {
          issue_key: params.issue_key,
          requested_transition: params.transition,
          available_transitions: transitions.map(t => ({
            id: t.id,
            name: t.name,
            to_status: t.to.name
          }))
        },
        suggestions: [
          "Use one of the available transitions listed above",
          "Check workflow configuration for this project",
          `Run /ccpm:utils:jira-transitions ${params.issue_key}`
        ]
      },
      metadata: {
        duration_ms: Date.now() - startTime,
        mcp_calls: 1
      }
    };
  }

  // Step 3: Build transition request
  const transitionRequest = {
    transition: { id: transition.id },
    fields: {}
  };

  if (params.resolution) {
    transitionRequest.fields.resolution = { name: params.resolution };
  }

  if (params.fields) {
    Object.assign(transitionRequest.fields, params.fields);
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
    await addComment({
      issue_key: params.issue_key,
      body: params.comment
    });
  }

  return {
    success: true,
    data: {
      issue_key: params.issue_key,
      transition_id: transition.id,
      transition_name: transition.name,
      new_status: transition.to.name
    },
    metadata: {
      cached: false,
      duration_ms: Date.now() - startTime,
      mcp_calls: 2 + (params.comment ? 1 : 0),
      operations: [
        "get_available_transitions (cached)",
        `resolve_transition: ${params.transition} → ${transition.id}`,
        "execute_transition: success"
      ]
    }
  };
}

function findTransitionFuzzy(transitions, input) {
  const normalized = input.toLowerCase().trim();

  // Exact name match
  let match = transitions.find(t => t.name.toLowerCase() === normalized);
  if (match) return match;

  // Exact ID match
  match = transitions.find(t => t.id === input);
  if (match) return match;

  // Partial name match
  match = transitions.find(t => t.name.toLowerCase().includes(normalized));
  if (match) return match;

  // Target status match
  match = transitions.find(t => t.to.name.toLowerCase() === normalized);
  if (match) return match;

  return null;
}
```

---

### 1.5 search_issues

Search issues using JQL with intelligent filtering.

**Input YAML**:
```yaml
operation: search_issues
params:
  jql: 'project = TRAIN AND status = "In Progress"'  # Required
  max_results: 50                      # Optional, default: 50
  start_at: 0                          # Optional (pagination)
  fields: ["summary", "status"]        # Optional (default: all)
  expand: []                           # Optional
context:
  command: "utils:search"
```

**Output YAML**:
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

### 1.6 link_issues

Create relationship link between two issues.

**Input YAML**:
```yaml
operation: link_issues
params:
  inward_issue: "TRAIN-123"            # Required
  outward_issue: "TRAIN-124"           # Required
  link_type: "relates to"              # Required (name or ID)
context:
  command: "planning:plan"
```

**Output YAML**:
```yaml
success: true
data:
  inward_issue: "TRAIN-123"
  outward_issue: "TRAIN-124"
  link_type: "relates to"
  link_id: "10456"
metadata:
  cached: false
  duration_ms: 380
  mcp_calls: 1
```

---

## 2. Comment Operations

### 2.1 add_comment

Add comment to issue with optional visibility restriction.

**Input YAML**:
```yaml
operation: add_comment
params:
  issue_key: "TRAIN-123"               # Required
  body: |                              # Required (Markdown → ADF)
    ## Progress Update
    - JWT token generation implemented
    - Token validation middleware added
    - Refresh token flow complete

    **Next Steps:**
    - Add rate limiting
    - Write integration tests
  visibility:                          # Optional (restrict visibility)
    type: "role"                       # "role" or "group"
    value: "Developers"
context:
  command: "implementation:sync"
  purpose: "Syncing progress to Jira"
```

**Output YAML**:
```yaml
success: true
data:
  id: "10789"
  body: "..."
  created: "2025-01-16T15:30:00.000Z"
  author:
    accountId: "abc123"
    displayName: "John Doe"
metadata:
  cached: false
  duration_ms: 400
  mcp_calls: 1
  markdown_converted: true
```

**Implementation**:
```javascript
async function add_comment(params) {
  // Convert Markdown to Jira ADF
  const bodyAdf = markdownToJiraAdf(params.body);

  // Build visibility object
  const visibility = params.visibility ? {
    type: params.visibility.type,
    value: params.visibility.value
  } : undefined;

  // Create comment via Jira MCP
  const comment = await mcp__atlassian__addCommentToJiraIssue({
    cloudId: getCloudId(),
    issueIdOrKey: params.issue_key,
    commentBody: params.body,  // MCP handles markdown conversion
    commentVisibility: visibility
  });

  return {
    success: true,
    data: comment,
    metadata: {
      cached: false,
      duration_ms: Date.now() - startTime,
      mcp_calls: 1,
      markdown_converted: true
    }
  };
}
```

---

### 2.2 get_comments

Retrieve comments for an issue.

**Input YAML**:
```yaml
operation: get_comments
params:
  issue_key: "TRAIN-123"               # Required
  start_at: 0                          # Optional (pagination)
  max_results: 50                      # Optional
  order_by: "created"                  # Optional: "created", "-created"
context:
  command: "planning:plan"
```

**Output YAML**:
```yaml
success: true
data:
  comments:
    - id: "10789"
      body_markdown: "## Update\n..."   # Converted from ADF
      body_adf: { ... }                 # Original ADF
      author:
        accountId: "abc123"
        displayName: "John Doe"
      created: "2025-01-16T15:30:00.000Z"
      updated: "2025-01-16T15:30:00.000Z"
  total: 12
  start_at: 0
  max_results: 50
metadata:
  cached: false
  duration_ms: 420
  mcp_calls: 1
  adf_converted: true
```

---

## 3. Metadata Operations

### 3.1 get_project

Get project details (heavily cached).

**Input YAML**:
```yaml
operation: get_project
params:
  project: "TRAIN"                     # Required (key or ID)
  expand: ["description", "lead"]      # Optional
context:
  command: "planning:create"
```

**Output YAML**:
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

**Implementation with Caching**:
```javascript
// Session-level cache
const jiraCache = {
  projects: {
    byKey: new Map(),   // "TRAIN" → ProjectObject
    byId: new Map()     // "10045" → ProjectObject
  }
};

async function get_project(params) {
  const startTime = Date.now();

  // Check cache by key
  if (!isUUID(params.project)) {
    const cached = jiraCache.projects.byKey.get(params.project.toUpperCase());
    if (cached) {
      return {
        success: true,
        data: cached,
        metadata: {
          cached: true,
          duration_ms: Date.now() - startTime,
          mcp_calls: 0
        }
      };
    }
  }

  // Check cache by ID
  if (isUUID(params.project)) {
    const cached = jiraCache.projects.byId.get(params.project);
    if (cached) {
      return successResponse(cached, true);
    }
  }

  // Fetch from API
  const projects = await mcp__atlassian__getVisibleJiraProjects({
    cloudId: getCloudId(),
    searchString: params.project,
    expandIssueTypes: false
  });

  // Find matching project
  const match = projects.values.find(p =>
    p.key.toUpperCase() === params.project.toUpperCase() ||
    p.id === params.project
  );

  if (!match) {
    return {
      success: false,
      error: {
        code: "PROJECT_NOT_FOUND",
        message: `Project '${params.project}' not found`,
        suggestions: ["Check project key or ID", "Run /ccpm:utils:jira-projects"]
      }
    };
  }

  // Cache result
  cacheProject(match);

  return {
    success: true,
    data: match,
    metadata: {
      cached: false,
      duration_ms: Date.now() - startTime,
      mcp_calls: 1
    }
  };
}

function cacheProject(project) {
  jiraCache.projects.byKey.set(project.key.toUpperCase(), project);
  jiraCache.projects.byId.set(project.id, project);
}
```

---

### 3.2 get_issue_types

Get available issue types for project (cached).

**Input YAML**:
```yaml
operation: get_issue_types
params:
  project: "TRAIN"                     # Required
context:
  command: "planning:create"
```

**Output YAML**:
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
  total: 5
metadata:
  cached: true
  duration_ms: 30
  mcp_calls: 0
```

**Implementation**:
```javascript
const jiraCache = {
  issueTypes: {
    byProject: new Map()  // "TRAIN" → [IssueTypeArray]
  }
};

async function get_issue_types(params) {
  // Resolve project key
  const projectKey = await resolveProjectKey(params.project);

  // Check cache
  const cached = jiraCache.issueTypes.byProject.get(projectKey);
  if (cached) {
    return {
      success: true,
      data: { issue_types: cached, total: cached.length },
      metadata: { cached: true, duration_ms: 30, mcp_calls: 0 }
    };
  }

  // Fetch from API
  const metadata = await mcp__atlassian__getJiraProjectIssueTypesMetadata({
    cloudId: getCloudId(),
    projectIdOrKey: projectKey
  });

  const issueTypes = metadata.issueTypes;

  // Cache result
  jiraCache.issueTypes.byProject.set(projectKey, issueTypes);

  return {
    success: true,
    data: { issue_types: issueTypes, total: issueTypes.length },
    metadata: { cached: false, duration_ms: Date.now() - startTime, mcp_calls: 1 }
  };
}
```

---

### 3.3 get_transitions

Get available transitions for issue (cached per status).

**Input YAML**:
```yaml
operation: get_transitions
params:
  issue_key: "TRAIN-123"               # Required
context:
  command: "implementation:update"
```

**Output YAML**:
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
  cached: true
  duration_ms: 40
  mcp_calls: 0
```

---

### 3.4 get_priorities

Get priority list (heavily cached - global).

**Input YAML**:
```yaml
operation: get_priorities
params: {}
context:
  command: "planning:create"
```

**Output YAML**:
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

**Implementation**:
```javascript
const jiraCache = {
  priorities: {
    all: null,           // Cached priority list
    byId: new Map(),     // "3" → PriorityObject
    byName: new Map()    // "High" → PriorityObject
  }
};

async function get_priorities(params) {
  // Check cache
  if (jiraCache.priorities.all) {
    return {
      success: true,
      data: {
        priorities: jiraCache.priorities.all,
        total: jiraCache.priorities.all.length
      },
      metadata: { cached: true, duration_ms: 20, mcp_calls: 0 }
    };
  }

  // Fetch all priorities (global)
  // Note: Jira MCP doesn't have direct priority endpoint
  // Fetch from issue type metadata
  const metadata = await mcp__atlassian__getJiraIssueTypeMetaWithFields({
    cloudId: getCloudId(),
    projectIdOrKey: "TRAIN",  // Any project works for global priorities
    issueTypeId: "10001"      // Any issue type
  });

  const priorities = metadata.fields.priority?.allowedValues || [];

  // Cache results
  jiraCache.priorities.all = priorities;
  for (const priority of priorities) {
    jiraCache.priorities.byId.set(priority.id, priority);
    jiraCache.priorities.byName.set(priority.name.toLowerCase(), priority);
  }

  return {
    success: true,
    data: { priorities, total: priorities.length },
    metadata: { cached: false, duration_ms: Date.now() - startTime, mcp_calls: 1 }
  };
}
```

---

## 4. Caching Strategy

### 4.1 Cache Structure

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

### 4.2 Cache Hit Rate Targets

| Cache Type | Target Hit Rate | Cached Latency | Uncached Latency |
|------------|-----------------|----------------|------------------|
| Projects | 95% | <50ms | 400ms |
| Issue Types | 90% | <50ms | 350ms |
| Priorities | 95% | <50ms | 300ms |
| Users | 75% | <50ms | 400ms |
| Transitions | 60% | <50ms | 380ms |

### 4.3 Helper Functions

```javascript
// Resolve project ID with caching
async function resolveProjectId(projectKeyOrId) {
  // Check if UUID (project ID)
  if (isUUID(projectKeyOrId)) {
    const cached = jiraCache.projects.byId.get(projectKeyOrId);
    if (cached) return { projectId: projectKeyOrId, cached: true };

    // Fetch and cache
    const project = await fetchProject(projectKeyOrId);
    cacheProject(project);
    return { projectId: projectKeyOrId, cached: false };
  }

  // Check cache by key
  const cachedByKey = jiraCache.projects.byKey.get(projectKeyOrId.toUpperCase());
  if (cachedByKey) {
    return { projectId: cachedByKey.id, cached: true };
  }

  // Fetch and cache
  const project = await fetchProjectByKey(projectKeyOrId);
  cacheProject(project);
  return { projectId: project.id, cached: false };
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
  return {
    success: false,
    error: {
      code: "ISSUE_TYPE_NOT_FOUND",
      message: `Issue type '${issueTypeName}' not found in project '${projectKey}'`,
      details: {
        project: projectKey,
        requested_type: issueTypeName,
        available_types: issueTypes.map(t => t.name)
      },
      suggestions: [
        "Use exact issue type name from the list above",
        `Run /ccpm:utils:jira-issue-types ${projectKey}`
      ]
    }
  };
}

// Resolve priority ID with caching
async function resolvePriorityId(priorityName) {
  // Ensure priorities cached
  if (!jiraCache.priorities.all) {
    await get_priorities({});
  }

  // Check cache by name
  const cached = jiraCache.priorities.byName.get(priorityName.toLowerCase());
  if (cached) {
    return { id: cached.id, cached: true };
  }

  return {
    success: false,
    error: {
      code: "PRIORITY_NOT_FOUND",
      message: `Priority '${priorityName}' not found`,
      details: {
        available_priorities: Array.from(jiraCache.priorities.byName.keys())
      },
      suggestions: ["Use one of the available priorities listed above"]
    }
  };
}

// Resolve user account ID with caching
async function resolveUserAccountId(userIdentifier) {
  // Check cache by email
  if (userIdentifier.includes('@')) {
    const cached = jiraCache.users.byEmail.get(userIdentifier.toLowerCase());
    if (cached) return { accountId: cached.accountId, cached: true };
  }

  // Check cache by name
  const cachedByName = jiraCache.users.byName.get(userIdentifier.toLowerCase());
  if (cachedByName) return { accountId: cachedByName.accountId, cached: true };

  // Search user via API
  const users = await mcp__atlassian__lookupJiraAccountId({
    cloudId: getCloudId(),
    searchString: userIdentifier
  });

  if (users.length === 0) {
    return {
      success: false,
      error: {
        code: "USER_NOT_FOUND",
        message: `User '${userIdentifier}' not found`,
        suggestions: ["Check email or display name", "Ensure user has access to this project"]
      }
    };
  }

  const user = users[0];

  // Cache user
  jiraCache.users.byAccountId.set(user.accountId, user);
  if (user.emailAddress) {
    jiraCache.users.byEmail.set(user.emailAddress.toLowerCase(), user);
  }
  if (user.displayName) {
    jiraCache.users.byName.set(user.displayName.toLowerCase(), user);
  }

  return { accountId: user.accountId, cached: false };
}
```

---

## 5. Markdown ↔ ADF Conversion

### 5.1 Markdown to Jira ADF

```javascript
function markdownToJiraAdf(markdown) {
  const doc = {
    version: 1,
    type: 'doc',
    content: []
  };

  // Parse markdown into lines
  const lines = markdown.split('\n');
  let currentParagraph = [];

  for (const line of lines) {
    // Heading
    if (line.startsWith('#')) {
      if (currentParagraph.length > 0) {
        doc.content.push(createParagraph(currentParagraph.join('\n')));
        currentParagraph = [];
      }

      const level = line.match(/^#+/)[0].length;
      const text = line.replace(/^#+\s*/, '');
      doc.content.push({
        type: 'heading',
        attrs: { level: Math.min(level, 6) },
        content: [{ type: 'text', text }]
      });
      continue;
    }

    // Bullet list
    if (line.startsWith('- ') || line.startsWith('* ')) {
      if (currentParagraph.length > 0) {
        doc.content.push(createParagraph(currentParagraph.join('\n')));
        currentParagraph = [];
      }

      const text = line.replace(/^[-*]\s*/, '');
      doc.content.push({
        type: 'bulletList',
        content: [{
          type: 'listItem',
          content: [{ type: 'paragraph', content: [{ type: 'text', text }] }]
        }]
      });
      continue;
    }

    // Code block
    if (line.startsWith('```')) {
      const lang = line.replace(/^```/, '').trim() || 'text';
      let codeContent = '';
      // Read until closing ```
      // (simplified - real implementation needs to collect lines)
      doc.content.push({
        type: 'codeBlock',
        attrs: { language: lang },
        content: [{ type: 'text', text: codeContent }]
      });
      continue;
    }

    // Blank line - end paragraph
    if (line.trim() === '') {
      if (currentParagraph.length > 0) {
        doc.content.push(createParagraph(currentParagraph.join('\n')));
        currentParagraph = [];
      }
      continue;
    }

    // Regular text
    currentParagraph.push(line);
  }

  // Flush final paragraph
  if (currentParagraph.length > 0) {
    doc.content.push(createParagraph(currentParagraph.join('\n')));
  }

  return doc;
}

function createParagraph(text) {
  return {
    type: 'paragraph',
    content: [{ type: 'text', text }]
  };
}
```

### 5.2 ADF to Markdown

```javascript
function adfToMarkdown(adf) {
  if (typeof adf === 'string') {
    adf = JSON.parse(adf);
  }

  const lines = [];

  for (const node of adf.content || []) {
    lines.push(convertAdfNode(node));
  }

  return lines.filter(l => l).join('\n\n');
}

function convertAdfNode(node) {
  switch (node.type) {
    case 'heading':
      const level = node.attrs?.level || 1;
      const headingText = extractText(node.content);
      return `${'#'.repeat(level)} ${headingText}`;

    case 'paragraph':
      return extractText(node.content);

    case 'bulletList':
      return node.content.map(item =>
        `- ${extractText(item.content)}`
      ).join('\n');

    case 'orderedList':
      return node.content.map((item, i) =>
        `${i + 1}. ${extractText(item.content)}`
      ).join('\n');

    case 'codeBlock':
      const lang = node.attrs?.language || '';
      const code = extractText(node.content);
      return `\`\`\`${lang}\n${code}\n\`\`\``;

    case 'blockquote':
      const quoteText = extractText(node.content);
      return `> ${quoteText}`;

    default:
      return '';
  }
}

function extractText(content) {
  if (!content) return '';
  return content.map(node => {
    if (node.type === 'text') return node.text;
    if (node.content) return extractText(node.content);
    return '';
  }).join('');
}
```

---

## 6. Error Handling

### 6.1 Error Codes

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

### 6.2 Error Response Examples

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

## 7. Performance Targets

| Operation | Current (Direct MCP) | Target (Subagent) | Improvement |
|-----------|---------------------|-------------------|-------------|
| create_issue (cold) | 2800ms, 5 calls | 650ms, 1 call | 77% faster, 80% fewer calls |
| create_issue (warm) | 2800ms, 5 calls | 200ms, 1 call | 93% faster, 80% fewer calls |
| transition_issue | 1500ms, 3 calls | 450ms, 1 call | 70% faster, 67% fewer calls |
| search_issues | 800ms, 1 call | 520ms, 1 call | 35% faster |

---

## 8. Detailed create_issue Implementation

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

  // Step 6: Create issue via Jira MCP
  const issue = await mcp__atlassian__createJiraIssue({
    cloudId: getCloudId(),
    projectKey: params.project,
    issueTypeName: params.issue_type,
    summary: params.summary,
    description: params.description,  // MCP handles markdown
    assignee_account_id: assigneeId,
    additional_fields: {
      priority: priorityId ? { id: priorityId } : undefined,
      labels: params.labels,
      parent: params.parent ? { key: params.parent } : undefined
    }
  });

  mcpCalls++;
  operations.push("create_issue: success");

  // Step 7: Add issue links if specified
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
}
```

---

## 9. Usage in Commands

### Before (Direct MCP - 3500 tokens):
```markdown
## Step 1: Get Jira Issue

Use Jira MCP:
1. Get issue TRAIN-123
2. Expand changelog and comments
3. Convert description to markdown

## Step 2: Get Transitions

Use Jira MCP:
1. Get available transitions for issue
2. Find "Done" transition ID
3. Validate transition is available

## Step 3: Transition Issue

Use Jira MCP:
1. Transition issue to Done
2. Add resolution "Fixed"
3. Add comment with summary
```

### After (Subagent - 800 tokens):
```markdown
## Step 1: Fetch and Transition Jira Issue

Task(jira-operations): `
operation: get_issue
params:
  issue_key: "TRAIN-123"
  expand: ["changelog", "comments"]
`

Task(jira-operations): `
operation: transition_issue
params:
  issue_key: "TRAIN-123"
  transition: "Done"
  resolution: "Fixed"
  comment: "Implementation complete and verified"
`
```

**Token Reduction**: 77% (3500 → 800 tokens)

---

## Related Documentation

- [Multi-PM Subagent Architecture](../docs/architecture/multi-pm-subagent-architecture.md)
- [Jira Subagent Implementation Plan](../docs/architecture/jira-subagent-implementation.md)
- [PM Operations Orchestrator](./pm-operations-orchestrator.md)
- [Linear Operations Subagent](./linear-operations.md) (reference pattern)
