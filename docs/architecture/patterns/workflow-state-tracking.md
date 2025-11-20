# Workflow State Tracking Design

**Version:** 1.0.0
**Phase:** PSN-31 Phase 4
**Status:** Design Specification

## Overview

This document specifies how CCPM tracks workflow state across commands, enabling accurate decision-making, workflow validation, and progress tracking.

---

## Table of Contents

1. [State Machine Design](#state-machine-design)
2. [State Persistence](#state-persistence)
3. [State Transitions](#state-transitions)
4. [Implementation Specification](#implementation-specification)
5. [Integration with Commands](#integration-with-commands)

---

## State Machine Design

### Core States

```yaml
CCPM Workflow States:

IDEA:
  description: "Initial concept, not yet planned"
  linear_status: "Backlog"
  phase: "ideation"
  next_states: [PLANNED, CANCELLED]
  allowed_commands:
    - /ccpm:plan (to move to PLANNED)
    - /ccpm:utils:status

PLANNED:
  description: "Requirements gathered, implementation plan created"
  linear_status: "Planned" | "Todo" | "Ready"
  phase: "planning"
  next_states: [IMPLEMENTING, IDEA, CANCELLED]
  allowed_commands:
    - /ccpm:work (to move to IMPLEMENTING)
    - /ccpm:plan (to update plan)
    - /ccpm:utils:*

IMPLEMENTING:
  description: "Active development in progress"
  linear_status: "In Progress" | "In Development" | "Doing"
  phase: "implementation"
  next_states: [VERIFYING, PLANNED, BLOCKED]
  allowed_commands:
    - /ccpm:sync
    - /ccpm:commit
    - /ccpm:implementation:*
    - /ccpm:utils:*

BLOCKED:
  description: "Cannot proceed due to blocker"
  linear_status: "Blocked"
  phase: "implementation"
  next_states: [IMPLEMENTING, CANCELLED]
  allowed_commands:
    - /ccpm:verification:fix
    - /ccpm:utils:status
    - (any command to unblock)

VERIFYING:
  description: "Quality checks and verification in progress"
  linear_status: "In Review" | "Testing" | "Verification"
  phase: "verification"
  next_states: [VERIFIED, IMPLEMENTING]
  allowed_commands:
    - /ccpm:verify
    - /ccpm:verification:*
    - /ccpm:utils:*

VERIFIED:
  description: "Verified and ready to complete"
  linear_status: "Verified" | "Ready for Review" | "Approved"
  phase: "completion"
  next_states: [COMPLETE, IMPLEMENTING]
  allowed_commands:
    - /ccpm:done
    - /ccpm:complete:finalize
    - /ccpm:utils:*

COMPLETE:
  description: "Task finalized and closed"
  linear_status: "Done" | "Completed" | "Closed"
  phase: "complete"
  next_states: []
  allowed_commands:
    - /ccpm:utils:status (read-only)
    - /ccpm:utils:report (read-only)

CANCELLED:
  description: "Task cancelled or abandoned"
  linear_status: "Cancelled" | "Archived"
  phase: "cancelled"
  next_states: []
  allowed_commands:
    - /ccpm:utils:status (read-only)
```

### State Transition Confidence

```yaml
Transition Confidence Rules:

IDEA → PLANNED:
  trigger: /ccpm:plan executed successfully
  confidence: 95%
  validation:
    - Issue has implementation checklist
    - Status updated to "Planned"
  auto_transition: true

PLANNED → IMPLEMENTING:
  trigger: /ccpm:work executed
  confidence: 95%
  validation:
    - Status updated to "In Progress"
    - Implementation started comment added
  auto_transition: true

IMPLEMENTING → BLOCKED:
  trigger: Blocker detected or user marks as blocked
  confidence: 90%
  validation:
    - "blocked" label added
    - Blocker comment added
  auto_transition: true (if blocker detected)

IMPLEMENTING → VERIFYING:
  trigger: /ccpm:verify executed
  confidence: 70%
  validation:
    - Checklist 100% complete
    - All tests passing
    - No uncommitted changes
  auto_transition: false (ask if checklist incomplete)

VERIFYING → VERIFIED:
  trigger: Verification passed
  confidence: 85%
  validation:
    - All quality checks passed
    - No critical issues
  auto_transition: true (if all checks pass)

VERIFYING → IMPLEMENTING:
  trigger: Verification failed
  confidence: 100%
  validation:
    - Critical issues found
  auto_transition: true

VERIFIED → COMPLETE:
  trigger: /ccpm:done executed
  confidence: 95%
  validation:
    - PR created
    - Status updated to "Done"
  auto_transition: true

Any → CANCELLED:
  trigger: User cancels task
  confidence: 50%
  validation: none
  auto_transition: false (always ask)
```

### Visual State Machine

```
                    ┌─────────┐
                    │  IDEA   │
                    └────┬────┘
                         │
                    /ccpm:plan
                         │
                    ┌────▼────┐
                    │ PLANNED │
                    └────┬────┘
                         │
                    /ccpm:work
                         │
        ┌────────────────▼────────────────┐
        │         IMPLEMENTING             │
        └────┬───────────┬────────────┬───┘
             │           │            │
      blocked│    /ccpm:verify   update plan
             │           │            │
        ┌────▼────┐ ┌────▼────┐ ┌────▼────┐
        │ BLOCKED │ │VERIFYING│ │ PLANNED │
        └────┬────┘ └────┬────┘ └─────────┘
             │           │
          unblock     all checks
             │          pass
             │           │
             └───────┬───┤
                 ┌───▼───▼──┐
                 │ VERIFIED │
                 └─────┬────┘
                       │
                  /ccpm:done
                       │
                  ┌────▼────┐
                  │COMPLETE │
                  └─────────┘

         (Any state can transition to CANCELLED)
```

---

## State Persistence

### Storage Location

State is stored in **Linear issue custom fields** for persistence and synchronization across sessions.

```yaml
Linear Custom Fields:

ccpmPhase:
  type: text
  values: [IDEA, PLANNED, IMPLEMENTING, BLOCKED, VERIFYING, VERIFIED, COMPLETE, CANCELLED]
  description: "Current CCPM workflow phase"

ccpmLastCommand:
  type: text
  description: "Last CCPM command executed"
  example: "/ccpm:plan"

ccpmLastUpdate:
  type: text (ISO 8601 timestamp)
  description: "Timestamp of last CCPM command"
  example: "2025-11-21T10:30:00Z"

ccpmAutoTransitions:
  type: boolean
  default: true
  description: "Allow automatic state transitions"

ccpmVerificationGate:
  type: text
  values: [NONE, STANDARD, STRICT]
  default: "STANDARD"
  description: "Verification requirements before completion"

ccpmChecklistRequired:
  type: boolean
  default: true
  description: "Require 100% checklist completion for verification"
```

### State Object Schema

```typescript
interface WorkflowState {
  // Current state
  phase: Phase;
  linearStatus: string;
  lastCommand: string;
  lastUpdate: string; // ISO 8601

  // Configuration
  autoTransitions: boolean;
  verificationGate: 'NONE' | 'STANDARD' | 'STRICT';
  checklistRequired: boolean;

  // History
  history: StateTransition[];

  // Metadata
  projectId: string;
  issueId: string;
  userId: string;
}

interface StateTransition {
  timestamp: string;
  from: Phase;
  to: Phase;
  command: string;
  confidence: number;
  userConfirmed: boolean;
  reason: string;
}

type Phase =
  | 'IDEA'
  | 'PLANNED'
  | 'IMPLEMENTING'
  | 'BLOCKED'
  | 'VERIFYING'
  | 'VERIFIED'
  | 'COMPLETE'
  | 'CANCELLED';
```

### Persistence Operations

```typescript
// Save state to Linear
async function saveWorkflowState(
  issueId: string,
  state: Partial<WorkflowState>
): Promise<void> {
  await linearMCP.updateIssue(issueId, {
    customFields: {
      ccpmPhase: state.phase,
      ccpmLastCommand: state.lastCommand,
      ccpmLastUpdate: new Date().toISOString(),
      ccpmAutoTransitions: state.autoTransitions,
      ccpmVerificationGate: state.verificationGate,
      ccpmChecklistRequired: state.checklistRequired
    }
  });
}

// Load state from Linear
async function loadWorkflowState(
  issueId: string
): Promise<WorkflowState> {
  const issue = await linearMCP.getIssue(issueId);

  return {
    phase: issue.customFields?.ccpmPhase || inferPhaseFromStatus(issue.state.name),
    linearStatus: issue.state.name,
    lastCommand: issue.customFields?.ccpmLastCommand || null,
    lastUpdate: issue.customFields?.ccpmLastUpdate || issue.updatedAt,
    autoTransitions: issue.customFields?.ccpmAutoTransitions ?? true,
    verificationGate: issue.customFields?.ccpmVerificationGate || 'STANDARD',
    checklistRequired: issue.customFields?.ccpmChecklistRequired ?? true,
    history: await loadStateHistory(issueId),
    projectId: issue.project.id,
    issueId: issue.id,
    userId: issue.assignee?.id || null
  };
}

// Infer phase from Linear status (fallback)
function inferPhaseFromStatus(status: string): Phase {
  const statusLower = status.toLowerCase();

  if (statusLower.includes('backlog')) return 'IDEA';
  if (statusLower.includes('plan') || statusLower.includes('todo')) return 'PLANNED';
  if (statusLower.includes('progress') || statusLower.includes('doing')) return 'IMPLEMENTING';
  if (statusLower.includes('blocked')) return 'BLOCKED';
  if (statusLower.includes('review') || statusLower.includes('verif')) return 'VERIFYING';
  if (statusLower.includes('approved')) return 'VERIFIED';
  if (statusLower.includes('done') || statusLower.includes('complete')) return 'COMPLETE';
  if (statusLower.includes('cancel')) return 'CANCELLED';

  // Default fallback
  return 'IDEA';
}
```

---

## State Transitions

### Transition Validation

```typescript
// Validate if transition is allowed
async function validateTransition(
  issueId: string,
  fromPhase: Phase,
  toPhase: Phase
): Promise<ValidationResult> {
  const stateMachine = getStateMachine();
  const allowedNextStates = stateMachine[fromPhase].next_states;

  if (!allowedNextStates.includes(toPhase)) {
    return {
      valid: false,
      confidence: 0,
      error: `Cannot transition from ${fromPhase} to ${toPhase}`,
      allowedStates: allowedNextStates
    };
  }

  // Validate pre-conditions based on target state
  const validations = await validatePreConditions(issueId, toPhase);

  if (!validations.passed) {
    return {
      valid: false,
      confidence: 0,
      error: `Pre-conditions not met: ${validations.failures.join(', ')}`,
      failures: validations.failures
    };
  }

  return {
    valid: true,
    confidence: 95
  };
}

// Validate pre-conditions for target state
async function validatePreConditions(
  issueId: string,
  toPhase: Phase
): Promise<{ passed: boolean; failures: string[] }> {
  const issue = await getIssue(issueId);
  const failures: string[] = [];

  switch (toPhase) {
    case 'PLANNED':
      if (!hasImplementationChecklist(issue)) {
        failures.push('Missing implementation checklist');
      }
      break;

    case 'IMPLEMENTING':
      if (!hasImplementationChecklist(issue)) {
        failures.push('Not planned yet');
      }
      break;

    case 'VERIFYING':
      const checklist = extractChecklist(issue.description);
      if (checklist.completion < 100) {
        failures.push(`Checklist incomplete (${checklist.completion}%)`);
      }

      const hasUncommitted = await hasUncommittedChanges();
      if (hasUncommitted) {
        failures.push('Uncommitted changes');
      }
      break;

    case 'COMPLETE':
      if (!hasBeenVerified(issue)) {
        failures.push('Not verified yet');
      }
      break;
  }

  return {
    passed: failures.length === 0,
    failures
  };
}
```

### Transition Execution

```typescript
// Execute state transition
async function transitionState(
  issueId: string,
  toPhase: Phase,
  reason: string,
  userConfirmed: boolean = false
): Promise<TransitionResult> {
  const currentState = await loadWorkflowState(issueId);

  // Validate transition
  const validation = await validateTransition(
    issueId,
    currentState.phase,
    toPhase
  );

  if (!validation.valid) {
    return {
      success: false,
      error: validation.error,
      suggestions: validation.allowedStates?.map(s => `Try: ${s}`)
    };
  }

  // Check if confirmation needed
  const config = getTransitionConfig(currentState.phase, toPhase);

  if (config.requiresConfirmation && !userConfirmed) {
    return {
      success: false,
      requiresConfirmation: true,
      message: `Transition ${currentState.phase} → ${toPhase} requires confirmation`,
      confidence: config.confidence
    };
  }

  // Execute transition
  const newLinearStatus = getLinearStatusForPhase(toPhase);

  await linearMCP.updateIssue(issueId, {
    state: newLinearStatus
  });

  // Update state
  await saveWorkflowState(issueId, {
    phase: toPhase,
    lastCommand: getCurrentCommand(),
    lastUpdate: new Date().toISOString()
  });

  // Log transition
  await logStateTransition({
    timestamp: new Date().toISOString(),
    from: currentState.phase,
    to: toPhase,
    command: getCurrentCommand(),
    confidence: validation.confidence,
    userConfirmed,
    reason
  });

  // Add Linear comment
  await addTransitionComment(issueId, currentState.phase, toPhase, reason);

  return {
    success: true,
    fromPhase: currentState.phase,
    toPhase,
    newStatus: newLinearStatus
  };
}

// Add comment documenting transition
async function addTransitionComment(
  issueId: string,
  fromPhase: Phase,
  toPhase: Phase,
  reason: string
): Promise<void> {
  const emoji = getPhaseEmoji(toPhase);

  await linearMCP.createComment(issueId, {
    body: `${emoji} **Workflow Phase: ${fromPhase} → ${toPhase}**

${reason}

---
*Automated state transition via ${getCurrentCommand()}*`
  });
}

function getPhaseEmoji(phase: Phase): string {
  const emojis: Record<Phase, string> = {
    IDEA: '💡',
    PLANNED: '📋',
    IMPLEMENTING: '🚀',
    BLOCKED: '🚫',
    VERIFYING: '🔍',
    VERIFIED: '✅',
    COMPLETE: '🎉',
    CANCELLED: '❌'
  };

  return emojis[phase];
}
```

---

## Implementation Specification

### State Management Module

```typescript
// state-manager.ts

export class WorkflowStateManager {
  private issueId: string;
  private state: WorkflowState | null = null;

  constructor(issueId: string) {
    this.issueId = issueId;
  }

  // Load state from Linear
  async load(): Promise<WorkflowState> {
    this.state = await loadWorkflowState(this.issueId);
    return this.state;
  }

  // Get current phase
  getCurrentPhase(): Phase {
    if (!this.state) {
      throw new Error('State not loaded. Call load() first.');
    }
    return this.state.phase;
  }

  // Check if command is allowed in current state
  isCommandAllowed(command: string): boolean {
    if (!this.state) return false;

    const stateMachine = getStateMachine();
    const allowedCommands = stateMachine[this.state.phase].allowed_commands;

    return allowedCommands.some(pattern =>
      matchCommandPattern(command, pattern)
    );
  }

  // Get next possible states
  getNextStates(): Phase[] {
    if (!this.state) return [];

    const stateMachine = getStateMachine();
    return stateMachine[this.state.phase].next_states;
  }

  // Transition to new state
  async transitionTo(
    toPhase: Phase,
    reason: string,
    userConfirmed: boolean = false
  ): Promise<TransitionResult> {
    if (!this.state) {
      throw new Error('State not loaded');
    }

    const result = await transitionState(
      this.issueId,
      toPhase,
      reason,
      userConfirmed
    );

    if (result.success) {
      // Reload state
      await this.load();
    }

    return result;
  }

  // Suggest next action based on current state
  suggestNextAction(): ActionSuggestion {
    if (!this.state) return null;

    const phase = this.state.phase;

    switch (phase) {
      case 'IDEA':
        return {
          command: '/ccpm:plan',
          description: 'Create implementation plan',
          confidence: 90
        };

      case 'PLANNED':
        return {
          command: '/ccpm:work',
          description: 'Start implementation',
          confidence: 90
        };

      case 'IMPLEMENTING':
        // Check checklist completion
        const completion = this.state.checklistCompletion || 0;
        if (completion >= 100) {
          return {
            command: '/ccpm:verify',
            description: 'Run quality checks',
            confidence: 85
          };
        } else {
          return {
            command: '/ccpm:sync',
            description: 'Save progress',
            confidence: 70
          };
        }

      case 'VERIFYING':
        return {
          command: '/ccpm:verify',
          description: 'Continue verification',
          confidence: 80
        };

      case 'VERIFIED':
        return {
          command: '/ccpm:done',
          description: 'Finalize and create PR',
          confidence: 95
        };

      default:
        return null;
    }
  }

  // Get state summary for display
  getSummary(): string {
    if (!this.state) return 'State not loaded';

    const phase = this.state.phase;
    const status = this.state.linearStatus;
    const lastUpdate = new Date(this.state.lastUpdate).toLocaleString();

    return `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Workflow State
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase: ${phase}
Status: ${status}
Last Update: ${lastUpdate}
Last Command: ${this.state.lastCommand || 'None'}

Next Actions:
${this.getNextStates().map(s => `  • Transition to ${s}`).join('\n')}
    `.trim();
  }
}
```

### Integration with Commands

```typescript
// Command wrapper that manages state
export async function executeCommandWithState(
  command: string,
  issueId: string,
  handler: () => Promise<void>
): Promise<void> {
  // Load state
  const stateManager = new WorkflowStateManager(issueId);
  await stateManager.load();

  // Check if command is allowed
  if (!stateManager.isCommandAllowed(command)) {
    const currentPhase = stateManager.getCurrentPhase();
    const allowedCommands = getStateMachine()[currentPhase].allowed_commands;

    console.log(`⚠️  Warning: ${command} is not typically used in ${currentPhase} phase`);
    console.log(`\nSuggested commands for ${currentPhase}:`);
    allowedCommands.forEach(cmd => console.log(`  • ${cmd}`));
    console.log('\nContinue anyway? (yes/no)');

    const response = await getUserInput();
    if (response.toLowerCase() !== 'yes') {
      console.log('❌ Cancelled');
      return;
    }
  }

  // Execute command
  try {
    await handler();

    // Update last command
    await saveWorkflowState(issueId, {
      lastCommand: command,
      lastUpdate: new Date().toISOString()
    });

    // Suggest next action
    const suggestion = stateManager.suggestNextAction();
    if (suggestion) {
      console.log(`\n💡 Suggested next step: ${suggestion.command}`);
      console.log(`   ${suggestion.description}`);
    }
  } catch (error) {
    console.error('❌ Command failed:', error.message);

    // If command failed, potentially transition to BLOCKED
    if (isBlockingError(error)) {
      console.log('\n🚫 This appears to be a blocking issue');
      console.log('Mark task as BLOCKED? (yes/no)');

      const response = await getUserInput();
      if (response.toLowerCase() === 'yes') {
        await stateManager.transitionTo(
          'BLOCKED',
          `Blocked by: ${error.message}`,
          true
        );
      }
    }

    throw error;
  }
}
```

### Usage in Commands

```typescript
// Example: /ccpm:plan command
export async function executePlan(args: string[]): Promise<void> {
  const issueId = args[0];

  await executeCommandWithState('/ccpm:plan', issueId, async () => {
    // Normal command logic
    const issue = await getIssue(issueId);

    // ... plan the issue ...

    // Transition state
    const stateManager = new WorkflowStateManager(issueId);
    await stateManager.load();
    await stateManager.transitionTo(
      'PLANNED',
      'Implementation plan created',
      false // auto-transition
    );
  });
}

// Example: /ccpm:work command
export async function executeWork(args: string[]): Promise<void> {
  const issueId = args[0] || await detectIssueFromBranch();

  await executeCommandWithState('/ccpm:work', issueId, async () => {
    const stateManager = new WorkflowStateManager(issueId);
    await stateManager.load();

    const currentPhase = stateManager.getCurrentPhase();

    if (currentPhase === 'PLANNED') {
      // START mode
      await startImplementation(issueId);

      await stateManager.transitionTo(
        'IMPLEMENTING',
        'Implementation started',
        false
      );
    } else if (currentPhase === 'IMPLEMENTING') {
      // RESUME mode
      await resumeImplementation(issueId);
    } else {
      console.log(`⚠️  Warning: Starting work from ${currentPhase} phase`);
      console.log('Continue? (yes/no)');

      const response = await getUserInput();
      if (response.toLowerCase() !== 'yes') {
        return;
      }
    }
  });
}
```

---

## Integration with Commands

### State-Aware Command Behavior

Commands should adapt their behavior based on current workflow state:

```typescript
// /ccpm:verify behavior changes based on state
export async function executeVerify(issueId: string): Promise<void> {
  const stateManager = new WorkflowStateManager(issueId);
  await stateManager.load();

  const currentPhase = stateManager.getCurrentPhase();

  switch (currentPhase) {
    case 'IMPLEMENTING':
      // First-time verification
      console.log('🔍 Running first-time verification...');
      await runFullVerification(issueId);

      // Transition to VERIFYING
      await stateManager.transitionTo(
        'VERIFYING',
        'Started verification process',
        false
      );
      break;

    case 'VERIFYING':
      // Continue verification
      console.log('🔍 Continuing verification...');
      await continueVerification(issueId);
      break;

    case 'VERIFIED':
      // Already verified
      console.log('✅ Already verified!');
      console.log(`Next step: /ccpm:done`);
      return;

    default:
      console.log(`⚠️  Warning: Running verification in ${currentPhase} phase`);
      console.log('Continue? (yes/no)');

      const response = await getUserInput();
      if (response.toLowerCase() !== 'yes') {
        return;
      }
  }
}
```

---

## Summary

This workflow state tracking system provides:

1. **State Machine** - Clear phases with allowed transitions
2. **Persistence** - Store state in Linear custom fields
3. **Validation** - Pre-condition checks before transitions
4. **Confidence** - Confidence levels for each transition
5. **Command Integration** - State-aware command behavior
6. **Next Action Suggestions** - Guide users through workflow

**Benefits**:
- Prevents invalid workflow transitions
- Provides context for decision-making
- Enables accurate progress tracking
- Guides users with suggestions
- Validates pre-conditions automatically

---

**Related Documents**:
- [Decision Framework](./decision-framework.md)
- [Decision Trees](./decision-trees-visual.md)
- [Always-Ask Policy](../guides/implementing-always-ask-policy.md)
