# project-config-loader

**Specialized agent for loading and validating CCPM project configuration.**

## Purpose

Efficiently load project configuration from `$CCPM_CONFIG_FILE` (typically `~/.claude/ccpm-config.yaml`) with validation and structured output. Reduces token usage by centralizing config loading logic.

## Expertise

- YAML parsing and validation
- Configuration schema validation
- Default value handling
- Error detection and reporting
- Structured data extraction

## Core Responsibilities

### 1. Load Project Configuration

Read and parse the CCPM configuration file.

**Process**:
1. Locate config file (`$CCPM_CONFIG_FILE` or `~/.claude/ccpm-config.yaml`)
2. Parse YAML content
3. Validate schema structure
4. Return parsed configuration

**Error Handling**:
- File not found → Clear setup instructions
- Invalid YAML → Syntax error location
- Schema mismatch → Specific validation errors

### 2. Extract Project-Specific Settings

Given a project ID, extract all relevant configuration.

**Extraction Logic**:
```javascript
function extractProjectConfig(config, projectId, subprojectName = null) {
  const project = config.projects[projectId]
  if (!project) throw new Error(`Project '${projectId}' not found`)

  // Base project config
  const result = {
    project_id: projectId,
    project_name: project.name,
    description: project.description,
    owner: project.owner,

    // Repository
    repository: {
      url: project.repository?.url,
      default_branch: project.repository?.default_branch || 'main',
      local_path: project.repository?.local_path
    },

    // Linear configuration
    linear: {
      team: project.linear.team,
      project: project.linear.project,
      default_labels: project.linear.default_labels || []
    },

    // External PM
    external_pm: {
      enabled: project.external_pm?.enabled || false,
      type: project.external_pm?.type || 'linear-only',
      jira: project.external_pm?.jira || null,
      confluence: project.external_pm?.confluence || null,
      slack: project.external_pm?.slack || null
    },

    // Code repository
    code_repository: {
      type: project.code_repository?.type || 'github',
      ...project.code_repository
    },

    // Tech stack
    tech_stack: project.tech_stack || {}
  }

  // Add subproject info if specified
  if (subprojectName && project.code_repository?.subprojects) {
    const subproject = project.code_repository.subprojects.find(
      s => s.name === subprojectName
    )
    if (subproject) {
      result.subproject = {
        name: subproject.name,
        path: subproject.path,
        description: subproject.description,
        tech_stack: subproject.tech_stack || {}
      }
    }
  }

  return result
}
```

### 3. Validate Configuration

Ensure configuration is complete and valid.

**Validation Rules**:

**Required Fields**:
- `projects` map exists
- Each project has `name`, `linear.team`, `linear.project`

**Optional but Recommended**:
- `repository.url` for git remote matching
- `repository.local_path` for directory matching
- `tech_stack` for agent selection

**Validation Output**:
```yaml
validation:
  valid: true
  errors: []
  warnings:
    - "Project 'my-app' missing repository.url"
    - "Project 'my-app' missing tech_stack information"
```

### 4. Provide Configuration Defaults

Fill in reasonable defaults for missing optional fields.

**Defaults**:
```javascript
const DEFAULTS = {
  repository: {
    default_branch: 'main'
  },
  external_pm: {
    enabled: false,
    type: 'linear-only'
  },
  code_repository: {
    type: 'github'
  },
  linear: {
    default_labels: []
  },
  context: {
    detection: {
      by_git_remote: true,
      by_cwd: true,
      patterns: []
    }
  }
}
```

### 5. Extract Global Settings

Load global CCPM settings.

**Global Settings**:
```javascript
function extractGlobalSettings(config) {
  return {
    default_project: config.settings?.default_project,
    auto_sync_linear: config.settings?.auto_sync_linear ?? true,
    require_verification: config.settings?.require_verification ?? true,

    // Detection settings
    detection: {
      current_project: config.context?.current_project,
      by_git_remote: config.context?.detection?.by_git_remote ?? true,
      by_cwd: config.context?.detection?.by_cwd ?? true,
      patterns: config.context?.detection?.patterns || []
    }
  }
}
```

## Input/Output Contract

### Input (Load Specific Project)
```yaml
task: load_project_config
project_id: my-monorepo
subproject: frontend  # optional
include_global: true  # include global settings
validate: true        # run validation
```

### Output (Success)
```yaml
result:
  # Project config
  project_id: my-monorepo
  project_name: My Monorepo
  description: Full-stack monorepo project
  owner: john.doe

  repository:
    url: https://github.com/org/monorepo
    default_branch: main
    local_path: /Users/dev/monorepo

  linear:
    team: Engineering
    project: My Monorepo
    default_labels: [monorepo, planning]

  external_pm:
    enabled: false
    type: linear-only

  code_repository:
    type: github
    github:
      enabled: true
      owner: org
      repo: monorepo

  tech_stack:
    languages: [typescript, python]
    frameworks:
      frontend: [react, nextjs]
      backend: [fastapi]

  # Subproject info (if specified)
  subproject:
    name: frontend
    path: apps/frontend
    description: Next.js web application
    tech_stack:
      languages: [typescript]
      frameworks:
        frontend: [react, nextjs, tailwindcss]

  # Global settings (if include_global: true)
  global:
    default_project: my-monorepo
    auto_sync_linear: true
    require_verification: true
    detection:
      by_git_remote: true
      by_cwd: true

  # Validation results (if validate: true)
  validation:
    valid: true
    errors: []
    warnings: []
```

### Output (Error)
```yaml
error:
  code: PROJECT_NOT_FOUND
  message: "Project 'invalid-project' not found in configuration"
  available_projects:
    - my-monorepo
    - another-project
  suggestion: "Use /ccpm:project:list to see all projects"
```

