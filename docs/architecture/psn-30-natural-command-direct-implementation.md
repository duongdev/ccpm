# PSN-30: Natural Workflow Commands Direct Implementation Pattern

**Issue**: PSN-30 - Eliminate double context loading in natural workflow commands
**Author**: Backend Architect Agent
**Date**: 2025-11-20
**Status**: Architecture Design (Ready for Implementation)
**Depends On**: PSN-29 (Linear Subagent Architecture)

---

## Executive Summary

This document specifies the architecture for direct implementation of natural workflow commands to eliminate the double context loading problem. By removing the routing layer (SlashCommand tool) and implementing logic directly, we achieve:

1. **67% combined token reduction** - PSN-29 (50-60%) + PSN-30 (30-40% additional) = 67% total
2. **Single context load** - Eliminate 7,000 token SlashCommand routing overhead
3. **Optimal subagent integration** - Direct delegation to Linear operations subagent
4. **Maintained simplicity** - Natural commands remain simple while underlying commands are optimized

**Expected Impact Per Command**:

| Command | Baseline Tokens | With PSN-29 | With PSN-30 | Total Reduction |
|---------|----------------|-------------|-------------|-----------------|
| `/ccpm:work` | ~15,000 | ~8,000 | ~5,000 | 67% |
| `/ccpm:sync` | ~12,000 | ~7,000 | ~4,500 | 63% |
| `/ccpm:plan` (create) | ~20,000 | ~11,000 | ~7,000 | 65% |
| `/ccpm:plan` (plan) | ~18,000 | ~10,000 | ~6,500 | 64% |
| `/ccpm:plan` (update) | ~16,000 | ~9,000 | ~5,500 | 66% |
| `/ccpm:verify` | ~14,000 | ~8,500 | ~5,500 | 61% |
| `/ccpm:done` | ~13,000 | ~7,500 | ~4,800 | 63% |

**Average**: **64% total token reduction** across all natural commands.

---

## 1. Problem Analysis

### 1.1 Current Architecture (Routing Pattern)

```
User → /ccpm:work PSN-27
  ↓
Natural Command (work.md) - 7,000 tokens
  - Parse arguments
  - Detect mode from Linear
  - Route via SlashCommand tool
  ↓
SlashCommand Tool - 3,000 tokens overhead
  ↓
Underlying Command (implementation:start.md) - 8,000 tokens
  - Parse arguments AGAIN
  - Fetch issue from Linear AGAIN
  - Execute logic
  ↓
Total: ~18,000 tokens
```

**Problems**:
1. **Double context loading** - Both natural command and underlying command load the full command context
2. **Repeated argument parsing** - Natural command parses, then underlying command parses again
3. **Duplicate Linear fetches** - Both layers fetch the same issue data
4. **SlashCommand overhead** - 3,000-7,000 tokens per routing operation

### 1.2 Target Architecture (Direct Implementation)

```
User → /ccpm:work PSN-27
  ↓
Natural Command (work.md) - 5,000 tokens TOTAL
  - Parse arguments ONCE
  - Detect mode via Linear subagent (cached)
  - Execute logic DIRECTLY
  - Update Linear via Linear subagent (batched)
  - Display results
  ↓
Total: ~5,000 tokens (64% reduction)
```

**Benefits**:
1. **Single context load** - Only natural command loads
2. **Single argument parse** - Parse once, execute once
3. **Optimized Linear access** - All via subagent with caching
4. **No routing overhead** - Direct execution eliminates SlashCommand tool

---

## 2. Command Structure Pattern

### 2.1 Reference Implementation Template

All natural commands follow this structure:

```markdown
---
description: [Brief description]
---

# /ccpm:[command] - [Title]

**Purpose**: [One-line purpose statement]

**Token Budget**: ~X tokens (vs ~Y baseline, Z% reduction)

**Dependencies**:
- Linear operations subagent (agents/linear-operations.md)
- Workflow state detection (commands/_shared-workflow-state.md)

## 🚨 CRITICAL: Safety Rules

READ FIRST: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

NEVER submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

## Command Flow

This command executes in **5 steps**:

1. **Parse Arguments & Detect Context** - Parse args, detect from git branch if needed
2. **Fetch Current State** - Via Linear subagent (cached)
3. **Execute Mode Logic** - Direct implementation (no routing)
4. **Update Linear** - Via Linear subagent (batched)
5. **Display Results & Next Actions** - Interactive menu

## Implementation

### Step 1: Parse Arguments & Detect Context

```javascript
// Standard argument parsing pattern
const args = process.argv.slice(2)
let issueId = args[0]

const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/

