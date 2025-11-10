# Plugin.json Schema Documentation

## Supported Fields (as of Claude Code latest)

Based on the official [Plugins Reference](https://code.claude.com/docs/en/plugins-reference), these are the **only** supported fields in `plugin.json`:

### Required Fields

```json
{
  "name": "plugin-name"  // REQUIRED: Unique identifier in kebab-case
}
```

### Metadata Fields

```json
{
  "version": "1.0.0",    // Semantic version
  "description": "...",  // Brief plugin description
  "author": {            // Author information
    "name": "Your Name",
    "email": "you@example.com",
    "url": "https://example.com"
  },
  "homepage": "https://...",    // Documentation URL
  "repository": "https://...",  // Source code URL
  "license": "MIT",             // License identifier
  "keywords": ["tag1", "tag2"]  // Discovery tags
}
```

### Component Path Fields

```json
{
  "commands": "./commands",           // Path to commands directory (optional)
  "agents": "./agents/agent.md",      // Path to .md file(s) - MUST end with .md
  "hooks": "./hooks/hooks.json",      // Path to hooks.json - MUST end with .json
  "mcpServers": "./mcp.json"          // Path to MCP server config
}
```

**Critical Requirements:**
- `hooks` field **MUST** point to a `.json` file (e.g., `./hooks/hooks.json`)
- `agents` field **MUST** point to `.md` file(s), NOT directories
- All paths must be **relative** and start with `./`
- These paths **supplement** (not replace) default directories
- Default directories are always checked: `commands/`, `agents/`, `hooks/`

**Validation errors you'll see if paths are wrong:**
- `hooks: Invalid input: must end with ".json"` - hooks must point to JSON file
- `agents: Invalid input: must end with ".md"` - agents must point to markdown file(s)

## Unsupported Fields

The following fields are **NOT supported** and will cause validation errors:

### ❌ `components`
```json
// INVALID - Use individual path fields instead
"components": {
  "commands": "./commands",
  "agents": "./agents"
}
```

**Use instead:**
```json
"commands": "./commands",      // Optional: points to directory
"hooks": "./hooks/hooks.json"  // MUST end with .json
// Note: omit "agents" to use default agents/ directory
```

**Common mistakes:**
```json
// ❌ WRONG - hooks pointing to directory
"hooks": "./hooks"

// ✅ CORRECT - hooks pointing to JSON file
"hooks": "./hooks/hooks.json"

// ❌ WRONG - agents pointing to directory
"agents": "./agents"

// ✅ CORRECT - omit agents field entirely, or point to specific .md file(s)
// (omitted) - uses default agents/ directory
```

### ❌ `features`
```json
// INVALID - Features are not part of the schema
"features": {
  "spec_management": { ... }
}
```

**Alternative:** Document features in separate markdown files (e.g., `FEATURES.md`)

### ❌ `requirements`
```json
// INVALID - Requirements are not validated by schema
"requirements": {
  "mcp_servers": ["linear", "github"]
}
```

**Alternative:** Document in README or separate REQUIREMENTS.md file

### ❌ `safety`
```json
// INVALID - Safety rules are not part of plugin manifest
"safety": {
  "external_writes": "require_confirmation"
}
```

**Alternative:** Document safety rules in command files or separate SAFETY_RULES.md

## Migration from v1 Schema

If you have a plugin with unsupported fields:

1. **Extract to separate files:**
   - `features` → `FEATURES.md`
   - `requirements` → README.md or REQUIREMENTS.md
   - `safety` → commands/SAFETY_RULES.md
   - `components` → Use individual path fields

2. **Update plugin.json:**
   ```bash
   # Only keep supported fields
   {
     "name": "...",
     "version": "...",
     "description": "...",
     "author": { ... },
     "keywords": [...],
     "homepage": "...",
     "repository": "...",
     "license": "...",
     "commands": "./commands",
     "agents": "./agents",
     "hooks": "./hooks"
   }
   ```

3. **Test validation:**
   ```bash
   /plugin install plugin-name@path
   ```

## References

- [Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
