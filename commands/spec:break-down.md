---
description: Break down Epic/Feature into Features/Tasks based on spec
allowed-tools: [LinearMCP, AskUserQuestion]
argument-hint: <epic-or-feature-id>
---

# Break Down: $1

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

---

## Shared Helpers

**READ**: `commands/_shared-linear-helpers.md`

This command uses the following helper functions:
- `ensureLabelsExist()` - Ensure labels exist before using them
- `getOrCreateLabel()` - Create or retrieve individual labels

---

## Argument

- **$1** - Epic ID (to break into Features) or Feature ID (to break into Tasks)

## Workflow

### Step 1: Fetch Issue and Determine Type

Use **Linear MCP** `get_issue` with ID `$1`:

- Get issue details
- Check if it's an Epic/Initiative or Feature (parent issue)
- Find linked spec document
- Get project/team information

```javascript
const issueType = determineType(issue)

function determineType(issue) {
  // Check if issue is an Initiative (Epic)
  if (issue.type === 'initiative' || issue.project?.type === 'initiative') {
    return 'epic'
  }

  // Check if issue has sub-issues (Feature)
  if (issue.children && issue.children.length > 0) {
    return 'feature'
  }

  // Check labels
  if (issue.labels.includes('epic')) return 'epic'
  if (issue.labels.includes('feature')) return 'feature'

  // Default: treat as feature
  return 'feature'
}
```

### Step 2: Fetch Spec Document

Extract spec document link from issue description:

```javascript
// Look for pattern: [Epic Spec: Title](url) or [Feature Design: Title](url)
const docLinkPattern = /\[(?:Epic Spec|Feature Design): .+?\]\((.+?)\)/

const match = issue.description.match(docLinkPattern)
if (match) {
  const docUrl = match[1]
  // Extract doc ID from URL
  const docId = extractDocId(docUrl)
}
```

Use **Linear MCP** `get_document` to fetch spec content.

### Step 3: Analyze Spec and Generate Breakdown

#### If Breaking Down EPIC → Features

**Parse Epic Spec:**

Look for "Features Breakdown" section in spec document.

```markdown
## 📊 Features Breakdown

| Feature | Priority | Complexity | Est. Timeline |
|---------|----------|------------|---------------|
| JWT Auth | P0 | High | 2 weeks |
| OAuth Integration | P1 | Medium | 1 week |
| MFA Support | P2 | Low | 3 days |
```

**AI Analysis:**

```javascript
const features = []

// Parse table
for (const row of featureTable) {
  const feature = {
    title: row.feature,
    priority: row.priority, // P0, P1, P2
    complexity: row.complexity, // High, Medium, Low
    estimate: row.estimate,
    description: generateDescription(row.feature, epicContext)
  }
  features.push(feature)
}

// Generate additional features if not in table
// Analyze epic requirements and suggest missing features
const suggestedFeatures = analyzeRequirements(epicSpec)
features.push(...suggestedFeatures)
```

**Create Feature Issues:**

For each feature:

```javascript
// Ensure required labels exist before creating issues
const featureLabels = await ensureLabelsExist(epic.team.id,
  ['feature', 'spec:draft'],
  {
    descriptions: {
      'feature': 'Feature-level work item',
      'spec:draft': 'Specification in draft state'
    }
  }
);

{
  title: feature.title,
  team: epic.team,
  project: epic.project,
  parent: epic.id, // Link to epic
  labelIds: featureLabels, // Use validated label IDs
  priority: mapPriority(feature.priority), // P0=1, P1=2, P2=3, P3=4
  description: `
## 📄 Specification

**Feature Design Doc**: [Will be created] ← Use /ccpm:spec:write to populate

**Parent Epic**: [${epic.title}](${epic.url})
**Epic Spec**: [Link to epic spec doc]

---

## 🎯 Overview

${feature.description}

## 📋 Initial Requirements

[AI generates based on epic context and feature title]

## ⏱️ Estimate

**Complexity**: ${feature.complexity}
**Timeline**: ${feature.estimate}

---

**Next Steps:**
1. Run /ccpm:spec:write to create detailed feature design
2. Run /ccpm:spec:review to validate completeness
3. Run /ccpm:spec:break-down to create implementation tasks
  `
}
```

#### If Breaking Down FEATURE → Tasks

**Parse Feature Design:**

Look for "Implementation Plan" or "Task Breakdown" section:

```markdown
## 🚀 Implementation Plan

### Task Breakdown
- [ ] **Task 1: Database schema**: Create user_auth table with migrations (Est: 2h)
- [ ] **Task 2: API endpoints**: POST /login, /logout, /refresh (Est: 4h)
- [ ] **Task 3: Frontend integration**: Login screen + auth context (Est: 6h)
- [ ] **Task 4: Testing**: Unit + integration tests (Est: 4h)
```

