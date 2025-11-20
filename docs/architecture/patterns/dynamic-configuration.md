# Dynamic Project Configuration Architecture

**Status**: ✅ Implemented
**Version**: 2.0
**Author**: CCPM Team
**Date**: 2025-01-20

## Overview

CCPM's dynamic project configuration system enables managing multiple projects from a single centralized configuration file (`~/.claude/ccpm-config.yaml`) with automatic project detection and seamless switching.

## Problem Statement

### Before: Hardcoded Project Definitions

**Issues:**
1. Project configurations scattered across command files
2. Adding new projects required editing multiple files
3. No way to manage multiple projects easily
4. Project-specific logic duplicated everywhere
5. Difficult to maintain and scale

**Example** (old approach):
```markdown
# In commands/planning:create.md

Projects and their PM systems:
- **my-app**: Uses Jira, Confluence, Slack
  - Linear: Team "Work", Project "My App"
- **repeat**: Uses Jira, Confluence, Slack
  - Linear: Team "Work", Project "Repeat"
- **personal-project**: Pure Linear-based (no external PM)
  - Linear: Team "Personal", Project "Personal Project"
```

Every command had to replicate this mapping.

### After: Dynamic Configuration

**Benefits:**
1. Single source of truth: `~/.claude/ccpm-config.yaml`
2. Add projects via commands: `/ccpm:project:add`
3. Automatic project detection based on context
4. Project templates for quick setup
5. Centralized, maintainable, scalable

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  ~/.claude/ccpm-config.yaml                 │
│  ┌────────────┬────────────┬────────────┬─────────────┐    │
│  │   Global   │  Projects  │ Templates  │   Context   │    │
│  │  Settings  │   Config   │            │  Detection  │    │
│  └────────────┴────────────┴────────────┴─────────────┘    │
└─────────────────────────────────────────────────────────────┘
           │                    │                   │
           ▼                    ▼                   ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐
│  Project Loader  │  │ Project Manager  │  │  Auto-Detect │
│    (Scripts)     │  │    (Commands)    │  │    Logic     │
└──────────────────┘  └──────────────────┘  └──────────────┘
           │                    │                   │
           └────────────────────┴───────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  CCPM Commands   │
                    │  (Planning, etc) │
                    └──────────────────┘
```

### File Structure

```
ccpm/
├── ccpm-config.example.yaml       # Example configuration with 3 project templates
├── scripts/
│   └── load-project-config.sh     # Configuration loader utility
├── commands/
│   ├── project:add.md             # Add new project interactively
│   ├── project:list.md            # List all projects
│   ├── project:show.md            # Show project details
│   ├── project:update.md          # Update project configuration
│   ├── project:delete.md          # Delete project (with backup)
│   └── project:set.md             # Set active project
└── docs/
    ├── guides/
    │   └── project-setup.md       # Complete setup guide
    ├── reference/
    │   └── project-config-usage.md # Config usage reference for developers
    └── architecture/
        └── dynamic-project-configuration.md  # This file
```

## Configuration Schema

### Top-Level Structure

```yaml
# Global defaults for all projects
global:
  linear_team: "Work"
  workflow_states: { ... }
  default_labels: [ ... ]
  tdd: { ... }
  code_review: { ... }

# Individual project configurations
projects:
  <project-id>:
    name: "Project Name"
    description: "..."
    linear: { ... }
    external_pm: { ... }
    code_repository: { ... }
    quality: { ... }
    tech_stack: { ... }
    custom_commands: [ ... ]
    workflow: { ... }

# Templates for quick project creation
templates:
  fullstack-with-jira: { ... }
  simple-linear: { ... }
  open-source: { ... }

# Active project context and auto-detection
context:
  current_project: <project-id> | null
  detection:
    by_git_remote: true
    by_cwd: true
    patterns:
      - { pattern: "...", project: "..." }
```

### Project Configuration Fields

#### Required Fields
- `name`: Human-readable project name
- `linear.team`: Linear team key
- `linear.project`: Linear project name

#### Optional Fields
- `description`: Project description
- `owner`: Team/person owning the project
- `repository`: Git repository details
- `external_pm`: Jira/Confluence/Slack integration
- `code_repository`: GitHub/BitBucket/GitLab settings
- `quality`: SonarQube and quality gates
- `tech_stack`: Languages, frameworks, databases
- `custom_commands`: Project-specific commands
- `workflow`: TDD, agent assignment, commits

See [`ccpm-config.example.yaml`](../../ccpm-config.example.yaml) for complete schema.

## Components

### 1. Configuration Loader (`scripts/load-project-config.sh`)

Shell script that loads and validates CCPM configuration.

**Features:**
- Find configuration file (searches up directory tree)
- Validate YAML syntax
- Validate required fields
- Get specific configuration values
- Output as JSON for MCP consumption

**Usage:**
```bash
# Validate configuration
./scripts/load-project-config.sh --validate-only

# Get specific value
./scripts/load-project-config.sh --get project.id

# Output as JSON
./scripts/load-project-config.sh --json

