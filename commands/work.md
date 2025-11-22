---
description: Smart work - start or resume with v1.0 workflow rules
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[issue-id]"
---

# /ccpm:work - Start or Resume Work

Intelligent command that detects whether to start new work or resume in-progress tasks.

## 🎯 v1.0 Interactive Workflow Rules

**WORK Mode Philosophy:**
- **Git branch safety** - Check protected branches before creating new branches
- **Phase planning** - Ask which phases to do now vs later
- **Document uncertainties** - Immediately note questions/unknowns in Linear
- **Regular progress updates** - Sync to Linear frequently
- **Proactive subagents** - Invoke specialized agents as needed
- **Parallel execution** - Organize independent tasks to run together
- **No auto-commit** - Only commit on explicit user request

## Mode Detection

- **START**: Status is Planning/Backlog/Todo/Planned → Initialize implementation
- **RESUME**: Status is In Progress/In Development/Doing → Show progress and next action
- **ERROR**: Status is Done/Completed/Cancelled → Cannot work on completed tasks

## Usage

```bash
# Auto-detect from git branch
/ccpm:work

# Explicit issue ID
/ccpm:work PSN-29

# Examples
/ccpm:work PROJ-123     # Start or resume PROJ-123
/ccpm:work              # Auto-detect from "feature/PSN-29-add-auth"
```

## Implementation

### Step 1: Parse Arguments & Detect Context

```javascript
let issueId = args[0];

if (!issueId) {
  const branch = await Bash('git rev-parse --abbrev-ref HEAD');
  const match = branch.match(/([A-Z]+-\d+)/);

  if (!match) {
    return error('Could not detect issue ID. Usage: /ccpm:work [ISSUE-ID]');
  }

  issueId = match[1];
  console.log(`📌 Detected issue from branch: ${issueId}`);
}

if (!/^[A-Z]+-\d+$/.test(issueId)) {
  return error(`Invalid issue ID format: ${issueId}. Expected format: PROJ-123`);
}
```

### Step 2: Fetch Issue via Linear Subagent

**Use the Task tool:**

Invoke `ccpm:linear-operations`:

```
operation: get_issue
params:
  issueId: "{issue ID from step 1}"
context:
  cache: true
  command: "work"
```

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
  mode = 'RESUME';
}

console.log(`\n🎯 Mode: ${mode}`);
console.log(`📋 Issue: ${issue.identifier} - ${issue.title}`);
console.log(`📊 Status: ${status}\n`);
```

### Step 4A: START Mode - Initialize Implementation

```yaml
## START Mode with v1.0 workflow

1. Git branch safety check (v1.0 workflow):

const currentBranch = await Bash('git rev-parse --abbrev-ref HEAD');
const protectedBranches = ['main', 'master', 'develop', 'staging', 'production'];

if (protectedBranches.includes(currentBranch)) {
  console.log(`⚠️  You are on protected branch: ${currentBranch}`);
  console.log(`\nRecommended: Create a feature branch`);
  console.log(`  git checkout -b feature/${issueId.toLowerCase()}-${issue.title.toLowerCase().replace(/\s+/g, '-').substring(0, 30)}`);
  console.log(`\nProceed anyway? This will create commits on ${currentBranch}.`);

  // Use AskUserQuestion for confirmation
  AskUserQuestion({
    questions: [{
      question: `Create commits on protected branch ${currentBranch}?`,
      header: "Safety Check",
      multiSelect: false,
      options: [
        { label: "No, I'll create a branch", description: "Stop and let me create a feature branch first" },
        { label: "Yes, proceed", description: "I know what I'm doing, proceed on this branch" }
      ]
    }]
  });

  if (answer !== "Yes, proceed") {
    console.log('\n⏸️  Stopped. Create a feature branch and run /ccpm:work again.');
    return;
  }
}

Display: "✅ Git branch safe: ${currentBranch}"

2. Phase planning (v1.0 workflow):

Extract checklist from description:
const checklist = issue.description.match(/- \[ \] .+/g) || [];

if (checklist.length > 5) {
  console.log('\n📋 Implementation Checklist:');
  checklist.forEach((item, idx) => {
    const text = item.replace(/- \[ \] /, '');
    console.log(`  ${idx + 1}. ${text}`);
  });

  console.log('\n💡 This task has multiple phases. Which would you like to tackle first?');

  // Use AskUserQuestion for phase selection
  AskUserQuestion({
    questions: [{
      question: "Which phases to work on now?",
      header: "Phase Planning",
      multiSelect: true,
      options: checklist.slice(0, 4).map((item, idx) => ({
        label: `Phase ${idx + 1}`,
        description: item.replace(/- \[ \] /, '')
      }))
    }]
  });

  // Store selected phases for focused work
  const selectedPhases = answers;
  console.log(`\n✅ Focusing on: ${selectedPhases.join(', ')}`);
}

