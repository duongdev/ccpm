# Phase 6: Support Playbook

**Objective:** Provide support team with clear procedures, scripts, and resources for handling Phase 6 migration and rollout.

**Target Response Time:** <4 hours for all tickets

---

## Table of Contents

1. [Support Team Structure](#support-team-structure)
2. [Common Issues & Solutions](#common-issues--solutions)
3. [Escalation Procedures](#escalation-procedures)
4. [Email Templates](#email-templates)
5. [Knowledge Base](#knowledge-base)
6. [Troubleshooting Guide](#troubleshooting-guide)
7. [FAQ](#faq)

---

## Support Team Structure

### Roles & Responsibilities

#### Support Engineer (Level 1)
- **Availability:** 24/5 (8 AM - 6 PM Mon-Fri PT)
- **Responsibilities:**
  - Respond to incoming support tickets
  - Answer questions about Phase 6
  - Direct users to migration guides
  - Collect error information for escalation
  - Track issue patterns for trending
- **Escalation:** Anything that requires code changes or product decision

#### Senior Support Engineer (Level 2)
- **Availability:** 24/5 (8 AM - 6 PM Mon-Fri PT)
- **Responsibilities:**
  - Handle escalated tickets
  - Debug technical issues
  - Interact with engineering team
  - Handle critical issues
  - Create workarounds for blocking issues
- **Escalation:** Anything that requires immediate engineering attention

#### On-Call Engineer
- **Availability:** 24/7 on-call (Dec 9 - Feb 14)
- **Responsibilities:**
  - On-call for critical incidents
  - Respond to page within 15 minutes
  - Handle error rate spikes
  - Authorize emergency rollbacks
  - Post-incident analysis
- **Escalation:** Already the top escalation point

#### Product Manager (Support)
- **Availability:** 9 AM - 5 PM Mon-Fri PT
- **Responsibilities:**
  - Strategic decisions on support approach
  - Prioritize common issues for fixes
  - Communicate with external teams
  - Gather feedback for product improvements
- **Escalation:** Major decisions, customer relations

---

## Common Issues & Solutions

### Issue Category: Migration Questions

#### Q1: "Do I have to migrate to the new commands?"

**Category:** L1 - Common question

**Response Template:**
```
Thanks for reaching out!

Great question. The short answer is: No, you don't have to migrate.

Here's the full picture:

✅ OLD COMMANDS STILL WORK:
   - All existing commands (/ccpm:planning:create, etc.) continue to work
   - You can keep using them if you prefer
   - No breaking changes to your current workflows

✅ NEW COMMANDS ARE BETTER:
   - 50% faster execution (less tokens)
   - Simpler to use (3 unified commands instead of 9)
   - Better integration (auto-detection from git)
   - Recommended but not required

✅ RECOMMENDED TIMELINE:
   - Try one new command on your next task
   - See the benefits firsthand
   - Gradually migrate at your own pace
   - Full adoption usually takes 1-2 days of active use

📚 RESOURCES:
   - Quick migration guide: (link)
   - Video walkthrough: (link)
   - FAQ: (link)

Still have questions? Happy to help!

Best,
Support Team
```

**Time to Resolve:** 5 minutes

---

#### Q2: "How do I go back to old commands?"

**Category:** L1 - Common question

**Response Template:**
```
You can absolutely use the old commands!

📍 WHAT'S THE SITUATION:
   - Switching back to old commands takes 30 seconds
   - Old commands work just fine
   - You lose the 50% performance benefit but keep full functionality

⚙️ HOW TO SWITCH BACK:
   Just disable the feature flag:

   /ccpm:config feature-flags optimized_workflow_commands false

   That's it! You're back to the old commands.

🔄 HOW TO RE-ENABLE:
   When you're ready to try again:

   /ccpm:config feature-flags optimized_workflow_commands true

📊 CHECKING YOUR STATUS:
   To see which commands you're using:

   /ccpm:config feature-flags --show

🤔 WHAT WE RECOMMEND:
   - Give the new commands 2-3 tries on simple tasks
   - Most people find them more intuitive after a few uses
   - The performance benefit is worth the learning curve

💡 IF YOU'RE STUCK:
   - Watch the 5-minute tutorial: (link)
   - Try the interactive guide: (link)
   - Reply here and we'll pair program!

Best,
Support Team
```

**Time to Resolve:** 5 minutes

---

### Issue Category: Technical Problems

#### T1: "Error: State 'In Progress' not found"

**Category:** L2 - Technical issue with Linear integration

**Root Cause:** Custom Linear workflow with different state names

**Solution:**

```
Thanks for reporting this!

This error happens when your Linear team uses custom workflow states.

🔍 DIAGNOSIS:
   The new shared Linear helpers use intelligent state matching,
   but your team has custom state names that don't match.

✅ SOLUTION (3 STEPS):

   Step 1: Check your Linear team's available states
   /ccpm:config linear-states --show

   Step 2: Find the state type that matches your workflow
   (e.g., "Todo" type = "unstarted" in standard workflows)

   Step 3: Update CCPM with your state mapping
   /ccpm:config linear-states --map-custom "In Progress" "started"

   The system will then recognize "In Progress" and map it correctly.

📖 REFERENCE:
   State types: unstarted, started, completed, canceled

🆘 IF THAT DOESN'T WORK:
   Please reply with:
   - Output from: /ccpm:config linear-states --show
   - Your team name (from Linear)
   - Which command failed

I can then create a manual mapping for you.

Best,
Support Team
```

**Time to Resolve:** 15-30 minutes

---

#### T2: "Command runs but nothing happens"

**Category:** L2 - Silent failure investigation

**Root Cause:** Usually Linear permissions or Linear MCP connection

**Solution:**

```
Silent failures are frustrating! Let's debug this together.

🔍 QUICK DIAGNOSTIC:
   Please run these commands and share the output:

   1. /ccpm:config --show
   2. /ccpm:utils:diagnose
   3. /ccpm:utils:diagnose --linear

   These will help me understand what's happening.

⚡ COMMON CAUSES:
   1. Linear MCP not connected
      Solution: Ensure Linear MCP is installed and authenticated

   2. Wrong project configured
      Solution: /ccpm:project:set [your-project]

   3. Missing Linear permissions
      Solution: Admin must grant you "Create issue" permission

   4. Rate limited
      Solution: Wait 60 seconds and retry

🚀 QUICK FIX TO TRY:
   1. Restart Claude Code
   2. Run: /ccpm:config --reset-cache
   3. Try the command again

📋 NEXT STEPS:
   If it still doesn't work, please reply with:
   - Diagnostic output from above
   - Your project name
   - The exact command you ran

Then I can dig deeper!

Best,
Support Team
```

**Time to Resolve:** 10-20 minutes (first response), 30-60 minutes (resolution)

---

#### T3: "Token reduction doesn't match the 50% claim"

**Category:** L2 - Performance concern

**Root Cause:** Baseline comparison issue or specific command usage pattern

**Solution:**

```
Great question! Let's verify the token reduction.

📊 IMPORTANT CONTEXT:
   The 50% reduction is an average across all commands.
   Different commands have different reductions:

   - /ccpm:plan vs /ccpm:planning:create    = 65% reduction
   - /ccpm:work vs /ccpm:implementation:*   = 67% reduction
   - /ccpm:commit (new command)             = 40% faster workflow
   - /ccpm:verify vs check+verify           = 70% reduction
   - /ccpm:done vs finalize                 = 5% reduction

🔢 HOW TO MEASURE:
   1. Run old command, note tokens used
   2. Run new command, note tokens used
   3. Calculate: (old - new) / old * 100

📈 REALISTIC EXPECTATIONS:
   - Shortest workflows (plan only): 45% reduction
   - Medium workflows (plan + work): 55% reduction
   - Full workflows (plan + work + verify + done): 60% reduction

💡 WHAT AFFECTS YOUR NUMBER:
   - Which commands you use
   - How much context/output they generate
   - Your specific task complexity

🤔 IF YOU'RE SEEING <40%:
   1. What workflow are you using?
   2. Are you using the new /ccpm:plan command?
   3. Are shared helpers enabled?

Please reply with your workflow and I can help optimize!

Best,
Support Team
```

**Time to Resolve:** 10-15 minutes

---

### Issue Category: Adoption & Training

#### A1: "I'm confused about which command to use"

**Category:** L1 - Training/guidance

**Response Template:**
```
No worries! The commands can be confusing at first.

🎯 QUICK ANSWER:
   Use these three commands in this order:

   1. /ccpm:plan "What you want to build"
   2. /ccpm:work
   3. /ccpm:done

   That's 80% of what CCPM does!

📝 THE FULL BREAKDOWN:

   PLANNING PHASE:
   /ccpm:plan "Feature description" [project] [jira-id]
   → Creates or updates the task plan

   IMPLEMENTATION PHASE:
   /ccpm:work              → Start or continue work
   /ccpm:sync "progress"   → Save progress (optional)
   /ccpm:commit "message"  → Git commit (optional)

   VERIFICATION PHASE:
   /ccpm:verify            → Run quality checks

   COMPLETION PHASE:
   /ccpm:done              → Create PR and finish

🎬 SEE IT IN ACTION:
   Watch this 5-minute video: (link)

📖 DETAILED COMMAND REFERENCE:
   /ccpm:help              → Built-in help
   /ccpm:help [command]    → Help for specific command

🤝 IF YOU WANT A WALKTHROUGH:
   We have weekly office hours: Wednesdays 2 PM PT
   Or I can do a quick 1-on-1 here!

Which command gave you the most confusion?

Best,
Support Team
```

**Time to Resolve:** 10 minutes

---

#### A2: "Team member can't upgrade"

**Category:** L1-L2 - Infrastructure issue

**Root Cause:** Plugin permissions or Claude Code version

**Solution:**

```
Let's get your team member upgraded!

🔧 QUICK TROUBLESHOOT:

   1. Check Claude Code version:
      Claude Code → Settings → About
      Need: Claude Code 1.0+ (released Oct 2025)

   2. Check plugin permissions:
      /plugin install ccpm --upgrade
      (May need admin approval)

   3. Verify installation:
      /ccpm:help
      (Should show help, not "command not found")

❌ IF UPGRADE FAILS:

   Try this manual installation:

   1. Go to Claude Code → Plugins
   2. Search for "CCPM"
   3. Click "Install" or "Update"
   4. Restart Claude Code
   5. Try /ccpm:help again

🔐 PERMISSION ISSUES:

   If they get "Permission denied":
   - They may need admin approval
   - Contact your workspace admin
   - Ask them to approve the plugin

🆘 IF STILL STUCK:

   Please have them send:
   - Claude Code version (Settings > About)
   - Error message (exact text)
   - Their OS (Mac/Windows/Linux)
   - Is this a work/personal workspace?

Then I can figure out the exact issue!

Best,
Support Team
```

**Time to Resolve:** 10-15 minutes

---

## Escalation Procedures

### Escalation Levels

#### Level 1 → Level 2 (When to Escalate)

**Escalate when:**
- User has tried suggested solutions
- Requires code investigation
- Involves external system (Jira, GitHub, etc.)
- Issue seems to be a bug, not user confusion
- Response time exceeds 2 hours

**How to escalate:**
1. Add `[ESCALATE: L2]` tag to ticket
2. Summarize steps already tried
3. Include diagnostic output (if available)
4. Assign to Senior Support Engineer
5. Post message in #support-escalations Slack channel

---

#### Level 2 → Engineering (When to Escalate)

**Escalate when:**
- Suspected bug in code
- Affects multiple users (>5)
- Breaking core functionality
- Requires code change
- Error rate spike

**How to escalate:**
1. Create GitHub issue with:
   - Title: `[SUPPORT] Issue summary`
   - Body: Detailed reproduction steps
   - Logs: Any error messages/diagnostics
   - Affected users: How many
2. Assign to engineering team
3. Notify in #product-support Slack channel
4. Keep user updated (email every 4 hours)

---

#### Level 2 → On-Call (When to Page)

**Page immediately if:**
- Error rate >5%
- >50 critical support tickets
- Core workflow broken for all users
- Data corruption/loss
- Security vulnerability

**How to page:**
1. Go to PagerDuty
2. Create incident (severity: SEV1 or SEV2)
3. Page on-call engineer
4. Conference call in #critical-incident Slack
5. Prepare incident handoff document

---

### Incident Response

#### Critical Incident SLA

| Severity | Response | Resolution Target |
|----------|----------|-------------------|
| SEV1 (Blocking) | 5 minutes | 1 hour |
| SEV2 (Major) | 15 minutes | 4 hours |
| SEV3 (Minor) | 1 hour | 1 day |

---

## Email Templates

### Template 1: Quick Answer

```
Hi [Name],

[Direct answer to question]

[Link to relevant resource]

Let me know if you have any other questions!

Best,
[Your name]
Support Team
```

---

### Template 2: Needs More Info

```
Hi [Name],

Thanks for reaching out!

To help you better, I need a bit more information:

1. [Question 1]
2. [Question 2]
3. [Question 3]

Once I have these details, I can provide a more targeted solution!

Best,
[Your name]
Support Team
```

---

### Template 3: Known Issue with Workaround

```
Hi [Name],

Thanks for reporting this!

We've identified the issue and have a workaround:

📋 THE ISSUE:
[Description]

✅ WORKAROUND:
[Steps to work around it]

🔧 PERMANENT FIX:
We're working on a fix that will be released in [version/date].

📞 NEED MORE HELP?
Reply here or schedule a call: [Calendly link]

Best,
[Your name]
Support Team
```

---

### Template 4: Escalating to Engineering

```
Hi [Name],

Thanks for the detailed report!

This looks like it might be a bug in our code. I'm escalating it to our engineering team for investigation.

📋 NEXT STEPS:
1. Engineering will investigate (usually 24 hours)
2. I'll keep you updated daily
3. We'll either provide a workaround or fix it

🎯 TICKET INFO:
GitHub Issue: [Link]
Ticket ID: [ID]

📞 QUICK QUESTION:
Does [Workaround option] work for you temporarily?

I'll follow up with updates daily.

Best,
[Your name]
Support Team
```

---

### Template 5: Closing Ticket

```
Hi [Name],

Great! Sounds like we've got it working for you.

✅ SUMMARY OF SOLUTION:
[What fixed the issue]

📚 FOR NEXT TIME:
[Tip to prevent issue in future]

🆘 IF IT HAPPENS AGAIN:
Just reply to this thread and we'll help!

Thanks for working with us!

Best,
[Your name]
Support Team
```

---

## Knowledge Base

### Key Documentation Links

**User-Facing:**
- Migration guide: `docs/guides/psn-30-migration-guide.md`
- Quick start: `docs/guides/new-user-quick-start.md`
- Migration by user type: `docs/guides/phase-6-migration-by-user-type.md`
- FAQ: `docs/guides/faq.md`
- Troubleshooting: `docs/guides/troubleshooting-linear.md`
- Video tutorials: `docs/guides/videos/`

**Internal:**
- Phase 6 rollout strategy: `docs/guides/phase-6-rollout-strategy.md`
- Implementation checklist: `docs/guides/phase-6-implementation-checklist.md`
- Dashboard: `docs/monitoring/phase-6-dashboard.md`
- Known issues: `docs/development/phase-6-known-issues.md` (update as we find issues)

---

## Troubleshooting Guide

### Error: "Feature flag not found"

**Cause:** Feature flag configuration missing or outdated

**Fix:**
```bash
/ccpm:config --reset-cache
/ccpm:config feature-flags --refresh
```

**If persists:** Escalate to L2

---

### Error: "Linear MCP not connected"

**Cause:** Linear MCP server not running

**Fix:**
```bash
# Restart Claude Code
# Check Settings > MCP Servers
# Verify Linear is connected

# If still not connected:
/ccpm:config mcp --restart
```

**If persists:** Escalate to L2

---

### Error: "Project not found"

**Cause:** Project not configured

**Fix:**
```bash
/ccpm:project:list  # See all projects
/ccpm:project:set [project-name]  # Set active project
/ccpm:project:add [project-name]  # Add new project
```

---

### Error: "Issue creation failed"

**Cause:** Usually Linear permissions

**Fix:**
1. Check Linear permissions (must have "Create issue")
2. Verify right team is selected
3. Check project exists in Linear

**If persists:** Escalate to L2 with error message

---

## FAQ

### Q: "Why is Phase 6 necessary?"

**A:** Phase 6 implements the rollout strategy for Phases 1-5 optimization work. It ensures:
- Smooth transition for existing users
- Backward compatibility throughout
- Gradual adoption with feature flags
- Clear migration paths for different user types
- Comprehensive support during transition

---

### Q: "How long will old commands be supported?"

**A:** Old commands will be supported for 6 months after GA (until Aug 2026), then deprecated. Users get 6 months warning before old commands are removed.

---

### Q: "What if I find a bug?"

**A:** Report it immediately:
1. Click "Report Bug" in Claude Code
2. Include:
   - What you were doing
   - Expected behavior
   - Actual behavior
   - Error message (if any)
3. Include diagnostic output: `/ccpm:utils:diagnose`

---

### Q: "Can I use old and new commands together?"

**A:** Yes! You can mix old and new commands. Both work together perfectly.

---

### Q: "Will this affect my existing scripts/automation?"

**A:** No! All old commands work exactly as before. Your scripts will continue to work without any changes.

---

### Q: "How much faster are the new commands really?"

**A:** On average, 50% fewer tokens. Specific commands:
- `/ccpm:plan`: 65% reduction
- `/ccpm:work`: 67% reduction
- `/ccpm:commit`: 40% faster
- `/ccpm:verify`: 70% reduction
- `/ccpm:done`: 5% reduction

---

### Q: "What if I hate the new commands?"

**A:** You can disable them anytime:
```bash
/ccpm:config feature-flags optimized_workflow_commands false
```

Your old commands will resume immediately.

---

## Support Resources

### Internal Resources
- **Slack:** #ccpm-support (urgent issues)
- **Database:** Support ticket system (for tracking)
- **Docs:** `docs/guides/` (user documentation)
- **Issues:** GitHub issues (for bugs)

### External Resources
- **Community:** Discord/Slack #ccpm-help
- **Email:** support@ccpm.dev
- **Office Hours:** Wednesdays 2 PM PT
- **YouTube:** CCPM tutorials channel

---

## Daily Support Checklist

**Start of Day:**
- [ ] Check overnight support tickets
- [ ] Review critical issues from yesterday
- [ ] Check dashboard for error spikes
- [ ] Respond to any escalations in queue

**Throughout Day:**
- [ ] Respond to new tickets (target: <1 hour)
- [ ] Update ticket statuses
- [ ] Escalate as needed
- [ ] Document new issues found

**End of Day:**
- [ ] Summarize ticket volume and trends
- [ ] Update known issues list
- [ ] Prepare escalations for next day
- [ ] Document any patterns noticed

---

## Sign-Off

**Support Manager:** _________________ Date: _________

**Reviewed By:** _________________ Date: _________

---

**Last Updated:** [Date]
**Next Review:** [Date]

This playbook is a living document. Update as new issues are discovered and solutions are developed.
