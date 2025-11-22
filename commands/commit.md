---
description: Smart git commit with Linear integration and conventional commits
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[issue-id] [message]"
---

# /ccpm:commit - Smart Git Commit

Auto-detects issue from git branch and creates conventional commits linked to Linear issues.

## 🎯 v1.0 Workflow Rules

**COMMIT Mode Philosophy:**
- **Conventional commits** - Automatic type detection (feat/fix/docs/etc)
- **Linear integration** - Links commits to issues
- **Smart auto-generation** - Creates meaningful messages from context
- **No auto-push** - Only commits locally, user decides when to push
- **Safe confirmation** - Always shows what will be committed

## Usage

```bash
# Auto-detect issue from git branch
/ccpm:commit

# Explicit issue ID
/ccpm:commit PSN-29

# With custom message
/ccpm:commit PSN-29 "Completed JWT validation"

# Message only (auto-detect issue)
/ccpm:commit "Fixed login bug"

# Full conventional format
/ccpm:commit "fix(auth): resolve login button handler"
```

## Implementation

### Step 1: Parse Arguments & Detect Issue

```javascript
const args = process.argv.slice(2);
let issueId = args[0];
let userMessage = args[1];

const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/;

// If first arg doesn't look like issue ID, treat as message
if (args[0] && !ISSUE_ID_PATTERN.test(args[0])) {
  userMessage = args[0];
  issueId = null;
}

// Auto-detect issue ID from git branch
if (!issueId) {
  const branch = await Bash('git rev-parse --abbrev-ref HEAD');
  const match = branch.match(/([A-Z]+-\d+)/);

  if (match) {
    issueId = match[1];
    console.log(`📌 Detected issue from branch: ${issueId}`);
  }
}
```

### Step 2: Check for Uncommitted Changes

```bash
git status --porcelain
```

If no changes:

```
✅ No changes to commit (working tree clean)
```

### Step 3: Analyze Changes

```bash
# Get file changes with stats
git status --porcelain && echo "---" && git diff --stat HEAD
```

Parse output:

```javascript
const changes = {
  modified: [],
  added: [],
  deleted: [],
  hasTests: false,
  hasSource: false,
  hasDocs: false
};

// Parse git status
lines.forEach(line => {
  const [status, file] = line.trim().split(/\s+/);

  if (status === 'M') changes.modified.push(file);
  else if (status === 'A' || status === '??') changes.added.push(file);
  else if (status === 'D') changes.deleted.push(file);

  // Detect file types
  if (file.includes('test') || file.includes('spec')) changes.hasTests = true;
  if (file.includes('src/') || file.includes('lib/')) changes.hasSource = true;
  if (file.match(/\.(md|txt)$/)) changes.hasDocs = true;
});

// Show summary
console.log('\n📊 Changes to commit:\n');
console.log(`  Modified: ${changes.modified.length}`);
console.log(`  Added: ${changes.added.length}`);
console.log(`  Deleted: ${changes.deleted.length}\n`);
```

### Step 4: Fetch Issue Context (if available)

If issue ID detected:

**Use the Task tool:**

Invoke `ccpm:linear-operations`:

```
operation: get_issue
params:
  issueId: "{issue ID}"
context:
  cache: true
  command: "commit"
```

Extract:
- Issue title
- Issue type (bug/feature from labels)
- Current status

```javascript
console.log(`📋 Issue: ${issue.identifier} - ${issue.title}`);
console.log(`📊 Status: ${issue.state.name}\n`);
```

### Step 5: Determine Commit Type

```javascript
function suggestCommitType(changes, issueLabels) {
  // From Linear issue labels
  if (issueLabels.includes('bug') || issueLabels.includes('fix')) return 'fix';
  if (issueLabels.includes('feature')) return 'feat';

  // From file analysis
  if (changes.hasSource && changes.added.length > 0) return 'feat';
  if (changes.hasTests && !changes.hasSource) return 'test';
  if (changes.hasDocs && !changes.hasSource) return 'docs';

  // Default for modifications
  if (changes.modified.length > 0 && changes.hasSource) return 'feat';

  return 'chore';
}

const commitType = suggestCommitType(changes, issue?.labels || []);
```

### Step 6: Generate Commit Message

```javascript
let commitMessage;

if (userMessage) {
  // Check if already in conventional format
  const conventionalMatch = userMessage.match(/^(\w+)(\([\w-]+\))?: (.+)$/);

  if (conventionalMatch) {
    // Use as-is
    commitMessage = userMessage;
  } else {
    // Add conventional format
    const scope = issueId || null;
    commitMessage = `${commitType}${scope ? `(${scope})` : ''}: ${userMessage}`;
  }
} else {
  // Auto-generate from issue title or file changes
  const scope = issueId || null;
  let description;

  if (issue?.title) {
    // Use issue title (lowercase first letter for conventional format)
    description = issue.title.charAt(0).toLowerCase() + issue.title.slice(1);
  } else {
    // Generate from changes
    if (changes.added.length > 0 && changes.hasSource) {
      const mainFile = changes.added[0].split('/').pop().replace(/\.(ts|js|tsx|jsx)$/, '');
      description = `add ${mainFile} module`;
    } else if (changes.modified.length > 0 && changes.hasSource) {
      description = `update implementation`;
    } else if (changes.hasDocs) {
      description = `update documentation`;
    } else {
      description = `update ${changes.modified.length} file(s)`;
    }
  }

  commitMessage = `${commitType}${scope ? `(${scope})` : ''}: ${description}`;
}
```