3. Update issue status:

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: update_issue
params:
  issueId: "{issue ID}"
  state: "In Progress"
  labels: ["implementation"]
context:
  cache: true
  command: "work"
```

Display: "✅ Updated status: ${issue.state.name} → In Progress"

4. Analyze codebase with smart agent:

Task: `
Analyze the codebase for: ${issue.title}

Context:
- Issue: ${issueId}
- Description: ${issue.description}
${selectedPhases ? `- Focus on: ${selectedPhases.join(', ')}` : ''}

Your task:
1. Identify files that need modification
2. List dependencies and imports needed
3. Note potential challenges or UNKNOWNS
4. Outline testing strategy
5. Estimate complexity (low/medium/high)

Provide structured plan with:
- **Files to modify** (with specific locations)
- **Dependencies** needed
- **Uncertainties** - flag anything unclear or needing decisions
- **Testing approach**
- **Complexity** with reasoning
`

Note: Smart-agent-selector automatically chooses optimal agent

5. Document uncertainties immediately (v1.0 workflow):

Extract uncertainties from analysis result:
const uncertainties = analysisResult.uncertainties || [];

if (uncertainties.length > 0) {
  console.log('\n⚠️  Uncertainties identified:');
  uncertainties.forEach((u, i) => console.log(`  ${i+1}. ${u}`));

  console.log('\nDocumenting in Linear issue...');

  **Use the Task tool to update description:**

  Invoke `ccpm:linear-operations`:
  ```
  operation: update_issue_description
  params:
    issueId: "{issue ID}"
    description: |
      {existing description}

      ## ⚠️ Uncertainties / Open Questions

      ${uncertainties.map((u, i) => `${i+1}. ${u}`).join('\n')}

      *Last updated: {timestamp}*
  context:
    command: "work"
  ```

  Display: "✅ Documented ${uncertainties.length} uncertainties in Linear"
}

6. Add concise comment to Linear (v1.0 strategy - shorter):

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: create_comment
params:
  issueId: "{issue ID}"
  body: |
    🚀 **Started** | ${currentBranch}

    **Focus**: ${selectedPhases ? selectedPhases.join(', ') : 'All phases'}
    **Files**: {count} files to modify
    ${uncertainties.length > 0 ? `**Uncertainties**: ${uncertainties.length} (see description)` : ''}

    _Use /ccpm:sync to update progress_
context:
  command: "work"
```

Display: "✅ Logged start in Linear"

7. Display next actions:

console.log('\n═══════════════════════════════════════');
console.log('🎯 Implementation Started');
console.log('═══════════════════════════════════════\n');
console.log(`📝 Working on: ${selectedPhases ? selectedPhases.join(', ') : 'All phases'}`);
console.log(`🌿 Branch: ${currentBranch}`);
console.log(`${uncertainties.length > 0 ? `⚠️  ${uncertainties.length} uncertainties documented` : '✅ No uncertainties'}`);
console.log('\n💡 Next Steps:');
console.log('  1. Review the implementation plan above');
console.log('  2. Start coding (no auto-commit - you decide when)');
console.log('  3. Use /ccpm:sync frequently to save progress');
console.log('  4. Use /ccpm:commit when ready to commit');
console.log('\n📌 Quick Commands:');
console.log(`  /ccpm:sync "progress update"`);
console.log(`  /ccpm:commit`);
console.log(`  /ccpm:verify`);
```

### Step 4B: RESUME Mode - Show Progress

```yaml
## RESUME Mode with v1.0 workflow

1. Fetch recent comments for accurate progress (v1.0 fix):

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: get_comments
params:
  issueId: "{issue ID}"
context:
  cache: false  # Always fresh for resume
  command: "work"
  purpose: "Get accurate progress from comments"
