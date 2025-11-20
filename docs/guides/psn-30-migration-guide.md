# PSN-30 Migration Guide

**Migrating to Optimized Natural Workflow Commands (v2.3)**

## Overview

PSN-30 introduces highly optimized natural workflow commands that reduce token usage by 63-67% while maintaining full backward compatibility. This guide helps you transition from the old command structure to the new optimized workflow.

**Key Benefits:**
- 🚀 **63-67% faster** - Reduced token usage across all commands
- 💰 **Lower costs** - $300-$3,000 annual savings depending on usage
- ⚡ **Better UX** - Auto-detection, smart defaults, intuitive syntax
- ✅ **Backward compatible** - Old commands still work, just show migration hints

## Quick Start

If you're already using CCPM, just start using the new commands:

```bash
# Old way (still works)
/ccpm:planning:create "Add auth" my-app JIRA-123

# New way (recommended)
/ccpm:plan "Add auth" my-app JIRA-123
```

**That's it!** The new commands do everything the old ones did, just faster and more efficiently.

## Command Mapping

### Complete Command Migration Table

| Old Command | New Command | What Changed |
|------------|-------------|--------------|
| `/ccpm:planning:create` | `/ccpm:plan "title" [project] [jira]` | Shorter, same functionality |
| `/ccpm:planning:plan` | `/ccpm:plan ISSUE-123` | Unified planning command |
| `/ccpm:planning:update` | `/ccpm:plan ISSUE-123 "changes"` | Same command for all planning |
| `/ccpm:implementation:start` | `/ccpm:work [issue-id]` | Auto-detects start vs resume |
| `/ccpm:implementation:next` | `/ccpm:work [issue-id]` | Combined into work command |
| `/ccpm:implementation:sync` | `/ccpm:sync [issue-id] [summary]` | Auto-detects from branch |
| *(manual git)* | `/ccpm:commit [issue-id] [message]` | **NEW** - Built into workflow |
| `/ccpm:verification:check` | `/ccpm:verify [issue-id]` | Combined checks + verification |
| `/ccpm:verification:verify` | `/ccpm:verify [issue-id]` | Sequential execution |
| `/ccpm:complete:finalize` | `/ccpm:done [issue-id]` | Simpler name, same safety |

**Important:** All old commands continue to work. They now display hints recommending the new commands.

## Detailed Migration Guide

### 1. Planning Workflow

#### Old Workflow (3 commands)

```bash
# Create new task
/ccpm:planning:create "Add user auth" my-app TRAIN-456

# Plan existing task
/ccpm:planning:plan WORK-123 TRAIN-456

# Update plan
/ccpm:planning:update WORK-123 "Also add 2FA"
```

#### New Workflow (1 command, 3 modes)

```bash
# Create new task (Mode 1: CREATE)
/ccpm:plan "Add user auth" my-app TRAIN-456

# Plan existing task (Mode 2: PLAN)
/ccpm:plan WORK-123

# Update plan (Mode 3: UPDATE)
/ccpm:plan WORK-123 "Also add 2FA"
```

**Benefits:**
- 65% token reduction (7,000 → 2,450 tokens)
- One command to remember
- Automatic mode detection
- Smart clarifying questions for updates

### 2. Implementation Workflow

#### Old Workflow

```bash
# Start work
/ccpm:implementation:start WORK-123

# Get next action
/ccpm:implementation:next WORK-123

# Sync progress
/ccpm:implementation:sync WORK-123 "Made progress"

# Manual git commits
git add .
git commit -m "feat: add authentication"
```

#### New Workflow

```bash
# Start work (auto-detects if starting or resuming)
/ccpm:work WORK-123
# or just
/ccpm:work  # Auto-detects from branch name

# Sync progress (auto-detects issue from branch)
/ccpm:sync "Made progress"
# or just
/ccpm:sync  # Auto-generates summary from git changes

# Commit (NEW - integrated into workflow)
/ccpm:commit "add authentication"
# or just
/ccpm:commit  # Auto-generates from issue + changes
```

**Benefits:**
- 67% token reduction for work (15,000 → 5,000 tokens)
- 65% token reduction for sync (6,000 → 2,100 tokens)
- Auto-detection from git branch
- Built-in conventional commits
- Combined start/resume logic

**Key Change:** `/ccpm:work` intelligently decides whether to START or RESUME based on issue status:
- **START:** Issue is in Planning/Backlog/Todo → Initialize implementation
- **RESUME:** Issue is In Progress → Show progress and suggest next action

### 3. Verification Workflow

#### Old Workflow (2 commands)

```bash
# Run quality checks
/ccpm:verification:check WORK-123

# Run verification
/ccpm:verification:verify WORK-123
```

