# UAT Scenario: Complete Feature Development Workflow

## Scenario ID
UAT-001

## Description
End-to-end workflow for developing a new feature using natural workflow commands, from planning through completion.

## Prerequisites
- CCPM plugin installed and configured
- Linear workspace connected
- GitHub repository connected
- Test project exists in Linear
- User has permissions for all operations

## User Story
As a developer, I want to implement a new feature using the complete CCPM workflow, from planning to deployment.

## Test Scenario
Implement a new "User Authentication" feature using natural workflow commands.

## Workflow Steps

### Step 1: Plan the Feature
```bash
/ccpm:plan "Add JWT user authentication" my-app
```

**Expected Results:**
- ✅ New Linear issue created
- ✅ Issue has title "Add JWT user authentication"
- ✅ Labels applied: planning, feature
- ✅ State: Backlog or Todo
- ✅ Implementation checklist generated
- ✅ Context gathered from codebase
- ✅ Interactive menu shown with next actions

**Success Criteria:**
- Issue created in < 10s
- Checklist has 5+ actionable items
- Context includes relevant files from codebase

**Interactive Menu Should Show:**
```
📋 Current Status: Planning Complete
Progress: ██░░░░░░░░ 20%

🎯 Suggested Next Actions:
  ⭐ 1. Start Implementation → /ccpm:work
  2. Update Plan → /ccpm:plan PSN-XX "add changes"
  3. View Full Status → /ccpm:utils:status PSN-XX
```

### Step 2: Start Implementation
```bash
/ccpm:work
```

**Expected Results:**
- ✅ Issue detected from planning step (or git branch)
- ✅ State changed to "In Progress"
- ✅ Implementation checklist displayed
- ✅ Agents suggested for subtasks
- ✅ Work context loaded

**Success Criteria:**
- Auto-detects issue from context
- State transition successful
- Checklist items are actionable
- Agents match subtask requirements

**Interactive Menu Should Show:**
```
📋 Current Status: Implementation In Progress
Progress: ████░░░░░░ 40%

🔨 Implementation Checklist:
  [ ] 1. Create JWT utility functions
  [ ] 2. Implement auth middleware
  [ ] 3. Add login/logout endpoints
  [ ] 4. Write unit tests
  [ ] 5. Update API documentation

🎯 Suggested Next Actions:
  ⭐ 1. Sync Progress → /ccpm:sync "implemented JWT utils"
  2. Update Subtask → /ccpm:implementation:update PSN-XX 1 completed
  3. Next Smart Action → /ccpm:implementation:next PSN-XX
```

### Step 3: TDD Enforcement (Automatic)
**Trigger:** Attempt to edit production code without tests

**Expected Behavior:**
- ⚠️ TDD enforcer hook blocks Write/Edit operations
- 📝 Message: "Tests must be written first (TDD)"
- 🤖 TDD orchestrator agent auto-invoked
- ✅ Failing test generated
- ✅ Test verified to fail for right reason
- ✅ Production code now allowed

**Success Criteria:**
- Hook blocks production code write
- Failing test is valid and meaningful
- Test fails with correct error message
- Production code write succeeds after test

### Step 4: Implement Feature (with sync)
```bash
# After implementing JWT utility functions
/ccpm:sync "Implemented JWT utility functions with tests"
```

**Expected Results:**
- ✅ Git changes detected and summarized
- ✅ Linear issue updated with progress
- ✅ Implementation checklist item updated
- ✅ Progress percentage increased
- ✅ Interactive menu updates

**Success Criteria:**
- Sync completes in < 5s
- Git diff accurately summarized
- Linear comment added
- Progress reflects completion

**Interactive Menu Should Show:**
```
📋 Current Status: Implementation In Progress
Progress: ██████░░░░ 60%

✅ Recently Completed:
  - JWT utility functions

🔨 Next Up:
  [ ] Implement auth middleware
  [ ] Add login/logout endpoints

🎯 Suggested Next Actions:
  ⭐ 1. Continue Implementation
  2. Sync Again → /ccpm:sync "next update"
  3. Commit Changes → /ccpm:commit
```

### Step 5: Commit Changes
```bash
/ccpm:commit
```

**Expected Results:**
- ✅ Git status checked
- ✅ Git diff summarized
- ✅ Conventional commit message generated
- ✅ Commit created and linked to Linear
- ✅ Commit message follows format: "feat(auth): implement JWT utilities"

**Success Criteria:**
- Commit message is descriptive
- Follows conventional commits format
- References Linear issue
- Includes relevant details

### Step 6: Quality Checks (Automatic)
**Trigger:** Implementation complete, ready for verification

**Expected Behavior:**
- 🤖 Code reviewer agent auto-invoked
- 🔍 All changed files analyzed
- 📊 Quality report generated
- ⚠️ Issues flagged (if any)
- ✅ Suggestions provided

**Success Criteria:**
- All files reviewed
- Security issues flagged
- Best practices enforced
- Report is actionable

### Step 7: Verify Implementation
```bash
/ccpm:verify
```

**Expected Results:**
- ✅ Quality checks run
  - IDE warnings resolved
  - Linting passed
  - Tests run and pass
- ✅ Final verification performed
- ✅ Verification report generated
- ✅ No blockers found

**Success Criteria:**
- All tests pass
- No lint errors
- No IDE warnings
- Security audit clean

