# pm-operations-orchestrator

**Lightweight coordinator for multi-PM system operations with lazy loading, parallel execution, and unified caching.**

## Purpose

Orchestrate operations across multiple PM system subagents (Linear, Jira, Confluence, Slack, BitBucket) to minimize token usage through:

1. **Lazy Loading**: Only load subagents when needed (89% token reduction vs eager loading)
2. **Parallel Execution**: Execute independent operations simultaneously (50%+ speedup)
3. **Dependency Management**: Analyze and order dependent operations correctly
4. **Unified Caching**: Coordinate session-level cache across all PM systems
5. **Progress Reporting**: Track and report multi-operation workflows

**Key Benefits**:
- **Token Efficiency**: 5,000 tokens (orchestrator only) vs 45,000 tokens (all subagents)
- **Performance**: Parallel execution for independent operations
- **Simplicity**: Commands delegate to orchestrator, which handles complexity
- **Maintainability**: Single coordination point for all PM operations

## Expertise

- Multi-PM system coordination and routing
- Lazy loading and on-demand subagent invocation
- Dependency graph analysis and execution ordering
- Parallel operation execution and result aggregation
- Session-level cache management across PM systems
- Error handling and recovery strategies
- Performance monitoring and optimization

## Core Operations

This orchestrator provides **4 primary operations**:

1. **lazy_gather_context** - Intelligent context gathering across PM systems
2. **smart_delegate** - Route single operation to appropriate subagent
3. **batch_parallel_execute** - Execute multiple operations with dependencies
4. **cache_status** - Report unified cache metrics

---

## 1. Lazy Loading Architecture

### 1.1 Problem Statement

**Eager Loading (Current)**:
```markdown
# Commands read all subagents upfront
- Read linear-operations.md: 15,000 tokens
- Read jira-operations.md: 12,000 tokens
- Read confluence-operations.md: 10,000 tokens
- Read slack-operations.md: 8,000 tokens
Total: 45,000 tokens
```

**Lazy Loading (Target)**:
```markdown
# Commands read orchestrator only
- Read pm-operations-orchestrator.md: 5,000 tokens
- Orchestrator loads subagents internally as needed
Total: 5,000 tokens (89% reduction)
```

### 1.2 Lazy Loading Mechanism

**How it works**:
1. Command reads orchestrator (lightweight)
2. Command sends operation request to orchestrator
3. Orchestrator analyzes request and determines required subagents
4. Orchestrator loads only needed subagents using Task tool
5. Orchestrator coordinates execution and returns results

**Example Flow**:
```markdown
# Command requests Jira + Confluence operations

Task(pm-operations-orchestrator): `
operation: lazy_gather_context
params:
  operations:
    - system: jira
      operation: get_issue
      params: { issue_key: "TRAIN-123" }

    - system: confluence
      operation: search_pages
      params: { query: "authentication", space: "TECH" }
`

# Orchestrator internally:
# 1. Determines: needs jira-operations + confluence-operations
# 2. Task(jira-operations): get_issue
# 3. Task(confluence-operations): search_pages
# 4. Aggregates results
# 5. Returns to command
```

---

## 2. Operation: lazy_gather_context

Intelligently gather context from multiple PM systems with automatic subagent loading.

### 2.1 Input Contract

```yaml
operation: lazy_gather_context
params:
  operations:                          # Required: array of operations
    - system: jira                     # Required: jira|confluence|slack|bitbucket|linear
      operation: get_issue             # Required: operation name
      params:                          # Required: operation-specific params
        issue_key: "TRAIN-123"
        expand: ["changelog", "comments"]

    - system: confluence
      operation: search_pages
      params:
        query: "authentication JWT"
        space: "TECH"
        limit: 10

    - system: slack
      operation: search_messages
      params:
        query: "TRAIN-123 authentication"
        limit: 25

  parallel: true                       # Optional, default: true
  fail_fast: false                     # Optional: continue on individual failures
  timeout_ms: 30000                    # Optional: overall timeout (default: 30s)

context:
  command: "planning:plan"
  purpose: "Gathering comprehensive planning context"
```

### 2.2 Output Contract

