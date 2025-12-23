# Parallel Execution Helper

**Dependency-aware parallel task execution for CCPM workflows**

## Purpose

Enables running multiple tasks in parallel while respecting dependency relationships. Uses a directed acyclic graph (DAG) to determine execution order and maximize parallelization.

## Concepts

### Dependency Graph

```
┌─────────────────────────────────────────────────────┐
│                  Example Graph                       │
├─────────────────────────────────────────────────────┤
│                                                      │
│     ┌─────────┐                                     │
│     │ Task A  │ ─────┐                              │
│     └─────────┘      │                              │
│                      ▼                              │
│     ┌─────────┐  ┌─────────┐                        │
│     │ Task B  │  │ Task C  │ ─────┐                │
│     └─────────┘  └─────────┘      │                │
│          │            │           ▼                │
│          │            │      ┌─────────┐           │
│          └────────────┴─────▶│ Task D  │           │
│                              └─────────┘           │
│                                                      │
│  Execution: [A,B parallel] → [C] → [D]              │
└─────────────────────────────────────────────────────┘
```

### Execution Waves

Tasks are grouped into "waves" that can execute in parallel:

```yaml
wave_1: [A, B]      # No dependencies, run parallel
wave_2: [C]         # Depends on A
wave_3: [D]         # Depends on B and C
```

## Data Structures

### Task Definition

```typescript
interface Task {
  id: string;
  name: string;
  description: string;
  agent: string;  // Which agent handles this task
  dependencies: string[];  // Task IDs this depends on
  status: 'pending' | 'running' | 'completed' | 'failed' | 'skipped';
  result?: TaskResult;
}

interface TaskResult {
  success: boolean;
  output: string;
  filesModified: string[];
  duration: number;  // ms
  error?: string;
}
```

### Dependency Graph

```typescript
interface DependencyGraph {
  tasks: Map<string, Task>;
  edges: Map<string, string[]>;  // taskId -> dependsOn[]

  // Methods
  addTask(task: Task): void;
  addDependency(from: string, to: string): void;
  getExecutionWaves(): Task[][];
  detectCycles(): string[] | null;
}
```

## Implementation

### Building the Graph

```typescript
function buildDependencyGraph(tasks: Task[]): DependencyGraph {
  const graph: DependencyGraph = {
    tasks: new Map(),
    edges: new Map(),
  };

  // Add all tasks
  for (const task of tasks) {
    graph.tasks.set(task.id, task);
    graph.edges.set(task.id, task.dependencies || []);
  }

  // Validate - check for missing dependencies
  for (const [taskId, deps] of graph.edges) {
    for (const dep of deps) {
      if (!graph.tasks.has(dep)) {
        throw new Error(`Task ${taskId} depends on unknown task ${dep}`);
      }
    }
  }

  // Check for cycles
  const cycle = detectCycles(graph);
  if (cycle) {
    throw new Error(`Circular dependency detected: ${cycle.join(' → ')}`);
  }

  return graph;
}
```

### Cycle Detection (Kahn's Algorithm)

```typescript
function detectCycles(graph: DependencyGraph): string[] | null {
  const inDegree = new Map<string, number>();
  const queue: string[] = [];
  const result: string[] = [];

  // Calculate in-degrees
  for (const taskId of graph.tasks.keys()) {
    inDegree.set(taskId, 0);
  }
  for (const [taskId, deps] of graph.edges) {
    for (const dep of deps) {
      inDegree.set(dep, (inDegree.get(dep) || 0) + 1);
    }
  }

  // Find tasks with no dependencies
  for (const [taskId, degree] of inDegree) {
    if (degree === 0) {
      queue.push(taskId);
    }
  }

  // Process queue
  while (queue.length > 0) {
    const taskId = queue.shift()!;
    result.push(taskId);

    for (const dep of graph.edges.get(taskId) || []) {
      const newDegree = (inDegree.get(dep) || 0) - 1;
      inDegree.set(dep, newDegree);
      if (newDegree === 0) {
        queue.push(dep);
      }
    }
  }

  // If not all tasks processed, there's a cycle
  if (result.length !== graph.tasks.size) {
    const remaining = [...graph.tasks.keys()].filter(t => !result.includes(t));
    return remaining;
  }

  return null;
}
```

### Computing Execution Waves

