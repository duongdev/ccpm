# CCPM Workflow State Machine

This file implements the CCPM workflow state machine for tracking task progression through workflow phases. It provides state management, validation, transitions, and persistence via Linear custom fields.

## Overview

The state machine tracks 8 workflow phases:
- **IDEA** - Initial concept
- **PLANNED** - Implementation plan created
- **IMPLEMENTING** - Active development
- **BLOCKED** - Cannot proceed due to blocker
- **VERIFYING** - Quality checks in progress
- **VERIFIED** - Verified and ready to complete
- **COMPLETE** - Task finalized
- **CANCELLED** - Task cancelled/abandoned

**Integration**: This file delegates all Linear operations to the `linear-operations` subagent for optimal performance.

---

## State Machine Definition

```javascript
const STATE_MACHINE = {
  IDEA: {
    description: "Initial concept, not yet planned",
    linear_status_mapping: ["Backlog"],
    phase: "ideation",
    next_states: ["PLANNED", "CANCELLED"],
    confidence_to_transition: {
      PLANNED: 95,  // High confidence via /ccpm:plan
      CANCELLED: 50  // Requires confirmation
    },
    allowed_commands: [
      "/ccpm:plan",
      "/ccpm:utils:*"
    ]
  },

  PLANNED: {
    description: "Requirements gathered, implementation plan created",
    linear_status_mapping: ["Planned", "Todo", "Ready"],
    phase: "planning",
    next_states: ["IMPLEMENTING", "IDEA", "CANCELLED"],
    confidence_to_transition: {
      IMPLEMENTING: 95,  // High confidence via /ccpm:work
      IDEA: 70,          // Re-planning
      CANCELLED: 50      // Requires confirmation
    },
    allowed_commands: [
      "/ccpm:work",
      "/ccpm:plan",  // Update plan
      "/ccpm:utils:*"
    ]
  },

  IMPLEMENTING: {
    description: "Active development in progress",
    linear_status_mapping: ["In Progress", "In Development", "Doing"],
    phase: "implementation",
    next_states: ["VERIFYING", "PLANNED", "BLOCKED"],
    confidence_to_transition: {
      VERIFYING: 70,    // Medium - depends on checklist
      PLANNED: 60,      // Re-planning
      BLOCKED: 90       // High if blocker detected
    },
    allowed_commands: [
      "/ccpm:sync",
      "/ccpm:commit",
      "/ccpm:verify",
      "/ccpm:implementation:*",
      "/ccpm:utils:*"
    ]
  },

  BLOCKED: {
    description: "Cannot proceed due to blocker",
    linear_status_mapping: ["Blocked"],
    phase: "implementation",
    next_states: ["IMPLEMENTING", "CANCELLED"],
    confidence_to_transition: {
      IMPLEMENTING: 85,  // High when unblocked
      CANCELLED: 50      // Requires confirmation
    },
    allowed_commands: [
      "/ccpm:verification:fix",
      "/ccpm:utils:status",
      "/ccpm:sync"
    ]
  },

  VERIFYING: {
    description: "Quality checks and verification in progress",
    linear_status_mapping: ["In Review", "Testing", "Verification"],
    phase: "verification",
    next_states: ["VERIFIED", "IMPLEMENTING"],
    confidence_to_transition: {
      VERIFIED: 85,      // High if all checks pass
      IMPLEMENTING: 100  // Certain if checks fail
    },
    allowed_commands: [
      "/ccpm:verify",
      "/ccpm:verification:*",
      "/ccpm:utils:*"
    ]
  },

  VERIFIED: {
    description: "Verified and ready to complete",
    linear_status_mapping: ["Verified", "Ready for Review", "Approved"],
    phase: "completion",
    next_states: ["COMPLETE", "IMPLEMENTING"],
    confidence_to_transition: {
      COMPLETE: 95,       // High confidence via /ccpm:done
      IMPLEMENTING: 70    // If changes needed
    },
    allowed_commands: [
      "/ccpm:done",
      "/ccpm:complete:finalize",
      "/ccpm:utils:*"
    ]
  },

  COMPLETE: {
    description: "Task finalized and closed",
    linear_status_mapping: ["Done", "Completed", "Closed"],
    phase: "complete",
    next_states: [],  // Terminal state
    confidence_to_transition: {},
    allowed_commands: [
      "/ccpm:utils:status",
      "/ccpm:utils:report"
    ]
  },

  CANCELLED: {
    description: "Task cancelled or abandoned",
    linear_status_mapping: ["Cancelled", "Archived"],
    phase: "cancelled",
    next_states: [],  // Terminal state
    confidence_to_transition: {},
    allowed_commands: [
      "/ccpm:utils:status"
    ]
  }
};
```

