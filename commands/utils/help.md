---
description: Context-aware PM commands help and suggestions
allowed-tools: [LinearMCP, Read, AskUserQuestion]
argument-hint: [issue-id]
---

# PM Commands Help

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass mode.

---

## Argument

- **$1** - (Optional) Linear issue ID for context-aware suggestions

## Workflow

### Step 1: Detect Context

If `$1` (issue ID) is provided:

```javascript
// Get issue details
const issue = await getLinearIssue($1)

// Detect context
const context = {
  type: detectIssueType(issue), // epic, feature, task
  status: issue.status, // Planning, In Progress, Verification, Done, Blocked
  hasSpec: hasLinkedSpecDoc(issue),
  hasSubtasks: issue.children && issue.children.length > 0,
  progress: calculateProgress(issue),
  labels: issue.labels
}
```

If no issue ID:

```javascript
// Show general help
const context = { type: 'general' }
```

### Step 2: Show Command Reference

Display categorized commands based on context:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 PM Commands Help ${$1 ? `- ${issue.title}` : ''}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${$1 ? `
📊 Current Context
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Issue: ${issue.identifier} - ${issue.title}
📋 Type: ${context.type}
📈 Status: ${context.status}
${context.hasSpec ? '📄 Spec Doc: Linked' : '⚠️  No spec document'}
${context.hasSubtasks ? `✅ Subtasks: ${context.progress.completed}/${context.progress.total} (${context.progress.percentage}%)` : ''}
🏷️  Labels: ${context.labels.join(', ')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
` : ''}

📋 Available Commands by Category
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 📐 Spec Management

/pm:spec:create <type> "<title>" [parent-id]
  Create Epic/Feature with Linear Document
  Types: epic, feature
  Example: /pm:spec:create epic "User Auth System"

/pm:spec:write <doc-id> <section>
  AI-assisted spec writing
  Sections: requirements, architecture, api-design, data-model, testing, security, user-flow, timeline, all
  Example: /pm:spec:write DOC-123 requirements

/pm:spec:review <doc-id>
  Validate spec completeness & quality (A-F grade)
  Example: /pm:spec:review DOC-123

/pm:spec:break-down <epic-or-feature-id>
  Epic → Features or Feature → Tasks
  Example: /pm:spec:break-down WORK-100

/pm:spec:migrate <project-path> [category]
  Migrate .claude/ markdown specs to Linear
  Categories: docs, plans, enhancements, tasks, all
  Example: /pm:spec:migrate ~/personal/nv-internal

/pm:spec:sync <doc-id-or-issue-id>
  Sync spec with implementation (detect drift)
  Example: /pm:spec:sync WORK-123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 📝 Planning

/pm:planning:create "<title>" <project> [jira-id]
  Create + plan Linear issue in one step
  Projects: trainer-guru, repeat, nv-internal
  Example: /pm:planning:create "Add JWT auth" nv-internal

/pm:planning:plan <linear-issue-id> [jira-id]
  Populate existing issue with research
  Example: /pm:planning:plan WORK-123 TRAIN-456

/pm:planning:quick-plan "<description>" <project>
  Quick planning (no Jira)
  Example: /pm:planning:quick-plan "Add dark mode" nv-internal

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔨 Implementation

/pm:implementation:start <linear-issue-id>
  Start with agent coordination
  Example: /pm:implementation:start WORK-123

/pm:implementation:next <linear-issue-id>
  Smart next action detection
  Example: /pm:implementation:next WORK-123

/pm:implementation:update <id> <idx> <status> "<msg>"
  Update subtask status
  Statuses: completed, in-progress, blocked
  Example: /pm:implementation:update WORK-123 0 completed "Done"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ✅ Verification

/pm:verification:check <linear-issue-id>
  Run quality checks (IDE, linting, tests)
  Example: /pm:verification:check WORK-123

/pm:verification:verify <linear-issue-id>
  Final verification with verification-agent
  Example: /pm:verification:verify WORK-123

/pm:verification:fix <linear-issue-id>
  Fix verification failures
  Example: /pm:verification:fix WORK-123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🎉 Completion

/pm:complete:finalize <linear-issue-id>
  Post-completion (PR + Jira sync + Slack)
  Example: /pm:complete:finalize WORK-123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🛠️ Utilities

