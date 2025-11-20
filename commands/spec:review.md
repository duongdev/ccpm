---
description: AI-powered spec review for completeness and quality
allowed-tools: [LinearMCP, AskUserQuestion]
argument-hint: <doc-id>
---

# Review Spec: $1

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

---

## Argument

- **$1** - Document ID (e.g., `DOC-456` or document title/slug)

## Workflow

### Step 1: Fetch Document

Use **Linear MCP** `get_document` with ID `$1`:

- Get full document content
- Identify document type (Epic Spec vs Feature Design)
- Parse all sections

### Step 2: Analyze Completeness

**For Epic Spec, check for:**

```javascript
const epicRequiredSections = {
  vision: {
    required: ['Problem Statement', 'Success Metrics'],
    optional: ['Out of Scope']
  },
  userResearch: {
    required: ['User Personas', 'User Stories'],
    optional: []
  },
  architecture: {
    required: ['System Components', 'Technology Choices'],
    optional: ['Integration Points']
  },
  features: {
    required: ['Features Breakdown'],
    optional: []
  },
  timeline: {
    required: ['Timeline & Milestones'],
    optional: []
  },
  security: {
    required: ['Security Considerations'],
    optional: ['Compliance Requirements']
  }
}

const score = calculateCompletenessScore(doc, epicRequiredSections)
// Score: 0-100 based on required sections filled
```

**For Feature Design, check for:**

```javascript
const featureRequiredSections = {
  requirements: {
    required: ['Functional Requirements', 'Acceptance Criteria'],
    optional: ['Non-Functional Requirements', 'User Acceptance Testing']
  },
  ux: {
    required: ['User Flows'],
    optional: ['Wireframes']
  },
  technical: {
    required: ['Architecture', 'API Design', 'Data Model'],
    optional: ['Component Structure']
  },
  testing: {
    required: ['Testing Strategy'],
    optional: ['Test Data']
  },
  implementation: {
    required: ['Implementation Plan', 'Task Breakdown'],
    optional: ['Dependencies']
  },
  security: {
    required: ['Security Considerations'],
    optional: []
  },
  risks: {
    required: ['Risks & Mitigations'],
    optional: []
  }
}

const score = calculateCompletenessScore(doc, featureRequiredSections)
```

### Step 3: Quality Analysis

**Content Quality Checks:**

1. **Specificity**:
   - ❌ "The system should be fast"
   - ✅ "API response time < 200ms for 95th percentile"

2. **Testability**:
   - ❌ "Feature should work well"
   - ✅ "When user clicks button, modal appears within 100ms"

3. **Clarity**:
   - Avoid vague terms: "probably", "might", "should be good"
   - Use precise language: "must", "will", "shall"

4. **Consistency**:
   - API endpoints follow same naming pattern
   - Data models use consistent field naming
   - Code examples use same style

5. **Technical Feasibility**:
   - Technology choices are realistic
   - Timeline is achievable
   - Dependencies are clear

### Step 4: Risk Assessment

**Identify Potential Issues:**

```javascript
const risks = {
  scope: detectScopeCreep(doc),
  technical: detectTechnicalRisks(doc),
  timeline: detectTimelineIssues(doc),
  dependencies: detectMissingDependencies(doc),
  security: detectSecurityGaps(doc)
}

function detectScopeCreep(doc) {
  // Check if feature count is too high
  // Check if requirements are too broad
  // Look for "also", "and", "additionally" in requirements
  return issues
}

function detectTechnicalRisks(doc) {
  // Check for unproven technologies
  // Check for complex integrations
  // Analyze technology choices
  return issues
}

function detectTimelineIssues(doc) {
  // Compare task count to estimated time
  // Check if estimates are too optimistic
  // Verify buffer exists
  return issues
}
```

### Step 5: Best Practices Check

**Epic Spec Best Practices:**

- [ ] Success metrics are measurable (not "improve UX", but "reduce task completion time by 30%")
- [ ] User personas are specific (not "users", but "Project Manager with 5+ years experience")
- [ ] Features are prioritized (P0, P1, P2)
- [ ] Technology choices include rationale
- [ ] Timeline has milestones
- [ ] Security considerations are addressed
- [ ] Out of scope is defined

**Feature Design Best Practices:**

- [ ] Requirements are numbered (FR1, FR2, NFR1)
- [ ] Acceptance criteria are testable
- [ ] API design follows REST principles
- [ ] Data model includes indexes
- [ ] Testing strategy covers unit + integration
- [ ] Security considerations include auth + validation
- [ ] Risks have mitigations
- [ ] Implementation tasks have estimates
- [ ] Dependencies are explicitly stated

### Step 6: Generate Review Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Spec Review: [Document Title]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 Document: [DOC-456](https://linear.app/workspace/document/DOC-456)
📊 Type: [Epic Spec / Feature Design]
📈 Completeness: [XX]% ([Grade])

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Completeness Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Complete Sections ([X]/[Y]):
- ✓ Requirements (Functional + Acceptance Criteria)
- ✓ Architecture (System Components + Tech Stack)
- ✓ Testing Strategy

⚠️  Incomplete Sections ([X]/[Y]):
- ⚠️  API Design (Missing error codes)
- ⚠️  Security (No rate limiting mentioned)
- ⚠️  Timeline (Missing milestones)

❌ Missing Sections ([X]/[Y]):
- ✗ User Flows (Required)
- ✗ Risks & Mitigations (Required)

