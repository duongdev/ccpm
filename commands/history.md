---
description: Show activity timeline for issues, git, and project
allowed-tools: [Bash, Task, Read]
argument-hint: "[issue-id] [--git] [--linear] [--days=N]"
---

# /ccpm:history - Activity Timeline

Display chronological activity history from git commits, Linear comments, and status changes.

## Usage

```bash
# History for current issue (auto-detect from branch)
/ccpm:history

# History for specific issue
/ccpm:history PSN-29

# Git history only
/ccpm:history --git

# Linear activity only
/ccpm:history --linear

# Last N days (default: 7)
/ccpm:history --days=14

# Combine sources
/ccpm:history PSN-29 --days=3
```

## Implementation

### Step 1: Parse Arguments

```javascript
let issueId = null;
let options = {
  git: true,     // Include git commits by default
  linear: true,  // Include Linear activity by default
  days: 7        // Default to last 7 days
};

for (const arg of args) {
  if (arg.match(/^[A-Z]+-\d+$/)) {
    issueId = arg;
  } else if (arg === '--git') {
    options.linear = false;
  } else if (arg === '--linear') {
    options.git = false;
  } else if (arg.startsWith('--days=')) {
    options.days = parseInt(arg.replace('--days=', ''), 10) || 7;
  }
}

// Auto-detect issue from git branch
if (!issueId) {
  const branch = await Bash('git rev-parse --abbrev-ref HEAD');
  const match = branch.match(/([A-Z]+-\d+)/);
  if (match) {
    issueId = match[1];
    console.log(`📌 Detected issue from branch: ${issueId}`);
  }
}
```

### Step 2: Gather Git History

```javascript
let gitEvents = [];

if (options.git) {
  const since = new Date(Date.now() - options.days * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

  // Get git log with structured format
  const gitLog = await Bash(`git log --since="${since}" --format="%H|%ai|%an|%s" --all 2>/dev/null || echo ""`);

  if (gitLog.trim()) {
    gitLog.trim().split('\n').forEach(line => {
      const [hash, date, author, message] = line.split('|');

      // Filter by issue if specified
      if (!issueId || message.toLowerCase().includes(issueId.toLowerCase())) {
        gitEvents.push({
          type: 'git_commit',
          date: new Date(date),
          icon: '📝',
          title: `Commit: ${message}`,
          detail: `by ${author} (${hash.substring(0, 7)})`,
          source: 'git'
        });
      }
    });
  }

  // Get recent branch activity
  const branchLog = await Bash(`git for-each-ref --sort=-committerdate --format='%(refname:short)|%(committerdate:iso8601)|%(authorname)' refs/heads/ | head -10`);

  branchLog.trim().split('\n').forEach(line => {
    const [branch, date, author] = line.split('|');
    if (issueId && branch.toLowerCase().includes(issueId.toLowerCase())) {
      gitEvents.push({
        type: 'git_branch',
        date: new Date(date),
        icon: '🌿',
        title: `Branch: ${branch}`,
        detail: `by ${author}`,
        source: 'git'
      });
    }
  });
}
```

### Step 3: Gather Linear History

```javascript
let linearEvents = [];

if (options.linear && issueId) {
  // Fetch issue with history
  const result = await Task({
    subagent_type: 'ccpm:linear-operations',
    prompt: `operation: get_issue_history
params:
  issueId: ${issueId}
  includeComments: true
  includeHistory: true
context:
  cache: false  # Fresh data for history
  command: history`
  });

  if (result.issue) {
    const issue = result.issue;

    // Issue creation
    linearEvents.push({
      type: 'linear_created',
      date: new Date(issue.createdAt),
      icon: '✨',
      title: `Issue created: ${issue.title}`,
      detail: `by ${issue.creator?.name || 'Unknown'}`,
      source: 'linear'
    });

    // Comments
    if (result.comments) {
      result.comments.forEach(comment => {
        // Detect comment type from content
        let icon = '💬';
        let title = 'Comment';

        if (comment.body.includes('🚀 **Started**')) {
          icon = '🚀';
          title = 'Work started';
        } else if (comment.body.includes('🔄 **Synced**')) {
          icon = '🔄';
          title = 'Progress synced';
        } else if (comment.body.includes('✅ **Completed**')) {
          icon = '✅';
          title = 'Task completed';
        } else if (comment.body.includes('🔄 **Continued**')) {
          icon = '🔄';
          title = 'Work resumed';
        }

        linearEvents.push({
          type: 'linear_comment',
          date: new Date(comment.createdAt),
          icon: icon,
          title: title,
          detail: comment.body.split('\n')[0].substring(0, 60) + '...',
          source: 'linear',
          author: comment.user?.name || 'Unknown'
        });
      });
    }

    // Status changes (from history if available)
    if (result.history) {
      result.history.forEach(entry => {
        if (entry.field === 'state') {
          linearEvents.push({
            type: 'linear_status',
            date: new Date(entry.createdAt),
            icon: '📊',
            title: `Status: ${entry.fromValue} → ${entry.toValue}`,
            detail: `by ${entry.actor?.name || 'Unknown'}`,
            source: 'linear'
          });
        }
      });
    }
  }
}
```

