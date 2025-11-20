# Shared Decision Helper Functions (Always-Ask Policy Implementation)

This file provides reusable decision-making utilities for implementing the Always-Ask Policy across all CCPM commands. These helpers enable consistent, confidence-based decision making with automatic user interaction when confidence is below thresholds.

## Overview

The Always-Ask Policy states: **When confidence < 80%, explicitly ask the user rather than making assumptions.**

These helper functions provide:
- **Confidence calculation** - Score decisions 0-100 based on context
- **Ask/proceed logic** - Automatically ask user when confidence is low
- **User question formatting** - Standardized question templates
- **Fuzzy matching** - Intelligent string matching with thresholds
- **Validation** - Pre/during/post command validation

**Usage in commands:** Reference this file at the start of command execution:
```markdown
READ: commands/_shared-decision-helpers.md
```

Then use the functions as described below.

---

## Core Functions

### 1. calculateConfidence

Calculates confidence score (0-100) for a decision based on multiple signals.

```javascript
/**
 * Calculate confidence score for a decision
 * @param {Object} context - Decision context
 * @param {any} context.input - User input to evaluate
 * @param {any} context.expected - Expected value/pattern
 * @param {Object} context.signals - Additional confidence signals
 * @param {number} context.signals.patternMatch - Pattern match confidence (0-100)
 * @param {number} context.signals.contextMatch - Context match confidence (0-100)
 * @param {number} context.signals.historicalSuccess - Historical success rate (0-100)
 * @param {number} context.signals.userPreference - User preference strength (0-100)
 * @returns {Object} Confidence result with score and reasoning
 */
function calculateConfidence(context) {
  let confidence = 0;
  const reasoning = [];

  // Signal 1: Pattern Match (weight: 50%)
  if (context.signals?.patternMatch !== undefined) {
    const patternScore = context.signals.patternMatch * 0.5;
    confidence += patternScore;
    reasoning.push(`Pattern match: ${context.signals.patternMatch}% (weighted: ${patternScore.toFixed(0)})`);
  }

  // Signal 2: Context Match (weight: 30%)
  if (context.signals?.contextMatch !== undefined) {
    const contextScore = context.signals.contextMatch * 0.3;
    confidence += contextScore;
    reasoning.push(`Context match: ${context.signals.contextMatch}% (weighted: ${contextScore.toFixed(0)})`);
  }

  // Signal 3: Historical Success (weight: 20%)
  if (context.signals?.historicalSuccess !== undefined) {
    const historyScore = context.signals.historicalSuccess * 0.2;
    confidence += historyScore;
    reasoning.push(`Historical success: ${context.signals.historicalSuccess}% (weighted: ${historyScore.toFixed(0)})`);
  }

  // Signal 4: User Preference (bonus: +10)
  if (context.signals?.userPreference !== undefined && context.signals.userPreference > 70) {
    const preferenceBonus = 10;
    confidence += preferenceBonus;
    reasoning.push(`User preference bonus: +${preferenceBonus}`);
  }

  // Cap at 100
  confidence = Math.min(confidence, 100);

  return {
    confidence: Math.round(confidence),
    reasoning: reasoning.join(', '),
    shouldAsk: confidence < 80,
    level: getConfidenceLevel(confidence)
  };
}

function getConfidenceLevel(confidence) {
  if (confidence >= 95) return 'CERTAIN';
  if (confidence >= 80) return 'HIGH';
  if (confidence >= 50) return 'MEDIUM';
  return 'LOW';
}
```

**Usage Example:**
```javascript
// Calculate confidence for issue ID pattern
const result = calculateConfidence({
  input: "PSN-29",
  expected: /^[A-Z]+-\d+$/,
  signals: {
    patternMatch: 100,  // Exact regex match
    contextMatch: 90,    // Branch name contains PSN-29
    historicalSuccess: 95 // 95% past success rate
  }
});

// Result:
// {
//   confidence: 93,
//   reasoning: "Pattern match: 100% (weighted: 50), Context match: 90% (weighted: 27), Historical success: 95% (weighted: 19)",
//   shouldAsk: false,
//   level: "HIGH"
// }
```

---

### 2. shouldAsk

Determines if user should be asked based on confidence level and policy.

