# Agent Auto-Invocation System via Claude Code Hooks

**Automatically invoke specialized agents based on task context using Claude Code hooks.**

## 🎯 Overview

This system uses Claude Code hooks to analyze every user request and automatically invoke the most appropriate specialized agents, enforce TDD practices, and run quality gates after implementation.

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     User Submits Request                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Hook 1: UserPromptSubmit (agent-selector.prompt)              │
│  • Analyzes user intent                                         │
│  • Selects appropriate agents (backend, frontend, TDD, etc.)    │
│  • Injects agent invocation instructions into context           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Claude Starts Working                         │
│  • Invokes selected agents (e.g., backend-architect)            │
│  • Plans implementation                                          │
│  • Prepares to write code                                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Hook 2: PreToolUse (tdd-enforcer.prompt)                      │
│  • Triggers before Write/Edit tools                             │
│  • Checks if tests exist for production code                    │
│  • BLOCKS if tests missing → invokes tdd-orchestrator           │
│  • Enforces Red-Green-Refactor                                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Tests Written First (TDD Enforced)                  │
│  • tdd-orchestrator writes failing tests                        │
│  • Implementation makes tests pass                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Implementation Complete                        │
│  • Code written                                                  │
│  • Tests passing                                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Hook 3: Stop (quality-gate.prompt)                            │
│  • Triggers after Claude finishes                               │
│  • Analyzes what was done                                        │
│  • Auto-invokes: code-reviewer, security-auditor                │
│  • Validates quality, security, performance                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│             Quality Validated, Feature Complete                  │
│  ✅ Tests written first                                         │
│  ✅ Implementation done                                         │
│  ✅ Code reviewed                                               │
│  ✅ Security validated                                          │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Files Structure

```
~/.claude/
├── hooks/
│   ├── agent-selector.prompt       # Analyzes user intent, selects agents
│   ├── tdd-enforcer.prompt         # Enforces test-first development
│   ├── quality-gate.prompt         # Post-implementation quality checks
│   └── README.md                   # This file
├── agent-invocation-hooks.json     # Complete hook configuration
└── settings.json                   # Your main settings (merge hooks here)
```

## 🚀 Installation

### Option 1: Automatic Merge (Recommended)

1. Review the configuration:
   ```bash
   cat ~/.claude/agent-invocation-hooks.json
   ```

2. Merge into your settings:
   ```bash
   # Backup existing settings
   cp ~/.claude/settings.json ~/.claude/settings.json.backup

   # Manual merge: Copy the "hooks" section from agent-invocation-hooks.json
   # into your settings.json
   ```

### Option 2: Use Separate Config

1. Create project-specific hooks:
   ```bash
   cd ~/your-project
   mkdir -p .claude
   cp ~/.claude/agent-invocation-hooks.json .claude/settings.local.json
   ```

2. Edit to customize for your project.

## 🎛️ Configuration

### Enable/Disable Individual Hooks

Edit `settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "enabled": true,  // ← Add this to disable
        "hooks": [...]
      }
    ]
  }
}
```

### Adjust Hook Behavior

Edit the prompt files in `~/.claude/hooks/`:

**Example: Disable TDD for documentation files**

Edit `tdd-enforcer.prompt`, find the "Allow If" section and add:
```
- File path contains /docs/ or /documentation/
```

**Example: Add custom agent to selector**

Edit `agent-selector.prompt`, find "Available Agents" and add:
```
- **your-custom-agent**: Description of what it does
```

## 🧪 Testing

### Test Agent Selection

```bash
# User prompt: "Add user authentication"
# Expected: Should select backend-architect, security-auditor, tdd-orchestrator
```

Output should show:
```
🤖 Agent Selection:
- backend-architect: Design auth API
- security-auditor: Validate security
- tdd-orchestrator: Write tests first

📋 Execution: Sequential
```

### Test TDD Enforcement

```bash
# Try to write production code without tests
# Expected: Should be blocked and invoke tdd-orchestrator
```

Output should show:
```
⚠️  TDD Enforcement: Tests must be written first
Invoking tdd-orchestrator...
```

### Test Quality Gate

```bash
# After implementing a feature
# Expected: Should auto-invoke code-reviewer
```

Output should show:
```
🔍 Quality Gate Active
Running: code-reviewer
```

## 📈 Benefits

### For Individual Developers

- ✅ **Never forget agents**: Automatically invoked based on task
- ✅ **TDD enforced**: Can't skip tests anymore
- ✅ **Quality guaranteed**: Automatic code review after every change
- ✅ **Learn best practices**: Agents guide you to better patterns

### For Teams

- ✅ **Consistent quality**: All developers follow same workflow
- ✅ **Security by default**: Security audits on sensitive changes
- ✅ **Test coverage**: TDD enforcement ensures coverage
- ✅ **Code review culture**: Every change gets reviewed

