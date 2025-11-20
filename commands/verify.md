---
description: Smart verification command - run quality checks and final verification
allowed-tools: [Bash, LinearMCP]
argument-hint: "[issue-id]"
---

# Smart Verify Command

You are executing the **smart verification command** that runs quality checks and final verification in sequence.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

## Auto-Detection

The command can detect the issue ID from:
1. **Command argument** (if provided): `/ccpm:verify PSN-27`
2. **Git branch name** (if no argument): `/ccpm:verify` (detects from branch)

## Verification Flow

This command executes a **sequential verification flow**:

1. **Quality Checks** (`/ccpm:verification:check`)
   - Resolve IDE warnings
   - Run linting
   - Execute tests
   - Build verification

2. **Final Verification** (`/ccpm:verification:verify`) - Only if checks pass
   - Code review
   - Security audit (if applicable)
   - Final quality assessment

## Implementation

### Step 1: Determine Issue ID

```javascript
const args = process.argv.slice(2)
let issueId = args[0]

const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/

// If no issue ID provided, try to detect from git branch
if (!issueId || !ISSUE_ID_PATTERN.test(issueId)) {
  try {
    const branch = execSync('git rev-parse --abbrev-ref HEAD', {
      encoding: 'utf-8'
    }).trim()

    const branchMatch = branch.match(/([A-Z]+-\d+)/)
    if (branchMatch) {
      issueId = branchMatch[1]
      console.log(`🔍 Detected issue from branch: ${issueId}`)
    } else {
      console.error("❌ Could not detect issue ID from branch name")
      console.log("")
      console.log("Please provide an issue ID:")
      console.log("  /ccpm:verify PSN-27")
      process.exit(1)
    }
  } catch (error) {
    console.error("❌ Error: Not in a git repository or could not detect issue")
    console.log("")
    console.log("Please provide an issue ID:")
    console.log("  /ccpm:verify PSN-27")
    process.exit(1)
  }
}
```

### Step 2: Display Verification Flow

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Smart Verify Command
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: ${issueId}

Verification Flow:
──────────────────
1. Quality Checks (linting, tests, build)
2. Final Verification (code review, security)

Starting verification...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 3: Execute Quality Checks First

```javascript
console.log("Step 1/2: Running quality checks...")
console.log("")

// Use SlashCommand to execute verification:check
let checksPassed = false

try {
  const checkResult = await SlashCommand(`/ccpm:verification:check ${issueId}`)

  // Parse result to determine if checks passed
  // Look for success indicators in output
  checksPassed = !checkResult.includes('❌') &&
                 !checkResult.includes('FAILED') &&
                 (checkResult.includes('✅') || checkResult.includes('PASSED'))

  console.log("")
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.log("")

} catch (error) {
  console.error("❌ Quality checks failed")
  checksPassed = false
}
```

### Step 4: Decide Next Action

```javascript
if (!checksPassed) {
  // Checks failed, stop here
  console.log("❌ Quality Checks Failed")
  console.log("")
  console.log("Please fix the issues before continuing:")
  console.log(`  /ccpm:verification:fix ${issueId}`)
  console.log("")
  console.log("Then run verification again:")
  console.log(`  /ccpm:verify ${issueId}`)
  console.log("")

  process.exit(1)
}

// Checks passed, proceed to final verification
console.log("✅ Quality Checks Passed!")
console.log("")
console.log("Step 2/2: Running final verification...")
console.log("")
```

### Step 5: Execute Final Verification

```javascript
try {
  await SlashCommand(`/ccpm:verification:verify ${issueId}`)

  console.log("")
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.log("✅ All Verification Complete!")
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  console.log("")

} catch (error) {
  console.error("❌ Final verification encountered issues")
  process.exit(1)
}
```

### Step 6: Suggest Next Action

```markdown
💡 What's Next?
───────────────

All verifications passed! Ready to finalize:

  /ccpm:done ${issueId}

This will:
  • Create pull request
  • Sync status to Jira (if configured)
  • Send Slack notification (if configured)
  • Mark task as complete

Or continue making changes:
  /ccpm:work ${issueId}
```

Use **AskUserQuestion**:

```javascript
{
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
        label: "Review Status",
        description: "Check current status (/ccpm:utils:status)"
      }
    ]
  }]
}
```

Execute chosen action:
- **Finalize** → `SlashCommand(\`/ccpm:done ${issueId}\`)`
- **Continue** → `SlashCommand(\`/ccpm:work ${issueId}\`)`
- **Review** → `SlashCommand(\`/ccpm:utils:status ${issueId}\`)`

## Examples

### Example 1: Verify with Auto-Detection

```bash
git checkout -b duongdev/PSN-27-add-auth
# ... complete work ...
/ccpm:verify
```

**Detection**: PSN-27 from branch
**Flow**: Runs checks → passes → runs final verification → suggests finalize
**Result**: Task fully verified

### Example 2: Verify with Explicit Issue ID

```bash
/ccpm:verify PSN-27
```

**Flow**: Same sequential verification
**Result**: Ready to finalize

### Example 3: Verification Fails at Checks

```bash
/ccpm:verify PSN-27
```

**Result**:
```
❌ Quality Checks Failed

Linting errors: 3
Test failures: 1

Please fix the issues:
  /ccpm:verification:fix PSN-27

Then run verification again:
  /ccpm:verify PSN-27
```

## Benefits

✅ **Sequential Flow**: Runs checks first, then verification (logical order)
✅ **Auto-Detection**: No need to provide issue ID if on feature branch
✅ **Fail Fast**: Stops at quality checks if they fail (no wasted time)
✅ **Smart Routing**: Routes to next appropriate action based on results
✅ **Interactive**: Suggests next steps after success

## Migration Hint

This command replaces:
- `/ccpm:verification:check` followed by `/ccpm:verification:verify`
- Use `/ccpm:verify` for both in sequence

The old commands still work and will show hints to use this command.

## Error Handling

### If checks fail:
```markdown
❌ Quality Checks Failed

To debug and fix:
  /ccpm:verification:fix ${issueId}

To see detailed failures:
  npm run lint    # Check linting
  npm test        # Run tests
  npm run build   # Try building
```

### If final verification has issues:
```markdown
⚠️  Code Review Agent found issues

Review the feedback above and make necessary changes.

Then re-run verification:
  /ccpm:verify ${issueId}
```
