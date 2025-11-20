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

CCPM (Claude Code Project Management) is a comprehensive Claude Code plugin that provides:
- **Project management** with Linear integration
- **Smart agent auto-invocation** using context-aware scoring
- **TDD enforcement** through hooks
- **Quality gates** with automated code review
- **Spec management** with Linear Documents
- **Skills system** for installable capabilities
- **49+ commands** for complete project lifecycle management

## Repository Structure

```
ccpm/
├── .claude-plugin/          # Plugin manifest and marketplace config
│   ├── plugin.json          # Plugin metadata, features, requirements
│   └── marketplace.json     # Marketplace listing information
├── commands/                # All slash commands (49 total) - flat structure
│   ├── spec:*.md           # Spec management (6 commands)
│   ├── planning:*.md       # Planning commands (7 commands)
│   ├── implementation:*.md # Implementation commands (4 commands)
│   ├── verification:*.md   # Verification commands (3 commands)
│   ├── complete:*.md       # Completion commands (1 command)
│   └── utils:*.md          # Utility commands (13+ commands)
├── hooks/                  # Hook implementations for automation
│   ├── smart-agent-selector-optimized.prompt  # Optimized intelligent agent selection
│   ├── tdd-enforcer-optimized.prompt         # Optimized TDD enforcement
│   ├── quality-gate-optimized.prompt         # Optimized quality checks
│   └── agent-selector.prompt                  # Static agent selector (backup)
├── scripts/                # Shell scripts for automation
│   ├── discover-agents.sh           # Dynamically discovers all available agents
│   ├── discover-agents-cached.sh    # Cached version for performance
│   └── benchmark-hooks.sh           # Hook performance testing
├── skills/                 # Claude Code skills (installable capabilities)
│   ├── ccpm-code-review/   # Code review skill
│   ├── ccpm-debugging/     # Debugging skill
│   └── ...                 # Additional skills
└── agents/                 # Custom agents for CCPM development
```

**Note:** Commands use a **flat directory structure** with namespace prefixes in the filename (e.g., `spec:create.md` → `/ccpm:spec:create`). All commands require the `/ccpm:` prefix.

## Key Architectural Concepts

### 1. Hook-Based Automation System

CCPM uses Claude Code's hook system to automate agent invocation and quality enforcement. **Optimized** versions of hooks provide better performance:

**UserPromptSubmit Hook** (smart-agent-selector-optimized.prompt):
- Triggers on every user message
- Uses cached agent discovery for performance
- Scores agents 0-100+ based on context-aware algorithm
- Injects agent invocation instructions into Claude's context
- Plans execution (sequential vs parallel)

**PreToolUse Hook** (tdd-enforcer-optimized.prompt):
- Triggers before Write/Edit/NotebookEdit operations
- Checks if corresponding test files exist
- Blocks production code if tests are missing
- Automatically invokes `tdd-orchestrator` to write tests first
- Enforces Red-Green-Refactor workflow

**Stop Hook** (quality-gate-optimized.prompt):
- Triggers after task completion
- Detects what changed (files, tools used)
- Automatically invokes `code-reviewer` for all code changes
- Invokes `security-auditor` for security-critical changes
- Ensures quality validation happens automatically

### 2. Agent Discovery & Scoring Algorithm

The `discover-agents.sh` script scans three sources:
1. **Plugin agents**: From `~/.claude/plugins/*/agents/`
2. **Global agents**: Built-in Claude Code agents (general-purpose, Explore, Plan)
3. **Project agents**: From `.claude/agents/` (highest priority)

**Scoring formula:**
```javascript
Score =
  + 10 per keyword match (user request vs agent description)
  + 20 for task type match (implementation, debugging, review)
  + 15 for tech stack match (React agent for React project)
  + 5 for plugin agents (more specialized)
  + 25 for project-specific agents (HIGHEST PRIORITY)
```

