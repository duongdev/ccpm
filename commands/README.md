# PM Commands 2.0 - Interactive Mode

Project Management commands with **Interactive Mode** for seamless workflow automation across Jira, Confluence, BitBucket, Slack, and Linear.

## 🚨 Critical Safety Notice

**All PM commands enforce strict safety rules to prevent accidental external system modifications.**

Read: [SAFETY_RULES.md](./SAFETY_RULES.md)

- ✅ **Read operations** - Freely gather from Jira/Confluence/BitBucket/Slack
- ⛔ **Write operations** - Require explicit user confirmation (even in bypass mode)
- ✅ **Linear operations** - Permitted (internal tracking)

## 🎯 What's New in 2.0

### Interactive Mode

**Every command now:**
- ✅ Shows current status after execution
- ✅ Calculates and displays progress
- ✅ Suggests intelligent next actions
- ✅ Asks what you want to do next
- ✅ Can chain directly to next command

**No more context switching!** Complete workflows in one continuous session.

### New Commands (16 Total in v2.0)

**Spec Management (6 new):**
1. `/pm:spec:create` - Create Epic/Feature with Linear Document
2. `/pm:spec:write` - AI-assisted spec writing
3. `/pm:spec:review` - Spec validation & grading
4. `/pm:spec:break-down` - Epic→Features, Feature→Tasks
5. `/pm:spec:migrate` - Migrate `.claude/` specs to Linear
6. `/pm:spec:sync` - Sync spec with implementation

**Workflow Enhancements (10 new):**
7. `/pm:planning:create` - Create + plan in one step
8. `/pm:utils:report` - Project-wide progress reporting
9. `/pm:utils:context` - Fast task context loading
10. `/pm:implementation:next` - Smart next action detection
11. `/pm:complete:finalize` - Post-completion workflow
12. `/pm:utils:sync-status` - Jira sync with confirmation
13. `/pm:utils:auto-assign` - AI-powered agent assignment
14. `/pm:utils:rollback` - Undo planning changes
15. `/pm:utils:dependencies` - Visualize task dependencies
16. `/pm:utils:insights` - AI complexity & risk analysis

## 📋 Complete Command Reference

### Spec Management Commands 🆕

#### `/pm:spec:create <type> "<title>" [parent-id]`

**Create Epic/Feature/Initiative with Linear Document for comprehensive spec management.**

**Types:**
- `epic` or `initiative` - High-level project/feature group
- `feature` - Specific feature (can belong to an epic)

**What it does:**
- Creates Epic (Initiative) or Feature (Parent Issue) in Linear
- Creates associated Linear Document for spec/design
- Links document to issue
- Populates with appropriate template

```bash
# Create Epic with spec document
/pm:spec:create epic "User Authentication System"

# Create Feature under an epic
/pm:spec:create feature "JWT Auth" WORK-100
```

#### `/pm:spec:write <doc-id> <section>`

**AI-assisted spec document writing with codebase analysis.**

**Sections:** `requirements`, `architecture`, `api-design`, `data-model`, `testing`, `security`, `user-flow`, `timeline`, `all`

**What it does:**
- Analyzes existing codebase for patterns
- Fetches library documentation (Context7)
- Generates detailed, specific content
- Follows project conventions

```bash
# Write specific section
/pm:spec:write DOC-123 requirements

# Write API design with examples
/pm:spec:write DOC-123 api-design

# Write all sections at once
/pm:spec:write DOC-123 all
```

#### `/pm:spec:review <doc-id>`

**AI-powered spec review for completeness and quality.**

**What it does:**
- Analyzes completeness (required vs optional sections)
- Validates content quality (specificity, testability)
- Identifies risks and gaps
- Grades spec (A-F) with detailed feedback
- Suggests improvements

```bash
/pm:spec:review DOC-123
```

**Output:**
- Completeness score (0-100%)
- Quality assessment
- Risk identification
- Actionable recommendations
- Best practices checklist

#### `/pm:spec:break-down <epic-or-feature-id>`

