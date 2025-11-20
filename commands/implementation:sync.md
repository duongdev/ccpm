---
description: Sync implementation progress, findings, and changes to Linear for full context
allowed-tools: [Bash, LinearMCP, Read, Glob, Grep]
argument-hint: <linear-issue-id> [optional-summary]
---

# Syncing Implementation Progress: $1

Syncing all implementation progress, code changes, technical findings, and blockers to Linear issue **$1** so you have full context to continue later.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (our internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Sync Workflow

### Step 1: Detect Changes Since Last Sync

Use **Bash** to gather git information:

```bash
# Get current branch
git rev-parse --abbrev-ref HEAD

# Get changed files (staged + unstaged)
git status --porcelain

# Get commit history since last sync (look for sync marker in Linear comments)
git log --oneline -10

# Get detailed diff summary
git diff --stat HEAD
git diff --cached --stat
```

**Parse output to identify:**
- Modified files (M)
- New files (A, ??)
- Deleted files (D)
- Renamed files (R)
- Number of insertions/deletions per file

### Step 2: Fetch Linear Issue Context

Use **Linear MCP** to:

1. Get full issue details (title, description, status, labels)
2. Get all comments to find last sync timestamp
3. Check for existing "Implementation Notes" section in description

**Look for last sync:**
```
Search for comments matching pattern: "## 🔄 Progress Sync"
Extract timestamp from most recent sync comment
```

### Step 3: Analyze Code Changes

For each changed file:

1. **Read file** (if <500 lines, otherwise read relevant sections)
2. **Get git diff** for the file
3. **Categorize change**:
   - New feature code
   - Bug fix
   - Refactoring
   - Test file
   - Configuration
   - Documentation

4. **Extract key information**:
   - New functions/classes added
   - Modified APIs
   - Dependencies added/removed
   - TODO/FIXME comments

Use **Grep** to find:
- TODO comments: `grep -r "TODO" --include="*.{js,ts,tsx,jsx}"`
- FIXME comments: `grep -r "FIXME" --include="*.{js,ts,tsx,jsx}"`
- New imports: Look for added import statements in diffs

### Step 4: Interactive Review & Add Notes

Display detected changes in a clear format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Detected Changes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Modified Files (3):
  1. src/api/auth.ts (+45, -12)
     • Added JWT token validation
     • New function: validateToken()

  2. src/components/Login.tsx (+23, -8)
     • Updated login form UI
     • Added error handling

  3. src/tests/auth.test.ts (+67, -0)
     • New test file
     • 12 test cases added

➕ New Files (2):
  4. src/middleware/jwt.ts (+89, -0)
     • JWT middleware implementation

  5. src/types/auth.d.ts (+23, -0)
     • Auth type definitions

📊 Summary:
  • 5 files changed
  • +247 insertions, -20 deletions
  • 2 new files created
  • Branch: feature/auth-implementation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Then use AskUserQuestion** to gather additional context:

```javascript
{
  questions: [
    {
      question: "Any technical decisions or findings to document?",
      header: "Tech Notes",
      multiSelect: false,
      options: [
        {
          label: "Yes, let me add notes",
          description: "I'll provide technical insights and decisions made"
        },
        {
          label: "No, changes are self-explanatory",
          description: "Code changes speak for themselves"
        }
      ]
    },
    {
      question: "Did you encounter any blockers or challenges?",
      header: "Blockers",
      multiSelect: false,
      options: [
        {
          label: "Yes, had blockers (resolved)",
          description: "Encountered issues but managed to resolve them"
        },
        {
          label: "Yes, still blocked",
          description: "Currently blocked and need help"
        },
        {
          label: "No blockers",
          description: "Everything went smoothly"
        }
      ]
    },
    {
      question: "Any test results or quality metrics to include?",
      header: "Quality",
      multiSelect: false,
      options: [
        {
          label: "Yes, ran tests",
          description: "I have test results to share"
        },
        {
          label: "Tests pending",
          description: "Haven't run tests yet"
        },
        {
          label: "No tests needed",
          description: "Not applicable for this change"
        }
      ]
    }
  ]
}
```

**If user wants to add technical notes**, prompt for free-form text input:
```
Please provide your technical notes (press Enter twice when done):
> [User types their notes]
```

**If user has blockers**, prompt for details:
```
Please describe the blocker and what's needed to unblock:
> [User types blocker details]
```

**If user has test results**, prompt for summary:
```
Please share test results (coverage %, passing/failing tests, etc.):
> [User types test results]
```

### Step 5: Build Progress Report

Combine all information into a comprehensive progress report:

```markdown
## 🔄 Progress Sync

**Timestamp**: [Current date/time]
**Branch**: [branch-name]
**Synced by**: @[user-name]

### 📝 Code Changes

**Summary**: [X] files changed (+[insertions], -[deletions])

**Modified Files**:
- `src/api/auth.ts` (+45, -12)
  - Added JWT token validation
  - New function: `validateToken()`

- `src/components/Login.tsx` (+23, -8)
  - Updated login form UI
  - Added error handling

**New Files**:
- `src/middleware/jwt.ts` (+89, -0)
  - JWT middleware implementation

- `src/types/auth.d.ts` (+23, -0)
  - Auth type definitions

### 🧠 Technical Decisions & Findings

[User-provided technical notes, or auto-detected insights:]
- Chose jsonwebtoken library over jose for broader Node.js compatibility
- Implemented token refresh strategy using sliding window approach
- Added rate limiting to prevent brute force attacks (100 req/15min per IP)

### 🚧 Blockers & Challenges

[If any blockers reported:]

**Resolved**:
- ✅ Issue with bcrypt on Node 20 → Upgraded to bcrypt@5.1.0
- ✅ CORS errors in dev → Added proper CORS middleware configuration

**Active Blockers**:
- 🚫 [Blocker description]
  - What's needed: [User-provided info]
  - Status: Needs attention

### ✅ Test Results & Quality

[If test results provided:]
- ✅ All 12 auth tests passing
- ✅ Code coverage: 87% (target: 80%)
- ✅ ESLint: No errors
- ⚠️ TypeScript: 2 warnings (non-critical)

### 📋 Checklist Update

[Auto-update based on completed work:]
- [x] ✅ Implement JWT authentication → Completed
- [x] ✅ Add login form validation → Completed
- [ ] ⏳ Integrate with frontend → In Progress (60%)
- [ ] Add refresh token rotation → Next

### 🎯 Next Steps

Based on progress, suggested next actions:
1. Continue with frontend integration
2. Implement refresh token rotation
3. Run end-to-end tests
4. Update API documentation

---

**Full Diff**: Available in git history (`git diff [previous-sync-commit]..HEAD`)
```

### Step 6: Update Linear Issue

**A) Add Progress Comment**

