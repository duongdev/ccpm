---
description: Delete a project from CCPM configuration
allowed-tools: [Bash, Read, Edit, AskUserQuestion]
argument-hint: <project-id> [--force]
---

# Delete Project from CCPM

Remove a project configuration from `~/.claude/ccpm-config.yaml`.

## Arguments

- **$1** - Project ID (required)
- **--force** - Skip confirmation (optional, dangerous)

## Usage

```bash
# Interactive delete with confirmation
/ccpm:project:delete my-app

# Force delete without confirmation
/ccpm:project:delete my-app --force
```

## Workflow

### Step 1: Validate Project Exists

```bash
CONFIG_FILE="$HOME/.claude/ccpm-config.yaml"
PROJECT_ID=$1

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Error: No CCPM configuration found"
  exit(1)
fi

if ! yq eval ".projects.$PROJECT_ID" "$CONFIG_FILE" > /dev/null 2>&1; then
  echo "❌ Error: Project '$PROJECT_ID' not found"
  echo ""
  echo "Available projects:"
  yq eval '.projects | keys | .[]' "$CONFIG_FILE"
  exit(1)
fi
```

### Step 2: Load and Display Project Info

```javascript
const projectConfig = await yq(`.projects.${projectId}`, CONFIG_FILE)

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Delete Project: ${projectId}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project will be removed:
  Name:        ${projectConfig.name}
  Description: ${projectConfig.description || "N/A"}
  Linear:      ${projectConfig.linear.team} / ${projectConfig.linear.project}
  Repository:  ${projectConfig.repository?.url || "N/A"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  WARNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This will remove the project configuration from CCPM.

What will happen:
  ✓ Project removed from ~/.claude/ccpm-config.yaml
  ✓ CCPM commands will no longer recognize this project
  ✓ You can re-add the project later if needed

What will NOT happen:
  ✗ No data in Linear will be deleted
  ✗ No data in Jira/Confluence will be deleted
  ✗ No code repositories will be affected
  ✗ No files in your project will be deleted

This ONLY removes the CCPM configuration for this project.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)
```

### Step 3: Confirm Deletion

If `--force` flag is NOT provided:

```javascript
{
  questions: [{
    question: `Are you sure you want to delete project '${projectId}'?`,
    header: "Confirm Delete",
    multiSelect: false,
    options: [
      {
        label: "Yes, delete it",
        description: "Remove project from CCPM configuration"
      },
      {
        label: "Show details first",
        description: "View full project configuration before deleting"
      },
      {
        label: "No, cancel",
        description: "Keep the project"
      }
    ]
  }]
}
```

If user selects "Show details first":
```bash
# Run /ccpm:project:show internally
/ccpm:project:show $PROJECT_ID

# Then ask again
{
  questions: [{
    question: "After reviewing, do you want to delete this project?",
    header: "Confirm Delete",
    multiSelect: false,
    options: [
      {
        label: "Yes, delete it",
        description: "Remove project from CCPM"
      },
      {
        label: "No, keep it",
        description: "Cancel deletion"
      }
    ]
  }]
}
```

### Step 4: Check if Project is Active

```javascript
const isActive = await isActiveProject(projectId)

if (isActive) {
  console.log(`
⚠️  Additional Warning: Active Project

This project is currently active (auto-detected from your working directory).

If you delete it, you'll need to:
  1. Use /ccpm:project:set <other-project> to switch, OR
  2. Navigate to a different project directory, OR
  3. CCPM commands will prompt you to select a project

`)

  // Ask for additional confirmation
  {
    questions: [{
      question: "This is your active project. Still delete?",
      header: "Active Project",
      multiSelect: false,
      options: [
        {
          label: "Yes, delete anyway",
          description: "I understand this is active"
        },
        {
          label: "No, cancel",
          description: "Keep the active project"
        }
      ]
    }]
  }
}
```

### Step 5: Perform Deletion

```bash
# Create backup first
BACKUP_FILE="$HOME/.claude/ccpm-config.backup.$(date +%Y%m%d_%H%M%S).yaml"
cp "$CONFIG_FILE" "$BACKUP_FILE"

echo "📦 Backup created: $BACKUP_FILE"
echo ""

# Delete the project using yq
yq eval -i "del(.projects.$PROJECT_ID)" "$CONFIG_FILE"

echo "✅ Project deleted successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Deleted:     $PROJECT_ID"
echo "Backup:      $BACKUP_FILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "View remaining projects:  /ccpm:project:list"
echo "Add new project:          /ccpm:project:add <project-id>"
echo ""
echo "To restore (if needed):"
echo "  cp $BACKUP_FILE $CONFIG_FILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

### Step 6: Cleanup Active Project Context

If the deleted project was active:

```bash
# Clear active project context
yq eval -i '.context.current_project = null' "$CONFIG_FILE"

echo ""
echo "ℹ️  Active project context cleared"
echo ""
echo "Next time you run a CCPM command, you'll be prompted to select a project."
echo "Or set a default: /ccpm:project:set <project-id>"
```

## Safety Features

### 1. Always Creates Backup

Before deletion, a timestamped backup is created:
```
~/.claude/ccpm-config.backup.20250120_143022.yaml
```

### 2. Confirmation Required

Unless `--force` is used, user must confirm:
- Once for regular projects
- Twice for active projects

### 3. Clear Communication

The command clearly states what WILL and WILL NOT be deleted.

### 4. Easy Restoration

Backup file path is provided for easy restoration if needed.

## Examples

### Example 1: Delete with confirmation

```bash
/ccpm:project:delete old-project

# Shows project details
# Asks for confirmation
# Creates backup
# Deletes configuration
# ✅ Done
```

### Example 2: Delete active project

```bash
/ccpm:project:delete my-current-app

# Shows project details
# ⚠️  Warns it's the active project
# Asks for confirmation twice
# Creates backup
# Deletes configuration
# Clears active project context
# ✅ Done
```

### Example 3: Force delete (no confirmation)

```bash
/ccpm:project:delete temp-project --force

# ⚠️  DANGEROUS: Skips all confirmations
# Creates backup
# Deletes immediately
# ✅ Done

# Use with caution!
```

### Example 4: Restore from backup

```bash
# If you deleted by mistake:
cp ~/.claude/ccpm-config.backup.20250120_143022.yaml ~/.claude/ccpm-config.yaml

# Or run:
/ccpm:project:list  # Shows the backup file path

# Then manually restore
```

## What Gets Deleted

### Deleted ✓

- Project configuration in `~/.claude/ccpm-config.yaml`
- Project entry from CCPM's project list
- Active project context (if applicable)

### NOT Deleted ✗

- Linear issues and data
- Jira tickets and data
- Confluence pages
- Slack messages
- Git repositories
- Local project files
- Any actual code or data

**This command ONLY removes the CCPM configuration, not any actual project data.**

## Notes

- Always creates a timestamped backup before deletion
- Can be safely restored from backup
- Does not affect any external systems
- Use `--force` carefully (skips all confirmations)
- Active projects require extra confirmation
- Configuration file: `~/.claude/ccpm-config.yaml`