```typescript
function getExecutionWaves(graph: DependencyGraph): Task[][] {
  const waves: Task[][] = [];
  const completed = new Set<string>();
  const remaining = new Set(graph.tasks.keys());

  while (remaining.size > 0) {
    const wave: Task[] = [];

    // Find all tasks whose dependencies are satisfied
    for (const taskId of remaining) {
      const deps = graph.edges.get(taskId) || [];
      const depsComplete = deps.every(d => completed.has(d));

      if (depsComplete) {
        wave.push(graph.tasks.get(taskId)!);
      }
    }

    if (wave.length === 0) {
      throw new Error('Unable to make progress - check for cycles');
    }

    // Move wave tasks from remaining to completed
    for (const task of wave) {
      remaining.delete(task.id);
      completed.add(task.id);
    }

    waves.push(wave);
  }

  return waves;
}
```

### Parallel Execution

```typescript
async function executeParallel(
  graph: DependencyGraph,
  executor: (task: Task) => Promise<TaskResult>,
  options: ExecutionOptions = {}
): Promise<ExecutionResult> {
  const waves = getExecutionWaves(graph);
  const results = new Map<string, TaskResult>();
  const startTime = Date.now();

  console.log(`\n📊 Execution Plan: ${waves.length} wave(s)`);
  waves.forEach((wave, i) => {
    console.log(`   Wave ${i + 1}: ${wave.map(t => t.name).join(', ')}`);
  });
  console.log('');

  for (let i = 0; i < waves.length; i++) {
    const wave = waves[i];
    console.log(`\n🌊 Wave ${i + 1}/${waves.length} (${wave.length} tasks)`);

    // Execute all tasks in this wave in parallel
    const wavePromises = wave.map(async (task) => {
      // Check if dependencies failed
      const deps = graph.edges.get(task.id) || [];
      const failedDeps = deps.filter(d => !results.get(d)?.success);

      if (failedDeps.length > 0 && options.stopOnFailure !== false) {
        task.status = 'skipped';
        console.log(`   ⏭️  ${task.name} (skipped - dependency failed)`);
        return {
          success: false,
          output: `Skipped due to failed dependencies: ${failedDeps.join(', ')}`,
          filesModified: [],
          duration: 0,
        };
      }

      task.status = 'running';
      console.log(`   🔄 ${task.name}...`);

      const taskStart = Date.now();
      try {
        const result = await executor(task);
        task.status = result.success ? 'completed' : 'failed';
        task.result = result;
        result.duration = Date.now() - taskStart;

        const icon = result.success ? '✅' : '❌';
        console.log(`   ${icon} ${task.name} (${result.duration}ms)`);

        return result;
      } catch (error) {
        const result: TaskResult = {
          success: false,
          output: '',
          filesModified: [],
          duration: Date.now() - taskStart,
          error: error.message,
        };
        task.status = 'failed';
        task.result = result;
        console.log(`   ❌ ${task.name} (error: ${error.message})`);
        return result;
      }
    });

    // Wait for all tasks in wave to complete
    const waveResults = await Promise.all(wavePromises);

    // Store results
    wave.forEach((task, idx) => {
      results.set(task.id, waveResults[idx]);
    });

    // Check for failures
    const failures = waveResults.filter(r => !r.success);
    if (failures.length > 0 && options.stopOnFailure !== false) {
      console.log(`\n⚠️  Wave ${i + 1} had ${failures.length} failure(s)`);

      if (i < waves.length - 1) {
        console.log(`   Remaining waves will be affected`);
      }
    }
  }

  const totalDuration = Date.now() - startTime;
  const successful = [...results.values()].filter(r => r.success).length;
  const failed = [...results.values()].filter(r => !r.success).length;

  console.log(`\n═══════════════════════════════════════`);
  console.log(`📊 Execution Complete`);
  console.log(`═══════════════════════════════════════`);
  console.log(`   Total: ${graph.tasks.size} tasks in ${waves.length} waves`);
  console.log(`   ✅ Successful: ${successful}`);
  console.log(`   ❌ Failed: ${failed}`);
  console.log(`   ⏱️  Duration: ${totalDuration}ms`);

  return {
    success: failed === 0,
    results,
    waves,
    duration: totalDuration,
  };
}
```

## Integration with CCPM

### Usage in /ccpm:work

```javascript
// When checklist has multiple independent items
const checklistItems = parseChecklist(issue.description);

// Build dependency graph from checklist
const graph = buildDependencyGraph(
  checklistItems.map((item, idx) => ({
    id: `task-${idx}`,
    name: item.content,
    description: item.content,
    agent: selectAgent(item.content),  // Match content to agent
    dependencies: item.dependencies || [],  // Parse from [depends: task-1] syntax
  }))
);

// Execute with parallel support
const result = await executeParallel(graph, async (task) => {
  return await Task({
    subagent_type: task.agent,
    prompt: buildTaskPrompt(task, issue),
  });
});
```

