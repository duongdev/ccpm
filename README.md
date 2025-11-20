# CCPM - Claude Code Project Management Plugin

**Comprehensive Project Management with Linear integration, smart agent auto-invocation, TDD enforcement, and quality gates.**

Version: 2.1.0
Author: Dustin Do ([@duongdev](https://github.com/duongdev))
License: MIT

> **🎉 NEW in v2.0**: Dynamic multi-project configuration! Manage all your projects from `~/.claude/ccpm-config.yaml`. See [Migration Guide](./MIGRATION_TO_DYNAMIC_CONFIG.md) for details.
>
> **✨ NEW in v2.1**: Monorepo subdirectory support! Auto-detect subprojects in monorepos with pattern-based matching. Includes 4 new management commands and agent-based architecture for 80% token reduction!

---

## 🎯 What is CCPM?

CCPM is a comprehensive Claude Code plugin that transforms your development workflow by combining:

- **31+ PM commands** for complete project lifecycle management
- **Dynamic project configuration** - Multi-project support with auto-detection
- **Monorepo subdirectory support** - Auto-detect subprojects with pattern matching (NEW!)
- **Agent-based architecture** - 80% token reduction with specialized agents (NEW!)
- **Smart agent auto-invocation** with context-aware scoring (0-100+)
- **TDD enforcement** that blocks production code without tests
- **Automatic quality gates** with code review and security audits
- **Linear integration** for spec management and task tracking
- **External PM tools** (Jira, Confluence, BitBucket, Slack)
- **Interactive mode** for continuous workflow without context switching

## 🚀 Quick Start

### Installation

#### Option 1: From GitHub (Recommended)

```bash
# Add the CCPM marketplace from GitHub
/plugin marketplace add your-org/ccpm

# Install the CCPM plugin
/plugin install ccpm

# Verify installation
/pm:utils:help
```

#### Option 2: Local Development

```bash
# Clone the repository
git clone https://github.com/your-org/ccpm
cd ccpm

# Add local marketplace
/plugin marketplace add ./

# Install from local marketplace
/plugin install ccpm

# Verify installation
/pm:utils:help
```

### Enable Hooks (Optional but Recommended)

To enable smart agent auto-invocation, TDD enforcement, and quality gates:

```bash
# Install CCPM hooks
./scripts/install-hooks.sh

# Verify installation
./scripts/verify-hooks.sh
```

**What Hooks Enable:**
- 🤖 **Smart Agent Selection** - Auto-invokes best agents for every task
- ✅ **TDD Enforcement** - Blocks code without tests
- 🔒 **Quality Gates** - Auto code review and security audits

See [INSTALL_HOOKS.md](./INSTALL_HOOKS.md) for detailed instructions.

### Configure Your Projects

```bash
# Add your first project (interactive)
/ccpm:project:add my-app

# Or use a template for quick setup
/ccpm:project:add my-app --template fullstack-with-jira

# Set as active project
/ccpm:project:set my-app

# Or enable auto-detection
/ccpm:project:set auto
```

### Create Your First Task

```bash
# Create task with full planning (uses active project)
/ccpm:planning:create "Add user authentication"

# Or with explicit project
/ccpm:planning:create "Add user authentication" my-app JIRA-123

# Or start with a spec-first approach
/ccpm:spec:create epic "User Management System"

# Follow the interactive prompts - CCPM will guide you!
```

---

## ✨ Key Features

### 1. Dynamic Multi-Project Configuration

**Manage all your projects from one place.** CCPM's new dynamic configuration system:

- **Centralized configuration**: All projects in `~/.claude/ccpm-config.yaml`
- **Auto-detection**: Automatically switches projects based on directory/git remote
- **Project templates**: Quick setup with pre-configured templates
- **Interactive management**: Add/update/delete projects via commands
- **No code changes needed**: Add new projects without editing command files

**Configuration:**
```yaml
# ~/.claude/ccpm-config.yaml
projects:
  my-app:
    name: "My Application"
    linear:
      team: "Work"
      project: "My Application"
    external_pm:
      enabled: true
      type: jira
    # ... and more
```

**Commands:**
```bash
/ccpm:project:add my-app              # Add new project
/ccpm:project:list                    # List all projects
/ccpm:project:show my-app             # Show project details
/ccpm:project:update my-app           # Update configuration
/ccpm:project:set my-app              # Set as active
/ccpm:project:set auto                # Enable auto-detection
```

See [Project Setup Guide](./docs/guides/project-setup.md) for complete documentation.

### 2. Monorepo Subdirectory Support (NEW!)

**Work seamlessly in monorepos with multiple subprojects.** CCPM automatically detects which subproject you're in:

- **Pattern-based detection**: Configure glob patterns for each subproject
- **Auto-detection**: Automatically switches subproject based on working directory
- **Priority-based matching**: Handle nested subdirectories with priority rules
- **Per-subproject tech stacks**: Different tech stacks for each subproject
- **Subproject-aware commands**: All commands understand subproject context

**Configuration:**
```yaml
# ~/.claude/ccpm-config.yaml
projects:
  my-monorepo:
    repository:
      local_path: "/Users/dev/my-monorepo"

    # Auto-detection for subdirectories
    context:
      detection:
        subdirectories:
          - subproject: "frontend"
            match_pattern: "*/apps/frontend/*"
            priority: 10
          - subproject: "backend"
            match_pattern: "*/apps/backend/*"
            priority: 10

    # Subproject metadata
    code_repository:
      subprojects:
        - name: "frontend"
          path: "apps/frontend"
          tech_stack:
            languages: [typescript]
            frameworks:
              frontend: [react, nextjs]
        - name: "backend"
          path: "apps/backend"
          tech_stack:
            languages: [python]
            frameworks:
              backend: [fastapi]
```

**Usage:**
```bash
# Navigate to a subproject
cd ~/my-monorepo/apps/frontend

# Commands automatically detect you're in "frontend"
/ccpm:planning:create "Add dark mode"
# → Creates issue with labels: [my-monorepo, frontend, planning]
# → Uses frontend tech stack (React, Next.js)

# View all subprojects
/ccpm:project:subdir:list my-monorepo

# Add new subproject
/ccpm:project:subdir:add my-monorepo mobile apps/mobile

# Update subproject
/ccpm:project:subdir:update my-monorepo frontend --field tech_stack
```

**Commands:**
- `/ccpm:project:subdir:add` - Add subdirectory configuration
- `/ccpm:project:subdir:list` - List all subdirectories
- `/ccpm:project:subdir:update` - Update subdirectory details
- `/ccpm:project:subdir:remove` - Remove subdirectory

**Benefits:**
- ✅ Automatic context switching as you navigate subdirectories
- ✅ Correct tech stack for agent selection per subproject
- ✅ Subproject labels automatically added to Linear issues
- ✅ Works with Nx, Turborepo, Lerna, pnpm workspaces, and custom setups

See [Monorepo Setup Guide](./docs/guides/monorepo-setup.md) for complete documentation.

### 3. Smart Agent Auto-Invocation

**Never forget to invoke the right agent again.** CCPM automatically:

- Discovers ALL available agents (global, plugins, project-specific)
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
      → Invokes: backend-architect → tdd-orchestrator → security-auditor
      → All automatically, in the right order
```

### 2. TDD Enforcement

**Write tests first, always.** CCPM blocks production code changes if tests don't exist:

- Hooks into Write/Edit/NotebookEdit operations
- Checks for corresponding test files
- **Blocks** execution if tests are missing
- Automatically invokes `tdd-orchestrator` to write tests first
- Enforces Red-Green-Refactor workflow

### 3. Automatic Quality Gates

**Quality checks run automatically.** After implementation, CCPM:

- Detects what changed (files, tools used)
- Invokes `code-reviewer` for all code changes
- Invokes `security-auditor` for security-critical changes
- Runs architecture review for significant changes
- Ensures nothing ships without validation

### 4. Spec Management with Linear Documents

**Spec-first development made easy:**

- Create Epics/Features with Linear Documents
- AI-assisted spec writing (requirements, architecture, API design, etc.)
- Spec validation and grading (A-F)
- Break down Epics → Features → Tasks automatically
- Sync spec with implementation reality
- Migrate existing `.claude/` specs to Linear

### 5. Interactive Workflow

**One continuous flow from idea to deployment:**

Every command shows:
- ✅ Current status and progress
- 💡 Smart next-action suggestions
- 🔗 One-click command chaining
- 🎯 Context-aware help

No more "what do I do next?"

---

## 📋 All Commands (27+ Total)

### Project Management (6 commands)

| Command | Description |
|---------|-------------|
| `/ccpm:project:add <project-id> [--template T]` | Add new project interactively |
| `/ccpm:project:list` | List all configured projects |
| `/ccpm:project:show <project-id>` | Show complete project configuration |
| `/ccpm:project:update <project-id> [--field F]` | Update project configuration |
| `/ccpm:project:delete <project-id> [--force]` | Delete project (with backup) |
| `/ccpm:project:set <project-id\|auto\|none>` | Set active project or enable auto-detection |

### Spec Management (6 commands)

| Command | Description |
|---------|-------------|
| `/pm:spec:create <type> "<title>" [parent]` | Create Epic/Feature with Linear Document |
| `/pm:spec:write <doc-id> <section>` | AI-assisted spec writing |
| `/pm:spec:review <doc-id>` | Spec validation & grading (A-F) |
| `/pm:spec:break-down <epic-or-feature-id>` | Epic→Features or Feature→Tasks |
| `/pm:spec:migrate <project-path>` | Migrate `.claude/` specs to Linear |
| `/pm:spec:sync <doc-id-or-issue-id>` | Sync spec with implementation |

### Planning (4 commands)

| Command | Description |
|---------|-------------|
| `/pm:planning:create "<title>" <project> [jira]` | Create + plan in one step |
| `/pm:planning:plan <issue-id> [jira]` | Populate existing issue with research |
| `/pm:planning:update <issue-id> "<request>"` | Update plan with interactive clarification |
| `/pm:planning:quick-plan "<desc>" <project>` | Quick planning (no external PM) |

### Implementation (3 commands)

| Command | Description |
|---------|-------------|
| `/pm:implementation:start <issue-id>` | Start with agent coordination |
| `/pm:implementation:next <issue-id>` | Smart next action detection |
| `/pm:implementation:update <issue-id> <idx> <status> "<msg>"` | Update subtask |

### Verification (3 commands)

| Command | Description |
|---------|-------------|
| `/pm:verification:check <issue-id>` | Run quality checks (IDE, lint, tests) |
| `/pm:verification:verify <issue-id>` | Final verification with agent |
| `/pm:verification:fix <issue-id>` | Fix verification failures |

### Completion (1 command)

| Command | Description |
|---------|-------------|
| `/pm:complete:finalize <issue-id>` | PR + Jira sync + Slack + cleanup |

### Utilities (10+ commands)

| Command | Description |
|---------|-------------|
| `/pm:utils:status <issue-id>` | Show detailed status |
| `/pm:utils:context <issue-id>` | Fast task context loading |
| `/pm:utils:report <project>` | Project-wide progress |
| `/pm:utils:insights <issue-id>` | AI complexity & risk analysis |
| `/pm:utils:auto-assign <issue-id>` | AI-powered agent assignment |
| `/pm:utils:sync-status <issue-id>` | Sync Linear→Jira |
| `/pm:utils:rollback <issue-id>` | Undo planning changes |
| `/pm:utils:dependencies <issue-id>` | Visualize dependencies |
| `/pm:utils:agents` | List all agents |
| `/pm:utils:help [issue-id]` | Context-aware help |

---

## 🔄 Workflows

### Spec-First Workflow (Recommended for new features)

```bash
# 1. Create Epic with spec
/pm:spec:create epic "User Authentication System"

# 2. Write comprehensive spec
/pm:spec:write DOC-123 all

# 3. Review and validate
/pm:spec:review DOC-123

# 4. Break down into tasks
/pm:spec:break-down WORK-100

# 5. Implement tasks
/pm:implementation:start WORK-101

# 6. Keep spec in sync
/pm:spec:sync DOC-123
```

### Task-First Workflow (For smaller tasks)

```bash
# 1. Create + plan in one step
/pm:planning:create "Add JWT auth" your-project JIRA-456

# 2. Start implementation (agent coordination automatic)
/pm:implementation:start WORK-123

# 3. Quality checks (TDD enforcer runs automatically)
/pm:verification:check WORK-123

# 4. Final verification (quality gates run automatically)
/pm:verification:verify WORK-123

# 5. Finalize (PR + Jira + Slack)
/pm:complete:finalize WORK-123
```

### Daily Routine

```bash
# Morning: Check project status
/pm:utils:report your-project

# Pick a task and load context
/pm:utils:context WORK-123

# Let interactive mode guide you!
```

---

## 🎯 Automatic Agent Invocation Examples

### Example 1: Backend Feature

**You type:** "Add user authentication"

**CCPM automatically:**
1. Detects: backend + security task
2. Discovers: 28 available agents
3. Scores agents:
   - `backend-architect`: 95
   - `security-auditor`: 90
   - `tdd-orchestrator`: 85
4. Plans sequential execution:
   - Step 1: backend-architect designs API
   - Step 2: tdd-orchestrator writes tests
   - Step 3: Implementation
   - Step 4: security-auditor + code-reviewer (parallel)
5. Invokes all agents automatically

**Result:** Complete feature with architecture, tests, implementation, security audit, and code review - all without you manually invoking a single agent.

### Example 2: Bug Fix

**You type:** "Fix the loading spinner bug"

**CCPM automatically:**
1. Detects: debugging task
2. Scores: `debugger`: 100
3. Invokes: `debugger` agent
4. After fix: Invokes `code-reviewer` (quality gate)

**Result:** Bug fixed with quality validation, automatically.

---

## 🔧 Configuration

### Enable/Disable Hooks

Hooks are enabled by default when you install the plugin. To disable specific hooks:

```json
// In your project's .claude/settings.json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "enabled": false  // Disable smart agent selection
      }
    ],
    "PreToolUse": [
      {
        "enabled": false  // Disable TDD enforcement
      }
    ]
  }
}
```

### Adjust Timeouts

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [{
        "timeout": 30000  // 30 seconds (default: 20s)
      }]
    }]
  }
}
```

