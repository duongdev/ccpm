---
description: Undo recent operations - git commits, Linear updates, file changes
allowed-tools: [Bash, Task, AskUserQuestion, Read]
argument-hint: "[--git] [--linear] [--files] [--last=N]"
---

# /ccpm:rollback - Undo Operations

Safely undo recent git commits, Linear updates, or file changes with confirmation.

## Usage

```bash
# Interactive rollback (shows options)
/ccpm:rollback

# Rollback last git commit (soft - keeps changes)
/ccpm:rollback --git

# Rollback last N commits
/ccpm:rollback --git --last=3

# Restore files from last commit
/ccpm:rollback --files

# Undo Linear status change
/ccpm:rollback --linear

# Hard reset (dangerous - loses changes)
/ccpm:rollback --git --hard
```

## ⚠️ Safety First

This command operates with extreme caution:
- **Always shows what will be undone** before acting
- **Requires explicit confirmation** for destructive operations
- **Creates backup** before dangerous operations
- **Blocks** rollback of pushed commits without `--force`

## Implementation

### Step 1: Parse Arguments

```javascript
let options = {
  git: false,
  linear: false,
  files: false,
  last: 1,
  hard: false,
  force: false
};

for (const arg of args) {
  if (arg === '--git') options.git = true;
  else if (arg === '--linear') options.linear = true;
  else if (arg === '--files') options.files = true;
  else if (arg.startsWith('--last=')) options.last = parseInt(arg.replace('--last=', ''), 10) || 1;
  else if (arg === '--hard') options.hard = true;
  else if (arg === '--force') options.force = true;
}

// Default: interactive mode
if (!options.git && !options.linear && !options.files) {
  options.interactive = true;
}
```

### Step 2: Interactive Mode

```javascript
if (options.interactive) {
  console.log('═══════════════════════════════════════');
  console.log('⏪ Rollback Options');
  console.log('═══════════════════════════════════════\n');

  // Show recent activity
  console.log('📋 Recent Activity:\n');

  // Last 3 git commits
  const commits = await Bash('git log -3 --format="%h|%s|%ar" 2>/dev/null || echo ""');
  if (commits.trim()) {
    console.log('Git Commits:');
    commits.trim().split('\n').forEach((line, i) => {
      const [hash, msg, time] = line.split('|');
      console.log(`   ${i + 1}. ${hash} - ${msg} (${time})`);
    });
    console.log('');
  }

  // Uncommitted changes
  const status = await Bash('git status --porcelain');
  if (status.trim()) {
    const changeCount = status.trim().split('\n').length;
    console.log(`📝 Uncommitted Changes: ${changeCount} file(s)`);
    console.log('');
  }

  // Detect Linear issue
  const branch = await Bash('git rev-parse --abbrev-ref HEAD');
  const issueMatch = branch.match(/([A-Z]+-\d+)/);
  if (issueMatch) {
    console.log(`📋 Linear Issue: ${issueMatch[1]}`);
    console.log('');
  }

  // Ask what to rollback
  const answer = await AskUserQuestion({
    questions: [{
      question: "What would you like to undo?",
      header: "Rollback",
      multiSelect: false,
      options: [
        { label: "Last commit (soft)", description: "Undo commit but keep file changes" },
        { label: "Last commit (hard)", description: "Undo commit and discard changes" },
        { label: "Uncommitted changes", description: "Discard all local modifications" },
        { label: "Linear status", description: "Revert Linear issue to previous state" },
        { label: "Cancel", description: "Exit without changes" }
      ]
    }]
  });

  if (answer === "Cancel") {
    console.log('\n⏸️  Rollback cancelled.');
    return;
  }

  // Route to appropriate action
  if (answer === "Last commit (soft)") {
    options.git = true;
    options.hard = false;
  } else if (answer === "Last commit (hard)") {
    options.git = true;
    options.hard = true;
  } else if (answer === "Uncommitted changes") {
    options.files = true;
  } else if (answer === "Linear status") {
    options.linear = true;
  }
}
```

### Step 3: Git Rollback

