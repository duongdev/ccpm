# CCPM Hooks Installation Guide

This guide explains how to install and configure CCPM's smart agent auto-invocation, TDD enforcement, and quality gate hooks.

---

## 🎯 What Are CCPM Hooks?

CCPM provides three powerful hooks that automate your development workflow:

### 1. **Smart Agent Selector** (UserPromptSubmit)
- **Triggers**: When you submit a prompt
- **Does**: Analyzes your request, discovers all available agents, scores them by relevance (0-100+), and auto-invokes the best matches
- **Latency**: ~2-5 seconds
- **File**: `hooks/smart-agent-selector.prompt`

### 2. **TDD Enforcer** (PreToolUse)
- **Triggers**: Before Write/Edit/NotebookEdit operations
- **Does**: Checks for test files, blocks production code if tests don't exist, enforces Red-Green-Refactor workflow
- **Latency**: ~1-2 seconds
- **File**: `hooks/tdd-enforcer.prompt`

### 3. **Quality Gate** (Stop)
- **Triggers**: After Claude finishes responding
- **Does**: Automatically invokes code-reviewer for all changes, security-auditor for sensitive code, architecture review for significant changes
- **Latency**: ~2-3 seconds
- **File**: `hooks/quality-gate.prompt`

---

## 📋 Prerequisites

### Required Dependencies

1. **jq** - JSON processor for shell scripts
   ```bash
   # macOS
   brew install jq

   # Ubuntu/Debian
   sudo apt-get install jq

   # Linux (RHEL/CentOS)
   sudo yum install jq
   ```

2. **Claude Code** - Latest version
   ```bash
   claude --version
   # Should be 2.0.0 or higher
   ```

3. **CCPM Plugin** - Already installed
   ```bash
   /plugin list
   # Should show: ccpm@duongdev-ccpm-marketplace
   ```

---

## 🚀 Quick Installation

### Automated Installation (Recommended)

Run the installation script:

```bash
/Users/duongdev/personal/ccpm/scripts/install-hooks.sh
```

This will:
1. ✅ Backup your existing `~/.claude/settings.json`
2. ✅ Verify all hook files exist
3. ✅ Merge CCPM hooks into your settings
4. ✅ Preserve your existing hooks (notifications, etc.)
5. ✅ Validate the resulting JSON

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CCPM Hooks Installation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Backup created: ~/.claude/backups/settings-20250111-143000.json
✓ All hook files verified

Installing the following hooks:

1. UserPromptSubmit - Smart agent discovery & selection
2. PreToolUse - TDD enforcement
3. Stop - Quality gate

Do you want to proceed with installation? (y/n)
```

---

## 🔧 Manual Installation

If you prefer to install manually:

### Step 1: Backup Settings

```bash
cp ~/.claude/settings.json ~/.claude/settings.json.backup
```

### Step 2: Edit Settings

Open `~/.claude/settings.json` and add the following to the `"hooks"` section:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "prompt",
            "promptFile": "/Users/duongdev/personal/ccpm/hooks/smart-agent-selector.prompt",
            "timeout": 20000,
            "description": "CCPM: Smart agent discovery and selection with context-aware scoring"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit|NotebookEdit",
        "hooks": [
          {
            "type": "prompt",
            "promptFile": "/Users/duongdev/personal/ccpm/hooks/tdd-enforcer.prompt",
            "timeout": 10000,
            "description": "CCPM: TDD enforcement - blocks code without tests"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "promptFile": "/Users/duongdev/personal/ccpm/hooks/quality-gate.prompt",
            "timeout": 15000,
            "description": "CCPM: Quality gate - auto code review and security audit"
          }
        ]
      }
    ]
  }
}
```

**Important Notes:**
- Use **absolute paths** (not relative paths like `./hooks/...`)
- Update the path if your CCPM installation is in a different location
- If you already have hooks in these categories, add CCPM hooks to the existing arrays

### Step 3: Validate JSON

```bash
jq empty ~/.claude/settings.json
```

If no errors, the JSON is valid.

---

