---
description: Plan a task - gather context from Jira/Confluence/Slack, analyze codebase, update Linear issue with research and checklist
allowed-tools: [Bash, LinearMCP, AtlassianMCP, SlackMCP, PlaywrightMCP, Context7MCP]
argument-hint: <linear-issue-id> <jira-ticket-id>
---

# Planning Task: Linear $1 (Jira: $2)

You are starting the **Planning Phase** for Linear issue **$1** based on Jira ticket **$2**.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

- ✅ **READ-ONLY** operations are permitted (fetch, search, view)
- ⛔ **WRITE operations** require user confirmation
- ✅ **Linear** operations are permitted (our internal tracking)

When in doubt, ASK before posting anything externally.

## Project Context

Projects and their PM systems:

- **trainer-guru**: Uses Jira, Confluence, Slack
  - Linear: Team "Work", Project "Trainer Guru"
- **repeat**: Uses Jira, Confluence, Slack
  - Linear: Team "Work", Project "Repeat"
- **nv-internal**: Pure Linear-based (no external PM)
  - Linear: Team "Personal", Project "NV Internal"

## Planning Workflow

### Step 0: Fetch Existing Linear Issue

Use **Linear MCP** to:

1. Get issue details for: $1
2. Read current title, description, and any existing context
3. Identify the project to determine which external PM systems to query
4. Extract any existing Jira ticket reference (if not provided as $2)

If $2 (Jira ticket ID) is not provided:

- Check Linear description for Jira ticket reference
- If no Jira ticket found, ask user for Jira ticket ID or proceed without external PM research

### Step 1: Gather All Context from External PM Systems

**Only if Jira ticket ID is available** (from $2 or Linear description):

1. **Use Atlassian MCP** to:
   - Fetch Jira ticket: $2 (or extracted from Linear)
   - Get all linked issues
   - Read issue description, comments, attachments

2. **Search Confluence** for:
   - Related documentation
   - PRD (Product Requirements Document)
   - Design documents
   - Architecture decisions
   - Technical specifications
   - **SAVE all page URLs** for linking in description

3. **Use Slack MCP** to:
   - Search relevant channels for discussions about this ticket
   - Find context from team conversations
   - Identify any blockers or decisions made
   - **SAVE thread URLs** for linking in description

4. **Use Playwright MCP** to:
   - Open BitBucket for related pull requests
   - Check commit history for related changes
   - Review code review comments if applicable
   - **SAVE PR URLs** for linking in description

5. **Extract and store all URLs**:
   - From Jira API responses (issue URLs, attachment URLs)
   - From Confluence API responses (page URLs)
   - From Slack API responses (thread/message URLs)
   - From BitBucket/browser (PR URLs, commit URLs)
   - From Linear API responses (related issue URLs)

6. **Use Context7 MCP** to:
   - Search for latest best practices related to this task
   - **IMPORTANT**: Do NOT trust knowledge cutoff - always search for current best practices
   - Find recommended approaches and patterns

### Step 2: Analyze Codebase

1. **Read relevant repository files**:
   - Identify files that need to be modified
   - Understand current implementation patterns
   - Find similar features for reference

2. **Identify patterns and conventions**:
   - Code structure and organization
   - Naming conventions
   - Testing patterns
   - API design patterns
   - Error handling approaches

3. **Map dependencies**:
   - Which repositories need changes
   - Dependencies between components
   - External service integrations
   - Database schema impacts

### Step 3: Update Linear Issue with Research

Use **Linear MCP** to update issue $1 with comprehensive research:

**Update Status**: Planning (if not already)
**Add Labels**: planning, research-complete

**IMPORTANT - Linking Format**:

When mentioning Jira tickets, Confluence pages, or related issues, create proper markdown links:

1. **Extract URLs from MCP responses** - When fetching from Atlassian MCP, Linear MCP, or Playwright:
   - Capture full URLs from API responses
   - Save them for linking in the description

2. **Link Format Examples**:
   - **Jira tickets**: `[TRAIN-123](https://jira.company.com/browse/TRAIN-123)`
   - **Confluence pages**: `[PRD: Authentication Flow](https://confluence.company.com/display/DOCS/Authentication)`
   - **Linear issues**: `[WORK-456](https://linear.app/workspace/issue/WORK-456)`
   - **BitBucket PRs**: `[PR #123: Add JWT auth](https://bitbucket.org/company/repo/pull-requests/123)`
   - **Slack threads**: `[Discussion about auth](https://company.slack.com/archives/C123/p456789)`

3. **Link Storage**:
   - Store all discovered URLs in a map/object as you research
   - Use them when writing the description
   - Example:
     ```javascript
     const links = {
       jira: "https://jira.company.com/browse/TRAIN-123",
       confluence: {
         prd: "https://confluence.company.com/display/DOCS/PRD",
         design: "https://confluence.company.com/display/DOCS/Design"
       },
       relatedTickets: [
         { id: "TRAIN-100", url: "https://jira.company.com/browse/TRAIN-100" },
         { id: "TRAIN-101", url: "https://jira.company.com/browse/TRAIN-101" }
       ]
     }
     ```

