---
description: Remove a subdirectory/subproject from a project
argument-hint: <project-id> <subproject-name>
---

# Remove Project Subdirectory

Remove subdirectory configuration from a monorepo project.

## Arguments

- **$1** - Project ID (required)
- **$2** - Subproject name (required)

## Usage

```bash
/ccpm:project:subdir:remove repeat jarvis
/ccpm:project:subdir:remove my-monorepo old-service
```

## Workflow

```javascript
const projectId = "$1"
const subprojectName = "$2"

// Load project
const projectConfig = Task(project-config-loader): `
Load configuration for project: ${projectId}
`

// Find subproject
const detectionEntry = projectConfig.context?.detection?.subdirectories?.find(
  s => s.subproject === subprojectName
)
const metadataEntry = projectConfig.code_repository?.subprojects?.find(
  s => s.name === subprojectName
)

if (!detectionEntry && !metadataEntry) {
  console.error(`❌ Subproject '${subprojectName}' not found in project '${projectId}'`)
  exit(1)
}

// Show what will be removed
console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Remove Subdirectory
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project:       ${projectId}
Subproject:    ${subprojectName}
Path:          ${metadataEntry?.path || "N/A"}
Match Pattern: ${detectionEntry?.match_pattern || "N/A"}

This will remove all configuration for this subdirectory.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)

// Confirm
const confirmation = AskUserQuestion({
  questions: [{
    question: "Remove this subdirectory configuration?",
    header: "Confirm",
    multiSelect: false,
    options: [
      { label: "Yes, remove it", description: "Delete all configuration" },
      { label: "No, keep it", description: "Cancel operation" }
    ]
  }]
})

if (confirmation !== "Yes, remove it") {
  console.log("❌ Cancelled")
  exit(0)
}

// Remove from config (pseudocode)
// yq eval -i "del(.projects.${projectId}.context.detection.subdirectories[] | select(.subproject == \"${subprojectName}\"))" ~/.claude/ccpm-config.yaml
// yq eval -i "del(.projects.${projectId}.code_repository.subprojects[] | select(.name == \"${subprojectName}\"))" ~/.claude/ccpm-config.yaml

console.log(`
✅ Subdirectory '${subprojectName}' removed from project '${projectId}'

View remaining subdirectories:
  /ccpm:project:subdir:list ${projectId}
`)
```

## Notes

- Removes both detection configuration and metadata
- Requires confirmation before removing
- Cannot be undone (backup config file first if needed)
- Use `/ccpm:project:subdir:list` to see all subdirectories

## Related Commands

- `/ccpm:project:subdir:list` - List all subdirectories
- `/ccpm:project:subdir:add` - Add new subdirectory
- `/ccpm:project:subdir:update` - Update subdirectory
