# Multi-PM Subagent System Architecture

**Issue**: PSN-31 - CCPM Ultimate Optimization - Phase 3: Token Efficiency
**Author**: Backend Architect Agent
**Date**: 2025-11-21
**Status**: Architecture Design (Ready for Implementation)
**Version**: 1.0

---

## Executive Summary

This document specifies the architecture for a comprehensive multi-PM (Project Management) subagent system that extends the Linear subagent pattern to **all external PM systems**, achieving:

1. **40-60% token reduction** across all external PM operations
2. **Unified caching strategy** with 80-90% cache hit rates
3. **Parallel orchestration** for independent operations
4. **Consistent error handling** with actionable recovery suggestions
5. **Lazy loading** for command optimization
6. **Session-level caching** across Jira, Confluence, Slack, BitBucket

**Expected Impact**:
- **Token reduction**: 40-60% for commands using external PM systems
- **Performance**: <100ms for cached operations, <600ms for uncached
- **API efficiency**: 70-80% reduction in external API calls
- **Cache hit rates**: 80-90% for metadata operations
- **Maintainability**: Single source of truth per PM system

**Systems Covered**:
- Jira (issues, transitions, comments)
- Confluence (pages, spaces, comments, search)
- Slack (messages, channels, threads)
- BitBucket (pull requests, repositories, commits)

---

## 1. System Architecture Overview

### 1.1 Architectural Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      CCPM Commands Layer                         │
│        (planning:*, implementation:*, verification:*, etc.)      │
└──────────────────────┬──────────────────────────────────────────┘
                       │ Task(pm-ops): {...}
                       ↓
┌─────────────────────────────────────────────────────────────────┐
│              PM Operations Orchestrator (NEW)                    │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Parallel Work Coordinator                              │    │
│  │  - Dependency graph analysis                            │    │
│  │  - Parallel execution planning                          │    │
│  │  - Progress aggregation                                 │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Unified Session Cache (Cross-PM)                       │    │
│  │  - Workspace metadata (users, permissions)              │    │
│  │  - Project/Space mappings                               │    │
│  │  - Status/Priority/Type mappings                        │    │
│  └────────────────────────────────────────────────────────┘    │
└──────────┬───────────┬───────────┬──────────┬───────────────────┘
           │           │           │          │
           ↓           ↓           ↓          ↓
┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐
│  Linear      │ │  Jira    │ │Confluence│ │   Slack    │
│  Operations  │ │  Ops     │ │   Ops    │ │    Ops     │
│  Subagent    │ │ Subagent │ │ Subagent │ │  Subagent  │
│  (EXISTING)  │ │  (NEW)   │ │  (NEW)   │ │   (NEW)    │
└──────┬───────┘ └────┬─────┘ └────┬─────┘ └─────┬──────┘
       │              │            │             │
       ↓              ↓            ↓             ↓
┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐
│Linear MCP    │ │Jira MCP  │ │Conf MCP  │ │ Slack MCP  │
└──────────────┘ └──────────┘ └──────────┘ └────────────┘
```

### 1.2 Core Principles

**Consistency First**:
- All subagents follow the same YAML contract structure
- Unified error handling and caching patterns
- Consistent operation naming conventions

**Performance Optimized**:
- Session-level caching with 80-90% hit rates
- Parallel execution for independent operations
- Lazy loading to minimize token overhead

**Developer Friendly**:
- Clear, predictable YAML contracts
- Structured error responses with suggestions
- Comprehensive documentation per subagent

**Maintainable**:
- Single source of truth per PM system
- Centralized caching logic
- Easy to add new PM systems

### 1.3 Design Patterns

#### Pattern 1: Delegation Pattern
Commands delegate entire operations to specialized subagents:

```markdown
# Before (Direct MCP - 3500 tokens)
Use Jira MCP to:
1. Get issue JIRA-123
2. Get transitions for issue
3. Find "Done" transition
4. Transition issue
5. Add comment with status

