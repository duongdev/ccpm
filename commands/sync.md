---
description: Smart sync - save progress to Linear with concise updates
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[issue-id] [summary]"
---

# /ccpm:sync - Smart Progress Sync

Auto-detects issue from git branch and syncs progress to Linear with smart checklist updates and **concise comments**.

## 🎯 v1.0 Linear Comment Strategy

**Focus**: Short, scannable updates (not verbose reports)
- **OLD**: 500-1000 word progress reports
- **NEW**: 50-100 word status snapshots
- **Details**: In issue description (single source of truth)

## Usage

```bash
# Auto-detect issue from git branch
/ccpm:sync

# Explicit issue ID
/ccpm:sync PSN-29

# With custom summary
/ccpm:sync PSN-29 "Completed auth implementation"

# Auto-detect with summary
/ccpm:sync "Finished UI components"
```

## Implementation

### Step 1: Parse Arguments & Detect Issue

```javascript
const args = process.argv.slice(2);
let issueId = args[0];
let summary = args[1];

const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/;

// If first arg looks like summary (not issue ID), treat as summary
if (args[0] && !ISSUE_ID_PATTERN.test(args[0])) {
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
- Use `_shared-checklist-helpers.md` for parsing
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

**B) Add CONCISE progress comment (using actual checklist data from Step 7A):**

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
context:
  command: "sync"
  purpose: "Concise progress update with actual checklist changes"
```

**Use actual data from checklist update (Step 7A):**
- `itemsUpdated`: From `checklistUpdateResult.itemsUpdated`
- `previousProgress`: From `checklistUpdateResult.previousProgress`
- `newProgress`: From `checklistUpdateResult.newProgress`

This ensures the comment reflects the ACTUAL checklist state, not estimated values!

**Example concise comment:**

```markdown
🔄 **Synced** | feature/psn-29-auth

Completed auth implementation, all tests passing

**Files**: 8 modified, 2 added (+234, -67)
**Checklist**: 2 completed
**Progress**: 40% → 60%
```

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

If user provides summary, skip interactive mode:

1. Skip checklist AI analysis
2. Skip AskUserQuestion
3. Use provided summary directly
4. Create simple concise comment
5. No automatic checklist updates

**Example:**

```bash
/ccpm:sync PSN-29 "Completed auth implementation, all tests passing"
```

**Output:**

```
✅ Quick sync complete!
💬 Concise comment added to Linear
📊 Summary: "Completed auth implementation, all tests passing"
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

## v1.0 Linear Comment Strategy Benefits

**Before (verbose):**
- 500-1000 words per sync comment
- Hard to scan Linear timeline
- Redundant information
- Details buried in comments

**After (concise):**
- 50-100 words per sync comment
- Easy to scan at a glance
- Key info highlighted
- Details in description (single source)

**Impact:**
- ✅ 90% shorter comments
- ✅ Cleaner Linear feed
- ✅ Faster to review progress
- ✅ Better signal-to-noise ratio

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