```javascript
/**
 * Determine if user should be asked for confirmation
 * @param {number} confidence - Confidence score (0-100)
 * @param {Object} options - Additional options
 * @param {boolean} options.alwaysAsk - Force asking regardless of confidence
 * @param {boolean} options.neverAsk - Never ask (for certain operations)
 * @param {number} options.threshold - Custom confidence threshold (default: 80)
 * @returns {Object} Decision result
 */
function shouldAsk(confidence, options = {}) {
  // Override: Always ask (for safety-critical operations)
  if (options.alwaysAsk) {
    return {
      shouldAsk: true,
      reason: 'Safety-critical operation requires confirmation',
      displayMode: 'CONFIRM_REQUIRED'
    };
  }

  // Override: Never ask (for validation operations)
  if (options.neverAsk) {
    return {
      shouldAsk: false,
      reason: 'Validation operation, no user input needed',
      displayMode: 'AUTO_PROCEED'
    };
  }

  // Default threshold: 80%
  const threshold = options.threshold || 80;

  if (confidence >= 95) {
    return {
      shouldAsk: false,
      reason: 'Certain - proceeding automatically',
      displayMode: 'AUTO_PROCEED_SILENT'
    };
  } else if (confidence >= threshold) {
    return {
      shouldAsk: false,
      reason: `High confidence (${confidence}%) - proceeding with display`,
      displayMode: 'AUTO_PROCEED_WITH_DISPLAY'
    };
  } else if (confidence >= 50) {
    return {
      shouldAsk: true,
      reason: `Medium confidence (${confidence}%) - suggesting with confirmation`,
      displayMode: 'SUGGEST_AND_CONFIRM'
    };
  } else {
    return {
      shouldAsk: true,
      reason: `Low confidence (${confidence}%) - asking user`,
      displayMode: 'ASK_WITHOUT_SUGGESTION'
    };
  }
}
```

**Usage Example:**
```javascript
// Check if we should ask
const decision = shouldAsk(65);
// Result: { shouldAsk: true, reason: "Medium confidence (65%) - suggesting with confirmation", displayMode: "SUGGEST_AND_CONFIRM" }

// Force asking for external writes
const externalWrite = shouldAsk(95, { alwaysAsk: true });
// Result: { shouldAsk: true, reason: "Safety-critical operation requires confirmation", displayMode: "CONFIRM_REQUIRED" }
```

---

### 3. askUserForClarification

Wrapper around AskUserQuestion tool with standardized formatting.

```javascript
/**
 * Ask user for clarification using AskUserQuestion tool
 * @param {Object} questionConfig - Question configuration
 * @param {string} questionConfig.question - The question to ask
 * @param {string} questionConfig.header - Short header (max 12 chars)
 * @param {Array} questionConfig.options - Array of options
 * @param {any} questionConfig.options[].label - Option label
 * @param {string} questionConfig.options[].description - Option description
 * @param {any} questionConfig.options[].value - Option value (optional, defaults to label)
 * @param {boolean} questionConfig.multiSelect - Allow multiple selections (default: false)
 * @param {any} questionConfig.suggestion - Suggested value (for pre-selection)
 * @param {number} questionConfig.confidence - Confidence in suggestion (for display)
 * @returns {Promise<any>} User's selected value(s)
 */
async function askUserForClarification(questionConfig) {
  const {
    question,
    header,
    options,
    multiSelect = false,
    suggestion = null,
    confidence = null
  } = questionConfig;

  // Format options with suggestion highlighting
  const formattedOptions = options.map(opt => {
    const isSuggestion = suggestion && (opt.value === suggestion || opt.label === suggestion);

    return {
      label: isSuggestion ? `${opt.label} ⭐ (suggested)` : opt.label,
      description: isSuggestion && confidence
        ? `${opt.description} (${confidence}% confidence)`
        : opt.description
    };
  });

  // Display question context if medium/low confidence
  if (confidence !== null && confidence < 80) {
    console.log(`\n💡 AI Confidence: ${confidence}%`);
    if (suggestion) {
      console.log(`   Suggested: ${suggestion}`);
    }
    console.log('');
  }

  // Ask user
  const answer = await AskUserQuestion({
    questions: [{
      question,
      header,
      multiSelect,
      options: formattedOptions
    }]
  });

  // Extract answer (remove suggestion marker if present)
  const rawAnswer = answer[header];
  const cleanedAnswer = Array.isArray(rawAnswer)
    ? rawAnswer.map(a => a.replace(' ⭐ (suggested)', ''))
    : rawAnswer.replace(' ⭐ (suggested)', '');

  return cleanedAnswer;
}
```

