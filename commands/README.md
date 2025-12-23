# CCPM v1.1 Commands

**Simple, powerful workflow commands for Claude Code project management.**

## 🎯 The Natural Workflow (6 Core + 6 Utility + 1 Chain)

CCPM v1.1 provides a streamlined command set optimized for developer productivity.

### Core Workflow Commands

```bash
# 1. PLAN - Create or plan tasks
/ccpm:plan "Add user authentication"              # Create new task
/ccpm:plan WORK-123                                # Plan existing task
/ccpm:plan WORK-123 "Also add 2FA"                 # Update plan

# 2. WORK - Start or resume work
/ccpm:work WORK-123                                # Start/resume specific task
/ccpm:work                                         # Auto-detect from git branch

# 3. SYNC - Save progress
/ccpm:sync                                         # Auto-detect issue, save progress
/ccpm:sync "Completed auth endpoints"              # With custom summary

# 4. COMMIT - Git integration
/ccpm:commit                                       # Auto-generate conventional commit
/ccpm:commit "custom message"                      # Custom commit message

# 5. VERIFY - Quality checks
/ccpm:verify                                       # Run linting, tests, build + code review
/ccpm:verify WORK-123                              # Explicit issue ID

# 6. DONE - Finalize task
/ccpm:done                                         # Create PR, sync status, complete task
/ccpm:done WORK-123                                # Explicit issue ID
```

### Utility Commands (5 commands - New in v1.1)

```bash
# Search & Discovery
/ccpm:search "auth"                                # Search issues by text
/ccpm:search --status="In Progress" --mine        # Filter by status and assignee

# Activity History
/ccpm:history                                      # Show activity timeline
/ccpm:history PSN-29 --days=14                    # Issue history for 2 weeks

# Branch Management
/ccpm:branch PSN-29                               # Create branch for issue
/ccpm:branch --list                               # List branches with Linear info
/ccpm:branch --cleanup                            # Delete merged branches

# Code Review
/ccpm:review                                       # Review current branch
/ccpm:review --staged --post-to-linear            # Review staged, post to Linear

# Rollback Operations
/ccpm:rollback                                     # Interactive rollback menu
/ccpm:rollback --git                              # Undo last commit (soft)
/ccpm:rollback --git --hard                       # Undo commit and discard changes
/ccpm:rollback --linear                           # Revert Linear status

# Command Chaining (New in v1.1)
/ccpm:chain full PSN-123                          # Complete feature workflow
/ccpm:chain bugfix PSN-456 "fix message"          # Quick bug fix
/ccpm:chain quality                               # Review + verify
/ccpm:chain ship                                  # Verify + done
/ccpm:chain --list                                # Show all templates
```

### Project Configuration Commands (6 commands)

```bash
# Project management
/ccpm:project:add <project-id>                     # Add new project
/ccpm:project:list                                 # List all projects
/ccpm:project:show <project-id>                    # Show project details
/ccpm:project:set <project-id>                     # Set active project
/ccpm:project:update <project-id>                  # Update project config
/ccpm:project:delete <project-id>                  # Delete project
```

## 📖 Complete Example Workflow

```bash
# 1. Create and plan a new task
/ccpm:plan "Add JWT authentication" my-app
# → Creates Linear issue WORK-123
# → Researches codebase, Jira, Confluence
# → Updates issue with research and checklist

# 2. Start implementation
/ccpm:work WORK-123
# → Git branch safety check
# → Phase planning (which tasks to do now?)
# → Documents uncertainties in Linear
# → Loads context and suggests implementation

# 3. Save progress regularly
/ccpm:sync "Implemented JWT endpoints"
# → Updates Implementation Checklist in Linear
# → Adds concise comment with progress
# → Shows git changes summary

# 4. Commit your work
/ccpm:commit
# → Auto-generates conventional commit message
# → Links commit to Linear issue
# → Follows repository commit conventions

# 5. Verify quality
/ccpm:verify
# → Runs linting, tests, build
# → Invokes code-reviewer agent
# → Updates Linear with results
# → Marks task as verified if all pass

# 6. Finalize and create PR
/ccpm:done
# → Pre-flight safety checks
# → Creates GitHub pull request
# → Optional: Sync with Jira/Slack (with confirmation)
# → Marks Linear task as Done
```

## 🚀 Key Features