# After (Subagent - 800 tokens, 77% reduction)
Task(jira-operations): `
operation: transition_issue
params:
  issue_key: JIRA-123
  transition: "Done"
  comment: "Implementation complete"
context:
  command: "verification:verify"
`
```

#### Pattern 2: Unified Caching Pattern
All subagents share cache structure and hit rate targets:

```yaml
# Cache structure (conceptual)
cache:
  jira:
    projects: Map<projectKey, ProjectObject>
    issue_types: Map<projectKey, IssueTypeArray>
    statuses: Map<projectKey, StatusArray>
    priorities: Map<id, PriorityObject>
  confluence:
    spaces: Map<spaceKey, SpaceObject>
    pages: Map<pageId, PageObject>
  slack:
    channels: Map<channelId, ChannelObject>
    users: Map<userId, UserObject>
```

#### Pattern 3: Parallel Orchestration Pattern
Independent operations execute in parallel:

```yaml
operation: batch_gather_context
params:
  issue_key: JIRA-123
  operations:
    - type: jira_issue
    - type: confluence_search
      query: "authentication"
    - type: slack_search
      query: "auth implementation"
    - type: bitbucket_related_prs
parallel: true  # Execute all in parallel
```

---

## 2. Jira Operations Subagent

### 2.1 Purpose

Centralized handler for all Jira operations with session-level caching.

**Token Impact**: 50-60% reduction (3500 → 1400-1800 tokens per workflow)

### 2.2 Core Operations

#### Issue Operations (6 operations)
1. **get_issue** - Fetch issue with optional expansions
2. **create_issue** - Create issue with validation
3. **update_issue** - Update issue fields
4. **transition_issue** - Change issue status
5. **search_issues** - JQL-based search
6. **link_issues** - Link issues together

#### Comment Operations (2 operations)
1. **add_comment** - Add comment to issue
2. **get_comments** - Fetch issue comments

#### Metadata Operations (4 operations)
1. **get_project** - Get project details
2. **get_issue_types** - Get available issue types
3. **get_transitions** - Get valid transitions for issue
4. **get_priorities** - Get priority list

### 2.3 Operation Specification: create_issue

**Input YAML**:
```yaml
operation: create_issue
params:
  project: "TRAIN"                 # Required (key or ID)
  issue_type: "Task"               # Required (name or ID)
  summary: "Implement JWT auth"    # Required
  description: "..."               # Optional (Markdown)
  assignee: "john@example.com"    # Optional (email, name, or ID)
  priority: "High"                 # Optional (name or ID)
  labels: ["backend", "security"]  # Optional
  parent: "TRAIN-100"              # Optional (for subtasks)
  custom_fields:                   # Optional
    customfield_10001: "value"
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
  self: "https://yoursite.atlassian.net/rest/api/3/issue/10234"
  fields:
    summary: "Implement JWT auth"
    description: "..."
    issuetype:
      id: "10001"
      name: "Task"
    status:
      id: "1"
      name: "To Do"
    assignee:
      accountId: "abc123"
      displayName: "John Doe"
      emailAddress: "john@example.com"
metadata:
  cached: false
  duration_ms: 650
  mcp_calls: 4
  operations:
    - "resolve_project: TRAIN → 10045 (cached)"
    - "resolve_issue_type: Task → 10001 (cached)"
    - "resolve_assignee: john@example.com → abc123 (cached)"
    - "resolve_priority: High → 3 (cached)"
    - "create_issue: success"
