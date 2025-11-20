---
description: Verify completed work with verification agent - final review before completion
allowed-tools: [Bash, LinearMCP]
argument-hint: <linear-issue-id>
---

# Verifying Task: $1

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

**READ**: `commands/_shared-linear-helpers.md`

Use **Linear MCP** to update issue status and labels:

```javascript
try {
  // Get team ID from issue
  const teamId = issue.team.id;

  // Get valid "Done" state ID
  const doneStateId = await getValidStateId(teamId, "Done");

  // Get current labels
  const currentLabels = issue.labels || [];
  const currentLabelIds = currentLabels.map(l => l.id);

  // Find labels to remove
  const verificationLabel = currentLabels.find(l =>
    l.name.toLowerCase() === "verification"
  );
  const blockedLabel = currentLabels.find(l =>
    l.name.toLowerCase() === "blocked"
  );

  // Build new label list: remove verification and blocked
  let newLabelIds = currentLabelIds.filter(id =>
    id !== verificationLabel?.id && id !== blockedLabel?.id
  );

  // Update issue with Done status and cleaned labels
  await mcp__agent-mcp-gateway__execute_tool({
    server: "linear",
    tool: "update_issue",
    args: {
      id: issue.id,
      stateId: doneStateId,
      labelIds: newLabelIds
    }
  });

  console.log("✅ Linear issue updated:");
  console.log("   Status: Done");
  console.log("   Labels: verification and blocked removed");

} catch (error) {
  console.error("⚠️ Failed to update Linear issue:", error.message);
  console.warn("⚠️ Task is verified but status may not be updated in Linear.");
  console.log("   You can manually update status to Done if needed.");
}
```

**Add completion comment**:

```javascript
const commentBody = `## ✅ Verification Complete - Task Done!

### Verification Results
✅ All requirements met
✅ All tests passing (${testResults.passed}/${testResults.total} tests)
✅ No regressions detected
✅ Code quality standards met
✅ Security best practices followed
✅ Performance acceptable

### Implementation Summary
${verificationReport.summary}

### Changes Made
**Files Modified**:
${verificationReport.filesModified.map(f => `- ${f.path} - ${f.description}`).join('\n')}

**Key Features Implemented**:
${verificationReport.features.map(f => `- ${f}`).join('\n')}

### Test Coverage
- Unit tests: ${testResults.unit} added/updated
- Integration tests: ${testResults.integration} added/updated
- All tests passing: ✅

### Related Links
- Linear: ${issue.url}
${jiraLink ? `- Jira: ${jiraLink}` : ''}
${prLink ? `- Pull request: ${prLink}` : ''}

---

**Task completed successfully!** 🎉
`;

try {
  await mcp__agent-mcp-gateway__execute_tool({
    server: "linear",
    tool: "create_comment",
    args: {
      issueId: issue.id,
      body: commentBody
    }
  });

  console.log("✅ Verification results added to Linear comments");
} catch (error) {
  console.error("⚠️ Failed to add comment:", error.message);
  // Not critical, continue
}
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

**READ**: `commands/_shared-linear-helpers.md`

Use **Linear MCP** to update issue and add blocker:

```javascript
try {
  // Get team ID from issue
  const teamId = issue.team.id;

  // Get or create "blocked" label
  const blockedLabel = await getOrCreateLabel(teamId, "blocked", {
    color: "#eb5757",
    description: "CCPM: Task blocked, needs resolution"
  });

  // Get current labels
  const currentLabels = issue.labels || [];
  const currentLabelIds = currentLabels.map(l => l.id);

  // Find verification label to remove
  const verificationLabel = currentLabels.find(l =>
    l.name.toLowerCase() === "verification"
  );

  // Build new label list: remove verification, add blocked
  let newLabelIds = currentLabelIds.filter(id =>
    id !== verificationLabel?.id
  );

  // Add blocked label if not already present
  if (!currentLabels.some(l => l.name.toLowerCase() === "blocked")) {
    newLabelIds.push(blockedLabel.id);
  }

  // Keep status as "In Progress" - don't change it
  // Just update labels
  await mcp__agent-mcp-gateway__execute_tool({
    server: "linear",
    tool: "update_issue",
    args: {
      id: issue.id,
      labelIds: newLabelIds
    }
  });

  console.log("✅ Linear issue updated:");
  console.log("   Status: In Progress (unchanged)");
  console.log("   Labels: blocked added, verification removed");

} catch (error) {
  console.error("⚠️ Failed to update Linear issue:", error.message);
  console.warn("⚠️ Verification failed but status may not be updated.");
  console.log("   Please manually add 'blocked' label if needed.");
}
```

**Add failure comment**:
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