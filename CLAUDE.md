# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ CRITICAL RULES - READ FIRST

### Git Commit & Push Policy

**🚫 NEVER auto-commit or auto-push without explicit user approval**

- ❌ **DO NOT** run `git commit` automatically after making changes
- ❌ **DO NOT** run `git push` automatically after committing
- ✅ **ALWAYS ASK** the user before committing or pushing
- ✅ **SHOW** what will be committed (file list, changes summary)
- ✅ **WAIT** for explicit "yes", "commit", "push" or similar confirmation

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

### Why This Matters
- Users may want to review changes before committing
- Commits may need specific formatting or messages
- Pushing may affect other team members or CI/CD pipelines
- User may want to test changes locally first

**Always ask, never assume permission to commit or push.**

---

## Project Overview

CCPM (Claude Code Project Management) v1.0 is a lean, optimized Claude Code plugin that provides:
- **6 natural workflow commands** (plan, work, sync, commit, verify, done)
- **6 project configuration commands** for multi-project/monorepo support
- **Smart agent auto-invocation** using context-aware scoring
- **Linear-first tracking** with extensible PM tool integration
- **Tool-agnostic architecture** via abstraction layer (Jira, Confluence, etc.)
- **50-60% token reduction** through Linear subagent caching

## Repository Structure

```
ccpm/
├── .claude-plugin/          # Plugin manifest and marketplace config
│   ├── plugin.json          # Plugin metadata (v1.0.0)
│   └── marketplace.json     # Marketplace listing
├── commands/                # All slash commands (13 total) - flat structure
│   ├── plan.md             # Create or plan tasks (with visual context)
│   ├── work.md             # Start or resume work (with pixel-perfect mode)
│   ├── sync.md             # Save progress to Linear
│   ├── commit.md           # Git commit with Linear integration
│   ├── verify.md           # Quality checks and verification
│   ├── done.md             # Finalize task and create PR
│   ├── figma-refresh.md    # Force refresh Figma design cache
│   ├── project:*.md        # Project configuration (6 commands)
│   ├── _*.md               # Feature flags and utilities
│   ├── README.md           # v1.0 command documentation
│   └── SAFETY_RULES.md     # External PM safety rules
├── helpers/                # Reusable helper utilities (10 files)
│   ├── image-analysis.md   # Image detection and analysis (1,836 lines)
│   ├── figma-detection.md  # Figma link detection (272 lines)
│   ├── planning-workflow.md # Planning workflow logic
│   ├── linear.md           # Linear utilities
│   ├── checklist.md        # Checklist management
│   └── ...                 # Other helpers
├── hooks/                  # Hook implementations (1 hook)
│   ├── hooks.json          # Hook configuration
│   ├── scripts/
│   │   └── smart-agent-selector.sh  # Dynamic agent discovery
│   └── README.md           # Hook system documentation
├── skills/                 # Claude Code skills (17 skills)
│   ├── ccpm-code-review/
│   ├── ccpm-debugging/
│   └── ...
└── agents/                 # Custom agents (12 agents)
    ├── linear-operations.md          # Linear subagent (50-60% token reduction)
    ├── pm-operations-orchestrator.md # Tool-agnostic PM routing
    ├── jira-operations.md
    ├── confluence-operations.md
    └── ...
```

**Note:** Commands use a **flat directory structure** with namespace prefixes. All commands require the `/ccpm:` prefix.

## v1.0 Key Changes

### Simplified Command Structure

**Before (v2.x):** 66 commands across spec, planning, implementation, verification, utils, complete
**After (v1.0):** 13 commands (80% reduction)

**Natural Workflow Commands (6):**
- `/ccpm:plan` - Create or plan tasks (routes to planning workflow)
- `/ccpm:work` - Start or resume work (auto-detects from branch)
- `/ccpm:sync` - Save progress to Linear (concise updates)
- `/ccpm:commit` - Git commit with conventional format
- `/ccpm:verify` - Quality checks + final verification
- `/ccpm:done` - Finalize task + create PR

**Visual Context Commands (1):**
- `/ccpm:figma-refresh` - Force refresh Figma design cache and update Linear

**Project Configuration (6):**
- `/ccpm:project:add`, `list`, `show`, `set`, `update`, `delete`

### Simplified Hook System

**Before (v2.x):** 3 hooks (UserPromptSubmit, PreToolUse, Stop)
**After (v1.0):** 1 hook (UserPromptSubmit only)

**Removed:**
- ❌ TDD Enforcer (PreToolUse) - Too opinionated
- ❌ Quality Gates (Stop) - Integrated into `/ccpm:verify`

**Kept:**
- ✅ Smart Agent Selector (UserPromptSubmit) - Core value proposition
- ✅ Optimized: 81.7% token reduction, <1s execution with caching

