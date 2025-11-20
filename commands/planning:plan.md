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

## Project Configuration

**IMPORTANT**: This command uses dynamic project configuration from `~/.claude/ccpm-config.yaml`.

## Planning Workflow

### Step 0: Fetch Existing Linear Issue & Load Project Config

Use **Linear MCP** to:

1. Get issue details for: $1
2. Read current title, description, and any existing context
3. **Determine the project from the Linear issue** (team/project mapping)
4. Extract any existing Jira ticket reference (if not provided as $2)

**Load Project Configuration:**

```bash
# Get project ID from Linear issue's team/project
# Map Linear team+project to project ID in config

# Example: If Linear shows "Work / My App"
# Search config for matching linear.team="Work" and linear.project="My App"

# Load project config
PROJECT_ARG=$(determine_project_from_linear_issue "$1")
```

**LOAD PROJECT CONFIG**: Follow instructions in `commands/_shared-project-config-loader.md`

After loading, you'll have:
- `${EXTERNAL_PM_ENABLED}` - Whether to query Jira/Confluence/Slack
- `${EXTERNAL_PM_TYPE}` - Type of external PM
- `${JIRA_ENABLED}`, `${CONFLUENCE_ENABLED}`, `${SLACK_ENABLED}`
- All other project settings

If $2 (Jira ticket ID) is not provided:

- Check Linear description for Jira ticket reference
- If no Jira ticket found, ask user for Jira ticket ID or proceed without external PM research

### Step 0.5+: Execute Shared Planning Workflow

**READ**: `commands/_shared-planning-workflow.md`

Execute the shared planning workflow to handle all planning steps systematically.

**Set required context variables:**
- `LINEAR_ISSUE_ID` = $1 (the Linear issue to plan)
- `JIRA_TICKET_ID` = $2 (optional, can be extracted from Linear issue)
- `PROJECT_CONFIG` = [loaded from Step 0]
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

## 💡 Hint: Try the New Natural Command

For a simpler workflow, consider using:

```bash
/ccpm:plan WORK-123
```

**Benefits:**
- Same functionality, simpler syntax
- Part of the 6-command natural workflow
- See: [Quick Start Guide](./README.md#quick-start)

This command still works perfectly! The hint is just a suggestion.

---

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

🚀 Ready for implementation! Run: /ccpm:implementation:start $1
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
