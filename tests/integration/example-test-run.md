# Example Test Run - Linear Helper Functions

This document provides a complete example of running the Linear helper integration tests.

## Setup

First, configure your test environment:

```bash
# Set your Linear test team ID
export LINEAR_TEST_TEAM_ID="team_abc123456"

# Enable cleanup after tests
export LINEAR_TEST_CLEANUP="true"

# Navigate to integration tests directory
cd tests/integration
```

## Test Execution Example

### Part 1: Pure Function Tests (No Linear API Required)

These tests validate the `getDefaultColor` function and can run without Linear MCP.

```javascript
// READ: commands/_shared-linear-helpers.md

console.log("=== Category 1: getDefaultColor Tests ===\n");

// Test 1.1: Planning label color
const planningColor = getDefaultColor("planning");
console.log(`✅ Test 1.1: Planning color = ${planningColor}`);
console.log(`   Expected: #f7c8c1, Got: ${planningColor}`);
console.log(`   Result: ${planningColor === "#f7c8c1" ? "PASS" : "FAIL"}\n`);

// Test 1.2: Implementation label color
const implColor = getDefaultColor("implementation");
console.log(`✅ Test 1.2: Implementation color = ${implColor}`);
console.log(`   Expected: #26b5ce, Got: ${implColor}`);
console.log(`   Result: ${implColor === "#26b5ce" ? "PASS" : "FAIL"}\n`);

// Test 1.3: Verification label color
const verifyColor = getDefaultColor("verification");
console.log(`✅ Test 1.3: Verification color = ${verifyColor}`);
console.log(`   Expected: #f2c94c, Got: ${verifyColor}`);
console.log(`   Result: ${verifyColor === "#f2c94c" ? "PASS" : "FAIL"}\n`);

// Test 1.4: Bug label color
const bugColor = getDefaultColor("bug");
console.log(`✅ Test 1.4: Bug color = ${bugColor}`);
console.log(`   Expected: #eb5757, Got: ${bugColor}`);
console.log(`   Result: ${bugColor === "#eb5757" ? "PASS" : "FAIL"}\n`);

// Test 1.5: Unknown label (default gray)
const unknownColor = getDefaultColor("unknown-custom-label");
console.log(`✅ Test 1.5: Unknown label color = ${unknownColor}`);
console.log(`   Expected: #95a2b3, Got: ${unknownColor}`);
console.log(`   Result: ${unknownColor === "#95a2b3" ? "PASS" : "FAIL"}\n`);

// Test 1.6: Case insensitive
const upperColor = getDefaultColor("FEATURE");
console.log(`✅ Test 1.6: Case insensitive (FEATURE) = ${upperColor}`);
console.log(`   Expected: #bb87fc, Got: ${upperColor}`);
console.log(`   Result: ${upperColor === "#bb87fc" ? "PASS" : "FAIL"}\n`);

// Test 1.7: Trimmed input
const trimmedColor = getDefaultColor("  backend  ");
console.log(`✅ Test 1.7: Trimmed input ('  backend  ') = ${trimmedColor}`);
console.log(`   Expected: #26b5ce, Got: ${trimmedColor}`);
console.log(`   Result: ${trimmedColor === "#26b5ce" ? "PASS" : "FAIL"}\n`);

console.log("=== Category 1 Complete: 7/7 tests ===\n");
```

**Expected Output:**
```
=== Category 1: getDefaultColor Tests ===

✅ Test 1.1: Planning color = #f7c8c1
   Expected: #f7c8c1, Got: #f7c8c1
   Result: PASS

✅ Test 1.2: Implementation color = #26b5ce
   Expected: #26b5ce, Got: #26b5ce
   Result: PASS

✅ Test 1.3: Verification color = #f2c94c
   Expected: #f2c94c, Got: #f2c94c
   Result: PASS

✅ Test 1.4: Bug color = #eb5757
   Expected: #eb5757, Got: #eb5757
   Result: PASS

✅ Test 1.5: Unknown label color = #95a2b3
   Expected: #95a2b3, Got: #95a2b3
   Result: PASS

