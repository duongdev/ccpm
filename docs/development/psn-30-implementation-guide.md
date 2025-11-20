# PSN-30 Implementation Guide

**For**: CCPM Command Developers
**Related**: PSN-30 Architecture (docs/architecture/psn-30-natural-command-direct-implementation.md)
**Date**: 2025-11-20

---

## Quick Start

This guide provides step-by-step instructions for converting natural workflow commands from routing pattern to direct implementation pattern.

---

## Step-by-Step Conversion

### Step 1: Understand Current Command

Before converting, analyze the current command structure:

```markdown
1. What does the command do? (start work, sync progress, etc.)
2. What modes does it have? (create/plan/update, start/resume, etc.)
3. What Linear operations are needed? (get_issue, update_issue, create_comment)
4. What external systems are involved? (git, Jira, GitHub)
5. What agents are needed? (technical analysis, code review)
```

**Example: `/ccpm:work`**
- Purpose: Start or resume work on a task
- Modes: START (not started) | RESUME (in progress)
- Linear ops: get_issue, update_issue, create_comment
- External: git (branch detection, status)
- Agents: Smart selection for codebase analysis (START mode only)

### Step 2: Create Command Template

Start with the standard template:

```markdown
---
description: [Brief description]
---

# /ccpm:[command] - [Title]

**Purpose**: [One-line purpose]

**Token Budget**: ~X tokens (vs ~Y baseline, Z% reduction)

**Dependencies**:
- Linear operations subagent (agents/linear-operations.md)
- Workflow state detection (commands/_shared-workflow-state.md)

## 🚨 CRITICAL: Safety Rules

READ FIRST: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

NEVER submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

## Command Flow

[5-step flow description]

## Implementation

[Steps 1-5]

## Examples

[3-5 usage examples]

## Benefits

[List of benefits]
```

### Step 3: Implement Argument Parsing

Use the standard pattern:

```javascript
// Step 1: Parse Arguments & Detect Context

const args = process.argv.slice(2)
let issueId = args[0]

const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/

// Git branch detection if no issue ID provided
if (!issueId || !ISSUE_ID_PATTERN.test(issueId)) {
  // Use shared utility from _shared-workflow-state.md
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

**Key Points**:
- Always validate issue ID format
- Support git branch detection for convenience
- Provide helpful error messages with examples
- Exit with code 1 on errors

### Step 4: Fetch Linear State

Use Linear subagent with caching:

```javascript
// Step 2: Fetch Current State (via Linear Subagent)

const result = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: false  # Only true if needed for logic
  include_attachments: false
  include_children: false
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

  if (result.error?.details?.available_statuses) {
    console.log("")
    console.log("Available statuses:")
    result.error.details.available_statuses.forEach(s => {
      console.log(`  - ${s.name} (type: ${s.type})`)
    })
  }

  process.exit(1)
}

const issue = result.data
const status = issue.state.name
const title = issue.title
const teamId = issue.team.id
const description = issue.description
```

**Key Points**:
- Always use `cache: true` for read operations
- Include only necessary expansions (comments, attachments)
- Handle errors gracefully with suggestions
- Extract all needed fields upfront

### Step 5: Implement Mode Logic

Detect mode and execute appropriate logic:

```javascript
// Step 3: Execute Mode Logic

const MODE_A_STATUSES = ['Status1', 'Status2', 'Status3']
const MODE_B_STATUSES = ['Status4', 'Status5', 'Status6']

let mode

if (MODE_A_STATUSES.includes(status)) {
  mode = 'mode_a'
  console.log("✅ Mode A detected - [description]")
} else if (MODE_B_STATUSES.includes(status)) {
  mode = 'mode_b'
  console.log("✅ Mode B detected - [description]")
} else {
  // Handle other statuses
  console.log(`ℹ️  Task status is "${status}"`)

  if (status === 'Done' || status === 'Completed') {
    console.error("❌ This task is already complete")
    process.exit(1)
  }

  // Default fallback
  mode = 'mode_b'
  console.log(`⚠️  Unknown status "${status}" - defaulting to mode B`)
}

