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
- Git context detection - For repo labels from `git remote` or folder name
- CLAUDE.md rules (all scopes) - For protected branches and workflow rules

## 🎯 v1.0 Interactive Workflow Rules

**WORK Mode Philosophy:**
- **⛔ NEVER implement inline** - ALWAYS delegate to specialized agents via Task tool
- **Respect CLAUDE.md rules** - Check all scopes for protected branches, prefixes, workflow rules
- **Git branch safety** - Check protected branches before creating new branches
- **Phase planning** - Ask which phases to do now vs later (multi-select support)
- **Implementation choice** - AI implements now (auto-sync) OR manual (you code)
- **Auto-sync after AI implementation** - Never lose context! Git changes → checklist update → progress comment
- **Confidence-based decisions** - Use decision-helpers.md to ask when confidence < 80%
- **Parallel implementation** - Detect and prioritize tasks that can run simultaneously
- **Document uncertainties** - Immediately note questions/unknowns in Linear
- **Robust checklist management** - Use checklist.md for automatic updates after changes
- **Proactive subagents** - Invoke specialized agents as needed
- **No auto-commit** - Only commit on explicit user request (use /ccpm:commit)

## Mode Detection

- **START**: Status is Planning/Backlog/Todo/Planned → Initialize implementation (AI or manual, auto-sync if AI)
- **RESUME**: Status is In Progress/In Development/Doing → Show progress + continue implementation (AI or manual, auto-sync if AI)
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

### Step 0: Check CLAUDE.md Workflow Rules (All Scopes)

**CRITICAL: Check ALL CLAUDE.md files for workflow rules!**

Claude Code loads CLAUDE.md files from multiple locations. This command must respect:
- Protected branch rules
- Branch naming conventions
- Workflow restrictions

```javascript
// Find all CLAUDE.md files in hierarchy
const cwd = process.cwd();
const gitRoot = await Bash('git rev-parse --show-toplevel 2>/dev/null || echo ""');
const homeDir = process.env.HOME;

// Collect all potential CLAUDE.md locations (order: global → local)
const claudeMdPaths = [];

// 1. User global
claudeMdPaths.push(`${homeDir}/.claude/CLAUDE.md`);

// 2. Walk up from git root to find parent CLAUDE.md files
let searchDir = gitRoot.trim() || cwd;
let prevDir = '';
while (searchDir !== prevDir && searchDir !== '/') {
  claudeMdPaths.push(`${searchDir}/CLAUDE.md`);
  claudeMdPaths.push(`${searchDir}/.claude/CLAUDE.md`);
  prevDir = searchDir;
  searchDir = path.dirname(searchDir);
}

// 3. Current working directory (if different from git root)
if (cwd !== gitRoot.trim()) {
  claudeMdPaths.push(`${cwd}/CLAUDE.md`);
  claudeMdPaths.push(`${cwd}/.claude/CLAUDE.md`);
}

// Default workflow rules
let workflowRules = {
  protectedBranches: ['main', 'master', 'develop', 'staging', 'production'],
  branchPrefix: 'feature/',
  requireBranchForWork: true,
  sources: []
};

// Read all existing CLAUDE.md files and extract workflow rules
for (const claudePath of claudeMdPaths) {
  const content = await Read(claudePath).catch(() => null);
  if (!content) continue;

  // Check for workflow/branch-related rules
  const hasWorkflowRules = content.match(/branch|protect|workflow/i);
  if (!hasWorkflowRules) continue;

  workflowRules.sources.push(claudePath);

  // Extract protected branches (patterns like "protected branches: main, develop")
  const protectedMatch = content.match(/protected.*branch(?:es)?[:\s]+([^\n]+)/i);
  if (protectedMatch) {
    const branches = protectedMatch[1].split(/[,\s]+/).filter(b => b.length > 0);
    workflowRules.protectedBranches = [...new Set([...workflowRules.protectedBranches, ...branches])];
  }

  // Extract branch prefix requirement
  const prefixMatch = content.match(/branch.*prefix[:\s]+([^\n\s]+)/i);
  if (prefixMatch) {
    workflowRules.branchPrefix = prefixMatch[1].trim();
  }

  // Check if direct commits to main are allowed
  if (content.match(/allow.*commit.*main|direct.*commit.*allowed/i)) {
    workflowRules.requireBranchForWork = false;
  }

  // Check for stricter rules
  if (content.match(/never.*commit.*main|always.*feature.*branch/i)) {
    workflowRules.requireBranchForWork = true;
  }
}

// Display what was found
if (workflowRules.sources.length > 0) {
  console.log('📋 Found CLAUDE.md workflow rules from:');
  workflowRules.sources.forEach(src => console.log(`   • ${src}`));
  console.log(`   Protected: ${workflowRules.protectedBranches.join(', ')}`);
}
```

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

