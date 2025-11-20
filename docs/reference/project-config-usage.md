# Project Configuration Usage Reference

**For Command Developers**: How to load and use CCPM project configuration in commands.

## Purpose

This reference guide shows how to load and use project configuration in CCPM commands using the configuration loader script.

## Loading Project Configuration

Use the configuration loader script to get project settings:

```bash
# Load full configuration as JSON
CONFIG=$(./scripts/load-project-config.sh --json)

# Get specific values
PROJECT_ID=$(./scripts/load-project-config.sh --get project.id)
LINEAR_TEAM=$(./scripts/load-project-config.sh --get linear.team)
LINEAR_PROJECT=$(./scripts/load-project-config.sh --get linear.project)

# Validate configuration exists
./scripts/load-project-config.sh --validate-only || {
  echo "Error: No project configuration found"
  exit 1
}
```

## Configuration Structure

### Project Metadata

```javascript
// Get project metadata
const projectId = await getConfig("project.id")
const projectName = await getConfig("project.name")
const projectDescription = await getConfig("project.description")
```

### Linear Configuration

```javascript
// Get Linear settings
const linearTeam = await getConfig("linear.team")
const linearProject = await getConfig("linear.project")
const defaultLabels = await getConfig("linear.default_labels")  // Array
const workflowStates = await getConfig("linear.workflow_states")  // Object
```

**Usage in Linear MCP calls:**

```javascript
// Create issue with project configuration
await mcp__linear__create_issue({
  team: linearTeam,
  project: linearProject,
  title: issueTitle,
  description: issueDescription,
  state: workflowStates.backlog,  // or "Backlog"
  labels: defaultLabels  // ["planning", "auto-created"]
})
```

### External PM Configuration

```javascript
// Check if external PM is enabled
const externalPmEnabled = await getConfig("external_pm.enabled")  // boolean
const externalPmType = await getConfig("external_pm.type")  // "jira", "github", "linear-only"

// Jira configuration
if (externalPmType === "jira") {
  const jiraEnabled = await getConfig("external_pm.jira.enabled")
  const jiraBaseUrl = await getConfig("external_pm.jira.base_url")
  const jiraProjectKey = await getConfig("external_pm.jira.project_key")

  // Example: Construct Jira ticket URL
  const jiraTicketUrl = `${jiraBaseUrl}/browse/${jiraProjectKey}-${ticketNumber}`
}

// Confluence configuration
const confluenceEnabled = await getConfig("external_pm.confluence.enabled")
const confluenceBaseUrl = await getConfig("external_pm.confluence.base_url")
const confluenceSpaceKey = await getConfig("external_pm.confluence.space_key")

// Slack configuration
const slackEnabled = await getConfig("external_pm.slack.enabled")
const slackChannels = await getConfig("external_pm.slack.channels")  // Array
```

### Code Repository Configuration

```javascript
// Get repository type
const repoType = await getConfig("code_repository.type")  // "github", "bitbucket", "gitlab"

// BitBucket configuration
if (repoType === "bitbucket") {
  const bitbucketWorkspace = await getConfig("code_repository.bitbucket.workspace")
  const bitbucketRepoSlug = await getConfig("code_repository.bitbucket.repo_slug")
  const bitbucketBaseUrl = await getConfig("code_repository.bitbucket.base_url")

  // Example: Construct PR URL
  const prUrl = `${bitbucketBaseUrl}/pull-requests/${prNumber}`
}

// GitHub configuration
if (repoType === "github") {
  const githubOwner = await getConfig("code_repository.github.owner")
  const githubRepo = await getConfig("code_repository.github.repo")
  const githubBaseUrl = await getConfig("code_repository.github.base_url")

  // Example: Construct PR URL
  const prUrl = `${githubBaseUrl}/pull/${prNumber}`
}
```

### Quality Configuration

```javascript
// SonarQube configuration
const sonarEnabled = await getConfig("quality.sonarqube.enabled")
const sonarBaseUrl = await getConfig("quality.sonarqube.base_url")
const sonarProjectKey = await getConfig("quality.sonarqube.project_key")
const sonarThresholds = await getConfig("quality.sonarqube.thresholds")  // Object

// Code review automation
const autoReview = await getConfig("quality.code_review.auto_invoke_reviewer")
const securityScan = await getConfig("quality.code_review.security_scan")
const reviewChecklist = await getConfig("quality.code_review.checklist")  // Array
```

### Custom Commands Configuration

```javascript
// Get custom command configuration
const customCommands = await getConfig("custom_commands")  // Array

// Find specific command config
const checkPrConfig = customCommands.find(cmd => cmd.name === "check-pr")

if (checkPrConfig && checkPrConfig.enabled) {
  const browserMcp = checkPrConfig.config.browser_mcp  // "playwright" or "browser"
  const autoSyncLinear = checkPrConfig.config.auto_sync_linear  // boolean
  const generateReport = checkPrConfig.config.generate_report  // boolean
}
```

### Tech Stack Configuration

```javascript
// Get tech stack information
const languages = await getConfig("tech_stack.languages")  // Array
const frontendFrameworks = await getConfig("tech_stack.frameworks.frontend")  // Array
const backendFrameworks = await getConfig("tech_stack.frameworks.backend")  // Array
const databases = await getConfig("tech_stack.databases")  // Array
```

## Fallback Behavior

