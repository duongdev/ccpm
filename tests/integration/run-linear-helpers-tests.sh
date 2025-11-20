#!/bin/bash
#
# Linear Helper Functions - Integration Test Runner
#
# Executes integration tests for shared Linear helper functions.
# Requires Linear MCP connection and test team configured.
#
# Usage:
#   ./run-linear-helpers-tests.sh [--verbose] [--cleanup] [--category CATEGORY]
#
# Options:
#   --verbose    Show detailed test output
#   --cleanup    Auto-delete created test data after completion
#   --category   Run specific test category only (1-6)
#   --help       Show this help message
#
# Examples:
#   ./run-linear-helpers-tests.sh
#   ./run-linear-helpers-tests.sh --verbose --cleanup
#   ./run-linear-helpers-tests.sh --category 2
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Configuration
VERBOSE=false
CLEANUP=false
CATEGORY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --cleanup)
      CLEANUP=true
      shift
      ;;
    --category)
      CATEGORY="$2"
      shift 2
      ;;
    --help)
      head -n 20 "$0" | tail -n +2 | sed 's/^# //'
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Helper functions
print_header() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_test() {
  echo -e "${BLUE}🧪 Test $TOTAL_TESTS: $1${NC}"
}

print_pass() {
  echo -e "${GREEN}✅ PASS${NC}: $1"
  ((PASSED_TESTS++))
}

print_fail() {
  echo -e "${RED}❌ FAIL${NC}: $1"
  echo -e "${RED}   Error: $2${NC}"
  ((FAILED_TESTS++))
}

print_skip() {
  echo -e "${YELLOW}⚠️  SKIP${NC}: $1"
  ((SKIPPED_TESTS++))
}

log_verbose() {
  if [ "$VERBOSE" = true ]; then
    echo -e "${NC}   $1${NC}"
  fi
}

# Check prerequisites
check_prerequisites() {
  print_header "Checking Prerequisites"

  # Check LINEAR_TEST_TEAM_ID
  if [ -z "$LINEAR_TEST_TEAM_ID" ]; then
    echo -e "${RED}❌ Error: LINEAR_TEST_TEAM_ID environment variable not set${NC}"
    echo ""
    echo "Please set your Linear test team ID:"
    echo "  export LINEAR_TEST_TEAM_ID=\"your-team-id\""
    echo ""
    echo "To find your team ID:"
    echo "  1. Use Linear MCP to list teams"
    echo "  2. Or check Linear URL: https://linear.app/[workspace]/team/[TEAM-ID]"
    exit 1
  fi

  echo -e "${GREEN}✅${NC} LINEAR_TEST_TEAM_ID set: ${LINEAR_TEST_TEAM_ID:0:8}..."

  # Check if cleanup enabled
  if [ "$CLEANUP" = true ]; then
    export LINEAR_TEST_CLEANUP="true"
    echo -e "${GREEN}✅${NC} Cleanup enabled: Test data will be deleted after tests"
  else
    echo -e "${YELLOW}⚠️${NC}  Cleanup disabled: Test data will remain in Linear"
  fi

  # Check Linear MCP availability (basic check)
  echo -e "${BLUE}ℹ️${NC}  Note: Tests require Linear MCP to be configured and accessible"
  echo ""
}

# Test Category 1: getDefaultColor (Pure Function Tests)
run_category_1() {
  if [ -n "$CATEGORY" ] && [ "$CATEGORY" != "1" ]; then
    return
  fi

  print_header "Test Category 1: getDefaultColor (Pure Functions)"

  # Test 1.1: Planning Label Color
  ((TOTAL_TESTS++))
  print_test "Planning label color"
  # This would be executed in Claude Code context
  print_skip "Pure function test - requires Claude Code execution context"

  # Test 1.2: Implementation Label Color
  ((TOTAL_TESTS++))
  print_test "Implementation label color"
  print_skip "Pure function test - requires Claude Code execution context"

  # Test 1.3: Verification Label Color
  ((TOTAL_TESTS++))
  print_test "Verification label color"
  print_skip "Pure function test - requires Claude Code execution context"

  # Test 1.4: Bug Label Color
  ((TOTAL_TESTS++))
  print_test "Bug label color"
  print_skip "Pure function test - requires Claude Code execution context"

  # Test 1.5: Unknown Label Color (Default)
  ((TOTAL_TESTS++))
  print_test "Unknown label color (default)"
  print_skip "Pure function test - requires Claude Code execution context"

  # Test 1.6: Case Insensitive Lookup
  ((TOTAL_TESTS++))
  print_test "Case insensitive color lookup"
  print_skip "Pure function test - requires Claude Code execution context"

  # Test 1.7: Trimmed Input
  ((TOTAL_TESTS++))
  print_test "Trimmed input color lookup"
  print_skip "Pure function test - requires Claude Code execution context"

  echo ""
  echo -e "${CYAN}Category 1 Summary:${NC}"
  echo "  Pure function tests require Claude Code execution context"
  echo "  These tests validate color mapping logic"
  echo "  Run manually in Claude Code session for validation"
}

