---
description: Create Linear issue and run full planning workflow in one step
allowed-tools: [Bash, LinearMCP, AtlassianMCP, SlackMCP, PlaywrightMCP, Context7MCP]
argument-hint: "<title>" <project> <jira-ticket-id>
---

# Creating & Planning: $1 for Project: $2

You are **creating a new Linear issue** and running the **Planning Phase** in one step.

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

## Workflow

### Step 1: Create Linear Issue

Use **Linear MCP** to create a new issue:

**Title**: $1
**Team & Project mapping**:

- If project is "trainer-guru" → Team: "Work", Project: "Trainer Guru"
- If project is "repeat" → Team: "Work", Project: "Repeat"
- If project is "nv-internal" → Team: "Personal", Project: "NV Internal"

**Status**: Backlog
**Labels**: planning

**Initial Description**:

```markdown
## Task

$1

**Jira Reference**: $3 (if provided)

---

_Planning in progress..._
```

Save the created Linear issue ID.

Display:

```
✅ Linear Issue Created!

📋 Issue: [WORK-123]
🔗 URL: https://linear.app/workspace/issue/[WORK-123]
📝 Title: $1
🏢 Project: $2

⏳ Starting planning workflow...
```

### Step 2: Run Full Planning Workflow

Now run the **same workflow as `/pm:planning:plan`** using the created issue ID:

1. **Fetch Jira context** (if $3 provided):
   - Use Atlassian MCP to fetch Jira ticket: $3
   - Get linked issues, comments, attachments
   - **SAVE all URLs** for linking

2. **Search Confluence** (if applicable):
   - Related documentation, PRD, design docs
   - **SAVE all page URLs**

3. **Search Slack** (if applicable):
   - Relevant channel discussions
   - **SAVE thread URLs**

4. **Use Playwright** (if applicable):
   - BitBucket PRs and commits
   - **SAVE PR URLs**

5. **Extract and store all URLs** discovered

6. **Analyze Codebase**:
   - Identify relevant files
   - Find patterns and conventions
   - Assess complexity

7. **Use Context7 MCP**:
   - Search for latest best practices
   - Find recommended approaches

### Step 3: Update Linear Issue with Research

Use **Linear MCP** to update the created issue with comprehensive research:

**Update Status**: Planning
**Add Labels**: research-complete
**Update Description** (replace the initial description):

```markdown
## ✅ Implementation Checklist

> **Status**: Planning
> **Complexity**: [Low/Medium/High - estimated from analysis]

- [ ] **Subtask 1**: [Specific, actionable description]
- [ ] **Subtask 2**: [Specific, actionable description]
- [ ] **Subtask 3**: [Specific, actionable description]
- [ ] **Subtask 4**: [Specific, actionable description]
- [ ] **Subtask 5**: [Specific, actionable description]

---

## 📋 Context

**Linear Issue**: [WORK-123](https://linear.app/workspace/issue/WORK-123)
**Original Jira Ticket**: [Jira $3](https://jira.company.com/browse/$3) (if provided)
**Summary**: [Brief description from Jira/title]

## 🔍 Research Findings

### Jira/Documentation Analysis

**Key Requirements**:

- [Key requirement 1 from Jira or inferred from title]
- [Key requirement 2 from Jira]

**Related Tickets** (if found):

- [TRAIN-XXX](link) - [Brief description]
- [TRAIN-YYY](link) - [Brief description]

**Design Decisions** (if found):

- [Decision 1 with link to [Confluence page](link)]
- [Decision 2 with link to [Confluence page](link)]

### Codebase Analysis

**Current Architecture**:

- [How related features currently work]
- [Relevant files and purposes]

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

- **Linear Issue**: [WORK-123](https://linear.app/workspace/issue/WORK-123)
- **Original Jira**: [$3](https://jira.company.com/browse/$3) (if provided)
- **Related PRD**: [Title](link) (if found)
- **Design Doc**: [Title](link) (if found)
- **Related PRs**: [PR #XXX](link) (if found)
- **Similar Implementation**: [file.ts:123](link) (if found)
```

### Step 4: Show Status & Interactive Next Actions

**READ**: `/Users/duongdev/.claude/commands/pm/utils/_shared.md`

Use **Linear MCP** to get current status.

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Create & Planning Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Linear Issue: [WORK-123]
🔗 URL: https://linear.app/workspace/issue/[WORK-123]
📝 Jira Reference: $3 (if provided)

📊 Current Status: Planning
🎯 Progress: 0 of [N] subtasks complete (0%)
🏷️  Labels: planning, research-complete
⏱️  Time in status: Just created
📈 Complexity: [Low/Medium/High]

📊 Research Summary:
- Gathered context from [X] Jira tickets (if applicable)
- Found [Y] relevant Confluence docs (if applicable)
- Analyzed [Z] related Slack discussions (if applicable)
- Identified [N] files to modify
- Researched best practices from Context7

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Suggested Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use **AskUserQuestion** tool:

```javascript
{
  questions: [{
    question: "Planning complete! What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "Start Implementation",
        description: "Begin working with agent coordination (/pm:implementation:start)"
      },
      {
        label: "Get AI Insights",
        description: "Get AI analysis of complexity, risks, and timeline (/pm:utils:insights)"
      },
      {
        label: "Review Planning",
        description: "Review the planning details in Linear (/pm:utils:status)"
      },
      {
        label: "Auto-Assign Agents",
        description: "Let AI assign subtasks to optimal agents (/pm:utils:auto-assign)"
      }
    ]
  }]
}
```

**Execute the chosen action**:

- If "Start Implementation" → Run `/pm:implementation:start [WORK-123]`
- If "Get AI Insights" → Run `/pm:utils:insights [WORK-123]`
- If "Review Planning" → Run `/pm:utils:status [WORK-123]`
- If "Auto-Assign Agents" → Run `/pm:utils:auto-assign [WORK-123]`
- If "Other" → Show quick commands and exit gracefully

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:        /pm:utils:status [WORK-123]
Start:         /pm:implementation:start [WORK-123]
Insights:      /pm:utils:insights [WORK-123]
Context:       /pm:utils:context [WORK-123]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

### This Command Combines

1. **Issue Creation** - No manual Linear UI needed
2. **Full Planning** - All research in one go
3. **Interactive Mode** - Suggests next actions
4. **Continuous Flow** - Can chain to next command

### Usage Patterns

**With Jira:**

```bash
/pm:planning:create "Add JWT authentication" trainer-guru TRAIN-456
```

**Without Jira (NV Internal):**

```bash
/pm:planning:create "Add dark mode toggle" nv-internal
```

### Benefits

- ✅ One command instead of two
- ✅ No context switching to Linear UI
- ✅ Immediate planning after creation
- ✅ Interactive next steps
- ✅ Fast workflow start
