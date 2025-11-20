---
description: Search and list tasks from a project by text query
allowed-tools: [LinearMCP]
argument-hint: <project> <search-query>
---

# Search Tasks in Project: $1

Searching for tasks matching: **$2**

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation.

- ✅ **Linear** operations are permitted (internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Project Context

**Project Mapping**:

- **my-app** → Linear Team: "Work", Project: "My App"
- **my-project** → Linear Team: "Work", Project: "My Project"
- **personal-project** → Linear Team: "Personal", Project: "Personal Project"

## Workflow

### Step 1: Parse Arguments

Extract:
- `$1` = Project identifier (my-app, my-project, or personal-project)
- `$2+` = Search query (all remaining arguments joined with spaces)

### Step 2: Search Issues

Use **Linear MCP** `list_issues` with:

```javascript
{
  query: "$2",              // Search in title and description
  project: "$1",            // Filter by project
  includeArchived: false,   // Exclude archived by default
  limit: 50,                // Return up to 50 results
  orderBy: "updatedAt"      // Most recently updated first
}
```

### Step 3: Display Results

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Search Results: "$2"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Project: $1
🔎 Query: $2
📊 Found: [N] issue(s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[For each issue, display:]

1. [WORK-123] 📌 [Status Emoji] [Title]
   Status: [Current Status]  |  Progress: [X/Y] subtasks ([%]%)
   Labels: [label1, label2, ...]
   Updated: [Relative time - e.g., "2 hours ago", "3 days ago"]

   📝 Description preview:
   [First 2 lines of description...]

   🔗 Actions:
   - View: /ccpm:utils:status WORK-123
   - Context: /ccpm:utils:context WORK-123
   - Start: /ccpm:implementation:start WORK-123

   ─────────────────────────────────────────────────────

2. [WORK-124] 📌 [Status Emoji] [Title]
   [... same format ...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Status Emojis**:
- 📦 = Backlog
- 📝 = Planning
- ⏳ = In Progress
- 🔍 = Verification
- 🚫 = Blocked (has "blocked" label)
- ✅ = Done

### Step 4: Handle Empty Results

If no issues found:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Search Results: "$2"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Project: $1
🔎 Query: $2
📊 Found: 0 issues

❌ No issues found matching "$2"

💡 Tips:
- Try broader search terms
- Check spelling
- Try searching in all projects (omit project parameter)
- View all project tasks: /ccpm:utils:report $1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5: Interactive Next Actions

**READ**: `/Users/duongdev/.claude/commands/pm/utils/_shared.md`

Use **AskUserQuestion** tool:

```javascript
{
  questions: [{
    question: "What would you like to do next?",
    header: "Next Action",
    multiSelect: false,
    options: [
      {
        label: "View Task Details",
        description: "View full details of a specific task from results"
      },
      {
        label: "Load Task Context",
        description: "Load task context to start working on it"
      },
      {
        label: "Refine Search",
        description: "Search again with different query"
      },
      {
        label: "View Project Report",
        description: "See full project report (/ccpm:utils:report)"
      }
    ]
  }]
}
```

**Execute based on choice**:

- If "View Task Details" → Ask which issue ID and run `/ccpm:utils:status <id>`
- If "Load Task Context" → Ask which issue ID and run `/ccpm:utils:context <id>`
- If "Refine Search" → Ask for new search query and re-run search
- If "View Project Report" → Run `/ccpm:utils:report $1`
- If "Other" → Show quick commands and exit

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

View Task:     /ccpm:utils:status <issue-id>
Load Context:  /ccpm:utils:context <issue-id>
Start Work:    /ccpm:implementation:start <issue-id>
Project Report: /ccpm:utils:report $1
New Search:    /ccpm:utils:search $1 "<new-query>"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Advanced Search Options

### Search by Status

Combine with status filters:

```bash
# Search for "auth" tasks in "In Progress" status
/ccpm:utils:search my-app "auth"
# Then manually filter by status in results
```

### Search Across All Projects

Omit project parameter to search all projects:

```bash
# Search all projects
/ccpm:utils:search "" "authentication"
# Note: Empty string for project searches all
```

### Search by Keywords

Common search patterns:

- Feature name: `/ccpm:utils:search my-project "user profile"`
- Bug description: `/ccpm:utils:search my-app "crash"`
- Technical term: `/ccpm:utils:search personal-project "API"`
- Label/tag: `/ccpm:utils:search my-project "backend"`

## Notes

### Search Behavior

- Searches both title AND description
- Case-insensitive
- Partial word matching
- Ordered by most recently updated
- Excludes archived issues by default

### Result Limit

- Returns up to 50 results maximum
- If more exist, shows "50+ issues found"
- Refine search query for better targeting

### Usage Examples

```bash
# Search for authentication tasks in My App
/ccpm:utils:search my-app "authentication"

# Search for UI-related tasks in My Project
/ccpm:utils:search my-project "UI component"

# Search for bug fixes in Personal Project
/ccpm:utils:search personal-project "bug fix"

# Search all projects for "Redis"
/ccpm:utils:search "" "Redis"
```

### Performance

- Fast search via Linear API
- Results appear immediately
- No local caching needed
- Always shows latest data

### Complementary Commands

- `/ccpm:utils:report <project>` - See all project tasks by status
- `/ccpm:utils:status <id>` - View full task details
- `/ccpm:utils:context <id>` - Load task context for work