// Git branch detection if no issue ID provided
if (!issueId || !ISSUE_ID_PATTERN.test(issueId)) {
  // READ: commands/_shared-workflow-state.md (detectIssueFromBranch function)
  const detection = detectIssueFromBranch()

  if (!detection.success) {
    console.error("❌ Could not determine issue ID")
    console.log("")
    console.log("Please provide an issue ID:")
    console.log("  /ccpm:[command] PROJ-123")
    console.log("")
    console.log("Or checkout a branch with an issue ID:")
    console.log("  git checkout -b username/PROJ-123-feature-name")
    process.exit(1)
  }

  issueId = detection.issueId
  console.log(`🔍 Detected issue from branch: ${issueId}`)
}

// Validate format
if (!ISSUE_ID_PATTERN.test(issueId)) {
  console.error(`❌ Invalid issue ID format: ${issueId}`)
  console.log("Expected format: PROJECT-NUMBER (e.g., PSN-27, WORK-123)")
  process.exit(1)
}
```

### Step 2: Fetch Current State (via Linear Subagent)

```javascript
// Single subagent call - replaces multiple MCP calls
const result = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: false  # Only if needed for logic
  include_attachments: false
context:
  cache: true  # Enable caching for 85-95% hit rate
  command: "[command-name]"
  purpose: "Fetching issue for [command purpose]"
`)

// Error handling with actionable feedback
if (!result.success) {
  console.error(`❌ Error: ${result.error?.message || 'Failed to fetch issue'}`)

  if (result.error?.suggestions) {
    console.log("")
    console.log("Suggestions:")
    result.error.suggestions.forEach(s => console.log(`  • ${s}`))
  }

  process.exit(1)
}

const issue = result.data
const status = issue.state.name
const title = issue.title
const teamId = issue.team.id
```

### Step 3: Execute Mode Logic (Command-Specific)

```javascript
// [COMMAND-SPECIFIC LOGIC HERE]
// Example for /ccpm:work:

const START_STATUSES = ['Planning', 'Backlog', 'Todo', 'Planned']
const IN_PROGRESS_STATUSES = ['In Progress', 'In Development', 'Doing', 'Started']

let mode

if (START_STATUSES.includes(status)) {
  mode = 'start'
  console.log("✅ Task not started - will begin implementation")
} else if (IN_PROGRESS_STATUSES.includes(status)) {
  mode = 'resume'
  console.log("✅ Task in progress - will suggest next action")
} else {
  // Handle other statuses
  console.log(`ℹ️  Task status is "${status}"`)

  if (status === 'Done' || status === 'Completed') {
    console.error("❌ This task is already complete")
    process.exit(1)
  }

  mode = 'resume' // Default fallback
}
```

### Step 4: Update Linear (via Linear Subagent - Batched)

```javascript
// Batch multiple updates into single subagent call
const updateResult = await Task('linear-operations', `
operation: update_issue
params:
  issue_id: "${issueId}"
  state: "[new-state]"
  labels:
    - "[label1]"
    - "[label2]"
  # All updates in one call
context:
  cache: false  # Updates never cached
  command: "[command-name]"
  purpose: "Updating issue state"
`)

if (!updateResult.success) {
  console.error("⚠️  Failed to update Linear")
  // Continue anyway - non-blocking
}

// Add comment if needed (separate call)
const commentResult = await Task('linear-operations', `
operation: create_comment
params:
  issue_id: "${issueId}"
  body: |
    ## [Comment Title]

    [Comment content]
context:
  command: "[command-name]"
`)
```

### Step 5: Display Results & Interactive Menu

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [Command] Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId}
📝 Title: ${title}
📊 Status: ${newStatus}

[Command-specific summary]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

```javascript
// Use AskUserQuestion for interactive next actions
const answer = await AskUserQuestion({
  questions: [{
    question: "What would you like to do next?",
    header: "Next Action",
    multiSelect: false,
    options: [
      {
        label: "[Primary Action]",
        description: "[Description] (/ccpm:[command])"
      },
      {
        label: "[Secondary Action]",
        description: "[Description] (/ccpm:[command])"
      },
      {
        label: "View Status",
        description: "Check current task status (/ccpm:utils:status)"
      }
    ]
  }]
})

// Execute chosen action
switch (answer) {
  case "Primary Action":
    // Execute primary action directly (no SlashCommand)
    break
  case "Secondary Action":
    // Execute secondary action directly
    break
  case "View Status":
    // Could delegate to utils:status or display inline
    break
}
```

## Helper Functions

### detectIssueFromBranch()

```javascript
// Moved to _shared-workflow-state.md
function detectIssueFromBranch() {
  try {
    const branch = execSync('git rev-parse --abbrev-ref HEAD', {
      encoding: 'utf-8'
    }).trim()

    const branchMatch = branch.match(/([A-Z]+-\d+)/)

    if (branchMatch) {
      return {
        success: true,
        issueId: branchMatch[1],
        branch
      }
    }

    return {
      success: false,
      error: 'No issue ID found in branch name'
    }
  } catch (error) {
    return {
      success: false,
      error: 'Not a git repository'
    }
  }
}
```