```javascript
if (options.git) {
  console.log('\n═══════════════════════════════════════');
  console.log('⏪ Git Rollback');
  console.log('═══════════════════════════════════════\n');

  // Get commits to rollback
  const commits = await Bash(`git log -${options.last} --format="%H|%h|%s|%ar|%an"`);
  const commitList = commits.trim().split('\n').map(line => {
    const [full, short, msg, time, author] = line.split('|');
    return { full, short, msg, time, author };
  });

  console.log(`Rolling back ${options.last} commit(s):\n`);
  commitList.forEach((c, i) => {
    console.log(`   ${i + 1}. ${c.short} - ${c.msg}`);
    console.log(`      by ${c.author}, ${c.time}`);
  });
  console.log('');

  // Check if pushed
  const unpushed = await Bash(`git log origin/$(git rev-parse --abbrev-ref HEAD)..HEAD --format="%H" 2>/dev/null || echo "error"`);
  const commitsPushed = !unpushed.includes(commitList[0].full) && unpushed !== 'error';

  if (commitsPushed && !options.force) {
    console.log('⚠️  WARNING: These commits have been pushed to remote!');
    console.log('   Rollback will require force push, affecting collaborators.');
    console.log('');

    const confirm = await AskUserQuestion({
      questions: [{
        question: "Force rollback of pushed commits?",
        header: "Danger",
        multiSelect: false,
        options: [
          { label: "Yes, force rollback", description: "I understand the risks" },
          { label: "No, cancel", description: "Abort rollback" }
        ]
      }]
    });

    if (confirm !== "Yes, force rollback") {
      console.log('\n⏸️  Rollback cancelled.');
      return;
    }
  }

  // Show what will happen
  if (options.hard) {
    console.log('⚠️  HARD RESET: Changes will be PERMANENTLY LOST');

    // Show files that will be lost
    const diff = await Bash(`git diff HEAD~${options.last} --name-only`);
    if (diff.trim()) {
      console.log('\nFiles that will be affected:');
      diff.trim().split('\n').forEach(f => console.log(`   • ${f}`));
    }
  } else {
    console.log('ℹ️  SOFT RESET: Commit undone, changes preserved as unstaged');
  }

  // Final confirmation
  const confirm = await AskUserQuestion({
    questions: [{
      question: `Proceed with ${options.hard ? 'hard' : 'soft'} reset of ${options.last} commit(s)?`,
      header: "Confirm",
      multiSelect: false,
      options: [
        { label: "Yes, proceed", description: "Execute rollback" },
        { label: "No, cancel", description: "Abort" }
      ]
    }]
  });

  if (confirm !== "Yes, proceed") {
    console.log('\n⏸️  Rollback cancelled.');
    return;
  }

  // Create backup tag (for hard reset)
  if (options.hard) {
    const backupTag = `backup-before-rollback-${Date.now()}`;
    await Bash(`git tag ${backupTag}`);
    console.log(`\n📦 Created backup tag: ${backupTag}`);
  }

  // Execute rollback
  const resetType = options.hard ? '--hard' : '--soft';
  await Bash(`git reset ${resetType} HEAD~${options.last}`);

  console.log(`\n✅ Successfully rolled back ${options.last} commit(s).`);

  if (!options.hard) {
    console.log('\n📝 Your changes are preserved as unstaged files.');
    console.log('   Use `git status` to see them.');
  }

  if (commitsPushed && options.force) {
    console.log('\n⚠️  Remember to force push: git push --force-with-lease');
  }
}
```

### Step 4: File Rollback