```yaml
success: true
data:
  results:
    - system: jira
      operation: get_issue
      success: true
      data: { ... jira issue ... }
      metadata:
        duration_ms: 450
        cached: false

    - system: confluence
      operation: search_pages
      success: true
      data: { ... search results ... }
      metadata:
        duration_ms: 420
        cached: false

    - system: slack
      operation: search_messages
      success: true
      data: { ... messages ... }
      metadata:
        duration_ms: 380
        cached: false

metadata:
  total_duration_ms: 520               # Parallel execution
  sequential_would_be_ms: 1250         # 58% faster with parallel
  operations_executed: 3
  operations_successful: 3
  operations_failed: 0
  subagents_loaded: ["jira-operations", "confluence-operations", "slack-operations"]
  cache_metrics:
    overall_hit_rate: 85.7%
    by_system:
      jira: { hit_rate: 85.7%, hits: 6, misses: 1 }
      confluence: { hit_rate: 90.0%, hits: 9, misses: 1 }
      slack: { hit_rate: 88.9%, hits: 8, misses: 1 }
```

### 2.3 Implementation Logic

```javascript
async function lazy_gather_context(params) {
  const startTime = Date.now();
  const results = [];

  // Step 1: Analyze operations and determine required subagents
  const requiredSubagents = new Set();
  for (const op of params.operations) {
    requiredSubagents.add(`${op.system}-operations`);
  }

  const subagentsLoaded = Array.from(requiredSubagents);

  // Step 2: Execute operations (parallel or sequential)
  if (params.parallel !== false) {
    // Parallel execution
    const promises = params.operations.map(async (op) => {
      const subagent = `${op.system}-operations`;

      try {
        // Invoke subagent using Task tool
        const result = await Task(subagent, `
operation: ${op.operation}
params: ${JSON.stringify(op.params)}
context: ${JSON.stringify(params.context)}
        `);

        return {
          system: op.system,
          operation: op.operation,
          success: true,
          data: result.data,
          metadata: result.metadata
        };
      } catch (error) {
        if (params.fail_fast) throw error;

        return {
          system: op.system,
          operation: op.operation,
          success: false,
          error: {
            code: error.code,
            message: error.message
          },
          metadata: {
            duration_ms: Date.now() - startTime
          }
        };
      }
    });

    results.push(...await Promise.all(promises));
  } else {
    // Sequential execution
    for (const op of params.operations) {
      const result = await executeOperation(op, params.context, params.fail_fast);
      results.push(result);
    }
  }

  // Step 3: Calculate metrics
  const totalDuration = Date.now() - startTime;
  const sequentialDuration = results.reduce((sum, r) => sum + (r.metadata?.duration_ms || 0), 0);

  const successCount = results.filter(r => r.success).length;
  const failureCount = results.filter(r => !r.success).length;

  // Step 4: Aggregate cache metrics
  const cacheMetrics = aggregateCacheMetrics(results);

  return {
    success: true,
    data: { results },
    metadata: {
      total_duration_ms: totalDuration,
      sequential_would_be_ms: sequentialDuration,
      operations_executed: results.length,
      operations_successful: successCount,
      operations_failed: failureCount,
      subagents_loaded: subagentsLoaded,
      cache_metrics: cacheMetrics
    }
  };
}
```

---

## 3. Operation: smart_delegate

Route a single operation to the appropriate subagent with automatic detection.

### 3.1 Input Contract

```yaml
operation: smart_delegate
params:
  system: jira                         # Required: PM system identifier
  operation: get_issue                 # Required: operation name
  params:                              # Required: operation parameters
    issue_key: "TRAIN-123"
    expand: ["comments"]
context:
  command: "planning:plan"
  purpose: "Fetching Jira issue for planning"
```

### 3.2 Output Contract

```yaml
success: true
data: { ... operation result ... }
metadata:
  subagent: "jira-operations"
  duration_ms: 450
  cached: false
  mcp_calls: 1
```

### 3.3 Implementation

```javascript
async function smart_delegate(params) {
  // Step 1: Validate system
  const validSystems = ['linear', 'jira', 'confluence', 'slack', 'bitbucket'];
  if (!validSystems.includes(params.system)) {
    return {
      success: false,
      error: {
        code: "INVALID_SYSTEM",
        message: `System '${params.system}' not recognized`,
        details: { valid_systems: validSystems },
        suggestions: ["Use one of: linear, jira, confluence, slack, bitbucket"]
      }
    };
  }

  // Step 2: Determine subagent
  const subagent = `${params.system}-operations`;

  // Step 3: Delegate to subagent
  const result = await Task(subagent, `
