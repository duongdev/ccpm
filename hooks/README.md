# Smart Agent Auto-Invocation System

**Automatically invoke specialized agents based on task context using Claude Code hooks.**

## 🎯 Overview (v1.0)

CCPM v1.0 uses a streamlined hook system focused on **smart agent selection**. The system analyzes every user request and automatically invokes the most appropriate specialized agents for optimal workflow efficiency.

**Key Changes in v1.0:**
- ✅ **Kept**: Smart Agent Selector (optimized, 81.7% token reduction)
- ❌ **Removed**: TDD Enforcer (developers manage their own testing)
- ❌ **Removed**: Quality Gates (integrated into `/ccpm:verify` command)

## 📊 Architecture (v1.0)

```
┌─────────────────────────────────────────────────────────────────┐
│                     User Submits Request                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Hook: UserPromptSubmit (smart-agent-selector.sh)              │
│  • Discovers all available agents dynamically                   │
│  • Scores agents based on context (0-100+ points)               │
│  • Plans execution (parallel vs sequential)                     │
│  • Injects agent invocation instructions                        │
│  • Caches results for 85-95% faster runs                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Claude Starts Working                         │
│  • Invokes selected agents automatically                        │
│  • Uses optimal agents for the task                             │
│  • Coordinates parallel/sequential execution                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              User Manages Quality Explicitly                     │
│  • Run /ccpm:verify for quality checks                          │
│  • Run /ccpm:commit when ready to commit                        │
│  • Full control over testing and quality workflow               │
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

## 🔧 Smart Agent Selector Hook

### Purpose

Analyzes every user request to determine which specialized agents should be invoked for optimal task execution.

### How It Works

1. **Discovery Phase** (cached)
   - Scans `~/.claude/plugins/*/agents/` for plugin agents
   - Scans `.claude/agents/` for project-specific agents
   - Discovers global agents (general-purpose, Explore, Plan)
   - Caches results for 85-95% faster subsequent runs

2. **Scoring Phase**
   - Analyzes user request for keywords and intent
   - Scores each agent (0-100+ points) based on:
     - Keyword matches (+10 per match)
     - Task type alignment (+20 for matching type)
     - Tech stack relevance (+15 for stack match)
     - Agent source (+5 for plugins, +25 for project-specific)

3. **Planning Phase**
   - Determines execution order (sequential vs parallel)
   - Example sequences:
     - Design → TDD → Implementation → Review (sequential)
     - Multiple independent agents (parallel)

4. **Injection Phase**
   - Injects agent invocation instructions into Claude's context
   - Claude automatically invokes the selected agents
   - Agents execute with full context awareness

### Performance

- **Token reduction**: 81.7% vs baseline
- **Execution time**: <1s with caching (first run: ~2-3s)
- **Cache hit rate**: 85-95%
- **Agent discovery**: 30-50 agents in <100ms

### Example

**User Request**: "Add user authentication with JWT"

**Agent Selector Output**:
```yaml
Agents to invoke:
1. backend-architect (score: 85)
   - Keyword matches: authentication, JWT
   - Task type: backend API design
   - Execution: Sequential (first)

2. security-auditor (score: 75)
   - Keyword matches: authentication
   - Task type: security validation
   - Execution: Sequential (after implementation)

3. tdd-orchestrator (score: 60)
   - Task type: testing strategy
   - Execution: Parallel with implementation
```

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
