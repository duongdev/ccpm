---
description: Add a subdirectory/subproject to a project for monorepo support
argument-hint: <project-id> <subproject-name> <path> [--pattern <pattern>] [--priority <priority>]
---

# Add Subdirectory to Project

Add subdirectory configuration to a project for automatic detection in monorepos.

## Arguments

- **$1** - Project ID (required)
- **$2** - Subproject name (required)
- **$3** - Subproject path (required, relative to repo root)
- **--pattern** - Match pattern (optional, default: `*/${path}/*`)
- **--priority** - Detection priority (optional, default: 10)

## Usage

```bash
# Add with defaults
/ccpm:project:subdir:add repeat jarvis jarvis

# Add with custom pattern and priority
/ccpm:project:subdir:add repeat jarvis jarvis --pattern "*/jarvis/**" --priority 15

# Interactive mode (prompts for details)
/ccpm:project:subdir:add repeat
```

## Workflow

### Step 1: Auto-Activate Skills

```markdown
Skill(project-operations): Provides configuration guidance
```

### Step 2: Parse Arguments

```javascript
const projectId = "$1"
const subprojectName = "$2"
const subprojectPath = "$3"

if (!projectId) {
  console.log("❌ Error: Project ID required")
  console.log("Usage: /ccpm:project:subdir:add <project-id> <name> <path>")
  console.log("")
  console.log("Available projects:")
  console.log("  /ccpm:project:list")
  exit(1)
}

// Check if interactive mode (only project ID provided)
const interactiveMode = !subprojectName
```

### Step 3: Load Project Configuration

```javascript
const projectConfig = Task(project-config-loader): `
Load configuration for project: ${projectId}
Validate: true
`

if (projectConfig.error) {
  console.error(`❌ ${projectConfig.error.message}`)
  exit(1)
}

console.log(`📋 Project: ${projectConfig.project_name}`)
console.log(`📁 Repository: ${projectConfig.repository.local_path || "Not configured"}`)
console.log("")
```

### Step 4: Interactive Input (if needed)

If in interactive mode, use AskUserQuestion to gather details:

```javascript
if (interactiveMode) {
  const answers = AskUserQuestion({
    questions: [
      {
        question: "What is the subproject name? (e.g., 'frontend', 'mobile-app')",
        header: "Name",
        multiSelect: false,
        options: [
          {
            label: "Enter custom name",
            description: "Provide a unique name for this subproject"
          }
        ]
      },
      {
        question: "What is the relative path to this subproject? (e.g., 'apps/frontend', 'packages/mobile')",
        header: "Path",
        multiSelect: false,
        options: [
          {
            label: "apps/*",
            description: "Subproject in apps directory"
          },
          {
            label: "packages/*",
            description: "Subproject in packages directory"
          },
          {
            label: "services/*",
            description: "Subproject in services directory"
          }
        ]
      }
    ]
  })

  subprojectName = answers["What is the subproject name?"]
  subprojectPath = answers["What is the relative path to this subproject?"]
}
```

### Step 5: Build Configuration