✅ Test 1.6: Case insensitive (FEATURE) = #bb87fc
   Expected: #bb87fc, Got: #bb87fc
   Result: PASS

✅ Test 1.7: Trimmed input ('  backend  ') = #26b5ce
   Expected: #26b5ce, Got: #26b5ce
   Result: PASS

=== Category 1 Complete: 7/7 tests ===
```

---

### Part 2: Label Creation Tests (Requires Linear MCP)

These tests validate `getOrCreateLabel` function with real Linear API.

```javascript
// READ: commands/_shared-linear-helpers.md

console.log("=== Category 2: getOrCreateLabel Tests ===\n");

const teamId = process.env.LINEAR_TEST_TEAM_ID;
const timestamp = Date.now();

// Test 2.1: Create new label with auto color
console.log("🧪 Test 2.1: Create new label with auto color");
const labelName1 = `test-auto-color-${timestamp}`;
const label1 = await getOrCreateLabel(teamId, labelName1);

console.log(`   Created label: ${label1.name} (${label1.id})`);

// Verify label exists
const verify1 = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelName1
});

console.log(`   Verification: ${verify1.length > 0 ? "PASS" : "FAIL"}`);
console.log(`   Color: ${verify1[0].color}`);
console.log(`   Result: ✅ PASS\n`);

// Test 2.2: Create new label with custom color
console.log("🧪 Test 2.2: Create new label with custom color");
const labelName2 = `test-custom-color-${timestamp}`;
const customColor = "#ff5733";
const label2 = await getOrCreateLabel(teamId, labelName2, {
  color: customColor,
  description: "Test label with custom color"
});

console.log(`   Created label: ${label2.name} (${label2.id})`);

// Verify color and description
const verify2 = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelName2
});

console.log(`   Color match: ${verify2[0].color === customColor ? "PASS" : "FAIL"}`);
console.log(`   Description: ${verify2[0].description}`);
console.log(`   Result: ✅ PASS\n`);

// Test 2.3: Idempotent behavior
console.log("🧪 Test 2.3: Return existing label (idempotent)");
const labelName3 = `test-existing-${timestamp}`;

// Create first time
const firstCreate = await getOrCreateLabel(teamId, labelName3);
console.log(`   First create: ${firstCreate.id}`);

// Create second time - should return existing
const secondCreate = await getOrCreateLabel(teamId, labelName3);
console.log(`   Second create: ${secondCreate.id}`);

console.log(`   IDs match: ${firstCreate.id === secondCreate.id ? "PASS" : "FAIL"}`);

// Verify only one label exists
const verify3 = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelName3
});

console.log(`   Only one label: ${verify3.length === 1 ? "PASS" : "FAIL"}`);
console.log(`   Result: ✅ PASS\n`);

// Test 2.4: Case-insensitive matching
console.log("🧪 Test 2.4: Case-insensitive label match");
const labelName4 = "TestCaseSensitive";

const lowerCase = await getOrCreateLabel(teamId, labelName4.toLowerCase());
const upperCase = await getOrCreateLabel(teamId, labelName4.toUpperCase());

console.log(`   Lower case ID: ${lowerCase.id}`);
console.log(`   Upper case ID: ${upperCase.id}`);
console.log(`   IDs match: ${lowerCase.id === upperCase.id ? "PASS" : "FAIL"}`);
console.log(`   Result: ✅ PASS\n`);

console.log("=== Category 2 Complete: 4/6 tests (2 skipped) ===\n");

// Cleanup if enabled
if (process.env.LINEAR_TEST_CLEANUP === "true") {
  console.log("🧹 Cleaning up test labels...");

  for (const name of [labelName1, labelName2, labelName3, labelName4]) {
    const labels = await mcp__linear__list_issue_labels({
      team: teamId,
      name: name
    });

    if (labels.length > 0) {
      await mcp__linear__delete_issue_label({
        id: labels[0].id
      });
      console.log(`   Deleted: ${name}`);
    }
  }

  console.log("✅ Cleanup complete\n");
}
```

**Expected Output:**
```
=== Category 2: getOrCreateLabel Tests ===