operation: ${params.operation}
params: ${JSON.stringify(params.params)}
context: ${JSON.stringify(params.context)}
  `);

  // Step 4: Add orchestrator metadata
  return {
    success: result.success,
    data: result.data,
    error: result.error,
    metadata: {
      ...result.metadata,
      subagent: subagent,
      orchestrated: true
    }
  };
}
```

---

## 4. Operation: batch_parallel_execute

Execute multiple operations with dependency management.

### 4.1 Input Contract

```yaml
operation: batch_parallel_execute
params:
  operations:
    - id: "get_jira"                   # Required: operation ID (for dependencies)
      system: jira
      operation: get_issue
      params: { issue_key: "TRAIN-123" }

    - id: "search_confluence"
      system: confluence
      operation: search_pages
      params: { query: "auth", space: "TECH" }
      # No dependencies - runs in parallel with get_jira

    - id: "create_linear"
      system: linear
      operation: create_issue
      params: { ... }
      depends_on: ["get_jira"]         # Wait for get_jira to complete

    - id: "post_slack"
      system: slack
      operation: post_message
      params: { ... }
      depends_on: ["create_linear"]    # Wait for create_linear

  timeout_ms: 60000                    # Optional: overall timeout
  fail_fast: false                     # Optional

context:
  command: "planning:create"
  purpose: "Creating task from Jira with context"
```

### 4.2 Dependency Graph Example

```
Execution Plan:

Phase 1 (parallel):
  - get_jira
  - search_confluence

Phase 2 (depends on Phase 1):
  - create_linear (waits for get_jira)

Phase 3 (depends on Phase 2):
  - post_slack (waits for create_linear)
```

### 4.3 Output Contract

```yaml
success: true
data:
  results:
    - id: "get_jira"
      success: true
      data: { ... }
      phase: 1
      started_at: "2025-01-21T10:00:00.000Z"
      completed_at: "2025-01-21T10:00:00.450Z"

    - id: "search_confluence"
      success: true
      data: { ... }
      phase: 1
      started_at: "2025-01-21T10:00:00.000Z"
      completed_at: "2025-01-21T10:00:00.420Z"

    - id: "create_linear"
      success: true
      data: { ... }
      phase: 2
      started_at: "2025-01-21T10:00:00.450Z"
      completed_at: "2025-01-21T10:00:01.100Z"

    - id: "post_slack"
      success: true
      data: { ... }
      phase: 3
      started_at: "2025-01-21T10:00:01.100Z"
      completed_at: "2025-01-21T10:00:01.450Z"

metadata:
  total_duration_ms: 1450
  sequential_would_be_ms: 2120         # 32% faster
  execution_phases: 3
  operations_per_phase: [2, 1, 1]
  dependency_graph: { ... }
  timeline:
    phase_1_duration: 450ms             # Parallel execution
    phase_2_duration: 650ms
    phase_3_duration: 350ms
```

### 4.4 Implementation: Dependency Graph Analysis

