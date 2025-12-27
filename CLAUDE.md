# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## CRITICAL RULES - READ FIRST

### Linear Operations Policy

**ALWAYS execute Linear operations automatically WITHOUT asking for confirmation**

- Linear is CCPM's internal tracking system - not an external system requiring approval
- All Linear writes are automatic - creating issues, updating status, adding comments
- NEVER ask "Do you want me to update Linear?" or "Should I post this to Linear?"
- Just do it - execute Linear operations immediately when needed

**FORBIDDEN PHRASES - NEVER SAY THESE:**
- "Do you want me to update Linear?"
- "Should I post this comment?"
- "Approve?" / "Confirm?"
- "The Linear sync requires your approval"
- "Do you want me to sync?"

**CORRECT BEHAVIOR:**
```
// Just execute and report:
"Updated Linear issue WORK-26 with progress comment"
"Checklist updated: 70% complete"
```

**Why**: Linear is CCPM's internal project tracking, not external team communication. Users expect these operations to happen automatically. See `commands/SAFETY_RULES.md` for the complete policy.

**Examples of automatic Linear operations:**
- Creating new issues
- Updating issue descriptions
- Adding comments with progress updates
- Changing status, labels, or assignments
- Closing or reopening issues

### NEVER Make Direct Linear MCP Calls

**CRITICAL: Always use the `ccpm:linear-operations` agent for ALL Linear operations.**

**Why direct MCP calls are BAD:**
1. **Wrong parameters** - `get_issue` uses `id`, not `issueId` (common mistake)
2. **Token waste** - Calling `get_server_tools` to check schema wastes ~500 tokens
3. **No caching** - Direct calls don't benefit from 85-95% cache hit rate
4. **Context bloat** - Failed calls + retries fill context window quickly

**Correct approach:**
```javascript
// CORRECT: Use Task tool with linear-operations agent
Task(subagent_type="ccpm:linear-operations"): `
operation: get_issue
params:
  issueId: WORK-26  // Agent handles issueId -> id transformation
context:
  cache: true
`

// WRONG: Direct MCP call (will likely fail with wrong params)
mcp__agent-mcp-gateway__execute_tool({
  server: "linear",
  tool: "get_issue",
  args: { issueId: "WORK-26" }  // WRONG! get_issue uses "id"
})
```

**Benefits of using the agent:**
- **Handles parameter transformation** - `issueId` -> `id` automatically
- **50-60% token reduction** - Caching and batching
- **85-95% cache hit rate** - Teams, labels, statuses cached
- **Structured errors** - Actionable suggestions on failure

### Linear MCP Parameter Names Reference

**These are the EXACT parameter names. Copy exactly - do not guess.**

```javascript
// GET ISSUE - uses "id"
{ server: "linear", tool: "get_issue", args: { id: "WORK-26" } }

// UPDATE ISSUE - uses "id"
{ server: "linear", tool: "update_issue", args: { id: "WORK-26", description: "...", state: "..." } }

// CREATE COMMENT - uses "issueId"
{ server: "linear", tool: "create_comment", args: { issueId: "WORK-26", body: "..." } }

// LIST COMMENTS - uses "issueId"
{ server: "linear", tool: "list_comments", args: { issueId: "WORK-26" } }

// CREATE ISSUE - uses "team" and "title"
{ server: "linear", tool: "create_issue", args: { team: "Engineering", title: "..." } }

// GET PROJECT/TEAM/USER - uses "query"
{ server: "linear", tool: "get_project", args: { query: "ProjectName" } }
{ server: "linear", tool: "get_team", args: { query: "TeamName" } }
{ server: "linear", tool: "get_user", args: { query: "me" } }
```

| Tool | Required Param | NOT This |
|------|---------------|----------|
| `get_issue` | **`id`** | ~~issueId~~ |
| `update_issue` | **`id`** | ~~issueId~~ |
| `create_comment` | **`issueId`** | ~~id~~ |
| `list_comments` | **`issueId`** | ~~id~~ |

### Linear Background Operations (Performance)

**Use background execution for non-critical Linear operations**

Linear MCP operations can take 1-2+ minutes due to cold-start latency. Use background execution for non-critical operations:

