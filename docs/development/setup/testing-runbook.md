# CCPM Testing Runbook

Quick reference guide for running tests and troubleshooting issues.

## Quick Start

### Run All Tests Locally
```bash
# Standard validation
./scripts/run-all-tests.sh

# With verbose output
./scripts/run-all-tests.sh --verbose

# Auto-fix issues
./scripts/run-all-tests.sh --fix

# CI/CD mode
./scripts/run-all-tests.sh --ci
```

### Run Specific Test Suites
```bash
# Plugin validation only
./scripts/validate-plugin.sh

# Skill activation tests
./scripts/test-skill-activation.sh

# Hook integrity check
./scripts/verify-hook-integrity.sh

# Linear integration tests
cd tests/integration
./run-linear-helpers-tests.sh
```

## Test Categories

### 1. Plugin Validation

**Purpose:** Validate plugin structure and configuration

**What it tests:**
- Command file structure and frontmatter
- Skill file structure
- Hook configuration
- JSON validation (plugin.json, hooks.json)
- Script syntax
- File permissions

**When to run:**
- Before committing changes
- After adding/modifying commands
- After updating plugin configuration
- In CI/CD on every push

**Command:**
```bash
./scripts/validate-plugin.sh --verbose
```

**Expected duration:** < 5 seconds

### 2. Skill Activation Tests

**Purpose:** Validate skill discovery and auto-activation

**What it tests:**
- Skill file structure
- Frontmatter validation
- Skill naming conventions
- Auto-activation triggers
- Content structure

**When to run:**
- After adding new skills
- After modifying skill frontmatter
- When testing auto-activation
- Before releasing new skills

**Command:**
```bash
./scripts/test-skill-activation.sh --verbose

# Simulate activation trigger
./scripts/test-skill-activation.sh --simulate "done"
```

**Expected duration:** < 3 seconds

### 3. Hook Integrity Tests

**Purpose:** Ensure hooks are properly configured

**What it tests:**
- hooks.json validity
- Hook file existence
- Shell script syntax
- Script permissions
- Dependency availability

**When to run:**
- After modifying hooks
- After updating hook scripts
- Before deploying hooks
- In CI/CD pipeline

**Command:**
```bash
./scripts/verify-hook-integrity.sh --verbose --fix
```

**Expected duration:** < 3 seconds

### 4. Integration Tests (Linear)

**Purpose:** Test Linear helper functions against real API

**What it tests:**
- Label creation and retrieval
- State validation
- Batch operations
- Error handling
- Integration scenarios

**When to run:**
- After modifying Linear helpers
- Before major releases
- On main branch only (CI/CD)
- Manual testing when needed

**Setup:**
```bash
export LINEAR_TEST_TEAM_ID="your-team-id"
export LINEAR_TEST_CLEANUP="true"
```

**Command:**
```bash
cd tests/integration
./run-linear-helpers-tests.sh --verbose --cleanup
```

**Expected duration:** 2-5 minutes

### 5. Mock Integration Tests

**Purpose:** Test commands against mock APIs (fast, no real API calls)

**What it tests:**
- Command logic with mocked responses
- Error handling
- Edge cases
- Integration workflows

**When to run:**
- During development
- In CI/CD on every PR
- For fast feedback

**Setup:**
```bash
# Start mock servers
node tests/mocks/mcp-servers/linear-mock.js --port 3001 &
```

**Command:**
```bash
# TODO: Implement mock test runner
./tests/run-mock-tests.sh
```

**Expected duration:** < 1 minute

### 6. Performance Benchmarks

**Purpose:** Measure token usage and execution time

**What it tests:**
- Token usage per command
- Baseline vs optimized comparison
- Cache performance
- Execution time

**When to run:**
- After optimization changes
- Before major releases
- Weekly for trend tracking
- In CI/CD on main branch

**Command:**
```bash
# Measure all commands (optimized)
./tests/benchmarks/scripts/measure-token-usage.sh --all --optimized

# Compare baseline vs optimized
./tests/benchmarks/scripts/measure-token-usage.sh --compare

# Generate report
./tests/benchmarks/scripts/generate-report.sh
```

**Expected duration:** 5-10 minutes

### 7. UAT Scenarios

**Purpose:** Validate end-to-end user workflows

**What it tests:**
- Complete feature lifecycle
- TDD enforcement
- Multi-command sequences
- Interactive workflows
- Error recovery

**When to run:**
- Before major releases
- After workflow changes
- Manual testing for new features

**Command:**
```bash
# Run specific scenario
./tests/uat/scripts/run-scenario.sh complete-feature-workflow

# Validate output
./tests/uat/scripts/validate-output.sh
```

**Expected duration:** 10-15 minutes per scenario

