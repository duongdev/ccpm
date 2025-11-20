# CCPM Path Standardization Standards (PSN-31)

## Overview

This document defines the standardized path variable system for the CCPM plugin. It addresses the need to make all paths portable across different installation environments, eliminating hardcoded absolute paths like `/Users/duongdev/personal/ccpm/` and `~/.claude/plugins/ccpm/`.

**Status**: Phase 1 - Path Variable Definition & Standards
**Scope**: 230+ files, 233+ path references
**Target**: 100% path standardization across all code, documentation, scripts, and configuration

---

## Path Variable System

### Core Path Variables

Path variables should be defined and resolved at runtime by scripts and plugin initialization.

#### Plugin-Level Variables

These variables are resolved at plugin initialization time:

```bash
# Plugin installation root directory
CCPM_PLUGIN_DIR              # e.g., ~/.claude/plugins/ccpm

# Core subdirectories
CCPM_COMMANDS_DIR            # $CCPM_PLUGIN_DIR/commands
CCPM_AGENTS_DIR              # $CCPM_PLUGIN_DIR/agents
CCPM_HOOKS_DIR               # $CCPM_PLUGIN_DIR/hooks
CCPM_SKILLS_DIR              # $CCPM_PLUGIN_DIR/skills
CCPM_SCRIPTS_DIR             # $CCPM_PLUGIN_DIR/scripts
CCPM_DOCS_DIR                # $CCPM_PLUGIN_DIR/docs

# Shared files
CCPM_SHARED_LINEAR_HELPERS   # $CCPM_COMMANDS_DIR/_shared-linear-helpers.md
CCPM_SHARED_WORKFLOW         # $CCPM_COMMANDS_DIR/_shared-planning-workflow.md
CCPM_SHARED_STATE            # $CCPM_COMMANDS_DIR/_shared-workflow-state.md
CCPM_SAFETY_RULES            # $CCPM_COMMANDS_DIR/SAFETY_RULES.md
```

#### User Home Variables

These variables are resolved based on the user's home directory:

```bash
# User's Claude Code directory
CLAUDE_HOME                  # ~/.claude (or $HOME/.claude)

# User's CCPM configuration
CCPM_CONFIG_FILE             # $CLAUDE_HOME/ccpm-config.yaml

# Claude Code directories
CLAUDE_SETTINGS              # $CLAUDE_HOME/settings.json
CLAUDE_COMMANDS              # $CLAUDE_HOME/commands
CLAUDE_AGENTS                # $CLAUDE_HOME/agents
CLAUDE_SKILLS                # $CLAUDE_HOME/skills
CLAUDE_LOGS                  # $CLAUDE_HOME/logs
CLAUDE_BACKUPS               # $CLAUDE_HOME/backups
CLAUDE_PLUGINS               # $CLAUDE_HOME/plugins
```

#### Repository-Level Variables

Used within documentation and development contexts:

```bash
# Repository root (when running from within repo during development)
CCPM_REPO_ROOT               # Repository root directory
```

---

## Usage Patterns by Context

### Pattern 1: Shell Scripts

In bash/shell scripts, define variables at the top:

```bash
#!/bin/bash
# Resolve plugin directory dynamically
if [ -z "$CCPM_PLUGIN_DIR" ]; then
  # Try to find plugin installation
  if [ -d "$HOME/.claude/plugins/ccpm" ]; then
    CCPM_PLUGIN_DIR="$HOME/.claude/plugins/ccpm"
  else
    echo "Error: CCPM plugin not found"
    exit 1
  fi
fi

# Define derived variables
CCPM_COMMANDS_DIR="$CCPM_PLUGIN_DIR/commands"
CCPM_AGENTS_DIR="$CCPM_PLUGIN_DIR/agents"
CCPM_HOOKS_DIR="$CCPM_PLUGIN_DIR/hooks"
CCPM_SCRIPTS_DIR="$CCPM_PLUGIN_DIR/scripts"

# Use in commands
source "$CCPM_COMMANDS_DIR/_shared-linear-helpers.md"
```

### Pattern 2: Markdown Command Files

In markdown commands, reference relative paths using backticks for variable notation:

```markdown
**READ FIRST**: `$CCPM_COMMANDS_DIR/SAFETY_RULES.md`

**READ**: `$CCPM_COMMANDS_DIR/_shared-linear-helpers.md`

**See also**: `$CCPM_DOCS_DIR/guides/installation.md`
```

**Important**: When rendered in Claude Code, these variables will be resolved by the plugin runtime.

### Pattern 3: Documentation Files

In markdown documentation, use relative paths with proper context:

For files within the same directory structure:
```markdown
See [Installation Guide](./installation.md)
See [Safety Rules](../../commands/SAFETY_RULES.md)
```

