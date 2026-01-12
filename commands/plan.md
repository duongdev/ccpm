---
description: Smart planning - create, plan, or update tasks with v1.0 workflow rules
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[title]" OR <issue-id> OR <issue-id> "[changes]"
---

# /ccpm:plan - Smart Planning

Intelligent command that creates new tasks, plans existing tasks, or updates plans based on context.

## ⛔ CRITICAL: Linear Operations

**ALL Linear operations MUST use the Task tool with `ccpm:linear-operations` subagent.**

```javascript
// ✅ CORRECT - Use Task tool with subagent
Task({
  subagent_type: "ccpm:linear-operations",
  prompt: `operation: get_issue\nparams:\n  issueId: WORK-26\ncontext:\n  cache: true`
})

// ❌ WRONG - Direct MCP call (will fail with wrong params)
mcp__agent-mcp-gateway__execute_tool({ server: "linear", tool: "get_issue", args: { issueId: "X" } })
```

## ✅ LINEAR = AUTOMATIC (NO CONFIRMATION)

**Linear is internal tracking. Execute ALL operations immediately:**
- ✅ Create issues → Just do it
- ✅ Update descriptions → Just do it
- ✅ Post comments → Just do it

**NEVER ask:** "Do you want me to update Linear?" - Just execute and report result.

---

## 🎯 v1.0 Interactive Workflow Rules

**PLAN Mode Philosophy:**
- **🚫 NO IMPLEMENTATION** - This command ONLY plans, NEVER implements code or commits
- **Seek details** - Consider multiple approaches, don't assume
- **Deep research** - Codebase, Linear, external PM, git history
- **Update description** - Keep plan consolidated (not scattered in comments)
- **Stay in plan mode** - Don't rush to implementation
- **Get confirmation** - Explicit approval before proceeding
- **Hybrid Q&A** - Critical questions via AskUserQuestion, clarifications via output

**🔴 CRITICAL**: `/ccpm:plan` creates checklists and updates Linear descriptions ONLY. Implementation happens in `/ccpm:work`.

## Mode Detection

Three modes with clear detection:

- **CREATE**: `/ccpm:plan "title" [project] [jira]` → Create + plan new task
- **PLAN**: `/ccpm:plan WORK-123` → Plan existing task
- **UPDATE**: `/ccpm:plan WORK-123 "changes"` → Update existing plan

## Usage

```bash
# CREATE - New task
/ccpm:plan "Add user authentication"
/ccpm:plan "Add dark mode" my-app TRAIN-456

# PLAN - Plan existing
/ccpm:plan PSN-27

# UPDATE - Update plan
/ccpm:plan PSN-27 "Add email notifications too"
/ccpm:plan PSN-27 "Use Redis instead of in-memory"
```

## Implementation

### Step 1: Parse Arguments & Detect Mode

```javascript
const args = process.argv.slice(2);
const arg1 = args[0];
const arg2 = args[1];
const arg3 = args[2];

const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/;

if (!arg1) {
  return error(`
❌ Missing arguments

Usage:
  /ccpm:plan "Task title" [project] [jira]  # Create new
  /ccpm:plan WORK-123                        # Plan existing
  /ccpm:plan WORK-123 "changes"              # Update plan
  `);
}

let mode, issueId, title, project, jiraTicket, updateText;

if (ISSUE_ID_PATTERN.test(arg1)) {
  issueId = arg1;
  mode = arg2 ? 'update' : 'plan';
  updateText = arg2;
} else {
  mode = 'create';
  title = arg1;
  project = arg2 || null;
  jiraTicket = arg3 || null;
}

console.log(`\n🎯 Mode: ${mode.toUpperCase()}`);
```

### Step 2A: CREATE Mode - Create & Plan New Task

```yaml
## CREATE: Create new task and plan it

1. Load project configuration:

Task(project-context-manager): `
${project ? `Get context for project: ${project}` : 'Get active project context'}
Format: standard
Include all sections: true
`

Store: projectId, teamId, projectLinearId, defaultLabels, externalPM config

2. Create Linear issue via subagent:

**Use the Task tool to create a new Linear issue:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: create_issue
  params:
    team: "{team ID from step 1}"
    title: "{task title from arguments}"
    project: "{project Linear ID from step 1}"
    state: "Backlog"
    labels: {default labels from step 1}
    description: |
      ## Task

      {task title}

      {if Jira ticket provided: **Jira Reference**: {jiraTicket}}
      ---

      _Planning in progress..._
  context:
    command: "plan"
    mode: "create"
  ```

Store: issue.id, issue.identifier

Display: "✅ Created issue: ${issue.identifier}"

3. Stage 1: Research & Clarify Requirements

**Deep research (parallel):**
a) Search Linear for similar issues
b) If Jira provided, research ticket + Confluence docs
c) Search codebase for similar implementations
d) Analyze recent git commits for related work