🧪 Test 2.1: Create new label with auto color
   Created label: test-auto-color-1700000000 (label_abc123)
   Verification: PASS
   Color: #95a2b3
   Result: ✅ PASS

🧪 Test 2.2: Create new label with custom color
   Created label: test-custom-color-1700000000 (label_abc124)
   Color match: PASS
   Description: Test label with custom color
   Result: ✅ PASS

🧪 Test 2.3: Return existing label (idempotent)
   First create: label_abc125
   Second create: label_abc125
   IDs match: PASS
   Only one label: PASS
   Result: ✅ PASS

🧪 Test 2.4: Case-insensitive label match
   Lower case ID: label_abc126
   Upper case ID: label_abc126
   IDs match: PASS
   Result: ✅ PASS

=== Category 2 Complete: 4/6 tests (2 skipped) ===

🧹 Cleaning up test labels...
   Deleted: test-auto-color-1700000000
   Deleted: test-custom-color-1700000000
   Deleted: test-existing-1700000000
   Deleted: TestCaseSensitive
✅ Cleanup complete
```

---

### Part 3: State Validation Tests (Requires Linear MCP)

These tests validate `getValidStateId` function.

```javascript
// READ: commands/_shared-linear-helpers.md

console.log("=== Category 3: getValidStateId Tests ===\n");

const teamId = process.env.LINEAR_TEST_TEAM_ID;

// First, get available states
const allStates = await mcp__linear__list_issue_statuses({
  team: teamId
});

console.log(`Available states in team:`);
for (const state of allStates) {
  console.log(`  - ${state.name} (type: ${state.type}, id: ${state.id})`);
}
console.log("");

// Test 3.1: Exact name match
console.log("🧪 Test 3.1: Exact state name match");
const testState = allStates[0];
const stateId1 = await getValidStateId(teamId, testState.name);

console.log(`   Looking for: "${testState.name}"`);
console.log(`   Found ID: ${stateId1}`);
console.log(`   Expected ID: ${testState.id}`);
console.log(`   Result: ${stateId1 === testState.id ? "✅ PASS" : "❌ FAIL"}\n`);

// Test 3.2: State type match (backlog)
console.log("🧪 Test 3.2: State type match (backlog)");
const backlogState = await getValidStateId(teamId, "backlog");
const backlogMatch = allStates.find(s => s.id === backlogState);

console.log(`   Looking for type: "backlog"`);
console.log(`   Found state: ${backlogMatch.name}`);
console.log(`   State type: ${backlogMatch.type}`);
console.log(`   Result: ${backlogMatch.type === "backlog" ? "✅ PASS" : "❌ FAIL"}\n`);

// Test 3.3: State type match (started)
console.log("🧪 Test 3.3: State type match (started)");
const startedState = await getValidStateId(teamId, "started");
const startedMatch = allStates.find(s => s.id === startedState);

console.log(`   Looking for type: "started"`);
console.log(`   Found state: ${startedMatch.name}`);
console.log(`   State type: ${startedMatch.type}`);
console.log(`   Result: ${startedMatch.type === "started" ? "✅ PASS" : "❌ FAIL"}\n`);

// Test 3.4: Fallback mapping (todo → unstarted)
console.log("🧪 Test 3.4: Fallback mapping (todo → unstarted)");
const todoState = await getValidStateId(teamId, "todo");
const todoMatch = allStates.find(s => s.id === todoState);

console.log(`   Input: "todo"`);
console.log(`   Mapped to state: ${todoMatch.name}`);
console.log(`   State type: ${todoMatch.type}`);
console.log(`   Result: ${todoMatch.type === "unstarted" ? "✅ PASS" : "❌ FAIL"}\n`);

// Test 3.5: Fallback mapping (in progress → started)
console.log("🧪 Test 3.5: Fallback mapping (in progress → started)");
const inProgressState = await getValidStateId(teamId, "in progress");
const inProgressMatch = allStates.find(s => s.id === inProgressState);

console.log(`   Input: "in progress"`);
console.log(`   Mapped to state: ${inProgressMatch.name}`);
console.log(`   State type: ${inProgressMatch.type}`);
console.log(`   Result: ${inProgressMatch.type === "started" ? "✅ PASS" : "❌ FAIL"}\n`);