## 🎯 Use Cases

### Use Case 1: New Feature Development

**Without Hooks:**
```
1. User: "Add user authentication"
2. Claude implements code
3. No tests? Oops, forgot to test
4. No security review? Missed vulnerabilities
5. Manual code review? Takes time
```

**With Hooks:**
```
1. User: "Add user authentication"
2. agent-selector → Selects: backend-architect, security-auditor, tdd-orchestrator
3. backend-architect → Designs auth system
4. tdd-orchestrator → Writes tests first (TDD enforced)
5. Claude → Implements auth to pass tests
6. quality-gate → Auto-invokes code-reviewer + security-auditor
7. Feature complete with tests + reviews + security validation
```

### Use Case 2: Bug Fix

**Without Hooks:**
```
1. User: "Fix the spinner bug"
2. Claude fixes bug
3. Did we add tests? Maybe forgot
4. Did we check for regressions? Not sure
```

**With Hooks:**
```
1. User: "Fix the spinner bug"
2. agent-selector → Selects: debugger
3. debugger → Analyzes and fixes bug
4. quality-gate → Auto-invokes code-reviewer
5. Validates no regressions introduced
```

### Use Case 3: Refactoring

**Without Hooks:**
```
1. User: "Refactor payment module"
2. Claude refactors
3. Tests still passing? Hope so
4. Code quality maintained? Unsure
```

**With Hooks:**
```
1. User: "Refactor payment module"
2. agent-selector → Selects: legacy-modernizer
3. legacy-modernizer → Plans refactoring strategy
4. tdd-enforcer → Verifies tests exist
5. Claude → Refactors
6. quality-gate → Validates tests pass + code quality maintained
```

## ⚙️ Advanced Configuration

### Project-Specific Rules

Create `.claude/settings.local.json` in your project:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Project-specific TDD rules:\n- Skip TDD for /scripts/\n- Require integration tests for /api/\n...",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

### Conditional Hook Execution

Use command hooks with conditions:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "if [[ \"$FILE_PATH\" == *.ts ]]; then ~/.claude/hooks/check-typescript.sh; fi",
            "timeout": 3000
          }
        ]
      }
    ]
  }
}
```

### Hook Chaining

Chain multiple hooks for complex workflows:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "promptFile": "~/.claude/hooks/quality-gate.prompt",
            "description": "Stage 1: Quality check"
          },
          {
            "type": "prompt",
            "promptFile": "~/.claude/hooks/security-check.prompt",
            "description": "Stage 2: Security validation"
          },
          {
            "type": "prompt",
            "promptFile": "~/.claude/hooks/performance-check.prompt",
            "description": "Stage 3: Performance analysis"
          }
        ]
      }
    ]
  }
}
```

## 🐛 Troubleshooting

### Hooks Not Running

1. **Check hook files exist:**
   ```bash
   ls -la ~/.claude/hooks/
   ```

2. **Verify settings.json syntax:**
   ```bash
   cat ~/.claude/settings.json | jq .
   ```

3. **Enable verbose logging:**
   ```bash
   claude --verbose
   ```

4. **Check hook output:**
   - Hook stdout/stderr appears in transcript mode

### False Positives

**TDD enforcer blocking docs:**
```
Edit tdd-enforcer.prompt:
Add to "Allow If" section:
- File path contains .md, .txt, or /docs/
```

**Quality gate triggering on minor changes:**
```
Edit quality-gate.prompt:
Update "Skip Quality Checks If":
- Less than 3 lines changed
- Only whitespace/formatting
```

### Performance Issues

**Hooks adding latency:**
- Each prompt hook: ~2-5 seconds
- Command hooks: <1 second

**Solutions:**
1. Increase timeouts if needed
2. Use command hooks for fast checks
3. Disable hooks for simple tasks
4. Cache agent decisions

## 📚 Additional Resources

- [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks)
- [Agent Workflows Plugin](https://github.com/anthropics/claude-code-workflows)
- [TDD Best Practices](https://code.claude.com/docs/en/tdd)

## 🤝 Contributing

To add custom agents or improve hook logic:

1. Edit prompt files in `~/.claude/hooks/`
2. Test thoroughly in safe environment
3. Document changes in this README
4. Share improvements with team

## ⚠️ Security Notes

- Hooks execute with your system permissions
- Review all prompt files before enabling
- Never run hooks from untrusted sources
- Test hooks in isolated environment first
- Validate hook outputs before execution

## 📝 License

MIT License - Use freely, modify as needed

---

**Questions or Issues?**
- Check troubleshooting section above
- Review hook logs in verbose mode
- Inspect hook JSON responses
- Test individual hooks in isolation