**Usage Example:**
```javascript
// Ask with suggestion (medium confidence)
const mode = await askUserForClarification({
  question: "What would you like to do?",
  header: "Mode",
  options: [
    { label: "Create new", description: "Start from scratch" },
    { label: "Plan existing", description: "Add plan to existing issue" },
    { label: "Update plan", description: "Modify existing plan" }
  ],
  suggestion: "Plan existing",
  confidence: 65
});

// Ask without suggestion (low confidence)
const commitType = await askUserForClarification({
  question: "Select commit type:",
  header: "Type",
  options: [
    { label: "feat", description: "New feature" },
    { label: "fix", description: "Bug fix" },
    { label: "docs", description: "Documentation" }
  ]
});
```

---

### 4. displayOptionsAndConfirm

Display what will happen and ask for confirmation.

```javascript
/**
 * Display proposed action and ask for confirmation
 * @param {string} action - Action description
 * @param {Object} details - Action details to display
 * @param {Object} options - Display options
 * @param {string} options.title - Section title (default: "Proposed Action")
 * @param {string} options.emoji - Title emoji (default: "📋")
 * @param {boolean} options.requireExplicitYes - Require "yes" instead of any confirmation (default: false)
 * @returns {Promise<boolean>} True if confirmed, false otherwise
 */
async function displayOptionsAndConfirm(action, details, options = {}) {
  const {
    title = 'Proposed Action',
    emoji = '📋',
    requireExplicitYes = false
  } = options;

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`${emoji} ${title}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  console.log(action);
  console.log('');

  // Display details
  Object.entries(details).forEach(([key, value]) => {
    if (Array.isArray(value)) {
      console.log(`${key}:`);
      value.forEach(item => console.log(`  • ${item}`));
    } else {
      console.log(`${key}: ${value}`);
    }
  });

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // Ask for confirmation
  const answer = await askUserForClarification({
    question: "Proceed with this action?",
    header: "Confirm",
    options: [
      { label: "Yes, proceed", description: "Execute the action shown above" },
      { label: "No, cancel", description: "Cancel and return" }
    ]
  });

  const confirmed = answer.toLowerCase().includes('yes');

  if (!confirmed) {
    console.log('❌ Cancelled\n');
  }

  return confirmed;
}
```

**Usage Example:**
```javascript
// Display and confirm external write
const confirmed = await displayOptionsAndConfirm(
  "Update Jira ticket TRAIN-456",
  {
    "Status": "In Progress → Done",
    "Comment": "Completed via /ccpm:done",
    "Labels": ["ccpm", "completed"]
  },
  {
    title: "External System Write",
    emoji: "🚨",
    requireExplicitYes: true
  }
);

if (confirmed) {
  // Proceed with write
}
```

---

### 5. fuzzyMatch

Intelligent fuzzy matching with confidence scoring.

```javascript
/**
 * Fuzzy match input against options with confidence scoring
 * @param {string} input - User input
 * @param {Array} options - Array of valid options (strings or objects with 'name' property)
 * @param {Object} config - Matching configuration
 * @param {number} config.threshold - Minimum similarity threshold (0-100, default: 60)
 * @param {boolean} config.caseSensitive - Case sensitive matching (default: false)
 * @param {Array} config.aliases - Map of aliases to canonical values
 * @returns {Object} Match result
 */
