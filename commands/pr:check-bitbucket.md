---
description: Check and analyze BitBucket PR for any project
allowed-tools: [PlaywrightMCP, BrowserMCP, LinearMCP, Read, AskUserQuestion, Bash]
argument-hint: <pr-number-or-url> [project-id]
---

# Check BitBucket PR

**Works with any project configured with BitBucket in `~/.claude/ccpm-config.yaml`**

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, comment, or modify anything on BitBucket or SonarQube without explicit user confirmation.

---

## Arguments

- **$1** - PR number or full BitBucket URL (required)
- **$2** - Project ID (optional, uses active project if not specified)

## Project Configuration

**Load project configuration to get BitBucket settings:**

```bash
# Set project argument
PROJECT_ARG="$2"  # Optional - will use active project if not provided
```

**LOAD PROJECT CONFIG**: Follow instructions in `commands/_shared-project-config-loader.md`

After loading, you'll have:
- `${REPO_TYPE}` - Should be "bitbucket"
- `${BITBUCKET_WORKSPACE}`, `${BITBUCKET_REPO}`, `${BITBUCKET_BASE_URL}`
- Custom command config (browser_mcp preference, etc.)

**Validate BitBucket is configured:**

```bash
if [[ "$REPO_TYPE" != "bitbucket" ]]; then
  echo "❌ Error: Project '$PROJECT_ID' is not configured for BitBucket"
  echo "   Current repository type: $REPO_TYPE"
  echo ""
  echo "To use this command, configure BitBucket in project settings:"
  echo "  /ccpm:project:update $PROJECT_ID"
  exit 1
fi
```

## Workflow

### Step 1: Select Browser MCP

Ask user which browser MCP to use:

```javascript
{
  questions: [{
    question: "Which browser automation tool would you like to use?",
    header: "Browser MCP",
    multiSelect: false,
    options: [
      {
        label: "Playwright MCP",
        description: "Recommended - More robust, better error handling (mcp__playwright__* tools)"
      },
      {
        label: "Browser MCP",
        description: "Alternative - Simpler interface (mcp__browsermcp__* tools)"
      }
    ]
  }]
}
```

Store the selected MCP type for use in subsequent steps.

### Step 2: Parse PR Identifier

Determine PR URL from input using loaded project configuration:

```javascript
let prUrl

if ($1.startsWith('http')) {
  // Full URL provided
  prUrl = $1
} else {
  // PR number provided - construct URL from project config
  // Use BITBUCKET_BASE_URL from loaded config
  prUrl = `${BITBUCKET_BASE_URL}/pull-requests/${$1}`

  // Alternative if base URL not in config:
  // prUrl = `https://bitbucket.org/${BITBUCKET_WORKSPACE}/${BITBUCKET_REPO}/pull-requests/${$1}`
}

console.log(`📎 PR URL: ${prUrl}`)
```

### Step 3: Navigate to PR

**IMPORTANT**: Different tool names based on selected MCP:

#### If Playwright MCP selected:
```javascript
await mcp__playwright__browser_navigate({ url: prUrl })
```

#### If Browser MCP selected:
```javascript
await mcp__browsermcp__browser_navigate({ url: prUrl })
```

**Authentication Check**:
- After navigation, check if redirected to login page
- If authentication required:
  ```
  🔐 Authentication Required

  I've navigated to the PR, but BitBucket requires sign-in.

  Please manually sign in to BitBucket in the browser, then reply with "continue" when ready.

  ⏸️  PAUSED - Waiting for authentication...
  ```
- Wait for user to reply "continue" before proceeding
- After user confirms, take a snapshot to verify successful authentication

### Step 4: Capture Initial State

Take snapshot of the PR page:

#### If Playwright MCP:
```javascript
const snapshot = await mcp__playwright__browser_snapshot({})
```

#### If Browser MCP:
```javascript
const snapshot = await mcp__browsermcp__browser_snapshot({})
```

Extract and display PR information:
- PR title
- Author
- Source/target branches
- Current status (Open, Merged, Declined)
- Number of reviewers and their status
- Number of comments

### Step 5: Check Build Status

Look for build/CI status indicators in the snapshot.

**If build is failing:**

```
⚠️  Build Status: FAILING

