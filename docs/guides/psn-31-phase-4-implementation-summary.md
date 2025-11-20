# PSN-31 Phase 4: Decision Framework Implementation Summary

**Version:** 1.0.0
**Status:** Implementation Complete - Part 1 & 2
**Date:** 2025-11-21

## Executive Summary

This document summarizes the implementation of the Always-Ask Policy and decision framework across CCPM commands. The implementation provides confidence-based decision making, workflow state tracking, and user interaction management.

---

## Table of Contents

1. [What Was Implemented](#what-was-implemented)
2. [Implementation Architecture](#implementation-architecture)
3. [Files Created](#files-created)
4. [Integration Guide](#integration-guide)
5. [Next Steps](#next-steps)
6. [Testing Strategy](#testing-strategy)

---

## What Was Implemented

### Part 1: Decision Helper Functions (✅ Complete)

**File**: `commands/_shared-decision-helpers.md`

**Capabilities**:
- **Confidence Calculation**: Score decisions 0-100 based on multiple signals
  - Pattern matching (50% weight)
  - Context matching (30% weight)
  - Historical success (20% weight)
  - User preference bonus (+10)

- **Always-Ask Logic**: Automatic decision to ask user when confidence < 80%
  - CERTAIN (95-100%): Auto-proceed silently
  - HIGH (80-94%): Auto-proceed with display
  - MEDIUM (50-79%): Suggest and confirm
  - LOW (0-49%): Ask without suggestion

- **User Question Formatting**: Standardized AskUserQuestion wrapper
  - Pre-selection of high-confidence suggestions
  - Confidence display for transparency
  - Multi-select support

- **Display and Confirmation**: Show proposed actions before execution
  - External write confirmation (safety-critical)
  - Change previews with details
  - Explicit "yes" requirement for dangerous operations

- **Fuzzy Matching**: Intelligent string matching with 60% threshold
  - Exact match (100%)
  - Starts with (85%)
  - Contains (70%)
  - Levenshtein distance (varies)
  - Alias support

- **Validation Functions**: Workflow state transition validation
- **Pattern Matching**: Issue ID, quoted string, change type detection
- **Error Handling**: Structured errors with suggestions

**Token Budget**: ~500 tokens per command (helper invocations)

---

### Part 2: Workflow State Machine (✅ Complete)

**File**: `commands/_shared-state-machine.md`

**Capabilities**:
- **8-State Machine**: IDEA → PLANNED → IMPLEMENTING → BLOCKED → VERIFYING → VERIFIED → COMPLETE/CANCELLED
- **State Persistence**: Linear custom fields integration
  - ccpmPhase (current phase)
  - ccpmLastCommand (last command executed)
  - ccpmLastUpdate (ISO 8601 timestamp)
  - ccpmAutoTransitions (boolean flag)
  - ccpmVerificationGate (NONE/STANDARD/STRICT)
  - ccpmChecklistRequired (boolean flag)

- **Transition Validation**: Pre-condition checks before state changes
  - Allowed transitions per state
  - Confidence scores per transition
  - Pre-condition validation (checklist, git status, etc.)

- **State Loading/Saving**: Delegate to linear-operations subagent
  - Auto-inference from Linear status (fallback)
  - Session-level caching via subagent

- **Next Action Suggestions**: Context-aware command suggestions
  - Based on current phase
  - Based on checklist completion
  - Confidence-scored suggestions

- **Command Validation**: Check if command allowed in current phase
  - Wildcard pattern support
  - Helpful error messages with suggestions

**Token Budget**: ~300 tokens per command (state operations)

---

## Implementation Architecture

### Layered Design

```
┌──────────────────────────────────────────────┐
│         CCPM Commands (49+ total)            │
│   /ccpm:plan, /ccpm:work, /ccpm:sync, etc.  │
└────────────────┬─────────────────────────────┘
                 │
                 │ Reference via READ:
                 │
┌────────────────▼─────────────────────────────┐
│       Shared Decision Helpers Layer          │
│  • calculateConfidence()                     │
│  • shouldAsk()                               │
│  • askUserForClarification()                 │
│  • displayOptionsAndConfirm()                │
│  • fuzzyMatch()                              │
└────────────────┬─────────────────────────────┘
                 │
                 │ Delegates state ops to:
                 │
┌────────────────▼─────────────────────────────┐
│       Workflow State Machine Layer           │
│  • loadWorkflowState()                       │
│  • saveWorkflowState()                       │
│  • validateTransition()                      │
│  • transitionState()                         │
│  • suggestNextAction()                       │
└────────────────┬─────────────────────────────┘
                 │
                 │ Delegates Linear ops to:
                 │
┌────────────────▼─────────────────────────────┐
│     Linear Operations Subagent               │
│  • get_issue (with caching)                  │
│  • update_issue_custom_fields                │
│  • create_comment                            │
│  • update_issue (status)                     │
└──────────────────────────────────────────────┘
```

### Data Flow

```
Command Execution:
1. READ: _shared-decision-helpers.md
2. READ: _shared-state-machine.md (optional)
3. Load workflow state (if state-aware)
4. Make decisions with confidence calculation
5. Ask user if confidence < 80%
6. Execute command logic
7. Update workflow state (if state changed)
8. Display results with confidence
```

---

## Files Created

### 1. `commands/_shared-decision-helpers.md`

**Purpose**: Reusable decision-making utilities

**Key Functions**:
- `calculateConfidence(context)` - Score decisions 0-100
- `shouldAsk(confidence, options)` - Determine if user input needed
- `askUserForClarification(questionConfig)` - AskUserQuestion wrapper
- `displayOptionsAndConfirm(action, details, options)` - Show and confirm
- `fuzzyMatch(input, options, config)` - Intelligent string matching
- `validateTransition(fromState, toState, stateMachine)` - State validation
- Pattern matching helpers (issue ID, quoted strings, change types)
- Display helpers (confidence display, decision summary)

**Usage Pattern**:
```markdown
## READ decision helpers
READ: commands/_shared-decision-helpers.md

## Calculate confidence
const result = calculateConfidence({
  input: "PSN-29",
  signals: {
    patternMatch: 100,
    contextMatch: 90,
    historicalSuccess: 95
  }
});

## Check if should ask
const decision = shouldAsk(result.confidence);

if (decision.shouldAsk) {
  // Ask user
  const answer = await askUserForClarification({...});
} else {
  // Proceed automatically
  displayWithConfidence(result.confidence, "Proceeding...");
}
```

**Token Impact**: +~500 tokens per command invocation

---

### 2. `commands/_shared-state-machine.md`

**Purpose**: Workflow state tracking and management

**Key Functions**:
- `loadWorkflowState(issueId)` - Load from Linear custom fields
- `saveWorkflowState(issueId, updates)` - Persist to Linear
- `validateTransition(fromPhase, toPhase, options)` - Validate state change
- `transitionState(issueId, toPhase, options)` - Execute transition
- `suggestNextAction(state)` - Recommend next command
- `isCommandAllowed(command, phase)` - Validate command usage
- `displayStateSummary(state)` - Show state for user

**State Machine**:
```yaml
IDEA → PLANNED → IMPLEMENTING → VERIFYING → VERIFIED → COMPLETE
                      ↓
                   BLOCKED
```

**Usage Pattern**:
```markdown
## READ state machine
READ: commands/_shared-state-machine.md

## Load current state
const state = await loadWorkflowState(issueId);

## Display state
displayStateSummary(state);

## Validate command
const commandCheck = isCommandAllowed('/ccpm:work', state.phase);
if (!commandCheck.allowed) {
  // Warn user or ask for confirmation
}

## Execute command logic
// ... command implementation ...

## Transition state if needed
if (shouldTransition) {
  const result = await transitionState(issueId, 'IMPLEMENTING', {
    reason: 'Started implementation',
    command: '/ccpm:work'
  });
}
```

**Token Impact**: +~300 tokens per command invocation

---

### 3. `docs/guides/psn-31-phase-4-implementation-summary.md` (This File)

**Purpose**: Implementation documentation and migration guide

---

## Integration Guide

### For New Commands

When creating a new CCPM command:

1. **Add helper references** at the top:
```markdown
## READ shared helpers
READ: commands/_shared-decision-helpers.md
READ: commands/_shared-state-machine.md  # If state-aware
```

2. **Use confidence-based decisions**:
```javascript
// Detect mode with confidence
const modeDetection = detectMode(args);

// Check if should ask
const decision = shouldAsk(modeDetection.confidence);

if (decision.shouldAsk) {
  // Ask user
  const mode = await askUserForClarification({
    question: "What would you like to do?",
    header: "Mode",
    options: [...],
    suggestion: modeDetection.suggestion,
    confidence: modeDetection.confidence
  });
} else {
  // Proceed automatically
  displayWithConfidence(modeDetection.confidence, `Mode: ${mode}`);
}
```

3. **Manage workflow state** (if applicable):
```javascript
// Load state at start
const state = await loadWorkflowState(issueId);

// Check if command allowed
const commandCheck = isCommandAllowed(currentCommand, state.phase);

// Execute command logic
// ...

// Update state at end
await transitionState(issueId, newPhase, {
  reason: 'Command completed',
  command: currentCommand
});
```

4. **Display confidence** for transparency:
```javascript
displayWithConfidence(confidence, "Action being taken");
```

---

### For Existing Commands

Migration checklist for existing commands:

#### Step 1: Add Helper References
```markdown
## Decision Framework (Add at top)
READ: commands/_shared-decision-helpers.md
READ: commands/_shared-state-machine.md
```

#### Step 2: Identify Decision Points
```markdown
## Decision Points in this Command:
1. Mode detection (create vs plan vs update)
   - Current: Pattern match only
   - New: Confidence-based with ask on < 80%

2. Project selection
   - Current: Auto-detect
   - New: Ask if confidence < 80%

3. External writes
   - Current: Direct write
   - New: Always ask (safety-critical)
```

#### Step 3: Replace Direct Logic with Helpers
```markdown
## OLD (before):
if (ISSUE_ID_PATTERN.test(arg1)) {
  mode = 'PLAN';
} else {
  mode = 'CREATE';
}

## NEW (after):
const issueIdCheck = detectIssueIdConfidence(arg1);
const askDecision = shouldAsk(issueIdCheck.confidence);

if (askDecision.shouldAsk) {
  mode = await askUserForClarification({...});
} else {
  displayWithConfidence(issueIdCheck.confidence, `Mode: ${mode}`);
}
```

#### Step 4: Add State Management (if command changes workflow)
```markdown
## At start of command:
const state = await loadWorkflowState(issueId);
displayStateSummary(state);

## After command execution:
await transitionState(issueId, 'IMPLEMENTING', {
  reason: 'Implementation started',
  command: '/ccpm:work'
});
```

#### Step 5: Add External Write Confirmations
```markdown
## Before any Jira/Slack/Confluence write:
const confirmed = await displayOptionsAndConfirm(
  "Update Jira ticket TRAIN-456",
  {
    "Status": "In Progress → Done",
    "Comment": "Completed via CCPM"
  },
  {
    title: "External System Write",
    emoji: "🚨",
    requireExplicitYes: true
  }
);

if (!confirmed) {
  return;  // Cancel operation
}

// Only now proceed with write
```

---

## Next Steps

### Immediate (Phase 4 Continuation)

1. **Update Routing Commands** (Part 3)
   - ✅ `/ccpm:plan` - Already optimized, add decision helpers
   - `/ccpm:work` - Add state machine integration
   - `/ccpm:sync` - Add checklist selection with confidence
   - `/ccpm:commit` - Add commit type detection with confidence
   - `/ccpm:verify` - Add verification gate decisions
   - `/ccpm:done` - Add external write confirmations

2. **Update Planning Commands** (Part 4)
   - `/ccpm:planning:create` - Add project detection with confidence
   - `/ccpm:planning:plan` - Add already-planned check
   - `/ccpm:planning:update` - Add change type detection
   - `/ccpm:planning:design-ui` - Add design preference questions
   - `/ccpm:planning:design-refine` - Add refinement confirmation
   - `/ccpm:planning:design-approve` - Add final approval confirmation
   - `/ccpm:planning:quick-plan` - Lightweight version

3. **Update Implementation & Verification Commands** (Part 5)
   - `/ccpm:implementation:start` - Add agent assignment confidence
   - `/ccpm:implementation:update` - Add status validation
   - `/ccpm:implementation:sync` - Same as `/ccpm:sync`
   - `/ccpm:implementation:next` - Add next action detection
   - `/ccpm:verification:check` - Add check selection
   - `/ccpm:verification:verify` - Add minor issues acceptance
   - `/ccpm:verification:fix` - Add fix approach selection

4. **Update Completion & Utility Commands** (Part 6)
   - `/ccpm:complete:finalize` - Same as `/ccpm:done`
   - `/ccpm:utils:*` - Add relevant decision points

5. **Testing & Validation** (Part 7)
   - Create test scenarios for all decision points
   - Validate confidence calculations
   - Tune thresholds based on accuracy
   - Track false positives/negatives

6. **Documentation** (Part 8)
   - Update command documentation
   - Create developer guide
   - Create user guide
   - Update CHANGELOG.md

### Long-term Improvements

1. **Machine Learning Integration**
   - Track decision accuracy over time
   - Adjust confidence weights based on success rate
   - Learn user preferences per decision point

2. **Analytics Dashboard**
   - Decision accuracy by command
   - Confidence distribution
   - User override patterns
   - False positive/negative rates

3. **Advanced Fuzzy Matching**
   - Phonetic matching (Soundex)
   - Abbreviation handling
   - Context-aware matching

4. **Workflow Customization**
   - Per-project state machines
   - Custom transition rules
   - Configurable confidence thresholds

---

## Testing Strategy

### Unit Testing

Test each helper function in isolation:

```javascript
// Test confidence calculation
describe('calculateConfidence', () => {
  it('should return 93% for high pattern match', () => {
    const result = calculateConfidence({
      signals: {
        patternMatch: 100,
        contextMatch: 90,
        historicalSuccess: 95
      }
    });
    expect(result.confidence).toBe(93);
    expect(result.shouldAsk).toBe(false);
    expect(result.level).toBe('HIGH');
  });

  it('should return LOW for ambiguous input', () => {
    const result = calculateConfidence({
      signals: {
        patternMatch: 30,
        contextMatch: 40,
        historicalSuccess: 20
      }
    });
    expect(result.confidence).toBeLessThan(50);
    expect(result.shouldAsk).toBe(true);
    expect(result.level).toBe('LOW');
  });
});

// Test fuzzy matching
describe('fuzzyMatch', () => {
  it('should match exact string', () => {
    const result = fuzzyMatch("In Progress", [
      "Backlog", "In Progress", "Done"
    ]);
    expect(result.match).toBe("In Progress");
    expect(result.confidence).toBe(100);
  });

  it('should fuzzy match partial string', () => {
    const result = fuzzyMatch("in prog", [
      "Backlog", "In Progress", "Done"
    ]);
    expect(result.match).toBe("In Progress");
    expect(result.confidence).toBeGreaterThanOrEqual(70);
  });
});
```

---

### Integration Testing

Test helper functions with real commands:

```javascript
describe('Command Integration', () => {
  it('should ask user when confidence is low', async () => {
    const askMock = jest.fn().mockResolvedValue({ Mode: 'CREATE' });

    await executePlan(['PSN'], { askUserQuestion: askMock });

    expect(askMock).toHaveBeenCalled();
    expect(askMock.mock.calls[0][0].questions[0].question)
      .toContain('What would you like to do');
  });

  it('should not ask when confidence is high', async () => {
    const askMock = jest.fn();

    await executePlan(['PSN-29'], { askUserQuestion: askMock });

    expect(askMock).not.toHaveBeenCalled();
  });
});
```

---

### Accuracy Tracking

Track decision accuracy over time:

```javascript
interface DecisionLog {
  timestamp: string;
  command: string;
  decisionPoint: string;
  confidence: number;
  suggestion: any;
  userChoice: any;
  wasCorrect: boolean;
}

// Log every decision
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

  // Store in analytics
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

**Target Accuracy**:
- High confidence (80-100%): 95%+ accuracy (proceed automatically)
- Medium confidence (50-79%): 70%+ accuracy (suggest and confirm)
- Low confidence (0-49%): Always ask (no accuracy target)

---

## Success Criteria

### Phase 4 Complete When:

- ✅ **Part 1**: Decision helper functions created
- ✅ **Part 2**: Workflow state machine implemented
- ⏳ **Part 3**: All 6 routing commands updated
- ⏳ **Part 4**: All 7 planning commands updated
- ⏳ **Part 5**: All 7 implementation/verification commands updated
- ⏳ **Part 6**: All remaining commands reviewed
- ⏳ **Part 7**: Testing complete with 95%+ accuracy
- ⏳ **Part 8**: Documentation complete

### Validation Metrics:

- **Decision Accuracy**: 95%+ for high confidence decisions
- **False Positives**: < 5% (auto-proceed when should ask)
- **False Negatives**: < 10% (ask when could auto-proceed)
- **User Satisfaction**: Positive feedback on decision transparency
- **Token Efficiency**: No significant token increase (< 10%)
- **Command Coverage**: All 49+ commands implement Always-Ask Policy

---

## Related Documents

- [Decision Framework](../architecture/decision-framework.md)
- [Decision Trees Visual](../architecture/decision-trees-visual.md)
- [Workflow State Tracking Design](../architecture/workflow-state-tracking.md)
- [Implementing Always-Ask Policy Guide](./implementing-always-ask-policy.md)
- [Decision Helpers Reference](../../commands/_shared-decision-helpers.md)
- [State Machine Reference](../../commands/_shared-state-machine.md)

---

## Changelog

### 2025-11-21 - v1.0.0
- ✅ Created shared decision helper functions library
- ✅ Created workflow state machine implementation
- ✅ Documented implementation architecture
- ✅ Created integration guide
- ✅ Defined testing strategy
- 📋 Next: Begin command updates (Parts 3-6)
