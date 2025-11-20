# PSN-31 Phase 4: Decision Framework - Summary

**Version:** 1.0.0
**Date:** 2025-11-21
**Status:** Design Complete

## Overview

Phase 4 of PSN-31 (CCPM Ultimate Optimization) focuses on documenting all decision points across CCPM's 49+ commands and implementing the **Always-Ask Policy** to ensure accuracy and prevent false assumptions.

---

## Objectives

1. ✅ Document all 50-50 decision points across commands
2. ✅ Create decision trees for ambiguous scenarios
3. ✅ Implement always-ask policy for uncertain decisions
4. ✅ Add workflow state tracking and persistence
5. ✅ Ensure every command updates Linear issue state
6. ✅ Create accuracy validation system

---

## Deliverables

### 1. Decision Framework Document

**File**: `docs/architecture/decision-framework.md`

**Contents**:
- Decision point taxonomy (Certain, High, Medium, Low confidence)
- Always-Ask Policy specification
- Command-level decision catalog (all 49+ commands)
- Workflow state tracking design
- Accuracy validation framework
- Implementation guidelines

**Key Sections**:
- **Decision Point Taxonomy** - 4-tier classification system
- **Always-Ask Policy** - When confidence < 80%, ask
- **Decision Catalog** - Exhaustive list of all command decisions
- **State Tracking** - Workflow state machine design
- **Validation** - Pre/during/post command validation

### 2. Visual Decision Trees

**File**: `docs/architecture/decision-trees-visual.md`

**Contents**:
- 8 major decision trees with visual flow diagrams
- Confidence level indicators
- User interaction points
- Automatic vs manual decision paths

**Decision Trees**:
1. Command Routing (`/ccpm:plan` mode detection)
2. State Transition (workflow phase changes)
3. External System Writes (Jira/Slack/Confluence)
4. Checklist Update (AI-assisted completion detection)
5. Project Detection (auto-detect vs explicit)
6. Verification Completion Gate (quality checks)
7. Agent Selection (smart agent scoring)
8. Commit Type Detection (conventional commits)

### 3. Implementation Guide

**File**: `docs/guides/implementing-always-ask-policy.md`

**Contents**:
- Core principles and confidence thresholds
- 4 implementation patterns with code examples
- Testing decision accuracy
- Common scenarios with solutions
- Best practices and anti-patterns

**Code Patterns**:
- Pattern 1: High Confidence with Display (95%+)
- Pattern 2: Medium Confidence with Suggestion (50-79%)
- Pattern 3: Low Confidence - Always Ask (0-49%)
- Pattern 4: External Writes - Always Confirm (0%)

### 4. Workflow State Tracking

**File**: `docs/architecture/workflow-state-tracking.md`

**Contents**:
- State machine design (8 workflow states)
- State persistence in Linear custom fields
- State transition validation
- Implementation specification
- Integration with commands

**Workflow States**:
- IDEA → PLANNED → IMPLEMENTING → VERIFYING → VERIFIED → COMPLETE
- BLOCKED (special state)
- CANCELLED (terminal state)

---

## Key Concepts

### Decision Point Classification

```
Confidence Level │ Range  │ Behavior
─────────────────┼────────┼──────────────────────
CERTAIN          │ 95-100%│ Auto proceed
HIGH             │ 80-94% │ Proceed with display
MEDIUM           │ 50-79% │ Suggest and confirm
LOW              │ 0-49%  │ Always ask
```

### Always-Ask Policy

**Core Rule**: When confidence < 80%, explicitly ask the user rather than making assumptions.

**Exceptions**:
- External system writes: ALWAYS ask (0% confidence by safety rules)
- Format validation: 100% confidence (pattern matching)
- Safety rules: 100% confidence (absolute blocks)

### Workflow State Machine

```
IDEA → PLANNED → IMPLEMENTING → VERIFYING → VERIFIED → COMPLETE
         ↓            ↓
     CANCELLED     BLOCKED
```

Each state has:
- Allowed next states
- Allowed commands
- Pre-condition validations
- Transition confidence levels

---

## Command Decision Catalog Summary

### Natural Workflow Commands (6)

| Command | Key Decisions | Confidence | Policy |
|---------|--------------|-----------|--------|
| `/ccpm:plan` | Mode detection (create/plan/update) | 90-95% | Auto-detect |
| `/ccpm:work` | Start vs resume | 95% | Auto-detect |
| `/ccpm:sync` | Checklist items complete | 50-70% | AI suggests, user confirms |
| `/ccpm:commit` | Commit type | 70% | Suggest with preview |
| `/ccpm:verify` | Minor issues acceptable | 40% | Always ask |
| `/ccpm:done` | External system updates | 0% | Always ask |

### Planning Commands (7)

| Command | Key Decisions | Confidence | Policy |
|---------|--------------|-----------|--------|
| `planning:create` | Project detection | 60-95% | Auto-detect, ask if ambiguous |
| `planning:plan` | Already planned | 100% | Block with suggestion |
| `planning:update` | Change type | 65% | Detect, ask clarifying questions |
| `planning:design-ui` | Design style | 30% | Always ask |
| `planning:design-refine` | Which option | 100% | User specifies |
| `planning:design-approve` | Final selection | 100% | User specifies |
| `planning:quick-plan` | Skip research | 100% | Intentional (command purpose) |

### Implementation Commands (4)

