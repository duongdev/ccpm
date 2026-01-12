---
description: Verify and fix CCPM plugin installation for local development
---

# /update-local - Verify CCPM Plugin Installation

This command verifies the CCPM plugin is correctly installed with a symlink to the local development directory, ensuring local changes are immediately available.

## Implementation

Run these verification steps in order:

### Step 1: Check Plugin Cache Structure

```bash
# Check if plugin cache directory exists
ls -la ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm/ 2>/dev/null || echo "MISSING: Plugin cache directory"
```

### Step 2: Verify Symlink

```bash
# Check if 1.2.0 is a symlink pointing to the dev directory
LINK_TARGET=$(readlink ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm/1.2.1 2>/dev/null)
DEV_DIR="/Users/duongdev/personal/ccpm"

if [ -z "$LINK_TARGET" ]; then
  echo "STATUS: Not a symlink or doesn't exist"
elif [ "$LINK_TARGET" = "$DEV_DIR" ]; then
  echo "STATUS: Symlink OK -> $DEV_DIR"
else
  echo "STATUS: Wrong symlink target -> $LINK_TARGET"
fi
```

### Step 3: Fix If Needed

If the symlink is missing or incorrect, recreate it:

```bash
# Recreate plugin cache with symlink
mkdir -p ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm
rm -rf ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm/1.2.1
ln -s /Users/duongdev/personal/ccpm ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm/1.2.1
echo "FIXED: Symlink recreated"
```

### Step 4: Verify Key Files

```bash
# Verify critical files are accessible through the symlink
echo "Checking key files..."

FILES=(
  "commands/plan.md"
  "commands/work.md"
  "helpers/checklist.md"
  "hooks/hooks.json"
  "hooks/scripts/session-init.cjs"
  "hooks/scripts/guard-commit.cjs"
  "hooks/scripts/smart-agent-selector.sh"
)

CACHE_PATH=~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm/1.2.1

for file in "${FILES[@]}"; do
  if [ -f "$CACHE_PATH/$file" ]; then
    echo "  ✓ $file"
  else
    echo "  ✗ $file MISSING"
  fi
done
```

### Step 5: Show Summary

Display the final status:

```
═══════════════════════════════════════
✅ CCPM Plugin Installation Verified
═══════════════════════════════════════

Symlink: ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm/1.2.1
Target:  /Users/duongdev/personal/ccpm
Status:  [OK/FIXED/ERROR]

Local changes are now immediately available.
No need to reinstall the plugin.

To test: Start a new Claude Code session or run /compact
```

## Quick One-Liner

For quick fixes, run this single command:

```bash
mkdir -p ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm && rm -rf ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm/1.2.1 && ln -s /Users/duongdev/personal/ccpm ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm/1.2.1 && echo "✅ CCPM plugin symlink updated"
```

## When to Use

- After `git pull` with changes to hooks or commands
- When getting "No such file or directory" errors for hook scripts
- After plugin cache gets cleared or corrupted
- When testing local changes to the plugin

## Troubleshooting

If files are still not found after running this command:

1. Check the dev directory exists: `ls /Users/duongdev/personal/ccpm`
2. Check installed_plugins.json: `grep ccpm ~/.claude/plugins/installed_plugins.json`
3. Restart Claude Code to reload hooks