### Dependency Syntax in Checklists

```markdown
## Implementation Checklist

- [ ] Create database schema [id: db-schema]
- [ ] Create API endpoints [id: api, depends: db-schema]
- [ ] Create UI components [id: ui]
- [ ] Integrate API with UI [id: integration, depends: api, ui]
- [ ] Add tests [id: tests, depends: integration]
```

Parsed into:
```yaml
wave_1: [db-schema, ui]    # Independent
wave_2: [api]               # Depends on db-schema
wave_3: [integration]       # Depends on api, ui
wave_4: [tests]             # Depends on integration
```

### Visualization

```
📊 Execution Plan: 4 wave(s)
   Wave 1: Create database schema, Create UI components
   Wave 2: Create API endpoints
   Wave 3: Integrate API with UI
   Wave 4: Add tests

🌊 Wave 1/4 (2 tasks)
   🔄 Create database schema...
   🔄 Create UI components...
   ✅ Create database schema (1234ms)
   ✅ Create UI components (2345ms)

🌊 Wave 2/4 (1 task)
   🔄 Create API endpoints...
   ✅ Create API endpoints (3456ms)

🌊 Wave 3/4 (1 task)
   🔄 Integrate API with UI...
   ✅ Integrate API with UI (2345ms)

🌊 Wave 4/4 (1 task)
   🔄 Add tests...
   ✅ Add tests (4567ms)

═══════════════════════════════════════
📊 Execution Complete
═══════════════════════════════════════
   Total: 5 tasks in 4 waves
   ✅ Successful: 5
   ❌ Failed: 0
   ⏱️  Duration: 13947ms
```

## Configuration Options

```typescript
interface ExecutionOptions {
  // Stop execution if a task fails
  stopOnFailure?: boolean;  // default: true

  // Maximum concurrent tasks per wave
  maxConcurrency?: number;  // default: unlimited

  // Timeout per task (ms)
  taskTimeout?: number;  // default: 300000 (5 min)

  // Retry failed tasks
  retryCount?: number;  // default: 0
  retryDelay?: number;  // default: 1000ms

  // Progress callback
  onProgress?: (task: Task, status: string) => void;

  // Dry run (don't execute, just show plan)
  dryRun?: boolean;  // default: false
}
```

## Error Handling

```typescript
// Handle various failure scenarios

// 1. Dependency not found
try {
  const graph = buildDependencyGraph(tasks);
} catch (e) {
  if (e.message.includes('unknown task')) {
    console.log('Fix: Check task IDs in depends: syntax');
  }
}

// 2. Circular dependency
try {
  const graph = buildDependencyGraph(tasks);
} catch (e) {
  if (e.message.includes('Circular dependency')) {
    console.log('Fix: Remove circular reference');
  }
}

// 3. Task failure with cascade
const result = await executeParallel(graph, executor, {
  stopOnFailure: false,  // Continue other branches
});

// Check which tasks were skipped
for (const task of graph.tasks.values()) {
  if (task.status === 'skipped') {
    console.log(`${task.name} skipped due to failed dependency`);
  }
}
```

## Examples

### Example 1: Frontend + Backend in Parallel

```yaml
tasks:
  - id: frontend
    name: Build login UI
    agent: frontend-developer
    dependencies: []

  - id: backend
    name: Create auth API
    agent: backend-architect
    dependencies: []

  - id: integration
    name: Connect UI to API
    agent: frontend-developer
    dependencies: [frontend, backend]

  - id: tests
    name: Add E2E tests
    agent: tdd-orchestrator
    dependencies: [integration]

# Execution:
# Wave 1: [frontend, backend] - parallel
# Wave 2: [integration]
# Wave 3: [tests]
```

### Example 2: Database Migration Chain

```yaml
tasks:
  - id: schema
    name: Update Prisma schema
    agent: backend-architect
    dependencies: []

  - id: migration
    name: Run migration
    agent: backend-architect
    dependencies: [schema]

  - id: seed
    name: Seed test data
    agent: backend-architect
    dependencies: [migration]

  - id: api
    name: Update API resolvers
    agent: backend-architect
    dependencies: [migration]

# Execution:
# Wave 1: [schema]
# Wave 2: [migration]
# Wave 3: [seed, api] - parallel after migration
```

## Related Helpers

- `helpers/checklist.md` - Parse checklist with dependency syntax
- `helpers/agent-delegation.md` - Select agents for tasks
- `commands/work:parallel.md` - Command using this helper

---

**Version:** 1.0.0
**Last updated:** 2025-12-23
