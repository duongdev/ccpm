---
description: Smart git commit with Linear integration and conventional commits
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[issue-id] [message]"
---

# /ccpm:commit - Smart Git Commit

Auto-detects issue from git branch and creates conventional commits linked to Linear issues.

## ⛔ CRITICAL: Linear Operations

**ALL Linear operations MUST use the Task tool with `ccpm:linear-operations` subagent.**

```javascript
// ✅ CORRECT - Use Task tool with subagent
Task({ subagent_type: "ccpm:linear-operations", prompt: `operation: get_issue\nparams:\n  issueId: X` })

// ❌ WRONG - Direct MCP call
mcp__agent-mcp-gateway__execute_tool({ server: "linear", ... })
```

## ✅ LINEAR = AUTOMATIC (NO CONFIRMATION)

**Linear is internal tracking. Execute immediately - NEVER ask for approval.**

---

## ⚠️ IMPORTANT: Respect CLAUDE.md Rules (All Scopes)

**Before executing any git commit operations, this command MUST check ALL CLAUDE.md files in the hierarchy:**

1. `~/.claude/CLAUDE.md` - User global rules
2. Parent directories (walking up from git root)
3. Git repository root `CLAUDE.md`
4. Current working directory `CLAUDE.md`
5. `.claude/CLAUDE.md` in any of the above

**Rules from more specific (closer) files take precedence over global ones.**

**Example rules to respect:**
- Custom commit message formats (e.g., `[PROJ-123] message`)
- Required commit prefixes or scopes
- Commit signing requirements (`--gpg-sign`, `--signoff`)
- Branch-specific commit rules
- Pre-commit checks or validations

**Example hierarchy:**
```
~/.claude/CLAUDE.md                    # Global: --signoff required
~/work/CLAUDE.md                       # Org: conventional commits
~/work/my-project/CLAUDE.md            # Project: GPG signing
~/work/my-project/apps/web/CLAUDE.md   # Subproject: custom prefix
```

**Result:** Command merges all rules, with subproject rules winning on conflicts.

## 🎯 v1.0 Workflow Rules

**COMMIT Mode Philosophy:**
- **Conventional commits** - Automatic type detection (feat/fix/docs/etc)
- **Linear integration** - Links commits to issues
- **Smart auto-generation** - Creates meaningful messages from context
- **No auto-push** - Only commits locally, user decides when to push
- **Safe confirmation** - Always shows what will be committed
- **Respect local rules** - Local CLAUDE.md commit rules take precedence

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

### Step 0: Check for CLAUDE.md Commit Rules (All Scopes)

**CRITICAL: Check ALL CLAUDE.md files in the hierarchy!**

Claude Code loads CLAUDE.md files from multiple locations (in order of precedence):
1. `~/.claude/CLAUDE.md` (user global)
2. Parent directories up to filesystem root
3. Git repository root `/CLAUDE.md`
4. Current working directory `./CLAUDE.md`
5. `.claude/CLAUDE.md` in any of above

**The command must respect rules from ALL these files, with more specific (closer) files taking precedence.**

```javascript
// Find all CLAUDE.md files in hierarchy
const cwd = process.cwd();
const gitRoot = await Bash('git rev-parse --show-toplevel 2>/dev/null || echo ""');
const homeDir = process.env.HOME;

// Collect all potential CLAUDE.md locations (order: global → local)
const claudeMdPaths = [];

// 1. User global
claudeMdPaths.push(`${homeDir}/.claude/CLAUDE.md`);

// 2. Walk up from git root (or cwd if no git) to find parent CLAUDE.md files
let searchDir = gitRoot.trim() || cwd;
let prevDir = '';
while (searchDir !== prevDir && searchDir !== '/') {
  claudeMdPaths.push(`${searchDir}/CLAUDE.md`);
  claudeMdPaths.push(`${searchDir}/.claude/CLAUDE.md`);
  prevDir = searchDir;
  searchDir = path.dirname(searchDir);
}

// 3. Current working directory (if different from git root)
if (cwd !== gitRoot.trim()) {
  claudeMdPaths.push(`${cwd}/CLAUDE.md`);
  claudeMdPaths.push(`${cwd}/.claude/CLAUDE.md`);
}

// Read all existing CLAUDE.md files and merge rules
let commitRules = {
  format: 'conventional',
  requireScope: false,
  requireSignoff: false,
  customPrefix: null,
  prependIssueId: true,
  additionalFlags: [],
  sources: []  // Track which files contributed rules
};

for (const claudePath of claudeMdPaths) {
  const content = await Read(claudePath).catch(() => null);
  if (!content) continue;

  // Check for commit-related rules
  const hasCommitRules = content.match(/commit|git/i);
  if (!hasCommitRules) continue;

  commitRules.sources.push(claudePath);

  // Parse rules (later files override earlier ones)
  if (content.includes('--signoff') || content.match(/\b-s\b.*commit/i)) {
    commitRules.requireSignoff = true;
    if (!commitRules.additionalFlags.includes('--signoff')) {
      commitRules.additionalFlags.push('--signoff');
    }
  }

  if (content.includes('--gpg-sign') || content.match(/\b-S\b.*commit/i)) {
    if (!commitRules.additionalFlags.includes('--gpg-sign')) {
      commitRules.additionalFlags.push('--gpg-sign');
    }
  }

  // Custom format (last one wins)
  const formatMatch = content.match(/commit.*format[:\s]+([^\n]+)/i);
  if (formatMatch) {
    commitRules.customFormat = formatMatch[1].trim();
  }

  // Scope requirements
  if (content.match(/must include.*scope|scope.*required/i)) {
    commitRules.requireScope = true;
  }

  // Issue ID requirements
  if (content.match(/must include.*issue|issue.*required/i)) {
    commitRules.prependIssueId = true;
  }

  // Custom commit message patterns (e.g., "[PROJ-123] message" format)
  const prefixMatch = content.match(/commit.*prefix[:\s]+([^\n]+)/i);
  if (prefixMatch) {
    commitRules.customPrefix = prefixMatch[1].trim();
  }
}

// Display what was found
if (commitRules.sources.length > 0) {
  console.log('📋 Found CLAUDE.md commit rules from:');
  commitRules.sources.forEach(src => console.log(`   • ${src}`));
  if (commitRules.additionalFlags.length > 0) {
    console.log(`   Flags: ${commitRules.additionalFlags.join(' ')}`);
  }
  if (commitRules.customFormat) {
    console.log(`   Format: ${commitRules.customFormat}`);
  }
}
```

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

# Build commit command with flags from local CLAUDE.md rules
const commitFlags = commitRules.additionalFlags.join(' ');

# Create commit (use heredoc for proper formatting)
# Include any additional flags from local CLAUDE.md (e.g., --signoff, --gpg-sign)
git commit ${commitFlags} -m "$(cat <<'EOF'
${commitMessage}
EOF
)"

# Examples:
# No extra flags:     git commit -m "feat(PSN-29): add auth"
# With signoff:       git commit --signoff -m "feat(PSN-29): add auth"
# With GPG:           git commit --gpg-sign -m "feat(PSN-29): add auth"
# Both:               git commit --signoff --gpg-sign -m "feat(PSN-29): add auth"
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
