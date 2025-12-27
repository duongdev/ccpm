# Version Bump Checklist

This checklist documents all files that need updating when bumping the CCPM version.

## Files to Update

### Required Updates

- [ ] `.claude-plugin/plugin.json`
  - Line 3: `"version": "X.Y.Z"`

- [ ] `.claude-plugin/marketplace.json`
  - Line 10: `"version": "X.Y.Z"` (in `latestVersion` field)
  - Line 17: `"version": "X.Y.Z"` (in `releases` array - add new release entry)

- [ ] `CHANGELOG.md`
  - Add new version section at the top following the format:
    ```markdown
    ## [X.Y.Z] - YYYY-MM-DD

    ### Added
    - New features...

    ### Changed
    - Changes to existing functionality...

    ### Fixed
    - Bug fixes...
    ```

### Optional Updates (if relevant)

- [ ] `CLAUDE.md`
  - Update version references in documentation sections
  - Update command/agent/helper counts if changed

- [ ] `README.md`
  - Update any version-specific documentation
  - Update feature descriptions if changed

- [ ] `commands/README.md`
  - Update command list if commands added/removed

- [ ] `agents/README.md`
  - Update agent list if agents added/removed

## Version Bump Steps

### 1. Pre-Bump Preparation

```bash
# Ensure you're on the main branch with latest changes
git checkout main
git pull origin main

# Check current version
grep -r '"version"' .claude-plugin/
```

### 2. Determine Version Number

Follow [Semantic Versioning](https://semver.org/):

| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| Bug fixes, minor improvements | Patch | 1.2.0 -> 1.2.1 |
| New features, backward compatible | Minor | 1.2.0 -> 1.3.0 |
| Breaking changes | Major | 1.2.0 -> 2.0.0 |

### 3. Update Files

```bash
# Set the new version
NEW_VERSION="X.Y.Z"
DATE=$(date +%Y-%m-%d)

# Update plugin.json
# Update marketplace.json
# Update CHANGELOG.md with new section
```

### 4. Verification

Run these checks before committing:

```bash
# Verify all version references match
grep -r '"version"' .claude-plugin/

# Verify CHANGELOG has the new version
head -20 CHANGELOG.md

# Verify plugin loads correctly
/ccpm:status
```

### 5. Commit and Tag

```bash
# Stage changes
git add .

# Commit with conventional format
git commit -m "chore(release): bump version to X.Y.Z"

# Create git tag
git tag -a vX.Y.Z -m "Release vX.Y.Z"

# Push changes and tag
git push origin main
git push origin vX.Y.Z
```

## Verification Checklist

After bumping the version:

- [ ] All version numbers are consistent across files
- [ ] CHANGELOG entry includes date in YYYY-MM-DD format
- [ ] CHANGELOG entry lists all notable changes
- [ ] Plugin loads without errors (`/ccpm:status`)
- [ ] Git tag matches version in plugin.json
- [ ] README reflects any new features/changes

## Files That Should NOT Be Updated

These files contain version references for other purposes:

- `tests/mocks/mcp-servers/package.json` - Mock package version
- `commands/init.md` - Example config version schema
- `scripts/test-figma-phase2.sh` - Test fixture version
- `.claude-plugin/SCHEMA.md` - Example schema documentation
- `helpers/image-analysis.md` - Internal changelog (separate versioning)

## Quick Reference

Current version locations:

| File | Line | Purpose |
|------|------|---------|
| `.claude-plugin/plugin.json` | 3 | Primary version source |
| `.claude-plugin/marketplace.json` | 10 | Marketplace latest version |
| `.claude-plugin/marketplace.json` | 17 | Release history entry |
| `CHANGELOG.md` | 8+ | Version changelog header |