## ✅ Verification

After installation, verify everything is working:

### Run Verification Script

```bash
/Users/duongdev/personal/ccpm/scripts/verify-hooks.sh
```

**Expected Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CCPM Hooks Verification
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/8] Checking jq installation...
✓ jq is installed: jq-1.7

[2/8] Checking settings.json...
✓ Settings file exists: /Users/duongdev/.claude/settings.json
✓ Settings file is valid JSON

[3/8] Checking plugin installation...
✓ Plugin directory exists: /Users/duongdev/personal/ccpm

[4/8] Checking hook files...
✓ smart-agent-selector.prompt (12807 bytes)
✓ tdd-enforcer.prompt (4853 bytes)
✓ quality-gate.prompt (4482 bytes)
✓ All hook files present

[5/8] Checking script permissions...
✓ discover-agents.sh is executable
✓ install-hooks.sh is executable
✓ uninstall-hooks.sh is executable
✓ verify-hooks.sh is executable
✓ All scripts are executable

[6/8] Checking hooks registration...
✓ UserPromptSubmit hook registered
✓ PreToolUse hook registered
✓ Stop hook registered
✓ All 3 CCPM hooks are registered

[7/8] Testing agent discovery...
✓ Agent discovery works: Found 24 agents
  • Plugin agents: 21
  • Global agents: 3
  • Project agents: 0

[8/8] Verifying hook file paths...
✓ Path exists: /Users/duongdev/personal/ccpm/hooks/smart-agent-selector.prompt
✓ Path exists: /Users/duongdev/personal/ccpm/hooks/tdd-enforcer.prompt
✓ Path exists: /Users/duongdev/personal/ccpm/hooks/quality-gate.prompt
✓ All hook paths are valid

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Verification Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ All checks passed!
```

### Manual Tests

#### 1. Test Agent Discovery

```bash
/Users/duongdev/personal/ccpm/scripts/discover-agents.sh | jq 'length'
```

**Expected**: `24` (or more)

#### 2. Test Claude Code with Verbose Mode

```bash
claude --verbose
```

Then type:
```
"Add user authentication"
```

**Expected Output** (in verbose logs):
```
Hook: UserPromptSubmit
Executing: /Users/duongdev/personal/ccpm/hooks/smart-agent-selector.prompt
Discovering agents...
Found 24 agents
Scoring agents:
  - backend-architect: 95
  - security-auditor: 90
  - tdd-orchestrator: 85
