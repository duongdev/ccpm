---
description: Fix verification failures by identifying issues and invoking relevant agents
allowed-tools: [Bash, LinearMCP]
argument-hint: <linear-issue-id>
---

# Fixing Verification Failures: $1

Addressing issues found during verification.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Fix Workflow

### Step 1: Fetch Failure Details

Use **Linear MCP** to get issue: $1

Find the verification failure comment and extract:

- ❌ Critical issues
- ⚠️ Non-critical issues
- 📋 Required actions
- 💡 Recommendations

Display:

```
📋 Issues to Fix:

Critical:
1. [Issue 1]
2. [Issue 2]

Non-Critical:
3. [Issue 3]
4. [Issue 4]
```

### Step 2: Analyze and Map to Agents

For each issue, determine:

1. **What** is the problem
2. **Where** in the code it exists
3. **Which agent** should fix it
4. **Priority** (critical first)

Create fix plan:

```
🔧 Fix Plan:

Priority 1 (Critical):
- Issue 1 → backend-agent
  Files: src/api/auth.ts
  Problem: JWT validation not handling expired tokens

- Issue 2 → frontend-agent
  Files: src/components/Login.tsx
  Problem: Missing error state handling

Priority 2 (Non-Critical):
- Issue 3 → integration-agent
  Files: src/services/payment.ts
  Problem: Retry logic could be improved

- Issue 4 → devops-agent
  Files: .github/workflows/deploy.yml
  Problem: Missing environment validation
```

### Step 3: Invoke Agents to Fix Issues

For each issue (in priority order):

**Invoke the assigned agent** with:

**Context**:

```
Task: $1
Issue to fix: [specific issue description]
Files affected: [list of files]
Current behavior: [what's wrong]
Expected behavior: [what should happen]
Related code: [relevant code context]
```

**Requirements**:

- Fix the specific issue
- Ensure no new issues introduced
- Follow project patterns
- Add/update tests if needed
- Verify fix works

**Example invocation**:

```
Invoke backend-agent to fix JWT validation issue:

Context:
- Task: $1
- Issue: JWT validation not handling expired tokens properly
- File: src/api/auth.ts
- Problem: Expired tokens returning 500 instead of 401
- Expected: Return 401 Unauthorized for expired tokens

Requirements:
- Add proper expiration checking
- Return correct HTTP status
- Add error message
- Update tests to cover this case
- Ensure no security issues

Success Criteria:
- Expired tokens return 401
- Error message is clear
- Tests pass
- No regressions
```

### Step 4: Update Progress

After each issue is fixed, use:

```
/update $1 <subtask-index> completed "Fixed: [issue description]"
```

Or add comments to Linear manually:

```markdown
## 🔧 Fix Progress

### Completed:

- ✅ Issue 1: Fixed JWT validation - now returns 401 for expired tokens
- ✅ Issue 2: Added error state handling in Login component

### In Progress:

- ⏳ Issue 3: Improving retry logic in payment service

### Todo:

- [ ] Issue 4: Add environment validation to deployment
```

### Step 5: Update Linear Status

Use **Linear MCP** to:

1. Remove label: **blocked**
2. Keep status: **In Progress**
3. Add comment:

```markdown
## 🔧 Fixing Verification Issues

### Issues Being Addressed

1. [Issue 1] → Assigned to: backend-agent ✅ FIXED
2. [Issue 2] → Assigned to: frontend-agent ✅ FIXED
3. [Issue 3] → Assigned to: integration-agent ⏳ IN PROGRESS
4. [Issue 4] → Assigned to: devops-agent

### Progress

- ✅ Critical issues: [X/Y] fixed
- ⏳ Non-critical issues: [M/N] fixed

---

Will run quality checks and re-verify once all fixes complete.
```

### Step 6: Coordinate Parallel Fixes

If multiple agents can work in parallel:

- Invoke them simultaneously
- Track progress for each
- Wait for all to complete before proceeding

### Step 7: After All Fixes Complete

Display summary:

```
✅ All Issues Fixed!

Critical Issues Resolved:
- ✅ Issue 1: [brief description]
- ✅ Issue 2: [brief description]

Non-Critical Issues Resolved:
- ✅ Issue 3: [brief description]
- ✅ Issue 4: [brief description]

🔍 Next Steps:
1. Run: /check $1  (quality checks)
2. Then: /verify $1  (re-verification)
```

## Agent Selection Guide

**backend-agent**:

- API issues
- Database problems
- Authentication/authorization bugs
- Server-side logic errors

**frontend-agent**:

- UI bugs
- Component issues
- State management problems
- Client-side logic errors

**mobile-agent**:

- React Native issues
- Platform-specific bugs
- Mobile UI problems

**integration-agent**:

- API integration issues
- Third-party service problems
- Data sync errors

**devops-agent**:

- CI/CD issues
- Deployment problems
- Infrastructure errors
- Environment configuration

**database-agent**:

- Schema issues
- Query problems
- Migration errors
- Performance issues

## Best Practices

1. **Fix critical issues first** - They block completion
2. **One agent per issue** - Don't mix responsibilities
3. **Provide full context** - Help agents understand the problem
4. **Test after each fix** - Ensure fix works
5. **Update Linear frequently** - Keep progress visible
6. **Parallel when possible** - Speed up fixes
7. **Re-verify after all fixes** - Ensure everything works

## After Fixing

Once all issues are fixed:

```bash
# Run quality checks
/check $1

# If checks pass, re-verify
/verify $1

# Should pass this time! 🎉
```

## Notes

- Don't skip non-critical issues - fix them all
- Each fix should have tests
- Verify no regressions introduced
- Update documentation if needed
- Keep fixes focused and minimal
