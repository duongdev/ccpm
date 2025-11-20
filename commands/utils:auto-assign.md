---
description: AI-powered agent assignment based on subtask analysis
allowed-tools: [LinearMCP, Read]
argument-hint: <linear-issue-id>
---

# Auto-Assigning Agents for: $1

## Workflow

### Step 1: Fetch Checklist
- Get all subtasks from Linear

### Step 2: Analyze Each Subtask
For each subtask:
```javascript
const analysis = {
  keywords: extractKeywords(subtask.description),
  type: detectType(keywords), // backend, frontend, database, etc.
  suggestedAgent: mapTypeToAgent(type),
  dependencies: extractDependencies(subtask.description),
  canRunParallel: checkParallelPossibility(subtask, allSubtasks)
}
```

Agent mapping:
- API/endpoint keywords → backend-agent
- UI/component keywords → frontend-agent
- Database/schema keywords → database-agent
- Integration/3rd-party → integration-agent
- Testing keywords → verification-agent
- CI/CD/deploy keywords → devops-agent

### Step 3: Create Execution Plan
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 AI Agent Assignment Plan
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Sequential Groups:

Group 1 (Run First):
- Subtask 1: [desc] → database-agent
  Reason: Database schema must be created first

Group 2 (After Group 1):
- Subtask 2: [desc] → backend-agent
  Reason: Depends on database schema

Group 3 (Parallel, after Group 2):
- Subtask 3: [desc] → frontend-agent (parallel)
- Subtask 4: [desc] → mobile-agent (parallel)
  Reason: Both depend on API, can run simultaneously

Group 4 (After Group 3):
- Subtask 5: [desc] → verification-agent
  Reason: Final testing after all implementation

Estimated Time: [X] hours (sequential) vs [Y] hours (with parallelization)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Confirm Plan
Use **AskUserQuestion** to approve or modify plan

### Step 5: Add to Linear
- Add comment with assignment plan
- Update labels if needed
- Show next action (/ccpm:implementation:start)

## Notes
- Detects parallelization opportunities
- Respects dependencies automatically
- Suggests optimal execution order