**Overall Grade**: [A/B/C/D/F]
- A (90-100%): Ready for approval
- B (75-89%): Minor fixes needed
- C (60-74%): Needs work
- D (50-59%): Major gaps
- F (<50%): Incomplete

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Quality Assessment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Strengths:
1. Requirements are specific and testable
2. Technology choices are well-justified
3. Data model includes proper indexes

⚠️  Issues Found:
1. **Vague Success Metrics** (Medium Priority)
   - Current: "Improve user experience"
   - Should be: "Reduce task completion time by 30%"
   - Section: Vision & Goals

2. **Missing Error Handling** (High Priority)
   - API design lacks error codes
   - Should include: Error code taxonomy
   - Section: API Design

3. **Timeline Too Optimistic** (Medium Priority)
   - 20 hours for 6 tasks seems tight
   - Consider: Adding 30% buffer
   - Section: Timeline

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 Risks Identified
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**High Priority Risks:**
1. **Scope Creep** (Probability: High, Impact: High)
   - Issue: Feature includes 8+ distinct capabilities
   - Mitigation: Split into 2 features (Core + Advanced)
   - Recommended: Review feature breakdown

2. **Missing Dependencies** (Probability: Medium, Impact: High)
   - Issue: No mention of auth system setup
   - Mitigation: Add auth as prerequisite
   - Recommended: Update dependencies section

**Medium Priority Risks:**
1. **Technical Complexity** (Probability: Medium, Impact: Medium)
   - Issue: Multiple external API integrations
   - Mitigation: Add integration testing plan
   - Recommended: Expand testing section

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ Recommendations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Immediate Actions (Before Approval):**
1. Add User Flows section (Required)
2. Complete Risks & Mitigations (Required)
3. Specify measurable success metrics
4. Add API error codes

**Nice to Have (Can Do Later):**
1. Add wireframes/mockups
2. Include performance benchmarks
3. Add monitoring plan

**Estimated Time to Address**: 2-3 hours

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Best Practices Checklist
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Legend: ✅ Pass | ⚠️  Partial | ❌ Fail

✅ Requirements are numbered and testable
⚠️  Acceptance criteria exist but lack "Given/When/Then"
✅ API follows REST conventions
✅ Data model includes indexes
⚠️  Testing strategy covers unit tests only (missing E2E)
❌ Security: No input validation mentioned
✅ Implementation tasks have estimates
⚠️  Dependencies mentioned but not in dependency graph

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎬 Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**If Grade A-B:**
→ Ready for approval! Update status to `spec:approved`

**If Grade C-D:**
→ Address issues above, then run review again

**If Grade F:**
→ Use `/ccpm:spec:write [doc-id] [section]` to complete missing sections

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 7: Update Linear Issue Label

**Based on grade:**

- **A (90-100%)**: Suggest changing label to `spec:approved`
- **B (75-89%)**: Keep as `spec:review`
- **C-D-F (<75%)**: Keep as `spec:draft`

**Use AskUserQuestion if grade is A:**

```javascript
{
  questions: [{
    question: "Spec review complete with Grade A! Should I update the status to 'spec:approved'?",
    header: "Approval",
    multiSelect: false,
    options: [
      {
        label: "Yes, Approve",
        description: "Update label to spec:approved (ready for implementation)"
      },
      {
        label: "Not Yet",
        description: "I'll review manually first"
      }
    ]
  }]
}
```

If approved, update Linear issue/initiative labels via **Linear MCP**.

### Step 8: Interactive Next Actions

```javascript
{
  questions: [{
    question: "Review complete! What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "Fix Issues",
        description: "Use /ccpm:spec:write to address identified issues"
      },
      {
        label: "Break Down into Tasks",
        description: "Create implementation tasks (/ccpm:spec:break-down)"
      },
      {
        label: "View in Linear",
        description: "Open document to review in Linear"
      },
      {
        label: "Done",
        description: "Finish for now"
      }
    ]
  }]
}
```

## Scoring Algorithm

```javascript
function calculateCompletenessScore(doc, requiredSections) {
  let totalRequired = 0
  let completedRequired = 0
  let totalOptional = 0
  let completedOptional = 0

  for (const [section, items] of Object.entries(requiredSections)) {
    totalRequired += items.required.length
    totalOptional += items.optional.length

    for (const item of items.required) {
      if (sectionExists(doc, item) && hasContent(doc, item)) {
        completedRequired++
      }
    }

    for (const item of items.optional) {
      if (sectionExists(doc, item) && hasContent(doc, item)) {
        completedOptional++
      }
    }
  }

  // Required sections: 80% weight
  // Optional sections: 20% weight
  const requiredScore = (completedRequired / totalRequired) * 80
  const optionalScore = (completedOptional / totalOptional) * 20

  return Math.round(requiredScore + optionalScore)
}

function sectionExists(doc, sectionName) {
  // Check if section heading exists in document
  return doc.content.includes(`## ${sectionName}`) ||
         doc.content.includes(`### ${sectionName}`)
}

function hasContent(doc, sectionName) {
  // Extract section content and check if it has meaningful content
  // (not just placeholders like "[TODO]" or "[Description]")
  const sectionContent = extractSection(doc, sectionName)

  const placeholders = ['[TODO]', '[Description]', '[TBD]', '[...]']
  const hasPlaceholder = placeholders.some(p => sectionContent.includes(p))

  const wordCount = sectionContent.split(/\s+/).length

  return wordCount > 10 && !hasPlaceholder
}
```

## Notes

- Review is non-destructive (read-only analysis)
- Provides actionable feedback
- Highlights both strengths and issues
- Grades based on completeness and quality
- Suggests specific improvements
