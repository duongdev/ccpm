# Shared Workflow State Detection

This file provides workflow state detection utilities used by the new natural workflow commands (`plan`, `work`, `sync`, `commit`, `verify`, `done`).

## Purpose

Detect potential workflow issues before executing commands:
- Uncommitted changes before creating new task
- Stale sync (>2h) before starting work
- Incomplete tasks before finalizing
- Wrong branch before operations

## Architecture

**Linear Operations**: This file delegates all Linear read operations to the `linear-operations` subagent for optimal token usage and caching.

**Git Operations**: All git-based state detection remains local in this file (no external dependencies).

**Function Classification**:
- Linear read functions (use subagent): `detectStaleSync()`, `checkTaskCompletion()`
- Pure git functions (local): `detectUncommittedChanges()`, `detectActiveWork()`, `isBranchPushed()`

## State Detection Functions

### 1. Detect Uncommitted Changes

```javascript
function detectUncommittedChanges() {
  try {
    const status = execSync('git status --porcelain', {
      encoding: 'utf-8'
    }).trim()

    if (status.length === 0) {
      return { hasChanges: false }
    }

    // Parse changes
    const lines = status.split('\n')
    const changes = lines.map(line => {
      const status = line.substring(0, 2)
      const path = line.substring(3)
      return { status: status.trim(), path }
    })

    return {
      hasChanges: true,
      count: changes.length,
      changes,
      summary: generateChangeSummary(changes)
    }
  } catch (error) {
    return { hasChanges: false, error: 'Not a git repository' }
  }
}

function generateChangeSummary(changes) {
  const modified = changes.filter(c => c.status === 'M').length
  const added = changes.filter(c => c.status === 'A' || c.status === '??').length
  const deleted = changes.filter(c => c.status === 'D').length

  const parts = []
  if (modified > 0) parts.push(`${modified} modified`)
  if (added > 0) parts.push(`${added} new`)
  if (deleted > 0) parts.push(`${deleted} deleted`)

  return parts.join(', ')
}
```

### 2. Detect Stale Sync

Uses Linear subagent to fetch issue comments, then compares with current time.

