# CCPM Test Framework Architecture

Comprehensive testing strategy and architecture for Phase 5: Testing & QA.

## Executive Summary

This document defines the complete testing framework for the CCPM plugin, covering:

- **Integration testing** for all 65+ commands
- **Mock MCP servers** for external system testing
- **Performance benchmarking** for token usage and execution time
- **UAT scenarios** for end-to-end workflow validation
- **CI/CD integration** for automated testing
- **Test fixtures** for comprehensive test data

**Goals:**
- Validate 40-60% token reduction optimization
- Ensure all commands work correctly with Linear, Jira, Confluence, Slack, BitBucket
- Prevent regressions with automated test suite
- Enable safe refactoring and feature additions
- Maintain high code quality standards

## Current State Analysis

### Existing Test Infrastructure

**✅ What We Have:**

1. **Plugin Validation** (`scripts/validate-plugin.sh`)
   - Command frontmatter validation
   - Skill structure validation
   - Hook integrity checks
   - JSON validation for plugin.json, hooks.json
   - Script syntax validation

2. **Skill Auto-Activation Testing** (`scripts/test-skill-activation.sh`)
   - Skill discovery validation
   - Auto-activation trigger simulation
   - Skill structure validation

3. **Hook Verification** (`scripts/verify-hook-integrity.sh`)
   - Hook file integrity checks
   - Shell script syntax validation
   - Dependency verification

4. **Local Marketplace Testing** (`scripts/setup-local-marketplace.sh`)
   - Plugin installation validation
   - Component discovery testing

5. **Linear Helpers Integration Tests** (`tests/integration/`)
   - 42 test cases for Linear helper functions
   - Real Linear API integration tests
   - Test cleanup utilities

6. **Comprehensive Test Runner** (`scripts/run-all-tests.sh`)
   - Orchestrates all test suites
   - CI/CD mode support
   - Verbose and fix modes

**❌ What's Missing:**

1. **Command Integration Tests** - No tests for 65+ slash commands
2. **Mock MCP Servers** - No mocked external system APIs
3. **Performance Benchmarks** - No token usage/speed measurement
4. **UAT Scenarios** - No end-to-end workflow tests
5. **Hook Behavior Tests** - No tests for hook invocation logic
6. **Test Fixtures** - Limited test data for comprehensive testing
7. **Regression Test Suite** - No automated regression detection

### Testing Scope

**Total Components to Test:**

- **65+ Commands** across 7 categories
  - Spec Management (6 commands)
  - Planning (7 commands)
  - Implementation (4 commands)
  - Verification (3 commands)
  - Completion (1 command)
  - Project Operations (11 commands)
  - Utilities (13+ commands)
  - Natural Workflow (6 commands)

- **4 Project-Specific Agents**
- **10 Installable Skills**
- **3 Optimized Hooks**
- **7 Shell Scripts**
- **5 MCP Integrations** (Linear, GitHub, Context7, Jira, Confluence)

## Test Framework Architecture

### Layer 1: Unit Tests (Lightweight)

**Purpose:** Test individual functions and components in isolation.

**What to Test:**
- Pure functions (color mapping, string formatting)
- Helper function logic without API calls
- Command argument parsing
- Configuration loading
- Project detection logic

**Technology:**
- Bash test framework (bats-core)
- Node.js test runner for JavaScript logic
- Mock implementations for external dependencies

**Example Structure:**
```
tests/unit/
├── helpers/
│   ├── linear-helpers.test.sh
│   ├── color-mapping.test.sh
│   └── argument-parsing.test.sh
├── commands/
│   ├── command-parser.test.sh
│   └── frontmatter-validation.test.sh
├── agents/
│   ├── project-detector.test.sh
│   └── agent-scoring.test.sh
└── utils/
    ├── string-utils.test.sh
    └── validation-utils.test.sh
```

**Key Features:**
- Fast execution (< 1s per test)
- No external dependencies
- Parallel execution safe
- Clear pass/fail assertions

### Layer 2: Integration Tests (Real APIs)

**Purpose:** Test commands against real MCP servers and APIs.

**What to Test:**
- Complete command workflows
- Linear API operations (create, update, delete)
- GitHub PR creation
- Jira integration
- Confluence operations
- Multi-step workflows

**Technology:**
- Bash test scripts
- Real MCP server connections
- Test workspace/project isolation
- Automated cleanup

