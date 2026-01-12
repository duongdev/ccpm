# Issue Hierarchy Helper

This file provides utilities for fetching and displaying parent/sibling context for subissues.

## Overview

When working on a subissue (an issue with a parent), it's helpful to have context from:
1. **Parent issue** - The overall goal and requirements
2. **Sibling subissues** - Related work being done, patterns to follow, conflicts to avoid

## Functions

### 1. getIssueHierarchy

Fetches issue with parent and sibling context via the `ccpm:linear-operations` subagent.

**Usage:**
```javascript
// In /ccpm:plan or /ccpm:work command:

Task(ccpm:linear-operations): `
operation: get_issue_hierarchy
params:
  issueId: ${issueId}
  includeParent: true
  includeSiblings: true
  siblingLimit: 10
context:
  cache: true
  command: "plan"
`

// Response structure:
const hierarchyData = {
  issue: { /* current issue */ },
  parent: { /* parent issue or null */ },
  siblings: [ /* sibling issues */ ],
  hierarchy: {
    isSubissue: true,
    parentIdentifier: "PSN-100",
    siblingCount: 3,
    position: 2
  }
};
```

### 2. formatParentContext

Formats parent issue context for display and agent prompts.

**Display Format:**
```
## 🔗 Parent Issue Context

**Parent**: PSN-100 - User Authentication Feature
**Status**: In Progress
**Progress**: 60% (3/5 tasks)
**Labels**: feature, backend, auth

### Parent Goal
Implement complete authentication flow with JWT tokens and OAuth support...

### Parent Checklist Progress
- [x] Design auth API endpoints
- [x] Implement JWT token service
- [ ] Add OAuth providers (← you are here)
- [ ] Create password reset flow
- [ ] Write integration tests
```

**Token-Optimized Format (for agent prompts):**
```
**Parent Goal**: ${parent.title}
**Parent Progress**: ${parent.checklist.progress}% complete (${parent.checklist.completed}/${parent.checklist.total} tasks)
**Context**: This task is part of "${parent.title}" which aims to ${parentGoalSummary}
```

### 3. formatSiblingsContext

Formats sibling subissues for display, grouped by status.

**Display Format:**
```
## 👥 Sibling Subissues (4)

### ✅ Completed (2)
- **PSN-101**: Design auth API endpoints
  - Pattern: Used OpenAPI spec, REST conventions
- **PSN-102**: Implement JWT token service
  - Pattern: jsonwebtoken library, refresh token rotation

### 🔄 In Progress (1)
- **PSN-103**: Add OAuth providers (50%)
  - Working on: Google OAuth integration

### ⏳ Pending (1)
- **PSN-105**: Write integration tests
```

**Token-Optimized Format (for agent prompts):**
```
**Sibling Status**: 2 done, 1 in progress, 1 pending

**Completed Siblings (reference for patterns)**:
- PSN-101: Design auth API endpoints
- PSN-102: Implement JWT token service

**In-Progress Siblings (avoid conflicts)**:
- PSN-103: Add OAuth providers

**Pending Siblings**:
- PSN-105: Write integration tests
```

### 4. formatHierarchyForAgent

Formats complete hierarchy context for agent prompts (token-optimized).

**Full Format (for planning agents):**
```markdown
## 📊 Issue Hierarchy Context

This is **subissue 3** of **5** under parent **PSN-100**.

### 🔗 Parent Issue
**Goal**: User Authentication Feature
**Status**: In Progress (60% complete)

**Parent Description** (for overall context):
${parent.description.substring(0, 800)}

**Parent Checklist** (overall progress):
${parent.checklist.items.map(i => `- [${i.checked ? 'x' : ' '}] ${i.content}`).join('\n')}

### 👥 Sibling Context

**Completed Siblings** (follow these patterns):
${completedSiblings.map(s => `- ${s.identifier}: ${s.title}`).join('\n')}

**In-Progress Siblings** (coordinate to avoid conflicts):
${inProgressSiblings.map(s => `- ${s.identifier}: ${s.title}`).join('\n')}

### Why This Matters for Your Task
- Consider how this task fits into the parent's overall goal
- Look at completed siblings for patterns and conventions established
- Avoid duplicating work done in other siblings
- Ensure consistency with sibling implementations
```

**Compact Format (for implementation agents):**
```markdown
## 📊 Subissue Context

**Parent**: PSN-100 - User Authentication Feature (60% complete)
**Position**: Subissue 3 of 5

**Completed siblings to reference**:
- PSN-101, PSN-102

**In-progress siblings (coordinate)**:
- PSN-103
```

## Integration Points

### In /ccpm:plan

Add after fetching the issue (Step 2B.1):

```javascript
// Step 2.3: Fetch Issue Hierarchy Context
Task(ccpm:linear-operations): `
operation: get_issue_hierarchy
params:
  issueId: ${issueId}
  includeParent: true
  includeSiblings: true
  siblingLimit: 10
context:
  cache: true
  command: "plan"