```javascript
// Parse optional flags
const customPattern = getFlag("--pattern")
const customPriority = getFlag("--priority")

// Build subdirectory detection entry
const detectionEntry = {
  subproject: subprojectName,
  match_pattern: customPattern || `*/${subprojectPath}/*`,
  priority: customPriority ? parseInt(customPriority) : 10
}

// Build subproject metadata entry
const metadataEntry = {
  name: subprojectName,
  path: subprojectPath,
  description: "",  // Will prompt user
  tech_stack: {}    // Can be filled later
}

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 New Subdirectory Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Subproject Name:   ${detectionEntry.subproject}
Path:              ${metadataEntry.path}
Match Pattern:     ${detectionEntry.match_pattern}
Priority:          ${detectionEntry.priority}

This will be added to project: ${projectId}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)
```

### Step 6: Confirm and Update Configuration

```javascript
const confirmation = AskUserQuestion({
  questions: [{
    question: "Add this subdirectory configuration?",
    header: "Confirm",
    multiSelect: false,
    options: [
      {
        label: "Yes, add subdirectory",
        description: "Update ccpm-config.yaml with this configuration"
      },
      {
        label: "No, cancel",
        description: "Don't make any changes"
      }
    ]
  }]
})

if (confirmation["Add this subdirectory configuration?"] === "No, cancel") {
  console.log("❌ Cancelled")
  exit(0)
}
```

### Step 7: Update Configuration File

```bash
CONFIG_FILE="$HOME/.claude/ccpm-config.yaml"

# Read current configuration
current_config=$(cat "$CONFIG_FILE")

# Add to context.detection.subdirectories
# (This is pseudocode - actual implementation would use yq or python)
yq eval -i ".projects.${projectId}.context.detection.subdirectories += [{
  \"subproject\": \"${subprojectName}\",
  \"match_pattern\": \"${matchPattern}\",
  \"priority\": ${priority}
}]" "$CONFIG_FILE"

# Add to code_repository.subprojects
yq eval -i ".projects.${projectId}.code_repository.subprojects += [{
  \"name\": \"${subprojectName}\",
  \"path\": \"${subprojectPath}\",
  \"description\": \"\",
  \"tech_stack\": {}
}]" "$CONFIG_FILE"

echo "✅ Subdirectory configuration added!"
```

### Step 8: Validate and Display Results

```javascript
// Reload configuration to validate
const updatedConfig = Task(project-config-loader): `
Load configuration for project: ${projectId}
Validate: true
`

if (updatedConfig.error) {
  console.error("⚠️  Warning: Configuration validation failed")
  console.error(updatedConfig.error.message)
  console.log("")
  console.log("Please check the configuration file:")
  console.log(`  ~/.claude/ccpm-config.yaml`)
  exit(1)
}

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Subdirectory Added Successfully
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project:          ${projectId}
Subproject:       ${subprojectName}
Path:             ${subprojectPath}
Match Pattern:    ${detectionEntry.match_pattern}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪 Test Detection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

To test automatic detection:
  cd ${projectConfig.repository.local_path}/${subprojectPath}
  /ccpm:project:list

Expected result:
  ⭐ ${projectId} › ${subprojectName}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Update tech stack:
  /ccpm:project:subdir:update ${projectId} ${subprojectName} --tech-stack

Add more subdirectories:
  /ccpm:project:subdir:add ${projectId}

View all subdirectories:
  /ccpm:project:subdir:list ${projectId}

View project details:
  /ccpm:project:show ${projectId}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)
```

## Examples

### Example 1: Add Frontend Subproject

```bash
/ccpm:project:subdir:add my-monorepo frontend apps/frontend
```

Output:
```
📋 Project: My Monorepo
📁 Repository: /Users/dev/my-monorepo

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 New Subdirectory Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Subproject Name:   frontend
Path:              apps/frontend
Match Pattern:     */apps/frontend/*
Priority:          10

✅ Subdirectory Added Successfully
```

### Example 2: Add with Custom Pattern

```bash
/ccpm:project:subdir:add my-monorepo backend services/api --pattern "**/services/api/**" --priority 15
```

### Example 3: Interactive Mode

```bash
/ccpm:project:subdir:add my-monorepo
```

Then answer prompts for name, path, tech stack, etc.

## Pattern Matching

**Glob Pattern Format**:
- `*/path/*` - Matches any nesting level with path in between
- `**/path/**` - Matches path at any depth
- `apps/*/src` - Matches specific structure

**Priority Guidelines**:
- **10** (default) - Standard subprojects
- **15-20** - More specific patterns (nested paths)
- **5** - Less specific, fallback patterns

**Examples**:
```yaml
# Specific nested path (high priority)
- subproject: admin-panel
  match_pattern: "*/apps/web/admin/*"
  priority: 20

# General web app (standard priority)
- subproject: web-app
  match_pattern: "*/apps/web/*"
  priority: 10
```

## Notes

- Subdirectory detection requires `repository.local_path` to be configured
- Patterns are matched against the current working directory
- Higher priority patterns are matched first
- Use `/ccpm:project:show <project-id>` to see all configured subdirectories
- Tech stack can be added later with `/ccpm:project:subdir:update`

## Agent Integration

Uses these agents:
- **project-config-loader**: Loads and validates project configuration
- **project-operations skill**: Provides configuration guidance

## Related Commands

- `/ccpm:project:subdir:list` - List all subdirectories
- `/ccpm:project:subdir:update` - Update subdirectory details
- `/ccpm:project:subdir:remove` - Remove subdirectory
- `/ccpm:project:show` - View complete project configuration