**Example Structure:**
```
tests/integration/
├── linear/
│   ├── linear-helpers.test.md (✅ existing)
│   ├── issue-operations.test.sh
│   ├── label-management.test.sh
│   ├── state-transitions.test.sh
│   └── document-operations.test.sh
├── commands/
│   ├── spec-commands.test.sh
│   ├── planning-commands.test.sh
│   ├── implementation-commands.test.sh
│   ├── verification-commands.test.sh
│   └── workflow-commands.test.sh
├── workflows/
│   ├── complete-lifecycle.test.sh
│   ├── tdd-workflow.test.sh
│   └── multi-project.test.sh
└── cleanup/
    ├── cleanup-linear-test-data.sh (✅ existing)
    ├── cleanup-github-test-data.sh
    └── cleanup-all-test-data.sh
```

**Key Features:**
- Real API validation
- End-to-end workflows
- Automatic cleanup
- Test isolation
- Rate limit handling

### Layer 3: Mock Integration Tests (Simulated APIs)

**Purpose:** Test commands without hitting real APIs (for CI/CD and fast testing).

**What to Test:**
- Command logic with mocked responses
- Error handling scenarios
- Edge cases and failure modes
- Performance under various conditions
- Rate limit behavior

**Technology:**
- Mock MCP server implementations
- HTTP mocking for API calls
- Response fixtures
- Error simulation

**Example Structure:**
```
tests/mocks/
├── mcp-servers/
│   ├── linear-mock.js
│   ├── github-mock.js
│   ├── jira-mock.js
│   ├── confluence-mock.js
│   └── context7-mock.js
├── fixtures/
│   ├── linear-issues.json
│   ├── linear-teams.json
│   ├── linear-projects.json
│   ├── jira-tickets.json
│   └── confluence-pages.json
├── scenarios/
│   ├── happy-path.json
│   ├── error-scenarios.json
│   ├── rate-limit.json
│   └── partial-failure.json
└── runners/
    ├── mock-server-manager.sh
    └── test-with-mocks.sh
```

**Key Features:**
- Fast execution (no network calls)
- Deterministic behavior
- Error scenario testing
- CI/CD friendly
- No cleanup required

### Layer 4: Performance Benchmarks

**Purpose:** Measure and track performance improvements, especially token usage reduction.

**What to Measure:**
- Token usage per command
- Command execution time
- API call count
- Cache hit rates
- Hook invocation overhead

**Technology:**
- Custom benchmark framework
- Token counting utilities
- Performance profiling
- Trend analysis

**Example Structure:**
```
tests/benchmarks/
├── token-usage/
│   ├── baseline-measurements.json
│   ├── optimized-measurements.json
│   ├── command-benchmarks.sh
│   └── hook-benchmarks.sh
├── performance/
│   ├── execution-time.sh
│   ├── cache-performance.sh
│   ├── api-call-counts.sh
│   └── memory-usage.sh
├── reports/
│   ├── token-reduction-report.md
│   ├── performance-trends.md
│   └── optimization-impact.md
└── scripts/
    ├── run-benchmarks.sh
    ├── compare-benchmarks.sh
    └── generate-report.sh
```

**Key Metrics:**
- Token usage: Baseline vs Optimized (40-60% reduction target)
- Execution time: < 5s for most commands
- Cache hit rate: 85-95% for Linear operations
- API calls: Minimize redundant calls

### Layer 5: User Acceptance Testing (UAT)

**Purpose:** Validate complete user workflows and real-world scenarios.

**What to Test:**
- Common user workflows
- Multi-command sequences
- Interactive mode navigation
- Error recovery
- User experience flows

**Technology:**
- Scenario-based test scripts
- User interaction simulation
- Workflow documentation
- Acceptance criteria validation

**Example Structure:**
```
tests/uat/
├── scenarios/
│   ├── new-feature-workflow.md
│   ├── bug-fix-workflow.md
│   ├── epic-breakdown-workflow.md
│   ├── tdd-enforcement-workflow.md
│   └── multi-project-workflow.md
├── scripts/
│   ├── run-scenario.sh
│   ├── validate-output.sh
│   └── interactive-test.sh
├── checklists/
│   ├── feature-complete.md
│   ├── quality-gates.md
│   └── release-readiness.md
└── reports/
    ├── uat-results.md
    └── user-feedback.md
```

**Key Scenarios:**
1. **Complete Feature Development**
   - `/ccpm:plan "Add authentication"`
   - `/ccpm:work`
   - `/ccpm:sync "Implemented JWT"`
   - `/ccpm:commit`
   - `/ccpm:verify`
   - `/ccpm:done`