## CI/CD Testing

### GitHub Actions Workflow

**File:** `.github/workflows/test-comprehensive.yml`

**Triggers:**
- Push to main/develop
- Pull requests to main/develop
- Manual dispatch

**Jobs:**
1. **Unit Tests** - Fast unit tests (< 10 min)
2. **Plugin Validation** - Structure validation (< 5 min)
3. **Mock Integration** - Mock API tests (< 15 min)
4. **Performance Benchmarks** - Token usage (< 20 min)
5. **Real Integration** - Real API tests (main branch only, < 30 min)
6. **Test Summary** - Aggregate results

**Viewing Results:**
- Go to GitHub Actions tab
- Click on workflow run
- View job results
- Download artifacts for detailed reports

**Required Secrets:**
```bash
LINEAR_TEST_API_KEY       # Linear API key for test workspace
LINEAR_TEST_TEAM_ID       # Linear test team ID
GITHUB_TEST_TOKEN         # GitHub token for PR tests
```

## Common Test Scenarios

### Scenario 1: Adding a New Command

```bash
# 1. Create command file
cat > commands/new:command.md

# 2. Validate structure
./scripts/validate-plugin.sh --verbose

# 3. Test in isolation
# (manual execution in Claude Code)

# 4. Run full test suite
./scripts/run-all-tests.sh

# 5. Commit if passing
git add commands/new:command.md
git commit -m "feat: add new command"
```

### Scenario 2: Modifying Hook Logic

```bash
# 1. Edit hook file
vim hooks/smart-agent-selector-optimized.prompt

# 2. Verify integrity
./scripts/verify-hook-integrity.sh --fix

# 3. Test hook behavior
./hooks/scripts/test-hook.sh

# 4. Benchmark performance
./scripts/benchmark-hooks.sh

# 5. Commit if passing
git add hooks/
git commit -m "feat: optimize agent selector hook"
```

### Scenario 3: Updating Linear Helpers

```bash
# 1. Edit helper functions
vim commands/_shared-linear-helpers.md

# 2. Run integration tests
cd tests/integration
./run-linear-helpers-tests.sh --verbose

# 3. Check for failures
# Fix any issues

# 4. Cleanup test data
./cleanup-linear-test-data.sh --all

# 5. Commit if passing
git add commands/_shared-linear-helpers.md
git commit -m "refactor: improve Linear helper caching"
```

### Scenario 4: Preparing for Release

```bash
# 1. Run comprehensive tests
./scripts/run-all-tests.sh --verbose

# 2. Run integration tests
cd tests/integration
./run-linear-helpers-tests.sh --cleanup

# 3. Run performance benchmarks
./tests/benchmarks/scripts/measure-token-usage.sh --all --compare

# 4. Review benchmark report
cat tests/benchmarks/reports/token-reduction-report_*.md

# 5. Run UAT scenarios
./tests/uat/scripts/run-scenario.sh complete-feature-workflow

# 6. Generate release notes
# Include test results and performance metrics

# 7. Tag release
git tag -a v2.0.0 -m "Release v2.0.0"
git push --tags
```

## Troubleshooting

### Issue: "Command file missing YAML frontmatter"

**Symptoms:**
```
✗ planning:create.md missing YAML frontmatter
```

**Solution:**
```yaml
---
description: Your command description here
---
# Command Name
...rest of file
```

### Issue: "LINEAR_TEST_TEAM_ID not set"

**Symptoms:**
```
Error: LINEAR_TEST_TEAM_ID environment variable not set
```

**Solution:**
```bash
# Get your team ID from Linear
# Option 1: Use Linear MCP
mcp__linear__list_teams

# Option 2: Check Linear URL
# https://linear.app/[workspace]/team/[TEAM-ID]

# Set environment variable
export LINEAR_TEST_TEAM_ID="your-team-id"
```

### Issue: "Rate limit exceeded"

**Symptoms:**
```
Error: Rate limit exceeded. Please try again later.
```

**Solution:**
```bash
# Reduce test frequency
# Add delays between tests
sleep 2

# Use mock servers instead
./tests/run-mock-tests.sh

# Use dedicated test workspace
# (separate from production)
```

### Issue: "Mock server not responding"

**Symptoms:**
```
Error: ECONNREFUSED localhost:3001
```

**Solution:**
```bash
# Check if server is running
lsof -i :3001

# Start server
node tests/mocks/mcp-servers/linear-mock.js --port 3001 &

# Wait for startup
sleep 2

# Verify server is up
curl http://localhost:3001/stats
```

### Issue: "Tests are slow"

**Symptoms:**
- Tests take > 15 minutes
- CI/CD timeouts

