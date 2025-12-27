# CCPM - Claude Code Project Management

A lean, powerful Claude Code plugin for project management with Linear integration, smart agents, and visual context support.

**Author:** duongdev ([@duongdev](https://github.com/duongdev))
**License:** MIT
**Repository:** [github.com/duongdev/ccpm](https://github.com/duongdev/ccpm)

---

## What is CCPM?

CCPM streamlines your development workflow with intelligent automation:

- **Natural workflow** - 6 core commands for your entire development lifecycle
- **Smart agents** - Context-aware automatic agent selection and delegation
- **Linear integration** - Automatic issue tracking with 50-60% token reduction
- **Visual context** - Figma designs and image analysis for pixel-perfect UI
- **Tool-agnostic** - Supports Linear, Jira, Confluence via abstraction layer
- **Safety-first** - Explicit confirmation for external system writes

---

## Quick Start

### Installation

```bash
# Add the CCPM marketplace
/plugin marketplace add duongdev/ccpm

# Install the plugin
/plugin install ccpm

# Verify installation
/ccpm:status
```

### Configure Your First Project

```bash
# Initialize CCPM in your project
/ccpm:init

# Or add project manually
/ccpm:project:add my-app

# Set as active project
/ccpm:project:set my-app
```

### Basic Workflow

```bash
# 1. Plan your task
/ccpm:plan "Add user authentication"

# 2. Start working
/ccpm:work

# 3. Save progress
/ccpm:sync

# 4. Commit changes
/ccpm:commit

# 5. Run quality checks
/ccpm:verify

# 6. Finalize and create PR
/ccpm:done
```

---

## Commands Reference

### Core Workflow Commands

| Command | Description | Example |
|---------|-------------|---------|
| `/ccpm:plan` | Create and plan tasks with deep research | `/ccpm:plan "Add OAuth2 login"` |
| `/ccpm:work` | Start or resume implementation | `/ccpm:work` or `/ccpm:work PSN-29` |
| `/ccpm:sync` | Save progress to Linear | `/ccpm:sync "Implemented endpoints"` |
| `/ccpm:commit` | Git commit with conventional format | `/ccpm:commit` |
| `/ccpm:verify` | Run quality checks and code review | `/ccpm:verify` |
| `/ccpm:done` | Create PR and finalize task | `/ccpm:done` |

### Planning Variants

| Command | Description | Example |
|---------|-------------|---------|
| `/ccpm:plan:quick` | Fast planning with minimal research | `/ccpm:plan:quick "Fix button"` |
| `/ccpm:plan:deep` | Comprehensive research and analysis | `/ccpm:plan:deep PSN-29` |

### Work Variants

| Command | Description | Example |
|---------|-------------|---------|
| `/ccpm:work:parallel` | Execute independent tasks simultaneously | `/ccpm:work:parallel PSN-29` |

### Utility Commands

| Command | Description | Example |
|---------|-------------|---------|
| `/ccpm:status` | Show project and task status | `/ccpm:status` |
| `/ccpm:search` | Search Linear issues | `/ccpm:search auth --status="In Progress"` |
| `/ccpm:history` | Activity timeline (git + Linear) | `/ccpm:history --days=7` |
| `/ccpm:branch` | Smart git branch management | `/ccpm:branch PSN-29` |
| `/ccpm:review` | Multi-perspective code review | `/ccpm:review --staged --multi` |
| `/ccpm:rollback` | Undo recent operations safely | `/ccpm:rollback --git` |
| `/ccpm:chain` | Execute command chains | `/ccpm:chain full PSN-123` |
| `/ccpm:init` | Initialize CCPM in a project | `/ccpm:init` |
| `/ccpm:org-docs` | Organize repository documentation | `/ccpm:org-docs` |
| `/ccpm:figma-refresh` | Refresh Figma design cache | `/ccpm:figma-refresh PSN-123` |

### Project Configuration

| Command | Description | Example |
|---------|-------------|---------|
| `/ccpm:project:add` | Add a new project | `/ccpm:project:add my-app` |
| `/ccpm:project:list` | List all projects | `/ccpm:project:list` |
| `/ccpm:project:show` | Show project details | `/ccpm:project:show my-app` |
| `/ccpm:project:set` | Set active project | `/ccpm:project:set my-app` |
| `/ccpm:project:update` | Update project config | `/ccpm:project:update my-app` |
| `/ccpm:project:delete` | Remove a project | `/ccpm:project:delete old-app` |

---

## Key Features

### Smart Agent System

CCPM automatically selects and invokes specialized agents based on your task:

| Agent | Purpose |
|-------|---------|
| `frontend-developer` | React/UI components, styling, accessibility |
| `backend-architect` | APIs, NestJS, databases, authentication |
| `code-reviewer` | Quality review, security, best practices |
| `security-auditor` | OWASP Top 10, vulnerability detection |
| `debugger` | Systematic debugging and investigation |
| `tdd-orchestrator` | Test-driven development workflow |
| `linear-operations` | Optimized Linear API operations (cached) |

Agent selection is automatic based on:
- Keywords in your message (+10 per match)
- Task type alignment (+20)
- Tech stack relevance (+15)
- Project-specific agents (+25 priority)

### Linear Integration

All Linear operations are automatic and optimized:

- **No confirmation needed** - Linear is internal tracking
- **50-60% token reduction** - Session-level caching
- **85-95% cache hit rate** - Teams, labels, statuses cached
- **Auto-detection** - Issue ID extracted from git branch

```bash
# Branch naming enables auto-detection
git checkout -b feature/PSN-29-add-auth

# Now all commands auto-detect PSN-29
/ccpm:work    # Works on PSN-29
/ccpm:sync    # Syncs PSN-29
/ccpm:done    # Finalizes PSN-29
```

### Visual Context

CCPM supports visual context for pixel-perfect UI implementation:

**Figma Integration:**
- Automatic design system extraction
- Color palette to Tailwind class mapping
- Typography and spacing conversion
- Cached in Linear for performance

**Image Analysis:**
- UI mockups analyzed during planning
- Screenshots passed to implementation agents
- 95-100% design fidelity (vs 70-80% text-based)

```bash
# Refresh Figma cache after designer updates
/ccpm:figma-refresh PSN-123
```

### Multi-Perspective Code Review

```bash
# Run comprehensive review from multiple perspectives
/ccpm:review --staged --multi
```

Perspectives analyzed:
- **Code Quality** - Bugs, style, complexity
- **Security** - OWASP Top 10, injection flaws
- **Architecture** - Patterns, coupling, scalability
- **UX/Accessibility** - A11y, responsive design

### Command Chaining

Execute workflow templates or custom chains:

```bash
# Built-in templates
/ccpm:chain full PSN-123       # plan -> work -> verify -> commit -> done
/ccpm:chain bugfix PSN-456     # work -> commit -> verify
/ccpm:chain ship               # verify -> done
/ccpm:chain morning            # status; search --mine

# Custom chains
/ccpm:chain "/ccpm:verify && /ccpm:done"
```

---

## Hooks

CCPM includes intelligent hooks that run automatically:

| Hook | Trigger | Purpose |
|------|---------|---------|
| Session Init | Session start | Detects project, git state, CLAUDE.md files |
| Smart Agent Selector | User prompt | Suggests optimal agents for task |
| Scout Block | Before Read/WebFetch/Task | Prevents wasted tokens on failing calls |
| Context Capture | Before Write/Edit/Task/Bash | Logs activity for subagent context |
| Delegation Enforcer | Before Edit/Write | Suggests delegation during work mode |
| Linear Param Fixer | Before MCP calls | Catches parameter mistakes |
| Subagent Context Injector | Subagent start | Injects CLAUDE.md and project context |
| Guard Commit | Session end | Warns about uncommitted changes |

---

## Requirements

### Required MCP Servers

| Server | Purpose |
|--------|---------|
| **Linear** | Issue tracking and project management |
| **GitHub** | Pull request creation, repository operations |

### Optional MCP Servers

| Server | Purpose |
|--------|---------|
| Jira | External issue tracking integration |
| Confluence | Documentation integration |
| Figma | Design system extraction |
| Context7 | Library documentation lookup |

---

## Configuration

CCPM stores configuration in `~/.claude/ccpm-config.yaml`:

```yaml
version: "1.0"
default_project: my-app

projects:
  my-app:
    name: "My Application"
    path: /path/to/my-app
    linear:
      team: "Engineering"
      project: "My App"
    git:
      protected_branches:
        - main
        - production
      branch_prefix: feature/
```

### Project Templates

```bash
# Use a template when adding projects
/ccpm:project:add my-app --template fullstack-with-jira
/ccpm:project:add lib --template simple-linear
/ccpm:project:add oss-project --template open-source
```

---

## Skills

CCPM includes installable skills for extended functionality:

| Skill | Purpose |
|-------|---------|
| `ccpm-code-review` | Enhanced code review workflows |
| `ccpm-debugging` | Structured debugging assistance |
| `ccpm-mcp-management` | MCP server management |
| `pm-workflow-guide` | Project management workflows |
| `sequential-thinking` | Complex problem-solving |
| `figma-integration` | Figma design extraction |
| `planning-strategy-guide` | Task complexity assessment |
| `commit-assistant` | Conventional commit assistance |
| `docs-seeker` | Documentation lookup |
| `external-system-safety` | External system confirmation |

---

## Safety Rules

CCPM follows strict safety rules:

**Automatic (no confirmation):**
- Linear operations (internal tracking)
- Local file operations
- Git operations (except push)

**Requires confirmation:**
- External PM systems (Jira, Azure DevOps)
- Documentation platforms (Confluence, Notion)
- Team communication (Slack, Teams)
- Push operations to remote

---

## Troubleshooting

### Commands Not Found

```bash
# Verify plugin is installed
/plugin list

# Reinstall if needed
/plugin install ccpm --force
```

### Linear Operations Failing

- Check Linear MCP server is running
- Verify team/project names match exactly
- Use `/ccpm:status` to check connection

### Hooks Not Running

```bash
# Check hook permissions
chmod +x ~/.claude/plugins/ccpm/hooks/scripts/*.sh
chmod +x ~/.claude/plugins/ccpm/hooks/scripts/*.cjs
```

### Agent Selection Issues

```bash
# Check what agents are discovered
cat /tmp/ccpm-session-*.json | jq '.agents'
```

### Uncommitted Changes Warning

When session ends with uncommitted changes, CCPM warns you:

```bash
# Commit your changes
/ccpm:commit

# Or rollback if needed
/ccpm:rollback --files
```

---

## Project Structure

```
ccpm/
├── commands/           # 19 slash commands
├── agents/             # 17 specialized agents
├── helpers/            # 22 reusable utilities
├── hooks/              # 6 intelligent hooks
├── skills/             # 17 installable skills
├── scripts/            # Helper scripts
└── .claude-plugin/     # Plugin manifest
```

---

## Examples

### Complete Feature Development

```bash
# Plan with deep research
/ccpm:plan:deep "Implement OAuth2 with Google, GitHub, and email login"

# Start implementation (agent selection is automatic)
/ccpm:work

# Save progress periodically
/ccpm:sync "Completed Google OAuth"

# Review your code
/ccpm:review --staged --multi

# Commit when ready
/ccpm:commit

# Final verification
/ccpm:verify

# Create PR and finalize
/ccpm:done
```

### Quick Bug Fix

```bash
# Fast planning for simple fix
/ccpm:plan:quick "Fix null pointer in user service"

# Work and commit
/ccpm:work
/ccpm:commit

# Quick verify and ship
/ccpm:chain ship
```

### Morning Standup

```bash
# Get overview of your work
/ccpm:chain morning

# Or manually
/ccpm:status
/ccpm:search --mine --status="In Progress"
```

### End of Day

```bash
# Wrap up and save progress
/ccpm:sync "EOD: Completed auth module, tests pending"
/ccpm:commit
```

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Follow existing code patterns
4. Submit a pull request

---

## Support

- **Issues:** [GitHub Issues](https://github.com/duongdev/ccpm/issues)
- **Documentation:** This README and inline command help

---

## License

MIT License - see [LICENSE](LICENSE) for details.