function fuzzyMatch(input, options, config = {}) {
  const {
    threshold = 60,
    caseSensitive = false,
    aliases = {}
  } = config;

  // Normalize input
  const normalizedInput = caseSensitive ? input : input.toLowerCase().trim();

  // Check aliases first
  if (aliases[normalizedInput]) {
    return {
      match: aliases[normalizedInput],
      confidence: 100,
      exactMatch: true,
      reason: 'Alias match'
    };
  }

  // Extract option strings
  const optionStrings = options.map(opt =>
    typeof opt === 'string' ? opt : opt.name || opt.label || String(opt)
  );

  // Normalize options
  const normalizedOptions = optionStrings.map(opt =>
    caseSensitive ? opt : opt.toLowerCase().trim()
  );

  // Strategy 1: Exact match
  const exactIndex = normalizedOptions.findIndex(opt => opt === normalizedInput);
  if (exactIndex !== -1) {
    return {
      match: optionStrings[exactIndex],
      confidence: 100,
      exactMatch: true,
      reason: 'Exact match'
    };
  }

  // Strategy 2: Starts with
  const startsWithIndex = normalizedOptions.findIndex(opt => opt.startsWith(normalizedInput));
  if (startsWithIndex !== -1) {
    return {
      match: optionStrings[startsWithIndex],
      confidence: 85,
      exactMatch: false,
      reason: 'Starts with match'
    };
  }

  // Strategy 3: Contains
  const containsIndex = normalizedOptions.findIndex(opt => opt.includes(normalizedInput));
  if (containsIndex !== -1) {
    return {
      match: optionStrings[containsIndex],
      confidence: 70,
      exactMatch: false,
      reason: 'Contains match'
    };
  }

  // Strategy 4: Levenshtein distance (simplified)
  const distances = normalizedOptions.map(opt => ({
    option: opt,
    distance: levenshteinDistance(normalizedInput, opt)
  }));

  distances.sort((a, b) => a.distance - b.distance);
  const closest = distances[0];

  // Calculate similarity percentage
  const maxLen = Math.max(normalizedInput.length, closest.option.length);
  const similarity = ((maxLen - closest.distance) / maxLen) * 100;

  if (similarity >= threshold) {
    const matchIndex = normalizedOptions.indexOf(closest.option);
    return {
      match: optionStrings[matchIndex],
      confidence: Math.round(similarity),
      exactMatch: false,
      reason: `Fuzzy match (${closest.distance} edits)`
    };
  }

  // No match found
  return {
    match: null,
    confidence: 0,
    exactMatch: false,
    reason: 'No match found',
    suggestions: optionStrings.slice(0, 3)
  };
}

// Simplified Levenshtein distance
function levenshteinDistance(str1, str2) {
  const len1 = str1.length;
  const len2 = str2.length;
  const matrix = Array(len1 + 1).fill(null).map(() => Array(len2 + 1).fill(0));

  for (let i = 0; i <= len1; i++) matrix[i][0] = i;
  for (let j = 0; j <= len2; j++) matrix[0][j] = j;

  for (let i = 1; i <= len1; i++) {
    for (let j = 1; j <= len2; j++) {
      const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1,      // deletion
        matrix[i][j - 1] + 1,      // insertion
        matrix[i - 1][j - 1] + cost // substitution
      );
    }
  }

  return matrix[len1][len2];
}
```

**Usage Example:**
```javascript
// Fuzzy match state name
const result = fuzzyMatch("in prog", [
  "Backlog",
  "In Progress",
  "In Review",
  "Done"
]);
// Result: { match: "In Progress", confidence: 70, exactMatch: false, reason: "Contains match" }

// Fuzzy match with aliases
const typeResult = fuzzyMatch("bugfix", ["feat", "fix", "docs"], {
  aliases: {
    "bugfix": "fix",
    "feature": "feat",
    "documentation": "docs"
  }
});
// Result: { match: "fix", confidence: 100, exactMatch: true, reason: "Alias match" }
```

---

## Validation Functions

### 6. validateTransition

Validate workflow state transitions.

```javascript
/**
 * Validate if state transition is allowed
 * @param {string} fromState - Current state
 * @param {string} toState - Target state
 * @param {Object} stateMachine - State machine definition
 * @returns {Object} Validation result
 */
function validateTransition(fromState, toState, stateMachine) {
  const currentStateConfig = stateMachine[fromState];

  if (!currentStateConfig) {
    return {
      valid: false,
      confidence: 0,
      error: `Unknown state: ${fromState}`,
      suggestions: Object.keys(stateMachine)
    };
  }

  const allowedNextStates = currentStateConfig.next_states || [];

  if (!allowedNextStates.includes(toState)) {
    return {
      valid: false,
      confidence: 0,
      error: `Cannot transition from ${fromState} to ${toState}`,
      allowedStates: allowedNextStates,
      suggestions: allowedNextStates.map(s => `Try: ${s}`)
    };
  }

  return {
    valid: true,
    confidence: currentStateConfig.confidence_to_transition || 90
  };
}
```

---

## Pattern Matching Functions

### 7. Common Patterns

```javascript
// Issue ID pattern (PROJECT-NUMBER)
const ISSUE_ID_PATTERN = /^[A-Z]+-\d+$/;

