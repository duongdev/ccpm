---
description: Update an existing project configuration
allowed-tools: [Bash, Read, Edit, AskUserQuestion]
argument-hint: <project-id> [--field FIELD_PATH]
---

# Update Project Configuration

Update an existing project in `~/.claude/ccpm-config.yaml`.

## Arguments

- **$1** - Project ID (required)
- **--field** - Specific field to update (optional, e.g., "linear.team", "external_pm.jira.project_key")

## Usage

```bash
# Interactive update (all fields)
/ccpm:project:update my-app

# Update specific field
/ccpm:project:update my-app --field linear.team
/ccpm:project:update my-app --field external_pm.jira.project_key
```

## Workflow

### Step 1: Validate and Load Project

```bash
CONFIG_FILE="$HOME/.claude/ccpm-config.yaml"
PROJECT_ID=$1

# Check configuration exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Error: No CCPM configuration found"
  echo ""
  echo "Create configuration:"
  echo "  /ccpm:project:add <project-id>"
  exit(1)
fi

# Check project exists
if ! yq eval ".projects.$PROJECT_ID" "$CONFIG_FILE" > /dev/null 2>&1; then
  echo "❌ Error: Project '$PROJECT_ID' not found"
  echo ""
  echo "Available projects:"
  yq eval '.projects | keys | .[]' "$CONFIG_FILE"
  exit(1)
fi

# Load current configuration
CURRENT_CONFIG=$(yq eval ".projects.$PROJECT_ID" "$CONFIG_FILE" -o=json)
```

### Step 2: Determine Update Mode

If `--field` is provided → **Targeted field update**
Otherwise → **Interactive full update**

### Mode A: Targeted Field Update

```javascript
const fieldPath = $2  // e.g., "linear.team"
const currentValue = await yq(`.projects.${projectId}.${fieldPath}`, CONFIG_FILE)

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Update Field: ${fieldPath}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project:      ${projectId}
Field:        ${fieldPath}
Current:      ${currentValue}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)

// Ask for new value
{
  questions: [{
    question: `What should the new value be for ${fieldPath}?`,
    header: "New Value",
    multiSelect: false,
    options: [
      {
        label: "Enter manually",
        description: "Type the new value"
      }
    ]
  }]
}

// Validate new value (type-specific validation)
const newValue = userInput

// Update configuration
await yq(`-i '.projects.${projectId}.${fieldPath} = "${newValue}"'`, CONFIG_FILE)

console.log(`
✅ Updated successfully!

Field:   ${fieldPath}
Old:     ${currentValue}
New:     ${newValue}
`)
```

### Mode B: Interactive Full Update

Ask user which category to update:

```javascript
{
  questions: [{
    question: "What would you like to update?",
    header: "Update Category",
    multiSelect: false,
    options: [
      {
        label: "Project Info",
        description: "Name, description, owner"
      },
      {
        label: "Linear Settings",
        description: "Team, project, labels, workflow states"
      },
      {
        label: "External PM",
        description: "Jira, Confluence, Slack configuration"
      },
      {
        label: "Code Repository",
        description: "Repository type and settings"
      },
      {
        label: "Quality Gates",
        description: "SonarQube, code review settings"
      },
      {
        label: "Tech Stack",
        description: "Languages, frameworks, databases"
      },
      {
        label: "Custom Commands",
        description: "Project-specific commands"
      },
      {
        label: "All Settings",
        description: "Review and update all categories"
      }
    ]
  }]
}
```

#### Update: Project Info

```javascript
const current = config

// Show current values
console.log(`
Current Project Info:
  Name:        ${current.name}
  Description: ${current.description}
  Owner:       ${current.owner}
`)

// Ask for updates
{
  questions: [
    {
      question: "New project name? (or keep current)",
      header: "Name",
      multiSelect: false,
      options: [
        { label: "Keep current", description: current.name },
        { label: "Change", description: "Enter new name" }
      ]
    },
    {
      question: "New description? (or keep current)",
      header: "Description",
      multiSelect: false,
      options: [
        { label: "Keep current", description: current.description },
        { label: "Change", description: "Enter new description" }
      ]
    }
  ]
}

// Apply changes
if (nameChanged) {
  await yq(`-i '.projects.${projectId}.name = "${newName}"'`, CONFIG_FILE)
}
if (descriptionChanged) {
  await yq(`-i '.projects.${projectId}.description = "${newDescription}"'`, CONFIG_FILE)
}
```

