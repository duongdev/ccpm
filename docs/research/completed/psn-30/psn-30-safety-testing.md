# PSN-30 Safety Testing: External System Confirmation Flows

**Version:** 1.0
**Date:** 2025-11-20
**Purpose:** Validate that all optimized commands properly implement safety confirmation workflows for external PM systems

---

## Overview

This document defines test scenarios for verifying that CCPM commands follow SAFETY_RULES.md when interacting with external project management systems. The goal is to ensure that:

1. Linear operations proceed without confirmation (internal tracking)
2. GitHub operations proceed without confirmation (code hosting)
3. External PM writes (Jira, Confluence, Slack, BitBucket) require explicit user confirmation
4. All confirmation prompts show exact content before posting
5. Users can opt out of external writes

---

## Safety Rules Summary

From `commands/SAFETY_RULES.md`:

### Prohibited Without Confirmation
- **Jira**: Issues, comments, attachments, status changes
- **Confluence**: Pages, comments, edits
- **BitBucket**: Pull requests, comments (beyond viewing)
- **Slack**: Messages, posts, reactions

### Allowed Without Confirmation
- **Read operations**: Fetching, searching, viewing from all systems
- **Linear operations**: Create/update issues, add comments, change status
- **GitHub operations**: PR creation (code hosting)
- **Local operations**: File changes, git commits

---

## Test Scenarios

### Scenario 1: `/ccpm:done` - Full Finalization Flow

**Command:** `/ccpm:done PSN-30`

**Expected Behavior:**

1. **Pre-flight checks** (no confirmation needed):
   - ✅ Verify not on main/master branch
   - ✅ Check for uncommitted changes
   - ✅ Verify branch pushed to remote

2. **Fetch issue from Linear** (no confirmation needed):
   - ✅ Use Linear subagent to get issue details
   - ✅ Parse checklist from description
   - ✅ Verify checklist completion (100% required)

3. **Create GitHub PR** (no confirmation needed):
   - ✅ Generate PR title from issue title
   - ✅ Generate PR body with issue details and checklist
   - ✅ Execute: `gh pr create --title "..." --body "..."`
   - ✅ Display PR URL

4. **Prompt for Jira update** (confirmation required):
   ```
   🚨 CONFIRMATION REQUIRED

   I will update Jira ticket TRAIN-123 to status "Done" with comment:

   ---
   Completed in Linear: PSN-30
   PR: https://github.com/org/repo/pull/42
   ---

   Proceed? (Type "yes" to confirm)
   ```

   **User response options:**
   - "yes" / "confirm" / "go ahead" → Proceed with Jira update
   - "no" / "skip" / any other → Skip Jira update

   **If user confirms:**
   - ✅ Update Jira status to "Done"
   - ✅ Add comment with Linear and PR links
   - ✅ Display success message

5. **Prompt for Slack notification** (confirmation required):
   ```
   🚨 CONFIRMATION REQUIRED

   I will post to #engineering Slack channel:

   ---
   ✅ PSN-30: Add user authentication is complete!
   Linear: https://linear.app/team/issue/PSN-30
   PR: https://github.com/org/repo/pull/42
   ---

   Proceed? (Type "yes" to confirm)
   ```

   **User response options:**
   - "yes" / "confirm" / "go ahead" → Proceed with Slack post
   - "no" / "skip" / any other → Skip Slack notification

6. **Update Linear status** (no confirmation needed):
   - ✅ Update issue state to "Done"
   - ✅ Add "done" label
   - ✅ Create Linear comment with completion summary
   - ✅ Display final summary

**Validation Criteria:**
- ✅ No auto-posting to Jira without user confirmation
- ✅ No auto-posting to Slack without user confirmation
- ✅ Exact content shown before posting
- ✅ User can skip external updates
- ✅ Linear updates happen automatically
- ✅ GitHub PR created automatically

---

