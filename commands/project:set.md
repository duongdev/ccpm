---
description: Set the active project for CCPM commands
allowed-tools: [Bash, Read, Edit, AskUserQuestion]
argument-hint: <project-id>
---

# Set Active CCPM Project

Set or change the currently active project for CCPM commands.

## Arguments

- **$1** - Project ID (required, or "auto" for auto-detection)

## Usage

```bash
# Set specific project as active
/ccpm:project:set my-app

# Enable auto-detection
/ccpm:project:set auto

# Clear active project
/ccpm:project:set none
```

## Workflow

### Step 1: Validate Configuration

```bash
CONFIG_FILE="$HOME/.claude/ccpm-config.yaml"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Error: No CCPM configuration found"
  echo ""
  echo "Create configuration:"
  echo "  /ccpm:project:add <project-id>"
  exit(1)
fi
```

### Step 2: Handle Special Values

#### If `$1 == "auto"`:

```bash
# Enable auto-detection
yq eval -i '.context.current_project = null' "$CONFIG_FILE"
yq eval -i '.context.detection.by_git_remote = true' "$CONFIG_FILE"
yq eval -i '.context.detection.by_cwd = true' "$CONFIG_FILE"

echo "✅ Auto-detection enabled"
echo ""
echo "CCPM will automatically detect your project based on:"
echo "  • Git remote URL"
echo "  • Current working directory"
echo "  • Custom detection patterns"
echo ""
echo "Test auto-detection:"
echo "  /ccpm:project:list  # Active project will be marked with ⭐"
exit(0)
```

#### If `$1 == "none"` or `$1 == "clear"`:

```bash
# Clear active project
yq eval -i '.context.current_project = null' "$CONFIG_FILE"
yq eval -i '.context.detection.by_git_remote = false' "$CONFIG_FILE"
yq eval -i '.context.detection.by_cwd = false' "$CONFIG_FILE"

echo "✅ Active project cleared"
echo ""
echo "CCPM commands will now prompt you to select a project."
echo ""
echo "To set an active project:"
echo "  /ccpm:project:set <project-id>"
exit(0)
```

### Step 3: Validate Project Exists

```bash
PROJECT_ID=$1

# Check if project exists in configuration
if ! yq eval ".projects.$PROJECT_ID" "$CONFIG_FILE" > /dev/null 2>&1; then
  echo "❌ Error: Project '$PROJECT_ID' not found"
  echo ""
  echo "Available projects:"
  yq eval '.projects | keys | .[]' "$CONFIG_FILE"
  echo ""
  echo "Add new project:"
  echo "  /ccpm:project:add $PROJECT_ID"
  exit(1)
fi
```

### Step 4: Show Project Info

```javascript
const projectConfig = await yq(`.projects.${projectId}`, CONFIG_FILE)

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Set Active Project: ${projectId}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project Details:
  Name:        ${projectConfig.name}
  Description: ${projectConfig.description || "N/A"}
  Linear:      ${projectConfig.linear.team} / ${projectConfig.linear.project}
  Repository:  ${projectConfig.repository?.url || "N/A"}

This project will be used by default for all CCPM commands.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)
```

### Step 5: Confirm (optional)

```javascript
{
  questions: [{
    question: `Set '${projectId}' as your active project?`,
    header: "Confirm",
    multiSelect: false,
    options: [
      {
        label: "Yes, set as active",
        description: "Use this project by default"
      },
      {
        label: "No, cancel",
        description: "Don't change active project"
      }
    ]
  }]
}
```

### Step 6: Set Active Project

```bash
# Set the active project
yq eval -i ".context.current_project = \"$PROJECT_ID\"" "$CONFIG_FILE"

# Optionally disable auto-detection to enforce this choice
yq eval -i '.context.detection.by_git_remote = false' "$CONFIG_FILE"
yq eval -i '.context.detection.by_cwd = false' "$CONFIG_FILE"

echo ""
echo "✅ Active project set to: $PROJECT_ID"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 This project will be used for:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  • All CCPM planning commands"
echo "  • Implementation and verification commands"
echo "  • Project-specific custom commands"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Quick Start"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Create a task:"
echo "  /ccpm:planning:create \"Task title\""
echo "  (no project ID needed - uses active project)"
echo ""
echo "View project status:"
echo "  /ccpm:project:show $PROJECT_ID"
echo ""
echo "Change active project:"
echo "  /ccpm:project:set <different-project-id>"
echo ""
echo "Enable auto-detection:"
echo "  /ccpm:project:set auto"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

## Auto-Detection vs Manual Setting

### Manual Setting

When you explicitly set a project with `/ccpm:project:set <project-id>`:
- Project is used **everywhere**, regardless of current directory
- Auto-detection is **disabled**
- Consistent project across all terminal sessions
- Good for focused work on one project

### Auto-Detection

When you enable auto-detection with `/ccpm:project:set auto`:
- Project is detected based on:
  1. Git remote URL matching
  2. Current working directory path matching
  3. Custom detection patterns
- Different directories can have different active projects
- More flexible for multi-project work
- Project changes as you `cd` between directories

## Detection Methods

### 1. Git Remote URL Matching

```yaml
# In ccpm-config.yaml
projects:
  my-app:
    repository:
      url: "https://github.com/company/my-app"
```

When `by_git_remote: true`:
```bash
cd ~/code/my-app
git remote get-url origin
# → https://github.com/company/my-app

# CCPM detects: "my-app" is active
```

### 2. Current Working Directory

```yaml
# In ccpm-config.yaml
context:
  detection:
    patterns:
      - pattern: "*/my-app*"
        project: my-app
      - pattern: "*/frontend/*"
        project: my-fullstack-app
```

When `by_cwd: true`:
```bash
cd ~/code/my-app/src
# Path matches "*/my-app*"
# CCPM detects: "my-app" is active

cd ~/code/frontend/dashboard
# Path matches "*/frontend/*"
# CCPM detects: "my-fullstack-app" is active
```

### 3. Priority Order

If multiple detection methods match:
1. **Manual setting** (highest priority)
2. Git remote URL match
3. Current working directory match
4. Custom patterns

## Examples

### Example 1: Set active project

```bash
/ccpm:project:set my-app

# ✅ Active project set to: my-app
# All CCPM commands now default to this project
```

### Example 2: Enable auto-detection

```bash
/ccpm:project:set auto

# ✅ Auto-detection enabled
# Project will be detected based on:
#   • Git remote URL
#   • Current directory
```

### Example 3: Clear active project

```bash
/ccpm:project:set none

# ✅ Active project cleared
# CCPM will prompt for project selection
```

### Example 4: Switch between projects

```bash
# Working on project A
/ccpm:project:set project-a
/ccpm:planning:create "Task for A"

# Switch to project B
/ccpm:project:set project-b
/ccpm:planning:create "Task for B"

# Back to auto-detection
/ccpm:project:set auto
```

## Verification

After setting active project, verify with:

```bash
# See active project marked with ⭐
/ccpm:project:list

# Or view project details
/ccpm:project:show <project-id>
```

## Notes

- Active project setting is global (affects all terminal sessions)
- Manual setting overrides auto-detection
- Auto-detection is more flexible for multi-project work
- Can switch projects anytime with `/ccpm:project:set`
- Configuration file: `~/.claude/ccpm-config.yaml`
