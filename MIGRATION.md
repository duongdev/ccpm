# Command Structure Migration

## Issues Fixed

### Issue 1: Commands Not Discovered

**Problem:** CCPM plugin was installed but no commands were showing up in Claude Code.

**Root Cause:** Claude Code requires a **flat directory structure** for plugin commands, but CCPM used nested directories:

### Issue 2: Invalid Plugin Manifest

**Problem:** Plugin failed to load with validation errors:
```
Unrecognized key(s) in object: 'components', 'features', 'requirements', 'safety'
```

**Root Cause:** `plugin.json` contained unsupported fields that are not part of the official Claude Code plugin schema.

```
❌ OLD (nested - not discovered):
commands/
├── spec/
│   ├── create.md
│   └── write.md
├── utils/
│   └── help.md

✅ NEW (flat - properly discovered):
commands/
├── pm:spec:create.md
├── pm:spec:write.md
└── pm:utils:help.md
```

## Solutions Applied

**Date:** November 10, 2025

### Fix 1: Flatten Command Structure
1. Created `scripts/flatten-commands.sh` migration script
2. Renamed all 27 command files from nested structure to flat with namespace prefixes
3. Removed empty subdirectories
4. Updated documentation (CLAUDE.md)

### Fix 2: Correct Plugin Manifest
1. Removed unsupported fields from `plugin.json`:
   - ❌ Removed `components` → ✅ Used individual `commands`, `agents`, `hooks` fields
   - ❌ Removed `features` → ✅ Moved to `.claude-plugin/FEATURES.md`
   - ❌ Removed `requirements` → ✅ Documented in README.md
   - ❌ Removed `safety` → ✅ Kept in `commands/SAFETY_RULES.md`

2. Created documentation files:
   - `.claude-plugin/FEATURES.md` - Feature list and command reference
   - `.claude-plugin/SCHEMA.md` - Valid plugin.json schema documentation

### Result
Both issues are now resolved. The plugin should load correctly and all commands should be discoverable.

## Command Mapping

All commands retained their original slash command syntax:

| Old File Path | New File Path | Slash Command |
|--------------|---------------|---------------|
| `commands/spec/create.md` | `commands/ccpm:spec:create.md` | `/ccpm:spec:create` |
| `commands/utils/help.md` | `commands/ccpm:utils:help.md` | `/ccpm:utils:help` |
| `commands/planning/create.md` | `commands/ccpm:planning:create.md` | `/ccpm:planning:create` |

**Total commands migrated:** 27

## Testing

After migration, commands should be discoverable:

```bash
# Reload plugin (restart Claude Code or reinstall plugin)
/plugin install ccpm@~/personal/ccpm

# Test command discovery
/ccpm:utils:help
/ccpm:spec:create
/ccpm:planning:create
```

## For Plugin Developers

**Key Learnings:**

1. **Claude Code requires flat command directory structure**
   - Commands must be at top level of `commands/` directory
   - Cannot use nested subdirectories for organization

2. **Use filename namespacing for organization**
   - Use `:` separator in filenames: `category:subcategory:command.md`
   - Maps to slash commands: `/category:subcategory:command`

3. **Command file format requirements**
   - YAML frontmatter with `description` field
   - Markdown content with instructions
   - Arguments referenced as `$1`, `$2`, etc.

## References

- [Claude Code Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Flatten Commands Script](./scripts/flatten-commands.sh)
- [Plugin Manifest](./.claude-plugin/plugin.json)