```

Extract latest progress updates:
- Last sync time
- Recently completed items
- Current focus areas
- Any blockers mentioned

2. Calculate progress from checklist:

const description = issue.description || '';
const checklistItems = description.match(/- \[([ x])\] .+/g) || [];
const totalItems = checklistItems.length;
const completedItems = checklistItems.filter(item => item.includes('[x]')).length;
const progress = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : 0;

3. Check for uncertainties in description:

const hasUncertainties = description.includes('## ⚠️ Uncertainties');
const uncertaintiesMatch = description.match(/## ⚠️ Uncertainties[^]*?(?=\n##|\n\*|$)/);
const uncertaintiesList = uncertaintiesMatch
  ? uncertaintiesMatch[0].match(/\d+\. .+/g) || []
  : [];

3. Determine next action:

let nextAction = null;
let suggestion = null;

if (uncertaintiesList.length > 0) {
  suggestion = `⚠️  ${uncertaintiesList.length} uncertainties need resolution`;
  nextAction = 'Resolve uncertainties first, then continue implementation';
} else if (progress === 100) {
  suggestion = 'All checklist items complete! Ready for verification.';
  nextAction = '/ccpm:verify';
} else {
  const incompleteItem = checklistItems.find(item => item.includes('[ ]'));
  if (incompleteItem) {
    const itemText = incompleteItem.replace(/- \[ \] /, '');
    nextAction = `Continue work on: ${itemText}`;
  } else {
    suggestion = 'No checklist found. Continue implementation.';
  }
}

4. Display progress and next action with recent activity (v1.0 enhancement):

console.log('\n═══════════════════════════════════════');
console.log('📊 Work in Progress');
console.log('═══════════════════════════════════════\n');
console.log(`📋 Issue: ${issue.identifier} - ${issue.title}`);
console.log(`📊 Status: ${issue.state.name}`);
console.log(`✅ Progress: ${progress}% (${completedItems}/${totalItems} items)\n`);

// Display recent activity from comments (v1.0 fix)
if (comments && comments.length > 0) {
  const recentComments = comments.slice(-3).reverse(); // Last 3 comments
  console.log('📝 Recent Activity:\n');
  recentComments.forEach(comment => {
    const timestamp = new Date(comment.createdAt).toLocaleDateString();
    const preview = comment.body.split('\n')[0].substring(0, 60);
    const icon = comment.body.includes('🚀') ? '🚀'
               : comment.body.includes('🔄') ? '🔄'
               : comment.body.includes('✅') ? '✅'
               : '💬';
    console.log(`  ${icon} ${timestamp}: ${preview}...`);
  });
  console.log('');
}

if (uncertaintiesList.length > 0) {
  console.log('⚠️  Uncertainties:');
  uncertaintiesList.slice(0, 3).forEach(u => console.log(`  ${u}`));
  if (uncertaintiesList.length > 3) {
    console.log(`  ... and ${uncertaintiesList.length - 3} more\n`);
  }
  console.log('');
}

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

5. Interactive menu:

console.log('Available Actions:');
console.log('  1. ⭐ Sync progress      - /ccpm:sync');
console.log('  2. 📝 Git commit         - /ccpm:commit');
console.log('  3. ✅ Run verification   - /ccpm:verify');
console.log('  4. 🔍 View issue details - /ccpm:utils:status ' + issueId);
if (uncertaintiesList.length > 0) {
  console.log('  5. ❓ Update uncertainties - Edit issue description');
}
console.log('\n📌 Quick Commands:');
console.log(`  /ccpm:sync "progress update"`);
console.log(`  /ccpm:commit`);

if (progress === 100 && uncertaintiesList.length === 0) {
  console.log('\n⭐ Recommended: /ccpm:verify (checklist complete, no uncertainties)');
}
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

### Protected Branch Warning

```
⚠️  You are on protected branch: main

Recommended: Create a feature branch
  git checkout -b feature/psn-29-add-authentication

Proceed anyway? This will create commits on main.

[Interactive confirmation required]
```

## Examples

### Example 1: START with v1.0 workflow

```bash
/ccpm:work PSN-29

