---
description: Smart finalize command - create PR, sync status, complete task (optimized)
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[issue-id]"
---

# /ccpm:done - Finalize Task

**Token Budget:** ~2,100 tokens (vs ~6,000 baseline) | **65% reduction**

Finalize a completed task: creates GitHub PR, updates Linear status, and optionally syncs with external PM systems.

## Safety Rules

**READ FIRST**: `commands/SAFETY_RULES.md`

- ✅ **Linear** operations are automatic (internal tracking)
- ✅ **GitHub** PR creation is automatic (code hosting)
- ⛔ **Jira/Confluence/Slack** writes require user confirmation

## Usage

```bash
# Auto-detect issue from git branch
/ccpm:done

# Explicit issue ID
/ccpm:done PSN-29

# Examples
/ccpm:done PROJ-123     # Finalize PROJ-123
/ccpm:done              # Auto-detect from branch "feature/PSN-29-add-auth"
```

## Implementation

### Step 1: Parse Arguments & Detect Context

```javascript
// Parse issue ID from arguments or git branch
let issueId = args[0];

if (!issueId) {
  // Attempt to extract from git branch name
  const branch = await Bash('git rev-parse --abbrev-ref HEAD');
  const match = branch.match(/([A-Z]+-\d+)/);

  if (!match) {
    return error('Could not detect issue ID from git branch.\n\nUsage: /ccpm:done [ISSUE-ID]\nExample: /ccpm:done PSN-29');
  }

  issueId = match[1];
  console.log(`📌 Detected issue from branch: ${issueId}`);
}

// Validate format
if (!/^[A-Z]+-\d+$/.test(issueId)) {
  return error(`Invalid issue ID format: ${issueId}. Expected: PROJ-123`);
}
```

### Step 2: Pre-Flight Safety Checks

```javascript
// 1. Check if on main/master branch
const currentBranch = await Bash('git rev-parse --abbrev-ref HEAD');

if (currentBranch === 'main' || currentBranch === 'master') {
  console.log('❌ Error: You are on the main/master branch\n');
  console.log('Please checkout a feature branch first:');
  console.log(`  git checkout -b your-name/${issueId}-feature-name\n`);
  return;
}

// 2. Check for uncommitted changes
const hasUncommitted = (await Bash('git status --porcelain')).trim().length > 0;

if (hasUncommitted) {
  const status = await Bash('git status --short');
  console.log('⚠️  You have uncommitted changes\n');
  console.log(status);
  console.log('\nCommit your changes first:');
  console.log('  /ccpm:commit\n');
  console.log('Then run /ccpm:done again');
  return;
}

// 3. Check if branch is pushed to remote
try {
  await Bash('git rev-parse @{u}', { stdio: 'ignore' });
} catch {
  console.log('⚠️  Branch not pushed to remote\n');
  console.log('Push your branch first:');
  console.log(`  git push -u origin ${currentBranch}\n`);
  console.log('Then run /ccpm:done again');
  return;
}

console.log('✅ All pre-flight checks passed!\n');
```

### Step 3: Fetch Issue & Verify Completion

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
    command: "done"
  ```

**Error handling:**
```javascript
if (subagentResponse.error) {
  console.log(`❌ Error: ${subagentResponse.error.message}\n`);
  subagentResponse.error.suggestions.forEach(s => console.log(`  - ${s}`));
  return;
}

const issue = subagentResponse.issue;
```

**Parse checklist and verify completion:**
```javascript
const description = issue.description || '';

