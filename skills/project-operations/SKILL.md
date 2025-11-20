---
name: project-operations
description: Provides intelligent project setup and management with agent-based architecture to minimize token usage. Auto-activates when user mentions project setup, "add project", "configure project", "monorepo", "subdirectories", "switch project", or "project info". Uses three specialized agents internally: project-detector (detect active), project-config-loader (load settings with validation), project-context-manager (manage active project). Guides through four workflows: Add New Project (setup + templates), Configure Monorepo (pattern matching + subdirectories), Switch Between Projects (auto or manual), View Project Information. Provides templates for common architectures (fullstack-with-jira, fullstack-linear-only, mobile-app, monorepo). Validates configuration and suggests fixes for errors. Handles context-aware error handling with specific fix suggestions.
---

# Project Operations Skill

This skill handles all project-related operations in CCPM, including setup, configuration, detection, and multi-project management. It automatically invokes specialized agents to optimize performance and reduce token usage.

## Instructions

### Automatic Activation

This skill activates when user mentions:
- Project setup or configuration
- Adding/updating/deleting projects
- Multi-project management
- Monorepo or subdirectory configuration
- Project switching or detection
- Active project context

### Core Principles

1. **Agent-First Approach**: Always use specialized agents for project operations
2. **Minimal Token Usage**: Agents handle heavy logic, skills provide guidance
3. **Context-Aware**: Detect project context before operations
4. **User-Friendly**: Clear errors and actionable suggestions

### Agent Usage Patterns

#### Pattern 1: Detect Project Context

**When**: Command needs to know active project

**Implementation**:
```javascript
// Always start with detection
const detection = Task(project-detector): `
Detect active project for current environment

Current directory: ${cwd}
Git remote: ${gitRemote}
`

// Then load full config
const context = Task(project-context-manager): `
Get full context for detected project
Project ID: ${detection.project_id}
Subproject: ${detection.subproject}
Include config: true
Format: standard
`

// Use context for operations
console.log(`📋 Project: ${context.display.title}`)
```

**Benefits**:
- Consistent detection logic
- Reduces token usage (agent handles logic)
- Structured output ready for use

#### Pattern 2: Load Project Configuration

**When**: Command needs project settings (Linear, Jira, tech stack)

**Implementation**:
```javascript
const config = Task(project-config-loader): `
Load configuration for project: ${projectId}
Include subproject: ${subprojectName}
Validate: true
`

if (!config.validation.valid) {
  console.error("Configuration errors:", config.validation.errors)
  return
}

// Use config
const linearTeam = config.linear.team
const techStack = config.tech_stack.languages
```

**Benefits**:
- Validation built-in
- Structured, type-safe output
- Errors with actionable messages

#### Pattern 3: Manage Project Context

**When**: Setting active project, enabling auto-detection

**Implementation**:
```javascript
// Set active project
const result = Task(project-context-manager): `
Set active project: ${projectId}
Mode: manual
Disable auto-detection: false
`

console.log(`✅ ${result.message}`)

// Or enable auto-detection
const result = Task(project-context-manager): `
Enable auto-detection
`

console.log(`✅ Auto-detection enabled`)
console.log(`Methods: ${result.methods.join(', ')}`)
```

### Project Setup Workflows

#### Workflow 1: Add New Project

**Trigger phrases**:
- "add a new project"
- "configure new project"
- "set up project"

**Command**: `/ccpm:project:add <project-id> [--template TEMPLATE]`

**Guidance**:
```
Let's set up your new project!

Quick templates available:
1. fullstack-with-jira - Full-stack app with Jira integration
2. fullstack-linear-only - Full-stack app, Linear-only
3. mobile-app - React Native / Expo mobile app
4. monorepo - Multi-project repository with subdirectories

Or create custom configuration interactively.

Example:
/ccpm:project:add my-app --template fullstack-with-jira
```

#### Workflow 2: Configure Monorepo with Subdirectories

**Trigger phrases**:
- "monorepo setup"
- "subdirectories"
- "multiple projects in one repo"

**Guidance**:
```
For monorepos with subdirectories (like Nx, Turborepo):

1. Add the project:
   /ccpm:project:add my-monorepo

2. Configure subdirectory detection:
   Edit ~/.claude/ccpm-config.yaml:

   ```yaml
   my-monorepo:
     repository:
       local_path: /Users/dev/monorepo

     context:
       detection:
         subdirectories:
           - subproject: frontend
             match_pattern: "*/apps/frontend/*"
             priority: 10
           - subproject: backend
             match_pattern: "*/apps/backend/*"
             priority: 10

     code_repository:
       subprojects:
         - name: frontend
           path: apps/frontend
           tech_stack:
             languages: [typescript]
             frameworks:
               frontend: [react, nextjs]
   ```

3. Enable auto-detection:
   /ccpm:project:set auto

4. Test detection:
   cd /Users/dev/monorepo/apps/frontend
   /ccpm:project:list  # Should show "frontend" subproject active
```

#### Workflow 3: Switch Between Projects

**Trigger phrases**:
- "switch project"
- "change active project"
- "work on different project"

**Commands**:
- `/ccpm:project:set <project-id>` - Set specific project
- `/ccpm:project:set auto` - Enable auto-detection
- `/ccpm:project:list` - See all projects with active marker

**Agent usage**:
```javascript
// Commands internally use:
Task(project-context-manager): `
Set active project: ${projectId}
Mode: manual
`

// Then display with:
Task(project-context-manager): `
Get context
Format: standard
`
```

#### Workflow 4: View Project Information

**Trigger phrases**:
- "show project details"
- "what's my current project"
- "project info"

