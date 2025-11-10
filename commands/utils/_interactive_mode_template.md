# Interactive Mode Template

Add this section to the END of existing PM command files to enable interactive mode.

## Template to Append

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Interactive Mode: Status & Next Actions

**After completing the main command, ALWAYS show status and suggest next actions.**

### Show Current Status

Use **Linear MCP** to fetch current issue status:

Display:

\`\`\`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [Command Name] Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Current Status: [status]
🎯 Progress: [X/Y] subtasks ([%]%)
🏷️  Labels: [labels]
⏱️  Time in status: [duration]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Suggested Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
\`\`\`

### Suggest Next Actions Based on Status

**READ**: `/Users/duongdev/.claude/commands/pm/utils/_shared.md` for status-based suggestions.

Detect appropriate next actions based on:
- Current status (Planning/In Progress/Verification/Done/Blocked)
- Progress percentage
- Labels present
- Time in current status

### Ask User

Use **AskUserQuestion** tool with 2-4 relevant options.

Example:

\`\`\`javascript
{
  questions: [{
    question: "What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "[Primary Suggested Action]",
        description: "[Why this makes sense]"
      },
      {
        label: "[Alternative Action]",
        description: "[Alternative approach]"
      },
      {
        label: "View Status",
        description: "Just show me current status"
      },
      {
        label: "Decide Later",
        description: "I'll decide what to do next later"
      }
    ]
  }]
}
\`\`\`

### Execute Chosen Action

Based on user's choice:
- If specific action → Execute the corresponding command
- If "View Status" → Run \`/pm:utils:status [issue-id]\`
- If "Decide Later" → Show quick commands and exit gracefully

### Quick Commands Footer

Always show:

\`\`\`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:        /pm:utils:status [issue-id]
Next:          /pm:implementation:next [issue-id]
Context:       /pm:utils:context [issue-id]
Report:        /pm:utils:report [project]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
\`\`\`
```

## Commands to Update

Add interactive mode to:

1. `/pm/planning/plan.md` - After planning complete
2. `/pm/planning/quick-plan.md` - After planning complete
3. `/pm/implementation/start.md` - After assignments created
4. `/pm/implementation/update.md` - After update complete
5. `/pm/verification/check.md` - After checks complete
6. `/pm/verification/verify.md` - After verification complete
7. `/pm/verification/fix.md` - After fixes complete
8. `/pm/utils/status.md` - After showing status
9. `/pm/utils/agents.md` - After showing agents

## Example Integration

### Before (plan.md):

```markdown
### Step 4: Confirm Completion

After updating the Linear issue:
1. Display the Linear issue ID and current status
2. Show a summary of the research findings added
3. Confirm checklist has been created/updated
4. Provide the Linear issue URL

## Notes
...
```

### After (plan.md with Interactive Mode):

```markdown
### Step 4: Confirm Completion & Interactive Next Actions

After updating the Linear issue:
1. Display the Linear issue ID and current status
2. Show a summary of the research findings added
3. Confirm checklist has been created/updated
4. Provide the Linear issue URL

**THEN immediately show status and suggest next actions:**

[Add full interactive mode template here from above]

## Notes
...
```

## Quick Reference

**Status-Based Next Actions** (from `_shared.md`):

- **Planning** → Suggest: Start implementation, Get insights, Auto-assign
- **In Progress** → Suggest: Next task, Update progress, Quality checks (if ready)
- **Verification** → Suggest: Run verification, Check quality
- **Blocked** → Suggest: Fix issues, Rollback
- **Done** → Suggest: Finalize, Create new task

**Always**:
1. Show current status
2. Calculate progress
3. Detect appropriate next action
4. Ask user with 2-4 options
5. Execute or exit gracefully
6. Show quick commands