### v1.0 Workflow Principles

**PLAN Mode:**
- Deep research (codebase, Linear, external PM, git history)
- Interactive clarification questions
- Automatic Linear updates (no confirmation - internal tracking)
- Updates issue description (single source of truth)

**WORK Mode:**
- Git branch safety (checks protected branches)
- Phase planning (ask which tasks to do now)
- Mandatory agent delegation (context protection)
- Uncertainty documentation (immediate capture)
- No auto-commit (you decide when)

**Quality Control:**
- Explicit verification via `/ccpm:verify`
- User controls when quality checks run
- No automatic enforcement hooks
- Clear separation: work vs. quality

### Performance Optimizations

- **Token Reduction**: 50-60% average across commands
- **Caching**: Linear subagent with 85-95% cache hit rate
- **Session-Level**: Metadata cached across operations
- **Smart Agent Selection**: Automatic optimal agent invocation

### Safety First

- **External PM writes** require explicit confirmation (Jira, Confluence, etc.)
- **Read operations** are always allowed
- **Linear operations** are internal tracking (automatic)
- **Git operations** follow standard git workflows

See [SAFETY_RULES.md](./SAFETY_RULES.md) for complete safety documentation.

## 📚 Command Details

### /ccpm:plan

Create, plan, or update tasks with deep research and interactive clarification.

**Modes:**
- `plan "title"` → Create new task (routes to planning workflow)
- `plan WORK-123` → Plan existing task (research + checklist)
- `plan WORK-123 "changes"` → Update plan (interactive clarification)

**Features:**
- Deep codebase research
- External PM integration (Jira, Confluence)
- Interactive clarification questions
- Explicit confirmation required

### /ccpm:work

Start new work or resume in-progress tasks with git safety and phase planning.

**Modes:**
- Auto-detection: Not started → start, In progress → resume
- Git branch detection: Extracts issue ID from branch name
- Phase planning: Ask which tasks to tackle first

**Features:**
- Git branch safety checks
- Phase planning for large tasks
- Uncertainty documentation
- Regular progress syncing

### /ccpm:sync

Save progress to Linear with concise updates and checklist tracking.

**Features:**
- Auto-detects issue from git branch
- Shows git changes summary
- Updates Implementation Checklist
- Concise Linear comments (50-100 words)

### /ccpm:commit

Create git commits with Linear integration and conventional format.

**Features:**
- Auto-generates commit messages
- Links commits to Linear issues
- Conventional commits format
- Smart commit type detection (feat/fix/docs)

### /ccpm:verify

Run quality checks and final verification before completion.

**Workflow:**
1. Quality Checks: linting, tests, build
2. Final Verification: code review, security validation

**Features:**
- Fail fast (stops at quality checks if they fail)
- Checklist validation
- Smart agent invocation for code review
- Updates Linear with results

### /ccpm:done

Finalize completed tasks with PR creation and status syncing.

**Features:**
- Pre-flight safety checks
- GitHub PR creation (automatic)
- External PM sync (with confirmation)
- Linear status update (automatic)

### /ccpm:project:*

Manage project configurations for multi-project workflows.

**Features:**
- Add/remove projects
- Switch between projects
- Configure external PM tools per project
- Monorepo support via subdirectory patterns

### /ccpm:search (New in v1.1)

Search Linear issues with flexible filtering.

**Features:**
- Text search in issue titles
- Filter by status, label, assignee
- `--mine` shortcut for your issues
- `--recent` for last 7 days activity

### /ccpm:history (New in v1.1)

View activity timeline combining git and Linear history.

**Features:**
- Chronological event view
- Git commits + Linear comments + status changes
- Filter by date range (`--days=N`)
- Auto-detects issue from branch

### /ccpm:branch (New in v1.1)

Smart git branch management with Linear integration.

**Features:**
- Auto-generates branch names from issue titles
- Lists branches with linked issue info
- Cleanup merged branches
- Respects CLAUDE.md protected branches

### /ccpm:review (New in v1.1)

AI-powered code review with actionable feedback.

**Features:**
- Reviews staged changes or branch diffs
- Security, bugs, quality, best practices checks
- Interactive fix suggestions
- Posts findings to Linear

### /ccpm:rollback (New in v1.1)

Safely undo recent operations with confirmation.

