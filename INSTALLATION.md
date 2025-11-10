# CCPM Installation Guide

Complete guide for installing and testing the CCPM plugin.

---

## 📦 Installation Methods

### Method 1: Local Testing (Recommended for Development)

**For testing the plugin locally before publishing:**

```bash
# 1. Add local marketplace
/plugin marketplace add ~/personal/ccpm

# 2. Install plugin
/plugin install ccpm@~/personal/ccpm

# 3. Verify installation
/pm:utils:help
```

### Method 2: From GitHub (After Publishing)

**After pushing to GitHub:**

```bash
# 1. Add GitHub marketplace
/plugin marketplace add duongdev/ccpm

# 2. Install plugin
/plugin install ccpm@duongdev

# 3. Verify installation
/pm:utils:help
```

---

## 🔧 Prerequisites

### Required MCP Servers

CCPM requires these MCP servers to be configured:

#### 1. Linear MCP

```json
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "@linear/mcp-server"],
      "env": {
        "LINEAR_API_KEY": "your-linear-api-key"
      }
    }
  }
}
```

Get your Linear API key: https://linear.app/settings/api

#### 2. GitHub MCP

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-github-token"
      }
    }
  }
}
```

Get your GitHub token: https://github.com/settings/tokens

#### 3. Context7 MCP

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"]
    }
  }
}
```

### Optional MCP Servers

These enhance functionality but are not required:

- **Playwright MCP** - For `/pm:repeat:check-pr` browser automation
- **Vercel MCP** - For deployment integration
- **Shadcn MCP** - For UI component integration

---

## ✅ Post-Installation Verification

### Step 1: Test Commands Available

```bash
# Should list all PM commands
/pm:utils:help
```

Expected output: List of 16+ commands organized by category.

### Step 2: Test Smart Agent Selection

The smart agent selection hook should run automatically on every prompt. Test with:

```bash
# Type a simple request
"Add user authentication"
```

**Expected behavior:**
- Hook runs before Claude responds
- Discovers available agents
- Scores agents by relevance
- Injects agent invocation instructions

**Check verbose logs:**
```bash
claude --verbose
```

You should see hook execution details.

### Step 3: Test TDD Enforcement

Create a test file to verify TDD enforcement works:

```bash
# Try to create production code without tests
# The hook should block and suggest writing tests first
```

### Step 4: Test Quality Gates

After implementation, the quality gate hook should run automatically:

```bash
# Complete a simple change
# The Stop hook should invoke code-reviewer
```

### Step 5: Create First Task

```bash
# Create your first task
/pm:planning:create "Test CCPM installation" test-project

# Follow interactive prompts
```

---

## 🐛 Troubleshooting

### Issue: Commands Not Found

```bash
# Verify plugin is installed
/plugin

# Should show ccpm in installed list
```

**Fix:**
```bash
# Reinstall
/plugin uninstall ccpm@~/personal/ccpm
/plugin install ccpm@~/personal/ccpm
```

### Issue: Hooks Not Running

```bash
# Check hook files exist
ls -la ~/personal/ccpm/hooks/

# Verify script permissions
chmod +x ~/personal/ccpm/scripts/discover-agents.sh

# Test discovery script
~/personal/ccpm/scripts/discover-agents.sh
```

**Expected:** JSON array of discovered agents

### Issue: MCP Servers Not Working

```bash
# Check MCP server status in Claude Code
# Look for error messages about Linear, GitHub, or Context7

# Verify credentials in ~/.claude/settings.json
```

### Issue: Agent Discovery Fails

```bash
# Test discovery script directly
~/personal/ccpm/scripts/discover-agents.sh | jq .

# Should return JSON array with agents
```

**Common causes:**
- Script not executable: `chmod +x ~/personal/ccpm/scripts/discover-agents.sh`
- jq not installed: `brew install jq`
- Plugin agents directory not found

### Issue: Timeouts

If hooks are timing out, increase timeout values in `hooks/hooks.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{
        "timeout": 30000  // Increase from 20000
      }]
    }]
  }
}
```

---

## 🔄 Updating the Plugin

### For Local Testing

```bash
# After making changes to plugin files
cd ~/personal/ccpm

# Commit changes
git add .
git commit -m "your changes"

# Reinstall (required for changes to take effect)
/plugin uninstall ccpm@~/personal/ccpm
/plugin install ccpm@~/personal/ccpm
```

### For GitHub Distribution

```bash
# 1. Update version in .claude-plugin/plugin.json
# 2. Update CHANGELOG.md
# 3. Commit and push
git add .
git commit -m "chore: bump version to x.y.z"
git push origin main

# 4. Create release tag
git tag v2.0.1
git push origin v2.0.1

# 5. Users update with:
/plugin update ccpm@duongdev
```

---

## 📊 Verifying Features

### Smart Agent Selection

**Test:** Type "Add user authentication"

**Expected:**
- Hook discovers ~28 agents
- Scores: backend-architect (95), security-auditor (90), tdd-orchestrator (85)
- Claude automatically invokes agents in sequence

### TDD Enforcement

**Test:** Try to write production code without tests

**Expected:**
- PreToolUse hook blocks Write/Edit
- Prompts to write tests first
- Invokes tdd-orchestrator automatically

### Quality Gates

**Test:** Complete a code change

**Expected:**
- Stop hook triggers after implementation
- Invokes code-reviewer automatically
- Invokes security-auditor if security-sensitive

### Interactive Mode

**Test:** Run any PM command

**Expected:**
- Shows status after execution
- Displays progress percentage
- Suggests next actions
- Offers command chaining

---

## 🎯 Quick Start After Installation

### Day 1: Create First Task

```bash
# Create task with full planning
/pm:planning:create "Your first task" your-project

# Follow interactive prompts
# Let CCPM guide you through the workflow
```

### Day 2+: Daily Workflow

```bash
# Morning: Check project status
/pm:utils:report your-project

# Pick a task
/pm:utils:context WORK-123

# Work on it (agents auto-invoke)
# Quality gates auto-run
# Interactive mode guides you
```

---

## 📚 Next Steps

- Read [README.md](./README.md) for complete feature overview
- Check [CHANGELOG.md](./CHANGELOG.md) for version history
- Review [commands/README.md](./commands/README.md) for command reference
- Study [hooks/SMART_AGENT_SELECTION.md](./hooks/SMART_AGENT_SELECTION.md) for agent selection details

---

## 🆘 Getting Help

- Check `/pm:utils:help` for context-aware guidance
- Review troubleshooting section above
- Check GitHub Issues: https://github.com/duongdev/ccpm/issues
- Contact: me@dustin.tv

---

**Installation complete! 🎉**

Start with: `/pm:utils:help`
