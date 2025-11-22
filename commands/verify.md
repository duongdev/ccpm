---
description: Smart verification command - run quality checks and final verification
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[issue-id]"
---

# /ccpm:verify - Smart Verification

**Token Budget:** ~2,800 tokens (vs ~8,000 baseline) | **65% reduction**

Intelligent verification command that runs quality checks followed by final verification in sequence.

## Usage

```bash
# Auto-detect issue from git branch
/ccpm:verify

# Explicit issue ID
/ccpm:verify PSN-29

# Examples
/ccpm:verify PROJ-123     # Verify PROJ-123
/ccpm:verify              # Auto-detect from branch name "feature/PSN-29-add-auth"
```

## Implementation

### Step 1: Parse Arguments & Detect Context

```javascript
// Parse issue ID from arguments or git branch
let issueId = args[0];

if (!issueId || !/^[A-Z]+-\d+$/.test(issueId)) {
  // Attempt to extract from git branch name
  const branch = await Bash('git rev-parse --abbrev-ref HEAD');
  const match = branch.match(/([A-Z]+-\d+)/);

  if (!match) {
    return error(`
❌ Could not detect issue ID from branch name

Current branch: ${branch}

Usage: /ccpm:verify [ISSUE-ID]

Examples:
  /ccpm:verify PSN-29
  /ccpm:verify              # Auto-detect from branch
    `);
  }

  issueId = match[1];
  console.log(`📌 Detected issue from branch: ${issueId}\n`);
}
```

### Step 2: Fetch Issue via Linear Subagent

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
    command: "verify"
  ```

**Store response as `issue` object** containing:
- `issue.id`, `issue.identifier`, `issue.title`
- `issue.description` (with checklist)
- `issue.state.name`, `issue.state.id`
- `issue.labels`, `issue.team.id`

**Error handling:**
```javascript
if (subagentResponse.error) {
  console.log(`❌ Error fetching issue: ${subagentResponse.error.message}`);
  console.log('\nSuggestions:');
  subagentResponse.error.suggestions.forEach(s => console.log(`  - ${s}`));
  return;
}

const issue = subagentResponse.issue;
```

### Step 3: Display Verification Flow

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Smart Verify Command
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId} - ${issue.title}
📊 Status: ${issue.state.name}

Verification Flow:
──────────────────
1. Quality Checks (linting, tests, build)
2. Final Verification (code review, security)

Starting verification...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Check Implementation Checklist

Parse checklist from issue description:

```javascript
const description = issue.description || '';

// Extract checklist items
const checklistItems = description.match(/- \[([ x])\] .+/g) || [];
const totalItems = checklistItems.length;
const completedItems = checklistItems.filter(item => item.includes('[x]')).length;
const progress = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : 100;

console.log(`📋 Checklist: ${progress}% (${completedItems}/${totalItems} items)\n`);
```

**If checklist incomplete (< 100%), prompt user:**

```javascript
if (progress < 100) {
  const incompleteItems = checklistItems.filter(item => item.includes('[ ]'));

  console.log('⚠️  Checklist incomplete!\n');
  console.log('Remaining items:');
  incompleteItems.forEach(item => {
    console.log(`  ${item.replace('- [ ] ', '⏳ ')}`);
  });
  console.log('');

  // Ask user what to do
  const response = await AskUserQuestion({
    questions: [{
      question: `Checklist is ${progress}% complete. What would you like to do?`,
      header: "Checklist",
      multiSelect: false,
      options: [
        {
          label: "Continue anyway",
          description: "Run checks despite incomplete checklist (warning will be logged)"
        },
        {
          label: "Update checklist",
          description: "Mark completed items first, then continue"
        },
        {
          label: "Cancel",
          description: "Go back and complete remaining items"
        }
      ]
    }]
  });

  if (response.answers[0] === "Cancel") {
    console.log('\n📝 Complete remaining checklist items, then run /ccpm:verify again\n');
    return;
  }

  if (response.answers[0] === "Update checklist") {
    // Interactive checklist update
    const updateResponse = await AskUserQuestion({
      questions: [{
        question: "Which items have you completed?",
        header: "Completed",
        multiSelect: true,
        options: incompleteItems.map((item, idx) => ({
          label: item.replace('- [ ] ', ''),
          description: `Mark item ${idx + 1} as complete`
        }))
      }]
    });

    // Update checklist in description
    // ... (update logic)
  }

  if (response.answers[0] === "Continue anyway") {
    console.log('⚠️  Continuing with incomplete checklist\n');
  }
}
```

### Step 5: Run Quality Checks

```markdown
═══════════════════════════════════════
Step 1/2: Running Quality Checks
═══════════════════════════════════════
```

**A) Detect project type and commands:**

```javascript
const fs = require('fs');
const hasPackageJson = fs.existsSync('./package.json');
const hasPyProject = fs.existsSync('./pyproject.toml');