// Execute mode-specific logic
if (mode === 'mode_a') {
  // [MODE A LOGIC]
} else {
  // [MODE B LOGIC]
}
```

**Key Points**:
- Define clear status lists for each mode
- Always have a fallback for unknown statuses
- Log what mode is detected and why
- Provide actionable feedback for invalid states

### Step 6: Integrate Smart Agents

Use smart agent selection for technical tasks:

```javascript
// Step 3b: Analyze Codebase (MODE A only)

if (mode === 'mode_a') {
  console.log("")
  console.log("🔍 Analyzing codebase...")
  console.log("")

  const analysis = await Task(`
Analyze the codebase for files related to: ${issue.title}

Context:
${issue.description}

Identify:
- Files to modify
- Dependencies to add
- Testing requirements
- Potential risks
- Recommended approach

Provide a structured implementation plan.
`)

  // Use analysis results in next steps
  console.log("✅ Analysis complete")
}
```

**Key Points**:
- Use `Task(...)` (no agent name) for smart selection
- Provide clear context from issue
- Ask for structured output
- Only invoke when needed (don't over-use agents)

### Step 7: Update Linear State

Batch updates into single subagent call:

```javascript
// Step 4: Update Linear (via Linear Subagent - Batched)

const updateResult = await Task('linear-operations', `
operation: update_issue
params:
  issue_id: "${issueId}"
  state: "[new-state]"
  labels:
    - "[label1]"
    - "[label2]"
    - "[label3]"
  ${assignee ? `assignee: "${assignee}"` : ''}
  ${priority ? `priority: ${priority}` : ''}
context:
  cache: false  # Updates never cached
  command: "[command-name]"
  purpose: "Updating issue state"
`)

if (!updateResult.success) {
  console.warn("⚠️  Failed to update Linear (non-blocking)")
  // Don't exit - update failure shouldn't block workflow
}
```

**Key Points**:
- Batch all updates into single call
- Use conditional YAML for optional fields
- `cache: false` for all write operations
- Non-blocking errors (warn but continue)

### Step 8: Add Comments

Create Linear comment for audit trail:

```javascript
// Step 4b: Add Comment to Linear

const commentResult = await Task('linear-operations', `
operation: create_comment
params:
  issue_id: "${issueId}"
  body: |
    ## [Comment Title]

    [Comment content with markdown formatting]

    **Key Details**:
    - Field 1: Value 1
    - Field 2: Value 2

    **Next Steps**:
    - Action 1
    - Action 2
context:
  command: "[command-name]"
  purpose: "Recording [action]"
`)

if (!commentResult.success) {
  console.warn("⚠️  Failed to add comment (non-blocking)")
}
```

**Key Points**:
- Use markdown formatting in comments
- Include structured information
- Record timestamp and actor
- Non-blocking (warn on failure)

### Step 9: Display Results

Show clear results with formatting:

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [Command] Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId}
📝 Title: ${title}
📊 Status: ${newStatus}
${progress ? `🎯 Progress: ${progress.completed}/${progress.total} (${progress.percent}%)` : ''}

[Command-specific summary]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Key Points**:
- Use consistent formatting (━ for headers)
- Use emoji for visual clarity
- Include key information (issue, status, progress)
- Keep it concise (5-10 lines max)

### Step 10: Interactive Next Actions

Use AskUserQuestion for next steps:

```javascript
// Step 5: Display Results & Interactive Menu

