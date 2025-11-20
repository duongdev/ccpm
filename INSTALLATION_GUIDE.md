# CCPM Installation & Activation Guide

This guide shows how to install the new command and activate the new skills.

## What's New

### New Command
- **`/ccpm:utils:organize-docs`** - Reorganize documentation following CCPM pattern

### New Skills (8 total)
1. `external-system-safety` - Prevents accidental external writes (existing)
2. `pm-workflow-guide` - Context-aware command suggestions (existing)
3. `sequential-thinking` - Structured problem-solving
4. `docs-seeker` - Documentation discovery
5. `ccpm-code-review` - Verification enforcement
6. `ccpm-debugging` - Systematic debugging
7. `ccpm-mcp-management` - MCP server troubleshooting
8. `ccpm-skill-creator` - Custom skill creation

## Installation Methods

### Method 1: Git-Based Installation (Recommended)

Since CCPM is a Claude Code plugin in a git repository, Claude Code will automatically pick up changes when you commit and push.

#### Step 1: Commit New Files

```bash
# Add all new files
git add commands/utils:organize-docs.md
git add scripts/organize-docs.sh
git add DOCUMENTATION_STRUCTURE_PROPOSAL.md
git add GLOBAL_DOCS_PATTERN.md
git add DOCS_BEFORE_AFTER.md
git add CLAUDE_MD_DOCUMENTATION_SECTION.md

# Commit
git commit -m "feat: add documentation organization command and global pattern

- Add /ccpm:utils:organize-docs command
- Add automated documentation reorganization script
- Add CCPM documentation pattern for global reuse
- Update CLAUDE.md with documentation guidelines
- Include before/after comparison and proposal docs"

# Push to GitHub
git push origin main
```

#### Step 2: Reload Plugin in Claude Code

After pushing, Claude Code will automatically detect the changes. To force reload:

```bash
# Option A: Restart Claude Code session
# Exit and restart your conversation

# Option B: Use plugin reload (if available)
/plugin reload ccpm

# Option C: Reinstall plugin
/plugin uninstall ccpm
/plugin install ccpm
```

#### Step 3: Verify Installation

```bash
# Test the new command
/ccpm:utils:organize-docs --dry-run

# Should show documentation analysis
```

### Method 2: Local Development (For Testing)

If you're developing locally and want to test without committing:

#### Step 1: Ensure Files are in Correct Locations

```bash
# Commands should be in commands/
ls -l commands/utils:organize-docs.md

# Scripts should be executable
chmod +x scripts/organize-docs.sh
ls -l scripts/organize-docs.sh

# Skills should be in skills/
ls -l skills/*/SKILL.md
```

#### Step 2: Verify Plugin Configuration

```bash
# Check plugin.json includes skills component
cat .claude-plugin/plugin.json | grep -A 5 '"components"'

# Should show:
# "components": {
#   "commands": "./commands",
#   "agents": "./agents",
#   "hooks": "./hooks",
#   "scripts": "./scripts",
#   "skills": "./skills"
# }
```

#### Step 3: Reload Claude Code

```bash
# Restart your Claude Code session
# Claude will discover new files automatically
```

## Skill Activation

Skills are **automatically discovered** by Claude Code when the plugin is loaded.

### How Skills Activate

Skills activate based on:

1. **Trigger phrases** in user messages
2. **Command execution** (some skills auto-activate with specific commands)
3. **Context detection** (workflow phase, errors, etc.)

### Verifying Skills are Active

#### Method 1: Check with verbose mode

```bash
# Run Claude Code with verbose logging
claude --verbose

# In conversation, trigger a skill
"I need to debug this failing test"

# Should see in logs:
# [DEBUG] Activating skill: ccpm-debugging
```

#### Method 2: Test skill activation

Test each skill with its trigger phrases:

```bash
# Test sequential-thinking
"Break down this complex authentication system"
# Should activate sequential-thinking skill

# Test docs-seeker
"Find documentation for Next.js App Router"
# Should activate docs-seeker skill

# Test ccpm-code-review
"I'm done with this task"
# Should activate ccpm-code-review skill

# Test ccpm-debugging
"Tests are failing"
# Should activate ccpm-debugging skill

# Test ccpm-mcp-management
"Linear tools not working"
# Should activate ccpm-mcp-management skill

# Test ccpm-skill-creator
"Create a custom skill for our deployment workflow"
# Should activate ccpm-skill-creator skill
```

#### Method 3: Check skills directory

```bash
# List all skills
ls -l skills/*/SKILL.md

# Should show:
# skills/ccpm-code-review/SKILL.md
# skills/ccpm-debugging/SKILL.md
# skills/ccpm-mcp-management/SKILL.md
# skills/ccpm-skill-creator/SKILL.md
# skills/docs-seeker/SKILL.md
# skills/external-system-safety/SKILL.md
# skills/pm-workflow-guide/SKILL.md
# skills/sequential-thinking/SKILL.md
```

## Testing the Installation

### Test 1: New Command Works

```bash
# Test dry-run
/ccpm:utils:organize-docs --dry-run

# Expected output:
# 📊 Documentation Analysis
# Repository: ccpm
# Found 22 markdown files in root
# ⚠️  Too many files in root (>5)
# [shows categorization]
```

