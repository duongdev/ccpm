# CCPM Plugin Installation Test

**Test the CCPM plugin installation and functionality.**

---

## ✅ Pre-Installation Checklist

- [x] Backup created: `~/.claude/backup-2025-01-10/`
- [x] Local PM commands removed: `~/.claude/commands/pm/`
- [x] Local hooks removed: PM-related hook files from `~/.claude/hooks/`
- [x] Plugin ready: `~/personal/ccpm/`

---

## 📋 Installation Steps

### Step 1: Add Local Marketplace

Run in Claude Code CLI:

```bash
/plugin marketplace add ~/personal/ccpm
```

**Expected output:**
```
✅ Marketplace added: ~/personal/ccpm
```

### Step 2: Install CCPM Plugin

```bash
/plugin install ccpm@~/personal/ccpm
```

**Expected output:**
```
✅ Installing plugin: ccpm@~/personal/ccpm
✅ Plugin installed successfully
```

### Step 3: Verify Plugin Installed

```bash
/plugin
```

**Expected output:**
```
Installed Plugins:
- ccpm@~/personal/ccpm (v2.0.0)
```

---

## 🧪 Functionality Tests

### Test 1: Help Command

```bash
/pm:utils:help
```

**Expected:**
- Shows list of all 16+ PM commands
- Organized by category
- Includes descriptions

**Pass criteria:** Command executes without errors and shows comprehensive help.

---

### Test 2: List Agents

```bash
/pm:utils:agents
```

**Expected:**
- Lists all available agents
- Shows agent types (global, plugin, project)
- Includes descriptions

**Pass criteria:** Command executes and shows agent list.

---

### Test 3: Create Test Task (Quick Plan)

```bash
/pm:planning:quick-plan "Test CCPM plugin installation" nv-internal
```

**Expected:**
- Creates Linear issue
- Shows issue ID (e.g., WORK-XXX)
- Displays planning checklist
- Suggests next actions

**Pass criteria:**
- Issue created successfully
- Interactive prompts appear
- No errors

---

### Test 4: Check Status

```bash
/pm:utils:status WORK-XXX
```

(Replace WORK-XXX with the issue ID from Test 3)

**Expected:**
- Shows detailed task status
- Displays progress
- Lists subtasks
- Shows next actions

**Pass criteria:** Status displayed correctly.

---

### Test 5: Smart Agent Selection Hook

**Test:** Type a request that should trigger agent selection

```
Add user authentication to the API
```

**Expected:**
- Hook runs automatically (check verbose logs)
- Discovers available agents
- Scores agents by relevance
- Injects agent invocation instructions
- Claude mentions invoking specific agents

**Pass criteria:**
- Hook executes (visible in `claude --verbose`)
- Agents are mentioned in response

---

### Test 6: TDD Enforcement Hook

**Test:** Try to create a production file without tests

```
Can you create a new API endpoint file src/api/auth.ts?
```

**Expected:**
- PreToolUse hook triggers
- Checks for test file
- If no test exists, blocks and suggests TDD workflow
- May invoke tdd-orchestrator

**Pass criteria:**
- Hook blocks write operation (if no tests)
- Suggests test-first approach

---

### Test 7: Quality Gate Hook

**Test:** Complete a small code change and finish the response

**Expected:**
- Stop hook triggers after implementation
- Invokes code-reviewer automatically
- May invoke security-auditor for security changes
- Shows quality check results

**Pass criteria:**
- Hook executes after response ends
- Quality checks run automatically

---

## 🐛 Troubleshooting

### Issue: Commands Not Found

**Symptom:** `/pm:utils:help` returns "command not found"

**Fix:**
```bash
# Verify plugin installed
/plugin

# If not listed, reinstall
/plugin install ccpm@~/personal/ccpm

# Check plugin files exist
ls -la ~/personal/ccpm/.claude-plugin/plugin.json
```

---

### Issue: Hooks Not Running

**Symptom:** Smart agent selection doesn't trigger

**Fix:**
```bash
# Check hook files
ls -la ~/personal/ccpm/hooks/

# Check script executable
ls -la ~/personal/ccpm/scripts/discover-agents.sh

# Make executable if needed
chmod +x ~/personal/ccpm/scripts/discover-agents.sh

# Test discovery script
~/personal/ccpm/scripts/discover-agents.sh

# Run Claude with verbose logs
claude --verbose
```

---

### Issue: Discovery Script Fails

**Symptom:** Error when running discover-agents.sh

**Fix:**
```bash
# Install jq if missing
brew install jq

# Test script directly
~/personal/ccpm/scripts/discover-agents.sh | jq .

# Check for syntax errors
bash -n ~/personal/ccpm/scripts/discover-agents.sh
```

---

## ✅ Test Results

Record your test results:

| Test | Status | Notes |
|------|--------|-------|
| 1. Help Command | ⬜ Pass / ⬜ Fail | |
| 2. List Agents | ⬜ Pass / ⬜ Fail | |
| 3. Create Task | ⬜ Pass / ⬜ Fail | Issue ID: _______ |
| 4. Check Status | ⬜ Pass / ⬜ Fail | |
| 5. Smart Agent Selection | ⬜ Pass / ⬜ Fail | |
| 6. TDD Enforcement | ⬜ Pass / ⬜ Fail | |
| 7. Quality Gate | ⬜ Pass / ⬜ Fail | |

---

## 📊 Overall Assessment

**Installation:** ⬜ Success / ⬜ Failure

**Commands:** ⬜ All working / ⬜ Some issues / ⬜ Not working

**Hooks:** ⬜ All working / ⬜ Some issues / ⬜ Not working

**Ready for Production:** ⬜ Yes / ⬜ No (issues to fix)

---

## 🔄 Rollback (If Needed)

If testing fails and you need to restore original setup:

```bash
# Restore PM commands
cp -r ~/.claude/backup-2025-01-10/pm ~/.claude/commands/

# Restore hooks
cp -r ~/.claude/backup-2025-01-10/hooks/* ~/.claude/hooks/

# Uninstall plugin
/plugin uninstall ccpm@~/personal/ccpm

# Verify restoration
ls -la ~/.claude/commands/pm
ls -la ~/.claude/hooks
```

---

## 📝 Notes

Record any issues, observations, or improvements:

```
[Your notes here]
```

---

**Next Steps After Successful Test:**

1. ✅ All tests pass → Ready to publish to GitHub
2. ⚠️ Some issues → Fix and retest
3. ❌ Major issues → Review plugin structure and fix

---

**Start testing:** Run Step 1 above in your Claude Code CLI session.
