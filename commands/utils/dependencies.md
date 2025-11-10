---
description: Visualize subtask dependencies and execution order
allowed-tools: [LinearMCP]
argument-hint: <linear-issue-id>
---

# Dependencies for: $1

## Workflow

### Step 1: Parse Dependencies
Extract from checklist items:
- "depends on: X"
- "(after: X)"
- "(requires: X)"

### Step 2: Build Dependency Graph
```javascript
const graph = checklist.map((task, idx) => ({
  index: idx,
  description: task.description,
  dependencies: extractDependencies(task.description),
  dependents: findDependents(idx, checklist),
  status: task.checked ? 'complete' : 'pending',
  canStart: allDependenciesMet(idx, checklist)
}))
```

### Step 3: Visualize
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Dependency Graph for: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Legend: ✅ Complete | ⏳ Ready | ⏸️  Blocked | 📍 Current

[1] ✅ Database schema
      ↓
[2] ✅ API endpoints (depends on: 1)
      ↓
      ├→ [3] ⏳ Frontend (depends on: 2) [READY TO START]
      └→ [4] ⏳ Mobile (depends on: 2) [READY TO START]
             ↓
          [5] ⏸️  Tests (depends on: 3, 4) [BLOCKED]

Execution Order:
1. Task 1 (no dependencies)
2. Task 2 (after task 1)
3. Tasks 3 & 4 in parallel (after task 2)
4. Task 5 (after tasks 3 & 4)

Ready to Start: Tasks 3, 4
Blocked: Task 5 (waiting on: 3, 4)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Suggest Next Action
Show which task(s) are ready to start

## Notes
- ASCII graph visualization
- Shows ready vs blocked
- Identifies parallel opportunities