**Execution Planning:**
- Sequential: Design → TDD → Implementation → Review
- Parallel: Independent agents run simultaneously
- Dependency-aware ordering

### 3. Command Structure & Interactive Mode

All commands follow a consistent pattern for interactive mode:

**Standard Command Flow:**
1. Execute command logic
2. Display current status and progress
3. Calculate completion percentage
4. Suggest intelligent next actions
5. Present interactive menu
6. Allow direct command chaining

**Command Categories:**
- **Spec Management** (6 commands): Epic/Feature creation, spec writing, review, breakdown, migration, sync
- **Planning** (7 commands): Task creation, planning, plan updating with interactive clarification, UI design, design approval, design refinement
- **Implementation** (4 commands): Start work, smart next action, subtask updates, sync
- **Verification** (3 commands): Quality checks, final verification, fix failures
- **Completion** (1 command): PR creation, Jira sync, Slack notifications
- **Utilities** (13+ commands): Status, context loading, reports, insights, dependencies, documentation organization, etc.

### 4. Safety Rules

Defined in `commands/SAFETY_RULES.md`, these rules are ABSOLUTE:

**⛔ NEVER write to external PM systems without explicit confirmation:**
- Jira (issues, comments, status changes)
- Confluence (pages, edits)
- BitBucket (pull requests, comments)
- Slack (messages, posts)

**✅ Always allowed:**
- Read operations from external systems (fetching, searching, viewing)
- Linear operations (internal tracking)
- Local file operations

**Confirmation workflow:**
1. Display what you intend to do
2. Show exact content to be posted/updated
3. Wait for explicit user confirmation
4. Only proceed after receiving "yes" or similar

### 5. Spec-First Development Pattern

CCPM promotes a spec-first workflow using Linear Documents:

1. **Create Epic/Feature** → `/ccpm:spec:create`
2. **Write Comprehensive Spec** → `/ccpm:spec:write` (all sections)
3. **Review & Validate** → `/ccpm:spec:review` (A-F grading)
4. **Break Down into Tasks** → `/ccpm:spec:break-down`
5. **Implement Tasks** → `/ccpm:implementation:start`
6. **Keep Spec in Sync** → `/ccpm:spec:sync` (detect drift)

**Spec sections:**
- Requirements
- Architecture
- API Design
- Data Model
- Testing Strategy
- Security Considerations
- User Flow
- Timeline

### 6. Skills System

CCPM provides a **skills** directory containing installable capabilities that extend Claude Code's functionality:

**Available Skills:**
- `ccpm-code-review/` - Enhanced code review workflows
- `ccpm-debugging/` - Structured debugging assistance
- `ccpm-mcp-management/` - MCP server management
- `ccpm-skill-creator/` - Create new skills
- `docs-seeker/` - Documentation search and retrieval
- `pm-workflow-guide/` - Project management workflows
- And more...

**Installing Skills:**
Skills can be installed globally or per-project using the Claude Code skills system. Each skill provides specialized prompts and workflows for specific tasks.

## Common Use Cases

### Updating an Existing Plan

When requirements change or clarification is needed during planning/implementation:

```bash
# User realizes they need to add email notifications
/ccpm:planning:update WORK-123 "Also add email notifications"

# User wants to change the technical approach
/ccpm:planning:update WORK-456 "Use Redis instead of in-memory cache"

# User needs to simplify the scope
/ccpm:planning:update WORK-789 "Remove admin dashboard, just add API"

# User encounters a blocker
/ccpm:planning:update WORK-321 "Library X doesn't support Node 20"
```

**What happens:**
1. Command fetches current plan from Linear
2. Analyzes the update request to detect change type
3. Asks targeted clarifying questions via AskUserQuestion
4. Gathers additional context (codebase, Context7, external PM)
5. Generates updated plan with impact analysis
6. Shows side-by-side comparison (kept, modified, added, removed)
7. Asks for confirmation before updating
8. Updates Linear with new plan and change history
9. Suggests next actions