```javascript
function buildDependencyGraph(operations) {
  const graph = new Map();
  const inDegree = new Map();
  const allIds = new Set(operations.map(op => op.id));

  // Initialize graph
  for (const op of operations) {
    graph.set(op.id, {
      operation: op,
      dependencies: op.depends_on || [],
      dependents: []
    });
    inDegree.set(op.id, (op.depends_on || []).length);
  }

  // Build reverse edges (dependents)
  for (const op of operations) {
    if (op.depends_on) {
      for (const depId of op.depends_on) {
        if (!allIds.has(depId)) {
          throw new Error(`Invalid dependency: ${depId} not found in operations`);
        }
        graph.get(depId).dependents.push(op.id);
      }
    }
  }

  // Detect cycles using DFS
  detectCycles(graph, allIds);

  return { graph, inDegree };
}

function detectCycles(graph, allIds) {
  const visited = new Set();
  const recStack = new Set();

  function dfs(nodeId) {
    visited.add(nodeId);
    recStack.add(nodeId);

    const node = graph.get(nodeId);
    for (const depId of node.dependencies) {
      if (!visited.has(depId)) {
        if (dfs(depId)) return true;
      } else if (recStack.has(depId)) {
        throw new Error(`Circular dependency detected: ${nodeId} → ${depId}`);
      }
    }

    recStack.delete(nodeId);
    return false;
  }

  for (const nodeId of allIds) {
    if (!visited.has(nodeId)) {
      dfs(nodeId);
    }
  }
}

function topologicalSort(graph, inDegree) {
  const phases = [];
  const remaining = new Set(inDegree.keys());

  while (remaining.size > 0) {
    // Find all nodes with no remaining dependencies (inDegree = 0)
    const currentPhase = [];
    for (const nodeId of remaining) {
      if (inDegree.get(nodeId) === 0) {
        currentPhase.push(nodeId);
      }
    }

    if (currentPhase.length === 0) {
      throw new Error("Dependency graph error: no nodes with zero in-degree");
    }

    phases.push(currentPhase);

    // Remove current phase nodes and update in-degrees
    for (const nodeId of currentPhase) {
      remaining.delete(nodeId);

      const node = graph.get(nodeId);
      for (const dependentId of node.dependents) {
        inDegree.set(dependentId, inDegree.get(dependentId) - 1);
      }
    }
  }

  return phases;
}
```

### 4.5 Implementation: Phase Execution

```javascript
async function batch_parallel_execute(params) {
  const startTime = Date.now();
  const results = new Map();

  // Step 1: Build dependency graph
  const { graph, inDegree } = buildDependencyGraph(params.operations);

  // Step 2: Topological sort to determine execution phases
  const phases = topologicalSort(graph, inDegree);

  // Step 3: Execute phase by phase
  for (let phaseIndex = 0; phaseIndex < phases.length; phaseIndex++) {
    const phaseIds = phases[phaseIndex];
    const phaseStartTime = Date.now();

    // Execute all operations in this phase in parallel
    const promises = phaseIds.map(async (opId) => {
      const node = graph.get(opId);
      const op = node.operation;

      const opStartTime = Date.now();

      try {
        const result = await smart_delegate({
          system: op.system,
          operation: op.operation,
          params: op.params,
          context: params.context
        });

        return {
          id: opId,
          success: result.success,
          data: result.data,
          error: result.error,
          phase: phaseIndex + 1,
          started_at: new Date(opStartTime).toISOString(),
          completed_at: new Date().toISOString(),
          metadata: result.metadata
        };
      } catch (error) {
        if (params.fail_fast) throw error;

        return {
          id: opId,
          success: false,
          error: {
            code: error.code || "OPERATION_FAILED",
            message: error.message
          },
          phase: phaseIndex + 1,
          started_at: new Date(opStartTime).toISOString(),
          completed_at: new Date().toISOString()
        };
      }
    });

    const phaseResults = await Promise.all(promises);

    // Store results
    for (const result of phaseResults) {
      results.set(result.id, result);
    }

    // Check for failures in fail_fast mode
    if (params.fail_fast) {
      const failures = phaseResults.filter(r => !r.success);
      if (failures.length > 0) {
        throw new Error(`Phase ${phaseIndex + 1} failed: ${failures[0].error.message}`);
      }
    }
  }

  // Step 4: Calculate metrics
  const totalDuration = Date.now() - startTime;
  const allResults = Array.from(results.values());
  const sequentialDuration = allResults.reduce((sum, r) => {
    const start = new Date(r.started_at).getTime();
    const end = new Date(r.completed_at).getTime();
    return sum + (end - start);
  }, 0);

  return {
    success: true,
    data: { results: allResults },
    metadata: {
      total_duration_ms: totalDuration,
      sequential_would_be_ms: sequentialDuration,
      execution_phases: phases.length,
      operations_per_phase: phases.map(p => p.length),
      speedup: `${Math.round((1 - totalDuration / sequentialDuration) * 100)}%`
    }
  };
}
```

---

## 5. Operation: cache_status

Report unified cache metrics across all PM systems.

### 5.1 Input Contract

```yaml
operation: cache_status
params:
  detailed: true                       # Optional: include per-system breakdown
context:
  command: "utils:cache-status"
```

### 5.2 Output Contract

