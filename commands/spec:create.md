---
description: Create Epic/Feature/Initiative with Linear Document
allowed-tools: [LinearMCP, Read, AskUserQuestion]
argument-hint: <type> "<title>" [parent-id]
---

# Create Spec: $2

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

---

## Shared Utilities

**READ**: commands/_shared-linear-helpers.md

This provides helper functions for Linear integration:
- `ensureLabelsExist()` - Ensures labels exist, creates if missing
- `getValidStateId()` - Validates and resolves state IDs
- `getOrCreateLabel()` - Get or create single label
- `getDefaultColor()` - Standard CCPM colors

---

## Arguments

- **$1** - Type: `epic`, `feature`, or `initiative`
- **$2** - Title: The name of the epic/feature/initiative
- **$3** - (Optional) Parent ID: For feature (parent epic ID) or task (parent feature ID)

## Workflow

### Step 1: Validate Type and Hierarchy

**Type Mapping:**
```javascript
const typeMapping = {
  'epic': {
    linearType: 'initiative',  // Epics are Initiatives in Linear
    labelPrefix: 'epic',
    docTemplate: 'epic-spec',
    canHaveParent: false
  },
  'feature': {
    linearType: 'issue',       // Features are Parent Issues
    labelPrefix: 'feature',
    docTemplate: 'feature-design',
    canHaveParent: true,       // Can belong to Epic
    requiresProject: true
  },
  'initiative': {
    linearType: 'initiative',  // Same as epic (alias)
    labelPrefix: 'initiative',
    docTemplate: 'epic-spec',
    canHaveParent: false
  }
}
```

**Validation:**
- If type is `feature` and no parent provided → Ask user to select parent epic
- If type is `epic` or `initiative` → No parent needed

### Step 2: Load Project Configuration

**IMPORTANT**: Uses dynamic project configuration from `~/.claude/ccpm-config.yaml`.

```bash
# Try to use active project or auto-detect
PROJECT_ARG=""  # Will be auto-detected or prompted
```

**LOAD PROJECT CONFIG**: Follow instructions in `commands/_shared-project-config-loader.md`

This will:
1. Try to use active project from config
2. Try auto-detection (git remote, directory patterns)
3. If neither works, list available projects and prompt user

After loading, you'll have:
- `${PROJECT_ID}` - Selected project
- `${LINEAR_TEAM}`, `${LINEAR_PROJECT}` - For creating Linear entities
- All other project settings

### Step 3: Create Linear Entity

#### For Epic/Initiative:

**Step 1: Ensure labels exist**

```javascript
// Ensure required labels exist before creating entity
const labelNames = await ensureLabelsExist(
  projectMapping[project].team,
  ["epic", "spec:draft"],
  {
    descriptions: {
      "epic": "CCPM: Epic-level work item",
      "spec:draft": "CCPM: Specification in draft status"
    }
  }
);
```

**Step 2: Validate state (optional)**

If you need to set a specific initial state:

```javascript
// Optional: Validate state if setting non-default state
// const stateId = await getValidStateId(projectMapping[project].team, "planned");
```

**Step 3: Create initiative**

Use **Linear MCP** `create_project` or initiative creation:

```javascript
{
  name: $2,
  team: projectMapping[project].team,
  description: "Spec document: [DOC-XXX](link) (will be added after doc creation)",
  // status: "planned",  // Optional: Use default state or validated stateId
  labels: labelNames  // Use validated label names
}
```

**Note**: State is optional for initiatives. If you need a specific state, use `getValidStateId()` to validate it first.

#### For Feature (Parent Issue):

**Step 1: Ensure labels exist**

```javascript
// Ensure required labels exist before creating issue
const labelNames = await ensureLabelsExist(
  projectMapping[project].team,
  ["feature", "spec:draft"],
  {
    descriptions: {
      "feature": "CCPM: Feature-level work item",
      "spec:draft": "CCPM: Specification in draft status"
    }
  }
);
```

**Step 2: Create issue**

Use **Linear MCP** `create_issue`:

```javascript
{
  title: $2,
  team: projectMapping[project].team,
  project: projectMapping[project].project,
  description: "Design doc: [DOC-XXX](link) (will be added after doc creation)",
  labels: labelNames,  // Use validated label names
  parent: $3, // if provided (epic/initiative ID)
  priority: 0  // No priority unless specified
}
```

**Save the created ID** (e.g., `WORK-123` for feature, initiative ID for epic)

### Step 4: Create Linear Document

Use **Linear MCP** `create_document`:

**Document Title Format:**
- Epic: `Epic Spec: $2`
- Feature: `Feature Design: $2`

**Document Content:**

Use template based on type (see templates below).

**Initial Content:**
- Epic → Use Epic Spec Template
- Feature → Use Feature Design Template

**Save Document ID** (e.g., `DOC-456`)

### Step 5: Link Document to Linear Entity

Update the created Linear issue/initiative description with link to document:

```markdown
## 📄 Specification

**Spec Document**: [Epic Spec: $2](https://linear.app/workspace/document/DOC-456) ← Full specification

---

[Rest of description...]
```

