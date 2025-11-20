---
name: ccpm-code-review
description: Enforces quality verification gates with four-step validation (tests pass, build succeeds, checklist complete, no blockers) before task completion, PR creation, or status updates. Auto-activates when user says "done", "complete", "finished", "ready to merge", or runs /ccpm:verification:verify or /ccpm:complete:finalize commands. Provides systematic verification workflow that prevents false completion claims and ensures production readiness. Blocks external system writes (Jira, Slack) until evidence collected. Integrates with external-system-safety for confirmation workflow. When verification fails, suggests /ccpm:verification:fix to debug issues systematically.
allowed-tools: read-file, grep, bash
---

# CCPM Code Review

Structured code review workflow integrated with CCPM's Linear-based project management system. Enforces "no completion claims without verification evidence" principle.

## When to Use

This skill auto-activates when:

- User says **"done"**, **"complete"**, **"finished"**, **"ready to merge"**
- Running **`/ccpm:verification:verify`** command
- Running **`/ccpm:complete:finalize`** command
- Before updating Linear task status to "Done"
- Before syncing Jira status
- Before creating BitBucket PR
- Before sending Slack completion notifications

## Core Principles

### 1. Technical Correctness Over Social Comfort

**Forbidden performative agreement:**
- ❌ "Great point!"
- ❌ "You're absolutely right!"
- ❌ "That makes total sense!"

**Required rigorous verification:**
- ✅ "Let me verify that assumption"
- ✅ "I'll test this approach first"
- ✅ "Here's the evidence: [test output]"

### 2. No Implementation Before Verification

When receiving feedback:
1. **First**: Verify the feedback is technically correct
2. **Then**: Implement the change
3. **Never**: Blindly implement without understanding

### 3. NO COMPLETION CLAIMS WITHOUT EVIDENCE

**Required evidence before any "done" claim:**
- ✅ Tests: All passing (screenshot or CI link)
- ✅ Build: Exit status 0 (no errors)
- ✅ Linear checklist: 100% complete
- ✅ No unresolved blockers in Linear comments

## Integration with CCPM Commands

### Before `/ccpm:complete:finalize`

**This skill blocks completion workflow until verified:**

```
User: "I'm done with AUTH-123, let's finalize"

Claude: [ccpm-code-review activates]

⚠️ VERIFICATION REQUIRED BEFORE COMPLETION

I cannot run /ccpm:complete:finalize until verification evidence exists.

Required steps:
1. /ccpm:verification:check AUTH-123
   → Run tests, linting, build
   → Show me the output

2. /ccpm:verification:verify AUTH-123
   → Code review
   → Security audit
   → Final sign-off

Only after BOTH pass can we:
3. /ccpm:complete:finalize AUTH-123
   → Create BitBucket PR
   → Update Jira status (with confirmation)
   → Send Slack notification (with confirmation)

Shall I start with verification checks?
```

### During `/ccpm:verification:verify`

**This skill enforces verification checklist:**

```
Claude runs /ccpm:verification:verify AUTH-123

[ccpm-code-review activates during verification]

Checking verification evidence:

□ Tests passing?
  → Running test suite...
  → ✅ All 47 tests passed

□ Build successful?
  → Running build...
  → ✅ Build completed with exit code 0

□ Linear checklist complete?
  → Fetching AUTH-123...
  → ❌ 3 of 5 items checked

□ No blockers?
  → Checking Linear comments...
  → ⚠️ 1 blocker found: "Redis connection failing in staging"

VERIFICATION FAILED:
- Linear checklist incomplete (3/5)
- Blocker unresolved: Redis connection issue

Cannot proceed with completion until:
1. Complete remaining checklist items
2. Resolve Redis blocker or document as out-of-scope

Would you like to:
A. Update checklist now
B. Investigate Redis blocker
C. Update task scope to exclude Redis
```

### When Creating BitBucket PR

**This skill ensures PR quality:**

```
User: "/ccpm:complete:finalize AUTH-789"

Claude: [ccpm-code-review + external-system-safety activate]

Step 1: Verification check
✅ Tests passing (52/52)
✅ Build successful
✅ Linear checklist complete (7/7)
✅ No blockers

Step 2: PR creation (external write detected)
⚠️ EXTERNAL SYSTEM WRITE - BitBucket PR

I will create PR with:
---
Title: "Implement JWT authentication for API endpoints"
Description: [Generated from Linear task + commits]
Reviewers: @tech-lead, @security-team
Link to: Linear AUTH-789, Jira PROJ-456
---

Proceed with PR creation? (yes/no)

[After user confirms "yes"]

✅ Created PR #234 on BitBucket
Link: https://bitbucket.org/company/repo/pull-requests/234

Step 3: Jira sync
[external-system-safety activates again for Jira update]

Step 4: Slack notification
[external-system-safety activates again for Slack post]
```

## Receiving Feedback Protocol

