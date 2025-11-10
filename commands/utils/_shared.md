# Shared Utilities for PM Commands

This file contains reusable patterns for interactive mode and status suggestions.
Include these patterns in all PM commands.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

---

## Interactive Mode Pattern

After completing the main action, ALWAYS:

1. **Show Current Status**
2. **Suggest Next Actions**
3. **Ask User for Choice**

### Template

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [Command Name] Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Current Status: [status from Linear]
🎯 Progress: [X of Y] subtasks complete ([percentage]%)
🏷️  Labels: [labels]
⏱️  Time in status: [duration]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Suggested Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Based on current status, show 2-4 options]

1. [Primary suggested action]
2. [Alternative action]
3. [Status check]
4. [Other relevant action]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then use **AskUserQuestion** tool to prompt for next action.

---

## Status-Based Suggestions

### Status: Backlog

**Suggest:**

1. Start planning: `/pm:planning:plan [issue-id] [jira-id]`
2. Quick plan (no Jira): `/pm:planning:quick-plan "[description]" [project]`
3. View status: `/pm:utils:status [issue-id]`

### Status: Planning

**Suggest:**

1. Start implementation: `/pm:implementation:start [issue-id]`
2. Review planning: `/pm:utils:status [issue-id]`
3. Get insights: `/pm:utils:insights [issue-id]`
4. Auto-assign agents: `/pm:utils:auto-assign [issue-id]`

### Status: In Progress

**Check subtask progress:**

- If < 50% complete → Suggest: Continue working, `/pm:implementation:next [issue-id]`
- If ≥ 50% complete → Suggest: Run quality checks, `/pm:verification:check [issue-id]`
- If all complete → Suggest: Run quality checks immediately

**Suggest:**

1. Update progress: `/pm:implementation:update [issue-id] [idx] [status] "[msg]"`
2. Next action: `/pm:implementation:next [issue-id]`
3. Check status: `/pm:utils:status [issue-id]`
4. Quality checks (if ready): `/pm:verification:check [issue-id]`

### Status: Verification

**Suggest:**

1. Run verification: `/pm:verification:verify [issue-id]`
2. Check quality: `/pm:verification:check [issue-id]`
3. View status: `/pm:utils:status [issue-id]`

### Status: Blocked

**Suggest:**

1. Fix issues: `/pm:verification:fix [issue-id]`
2. View status: `/pm:utils:status [issue-id]`
3. Rollback: `/pm:utils:rollback [issue-id]`

### Status: Done

**Suggest:**

1. Finalize: `/pm:complete:finalize [issue-id]`
2. Create new task: `/pm:planning:create "[title]" [project]`
3. View report: `/pm:utils:report [project]`

---

## Progress Calculation

```javascript
const progress = {
  total: checklistItems.length,
  completed: checklistItems.filter(item => item.checked).length,
  percentage: Math.round((completed / total) * 100),
  inProgress: checklistItems.filter(item => item.status === 'in_progress').length,
  blocked: checklistItems.filter(item => item.status === 'blocked').length
}
```

---

## Time in Status Calculation

```javascript
const timeInStatus = {
  statusUpdatedAt: issue.updatedAt, // from Linear
  now: new Date(),
  duration: calculateDuration(statusUpdatedAt, now),
  // Returns: "2 hours", "3 days", "1 week"
}
```

---

## Next Action Detection Logic

```javascript
function detectNextAction(issue) {
  // If planning status
  if (issue.status === 'Planning') {
    if (hasChecklist && checklistComplete) {
      return 'start-implementation'
    }
    return 'review-planning'
  }

  // If in progress
  if (issue.status === 'In Progress') {
    const incompleteTasks = getIncompleteTasks(issue)
    if (incompleteTasks.length === 0) {
      return 'run-quality-checks'
    }

    const nextTask = getNextReadyTask(issue) // Check dependencies
    if (nextTask) {
      return `work-on-task-${nextTask.index}`
    }

    return 'update-progress'
  }

  // If verification
  if (issue.status === 'Verification') {
    return 'run-verification'
  }

  // If blocked
  if (issue.labels.includes('blocked')) {
    return 'fix-issues'
  }

  // If done
  if (issue.status === 'Done') {
    return 'finalize'
  }

  return 'check-status'
}
```

---

## Interactive Choice Format

Use **AskUserQuestion** with these patterns:

### After Planning

```javascript
{
  questions: [{
    question: "Planning complete! What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "Start Implementation",
        description: "Begin working on the implementation with agent coordination"
      },
      {
        label: "Review Planning",
        description: "Review the planning details and checklist"
      },
      {
        label: "Get Insights",
        description: "Get AI-powered insights on complexity and risks"
      },
      {
        label: "Just Status",
        description: "Just show me the current status, I'll decide later"
      }
    ]
  }]
}
```

### After Implementation Start

```javascript
{
  questions: [{
    question: "Implementation started! Which subtask should we work on first?",
    header: "Choose Task",
    multiSelect: false,
    options: [
      {
        label: "Auto-select (AI)",
        description: "Let AI choose the optimal next task based on dependencies"
      },
      {
        label: "Subtask 1",
        description: "[Description of subtask 1]"
      },
      {
        label: "Subtask 2",
        description: "[Description of subtask 2]"
      },
      {
        label: "View All",
        description: "Show all subtasks and their status"
      }
    ]
  }]
}
```

### After Quality Checks Pass

```javascript
{
  questions: [{
    question: "All quality checks passed! Ready for final verification?",
    header: "Verification",
    multiSelect: false,
    options: [
      {
        label: "Run Verification",
        description: "Run comprehensive verification with verification-agent"
      },
      {
        label: "Review Changes",
        description: "Review all changes before verification"
      },
      {
        label: "Additional Tests",
        description: "Run additional manual tests first"
      },
      {
        label: "Later",
        description: "I'll run verification later"
      }
    ]
  }]
}
```

### After Verification Passes

```javascript
{
  questions: [{
    question: "Verification passed! 🎉 Ready to finalize this task?",
    header: "Finalize",
    multiSelect: false,
    options: [
      {
        label: "Finalize Task",
        description: "Mark as done, sync with Jira, and clean up"
      },
      {
        label: "Create PR",
        description: "Create a pull request with generated description"
      },
      {
        label: "Review Summary",
        description: "Review completion summary before finalizing"
      },
      {
        label: "Keep Open",
        description: "Keep the task open for now"
      }
    ]
  }]
}
```

---

## Command Output Footer Template

Always end commands with:

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:        /pm:utils:status [issue-id]
Next Action:   /pm:implementation:next [issue-id]
Context:       /pm:utils:context [issue-id]
Report:        /pm:utils:report [project]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Usage in Commands

Every PM command should:

1. **Do its main work**
2. **Fetch current Linear status**
3. **Show status summary** (using template above)
4. **Detect next action** (using logic above)
5. **Suggest actions** (2-4 options)
6. **Ask user** (using AskUserQuestion)
7. **Execute chosen action** OR exit gracefully

---

## Example Integration

```markdown
## After Main Command Completes

### Step N: Show Status & Suggest Next Action

Use **Linear MCP** to get current status of issue.

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Planning Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Current Status: Planning
🎯 Progress: 0 of 5 subtasks complete (0%)
🏷️  Labels: planning, research-complete
⏱️  Time in status: 5 minutes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Suggested Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use **AskUserQuestion** to prompt:

[Question options here...]

Based on user choice, execute the next command.
```

This creates a continuous, interactive flow!
