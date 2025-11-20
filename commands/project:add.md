---
description: Add a new project to CCPM configuration
allowed-tools: [Bash, Read, Write, Edit, AskUserQuestion]
argument-hint: <project-id> [--template TEMPLATE]
---

# Add New Project to CCPM

Add a new project configuration to `~/.claude/ccpm-config.yaml`.

## Arguments

- **$1** - Project ID (required, e.g., "my-app", "acme-platform")
- **--template** - Use a template (optional: "fullstack-with-jira", "simple-linear", "open-source")

## Workflow

### Step 1: Validate Project ID

```javascript
const projectId = $1

if (!projectId) {
  console.log("❌ Error: Project ID required")
  console.log("Usage: /ccpm:project:add <project-id> [--template TEMPLATE]")
  exit(1)
}

// Validate format (lowercase, hyphens only)
if (!/^[a-z0-9-]+$/.test(projectId)) {
  console.log("❌ Error: Invalid project ID format")
  console.log("Project ID must be lowercase with hyphens only (e.g., 'my-app')")
  exit(1)
}
```

### Step 2: Check if Configuration Exists

```bash
CONFIG_FILE="$HOME/.claude/ccpm-config.yaml"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "📝 No CCPM configuration found. Creating new one..."

  # Create from example
  cp "$HOME/.claude/plugins/ccpm/ccpm-config.example.yaml" "$CONFIG_FILE"

  echo "✅ Created $CONFIG_FILE"
fi
```

### Step 3: Check if Project Already Exists

```bash
# Use yq to check if project exists
if yq eval ".projects.$PROJECT_ID" "$CONFIG_FILE" > /dev/null 2>&1; then
  EXISTING=$(yq eval ".projects.$PROJECT_ID.name" "$CONFIG_FILE")

  if [[ "$EXISTING" != "null" ]]; then
    echo "⚠️  Project '$PROJECT_ID' already exists: $EXISTING"
    echo ""
    echo "Options:"
    echo "  1. Update existing project: /ccpm:project:update $PROJECT_ID"
    echo "  2. Delete and recreate: /ccpm:project:delete $PROJECT_ID"
    echo "  3. Choose different ID: /ccpm:project:add <different-id>"
    exit 1
  fi
fi
```

### Step 4: Gather Project Information

Use **AskUserQuestion** to gather project details:

```javascript
{
  questions: [
    {
      question: "What type of project is this?",
      header: "Project Type",
      multiSelect: false,
      options: [
        {
          label: "Full-stack with Jira",
          description: "Jira, Confluence, Slack integration (template: fullstack-with-jira)"
        },
        {
          label: "Simple Linear-only",
          description: "Linear tracking only, no external PM (template: simple-linear)"
        },
        {
          label: "Open Source",
          description: "GitHub-based open source project (template: open-source)"
        },
        {
          label: "Custom",
          description: "Configure from scratch"
        }
      ]
    },
    {
      question: "What's the project name (human-readable)?",
      header: "Project Name",
      multiSelect: false,
      options: [
        {
          label: "Enter manually",
          description: "Type the project name"
        }
      ]
    },
    {
      question: "Which Linear team should this project use?",
      header: "Linear Team",
      multiSelect: false,
      options: [
        {
          label: "Work",
          description: "Work-related projects"
        },
        {
          label: "Personal",
          description: "Personal projects"
        },
        {
          label: "Other",
          description: "Specify custom team"
        }
      ]
    },
    {
      question: "What's the code repository type?",
      header: "Repository",
      multiSelect: false,
      options: [
        {
          label: "GitHub",
          description: "GitHub repository"
        },
        {
          label: "BitBucket",
          description: "BitBucket repository"
        },
        {
          label: "GitLab",
          description: "GitLab repository"
        }
      ]
    }
  ]
}
```

Store answers:
- `projectType` → template to use
- `projectName` → human-readable name
- `linearTeam` → Linear team
- `repoType` → repository type

### Step 5: Gather Additional Details Based on Type

#### If "Full-stack with Jira" selected:

```javascript
{
  questions: [
    {
      question: "What's your Jira project key? (e.g., PROJ)",
      header: "Jira Key",
      multiSelect: false,
      options: [
        {
          label: "Enter manually",
          description: "Type the Jira project key"
        }
      ]
    },
    {
      question: "What's your Confluence space key?",
      header: "Confluence",
      multiSelect: false,
      options: [
        {
          label: "Same as Jira",
          description: "Use same key as Jira project"
        },
        {
          label: "Enter manually",
          description: "Type the Confluence space key"
        }
      ]
    },
    {
      question: "What's your primary Slack channel?",
      header: "Slack Channel",
      multiSelect: false,
      options: [
        {
          label: "Enter manually",
          description: "e.g., #project-dev"
        }
      ]
    }
  ]
}
```

#### If GitHub/BitBucket/GitLab selected:

```javascript
{
  questions: [
    {
      question: `What's your ${repoType} repository? (format: owner/repo)`,
      header: "Repository",
      multiSelect: false,
      options: [
        {
          label: "Enter manually",
          description: "e.g., company/project-name"
        }
      ]
    }
  ]
}
```

### Step 6: Build Project Configuration

```javascript
// Start with template or empty config
let projectConfig = {}