**Identify ambiguities using helpers/decision-helpers.md:**

Use `calculateConfidence()` to assess understanding:
- Requirements clarity (0-100)
- Technical approach certainty (0-100)
- Scope boundaries definition (0-100)

**Gather clarification questions (DO NOT ASSUME):**

Generate questions for any area with confidence < 80%:
- Technical approach preferences
- Scope boundaries (what's included/excluded)
- Constraints (time, compatibility, existing patterns to follow)
- Risk tolerance
- Integration requirements
- Testing expectations

**Use AskUserQuestion to ask ALL clarifying questions:**

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Which approach do you prefer for [technical decision]?",
      header: "Approach",
      multiSelect: false,
      options: [
        { label: "Option A", description: "Pros/cons..." },
        { label: "Option B", description: "Pros/cons..." }
      ]
    },
    // ... more questions as needed
  ]
});
```

**Based on answers, propose 2-3 implementation approaches:**

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Implementation Approaches for ${title}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Approach 1: [Name]
   Complexity: [Low/Medium/High]
   Effort: [estimate]
   Pros: [benefits]
   Cons: [drawbacks]

📋 Approach 2: [Name]
   Complexity: [Low/Medium/High]
   Effort: [estimate]
   Pros: [benefits]
   Cons: [drawbacks]

📋 Approach 3: [Name] (if applicable)
   Complexity: [Low/Medium/High]
   Effort: [estimate]
   Pros: [benefits]
   Cons: [drawbacks]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**User selects preferred approach:**

```javascript
const selectedApproach = await AskUserQuestion({
  questions: [{
    question: "Which approach would you like to use?",
    header: "Approach",
    multiSelect: false,
    options: [
      { label: "Approach 1", description: "Brief summary" },
      { label: "Approach 2", description: "Brief summary" },
      { label: "Approach 3", description: "Brief summary" }
    ]
  }]
});
```

**Document scope boundaries:**

Output:
```
✅ Selected Approach: ${selectedApproach}

📍 Scope Boundaries:
   IN SCOPE:
   • [specific items included]

   OUT OF SCOPE:
   • [specific items excluded]
   • [features deferred]
```

4. Stage 2: Detailed Planning with Smart Agent Selection

**Let smart-agent-selector determine best agent(s):**

Based on task context (tech stack, requirements, approach), the smart-agent-selector will automatically choose optimal agent(s):
- Backend/API → ccpm:backend-architect
- Frontend/UI → ccpm:frontend-developer
- Mobile → ccpm:frontend-developer (handles React Native/mobile)
- Full-stack → Both backend + frontend (parallel)
- Check hook hints for project-specific agent names

**Invoke selected agent(s) with strict scope constraints:**

Task: `
**APPROVED APPROACH**: ${selectedApproach}

**SCOPE BOUNDARIES**:
IN SCOPE: ${scopeIn}
OUT OF SCOPE: ${scopeOut}

**CRITICAL CONSTRAINTS - DO NOT VIOLATE**:
- ❌ NO features outside approved scope
- ❌ NO refactoring unrelated code
- ❌ NO alternative approaches
- ❌ NO nice-to-have improvements
- ❌ NO implementation (planning only!)

**YOUR JOB - PROVIDE ONLY**:
- ✅ Step-by-step implementation for approved approach
- ✅ Specific file changes within scope
- ✅ Technical gotchas for this approach
- ✅ Testing strategy for approved scope

---

Create detailed implementation plan for: ${title}

Approved Approach: ${selectedApproach}
User Clarifications: ${clarificationAnswers}

Context gathered:
- Linear similar issues: [if found]
- Jira context: [if provided]
- Codebase patterns: [found implementations]
- Recent commits: [related work]

Provide:
1. **Implementation Checklist** (5-15 actionable items with EMBEDDED METADATA)
2. **Complexity Assessment** (low/medium/high with reasoning)
3. **Dependencies** (prerequisites, external factors)

**CRITICAL: FORMAT CHECKLIST WITH SELF-CONTAINED ITEMS**

Each checklist item MUST include embedded metadata so agents know exactly:
- WHAT files to modify
- HOW to implement it (approach)
- WHAT pattern to follow
- WHAT tests to write
- WHAT gotchas to avoid

