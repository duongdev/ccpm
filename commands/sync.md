---
description: Smart sync - save progress to Linear with concise updates
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[issue-id] [summary]"
---

# /ccpm:sync - Smart Progress Sync

Auto-detects issue from git branch and syncs progress to Linear with smart checklist updates and **concise comments**.

## ⛔ CRITICAL: Linear Operations

**ALL Linear operations MUST use the Task tool with `ccpm:linear-operations` subagent.**

```javascript
// ✅ CORRECT - Use Task tool with subagent
Task({
  subagent_type: "ccpm:linear-operations",
  prompt: `operation: get_issue\nparams:\n  issueId: WORK-26\ncontext:\n  cache: true`
})

// ❌ WRONG - Direct MCP call
mcp__agent-mcp-gateway__execute_tool({ server: "linear", ... })
```

## ✅ LINEAR = AUTOMATIC (NO CONFIRMATION)

**Linear is internal tracking. Execute ALL operations immediately:**
- ✅ Update checklist → Just do it
- ✅ Post comment → Just do it
- ✅ Change status → Just do it

**NEVER ask user:** "Do you want me to sync?" or "Approve?"

---

## 🎯 v1.0 Linear Comment Strategy (Native Collapsible)

**Focus**: Scannable summary + detailed context using Linear's native collapsible syntax
- **Top**: 3-5 line summary (always visible)
- **Collapsible section**: Detailed context (click to expand)
- **Benefits**: Quick scan in feed, full context when needed

**Structure**:
```
🔄 Summary (always visible)

+++ 📋 Context for Next Session
[Detailed context here]
+++
```

**Linear's Native Syntax**: The `+++ Title` syntax creates a true collapsible section that starts collapsed and expands on click.

## Usage

```bash
# Auto-detect issue from git branch (full interactive mode)
/ccpm:sync

# Explicit issue ID
/ccpm:sync PSN-29

# With custom summary (still prompts for checklist items)
/ccpm:sync PSN-29 "Completed auth implementation"

# Auto-detect with summary
/ccpm:sync "Finished UI components"

# Quick mode: skip checklist prompt entirely (just add comment)
/ccpm:sync PSN-29 "Quick update" --quick
/ccpm:sync --quick "Just a note"
```

## Implementation

### Step 1: Parse Arguments & Detect Issue

```javascript
const args = process.argv.slice(2);
let issueId = args[0];
let summary = args[1];
let quickMode = false;

const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/;

// Check for --quick flag (skip checklist prompt entirely)
if (args.includes('--quick')) {
  quickMode = true;
  // Remove flag from args
  const flagIndex = args.indexOf('--quick');
  args.splice(flagIndex, 1);
}

// If first arg looks like summary (not issue ID), treat as summary
if (args[0] && !ISSUE_ID_PATTERN.test(args[0]) && !args[0].startsWith('--')) {
  summary = args[0];
  issueId = null;
}

// Auto-detect from git branch if no issue ID
if (!issueId) {
  console.log("🔍 Auto-detecting issue from git branch...");

  const branch = await Bash('git rev-parse --abbrev-ref HEAD');
  const match = branch.match(/([A-Z]+-\d+)/);

  if (!match) {
    return error(`
❌ Could not detect issue ID from branch name

Current branch: ${branch}

Usage: /ccpm:sync [ISSUE-ID] [summary]

Examples:
  /ccpm:sync PSN-29
  /ccpm:sync PSN-29 "Completed feature X"
  /ccpm:sync "Made progress on auth"
    `);
  }

  issueId = match[1];
  console.log(`✅ Detected issue: ${issueId}\n`);
}

if (!ISSUE_ID_PATTERN.test(issueId)) {
  return error(`Invalid issue ID: ${issueId}. Expected format: PROJ-123`);
}
```

### Step 2: Detect Git Changes (Parallel)

```bash
# Get all git information in one call
git status --porcelain && echo "---" && \
git diff --stat HEAD && echo "---" && \
git diff --cached --stat
```

Parse output:

```javascript
const changes = {
  modified: [],
  added: [],
  deleted: [],
  insertions: 0,
  deletions: 0
};

// Parse git status (M, A, D, R, ??)
lines.forEach(line => {
  const [status, file] = line.trim().split(/\s+/);
  if (status === 'M') changes.modified.push(file);
  else if (status === 'A' || status === '??') changes.added.push(file);
  else if (status === 'D') changes.deleted.push(file);
});
```

### Step 3: Fetch Issue via Linear Subagent

**Use the Task tool:**

Invoke `ccpm:linear-operations`:

```
operation: get_issue
params:
  issueId: "{issue ID from step 1}"
context:
  cache: true
  command: "sync"
```

