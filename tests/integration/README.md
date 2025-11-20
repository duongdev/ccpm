# Integration Tests - Linear Helper Functions

Complete integration testing suite for shared Linear helper functions in CCPM.

## Overview

This directory contains integration tests that validate Linear helper functions against a real Linear workspace using the Linear MCP server.

**What's Included:**
- 42 comprehensive test cases across 6 categories
- Automated test runner script
- Cleanup utilities for test data
- Detailed test documentation
- Execution instructions

## Quick Start

### 1. Set Up Test Environment

```bash
# Required: Set your Linear test team ID
export LINEAR_TEST_TEAM_ID="your-team-id-here"

# Optional: Enable auto-cleanup after tests
export LINEAR_TEST_CLEANUP="true"
```

**Finding your team ID:**
- Use Linear MCP: `mcp__linear__list_teams`
- Or check Linear URL: `https://linear.app/[workspace]/team/[TEAM-ID]`

### 2. Run Test Runner

```bash
# Navigate to integration tests directory
cd tests/integration

# Run test script (shows what tests are available)
./run-linear-helpers-tests.sh

# Run with verbose output
./run-linear-helpers-tests.sh --verbose

# Run specific category only
./run-linear-helpers-tests.sh --category 2
```

### 3. Execute Tests Manually

Since these tests require Linear MCP integration, execute them in Claude Code:

```bash
# Open the test file
cat linear-helpers.test.md

# Copy test code blocks and run in Claude Code
# Each test includes assertions and expected behavior
```

## Test Categories

### Category 1: getDefaultColor (7 tests)
Pure function tests for color mapping logic.

**Tests:**
- Planning label color → #f7c8c1
- Implementation label color → #26b5ce
- Verification label color → #f2c94c
- Bug label color → #eb5757
- Unknown label default → #95a2b3
- Case-insensitive lookup
- Trimmed input handling

**Status:** Ready to run (no Linear API required)

### Category 2: getOrCreateLabel (6 tests)
Label creation and retrieval operations.

**Tests:**
- Create new label with auto color
- Create new label with custom color
- Return existing label (idempotent)
- Case-insensitive label matching
- Invalid team ID handling
- Special characters in label names

**Status:** Requires Linear MCP connection

### Category 3: getValidStateId (11 tests)
State validation and mapping logic.

**Tests:**
- Exact state name match
- State type matching (backlog, unstarted, started, completed)
- Fallback mappings (todo→unstarted, done→completed)
- Case-insensitive state names
- Helpful error messages
- Invalid team ID handling

**Status:** Requires Linear MCP connection

### Category 4: ensureLabelsExist (6 tests)
Batch label operations and management.

**Tests:**
- Create multiple new labels
- Mix of existing and new labels
- Custom colors for labels
- Custom descriptions for labels
- Empty label array handling
- Rate limit handling (sequential processing)

**Status:** Requires Linear MCP connection

### Category 5: Error Handling (3 tests)
Error scenarios and edge cases.

**Tests:**
- Network error simulation
- Invalid color format handling
- Partial failure in batch operations

**Status:** Requires manual/mocked execution

### Category 6: Integration Scenarios (3 tests)
End-to-end workflow validation.

**Tests:**
- Complete issue creation workflow
- Issue status transitions
- Label color consistency

**Status:** Requires Linear MCP connection

## File Structure

```
tests/integration/
├── README.md                          # This file
├── linear-helpers.test.md             # Test specifications (42 tests)
├── run-linear-helpers-tests.sh        # Automated test runner
└── cleanup-linear-test-data.sh        # Cleanup utility
```

## Running Tests

### Option 1: Manual Execution in Claude Code

**Best for:** Individual test debugging, comprehensive validation

```bash
# 1. Open test documentation
cat tests/integration/linear-helpers.test.md

# 2. Set environment variables
export LINEAR_TEST_TEAM_ID="your-team-id"

# 3. Copy test code from documentation
# 4. Execute in Claude Code session
# 5. Verify results match expected behavior
```

### Option 2: Test Runner Script

**Best for:** Understanding test structure, documentation review

```bash
# Run all tests (shows structure)
./run-linear-helpers-tests.sh

# Run with verbose output
./run-linear-helpers-tests.sh --verbose

# Run specific category
./run-linear-helpers-tests.sh --category 1  # Pure functions
./run-linear-helpers-tests.sh --category 2  # Label operations
./run-linear-helpers-tests.sh --category 3  # State validation
./run-linear-helpers-tests.sh --category 4  # Batch operations
./run-linear-helpers-tests.sh --category 5  # Error handling
./run-linear-helpers-tests.sh --category 6  # Integration scenarios

# Enable cleanup after tests
./run-linear-helpers-tests.sh --cleanup
```

### Option 3: Automated CI/CD Integration

**Note:** Integration tests with Linear API require additional setup for CI/CD.

**Options:**
1. **Skip in CI/CD** - Run only structural validation
2. **Separate Test Workspace** - Use dedicated Linear workspace with test team
3. **Mocked Tests** - Create unit tests with mocked Linear MCP (future enhancement)

## Test Execution Examples

### Example 1: Test Pure Functions (Category 1)

```javascript
// READ: commands/_shared-linear-helpers.md

// Test: Planning label color
const result = getDefaultColor("planning");
console.log("Planning color:", result); // Expected: #f7c8c1

// Test: Unknown label default
const defaultColor = getDefaultColor("unknown-label");
console.log("Default color:", defaultColor); // Expected: #95a2b3

// Test: Case-insensitive
const upperResult = getDefaultColor("FEATURE");
console.log("Feature color:", upperResult); // Expected: #bb87fc
```

### Example 2: Test Label Creation (Category 2)

