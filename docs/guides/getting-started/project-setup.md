# CCPM Project Setup Guide

Complete guide to setting up and configuring projects with CCPM's dynamic project configuration system.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Configuration File](#configuration-file)
4. [Adding Projects](#adding-projects)
5. [Managing Projects](#managing-projects)
6. [Project Templates](#project-templates)
7. [Auto-Detection](#auto-detection)
8. [Using Projects in Commands](#using-projects-in-commands)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

## Overview

CCPM's dynamic project configuration system allows you to:

- **Manage multiple projects** in one centralized configuration file
- **Auto-detect active project** based on your current directory or git repository
- **Customize workflows** per project (Jira, Linear-only, GitHub, BitBucket, etc.)
- **Use templates** for quick project setup
- **Switch projects** seamlessly without editing configuration files

All projects are configured in: `~/.claude/ccpm-config.yaml`

## Quick Start

### 1. Add Your First Project

```bash
# Interactive project creation
/ccpm:project:add my-app

# Follow the prompts to configure:
# - Project type (Jira integration, Linear-only, etc.)
# - Linear team and project name
# - Repository details
# - Tech stack
```

### 2. Set as Active Project

```bash
/ccpm:project:set my-app

# Or enable auto-detection
/ccpm:project:set auto
```

### 3. Start Using CCPM

```bash
# Create a task (uses active project automatically)
/ccpm:planning:create "Add user authentication"

# View project status
/ccpm:project:show my-app

# List all projects
/ccpm:project:list
```

## Configuration File

### Location

```
~/.claude/ccpm-config.yaml
```

### Structure

```yaml
# Global settings (apply to all projects)
global:
  linear_team: "Work"
  default_labels: [planning, auto-created]
  # ...

# Individual projects
projects:
  my-app:
    name: "My Application"
    linear:
      team: "Work"
      project: "My Application"
    external_pm:
      enabled: true
      type: jira
    # ...

  another-app:
    name: "Another App"
    # ...

# Project templates for quick setup
templates:
  fullstack-with-jira: { ... }
  simple-linear: { ... }
  open-source: { ... }

# Active project context
context:
  current_project: my-app  # or null for auto-detect
  detection:
    by_git_remote: true
    by_cwd: true
```

### Creating Configuration File

#### Option 1: Copy Example

```bash
cp ~/.claude/plugins/ccpm/ccpm-config.example.yaml ~/.claude/ccpm-config.yaml
```

Then edit manually to add your projects.

#### Option 2: Use Commands

```bash
# Start from scratch - add your first project
/ccpm:project:add my-first-project
```

CCPM will create `~/.claude/ccpm-config.yaml` if it doesn't exist.

## Adding Projects

### Interactive Addition

```bash
/ccpm:project:add <project-id>
```

Example flow:

```bash
/ccpm:project:add trainer-app

# Prompts:
# 1. Project type: Full-stack with Jira / Simple Linear / Open Source / Custom
# 2. Project name: "Trainer App"
# 3. Linear team: Work / Personal / Other
# 4. Repository type: GitHub / BitBucket / GitLab
# 5. (If Jira) Jira project key: TRAIN
# 6. (If Jira) Confluence space: TRAIN
# 7. (If Jira) Slack channel: #trainer-app-dev
# 8. Repository owner/repo: company/trainer-app
# 9. Tech stack: TypeScript, React, Node.js, etc.
# 10. Review and confirm

# Result:
# ✅ Project added successfully!
```

### Using Templates

```bash
/ccpm:project:add my-app --template simple-linear
```

Available templates:
- **fullstack-with-jira**: Full Jira/Confluence/Slack integration
- **simple-linear**: Linear-only tracking (no external PM)
- **open-source**: GitHub-based open source project

### Project Configuration Fields

#### Required Fields

```yaml
project-id:
  name: "Human-readable name"
  linear:
    team: "Linear team key"
    project: "Linear project name"
```

#### Optional Fields

- **description**: Project description
- **owner**: Team or person owning the project
- **repository**: Git repository URL and branch
- **external_pm**: Jira, Confluence, Slack integration
- **code_repository**: GitHub/BitBucket/GitLab settings
- **quality**: SonarQube and code review configuration
- **tech_stack**: Languages, frameworks, databases
- **custom_commands**: Project-specific commands
- **workflow**: TDD, agent auto-assignment settings

See `ccpm-config.example.yaml` for complete field reference.

## Managing Projects

### List All Projects

```bash
/ccpm:project:list
```

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 CCPM Projects (3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⭐ my-app (Active)
   Name:        My Application
   Linear:      Work / My Application
   Repo Type:   github
   External PM: jira

   another-app
   Name:        Another App
   Linear:      Work / Another App
   Repo Type:   bitbucket
   External PM: jira

   side-project
   Name:        My Side Project
   Linear:      Personal / My Side Project
   Repo Type:   github
   External PM: disabled
```

### Show Project Details

```bash
/ccpm:project:show my-app
```

Displays complete configuration including:
- Linear settings
- External PM details (Jira, Confluence, Slack)
- Code repository configuration
- Quality gates
- Tech stack
- Custom commands

### Update Project

```bash
# Interactive update
/ccpm:project:update my-app

# Update specific field
/ccpm:project:update my-app --field linear.team
```

### Delete Project

```bash
# With confirmation
/ccpm:project:delete my-app

# Force delete (no confirmation)
/ccpm:project:delete my-app --force
```

**Note**: This only removes the CCPM configuration. It does NOT delete:
- Linear issues
- Jira tickets
- Code repositories
- Any actual project data

### Set Active Project

```bash
# Set specific project as active
/ccpm:project:set my-app

# Enable auto-detection
/ccpm:project:set auto

# Clear active project
/ccpm:project:set none
```

## Project Templates

### Built-in Templates

#### 1. fullstack-with-jira

Full-featured enterprise project with:
- Jira issue tracking
- Confluence documentation
- Slack notifications
- SonarQube quality gates
- Auto code review

```bash
/ccpm:project:add enterprise-app --template fullstack-with-jira
```

#### 2. simple-linear

Minimal setup for personal/small projects:
- Linear-only tracking
- No external PM integration
- Relaxed TDD requirements
- GitHub repository

```bash
/ccpm:project:add my-side-project --template simple-linear
```

#### 3. open-source

Open source project configuration:
- GitHub-based
- No external PM
- Enforced TDD
- Public repository

```bash
/ccpm:project:add my-oss-lib --template open-source
```

### Creating Custom Templates

Edit `~/.claude/ccpm-config.yaml`:

```yaml
templates:
  my-custom-template:
    external_pm:
      enabled: true
      type: jira
    quality:
      sonarqube:
        enabled: true
        thresholds:
          coverage: 90  # Stricter than default
    workflow:
      tdd:
        enabled: true
        enforce_tests_first: true
```

Then use:

```bash
/ccpm:project:add new-app --template my-custom-template
```

## Auto-Detection

### How It Works

When auto-detection is enabled (`/ccpm:project:set auto`), CCPM automatically determines the active project based on:

1. **Git Remote URL**: Matches repository URL in project config
2. **Current Working Directory**: Matches path patterns
3. **Custom Patterns**: User-defined detection rules

### Git Remote Detection

```yaml
projects:
  my-app:
    repository:
      url: "https://github.com/company/my-app"
```

When you're in a directory with this git remote:
```bash
cd ~/code/my-app
# CCPM detects: my-app is active ⭐
```

### Directory Path Detection

```yaml
context:
  detection:
    patterns:
      - pattern: "*/my-app*"
        project: my-app
      - pattern: "*/frontend/*"
        project: my-fullstack-app
      - pattern: "*duongdev*"
        project: personal-project
```

Examples:
```bash
cd ~/code/my-app/src
# Matches "*/my-app*" → my-app is active

cd ~/projects/frontend/dashboard
# Matches "*/frontend/*" → my-fullstack-app is active

cd ~/duongdev/tools
# Matches "*duongdev*" → personal-project is active
```

### Detection Priority

1. **Manual setting** (highest) - Set with `/ccpm:project:set <id>`
2. **Git remote match** - Repository URL matches
3. **Directory pattern** - Path matches pattern
4. **Prompt user** (lowest) - If nothing matches, ask

### Configuration

```yaml
context:
  # Manual override (null = auto-detect)
  current_project: null

  detection:
    # Enable git remote detection
    by_git_remote: true

    # Enable directory path detection
    by_cwd: true

    # Custom detection patterns
    patterns:
      - pattern: "*/project-a*"
        project: project-a
      - pattern: "*/workspace/b/*"
        project: project-b
```

## Using Projects in Commands

### With Active Project

When you have an active project set:

```bash
# No project ID needed - uses active project
/ccpm:planning:create "Add feature X"
/ccpm:implementation:start WORK-123
/ccpm:verification:check WORK-123
```

### Without Active Project

If no active project is set, commands will prompt:

```bash
/ccpm:planning:create "Add feature X"

# Prompts:
# Which project is this for?
# 1. my-app
# 2. another-app
# 3. side-project
```

### Explicit Project Override

Some commands accept an explicit project argument:

```bash
# Force use of specific project (overrides active project)
/ccpm:planning:create "Task title" my-app

# Useful for creating tasks in different projects
/ccpm:planning:create "Fix bug" project-a
/ccpm:planning:create "Add feature" project-b
```

### Project-Specific Commands

Custom commands can be defined per-project:

```yaml
projects:
  my-mobile-app:
    custom_commands:
      - name: "check-pr"
        enabled: true
        config:
          browser_mcp: "playwright"
          auto_sync_linear: true
```

Usage:
```bash
# Project-specific command
/ccpm:my-mobile-app:check-pr 123

# Or if my-mobile-app is active:
/ccpm:check-pr 123  # Auto-uses active project config
```

## Best Practices

### 1. Use Descriptive Project IDs

✅ Good:
```
my-app-mobile
acme-platform-api
personal-blog
```

❌ Avoid:
```
proj1
app
test
```

### 2. Organize by Team/Purpose

```yaml
projects:
  # Work projects
  work-platform-api:
    linear:
      team: "Work"

  work-mobile-app:
    linear:
      team: "Work"

  # Personal projects
  personal-blog:
    linear:
      team: "Personal"

  personal-tools:
    linear:
      team: "Personal"
```

### 3. Use Templates for Consistency

Create organization-wide templates:

```yaml
templates:
  company-standard:
    external_pm:
      enabled: true
      type: jira
    quality:
      sonarqube:
        enabled: true
        thresholds:
          coverage: 80
    workflow:
      tdd:
        enabled: true
```

### 4. Configure Auto-Detection Patterns

Make switching between projects seamless:

```yaml
context:
  detection:
    patterns:
      # All work projects in ~/work/*
      - pattern: "*/work/*"
        project: work-default

      # Personal projects in ~/personal/*
      - pattern: "*/personal/*"
        project: personal-default

      # Mobile apps in */mobile/*
      - pattern: "*/mobile/*"
        project: mobile-app
```

### 5. Document Project-Specific Workflows

Add descriptions:

```yaml
projects:
  complex-app:
    name: "Complex Application"
    description: |
      Multi-repo application with:
      - Frontend: React Native
      - Backend: Node.js + Python
      - Database: PostgreSQL

      Workflow:
      1. Always create Jira ticket first
      2. Plan with /ccpm:planning:plan
      3. TDD enforced
      4. PR requires 2 approvals
```

### 6. Regular Configuration Backups

```bash
# Manual backup
cp ~/.claude/ccpm-config.yaml ~/.claude/ccpm-config.backup.yaml

# Automated (add to cron or git)
cd ~/.claude
git add ccpm-config.yaml
git commit -m "Update CCPM config"
```

## Troubleshooting

### Project Not Auto-Detected

**Symptom**: CCPM always prompts for project selection

**Solution**:
```bash
# Check auto-detection is enabled
/ccpm:project:set auto

# View current configuration
cat ~/.claude/ccpm-config.yaml | grep -A 10 "context:"

# Should show:
# context:
#   current_project: null
#   detection:
#     by_git_remote: true
#     by_cwd: true
```

### Wrong Project Detected

**Symptom**: CCPM detects the wrong project

**Solution**:
```bash
# Check detection patterns
cat ~/.claude/ccpm-config.yaml | grep -A 20 "patterns:"

# Remove conflicting patterns or make them more specific
/ccpm:project:update <project-id>
```

### Commands Don't Use Active Project

**Symptom**: Commands still ask for project even though one is active

**Solution**:
```bash
# Verify active project is set
/ccpm:project:list
# Look for ⭐ next to active project

# If not set:
/ccpm:project:set <project-id>
```

### Configuration File Errors

**Symptom**: YAML parsing errors

**Solution**:
```bash
# Validate YAML syntax
yq eval '.' ~/.claude/ccpm-config.yaml

# If errors, restore from backup
cp ~/.claude/ccpm-config.backup.*.yaml ~/.claude/ccpm-config.yaml

# Or use the example as template
cp ~/.claude/plugins/ccpm/ccpm-config.example.yaml ~/.claude/ccpm-config.yaml
```

### Can't Find yq Command

**Symptom**: "yq: command not found"

**Solution**:
```bash
# Install yq (macOS)
brew install yq

# Install yq (Linux)
snap install yq

# Verify installation
yq --version
```

### Project Configuration Not Loading

**Symptom**: Commands don't see project configuration

**Solution**:
```bash
# Check file exists
ls -la ~/.claude/ccpm-config.yaml

# Check permissions
chmod 644 ~/.claude/ccpm-config.yaml

# Validate configuration
./scripts/load-project-config.sh --validate-only

# Test loading
./scripts/load-project-config.sh --json
```

## Advanced Usage

### Multi-Repository Projects

For projects spanning multiple repositories:

```yaml
projects:
  my-platform:
    name: "My Platform"
    repositories:
      frontend:
        url: "https://github.com/company/platform-frontend"
        path: "~/code/platform-frontend"
      backend:
        url: "https://github.com/company/platform-backend"
        path: "~/code/platform-backend"
      mobile:
        url: "https://github.com/company/platform-mobile"
        path: "~/code/platform-mobile"

    # Auto-detect based on any repo
    context:
      detection:
        patterns:
          - pattern: "*/platform-*"
            project: my-platform
```

### Environment-Specific Settings

Different settings per environment:

```yaml
projects:
  my-app:
    environments:
      development:
        base_url: "https://dev.myapp.com"
        db: "dev-db"
      staging:
        base_url: "https://staging.myapp.com"
        db: "staging-db"
      production:
        base_url: "https://myapp.com"
        db: "prod-db"
```

### Team-Shared Configuration

For teams using CCPM together:

```bash
# Store in git repository
cd ~/company-config
git init
cp ~/.claude/ccpm-config.yaml ./ccpm-config-team.yaml
git add ccpm-config-team.yaml
git commit -m "Team CCPM configuration"
git push

# Team members clone and use:
git clone <repo-url> ~/company-config
ln -s ~/company-config/ccpm-config-team.yaml ~/.claude/ccpm-config.yaml
```

## Next Steps

- [Command Reference](../reference/commands.md) - All CCPM commands
- [Hooks Guide](./hooks-installation.md) - Smart agent selection
- [Integration Guide](./integrations.md) - Linear, Jira, GitHub setup
- [CLAUDE.md](../../CLAUDE.md) - Complete CCPM documentation
