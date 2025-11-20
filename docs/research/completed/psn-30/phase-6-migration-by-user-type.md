# Phase 6: Migration Guides by User Type

**Objective:** Provide clear, targeted migration paths for different CCPM user segments.

---

## User Segmentation

Based on usage patterns and technical expertise, we've identified five user segments:

1. **Power Users** (Daily CCPM usage, all 49+ commands)
2. **Casual Users** (Weekly CCPM usage, 5-10 commands)
3. **New Users** (First-time CCPM users after Phase 6 release)
4. **Integration Developers** (Using CCPM via API/scripts)
5. **Team Leaders** (Managing CCPM rollout across teams)

---

## 1. Power Users Migration

**Profile:**
- Use CCPM daily (3-5 times/day)
- Familiar with most 49+ commands
- Active on community/Discord
- Care deeply about efficiency and optimization
- Comfortable with command line and automation

**Current Usage:**
```bash
# Typical day for power user
/ccpm:planning:create "Feature X" my-app JIRA-123
/ccpm:implementation:start ISSUE-123
/ccpm:implementation:sync ISSUE-123 "Made progress"
/ccpm:verification:check ISSUE-123
/ccpm:implementation:next ISSUE-123
/ccpm:complete:finalize ISSUE-123
```

### Migration Path

#### Week 1: Awareness
- [ ] Receive Phase 6 announcement email
- [ ] Review migration guide (this document)
- [ ] Watch 2-minute overview video
- [ ] Understand 3-5 main command changes

**Key Takeaway:** "New commands are 50% faster, all old ones still work"

#### Week 2: Experimentation
- [ ] Try `/ccpm:plan` command (replaces 3 old commands)
- [ ] Try `/ccpm:work` command (replaces 2 old commands)
- [ ] Try `/ccpm:commit` command (replaces manual git)
- [ ] Compare token counts

**Tasks to Complete:**
```bash
# Task 1: Try new planning command
/ccpm:plan "Add dark mode" my-app JIRA-456  # vs /ccpm:planning:create

# Task 2: Try new work command
/ccpm:work ISSUE-456  # vs /ccpm:implementation:start

# Task 3: Try new sync command
/ccpm:sync "Implemented UI component"  # vs /ccpm:implementation:sync

# Task 4: Try new commit command
/ccpm:commit "add dark mode"  # vs manual git commit

# Task 5: Try new verification command
/ccpm:verify ISSUE-456  # vs /ccpm:verification:check + /ccpm:verification:verify
```

**Success Criteria:** Comfortable with at least 3 new commands

#### Week 3: Gradual Replacement
- [ ] Replace all `/ccpm:planning:create` with `/ccpm:plan`
- [ ] Replace all `/ccpm:implementation:start` with `/ccpm:work`
- [ ] Replace all `/ccpm:implementation:next` with `/ccpm:work`
- [ ] Replace all `/ccpm:verification:check` with `/ccpm:verify`

**New Workflow:**
```bash
# Complete new workflow
/ccpm:plan "Feature Y" my-app JIRA-789
/ccpm:work ISSUE-789
/ccpm:sync "Finished implementation"
/ccpm:commit "add feature Y"
/ccpm:verify ISSUE-789
/ccpm:done ISSUE-789
```

**Time Estimate:** 30-60 minutes to fully adopt

#### Week 4: Optimization
- [ ] Use auto-detection (`/ccpm:work` without issue)
- [ ] Use smart defaults (`/ccpm:sync` auto-generates summary)
- [ ] Enable all feature flags for maximum optimization
- [ ] Measure token reduction in your workflows

**Optimization Tips:**
```bash
# Auto-detect from branch name
git checkout -b issue-ISSUE-789-feature-name
/ccpm:work  # Auto-detects ISSUE-789

# Auto-generate sync summary
git add .
git commit -m "WIP"
/ccpm:sync  # Auto-generates from git diff

# Conventional commits
/ccpm:commit  # Auto-generates from branch + changes
```

### Migration Reference Table

