# Monorepo Setup Guide

Complete guide to setting up CCPM for monorepo projects with automatic subdirectory detection.

## Overview

CCPM v2.1+ supports monorepos with multiple subprojects. When you navigate between subdirectories, CCPM automatically detects which subproject you're working in and adjusts:

- Active project context
- Tech stack for agent selection
- Labels for Linear issues
- Command behavior

## Quick Start

### 1. Add Your Monorepo Project

```bash
/ccpm:project:add my-monorepo
```

Follow the prompts to configure basic settings (Linear team, external PM, etc.).

### 2. Configure Subdirectories

Edit `~/.claude/ccpm-config.yaml` to add subdirectory detection:

```yaml
projects:
  my-monorepo:
    repository:
      local_path: "/Users/dev/my-monorepo"

    # Subdirectory detection configuration
    context:
      detection:
        subdirectories:
          - subproject: "frontend"
            match_pattern: "*/apps/frontend/*"
            priority: 10
          - subproject: "backend"
            match_pattern: "*/apps/backend/*"
            priority: 10

    # Subproject metadata
    code_repository:
      subprojects:
        - name: "frontend"
          path: "apps/frontend"
          description: "Next.js web application"
          tech_stack:
            languages: [typescript]
            frameworks:
              frontend: [react, nextjs, tailwindcss]

        - name: "backend"
          path: "apps/backend"
          description: "FastAPI backend service"
          tech_stack:
            languages: [python]
            frameworks:
              backend: [fastapi]
            database: [postgresql]
```

### 3. Enable Auto-Detection

```bash
/ccpm:project:set auto
```

### 4. Test It!

```bash
cd ~/my-monorepo/apps/frontend
/ccpm:project:list
# Should show: ⭐ my-monorepo › frontend
```

## Configuration Details

### Subdirectory Detection

The `context.detection.subdirectories` section configures pattern matching:

```yaml
context:
  detection:
    subdirectories:
      - subproject: "frontend"           # Name matching subprojects below
        match_pattern: "*/apps/frontend/*"  # Glob pattern
        priority: 10                      # Higher = more specific
```

**Pattern Syntax:**
- `*/path/*` - Matches path with any prefix/suffix
- `**/path/**` - Matches path at any depth
- `apps/*/src` - Matches specific structure

**Priority Guidelines:**
- `5` - General, low-priority patterns
- `10` - Standard subprojects (default)
- `15-20` - Specific nested paths
- Higher priority wins when multiple patterns match

### Subproject Metadata

The `code_repository.subprojects` section defines metadata:

```yaml
code_repository:
  subprojects:
    - name: "frontend"              # Must match detection.subdirectories
      path: "apps/frontend"         # Relative to repo root
      description: "Web application"
      tech_stack:                   # Used for agent selection
        languages: [typescript]
        frameworks:
          frontend: [react, nextjs]
          backend: []
        database: []
```

## Common Monorepo Setups

### Nx Monorepo

```yaml
projects:
  my-nx-workspace:
    repository:
      local_path: "/Users/dev/my-nx-workspace"

    context:
      detection:
        subdirectories:
          - subproject: "web-app"
            match_pattern: "*/apps/web/*"
            priority: 10
          - subproject: "mobile-app"
            match_pattern: "*/apps/mobile/*"
            priority: 10
          - subproject: "shared-ui"
            match_pattern: "*/libs/shared-ui/*"
            priority: 10

    code_repository:
      subprojects:
        - name: "web-app"
          path: "apps/web"
          tech_stack:
            languages: [typescript]
            frameworks:
              frontend: [react, nextjs]

        - name: "mobile-app"
          path: "apps/mobile"
          tech_stack:
            languages: [typescript]
            frameworks:
              frontend: [react-native, expo]

        - name: "shared-ui"
          path: "libs/shared-ui"
          tech_stack:
            languages: [typescript]
            frameworks:
              frontend: [react]
```

### Turborepo

