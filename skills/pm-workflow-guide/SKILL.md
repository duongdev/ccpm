---
name: pm-workflow-guide
description: Provides intelligent context-aware PM workflow guidance using automatic phase detection and command suggestion. Auto-activates when user mentions planning, implementation, verification, spec management, or asks "what command should I use". Detects workflow phase (Planning → Spec → Implementation → Verification → Completion) and suggests optimal command path. Provides learning mode for new users with explanations of each command. Prevents common mistakes (implementing without planning, completing without verification). Suggests next actions based on task status and dependencies. Works with pm-workflow state machine (IDEA → PLANNED → IMPLEMENTING → VERIFYING → VERIFIED → COMPLETE). Offers error prevention ("Run planning first" when needed) and smart automation recommendations.
---

# PM Workflow Guide

This skill helps you navigate CCPM's 27 commands by automatically detecting your current workflow phase and suggesting the most appropriate commands.

## Instructions

### Automatic Phase Detection

This skill activates when user mentions workflow-related keywords and provides context-aware command suggestions.

### Planning Phase

**Trigger phrases**:
- "plan this task"
- "create new task/epic/feature"
- "write a spec"
- "gather requirements"
- "need to understand..."
- "starting a new project"

**Recommended commands**:

1. **Starting from scratch** → `/ccpm:planning:create "Task title" <project> <jira-id>`
   - Creates Linear issue
   - Gathers context from Jira/Confluence/Slack
   - Analyzes codebase
   - Generates comprehensive plan
   - Updates Linear with checklist

2. **Existing Linear issue** → `/ccpm:planning:plan <linear-issue-id> <jira-ticket-id>`
   - Same as above but for existing issue
   - Use when issue created separately

3. **Quick internal task** → `/ccpm:planning:quick-plan "<task-description>" <project>`
   - Lightweight planning without external PM
   - Ideal for quick fixes or quick fixes

4. **Requirements changed** → `/ccpm:planning:update <linear-issue-id> "<update-request>"`
   - Modifies existing plan
   - Interactive clarification
   - Impact analysis
   - Side-by-side comparison

**Example conversation**:
```
User: "I need to plan the new user authentication feature"

Claude: [pm-workflow-guide activates]

I'll help you plan this task. First, let me ask:

Do you have:
1. A Jira ticket with requirements? → Use /ccpm:planning:create
2. An existing Linear issue? → Use /ccpm:planning:plan
3. Just a quick internal task? → Use /ccpm:planning:quick-plan

Which applies?
```

### Spec Management Phase

**Trigger phrases**:
- "write a spec"
- "need architecture document"
- "document this feature"
- "create epic/feature"
- "requirements doc"

**Recommended commands**:

1. **Create Epic/Feature** → `/ccpm:spec:create <type> "<title>" [parent-id]`
   - Types: epic, feature, initiative
   - Creates Linear issue + Document
   - Links them together
   - Populates with template

2. **Write spec content** → `/ccpm:spec:write <doc-id> <section>`
   - Sections: requirements, architecture, api-design, data-model, testing, security, user-flow, timeline
   - AI-assisted writing
   - Fetches latest library docs via Context7

3. **Review spec quality** → `/ccpm:spec:review <doc-id>`
   - A-F grading system
   - Identifies missing sections
   - Suggests improvements
   - Ensures completeness

4. **Break down into tasks** → `/ccpm:spec:break-down <epic-or-feature-id>`
   - Analyzes spec
   - Creates Features from Epics
   - Creates Tasks from Features
   - Maintains hierarchy

5. **Keep spec in sync** → `/ccpm:spec:sync <doc-id-or-issue-id>`
   - Detects spec drift
   - Compares spec vs implementation
   - Updates spec with reality
   - Flags discrepancies

6. **Migrate old specs** → `/ccpm:spec:migrate <project-path> [category]`
   - Converts `.claude/*.md` to Linear Docs
   - Maintains organization
   - Preserves content

