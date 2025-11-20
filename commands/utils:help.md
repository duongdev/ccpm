---
description: Context-aware PM commands help and suggestions
allowed-tools: [LinearMCP, Read, AskUserQuestion]
argument-hint: [issue-id]
---

# PM Commands Help

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

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

/ccpm:spec:create <type> "<title>" [parent-id]
  Create Epic/Feature with Linear Document
  Types: epic, feature
  Example: /ccpm:spec:create epic "User Auth System"

/ccpm:spec:write <doc-id> <section>
  AI-assisted spec writing
  Sections: requirements, architecture, api-design, data-model, testing, security, user-flow, timeline, all
  Example: /ccpm:spec:write DOC-123 requirements

/ccpm:spec:review <doc-id>
  Validate spec completeness & quality (A-F grade)
  Example: /ccpm:spec:review DOC-123

/ccpm:spec:break-down <epic-or-feature-id>
  Epic → Features or Feature → Tasks
  Example: /ccpm:spec:break-down WORK-100

/ccpm:spec:migrate <project-path> [category]
  Migrate .claude/ markdown specs to Linear
  Categories: docs, plans, enhancements, tasks, all
  Example: /ccpm:spec:migrate ~/personal/personal-project

/ccpm:spec:sync <doc-id-or-issue-id>
  Sync spec with implementation (detect drift)
  Example: /ccpm:spec:sync WORK-123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 📝 Planning

/ccpm:planning:create "<title>" <project> [jira-id]
  Create + plan Linear issue in one step
  Projects: my-app, my-project, personal-project
  Example: /ccpm:planning:create "Add JWT auth" personal-project

/ccpm:planning:plan <linear-issue-id> [jira-id]
  Populate existing issue with research
  Example: /ccpm:planning:plan WORK-123 TRAIN-456

/ccpm:planning:quick-plan "<description>" <project>
  Quick planning (no Jira)
  Example: /ccpm:planning:quick-plan "Add dark mode" personal-project

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔨 Implementation

/ccpm:implementation:start <linear-issue-id>
  Start with agent coordination
  Example: /ccpm:implementation:start WORK-123

/ccpm:implementation:next <linear-issue-id>
  Smart next action detection
  Example: /ccpm:implementation:next WORK-123

/ccpm:implementation:update <id> <idx> <status> "<msg>"
  Update subtask status
  Statuses: completed, in-progress, blocked
  Example: /ccpm:implementation:update WORK-123 0 completed "Done"

/ccpm:implementation:sync <linear-issue-id> [summary]
  Sync progress, findings & code changes to Linear
  Auto-detects git changes, prompts for notes
  Example: /ccpm:implementation:sync WORK-123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ✅ Verification

/ccpm:verification:check <linear-issue-id>
  Run quality checks (IDE, linting, tests)
  Example: /ccpm:verification:check WORK-123

/ccpm:verification:verify <linear-issue-id>
  Final verification with verification-agent
  Example: /ccpm:verification:verify WORK-123

/ccpm:verification:fix <linear-issue-id>
  Fix verification failures
  Example: /ccpm:verification:fix WORK-123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🎉 Completion

/ccpm:complete:finalize <linear-issue-id>
  Post-completion (PR + Jira sync + Slack)
  Example: /ccpm:complete:finalize WORK-123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🛠️ Utilities

/ccpm:utils:status <linear-issue-id>
  Show detailed task status
  Example: /ccpm:utils:status WORK-123

/ccpm:utils:context <linear-issue-id>
  Fast task context loading
  Example: /ccpm:utils:context WORK-123

/ccpm:utils:report <project>
  Project-wide progress report
  Example: /ccpm:utils:report personal-project

/ccpm:utils:insights <linear-issue-id>
  AI complexity & risk analysis
  Example: /ccpm:utils:insights WORK-123

/ccpm:utils:auto-assign <linear-issue-id>
  AI-powered agent assignment
  Example: /ccpm:utils:auto-assign WORK-123

/ccpm:utils:sync-status <linear-issue-id>
  Sync Linear → Jira (with confirmation)
  Example: /ccpm:utils:sync-status WORK-123

/ccpm:utils:rollback <linear-issue-id>
  Rollback planning changes
  Example: /ccpm:utils:rollback WORK-123

/ccpm:utils:dependencies <linear-issue-id>
  Visualize task dependencies
  Example: /ccpm:utils:dependencies WORK-123

/ccpm:utils:agents
  List available subagents
  Example: /ccpm:utils:agents

