---
description: Smart work command - start or resume work (optimized)
allowed-tools: [Bash, Task]
argument-hint: "[issue-id]"
---

# /ccpm:work - Start or Resume Work

**Token Budget:** ~5,000 tokens (vs ~15,000 baseline) | **67% reduction**

Intelligent command that detects whether to start new work or resume in-progress tasks.

## Mode Detection

- **START**: Issue status is Planning/Backlog/Todo/Planned → Initialize implementation
- **RESUME**: Issue status is In Progress/In Development/Doing → Show progress and next action
- **ERROR**: Issue status is Done/Completed/Cancelled → Cannot work on completed tasks

## Usage

```bash
# Auto-detect issue from git branch
/ccpm:work

# Explicit issue ID
/ccpm:work PSN-29

# Examples
/ccpm:work PROJ-123     # Start or resume PROJ-123
/ccpm:work              # Auto-detect from branch name "feature/PSN-29-add-auth"
```

## Implementation

### Step 1: Parse Arguments & Detect Context

```javascript
// Parse issue ID from arguments or git branch
let issueId = args[0];

if (!issueId) {
  // Attempt to extract from git branch name
  const branch = await Bash('git rev-parse --abbrev-ref HEAD');
  const match = branch.match(/([A-Z]+-\d+)/);

  if (!match) {
    return error('Could not detect issue ID. Usage: /ccpm:work [ISSUE-ID]');
  }

  issueId = match[1];
  console.log(`📌 Detected issue from branch: ${issueId}`);
}

// Validate format
if (!/^[A-Z]+-\d+$/.test(issueId)) {
  return error(`Invalid issue ID format: ${issueId}. Expected format: PROJ-123`);
}
```

### Step 2: Fetch Issue via Linear Subagent

```yaml
Task(ccpm:linear-operations): `
operation: get_issue
params:
  issueId: "${issueId}"
context:
  cache: true
  command: "work"
`
```

**Store response as `issue` object** containing:
- `issue.id` - Internal Linear ID
- `issue.identifier` - Human-readable ID (e.g., PSN-29)
- `issue.title` - Issue title
- `issue.description` - Full description with checklist
- `issue.state.name` - Current status name
- `issue.state.id` - Status ID
- `issue.labels` - Array of label objects
- `issue.team.id` - Team ID

**Error handling:**
```javascript
if (subagentResponse.error) {
  console.log(`❌ Error fetching issue: ${subagentResponse.error.message}`);
  console.log('\nSuggestions:');
  subagentResponse.error.suggestions.forEach(s => console.log(`  - ${s}`));
  return;
}

const issue = subagentResponse.issue;
```

### Step 3: Detect Mode

```javascript
const status = issue.state.name;

const startStatuses = ['Planning', 'Backlog', 'Todo', 'Planned', 'Not Started'];
const resumeStatuses = ['In Progress', 'In Development', 'Doing', 'Started'];
const completeStatuses = ['Done', 'Completed', 'Closed', 'Cancelled'];

let mode;
if (startStatuses.includes(status)) {
  mode = 'START';
} else if (resumeStatuses.includes(status)) {
  mode = 'RESUME';
} else if (completeStatuses.includes(status)) {
  console.log(`❌ Cannot work on completed task: ${issueId}`);
  console.log(`Status: ${status}`);
  console.log('\nThis task is already complete. Did you mean to start a different task?');
  return;
} else {
  // Unknown status - default to RESUME
  mode = 'RESUME';
}

console.log(`\n🎯 Mode: ${mode}`);
console.log(`📋 Issue: ${issue.identifier} - ${issue.title}`);
console.log(`📊 Status: ${status}\n`);
```

### Step 4A: START Mode Implementation

```yaml
## START Mode: Initialize Implementation

1. Update issue status and labels (batch operation):

Task(ccpm:linear-operations): `
operation: update_issue
params:
  issueId: "${issueId}"
  state: "In Progress"
  labels: ["implementation"]
context:
  cache: true
  command: "work"
`

Display: "✅ Updated status: Planning → In Progress"

2. Analyze codebase with smart agent selection:

Task: `
Analyze the codebase to create an implementation plan for: ${issue.title}

Context:
- Issue: ${issueId}
- Description:
${issue.description}

Your task:
1. Identify files that need to be modified
2. List dependencies and imports needed
3. Outline testing strategy
4. Note potential challenges or risks
5. Estimate complexity (low/medium/high)

Provide a structured implementation plan with specific file paths and line numbers where possible.
`

Note: The smart-agent-selector hook will automatically choose the optimal agent:
- backend-architect for API/backend tasks
- frontend-developer for UI/React tasks
- mobile-developer for mobile tasks
- etc.

3. Store the plan and add comment via Linear subagent:

Task(ccpm:linear-operations): `
operation: create_comment
params:
  issueId: "${issueId}"
  body: |
    ## 🚀 Implementation Started

    **Status:** Planning → In Progress

    ### Implementation Plan

    ${analysisResult}

    ---
    *Started via /ccpm:work*