**Example conversation**:
```
User: "Let's implement the payment gateway integration"

Claude: [pm-workflow-guide + spec-first-development activate]

⚠️ This sounds like a complex feature that needs a spec first.

Recommended workflow:
1. /ccpm:spec:create epic "Payment Gateway Integration"
2. /ccpm:spec:write <doc-id> (all sections: architecture, security, api-design)
3. /ccpm:spec:review <doc-id> (ensure A/B grade)
4. /ccpm:spec:break-down <doc-id> (create implementation tasks)
5. Then start implementation

Would you like to start with spec creation?
```

### Implementation Phase

**Trigger phrases**:
- "start coding"
- "begin implementation"
- "let's build this"
- "what should I work on"
- "ready to code"

**Recommended commands**:

1. **Start implementation** → `/ccpm:implementation:start <linear-issue-id>`
   - Fetches task context
   - Lists available agents
   - Analyzes subtasks
   - Assigns agents to subtasks
   - Coordinates parallel work

2. **Smart next action** → `/ccpm:implementation:next <linear-issue-id>`
   - Analyzes task status
   - Checks dependencies
   - Reviews progress
   - Suggests optimal next step
   - Considers blockers

3. **Update progress** → `/ccpm:implementation:update <linear-issue-id> <subtask-index> <status> "<summary>"`
   - Status: pending, in_progress, completed
   - Adds work summary to Linear
   - Updates progress tracking
   - Maintains context

4. **Sync progress** → `/ccpm:implementation:sync <linear-issue-id> [summary]`
   - Syncs implementation findings
   - Documents changes made
   - Updates Linear context
   - Maintains full history

**Example conversation**:
```
User: "Let's start working on AUTH-123"

Claude: [pm-workflow-guide activates]

I'll help you start implementation. Use:

/ccpm:implementation:start AUTH-123

This will:
✓ Load full task context
✓ Identify required agents (backend, frontend, security)
✓ Assign subtasks to agents
✓ Coordinate parallel work
✓ Start with highest priority subtask

Ready to proceed?
```

### Verification Phase

**Trigger phrases**:
- "ready to test"
- "done coding"
- "check my work"
- "run quality checks"
- "verify implementation"

**Recommended commands**:

1. **Quality checks** → `/ccpm:verification:check <linear-issue-id>`
   - Resolves IDE warnings
   - Runs linting (ESLint, Prettier)
   - Executes test suite
   - Checks build success
   - Reports all issues

2. **Fix failures** → `/ccpm:verification:fix <linear-issue-id>`
   - Identifies verification failures
   - Analyzes error messages
   - Invokes relevant agents
   - Fixes issues automatically
   - Re-runs verification

3. **Final verification** → `/ccpm:verification:verify <linear-issue-id>`
   - Comprehensive code review
   - Security audit
   - Performance check
   - Documentation review
   - Final sign-off

**Example conversation**:
```
User: "I'm done implementing, ready to test"

Claude: [pm-workflow-guide activates]

Great! Let's verify your work:

Step 1: /ccpm:verification:check <issue-id>
- Runs all automated checks
- Identifies any issues

If issues found:
Step 2: /ccpm:verification:fix <issue-id>
- Automatically fixes common issues

Final step: /ccpm:verification:verify <issue-id>
- Comprehensive review
- Final approval

Shall I start with the quality checks?
```

### Completion Phase

**Trigger phrases**:
- "ready to merge"
- "ship it"
- "create PR"
- "deploy this"
- "mark as complete"

**Recommended commands**:

1. **Finalize task** → `/ccpm:complete:finalize <linear-issue-id>`
   - Creates BitBucket PR
   - Syncs status to Jira
   - Sends Slack notification
   - Cleans up local state
   - Marks Linear issue complete

