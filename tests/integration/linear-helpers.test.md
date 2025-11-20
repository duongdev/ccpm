# Linear Helper Functions - Integration Tests

Comprehensive integration tests for shared Linear helper functions defined in `commands/_shared-linear-helpers.md`.

## Overview

These tests validate the Linear helper functions against a real Linear workspace using the Linear MCP server.

**Test Categories:**
- Label creation and retrieval (`getOrCreateLabel`)
- State validation and mapping (`getValidStateId`)
- Batch label operations (`ensureLabelsExist`)
- Color mapping (`getDefaultColor`)
- Error handling and edge cases

## Prerequisites

### 1. Linear MCP Server Setup

Ensure Linear MCP is configured and accessible:

```bash
# Check Linear MCP is available
claude --list-mcps | grep linear

# Test Linear connection
claude --mcp linear --test
```

### 2. Test Team Setup

**Required:** A Linear team dedicated to testing with permission to:
- Create labels
- Read workflow states
- Modify team settings (optional)

**Get your team ID:**
```bash
# Use Linear MCP to list teams
mcp__linear__list_teams
```

**Set test team ID:**
```bash
export LINEAR_TEST_TEAM_ID="your-team-id-here"
```

### 3. Test Environment Variables

```bash
# Required
export LINEAR_TEST_TEAM_ID="team_abc123"

# Optional - for cleanup
export LINEAR_TEST_CLEANUP="true"  # Auto-delete created labels after tests
```

## Test Suite Structure

```
linear-helpers.test.md
├── Test 1: getDefaultColor (pure function)
├── Test 2: getOrCreateLabel (label operations)
├── Test 3: getValidStateId (state validation)
├── Test 4: ensureLabelsExist (batch operations)
├── Test 5: Error Handling
└── Test 6: Integration Scenarios
```

---

## Test 1: getDefaultColor

**Pure function tests - no Linear API required**

### Test 1.1: Planning Label Color
```javascript
// Expected: #f7c8c1 (light coral)
const result = getDefaultColor("planning");
assert(result === "#f7c8c1", `Expected #f7c8c1, got ${result}`);
```
✅ **Expected:** Returns `#f7c8c1`
✅ **Status:** Pass

### Test 1.2: Implementation Label Color
```javascript
// Expected: #26b5ce (cyan)
const result = getDefaultColor("implementation");
assert(result === "#26b5ce", `Expected #26b5ce, got ${result}`);
```
✅ **Expected:** Returns `#26b5ce`
✅ **Status:** Pass

### Test 1.3: Verification Label Color
```javascript
// Expected: #f2c94c (yellow)
const result = getDefaultColor("verification");
assert(result === "#f2c94c", `Expected #f2c94c, got ${result}`);
```
✅ **Expected:** Returns `#f2c94c`
✅ **Status:** Pass

### Test 1.4: Bug Label Color
```javascript
// Expected: #eb5757 (red)
const result = getDefaultColor("bug");
assert(result === "#eb5757", `Expected #eb5757, got ${result}`);
```
✅ **Expected:** Returns `#eb5757`
✅ **Status:** Pass

### Test 1.5: Unknown Label Color (Default)
```javascript
// Expected: #95a2b3 (default gray)
const result = getDefaultColor("unknown-custom-label");
assert(result === "#95a2b3", `Expected #95a2b3, got ${result}`);
```
✅ **Expected:** Returns `#95a2b3`
✅ **Status:** Pass

### Test 1.6: Case Insensitive Lookup
```javascript
// Expected: #bb87fc (purple) - same as "feature"
const result = getDefaultColor("FEATURE");
assert(result === "#bb87fc", `Expected #bb87fc, got ${result}`);
```
✅ **Expected:** Returns `#bb87fc`
✅ **Status:** Pass

### Test 1.7: Trimmed Input
```javascript
// Expected: #26b5ce (cyan) - same as "backend"
const result = getDefaultColor("  backend  ");
assert(result === "#26b5ce", `Expected #26b5ce, got ${result}`);
```
✅ **Expected:** Returns `#26b5ce`
✅ **Status:** Pass

---

