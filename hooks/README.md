# CCPM Hook System

CCPM uses Claude Code hooks to provide intelligent automation throughout the development workflow. Hooks intercept events at key points in the session lifecycle to inject context, validate operations, and prevent common mistakes.

## Hook Overview

| Hook Phase | Script | Purpose |
|------------|--------|---------|
| **SessionStart** | `session-init.cjs` | Initialize session with project context |
| **UserPromptSubmit** | `smart-agent-selector.sh` | Suggest optimal agents for tasks |
| **PreToolUse** | `scout-block.cjs` | Block invalid tool operations |
| **PreToolUse** | `delegation-enforcer.cjs` | Enforce agent delegation patterns |
| **PreToolUse** | `context-capture.cjs` | Log session activity for subagents |
| **PreToolUse** | `linear-param-fixer.sh` | Fix Linear MCP parameter mistakes |
| **SubagentStart** | `subagent-context-injector.cjs` | Inject project context to subagents |
| **Stop** | `guard-commit.cjs` | Warn about uncommitted changes |

## Architecture

```
Session Lifecycle
=================

┌─────────────────────────────────────────────────────────────┐
│                    SESSION STARTS                            │
│  Hook: SessionStart (session-init.cjs)                      │
│  - Detects project from git remote/directory                │
│  - Extracts issue ID from branch name                       │
│  - Discovers available agents                               │
│  - Persists state to /tmp/ccpm-session-*.json              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  USER SENDS MESSAGE                          │
│  Hook: UserPromptSubmit (smart-agent-selector.sh)           │
│  - Detects task-specific keywords                           │
│  - Outputs minimal agent hint (~15 tokens)                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  CLAUDE USES TOOLS                           │
│  Hooks: PreToolUse (multiple scripts)                       │
│  - scout-block: Validates Read/WebFetch/Task calls          │
│  - delegation-enforcer: Warns on direct Edit/Write          │
│  - context-capture: Logs activity for subagents             │
│  - linear-param-fixer: Corrects MCP parameter errors        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  SUBAGENT SPAWNED                            │
│  Hook: SubagentStart (subagent-context-injector.cjs)        │
│  - Injects CLAUDE.md files                                  │
│  - Adds task context (issue, branch, progress)              │
│  - Includes session activity log                            │
│  - Provides agent-specific guidance                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    SESSION ENDS                              │
│  Hook: Stop (guard-commit.cjs)                              │
│  - Checks for uncommitted changes                           │
│  - Warns if thresholds exceeded                             │
│  - Suggests commit command                                  │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
hooks/
├── hooks.json                         # Hook configuration
├── README.md                          # This documentation
├── SMART_AGENT_SELECTION.md           # Agent selection algorithm details
└── scripts/
    ├── session-init.cjs               # SessionStart hook
    ├── smart-agent-selector.sh        # UserPromptSubmit hook
    ├── scout-block.cjs                # PreToolUse: block invalid operations
    ├── delegation-enforcer.cjs        # PreToolUse: enforce agent patterns
    ├── context-capture.cjs            # PreToolUse: log session activity
    ├── linear-param-fixer.sh          # PreToolUse: fix Linear params
    ├── subagent-context-injector.cjs  # SubagentStart hook
    ├── guard-commit.cjs               # Stop hook
    ├── statusline.cjs                 # CLI status bar display
    └── lib/
        ├── hook-logger.cjs            # Shared logging utility
        └── session-utils.cjs          # Session state utilities
```

## Hook Details

### SessionStart: Session Initialization

**Script:** `session-init.cjs`
**Triggers:** startup, resume, clear, compact
**Timeout:** 5000ms

Initializes the CCPM session with comprehensive project context. Runs once at session start rather than per-message, reducing token usage by 94%.

**Features:**
- Detects Linear issue from git branch (e.g., `feature/WORK-26-add-auth`)
- Identifies project from git remote or directory name
- Captures git state: uncommitted files, last commit
- Discovers CLAUDE.md files in project hierarchy
- Extracts key rules from CLAUDE.md
- Discovers all available agents (plugin + project)
- Persists state to `/tmp/ccpm-session-{sessionId}.json`
- Exports environment variables: `CCPM_SESSION_ID`, `CCPM_ACTIVE_ISSUE`, `CCPM_ACTIVE_PROJECT`

