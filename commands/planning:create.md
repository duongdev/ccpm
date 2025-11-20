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

## Project Configuration

**IMPORTANT**: This command uses CCPM agents for efficient project detection and configuration loading.

### Auto-Activate Skills

```markdown
Skill(project-detection): Auto-activates for project context
Skill(project-operations): Provides workflow guidance
```

### Load Project Configuration with Agents

Use project agents to detect and load configuration:

```javascript
// Step 1: Detect or get project from argument
const projectArg = "$2"  // Optional project argument

let projectContext

if (projectArg && projectArg !== "") {
  // User specified project, load it
  projectContext = Task(project-context-manager): `
  Get context for project: ${projectArg}
  Format: standard
  Include all sections: true
  `
} else {
  // Auto-detect from current directory
  projectContext = Task(project-context-manager): `
  Get active project context
  Format: standard
  Include all sections: true
  `
}

if (projectContext.error) {
  console.error(`❌ ${projectContext.error.message}`)
  projectContext.error.suggestions?.forEach(s => console.log(`  - ${s}`))
  exit(1)
}

// Now we have all project configuration in structured format:
const PROJECT_ID = projectContext.detected.project_id
const PROJECT_NAME = projectContext.config.project_name
const SUBPROJECT = projectContext.detected.subproject  // NEW: for monorepos

const LINEAR_TEAM = projectContext.config.linear.team
const LINEAR_PROJECT = projectContext.config.linear.project
const LINEAR_DEFAULT_LABELS = projectContext.config.linear.default_labels

const EXTERNAL_PM_ENABLED = projectContext.config.external_pm.enabled
const EXTERNAL_PM_TYPE = projectContext.config.external_pm.type
const JIRA_CONFIG = projectContext.config.external_pm.jira
const CONFLUENCE_CONFIG = projectContext.config.external_pm.confluence

const TECH_STACK = SUBPROJECT
  ? projectContext.config.subproject?.tech_stack
  : projectContext.config.tech_stack

// Display context
console.log(projectContext.display.title)  // e.g., "My Monorepo › frontend"
```

**Benefits of Agent-Based Approach**:
- ~80% token reduction vs inline logic
- Automatic subdirectory detection for monorepos
- Consistent error handling
- Structured, validated output
- Tech stack awareness (overall or per-subproject)

## Workflow

### Step 1: Create Linear Issue

Use **Linear MCP** to create a new issue using loaded configuration:

**Title**: $1
**Team**: ${LINEAR_TEAM} (from config)
**Project**: ${LINEAR_PROJECT} (from config)
**Status**: Backlog
**Labels**: ${LINEAR_DEFAULT_LABELS} + subproject label (if in monorepo)

```javascript
// Build labels array
const labels = [...LINEAR_DEFAULT_LABELS]

// Add subproject label for monorepo context
if (SUBPROJECT) {
  labels.push(SUBPROJECT)
  console.log(`📁 Subproject context: ${SUBPROJECT}`)
}

// Create issue
const issue = linear_create_issue({
  title: "$1",
  team: LINEAR_TEAM,
  project: LINEAR_PROJECT,
  state: "Backlog",
  labels: labels
})
```

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

Now run the **same workflow as `/ccpm:planning:plan`** using the created issue ID:

#### Check if External PM is Enabled

```javascript
// Only fetch external PM data if enabled in config
if (EXTERNAL_PM_ENABLED === "true") {
  console.log(`📡 External PM enabled: ${EXTERNAL_PM_TYPE}`)

  // Fetch based on PM type
  if (EXTERNAL_PM_TYPE === "jira") {
    // Steps 1-3 below
  }
} else {
  console.log(`📋 Linear-only mode (no external PM)`)
  // Skip to Step 4
}
```

1. **Fetch Jira context** (if `EXTERNAL_PM_ENABLED` and $3 provided):
   - Load Jira config: `JIRA_BASE_URL`, `JIRA_PROJECT_KEY`
   - Use Atlassian MCP to fetch Jira ticket: $3
   - Get linked issues, comments, attachments
   - **SAVE all URLs** for linking

2. **Search Confluence** (if `confluence.enabled` in config):
   - Load Confluence config: `CONFLUENCE_BASE_URL`, `CONFLUENCE_SPACE_KEY`
   - Search for related documentation, PRD, design docs
   - **SAVE all page URLs**

3. **Search Slack** (if `slack.enabled` in config):
   - Load Slack config: `SLACK_WORKSPACE`, `SLACK_CHANNELS`
   - Search relevant channel discussions
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
        description: "Begin working with agent coordination (/ccpm:implementation:start)"
      },
      {
        label: "Get AI Insights",
        description: "Get AI analysis of complexity, risks, and timeline (/ccpm:utils:insights)"
      },
      {
        label: "Review Planning",
        description: "Review the planning details in Linear (/ccpm:utils:status)"
      },
      {
        label: "Auto-Assign Agents",
        description: "Let AI assign subtasks to optimal agents (/ccpm:utils:auto-assign)"
      }
    ]
  }]
}
```

**Execute the chosen action**:

- If "Start Implementation" → Run `/ccpm:implementation:start [WORK-123]`
- If "Get AI Insights" → Run `/ccpm:utils:insights [WORK-123]`
- If "Review Planning" → Run `/ccpm:utils:status [WORK-123]`
- If "Auto-Assign Agents" → Run `/ccpm:utils:auto-assign [WORK-123]`
- If "Other" → Show quick commands and exit gracefully

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:        /ccpm:utils:status [WORK-123]
Start:         /ccpm:implementation:start [WORK-123]
Insights:      /ccpm:utils:insights [WORK-123]
Context:       /ccpm:utils:context [WORK-123]

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
/ccpm:planning:create "Add JWT authentication" my-app PROJ-456
```

**Without Jira (Linear-only):**

```bash
/ccpm:planning:create "Add dark mode toggle" personal-project
```

**With Active Project:**

```bash
/ccpm:project:set my-app
/ccpm:planning:create "Add JWT authentication"  # Uses active project
```

### Benefits

- ✅ One command instead of two
- ✅ No context switching to Linear UI
- ✅ Immediate planning after creation
- ✅ Interactive next steps
- ✅ Fast workflow start