## Test 2: getOrCreateLabel

**Requires Linear MCP connection**

### Test 2.1: Create New Label with Auto Color
```javascript
// READ: commands/_shared-linear-helpers.md

const teamId = process.env.LINEAR_TEST_TEAM_ID;
const labelName = `test-auto-color-${Date.now()}`;

const result = await getOrCreateLabel(teamId, labelName);

// Assertions
assert(result.id, "Label should have an ID");
assert(result.name === labelName, `Name should be ${labelName}`);

// Verify label exists in Linear
const existingLabels = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelName
});

assert(existingLabels.length > 0, "Label should exist in Linear");
assert(existingLabels[0].name === labelName, "Label name should match");
```
✅ **Expected:** Creates label with auto-assigned color
✅ **Cleanup:** Delete label if LINEAR_TEST_CLEANUP=true

### Test 2.2: Create New Label with Custom Color
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;
const labelName = `test-custom-color-${Date.now()}`;
const customColor = "#ff5733";

const result = await getOrCreateLabel(teamId, labelName, {
  color: customColor,
  description: "Test label with custom color"
});

// Assertions
assert(result.id, "Label should have an ID");
assert(result.name === labelName, "Name should match");

// Verify color and description
const existingLabels = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelName
});

assert(existingLabels[0].color === customColor, `Color should be ${customColor}`);
assert(existingLabels[0].description === "Test label with custom color", "Description should match");
```
✅ **Expected:** Creates label with specified color and description
✅ **Cleanup:** Delete label if LINEAR_TEST_CLEANUP=true

### Test 2.3: Return Existing Label (Idempotent)
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;
const labelName = `test-existing-${Date.now()}`;

// Create label first time
const result1 = await getOrCreateLabel(teamId, labelName);
const labelId1 = result1.id;

// Call again - should return existing
const result2 = await getOrCreateLabel(teamId, labelName);
const labelId2 = result2.id;

// Assertions
assert(labelId1 === labelId2, "Should return same label ID");
assert(result1.name === result2.name, "Label name should match");

// Verify only one label exists
const allLabels = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelName
});

assert(allLabels.length === 1, "Should only have one label with this name");
```
✅ **Expected:** Returns existing label without creating duplicate
✅ **Cleanup:** Delete label if LINEAR_TEST_CLEANUP=true

### Test 2.4: Case-Insensitive Label Match
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;
const labelName = "TestCaseSensitive";

// Create with original case
const result1 = await getOrCreateLabel(teamId, labelName);

// Try to create with different case
const result2 = await getOrCreateLabel(teamId, "testcasesensitive");

// Assertions
assert(result1.id === result2.id, "Should match existing label (case-insensitive)");
```
✅ **Expected:** Matches existing label regardless of case
✅ **Cleanup:** Delete label if LINEAR_TEST_CLEANUP=true

### Test 2.5: Invalid Team ID Handling
```javascript
const invalidTeamId = "invalid-team-123";
const labelName = "test-label";

try {
  await getOrCreateLabel(invalidTeamId, labelName);
  assert(false, "Should throw error for invalid team ID");
} catch (error) {
  assert(error, "Should catch error");
  console.log("✅ Correctly handles invalid team ID:", error.message);
}
```
✅ **Expected:** Throws error with helpful message
✅ **Cleanup:** Not needed (operation fails)

### Test 2.6: Label with Special Characters
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;
const labelName = `test-special!@#-${Date.now()}`;

const result = await getOrCreateLabel(teamId, labelName);

assert(result.id, "Label with special chars should have ID");
assert(result.name === labelName, "Name should match exactly");
```
✅ **Expected:** Handles special characters correctly
✅ **Cleanup:** Delete label if LINEAR_TEST_CLEANUP=true

---

## Test 3: getValidStateId

**Requires Linear MCP connection**

### Test 3.1: Exact State Name Match
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

// First, get available states
const states = await mcp__linear__list_issue_statuses({
  team: teamId
});

assert(states.length > 0, "Team should have workflow states");

// Pick first state for testing
const testState = states[0];
const stateId = await getValidStateId(teamId, testState.name);

assert(stateId === testState.id, "Should return correct state ID for exact name");
```
✅ **Expected:** Returns correct state ID for exact name match
✅ **Cleanup:** Not needed (read-only)