#### New Workflow (1 command)

```bash
# Run checks + verification sequentially
/ccpm:verify WORK-123
# or just
/ccpm:verify  # Auto-detects from branch
```

**Benefits:**
- 65% token reduction (8,000 → 2,800 tokens)
- Sequential execution (fail fast)
- Auto-detection from branch
- Interactive prompts for incomplete checklist

**Key Change:** Verification now runs quality checks first, then final verification. If checks fail, it stops and suggests fixes (fail fast).

### 4. Completion Workflow

#### Old Workflow

```bash
/ccpm:complete:finalize WORK-123
```

#### New Workflow

```bash
# Same functionality, simpler name
/ccpm:done WORK-123
# or just
/ccpm:done  # Auto-detects from branch
```

**Benefits:**
- 65% token reduction (6,000 → 2,100 tokens)
- Shorter command name
- Auto-detection from branch
- Enhanced pre-flight safety checks

## Migration Strategies

### Strategy 1: Immediate Migration (Recommended)

**Best for:** Power users, teams wanting maximum efficiency

**Steps:**
1. Learn the 6 new commands (plan, work, sync, commit, verify, done)
2. Start using them in your next workflow
3. Take advantage of auto-detection features

**Timeline:** 1 day

**Effort:** Low - commands are intuitive

### Strategy 2: Gradual Migration

**Best for:** Teams with established workflows, conservative migration

**Steps:**
1. Week 1: Start with `/ccpm:plan` (replaces 3 planning commands)
2. Week 2: Add `/ccpm:work` and `/ccpm:sync` (replaces 3 implementation commands)
3. Week 3: Add `/ccpm:commit` (new command)
4. Week 4: Complete with `/ccpm:verify` and `/ccpm:done`

**Timeline:** 4 weeks

**Effort:** Minimal - one new command per week

### Strategy 3: Side-by-Side Usage

**Best for:** Large teams, risk-averse organizations

**Steps:**
1. Continue using old commands for existing workflows
2. Use new commands for new workflows
3. Compare efficiency and experience
4. Migrate team-wide after validation period

**Timeline:** 1-2 months

**Effort:** Medium - running two approaches in parallel

## Common Migration Scenarios

### Scenario 1: Mid-Task Migration

You're in the middle of a task using old commands. Can you switch?

**Answer:** Yes! The commands are fully compatible.

```bash
# You started with old commands
/ccpm:planning:create "Add auth" my-app
/ccpm:implementation:start WORK-123

# Continue with new commands
/ccpm:sync "Made progress"
/ccpm:verify
/ccpm:done
```

**No issues!** Linear tracks the same data regardless of which command set you use.

### Scenario 2: Team with Different Preferences

Some team members prefer old commands, others want new ones.

**Answer:** Both work! Team members can use whichever they prefer.

**Best Practice:**
- Document both command sets in team wiki
- Recommend new commands for new hires
- Let experienced users choose their preference
- Eventually phase out old commands when everyone's comfortable

### Scenario 3: Scripted Workflows

You have scripts/automation using old commands.

**Answer:** Scripts continue working. Update at your convenience.

**Migration Path:**
1. Keep scripts working with old commands
2. Test new commands manually
3. Update scripts one at a time
4. Validate each script after update

### Scenario 4: Custom Workflows

You've built custom workflows around specific commands.

**Answer:** New commands are more flexible, easier to customize.

**Example:**

```bash
# Old custom workflow script
function create_and_start() {
  /ccpm:planning:create "$1" my-app
  # Extract issue ID from output (complex)
  /ccpm:implementation:start $ISSUE_ID
}

# New custom workflow script (simpler)
function create_and_start() {
  /ccpm:plan "$1"
  # Interactive prompt offers "Start implementation"
  # Just select it!
}
```

## Feature Comparison

### What's the Same

✅ All functionality preserved
✅ Linear integration unchanged
✅ External PM system integration (Jira, Confluence, Slack)
✅ Safety rules enforced
✅ Interactive mode
✅ Smart agent selection
✅ Quality checks and verification

### What's Better

🚀 **Performance:**
- 63-67% token reduction
- 3-5x faster response times (cached operations)
- Fewer API calls to external systems

💡 **User Experience:**
- Auto-detection from git branch
- Smart defaults (less typing)
- Unified commands (fewer to remember)
- Better error messages
- Fail-fast validation

🔧 **Technical:**
- Direct implementation (no routing overhead)
- Session-level caching (85-95% hit rates)
- Batch operations (combine API calls)
- Optimized for Claude Sonnet 4.5

### What's Different

⚠️ **Breaking Changes:** None! Backward compatible.