context:
  command: "work"
`

Display: "✅ Added implementation plan to Linear"

4. Display next actions:

console.log('\n═══════════════════════════════════════');
console.log('🎯 Implementation Started');
console.log('═══════════════════════════════════════\n');
console.log('📝 Plan added to Linear issue');
console.log('\n💡 Next Steps:');
console.log('  1. Review the implementation plan above');
console.log('  2. Start coding');
console.log('  3. Use /ccpm:sync to save progress');
console.log('  4. Use /ccpm:verify when ready for review');
console.log('\n📌 Quick Commands:');
console.log(`  /ccpm:sync "${issueId}" "progress update"`);
console.log(`  /ccpm:commit "${issueId}"`);
console.log(`  /ccpm:verify "${issueId}"`);
```

### Step 4B: RESUME Mode Implementation

```yaml
## RESUME Mode: Show Progress and Next Action

1. Calculate progress from checklist:

const description = issue.description || '';
const checklistItems = description.match(/- \[([ x])\] .+/g) || [];
const totalItems = checklistItems.length;
const completedItems = checklistItems.filter(item => item.includes('[x]')).length;
const progress = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : 0;

2. Determine next action:

let nextAction = null;
let suggestion = null;

if (progress === 100) {
  suggestion = 'All checklist items complete! Ready for verification.';
  nextAction = '/ccpm:verify';
} else {
  // Find first incomplete checklist item
  const incompleteItem = checklistItems.find(item => item.includes('[ ]'));
  if (incompleteItem) {
    const itemText = incompleteItem.replace(/- \[ \] /, '');
    nextAction = `Continue work on: ${itemText}`;
  } else {
    suggestion = 'No checklist found. Continue implementation.';
  }
}

3. Display progress and suggestion:

console.log('\n═══════════════════════════════════════');
console.log('📊 Work in Progress');
console.log('═══════════════════════════════════════\n');
console.log(`📋 Issue: ${issue.identifier} - ${issue.title}`);
console.log(`📊 Status: ${issue.state.name}`);
console.log(`✅ Progress: ${progress}% (${completedItems}/${totalItems} items)\n`);

if (checklistItems.length > 0) {
  console.log('📝 Checklist:\n');
  checklistItems.forEach(item => {
    const isComplete = item.includes('[x]');
    const icon = isComplete ? '✅' : '⏳';
    const text = item.replace(/- \[([ x])\] /, '');
    console.log(`  ${icon} ${text}`);
  });
  console.log('');
}

if (suggestion) {
  console.log(`💡 Suggestion: ${suggestion}\n`);
}

if (nextAction) {
  console.log(`🎯 Next Action: ${nextAction}\n`);
}

4. Interactive menu:

console.log('Available Actions:');
console.log('  1. ⭐ Sync progress      - /ccpm:sync');
console.log('  2. 📝 Git commit         - /ccpm:commit');
console.log('  3. ✅ Run verification   - /ccpm:verify');
console.log('  4. 🔍 View issue details - /ccpm:utils:status ' + issueId);
console.log('  5. 🛠️  Fix issues         - /ccpm:verification:fix ' + issueId);
console.log('\n📌 Quick Commands:');
console.log(`  /ccpm:sync "completed ${itemText}"`);
console.log(`  /ccpm:commit "feat: ${issue.title.toLowerCase()}"`);

if (progress === 100) {
  console.log('\n⭐ Recommended: /ccpm:verify (checklist complete)');
}
```

### Step 5: Interactive Menu

Display menu based on mode:

**START mode menu:**
```
Available Actions:
  1. ⭐ Start coding        - Begin implementation
  2. 📝 Sync progress       - /ccpm:sync
  3. 🔍 View issue details  - /ccpm:utils:status PSN-29

Quick Commands:
  /ccpm:sync "implemented X feature"
  /ccpm:commit "feat: add user authentication"
```

**RESUME mode menu:**
```
Available Actions:
  1. ⭐ Sync progress       - /ccpm:sync
  2. 📝 Git commit          - /ccpm:commit
  3. ✅ Run verification    - /ccpm:verify
  4. 🔍 View issue details  - /ccpm:utils:status PSN-29
  5. 🛠️  Fix issues          - /ccpm:verification:fix PSN-29

Quick Commands:
  /ccpm:sync "progress update"
  /ccpm:commit
  /ccpm:verify
```

## Error Handling

### Invalid Issue ID Format
```
❌ Invalid issue ID format: proj123
Expected format: PROJ-123 (uppercase letters, hyphen, numbers)
```

