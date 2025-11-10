---
description: Update subtask status and add work summary to Linear
allowed-tools: [LinearMCP]
argument-hint: <linear-issue-id> <subtask-index> <status> "<summary>"
---

# Updating Subtask for: $1

Subtask Index: $2
New Status: $3
Summary: $4

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (our internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Update Workflow

### Step 1: Fetch Current Issue

Use **Linear MCP** to get issue: $1

Read the current checklist and description.

### Step 2: Update Checklist Item

Update checklist item at index **$2** (0-based indexing):

**If status is "completed"**:
- Mark as checked: `- [x]`
- Append: ` ✅ $4`

**If status is "in-progress"**:
- Keep unchecked: `- [ ]`
- Append: ` ⏳ $4`

**If status is "blocked"**:
- Keep unchecked: `- [ ]`
- Append: ` 🚫 $4`
- **Also add "blocked" label** to the issue

### Step 3: Add Comment

Use **Linear MCP** to add this comment:

```markdown
## 📝 Subtask #$2 Update

**Status**: $3  
**Summary**: $4

**Timestamp**: [current date/time]
```

### Step 4: Confirm Update

Display confirmation:
```
✅ Subtask #$2 Updated!

Status: $3
Summary: $4

Updated in Linear issue: $1
```

## Status Options

- **completed**: Task done, mark as checked
- **in-progress**: Currently working on it
- **blocked**: Cannot proceed, needs resolution

## Examples

```bash
# Mark subtask complete
/update TRAIN-123 0 completed "Implemented JWT authentication with rate limiting"

# Update progress
/update TRAIN-123 1 in-progress "Working on frontend integration, 60% done"

# Mark as blocked
/update TRAIN-123 2 blocked "Waiting for backend API endpoint to be deployed"
```

## Notes

- Use 0-based indexing for subtask index (first item is 0)
- Always provide a clear summary of work done
- If blocked, explain what's blocking and what's needed
- Keep summaries concise but informative