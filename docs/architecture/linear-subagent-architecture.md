# Linear Operations Subagent Architecture

**Issue**: PSN-29 - Implement Linear subagents to optimize token usage
**Author**: Backend Architect Agent
**Date**: 2025-11-20
**Status**: Architecture Design (Ready for Implementation)

---

## Executive Summary

This document specifies the architecture for a specialized Linear operations subagent designed to reduce CCPM token usage by 50-60% through:

1. **Centralized Linear MCP operations** - Single responsibility agent handling all Linear API interactions
2. **Session-level caching** - In-memory cache for teams, projects, labels, and statuses
3. **Structured I/O contracts** - YAML-based input/output for clear, predictable interactions
4. **Intelligent batching** - Optimized API call patterns with minimal round-trips
5. **Graceful error handling** - Actionable error messages with recovery suggestions

**Expected Impact**:
- Token reduction: 50-60% (from 15,000-25,000 to 6,000-10,000 per workflow)
- Performance: <500ms for most operations, <50ms for cached operations
- Maintainability: Single source of truth for Linear operations
- Backward compatibility: Existing direct MCP calls continue to work during migration

---

## 1. Architecture Overview

### 1.1 System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    CCPM Commands Layer                       │
│  (planning:*, implementation:*, verification:*, utils:*)    │
└──────────────────────┬──────────────────────────────────────┘
                       │ Task(linear-ops-agent): {...}
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              Linear Operations Subagent                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          Session-Level In-Memory Cache               │   │
│  │  - Teams (by ID, name)                               │   │
│  │  - Projects (by ID, name)                            │   │
│  │  - Labels (by ID, name, team)                        │   │
│  │  - Statuses (by ID, name, type, team)                │   │
│  │  - Users (by ID, name, email)                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌───────────┬───────────┬───────────┬──────────┐          │
│  │  Issue    │  Label    │  State    │  Team/   │          │
│  │  Ops      │  Mgmt     │  Mgmt     │  Project │          │
│  │           │           │           │  Ops     │          │
│  └─────┬─────┴─────┬─────┴─────┬─────┴────┬─────┘          │
│        │           │           │          │                 │
│        └───────────┴───────────┴──────────┘                 │
│                     │                                        │
└─────────────────────┼────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                  Linear MCP Server                           │
│  (23 tools: get_issue, create_issue, list_labels, etc.)    │
└──────────────────────┬──────────────────────────────────────┘
                       │ GraphQL/REST API
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                    Linear API                                │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Data Flow Patterns

**Pattern 1: Cached Lookup Flow**
```
Command → Subagent → Check Cache → Return (50ms)
```

**Pattern 2: Cache Miss Flow**
```
Command → Subagent → Check Cache → Miss → MCP Call → Update Cache → Return (500ms)
```

**Pattern 3: Batch Operation Flow**
```
Command → Subagent → Batch Request → Parallel MCP Calls → Aggregate → Return (800ms)
```

**Pattern 4: Create Operation Flow**
```
Command → Subagent → Validate Inputs → Check Cache for IDs → MCP Create → Update Cache → Return (600ms)
```

### 1.3 Invocation Pattern

Commands invoke the subagent using the Task tool with YAML-formatted requests:

```javascript
// From a command
const result = Task(linear-ops-agent): `
operation: get_issue
params:
  issue_id: PSN-123
  include_comments: true
  include_attachments: false
context:
  command: planning:plan
  purpose: "Fetching issue for planning phase"
`

// Subagent returns structured YAML
// result = {
//   success: true,
//   data: { id, title, description, ... },
//   metadata: { cached: false, duration_ms: 450 }
// }
```

---

## 2. Agent Responsibilities

The Linear operations subagent handles **6 primary operation categories**, each optimized for performance and caching.

### 2.1 Issue Operations

**Core Responsibilities**: CRUD operations for Linear issues

#### Operations

##### `get_issue`
Retrieve a single issue by ID with optional expansions.

**Input**:
```yaml
operation: get_issue
params:
  issue_id: "PSN-123"              # Required
  include_comments: false           # Optional, default: false
  include_attachments: false        # Optional, default: false
  include_children: false           # Optional, default: false
context:
  command: "planning:plan"
```

**Output**:
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
  project:
    id: "proj-789"
    name: "Auth System"
  labels:
    - id: "label-1"
      name: "planning"
      color: "#f7c8c1"
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

##### `create_issue`
Create a new Linear issue with labels and state.

**Input**:
```yaml
operation: create_issue
params:
  team: "Engineering"               # Required (name or ID)
  title: "Implement OAuth flow"    # Required
  description: "## Overview\n..."   # Optional
  state: "In Progress"              # Optional (name, type, or ID)
  labels:                           # Optional
    - "planning"
    - "backend"
  assignee: "john@example.com"     # Optional (name, email, ID, or "me")
  project: "Auth System"            # Optional (name or ID)
  priority: 2                       # Optional (0-4)
  estimate: 8                       # Optional
  parent_id: "PSN-100"              # Optional (for sub-issues)
  due_date: "2025-02-01"            # Optional (ISO format)
  links:                            # Optional
    - url: "https://figma.com/..."
      title: "Design Mockup"
context:
  command: "planning:create"
```

**Output**:
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
  mcp_calls: 4  # team lookup, state lookup, label lookups, create
  operations:
    - "resolve_team_id: Engineering → team-456"
    - "resolve_state_id: In Progress → state-123"
    - "ensure_labels: planning, backend → label-1, label-2"
    - "create_issue: success"
