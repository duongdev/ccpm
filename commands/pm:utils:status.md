---
description: Show current status of a task from Linear with formatted display
allowed-tools: [LinearMCP]
argument-hint: <linear-issue-id>
---

# Status for: $1

Fetching current status from Linear...

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Status Display

Use **Linear MCP** to get issue: $1

Display formatted status:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Task Status: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏷️  **Title**: [Issue title]
🏢 **Team**: [Team name - Work or Personal]
📦 **Project**: [Project name - Trainer Guru, Repeat, or NV Internal]
📊 **Status**: [Current status]
🏷️  **Labels**: [Comma-separated labels]
👤 **Assignee**: [Assignee name if any]
📅 **Created**: [Creation date]
📅 **Updated**: [Last update date]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Description (Preview)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[First 5 lines of description...]

[If longer: "... (see full description in Linear)"]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Progress: [X of Y] subtasks completed ([percentage]%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Checklist**:
[x] Subtask 1 ✅ [Summary if available]
[x] Subtask 2 ✅ [Summary if available]
[ ] Subtask 3 ⏳ [Summary if available]
[ ] Subtask 4 🚫 [Summary if available]
[ ] Subtask 5

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬 Recent Activity (Last 3 comments)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**[Date/Time]** - [Author]
[Comment preview - first 2 lines...]

**[Date/Time]** - [Author]
[Comment preview - first 2 lines...]

**[Date/Time]** - [Author]
[Comment preview - first 2 lines...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 Links & References
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Linear Issue**: https://linear.app/[workspace]/issue/$1
[If found in description]:
**Original Ticket**: [Jira/other link]
**Related Docs**: [Documentation links]
**Pull Request**: [PR link if available]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Current Phase & Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Based on current status, show appropriate next step]:

If status is "Planning":
  📋 Next: Begin implementation with /start $1

If status is "In Progress" and no blockers:
  ⏳ In Progress: Continue working on subtasks
  📝 Update progress: /update $1 <index> <status> "<summary>"

If status is "In Progress" with blockers:
  🚫 Blocked: Address blocking issues
  🔧 Fix issues: /fix $1

If status is "Verification":
  🔍 Next: Run quality checks with /check $1
  ✅ Then verify: /verify $1

If status is "Done":
  ✅ Task Complete! No further action needed.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Status Indicators

**Checklist Items**:
- `- [x] ✅` = Completed
- `- [ ] ⏳` = In Progress
- `- [ ] 🚫` = Blocked
- `- [ ]` = Not Started

**Status Meanings**:
- **Backlog**: Not started yet
- **Planning**: Research and planning phase
- **Ready**: Ready to implement
- **In Progress**: Active development
- **Verification**: Quality checks and verification
- **Done**: Completed and verified
- **Blocked**: Cannot proceed (with "blocked" label)

## Quick Actions Based on Status

Display relevant quick actions:

```
💡 Quick Actions:

[If Planning]:
  /start $1  - Begin implementation

[If In Progress]:
  /update $1 <idx> <status> "msg"  - Update a subtask
  /status $1  - Refresh status
  /check $1  - Run quality checks (when ready)

[If Verification]:
  /check $1  - Run quality checks
  /verify $1  - Verify task completion

[If Blocked]:
  /fix $1  - Start fixing issues
  /status $1  - Check current state
```

## Summary Statistics

Also display high-level stats:

```
📊 Statistics:
- Total subtasks: [N]
- Completed: [X] ([percentage]%)
- In progress: [Y]
- Blocked: [Z]
- Comments: [M]
- Days in current status: [D]
```

## Notes

- Status updates in real-time from Linear
- Shows most recent activity
- Highlights any blocking issues
- Provides contextual next steps
- Use this command frequently to stay updated