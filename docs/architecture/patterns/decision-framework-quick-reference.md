# Decision Framework - Quick Reference

**Version:** 1.0.0
**For:** CCPM Command Developers

## The Always-Ask Rule

**When confidence < 80%, explicitly ask the user rather than making assumptions.**

---

## Confidence Thresholds

| Level | Range | Action | Code Pattern |
|-------|-------|--------|--------------|
| **CERTAIN** | 95-100% | Auto proceed | `if (conf >= 95) proceed();` |
| **HIGH** | 80-94% | Proceed + display | `console.log(action); proceed();` |
| **MEDIUM** | 50-79% | Suggest + confirm | `suggest(); ask();` |
| **LOW** | 0-49% | Always ask | `ask(); // no suggestion` |

---

## Decision Types

### 1. Pattern Matching (High Confidence)

```typescript
// Example: Issue ID validation
if (/^[A-Z]+-\d+$/.test(input)) {
  // ✅ 95% confidence
  console.log(`✅ Detected issue: ${input}`);
  proceed();
}
```

### 2. Context-Based (Medium Confidence)

```typescript
// Example: Commit type detection
const type = detectCommitType(files, description);
if (type.confidence >= 50 && type.confidence < 80) {
  // ⚠️ Medium confidence
  const confirmed = await confirm(
    `Suggested: ${type.value} (${type.confidence}%). Correct?`
  );
}
```

### 3. Ambiguous Input (Low Confidence)

```typescript
// Example: Unclear command intent
if (input.length <= 3) {
  // ❌ Low confidence
  const answer = await AskUserQuestion({
    question: "What did you mean?",
    options: getAllOptions()
  });
}
```

### 4. External Writes (Always Confirm)

```typescript
// Example: Jira update
console.log('🚨 CONFIRMATION REQUIRED');
console.log('I will post to Jira:');
console.log('---');
console.log(content);
console.log('---');
const response = await getUserInput();
if (response !== 'yes') return;
```

---

## State Machine

```
IDEA → PLANNED → IMPLEMENTING → VERIFYING → VERIFIED → COMPLETE
         ↓            ↓
     CANCELLED     BLOCKED
```

### State Transitions

| From | To | Confidence | Policy |
|------|-----|-----------|--------|
| IDEA → PLANNED | 95% | Auto |
| PLANNED → IMPLEMENTING | 95% | Auto |
| IMPLEMENTING → VERIFYING | 70% | Ask if checklist incomplete |
| VERIFYING → VERIFIED | 85% | Auto if all checks pass |
| VERIFIED → COMPLETE | 95% | Auto |

---

## Common Patterns

### High Confidence Display

```typescript
function displayHighConfidence(action: string, conf: number) {
  if (conf >= 95) {
    console.log(`✅ ${action}`);
  } else {
    console.log(`✅ ${action} (${conf}% confidence)`);
  }
  proceed();
}
```

### Medium Confidence Suggestion

```typescript
async function askWithSuggestion<T>(
  question: string,
  suggestion: T,
  confidence: number
): Promise<T> {
  return await AskUserQuestion({
    questions: [{
      question,
      options: [
        {
          label: `${suggestion} (suggested)`,
          description: `Confidence: ${confidence}%`
        },
        ...alternatives
      ]
    }]
  });
}
```

### External Write Confirmation

```typescript
async function confirmExternalWrite(
  system: string,
  operation: string,
  content: string
): Promise<boolean> {
  console.log('🚨 CONFIRMATION REQUIRED\n');
  console.log(`I will ${operation} to ${system}:\n`);
  console.log('─'.repeat(40));
  console.log(content);
  console.log('─'.repeat(40));
  console.log('\nProceed? (yes/no)');

  const response = await getUserInput();
  return response.toLowerCase() === 'yes';
}
```

---

## Safety Rules

### Always Confirm

