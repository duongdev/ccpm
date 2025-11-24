# CCPM - Claude Code Project Management Plugin

**Lean, powerful project management with Linear integration, smart agent auto-invocation, and visual context for pixel-perfect implementation.**

Version: 1.0.0
Author: Dustin Do ([@duongdev](https://github.com/duongdev))
License: MIT

---

## 🎯 What is CCPM v1.0?

CCPM is a lean Claude Code plugin that streamlines your development workflow with intelligent automation and natural commands:

- **13 lean commands** - 6 natural workflow + 6 project config + 1 visual context
- **10 reusable helpers** - Image analysis, Figma integration, and more (2 active, 8 ready)
- **Smart agent auto-invocation** - Context-aware automatic agent selection
- **50-60% token reduction** - Linear subagent with session-level caching
- **Visual context integration** - Figma designs + image analysis for pixel-perfect UI
- **Tool-agnostic architecture** - Jira, Confluence, BitBucket via abstraction layer
- **Safety-first design** - Explicit confirmation for external system writes
- **User-controlled quality** - You decide when to verify and commit

**Built for v1.0:**
- ✅ 82% simpler than v2.x (13 vs 53 commands)
- ✅ Faster execution (optimized caching)
- ✅ More control (explicit quality checks)
- ✅ Still powerful (smart agents + helpers)

---

## 🚀 Quick Start

### Installation

```bash
# Add the CCPM marketplace from GitHub
/plugin marketplace add duongdev/ccpm

# Install the CCPM plugin
/plugin install ccpm

# Verify installation
/ccpm:project:list
```

### Configure Your First Project

```bash
# Add your project (interactive)
/ccpm:project:add my-app

# Set as active project
/ccpm:project:set my-app

# Or enable auto-detection (cd = switch)
/ccpm:project:set auto
```

### Your First Workflow - Natural Commands

**Learn 6 commands, master everything:**

```bash
# 1. PLAN - Create and plan your task
/ccpm:plan "Add user authentication"

# 2. WORK - Start implementation
/ccpm:work

# 3. SYNC - Save progress
/ccpm:sync "Implemented JWT endpoints"

# 4. COMMIT - Commit your work
/ccpm:commit

# 5. VERIFY - Run quality checks
/ccpm:verify

# 6. DONE - Finalize and create PR
/ccpm:done

# That's it! Complete workflow in 6 commands.
```

**Key Benefits:**
- ✅ Auto-detects issue from git branch
- ✅ Smart suggestions after each command
- ✅ Visual context for pixel-perfect UI
- ✅ No automatic enforcement (you control quality)

---

## ✨ Key Features

### 1. Natural Workflow Commands (6 Commands)

**Simple, powerful commands for your entire development lifecycle:**

```bash
/ccpm:plan     # Create or plan tasks
/ccpm:work     # Start or resume work
/ccpm:sync     # Save progress to Linear
/ccpm:commit   # Git commit with conventional format
/ccpm:verify   # Quality checks + code review
/ccpm:done     # Create PR + sync status + complete
```

Each command:
- Auto-detects issue from git branch
- Shows current status and progress
- Suggests intelligent next actions
- Supports interactive mode

### 2. Visual Context Integration (NEW!)

**Pixel-perfect UI implementation with automatic visual analysis:**

- **Automatic Image Detection** - UI mockups, architecture diagrams, screenshots
- **Figma Design Extraction** - Design system → Tailwind class mappings
- **Pixel-Perfect Mode** - Agents see exact designs (95-100% fidelity vs 70-80% text)
- **Design System Caching** - Colors, typography, spacing cached in Linear (1-hour TTL)
- **Change Detection** - Automatic design updates when Figma files change

**How It Works:**

```bash
# 1. Plan task with Figma design link
/ccpm:plan "Implement login screen"
# → Detects Figma link in Linear description
# → Extracts design system (colors #3b82f6 → blue-500)
# → Updates description with Tailwind mappings

# 2. Start implementation with visual context
/ccpm:work
# → Loads UI mockups directly for agent to see
# → Agent implements with 95-100% design fidelity
# → No lossy text translation

# 3. Refresh design cache after updates
/ccpm:figma-refresh PSN-123
# → Fetches latest Figma data
# → Detects color/typography changes
# → Updates Linear with fresh mappings
```

**Supported Visual Contexts:**
- Images: PNG, JPG, GIF, WEBP, SVG
- Figma: Design files via Figma MCP server
- Analysis: Context-aware prompts (UI mockups vs diagrams vs screenshots)

**Performance:**
- Image analysis: ~2-5s per image (max 5)
- Figma extraction: ~2-3s cached, ~11-21s first run
- Total overhead: ~10-25s for typical UI task

### 3. Helper System (10 Reusable Modules)

**Modular helpers for complex functionality:**

**Active Helpers (2):**
- `image-analysis.md` (1,836 lines) - Image detection and visual context analysis
- `figma-detection.md` (272 lines) - Figma link detection and MCP integration

**Ready for Integration (8):**
- `planning-workflow.md` - Planning logic and research
- `linear.md` - Linear utilities
- `checklist.md` - Checklist management
- And 5 more...

**Why Helpers?**
- ✅ Reusable across commands
- ✅ Easier to maintain (single source of truth)
- ✅ Staged integration (add features incrementally)
- ✅ Better performance (only load when needed)

### 4. Smart Agent Auto-Invocation

**Never manually invoke agents again. CCPM automatically:**

- Discovers all available agents (global, plugins, project-specific)
- Analyzes your request context (tech stack, files, task type)
- Scores agents by relevance (0-100+ algorithm)
- Selects and invokes the best agents automatically
- Plans execution (parallel vs sequential)

**Scoring Algorithm:**
```
Score =
  + 10 per keyword match
  + 20 for task type match
  + 15 for tech stack match
  + 5 for plugin agents
  + 25 for project-specific agents (highest priority!)
```

**Example:**
```
You: "Add JWT authentication"
CCPM: Detects backend + security task
      → Invokes: backend-architect → security-auditor
      → All automatically, in the right order
```

**Hook Performance:**
- 81.7% token reduction with caching
- <1s execution (85-95% cache hit rate)
- Runs on every user message (UserPromptSubmit hook)

### 5. Tool-Agnostic PM Architecture

**Work with any project management tools via MCP abstraction:**

```
Commands → pm-operations-orchestrator → Tool-specific subagents → MCP servers
                                       ├─ linear-operations (internal tracking)
                                       ├─ jira-operations (external sync)
                                       └─ confluence-operations (docs)
```

**Benefits:**
- Add new PM tools without modifying commands
- Configuration-driven tool selection per project
- Universal safety rules apply to ALL external systems
- Graceful fallbacks if tools unavailable

**Safety Rules:**
- ✅ Read operations: Always allowed
- ✅ Linear operations: Internal tracking (automatic)
- ⛔ External PM writes: Require explicit confirmation (Jira, Confluence, Slack, BitBucket)
- ✅ Git operations: Follow standard workflows

### 6. Linear Integration with Token Optimization

**50-60% token reduction via Linear subagent caching:**

- Session-level caching (teams, projects, labels, statuses)
- 85-95% cache hit rate
- <50ms for cached operations (vs 400-600ms direct MCP)
- Single source of truth for Linear logic
- Structured error handling with actionable suggestions

**Performance:**
- Before: 15k-25k tokens per workflow
- After: 8k-12k tokens per workflow
- Reduction: 50-60%

### 7. Multi-Project Support

**Manage unlimited projects with auto-detection:**

- Centralized configuration (`~/.claude/ccpm-config.yaml`)
- Auto-detection by directory/git remote
- Project templates for quick setup
- Per-project tech stacks and PM tools
- Monorepo subdirectory support (pattern-based)

**Commands:**
```bash
/ccpm:project:add my-app         # Add new project
/ccpm:project:list               # List all projects
/ccpm:project:show my-app        # Show details
/ccpm:project:set my-app         # Set active project
/ccpm:project:update my-app      # Update config
/ccpm:project:delete my-app      # Delete project
```

---

## 📋 All Commands (13 Total)

### Natural Workflow (6 commands)

| Command | Description |
|---------|-------------|
| `/ccpm:plan [title\|issue-id] ["changes"]` | Create new task, plan existing, or update plan |
| `/ccpm:work [issue-id]` | Start or resume work (auto-detects from branch) |
| `/ccpm:sync [issue-id] [summary]` | Save progress to Linear with checklist updates |
| `/ccpm:commit [issue-id] [message]` | Git commit with Linear integration |
| `/ccpm:verify [issue-id]` | Quality checks + final verification |
| `/ccpm:done [issue-id]` | Create PR + sync status + complete task |

### Project Configuration (6 commands)

| Command | Description |
|---------|-------------|
| `/ccpm:project:add <project-id> [--template T]` | Add new project interactively |
| `/ccpm:project:list` | List all configured projects |
| `/ccpm:project:show <project-id>` | Show complete project configuration |
| `/ccpm:project:set <project-id\|auto\|none>` | Set active project or enable auto-detection |
| `/ccpm:project:update <project-id> [--field F]` | Update project configuration |
| `/ccpm:project:delete <project-id> [--force]` | Delete project (with backup) |

### Visual Context (1 command)

| Command | Description |
|---------|-------------|
| `/ccpm:figma-refresh <issue-id>` | Force refresh Figma design cache and update Linear |

---

## 🔄 Complete Example Workflow

### Task Lifecycle with Visual Context

```bash
# 1. Create and plan a UI task with Figma design
/ccpm:plan "Implement login screen"
# → Creates Linear issue PSN-123
# → Detects Figma link in issue description
# → Extracts design system (colors → blue-500, fonts → Inter, spacing → space-4)
# → Researches codebase (existing auth patterns, UI components)
# → Updates issue with Tailwind mappings and checklist

# 2. Start implementation with pixel-perfect mode
/ccpm:work PSN-123
# → Git branch safety check (prevents commits to main)
# → Phase planning: "Let's implement login form first, then social auth buttons"
# → Loads UI mockups directly for agent
# → Agent sees exact design (95-100% fidelity)
# → Implements with precise spacing, colors, typography
# → Documents uncertainties in Linear (e.g., "Need API endpoint for /login")

# 3. Save progress regularly
/ccpm:sync "Completed login form with validation"
# → Auto-detects issue PSN-123 from branch name
# → Shows git changes summary
# → Updates Implementation Checklist in Linear
# → Adds concise comment (50-100 words) with progress

# 4. Commit your work with conventional format
/ccpm:commit
# → Auto-generates: "feat(auth): implement login form with validation"
# → Links commit to Linear issue PSN-123
# → Follows repository commit conventions

# 5. Designer updates Figma file → refresh cache
/ccpm:figma-refresh PSN-123
# → Fetches latest Figma data
# → Detects color change (#3b82f6 → #2563eb)
# → Updates Linear: "🎨 Design Update: Primary color changed blue-500 → blue-600"

# 6. Verify quality before finalizing
/ccpm:verify
# → Runs linting (ESLint passes ✅)
# → Runs tests (12/12 passed ✅)
# → Runs build (successful ✅)
# → Invokes code-reviewer agent (security, performance, best practices)
# → Updates Linear with verification results
# → Marks task as "Ready for Review"

# 7. Finalize and create PR
/ccpm:done
# → Pre-flight safety checks (all tests pass, branch up-to-date)
# → Creates GitHub pull request with summary
# → Optional: Sync with Jira/Slack (prompts for confirmation)
# → Marks Linear task as "Done"
# → Returns PR URL for review
```

**Total Time:** ~15-20 minutes (vs 40-60 minutes manual workflow)
**Token Usage:** ~8k-12k tokens (vs 15k-25k without caching)
**Design Fidelity:** 95-100% (vs 70-80% text-based)

---

## 📦 Requirements

### Required MCP Servers

CCPM requires two MCP servers to function:

#### Linear MCP
- **Purpose:** Task tracking and project organization
- **Installation:** `npx @lucitra/linear-mcp`
- **Setup:** Requires Linear API key from [linear.app/settings](https://linear.app/settings)
- **Used by:** All workflow commands

#### GitHub MCP
- **Purpose:** PR creation and repository operations
- **Installation:** Remote server (recommended) or `npm install -g @modelcontextprotocol/server-github`
- **Setup:** OAuth via VS Code or personal access token
- **Used by:** `/ccpm:done`, PR workflows

### Optional MCP Servers

These enhance CCPM capabilities:

- **Context7** - Latest library documentation (`npx @upstash/context7-mcp`)
- **Figma** - Design file access for visual context (see [Figma MCP Setup](https://github.com/your-org/figma-mcp))
- **Jira** - External issue tracking integration
- **Confluence** - External documentation sync

### Quick MCP Setup

Add to your `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "@lucitra/linear-mcp"],
      "env": {
        "LINEAR_API_KEY": "your-linear-api-key"
      }
    },
    "github": {
      "command": "github-mcp",
      "args": ["--remote"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

---

## 🔧 Configuration

### Enable Smart Agent Hook (Recommended)

The smart agent selector hook runs on every user message for automatic agent invocation:

```bash
# Hook is installed automatically with plugin
# Verify it's working:
./hooks/scripts/smart-agent-selector.sh | head -20
```

**What It Does:**
- Discovers all available agents (global, plugins, project-specific)
- Scores agents by context relevance (0-100+)
- Automatically invokes best agents
- <1s execution with 85-95% cache hit rate

### Project-Specific Agents

Add custom agents that CCPM will prioritize (+25 score bonus):

```bash
mkdir -p .claude/agents

cat > .claude/agents/api-validator.md << 'EOF'
---
description: Validates API endpoints against our company standards
---

# API Validator

Custom validation for our API conventions...
EOF
```

---

## 🆚 CCPM v1.0 vs v2.x

### What Changed

**Removed:**
- 40+ commands consolidated into 6 natural workflow commands
- TDD enforcer hook (too opinionated)
- Automatic quality gates (manual via `/ccpm:verify`)
- spec:*, planning:*, implementation:*, verification:*, utils:* commands

**Added:**
- Helper system (10 reusable modules)
- Visual context integration (Figma + images)
- Tool-agnostic PM architecture
- Staged feature integration approach

**Benefits:**
- ✅ 82% simpler (13 vs 53 commands)
- ✅ 50-60% token reduction
- ✅ More control (explicit quality checks)
- ✅ Better UX (no automatic enforcement)
- ✅ Faster (optimized caching)
- ✅ Still powerful (smart agents + helpers)

### Migration Steps

If you used v2.x commands:

1. **spec:*** → Use Linear Documents directly (no commands needed)
2. **planning:create/plan** → Use `/ccpm:plan`
3. **implementation:start/sync** → Use `/ccpm:work` and `/ccpm:sync`
4. **verification:check/verify** → Use `/ccpm:verify`
5. **complete:finalize** → Use `/ccpm:done`
6. **utils:*** → Functionality integrated into main commands

---

## 📚 Documentation

### Getting Started
- **[User Guide](./USER_GUIDE.md)** - Complete guide for using CCPM in your projects ⭐ **START HERE**
- [Complete Command Reference](./commands/README.md) - All 13 commands with examples
- [Safety Rules](./commands/SAFETY_RULES.md) - External PM safety guidelines

### Architecture
- [CLAUDE.md](./CLAUDE.md) - Project instructions for development
- [Helper System Overview](./helpers/README.md) - Reusable helper modules
- [Visual Context Integration](./docs/architecture/visual-context.md) - Figma + image analysis

### Development
- [Hook System](./hooks/README.md) - Smart agent auto-invocation
- [Smart Agent Selection](./hooks/SMART_AGENT_SELECTION.md) - Scoring algorithm
- [Skills Catalog](./skills/README.md) - Available skills

---

## 🐛 Troubleshooting

### Commands Not Found

```bash
# 1. Verify plugin is installed
/plugin list
# Should show: ccpm v1.0.0

# 2. Reinstall if needed
/plugin uninstall ccpm
/plugin install ccpm
```

### Hooks Not Running

```bash
# 1. Check hook files exist
ls -la ~/.claude/plugins/ccpm/hooks/

# 2. Test agent discovery
~/.claude/plugins/ccpm/hooks/scripts/smart-agent-selector.sh

# 3. Verify script permissions
chmod +x ~/.claude/plugins/ccpm/hooks/scripts/*.sh
```

### MCP Server Issues

```bash
# Test Linear connection
"List my Linear teams"

# Test GitHub connection
"Show my GitHub repositories"

# Verify API keys in settings
cat ~/.claude/settings.json | grep -A 5 "linear"
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📄 License

MIT License - See [LICENSE](./LICENSE) for details

---

## 🙏 Acknowledgments

Built with:
- [Claude Code](https://code.claude.com) - AI-powered CLI
- [Linear](https://linear.app) - Issue tracking and project management
- [Context7](https://context7.com) - Documentation MCP

CCPM v1.0 is built on lessons learned from v2.x:
- PSN-31: Linear subagent pattern (50-60% token reduction)
- PSN-37: Unified checklist updates
- PSN-39: v1.0 simplification (82% command reduction)
- PSN-24 + PSN-25: Visual context integration (pixel-perfect UI)

---

## 📞 Support

- Issues: [GitHub Issues](https://github.com/duongdev/ccpm/issues)
- Author: [@duongdev](https://github.com/duongdev)
- Email: dustin.do95@gmail.com

---

**CCPM v1.0 - Lean, powerful project management with visual context for pixel-perfect implementation.**

🚀 Get started: `/plugin install ccpm`