**Output (~1.2K tokens):**
```markdown
## CCPM Session Initialized

**Project:** my-app | **Issue:** WORK-26 | **Branch:** feature/WORK-26

### Available Agents (18)
ccpm:linear-operations, ccpm:frontend-developer, ccpm:backend-architect...

### Agent Invocation Rules
| Task Type | Agent | Triggers |
|-----------|-------|----------|
| Linear ops | ccpm:linear-operations | issue, linear, status |
| Frontend | ccpm:frontend-developer | component, UI, React |
...
```

### UserPromptSubmit: Smart Agent Selector

**Script:** `smart-agent-selector.sh`
**Triggers:** Every user message
**Timeout:** 5000ms

Provides lightweight task-specific agent hints. Since full context is injected at session start, this hook only adds minimal hints when specific keywords are detected.

**Features:**
- Keyword-based task detection
- Minimal context injection (~15 tokens max)
- Fast execution (<100ms)

**Output (when keywords match):**
```
Hint: Linear task detected - use `ccpm:linear-operations` agent
```

### PreToolUse: Scout Block

**Script:** `scout-block.cjs`
**Triggers:** Read, WebFetch, Task tool calls
**Timeout:** 1000ms

Pre-filters tool calls to prevent wasted tokens on operations that will fail. Provides 30-50% token savings by catching invalid operations before execution.

**Validations:**
- **Read:** File exists, size < 5MB, not binary
- **WebFetch:** Valid URL format, blocks localhost/internal
- **Task:** Subagent type and prompt are provided

**Output (when blocked):**
```
Blocked: File does not exist: /path/to/missing.ts
Suggestion: Use Glob to find similar files
```

### PreToolUse: Delegation Enforcer

**Script:** `delegation-enforcer.cjs`
**Triggers:** Edit, Write tool calls
**Timeout:** 500ms

Enforces agent delegation during `/ccpm:work` AI implementation mode. Warns when the main agent uses Edit/Write directly instead of delegating to specialized agents.

