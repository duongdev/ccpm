---
description: Run quality checks - resolve IDE warnings, run linting, execute tests
allowed-tools: [Bash, LinearMCP]
argument-hint: <linear-issue-id>
---

# Quality Check for: $1

## 💡 Hint: Try the New Natural Command

For a simpler workflow, consider using:

```bash
/ccpm:verify [issue-id]
```

**Benefits:**
- Auto-detects issue from git branch if not provided
- Runs both quality checks AND final verification in sequence
- Part of the 6-command natural workflow
- See: [Quick Start Guide](./README.md#quick-start)

This command still works perfectly! The hint is just a suggestion.

---

Running comprehensive quality checks before verification.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Quality Check Workflow

### Step 0: Check Implementation Checklist Completion

**BEFORE running quality checks**, verify the Implementation Checklist is complete:

**A) Fetch Linear Issue**

Use **Linear MCP** to get issue: $1

**B) Parse Checklist from Description**

Look for checklist using markers:
```markdown
<!-- ccpm-checklist-start -->
- [ ] Task 1
- [x] Task 2
<!-- ccpm-checklist-end -->
```

Or find "## ✅ Implementation Checklist" header.

**C) Calculate Completion Percentage**

Count total items vs. checked items:
- Total items: Count all `- [ ]` and `- [x]` lines
- Checked items: Count `- [x]` lines only
- Percentage: (checked / total) × 100

**D) Display Checklist Status**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Implementation Checklist Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Progress: X% (Y/Z completed)

[If < 100%]
⚠️  Checklist is not complete!

Remaining Items:
 - [ ] Task 3: Description
 - [ ] Task 5: Description

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**E) Prompt User if Incomplete**

If completion < 100%, use **AskUserQuestion**:

```javascript
{
  questions: [
    {
      question: "Checklist shows X% complete. What would you like to do?",
      header: "Checklist",
      multiSelect: false,
      options: [
        {
          label: "Update checklist first",
          description: "Mark completed items before verification"
        },
        {
          label: "Continue anyway",
          description: "Run quality checks with incomplete checklist (warning will be logged)"
        },
        {
          label: "Cancel",
          description: "Go back and complete remaining items"
        }
      ]
    }
  ]
}
```

**If "Update checklist first" selected:**
- Display unchecked items
- Use **AskUserQuestion** multi-select to let user mark items complete
- Update description with changes
- Then proceed to quality checks

**If "Continue anyway" selected:**
- Log warning in Linear comment:
  ```markdown
  ⚠️ Quality checks run with incomplete checklist (X% complete)
  ```
- Add "incomplete-checklist" label
- Proceed to quality checks

**If "Cancel" selected:**
- Display message: "Complete remaining checklist items, then run /ccpm:verification:check $1 again"
- Exit without running checks

**If 100% complete:**
- Display: ✅ Checklist complete! Proceeding with quality checks...
- Continue to Step 1

### Step 1: IDE Warnings & Errors

Check and resolve:
- ✅ All IDE warnings
- ✅ All compilation errors
- ✅ Unused imports and variables
- ✅ Type consistency
- ✅ Missing dependencies

Use your IDE or LSP to identify issues, then fix them.

Display results:
```
🔧 IDE Checks:
[List any warnings/errors found and fixed]
```

### Step 2: Linting

Run project linter based on project type:

**For JavaScript/TypeScript projects**:
```bash
!npm run lint
# or
!yarn lint
# or
!pnpm lint
```

**For Python projects**:
```bash
!pylint src/
# or
!flake8 src/
# or
!ruff check .
```

**Auto-fix if available**:
```bash
!npm run lint:fix
# or
!yarn lint --fix
```

Display results:
```
✨ Linting:
[Show linting results]
```

If linting fails, fix all issues before proceeding.

### Step 3: Run Tests

Execute all test suites:

**For JavaScript/TypeScript**:
```bash
!npm test
# or
!yarn test
# or
!pnpm test
```

**For Python**:
```bash
!pytest
# or
!python -m unittest
```

**Optional - Check coverage**:
```bash
!npm run test:coverage
```

Display results:
```
🧪 Tests:
[X/Y tests passed]
[Coverage: Z%]
```

If any tests fail, fix them before proceeding.

### Step 4: Project-Specific Checks

Run any additional project-specific checks:
- Build verification
- Type checking (if separate from linting)
- Security scans
- Integration tests

### Step 5: Update Linear

Use **Linear MCP**:

**If ALL checks passed**:
1. Update status to: **Verification**
2. Remove label: **implementation**
3. Add label: **verification**
4. Add comment:

```markdown
## ✅ Quality Checks Passed

### Results:
- ✅ IDE checks: PASS
- ✅ Linting: PASS  
- ✅ Tests: PASS ([X]/[Y] tests)
- ✅ Coverage: [Z]%

Ready for verification!
```

**If ANY checks failed**:
1. Keep status: **In Progress**
2. Add label: **blocked**
3. Add comment:

```markdown
## ❌ Quality Checks Failed

### Issues Found:
- [ ] IDE warnings: [count and description]
- [ ] Linting errors: [count and description]
- [ ] Test failures: [count and description]

### Action Required:
Fix the issues above before proceeding to verification.
```

### Step 6: Display Summary

```
📊 Quality Check Results for $1

✅ IDE Checks: [PASS/FAIL]
✅ Linting: [PASS/FAIL]
✅ Tests: [PASS/FAIL - X/Y tests]

[If all passed]
🎉 All checks passed!
Next step: /verify $1

[If any failed]
❌ Some checks failed - please fix issues and run /check again
```

## Common Commands by Project Type

### React/Next.js
```bash
npm run lint
npm run type-check
npm test
npm run build
```

### React Native
```bash
npm run lint
npm test
npm run ios  # or android - build check
```

### Node.js/Express
```bash
npm run lint
npm run type-check
npm test
```

### Python/Django
```bash
flake8 .
mypy .
pytest
python manage.py check
```

## Notes

- Fix all issues before moving to verification
- If build fails, that's a blocking issue
- Test failures must be resolved, not skipped
- Linting rules should not be disabled to pass checks
- Use `--fix` flags when available for auto-fixes