### Scenario 2: `/ccpm:planning:plan` - Planning with Jira/Confluence Research

**Command:** `/ccpm:planning:plan PSN-30 TRAIN-456`

**Expected Behavior:**

1. **Fetch Jira ticket** (read-only, no confirmation):
   - ✅ Fetch ticket details from Jira
   - ✅ Parse requirements, acceptance criteria
   - ✅ Extract links to Confluence pages

2. **Fetch Confluence documentation** (read-only, no confirmation):
   - ✅ Search Confluence for related documentation
   - ✅ Fetch linked pages from Jira ticket
   - ✅ Extract technical specifications

3. **Create/update Linear issue** (no confirmation):
   - ✅ Create Linear issue if not exists
   - ✅ Update issue description with planning details
   - ✅ Add implementation checklist
   - ✅ Set status to "Planning"
   - ✅ Add "planning" label

4. **NO prompt to update Jira** (should not happen):
   - ❌ Command should NOT offer to update Jira
   - ❌ Command should NOT post planning notes to Jira
   - ✅ All planning stored in Linear only

5. **Display planning summary**:
   - ✅ Show Linear issue URL
   - ✅ Show implementation checklist
   - ✅ Suggest next actions

**Validation Criteria:**
- ✅ Reads from Jira/Confluence without confirmation
- ✅ Does not write back to Jira/Confluence
- ✅ All planning stored in Linear only
- ✅ No external system confirmation prompts

---

### Scenario 3: `/ccpm:implementation:sync` - Progress Sync

**Command:** `/ccpm:sync PSN-30 "Implemented authentication endpoints"`

**Expected Behavior:**

1. **Fetch current issue** (no confirmation):
   - ✅ Get issue details from Linear
   - ✅ Show current status and progress

2. **Update Linear issue** (no confirmation):
   - ✅ Add comment with progress update
   - ✅ Update progress percentage
   - ✅ Display confirmation

3. **NO prompts for external systems**:
   - ❌ Command should NOT offer to update Jira
   - ❌ Command should NOT post to Slack
   - ✅ Progress tracked in Linear only

**Validation Criteria:**
- ✅ Linear updates happen automatically
- ✅ No external system prompts
- ✅ Fast operation (no user interruption)

---

### Scenario 4: `/ccpm:verification:verify` - Quality Checks and Verification

**Command:** `/ccpm:verify PSN-30`

**Expected Behavior:**

1. **Fetch issue and run checks** (no confirmation):
   - ✅ Get issue from Linear
   - ✅ Run linting, tests, build
   - ✅ Run code review agent
   - ✅ Display results

2. **Update Linear based on results** (no confirmation):
   - ✅ Update issue status to "Done" (if passed)
   - ✅ Add "verified" label (if passed)
   - ✅ Add verification comment with results
   - ✅ OR add "blocked" label (if failed)

3. **NO prompts for external systems**:
   - ❌ Command should NOT update Jira status
   - ❌ Command should NOT post to Slack
   - ✅ Verification results stored in Linear only

**Validation Criteria:**
- ✅ Verification runs without interruption
- ✅ Linear updated automatically
- ✅ No external system prompts
- ✅ Results tracked in Linear comments

---

### Scenario 5: `/ccpm:work` - Start or Resume Work

**Command:** `/ccpm:work PSN-30`

**Expected Behavior (START mode):**

1. **Fetch issue** (no confirmation):
   - ✅ Get issue from Linear
   - ✅ Determine mode (START vs RESUME)

2. **Update Linear status** (no confirmation):
   - ✅ Change status to "In Progress"
   - ✅ Add "implementation" label
   - ✅ Add implementation plan comment

3. **NO external prompts**:
   - ❌ Should NOT update Jira status
   - ❌ Should NOT notify Slack
   - ✅ Work starts immediately in Linear

**Expected Behavior (RESUME mode):**

