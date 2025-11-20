---
description: Finalize completed task - sync with Jira, create PR, clean up
allowed-tools: [Bash, LinearMCP, AtlassianMCP, SlackMCP]
argument-hint: <linear-issue-id>
---

# Finalizing Task: $1

## 💡 Hint: Try the New Natural Command

For a simpler workflow, consider using:

```bash
/ccpm:done [issue-id]
```

**Benefits:**
- Auto-detects issue from git branch if not provided
- Includes pre-flight safety checks (uncommitted changes, branch pushed, etc.)
- Part of the 6-command natural workflow
- See: [Quick Start Guide](./README.md#quick-start)

This command still works perfectly! The hint is just a suggestion.

---

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

⛔ **WILL ASK FOR CONFIRMATION** before posting to Jira, Slack, or creating PR!

## Workflow

### Step 1: Verify Task is Complete

Use **Linear MCP** to get issue: $1

**A) Check Status**

Verify status is "Done" or "Verification" (passed).

If status is "In Progress" or "Backlog":
- Display: ⚠️ Task status is "$status". Run `/ccpm:verification:verify $1` first.
- Exit

**B) Parse and Verify Checklist Completion**

Look for checklist in description using markers:
```markdown
<!-- ccpm-checklist-start -->
- [ ] Task 1
- [x] Task 2
<!-- ccpm-checklist-end -->
```

Or find "## ✅ Implementation Checklist" header.

**Calculate completion:**
- Total items: Count all `- [ ]` and `- [x]` lines
- Checked items: Count `- [x]` lines only
- Percentage: (checked / total) × 100

**If completion < 100%:**

Display incomplete items:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔ Cannot Finalize: Checklist Incomplete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Progress: X% (Y/Z completed)

❌ Remaining Items:
 - [ ] Task 3: Description
 - [ ] Task 5: Description

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 Actions Required
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Complete remaining items
2. Update checklist: /ccpm:utils:update-checklist $1
3. Then run finalize again: /ccpm:complete:finalize $1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**BLOCK finalization and exit.**

**If completion = 100%:**

Display:
```
✅ Checklist complete! (100% - Z/Z items)
```

Continue to Step 2.

**C) Check for "blocked" label**

If "blocked" label exists:
- Display: ⚠️ Task has "blocked" label. Resolve blockers before finalizing.
- Exit

**If all verifications pass:**
- Continue to Step 2

### Step 2: Generate Completion Summary

Create summary from Linear description and checklist:

```markdown
## Implementation Summary for $1

### What Was Implemented
[Extract from checklist items marked complete]

### Files Modified
[Extract file paths mentioned in description/comments]

### Tests Added
[Extract test information]

### Related Links
- Linear: [link]
- Jira: [link]
- PRs: [links if exist]
```

### Step 3: Interactive Finalization Choices

Use **AskUserQuestion**:

```javascript
{
  questions: [
    {
      question: "Do you want to create a Pull Request?",
      header: "Create PR",
      multiSelect: false,
      options: [
        {label: "Yes, Create PR", description: "Generate PR with description"},
        {label: "No, Skip PR", description: "I'll create it manually later"}
      ]
    },
    {
      question: "Do you want to update Jira status?",
      header: "Sync Jira",
      multiSelect: false,
      options: [
        {label: "Yes, Update Jira", description: "Mark Jira ticket as Done"},
        {label: "No, Skip Jira", description: "I'll update manually"}
      ]
    },
    {
      question: "Do you want to notify team in Slack?",
      header: "Notify Team",
      multiSelect: false,
      options: [
        {label: "Yes, Notify Slack", description: "Post completion message"},
        {label: "No, Skip Slack", description: "No notification needed"}
      ]
    }
  ]
}
```

### Step 4: Execute Chosen Actions

**If Create PR chosen**:
- Generate PR title from Linear title
- Generate PR description from implementation summary
- Suggest command: `gh pr create --title "..." --body "..."`
- Show command for user approval

**If Update Jira chosen**:
- **ASK FOR CONFIRMATION** with preview:
  ```
  🚨 CONFIRMATION REQUIRED

  I will update Jira ticket [JIRA-ID] to status "Done" with comment:
  ---
  Completed in Linear: [WORK-123]
  [Implementation summary]
  ---

  Proceed? (yes/no)
  ```
- If yes → Use Atlassian MCP to update

**If Notify Slack chosen**:
- **ASK FOR CONFIRMATION** with preview:
  ```
  🚨 CONFIRMATION REQUIRED

  I will post to #[channel]:
  ---
  ✅ [Linear title] is complete!
  [Brief summary]
  Linear: [link]
  ---

  Proceed? (yes/no)
  ```
- If yes → Use Slack MCP to post

### Step 5: Archive and Clean Up

- Update Linear status to "Done" (if not already)
- Remove "in-progress" labels
- Add completion timestamp comment

### Step 6: Show Final Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Task Finalized: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Linear: Updated to Done
[✅/⏭️ ] Pull Request: [Created/Skipped]
[✅/⏭️ ] Jira: [Updated/Skipped]
[✅/⏭️ ] Slack: [Notified/Skipped]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 What's Next?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use **AskUserQuestion** for next action:

```javascript
{
  questions: [{
    question: "Task complete! What would you like to do next?",
    header: "Next Action",
    multiSelect: false,
    options: [
      {label: "Create New Task", description: "Start a new task"},
      {label: "View Project Report", description: "See project progress"},
      {label: "Pick Another Task", description: "Work on existing task"},
      {label: "Done for Now", description: "Exit"}
    ]
  }]
}
```

## Notes

- Always asks for confirmation before external writes
- Generates helpful PR descriptions
- Keeps team informed (if desired)
- Suggests next productive action
