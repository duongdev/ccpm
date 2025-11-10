# PM Commands Safety Rules

## 🚨 CRITICAL SAFETY CONSTRAINTS

### ⛔ ABSOLUTE PROHIBITION - External PM Systems

**NEVER submit, post, update, or modify ANYTHING to the following systems without EXPLICIT user confirmation:**

- ✖️ **Jira** (issues, comments, attachments, status changes)
- ✖️ **Confluence** (pages, comments, edits)
- ✖️ **BitBucket** (pull requests, comments, repository changes)
- ✖️ **Slack** (messages, posts, reactions)

**This applies even in bypass permission mode.**

### ✅ Allowed Actions (Read-Only)

The following read-only operations are permitted without confirmation:

- ✅ **Fetching/Reading** Jira tickets
- ✅ **Searching** Confluence documentation
- ✅ **Viewing** BitBucket pull requests and commits
- ✅ **Searching** Slack messages and conversations
- ✅ **Browsing** with Playwright MCP (read-only)

### 📝 Linear Operations

Linear operations are permitted but should follow confirmation workflow:

- ✅ **Creating** Linear issues (confirm if creating multiple)
- ✅ **Updating** Linear issues (confirm if significant changes)
- ✅ **Adding** comments to Linear (always safe)
- ✅ **Changing** status/labels in Linear (confirm if bulk changes)

### 🔒 Confirmation Workflow

Before ANY write operation to external PM systems:

1. **Display** what you intend to do
2. **Show** the exact content to be posted/updated
3. **Wait** for explicit user confirmation
4. **Only proceed** after receiving "yes", "confirm", "go ahead", or similar

Example:

```text
🚨 CONFIRMATION REQUIRED

I want to post the following comment to Jira ticket TRAIN-123:

---
Implementation complete. Moving to QA.
- All tests passing
- Code review approved
---

Do you want me to proceed? (yes/no)
```

### ⚠️ Common Pitfalls to Avoid

**DO NOT:**

- ❌ Auto-post status updates to Jira after completing work
- ❌ Auto-update Confluence with implementation notes
- ❌ Auto-comment on BitBucket PRs with review feedback
- ❌ Auto-send Slack notifications about task completion
- ❌ Assume "go ahead and finish" means "post to Jira"

**DO:**

- ✅ Gather all information from external systems
- ✅ Create comprehensive Linear issues with all context
- ✅ Update Linear freely (internal tracking)
- ✅ Ask before posting anything externally
- ✅ Show exactly what will be posted before posting

### 📋 Remember

**The goal is to:**

- **Gather** intelligence from external PM systems
- **Centralize** planning and tracking in Linear
- **Never pollute** external systems without explicit approval
- **Maintain** full transparency with the user

**When in doubt, ASK first.**
