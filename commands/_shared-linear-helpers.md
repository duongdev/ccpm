# Shared Linear Integration Helpers

This file provides reusable utility functions for Linear integration across CCPM commands.

## Overview

These helper functions handle common Linear operations including:
- Label creation and retrieval
- Status/state ID validation and mapping
- Color standardization for CCPM workflow labels

**Usage in commands:** Reference this file at the start of command execution:
```markdown
READ: commands/_shared-linear-helpers.md
```

Then use the functions as described below.

---

## Functions

### 1. getOrCreateLabel

Retrieves an existing label or creates it if it doesn't exist.

```javascript
/**
 * Get existing label or create new one
 * @param {string} teamId - Linear team ID
 * @param {string} labelName - Label name to find or create
 * @param {Object} options - Optional configuration
 * @param {string} options.color - Hex color code (default: auto-assigned)
 * @param {string} options.description - Label description
 * @returns {Promise<Object>} Label object with id and name
 */
async function getOrCreateLabel(teamId, labelName, options = {}) {
  // Step 1: Search for existing label
  const existingLabels = await mcp__linear__list_issue_labels({
    team: teamId,
    name: labelName
  });

  // Step 2: Return if exists (case-insensitive match)
  const existing = existingLabels.find(
    label => label.name.toLowerCase() === labelName.toLowerCase()
  );

  if (existing) {
    return {
      id: existing.id,
      name: existing.name
    };
  }

  // Step 3: Create new label if not found
  const color = options.color || getDefaultColor(labelName);
  const description = options.description || `CCPM: ${labelName}`;

  console.log(`Creating new label: ${labelName} (${color})`);

  const newLabel = await mcp__linear__create_issue_label({
    name: labelName,
    teamId: teamId,
    color: color,
    description: description
  });

  return {
    id: newLabel.id,
    name: newLabel.name
  };
}
```

**Usage Example:**
```javascript
// Simple usage - auto color
const label = await getOrCreateLabel(teamId, "planning");

// With custom options
const label = await getOrCreateLabel(teamId, "high-priority", {
  color: "#eb5757",
  description: "High priority tasks"
});
```

---

### 2. getValidStateId

Validates and resolves state names/types to valid Linear state IDs.

```javascript
/**
 * Get valid Linear state ID from state name or type
 * @param {string} teamId - Linear team ID
 * @param {string} stateNameOrType - State name (e.g., "In Progress") or type (e.g., "started")
 * @returns {Promise<string>} Valid state ID
 * @throws {Error} If no matching state found
 */
async function getValidStateId(teamId, stateNameOrType) {
  // Step 1: Fetch all workflow states for team
  const states = await mcp__linear__list_issue_statuses({
    team: teamId
  });

  if (!states || states.length === 0) {
    throw new Error(`No workflow states found for team ${teamId}`);
  }

  const input = stateNameOrType.toLowerCase().trim();

  // Step 2: Try exact name match (case-insensitive)
  let match = states.find(s => s.name.toLowerCase() === input);
  if (match) return match.id;

  // Step 3: Try type match
  match = states.find(s => s.type.toLowerCase() === input);
  if (match) return match.id;

  // Step 4: Try fallback mapping for common state names
  const fallbackMap = {
    'backlog': 'backlog',
    'todo': 'unstarted',
    'planning': 'unstarted',
    'ready': 'unstarted',
    'in progress': 'started',
    'in review': 'started',
    'reviewing': 'started',
    'testing': 'started',
    'done': 'completed',
    'completed': 'completed',
    'finished': 'completed',
    'canceled': 'canceled',
    'cancelled': 'canceled',
    'blocked': 'canceled'
  };

  const mappedType = fallbackMap[input];
  if (mappedType) {
    match = states.find(s => s.type.toLowerCase() === mappedType);
    if (match) return match.id;
  }

  // Step 5: Partial name match (contains)
  match = states.find(s => s.name.toLowerCase().includes(input));
  if (match) return match.id;

  // Step 6: No match found - throw helpful error
  const availableStates = states.map(s => `  - ${s.name} (type: ${s.type})`).join('\n');
  throw new Error(
    `Invalid state: "${stateNameOrType}"\n\n` +
    `Available states for this team:\n${availableStates}\n\n` +
    `Tip: Use state name (e.g., "In Progress") or type (e.g., "started")`
  );
}
```

