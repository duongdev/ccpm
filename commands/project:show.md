---
description: Show detailed configuration for a specific project
argument-hint: <project-id>
---

# Show Project Details

Display complete configuration for a specific CCPM project, including subdirectory/subproject information for monorepos.

## Arguments

- **$1** - Project ID (required)

## Usage

```bash
/ccpm:project:show my-app
/ccpm:project:show repeat  # Shows all subprojects in monorepo
```

## Workflow

### Step 1: Auto-Activate Skills

```markdown
Skill(project-operations): Provides display format guidance
Skill(project-detection): Helps with detection context
```

### Step 2: Validate Arguments

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

### Step 3: Load Project Configuration

Use project-config-loader agent:

```javascript
const projectConfig = Task(project-config-loader): `
Load configuration for project: ${projectId}
Include all sections: true
Validate: true
`

if (projectConfig.error) {
  if (projectConfig.error.code === 'PROJECT_NOT_FOUND') {
    console.log(`❌ Error: Project '${projectId}' not found`)
    console.log("")
    console.log("Available projects:")
    projectConfig.error.available_projects.forEach(p => console.log(`  - ${p}`))
    console.log("")
    console.log("View all: /ccpm:project:list")
    exit(1)
  }

  console.error(`❌ Error: ${projectConfig.error.message}`)
  exit(1)
}
```

### Step 4: Check if Active

Use project-context-manager to check if this is the active project:

```javascript
const activeContext = Task(project-context-manager): `
Get active project context
Format: compact
`

const isActive = activeContext?.project_id === projectId
const activeSubproject = isActive ? activeContext.subproject : null
```

### Step 5: Display Complete Configuration

```javascript
const config = projectConfig

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Project: ${projectId} ${isActive ? "⭐ (Active)" : ""}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Project Information

Name:         ${config.project_name}
Description:  ${config.description || "N/A"}
Owner:        ${config.owner || "N/A"}

Repository:
  URL:          ${config.repository.url || "N/A"}
  Branch:       ${config.repository.default_branch}
  Local Path:   ${config.repository.local_path || "N/A"}

${isActive ? `
Detection:
  Method:       ${activeContext.detection_method}
  ${activeSubproject ? `Subproject:   ${activeSubproject}` : ""}
` : ""}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Linear Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Team:         ${config.linear.team}
Project:      ${config.linear.project}
Labels:       ${config.linear.default_labels?.join(", ") || "N/A"}

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
  `)
}

