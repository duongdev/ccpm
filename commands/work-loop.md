---
description: Autonomous work loop - complete all checklist items iteratively (ralph-wiggum pattern)
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[issue-id] [--max-iterations N] [--resume]"
---

# /ccpm:work:loop - Autonomous Work Loop

Start an iterative loop that automatically works through all checklist items without manual intervention between items. Based on the ralph-wiggum pattern from claude-code.

## ⛔ ABSOLUTE RULE: MAIN AGENT = COORDINATOR ONLY

**The main agent MUST NOT implement code or run tests directly.**

| Main Agent Role | Subagent Role |
|-----------------|---------------|
| Track iterations | Implement code |
| Coordinate loop | Write tests |
| Update Linear | Run test suites |
| Detect completion | Debug issues |
| Handle blockers | Code review |

**Main agent ONLY does:**
1. Parse arguments and manage loop state
2. Fetch issue/checklist from Linear (via `ccpm:linear-operations`)
3. Coordinate which subagents to invoke for EACH checklist item
4. Track progress and update Linear
5. Detect completion or blockers
6. Output completion promise when ALL items done

**Main agent NEVER does:**
- Read source files (use `Explore` agent)
- Write/Edit any code files
- Run tests directly (use `ccpm:tdd-orchestrator`)
- Debug issues inline (use `ccpm:debugger`)

## Usage

```bash
# Start new loop (auto-detect issue from branch)
/ccpm:work:loop

# Start loop for specific issue
/ccpm:work:loop WORK-26

# With custom iteration limit
/ccpm:work:loop WORK-26 --max-iterations 50

# Resume paused loop (after blocker resolved)
/ccpm:work:loop --resume
```

## How It Works

1. **Setup**: Creates state file (`.claude/ccpm-work-loop.local.md`) with loop metadata
2. **First Iteration**: Fetches checklist, implements first uncompleted item
3. **Stop Hook**: When Claude tries to exit, hook intercepts and re-feeds prompt
4. **Continue**: Loop continues through all checklist items
5. **Completion**: Loop ends when completion promise output or max iterations reached

## Completion Signals

| Signal | Effect |
|--------|--------|
| `<promise>ALL_ITEMS_COMPLETE</promise>` | Loop ends successfully |
| `Status: Blocked` | Loop pauses for user input |
| Max iterations reached | Loop ends with warning |

## Differences from /ccpm:work

| Aspect | /ccpm:work | /ccpm:work:loop |
|--------|------------|-----------------|
| Control | Manual, interactive | Autonomous, unattended |
| Items | One at a time | All items in one session |
| Exit | Normal session end | Intercepted until complete |
| Best for | Complex tasks needing review | Well-defined checklist tasks |

## State File

Location: `.claude/ccpm-work-loop.local.md`

```yaml
---
issue_id: "WORK-26"
iteration: 1
max_iterations: 30
completion_promise: "ALL_ITEMS_COMPLETE"
started_at: "2026-01-12T10:00:00Z"
branch: "feature/work-26-auth"
---
```

## Implementation

### Step 1: Parse Arguments

```javascript
// Check for resume mode
if (args.includes('--resume')) {
  if (!fs.existsSync('.claude/ccpm-work-loop.local.md')) {
    return error('No active work loop to resume. Start with: /ccpm:work:loop ISSUE-ID');
  }
  // Read existing state and continue
  const state = parseStateFile('.claude/ccpm-work-loop.local.md');
  issueId = state.issue_id;
  console.log(`Resuming work loop for ${issueId} (iteration ${state.iteration})`);
}

// Parse issue ID and options
let issueId = args[0];
let maxIterations = 30;

const maxIterIdx = args.indexOf('--max-iterations');
if (maxIterIdx !== -1 && args[maxIterIdx + 1]) {
  maxIterations = parseInt(args[maxIterIdx + 1]);
}

// Auto-detect from branch if not provided
if (!issueId) {
  const branch = await Bash('git rev-parse --abbrev-ref HEAD');
  const match = branch.match(/([A-Z]+-\d+)/);
  if (match) {
    issueId = match[1];
    console.log(`Detected issue from branch: ${issueId}`);
  }
}

if (!issueId) {
  return error('Issue ID required. Usage: /ccpm:work:loop ISSUE-ID');
}
```