**Usage Example:**
```javascript
// By state name
const stateId = await getValidStateId(teamId, "In Progress");

// By state type
const stateId = await getValidStateId(teamId, "started");

// Common aliases work too
const stateId = await getValidStateId(teamId, "todo"); // Maps to "unstarted" type
```

---

### 3. ensureLabelsExist

Ensures multiple labels exist, creating them if needed.

```javascript
/**
 * Ensure multiple labels exist, creating missing ones
 * @param {string} teamId - Linear team ID
 * @param {string[]} labelNames - Array of label names
 * @param {Object} options - Optional configuration
 * @param {Object} options.colors - Map of label names to color codes
 * @param {Object} options.descriptions - Map of label names to descriptions
 * @returns {Promise<string[]>} Array of label names (guaranteed to exist)
 */
async function ensureLabelsExist(teamId, labelNames, options = {}) {
  const colors = options.colors || {};
  const descriptions = options.descriptions || {};
  const results = [];

  // Process labels sequentially to avoid rate limits
  for (const labelName of labelNames) {
    const labelOptions = {
      color: colors[labelName],
      description: descriptions[labelName]
    };

    const label = await getOrCreateLabel(teamId, labelName, labelOptions);
    results.push(label.name);
  }

  return results;
}
```

**Usage Example:**
```javascript
// Simple usage - auto colors
const labels = await ensureLabelsExist(teamId, [
  "planning",
  "implementation",
  "verification"
]);

// With custom colors and descriptions
const labels = await ensureLabelsExist(teamId,
  ["bug", "feature", "epic"],
  {
    colors: {
      bug: "#eb5757",
      feature: "#bb87fc"
    },
    descriptions: {
      bug: "Bug fix required",
      feature: "New feature implementation"
    }
  }
);
```

---

### 4. getDefaultColor

Returns standardized hex color codes for CCPM workflow labels.

```javascript
/**
 * Get default color for common CCPM labels
 * @param {string} labelName - Label name (case-insensitive)
 * @returns {string} Hex color code (with #)
 */
function getDefaultColor(labelName) {
  const colorMap = {
    // CCPM Workflow stages
    'planning': '#f7c8c1',           // Light coral
    'implementation': '#26b5ce',      // Cyan
    'verification': '#f2c94c',        // Yellow
    'pr-review': '#5e6ad2',          // Indigo
    'done': '#4cb782',               // Green
    'approved': '#4cb782',           // Green

    // Issue types
    'bug': '#eb5757',                // Red
    'feature': '#bb87fc',            // Purple
    'epic': '#f7c8c1',               // Light coral
    'task': '#26b5ce',               // Cyan
    'improvement': '#4ea7fc',        // Blue

    // Status indicators
    'blocked': '#eb5757',            // Red
    'research': '#26b5ce',           // Cyan
    'research-complete': '#26b5ce',  // Cyan

    // Priority labels
    'critical': '#eb5757',           // Red
    'high-priority': '#f2994a',      // Orange
    'low-priority': '#95a2b3',       // Gray

    // Technical areas
    'backend': '#26b5ce',            // Cyan
    'frontend': '#bb87fc',           // Purple
    'database': '#4ea7fc',           // Blue
    'api': '#26b5ce',                // Cyan
    'security': '#eb5757',           // Red
    'performance': '#f2c94c',        // Yellow
    'testing': '#4cb782',            // Green
    'documentation': '#95a2b3'       // Gray
  };

  const normalized = labelName.toLowerCase().trim();
  return colorMap[normalized] || '#95a2b3'; // Default gray
}
```

**Usage Example:**
```javascript
// Get color for standard label
const color = getDefaultColor("planning"); // Returns "#f7c8c1"

// Unknown labels get gray
const color = getDefaultColor("custom-label"); // Returns "#95a2b3"

// Case-insensitive
const color = getDefaultColor("FEATURE"); // Returns "#bb87fc"
```

---

## Error Handling Patterns

### Graceful Label Creation
```javascript
try {
  const label = await getOrCreateLabel(teamId, "planning");
  // Proceed with label.id
} catch (error) {
  console.error("Failed to create/get label:", error);
  // Decide: fail task or continue without label
  throw new Error(`Linear label operation failed: ${error.message}`);
}
```

### State Validation with Helpful Messages
```javascript
try {
  const stateId = await getValidStateId(teamId, "In Progress");
  // Use stateId
} catch (error) {
  // Error already includes helpful message with available states
  console.error(error.message);
  throw error; // Re-throw to halt command
}
```