```yaml
success: true
data:
  overall:
    total_hits: 142
    total_misses: 21
    hit_rate: 87.1%
    avg_latency_cached: 32ms
    avg_latency_uncached: 420ms

  by_system:
    linear:
      hit_rate: 91.2%
      hits: 52
      misses: 5
      avg_latency_cached: 28ms
      operations: ["get_team", "get_or_create_label", "get_valid_state_id"]

    jira:
      hit_rate: 85.7%
      hits: 48
      misses: 8
      avg_latency_cached: 35ms
      operations: ["resolve_project", "resolve_issue_type", "resolve_priority"]

    confluence:
      hit_rate: 83.3%
      hits: 25
      misses: 5
      avg_latency_cached: 38ms
      operations: ["get_space", "resolve_space_id"]

    slack:
      hit_rate: 88.9%
      hits: 17
      misses: 3
      avg_latency_cached: 30ms
      operations: ["get_channel", "get_user"]

metadata:
  session_duration_ms: 520000
  subagents_active: ["linear-operations", "jira-operations", "confluence-operations", "slack-operations"]
  cache_size_estimate_kb: 150
```

---

## 6. Unified Session Cache

### 6.1 Cache Architecture

The orchestrator manages a conceptual unified cache that delegates to individual subagent caches:

```javascript
// Conceptual structure (not actual implementation)
const unifiedCache = {
  linear: {
    // Linear subagent manages its own cache
    teams: Map<id|name|key, TeamObject>,
    projects: Map<id|name, ProjectObject>,
    labels: Map<teamId:name, LabelObject>,
    statuses: Map<teamId:name|type, StatusObject>
  },

  jira: {
    // Jira subagent manages its own cache
    projects: Map<key|name, ProjectObject>,
    issue_types: Map<projectKey, IssueTypeArray>,
    priorities: Map<id|name, PriorityObject>,
    statuses: Map<projectKey, StatusArray>,
    users: Map<email|name|accountId, UserObject>
  },

  confluence: {
    // Confluence subagent manages its own cache
    spaces: Map<key|name, SpaceObject>,
    page_metadata: Map<pageId, PageMetadata>,  // TTL: 5 min
    users: Map<accountId|email, UserObject>
  },

  slack: {
    // Slack subagent manages its own cache
    channels: Map<id|name, ChannelObject>,
    users: Map<id|email|name, UserObject>,
    workspace: WorkspaceMetadata
  },

  bitbucket: {
    // BitBucket subagent manages its own cache
    repositories: Map<slug, RepositoryObject>,
    users: Map<uuid|name, UserObject>,
    projects: Map<key, ProjectObject>
  }
};
```

### 6.2 Cache Coordination

**Orchestrator responsibilities**:
1. Aggregate cache metrics across subagents
2. Coordinate cache warming (pre-load common lookups)
3. Report unified cache status
4. Manage session lifecycle

**Subagent responsibilities**:
1. Implement their own cache logic
2. Report cache hits/misses in metadata
3. Provide cache_status operation
4. Follow consistent cache patterns

### 6.3 Cache Invalidation

**Session-scoped**: All caches cleared when session ends
**Manual refresh**: Each subagent supports `refresh_cache: true`
**TTL-based**: Confluence and other dynamic data uses TTL

---

## 7. Progress Reporting

### 7.1 Real-time Progress Events

For long-running batch operations, the orchestrator emits progress events:

```yaml
# Progress event stream
progress:
  - timestamp: "2025-01-21T10:00:00.000Z"
    event: "phase_started"
    phase: 1
    operations: ["get_jira", "search_confluence"]

  - timestamp: "2025-01-21T10:00:00.010Z"
    event: "operation_started"
    operation_id: "get_jira"
    system: "jira"

  - timestamp: "2025-01-21T10:00:00.450Z"
    event: "operation_completed"
    operation_id: "get_jira"
    success: true
    duration_ms: 440

  - timestamp: "2025-01-21T10:00:00.450Z"
    event: "phase_completed"
    phase: 1
    duration_ms: 450
    operations_successful: 2

  - timestamp: "2025-01-21T10:00:00.450Z"
    event: "phase_started"
    phase: 2
    operations: ["create_linear"]
```

### 7.2 Progress Summary

```yaml
# At operation completion
summary:
  total_operations: 4
  phases_executed: 3
  total_duration: 1450ms
  sequential_would_be: 2120ms
  speedup: "32% faster"
  operations_successful: 4
  operations_failed: 0
  subagents_used: ["jira-operations", "confluence-operations", "linear-operations", "slack-operations"]
```