/pm:utils:status <linear-issue-id>
  Show detailed task status
  Example: /pm:utils:status WORK-123

/pm:utils:context <linear-issue-id>
  Fast task context loading
  Example: /pm:utils:context WORK-123

/pm:utils:report <project>
  Project-wide progress report
  Example: /pm:utils:report nv-internal

/pm:utils:insights <linear-issue-id>
  AI complexity & risk analysis
  Example: /pm:utils:insights WORK-123

/pm:utils:auto-assign <linear-issue-id>
  AI-powered agent assignment
  Example: /pm:utils:auto-assign WORK-123

/pm:utils:sync-status <linear-issue-id>
  Sync Linear → Jira (with confirmation)
  Example: /pm:utils:sync-status WORK-123

/pm:utils:rollback <linear-issue-id>
  Rollback planning changes
  Example: /pm:utils:rollback WORK-123

/pm:utils:dependencies <linear-issue-id>
  Visualize task dependencies
  Example: /pm:utils:dependencies WORK-123

/pm:utils:agents
  List available subagents
  Example: /pm:utils:agents

/pm:utils:help [issue-id]
  This help (context-aware)
  Example: /pm:utils:help WORK-123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 3: Context-Aware Suggestions

If issue ID provided, suggest relevant commands based on status:

```javascript
function suggestCommands(context) {
  const suggestions = []

  // Status-based suggestions
  if (context.status === 'Planning') {
    if (!context.hasSpec && context.type === 'feature') {
      suggestions.push({
        command: `/pm:spec:create feature "${context.title}" [epic-id]`,
        reason: 'Create spec document for better planning',
        priority: 'high'
      })
    }

    if (context.hasSpec) {
      suggestions.push({
        command: `/pm:spec:write ${context.specDocId} all`,
        reason: 'Write comprehensive spec sections',
        priority: 'high'
      })

      suggestions.push({
        command: `/pm:spec:review ${context.specDocId}`,
        reason: 'Validate spec before implementation',
        priority: 'medium'
      })
    }

    if (context.type === 'epic' && context.hasSpec) {
      suggestions.push({
        command: `/pm:spec:break-down ${context.issueId}`,
        reason: 'Break epic into features',
        priority: 'high'
      })
    }

    if (context.type === 'feature' && context.hasSpec) {
      suggestions.push({
        command: `/pm:spec:break-down ${context.issueId}`,
        reason: 'Break feature into tasks',
        priority: 'high'
      })
    }

    if (!context.hasSpec) {
      suggestions.push({
        command: `/pm:implementation:start ${context.issueId}`,
        reason: 'Start implementation (task-first approach)',
        priority: 'medium'
      })

      suggestions.push({
        command: `/pm:utils:insights ${context.issueId}`,
        reason: 'Get AI analysis before starting',
        priority: 'low'
      })
    }
  }

  if (context.status === 'In Progress') {
    suggestions.push({
      command: `/pm:implementation:next ${context.issueId}`,
      reason: 'Find optimal next action',
      priority: 'high'
    })

    if (context.progress.percentage >= 100) {
      suggestions.push({
        command: `/pm:verification:check ${context.issueId}`,
        reason: 'All subtasks complete - run quality checks',
        priority: 'high'
      })
    }

    if (context.hasSpec) {
      suggestions.push({
        command: `/pm:spec:sync ${context.issueId}`,
        reason: 'Check if implementation matches spec',
        priority: 'medium'
      })
    }
  }

  if (context.status === 'Verification') {
    suggestions.push({
      command: `/pm:verification:verify ${context.issueId}`,
      reason: 'Run final verification',
      priority: 'high'
    })
  }

  if (context.labels.includes('blocked')) {
    suggestions.push({
      command: `/pm:verification:fix ${context.issueId}`,
      reason: 'Fix blocking issues',
      priority: 'high'
    })

    suggestions.push({
      command: `/pm:utils:status ${context.issueId}`,
      reason: 'Review current status and blockers',
      priority: 'high'
    })
  }

  if (context.status === 'Done') {
    suggestions.push({
      command: `/pm:complete:finalize ${context.issueId}`,
      reason: 'Finalize with PR creation and notifications',
      priority: 'high'
    })

    if (context.hasSpec) {
      suggestions.push({
        command: `/pm:spec:sync ${context.issueId}`,
        reason: 'Final spec sync to document changes',
        priority: 'medium'
      })
    }
  }

  return suggestions.sort((a, b) => {
    const priorityOrder = { high: 0, medium: 1, low: 2 }
    return priorityOrder[a.priority] - priorityOrder[b.priority]
  })
}
```