```

### 2.4 Caching Strategy

**Highly Cacheable** (90-95% hit rate):
- Projects (by key, name)
- Issue types (by project)
- Priorities
- Statuses/Transitions (by project)

**Moderately Cacheable** (70-80% hit rate):
- Users (by email, name)
- Custom field schemas

**Not Cached**:
- Issue details (too dynamic)
- Comments (user-generated content)

### 2.5 Error Handling

**Error Codes**:
```yaml
2001: PROJECT_NOT_FOUND
2002: ISSUE_TYPE_NOT_FOUND
2003: ISSUE_NOT_FOUND
2004: INVALID_TRANSITION
2005: PERMISSION_DENIED
2006: REQUIRED_FIELD_MISSING
2401: JIRA_API_ERROR
2402: JIRA_API_RATE_LIMIT
2403: JIRA_API_TIMEOUT
```

**Example Error Response**:
```yaml
success: false
error:
  code: INVALID_TRANSITION
  message: "Cannot transition TRAIN-123 to 'Done' - invalid workflow state"
  details:
    issue_key: "TRAIN-123"
    current_status: "In Progress"
    requested_transition: "Done"
    available_transitions:
      - id: "31"
        name: "In Review"
      - id: "41"
        name: "Blocked"
  suggestions:
    - "Use 'In Review' transition first"
    - "Check workflow configuration for this project"
    - "Run /ccpm:utils:jira-transitions TRAIN-123 to see all options"
metadata:
  duration_ms: 350
  mcp_calls: 2
```

### 2.6 Performance Targets

| Operation | Cached | Uncached | Target Hit Rate |
|-----------|--------|----------|-----------------|
| Project lookup | <50ms | 400ms | 95% |
| Issue type lookup | <50ms | 350ms | 90% |
| Priority lookup | <50ms | 300ms | 95% |
| User lookup | <50ms | 400ms | 75% |
| Issue get | N/A | 500ms | N/A |
| Issue create | N/A | 650ms | N/A |
| Transition issue | <100ms | 450ms | 50% (transition cache) |

---

## 3. Confluence Operations Subagent

### 3.1 Purpose

Centralized handler for Confluence operations with content-aware caching.

**Token Impact**: 45-55% reduction (2800 → 1260-1540 tokens per workflow)

### 3.2 Core Operations

#### Page Operations (5 operations)
1. **get_page** - Fetch page with content (Markdown)
2. **search_pages** - CQL-based search
3. **create_page** - Create new page
4. **update_page** - Update existing page
5. **get_page_tree** - Get page hierarchy

#### Space Operations (2 operations)
1. **get_space** - Get space details
2. **list_spaces** - List accessible spaces

#### Comment Operations (2 operations)
1. **add_comment** - Add page/inline comment
2. **get_comments** - Get page comments

### 3.3 Operation Specification: search_pages

**Input YAML**:
```yaml
operation: search_pages
params:
  query: "authentication implementation"  # Required (search text)
  space: "TECH"                          # Optional (space key)
  type: "page"                           # Optional (page, blogpost)
  limit: 25                              # Optional (default: 25)
  cql: 'label = "backend"'               # Optional (additional CQL)
context:
  command: "planning:plan"
  purpose: "Searching for implementation docs"
```

**Output YAML**:
```yaml
success: true
data:
  results:
    - id: "12345678"
      type: "page"
      title: "Authentication Implementation Guide"
      space:
        key: "TECH"
        name: "Technical Docs"
      excerpt: "This guide covers JWT authentication..."
      url: "https://yoursite.atlassian.net/wiki/spaces/TECH/pages/12345678"
      lastModified: "2025-01-15T10:30:00Z"
    # ... more results
  total: 8
  has_more: false
metadata:
  cached: false
  duration_ms: 450
  mcp_calls: 1
  search_tokens: ["authentication", "implementation", "JWT"]