### Step 4: Auto-Generate Summary (if not provided)

```javascript
if (!summary && changes.modified.length + changes.added.length > 0) {
  const parts = [];

  if (changes.modified.length > 0) {
    parts.push(`Updated ${changes.modified.length} file(s)`);
  }
  if (changes.added.length > 0) {
    parts.push(`Added ${changes.added.length} new file(s)`);
  }
  if (changes.deleted.length > 0) {
    parts.push(`Deleted ${changes.deleted.length} file(s)`);
  }

  summary = parts.join(', ') || 'Work in progress';
}
```

### Step 5: Smart Checklist Analysis (AI-Powered)

Extract unchecked items and score based on git changes:

```javascript
const checklistItems = issue.description.match(/- \[ \] (.+)/g) || [];
const uncheckedItems = checklistItems.map((item, idx) => ({
  index: idx,
  text: item.replace('- [ ] ', ''),
  score: 0
}));

uncheckedItems.forEach(item => {
  const keywords = extractKeywords(item.text);

  // File path matching (30 points)
  changes.modified.concat(changes.added).forEach(file => {
    if (keywords.some(kw => file.toLowerCase().includes(kw))) {
      item.score += 30;
    }
  });

  // File name exact match (40 points)
  if (changes.modified.some(f => matchesPattern(f, item.text))) {
    item.score += 40;
  }

  // Large changes (10-20 points)
  const totalLines = changes.insertions + changes.deletions;
  if (totalLines > 50) item.score += 10;
  if (totalLines > 100) item.score += 20;
});

// Categorize by confidence
const highConfidence = uncheckedItems.filter(i => i.score >= 50);
const mediumConfidence = uncheckedItems.filter(i => i.score >= 30 && i.score < 50);
```

### Step 6: Interactive Checklist Update

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Which checklist items did you complete? (AI suggestions pre-selected)",
      header: "Completed",
      multiSelect: true,
      options: uncheckedItems.map(item => ({
        label: `${item.text}`,
        description: item.score >= 50
          ? "🤖 SUGGESTED - High confidence"
          : item.score >= 30
          ? "💡 Possible match"
          : "Mark as complete"
      }))
    }
  ]
});
```

### Step 7: Update Linear with Concise Comment (v1.0 Strategy)

**A) Update checklist in description (v1.0 fix - actually update it!):**

If user selected checklist items to complete in Step 6:

**Use the Task tool:**

Invoke `ccpm:linear-operations`:

```
operation: update_checklist_items
params:
  issue_id: "{issue ID}"
  indices: [{completed item indices from step 6}]
  mark_complete: true
  add_comment: false  # We'll add our own concise comment below
  update_timestamp: true
context:
  command: "sync"
  purpose: "Update checklist based on git changes and user confirmation"
```

**This operation will:**
- Read the issue description
- Parse checklist items inline (regex: `- \[([ x])\] (.+)`)
- Update checkboxes from `- [ ]` to `- [x]` for selected indices
- Recalculate progress percentage
- Update the progress line with timestamp
- Return updated progress metrics

**Track result:**
```javascript
const checklistUpdateResult = {
  itemsUpdated: selectedIndices.length,
  previousProgress: checklist.progress.percentage,
  newProgress: result.data.checklist_summary.new_progress
};
```

**B) Add HYBRID progress comment (concise summary + detailed context):**

**Use the Task tool:**

Invoke `ccpm:linear-operations`:

```
operation: create_comment
params:
  issueId: "{issue ID}"
  body: |
    🔄 **Synced** | {branch name}

    {summary or auto-generated from git changes}

    **Files**: {modified} modified, {added} added (+{insertions}, -{deletions})
    **Checklist**: {checklistUpdateResult.itemsUpdated} completed
    **Progress**: {checklistUpdateResult.previousProgress}% → {checklistUpdateResult.newProgress}%

    +++ 📋 Context for Next Session

    **Changed Files**:
    {changes.modified.map(f => `- ${f}`).join('\n')}
    {changes.added.length > 0 ? '\n**New Files**:\n' + changes.added.map(f => `- ${f}`).join('\n') : ''}

    **Completed Items** (this session):
    {completedItems.map(item => `- ✅ ${item.text}`).join('\n')}

    **Remaining Work**:
    {remainingItems.slice(0, 5).map(item => `- ⏳ ${item.text}`).join('\n')}
    {remainingItems.length > 5 ? `\n_...and ${remainingItems.length - 5} more items_` : ''}

    **Git Summary**:
    ```
    {git diff --stat output or summary}
    ```

    **Key Insights**:
    - {any important notes or blockers discovered}
    - {technical decisions made}
    - {next logical steps}

    +++