**Key Features:**
- **Interactive Clarification**: Asks 1-4 smart questions based on request
- **Change Detection**: Identifies scope changes, approach changes, simplifications, blockers
- **Impact Analysis**: Shows complexity and timeline changes
- **Change Tracking**: Documents all updates in Linear comments
- **Progressive Refinement**: Can iterate if user selects "Needs Adjustment"

## Development Commands

### Testing the Plugin

```bash
# Test agent discovery
./scripts/discover-agents.sh | jq .

# Verify hook files
ls -la hooks/

# Check permissions
chmod +x scripts/*.sh
```

### Working with Commands

```bash
# Command files are markdown with frontmatter
# Structure:
# ---
# description: Brief command description
# ---
# # Command Name
# Implementation details...

# Add new command (flat structure with namespace prefix)
# File naming: commands/category:command-name.md
# Command invocation: /ccpm:category:command-name
cat > commands/planning:create.md  # Creates /ccpm:planning:create command
```

### Hook Development

```bash
# Hooks are in hooks/ directory
# Types:
# - .prompt files: For AI-based decision making
# - -optimized.prompt files: Performance-optimized versions (preferred)

# Test hook performance
./scripts/benchmark-hooks.sh

# Test hook in isolation (use optimized versions)
cat hooks/smart-agent-selector-optimized.prompt | \
  sed 's/{{userMessage}}/Add user auth/g' | \
  claude --stdin
```

## Important Conventions

### Command Naming

- Use namespace prefix: `/ccpm:category:command-name`
- Categories: spec, planning, implementation, verification, complete, utils
- Names should be verb-based: create, write, review, start, check
- Example: `/ccpm:planning:create`, `/ccpm:spec:write`, `/ccpm:utils:status`

### Interactive Mode Template

All commands should follow the interactive mode pattern:

1. Show status with emoji indicators (✅ ⏳ ❌ 🎯)
2. Calculate and display progress percentage
3. Detect optimal next actions based on status
4. Present numbered menu with ⭐ for recommended action
5. Allow command chaining

### Safety First

When implementing new commands:
1. **ALWAYS** check if operation writes to external systems
2. If yes, implement confirmation workflow
3. Show exact content before posting
4. Never assume user approval
5. Document safety considerations

### Agent Integration

When new agents are added to the ecosystem:
- They are automatically discovered by `discover-agents.sh`
- No code changes needed in CCPM
- Scoring algorithm applies automatically
- Project-specific agents get +25 priority bonus

### Progress and Documentation Standards

**Progress Tracking:**
- ⛔ NEVER write progress, status updates, or task notes to local markdown files
- ✅ ALWAYS use Linear ticket comments for all progress updates
- ✅ Update Linear issue fields (status, progress %, assignee, etc.)
- ✅ Use Linear comments for blockers, decisions, and status changes

**Documentation Creation:**
- ⛔ NEVER create new markdown files in root directory
- ✅ ALL documentation goes in `docs/` subdirectories
- ✅ Follow the docs/ structure: guides/, reference/, architecture/, development/, research/
- ✅ Update relevant index README.md files when adding docs

## Testing Practices

### Testing Agent Discovery

```bash
# Should output JSON array of all agents
./scripts/discover-agents.sh

# Should include:
# - Plugin agents (type: "plugin")
# - Global agents (type: "global")
# - Project agents (type: "project")
```

### Testing Command Execution

```bash
# Commands are invoked as slash commands
# Test format:
/ccpm:utils:help

# With arguments:
/ccpm:planning:create "Test task" test-project JIRA-123
```

### Testing Hooks

Hooks are tested by Claude Code's hook system:
1. Place prompt files in `hooks/`
2. Register in plugin.json under `hooks` section
3. Hooks trigger automatically on events

## Common Patterns

### Reading Linear Issues

```markdown
Use Linear MCP tools to fetch issue details:
- linear_get_issue - Get issue by ID
- linear_get_team - Get team details
- linear_get_project - Get project details
```

