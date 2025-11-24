---
description: Smart work - start or resume with v1.0 workflow rules
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[issue-id]"
---

# /ccpm:work - Start or Resume Work

Intelligent command that detects whether to start new work or resume in-progress tasks.

## Helper Functions

This command uses:
- `helpers/decision-helpers.md` - For confidence-based decision making (Always-Ask Policy)
- `helpers/checklist.md` - For robust checklist parsing and progress tracking

## 🎯 v1.0 Interactive Workflow Rules

**WORK Mode Philosophy:**
- **Git branch safety** - Check protected branches before creating new branches
- **Phase planning** - Ask which phases to do now vs later (multi-select support)
- **Confidence-based decisions** - Use decision-helpers.md to ask when confidence < 80%
- **Parallel implementation** - Detect and prioritize tasks that can run simultaneously
- **Document uncertainties** - Immediately note questions/unknowns in Linear
- **Regular progress updates** - Sync to Linear frequently
- **Robust checklist management** - Use checklist.md for consistent parsing and updates
- **Proactive subagents** - Invoke specialized agents as needed
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

**Use helpers/checklist.md to parse checklist:**

const checklistData = parseChecklist(issue.description);

if (!checklistData) {
  console.log('\n⚠️  No implementation checklist found. Consider running /ccpm:plan first.');
  // Continue anyway, but no phase planning
} else if (checklistData.items.length > 5) {
  console.log('\n📋 Implementation Checklist:');
  checklistData.items.forEach((item, idx) => {
    const icon = item.checked ? '✅' : '⏳';
    console.log(`  ${icon} ${idx + 1}. ${item.content}`);
  });

  // Only show phase planning for uncompleted items
  const incompleteItems = checklistData.items.filter(item => !item.checked);

  if (incompleteItems.length > 0) {
    console.log('\n💡 This task has multiple phases. Which would you like to tackle first?');

    // Use AskUserQuestion for phase selection
    AskUserQuestion({
      questions: [{
        question: "Which phases to work on now?",
        header: "Phase Planning",
        multiSelect: true,
        options: incompleteItems.slice(0, 4).map((item, idx) => ({
          label: `Phase ${idx + 1}`,
          description: item.content
        }))
      }]
    });

    // Store selected phases for focused work
    const selectedPhases = answers;
    console.log(`\n✅ Focusing on: ${selectedPhases.join(', ')}`);
  }
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

3.5. Load visual context for implementation (if available):

**Detect and load visual references** (for pixel-perfect UI implementation):

a) Check for images in issue (helpers/image-analysis.md):
   - Scan issue.attachments for images
   - Scan issue.description for markdown images
   - Filter for UI mockups specifically

b) Check for Figma links (helpers/figma-detection.md):
   - Search issue.description and comments for Figma URLs
   - Check Linear comments for cached design data

**If UI-related visual context found:**

Display: "🎨 Visual context available for implementation"

**For UI tasks - Load mockups directly for pixel-perfect implementation:**

```javascript
const isUITask = issue.description.match(/\b(ui|design|mockup|interface|component|screen|page)\b/i)
  || issue.title.match(/\b(ui|design|mockup|interface|component|screen|page)\b/i);

if (isUITask && (detectedImages.length > 0 || detectedFigmaLinks.length > 0)) {
  // This is THE KEY FEATURE from PSN-24 Subtask 9
  // Pass visual mockups DIRECTLY to agents for pixel-perfect implementation

  console.log('\n🎨 UI Task Detected - Loading visual references:');

  // Prepare visual context for agents
  const visualReferences = [];

  // Load images (mockups, designs)
  for (const image of detectedImages.filter(img => img.type === 'ui_mockup')) {
    console.log(`  📸 Loading mockup: ${image.url}`);

    // Fetch image via WebFetch for agent to see
    const imageContent = await WebFetch(image.url, 'Fetch UI mockup for implementation');

    visualReferences.push({
      type: 'image',
      url: image.url,
      content: imageContent,
      purpose: 'pixel_perfect_implementation'
    });
  }

  // Load Figma design data
  for (const figmaUrl of detectedFigmaLinks) {
    console.log(`  🎨 Loading Figma design: ${figmaUrl}`);

    // Check cache first
    const cached = await Bash(`./scripts/figma-cache-manager.sh get "${issueId}" "${figmaUrl}"`);

    if (cached) {
      visualReferences.push({
        type: 'figma',
        url: figmaUrl,
        designSystem: JSON.parse(cached),
        purpose: 'design_system_reference'
      });
    }
  }

  console.log(`✅ Loaded ${visualReferences.length} visual reference(s)`);

  // Store for use in agent invocation
  const visualContext = {
    available: true,
    references: visualReferences,
    mode: 'pixel_perfect' // Enable pixel-perfect mode
  };
}
```

