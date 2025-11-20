---
description: Load task context quickly - fetch issue, related files, and set up environment
allowed-tools: [Bash, LinearMCP, Read, Glob]
argument-hint: <linear-issue-id>
---

# Loading Context for: $1

Quickly loading all context for Linear issue **$1** to help you resume work.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Workflow

### Step 1: Fetch Linear Issue Details

Use **Linear MCP** to get full issue details:

1. Title, description, status, labels
2. Full checklist with progress
3. All comments and activity
4. Related issues (parent, sub-issues)
5. Assignee, dates, project info

### Step 2: Extract Context from Description

Parse the description to extract:

**Files Mentioned**:

- Look for code file paths (e.g., `src/api/auth.ts`, `components/Login.tsx`)
- Look for file patterns (e.g., `*.test.ts`, `api/**/*.js`)
- Extract all file references from implementation plan

**Related Links**:

- Jira tickets (extract URLs)
- Confluence pages (extract URLs)
- Slack threads (extract URLs)
- BitBucket PRs (extract URLs)
- Linear issues (extract issue IDs)

**Key Sections**:

- Current architecture
- Implementation approach
- Technical constraints
- Best practices
- Cross-repository dependencies

### Step 3: Load Relevant Files

Use **Glob** and **Read** tools to:

1. Find all mentioned files in the codebase
2. Read key files (limited to first 100 lines each)
3. Display file summaries

```
📂 Relevant Files Found:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. src/api/auth.ts (145 lines)
   Purpose: [Inferred from description or filename]
   Status: [To be modified/new file/reference only]

2. src/components/Login.tsx (89 lines)
   Purpose: [Inferred from description]
   Status: [To be modified]

3. src/middleware/jwt.ts (67 lines)
   Purpose: [Inferred from description]
   Status: [To be created]

[... up to 10 most relevant files ...]
```

### Step 4: Analyze Current Progress

Calculate and display progress:

```javascript
const progress = {
  total: checklistItems.length,
  completed: checklistItems.filter(i => i.checked).length,
  inProgress: checklistItems.filter(i => i.status === 'in_progress').length,
  blocked: checklistItems.filter(i => i.status === 'blocked').length,
  remaining: checklistItems.filter(i => !i.checked).length,
  percentage: Math.round((completed / total) * 100)
}
```

### Step 5: Display Complete Context

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Context Loaded: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏷️  Title: [Full title]
📊 Status: [Current status]
🎯 Progress: [X/Y] subtasks ([%]%)
⏱️  Time in status: [Duration]
🏷️  Labels: [Comma-separated labels]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[First paragraph from Context section of description]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Checklist Progress
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Completed ([X]):
✅ Subtask 1: [Description]
✅ Subtask 2: [Description]

In Progress ([Y]):
⏳ Subtask 3: [Description]

Remaining ([Z]):
⬜ Subtask 4: [Description]
⬜ Subtask 5: [Description]

Blocked ([N]):
🚫 Subtask 6: [Description] - [Blocker reason]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📂 Files to Work On
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[List from Step 3 above]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 Related Links
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Jira: [TRAIN-123](link)
Confluence: [PRD](link), [Design Doc](link)
Slack: [Discussion](link)
PRs: [PR #789](link)
Related Issues: [WORK-456](link)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Implementation Approach
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Extracted from Implementation Plan section]

Key Points:
- [Point 1]
- [Point 2]
- [Point 3]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Important Considerations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Technical Constraints:
- [Constraint 1]
- [Constraint 2]

Best Practices:
- [Practice 1]
- [Practice 2]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬 Recent Activity
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Last 3 comments with timestamps and authors]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 6: Interactive Next Actions

**READ**: `/Users/duongdev/.claude/commands/pm/utils/_shared.md`

Determine next action based on status and progress:

```javascript
// If status is Planning
if (status === 'Planning') {
  suggestOptions = [
    "Start Implementation",
    "Get AI Insights",
    "Auto-Assign Agents",
    "Just Review"
  ]
}

// If status is In Progress
if (status === 'In Progress') {
  if (hasIncompleteTask) {
    suggestOptions = [
      "Continue Next Task",
      "Update Progress",
      "Check Quality (if ready)",
      "Just Review"
    ]
  } else {
    suggestOptions = [
      "Run Quality Checks",
      "Update Last Task",
      "Just Review"
    ]
  }
}

// If status is Verification
if (status === 'Verification') {
  suggestOptions = [
    "Run Verification",
    "Check Quality First",
    "Just Review"
  ]
}

// If blocked
if (labels.includes('blocked')) {
  suggestOptions = [
    "Fix Issues",
    "View Status",
    "Rollback Changes",
    "Just Review"
  ]
}

// If done
if (status === 'Done') {
  suggestOptions = [
    "Finalize Task",
    "Create New Task",
    "Just Review"
  ]
}
```

Use **AskUserQuestion** tool with detected options.

**Execute based on choice** or show quick commands and exit.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:        /ccpm:utils:status $1
Next:          /ccpm:implementation:next $1
Start:         /ccpm:implementation:start $1
Update:        /ccpm:implementation:update $1 <idx> <status> "msg"
Check:         /ccpm:verification:check $1
Verify:        /ccpm:verification:verify $1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

### When to Use

- **Starting your work day** - Quick recap of what you're working on
- **Switching between tasks** - Fast context switch
- **After a break** - Remember where you left off
- **Code review** - Understand the full context quickly
- **Onboarding** - Get up to speed on a task

### What It Does

✅ Fetches full Linear issue
✅ Extracts all relevant files
✅ Shows progress at a glance
✅ Provides related links
✅ Displays key implementation points
✅ Shows recent activity
✅ Suggests next actions

### Usage

```bash
# Load context for any task
/ccpm:utils:context WORK-123

# Quick resume after break
/ccpm:utils:context WORK-123

# Switch to different task
/ccpm:utils:context WORK-456
```

### Benefits

- ⚡ **Fast** - No manual searching
- 🎯 **Focused** - Only relevant information
- 🔄 **Resumable** - Easy to pick up where you left off
- 📋 **Complete** - All context in one view
- 🤖 **Interactive** - Suggests what to do next