### Tool-Agnostic Architecture

CCPM v1.0 uses an abstraction layer for external PM tools:

```
Commands → pm-operations-orchestrator → Tool-specific subagents → MCP servers
                                       ├─ linear-operations
                                       ├─ jira-operations
                                       └─ confluence-operations
```

**Benefits:**
- Add new PM tools without modifying commands
- Configuration-driven tool selection per project
- Universal safety rules apply to ALL external systems
- Graceful fallbacks if tools unavailable

See `commands/SAFETY_RULES.md` for external PM write confirmation workflow.

## Key Architectural Concepts

### 1. Smart Agent Auto-Invocation

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
- Example: Design → Implementation → Review (sequential)
- Injects agent invocation instructions into Claude's context

### 2. Linear Operations Subagent

CCPM uses a dedicated Linear subagent for all Linear API operations:

**Purpose:** Central handler for Linear MCP operations with session-level caching

**Benefits:**
- **50-60% token reduction** (15k-25k → 8k-12k per workflow)
- **85-95% cache hit rate** for teams, projects, labels, statuses
- **<50ms** for cached operations (vs 400-600ms direct MCP)
- **Single source of truth** for Linear logic
- **Structured error handling** with actionable suggestions

**Usage in Commands:**

Commands delegate to the subagent via the Task tool. Commands must use **explicit execution instructions**, not YAML template syntax.

**Correct format:**
```markdown
Use the Task tool to update the Linear issue:

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: update_issue
  params:
    issueId: PSN-29
    state: "In Progress"
  context:
    cache: true
  ```
```

**Location:** `agents/linear-operations.md`

### 3. v1.0 Workflow Principles

**PLAN Mode:**
- Deep research (codebase, Linear, external PM, git history)
- Interactive clarification questions (AskUserQuestion)
- Explicit confirmation before updating Linear
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

### 4. Safety Rules

Defined in `commands/SAFETY_RULES.md`, these rules are **ABSOLUTE**:

**⛔ NEVER write to external PM systems without explicit confirmation:**
- Issue tracking (Jira, Azure DevOps, GitHub Issues, etc.)
- Documentation (Confluence, Notion, SharePoint, etc.)
- Team communication (Slack, Teams, Discord, etc.)
- Code hosting writes (BitBucket, GitLab PR posts, etc.)

**✅ Always allowed:**
- Read operations from external systems
- Linear operations (internal tracking)
- Local file operations
- Git operations (commits, pushes follow standard workflow)

**Confirmation workflow:**
1. Display what you intend to do
2. Show exact content to be posted/updated
3. Wait for explicit user confirmation ("yes" or similar)
4. Only proceed after confirmation

### 5. Command Structure & Interactive Mode

All commands follow a consistent pattern:

**Standard Command Flow:**
1. Execute command logic
2. Display current status and progress
3. Calculate completion percentage
4. Suggest intelligent next actions
5. Present interactive menu
6. Allow direct command chaining

**Command Categories:**
- **Natural Workflow** (6 commands): plan, work, sync, commit, verify, done
- **Project Configuration** (6 commands): add, list, show, set, update, delete

### 6. Skills System

CCPM provides 17 installable skills that extend Claude Code's functionality:

**Available Skills:**
- `ccpm-code-review/` - Enhanced code review workflows
- `ccpm-debugging/` - Structured debugging assistance
- `ccpm-mcp-management/` - MCP server management
- `pm-workflow-guide/` - Project management workflows
- `sequential-thinking/` - Complex problem-solving
- And more...

**Installing Skills:**
Skills can be installed globally or per-project using the Claude Code skills system.

### 7. Helper System

CCPM v1.0 includes 10 reusable helper modules in `helpers/` that provide common functionality across commands:

**Active Helpers** (currently used):
- `image-analysis.md` (1,836 lines) - Image detection and analysis for visual context
- `figma-detection.md` (272 lines) - Figma link detection and MCP integration

**Available Helpers** (ready for integration):
- `checklist.md` (802 lines) - Checklist parsing, updating, and progress calculation
- `decision-helpers.md` (919 lines) - Confidence-based decision making with Always-Ask Policy
- `linear.md` - Linear subagent delegation layer for optimized token usage
- `workflow.md` - Workflow state detection (uncommitted changes, stale sync, etc.)
- `planning-workflow.md` - Planning workflow logic for `/ccpm:plan`
- `next-actions.md` - Smart next-action suggestions based on workflow state
- `state-machine.md` - Workflow state machine (IDEA → PLANNED → IMPLEMENTING → etc.)
- `project-config.md` - Project configuration loader for multi-project support

**Helper Integration Strategy** (Staged Approach):
- ✅ **Phase 10.5 (Complete)**: Fixed all v2.x command references in helpers
- ⏳ **Phase 11**: Integrate critical helpers (`checklist`, `decision-helpers`) into commands
- ⏳ **Phase 12**: Full integration with examples and documentation

**Usage Pattern**:
Commands reference helpers at the top:
```markdown
## Helper Functions