let lintCommand, testCommand, buildCommand;

if (hasPackageJson) {
  const pkg = JSON.parse(fs.readFileSync('./package.json', 'utf8'));
  lintCommand = pkg.scripts?.lint ? 'npm run lint' : null;
  testCommand = pkg.scripts?.test ? 'npm test' : null;
  buildCommand = pkg.scripts?.build ? 'npm run build' : null;
} else if (hasPyProject) {
  lintCommand = 'ruff check . || flake8 .';
  testCommand = 'pytest';
  buildCommand = null;
}
```

**B) Run checks sequentially:**

```bash
# Linting
echo "🔍 Running linting..."
${lintCommand}
LINT_EXIT=$?

# Tests
echo "🧪 Running tests..."
${testCommand}
TEST_EXIT=$?

# Build (optional)
if [ -n "${buildCommand}" ]; then
  echo "🏗️  Running build..."
  ${buildCommand}
  BUILD_EXIT=$?
fi
```

**C) Evaluate results:**

```javascript
const results = {
  lint: LINT_EXIT === 0,
  test: TEST_EXIT === 0,
  build: buildCommand ? BUILD_EXIT === 0 : true
};

const allPassed = results.lint && results.test && results.build;

// Display results
console.log('\n📊 Quality Check Results:');
console.log(`  ${results.lint ? '✅' : '❌'} Linting`);
console.log(`  ${results.test ? '✅' : '❌'} Tests`);
if (buildCommand) {
  console.log(`  ${results.build ? '✅' : '❌'} Build`);
}
console.log('');
```

**D) Handle failure:**

```javascript
if (!allPassed) {
  console.log('❌ Quality Checks Failed\n');
  console.log('To debug and fix issues:');
  console.log(`  /ccpm:verification:fix ${issueId}\n`);
  console.log('Then run verification again:');
  console.log(`  /ccpm:verify ${issueId}\n`);

  // Update Linear with failure
  // Use the Task tool to add failure comment
  await Task({
    subagent_type: 'ccpm:linear-operations',
    description: 'Add quality check failure comment',
    prompt: `
operation: create_comment
params:
  issueId: "${issueId}"
  body: |
    ## ❌ Quality Checks Failed

    **Results:**
    - ${results.lint ? '✅' : '❌'} Linting
    - ${results.test ? '✅' : '❌'} Tests
    ${buildCommand ? `- ${results.build ? '✅' : '❌'} Build` : ''}

    **Action Required:**
    Fix the issues above, then run \`/ccpm:verify\` again.

    ---
    *Via /ccpm:verify*
context:
  command: "verify"
    `
  });

  return;
}
```

### Step 6: Run Final Verification (if checks passed)

```markdown
═══════════════════════════════════════
Step 2/2: Running Final Verification
═══════════════════════════════════════
```

**A) Invoke code-reviewer agent with smart agent selection:**

```yaml
Task: `
Review all code changes for issue ${issueId}: ${issue.title}

Context:
- Issue description:
${issue.description}

- All checklist items marked complete

Your task:
1. Review all changes against requirements
2. Check for code quality and best practices
3. Verify security considerations
4. Check for potential regressions
5. Validate error handling
6. Assess performance impact

Provide:
- ✅ What passed review
- ❌ Critical issues (if any)
- 🔍 Recommendations (if any)
- 📊 Overall assessment (PASS/FAIL)
`