### Step 4: Merge and Sort Events

```javascript
// Combine all events
const allEvents = [...gitEvents, ...linearEvents];

// Sort by date (newest first)
allEvents.sort((a, b) => b.date - a.date);

// Filter by date range
const cutoff = new Date(Date.now() - options.days * 24 * 60 * 60 * 1000);
const filteredEvents = allEvents.filter(e => e.date >= cutoff);
```

### Step 5: Display Timeline

```javascript
console.log('═══════════════════════════════════════');
console.log('📅 Activity Timeline');
console.log('═══════════════════════════════════════\n');

// Show context
if (issueId) {
  console.log(`📋 Issue: ${issueId}`);
}
console.log(`📆 Period: Last ${options.days} days`);
console.log(`📊 Sources: ${[options.git ? 'Git' : null, options.linear ? 'Linear' : null].filter(Boolean).join(', ')}`);
console.log('');

if (filteredEvents.length === 0) {
  console.log('No activity found in this period.\n');
  console.log('💡 Try:');
  console.log('   - Extending the date range: --days=30');
  console.log('   - Including all sources: /ccpm:history');
  return;
}

console.log(`Found ${filteredEvents.length} event(s):\n`);

// Group by date
let currentDate = null;
filteredEvents.forEach(event => {
  const dateStr = event.date.toISOString().split('T')[0];

  if (dateStr !== currentDate) {
    currentDate = dateStr;
    const dayName = event.date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
    console.log(`\n── ${dayName} ──────────────────────`);
  }

  const time = event.date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
  const sourceTag = event.source === 'git' ? '[Git]' : '[Linear]';

  console.log(`${event.icon} ${time} ${event.title}`);
  console.log(`   ${event.detail}`);
});

console.log('\n───────────────────────────────────────');

// Summary stats
const gitCount = filteredEvents.filter(e => e.source === 'git').length;
const linearCount = filteredEvents.filter(e => e.source === 'linear').length;

console.log('\n📊 Summary');
if (options.git) console.log(`   Git: ${gitCount} events`);
if (options.linear) console.log(`   Linear: ${linearCount} events`);

// Quick commands
console.log('\n💡 Quick Commands');
console.log('   /ccpm:history --days=30  - Extended history');
console.log('   /ccpm:status             - Current status');
```

## Example Output

```
═══════════════════════════════════════
📅 Activity Timeline
═══════════════════════════════════════

📋 Issue: PSN-29
📆 Period: Last 7 days
📊 Sources: Git, Linear

Found 8 event(s):

── Thu, Dec 19 ────────────────────
🔄 03:45 PM Progress synced
   🔄 **Synced** | feature/psn-29-auth  Completed a...
📝 03:30 PM Commit: feat(auth): add JWT middleware
   by John Doe (a1b2c3d)

── Wed, Dec 18 ────────────────────
🚀 10:15 AM Work started
   🚀 **Started** | feature/psn-29-auth  **Focus**: P...
📊 10:14 AM Status: Planned → In Progress
   by John Doe
🌿 10:10 AM Branch: feature/psn-29-add-auth
   by John Doe

── Mon, Dec 16 ────────────────────
✨ 02:30 PM Issue created: Add user authentication
   by Jane Smith

───────────────────────────────────────

📊 Summary
   Git: 3 events
   Linear: 5 events

💡 Quick Commands
   /ccpm:history --days=30  - Extended history
   /ccpm:status             - Current status
```

## Event Types

| Icon | Type | Source | Description |
|------|------|--------|-------------|
| ✨ | Issue Created | Linear | New issue opened |
| 📊 | Status Change | Linear | State transition |
| 🚀 | Work Started | Linear | Implementation began |
| 🔄 | Progress Synced | Linear | /ccpm:sync executed |
| ✅ | Completed | Linear | Task marked done |
| 💬 | Comment | Linear | General comment |
| 📝 | Commit | Git | Code committed |
| 🌿 | Branch | Git | Branch created/updated |

## Integration

- Combines git log and Linear API data
- Auto-detects issue from current branch
- Uses `ccpm:linear-operations` with fresh data (no cache)
- Chronological ordering across sources
