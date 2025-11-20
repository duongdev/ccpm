---
description: List all subdirectories/subprojects configured for a project
argument-hint: <project-id>
---

# List Project Subdirectories

Display all subdirectories configured for a monorepo project with their detection patterns and metadata.

## Arguments

- **$1** - Project ID (required)

## Usage

```bash
/ccpm:project:subdir:list repeat
/ccpm:project:subdir:list my-monorepo
```

## Workflow

### Step 1: Auto-Activate Skills

```markdown
Skill(project-operations): Provides display guidance
Skill(project-detection): Provides detection context
```

### Step 2: Load Project Configuration

```javascript
const projectId = "$1"

if (!projectId) {
  console.log("❌ Error: Project ID required")
  console.log("Usage: /ccpm:project:subdir:list <project-id>")
  console.log("")
  console.log("Available projects:")
  console.log("  /ccpm:project:list")
  exit(1)
}

const projectConfig = Task(project-config-loader): `
Load configuration for project: ${projectId}
Include all sections: true
Validate: false
`

if (projectConfig.error) {
  console.error(`❌ ${projectConfig.error.message}`)
  exit(1)
}
```

### Step 3: Check for Subdirectories

```javascript
const hasDetection = projectConfig.context?.detection?.subdirectories?.length > 0
const hasMetadata = projectConfig.code_repository?.subprojects?.length > 0

if (!hasDetection && !hasMetadata) {
  console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 No Subdirectories Configured
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: ${projectConfig.project_name} (${projectId})

This project doesn't have subdirectory detection configured.

Add subdirectories for monorepo support:
  /ccpm:project:subdir:add ${projectId}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  `)
  exit(0)
}
```

### Step 4: Get Active Subproject

```javascript
const activeContext = Task(project-context-manager): `
Get active project context
Format: compact
`

const isThisProjectActive = activeContext?.project_id === projectId
const activeSubproject = isThisProjectActive ? activeContext.subproject : null
```

### Step 5: Display Subdirectories

```javascript
const detectionConfig = projectConfig.context?.detection?.subdirectories || []
const metadataConfig = projectConfig.code_repository?.subprojects || []

// Combine both sources
const allSubprojects = new Map()

// Add from metadata
metadataConfig.forEach(meta => {
  allSubprojects.set(meta.name, {
    name: meta.name,
    path: meta.path,
    description: meta.description,
    tech_stack: meta.tech_stack,
    detection: null
  })
})

// Add detection info
detectionConfig.forEach(det => {
  if (allSubprojects.has(det.subproject)) {
    allSubprojects.get(det.subproject).detection = det
  } else {
    allSubprojects.set(det.subproject, {
      name: det.subproject,
      path: null,
      description: null,
      tech_stack: null,
      detection: det
    })
  }
})

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 Subdirectories for ${projectConfig.project_name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project ID:       ${projectId}
Repository:       ${projectConfig.repository.local_path || "Not configured"}
Total Subprojects: ${allSubprojects.size}
${isThisProjectActive && activeSubproject ? `Active:           ⭐ ${activeSubproject}` : ""}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)

allSubprojects.forEach((subproject, name) => {
  const isActive = activeSubproject === name
  const indicator = isActive ? "⭐" : "  "

  console.log(`
${indicator} ${name}
   Path:             📁 ${subproject.path || "Not configured"}
   Description:      ${subproject.description || "N/A"}`)

  if (subproject.detection) {
    console.log(`   Match Pattern:    ${subproject.detection.match_pattern}`)
    console.log(`   Priority:         ${subproject.detection.priority || 0}`)
  } else {
    console.log(`   Detection:        ⚠️  Not configured`)
  }

  if (subproject.tech_stack) {
    const langs = subproject.tech_stack.languages?.join(", ") || ""
    if (langs) console.log(`   Languages:        ${langs}`)

    if (subproject.tech_stack.frameworks) {
      const frameworks = Object.entries(subproject.tech_stack.frameworks)
        .map(([type, fws]) => `${type}: ${fws.join(", ")}`)
        .join(", ")
      if (frameworks) console.log(`   Frameworks:       ${frameworks}`)
    }

    const dbs = subproject.tech_stack.database?.join(", ") || ""
    if (dbs) console.log(`   Database:         ${dbs}`)
  }

  console.log("")
  console.log(`   Commands:`)
  console.log(`     Update:  /ccpm:project:subdir:update ${projectId} ${name}`)
  console.log(`     Remove:  /ccpm:project:subdir:remove ${projectId} ${name}`)
  console.log("")
})

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Quick Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Add new subdirectory:
  /ccpm:project:subdir:add ${projectId}

View complete project details:
  /ccpm:project:show ${projectId}

Test detection:
  cd ${projectConfig.repository.local_path}/<subproject-path>
  /ccpm:project:list

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)
```

## Example Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 Subdirectories for Repeat
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project ID:       repeat
Repository:       /Users/duongdev/repeat
Total Subprojects: 4
Active:           ⭐ jarvis

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   xygaming_symfony
   Path:             📁 xygaming_symfony
   Description:      Legacy Symfony 4.4 PHP web application
   Match Pattern:    */xygaming_symfony/*
   Priority:         10
   Languages:        php
   Frameworks:       backend: symfony
   Database:         mysql, redis

   Commands:
     Update:  /ccpm:project:subdir:update repeat xygaming_symfony
     Remove:  /ccpm:project:subdir:remove repeat xygaming_symfony

⭐ jarvis
   Path:             📁 jarvis
   Description:      Modern admin web application (TurboRepo)
   Match Pattern:    */jarvis/*
   Priority:         10
   Languages:        typescript
   Frameworks:       frontend: nextjs, react, backend: nestjs
   Database:         mysql, prisma

   Commands:
     Update:  /ccpm:project:subdir:update repeat jarvis
     Remove:  /ccpm:project:subdir:remove repeat jarvis

   repeat-mobile-app
   Path:             📁 repeat-mobile-app
   Description:      React Native mobile application
   Match Pattern:    */repeat-mobile-app/*
   Priority:         10
   Languages:        typescript, javascript
   Frameworks:       frontend: react-native, expo

   Commands:
     Update:  /ccpm:project:subdir:update repeat repeat-mobile-app
     Remove:  /ccpm:project:subdir:remove repeat repeat-mobile-app

   messaging
   Path:             📁 messaging
   Description:      Node.js microservice
   Match Pattern:    */messaging/*
   Priority:         10
   Languages:        javascript, typescript
   Frameworks:       backend: nodejs

   Commands:
     Update:  /ccpm:project:subdir:update repeat messaging
     Remove:  /ccpm:project:subdir:remove repeat messaging

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Quick Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Add new subdirectory:
  /ccpm:project:subdir:add repeat

View complete project details:
  /ccpm:project:show repeat

Test detection:
  cd /Users/duongdev/repeat/<subproject-path>
  /ccpm:project:list

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

- Active subproject (if this project is active) is marked with ⭐
- Shows both detection configuration and metadata
- Warns if detection is not configured for a subproject
- Provides commands to update or remove each subdirectory
- Use `/ccpm:project:show` for complete project view

## Agent Integration

Uses these agents:
- **project-config-loader**: Loads project configuration
- **project-context-manager**: Checks active subproject
- **project-operations skill**: Provides display guidance
- **project-detection skill**: Provides detection context

## Related Commands

- `/ccpm:project:subdir:add` - Add new subdirectory
- `/ccpm:project:subdir:update` - Update subdirectory details
- `/ccpm:project:subdir:remove` - Remove subdirectory
- `/ccpm:project:show` - View complete project configuration
- `/ccpm:project:list` - List all projects with active detection