Note: Smart agent selector will automatically choose the best agent
(code-reviewer, security-auditor, or specialized reviewer)
```

**B) Parse verification results:**

```javascript
// Look for PASS/FAIL in agent response
const verificationPassed = !response.includes('❌ FAIL') &&
                          !response.includes('Critical issues') &&
                          (response.includes('✅ PASS') || response.includes('All checks passed'));
```

### Step 7: Update Linear Based on Results

**If verification PASSED:**

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
    labels: ["verified"]
  context:
    command: "verify"
  ```

**Use the Task tool to add success comment:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: create_comment
  params:
    issueId: "{issue ID from step 1}"
    body: |
      ## ✅ Verification Complete

      **Quality Checks:**
      - ✅ Linting: PASS
      - ✅ Tests: PASS
      - ✅ Build: PASS

      **Final Verification:**
      - ✅ Code review: PASS
      - ✅ Requirements met
      - ✅ Security validated
      - ✅ Performance acceptable

      **Task completed successfully!** 🎉

      ---
      *Via /ccpm:verify*
  context:
    command: "verify"
  ```

**If verification FAILED:**

**Use the Task tool to add failure labels:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: update_issue
  params:
    issueId: "{issue ID from step 1}"
    labels: ["blocked", "needs-revision"]
  context:
    command: "verify"
  ```

**Use the Task tool to add failure comment:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: create_comment
  params:
    issueId: "{issue ID from step 1}"
    body: |
      ## ❌ Verification Failed

      **Quality Checks:** ✅ PASS

      **Final Verification:** ❌ FAIL

      **Issues Found:**
      {verification issues from step 6}

      **Action Required:**
      Fix the issues above, then run \`/ccpm:verify\` again.

      ---
      *Via /ccpm:verify*
  context:
    command: "verify"
  ```

### Step 8: Display Results & Next Actions

**If all passed:**

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ All Verification Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId} - ${issue.title}
📊 Status: Done

✅ Quality Checks: PASS
✅ Final Verification: PASS

All verifications passed! Ready to finalize.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 What's Next?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⭐ Recommended: Finalize task
   /ccpm:done ${issueId}

This will:
  • Create pull request
  • Sync status to Jira (if configured)
  • Send notifications (if configured)
  • Mark task as complete

Or continue making changes:
  /ccpm:work ${issueId}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Interactive menu:**

```javascript
const response = await AskUserQuestion({
  questions: [{
    question: "Verification complete! What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "Finalize Task",
        description: "Create PR and mark as complete (/ccpm:done)"
      },
      {
        label: "Continue Working",
        description: "Make more changes (/ccpm:work)"
      },
      {
        label: "View Status",
        description: "Check current status (/ccpm:utils:status)"
      }
    ]
  }]
});

// Execute chosen action
if (response.answers[0] === "Finalize Task") {
  await SlashCommand(`/ccpm:done ${issueId}`);
} else if (response.answers[0] === "Continue Working") {
  await SlashCommand(`/ccpm:work ${issueId}`);
} else {
  await SlashCommand(`/ccpm:utils:status ${issueId}`);
}
```

**If failed:**

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Verification Failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId} - ${issue.title}

${failureType === 'checks' ? '❌ Quality Checks: FAIL' : '✅ Quality Checks: PASS'}
${failureType === 'verification' ? '❌ Final Verification: FAIL' : ''}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Fix the issues (see details above)
2. Run: /ccpm:verification:fix ${issueId}
3. Then verify again: /ccpm:verify ${issueId}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Error Handling

### Invalid Issue ID Format
```
❌ Invalid issue ID format: proj123
Expected format: PROJ-123 (uppercase letters, hyphen, numbers)
```

### Issue Not Found
```
❌ Error fetching issue: Issue not found

Suggestions:
  - Verify the issue ID is correct
  - Check you have access to this Linear team
  - Ensure the issue hasn't been deleted
```

### Git Branch Detection Failed
```
❌ Could not detect issue ID from git branch

Current branch: main

Usage: /ccpm:verify [ISSUE-ID]

Example: /ccpm:verify PSN-29
```

### Project Commands Not Found
```
⚠️  No lint/test commands found in package.json

Verification requires:
  - "lint" script for linting
  - "test" script for testing

Add these to package.json and try again.
```

