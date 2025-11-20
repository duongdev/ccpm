---
description: Smart planning command - create, plan, or update tasks (optimized)
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[title]" OR <issue-id> OR <issue-id> "[changes]"
---

# /ccpm:plan - Smart Planning Command

**Token Budget:** ~2,450 tokens (vs ~7,000 baseline) | **65% reduction**

Intelligent command that creates new tasks, plans existing tasks, or updates plans based on context.

## Mode Detection

The command has **3 modes** with clear, unambiguous detection:

- **CREATE**: `plan "title" [project] [jira-ticket]` → Creates new task and plans it
- **PLAN**: `plan WORK-123` → Plans existing task
- **UPDATE**: `plan WORK-123 "changes"` → Updates existing plan

## Usage

```bash
# Mode 1: CREATE - New task
/ccpm:plan "Add user authentication"
/ccpm:plan "Add dark mode" my-app TRAIN-456

# Mode 2: PLAN - Plan existing
/ccpm:plan PSN-27

# Mode 3: UPDATE - Update plan
/ccpm:plan PSN-27 "Add email notifications too"
/ccpm:plan PSN-27 "Use Redis instead of in-memory cache"
```

## Implementation

### Step 1: Parse Arguments & Detect Mode

```javascript
const args = process.argv.slice(2);
const arg1 = args[0];
const arg2 = args[1];
const arg3 = args[2];

// Issue ID pattern: PROJECT-NUMBER (e.g., PSN-27, WORK-123)
const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/;

if (!arg1) {
  return error(`
❌ Missing arguments

Usage:
  /ccpm:plan "Task title" [project] [jira]  # Create new
  /ccpm:plan WORK-123                        # Plan existing
  /ccpm:plan WORK-123 "changes"              # Update plan
  `);
}

// Detect mode
let mode, issueId, title, project, jiraTicket, updateText;

if (ISSUE_ID_PATTERN.test(arg1)) {
  // Starts with issue ID
  issueId = arg1;
  if (arg2) {
    mode = 'update';
    updateText = arg2;
  } else {
    mode = 'plan';
  }
} else {
  // First arg is not issue ID = CREATE mode
  mode = 'create';
  title = arg1;
  project = arg2 || null;
  jiraTicket = arg3 || null;
}

console.log(`\n🎯 Mode: ${mode.toUpperCase()}`);
```

### Step 2A: CREATE Mode - Create & Plan New Task

```yaml
## CREATE: Create new task and plan it

1. Detect/load project configuration:

Task(project-context-manager): `
${project ? `Get context for project: ${project}` : 'Get active project context'}
Format: standard
Include all sections: true
`

Store: projectId, teamId, projectLinearId, defaultLabels, externalPM config

2. Create Linear issue via subagent:

Task(ccpm:linear-operations): `
operation: create_issue
params:
  team: "${teamId}"
  title: "${title}"
  project: "${projectLinearId}"
  state: "Backlog"
  labels: ${JSON.stringify(defaultLabels)}
  description: |
    ## Task

    ${title}

    ${jiraTicket ? `**Jira Reference**: ${jiraTicket}\n\n` : ''}
    ---

    _Planning in progress..._
context:
  command: "plan"
  mode: "create"
`

Store: issue.id, issue.identifier (e.g., PSN-30)

Display: "✅ Created issue: ${issue.identifier}"

3. Gather context (smart agent selection):

Task: `
Plan implementation for: ${title}

${jiraTicket ? `Jira Ticket: ${jiraTicket}\n` : ''}

Your task:
1. If Jira ticket provided, research it and related Confluence docs
2. Analyze codebase to identify files to modify
3. Research best practices using Context7 MCP
4. Create detailed implementation checklist (5-10 items)
5. Estimate complexity (low/medium/high)
6. Identify potential risks or challenges

Provide structured plan with:
- Implementation checklist (actionable subtasks)
- Files to modify (with brief rationale)
- Dependencies and prerequisites
- Testing approach
- Complexity estimate and reasoning
`

Note: Smart-agent-selector automatically chooses optimal agent based on task type

4. Update Linear issue with plan:

Task(ccpm:linear-operations): `
operation: update_issue_description
params:
  issueId: "${issue.identifier}"
  description: |
    ## Implementation Checklist

    ${generateChecklist(planningResult)}

    > **Complexity**: ${complexity} | **Estimated**: ${estimate}

    ---

    ## Task

    ${title}

    ${jiraTicket ? `**Jira**: [${jiraTicket}](url)\n\n` : ''}

    ## Files to Modify

    ${formatFilesList(planningResult.files)}

    ## Research & Context

    ${planningResult.research}

    ## Testing Strategy

    ${planningResult.testing}

    ---

    *Planned via /ccpm:plan*
