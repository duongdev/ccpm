---
description: Update existing plan with interactive clarification and smart analysis
allowed-tools: [Bash, LinearMCP, AtlassianMCP, SlackMCP, PlaywrightMCP, Context7MCP, AskUserQuestion]
argument-hint: <linear-issue-id> "<update-request>"
---

# Updating Plan: $1

You are updating the existing plan for Linear issue **$1** based on the update request: **$2**

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

- ✅ **READ-ONLY** operations are permitted (fetch, search, view)
- ⛔ **WRITE operations** require user confirmation
- ✅ **Linear** operations are permitted (our internal tracking)

When in doubt, ASK before posting anything externally.

## Workflow

### Step 1: Fetch Current Plan

Use **Linear MCP** to:

1. Get issue details for: $1
2. Read current description, title, status, labels
3. Parse existing checklist and subtasks
4. Identify project to determine PM systems
5. Extract any Jira ticket reference from description

**Display Current Plan Summary:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Current Plan: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏷️  Title: [Current title]
📊 Status: [Current status]
🎯 Progress: [X/Y] subtasks ([percentage]%)
⏱️  Complexity: [Low/Medium/High if available]

Current Subtasks:
[x] 1. [Subtask 1] ✅
[x] 2. [Subtask 2] ✅
[ ] 3. [Subtask 3] ⏳
[ ] 4. [Subtask 4]
[ ] 5. [Subtask 5]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Update Request
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$2

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 2: Intelligent Analysis

Analyze the update request and current plan to determine:

**Change Type Detection:**

1. **Scope Change**:
   - Keywords: "add", "also need", "include", "plus", "additionally"
   - Impact: New subtasks, modified requirements

2. **Approach Change**:
   - Keywords: "instead of", "different approach", "change how", "use X not Y"
   - Impact: Modified subtasks, architecture changes

3. **Clarification**:
   - Keywords: "unclear", "what about", "how to", "explain", "detail"
   - Impact: Need more context, no plan change yet

4. **Simplification**:
   - Keywords: "remove", "don't need", "simpler", "skip", "not necessary"
   - Impact: Remove subtasks, reduce complexity

5. **Blocker/Issue**:
   - Keywords: "blocked", "can't", "doesn't work", "problem with", "issue"
   - Impact: May need alternative approach

**Analyze Required Information:**

Identify what information is needed to make the update:

- Technical constraints or limitations?
- Priority or urgency changes?
- Dependencies on other work?
- Resource or timeline constraints?
- Specific implementation preferences?
- Risk tolerance or security requirements?

### Step 3: Interactive Clarification

Use **AskUserQuestion** tool to gather necessary context.

**Ask 1-4 targeted questions** based on the analysis:

```javascript
{
  questions: [
    {
      question: "[Specific clarifying question based on update request]",
      header: "Clarification",
      multiSelect: false,
      options: [
        {
          label: "[Option 1]",
          description: "[What this means for the plan]"
        },
        {
          label: "[Option 2]",
          description: "[What this means for the plan]"
        },
        {
          label: "[Option 3]",
          description: "[What this means for the plan]"
        }
      ]
    }
  ]
}
```

**Example Clarification Scenarios:**

**Scenario 1: Scope Addition**
```
Update request: "Also add email notifications"

Question: "How should email notifications be implemented?"
Options:
- "Use existing email service" → Add 2 subtasks
- "Integrate new service (SendGrid)" → Add 4 subtasks + config
- "Just log for now, implement later" → Add 1 subtask (placeholder)
```

**Scenario 2: Approach Change**
```
Update request: "Use REST instead of GraphQL"

Question: "What should we do with existing GraphQL work?"
Options:
- "Replace entirely" → Remove GraphQL subtasks, add REST subtasks
- "Support both" → Keep GraphQL, add REST subtasks
- "Migrate gradually" → Add migration subtasks
```

**Scenario 3: Ambiguous Request**
```
Update request: "Make it faster"

Multiple questions:
1. "What specifically needs to be faster?"
   - Database queries
   - API response time
   - UI rendering
   - All of the above

2. "What's the target performance?"
   - <100ms (aggressive)
   - <500ms (moderate)
   - <1s (baseline)
   - Not sure / measure first
```

**Scenario 4: Blocker**
```
Update request: "Can't use library X, it's deprecated"

Question: "What should we use instead of library X?"
Options:
- "Library Y (recommended alternative)" → Update subtasks
- "Build custom solution" → Add more subtasks
- "Research alternatives first" → Add research subtask
```

### Step 4: Gather Additional Context

Based on clarifications and change type, gather additional context:

**For Scope/Approach Changes:**

1. **Search Codebase**:
   - Find similar implementations
   - Identify affected files
   - Check for existing patterns

2. **Use Context7 MCP**:
   - Search for latest best practices for new approach
   - Find recommended libraries/frameworks
   - Get implementation examples

3. **Check External PM** (if applicable):
   - Search Jira for related tickets
   - Check Confluence for design docs
   - Search Slack for team discussions

**For Clarifications:**

1. **Analyze Current Code**:
   - Read relevant files
   - Understand current architecture
   - Identify constraints