```

### 3.4 Caching Strategy

**Highly Cacheable** (85-90% hit rate):
- Spaces (by key, name)
- Space permissions
- User mappings

**Conditionally Cacheable** (60-70% hit rate):
- Page metadata (title, URL, last modified)
- Page tree structure

**Not Cached**:
- Page content (large, frequently updated)
- Search results (query-dependent)
- Comments

**Cache Invalidation**:
- Manual refresh: `refresh_cache: true`
- TTL: 5 minutes for page metadata

### 3.5 Error Handling

**Error Codes**:
```yaml
3001: SPACE_NOT_FOUND
3002: PAGE_NOT_FOUND
3003: PERMISSION_DENIED
3004: INVALID_CQL
3005: ATTACHMENT_NOT_FOUND
3401: CONFLUENCE_API_ERROR
3402: CONFLUENCE_API_RATE_LIMIT
3403: CONFLUENCE_API_TIMEOUT
```

### 3.6 Performance Targets

| Operation | Cached | Uncached | Target Hit Rate |
|-----------|--------|----------|-----------------|
| Space lookup | <50ms | 400ms | 90% |
| Page metadata | <80ms | 500ms | 65% |
| Page content | N/A | 600ms | N/A (not cached) |
| Search pages | N/A | 450ms | N/A |
| Create page | N/A | 700ms | N/A |

---

## 4. Slack Operations Subagent

### 4.1 Purpose

Centralized handler for Slack operations with conversation-aware caching.

**Token Impact**: 40-50% reduction (2200 → 1100-1320 tokens per workflow)

### 4.2 Core Operations

#### Channel Operations (3 operations)
1. **get_channel** - Get channel details
2. **list_channels** - List accessible channels
3. **search_messages** - Search channel messages

#### Message Operations (3 operations)
1. **post_message** - Send message to channel
2. **get_thread** - Get conversation thread
3. **get_message_history** - Get channel history

#### User Operations (2 operations)
1. **get_user** - Get user details
2. **list_users** - List workspace users

### 4.3 Operation Specification: search_messages

**Input YAML**:
```yaml
operation: search_messages
params:
  query: "authentication bug"      # Required
  channel: "C12345678"             # Optional (channel ID or name)
  from_user: "john@example.com"   # Optional
  after: "2025-01-01"              # Optional (ISO date)
  limit: 50                        # Optional (default: 50)
context:
  command: "planning:plan"
  purpose: "Finding discussions about auth bug"
```

**Output YAML**:
```yaml
success: true
data:
  messages:
    - ts: "1705320000.123456"
      user:
        id: "U12345"
        name: "John Doe"
        email: "john@example.com"
      text: "We found a bug in the JWT validation..."
      channel:
        id: "C12345678"
        name: "engineering"
      thread_ts: "1705320000.123456"  # If message starts thread
      replies: 5                       # Number of thread replies
      permalink: "https://yourworkspace.slack.com/archives/..."
    # ... more messages
  total: 12
  has_more: false
metadata:
  cached: false
  duration_ms: 500
  mcp_calls: 1