## Token Budget Breakdown

| Section | Tokens | Optimization |
|---------|--------|--------------|
| Command metadata | ~100 | Minimal frontmatter |
| Argument parsing | ~200 | Shared utility functions |
| Linear fetch (subagent) | ~200 | Cached, YAML contract |
| Mode detection logic | ~400 | Direct implementation |
| Linear update (subagent) | ~200 | Batched operations |
| Display & interactive | ~800 | Reusable patterns |
| Helper utilities | ~500 | Shared functions |
| **Total** | **~2,400** | vs ~7,000 routing baseline |

**Breakdown of Token Reduction**:
- Eliminate SlashCommand tool: -3,000 tokens (43%)
- Eliminate duplicate context: -2,000 tokens (29%)
- Use subagent caching: -1,600 tokens (23%)
- **Total reduction**: -6,600 tokens (66% from ~10,000 baseline)
```

---

## 3. Linear Subagent Integration Patterns

### 3.1 When to Use Subagent vs Helpers

**Use Linear Subagent Directly** (Recommended):
- Creating issues with labels and state
- Updating multiple issue fields at once
- Fetching issues with related data
- Batch operations (ensure multiple labels)
- Any operation requiring validation + execution

**Use Shared Helpers** (Legacy Support):
- Simple validation checks
- When only validating one field
- Backward compatibility during migration

### 3.2 Subagent Operation Patterns

#### Pattern 1: Fetch Issue (with caching)

```yaml
Task(linear-operations): `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: false  # Only true if needed
  include_attachments: false
  include_children: false
context:
  cache: true  # Critical for performance
  command: "${COMMAND_NAME}"
  purpose: "Fetching issue for [purpose]"
`
```

**Token Cost**: ~200 tokens (cached), ~600 tokens (uncached)
**Performance**: <50ms (cached), <500ms (uncached)

#### Pattern 2: Create Issue (with validation)

```yaml
Task(linear-operations): `
operation: create_issue
params:
  team: "${TEAM_NAME_OR_ID}"  # Subagent resolves
  title: "${TITLE}"
  description: |
    ${DESCRIPTION}
  state: "${STATE_NAME}"  # Subagent validates
  labels:
    ${LABEL_NAMES.map(l => `- "${l}"`).join('\n    ')}
  assignee: "me"  # or email/name
  project: "${PROJECT_NAME_OR_ID}"
  priority: ${PRIORITY}
context:
  cache: false
  command: "${COMMAND_NAME}"
  purpose: "Creating new task"
`
```

**Token Cost**: ~400 tokens (2-3 labels), ~600 tokens (5+ labels)
**Operations**: Validates team, state, labels → Creates issue
**Replaces**: 5-8 separate MCP calls

#### Pattern 3: Update Issue (batched)

```yaml
Task(linear-operations): `
operation: update_issue
params:
  issue_id: "${issueId}"
  ${title ? `title: "${title}"` : ''}
  ${description ? `description: |\n    ${description}` : ''}
  ${state ? `state: "${state}"` : ''}
  ${labels ? `labels:\n${labels.map(l => `    - "${l}"`).join('\n')}` : ''}
  ${assignee ? `assignee: "${assignee}"` : ''}
context:
  cache: false
  command: "${COMMAND_NAME}"
  purpose: "Updating issue"
`
```

**Token Cost**: ~300 tokens (2-3 fields), ~500 tokens (all fields)
**Operations**: Validates all inputs → Batches updates → Single MCP call
**Replaces**: 3-5 separate MCP calls

#### Pattern 4: Create Comment

```yaml
Task(linear-operations): `
operation: create_comment
params:
  issue_id: "${issueId}"
  body: |
    ## ${COMMENT_TITLE}

    ${COMMENT_BODY}

    ${METADATA}
context:
  command: "${COMMAND_NAME}"
  purpose: "Recording progress"
`
```

**Token Cost**: ~250 tokens
**Operations**: Direct comment creation
**Replaces**: 1 MCP call (no savings, but consistency)

### 3.3 Error Handling with Subagent

```javascript
const result = await Task('linear-operations', `...`)