---

## Core Functions

### 1. loadWorkflowState

Load current workflow state from Linear custom fields.

```javascript
/**
 * Load workflow state from Linear issue
 * @param {string} issueId - Linear issue ID or identifier
 * @returns {Promise<Object>} Workflow state object
 */
async function loadWorkflowState(issueId) {
  // Delegate to Linear subagent
  const result = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
  include_custom_fields: true
context:
  command: "state-machine:load"
  purpose: "Loading workflow state"
`);

  if (!result.success) {
    throw new Error(`Failed to load workflow state: ${result.error?.message || 'Unknown error'}`);
  }

  const issue = result.data;
  const customFields = issue.customFields || {};

  // Extract CCPM state fields
  const phase = customFields.ccpmPhase || inferPhaseFromStatus(issue.state.name);
  const lastCommand = customFields.ccpmLastCommand || null;
  const lastUpdate = customFields.ccpmLastUpdate || issue.updatedAt;
  const autoTransitions = customFields.ccpmAutoTransitions !== false;  // Default true
  const verificationGate = customFields.ccpmVerificationGate || 'STANDARD';
  const checklistRequired = customFields.ccpmChecklistRequired !== false;  // Default true

  return {
    // Current state
    phase,
    linearStatus: issue.state.name,
    lastCommand,
    lastUpdate,

    // Configuration
    autoTransitions,
    verificationGate,
    checklistRequired,

    // Metadata
    issueId: issue.id,
    issueIdentifier: issue.identifier,
    title: issue.title,
    teamId: issue.team.id,
    projectId: issue.project?.id || null,

    // Calculated fields
    nextStates: STATE_MACHINE[phase]?.next_states || [],
    allowedCommands: STATE_MACHINE[phase]?.allowed_commands || []
  };
}

/**
 * Infer CCPM phase from Linear status name (fallback)
 * @param {string} statusName - Linear status name
 * @returns {string} CCPM phase
 */
function inferPhaseFromStatus(statusName) {
  const lower = statusName.toLowerCase();

  if (lower.includes('backlog')) return 'IDEA';
  if (lower.includes('plan') || lower.includes('todo') || lower.includes('ready')) return 'PLANNED';
  if (lower.includes('progress') || lower.includes('doing') || lower.includes('development')) return 'IMPLEMENTING';
  if (lower.includes('blocked')) return 'BLOCKED';
  if (lower.includes('review') || lower.includes('verif') || lower.includes('testing')) return 'VERIFYING';
  if (lower.includes('approved')) return 'VERIFIED';
  if (lower.includes('done') || lower.includes('complete') || lower.includes('closed')) return 'COMPLETE';
  if (lower.includes('cancel') || lower.includes('archived')) return 'CANCELLED';

  // Default fallback
  return 'IDEA';
}
```

---

### 2. saveWorkflowState

Persist workflow state to Linear custom fields.

```javascript
/**
 * Save workflow state to Linear
 * @param {string} issueId - Linear issue ID or identifier
 * @param {Object} stateUpdates - State fields to update
 * @returns {Promise<void>}
 */