2. **TDD Workflow**
   - Write test first (TDD enforcer blocks production code)
   - Implement feature
   - Tests pass
   - Refactor with safety

3. **Epic Breakdown**
   - Create Epic with spec
   - Write comprehensive spec
   - Review and grade spec
   - Break down into tasks
   - Implement tasks

## Test Fixtures

### Linear Test Data

```json
// tests/fixtures/linear/teams.json
{
  "teams": [
    {
      "id": "test-team-1",
      "name": "Test Team Alpha",
      "key": "TTA"
    },
    {
      "id": "test-team-2",
      "name": "Test Team Beta",
      "key": "TTB"
    }
  ]
}

// tests/fixtures/linear/issues.json
{
  "issues": [
    {
      "id": "TTA-1",
      "title": "Test Issue 1",
      "description": "Test description",
      "state": "todo",
      "labels": ["planning", "feature"],
      "teamId": "test-team-1"
    }
  ]
}

// tests/fixtures/linear/labels.json
{
  "labels": [
    {
      "id": "label-1",
      "name": "planning",
      "color": "#f7c8c1"
    },
    {
      "id": "label-2",
      "name": "implementation",
      "color": "#26b5ce"
    }
  ]
}

// tests/fixtures/linear/states.json
{
  "states": [
    {
      "id": "state-1",
      "name": "Backlog",
      "type": "backlog"
    },
    {
      "id": "state-2",
      "name": "Todo",
      "type": "unstarted"
    },
    {
      "id": "state-3",
      "name": "In Progress",
      "type": "started"
    },
    {
      "id": "state-4",
      "name": "Done",
      "type": "completed"
    }
  ]
}
```

### Jira Test Data

```json
// tests/fixtures/jira/tickets.json
{
  "tickets": [
    {
      "key": "PROJ-123",
      "summary": "Test ticket",
      "description": "Test description",
      "issueType": "Task",
      "status": "To Do"
    }
  ]
}

// tests/fixtures/jira/projects.json
{
  "projects": [
    {
      "key": "PROJ",
      "name": "Test Project"
    }
  ]
}
```

### GitHub Test Data

```json
// tests/fixtures/github/repos.json
{
  "repositories": [
    {
      "owner": "test-org",
      "name": "test-repo",
      "defaultBranch": "main"
    }
  ]
}

// tests/fixtures/github/prs.json
{
  "pullRequests": [
    {
      "number": 123,
      "title": "Test PR",
      "state": "open"
    }
  ]
}
```

## Mock MCP Server Implementation

### Architecture

```
┌──────────────────────────────────────────────┐
│         Claude Code                          │
└────────────────┬─────────────────────────────┘
                 │
                 │ MCP Protocol
                 │
┌────────────────▼─────────────────────────────┐
│         Mock MCP Gateway                     │
│  - Request routing                           │
│  - Response simulation                       │
│  - Fixture loading                           │
│  - Error injection                           │
└────────────────┬─────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
┌───────▼──────┐   ┌──────▼─────────┐
│ Linear Mock  │   │  Jira Mock     │
│ - Issues     │   │  - Tickets     │
│ - Labels     │   │  - Comments    │
│ - States     │   │  - Transitions │
└──────────────┘   └────────────────┘
```

### Mock Server Features

1. **Request Validation**
   - Validate request format
   - Check required parameters
   - Simulate authentication

2. **Response Simulation**
   - Load fixtures for responses
   - Simulate network delays
   - Return realistic data

3. **Error Injection**
   - Network errors (timeout, connection refused)
   - API errors (rate limit, permission denied)
   - Invalid data errors

4. **State Management**
   - Track created resources
   - Handle updates and deletes
   - Maintain consistency

### Implementation Example

```javascript
// tests/mocks/mcp-servers/linear-mock.js

class LinearMockServer {
  constructor(fixtures) {
    this.fixtures = fixtures;
    this.state = {
      issues: new Map(),
      labels: new Map(),
      states: new Map()
    };
  }

  async handleRequest(method, params) {
    switch (method) {
      case 'linear_create_issue':
        return this.createIssue(params);
      case 'linear_get_issue':
        return this.getIssue(params);
      case 'linear_update_issue':
        return this.updateIssue(params);
      case 'linear_list_teams':
        return this.listTeams();
      default:
        throw new Error(`Unknown method: ${method}`);
    }
  }

  createIssue(params) {
    const issue = {
      id: `issue-${Date.now()}`,
      ...params,
      createdAt: new Date().toISOString()
    };
    this.state.issues.set(issue.id, issue);
    return issue;
  }

  getIssue(params) {
    const issue = this.state.issues.get(params.id);
    if (!issue) {
      throw new Error(`Issue not found: ${params.id}`);
    }
    return issue;
  }

  // ... other methods
}

module.exports = LinearMockServer;
```

