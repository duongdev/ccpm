# Bugfix Plan Template

## Bug Summary
**Title**: {title}
**Type**: Bugfix
**Severity**: {critical|high|medium|low}
**Reported By**: {reporter}
**Environment**: {environment}

## Bug Description
What is happening vs what should happen?

**Actual Behavior**:
{actual_behavior}

**Expected Behavior**:
{expected_behavior}

## Reproduction Steps
1. {step_1}
2. {step_2}
3. {step_3}

## Root Cause Analysis
What is causing this bug?

{root_cause}

## Fix Strategy
How will we fix this?

{fix_strategy}

## Implementation Checklist

### 1. Investigation
- [ ] Reproduce the bug locally
- [ ] Identify root cause
- [ ] Document affected code paths
- [ ] Check for related issues

### 2. Fix Implementation
- [ ] Implement the fix
- [ ] Add regression test
- [ ] Verify fix works locally
- [ ] Check for side effects

### 3. Verification
- [ ] Run all related tests
- [ ] Test edge cases
- [ ] Verify in staging environment
- [ ] Get code review

### 4. Documentation
- [ ] Update relevant docs if needed
- [ ] Add fix notes to changelog
- [ ] Close related issues

## Affected Areas
- Files: {affected_files}
- Features: {affected_features}
- Users: {affected_users}

## Rollback Plan
If the fix causes issues:
{rollback_plan}

## References
- Error logs: {error_logs}
- Screenshots: {screenshots}
- Related issues: {related_issues}
