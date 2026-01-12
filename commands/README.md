# CCPM Commands Reference

Complete reference for all CCPM slash commands.

## Quick Reference

| Category | Commands | Purpose |
|----------|----------|---------|
| **Core Workflow** | plan, work, sync, commit, verify, done | Main development cycle |
| **Planning Variants** | plan:quick, plan:deep | Fast or thorough planning |
| **Work Variants** | work:parallel, work:loop, cancel-work-loop | Parallel and autonomous execution |
| **Utility** | search, history, branch, review, rollback, chain | Discovery and management |
| **Visual Context** | figma-refresh | Design system updates |
| **Project Config** | project:add, list, show, set, update, delete | Multi-project management |
| **Setup** | init, status, org-docs | Initialization and status |

---

## Core Workflow Commands

The six essential commands for the development lifecycle.

### /ccpm:plan

**Create, plan, or update tasks with intelligent research.**

```bash
# Create new task
/ccpm:plan "Add user authentication"

# Plan existing task
/ccpm:plan WORK-123

# Update existing plan
/ccpm:plan WORK-123 "Also add 2FA support"
```

**Features:**
- Deep codebase analysis
- External PM integration (Jira, Confluence)
- Interactive clarification questions
- Automatic Linear issue updates
- Visual context detection (images, Figma)

---

### /ccpm:work

**Start or resume work with git safety and context loading.**

```bash
# Start/resume specific task
/ccpm:work WORK-123

# Auto-detect from git branch
/ccpm:work
```

**Features:**
- Git branch safety checks
- Phase planning for large tasks
- Uncertainty documentation
- Agent delegation for implementation
- Visual context loading (Figma designs)

---

### /ccpm:sync

**Save progress to Linear with concise updates.**

```bash
# Auto-detect issue and sync
/ccpm:sync

# With custom summary
/ccpm:sync "Completed JWT endpoints"

# Explicit issue
/ccpm:sync WORK-123 "Auth module complete"
```

**Features:**
- Auto-detects issue from git branch
- Updates Implementation Checklist
- Git changes summary
- Concise Linear comments (50-100 words)

---

### /ccpm:commit

**Create conventional commits linked to Linear issues.**

```bash
# Auto-generate commit message
/ccpm:commit

# Custom message
/ccpm:commit "add JWT validation middleware"

# Explicit issue
/ccpm:commit WORK-123 "implement refresh tokens"
```

**Features:**
- Conventional commits format (feat/fix/docs)
- Automatic issue linking
- Smart commit type detection
- Respects repository conventions

---

### /ccpm:verify

**Run quality checks and code review.**

```bash
# Verify current work
/ccpm:verify

# Explicit issue
/ccpm:verify WORK-123
```

**Features:**
- Sequential checks: lint, test, build
- AI-powered code review
- Fail-fast on quality issues
- Results posted to Linear

---

### /ccpm:done

**Finalize task: create PR, update status, complete.**

```bash
# Finalize current task
/ccpm:done

# Explicit issue
/ccpm:done WORK-123
```

**Features:**
- Pre-flight safety checks
- GitHub PR creation
- Optional external PM sync (with confirmation)
- Linear status to Done

---

## Planning Variants

### /ccpm:plan:quick

**Fast planning with minimal research.**

```bash
# Quick task creation
/ccpm:plan:quick "Fix login button alignment"

# With project
/ccpm:plan:quick "Add dark mode toggle" my-app
```

**Differences from /ccpm:plan:**
- Shallow codebase analysis (2-3 files vs 5-10)
- No external research
- Brief checklist (3-5 items vs 10+)
- Skip Figma extraction
- 5-10 seconds vs 30-60

---

### /ccpm:plan:deep

**Comprehensive planning with thorough research.**

```bash
# Deep plan existing issue
/ccpm:plan:deep PSN-29

# Deep plan new task
/ccpm:plan:deep "Implement OAuth2 with multiple providers"
```

**Differences from /ccpm:plan:**
- Comprehensive codebase analysis (20+ files)
- Extended research (docs, APIs, libraries)
- Full dependency graph
- Stakeholder analysis
- Risk assessment
- 2-5 minutes vs 30-60 seconds

---

## Work Variants

### /ccpm:work:parallel

**Execute independent tasks simultaneously.**

```bash
# Auto-detect parallel opportunities
/ccpm:work:parallel PSN-29

# Specific items to parallelize
/ccpm:work:parallel PSN-29 --items 1,2,3

# Maximum parallelism (up to 4 agents)
/ccpm:work:parallel PSN-29 --max 4
```