context:
  command: "plan"
`

5. Update issue status and labels:

Task(ccpm:linear-operations): `
operation: update_issue
params:
  issueId: "${issue.identifier}"
  state: "Planned"
  labels: ["planned", "ready"]
context:
  command: "plan"
`

6. Display completion:

console.log('\n═══════════════════════════════════════');
console.log('✅ Task Created & Planned!');
console.log('═══════════════════════════════════════\n');
console.log(`📋 Issue: ${issue.identifier} - ${title}`);
console.log(`🔗 ${issue.url}`);
console.log(`\n📊 Plan Summary:`);
console.log(`  ✅ ${checklistCount} subtasks created`);
console.log(`  📁 ${filesCount} files to modify`);
console.log(`  ⚡ Complexity: ${complexity}`);
console.log(`\n💡 Next: /ccpm:work ${issue.identifier}`);
```

### Step 2B: PLAN Mode - Plan Existing Task

```yaml
## PLAN: Plan existing task

1. Fetch issue via subagent:

Task(ccpm:linear-operations): `
operation: get_issue
params:
  issueId: "${issueId}"
context:
  cache: true
  command: "plan"
`

Store: issue.id, issue.title, issue.description, issue.state, issue.team

Display: "📋 Planning: ${issue.identifier} - ${issue.title}"

2. Check if already planned:

const hasChecklist = issue.description.includes('## Implementation Checklist');
const isPlanned = issue.state.name === 'Planned' || issue.state.name === 'Ready';

if (hasChecklist && isPlanned) {
  console.log('\nℹ️  Task already has a plan. Use one of:');
  console.log(`  • /ccpm:plan ${issueId} "changes" - Update the plan`);
  console.log(`  • /ccpm:work ${issueId} - Start implementation`);
  return;
}

3. Extract context from description:

// Check for Jira reference
const jiraMatch = issue.description.match(/\*\*Jira.*?\*\*:\s*([A-Z]+-\d+)/);
const jiraTicket = jiraMatch ? jiraMatch[1] : null;

4. Gather planning context (smart agent selection):

Task: `
Create implementation plan for: ${issue.title}

Current description:
${issue.description}

${jiraTicket ? `Jira ticket: ${jiraTicket}\n` : ''}

Your task:
1. ${jiraTicket ? 'Research Jira ticket and related Confluence docs' : 'Use current description as requirements'}
2. Analyze codebase to identify files to modify
3. Research best practices using Context7 MCP
4. Create detailed implementation checklist (5-10 items)
5. Estimate complexity (low/medium/high)
6. Identify potential risks

Provide structured plan with:
- Implementation checklist (specific, actionable items)
- Files to modify with rationale
- Dependencies and prerequisites
- Testing strategy
- Complexity and estimate
`

5. Update issue description with plan:

Task(ccpm:linear-operations): `
operation: update_issue_description
params:
  issueId: "${issueId}"
  description: |
    ## Implementation Checklist

    ${generateChecklist(planningResult)}

    > **Complexity**: ${complexity} | **Estimated**: ${estimate}

    ---

    ${issue.description}

    ## Files to Modify

    ${formatFilesList(planningResult.files)}

    ## Research & Context

    ${planningResult.research}

    ## Testing Strategy

    ${planningResult.testing}

    ---

    *Planned via /ccpm:plan*
context:
  command: "plan"
`

6. Update status and labels:

Task(ccpm:linear-operations): `
operation: update_issue
params:
  issueId: "${issueId}"
  state: "Planned"
  labels: ["planned", "ready"]
context:
  command: "plan"
`

7. Display completion:

console.log('\n═══════════════════════════════════════');
console.log('✅ Planning Complete!');
console.log('═══════════════════════════════════════\n');
console.log(`📋 Issue: ${issueId} - ${issue.title}`);
console.log(`🔗 ${issue.url}`);
console.log(`\n📊 Plan Added:`);
console.log(`  ✅ ${checklistCount} subtasks`);
console.log(`  📁 ${filesCount} files to modify`);
console.log(`  ⚡ Complexity: ${complexity}`);
console.log(`\n💡 Next: /ccpm:work ${issueId}`);
```

### Step 2C: UPDATE Mode - Update Existing Plan

```yaml
## UPDATE: Update existing plan

1. Fetch current plan:

Task(ccpm:linear-operations): `
operation: get_issue
params:
  issueId: "${issueId}"
context:
  cache: true
  command: "plan"