Use **Linear MCP** to create comment with the progress report from Step 5.

**B) Update Issue Description**

1. Fetch current description
2. Look for "## 📊 Implementation Notes" section
3. If exists, append new entry
4. If not exists, create section before checklist

**Format for description section:**

```markdown
## 📊 Implementation Notes

<details>
<summary>🔄 Latest Sync - [Date/Time] - [% Complete]</summary>

**Files Changed**: [X] files (+[insertions], -[deletions])
**Status**: [Status summary]
**Key Progress**: [Brief summary of main achievements]

See latest comment for full details.

</details>

<details>
<summary>🔄 Previous Sync - [Date/Time] - [% Complete]</summary>
[Previous sync summary...]
</details>
```

This keeps description clean while maintaining history.

**C) Update Labels if Needed**

- Add "blocked" label if active blockers reported
- Remove "blocked" label if all blockers resolved
- Add "needs-review" label if work is ready for review

**D) Auto-Update Checklist**

Based on completed work mentioned in sync:
- Mark relevant subtasks as completed
- Update in-progress subtasks with percentage
- Add completion notes to checklist items

### Step 7: Display Confirmation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Progress Synced to Linear!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: $1
🔗 Link: [Linear issue URL]

📝 Synced Information:
  ✅ Code changes (5 files)
  ✅ Technical decisions (3 notes)
  ✅ Blockers (1 resolved, 0 active)
  ✅ Test results (12 passing)
  ✅ Checklist updated (2 items marked complete)

💬 Comment added with full details
📊 Description updated with sync summary

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. ⭐ Continue Next Subtask
   /ccpm:implementation:next $1

2. Run Quality Checks
   /ccpm:verification:check $1

