# Implementing the Always-Ask Policy

**Version:** 1.0.0
**Phase:** PSN-31 Phase 4
**Audience:** CCPM Command Developers

## Overview

This guide provides practical instructions for implementing the Always-Ask Policy across all CCPM commands. It includes code patterns, examples, and best practices for handling ambiguous decisions.

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Confidence Thresholds](#confidence-thresholds)
3. [Implementation Patterns](#implementation-patterns)
4. [Testing Decisions](#testing-decisions)
5. [Common Scenarios](#common-scenarios)
6. [Code Examples](#code-examples)

---

## Core Principles

### The Always-Ask Rule

**When confidence < 80%, explicitly ask the user rather than making assumptions.**

### Why This Matters

```
Without Always-Ask:
User: /ccpm:plan PSN
AI: (assumes it's issue ID PSN-29)
AI: (plans wrong issue)
Result: ❌ False positive, wasted time

With Always-Ask:
User: /ccpm:plan PSN
AI: "Did you mean to:
     1. Plan existing issue PSN-29
     2. Create new task titled 'PSN'"
Result: ✅ User confirms intent, correct action
```

### Three-Tier Response System

```yaml
High Confidence (80-100%):
  action: Proceed automatically
  display: Show what you're doing
  example: "✅ Detected mode: PLAN"

Medium Confidence (50-79%):
  action: Suggest and confirm
  display: Show suggestion with confidence
  example: "Suggested: feat (75% confidence). Proceed?"

Low Confidence (0-49%):
  action: Always ask
  display: Show options, no suggestion
  example: "Select commit type: feat, fix, docs..."
```

---

## Confidence Thresholds

### Decision Confidence Matrix

| Confidence | Range | Behavior | Code Pattern |
|-----------|-------|----------|--------------|
| **CERTAIN** | 95-100% | Auto proceed | `if (confidence >= 95) { proceed(); }` |
| **HIGH** | 80-94% | Proceed with display | `if (confidence >= 80) { display(); proceed(); }` |
| **MEDIUM** | 50-79% | Suggest and confirm | `if (confidence >= 50) { suggest(); ask(); }` |
| **LOW** | 0-49% | Always ask | `ask(); // no suggestion` |

### Calculating Confidence

```typescript
interface ConfidenceResult {
  confidence: number;  // 0-100
  suggestion: any;     // What AI thinks is correct
  alternatives: any[]; // Other possibilities
  reasoning: string;   // Why this confidence
}

function calculateConfidence(
  input: any,
  context: Context
): ConfidenceResult {
  let confidence = 0;
  let reasoning = [];

  // Add confidence from different signals
  if (exactPatternMatch(input)) {
    confidence += 50;
    reasoning.push("Exact pattern match");
  }

  if (contextualMatch(input, context)) {
    confidence += 30;
    reasoning.push("Contextual match");
  }

  if (historicalSuccess(input)) {
    confidence += 20;
    reasoning.push("Historical success rate");
  }

  return {
    confidence: Math.min(confidence, 100),
    suggestion: determineSuggestion(input),
    alternatives: determineAlternatives(input),
    reasoning: reasoning.join(", ")
  };
}
```

---

## Implementation Patterns

### Pattern 1: High Confidence with Display

**Use when**: Pattern matching is clear (95%+ confidence)

```typescript
// Example: Issue ID validation
const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/;

function parseIssueId(input: string): Result {
  if (ISSUE_ID_PATTERN.test(input)) {
    // ✅ CONFIDENCE: 95%
    console.log(`✅ Detected issue: ${input}`);
    return {
      success: true,
      issueId: input,
      confidence: 95
    };
  }

  // ❌ CONFIDENCE: 0%
  return {
    success: false,
    error: "Invalid issue ID format",
    confidence: 0
  };
}
```

### Pattern 2: Medium Confidence with Suggestion

**Use when**: Multiple possibilities, but one is more likely (50-79% confidence)

```typescript
// Example: Commit type detection
function detectCommitType(
  files: GitChanges,
  description: string
): ConfidenceResult {
  const scores = {
    feat: 0,
    fix: 0,
    docs: 0,
    refactor: 0
  };

  // Score each type
  if (hasNewFeatureFiles(files)) scores.feat += 40;
  if (description.includes('add') || description.includes('new')) {
    scores.feat += 30;
  }

  if (description.includes('fix') || description.includes('bug')) {
    scores.fix += 50;
  }

  // ... more scoring logic

  const topType = Object.entries(scores)
    .sort(([,a], [,b]) => b - a)[0];

  const confidence = topType[1];

  if (confidence >= 50 && confidence < 80) {
    // ⚠️ MEDIUM CONFIDENCE
    return {
      confidence,
      suggestion: topType[0],
      alternatives: Object.keys(scores).filter(k => k !== topType[0]),
      shouldAsk: true,
      message: `Suggested: ${topType[0]} (${confidence}% confidence). Correct?`
    };
  }

  // Either high confidence or low confidence
  return {
    confidence,
    suggestion: confidence >= 80 ? topType[0] : null,
    alternatives: Object.keys(scores),
    shouldAsk: confidence < 80
  };
}
```

### Pattern 3: Low Confidence - Always Ask

**Use when**: Too ambiguous to make a suggestion (0-49% confidence)

```typescript
// Example: Ambiguous command input
function parseCommand(input: string): ConfidenceResult {
  // Check if input is ambiguous
  if (input === "PSN" || input.length <= 3) {
    // ❌ LOW CONFIDENCE
    return {
      confidence: 30,
      suggestion: null,  // No suggestion
      alternatives: [
        "Plan existing issue",
        "Create new task with this title"
      ],
      shouldAsk: true,
      message: "Input is ambiguous. What did you mean?"
    };
  }

  // ... normal parsing
}
```

### Pattern 4: External Writes - Always Confirm

**Use when**: Writing to external PM systems (CONFIDENCE: 0%)

```typescript
// Example: Jira status update
async function updateJiraStatus(
  ticket: string,
  status: string,
  comment: string
): Promise<Result> {
  // 🚨 SAFETY RULE: ALWAYS CONFIRM
  console.log('🚨 CONFIRMATION REQUIRED\n');
  console.log(`I will update Jira ticket ${ticket}:`);
  console.log('---');
  console.log(`Status: ${status}`);
  console.log(`Comment: ${comment}`);
  console.log('---\n');
  console.log('Proceed? (Type "yes" to confirm)');

  const response = await getUserInput();

  if (response.toLowerCase() !== 'yes') {
    console.log('❌ Cancelled');
    return { cancelled: true };
  }

  // Only now execute
  return await jiraMCP.updateIssue(ticket, { status, comment });
}
```

---

## Testing Decisions

### Unit Tests for Confidence

```typescript
describe('Decision Confidence', () => {
  describe('parseIssueId', () => {
    it('should have 95% confidence for valid issue ID', () => {
      const result = parseIssueId('PSN-29');
      expect(result.confidence).toBeGreaterThanOrEqual(95);
      expect(result.success).toBe(true);
    });

    it('should have 0% confidence for invalid format', () => {
      const result = parseIssueId('PSN');
      expect(result.confidence).toBe(0);
      expect(result.success).toBe(false);
    });
  });

  describe('detectCommitType', () => {
    it('should suggest "feat" with medium confidence for new features', () => {
      const result = detectCommitType(
        { added: ['feature.ts'], modified: [] },
        'Add new authentication'
      );
      expect(result.suggestion).toBe('feat');
      expect(result.confidence).toBeGreaterThanOrEqual(50);
      expect(result.confidence).toBeLessThan(80);
      expect(result.shouldAsk).toBe(true);
    });

    it('should ask without suggestion for ambiguous changes', () => {
      const result = detectCommitType(
        { added: [], modified: ['config.json'] },
        'Update'
      );
      expect(result.suggestion).toBeNull();
      expect(result.confidence).toBeLessThan(50);
      expect(result.shouldAsk).toBe(true);
    });
  });
});
```

### Integration Tests

```typescript
describe('Command Integration', () => {
  it('should ask user when input is ambiguous', async () => {
    const askMock = jest.fn().mockResolvedValue({ mode: 'create' });

    await executePlan(['PSN'], { askUserQuestion: askMock });

    expect(askMock).toHaveBeenCalled();
    expect(askMock.mock.calls[0][0].questions[0].question)
      .toContain('What did you mean');
  });

  it('should not ask when confidence is high', async () => {
    const askMock = jest.fn();

    await executePlan(['PSN-29'], { askUserQuestion: askMock });

    expect(askMock).not.toHaveBeenCalled();
  });
});
```

### Accuracy Tracking

```typescript
// Track decision accuracy over time
interface DecisionLog {
  timestamp: string;
  command: string;
  decisionPoint: string;
  confidence: number;
  suggestion: any;
  userChoice: any;
  wasCorrect: boolean;
}

function logDecision(
  command: string,
  decisionPoint: string,
  confidence: number,
  suggestion: any,
  userChoice: any
) {
  const log: DecisionLog = {
    timestamp: new Date().toISOString(),
    command,
    decisionPoint,
    confidence,
    suggestion,
    userChoice,
    wasCorrect: suggestion === userChoice
  };

  // Store in telemetry
  analytics.track('decision_accuracy', log);
}

// Analyze accuracy by confidence level
function analyzeAccuracy(logs: DecisionLog[]) {
  const byConfidence = {
    high: logs.filter(l => l.confidence >= 80),
    medium: logs.filter(l => l.confidence >= 50 && l.confidence < 80),
    low: logs.filter(l => l.confidence < 50)
  };

  return {
    high: {
      count: byConfidence.high.length,
      accuracy: byConfidence.high.filter(l => l.wasCorrect).length / byConfidence.high.length
    },
    medium: {
      count: byConfidence.medium.length,
      accuracy: byConfidence.medium.filter(l => l.wasCorrect).length / byConfidence.medium.length
    },
    low: {
      count: byConfidence.low.length,
      accuracy: byConfidence.low.filter(l => l.wasCorrect).length / byConfidence.low.length
    }
  };
}
```

---

## Common Scenarios

### Scenario 1: Mode Detection

**Problem**: User types `/ccpm:plan PSN-29`
**Question**: Create new task or plan existing?

```typescript
function detectPlanMode(arg1: string, arg2?: string): ModeResult {
  const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/;

  // Case 1: Clear issue ID pattern
  if (ISSUE_ID_PATTERN.test(arg1)) {
    if (arg2) {
      // Has second argument = UPDATE mode
      return {
        mode: 'UPDATE',
        confidence: 95,
        shouldAsk: false,
        display: `✅ Detected mode: UPDATE`
      };
    } else {
      // No second argument = PLAN mode
      return {
        mode: 'PLAN',
        confidence: 95,
        shouldAsk: false,
        display: `✅ Detected mode: PLAN`
      };
    }
  }

  // Case 2: Ambiguous short input
  if (arg1.length <= 3) {
    return {
      mode: null,
      confidence: 30,
      shouldAsk: true,
      question: "What did you mean?",
      options: [
        { label: "Plan existing issue", value: "PLAN" },
        { label: "Create new task", value: "CREATE" }
      ]
    };
  }

  // Case 3: Looks like a title
  return {
    mode: 'CREATE',
    confidence: 90,
    shouldAsk: false,
    display: `✅ Detected mode: CREATE`
  };
}
```

### Scenario 2: State Transition

**Problem**: Issue is "In Progress", user runs `/ccpm:verify`
**Question**: Move to "In Review" or "Done"?

```typescript
async function determineNextState(
  currentState: string,
  context: Context
): Promise<StateResult> {
  // Get workflow config
  const workflow = await getWorkflowConfig(context.projectId);
  const validNextStates = workflow[currentState]?.nextStates || [];

  // Case 1: Only one valid next state
  if (validNextStates.length === 1) {
    return {
      state: validNextStates[0],
      confidence: 90,
      shouldAsk: false,
      display: `Moving to ${validNextStates[0]}`
    };
  }

  // Case 2: Multiple valid states - check checklist
  const checklistComplete = await isChecklistComplete(context.issueId);

  if (checklistComplete && validNextStates.includes('Done')) {
    return {
      state: 'Done',
      confidence: 85,
      shouldAsk: true,
      question: "Checklist is 100% complete. Move to Done?",
      options: [
        { label: "Yes, mark as Done", value: "Done" },
        { label: "No, move to Review first", value: "In Review" }
      ]
    };
  }

  // Case 3: Multiple states, no clear winner
  return {
    state: null,
    confidence: 50,
    shouldAsk: true,
    question: "Select next state:",
    options: validNextStates.map(s => ({
      label: s,
      value: s,
      description: workflow[s]?.description
    }))
  };
}
```

### Scenario 3: Checklist Item Selection

**Problem**: Files changed, which checklist items are complete?
**Question**: Mark items 1 and 2 as complete?

```typescript
interface ChecklistItem {
  index: number;
  text: string;
  score: number;
  confidence: number;
}

function scoreChecklistItems(
  items: string[],
  changes: GitChanges
): ChecklistItem[] {
  return items.map((text, index) => {
    let score = 0;
    const keywords = extractKeywords(text);

    // File path matches
    changes.modified.concat(changes.added).forEach(file => {
      if (keywords.some(kw => file.toLowerCase().includes(kw))) {
        score += 30;
      }
    });

    // Exact file name match
    if (hasExactMatch(text, changes)) {
      score += 40;
    }

    // Large changes
    const totalLines = changes.insertions + changes.deletions;
    if (totalLines > 50) score += 10;
    if (totalLines > 100) score += 20;

    return {
      index,
      text,
      score,
      confidence: Math.min(score, 100)
    };
  });
}

async function suggestChecklistCompletions(
  issueId: string,
  changes: GitChanges
): Promise<SelectionResult> {
  const issue = await getIssue(issueId);
  const uncheckedItems = extractUncheckedItems(issue.description);
  const scored = scoreChecklistItems(uncheckedItems, changes);

  // Categorize by confidence
  const high = scored.filter(i => i.confidence >= 70);
  const medium = scored.filter(i => i.confidence >= 30 && i.confidence < 70);
  const low = scored.filter(i => i.confidence < 30);

  // NEVER auto-select, always ask
  return {
    shouldAsk: true,
    question: "Which items did you complete?",
    options: scored.map(item => ({
      label: `${item.index}: ${item.text}`,
      value: item.index,
      description: item.confidence >= 70
        ? "🤖 SUGGESTED - High confidence"
        : item.confidence >= 30
        ? "💡 Possible match"
        : "Mark as complete",
      preSelected: item.confidence >= 70  // Pre-select high confidence only
    }))
  };
}
```

### Scenario 4: External System Write

**Problem**: User wants to update Jira
**Question**: Always confirm

```typescript
async function writeToExternalSystem(
  system: 'jira' | 'slack' | 'confluence',
  operation: ExternalOperation
): Promise<WriteResult> {
  // 🚨 ABSOLUTE RULE: Always confirm
  const preview = buildPreview(operation);

  console.log('🚨 CONFIRMATION REQUIRED\n');
  console.log(`I will ${operation.action} to ${system}:\n`);
  console.log('─'.repeat(40));
  console.log(preview);
  console.log('─'.repeat(40));
  console.log('\nProceed? (Type "yes" to confirm)');

  const response = await getUserInput();

  if (response.toLowerCase() !== 'yes') {
    return {
      cancelled: true,
      reason: 'User declined confirmation'
    };
  }

  // Log the confirmation
  await logExternalWrite(system, operation, 'confirmed');

  // Execute
  const result = await executeWrite(system, operation);

  // Log completion
  await logExternalWrite(system, operation, 'completed');

  return result;
}

function buildPreview(operation: ExternalOperation): string {
  switch (operation.type) {
    case 'comment':
      return `Comment:\n${operation.comment}`;

    case 'status_update':
      return `Status: ${operation.oldStatus} → ${operation.newStatus}`;

    case 'field_update':
      return `Update ${operation.field}: ${operation.value}`;

    default:
      return JSON.stringify(operation, null, 2);
  }
}
```

---

## Code Examples

### Complete Command with Always-Ask Policy

```typescript
// /ccpm:plan command implementation
async function executePlan(args: string[]): Promise<void> {
  // Step 1: Parse arguments with confidence
  const modeResult = detectPlanMode(args[0], args[1]);

  // Step 2: Handle based on confidence
  if (modeResult.shouldAsk) {
    // ❌ Low confidence - ask user
    const answer = await AskUserQuestion({
      questions: [{
        question: modeResult.question,
        header: "Mode",
        multiSelect: false,
        options: modeResult.options
      }]
    });

    modeResult.mode = answer['Mode'];
  } else if (modeResult.confidence >= 80) {
    // ✅ High confidence - proceed with display
    console.log(modeResult.display);
  } else {
    // ⚠️ Medium confidence - suggest and confirm
    const confirmed = await confirm(
      `${modeResult.display}. Proceed?`
    );

    if (!confirmed) {
      // User rejected suggestion - ask for correct mode
      const answer = await AskUserQuestion({
        questions: [{
          question: "What would you like to do?",
          header: "Mode",
          multiSelect: false,
          options: getAllModeOptions()
        }]
      });

      modeResult.mode = answer['Mode'];
    }
  }

  // Step 3: Execute based on mode
  switch (modeResult.mode) {
    case 'CREATE':
      await executeCreate(args[0], args[1], args[2]);
      break;

    case 'PLAN':
      await executePlanExisting(args[0]);
      break;

    case 'UPDATE':
      await executeUpdate(args[0], args[1]);
      break;
  }
}
```

### Helper Functions

```typescript
// Confidence-based display helper
function displayWithConfidence(
  message: string,
  confidence: number
): void {
  if (confidence >= 95) {
    console.log(`✅ ${message}`);
  } else if (confidence >= 80) {
    console.log(`✅ ${message} (${confidence}% confidence)`);
  } else if (confidence >= 50) {
    console.log(`⚠️ ${message} (${confidence}% confidence)`);
  } else {
    console.log(`❓ ${message} (low confidence)`);
  }
}

// Ask with suggestion helper
async function askWithSuggestion<T>(
  question: string,
  suggestion: T,
  alternatives: T[],
  confidence: number
): Promise<T> {
  const options = [
    {
      label: `${suggestion} (suggested)`,
      value: suggestion,
      description: `Confidence: ${confidence}%`
    },
    ...alternatives.map(alt => ({
      label: String(alt),
      value: alt
    }))
  ];

  const answer = await AskUserQuestion({
    questions: [{
      question,
      header: "Selection",
      multiSelect: false,
      options
    }]
  });

  return answer['Selection'];
}

// Validation helper with confidence
function validate<T>(
  value: T,
  validator: (v: T) => boolean,
  errorMessage: string
): { valid: boolean; confidence: number; error?: string } {
  const valid = validator(value);

  return {
    valid,
    confidence: valid ? 100 : 0,
    error: valid ? undefined : errorMessage
  };
}
```

---

## Best Practices

### 1. Always Display What You're Doing

```typescript
// ❌ BAD: Silent operation
async function updateIssue(id: string, state: string) {
  await linearMCP.updateIssue(id, { state });
}

// ✅ GOOD: Display action
async function updateIssue(id: string, state: string) {
  console.log(`📝 Updating ${id}: ${state}`);
  const result = await linearMCP.updateIssue(id, { state });
  console.log(`✅ Updated successfully`);
  return result;
}
```

### 2. Provide Confidence Scores

```typescript
// ❌ BAD: No confidence info
console.log("Detected mode: PLAN");

// ✅ GOOD: Show confidence
console.log("✅ Detected mode: PLAN (95% confidence)");
```

### 3. Always Validate Results

```typescript
// ❌ BAD: Assume success
await linearMCP.updateIssue(id, { state: "Done" });
console.log("✅ Done!");

// ✅ GOOD: Verify and validate
const result = await linearMCP.updateIssue(id, { state: "Done" });
const verification = await verifyUpdate(id, "Done");

if (!verification.success) {
  console.log("❌ Update failed:", verification.error);
  return;
}

console.log("✅ Verified: Issue marked as Done");
```

### 4. Log Decisions for Analysis

```typescript
// Always log decisions
function makeDecision(
  decisionPoint: string,
  confidence: number,
  suggestion: any,
  userChoice: any
) {
  logDecision({
    timestamp: new Date().toISOString(),
    command: getCurrentCommand(),
    decisionPoint,
    confidence,
    suggestion,
    userChoice,
    wasCorrect: suggestion === userChoice
  });

  return userChoice;
}
```

### 5. Provide Escape Hatches

```typescript
// Allow user to cancel or modify at any point
async function executePlan(args: string[]) {
  const mode = await detectMode(args);

  // Show what will happen
  console.log(`\n📋 Plan:`);
  console.log(`  Mode: ${mode}`);
  console.log(`  Action: ${getActionDescription(mode)}`);
  console.log(`\nContinue? (yes/no/edit)`);

  const response = await getUserInput();

  if (response === 'edit') {
    // Let user modify
    return await interactiveEdit(mode);
  }

  if (response !== 'yes') {
    console.log('❌ Cancelled');
    return;
  }

  // Proceed
  await executeMode(mode);
}
```

---

## Summary

This guide provides:

1. **Core principles** - When and why to ask
2. **Confidence thresholds** - How to calculate and use confidence
3. **Implementation patterns** - Reusable code patterns
4. **Testing** - How to test decision accuracy
5. **Common scenarios** - Real-world examples
6. **Code examples** - Complete implementations
7. **Best practices** - Do's and don'ts

**Key Takeaway**: When confidence < 80%, ask the user. Provide clear displays, confidence scores, and always validate results.

---

**Related Documents**:
- [Decision Framework](../architecture/decision-framework.md)
- [Decision Trees](../architecture/decision-trees-visual.md)
- [Safety Rules](../../commands/SAFETY_RULES.md)