function isIssueId(input) {
  return ISSUE_ID_PATTERN.test(input);
}

function detectIssueIdConfidence(input) {
  if (ISSUE_ID_PATTERN.test(input)) {
    return { confidence: 95, match: true };
  }

  // Partial match (e.g., "PSN" or "123")
  if (/^[A-Z]+$/.test(input) || /^\d+$/.test(input)) {
    return { confidence: 30, match: false, suggestion: 'Provide full issue ID (e.g., PSN-29)' };
  }

  return { confidence: 0, match: false };
}

// Quoted string pattern (for titles)
const QUOTED_STRING_PATTERN = /^["'].*["']$/;

function isQuotedString(input) {
  return QUOTED_STRING_PATTERN.test(input);
}

// Detect change type from update text
function detectChangeType(text) {
  const lower = text.toLowerCase();

  const patterns = {
    scope_change: /(add|also|include|plus|additionally|extra)/i,
    approach_change: /(instead|different|change|use.*not|replace.*with)/i,
    simplification: /(remove|don't need|skip|simpler|drop|omit)/i,
    blocker: /(blocked|can't|cannot|doesn't work|issue|problem|error)/i,
    clarification: /.*/  // Default
  };

  for (const [type, pattern] of Object.entries(patterns)) {
    if (pattern.test(lower) && type !== 'clarification') {
      return {
        type,
        confidence: 75,
        keywords: lower.match(pattern)
      };
    }
  }

  return {
    type: 'clarification',
    confidence: 50,
    keywords: []
  };
}
```

---

## Display Helpers

### 8. Confidence Display

```javascript
/**
 * Display confidence level with appropriate emoji and color
 * @param {number} confidence - Confidence score (0-100)
 * @param {string} message - Message to display
 */
function displayWithConfidence(confidence, message) {
  let emoji, prefix;

  if (confidence >= 95) {
    emoji = '✅';
    prefix = 'CERTAIN';
  } else if (confidence >= 80) {
    emoji = '✅';
    prefix = `HIGH (${confidence}%)`;
  } else if (confidence >= 50) {
    emoji = '⚠️';
    prefix = `MEDIUM (${confidence}%)`;
  } else {
    emoji = '❓';
    prefix = `LOW (${confidence}%)`;
  }

  console.log(`${emoji} ${prefix}: ${message}`);
}

/**
 * Display decision summary
 * @param {Object} decision - Decision result
 */
function displayDecision(decision) {
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🎯 Decision Summary');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  displayWithConfidence(decision.confidence, decision.suggestion || decision.action);

  if (decision.reasoning) {
    console.log(`\n📊 Reasoning: ${decision.reasoning}`);
  }

  if (decision.shouldAsk) {
    console.log(`\n👤 User input required`);
  } else {
    console.log(`\n🤖 Proceeding automatically`);
  }

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}
```

---

## Error Handling

### 9. Structured Error Messages

```javascript
/**
 * Create structured error with suggestions
 * @param {string} message - Error message
 * @param {Object} details - Error details
 * @param {Array} details.suggestions - Actionable suggestions
 * @param {Array} details.availableOptions - Available options
 * @returns {Error} Enhanced error object
 */
function createStructuredError(message, details = {}) {
  const error = new Error(message);
  error.details = details;

  // Format error message with suggestions
  let fullMessage = message;

  if (details.availableOptions && details.availableOptions.length > 0) {
    fullMessage += '\n\nAvailable options:';
    details.availableOptions.forEach(opt => {
      fullMessage += `\n  • ${opt}`;
    });
  }

  if (details.suggestions && details.suggestions.length > 0) {
    fullMessage += '\n\nSuggestions:';
    details.suggestions.forEach(suggestion => {
      fullMessage += `\n  • ${suggestion}`;
    });
  }

  error.message = fullMessage;
  return error;
}
```

---

## Integration Example

Complete example showing all helpers working together:

```javascript
// Example: Command routing with Always-Ask Policy
async function executeSmartPlan(args) {
  const arg1 = args[0];
  const arg2 = args[1];

  // Step 1: Detect mode with confidence
  const issueIdCheck = detectIssueIdConfidence(arg1);

  let modeDecision;
  if (issueIdCheck.match) {
    // High confidence: Issue ID pattern
    if (arg2) {
      modeDecision = {
        mode: 'UPDATE',
        confidence: 95,
        reasoning: 'Issue ID with update text provided'
      };
    } else {
      modeDecision = {
        mode: 'PLAN',
        confidence: 95,
        reasoning: 'Issue ID without update text'
      };
    }
  } else if (isQuotedString(arg1)) {
    // High confidence: Quoted title
    modeDecision = {
      mode: 'CREATE',
      confidence: 90,
      reasoning: 'Quoted string indicates new task title'
    };
  } else {
    // Low confidence: Ambiguous
    modeDecision = {
      mode: null,
      confidence: 30,
      reasoning: 'Input format is ambiguous'
    };
  }

  // Step 2: Check if we should ask
  const askDecision = shouldAsk(modeDecision.confidence);

  // Step 3: Ask user if needed
  if (askDecision.shouldAsk) {
    displayDecision({
      ...modeDecision,
      shouldAsk: true,
      action: `Detected input: "${arg1}"`
    });

    const mode = await askUserForClarification({
      question: "What would you like to do?",
      header: "Mode",
      options: [
        { label: "Create new", description: "Create new task with this title" },
        { label: "Plan existing", description: "Plan existing issue" },
        { label: "Update plan", description: "Update existing plan" }
      ],
      suggestion: modeDecision.mode,
      confidence: modeDecision.confidence
    });

    modeDecision.mode = mode.replace(' new', '').replace(' existing', '').replace(' plan', '');
  } else {
    // High confidence: Display and proceed
    displayWithConfidence(modeDecision.confidence, `Mode: ${modeDecision.mode}`);
  }

  // Step 4: Execute mode
  switch (modeDecision.mode.toUpperCase()) {
    case 'CREATE':
      await executeCreate(arg1, arg2);
      break;
    case 'PLAN':
      await executePlan(arg1);
      break;
    case 'UPDATE':
      await executeUpdate(arg1, arg2);
      break;
  }
}
```

---

## Best Practices

1. **Always calculate confidence** - Don't guess, use signals
2. **Display confidence scores** - Be transparent with users
3. **Provide reasoning** - Explain why confidence is at a level
4. **Ask with suggestions** - Pre-select high confidence options
5. **Validate early** - Catch errors before execution
6. **Use fuzzy matching** - Be forgiving with user input
7. **Log decisions** - Track accuracy over time
8. **Fail gracefully** - Provide actionable error messages

---

## Testing Helpers

```javascript
// Test confidence calculation
const testConfidence = calculateConfidence({
  input: "PSN-29",
  signals: {
    patternMatch: 100,
    contextMatch: 90,
    historicalSuccess: 95
  }
});
console.log('Confidence test:', testConfidence);

// Test fuzzy matching
const testMatch = fuzzyMatch("in prog", ["Backlog", "In Progress", "Done"]);
console.log('Fuzzy match test:', testMatch);

// Test should ask
const testAsk = shouldAsk(65);
console.log('Should ask test:', testAsk);
```

---

## Performance Characteristics

| Operation | Avg Time | Notes |
|-----------|----------|-------|
| calculateConfidence | <1ms | Synchronous calculation |
| shouldAsk | <1ms | Simple threshold check |
| askUserForClarification | Varies | Waits for user input |
| fuzzyMatch | 1-5ms | Depends on options count |
| displayOptionsAndConfirm | Varies | Waits for user input |

---

## Migration Guide

**Old Pattern (no confidence tracking)**:
```javascript
if (ISSUE_ID_PATTERN.test(arg1)) {
  mode = 'PLAN';
} else {
  mode = 'CREATE';
}
```

**New Pattern (with Always-Ask Policy)**:
```javascript
const issueIdCheck = detectIssueIdConfidence(arg1);
const decision = shouldAsk(issueIdCheck.confidence);

if (decision.shouldAsk) {
  mode = await askUserForClarification({ ... });
} else {
  displayWithConfidence(issueIdCheck.confidence, `Mode: ${mode}`);
}
```

---

## Related Documents

- [Decision Framework](../docs/architecture/decision-framework.md)
- [Decision Trees](../docs/architecture/decision-trees-visual.md)
- [Implementation Guide](../docs/guides/implementing-always-ask-policy.md)
- [Workflow State Tracking](./_shared-workflow-state.md)