```

##### `update_issue`
Update an existing Linear issue.

**Input**:
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

**Output**:
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

##### `list_issues`
Search and filter issues with pagination.

**Input**:
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

**Output**:
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

##### `search_issues`
Advanced issue search (wrapper around list_issues with better defaults).

**Input**:
```yaml
operation: search_issues
params:
  query: "auth bug"                 # Required
  team: "Engineering"               # Optional
  limit: 20                         # Optional
context:
  command: "utils:search"
```

---

### 2.2 Label Management

**Core Responsibilities**: Label creation, lookup, and batching

#### Operations

##### `get_or_create_label`
Get existing label or create if missing (most common operation).

**Input**:
```yaml
operation: get_or_create_label
params:
  team: "Engineering"               # Required (name or ID)
  name: "planning"                  # Required
  color: "#f7c8c1"                  # Optional (auto-assigned if missing)
  description: "Planning phase"     # Optional
context:
  command: "planning:create"
```

**Output**:
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

##### `ensure_labels_exist`
Batch operation to ensure multiple labels exist.

**Input**:
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

**Output**:
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

##### `list_labels`
List all labels for a team (populates cache).

**Input**:
```yaml
operation: list_labels
params:
  team: "Engineering"               # Optional (if omitted, workspace labels)
  refresh_cache: false              # Optional, force cache refresh
context:
  command: "utils:labels"
```

**Output**:
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

---

### 2.3 State/Status Management

**Core Responsibilities**: Status lookup, validation, and state transitions

#### Operations

##### `get_valid_state_id`
Resolve state name/type to valid state ID with fuzzy matching.

**Input**:
```yaml
operation: get_valid_state_id
params:
  team: "Engineering"               # Required
  state: "In Progress"              # Required (name, type, or ID)
context:
  command: "planning:create"
```

**Output**:
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

##### `list_statuses`
List all workflow states for a team (populates cache).

**Input**:
```yaml
operation: list_statuses
params:
  team: "Engineering"               # Required
  refresh_cache: false              # Optional
context:
  command: "utils:statuses"
```

**Output**:
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

##### `validate_state`
Validate a state exists and return detailed info (alias for get_valid_state_id).

---

### 2.4 Team/Project Operations

**Core Responsibilities**: Team and project lookups (heavily cached)

#### Operations

##### `get_team`
Retrieve team details by name or ID.

**Input**:
```yaml
operation: get_team
params:
  team: "Engineering"               # Required (name, key, or ID)
context:
  command: "planning:create"
```

**Output**:
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

##### `get_project`
Retrieve project details by name or ID.

**Input**:
```yaml
operation: get_project
params:
  project: "Auth System"            # Required (name or ID)
  team: "Engineering"               # Optional (for scoped lookup)
context:
  command: "planning:create"
```

**Output**:
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

##### `list_projects`
List projects with filtering (populates cache).

**Input**:
```yaml
operation: list_projects
params:
  team: "Engineering"               # Optional
  state: "planned"                  # Optional
  limit: 50                         # Optional
context:
  command: "utils:projects"
```

**Output**:
```yaml
success: true
data:
  projects:
    - id: "proj-1"
      name: "Auth System"
      # ...
  total: 10
metadata:
  cached: false
  duration_ms: 350
  mcp_calls: 1
```

---

### 2.5 Comment Operations

**Core Responsibilities**: Issue comment management

#### Operations

##### `create_comment`
Add a comment to an issue.

**Input**:
```yaml
operation: create_comment
params:
  issue_id: "PSN-123"               # Required
  body: "## Update\n..."            # Required (Markdown)
  parent_id: "comment-456"          # Optional (for replies)
context:
  command: "implementation:sync"
```

**Output**:
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

##### `list_comments`
Retrieve comments for an issue.

**Input**:
```yaml
operation: list_comments
params:
  issue_id: "PSN-123"               # Required
context:
  command: "planning:plan"
```

**Output**:
```yaml
success: true
data:
  comments:
    - id: "comment-1"
      body: "..."
      created_at: "..."
      user: {...}
  total: 5
metadata:
  cached: false
  duration_ms: 300
  mcp_calls: 1
```

---

### 2.6 Document Operations

**Core Responsibilities**: Linear Document management (for specs)

#### Operations

##### `get_document`
Retrieve a Linear document by ID or slug.

**Input**:
```yaml
operation: get_document
params:
  document_id: "doc-abc-123"        # Required (ID or slug)
context:
  command: "spec:write"
```

**Output**:
```yaml
success: true
data:
  id: "doc-abc-123"
  title: "Auth System Spec"
  content: "# Overview\n..."
  project:
    id: "proj-789"
    name: "Auth System"
  created_at: "..."
  updated_at: "..."
metadata:
  cached: false
  duration_ms: 400
  mcp_calls: 1
```

##### `list_documents`
List documents with filtering.

**Input**:
```yaml
operation: list_documents
params:
  project_id: "proj-789"            # Optional
  query: "authentication"           # Optional
  limit: 50                         # Optional
context:
  command: "spec:list"
```

**Output**:
```yaml
success: true
data:
  documents:
    - id: "doc-1"
      title: "..."
      # ...
  total: 8
metadata:
  cached: false
  duration_ms: 350
  mcp_calls: 1