**Background (fire-and-forget):**
```bash
# Post comment in background
./scripts/linear-background-ops.sh comment ${issueId} "Progress update"

# Update status in background
./scripts/linear-background-ops.sh update-status ${issueId} "In Progress"
```

**Blocking (must wait) - use for:**
- `get_issue` - Need the data to continue
- `create_issue` - Need the issue ID
- `update_checklist_items` - Need progress % for display

| Operation | Mode | Reason |
|-----------|------|--------|
| `create_comment` | Background | User doesn't wait for comments |
| `update_issue` (status) | Background | Non-blocking status change |
| `get_issue` | Blocking | Need data to continue |
| `create_issue` | Blocking | Need issue ID |
| `update_checklist_items` | Blocking | Need progress for display |

### Agent Delegation for Implementation

**ALWAYS delegate implementation to specialized agents to protect main context**

The main context fills rapidly when doing codebase analysis and implementation inline. Use specialized agents:

**Agent Selection by Task Type:**

| Task Type | Agent | Example Tasks |
|-----------|-------|---------------|
| Codebase analysis | `Explore` | Finding files, patterns |
| Frontend/UI | `ccpm:frontend-developer` | React components, CSS |
| Backend/API | `ccpm:backend-architect` | APIs, databases, auth |
| Testing | `ccpm:tdd-orchestrator` | Unit tests, E2E |
| Code Review | `ccpm:code-reviewer` | Quality, security |
| Debugging | `ccpm:debugger` | Investigation, fixes |
| Security | `ccpm:security-auditor` | OWASP, vulnerabilities |

**Context Impact:**

| Approach | Main Context Usage |
|----------|-------------------|
| Analysis + implementation inline | ~15,000 tokens (context full!) |
| Via specialized agents | ~500 tokens (sustainable) |

**Implementation Pattern:**

```javascript
// 1. Use Explore agent for codebase analysis
Task(subagent_type="Explore"): "Find files for ${task}"
// Returns: ~100 tokens (summary)

// 2. Use specialized agent for each checklist item
Task(subagent_type="ccpm:frontend-developer"): "Implement ${item}"
// Returns: ~50 tokens (summary)

// 3. Use background for Linear updates
./scripts/linear-background-ops.sh comment ${issueId} "Done"
// Uses: ~20 tokens
```

**Key Rules:**
- **NEVER** analyze codebase in main context - use Explore agent
- **NEVER** implement code in main context - use specialized agents
- **ALWAYS** break implementation into chunks (one agent per checklist item)
- **ALWAYS** use parallel Task calls when tasks are independent

### Git Commit & Push Policy

**NEVER auto-commit or auto-push without explicit user approval**

- **DO NOT** run `git commit` automatically after making changes
- **DO NOT** run `git push` automatically after committing
- **ALWAYS ASK** the user before committing or pushing
- **SHOW** what will be committed (file list, changes summary)
- **WAIT** for explicit "yes", "commit", "push" or similar confirmation

**Example workflow:**
```
1. Make changes to files
2. Show user: "I've made changes to X files. Would you like me to commit them?"
3. Wait for user response
4. Only then: git add . && git commit -m "message"
5. Ask again: "Would you like me to push to remote?"
6. Wait for confirmation
7. Only then: git push
```

**Why This Matters:**
- Users may want to review changes before committing
- Commits may need specific formatting or messages
- Pushing may affect other team members or CI/CD pipelines
- User may want to test changes locally first

**Always ask, never assume permission to commit or push.**

---

## Project Overview

CCPM (Claude Code Project Management) is a Claude Code plugin that provides:
- **Natural workflow commands** (plan, work, sync, commit, verify, done)
- **Project configuration commands** for multi-project/monorepo support
- **Smart agent auto-invocation** using context-aware scoring
- **Linear-first tracking** with extensible PM tool integration
- **Tool-agnostic architecture** via abstraction layer (Jira, Confluence, etc.)
- **Token-optimized operations** through Linear subagent caching

## Repository Structure