**Example conversation**:
```
User: "Everything looks good, ready to ship!"

Claude: [pm-workflow-guide + external-system-safety activate]

Perfect! Let's finalize:

/ccpm:complete:finalize <issue-id>

This will:
1. Create BitBucket PR with description
2. Sync Jira status to "Done"
3. Send Slack notification to team
4. Clean up local branches

⚠️ Note: Steps 2-3 require confirmation (external system writes)

Ready to proceed?
```

### Utility Commands (Context-Aware)

**When user asks "what's the status"** → `/ccpm:utils:status <linear-issue-id>`
- Shows current Linear status
- Formatted display
- Progress indicators

**When user asks "load this task"** → `/ccpm:utils:context <linear-issue-id>`
- Quick context loading
- Fetches issue details
- Identifies related files
- Sets up environment

**When user asks "what's available"** → `/ccpm:utils:agents`
- Lists all available agents
- Shows capabilities
- From CLAUDE.md

**When user asks "how complex"** → `/ccpm:utils:insights <linear-issue-id>`
- AI-powered analysis
- Complexity assessment
- Risk identification
- Timeline estimation

**When user asks "what depends on what"** → `/ccpm:utils:dependencies <linear-issue-id>`
- Visualizes dependencies
- Shows execution order
- Identifies blockers

**When user asks "show progress"** → `/ccpm:utils:report <project>`
- Progress across all tasks
- Team velocity
- Burndown charts

**When user asks "search tasks"** → `/ccpm:utils:search <project> "<query>"`
- Text search in Linear
- Lists matching tasks
- Quick access

**When user is stuck** → `/ccpm:utils:help [issue-id]`
- Context-aware help
- Command suggestions
- Workflow guidance

### Workflow State Machine

```
┌─────────────┐
│   IDEA      │ "I need to..."
└──────┬──────┘
       │ /ccpm:spec:create (for epics/features)
       │ /ccpm:planning:create (for tasks)
       ▼
┌─────────────┐
│  PLANNED    │ "Plan is ready"
└──────┬──────┘
       │ /ccpm:implementation:start
       ▼
┌─────────────┐
│IMPLEMENTING │ "Working on it"
└──────┬──────┘
       │ /ccpm:verification:check
       ▼
┌─────────────┐
│  VERIFYING  │ "Testing & reviewing"
└──────┬──────┘
       │ /ccpm:verification:verify
       ▼
┌─────────────┐
│  VERIFIED   │ "All checks passed"
└──────┬──────┘
       │ /ccpm:complete:finalize
       ▼
┌─────────────┐
│  COMPLETE   │ "Shipped! 🚀"
└─────────────┘
```

### Special Workflows

#### Repeat Project (BitBucket PR Review)

**Trigger phrases**:
- "check this PR"
- "review PR 123"
- "analyze pull request"
- "Repeat project PR"

**Command**: `/ccpm:repeat:check-pr <pr-number-or-url>`
- Uses Playwright browser automation
- Navigates BitBucket
- Analyzes PR changes
- Reviews code quality
- Provides feedback

#### UI Design Workflow

**Trigger phrases**:
- "design the UI"
- "create mockups"
- "need wireframes"

**Commands**:
1. `/ccpm:planning:design-ui <issue-id>` - Generate multiple design options
2. `/ccpm:planning:design-refine <issue-id> <option-number> "<feedback>"` - Iterate on design
3. `/ccpm:planning:design-approve <issue-id> <option-number>` - Finalize and generate specs

### Smart Suggestions Based on Context

**If user mentions issue ID directly**:
```
User: "What's the status of AUTH-123?"
Claude: Let me check: /ccpm:utils:status AUTH-123
```

**If user seems lost**:
```
User: "I don't know what to do next with this task"
Claude: Let me help: /ccpm:implementation:next <issue-id>
```

**If user mentions external ticket**:
```
User: "I need to plan JIRA-456"
Claude: I'll create a Linear issue and plan it: /ccpm:planning:create
```

**If user asks about agents**:
```
User: "What agents can help with backend work?"
Claude: Let me show you: /ccpm:utils:agents
```