# Output:
# 🎯 Mode: START
# 📋 Issue: PSN-29 - Add user authentication
# 📊 Status: Planned
#
# ✅ Git branch safe: feature/psn-29-auth
#
# 📋 Implementation Checklist:
#   1. Create auth endpoints
#   2. Add JWT validation
#   3. Implement login flow
#   4. Add password reset
#   5. Write tests
#
# 💡 This task has multiple phases. Which would you like to tackle first?
#
# [Interactive phase selection]
#
# ✅ Focusing on: Phase 1, Phase 2
# ✅ Updated status: Planned → In Progress
#
# [Smart agent analyzes codebase...]
#
# ⚠️  Uncertainties identified:
#   1. Which OAuth providers to support?
#   2. Password reset flow requirements?
#
# ✅ Documented 2 uncertainties in Linear
# ✅ Logged start in Linear
#
# ═══════════════════════════════════════
# 🎯 Implementation Started
# ═══════════════════════════════════════
#
# 📝 Working on: Phase 1, Phase 2
# 🌿 Branch: feature/psn-29-auth
# ⚠️  2 uncertainties documented
#
# 💡 Next Steps:
#   1. Review the implementation plan above
#   2. Start coding (no auto-commit - you decide when)
#   3. Use /ccpm:sync frequently to save progress
```

### Example 2: RESUME with uncertainties

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
# ✅ Progress: 40% (2/5 items)
#
# ⚠️  Uncertainties:
#   1. Which OAuth providers to support?
#   2. Password reset flow requirements?
#
# 📝 Checklist:
#
#   ✅ Create auth endpoints
#   ✅ Add JWT validation
#   ⏳ Implement login flow
#   ⏳ Add password reset
#   ⏳ Write tests
#
# 💡 Suggestion: ⚠️  2 uncertainties need resolution
# 🎯 Next Action: Resolve uncertainties first, then continue implementation
#
# Available Actions:
#   1. ⭐ Sync progress      - /ccpm:sync
#   2. 📝 Git commit         - /ccpm:commit
#   3. ✅ Run verification   - /ccpm:verify
#   4. 🔍 View issue details - /ccpm:utils:status PSN-29
#   5. ❓ Update uncertainties - Edit issue description
```

### Example 3: Protected branch safety check

```bash
# On main branch
/ccpm:work PSN-30

# Output:
# 🎯 Mode: START
# 📋 Issue: PSN-30 - Implement feature X
#
# ⚠️  You are on protected branch: main
#
# Recommended: Create a feature branch
#   git checkout -b feature/psn-30-implement-feature-x
#
# Proceed anyway? This will create commits on main.
#
# [Interactive confirmation]
#
# Choose:
#   • No, I'll create a branch (recommended)
#   • Yes, proceed
#
# [User selects "No, I'll create a branch"]
#
# ⏸️  Stopped. Create a feature branch and run /ccpm:work again.
```

## Key Optimizations

1. ✅ **Direct implementation** - No routing overhead
2. ✅ **Linear subagent** - All ops cached (85-95% hit rate)
3. ✅ **Smart agent selection** - Automatic optimal agent choice
4. ✅ **v1.0 workflow** - Git safety, phase planning, uncertainty tracking
5. ✅ **Shorter Linear comments** - Concise status updates (not long reports)
6. ✅ **Uncertainty tracking** - Documented in description, not comments
7. ✅ **No auto-commit** - Explicit user control over git commits

## v1.0 Linear Comment Strategy

**OLD (verbose):**
```markdown
## 🚀 Implementation Started

**Status:** Planning → In Progress

### Implementation Plan

[500-1000 words of analysis...]

### Files to Modify
[Long list...]

### Testing Strategy
[Detailed strategy...]

---
*Started via /ccpm:work*
```

**NEW (concise):**
```markdown
🚀 **Started** | feature/psn-29-auth

**Focus**: Phase 1, Phase 2
**Files**: 8 files to modify
**Uncertainties**: 2 (see description)

_Use /ccpm:sync to update progress_
```

**Benefits:**
- ✅ 80% shorter comments
- ✅ Easier to scan Linear timeline
- ✅ Key info at a glance
- ✅ Details in description (single source of truth)
- ✅ Less noise in Linear feed

## Integration

- **After /ccpm:plan** → `/ccpm:work` to start implementation
- **During work** → `/ccpm:sync` to save progress (frequently!)
- **Git commits** → `/ccpm:commit` when ready (no auto-commit)
- **Before completion** → `/ccpm:verify` for quality checks
- **Finalize** → `/ccpm:done` to create PR and complete

## Notes

- **v1.0 workflow**: Git safety, phase planning, uncertainty tracking, no auto-commit
- **Git branch safety**: Checks protected branches, requires confirmation
- **Phase planning**: Interactive selection for large tasks (>5 items)
- **Uncertainty tracking**: Documented in issue description for visibility
- **Shorter comments**: 80% reduction, easier to scan timeline
- **Smart agents**: Automatic selection based on task type
- **Caching**: Linear subagent caches for 85-95% faster operations