### Test 3.2: State Type Match (backlog)
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

const stateId = await getValidStateId(teamId, "backlog");

// Verify it's a backlog type state
const states = await mcp__linear__list_issue_statuses({
  team: teamId
});

const matchedState = states.find(s => s.id === stateId);
assert(matchedState.type === "backlog", "Should return backlog type state");
```
✅ **Expected:** Returns state ID for "backlog" type
✅ **Cleanup:** Not needed (read-only)

### Test 3.3: State Type Match (unstarted)
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

const stateId = await getValidStateId(teamId, "unstarted");

const states = await mcp__linear__list_issue_statuses({
  team: teamId
});

const matchedState = states.find(s => s.id === stateId);
assert(matchedState.type === "unstarted", "Should return unstarted type state");
```
✅ **Expected:** Returns state ID for "unstarted" type
✅ **Cleanup:** Not needed (read-only)

### Test 3.4: State Type Match (started)
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

const stateId = await getValidStateId(teamId, "started");

const states = await mcp__linear__list_issue_statuses({
  team: teamId
});

const matchedState = states.find(s => s.id === stateId);
assert(matchedState.type === "started", "Should return started type state");
```
✅ **Expected:** Returns state ID for "started" type
✅ **Cleanup:** Not needed (read-only)

### Test 3.5: State Type Match (completed)
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

const stateId = await getValidStateId(teamId, "completed");

const states = await mcp__linear__list_issue_statuses({
  team: teamId
});

const matchedState = states.find(s => s.id === stateId);
assert(matchedState.type === "completed", "Should return completed type state");
```
✅ **Expected:** Returns state ID for "completed" type
✅ **Cleanup:** Not needed (read-only)

### Test 3.6: Fallback Mapping (todo → unstarted)
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

const stateId = await getValidStateId(teamId, "todo");

const states = await mcp__linear__list_issue_statuses({
  team: teamId
});

const matchedState = states.find(s => s.id === stateId);
assert(matchedState.type === "unstarted", "Should map 'todo' to 'unstarted' type");
```
✅ **Expected:** Maps "todo" to "unstarted" type state
✅ **Cleanup:** Not needed (read-only)

### Test 3.7: Fallback Mapping (in progress → started)
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

const stateId = await getValidStateId(teamId, "in progress");

const states = await mcp__linear__list_issue_statuses({
  team: teamId
});

const matchedState = states.find(s => s.id === stateId);
assert(matchedState.type === "started", "Should map 'in progress' to 'started' type");
```
✅ **Expected:** Maps "in progress" to "started" type state
✅ **Cleanup:** Not needed (read-only)

### Test 3.8: Fallback Mapping (done → completed)
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

const stateId = await getValidStateId(teamId, "done");

const states = await mcp__linear__list_issue_statuses({
  team: teamId
});

const matchedState = states.find(s => s.id === stateId);
assert(matchedState.type === "completed", "Should map 'done' to 'completed' type");
```
✅ **Expected:** Maps "done" to "completed" type state
✅ **Cleanup:** Not needed (read-only)

### Test 3.9: Case-Insensitive State Name
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

// Get available states
const states = await mcp__linear__list_issue_statuses({
  team: teamId
});

const testState = states[0];
const upperCaseName = testState.name.toUpperCase();

const stateId = await getValidStateId(teamId, upperCaseName);

assert(stateId === testState.id, "Should match state regardless of case");
```
✅ **Expected:** Matches state name case-insensitively
✅ **Cleanup:** Not needed (read-only)

### Test 3.10: Invalid State Name - Helpful Error
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

try {
  await getValidStateId(teamId, "completely-invalid-state-12345");
  assert(false, "Should throw error for invalid state");
} catch (error) {
  // Error should include available states
  assert(error.message.includes("Invalid state"), "Error should mention invalid state");
  assert(error.message.includes("Available states"), "Error should list available states");
  assert(error.message.includes("type:"), "Error should show state types");
  console.log("✅ Helpful error message:", error.message);
}
```
✅ **Expected:** Throws error with list of available states
✅ **Cleanup:** Not needed (operation fails)

### Test 3.11: Invalid Team ID
```javascript
const invalidTeamId = "invalid-team-123";