# Display summary
./scripts/load-project-config.sh
```

**Dependencies:**
- `yq` (YAML processor)
- `jq` (JSON processor)

### 2. Project Management Commands

#### `/ccpm:project:add <project-id>`

Interactive command to add new projects.

**Flow:**
1. Validate project ID format
2. Check if project already exists
3. Ask for project type (template or custom)
4. Gather project information via prompts
5. Build configuration object
6. Show preview
7. Confirm and save to `~/.claude/ccpm-config.yaml`

**Templates:**
- `fullstack-with-jira`: Full Jira/Confluence/Slack integration
- `simple-linear`: Linear-only, no external PM
- `open-source`: GitHub-based OSS project

#### `/ccpm:project:list`

Display all configured projects with summary information.

**Output:**
- Project ID and name
- Linear team/project
- Repository type
- External PM status
- Active indicator (⭐) for current project
- Quick commands for each project

#### `/ccpm:project:show <project-id>`

Show complete configuration for a specific project.

**Displays:**
- Project metadata
- Linear configuration
- External PM details (Jira, Confluence, Slack)
- Code repository settings
- Quality gates (SonarQube)
- Tech stack
- Custom commands
- Quick action commands

#### `/ccpm:project:update <project-id>`

Update existing project configuration.

**Modes:**
1. **Targeted update**: `--field <field-path>` to update specific field
2. **Interactive update**: Choose category and update multiple fields

**Categories:**
- Project Info (name, description, owner)
- Linear Settings (team, project, labels, workflow)
- External PM (Jira, Confluence, Slack)
- Code Repository (GitHub, BitBucket, GitLab)
- Quality Gates (SonarQube, code review)
- Tech Stack (languages, frameworks)
- Custom Commands

#### `/ccpm:project:delete <project-id>`

Delete a project from configuration (with safety features).

**Safety Features:**
1. **Automatic backup**: Creates timestamped backup before deletion
2. **Confirmation required**: Unless `--force` flag used
3. **Extra warning for active projects**: Requires double confirmation
4. **Clear communication**: Explains what WILL and WON'T be deleted

**Important**: Only removes CCPM configuration, does NOT delete:
- Linear issues
- Jira tickets
- Code repositories
- Any actual project data

#### `/ccpm:project:set <project-id>`

Set the active project for CCPM commands.

**Special Values:**
- `<project-id>`: Set specific project as active
- `auto`: Enable auto-detection
- `none` or `clear`: Clear active project

**Effects:**
- Manual setting disables auto-detection
- Active project used by all commands by default
- Can be overridden per-command with explicit project argument

### 3. Auto-Detection System

Automatically determines active project based on context.

**Detection Methods:**

1. **Git Remote URL Matching**
   ```yaml
   projects:
     my-app:
       repository:
         url: "https://github.com/company/my-app"
   ```
   When in a git repo with matching remote URL → project is active

2. **Current Working Directory Matching**
   ```yaml
   context:
     detection:
       patterns:
         - pattern: "*/my-app*"
           project: my-app
         - pattern: "*/workspace/frontend/*"
           project: frontend-app
   ```
   When current path matches pattern → project is active

3. **Priority Order:**
   1. Manual setting (highest)
   2. Git remote match
   3. Directory pattern match
   4. Prompt user (lowest)

**Configuration:**
```yaml
context:
  current_project: null  # null = auto-detect, or project-id for manual
  detection:
    by_git_remote: true   # Enable git remote detection
    by_cwd: true          # Enable directory path detection
    patterns:             # Custom detection rules
      - pattern: "*/project-a*"
        project: project-a
```

### 4. Configuration Usage Reference

Developer reference guide for loading project configuration in commands.

**Location:** `docs/reference/project-config-usage.md`

**Provides:**
- Configuration loading patterns
- Field access examples
- Fallback behavior guidelines
- Caching strategies
- Best practices

**Example:**
```javascript
// Load configuration
const linearTeam = await getConfig("linear.team")
const linearProject = await getConfig("linear.project")
const jiraEnabled = await getConfig("external_pm.jira.enabled")

// Use in Linear MCP call
await mcp__linear__create_issue({
  team: linearTeam,
  project: linearProject,
  title: "Task",
  // ...
})
```

## Usage Patterns

### Pattern 1: Single Active Project

User working on one project at a time.

```bash
# Set active project
/ccpm:project:set my-app

# All commands use this project by default
/ccpm:planning:create "Add feature"
/ccpm:implementation:start WORK-123

# Switch to different project
/ccpm:project:set another-app
```

### Pattern 2: Auto-Detection for Multi-Project Work

User switching between multiple projects.

```bash
# Enable auto-detection
/ccpm:project:set auto

# Project detected based on current directory
cd ~/code/project-a
/ccpm:planning:create "Task for A"  # Uses project-a

cd ~/code/project-b
/ccpm:planning:create "Task for B"  # Uses project-b
```

### Pattern 3: Explicit Project Override

Force specific project regardless of active setting.

```bash
# Active project: my-app
/ccpm:project:set my-app

# But create task for different project
/ccpm:planning:create "Task" another-app  # Overrides active project
```

### Pattern 4: Template-Based Quick Setup

Create new projects quickly using templates.

```bash
# Use template for consistent setup
/ccpm:project:add new-app --template fullstack-with-jira