3. View Updated Status
   /ccpm:utils:status $1

4. Just review what was synced
   [Show Linear issue link]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What would you like to do?
```

Use **AskUserQuestion** to let user choose next action.

## Alternative: Manual Summary Mode

If user provided summary as second argument: `$2`

Skip interactive questions and git detection, just:
1. Use provided summary text as the progress note
2. Still fetch Linear issue for context
3. Create simpler sync comment with manual summary
4. Update description with summary
5. Skip automatic checklist updates

**Format:**
```markdown
## 🔄 Progress Sync (Manual)

**Timestamp**: [Current date/time]
**Summary**: $2

[Rest of standard format...]
```

## Command Variants

### Quick Sync (No Interaction)

```bash
# Quick sync with just summary
/ccpm:implementation:sync WORK-123 "Completed auth implementation, all tests passing"
```

### Full Interactive Sync

```bash
# Full interactive mode with git detection
/ccpm:implementation:sync WORK-123
```

### Sync with Blocker

```bash
# Sync and mark as blocked
/ccpm:implementation:sync WORK-123 "Blocked: Need backend API endpoint deployed"
# → Automatically adds "blocked" label
```

## Examples

### Example 1: Mid-Implementation Sync

```bash
/ccpm:implementation:sync TRAIN-456
```

**Output:**
```
Detected 3 file changes:
  • src/components/Dashboard.tsx (modified)
  • src/hooks/useAuth.ts (new)
  • src/tests/dashboard.test.ts (new)

[Interactive prompts for notes, blockers, tests...]

✅ Synced to Linear!
📋 2 checklist items updated
💬 Progress comment added
```

### Example 2: Quick Manual Sync

```bash
/ccpm:implementation:sync TRAIN-456 "Refactored auth logic to use hooks pattern. Tests updated and passing. Ready for code review."
```

**Output:**
```
✅ Quick sync complete!
💬 Comment added to Linear
📊 Description updated
```

### Example 3: End-of-Day Sync

```bash
/ccpm:implementation:sync TRAIN-456
```

User adds comprehensive notes:
- Technical decisions made today
- Challenges encountered and resolved
- Tomorrow's plan
- Test coverage status

→ Creates complete progress snapshot for next day

## Benefits

### 🎯 Full Context Capture
- Never lose track of what you did
- Document technical decisions in real-time
- Track evolution of implementation approach

### 🔄 Easy Resume
- Use with `/ccpm:utils:context` to quickly resume work
- All progress and decisions documented
- Clear picture of what's done and what's next

### 📊 Progress Visibility
- Team can see progress without asking
- Stakeholders get regular updates
- Project managers have real-time status

### 🧠 Knowledge Retention
- Technical decisions documented
- Blockers and solutions recorded
- Learning captured for future reference

### ⚡ Automation
- Auto-detects code changes from git
- Auto-updates checklist based on work done
- Auto-adds relevant labels

## Integration with Other Commands

**Before starting work:**
```bash
/ccpm:utils:context WORK-123      # Load context
/ccpm:implementation:next WORK-123  # Get next task
```

**During work (multiple times per day):**
```bash
/ccpm:implementation:sync WORK-123  # Sync progress
```

**After work session:**
```bash
/ccpm:implementation:sync WORK-123  # Final sync
/ccpm:verification:check WORK-123   # Run quality checks
```

**Next day:**
```bash
/ccpm:utils:context WORK-123       # Resume with full context
```

## Notes

### When to Sync

- ✅ **End of work session** - Capture progress before stopping
- ✅ **After major milestone** - Document completion of big chunks
- ✅ **When blocked** - Record blocker for team awareness
- ✅ **Before switching tasks** - Save state before context switch
- ✅ **Mid-day checkpoints** - Capture progress on long tasks

### What Gets Synced

- ✅ All git changes (files, diffs, stats)
- ✅ Technical notes and decisions
- ✅ Blockers and resolutions
- ✅ Test results and quality metrics
- ✅ Automatic checklist updates
- ✅ Next steps suggestions

### Safety

- ✅ Only writes to Linear (safe)
- ❌ Never writes to Jira/Confluence/Slack without confirmation
- ✅ Creates immutable history in comments
- ✅ Keeps description summary clean with collapsible sections