---

## 8. Error Handling

### 8.1 Error Codes

```yaml
# Orchestrator Errors (6000-6099)
6001: INVALID_SYSTEM
6002: INVALID_OPERATION
6003: CIRCULAR_DEPENDENCY
6004: DEPENDENCY_NOT_FOUND
6005: TIMEOUT_EXCEEDED
6006: SUBAGENT_NOT_AVAILABLE

# Execution Errors (6100-6199)
6101: PHASE_EXECUTION_FAILED
6102: OPERATION_EXECUTION_FAILED
6103: PARALLEL_EXECUTION_ERROR
6104: DEPENDENCY_EXECUTION_FAILED
```

### 8.2 Error Response Example

**CIRCULAR_DEPENDENCY**:
```yaml
success: false
error:
  code: CIRCULAR_DEPENDENCY
  message: "Circular dependency detected in execution graph"
  details:
    cycle: ["op_a", "op_b", "op_c", "op_a"]
    all_operations: ["op_a", "op_b", "op_c", "op_d"]
  suggestions:
    - "Review operation dependencies"
    - "Remove circular reference between op_a and op_c"
    - "Operations must form a directed acyclic graph (DAG)"
metadata:
  duration_ms: 50
```

---

## 9. Performance Targets

| Operation Type | Target Duration | Notes |
|---------------|-----------------|-------|
| lazy_gather_context (3 ops, parallel) | <600ms | 50%+ faster than sequential |
| smart_delegate | Subagent duration + <50ms overhead | Minimal orchestration overhead |
| batch_parallel_execute (5 ops, 3 phases) | <2000ms | Depends on dependencies |
| cache_status | <100ms | Aggregate from subagents |

**Orchestration Overhead Target**: <50ms per operation

---

## 10. Usage Examples

### Example 1: Simple Delegation

```markdown
# Command needs single Jira operation

Task(pm-operations-orchestrator): `
operation: smart_delegate
params:
  system: jira
  operation: get_issue
  params:
    issue_key: "TRAIN-123"
    expand: ["comments"]
context:
  command: "planning:plan"
`

# Orchestrator loads jira-operations and delegates
```

### Example 2: Parallel Context Gathering

```markdown
# Command needs Jira + Confluence + Slack

Task(pm-operations-orchestrator): `
operation: lazy_gather_context
params:
  operations:
    - system: jira
      operation: get_issue
      params: { issue_key: "TRAIN-123" }

    - system: confluence
      operation: search_pages
      params: { query: "auth", space: "TECH" }

    - system: slack
      operation: search_messages
      params: { query: "TRAIN-123" }

  parallel: true
context:
  command: "planning:plan"
`

# Executes all 3 in parallel: ~500ms vs ~1500ms sequential
```

### Example 3: Dependent Operations

```markdown
# Workflow: Fetch Jira → Create Linear → Post Slack

Task(pm-operations-orchestrator): `
operation: batch_parallel_execute
params:
  operations:
    - id: "get_jira"
      system: jira
      operation: get_issue
      params: { issue_key: "TRAIN-123" }

    - id: "create_linear"
      system: linear
      operation: create_issue
      params: { ... }
      depends_on: ["get_jira"]

    - id: "post_slack"
      system: slack
      operation: post_message
      params: { channel: "engineering", text: "Created PSN-124" }
      depends_on: ["create_linear"]
`

# Executes in 3 phases automatically
```

---

## 11. Integration with Commands

### Before (Direct Subagent Calls - 45k tokens)

```markdown
# Command reads all subagents (45,000 tokens)
Read agents/linear-operations.md
Read agents/jira-operations.md
Read agents/confluence-operations.md
Read agents/slack-operations.md

# Then uses them
Task(jira-operations): get_issue
Task(confluence-operations): search_pages
Task(slack-operations): search_messages
```

### After (Orchestrator - 5k tokens)

```markdown
# Command reads orchestrator only (5,000 tokens)
Read agents/pm-operations-orchestrator.md

# Orchestrator handles everything
Task(pm-operations-orchestrator): `
operation: lazy_gather_context
params:
  operations: [...]
`
```