2. **Check Documentation**:
   - Search Confluence for specs
   - Find related PRs in BitBucket
   - Review team decisions

### Step 5: Generate Updated Plan

Based on gathered context and clarifications, generate updated plan:

**Update Checklist:**

```markdown
## ✅ Implementation Checklist

> **Status**: [Keep current status or change to "Planning" if major changes]
> **Complexity**: [Update if complexity changed]
> **Last Updated**: [Current date/time] - [Update summary]

[Generate new checklist]:
- [ ] **Subtask 1**: [Description]
- [ ] **Subtask 2**: [Description]
- [ ] **Subtask 3**: [Description]
...

**Changes from previous plan:**
- ✅ Kept: [List unchanged subtasks]
- 🔄 Modified: [List modified subtasks with what changed]
- ➕ Added: [List new subtasks]
- ➖ Removed: [List removed subtasks with reason]
```

**Update Research Findings:**

Add or modify relevant sections:

```markdown
## 🔍 Research Findings

[Keep existing sections that are still relevant]

### Update History

**[Date/Time] - Plan Update**:
- **Requested**: $2
- **Clarifications**: [Summary of user answers]
- **Changes**: [Summary of plan changes]
- **Rationale**: [Why these changes were made]

[Add new sections if needed based on new research]:

### New Approach Analysis (if approach changed)

**Previous Approach**: [Old approach]
**New Approach**: [New approach]
**Reasoning**: [Why the change]
**Trade-offs**:
- ✅ Benefits: [List benefits]
- ⚠️ Considerations: [List considerations]

### Additional Best Practices (if new research done)

[New best practices from Context7]

### Updated Dependencies (if scope changed)

[Updated dependency information]
```

**Preserve Important Context:**

- Keep all URLs and references from original plan
- Preserve completed subtask history
- Maintain link to original Jira/external tickets
- Keep research findings that are still relevant

### Step 6: Display Plan Comparison

Show side-by-side comparison of changes:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Plan Update Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 Changes Overview:
   ✅ Kept:     [X] subtasks unchanged
   🔄 Modified: [Y] subtasks updated
   ➕ Added:    [Z] new subtasks
   ➖ Removed:  [W] subtasks

📈 Complexity Impact:
   Before: [Old complexity]
   After:  [New complexity]
   Change: [Increased/Decreased/Unchanged]

⏱️  Timeline Impact:
   Estimated: [+/- X days/hours]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Detailed Changes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ KEPT (Unchanged):
   1. [Subtask that stayed the same]
   2. [Another unchanged subtask]

🔄 MODIFIED:
   3. [Old: "Previous description"]
      [New: "Updated description"]
      [Why: Reason for change]

➕ ADDED:
   6. [New subtask 1]
      [Why: Reason for addition]
   7. [New subtask 2]
      [Why: Reason for addition]

➖ REMOVED:
   [Old subtask 4: "Removed description"]
   [Why: Reason for removal]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 7: Confirm and Update

Use **AskUserQuestion** to confirm changes:

```javascript
{
  questions: [{
    question: "Does this updated plan look correct?",
    header: "Confirm",
    multiSelect: false,
    options: [
      {
        label: "Approve & Update",
        description: "Update Linear issue with new plan"
      },
      {
        label: "Needs Adjustment",
        description: "Make further changes before updating"
      },
      {
        label: "Cancel",
        description: "Keep current plan, don't update"
      }
    ]
  }]
}
```

**If "Approve & Update":**

Use **Linear MCP** to update issue $1:
- Update description with new plan
- Update complexity if changed
- Change status to "Planning" if major changes
- Add comment documenting the update
- Add label "plan-updated"

**If "Needs Adjustment":**

Ask follow-up question:

```javascript
{
  questions: [{
    question: "What needs to be adjusted?",
    header: "Adjustment",
    multiSelect: false,
    options: [
      {
        label: "Too many subtasks",
        description: "Consolidate or reduce scope"
      },
      {
        label: "Missing something",
        description: "Add missing requirements"
      },
      {
        label: "Wrong approach",
        description: "Reconsider technical approach"
      }
    ]
  }]
}
```

Then refine and show comparison again (loop to Step 6).

**If "Cancel":**

Exit gracefully without changes.

### Step 8: Show Next Actions

After successful update, display interactive next actions:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Plan Updated Successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Linear Issue: $1
🔗 URL: https://linear.app/workspace/issue/$1

📊 Update Summary:
   🔄 Modified: [Y] subtasks
   ➕ Added:    [Z] subtasks
   ➖ Removed:  [W] subtasks
   📈 Complexity: [New complexity]

💬 Update logged in comments

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Suggested Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use **AskUserQuestion**:

```javascript
{
  questions: [{
    question: "What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "Review Updated Plan",
        description: "Review the updated plan details (/pm:utils:status)"
      },
      {
        label: "Get Fresh Insights",
        description: "Get AI analysis of updated plan (/pm:utils:insights)"
      },
      {
        label: "Start/Resume Work",
        description: "Begin or continue implementation (/pm:implementation:start or /pm:implementation:next)"
      },
      {
        label: "Sync External Systems",
        description: "Update Jira status if needed (/pm:utils:sync-status)"
      }
    ]
  }]
}
```