**FORMAT TEMPLATE** (use marker comments):
<!-- ccpm-checklist-start -->
- [ ] **1. [Action verb] [Component/Feature]**
  - Files: \`path/to/file.ts\`, \`path/to/other.ts\`
  - Approach: [Specific implementation approach - libraries, methods, patterns]
  - Pattern: Follow \`path/to/reference/file.ts\` structure
  - Tests: [Specific tests to write]
  - Gotchas: [Technical warnings, edge cases, common mistakes]

- [ ] **2. [Next task]**
  - Files: \`path/to/file.ts\`
  - Approach: [How to implement]
  - Pattern: Follow existing [X] pattern in codebase
  - Tests: [Required tests]
  - Gotchas: [What to watch out for]
<!-- ccpm-checklist-end -->

**EXAMPLE OF GOOD vs BAD CHECKLIST ITEMS:**

❌ BAD (vague - agent will interpret differently each time):
- [ ] Create login form component
- [ ] Add validation
- [ ] Write tests

✅ GOOD (self-contained - agent knows exactly what to do):
- [ ] **1. Create LoginForm component with email/password fields**
  - Files: \`src/components/auth/LoginForm.tsx\`
  - Approach: Use react-hook-form with zod schema, existing Button/Input components
  - Pattern: Follow \`src/components/auth/SignupForm.tsx\` structure
  - Tests: Unit tests for form submission, validation errors, loading state
  - Gotchas: Handle async email validation, clear errors on input change

**WHY THIS MATTERS:**
- Agents receive item-specific context, not just generic description
- Implementation stays consistent with the original plan
- Files, patterns, and gotchas are linked to specific tasks
- No interpretation drift between planning and implementation

**REMEMBER**: Stay within approved scope. No code implementation, planning only.
`

Note: Smart-agent-selector chooses agent automatically. Agent provides scoped, detailed plan.

5. Present plan for confirmation (v1.0 workflow):

Display the complete plan with:
- Recommended approach + alternatives
- Full checklist
- Files to modify
- Uncertainties identified

**Get explicit confirmation before proceeding:**

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Proposed Plan for ${title}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Recommended Approach:
[approach description]

💡 Alternatives Considered:
[alternatives and why not chosen]

✅ Implementation Checklist:
[checklist items]

📁 Files to Modify:
[files with rationale]

⚠️ Uncertainties:
[questions/unknowns identified]

🧪 Testing Strategy:
[testing approach]

⚡ Complexity: [Low/Medium/High] - [reasoning]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then ask: "Does this plan look good? Any adjustments needed?"

6. Update Linear issue with confirmed plan:

**Use the Task tool to update the issue description:**

Invoke the `ccpm:linear-operations` subagent:
- **Tool**: Task
- **Subagent**: ccpm:linear-operations
- **Prompt**:
  ```
  operation: update_issue_description
  params:
    issueId: "{issue identifier}"
    description: |
      ## Implementation Checklist

      <!-- ccpm-checklist-start -->
      {checklist with EMBEDDED METADATA - each item includes Files, Approach, Pattern, Tests, Gotchas}

      Example format:
      - [ ] **1. Create LoginForm component**
        - Files: \`src/components/auth/LoginForm.tsx\`
        - Approach: Use react-hook-form with existing Form wrapper
        - Pattern: Follow \`src/components/auth/SignupForm.tsx\`
        - Tests: Unit tests for form submission, validation
        - Gotchas: Handle async email validation

      - [ ] **2. Add validation schema**
        - Files: \`src/schemas/auth.ts\`
        - Approach: Use zod matching backend requirements
        - Pattern: Follow \`src/schemas/user.ts\`
        - Tests: Unit tests for valid/invalid inputs
        - Gotchas: Email regex must match backend
      <!-- ccpm-checklist-end -->

      Progress: 0% (0/{N} completed)
      Last updated: {timestamp}

      > **Complexity**: {complexity} | **Approach**: {selected approach name}

      ---

      ## Task

      {title}

      {if Jira: **Jira**: [{jiraTicket}](url)}

      ---

      ## ❓ Clarifications

      {Questions asked and user answers from Stage 1}

      **Q: {question 1}**
      A: {user answer}

      **Q: {question 2}**
      A: {user answer}

      ---

      ## 🔍 Approach Analysis

      ### Approaches Considered:

      **1. {Approach 1 Name}** (Selected ✓)
      - Complexity: {complexity}
      - Pros: {benefits}
      - Cons: {drawbacks}

      **2. {Approach 2 Name}**
      - Complexity: {complexity}
      - Pros: {benefits}
      - Cons: {drawbacks}

      **Why selected**: {rationale for selection}

      **Scope Boundaries**:
      - IN SCOPE: {specific items included}
      - OUT OF SCOPE: {specific items excluded/deferred}

      ---

      ## Dependencies

      {prerequisites, external factors}

      ---

      *Planned via /ccpm:plan*
  context:
    command: "plan"
  ```

7. Update status and labels:

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: update_issue
params:
  issueId: "{issue identifier}"
  state: "Planned"
  labels: ["planned", "ready"]
context:
  command: "plan"
```

8. Display completion:

console.log('\n═══════════════════════════════════════');
console.log('✅ Task Created & Planned!');
console.log('═══════════════════════════════════════\n');
console.log(`📋 Issue: ${issue.identifier} - ${title}`);
console.log(`🔗 ${issue.url}`);
console.log(`\n📊 Plan Summary:`);
console.log(`  ✅ ${checklistCount} subtasks created`);
console.log(`  📁 ${filesCount} files to modify`);
console.log(`  ⚡ Complexity: ${complexity}`);
console.log(`\n💡 Next: /ccpm:work ${issue.identifier}`);
```

