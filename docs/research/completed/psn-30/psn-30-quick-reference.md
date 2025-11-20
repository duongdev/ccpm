# PSN-30 Quick Reference Card

**For**: Quick lookup during command implementation
**Related**: PSN-30 Architecture, PSN-30 Implementation Guide

---

## Token Budget Targets

| Command | Target Tokens | Baseline | Reduction |
|---------|--------------|----------|-----------|
| `/ccpm:work` | ~5,000 | ~15,000 | 67% |
| `/ccpm:sync` | ~4,500 | ~12,000 | 63% |
| `/ccpm:plan` (create) | ~7,000 | ~20,000 | 65% |
| `/ccpm:plan` (plan) | ~6,500 | ~18,000 | 64% |
| `/ccpm:plan` (update) | ~5,500 | ~16,000 | 66% |
| `/ccpm:verify` | ~5,500 | ~14,000 | 61% |
| `/ccpm:done` | ~4,800 | ~13,000 | 63% |

---

## Standard Argument Parsing

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

---

## Linear Subagent Patterns

### Get Issue (Cached)

```yaml
Task(linear-operations): `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: false
context:
  cache: true
  command: "${COMMAND_NAME}"
`
```

**Tokens**: 200 (cached), 600 (uncached)
**Performance**: <50ms (cached), <500ms (uncached)

### Create Issue

```yaml
Task(linear-operations): `
operation: create_issue
params:
  team: "${TEAM}"
  title: "${TITLE}"
  description: |
    ${DESCRIPTION}
  state: "${STATE}"
  labels:
    - "${LABEL1}"
    - "${LABEL2}"
  assignee: "me"
context:
  command: "${COMMAND_NAME}"
`
```

**Tokens**: 400-600
**Operations**: Validates team, state, labels → Creates issue

### Update Issue (Batched)

```yaml
Task(linear-operations): `
operation: update_issue
params:
  issue_id: "${issueId}"
  state: "${STATE}"
  labels:
    - "${LABEL1}"
    - "${LABEL2}"
context:
  command: "${COMMAND_NAME}"
`
```

**Tokens**: 300-500
**Operations**: Batches all updates into single call

### Create Comment

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

**Tokens**: 250
**Operations**: Direct comment creation

---

## Smart Agent Selection

```javascript
// For technical analysis, let smart-agent-selector choose
const analysis = await Task(`
Analyze the codebase for: ${issue.title}

Context:
${issue.description}

Identify:
- Files to modify
- Dependencies
- Testing requirements
`)
```

**Tokens**: 1,500-2,000
**Agent Selection**: Automatic (backend-architect, frontend-developer, etc.)

---

## Error Handling

```javascript
const result = await Task('linear-operations', `...`)

if (!result.success) {
  console.error(`❌ Error: ${result.error?.message || 'Failed'}`)

  if (result.error?.suggestions) {
    console.log("")
    console.log("Suggestions:")
    result.error.suggestions.forEach(s => console.log(`  • ${s}`))
  }

  process.exit(1)
}
```

---

## Interactive Menu

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
      }
    ]
  }]
})

switch (answer) {
  case "Continue Work":
    // Execute
    break
  case "Save Progress":
    // Execute
    break
}
```

---

## Token Budget Calculator

```
Total = BASE + PARSE + LINEAR + LOGIC + AGENTS + DISPLAY

BASE = 200
PARSE = 200
LINEAR = 200-600 (depends on caching)
LOGIC = 400-800 (depends on complexity)
AGENTS = 0-2000 (if technical analysis needed)
DISPLAY = 600