For external plugin references:
```markdown
The safety rules are defined in: `$CCPM_COMMANDS_DIR/SAFETY_RULES.md`

For more information, see: `$CLAUDE_HOME/plugins/ccpm/docs/guides/installation.md`
```

### Pattern 4: Configuration Files

In YAML/JSON configuration:

```yaml
# ~/.claude/ccpm-config.yaml
version: 1.0

# Use tilde expansion for home directory
ccpm_plugin: ~/.claude/plugins/ccpm

# Or use relative paths for config-relative references
scripts_dir: ./scripts

# For paths that need to be resolved at runtime
workspace:
  root: $HOME/projects
```

### Pattern 5: Inline Examples and Output

When showing example paths in documentation:

```markdown
# Example: Plugin Discovery

The plugin is typically located at:
  ~/.claude/plugins/ccpm

Commands are stored in:
  $CCPM_COMMANDS_DIR (e.g., ~/.claude/plugins/ccpm/commands)

Your CCPM configuration file:
  ~/.claude/ccpm-config.yaml
```

---

## Migration Strategy

### Phase 1: Definition & Standardization (Current)
- Define all path variables (DONE)
- Create this standards document (DONE)
- Audit all files with absolute paths (DONE)
- Create path resolution helper script

### Phase 2: Command File Updates
- Update 32 command files that reference `/Users/duongdev/.claude/commands/pm/`
- Update internal command references
- Test command invocation

### Phase 3: Documentation Updates
- Update 25+ documentation files
- Convert hardcoded paths to variables
- Update links and references

### Phase 4: Script Updates
- Update shell scripts with dynamic path resolution
- Test in multiple environments
- Verify error handling

### Phase 5: Verification & Testing
- Test across different installations
- Verify path resolution in all contexts
- Create comprehensive test suite

---

## File-by-File Migration

### High Priority (Most References)

1. **hooks/smart-agent-selector.prompt** (1 ref)
   - Change: `/Users/duongdev/.claude/plugins/ccpm/` → variable reference

2. **docs/guides/hooks-installation.md** (41 refs)
   - Change: `~/.claude/plugins/ccpm/personal/ccpm/` → `$CCPM_PLUGIN_DIR`
   - Change: `~/.claude/settings.json` → `$CLAUDE_SETTINGS`

3. **README.md** (23 refs)
   - Change: `~/.claude/` references → variables
   - Change: `~/.claude/plugins/ccpm/` → `$CCPM_PLUGIN_DIR`

4. **docs/research/skills/enhancement-index.md** (28 refs)
   - Change: `/Users/duongdev/personal/ccpm/skills/` → `$CCPM_SKILLS_DIR`

