---
description: Rollback planning changes to previous version
allowed-tools: [LinearMCP]
argument-hint: <linear-issue-id>
---

# Rollback for: $1

## Workflow

### Step 1: Fetch History
- Get Linear issue history/activity
- Show last 10 description changes with timestamps

### Step 2: Show Versions
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📜 Description History for: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current (v5): [timestamp] by [user]
Preview: [first 100 chars...]

v4: [timestamp] by [user]
Preview: [first 100 chars...]

v3: [timestamp] by [user]
Preview: [first 100 chars...]

[... up to 10 versions ...]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 3: Ask Which Version
Use **AskUserQuestion** to select version to rollback to

### Step 4: Preview Rollback
Show full description of selected version for review

### Step 5: Confirm Rollback
Ask final confirmation before updating Linear

### Step 6: Execute
- Update Linear description to selected version
- Add comment: "Rolled back to version from [timestamp]"
- Show success

## Notes
- Safer than manual editing
- Shows full history
- Requires confirmation