### When PR Reviewer Comments

**Scenario**: Reviewer says "Add error handling to login function"

**❌ Wrong approach** (performative):
```
"Great point! I'll add error handling right away."
[Immediately adds try-catch without understanding]
```

**✅ Correct approach** (verification-first):
```
Claude: [ccpm-code-review activates]

Let me verify this feedback:

1. Checking current error handling...
   ```typescript
   // login.ts
   async function login(email, password) {
     const user = await db.findUser(email);  // ← No error handling
     return generateToken(user);             // ← No error handling
   }
   ```

2. Potential issues:
   - Database query could fail (network, timeout)
   - user might be null (not found)
   - generateToken could throw (invalid data)

3. Verification: Feedback is VALID
   - Missing error handling confirmed
   - Could cause uncaught exceptions

4. Implementation approach:
   ```typescript
   async function login(email, password) {
     try {
       const user = await db.findUser(email);
       if (!user) {
         throw new UnauthorizedError('Invalid credentials');
       }
       return generateToken(user);
     } catch (error) {
       if (error instanceof DatabaseError) {
         logger.error('Database error during login', error);
         throw new ServiceUnavailableError();
       }
       throw error;
     }
   }
   ```

5. Testing the fix:
   - Add test: login with network error → returns 503
   - Add test: login with invalid user → returns 401
   - Verify existing tests still pass

6. Update Linear:
   - Add comment: "PR feedback: Added error handling"
   - Link to new commit

Implementing fix now...
```

### When Feedback Seems Wrong

**Scenario**: Reviewer says "Use var instead of const"

**❌ Wrong approach**:
```
"Okay, I'll change it!"
[Blindly makes change]
```

**✅ Correct approach**:
```
Claude: [ccpm-code-review activates]

Let me verify this feedback:

1. Current code uses `const` (ES6+)
2. Feedback suggests `var` (ES5)

3. Technical analysis:
   - `const`: Block-scoped, immutable binding, prevents reassignment bugs
   - `var`: Function-scoped, allows reassignment, hoisting issues

4. Project standards check:
   - .eslintrc: Enforces `const`/`let`, disallows `var`
   - Existing codebase: 100% uses `const`/`let`

5. Verification: Feedback appears INCORRECT
   - Contradicts project standards
   - Would cause linting failures
   - Downgrades code quality

6. Response to reviewer:
   "I checked our ESLint config and existing codebase. We enforce `const`/`let`
   and disallow `var` for block-scoping safety. Changing to `var` would:
   - Fail CI linting
   - Contradict project standards
   - Introduce potential hoisting bugs

   Did you mean something else, or is there a specific reason for `var` here?"

Waiting for reviewer clarification before making changes...
```

## Verification Gates

### Gate 1: Tests Must Pass

**Requirement**: Zero test failures

```
✅ PASS: 52 tests, 0 failures
❌ FAIL: 48 tests passed, 4 failures

If failures exist:
1. Run /ccpm:verification:fix to debug
2. Update Linear with findings
3. Re-run verification after fixes
4. Only proceed when 0 failures
```

### Gate 2: Build Must Succeed

**Requirement**: Exit status 0

```
✅ PASS: Build completed successfully (exit 0)
❌ FAIL: Build failed with 3 TypeScript errors (exit 1)

If build fails:
1. Review error messages
2. Fix compilation errors
3. Re-run build
4. Only proceed when exit 0
```

### Gate 3: Linear Checklist Must Be Complete

**Requirement**: 100% of checklist items checked

```
✅ PASS: 7/7 checklist items complete
❌ FAIL: 5/7 checklist items complete

Incomplete items:
- [ ] Add integration tests
- [ ] Update API documentation

Action required:
1. Complete remaining items, OR
2. Update task scope (with /ccpm:planning:update)
3. Mark items as out-of-scope explicitly
4. Only proceed when justified
```

### Gate 4: No Unresolved Blockers

**Requirement**: Zero blocker comments in Linear

```
✅ PASS: No blockers found
❌ FAIL: 2 blockers in Linear comments

Blockers:
1. "Database migration failing in staging"
2. "Awaiting security team approval"

Action required:
1. Resolve each blocker, OR
2. Document why blocker doesn't apply
3. Get explicit approval to proceed despite blocker
4. Only proceed when all blockers addressed
```

## Integration with CCPM Safety Rules

### Works with `external-system-safety` Skill

This skill focuses on **verification**, `external-system-safety` focuses on **confirmation**.

**Division of responsibility:**

| Concern | Skill | Check |
|---------|-------|-------|
| Are tests passing? | ccpm-code-review | ✓ |
| Is build successful? | ccpm-code-review | ✓ |
| Is checklist complete? | ccpm-code-review | ✓ |
| User confirms Jira update? | external-system-safety | ✓ |
| User confirms Slack post? | external-system-safety | ✓ |