**Break down Epic into Features or Feature into Tasks based on spec.**

**What it does:**
- Parses spec document for breakdown items
- Generates Features (from Epic) or Tasks (from Feature)
- Creates Linear issues with proper hierarchy
- Links back to spec
- Detects dependencies

```bash
# Break Epic into Features
/pm:spec:break-down WORK-100

# Break Feature into Tasks
/pm:spec:break-down WORK-101
```

**Features:**
- Auto-extracts from "Features Breakdown" or "Task Breakdown" sections
- AI suggests missing items
- Preserves dependencies
- Maps priorities (P0=Urgent, P1=High, etc.)
- Converts estimates to Linear points

#### `/pm:spec:migrate <project-path> [category]`

**Migrate existing markdown specs from `.claude/` to Linear Documents.**

**Categories:** `docs`, `plans`, `enhancements`, `tasks`, `all` (default)

**What it does:**
- Scans `.claude/` directory for markdown files
- Categorizes files (Epic, Feature, Task, Documentation)
- Creates Linear Issues + Documents
- Preserves content and metadata
- Moves originals to `.claude/migrated/`

```bash
# Migrate from current directory (most common)
/pm:spec:migrate .

# Migrate from specific project path
/pm:spec:migrate ~/personal/nv-internal

# Migrate only specific category (skip selection)
/pm:spec:migrate . enhancements
```

**Interactive Selection:**
- Select which categories to migrate (Epics, Features, Tasks, Docs)
- Shows file counts for each category
- Can select multiple categories
- Full preview before confirming

**Migration Process:**
1. Discovers and categorizes all `.md` files
2. Shows preview with file counts
3. Asks for confirmation
4. Creates Linear entities with documents
5. Extracts checklists → sub-tasks
6. Moves originals to `.claude/migrated/`
7. Creates breadcrumb files with Linear links

**Safe Migration:**
- Original files NOT deleted (moved to `.claude/migrated/`)
- Full content preserved in Linear Documents
- Breadcrumb files created for reference
- Can rollback from `.claude/migrated/` if needed

#### `/pm:spec:sync <doc-id-or-issue-id>`

**Sync spec document with implementation reality.**

**What it does:**
- Compares spec with actual implementation
- Detects drift in requirements, API, data model, tasks
- Searches codebase for implemented code
- Generates detailed drift report
- Offers to update spec or create implementation tasks

```bash
/pm:spec:sync DOC-123
# or
/pm:spec:sync WORK-123
```

**Drift Detection:**
- **Requirements**: Missing, extra, or changed features
- **API Design**: Endpoint signatures, new/missing endpoints
- **Data Model**: Schema changes, field modifications
- **Tasks**: Status mismatches between spec and Linear

**Sync Options:**
- Update spec to match reality (recommended)
- Update implementation to match spec
- Hybrid approach (choose per item)
- Review only

### Planning Commands

#### `/pm:planning:create "<title>" <project> [jira-ticket-id]` 🆕

**Create Linear issue + run full planning in one step.**

- No manual Linear UI needed
- Automatically populates with research
- Interactive next action prompts

```bash
/pm:planning:create "Add JWT authentication" trainer-guru TRAIN-456
```

#### `/pm:planning:plan <linear-issue-id> [jira-ticket-id]`

**Populate existing Linear issue with comprehensive research.**

- Checklist at top
- All links properly formatted
- Supports with/without Jira

```bash
/pm:planning:plan WORK-123 TRAIN-456
```

#### `/pm:planning:quick-plan "<description>" <project>`

**Quick planning for NV Internal (no external PM).**

```bash
/pm:planning:quick-plan "Add dark mode" nv-internal
```

### Implementation Commands

#### `/pm:implementation:start <linear-issue-id>`

**Start implementation with agent coordination.**

- Lists available agents
- Creates assignment plan
- Begins execution

```bash
/pm:implementation:start WORK-123
```

#### `/pm:implementation:next <linear-issue-id>` 🆕

**Smart next action detection based on status & dependencies.**