This command uses:
- `helpers/checklist.md` - For checklist parsing and updates
- `helpers/decision-helpers.md` - For confidence-based decisions
```

**Key Benefits**:
- **Consistent behavior** across commands
- **Reusable patterns** reduce duplication
- **Single source of truth** for common logic
- **Token efficiency** through shared utilities

### 8. Visual Context Integration (PSN-24 + PSN-25)

CCPM v1.0 includes automatic visual context detection and analysis for pixel-perfect UI implementation:

**Supported Visual Context:**
- **Images** (PNG, JPG, GIF, WEBP, SVG) - UI mockups, architecture diagrams, screenshots
- **Figma Designs** - Design system extraction with Tailwind mappings

**Key Features:**

1. **Automatic Detection** (`/ccpm:plan`):
   - Scans Linear issue attachments for images
   - Detects markdown images in descriptions
   - Extracts Figma links from descriptions and comments
   - Analyzes visual content with context-aware prompts

2. **Pixel-Perfect Implementation** (`/ccpm:work`):
   - Loads UI mockups directly for agents to see
   - Passes visual references to frontend/mobile agents
   - Achieves **95-100% design fidelity** (vs 70-80% text-based)
   - Eliminates lossy translation from design → text → implementation

3. **Design System Extraction** (Figma):
   - Automatic color palette → Tailwind class mapping (#3b82f6 → `blue-500`)
   - Typography → Font family mapping (Inter → `font-sans`)
   - Spacing → Tailwind scale (16px → `space-4`)
   - Cached in Linear comments (1-hour TTL)

4. **Cache Management**:
   - `/ccpm:figma-refresh <issue-id>` - Force refresh cached design data
   - Automatic change detection (color/typography/spacing changes)
   - Multi-server support (per-project Figma MCP instances)

**Helper Files:**
- `helpers/image-analysis.md` (1,836 lines) - Image detection and analysis logic
- `helpers/figma-detection.md` (272 lines) - Figma link detection and MCP integration

**Scripts:**
- `scripts/figma-utils.sh` - URL parsing and validation
- `scripts/figma-server-manager.sh` - MCP server selection
- `scripts/figma-data-extractor.sh` - Design data extraction
- `scripts/figma-design-analyzer.sh` - Tailwind mapping generation
- `scripts/figma-cache-manager.sh` - Linear comment caching

**Performance:**
- Image analysis: ~2-5s per image (max 5 images)
- Figma extraction: ~2-3s cached, ~11-21s first run
- Total: ~10-25s for typical UI task with visual context

**Usage Example:**

```bash
# 1. Plan UI task with Figma design
/ccpm:plan "Implement login screen"
# → Detects Figma link in description
# → Extracts design system (colors, fonts, spacing)
# → Updates description with Tailwind mappings

# 2. Start implementation with visual context
/ccpm:work
# → Loads UI mockups directly for agent
# → Agent sees exact design (pixel-perfect mode)
# → Implements with 95-100% fidelity

# 3. Refresh design cache after designer updates
/ccpm:figma-refresh PSN-123
# → Fetches latest Figma data
# → Detects color/typography changes
# → Updates Linear description with fresh mappings
```

**Impact:**
- **Design Fidelity**: 70-80% (text) → 95-100% (visual) = **+25% improvement**
- **Implementation Speed**: Faster (no text interpretation rounds)
- **Designer-Developer Sync**: Automatic design system updates

## Common Use Cases

### Natural Workflow Example

```bash
# Complete workflow example
/ccpm:plan "Add user authentication" my-app          # Create + plan
/ccpm:work                                           # Start (auto-detects from branch)
/ccpm:sync "Implemented JWT endpoints"               # Save progress
/ccpm:commit                                         # Git commit (conventional)
/ccpm:verify                                         # Quality checks
/ccpm:done                                           # Create PR + finalize
```

### Command Details

**`/ccpm:plan`** - Smart planning with 3 modes:
- Mode 1: `plan "title"` → creates new task
- Mode 2: `plan WORK-123` → plans existing task
- Mode 3: `plan WORK-123 "changes"` → updates plan

**`/ccpm:work`** - Smart work detection:
- Auto-detects: Not started → start, In progress → resume
- Can detect issue from git branch name (e.g., `feature/PSN-29-add-auth`)

**`/ccpm:sync`** - Save progress:
- Auto-detects issue from git branch
- Shows git changes summary
- Updates Implementation Checklist in Linear
- Concise comments (50-100 words vs 500-1000)

**`/ccpm:commit`** - Git integration:
- Conventional commits format automatic
- Links commits to Linear issues
- Smart commit type detection (feat/fix/docs)

**`/ccpm:verify`** - Quality checks:
- Sequential: quality checks → final verification
- Fails fast if checks don't pass
- Invokes code-reviewer agent

**`/ccpm:done`** - Finalize:
- Pre-flight safety checks
- Creates GitHub pull request
- Optional: Sync with Jira/Slack (with confirmation)
- Marks Linear task as Done

## Development Commands

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

File naming: `commands/category:command-name.md` → `/ccpm:category:command-name`

## Important Conventions

### Command Naming

- Use namespace prefix: `/ccpm:category:command-name`
- Natural workflow: plan, work, sync, commit, verify, done
- Project config: project:add, project:list, etc.
- Names should be verb-based

### Safety First

When implementing new commands:
1. **ALWAYS** check if operation writes to external systems
2. If yes, implement confirmation workflow
3. Show exact content before posting
4. Never assume user approval
5. Document safety considerations

### Progress Tracking

**⛔ NEVER write progress, status updates, or task notes to local markdown files**
**✅ ALWAYS use Linear ticket comments for all progress updates**

Benefits:
- Single source of truth
- Visible to entire team
- Automatically timestamped
- Searchable history
- No git noise from progress updates

## Testing Practices

### Testing Command Execution

```bash
# Commands are invoked as slash commands
/ccpm:plan "Test task" test-project