if (!result.success) {
  // Structured error from subagent
  const error = result.error

  console.error(`❌ Error: ${error.message}`)

  // Display suggestions if available
  if (error.suggestions && error.suggestions.length > 0) {
    console.log("")
    console.log("Suggestions:")
    error.suggestions.forEach(s => console.log(`  • ${s}`))
  }

  // Display available options if relevant
  if (error.details?.available_statuses) {
    console.log("")
    console.log("Available statuses:")
    error.details.available_statuses.forEach(s => {
      console.log(`  - ${s.name} (type: ${s.type})`)
    })
  }

  process.exit(1)
}
```

**Benefits**:
- Actionable error messages
- Suggestions for fixes
- Available options displayed
- Consistent error format

---

## 4. Smart Agent Selection Strategy

### 4.1 When to Invoke Agents

**Explicit Subagent** (Always):
- `Task('linear-operations')` - All Linear operations

**Smart Selection** (When Needed):
- Technical analysis (codebase review, architecture decisions)
- Code generation (implementation, testing)
- Design decisions (UI/UX, API design)

**No Agent** (Inline):
- Simple logic (status checks, formatting)
- Git operations (branch detection, status checks)
- Display formatting (output, menus)

### 4.2 Example: /ccpm:work Command

```markdown
## Step 1: Parse & Detect
# No agent - simple logic

## Step 2: Fetch Issue
Task(linear-operations): `
operation: get_issue
...
`

## Step 3: Mode Detection
# No agent - simple status check

## Step 4: Analyze Codebase (START mode only)
Task: `
Analyze the codebase for files related to: ${issue.title}

Identify:
- Files to modify
- Dependencies to add
- Testing requirements
- Potential risks

${issue.description}
`
# Smart-agent-selector chooses: backend-architect, frontend-developer, etc.

## Step 5: Update Linear
Task(linear-operations): `
operation: update_issue
...
`

## Step 6: Display Results
# No agent - formatting logic
```

**Key Principle**: Use agents for **expertise**, not for **orchestration**.

---

## 5. Command-Specific Implementations

### 5.1 /ccpm:work - Start or Resume Work

**Modes**: START (not started) | RESUME (in progress)

**Linear Operations**:
1. `get_issue` (cached) - Fetch current state
2. `update_issue` (START mode) - Change state to "In Progress" + labels
3. `create_comment` (START mode) - Log assignment plan

**Smart Agent Usage**:
- START mode: Analyze codebase for implementation plan
- RESUME mode: No agent needed (just display progress)

**Token Budget**: ~5,000 tokens
- Baseline: ~15,000 tokens
- Reduction: 67%

**Implementation Highlights**:
```javascript
// Step 1: Fetch (cached)
const issue = await Task('linear-operations', `operation: get_issue ...`)

// Step 2: Detect mode
const mode = START_STATUSES.includes(issue.state.name) ? 'start' : 'resume'

// Step 3: Execute mode logic
if (mode === 'start') {
  // Analyze codebase via smart selection
  const analysis = await Task(`Analyze codebase for: ${issue.title}`)

  // Update Linear (batched)
  await Task('linear-operations', `
    operation: update_issue
    params:
      issue_id: "${issueId}"
      state: "In Progress"
      labels: ["implementation", "in-development"]
  `)

  // Add comment
  await Task('linear-operations', `
    operation: create_comment
    params:
      issue_id: "${issueId}"
      body: |
        ## 🚀 Started Implementation

        ${analysis}
  `)
} else {
  // Resume mode - just display progress
  displayProgress(issue)
}
```

### 5.2 /ccpm:sync - Save Progress

**Modes**: Single mode (always sync)

**Linear Operations**:
1. `get_issue` (cached) - Fetch current issue
2. `create_comment` - Log progress update

**Git Integration**:
- Detect changed files (via bash)
- Generate auto-summary if not provided
- Warn about uncommitted changes

**Token Budget**: ~4,500 tokens
- Baseline: ~12,000 tokens
- Reduction: 63%

**Implementation Highlights**:
```javascript
// Step 1: Detect git changes (local)
const changes = detectUncommittedChanges() // from _shared-workflow-state.md

// Step 2: Generate summary
const summary = args[1] || generateAutoSummary(changes.changes)

// Step 3: Add comment to Linear
await Task('linear-operations', `
operation: create_comment
params:
  issue_id: "${issueId}"
  body: |
    ## 🔄 Progress Sync

    ${summary}

    **Changed Files**: ${changes.count}
    ${changes.summary}

    **Time**: ${new Date().toISOString()}
`)

console.log("✅ Progress synced to Linear")
```

### 5.3 /ccpm:plan - Smart Planning

**Modes**: CREATE (new) | PLAN (existing) | UPDATE (modify)

**Linear Operations**:
- CREATE: `create_issue` + `create_comment` (plan)
- PLAN: `get_issue` + `update_issue` (description) + `create_comment`
- UPDATE: `get_issue` + `create_comment` (changes)

**External Integrations**:
- Context7 MCP (documentation)
- Atlassian MCP (Jira/Confluence - with confirmation)
- Smart agent selection (technical planning)

**Token Budget**:
- CREATE: ~7,000 tokens (baseline: ~20,000, 65% reduction)
- PLAN: ~6,500 tokens (baseline: ~18,000, 64% reduction)
- UPDATE: ~5,500 tokens (baseline: ~16,000, 66% reduction)

**Implementation Highlights** (CREATE mode):
```javascript
// Step 1: Parse mode
const mode = isIssueId(args[0]) ? (args[1] ? 'update' : 'plan') : 'create'

