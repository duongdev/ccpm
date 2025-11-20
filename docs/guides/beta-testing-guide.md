# CCPM v2.3 Beta Testing Guide

**Welcome to the CCPM v2.3 Beta Program!**

---

## What You're Testing

You're part of a select group of 50-100 power users testing **CCPM v2.3**, which includes:

### New Features
- 6 optimized commands (plan, work, sync, commit, verify, done)
- Feature flag system for safe rollout
- Auto-detection from git branches
- Linear subagent optimization
- Monitoring dashboard

### What We're Measuring
- Command execution success rate
- Token reduction (should be 45-60%)
- Error rates and edge cases
- User satisfaction (NPS)
- Feature usage patterns
- Workflow improvements

---

## Your Role as a Beta Tester

### What We Need From You

1. **Use the new commands regularly** (daily or as needed)
   - Try `/ccpm:plan`, `/ccpm:work`, `/ccpm:sync`, `/ccpm:commit`, `/ccpm:verify`, `/ccpm:done`
   - Report what works and what doesn't

2. **Provide honest feedback**
   - What's better than old commands?
   - What could be improved?
   - Any bugs or unexpected behaviors?
   - Suggestions for features?

3. **Report issues** (critical bugs, errors, edge cases)
   - Use feedback form or GitHub Issues
   - Include context and reproduction steps

4. **Complete NPS survey**
   - At end of beta period (Dec 20)
   - Tells us if users love it or not
   - Takes 2 minutes

---

## Testing Timeline

### Week 1: Dec 9-13 (Monday-Friday)

**Daily checklist:**
- [ ] Install v2.3.0-beta.1
- [ ] Try at least one new command
- [ ] Report any issues
- [ ] Respond to daily survey

**Goals:**
- Get familiar with new commands
- Identify critical bugs
- Provide initial feedback

### Week 2: Dec 16-20 (Monday-Friday)

**Daily checklist:**
- [ ] Use new commands in your normal workflow
- [ ] Track token counts vs old commands
- [ ] Report improvements or issues
- [ ] Complete feedback form

**Goals:**
- Test at scale in real workflows
- Measure token reduction
- Find edge cases
- Provide detailed feedback

### Week 3: Dec 21+ (Preparation for Early Access)

- Your testing inputs inform the Early Access rollout
- v2.3.0-rc.1 is released with improvements
- You're invited to continue testing if interested

---

## How to Test

### Step 1: Install v2.3.0-beta.1

In Claude Code:

```bash
/plugin update ccpm
```

Or:

```bash
/plugin remove ccpm
/plugin install ccpm@2.3.0-beta.1
```

---

### Step 2: Verify Installation

```bash
/ccpm:config feature-flags --show
```

Expected output:
```
Feature Flags Status:
├─ optimized_workflow_commands: enabled
├─ linear_subagent_enabled: enabled
├─ auto_detect_from_branch: enabled
├─ shared_linear_helpers: enabled
├─ legacy_command_support: enabled
└─ monitoring_collection: enabled
```

---

### Step 3: Test Each New Command

#### Test 1: Planning
```bash
/ccpm:plan "Add feature X" my-app
```

**What to check:**
- [ ] Task created successfully
- [ ] Plan generated correctly
- [ ] No errors
- [ ] Token count shown (should be ~50% less than old way)

**Questions to answer:**
- Was task created correctly?
- Was plan thorough?
- Any missing information?

#### Test 2: Start Work
```bash
# Create feature branch first
git checkout -b feature/ISSUE-123-my-feature

# Then start work
/ccpm:work
```

**What to check:**
- [ ] Auto-detected issue ID correctly
- [ ] Showed work instructions
- [ ] Suggested next steps
- [ ] No errors

**Questions to answer:**
- Did auto-detection work?
- Was guidance helpful?

#### Test 3: Save Progress
```bash
/ccpm:sync "Implemented feature X component"
```

**What to check:**
- [ ] Auto-detected issue ID correctly
- [ ] Saved progress to Linear
- [ ] No errors

**Questions to answer:**
- Did it save correctly?
- Was progress shown in Linear?

#### Test 4: Commit Changes
```bash
git add src/featureX.ts
/ccpm:commit "Implement feature X component"
```

**What to check:**
- [ ] Created git commit
- [ ] Used conventional format: `feat(ISSUE-123): ...`
- [ ] Linked to Linear
- [ ] Updated task automatically

**Questions to answer:**
- Was commit format correct?
- Did Linear get updated?

#### Test 5: Verify Quality
```bash
/ccpm:verify
```