- Respects task dependencies
- Suggests optimal next step
- One-click execution

```bash
/pm:implementation:next WORK-123
```

#### `/pm:implementation:update <linear-issue-id> <idx> <status> "<msg>"`

**Update subtask progress.**

```bash
/pm:implementation:update WORK-123 0 completed "Added auth endpoints"
```

### Verification Commands

#### `/pm:verification:check <linear-issue-id>`

**Run quality checks before verification.**

- IDE warnings/errors
- Linting (auto-fix)
- Test execution
- Updates to Verification status if all pass

```bash
/pm:verification:check WORK-123
```

#### `/pm:verification:verify <linear-issue-id>`

**Final verification with verification-agent.**

- Comprehensive review
- Regression checks
- Marks as Done if passes

```bash
/pm:verification:verify WORK-123
```

#### `/pm:verification:fix <linear-issue-id>`

**Fix verification failures with agent coordination.**

- Analyzes failures
- Maps to agents
- Parallel fixes

```bash
/pm:verification:fix WORK-123
```

### Completion Commands

#### `/pm:complete:finalize <linear-issue-id>` 🆕

**Post-completion workflow with confirmations.**

- Create PR (optional)
- Sync Jira status (with confirmation)
- Notify Slack (with confirmation)
- Archive and clean up

```bash
/pm:complete:finalize WORK-123
```

### Utility Commands

#### `/pm:utils:status <linear-issue-id>`

**Show detailed task status with next actions.**

```bash
/pm:utils:status WORK-123
```

#### `/pm:utils:context <linear-issue-id>` 🆕

**Load full task context for quick resume.**

- Fetches issue details
- Loads relevant files
- Shows progress
- Suggests next actions

```bash
/pm:utils:context WORK-123
```

#### `/pm:utils:report <project>` 🆕

**Project-wide progress report.**

- All active tasks
- Blocked items highlighted
- Velocity metrics
- Interactive next actions

```bash
/pm:utils:report trainer-guru
```

#### `/pm:utils:insights <linear-issue-id>` 🆕

**AI-powered complexity & risk analysis.**

- Complexity scoring (1-10)
- Risk identification
- Timeline estimation
- Optimization recommendations

```bash
/pm:utils:insights WORK-123
```

#### `/pm:utils:auto-assign <linear-issue-id>` 🆕

**AI-powered agent assignment.**

- Analyzes each subtask
- Suggests optimal agent
- Detects parallelization opportunities
- Creates execution plan

```bash
/pm:utils:auto-assign WORK-123
```

#### `/pm:utils:sync-status <linear-issue-id>` 🆕

**Sync Linear status to Jira (with confirmation).**

- Shows preview
- Asks confirmation
- Updates Jira

```bash
/pm:utils:sync-status WORK-123
```

#### `/pm:utils:rollback <linear-issue-id>` 🆕

**Rollback planning to previous version.**

- Shows history
- Preview before rollback
- Confirmation required

```bash
/pm:utils:rollback WORK-123
```

#### `/pm:utils:dependencies <linear-issue-id>` 🆕

**Visualize subtask dependencies.**

- ASCII dependency graph
- Shows ready vs blocked
- Execution order

```bash
/pm:utils:dependencies WORK-123
```

#### `/pm:utils:agents`

**List all available subagents.**

```bash
/pm:utils:agents
```

#### `/pm:utils:help [issue-id]` 🆕

**Context-aware help and command suggestions.**

**What it does:**
- Shows categorized command reference
- Suggests relevant commands based on current status
- Provides workflow guidance
- Interactive quick actions

```bash
# General help
/pm:utils:help

# Context-aware help with suggestions
/pm:utils:help WORK-123
```

**Features:**
- Detects issue status and suggests next actions
- Shows all available commands by category
- Workflow quick reference
- Interactive action menu

## 🔄 Interactive Workflow Example

