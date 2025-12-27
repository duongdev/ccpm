# Claude-Mem Integration with CCPM

This helper documents how to integrate [claude-mem](https://github.com/thedotmack/claude-mem) with CCPM for persistent cross-session memory.

## Overview

**claude-mem** is a Claude Code plugin that:
- Automatically captures tool usage observations
- Compresses them with AI (using Claude Agent SDK)
- Injects relevant context into future sessions
- Provides semantic search across project history

**CCPM + claude-mem** = Best of both worlds:
- CCPM: Structured workflow + Linear integration + specialized agents
- claude-mem: Cross-session memory + semantic search + knowledge persistence

## Architecture Comparison

| Feature | CCPM | claude-mem | Combined |
|---------|------|------------|----------|
| Session context | ✅ session-init | ✅ SessionStart | Both work together |
| Tool observation | ✅ context-capture | ✅ PostToolUse | claude-mem is more comprehensive |
| Decision tracking | ✅ decisions-log | ✅ Learnings extraction | CCPM is more structured |
| Linear integration | ✅ Full | ❌ None | Use CCPM |
| Semantic search | ❌ None | ✅ ChromaDB vectors | Use claude-mem |
| Agent routing | ✅ Smart selector | ❌ None | Use CCPM |

## Installation

### Step 1: Install claude-mem

```bash
# In Claude Code session
/plugin marketplace add thedotmack/claude-mem
/plugin install claude-mem

# Restart Claude Code to activate
```

### Step 2: Verify Compatibility

CCPM and claude-mem both use hooks. They should coexist because:
- They use **different hook phases** for most operations
- CCPM: SessionStart (full context), UserPromptSubmit (hints), PreToolUse (validation)
- claude-mem: SessionStart (memory injection), PostToolUse (observation capture)

The only overlap is **SessionStart** - both will run, which is fine.

### Step 3: Configure Integration

Create `~/.claude-mem/settings.json` if needed:

```json
{
  "model": "claude-sonnet-4-20250514",
  "workerPort": 37777,
  "logLevel": "info",
  "context": {
    "maxTokens": 4000,
    "includeRecentSessions": 10,
    "injectOnSessionStart": true
  }
}
```

## How They Work Together

### Session Start Flow

```
┌─────────────────────────────────────────────────────────┐
│                   Session Starts                         │
└────────────────────────────┬────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                              ▼
┌─────────────────────────┐    ┌─────────────────────────┐
│   CCPM: session-init    │    │ claude-mem: SessionStart │
│ • Detects project/issue │    │ • Retrieves past context │
│ • Discovers agents      │    │ • Semantic memory inject │
│ • Injects rules         │    │ • Past error solutions   │
│ • ~1.2K tokens          │    │ • ~2-4K tokens           │
└─────────────────────────┘    └─────────────────────────┘
              │                              │
              └──────────────┬───────────────┘
                             ▼
┌─────────────────────────────────────────────────────────┐
│  Claude has: CCPM context + Past session memory         │
│  • Knows project structure, agents, rules               │
│  • Remembers past decisions, errors, solutions          │
└─────────────────────────────────────────────────────────┘
```

### Tool Observation Flow

```
┌─────────────────────────────────────────────────────────┐
│           Tool Executes (Write, Edit, Bash)             │
└────────────────────────────┬────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                              ▼
┌─────────────────────────┐    ┌─────────────────────────┐
│ CCPM: context-capture   │    │ claude-mem: PostToolUse  │
│ • Logs to session file  │    │ • AI-compressed summary  │
│ • For subagent context  │    │ • Stored in ChromaDB     │
│ • Simple entries        │    │ • Semantic searchable    │
└─────────────────────────┘    └─────────────────────────┘
```

## Usage Patterns

### Pattern 1: Querying Past Work (claude-mem)

Use claude-mem's `mem-search` skill for semantic queries:

```
User: "What authentication approach did we use last week?"

Claude: [mem-search skill activates]
> Searching past sessions...
> Found: On 2025-01-20, we implemented NextAuth.js with JWT sessions
> Reason: Team familiarity, built-in OAuth providers
```

### Pattern 2: Current Task Context (CCPM)

Use CCPM's structured workflow for current task:

```bash
/ccpm:work WORK-42
# CCPM provides: issue details, checklist, agents
# claude-mem adds: relevant past context about similar work
```

### Pattern 3: Decision Continuity

CCPM decisions + claude-mem memory = Full context:

```javascript
// CCPM: Log structured decision
await logDecision({
  title: 'Use Zod for validation',
  reason: 'Type-safe, composable schemas',
  issueId: 'WORK-42'
});

// claude-mem: Automatically captures and stores
// Future sessions: Both systems recall this decision
```

### Pattern 4: Error Resolution

claude-mem shines at remembering past error solutions:

```
Session 1 (last week):
  Error: "Cannot find module '@prisma/client'"
  Solution: Run `prisma generate` after schema changes

Session 2 (today):
  Same error appears
  claude-mem: "Last time you fixed this by running `prisma generate`"
```

## Complementary Features

### CCPM Provides:
- **Structured workflow** - plan → work → sync → verify → done
- **Linear integration** - Issue tracking, comments, status
- **Specialized agents** - Frontend, backend, security, etc.
- **Agent routing** - Smart selection based on task
- **Guard commit** - Prevent work loss

### claude-mem Provides:
- **Semantic memory** - "What did we do about X?"
- **Cross-session context** - Remember past decisions
- **Error pattern detection** - Recall solutions
- **Progressive disclosure** - Layer memory by relevance
- **Web UI** - Visual memory stream at localhost:37777

## Configuration Recommendations

### For Best Integration

1. **Keep both context budgets reasonable**:
   - CCPM session-init: ~1.2K tokens
   - claude-mem injection: ~4K tokens
   - Total: ~5.2K tokens (acceptable overhead)

2. **Use CCPM for structured tracking**:
   - Decisions → `helpers/decisions-log.md`
   - Progress → Linear comments
   - Agents → CCPM specialized agents

3. **Use claude-mem for semantic memory**:
   - Past solutions → mem-search skill
   - Error patterns → Automatic
   - Project history → Automatic

### Environment Variables

```bash
# CCPM settings
export CCPM_GUARD_COMMIT_MAX_FILES=5
export CCPM_GUARD_COMMIT_MAX_LINES=100

# claude-mem works automatically, but you can adjust:
# ~/.claude-mem/settings.json
```

## Troubleshooting

### Hook Conflicts

If hooks seem to conflict:

1. Check hook order in `~/.claude/settings.json`
2. CCPM hooks should run before claude-mem (both non-blocking)
3. Both use fail-open design - one failure won't block the other

### Memory Overlap

If context seems duplicated:

1. CCPM context-capture and claude-mem PostToolUse capture similar data
2. This is intentional - they serve different purposes
3. CCPM: For subagent injection (immediate use)
4. claude-mem: For cross-session memory (future use)

### Performance

If startup is slow:

1. Check claude-mem worker: `http://localhost:37777`
2. Verify ChromaDB is healthy
3. Adjust `maxTokens` in claude-mem settings if needed

## Feature Comparison Matrix

| Need | Use | Why |
|------|-----|-----|
| Start work on issue | CCPM `/ccpm:work` | Linear integration |
| Recall past decision | claude-mem `mem-search` | Semantic search |
| Track current progress | CCPM `/ccpm:sync` | Structured updates |
| Remember error fix | claude-mem (automatic) | Cross-session |
| Run quality checks | CCPM `/ccpm:verify` | Agent orchestration |
| Search project history | claude-mem | Vector search |
| Commit with context | CCPM `/ccpm:commit` | Linear linking |

## Recommended Workflow

1. **Session Start**:
   - CCPM injects project context + agents
   - claude-mem injects relevant past memory

2. **Planning** (`/ccpm:plan`):
   - CCPM structures the plan
   - claude-mem recalls similar past implementations

3. **Implementation** (`/ccpm:work`):
   - CCPM routes to specialized agents
   - claude-mem captures observations

4. **Problem Solving**:
   - Ask "Have we seen this before?"
   - claude-mem searches past solutions

5. **Decisions**:
   - Log with CCPM `logDecision()`
   - claude-mem auto-captures for future

6. **Session End**:
   - CCPM guard-commit warns about uncommitted work
   - claude-mem generates session summary

## Summary

| Component | Role |
|-----------|------|
| **CCPM** | Structured workflow orchestration |
| **claude-mem** | Semantic memory persistence |
| **Together** | Complete development assistant with memory |

Install both, let them work together, get the best of structured workflows + persistent memory.

## Resources

- [claude-mem GitHub](https://github.com/thedotmack/claude-mem)
- [claude-mem Docs](https://docs.claude-mem.ai)
- [CCPM Helpers](./README.md)
- [CCPM Decisions Log](./decisions-log.md)