### Step 2B: PLAN Mode - Plan Existing Task

```yaml
## PLAN: Plan existing task

1. Fetch issue via subagent:

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: get_issue
params:
  issueId: "{issue ID}"
context:
  cache: true
  command: "plan"
```

Store: issue details

Display: "📋 Planning: ${issue.identifier} - ${issue.title}"

2. Check if already planned:

const hasChecklist = issue.description.includes('## Implementation Checklist');
const isPlanned = issue.state.name === 'Planned' || issue.state.name === 'Ready';

if (hasChecklist && isPlanned) {
  console.log('\nℹ️  Task already has a plan. Use one of:');
  console.log(`  • /ccpm:plan ${issueId} "changes" - Update the plan`);
  console.log(`  • /ccpm:work ${issueId} - Start implementation`);
  return;
}

2.5. Detect and analyze visual context (images + Figma):

**Extract visual context from issue** (parallel detection):

a) Detect images using helpers/image-analysis.md logic:
   - Scan issue.attachments for image files (jpg, png, gif, webp, svg)
   - Scan issue.description for markdown images: ![alt](url)
   - Deduplicate by URL
   - Limit to 5 images max (performance)

b) Detect Figma links using helpers/figma-detection.md logic:
   - Search issue.description and comments for Figma URLs
   - Parse URLs to extract file_id, node_id
   - Select appropriate MCP server for project

**If images or Figma links found:**

Display: "🎨 Visual context detected: {count} image(s), {count} Figma link(s)"

**Process visual context (parallel analysis):**

For images (if detected):
```bash
# Analyze each image with context-aware prompts
for each image in detectedImages:
  - Determine image type (UI mockup, diagram, screenshot, generic)
  - Fetch image via WebFetch or Read tool
  - Analyze with appropriate prompt template from helpers/image-analysis.md:
    * UI mockup → Extract layout, components, colors, typography
    * Architecture diagram → Extract components, relationships, data flow
    * Screenshot → Extract current state, issues, context
    * Generic → General visual analysis
  - Store analysis results
```

For Figma links (if detected):
```bash
# Extract design system via scripts
for each figmaUrl in detectedFigmaLinks:
  # Parse Figma URL
  parsed=$(./scripts/figma-utils.sh parse "$figmaUrl")

  # Select MCP server for project
  server=$(./scripts/figma-server-manager.sh select "$projectId")

  # Check cache first (Linear comments)
  cached=$(./scripts/figma-cache-manager.sh get "$issueId" "$figmaUrl")

  if [ -n "$cached" ]; then
    # Use cached design data (fast path)
    designData=$cached
  else
    # Extract design data via MCP (scripts/figma-data-extractor.sh)
    designData=$(./scripts/figma-data-extractor.sh extract "$server" "$figmaUrl")

    # Analyze design system (scripts/figma-design-analyzer.sh)
    designSystem=$(./scripts/figma-design-analyzer.sh analyze "$designData")

    # Cache in Linear comment for 1 hour
    ./scripts/figma-cache-manager.sh set "$issueId" "$figmaUrl" "$designSystem"
  fi

  # Store: colors → Tailwind, fonts → Tailwind, spacing → Tailwind
```

**Store visual context for planning:**
```javascript
const visualContext = {
  images: [
    { url, type: 'ui_mockup', analysis: {...} },
    { url, type: 'diagram', analysis: {...} }
  ],
  figma: [
    {
      url,
      file_name,
      design_system: {
        colors: [{ hex: '#3b82f6', tailwind: 'blue-500' }],
        typography: [{ family: 'Inter', tailwind: 'font-sans' }],
        spacing: [{ value: '16px', tailwind: 'space-4' }]
      }
    }
  ],
  summary: "2 UI mockups, 1 Figma design system extracted"
}
```

Display: "✅ Visual context analyzed and ready for planning"

3. Stage 1: Research & Clarify Requirements

**Deep research (parallel):**
a) Search Linear for similar issues
b) Extract Jira reference from description, research if found
c) Search codebase for similar implementations
d) Analyze git history for related work

**Identify ambiguities using helpers/decision-helpers.md:**

Use `calculateConfidence()` to assess understanding:
- Requirements clarity (0-100)
- Technical approach certainty (0-100)
- Scope boundaries definition (0-100)

**Gather clarification questions (DO NOT ASSUME):**

