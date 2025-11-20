---
description: Sync Linear status to Jira with confirmation
allowed-tools: [LinearMCP, AtlassianMCP]
argument-hint: <linear-issue-id>
---

# Syncing Status: $1

## 🚨 CRITICAL: Safety Rules

**WILL ASK FOR CONFIRMATION** before updating Jira!

## Workflow

### Step 1: Fetch Linear Status
- Get current Linear status, progress, completion summary

### Step 2: Determine Jira Status
Map Linear → Jira:
- Planning → "In Progress" or "To Do"
- In Progress → "In Progress"
- Verification → "In Review"
- Done → "Done"

### Step 3: Preview Changes
```
🔄 Proposed Jira Update

Jira Ticket: [JIRA-ID]
Current Status: [Current]
New Status: [Proposed]

Comment to add:
---
Updated from Linear [WORK-123]
Status: [status]
Progress: [X/Y] subtasks ([%]%)
[Brief summary if done]
---
```

### Step 4: Ask Confirmation
Use **AskUserQuestion**:
```javascript
{questions: [{
  question: "Update Jira with this status?",
  header: "Confirm",
  multiSelect: false,
  options: [
    {label: "Yes, Update Jira", description: "Proceed with update"},
    {label: "Edit Comment", description: "Let me edit the comment first"},
    {label: "Cancel", description: "Don't update Jira"}
  ]
}]}
```

### Step 5: Execute if Confirmed
- Use Atlassian MCP to update Jira
- Add comment with Linear link
- Show confirmation

## Notes
- Read-only until user confirms
- Always shows preview first
- Includes link back to Linear
