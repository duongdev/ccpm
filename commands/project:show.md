---
description: Show detailed configuration for a specific project
allowed-tools: [Bash, Read]
argument-hint: <project-id>
---

# Show Project Details

Display complete configuration for a specific CCPM project.

## Arguments

- **$1** - Project ID (required)

## Usage

```bash
/ccpm:project:show my-app
```

## Workflow

### Step 1: Validate Arguments

```javascript
const projectId = $1

if (!projectId) {
  console.log("❌ Error: Project ID required")
  console.log("Usage: /ccpm:project:show <project-id>")
  console.log("")
  console.log("Available projects:")
  console.log("  /ccpm:project:list")
  exit(1)
}
```

### Step 2: Load Project Configuration

```bash
CONFIG_FILE="$HOME/.claude/ccpm-config.yaml"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Error: No CCPM configuration found"
  echo ""
  echo "Create configuration:"
  echo "  /ccpm:project:add <project-id>"
  exit(1)
fi

# Check if project exists
if ! yq eval ".projects.$PROJECT_ID" "$CONFIG_FILE" > /dev/null 2>&1; then
  echo "❌ Error: Project '$PROJECT_ID' not found"
  echo ""
  echo "Available projects:"
  yq eval '.projects | keys | .[]' "$CONFIG_FILE"
  echo ""
  echo "Add new project:"
  echo "  /ccpm:project:add $PROJECT_ID"
  exit(1)
fi

# Load project config
PROJECT_CONFIG=$(yq eval ".projects.$PROJECT_ID" "$CONFIG_FILE" -o=json)
```

### Step 3: Display Complete Configuration

```javascript
const config = JSON.parse(PROJECT_CONFIG)
const isActive = await isActiveProject(projectId)

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Project: ${projectId} ${isActive ? "⭐ (Active)" : ""}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Project Information

Name:         ${config.name}
Description:  ${config.description || "N/A"}
Owner:        ${config.owner || "N/A"}

Repository:
  URL:          ${config.repository?.url || "N/A"}
  Branch:       ${config.repository?.default_branch || "main"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Linear Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Team:         ${config.linear.team}
Project:      ${config.linear.project}
Labels:       ${config.linear.default_labels?.join(", ") || "N/A"}

Workflow States:
  Backlog:      ${config.linear.workflow_states?.backlog || "Backlog"}
  Planning:     ${config.linear.workflow_states?.planning || "Planning"}
  In Progress:  ${config.linear.workflow_states?.in_progress || "In Progress"}
  In Review:    ${config.linear.workflow_states?.in_review || "In Review"}
  Done:         ${config.linear.workflow_states?.done || "Done"}
  Canceled:     ${config.linear.workflow_states?.canceled || "Canceled"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## External PM Integration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:       ${config.external_pm.enabled ? "✅ Enabled" : "❌ Disabled"}
Type:         ${config.external_pm.type}
`)

if (config.external_pm.enabled && config.external_pm.jira?.enabled) {
  console.log(`
### Jira
  Enabled:      ✅
  Base URL:     ${config.external_pm.jira.base_url}
  Project Key:  ${config.external_pm.jira.project_key}
  Ticket URL:   ${config.external_pm.jira.base_url}/browse/${config.external_pm.jira.project_key}-XXX
  `)
}

if (config.external_pm.enabled && config.external_pm.confluence?.enabled) {
  console.log(`
### Confluence
  Enabled:      ✅
  Base URL:     ${config.external_pm.confluence.base_url}
  Space Key:    ${config.external_pm.confluence.space_key}
  Space URL:    ${config.external_pm.confluence.base_url}/display/${config.external_pm.confluence.space_key}
  `)
}

if (config.external_pm.enabled && config.external_pm.slack?.enabled) {
  console.log(`
### Slack
  Enabled:      ✅
  Workspace:    ${config.external_pm.slack.workspace}
  Channels:
  `)

  config.external_pm.slack.channels?.forEach(channel => {
    console.log(`    - ${channel.name} (${channel.id})`)
  })
}

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Code Repository
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type:         ${config.code_repository.type}
`)

if (config.code_repository.type === "github" && config.code_repository.github?.enabled) {
  console.log(`
### GitHub
  Owner:        ${config.code_repository.github.owner}
  Repository:   ${config.code_repository.github.repo}
  URL:          https://github.com/${config.code_repository.github.owner}/${config.code_repository.github.repo}
  `)
}

if (config.code_repository.type === "bitbucket" && config.code_repository.bitbucket?.enabled) {
  console.log(`
### BitBucket
  Workspace:    ${config.code_repository.bitbucket.workspace}
  Repository:   ${config.code_repository.bitbucket.repo_slug}
  URL:          ${config.code_repository.bitbucket.base_url}
  `)
}

if (config.quality?.sonarqube?.enabled) {
  console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Quality Gates
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### SonarQube
  Enabled:      ✅
  Base URL:     ${config.quality.sonarqube.base_url}
  Project Key:  ${config.quality.sonarqube.project_key}
  Project URL:  ${config.quality.sonarqube.base_url}/dashboard?id=${config.quality.sonarqube.project_key}

  Thresholds:
    Coverage:     ${config.quality.sonarqube.thresholds?.coverage || "N/A"}%
    Duplications: ${config.quality.sonarqube.thresholds?.duplications || "N/A"}%
  `)
}

if (config.tech_stack) {
  console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Tech Stack
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Languages:    ${config.tech_stack.languages?.join(", ") || "N/A"}

Frameworks:
  Frontend:   ${config.tech_stack.frameworks?.frontend?.join(", ") || "N/A"}
  Backend:    ${config.tech_stack.frameworks?.backend?.join(", ") || "N/A"}
  Testing:    ${config.tech_stack.frameworks?.testing?.join(", ") || "N/A"}

Databases:    ${config.tech_stack.databases?.join(", ") || "N/A"}
  `)
}

if (config.custom_commands && config.custom_commands.length > 0) {
  console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Custom Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  `)

  config.custom_commands.forEach(cmd => {
    console.log(`
### ${cmd.name}
  Enabled:      ${cmd.enabled ? "✅" : "❌"}
  Category:     ${cmd.category || "N/A"}
  Command:      /ccpm:${projectId}:${cmd.name}
    `)

    if (cmd.config) {
      console.log("  Configuration:")
      Object.entries(cmd.config).forEach(([key, value]) => {
        console.log(`    ${key}: ${value}`)
      })
    }
  })
}

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Quick Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Update configuration:  /ccpm:project:update ${projectId}
Delete project:        /ccpm:project:delete ${projectId}
${!isActive ? `Set as active:         /ccpm:project:set ${projectId}` : ""}

Create task:           /ccpm:planning:create "Task title" ${projectId}
List all projects:     /ccpm:project:list

Configuration file:    ~/.claude/ccpm-config.yaml

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)
```

## Examples

### Example 1: Show full-stack project

```bash
/ccpm:project:show my-app

# Output shows:
# - Complete Linear configuration
# - Jira/Confluence/Slack settings
# - GitHub repository details
# - Quality gate thresholds
# - Tech stack information
```

### Example 2: Show simple project

```bash
/ccpm:project:show personal-project

# Output shows:
# - Linear-only configuration
# - No external PM integration
# - GitHub repository
# - Simplified workflow settings
```

## Notes

- Shows complete configuration for debugging
- All URLs are clickable in supported terminals
- Active project is marked with ⭐
- Use `/ccpm:project:update` to modify settings
- Configuration file: `~/.claude/ccpm-config.yaml`