```javascript
// READ: commands/_shared-linear-helpers.md

const teamId = process.env.LINEAR_TEST_TEAM_ID;

// Test: Create new label
const label = await getOrCreateLabel(teamId, `test-label-${Date.now()}`);
console.log("Created label:", label.id, label.name);

// Test: Idempotent behavior
const label2 = await getOrCreateLabel(teamId, label.name);
console.log("Same label:", label.id === label2.id); // Expected: true
```

### Example 3: Test State Validation (Category 3)

```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

// Test: State type matching
const stateId = await getValidStateId(teamId, "started");
console.log("Started state ID:", stateId);

// Test: Fallback mapping
const todoStateId = await getValidStateId(teamId, "todo");
console.log("Todo maps to unstarted:", todoStateId);

// Test: Error handling
try {
  await getValidStateId(teamId, "invalid-state");
} catch (error) {
  console.log("Helpful error:", error.message);
  // Should include list of available states
}
```

## Cleanup

### Option 1: Automatic Cleanup

```bash
# Enable cleanup during test execution
export LINEAR_TEST_CLEANUP="true"

# Run tests - will auto-delete created data
./run-linear-helpers-tests.sh --cleanup
```

### Option 2: Manual Cleanup Script

```bash
# Dry run (see what would be deleted)
./cleanup-linear-test-data.sh --dry-run

# Delete test labels only
./cleanup-linear-test-data.sh --labels

# Delete test issues only
./cleanup-linear-test-data.sh --issues

# Delete all test data
./cleanup-linear-test-data.sh --all
```

### Option 3: Manual Cleanup via Linear UI

1. Go to Linear workspace settings
2. Navigate to Labels section
3. Filter labels starting with "test-"
4. Delete test labels
5. Search for test issues in Linear
6. Archive or delete test issues

## Best Practices

### Test Naming Convention

Always prefix test data with "test-":

```javascript
// Good
const labelName = `test-planning-${Date.now()}`;
const issueTitle = `Integration Test Issue ${Date.now()}`;

// Bad
const labelName = "planning"; // Could conflict with real data
```

### Test Isolation

Each test should be independent:

```javascript
// Use unique timestamps for each test
const timestamp = Date.now();
const uniqueLabel = `test-label-${timestamp}`;

// Clean up after test
if (LINEAR_TEST_CLEANUP) {
  // Delete created data
}
```

### Error Handling

Always verify expected behavior:

```javascript
// Verify success
const result = await getOrCreateLabel(teamId, labelName);
assert(result.id, "Label should have an ID");
assert(result.name === labelName, "Name should match");

// Verify error handling
try {
  await getValidStateId("invalid-team", "state");
  assert(false, "Should throw error");
} catch (error) {
  assert(error.message.includes("Invalid"), "Should have helpful error");
}
```

## Troubleshooting

### "LINEAR_TEST_TEAM_ID not set"

**Solution:**
```bash
# Get your team ID from Linear MCP
mcp__linear__list_teams

# Set environment variable
export LINEAR_TEST_TEAM_ID="your-team-id"
```

### "Permission denied" during label creation

**Solution:**
- Verify Linear API token has correct permissions
- Check team settings allow label creation
- Ensure you're testing in a development/test team, not production

### "Rate limit exceeded"

**Solution:**
- Reduce batch size in tests
- Add delays between operations
- Use `ensureLabelsExist()` which processes sequentially

### Labels not cleaning up

**Solution:**
```bash
# Run cleanup script
./cleanup-linear-test-data.sh --all

# Or manually in Linear UI
# Settings > Labels > Delete test labels
```

## Test Results Template

Use this template to document test runs:

```markdown
# Test Run: [Date]

## Environment
- Team ID: team_***
- Linear MCP Version: X.X.X
- Cleanup Enabled: Yes/No

## Results Summary
- Total Tests: 42
- Passed: XX
- Failed: XX
- Skipped: XX

## Category Results
- Category 1 (getDefaultColor): X/7 passed
- Category 2 (getOrCreateLabel): X/6 passed
- Category 3 (getValidStateId): X/11 passed
- Category 4 (ensureLabelsExist): X/6 passed
- Category 5 (Error Handling): X/3 passed
- Category 6 (Integration Scenarios): X/3 passed

## Failed Tests
(List any failures with error messages)

## Notes
(Any observations or issues encountered)
```

## Contributing

When adding new tests:

1. **Follow existing structure** - Match test naming and organization
2. **Include assertions** - Verify expected behavior explicitly
3. **Document expected results** - Use ✅ markers for clarity
4. **Add cleanup code** - Ensure test data can be removed
5. **Update test count** - Keep documentation in sync
6. **Run full suite** - Verify new tests don't break existing ones

## CI/CD Integration (Future)

Planned enhancements for automated testing:

1. **Mocked Linear MCP** - Unit tests without API calls
2. **Dedicated test workspace** - Isolated Linear environment
3. **GitHub Actions workflow** - Automated test execution
4. **Coverage reporting** - Track test coverage metrics
5. **Performance benchmarks** - Monitor execution time trends

## Resources

- [Linear Helper Functions Documentation](../../commands/_shared-linear-helpers.md)
- [Linear MCP Documentation](https://github.com/linear/linear-mcp)
- [CCPM Testing Infrastructure](../../docs/development/testing-infrastructure.md)
- [Linear API Documentation](https://developers.linear.app/)

## Support

For issues or questions:

1. **Review test documentation** - Check `linear-helpers.test.md`
2. **Check troubleshooting** - Common issues listed above
3. **Verify prerequisites** - Ensure Linear MCP is configured
4. **Review helper functions** - Check `commands/_shared-linear-helpers.md`

---

**Created:** November 20, 2025
**Last Updated:** November 20, 2025
**Status:** Ready for Testing
**Total Tests:** 42 (across 6 categories)