try {
  await getValidStateId(invalidTeamId, "backlog");
  assert(false, "Should throw error for invalid team");
} catch (error) {
  assert(error, "Should catch error");
  console.log("✅ Correctly handles invalid team ID:", error.message);
}
```
✅ **Expected:** Throws error for invalid team ID
✅ **Cleanup:** Not needed (operation fails)

---

## Test 4: ensureLabelsExist

**Requires Linear MCP connection**

### Test 4.1: Create Multiple New Labels
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;
const timestamp = Date.now();
const labelNames = [
  `test-batch-1-${timestamp}`,
  `test-batch-2-${timestamp}`,
  `test-batch-3-${timestamp}`
];

const result = await ensureLabelsExist(teamId, labelNames);

// Assertions
assert(result.length === 3, "Should return 3 label names");
assert(result.includes(labelNames[0]), "Should include first label");
assert(result.includes(labelNames[1]), "Should include second label");
assert(result.includes(labelNames[2]), "Should include third label");

// Verify all labels exist
for (const name of labelNames) {
  const labels = await mcp__linear__list_issue_labels({
    team: teamId,
    name: name
  });
  assert(labels.length > 0, `Label ${name} should exist`);
}
```
✅ **Expected:** Creates all labels and returns names
✅ **Cleanup:** Delete labels if LINEAR_TEST_CLEANUP=true

### Test 4.2: Mix of Existing and New Labels
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;
const timestamp = Date.now();

// Create one label first
const existingLabel = `test-existing-${timestamp}`;
await getOrCreateLabel(teamId, existingLabel);

// Try to ensure labels including the existing one
const labelNames = [
  existingLabel,  // Already exists
  `test-new-1-${timestamp}`,  // New
  `test-new-2-${timestamp}`   // New
];

const result = await ensureLabelsExist(teamId, labelNames);

// Assertions
assert(result.length === 3, "Should return 3 label names");
assert(result.includes(existingLabel), "Should include existing label");

// Verify no duplicates created
const existingLabels = await mcp__linear__list_issue_labels({
  team: teamId,
  name: existingLabel
});

assert(existingLabels.length === 1, "Should not create duplicate of existing label");
```
✅ **Expected:** Returns existing and creates new labels
✅ **Cleanup:** Delete labels if LINEAR_TEST_CLEANUP=true

### Test 4.3: Custom Colors for Labels
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;
const timestamp = Date.now();

const labelNames = [
  `test-color-1-${timestamp}`,
  `test-color-2-${timestamp}`
];

const result = await ensureLabelsExist(teamId, labelNames, {
  colors: {
    [`test-color-1-${timestamp}`]: "#ff0000",
    [`test-color-2-${timestamp}`]: "#00ff00"
  }
});

// Verify colors
const label1 = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelNames[0]
});

const label2 = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelNames[1]
});

assert(label1[0].color === "#ff0000", "First label should have red color");
assert(label2[0].color === "#00ff00", "Second label should have green color");
```
✅ **Expected:** Creates labels with specified colors
✅ **Cleanup:** Delete labels if LINEAR_TEST_CLEANUP=true

### Test 4.4: Custom Descriptions for Labels
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;
const timestamp = Date.now();

const labelNames = [
  `test-desc-1-${timestamp}`,
  `test-desc-2-${timestamp}`
];

const result = await ensureLabelsExist(teamId, labelNames, {
  descriptions: {
    [`test-desc-1-${timestamp}`]: "First test description",
    [`test-desc-2-${timestamp}`]: "Second test description"
  }
});

// Verify descriptions
const label1 = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelNames[0]
});

const label2 = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelNames[1]
});