Example:
200 + 200 + 750 + 300 + 1500 + 600 = 3550 tokens
With 15% margin: ~4100 tokens
```

---

## Common Operations Token Costs

| Operation | Tokens | Notes |
|-----------|--------|-------|
| Argument parsing | 200 | Standard pattern |
| Git detection | 150 | Bash + parsing |
| Linear get_issue (cached) | 200 | With caching |
| Linear get_issue (uncached) | 600 | Full fetch |
| Linear create_issue | 400 | With 2-3 labels |
| Linear update_issue | 300 | Batch 3-4 fields |
| Linear create_comment | 250 | Standard comment |
| Smart agent analysis | 1,500 | Codebase analysis |
| Display + menu | 600 | Formatted output |

---

## Mode Detection Pattern

```javascript
const MODE_A = ['Status1', 'Status2']
const MODE_B = ['Status3', 'Status4']

let mode

if (MODE_A.includes(status)) {
  mode = 'mode_a'
  console.log("✅ Mode A: [description]")
} else if (MODE_B.includes(status)) {
  mode = 'mode_b'
  console.log("✅ Mode B: [description]")
} else {
  console.log(`ℹ️  Unknown status: ${status}`)
  mode = 'mode_b' // Default fallback
}
```

---

## Git Operations

### Detect Issue from Branch

```javascript
// From _shared-workflow-state.md
const detection = detectIssueFromBranch()

if (detection.success) {
  console.log(`🔍 Detected: ${detection.issueId}`)
  const issueId = detection.issueId
}
```

### Detect Uncommitted Changes

```javascript
// From _shared-workflow-state.md
const changes = detectUncommittedChanges()

if (changes.hasChanges) {
  console.log(`⚠️  ${changes.count} uncommitted files`)
  console.log(changes.summary)
}
```

### Check if Branch Pushed

```javascript
// From _shared-workflow-state.md
const isPushed = isBranchPushed()

if (!isPushed) {
  console.error("❌ Branch not pushed to remote")
  process.exit(1)
}
```

---

## Display Formatting

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ [Command] Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId}
📝 Title: ${title}
📊 Status: ${status}

[Summary content]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Emoji Guide**:
- ✅ Success
- ❌ Error
- ⚠️  Warning
- ℹ️  Info
- 🔍 Detection
- 📋 Issue
- 📝 Title
- 📊 Status
- 🎯 Progress
- 🔄 Sync
- 🚀 Start

---

## Testing Checklist

- [ ] Valid issue ID
- [ ] Invalid issue ID
- [ ] Git detection success
- [ ] Git detection failure
- [ ] Linear fetch success
- [ ] Linear fetch failure
- [ ] Mode detection for all statuses
- [ ] Update success
- [ ] Update failure
- [ ] Interactive menu works
- [ ] Token budget within target

---

## Common Pitfalls

❌ **Over-fetching**: Don't set `include_comments: true` unless needed
❌ **Multiple updates**: Batch into single `update_issue` call
❌ **Blocking errors**: Use `console.warn` for non-critical failures
❌ **No caching**: Always `cache: true` for read operations
❌ **Vague errors**: Include suggestions and next steps

---

## When to Use What

### Use Linear Subagent (Always)
- All Linear operations (get, create, update, comment)
- Operations requiring validation (state, labels)
- Batch operations

### Use Smart Agent Selection (Sometimes)
- Technical analysis (codebase review)
- Code generation
- Design decisions
- Complex problem solving

### Use Inline Logic (Often)
- Simple status checks
- Git operations
- Display formatting
- Mode detection
- Argument parsing

---

## Phase 1 Commands (Week 1)

1. `/ccpm:work` - Start or resume work
   - Target: 5,000 tokens (67% reduction)
   - Modes: START | RESUME

2. `/ccpm:sync` - Save progress
   - Target: 4,500 tokens (63% reduction)
   - Modes: Single mode

3. `/ccpm:done` - Finalize task
   - Target: 4,800 tokens (63% reduction)
   - Modes: Single mode

---

## Quick Links

- **Architecture**: `docs/architecture/psn-30-natural-command-direct-implementation.md`
- **Implementation Guide**: `docs/development/psn-30-implementation-guide.md`
- **Linear Subagent**: `agents/linear-operations.md`
- **Workflow State**: `commands/_shared-workflow-state.md`
- **Linear Helpers**: `commands/_shared-linear-helpers.md`

---

**End of Quick Reference**