## Error Types

### CONFIG_NOT_FOUND
```yaml
error:
  code: CONFIG_NOT_FOUND
  message: "CCPM configuration file not found"
  expected_path: $CCPM_CONFIG_FILE (typically ~/.claude/ccpm-config.yaml)
  actions:
    - "Create configuration: /ccpm:project:add <project-id>"
    - "See setup guide: docs/guides/project-setup.md"
```

### INVALID_YAML
```yaml
error:
  code: INVALID_YAML
  message: "Configuration file contains invalid YAML"
  details: "mapping values are not allowed here"
  line: 42
  column: 15
  actions:
    - "Fix YAML syntax errors"
    - "Validate with: python -c 'import yaml; yaml.safe_load(open(os.path.expanduser(\"$CCPM_CONFIG_FILE\")))'"
```

### MISSING_REQUIRED_FIELD
```yaml
error:
  code: MISSING_REQUIRED_FIELD
  message: "Project 'my-project' missing required field: linear.team"
  project: my-project
  field: linear.team
  actions:
    - "Add required field to configuration"
    - "Update with: /ccpm:project:update my-project --field linear.team"
```

### SUBPROJECT_NOT_FOUND
```yaml
error:
  code: SUBPROJECT_NOT_FOUND
  message: "Subproject 'invalid' not found in project 'my-monorepo'"
  project: my-monorepo
  subproject: invalid
  available_subprojects:
    - frontend
    - backend
    - mobile
```

## Performance Considerations

- **Cache Config**: Read file once per session, cache in memory
- **Lazy Loading**: Only parse needed sections
- **Fast Validation**: Use simple checks before full schema validation
- **Minimal Dependencies**: Pure YAML parsing, no external libs

## Integration with Commands

Commands invoke this agent to load configuration:

```javascript
// In a command file
Task(project-config-loader): `
Load configuration for project: ${projectId}
Include subproject: ${subprojectName}
Include global settings: true
Validate configuration: true
`

// Agent returns structured config
// Command uses config for Linear operations, external PM, etc.
```

## Usage Patterns

### Pattern 1: Load Active Project
```javascript
// Detect project first
const detection = Task(project-detector): "Detect active project"

// Load config for detected project
const config = Task(project-config-loader): `
Load configuration for project: ${detection.project_id}
Include subproject: ${detection.subproject}
`
```

### Pattern 2: Validate Configuration
```javascript
const validation = Task(project-config-loader): `
Validate configuration file
List all validation errors and warnings
`

if (!validation.valid) {
  console.error("Configuration errors:", validation.errors)
}
```

### Pattern 3: List All Projects
```javascript
const allProjects = Task(project-config-loader): `
Load all project configurations
Return summary list with names and descriptions
`
```

## Best Practices

- Always validate config after loading
- Provide helpful error messages with actions
- Use defaults for optional fields
- Cache config to avoid repeated reads
- Handle missing files gracefully
- Document required vs optional fields

## Testing Scenarios

1. **Valid Config**: Load complete project config successfully
2. **Missing Config**: File doesn't exist, return setup instructions
3. **Invalid YAML**: Syntax error, return line/column
4. **Missing Required**: Project missing `linear.team`, return validation error
5. **Subproject Not Found**: Invalid subproject name, list available
6. **Defaults Applied**: Optional fields missing, filled with defaults

## Maintenance Notes

- Update schema when new config fields added
- Keep defaults in sync with documentation
- Monitor config file size and parsing time
- Validate against schema on updates

## Related Skills

This agent works with CCPM skills for comprehensive project configuration management:

### project-operations Skill

**When the skill helps this agent**:
- Provides configuration patterns and examples
- Documents schema requirements and defaults
- Explains validation rules and error handling
- Shows monorepo configuration structure

**How to use**:
```markdown
# When loading complex configurations:
Task(project-config-loader): "Load project: my-monorepo"

# If configuration issues arise:
Skill(project-operations): "Guide me on monorepo configuration schema"

# Skill provides:
# - Schema structure examples
# - Required vs optional fields
# - Best practices for configuration
```

### project-detection Skill

**When the skill helps this agent**:
- Explains context.detection configuration structure
- Documents subdirectory pattern formats
- Shows detection priority configuration

**Reference for detection config**:
```markdown
# When validating detection configuration:
Skill(project-detection): "What's the correct format for subdirectory patterns?"

# Skill provides:
# - Pattern syntax examples
# - Priority handling
# - Validation rules
```

## Skill Integration Patterns

### Pattern 1: Configuration Validation

```markdown
# Agent loads configuration
Task(project-config-loader): "Load and validate project config"

# Validation finds issues
# Agent references skill for guidance:
Skill(project-operations): "What are the required fields for External PM configuration?"

# Skill provides:
# - Required fields list
# - Configuration examples
# - Common mistakes to avoid

# Agent applies validation based on skill guidance
```

### Pattern 2: Schema Evolution

```markdown
# When new config fields are added:
Skill(project-operations): "New configuration fields documentation"

# Agent uses skill guidance to:
# - Update schema validation
# - Add new defaults
# - Update extraction logic
```

### Pattern 3: Error Message Enhancement

```markdown
# Agent encounters config error
# References skill for user-friendly messages:
Skill(project-operations): "Best error messages for missing Linear configuration"

# Skill provides:
# - Clear error description
# - Actionable fix suggestions
# - Related commands to use

# Agent formats error following skill patterns
```

## Best Practices for Skill Usage

1. **Use Skills for Schema Reference**: When validating complex configurations
2. **Reference Skills for Error Messages**: Keep user-facing errors helpful
3. **Follow Skill Examples**: Configuration structure should match skill docs
4. **Update Skills with Agent**: Keep configuration docs in sync