async function saveWorkflowState(issueId, stateUpdates) {
  // Build custom fields update
  const customFields = {};

  if (stateUpdates.phase !== undefined) {
    customFields.ccpmPhase = stateUpdates.phase;
  }

  if (stateUpdates.lastCommand !== undefined) {
    customFields.ccpmLastCommand = stateUpdates.lastCommand;
  }

  // Always update timestamp
  customFields.ccpmLastUpdate = new Date().toISOString();

  if (stateUpdates.autoTransitions !== undefined) {
    customFields.ccpmAutoTransitions = stateUpdates.autoTransitions;
  }

  if (stateUpdates.verificationGate !== undefined) {
    customFields.ccpmVerificationGate = stateUpdates.verificationGate;
  }

  if (stateUpdates.checklistRequired !== undefined) {
    customFields.ccpmChecklistRequired = stateUpdates.checklistRequired;
  }

  // Delegate to Linear subagent
  const result = await Task('linear-operations', `
operation: update_issue_custom_fields
params:
  issue_id: "${issueId}"
  custom_fields:
    ${Object.entries(customFields).map(([key, value]) =>
      `${key}: ${typeof value === 'string' ? `"${value}"` : value}`
    ).join('\n    ')}
context:
  command: "state-machine:save"
  purpose: "Persisting workflow state"
`);

  if (!result.success) {
    throw new Error(`Failed to save workflow state: ${result.error?.message || 'Unknown error'}`);
  }
}
```

---

### 3. validateTransition

Validate if a state transition is allowed.

```javascript
/**
 * Validate if transition is allowed
 * @param {string} fromPhase - Current phase
 * @param {string} toPhase - Target phase
 * @param {Object} options - Validation options
 * @param {string} options.issueId - Issue ID for pre-condition checks
 * @returns {Promise<Object>} Validation result
 */
async function validateTransition(fromPhase, toPhase, options = {}) {
  const stateMachine = STATE_MACHINE;
  const currentStateConfig = stateMachine[fromPhase];

  if (!currentStateConfig) {
    return {
      valid: false,
      confidence: 0,
      error: `Unknown phase: ${fromPhase}`,
      suggestions: Object.keys(stateMachine)
    };
  }

  const allowedNextStates = currentStateConfig.next_states || [];

  if (!allowedNextStates.includes(toPhase)) {
    return {
      valid: false,
      confidence: 0,
      error: `Cannot transition from ${fromPhase} to ${toPhase}`,
      allowedStates: allowedNextStates,
      suggestions: allowedNextStates.map(s => `Try transitioning to: ${s}`)
    };
  }

  // Validate pre-conditions if issueId provided
  if (options.issueId) {
    const preConditions = await validatePreConditions(options.issueId, toPhase);

    if (!preConditions.passed) {
      return {
        valid: false,
        confidence: 0,
        error: `Pre-conditions not met for ${toPhase}`,
        failures: preConditions.failures,
        suggestions: preConditions.failures.map(f => `Fix: ${f}`)
      };
    }
  }

  // Get confidence for this transition
  const confidence = currentStateConfig.confidence_to_transition[toPhase] || 90;

  return {
    valid: true,
    confidence
  };
}

/**
 * Validate pre-conditions for target phase
 * @param {string} issueId - Issue ID
 * @param {string} toPhase - Target phase
 * @returns {Promise<Object>} Pre-condition validation result
 */
async function validatePreConditions(issueId, toPhase) {
  const failures = [];

  // Load issue data
  const state = await loadWorkflowState(issueId);
  const issueResult = await Task('linear-operations', `
operation: get_issue
params:
  issue_id: "${issueId}"
context:
  command: "state-machine:validate-preconditions"
`);

  if (!issueResult.success) {
    failures.push('Failed to fetch issue data');
    return { passed: false, failures };
  }

  const issue = issueResult.data;

  switch (toPhase) {
    case 'PLANNED':
      // Must have implementation checklist
      if (!issue.description.includes('## Implementation Checklist')) {
        failures.push('Missing implementation checklist');
      }
      break;

    case 'IMPLEMENTING':
      // Must be planned
      if (!issue.description.includes('## Implementation Checklist')) {
        failures.push('Not planned yet - run /ccpm:plan first');
      }
      break;

    case 'VERIFYING':
      // Check checklist completion
      const checklist = extractChecklist(issue.description);
      if (state.checklistRequired && checklist.completion < 100) {
        failures.push(`Checklist incomplete (${checklist.completion}%)`);
      }

      // Check for uncommitted changes (local git check)
      const hasUncommitted = await hasUncommittedChanges();
      if (hasUncommitted) {
        failures.push('Uncommitted changes detected - commit first');
      }
      break;

    case 'VERIFIED':
      // Must have passing verification
      // Note: This is typically checked by verification command
      break;

    case 'COMPLETE':
      // Must be verified
      if (state.phase !== 'VERIFIED') {
        failures.push('Not verified yet - run /ccpm:verify first');
      }
      break;
  }

  return {
    passed: failures.length === 0,
    failures
  };
}

