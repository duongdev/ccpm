---
description: List all configured CCPM projects
allowed-tools: [Bash, Read]
---

# List CCPM Projects

Display all projects configured in `~/.claude/ccpm-config.yaml`.

## Usage

```bash
/ccpm:project:list
```

## Workflow

### Step 1: Check Configuration Exists

```bash
CONFIG_FILE="$HOME/.claude/ccpm-config.yaml"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "⚠️  No CCPM configuration found"
  echo ""
  echo "Create configuration:"
  echo "  /ccpm:project:add <project-id>"
  echo ""
  echo "Or copy example:"
  echo "  cp ~/.claude/plugins/ccpm/ccpm-config.example.yaml ~/.claude/ccpm-config.yaml"
  exit 0
fi
```

### Step 2: Load and Display Projects

```bash
# Get all project IDs
PROJECT_IDS=$(yq eval '.projects | keys | .[]' "$CONFIG_FILE")

if [[ -z "$PROJECT_IDS" ]]; then
  echo "📋 No projects configured yet"
  echo ""
  echo "Add your first project:"
  echo "  /ccpm:project:add <project-id>"
  exit 0
fi
```

### Step 3: Display Project List

For each project, show summary information:

```javascript
const projects = await yq('.projects', CONFIG_FILE)

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 CCPM Projects (${Object.keys(projects).length})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)

for (const [projectId, config] of Object.entries(projects)) {
  const isActive = await isActiveProject(projectId)
  const activeIndicator = isActive ? "⭐" : "  "

  console.log(`
${activeIndicator} ${projectId}
   Name:        ${config.name}
   Description: ${config.description || "N/A"}
   Linear:      ${config.linear.team} / ${config.linear.project}
   Repo Type:   ${config.code_repository.type}
   External PM: ${config.external_pm.enabled ? config.external_pm.type : "disabled"}
   ${isActive ? "Status:      🟢 Active (auto-detected)" : ""}
  `)

  console.log("   Commands:")
  console.log(`     View details:  /ccpm:project:show ${projectId}`)
  console.log(`     Update config: /ccpm:project:update ${projectId}`)
  console.log(`     Delete:        /ccpm:project:delete ${projectId}`)
  console.log(`     Set active:    /ccpm:project:set ${projectId}`)
  console.log("")
}

console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
```

### Step 4: Show Quick Actions

```plaintext
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Quick Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Add new project:     /ccpm:project:add <project-id>
Show project info:   /ccpm:project:show <project-id>
Update project:      /ccpm:project:update <project-id>
Delete project:      /ccpm:project:delete <project-id>

Configuration file:  ~/.claude/ccpm-config.yaml

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Output Format

### Compact View (default)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 CCPM Projects (3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⭐ my-app
   Name:        My App
   Description: Example application with full PM integration
   Linear:      Work / My App
   Repo Type:   github
   External PM: jira
   Status:      🟢 Active (auto-detected)

   my-project
   Name:        My Project
   Description: Another example project
   Linear:      Work / My Project
   Repo Type:   bitbucket
   External PM: jira

   personal-project
   Name:        Personal Project
   Description: Simple Linear-only project
   Linear:      Personal / Personal Project
   Repo Type:   github
   External PM: disabled

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Detailed View (with --detailed flag)

Shows complete configuration for each project including:
- All Linear settings
- External PM details (Jira, Confluence, Slack)
- Code repository configuration
- Tech stack
- Custom commands
- Quality gates

## Active Project Detection

The command automatically detects the active project by:

1. **Git remote URL** - Matches repository URL in config
2. **Current working directory** - Matches path patterns
3. **Manual override** - User-set active project

The active project is marked with ⭐.

## Notes

- Projects are listed alphabetically by ID
- Active project (if detected) appears first
- Use `/ccpm:project:show <id>` for full details
- Configuration file: `~/.claude/ccpm-config.yaml`