**AI Analysis:**

```javascript
const tasks = []

// Parse task list
for (const item of taskList) {
  const task = {
    title: extractTitle(item), // "Database schema"
    description: extractDescription(item), // "Create user_auth table..."
    estimate: extractEstimate(item), // "2h"
    dependencies: extractDependencies(item) // If mentioned
  }
  tasks.push(task)
}

// Analyze dependencies
const dependencyGraph = buildDependencyGraph(tasks)

// Suggest additional tasks if missing
const suggestedTasks = analyzeMissingTasks(featureSpec, tasks)
// Example: Missing documentation task, missing E2E test task
tasks.push(...suggestedTasks)
```

**Create Task Issues (as Sub-Issues):**

For each task:

```javascript
// Ensure required labels exist before creating tasks
const taskLabels = await ensureLabelsExist(feature.team.id,
  ['task', 'planning'],
  {
    descriptions: {
      'task': 'Implementation task',
      'planning': 'Task in planning phase'
    }
  }
);

{
  title: task.title,
  team: feature.team,
  project: feature.project,
  parent: feature.id, // Link to feature as sub-issue
  labelIds: taskLabels, // Use validated label IDs
  estimate: convertToPoints(task.estimate), // 2h → 1 point, 4h → 2 points
  description: `
## 📋 Task Description

${task.description}

---

## 📄 Related Spec

**Feature**: [${feature.title}](${feature.url})
**Feature Design**: [Link to design doc]

---

## 🎯 Acceptance Criteria

[AI generates based on task title and feature requirements]

- [ ] Criterion 1
- [ ] Criterion 2

---

## ⏱️ Estimate

**Time**: ${task.estimate}
**Complexity**: [Low/Medium/High based on estimate]

---

## 🔗 Dependencies

${task.dependencies ? `Depends on: ${task.dependencies.map(d => `[Task ${d}]`).join(', ')}` : 'No dependencies'}

---

**Next Steps:**
1. Run /ccpm:planning:plan to gather implementation research
2. Run /ccpm:implementation:start when ready to begin work
  `
}
```

### Step 4: Show Preview

Before creating, show preview to user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Breakdown Preview: [$1]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Type: [Epic → Features / Feature → Tasks]
📄 Spec: [DOC-XXX]
🔢 Items to Create: [N]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Breakdown Items
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[If Epic → Features:]

1. **JWT Auth** (P0, High Complexity)
   - Timeline: 2 weeks
   - Description: Implement JWT-based authentication...

2. **OAuth Integration** (P1, Medium Complexity)
   - Timeline: 1 week
   - Description: Add OAuth 2.0 support for Google, GitHub...

3. **MFA Support** (P2, Low Complexity)
   - Timeline: 3 days
   - Description: Two-factor authentication with TOTP...

[If Feature → Tasks:]

1. **Database schema** (Est: 2h)
   - Description: Create user_auth table with migrations
   - Dependencies: None

2. **API endpoints** (Est: 4h)
   - Description: POST /login, /logout, /refresh
   - Dependencies: Task 1

3. **Frontend integration** (Est: 6h)
   - Description: Login screen + auth context
   - Dependencies: Task 2

4. **Testing** (Est: 4h)
   - Description: Unit + integration tests
   - Dependencies: Task 3

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Items: [N]
Total Estimate: [X hours / Y days]
Critical Path: [Task sequence]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5: Confirm Creation

Use **AskUserQuestion**:

```javascript
{
  questions: [{
    question: "Create these [N] [features/tasks] in Linear?",
    header: "Confirm",
    multiSelect: false,
    options: [
      {
        label: "Yes, Create All",
        description: "Create all [N] items as shown above"
      },
      {
        label: "Let Me Edit First",
        description: "I want to modify the breakdown in the spec doc first"
      },
      {
        label: "Cancel",
        description: "Don't create anything"
      }
    ]
  }]
}
```

### Step 6: Create Issues in Linear

If user confirms:

```javascript
const createdIssues = []

try {
  // Ensure labels exist once before creating all issues
  // (Labels are reused across all items in the breakdown)
  const labels = isEpicBreakdown
    ? await ensureLabelsExist(parentIssue.team.id,
        ['feature', 'spec:draft'],
        {
          descriptions: {
            'feature': 'Feature-level work item',
            'spec:draft': 'Specification in draft state'
          }
        }
      )
    : await ensureLabelsExist(parentIssue.team.id,
        ['task', 'planning'],
        {
          descriptions: {
            'task': 'Implementation task',
            'planning': 'Task in planning phase'
          }
        }
      );

  for (const item of breakdownItems) {
    const issue = await createLinearIssue({
      ...item,
      labelIds: labels // Use pre-validated labels
    })
    createdIssues.push(issue)

    // Brief pause to avoid rate limits
    await sleep(500)
  }
} catch (error) {
  console.error(`Failed to create issues: ${error.message}`);

  if (error.message.includes('label')) {
    throw new Error(
      `Label operation failed. Please check that you have permission to create labels in this team.\n` +
      `Error: ${error.message}`
    );
  }

  throw error;
}
```