### Integration with Other Skills

This skill works alongside:

1. **external-system-safety**: Reminds user about confirmation requirements
   ```
   Claude: Note: /ccpm:complete:finalize will require confirmation for:
   - Jira status update
   - Slack notification
   ```

2. **spec-first-development**: Encourages spec creation before implementation
   ```
   Claude: Before using /ccpm:implementation:start, consider:
   - Does this task have a spec?
   - For complex features, use /ccpm:spec:create first
   ```

3. **tdd-practices**: Reminds about TDD workflow
   ```
   Claude: Remember: Write tests first!
   The tdd-enforcer hook will block production code without tests.
   ```

### Error Prevention

**Prevent common mistakes**:

❌ User: "/ccpm:planning:create without JIRA ticket"
✅ Claude: "You'll need a Jira ticket ID. Do you have one, or should we use /ccpm:planning:quick-plan?"

❌ User: "/ccpm:implementation:start without planning"
✅ Claude: "I don't see a plan for this issue yet. Run /ccpm:planning:plan first."

❌ User: "/ccpm:complete:finalize before verification"
✅ Claude: "Run /ccpm:verification:verify first to ensure quality checks pass."

### Learning Mode

For new users, provide extra context:

```
User: "How do I plan a task?"

Claude: [pm-workflow-guide activates - detects new user]

CCPM provides several planning commands:

📋 /ccpm:planning:create - Complete workflow (Jira → Linear → Plan)
   Best for: New tasks with Jira tickets

⚡ /ccpm:planning:quick-plan - Fast planning without Jira
   Best for: Internal tasks, quick fixes

🔄 /ccpm:planning:update - Update existing plan
   Best for: Changed requirements, new information

Which matches your situation?

(Tip: For complex features, consider /ccpm:spec:create first)
```

## Examples

### Example 1: New Feature from Scratch

```
User: "I need to implement a new export feature for reports"

Claude: [pm-workflow-guide + spec-first-development activate]

This sounds like a new feature. Let's start right:

1. Do you have a Jira ticket?
   → Yes: Use /ccpm:planning:create "Export reports feature" <project> <jira-id>
   → No: Use /ccpm:planning:quick-plan "Export reports feature" <project>

2. Is this complex enough for a spec?
   → Yes: Start with /ccpm:spec:create feature "Report Export"
   → No: Proceed with planning

Which path fits your needs?
```

### Example 2: Mid-Implementation Questions

```
User: "I'm stuck on this auth task, not sure what to do next"

Claude: [pm-workflow-guide activates]

Let me help you find the next step:

/ccpm:implementation:next <your-issue-id>

This will analyze:
✓ What subtasks are complete
✓ What's blocked vs available
✓ Dependencies between subtasks
✓ Best next action

It will suggest exactly what to work on next.

What's your issue ID?
```

### Example 3: Ready to Ship

```
User: "I think I'm done, how do I finish this?"

Claude: [pm-workflow-guide activates]

Great! Here's the completion checklist:

✅ Step 1: Quality checks
   /ccpm:verification:check <issue-id>

✅ Step 2: Fix any issues
   /ccpm:verification:fix <issue-id>

✅ Step 3: Final review
   /ccpm:verification:verify <issue-id>

✅ Step 4: Finalize & ship
   /ccpm:complete:finalize <issue-id>

Shall I start with quality checks?
```

## Command Reference Quick Access

**Full command list**: `/ccpm:utils:help`
**Visual workflow**: `/ccpm:utils:cheatsheet`
**Search commands**: Ask "what command should I use for..."

## Summary

This skill helps you:
- ✅ Never wonder "which command should I use?"
- ✅ Follow the optimal workflow for each phase
- ✅ Avoid common mistakes
- ✅ Learn CCPM as you go
- ✅ Stay productive without memorizing 27 commands

The skill activates automatically when you mention planning, implementation, verification, or completion - providing intelligent command suggestions based on your exact context.