```bash
# 1. Create & Plan
/pm:planning:create "Add JWT auth" trainer-guru TRAIN-456

📋 Issue Created: WORK-123
✅ Planning Complete!

💡 What would you like to do next?
  1. Start Implementation ⭐
  2. Get AI Insights
  3. Auto-Assign Agents
  4. Just Review

→ [You select: 1. Start Implementation]

# 2. Implementation Starts Automatically
📝 Assignment Plan Created
🤖 3 agents assigned

💡 Which subtask first?
  1. Auto-select (AI) ⭐
  2. Subtask 1: Database schema
  3. View All

→ [You select: 1. Auto-select]

# 3. Work Continues...
[Agent completes subtask 1]

✅ Subtask 1 Complete!
🎯 Progress: 1/5 (20%)

💡 Next action?
  1. Continue Next Task ⭐
  2. Run Quality Checks
  3. Update Status

→ [Continuous workflow...]

# 4. All Done
✅ All Subtasks Complete!

💡 Ready for quality checks?
  1. Run Checks ⭐
  2. Review First

→ [You select: 1]

# 5. Verification
✅ Quality Checks Passed!

💡 Run final verification?
  1. Verify Now ⭐
  2. Additional Tests

→ [You select: 1]

# 6. Finalize
🎉 Verification Passed!

💡 Finalize this task?
  1. Finalize (PR + Jira + Slack) ⭐
  2. Just PR
  3. Keep Open

→ [One continuous flow from start to finish!]
```

## 🎯 Best Practices

### Spec-First Workflow (Recommended for NV Internal)

**For new features or major projects:**

1. **Create Epic/Feature with Spec** → `/pm:spec:create`
2. **Write Comprehensive Spec** → `/pm:spec:write` (all sections)
3. **Review & Validate** → `/pm:spec:review`
4. **Break Down into Tasks** → `/pm:spec:break-down`
5. **Implement Tasks** → `/pm:implementation:start`
6. **Keep Spec in Sync** → `/pm:spec:sync` (periodically)

**Benefits:**
- Clear requirements before coding
- Better estimates and planning
- Easier onboarding and handoffs
- Documentation-first approach
- Reduce scope creep

### Task-First Workflow (For smaller tasks)

1. **Start with `/pm:planning:create`** - One command to create + plan
2. **Use `/pm:utils:context`** when resuming work
3. **Run `/pm:implementation:next`** when unsure what's next
4. **Check `/pm:utils:report`** daily for project overview
5. **Get `/pm:utils:insights`** early for complex tasks
6. **Always `/pm:verification:check`** before `/pm:verification:verify`
7. **Trust interactive prompts** - They know the workflow
8. **Let it flow** - Each command suggests the next

### Migrating Existing Specs

**If you have existing markdown specs in `.claude/`:**

1. **Run Migration** → `/pm:spec:migrate ~/personal/nv-internal`
2. **Review in Linear** - Check migrated items
3. **Organize Hierarchy** - Link features to epics
4. **Continue with Spec Workflow** - Use spec commands going forward

## 📊 Command Workflow Map

### Spec-First Workflow

```
Create Epic/Feature (/pm:spec:create)
  ↓
Write Spec (/pm:spec:write)
  ↓
Review Spec (/pm:spec:review)
  ↓
Break Down (/pm:spec:break-down) → Creates Tasks
  ↓
[Continue with Task-First Workflow below]
```

### Task-First Workflow

```
Create Task (/pm:planning:create)
  ↓
Planning Complete → Suggest: Start/Insights/Auto-Assign
  ↓
Start Implementation (/pm:implementation:start)
  ↓
Work on Subtasks → Auto-suggest next (/pm:implementation:next)
  ↓
All Complete → Suggest: Quality Checks
  ↓
Quality Checks (/pm:verification:check)
  ↓
Checks Pass → Suggest: Verification
  ↓
Verification (/pm:verification:verify)
  ↓
Passes → Suggest: Finalize
  ↓
Finalize (/pm:complete:finalize)
  ↓
Done → Suggest: New Task/Report

[At any point]:
- /pm:utils:context - Resume quickly
- /pm:utils:status - Check status
- /pm:utils:report - Project overview
- /pm:utils:insights - Get AI analysis
- /pm:spec:sync - Keep spec in sync with reality
```