**Features:**
- Git commit rollback (soft/hard)
- File change restoration
- Linear status reversion
- Creates backup tags for recovery

### /ccpm:chain (New in v1.1)

Execute chained commands with conditional logic.

**Templates:**
- `full` - Complete feature: plan → work → verify → commit → done
- `iterate` - Quick save: sync → commit
- `quality` - Quality checks: review → verify
- `bugfix` - Bug fix: work → commit → verify
- `ship` - Finalize: verify → done
- `morning` - Day start: status ; search --mine
- `eod` - Day end: sync → status

**Operators:**
- `&&` - Run next if success
- `||` - Run next if failure
- `;` - Always run next

## 🔄 Migration from v2.x

### What Changed in v1.0

**Removed:**
- 40+ old commands (spec:*, planning:*, implementation:*, verification:*, utils:*)
- TDD enforcer hook (too opinionated)
- Quality gates hook (integrated into `/ccpm:verify`)
- BitBucket/Slack specific integrations (tool-agnostic now)

**Simplified:**
- 6 natural workflow commands (vs 49 total before)
- 1 hook (smart agent selector) vs 3 hooks before
- Tool-agnostic architecture (any PM tool via MCP)

**Benefits:**
- ✅ Simpler command set (easier to learn)
- ✅ Faster execution (optimized, cached)
- ✅ More control (explicit quality checks)
- ✅ Better UX (less automatic enforcement)
- ✅ Still powerful (smart agent selection)

### Migration Steps

If you were using old commands:

1. **spec:*** → Use Linear Documents directly (no spec commands needed)
2. **planning:*** → Use `/ccpm:plan` (consolidates all planning)
3. **implementation:*** → Use `/ccpm:work` and `/ccpm:sync`
4. **verification:*** → Use `/ccpm:verify`
5. **complete:finalize** → Use `/ccpm:done`
6. **utils:*** → Most functionality integrated into main commands

## 🔧 Helper Utilities

Commands use shared helper utilities from `helpers/`:

| Helper | Used By | Purpose |
|--------|---------|---------|
| `checklist.md` | `/ccpm:work`, `/ccpm:sync` | Parse and update Linear checklists |
| `decision-helpers.md` | `/ccpm:work`, `/ccpm:plan` | Confidence-based decisions (Always-Ask Policy) |
| `image-analysis.md` | `/ccpm:plan` | Detect and analyze UI mockups |
| `figma-detection.md` | `/ccpm:plan`, `/ccpm:figma-refresh` | Extract Figma links and design data |
| `agent-delegation.md` | `/ccpm:work` | Delegate to specialized agents |
| `linear.md` | All commands | Linear subagent delegation layer |
| `gemini-fallback.md` | Large file handling | Process files >25K tokens via Gemini CLI |
| `next-actions.md` | `/ccpm:work`, `/ccpm:sync` | Suggest next steps based on workflow state |
| `state-machine.md` | All commands | Workflow states (IDEA→PLANNED→IMPLEMENTING→VERIFIED→COMPLETE) |
| `planning-workflow.md` | `/ccpm:plan` | Planning workflow logic |
| `project-config.md` | `/ccpm:project:*` | Multi-project configuration loader |
| `workflow.md` | All commands | Detect uncommitted changes, stale sync, etc. |

**New in v1.1:**
- `gemini-fallback.md` - Handle large Linear descriptions via Gemini 2M context
- `gemini-figma-analysis.md` - Design extraction with Gemini vision
- `gemini-multimodal.md` - Audio/video processing support
- `linear-background.md` - Background Linear operations for performance
- `linear-direct.md` - Direct MCP call patterns (verified parameters)

## 📖 Documentation

- [SAFETY_RULES.md](./SAFETY_RULES.md) - External PM system safety rules
- [PM Tool Abstraction](../docs/architecture/pm-tool-abstraction.md) - Architecture guide
- [Smart Agent Selection](../hooks/SMART_AGENT_SELECTION.md) - Agent auto-invocation
- [Skills Catalog](../skills/README.md) - Available skills

## 🙏 Credits

CCPM v1.0 is built on lessons learned from v2.x:
- PSN-31: Linear subagent pattern (50-60% token reduction)
- PSN-37: Unified checklist updates
- PSN-39: v1.0 simplification (82% command reduction)

Built for Claude Code with ❤️ by the CCPM team.
