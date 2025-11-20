---
description: Load task context quickly - fetch issue, related files, and set up environment
allowed-tools: [Bash, LinearMCP, Read, Glob]
argument-hint: <linear-issue-id>
---

# Loading Context for: $1

Quickly loading all context for Linear issue **$1** to help you resume work.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Workflow

### Step 1: Fetch Linear Issue Details

Use **Linear MCP** to get full issue details:

1. Title, description, status, labels
2. Full checklist with progress
3. All comments and activity
4. Related issues (parent, sub-issues)
5. Assignee, dates, project info

### Step 1.5: Display Attached Images

**READ**: `commands/_shared-image-analysis.md`

If the issue has attached images, display them:

```javascript
const images = detectImages(issue)
if (images.length > 0) {
  console.log("📎 Attached Images (" + images.length + "):")
  images.forEach((img, i) => {
    console.log(`  ${i+1}. ${img.title} (${img.type.toUpperCase()}) - ${img.url}`)
  })
}
```

**Note**: Images may contain UI mockups, architecture diagrams, or screenshots that provide visual context for the task.


### Step 2: Extract Context from Description

Parse the description to extract:

**Files Mentioned**:

- Look for code file paths (e.g., `src/api/auth.ts`, `components/Login.tsx`)
- Look for file patterns (e.g., `*.test.ts`, `api/**/*.js`)
- Extract all file references from implementation plan

**Related Links**:

- Jira tickets (extract URLs)
- Confluence pages (extract URLs)
- Slack threads (extract URLs)
- BitBucket PRs (extract URLs)
- Linear issues (extract issue IDs)

**Key Sections**:

- Current architecture
- Implementation approach
- Technical constraints
- Best practices
- Cross-repository dependencies

### Step 3: Load Relevant Files

Use **Glob** and **Read** tools to:

1. Find all mentioned files in the codebase
2. Read key files (limited to first 100 lines each)
3. Display file summaries

```
📂 Relevant Files Found:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. src/api/auth.ts (145 lines)
   Purpose: [Inferred from description or filename]
   Status: [To be modified/new file/reference only]

2. src/components/Login.tsx (89 lines)
   Purpose: [Inferred from description]
   Status: [To be modified]

3. src/middleware/jwt.ts (67 lines)
   Purpose: [Inferred from description]
   Status: [To be created]

[... up to 10 most relevant files ...]
```

### Step 4: Analyze Current Progress

Calculate and display progress:

```javascript
const progress = {
  total: checklistItems.length,
  completed: checklistItems.filter(i => i.checked).length,
  inProgress: checklistItems.filter(i => i.status === 'in_progress').length,
  blocked: checklistItems.filter(i => i.status === 'blocked').length,
  remaining: checklistItems.filter(i => !i.checked).length,
  percentage: Math.round((completed / total) * 100)
}
```

### Step 5: Display Complete Context

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Context Loaded: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏷️  Title: [Full title]
📊 Status: [Current status]
🎯 Progress: [X/Y] subtasks ([%]%)
⏱️  Time in status: [Duration]
🏷️  Labels: [Comma-separated labels]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[First paragraph from Context section of description]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Checklist Progress
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Completed ([X]):
✅ Subtask 1: [Description]
✅ Subtask 2: [Description]

In Progress ([Y]):
⏳ Subtask 3: [Description]

Remaining ([Z]):
⬜ Subtask 4: [Description]
⬜ Subtask 5: [Description]

Blocked ([N]):
🚫 Subtask 6: [Description] - [Blocker reason]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📂 Files to Work On
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[List from Step 3 above]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 Related Links
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Jira: [TRAIN-123](link)
Confluence: [PRD](link), [Design Doc](link)
Slack: [Discussion](link)
PRs: [PR #789](link)
Related Issues: [WORK-456](link)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Implementation Approach
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Extracted from Implementation Plan section]

Key Points:
- [Point 1]
- [Point 2]
- [Point 3]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Important Considerations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Technical Constraints:
- [Constraint 1]
- [Constraint 2]

Best Practices:
- [Practice 1]
- [Practice 2]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬 Recent Activity
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Last 3 comments with timestamps and authors]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 6: Interactive Next Actions

**READ**: ``$CCPM_COMMANDS_DIR/_shared-linear-helpers.md``

Determine next action based on status and progress:

```javascript
// If status is Planning
if (status === 'Planning') {
  suggestOptions = [
    "Start Implementation",
    "Get AI Insights",
    "Auto-Assign Agents",
    "Just Review"
  ]
}

// If status is In Progress
if (status === 'In Progress') {
  if (hasIncompleteTask) {
    suggestOptions = [
      "Continue Next Task",
      "Update Progress",
      "Check Quality (if ready)",
      "Just Review"
    ]
  } else {
    suggestOptions = [
      "Run Quality Checks",
      "Update Last Task",
      "Just Review"
    ]
  }
}

// If status is Verification
if (status === 'Verification') {
  suggestOptions = [
    "Run Verification",
    "Check Quality First",
    "Just Review"
  ]
}

// If blocked
if (labels.includes('blocked')) {
  suggestOptions = [
    "Fix Issues",
    "View Status",
    "Rollback Changes",
    "Just Review"
  ]
}

// If done
if (status === 'Done') {
  suggestOptions = [
    "Finalize Task",
    "Create New Task",
    "Just Review"
  ]
}
```

Use **AskUserQuestion** tool with detected options.

**Execute based on choice** or show quick commands and exit.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:        /ccpm:utils:status $1
Next:          /ccpm:implementation:next $1
Start:         /ccpm:implementation:start $1
Update:        /ccpm:implementation:update $1 <idx> <status> "msg"
Check:         /ccpm:verification:check $1
Verify:        /ccpm:verification:verify $1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

### When to Use

- **Starting your work day** - Quick recap of what you're working on
- **Switching between tasks** - Fast context switch
- **After a break** - Remember where you left off
- **Code review** - Understand the full context quickly
- **Onboarding** - Get up to speed on a task

### What It Does

✅ Fetches full Linear issue
✅ Extracts all relevant files
✅ Shows progress at a glance
✅ Provides related links
✅ Displays key implementation points
✅ Shows recent activity
✅ Suggests next actions

### Usage

```bash
# Load context for any task
/ccpm:utils:context WORK-123

# Quick resume after break
/ccpm:utils:context WORK-123

# Switch to different task
/ccpm:utils:context WORK-456
```

### Benefits

- ⚡ **Fast** - No manual searching
- 🎯 **Focused** - Only relevant information
- 🔄 **Resumable** - Easy to pick up where you left off
- 📋 **Complete** - All context in one view
- 🤖 **Interactive** - Suggests what to do next

### Step 1.6: Display Figma Design Links

**READ**: `commands/_shared-figma-detection.md`

If the issue contains Figma design links, display them for easy access:

```bash
# Detect Figma links from Linear issue
LINEAR_DESC=$(linear_get_issue "$1" | jq -r '.description')
LINEAR_COMMENTS=$(linear_get_issue "$1" | jq -r '.comments[] | .body' || echo "")
FIGMA_LINKS=$(./scripts/figma-utils.sh extract-markdown "$LINEAR_DESC $LINEAR_COMMENTS")
FIGMA_COUNT=$(echo "$FIGMA_LINKS" | jq 'length')

if [ "$FIGMA_COUNT" -gt 0 ]; then
  echo ""
  echo "🎨 Figma Designs ($FIGMA_COUNT):"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Display each Figma design with details
  echo "$FIGMA_LINKS" | jq -r '.[] | "\n  📐 \(.file_name)\n  🔗 \(.canonical_url)\n  📍 Node: \(.node_id // "Full file")\n  🎯 Type: \(.type)"'
  
  # Show quick access command
  echo ""
  echo "💡 Quick Access:"
  echo "  • Open in Figma: Click URLs above"
  echo "  • Refresh cache: /ccpm:utils:figma-refresh $1 (Phase 2)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  echo ""
  echo "ℹ️  No Figma designs found in this issue"
fi
```

**Figma Context Display Format**

```
🎨 Figma Designs (2):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  📐 Login Screen Design
  🔗 https://www.figma.com/file/ABC123
  📍 Node: 1-2
  🎯 Type: file

  📐 Dashboard Mockup
  🔗 https://www.figma.com/design/XYZ789
  📍 Node: Full file
  🎯 Type: design

💡 Quick Access:
  • Open in Figma: Click URLs above
  • Refresh cache: /ccpm:utils:figma-refresh PSN-25 (Phase 2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Integration with Image Context**

Display both images and Figma designs together:

```javascript
// After Step 1.5 (Display Attached Images)
// Add Step 1.6 (Display Figma Designs)

const visualResources = {
  images: images.length,
  figma: figmaLinks.length,
  total: images.length + figmaLinks.length
}

if (visualResources.total > 0) {
  console.log(`\n📊 Visual Resources Summary: ${visualResources.total} total`)
  console.log(`  • Static Images: ${visualResources.images} (snapshots, mockups)`)
  console.log(`  • Figma Designs: ${visualResources.figma} (live, authoritative)`)
  console.log(`\n💡 Use Figma as primary source, images for quick reference`)
}
```

**Why This Matters**:
- **Quick Access**: All design resources visible immediately when loading context
- **Context Awareness**: Understand what visual resources are available
- **Design Priority**: Figma = authoritative, images = supplementary
- **Efficiency**: No need to search through Linear comments for design links

**Performance**: Figma link detection adds <100ms to context loading.