```

##### `link_document`
Link a document to an issue (for spec management).

**Input**:
```yaml
operation: link_document
params:
  issue_id: "PSN-123"               # Required
  document_id: "doc-abc-123"        # Required
context:
  command: "spec:create"
```

**Output**:
```yaml
success: true
data:
  linked: true
metadata:
  cached: false
  duration_ms: 300
  mcp_calls: 1
```

---

## 3. Input/Output Contract Specification

### 3.1 Input Structure

All operations follow a consistent YAML structure:

```yaml
operation: <operation_name>     # Required: Operation to perform
params:                          # Required: Operation-specific parameters
  <param1>: <value1>
  <param2>: <value2>
context:                         # Optional: Execution context for logging
  command: <command_name>        # Which command invoked this
  purpose: <description>         # Why this operation is needed
  trace_id: <uuid>               # For distributed tracing
```

### 3.2 Output Structure

All operations return structured YAML responses:

#### Success Response
```yaml
success: true                    # Operation succeeded
data:                            # Operation result
  <result_data>
metadata:                        # Execution metadata
  cached: true/false             # Was result from cache?
  duration_ms: 450               # Total execution time
  mcp_calls: 2                   # Number of Linear MCP calls
  operations: []                 # List of sub-operations performed
```

#### Error Response
```yaml
success: false                   # Operation failed
error:
  code: <ERROR_CODE>             # Machine-readable error code
  message: <human_message>       # User-friendly error message
  details:                       # Additional error context
    <key>: <value>
  suggestions: []                # Actionable recovery suggestions
metadata:
  duration_ms: 200               # Time until failure
  mcp_calls: 1                   # Calls made before failure
```

### 3.3 Common Parameters

Parameters used across multiple operations:

- **team**: Team identifier (name, key, or UUID)
- **issue_id**: Issue identifier (ID or identifier like "PSN-123")
- **state**: State identifier (name, type, or UUID)
- **labels**: Array of label names or UUIDs
- **assignee**: User identifier (name, email, UUID, or "me")
- **project**: Project identifier (name or UUID)
- **limit**: Result limit (default: 50, max: 250)
- **order_by**: Sort order (createdAt, updatedAt)

---

## 4. Caching Strategy

### 4.1 Cache Scope

**Session-level caching**: Cache persists for the duration of agent invocation (command execution).

### 4.2 Cached Data Structures

```javascript
// In-memory cache structure (conceptual)
const cache = {
  teams: {
    by_id: Map<teamId, TeamObject>,
    by_name: Map<teamName, teamId>,
    by_key: Map<teamKey, teamId>
  },
  projects: {
    by_id: Map<projectId, ProjectObject>,
    by_name: Map<projectName, projectId>
  },
  labels: {
    by_id: Map<labelId, LabelObject>,
    by_name: Map<`${teamId}:${labelName}`, labelId>
  },
  statuses: {
    by_id: Map<statusId, StatusObject>,
    by_name: Map<`${teamId}:${statusName}`, statusId>,
    by_type: Map<`${teamId}:${type}`, statusId>
  },
  users: {
    by_id: Map<userId, UserObject>,
    by_email: Map<email, userId>,
    by_name: Map<name, userId>
  },
  issues: {
    // Issues NOT cached (too dynamic)
  }
}
```

### 4.3 Cache Keys

**Teams**:
- Primary: `team:id:${teamId}`
- Secondary: `team:name:${teamName}`, `team:key:${teamKey}`

**Projects**:
- Primary: `project:id:${projectId}`
- Secondary: `project:name:${teamId}:${projectName}`

**Labels**:
- Primary: `label:id:${labelId}`
- Secondary: `label:name:${teamId}:${labelName}`

**Statuses**:
- Primary: `status:id:${statusId}`
- Secondary: `status:name:${teamId}:${statusName}`, `status:type:${teamId}:${type}`

**Users**:
- Primary: `user:id:${userId}`
- Secondary: `user:email:${email}`, `user:name:${name}`

### 4.4 Cache Population

**Lazy loading**: Cache populated on-demand when data is requested.

**Batch loading**: When listing operations occur (list_labels, list_statuses), entire result set populates cache.

**Example**:
```javascript
// First call to get_team("Engineering")
// - Cache miss
// - MCP call to Linear
// - Populate cache: team:name:Engineering → team:id:team-456
// - Return result (500ms)

// Second call to get_team("Engineering")
// - Cache hit on team:name:Engineering
// - Return cached result (20ms)

// Third call to get_team("team-456")
// - Cache hit on team:id:team-456 (same team, different lookup key)
// - Return cached result (20ms)
```

### 4.5 Cache Invalidation

**No explicit invalidation**: Session-scoped cache cleared when command execution completes.

**Manual refresh**: `refresh_cache: true` parameter forces cache bypass and refresh.

**Example**:
```yaml
operation: list_labels
params:
  team: "Engineering"
  refresh_cache: true  # Force fresh data from Linear API