console.log("")
console.log("💡 What's Next?")
console.log("───────────────")
console.log("")

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
    // Execute primary action
    // Either inline logic or delegate to another command
    break

  case "Secondary Action":
    // Execute secondary action
    break

  case "View Status":
    // Display status or delegate to utils:status
    break
}
```

**Key Points**:
- Always offer 2-4 options
- Mark recommended option in description
- Include command name in description
- Handle all options

---

## Linear Subagent Integration Patterns

### Pattern 1: Simple Read (Cached)

```yaml
Task(linear-operations): `
operation: get_issue
params:
  issue_id: "${issueId}"
context:
  cache: true
  command: "${COMMAND_NAME}"
`
```

**Use When**: Fetching issue state for display or logic

### Pattern 2: Create Issue (Complex)

```yaml
Task(linear-operations): `
operation: create_issue
params:
  team: "${TEAM_NAME}"
  title: "${TITLE}"
  description: |
    ${DESCRIPTION}
  state: "${STATE_NAME}"
  labels:
    - "${LABEL1}"
    - "${LABEL2}"
  assignee: "me"
context:
  command: "${COMMAND_NAME}"
  purpose: "Creating new task"
`
```

**Use When**: Creating issue with labels and state

### Pattern 3: Batch Update

```yaml
Task(linear-operations): `
operation: update_issue
params:
  issue_id: "${issueId}"
  ${title ? `title: "${title}"` : ''}
  ${state ? `state: "${state}"` : ''}
  ${labels ? `labels:\n${labels.map(l => `    - "${l}"`).join('\n')}` : ''}
context:
  command: "${COMMAND_NAME}"
`
```

**Use When**: Updating multiple fields at once

### Pattern 4: Create Comment

```yaml
Task(linear-operations): `
operation: create_comment
params:
  issue_id: "${issueId}"
  body: |
    ## ${TITLE}

    ${CONTENT}
context:
  command: "${COMMAND_NAME}"
`
```

**Use When**: Recording actions or progress

---

## Testing Checklist

### Per Command

- [ ] **Argument Parsing**
  - [ ] Valid issue ID provided
  - [ ] Invalid issue ID provided
  - [ ] No issue ID (git detection success)
  - [ ] No issue ID (git detection failure)
  - [ ] Edge cases (special characters, etc.)

- [ ] **Linear Operations**
  - [ ] Issue fetch successful
  - [ ] Issue fetch failed (404)
  - [ ] Issue fetch failed (network error)
  - [ ] Update successful
  - [ ] Update failed
  - [ ] Comment creation successful
  - [ ] Comment creation failed

- [ ] **Mode Detection**
  - [ ] Each valid status maps to correct mode
  - [ ] Invalid status handled gracefully
  - [ ] Unknown status defaults correctly

- [ ] **Git Integration**
  - [ ] Branch detection successful
  - [ ] Branch detection failed (no pattern)
  - [ ] Branch detection failed (not git repo)

- [ ] **Agent Integration**
  - [ ] Smart agent selected correctly
  - [ ] Agent provides useful output
  - [ ] Agent failure handled gracefully

- [ ] **Interactive Menu**
  - [ ] All options work correctly
  - [ ] Option execution successful
  - [ ] Option execution failed

### Token Budget Validation

- [ ] Measure actual token usage
- [ ] Compare with budget estimate
- [ ] Within 15% of target
- [ ] Track cache hit rate
- [ ] Verify subagent optimizations

### User Experience

- [ ] Error messages clear and actionable
- [ ] Success messages informative
- [ ] Interactive flow intuitive
- [ ] Performance feels fast (<5s)

---

## Common Pitfalls

### Pitfall 1: Over-Fetching Data

**Bad**:
```javascript
const result = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: true
  include_attachments: true
  include_children: true
`)
```

