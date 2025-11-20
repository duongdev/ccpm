# Migration to Dynamic Project Configuration

**Date**: 2025-01-20
**Version**: 2.0.0

## Summary

CCPM has migrated from hardcoded project definitions to a dynamic configuration system using `~/.claude/ccpm-config.yaml`.

## What Changed

### Before (v1.x - Hardcoded)

Projects were hardcoded in every command file:

```markdown
## Project Context

- **my-app**: Uses Jira, Confluence, Slack
  - Linear: Team "Work", Project "My App"
- **my-project**: Uses Jira, Confluence, Slack
  - Linear: Team "Work", Project "My Project"
- **personal-project**: Pure Linear-based
  - Linear: Team "Personal", Project "Personal Project"
```

**Problems:**
- Adding projects required editing multiple files
- No central configuration
- Difficult to maintain
- No multi-project support

### After (v2.0 - Dynamic)

Projects are configured in `~/.claude/ccpm-config.yaml`:

```yaml
projects:
  my-project:
    name: "My Project"
    linear:
      team: "Work"
      project: "My Project"
    external_pm:
      enabled: true
      type: jira
    # ... full configuration
```

**Benefits:**
- ✅ Add projects via commands (`/ccpm:project:add`)
- ✅ Auto-detection based on directory/git
- ✅ Project templates for quick setup
- ✅ Manage unlimited projects
- ✅ No code changes needed

## Configuration File Location

**Global configuration**: `~/.claude/ccpm-config.yaml`

Create this file using:
```bash
/ccpm:project:add my-first-project
```

Or copy the example:
```bash
cp ~/.claude/plugins/ccpm/ccpm-config.example.yaml ~/.claude/ccpm-config.yaml
```

## Updated Commands

### New Project Management Commands

```bash
/ccpm:project:add <project-id>      # Add new project
/ccpm:project:list                  # List all projects
/ccpm:project:show <project-id>     # Show project details
/ccpm:project:update <project-id>   # Update configuration
/ccpm:project:delete <project-id>   # Delete project
/ccpm:project:set <project-id>      # Set active project
```

### Existing Commands Now Support Dynamic Config

All planning, implementation, and utility commands now:
- Use active project by default
- Accept optional project ID argument
- Load configuration from `~/.claude/ccpm-config.yaml`

**Examples:**

```bash
# With active project set
/ccpm:project:set my-app
/ccpm:planning:create "Add feature"  # Uses my-app

# With explicit project
/ccpm:planning:create "Add feature" my-app

# Auto-detection enabled
/ccpm:project:set auto
cd ~/code/my-app
/ccpm:planning:create "Add feature"  # Auto-detects my-app
```

## Migration Steps for Users

### 1. Verify Configuration File

```bash
# Check if config exists
ls -la ~/.claude/ccpm-config.yaml

# If doesn't exist, create it
/ccpm:project:add my-first-project

# View your projects
/ccpm:project:list
```

### 2. Set Active Project (Optional)

```bash
# Set active project
/ccpm:project:set my-app

# Or enable auto-detection
/ccpm:project:set auto
```

### 3. Add More Projects

```bash
# Add projects as needed
/ccpm:project:add another-project

# Or use template for quick setup
/ccpm:project:add new-app --template fullstack-with-jira
```

### 4. Update Projects

```bash
# Update any field
/ccpm:project:update my-app --field linear.team

# Or interactive update
/ccpm:project:update my-app
```

## For Command Developers

### How to Update Commands

Commands should now load configuration dynamically:

```markdown
## Load Project Configuration

```bash
# Set project argument based on your command structure
PROJECT_ARG="$2"  # Adjust based on your argument position
```

**LOAD PROJECT CONFIG**: Follow instructions in `commands/_shared-project-config-loader.md`

After loading, use these variables:
- `${LINEAR_TEAM}`, `${LINEAR_PROJECT}`
- `${EXTERNAL_PM_ENABLED}`, `${JIRA_ENABLED}`
- etc.
```

### Shared Configuration Loader

All commands use `commands/_shared-project-config-loader.md` which provides:
- Configuration loading logic
- Project validation
- Active project fallback
- Helpful error messages
- All project variables

## Backward Compatibility

### Hardcoded Project Names in Examples

Documentation still references example project names like:
- `my-app`
- `repeat`
- `personal-project`

**These are now examples only.** Replace with your actual project IDs:

**Old documentation:**
```bash
/ccpm:planning:create "Task" my-app PROJ-123
```

**Your usage:**
```bash
# Use your actual project ID
/ccpm:planning:create "Task" my-project PROJ-123

# Or use active project
/ccpm:project:set my-project
/ccpm:planning:create "Task"
```

## Troubleshooting

### "Project not found" Error

```bash
❌ Error: Project 'xyz' not found

# Solution: List available projects
/ccpm:project:list

# Add the project
/ccpm:project:add xyz
```

### "No active project set"

```bash
⚠️  No project specified and no active project set

# Solution: Set active project
/ccpm:project:set <project-id>

# Or enable auto-detection
/ccpm:project:set auto
```

### "Configuration file not found"

```bash
❌ Error: CCPM configuration not found

# Solution: Create from example
cp ~/.claude/plugins/ccpm/ccpm-config.example.yaml ~/.claude/ccpm-config.yaml

# Or add your first project
/ccpm:project:add my-first-project
```

### Commands Using Old Hardcoded Names

Some documentation may still reference old project names. Simply replace with your project IDs.

**If you see:**
```bash
/ccpm:planning:create "Task" my-app
```

**Use:**
```bash
/ccpm:planning:create "Task" your-project-id
```

## Breaking Changes

### ⚠️ Commands No Longer Accept Hardcoded Project Names

If you have scripts or aliases using hardcoded projects:

**Before:**
```bash
alias create-task='/ccpm:planning:create "$1" my-app'
```

**After:**
```bash
# Option 1: Use active project
/ccpm:project:set my-app
alias create-task='/ccpm:planning:create "$1"'

# Option 2: Explicit project
alias create-task='/ccpm:planning:create "$1" my-app'
```

### Configuration File Required

All commands now require `~/.claude/ccpm-config.yaml` to exist.

**Solution**: Run `/ccpm:project:add` to create it automatically.

## Resources

- **[Project Setup Guide](./docs/guides/project-setup.md)** - Complete guide
- **[Dynamic Configuration Architecture](./docs/architecture/dynamic-project-configuration.md)** - Technical details
- **[Project Config Example](./ccpm-config.example.yaml)** - Full example with all fields
- **[Project Commands Reference](./commands/README.md)** - All `/ccpm:project:*` commands

## Support

If you encounter issues:

1. Check configuration exists: `ls ~/.claude/ccpm-config.yaml`
2. List projects: `/ccpm:project:list`
3. View project details: `/ccpm:project:show <project-id>`
4. See [Troubleshooting](#troubleshooting) above

For bugs or questions:
- GitHub Issues: https://github.com/duongdev/ccpm/issues
- Author: [@duongdev](https://github.com/duongdev)

---

**Migration complete!** 🎉 You can now manage unlimited projects from one configuration file.
