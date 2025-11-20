---
description: Smart finalize command - create PR, sync status, complete task
allowed-tools: [Bash, LinearMCP, AtlassianMCP, SlackMCP, GitHubMCP]
argument-hint: "[issue-id]"
---

# Smart Done Command

You are executing the **smart done command** that finalizes a task: creates PR, syncs status, and marks complete.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (internal tracking)
- ✅ **GitHub** PR creation is permitted (code hosting)
- ⛔ **Jira/Confluence/Slack** writes require user confirmation

## Auto-Detection

The command can detect the issue ID from:
1. **Command argument** (if provided): `/ccpm:done PSN-27`
2. **Git branch name** (if no argument): `/ccpm:done` (detects from branch)

## Implementation

### Step 1: Determine Issue ID

```javascript
const args = process.argv.slice(2)
let issueId = args[0]

const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/

// If no issue ID provided, try to detect from git branch
if (!issueId || !ISSUE_ID_PATTERN.test(issueId)) {
  try {
    const branch = execSync('git rev-parse --abbrev-ref HEAD', {
      encoding: 'utf-8'
    }).trim()

    const branchMatch = branch.match(/([A-Z]+-\d+)/)
    if (branchMatch) {
      issueId = branchMatch[1]
      console.log(`🔍 Detected issue from branch: ${issueId}`)
    } else {
      console.error("❌ Could not detect issue ID from branch name")
      console.log("")
      console.log("Please provide an issue ID:")
      console.log("  /ccpm:done PSN-27")
      process.exit(1)
    }
  } catch (error) {
    console.error("❌ Error: Not in a git repository or could not detect issue")
    console.log("")
    console.log("Please provide an issue ID:")
    console.log("  /ccpm:done PSN-27")
    process.exit(1)
  }
}
```

### Step 2: Display Finalization Flow

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Smart Done Command
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId}

Finalization Flow:
──────────────────
1. Create GitHub Pull Request
2. Sync status to Jira (if configured)
3. Send Slack notification (if configured)
4. Mark Linear task as complete

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 3: Pre-Flight Checks

Before routing to complete:finalize, perform safety checks:

```javascript
// Check if on main/master branch (shouldn't finalize from there)
const currentBranch = execSync('git rev-parse --abbrev-ref HEAD', {
  encoding: 'utf-8'
}).trim()

if (currentBranch === 'main' || currentBranch === 'master') {
  console.error("❌ Error: You're on the main/master branch")
  console.log("")
  console.log("Please checkout a feature branch first:")
  console.log(`  git checkout -b your-name/${issueId}-feature-name`)
  console.log("")
  process.exit(1)
}

// Check if branch is pushed to remote
let isPushed = false
try {
  execSync('git rev-parse @{u}', { stdio: 'ignore' })
  isPushed = true
} catch {
  isPushed = false
}

if (!isPushed) {
  console.log("⚠️  Branch not pushed to remote")
  console.log("")
  console.log("Push your branch first:")
  console.log(`  git push -u origin ${currentBranch}`)
  console.log("")
  console.log("Then run /ccpm:done again")
  process.exit(1)
}

// Check for uncommitted changes
const hasUncommitted = execSync('git status --porcelain', {
  encoding: 'utf-8'
}).trim().length > 0

if (hasUncommitted) {
  console.log("⚠️  You have uncommitted changes")
  console.log("")

  // Show changed files
  const status = execSync('git status --short', { encoding: 'utf-8' })
  console.log(status)
  console.log("")

  console.log("Commit your changes first:")
  console.log("  /ccpm:commit")
  console.log("")
  console.log("Then run /ccpm:done again")
  process.exit(1)
}
```

### Step 4: Route to complete:finalize

```javascript
console.log("✅ All pre-flight checks passed!")
console.log("")
console.log("⚡ Routing to: /ccpm:complete:finalize")
console.log("")

SlashCommand(`/ccpm:complete:finalize ${issueId}`)
```

## Examples

### Example 1: Done with Auto-Detection

```bash
git checkout -b duongdev/PSN-27-add-auth
# ... complete work, commit, push ...
/ccpm:done
```

**Detection**: PSN-27 from branch
**Checks**: Branch pushed, no uncommitted changes
**Result**: Creates PR, syncs, marks complete

### Example 2: Done with Explicit Issue ID

```bash
/ccpm:done PSN-27
```

**Checks**: Same pre-flight checks
**Result**: Task finalized

### Example 3: Done with Uncommitted Changes (Error)

```bash
/ccpm:done PSN-27
```

**Result**:
```
⚠️  You have uncommitted changes

M  src/api/auth.ts
?? src/tests/new-test.ts

Commit your changes first:
  /ccpm:commit

Then run /ccpm:done again
```

### Example 4: Done on Main Branch (Error)

```bash
git checkout main
/ccpm:done PSN-27
```

**Result**:
```
❌ Error: You're on the main/master branch

Please checkout a feature branch first:
  git checkout -b your-name/PSN-27-feature-name
```

## Pre-Flight Checks

This command runs several safety checks before finalizing:

1. **Branch Check**: Ensures not on main/master
2. **Push Check**: Ensures branch is pushed to remote
3. **Commit Check**: Ensures no uncommitted changes
4. **Linear Status**: Ensures task is in appropriate status

These checks prevent common mistakes:
- Creating PR from main branch
- Finalizing without pushing code
- Leaving uncommitted work
- Marking incomplete tasks as done

## Benefits

✅ **Auto-Detection**: No need to provide issue ID if on feature branch
✅ **Safety Checks**: Prevents common mistakes before finalizing
✅ **Clear Feedback**: Shows exactly what needs to be fixed
✅ **Smart Routing**: Routes to underlying finalize command
✅ **Complete Workflow**: Handles PR creation + external syncs

## Migration Hint

This command replaces:
- `/ccpm:complete:finalize` → Use `/ccpm:done` (auto-detects + safety checks)

The old command still works and will show hints to use this command.

## Error Handling

### If branch not pushed:
```markdown
⚠️  Branch not pushed to remote

Push your branch first:
  git push -u origin ${currentBranch}

Then run /ccpm:done again
```

### If uncommitted changes:
```markdown
⚠️  You have uncommitted changes

Commit them first:
  /ccpm:commit

Or stash them:
  git stash

Then run /ccpm:done again
```

### If on wrong branch:
```markdown
❌ Error: You're on the main/master branch

Checkout a feature branch:
  git checkout -b your-name/${issueId}-feature-name
```

## What Happens Next

After routing to `/ccpm:complete:finalize`, it will:

1. **Create GitHub PR**:
   - Title from Linear issue
   - Description with checklist summary
   - Links to Linear issue
   - Requests reviews

2. **Sync to Jira** (if configured):
   - ⛔ Requires user confirmation
   - Updates Jira ticket status
   - Adds PR link to Jira
   - Syncs completion

3. **Slack Notification** (if configured):
   - ⛔ Requires user confirmation
   - Posts to configured channel
   - Includes PR link and summary

4. **Mark Linear Complete**:
   - Updates status to "Done"
   - Adds completion comment
   - Archives if configured