/**
 * Extract checklist from description
 * @param {string} description - Issue description
 * @returns {Object} Checklist data
 */
function extractChecklist(description) {
  const checklistItems = description.match(/- \[([ x])\] .+/g) || [];
  const completed = checklistItems.filter(i => i.includes('[x]')).length;
  const total = checklistItems.length;

  return {
    items: checklistItems,
    completed,
    total,
    completion: total > 0 ? Math.round((completed / total) * 100) : 0
  };
}

/**
 * Check for uncommitted changes (local git)
 * @returns {Promise<boolean>}
 */
async function hasUncommittedChanges() {
  try {
    const result = await Bash({
      command: 'git status --porcelain',
      description: 'Check for uncommitted changes'
    });
    return result.trim().length > 0;
  } catch (error) {
    return false;  // Not a git repo or error
  }
}
```

---

### 4. transitionState

Execute a state transition with validation and persistence.

```javascript
/**
 * Execute state transition
 * @param {string} issueId - Issue ID
 * @param {string} toPhase - Target phase
 * @param {Object} options - Transition options
 * @param {string} options.reason - Reason for transition
 * @param {boolean} options.userConfirmed - User confirmed transition
 * @param {string} options.command - Command triggering transition
 * @returns {Promise<Object>} Transition result
 */
async function transitionState(issueId, toPhase, options = {}) {
  const {
    reason = 'State transition',
    userConfirmed = false,
    command = 'unknown'
  } = options;

  // Load current state
  const currentState = await loadWorkflowState(issueId);

  // Validate transition
  const validation = await validateTransition(
    currentState.phase,
    toPhase,
    { issueId }
  );

  if (!validation.valid) {
    return {
      success: false,
      error: validation.error,
      failures: validation.failures,
      suggestions: validation.suggestions
    };
  }

  // Check if confirmation needed
  const requiresConfirmation = validation.confidence < 80;

  if (requiresConfirmation && !userConfirmed) {
    return {
      success: false,
      requiresConfirmation: true,
      message: `Transition ${currentState.phase} → ${toPhase} requires confirmation`,
      confidence: validation.confidence
    };
  }

  // Determine new Linear status
  const newLinearStatus = getLinearStatusForPhase(toPhase);

  // Update Linear issue status
  const updateResult = await Task('linear-operations', `
operation: update_issue
params:
  issue_id: "${issueId}"
  state: "${newLinearStatus}"
context:
  command: "state-machine:transition"
  from_phase: "${currentState.phase}"
  to_phase: "${toPhase}"
`);

  if (!updateResult.success) {
    return {
      success: false,
      error: `Failed to update Linear status: ${updateResult.error?.message}`
    };
  }

  // Update workflow state
  await saveWorkflowState(issueId, {
    phase: toPhase,
    lastCommand: command
  });

  // Add transition comment
  await addTransitionComment(issueId, currentState.phase, toPhase, reason);

  return {
    success: true,
    fromPhase: currentState.phase,
    toPhase,
    newStatus: newLinearStatus,
    confidence: validation.confidence
  };
}

/**
 * Get Linear status for phase
 * @param {string} phase - CCPM phase
 * @returns {string} Linear status name
 */
function getLinearStatusForPhase(phase) {
  const statusMap = {
    IDEA: 'Backlog',
    PLANNED: 'Planned',
    IMPLEMENTING: 'In Progress',
    BLOCKED: 'Blocked',
    VERIFYING: 'In Review',
    VERIFIED: 'Verified',
    COMPLETE: 'Done',
    CANCELLED: 'Cancelled'
  };

  return statusMap[phase] || 'Backlog';
}

/**
 * Add transition comment to Linear
 * @param {string} issueId - Issue ID
 * @param {string} fromPhase - Previous phase
 * @param {string} toPhase - New phase
 * @param {string} reason - Transition reason
 * @returns {Promise<void>}
 */
