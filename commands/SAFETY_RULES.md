# PM Commands Safety Rules

## 🚨 CRITICAL SAFETY CONSTRAINTS

### ⛔ ABSOLUTE PROHIBITION - External PM Systems

**NEVER submit, post, update, or modify ANYTHING to external PM/collaboration systems without EXPLICIT user confirmation.**

**This applies to ANY external system that stores team data, including but not limited to:**

- ✖️ **Issue Tracking** (Jira, Azure DevOps, GitHub Issues, etc.)
- ✖️ **Documentation** (Confluence, Notion, SharePoint, etc.)
- ✖️ **Code Hosting** (BitBucket, GitLab beyond Linear's use, etc.)
- ✖️ **Team Communication** (Slack, Teams, Discord, etc.)

**Prohibited operations:**
- Creating/updating issues, tickets, or work items
- Posting comments or attachments
- Changing status, labels, or assignments
- Sending messages or notifications
- Creating/editing documentation pages
- Making repository changes (except via Linear's GitHub integration)

**This applies even in bypass permission mode.**

###  ✅ Allowed Actions (Read-Only)

The following read-only operations are permitted without confirmation:

- ✅ **Fetching/Reading** tickets and issues
- ✅ **Searching** documentation and wikis
- ✅ **Viewing** pull requests, commits, and code
- ✅ **Searching** messages and conversations
- ✅ **Browsing** with Playwright MCP (read-only)

### 📝 Linear Operations (Internal - No Confirmation Required)

**Linear is CCPM's internal tracking system. All Linear operations are ALWAYS ALLOWED without confirmation.**

**Never ask for confirmation when:**
- ✅ **Creating** Linear issues (single or multiple)
- ✅ **Updating** Linear issue descriptions/fields
- ✅ **Adding** comments to Linear issues
- ✅ **Changing** status, labels, or assignments in Linear
- ✅ **Closing** or reopening Linear issues

**Rationale**: Linear is internal project tracking, not external team communication. Users expect these operations to happen automatically when requested.

### 🔒 Confirmation Workflow

Before ANY write operation to external PM systems:

1. **Display** what you intend to do
2. **Show** the exact content to be posted/updated
3. **Wait** for explicit user confirmation
4. **Only proceed** after receiving "yes", "confirm", "go ahead", or similar

Example:

```text
🚨 CONFIRMATION REQUIRED

I want to post the following comment to [SYSTEM] ticket PROJ-123:

---
Implementation complete. Moving to QA.
- All tests passing
- Code review approved
---

Do you want me to proceed? (yes/no)
```

### ⚠️ Common Pitfalls to Avoid

**DO NOT:**

- ❌ Auto-post status updates to external issue trackers
- ❌ Auto-update external documentation with implementation notes
- ❌ Auto-comment on external PRs with review feedback
- ❌ Auto-send team notifications about task completion
- ❌ Assume "go ahead and finish" means "post externally"

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

### 🔧 Extending to New Tools

CCPM is designed to work with ANY external PM tool via MCP servers. When integrating a new tool:

1. **Classify operations** as read (allowed) or write (requires confirmation)
2. **Follow the pattern** established by existing integrations (Jira, Confluence)
3. **Preserve abstraction** - use pm-operations-orchestrator for tool-agnostic operations
4. **Document safety rules** for the specific tool if needed

The safety rules apply universally to ALL external systems, not just those explicitly listed above.
