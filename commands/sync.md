---
description: Smart sync command - save progress to Linear (auto-detect task)
allowed-tools: [Bash, LinearMCP, Read, Glob, Grep]
argument-hint: "[issue-id] [summary]"
---

# Smart Sync Command

You are executing the **smart sync command** that automatically detects the current task and syncs progress to Linear.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

## Auto-Detection

The command can detect the issue ID from:
1. **Command argument** (if provided): `/ccpm:sync PSN-27`
2. **Git branch name** (if no argument): `/ccpm:sync` (detects from branch)
3. **Last worked issue** (from Linear state, future enhancement)

## Implementation

### Step 1: Determine Issue ID

```javascript
const args = process.argv.slice(2)
let issueId = args[0]
let summary = args[1]

// If first arg looks like summary text (not issue ID), treat as summary
const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/
if (args[0] && !ISSUE_ID_PATTERN.test(args[0])) {
  summary = args[0]
  issueId = null
}

// If no issue ID provided, try to detect from context
if (!issueId) {
  console.log("🔍 No issue ID provided, detecting from git branch...")

  try {
    // Get current branch
    const branch = execSync('git rev-parse --abbrev-ref HEAD', {
      encoding: 'utf-8'
    }).trim()

    // Pattern: username/PROJ-123-feature-name or PROJ-123-feature-name
    const branchMatch = branch.match(/([A-Z]+-\d+)/)

    if (branchMatch) {
      issueId = branchMatch[1]
      console.log(`✅ Detected issue from branch: ${issueId}`)
    } else {
      console.error("❌ Could not detect issue ID from branch name")
      console.log("")
      console.log("Branch name should include issue ID:")
      console.log("  Example: duongdev/PSN-27-add-feature")
      console.log("")
      console.log("Or provide issue ID explicitly:")
      console.log("  /ccpm:sync PSN-27")
      console.log("  /ccpm:sync PSN-27 \"Made progress on auth\"")
      process.exit(1)
    }
  } catch (error) {
    console.error("❌ Error: Not in a git repository")
    console.log("")
    console.log("Please provide an issue ID:")
    console.log("  /ccpm:sync PSN-27")
    process.exit(1)
  }
}

// Validate issue ID format
if (!ISSUE_ID_PATTERN.test(issueId)) {
  console.error(`❌ Error: Invalid issue ID format: ${issueId}`)
  console.log("Expected format: PROJECT-NUMBER (e.g., PSN-27, WORK-123)")
  process.exit(1)
}
```

### Step 2: Display Detected Context

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Smart Sync Command
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId}
${summary ? `📝 Summary: ${summary}` : ''}

Analyzing changes and syncing to Linear...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 3: Detect Git Changes

Use **Bash** to gather git information:

```bash
# Get changed files (staged + unstaged)
git status --porcelain

# Get uncommitted changes summary
git diff --stat HEAD
git diff --cached --stat

# Get current branch
git rev-parse --abbrev-ref HEAD
```

### Step 4: Show Changes Summary

```markdown
📊 Detected Changes:
────────────────────

${changedFiles.length > 0 ? `
Modified/New Files (${changedFiles.length}):
${changedFiles.map((file, i) => `  ${i+1}. ${file.path} (${file.stats})`).join('\n')}

${changedFiles.length > 5 ? '  ... and more' : ''}

📈 Total: +${insertions} insertions, -${deletions} deletions
` : `
✅ No uncommitted changes detected
ℹ️  All work committed to git
`}

${hasCommitsSinceLastSync ? `
📝 Recent Commits:
${recentCommits.slice(0, 3).map(c => `  • ${c.hash.substr(0,7)} ${c.message}`).join('\n')}
` : ''}
```

### Step 5: Route to implementation:sync

Now route to the underlying sync command with gathered context:

```javascript
console.log("")
console.log("⚡ Routing to: /ccpm:implementation:sync")
console.log("")

// Build command with arguments
let syncCommand = `/ccpm:implementation:sync ${issueId}`

// Add summary if provided or auto-generate
if (summary) {
  syncCommand += ` "${summary}"`
} else if (changedFiles.length > 0) {
  // Auto-generate summary from changes
  const autoSummary = generateAutoSummary(changedFiles)
  syncCommand += ` "${autoSummary}"`
}

SlashCommand(syncCommand)
```

## Helper Functions

### Generate Auto Summary

```javascript
function generateAutoSummary(changedFiles) {
  const categories = {
    src: [],
    test: [],
    config: [],
    docs: []
  }

  changedFiles.forEach(file => {
    if (file.path.includes('test') || file.path.includes('spec')) {
      categories.test.push(file)
    } else if (file.path.includes('src/')) {
      categories.src.push(file)
    } else if (file.path.match(/\.(config|json|yaml|yml)$/)) {
      categories.config.push(file)
    } else if (file.path.match(/\.(md|txt)$/)) {
      categories.docs.push(file)
    }
  })

  const parts = []
  if (categories.src.length > 0) {
    parts.push(`Updated ${categories.src.length} source file(s)`)
  }
  if (categories.test.length > 0) {
    parts.push(`${categories.test.length} test file(s)`)
  }
  if (categories.config.length > 0) {
    parts.push(`config changes`)
  }
  if (categories.docs.length > 0) {
    parts.push(`documentation`)
  }

  return parts.join(', ') || 'Work in progress'
}
```

## Examples

### Example 1: Sync with Explicit Issue ID

```bash
/ccpm:sync PSN-27
```

**Detection**: Issue ID provided explicitly
**Action**: Sync progress to PSN-27
**Summary**: Auto-generated from git changes

### Example 2: Sync with Issue ID and Custom Summary

```bash
/ccpm:sync PSN-27 "Completed auth implementation"
```

**Detection**: Issue ID and summary provided
**Action**: Sync to PSN-27 with custom summary

### Example 3: Auto-Detect from Branch

```bash
git checkout -b duongdev/PSN-27-add-feature
# ... make changes ...
/ccpm:sync
```

**Detection**: PSN-27 detected from branch name
**Action**: Sync progress to PSN-27
**Summary**: Auto-generated

### Example 4: Sync with Summary Only (Auto-Detect Issue)

```bash
git checkout -b duongdev/PSN-27-add-feature
/ccpm:sync "Finished UI components"
```

**Detection**: PSN-27 from branch, custom summary provided
**Action**: Sync to PSN-27 with custom summary

## Additional Features

### Uncommitted Changes Warning

If there are many uncommitted changes:

```markdown
⚠️  You have ${changedFiles.length} uncommitted files

Consider committing your work before syncing:
  /ccpm:commit
  (then)
  /ccpm:sync

Or continue to sync current progress anyway.
```

### No Changes Detected

If no changes since last sync:

```markdown
ℹ️  No new changes detected since last sync

Last sync: 2 hours ago

You can still update status or add notes if needed.
Continue? (y/n)
```

## Benefits

✅ **Auto-Detection**: No need to remember issue ID if on feature branch
✅ **Auto-Summary**: Generates summary from git changes
✅ **Smart Warnings**: Alerts about uncommitted work
✅ **Flexible**: Works with or without arguments
✅ **Fast**: Quick progress saves during work

## Migration Hint

This command replaces:
- `/ccpm:implementation:sync WORK-123` → Use `/ccpm:sync` (auto-detects)
- `/ccpm:implementation:sync WORK-123 "summary"` → Use `/ccpm:sync "summary"` (auto-detects)

The old command still works and will show hints to use this command.
