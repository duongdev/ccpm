---
description: Smart sync command - save progress to Linear (auto-detect task)
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[issue-id] [summary]"
---

# /ccpm:sync - Smart Progress Sync

**Token Budget:** ~2,100 tokens (vs ~6,000 baseline) | **65% reduction**

Auto-detects issue from git branch and syncs progress to Linear with smart checklist updates.

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

// Pattern for issue ID validation
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

// Validate issue ID format
if (!ISSUE_ID_PATTERN.test(issueId)) {
  return error(`Invalid issue ID: ${issueId}. Expected format: PROJ-123`);
}
```

### Step 2: Detect Git Changes

Run in parallel using Bash:

```bash
# Get all git information in one call
git status --porcelain && echo "---" && \
git diff --stat HEAD && echo "---" && \
git diff --cached --stat && echo "---" && \
git rev-parse --abbrev-ref HEAD
```

Parse output to extract:
- Changed files (M, A, D, R, ??)
- Insertions/deletions per file
- Staged vs unstaged changes
- Current branch name

```javascript
const changes = {
  modified: [],
  added: [],
  deleted: [],
  renamed: [],
  insertions: 0,
  deletions: 0
};

// Parse git status output
// M  = modified, A = added, D = deleted, R = renamed, ?? = untracked
lines.forEach(line => {
  const [status, file] = line.trim().split(/\s+/);
  if (status === 'M') changes.modified.push(file);
  else if (status === 'A' || status === '??') changes.added.push(file);
  else if (status === 'D') changes.deleted.push(file);
  else if (status === 'R') changes.renamed.push(file);
});
```

### Step 3: Fetch Issue via Linear Subagent

**Use the Task tool to fetch the issue from Linear:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: get_issue
  params:
    issueId: "{issue ID from step 1}"
  context:
    cache: true
    command: "sync"
  ```

Store response containing:
- issue.id, issue.identifier, issue.title
- issue.description (with checklist)
- issue.state, issue.labels
- issue.comments (for last sync timestamp)

### Step 4: Auto-Generate Summary (if not provided)

If no summary provided, generate from git changes:

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

Extract unchecked items from issue description:

```javascript
const checklistItems = issue.description.match(/- \[ \] (.+)/g) || [];
const uncheckedItems = checklistItems.map((item, idx) => ({
  index: idx,
  text: item.replace('- [ ] ', ''),
  score: 0
}));
```

**Score each item based on git changes:**

```javascript
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

Use AskUserQuestion to confirm suggested items:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Which checklist items did you complete? (AI suggestions pre-selected)",
      header: "Completed",
      multiSelect: true,
      options: uncheckedItems.map(item => ({
        label: `${item.index}: ${item.text}`,
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

### Step 7: Build Progress Report

```markdown
## 🔄 Progress Sync

**Timestamp**: ${new Date().toISOString()}
**Branch**: ${branchName}

### 📝 Summary
${summary}

### 📊 Code Changes
**Files Changed**: ${totalFiles} (+${changes.insertions}, -${changes.deletions})

**Modified**:
${changes.modified.slice(0, 5).map(f => `- ${f}`).join('\n')}
${changes.modified.length > 5 ? `\n... and ${changes.modified.length - 5} more` : ''}

**New Files**:
${changes.added.slice(0, 3).map(f => `- ${f}`).join('\n')}

### 📋 Checklist Updated
${completedItems.length > 0 ? `
**Completed This Session**:
${completedItems.map(i => `- ✅ ${i.text}`).join('\n')}
` : 'No checklist updates'}

---
*Synced via /ccpm:sync*
```

### Step 8: Update Linear Issue

**A) Update checklist in description:**

**Use the Task tool to update the checklist:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: update_checklist_items
  params:
    issue_id: "{issue ID from step 1}"
    indices: [{list of completed item indices from step 6}]
    mark_complete: true
    add_comment: false  # We'll add the full progress report separately
    update_timestamp: true
  context:
    command: "sync"
    purpose: "Marking completed checklist items based on git changes"
  ```

