---
description: Verify completed work with verification agent - final review before completion
allowed-tools: [Bash, LinearMCP]
argument-hint: <linear-issue-id>
---

# Verifying Task: $1

Running final verification before marking task as complete.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Verification Workflow

### Step 1: Fetch Task Requirements

Use **Linear MCP** to get issue: $1

Review:
- Original requirements
- All checklist items
- Expected outcomes
- Success criteria

### Step 2: Invoke Verification Agent

From **CLAUDE.md**, invoke the **verification-agent** with:

**Context**:
```
Task: $1
Requirements: [from Linear description]
All changes made: [list of modified files]
All completed subtasks: [from checklist]
```

**Verification Checklist**:
- [ ] All requirements from original ticket met
- [ ] All checklist items completed
- [ ] Code follows project patterns and conventions
- [ ] No regressions in existing functionality
- [ ] All tests passing
- [ ] No security vulnerabilities introduced
- [ ] Performance meets expectations
- [ ] Error handling is comprehensive
- [ ] Documentation updated if needed
- [ ] Code is production-ready

**Ask verification-agent to**:
1. Review all changes against requirements
2. Run comprehensive test suite
3. Check for regressions
4. Validate against original ticket
5. Verify code quality standards
6. Check security best practices
7. Assess performance impact

### Step 3: Collect Verification Results

The verification-agent should provide:
- ✅ What passed verification
- ❌ What failed verification (if any)
- 🔍 Any concerns or recommendations
- 📊 Test results
- 🚨 Critical issues found (if any)

### Step 4a: If Verification PASSES

Use **Linear MCP** to:

1. Update status to: **Done**
2. Remove labels: **verification**, **blocked**
3. Mark all checklist items as complete
4. Add completion comment:

```markdown
## ✅ Verification Complete - Task Done!

### Verification Results
✅ All requirements met
✅ All tests passing ([X]/[Y] tests)
✅ No regressions detected
✅ Code quality standards met
✅ Security best practices followed
✅ Performance acceptable

### Implementation Summary
[High-level summary of what was implemented]

### Changes Made
**Files Modified**:
- [file1.ts - description]
- [file2.tsx - description]
- [file3.py - description]

**Key Features Implemented**:
- [Feature 1]
- [Feature 2]
- [Feature 3]

### Test Coverage
- Unit tests: [X] added/updated
- Integration tests: [Y] added/updated
- All tests passing: ✅

### Related Links
- Original ticket: [Jira link if applicable]
- Pull request: [PR link if created]
- Documentation: [Doc link if updated]

---

**Task completed successfully!** 🎉
```

Display success message:
```
🎉 Verification Passed!

✅ Task $1 is complete and verified
✅ Status updated to Done
✅ All requirements met

Summary: [brief summary of work]
```

### Step 4b: If Verification FAILS

Use **Linear MCP** to:

1. Keep status: **In Progress**
2. Add label: **blocked**
3. Remove label: **verification**
4. Add failure comment:

```markdown
## ❌ Verification Failed

### Issues Found

**Critical Issues**:
1. [Issue 1 description]
2. [Issue 2 description]

**Non-Critical Issues**:
1. [Issue 3 description]
2. [Issue 4 description]

### Required Actions

- [ ] **Action 1**: [What needs to be fixed]
- [ ] **Action 2**: [What needs to be fixed]
- [ ] **Action 3**: [What needs to be fixed]

### Recommendations
- [Recommendation 1]
- [Recommendation 2]

---

**Next Steps**: Fix the issues above, then run quality checks and verification again.
```

Display failure message:
```
❌ Verification Failed for $1

Issues found:
[List critical issues]

Next steps:
1. Fix the issues listed above
2. Run: /fix $1
3. After fixes: /check $1
4. Then: /verify $1 again
```

## Post-Verification

### If Passed
- Task is complete ✅
- Can move to next task
- Consider creating PR if not done

### If Failed
- Run `/fix $1` to start fixing issues
- Address all critical issues first
- Re-run quality checks after fixes
- Re-run verification

## Verification Standards

The verification-agent should check:

**Functionality**:
- All acceptance criteria met
- Edge cases handled
- Error scenarios covered

**Code Quality**:
- Follows project patterns
- Readable and maintainable
- Properly documented
- No code smells

**Testing**:
- Comprehensive test coverage
- All tests passing
- No flaky tests

**Security**:
- No vulnerabilities introduced
- Input validation present
- Authorization checks in place

**Performance**:
- No performance regressions
- Efficient algorithms used
- Database queries optimized

## Notes

- Verification is the final gate before completion
- All issues must be addressed
- Critical issues block completion
- Non-critical issues can be documented as follow-ups
- Be thorough - this ensures production-ready code