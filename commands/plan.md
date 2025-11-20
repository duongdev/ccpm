---
description: Smart planning command - create, plan, or update tasks
allowed-tools: [Bash, LinearMCP, AtlassianMCP, SlackMCP, PlaywrightMCP, Context7MCP]
argument-hint: "[title]" OR <issue-id> OR <issue-id> "[changes]"
---

# Smart Planning Command

You are executing the **smart planning command** that routes to the appropriate planning workflow based on context.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

## Mode Detection

The command has **3 modes** with clear, unambiguous detection:

### Mode 1: CREATE - New Task
**Syntax**: `plan "title" [project] [jira-ticket]`
**Detection**: First argument is a quoted string (not an issue ID pattern)
**Routes to**: `/ccpm:planning:create`

### Mode 2: PLAN - Plan Existing Task
**Syntax**: `plan WORK-123`
**Detection**: Single argument matching issue ID pattern (^[A-Z]+-\d+$)
**Routes to**: `/ccpm:planning:plan`

### Mode 3: UPDATE - Update Plan
**Syntax**: `plan WORK-123 "changes"`
**Detection**: Two arguments: issue ID + text
**Routes to**: `/ccpm:planning:update`

## Implementation

### Step 1: Parse Arguments and Detect Mode

```javascript
const args = process.argv.slice(2) // Get all arguments after command
const arg1 = args[0]
const arg2 = args[1]
const arg3 = args[2]

// Issue ID pattern: PROJECT-NUMBER (e.g., PSN-27, WORK-123)
const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/

const isIssueId = (str) => str && ISSUE_ID_PATTERN.test(str)

let mode, issueId, title, project, jiraTicket, updateText

if (!arg1) {
  console.error("❌ Error: Missing arguments")
  console.log("")
  console.log("Usage:")
  console.log("  /ccpm:plan \"Task title\" [project] [jira]  # Create new")
  console.log("  /ccpm:plan WORK-123                         # Plan existing")
  console.log("  /ccpm:plan WORK-123 \"changes\"              # Update plan")
  process.exit(1)
}

// Detect mode
if (isIssueId(arg1)) {
  // Starts with issue ID
  if (arg2) {
    // Has second argument = UPDATE mode
    mode = 'update'
    issueId = arg1
    updateText = arg2
  } else {
    // No second argument = PLAN mode
    mode = 'plan'
    issueId = arg1
  }
} else {
  // First arg is not issue ID = CREATE mode
  mode = 'create'
  title = arg1
  project = arg2 || '' // Optional
  jiraTicket = arg3 || '' // Optional
}
```

### Step 2: Display Detected Mode

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Smart Plan Command
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Detected Mode: ${mode.toUpperCase()}

${mode === 'create' ? `
📝 Creating new task...
   Title: ${title}
   ${project ? `Project: ${project}` : 'Project: (auto-detect)'}
   ${jiraTicket ? `Jira: ${jiraTicket}` : ''}

→ Routing to: /ccpm:planning:create
` : ''}

${mode === 'plan' ? `
🔍 Planning existing task...
   Issue: ${issueId}

→ Routing to: /ccpm:planning:plan
` : ''}

${mode === 'update' ? `
✏️  Updating plan...
   Issue: ${issueId}
   Changes: ${updateText}

→ Routing to: /ccpm:planning:update
` : ''}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 3: Route to Appropriate Command

Use the `SlashCommand` tool to execute the appropriate underlying command:

```javascript
switch (mode) {
  case 'create':
    // Route to planning:create
    // Command format: /ccpm:planning:create "title" [project] [jira-ticket]
    const createArgs = [title]
    if (project) createArgs.push(project)
    if (jiraTicket) createArgs.push(jiraTicket)

    console.log("⚡ Executing: /ccpm:planning:create")
    SlashCommand(`/ccpm:planning:create ${createArgs.map(a =>
      a.includes(' ') ? `"${a}"` : a
    ).join(' ')}`)
    break

  case 'plan':
    // Route to planning:plan
    // Command format: /ccpm:planning:plan <issue-id> [jira-ticket]
    console.log("⚡ Executing: /ccpm:planning:plan")
    SlashCommand(`/ccpm:planning:plan ${issueId}`)
    break

  case 'update':
    // Route to planning:update
    // Command format: /ccpm:planning:update <issue-id> "update-text"
    console.log("⚡ Executing: /ccpm:planning:update")
    SlashCommand(`/ccpm:planning:update ${issueId} "${updateText}"`)
    break
}
```

## Examples

### Example 1: Create New Task

```bash
/ccpm:plan "Add user authentication"
```

**Detection**: First arg is quoted text (not issue ID)
**Mode**: CREATE
**Routes to**: `/ccpm:planning:create "Add user authentication"`

### Example 2: Create with Project and Jira

```bash
/ccpm:plan "Add dark mode toggle" my-app TRAIN-456
```

**Detection**: First arg is quoted text
**Mode**: CREATE
**Routes to**: `/ccpm:planning:create "Add dark mode toggle" my-app TRAIN-456`

### Example 3: Plan Existing Task

```bash
/ccpm:plan PSN-27
```

**Detection**: Matches issue ID pattern (PSN-27), no second arg
**Mode**: PLAN
**Routes to**: `/ccpm:planning:plan PSN-27`

### Example 4: Update Existing Plan

```bash
/ccpm:plan PSN-27 "Add email notifications too"
```

**Detection**: Matches issue ID pattern, has second arg
**Mode**: UPDATE
**Routes to**: `/ccpm:planning:update PSN-27 "Add email notifications too"`

## Benefits

✅ **Simple Syntax**: One command for all planning scenarios
✅ **No Ambiguity**: Clear detection logic, no guessing
✅ **Natural Flow**: Matches how users think ("I want to plan")
✅ **Backward Compatible**: Old commands still work
✅ **Fast**: Direct routing, no extra overhead

## Migration Hint

This command replaces:
- `/ccpm:planning:create` → Use `/ccpm:plan "title"`
- `/ccpm:planning:plan` → Use `/ccpm:plan WORK-123`
- `/ccpm:planning:update` → Use `/ccpm:plan WORK-123 "changes"`

The old commands still work and will show hints to use this command.
