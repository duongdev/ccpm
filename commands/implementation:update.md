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

### Step 0: Load Shared Helpers

READ: commands/_shared-linear-helpers.md

### Step 1: Fetch Current Issue

Use **Linear MCP** to get issue: $1

Read the current checklist and description.

### Step 2: Parse Checklist from Description

Look for the Implementation Checklist section in the description:

**Pattern 1: Marker Comments (Preferred)**
```markdown
<!-- ccpm-checklist-start -->
- [ ] Task 1: Description
- [x] Task 2: Description
<!-- ccpm-checklist-end -->
```

**Pattern 2: Header-Based (Fallback)**
```markdown
## ✅ Implementation Checklist
- [ ] Task 1
- [ ] Task 2
```

Parse the checklist to find item at index **$2**.

### Step 3: Update Checklist Item in Description

Update checklist item at index **$2** (0-based indexing) **directly in the description**:

**If status is "completed"**:
- Change `- [ ]` to `- [x]` at line index $2
- Mark as checked in description

**If status is "in-progress"**:
- Keep `- [ ]` (unchecked)
- No change to checkbox, only update via comment

**If status is "blocked"**:
- Keep `- [ ]` (unchecked)
- No change to checkbox
- **Also add "blocked" label** to the issue (ensure it exists first using `getOrCreateLabel()`)

**Generate Updated Description:**

1. Split description into lines
2. Find checklist section (between markers or under header)
3. Locate line at index $2 within checklist
4. If status is "completed":
   - Replace `- [ ]` with `- [x]` on that line
5. Calculate new completion percentage
6. Update progress line: `Progress: X% (Y/Z completed)`
7. Add/update timestamp: `Last updated: [ISO timestamp]`

**Example Update:**
```markdown
<!-- ccpm-checklist-start -->
- [ ] Task 1: Description
- [x] Task 2: Description ← UPDATED!
- [ ] Task 3: Description
<!-- ccpm-checklist-end -->

Progress: 33% (1/3 completed) ← UPDATED!
Last updated: 2025-01-20T14:30:00Z
```

### Step 4: Update Linear Issue

Use **Linear MCP** to:

**A) Update description** (with modified checklist from Step 3)

**B) Add comment** documenting the change:

```markdown
## 📝 Subtask #$2 Update

**Status**: $3
**Summary**: $4

**Checklist Progress**: X% → Y% (if status is "completed")

**Timestamp**: [current date/time]
```

**C) Update labels if needed**:
- If status is "blocked":
  1. Get team ID from the issue
  2. Use `getOrCreateLabel(teamId, "blocked", { color: "#eb5757", description: "CCPM: Task blocked, needs resolution" })`
  3. Add the label to the issue using the returned label ID
- If status is "completed" and all items complete:
  1. Use `getOrCreateLabel(teamId, "ready-for-review", { color: "#5e6ad2", description: "CCPM: Ready for code review" })`
  2. Add the label to the issue

**Error Handling**:
```javascript
try {
  // Get or create label
  const blockedLabel = await getOrCreateLabel(teamId, "blocked", {
    color: "#eb5757",
    description: "CCPM: Task blocked, needs resolution"
  });

  // Add label to issue
  await mcp__linear__update_issue({
    id: issueId,
    labelIds: [...existingLabelIds, blockedLabel.id]
  });
} catch (error) {
  console.error("Failed to add blocked label:", error);
  // Continue with update but warn user
  console.warn("⚠️ Could not add 'blocked' label. Please add manually if needed.");
}
```

### Step 5: Display Confirmation

Display confirmation:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Subtask #$2 Updated!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: $1
Status: $3
Summary: $4

📊 Progress: X% → Y% (if completed)

✅ Updated in Linear:
  • Description checkbox updated
  • Progress % recalculated
  • Comment added

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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