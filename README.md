# CCPM - Claude Code Project Management Plugin

**Comprehensive Project Management with Linear integration, smart agent auto-invocation, TDD enforcement, and quality gates.**

Version: 2.0.0
Author: Dustin Duong ([@duongdev](https://github.com/duongdev))
License: MIT

---

## 🎯 What is CCPM?

CCPM is a comprehensive Claude Code plugin that transforms your development workflow by combining:

- **16+ PM commands** for complete project lifecycle management
- **Smart agent auto-invocation** with context-aware scoring (0-100+)
- **TDD enforcement** that blocks production code without tests
- **Automatic quality gates** with code review and security audits
- **Linear integration** for spec management and task tracking
- **External PM tools** (Jira, Confluence, BitBucket, Slack)
- **Interactive mode** for continuous workflow without context switching

## 🚀 Quick Start

### Installation

```bash
# Add the CCPM plugin marketplace
/plugin marketplace add duongdev/ccpm

# Install the CCPM plugin
/plugin install ccpm@duongdev

# Verify installation
/pm:utils:help
```

### First Steps

```bash
# Create your first task with full planning
/pm:planning:create "Add user authentication" your-project JIRA-123

# Or start with a spec-first approach
/pm:spec:create epic "User Management System"

# Follow the interactive prompts - CCPM will guide you!
```

---

## ✨ Key Features

### 1. Smart Agent Auto-Invocation

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

## 📋 All Commands (16 Total)

### Spec Management (6 commands)

| Command | Description |
|---------|-------------|
| `/pm:spec:create <type> "<title>" [parent]` | Create Epic/Feature with Linear Document |
| `/pm:spec:write <doc-id> <section>` | AI-assisted spec writing |
| `/pm:spec:review <doc-id>` | Spec validation & grading (A-F) |
| `/pm:spec:break-down <epic-or-feature-id>` | Epic→Features or Feature→Tasks |
| `/pm:spec:migrate <project-path>` | Migrate `.claude/` specs to Linear |
| `/pm:spec:sync <doc-id-or-issue-id>` | Sync spec with implementation |

### Planning (3 commands)

| Command | Description |
|---------|-------------|
| `/pm:planning:create "<title>" <project> [jira]` | Create + plan in one step |
| `/pm:planning:plan <issue-id> [jira]` | Populate existing issue with research |
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

- **Linear** - Task tracking and spec management
- **GitHub** - PR creation and code hosting
- **Context7** - Latest library documentation

### Optional MCP Servers

- **Playwright** - Browser automation for PR checks
- **Vercel** - Deployment integration
- **Shadcn** - UI component integration

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

- [Complete Command Reference](./commands/README.md)
- [Spec Management Guide](./commands/SPEC_MANAGEMENT_SUMMARY.md)
- [Safety Rules](./commands/SAFETY_RULES.md)
- [Hooks Implementation](./hooks/README.md) (coming soon)
- [Smart Agent Selection](./hooks/SMART_AGENT_SELECTION.md) (coming soon)

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

- Issues: [GitHub Issues](https://github.com/duongdev/ccpm/issues)
- Author: [@duongdev](https://github.com/duongdev)
- Email: me@dustin.tv

---

**CCPM - Transform your development workflow with intelligent automation.**

🚀 Get started: `/plugin install ccpm@duongdev`