```

### 4.6 Performance Targets

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

## 5. Error Handling Patterns

### 5.1 Error Code Taxonomy

#### Entity Not Found Errors (1000-1099)
```yaml
1001: TEAM_NOT_FOUND
1002: PROJECT_NOT_FOUND
1003: LABEL_NOT_FOUND
1004: STATUS_NOT_FOUND
1005: ISSUE_NOT_FOUND
1006: USER_NOT_FOUND
1007: DOCUMENT_NOT_FOUND
```

#### Validation Errors (1100-1199)
```yaml
1101: INVALID_TEAM_IDENTIFIER
1102: INVALID_STATE_NAME
1103: INVALID_LABEL_NAME
1104: INVALID_PRIORITY
1105: INVALID_DATE_FORMAT
1106: MISSING_REQUIRED_PARAM
```

#### Creation Errors (1200-1299)
```yaml
1201: LABEL_CREATION_FAILED
1202: ISSUE_CREATION_FAILED
1203: COMMENT_CREATION_FAILED
1204: PROJECT_CREATION_FAILED
```

#### Update Errors (1300-1399)
```yaml
1301: ISSUE_UPDATE_FAILED
1302: PROJECT_UPDATE_FAILED
```

#### API Errors (1400-1499)
```yaml
1401: LINEAR_API_ERROR
1402: LINEAR_API_RATE_LIMIT
1403: LINEAR_API_TIMEOUT
1404: LINEAR_API_UNAUTHORIZED
```

### 5.2 Error Response Examples

#### TEAM_NOT_FOUND (1001)
```yaml
success: false
error:
  code: TEAM_NOT_FOUND
  message: "Team 'InvalidTeam' not found in Linear workspace"
  details:
    input: "InvalidTeam"
    available_teams:
      - "Engineering"
      - "Design"
      - "Product"
  suggestions:
    - "Use one of the available teams listed above"
    - "Check team name spelling (case-insensitive match)"
    - "Use /ccpm:utils:teams to list all teams"
metadata:
  duration_ms: 250
  mcp_calls: 1
```

#### STATUS_NOT_FOUND (1004)
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
      - name: "Todo"
        type: "unstarted"
      - name: "In Progress"
        type: "started"
      - name: "Done"
        type: "completed"
      - name: "Canceled"
        type: "canceled"
  suggestions:
    - "Use exact status name: 'In Progress'"
    - "Use status type: 'started'"
    - "Use common alias: 'todo' maps to 'unstarted'"
    - "Run /ccpm:utils:statuses to see all available statuses"
metadata:
  duration_ms: 180
  mcp_calls: 1
```

#### LABEL_CREATION_FAILED (1201)
```yaml
success: false
error:
  code: LABEL_CREATION_FAILED
  message: "Failed to create label 'new-label' in team 'Engineering'"
  details:
    label_name: "new-label"
    team: "Engineering"
    reason: "Label name contains invalid characters"
  suggestions:
    - "Use alphanumeric characters, hyphens, and underscores only"
    - "Remove special characters from label name"
    - "Check Linear label naming guidelines"
metadata:
  duration_ms: 400
  mcp_calls: 2
```

#### LINEAR_API_RATE_LIMIT (1402)
```yaml
success: false
error:
  code: LINEAR_API_RATE_LIMIT
  message: "Linear API rate limit exceeded"
  details:
    rate_limit: 1000
    reset_at: "2025-01-16T16:00:00Z"
    retry_after_seconds: 300
  suggestions:
    - "Wait 5 minutes before retrying"
    - "Reduce number of API calls by using cached operations"
    - "Batch operations when possible"
metadata:
  duration_ms: 150
  mcp_calls: 1
```

### 5.3 Graceful Degradation

When non-critical operations fail, continue with partial results:

**Example: Batch Label Creation**
```yaml
operation: ensure_labels_exist
params:
  team: "Engineering"
  labels:
    - name: "valid-label"
    - name: "invalid@label"  # Contains invalid character
    - name: "another-valid"
```

**Response**:
```yaml
success: true  # Partial success
data:
  labels:
    - id: "label-1"
      name: "valid-label"
      created: true
    - id: null
      name: "invalid@label"
      created: false
      error: "Invalid label name"
    - id: "label-3"
      name: "another-valid"
      created: true
warnings:
  - "Failed to create 1 of 3 labels: invalid@label"
metadata:
  duration_ms: 600
  mcp_calls: 3
  success_rate: "66.7%"
```

---

## 6. Performance Considerations

### 6.1 Performance Targets

| Operation | Target | Max | Notes |
|-----------|--------|-----|-------|
| Cached lookup | <50ms | 100ms | Team, project, label, status |
| Single issue get | <500ms | 800ms | With expansions |
| Issue create | <600ms | 1000ms | With label/state resolution |
| Issue update | <500ms | 800ms | With validations |
| List operations | <400ms | 800ms | Default limit: 50 |
| Batch label create | <800ms | 1500ms | 5 labels |
| Comment create | <400ms | 600ms | Simple comment |

### 6.2 Batching Strategies

#### Sequential Batching
For operations requiring ordered execution (e.g., dependent label creation):
```javascript
// Pseudo-code
for (const label of labels) {
  await createLabel(label)  // Wait for each to complete
}
```

#### Parallel Batching
For independent operations (e.g., fetching multiple issues):
```javascript
// Pseudo-code
const promises = issueIds.map(id => getIssue(id))
const results = await Promise.all(promises)
```

#### Smart Batching
Combine parallel and sequential based on dependencies:
```javascript
// Pseudo-code
// Step 1: Resolve team ID (required first)
const teamId = await resolveTeamId(teamName)

// Step 2: Parallel resolution of state and labels
const [stateId, labelIds] = await Promise.all([
  resolveStateId(teamId, stateName),
  resolveLabels(teamId, labelNames)
])

// Step 3: Create issue with resolved IDs
const issue = await createIssue({teamId, stateId, labelIds, ...})
```