**Solution:**
```bash
# Run mock tests instead of real API
./tests/run-mock-tests.sh

# Run specific test suites
./scripts/validate-plugin.sh --only "Plugin"

# Use parallel execution
# (implemented in CI/CD)

# Skip integration tests during development
# (run only on main branch)
```

### Issue: "Test data not cleaned up"

**Symptoms:**
- Test labels left in Linear workspace
- Test issues not deleted

**Solution:**
```bash
# Manual cleanup
cd tests/integration
./cleanup-linear-test-data.sh --all

# Enable auto-cleanup
export LINEAR_TEST_CLEANUP="true"
./run-linear-helpers-tests.sh --cleanup

# Use dedicated test workspace
# (prevents pollution of production data)
```

## Performance Targets

### Token Usage
- **Target:** 40-60% reduction from baseline
- **Baseline:** Pre-optimization (without Linear subagent)
- **Optimized:** With Linear subagent, caching, hook optimization
- **Measurement:** Token counts per command execution

### Cache Performance
- **Hit Rate:** 85-95%
- **Miss Penalty:** < 600ms
- **Avg Response (cached):** < 50ms
- **Avg Response (uncached):** < 500ms

### Execution Time
- **Most commands:** < 5s
- **Complex commands:** < 10s
- **Integration tests:** < 10 minutes
- **Full test suite:** < 15 minutes

### Test Coverage
- **Command coverage:** 100% (all 65+ commands)
- **Integration coverage:** 90% (critical workflows)
- **Error scenario coverage:** 80% (common errors)
- **Performance benchmarks:** 100% (all commands)

## Best Practices

### 1. Run Tests Before Committing
```bash
# Always run full validation
./scripts/run-all-tests.sh --verbose

# Fix issues before committing
./scripts/run-all-tests.sh --fix
```

### 2. Use Test Prefixes
```bash
# Always prefix test data with "test-"
const labelName = `test-planning-${Date.now()}`;
const issueTitle = `Test Issue ${Date.now()}`;
```

### 3. Clean Up After Tests
```bash
# Enable automatic cleanup
export LINEAR_TEST_CLEANUP="true"

# Or run cleanup manually
./tests/integration/cleanup-linear-test-data.sh --all
```

### 4. Use Dedicated Test Workspaces
- Separate Linear workspace for testing
- Separate GitHub org/repo for PR tests
- Separate Jira project for sync tests
- **Never test in production workspaces**

### 5. Review Test Output
- Check warnings, not just errors
- Look for performance degradation
- Monitor token usage trends
- Track cache hit rates

### 6. Document Test Failures
- Include error messages
- Provide reproduction steps
- Suggest fixes
- Link to relevant issues

## Maintenance Schedule

### Daily (Automated)
- Run plugin validation on every push
- Run mock integration tests on every PR
- Run performance benchmarks on main branch

### Weekly (Automated/Manual)
- Run real integration tests on main branch
- Review performance trends
- Update test fixtures
- Clean up old test data

### Monthly (Manual)
- Review test coverage
- Add tests for new features
- Update UAT scenarios
- Optimize slow tests

### Quarterly (Manual)
- Comprehensive test review
- Update test documentation
- Benchmark against baseline
- Plan test infrastructure improvements

## Reference

### Test Script Locations
```
scripts/
├── validate-plugin.sh
├── test-skill-activation.sh
├── verify-hook-integrity.sh
├── run-all-tests.sh
└── benchmark-hooks.sh

tests/
├── integration/
│   ├── run-linear-helpers-tests.sh
│   └── cleanup-linear-test-data.sh
├── benchmarks/
│   └── scripts/
│       └── measure-token-usage.sh
├── uat/
│   └── scripts/
│       └── run-scenario.sh
└── mocks/
    └── mcp-servers/
        └── linear-mock.js
```

### Environment Variables
```bash
# Required for integration tests
LINEAR_TEST_TEAM_ID=your-team-id
LINEAR_API_KEY=your-api-key

# Optional
LINEAR_TEST_CLEANUP=true
VERBOSE=true
```

### Documentation
- [Testing Infrastructure](../development/testing-infrastructure.md)
- [Test Framework Architecture](../architecture/test-framework-architecture.md)
- [Testing Implementation Plan](../development/testing-implementation-plan.md)
- [Linear Integration Tests](../../tests/integration/README.md)

## Support

**Questions or Issues:**
1. Check this runbook first
2. Review test documentation
3. Check troubleshooting section
4. Create GitHub issue if needed

**Reporting Test Failures:**
1. Include error message
2. Provide reproduction steps
3. Attach test output
4. Specify environment details

---

**Version:** 1.0
**Last Updated:** November 21, 2025
**Maintained by:** Testing & QA Team