```javascript
async function detectStaleSync(issueId) {
  try {
    // Step 1: Fetch issue with comments via Linear subagent
    const linearResult = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: true
context:
  command: "workflow:detect-stale"
  purpose: "Checking if Linear comments are stale"
`);

    if (!linearResult.success) {
      return {
        isStale: false,
        error: linearResult.error?.message || 'Failed to fetch issue'
      }
    }

    const issue = linearResult.data
    const comments = issue.comments || []

    // Step 2: Find most recent sync comment (local logic)
    const syncComments = comments.filter(c =>
      c.body.includes('## 🔄 Progress Sync') ||
      c.body.includes('Progress Sync') ||
      c.body.includes('📝 Implementation Progress')
    )

    if (syncComments.length === 0) {
      return { isStale: false, reason: 'No previous sync' }
    }

    // Step 3: Compare timestamps (local logic)
    const lastSync = syncComments[syncComments.length - 1]
    const lastSyncTime = new Date(lastSync.createdAt)
    const now = new Date()
    const hoursSinceSync = (now - lastSyncTime) / (1000 * 60 * 60)

    return {
      isStale: hoursSinceSync > 2,
      hoursSinceSync: Math.round(hoursSinceSync * 10) / 10,
      lastSyncTime: lastSyncTime.toISOString()
    }
  } catch (error) {
    return { isStale: false, error: error.message }
  }
}
```

**Note**: The Linear subagent caches comments at session level, making subsequent calls very fast (<50ms).
The parsing and comparison logic remains local for full control over stale detection thresholds.

### 3. Detect Active Work on Another Task

```javascript
async function detectActiveWork(currentIssueId) {
  try {
    // Check git branch for different issue
    const branch = execSync('git rev-parse --abbrev-ref HEAD', {
      encoding: 'utf-8'
    }).trim()

    const branchMatch = branch.match(/([A-Z]+-\d+)/)
    if (branchMatch && branchMatch[1] !== currentIssueId) {
      return {
        hasActiveWork: true,
        activeIssueId: branchMatch[1],
        branch
      }
    }

    // Check for uncommitted work
    const uncommitted = detectUncommittedChanges()
    if (uncommitted.hasChanges) {
      return {
        hasActiveWork: true,
        uncommittedChanges: uncommitted
      }
    }

    return { hasActiveWork: false }
  } catch (error) {
    return { hasActiveWork: false, error: error.message }
  }
}
```

### 4. Check If Branch is Pushed

```javascript
function isBranchPushed() {
  try {
    execSync('git rev-parse @{u}', { stdio: 'ignore' })
    return { isPushed: true }
  } catch {
    const branch = execSync('git rev-parse --abbrev-ref HEAD', {
      encoding: 'utf-8'
    }).trim()

    return {
      isPushed: false,
      branch,
      command: `git push -u origin ${branch}`
    }
  }
}
```

### 5. Check Task Completion Status

Uses Linear subagent to fetch issue description, then parses checklist locally.

```javascript
async function checkTaskCompletion(issueId) {
  try {
    // Step 1: Fetch issue via Linear subagent
    const linearResult = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_comments: false
  include_attachments: false
context:
  command: "workflow:check-completion"
  purpose: "Checking task completion status from checklist"
`);

    if (!linearResult.success) {
      return {
        hasChecklist: false,
        isComplete: false,
        error: linearResult.error?.message || 'Failed to fetch issue'
      }
    }

    const issue = linearResult.data

    // Step 2: Parse checklist from description (local logic)
    const description = issue.description || ''
    const checklistMatch = description.match(/- \[([ x])\]/g)

    if (!checklistMatch) {
      return {
        hasChecklist: false,
        isComplete: true // No checklist = assume complete
      }
    }

    // Step 3: Calculate completion percentage (local logic)
    const total = checklistMatch.length
    const completed = checklistMatch.filter(m => m.includes('[x]')).length
    const percent = Math.round((completed / total) * 100)

    return {
      hasChecklist: true,
      isComplete: completed === total,
      total,
      completed,
      percent,
      remaining: total - completed
    }
  } catch (error) {
    return { hasChecklist: false, isComplete: false, error: error.message }
  }
}
```

**Note**: The Linear subagent caches issue descriptions at session level.
The regex parsing and completion calculation remain local for full control over what constitutes "completion".

## Usage in Commands

### In `/ccpm:plan` (before creating new task)

```javascript
// Check for active work before creating new task
const activeWork = await detectActiveWork(null)

if (activeWork.hasActiveWork) {
  console.log("⚠️  You have active work in progress")
  console.log("")

  if (activeWork.activeIssueId) {
    console.log(`Current branch: ${activeWork.branch}`)
    console.log(`Active issue: ${activeWork.activeIssueId}`)
  }

  if (activeWork.uncommittedChanges) {
    console.log(`Uncommitted changes: ${activeWork.uncommittedChanges.summary}`)
  }

  console.log("")
  console.log("Recommendation:")
  console.log("  1. Commit current work: /ccpm:commit")
  console.log("  2. Or sync progress: /ccpm:sync")
  console.log("  3. Then create new task")
  console.log("")

  // Ask user if they want to proceed anyway
  const answer = await askUser("Create new task anyway?")
  if (answer !== "Yes") {
    process.exit(0)
  }
}
```

### In `/ccpm:work` (before starting work)

```javascript
// Check for stale sync
const staleCheck = await detectStaleSync(issueId)

if (staleCheck.isStale) {
  console.log(`⚠️  Last sync was ${staleCheck.hoursSinceSync} hours ago`)
  console.log("")
  console.log("Recommendation: Sync progress first")
  console.log(`  /ccpm:sync ${issueId}`)
  console.log("")

  const answer = await askUser("Continue without syncing?")
  if (answer !== "Yes") {
    process.exit(0)
  }
}
```

### In `/ccpm:done` (before finalizing)

```javascript
// Check task completion
const completion = await checkTaskCompletion(issueId)

if (completion.hasChecklist && !completion.isComplete) {
  console.log(`⚠️  Task is only ${completion.percent}% complete`)
  console.log(`   ${completion.remaining} checklist items remaining`)
  console.log("")
  console.log("Recommendation: Complete all tasks first")
  console.log(`  /ccpm:work ${issueId}`)
  console.log("")

  const answer = await askUser("Finalize incomplete task?")
  if (answer !== "Yes") {
    process.exit(0)
  }
}

// Check if branch is pushed
const pushCheck = isBranchPushed()

if (!pushCheck.isPushed) {
  console.error("❌ Branch not pushed to remote")
  console.log("")
  console.log(`Push first: ${pushCheck.command}`)
  process.exit(1)
}
```

## Warning Display Template

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Workflow Warning
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${warningMessage}

${recommendation}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Subagent Integration

### Linear Operations Subagent

Two functions in this file use the `linear-operations` subagent for optimized read operations:

1. **`detectStaleSync(issueId)`**
   - Uses: `linear-operations` with `get_issue` operation
   - Fetches: Issue with comments (`include_comments: true`)
   - Local logic: Filters sync comments, compares timestamps
   - Performance: <50ms for cached calls, ~400-500ms for uncached
   - Caching: Session-level cache automatically populated

2. **`checkTaskCompletion(issueId)`**
   - Uses: `linear-operations` with `get_issue` operation
   - Fetches: Issue description only (no comments/attachments)
   - Local logic: Regex parsing, completion calculation
   - Performance: <50ms for cached calls, ~400-500ms for uncached
   - Caching: Session-level cache automatically populated

### Why Use the Subagent?

- **Token Efficiency**: 60-70% fewer tokens vs direct Linear MCP calls
- **Caching**: Session-level cache hits = massive performance boost
- **Consistency**: Single source of truth for Linear API interactions
- **Error Handling**: Standardized error responses with helpful suggestions
- **Maintainability**: Linear API changes isolated to subagent

### Error Handling

Both functions gracefully handle subagent errors:

```javascript
if (!linearResult.success) {
  return {
    isStale: false,  // or appropriate default
    error: linearResult.error?.message || 'Fallback error message'
  }
}
```

If the subagent fails to fetch Linear data, the workflow continues with safe defaults rather than blocking.

### Subagent Task Format

Both functions use the standard CCPM subagent invocation pattern:

```javascript
const result = await Task('linear-operations', `
operation: <operation_name>
params:
  <param_name>: <value>
  ...
context:
  command: "workflow:..."
  purpose: "..."
`);
```

Key fields:
- `operation`: The subagent operation (e.g., `get_issue`)
- `params`: Operation parameters with issue_id/team/etc
- `context`: Metadata for logging and command tracking
- `success`: Result boolean indicating success/failure
- `data`: Operation response (issue object, etc)
- `error`: Error details if success=false
- `metadata`: Execution metrics (duration_ms, mcp_calls, cached flag)

## Benefits

✅ **Prevents Common Mistakes**: Catches issues before they cause problems
✅ **Actionable Recommendations**: Always suggests what to do next
✅ **User Control**: Warnings, not errors - user can proceed if needed
✅ **Context Aware**: Different checks for different workflow stages
✅ **Optimized Linear Reads**: Uses subagent caching for 60-70% token reduction
✅ **Pure Git Operations**: All git logic remains fast and local