## Test Execution Strategy

### Local Development

```bash
# Quick validation (fast)
./scripts/run-all-tests.sh

# Unit tests only (< 10s)
./tests/run-unit-tests.sh

# Integration tests (real APIs, ~2-5 min)
./tests/run-integration-tests.sh

# Mock integration tests (< 1 min)
./tests/run-mock-tests.sh

# Performance benchmarks
./tests/run-benchmarks.sh

# UAT scenarios
./tests/run-uat-scenarios.sh

# Everything
./tests/run-all-test-suites.sh --verbose
```

### CI/CD Pipeline

```yaml
# .github/workflows/test-comprehensive.yml

name: Comprehensive Test Suite

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run unit tests
        run: ./tests/run-unit-tests.sh
      - name: Upload results
        uses: actions/upload-artifact@v4
        with:
          name: unit-test-results
          path: tests/results/unit/

  mock-integration:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Start mock servers
        run: ./tests/mocks/start-mock-servers.sh
      - name: Run mock integration tests
        run: ./tests/run-mock-tests.sh
      - name: Stop mock servers
        run: ./tests/mocks/stop-mock-servers.sh

  performance-benchmarks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run benchmarks
        run: ./tests/run-benchmarks.sh
      - name: Compare with baseline
        run: ./tests/benchmarks/compare-benchmarks.sh
      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: benchmark-report
          path: tests/benchmarks/reports/

  real-integration:
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Configure test workspace
        env:
          LINEAR_API_KEY: ${{ secrets.LINEAR_TEST_API_KEY }}
          LINEAR_TEST_TEAM_ID: ${{ secrets.LINEAR_TEST_TEAM_ID }}
        run: ./tests/configure-test-env.sh
      - name: Run integration tests
        run: ./tests/run-integration-tests.sh
      - name: Cleanup test data
        run: ./tests/cleanup-all-test-data.sh
```

## Performance Benchmark Framework

### Token Usage Measurement

```bash
#!/bin/bash
# tests/benchmarks/token-usage/measure-tokens.sh

measure_command_tokens() {
  local command="$1"
  local args="$2"

  # Run command with token counting enabled
  local output=$(claude-code --count-tokens "$command" $args)

  # Extract token counts
  local input_tokens=$(echo "$output" | grep "Input tokens:" | awk '{print $3}')
  local output_tokens=$(echo "$output" | grep "Output tokens:" | awk '{print $3}')
  local total_tokens=$((input_tokens + output_tokens))

  echo "{\"command\":\"$command\",\"input\":$input_tokens,\"output\":$output_tokens,\"total\":$total_tokens}"
}

# Measure baseline (without optimizations)
measure_command_tokens "/ccpm:planning:plan" "PSN-123"

# Measure optimized (with Linear subagent, caching)
measure_command_tokens "/ccpm:plan" "PSN-123"

# Calculate reduction
calculate_reduction() {
  local baseline=$1
  local optimized=$2
  local reduction=$(echo "scale=2; (($baseline - $optimized) / $baseline) * 100" | bc)
  echo "${reduction}%"
}
```

### Benchmark Reporting

```markdown
# Token Usage Benchmark Report

## Summary
- **Total Commands Tested:** 65
- **Average Token Reduction:** 52%
- **Target Achievement:** ✅ Met (40-60% target)

## By Category

### Planning Commands (7 commands)
| Command | Baseline | Optimized | Reduction |
|---------|----------|-----------|-----------|
| planning:create | 25,000 | 12,000 | 52% |
| planning:plan | 28,000 | 13,500 | 51.7% |
| planning:update | 22,000 | 10,800 | 50.9% |
| **Average** | 25,000 | 12,100 | **51.6%** |

### Implementation Commands (4 commands)
| Command | Baseline | Optimized | Reduction |
|---------|----------|-----------|-----------|
| implementation:start | 20,000 | 9,600 | 52% |
| implementation:sync | 15,000 | 7,200 | 52% |
| **Average** | 17,500 | 8,400 | **52%** |

## Cache Performance

- **Cache Hit Rate:** 92%
- **Cache Miss Penalty:** 400-600ms
- **Average Response Time (cached):** < 50ms
- **Average Response Time (uncached):** 500ms

## Recommendations

1. ✅ Token reduction target met (52% average)
2. ✅ Cache hit rate exceeds target (92% vs 85% target)
3. ⚠️ Some commands exceed 5s execution time
4. 💡 Consider additional caching for project operations
```