I can see the build is failing. Would you like me to:
1. Analyze build logs and suggest fixes
2. Skip build analysis for now

Please select an option (1 or 2):
```

If user selects option 1:
1. Click on build status link to view logs (using appropriate MCP click tool)
2. **Authentication Check**: If redirected to CI/CD login, pause and ask user to authenticate
3. Read and analyze build logs
4. Identify failure causes
5. Suggest specific fixes
6. Display suggestions but **DO NOT** make any code changes without explicit approval

**If build is passing:**
```
✅ Build Status: PASSING

Proceeding to code review...
```

### Step 6: Review SonarQube Issues

Navigate to Quality Gate section (if visible in PR):

#### If Playwright MCP:
```javascript
// Look for SonarQube link in snapshot
// Click if found
await mcp__playwright__browser_click({
  element: "SonarQube Quality Gate link",
  ref: "[ref from snapshot]"
})
```

#### If Browser MCP:
```javascript
await mcp__browsermcp__browser_click({
  element: "SonarQube Quality Gate link",
  ref: "[ref from snapshot]"
})
```

**Authentication Check**:
- If SonarQube requires login:
  ```
  🔐 SonarQube Authentication Required

  Please sign in to SonarQube in the browser, then reply with "continue" when ready.

  ⏸️  PAUSED - Waiting for authentication...
  ```
- Wait for user confirmation before proceeding

**Analyze Issues**:

For each issue found, categorize and suggest improvements:

```
📊 SonarQube Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 Critical Issues (0)
🟠 Major Issues (3)
🟡 Minor Issues (12)
📋 Code Smells (5)
🎯 Test Coverage: 78% (target: 80%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Major Issues:

1. [Bug] Potential null pointer dereference
   📁 File: src/components/TaskList.tsx:45
   💡 Suggestion: Add null check before accessing property
   ```typescript
   // Current code
   const title = task.details.title

   // Suggested fix
   const title = task.details?.title ?? 'Untitled'
   ```

2. [Security] Hardcoded credentials detected
   📁 File: src/config/api.ts:12
   💡 Suggestion: Move to environment variables
   ```typescript
   // Current code
   const API_KEY = 'sk_test_12345'

   // Suggested fix
   const API_KEY = process.env.EXPO_PUBLIC_API_KEY
   ```

3. [Performance] Inefficient array iteration
   📁 File: src/utils/helpers.ts:89
   💡 Suggestion: Use more efficient method
   ```typescript
   // Current code
   items.forEach(item => {
     if (item.id === targetId) result = item
   })

   // Suggested fix
   const result = items.find(item => item.id === targetId)
   ```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 Test Coverage Gaps:

Files below 80% coverage:
- src/components/TaskList.tsx: 65%
- src/hooks/useAuth.tsx: 72%
- src/utils/validation.ts: 45%

💡 Recommendations:
1. Add unit tests for edge cases in TaskList
2. Test error handling in useAuth hook
3. Add comprehensive tests for validation utilities

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**IMPORTANT**: Display suggestions only - DO NOT create files, commit changes, or modify code without explicit user approval.

### Step 7: Find and Sync Linear Ticket

Look for Linear issue reference in:

1. PR title (e.g., "RPT-123: Add feature")
2. Branch name (format: `feature/RPT-XXXX-description`)
3. PR description
4. Extract Jira ticket ID if found (format: `RPT-\d+`)

#### Search for Linear Issue

```javascript
// Extract ticket ID from PR
const ticketMatch = branchName.match(/RPT-(\d+)/) ||
                   prTitle.match(/RPT-(\d+)/) ||
                   prDescription.match(/RPT-(\d+)/)

let linearIssue = null

if (ticketMatch) {
  const ticketId = `RPT-${ticketMatch[1]}`
  console.log(`🔍 Found Jira Ticket: ${ticketId}`)

  // Search for Linear issue linked to this Jira ticket
  // Use Linear MCP to search by title or description containing ticket ID
  const searchResults = await mcp__linear__list_issues({
    team: ${LINEAR_TEAM},  // or appropriate team identifier
    query: ticketId,
    limit: 10
  })

  // Find exact match
  linearIssue = searchResults.find(issue =>
    issue.title.includes(ticketId) ||
    issue.description?.includes(ticketId)
  )

  if (linearIssue) {
    console.log(`✅ Found Linear Issue: ${linearIssue.identifier} - ${linearIssue.title}`)
  } else {
    console.log(`⚠️  No Linear issue found for Jira ticket ${ticketId}`)
  }
}
```

#### Display Current Status

If Linear issue found:

```plaintext
📋 Linear Issue Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Issue: ${linearIssue.identifier}
Title: ${linearIssue.title}
Status: ${linearIssue.state.name}
Assignee: ${linearIssue.assignee?.name || 'Unassigned'}
Priority: ${linearIssue.priority || 'None'}
Labels: ${linearIssue.labels.map(l => l.name).join(', ')}

🔗 Jira Ticket: ${ticketId}
🔗 PR: #${prNumber}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Sync PR Status to Linear

Ask user if they want to update Linear:

```javascript
{
  questions: [{
    question: "Would you like to sync PR review findings to Linear?",
    header: "Linear Sync",
    multiSelect: false,
    options: [
      {
        label: "Add Comment",
        description: "Add PR review summary as Linear comment"
      },
      {
        label: "Update Status",
        description: "Update Linear issue status based on PR state"
      },
      {
        label: "Both",
        description: "Add comment AND update status"
      },
      {
        label: "Skip",
        description: "Don't sync to Linear"
      }
    ]
  }]
}
```

**Option: Add Comment**

Draft Linear comment with PR review findings:

```markdown
## PR Review - #${prNumber}

### Status: ${prStatus} (${buildStatus})

### Build & Quality
- Build: ${buildPassing ? '✅ Passing' : '❌ Failing'}
- Tests: ${testsPassing ? '✅ All passing' : '⚠️  Some failing'}
- Coverage: ${testCoverage}%
- SonarQube: ${criticalIssues} critical, ${majorIssues} major, ${minorIssues} minor

### Issues Found
${issuesList}

### Recommended Actions
${recommendedActions}

🔗 [View PR](${prUrl})
```

Show preview and ask for confirmation:

```plaintext
🚨 CONFIRMATION REQUIRED

I'll add the following comment to Linear issue ${linearIssue.identifier}:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Show comment preview above]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reply "yes" to post, or "no" to cancel.
```

If user confirms:

```javascript
await mcp__linear__create_comment({
  issueId: linearIssue.id,
  body: commentMarkdown
})

console.log('✅ Comment added to Linear issue')
```

**Option: Update Status**

Suggest status update based on PR state:

```javascript
// Determine suggested status
let suggestedStatus = linearIssue.state.name  // Keep current by default

if (prStatus === 'MERGED') {
  suggestedStatus = 'Done'
} else if (prStatus === 'OPEN' && buildPassing && noBlockingIssues) {
  suggestedStatus = 'In Review'
} else if (prStatus === 'OPEN' && (!buildPassing || hasBlockingIssues)) {
  suggestedStatus = 'In Progress'  // Needs fixes
} else if (prStatus === 'DECLINED') {
  suggestedStatus = 'Canceled'
}

// Show current and suggested status
console.log(`
📊 Status Update Suggestion
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Status: ${linearIssue.state.name}
Suggested Status: ${suggestedStatus}

Reason: ${getStatusReason()}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`)

// Ask for confirmation
{
  questions: [{
    question: `Update Linear status from "${linearIssue.state.name}" to "${suggestedStatus}"?`,
    header: "Status Update",
    multiSelect: false,
    options: [
      { label: "Yes", description: "Update status as suggested" },
      { label: "Choose Different", description: "Select a different status" },
      { label: "No", description: "Keep current status" }
    ]
  }]
}
```

If user chooses "Choose Different":

```javascript
// Get available statuses for the team
const statuses = await mcp__linear__list_issue_statuses({
  team: linearIssue.team.key
})

// Ask user to select
{
  questions: [{
    question: "Which status would you like?",
    header: "Select Status",
    multiSelect: false,
    options: statuses.map(s => ({
      label: s.name,
      description: s.description || s.type
    }))
  }]
}
```

If user confirms status update:

```javascript
await mcp__linear__update_issue({
  id: linearIssue.id,
  state: selectedStatus
})

console.log(`✅ Linear issue updated to "${selectedStatus}"`)
```

**Option: Both**

Execute both comment addition and status update in sequence with confirmations.

#### If No Linear Issue Found

Offer to create one:

```javascript
if (!linearIssue && ticketId) {
  {
    questions: [{
      question: "No Linear issue found. Would you like to create one?",
      header: "Create Linear Issue",
      multiSelect: false,
      options: [
        {
          label: "Yes",
          description: `Create Linear issue for ${ticketId}`
        },
        {
          label: "No",
          description: "Skip Linear tracking"
        }
      ]
    }]
  }

  if (userWantsCreate) {
    // Create Linear issue with PR context
    const newIssue = await mcp__linear__create_issue({
      team: ${LINEAR_TEAM},
      title: `[${ticketId}] ${prTitle}`,
      description: `
# Jira Ticket: ${ticketId}
# PR: #${prNumber}

${prDescription}

## PR Review Findings
${reviewSummary}
      `,
      state: 'In Review',
      labels: ['pr-review'],
      // Add PR link
      links: [{
        url: prUrl,
        title: `PR #${prNumber}`
      }]
    })

    console.log(`✅ Created Linear issue: ${newIssue.identifier}`)
  }
}
```

### Step 8: Quality Verification Checklist

Display comprehensive quality checklist:

```
✅ Quality Verification Checklist
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Build & Tests:
  ✅ Build passing
  ✅ All tests passing
  ⚠️  Test coverage: 78% (below 80% target)

Code Quality:
  ⚠️  3 major SonarQube issues
  ⚠️  12 minor issues
  ✅ No critical/blocking issues

Best Practices:
  ✅ Proper error handling
  ⚠️  Hardcoded credentials detected
  ✅ TypeScript types properly defined

Security:
  ⚠️  1 security vulnerability (hardcoded credentials)
  ✅ No SQL injection risks
  ✅ No XSS vulnerabilities

Performance:
  ⚠️  1 inefficient iteration pattern
  ✅ No memory leaks detected

Documentation:
  ✅ PR description clear
  ✅ Code comments present
  ⚠️  Missing JSDoc for public APIs

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overall Assessment: NEEDS IMPROVEMENTS ⚠️

Recommended Actions:
1. Fix hardcoded credentials (security issue)
2. Improve test coverage to 80%+
3. Address major SonarQube issues
4. Optimize array iteration pattern

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 9: Interactive Next Actions

Ask user what they want to do:

```javascript
{
  questions: [{
    question: "What would you like to do next?",
    header: "Next Action",
    multiSelect: false,
    options: [
      {
        label: "Sync to Linear",
        description: "Update Linear issue with PR review findings (if Linear issue found)"
      },
      {
        label: "Fix Issues Locally",
        description: "I'll help you fix the identified issues in your local codebase"
      },
      {
        label: "Review Code Changes",
        description: "Let me show you the specific code changes in this PR"
      },
      {
        label: "Generate PR Comment",
        description: "Draft a review comment (I'll show it to you before posting)"
      },
      {
        label: "Export Report",
        description: "Save this analysis to a markdown file"
      },
      {
        label: "Done",
        description: "Just review the findings above"
      }
    ]
  }]
}
```

Handle each option:

#### Option 1: Sync to Linear

If Linear issue was found in Step 7, re-run the Linear sync workflow:

```javascript
if (linearIssue) {
  // Go back to Step 7: Sync PR Status to Linear
  // Show the same options: Add Comment, Update Status, Both, Skip
  // Execute based on user selection with confirmations
} else {
  console.log('⚠️  No Linear issue found. Run Step 7 to search or create one.')
}
```

#### Option 2: Fix Issues Locally
```
I can help you fix the issues. Would you like me to:

1. Fix security issues (hardcoded credentials)
2. Improve test coverage
3. Refactor inefficient code
4. All of the above

Please select or reply with specific instructions.
```

After user confirms what to fix, make the changes and show a summary before committing.

#### Option 3: Review Code Changes

Navigate to "Files changed" tab and analyze specific modifications.

#### Option 4: Generate PR Comment
Draft a professional review comment:

```markdown
## Code Review Summary

### ✅ Strengths
- Clean code structure
- Good test coverage in core modules
- Proper TypeScript usage

### ⚠️ Issues to Address

**High Priority:**
1. **Security**: Remove hardcoded credentials in `src/config/api.ts`
2. **Test Coverage**: Increase coverage to 80%+ (currently 78%)

**Medium Priority:**
3. **Performance**: Optimize array iteration in `src/utils/helpers.ts:89`
4. **Code Quality**: Address 3 major SonarQube issues

### 📝 Detailed Recommendations

[... detailed suggestions from Step 6 ...]

### 🎯 Next Steps
1. Address security vulnerability
2. Add missing test cases
3. Re-run SonarQube analysis
4. Request re-review when ready
```

Show this to user:
```
🚨 CONFIRMATION REQUIRED

I've drafted the following PR review comment.

Would you like me to post this to BitBucket?

⚠️  This will add a comment to PR #${prNumber}

Reply "yes" to post, "edit" to modify, or "no" to cancel.
```

**DO NOT POST** without explicit "yes" confirmation.

#### Option 5: Export Report
```javascript
const reportPath = `./pr-${prNumber}-review-${Date.now()}.md`

// Generate comprehensive markdown report
const report = `# PR #${prNumber} Review Report

Generated: ${new Date().toISOString()}

... (include all analysis from above)
...
`

// Save to file
fs.writeFileSync(reportPath, report)

console.log(`✅ Report saved to: ${reportPath}`)
```

### Step 10: Close Browser (Optional)

Ask user if they want to close the browser:

```javascript
{
  questions: [{
    question: "Close the browser?",
    header: "Cleanup",
    multiSelect: false,
    options: [
      { label: "Yes", description: "Close browser session" },
      { label: "No", description: "Keep browser open for manual review" }
    ]
  }]
}
```

#### If Playwright MCP:
```javascript
if (userWantsClose) {
  await mcp__playwright__browser_close({})
}
```

#### If Browser MCP:
```javascript
if (userWantsClose) {
  await mcp__browsermcp__browser_close({})
}
```

## Safety Reminders

Throughout the entire workflow:

1. **✅ READ OPERATIONS** - Freely read from BitBucket, SonarQube, Jira
2. **⛔ WRITE OPERATIONS** - ALWAYS require explicit confirmation:
   - Posting PR comments
   - Updating Jira tickets
   - Committing code changes
   - Modifying any external system

3. **🔐 AUTHENTICATION** - Pause and wait for user to sign in manually:
   - BitBucket login
   - SonarQube login
   - CI/CD system login

4. **📝 TRANSPARENCY** - Always show what you plan to do before doing it:
   - Show comment drafts before posting
   - Show code changes before committing
   - Show ticket updates before sending

## Examples

### Example 1: Check PR by number

```bash
/ccpm:pr:check-bitbucket 123

# Workflow:
# 1. Ask which MCP to use
# 2. Navigate to PR #123
# 3. Authenticate if needed
# 4. Analyze build, SonarQube, code
# 5. Show findings
# 6. Ask for next action
```

### Example 2: Check PR by URL

```bash
/ccpm:pr:check-bitbucket https://bitbucket.org/my-workspace/my-repo/pull-requests/456

# Workflow:
# Same as above but uses provided URL directly
```

### Example 3: Full workflow with fixes

```bash
/ccpm:pr:check-bitbucket 789

# After review:
# User selects: "Fix Issues Locally"
# User confirms: "Fix all issues"
# → Makes changes
# → Shows diff
# → Asks: "Commit these changes?"
# → User confirms: "yes"
# → Commits with message: "fix: address PR review findings"
```

## Notes

- Browser MCP selection allows flexibility between Playwright and Browser MCPs
- All authentication is manual - we pause and wait for user
- Zero mutations without explicit approval
- Comprehensive analysis with actionable suggestions
- Interactive workflow for maximum control
- Export capability for offline review
- Respects PM Commands safety rules throughout