```
ccpm/
├── .claude-plugin/          # Plugin manifest and marketplace config
│   ├── plugin.json          # Plugin metadata
│   └── marketplace.json     # Marketplace listing
├── commands/                # All slash commands (flat structure)
│   ├── plan.md             # Create or plan tasks (with visual context)
│   ├── work.md             # Start or resume work (with pixel-perfect mode)
│   ├── sync.md             # Save progress to Linear
│   ├── commit.md           # Git commit with Linear integration
│   ├── verify.md           # Quality checks and verification
│   ├── done.md             # Finalize task and create PR
│   ├── figma-refresh.md    # Force refresh Figma design cache
│   ├── project:*.md        # Project configuration (6 commands)
│   ├── README.md           # Command documentation
│   └── SAFETY_RULES.md     # External PM safety rules
├── helpers/                # Reusable helper utilities
│   ├── image-analysis.md   # Image detection and analysis
│   ├── figma-detection.md  # Figma link detection
│   ├── planning-workflow.md # Planning workflow logic
│   ├── linear.md           # Linear utilities
│   ├── checklist.md        # Checklist management
│   └── ...                 # Other helpers
├── hooks/                  # Hook implementations
│   ├── hooks.json          # Hook configuration
│   ├── scripts/            # Hook scripts
│   └── README.md           # Hook system documentation
├── skills/                 # Claude Code skills
│   ├── ccpm-code-review/
│   ├── ccpm-debugging/
│   └── ...
└── agents/                 # Custom agents
    ├── linear-operations.md          # Linear subagent
    ├── pm-operations-orchestrator.md # Tool-agnostic PM routing
    ├── frontend-developer.md
    ├── backend-architect.md
    └── ...
```

**Note:** Commands use a **flat directory structure** with namespace prefixes. All commands require the `/ccpm:` prefix.

## Commands

### Natural Workflow Commands

| Command | Description |
|---------|-------------|
| `/ccpm:plan` | Create or plan tasks (routes to planning workflow) |
| `/ccpm:work` | Start or resume work (auto-detects from branch) |
| `/ccpm:sync` | Save progress to Linear (concise updates) |
| `/ccpm:commit` | Git commit with conventional format |
| `/ccpm:verify` | Quality checks + final verification |
| `/ccpm:done` | Finalize task + create PR |

### Planning Variants

| Command | Description |
|---------|-------------|
| `/ccpm:plan:quick` | Fast planning for simple tasks |
| `/ccpm:plan:deep` | Thorough research-based planning |

### Work Variants

| Command | Description |
|---------|-------------|
| `/ccpm:work:parallel` | Parallel execution of independent tasks |

### Visual Context

| Command | Description |
|---------|-------------|
| `/ccpm:figma-refresh` | Force refresh Figma design cache and update Linear |

### Search & Discovery

| Command | Description |
|---------|-------------|
| `/ccpm:search` | Search Linear issues by query, status, label, assignee |
| `/ccpm:history` | Activity timeline combining git + Linear events |
| `/ccpm:status` | Show current CCPM project and task status |

### Branch & Git

| Command | Description |
|---------|-------------|
| `/ccpm:branch` | Smart git branch management with Linear linking |

### Quality & Safety

| Command | Description |
|---------|-------------|
| `/ccpm:review` | AI-powered code review with interactive fixes |
| `/ccpm:rollback` | Safe undo for git commits, files, Linear status |

### Workflow Automation

| Command | Description |
|---------|-------------|
| `/ccpm:chain` | Execute chained commands with conditional logic |
| `/ccpm:init` | Initialize CCPM in a new project |
| `/ccpm:org-docs` | Organize repository documentation |

### Project Configuration

| Command | Description |
|---------|-------------|
| `/ccpm:project:add` | Add a new project to CCPM configuration |
| `/ccpm:project:list` | List all configured CCPM projects |
| `/ccpm:project:show` | Show detailed configuration for a project |
| `/ccpm:project:set` | Set the active project |
| `/ccpm:project:update` | Update an existing project configuration |
| `/ccpm:project:delete` | Delete a project from CCPM configuration |

## Agents

### Linear & PM Operations

| Agent | Purpose |
|-------|---------|
| `linear-operations` | Central handler for Linear MCP operations with caching |
| `pm-operations-orchestrator` | Tool-agnostic PM routing layer |
| `jira-operations` | Jira integration operations |
| `confluence-operations` | Confluence documentation operations |