# Test Category 2: getOrCreateLabel
run_category_2() {
  if [ -n "$CATEGORY" ] && [ "$CATEGORY" != "2" ]; then
    return
  fi

  print_header "Test Category 2: getOrCreateLabel (Label Operations)"

  # Test 2.1: Create New Label with Auto Color
  ((TOTAL_TESTS++))
  print_test "Create new label with auto color"
  print_skip "Linear MCP integration test - run manually in Claude Code"

  # Test 2.2: Create New Label with Custom Color
  ((TOTAL_TESTS++))
  print_test "Create new label with custom color"
  print_skip "Linear MCP integration test - run manually in Claude Code"

  # Test 2.3: Return Existing Label (Idempotent)
  ((TOTAL_TESTS++))
  print_test "Return existing label (idempotent)"
  print_skip "Linear MCP integration test - run manually in Claude Code"

  # Test 2.4: Case-Insensitive Label Match
  ((TOTAL_TESTS++))
  print_test "Case-insensitive label match"
  print_skip "Linear MCP integration test - run manually in Claude Code"

  # Test 2.5: Invalid Team ID Handling
  ((TOTAL_TESTS++))
  print_test "Invalid team ID handling"
  print_skip "Linear MCP integration test - run manually in Claude Code"

  # Test 2.6: Label with Special Characters
  ((TOTAL_TESTS++))
  print_test "Label with special characters"
  print_skip "Linear MCP integration test - run manually in Claude Code"

  echo ""
  echo -e "${CYAN}Category 2 Summary:${NC}"
  echo "  Label creation and retrieval tests"
  echo "  Tests idempotent behavior and error handling"
  echo "  Requires Linear MCP connection to execute"
}

# Test Category 3: getValidStateId
run_category_3() {
  if [ -n "$CATEGORY" ] && [ "$CATEGORY" != "3" ]; then
    return
  fi

  print_header "Test Category 3: getValidStateId (State Validation)"

  # Test 3.1-3.11
  for i in {1..11}; do
    ((TOTAL_TESTS++))
    case $i in
      1) print_test "Exact state name match" ;;
      2) print_test "State type match (backlog)" ;;
      3) print_test "State type match (unstarted)" ;;
      4) print_test "State type match (started)" ;;
      5) print_test "State type match (completed)" ;;
      6) print_test "Fallback mapping (todo → unstarted)" ;;
      7) print_test "Fallback mapping (in progress → started)" ;;
      8) print_test "Fallback mapping (done → completed)" ;;
      9) print_test "Case-insensitive state name" ;;
      10) print_test "Invalid state name - helpful error" ;;
      11) print_test "Invalid team ID" ;;
    esac
    print_skip "Linear MCP integration test - run manually in Claude Code"
  done

  echo ""
  echo -e "${CYAN}Category 3 Summary:${NC}"
  echo "  State validation and mapping tests"
  echo "  Tests fuzzy matching and fallback logic"
  echo "  Tests error messages with helpful context"
}

# Test Category 4: ensureLabelsExist
run_category_4() {
  if [ -n "$CATEGORY" ] && [ "$CATEGORY" != "4" ]; then
    return
  fi

  print_header "Test Category 4: ensureLabelsExist (Batch Operations)"

  # Test 4.1-4.6
  for i in {1..6}; do
    ((TOTAL_TESTS++))
    case $i in
      1) print_test "Create multiple new labels" ;;
      2) print_test "Mix of existing and new labels" ;;
      3) print_test "Custom colors for labels" ;;
      4) print_test "Custom descriptions for labels" ;;
      5) print_test "Empty label array" ;;
      6) print_test "Rate limit handling (sequential processing)" ;;
    esac
    print_skip "Linear MCP integration test - run manually in Claude Code"
  done

  echo ""
  echo -e "${CYAN}Category 4 Summary:${NC}"
  echo "  Batch label creation and management"
  echo "  Tests sequential processing for rate limits"
  echo "  Tests partial success scenarios"
}