context:
  command: "sync"
  purpose: "Hybrid: scannable summary + detailed session context"
```

**Use actual data from checklist update (Step 7A):**
- `itemsUpdated`: From `checklistUpdateResult.itemsUpdated`
- `previousProgress`: From `checklistUpdateResult.previousProgress`
- `newProgress`: From `checklistUpdateResult.newProgress`

This ensures the comment reflects the ACTUAL checklist state, not estimated values!

**Example with Linear's native collapsible:**

```markdown
🔄 **Synced** | feature/psn-29-auth

Completed auth implementation, all tests passing

**Files**: 8 modified, 2 added (+234, -67)
**Checklist**: 2 completed
**Progress**: 40% → 60%

+++ 📋 Context for Next Session

**Changed Files**:
- src/auth/jwt.ts
- src/auth/middleware.ts
- src/auth/routes.ts
- src/tests/auth.test.ts

**New Files**:
- src/utils/validators.ts
- src/types/auth.d.ts

**Completed Items** (this session):
- ✅ Implement JWT authentication
- ✅ Add login form validation

**Remaining Work**:
- ⏳ Add password reset flow
- ⏳ Implement OAuth providers
- ⏳ Write integration tests
- ⏳ Update documentation

**Git Summary**:
```
8 files changed, 234 insertions(+), 67 deletions(-)
```

**Key Insights**:
- Used jsonwebtoken library for JWT implementation
- Chose bcrypt for password hashing (industry standard)
- Next: Password reset requires email service setup

+++
```

**How it appears in Linear**:
- Summary visible immediately
- "📋 Context for Next Session" shows as collapsed section
- Click to expand for full details
- Native Linear UX - no workarounds needed!

**Comparison:**

❌ **OLD (verbose - 500+ words):**

```markdown
## 🔄 Progress Sync

**Timestamp**: 2025-11-23T10:30:00Z
**Branch**: feature/psn-29-auth

### 📝 Summary
Completed auth implementation, all tests passing

### 📊 Code Changes
**Files Changed**: 10 (+234, -67)

**Modified**:
- src/auth/jwt.ts
- src/auth/middleware.ts
- src/auth/routes.ts
- src/tests/auth.test.ts
... and 4 more

**New Files**:
- src/utils/validators.ts
- src/types/auth.d.ts

### 📋 Checklist Updated

**Completed This Session**:
- ✅ Implement JWT authentication
- ✅ Add login form

### 🎯 Current Progress
- Overall: 60% complete (6/10 items)
- This session: 2 items completed
- Remaining: 4 items

---
*Synced via /ccpm:sync*
```

✅ **NEW (concise - 50 words):**

```markdown
🔄 **Synced** | feature/psn-29-auth

Completed auth implementation, all tests passing

**Files**: 8 modified, 2 added (+234, -67)
**Checklist**: 2 completed
**Progress**: 40% → 60%
```

### Step 8: Display Confirmation

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Progress Synced to Linear!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId} - ${issue.title}
🔗 ${issue.url}

📝 Synced:
  ✅ ${totalFiles} files changed
  ✅ ${completedItems.length} checklist items updated
  💬 Concise comment added

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. ⭐ Continue work
2. 📝 Commit changes       /ccpm:commit
3. ✅ Run verification     /ccpm:verify
4. 🔍 View status          /ccpm:utils:status ${issueId}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Quick Sync Mode (Manual Summary)

If user provides summary, use streamlined flow with **optional** checklist update:

1. Use provided summary directly (skip AI analysis)
2. **Still show checklist items** for quick manual selection
3. Create concise comment with progress
4. Update checklist if items selected

**Flow:**

```javascript
// Quick mode still offers checklist selection
if (summary) {
  console.log(`📝 Summary: "${summary}"\n`);

  // Parse checklist for quick selection
  const checklist = parseChecklist(issue.description);

  if (checklist && checklist.items.some(i => !i.checked)) {
    const uncheckedItems = checklist.items.filter(i => !i.checked);

    // Show numbered list for quick reference
    console.log('📋 Unchecked items:');
    uncheckedItems.forEach((item, idx) => {
      console.log(`  [${item.index}] ${item.content}`);
    });

    // Ask which to mark complete (can skip with empty selection)
    AskUserQuestion({
      questions: [{
        question: "Mark any items as complete? (skip to just add comment)",
        header: "Checklist",
        multiSelect: true,
        options: uncheckedItems.slice(0, 4).map(item => ({
          label: item.content.substring(0, 50) + (item.content.length > 50 ? '...' : ''),
          description: `Index ${item.index}`
        }))
      }]
    });

    // If items selected, update checklist
    if (selectedIndices.length > 0) {
      // Call update_checklist_items (same as full mode)
    }
  }

  // Always add comment with summary
  // ...
}
```

**Example:**

```bash
/ccpm:sync PSN-29 "Completed auth implementation, all tests passing"
```

**Output:**

```
📝 Summary: "Completed auth implementation, all tests passing"

