# CCPM Hooks - Current Limitation & Workaround

## Issue

Claude Code's hook system has a limitation that prevents CCPM's advanced hooks from working:

### Hook Type Constraints

Claude Code hooks only support two types:
- `type: "command"` - Execute a shell command
- `type: "prompt"` - Inline prompt text only

**Problem**: Our hook prompts are 100-500 lines long and cannot be embedded inline in JSON.

### Path Resolution Issues

When using `type: "command"`, the hook system cannot reliably resolve paths to plugin files:
- `$CLAUDE_PROJECT_DIR` variable doesn't expand correctly
- Relative paths from plugin root don't work
- Absolute paths are user-specific and break portability

### Error Encountered

```
Plugin hook error: cat: /Users/duongdev/.claude/.claude/plugins/ccpm@duongdev-ccpm-marketplace/hooks/smart-agent-selector.prompt: No such file or directory
```

## Current Status: Hooks Temporarily Disabled

All CCPM hooks are currently disabled with placeholder prompts:

1. **Smart Agent Selector** (UserPromptSubmit) - Disabled
2. **TDD Enforcer** (PreToolUse) - Disabled
3. **Quality Gate** (Stop) - Disabled
4. **Agent Chaining** (SubagentStop) - Active (uses inline prompt)

## Workaround: Manual Agent Invocation

Until hook system is enhanced, users should manually invoke agents:

### Instead of Automatic Agent Selection:

**Before (with hooks):**
```
User: "Add user authentication"
→ Hook automatically invokes backend-architect + tdd-orchestrator + security-auditor
```

**Now (manual):**
```
User: "Add user authentication"
User manually invokes:
  - Task(backend-architect): "Design auth system"
  - Task(tdd-orchestrator): "Write auth tests"
  - Task(security-auditor): "Review auth security"
```

### Instead of Automatic TDD Enforcement:

**Before (with hooks):**
```
Write production code → Hook blocks → Auto-invokes tdd-orchestrator
```

**Now (manual):**
```
User: "Write tests first before implementing feature"
Or use: Task(tdd-orchestrator): "Write tests for [feature]"
```

### Instead of Automatic Quality Gate:

**Before (with hooks):**
```
Implementation done → Hook auto-invokes code-reviewer + security-auditor
```

**Now (manual):**
```
After implementation:
  - Task(code-reviewer): "Review changes"
  - Task(security-auditor): "Security audit" (if security-related)
```

## Future Solutions

### Option 1: Hook System Enhancement (Claude Code team)

Enhance Claude Code to support:
- `type: "file"` - Reference external prompt files
- Better path resolution for plugin resources
- Environment variables that expand correctly

### Option 2: Bundled Hooks (CCPM team)

Create a build step that:
1. Reads all `.prompt` files
2. Minifies and escapes them
3. Embeds inline in `hooks.json` as `type: "prompt"`
4. Auto-generates during plugin build

Example:
```json
{
  "type": "prompt",
  "prompt": "You are an intelligent agent selector...[full 500-line prompt here]"
}
```

**Pros**: Works with current hook system
**Cons**: Harder to maintain, hooks.json becomes very large

### Option 3: Runtime Hook Loader (CCPM team)

Create a lightweight shell script that:
1. Detects plugin installation directory
2. Reads prompt file from that directory
3. Outputs prompt to stdout

Example `hooks/load-prompt.sh`:
```bash
#!/bin/bash
PLUGIN_DIR="$HOME/.claude/plugins/ccpm@duongdev-ccpm-marketplace"
cat "$PLUGIN_DIR/hooks/$1.prompt"
```

Then in `hooks.json`:
```json
{
  "type": "command",
  "command": "bash hooks/load-prompt.sh smart-agent-selector"
}
```

**Pros**: Keeps prompts separate, maintainable
**Cons**: Requires shell script, path detection still fragile

### Option 4: Slash Commands Instead (CCPM team - RECOMMENDED)

Convert hooks into slash commands:

1. `/ccpm:utils:select-agents` - Manual agent selection helper
2. `/ccpm:utils:tdd-check` - Check if tests exist before coding
3. `/ccpm:utils:quality-review` - Run code review and quality checks

**Pros**:
- Works with current system
- User has full control
- No path resolution issues
- Easy to maintain

**Cons**:
- Not automatic (user must invoke)
- Loses the "magic" of automatic agent invocation

## Recommendation

**Short-term**: Use Option 4 (slash commands) - Most reliable with current Claude Code

**Long-term**: Advocate for Option 1 (hook system enhancement) - Best UX

## Implementation Plan for Slash Commands

Create these new utility commands:

### `/ccpm:utils:select-agents [request]`

Analyzes request and suggests which agents to invoke:
- Runs agent discovery script
- Applies scoring algorithm
- Outputs recommended agents with reasons
- User decides whether to proceed

### `/ccpm:utils:tdd-check [file-path]`

Checks if tests exist before modifying code:
- Detects test file location patterns
- Checks if test file exists
- If not, offers to invoke tdd-orchestrator
- Blocks or warns user

### `/ccpm:utils:quality-review`

Runs post-implementation quality checks:
- Detects what changed (git diff)
- Invokes appropriate agents (code-reviewer, security-auditor)
- Provides quality report
- Suggests improvements

## Status

- ✅ Hooks disabled with placeholder prompts (plugin loads successfully)
- ⏳ Slash command implementation (future work)
- ⏳ Documentation updated (in progress)
- ⏳ Advocate for hook system enhancement (Claude Code team)

## Files

Hook implementation files (currently unused):
- `hooks/smart-agent-selector.prompt` (469 lines)
- `hooks/tdd-enforcer.prompt` (173 lines)
- `hooks/quality-gate.prompt` (160 lines)
- `hooks/agent-selector.prompt` (129 lines - backup)

Current hooks config:
- `hooks/hooks.json` (placeholder prompts only)