Generate questions for any area with confidence < 80%:
- Technical approach preferences
- Scope boundaries (what's included/excluded)
- Constraints (time, compatibility, existing patterns to follow)
- Risk tolerance
- Integration requirements
- Testing expectations
${visualContext ? '- Visual context interpretation (mockup details, design intent)' : ''}

**Use AskUserQuestion to ask ALL clarifying questions:**

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Which approach do you prefer for [technical decision]?",
      header: "Approach",
      multiSelect: false,
      options: [
        { label: "Option A", description: "Pros/cons..." },
        { label: "Option B", description: "Pros/cons..." }
      ]
    },
    // ... more questions as needed
  ]
});
```

**Based on answers, propose 2-3 implementation approaches:**

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Implementation Approaches for ${issue.title}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Approach 1: [Name]
   Complexity: [Low/Medium/High]
   Effort: [estimate]
   Pros: [benefits]
   Cons: [drawbacks]

📋 Approach 2: [Name]
   Complexity: [Low/Medium/High]
   Effort: [estimate]
   Pros: [benefits]
   Cons: [drawbacks]

📋 Approach 3: [Name] (if applicable)
   Complexity: [Low/Medium/High]
   Effort: [estimate]
   Pros: [benefits]
   Cons: [drawbacks]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**User selects preferred approach:**

```javascript
const selectedApproach = await AskUserQuestion({
  questions: [{
    question: "Which approach would you like to use?",
    header: "Approach",
    multiSelect: false,
    options: [
      { label: "Approach 1", description: "Brief summary" },
      { label: "Approach 2", description: "Brief summary" },
      { label: "Approach 3", description: "Brief summary" }
    ]
  }]
});
```

**Document scope boundaries:**

Output:
```
✅ Selected Approach: ${selectedApproach}

📍 Scope Boundaries:
   IN SCOPE:
   • [specific items included]

   OUT OF SCOPE:
   • [specific items excluded]
   • [features deferred]
```

4. Stage 2: Detailed Planning with Smart Agent Selection

**Let smart-agent-selector determine best agent(s):**

Based on task context (tech stack, requirements, approach), the smart-agent-selector will automatically choose optimal agent(s):
- Backend/API → ccpm:backend-architect
- Frontend/UI → ccpm:frontend-developer
- Mobile → ccpm:frontend-developer (handles React Native/mobile)
- Full-stack → Both backend + frontend (parallel)
- Check hook hints for project-specific agent names

**Invoke selected agent(s) with strict scope constraints:**

Task: `
**APPROVED APPROACH**: ${selectedApproach}

**SCOPE BOUNDARIES**:
IN SCOPE: ${scopeIn}
OUT OF SCOPE: ${scopeOut}

**CRITICAL CONSTRAINTS - DO NOT VIOLATE**:
- ❌ NO features outside approved scope
- ❌ NO refactoring unrelated code
- ❌ NO alternative approaches
- ❌ NO nice-to-have improvements
- ❌ NO implementation (planning only!)

**YOUR JOB - PROVIDE ONLY**:
- ✅ Step-by-step implementation for approved approach
- ✅ Specific file changes within scope
- ✅ Technical gotchas for this approach
- ✅ Testing strategy for approved scope

---

Create detailed implementation plan for: ${issue.title}

Current description:
${issue.description}

Approved Approach: ${selectedApproach}
User Clarifications: ${clarificationAnswers}

Context gathered:
- Linear similar issues: [if found]
- Jira context: [if found]
- Codebase patterns: [implementations]
- Recent commits: [related work]
${visualContext ? `- Visual context: ${visualContext.summary}` : ''}

${visualContext?.images?.length > 0 ? `
Visual Context - Images:
${visualContext.images.map(img => `
  - ${img.type}: ${img.url}
    Analysis: ${JSON.stringify(img.analysis, null, 2)}
`).join('\n')}
` : ''}

${visualContext?.figma?.length > 0 ? `
Visual Context - Figma Design System:
${visualContext.figma.map(fig => `
  - File: ${fig.file_name}
    URL: ${fig.url}
    Colors: ${fig.design_system.colors.map(c => `${c.hex} → ${c.tailwind}`).join(', ')}
    Fonts: ${fig.design_system.typography.map(t => `${t.family} → ${t.tailwind}`).join(', ')}
    Spacing: ${fig.design_system.spacing.map(s => `${s.value} → ${s.tailwind}`).join(', ')}
`).join('\n')}
` : ''}

Provide:
1. **Implementation Checklist** (5-15 actionable items with EMBEDDED METADATA)
2. **Complexity Assessment** (low/medium/high with reasoning)
3. **Dependencies** (prerequisites, external factors)
${visualContext ? '4. **Visual Context Usage** - How to use mockups/designs for pixel-perfect implementation' : ''}

**CRITICAL: FORMAT CHECKLIST WITH SELF-CONTAINED ITEMS**

Each checklist item MUST include embedded metadata so agents know exactly:
- WHAT files to modify
- HOW to implement it (approach)
- WHAT pattern to follow
- WHAT tests to write
- WHAT gotchas to avoid