Injecting agent invocation instructions...
```

#### 3. Test TDD Enforcement

Try to create a file without tests:
```
"Create a new function calculateTotal in src/utils.ts"
```

**Expected**: Hook should detect missing tests and block or invoke `tdd-orchestrator`

---

## 🎛️ Configuration Options

### Adjusting Timeouts

If hooks are timing out, increase the timeout values in `~/.claude/settings.json`:

```json
{
  "type": "prompt",
  "promptFile": "/path/to/hook.prompt",
  "timeout": 30000  // 30 seconds (default: 20s)
}
```

**Recommendations:**
- `UserPromptSubmit`: 15-30 seconds (runs agent discovery)
- `PreToolUse`: 5-10 seconds (fast validation)
- `Stop`: 10-20 seconds (quality gates)

### Disabling Specific Hooks

To temporarily disable a hook without uninstalling, remove it from `~/.claude/settings.json` or set a condition:

```json
{
  "hooks": {
    "UserPromptSubmit": []  // Disabled
  }
}
```

### Project-Specific Hooks

To enable hooks only for specific projects, use `.claude/settings.json` in the project root instead of `~/.claude/settings.json`.

---

## 🗑️ Uninstallation

### Automated Uninstallation (Recommended)

```bash
/Users/duongdev/personal/ccpm/scripts/uninstall-hooks.sh
```

This will:
1. ✅ Backup your current settings
2. ✅ Remove only CCPM hooks
3. ✅ Preserve your other hooks
4. ✅ Validate the resulting JSON

### Manual Uninstallation

1. Open `~/.claude/settings.json`
2. Remove CCPM hook entries (look for `"description"` containing `"CCPM:"`)
3. Save and validate JSON: `jq empty ~/.claude/settings.json`

---

## 🐛 Troubleshooting

### Problem: Hooks Not Executing

**Symptoms**: No hook activity in verbose mode

**Solutions**:
1. Verify hooks are registered:
   ```bash
   cat ~/.claude/settings.json | jq '.hooks'
   ```

2. Check file paths are absolute:
   ```bash
   cat ~/.claude/settings.json | jq '.hooks.UserPromptSubmit[].hooks[].promptFile'
   ```

3. Re-run installation:
   ```bash
   /Users/duongdev/personal/ccpm/scripts/install-hooks.sh
   ```

### Problem: "jq: command not found"

**Solution**: Install jq
```bash
brew install jq
```

### Problem: "Permission denied" for scripts

**Solution**: Make scripts executable
```bash
chmod +x /Users/duongdev/personal/ccpm/scripts/*.sh
```

### Problem: Agent Discovery Returns 0 Agents

**Symptoms**: `discover-agents.sh | jq 'length'` returns `0`

**Solutions**:
1. Check if plugins are installed:
   ```bash
   cat ~/.claude/plugins/installed_plugins.json | jq '.plugins | keys'
   ```

2. Test script manually:
   ```bash
   /Users/duongdev/personal/ccpm/scripts/discover-agents.sh
   ```

3. Check for error messages in the output

### Problem: Hooks Timeout

**Symptoms**: Hooks take too long and get cancelled

**Solutions**:
1. Increase timeout in settings.json (see Configuration Options)
2. Check if `discover-agents.sh` is slow
3. Reduce number of installed plugins (if discovery is slow)

### Problem: Invalid JSON After Installation

**Symptoms**: `jq empty ~/.claude/settings.json` shows errors

**Solutions**:
1. Restore from backup:
   ```bash
   cp ~/.claude/backups/settings-*.json ~/.claude/settings.json
   ```

2. Use verification script to identify issues:
   ```bash
   /Users/duongdev/personal/ccpm/scripts/verify-hooks.sh
   ```

---

## 📚 Additional Resources

- [Hooks Reference](./hooks/README.md) - Detailed hook documentation
- [Smart Agent Selection](./hooks/SMART_AGENT_SELECTION.md) - How agent selection works
- [Official Claude Code Hooks Docs](https://code.claude.com/docs/en/hooks)
- [CCPM Commands](./commands/README.md) - All available PM commands

---

## 💡 Tips & Best Practices

1. **Start with Verbose Mode**: Always use `claude --verbose` when testing hooks to see what's happening

2. **Test Incrementally**: Install one hook at a time if you're troubleshooting issues

3. **Monitor Performance**: Hooks add latency. If it's too much, adjust timeouts or disable hooks temporarily

4. **Use Project Hooks**: For project-specific agent configurations, use `.claude/settings.json` in the project root

5. **Keep Backups**: The install script automatically creates backups in `~/.claude/backups/`

6. **Check Logs**: Hook execution logs are in `~/.claude/logs/`

7. **Update Plugin**: When updating CCPM, re-run verification to ensure hooks still work:
   ```bash
   /Users/duongdev/personal/ccpm/scripts/verify-hooks.sh
   ```

---

## ✅ Quick Command Reference

```bash
# Install hooks
/Users/duongdev/personal/ccpm/scripts/install-hooks.sh

# Verify installation
/Users/duongdev/personal/ccpm/scripts/verify-hooks.sh

# Test agent discovery
/Users/duongdev/personal/ccpm/scripts/discover-agents.sh | jq 'length'

# Uninstall hooks
/Users/duongdev/personal/ccpm/scripts/uninstall-hooks.sh

# View settings
cat ~/.claude/settings.json | jq '.hooks'

# Test with verbose mode
claude --verbose

# Make scripts executable (if needed)
chmod +x /Users/duongdev/personal/ccpm/scripts/*.sh
```

---

**Happy Coding with CCPM! 🚀**