### 6.3 API Call Optimization

#### Minimize Round-Trips

**Before (Direct MCP calls from command)**:
```
Command → MCP: get_team("Engineering")     [500ms]
Command → MCP: list_issue_labels(teamId)   [400ms]
Command → MCP: get_label("planning")       [350ms]
Command → MCP: get_label("backend")        [350ms]
Command → MCP: list_issue_statuses(teamId) [400ms]
Command → MCP: create_issue(...)           [600ms]
Total: 2600ms, 6 API calls
```

**After (Subagent with caching)**:
```
Command → Subagent: create_issue(...)
  Subagent → Cache: get_team("Engineering")    [20ms, cached]
  Subagent → Cache: get_label("planning")      [20ms, cached]
  Subagent → Cache: get_label("backend")       [20ms, cached]
  Subagent → Cache: get_state("In Progress")   [20ms, cached]
  Subagent → MCP: create_issue(...)            [600ms]
Total: 680ms, 1 API call
```

**Improvement**: 74% faster, 83% fewer API calls

#### Bulk Lookups

When listing operations are needed, fetch all at once:
```yaml
# Instead of individual label lookups:
# - get_or_create_label("planning")
# - get_or_create_label("backend")
# - get_or_create_label("frontend")

# Use bulk operation:
operation: ensure_labels_exist
params:
  team: "Engineering"
  labels: ["planning", "backend", "frontend"]
# Result: 1 API call instead of 3, shared cache population
```

### 6.4 Metrics to Track

Subagent should log performance metrics for optimization:

```yaml
# Example metrics log
operation: create_issue
metrics:
  total_duration_ms: 680
  cache_hits: 4
  cache_misses: 0
  mcp_calls: 1
  cache_hit_rate: 100%
  breakdown:
    resolve_team: 20ms (cached)
    resolve_labels: 60ms (3x cached)
    resolve_state: 20ms (cached)
    mcp_create_issue: 600ms
```

**Metrics Collection**:
- Cache hit/miss rates per operation type
- Average response time per operation
- MCP call count per operation
- Error rates by error code
- Most expensive operations

---

## 7. Migration Strategy

### 7.1 Phased Migration Approach

#### Phase 1: Subagent Creation (Week 1)
1. Create `agents/linear-ops-agent.md` with all 6 operation categories
2. Implement caching layer structure
3. Add comprehensive error handling
4. Write unit tests for all operations

#### Phase 2: High-Traffic Command Migration (Week 2)
Migrate commands with highest token usage first:
- `planning:plan` (5000+ tokens)
- `planning:create` (4000+ tokens)
- `implementation:start` (3500+ tokens)
- `verification:verify` (3000+ tokens)

**Migration pattern**:
```markdown
<!-- Before -->
Use **Linear MCP** to:
1. Fetch team details for: ${TEAM_NAME}
2. List all labels in team
3. Find or create "planning" label
4. List workflow states
5. Find "In Progress" state
6. Create issue with resolved IDs

<!-- After -->
Task(linear-ops-agent): `
operation: create_issue
params:
  team: ${TEAM_NAME}
  title: "${TITLE}"
  description: "${DESCRIPTION}"
  state: "In Progress"
  labels: ["planning", "backend"]
context:
  command: "planning:create"
`
```

#### Phase 3: Helper Function Migration (Week 3)
- Migrate `commands/_shared-linear-helpers.md` functions into subagent
- Update commands using helpers to use subagent instead
- Keep helpers as fallback for backward compatibility

**Deprecation notice in helpers**:
```markdown
# Shared Linear Integration Helpers

**⚠️ DEPRECATED**: This file is deprecated in favor of the `linear-ops-agent` subagent.
Use the subagent for better performance and caching.

**Migration guide**: See `docs/guides/linear-subagent-migration.md`

## Legacy Functions (Still Supported)
...
```

#### Phase 4: Remaining Commands (Week 4)
- Migrate all remaining commands
- Remove inline Linear MCP calls
- Update documentation

### 7.2 Backward Compatibility

**Direct MCP calls still work**: Commands can still call Linear MCP directly during migration.

**Gradual rollout**: Migrate one command at a time, test thoroughly.

**Rollback support**: If issues arise, revert to direct MCP calls in specific commands.

### 7.3 Testing Strategy

#### Unit Testing
Test each operation in isolation:
```bash
# Test get_issue
Task(linear-ops-agent): `
operation: get_issue
params:
  issue_id: "PSN-123"
`

# Verify response structure, caching, error handling
```

#### Integration Testing
Test command-to-subagent integration:
```bash
# Run existing commands with subagent
/ccpm:planning:create "Test task" test-project

# Verify:
# - Issue created successfully
# - Labels applied correctly
# - State set correctly
# - Performance improved
```

#### Performance Testing
Measure token reduction and latency:
```bash
# Before migration
Command: planning:create
Tokens: 4500
Duration: 2600ms
API calls: 6

# After migration
Command: planning:create (with subagent)
Tokens: 1800 (60% reduction ✅)
Duration: 680ms (74% faster ✅)
API calls: 1 (83% reduction ✅)
```