### Step 2: Detect Repository Context for Labels

**Get repo name from git remote or folder name:**

```bash
# Try git remote first (preferred - gets actual repo name)
REPO_NAME=$(git remote get-url origin 2>/dev/null | sed -E 's/.*[\/:]([^\/]+)\.git$/\1/' | sed 's/\.git$//')

# Fallback to current folder name if no remote
if [ -z "$REPO_NAME" ]; then
  REPO_NAME=$(basename "$(pwd)")
fi

echo "Repo: $REPO_NAME"
```

**Store for label application:**

```javascript
// Get repo name from git
const gitRemote = await Bash('git remote get-url origin 2>/dev/null || echo ""');
let repoName = '';

if (gitRemote.trim()) {
  // Extract repo name from remote URL
  // Handles: git@github.com:user/repo.git, https://github.com/user/repo.git
  const match = gitRemote.match(/[\/:]([^\/]+?)(\.git)?$/);
  repoName = match ? match[1].replace('.git', '') : '';
}

// Fallback to folder name
if (!repoName) {
  const cwd = await Bash('basename "$(pwd)"');
  repoName = cwd.trim();
}

// Optional: detect monorepo subproject from cwd
const cwdParts = process.cwd().split('/');
const appsIndex = cwdParts.findIndex(p => ['apps', 'packages', 'services'].includes(p));
const subproject = appsIndex !== -1 && cwdParts[appsIndex + 1]
  ? cwdParts[appsIndex + 1]
  : null;

// Build labels array
const repoLabels = [repoName];
if (subproject) {
  repoLabels.push(subproject);
}

console.log(`📁 Repository: ${repoName}`);
if (subproject) {
  console.log(`📦 Subproject: ${subproject}`);
}
console.log(`🏷️  Labels: ${repoLabels.join(', ')}`);
```

**Example outputs:**

| Context | repoLabels |
|---------|------------|
| `~/projects/my-app` (simple repo) | `["my-app"]` |
| `~/projects/monorepo/apps/web` | `["monorepo", "web"]` |
| `~/projects/monorepo/packages/ui` | `["monorepo", "ui"]` |

### Step 3: Fetch Issue via Linear Subagent

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

### Step 4: Detect Mode

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

1. Git branch safety check (uses CLAUDE.md rules from Step 0):