### Step 2: Initialize Loop

```bash
# Run setup script to create state file
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-work-loop.sh" ${issueId} --max-iterations ${maxIterations}
```

### Step 3: Fetch Issue and Checklist

**Use Task tool to fetch issue:**

```
Task(subagent_type="ccpm:linear-operations"): `
operation: get_issue
params:
  issueId: "${issueId}"
context:
  cache: true
  command: "work-loop"
`
```

**Parse checklist from issue description:**

```javascript
const checklistData = parseChecklist(issue.description);
if (!checklistData || checklistData.items.length === 0) {
  console.log('No checklist found. Consider running /ccpm:plan first.');
  // Remove state file since nothing to loop through
  await Bash('rm -f .claude/ccpm-work-loop.local.md');
  return;
}

console.log(`Checklist: ${checklistData.items.length} items`);
console.log(`Progress: ${checklistData.progress}%`);
```

### Step 4: Begin Implementation Loop (MANDATORY AGENT DELEGATION)

**For each uncompleted item, the main agent MUST:**

1. **Select appropriate agent** based on item content/keywords (see table below)
2. **Delegate implementation** via Task tool with full context
3. **Delegate testing** via `ccpm:tdd-orchestrator` if item involves code
4. **Sync to Linear** after item completion (via `ccpm:linear-operations`)
5. **Mark item complete** in checklist

**Agent Selection Table (MUST USE):**

| Item Keywords | Subagent | Purpose |
|---------------|----------|---------|
| component, UI, React, CSS, layout | `ccpm:frontend-developer` | Frontend implementation |
| API, endpoint, database, resolver | `ccpm:backend-architect` | Backend implementation |
| test, spec, coverage | `ccpm:tdd-orchestrator` | Write and run tests |
| bug, error, fix, broken | `ccpm:debugger` | Debug issues |
| review, quality | `ccpm:code-reviewer` | Code review |
| security, auth, vulnerability | `ccpm:security-auditor` | Security checks |
| (any code implementation) | → THEN `ccpm:tdd-orchestrator` | Run tests after impl |

```javascript
const incompleteItems = checklistData.items.filter(item => !item.checked);

if (incompleteItems.length === 0) {
  console.log('All checklist items already complete!');
  console.log('<promise>ALL_ITEMS_COMPLETE</promise>');
  return;
}

const currentItem = incompleteItems[0];
console.log(`Working on: ${currentItem.content}`);

// MANDATORY: Determine agent from item content using table above
const agent = determineAgent(currentItem.content);
// e.g., "frontend" keywords -> ccpm:frontend-developer
//       "api/backend" keywords -> ccpm:backend-architect
//       "test" keywords -> ccpm:tdd-orchestrator

// Delegate to agent
Task(subagent_type=agent): `
## Task
${currentItem.content}

## Task-Specific Context
${currentItem.metadata ? formatItemMetadata(currentItem.metadata) : ''}

## Issue Context
- Issue: ${issueId} - ${issue.title}
- Branch: ${currentBranch}
- Progress: ${checklistData.progress}%

## Quality Requirements
- Follow existing code patterns
- Use TypeScript strict mode if applicable
- Handle edge cases and errors
- NO placeholder code - implement fully

## Expected Output
1. Files modified (list)
2. Summary of changes
3. Any blockers encountered
`;

// STEP 4B: After implementation, run tests via tdd-orchestrator
console.log('Running tests via ccpm:tdd-orchestrator...');
Task(subagent_type="ccpm:tdd-orchestrator"): `
## Task
Run tests for the changes just implemented.

## Context
- Issue: ${issueId}
- Item just completed: ${currentItem.content}
- Files likely modified by previous agent

## Requirements
1. Run relevant test suites (unit, integration)
2. If tests fail, attempt to fix them
3. Report final test status