**Note**: This operation uses the shared checklist helpers (`_shared-checklist-helpers.md`) for consistent parsing and updating. It will:
- Parse the checklist using marker comments or header detection
- Update the specified indices (mark as complete)
- Recalculate progress percentage
- Update the progress line with timestamp
- Return structured result with before/after progress

**B) Add progress comment:**

**Use the Task tool to add a progress comment:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: create_comment
  params:
    issueId: "{issue ID from step 1}"
    body: |
      {the progress report from step 7}
  context:
    command: "sync"
  ```

### Step 9: Display Confirmation & Next Actions

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Progress Synced to Linear!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId} - ${issue.title}
🔗 ${issue.url}

📝 Synced:
  ✅ ${totalFiles} files changed
  ✅ ${completedItems.length} checklist items updated
  💬 Progress comment added

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

If user provides summary argument, skip interactive mode:

1. Skip checklist AI analysis
2. Skip AskUserQuestion
3. Use provided summary directly
4. Create simple progress comment
5. No automatic checklist updates

**Example:**
```bash
/ccpm:sync PSN-29 "Completed auth implementation, all tests passing"
```

**Output:**
```
✅ Quick sync complete!
💬 Comment added to Linear
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

### Example 1: Auto-detect with changes

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
# ✅ 0: Implement JWT authentication (High confidence)
# ✅ 2: Add login form (High confidence)
#
# [Interactive checklist update...]
#
# ✅ Progress Synced to Linear!
```

### Example 2: Quick sync with summary

```bash
/ccpm:sync PSN-29 "Finished refactoring auth module"

# Output:
# ✅ Quick sync complete!
# 💬 Comment added to Linear
```

### Example 3: Summary-only (auto-detect issue)

```bash
# Branch: feature/PSN-29-add-auth
/ccpm:sync "Completed UI components, tests passing"

# Output:
# ✅ Detected issue: PSN-29
# ✅ Quick sync complete!
```

## Token Budget Breakdown

| Section | Tokens | Notes |
|---------|--------|-------|
| Frontmatter & description | 80 | Minimal metadata |
| Step 1: Argument parsing | 250 | Git detection + validation |
| Step 2: Git changes | 200 | Parallel bash execution |
| Step 3: Fetch issue | 150 | Linear subagent (cached) |
| Step 4: Auto-summary | 100 | Simple generation logic |
| Step 5: AI checklist analysis | 300 | Scoring algorithm |
| Step 6: Interactive update | 200 | AskUserQuestion |
| Step 7: Build report | 200 | Markdown generation |
| Step 8: Update Linear | 200 | Subagent batch operations |
| Step 9: Confirmation | 150 | Next actions menu |
| Quick sync mode | 100 | Manual summary path |
| Error handling | 100 | 4 scenarios |
| Examples | 270 | 3 concise examples |
| **Total** | **~2,100** | **vs ~6,000 baseline (65% reduction)** |

## Key Optimizations

1. ✅ **Linear subagent** - All Linear ops cached (85-95% hit rate)
2. ✅ **Parallel git operations** - Single bash call for all git info
3. ✅ **No routing overhead** - Direct implementation (no /ccpm:implementation:sync call)
4. ✅ **Smart defaults** - Auto-generates summary from changes
5. ✅ **Quick sync mode** - Skip interactions when summary provided
6. ✅ **Batch updates** - Single subagent call for description + comment

## Integration with Other Commands

- **During work** → Use `/ccpm:sync` to save progress
- **After sync** → Use `/ccpm:commit` for git commits
- **Before completion** → Use `/ccpm:verify` for quality checks
- **Resume work** → Use `/ccpm:work` to continue

## Notes

- **Git detection**: Extracts issue ID from branch names like `feature/PSN-29-add-auth`
- **AI suggestions**: Analyzes git changes to pre-select completed checklist items
- **Caching**: Linear subagent caches issue data for faster operations
- **Flexible**: Works with or without arguments, adapts to context