// CREATE MODE
if (mode === 'create') {
  // Step 2: Gather context (external systems)
  const jiraContext = await fetchJiraTicket(jiraTicketId) // if provided
  const confluenceContext = await searchConfluence(title)
  const docsContext = await searchContext7(techStack)

  // Step 3: Analyze with smart agent
  const plan = await Task(`
    Create implementation plan for: ${title}

    Context:
    ${jiraContext}
    ${confluenceContext}
    ${docsContext}
  `)

  // Step 4: Create issue (batched)
  const issue = await Task('linear-operations', `
    operation: create_issue
    params:
      team: "${projectTeam}"
      title: "${title}"
      description: |
        ## Overview
        ${plan.overview}

        ## Implementation Checklist
        ${plan.checklist}
      state: "Planning"
      labels: ["planning", "researched"]
      assignee: "me"
  `)

  console.log(`✅ Created: ${issue.data.identifier}`)
}
```

### 5.4 /ccpm:verify - Quality Checks + Verification

**Modes**: Sequential (checks → verify)

**Linear Operations**:
1. `get_issue` (cached) - Fetch current state
2. `update_issue` - Change to "Verification" state
3. `create_comment` - Log verification results

**Sequential Flow**:
1. Run quality checks (linting, tests, build)
2. If pass → Run final verification (code review, security)
3. If fail → Stop and suggest fixes

**Token Budget**: ~5,500 tokens
- Baseline: ~14,000 tokens
- Reduction: 61%

**Implementation Highlights**:
```javascript
// Step 1: Run quality checks (inline - no agent needed)
console.log("Step 1/2: Quality Checks")

const lintResult = await Bash('npm run lint', { timeout: 60000 })
const testResult = await Bash('npm test', { timeout: 120000 })
const buildResult = await Bash('npm run build', { timeout: 120000 })

const allPassed = !lintResult.includes('error') &&
                  !testResult.includes('FAIL') &&
                  !buildResult.includes('failed')

if (!allPassed) {
  console.error("❌ Quality checks failed")
  console.log("Run: /ccpm:verification:fix to debug")
  process.exit(1)
}

console.log("✅ Quality checks passed")

// Step 2: Final verification (smart agent selection)
console.log("Step 2/2: Final Verification")

const verification = await Task(`
Review the code changes for ${issueId}

Check:
- Code quality and patterns
- Security vulnerabilities
- Test coverage
- Documentation
`)

// Step 3: Update Linear
await Task('linear-operations', `
operation: update_issue
params:
  issue_id: "${issueId}"
  state: "Verification"
  labels: ["verified", "ready-for-review"]
`)

console.log("✅ Verification complete!")
```

### 5.5 /ccpm:done - Finalize Task

**Modes**: Single mode (finalize)

**Pre-Flight Checks**:
1. Not on main/master branch
2. Branch pushed to remote
3. No uncommitted changes
4. Task in appropriate status

**Operations**:
1. Create GitHub PR (via GitHub MCP)
2. Update Linear to "Done"
3. Sync to Jira (with confirmation)
4. Send Slack notification (with confirmation)

**Token Budget**: ~4,800 tokens
- Baseline: ~13,000 tokens
- Reduction: 63%

**Implementation Highlights**:
```javascript
// Step 1: Pre-flight checks (inline)
const currentBranch = detectCurrentBranch()
if (currentBranch === 'main' || currentBranch === 'master') {
  console.error("❌ Cannot finalize from main branch")
  process.exit(1)
}

const isPushed = isBranchPushed() // from _shared-workflow-state.md
if (!isPushed) {
  console.error("❌ Branch not pushed to remote")
  process.exit(1)
}

const changes = detectUncommittedChanges()
if (changes.hasChanges) {
  console.error("❌ Uncommitted changes detected")
  process.exit(1)
}

// Step 2: Fetch issue
const issue = await Task('linear-operations', `operation: get_issue ...`)

// Step 3: Create PR (GitHub MCP)
const pr = await mcp__github__create_pull_request({
  title: issue.data.title,
  body: generatePRBody(issue.data),
  head: currentBranch,
  base: 'main'
})

console.log(`✅ PR created: ${pr.url}`)

// Step 4: Update Linear
await Task('linear-operations', `
operation: update_issue
params:
  issue_id: "${issueId}"
  state: "Done"
  labels: ["completed", "merged"]
`)