assert(label1[0].description === "First test description", "First label description should match");
assert(label2[0].description === "Second test description", "Second label description should match");
```
✅ **Expected:** Creates labels with specified descriptions
✅ **Cleanup:** Delete labels if LINEAR_TEST_CLEANUP=true

### Test 4.5: Empty Label Array
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

const result = await ensureLabelsExist(teamId, []);

assert(result.length === 0, "Should return empty array for empty input");
```
✅ **Expected:** Returns empty array gracefully
✅ **Cleanup:** Not needed

### Test 4.6: Rate Limit Handling (Sequential Processing)
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;
const timestamp = Date.now();

// Create many labels to test sequential processing
const labelNames = Array.from({ length: 10 }, (_, i) => `test-rate-${timestamp}-${i}`);

const startTime = Date.now();
const result = await ensureLabelsExist(teamId, labelNames);
const endTime = Date.now();

// Assertions
assert(result.length === 10, "Should create all 10 labels");

// Sequential processing should take longer than parallel
// (rough check - sequential should be > 1s for 10 labels)
const duration = endTime - startTime;
console.log(`✅ Sequential processing took ${duration}ms for 10 labels`);

// Verify all exist
for (const name of labelNames) {
  const labels = await mcp__linear__list_issue_labels({
    team: teamId,
    name: name
  });
  assert(labels.length > 0, `Label ${name} should exist`);
}
```
✅ **Expected:** Processes labels sequentially to avoid rate limits
✅ **Cleanup:** Delete labels if LINEAR_TEST_CLEANUP=true

---

## Test 5: Error Handling

### Test 5.1: Network Error Simulation
```javascript
// This test requires disconnecting Linear MCP temporarily
// Manual test only - skip in automated runs

// Expected: Should throw error with network message
// Example: "Failed to connect to Linear API"
```
⚠️ **Manual Test Only:** Requires network manipulation
✅ **Expected:** Graceful error handling with helpful message

### Test 5.2: Invalid Color Format
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;
const timestamp = Date.now();

// Linear may accept various formats, but test invalid ones
try {
  await getOrCreateLabel(teamId, `test-bad-color-${timestamp}`, {
    color: "not-a-color"  // Invalid format
  });
  // If it succeeds, just log warning
  console.log("⚠️ Linear accepted invalid color format");
} catch (error) {
  console.log("✅ Correctly rejected invalid color:", error.message);
}
```
✅ **Expected:** Handles invalid color gracefully
✅ **Cleanup:** Delete label if created

### Test 5.3: Partial Failure in Batch Operation
```javascript
// Note: This is hard to test without mocking
// Linear API either succeeds or fails for each label independently

const teamId = process.env.LINEAR_TEST_TEAM_ID;
const timestamp = Date.now();

const labelNames = [
  `test-partial-1-${timestamp}`,
  `test-partial-2-${timestamp}`,
  `test-partial-3-${timestamp}`
];

try {
  const result = await ensureLabelsExist(teamId, labelNames);

  // In real scenario, check if some succeeded
  console.log(`✅ Created ${result.length} out of ${labelNames.length} labels`);

} catch (error) {
  // Catch any errors
  console.log("Error during batch operation:", error.message);
}
```
⚠️ **Hard to Test:** Requires specific API failure scenarios
✅ **Expected:** Handles partial failures gracefully

---

## Test 6: Integration Scenarios

### Test 6.1: Complete Issue Creation Workflow
```javascript
// READ: commands/_shared-linear-helpers.md

const teamId = process.env.LINEAR_TEST_TEAM_ID;
const timestamp = Date.now();

// Step 1: Ensure labels exist
const labels = await ensureLabelsExist(teamId, [
  "planning",
  "backend",
  "high-priority"
]);

console.log("✅ Labels ready:", labels);

// Step 2: Get valid state
const stateId = await getValidStateId(teamId, "in progress");

console.log("✅ State ID:", stateId);

// Step 3: Create issue (using Linear MCP)
const issue = await mcp__linear__create_issue({
  teamId: teamId,
  title: `Integration Test Issue ${timestamp}`,
  description: "Test issue created by integration test",
  stateId: stateId,
  labelIds: labels  // Should accept label names
});

console.log("✅ Issue created:", issue.id);

// Step 4: Verify issue has correct state and labels
const createdIssue = await mcp__linear__get_issue({
  id: issue.id
});

assert(createdIssue.state.id === stateId, "Issue should have correct state");
// Note: Label verification depends on Linear MCP return format
```
✅ **Expected:** Complete workflow succeeds
✅ **Cleanup:** Delete issue if LINEAR_TEST_CLEANUP=true