1. **Fetch issue and display progress** (no confirmation):
   - ✅ Get issue from Linear
   - ✅ Calculate progress from checklist
   - ✅ Display next actions

2. **NO updates or prompts**:
   - ❌ No status changes
   - ❌ No external system updates
   - ✅ Read-only display of progress

**Validation Criteria:**
- ✅ START mode updates Linear automatically
- ✅ RESUME mode is read-only
- ✅ No external system prompts in either mode

---

### Scenario 6: `/ccpm:commit` - Git Commit with Linear Link

**Command:** `/ccpm:commit PSN-30 "feat: add JWT authentication"`

**Expected Behavior:**

1. **Create git commit** (no confirmation):
   - ✅ Stage changes
   - ✅ Create commit with conventional format
   - ✅ Include Linear issue ID in commit message
   - ✅ Display commit hash

2. **Add Linear comment** (no confirmation):
   - ✅ Add comment to Linear issue with commit details
   - ✅ Include commit hash and message

3. **NO external prompts**:
   - ❌ Should NOT update Jira
   - ❌ Should NOT post to Slack
   - ✅ Git commit and Linear update only

**Validation Criteria:**
- ✅ Git commit happens automatically
- ✅ Linear comment added automatically
- ✅ No external system prompts

---

## Edge Cases and Error Scenarios

### Edge Case 1: User Cancels External Update

**Scenario:** User types "no" when prompted for Jira update

**Expected Behavior:**
- ✅ Jira update skipped
- ✅ Command continues with remaining steps
- ✅ Linear updates still happen
- ✅ Final summary shows "Jira: Skipped"

### Edge Case 2: External System API Failure

**Scenario:** Jira API returns error when user confirms update

**Expected Behavior:**
- ✅ Display error message clearly
- ✅ Show exact error from API
- ✅ Linear updates already completed (not rolled back)
- ✅ Suggest manual update to Jira

### Edge Case 3: Ambiguous User Response

**Scenario:** User types "ok" or "sure" instead of "yes"

**Expected Behavior:**
- ⚠️  Treat as confirmation (acceptable)
- ✅ OR prompt again for explicit "yes"
- ✅ Document acceptable confirmation phrases

### Edge Case 4: Multiple External Systems

**Scenario:** `/ccpm:done` with both Jira and Slack configured

**Expected Behavior:**
- ✅ Prompt for Jira update first
- ✅ Wait for user response
- ✅ Then prompt for Slack notification
- ✅ Wait for user response
- ✅ Each system can be confirmed or skipped independently

---

## Testing Checklist

### Pre-Testing Setup

- [ ] Configure CCPM project with Linear integration
- [ ] Configure Jira integration (optional, for testing external writes)
- [ ] Configure Slack integration (optional, for testing external writes)
- [ ] Set up test Linear workspace with test issues
- [ ] Set up test git repository with feature branch

### Core Commands to Test

#### High-Priority (External Write Risk)
- [ ] `/ccpm:done` - Finalization with Jira/Slack sync
- [ ] `/ccpm:complete:finalize` - Same as done, direct implementation

#### Medium-Priority (Should Not Write Externally)
- [ ] `/ccpm:planning:plan` - Planning with Jira/Confluence reads
- [ ] `/ccpm:implementation:sync` - Progress updates
- [ ] `/ccpm:verification:verify` - Quality checks
- [ ] `/ccpm:work` - Start/resume work

#### Low-Priority (Local/Linear Only)
- [ ] `/ccpm:commit` - Git commits
- [ ] `/ccpm:utils:status` - Display status
- [ ] `/ccpm:utils:context` - Load context

### Safety Validation Tests

For each command with external write risk:

1. **Confirmation Prompt Appears**
   - [ ] Prompt displays before any external write
   - [ ] Prompt shows exact content that will be posted
   - [ ] Prompt clearly identifies target system (Jira/Slack/etc)

