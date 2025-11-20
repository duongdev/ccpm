---
description: Update subdirectory/subproject configuration
argument-hint: <project-id> <subproject-name> [--field <field>]
---

# Update Project Subdirectory

Update subdirectory configuration including tech stack, description, pattern, and priority.

## Arguments

- **$1** - Project ID (required)
- **$2** - Subproject name (required)
- **--field** - Specific field to update (optional)

## Usage

```bash
# Interactive update (all fields)
/ccpm:project:subdir:update repeat jarvis

# Update specific field
/ccpm:project:subdir:update repeat jarvis --field tech_stack
/ccpm:project:subdir:update repeat jarvis --field description
/ccpm:project:subdir:update repeat jarvis --field pattern
/ccpm:project:subdir:update repeat jarvis --field priority
```

## Workflow

```javascript
const projectId = "$1"
const subprojectName = "$2"
const specificField = getFlag("--field")

// Load configuration
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
  console.error(`❌ Subproject '${subprojectName}' not found`)
  exit(1)
}

// Display current configuration
console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Update Subdirectory: ${subprojectName}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Configuration:
  Path:          ${metadataEntry?.path || "Not set"}
  Description:   ${metadataEntry?.description || "Not set"}
  Match Pattern: ${detectionEntry?.match_pattern || "Not set"}
  Priority:      ${detectionEntry?.priority || "Not set"}
  Tech Stack:    ${metadataEntry?.tech_stack ? "Configured" : "Not set"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)

// Interactive field selection or update specific field
const fieldsToUpdate = specificField
  ? [specificField]
  : await selectFieldsToUpdate()

// Update each selected field
for (const field of fieldsToUpdate) {
  const newValue = await promptForFieldValue(field, currentValue)
  // Update in config file
  // yq eval -i ".projects.${projectId}...${field} = \"${newValue}\"" ~/.claude/ccpm-config.yaml
}

console.log(`
✅ Subdirectory '${subprojectName}' updated successfully

View changes:
  /ccpm:project:subdir:list ${projectId}
  /ccpm:project:show ${projectId}
`)
```

## Updatable Fields

### Description
Update the human-readable description:
```bash
/ccpm:project:subdir:update repeat jarvis --field description
# Prompts: "Enter description for jarvis"
```

### Tech Stack
Update languages, frameworks, databases:
```bash
/ccpm:project:subdir:update repeat jarvis --field tech_stack
# Interactive prompts for:
# - Languages (typescript, python, etc.)
# - Frontend frameworks (react, vue, etc.)
# - Backend frameworks (nestjs, express, etc.)
# - Databases (postgresql, mongodb, etc.)
```

### Match Pattern
Update the glob pattern for detection:
```bash
/ccpm:project:subdir:update repeat jarvis --field pattern
# Prompts: "Enter new match pattern"
# Example: "*/jarvis/**" or "**/services/jarvis/*"
```

### Priority
Update detection priority (higher = more specific):
```bash
/ccpm:project:subdir:update repeat jarvis --field priority
# Prompts: "Enter priority (0-100)"
# Default: 10, Specific paths: 15-20
```

## Example: Update Tech Stack

```bash
/ccpm:project:subdir:update repeat jarvis --field tech_stack
```

Interactive prompts:
```
Languages (comma-separated): typescript, javascript
Frontend frameworks: react, nextjs, tailwindcss
Backend frameworks: nestjs
Databases: postgresql, redis

✅ Tech stack updated for 'jarvis'
```

Result in config:
```yaml
subprojects:
  - name: jarvis
    path: jarvis
    tech_stack:
      languages: [typescript, javascript]
      frameworks:
        frontend: [react, nextjs, tailwindcss]
        backend: [nestjs]
      database: [postgresql, redis]
```

## Notes

- Changes are saved to `~/.claude/ccpm-config.yaml`
- Validates configuration after updates
- Use `--field` to update specific field quickly
- Without `--field`, enters interactive mode for all fields

## Agent Integration

Uses:
- **project-config-loader**: Loads current configuration
- **project-operations skill**: Provides update guidance

## Related Commands

- `/ccpm:project:subdir:list` - View all subdirectories
- `/ccpm:project:subdir:add` - Add new subdirectory
- `/ccpm:project:subdir:remove` - Remove subdirectory
- `/ccpm:project:show` - View complete project config