#### Cache Testing
Verify caching behavior:
```bash
# First invocation (cold cache)
Task(linear-ops-agent): `operation: get_team, params: {team: "Engineering"}`
# Expected: 500ms, 1 MCP call, cached: false

# Second invocation (warm cache)
Task(linear-ops-agent): `operation: get_team, params: {team: "Engineering"}`
# Expected: 20ms, 0 MCP calls, cached: true
```

---

## 8. Integration Examples

### 8.1 Example 1: Command Creating Issue with Labels

**Command**: `planning:create`

**Before (Direct MCP)**:
```markdown
<!-- In command file -->
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
Use Linear MCP to create issue with:
  - teamId (from Step 1)
  - labelIds (from Step 2)
  - stateId (from Step 3)
  - title, description, assignee
```

**Token count**: ~2500 tokens (verbose instructions + inline helpers)

**After (Subagent)**:
```markdown
<!-- In command file -->
## Step 1: Create Issue with Labels

Task(linear-ops-agent): `
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

# Subagent handles:
# - Team ID resolution (cached)
# - Label creation/lookup (cached)
# - State ID resolution (cached)
# - Issue creation
# - Returns created issue with identifier
```

**Token count**: ~400 tokens (60% reduction)

### 8.2 Example 2: Batch Label Creation with Caching

**Command**: `utils:ensure-labels`

**Before**:
```markdown
## Ensure CCPM Workflow Labels Exist

Use Linear MCP:

For each label in [planning, implementation, verification, pr-review, done]:
  1. Search for label in team
  2. If exists, skip
  3. If not exists:
     - Get default color from color map
     - Create label with name, color, description
     - Log creation
  4. Collect all label IDs

Return array of label IDs.
```

**Token count**: ~1200 tokens

**After**:
```markdown
## Ensure CCPM Workflow Labels Exist

Task(linear-ops-agent): `
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
    - name: "pr-review"
      color: "#5e6ad2"
    - name: "done"
      color: "#4cb782"
context:
  command: "utils:ensure-labels"
`

# Subagent handles batching, caching, and creation
# Returns: array of label objects with IDs
```

**Token count**: ~350 tokens (71% reduction)

### 8.3 Example 3: State Transition with Validation

**Command**: `implementation:update`

**Before**:
```markdown
## Update Issue State to "Done"

1. Fetch team ID from Linear issue
2. List all workflow states for team
3. Find "Done" state (try exact match, then type match, then fuzzy)
4. If no match found:
   - List all available states
   - Return error with suggestions
5. Update issue with new state ID

Handle errors:
- Issue not found
- Team not found
- Invalid state
```

**Token count**: ~1000 tokens

**After**:
```markdown
## Update Issue State to "Done"

# Resolve team from issue
const team = Task(linear-ops-agent): `
operation: get_issue
params:
  issue_id: ${ISSUE_ID}
`

# Update with state validation
Task(linear-ops-agent): `
operation: update_issue
params:
  issue_id: ${ISSUE_ID}
  state: "Done"
context:
  command: "implementation:update"
`

# Subagent handles:
# - State ID resolution with fuzzy matching
# - Validation with helpful errors
# - Issue update
```

**Token count**: ~300 tokens (70% reduction)

### 8.4 Example 4: Error Handling and Recovery

**Command**: `planning:plan`

**Before**:
```markdown
## Fetch Linear Issue

Try:
  Fetch issue by ID: ${ISSUE_ID}
Catch:
  If issue not found:
    - Check if ID format is valid
    - Suggest correct format (TEAM-123)
    - List recent issues if needed
  If API error:
    - Log error details
    - Suggest retry
    - Check Linear API status
```

**Token count**: ~800 tokens

**After**:
```markdown
## Fetch Linear Issue

const result = Task(linear-ops-agent): `
operation: get_issue
params:
  issue_id: ${ISSUE_ID}
  include_comments: true
context:
  command: "planning:plan"
`

# Subagent returns structured error if failed:
if (!result.success) {
  # Display error.message and error.suggestions to user
  # Error includes:
  # - Clear message
  # - Available alternatives
  # - Recovery actions
  exit with error
}
```

**Token count**: ~250 tokens (69% reduction)

---

## 9. Implementation Guidelines

### 9.1 Agent File Structure

```markdown
# linear-ops-agent

**Specialized agent for all Linear API operations with session-level caching.**

## Purpose

Centralized Linear operations handler to reduce token usage by 50-60% through:
- Session-scoped in-memory caching
- Structured YAML input/output contracts
- Intelligent batching and optimization
- Graceful error handling with recovery suggestions

## Expertise

- Linear GraphQL API
- Issue lifecycle management
- Label and status management
- Team and project operations
- Document operations
- Caching strategies
- Performance optimization

## Core Responsibilities

[Detailed operation documentation from Section 2]

## Caching Architecture

[Cache structure and strategies from Section 4]

## Error Handling

[Error codes and patterns from Section 5]

## Input/Output Contract

[YAML structures from Section 3]

## Performance Targets

[Benchmarks from Section 6]

## Usage Examples

[Examples from Section 8]

## Best Practices

1. **Always use structured YAML input** - Clear, parseable contracts
2. **Leverage caching** - Second lookups are 90% faster
3. **Batch operations** - Use ensure_labels_exist over individual calls
4. **Handle errors gracefully** - Check success field, display suggestions
5. **Log operations** - Use context field for tracing
6. **Optimize for common paths** - Cache hit rate targets: 85-95%
7. **Monitor performance** - Track metrics in metadata field