Display: "✅ Visual context prepared for pixel-perfect implementation"

4. Analyze codebase with smart agent and detect parallel opportunities:

Task: `
Analyze the codebase for: ${issue.title}

Context:
- Issue: ${issueId}
- Description: ${issue.description}
${selectedPhases ? `- Focus on: ${selectedPhases.join(', ')}` : ''}
${visualContext?.available ? `
- **Visual Context Available**: ${visualContext.references.length} reference(s)
  ${visualContext.references.map(ref => `
  - ${ref.type}: ${ref.url}
    Purpose: ${ref.purpose}
  `).join('\n')}

  **IMPORTANT**: You have direct access to UI mockups. For UI implementation tasks,
  reference the visual mockups directly for pixel-perfect implementation.
  Aim for 95-100% design fidelity (not 70-80% text-based interpretation).
` : ''}

Your task:
1. Identify files that need modification
2. List dependencies and imports needed
3. **Analyze task dependencies** - identify which tasks can run in parallel vs sequential
4. Note potential challenges or UNKNOWNS
5. Outline testing strategy
6. Estimate complexity (low/medium/high)

Provide structured plan with:
- **Files to modify** (with specific locations)
- **Dependencies** needed
- **Task Dependencies** - Group tasks as:
  - **Parallel Group 1**: [independent tasks that can be done simultaneously]
  - **Parallel Group 2**: [depends on Group 1 completion]
  - **Sequential Tasks**: [tasks requiring specific order]
- **Uncertainties** - flag anything unclear or needing decisions
- **Testing approach**
- **Complexity** with reasoning

**Example task grouping:**
Parallel Group 1: [Create API endpoint, Design UI component] (independent)
Sequential: [After Group 1] Integrate UI with API endpoint
Parallel Group 2: [Write unit tests for API, Write UI tests] (independent)
`

Note: Smart-agent-selector automatically chooses optimal agent

**After agent analysis, evaluate implementation approach confidence (helpers/decision-helpers.md):**

const implementationConfidence = calculateConfidence({
  input: analysisResult.approach,
  signals: {
    patternMatch: analysisResult.similarPatternsFound ? 80 : 40,
    contextMatch: analysisResult.filesIdentified.length > 0 ? 70 : 30,
    uncertaintyCount: analysisResult.uncertainties?.length || 0
  }
});

// If confidence < 80%, ask user for clarification
if (implementationConfidence.score < 80 || analysisResult.uncertainties.length > 0) {
  console.log('\n⚠️  Implementation approach needs clarification');
  console.log(`Confidence: ${implementationConfidence.score}%`);

  // Generate clarifying questions based on uncertainties
  const questions = analysisResult.uncertainties.map(uncertainty => {
    return {
      question: uncertainty.question,
      header: uncertainty.category || "Approach",
      multiSelect: false,
      options: uncertainty.options || [
        { label: "Option A", description: "..." },
        { label: "Option B", description: "..." }
      ]
    };
  });

  // Ask user for decisions
  AskUserQuestion({ questions: questions.slice(0, 4) }); // Max 4 questions

  console.log('\n✅ Clarifications received. Proceeding with implementation.');
}

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

7. Display next actions with parallel implementation guidance:

console.log('\n═══════════════════════════════════════');
console.log('🎯 Implementation Started');
console.log('═══════════════════════════════════════\n');
console.log(`📝 Working on: ${selectedPhases ? selectedPhases.join(', ') : 'All phases'}`);
console.log(`🌿 Branch: ${currentBranch}`);
console.log(`${uncertainties.length > 0 ? `⚠️  ${uncertainties.length} uncertainties documented` : '✅ No uncertainties'}`);