```javascript
const currentBranch = await Bash('git rev-parse --abbrev-ref HEAD');

// Use protected branches from CLAUDE.md rules (Step 0)
// Default: ['main', 'master', 'develop', 'staging', 'production']
const protectedBranches = workflowRules.protectedBranches;
const branchPrefix = workflowRules.branchPrefix || 'feature/';

if (protectedBranches.includes(currentBranch)) {
  console.log(`⚠️  You are on protected branch: ${currentBranch}`);

  if (workflowRules.sources.length > 0) {
    console.log(`   (Protected by CLAUDE.md rules)`);
  }

  console.log(`\nRecommended: Create a feature branch`);
  console.log(`  git checkout -b ${branchPrefix}${issueId.toLowerCase()}-${issue.title.toLowerCase().replace(/\s+/g, '-').substring(0, 30)}`);
  console.log(`\nProceed anyway? This will create commits on ${currentBranch}.`);
```

  // Generate suggested branch name
  const suggestedBranch = `${branchPrefix}${issueId.toLowerCase()}-${issue.title.toLowerCase().replace(/[^a-z0-9]+/g, '-').substring(0, 30).replace(/-$/, '')}`;

  // Use AskUserQuestion for confirmation
  AskUserQuestion({
    questions: [{
      question: `You're on protected branch '${currentBranch}'. What would you like to do?`,
      header: "Safety Check",
      multiSelect: false,
      options: [
        { label: "Create branch for me", description: `Auto-create: ${suggestedBranch}` },
        { label: "I'll create branch myself", description: "Stop here and let me handle it" },
        { label: "Continue on main", description: "I know what I'm doing, proceed on this branch" }
      ]
    }]
  });

  if (answer === "Create branch for me") {
    // Auto-create the feature branch
    console.log(`\n🌿 Creating branch: ${suggestedBranch}`);
    await Bash(`git checkout -b ${suggestedBranch}`);
    console.log(`✅ Switched to new branch: ${suggestedBranch}`);
  } else if (answer === "Continue on main") {
    console.log(`\n⚠️  Proceeding on protected branch: ${currentBranch}`);
  } else {
    // "I'll create branch myself" or cancelled
    console.log('\n⏸️  Stopped. Create a feature branch and run /ccpm:work again.');
    console.log(`\nSuggested command:`);
    console.log(`  git checkout -b ${suggestedBranch}`);
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

3. Update issue status with repo labels:

**Use the Task tool:**

Invoke `ccpm:linear-operations`:

```yaml
operation: update_issue
params:
  issueId: "{issue ID}"
  state: "In Progress"
  labels: [...repoLabels, "implementation"]  # Merge repo + workflow labels
  # e.g., ["my-app", "implementation"] or ["monorepo", "web", "implementation"]
context:
  cache: true
  command: "work"
```

**Label strategy:**
- `repoLabels` from Step 2 (git remote or folder name + optional subproject)
- `"implementation"` added as workflow stage label
- Result: Linear issue shows which repo/subproject is affected

Display: "✅ Updated status: ${issue.state.name} → In Progress"
Display: "🏷️  Labels: ${[...repoLabels, 'implementation'].join(', ')}"

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

4. Analyze codebase with Explore agent (CONTEXT PROTECTION):

**🎯 IMPORTANT: Use Explore agent to protect main context**

See `helpers/agent-delegation.md` for full patterns.

**Use Task tool with Explore agent (isolates exploration from main context):**

Task(subagent_type="Explore", model="haiku"): `
Find files and patterns for implementing: ${issue.title}

${selectedPhases ? `Focus on phases: ${selectedPhases.join(', ')}` : ''}

Return ONLY:
1. **file_paths**: List of files to modify
2. **patterns**: Existing patterns to follow
3. **dependencies**: Imports/packages needed
4. **task_groups**: Group tasks as parallel vs sequential
5. **uncertainties**: Questions needing decisions
6. **complexity**: low/medium/high with reasoning
`

**Main context receives:** ~100 tokens (just the structured result)
**Explore context:** ~2000 tokens (discarded after)

Store result as `explorationResult`:
```javascript
const explorationResult = {
  file_paths: [...],
  patterns: [...],
  dependencies: [...],
  task_groups: {
    parallel: [...],      // Independent tasks
    sequential: [...]     // Tasks with dependencies
  },
  uncertainties: [...],
  complexity: 'medium'
};
```

Note: Explore agent runs in isolated context - doesn't fill main context

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

4A. Ask user: AI implementation or manual? (Context preservation):

console.log('\n💡 Implementation Mode:');
console.log('  Option 1: AI implements now (auto-sync progress to Linear)');
console.log('  Option 2: Manual implementation (you code, sync later with /ccpm:sync)');

AskUserQuestion({
  questions: [{
    question: "How would you like to implement this?",
    header: "Implementation",
    multiSelect: false,
    options: [
      {
        label: "AI implements now",
        description: "AI makes changes, automatically syncs progress to Linear (never lose context)"
      },
      {
        label: "I'll implement manually",
        description: "You write code, use /ccpm:sync when ready"
      }
    ]
  }]
});

const aiImplement = (answer === "AI implements now");

**If AI implements (aiImplement === true):**

4B. Chunked implementation via specialized agents (CONTEXT PROTECTION):

## ⛔ CRITICAL: NEVER Implement Code Inline - ALWAYS Delegate to Agents

**These rules are ABSOLUTE and MUST be followed:**

1. **NEVER** write implementation code directly in the main context
2. **NEVER** use Read/Edit/Write tools to implement features yourself
3. **NEVER** do codebase analysis inline - use Explore agent
4. **ALWAYS** use `Task(subagent_type=...)` for ALL implementation work
5. **ALWAYS** select the appropriate specialized agent for each task
6. **ALWAYS** invoke agents via the Task tool, not inline code

**Why?** Main context fills up rapidly (~200k limit). Each agent call uses only ~50 tokens in main context, while inline implementation uses ~2000-5000 tokens per file.

**Violation example (WRONG):**
```
// DON'T DO THIS - implementing inline fills main context
const code = `function login() { ... }`;
Edit("src/auth.ts", code);  // ❌ WRONG - direct implementation
```

**Correct approach (RIGHT):**
```
Task(subagent_type="frontend-mobile-development:frontend-developer"): `
Implement login component using existing patterns.
Files: src/components/Login.tsx
Make actual file changes.
`  // ✅ RIGHT - delegated to agent
```

See `helpers/agent-delegation.md` for full patterns.

console.log('\n🤖 Implementing via specialized agents...');

**Agent Selection Function:**

```javascript
function selectAgent(taskContent) {
  const task = taskContent.toLowerCase();

  // Frontend/UI signals
  if (task.match(/\b(ui|component|react|css|tailwind|frontend|page|screen|layout|button|form)\b/)) {
    return 'frontend-mobile-development:frontend-developer';
  }

  // Backend/API signals
  if (task.match(/\b(api|endpoint|database|auth|backend|server|graphql|rest|model)\b/)) {
    return 'backend-development:backend-architect';
  }

  // Mobile signals
  if (task.match(/\b(mobile|react native|flutter|ios|android|app)\b/)) {
    return 'frontend-mobile-development:mobile-developer';
  }

  // Testing signals
  if (task.match(/\b(test|spec|jest|vitest|cypress|playwright)\b/)) {
    return 'full-stack-orchestration:test-automator';
  }

  // Default: general purpose
  return 'general-purpose';
}
```

**Chunked Implementation - One agent per checklist item:**

```javascript
const checklistItems = selectedPhases || checklistData?.items.filter(i => !i.checked) || [];

for (const item of checklistItems) {
  const agentType = selectAgent(item.content);

  console.log(`\n📦 Implementing: ${item.content}`);
  console.log(`   Agent: ${agentType}`);

  // Invoke specialized agent with minimal context
  Task(subagent_type=agentType): `
  Implement: ${item.content}

  Context:
  - Files: ${explorationResult.file_paths.join(', ')}
  - Patterns: ${explorationResult.patterns.join(', ')}
  ${visualContext?.available && agentType.includes('frontend') ? `
  - Visual mockup available for pixel-perfect implementation
  - Target: 95-100% design fidelity
  ` : ''}

  Make actual file changes. Return brief summary of changes.
  `

  console.log(`   ✅ Completed`);
}
```

**Parallel Implementation (when tasks are independent):**

If `explorationResult.task_groups.parallel` has multiple items:

```javascript
// Invoke multiple agents in parallel (single message, multiple Task calls)
const parallelTasks = explorationResult.task_groups.parallel;

if (parallelTasks.length > 1) {
  console.log(`\n⚡ Running ${parallelTasks.length} independent tasks in parallel...`);

  // These Task calls should be in a SINGLE message to run in parallel:
  // Task(frontend-developer): "Implement ${parallelTasks[0]}"
  // Task(backend-architect): "Implement ${parallelTasks[1]}"
  // etc.
}
```

**Benefits of chunked agent delegation:**
- Main context: ~50 tokens per item (vs ~2000 without delegation)
- Each agent has full context for its specific task
- Parallel execution reduces total time by ~40-60%
- Agent context discarded after each call

console.log('\n✅ All implementations complete');

4C. Auto-sync progress (detect git changes):

console.log('\n🔄 Auto-syncing progress to Linear...');

// Detect git changes (same logic as sync command)
const gitChanges = await Bash('git status --porcelain && echo "---" && git diff --stat HEAD');

Parse changes:
const changes = {
  modified: [],
  added: [],
  deleted: [],
  insertions: 0,
  deletions: 0
};

// Parse git status and diff stats
// (same parsing logic as sync command)

if (changes.modified.length === 0 && changes.added.length === 0) {
  console.log('⚠️  No git changes detected. Skipping auto-sync.');
  // Continue to manual flow (Step 5)
} else {
  console.log(`📊 Detected: ${changes.modified.length} modified, ${changes.added.length} added`);

  4D. AI-powered checklist matching (from sync command):

  // Extract unchecked items from current checklist
  const checklistData = parseChecklist(issue.description);
  const uncheckedItems = checklistData?.items.filter(item => !item.checked) || [];

  if (uncheckedItems.length > 0) {
    // Score each item based on git changes (same logic as sync command)
    uncheckedItems.forEach(item => {
      const keywords = extractKeywords(item.content);
      item.score = 0;

      // File path matching (30 points)
      changes.modified.concat(changes.added).forEach(file => {
        if (keywords.some(kw => file.toLowerCase().includes(kw))) {
          item.score += 30;
        }
      });

      // File name exact match (40 points)
      if (changes.modified.some(f => matchesPattern(f, item.content))) {
        item.score += 40;
      }

      // Large changes (10-20 points)
      const totalLines = changes.insertions + changes.deletions;
      if (totalLines > 50) item.score += 10;
      if (totalLines > 100) item.score += 20;
    });

    // Auto-complete high-confidence items (score >= 50)
    const completedItems = uncheckedItems.filter(i => i.score >= 50);

    if (completedItems.length > 0) {
      console.log(`\n✅ Auto-completing ${completedItems.length} high-confidence checklist item(s):`);
      completedItems.forEach(item => console.log(`  - ${item.content}`));

      4E. Update checklist automatically:

      **Use the Task tool:**

      Invoke `ccpm:linear-operations`:
      ```
      operation: update_checklist_items
      params:
        issueId: "{issue ID}"
        indices: [${completedItems.map(i => i.index).join(', ')}]
        mark_complete: true
        add_comment: false  # We'll add comprehensive comment below
        update_timestamp: true
      context:
        command: "work"
        purpose: "Auto-sync progress after AI implementation"
      ```

      const checklistUpdateResult = {
        itemsUpdated: completedItems.length,
        previousProgress: checklistData.progress || 0,
        newProgress: /* result from update */
      };
    }
  }

  4F. Post comprehensive progress comment (with actual changes):

  **Use the Task tool:**

  Invoke `ccpm:linear-operations`:
  ```
  operation: create_comment
  params:
    issueId: "{issue ID}"
    body: |
      🚀 **Implemented** | ${currentBranch}

      ${selectedPhases ? `**Focus**: ${selectedPhases.join(', ')}` : 'Implemented all phases'}
      **Files**: ${changes.modified.length} modified, ${changes.added.length} added (+${changes.insertions}, -${changes.deletions})
      ${checklistUpdateResult ? `**Checklist**: ${checklistUpdateResult.itemsUpdated} completed` : ''}
      ${checklistUpdateResult ? `**Progress**: ${checklistUpdateResult.previousProgress}% → ${checklistUpdateResult.newProgress}%` : ''}

      +++ 📋 Implementation Details

      **Changed Files**:
      ${changes.modified.map(f => `- ${f}`).join('\n')}
      ${changes.added.length > 0 ? `\n**New Files**:\n${changes.added.map(f => `- ${f}`).join('\n')}` : ''}

      ${completedItems?.length > 0 ? `
      **Completed Items** (auto-detected):
      ${completedItems.map(item => `- ✅ ${item.content}`).join('\n')}
      ` : ''}

      ${uncertainties.length > 0 ? `
      **Uncertainties** (documented in description):
      ${uncertainties.map((u, i) => `${i+1}. ${u}`).join('\n')}
      ` : ''}

      **Git Summary**:
      \`\`\`
      ${changes.modified.length + changes.added.length} files changed, ${changes.insertions} insertions(+), ${changes.deletions} deletions(-)
      \`\`\`

      **Next Steps**:
      1. Review the changes
      2. Use /ccpm:commit to commit changes
      3. Use /ccpm:verify for quality checks
      4. Use /ccpm:sync for additional progress updates

      +++
  context:
    command: "work"
    purpose: "Auto-sync progress with implementation details"
  ```

  Display: "✅ Progress auto-synced to Linear (never lose context!)"

  // Skip manual comment (Step 6) since we already posted progress
  const skipManualComment = true;
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

6. Add structured comment to Linear (ONLY if manual implementation):

**Skip this step if AI already implemented and auto-synced (skipManualComment === true)**

**If manual implementation (skipManualComment !== true):**

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: create_comment
params:
  issueId: "{issue ID}"
  body: |
    🚀 **Started** | ${currentBranch}

    ${selectedPhases ? `**Focus**: ${selectedPhases.join(', ')}` : 'Starting all phases'}
    **Files**: ${analysisResult.filesToModify.length} files to modify
    ${uncertainties.length > 0 ? `**Uncertainties**: ${uncertainties.length} (see description)` : '✅ No uncertainties'}

    +++ 📋 Implementation Context

    **Selected Phases**:
    ${selectedPhases?.map(p => `- ${p}`).join('\n') || '- All phases'}

    **Files to Modify**:
    ${analysisResult.filesToModify.slice(0, 10).map(f => `- ${f.path || f}`).join('\n')}
    ${analysisResult.filesToModify.length > 10 ? `\n_...and ${analysisResult.filesToModify.length - 10} more files_` : ''}

    **Dependencies**:
    ${analysisResult.dependencies?.join(', ') || 'None specified'}

    ${analysisResult.taskDependencies?.parallelGroup1?.length > 0 ? `
    **Parallel Implementation Opportunities**:
    - Group 1 (start now): ${analysisResult.taskDependencies.parallelGroup1.join(', ')}
    ${analysisResult.taskDependencies.sequentialTasks?.length > 0 ? `- Sequential: ${analysisResult.taskDependencies.sequentialTasks.join(', ')}` : ''}
    ${analysisResult.taskDependencies.parallelGroup2?.length > 0 ? `- Group 2 (after sequential): ${analysisResult.taskDependencies.parallelGroup2.join(', ')}` : ''}
    ` : ''}

    **Testing Strategy**:
    ${analysisResult.testingApproach || analysisResult.testing || 'TBD'}

    ${uncertainties.length > 0 ? `
    **Uncertainties** (documented in description):
    ${uncertainties.map((u, i) => `${i+1}. ${u}`).join('\n')}
    ` : ''}

    **Complexity**: ${analysisResult.complexity || 'TBD'}

    **Next Steps**:
    1. Implement selected phases
    2. **Use /ccpm:sync frequently** to save progress and update checklist
    3. Use /ccpm:commit when ready to commit
    4. Use /ccpm:verify before completion

    +++
context:
  command: "work"
  purpose: "Start work with full implementation context"
```

Display: "✅ Logged start in Linear with implementation context"

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

if (aiImplement) {
  console.log('  ✅ AI implementation complete!');
  console.log('  ✅ Progress auto-synced to Linear (never lose context!)');
  console.log('');
  console.log('  1. Review the changes made by AI');
  console.log('  2. Use /ccpm:commit to commit changes');
  console.log('  3. Use /ccpm:verify for quality checks');
  console.log('  4. Use /ccpm:sync for additional progress updates (optional)');
} else {
  console.log('  1. Review the implementation plan above');
  console.log('  2. Start coding (no auto-commit - you decide when)');
  console.log('  3. ⭐ Use /ccpm:sync frequently to:');
  console.log('     - Save progress updates');
  console.log('     - Update checklist items automatically (AI-powered matching)');
  console.log('     - Track file changes');
  console.log('  4. Use /ccpm:commit when ready to commit');
}

console.log('\n📌 Quick Commands:');
console.log(`  /ccpm:sync                     # Interactive checklist update`);
console.log(`  /ccpm:sync "progress note"     # Quick sync without checklist`);
console.log(`  /ccpm:commit                   # Git commit`);
console.log(`  /ccpm:verify                   # Quality checks`);
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

5. Ask user: Continue with AI or manual? (Same as START mode):

// Only offer AI continuation if there's remaining work
if (progress < 100) {
  console.log('\n💡 Continue Implementation:');
  console.log('  Option 1: AI continues now (auto-sync progress to Linear)');
  console.log('  Option 2: I'll continue manually (you code, sync later)');
  console.log('  Option 3: Just show menu (no implementation now)');

  AskUserQuestion({
    questions: [{
      question: "How would you like to continue?",
      header: "Continue Work",
      multiSelect: false,
      options: [
        {
          label: "AI continues now",
          description: "AI implements remaining items, auto-syncs progress (never lose context)"
        },
        {
          label: "I'll continue manually",
          description: "You write code, use /ccpm:sync when ready"
        },
        {
          label: "Just show menu",
          description: "Review options without implementing now"
        }
      ]
    }]
  });

  const continueMode = answer;

  if (continueMode === "AI continues now") {
    console.log('\n🤖 AI continuing implementation...');

    // Get remaining work context
    const remainingItems = checklistData?.items.filter(item => !item.checked) || [];

    // Invoke specialized agent to continue implementation
    Task: `
    Continue implementation for: ${issue.title}

    **Context:**
    - Issue: ${issueId}
    - Current Progress: ${progress}% (${completedItems}/${totalItems} items)
    - Recent Activity: ${recentComments?.[0]?.body?.split('\n')[0] || 'None'}

    **Remaining Work:**
    ${remainingItems.map((item, i) => `${i+1}. ${item.content}`).join('\n')}

    ${uncertaintiesList.length > 0 ? `
    **Uncertainties to Address:**
    ${uncertaintiesList.map((u, i) => `${i+1}. ${u}`).join('\n')}
    ` : ''}

    **Your Task:**
    Continue implementing the remaining checklist items. Make actual code changes to complete the work.

    **Constraints:**
    - Focus on remaining uncompleted items only
    - Follow existing code patterns and standards
    - Write production-quality code
    - Add necessary imports and dependencies

    **Important:** Make actual file changes. This is continuation of implementation.
    `

    console.log('✅ Implementation continued');

    // Auto-sync progress (same logic as START mode)
    console.log('\n🔄 Auto-syncing progress to Linear...');

    const gitChanges = await Bash('git status --porcelain && echo "---" && git diff --stat HEAD');

    // Parse changes (same logic as START mode Step 4C)
    const changes = { modified: [], added: [], deleted: [], insertions: 0, deletions: 0 };
    // ... parsing logic ...

    if (changes.modified.length > 0 || changes.added.length > 0) {
      console.log(`📊 Detected: ${changes.modified.length} modified, ${changes.added.length} added`);

      // AI-powered checklist matching (same as START mode Step 4D)
      const uncheckedItems = remainingItems;
      uncheckedItems.forEach(item => {
        // Score items based on git changes
        // ... scoring logic (same as START mode) ...
      });

      const completedItems = uncheckedItems.filter(i => i.score >= 50);

      if (completedItems.length > 0) {
        console.log(`\n✅ Auto-completing ${completedItems.length} checklist item(s)`);

        // Update checklist
        Invoke `ccpm:linear-operations`:
        ```
        operation: update_checklist_items
        params:
          issueId: "{issue ID}"
          indices: [${completedItems.map(i => i.index).join(', ')}]
          mark_complete: true
          add_comment: false
          update_timestamp: true
        context:
          command: "work"
          purpose: "Auto-sync after continued implementation"
        ```
      }

      // Post progress comment (same format as START mode Step 4F)
      Invoke `ccpm:linear-operations`:
      ```
      operation: create_comment
      params:
        issueId: "{issue ID}"
        body: |
          🔄 **Continued** | ${currentBranch}

          **Remaining work**: ${remainingItems.length - completedItems.length} items
          **Files**: ${changes.modified.length} modified, ${changes.added.length} added (+${changes.insertions}, -${changes.deletions})
          **Checklist**: ${completedItems.length} completed
          **Progress**: ${progress}% → ${newProgress}%

          +++ 📋 Implementation Details

          **Changed Files**:
          ${changes.modified.map(f => `- ${f}`).join('\n')}

          **Completed Items** (auto-detected):
          ${completedItems.map(item => `- ✅ ${item.content}`).join('\n')}

          **Remaining Work**:
          ${(remainingItems.length - completedItems.length > 0) ? remainingItems.filter(i => !completedItems.includes(i)).map(item => `- ⏳ ${item.content}`).join('\n') : '✅ All items complete!'}

          **Next Steps**:
          1. Review the changes
          2. Use /ccpm:commit to commit
          3. Use /ccpm:verify for quality checks

          +++
      context:
        command: "work"
        purpose: "Auto-sync continued implementation"
      ```

      Display: "✅ Progress auto-synced to Linear!"
    }

    // Skip interactive menu since AI already implemented
    const skipMenu = true;
  } else if (continueMode === "I'll continue manually") {
    console.log('\n📝 Manual implementation mode - use /ccpm:sync when ready');
    const skipMenu = false;  // Show menu
  } else {
    // Just show menu
    const skipMenu = false;
  }
}

6. Interactive menu (if not skipped):

**Only show if skipMenu !== true (i.e., manual mode or just show menu)**

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
} else if (continueMode === "AI continues now") {
  console.log('\n✅ AI implementation complete + auto-synced!');
  console.log('⏭️  Next: Review changes, then /ccpm:commit');
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

1. ✅ **Auto-sync after AI implementation** - Never lose context! Git changes → checklist → progress comment
2. ✅ **Direct implementation** - No routing overhead
3. ✅ **Linear subagent** - All ops cached (85-95% hit rate)
4. ✅ **Smart agent selection** - Automatic optimal agent choice
5. ✅ **Decision helpers** - Confidence-based decisions (Always-Ask Policy when < 80%)
6. ✅ **Parallel implementation** - Detects and prioritizes independent tasks
7. ✅ **AI-powered checklist matching** - Automatic item completion based on git changes (score >= 50)
8. ✅ **Checklist helpers** - Robust parsing with marker comment support
9. ✅ **v1.0 workflow** - Git safety, phase planning, uncertainty tracking
10. ✅ **Collapsible Linear comments** - Scannable summary + detailed context (`+++` syntax)
11. ✅ **Uncertainty tracking** - Documented in description, not comments
12. ✅ **No auto-commit** - Explicit user control over git commits
13. ✅ **Visual context integration** - Pixel-perfect UI implementation (95-100% fidelity)
14. ✅ **Flexible workflow** - Choose AI or manual implementation each time

## v1.0 Linear Comment Strategy (Native Collapsible)

**OLD (verbose - 500-1000 words):**
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

**NEW (scannable summary + collapsible details):**
```markdown
🚀 **Started** | feature/psn-29-auth

**Focus**: Phase 1, Phase 2
**Files**: 8 files to modify
**Uncertainties**: 2 (see description)

+++ 📋 Implementation Context

**Selected Phases**:
- Phase 1: Create auth endpoints
- Phase 2: Add JWT validation

**Files to Modify**:
- src/auth/jwt.ts
- src/auth/middleware.ts
... and 6 more files

**Dependencies**:
jsonwebtoken, bcrypt

**Parallel Implementation Opportunities**:
- Group 1 (start now): Create API endpoint, Design UI component

**Testing Strategy**:
Unit tests for all auth functions

**Complexity**: Medium

**Next Steps**:
1. Implement selected phases
2. **Use /ccpm:sync frequently** to save progress and update checklist
3. Use /ccpm:commit when ready to commit
4. Use /ccpm:verify before completion

+++
```

**Benefits:**
- ✅ **Scannable**: 3-5 line summary always visible
- ✅ **Complete**: Full context in collapsible section
- ✅ **Linear-native**: Uses `+++` syntax (true collapsible)
- ✅ **Session-friendly**: All context for resuming work
- ✅ **Consistent**: Matches `/ccpm:sync` format
- ✅ **Workflow guidance**: Clear next steps with checklist update reminders

## Integration

- **After /ccpm:plan** → `/ccpm:work` to start implementation
- **During work** → `/ccpm:sync` to save progress (frequently!)
- **Git commits** → `/ccpm:commit` when ready (no auto-commit)
- **Before completion** → `/ccpm:verify` for quality checks
- **Finalize** → `/ccpm:done` to create PR and complete

## Notes

### Workflow Options

**Option 1: AI Implementation (Auto-sync - Never Lose Context!)**
- `/ccpm:work` → analyze → AI implements → **auto-sync** (git changes → update checklist → post progress) → `/ccpm:commit` → `/ccpm:verify` → `/ccpm:done`
- ✅ **Best for**: Context preservation, complex tasks, learning from AI
- ✅ **Benefit**: Progress automatically saved to Linear, never lose work if session ends

**Option 2: Manual Implementation**
- `/ccpm:work` → analyze → you code → `/ccpm:sync` → `/ccpm:commit` → `/ccpm:verify` → `/ccpm:done`
- ✅ **Best for**: Learning by doing, custom implementation, pair programming with AI

### Features

- **Implementation choice**: Ask user whether AI implements or manual
- **Auto-sync after AI implementation**: Detects git changes → updates checklist → posts progress comment
- **Git branch safety**: Checks protected branches, requires confirmation
- **Phase planning**: Interactive multi-select for large tasks (>5 items), skips completed items
- **Decision helpers**: Confidence-based decisions with Always-Ask Policy (< 80% threshold)
- **Parallel implementation**: Detects independent tasks, groups for simultaneous execution
- **Checklist automation**: AI-powered matching of git changes to checklist items (score >= 50 = auto-complete)
- **Uncertainty tracking**: Documented in issue description for visibility
- **Collapsible comments**: Scannable summary + detailed context using `+++` syntax
- **Smart agents**: Automatic selection based on task type (backend, frontend, mobile, etc.)
- **Caching**: Linear subagent caches for 85-95% faster operations
- **Visual context**: Loads UI mockups and Figma designs for pixel-perfect implementation

### Important

- 🚀 **Auto-sync**: If AI implements, progress is automatically saved to Linear (never lose context!)
- 🎯 **AI Checklist Matching**: High-confidence items (score >= 50) are auto-completed based on git changes
- 💡 **Manual workflow**: If you implement manually, use `/ccpm:sync` to update progress
- 🔄 **Flexibility**: Choose AI or manual implementation each time based on your needs
