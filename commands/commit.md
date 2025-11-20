---
description: Smart git commit with Linear integration and conventional commits
allowed-tools: [Bash, LinearMCP]
argument-hint: "[issue-id] [message]"
---

# Smart Commit Command

You are executing the **smart git commit command** that integrates with Linear and follows conventional commits format.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

This command performs **git operations** which are local and safe. No external PM system writes.

## Conventional Commits Format

This command follows the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

## Implementation

### Step 1: Determine Issue ID

```javascript
const args = process.argv.slice(2)
let issueId = args[0]
let userMessage = args[1]

const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/

// If first arg doesn't look like issue ID, it might be the message
if (args[0] && !ISSUE_ID_PATTERN.test(args[0])) {
  userMessage = args[0]
  issueId = null
}

// Try to detect issue ID from git branch
if (!issueId) {
  try {
    const branch = execSync('git rev-parse --abbrev-ref HEAD', {
      encoding: 'utf-8'
    }).trim()

    const branchMatch = branch.match(/([A-Z]+-\d+)/)
    if (branchMatch) {
      issueId = branchMatch[1]
      console.log(`🔍 Detected issue from branch: ${issueId}`)
    }
  } catch (error) {
    // Not in a git repo or branch detection failed
    console.log("ℹ️  Could not detect issue from branch")
  }
}
```

### Step 2: Check for Uncommitted Changes

```bash
# Get status
git status --porcelain

# Check if there are changes to commit
if [ -z "$(git status --porcelain)" ]; then
  echo "✅ No changes to commit (working tree clean)"
  exit 0
fi
```

### Step 3: Show Changes Summary

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Smart Commit Command
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${issueId ? `📋 Issue: ${issueId}` : ''}

📊 Changes to commit:
────────────────────

${changedFiles.map((file, i) => `  ${i+1}. ${file.status} ${file.path}`).join('\n')}

📈 Total: ${changedFiles.length} file(s) changed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Fetch Issue Context (if Issue ID available)

If issue ID is available, get context from Linear:

```javascript
let issueTitle = null
let issueType = null

if (issueId) {
  try {
    const issue = await linear_get_issue(issueId)
    issueTitle = issue.title
    issueType = detectIssueType(issue)

    console.log(`📋 Issue: ${issueId} - ${issueTitle}`)
    console.log("")
  } catch (error) {
    console.log(`⚠️  Could not fetch issue ${issueId} from Linear`)
    console.log("   Proceeding without issue context")
  }
}
```

### Step 5: Analyze Changes and Determine Commit Type

```javascript
function analyzeChanges(changedFiles) {
  const analysis = {
    hasTests: false,
    hasSource: false,
    hasDocs: false,
    hasConfig: false,
    newFiles: 0,
    modifiedFiles: 0
  }

  changedFiles.forEach(file => {
    if (file.status === 'A' || file.status === '??') {
      analysis.newFiles++
    } else if (file.status === 'M') {
      analysis.modifiedFiles++
    }

    if (file.path.includes('test') || file.path.includes('spec')) {
      analysis.hasTests = true
    } else if (file.path.includes('src/') || file.path.includes('lib/')) {
      analysis.hasSource = true
    } else if (file.path.match(/\.(md|txt)$/)) {
      analysis.hasDocs = true
    } else if (file.path.match(/\.(config|json|yaml|yml)$/)) {
      analysis.hasConfig = true
    }
  })

  return analysis
}

function suggestCommitType(analysis, issueType) {
  // Priority order for determining type
  if (issueType === 'bug') return 'fix'
  if (issueType === 'feature') return 'feat'

  // Infer from changes
  if (analysis.hasSource && analysis.newFiles > 0) return 'feat'
  if (analysis.hasSource && analysis.modifiedFiles > 0) {
    // Could be feat, fix, or refactor - let user choose
    return 'feat' // default to feat
  }
  if (analysis.hasTests && !analysis.hasSource) return 'test'
  if (analysis.hasDocs && !analysis.hasSource) return 'docs'
  if (analysis.hasConfig) return 'chore'

  return 'feat' // default
}
```

### Step 6: Generate or Collect Commit Message

```javascript
let commitType, commitScope, commitDescription

if (userMessage) {
  // User provided message, parse or use as-is
  const conventionalMatch = userMessage.match(/^(\w+)(\([\w-]+\))?: (.+)$/)

  if (conventionalMatch) {
    // Already in conventional format
    commitType = conventionalMatch[1]
    commitScope = conventionalMatch[2]?.slice(1, -1) // Remove parens
    commitDescription = conventionalMatch[3]
  } else {
    // Plain message, add conventional format
    commitType = suggestCommitType(analysis, issueType)
    commitScope = issueId ? issueId : null
    commitDescription = userMessage
  }
} else {
  // Auto-generate from context
  commitType = suggestCommitType(analysis, issueType)
  commitScope = issueId ? issueId : null

  // Generate description
  if (issueTitle) {
    commitDescription = issueTitle
  } else {
    // Generate from file changes
    commitDescription = generateDescriptionFromChanges(analysis, changedFiles)
  }
}
```