if (projectType !== "Custom") {
  // Load template from global config
  const template = await yq(".templates.${templateName}", CONFIG_FILE)
  projectConfig = { ...template }
}

// Set basic fields
projectConfig.name = projectName
projectConfig.description = projectDescription || `${projectName} project`
projectConfig.owner = projectOwner || "Engineering Team"

// Repository
projectConfig.repository = {
  url: repositoryUrl,
  default_branch: "main"
}

// Linear configuration
projectConfig.linear = {
  team: linearTeam,
  project: projectName,
  default_labels: [projectId, "planning"]
}

// External PM (if applicable)
if (jiraEnabled) {
  projectConfig.external_pm = {
    enabled: true,
    type: "jira",
    jira: {
      enabled: true,
      base_url: jiraBaseUrl || "https://jira.company.com",
      project_key: jiraProjectKey
    },
    confluence: {
      enabled: confluenceEnabled,
      base_url: confluenceBaseUrl || "https://confluence.company.com",
      space_key: confluenceSpaceKey || jiraProjectKey
    },
    slack: {
      enabled: slackEnabled,
      workspace: slackWorkspace || "company-workspace",
      channels: [
        {
          name: slackChannel,
          id: slackChannelId || "C0XXXXXXX"
        }
      ]
    }
  }
} else {
  projectConfig.external_pm = {
    enabled: false,
    type: "linear-only"
  }
}

// Code repository
if (repoType === "github") {
  const [owner, repo] = repoUrl.split("/")
  projectConfig.code_repository = {
    type: "github",
    github: {
      enabled: true,
      owner: owner,
      repo: repo
    }
  }
} else if (repoType === "bitbucket") {
  const [workspace, repoSlug] = repoUrl.split("/")
  projectConfig.code_repository = {
    type: "bitbucket",
    bitbucket: {
      enabled: true,
      workspace: workspace,
      repo_slug: repoSlug,
      base_url: `https://bitbucket.org/${workspace}/${repoSlug}`
    }
  }
}

// Tech stack (ask for details)
projectConfig.tech_stack = {
  languages: techLanguages || ["typescript"],
  frameworks: {
    frontend: frontendFrameworks || [],
    backend: backendFrameworks || []
  }
}
```

### Step 7: Show Configuration Preview

```yaml
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 New Project Configuration Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project ID:   ${projectId}
Name:         ${projectName}
Description:  ${projectDescription}

Linear:
  Team:       ${linearTeam}
  Project:    ${projectName}
  Labels:     [${projectLabels.join(", ")}]

${jiraEnabled ? `
External PM:
  Jira:       ${jiraProjectKey}
  Confluence: ${confluenceSpaceKey}
  Slack:      ${slackChannel}
` : `
External PM:  Linear-only (no external integration)
`}

Repository:
  Type:       ${repoType}
  ${repoType === "github" ? `Owner/Repo: ${owner}/${repo}` : `Workspace/Repo: ${workspace}/${repoSlug}`}

Tech Stack:
  Languages:  ${languages.join(", ")}
  Frontend:   ${frontendFrameworks.join(", ") || "N/A"}
  Backend:    ${backendFrameworks.join(", ") || "N/A"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 8: Confirm and Save

```javascript
{
  questions: [{
    question: "Add this project to CCPM configuration?",
    header: "Confirm",
    multiSelect: false,
    options: [
      {
        label: "Yes, add it",
        description: "Save configuration to ~/.claude/ccpm-config.yaml"
      },
      {
        label: "Edit details",
        description: "Go back and modify configuration"
      },
      {
        label: "Cancel",
        description: "Don't add project"
      }
    ]
  }]
}
```

If confirmed:

```bash
# Add project to configuration using yq
yq eval -i ".projects.$PROJECT_ID = $PROJECT_CONFIG_JSON" "$CONFIG_FILE"

echo ""
echo "✅ Project added successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. View configuration:"
echo "   /ccpm:project:list"
echo ""
echo "2. Set as active project (if in project directory):"
echo "   /ccpm:project:set $PROJECT_ID"
echo ""
echo "3. Create your first task:"
echo "   /ccpm:planning:create \"Task title\" $PROJECT_ID"
echo ""
echo "4. Edit configuration anytime:"
echo "   /ccpm:project:update $PROJECT_ID"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

## Examples

### Example 1: Add with template

```bash
/ccpm:project:add my-app --template simple-linear

# Will prompt for:
# - Project name
# - Linear team
# - Repository details
```

### Example 2: Add full-stack project

```bash
/ccpm:project:add acme-platform

# Interactive prompts will guide you through:
# - Project type selection (choose "Full-stack with Jira")
# - Jira/Confluence/Slack configuration
# - Repository setup
# - Tech stack details
```

### Example 3: Add personal project

```bash
/ccpm:project:add my-side-project --template open-source

# Quick setup for personal/open-source projects
```

## Notes

- Configuration is stored in `~/.claude/ccpm-config.yaml`
- You can manually edit this file later
- Templates provide quick starting points
- All fields can be customized after creation
- Use `/ccpm:project:update` to modify existing projects