// Display parallel implementation opportunities if detected
if (analysisResult.taskDependencies) {
  console.log('\n⚡ Parallel Implementation Opportunities:');

  if (analysisResult.taskDependencies.parallelGroup1?.length > 0) {
    console.log(`  🔵 Group 1 (start now): ${analysisResult.taskDependencies.parallelGroup1.join(', ')}`);
  }

  if (analysisResult.taskDependencies.sequentialTasks?.length > 0) {
    console.log(`  🔴 Sequential (after Group 1): ${analysisResult.taskDependencies.sequentialTasks.join(', ')}`);
  }

  if (analysisResult.taskDependencies.parallelGroup2?.length > 0) {
    console.log(`  🔵 Group 2 (after sequential): ${analysisResult.taskDependencies.parallelGroup2.join(', ')}`);
  }

  console.log('\n  💡 Tip: Focus on parallel tasks together for faster progress');
}

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

2. Calculate progress from checklist (using helpers/checklist.md):

**Use parseChecklist and calculateProgress:**

const checklistData = parseChecklist(issue.description);

let progress = 0;
let completedItems = 0;
let totalItems = 0;

if (checklistData) {
  progress = calculateProgress(checklistData);
  completedItems = checklistData.items.filter(item => item.checked).length;
  totalItems = checklistData.items.length;
} else {
  console.log('\n⚠️  No implementation checklist found.');
}

3. Check for uncertainties in description:

const description = issue.description || '';
const hasUncertainties = description.includes('## ⚠️ Uncertainties');
const uncertaintiesMatch = description.match(/## ⚠️ Uncertainties[^]*?(?=\n##|\n\*|$)/);
const uncertaintiesList = uncertaintiesMatch
  ? uncertaintiesMatch[0].match(/\d+\. .+/g) || []
  : [];

4. Determine next action:

let nextAction = null;
let suggestion = null;

if (uncertaintiesList.length > 0) {
  suggestion = `⚠️  ${uncertaintiesList.length} uncertainties need resolution`;
  nextAction = 'Resolve uncertainties first, then continue implementation';
} else if (progress === 100) {
  suggestion = 'All checklist items complete! Ready for verification.';
  nextAction = '/ccpm:verify';
} else if (checklistData) {
  const incompleteItem = checklistData.items.find(item => !item.checked);
  if (incompleteItem) {
    nextAction = `Continue work on: ${incompleteItem.content}`;
  } else {
    suggestion = 'All items checked. Ready for verification.';
    nextAction = '/ccpm:verify';
  }
} else {
  suggestion = 'No checklist found. Continue implementation.';
}

5. Display progress and next action with recent activity (v1.0 enhancement):

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

if (checklistData && checklistData.items.length > 0) {
  console.log('📝 Checklist:\n');
  checklistData.items.forEach(item => {
    const icon = item.checked ? '✅' : '⏳';
    console.log(`  ${icon} ${item.content}`);
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

if (uncertaintiesList.length > 0) {
  console.log('  4. ❓ Update uncertainties - Edit issue description');
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
4. ✅ **Decision helpers** - Confidence-based decisions (Always-Ask Policy when < 80%)
5. ✅ **Parallel implementation** - Detects and prioritizes independent tasks
6. ✅ **Checklist helpers** - Robust parsing with marker comment support
7. ✅ **v1.0 workflow** - Git safety, phase planning, uncertainty tracking
8. ✅ **Shorter Linear comments** - Concise status updates (not long reports)
9. ✅ **Uncertainty tracking** - Documented in description, not comments
10. ✅ **No auto-commit** - Explicit user control over git commits
11. ✅ **Visual context integration** - Pixel-perfect UI implementation (95-100% fidelity)

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
- **Phase planning**: Interactive multi-select for large tasks (>5 items), skips completed items
- **Decision helpers**: Confidence-based decisions with Always-Ask Policy (< 80% threshold)
- **Parallel implementation**: Detects independent tasks, groups for simultaneous execution
- **Checklist helpers**: Robust parsing with marker comments (`<!-- ccpm-checklist-start -->`), progress tracking
- **Uncertainty tracking**: Documented in issue description for visibility
- **Shorter comments**: 80% reduction, easier to scan timeline
- **Smart agents**: Automatic selection based on task type
- **Caching**: Linear subagent caches for 85-95% faster operations
- **Visual context**: Loads UI mockups and Figma designs for pixel-perfect implementation