📋 Unchecked items:
  [0] Implement JWT authentication
  [2] Add password validation
  [3] Write unit tests

? Mark any items as complete? (skip to just add comment)
  ☐ Implement JWT authentication
  ☐ Add password validation
  ☐ Write unit tests
  ☐ Skip - just add comment

[User selects items or skips]

✅ Quick sync complete!
💬 Comment added to Linear
📋 Checklist: 2 items completed (if selected)
📊 Progress: 40% → 60% (if updated)
```

**Skip checklist entirely:**

If no checklist exists or user wants pure quick mode, add `--quick` flag:

```bash
/ccpm:sync PSN-29 "Quick update" --quick
# → Skips checklist prompt entirely, just adds comment
```

## Error Handling

### Invalid Issue ID

```
❌ Invalid issue ID format: proj123
Expected format: PROJ-123
```

### No Git Changes

```
ℹ️  No uncommitted changes detected

You can still sync progress with a manual summary:
  /ccpm:sync PSN-29 "Updated documentation"
```

### Branch Detection Failed

```
❌ Could not detect issue ID from branch

Current branch: main

Usage: /ccpm:sync [ISSUE-ID]
Example: /ccpm:sync PSN-29
```

## Examples

### Example 1: Auto-detect with AI suggestions

```bash
# Branch: feature/PSN-29-add-auth
/ccpm:sync

# Output:
# 🔍 Auto-detecting issue from git branch...
# ✅ Detected issue: PSN-29
#
# 📊 Detected Changes:
# Modified: 3 files (+127, -45)
#
# 🤖 AI Suggestions:
# ✅ Implement JWT authentication (High confidence)
# ✅ Add login form (High confidence)
#
# [Interactive checklist update...]
#
# ✅ Progress Synced to Linear!
# 💬 Concise comment added (50 words vs old 500+)
```

### Example 2: Quick sync with summary

```bash
/ccpm:sync PSN-29 "Finished refactoring auth module"

# Output:
# ✅ Quick sync complete!
# 💬 Concise comment added to Linear
```

### Example 3: Summary-only (auto-detect issue)

```bash
# Branch: feature/PSN-29-add-auth
/ccpm:sync "Completed UI components, tests passing"

# Output:
# ✅ Detected issue: PSN-29
# ✅ Quick sync complete!
# 💬 Concise comment: 3 lines (was 50+ lines before)
```

## Key Optimizations

1. ✅ **Linear subagent** - All Linear ops cached (85-95% hit rate)
2. ✅ **Parallel git operations** - Single bash call for all git info
3. ✅ **No routing overhead** - Direct implementation
4. ✅ **Smart defaults** - Auto-generates summary from changes
5. ✅ **Quick sync mode** - Skip interactions when summary provided
6. ✅ **Concise comments** - 90% shorter (50 words vs 500+)
7. ✅ **Batch updates** - Single subagent call for description + comment

## Linear Comment Strategy Benefits (Native Collapsible)

**Benefits:**
- ✅ **Scannable**: Summary always visible
- ✅ **Complete**: Full context in collapsible section
- ✅ **Session-friendly**: Everything needed to resume work
- ✅ **Linear-native**: Uses `+++` syntax (true collapsible, not auto-collapse)
- ✅ **Clean UX**: Native Linear behavior, no HTML hacks

**Use Cases:**
- **Quick scan**: See progress across multiple issues in feed
- **Deep dive**: Click "📋 Context for Next Session" to expand
- **Resume work**: All details available for next session
- **Team sync**: Summary for stakeholders, details for developers

**Technical Detail:**
Linear's `+++ Title` syntax creates a true collapsible section that:
- Starts collapsed by default
- Shows title with expand/collapse indicator
- Preserves full markdown formatting inside
- Works in comments, issue descriptions, and documents

## Integration

- **During work** → `/ccpm:sync` to save progress frequently
- **After sync** → `/ccpm:commit` for git commits
- **Before completion** → `/ccpm:verify` for quality checks
- **Resume work** → `/ccpm:work` to continue

## Notes

- **Git detection**: Extracts issue ID from branch names like `feature/PSN-29-add-auth`
- **AI suggestions**: Analyzes git changes to pre-select completed checklist items
- **Caching**: Linear subagent caches issue data for faster operations
- **Flexible**: Works with or without arguments, adapts to context
- **Concise comments**: 90% shorter, scannable, focused on key changes