5. **commands/** (32 files with `/Users/duongdev/.claude/commands/pm/` refs)
   - All: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md` → `$CCPM_COMMANDS_DIR/SAFETY_RULES.md`

### Medium Priority

6. **docs/research/hooks/implementation-summary.md** (20 refs)
   - Change: `~/.claude/settings.json` → `$CLAUDE_SETTINGS`
   - Change: `~/.claude/plugins/ccpm/` → `$CCPM_PLUGIN_DIR`

7. **docs/research/documentation/global-pattern.md** (11 refs)
   - Change: `~/.claude/` references → variables

8. **scripts/*.sh** (15+ refs)
   - Add dynamic path resolution logic
   - Use variables throughout

### Lower Priority (Documentation/Research)

9. **docs/research/** (45+ references)
   - These are historical/research files
   - Still need standardization for consistency

---

## Resolution Logic

### Plugin Initialization (Claude Code Runtime)

When the CCPM plugin loads, it should resolve path variables:

```javascript
// Pseudo-code for Claude Code plugin runtime
const resolvePaths = () => {
  const homeDir = process.env.HOME || process.env.USERPROFILE;

  return {
    CCPM_PLUGIN_DIR: `${homeDir}/.claude/plugins/ccpm`,
    CCPM_COMMANDS_DIR: `${homeDir}/.claude/plugins/ccpm/commands`,
    CCPM_AGENTS_DIR: `${homeDir}/.claude/plugins/ccpm/agents`,
    CCPM_HOOKS_DIR: `${homeDir}/.claude/plugins/ccpm/hooks`,
    CCPM_SKILLS_DIR: `${homeDir}/.claude/plugins/ccpm/skills`,
    CCPM_SCRIPTS_DIR: `${homeDir}/.claude/plugins/ccpm/scripts`,
    CCPM_DOCS_DIR: `${homeDir}/.claude/plugins/ccpm/docs`,

    CLAUDE_HOME: `${homeDir}/.claude`,
    CCPM_CONFIG_FILE: `${homeDir}/.claude/ccpm-config.yaml`,
    CLAUDE_SETTINGS: `${homeDir}/.claude/settings.json`,
  };
};
```

### Shell Script Resolution

```bash
# In shell scripts, resolve dynamically
resolve_paths() {
  local HOME_DIR="${HOME:?Error: HOME not set}"

  export CCPM_PLUGIN_DIR="${CCPM_PLUGIN_DIR:-$HOME_DIR/.claude/plugins/ccpm}"
  export CCPM_COMMANDS_DIR="$CCPM_PLUGIN_DIR/commands"
  export CCPM_AGENTS_DIR="$CCPM_PLUGIN_DIR/agents"
  export CCPM_HOOKS_DIR="$CCPM_PLUGIN_DIR/hooks"

  # Verify plugin exists
  if [ ! -d "$CCPM_PLUGIN_DIR" ]; then
    echo "Error: CCPM plugin not found at $CCPM_PLUGIN_DIR"
    return 1
  fi
}

# Call at start of script
resolve_paths || exit 1
```

---

## Backward Compatibility

### Handling Hardcoded Paths

During the migration, some files may temporarily contain both variable references and absolute paths. To ensure backward compatibility:

1. **New code** uses only path variables
2. **Legacy references** are marked with `LEGACY:` comments
3. **Deprecation period** of 1 major version (e.g., v2.0 → v3.0)
4. **Final removal** after deprecation period ends

Example:
```markdown
**READ FIRST**: `$CCPM_COMMANDS_DIR/SAFETY_RULES.md`

<!-- LEGACY: Previously referenced as /Users/duongdev/.claude/commands/pm/SAFETY_RULES.md -->
```

---

## Testing Strategy

### Test Categories

#### 1. Path Resolution Tests

```bash
# Test: Variables resolve to existing directories
test_path_resolution() {
  local result=$($CCPM_SCRIPTS_DIR/resolve-paths.sh CCPM_PLUGIN_DIR)
  [ -d "$result" ] || return 1
}

# Test: Shared files exist at resolved paths
test_shared_files() {
  [ -f "$CCPM_COMMANDS_DIR/SAFETY_RULES.md" ] || return 1
  [ -f "$CCPM_COMMANDS_DIR/_shared-linear-helpers.md" ] || return 1
}
```

#### 2. Documentation Link Tests

```bash
# Test: All relative links in docs are valid
test_doc_links() {
  find docs -name "*.md" -exec \
    grep -o '\[.*\](.*\.md)' {} \; | \
    while read link; do
      # Verify file exists
      [ -f "${link#*(}" ] || return 1
    done
}
```

#### 3. Environment Tests

Test in multiple environments:
- macOS with various Claude Code installations
- Linux with various directory structures
- Windows with different path conventions

---

## Documentation Standards

### Linking to Plugin Resources

**Command to Shared Helpers**:
```markdown
**Helper Reference**: `$CCPM_COMMANDS_DIR/_shared-linear-helpers.md`
```

**Documentation to Documentation**:
```markdown
For installation instructions, see [Installation Guide](./installation.md)

For system architecture, see [Architecture](../architecture/overview.md)
```

**Inline Path Examples**:
```markdown
Your CCPM plugin is installed at:
  ~/.claude/plugins/ccpm

Your configuration file:
  ~/.claude/ccpm-config.yaml

To verify installation:
  ls -la ~/.claude/plugins/ccpm/commands/
```

---

## Summary of Changes

| Category | Old Pattern | New Pattern | Count |
|----------|------------|------------|-------|
| Plugin paths | `/Users/duongdev/personal/ccpm/` | `$CCPM_PLUGIN_DIR` | 120+ |
| Command refs | `/Users/duongdev/.claude/commands/pm/` | `$CCPM_COMMANDS_DIR` | 60+ |
| Home paths | `~/.claude/` | Variables (with tilde for docs) | 49+ |
| Total | - | - | **233+** |

---

## Implementation Checklist

- [ ] Path variables defined (DONE)
- [ ] Standards document created (DONE)
- [ ] Audit report completed (DONE)
- [ ] Path resolution script created
- [ ] Command files updated (32 files)
- [ ] Documentation files updated (25+ files)
- [ ] Script files updated (5+ files)
- [ ] Verification tests written
- [ ] Environment testing completed
- [ ] Backward compatibility verified
- [ ] Migration guide created

---

## Future Enhancements

### 1. Dynamic Path Resolution Plugin

Create a Claude Code plugin that automatically resolves path variables in all contexts.

### 2. Path Validation Tool

Build a linting tool that validates all paths in the codebase.

### 3. Cross-Platform Support

Extend path variables to support Windows paths (`%APPDATA%`, etc.) and Linux paths.

### 4. Configuration Management

Create a centralized path configuration system that can be customized per installation.

---

## References

- [CCPM Plugin Structure](../plugin-structure.md)
- [Installation Guide](../../guides/installation.md)
- [SAFETY_RULES.md](../../commands/SAFETY_RULES.md)
- [PSN-31 Audit Report](./pSN-31-audit-report.md)
