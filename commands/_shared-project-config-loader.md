# Shared Project Configuration Loader

**Include this in commands that need project configuration.**

## Usage

Add this to your command file where you need to load project config:

```markdown
**LOAD PROJECT CONFIG** (see `_shared-project-config-loader.md`)
```

## Configuration Loader Code

```bash
# ============================================================================
# Project Configuration Loader
# ============================================================================

CONFIG_FILE="$HOME/.claude/ccpm-config.yaml"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Error: CCPM configuration not found"
  echo ""
  echo "Create configuration:"
  echo "  /ccpm:project:add <project-id>"
  echo ""
  echo "Or copy example:"
  echo "  cp ~/.claude/plugins/ccpm/ccpm-config.example.yaml ~/.claude/ccpm-config.yaml"
  exit 1
fi

# Get project ID from argument (adjust $INDEX based on your command)
# For most commands: $2 is project ID
# Adjust this based on your command's argument structure
PROJECT_ID="${PROJECT_ARG}"  # Set PROJECT_ARG before including this

# If no project specified, try active project
if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID=$(yq eval '.context.current_project' "$CONFIG_FILE" 2>/dev/null)

  if [[ "$PROJECT_ID" == "null" ]] || [[ -z "$PROJECT_ID" ]]; then
    # No active project - list available and exit
    echo "⚠️  No project specified and no active project set"
    echo ""
    echo "Available projects:"
    yq eval '.projects | keys | .[]' "$CONFIG_FILE"
    echo ""
    echo "To use this command:"
    echo "  1. Set active project: /ccpm:project:set <project-id>"
    echo "  2. Or specify in command: <command> ... <project-id>"
    echo ""
    echo "To add a new project:"
    echo "  /ccpm:project:add <project-id>"
    exit 1
  fi

  echo "ℹ️  Using active project: $PROJECT_ID"
fi

# Validate project exists in configuration
if ! yq eval ".projects.$PROJECT_ID" "$CONFIG_FILE" > /dev/null 2>&1; then
  echo "❌ Error: Project '$PROJECT_ID' not found"
  echo ""
  echo "Available projects:"
  yq eval '.projects | keys | .[]' "$CONFIG_FILE"
  echo ""
  echo "Add project:"
  echo "  /ccpm:project:add $PROJECT_ID"
  exit 1
fi

# Load all project settings into variables
PROJECT_NAME=$(yq eval ".projects.$PROJECT_ID.name" "$CONFIG_FILE")
PROJECT_DESCRIPTION=$(yq eval ".projects.$PROJECT_ID.description" "$CONFIG_FILE")

# Linear configuration
LINEAR_TEAM=$(yq eval ".projects.$PROJECT_ID.linear.team" "$CONFIG_FILE")
LINEAR_PROJECT=$(yq eval ".projects.$PROJECT_ID.linear.project" "$CONFIG_FILE")
LINEAR_DEFAULT_LABELS=$(yq eval ".projects.$PROJECT_ID.linear.default_labels[]" "$CONFIG_FILE" | tr '\n' ',' | sed 's/,$//')

# External PM configuration
EXTERNAL_PM_ENABLED=$(yq eval ".projects.$PROJECT_ID.external_pm.enabled" "$CONFIG_FILE")
EXTERNAL_PM_TYPE=$(yq eval ".projects.$PROJECT_ID.external_pm.type" "$CONFIG_FILE")

# Jira configuration (if enabled)
if [[ "$EXTERNAL_PM_ENABLED" == "true" ]] && [[ "$EXTERNAL_PM_TYPE" == "jira" ]]; then
  JIRA_ENABLED=$(yq eval ".projects.$PROJECT_ID.external_pm.jira.enabled" "$CONFIG_FILE")
  JIRA_BASE_URL=$(yq eval ".projects.$PROJECT_ID.external_pm.jira.base_url" "$CONFIG_FILE")
  JIRA_PROJECT_KEY=$(yq eval ".projects.$PROJECT_ID.external_pm.jira.project_key" "$CONFIG_FILE")

  CONFLUENCE_ENABLED=$(yq eval ".projects.$PROJECT_ID.external_pm.confluence.enabled" "$CONFIG_FILE")
  CONFLUENCE_BASE_URL=$(yq eval ".projects.$PROJECT_ID.external_pm.confluence.base_url" "$CONFIG_FILE")
  CONFLUENCE_SPACE_KEY=$(yq eval ".projects.$PROJECT_ID.external_pm.confluence.space_key" "$CONFIG_FILE")

  SLACK_ENABLED=$(yq eval ".projects.$PROJECT_ID.external_pm.slack.enabled" "$CONFIG_FILE")
  SLACK_WORKSPACE=$(yq eval ".projects.$PROJECT_ID.external_pm.slack.workspace" "$CONFIG_FILE")
fi

# Repository configuration
REPO_TYPE=$(yq eval ".projects.$PROJECT_ID.code_repository.type" "$CONFIG_FILE")

if [[ "$REPO_TYPE" == "github" ]]; then
  GITHUB_OWNER=$(yq eval ".projects.$PROJECT_ID.code_repository.github.owner" "$CONFIG_FILE")
  GITHUB_REPO=$(yq eval ".projects.$PROJECT_ID.code_repository.github.repo" "$CONFIG_FILE")
elif [[ "$REPO_TYPE" == "bitbucket" ]]; then
  BITBUCKET_WORKSPACE=$(yq eval ".projects.$PROJECT_ID.code_repository.bitbucket.workspace" "$CONFIG_FILE")
  BITBUCKET_REPO=$(yq eval ".projects.$PROJECT_ID.code_repository.bitbucket.repo_slug" "$CONFIG_FILE")
  BITBUCKET_BASE_URL=$(yq eval ".projects.$PROJECT_ID.code_repository.bitbucket.base_url" "$CONFIG_FILE")
fi

# Display loaded configuration (optional - for debugging)
echo "✅ Loaded project configuration: $PROJECT_NAME"
echo "   Linear: $LINEAR_TEAM / $LINEAR_PROJECT"
echo "   External PM: $([ "$EXTERNAL_PM_ENABLED" = "true" ] && echo "$EXTERNAL_PM_TYPE" || echo "disabled")"
echo ""

# ============================================================================
# Available Variables After Loading:
# ============================================================================
# - PROJECT_ID: Project identifier
# - PROJECT_NAME: Human-readable project name
# - PROJECT_DESCRIPTION: Project description
#
# Linear:
# - LINEAR_TEAM: Linear team name
# - LINEAR_PROJECT: Linear project name
# - LINEAR_DEFAULT_LABELS: Comma-separated labels
#
# External PM:
# - EXTERNAL_PM_ENABLED: true/false
# - EXTERNAL_PM_TYPE: jira/github/linear-only
#
# Jira (if enabled):
# - JIRA_ENABLED: true/false
# - JIRA_BASE_URL: https://jira.company.com
# - JIRA_PROJECT_KEY: PROJ
# - CONFLUENCE_ENABLED: true/false
# - CONFLUENCE_BASE_URL: https://confluence.company.com
# - CONFLUENCE_SPACE_KEY: PROJ
# - SLACK_ENABLED: true/false
# - SLACK_WORKSPACE: company-workspace
#
# Repository:
# - REPO_TYPE: github/bitbucket/gitlab
# - GITHUB_OWNER, GITHUB_REPO (if GitHub)
# - BITBUCKET_WORKSPACE, BITBUCKET_REPO, BITBUCKET_BASE_URL (if BitBucket)
# ============================================================================
```

## Example Usage in Commands

### In planning:create.md

```markdown
## Load Project Configuration

Set the project argument index:
```bash
PROJECT_ARG="$2"  # $2 is the project ID in this command
```

**LOAD PROJECT CONFIG** (see `_shared-project-config-loader.md`)

Now you can use all the loaded variables:
- ${LINEAR_TEAM}
- ${LINEAR_PROJECT}
- ${JIRA_ENABLED}
- etc.
```

### In planning:plan.md

```markdown
## Load Project Configuration

Set the project argument:
```bash
# Extract from Linear issue or use argument
PROJECT_ARG=$(get_project_from_issue "$1")  # Or $2, etc.
```

**LOAD PROJECT CONFIG** (see `_shared-project-config-loader.md`)
```

## Notes

- Commands must set `PROJECT_ARG` before loading
- All variables are available after loading
- Handles active project fallback automatically
- Provides helpful error messages
- Validates project exists before proceeding