### Batch Label Creation
```javascript
try {
  const labels = await ensureLabelsExist(teamId, [
    "planning",
    "implementation",
    "verification"
  ]);
  console.log(`Labels ready: ${labels.join(", ")}`);
} catch (error) {
  console.error("Failed to ensure labels exist:", error);
  // Decide: fail or continue with partial labels
  throw error;
}
```

---

## Integration Examples

### Example 1: Creating Issue with Labels and State
```javascript
// Read this file for helpers
// READ: commands/_shared-linear-helpers.md

// Ensure workflow labels exist
const labels = await ensureLabelsExist(teamId, [
  "planning",
  "backend",
  "high-priority"
]);

// Get valid state ID
const stateId = await getValidStateId(teamId, "In Progress");

// Create issue with labels and state
const issue = await mcp__linear__create_issue({
  teamId: teamId,
  title: "Implement user authentication",
  description: "...",
  stateId: stateId,
  labelIds: labels // Use label names directly
});
```

### Example 2: Updating Issue Status
```javascript
// Get correct state ID using fuzzy matching
const completedStateId = await getValidStateId(teamId, "done");

// Update issue
await mcp__linear__update_issue({
  id: issueId,
  stateId: completedStateId
});
```

### Example 3: Conditional Label Creation
```javascript
// Create label only if needed
const shouldAddPriorityLabel = isUrgent;

if (shouldAddPriorityLabel) {
  await getOrCreateLabel(teamId, "high-priority", {
    color: "#f2994a",
    description: "Requires immediate attention"
  });
}
```

---

## State Type Reference

Linear workflow state types:
- **backlog**: Issue is in backlog, not yet planned
- **unstarted**: Planned but not started (Todo, Ready)
- **started**: Actively being worked on (In Progress, In Review)
- **completed**: Successfully finished (Done, Deployed)
- **canceled**: Closed without completion (Canceled, Blocked)

---

## Color Palette Reference

CCPM standard colors:
- **Workflow**: Coral (#f7c8c1), Cyan (#26b5ce), Yellow (#f2c94c), Green (#4cb782)
- **Priority**: Red (#eb5757), Orange (#f2994a), Gray (#95a2b3)
- **Types**: Purple (#bb87fc), Blue (#4ea7fc), Indigo (#5e6ad2)

---

## Best Practices

1. **Always validate state IDs** before creating/updating issues
2. **Reuse existing labels** instead of creating duplicates
3. **Use consistent colors** from `getDefaultColor()` for visual clarity
4. **Handle errors gracefully** with helpful messages
5. **Batch label operations** when creating multiple labels
6. **Log label creation** for debugging and transparency
7. **Use case-insensitive matching** for better UX

---

## Testing Helpers

To test these functions in isolation:

```javascript
// Test label creation
const label = await getOrCreateLabel("TEAM-123", "test-label");
console.log("Created/found label:", label);

// Test state validation
try {
  const stateId = await getValidStateId("TEAM-123", "invalid-state");
} catch (error) {
  console.log("Expected error:", error.message);
}

// Test batch labels
const labels = await ensureLabelsExist("TEAM-123", [
  "label1",
  "label2",
  "label3"
]);
console.log("All labels exist:", labels);

// Test color lookup
console.log("Planning color:", getDefaultColor("planning"));
console.log("Unknown color:", getDefaultColor("random"));
```

---

## Migration Guide

For existing commands using hardcoded label/state logic:

**Before:**
```javascript
// Hardcoded state ID (breaks if workflow changes)
const stateId = "state_12345";

// Manual label creation without checking existence
await mcp__linear__create_issue_label({name: "planning", teamId});
```

**After:**
```javascript
// READ: commands/_shared-linear-helpers.md

// Resilient state resolution
const stateId = await getValidStateId(teamId, "In Progress");

// Automatic label reuse
const label = await getOrCreateLabel(teamId, "planning");
```

---

## Performance Considerations

- **Caching**: Consider caching label lookups within a command execution
- **Batch operations**: Use `ensureLabelsExist()` for multiple labels
- **Sequential processing**: Labels created one-by-one to respect rate limits
- **Error handling**: Fast-fail on invalid states to avoid wasted API calls

---

## Maintenance

When updating these helpers:
1. Test changes with real Linear API
2. Update usage examples in this file
3. Search for usage in commands: `grep -r "getOrCreateLabel" commands/`
4. Update affected commands if function signatures change
5. Document breaking changes in CHANGELOG.md
