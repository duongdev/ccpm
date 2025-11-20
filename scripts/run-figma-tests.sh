#!/bin/bash
# run-figma-tests.sh - Test suite for Figma MCP integration
# Part of CCPM Figma MCP integration (PSN-25)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function: run_test
run_test() {
    local test_name="$1"
    local test_command="$2"

    echo -n "Testing: $test_name ... "

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "=========================================="
echo "CCPM Figma Integration Test Suite"
echo "=========================================="
echo ""

# Phase 1 Tests
echo "Phase 1: Foundation Tests"
echo "------------------------------------------"

run_test "figma-utils.sh exists" "[ -f scripts/figma-utils.sh ]"
run_test "figma-utils.sh is executable" "[ -x scripts/figma-utils.sh ]"

run_test "figma-server-manager.sh exists" "[ -f scripts/figma-server-manager.sh ]"
run_test "figma-cache-manager.sh exists" "[ -f scripts/figma-cache-manager.sh ]"
run_test "figma-rate-limiter.sh exists" "[ -f scripts/figma-rate-limiter.sh ]"

echo ""
echo "Phase 3: Design Analysis Tests"
echo "------------------------------------------"

run_test "figma-design-analyzer.sh exists" "[ -f scripts/figma-design-analyzer.sh ]"
run_test "figma-design-analyzer.sh is executable" "[ -x scripts/figma-design-analyzer.sh ]"

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
