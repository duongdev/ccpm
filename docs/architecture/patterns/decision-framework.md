# CCPM Decision Framework

**Version:** 1.0.0
**Phase:** PSN-31 Phase 4
**Status:** Implementation Guide

## Executive Summary

This document catalogs all decision points across CCPM's 49+ commands and establishes the **Always-Ask Policy** for ambiguous scenarios. The framework ensures accuracy, prevents false assumptions, and maintains user control over critical decisions.

**Key Principle:** When in doubt, ask. Better to confirm than to assume incorrectly.

---

## Table of Contents

1. [Decision Point Taxonomy](#decision-point-taxonomy)
2. [Always-Ask Policy](#always-ask-policy)
3. [Decision Trees](#decision-trees)
4. [Command-Level Decision Catalog](#command-level-decision-catalog)
5. [Workflow State Tracking](#workflow-state-tracking)
6. [Accuracy Validation Framework](#accuracy-validation-framework)
7. [Implementation Guidelines](#implementation-guidelines)

---

## Decision Point Taxonomy

### Classification System

Decision points are categorized by **confidence level**:

| Category | Confidence | Behavior | Examples |
|----------|-----------|----------|----------|
| **Certain (100%)** | Unambiguous | Proceed automatically | Issue ID format validation, git status check |
| **High (80-99%)** | Strong heuristics | Proceed with confirmation display | Auto-detect issue from branch name |
| **Medium (50-79%)** | Multiple possibilities | Ask user to clarify | Status transition (multiple valid targets) |
| **Low (0-49%)** | Ambiguous | Always ask | Command routing, external system writes |

### Decision Domains

1. **Command Routing** - Which specialized command to invoke
2. **State Transitions** - How to update issue status
3. **Label Management** - Which labels to add/remove
4. **External System Integration** - When to write to Jira/Slack/etc
5. **Checklist Updates** - Which items to mark complete
6. **Project Detection** - Which project configuration to use
7. **Agent Selection** - Which agent to invoke
8. **Verification Gates** - When work is "done enough"

---

## Always-Ask Policy

### Core Principle

**When confidence < 80%, explicitly ask the user rather than making assumptions.**

### When to Ask

#### 1. Ambiguous Command Intent

```bash
# AMBIGUOUS: What does "plan" mean?
/ccpm:plan PSN-29

# Could mean:
# - Create new task with title "PSN-29" (unlikely but possible)
# - Plan existing task PSN-29 (most likely)
# - Update plan for PSN-29 (if description provided)

# SOLUTION: Use pattern matching
if ISSUE_ID_PATTERN.test(arg) → Plan existing
else → Create new
```

**Decision**: This is **High confidence (90%)** based on pattern matching → Proceed

#### 2. Multiple Valid State Transitions

```javascript
// Current state: "In Progress"
// User says: "I'm done"

// Possible transitions:
// - "In Review" (standard workflow)
// - "Done" (skip review)
// - "Verification" (QA needed)
// - "Blocked" (if issues found)

// CONFIDENCE: Medium (60%) - depends on project workflow
// ACTION: Ask user to select transition
```

**Decision**: This is **Medium confidence (60%)** → Ask

#### 3. External System Writes

```javascript
// User: "Update Jira with progress"

// Questions:
// - Which Jira ticket? (might not match Linear ID)
// - What status to set? (many options)
// - What comment to add? (user-specific)

// CONFIDENCE: Low (30%) - too many unknowns
// ACTION: Show preview, require confirmation
```

**Decision**: This is **Low confidence (30%)** → Always ask (per Safety Rules)

#### 4. Checklist Completion Detection

```javascript
// Files changed: auth.ts, login.tsx
// Unchecked items:
// - [ ] Implement authentication
// - [ ] Add login form
// - [ ] Write tests
// - [ ] Update documentation

// AI scores:
// - Implement authentication: 70 (high confidence)
// - Add login form: 60 (medium confidence)
// - Write tests: 20 (no test files changed)
// - Update docs: 10 (no doc files changed)

// CONFIDENCE: 70% for first, 60% for second
// ACTION: Pre-select high confidence, let user confirm
```

**Decision**: This is **High confidence for some (70%)**, **Medium for others (60%)** → Pre-select suggestions, allow user to adjust

### When NOT to Ask

#### Certain Decisions

1. **Format Validation** - Issue ID must match `[A-Z]+-\d+`
2. **Git Status** - Check for uncommitted changes automatically
3. **Branch Detection** - Extract issue ID from branch name pattern
4. **Linear Reads** - Always safe to fetch issue data
5. **Safety Rules** - Always block external writes without confirmation

---

## Decision Trees

### 1. Command Routing Decision Tree (`/ccpm:plan`)

```
User Input: /ccpm:plan [arg1] [arg2]
│
├─ arg1 is empty
│  └─ ERROR: Show usage
│
├─ arg1 matches ISSUE_ID_PATTERN ([A-Z]+-\d+)
│  │
│  ├─ arg2 is empty
│  │  └─ MODE: PLAN (plan existing task)
│  │     CONFIDENCE: 95%
│  │     ACTION: Proceed
│  │
│  └─ arg2 is provided
│     └─ MODE: UPDATE (update existing plan)
│        CONFIDENCE: 95%
│        ACTION: Proceed, but ask clarifying questions
│
└─ arg1 does NOT match ISSUE_ID_PATTERN
   └─ MODE: CREATE (create new task)
      CONFIDENCE: 90%
      ACTION: Proceed
      │
      ├─ If arg1 looks ambiguous (e.g., "PSN")
      │  └─ ASK: "Did you mean to plan existing issue or create new task?"
      │     OPTIONS: ["Plan existing", "Create new with this title"]
      │
      └─ Otherwise, proceed with CREATE
```

### 2. State Transition Decision Tree

```
Current State: [state]
User Action: [action]
│
├─ Explicit state provided by user
│  └─ CONFIDENCE: 100%
│     ACTION: Use provided state (after validation)
│
├─ Standard workflow transition available
│  │
│  ├─ Single next state (linear workflow)
│  │  └─ CONFIDENCE: 90%
│  │     ACTION: Proceed with display ("Moving to [state]")
│  │
│  └─ Multiple possible next states
│     └─ CONFIDENCE: 50%
│        ACTION: ASK user to choose
│        │
│        ├─ Based on project workflow config
│        │  └─ Show: "Your workflow → [options]"
│        │
│        └─ Based on checklist completion
│           └─ Show: "Checklist 100% → Ready for verification?"
│
└─ No clear next state
   └─ CONFIDENCE: 30%
      ACTION: ASK user to select from valid states
```

### 3. External System Write Decision Tree

```
User requests external write (Jira/Slack/Confluence)
│
├─ Safety Rules Check
│  └─ ALWAYS REQUIRE CONFIRMATION (per SAFETY_RULES.md)
│
├─ Build preview of what will be written
│  ├─ Target system
│  ├─ Target ticket/channel/page
│  ├─ Exact content
│  └─ Action type (create/update/comment)
│
├─ Display preview to user
│  └─ "🚨 CONFIRMATION REQUIRED"
│     "I will [action] to [system]:"
│     "---"
│     "[exact content]"
│     "---"
│     "Proceed? (yes/no)"
│
└─ Wait for explicit confirmation
   ├─ "yes" / "confirm" / "go ahead" / "proceed"
   │  └─ Execute write
   │
   └─ Anything else
      └─ Cancel operation
```

### 4. Checklist Update Decision Tree

```
Files changed: [list]
Unchecked items: [list]
│
├─ Score each item (0-100)
│  ├─ File path match: +30
│  ├─ File name exact match: +40
│  ├─ Large changes (50+ lines): +10
│  └─ Large changes (100+ lines): +20
│
├─ Categorize by confidence
│  ├─ High (50-100): Pre-select
│  ├─ Medium (30-49): Suggest
│  └─ Low (0-29): Available
│
├─ Present interactive selection
│  └─ AskUserQuestion with:
│     - Pre-selected high confidence items (✅)
│     - Suggested medium confidence items (💡)
│     - Available low confidence items ( )
│     - Allow user to adjust selections
│
└─ Apply user-confirmed selections only
```

### 5. Project Detection Decision Tree

```
User command with [project] argument
│
├─ Explicit project provided
│  └─ CONFIDENCE: 100%
│     ACTION: Use provided project
│
├─ No project provided
│  │
│  ├─ Auto-detect from git remote
│  │  ├─ Single match found
│  │  │  └─ CONFIDENCE: 95%
│  │  │     ACTION: Use detected project, display for confirmation
│  │  │
│  │  └─ Multiple matches found (monorepo subdirectories)
│  │     └─ CONFIDENCE: 60%
│  │        ACTION: ASK user to select
│  │
│  ├─ Auto-detect from directory path
│  │  ├─ Single match found
│  │  │  └─ CONFIDENCE: 90%
│  │  │     ACTION: Use detected project
│  │  │
│  │  └─ Multiple possible matches
│  │     └─ CONFIDENCE: 50%
│  │        ACTION: ASK user to clarify
│  │
│  └─ No detection possible
│     └─ CONFIDENCE: 0%
│        ACTION: ERROR with suggestions
│        "Could not detect project. Options:"
│        "1. Specify project: /ccpm:plan 'title' my-project"
│        "2. Configure project: /ccpm:project:add"
```

### 6. Verification Completion Decision Tree

```
User runs /ccpm:verify or /ccpm:done
│
├─ Check pre-conditions
│  ├─ Checklist incomplete
│  │  └─ BLOCK with error
│  │     CONFIDENCE: 100%
│  │     "Cannot verify: X/Y items incomplete"
│  │
│  ├─ Tests failing
│  │  └─ BLOCK with error
│  │     CONFIDENCE: 100%
│  │     "Cannot verify: Tests failing"
│  │
│  ├─ Uncommitted changes
│  │  └─ BLOCK with error
│  │     CONFIDENCE: 100%
│  │     "Commit changes first"
│  │
│  └─ All checks pass
│     └─ CONFIDENCE: 90%
│        ACTION: Proceed with verification
│
├─ Run verification
│  └─ Collect results
│
└─ Determine if "done"
   ├─ All critical checks pass
   │  ├─ Minor issues found
   │  │  └─ CONFIDENCE: 70%
   │  │     ACTION: ASK if acceptable
   │  │     "Found minor issues. Proceed anyway?"
   │  │
   │  └─ No issues
   │     └─ CONFIDENCE: 95%
   │        ACTION: Mark as verified
   │
   └─ Critical issues found
      └─ CONFIDENCE: 100%
         ACTION: BLOCK
         "Cannot complete: Critical issues found"
```

---

## Command-Level Decision Catalog

### Natural Workflow Commands (6)

#### 1. `/ccpm:plan`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Mode detection (create/plan/update) | 90-95% | Auto-detect from pattern |
| Project selection | 60-95% | Auto-detect, ask if ambiguous |
| Jira ticket association | 30% | Ask if not provided |
| Complexity estimation | 40% | AI suggests, user confirms |
| Label application | 70% | Apply defaults, user can adjust |

**Key Decision**: Mode Detection
- **Pattern**: First arg matches `[A-Z]+-\d+` = existing issue
- **Confidence**: 95%
- **Action**: Proceed automatically
- **Exception**: If arg is exactly "PSN" or similar short pattern, ask for clarification

#### 2. `/ccpm:work`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Issue detection from branch | 85% | Auto-detect, display confirmation |
| Mode (start vs resume) | 95% | Based on current status |
| Agent selection for analysis | 75% | Smart agent selector automatic |
| Status transition | 90% | Auto to "In Progress" |

**Key Decision**: Start vs Resume
- **Pattern**: Check current issue status
  - Planning/Backlog/Todo → START
  - In Progress → RESUME
  - Done/Cancelled → ERROR
- **Confidence**: 95%
- **Action**: Proceed automatically

#### 3. `/ccpm:sync`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Issue detection from branch | 85% | Auto-detect, display confirmation |
| Summary generation | 60% | Auto-generate from changes, user can override |
| Checklist item completion | 50-70% | AI suggests, user confirms via interactive selection |
| Progress percentage | 40% | Calculate from checklist, user can adjust |

**Key Decision**: Checklist Item Selection
- **Pattern**: Score items based on file changes
- **Confidence**: 50-70% per item
- **Action**: Pre-select high-confidence, ask user to confirm

#### 4. `/ccpm:commit`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Issue detection from branch | 85% | Auto-detect, display |
| Commit type (feat/fix/docs) | 70% | Detect from changes, ask if unclear |
| Commit scope | 60% | Extract from issue title, ask if unclear |
| Breaking change detection | 50% | Analyze, ask user to confirm |

**Key Decision**: Commit Type Detection
- **Pattern**: Analyze changed files and issue description
- **Confidence**: 70%
- **Action**: Suggest type, show in preview, allow edit

#### 5. `/ccpm:verify`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Issue detection from branch | 85% | Auto-detect |
| Verification success criteria | 60% | Use project standards, ask if unclear |
| Minor issues acceptable | 40% | Always ask user |
| Status transition after verify | 70% | Suggest "Ready for Review", ask to confirm |

**Key Decision**: Minor Issues Acceptable
- **Pattern**: Verification found minor issues (style, comments, etc)
- **Confidence**: 40%
- **Action**: Always ask "Found X minor issues. Mark as verified anyway?"

#### 6. `/ccpm:done`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Issue detection from branch | 85% | Auto-detect |
| PR creation | 90% | Auto with preview |
| Jira status update | 0% | Always ask (safety rules) |
| Slack notification | 0% | Always ask (safety rules) |
| Status transition to "Done" | 95% | Auto (internal tracking) |

**Key Decision**: External System Updates
- **Confidence**: 0% (always ask per safety rules)
- **Action**: Display preview, require explicit "yes"

### Planning Commands (7)

#### 7. `/ccpm:planning:create`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Project detection | 60-95% | Auto-detect, ask if ambiguous |
| Label application | 70% | Use project defaults |
| Status selection | 90% | Default to "Backlog" |
| Jira research required | 50% | Ask if Jira ticket provided |

#### 8. `/ccpm:planning:plan`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Already planned check | 100% | Block if checklist exists, suggest update |
| Complexity estimation | 40% | AI suggests, display, no auto-write |
| File identification | 60% | AI suggests, user reviews |

#### 9. `/ccpm:planning:update`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Change type detection | 65% | Detect, ask clarifying questions |
| Scope change impact | 40% | Analyze, ask user to confirm |
| Checklist modification | 50% | Show diff, require confirmation |

**Key Decision**: Change Type Detection
- **Patterns**:
  - "add", "also", "include" → scope_change (70%)
  - "instead", "use X not Y" → approach_change (75%)
  - "remove", "skip", "simpler" → simplification (80%)
  - "blocked", "can't", "issue" → blocker (85%)
- **Action**: Detect type, ask 1-4 clarifying questions based on type

#### 10-12. UI Design Commands

| Command | Key Decision | Confidence | Policy |
|---------|-------------|-----------|--------|
| `design-ui` | Design style selection | 30% | Always ask user preference |
| `design-refine` | Which option to refine | 100% | User specifies explicitly |
| `design-approve` | Final design selection | 100% | User specifies explicitly |

#### 13. `/ccpm:planning:quick-plan`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Skip external research | 100% | Intentional (command purpose) |
| Simplified checklist | 80% | Generate from description only |

### Implementation Commands (4)

#### 14. `/ccpm:implementation:start`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Agent assignment | 60% | Auto-assign based on task analysis |
| Parallel vs sequential | 55% | Detect dependencies, ask if unclear |
| Status transition | 95% | Auto to "In Progress" |

**Key Decision**: Agent Assignment
- **Confidence**: 60%
- **Action**: Use `/ccpm:utils:auto-assign` which asks user to review assignments

#### 15. `/ccpm:implementation:next`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Next action suggestion | 65% | Analyze context, suggest, user chooses |
| Dependency resolution | 50% | Detect, ask user to confirm order |

#### 16. `/ccpm:implementation:update`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Subtask index validation | 100% | User provides explicitly |
| Status value | 100% | User provides explicitly |

#### 17. `/ccpm:implementation:sync`

**See `/ccpm:sync` above (natural command version)**

### Verification Commands (3)

#### 18. `/ccpm:verification:check`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Which checks to run | 80% | Run all standard checks |
| Failure blocking | 100% | Block if critical checks fail |
| Continue after warnings | 40% | Ask user |

#### 19. `/ccpm:verification:verify`

**See `/ccpm:verify` above (natural command version)**

#### 20. `/ccpm:verification:fix`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Issue diagnosis | 60% | AI analyzes, presents findings |
| Fix approach | 40% | Suggest, ask user to approve |
| Auto-fix vs manual | 30% | Always ask for risky changes |

### Complete Commands (1)

#### 21. `/ccpm:complete:finalize`

**See `/ccpm:done` above (natural command version)**

### Spec Management Commands (6)

#### 22. `/ccpm:spec:create`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Spec type (epic/feature) | 100% | User specifies explicitly |
| Parent relationship | 95% | User provides if needed |
| Linear document creation | 90% | Auto-create, link to issue |

#### 23. `/ccpm:spec:write`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Section to write | 100% | User specifies explicitly |
| Context research required | 60% | Auto-research, ask if extensive |
| Overwrite existing | 50% | Ask if section already has content |

**Key Decision**: Overwrite Existing Content
- **Confidence**: 50%
- **Action**: "Section [X] already has content. Overwrite or append?"

#### 24. `/ccpm:spec:review`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Grading criteria | 85% | Use standard rubric |
| Passing grade threshold | 90% | B- or higher = pass |

#### 25. `/ccpm:spec:sync`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Drift detection | 70% | Compare spec vs implementation |
| Which to update | 0% | Always ask user |

**Key Decision**: Spec vs Code Truth
- **Confidence**: 0% (can't assume)
- **Action**: "Found drift. Update spec to match code, or update code to match spec?"

#### 26. `/ccpm:spec:break-down`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Task granularity | 50% | Suggest size, ask user to adjust |
| Task creation | 60% | Preview all, ask to confirm batch |

#### 27. `/ccpm:spec:migrate`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| File categorization | 70% | Auto-categorize, show preview |
| Linear document structure | 80% | Use standard templates |

### Utility Commands (15)

#### 28. `/ccpm:utils:status`

**No significant decisions** - Read-only display

#### 29. `/ccpm:utils:context`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Which files to load | 70% | Based on issue description |
| Environment setup | 80% | Based on project config |

#### 30. `/ccpm:utils:agents`

**No decisions** - Display only

#### 31. `/ccpm:utils:auto-assign`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Agent assignment | 60% | AI suggests, user reviews |
| Assignment confidence | Varies | Display confidence scores |

**Key Decision**: Assignment Confirmation
- **Action**: Always show proposed assignments and ask user to review/adjust

#### 32. `/ccpm:utils:cheatsheet`

**No decisions** - Display only

#### 33. `/ccpm:utils:dependencies`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Dependency detection | 65% | Analyze checklist, ask to verify |
| Execution order | 70% | Suggest order, user can adjust |

#### 34. `/ccpm:utils:help`

**No decisions** - Contextual help display

#### 35. `/ccpm:utils:insights`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Complexity assessment | 50% | AI analyzes, presents insights |
| Risk identification | 45% | Suggest risks, user validates |
| Timeline estimate | 40% | Suggest, clearly mark as estimate |

**Key Decision**: Presenting Estimates
- **Action**: Always label as "Estimated" and "Subject to change"

#### 36. `/ccpm:utils:organize-docs`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| File categorization | 75% | Auto-categorize, show preview |
| Move operation | 0% | Always confirm before moving |

#### 37. `/ccpm:utils:report`

**No significant decisions** - Aggregates and displays data

#### 38. `/ccpm:utils:rollback`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Which version to restore | 100% | User selects from history |
| Destructive operation | 0% | Always confirm |

#### 39. `/ccpm:utils:search`

**No decisions** - Search and display

#### 40. `/ccpm:utils:sync-status`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Jira status mapping | 50% | Suggest mapping, ask to confirm |
| Write to Jira | 0% | Always confirm (safety rules) |

#### 41. `/ccpm:utils:update-checklist`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Which items to update | 100% | User specifies explicitly |
| Markdown formatting | 90% | Auto-format, preview changes |

#### 42. `/ccpm:utils:figma-refresh`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| Cache invalidation | 100% | Explicit command purpose |
| Update Linear with new data | 80% | Auto-update if changed |

### Project Management Commands (9)

#### 43-51. Project Commands

| Command | Key Decisions | Policy |
|---------|--------------|--------|
| `project:add` | Template selection | Ask if not specified |
| `project:update` | Which field to update | User specifies |
| `project:delete` | Destructive operation | Require --force flag + confirmation |
| `project:list` | Display format | Standard format |
| `project:show` | Detail level | Full details |
| `project:set` | Active project change | Confirm with display |
| `project:subdir:*` | Monorepo subdirectory ops | Validate before modifying |

### PR Management Commands (1)

#### 52. `/ccpm:pr:check-bitbucket`

| Decision Point | Confidence | Policy |
|---------------|-----------|--------|
| PR number extraction | 90% | Parse from URL or number |
| Analysis depth | 80% | Standard checks |
| Comment posting | 0% | Always ask (safety rules) |

---

## Workflow State Tracking

### State Machine Design

```yaml
states:
  IDEA:
    description: "Initial concept, not yet planned"
    next_states: [PLANNED, CANCELLED]
    confidence_to_transition: HIGH

  PLANNED:
    description: "Requirements gathered, plan created"
    next_states: [IMPLEMENTING, IDEA, CANCELLED]
    confidence_to_transition: MEDIUM

  IMPLEMENTING:
    description: "Work in progress"
    next_states: [VERIFYING, PLANNED, BLOCKED]
    confidence_to_transition: MEDIUM

  BLOCKED:
    description: "Cannot proceed due to blocker"
    next_states: [IMPLEMENTING, CANCELLED]
    confidence_to_transition: HIGH

  VERIFYING:
    description: "Quality checks and verification"
    next_states: [VERIFIED, IMPLEMENTING]
    confidence_to_transition: HIGH

  VERIFIED:
    description: "Verified and ready to complete"
    next_states: [COMPLETE, IMPLEMENTING]
    confidence_to_transition: HIGH

  COMPLETE:
    description: "Task finalized and closed"
    next_states: []
    confidence_to_transition: N/A

  CANCELLED:
    description: "Task cancelled"
    next_states: []
    confidence_to_transition: N/A
```

### Transition Confidence Rules

| From State | To State | Confidence | Policy |
|-----------|----------|-----------|--------|
| IDEA → PLANNED | 95% | Auto (via `/ccpm:plan`) |
| PLANNED → IMPLEMENTING | 95% | Auto (via `/ccpm:work`) |
| IMPLEMENTING → VERIFYING | 70% | Ask if checklist incomplete |
| IMPLEMENTING → BLOCKED | 90% | Auto if blockers detected |
| VERIFYING → VERIFIED | 85% | Auto if all checks pass |
| VERIFIED → COMPLETE | 95% | Auto (via `/ccpm:done`) |
| Any → CANCELLED | 50% | Always ask for confirmation |

### State Persistence

```javascript
// State tracking stored in Linear issue custom fields
interface WorkflowState {
  phase: string;              // Current CCPM workflow phase
  lastCommand: string;         // Last command executed
  lastUpdate: string;          // Timestamp of last update
  autoTransitions: boolean;    // Allow auto-transitions
  verificationGate: string;    // Which gate required
  checklistRequired: boolean;  // Enforce checklist completion
}

// Update state on every command
function updateWorkflowState(issueId: string, command: string, phase: string) {
  linearMCP.updateIssue({
    issueId,
    customFields: {
      ccpmPhase: phase,
      ccpmLastCommand: command,
      ccpmLastUpdate: new Date().toISOString()
    }
  });
}
```

---

## Accuracy Validation Framework

### Validation Categories

#### 1. Pre-Command Validation

**Purpose**: Catch errors before execution

```javascript
// Example: Validate issue ID before any operation
function validateIssueId(input: string): ValidationResult {
  // Pattern check
  if (!/ ^[A-Z]+-\d+$/.test(input)) {
    return {
      valid: false,
      confidence: 0,
      error: "Invalid format. Expected: PROJ-123",
      suggestions: ["Check issue ID spelling", "Verify issue exists in Linear"]
    };
  }

  // Confidence high - pattern matches
  return {
    valid: true,
    confidence: 95,
    normalized: input.toUpperCase()
  };
}
```

#### 2. During-Command Validation

**Purpose**: Validate intermediate steps

```javascript
// Example: Validate state transition is allowed
async function validateStateTransition(
  issueId: string,
  fromState: string,
  toState: string
): Promise<ValidationResult> {
  // Get workflow config
  const workflow = await getWorkflowConfig(issueId);

  // Check if transition is valid
  const allowed = workflow[fromState]?.next_states.includes(toState);

  if (!allowed) {
    return {
      valid: false,
      confidence: 100,
      error: `Cannot transition from ${fromState} to ${toState}`,
      suggestions: workflow[fromState]?.next_states.map(s => `Try: ${s}`)
    };
  }

  return {
    valid: true,
    confidence: 95
  };
}
```

#### 3. Post-Command Validation

**Purpose**: Verify command achieved desired outcome

```javascript
// Example: Verify issue was updated successfully
async function verifyIssueUpdate(
  issueId: string,
  expectedChanges: Partial<Issue>
): Promise<ValidationResult> {
  // Fetch current state
  const issue = await linearMCP.getIssue(issueId);

  // Validate each expected change
  const mismatches = [];

  if (expectedChanges.state && issue.state.name !== expectedChanges.state) {
    mismatches.push(`State: expected ${expectedChanges.state}, got ${issue.state.name}`);
  }

  if (expectedChanges.labels) {
    const missing = expectedChanges.labels.filter(
      l => !issue.labels.some(il => il.name === l)
    );
    if (missing.length > 0) {
      mismatches.push(`Missing labels: ${missing.join(', ')}`);
    }
  }

  if (mismatches.length > 0) {
    return {
      valid: false,
      confidence: 100,
      error: "Update verification failed",
      details: mismatches
    };
  }

  return {
    valid: true,
    confidence: 100
  };
}
```

### Accuracy Metrics

Track decision accuracy over time:

```javascript
interface AccuracyMetrics {
  command: string;
  decisionPoint: string;
  confidence: number;
  userAccepted: boolean;   // Did user accept AI suggestion?
  userModified: boolean;    // Did user modify suggestion?
  timestamp: string;
}

// Example: Track checklist item suggestions
function trackChecklistAccuracy(
  suggestions: ChecklistItem[],
  userSelections: ChecklistItem[]
) {
  suggestions.forEach(item => {
    const accepted = userSelections.some(s => s.index === item.index);

    logAccuracy({
      command: 'sync',
      decisionPoint: 'checklist_items',
      confidence: item.score,
      userAccepted: accepted,
      userModified: false,
      timestamp: new Date().toISOString()
    });
  });
}

// Analyze over time
function getAccuracyReport(command: string, decisionPoint: string) {
  const metrics = getMetrics({ command, decisionPoint });

  return {
    totalDecisions: metrics.length,
    acceptanceRate: metrics.filter(m => m.userAccepted).length / metrics.length,
    averageConfidence: metrics.reduce((sum, m) => sum + m.confidence, 0) / metrics.length,
    confidenceVsAccuracy: correlate(
      metrics.map(m => m.confidence),
      metrics.map(m => m.userAccepted ? 100 : 0)
    )
  };
}
```

### False Positive Prevention

#### Pattern: Checklist Completion

**Problem**: AI marks item complete that isn't actually done

**Solution**:
1. Show confidence score for each suggestion (50-100)
2. Pre-select only high confidence (70+)
3. Allow user to adjust before applying
4. Track accuracy over time

```javascript
// Never auto-mark complete without user confirmation
function suggestChecklistCompletions(
  items: ChecklistItem[],
  changes: GitChanges
): SuggestionSet {
  const suggestions = items.map(item => ({
    item,
    score: scoreItem(item, changes),
    autoSelect: false  // NEVER auto-select
  }));

  // Only pre-select high confidence
  suggestions.forEach(s => {
    s.autoSelect = s.score >= 70;
  });

  return {
    suggestions,
    requiresConfirmation: true,  // ALWAYS require confirmation
    allowAdjustment: true
  };
}
```

#### Pattern: External System Writes

**Problem**: AI posts to Jira/Slack without user awareness

**Solution**: ABSOLUTE RULE per SAFETY_RULES.md

```javascript
function writeToExternalSystem(system: string, content: any) {
  // ABSOLUTE BLOCK
  console.log('🚨 CONFIRMATION REQUIRED');
  console.log(`I will post to ${system}:`);
  console.log('---');
  console.log(JSON.stringify(content, null, 2));
  console.log('---');
  console.log('Proceed? (Type "yes" to confirm)');

  // MUST wait for explicit "yes"
  const response = await getUserInput();

  if (response.toLowerCase() !== 'yes') {
    console.log('❌ Cancelled');
    return { cancelled: true };
  }

  // Only now proceed
  return executeWrite(system, content);
}
```

---

## Implementation Guidelines

### For Command Developers

#### 1. Classify Every Decision Point

Before implementing a command, identify ALL decision points:

```yaml
command: /ccpm:plan
decision_points:
  - name: mode_detection
    confidence: 95%
    policy: auto_detect
    fallback: ask_user

  - name: project_selection
    confidence: 60-95%
    policy: auto_detect_with_display
    fallback: ask_user

  - name: label_application
    confidence: 70%
    policy: apply_defaults
    fallback: user_can_adjust
```

#### 2. Implement Confidence-Based Branching

```javascript
async function executeCommand(args) {
  // Decision 1: Mode detection
  const modeResult = detectMode(args);

  if (modeResult.confidence >= 80) {
    // High confidence - proceed with display
    console.log(`✅ Detected mode: ${modeResult.mode}`);
    return executeMode(modeResult.mode);
  } else if (modeResult.confidence >= 50) {
    // Medium confidence - ask with suggestion
    return askUser({
      question: "What would you like to do?",
      suggestion: modeResult.mode,
      confidence: modeResult.confidence,
      options: modeResult.alternatives
    });
  } else {
    // Low confidence - ask without suggestion
    return askUser({
      question: "What would you like to do?",
      options: getAllOptions()
    });
  }
}
```

#### 3. Use AskUserQuestion Consistently

```javascript
// Standard pattern for asking
const answer = await AskUserQuestion({
  questions: [{
    question: "Which mode do you want?",
    header: "Mode",
    multiSelect: false,
    options: [
      {
        label: "Create new task",
        description: "Start from scratch with a new Linear issue"
      },
      {
        label: "Plan existing task",
        description: "Add implementation plan to existing issue"
      },
      {
        label: "Update existing plan",
        description: "Modify the plan for an existing issue"
      }
    ]
  }]
});
```

#### 4. Always Validate and Display

```javascript
// Before making changes, show what will happen
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('📝 Proposed Changes');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
console.log(`Issue: ${issueId}`);
console.log(`Status: ${currentStatus} → ${newStatus}`);
console.log(`Labels: +${labelsToAdd.join(', ')} -${labelsToRemove.join(', ')}`);
console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

// Then ask for confirmation if needed
if (requiresConfirmation) {
  const confirmed = await askUserConfirmation();
  if (!confirmed) {
    console.log('❌ Cancelled');
    return;
  }
}
```

#### 5. Track Decision Accuracy

```javascript
// After user makes decision, log it
function logDecision(decision: Decision, userChoice: any) {
  // Send to telemetry
  analytics.track('decision_made', {
    command: decision.command,
    decisionPoint: decision.point,
    aiConfidence: decision.confidence,
    aiSuggestion: decision.suggestion,
    userChoice: userChoice,
    userModified: userChoice !== decision.suggestion,
    timestamp: new Date().toISOString()
  });
}
```

### Testing Decision Points

#### Unit Tests

```javascript
describe('Mode Detection', () => {
  it('should detect PLAN mode with high confidence', () => {
    const result = detectMode(['PSN-29']);
    expect(result.mode).toBe('PLAN');
    expect(result.confidence).toBeGreaterThan(90);
  });

  it('should detect CREATE mode with high confidence', () => {
    const result = detectMode(['"Add user auth"']);
    expect(result.mode).toBe('CREATE');
    expect(result.confidence).toBeGreaterThan(90);
  });

  it('should have low confidence for ambiguous input', () => {
    const result = detectMode(['PSN']);
    expect(result.confidence).toBeLessThan(50);
    expect(result.shouldAsk).toBe(true);
  });
});
```

#### Integration Tests

```javascript
describe('/ccpm:plan Integration', () => {
  it('should ask user when input is ambiguous', async () => {
    const askUserQuestionMock = jest.fn();

    await executePlan(['PSN'], { askUserQuestion: askUserQuestionMock });

    expect(askUserQuestionMock).toHaveBeenCalled();
    expect(askUserQuestionMock.mock.calls[0][0].questions[0].question)
      .toContain('Which mode');
  });
});
```

---

## Summary

This decision framework provides:

1. **Taxonomy** - Clear categories for decision types
2. **Policy** - When to ask vs when to proceed
3. **Trees** - Visual representation of decision logic
4. **Catalog** - Exhaustive list of all 49+ command decision points
5. **State Tracking** - How to maintain workflow state
6. **Validation** - How to ensure accuracy
7. **Guidelines** - How to implement consistently

**Key Takeaway**: When confidence < 80%, ask the user. Better to confirm than to assume incorrectly.

---

## Next Steps

1. **Implement Always-Ask Policy** - Update all commands with confidence thresholds
2. **Add State Tracking** - Store workflow state in Linear custom fields
3. **Build Validation Framework** - Add pre/during/post validations
4. **Create Accuracy Metrics** - Track decision accuracy over time
5. **Update Documentation** - Document all decision points for each command

---

**Related Documents**:
- [Safety Rules](../../commands/SAFETY_RULES.md)
- [Natural Workflow Commands](../../commands/README.md#natural-workflow)
- [Linear Subagent Architecture](./linear-subagent-architecture.md)
- [Interactive Mode Guide](../guides/interactive-mode.md)