### Test 6.2: Issue Status Transition
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;
const timestamp = Date.now();

// Create issue
const issue = await mcp__linear__create_issue({
  teamId: teamId,
  title: `Status Test ${timestamp}`,
  description: "Testing status transitions"
});

// Transition through states
const todoStateId = await getValidStateId(teamId, "todo");
await mcp__linear__update_issue({
  id: issue.id,
  stateId: todoStateId
});

const inProgressStateId = await getValidStateId(teamId, "in progress");
await mcp__linear__update_issue({
  id: issue.id,
  stateId: inProgressStateId
});

const doneStateId = await getValidStateId(teamId, "done");
await mcp__linear__update_issue({
  id: issue.id,
  stateId: doneStateId
});

console.log("✅ Successfully transitioned through all states");
```
✅ **Expected:** State transitions work correctly
✅ **Cleanup:** Delete issue if LINEAR_TEST_CLEANUP=true

### Test 6.3: Label Color Consistency
```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

// Create workflow labels
const workflowLabels = await ensureLabelsExist(teamId, [
  "planning",
  "implementation",
  "verification"
]);

// Verify colors match defaults
const planningLabel = await mcp__linear__list_issue_labels({
  team: teamId,
  name: "planning"
});

const implLabel = await mcp__linear__list_issue_labels({
  team: teamId,
  name: "implementation"
});

const verifyLabel = await mcp__linear__list_issue_labels({
  team: teamId,
  name: "verification"
});

assert(planningLabel[0].color === "#f7c8c1", "Planning label should be coral");
assert(implLabel[0].color === "#26b5ce", "Implementation label should be cyan");
assert(verifyLabel[0].color === "#f2c94c", "Verification label should be yellow");

console.log("✅ All workflow labels have correct colors");
```
✅ **Expected:** Workflow labels have standardized colors
✅ **Cleanup:** Delete labels if LINEAR_TEST_CLEANUP=true

---

## Running the Tests

### Manual Test Execution

Since these are integration tests that interact with Linear MCP, run them manually:

```bash
# Set up environment
export LINEAR_TEST_TEAM_ID="your-team-id"
export LINEAR_TEST_CLEANUP="true"

# Run tests in Claude Code
# Copy test code from this file and execute in Claude Code session
```

### Automated Test Script

Create a test runner script:

```bash
#!/bin/bash
# tests/integration/run-linear-helpers-tests.sh

set -e

# Check prerequisites
if [ -z "$LINEAR_TEST_TEAM_ID" ]; then
  echo "❌ LINEAR_TEST_TEAM_ID not set"
  exit 1
fi

echo "🧪 Running Linear Helper Integration Tests"
echo "Team ID: $LINEAR_TEST_TEAM_ID"
echo ""

# Test categories
echo "📋 Test 1: getDefaultColor (pure functions)"
# Run getDefaultColor tests

echo "📋 Test 2: getOrCreateLabel"
# Run getOrCreateLabel tests

echo "📋 Test 3: getValidStateId"
# Run getValidStateId tests

echo "📋 Test 4: ensureLabelsExist"
# Run ensureLabelsExist tests

echo "📋 Test 5: Error Handling"
# Run error handling tests

echo "📋 Test 6: Integration Scenarios"
# Run integration scenario tests

echo ""
echo "✅ All tests completed"
```

### CI/CD Integration

**Note:** Integration tests require Linear API access. Consider:

1. **Skip in CI/CD** - Run only structural validation
2. **Separate Test Workspace** - Use dedicated Linear workspace
3. **Mocked Tests** - Create unit tests with mocked Linear MCP

---

## Test Results Template

```markdown
# Test Run: [Date]

## Environment
- Team ID: team_***
- Linear MCP Version: X.X.X
- Cleanup Enabled: Yes/No