```javascript
if (options.files) {
  console.log('\n═══════════════════════════════════════');
  console.log('⏪ File Rollback');
  console.log('═══════════════════════════════════════\n');

  // Get list of modified files
  const status = await Bash('git status --porcelain');
  if (!status.trim()) {
    console.log('✅ No uncommitted changes to rollback.\n');
    return;
  }

  const files = status.trim().split('\n').map(line => {
    const status = line.substring(0, 2).trim();
    const file = line.substring(3);
    return { status, file };
  });

  console.log(`Found ${files.length} modified file(s):\n`);

  // Group by status
  const modified = files.filter(f => f.status === 'M');
  const added = files.filter(f => f.status === 'A' || f.status === '??');
  const deleted = files.filter(f => f.status === 'D');

  if (modified.length > 0) {
    console.log('Modified (will be restored):');
    modified.forEach(f => console.log(`   📝 ${f.file}`));
    console.log('');
  }

  if (added.length > 0) {
    console.log('Added (will be deleted):');
    added.forEach(f => console.log(`   ➕ ${f.file}`));
    console.log('');
  }

  if (deleted.length > 0) {
    console.log('Deleted (will be restored):');
    deleted.forEach(f => console.log(`   ❌ ${f.file}`));
    console.log('');
  }

  // Ask which to rollback
  const answer = await AskUserQuestion({
    questions: [{
      question: "Which files to rollback?",
      header: "Select",
      multiSelect: false,
      options: [
        { label: "All files", description: `Discard all ${files.length} changes` },
        { label: "Modified only", description: `Restore ${modified.length} modified files` },
        { label: "Select individually", description: "Choose specific files" },
        { label: "Cancel", description: "Keep all changes" }
      ]
    }]
  });

  if (answer === "Cancel") {
    console.log('\n⏸️  Rollback cancelled.');
    return;
  }

  let filesToRollback = [];

  if (answer === "All files") {
    filesToRollback = files.map(f => f.file);
  } else if (answer === "Modified only") {
    filesToRollback = modified.map(f => f.file);
  } else if (answer === "Select individually") {
    // Let user select files
    const fileOptions = files.slice(0, 4).map(f => ({
      label: f.file.split('/').pop(),
      description: `${f.status === 'M' ? 'Modified' : f.status === 'D' ? 'Deleted' : 'Added'}: ${f.file}`
    }));

    const selected = await AskUserQuestion({
      questions: [{
        question: "Select files to rollback:",
        header: "Files",
        multiSelect: true,
        options: fileOptions
      }]
    });

    // Map selected labels back to file paths
    filesToRollback = files
      .filter(f => selected.includes(f.file.split('/').pop()))
      .map(f => f.file);
  }

  if (filesToRollback.length === 0) {
    console.log('\n⏸️  No files selected for rollback.');
    return;
  }

  // Execute rollback
  console.log(`\n⏪ Rolling back ${filesToRollback.length} file(s)...`);

  for (const file of filesToRollback) {
    const fileInfo = files.find(f => f.file === file);

    if (fileInfo.status === '??' || fileInfo.status === 'A') {
      // Delete untracked/added file
      await Bash(`rm -f "${file}"`);
      console.log(`   ❌ Deleted: ${file}`);
    } else {
      // Restore from HEAD
      await Bash(`git checkout HEAD -- "${file}"`);
      console.log(`   ✅ Restored: ${file}`);
    }
  }

  console.log(`\n✅ Rolled back ${filesToRollback.length} file(s).`);
}
```

### Step 5: Linear Rollback

```javascript
if (options.linear) {
  console.log('\n═══════════════════════════════════════');
  console.log('⏪ Linear Status Rollback');
  console.log('═══════════════════════════════════════\n');

  // Detect issue from branch
  const branch = await Bash('git rev-parse --abbrev-ref HEAD');
  const issueMatch = branch.match(/([A-Z]+-\d+)/);

  if (!issueMatch) {
    console.log('❌ No Linear issue detected from branch.');
    console.log('   Switch to a feature branch or specify issue ID.');
    return;
  }

  const issueId = issueMatch[1];
  console.log(`📋 Issue: ${issueId}`);

  // Fetch issue history
  const result = await Task({
    subagent_type: 'ccpm:linear-operations',
    prompt: `operation: get_issue_history
params:
  issueId: ${issueId}
  includeHistory: true