if (config.external_pm.enabled && config.external_pm.confluence?.enabled) {
  console.log(`
### Confluence
  Enabled:      ✅
  Base URL:     ${config.external_pm.confluence.base_url}
  Space Key:    ${config.external_pm.confluence.space_key}
  `)
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
  URL:          ${config.code_repository.bitbucket.base_url}
  `)
}

// NEW: Display subprojects if configured
if (config.code_repository.subprojects && config.code_repository.subprojects.length > 0) {
  console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Subprojects (Monorepo) ${activeSubproject ? `⭐ Active: ${activeSubproject}` : ""}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)

  config.code_repository.subprojects.forEach(subproject => {
    const isActiveSub = activeSubproject === subproject.name
    const indicator = isActiveSub ? "⭐" : "  "

    console.log(`
${indicator} ${subproject.name}
   Description:  ${subproject.description || "N/A"}
   Path:         📁 ${subproject.path}`)

    if (subproject.tech_stack) {
      const langs = subproject.tech_stack.languages?.join(", ") || ""
      if (langs) console.log(`   Languages:    ${langs}`)

      if (subproject.tech_stack.frameworks) {
        const frameworks = Object.entries(subproject.tech_stack.frameworks)
          .map(([type, fws]) => `${type}: ${fws.join(", ")}`)
          .join(", ")
        if (frameworks) console.log(`   Frameworks:   ${frameworks}`)
      }

      const dbs = subproject.tech_stack.database?.join(", ") || ""
      if (dbs) console.log(`   Database:     ${dbs}`)
    }

    console.log("")
  })

  console.log(`
Subdirectory Detection:
  Configured:   ${config.context?.detection?.subdirectories ? "✅ Yes" : "❌ No"}
`)

  if (config.context?.detection?.subdirectories) {
    console.log("  Patterns:")
    config.context.detection.subdirectories.forEach(pattern => {
      console.log(`    - ${pattern.match_pattern} → ${pattern.subproject} (priority: ${pattern.priority || 0})`)
    })
  }
}

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Tech Stack (Overall)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)

if (config.tech_stack.languages) {
  console.log(`Languages:    ${config.tech_stack.languages.join(", ")}`)
}

if (config.tech_stack.frameworks) {
  if (config.tech_stack.frameworks.frontend) {
    console.log(`Frontend:     ${config.tech_stack.frameworks.frontend.join(", ")}`)
  }
  if (config.tech_stack.frameworks.backend) {
    console.log(`Backend:      ${config.tech_stack.frameworks.backend.join(", ")}`)
  }
}

if (config.tech_stack.database) {
  console.log(`Database:     ${config.tech_stack.database.join(", ")}`)
}

if (config.tech_stack.infrastructure) {
  console.log(`Infra:        ${config.tech_stack.infrastructure.join(", ")}`)
}

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Set as active:     /ccpm:project:set ${projectId}
Update config:     /ccpm:project:update ${projectId}
Delete project:    /ccpm:project:delete ${projectId}
List all:          /ccpm:project:list

${config.code_repository.subprojects && config.code_repository.subprojects.length > 0 ? `
For subdirectory detection to work:
1. Navigate to a subproject directory
2. CCPM will auto-detect the active subproject
3. All commands will use that context
` : ""}

Configuration file: ~/.claude/ccpm-config.yaml

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)
```

## Agent Integration

This command uses CCPM agents:

- **project-config-loader**: Loads and validates project configuration
- **project-context-manager**: Checks if project is currently active
- **project-operations skill**: Provides display format guidance
- **project-detection skill**: Auto-activates for context awareness

Token usage: ~200 tokens (vs ~2000 with inline logic)

## Example Output

### Simple Project

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Project: my-app ⭐ (Active)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Project Information

Name:         My App
Description:  Example application
Owner:        john.doe

Repository:
  URL:          https://github.com/org/my-app
  Branch:       main
  Local Path:   /Users/dev/my-app

Detection:
  Method:       git_remote

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Linear Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Team:         Engineering
Project:      My App
Labels:       my-app, planning

[... rest of configuration ...]
```

### Monorepo with Subprojects

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Project: repeat ⭐ (Active)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Project Information

Name:         Repeat
Description:  Repeat.gg gaming platform - multi-project repository
Owner:        duongdev

Repository:
  URL:          https://bitbucket.org/repeatgg/repeat
  Branch:       develop
  Local Path:   /Users/duongdev/repeat

Detection:
  Method:       subdirectory
  Subproject:   jarvis

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Subprojects (Monorepo) ⭐ Active: jarvis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   xygaming_symfony
   Description:  Legacy Symfony 4.4 PHP web application
   Path:         📁 xygaming_symfony
   Languages:    php
   Frameworks:   backend: symfony
   Database:     mysql, redis

⭐ jarvis
   Description:  Modern admin web application (TurboRepo)
   Path:         📁 jarvis
   Languages:    typescript
   Frameworks:   frontend: nextjs, react, backend: nestjs
   Database:     mysql, prisma

   repeat-mobile-app
   Description:  React Native mobile application
   Path:         📁 repeat-mobile-app
   Languages:    typescript, javascript
   Frameworks:   frontend: react-native, expo

   messaging
   Description:  Node.js microservice
   Path:         📁 messaging
   Languages:    javascript, typescript
   Frameworks:   backend: nodejs

Subdirectory Detection:
  Configured:   ✅ Yes
  Patterns:
    - */xygaming_symfony/* → xygaming_symfony (priority: 10)
    - */jarvis/* → jarvis (priority: 10)
    - */repeat-mobile-app/* → repeat-mobile-app (priority: 10)
    - */messaging/* → messaging (priority: 10)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Tech Stack (Overall)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Languages:    php, typescript, javascript
Frontend:     nextjs, react, react-native
Backend:      symfony, nestjs, nodejs
Database:     mysql, redis
Infra:        aws-ecs, aws-s3, aws-ssm, firebase, kafka

[... rest of configuration ...]
```

## Notes

- **NEW**: Displays all subprojects in monorepo configuration
- **NEW**: Shows active subproject with ⭐ marker
- **NEW**: Displays subdirectory detection patterns
- **NEW**: Shows tech stack per subproject
- Uses agents for efficient configuration loading
- Validates project exists before displaying
- Provides actionable quick commands
