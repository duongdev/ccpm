---
description: Smart work command - start or resume work on a task
allowed-tools: [Bash, LinearMCP]
argument-hint: "[issue-id]"
---

# Smart Work Command

You are executing the **smart work command** that automatically starts or resumes work based on task status.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

## Mode Detection

The command has **2 modes** with automatic detection:

### Mode 1: START - Begin Work
**When**: Task status is "Planning", "Backlog", or "Todo"
**Routes to**: `/ccpm:implementation:start`
**Action**: Load context, create assignment plan, begin implementation

### Mode 2: RESUME - Continue Work
**When**: Task status is "In Progress"
**Routes to**: `/ccpm:implementation:next`
**Action**: Show current progress, suggest next subtask, continue work

## Implementation

### Step 1: Determine Issue ID

```javascript
const args = process.argv.slice(2)
let issueId = args[0]

// If no issue ID provided, try to detect from context
if (!issueId) {
  // Try to get from git branch name
  const branch = execSync('git rev-parse --abbrev-ref HEAD', {encoding: 'utf-8'}).trim()

  // Pattern: username/PROJ-123-feature-name
  const branchMatch = branch.match(/([A-Z]+-\d+)/)
  if (branchMatch) {
    issueId = branchMatch[1]
    console.log(`🔍 Detected issue from branch: ${issueId}`)
  } else {
    console.error("❌ Error: Could not determine issue ID")
    console.log("")
    console.log("Please provide an issue ID:")
    console.log("  /ccpm:work WORK-123")
    console.log("")
    console.log("Or checkout a branch with an issue ID:")
    console.log("  git checkout -b username/WORK-123-feature-name")
    process.exit(1)
  }
}

// Validate issue ID format
const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/
if (!ISSUE_ID_PATTERN.test(issueId)) {
  console.error(`❌ Error: Invalid issue ID format: ${issueId}`)
  console.log("Expected format: PROJECT-NUMBER (e.g., PSN-27, WORK-123)")
  process.exit(1)
}
```

### Step 2: Fetch Task Status from Linear

Use **Linear MCP** to get issue details:

```javascript
const issue = await linear_get_issue(issueId)

if (!issue) {
  console.error(`❌ Error: Could not find issue: ${issueId}`)
  process.exit(1)
}

const status = issue.status
const title = issue.title
const progress = calculateProgress(issue.description)
```

### Step 3: Detect Mode and Display

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Smart Work Command
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId}
📝 Title: ${title}
📊 Status: ${status}
${progress ? `🎯 Progress: ${progress.completed}/${progress.total} subtasks (${progress.percent}%)` : ''}

${mode === 'start' ? `
Mode: START 🎬
─────────────
This task hasn't been started yet.

→ Routing to: /ccpm:implementation:start
→ Action: Load context, create assignment plan, begin implementation
` : ''}

${mode === 'resume' ? `
Mode: RESUME ⚡
───────────────
Work in progress on this task.

→ Routing to: /ccpm:implementation:next
→ Action: Show progress, suggest next subtask
` : ''}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Determine Mode

```javascript
const START_STATUSES = ['Planning', 'Backlog', 'Todo', 'Planned']
const IN_PROGRESS_STATUSES = ['In Progress', 'In Development', 'Doing', 'Started']

let mode

if (START_STATUSES.includes(status)) {
  mode = 'start'
  console.log("✅ Task not started - will begin implementation")
} else if (IN_PROGRESS_STATUSES.includes(status)) {
  mode = 'resume'
  console.log("✅ Task in progress - will suggest next action")
} else {
  // Status is Done, Verification, Cancelled, etc.
  console.log(`ℹ️  Task status is "${status}"`)

  if (status === 'Done' || status === 'Completed' || status === 'Cancelled') {
    console.error("❌ This task is already complete")
    console.log("")
    console.log("To work on a different task:")
    console.log("  /ccpm:work <issue-id>")
    process.exit(1)
  } else if (status === 'Verification' || status === 'Review') {
    console.log("ℹ️  Task is in verification phase")
    console.log("")
    console.log("Try these commands:")
    console.log("  /ccpm:verify ${issueId}     # Run quality checks")
    console.log("  /ccpm:done ${issueId}       # Finalize task")
    process.exit(0)
  } else {
    // Unknown status, default to resume mode
    mode = 'resume'
    console.log(`⚠️  Unknown status "${status}" - defaulting to resume mode`)
  }
}
```

### Step 5: Route to Appropriate Command

Use the `SlashCommand` tool to execute the underlying command:

```javascript
console.log("")
console.log("⚡ Executing...")
console.log("")

switch (mode) {
  case 'start':
    // Route to implementation:start
    console.log(`→ /ccpm:implementation:start ${issueId}`)
    SlashCommand(`/ccpm:implementation:start ${issueId}`)
    break

  case 'resume':
    // Route to implementation:next
    console.log(`→ /ccpm:implementation:next ${issueId}`)
    SlashCommand(`/ccpm:implementation:next ${issueId}`)
    break
}
```

## Helper Functions

### Calculate Progress

```javascript
function calculateProgress(description) {
  if (!description) return null

  // Extract checklist items
  const lines = description.split('\n')
  const checklistItems = lines.filter(line =>
    line.match(/^-\s*\[([ x])\]/)
  )

  if (checklistItems.length === 0) return null

  const total = checklistItems.length
  const completed = checklistItems.filter(line =>
    line.match(/^-\s*\[x\]/)
  ).length

  const percent = Math.round((completed / total) * 100)

  return { total, completed, percent }
}
```

## Examples

### Example 1: Start Work on New Task

```bash
/ccpm:work PSN-27
```

**Issue Status**: Planning
**Mode**: START
**Routes to**: `/ccpm:implementation:start PSN-27`
**Action**: Load context, list agents, create assignment plan

### Example 2: Resume Work on In-Progress Task

```bash
/ccpm:work PSN-27
```

**Issue Status**: In Progress
**Mode**: RESUME
**Routes to**: `/ccpm:implementation:next PSN-27`
**Action**: Show progress, suggest next ready subtask

### Example 3: Auto-Detect from Branch

```bash
git checkout -b duongdev/PSN-27-add-feature
/ccpm:work
```

**Detected**: PSN-27 from branch name
**Mode**: (determined by status)
**Routes to**: Appropriate command

### Example 4: Work on Completed Task (Error)

```bash
/ccpm:work PSN-26
```

**Issue Status**: Done
**Result**: Error message - task already complete
**Suggestion**: Use `/ccpm:work <other-issue-id>` for a different task

## Benefits

✅ **Automatic Detection**: No need to remember start vs. next
✅ **Smart Routing**: Routes based on actual task status
✅ **Context Aware**: Can detect issue from git branch
✅ **Clear Feedback**: Shows detected mode and action
✅ **Error Handling**: Guides users when task is complete or in wrong status

## Migration Hint

This command replaces:
- `/ccpm:implementation:start` → Use `/ccpm:work` (auto-detects)
- `/ccpm:implementation:next` → Use `/ccpm:work` (auto-detects)

The old commands still work and will show hints to use this command.