`

if (hierarchyData.hierarchy.isSubissue) {
  console.log(`\n📊 Subissue detected: Part of ${hierarchyData.hierarchy.parentIdentifier}`);
  console.log(`   Parent: ${hierarchyData.parent.title}`);
  console.log(`   Siblings: ${hierarchyData.hierarchy.siblingCount} other subissues`);

  // Store for agent prompts
  issue.hierarchyContext = hierarchyData;
}
```

Include in planning agent prompt:
```
${issue.hierarchyContext ? `
## 📊 Parent Issue Context

This task is a SUBISSUE of: **${issue.hierarchyContext.parent.identifier} - ${issue.hierarchyContext.parent.title}**

**Parent Description**:
${issue.hierarchyContext.parent.description?.substring(0, 800) || 'No description'}

**Parent Checklist** (for context on overall goal):
${formatParentChecklist(issue.hierarchyContext.parent.checklist)}

## 👥 Sibling Subissues

${formatSiblingsForAgent(issue.hierarchyContext.siblings)}

**WHY THIS MATTERS FOR PLANNING:**
- Consider how this task fits into the parent's overall goal
- Look at completed siblings for patterns and conventions
- Avoid duplicating work done in other siblings
- Ensure consistency with sibling implementations
` : ''}
```

### In /ccpm:work

Add as Step 3.6 after fetching comments:

```javascript
// Step 3.6: Fetch Issue Hierarchy Context (for Subissues)
Task(ccpm:linear-operations): `
operation: get_issue_hierarchy
params:
  issueId: ${issue.identifier}
  includeParent: true
  includeSiblings: true
  siblingLimit: 10
context:
  cache: true
  command: "work"
`

if (hierarchyData.hierarchy.isSubissue) {
  console.log(`\n📊 Subissue of: ${hierarchyData.parent.identifier} - ${hierarchyData.parent.title}`);

  // Show sibling summary
  const completed = hierarchyData.siblings.filter(s =>
    ['Done', 'Completed'].includes(s.state.name)
  ).length;
  console.log(`   Siblings: ${completed}/${hierarchyData.siblings.length} completed`);

  // Cache for subagent injection
  issueCache.hierarchyContext = {
    parent: {
      identifier: hierarchyData.parent.identifier,
      title: hierarchyData.parent.title,
      description: hierarchyData.parent.description,
      checklist: hierarchyData.parent.checklist,
      attachments: hierarchyData.parent.attachments
    },
    siblings: hierarchyData.siblings.map(s => ({
      identifier: s.identifier,
      title: s.title,
      state: s.state.name,
      checklist: s.checklist
    })),
    position: hierarchyData.hierarchy.position,
    siblingCount: hierarchyData.hierarchy.siblingCount
  };

  // Write to cache file for subagent-context-injector
  fs.writeFileSync(
    `/tmp/ccpm-issue-${issue.identifier}.json`,
    JSON.stringify(issueCache, null, 2)
  );

  console.log(`📦 Hierarchy context cached for subagents`);
}
```

### In SubagentStart Hook

The `subagent-context-injector.cjs` reads the cached hierarchy context and includes it in agent prompts:

```javascript
// In formatIssueContext function, after existing fields:

if (issue.hierarchyContext) {
  const hierarchy = issue.hierarchyContext;

  context += '## 📊 Issue Hierarchy Context\n\n';
  context += `**Parent Issue**: ${hierarchy.parent.identifier} - ${hierarchy.parent.title}\n`;
  context += `**Position**: Subissue ${hierarchy.position} of ${hierarchy.siblingCount + 1}\n\n`;

  // Completed siblings (for pattern reference)
  const completedSiblings = hierarchy.siblings.filter(s =>
    ['Done', 'Completed'].includes(s.state)
  );
  if (completedSiblings.length > 0) {
    context += '**Completed Siblings** (reference for patterns):\n';
    completedSiblings.forEach(s => {
      context += `- ${s.identifier}: ${s.title}\n`;
    });
    context += '\n';
  }

  // In-progress siblings (avoid conflicts)
  const inProgressSiblings = hierarchy.siblings.filter(s =>
    s.state === 'In Progress'
  );
  if (inProgressSiblings.length > 0) {
    context += '**In-Progress Siblings** (coordinate to avoid conflicts):\n';
    inProgressSiblings.forEach(s => {
      context += `- ${s.identifier}: ${s.title}\n`;
    });
    context += '\n';
  }
}
```

## Token Budget Guidelines

| Data | Max Size | Reason |
|------|----------|--------|
| Parent description | 800 chars | Context, not full spec |
| Parent checklist | 10 items max | Overview of parent scope |
| Sibling descriptions | 200 chars each | Just enough for context |
| Max siblings | 10 | Avoid context bloat |

## Error Handling

### Parent not found
If `parentId` exists but parent issue is deleted/inaccessible:
```
⚠️ Parent issue (PSN-100) not accessible
Continuing without parent context...
```

### API timeout on sibling fetch
```
⚠️ Could not fetch sibling context (timeout)
Parent context loaded successfully.
```

### Too many siblings
If parent has >20 children, truncate:
```
👥 Showing 10 of 25 siblings (most recent)
```
