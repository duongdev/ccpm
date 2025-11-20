# CCPM - Claude Code Project Management Plugin

**Comprehensive Project Management with Linear integration, smart agent auto-invocation, TDD enforcement, and quality gates.**

Version: 2.1.0
Author: Dustin Do ([@duongdev](https://github.com/duongdev))
License: MIT

> **🎉 NEW in v2.0**: Dynamic multi-project configuration! Manage all your projects from `~/.claude/ccpm-config.yaml`. See [Migration Guide](./MIGRATION.md) for details.
>
> **✨ NEW in v2.1**: Monorepo subdirectory support! Auto-detect subprojects in monorepos with pattern-based matching. Includes 4 new management commands and agent-based architecture for 80% token reduction!

---

## 🎯 What is CCPM?

CCPM is a comprehensive Claude Code plugin that transforms your development workflow by combining **2025 best practices** with intelligent automation:

- **Natural workflow commands** - 6 verb-based commands for your entire workflow (plan/work/sync/commit/verify/done)
- **53 total commands** - Complete project lifecycle management (6 primary + 47 advanced)
- **10 Agent Skills** with auto-activation based on context
- **Git integration** - Built-in conventional commits with Linear linking
- **Smart auto-detection** - Issue IDs from branches, modes from context
- **Workflow state detection** - Warns about uncommitted changes, stale syncs
- **Dynamic project configuration** - Multi-project support with auto-detection
- **Monorepo subdirectory support** - Auto-detect subprojects with pattern matching
- **Hook-based automation** - Smart agent selection, TDD enforcement, quality gates
- **Spec-first development** with Linear Documents and AI-assisted writing
- **Linear integration** for task tracking and project organization
- **Multi-system workflows** - Jira, Confluence, BitBucket, Slack integration
- **Safety-first design** - Confirmation required for external system writes
- **Interactive mode** for continuous workflow without context switching

**Built for 2025:**
- ⚡ **NEW**: Natural workflow commands - Learn 6 commands, master everything
- ✨ Agent Skills auto-activation (no manual invocation)
- ✨ Hook-driven workflow automation
- ✨ Spec-to-implementation pipeline
- ✨ Enterprise-grade multi-project support

## 🚀 Quick Start

### Installation

#### Option 1: From GitHub (Recommended)

```bash
# Add the CCPM marketplace from GitHub
/plugin marketplace add your-org/ccpm

# Install the CCPM plugin
/plugin install ccpm

# Verify installation
/ccpm:utils:help
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
/ccpm:utils:help
```

### Installation Verification

After installation, verify CCPM is working correctly:

#### 1. Check Plugin Installation

```bash
# List all installed plugins
/plugin list

# You should see: ccpm v2.1.0 (or latest version)
```

#### 2. Test Commands

```bash
# Test help command (should show CCPM commands)
/ccpm:utils:help

# Test project listing (should show empty or configured projects)
/ccpm:project:list

# Test cheatsheet (should display workflow guide)
/ccpm:utils:cheatsheet
```

#### 3. Verify MCP Server Connections

```bash
# Test Linear MCP (should list your Linear teams)
# In Claude Code prompt:
"List my Linear teams"

# Test GitHub MCP (should show your repositories)
"Show my GitHub repositories"

# Test Context7 MCP (should fetch React docs)
"use context7 to explain React hooks"
```

If any MCP servers fail, see [MCP Integration Guide](./docs/guides/features/mcp-integration.md) for detailed setup.

#### 4. Verify Hook Execution (Optional)

If you installed hooks:

```bash
# Check hook files exist
ls ~/.claude/plugins/ccpm/hooks/

# Test agent discovery
~/.claude/plugins/ccpm/scripts/discover-agents.sh

# Type a request to test auto-invocation
"Add user authentication"
# → Should automatically suggest relevant agents
```

**Expected Results:**
- ✅ Plugin shows in `/plugin list`
- ✅ Commands respond without "command not found" errors
- ✅ MCP servers return data (teams, repos, docs)
- ✅ Hooks suggest agents for complex requests

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

See [Hooks Setup Guide](./docs/guides/features/hooks-setup.md) for detailed instructions.

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

### Your First Workflow - Natural Commands

⚡ **Learn 6 commands, master your workflow:**

```bash
# 1. PLAN - Create and plan your task
/ccpm:plan "Add user authentication" my-app

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
- ✅ Git integration built-in (conventional commits)
- ✅ Auto-detects issue from branch name
- ✅ Smart suggestions after each command
- ✅ Workflow state warnings (uncommitted changes, etc.)

📚 **See full examples**: `/ccpm:utils:cheatsheet` or [Command Reference](./commands/README.md)

**Alternative: Classic commands still work**
```bash
# Classic workflow (47 commands available)
/ccpm:planning:create "Add user authentication" my-app JIRA-123
/ccpm:implementation:start WORK-123
# ... etc
```

---

## ✨ Key Features

### 1. Automatic Image Analysis

**Visual context for pixel-perfect implementation.** CCPM automatically detects and analyzes images in Linear issues:

- **Automatic Image Detection** - Detects UI mockups, architecture diagrams, and screenshots attached to Linear issues
- **Visual Context in Planning** - Analyzes images and includes findings in Linear descriptions
- **Pixel-Perfect UI Implementation** - Frontend/mobile agents receive mockups directly for ~95-100% design fidelity
- **Smart Prompt Selection** - Uses context-aware prompts for UI mockups, diagrams, screenshots
- **Direct Visual Reference** - Image URLs preserved for implementation phase
- **Graceful Error Handling** - Failed images do not block workflows


### 2. Dynamic Multi-Project Configuration

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

See [Project Setup Guide](./docs/guides/getting-started/project-setup.md) for complete documentation.

### 3. Monorepo Subdirectory Support (NEW!)

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

See [Monorepo Workflow Guide](./docs/guides/workflows/monorepo-workflow.md) for complete documentation.

### 4. Smart Agent Auto-Invocation

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

### 5. TDD Enforcement

**Write tests first, always.** CCPM blocks production code changes if tests don't exist:

- Hooks into Write/Edit/NotebookEdit operations
- Checks for corresponding test files
- **Blocks** execution if tests are missing
- Automatically invokes `tdd-orchestrator` to write tests first
- Enforces Red-Green-Refactor workflow

### 6. Automatic Quality Gates

**Quality checks run automatically.** After implementation, CCPM:

- Detects what changed (files, tools used)
- Invokes `code-reviewer` for all code changes
- Invokes `security-auditor` for security-critical changes
- Runs architecture review for significant changes
- Ensures nothing ships without validation

### 7. Spec Management with Linear Documents

**Spec-first development made easy:**

- Create Epics/Features with Linear Documents
- AI-assisted spec writing (requirements, architecture, API design, etc.)
- Spec validation and grading (A-F)
- Break down Epics → Features → Tasks automatically
- Sync spec with implementation reality
- Migrate existing `.claude/` specs to Linear

### 8. Interactive Workflow

**One continuous flow from idea to deployment:**

Every command shows:
- ✅ Current status and progress
- 💡 Smart next-action suggestions
- 🔗 One-click command chaining
- 🎯 Context-aware help

No more "what do I do next?"

---

## 📋 All Commands (45 Total)

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
| `/ccpm:spec:create <type> "<title>" [parent]` | Create Epic/Feature with Linear Document |
| `/ccpm:spec:write <doc-id> <section>` | AI-assisted spec writing |
| `/ccpm:spec:review <doc-id>` | Spec validation & grading (A-F) |
| `/ccpm:spec:break-down <epic-or-feature-id>` | Epic→Features or Feature→Tasks |
| `/ccpm:spec:migrate <project-path>` | Migrate `.claude/` specs to Linear |
| `/ccpm:spec:sync <doc-id-or-issue-id>` | Sync spec with implementation |

### Planning (4 commands)

| Command | Description |
|---------|-------------|
| `/ccpm:planning:create "<title>" <project> [jira]` | Create + plan in one step |
| `/ccpm:planning:plan <issue-id> [jira]` | Populate existing issue with research |
| `/ccpm:planning:update <issue-id> "<request>"` | Update plan with interactive clarification |
| `/ccpm:planning:quick-plan "<desc>" <project>` | Quick planning (no external PM) |

### Implementation (5 commands)

| Command | Description |
|---------|-------------|
| `/ccpm:implementation:start <issue-id>` | Start with agent coordination |
| `/ccpm:implementation:next <issue-id>` | Smart next action detection |
| `/ccpm:implementation:sync <issue-id> [summary]` | Sync progress to Linear |
| `/ccpm:implementation:update <issue-id> <idx> <status> "<msg>"` | Update subtask |

### Verification (3 commands)

| Command | Description |
|---------|-------------|
| `/ccpm:verification:check <issue-id>` | Run quality checks (IDE, lint, tests) |
| `/ccpm:verification:verify <issue-id>` | Final verification with agent |
| `/ccpm:verification:fix <issue-id>` | Fix verification failures |

### Completion (1 command)

| Command | Description |
|---------|-------------|
| `/ccpm:complete:finalize <issue-id>` | PR + Jira sync + Slack + cleanup |

### Utilities (16+ commands)

| Command | Description |
|---------|-------------|
| `/ccpm:utils:status <issue-id>` | Show detailed status |
| `/ccpm:utils:context <issue-id>` | Fast task context loading |
| `/ccpm:utils:report <project>` | Project-wide progress |
| `/ccpm:utils:search <project> <query>` | Search tasks by text |
| `/ccpm:utils:insights <issue-id>` | AI complexity & risk analysis |
| `/ccpm:utils:auto-assign <issue-id>` | AI-powered agent assignment |
| `/ccpm:utils:dependencies <issue-id>` | Visualize dependencies |
| `/ccpm:utils:sync-status <issue-id>` | Sync Linear→Jira |
| `/ccpm:utils:rollback <issue-id>` | Undo planning changes |
| `/ccpm:utils:agents` | List all agents |
| `/ccpm:utils:help [issue-id]` | Context-aware help |
| `/ccpm:utils:cheatsheet` | Visual workflow guide |
| `/ccpm:utils:organize-docs [path]` | Organize repository docs |

---

## 🔄 Workflows

### Spec-First Workflow (Recommended for new features)

```bash
# 1. Create Epic with spec
/ccpm:spec:create epic "User Authentication System"

# 2. Write comprehensive spec
/ccpm:spec:write DOC-123 all

# 3. Review and validate
/ccpm:spec:review DOC-123

# 4. Break down into tasks
/ccpm:spec:break-down WORK-100

# 5. Implement tasks
/ccpm:implementation:start WORK-101

# 6. Keep spec in sync
/ccpm:spec:sync DOC-123
```

### Task-First Workflow (For smaller tasks)

```bash
# 1. Create + plan in one step
/ccpm:planning:create "Add JWT auth" your-project JIRA-456

# 2. Start implementation (agent coordination automatic)
/ccpm:implementation:start WORK-123

# 3. Quality checks (TDD enforcer runs automatically)
/ccpm:verification:check WORK-123

# 4. Final verification (quality gates run automatically)
/ccpm:verification:verify WORK-123

# 5. Finalize (PR + Jira + Slack)
/ccpm:complete:finalize WORK-123
```

### Daily Routine

```bash
# Morning: Check project status
/ccpm:utils:report your-project

# Pick a task and load context
/ccpm:utils:context WORK-123

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

CCPM requires three MCP servers to function correctly. See [MCP Integration Guide](./docs/guides/features/mcp-integration.md) for detailed setup instructions.

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
**[MCP Integration Guide](./docs/guides/features/mcp-integration.md)** ← Comprehensive documentation

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

### Commands Not Found

**Symptoms:**
- `/ccpm:utils:help` returns "command not found"
- Commands don't appear in autocomplete

**Solutions:**

```bash
# 1. Verify plugin is installed
/plugin list
# Should show: ccpm v2.1.0

# 2. Reinstall plugin if missing
/plugin uninstall ccpm
/plugin install ccpm

# 3. Check command files exist
ls ~/.claude/plugins/ccpm/commands/*.md | wc -l
# Should show: 49 files

# 4. Reload Claude Code
# Restart your Claude Code session
```

### Hooks Not Running

**Symptoms:**
- Agents not automatically suggested
- TDD enforcement not blocking code changes
- No quality gates running after completion

**Solutions:**

```bash
# 1. Check hook files exist
ls -la ~/.claude/plugins/ccpm/hooks/
# Should show: smart-agent-selector.prompt, tdd-enforcer.prompt, quality-gate.prompt

# 2. Verify script permissions
chmod +x ~/.claude/plugins/ccpm/scripts/*.sh

# 3. Test agent discovery
~/.claude/plugins/ccpm/scripts/discover-agents.sh
# Should output JSON array of agents

# 4. Check hooks are enabled in settings
cat ~/.claude/settings.json | grep -A 10 "hooks"

# 5. Enable verbose logging
claude --verbose
# Then try a command to see hook execution logs
```

### MCP Server Connection Issues

**Symptoms:**
- Linear commands fail with "MCP server not found"
- GitHub operations timeout
- Context7 doesn't fetch documentation

**Solutions:**

```bash
# 1. Check MCP server configuration
cat ~/.claude/settings.json | grep -A 20 "mcpServers"

# 2. Test individual MCP servers
# Linear test:
echo "List my Linear teams" | claude

# GitHub test:
echo "Show my GitHub repos" | claude

# Context7 test:
echo "use context7 to explain React" | claude

# 3. Verify API keys are set
# Linear: Check LINEAR_API_KEY in settings.json
# GitHub: Check github-mcp is configured
# Context7: No API key needed

# 4. Restart MCP servers
# Kill existing sessions and restart Claude Code

# 5. See detailed MCP setup guide
# [MCP Integration Guide](./docs/guides/features/mcp-integration.md)
```

### Linear Integration Problems

**Symptoms:**
- "Team not found" errors
- Issues not creating in Linear
- Documents not linking to issues

**Solutions:**

```bash
# 1. Verify Linear API key
# Check ~/.claude/settings.json has LINEAR_API_KEY

# 2. Test Linear connection
"List my Linear teams"
# Should return your teams

# 3. Check project configuration
/ccpm:project:show your-project
# Verify linear.team and linear.project match Linear exactly

# 4. Verify Linear team/project exist
# Log into Linear web app
# Check team name matches config (case-sensitive)

# 5. Update project configuration
/ccpm:project:update your-project --field linear
# Enter correct team and project names
```

### Agent Auto-Activation Not Working

**Symptoms:**
- Agent Skills not auto-activating
- No agent suggestions for requests
- Skills must be manually invoked

**Solutions:**

```bash
# 1. Check agent discovery
~/.claude/plugins/ccpm/scripts/discover-agents.sh | jq .
# Should return array of 10+ agents/skills

# 2. Verify hook is running
claude --verbose
# Then make a request: "Add authentication"
# Check logs for "Smart Agent Selection" execution

# 3. Check scoring algorithm
~/.claude/plugins/ccpm/scripts/discover-agents.sh | \
  jq '.[] | {name, description, score}'

# 4. Test with explicit request
"I need help adding user authentication to my backend"
# Should trigger backend-related agents

# 5. Check project-specific agents
ls .claude/agents/
# Project agents get +25 priority bonus
```

### Wrong Agents Selected

**Symptoms:**
- Frontend agent invoked for backend tasks
- Generic agents chosen instead of specialized ones
- Too many agents activated

**Solutions:**

```bash
# 1. View scoring output with verbose mode
claude --verbose
# Check agent scores in logs

# 2. Inspect agent descriptions
~/.claude/plugins/ccpm/scripts/discover-agents.sh | \
  jq '.[] | {name, description}'

# 3. Add project-specific agents for customization
mkdir -p .claude/agents
# Create agents matching your tech stack
# They get +25 priority bonus

# 4. Review scoring weights
cat ~/.claude/plugins/ccpm/hooks/smart-agent-selector.prompt
# Keyword match: +10, Task type: +20, Tech stack: +15, etc.

# 5. Provide more context in requests
# Instead of: "Add auth"
# Try: "Add JWT authentication to the Express.js backend"
```

### Performance Issues

**Symptoms:**
- Commands take 10+ seconds to respond
- Hook execution feels slow
- Timeouts on complex requests

**Solutions:**

```bash
# 1. Increase hook timeouts
# Edit ~/.claude/settings.json:
{
  "hooks": {
    "UserPromptSubmit": [{
      "timeout": 30000  // Increase from 20s to 30s
    }]
  }
}

# 2. Disable hooks for simple tasks
# Hooks already skip simple questions
# But you can manually disable:
{
  "hooks": {
    "UserPromptSubmit": [{ "enabled": false }]
  }
}

# 3. Optimize agent discovery
# The discover-agents.sh script is already optimized
# But ensure no circular symlinks in plugins:
find ~/.claude/plugins -type l

# 4. Use command chaining instead of multiple calls
/ccpm:planning:create "Task" project JIRA-123
# Instead of: /ccpm:planning:create + /ccpm:planning:plan

# 5. Monitor execution with verbose mode
claude --verbose
# Identify slow operations
```

### Configuration Issues

**Symptoms:**
- Project detection not working
- Auto-detection switching to wrong project
- Subproject not detected in monorepo

**Solutions:**

```bash
# 1. Check config file syntax
cat ~/.claude/ccpm-config.yaml
# Ensure valid YAML (indentation, colons, dashes)

# 2. Validate project configuration
/ccpm:project:show your-project
# Check all fields are populated correctly

# 3. Test auto-detection
cd /path/to/your/project
/ccpm:project:set auto
/ccpm:project:list
# Should show active project with ⭐

# 4. Debug subdirectory detection
/ccpm:project:subdir:list your-monorepo
# Verify match_pattern covers your directory

# 5. Use explicit project instead of auto
/ccpm:project:set your-project
# Or pass project explicitly to commands
```

### Getting Help

If issues persist:

1. **Enable verbose logging**: `claude --verbose`
2. **Check logs**: Look for error messages in output
3. **Review documentation**: [Documentation Hub](./docs/README.md)
4. **Report issues**: [GitHub Issues](https://github.com/duongdev/ccpm/issues)
5. **Contact support**: Include verbose logs and config (remove sensitive data)

---

## 🆚 How CCPM Compares

### CCPM vs Traditional Linear Workflow

| Feature | Traditional Linear | CCPM with Linear |
|---------|-------------------|------------------|
| **Task Creation** | Manual issue creation in web UI | `/ccpm:planning:create` with auto-research |
| **Planning** | Write description by hand | AI-powered planning with Jira/Confluence context |
| **Spec Management** | Separate docs or no specs | Integrated Linear Documents with AI writing |
| **Agent Selection** | Manual skill invocation | Auto-selects best agents (10+ available) |
| **Testing** | Manual test writing | TDD enforcement blocks code without tests |
| **Code Review** | Manual request | Auto-invokes reviewer after changes |
| **Workflow** | Context switching to web | 45 commands, all in CLI |
| **Progress Tracking** | Manual status updates | Auto-sync from implementation |
| **Monorepo Support** | Manual labels | Auto-detects subproject context |

**Result:** CCPM saves 60-70% of PM overhead while improving quality.

### CCPM vs Jira-Only Workflow

| Feature | Jira-Only | CCPM Multi-System |
|---------|-----------|-------------------|
| **Issue Tracking** | Jira only | Linear (primary) + Jira (sync) |
| **Specs** | Confluence (separate) | Linear Documents (integrated) |
| **Code** | BitBucket (separate) | GitHub + Linear integration |
| **Communication** | Slack + Jira comments | Unified with auto-notifications |
| **Context Gathering** | Manual search across systems | Auto-fetches from all systems |
| **Status Sync** | Manual dual-entry | One-way sync with confirmation |
| **Developer Experience** | 4 separate web UIs | Single CLI interface |
| **Safety** | Easy to accidentally modify | Write confirmation required |

**Result:** CCPM unifies fragmented workflows while maintaining data in each system.

### CCPM vs Other Claude Code PM Plugins

| Feature | Basic PM Plugins | CCPM |
|---------|-----------------|------|
| **Commands** | 5-10 commands | 45 commands |
| **Agent Skills** | 0-2 skills | 10 auto-activating skills |
| **Automation** | Manual invocation | Hooks for auto-invocation, TDD, quality gates |
| **Multi-Project** | Single project | Unlimited projects with auto-detection |
| **Monorepo** | Not supported | Subdirectory detection with patterns |
| **External PM** | Limited or none | Jira, Confluence, BitBucket, Slack |
| **Spec Management** | Not included | Full spec lifecycle with AI assistance |
| **Interactive Mode** | Basic | Smart next-action with command chaining |
| **Safety Rules** | Ad-hoc | Enforced confirmation for external writes |
| **Documentation** | Basic README | 20+ docs with guides, architecture, references |

**Result:** CCPM is enterprise-grade with 2025 best practices built-in.

### Why Choose CCPM?

**Choose CCPM if you:**
- ✅ Work with Linear and need deeper integration
- ✅ Use multiple PM systems (Linear + Jira + Confluence + etc.)
- ✅ Want TDD enforcement and automatic quality gates
- ✅ Need spec-first development with AI assistance
- ✅ Maintain monorepos with multiple subprojects
- ✅ Want 10+ agent skills auto-activating based on context
- ✅ Prefer comprehensive CLI over web UI context switching
- ✅ Need enterprise-grade safety for multi-system workflows

**Consider alternatives if you:**
- ❌ Only use Linear web UI (no CLI preference)
- ❌ Have simple single-project workflows
- ❌ Don't need external PM system integration
- ❌ Prefer minimal tooling over comprehensive features

---

## 📚 Documentation

### User Guides
- **[Project Setup Guide](./docs/guides/getting-started/project-setup.md)** - Complete guide to configuring and managing projects
- **[MCP Integration Guide](./docs/guides/features/mcp-integration.md)** - Comprehensive MCP server setup and best practices
- **[Installation Guide](./docs/guides/getting-started/installation.md)** - Install CCPM with all features
- **[Hooks Setup Guide](./docs/guides/features/hooks-setup.md)** - Enable automation with hooks

### Reference Documentation
- [Complete Command Reference](./commands/README.md) - All 27+ commands
- [Spec Management Guide](./commands/SPEC_MANAGEMENT_SUMMARY.md) - Spec-first development
- [Safety Rules](./commands/SAFETY_RULES.md) - External PM safety guidelines

### Architecture & Development
- [CLAUDE.md](./CLAUDE.md) - Project instructions for development
- [Dynamic Project Configuration](./docs/architecture/patterns/dynamic-configuration.md) - Architecture deep-dive
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