**Together they ensure**:
1. Quality standards met (ccpm-code-review)
2. User approves external writes (external-system-safety)

### References SAFETY_RULES.md

All external writes follow `../commands/SAFETY_RULES.md`:

**⛔ Require confirmation**:
- Jira status updates
- Confluence page edits
- BitBucket PR creation
- Slack notifications

**✅ Always allowed**:
- Linear status updates (internal tracking)
- Local file modifications
- Read operations

## Examples

### Example 1: Successful Completion Flow

```
User: "Done with AUTH-123, ready to ship!"

Claude: [ccpm-code-review activates]

Let me verify before proceeding:

1. Running /ccpm:verification:check AUTH-123...
   ✅ Tests: 52/52 passing
   ✅ Build: Successful (exit 0)
   ✅ Linting: No errors

2. Checking Linear checklist...
   ✅ All 7 items complete

3. Checking for blockers...
   ✅ No blockers found

4. Running /ccpm:verification:verify AUTH-123...
   ✅ Code review: Passed
   ✅ Security audit: Passed
   ✅ Final sign-off: Approved

VERIFICATION COMPLETE ✅

Now ready for /ccpm:complete:finalize AUTH-123:
1. Create BitBucket PR
2. Update Jira status (will ask confirmation)
3. Send Slack notification (will ask confirmation)

Proceed with finalization? (yes/no)
```

### Example 2: Failed Verification

```
User: "I'm done, let's merge"

Claude: [ccpm-code-review activates]

Let me verify:

1. Running tests...
   ❌ 3 tests failing:
   - test/auth/login.test.ts: "should handle invalid credentials"
   - test/auth/jwt.test.ts: "should refresh expired tokens"
   - test/api/protected.test.ts: "should reject missing tokens"

2. Running build...
   ❌ TypeScript error:
   src/auth/jwt.ts:45:12 - error TS2345: Argument of type 'string | undefined' is not assignable to parameter of type 'string'

VERIFICATION FAILED ❌

Cannot proceed with completion until:
1. Fix 3 failing tests
2. Fix TypeScript compilation error

Would you like me to run /ccpm:verification:fix to debug these issues?
```

### Example 3: Incomplete Checklist

```
User: "/ccpm:complete:finalize AUTH-456"

Claude: [ccpm-code-review activates]

Checking verification gates:

✅ Tests passing (41/41)
✅ Build successful
❌ Linear checklist incomplete (4/6):
   ✓ Implement JWT generation
   ✓ Add login endpoint
   ✓ Add logout endpoint
   ✓ Write unit tests
   ✗ Add integration tests
   ✗ Update API documentation

CANNOT FINALIZE: Checklist incomplete

Options:
A. Complete remaining items (integration tests + docs)
B. Update scope with /ccpm:planning:update to mark items as Phase 2
C. Explain why items are not needed

Which would you like to do?
```

## Verification Checklist Template

Before claiming "done":

- [ ] Tests executed
  - [ ] All tests passing (0 failures)
  - [ ] Coverage meets requirements
  - [ ] New tests added for new code

- [ ] Build verified
  - [ ] Build successful (exit 0)
  - [ ] No compilation errors
  - [ ] No linting errors

- [ ] Linear task complete
  - [ ] All checklist items checked
  - [ ] No unresolved blockers
  - [ ] Work summary added

- [ ] Code quality
  - [ ] Code reviewed (by human or code-reviewer agent)
  - [ ] Security checked (if applicable)
  - [ ] Performance acceptable

- [ ] Documentation
  - [ ] Code comments added where needed
  - [ ] API docs updated (if API changed)
  - [ ] README updated (if user-facing)

Only after ALL checked:
- [ ] Ready for /ccpm:complete:finalize

## Integration with Other CCPM Skills

**Works alongside**:

- **external-system-safety**: Enforces confirmation for external writes
- **pm-workflow-guide**: Suggests verification commands at right time
- **ccpm-debugging**: If verification fails, helps debug issues
- **sequential-thinking**: For complex verification scenarios

**Example combined activation**:
```
User: "Ready to merge AUTH-123"
       ↓
ccpm-code-review → Enforces verification gates
       ↓
[If gates pass]
       ↓
external-system-safety → Confirms PR/Jira/Slack writes
       ↓
[If user confirms]
       ↓
Complete! ✅
```

## Summary

This skill ensures:

- ✅ No false completion claims
- ✅ Evidence required before "done"
- ✅ Quality gates enforced
- ✅ Technical rigor over social comfort
- ✅ Integration with CCPM workflows

**Philosophy**: Verification before completion, evidence over claims, quality over speed.

---

**Source**: Adapted from [claudekit-skills/code-review](https://github.com/mrgoonie/claudekit-skills)
**License**: MIT
**CCPM Integration**: `/ccpm:verification:verify`, `/ccpm:complete:finalize`, quality-gate hook