### Tracking Progress on Linear Tickets

```markdown
⛔ NEVER write progress updates to local markdown files
✅ ALWAYS comment on the Linear ticket instead

When tracking progress during task execution:
1. Use Linear MCP tools to add comments to the issue
2. Include status updates, blockers, and decisions
3. Keep the issue description up-to-date
4. Update custom fields (progress %, status, etc.)

Benefits:
- Single source of truth
- Visible to entire team
- Automatically timestamped
- Searchable history
- No git noise from progress updates
```

### Creating Linear Documents

```markdown
1. Create Linear Issue (Epic or Feature)
2. Create Linear Document
3. Link document to issue
4. Populate with template content
```

### Handling External PM Systems

```markdown
ALWAYS follow this pattern:

1. Fetch data from external system (Jira, Confluence, etc.)
2. Create/update Linear issue with gathered information
3. NEVER post back to external system without confirmation
4. If write needed:
   a. Show user exactly what will be posted
   b. Wait for explicit confirmation
   c. Only then execute write operation
```

### Agent Invocation in Commands

```markdown
When a command needs agent help:

1. Describe the task clearly
2. Use Task tool with appropriate subagent_type
3. Let smart-agent-selector choose the best agent
4. OR explicitly invoke specific agent if you know which one

Example:
Task(backend-architect): "Design REST API for user authentication..."
```

## Plugin Configuration

### plugin.json Structure

- `name`: Plugin identifier (ccpm)
- `version`: Semantic version (2.0.0)
- `components`: Maps component types to directories
  - commands: ./commands
  - agents: ./agents
  - hooks: ./hooks
  - scripts: ./scripts
- `features`: Lists all plugin capabilities
- `requirements.mcp_servers`: Required MCP servers (linear, github, context7)
- `safety`: Defines safety rules for external writes

### marketplace.json Structure

- Marketplace listing metadata
- Installation instructions
- Feature highlights
- Screenshots/demos

## Troubleshooting

### Hooks Not Running

1. Check `~/.claude/settings.json` for hook configuration
2. Verify script permissions: `chmod +x scripts/*.sh`
3. Test discovery script: `./scripts/discover-agents.sh`
4. Enable verbose mode: `claude --verbose`

### Wrong Agents Selected

1. Check agent descriptions in discovery output
2. Verify scoring weights in `hooks/smart-agent-selector-optimized.prompt`
3. Add project-specific agents for customization
4. Review verbose logs for scoring details

### Commands Not Found

1. Verify plugin installation: `/plugin list`
2. Check command files exist in `commands/`
3. Ensure proper markdown structure with frontmatter
4. Reload Claude Code

## Integration Points

### Required MCP Servers

- **Linear**: Task tracking, spec management, document creation
- **GitHub**: PR creation, code hosting, repository operations
- **Context7**: Latest library documentation fetching

### Optional MCP Servers

- **Playwright**: Browser automation for PR checks
- **Vercel**: Deployment integration
- **Shadcn**: UI component integration

## Best Practices for CCPM Development

1. **Hook Development**: Keep hooks fast (<5s) to avoid latency
2. **Command Documentation**: Use clear examples and interactive mode
3. **Safety First**: Always implement confirmation for external writes
4. **Test Discovery**: Ensure new agents are discoverable by script
5. **Scoring Tuning**: Adjust weights based on real-world usage
6. **Documentation**: Keep README.md, SAFETY_RULES.md, and command docs in sync
7. **Versioning**: Follow semantic versioning for plugin releases
8. **Progress Tracking**: NEVER write progress updates to local markdown files. Always comment on the Linear ticket instead.
9. **Documentation Structure**: ALL new documentation MUST follow the docs/ structure (guides/, reference/, architecture/, development/, research/)

## Documentation Structure

This repository follows the CCPM documentation pattern for clean, navigable, and scalable documentation.

### Pattern Overview