async function addTransitionComment(issueId, fromPhase, toPhase, reason) {
  const emoji = getPhaseEmoji(toPhase);

  const commentBody = `${emoji} **Workflow Phase: ${fromPhase} → ${toPhase}**

${reason}

---
*Automated state transition*`;

  await Task('linear-operations', `
operation: create_comment
params:
  issue_id: "${issueId}"
  body: |
    ${commentBody}
context:
  command: "state-machine:transition-comment"
`);
}

function getPhaseEmoji(phase) {
  const emojis = {
    IDEA: '💡',
    PLANNED: '📋',
    IMPLEMENTING: '🚀',
    BLOCKED: '🚫',
    VERIFYING: '🔍',
    VERIFIED: '✅',
    COMPLETE: '🎉',
    CANCELLED: '❌'
  };

  return emojis[phase] || '📌';
}
```

---

### 5. suggestNextAction

Suggest the next command based on current workflow state.

```javascript
/**
 * Suggest next action based on current state
 * @param {Object} state - Workflow state
 * @returns {Object} Action suggestion
 */
function suggestNextAction(state) {
  const phase = state.phase;

  switch (phase) {
    case 'IDEA':
      return {
        command: '/ccpm:plan',
        description: 'Create implementation plan',
        confidence: 90,
        reasoning: 'Task needs planning before implementation'
      };

    case 'PLANNED':
      return {
        command: '/ccpm:work',
        description: 'Start implementation',
        confidence: 90,
        reasoning: 'Plan is ready, begin development'
      };

    case 'IMPLEMENTING':
      // Check progress
      if (state.checklistCompletion >= 100) {
        return {
          command: '/ccpm:verify',
          description: 'Run quality checks',
          confidence: 85,
          reasoning: 'Checklist complete, verify before completion'
        };
      } else {
        return {
          command: '/ccpm:sync',
          description: 'Save progress',
          confidence: 70,
          reasoning: 'Continue implementation and sync progress'
        };
      }

    case 'BLOCKED':
      return {
        command: '/ccpm:verification:fix',
        description: 'Fix blocker',
        confidence: 80,
        reasoning: 'Address blocking issue to continue'
      };

    case 'VERIFYING':
      return {
        command: '/ccpm:verify',
        description: 'Continue verification',
        confidence: 80,
        reasoning: 'Complete verification process'
      };

    case 'VERIFIED':
      return {
        command: '/ccpm:done',
        description: 'Finalize and create PR',
        confidence: 95,
        reasoning: 'Verification passed, ready to complete'
      };

    case 'COMPLETE':
      return null;  // Terminal state

    case 'CANCELLED':
      return null;  // Terminal state

    default:
      return {
        command: '/ccpm:utils:status',
        description: 'Check task status',
        confidence: 60,
        reasoning: 'Unknown state, check status'
      };
  }
}
```

---

### 6. isCommandAllowed

Check if command is allowed in current state.

```javascript
/**
 * Check if command is allowed in current phase
 * @param {string} command - Command to check
 * @param {string} phase - Current phase
 * @returns {Object} Validation result
 */
function isCommandAllowed(command, phase) {
  const stateConfig = STATE_MACHINE[phase];

  if (!stateConfig) {
    return {
      allowed: false,
      reason: `Unknown phase: ${phase}`
    };
  }

  const allowedPatterns = stateConfig.allowed_commands || [];

  // Check if command matches any pattern
  const isAllowed = allowedPatterns.some(pattern => {
    if (pattern.endsWith('*')) {
      // Wildcard pattern (e.g., "/ccpm:utils:*")
      const prefix = pattern.slice(0, -1);
      return command.startsWith(prefix);
    } else {
      // Exact match
      return command === pattern;
    }
  });

  if (!isAllowed) {
    return {
      allowed: false,
      reason: `Command ${command} not typically used in ${phase} phase`,
      suggestedCommands: allowedPatterns
    };
  }

  return {
    allowed: true
  };
}
```

---

## Integration Example

```javascript
// Example: Using state machine in /ccpm:work command

