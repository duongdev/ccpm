---
description: Show current CCPM project and task status
allowed-tools: [Bash, Task, Read]
argument-hint: "[issue-id]"
---

# /ccpm:status - Show Project & Task Status

Displays current CCPM session status, active project, and task progress.

## Usage

```bash
# Show overall status
/ccpm:status

# Show specific issue status
/ccpm:status PSN-29

# Show project status
/ccpm:status --project
```

## What It Shows

1. **Session Context**
   - Active project
   - Current git branch
   - Detected Linear issue

2. **Task Progress**
   - Issue title and status
   - Checklist completion %
   - Recent activity

3. **Git Status**
   - Uncommitted changes
   - Branch sync status
   - Last commit info

4. **Workflow Suggestions**
   - Next recommended action
   - Available commands

## Implementation

### Step 1: Gather Context

```javascript
// Session state
const sessionFile = process.env.CCPM_SESSION_FILE;
let session = {};
if (sessionFile && fs.existsSync(sessionFile)) {
  session = JSON.parse(fs.readFileSync(sessionFile, 'utf8'));
}

// Git info
const gitBranch = await Bash('git rev-parse --abbrev-ref HEAD');
const gitStatus = await Bash('git status --porcelain');
const lastCommit = await Bash('git log -1 --format="%h %s" 2>/dev/null || echo "No commits"');

// Detect issue from branch or args
let issueId = args[0] || session.issueId;
if (!issueId && gitBranch) {
  const match = gitBranch.match(/([A-Z]+-\d+)/);
  if (match) issueId = match[1];
}
```

### Step 2: Fetch Issue Data (if available)

```javascript
let issue = null;
let checklistProgress = null;

if (issueId) {
  // Use Linear subagent
  const result = await Task({
    subagent_type: 'ccpm:linear-operations',
    prompt: `operation: get_issue
params:
  issueId: ${issueId}
context:
  cache: true
  command: status`
  });

  if (result.issue) {
    issue = result.issue;

    // Parse checklist
    const checklistMatch = issue.description?.match(/## Implementation Checklist[\s\S]*?(?=\n##|$)/);
    if (checklistMatch) {
      const checked = (checklistMatch[0].match(/- \[x\]/gi) || []).length;
      const total = (checklistMatch[0].match(/- \[[ x]\]/gi) || []).length;
      checklistProgress = total > 0 ? Math.round((checked / total) * 100) : null;
    }
  }
}
```

### Step 3: Display Status

```javascript
console.log('═══════════════════════════════════════');
console.log('📊 CCPM Status');
console.log('═══════════════════════════════════════\n');

// Project info
console.log('📁 Project');
console.log(`   Name: ${session.project || 'Not configured'}`);
console.log(`   Path: ${process.cwd()}`);
console.log('');

// Git info
console.log('🌿 Git');
console.log(`   Branch: ${gitBranch.trim()}`);
console.log(`   Changes: ${gitStatus.trim() ? gitStatus.split('\n').length + ' files' : 'Clean'}`);
console.log(`   Last Commit: ${lastCommit.trim()}`);
console.log('');

// Issue info
if (issue) {
  console.log('📋 Active Task');
  console.log(`   Issue: ${issue.identifier} - ${issue.title}`);
  console.log(`   Status: ${issue.state.name}`);
  if (checklistProgress !== null) {
    const bar = getProgressBar(checklistProgress);
    console.log(`   Progress: ${bar} ${checklistProgress}%`);
  }
  console.log(`   URL: ${issue.url}`);
  console.log('');
} else if (issueId) {
  console.log('📋 Active Task');
  console.log(`   Issue: ${issueId} (not found)`);
  console.log('');
} else {
  console.log('📋 Active Task');
  console.log('   No task detected');
  console.log('   💡 Create one with: /ccpm:plan "Your task"');
  console.log('');
}

// Workflow suggestions
console.log('💡 Suggestions');
if (!issue) {
  console.log('   → /ccpm:plan "Task description" to create a task');
} else if (issue.state.name === 'Backlog' || issue.state.name === 'Todo') {
  console.log('   → /ccpm:work to start implementation');
} else if (issue.state.name === 'In Progress') {
  if (gitStatus.trim()) {
    console.log('   → /ccpm:sync to save progress');
    console.log('   → /ccpm:commit to commit changes');
  } else if (checklistProgress === 100) {
    console.log('   → /ccpm:verify to run quality checks');
  } else {
    console.log('   → Continue implementation');
    console.log('   → /ccpm:sync when progress is made');
  }
} else if (issue.state.name === 'Verified') {
  console.log('   → /ccpm:done to finalize and create PR');
}
console.log('');

// Quick commands
console.log('📌 Quick Commands');
console.log('   /ccpm:work      - Start/resume work');
console.log('   /ccpm:sync      - Save progress');
console.log('   /ccpm:commit    - Commit changes');
console.log('   /ccpm:verify    - Quality checks');
console.log('   /ccpm:done      - Finalize task');
```

### Helper: Progress Bar

```javascript
function getProgressBar(percent) {
  const filled = Math.round(percent / 10);
  const empty = 10 - filled;
  const bar = '█'.repeat(filled) + '░'.repeat(empty);

  // Color based on progress
  if (percent < 30) return `🔴 ${bar}`;
  if (percent < 70) return `🟡 ${bar}`;
  return `🟢 ${bar}`;
}
```

## Example Output

```
═══════════════════════════════════════
📊 CCPM Status
═══════════════════════════════════════

📁 Project
   Name: ccpm
   Path: /Users/dev/personal/ccpm

🌿 Git
   Branch: feature/psn-29-auth
   Changes: 5 files
   Last Commit: a1b2c3d feat: add login form

📋 Active Task
   Issue: PSN-29 - Add user authentication
   Status: In Progress
   Progress: 🟡 ██████░░░░ 60%
   URL: https://linear.app/team/issue/PSN-29

💡 Suggestions
   → /ccpm:sync to save progress
   → /ccpm:commit to commit changes

📌 Quick Commands
   /ccpm:work      - Start/resume work
   /ccpm:sync      - Save progress
   /ccpm:commit    - Commit changes
   /ccpm:verify    - Quality checks
   /ccpm:done      - Finalize task
```

## Integration

- Uses session state from `/tmp/ccpm-session-*.json`
- Respects `CCPM_*` environment variables
- Caches Linear data for fast display
- Updates automatically on session refresh
