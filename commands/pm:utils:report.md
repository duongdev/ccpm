---
description: Show progress report across all tasks in a project
allowed-tools: [LinearMCP]
argument-hint: <project>
---

# Progress Report for Project: $1

Generating comprehensive progress report for **$1** project.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Project Context

**Project Mapping**:

- **trainer-guru** → Linear Team: "Work", Project: "Trainer Guru"
- **repeat** → Linear Team: "Work", Project: "Repeat"
- **nv-internal** → Linear Team: "Personal", Project: "NV Internal"

## Workflow

### Step 1: Fetch All Issues for Project

Use **Linear MCP** to:

1. List all issues for the project ($1)
2. Include: Backlog, Planning, In Progress, Verification, Done (recent)
3. Exclude: Canceled, archived (unless requested)
4. Get full details: status, labels, assignee, checklist progress, dates

### Step 2: Categorize and Analyze

Group issues by status:

```javascript
const categories = {
  backlog: issues.filter(i => i.status === 'Backlog'),
  planning: issues.filter(i => i.status === 'Planning'),
  inProgress: issues.filter(i => i.status === 'In Progress'),
  verification: issues.filter(i => i.status === 'Verification'),
  blocked: issues.filter(i => i.labels.includes('blocked')),
  done: issues.filter(i => i.status === 'Done' && withinLast7Days(i))
}
```

Calculate statistics:

```javascript
const stats = {
  total: issues.length,
  byStatus: Object.keys(categories).map(k => ({
    status: k,
    count: categories[k].length,
    percentage: (categories[k].length / issues.length * 100).toFixed(1)
  })),
  avgCompletionTime: calculateAvgTime(categories.done),
  totalSubtasks: sumAllSubtasks(issues),
  completedSubtasks: sumCompletedSubtasks(issues),
  blockedCount: categories.blocked.length
}
```

### Step 3: Display Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Progress Report: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 Report Date: [Current Date]
🏢 Project: $1
📈 Total Issues: [N]
✅ Overall Progress: [X]% ([Y] of [Z] subtasks complete)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Status Breakdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Backlog:        [N] issues ([%]%)
📝 Planning:       [N] issues ([%]%)
⏳ In Progress:    [N] issues ([%]%)
🔍 Verification:   [N] issues ([%]%)
🚫 Blocked:        [N] issues ([%]%) ⚠️
✅ Done (7d):      [N] issues ([%]%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Blocked Issues (Needs Attention!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[If blocked issues exist, list them:]

1. [WORK-123]: [Title]
   Status: [Status]
   Blocked: [Duration]
   Action: /pm:verification:fix WORK-123

2. [WORK-124]: [Title]
   Status: [Status]
   Blocked: [Duration]
   Action: /pm:verification:fix WORK-124

[Or if none:]
✅ No blocked issues!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏃 In Progress Issues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[For each in-progress issue:]

1. [WORK-125]: [Title]
   Progress: [X/Y] subtasks ([%]%)
   Time in progress: [Duration]
   Next: /pm:implementation:next WORK-125

2. [WORK-126]: [Title]
   Progress: [X/Y] subtasks ([%]%)
   Time in progress: [Duration]
   Next: /pm:implementation:next WORK-126

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Planning Issues (Ready to Start)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[For each planning issue:]

1. [WORK-127]: [Title]
   Checklist: [N] subtasks
   Ready: /pm:implementation:start WORK-127

2. [WORK-128]: [Title]
   Checklist: [N] subtasks
   Ready: /pm:implementation:start WORK-128

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Verification Issues (Almost Done!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[For each verification issue:]

1. [WORK-129]: [Title]
   Time in verification: [Duration]
   Next: /pm:verification:verify WORK-129

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Recently Completed (Last 7 Days)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[For each done issue:]

1. [WORK-130]: [Title]
   Completed: [Date]
   Time to complete: [Duration]

2. [WORK-131]: [Title]
   Completed: [Date]
   Time to complete: [Duration]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📈 Insights
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚡ Velocity: [N] issues completed in last 7 days
⏱️  Avg Completion Time: [X] days
🎯 Focus: [Most common status - where work is concentrated]
🚨 Attention Needed: [Number] blocked, [Number] in verification too long

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Interactive Next Actions

**READ**: `/Users/duongdev/.claude/commands/pm/utils/_shared.md`

Use **AskUserQuestion** tool:

```javascript
{
  questions: [{
    question: "What would you like to do next?",
    header: "Next Action",
    multiSelect: false,
    options: [
      {
        label: "Work on Blocked Issues",
        description: `Fix ${blockedCount} blocked issues`
      },
      {
        label: "Continue In-Progress",
        description: `Work on ${inProgressCount} active tasks`
      },
      {
        label: "Start New Task",
        description: "Start one of the planning tasks"
      },
      {
        label: "Create New Issue",
        description: "Create and plan a new task (/pm:planning:create)"
      }
    ]
  }]
}
```

**Execute based on choice**:

- If "Work on Blocked Issues" → Show blocked issues and ask which to fix
- If "Continue In-Progress" → Show in-progress issues and ask which to work on
- If "Start New Task" → Show planning issues and ask which to start
- If "Create New Issue" → Prompt for title and run `/pm:planning:create`
- If "Other" → Show quick commands and exit

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Create Task:   /pm:planning:create "<title>" $1
View Task:     /pm:utils:status <issue-id>
Context:       /pm:utils:context <issue-id>
Refresh:       /pm:utils:report $1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

### Report Scope

- Shows all active work in the project
- Highlights blockers and issues needing attention
- Provides quick actions for each category
- Calculates velocity and insights

### Usage

```bash
# For external PM projects
/pm:utils:report trainer-guru
/pm:utils:report repeat

# For internal projects
/pm:utils:report nv-internal
```

### Refresh Frequency

- Run anytime to see current project state
- Especially useful at start of day
- Or when planning next work
- Or in team standups