**Features:**
- Dependency graph analysis
- Parallel agent invocation
- Progress aggregation
- Conflict detection

---

### /ccpm:work:loop

**Autonomous work loop - iterate through all checklist items automatically.**

Based on the [ralph-wiggum pattern](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) for self-referential iterative development.

```bash
# Start loop (auto-detect issue from branch)
/ccpm:work:loop

# Start loop for specific issue
/ccpm:work:loop WORK-26

# Custom iteration limit
/ccpm:work:loop WORK-26 --max-iterations 50

# Resume paused loop (after blocker resolved)
/ccpm:work:loop --resume
```

**How It Works:**
1. Creates state file tracking loop progress
2. Implements first uncompleted checklist item
3. Stop hook intercepts exit and re-feeds prompt
4. Loop continues through all items
5. Ends when: completion promise output, max iterations, or blocker detected

**Completion Signals:**
| Signal | Effect |
|--------|--------|
| `<promise>ALL_ITEMS_COMPLETE</promise>` | Loop ends successfully |
| `Status: Blocked` | Loop pauses for user input |
| Max iterations reached | Loop ends with warning |

**When to Use:**
- Well-defined tasks with clear checklists
- Unattended implementation sessions
- Repetitive multi-item tasks

**When NOT to Use:**
- Tasks requiring design decisions
- Complex tasks needing user judgment
- Exploratory work

---

### /ccpm:cancel-work-loop

**Cancel an active work loop.**

```bash
/ccpm:cancel-work-loop
```

**Output:**
```
Cancelling work loop...

Loop Summary:
  Issue: WORK-26
  Iterations: 5 of 30
  Started: 2026-01-12T10:00:00Z

Work loop cancelled.

Next Steps:
  - Review uncommitted changes with: git status
  - Sync progress manually with: /ccpm:sync
  - Continue interactively with: /ccpm:work WORK-26
```

---

## Utility Commands

### /ccpm:search

**Search Linear issues with flexible filters.**

```bash
# Text search
/ccpm:search authentication

# Status filter
/ccpm:search --status="In Progress"

# Label filter
/ccpm:search --label=frontend

# My assigned issues
/ccpm:search --assignee=me

# Combine filters
/ccpm:search auth --status="In Progress" --label=backend

# Recent issues (last 7 days)
/ccpm:search --recent
```

---

### /ccpm:history

**View activity timeline from git and Linear.**

```bash
# Current issue history
/ccpm:history

# Specific issue
/ccpm:history PSN-29

# Git only
/ccpm:history --git

# Linear only
/ccpm:history --linear

# Custom date range
/ccpm:history --days=14

# Combined
/ccpm:history PSN-29 --days=3
```

---

### /ccpm:branch

**Smart branch management with Linear integration.**

```bash
# Create branch for issue
/ccpm:branch PSN-29

# Custom suffix
/ccpm:branch PSN-29 --suffix=jwt-auth

# Switch to existing branch
/ccpm:branch PSN-29 --switch

# List branches with Linear info
/ccpm:branch --list

# Delete merged branches
/ccpm:branch --cleanup

# Show current branch info
/ccpm:branch
```

---

### /ccpm:review

**AI-powered code review with multiple perspectives.**

```bash
# Review current branch
/ccpm:review

# Review staged changes
/ccpm:review --staged

# Review specific branch
/ccpm:review --branch=feature/auth

# Multi-perspective review
/ccpm:review --multi

# Post to Linear
/ccpm:review --post-to-linear
```

**Multi-perspective mode (`--multi`):**
| Perspective | Focus Areas |
|-------------|-------------|
| Code Quality | Bugs, style, complexity |
| Security | OWASP Top 10, injection, auth |
| Architecture | Patterns, coupling, scalability |
| UX/Accessibility | A11y, responsive design |

---

### /ccpm:rollback

**Safely undo recent operations.**

```bash
# Interactive rollback menu
/ccpm:rollback

# Undo last commit (keeps changes)
/ccpm:rollback --git

# Undo last N commits
/ccpm:rollback --git --last=3

# Restore files from last commit
/ccpm:rollback --files

# Undo Linear status change
/ccpm:rollback --linear

# Hard reset (discards changes)
/ccpm:rollback --git --hard
```

---

### /ccpm:chain

**Execute chained commands with conditional logic.**

```bash
# Use workflow template
/ccpm:chain full PSN-123
/ccpm:chain bugfix PSN-456 "null pointer fix"
/ccpm:chain ship

# Custom chain
/ccpm:chain "/ccpm:work && /ccpm:verify"
/ccpm:chain "/ccpm:verify || /ccpm:sync 'Issues found'"

# List templates
/ccpm:chain --list
```