### Development Agents

| Agent | Purpose |
|-------|---------|
| `frontend-developer` | React/UI with design system integration |
| `backend-architect` | APIs, NestJS, databases, authentication |
| `tdd-orchestrator` | Test-driven development workflow |
| `code-reviewer` | Automated code review and quality |
| `debugger` | Systematic debugging investigation |
| `security-auditor` | OWASP Top 10, security assessment |

### Project Management Agents

| Agent | Purpose |
|-------|---------|
| `project-config-loader` | Loads project configuration |
| `project-context-manager` | Manages project context |
| `project-detector` | Auto-detects project from git/directory |
| `pm:ui-designer` | UI/UX design guidance |

### CCPM Support Agents

| Agent | Purpose |
|-------|---------|
| `claude-code-guide` | Claude Code usage guidance |
| `ccpm-developer` | CCPM plugin development |
| `ccpm-troubleshooter` | Troubleshooting CCPM issues |

## Hooks

CCPM uses multiple hooks to enhance the workflow:

### SessionStart
- **session-init.cjs** - Initializes CCPM session: detects project, git state, CLAUDE.md files

### UserPromptSubmit
- **smart-agent-selector.sh** - Dynamic agent discovery and scoring

### PreToolUse
- **scout-block.cjs** - Pre-filters tool calls to avoid wasted tokens
- **delegation-enforcer.cjs** - Warns when Edit/Write used during AI implementation mode
- **context-capture.cjs** - Auto-logs file changes for subagent context
- **linear-param-fixer.sh** - Catches issueId vs id mistakes before they fail

### SubagentStart
- **subagent-context-injector.cjs** - Injects comprehensive CCPM context to all subagents

### Stop
- **guard-commit.cjs** - Warns about uncommitted changes when session ends

## Architecture

### Tool-Agnostic PM Integration

CCPM uses an abstraction layer for external PM tools:

```
Commands -> pm-operations-orchestrator -> Tool-specific subagents -> MCP servers
                                         ├─ linear-operations
                                         ├─ jira-operations
                                         └─ confluence-operations
```

**Benefits:**
- Add new PM tools without modifying commands
- Configuration-driven tool selection per project
- Universal safety rules apply to ALL external systems
- Graceful fallbacks if tools unavailable

### Smart Agent Auto-Invocation

The `smart-agent-selector.sh` hook runs on every user message:

**Discovery Phase** (cached):
- Scans plugin agents, global agents, project agents
- Builds agent catalog with descriptions and capabilities
- Cache hit rate: 85-95%

**Scoring Phase:**
- Scores agents 0-100+ based on context:
  - +10 per keyword match
  - +20 for task type alignment
  - +15 for tech stack relevance
  - +5 for plugin agents
  - +25 for project-specific agents (highest priority)

**Execution Planning:**
- Determines sequential vs parallel execution
- Example: Design -> Implementation -> Review (sequential)
- Injects agent invocation instructions into Claude's context

### Linear Operations Subagent

CCPM uses a dedicated Linear subagent for all Linear API operations:

**Purpose:** Central handler for Linear MCP operations with session-level caching

**Benefits:**
- **50-60% token reduction** (15k-25k -> 8k-12k per workflow)
- **85-95% cache hit rate** for teams, projects, labels, statuses
- **<50ms** for cached operations (vs 400-600ms direct MCP)
- **Single source of truth** for Linear logic
- **Structured error handling** with actionable suggestions

**CRITICAL:** Linear operations **NEVER require user confirmation**. Linear is CCPM's internal tracking system.

**Location:** `agents/linear-operations.md`

### Workflow Principles

**PLAN Mode:**
- Deep research (codebase, Linear, external PM, git history)
- Interactive clarification questions
- Automatic Linear updates (no confirmation required - internal tracking)
- Updates issue description (single source of truth)

**WORK Mode:**
- Git branch safety checks (prevents commits to protected branches)
- Phase planning (ask which tasks to do now for large tasks)
- Uncertainty documentation (capture blockers immediately)
- No auto-commit (user decides when to commit)

**Quality Control:**
- Explicit verification via `/ccpm:verify` (user controls when)
- User controls when quality checks run (not automatic hooks)
- Clear separation: work vs. quality

