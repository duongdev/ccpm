---
description: Create Linear issue and run full planning workflow in one step
allowed-tools: [Bash, LinearMCP, AtlassianMCP, SlackMCP, PlaywrightMCP, Context7MCP]
argument-hint: "<title>" <project> <jira-ticket-id>
---

# Creating & Planning: $1 for Project: $2

You are **creating a new Linear issue** and running the **Planning Phase** in one step.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

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

**IMPORTANT**: Use shared Linear helpers for resilient state and label handling:

```markdown
READ: commands/_shared-linear-helpers.md
```

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

// Ensure all labels exist before creating issue
try {
  const validLabels = await ensureLabelsExist(LINEAR_TEAM, labels, {
    descriptions: {
      'planning': 'Task is in planning phase',
      'research': 'Research and discovery required',
      'implementation': 'Task is being implemented',
      'verification': 'Task is being verified'
    }
  })

  // Get valid state ID for "Backlog"
  const backlogStateId = await getValidStateId(LINEAR_TEAM, "Backlog")

  // Create issue with validated state and labels
  const issue = linear_create_issue({
    title: "$1",
    team: LINEAR_TEAM,
    project: LINEAR_PROJECT,
    stateId: backlogStateId,
    labelIds: validLabels
  })

} catch (error) {
  if (error.message.includes('Could not find state') || error.message.includes('Invalid state')) {
    console.error(`❌ Linear State Error: ${error.message}`)
    console.log(`💡 Tip: Run '/ccpm:utils:status' to see available states for your team`)
    throw error
  }
  throw error
}
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

### Step 2: Execute Shared Planning Workflow

**READ**: `commands/_shared-planning-workflow.md`

Execute the shared planning workflow to complete planning for the newly created issue.

**Set required context variables:**
- `LINEAR_ISSUE_ID` = [created issue ID from Step 1]
- `JIRA_TICKET_ID` = $3 (optional Jira ticket ID)
- `PROJECT_CONFIG` = [loaded in project configuration section]
- `EXTERNAL_PM_ENABLED` = [from config]
- `EXTERNAL_PM_TYPE` = [from config]
- `JIRA_ENABLED`, `CONFLUENCE_ENABLED`, `SLACK_ENABLED` = [from config]

**Execute these steps from the shared workflow:**

1. **Step 0.5**: Detect and analyze images in the Linear issue
   - Uses `commands/_shared-image-analysis.md` logic
   - Finds UI mockups, diagrams, screenshots
   - Analyzes and formats for Linear description

2. **Step 0.6**: Detect and extract Figma designs
   - Uses `commands/_shared-figma-detection.md` logic
   - Identifies live Figma links
   - Extracts design tokens and specifications
   - Caches results in Linear comments

3. **Step 1**: Gather external PM context (Jira, Confluence, Slack)
   - Only if external PM is enabled
   - Fetches Jira ticket details and linked issues
   - Searches Confluence for related documentation
   - Finds Slack thread discussions
   - Checks BitBucket for related PRs

4. **Step 2**: Analyze codebase
   - Identifies relevant files to modify
   - Maps patterns and conventions
   - Determines dependencies

5. **Step 2.5**: Invoke engineer agents for technical analysis
   - Selects appropriate agents based on task type
   - Backend tasks → `backend-architect`
   - Frontend tasks → `frontend-developer`
   - Mobile tasks → `mobile-developer`
   - Full-stack → both backend and frontend in parallel
   - Security-critical → add `security-auditor`

6. **Step 3**: Update Linear description with comprehensive research
   - Creates implementation checklist
   - Inserts visual context (images + Figma designs)
   - Adds research findings
   - Includes agent analysis
   - Links all external resources

7. **Step 4**: Confirm completion
   - Display status summary
   - Show research added
   - Provide Linear issue URL

This ensures the new issue receives the same comprehensive planning as existing issues:
- Image analysis
- Figma design extraction
- External PM research
- Codebase analysis
- Implementation checklist generation

### Step 3: Show Status & Interactive Next Actions

**READ**: ``$CCPM_COMMANDS_DIR/_shared-linear-helpers.md``

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

## 💡 Hint: Try the New Natural Command

For a simpler workflow, consider using:

```bash
/ccpm:plan "task title" [project] [jira-ticket]
```

**Benefits:**
- Same functionality, simpler syntax
- Part of the 6-command natural workflow
- Auto-detects project if configured
- See: [Quick Start Guide](./README.md#quick-start)

This command still works perfectly! The hint is just a suggestion.

---

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