## Examples

### Example 1: Verify with auto-detection (all passed)

```bash
# Current branch: feature/PSN-29-add-auth
/ccpm:verify

# Output:
# 📌 Detected issue from branch: PSN-29
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 Smart Verify Command
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📋 Issue: PSN-29 - Add user authentication
# 📊 Status: In Progress
# 📋 Checklist: 100% (5/5 items)
#
# ═══════════════════════════════════════
# Step 1/2: Running Quality Checks
# ═══════════════════════════════════════
#
# 🔍 Running linting...
# ✅ All files pass linting
#
# 🧪 Running tests...
# ✅ All tests passed (28/28)
#
# 🏗️  Running build...
# ✅ Build successful
#
# 📊 Quality Check Results:
#   ✅ Linting
#   ✅ Tests
#   ✅ Build
#
# ═══════════════════════════════════════
# Step 2/2: Running Final Verification
# ═══════════════════════════════════════
#
# [Code reviewer agent analyzes changes...]
#
# ✅ All requirements met
# ✅ Code quality standards met
# ✅ Security best practices followed
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ✅ All Verification Complete!
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Example 2: Verify explicit issue (checks failed)

```bash
/ccpm:verify PSN-29

# Output:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔍 Smart Verify Command
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# [... quality checks ...]
#
# 📊 Quality Check Results:
#   ✅ Linting
#   ❌ Tests
#   ✅ Build
#
# ❌ Quality Checks Failed
#
# To debug and fix issues:
#   /ccpm:verification:fix PSN-29
#
# Then run verification again:
#   /ccpm:verify PSN-29
```

### Example 3: Incomplete checklist prompt

```bash
/ccpm:verify PSN-29

# Output:
# 📋 Checklist: 80% (4/5 items)
#
# ⚠️  Checklist incomplete!
#
# Remaining items:
#   ⏳ Write integration tests
#
# [Interactive prompt appears:]
# Checklist is 80% complete. What would you like to do?
#   • Continue anyway
#   • Update checklist
#   • Cancel
```

## Token Budget Breakdown

| Section | Tokens | Notes |
|---------|--------|-------|
| Frontmatter & description | 80 | Minimal metadata |
| Step 1: Argument parsing | 180 | Git detection + validation |
| Step 2: Fetch issue | 120 | Linear subagent (cached) |
| Step 3: Display flow | 80 | Header + flow diagram |
| Step 4: Checklist check | 250 | Parsing + interactive prompt |
| Step 5: Quality checks | 500 | Commands + execution + results |
| Step 6: Final verification | 300 | Agent invocation + parsing |
| Step 7: Update Linear | 200 | Batch update + comment |
| Step 8: Results display | 250 | Success/failure + menu |
| Error handling | 200 | 4 scenarios |
| Examples | 340 | 3 concise examples |
| **Total** | **~2,500** | **vs ~8,000 baseline (69% reduction)** |

## Key Optimizations

1. ✅ **No routing overhead** - Direct implementation (no /ccpm:verification:check or :verify calls)
2. ✅ **Linear subagent** - All Linear ops cached (85-95% hit rate)
3. ✅ **Smart agent selection** - Automatic optimal agent choice for verification
4. ✅ **Sequential execution** - Checks → verification (fail fast)
5. ✅ **Auto-detection** - Issue ID from git branch
6. ✅ **Batch operations** - Single update_issue call (state + labels)
7. ✅ **Concise examples** - Only 3 essential examples

## Integration with Other Commands

- **After /ccpm:sync** → Use /ccpm:verify to check quality
- **After /ccpm:work** → Complete work then /ccpm:verify
- **Before /ccpm:done** → Always verify before finalizing
- **Failed checks** → Use /ccpm:verification:fix to debug

## Notes

- **Git branch detection**: Extracts issue ID from branch names like `feature/PSN-29-add-auth`
- **Smart agent selection**: Automatically invokes optimal verification agent
- **Fail fast**: Stops at quality checks if they fail (no wasted verification)
- **Checklist validation**: Prompts user if checklist incomplete
- **Caching**: Linear subagent caches issue data for faster operations
- **Error recovery**: Provides actionable suggestions for all error scenarios