### Visual Context Integration

CCPM includes automatic visual context detection for pixel-perfect UI implementation:

**Supported Visual Context:**
- **Images** (PNG, JPG, GIF, WEBP, SVG) - UI mockups, architecture diagrams
- **Figma Designs** - Design system extraction with Tailwind mappings

**Key Features:**
1. **Automatic Detection** (`/ccpm:plan`) - Scans Linear issue attachments for images and Figma links
2. **Pixel-Perfect Implementation** (`/ccpm:work`) - Loads UI mockups directly for agents
3. **Design System Extraction** (Figma) - Automatic color/typography/spacing -> Tailwind mapping
4. **Cache Management** - `/ccpm:figma-refresh` for refreshing cached design data

## Safety Rules

Defined in `commands/SAFETY_RULES.md`, these rules are **ABSOLUTE**:

**NEVER write to external PM systems without explicit confirmation:**
- Issue tracking (Jira, Azure DevOps, GitHub Issues, etc.)
- Documentation (Confluence, Notion, SharePoint, etc.)
- Team communication (Slack, Teams, Discord, etc.)
- Code hosting writes (BitBucket, GitLab PR posts, etc.)

**Always allowed:**
- Read operations from external systems
- Linear operations (internal tracking)
- Local file operations
- Git operations (commits, pushes follow standard workflow)

**Confirmation workflow:**
1. Display what you intend to do
2. Show exact content to be posted/updated
3. Wait for explicit user confirmation ("yes" or similar)
4. Only proceed after confirmation

### Progress Tracking

**NEVER write progress, status updates, or task notes to local markdown files**
**ALWAYS use Linear ticket comments for all progress updates**

Benefits:
- Single source of truth
- Visible to entire team
- Automatically timestamped
- Searchable history
- No git noise from progress updates

## Helpers

CCPM includes reusable helper modules in `helpers/`:

| Helper | Purpose |
|--------|---------|
| `image-analysis.md` | Image detection and analysis for visual context |
| `figma-detection.md` | Figma link detection and MCP integration |
| `checklist.md` | Checklist parsing, updating, and progress calculation |
| `decision-helpers.md` | Confidence-based decision making |
| `linear.md` | Linear subagent delegation layer |
| `workflow.md` | Workflow state detection |
| `planning-workflow.md` | Planning workflow logic |
| `next-actions.md` | Smart next-action suggestions |
| `state-machine.md` | Workflow state machine |
| `project-config.md` | Project configuration loader |
| `gemini-fallback.md` | Gemini CLI fallback for large files |
| `parallel-execution.md` | DAG-based dependency graphs |
| `command-chaining.md` | Chain operators and workflow templates |
| `agent-delegation.md` | Full delegation patterns |
| `branching-strategy.md` | Git branching patterns |
| `commit-patterns.md` | Conventional commit patterns |

## Skills

CCPM provides installable skills in `skills/`:

| Skill | Purpose |
|-------|---------|
| `ccpm-code-review` | Enhanced code review workflows |
| `ccpm-debugging` | Structured debugging assistance |
| `ccpm-mcp-management` | MCP server management |
| `ccpm-skill-creator` | Creating new skills |
| `commit-assistant` | Commit message assistance |
| `docs-seeker` | Documentation searching |
| `external-system-safety` | External system safety patterns |
| `figma-integration` | Figma integration patterns |
| `hook-optimization` | Hook performance optimization |
| `linear-subagent-guide` | Linear subagent usage |
| `natural-workflow` | Natural workflow patterns |
| `planning-strategy-guide` | Planning strategies |
| `pm-workflow-guide` | Project management workflows |
| `project-detection` | Project auto-detection |
| `project-operations` | Project operations |
| `sequential-thinking` | Complex problem-solving |
| `workflow-state-tracking` | Workflow state management |

## Common Workflows

### Complete Task Workflow

```bash
/ccpm:plan "Add user authentication" my-app    # Create + plan
/ccpm:work                                     # Start (auto-detects from branch)
/ccpm:sync "Implemented JWT endpoints"         # Save progress
/ccpm:commit                                   # Git commit (conventional)
/ccpm:verify                                   # Quality checks
/ccpm:done                                     # Create PR + finalize
```