#### Update: Linear Settings

```javascript
{
  questions: [
    {
      question: "Which Linear setting to update?",
      header: "Linear",
      multiSelect: true,  // Allow multiple selections
      options: [
        { label: "Team", description: `Current: ${config.linear.team}` },
        { label: "Project", description: `Current: ${config.linear.project}` },
        { label: "Labels", description: `Current: ${config.linear.default_labels.join(", ")}` },
        { label: "Workflow States", description: "Backlog, Planning, etc." }
      ]
    }
  ]
}

// For each selected setting, prompt for new value
// Then update configuration
```

#### Update: External PM

```javascript
{
  questions: [{
    question: "Update external PM integration?",
    header: "External PM",
    multiSelect: false,
    options: [
      {
        label: "Enable/Disable",
        description: `Currently: ${config.external_pm.enabled ? "Enabled" : "Disabled"}`
      },
      {
        label: "Jira Settings",
        description: "Base URL, project key"
      },
      {
        label: "Confluence Settings",
        description: "Base URL, space key"
      },
      {
        label: "Slack Settings",
        description: "Workspace, channels"
      },
      {
        label: "Disable All External PM",
        description: "Switch to Linear-only mode"
      }
    ]
  }]
}
```

#### Update: Code Repository

```javascript
{
  questions: [{
    question: "Update repository settings?",
    header: "Repository",
    multiSelect: false,
    options: [
      {
        label: "Change Type",
        description: `Currently: ${config.code_repository.type}`
      },
      {
        label: "Update GitHub Settings",
        description: "Owner, repo name"
      },
      {
        label: "Update BitBucket Settings",
        description: "Workspace, repo slug"
      },
      {
        label: "Update Repository URL",
        description: "Change repository URL"
      }
    ]
  }]
}
```

### Step 3: Show Changes Summary

After collecting all updates:

```javascript
console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Changes Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: ${projectId}

${changes.map(change => `
  ${change.field}
    Old: ${change.oldValue}
    New: ${change.newValue}
`).join("\n")}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)
```

### Step 4: Confirm and Apply

```javascript
{
  questions: [{
    question: "Apply these changes?",
    header: "Confirm",
    multiSelect: false,
    options: [
      {
        label: "Yes, apply",
        description: "Save changes to configuration"
      },
      {
        label: "Review again",
        description: "Go back and modify"
      },
      {
        label: "Cancel",
        description: "Discard all changes"
      }
    ]
  }]
}
```

If confirmed:

```bash
# Apply all changes using yq
for change in "${CHANGES[@]}"; do
  yq eval -i ".projects.$PROJECT_ID.${change.field} = ${change.value}" "$CONFIG_FILE"
done

echo ""
echo "✅ Project configuration updated!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "View updated config:   /ccpm:project:show $PROJECT_ID"
echo "List all projects:     /ccpm:project:list"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

## Examples

### Example 1: Update Linear team

```bash
/ccpm:project:update my-app --field linear.team

# Prompts:
# Current: Work
# New value: Personal

# Result:
# ✅ Updated linear.team from "Work" to "Personal"
```

### Example 2: Interactive update

```bash
/ccpm:project:update my-app

# Shows menu:
# 1. Project Info
# 2. Linear Settings
# 3. External PM
# ...

# User selects "Linear Settings"
# Shows checkboxes for Team, Project, Labels, Workflow States
# Updates selected fields
```

### Example 3: Enable Jira integration

```bash
/ccpm:project:update my-side-project

# Select: External PM
# Choose: Enable Jira
# Enter: Base URL, project key
# Result: external_pm.enabled = true, jira configured
```

## Validation

The command validates:
- Project ID exists
- Field paths are valid
- Values match expected types
- Required fields are not left empty
- URLs are properly formatted

## Notes

- All changes are applied atomically
- Invalid changes are rejected before saving
- Can cancel at any point before confirmation
- Use `/ccpm:project:show` to verify changes
- Configuration file: `~/.claude/ccpm-config.yaml`