# Template provides:
# - Jira/Confluence/Slack integration
# - SonarQube quality gates
# - TDD enforcement
# - Standard workflow
```

## Migration from Hardcoded Configuration

### Before (Hardcoded)

```markdown
# In commands/planning:create.md

Projects and their PM systems:
- **my-app**: Uses Jira, Confluence, Slack
  - Linear: Team "Work", Project "My App"
- **repeat**: Uses Jira, Confluence, Slack
  - Linear: Team "Work", Project "Repeat"
```

### After (Dynamic)

```yaml
# ~/.claude/ccpm-config.yaml
projects:
  my-app:
    name: "My App"
    linear:
      team: "Work"
      project: "My App"
    external_pm:
      enabled: true
      type: jira
      jira:
        project_key: "TRAIN"
```

**Commands now use:**
```javascript
// Load from config instead of hardcoding
const linearTeam = await getConfig("linear.team")
const linearProject = await getConfig("linear.project")
```

### Migration Steps

1. **Create initial configuration:**
   ```bash
   cp ~/.claude/plugins/ccpm/ccpm-config.example.yaml ~/.claude/ccpm-config.yaml
   ```

2. **Add existing projects:**
   ```bash
   /ccpm:project:add my-app
   /ccpm:project:add repeat
   /ccpm:project:add personal-project --template simple-linear
   ```

3. **Update commands to use dynamic config:**
   - Add `**READ**: .../_project-config.md` to commands
   - Replace hardcoded values with config lookups
   - Use `getConfig()` helper functions

4. **Test auto-detection:**
   ```bash
   /ccpm:project:set auto
   cd ~/code/my-app
   /ccpm:project:list  # Should show my-app as active ⭐
   ```

## Benefits

### For Users

1. **Easy project management**: Add/update/delete projects via commands
2. **Automatic switching**: No manual project selection when switching directories
3. **Consistent configuration**: Templates ensure all projects follow standards
4. **Clear visibility**: See all projects with `/ccpm:project:list`
5. **Safe operations**: Backups created before deletions

### For Developers

1. **Single source of truth**: One configuration file, no duplication
2. **Easy to extend**: Add new fields to schema without breaking existing configs
3. **Reusable patterns**: Shared configuration helper for all commands
4. **Testable**: Configuration loading logic in separate utility
5. **Maintainable**: Changes to project logic in one place

### For Teams

1. **Shareable configuration**: Can version control team-wide config
2. **Templates for consistency**: Ensure all projects follow team standards
3. **Documentation**: Configuration is self-documenting
4. **Onboarding**: New team members can see all projects easily

## Future Enhancements

### Short Term

1. **Project validation**: Lint configuration for common mistakes
2. **Export/Import**: Export project config to share with team
3. **Migration wizard**: Convert old hardcoded configs automatically
4. **Search**: Full-text search across projects

### Long Term

1. **Multi-config support**: Different configs for different contexts
2. **Remote configuration**: Load config from URL or git
3. **Configuration UI**: Web-based editor for configuration
4. **Project analytics**: Track which projects are most active
5. **Configuration sync**: Sync configuration across machines

## Testing

### Unit Tests

```bash
# Test configuration loader
./scripts/load-project-config.sh --validate-only

# Test specific field access
./scripts/load-project-config.sh --get project.id
```

### Integration Tests

```bash
# Test full workflow
/ccpm:project:add test-project --template simple-linear
/ccpm:project:show test-project
/ccpm:project:set test-project
/ccpm:project:delete test-project
```

### Auto-Detection Tests

```bash
# Test git remote detection
cd ~/code/my-app
/ccpm:project:list  # Should show my-app as active

# Test directory pattern detection
cd ~/workspace/frontend
/ccpm:project:list  # Should detect based on path pattern
```

## Security Considerations

### File Permissions

```bash
# Configuration file should be user-readable only
chmod 600 ~/.claude/ccpm-config.yaml
```

### Sensitive Data

**Avoid storing:**
- API keys
- Passwords
- Access tokens

**Store in environment variables instead:**
```yaml
external_pm:
  jira:
    base_url: "https://jira.company.com"
    # Do NOT store credentials here
    # Use environment variables or MCP auth
```

### Backup Files

Backup files may contain sensitive configuration:
```bash
~/.claude/ccpm-config.backup.*.yaml
```

Clean up old backups regularly.

## Troubleshooting

See [Project Setup Guide](../guides/project-setup.md#troubleshooting) for detailed troubleshooting steps.

**Common Issues:**
- Project not auto-detected → Check detection patterns
- YAML syntax errors → Validate with `yq`
- Commands don't use config → Check if config file exists
- `yq` not found → Install yq: `brew install yq`

## References

- [Project Setup Guide](../guides/project-setup.md) - Complete user guide
- [CLAUDE.md](../../CLAUDE.md) - Main CCPM documentation
- [Command Reference](../../commands/README.md) - All CCPM commands
- [ccpm-config.example.yaml](../../ccpm-config.example.yaml) - Configuration template