### Issue Not Found
```
❌ Error fetching issue: Issue not found

Suggestions:
  - Verify the issue ID is correct
  - Check you have access to this Linear team
  - Ensure the issue hasn't been deleted
```

### Git Branch Detection Failed
```
❌ Could not detect issue ID from git branch

Current branch: main

Usage: /ccpm:work [ISSUE-ID]

Example: /ccpm:work PSN-29
```

### Completed Task
```
❌ Cannot work on completed task: PSN-29
Status: Done

This task is already complete. Did you mean to start a different task?
```

### Network Errors
```
❌ Error fetching issue: Network request failed

Suggestions:
  - Check your internet connection
  - Verify Linear MCP server is running
  - Try again in a moment
```

## Examples

### Example 1: Start work (auto-detect from branch)

```bash
# Current branch: feature/PSN-29-add-auth
/ccpm:work

# Output:
# 📌 Detected issue from branch: PSN-29
#
# 🎯 Mode: START
# 📋 Issue: PSN-29 - Add user authentication
# 📊 Status: Planning
#
# ✅ Updated status: Planning → In Progress
#
# [Smart agent analyzes codebase...]
#
# ✅ Added implementation plan to Linear
#
# ═══════════════════════════════════════
# 🎯 Implementation Started
# ═══════════════════════════════════════
#
# 📝 Plan added to Linear issue
#
# 💡 Next Steps:
#   1. Review the implementation plan above
#   2. Start coding
#   3. Use /ccpm:sync to save progress
#   4. Use /ccpm:verify when ready for review
```

### Example 2: Resume work (explicit issue ID)

```bash
/ccpm:work PSN-29

# Output:
# 🎯 Mode: RESUME
# 📋 Issue: PSN-29 - Add user authentication
# 📊 Status: In Progress
#
# ═══════════════════════════════════════
# 📊 Work in Progress
# ═══════════════════════════════════════
#
# 📋 Issue: PSN-29 - Add user authentication
# 📊 Status: In Progress
# ✅ Progress: 60% (3/5 items)
#
# 📝 Checklist:
#
#   ✅ Create auth endpoints
#   ✅ Add JWT validation
#   ✅ Implement login flow
#   ⏳ Add password reset
#   ⏳ Write tests
#
# 🎯 Next Action: Continue work on: Add password reset
#
# Available Actions:
#   1. ⭐ Sync progress      - /ccpm:sync
#   2. 📝 Git commit         - /ccpm:commit
#   3. ✅ Run verification   - /ccpm:verify
```

### Example 3: Resume completed work (error)

```bash
/ccpm:work PSN-28

# Output:
# 🎯 Mode: ERROR
# 📋 Issue: PSN-28 - Fix navigation bug
# 📊 Status: Done
#
# ❌ Cannot work on completed task: PSN-28
# Status: Done
#
# This task is already complete. Did you mean to start a different task?
```

## Token Budget Breakdown

| Section | Tokens | Notes |
|---------|--------|-------|
| Frontmatter & description | 100 | Minimal metadata |
| Step 1: Argument parsing | 300 | Git detection + validation |
| Step 2: Fetch issue | 400 | Linear subagent + error handling |
| Step 3: Mode detection | 200 | Status checks + display |
| Step 4A: START mode | 1,500 | Update + analysis + comment |
| Step 4B: RESUME mode | 1,000 | Progress + next action + menu |
| Step 5: Interactive menu | 600 | Mode-specific menus |
| Examples | 400 | 3 concise examples |
| Error handling | 500 | 5 error scenarios |
| **Total** | **~5,000** | **vs ~15,000 baseline (67% reduction)** |

## Key Optimizations

1. ✅ **No routing overhead** - Direct implementation of both modes
2. ✅ **Linear subagent** - All Linear ops cached (85-95% hit rate)
3. ✅ **Smart agent selection** - Automatic optimal agent choice for analysis
4. ✅ **Batch operations** - Single update_issue call (state + labels)
5. ✅ **Concise examples** - Only 3 essential examples
6. ✅ **Focused scope** - START mode simplified (no full agent discovery)

## Integration with Other Commands

- **After /ccpm:plan** → Use /ccpm:work to start implementation
- **During work** → Use /ccpm:sync to save progress
- **Git commits** → Use /ccpm:commit for conventional commits
- **Before completion** → Use /ccpm:verify for quality checks
- **Finalize** → Use /ccpm:done to create PR and complete

## Notes

- **Git branch detection**: Extracts issue ID from branch names like `feature/PSN-29-add-auth`
- **Smart agent selection**: Automatically invokes optimal agent based on task type
- **Progress tracking**: Calculates from checklist items in issue description
- **Caching**: Linear subagent caches issue data for 85-95% faster subsequent operations
- **Error recovery**: Provides actionable suggestions for all error scenarios
