---
description: Create Epic/Feature/Initiative with Linear Document
allowed-tools: [LinearMCP, Read, AskUserQuestion]
argument-hint: <type> "<title>" [parent-id]
---

# Create Spec: $2

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

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

### Step 2: Determine Project Mapping

**Project Detection:**
```javascript
// Detect from current directory or ask user
const projectMapping = {
  'trainer-guru': { team: 'Work', project: 'Trainer Guru' },
  'repeat': { team: 'Work', project: 'Repeat' },
  'nv-internal': { team: 'Personal', project: 'NV Internal' }
}

// Check if in project directory
const cwd = process.cwd()
let project = 'nv-internal' // default

if (cwd.includes('trainer-guru')) project = 'trainer-guru'
else if (cwd.includes('repeat')) project = 'repeat'
else if (cwd.includes('nv-internal')) project = 'nv-internal'
```

If cannot detect, use **AskUserQuestion** to select project.

### Step 3: Create Linear Entity

#### For Epic/Initiative:

Use **Linear MCP** `create_project` or initiative creation:

```javascript
{
  name: $2,
  team: projectMapping[project].team,
  description: "Spec document: [DOC-XXX](link) (will be added after doc creation)",
  status: "planned",
  labels: ["epic", "spec:draft"]
}
```

#### For Feature (Parent Issue):

Use **Linear MCP** `create_issue`:

```javascript
{
  title: $2,
  team: projectMapping[project].team,
  project: projectMapping[project].project,
  description: "Design doc: [DOC-XXX](link) (will be added after doc creation)",
  labels: ["feature", "spec:draft"],
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
        description: "Start writing the spec document with AI assistance (/pm:spec:write)"
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
- Write Spec Content → Run `/pm:spec:write [doc-id] requirements`
- View in Linear → Show URL and exit
- Create Another → Ask for details and repeat
- Done → Show quick commands and exit

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

**💡 Tip**: Use `/pm:spec:break-down [epic-id]` to auto-generate features from this spec.

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

**💡 Tip**: Use `/pm:spec:break-down [feature-id]` to create Linear tasks from this plan.

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

Write Spec:    /pm:spec:write [doc-id] [section]
Review Spec:   /pm:spec:review [doc-id]
Break Down:    /pm:spec:break-down [issue-id]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

- Epic/Initiative are interchangeable (same Linear entity type)
- Features are Parent Issues that can have Tasks as sub-issues
- All specs start with `spec:draft` label
- Use `/pm:spec:write` to populate sections with AI assistance
- Use `/pm:spec:review` to validate completeness before approval