async function executeWork(issueId) {
  // Load current state
  const state = await loadWorkflowState(issueId);

  console.log(`\n📊 Current Phase: ${state.phase}`);
  console.log(`📋 Status: ${state.linearStatus}\n`);

  // Check if command is allowed
  const commandCheck = isCommandAllowed('/ccpm:work', state.phase);

  if (!commandCheck.allowed) {
    console.log(`⚠️  ${commandCheck.reason}`);
    console.log(`\nSuggested commands for ${state.phase}:`);
    commandCheck.suggestedCommands.forEach(cmd => console.log(`  • ${cmd}`));
    console.log('');

    // Ask user if they want to continue anyway
    const answer = await askUserForClarification({
      question: "Continue anyway?",
      header: "Confirm",
      options: [
        { label: "Yes, continue", description: "Proceed with command" },
        { label: "No, cancel", description: "Cancel command" }
      ]
    });

    if (!answer.includes('Yes')) {
      console.log('❌ Cancelled');
      return;
    }
  }

  // Determine action based on current phase
  if (state.phase === 'PLANNED') {
    // START mode - transition to IMPLEMENTING
    console.log('🚀 Starting implementation...\n');

    const transitionResult = await transitionState(issueId, 'IMPLEMENTING', {
      reason: 'Implementation started via /ccpm:work',
      command: '/ccpm:work'
    });

    if (transitionResult.success) {
      console.log(`✅ Transitioned: ${transitionResult.fromPhase} → ${transitionResult.toPhase}`);
      // ... continue with implementation start
    } else {
      console.error(`❌ Transition failed: ${transitionResult.error}`);
      if (transitionResult.failures) {
        transitionResult.failures.forEach(f => console.log(`  • ${f}`));
      }
      return;
    }
  } else if (state.phase === 'IMPLEMENTING') {
    // RESUME mode
    console.log('⏩ Resuming implementation...\n');
    // ... continue with resume logic
  } else {
    // Unexpected phase
    const suggestion = suggestNextAction(state);
    if (suggestion) {
      console.log(`💡 Suggested: ${suggestion.command}`);
      console.log(`   ${suggestion.description}\n`);
    }
  }
}
```

---

## Display Helpers

```javascript
/**
 * Display workflow state summary
 * @param {Object} state - Workflow state
 */
function displayStateSummary(state) {
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🎯 Workflow State');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  const emoji = getPhaseEmoji(state.phase);
  console.log(`${emoji} Phase: ${state.phase}`);
  console.log(`📋 Status: ${state.linearStatus}`);

  if (state.lastCommand) {
    console.log(`⚙️  Last Command: ${state.lastCommand}`);
  }

  const lastUpdateDate = new Date(state.lastUpdate);
  console.log(`🕐 Last Update: ${lastUpdateDate.toLocaleString()}`);

  console.log('\n📍 Next Actions:');
  state.nextStates.forEach(nextState => {
    console.log(`  • Transition to ${nextState}`);
  });

  const suggestion = suggestNextAction(state);
  if (suggestion) {
    console.log(`\n💡 Suggested: ${suggestion.command}`);
    console.log(`   ${suggestion.description}`);
    console.log(`   Confidence: ${suggestion.confidence}%`);
  }

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}
```

---

## Best Practices

1. **Always load state** before command execution
2. **Validate transitions** before attempting state changes
3. **Check pre-conditions** for critical transitions
4. **Display state** for user awareness
5. **Persist transitions** with comments for audit trail
6. **Suggest next actions** to guide workflow
7. **Handle terminal states** (COMPLETE, CANCELLED) gracefully

---

## Testing

```javascript
// Test state loading
const state = await loadWorkflowState('PSN-29');
console.log('Loaded state:', state);

// Test transition validation
const validation = await validateTransition('IMPLEMENTING', 'VERIFYING', {
  issueId: 'PSN-29'
});
console.log('Validation:', validation);

// Test state transition
const result = await transitionState('PSN-29', 'VERIFYING', {
  reason: 'Checklist complete',
  command: '/ccpm:verify'
});
console.log('Transition result:', result);

// Test next action suggestion
const suggestion = suggestNextAction(state);
console.log('Suggested action:', suggestion);
```

---

## Related Documents

- [Decision Framework](../docs/architecture/decision-framework.md)
- [Workflow State Tracking Design](../docs/architecture/workflow-state-tracking.md)
- [Decision Helpers](./_shared-decision-helpers.md)
