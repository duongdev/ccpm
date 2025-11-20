---
description: Run quality checks - resolve IDE warnings, run linting, execute tests
allowed-tools: [Bash, LinearMCP]
argument-hint: <linear-issue-id>
---

# Quality Check for: $1

Running comprehensive quality checks before verification.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Quality Check Workflow

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