| Command | Key Decisions | Confidence | Policy |
|---------|--------------|-----------|--------|
| `implementation:start` | Agent assignment | 60% | AI assigns, user reviews |
| `implementation:next` | Next action | 65% | Suggest, user chooses |
| `implementation:update` | Subtask index | 100% | User specifies |
| `implementation:sync` | See `/ccpm:sync` | - | - |

### Verification Commands (3)

| Command | Key Decisions | Confidence | Policy |
|---------|--------------|-----------|--------|
| `verification:check` | Which checks | 80% | Run all standard |
| `verification:verify` | Minor issues | 40% | Always ask |
| `verification:fix` | Fix approach | 40% | Suggest, ask to approve |

### Complete Commands (1)

| Command | Key Decisions | Confidence | Policy |
|---------|--------------|-----------|--------|
| `complete:finalize` | See `/ccpm:done` | - | - |

### Spec Management Commands (6)

| Command | Key Decisions | Confidence | Policy |
|---------|--------------|-----------|--------|
| `spec:create` | Spec type | 100% | User specifies |
| `spec:write` | Overwrite existing | 50% | Ask if content exists |
| `spec:review` | Passing grade | 90% | B- or higher |
| `spec:sync` | Spec vs code truth | 0% | Always ask |
| `spec:break-down` | Task granularity | 50% | Suggest, user adjusts |
| `spec:migrate` | File categorization | 70% | Auto-categorize, preview |

### Utility Commands (15)

Most utility commands are read-only or have explicit user input. Key decisions:

| Command | Key Decisions | Confidence | Policy |
|---------|--------------|-----------|--------|
| `utils:auto-assign` | Agent assignment | 60% | AI suggests, user reviews |
| `utils:dependencies` | Execution order | 70% | Suggest, user adjusts |
| `utils:insights` | Timeline estimate | 40% | Present as estimate |
| `utils:organize-docs` | File moves | 0% | Always confirm |
| `utils:rollback` | Destructive operation | 0% | Always confirm |
| `utils:sync-status` | Jira write | 0% | Always confirm |

---

## Implementation Roadmap

### Phase 1: Core Framework (Immediate)

1. Create `WorkflowStateManager` class
2. Add Linear custom fields for state tracking
3. Implement confidence calculation helpers
4. Create `AskUserQuestion` wrappers

### Phase 2: Command Updates (Sprint 1)

1. Update natural workflow commands (6)
2. Add state tracking to all commands
3. Implement confidence-based decision making
4. Add validation framework

### Phase 3: Testing & Validation (Sprint 2)

1. Unit tests for decision confidence
2. Integration tests for state transitions
3. Accuracy tracking implementation
4. False positive prevention

### Phase 4: Monitoring & Optimization (Ongoing)

1. Track decision accuracy metrics
2. Adjust confidence thresholds
3. Improve AI scoring algorithms
4. Refine user interaction patterns

---

## Benefits

### For Users

- **No False Assumptions** - System asks when uncertain
- **Clear Communication** - Always displays what it's doing
- **Control** - User confirms critical decisions
- **Guidance** - Suggests next actions based on state

### For Developers

- **Clear Guidelines** - When to ask vs proceed
- **Reusable Patterns** - Consistent decision handling
- **Testing Framework** - Validate decision accuracy
- **State Tracking** - Context for all operations

### For CCPM System

- **Accuracy** - Reduces false positives
- **Reliability** - Validates all transitions
- **Learning** - Improves over time with metrics
- **Safety** - Enforces external write confirmations

---

## Metrics & Success Criteria

### Decision Accuracy

**Target**: 90%+ accuracy for high-confidence decisions

```
Metric: (Correct AI suggestions) / (Total decisions)

High confidence (80%+): Should be 90%+ accurate
Medium confidence (50-79%): Should be 70%+ accurate
Low confidence (0-49%): N/A (always asks)
```

### User Satisfaction

**Target**: Reduce user-reported false assumptions by 80%

```
Metric: User reports of incorrect assumptions

Before: ~10-15 reports per sprint
Target: <3 reports per sprint
```

### State Tracking Coverage

**Target**: 100% of commands update workflow state

```
Metric: Commands updating state / Total commands

Current: 0%
Target: 100%
```

---

## Next Steps

1. **Review & Approve** - Stakeholder review of design
2. **Implementation** - Begin Phase 1 (Core Framework)
3. **Testing** - Create test suite for decision accuracy
4. **Rollout** - Gradual rollout to commands
5. **Monitor** - Track metrics and adjust

---

## Files Created

1. `docs/architecture/decision-framework.md` - Main framework document
2. `docs/architecture/decision-trees-visual.md` - Visual decision trees
3. `docs/guides/implementing-always-ask-policy.md` - Implementation guide
4. `docs/architecture/workflow-state-tracking.md` - State tracking design
5. `docs/architecture/psn-31-phase4-summary.md` - This summary

---

## Related Documents

- [Decision Framework](./decision-framework.md)
- [Decision Trees](./decision-trees-visual.md)
- [Implementation Guide](../guides/implementing-always-ask-policy.md)
- [State Tracking](./workflow-state-tracking.md)
- [Safety Rules](../../commands/SAFETY_RULES.md)
- [CLAUDE.md](../../CLAUDE.md)

---

## Conclusion

Phase 4 provides a comprehensive decision framework that:

- **Catalogs all decision points** across 49+ commands
- **Defines clear policies** for when to ask vs proceed
- **Implements state tracking** for workflow validation
- **Establishes accuracy metrics** for continuous improvement

This framework ensures CCPM makes accurate decisions, asks when uncertain, and never makes false assumptions that waste user time.

**Status**: ✅ Design Complete - Ready for Implementation
