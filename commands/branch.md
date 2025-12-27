---
description: Smart git branch management with Linear integration
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[issue-id | branch-name] [--create] [--switch] [--delete] [--list]"
---

# /ccpm:branch - Smart Branch Management

Manage git branches with automatic naming conventions and Linear issue linking.

## Usage

```bash
# Create branch for issue (auto-generates name)
/ccpm:branch PSN-29

# Create with custom suffix
/ccpm:branch PSN-29 --suffix=jwt-auth

# Switch to issue branch (finds existing)
/ccpm:branch PSN-29 --switch

# List branches with Linear info
/ccpm:branch --list

# Delete merged branches
/ccpm:branch --cleanup

# Show branch info
/ccpm:branch
```

## Helper Functions

This command uses:
- `helpers/branching-strategy.md` - For type-based branch prefix mapping from multi-level CLAUDE.md

## Implementation

### Step 0: Load Branching Strategy from CLAUDE.md Hierarchy

**Uses `helpers/branching-strategy.md` for type-based branch prefixes!**

```javascript
// Load branching strategy from multi-level CLAUDE.md files
// See: helpers/branching-strategy.md for full implementation

const strategy = await loadBranchingStrategy();
// Returns:
// {
//   prefixes: { feature: 'feature/', fix: 'fix/', bug: 'bugfix/', ... },
//   defaultPrefix: 'feature/',
//   protectedBranches: ['main', 'master', 'develop', ...],
//   format: '{prefix}{issue-id}-{title-slug}',
//   sources: ['/path/to/CLAUDE.md', ...]
// }

// For backward compatibility
let workflowRules = {
  protectedBranches: strategy.protectedBranches,
  branchPrefix: strategy.defaultPrefix,
  branchingStrategy: strategy,
  branchFormat: strategy.format
};

// Display loaded configuration
if (strategy.sources.length > 0) {
  console.log('📋 Branching strategy loaded from:');
  strategy.sources.forEach(src => console.log(`   • ${src}`));
}
console.log(`   Default prefix: ${strategy.defaultPrefix}`);
console.log(`🔒 Protected: ${strategy.protectedBranches.join(', ')}`);
```

### Step 1: Parse Arguments

```javascript
let issueId = null;
let options = {
  create: false,
  switch: false,
  delete: false,
  list: false,
  cleanup: false,
  suffix: null
};

for (const arg of args) {
  if (arg.match(/^[A-Z]+-\d+$/)) {
    issueId = arg;
    options.create = true; // Default action for issue ID
  } else if (arg === '--create') {
    options.create = true;
  } else if (arg === '--switch') {
    options.switch = true;
    options.create = false;
  } else if (arg === '--delete') {
    options.delete = true;
  } else if (arg === '--list') {
    options.list = true;
  } else if (arg === '--cleanup') {
    options.cleanup = true;
  } else if (arg.startsWith('--suffix=')) {
    options.suffix = arg.replace('--suffix=', '');
  }
}
```

### Step 2: List Branches

```javascript
if (options.list) {
  console.log('═══════════════════════════════════════');
  console.log('🌿 Git Branches');
  console.log('═══════════════════════════════════════\n');

  // Get all local branches with details
  const branches = await Bash(`git for-each-ref --sort=-committerdate --format='%(refname:short)|%(committerdate:relative)|%(upstream:short)|%(upstream:track)' refs/heads/`);

  const branchList = branches.trim().split('\n').map(line => {
    const [name, date, upstream, track] = line.split('|');

    // Extract issue ID if present
    const issueMatch = name.match(/([A-Z]+-\d+)/);
    const linkedIssue = issueMatch ? issueMatch[1] : null;

    return { name, date, upstream, track, linkedIssue };
  });

  // Current branch
  const currentBranch = await Bash('git rev-parse --abbrev-ref HEAD');

  // Fetch Linear info for linked issues
  const linkedIssues = branchList.filter(b => b.linkedIssue).map(b => b.linkedIssue);
  let issueInfo = {};

  if (linkedIssues.length > 0) {
    // Batch fetch issue info (up to 10)
    for (const id of linkedIssues.slice(0, 10)) {
      const result = await Task({
        subagent_type: 'ccpm:linear-operations',
        prompt: `operation: get_issue
params:
  issueId: ${id}
context:
  cache: true
  command: branch`
      });

      if (result.issue) {
        issueInfo[id] = {
          title: result.issue.title,
          status: result.issue.state?.name || 'Unknown'
        };
      }
    }
  }

  // Display
  branchList.forEach(branch => {
    const isCurrent = branch.name.trim() === currentBranch.trim();
    const marker = isCurrent ? '→ ' : '  ';
    const isProtected = workflowRules.protectedBranches.includes(branch.name);
    const protectedMark = isProtected ? '🔒' : '  ';

    console.log(`${marker}${protectedMark} ${branch.name}`);
    console.log(`      Updated: ${branch.date}`);

    if (branch.linkedIssue && issueInfo[branch.linkedIssue]) {
      const info = issueInfo[branch.linkedIssue];
      const statusIcon = getStatusIcon(info.status);
      console.log(`      ${statusIcon} ${branch.linkedIssue}: ${info.title}`);
    }

    if (branch.track) {
      console.log(`      ${branch.track}`);
    }
    console.log('');
  });

  return;
}
```