## Test Documentation Requirements

### Test Case Template

```markdown
# Test Case: [Command Name]

## Test ID
TC-[Category]-[Number]

## Description
Brief description of what this test validates

## Prerequisites
- Linear test workspace configured
- Test team ID: test-team-1
- Test project exists

## Test Steps
1. Execute command: `/ccpm:planning:create "Test task" test-project`
2. Verify Linear issue created
3. Check labels applied correctly
4. Verify state is correct

## Expected Results
- ✅ Issue created with correct title
- ✅ Labels: planning, feature
- ✅ State: Backlog
- ✅ Description contains checklist

## Actual Results
[To be filled during test execution]

## Pass/Fail
[ ] Pass
[ ] Fail

## Notes
Additional observations or issues
```

### Test Run Documentation

```markdown
# Test Run Report: [Date]

## Environment
- Plugin Version: 2.0.0
- Linear MCP Version: X.X.X
- Test Workspace: ccpm-test-workspace
- Test Team: test-team-1

## Summary
- **Total Tests:** 150
- **Passed:** 147
- **Failed:** 3
- **Skipped:** 0
- **Pass Rate:** 98%

## Failed Tests

### TC-PLAN-003: planning:update with invalid issue
- **Error:** Issue not found: PSN-999
- **Root Cause:** Test fixture missing
- **Fix:** Add issue to fixtures
- **Status:** In Progress

## Performance Metrics
- Average execution time: 2.3s
- Token usage reduction: 52%
- Cache hit rate: 92%

## Recommendations
1. Fix failed tests
2. Add more edge case coverage
3. Improve error messages
```

## Test Maintenance Strategy

### Regular Maintenance Tasks

1. **Weekly:**
   - Run full test suite
   - Review failed tests
   - Update fixtures as needed

2. **Monthly:**
   - Review test coverage
   - Add tests for new features
   - Update benchmarks

3. **Quarterly:**
   - Comprehensive test review
   - Performance benchmark analysis
   - Test infrastructure improvements

### Test Coverage Goals

- **Command Coverage:** 100% (all 65+ commands)
- **Integration Coverage:** 90% (critical workflows)
- **Error Scenario Coverage:** 80% (common errors)
- **Performance Benchmarks:** 100% (all commands)

## Implementation Roadmap

### Phase 5.1: Foundation (Week 1)
- ✅ Test framework architecture document
- ⏳ Mock MCP server implementation
- ⏳ Test fixtures creation
- ⏳ Basic test runners

### Phase 5.2: Integration Tests (Week 2)
- ⏳ Command integration tests
- ⏳ Workflow integration tests
- ⏳ Cleanup utilities

### Phase 5.3: Performance (Week 3)
- ⏳ Token usage benchmarks
- ⏳ Performance profiling
- ⏳ Benchmark reporting

### Phase 5.4: UAT & CI/CD (Week 4)
- ⏳ UAT scenarios
- ⏳ CI/CD integration
- ⏳ Test documentation
- ⏳ Runbook creation

## Success Criteria

### Must Have
- ✅ All 65+ commands have integration tests
- ✅ Mock MCP servers for all external systems
- ✅ Performance benchmarks showing 40-60% token reduction
- ✅ CI/CD pipeline with automated testing
- ✅ Test documentation and runbook

### Nice to Have
- Unit tests for all helper functions
- Property-based testing for edge cases
- Mutation testing for test quality
- Load testing for concurrent operations
- Visual regression testing for UI commands

## Resources

- [Existing Testing Infrastructure](../../docs/development/testing-infrastructure.md)
- [Linear Integration Tests](../../tests/integration/README.md)
- [Plugin Validation Scripts](../../scripts/)
- [Performance Optimization](../../docs/development/hook-performance-optimization.md)

---

**Document Version:** 1.0
**Created:** November 21, 2025
**Status:** Foundation Complete
**Next Phase:** Mock MCP Implementation