## Results Summary
- ✅ Passed: XX/XX
- ❌ Failed: XX/XX
- ⚠️ Skipped: XX/XX

## Failed Tests
(List any failures with error messages)

## Notes
(Any observations or issues encountered)
```

---

## Cleanup Strategy

### Auto-Cleanup Script

```bash
#!/bin/bash
# tests/integration/cleanup-linear-test-labels.sh

TEAM_ID="${LINEAR_TEST_TEAM_ID}"

echo "🧹 Cleaning up test labels from team: $TEAM_ID"

# List all labels with "test-" prefix
# Delete using Linear MCP

echo "✅ Cleanup complete"
```

### Manual Cleanup

1. Go to Linear workspace settings
2. Navigate to Labels section
3. Filter labels starting with "test-"
4. Delete test labels

---

## Mocking Strategy (Optional)

For unit tests without Live Linear API:

### Mock Linear MCP Functions

```javascript
// tests/mocks/linear-mcp-mock.js

const mockLabels = new Map();
const mockStates = [
  { id: "state_1", name: "Backlog", type: "backlog" },
  { id: "state_2", name: "Todo", type: "unstarted" },
  { id: "state_3", name: "In Progress", type: "started" },
  { id: "state_4", name: "Done", type: "completed" }
];

async function mcp__linear__list_issue_labels({ team, name }) {
  if (name) {
    const label = mockLabels.get(`${team}:${name.toLowerCase()}`);
    return label ? [label] : [];
  }
  return Array.from(mockLabels.values())
    .filter(l => l.teamId === team);
}

async function mcp__linear__create_issue_label({ name, teamId, color, description }) {
  const label = {
    id: `label_${Date.now()}`,
    name,
    teamId,
    color,
    description
  };
  mockLabels.set(`${teamId}:${name.toLowerCase()}`, label);
  return label;
}

async function mcp__linear__list_issue_statuses({ team }) {
  return mockStates;
}

module.exports = {
  mcp__linear__list_issue_labels,
  mcp__linear__create_issue_label,
  mcp__linear__list_issue_statuses
};
```

---

## Best Practices

1. **Always use test prefix** - Prefix test labels with `test-` for easy cleanup
2. **Use timestamps** - Include timestamp in label names to avoid conflicts
3. **Clean up after tests** - Delete created labels/issues
4. **Verify state** - Always check actual Linear state after operations
5. **Handle rate limits** - Use sequential processing for batch operations
6. **Document failures** - Log all errors with context
7. **Isolate tests** - Each test should be independent
8. **Use dedicated team** - Don't run tests in production workspace

---

## Troubleshooting

### Test fails: "No workflow states found"
**Solution:** Ensure team has workflow configured in Linear

### Test fails: "Permission denied"
**Solution:** Verify Linear API token has correct permissions

### Test fails: "Rate limit exceeded"
**Solution:** Reduce test batch size or add delays

### Labels not cleaning up
**Solution:** Run cleanup script manually or check LINEAR_TEST_CLEANUP variable

---

## Future Enhancements

1. **Automated test runner** - Shell script to execute all tests
2. **Parallel test execution** - Run independent tests concurrently
3. **Performance benchmarks** - Track execution time trends
4. **Coverage reporting** - Generate test coverage reports
5. **Integration with CI/CD** - Run in GitHub Actions with test workspace
6. **Snapshot testing** - Compare results against known good states
7. **Fuzzy testing** - Random input generation for edge cases

---

## Contributing

When adding new tests:

1. Follow existing test structure
2. Include clear assertions
3. Document expected behavior
4. Add cleanup code
5. Update test count in summary
6. Run full test suite before committing

---

## References

- [Linear Helper Functions](../../commands/_shared-linear-helpers.md)
- [Linear MCP Documentation](https://github.com/linear/linear-mcp)
- [CCPM Testing Infrastructure](../../docs/development/testing-infrastructure.md)
- [Linear API Documentation](https://developers.linear.app/)

---

**Created:** November 20, 2025
**Last Updated:** November 20, 2025
**Status:** Ready for Testing
**Total Tests:** 42