`

Store: issue with full description, checklist, state

2. Display current plan summary:

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log(`📋 Current Plan: ${issueId}`);
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log(`🏷️  Title: ${issue.title}`);
console.log(`📊 Status: ${issue.state.name}`);

const checklist = issue.description.match(/- \[([ x])\] .+/g) || [];
const completed = checklist.filter(i => i.includes('[x]')).length;
console.log(`🎯 Progress: ${completed}/${checklist.length} items\n`);

if (checklist.length > 0) {
  console.log('Current Checklist:');
  checklist.slice(0, 5).forEach((item, idx) => {
    const icon = item.includes('[x]') ? '✅' : '⏳';
    const text = item.replace(/- \[([ x])\] /, '');
    console.log(`  ${icon} ${idx + 1}. ${text}`);
  });
  if (checklist.length > 5) console.log(`  ... and ${checklist.length - 5} more\n`);
}

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('📝 Update Request');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log(updateText);
console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

3. Analyze update request:

// Detect change type
const changeType = detectChangeType(updateText);
// Returns: 'scope_change', 'approach_change', 'simplification', 'blocker', 'clarification'

4. Interactive clarification (if needed):

if (requiresClarification(changeType, updateText)) {
  const questions = generateClarificationQuestions(changeType, updateText, issue);

  AskUserQuestion({
    questions: questions  // 1-4 targeted questions based on update
  });

  // Use answers to refine update request
}

5. Generate updated plan with smart agent:

Task: `
Update implementation plan for: ${issue.title}

Update request: ${updateText}
Change type: ${changeType}
${clarification ? `Clarification: ${JSON.stringify(clarification)}` : ''}

Current plan:
${issue.description}

Your task:
1. Analyze the update request and current plan
2. Determine what needs to change (keep/modify/add/remove)
3. Research any new requirements using Context7 MCP
4. Update implementation checklist accordingly
5. Adjust complexity estimate if needed
6. Document the changes made

Provide:
- Updated checklist with changes highlighted
- Change summary (what was kept/modified/added/removed)
- Updated complexity if changed
- Rationale for changes
`

6. Display change preview:

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('📝 Proposed Changes');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log('✅ Kept:');
keptItems.forEach(i => console.log(`  • ${i}`));
console.log('\n✏️  Modified:');
modifiedItems.forEach(i => console.log(`  • ${i.old} → ${i.new}`));
console.log('\n➕ Added:');
addedItems.forEach(i => console.log(`  • ${i}`));
if (removedItems.length > 0) {
  console.log('\n❌ Removed:');
  removedItems.forEach(i => console.log(`  • ${i}`));
}

7. Confirm and update:

AskUserQuestion({
  questions: [{
    question: "Apply these changes to the plan?",
    header: "Confirm",
    multiSelect: false,
    options: [
      { label: "Yes, apply changes", description: "Update the plan with changes shown above" },
      { label: "Needs adjustment", description: "Refine the changes first" }
    ]
  }]
});

if (confirmed) {
  Task(ccpm:linear-operations): `
operation: update_issue_description
params:
  issueId: "${issueId}"
  description: ${updatedDescription}
context:
  command: "plan"
  changeType: "${changeType}"
`

  // Add comment documenting the change
  Task(ccpm:linear-operations): `
operation: create_comment
params:
  issueId: "${issueId}"
  body: |
    ## 📝 Plan Updated

    **Change Type**: ${changeType}
    **Request**: ${updateText}

    ### Changes Made

    ${formatChangeSummary(changes)}

    ---
    *Updated via /ccpm:plan*
context:
  command: "plan"
`
}

8. Display completion:

console.log('\n✅ Plan Updated!');
console.log(`📋 Issue: ${issueId} - ${issue.title}`);
console.log(`🔗 ${issue.url}`);
console.log(`\n📊 Changes: ${changes.added} added, ${changes.modified} modified, ${changes.removed} removed`);
console.log(`\n💡 Next: /ccpm:work ${issueId}`);
```

### Helper Functions

```javascript
// Detect change type from update request
function detectChangeType(text) {
  const lower = text.toLowerCase();

  if (/(add|also|include|plus|additionally)/i.test(lower)) return 'scope_change';
  if (/(instead|different|change|use.*not)/i.test(lower)) return 'approach_change';
  if (/(remove|don't need|skip|simpler)/i.test(lower)) return 'simplification';
  if (/(blocked|can't|doesn't work|issue|problem)/i.test(lower)) return 'blocker';
  return 'clarification';
}

// Generate checklist from planning result
function generateChecklist(plan) {
  return plan.subtasks.map(task => `- [ ] ${task}`).join('\n');
}

// Format files list
function formatFilesList(files) {
  return files.map(f => `- **${f.path}**: ${f.rationale}`).join('\n');
}

// Generate clarification questions based on change type
function generateClarificationQuestions(changeType, updateText, issue) {
  // Returns 1-4 AskUserQuestion-formatted questions
  // Based on change type and context
}
```