### Step 7: Display Proposed Commit & Confirm

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬 Proposed Commit Message
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${commitMessage}

${issueId ? `🔗 Linked to: ${issueId}` : ''}

📊 Changes:
  • Modified: ${changes.modified.length}
  • Added: ${changes.added.length}
  • Deleted: ${changes.deleted.length}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use **AskUserQuestion**:

```javascript
{
  questions: [{
    question: "Proceed with this commit?",
    header: "Confirm",
    multiSelect: false,
    options: [
      {
        label: "Yes, commit",
        description: "Create commit with this message"
      },
      {
        label: "Edit message",
        description: "Modify the commit message first"
      },
      {
        label: "Cancel",
        description: "Don't commit, go back"
      }
    ]
  }]
}
```

### Step 8: Create Commit

**If "Yes, commit":**

```bash
# Stage all changes
git add .

# Create commit (use heredoc for proper formatting)
git commit -m "$(cat <<'EOF'
${commitMessage}
EOF
)"
```

Display success:

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Commit Created Successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Commit: ${commitHash} - ${commitMessage}

🎯 Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. ⭐ Sync to Linear       /ccpm:sync
2. 🚀 Push to remote       git push
3. 🔄 Continue work        /ccpm:work
4. ✅ Run verification     /ccpm:verify

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If "Edit message":**

Display prompt:

```markdown
Please provide your commit message (conventional format):

Format: <type>(<scope>): <description>

Examples:
  • feat(auth): add JWT token validation
  • fix(PSN-27): resolve login button handler
  • docs: update API documentation

Your message:
```

Wait for user input, then repeat from Step 7.

**If "Cancel":**

```
⏸️  Commit cancelled. Changes remain staged.
```

## Error Handling

### No Changes to Commit

```
✅ No changes to commit (working tree clean)

Run /ccpm:work to continue working or make changes first.
```

### Git Not Initialized

```
❌ Not a git repository

Initialize git first:
  git init
```

### Issue Not Found

```
⚠️  Could not fetch issue ${issueId} from Linear

Proceeding without issue context...
```

## Examples

### Example 1: Auto-detect everything

```bash
# Branch: feature/PSN-29-add-auth
# Made changes to src/auth/*.ts
/ccpm:commit

# Output:
# 📌 Detected issue from branch: PSN-29
# 📋 Issue: PSN-29 - Add user authentication
#
# 💬 Proposed: feat(PSN-29): add user authentication
#
# [Confirmation]
#
# ✅ Commit created!
```

### Example 2: Custom message with auto-detect

```bash
# Branch: feature/PSN-29-add-auth
/ccpm:commit "Completed JWT validation"

# Output:
# 📌 Detected issue from branch: PSN-29
#
# 💬 Proposed: feat(PSN-29): Completed JWT validation
#
# ✅ Commit created!
```

### Example 3: Explicit issue ID

```bash
/ccpm:commit PSN-29 "Fixed login bug"

# Output:
# 💬 Proposed: fix(PSN-29): Fixed login bug
#
# ✅ Commit created!
```

### Example 4: Already conventional format

```bash
/ccpm:commit "fix(auth): resolve login button handler"

# Output:
# 💬 Proposed: fix(auth): resolve login button handler
#
# ✅ Commit created! (used as-is)
```

### Example 5: No issue ID

```bash
/ccpm:commit "update documentation"

# Output:
# 💬 Proposed: docs: update documentation
#
# ✅ Commit created!
```

## Key Optimizations

1. ✅ **Auto-detection** - Issue ID from branch, commit type from changes
2. ✅ **Linear subagent** - Cached issue lookups (85-95% hit rate)
3. ✅ **Smart defaults** - Meaningful messages from context
4. ✅ **No routing** - Direct implementation
5. ✅ **Safe operation** - Local only, no auto-push
6. ✅ **Conventional commits** - Automatic format following best practices

## Conventional Commits Reference

**Common types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, whitespace
- `refactor`: Code restructuring
- `test`: Adding/updating tests
- `chore`: Maintenance, dependencies

**Format:**
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Examples:**
- `feat(auth): add JWT token validation`
- `fix(PSN-27): resolve race condition in login`
- `docs: update API reference for auth endpoints`
- `chore(deps): upgrade react to v19`

## Integration

- **After work** → `/ccpm:commit` to save changes to git
- **After commit** → `/ccpm:sync` to update Linear
- **Before push** → Review commits with `git log`
- **Finalize** → `/ccpm:done` to create PR

## Notes

- **Local operation** - Only commits to local git, never auto-pushes
- **Conventional format** - Follows industry standard for commit messages
- **Linear integration** - Automatically links commits to issues
- **Smart detection** - Auto-determines type from file changes and issue labels
- **Safe confirmation** - Always shows what will be committed
- **Edit capability** - Can modify message before committing