## 🚀 Quick Start

### First Time

```bash
# Day 1: Create your first task
/pm:planning:create "Your task title" your-project JIRA-123

# Follow interactive prompts - it will guide you through everything!
```

### Daily Routine

```bash
# Morning: Check project status
/pm:utils:report your-project

# Pick a task and load context
/pm:utils:context WORK-123

# Let interactive mode guide you from there!
```

### When Stuck

```bash
# What should I do next?
/pm:implementation:next WORK-123

# What's the full picture?
/pm:utils:context WORK-123

# How complex is this really?
/pm:utils:insights WORK-123
```

### Project-Specific Commands

#### `/pm:repeat:check-pr <pr-number-or-url>` 🆕

**Comprehensive BitBucket PR analysis for Repeat project.**

**What it does:**
- Browser MCP selection (Playwright or Browser MCP)
- Authentication pause for manual sign-in
- Build status analysis with fix suggestions
- SonarQube quality gate review
- Code quality assessment
- Test coverage analysis
- Security vulnerability detection
- Jira ticket integration (read-only)
- Interactive fix workflow
- Export detailed reports

```bash
# Check PR by number
/pm:repeat:check-pr 123

# Check PR by full URL
/pm:repeat:check-pr https://bitbucket.org/repeat-dev/repeat-mobile-app/pull-requests/456
```

**Features:**
- ✅ Flexible browser MCP choice
- 🔐 Manual authentication support (pauses for sign-in)
- ⛔ Never mutates BitBucket/SonarQube without explicit approval
- 📊 Comprehensive quality analysis
- 💡 Actionable fix suggestions with code examples
- 📝 Draft PR comments for review before posting
- 📄 Export analysis to markdown
- 🎯 Interactive next-action workflow

**Safety:**
- All write operations require explicit confirmation
- Shows exact content before posting anything
- Respects SAFETY_RULES.md throughout

## 📁 Directory Structure

```
/Users/duongdev/.claude/commands/pm/
├── README.md (this file)
├── SAFETY_RULES.md
├── spec/ (NEW - Spec Management)
│   ├── create.md - Create Epic/Feature with spec doc
│   ├── write.md - AI-assisted spec writing
│   ├── review.md - Spec validation & grading
│   ├── break-down.md - Epic→Features, Feature→Tasks
│   ├── migrate.md - Migrate .claude/ specs to Linear
│   └── sync.md - Sync spec with implementation
├── planning/
│   ├── create.md - Create + plan in one step
│   ├── plan.md - Populate existing issue
│   └── quick-plan.md - Quick planning (no Jira)
├── implementation/
│   ├── start.md - Start with agent coordination
│   ├── next.md - Smart next action detection
│   └── update.md - Update subtask status
├── verification/
│   ├── check.md - Quality checks
│   ├── verify.md - Final verification
│   └── fix.md - Fix verification failures
├── complete/
│   └── finalize.md - Post-completion workflow
├── repeat/ (NEW - Repeat Project)
│   └── check-pr.md - Comprehensive PR analysis
└── utils/
    ├── _shared.md (Interactive mode patterns)
    ├── _interactive_mode_template.md
    ├── status.md
    ├── context.md (NEW)
    ├── report.md (NEW)
    ├── insights.md (NEW)
    ├── auto-assign.md (NEW)
    ├── sync-status.md (NEW)
    ├── rollback.md (NEW)
    ├── dependencies.md (NEW)
    └── agents.md
```

## 🎉 Summary

**PM Commands 2.0** transforms your workflow from:
- ❌ Manual, disconnected commands
- ❌ Constant context switching
- ❌ Forgetting what's next

To:
- ✅ Continuous, guided workflow
- ✅ Intelligent next-action suggestions
- ✅ One-click command chaining
- ✅ Full automation with safety

**Try it now:**
```bash
/pm:planning:create "Your next big feature" your-project
```

Let interactive mode guide you to completion! 🚀