```
docs/
├── README.md               # Documentation navigation hub
├── guides/                 # 📘 User how-to guides
├── reference/              # 📖 API & feature reference
├── architecture/           # 🏗️ Design decisions & ADRs
├── development/            # 🔧 Contributor documentation
└── research/               # 📚 Historical context (archived)
```

### Documentation Guidelines

**⛔ CRITICAL: ALL new documentation MUST go in the `docs/` directory structure**
**⛔ NEVER create new markdown files in the root directory**

**When creating new documentation:**

1. **User guides** → `docs/guides/`
   - Installation, setup, configuration
   - Feature walkthroughs and tutorials
   - Troubleshooting guides
   - Use descriptive filenames: `installation.md`, `hooks-installation.md`

2. **Reference documentation** → `docs/reference/`
   - API documentation
   - Command/feature catalogs
   - Configuration references
   - Technical specifications

3. **Architecture documentation** → `docs/architecture/`
   - System architecture overviews
   - Component designs
   - Architecture Decision Records (ADRs)
   - Use descriptive names: `skills-system.md`, `documentation-structure.md`

4. **Development documentation** → `docs/development/`
   - Development environment setup
   - Testing guides
   - Release processes
   - Contribution workflows

5. **Research/Planning documents** → `docs/research/`
   - Historical planning documents
   - Research findings
   - Implementation journeys
   - Organized by topic: `skills/`, `hooks/`, `documentation/`, etc.
   - **Note**: These are archived - current docs go elsewhere

**⚠️ IMPORTANT: Progress tracking, status updates, and task notes should NEVER be written to any markdown files. Always use Linear ticket comments instead.**

### Root Directory Rules

**Keep ONLY these files in root:**
- `README.md` - Main entry point
- `CHANGELOG.md` - Version history
- `CONTRIBUTING.md` - Contribution guide
- `LICENSE` - License file
- `CLAUDE.md` - This file
- `MIGRATION.md` - Migration guide

**All other documentation goes in `docs/`**

### Index Files

Each documentation directory has a `README.md` that:
- Explains what the directory contains
- Links to all documents in that directory
- Provides navigation back to main docs

### Maintaining Documentation

**When you create or move documentation:**

1. Place it in the appropriate `docs/` subdirectory
2. Update the relevant index `README.md`
3. Update internal links to use correct relative paths
4. Keep root directory clean (≤5 markdown files)

**When you reference documentation:**

1. Use relative links from current location
2. Link to `docs/README.md` for main navigation
3. Link to specific guides/references as needed

### Auto-Organization

To reorganize documentation automatically:

```bash
/ccpm:utils:organize-docs [repo-path] [--dry-run] [--global]
```

This command:
- Analyzes current documentation structure
- Categorizes files using CCPM pattern rules
- Moves files to appropriate locations
- Creates index files
- Updates internal links
- Can be installed globally for use in any repository

### Navigation

All documentation is accessible from `docs/README.md`:
- **Quick Start**: `docs/guides/installation.md`
- **Full Documentation**: Browse by category in `docs/`
- **Contributing**: `CONTRIBUTING.md`

### Pattern Benefits

- ✅ Clean root directory
- ✅ Clear separation of concerns
- ✅ Easy to find documentation
- ✅ Scales with project growth
- ✅ Historical context preserved
- ✅ AI assistant friendly
- ✅ Consistent across projects

## Resources

- [Documentation Hub](./docs/README.md)
- [Installation Guide](./docs/guides/installation.md)
- [Complete Command Reference](./commands/README.md)
- [Safety Rules](./commands/SAFETY_RULES.md)
- [Spec Management Guide](./commands/SPEC_MANAGEMENT_SUMMARY.md)
- [Skills Catalog](./docs/reference/skills-catalog.md)
- [Hooks Implementation](./docs/research/hooks/implementation-summary.md)
- [Smart Agent Selection](./hooks/SMART_AGENT_SELECTION.md)