When project configuration is not found or a field is missing:

### Option 1: Use Defaults

```javascript
// Provide sensible defaults
const linearTeam = await getConfig("linear.team") || "Work"
const linearProject = await getConfig("linear.project") || "Default"
```

### Option 2: Ask User

```javascript
// If critical field missing, ask user
if (!projectConfig) {
  // Use AskUserQuestion to gather missing config
  {
    questions: [{
      question: "No project configuration found. What's the Linear team?",
      header: "Linear Team",
      multiSelect: false,
      options: [
        { label: "Work", description: "Work team" },
        { label: "Personal", description: "Personal team" }
      ]
    }]
  }
}
```

### Option 3: Error and Guide

```javascript
// For commands that require configuration
if (!projectConfig) {
  console.log(`
⚠️  No CCPM project configuration found.

To use this command, create a project configuration:

1. Copy the example:
   cp ~/.claude/plugins/ccpm/project.example.yaml .ccpm/project.yaml

2. Edit the configuration:
   code .ccpm/project.yaml

3. Update these required fields:
   - project.id
   - project.name
   - linear.team
   - linear.project

4. Run this command again

For more help: /ccpm:utils:help
  `)
  exit 1
}
```

## Dynamic Project Selection

For multi-project workspaces:

```javascript
// Let user select from available projects
// (This assumes multiple .ccpm/projects/*.yaml files)

const availableProjects = [
  { id: "my-app", name: "My App" },
  { id: "my-project", name: "My Project" },
  { id: "personal-project", name: "Personal Project" }
]

// Use AskUserQuestion
{
  questions: [{
    question: "Which project is this for?",
    header: "Project",
    multiSelect: false,
    options: availableProjects.map(p => ({
      label: p.id,
      description: p.name
    }))
  }]
}

// Load selected project config
const selectedProjectConfig = loadProjectConfig(selectedProjectId)
```

## Project Configuration in Command Arguments

Some commands accept a `<project>` argument. When project configuration exists:

### Validate Project Argument

```javascript
// Command: /ccpm:planning:create "Task title" <project> <jira-id>

// If $2 (project argument) is provided:
const providedProjectId = $2

// Validate against configuration
const configuredProjectId = await getConfig("project.id")

if (providedProjectId !== configuredProjectId) {
  console.log(`
⚠️  Warning: Project mismatch

Argument:      ${providedProjectId}
Configuration: ${configuredProjectId}

Using configuration: ${configuredProjectId}
  `)
}
```

### Use Configuration as Default

```javascript
// If project argument is optional, use config as default
const projectId = $2 || await getConfig("project.id")
```

## Examples

### Example 1: Create Linear Issue with Config

```javascript
// Load configuration
const linearTeam = await getConfig("linear.team")
const linearProject = await getConfig("linear.project")
const defaultLabels = await getConfig("linear.default_labels")

// Create issue
const issue = await mcp__linear__create_issue({
  team: linearTeam,
  project: linearProject,
  title: "Implement feature",
  description: "...",
  labels: defaultLabels,
  state: await getConfig("linear.workflow_states.backlog")
})

console.log(`✅ Created issue: ${issue.identifier}`)
```

### Example 2: Check PR with Project-Specific Settings

```javascript
// Load PR check configuration
const checkPrConfig = (await getConfig("custom_commands")).find(cmd => cmd.name === "check-pr")

// Use project-specific browser MCP
const browserMcp = checkPrConfig?.config?.browser_mcp || "playwright"

// Construct BitBucket URL from config
const bitbucketBaseUrl = await getConfig("code_repository.bitbucket.base_url")
const prUrl = $1.startsWith('http')
  ? $1
  : `${bitbucketBaseUrl}/pull-requests/${$1}`

// Auto-sync to Linear if configured
const autoSync = checkPrConfig?.config?.auto_sync_linear || false
```

### Example 3: Sync Jira Status to Linear

```javascript
// Check if Jira sync is enabled
const jiraEnabled = await getConfig("external_pm.jira.enabled")

if (jiraEnabled) {
  // Get status mapping
  const statusMapping = await getConfig("automation.jira_sync.status_mapping")

  // Map Jira status to Linear status
  const jiraStatus = "In Progress"
  const linearStatus = statusMapping[jiraStatus] || "In Progress"

  // Update Linear
  await mcp__linear__update_issue({
    id: linearIssueId,
    state: linearStatus
  })
}
```

## Best Practices

1. **Always validate configuration exists** before using critical fields
2. **Provide helpful error messages** when configuration is missing
3. **Use sensible defaults** for non-critical fields
4. **Cache configuration** in a variable to avoid repeated reads
5. **Document which config fields your command uses** in the command description
6. **Test with and without configuration** to ensure graceful fallback

## Configuration Caching Pattern

For commands that read config multiple times:

```bash
# At the start of your command, load once and cache
CONFIG_JSON=$(./scripts/load-project-config.sh --json 2>/dev/null || echo "{}")

# Then extract values as needed
PROJECT_ID=$(echo "$CONFIG_JSON" | jq -r '.project.id // "default"')
LINEAR_TEAM=$(echo "$CONFIG_JSON" | jq -r '.linear.team // "Work"')
LINEAR_PROJECT=$(echo "$CONFIG_JSON" | jq -r '.linear.project // "Default"')
```

This is more efficient than calling the script multiple times.