**What to check:**
- [ ] Ran quality checks
- [ ] Reported test results
- [ ] Found issues if any
- [ ] Asked for confirmation
- [ ] No errors

**Questions to answer:**
- Did checks run completely?
- Were results accurate?

#### Test 6: Complete Task
```bash
/ccpm:done
```

**What to check:**
- [ ] Pre-flight checks passed
- [ ] Created pull request
- [ ] Updated Linear task
- [ ] Cleaned up
- [ ] No errors

**Questions to answer:**
- Was PR created correctly?
- Did Linear get updated?

---

### Step 4: Compare with Old Commands

Do the same workflow with old commands once and compare:

```bash
# Old workflow
/ccpm:planning:create "Add feature Y" my-app
/ccpm:planning:plan ISSUE-456
/ccpm:implementation:start ISSUE-456
git commit -m "..."
/ccpm:implementation:sync ISSUE-456 "message"
/ccpm:verification:check ISSUE-456
/ccpm:verification:verify ISSUE-456
/ccpm:complete:finalize ISSUE-456
```

**Compare:**
- [ ] Token counts: New should be 40-60% less
- [ ] Speed: New should be 2-3x faster
- [ ] Simplicity: New should feel easier
- [ ] Accuracy: Both should produce same results

---

## Reporting Issues

### Critical Bugs (Report Immediately)

**Examples:**
- Command doesn't work at all
- Creates incorrect data
- Loses user data
- Breaks existing functionality

**How to report:**
```bash
/ccpm:help feedback  # Opens report form
```

Or GitHub Issues: https://github.com/duongdev/ccpm/issues

**Include:**
```
Title: [CRITICAL] /ccpm:work not detecting issue ID

Steps to reproduce:
1. Create branch: git checkout -b feature/PSN-30-test
2. Run: /ccpm:work
3. Error: "Can't find your issue"

Expected: Auto-detect PSN-30 from branch name
Actual: Shows error message

Git branch name: feature/PSN-30-test
Issue ID: PSN-30
Environment: Claude Code [version]
```

---

### Feature Requests

**Examples:**
- Wish new commands had an option for X
- Would like feature Y to also do Z
- Could improve flow with change to A

**How to suggest:**
```bash
/ccpm:help feedback  # Choose "Feature Request"
```

Or comment on GitHub Issues

**Include:**
```
Title: Suggestion: /ccpm:work should show recent branches

Description:
When I run /ccpm:work and auto-detection fails,
it would be helpful to show 5 most recent branches
so I can pick one.

Current: Error message only
Suggested: Error + list of recent branches

Benefit: Faster recovery from branch name mismatches
```

---

### Feedback & Suggestions

**Examples:**
- Command was confusing, here's how to improve
- This workflow is awkward, try this instead
- Documentation unclear here