## Maintenance Notes

- Cache invalidation is session-scoped (no manual invalidation needed)
- Add new operations following existing patterns
- Update error codes in centralized taxonomy
- Keep performance targets documented
- Log cache hit rates for optimization
```

### 9.2 Command Migration Template

```markdown
<!-- Before migration -->
## Step X: [Operation Name]

Use Linear MCP to:
1. [Detailed step 1]
2. [Detailed step 2]
3. [Detailed step 3]

[Inline helper function usage]
[Error handling logic]

<!-- After migration -->
## Step X: [Operation Name]

Task(linear-ops-agent): `
operation: <operation_name>
params:
  <param1>: <value1>
  <param2>: <value2>
context:
  command: "<command_name>"
  purpose: "<brief_description>"
`

# Subagent handles all logic, caching, and errors
# Result: {success, data, error, metadata}
```

### 9.3 Testing Checklist

For each migrated command:

- [ ] Unit test: Subagent operation works in isolation
- [ ] Integration test: Command executes successfully end-to-end
- [ ] Performance test: Token count reduced by target %
- [ ] Cache test: Second invocation uses cache
- [ ] Error test: Invalid inputs return helpful errors
- [ ] Backward compat test: Old direct MCP calls still work
- [ ] Documentation: Updated command docs and examples

### 9.4 Code Review Guidelines

When reviewing subagent implementation:

1. **Caching correctness**: Verify cache keys are unique and lookups work
2. **Error handling**: All error codes defined, messages helpful
3. **Performance**: Operations meet target latency
4. **YAML structure**: Input/output follows contract specification
5. **Documentation**: Examples clear, usage documented
6. **Testing**: All operations have test coverage
7. **Token reduction**: Actual reduction matches target (50-60%)

---

## 10. Success Metrics

### 10.1 Token Reduction Targets

| Command Category | Before (tokens) | After (tokens) | Reduction % | Status |
|------------------|-----------------|----------------|-------------|---------|
| Planning commands | 4000-5000 | 1600-2000 | 60% | 🎯 Target |
| Implementation commands | 3000-4000 | 1200-1600 | 60% | 🎯 Target |
| Verification commands | 2500-3500 | 1000-1400 | 60% | 🎯 Target |
| Utility commands | 1500-2500 | 600-1000 | 60% | 🎯 Target |

### 10.2 Performance Targets

| Metric | Target | Acceptable | Red Flag |
|--------|--------|-----------|----------|
| Cached lookup | <50ms | <100ms | >150ms |
| Uncached lookup | <500ms | <800ms | >1000ms |
| Cache hit rate | >90% | >80% | <70% |
| Issue creation | <600ms | <1000ms | >1500ms |
| Batch operation (5 items) | <800ms | <1500ms | >2000ms |

### 10.3 Quality Targets

| Metric | Target |
|--------|--------|
| Test coverage | >90% |
| Error handling coverage | 100% (all error codes) |
| Documentation completeness | 100% (all operations) |
| Backward compatibility | 100% (no breaking changes) |

### 10.4 Rollout Milestones

| Milestone | Date | Deliverable |
|-----------|------|-------------|
| M1: Architecture approved | Week 1 Day 1 | This document |
| M2: Subagent implemented | Week 1 Day 5 | `agents/linear-ops-agent.md` |
| M3: High-traffic commands migrated | Week 2 Day 5 | 4 commands migrated |
| M4: Helper functions migrated | Week 3 Day 5 | Helpers deprecated |
| M5: All commands migrated | Week 4 Day 5 | 100% migration |
| M6: Documentation complete | Week 4 Day 7 | Migration guide published |

---

## 11. Risks and Mitigations

### 11.1 Risk: Cache Staleness

**Description**: Cached data becomes outdated if Linear data changes externally.

**Impact**: Medium - Users might see stale label/status lists.

**Mitigation**:
- Session-scoped cache (cleared on command completion)
- Manual refresh option: `refresh_cache: true`
- Document cache behavior in agent docs

### 11.2 Risk: Increased Agent Complexity

**Description**: Subagent adds complexity vs direct MCP calls.

**Impact**: Low - More code to maintain, test.

**Mitigation**:
- Comprehensive documentation (this document)
- Unit tests for all operations
- Clear error messages for debugging
- Gradual rollout with rollback plan

### 11.3 Risk: Migration Effort Underestimated

**Description**: Migrating 49+ commands may take longer than expected.

**Impact**: Medium - Delayed completion.

**Mitigation**:
- Phased approach (high-traffic commands first)
- Migration template for consistency
- Backward compatibility (no hard cutover)
- Prioritize commands by token usage

### 11.4 Risk: Performance Degradation

**Description**: Subagent overhead reduces performance.

**Impact**: Low - Additional layer adds latency.

**Mitigation**:
- Performance targets defined and measured
- Caching reduces overall latency
- Metrics tracking for optimization
- Fallback to direct MCP if needed

---

## 12. Next Steps

### 12.1 Immediate Actions (Day 1)

1. **Review and approve architecture** - Stakeholder sign-off
2. **Create agent file scaffold** - `agents/linear-ops-agent.md`
3. **Set up testing framework** - Unit test structure

### 12.2 Week 1 Tasks

1. Implement all 6 operation categories in subagent
2. Add caching layer with all data structures
3. Implement error handling for all error codes
4. Write comprehensive documentation in agent file
5. Create unit tests for each operation

### 12.3 Week 2 Tasks

1. Migrate `planning:plan` command
2. Migrate `planning:create` command
3. Migrate `implementation:start` command
4. Migrate `verification:verify` command
5. Measure token reduction and performance

### 12.4 Week 3 Tasks

1. Migrate helper functions from `_shared-linear-helpers.md`
2. Update all commands using helpers
3. Mark helpers as deprecated
4. Write migration guide documentation

### 12.5 Week 4 Tasks

1. Migrate remaining commands
2. Complete end-to-end testing
3. Finalize documentation
4. Publish migration guide
5. Monitor metrics and optimize

---

## 13. Conclusion

The Linear operations subagent architecture provides a comprehensive solution to CCPM's token usage problem by:

1. **Centralizing Linear operations** - Single source of truth with clear contracts
2. **Implementing aggressive caching** - 85-95% cache hit rates for metadata
3. **Optimizing API calls** - 83% reduction in Linear MCP calls
4. **Providing clear error handling** - Actionable recovery suggestions
5. **Maintaining backward compatibility** - Gradual migration with no breaking changes

**Expected outcomes**:
- ✅ 50-60% token reduction across all commands
- ✅ 74% faster execution for cached operations
- ✅ 83% fewer Linear API calls
- ✅ Improved maintainability with single agent
- ✅ Better error handling and debugging

**Implementation timeline**: 4 weeks with phased rollout

**Risk level**: Low - Mitigations in place for all identified risks

This architecture is **ready for implementation** and expected to deliver significant performance and cost improvements to the CCPM plugin.

---

## Appendix A: Linear MCP Tool Reference

Complete list of Linear MCP tools used by subagent:

| Tool | Usage | Cached |
|------|-------|--------|
| `get_team` | Team lookup | ✅ Yes |
| `list_teams` | Cache population | ✅ Yes |
| `get_project` | Project lookup | ✅ Yes |
| `list_projects` | Cache population | ✅ Yes |
| `list_issue_labels` | Label lookup | ✅ Yes |
| `create_issue_label` | Label creation | ➡️ Updates cache |
| `list_issue_statuses` | Status lookup | ✅ Yes |
| `get_issue_status` | Status details | ✅ Yes |
| `get_issue` | Issue retrieval | ❌ No |
| `create_issue` | Issue creation | ❌ No |
| `update_issue` | Issue update | ❌ No |
| `list_issues` | Issue search | ❌ No |
| `create_comment` | Comment creation | ❌ No |
| `list_comments` | Comment retrieval | ❌ No |
| `get_document` | Document retrieval | ❌ No |
| `list_documents` | Document search | ❌ No |
| `get_user` | User lookup | ✅ Yes |
| `list_users` | Cache population | ✅ Yes |

---

## Appendix B: YAML Contract Examples

### Complete Issue Creation Example

```yaml
# Input
operation: create_issue
params:
  team: "Engineering"
  title: "Implement OAuth 2.0 flow"
  description: |
    ## Overview
    Add OAuth 2.0 authentication flow to support third-party login.

    ## Requirements
    - Google OAuth provider
    - Facebook OAuth provider
    - JWT token generation
    - Refresh token support

    ## Acceptance Criteria
    - [ ] Users can log in with Google
    - [ ] Users can log in with Facebook
    - [ ] Tokens expire after 1 hour
    - [ ] Refresh tokens work correctly
  state: "In Progress"
  labels:
    - "planning"
    - "backend"
    - "security"
  assignee: "john@example.com"
  project: "Auth System"
  priority: 2
  estimate: 13
  due_date: "2025-02-15"
  links:
    - url: "https://figma.com/design/oauth-flow"
      title: "OAuth Flow Design"
    - url: "https://confluence.com/oauth-spec"
      title: "OAuth Specification"