### Step 7: Display Proposed Commit Message

```markdown
💬 Proposed Commit Message:
───────────────────────────

${commitType}${commitScope ? `(${commitScope})` : ''}: ${commitDescription}

${issueId ? `
Related to: ${issueId}
${issueTitle ? `Issue: ${issueTitle}` : ''}
` : ''}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 8: Confirm and Commit

Use **AskUserQuestion** to confirm:

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
        description: "Let me modify the commit message"
      },
      {
        label: "Cancel",
        description: "Don't commit, go back"
      }
    ]
  }]
}
```

**If "Yes, commit"**:

```bash
# Stage all changes
git add .

# Create commit with conventional format
git commit -m "${commitType}${commitScope ? `(${commitScope})` : ''}: ${commitDescription}" \
  ${issueId ? `-m "Related to: ${issueId}"` : ''} \
  ${issueTitle ? `-m "${issueTitle}"` : ''}

echo "✅ Commit created successfully!"
echo ""
echo "Commit: $(git log -1 --oneline)"
echo ""
echo "Next steps:"
echo "  /ccpm:sync        # Sync progress to Linear"
echo "  /ccpm:work        # Continue working"
echo "  git push          # Push to remote"
```

**If "Edit message"**:

```markdown
Please provide your commit message (conventional format preferred):

Format: <type>(<scope>): <description>
Examples:
  - feat(auth): add JWT token validation
  - fix(PSN-27): resolve login button click handler
  - docs: update API documentation

Your message:
> [User input]
```

Then repeat confirmation.

## Helper Functions

### Detect Issue Type

```javascript
function detectIssueType(issue) {
  const title = issue.title.toLowerCase()
  const labels = issue.labels || []

  // Check labels first
  if (labels.includes('bug') || labels.includes('fix')) return 'bug'
  if (labels.includes('feature') || labels.includes('enhancement')) return 'feature'

  // Check title keywords
  if (title.includes('fix') || title.includes('bug')) return 'bug'
  if (title.includes('add') || title.includes('implement')) return 'feature'

  return 'feature' // default
}
```

### Generate Description from Changes

```javascript
function generateDescriptionFromChanges(analysis, changedFiles) {
  if (analysis.newFiles > 0 && analysis.hasSource) {
    const mainFile = changedFiles.find(f => f.status === 'A' && f.path.includes('src/'))
    if (mainFile) {
      const fileName = mainFile.path.split('/').pop().replace(/\.(ts|js|tsx|jsx)$/, '')
      return `add ${fileName} module`
    }
    return `add new feature components`
  }

  if (analysis.modifiedFiles > 0 && analysis.hasSource) {
    return `update implementation`
  }

  if (analysis.hasTests) {
    return `add tests`
  }

  if (analysis.hasDocs) {
    return `update documentation`
  }

  return `update files`
}
```

## Examples

### Example 1: Commit with Auto-Detection

```bash
git checkout -b duongdev/PSN-27-add-auth
# ... make changes ...
/ccpm:commit
```

**Detection**: PSN-27 from branch, fetches issue title from Linear
**Generated**: `feat(PSN-27): Add user authentication`
**Result**: Conventional commit created with Linear link

### Example 2: Commit with Custom Message

```bash
/ccpm:commit PSN-27 "Completed JWT token validation"
```

**Result**: `feat(PSN-27): Completed JWT token validation`

### Example 3: Commit with Full Conventional Format

```bash
/ccpm:commit "fix(auth): resolve login button handler"
```

**Result**: Uses provided conventional format as-is

### Example 4: Commit Without Issue ID

```bash
/ccpm:commit "update documentation"
```

**Result**: `docs: update documentation`

## Benefits

✅ **Conventional Commits**: Automatic format following best practices
✅ **Linear Integration**: Links commits to issues automatically
✅ **Smart Detection**: Auto-detects commit type from changes
✅ **Auto-Generation**: Creates meaningful messages from context
✅ **Git Integration**: Built into workflow (no context switching)
✅ **Change Summary**: Shows what's being committed before confirming

## Migration Hint

This is a NEW command that integrates git commits into CCPM workflow:
- Replaces manual `git add . && git commit -m "message"`
- Automatically follows conventional commits format
- Links commits to Linear issues
- Part of natural workflow (plan → work → commit → sync → verify → done)