### Step 3: Cleanup Merged Branches

```javascript
if (options.cleanup) {
  console.log('═══════════════════════════════════════');
  console.log('🧹 Branch Cleanup');
  console.log('═══════════════════════════════════════\n');

  // Find merged branches (excluding protected)
  const protectedPattern = workflowRules.protectedBranches.join('\\|');
  const merged = await Bash(`git branch --merged main | grep -v "^\\*" | grep -vE "(${protectedPattern})" | tr -d ' '`);

  if (!merged.trim()) {
    console.log('✅ No merged branches to clean up.\n');
    return;
  }

  const branchesToDelete = merged.trim().split('\n').filter(b => b.length > 0);

  console.log(`Found ${branchesToDelete.length} merged branch(es):\n`);
  branchesToDelete.forEach(b => console.log(`   • ${b}`));
  console.log('');

  // Confirm deletion
  const answer = await AskUserQuestion({
    questions: [{
      question: `Delete ${branchesToDelete.length} merged branches?`,
      header: "Cleanup",
      multiSelect: false,
      options: [
        { label: "Yes, delete all", description: "Remove all merged branches" },
        { label: "No, cancel", description: "Keep all branches" }
      ]
    }]
  });

  if (answer === "Yes, delete all") {
    for (const branch of branchesToDelete) {
      await Bash(`git branch -d ${branch}`);
      console.log(`   ✅ Deleted: ${branch}`);
    }
    console.log(`\n✅ Cleaned up ${branchesToDelete.length} branch(es).`);
  } else {
    console.log('\n⏸️  Cleanup cancelled.');
  }

  return;
}
```

### Step 4: Create or Switch Branch

```javascript
if (issueId) {
  // Fetch issue info for branch naming
  const result = await Task({
    subagent_type: 'ccpm:linear-operations',
    prompt: `operation: get_issue
params:
  issueId: ${issueId}
context:
  cache: true
  command: branch`
  });

  if (result.error) {
    console.log(`❌ Issue not found: ${issueId}`);
    return;
  }

  const issue = result.issue;

  // Generate branch name using type-based prefix selection
  // See: helpers/branching-strategy.md → determineBranchPrefix() & generateBranchName()

  const strategy = workflowRules.branchingStrategy;

  // Determine prefix based on issue labels/type
  const branchPrefix = determineBranchPrefix(issue, strategy);

  // Show reasoning for prefix selection
  if (issue.labels && issue.labels.length > 0) {
    const matchingLabel = issue.labels.find(l =>
      strategy.prefixes[(l.name || l).toLowerCase()]
    );
    if (matchingLabel) {
      console.log(`🏷️  Using prefix '${branchPrefix}' (based on label: ${matchingLabel.name || matchingLabel})`);
    }
  } else if (issue.title.match(/^(feat|fix|docs|chore|refactor)/i)) {
    const match = issue.title.match(/^(feat|fix|docs|chore|refactor)/i);
    console.log(`🏷️  Using prefix '${branchPrefix}' (based on title: ${match[1]})`);
  }

  // Generate full branch name
  let branchName = options.suffix
    ? generateBranchName(issue, strategy, options.suffix)
    : generateBranchName(issue, strategy);

  // Check if branch exists
  const existingBranches = await Bash(`git branch --list "*${issueId}*" "*${issueId.toLowerCase()}*"`);
  const existingBranch = existingBranches.trim().split('\n').filter(b => b.trim())[0]?.trim().replace('* ', '');

  if (options.switch && existingBranch) {
    // Switch to existing branch
    console.log(`🔄 Switching to existing branch: ${existingBranch}`);
    await Bash(`git checkout ${existingBranch}`);
    console.log(`\n✅ Now on branch: ${existingBranch}`);
    console.log(`📋 Issue: ${issue.identifier} - ${issue.title}`);
    console.log(`📊 Status: ${issue.state?.name || 'Unknown'}`);
    return;
  }

  if (existingBranch && !options.create) {
    // Branch exists, ask what to do
    const answer = await AskUserQuestion({
      questions: [{
        question: `Branch exists: ${existingBranch}. What would you like to do?`,
        header: "Branch Exists",
        multiSelect: false,
        options: [
          { label: "Switch to it", description: `Checkout ${existingBranch}` },
          { label: "Create new", description: `Create ${branchName}` },
          { label: "Cancel", description: "Do nothing" }
        ]
      }]
    });

    if (answer === "Switch to it") {
      await Bash(`git checkout ${existingBranch}`);
      console.log(`\n✅ Now on branch: ${existingBranch}`);
      return;
    } else if (answer === "Cancel") {
      console.log('\n⏸️  Cancelled.');
      return;
    }
    // Continue to create new if "Create new" selected
  }

  // Create new branch
  console.log('═══════════════════════════════════════');
  console.log('🌿 Creating Branch');
  console.log('═══════════════════════════════════════\n');

  console.log(`📋 Issue: ${issue.identifier} - ${issue.title}`);
  console.log(`📊 Status: ${issue.state?.name || 'Unknown'}`);
  console.log(`\n🌿 Branch: ${branchName}`);

  // Check current branch for safety
  const currentBranch = await Bash('git rev-parse --abbrev-ref HEAD');
  const baseBranch = workflowRules.protectedBranches.includes(currentBranch.trim())
    ? currentBranch.trim()
    : 'main';

  console.log(`📍 Base: ${baseBranch}`);

  // Ensure we're up to date
  console.log('\n🔄 Fetching latest...');
  await Bash('git fetch origin');

  // Create and switch
  await Bash(`git checkout -b ${branchName} origin/${baseBranch}`);

  console.log(`\n✅ Created and switched to: ${branchName}`);
  console.log('\n💡 Next Steps:');
  console.log(`   /ccpm:work ${issueId}  - Start implementation`);
  console.log(`   /ccpm:status          - View status`);
}
```