context:
  command: "planning:create"
  purpose: "Creating new authentication feature"
  trace_id: "trace-abc-123"

# Output
success: true
data:
  id: "issue-xyz-789"
  identifier: "ENG-234"
  title: "Implement OAuth 2.0 flow"
  description: "[full description]"
  url: "https://linear.app/engineering/issue/ENG-234"
  state:
    id: "state-456"
    name: "In Progress"
    type: "started"
  team:
    id: "team-123"
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
    - id: "label-3"
      name: "security"
      color: "#eb5757"
  assignee:
    id: "user-456"
    name: "John Doe"
    email: "john@example.com"
  priority: 2
  estimate: 13
  due_date: "2025-02-15T00:00:00Z"
  branch_name: "john/eng-234-implement-oauth-2-0-flow"
  created_at: "2025-01-16T10:00:00Z"
  updated_at: "2025-01-16T10:00:00Z"
metadata:
  cached: false
  duration_ms: 680
  mcp_calls: 5
  operations:
    - "resolve_team_id: Engineering → team-123 (cached)"
    - "resolve_project_id: Auth System → proj-789 (cached)"
    - "resolve_state_id: In Progress → state-456 (cached)"
    - "ensure_labels: planning, backend, security → 3 labels (2 cached, 1 created)"
    - "resolve_user: john@example.com → user-456 (cached)"
    - "create_issue: success"
```

---

**Document Version**: 1.0
**Last Updated**: 2025-11-20
**Review Date**: 2025-12-01 (post-implementation review)