4. **Every mention MUST be a link**:
   - ✅ `See [TRAIN-123](https://jira.company.com/browse/TRAIN-123) for details`
   - ❌ `See TRAIN-123 for details` (no link)
   - ✅ `Based on [PRD](https://confluence.company.com/display/DOCS/PRD)`
   - ❌ `Based on PRD` (no link)

**Update Description** with this structure (replace existing content):

```markdown
## ✅ Implementation Checklist

> **Status**: Planning
> **Complexity**: [Low/Medium/High]

- [ ] **Subtask 1**: [Specific, actionable description]
- [ ] **Subtask 2**: [Specific, actionable description]
- [ ] **Subtask 3**: [Specific, actionable description]
- [ ] **Subtask 4**: [Specific, actionable description]
- [ ] **Subtask 5**: [Specific, actionable description]

---

## 📋 Context

**Linear Issue**: [$1](https://linear.app/workspace/issue/$1)
**Original Jira Ticket**: [Jira $2](https://jira.company.com/browse/$2) (if available)
**Summary**: [Brief description from Jira/Linear]

## 🔍 Research Findings

### Jira/Documentation Analysis

**Key Requirements**:

- [Key requirement 1 from Jira]
- [Key requirement 2 from Jira]

**Related Tickets**:

- [TRAIN-XXX](link) - [Brief description and outcome]
- [TRAIN-YYY](link) - [Brief description and outcome]

**Design Decisions** (from PRD/Confluence):

- [Decision 1 with link to [Confluence page](link)]
- [Decision 2 with link to [Confluence page](link)]

### Codebase Analysis

**Current Architecture**:

- [How feature currently works]
- [Relevant files and their purposes]

**Patterns Used**:

- [Code patterns found in similar features]
- [Conventions to follow]

**Technical Constraints**:

- [Any limitations or considerations]

### Best Practices (from Context7)

- [Latest recommended approach 1]
- [Latest recommended approach 2]
- [Performance considerations]
- [Security considerations]

### Cross-Repository Dependencies

[If applicable]:

- **Repository 1**: [What needs to change]
- **Repository 2**: [What needs to change]
- **Database**: [Schema changes if needed]

## 📝 Implementation Plan

**Approach**:
[Detailed explanation of how to implement this]

**Considerations**:

- [Edge cases to handle]
- [Backward compatibility]
- [Testing strategy]
- [Rollout plan if needed]

## 🔗 References

- **Linear Issue**: [$1](https://linear.app/workspace/issue/$1)
- **Original Jira**: [$2](https://jira.company.com/browse/$2) (if available)
- **Related PRD**: [Title](link to Confluence page) (if found)
- **Design Doc**: [Title](link to Confluence page) (if found)
- **Related PRs**: [PR #XXX](link to BitBucket) (if found)
- **Similar Implementation**: [file.ts:123](link to code) (if found)
```

### Step 4: Confirm Completion

After updating the Linear issue:

1. Display the Linear issue ID and current status
2. Show a summary of the research findings added
3. Confirm checklist has been created/updated
4. Provide the Linear issue URL

## Output Format

Provide a summary like:

```
✅ Planning Complete!

📋 Linear Issue Updated: $1
🔗 URL: https://linear.app/workspace/issue/$1
📝 Jira Reference: $2 (if available)

📊 Research Summary Added:
- Gathered context from [X] Jira tickets
- Found [Y] relevant Confluence docs
- Analyzed [Z] related Slack discussions
- Identified [N] files to modify
- Researched best practices from Context7

✅ Checklist: [X] subtasks created/updated

🚀 Ready for implementation! Run: /pm:implementation:start $1
```

## Notes

### Checklist Positioning

- **ALWAYS place checklist at the TOP** of the description
- This makes it immediately visible when opening the ticket
- Use blockquote for status and complexity metadata
- Separate checklist from detailed research with `---` horizontal rule

### Linking Best Practices

- **Every ticket/page mention MUST be a clickable link**
- Extract URLs from MCP API responses, not manual construction
- Store URLs as you research, use when writing description
- Link text should be descriptive (not just ticket ID)
- Example: `[TRAIN-123: Add JWT auth](url)` not just `[TRAIN-123](url)`

### Research Quality

- Be thorough in research - this is the foundation for successful implementation
- Always search Context7 for latest best practices
- Cross-reference multiple sources to validate approach
- If information is missing, document what's unknown in the Linear issue
- Create specific, actionable subtasks in the checklist
- Include links to ALL referenced materials (Jira, Confluence, Slack, PRs)