### Step 5: Show Current Branch Info (Default)

```javascript
if (!issueId && !options.list && !options.cleanup) {
  console.log('═══════════════════════════════════════');
  console.log('🌿 Current Branch');
  console.log('═══════════════════════════════════════\n');

  const currentBranch = await Bash('git rev-parse --abbrev-ref HEAD');
  const isProtected = workflowRules.protectedBranches.includes(currentBranch.trim());

  console.log(`Branch: ${currentBranch.trim()}`);
  if (isProtected) {
    console.log('🔒 This is a protected branch');
  }

  // Check for linked issue
  const issueMatch = currentBranch.match(/([A-Z]+-\d+)/);
  if (issueMatch) {
    const linkedId = issueMatch[1];

    const result = await Task({
      subagent_type: 'ccpm:linear-operations',
      prompt: `operation: get_issue
params:
  issueId: ${linkedId}
context:
  cache: true
  command: branch`
    });

    if (result.issue) {
      const statusIcon = getStatusIcon(result.issue.state?.name);
      console.log(`\n📋 Linked Issue: ${result.issue.identifier}`);
      console.log(`   Title: ${result.issue.title}`);
      console.log(`   ${statusIcon} Status: ${result.issue.state?.name || 'Unknown'}`);
    }
  }

  // Show tracking info
  const tracking = await Bash('git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "not tracking"');
  console.log(`\n📡 Tracking: ${tracking.trim()}`);

  // Show ahead/behind
  const ahead = await Bash('git rev-list --count @{u}..HEAD 2>/dev/null || echo "0"');
  const behind = await Bash('git rev-list --count HEAD..@{u} 2>/dev/null || echo "0"');

  if (ahead.trim() !== '0' || behind.trim() !== '0') {
    console.log(`   ↑ ${ahead.trim()} ahead, ↓ ${behind.trim()} behind`);
  } else {
    console.log('   ✅ Up to date');
  }

  // Quick commands
  console.log('\n💡 Quick Commands');
  console.log('   /ccpm:branch PSN-XX   - Create branch for issue');
  console.log('   /ccpm:branch --list   - List all branches');
  console.log('   /ccpm:branch --cleanup - Delete merged branches');
}
```

### Helper Functions

```javascript
function getStatusIcon(status) {
  const icons = {
    'Backlog': '📋',
    'Todo': '📝',
    'In Progress': '🔄',
    'In Review': '👁️',
    'Done': '✅',
    'Cancelled': '❌'
  };
  return icons[status] || '⏳';
}
```

## Example Output

### Create Branch

```
═══════════════════════════════════════
🌿 Creating Branch
═══════════════════════════════════════

📋 Issue: PSN-29 - Add user authentication
📊 Status: Todo

🌿 Branch: feature/psn-29-add-user-authentication
📍 Base: main

🔄 Fetching latest...

✅ Created and switched to: feature/psn-29-add-user-authentication

💡 Next Steps:
   /ccpm:work PSN-29  - Start implementation
   /ccpm:status       - View status
```

### List Branches

```
═══════════════════════════════════════
🌿 Git Branches
═══════════════════════════════════════

→  🔒 main
      Updated: 2 hours ago
      [up to date]

   feature/psn-29-add-auth
      Updated: 1 hour ago
      🔄 PSN-29: Add user authentication

   feature/psn-45-oauth
      Updated: 3 days ago
      ✅ PSN-45: OAuth integration
      [ahead 2]
```

## Integration

- Respects CLAUDE.md protected branches and naming conventions
- Links branches to Linear issues automatically
- Works with `/ccpm:work` for seamless workflow
- Uses `ccpm:linear-operations` with caching