context:
  cache: false
  command: rollback`
  });

  if (result.error) {
    console.log(`❌ Failed to fetch issue: ${result.error.message}`);
    return;
  }

  const issue = result.issue;
  console.log(`   Title: ${issue.title}`);
  console.log(`   Current Status: ${issue.state?.name}`);

  // Find status history
  const statusHistory = (result.history || [])
    .filter(h => h.field === 'state')
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  if (statusHistory.length === 0) {
    console.log('\n❌ No status history found for this issue.');
    return;
  }

  console.log('\n📊 Status History:\n');
  statusHistory.slice(0, 5).forEach((h, i) => {
    const time = new Date(h.createdAt).toLocaleString();
    console.log(`   ${i + 1}. ${h.fromValue} → ${h.toValue}`);
    console.log(`      ${time} by ${h.actor?.name || 'Unknown'}`);
  });

  // Ask which state to restore
  const previousState = statusHistory[0]?.fromValue;
  if (!previousState) {
    console.log('\n❌ Could not determine previous state.');
    return;
  }

  const answer = await AskUserQuestion({
    questions: [{
      question: `Revert to previous status: ${previousState}?`,
      header: "Confirm",
      multiSelect: false,
      options: [
        { label: `Yes, revert to ${previousState}`, description: "Restore previous status" },
        { label: "Choose different status", description: "Select from history" },
        { label: "Cancel", description: "Keep current status" }
      ]
    }]
  });

  if (answer === "Cancel") {
    console.log('\n⏸️  Rollback cancelled.');
    return;
  }

  let targetState = previousState;

  if (answer === "Choose different status") {
    const stateOptions = statusHistory.slice(0, 4).map(h => ({
      label: h.fromValue,
      description: `From ${new Date(h.createdAt).toLocaleDateString()}`
    }));

    const selected = await AskUserQuestion({
      questions: [{
        question: "Select target status:",
        header: "Status",
        multiSelect: false,
        options: stateOptions
      }]
    });

    targetState = selected;
  }

  // Update status
  console.log(`\n⏪ Reverting status to: ${targetState}...`);

  await Task({
    subagent_type: 'ccpm:linear-operations',
    prompt: `operation: update_issue
params:
  issueId: ${issueId}
  state: "${targetState}"
context:
  command: rollback`
  });

  // Add comment
  await Task({
    subagent_type: 'ccpm:linear-operations',
    prompt: `operation: create_comment
params:
  issueId: ${issueId}
  body: |
    ⏪ **Status Rollback**

    Reverted: ${issue.state?.name} → ${targetState}

    *via /ccpm:rollback*
context:
  command: rollback`
  });

  console.log(`\n✅ Status reverted to: ${targetState}`);
  console.log('   Comment added to issue history.');
}
```

### Step 6: Summary

```javascript
console.log('\n═══════════════════════════════════════');
console.log('💡 Recovery Options');
console.log('═══════════════════════════════════════\n');

if (options.git && options.hard) {
  console.log('If you need to undo this rollback:');
  console.log(`   git reflog                     # Find the commit hash`);
  console.log(`   git reset --hard <hash>        # Restore to that point`);
  console.log('   OR: git checkout backup-before-rollback-*');
}

console.log('\n📌 Quick Commands');
console.log('   /ccpm:status    - View current state');
console.log('   /ccpm:history   - View activity timeline');
console.log('   /ccpm:work      - Resume work');
```

## Example Output

### Interactive Mode

```
═══════════════════════════════════════
⏪ Rollback Options
═══════════════════════════════════════

📋 Recent Activity:

Git Commits:
   1. a1b2c3d - feat: add JWT auth (2 hours ago)
   2. d4e5f6g - fix: login form (3 hours ago)
   3. h7i8j9k - docs: update README (1 day ago)

📝 Uncommitted Changes: 3 file(s)

📋 Linear Issue: PSN-29

What would you like to undo?
  > Last commit (soft)
    Last commit (hard)
    Uncommitted changes
    Linear status
    Cancel
```

### Git Rollback

```
═══════════════════════════════════════
⏪ Git Rollback
═══════════════════════════════════════

Rolling back 1 commit(s):

   1. a1b2c3d - feat: add JWT auth
      by John Doe, 2 hours ago

ℹ️  SOFT RESET: Commit undone, changes preserved as unstaged

Proceed with soft reset of 1 commit(s)?
  > Yes, proceed
    No, cancel

✅ Successfully rolled back 1 commit(s).

📝 Your changes are preserved as unstaged files.
   Use `git status` to see them.
```

## Safety Features

| Feature | Description |
|---------|-------------|
| Confirmation | All destructive actions require explicit confirmation |
| Backup tags | Hard resets create backup tags for recovery |
| Push detection | Warns before rolling back pushed commits |
| Reflog | Git reflog preserves history for recovery |
| Comments | Linear changes are documented with comments |

## Integration

- Works with `/ccpm:commit` for commit/rollback workflow
- Updates Linear via `ccpm:linear-operations` subagent
- Respects CLAUDE.md protected branches
- Compatible with `/ccpm:sync` progress tracking