```yaml
projects:
  my-turborepo:
    repository:
      local_path: "/Users/dev/my-turborepo"

    context:
      detection:
        subdirectories:
          - subproject: "docs"
            match_pattern: "*/apps/docs/*"
            priority: 10
          - subproject: "web"
            match_pattern: "*/apps/web/*"
            priority: 10
          - subproject: "ui-library"
            match_pattern: "*/packages/ui/*"
            priority: 10

    code_repository:
      subprojects:
        - name: "docs"
          path: "apps/docs"
          tech_stack:
            languages: [typescript]
            frameworks:
              frontend: [nextjs]

        - name: "web"
          path: "apps/web"
          tech_stack:
            languages: [typescript]
            frameworks:
              frontend: [react, nextjs]

        - name: "ui-library"
          path: "packages/ui"
          tech_stack:
            languages: [typescript]
            frameworks:
              frontend: [react]
```

### Lerna / pnpm Workspaces

```yaml
projects:
  my-workspace:
    repository:
      local_path: "/Users/dev/my-workspace"

    context:
      detection:
        subdirectories:
          - subproject: "api-server"
            match_pattern: "*/packages/api/*"
            priority: 10
          - subproject: "web-client"
            match_pattern: "*/packages/web/*"
            priority: 10
          - subproject: "cli-tool"
            match_pattern: "*/packages/cli/*"
            priority: 10

    code_repository:
      subprojects:
        - name: "api-server"
          path: "packages/api"
          tech_stack:
            languages: [typescript]
            frameworks:
              backend: [express]
            database: [mongodb]

        - name: "web-client"
          path: "packages/web"
          tech_stack:
            languages: [typescript]
            frameworks:
              frontend: [react, vite]

        - name: "cli-tool"
          path: "packages/cli"
          tech_stack:
            languages: [typescript]
            frameworks:
              backend: [nodejs]
```

## Management Commands

### Add Subdirectory

```bash
# Interactive mode
/ccpm:project:subdir:add my-monorepo

# Command-line mode
/ccpm:project:subdir:add my-monorepo mobile apps/mobile

# With custom pattern and priority
/ccpm:project:subdir:add my-monorepo admin apps/web/admin --pattern "*/apps/web/admin/*" --priority 15
```

### List Subdirectories

```bash
/ccpm:project:subdir:list my-monorepo
```

Output shows:
- All configured subdirectories
- Detection patterns
- Tech stacks
- Active subproject (marked with ⭐)

### Update Subdirectory

```bash
# Interactive update (all fields)
/ccpm:project:subdir:update my-monorepo frontend

# Update specific field
/ccpm:project:subdir:update my-monorepo frontend --field tech_stack
/ccpm:project:subdir:update my-monorepo frontend --field description
/ccpm:project:subdir:update my-monorepo frontend --field pattern
```

### Remove Subdirectory

```bash
/ccpm:project:subdir:remove my-monorepo old-service
```

Requires confirmation before removing.

## Detection Flow

When you run a command, CCPM detects your context:

1. **Manual Setting** (if set with `/ccpm:project:set`)
2. **Git Remote URL** (matches `repository.url`)
3. **Subdirectory Pattern** (NEW - matches `context.detection.subdirectories`)
4. **Local Path** (matches `repository.local_path`)
5. **Custom Patterns** (matches `context.detection.patterns`)

**Example:**

```bash
cd ~/my-monorepo/apps/frontend/src/components
/ccpm:planning:create "Add dark mode toggle"
```

Detection:
1. Git remote matches "my-monorepo" ✓
2. Working directory matches "*/apps/frontend/*" ✓
3. Result: project="my-monorepo", subproject="frontend"
4. Linear issue created with labels: ["my-monorepo", "frontend", "planning"]
5. Agent selection uses frontend tech stack (React, Next.js)

## How Commands Use Subproject Context

### Planning Commands

```bash
cd ~/monorepo/apps/mobile
/ccpm:planning:create "Add push notifications"
```