**FORMAT TEMPLATE** (use marker comments):
<!-- ccpm-checklist-start -->
- [ ] **1. [Action verb] [Component/Feature]**
  - Files: \`path/to/file.ts\`, \`path/to/other.ts\`
  - Approach: [Specific implementation approach - libraries, methods, patterns]
  - Pattern: Follow \`path/to/reference/file.ts\` structure
  - Tests: [Specific tests to write]
  - Gotchas: [Technical warnings, edge cases, common mistakes]

- [ ] **2. [Next task]**
  - Files: \`path/to/file.ts\`
  - Approach: [How to implement]
  - Pattern: Follow existing [X] pattern in codebase
  - Tests: [Required tests]
  - Gotchas: [What to watch out for]
<!-- ccpm-checklist-end -->

**EXAMPLE OF GOOD vs BAD CHECKLIST ITEMS:**

❌ BAD (vague - agent will interpret differently each time):
- [ ] Create login form component
- [ ] Add validation
- [ ] Write tests

✅ GOOD (self-contained - agent knows exactly what to do):
- [ ] **1. Create LoginForm component with email/password fields**
  - Files: \`src/components/auth/LoginForm.tsx\`
  - Approach: Use react-hook-form with zod schema, existing Button/Input components
  - Pattern: Follow \`src/components/auth/SignupForm.tsx\` structure
  - Tests: Unit tests for form submission, validation errors, loading state
  - Gotchas: Handle async email validation, clear errors on input change

**WHY THIS MATTERS:**
- Agents receive item-specific context, not just generic description
- Implementation stays consistent with the original plan
- Files, patterns, and gotchas are linked to specific tasks
- No interpretation drift between planning and implementation

**REMEMBER**: Stay within approved scope. No code implementation, planning only.
`

Note: Smart-agent-selector chooses agent automatically. Agent provides scoped, detailed plan.

5. Present plan for confirmation (v1.0 workflow):

Display complete plan and ask: "Does this plan look good? Any adjustments needed?"

6. Update issue description with confirmed plan:

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: update_issue_description
params:
  issueId: "{issue ID}"
  description: |
    ## Implementation Checklist

    <!-- ccpm-checklist-start -->
    {checklist with EMBEDDED METADATA - each item includes Files, Approach, Pattern, Tests, Gotchas}

    Example format:
    - [ ] **1. Create LoginForm component**
      - Files: \`src/components/auth/LoginForm.tsx\`
      - Approach: Use react-hook-form with existing Form wrapper
      - Pattern: Follow \`src/components/auth/SignupForm.tsx\`
      - Tests: Unit tests for form submission, validation
      - Gotchas: Handle async email validation

    - [ ] **2. Add validation schema**
      - Files: \`src/schemas/auth.ts\`
      - Approach: Use zod matching backend requirements
      - Pattern: Follow \`src/schemas/user.ts\`
      - Tests: Unit tests for valid/invalid inputs
      - Gotchas: Email regex must match backend
    <!-- ccpm-checklist-end -->

    Progress: 0% (0/{N} completed)
    Last updated: {timestamp}

    > **Complexity**: {complexity} | **Approach**: {selected approach name}

    ---

    {original description}

    ---

    ## ❓ Clarifications

    {Questions asked and user answers from Stage 1}

    **Q: {question 1}**
    A: {user answer}

    **Q: {question 2}**
    A: {user answer}

    ---

    ## 🔍 Approach Analysis

    ### Approaches Considered:

    **1. {Approach 1 Name}** (Selected ✓)
    - Complexity: {complexity}
    - Pros: {benefits}
    - Cons: {drawbacks}

    **2. {Approach 2 Name}**
    - Complexity: {complexity}
    - Pros: {benefits}
    - Cons: {drawbacks}

    **Why selected**: {rationale for selection}

    **Scope Boundaries**:
    - IN SCOPE: {specific items included}
    - OUT OF SCOPE: {specific items excluded/deferred}

    ---

    ## Dependencies

    {prerequisites, external factors}

    ---

    *Planned via /ccpm:plan*
context:
  command: "plan"
```

7. Update status and labels:

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: update_issue
params:
  issueId: "{issue ID}"
  state: "Planned"
  labels: ["planned", "ready"]
context:
  command: "plan"
```

8. Display completion:

console.log('\n═══════════════════════════════════════');
console.log('✅ Planning Complete!');
console.log('═══════════════════════════════════════\n');
console.log(`📋 Issue: ${issueId} - ${issue.title}`);
console.log(`🔗 ${issue.url}`);
console.log(`\n📊 Plan Added:`);
console.log(`  ✅ ${checklistCount} subtasks`);
console.log(`  📁 ${filesCount} files to modify`);
console.log(`  ⚡ Complexity: ${complexity}`);
console.log(`\n💡 Next: /ccpm:work ${issueId}`);
```

### Step 2C: UPDATE Mode - Update Existing Plan

```yaml
## UPDATE: Update existing plan

1. Fetch current plan:

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: get_issue
params:
  issueId: "{issue ID}"
context:
  cache: true
  command: "plan"
```