📝 **Behavior Changes:**
1. **Auto-detection:** Commands try to detect issue ID from branch
2. **Mode detection:** Single command handles multiple modes (e.g., `/ccpm:plan`)
3. **Sequential execution:** `/ccpm:verify` runs checks then verification
4. **Interactive prompts:** More context-aware suggestions

## Troubleshooting

### Issue: "Command not found"

**Cause:** Using old command syntax with typos

**Solution:** Check command mapping table above

**Example:**
```bash
# Wrong
/ccpm:planning-create  # Hyphen instead of colon

# Right
/ccpm:plan
```

### Issue: "Could not detect issue ID from branch"

**Cause:** Git branch name doesn't contain issue ID

**Solution:** Either:
1. Use explicit issue ID: `/ccpm:work WORK-123`
2. Rename branch to include issue ID: `feature/WORK-123-description`

**Branch naming convention:**
```
✅ feature/WORK-123-add-auth
✅ WORK-123-bugfix
✅ fix/WORK-123
❌ feature/add-authentication  (no issue ID)
```

### Issue: "Mode detection failed"

**Cause:** Ambiguous arguments to `/ccpm:plan`

**Solution:** Follow clear patterns:
- **CREATE:** First arg is quoted string: `/ccpm:plan "title"`
- **PLAN:** First arg is issue ID: `/ccpm:plan WORK-123`
- **UPDATE:** First arg is issue ID, second is quoted: `/ccpm:plan WORK-123 "changes"`

### Issue: "Cache miss, slower than expected"

**Cause:** First time running command in session

**Solution:** This is normal! Cache warms up after first use:
- **First call:** 400-600ms (cache miss)
- **Subsequent calls:** <50ms (cache hit)
- **Cache hit rate:** 85-95%

**Tip:** Run `/ccpm:utils:status` at start of session to warm cache

### Issue: "Old command shows migration hint"

**Cause:** Using old command, system suggests new one

**Solution:** This is intentional! Old commands now display:
```
ℹ️  TIP: Use the optimized command for better performance:
   /ccpm:plan WORK-123

This achieves the same result with 65% fewer tokens.
```

**Action:** Switch to new command when convenient (not urgent)

## Best Practices for Migration

### 1. Use Auto-Detection

Take advantage of automatic issue ID detection:

```bash
# Instead of
/ccpm:work WORK-123
/ccpm:sync WORK-123
/ccpm:verify WORK-123
/ccpm:done WORK-123

# Just use
/ccpm:work
/ccpm:sync
/ccpm:verify
/ccpm:done
```

**Requirement:** Branch name must contain issue ID (e.g., `feature/WORK-123-description`)

### 2. Branch Naming Convention

Adopt a consistent branch naming pattern:

```bash
# Recommended patterns
git checkout -b feature/WORK-123-short-description
git checkout -b fix/WORK-123-bug-name
git checkout -b WORK-123-feature-name

# Also works
git checkout -b yourname/WORK-123-feature
```

### 3. Quick Sync Mode

When you just want to save progress without interactive prompts:

```bash
# Instead of interactive mode
/ccpm:sync  # Opens interactive checklist update

# Use quick sync
/ccpm:sync "Completed auth endpoints"
```

### 4. Trust Interactive Prompts

New commands provide smart suggestions. Trust them!

```bash
/ccpm:work WORK-123

# Command suggests:
# 💡 Next action?
#   1. Continue Next Task ⭐
#   2. Run Quality Checks
#   3. Update Status

# Just select option 1, don't overthink it
```

### 5. Commit Often with `/ccpm:commit`

Take advantage of the new built-in git commit:

```bash
# Traditional approach (manual)
git add .
git commit -m "feat(WORK-123): add authentication"

# New approach (automated)
/ccpm:commit  # Auto-generates conventional commit
```

**Benefits:**
- Automatic conventional commit format
- Links to Linear issues
- Smart type detection (feat/fix/docs)
- Shows summary before committing

## Performance Optimization Tips

### 1. Warm Up Cache at Session Start

```bash
# At start of work session, run any command to warm cache
/ccpm:utils:status WORK-123

# Now all subsequent commands benefit from cache
/ccpm:work
/ccpm:sync
# etc.
```

### 2. Use Batch Operations

Don't run commands redundantly:

```bash
# Inefficient
/ccpm:work WORK-123  # Fetches issue
/ccpm:utils:status WORK-123  # Fetches issue again

# Efficient
/ccpm:work WORK-123  # Fetches and caches issue
# Status is shown in work output
```

### 3. Prefer New Commands

New commands are optimized. Old commands have routing overhead:

```bash
# Slower (routing overhead)
/ccpm:planning:plan WORK-123  # ~7,000 tokens

# Faster (direct implementation)
/ccpm:plan WORK-123  # ~2,450 tokens
```

### 4. Leverage Auto-Generation

Let commands auto-generate content:

```bash
# Manual (more tokens, more typing)
/ccpm:sync WORK-123 "Updated auth module to use JWT, added validation middleware, fixed token expiration bug"

# Auto-generated (fewer tokens, less typing)
/ccpm:sync  # Analyzes git changes, generates summary
```

## Rollback Plan

If you need to rollback to old commands:

**Good news:** You don't need to! Old commands still work.

But if you want to:

1. **Stop using new commands** - Just use old command syntax
2. **No data migration needed** - Linear data is the same
3. **Scripts continue working** - Old commands unchanged
4. **Team flexibility** - Each person can choose

**Note:** Rollback loses performance benefits (63-67% token savings)

## Getting Help

### Command Reference

- **Full command list:** [commands/README.md](/Users/duongdev/personal/ccpm/commands/README.md)
- **Token savings report:** [docs/development/psn-30-token-savings-report.md](/Users/duongdev/personal/ccpm/docs/development/psn-30-token-savings-report.md)
- **Architecture:** [docs/architecture/psn-30-natural-command-direct-implementation.md](/Users/duongdev/personal/ccpm/docs/architecture/psn-30-natural-command-direct-implementation.md)

### Interactive Help

```bash
# Context-aware help
/ccpm:utils:help WORK-123

# Workflow cheatsheet
/ccpm:utils:cheatsheet
```

### Common Commands Quick Reference

```bash
# Planning
/ccpm:plan "title" [project] [jira]     # Create
/ccpm:plan ISSUE-123                     # Plan existing
/ccpm:plan ISSUE-123 "changes"           # Update

# Implementation
/ccpm:work [issue-id]                    # Start/resume
/ccpm:sync [issue-id] [summary]          # Save progress
/ccpm:commit [issue-id] [message]        # Git commit

# Verification & Completion
/ccpm:verify [issue-id]                  # Quality checks + verification
/ccpm:done [issue-id]                    # Finalize (PR + sync + complete)
```

## FAQ

### Q: Do I have to migrate?

**A:** No! Old commands continue working. But new commands are 63-67% faster and more efficient.

### Q: When should I migrate?

**A:** Anytime! Start with your next workflow. No preparation needed.

### Q: Can I use both old and new commands?

**A:** Yes! They're fully compatible. Mix and match as needed.

### Q: What if I forget the new syntax?

**A:** Old commands now show hints with the new syntax. Also, use `/ccpm:utils:help` or `/ccpm:utils:cheatsheet`.

### Q: Will old commands be removed?

**A:** Not in the near term. They'll remain for backward compatibility, but may show deprecation warnings in future versions.

### Q: How do I test new commands without affecting production?

**A:** Commands have the same safety rules. Test on personal tasks first. All external system writes require confirmation (Jira, Slack, etc.).

### Q: Do new commands work with all integrations?

**A:** Yes! Linear, Jira, Confluence, BitBucket, Slack, GitHub - all work the same.

### Q: Are there any risks?

**A:** No. New commands are thoroughly tested and backward compatible. If issues arise, old commands still work.

### Q: Can I revert mid-workflow?

**A:** Yes! Commands are interoperable:
```bash
/ccpm:plan "Task"          # New
/ccpm:implementation:start WORK-123  # Old
/ccpm:sync                 # New
/ccpm:verification:verify WORK-123   # Old
/ccpm:done                 # New
```

### Q: How do I update my team's documentation?

**A:** We recommend:
1. Add new command syntax to docs
2. Mark old commands as "legacy" but still supported
3. Show both syntaxes during transition period
4. Eventually remove old syntax documentation

### Q: What about custom scripts and automation?

**A:** Scripts using old commands continue working. Update scripts gradually:
1. Test new commands manually
2. Update one script at a time
3. Validate each script after update

## Summary

✅ **Migration is optional** - old commands still work
✅ **Zero downtime** - switch anytime, even mid-workflow
✅ **Better performance** - 63-67% token reduction, 3-5x faster
✅ **Improved UX** - auto-detection, smart defaults, intuitive syntax
✅ **Fully compatible** - Linear data unchanged, integrations work

**Recommended Approach:**
1. Read this guide (15 minutes)
2. Try new commands on next task (immediate)
3. Adopt permanently after 1-2 workflows

**The Bottom Line:**

The new commands do everything the old ones did, just faster and more efficiently. Start using them today!

---

**Last Updated:** 2025-11-20
**CCPM Version:** 2.3.0
**Migration Status:** Stable, Recommended