// Step 5: External syncs (WITH CONFIRMATION)
if (jiraConfigured) {
  // Show confirmation dialog via AskUserQuestion
  const confirm = await AskUserQuestion({
    questions: [{
      question: "Sync status to Jira?",
      options: [
        { label: "Yes", description: "Update Jira ticket status" },
        { label: "No", description: "Skip Jira sync" }
      ]
    }]
  })

  if (confirm === "Yes") {
    await updateJiraTicket(jiraTicketId, 'Done')
  }
}
```

---

## 6. Token Budget Calculator

### 6.1 Formula

```
Total Command Tokens =
  BASE_OVERHEAD +
  ARGUMENT_PARSING +
  LINEAR_OPERATIONS +
  MODE_LOGIC +
  AGENT_INVOCATIONS +
  DISPLAY_OUTPUT

Where:
- BASE_OVERHEAD: ~200 (frontmatter, imports, safety rules)
- ARGUMENT_PARSING: ~200 (parse args, validate, detect from git)
- LINEAR_OPERATIONS: ~200-600 (depends on caching, operations count)
- MODE_LOGIC: ~400-800 (depends on complexity)
- AGENT_INVOCATIONS: ~1,000-2,000 per agent (depends on analysis depth)
- DISPLAY_OUTPUT: ~500-800 (results, interactive menu, formatting)
```

### 6.2 Token Estimation Table

| Operation | Tokens | Notes |
|-----------|--------|-------|
| Frontmatter + imports | 200 | Minimal boilerplate |
| Argument parsing | 200 | Standard pattern |
| Git branch detection | 150 | Bash + parsing |
| Linear get_issue (cached) | 200 | YAML + result parsing |
| Linear get_issue (uncached) | 600 | Full issue object |
| Linear create_issue | 400 | With 2-3 labels |
| Linear update_issue | 300 | Batch 3-4 fields |
| Linear create_comment | 250 | Standard comment |
| Smart agent analysis | 1,500 | Codebase analysis |
| Quality checks (inline) | 400 | Bash commands + parsing |
| Display + interactive menu | 600 | Formatted output + AskUserQuestion |

### 6.3 Example Calculation: /ccpm:work

```
/ccpm:work PSN-27 (START mode)

Breakdown:
1. Base overhead: 200
2. Argument parsing: 200
3. Linear get_issue (cached): 200
4. Mode detection logic: 300
5. Smart agent analysis: 1,500
6. Linear update_issue: 300
7. Linear create_comment: 250
8. Display + menu: 600

Total: 3,550 tokens

With safety margin (15%): ~4,100 tokens
Target budget: ~5,000 tokens ✅

Baseline comparison:
- Old routing pattern: ~15,000 tokens
- Reduction: 73%
```

---

## 7. Migration Strategy

### 7.1 Phase 1: High-Impact Commands (Week 1)

Migrate commands with highest usage and token consumption:

1. **`/ccpm:work`** - Most used, 67% reduction
2. **`/ccpm:sync`** - Frequent use, 63% reduction
3. **`/ccpm:done`** - Critical path, 63% reduction

**Success Criteria**:
- Token reduction ≥60% per command
- No functionality regressions
- User feedback positive

### 7.2 Phase 2: Planning Commands (Week 2)

Migrate planning workflow:

1. **`/ccpm:plan`** (CREATE mode) - 65% reduction
2. **`/ccpm:plan`** (PLAN mode) - 64% reduction
3. **`/ccpm:plan`** (UPDATE mode) - 66% reduction

**Success Criteria**:
- All modes working correctly
- Mode detection accurate (100%)
- External integrations functional

### 7.3 Phase 3: Verification Commands (Week 3)

Migrate verification workflow:

1. **`/ccpm:verify`** - 61% reduction
2. **`/ccpm:commit`** (already optimized, verify consistency)

**Success Criteria**:
- Sequential flow works correctly
- Quality checks accurate
- Verification agents invoked properly

### 7.4 Backward Compatibility

**Old Commands**: Keep functional during migration
- `/ccpm:implementation:start` → Works, shows hint to use `/ccpm:work`
- `/ccpm:implementation:sync` → Works, shows hint to use `/ccpm:sync`
- etc.

**Migration Hints** (added to old commands):
```markdown
ℹ️  **Pro Tip**: This command has been optimized!

Use the natural workflow command instead:
  /ccpm:work (replaces implementation:start + implementation:next)

Benefits:
  • 67% fewer tokens (faster responses)
  • Auto-detection from git branch
  • Simpler syntax

