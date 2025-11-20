#!/bin/bash

#######################################
# Integration Test: /ccpm:plan
#
# Tests the natural workflow planning command
#
# Usage: ./plan.test.sh
#######################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TEST_RESULTS_DIR="$SCRIPT_DIR/../../../results/integration"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Test state
TEST_NAME="workflow:plan"
TEST_CATEGORY="workflow"
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# Mock server configuration
LINEAR_MOCK_PORT=3001
JIRA_MOCK_PORT=3002

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[PASS]${NC} $*"
}

log_failure() {
  echo -e "${RED}[FAIL]${NC} $*"
}

# Test assertion functions
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-String should contain substring}"

  TEST_COUNT=$((TEST_COUNT + 1))

  if echo "$haystack" | grep -q "$needle"; then
    PASS_COUNT=$((PASS_COUNT + 1))
    log_success "$message"
    return 0
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    log_failure "$message"
    log_failure "  Looking for: $needle"
    return 1
  fi
}

assert_http_success() {
  local url="$1"
  local message="${2:-HTTP request should succeed}"

  TEST_COUNT=$((TEST_COUNT + 1))

  local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")

  if [[ "$status_code" =~ ^2[0-9][0-9]$ ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    log_success "$message (HTTP $status_code)"
    return 0
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    log_failure "$message (HTTP $status_code)"
    return 1
  fi
}

# Mock API helpers
call_linear_api() {
  local method="$1"
  local params="$2"

  curl -s -X POST "http://localhost:$LINEAR_MOCK_PORT" \
    -H "Content-Type: application/json" \
    -d "{\"method\": \"$method\", \"params\": $params}" 2>/dev/null || echo '{"error": "connection failed"}'
}

verify_mock_server() {
  local port="$1"
  local name="$2"

  if curl -s "http://localhost:$port/stats" > /dev/null 2>&1; then
    log_info "$name mock server is running on port $port"
    return 0
  else
    log_failure "$name mock server is not running on port $port"
    return 1
  fi
}

# Test setup and teardown
setup() {
  log_info "Setting up test environment for $TEST_NAME..."

  mkdir -p "$TEST_RESULTS_DIR"

  # Verify required mock servers
  verify_mock_server "$LINEAR_MOCK_PORT" "Linear" || {
    log_failure "Linear mock server required but not running"
    log_info "Start with: node tests/mocks/mcp-servers/linear-mock.js"
    return 1
  }

  # Reset mock server state
  curl -s -X POST "http://localhost:$LINEAR_MOCK_PORT/reset" > /dev/null 2>&1

  log_success "Test environment ready"
}

teardown() {
  log_info "Cleaning up test environment..."

  # Generate test report
  local report_file="$TEST_RESULTS_DIR/workflow-plan.json"
  local pass_rate=0

  if [[ $TEST_COUNT -gt 0 ]]; then
    pass_rate=$(echo "scale=2; ($PASS_COUNT / $TEST_COUNT) * 100" | bc)
  fi

  cat > "$report_file" <<EOF
{
  "test": "$TEST_NAME",
  "category": "$TEST_CATEGORY",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "summary": {
    "total": $TEST_COUNT,
    "passed": $PASS_COUNT,
    "failed": $FAIL_COUNT,
    "skipped": $SKIP_COUNT,
    "pass_rate": $pass_rate
  },
  "status": "$([ $FAIL_COUNT -eq 0 ] && echo "PASS" || echo "FAIL")"
}
EOF

  log_info "Test report saved to $report_file"
}

# Test Cases

test_mode_1_create_task() {
  log_info "Test: Mode 1 - Create new task with title"

  # Simulate: /ccpm:plan "Add user authentication" my-project
  # Should create Linear issue

  local result=$(call_linear_api "linear_create_issue" '{
    "title": "Add user authentication",
    "teamId": "test-team-1",
    "description": "Test task creation"
  }')

  assert_contains "$result" "issue-" "Should create issue with ID"
  assert_contains "$result" "Add user authentication" "Should have correct title"
}

test_mode_2_plan_existing() {
  log_info "Test: Mode 2 - Plan existing issue"

  # First create an issue
  local create_result=$(call_linear_api "linear_create_issue" '{
    "title": "Existing task",
    "teamId": "test-team-1"
  }')

  local issue_id=$(echo "$create_result" | grep -o 'TTA-[0-9]*' || echo "TTA-1")

  # Now get it (simulating planning)
  local result=$(call_linear_api "linear_get_issue" "{\"issueId\": \"$issue_id\"}")

  assert_contains "$result" "$issue_id" "Should retrieve existing issue"
}

test_mode_3_update_plan() {
  log_info "Test: Mode 3 - Update existing plan"

  # Create issue
  local create_result=$(call_linear_api "linear_create_issue" '{
    "title": "Task to update",
    "teamId": "test-team-1",
    "description": "Original plan"
  }')

  local issue_id=$(echo "$create_result" | grep -o 'TTA-[0-9]*' || echo "TTA-1")

  # Update it
  local result=$(call_linear_api "linear_update_issue" "{
    \"issueId\": \"$issue_id\",
    \"updates\": {
      \"description\": \"Updated plan with new requirements\"
    }
  }")

  assert_contains "$result" "Updated plan" "Should update description"
}

test_error_invalid_team() {
  log_info "Test: Error handling - Invalid team"

  local result=$(call_linear_api "linear_create_issue" '{
    "title": "Test task",
    "teamId": "invalid-team"
  }')

  assert_contains "$result" "error" "Should return error for invalid team"
}

test_mock_server_health() {
  log_info "Test: Mock server health check"

  assert_http_success "http://localhost:$LINEAR_MOCK_PORT/stats" "Linear mock should be healthy"
}

# Main test execution
main() {
  echo ""
  echo "========================================="
  echo "  Integration Test: $TEST_NAME"
  echo "========================================="
  echo ""

  # Setup
  setup || exit 1

  # Run tests
  test_mode_1_create_task
  test_mode_2_plan_existing
  test_mode_3_update_plan
  test_error_invalid_team
  test_mock_server_health

  # Teardown
  teardown

  # Print summary
  echo ""
  echo "========================================="
  echo "  Test Summary"
  echo "========================================="
  echo -e "Total:   $TEST_COUNT"
  echo -e "${GREEN}Passed:  $PASS_COUNT${NC}"
  echo -e "${RED}Failed:  $FAIL_COUNT${NC}"
  echo -e "${YELLOW}Skipped: $SKIP_COUNT${NC}"
  echo ""

  # Exit with appropriate code
  if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

# Run tests
main "$@"
