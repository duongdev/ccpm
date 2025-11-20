---
description: Finalize completed task - sync with Jira, create PR, clean up
allowed-tools: [Bash, LinearMCP, AtlassianMCP, SlackMCP]
argument-hint: <linear-issue-id>
---

# Finalizing Task: $1

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

⛔ **WILL ASK FOR CONFIRMATION** before posting to Jira, Slack, or creating PR!

## Workflow

### Step 1: Verify Task is Complete

Use **Linear MCP** to verify:
- Status is "Done" or "Verification" passed
- All checklist items complete
- No "blocked" label

If not complete, suggest `/ccpm:verification:verify $1` first.

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