### Project-Specific Agents

Create `.claude/agents/` in your project to add custom agents that CCPM will prioritize (+25 score bonus):

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

## 🔒 Safety Rules

**CCPM enforces strict safety rules to prevent accidental external system modifications.**

- ✅ **Read operations** - Freely gather from Jira/Confluence/BitBucket/Slack
- ⛔ **Write operations** - Require explicit user confirmation
- ✅ **Linear operations** - Permitted (internal tracking)

See [SAFETY_RULES.md](./commands/SAFETY_RULES.md) for complete details.

---

## 📦 Requirements

### Required MCP Servers

CCPM requires three MCP servers to function correctly. See [MCP_INTEGRATION_GUIDE.md](./MCP_INTEGRATION_GUIDE.md) for detailed setup instructions.

#### Linear MCP
- **Purpose:** Task tracking, spec management, and project organization
- **Installation:** `npx @lucitra/linear-mcp`
- **Setup:** Requires Linear API key from [linear.app/settings](https://linear.app/settings)
- **Used by:** All `/pm:*` commands, spec management, task tracking

#### GitHub MCP
- **Purpose:** PR creation, code hosting, repository operations
- **Installation:** Remote server (recommended) or `npm install -g @modelcontextprotocol/server-github`
- **Setup:** OAuth via VS Code or personal access token
- **Used by:** `/pm:complete:finalize`, PR workflows, CI/CD integration

#### Context7 MCP
- **Purpose:** Fetch latest library documentation into prompts
- **Installation:** `npx @upstash/context7-mcp`
- **Setup:** No API key required (free service by Upstash)
- **Usage:** Add "use context7" to prompts about libraries/frameworks
- **IMPORTANT:** Always use Context7 for library questions per global CLAUDE.md instructions

### Optional MCP Servers

These enhance CCPM capabilities but are not required:

- **Playwright** - Browser automation for PR checks and visual testing
- **Vercel** - Deployment integration and preview environment management
- **Shadcn** - UI component integration with shadcn/ui library

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

For complete MCP setup, configuration, and troubleshooting, see:
**[MCP Integration Guide](./MCP_INTEGRATION_GUIDE.md)** ← Comprehensive documentation

---

## 🧠 How Smart Agent Selection Works

### Phase 1: Discovery
```bash
~/.claude/plugins/ccpm/scripts/discover-agents.sh
```
Scans:
- Plugin agents from `~/.claude/plugins/*/agents/`
- Global built-in agents (general-purpose, Explore, Plan)
- Project agents from `.claude/agents/`

### Phase 2: Context Collection
- User message (what you asked)
- Tech stack (from package.json, requirements.txt)
- Recent files (git diff)
- Git branch
- Conversation history

### Phase 3: Intelligent Scoring
```javascript
Score =
  + 10: Each keyword match (user request vs agent description)
  + 20: Task type match (implementation, debugging, review)
  + 15: Tech stack match (React agent for React project)
  + 5:  Plugin agents (more specialized)
  + 25: Project-specific agents (HIGHEST PRIORITY)
```

### Phase 4: Execution Planning
- Sequential: Design → TDD → Implementation → Review
- Parallel: Frontend + Backend simultaneously
- Dependency handling

### Phase 5: Instruction Injection
Injects detailed instructions into Claude's context:
```
INVOKE backend-architect to design JWT auth:
- API endpoints: POST /signup, POST /login, GET /verify
- JWT strategy with refresh tokens
- Password hashing with bcrypt

Then INVOKE tdd-orchestrator to write tests:
- Test signup with valid/invalid inputs
- Test login success/failure
...
```

---

## 🐛 Troubleshooting

### Hooks Not Running

```bash
# 1. Check hook files exist
ls -la ~/.claude/plugins/ccpm/hooks/

# 2. Verify script permissions
chmod +x ~/.claude/plugins/ccpm/scripts/*.sh

# 3. Test discovery
~/.claude/plugins/ccpm/scripts/discover-agents.sh

# 4. Enable verbose logging
claude --verbose
```

### Wrong Agents Selected

```bash
# View scoring output
claude --verbose

# Check agent descriptions
~/.claude/plugins/ccpm/scripts/discover-agents.sh | jq '.[] | {name, description}'
```

### Performance Issues

Each hook adds ~2-5 seconds latency. To optimize:

1. Increase timeouts: `"timeout": 30000`
2. Disable hooks for simple tasks
3. The selector already skips simple questions

---

## 📚 Documentation

### User Guides
- **[Project Setup Guide](./docs/guides/project-setup.md)** - Complete guide to configuring and managing projects ⭐ NEW
- **[MCP Integration Guide](./MCP_INTEGRATION_GUIDE.md)** - Comprehensive MCP server setup and best practices
- [Installation Guide](./INSTALL_HOOKS.md) - Install CCPM with hooks
- [Installation Test Guide](./TEST_INSTALLATION.md) - Verify plugin installation

### Reference Documentation
- [Complete Command Reference](./commands/README.md) - All 27+ commands
- [Spec Management Guide](./commands/SPEC_MANAGEMENT_SUMMARY.md) - Spec-first development
- [Safety Rules](./commands/SAFETY_RULES.md) - External PM safety guidelines

### Architecture & Development
- [CLAUDE.md](./CLAUDE.md) - Project instructions for development
- [Dynamic Project Configuration](./docs/architecture/dynamic-project-configuration.md) - Architecture deep-dive ⭐ NEW
- [Documentation Hub](./docs/README.md) - Complete documentation index

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
- [Linear](https://linear.app) - Issue tracking
- [Context7](https://context7.com) - Documentation MCP

---

## 📞 Support

- Issues: [GitHub Issues](https://github.com/your-org/ccpm/issues)
- Author: [@duongdev](https://github.com/duongdev)
- Email: support@example.com

---

**CCPM - Transform your development workflow with intelligent automation.**

🚀 Get started: `/plugin install ccpm@your-marketplace`