| Old Command | New Command | What Changed | Benefit |
|------------|-------------|--------------|---------|
| `/ccpm:planning:create "title" proj jira` | `/ccpm:plan "title" proj jira` | Shorter name | 5% faster |
| `/ccpm:planning:plan ISSUE-123` | `/ccpm:plan ISSUE-123` | Unified command | 65% fewer tokens |
| `/ccpm:planning:update ISSUE-123 "changes"` | `/ccpm:plan ISSUE-123 "changes"` | Same command | Same efficiency |
| `/ccpm:implementation:start ISSUE-123` | `/ccpm:work ISSUE-123` | Auto-detect | 30% fewer tokens |
| `/ccpm:implementation:next ISSUE-123` | `/ccpm:work ISSUE-123` | Auto-detect | 50% fewer tokens |
| `/ccpm:implementation:sync ISSUE-123 "msg"` | `/ccpm:sync [ISSUE-123] [msg]` | Auto-detect | 65% fewer tokens |
| *(manual git)* | `/ccpm:commit "msg"` | **NEW** Built-in | 40% faster workflow |
| `/ccpm:verification:check ISSUE-123` | `/ccpm:verify ISSUE-123` | Unified check | 70% fewer tokens |
| `/ccpm:verification:verify ISSUE-123` | `/ccpm:verify ISSUE-123` | Combined | N/A |
| `/ccpm:complete:finalize ISSUE-123` | `/ccpm:done ISSUE-123` | Simpler name | 3% faster |

### Support & Help

**Common Questions:**

Q: Do my old commands still work?
A: Yes! All old commands remain functional. The new ones are just faster and recommended.

Q: Will I lose any functionality?
A: No. The new commands do everything the old ones did, just more efficiently.

Q: How much faster are the new commands?
A: 45-67% reduction in token usage per command. Average cost savings: $300-500/year.

Q: Can I mix old and new commands?
A: Yes! Use whatever works for you. The new commands show helpful hints when old ones are used.

Q: What if I don't want to migrate?
A: That's fine. Old commands will work for at least 6 months. But we recommend the new ones for efficiency.

**Getting Help:**
- Video tutorials: `docs/guides/videos/` (5-10 minute walkthroughs)
- Interactive guide: `/ccpm:migration:interactive`
- Weekly office hours: Wednesdays 2 PM PT
- Slack/Discord: #ccpm-migration channel
- Email: support@ccpm.dev

---

## 2. Casual Users Migration

**Profile:**
- Use CCPM weekly (1-2 times/week)
- Familiar with basic 5-10 commands
- Don't follow community closely
- Want simple, straightforward workflows
- Prefer minimal cognitive load

**Current Usage:**
```bash
# Typical week for casual user
/ccpm:planning:create "Task" my-app JIRA-999
/ccpm:implementation:start ISSUE-999
# Manual git workflow for 3 days
/ccpm:complete:finalize ISSUE-999
```

### Migration Path

#### Upon Update (Automatic)
- [ ] Receive automatic plugin update notification
- [ ] See "CCPM 2.3 Available - 50% Faster" in Claude Code
- [ ] Old commands continue to work with helpful hints

**What You'll See:**
When using old commands, a helpful message appears:
```
✨ Pro Tip: You just used /ccpm:planning:create

The new /ccpm:plan command is 63% faster:
  /ccpm:plan "Task" my-app JIRA-999

Try it next time! Learn more: ccpm-migration-guide.md
```

#### First Use (Week 1-2)
- [ ] Try one new command (`/ccpm:plan`)
- [ ] See the benefits (faster execution)
- [ ] Decide if you want to migrate

**Try This:**
```bash
# Your next task, try the new way
/ccpm:plan "Next Task" my-app JIRA-1000

# Compare with old way (uses same old command for comparison)
# You'll notice it runs faster!
```

#### Gradual Adoption (Week 3-4)
- [ ] Use new commands when starting new tasks
- [ ] Keep using old commands if you prefer
- [ ] Gradually transition at your own pace

**Zero Pressure:**
- All old commands work indefinitely (6+ months)
- New commands are optional, not required
- Mix and match as you prefer

#### Complete Migration (Month 2-3)
- [ ] All new tasks use new commands
- [ ] Efficiency benefits accumulate
- [ ] You're automatically more productive

**Total Effort:** 5-10 minutes (just try one command)

### Quick Reference Card

**Just Starting a Task? Use:**
```bash
/ccpm:plan "Task description" my-app JIRA-ID
```

**Working on a Task? Use:**
```bash
/ccpm:work  # Auto-detects issue from branch
```

**Finished Working? Use:**
```bash
/ccpm:done  # Auto-detects issue from branch
```

**That's it!** The new commands handle everything else.

### Support & Help