**Commands**:
- `/ccpm:project:show <project-id>` - Detailed project info
- `/ccpm:project:list` - List all projects
- `/ccpm:utils:status <issue-id>` - Task with project context

**Agent usage**:
```javascript
Task(project-context-manager): `
Get context for project: ${projectId}
Format: detailed
Include all sections: true
`

// Returns full display-ready output
```

### Subdirectory Detection

#### How It Works

1. **Git Remote Match**: Matches repo URL (highest priority after manual)
2. **Subdirectory Pattern Match**: Matches working directory against patterns
3. **Local Path Match**: Falls back to project root match

**Example**:
```
Working in: /Users/dev/repeat/jarvis/src

Detection flow:
1. Check git remote → matches "repeat" project ✓
2. Check subdirectory patterns:
   - "*/xygaming_symfony/*" → ❌
   - "*/jarvis/*" → ✅ Match!
3. Return: project="repeat", subproject="jarvis"

Result:
📋 Project: Repeat › jarvis
🛠️ Tech Stack: TypeScript, Next.js, NestJS
```

#### Configuration Format

```yaml
projects:
  my-monorepo:
    repository:
      local_path: /Users/dev/monorepo

    # Subdirectory detection
    context:
      detection:
        subdirectories:
          # Each subdirectory rule
          - subproject: frontend        # Name (references subprojects below)
            match_pattern: "*/apps/frontend/*"  # Glob pattern
            priority: 10                # Higher = more specific

          - subproject: backend
            match_pattern: "*/apps/backend/*"
            priority: 10

          - subproject: mobile
            match_pattern: "*/apps/mobile/*"
            priority: 10

    # Metadata about subprojects (optional but recommended)
    code_repository:
      subprojects:
        - name: frontend
          path: apps/frontend
          description: Next.js web application
          tech_stack:
            languages: [typescript]
            frameworks:
              frontend: [react, nextjs, tailwindcss]
```

### Error Handling

#### No Project Detected

**Error**:
```
❌ Could not detect active project

Suggestions:
- Set active project: /ccpm:project:set <project-id>
- Enable auto-detection: /ccpm:project:set auto
- Check you're in a configured project directory
```

**Solution with agents**:
```javascript
const detection = Task(project-detector): "Detect active project"

if (detection.error) {
  console.log(detection.error.message)
  console.log("\nSuggestions:")
  detection.error.suggestions.forEach(s => console.log(`- ${s}`))
}
```

#### Configuration Error

**Error**:
```
❌ Project configuration invalid

Project 'my-app' missing required field: linear.team

Fix with: /ccpm:project:update my-app --field linear.team
```

**Solution with agents**:
```javascript
const config = Task(project-config-loader): `
Load project: ${projectId}
Validate: true
`

if (!config.validation.valid) {
  config.validation.errors.forEach(err => {
    console.error(`❌ ${err.message}`)
    err.actions?.forEach(action => console.log(`   Fix: ${action}`))
  })
}
```

### Best Practices

1. **Always Detect First**: Start commands with project detection
2. **Use Agents for Logic**: Don't reimplement detection/loading
3. **Cache Context**: Detect once, use throughout command
4. **Display Context**: Show users which project is active
5. **Handle Errors Gracefully**: Provide actionable error messages
6. **Support Auto-Detection**: Let users work naturally

### Command Integration Examples

#### Example 1: Planning Command with Project Context

```markdown
# In /ccpm:planning:create

Task(project-context-manager): `
Get active project context
Include: detection + config
Format: compact
`

# Display: 📋 Project: My Monorepo › frontend

# Use context for Linear:
linear_create_issue({
  team: context.config.linear.team,
  project: context.config.linear.project,
  labels: context.display.labels
})
```

#### Example 2: Implementation Command with Subproject Info

```markdown
# In /ccpm:implementation:start

const context = Task(project-context-manager): "Get context"

console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Starting Implementation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project:     ${context.config.project_name}
Subproject:  ${context.config.subproject?.name || 'N/A'}
Tech Stack:  ${context.display.subtitle}
Location:    ${context.display.location}
`)

# Agent selection uses tech stack:
const agents = selectAgents(context.config.subproject?.tech_stack || context.config.tech_stack)
```

### Performance Optimizations

1. **Agent Caching**: Agents handle caching internally
2. **Lazy Loading**: Only load config when needed
3. **Parallel Ops**: Detect and load in parallel when possible
4. **Session State**: Cache detection result for command duration

### Testing

Test with these scenarios:

1. **Simple Project**: Single repo, no subdirectories
2. **Monorepo**: Multiple subdirectories with patterns
3. **Manual Override**: User sets specific project
4. **Auto-Detection**: Switch directories, auto-detect
5. **No Config**: Fresh install, guide user to setup
6. **Invalid Config**: Missing fields, show validation errors

### Migration Guide

**From inline logic to agents**:

Before:
```markdown
# Read config file
# Parse YAML
# Validate project
# Extract settings
# 50+ lines of logic
```

After:
```markdown
Task(project-config-loader): `Load project: ${projectId}`

# 1 line, agent handles everything
```

**Token savings**: ~80% reduction in command size

### Related Commands

- `/ccpm:project:add` - Add new project
- `/ccpm:project:list` - List all projects
- `/ccpm:project:show` - Show project details
- `/ccpm:project:set` - Set active project
- `/ccpm:project:update` - Update project config
- `/ccpm:project:delete` - Delete project

### Maintenance

**When to update this skill**:
- New project config fields added
- New detection methods implemented
- Agent interfaces change
- New project templates added

**Update locations**:
- This skill (guidance and examples)
- Project agents (implementation)
- Command files (integration)
- Documentation (user-facing guides)
