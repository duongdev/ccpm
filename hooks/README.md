# Smart Agent Auto-Invocation System

**Automatically invoke specialized agents based on task context using Claude Code hooks.**

## 🎯 Overview (v1.1)

CCPM v1.1 uses an optimized two-phase hook system:
1. **SessionStart** - Injects full CCPM context once per session (~1.2K tokens)
2. **UserPromptSubmit** - Provides lightweight task-specific hints (~15 tokens max)

**Key Optimization in v1.1:**
- ✅ **94% token reduction** - Context injected once, not per-message
- ✅ **SessionStart** - Full agent discovery + rules injection (once)
- ✅ **UserPromptSubmit** - Minimal keyword-based hints only
- ❌ **Removed**: Per-message agent discovery (moved to SessionStart)

## 📊 Architecture (v1.1)

```
┌─────────────────────────────────────────────────────────────────┐
│                     Session Starts                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Hook: SessionStart (session-init.cjs) - RUNS ONCE             │
│  • Discovers all available agents (plugin + project)            │
│  • Injects agent invocation rules table                         │
│  • Injects CCPM slash command reference                         │
│  • Detects project/issue from git branch                        │
│  • ~1.2K tokens injected once per session                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     User Sends Message                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Hook: UserPromptSubmit (smart-agent-selector.sh) - MINIMAL    │
│  • Detects task-specific keywords                               │
│  • Outputs hint: "💡 Linear task → use ccpm:linear-operations" │
│  • ~15 tokens max (or nothing if no match)                      │
│  • 94% reduction vs per-message full injection                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Claude Starts Working                         │
│  • Has full context from SessionStart                           │
│  • Gets per-message hints for specific tasks                    │
│  • Invokes agents based on injected rules                       │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Files Structure

```
hooks/
├── hooks.json                               # Hook configuration
├── scripts/
│   ├── smart-agent-selector.sh             # Agent discovery script
│   └── discover-agents-cached.sh           # Cached discovery for performance
├── smart-agent-selector.prompt             # Full prompt (fallback)
├── smart-agent-selector-optimized.prompt   # Optimized prompt (81.7% reduction)
├── agent-selector.prompt                   # Static selector (backup)
├── SMART_AGENT_SELECTION.md                # Detailed documentation
└── README.md                               # This file
```

## 🔧 Two-Phase Hook System

### Phase 1: SessionStart (session-init.cjs)

**Purpose:** Inject full CCPM context once per session

**Triggers:** startup, resume, clear, compact

**What it does:**
1. Detects project from git remote
2. Extracts issue ID from branch name (e.g., `feature/WORK-26-...`)
3. Discovers all available agents (plugin + project)
4. Injects agent invocation rules table
5. Injects CCPM slash command reference
6. Persists session state to `/tmp/ccpm-session-*.json`

**Output (~1.2K tokens, once):**
```markdown
## CCPM Session Initialized

**Project:** my-app | **Issue:** WORK-26 | **Branch:** feature/WORK-26

### Available Agents (18)
ccpm:linear-operations, ccpm:frontend-developer, ccpm:backend-architect, ...

### 🔴 Agent Invocation Rules (MANDATORY)
| Task Type | Agent | Triggers |
|-----------|-------|----------|
| Linear ops | ccpm:linear-operations | issue, linear, status, sync |
| Frontend | ccpm:frontend-developer | component, UI, React, CSS |
...
```

### Phase 2: UserPromptSubmit (smart-agent-selector.sh)

**Purpose:** Provide lightweight task-specific hints

**Triggers:** Every user message

**What it does:**
1. Detects keywords in user message
2. Outputs minimal hint if match found
3. No agent discovery (already done in SessionStart)

**Output (~15 tokens max, or nothing):**
```
💡 Linear task detected → use `ccpm:linear-operations` agent
```

### Performance

| Metric | v1.0 | v1.1 |
|--------|------|------|
| Per-message injection | ~2.5K tokens | ~15 tokens |
| 10-message session | ~25K tokens | ~1.35K tokens |
| Token reduction | baseline | **94%** |
| Execution time | <1s | <100ms |

## ⚙️ Configuration

### Installation

The hook is automatically installed with the CCPM plugin. Configuration is in `hooks/hooks.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/smart-agent-selector.sh",
            "timeout": 5000,
            "description": "Smart agent selector"
          }
        ]
      }
    ]
  }
}
```

### Customization

Users can disable the hook in their project's `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": []
  }
}
```

Or adjust the timeout:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/smart-agent-selector.sh",
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
```

## 🚀 Optimization

### Caching Strategy

The smart agent selector uses aggressive caching:

1. **Agent Discovery Cache** (~5 minutes TTL)
   - Cached list of all available agents
   - Invalidated when plugin structure changes
   - Shared across all sessions