2. Display current plan summary:

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log(`📋 Current Plan: ${issueId}`);
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log(`🏷️  Title: ${issue.title}`);
console.log(`📊 Status: ${issue.state.name}`);

const checklist = issue.description.match(/- \[([ x])\] .+/g) || [];
const completed = checklist.filter(i => i.includes('[x]')).length;
console.log(`🎯 Progress: ${completed}/${checklist.length} items\n`);

if (checklist.length > 0) {
  console.log('Current Checklist:');
  checklist.slice(0, 5).forEach((item, idx) => {
    const icon = item.includes('[x]') ? '✅' : '⏳';
    const text = item.replace(/- \[([ x])\] /, '');
    console.log(`  ${icon} ${idx + 1}. ${text}`);
  });
  if (checklist.length > 5) console.log(`  ... and ${checklist.length - 5} more\n`);
}

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('📝 Update Request');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log(updateText);
console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

3. Analyze update request:

// Detect change type
const changeType = detectChangeType(updateText);
// Returns: 'scope_change', 'approach_change', 'simplification', 'blocker', 'clarification'

4. Interactive clarification (v1.0 workflow - hybrid approach):

**Critical questions:** Use AskUserQuestion for interactive response
**Clarifications:** Output questions, wait for user response

if (requiresClarification(changeType, updateText)) {
  // For scope changes, approach changes - ask interactively
  if (changeType === 'scope_change' || changeType === 'approach_change') {
    const questions = generateClarificationQuestions(changeType, updateText, issue);

    AskUserQuestion({
      questions: questions  // 1-4 targeted questions
    });

    // Store answers for refinement
  }

  // For clarifications - output questions
  if (changeType === 'clarification') {
    console.log('\n💡 Questions to clarify:');
    const questions = generateClarificationQuestions(changeType, updateText, issue);
    questions.forEach((q, i) => console.log(`  ${i+1}. ${q.question}`));
    console.log('\nPlease provide clarification, then run the update again.');
    return;
  }
}

5. Deep research for update (v1.0 workflow):

**Research changes needed (parallel):**
a) Search codebase for new requirements
b) Search Linear for related issues
c) If approach change, research alternatives via Context7
d) Check git history for relevant patterns

**Generate updated plan with smart agent:**

Task: `
Update implementation plan for: ${issue.title}

Update request: ${updateText}
Change type: ${changeType}
${clarification ? `Clarification: ${JSON.stringify(clarification)}` : ''}

Current plan:
${issue.description}

Context gathered:
- Codebase research: [results]
- Similar issues: [if found]
- Alternative approaches: [if relevant]
- Git patterns: [if relevant]

Your task:
1. Analyze update request and current plan
2. Consider impact and alternatives
3. Determine what changes (keep/modify/add/remove)
4. Research new requirements via Context7
5. Update checklist accordingly
6. Adjust complexity if needed
7. Document changes and rationale

Provide:
- Updated checklist with changes highlighted
- Change summary (kept/modified/added/removed)
- Updated complexity if changed
- Rationale for all changes
- New uncertainties if any
`

6. Display change preview (v1.0 workflow):

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('📝 Proposed Changes');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log('✅ Kept:');
keptItems.forEach(i => console.log(`  • ${i}`));
console.log('\n✏️  Modified:');
modifiedItems.forEach(i => console.log(`  • ${i.old} → ${i.new}`));
console.log('\n➕ Added:');
addedItems.forEach(i => console.log(`  • ${i}`));
if (removedItems.length > 0) {
  console.log('\n❌ Removed:');
  removedItems.forEach(i => console.log(`  • ${i}`));
}

7. Get explicit confirmation (v1.0 workflow):

AskUserQuestion({
  questions: [{
    question: "Apply these changes to the plan?",
    header: "Confirm",
    multiSelect: false,
    options: [
      { label: "Yes, apply changes", description: "Update the plan with changes shown above" },
      { label: "Needs adjustment", description: "Refine the changes first" }
    ]
  }]
});

if (!confirmed) {
  console.log('\n⏸️  Update cancelled. Run the command again with refined changes.');
  return;
}

8. Update Linear with confirmed changes:

**Use the Task tool to update description:**

Invoke `ccpm:linear-operations`:
```
operation: update_issue_description
params:
  issueId: "{issue ID}"
  description: {updated description}
context:
  command: "plan"
  changeType: "{change type}"
```

**Use the Task tool to add comment:**

Invoke `ccpm:linear-operations`:
```
operation: create_comment
params:
  issueId: "{issue ID}"
  body: |
    ## 📝 Plan Updated

    **Change Type**: {change type}
    **Request**: {update text}

    ### Changes Made

    {change summary}

    ---
    *Updated via /ccpm:plan*
context:
  command: "plan"
```

9. Display completion:

console.log('\n✅ Plan Updated!');
console.log(`📋 Issue: ${issueId} - ${issue.title}`);
console.log(`🔗 ${issue.url}`);
console.log(`\n📊 Changes: ${changes.added} added, ${changes.modified} modified, ${changes.removed} removed`);
console.log(`\n💡 Next: /ccpm:work ${issueId}`);
```

### Helper Functions

```javascript
// Detect change type from update request
function detectChangeType(text) {
  const lower = text.toLowerCase();

  if (/(add|also|include|plus|additionally)/i.test(lower)) return 'scope_change';
  if (/(instead|different|change|use.*not)/i.test(lower)) return 'approach_change';
  if (/(remove|don't need|skip|simpler)/i.test(lower)) return 'simplification';
  if (/(blocked|can't|doesn't work|issue|problem)/i.test(lower)) return 'blocker';
  return 'clarification';
}
```

## Error Handling

### Invalid Issue ID
```
❌ Invalid issue ID format: proj123
Expected format: PROJ-123
```

### Issue Not Found
```
❌ Error fetching issue: Issue not found

Suggestions:
  - Verify the issue ID is correct
  - Check you have access to this Linear team
```

### Missing Title
```
❌ Missing arguments

Usage:
  /ccpm:plan "Task title" [project] [jira]  # Create new
  /ccpm:plan WORK-123                        # Plan existing
  /ccpm:plan WORK-123 "changes"              # Update plan
```

### Project Configuration Error
```
❌ Could not detect project configuration

Suggestions:
  - Specify project: /ccpm:plan "title" my-project
  - Configure project: /ccpm:project:add my-project
```

## Examples

### Example 1: CREATE with v1.0 workflow

```bash
/ccpm:plan "Add user authentication"

# Output:
# 🎯 Mode: CREATE
#
# ✅ Created issue: PSN-30
# 📋 Planning: PSN-30 - Add user authentication
#
# [Deep research: codebase, Linear, git history...]
# [Smart agent analyzes and considers approaches...]
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📋 Proposed Plan for Add user authentication
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 🎯 Recommended Approach:
# JWT-based authentication with refresh tokens...
#
# 💡 Alternatives Considered:
# 1. Session-based auth - rejected (scalability)
# 2. OAuth only - rejected (adds complexity)
#
# ✅ Implementation Checklist:
# - [ ] Create auth endpoints (/login, /logout, /refresh)
# - [ ] Add JWT validation middleware
# ...
#
# ⚠️ Uncertainties:
# - Which OAuth providers to support?
# - Password reset flow requirements?
#
# Does this plan look good? Any adjustments needed?
# [User confirms]
#
# ═══════════════════════════════════════
# ✅ Task Created & Planned!
# ═══════════════════════════════════════
#
# 📋 Issue: PSN-30 - Add user authentication
# 💡 Next: /ccpm:work PSN-30
```

### Example 2: UPDATE with interactive clarification

```bash
/ccpm:plan PSN-29 "Also add email notifications"

# Output:
# 🎯 Mode: UPDATE
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📋 Current Plan: PSN-29
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 🏷️  Title: Implement dark mode
# 🎯 Progress: 0/6 items
#
# [Shows clarification questions via AskUserQuestion]
#
# 1. Which events should trigger notifications?
#    • Theme change only
#    • All user preference changes
#
# 2. Notification delivery method?
#    • Email
#    • In-app
#    • Both
#
# [User answers interactively]
#
# [Deep research: email services, templates, best practices...]
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📝 Proposed Changes
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# ✅ Kept: 6 original items
# ➕ Added:
#   • Set up email service integration (SendGrid)
#   • Create notification templates
#   • Add notification preferences to user settings
#
# Apply these changes to the plan?
# [User confirms]
#
# ✅ Plan Updated!
# 📊 Changes: 3 added, 0 modified, 0 removed
```

## Key Optimizations

1. ✅ **Direct implementation** - No routing overhead, all modes in one file
2. ✅ **Linear subagent** - All ops cached (85-95% hit rate)
3. ✅ **Smart agent selection** - Automatic optimal agent choice
4. ✅ **v1.0 workflow** - Deep research, explicit confirmation, hybrid Q&A
5. ✅ **Parallel research** - Codebase + Linear + git + external PM
6. ✅ **Consolidated plan** - All in description, not scattered in comments

## Integration

- **After planning** → `/ccpm:work` to start implementation
- **During work** → `/ccpm:sync` to save progress
- **Before completion** → `/ccpm:verify` for quality checks
- **Finalize** → `/ccpm:done` to create PR and complete

## Notes

- **v1.0 workflow**: Deep research, multiple approaches, explicit confirmation
- **Hybrid Q&A**: Interactive (AskUserQuestion) for critical, output for clarifications
- **Description updates**: All plan content in description, comments for history only
- **Smart agents**: Automatic selection based on task type
- **Caching**: Linear subagent caches for 85-95% faster operations