**Interactive Menu Should Show:**
```
📋 Current Status: Verification Complete
Progress: ██████████ 100%

✅ Verification Results:
  ✓ Quality Checks Passed
  ✓ Tests Passed (42 tests)
  ✓ Linting Passed
  ✓ Security Audit Clean

🎯 Suggested Next Actions:
  ⭐ 1. Finalize & Create PR → /ccpm:done
  2. Fix Any Issues → /ccpm:verification:fix PSN-XX
```

### Step 8: Create PR and Finalize
```bash
/ccpm:done
```

**Expected Results:**
- ✅ Pre-flight safety checks passed
- ✅ Git branch status verified
- ✅ PR created on GitHub
- ✅ PR title and body generated
- ✅ Linear state changed to "In Review" or "Done"
- ✅ Jira status synced (if configured)
- ✅ Slack notification sent (if configured)

**Success Criteria:**
- PR created successfully
- PR body includes summary and test plan
- Linear status updated
- External systems synced
- Team notified

**Interactive Menu Should Show:**
```
📋 Current Status: Complete
Progress: ██████████ 100%

✅ Task Complete:
  - PR Created: #123
  - Linear Status: In Review
  - Jira Synced: PROJ-456
  - Team Notified: #eng-updates

🎉 Feature Development Complete!

Next Steps:
  - Wait for PR review
  - Address review comments
  - Merge and deploy
```

## External System Confirmation

### Step 8.1: External System Writes (Should Require Confirmation)
**Before finalizing**, the system should ask:

```
⚠️ External System Operations Required

The following operations will be performed:

1. Jira (PROJ-456):
   - Update status: "In Progress" → "In Review"
   - Add comment: "Implementation complete. PR: #123"

2. Confluence (Project Docs):
   - Update feature status page
   - Mark "User Auth" as complete

3. Slack (#eng-updates):
   - Post message: "✅ User Authentication feature ready for review"

❓ Proceed with these operations? (yes/no)
```

**User must explicitly confirm** before any external writes.

**Success Criteria:**
- All external operations shown clearly
- User explicitly confirms
- No operations occur without confirmation
- User can cancel if needed

## Validation Checkpoints

### Checkpoint 1: Planning Complete
- [ ] Issue created in Linear
- [ ] Implementation checklist generated
- [ ] Labels and state correct
- [ ] Context gathered from codebase
- [ ] Interactive menu shown

### Checkpoint 2: Implementation Started
- [ ] Issue state changed to "In Progress"
- [ ] Work context loaded
- [ ] Checklist displayed
- [ ] Agents suggested

### Checkpoint 3: TDD Enforced
- [ ] Production code blocked without tests
- [ ] Failing test generated
- [ ] Test verified to fail correctly
- [ ] Production code allowed after test

### Checkpoint 4: Progress Synced
- [ ] Git changes detected
- [ ] Linear updated
- [ ] Checklist items updated
- [ ] Progress percentage accurate

### Checkpoint 5: Quality Verified
- [ ] Code reviewed automatically
- [ ] Tests passed
- [ ] Linting clean
- [ ] Security audit clean

### Checkpoint 6: Finalized
- [ ] PR created
- [ ] Linear status updated
- [ ] External systems synced (with confirmation)
- [ ] Team notified

## Performance Metrics

### Token Usage
- **Target**: < 100,000 tokens for complete workflow
- **Optimized**: ~60,000 tokens (40% reduction)

### Execution Time
- Planning: < 10s
- Work start: < 5s
- Sync: < 5s
- Commit: < 3s
- Verify: < 30s (includes running tests)
- Done: < 15s (includes PR creation)
- **Total**: < 70s for complete workflow

### Cache Performance
- Linear team/project lookups: 95% hit rate
- Label lookups: 92% hit rate
- State lookups: 90% hit rate

## Error Scenarios

### Scenario E1: Planning Fails
**Trigger:** Invalid project ID
**Expected:** Clear error message, suggestions provided

### Scenario E2: TDD Enforcement Fails
**Trigger:** Test generation fails
**Expected:** Graceful fallback, user notified

### Scenario E3: Verification Fails
**Trigger:** Tests fail
**Expected:** Detailed failure report, fix suggestions

### Scenario E4: External System Fails
**Trigger:** Jira API error
**Expected:** Linear updated, external sync skipped with warning

## Success Criteria

### Must Pass
- ✅ All 8 workflow steps complete successfully
- ✅ All 6 validation checkpoints pass
- ✅ Performance metrics within targets
- ✅ External system confirmation works
- ✅ Error handling is graceful

### Nice to Have
- Interactive menus helpful and accurate
- Progress tracking clear and intuitive
- Suggestions are relevant
- Command chaining feels natural

## Test Data Cleanup

After test execution:
- Delete test Linear issue
- Delete test git branch
- Delete test PR (if created)
- Clean up test files
- Remove test labels/projects

## Notes
- This scenario tests the complete "happy path"
- Additional scenarios cover error cases
- External system confirmation is CRITICAL for safety
- TDD enforcement demonstrates hook automation
- Natural workflow commands provide optimal UX

---

**Scenario Version:** 1.0
**Last Updated:** November 21, 2025
**Estimated Duration:** 10-15 minutes
**Automation Level:** Semi-automated (requires manual verification)
