---
description: Update Implementation Checklist items in Linear issue description
allowed-tools: [LinearMCP, AskUserQuestion, Bash]
argument-hint: <linear-issue-id>
---

# Update Checklist: $1

Updating Implementation Checklist directly in the Linear issue description.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (our internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Checklist Update Workflow

### Step 1: Fetch Linear Issue

Use **Linear MCP** to get issue: $1

Extract:
- Full description (markdown)
- Current status
- Title

### Step 2: Parse Checklist from Description

Look for the Implementation Checklist section in the description using these markers:

**Pattern 1: Marker Comments (Preferred)**
```markdown
<!-- ccpm-checklist-start -->
- [ ] Task 1: Description
- [x] Task 2: Description (completed)
- [ ] Task 3: Description
<!-- ccpm-checklist-end -->
```

**Pattern 2: Header-Based (Fallback)**
```markdown
## ✅ Implementation Checklist
- [ ] Task 1
- [ ] Task 2
...
(until next ## header or end of content)
```

**Parsing Logic:**
1. Search for `<!-- ccpm-checklist-start -->` marker
2. If found, extract all lines between start and end markers
3. If not found, look for "## ✅ Implementation Checklist" or similar headers
4. Extract all checklist items (lines starting with `- [ ]` or `- [x]`)
5. Parse each item to extract:
   - Index (0-based position)
   - Status (checked or unchecked)
   - Content (the text after the checkbox)

**Edge Cases:**
- No checklist found → Display warning, offer to skip
- Corrupted format → Attempt recovery, show warning
- Multiple checklists → Use marker comments to identify the right one
- Empty checklist → Display error

### Step 3: Display Current Checklist

Show current state with indices:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Current Implementation Checklist ($1)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Progress: X% (Y/Z completed)

 0. [ ] Task 1: Description
 1. [x] Task 2: Description ✅
 2. [ ] Task 3: Description
 3. [ ] Task 4: Description
 4. [x] Task 5: Description ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Choose Update Mode

First, ask user if they want to mark items complete or rollback (uncheck) items:

Use **AskUserQuestion**:

```javascript
{
  questions: [
    {
      question: "What would you like to do with the checklist?",
      header: "Action",
      multiSelect: false,
      options: [
        {
          label: "Mark items complete",
          description: "Check off completed tasks (default)"
        },
        {
          label: "Rollback items",
          description: "Uncheck incorrectly marked items"
        }
      ]
    }
  ]
}
```

### Step 5: Interactive Selection

**If "Mark items complete" selected:**

Use **AskUserQuestion** with multi-select to let user choose which items to check:

```javascript
{
  questions: [
    {
      question: "Which checklist items did you complete? (Select all that apply)",
      header: "Completed",
      multiSelect: true,
      options: [
        {
          label: "0: Task 1: Description",
          description: "Mark this task as complete"
        },
        {
          label: "2: Task 3: Description",
          description: "Mark this task as complete"
        },
        {
          label: "3: Task 4: Description",
          description: "Mark this task as complete"
        }
        // Only show UNCHECKED items
      ]
    }
  ]
}
```

**If "Rollback items" selected:**

Use **AskUserQuestion** with multi-select to let user choose which items to uncheck:

```javascript
{
  questions: [
    {
      question: "Which items were incorrectly marked complete? (Select all to rollback)",
      header: "Rollback",
      multiSelect: true,
      options: [
        {
          label: "1: Task 2: Description",
          description: "Uncheck this item (mark incomplete)"
        },
        {
          label: "4: Task 5: Description",
          description: "Uncheck this item (mark incomplete)"
        }
        // Only show CHECKED items
      ]
    }
  ]
}
```

**Parse user selections:**
- Extract indices from selected options (first number before ":")
- Store as array of indices
- Store mode: "complete" or "rollback"

### Step 6: Update Checklist via Linear Operations Subagent

**Use the Task tool to update the checklist:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: update_checklist_items
  params:
    issue_id: "{issue ID from step 1}"
    indices: [{selected indices from step 5}]
    mark_complete: {true if mode is "complete", false if mode is "rollback"}
    add_comment: true  # Document the change with a comment
    update_timestamp: true
  context:
    command: "utils:update-checklist"
    purpose: "Manual checklist update by user"
  ```

**This operation will:**
1. Use shared checklist helpers (`_shared-checklist-helpers.md`) for parsing
2. Update the specified checkbox states (✓ or uncheck)
3. Recalculate progress percentage automatically
4. Update the progress line with current timestamp
5. Add a comment documenting the changes
6. Return structured result with before/after progress

**Example response:**
```yaml
success: true
data:
  checklist_summary:
    items_updated: 2
    previous_progress: 20
    new_progress: 60
    completed: 3
    total: 5
  changed_items:
    - index: 1
      content: "Task 2: Description"
      previous_state: unchecked
      new_state: checked
metadata:
  duration_ms: 320
  used_shared_helpers: true
```

### Step 7: Display Confirmation

Show success message with details

**Timestamp**: [current date/time]
```

**If mode is "rollback":**
```markdown
## 🔄 Checklist Rollback

**Progress**: X% → Y% (-Z%)

**Unmarked Items** (marked incomplete):
- ⏪ Task 2: Description
- ⏪ Task 3: Description

**Reason**: Incorrectly marked complete, rolling back for accuracy

**Timestamp**: [current date/time]
```

3. **Track version history** in comment:
   - Include previous state
   - Include new state
   - Record who made the change and why

### Step 8: Display Confirmation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Checklist Updated Successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: $1
🔗 Linear: [issue URL]

📊 Progress: X% → Y% (+Z%)

✅ Marked Complete (N items):
  • Task 2: Description
  • Task 3: Description

📝 Updated in Linear:
  ✅ Issue description updated
  ✅ Progress comment added

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. ⭐ Continue Implementation
   /ccpm:implementation:next $1

2. Sync Progress
   /ccpm:implementation:sync $1

3. Run Quality Checks
   /ccpm:verification:check $1

4. View Updated Status
   /ccpm:utils:status $1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Helper Functions (Inline Logic)

### Parse Checklist

**Pseudocode:**
```
1. Get description text
2. Find start marker: <!-- ccpm-checklist-start -->
3. Find end marker: <!-- ccpm-checklist-end -->
4. If markers found:
   - Extract lines between markers
5. Else:
   - Find "## ✅ Implementation Checklist" or "## Implementation Checklist"
   - Extract lines until next ## header
6. Filter lines that match: /^- \[([ x])\] (.+)$/
7. Parse each line:
   - Extract checkbox state: [ ] or [x]
   - Extract content after checkbox
   - Store index, state, content
8. Return array of checklist items
```

### Calculate Completion

**Pseudocode:**
```
1. Count total items
2. Count checked items (- [x])
3. Calculate percentage: (checked / total) * 100
4. Round to nearest integer
5. Return percentage and counts
```

### Update Checklist Items

**Pseudocode:**
```
1. Get current description
2. Parse checklist (get start/end positions)
3. For each index in indices_to_complete:
   - Find line in checklist section
   - Replace "- [ ]" with "- [x]"
4. Calculate new completion %
5. Find or create progress line
6. Update progress line with new %
7. Add/update timestamp
8. Return modified description
```

## Rollback Capability (Built-in)

The rollback feature is now fully integrated into the main workflow (Step 4):

**Features:**
- ✅ Two-mode operation: Complete or Rollback
- ✅ Rollback shows only checked items
- ✅ Complete shows only unchecked items
- ✅ Version history tracked in comments
- ✅ Clear reasoning documented

**Use Cases:**
- Accidentally marked wrong item complete
- Item thought complete but needs more work
- Task requirements changed, no longer complete
- Quality issues discovered after marking complete

## Examples

### Example 1: Mark Multiple Items Complete

```bash
/ccpm:utils:update-checklist PSN-26
```

**Interactive Flow:**
```
Current Progress: 20% (1/5 completed)

Which items did you complete?
[x] 0: Create checklist parser functions
[ ] 2: Modify /ccpm:implementation:sync
[ ] 3: Modify /ccpm:implementation:update

→ User selects items 0 and 2

✅ Updated! Progress: 20% → 60% (+40%)
```

### Example 2: No Changes Needed

```bash
/ccpm:utils:update-checklist PSN-26
```

**Interactive Flow:**
```
Current Progress: 100% (5/5 completed)

All items complete! ✅

No changes needed.
```

### Example 3: Rollback Mistake

```bash
/ccpm:utils:update-checklist PSN-26
```

**Interactive Flow:**
```
What would you like to do?
( ) Mark items complete
(●) Rollback items

Which items were incorrectly marked complete?
[x] 3: Modify /ccpm:implementation:update
[x] 4: Modify /ccpm:verification:check

→ User selects items 3 and 4

✅ Rolled back! Progress: 80% → 40% (-40%)

Comment added:
"🔄 Checklist Rollback
Unmarked: Task 3, Task 4
Reason: Incorrectly marked complete, rolling back for accuracy"
```

## Notes

- **Idempotent**: Running multiple times is safe
- **Atomic**: Either all updates succeed or none
- **Tracked**: Every change creates a comment for history
- **Visible**: Progress visible in description, not just comments
- **Flexible**: Works with or without marker comments

## Integration with Other Commands

This command provides the core checklist update logic that other commands can reference:

- `/ccpm:implementation:sync` - Auto-suggest completed items based on git diff
- `/ccpm:implementation:update` - Update specific item by index
- `/ccpm:verification:check` - Check completion % before verification
- `/ccpm:complete:finalize` - Require 100% before finalization