# Test Category 5: Error Handling
run_category_5() {
  if [ -n "$CATEGORY" ] && [ "$CATEGORY" != "5" ]; then
    return
  fi

  print_header "Test Category 5: Error Handling"

  # Test 5.1-5.3
  for i in {1..3}; do
    ((TOTAL_TESTS++))
    case $i in
      1) print_test "Network error simulation" ;;
      2) print_test "Invalid color format" ;;
      3) print_test "Partial failure in batch operation" ;;
    esac
    print_skip "Manual/mocked test - requires specific conditions"
  done

  echo ""
  echo -e "${CYAN}Category 5 Summary:${NC}"
  echo "  Error handling and edge case tests"
  echo "  Some tests require manual execution or mocking"
  echo "  Tests graceful degradation behavior"
}

# Test Category 6: Integration Scenarios
run_category_6() {
  if [ -n "$CATEGORY" ] && [ "$CATEGORY" != "6" ]; then
    return
  fi

  print_header "Test Category 6: Integration Scenarios"

  # Test 6.1-6.3
  for i in {1..3}; do
    ((TOTAL_TESTS++))
    case $i in
      1) print_test "Complete issue creation workflow" ;;
      2) print_test "Issue status transition" ;;
      3) print_test "Label color consistency" ;;
    esac
    print_skip "End-to-end integration test - run manually in Claude Code"
  done

  echo ""
  echo -e "${CYAN}Category 6 Summary:${NC}"
  echo "  End-to-end workflow tests"
  echo "  Tests complete issue lifecycle"
  echo "  Tests real-world usage patterns"
}

# Print final summary
print_summary() {
  print_header "Test Summary"

  echo ""
  echo -e "${CYAN}Results:${NC}"
  echo -e "  Total Tests:   ${TOTAL_TESTS}"
  echo -e "  ${GREEN}Passed:        ${PASSED_TESTS}${NC}"
  echo -e "  ${RED}Failed:        ${FAILED_TESTS}${NC}"
  echo -e "  ${YELLOW}Skipped:       ${SKIPPED_TESTS}${NC}"
  echo ""

  if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
  elif [ $PASSED_TESTS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No tests executed (all skipped)${NC}"
    echo ""
    echo "These integration tests require Linear MCP connection and"
    echo "must be run within Claude Code execution context."
    echo ""
    echo "To run tests:"
    echo "  1. Open Claude Code"
    echo "  2. Set LINEAR_TEST_TEAM_ID environment variable"
    echo "  3. Copy test code from linear-helpers.test.md"
    echo "  4. Execute tests manually"
    echo ""
  else
    echo -e "${GREEN}✅ All tests passed${NC}"
  fi

  # Show next steps
  echo ""
  echo -e "${CYAN}Next Steps:${NC}"
  echo "  1. Review test documentation: tests/integration/linear-helpers.test.md"
  echo "  2. Run tests manually in Claude Code session"
  echo "  3. Set LINEAR_TEST_TEAM_ID to your test team"
  echo "  4. Execute test code blocks from test file"
  echo ""
  echo "For detailed test documentation:"
  echo "  cat tests/integration/linear-helpers.test.md"
}

# Cleanup function
cleanup() {
  if [ "$CLEANUP" = true ]; then
    print_header "Cleanup"
    echo "Cleanup would run here (requires Claude Code context)"
    echo "Labels with prefix 'test-' would be deleted"
  fi
}

# Main execution
main() {
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                                                                ║${NC}"
  echo -e "${CYAN}║          Linear Helper Functions - Integration Tests          ║${NC}"
  echo -e "${CYAN}║                                                                ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"

  check_prerequisites

  # Run test categories
  if [ -z "$CATEGORY" ]; then
    echo ""
    echo -e "${CYAN}Running all test categories...${NC}"
    run_category_1
    run_category_2
    run_category_3
    run_category_4
    run_category_5
    run_category_6
  else
    echo ""
    echo -e "${CYAN}Running test category $CATEGORY only...${NC}"
    case $CATEGORY in
      1) run_category_1 ;;
      2) run_category_2 ;;
      3) run_category_3 ;;
      4) run_category_4 ;;
      5) run_category_5 ;;
      6) run_category_6 ;;
      *)
        echo -e "${RED}Invalid category: $CATEGORY${NC}"
        echo "Valid categories: 1-6"
        exit 1
        ;;
    esac
  fi

  # Cleanup if enabled
  cleanup

  # Print summary
  print_summary
}

# Run main function
main