2. **Scoring Cache** (session-level)
   - Cached scoring results for similar requests
   - Invalidated on context changes

### Performance Tips

1. **Keep plugins organized** - Faster discovery
2. **Use project-specific agents** - Higher priority (+25 points)
3. **Clear descriptions** - Better keyword matching
4. **Avoid deep nesting** - Faster file system scans

## 📖 Documentation

For detailed information about the smart agent selection system:

- **Algorithm Details**: See `SMART_AGENT_SELECTION.md`
- **Agent Creation**: See `docs/guides/creating-agents.md`
- **Hook Development**: See `docs/development/hooks.md`

## 🔄 Migration from v2.x

### What Changed

**Removed Hooks:**

1. **TDD Enforcer** (`PreToolUse` hook)
   - **Reason**: Too opinionated, not all projects use TDD
   - **Alternative**: Developers manage their own testing workflow
   - **Benefit**: More flexibility, less overhead

2. **Quality Gates** (`Stop` hook)
   - **Reason**: Integrated into `/ccpm:verify` command
   - **Alternative**: Run `/ccpm:verify` explicitly when needed
   - **Benefit**: User controls when quality checks run

**Kept Hook:**

1. **Smart Agent Selector** (`UserPromptSubmit` hook)
   - **Reason**: Core value proposition of CCPM
   - **Improvement**: 81.7% token reduction in v1.0
   - **Benefit**: Automatic optimal agent selection

### Migration Steps

If you were using the removed hooks:

1. **For TDD Enforcement**:
   - Remove reliance on automatic test enforcement
   - Use `/ccpm:verify` to run tests before committing
   - Consider adding `npm run test` to your git pre-commit hook

2. **For Quality Gates**:
   - Replace automatic quality checks with `/ccpm:verify`
   - Run `/ccpm:verify` before `/ccpm:done` to ensure quality
   - Quality checks now happen when YOU decide, not automatically

### Benefits of v1.0 Hooks

- ✅ **Simpler**: 1 hook instead of 3
- ✅ **Faster**: 81.7% token reduction
- ✅ **More control**: Quality checks on demand
- ✅ **Still powerful**: Smart agent selection remains
- ✅ **Less intrusive**: No blocking hooks
- ✅ **Better UX**: Developers control their workflow

## 🎯 Best Practices

### When to Use Smart Agent Selection

**Automatically invoked** - The hook runs on every user request. Best for:
- Complex tasks requiring specialized knowledge
- Multi-disciplinary work (backend + frontend + security)
- Tasks where you're unsure which agent to use
- New team members learning the system

### When to Override

**Manual agent invocation** - Use the Task tool directly when:
- You know exactly which agent you need
- Debugging agent behavior
- Testing new agents
- Performance-critical scenarios

### Optimal Workflow

1. **Let the hook work** - Trust the smart selection
2. **Review suggestions** - Check which agents were selected
3. **Override if needed** - Manual invocation for edge cases
4. **Use `/ccpm:verify`** - Explicit quality checks before finalizing

## 🐛 Troubleshooting

### Hook Not Running

```bash
# Check hook is registered
cat ~/.claude/settings.json | grep -A 10 "UserPromptSubmit"

# Verify script exists
ls -la ~/.claude/plugins/ccpm/hooks/scripts/smart-agent-selector.sh

# Check permissions
chmod +x ~/.claude/plugins/ccpm/hooks/scripts/smart-agent-selector.sh
```

### Slow Performance

```bash
# Clear agent discovery cache
rm -rf /tmp/claude-agent-cache*

# Reduce plugin count
# Move unused plugins out of ~/.claude/plugins/

# Check script execution time
time ~/.claude/plugins/ccpm/hooks/scripts/smart-agent-selector.sh "test request"
```

### Wrong Agents Selected

```bash
# Enable verbose logging (if available)
export CLAUDE_HOOK_DEBUG=1

# Check agent descriptions
cat ~/.claude/plugins/*/agents/*.md | grep -A 5 "description:"

# Review scoring algorithm
cat ~/.claude/plugins/ccpm/hooks/SMART_AGENT_SELECTION.md
```

## 📚 Resources

- [CCPM Documentation](../README.md)
- [Smart Agent Selection Details](./SMART_AGENT_SELECTION.md)
- [Creating Custom Agents](../docs/guides/creating-agents.md)
- [Hook Development Guide](../docs/development/hooks.md)
- [PM Tool Abstraction](../docs/architecture/pm-tool-abstraction.md)

## 🙏 Credits

CCPM v1.0 hooks are optimized based on:
- PSN-23: Hook performance optimization (81.7% token reduction)
- PSN-31: Linear subagent pattern (session-level caching)
- PSN-39: v1.0 simplification (remove unused hooks)

Built with Claude Code hooks system and best practices from the community.