**Update parent issue description** to include links to created children:

For Epic:
```markdown
## 🎨 Features

Created from spec breakdown:

- [Feature 1: JWT Auth](https://linear.app/workspace/issue/WORK-101)
- [Feature 2: OAuth Integration](https://linear.app/workspace/issue/WORK-102)
- [Feature 3: MFA Support](https://linear.app/workspace/issue/WORK-103)
```

For Feature:
```markdown
## ✅ Implementation Tasks

Created from spec breakdown:

- [Task 1: Database schema](https://linear.app/workspace/issue/WORK-201)
- [Task 2: API endpoints](https://linear.app/workspace/issue/WORK-202)
- [Task 3: Frontend integration](https://linear.app/workspace/issue/WORK-203)
- [Task 4: Testing](https://linear.app/workspace/issue/WORK-204)

**💡 Tip**: Use /ccpm:utils:dependencies to visualize task order
```

### Step 7: Display Results

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Breakdown Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Parent: [$1 - Title]
🔢 Created: [N] [Features/Tasks]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Created Items
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ WORK-101: JWT Auth (Feature, P0)
✅ WORK-102: OAuth Integration (Feature, P1)
✅ WORK-103: MFA Support (Feature, P2)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Suggested Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 8: Interactive Next Actions

```javascript
{
  questions: [{
    question: "Breakdown complete! What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      // If broke down Epic → Features
      epicMode ? {
        label: "Write Feature Specs",
        description: "Start writing detailed design for first feature"
      } : {
        label: "Start Implementation",
        description: "Begin working on first task (/ccpm:implementation:start)"
      },
      {
        label: "View Dependencies",
        description: "Visualize task dependencies (/ccpm:utils:dependencies)"
      },
      {
        label: "Auto-Assign Agents",
        description: "AI-powered agent assignment (/ccpm:utils:auto-assign)"
      },
      {
        label: "View in Linear",
        description: "Open parent issue in Linear"
      }
    ]
  }]
}
```

## Estimation Conversion

```javascript
function convertToPoints(timeEstimate) {
  // Convert time estimates to Linear points
  const hours = parseHours(timeEstimate) // "2h" → 2, "1 day" → 8

  if (hours <= 2) return 1   // 1 point = 1-2 hours
  if (hours <= 4) return 2   // 2 points = 2-4 hours
  if (hours <= 8) return 3   // 3 points = 4-8 hours (1 day)
  if (hours <= 16) return 5  // 5 points = 1-2 days
  if (hours <= 40) return 8  // 8 points = 1 week
  return 13                  // 13 points = 2+ weeks
}

function mapPriority(priority) {
  // Linear priority: 1 = Urgent, 2 = High, 3 = Medium, 4 = Low, 0 = No priority
  const mapping = {
    'P0': 1,  // Urgent
    'P1': 2,  // High
    'P2': 3,  // Medium
    'P3': 4   // Low
  }
  return mapping[priority] || 0
}
```

## Dependency Detection

```javascript
function extractDependencies(taskDescription) {
  // Look for patterns:
  // - "depends on Task 1"
  // - "after Task 2"
  // - "requires Task 3"
  // - "(depends: 1, 2)"

  const patterns = [
    /depends on (?:Task )?(\d+)/gi,
    /after (?:Task )?(\d+)/gi,
    /requires (?:Task )?(\d+)/gi,
    /\(depends: ([\d, ]+)\)/gi
  ]

  const dependencies = []

  for (const pattern of patterns) {
    const matches = taskDescription.matchAll(pattern)
    for (const match of matches) {
      const taskNum = match[1]
      dependencies.push(parseInt(taskNum))
    }
  }

  return [...new Set(dependencies)] // Remove duplicates
}
```

## Notes

- Epic → Features creates Parent Issues
- Feature → Tasks creates Sub-Issues
- All created items link back to spec
- Dependencies are parsed and preserved
- Timeline estimates are converted to Linear points
- Priority mapping follows P0=Urgent, P1=High, etc.
- **Label Handling**: Uses shared Linear helpers from `_shared-linear-helpers.md`
  - Labels are validated/created once before batch issue creation
  - Features get labels: `['feature', 'spec:draft']`
  - Tasks get labels: `['task', 'planning']`
  - Graceful error handling if label creation fails
  - Automatic label reuse prevents duplicates