- ⛔ **Jira** writes (issues, comments, status)
- ⛔ **Confluence** writes (pages, comments)
- ⛔ **BitBucket** writes (PRs, comments)
- ⛔ **Slack** messages

### Always Proceed

- ✅ **Linear** operations (internal tracking)
- ✅ **Git** status checks
- ✅ **Format validation**
- ✅ **Read operations** (all systems)

---

## Testing

```typescript
describe('Decision Confidence', () => {
  it('should have 95%+ for valid patterns', () => {
    const result = detectMode('PSN-29');
    expect(result.confidence).toBeGreaterThanOrEqual(95);
  });

  it('should have <50% for ambiguous input', () => {
    const result = detectMode('PSN');
    expect(result.confidence).toBeLessThan(50);
    expect(result.shouldAsk).toBe(true);
  });

  it('should ask user when confidence is low', async () => {
    const askMock = jest.fn();
    await executeCommand(['PSN'], { ask: askMock });
    expect(askMock).toHaveBeenCalled();
  });
});
```

---

## Validation

```typescript
// Pre-command validation
async function validateBeforeExecute(
  issueId: string,
  command: string
): Promise<ValidationResult> {
  // Check format
  if (!ISSUE_ID_PATTERN.test(issueId)) {
    return { valid: false, confidence: 0, error: "Invalid format" };
  }

  // Check state
  const state = await getWorkflowState(issueId);
  if (!state.allowsCommand(command)) {
    return {
      valid: false,
      confidence: 100,
      error: `${command} not allowed in ${state.phase}`
    };
  }

  return { valid: true, confidence: 95 };
}

// Post-command validation
async function validateAfterExecute(
  issueId: string,
  expectedChanges: Changes
): Promise<ValidationResult> {
  const actual = await getIssue(issueId);

  if (actual.state !== expectedChanges.state) {
    return {
      valid: false,
      confidence: 100,
      error: `State mismatch: expected ${expectedChanges.state}, got ${actual.state}`
    };
  }

  return { valid: true, confidence: 100 };
}
```

---

## Command Integration

```typescript
// Wrap command with state management
async function executeWithState(
  command: string,
  issueId: string,
  handler: () => Promise<void>
): Promise<void> {
  // Load state
  const state = new WorkflowStateManager(issueId);
  await state.load();

  // Validate command
  if (!state.isCommandAllowed(command)) {
    console.log(`⚠️  ${command} not typical for ${state.phase}`);
    const confirmed = await confirm('Continue?');
    if (!confirmed) return;
  }

  // Execute
  await handler();

  // Update state
  await state.save({
    lastCommand: command,
    lastUpdate: new Date().toISOString()
  });

  // Suggest next action
  const next = state.suggestNextAction();
  if (next) {
    console.log(`\n💡 Next: ${next.command} - ${next.description}`);
  }
}
```

---

## Checklist

Before implementing a command:

- [ ] Identify all decision points
- [ ] Calculate confidence for each
- [ ] Implement appropriate ask/proceed logic
- [ ] Add state tracking
- [ ] Validate pre-conditions
- [ ] Validate post-execution
- [ ] Add tests for confidence levels
- [ ] Document decision rationale

---

## Key Resources

- [Full Decision Framework](../architecture/decision-framework.md)
- [Decision Trees](../architecture/decision-trees-visual.md)
- [Implementation Guide](../guides/implementing-always-ask-policy.md)
- [State Tracking](../architecture/workflow-state-tracking.md)
- [Safety Rules](../../commands/SAFETY_RULES.md)

---

## Quick Checklist

**For every decision:**

1. ❓ **What** needs to be decided?
2. 📊 **How confident** are we (0-100)?
3. 🎯 **Based on confidence**:
   - 95%+ → Proceed
   - 80-94% → Proceed + display
   - 50-79% → Suggest + confirm
   - 0-49% → Always ask
4. ✅ **Validate** result
5. 📝 **Log** for accuracy tracking

**Remember**: When in doubt, ask. Better to confirm than to assume incorrectly.