- Creates Linear issue with subproject label: "mobile"
- Uses mobile tech stack for Context7 research
- Agent selection considers React Native expertise

### Project Commands

```bash
/ccpm:project:list
```

Shows:
```
⭐ my-monorepo › mobile
   Subproject:  📁 apps/mobile
   Tech Stack:  typescript, react-native, expo
   Status:      🟢 Active (Subdirectory match)
```

```bash
/ccpm:project:show my-monorepo
```

Displays all subprojects with:
- Paths
- Tech stacks
- Detection patterns
- Active marker (⭐)

## Nested Subdirectories

For nested structures, use priority to resolve conflicts:

```yaml
context:
  detection:
    subdirectories:
      # More specific (higher priority)
      - subproject: "admin-panel"
        match_pattern: "*/apps/web/admin/*"
        priority: 20

      # General web app (lower priority)
      - subproject: "web-app"
        match_pattern: "*/apps/web/*"
        priority: 10
```

Working in `/apps/web/admin/` → Detects "admin-panel" (priority 20)
Working in `/apps/web/public/` → Detects "web-app" (priority 10)

## Troubleshooting

### Wrong Subproject Detected

**Problem**: CCPM detects wrong subproject or no subproject.

**Solutions**:
1. Check patterns match your directory structure:
   ```bash
   pwd  # Check current directory
   /ccpm:project:subdir:list my-monorepo  # Check configured patterns
   ```

2. Verify `local_path` is set:
   ```bash
   /ccpm:project:show my-monorepo
   # Look for: "Local Path: /Users/dev/my-monorepo"
   ```

3. Test pattern manually:
   ```bash
   # If pwd = /Users/dev/my-monorepo/apps/frontend/src
   # Pattern "*/apps/frontend/*" should match
   ```

4. Adjust priority if multiple patterns match:
   ```bash
   /ccpm:project:subdir:update my-monorepo frontend --field priority
   # Enter higher priority (e.g., 15)
   ```

### No Subdirectory Detected

**Problem**: Commands don't show subproject context.

**Solutions**:
1. Enable auto-detection:
   ```bash
   /ccpm:project:set auto
   ```

2. Verify you're in the project directory:
   ```bash
   pwd  # Should be within repository.local_path
   ```

3. Check subdirectories are configured:
   ```bash
   /ccpm:project:subdir:list my-monorepo
   # Should list configured subdirectories
   ```

### Subdirectory Not in List

**Problem**: New subdirectory not showing in commands.

**Solution**: Add it:
```bash
/ccpm:project:subdir:add my-monorepo new-service services/new-service
```

## Best Practices

1. **Use Descriptive Names**: `mobile-app` instead of `app2`
2. **Match Your Structure**: Patterns should reflect your actual directory layout
3. **Set Appropriate Priorities**: Use 10 for standard, 15-20 for specific/nested
4. **Configure Tech Stacks**: Helps with agent selection and documentation
5. **Test After Configuration**: Navigate to subdirectories and verify detection
6. **Document Subprojects**: Add clear descriptions for team members

## Integration with Other Features

### With Planning Commands

Subproject context automatically flows to planning:
- Linear issue labels include subproject
- Tech stack used for Context7 research
- Spec templates consider subproject type

### With Agent Selection

Smart agent selection uses subproject tech stack:
- Frontend subproject → frontend-developer agent
- Backend subproject → backend-architect agent
- Mobile subproject → mobile-developer agent

### With TDD Enforcement

Test location detection considers subproject paths:
- `apps/frontend/__tests__/` for frontend
- `apps/backend/tests/` for backend
- Each subproject can have different test conventions

## Next Steps

- [Project Setup Guide](./project-setup.md) - Basic project configuration
- [Command Reference](../../commands/README.md) - All available commands
- [Agent Architecture](../architecture/project-agents.md) - How agents work
- [Examples](../../examples/monorepo-configs.yaml) - Real-world configurations