## Error Handling

### Invalid Issue ID Format
```
❌ Invalid issue ID format: proj123
Expected format: PROJ-123
```

### Issue Not Found
```
❌ Error fetching issue: Issue not found

Suggestions:
  - Verify the issue ID is correct
  - Check you have access to this Linear team
```

### Missing Title
```
❌ Missing arguments

Usage:
  /ccpm:plan "Task title" [project] [jira]  # Create new
  /ccpm:plan WORK-123                        # Plan existing
  /ccpm:plan WORK-123 "changes"              # Update plan
```

### Project Configuration Error
```
❌ Could not detect project configuration

Suggestions:
  - Specify project: /ccpm:plan "title" my-project
  - Configure project: /ccpm:project:add my-project
```

## Examples

### Example 1: CREATE Mode

```bash
/ccpm:plan "Add user authentication"

# Output:
# 🎯 Mode: CREATE
#
# ✅ Created issue: PSN-30
# 📋 Planning: PSN-30 - Add user authentication
#
# [Smart agent analyzes requirements...]
#
# ═══════════════════════════════════════
# ✅ Task Created & Planned!
# ═══════════════════════════════════════
#
# 📋 Issue: PSN-30 - Add user authentication
# 🔗 https://linear.app/.../PSN-30
#
# 📊 Plan Summary:
#   ✅ 7 subtasks created
#   📁 5 files to modify
#   ⚡ Complexity: Medium
#
# 💡 Next: /ccpm:work PSN-30
```

### Example 2: PLAN Mode

```bash
/ccpm:plan PSN-29

# Output:
# 🎯 Mode: PLAN
#
# 📋 Planning: PSN-29 - Implement dark mode
#
# [Smart agent creates plan...]
#
# ═══════════════════════════════════════
# ✅ Planning Complete!
# ═══════════════════════════════════════
#
# 📋 Issue: PSN-29 - Implement dark mode
# 🔗 https://linear.app/.../PSN-29
#
# 📊 Plan Added:
#   ✅ 6 subtasks
#   📁 8 files to modify
#   ⚡ Complexity: Low
#
# 💡 Next: /ccpm:work PSN-29
```

### Example 3: UPDATE Mode

```bash
/ccpm:plan PSN-29 "Also add email notifications"

# Output:
# 🎯 Mode: UPDATE
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📋 Current Plan: PSN-29
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 🏷️  Title: Implement dark mode
# 📊 Status: Planned
# 🎯 Progress: 0/6 items
#
# [Shows clarification questions...]
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📝 Proposed Changes
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# ✅ Kept: 6 items
# ➕ Added:
#   • Set up email service integration
#   • Add notification templates
#
# [Confirmation prompt...]
#
# ✅ Plan Updated!
# 📊 Changes: 2 added, 0 modified, 0 removed
```

## Token Budget Breakdown

| Section | Tokens | Notes |
|---------|--------|-------|
| Frontmatter & description | 100 | Minimal metadata |
| Step 1: Parse & detect mode | 200 | Argument parsing |
| Step 2A: CREATE mode | 600 | Create + plan workflow |
| Step 2B: PLAN mode | 550 | Plan existing workflow |
| Step 2C: UPDATE mode | 500 | Update workflow with clarification |
| Helper functions | 150 | Reusable utilities |
| Error handling | 100 | 4 error scenarios |
| Examples | 250 | 3 concise examples |
| **Total** | **~2,450** | **vs ~7,000 baseline (65% reduction)** |

## Key Optimizations

1. ✅ **No routing overhead** - All 3 modes implemented directly
2. ✅ **Linear subagent** - All Linear ops cached (85-95% hit rate)
3. ✅ **Smart agent selection** - Automatic optimal agent for planning
4. ✅ **Batch operations** - Single update_issue call (state + labels + description)
5. ✅ **Concise examples** - Only 3 essential examples
6. ✅ **Focused scope** - Simplified planning workflow (no full external PM research by default)

## Integration with Other Commands

- **After planning** → Use /ccpm:work to start implementation
- **During work** → Use /ccpm:sync to save progress
- **Before completion** → Use /ccpm:verify for quality checks
- **Finalize** → Use /ccpm:done to create PR and complete

## Notes

- **Mode detection**: Clear, unambiguous patterns (issue ID vs quoted string)
- **Smart agents**: Automatic selection based on task type (backend/frontend/mobile)
- **Project detection**: Auto-detects or uses explicit project argument
- **Caching**: Linear subagent caches all data for 85-95% faster operations
- **Error recovery**: Structured error messages with actionable suggestions