Display suggestions:

```
${$1 ? `
💡 Suggested Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Based on current status (${context.status}):

🔥 High Priority:
1. ${suggestions[0].command}
   → ${suggestions[0].reason}

2. ${suggestions[1].command}
   → ${suggestions[1].reason}

💡 Consider Also:
3. ${suggestions[2].command}
   → ${suggestions[2].reason}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
` : ''}
```

### Step 4: Workflow Quick Reference

```
📊 Workflow Quick Reference
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Spec-First Workflow (Recommended):**
1. /pm:spec:create → Create Epic/Feature
2. /pm:spec:write → Write spec sections
3. /pm:spec:review → Validate spec
4. /pm:spec:break-down → Generate tasks
5. /pm:implementation:start → Begin work
6. /pm:spec:sync → Keep in sync

**Task-First Workflow (Quick):**
1. /pm:planning:create → Create + plan
2. /pm:implementation:start → Begin work
3. /pm:verification:check → Quality checks
4. /pm:verification:verify → Final review
5. /pm:complete:finalize → Wrap up

**Daily Commands:**
- /pm:utils:report <project> - Morning overview
- /pm:utils:context <id> - Resume work
- /pm:implementation:next <id> - What's next?

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5: Interactive Actions

If issue ID provided, offer quick actions:

```javascript
{
  questions: [{
    question: "What would you like to do?",
    header: "Quick Action",
    multiSelect: false,
    options: [
      // Dynamically show top 3-4 suggestions
      {
        label: suggestions[0].command.split(' ')[0].replace('/pm:', ''),
        description: suggestions[0].reason
      },
      {
        label: "View Full Status",
        description: "See detailed status (/pm:utils:status)"
      },
      {
        label: "Load Context",
        description: "Load full task context (/pm:utils:context)"
      },
      {
        label: "Just Show Help",
        description: "I just wanted the command reference"
      }
    ]
  }]
}
```

If no issue ID:

```javascript
{
  questions: [{
    question: "What would you like to do?",
    header: "Getting Started",
    multiSelect: false,
    options: [
      {
        label: "Create New Epic/Feature",
        description: "Start with spec-first approach (/pm:spec:create)"
      },
      {
        label: "Create New Task",
        description: "Quick task-first approach (/pm:planning:create)"
      },
      {
        label: "Migrate Existing Specs",
        description: "Import markdown specs to Linear (/pm:spec:migrate)"
      },
      {
        label: "View Project Report",
        description: "See project overview (/pm:utils:report)"
      },
      {
        label: "List Agents",
        description: "See available subagents (/pm:utils:agents)"
      },
      {
        label: "Just Show Help",
        description: "I just wanted the command reference"
      }
    ]
  }]
}
```

### Step 6: Show Additional Resources

```
📚 Additional Resources
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📖 Full Documentation:
   ~/Users/duongdev/.claude/commands/pm/README.md

⚠️  Safety Rules:
   ~/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md

🔍 Command Details:
   Each command has detailed docs in:
   ~/.claude/commands/pm/<category>/<command>.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Examples

### Example 1: General Help

```bash
/pm:utils:help
```

Shows:
- All commands categorized
- Workflow quick reference
- Getting started options

### Example 2: Context-Aware Help

```bash
/pm:utils:help WORK-123
```

If WORK-123 is in "Planning" status with no spec:

Shows:
- Current status summary
- **Suggested**: Create spec document
- **Suggested**: Or start implementation directly
- **Suggested**: Get AI insights
- All commands (for reference)
- Quick action menu

### Example 3: Help During Implementation

```bash
/pm:utils:help WORK-123
```

If WORK-123 is "In Progress" (3/5 subtasks done):

Shows:
- Progress: 60% complete
- **Suggested**: Continue with next task (/pm:implementation:next)
- **Suggested**: Sync spec if exists
- All commands
- Quick action menu

## Notes

- Context-aware suggestions based on issue status
- Interactive quick actions for common workflows
- Categorized command reference
- Workflow guidance for new users
- Always accessible via `/pm:utils:help` or `/pm:help`