**Execute chosen action:**

- If "Review Updated Plan" → Run `/pm:utils:status $1`
- If "Get Fresh Insights" → Run `/pm:utils:insights $1`
- If "Start/Resume Work" → Determine if should run `/pm:implementation:start $1` or `/pm:implementation:next $1` based on current status
- If "Sync External Systems" → Run `/pm:utils:sync-status $1`
- If "Other" → Show quick commands

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:        /pm:utils:status $1
Insights:      /pm:utils:insights $1
Start:         /pm:implementation:start $1
Next:          /pm:implementation:next $1
Update Again:  /pm:planning:update $1 "<new request>"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Smart Analysis Features

### Context-Aware Question Generation

The command should intelligently determine what to ask based on:

1. **Ambiguity Level**: More ambiguous requests need more clarification
2. **Change Scope**: Larger changes need more questions
3. **Technical Complexity**: Complex changes need architecture questions
4. **Current Status**: In-progress tasks need migration questions
5. **Project Type**: Different projects may have different constraints

### Change Impact Assessment

Automatically analyze:

- **Complexity Change**: Does this make the task simpler or more complex?
- **Timeline Impact**: Does this add or reduce estimated time?
- **Risk Impact**: Does this introduce new risks?
- **Dependency Impact**: Does this affect other tasks?
- **Resource Impact**: Does this require new skills/tools?

### Intelligent Subtask Generation

When generating new subtasks:

1. **Maintain Granularity**: Match existing subtask size
2. **Logical Ordering**: Put subtasks in implementation order
3. **Dependency Awareness**: Note dependencies between subtasks
4. **Actionable Language**: Use clear, specific verbs
5. **Testable Outcomes**: Each subtask should have clear completion criteria

### Progressive Refinement

If user selects "Needs Adjustment", continue refining:

- Ask follow-up questions
- Adjust based on feedback
- Show updated comparison
- Repeat until approved

## Example Usage Scenarios

### Scenario 1: Adding Scope

```bash
/pm:planning:update WORK-123 "Also add email notifications"

→ Analyzes current plan
→ Asks: "Should we use existing email service or integrate new one?"
→ User: "Use existing service"
→ Asks: "What events should trigger emails?"
→ User: "User signup and password reset"
→ Generates: 2 new subtasks for email integration
→ Shows: Comparison (added 2 subtasks, complexity +1)
→ Confirms and updates
```

### Scenario 2: Changing Approach

```bash
/pm:planning:update WORK-456 "Use Redis caching instead of in-memory"

→ Analyzes: Architecture change
→ Asks: "What's the reason for switching to Redis?"
→ User: "Need persistence across restarts"
→ Asks: "Redis already set up or need to add?"
→ User: "Need to set up"
→ Generates: Updated subtasks (remove in-memory, add Redis setup + integration)
→ Shows: Comparison (modified 3, added 2 subtasks, complexity +2)
→ Asks: "Need Redis for local dev too?"
→ User: "Yes, add Docker setup"
→ Refines: Adds Docker setup subtask
→ Confirms and updates
```

### Scenario 3: Simplification

```bash
/pm:planning:update WORK-789 "Remove the admin dashboard, just add an API"

→ Analyzes: Scope reduction
→ Asks: "Keep any of the admin dashboard work?"
→ User: "No, remove it all"
→ Generates: Removes 4 subtasks, keeps API subtasks
→ Shows: Comparison (removed 4 subtasks, complexity -3)
→ Confirms and updates
```

### Scenario 4: Blocker Resolution

```bash
/pm:planning:update WORK-321 "Library X doesn't support Node 20, need alternative"

→ Analyzes: Technical constraint
→ Asks: "Researched alternatives yet?"
→ User: "Not yet"
→ Adds: Research subtask first
→ Asks: "Want suggestions for alternatives?"
→ User: "Yes"
→ [Searches Context7 for alternatives]
→ Suggests: Library Y and Library Z
→ User: "Library Y looks good"
→ Generates: Updated subtasks using Library Y
→ Shows: Comparison (modified 2 subtasks)
→ Confirms and updates
```

## Notes

### This Command Provides

1. **Interactive Clarification** - Asks smart questions before changing
2. **Context Gathering** - Fetches additional info as needed
3. **Impact Analysis** - Shows complexity/timeline changes
4. **Change Tracking** - Documents update history
5. **Safe Updates** - Confirms before modifying plan
6. **Next Actions** - Suggests what to do after update

### Best Practices

- **Be Specific**: More specific update requests need fewer clarifications
- **Progressive**: Can run multiple times to refine iteratively
- **History**: All updates are logged in Linear comments
- **Reversible**: Original plan is preserved in update history
- **Transparent**: Shows exactly what will change before updating

### Integration with Other Commands

- **After `/pm:planning:plan`**: Update if initial plan needs refinement
- **During `/pm:implementation:*`**: Update if scope/approach changes
- **With `/pm:utils:insights`**: Get AI analysis after updating
- **Before `/pm:verification:check`**: Ensure plan reflects actual work