```

### 4.4 Caching Strategy

**Highly Cacheable** (85-95% hit rate):
- Channels (by ID, name)
- Users (by ID, email, name)
- Workspace metadata

**Not Cached**:
- Messages (real-time, user-generated)
- Thread replies (dynamic)
- Search results (query-dependent)

### 4.5 Error Handling

**Error Codes**:
```yaml
4001: CHANNEL_NOT_FOUND
4002: USER_NOT_FOUND
4003: MESSAGE_NOT_FOUND
4004: PERMISSION_DENIED
4005: CHANNEL_ARCHIVED
4401: SLACK_API_ERROR
4402: SLACK_API_RATE_LIMIT
4403: SLACK_API_TIMEOUT
```

### 4.6 Performance Targets

| Operation | Cached | Uncached | Target Hit Rate |
|-----------|--------|----------|-----------------|
| Channel lookup | <50ms | 350ms | 90% |
| User lookup | <50ms | 350ms | 90% |
| Search messages | N/A | 500ms | N/A |
| Get thread | N/A | 400ms | N/A |
| Post message | N/A | 350ms | N/A |

---

## 5. Unified Session Cache Architecture

### 5.1 Cache Structure

```javascript
// Conceptual unified cache
const sessionCache = {
  // Linear (existing)
  linear: {
    teams: Map<id|name|key, TeamObject>,
    projects: Map<id|name, ProjectObject>,
    labels: Map<teamId:name, LabelObject>,
    statuses: Map<teamId:name|type, StatusObject>
  },

  // Jira (new)
  jira: {
    projects: Map<key|name, ProjectObject>,
    issue_types: Map<projectKey, IssueTypeArray>,
    priorities: Map<id|name, PriorityObject>,
    statuses: Map<projectKey, StatusArray>,
    users: Map<email|name|accountId, UserObject>
  },

  // Confluence (new)
  confluence: {
    spaces: Map<key|name, SpaceObject>,
    page_metadata: Map<pageId, PageMetadata>,  // TTL: 5 min
    users: Map<accountId|email, UserObject>
  },

  // Slack (new)
  slack: {
    channels: Map<id|name, ChannelObject>,
    users: Map<id|email|name, UserObject>,
    workspace: WorkspaceMetadata
  },

  // BitBucket (new)
  bitbucket: {
    repositories: Map<slug, RepositoryObject>,
    users: Map<uuid|name, UserObject>,
    projects: Map<key, ProjectObject>
  },

  // Cross-PM mappings
  mappings: {
    users: {
      // Map users across systems
      jira_accountId_to_slack_userId: Map<string, string>,
      jira_accountId_to_linear_userId: Map<string, string>
    }
  }
};
```

### 5.2 Cache Lifecycle

**Population Strategy**:
- **Lazy loading**: Cache populated on first access
- **Batch loading**: List operations populate entire cache
- **Pre-warming**: Common lookups pre-loaded at session start

**Invalidation Strategy**:
- **Session-scoped**: Clear on command completion
- **Manual refresh**: `refresh_cache: true` parameter
- **TTL-based**: Short TTL (5 min) for frequently-changing data

**Cache Metrics**:
```yaml
cache_metrics:
  hit_rate: 87.3%
  hits: 142
  misses: 21
  by_system:
    linear: { hit_rate: 91.2%, hits: 52, misses: 5 }
    jira: { hit_rate: 85.7%, hits: 48, misses: 8 }
    confluence: { hit_rate: 83.3%, hits: 25, misses: 5 }
    slack: { hit_rate: 88.9%, hits: 17, misses: 3 }
```

---

## 6. Parallel Orchestration System

### 6.1 Purpose

Coordinate parallel execution of independent operations across multiple PM systems.

### 6.2 Operation: batch_gather_context

**Input YAML**:
```yaml
operation: batch_gather_context
params:
  jira_ticket: "TRAIN-123"
  operations:
    - subagent: jira-operations
      operation: get_issue
      params:
        issue_key: "TRAIN-123"
        expand: ["changelog", "comments"]

    - subagent: confluence-operations
      operation: search_pages
      params:
        query: "authentication JWT"
        space: "TECH"
        limit: 10

    - subagent: slack-operations
      operation: search_messages
      params:
        query: "TRAIN-123 authentication"
        limit: 25

    - subagent: bitbucket-operations
      operation: search_pull_requests
      params:
        query: "TRAIN-123"
        state: "MERGED"

  parallel: true  # Execute all in parallel
  fail_fast: false  # Continue on individual failures
context:
  command: "planning:plan"
  purpose: "Gathering comprehensive context for planning"
```

**Output YAML**:
```yaml
success: true
data:
  results:
    - subagent: jira-operations
      success: true
      data: { ... jira issue ... }
      duration_ms: 450

    - subagent: confluence-operations
      success: true
      data: { ... search results ... }
      duration_ms: 420

    - subagent: slack-operations
      success: true
      data: { ... messages ... }
      duration_ms: 380

    - subagent: bitbucket-operations
      success: false
      error:
        code: REPOSITORY_NOT_FOUND
        message: "Repository not found"
      duration_ms: 200
metadata:
  total_duration_ms: 520  # Parallel execution
  sequential_would_be_ms: 1450  # 64% faster
  success_rate: "75%" (3/4 succeeded)
  operations_executed: 4
  operations_successful: 3
  operations_failed: 1