/ccpm:utils:help [issue-id]
  This help (context-aware)
  Example: /ccpm:utils:help WORK-123

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
        command: `/ccpm:spec:create feature "${context.title}" [epic-id]`,
        reason: 'Create spec document for better planning',
        priority: 'high'
      })
    }

    if (context.hasSpec) {
      suggestions.push({
        command: `/ccpm:spec:write ${context.specDocId} all`,
        reason: 'Write comprehensive spec sections',
        priority: 'high'
      })

      suggestions.push({
        command: `/ccpm:spec:review ${context.specDocId}`,
        reason: 'Validate spec before implementation',
        priority: 'medium'
      })
    }

    if (context.type === 'epic' && context.hasSpec) {
      suggestions.push({
        command: `/ccpm:spec:break-down ${context.issueId}`,
        reason: 'Break epic into features',
        priority: 'high'
      })
    }

    if (context.type === 'feature' && context.hasSpec) {
      suggestions.push({
        command: `/ccpm:spec:break-down ${context.issueId}`,
        reason: 'Break feature into tasks',
        priority: 'high'
      })
    }

    if (!context.hasSpec) {
      suggestions.push({
        command: `/ccpm:implementation:start ${context.issueId}`,
        reason: 'Start implementation (task-first approach)',
        priority: 'medium'
      })

      suggestions.push({
        command: `/ccpm:utils:insights ${context.issueId}`,
        reason: 'Get AI analysis before starting',
        priority: 'low'
      })
    }
  }

  if (context.status === 'In Progress') {
    suggestions.push({
      command: `/ccpm:implementation:next ${context.issueId}`,
      reason: 'Find optimal next action',
      priority: 'high'
    })

    suggestions.push({
      command: `/ccpm:implementation:sync ${context.issueId}`,
      reason: 'Save current progress and findings',
      priority: 'medium'
    })

    if (context.progress.percentage >= 100) {
      suggestions.push({
        command: `/ccpm:verification:check ${context.issueId}`,
        reason: 'All subtasks complete - run quality checks',
        priority: 'high'
      })
    }

    if (context.hasSpec) {
      suggestions.push({
        command: `/ccpm:spec:sync ${context.issueId}`,
        reason: 'Check if implementation matches spec',
        priority: 'medium'
      })
    }
  }

  if (context.status === 'Verification') {
    suggestions.push({
      command: `/ccpm:verification:verify ${context.issueId}`,
      reason: 'Run final verification',
      priority: 'high'
    })
  }

  if (context.labels.includes('blocked')) {
    suggestions.push({
      command: `/ccpm:verification:fix ${context.issueId}`,
      reason: 'Fix blocking issues',
      priority: 'high'
    })

    suggestions.push({
      command: `/ccpm:utils:status ${context.issueId}`,
      reason: 'Review current status and blockers',
      priority: 'high'
    })
  }

  if (context.status === 'Done') {
    suggestions.push({
      command: `/ccpm:complete:finalize ${context.issueId}`,
      reason: 'Finalize with PR creation and notifications',
      priority: 'high'
    })

    if (context.hasSpec) {
      suggestions.push({
        command: `/ccpm:spec:sync ${context.issueId}`,
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
1. /ccpm:spec:create → Create Epic/Feature
2. /ccpm:spec:write → Write spec sections
3. /ccpm:spec:review → Validate spec
4. /ccpm:spec:break-down → Generate tasks
5. /ccpm:implementation:start → Begin work
6. /ccpm:spec:sync → Keep in sync

**Task-First Workflow (Quick):**
1. /ccpm:planning:create → Create + plan
2. /ccpm:implementation:start → Begin work
3. /ccpm:verification:check → Quality checks
4. /ccpm:verification:verify → Final review
5. /ccpm:complete:finalize → Wrap up

**Daily Commands:**
- /ccpm:utils:report <project> - Morning overview
- /ccpm:utils:context <id> - Resume work
- /ccpm:implementation:next <id> - What's next?
- /ccpm:implementation:sync <id> - Save progress

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
        label: suggestions[0].command.split(' ')[0].replace('/ccpm:', ''),
        description: suggestions[0].reason
      },
      {
        label: "View Full Status",
        description: "See detailed status (/ccpm:utils:status)"
      },
      {
        label: "Load Context",
        description: "Load full task context (/ccpm:utils:context)"
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
        description: "Start with spec-first approach (/ccpm:spec:create)"
      },
      {
        label: "Create New Task",
        description: "Quick task-first approach (/ccpm:planning:create)"
      },
      {
        label: "Migrate Existing Specs",
        description: "Import markdown specs to Linear (/ccpm:spec:migrate)"
      },
      {
        label: "View Project Report",
        description: "See project overview (/ccpm:utils:report)"
      },
      {
        label: "List Agents",
        description: "See available subagents (/ccpm:utils:agents)"
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
   ~`$CCPM_COMMANDS_DIR/`README.md

⚠️  Safety Rules:
   ~`$CCPM_COMMANDS_DIR/SAFETY_RULES.md`

🔍 Command Details:
   Each command has detailed docs in:
   ~/.claude/commands/pm/<category>/<command>.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Examples

### Example 1: General Help

```bash
/ccpm:utils:help
```

Shows:
- All commands categorized
- Workflow quick reference
- Getting started options

### Example 2: Context-Aware Help

```bash
/ccpm:utils:help WORK-123
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
/ccpm:utils:help WORK-123
```

If WORK-123 is "In Progress" (3/5 subtasks done):

Shows:
- Progress: 60% complete
- **Suggested**: Continue with next task (/ccpm:implementation:next)
- **Suggested**: Sync spec if exists
- All commands
- Quick action menu

## Notes

- Context-aware suggestions based on issue status
- Interactive quick actions for common workflows
- Categorized command reference
- Workflow guidance for new users
- Always accessible via `/ccpm:utils:help` or `/ccpm:help`