## Expected Output
1. Test results (pass/fail counts)
2. Any fixes applied
3. Blockers if tests cannot be fixed
`;

// STEP 4C: After tests pass, sync to Linear
Task(subagent_type="ccpm:linear-operations"): `
operation: update_checklist_items
params:
  issueId: "${issueId}"
  indices: [${currentItem.index}]
  mark_complete: true
context:
  command: "work-loop"
`;

console.log(`Item ${currentItem.index + 1} complete (implementation + tests)`);
```

### Step 5: Check Completion

After each iteration, check if all items are done:

```javascript
// Re-fetch checklist to verify progress
const updatedIssue = await getIssue(issueId);
const updatedChecklist = parseChecklist(updatedIssue.description);

if (updatedChecklist.progress === 100) {
  console.log('All checklist items complete!');
  console.log('<promise>ALL_ITEMS_COMPLETE</promise>');
  // Stop hook will detect this and allow exit
} else {
  console.log(`Progress: ${updatedChecklist.progress}%`);
  console.log(`Remaining: ${updatedChecklist.items.filter(i => !i.checked).length} items`);
  // Stop hook will intercept exit and continue loop
}
```

## Stop Hook Behavior

The Stop hook (`hooks/scripts/work-loop-stop-hook.sh`) runs when Claude tries to exit:

1. **No state file** → Allow normal exit
2. **Completion promise in transcript** → Clean up state, allow exit
3. **Blocker signal in transcript** → Preserve state, allow exit (pause)
4. **Max iterations reached** → Clean up state, allow exit
5. **None of above** → Block exit, re-feed continuation prompt

## Error Handling

### No Checklist Found

```
No checklist found in issue description.

Consider running /ccpm:plan first to create a checklist.
```

### Issue Not Found

```
Error fetching issue: Issue not found

Suggestions:
  - Verify the issue ID is correct
  - Check you have access to this Linear team
```

### Max Iterations Reached

```
Work loop: Max iterations (30) reached

Progress: 70% (7/10 items complete)
Remaining items:
  - Item 8: Add unit tests
  - Item 9: Update documentation
  - Item 10: Final review

Resume with: /ccpm:work:loop --resume
Or continue manually: /ccpm:work
```

## Examples

### Example 1: Start Fresh Loop

```bash
/ccpm:work:loop WORK-26

# Output:
# Starting work loop for WORK-26
#   Max iterations: 30
#   Branch: feature/work-26-auth
#
# Checklist: 5 items (0% complete)
#
# Working on: Create auth endpoints
# [Agent implements...]
# Item 1 complete
#
# Working on: Add JWT validation
# [Agent implements...]
# Item 2 complete
#
# ... continues automatically ...
#
# All checklist items complete!
# <promise>ALL_ITEMS_COMPLETE</promise>
```

### Example 2: Resume After Blocker

```bash
# Previous run hit a blocker
# Status: Blocked - Need database credentials

# After resolving blocker:
/ccpm:work:loop --resume

# Output:
# Resuming work loop for WORK-26 (iteration 4)
#
# Working on: Configure database connection
# [Agent implements...]
# Item 4 complete
#
# ... continues ...
```

### Example 3: Custom Iteration Limit

```bash
/ccpm:work:loop WORK-26 --max-iterations 10

# Stops after 10 iterations regardless of progress
```

## Best Practices

1. **Use for well-defined tasks**: Works best when checklist items are clear and actionable
2. **Set reasonable max-iterations**: Default 30 is good for most tasks
3. **Review before commit**: Loop syncs to Linear but doesn't auto-commit
4. **Handle blockers promptly**: Resume loop after resolving blockers
5. **Use /ccpm:work for complex tasks**: Interactive mode better for tasks needing judgment

## Related Commands

- `/ccpm:work` - Interactive single-item work
- `/ccpm:cancel-work-loop` - Cancel active loop
- `/ccpm:sync` - Manual progress sync
- `/ccpm:verify` - Quality checks before completion
