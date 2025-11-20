# CCPM Hooks Research Summary

## Problem Statement

When running `/hooks` in Claude Code, no hooks are shown despite having:
- ✅ `hooks/hooks.json` file exists
- ✅ `plugin.json` has `"hooks": "./hooks/hooks.json"` field
- ✅ All hook types are valid (`prompt`)
- ✅ JSON is well-formed

## Research Findings

### 1. Hook Discovery Mechanism

From official Claude Code documentation:
> "Plugin hooks are defined in the plugin's `hooks/hooks.json` file or in a file given by a custom path to the `hooks` field."

**Key insight**: Claude Code automatically discovers hooks from the default `hooks/` directory. The `hooks` field in `plugin.json` is only needed for custom paths.

### 2. Working Plugin Example (todo-ware)

Examined `lessuselesss/todo-ware` plugin:

**Their plugin.json**:
```json
{
  "name": "kiro-scaffold",
  "version": "1.2.0",
  "components": {
    "hooks": 4
  }
}
```

**Their hooks/hooks.json**:
```json
{
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate-scope-nickel.sh",
          "timeout": 5000
        }
      ]
    }
  ]
}
```

**Key differences**:
1. They use `type: "command"` with actual executable scripts
2. They use `${CLAUDE_PLUGIN_ROOT}` environment variable
3. Their hooks DO something (execute validation scripts)

### 3. Current CCPM Hooks Configuration

**What we have**:
```json
{
  "UserPromptSubmit": [
    {
      "hooks": [
        {
          "type": "prompt",
          "prompt": "CCPM Smart Agent Selector is temporarily disabled...",
          "timeout": 20
        }
      ]
    }
  ]
}
```

**Problem**: Our hooks are just notification messages, not actual functional hooks. This might explain why they don't appear in the `/hooks` UI.

## Hypothesis: Why Hooks Aren't Showing

Two possible reasons:

### Theory 1: Placeholder Hooks Aren't Real Hooks
Claude Code's `/hooks` UI might filter out hooks that:
- Don't execute commands
- Don't modify tool behavior
- Are just informational prompts

Our "disabled" placeholder hooks might not qualify as actual hooks from the UI's perspective.

### Theory 2: Plugin Not Fully Loaded
The plugin might not be properly installed/loaded, even though the structure is valid.

## Verification Steps

To test which theory is correct:

### Test 1: Check if Plugin is Loaded
```bash
# In Claude Code
/plugin list
```
Expected: Should show `ccpm` in the list

### Test 2: Create a Simple Functional Hook
Replace one placeholder with a real command hook:

```json
{
  "PreToolUse": [
    {
      "matcher": "Write",
      "hooks": [
        {
          "type": "command",
          "command": "echo 'CCPM: About to write file'",
          "timeout": 1000,
          "description": "CCPM write notification"
        }
      ]
    }
  ]
}
```

Then check `/hooks` again.

### Test 3: Check Hook Execution
Trigger a Write operation and see if the hook executes (check output/logs).

## Recommended Next Steps

### Option A: Keep Hooks Disabled (Current Approach)
**Pros**:
- Plugin loads without errors
- Hooks don't interfere
- Can focus on commands

**Cons**:
- Advanced automation features unavailable
- Manual agent invocation required

### Option B: Implement Simple Command Hooks
Create lightweight shell scripts that work around the size limitation:

**Example structure**:
```bash
hooks/
├── hooks.json
└── scripts/
    ├── agent-selector.sh      # Simplified version
    ├── tdd-reminder.sh         # Just a reminder, not enforcer
    └── quality-reminder.sh     # Reminder to run review
```

**hooks.json**:
```json
{
  "UserPromptSubmit": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/agent-selector.sh",
          "timeout": 5000,
          "description": "Suggest agents based on user request"
        }
      ]
    }
  ]
}
```

**Pros**:
- Hooks appear in `/hooks` UI
- Provides some automation
- Works within size constraints

**Cons**:
- Less sophisticated than original design
- Still requires simplified logic

### Option C: Remove Hooks Entirely
Delete `hooks/` directory and `"hooks"` field from `plugin.json`.

**Pros**:
- Clean, no confusion
- Focus on commands only
- No maintenance burden

**Cons**:
- Lose automation potential completely
- Users must do everything manually

## Documentation Insights

### From Official Docs

**Hook Loading**:
> "When a plugin is enabled, its hooks are merged with user and project hooks"

**Hook Execution**:
> "Multiple hooks from different sources can respond to the same event"

**Environment Variables**:
- `${CLAUDE_PLUGIN_ROOT}` - Plugin directory path
- `${CLAUDE_PROJECT_DIR}` - Project root path

**Hook Types**:
- `command`: Execute bash scripts (most common)
- `prompt`: LLM-based decisions (limited to Stop, SubagentStop)

### Key Takeaway

**Command hooks are the standard pattern** for plugins. Prompt hooks are typically used for sophisticated decision-making that requires LLM reasoning, not for simple notifications.

## Conclusion

**Most Likely Issue**: Our placeholder prompt hooks don't qualify as "real hooks" from Claude Code's perspective, so they don't show up in `/hooks` UI.

**Recommendation**: Implement **Option B** - Simple Command Hooks

Create lightweight shell scripts that:
1. Run quickly (<5s)
2. Provide useful feedback
3. Don't require 500-line prompts
4. Use command hooks (industry standard)

This approach:
- ✅ Appears in `/hooks` UI
- ✅ Provides some automation value
- ✅ Works within current limitations
- ✅ Follows Claude Code conventions
- ✅ Keeps plugin functional

Next step: Prototype a simple agent-selector script that runs quickly and provides suggestions without complex logic.