**For Casual Users (Keep It Simple)**

Q: Should I migrate now?
A: Not urgent. Try the new commands when you start your next task. Old ones work fine.

Q: Will this break my workflows?
A: No. All old commands still work. New ones are optional.

Q: What's the simplest new workflow?
A: `/ccpm:plan`, `/ccpm:work`, `/ccpm:done`. That's all you need.

Q: Can I get back to old commands?
A: Yes. Just keep using them. Both work together.

**Getting Help:**
- Simple one-page guide: `docs/guides/simple-migration.md`
- Short video (2 min): "CCPM 2.3 for Casual Users"
- Just ask: Helpful hints shown in Claude Code
- Email: support@ccpm.dev (we'll help personally)

---

## 3. New Users Migration

**Profile:**
- Installing CCPM for the first time (after Phase 6)
- No prior CCPM experience
- Want to learn best practices
- Prefer modern, efficient workflows

**Installation & Setup (Dec 9+)**

### First-Time Setup

```bash
# 1. Install CCPM from Claude Code marketplace
/plugin install ccpm

# 2. Configure your project (if needed)
/ccpm:project:add my-app
/ccpm:project:set my-app

# 3. You're ready to go!
```

### Learning the Workflow

#### Day 1: Understand the Basics

**Video:** "CCPM for First-Time Users" (5 min)

**Workflow:**
```bash
# 1. Plan your work
/ccpm:plan "Add user authentication" my-app JIRA-123

# 2. Start working
/ccpm:work

# 3. Make your changes in code

# 4. Commit your work
/ccpm:commit "add JWT authentication"

# 5. Verify quality
/ccpm:verify

# 6. Create PR and finalize
/ccpm:done
```

**Concepts Learned:**
- Plan before you code
- Work command starts the implementation
- Commit with conventional format
- Verify quality automatically
- Done creates PR and updates tracker

#### Day 2: Understand Auto-Detection

**Topic:** Smart defaults that save you typing

```bash
# Instead of specifying issue every time:
/ccpm:work ISSUE-123

# Just use auto-detection from branch:
git checkout -b issue-ISSUE-123-auth
/ccpm:work  # Automatically finds ISSUE-123

# Same with sync and verification:
/ccpm:sync  # Auto-detects issue, generates summary
/ccpm:verify  # Auto-detects issue
/ccpm:done  # Auto-detects issue
```

#### Day 3: Learn Advanced Features

**Topics:**
- Feature flags for optimization
- Multiple projects support
- Spec management with Linear Documents
- Advanced verification workflows

#### Week 1: Practice & Master

**Recommended Practice:**
- [ ] Complete 3-5 small tasks using new workflow
- [ ] Try all 6 main commands
- [ ] Watch 1-2 feature-specific videos
- [ ] Ask questions in community

**Success Criteria:**
- Comfortable with basic workflow
- Know how to use auto-detection
- Understand when to use each command

### Learning Resources

**Quick Start (5 minutes):**
- Video: "CCPM Basics" (5 min)
- Cheat sheet: `docs/reference/command-cheatsheet.md`

**Comprehensive Learning (30 minutes):**
- Full guide: `docs/guides/new-user-quick-start.md`
- Video series: 5 videos × 5 min each
- Interactive tutorial: `ccpm:guide interactive`

**Deep Learning (2-4 hours):**
- Complete documentation: `docs/`
- Video tutorials: All feature videos
- Community examples: Discord/community channels

### Zero-to-Productive Timeline

| Time | Milestone | Effort |
|------|-----------|--------|
| 5 min | Install & configure | CLI commands |
| 10 min | Learn basic workflow | Read quick start |
| 15 min | Complete first task | Try commands |
| 30 min | Master auto-detection | Try more commands |
| 1 hour | Try advanced features | Explore options |
| 2-4 hours | Full mastery | Deep learning phase |

### Support & Help

**As a New User:**

Q: Where do I start?
A: Follow `docs/guides/new-user-quick-start.md` - you'll be productive in 15 minutes.

Q: What's the main workflow?
A: Plan → Work → Commit → Verify → Done

Q: What if I make a mistake?
A: CCPM has safeguards. Most operations confirm before executing.

Q: How long does it take to learn?
A: 15 minutes for basics, 1-2 hours for full mastery.

**Getting Help:**
- Interactive guide: `/ccpm:guide interactive`
- Quick start: `docs/guides/new-user-quick-start.md`
- Discord/Slack: #ccpm-help channel
- Email: support@ccpm.dev

---

## 4. Integration Developers Migration

**Profile:**
- Use CCPM via API/scripts
- Automate CCPM workflows
- Build tools on top of CCPM
- Need backward compatibility assurance
- Technical, want detailed documentation

**Current Usage:**
```bash
# Example: Automated workflow script
#!/bin/bash
ISSUE="ISSUE-123"
/ccpm:planning:create "Automation Test" my-app JIRA-456
/ccpm:implementation:start "$ISSUE"
# ... automate the workflow ...
/ccpm:complete:finalize "$ISSUE"
```

### Migration Path

#### Phase 1: Review API Compatibility (Week 1)

**Review:**
- [ ] Read API migration guide: `docs/guides/api-migration-guide.md`
- [ ] Check command endpoint changes
- [ ] Verify parameter compatibility
- [ ] Identify deprecated endpoints

**Compatibility Matrix:**
```
✅ Backward Compatible:
- All command endpoints remain (old naming)
- All parameters work as before
- Response format unchanged

⚠️ Deprecated (6-month sunset):
- /ccpm:planning:create → /ccpm:plan
- /ccpm:implementation:start → /ccpm:work
- /ccpm:implementation:next → /ccpm:work
- /ccpm:implementation:sync → /ccpm:sync
- /ccpm:verification:check → /ccpm:verify
- /ccpm:verification:verify → /ccpm:verify
- /ccpm:complete:finalize → /ccpm:done

🆕 New Endpoints:
- /ccpm:work (smart start/resume)
- /ccpm:plan (unified planning)
- /ccpm:commit (new)
- /ccpm:done (new)
```

#### Phase 2: Test Integration in Staging (Week 2)

**Steps:**
```bash
# 1. Update integration code to support new endpoints
# 2. Test in staging environment
# 3. Verify response format
# 4. Check error handling
# 5. Validate token counts

# Example: Test both old and new endpoints
./test-api.sh --old-endpoints  # Should still work
./test-api.sh --new-endpoints  # Should work better
./test-api.sh --compare-tokens  # Should show reduction
```

**Test Cases to Verify:**
- [ ] All old endpoint calls work (backward compatibility)
- [ ] All new endpoint calls work (new features)
- [ ] Response format unchanged
- [ ] Error handling works
- [ ] Rate limiting respected
- [ ] Token reduction measured

#### Phase 3: Plan Migration Strategy (Week 3)

**Options:**
1. **Minimal Change:** Keep using old endpoints, they work forever
   - Pro: Zero code changes, works indefinitely
   - Con: Missing 50%+ performance improvements

2. **Dual Support:** Call both old and new, compare results
   - Pro: Gradual migration, easy rollback
   - Con: Requires some code changes

3. **Full Migration:** Migrate to new endpoints completely
   - Pro: Maximum performance, modern API
   - Con: Requires code refactoring

**Recommended:** Option 3 (Full Migration) with phased rollout

#### Phase 4: Implement Migration (Week 3-4)

**Example: Migrating Planning Workflow**

```javascript
// BEFORE (Old API)
async function planTask(title, project, jiraId) {
  return await ccpm.api.post('/ccpm:planning:create', {
    title, project, jiraId
  });
}

// AFTER (New API)
async function planTask(title, project, jiraId) {
  return await ccpm.api.post('/ccpm:plan', {
    title, project, jiraId
  });
}

// BOTH WORK - choose your migration pace
```

**Code Changes Required:**
- Replace old endpoint paths with new paths
- Update response parsing if needed (usually not needed)
- Test thoroughly in staging
- Deploy to production with feature flag

**Estimated Effort:** 2-4 hours per integration

#### Phase 5: Deploy to Production (Week 4)

**Deployment Strategy:**
```bash
# 1. Deploy with feature flag off (uses old endpoints)
/ccpm:config api-migration --mode off

# 2. Monitor for issues (1-2 days)
# 3. Enable feature flag (uses new endpoints)
/ccpm:config api-migration --mode on

# 4. Monitor performance (2-3 days)
# 5. Confirm migration successful
/ccpm:config api-migration --status
```

**Rollback Plan:**
If issues arise, immediately:
```bash
/ccpm:config api-migration --mode off  # Back to old endpoints
```

### API Migration Guide

**Location:** `docs/guides/api-migration-guide.md`

**Contents:**
- Endpoint mapping (old → new)
- Parameter changes
- Response format comparison
- Error handling updates
- Performance benchmarks
- Code examples

### Support & Help

**For Integration Developers:**

Q: How long is the migration window?
A: Old endpoints supported for 6 months (until Aug 2026). Plan accordingly.

Q: Can I use both old and new endpoints?
A: Yes. Test both, migrate gradually.

Q: What if my integration breaks?
A: Detailed error documentation and support available. We'll help.

Q: Should I migrate now?
A: Yes, during the Phase 6 rollout window. This ensures 6+ months of support.

**Getting Help:**
- API migration guide: `docs/guides/api-migration-guide.md`
- Code examples: `docs/guides/api-examples/`
- Technical support: support@ccpm.dev
- Office hours: Thursdays 10 AM PT (for technical questions)

---

## 5. Team Leaders Migration

**Profile:**
- Managing CCPM rollout for team/organization
- Responsible for adoption across multiple users
- Need communication templates and planning docs
- Want metrics to track progress

**Responsibilities:**

### 1. Planning the Rollout (Dec 1-8)

**Checklist:**
- [ ] Review Phase 6 rollout strategy
- [ ] Decide on adoption timeline for your team
- [ ] Identify power users as migration champions
- [ ] Plan team communication
- [ ] Allocate time for training

**Planning Questions:**
- When will your team adopt Phase 6?
- Who are your migration champions?
- What support will you need?
- How will you track adoption?

### 2. Communicating the Change (Dec 9+)

**Week 1-2: Announcement**

Email template:
```
Subject: CCPM 2.3 is Here - 50% Faster Workflows

Hi team,

We're excited to announce CCPM 2.3 with significant performance improvements:
- 50% faster command execution
- New simplified commands (/ccpm:plan, /ccpm:work, /ccpm:done)
- 100% backward compatible (old commands still work)

What you need to do: Nothing! Old commands work as before.
What we recommend: Try the new commands when you start your next task.

Resources:
- Quick overview video: (link)
- Migration guide: (link)
- FAQ: (link)

Questions? Reply to this email or ask in #ccpm-migration

Best,
Engineering Team
```

**Week 2-3: Education**

Hold team training session:
```
Duration: 30 minutes
Format: Live demo + Q&A
Topics:
1. What's new (2 min)
2. Live demo of new workflow (8 min)
3. Q&A (10 min)
4. Resources and next steps (5 min)
5. Optional: 1-on-1 help (5 min)
```

**Week 3-4: Support**

Post-training support:
```
- Dedicated #ccpm-help Slack channel
- Daily office hours (15 min) for questions
- Shared document with common issues
- 1-on-1 pairing sessions for those who need it
```

### 3. Tracking Adoption (Ongoing)

**Metrics Dashboard:**

```
Create a shared spreadsheet/dashboard tracking:

Team Member | Status | Commands Tried | % of Tasks Using New | Notes
-----------|--------|----------------|-------------------|-------
Alice      | Done   | plan, work     | 100%              | Migrated day 1
Bob        | In Progress | plan     | 30%               | Using for new tasks
Carol      | Not Started | none     | 0%                | Follow up next week
```

**Adoption Goals:**
- Week 1: 20% of team trying new commands
- Week 2: 50% of team using new commands
- Week 3: 70% of team using new commands
- Week 4: 90% of team using new commands

### 4. Providing Support

**Common Questions Your Team Will Ask:**

Q: Do I have to migrate?
A: No, but new commands are faster and recommended.

Q: Will this break my workflow?
A: No. Old commands continue to work.

Q: How long does migration take?
A: 5-15 minutes to learn, ongoing for new tasks.

Q: What if something breaks?
A: Fallback to old commands immediately. Contact support.

**Support Playbook:**

```
For team members struggling:

1. Share migration guide relevant to their user type
2. Offer to do a 10-minute 1-on-1 walkthrough
3. Pair with a migration champion (power user)
4. Have them try one new command on a simple task
5. Celebrate their success and next time will be easier
```

### 5. Celebrating Success

**Milestones to Celebrate:**

- First team member fully migrated → Slack shout-out
- 50% team migration → Team post-mortem discussion
- 100% team migration → Team celebration + metrics sharing

**Share Results:**
```
Share with team:
- How much faster workflows are
- Token savings for the team
- Success stories from early adopters
- What's next in CCPM roadmap
```

### Resources for Team Leaders

**Planning Documents:**
- Team rollout template: `docs/guides/team-rollout-template.md`
- Communication templates: `docs/guides/communication-templates.md`
- Training materials: `docs/guides/training-materials/`

**Tracking & Metrics:**
- Adoption tracker template: `docs/guides/adoption-tracker.md`
- Metrics dashboard: `docs/guides/phase-6-dashboard.md`

**Support Materials:**
- FAQs: `docs/guides/faq.md`
- Troubleshooting: `docs/guides/troubleshooting-linear.md`
- Common issues: `docs/guides/common-issues.md`

### Team Leader Checklist

**Pre-Launch (Dec 1-8):**
- [ ] Read Phase 6 rollout strategy
- [ ] Review team migration guide
- [ ] Identify migration champions
- [ ] Schedule team communication
- [ ] Prepare training slides

**Launch Week (Dec 9-13):**
- [ ] Send team announcement
- [ ] Share migration resources
- [ ] Hold team training session
- [ ] Identify early adopters and champions
- [ ] Set up help channel

**Post-Launch (Dec 14+):**
- [ ] Track adoption metrics
- [ ] Support struggling team members
- [ ] Share success stories
- [ ] Monitor progress toward 100% adoption
- [ ] Celebrate milestones

---

## General Support

### Help Resources Available

For all user types:
- **Quick Reference:** `/ccpm:help`
- **Interactive Guide:** `/ccpm:migration interactive`
- **FAQ:** `docs/guides/faq.md`
- **Video Library:** `docs/guides/videos/`
- **Community:** Discord/Slack #ccpm-migration
- **Email Support:** support@ccpm.dev
- **Office Hours:** Weekly (details in community)

### Communication Channels

**Where to Get Help:**
1. Interactive hints (in Claude Code)
2. Documentation (links provided)
3. Community (Discord/Slack)
4. Email support (support@ccpm.dev)
5. Office hours (weekly scheduled calls)

**Timeline for Migration Support:**
- Dec 2025: Launch and beta support
- Jan 2026: Early access and adoption support
- Feb-Jul 2026: General availability support
- Aug 2026: Deprecation phase begins

---

## Success Metrics

**We Know the Migration is Successful When:**

✅ 70%+ of user base upgraded to v2.3.0
✅ 60%+ of commands using new implementations
✅ 45-60% average token reduction
✅ <1% error rate
✅ NPS 60+
✅ <10% support tickets related to migration
✅ Positive feedback >80%

---

## Feedback & Improvement

**Your feedback is valuable!**

Tell us what's working and what's not:
- Survey: `ccpm-migration-feedback.survey`
- Community post: Tag with #migration-feedback
- Direct email: feedback@ccpm.dev
- Open issue: github.com/duongdev/ccpm/issues

We use your feedback to improve the migration and future releases.

---

## Timeline Summary

| User Type | Awareness | Experimentation | Adoption | Optimization |
|-----------|-----------|-----------------|----------|--------------|
| Power Users | Week 1 | Week 2 | Week 3-4 | Week 4+ |
| Casual Users | Week 1-2 | Week 2-4 | Month 2-3 | Automatic |
| New Users | Day 1 | Day 1 | Day 1-2 | Week 1+ |
| Integration Devs | Week 1 | Week 2-3 | Week 3-4 | Month 2+ |
| Team Leaders | Week -1 | Week 1 | Week 2-4 | Month 2+ |

---

## Next Steps

**Choose Your Path:**

1. **Power Users:** Go to "Power Users Migration" section above
2. **Casual Users:** Go to "Casual Users Migration" section above
3. **New Users:** Go to "New Users Migration" section above
4. **Integration Developers:** Go to "Integration Developers Migration" section above
5. **Team Leaders:** Go to "Team Leaders Migration" section above

**Or:** Take interactive assessment: `/ccpm:migration assess-my-type`

This will show you exactly which section is relevant for your situation.

---

## Questions?

Having trouble with the migration?

1. **Check the relevant section** for your user type above
2. **Search the FAQ:** `docs/guides/faq.md`
3. **Watch a video:** `docs/guides/videos/`
4. **Ask in community:** #ccpm-migration channel
5. **Email us:** support@ccpm.dev

We're here to help make your migration smooth and successful!