**Features:**
- Checks delegation mode state (set by `/ccpm:work`)
- Warns on Edit/Write during active delegation mode
- Suggests appropriate agent based on file type
- Advisory mode (warns but doesn't block)
- 1-hour timeout for delegation mode

**State file:** `/tmp/ccpm-delegation-mode.json`

### PreToolUse: Context Capture

**Script:** `context-capture.cjs`
**Triggers:** Write, Edit, Task, Bash tool calls
**Timeout:** 500ms

Auto-captures session activity for injection into subagents. Zero token cost to main agent (purely observational).

**Captured Events:**
- File creations and modifications
- Task starts with agent type
- Test runs and builds
- Git commits
- Decisions from task prompts

**Output:** Appends to `/tmp/ccpm-context-{issueId}.log`

### PreToolUse: Linear Parameter Fixer

**Script:** `linear-param-fixer.sh`
**Triggers:** `mcp__agent-mcp-gateway__execute_tool` calls
**Timeout:** 2000ms

Catches common Linear MCP parameter mistakes before they cause failures. The Linear API uses inconsistent parameter names (`id` vs `issueId`).

**Parameter Corrections:**
| Tool | Correct Parameter | Common Mistake |
|------|------------------|----------------|
| `get_issue` | `id` | `issueId` |
| `update_issue` | `id` | `issueId` |
| `create_comment` | `issueId` | `id` |
| `list_comments` | `issueId` | `id` |

### SubagentStart: Context Injector

**Script:** `subagent-context-injector.cjs`
**Triggers:** All subagent spawns (Task tool)
**Timeout:** 3000ms

Injects comprehensive CCPM context into all subagents (~10K tokens). Ensures subagents follow project instructions and have full context.

**Context Sections:**
1. **CLAUDE.md files** (~5K tokens) - Full project instructions
2. **Task context** (~500 tokens) - Issue, branch, progress
3. **Agent-specific rules** (~500 tokens) - Tailored guidance per agent type
4. **Session context** (~500 tokens) - Recent decisions, completions
5. **Git state** (~200 tokens) - Uncommitted files, recent commits
6. **Global rules** (~200 tokens) - CCPM-wide rules

**Agent-Specific Rules:**
- `ccpm:frontend-developer` - Component patterns, styling, accessibility
- `ccpm:backend-architect` - API patterns, database, auth, error handling
- `ccpm:debugger` - Investigation, root cause, fixing, prevention
- `ccpm:code-reviewer` - Security, code quality, testing
- `ccpm:security-auditor` - Injection, auth, data protection
- `ccpm:linear-operations` - Parameter names, caching, batching

### Stop: Guard Commit

**Script:** `guard-commit.cjs`
**Triggers:** Session end, throttle, context full
**Timeout:** 5000ms

Prevents work loss by warning about uncommitted changes when the session ends unexpectedly.

**Features:**
- Detects uncommitted files (staged and unstaged)
- Counts changed lines for threshold comparison
- Suggests commit message based on file types
- Extracts issue ID from branch name for commit scope

**Configuration (environment variables):**
| Variable | Default | Description |
|----------|---------|-------------|
| `CCPM_GUARD_COMMIT_MAX_FILES` | 5 | Trigger if more than N files changed |
| `CCPM_GUARD_COMMIT_MAX_LINES` | 100 | Trigger if more than N lines changed |
| `CCPM_GUARD_COMMIT_AUTO` | false | If true, suggest auto-commit command |

**Output (when thresholds exceeded):**
```markdown
## Uncommitted Changes Detected

| Metric | Value | Threshold |
|--------|-------|-----------|
| Files changed | 8 | 5 |
| Lines changed | ~150 | 100 |

### Suggested Commit
git add . && git commit -m "wip(WORK-42): work in progress"
```

## Status Line

CCPM provides a CLI status bar that displays current session information.

**Script:** `statusline.cjs`

**Display Format:** `project | ISSUE-ID | progress% | branch`

**Example:** `ccpm | WORK-26 | 75% | add-improvements`

**Color Coding:**
- Project name: cyan
- Issue ID: green
- Progress: red (<30%), yellow (30-70%), green (>70%)
- Branch: magenta

## Hook Logging

All hooks log to `/tmp/ccpm-hooks.log` for debugging:

```bash
# Watch hook activity in real-time
tail -f /tmp/ccpm-hooks.log
```

**Example output:**
```
19:15:45 [session-init] Project: ccpm | Branch: main | Issue: none
19:16:02 [smart-agent-selector] Hint: Debug task - use ccpm:debugger
19:30:00 [guard-commit] 8 files, 150 lines UNCOMMITTED
```

The log is cleared at the start of each session.

## Configuration

### Automatic Installation

Hooks are automatically installed with the CCPM plugin. The configuration in `hooks/hooks.json` is applied when the plugin loads.

### Disabling Hooks

Disable specific hooks in your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": []
  }
}
```

### Adjusting Timeouts

Override hook timeouts for slower environments:

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/subagent-context-injector.cjs",
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
```

## Performance

| Metric | Value |
|--------|-------|
| Session initialization | ~1.2K tokens (once) |
| Per-message hints | ~15 tokens |
| 10-message session total | ~1.35K tokens |
| Token reduction vs per-message injection | **94%** |
| Hook execution time | <100ms typical |

## Troubleshooting

### Hook Not Running

```bash
# Verify scripts are executable
chmod +x hooks/scripts/*.sh
chmod +x hooks/scripts/*.cjs

# Check hook registration
cat hooks/hooks.json | jq '.hooks'

# Test script manually
./hooks/scripts/smart-agent-selector.sh "test message"
```

### Slow Performance

```bash
# Clear caches
rm -rf /tmp/ccpm-session-*
rm -rf /tmp/ccpm-context-*

# Check script execution time
time ./hooks/scripts/session-init.cjs
```

### Session State Issues

```bash
# View current session state
cat /tmp/ccpm-session-*.json | jq .

# Clear session state
rm /tmp/ccpm-session-*.json
```

### Subagent Missing Context

```bash
# Check context log exists
ls -la /tmp/ccpm-context-*.log

# View captured context
cat /tmp/ccpm-context-*.log
```

## Design Principles

1. **Fail-open** - Hooks exit successfully even on errors to avoid blocking sessions
2. **Minimal overhead** - Context injected once at session start, not per-message
3. **Observational** - Context capture adds zero tokens to main agent
4. **Advisory** - Delegation enforcer warns but doesn't block
5. **Cacheable** - Session state persisted for fast retrieval

## Resources

- [Smart Agent Selection Algorithm](./SMART_AGENT_SELECTION.md)
- [CCPM Main Documentation](../README.md)
- [Agent Definitions](../agents/)
- [Command Reference](../commands/README.md)