### Test 2: Skills Activate

```bash
# Test each skill
"I need help debugging" # → ccpm-debugging
"I'm done" # → ccpm-code-review
"Find docs for React" # → docs-seeker
"Plan this feature" # → sequential-thinking
"MCP not working" # → ccpm-mcp-management
"Create skill" # → ccpm-skill-creator
```

### Test 3: Skills Reference in Plugin

```bash
# Check plugin features list
cat .claude-plugin/plugin.json | grep -A 20 '"features"'

# Should include skills
```

## Applying the Documentation Pattern

Once installed, apply the documentation pattern:

### Step 1: Review Current Structure

```bash
/ccpm:utils:organize-docs --dry-run
```

Review the proposed changes.

### Step 2: Apply Reorganization

```bash
/ccpm:utils:organize-docs
```

This will:
- Create docs/ structure
- Move 16 files from root
- Create index files
- Update CLAUDE.md
- Update internal links

### Step 3: Verify Results

```bash
# Check root directory (should have ≤5 files)
ls -l *.md | wc -l

# Check docs/ structure
tree docs/

# Review CLAUDE.md
tail -100 CLAUDE.md
```

### Step 4: Commit Changes

```bash
git status
git add .
git commit -m "docs: reorganize documentation structure

- Move documentation to docs/ directory
- Create index files for navigation
- Update CLAUDE.md with documentation pattern
- Update internal links"
git push origin main
```

## Global Installation

To use the documentation pattern in other repositories:

### Step 1: Install Globally

```bash
/ccpm:utils:organize-docs . --global
```

This installs:
- Pattern to `~/.claude/templates/ccpm-docs-pattern/`
- Global command to `~/.claude/scripts/organize-docs`

### Step 2: Add to PATH

```bash
# Add to ~/.zshrc or ~/.bashrc
echo 'export PATH="$HOME/.claude/scripts:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Step 3: Use in Any Repository

```bash
cd ~/projects/any-other-repo
organize-docs --dry-run
organize-docs
```

## Troubleshooting

### Command Not Found

**Problem**: `/ccpm:utils:organize-docs` not recognized

**Solutions**:
1. Check file exists: `ls -l commands/utils:organize-docs.md`
2. Verify plugin loaded: `/plugin list` (should show ccpm)
3. Reload plugin: `/plugin reload ccpm`
4. Restart Claude Code session

### Skills Not Activating

**Problem**: Skills don't trigger when using trigger phrases

**Solutions**:
1. Check skills exist: `ls -l skills/*/SKILL.md`
2. Verify plugin.json includes skills component
3. Check SKILL.md frontmatter has correct format:
   ```yaml
   ---
   name: skill-name
   description: Clear description with trigger phrases
   ---
   ```
4. Use verbose mode: `claude --verbose`
5. Restart Claude Code session

### Files in Wrong Location

**Problem**: Command or skill files not being discovered

**Solutions**:
1. Check directory structure:
   ```
   ccpm/
   ├── commands/
   │   └── utils:organize-docs.md  ← Must be here
   ├── skills/
   │   ├── ccpm-code-review/
   │   │   └── SKILL.md            ← Must be here
   │   └── [other skills]/
   ```
2. Verify plugin.json components paths
3. Check file permissions: `chmod 644 commands/utils:organize-docs.md`

### Git Not Tracking Changes

**Problem**: Changes not appearing in git

**Solutions**:
```bash
# Check git status
git status

# Add untracked files
git add commands/utils:organize-docs.md
git add scripts/organize-docs.sh
git add skills/

# Commit
git commit -m "feat: add new command and skills"
```

## Verification Checklist

After installation, verify:

- [ ] Command file exists: `commands/utils:organize-docs.md`
- [ ] Script is executable: `scripts/organize-docs.sh`
- [ ] All 8 skills have SKILL.md files
- [ ] Plugin.json includes skills component
- [ ] Can run: `/ccpm:utils:organize-docs --dry-run`
- [ ] Skills activate with trigger phrases
- [ ] Documentation proposal files created
- [ ] Files committed to git
- [ ] Plugin reloaded in Claude Code

## What Happens Next

After installation:

1. **New command available**: Use `/ccpm:utils:organize-docs` anytime
2. **Skills auto-activate**: Trigger on context (no manual invocation)
3. **Documentation organized**: Run command to reorganize
4. **CLAUDE.md updated**: AI assistants follow pattern
5. **Global pattern ready**: Install globally for other repos

## Quick Start

```bash
# 1. Commit new files
git add commands/utils:organize-docs.md scripts/organize-docs.sh skills/ *.md
git commit -m "feat: add documentation organization and skills"
git push origin main

# 2. Reload plugin (restart Claude Code)
# Exit and start new session

# 3. Test new command
/ccpm:utils:organize-docs --dry-run

# 4. Apply if looks good
/ccpm:utils:organize-docs

# 5. Install globally (optional)
/ccpm:utils:organize-docs . --global

# Done! ✅
```

## Summary

**Installation**: Commit files → Push to git → Reload plugin
**Skill Activation**: Automatic based on trigger phrases
**Documentation Pattern**: Run `/ccpm:utils:organize-docs`
**Global Use**: Add `--global` flag, then use anywhere

The new command and skills are now ready to use! 🚀