```

### 6.3 Dependency Graph Analysis

When operations have dependencies, the orchestrator builds a dependency graph:

```yaml
operation: batch_operations_with_deps
params:
  operations:
    - id: "get_jira"
      subagent: jira-operations
      operation: get_issue
      params: { issue_key: "TRAIN-123" }

    - id: "create_linear"
      subagent: linear-operations
      operation: create_issue
      params: { ... }
      depends_on: ["get_jira"]  # Wait for Jira issue first

    - id: "search_confluence"
      subagent: confluence-operations
      operation: search_pages
      params: { ... }
      # No dependencies - can run in parallel
```

**Execution Plan**:
```
Phase 1 (parallel): get_jira, search_confluence
Phase 2 (depends on Phase 1): create_linear (waits for get_jira)
```

### 6.4 Progress Reporting

For long-running batch operations:

```yaml
# Progress event stream
progress:
  - timestamp: "2025-01-21T10:00:00.000Z"
    operation: "get_jira"
    status: "started"

  - timestamp: "2025-01-21T10:00:00.450Z"
    operation: "get_jira"
    status: "completed"
    duration_ms: 450

  - timestamp: "2025-01-21T10:00:00.820Z"
    operation: "search_confluence"
    status: "completed"
    duration_ms: 420

  - timestamp: "2025-01-21T10:00:00.900Z"
    operation: "create_linear"
    status: "started"

  - timestamp: "2025-01-21T10:00:01.520Z"
    operation: "create_linear"
    status: "completed"
    duration_ms: 620
```

---

## 7. Lazy Loading Mechanism

### 7.1 Purpose

Minimize token overhead by loading subagents on-demand.

### 7.2 Implementation Strategy

**Command Structure**:
```markdown
# In commands/planning:plan.md

## Step 1: Gather Context (Lazy Load)

# Don't read all subagents upfront
# Instead, delegate to orchestrator

Task(pm-orchestrator): `
operation: lazy_gather_context
params:
  required_systems: ["jira", "confluence", "slack"]
  operations: [...]
`

# Orchestrator will:
# 1. Determine which subagents are needed
# 2. Load only those subagents
# 3. Execute operations
# 4. Return aggregated results
```

**Token Savings**:
```
Before (Eager Loading):
- Read linear-operations.md: 15,000 tokens
- Read jira-operations.md: 12,000 tokens
- Read confluence-operations.md: 10,000 tokens
- Read slack-operations.md: 8,000 tokens
Total: 45,000 tokens

After (Lazy Loading):
- Read pm-orchestrator.md: 5,000 tokens
- Orchestrator reads only needed subagents internally
- Commands never directly read subagents
Total: 5,000 tokens (89% reduction)
```

### 7.3 Orchestrator Design

```markdown
# agents/pm-orchestrator.md

## Purpose

Lightweight orchestrator that:
1. Analyzes requested operations
2. Determines required subagents
3. Loads subagents dynamically
4. Coordinates execution
5. Aggregates results

## Operations

### lazy_gather_context

Intelligently load and execute across multiple PM systems.

### smart_delegate

Analyze operation and route to appropriate subagent.

### batch_parallel_execute

