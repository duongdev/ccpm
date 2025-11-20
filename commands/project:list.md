---
description: List all configured CCPM projects
---

# List CCPM Projects

Display all projects configured in `~/.claude/ccpm-config.yaml` with active project detection including subdirectory/subproject context.

## Usage

```bash
/ccpm:project:list
```

## Workflow

### Step 1: Auto-Activate Skills

```markdown
# Skills auto-activate for guidance
Skill(project-detection): Provides detection workflow
Skill(project-operations): Provides display format guidance
```

### Step 2: Get Active Project Context

Use the project-context-manager agent to detect the active project:

```javascript
const activeContext = Task(project-context-manager): `
Get active project context
Include detection method
Format: compact
`

// activeContext contains:
// - project_id (or null if not detected)
// - subproject (or null if not in subdirectory)
// - detection_method (git_remote, subdirectory, local_path, etc.)
```

### Step 3: List All Projects

Use the project-config-loader agent to get all projects:

```javascript
const allProjects = Task(project-config-loader): `
Load all project configurations
Return summary list with names and descriptions
Validate: false
`

if (allProjects.error?.code === 'CONFIG_NOT_FOUND') {
  console.log("⚠️  No CCPM configuration found")
  console.log("")
  console.log("Create configuration:")
  console.log("  /ccpm:project:add <project-id>")
  exit(0)
}

if (Object.keys(allProjects.projects).length === 0) {
  console.log("📋 No projects configured yet")
  console.log("")
  console.log("Add your first project:")
  console.log("  /ccpm:project:add <project-id>")
  exit(0)
}
```

### Step 4: Display Project List

Sort projects with active first, then alphabetically:

```javascript
const projects = allProjects.projects
const projectIds = Object.keys(projects)

// Sort: active first, then alphabetically
projectIds.sort((a, b) => {
  if (activeContext?.project_id === a) return -1
  if (activeContext?.project_id === b) return 1
  return a.localeCompare(b)
})

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 CCPM Projects (${projectIds.length})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)

for (const projectId of projectIds) {
  const config = projects[projectId]
  const isActive = activeContext?.project_id === projectId
  const activeIndicator = isActive ? "⭐" : "  "

  // Build project title with subproject if applicable
  let projectTitle = projectId
  if (isActive && activeContext.subproject) {
    projectTitle = `${projectId} › ${activeContext.subproject}`
  }

  console.log(`
${activeIndicator} ${projectTitle}
   Name:        ${config.name}
   Description: ${config.description || "N/A"}
   Linear:      ${config.linear.team} / ${config.linear.project}
   Repo Type:   ${config.code_repository?.type || "N/A"}
   External PM: ${config.external_pm?.enabled ? config.external_pm.type : "disabled"}`)

  // Show subproject info for active project
  if (isActive && activeContext.subproject) {
    const subprojectConfig = config.code_repository?.subprojects?.find(
      s => s.name === activeContext.subproject
    )
    if (subprojectConfig) {
      console.log(`   Subproject:  📁 ${subprojectConfig.path}`)
      const techStack = subprojectConfig.tech_stack
      if (techStack) {
        const langs = techStack.languages?.join(", ") || ""
        const frameworks = Object.values(techStack.frameworks || {}).flat().join(", ")
        console.log(`   Tech Stack:  ${[langs, frameworks].filter(Boolean).join(", ")}`)
      }
    }
  }

  if (isActive) {
    const detectionMethod = activeContext.detection_method || "unknown"
    const methodDisplay = {
      'manual': 'Manual setting',
      'git_remote': 'Git remote match',
      'subdirectory': 'Subdirectory match',
      'local_path': 'Local path match',
      'pattern': 'Custom pattern match'
    }[detectionMethod] || detectionMethod
    console.log(`   Status:      🟢 Active (${methodDisplay})`)
  }

  console.log("")
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

**Example 1: Simple Project (no subdirectories)**

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
   Status:      🟢 Active (Git remote match)

   Commands:
     View details:  /ccpm:project:show my-app
     Update config: /ccpm:project:update my-app
     Delete:        /ccpm:project:delete my-app
     Set active:    /ccpm:project:set my-app

   my-project
   Name:        My Project
   Description: Another example project
   Linear:      Work / My Project
   Repo Type:   bitbucket
   External PM: jira

   Commands:
     View details:  /ccpm:project:show my-project
     Update config: /ccpm:project:update my-project
     Delete:        /ccpm:project:delete my-project
     Set active:    /ccpm:project:set my-project

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Example 2: Monorepo with Active Subproject**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 CCPM Projects (2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⭐ repeat › jarvis
   Name:        Repeat
   Description: Repeat.gg gaming platform - multi-project repository
   Linear:      Work / Repeat
   Repo Type:   bitbucket
   External PM: jira
   Subproject:  📁 jarvis
   Tech Stack:  typescript, nextjs, react, nestjs
   Status:      🟢 Active (Subdirectory match)

   Commands:
     View details:  /ccpm:project:show repeat
     Update config: /ccpm:project:update repeat
     Delete:        /ccpm:project:delete repeat
     Set active:    /ccpm:project:set repeat

   nv-internal
   Name:        NV Internal
   Description: Task management application
   Linear:      Personal / NV Internal
   Repo Type:   github
   External PM: disabled

   Commands:
     View details:  /ccpm:project:show nv-internal
     Update config: /ccpm:project:update nv-internal
     Delete:        /ccpm:project:delete nv-internal
     Set active:    /ccpm:project:set nv-internal

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

The command uses the `project-context-manager` agent to automatically detect the active project by:

**Detection Priority Order**:
1. **Manual override** - User-set active project (highest priority)
2. **Git remote URL** - Matches repository URL in config
3. **Subdirectory patterns** - Matches working directory against configured patterns (NEW)
4. **Local path** - Matches current directory path
5. **Custom patterns** - User-defined glob patterns

**Subdirectory Detection** (NEW):
- For monorepos, detects which subproject you're currently in
- Displays as: `project-name › subproject-name`
- Shows subproject path and tech stack
- Detection method shown as "Subdirectory match"

**Example**:
```bash
# Working in /Users/dev/repeat/jarvis/src
# Detects: project="repeat", subproject="jarvis"
# Displays: ⭐ repeat › jarvis
```

The active project is marked with ⭐ and always appears first in the list.

## Agent Integration

This command uses CCPM agents for efficient operation:

- **project-context-manager**: Detects active project and subproject
- **project-config-loader**: Loads all project configurations
- **project-detection skill**: Auto-activates for detection guidance
- **project-operations skill**: Provides display format guidance

Token usage: ~200 tokens (vs ~2000 with inline logic)

## Notes

- Projects are listed with active first, then alphabetically
- Active project shows detection method (git remote, subdirectory, etc.)
- Subproject information shown only for active monorepo projects
- Use `/ccpm:project:show <id>` for full details including all subprojects
- Configuration file: `~/.claude/ccpm-config.yaml`