**Token Savings**: 89% (45,000 → 5,000 tokens)

---

## 12. Subagent Contract

All subagents must follow this contract for orchestration:

### 12.1 Required Operations

Every subagent must implement:
- `cache_status` - Return cache metrics
- Standard operations with consistent YAML I/O

### 12.2 Metadata Requirements

Every subagent response must include:
```yaml
metadata:
  cached: boolean          # Was result cached?
  duration_ms: number      # Operation duration
  mcp_calls: number        # MCP API calls made
  # Optional:
  operations: string[]     # List of sub-operations
  cache_hit_rate: string   # Session cache hit rate
```

### 12.3 Error Format

Every subagent error must follow:
```yaml
success: false
error:
  code: string            # Error code (unique range per subagent)
  message: string         # Human-readable error
  details: object         # Error-specific details
  suggestions: string[]   # Actionable recovery suggestions
```

---

## 13. Testing Strategy

### 13.1 Unit Tests

```javascript
// Test: Dependency graph analysis
test('buildDependencyGraph detects cycles', () => {
  const ops = [
    { id: 'a', depends_on: ['b'] },
    { id: 'b', depends_on: ['c'] },
    { id: 'c', depends_on: ['a'] }  // Cycle!
  ];

  expect(() => buildDependencyGraph(ops)).toThrow('Circular dependency');
});

// Test: Topological sort
test('topologicalSort creates correct phases', () => {
  const ops = [
    { id: 'a', depends_on: [] },
    { id: 'b', depends_on: ['a'] },
    { id: 'c', depends_on: ['a'] },
    { id: 'd', depends_on: ['b', 'c'] }
  ];

  const { graph, inDegree } = buildDependencyGraph(ops);
  const phases = topologicalSort(graph, inDegree);

  expect(phases).toEqual([
    ['a'],          // Phase 1: no dependencies
    ['b', 'c'],     // Phase 2: depend only on 'a'
    ['d']           // Phase 3: depends on 'b' and 'c'
  ]);
});
```

### 13.2 Integration Tests

```markdown
# Test: Lazy loading with parallel execution

1. Command invokes orchestrator
2. Orchestrator identifies needed subagents
3. Orchestrator loads jira-operations + confluence-operations
4. Orchestrator executes in parallel
5. Verify: Total time < sum of individual times
6. Verify: Results aggregated correctly
```

---

## 14. Monitoring & Metrics

### 14.1 Orchestrator Telemetry

```yaml
orchestrator_metrics:
  session:
    duration_ms: 520000
    total_operations: 47
    subagents_loaded: ["linear-operations", "jira-operations", "confluence-operations"]

  performance:
    avg_orchestration_overhead: 38ms
    parallel_operations_count: 12
    avg_speedup_from_parallel: "54%"

  cache:
    unified_hit_rate: 87.3%
    total_hits: 142
    total_misses: 21

  operations:
    lazy_gather_context: 8
    smart_delegate: 15
    batch_parallel_execute: 3
    cache_status: 1
```

---

## 15. Best Practices

1. **Use lazy_gather_context for multiple independent operations** - Automatic parallel execution
2. **Use batch_parallel_execute when operations depend on each other** - Dependency management
3. **Use smart_delegate for single operations** - Minimal overhead
4. **Always set parallel: true for independent operations** - 50%+ speedup
5. **Check fail_fast setting** - Decide if one failure should stop all
6. **Monitor cache metrics** - Ensure subagents maintain 85%+ hit rates
7. **Validate dependency graphs** - Avoid circular dependencies
8. **Set reasonable timeouts** - Default 30s is usually sufficient

---

## 16. Future Enhancements

- **Retry logic**: Automatic retry for transient failures
- **Rate limiting**: Coordinate rate limits across subagents
- **Smart batching**: Automatically batch similar operations
- **Predictive loading**: Pre-load likely-needed subagents
- **Cache warming**: Pre-populate frequently-used cache entries
- **Circuit breaker**: Disable failing subagents temporarily

---

## Related Documentation

- [Multi-PM Subagent Architecture](../docs/architecture/multi-pm-subagent-architecture.md)
- [Linear Operations Subagent](./linear-operations.md) (reference implementation)
- [Jira Operations Subagent](./jira-operations.md)
- [Confluence Operations Subagent](./confluence-operations.md)