**How to share:**
1. Daily feedback form (we'll send link)
2. Fill out at end of each day
3. Takes 5-10 minutes

**Include:**
- What you liked
- What could improve
- Your suggestions
- Overall impression

---

## Daily Testing Checklist

### Every Day You Test

- [ ] Tried at least one new command
- [ ] Checked for errors
- [ ] Noted token counts
- [ ] Filled feedback form (if sent)
- [ ] Reported critical issues
- [ ] Updated NPS survey if sent

### End of Week 1 (Dec 13)

- [ ] Tried all 6 new commands
- [ ] Tested auto-detection
- [ ] Compared vs old commands
- [ ] Filled comprehensive feedback
- [ ] Reported any bugs
- [ ] Suggested improvements

### End of Week 2 (Dec 20)

- [ ] Used new commands in real workflow (5+ times each)
- [ ] Measured token reduction
- [ ] Found edge cases
- [ ] Provided detailed feedback
- [ ] Completed NPS survey
- [ ] Contributed to success!

---

## Feedback Form Template

We'll send daily feedback form. Here's what we ask:

```
Date: [Today]
User: [Your name]

1. Which commands did you test today?
   - [ ] /ccpm:plan
   - [ ] /ccpm:work
   - [ ] /ccpm:sync
   - [ ] /ccpm:commit
   - [ ] /ccpm:verify
   - [ ] /ccpm:done

2. Did all commands work?
   - [ ] All worked
   - [ ] Some issues (describe below)
   - [ ] Major problems (describe below)

3. Token reduction vs old commands?
   - Old command tokens: ____
   - New command tokens: ____
   - Reduction: ___% (target: 40-60%)

4. What went well?
   (Free text)

5. What could improve?
   (Free text)

6. Any bugs found?
   (Free text - include steps to reproduce)

7. Overall impression?
   (1-10 scale, with comment)

8. Suggestions for next phase?
   (Free text)
```

---

## NPS Survey

At end of beta (Dec 20), we'll send NPS survey:

```
How likely are you to recommend CCPM v2.3 to a colleague?
(0-10 scale, where 0 = not at all, 10 = extremely likely)

Comments: (why that score?)
```

This is crucial for us! Takes 2 minutes.

---

## Communicating Issues to Team

### Daily Standup (Optional)

**Time:** 3 PM PT, 30 min
**Format:** Zoom call or async update
**Attendees:** Beta testers + CCPM team

**Agenda:**
- What you tested
- Issues found
- Questions
- Feedback

**Can't make it live?** Async update is fine.

---

### Slack/Discord

**Channel:** #ccpm-beta
**Use for:**
- Quick questions
- Issues discussion
- Live feedback
- Celebrating wins

---

## Success Stories & Examples

**We'd love to share:**
- Before/after screenshots
- Token reduction measurements
- Workflow improvements
- Positive feedback
- Success stories

**Share with:**
```bash
/ccpm:help feedback  # Select "Success Story"
```

---

## Perks of Being a Beta Tester

### Recognition
- Featured in v2.3 release notes
- Beta tester spotlight posts
- Community recognition
- Special badge (if we add one)

### Exclusive Access
- Early access to new features
- Direct line to CCPM team
- Special support channel
- Input on future roadmap

### Priority Support
- 2-hour response time for issues
- Direct email: ccpm-feedback@example.com
- Dedicated Slack channel
- Regular check-ins

### Community
- Join private beta tester community
- Network with other power users
- Share workflows and tips
- Influence product direction

---

## Q&A During Beta

### How often should I test?

**Ideal:** Daily or 3-4 times per week
**Minimum:** At least once (try each command)
**Realistic:** Whenever you use CCPM normally

We're not looking for lab testing—real workflow usage is best!

### What if I find a bug?

Report immediately using feedback form or GitHub Issues.

**We'll:**
- Acknowledge within 2 hours
- Investigate within 4 hours
- Fix within 24 hours (if critical)
- Update you on progress

### What if new commands don't work for me?

That's valuable feedback!

**Tell us:**
- What didn't work
- Why it didn't work
- What you expected
- Suggestions for improvement

We'll either fix it or improve documentation.

### Can I switch back to old commands?

Yes! At any time:

```bash
/ccpm:config feature-flags optimized_workflow_commands false
```

Old commands work as before. If you need to revert:

```bash
/plugin remove ccpm
/plugin install ccpm@2.2.4
```

### How do I know my feedback matters?

It really does! We'll show you:

- **Dec 21**: What we changed based on beta feedback
- **Early Access notes**: Credit your improvements
- **GA release**: Thank you message
- **Roadmap**: Your suggestions included

---

## After Beta Period

### What Happens Dec 21?

- Beta closes
- Early Access begins (v2.3.0-rc.1)
- 500-1,000 users invited
- Beta testers can continue if interested

### Can I Keep Testing?

**Absolutely!** You're welcome to:
- Continue testing Early Access
- Provide feedback on improvements
- Help scale testing
- Guide new testers

---

## Important Reminders

### This Is Beta

- Some features may not be perfect
- Bugs are expected and welcomed
- Performance numbers are estimates
- Things may change based on feedback

### Your Data Is Safe

- All data properly secured
- No data loss during beta
- Can rollback if needed
- Your Linear data unchanged

### We Value Your Time

- Testing is voluntary
- Do what feels right
- No pressure to test everything
- Your feedback is the real value

---

## Get Started!

1. Install v2.3.0-beta.1
2. Try first new command today
3. Fill feedback form
4. Report critical issues
5. Help shape the future of CCPM!

**Thank you for being part of this journey!** 🚀

---

## Resources

- **Quick Start**: `docs/guides/v2.3-quick-start.md`
- **Release Notes**: `docs/guides/v2.3-release-notes.md`
- **Migration Guide**: `docs/guides/v2.3-migration-guide.md`
- **FAQ**: `docs/guides/v2.3-faq.md`
- **Rollout Strategy**: `docs/guides/phase-6-rollout-strategy.md`

## Support

- **Questions**: `docs/guides/v2.3-faq.md`
- **Feedback**: `/ccpm:help feedback`
- **Issues**: GitHub Issues
- **Community**: Discord #ccpm-beta
- **Email**: ccpm-feedback@example.com

---

Happy testing! We're excited to have you shape v2.3! 🎉