# With auto-detection
/ccpm:work  # Detects issue from branch
/ccpm:sync  # Detects issue from branch
```

### Testing Hooks

Hooks are tested by Claude Code's hook system. Place prompt files in `hooks/`, register in `hooks.json`, and hooks trigger automatically.

## Plugin Configuration

### plugin.json Structure

- `name`: Plugin identifier (ccpm)
- `version`: Semantic version (1.0.0)
- `commands`: ./commands
- `agents`: Array of agent markdown files

### Key Features

- 12 lean commands (82% reduction from v2.x)
- 1 optimized hook (67% reduction from v2.x)
- Tool-agnostic PM integration
- Linear-first with 50-60% token reduction
- Smart agent auto-invocation
- Safety-first design

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

## Best Practices

1. **Hook Development**: Keep hooks fast (<5s) to avoid latency
2. **Command Documentation**: Use clear examples and interactive mode
3. **Safety First**: Always implement confirmation for external writes
4. **Progress Tracking**: Always use Linear comments, never local markdown files
5. **Agent Integration**: Trust smart-agent-selector for optimal agent selection

## Linear Subagent Best Practices

When working with Linear operations in CCPM:

### Enable Caching for Read Operations

```markdown
Task(linear-operations): `
operation: get_issue
params:
  issueId: ${issueId}
context:
  cache: true  # Enable caching for 85-95% hit rate
`
```

### Provide Context for Better Error Messages

```markdown
context:
  command: "plan"  # Helps with debugging
  purpose: "Creating new task"
```

### Handle Errors Gracefully

The subagent provides structured errors with suggestions:

```yaml
error:
  code: STATE_NOT_FOUND
  message: "State 'In Progress' not found"
  suggestions:
    - "Use 'In Progress' (exact match required)"
    - "Available states: Backlog, Todo, In Progress, Done"
```

## Resources

- [Command Reference](./commands/README.md)
- [Safety Rules](./commands/SAFETY_RULES.md)
- [Hook System](./hooks/README.md)
- [Smart Agent Selection](./hooks/SMART_AGENT_SELECTION.md)
- [Skills Catalog](./skills/README.md)

## v1.0 Migration

### From v2.x

**Removed:**
- 40+ old commands consolidated into 6 natural workflow commands
- TDD enforcer hook (too opinionated)
- Quality gates hook (integrated into `/ccpm:verify`)
- BitBucket/Slack specific integrations (tool-agnostic now)

**Benefits:**
- ✅ Simpler (82% fewer commands)
- ✅ Faster (50-60% token reduction)
- ✅ More control (explicit quality checks)
- ✅ Still powerful (smart agent selection)

### Migration Steps

1. **spec:*** → Use Linear Documents directly
2. **planning:*** → Use `/ccpm:plan`
3. **implementation:*** → Use `/ccpm:work` and `/ccpm:sync`
4. **verification:*** → Use `/ccpm:verify`
5. **complete:finalize** → Use `/ccpm:done`
6. **utils:*** → Functionality integrated into main commands

## Credits

CCPM v1.0 is built on lessons learned from v2.x:
- PSN-31: Linear subagent pattern (50-60% token reduction)
- PSN-37: Unified checklist updates
- PSN-39: v1.0 simplification (82% command reduction)

Built for Claude Code with care by the CCPM team.