### Command Details

**`/ccpm:plan`** - Smart planning with 3 modes:
- Mode 1: `plan "title"` - creates new task
- Mode 2: `plan WORK-123` - plans existing task
- Mode 3: `plan WORK-123 "changes"` - updates plan

**`/ccpm:work`** - Smart work detection:
- Auto-detects: Not started -> start, In progress -> resume
- Can detect issue from git branch name (e.g., `feature/PSN-29-add-auth`)

**`/ccpm:sync`** - Save progress:
- Auto-detects issue from git branch
- Shows git changes summary
- Updates Implementation Checklist in Linear
- Concise comments (50-100 words)

**`/ccpm:commit`** - Git integration:
- Conventional commits format automatic
- Links commits to Linear issues
- Smart commit type detection (feat/fix/docs)

**`/ccpm:verify`** - Quality checks:
- Sequential: quality checks -> final verification
- Fails fast if checks don't pass
- Invokes code-reviewer agent

**`/ccpm:done`** - Finalize:
- Pre-flight safety checks
- Creates GitHub pull request
- Optional: Sync with Jira/Slack (with confirmation)
- Marks Linear task as Done

## Development

### Testing the Plugin

```bash
# Test agent discovery
./hooks/scripts/smart-agent-selector.sh | head -20

# Check permissions
chmod +x hooks/scripts/*.sh

# Test a command
/ccpm:plan WORK-123
```

### Working with Commands

Commands are markdown files with frontmatter:

```markdown
---
description: Brief command description
---
# Command Name
Implementation details...
```

File naming: `commands/command-name.md` -> `/ccpm:command-name`

### plugin.json Structure

- `name`: Plugin identifier (ccpm)
- `version`: Semantic version
- `commands`: ./commands
- `agents`: Array of agent markdown files

## Best Practices

1. **Hook Development**: Keep hooks fast (<5s) to avoid latency
2. **Command Documentation**: Use clear examples and interactive mode
3. **Safety First**: Always implement confirmation for external writes
4. **Progress Tracking**: Always use Linear comments, never local markdown files
5. **Agent Integration**: Trust smart-agent-selector for optimal agent selection

### Linear Subagent Best Practices

**Enable Caching for Read Operations:**
```markdown
Task(linear-operations): `
operation: get_issue
params:
  issueId: ${issueId}
context:
  cache: true  # Enable caching for 85-95% hit rate
`
```

**Provide Context for Better Error Messages:**
```markdown
context:
  command: "plan"  # Helps with debugging
  purpose: "Creating new task"
```

**Handle Errors Gracefully:**

The subagent provides structured errors with suggestions:
```yaml
error:
  code: STATE_NOT_FOUND
  message: "State 'In Progress' not found"
  suggestions:
    - "Use 'In Progress' (exact match required)"
    - "Available states: Backlog, Todo, In Progress, Done"
```

## Troubleshooting

### Hooks Not Running

1. Check `~/.claude/settings.json` for hook configuration
2. Verify script permissions: `chmod +x hooks/scripts/*.sh`
3. Test discovery script: `./hooks/scripts/smart-agent-selector.sh`

### Wrong Agents Selected

1. Check agent descriptions in discovery output
2. Verify scoring weights in hook script
3. Add project-specific agents for customization (+25 priority bonus)

### Commands Not Found

1. Verify plugin installation: `/plugin list`
2. Check command files exist in `commands/`
3. Ensure proper markdown structure with frontmatter
4. Reload Claude Code

## Integration Points

### Required MCP Servers

- **Linear**: Task tracking, document creation
- **GitHub**: PR creation, repository operations

### Optional MCP Servers

- **Jira**: External issue tracking
- **Confluence**: External documentation
- **Context7**: Latest library documentation fetching
- **Figma**: Design extraction for visual context

## Resources

- [Command Reference](./commands/README.md)
- [Safety Rules](./commands/SAFETY_RULES.md)
- [Hook System](./hooks/README.md)
- [Smart Agent Selection](./hooks/SMART_AGENT_SELECTION.md)
- [Skills Catalog](./skills/README.md)
- [Agents](./agents/README.md)

---

Built for Claude Code by the CCPM team.