**Good**:
```javascript
const result = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: false  # Only if needed
`)
```

**Why**: Each expansion adds tokens and latency

### Pitfall 2: Multiple Separate Updates

**Bad**:
```javascript
await Task('linear-operations', `operation: update_issue\nparams:\n  issue_id: "${issueId}"\n  state: "In Progress"`)
await Task('linear-operations', `operation: update_issue\nparams:\n  issue_id: "${issueId}"\n  labels: ["planning"]`)
await Task('linear-operations', `operation: update_issue\nparams:\n  issue_id: "${issueId}"\n  assignee: "me"`)
```

**Good**:
```javascript
await Task('linear-operations', `
operation: update_issue
params:
  issue_id: "${issueId}"
  state: "In Progress"
  labels: ["planning"]
  assignee: "me"
`)
```

**Why**: Single call = 1 MCP operation, 3x faster

### Pitfall 3: Blocking on Non-Critical Errors

**Bad**:
```javascript
const commentResult = await Task('linear-operations', `...`)
if (!commentResult.success) {
  console.error("❌ Failed to create comment")
  process.exit(1)  // BLOCKS ENTIRE WORKFLOW
}
```

**Good**:
```javascript
const commentResult = await Task('linear-operations', `...`)
if (!commentResult.success) {
  console.warn("⚠️  Failed to create comment (non-blocking)")
  // Continue execution
}
```

**Why**: Comment failure shouldn't break workflow

### Pitfall 4: Not Using Caching

**Bad**:
```javascript
const result = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
context:
  cache: false  # WHY?!
`)
```

**Good**:
```javascript
const result = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
context:
  cache: true  # 85-95% hit rate
`)
```

**Why**: Caching reduces tokens by 50-70%

### Pitfall 5: Unclear Error Messages

**Bad**:
```javascript
console.error("❌ Error")
process.exit(1)
```

**Good**:
```javascript
console.error(`❌ Error: ${result.error?.message || 'Failed to fetch issue'}`)

if (result.error?.suggestions) {
  console.log("")
  console.log("Suggestions:")
  result.error.suggestions.forEach(s => console.log(`  • ${s}`))
}

console.log("")
console.log("Please try:")
console.log("  /ccpm:[command] PROJ-123")
process.exit(1)
```

**Why**: Users need actionable guidance

---

## Token Budget Estimation

Use this formula to estimate token budget:

```
Total Tokens = BASE + PARSE + LINEAR + LOGIC + AGENTS + DISPLAY

Where:
- BASE = 200 (frontmatter, imports, safety)
- PARSE = 200 (argument parsing, validation)
- LINEAR = 200-600 (subagent calls, depends on caching)
- LOGIC = 400-800 (mode detection, business logic)
- AGENTS = 0-2000 (smart agent invocations, if any)
- DISPLAY = 600 (results, interactive menu)

Example for /ccpm:work (START mode):
BASE = 200
PARSE = 200
LINEAR = 200 (cached get_issue) + 300 (update_issue) + 250 (create_comment) = 750
LOGIC = 300
AGENTS = 1500 (codebase analysis)
DISPLAY = 600
TOTAL = 3550 tokens

With 15% safety margin: ~4100 tokens
Target budget: 5000 tokens ✅
```

---

## Migration Checklist

### Pre-Migration

- [ ] Read PSN-30 architecture document
- [ ] Understand current command behavior
- [ ] Identify all modes and edge cases
- [ ] Map Linear operations needed
- [ ] Identify agent integration points
- [ ] Estimate token budget

### During Implementation

- [ ] Create new command file
- [ ] Implement argument parsing
- [ ] Integrate Linear subagent
- [ ] Implement mode logic
- [ ] Add agent integration
- [ ] Implement interactive menu
- [ ] Add comprehensive comments
- [ ] Test all scenarios

### Post-Implementation

- [ ] Measure token usage
- [ ] Validate against budget
- [ ] Test with real workflows
- [ ] Collect user feedback
- [ ] Update documentation
- [ ] Add migration hint to old command

---

## Support & Questions

If you encounter issues during implementation:

1. **Check the architecture doc** - Most patterns are documented
2. **Review existing implementations** - Look at `/ccpm:work` or `/ccpm:sync`
3. **Test incrementally** - Don't implement all at once
4. **Measure tokens** - Track actual usage vs estimates
5. **Ask for help** - Tag backend-architect agent if stuck

---

**End of Implementation Guide**