// Find checklist section (between markers or under header)
const checklistMatch = description.match(
  /<!-- ccpm-checklist-start -->([\s\S]*?)<!-- ccpm-checklist-end -->/
) || description.match(/## ✅ Implementation Checklist([\s\S]*?)(?=\n## |$)/);

if (checklistMatch) {
  const checklistContent = checklistMatch[1];
  const items = checklistContent.match(/- \[([ x])\] .+/g) || [];
  const total = items.length;
  const completed = items.filter(item => item.includes('[x]')).length;
  const progress = total > 0 ? Math.round((completed / total) * 100) : 100;

  if (progress < 100) {
    const incomplete = items.filter(item => item.includes('[ ]'));

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('⛔ Cannot Finalize: Checklist Incomplete');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.log(`Progress: ${progress}% (${completed}/${total} completed)\n`);
    console.log('❌ Remaining Items:');
    incomplete.forEach(item => console.log(`  ${item}`));
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🔧 Actions Required');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.log('1. Complete remaining checklist items');
    console.log(`2. Update checklist: /ccpm:utils:update-checklist ${issueId}`);
    console.log(`3. Then run: /ccpm:done ${issueId}\n`);
    return;
  }

  console.log(`✅ Checklist complete: ${progress}% (${completed}/${total} items)\n`);
}

// Check for blocked label
const isBlocked = (issue.labels || []).some(l =>
  l.name.toLowerCase() === 'blocked'
);

if (isBlocked) {
  console.log('⚠️  Task has "blocked" label\n');
  console.log('Resolve blockers before finalizing');
  return;
}
```

### Step 4: Create GitHub Pull Request

```javascript
// Generate PR title and description
const prTitle = issue.title;
const prBody = `## Summary

Closes: ${issue.identifier}

${issue.description || ''}

## Checklist

${checklistContent || '- [x] Implementation complete'}

---

Linear: ${issue.url}
`;

console.log('📝 Creating GitHub Pull Request...\n');

// Create PR using gh CLI (delegates to smart agent selector)
Task: `
Create a GitHub pull request with the following details:

Title: ${prTitle}
Body:
${prBody}

Use: gh pr create --title "${prTitle}" --body-file <(echo "${prBody}")

After creating the PR:
1. Extract the PR URL from output
2. Return the PR URL
`

console.log('✅ Pull Request created\n');
```

### Step 5: Prompt for External System Updates

Use AskUserQuestion for Jira/Slack confirmation:

```javascript
const answers = await AskUserQuestion({
  questions: [
    {
      question: "Do you want to update Jira status to Done?",
      header: "Sync Jira",
      multiSelect: false,
      options: [
        {label: "Yes, Update Jira", description: "Mark Jira ticket as Done"},
        {label: "No, Skip", description: "I'll update manually"}
      ]
    },
    {
      question: "Do you want to notify team in Slack?",
      header: "Notify Team",
      multiSelect: false,
      options: [
        {label: "Yes, Send Notification", description: "Post completion message"},
        {label: "No, Skip", description: "No notification needed"}
      ]
    }
  ]
});

const updateJira = answers['Sync Jira'] === 'Yes, Update Jira';
const notifySlack = answers['Notify Team'] === 'Yes, Send Notification';
```

**If Jira update requested:**
```javascript
if (updateJira) {
  console.log('\n🚨 CONFIRMATION REQUIRED\n');
  console.log(`I will update Jira ticket to status "Done" with comment:\n`);
  console.log('---');
  console.log(`Completed in Linear: ${issueId}`);
  console.log(`PR: ${prUrl}`);
  console.log('---\n');
  console.log('Proceed? (Type "yes" to confirm)');

  // Wait for confirmation (handled by external-system-safety skill)
  // Then delegate to smart agent selector for Jira update
  Task: `Update Jira ticket to Done status and add completion comment with PR link`;
}
```

**If Slack notification requested:**
```javascript
if (notifySlack) {
  console.log('\n🚨 CONFIRMATION REQUIRED\n');
  console.log('I will post to Slack:\n');
  console.log('---');
  console.log(`✅ ${issue.title} is complete!`);
  console.log(`Linear: ${issue.url}`);
  console.log(`PR: ${prUrl}`);
  console.log('---\n');
  console.log('Proceed? (Type "yes" to confirm)');

  // Wait for confirmation (handled by external-system-safety skill)
  // Then delegate to smart agent selector for Slack notification
  Task: `Post completion message to Slack with PR and Linear links`;
}
```

### Step 6: Update Linear Status (Automatic)

**Use the Task tool to update Linear issue to Done:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: update_issue
  params:
    issueId: "{issue ID from step 1}"
    state: "Done"
    labels: ["done"]
  context:
    cache: true
    command: "done"
    purpose: "Marking task as complete"
  ```

**Use the Task tool to add completion comment:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: create_comment
  params:
    issueId: "{issue ID from step 1}"
    body: |
      ## 🎉 Task Completed and Finalized

      **Completion Time:** {current timestamp}

      ### Actions Taken:
      ✅ Pull Request created: {PR URL from step 4}
      {if Jira updated: ✅ Jira status updated to Done, else: ⏭️ Jira update skipped}
      {if Slack notified: ✅ Team notified in Slack, else: ⏭️ Slack notification skipped}

      ### Final Status:
      - Linear: Done ✅
      - Workflow labels cleaned up
      - Task marked as complete

      ---

      **This task is now closed.** 🎊
  context:
    command: "done"
  ```

**Display:**
```javascript
console.log('✅ Linear issue updated to Done\n');
```

### Step 7: Show Final Summary

```javascript
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log(`🎉 Task Finalized: ${issueId}`);
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log('✅ Linear: Updated to Done');
console.log(`✅ Pull Request: ${prUrl}`);
console.log(`${updateJira ? '✅' : '⏭️ '} Jira: ${updateJira ? 'Updated' : 'Skipped'}`);
console.log(`${notifySlack ? '✅' : '⏭️ '} Slack: ${notifySlack ? 'Notified' : 'Skipped'}`);
console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('💡 What\'s Next?');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log('Available Actions:');
console.log('  1. /ccpm:plan "title" - Create new task');
console.log('  2. /ccpm:utils:report <project> - View project progress');
console.log('  3. /ccpm:utils:search <project> "query" - Find task to work on');
console.log('\n🎊 Great work! Task complete.');
```

## Error Handling

### Invalid Issue ID Format
```
❌ Invalid issue ID format: proj123
Expected format: PROJ-123 (uppercase letters, hyphen, numbers)
```

### Git Branch Detection Failed
```
❌ Could not detect issue ID from git branch

Current branch: main

Usage: /ccpm:done [ISSUE-ID]
Example: /ccpm:done PSN-29
```

### Uncommitted Changes
```
⚠️  You have uncommitted changes

M  src/api/auth.ts
?? src/tests/new-test.ts

Commit your changes first:
  /ccpm:commit

Then run /ccpm:done again
```

### On Main Branch
```
❌ Error: You are on the main/master branch

Please checkout a feature branch first:
  git checkout -b your-name/PSN-29-feature-name
```

### Branch Not Pushed
```
⚠️  Branch not pushed to remote

Push your branch first:
  git push -u origin feature/PSN-29-add-auth

Then run /ccpm:done again
```

### Checklist Incomplete
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔ Cannot Finalize: Checklist Incomplete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Progress: 80% (4/5 completed)

❌ Remaining Items:
  - [ ] Write tests for password reset
```

### Task Blocked
```
⚠️  Task has "blocked" label

Resolve blockers before finalizing
```

## Examples

### Example 1: Done with Auto-Detection

```bash
# Current branch: feature/PSN-29-add-auth
/ccpm:done

# Output:
# 📌 Detected issue from branch: PSN-29
#
# ✅ All pre-flight checks passed!
#
# ✅ Checklist complete: 100% (5/5 items)
#
# 📝 Creating GitHub Pull Request...
# ✅ Pull Request created
#
# [AskUserQuestion for Jira/Slack]
#
# ✅ Linear issue updated to Done
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎉 Task Finalized: PSN-29
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# ✅ Linear: Updated to Done
# ✅ Pull Request: https://github.com/...
# ⏭️  Jira: Skipped
# ⏭️  Slack: Skipped
```

### Example 2: Done with Explicit Issue ID

```bash
/ccpm:done PSN-29

# Same flow as Example 1
```

### Example 3: Done with Uncommitted Changes (Error)

```bash
/ccpm:done PSN-29

# Output:
# ⚠️  You have uncommitted changes
#
# M  src/api/auth.ts
# ?? src/tests/new-test.ts
#
# Commit your changes first:
#   /ccpm:commit
#
# Then run /ccpm:done again
```

## Token Budget Breakdown

| Section | Tokens | Notes |
|---------|--------|-------|
| Frontmatter & description | 80 | Minimal metadata |
| Step 1: Argument parsing | 150 | Git detection + validation |
| Step 2: Pre-flight checks | 300 | Branch/commit/push checks |
| Step 3: Fetch & verify | 350 | Linear subagent + checklist parsing |
| Step 4: Create PR | 250 | Smart agent delegation |
| Step 5: External confirmations | 200 | AskUserQuestion + safety |
| Step 6: Update Linear | 250 | Batch update + comment |
| Step 7: Final summary | 150 | Display results |
| Error handling | 220 | 6 error scenarios (concise) |
| Examples | 150 | 3 essential examples |
| **Total** | **~2,100** | **vs ~6,000 baseline (65% reduction)** |

## Key Optimizations

1. ✅ **No routing overhead** - Direct implementation (no call to complete:finalize)
2. ✅ **Linear subagent** - All Linear ops with session-level caching
3. ✅ **Smart agent delegation** - PR creation and external syncs use smart-agent-selector
4. ✅ **Pre-flight checks** - Prevent common mistakes before processing
5. ✅ **Batch operations** - Single update for state + labels
6. ✅ **Safety confirmation** - Built into workflow for Jira/Slack
7. ✅ **Concise examples** - Only 3 essential examples

## Integration with Other Commands

- **After /ccpm:verify** → Use /ccpm:done to finalize
- **Auto-detection** → Works with /ccpm:work branch-based workflow
- **Git integration** → Follows /ccpm:commit for clean commits
- **Safety rules** → Enforces confirmation for external systems

## Notes

- **Git branch detection**: Extracts issue ID from branch names like `feature/PSN-29-add-auth`
- **Pre-flight checks**: Validates all prerequisites before finalization
- **Smart agent selection**: Automatically chooses optimal agents for PR and external syncs
- **Safety first**: Jira/Slack updates require explicit confirmation
- **Linear automatic**: Internal tracking updates happen automatically
- **Caching**: Linear subagent provides 85-95% cache hit rate for faster operations