**Built-in Templates:**
| Template | Commands | Use Case |
|----------|----------|----------|
| `full` | plan -> work -> verify -> commit -> done | Complete feature |
| `iterate` | sync -> commit | Quick save |
| `quality` | review -> verify | Quality checks |
| `bugfix` | work -> commit -> verify | Bug fix |
| `ship` | verify -> done | Finalize |
| `morning` | status ; search --mine | Day start |
| `eod` | sync -> status | Day end |

**Operators:**
- `&&` - Run next if success
- `||` - Run next if failure
- `;` - Always run next

---

## Visual Context Commands

### /ccpm:figma-refresh

**Force refresh Figma design cache.**

```bash
# Refresh design data for task
/ccpm:figma-refresh PSN-123

# After designer updates
/ccpm:figma-refresh WORK-456
```

**Features:**
- Fetches latest Figma data
- Extracts design system (colors, fonts, spacing)
- Updates Linear description with Tailwind mappings
- Detects design changes

---

## Project Configuration Commands

Manage multi-project setups and monorepo configurations.

### /ccpm:project:add

**Add a new project configuration.**

```bash
# Add project
/ccpm:project:add my-app

# With template
/ccpm:project:add my-app --template fullstack-with-jira
```

---

### /ccpm:project:list

**List all configured projects.**

```bash
/ccpm:project:list
```

---

### /ccpm:project:show

**Show detailed project configuration.**

```bash
/ccpm:project:show my-app

# Monorepo with subprojects
/ccpm:project:show repeat
```

---

### /ccpm:project:set

**Set active project for commands.**

```bash
# Set specific project
/ccpm:project:set my-app

# Enable auto-detection
/ccpm:project:set auto

# Clear active project
/ccpm:project:set none
```

---

### /ccpm:project:update

**Update project configuration.**

```bash
# Interactive update
/ccpm:project:update my-app

# Update specific field
/ccpm:project:update my-app --field linear.team
/ccpm:project:update my-app --field external_pm.jira.project_key
```

---

### /ccpm:project:delete

**Remove a project configuration.**

```bash
# With confirmation
/ccpm:project:delete my-app

# Force (skip confirmation)
/ccpm:project:delete my-app --force
```

---

## Setup Commands

### /ccpm:init

**Initialize CCPM in a new project.**

```bash
# Interactive setup
/ccpm:init

# With project name
/ccpm:init my-project

# In monorepo subdirectory
/ccpm:init apps/web
```

---

### /ccpm:status

**Show current project and task status.**

```bash
# Overall status
/ccpm:status

# Specific issue
/ccpm:status PSN-29

# Project status
/ccpm:status --project
```

---

### /ccpm:org-docs

**Organize repository documentation.**

```bash
# Organize current repo
/ccpm:org-docs

# Preview changes
/ccpm:org-docs --dry-run

# Specific path
/ccpm:org-docs /path/to/repo
```

---

## Complete Workflow Example

```bash
# 1. Create and plan task
/ccpm:plan "Add JWT authentication" my-app
# -> Creates Linear issue WORK-123
# -> Researches codebase and external systems
# -> Updates issue with checklist

# 2. Start implementation
/ccpm:work WORK-123
# -> Creates feature branch
# -> Loads visual context (Figma)
# -> Delegates to implementation agents

# 3. Save progress regularly
/ccpm:sync "Completed auth endpoints"
# -> Updates checklist in Linear
# -> Posts progress comment

# 4. Commit work
/ccpm:commit
# -> Generates conventional commit
# -> Links to Linear issue

# 5. Verify quality
/ccpm:verify
# -> Runs lint, test, build
# -> AI code review
# -> Posts results to Linear

# 6. Finalize
/ccpm:done
# -> Creates GitHub PR
# -> Marks Linear as Done
```

---

## Safety Rules

- **Linear operations** are automatic (internal tracking)
- **External PM writes** (Jira, Confluence) require confirmation
- **Read operations** are always allowed
- **Git commits/pushes** require user approval

See [SAFETY_RULES.md](./SAFETY_RULES.md) for details.

---

## Related Documentation

- [SAFETY_RULES.md](./SAFETY_RULES.md) - External PM system rules
- [Hooks](../hooks/README.md) - Smart agent selection
- [Agents](../agents/README.md) - Specialized agents
- [Skills](../skills/README.md) - Available skills