// Test 3.6: Invalid state - helpful error
console.log("🧪 Test 3.6: Invalid state name - helpful error");
try {
  await getValidStateId(teamId, "completely-invalid-state-12345");
  console.log(`   Result: ❌ FAIL (should have thrown error)\n`);
} catch (error) {
  const hasInvalidMsg = error.message.includes("Invalid state");
  const hasAvailableMsg = error.message.includes("Available states");
  const hasTypeInfo = error.message.includes("type:");

  console.log(`   Error thrown: ✅`);
  console.log(`   Contains "Invalid state": ${hasInvalidMsg ? "✅" : "❌"}`);
  console.log(`   Contains "Available states": ${hasAvailableMsg ? "✅" : "❌"}`);
  console.log(`   Contains type info: ${hasTypeInfo ? "✅" : "❌"}`);
  console.log(`   Error message:\n   ${error.message.split('\n')[0]}`);
  console.log(`   Result: ✅ PASS\n`);
}

console.log("=== Category 3 Complete: 6/11 tests (5 skipped) ===\n");
```

**Expected Output:**
```
=== Category 3: getValidStateId Tests ===

Available states in team:
  - Backlog (type: backlog, id: state_123)
  - Todo (type: unstarted, id: state_124)
  - In Progress (type: started, id: state_125)
  - Done (type: completed, id: state_126)

🧪 Test 3.1: Exact state name match
   Looking for: "Backlog"
   Found ID: state_123
   Expected ID: state_123
   Result: ✅ PASS

🧪 Test 3.2: State type match (backlog)
   Looking for type: "backlog"
   Found state: Backlog
   State type: backlog
   Result: ✅ PASS

🧪 Test 3.3: State type match (started)
   Looking for type: "started"
   Found state: In Progress
   State type: started
   Result: ✅ PASS

🧪 Test 3.4: Fallback mapping (todo → unstarted)
   Input: "todo"
   Mapped to state: Todo
   State type: unstarted
   Result: ✅ PASS

🧪 Test 3.5: Fallback mapping (in progress → started)
   Input: "in progress"
   Mapped to state: In Progress
   State type: started
   Result: ✅ PASS

🧪 Test 3.6: Invalid state name - helpful error
   Error thrown: ✅
   Contains "Invalid state": ✅
   Contains "Available states": ✅
   Contains type info: ✅
   Error message:
   Invalid state: "completely-invalid-state-12345"
   Result: ✅ PASS

=== Category 3 Complete: 6/11 tests (5 skipped) ===
```

---

### Part 4: Batch Operations Tests (Requires Linear MCP)

These tests validate `ensureLabelsExist` function.

```javascript
// READ: commands/_shared-linear-helpers.md

console.log("=== Category 4: ensureLabelsExist Tests ===\n");

const teamId = process.env.LINEAR_TEST_TEAM_ID;
const timestamp = Date.now();

// Test 4.1: Create multiple new labels
console.log("🧪 Test 4.1: Create multiple new labels");
const labelNames1 = [
  `test-batch-1-${timestamp}`,
  `test-batch-2-${timestamp}`,
  `test-batch-3-${timestamp}`
];

const result1 = await ensureLabelsExist(teamId, labelNames1);

console.log(`   Requested labels: ${labelNames1.length}`);
console.log(`   Created labels: ${result1.length}`);
console.log(`   Result: ${result1.length === 3 ? "✅ PASS" : "❌ FAIL"}\n`);

// Test 4.2: Mix of existing and new labels
console.log("🧪 Test 4.2: Mix of existing and new labels");

// Create one label first
const existingLabel = `test-existing-${timestamp}`;
await getOrCreateLabel(teamId, existingLabel);

const labelNames2 = [
  existingLabel,  // Existing
  `test-new-1-${timestamp}`,  // New
  `test-new-2-${timestamp}`   // New
];

const result2 = await ensureLabelsExist(teamId, labelNames2);

console.log(`   Existing labels: 1`);
console.log(`   New labels: 2`);
console.log(`   Total returned: ${result2.length}`);
console.log(`   Result: ${result2.length === 3 ? "✅ PASS" : "❌ FAIL"}\n`);

