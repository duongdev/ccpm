---
description: Suggest smart next action based on task status, dependencies, and progress
allowed-tools: [LinearMCP]
argument-hint: <linear-issue-id>
---

# Next Action for: $1

Analyzing task **$1** to suggest the optimal next action.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to external PM systems without confirmation.

## Workflow

### Step 1: Fetch Task Details

Use **Linear MCP** to get:
- Full issue details, status, labels
- Complete checklist with all subtasks
- Progress information
- Any blockers or dependencies

### Step 2: Analyze Current State

```javascript
const state = {
  status: issue.status,
  progress: {
    total: checklist.length,
    completed: checklist.filter(i => i.checked).length,
    inProgress: checklist.filter(i => i.status === 'in_progress').length,
    blocked: checklist.filter(i => i.status === 'blocked').length
  },
  isBlocked: issue.labels.includes('blocked'),
  timeInStatus: calculateDuration(issue.statusUpdatedAt, now)
}
```

### Step 3: Determine Next Action

**Logic**:

```javascript
function determineNextAction(state) {
  // If blocked
  if (state.isBlocked) {
    return {
      action: 'fix-blockers',
      command: `/pm:verification:fix ${issueId}`,
      reason: 'Task is blocked. Fix issues before continuing.'
    }
  }

  // If status is Planning
  if (state.status === 'Planning') {
    return {
      action: 'start-implementation',
      command: `/pm:implementation:start ${issueId}`,
      reason: 'Planning complete. Ready to start implementation.'
    }
  }

  // If status is In Progress
  if (state.status === 'In Progress') {
    // All tasks complete
    if (state.progress.completed === state.progress.total) {
      return {
        action: 'quality-checks',
        command: `/pm:verification:check ${issueId}`,
        reason: 'All subtasks complete. Run quality checks.'
      }
    }

    // Check for next ready task (respecting dependencies)
    const nextTask = findNextReadyTask(checklist)
    if (nextTask) {
      return {
        action: 'work-on-subtask',
        subtask: nextTask,
        command: `Work on: ${nextTask.description}`,
        reason: `Next ready subtask (${nextTask.index + 1}/${state.progress.total})`
      }
    }

    // Has in-progress task
    if (state.progress.inProgress > 0) {
      return {
        action: 'continue-current',
        command: `/pm:utils:context ${issueId}`,
        reason: 'Continue working on in-progress subtask.'
      }
    }
  }

  // If status is Verification
  if (state.status === 'Verification') {
    return {
      action: 'run-verification',
      command: `/pm:verification:verify ${issueId}`,
      reason: 'Ready for final verification.'
    }
  }

  // If status is Done
  if (state.status === 'Done') {
    return {
      action: 'finalize',
      command: `/pm:complete:finalize ${issueId}`,
      reason: 'Task complete. Finalize and sync.'
    }
  }

  // Default
  return {
    action: 'check-status',
    command: `/pm:utils:status ${issueId}`,
    reason: 'Review current status to decide next step.'
  }
}
```

### Step 4: Check Dependencies

For "In Progress" tasks, check dependencies:

```markdown
Parse checklist items for dependency markers:
- "depends on: X" or "(depends: X)" or "(after: X)"
- Extract dependency index/description
- Check if dependency is complete
- Only suggest tasks with all dependencies met
```

###Step 5: Display Analysis

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Next Action for: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Current Status: [status]
🎯 Progress: [X/Y] subtasks ([%]%)
⏱️  Time in status: [duration]
🏷️  Labels: [labels]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Recommended Next Action
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Action: [action type]
Why: [reason]
Command: [suggested command]

[If subtask work recommended:]
📝 Next Subtask: [index]/[total]
Description: [subtask description]
Dependencies: [All met ✅ / Waiting on: X]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 6: Interactive Choice

**READ**: `/Users/duongdev/.claude/commands/pm/_shared.md`

Use **AskUserQuestion**:

```javascript
{
  questions: [{
    question: "Ready to proceed with the recommended action?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "Yes, Proceed",
        description: suggestedAction.reason
      },
      {
        label: "Show All Options",
        description: "See all available actions for this task"
      },
      {
        label: "Load Context First",
        description: "Load full task context before deciding"
      },
      {
        label: "Just Status",
        description: "Just show current status, I'll decide"
      }
    ]
  }]
}
```

**Execute based on choice**:
- "Yes, Proceed" → Execute suggested command
- "Show All Options" → Display all possible next actions with pros/cons
- "Load Context First" → Run `/pm:utils:context $1`
- "Just Status" → Run `/pm:utils:status $1`
- "Other" → Exit gracefully

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:        /pm:utils:status $1
Context:       /pm:utils:context $1
Update:        /pm:implementation:update $1 <idx> <status> "msg"
Report:        /pm:utils:report [project]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

### Smart Detection

- ✅ Respects task dependencies
- ✅ Detects blockers automatically
- ✅ Suggests quality checks when ready
- ✅ Identifies next ready subtask
- ✅ Considers time in status

### Usage

```bash
# Quick decision helper
/pm:implementation:next WORK-123

# After completing a subtask
/pm:implementation:next WORK-123

# When resuming work
/pm:implementation:next WORK-123
```

### Benefits

- ⚡ **Fast** - Instant recommendation
- 🎯 **Smart** - Considers all factors
- 📋 **Clear** - Explains reasoning
- 🤖 **Interactive** - One-click execution
- 🔄 **Context-aware** - Understands workflow