2. **User Can Accept**
   - [ ] Typing "yes" proceeds with external write
   - [ ] Success message displayed after write
   - [ ] Content matches what was shown in prompt

3. **User Can Decline**
   - [ ] Typing "no" skips external write
   - [ ] Command continues with remaining steps
   - [ ] Final summary shows external write was skipped

4. **Linear Operations Automatic**
   - [ ] Linear updates happen without confirmation
   - [ ] Linear comments added without confirmation
   - [ ] Linear status/labels updated without confirmation

5. **GitHub Operations Automatic**
   - [ ] PR creation happens without confirmation
   - [ ] PR body includes Linear issue details
   - [ ] PR URL displayed after creation

---

## Validation Criteria Summary

### MUST HAVE (Critical)
- ✅ External PM writes require confirmation (Jira, Confluence, Slack)
- ✅ Confirmation shows exact content before posting
- ✅ User can skip external writes
- ✅ Linear operations proceed automatically
- ✅ GitHub operations proceed automatically

### SHOULD HAVE (Important)
- ✅ Clear visual distinction for confirmation prompts (🚨 icon)
- ✅ Multiple confirmation formats accepted ("yes", "confirm", "go ahead")
- ✅ Final summary shows which systems were updated vs skipped
- ✅ Error messages for failed external writes are actionable

### NICE TO HAVE (Enhancement)
- ✅ Ability to set default preferences (always skip Jira, etc.)
- ✅ Dry-run mode to preview all operations
- ✅ Batch confirmation for multiple external writes

---

## Test Execution Log Template

Use this template to record test results:

```markdown
### Test: [Command Name]
**Date:** YYYY-MM-DD
**Tester:** [Name]
**Issue ID:** [Test Issue]

#### Setup
- Linear workspace: [workspace-name]
- Jira project: [project-key] (if applicable)
- Slack channel: [#channel] (if applicable)

#### Execution Steps
1. [Step 1 description]
   - Expected: [expected behavior]
   - Actual: [actual behavior]
   - Status: ✅ PASS / ❌ FAIL

2. [Step 2 description]
   - Expected: [expected behavior]
   - Actual: [actual behavior]
   - Status: ✅ PASS / ❌ FAIL

#### Results
- Overall: ✅ PASS / ❌ FAIL
- Issues Found: [list any issues]
- Notes: [additional observations]
```

---

## Known Issues and Workarounds

### Issue 1: Confirmation Prompt Not Appearing
**Symptom:** Command posts to Jira without confirmation
**Root Cause:** Safety check bypassed or not implemented
**Fix:** Add safety check before MCP tool invocation
**Workaround:** Manually confirm in Jira before running command

### Issue 2: Unclear Confirmation Prompt
**Symptom:** User unsure what will be posted
**Root Cause:** Prompt shows placeholder instead of actual content
**Fix:** Resolve all variables before displaying confirmation
**Workaround:** Review Jira ticket manually before confirming

---

## Future Enhancements

1. **Confirmation History**: Track which external writes user has approved/declined
2. **Default Preferences**: Allow user to set "always skip Jira" or "always notify Slack"
3. **Dry-Run Mode**: Preview all operations without executing
4. **Audit Log**: Record all external writes with timestamps and user confirmation
5. **Batch Confirmation**: Single prompt for multiple related external writes

---

## References

- [SAFETY_RULES.md](../../commands/SAFETY_RULES.md) - Official safety rules
- [done.md](../../commands/done.md) - Implementation of `/ccpm:done` command
- [complete:finalize.md](../../commands/complete:finalize.md) - Direct finalization implementation
- [PSN-30 Architecture](../architecture/psn-30-natural-command-direct-implementation.md) - Command optimization architecture

---

## Approval

**Reviewed by:** [Name]
**Date:** YYYY-MM-DD
**Status:** ✅ Approved / ⏳ Pending / ❌ Needs Revision

---

## Change Log

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-20 | Initial safety testing document | PSN-30 Implementation |