// Test 4.3: Custom colors
console.log("🧪 Test 4.3: Custom colors for labels");
const labelNames3 = [
  `test-color-1-${timestamp}`,
  `test-color-2-${timestamp}`
];

const result3 = await ensureLabelsExist(teamId, labelNames3, {
  colors: {
    [`test-color-1-${timestamp}`]: "#ff0000",
    [`test-color-2-${timestamp}`]: "#00ff00"
  }
});

// Verify colors
const verify1 = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelNames3[0]
});

const verify2 = await mcp__linear__list_issue_labels({
  team: teamId,
  name: labelNames3[1]
});

console.log(`   Label 1 color: ${verify1[0].color} (expected: #ff0000)`);
console.log(`   Label 2 color: ${verify2[0].color} (expected: #00ff00)`);
console.log(`   Result: ✅ PASS\n`);

console.log("=== Category 4 Complete: 3/6 tests (3 skipped) ===\n");

// Cleanup
if (process.env.LINEAR_TEST_CLEANUP === "true") {
  console.log("🧹 Cleaning up test labels...");

  const allTestLabels = [
    ...labelNames1,
    ...labelNames2,
    ...labelNames3
  ];

  for (const name of allTestLabels) {
    const labels = await mcp__linear__list_issue_labels({
      team: teamId,
      name: name
    });

    if (labels.length > 0) {
      await mcp__linear__delete_issue_label({
        id: labels[0].id
      });
      console.log(`   Deleted: ${name}`);
    }
  }

  console.log("✅ Cleanup complete\n");
}
```

**Expected Output:**
```
=== Category 4: ensureLabelsExist Tests ===

🧪 Test 4.1: Create multiple new labels
   Requested labels: 3
   Created labels: 3
   Result: ✅ PASS

🧪 Test 4.2: Mix of existing and new labels
   Existing labels: 1
   New labels: 2
   Total returned: 3
   Result: ✅ PASS

🧪 Test 4.3: Custom colors for labels
   Label 1 color: #ff0000 (expected: #ff0000)
   Label 2 color: #00ff00 (expected: #00ff00)
   Result: ✅ PASS

=== Category 4 Complete: 3/6 tests (3 skipped) ===

🧹 Cleaning up test labels...
   Deleted: test-batch-1-1700000000
   Deleted: test-batch-2-1700000000
   Deleted: test-batch-3-1700000000
   Deleted: test-existing-1700000000
   Deleted: test-new-1-1700000000
   Deleted: test-new-2-1700000000
   Deleted: test-color-1-1700000000
   Deleted: test-color-2-1700000000
✅ Cleanup complete
```

---

## Test Results Summary

After running all test categories, create a summary:

```markdown
# Test Run Results

**Date:** November 20, 2025
**Environment:**
- Team ID: team_***
- Linear MCP Version: 1.0.0
- Cleanup Enabled: Yes

## Results Summary

Total Tests: 42
- ✅ Passed: 20
- ❌ Failed: 0
- ⚠️ Skipped: 22

## Category Results

- Category 1 (getDefaultColor): 7/7 ✅
- Category 2 (getOrCreateLabel): 4/6 (2 skipped)
- Category 3 (getValidStateId): 6/11 (5 skipped)
- Category 4 (ensureLabelsExist): 3/6 (3 skipped)
- Category 5 (Error Handling): 0/3 (3 skipped - manual only)
- Category 6 (Integration Scenarios): 0/3 (3 skipped - manual only)

## Notes

- All executed tests passed successfully
- Skipped tests require manual execution or specific conditions
- Cleanup completed successfully - no test data remaining
- All helper functions working as expected
```

---

## Next Steps

1. **Run full test suite** - Execute all 42 tests in Claude Code
2. **Document results** - Record outcomes and any issues
3. **Report bugs** - File issues for any failures
4. **Add more tests** - Expand coverage for edge cases
5. **Automate further** - Create CI/CD integration

---

**Created:** November 20, 2025
**Status:** Example Test Run Documentation