### Step 6: Display Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Epic/Feature Created!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Type: [Epic/Feature]
🎯 Title: [$2]
🔗 Linear: [WORK-123](https://linear.app/workspace/issue/WORK-123)
📄 Spec Doc: [DOC-456](https://linear.app/workspace/document/DOC-456)
🏷️  Labels: spec:draft, [epic/feature]
📁 Project: [project name]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Suggested Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 7: Interactive Next Actions

Use **AskUserQuestion**:

```javascript
{
  questions: [{
    question: "Spec created! What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "Write Spec Content",
        description: "Start writing the spec document with AI assistance (/ccpm:spec:write)"
      },
      {
        label: "View in Linear",
        description: "Open Linear to see the created epic/feature"
      },
      {
        label: "Create Another",
        description: "Create another epic/feature"
      },
      {
        label: "Done for Now",
        description: "I'll work on the spec later"
      }
    ]
  }]
}
```

**Execute based on choice:**
- Write Spec Content → Run `/ccpm:spec:write [doc-id] requirements`
- View in Linear → Show URL and exit
- Create Another → Ask for details and repeat
- Done → Show quick commands and exit

---

## Error Handling

### Label Creation Failures

If label creation fails, show helpful error message:

```javascript
try {
  const labelNames = await ensureLabelsExist(teamId, ["epic", "spec:draft"], {...});
} catch (error) {
  console.error("❌ Failed to create/verify labels:", error.message);
  throw new Error(
    `Unable to create spec labels. This may indicate:\n` +
    `  - Insufficient Linear permissions\n` +
    `  - Network connectivity issues\n` +
    `  - Invalid team ID\n\n` +
    `Original error: ${error.message}`
  );
}
```

### State Validation Failures

If state validation is used (optional for this command):

```javascript
try {
  const stateId = await getValidStateId(teamId, "planned");
} catch (error) {
  // Error already includes helpful message with available states
  console.error("❌ Invalid state:", error.message);
  throw error; // Re-throw to halt command
}
```

### Recovery Strategy

If label/state operations fail:
1. Display clear error message with context
2. Show what was attempted (label names, state name)
3. Suggest fixes (check permissions, verify team ID)
4. DO NOT proceed with entity creation if validation fails

---

## Templates

### Epic Spec Template

```markdown
# Epic: [$2]

**Status**: 🟡 Draft
**Owner**: [Auto-detect from Linear user]
**Created**: [Current date]
**Last Updated**: [Current date]

---

## 🎯 Vision & Goals

### Problem Statement
What problem are we solving? Who has this problem?

[AI: Analyze the epic title and suggest problem statement based on common patterns]

### Success Metrics
How will we measure success?
- Metric 1: [Target]
- Metric 2: [Target]

### Out of Scope
What are we explicitly NOT doing?

---

## 🔍 User Research

### User Personas
- **Persona 1**: [Description]

### User Stories
- As a [role], I want [feature] so that [benefit]

---

## 🏗️ High-Level Architecture

### System Components
- Component 1: [Purpose]

### Integration Points
- External System 1: [How we integrate]

### Technology Choices
- Frontend: [Tech + Rationale]
- Backend: [Tech + Rationale]
- Database: [Tech + Rationale]

---

## 📊 Features Breakdown

| Feature | Priority | Complexity | Est. Timeline |
|---------|----------|------------|---------------|
| Feature 1 | P0 | High | 2 weeks |

**💡 Tip**: Use `/ccpm:spec:break-down [epic-id]` to auto-generate features from this spec.

---

## 🔒 Security & Compliance

### Security Considerations
- Authentication: [Approach]
- Authorization: [Approach]
- Data Protection: [Approach]

---

## 📅 Timeline & Milestones

| Milestone | Date | Status |
|-----------|------|--------|
| Spec Complete | [Date] | ⏳ |
| Feature 1 Complete | [Date] | 📅 |

---

## 🔗 References

**Linear Epic**: [WORK-XXX](https://linear.app/workspace/issue/WORK-XXX)

---

## 📝 Change Log

| Date | Change | Author |
|------|--------|--------|
| [Date] | Initial draft | [Name] |
```

### Feature Design Template

```markdown
# Feature: [$2]

**Status**: 🟡 Draft
**Epic**: [Link to parent Epic if exists]
**Owner**: [Auto-detect from Linear user]
**Created**: [Current date]

---

## 📋 Requirements

### Functional Requirements
- FR1: System shall...
- FR2: System shall...

### Non-Functional Requirements
- NFR1: Performance...
- NFR2: Scalability...

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

---

## 🎨 User Experience

### User Flows
1. Flow 1: [Step by step]

### Wireframes / Designs
[Link to Figma/designs if available]

---

## 🏗️ Technical Design

### Architecture
[Diagram or description]

### API Design
```
POST /api/endpoint
Request: {...}
Response: {...}
```

### Data Model
```typescript
interface Model {
  field1: type
  field2: type
}
```

### Component Structure (Frontend)
```
- ComponentName/
  - index.tsx
  - types.ts
```

---

## 🧪 Testing Strategy

### Unit Tests
- Test case 1

### Integration Tests
- Test scenario 1

---

## 🚀 Implementation Plan

### Task Breakdown
- [ ] **Task 1**: Description (Est: 2h)
- [ ] **Task 2**: Description (Est: 4h)

**Total Estimate**: 6 hours (~1 day)

**💡 Tip**: Use `/ccpm:spec:break-down [feature-id]` to create Linear tasks from this plan.

---

## 🔒 Security Considerations

- Input validation: [Approach]
- Authentication: [Required?]

---

## 📊 Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Risk 1 | Medium | High | [Strategy] |

---

## 🔗 References

**Linear Feature**: [WORK-XXX](https://linear.app/workspace/issue/WORK-XXX)
**Parent Epic Spec**: [Link if exists]

---

## 📝 Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| [Date] | Initial design | [Why] |
```

---

## Quick Commands Footer

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Write Spec:    /ccpm:spec:write [doc-id] [section]
Review Spec:   /ccpm:spec:review [doc-id]
Break Down:    /ccpm:spec:break-down [issue-id]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

- Epic/Initiative are interchangeable (same Linear entity type)
- Features are Parent Issues that can have Tasks as sub-issues
- All specs start with `spec:draft` label
- Use `/ccpm:spec:write` to populate sections with AI assistance
- Use `/ccpm:spec:review` to validate completeness before approval