Execute multiple operations in parallel with dependencies.
```

---

## 8. Token Usage Projections

### 8.1 Current State (Without Subagents)

| Command | Token Usage | API Calls | Duration |
|---------|-------------|-----------|----------|
| planning:plan | 5,500 | 12 | 3,500ms |
| planning:create | 4,200 | 9 | 2,800ms |
| implementation:start | 3,800 | 8 | 2,400ms |
| verification:verify | 3,200 | 7 | 2,100ms |

**Total per full workflow**: ~16,700 tokens, 36 API calls

### 8.2 After Phase 3 (With Multi-PM Subagents)

| Command | Token Usage | Reduction | API Calls | Reduction | Duration |
|---------|-------------|-----------|-----------|-----------|----------|
| planning:plan | 2,200 | 60% | 5 | 58% | 1,200ms |
| planning:create | 1,680 | 60% | 4 | 56% | 1,000ms |
| implementation:start | 1,520 | 60% | 3 | 63% | 900ms |
| verification:verify | 1,280 | 60% | 3 | 57% | 800ms |

**Total per full workflow**: ~6,680 tokens (60% reduction), 15 API calls (58% reduction)

### 8.3 Breakdown by System

**Jira Operations**:
- Before: 3,500 tokens per workflow
- After: 1,400 tokens (60% reduction)
- Cache hit rate: 85%

**Confluence Operations**:
- Before: 2,800 tokens per workflow
- After: 1,260 tokens (55% reduction)
- Cache hit rate: 80%

**Slack Operations**:
- Before: 2,200 tokens per workflow
- After: 1,100 tokens (50% reduction)
- Cache hit rate: 85%

**Linear Operations** (already optimized in v2.3):
- Already: 50-60% reduction
- With orchestrator: Additional 10% improvement

---

## 9. Migration Strategy

### 9.1 Phased Rollout

#### Phase 3.1: Foundation (Week 1)
**Deliverables**:
- PM Orchestrator agent (`agents/pm-orchestrator.md`)
- Unified cache architecture
- Dependency graph analyzer
- Progress reporting system

**Tasks**:
1. Create orchestrator agent scaffold
2. Implement unified cache structure
3. Build dependency graph analyzer
4. Add progress reporting

#### Phase 3.2: Jira Subagent (Week 2)
**Deliverables**:
- Jira Operations Subagent (`agents/jira-operations.md`)
- All 12 Jira operations
- Jira-specific caching
- Error handling and codes

**Tasks**:
1. Design Jira operation contracts
2. Implement all operations
3. Add caching layer
4. Write comprehensive tests
5. Migrate 2-3 high-traffic commands

#### Phase 3.3: Confluence Subagent (Week 3)
**Deliverables**:
- Confluence Operations Subagent (`agents/confluence-operations.md`)
- All 9 Confluence operations
- Content-aware caching
- Error handling

**Tasks**:
1. Design Confluence operation contracts
2. Implement page/space operations
3. Add TTL-based caching
4. Migrate planning commands
5. Test CQL search functionality

#### Phase 3.4: Slack + BitBucket Subagents (Week 4)
**Deliverables**:
- Slack Operations Subagent (`agents/slack-operations.md`)
- BitBucket Operations Subagent (`agents/bitbucket-operations.md`)
- Complete multi-PM system

**Tasks**:
1. Implement Slack operations
2. Implement BitBucket operations
3. Test parallel orchestration
4. Migrate remaining commands
5. Complete documentation

#### Phase 3.5: Optimization & Rollout (Week 5)
**Deliverables**:
- Complete migration
- Performance benchmarks
- Documentation
- Migration guide

**Tasks**:
1. Optimize cache hit rates
2. Benchmark token savings
3. Complete command migration
4. Write migration guide
5. Monitor and tune

### 9.2 Backward Compatibility

**Zero Breaking Changes**:
- Direct MCP calls continue to work
- Commands can mix direct calls and subagents
- Gradual migration per command

**Migration Path**:
```markdown
# Command can use both patterns during migration

# Old pattern (still works)
Use Jira MCP to get issue TRAIN-123