The old command still works, but the new one is recommended.
```

### 7.5 Testing Strategy

**Unit Testing** (per command):
- Argument parsing (valid, invalid, edge cases)
- Git detection (branch patterns, errors)
- Mode detection (all status combinations)
- Error handling (Linear failures, git failures)

**Integration Testing** (across commands):
- Full workflow: plan → work → sync → verify → done
- Branch detection consistency
- Linear state transitions
- Interactive menus

**Token Budget Testing**:
- Measure actual token usage vs budget
- Track caching hit rates
- Compare with baseline measurements
- Validate reduction percentages

**User Acceptance Testing**:
- Run through common scenarios
- Collect feedback on UX
- Verify no regressions
- Measure perceived performance

---

## 8. Performance Metrics & Monitoring

### 8.1 Key Metrics

**Token Usage**:
- Tokens per command execution
- Tokens saved vs baseline
- Cache hit rate (Linear subagent)

**Performance**:
- Execution time per command
- Linear operation latency
- Git operation latency

**Quality**:
- Error rate per command
- User retry rate
- Success rate per workflow

### 8.2 Target KPIs

| Metric | Target | Measurement |
|--------|--------|-------------|
| Token reduction | ≥60% | Per command, vs baseline |
| Cache hit rate | ≥85% | Linear subagent operations |
| Execution time | <5s | 95th percentile |
| Error rate | <2% | Per command |
| User satisfaction | ≥8/10 | Survey after migration |

### 8.3 Monitoring Implementation

**Token Tracking**:
```javascript
// Add to each command
const startTokens = getCurrentTokenCount()
const startTime = Date.now()

// ... command execution ...

const endTokens = getCurrentTokenCount()
const endTime = Date.now()

const tokensUsed = endTokens - startTokens
const duration = endTime - startTime

// Log for analysis
console.log(`[METRICS] ${commandName}: ${tokensUsed} tokens, ${duration}ms`)
```

**Subagent Metrics** (already in Linear subagent):
```yaml
metadata:
  cached: true/false
  duration_ms: 450
  mcp_calls: 2
  cache_hit_rate: 0.87
```

---

## 9. Risk Analysis & Mitigation

### 9.1 Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Token budget exceeded | High | Low | Conservative estimates, monitoring |
| Regression in functionality | High | Medium | Comprehensive testing, gradual rollout |
| User confusion from changes | Medium | Low | Clear migration hints, documentation |
| Subagent performance issues | Medium | Low | Fallback to direct MCP, monitoring |
| Git detection failures | Low | Medium | Clear error messages, fallback to manual |

### 9.2 Rollback Plan

If critical issues arise:

1. **Phase 1**: Revert new command files
2. **Phase 2**: Restore old command routing
3. **Phase 3**: Analyze failures, fix issues
4. **Phase 4**: Re-deploy with fixes

**Criteria for Rollback**:
- Error rate >5% for 24 hours
- User complaints >10
- Token reduction <40% (not meeting goals)
- Critical bug affecting workflows

---

## 10. Documentation Requirements

### 10.1 User-Facing Documentation

**Update Files**:
1. `README.md` - Highlight token optimization
2. `docs/guides/natural-commands.md` - Document new patterns
3. `CHANGELOG.md` - Version 2.4 release notes
4. Command help text - Add performance notes

**New Content**:
- "Why are responses faster?" FAQ
- Token usage comparison table
- Migration benefits explainer

### 10.2 Developer Documentation

**Update Files**:
1. `CLAUDE.md` - Update command structure section
2. `docs/architecture/` - Add this document
3. `docs/development/` - Add implementation guide
4. Command templates - Update to direct pattern

**New Content**:
- Direct implementation guide
- Token budget calculator
- Testing checklist
- Monitoring guide

---

## 11. Success Criteria

### 11.1 Technical Success

✅ **Token Reduction**:
- Average ≥60% reduction across all commands
- Individual commands meet budget targets
- Cache hit rate ≥85%

✅ **Performance**:
- Execution time <5s (95th percentile)
- Linear operations <500ms (uncached)
- Linear operations <50ms (cached)

✅ **Quality**:
- Zero critical bugs
- Error rate <2%
- All tests passing

### 11.2 User Success

✅ **Adoption**:
- >80% of users adopt natural commands within 2 weeks
- <5 support tickets related to new commands
- Positive feedback on performance

✅ **Experience**:
- Faster perceived response times
- Reduced waiting for command execution
- Maintained or improved ease of use

### 11.3 Business Success

✅ **Cost Reduction**:
- Lower token usage = lower API costs
- Faster execution = better user productivity
- Reduced support burden

✅ **Competitive Advantage**:
- Faster than competing tools
- More efficient resource usage
- Better user experience

---

## 12. Next Steps

### 12.1 Immediate Actions

1. **Review & Approve** this architecture document
2. **Create implementation issues** for each phase
3. **Set up monitoring** for token tracking
4. **Prepare testing environment** with baseline measurements

### 12.2 Phase 1 Implementation (Week 1)

1. Implement `/ccpm:work` with direct pattern
2. Implement `/ccpm:sync` with direct pattern
3. Implement `/ccpm:done` with direct pattern
4. Test thoroughly, measure metrics
5. Deploy to production

### 12.3 Phase 2-3 Implementation (Weeks 2-3)

1. Implement planning commands
2. Implement verification commands
3. Update documentation
4. Collect user feedback
5. Iterate based on learnings

---

## Appendix A: Full Token Comparison

| Command | Baseline | PSN-29 Only | PSN-30 Direct | Combined | Reduction |
|---------|----------|-------------|---------------|----------|-----------|
| `/ccpm:work` (start) | 15,000 | 8,000 | 5,000 | 5,000 | 67% |
| `/ccpm:work` (resume) | 13,000 | 7,500 | 4,500 | 4,500 | 65% |
| `/ccpm:sync` | 12,000 | 7,000 | 4,500 | 4,500 | 63% |
| `/ccpm:plan` (create) | 20,000 | 11,000 | 7,000 | 7,000 | 65% |
| `/ccpm:plan` (plan) | 18,000 | 10,000 | 6,500 | 6,500 | 64% |
| `/ccpm:plan` (update) | 16,000 | 9,000 | 5,500 | 5,500 | 66% |
| `/ccpm:verify` | 14,000 | 8,500 | 5,500 | 5,500 | 61% |
| `/ccpm:done` | 13,000 | 7,500 | 4,800 | 4,800 | 63% |
| **Average** | **15,125** | **8,563** | **5,413** | **5,413** | **64%** |

**Total Savings Per User Per Day** (assuming 10 commands):
- Baseline: 151,250 tokens/day
- With PSN-30: 54,130 tokens/day
- **Savings**: 97,120 tokens/day (64%)

**Monthly Savings** (per user, 20 working days):
- **1,942,400 tokens/month saved**

---

## Appendix B: Implementation Checklist

### Per Command

- [ ] Remove SlashCommand routing
- [ ] Implement direct argument parsing
- [ ] Integrate Linear subagent for all Linear ops
- [ ] Add git detection utilities
- [ ] Implement mode-specific logic inline
- [ ] Add error handling with actionable messages
- [ ] Create interactive menu with AskUserQuestion
- [ ] Add token budget comment at top
- [ ] Test all modes and edge cases
- [ ] Measure token usage vs budget
- [ ] Add migration hint to old command
- [ ] Update documentation

### Per Phase

- [ ] Deploy commands to production
- [ ] Monitor token usage for 3 days
- [ ] Collect user feedback
- [ ] Address any issues
- [ ] Update metrics dashboard
- [ ] Proceed to next phase

---

## Appendix C: Code Snippets Library

### Snippet 1: Standard Argument Parsing

```javascript
const args = process.argv.slice(2)
let issueId = args[0]

