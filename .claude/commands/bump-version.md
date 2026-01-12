---
description: Bump CCPM plugin version (patch, minor, or major)
---

# /bump-version - Bump Plugin Version

Bumps the CCPM plugin version across all relevant files and optionally updates the local symlink.

## Usage

```bash
/bump-version patch   # 1.2.0 -> 1.2.1
/bump-version minor   # 1.2.0 -> 1.3.0
/bump-version major   # 1.2.0 -> 2.0.0
/bump-version 1.5.0   # Set specific version
```

## Implementation

### Step 1: Parse Arguments

```javascript
const args = process.argv.slice(2);
const bumpType = args[0] || 'patch';

// Validate bump type
const validTypes = ['patch', 'minor', 'major'];
const isSpecificVersion = /^\d+\.\d+\.\d+$/.test(bumpType);

if (!validTypes.includes(bumpType) && !isSpecificVersion) {
  console.log(`
❌ Invalid version type: ${bumpType}

Usage:
  /bump-version patch   # 1.2.0 -> 1.2.1
  /bump-version minor   # 1.2.0 -> 1.3.0
  /bump-version major   # 1.2.0 -> 2.0.0
  /bump-version 1.5.0   # Set specific version
  `);
  return;
}
```

### Step 2: Read Current Version

```bash
CURRENT_VERSION=$(jq -r '.version' .claude-plugin/plugin.json)
echo "Current version: $CURRENT_VERSION"
```

### Step 3: Calculate New Version

```javascript
function bumpVersion(current, type) {
  const [major, minor, patch] = current.split('.').map(Number);

  switch (type) {
    case 'major':
      return `${major + 1}.0.0`;
    case 'minor':
      return `${major}.${minor + 1}.0`;
    case 'patch':
      return `${major}.${minor}.${patch + 1}`;
    default:
      // Specific version provided
      return type;
  }
}

const newVersion = bumpVersion(currentVersion, bumpType);
console.log(`New version: ${newVersion}`);
```

### Step 4: Update Version in All Files

**Files to update:**
1. `.claude-plugin/plugin.json` - line 3: `"version": "X.Y.Z"`
2. `.claude-plugin/marketplace.json` - line 10 and 17: `"version": "X.Y.Z"`
3. `.claude/commands/update-local.md` - version directory references

```bash
# Get versions
CURRENT_VERSION=$(jq -r '.version' .claude-plugin/plugin.json)
NEW_VERSION="${NEW_VERSION}"  # From calculation above

echo "Updating: $CURRENT_VERSION -> $NEW_VERSION"

# Update plugin.json
jq ".version = \"$NEW_VERSION\"" .claude-plugin/plugin.json > .claude-plugin/plugin.json.tmp && mv .claude-plugin/plugin.json.tmp .claude-plugin/plugin.json

# Update marketplace.json (both metadata.version and plugins[0].version)
jq ".metadata.version = \"$NEW_VERSION\" | .plugins[0].version = \"$NEW_VERSION\"" .claude-plugin/marketplace.json > .claude-plugin/marketplace.json.tmp && mv .claude-plugin/marketplace.json.tmp .claude-plugin/marketplace.json

# Update update-local.md (replace version directory references)
sed -i '' "s|ccpm/${CURRENT_VERSION}|ccpm/${NEW_VERSION}|g" .claude/commands/update-local.md

echo "✓ Updated all version references"
```

### Step 5: Update Local Symlink

```bash
# Remove old symlink and create new one
PLUGIN_CACHE=~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm
DEV_DIR="/Users/duongdev/personal/ccpm"

# Check if old version symlink exists
if [ -L "$PLUGIN_CACHE/$CURRENT_VERSION" ]; then
  rm "$PLUGIN_CACHE/$CURRENT_VERSION"
  echo "✓ Removed old symlink: $CURRENT_VERSION"
fi

# Create new version symlink
mkdir -p "$PLUGIN_CACHE"
ln -sf "$DEV_DIR" "$PLUGIN_CACHE/$NEW_VERSION"
echo "✓ Created new symlink: $NEW_VERSION -> $DEV_DIR"
```

### Step 6: Update installed_plugins.json

```bash
# Update the version in installed_plugins.json
INSTALLED_PLUGINS=~/.claude/plugins/installed_plugins.json

if [ -f "$INSTALLED_PLUGINS" ]; then
  # Update the version for ccpm plugin
  jq --arg old "$CURRENT_VERSION" --arg new "$NEW_VERSION" '
    .[] |= if .name == "ccpm@duongdev-ccpm-marketplace" then
      .version = $new |
      .installPath = (.installPath | sub($old; $new))
    else . end
  ' "$INSTALLED_PLUGINS" > "${INSTALLED_PLUGINS}.tmp" && mv "${INSTALLED_PLUGINS}.tmp" "$INSTALLED_PLUGINS"

  echo "✓ Updated installed_plugins.json"
fi
```

### Step 7: Display Summary

```
═══════════════════════════════════════
✅ Version Bumped Successfully
═══════════════════════════════════════

Version: {old} -> {new}

Files Updated:
  ✓ .claude-plugin/plugin.json
  ✓ .claude-plugin/marketplace.json
  ✓ .claude/commands/update-local.md
  ✓ ~/.claude/plugins/installed_plugins.json

Symlink Updated:
  ✓ ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm/{new}

═══════════════════════════════════════
📝 Next Steps
═══════════════════════════════════════

1. Review changes: git diff
2. Commit: git add -A && git commit -m "chore: bump version to {new}"
3. Tag (optional): git tag v{new}
4. Push: git push origin main --tags

═══════════════════════════════════════
```

## Quick One-Liner (Patch Bump)

```bash
# Read current, calculate new, update all files
OLD=$(jq -r '.version' .claude-plugin/plugin.json) && \
NEW=$(echo $OLD | awk -F. '{print $1"."$2"."$3+1}') && \
jq ".version = \"$NEW\"" .claude-plugin/plugin.json > tmp && mv tmp .claude-plugin/plugin.json && \
jq ".metadata.version = \"$NEW\" | .plugins[0].version = \"$NEW\"" .claude-plugin/marketplace.json > tmp && mv tmp .claude-plugin/marketplace.json && \
sed -i '' "s|ccpm/${OLD}|ccpm/${NEW}|g" .claude/commands/update-local.md && \
rm -f ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm/$OLD && \
ln -sf /Users/duongdev/personal/ccpm ~/.claude/plugins/cache/duongdev-ccpm-marketplace/ccpm/$NEW && \
echo "✅ Bumped: $OLD -> $NEW"
```

## Notes

- Always commit version changes before releasing
- The symlink update ensures local development continues working
- Use semantic versioning: major.minor.patch
- Major: Breaking changes
- Minor: New features (backward compatible)
- Patch: Bug fixes (backward compatible)