# New pattern (optimized)
Task(jira-operations): `
operation: get_issue
params:
  issue_key: "TRAIN-123"
`
```

---

## 10. Success Metrics

### 10.1 Token Reduction Targets

| Metric | Target | Acceptable | Current |
|--------|--------|-----------|---------|
| Overall token reduction | 50-60% | 40-50% | 0% |
| Jira operations | 55-65% | 45-55% | 0% |
| Confluence operations | 50-60% | 40-50% | 0% |
| Slack operations | 45-55% | 35-45% | 0% |
| Cache hit rate | 85%+ | 75%+ | N/A |

### 10.2 Performance Targets

| Operation Type | Target | Acceptable | Red Flag |
|---------------|--------|-----------|----------|
| Cached metadata | <100ms | <150ms | >200ms |
| Uncached metadata | <500ms | <800ms | >1200ms |
| Content operations | <600ms | <1000ms | >1500ms |
| Batch operations (5 items) | <1000ms | <1500ms | >2500ms |
| Parallel execution speedup | 60%+ | 50%+ | <40% |

### 10.3 Quality Targets

| Metric | Target |
|--------|--------|
| Test coverage | >90% |
| Error handling coverage | 100% |
| Documentation completeness | 100% |
| Cache hit rate | 80-90% |
| API call reduction | 60-70% |

### 10.4 Milestones

| Milestone | Week | Deliverable |
|-----------|------|-------------|
| M1: Architecture approved | W1 D1 | This document |
| M2: Orchestrator implemented | W1 D5 | pm-orchestrator.md |
| M3: Jira subagent complete | W2 D5 | jira-operations.md |
| M4: Confluence subagent complete | W3 D5 | confluence-operations.md |
| M5: Slack/BitBucket complete | W4 D5 | All subagents |
| M6: Migration complete | W5 D5 | 100% migration |

---

## 11. Risk Assessment

### 11.1 Technical Risks

**Risk: Cache Complexity**
- **Impact**: Medium - Cross-PM cache coordination
- **Mitigation**: Isolated cache per system, clear boundaries

**Risk: Parallel Execution Bugs**
- **Impact**: High - Race conditions, dependency errors
- **Mitigation**: Comprehensive testing, dependency graph validation

**Risk: Performance Degradation**
- **Impact**: Medium - Orchestrator overhead
- **Mitigation**: Benchmarking, optimization, lazy loading

### 11.2 Migration Risks

**Risk: Large Scope**
- **Impact**: High - Multiple subagents, many commands
- **Mitigation**: Phased rollout, high-traffic first

**Risk: API Breaking Changes**
- **Impact**: Medium - External PM APIs change
- **Mitigation**: Version detection, graceful degradation

### 11.3 Operational Risks

**Risk: Cache Staleness**
- **Impact**: Low - Users see outdated data
- **Mitigation**: TTL for dynamic data, manual refresh

**Risk: Rate Limiting**
- **Impact**: Medium - External APIs rate limit
- **Mitigation**: Caching reduces calls, backoff strategy

---

## 12. Next Steps

### 12.1 Immediate Actions (Day 1)

1. **Review and approve this architecture**
2. **Create PM orchestrator scaffold**
3. **Set up testing framework**
4. **Begin Jira subagent design**

### 12.2 Week 1 Deliverables

1. PM orchestrator implementation
2. Unified cache architecture
3. Dependency graph system
4. Progress reporting
5. Initial test suite

### 12.3 Success Criteria

- [ ] All 4 subagents implemented
- [ ] Token reduction: 50-60% across workflows
- [ ] Cache hit rate: 80-90%
- [ ] API call reduction: 60-70%
- [ ] Zero breaking changes
- [ ] Complete documentation
- [ ] Migration guide published

---

## Conclusion

The Multi-PM Subagent System extends the proven Linear subagent pattern to all external PM systems, achieving:

✅ **40-60% token reduction** for commands using external PM systems
✅ **80-90% cache hit rates** for metadata operations
✅ **60-70% API call reduction** through intelligent caching
✅ **Parallel execution** for independent operations
✅ **Lazy loading** for optimal token efficiency
✅ **Consistent patterns** across all PM systems
✅ **Zero breaking changes** with gradual migration

**Implementation timeline**: 5 weeks with phased rollout
**Risk level**: Medium - manageable with phased approach
**Expected ROI**: Significant - 60% token reduction across all workflows

This architecture is **ready for implementation** and will deliver transformative improvements to CCPM's efficiency and performance.

---

**Document Version**: 1.0
**Last Updated**: 2025-11-21
**Review Date**: 2025-12-05 (post-Phase 3.1 review)