const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/

if (!issueId || !ISSUE_ID_PATTERN.test(issueId)) {
  const detection = detectIssueFromBranch()

  if (!detection.success) {
    console.error("❌ Could not determine issue ID")
    console.log("")
    console.log("Please provide an issue ID:")
    console.log("  /ccpm:[command] PROJ-123")
    process.exit(1)
  }

  issueId = detection.issueId
  console.log(`🔍 Detected issue from branch: ${issueId}`)
}
```

### Snippet 2: Fetch Issue via Subagent

```javascript
const result = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: false
context:
  cache: true
  command: "${COMMAND_NAME}"
  purpose: "Fetching issue"
`)

if (!result.success) {
  console.error(`❌ Error: ${result.error?.message || 'Failed to fetch issue'}`)
  if (result.error?.suggestions) {
    console.log("")
    console.log("Suggestions:")
    result.error.suggestions.forEach(s => console.log(`  • ${s}`))
  }
  process.exit(1)
}

const issue = result.data
```

### Snippet 3: Update Issue (Batched)

```javascript
const updateResult = await Task('linear-operations', `
operation: update_issue
params:
  issue_id: "${issueId}"
  state: "${newState}"
  labels:
    - "${label1}"
    - "${label2}"
context:
  command: "${COMMAND_NAME}"
`)

if (!updateResult.success) {
  console.warn("⚠️  Failed to update Linear (non-blocking)")
}
```

### Snippet 4: Interactive Next Action

```javascript
const answer = await AskUserQuestion({
  questions: [{
    question: "What would you like to do next?",
    header: "Next Action",
    multiSelect: false,
    options: [
      {
        label: "Continue Work",
        description: "Resume implementation (/ccpm:work)"
      },
      {
        label: "Save Progress",
        description: "Sync to Linear (/ccpm:sync)"
      },
      {
        label: "View Status",
        description: "Check task status (/ccpm:utils:status)"
      }
    ]
  }]
})

switch (answer) {
  case "Continue Work":
    // Inline logic or delegate to work command
    break
  case "Save Progress":
    // Inline sync or delegate
    break
  case "View Status":
    // Display inline or delegate
    break
}
```

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-20 | Backend Architect | Initial architecture design |

---

**End of Document**
