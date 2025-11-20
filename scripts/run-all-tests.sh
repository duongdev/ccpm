#!/bin/bash

#######################################
# CCPM Plugin Test Suite Runner
#
# Runs all validation and testing:
# - Plugin validation (commands, skills, hooks)
# - Skill auto-activation testing
# - Hook integrity verification
# - Local marketplace testing
#
# Usage: ./scripts/run-all-tests.sh [--verbose] [--fix] [--ci]
#######################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Options
VERBOSE=false
FIX_ISSUES=false
CI_MODE=false
ONLY_TESTS=""

# Results tracking
declare -A TEST_RESULTS
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
START_TIME=$(date +%s)

# Helper functions
log_header() {
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║ $1${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_suite() {
    echo -e "${BLUE}▶${NC} Running: $1"
}

log_suite_pass() {
    echo -e "${GREEN}✓${NC} $1 PASSED"
    TEST_RESULTS["$1"]="PASSED"
    ((PASSED_SUITES++))
}

log_suite_fail() {
    echo -e "${RED}✗${NC} $1 FAILED"
    TEST_RESULTS["$1"]="FAILED"
    ((FAILED_SUITES++))
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

# Test suite runners
run_plugin_validation() {
    local suite_name="Plugin Validation"
    ((TOTAL_SUITES++))

    log_suite "$suite_name"

    local args=""
    [[ "$VERBOSE" == true ]] && args="$args --verbose"
    [[ "$FIX_ISSUES" == true ]] && args="$args --fix"

    if "$SCRIPT_DIR/validate-plugin.sh" $args; then
        log_suite_pass "$suite_name"
        return 0
    else
        log_suite_fail "$suite_name"
        return 1
    fi
}

run_skill_activation_tests() {
    local suite_name="Skill Auto-Activation"
    ((TOTAL_SUITES++))

    log_suite "$suite_name"

    local args=""
    [[ "$VERBOSE" == true ]] && args="$args --verbose"

    if "$SCRIPT_DIR/test-skill-activation.sh" $args; then
        log_suite_pass "$suite_name"
        return 0
    else
        log_suite_fail "$suite_name"
        return 1
    fi
}

run_hook_verification() {
    local suite_name="Hook Integrity"
    ((TOTAL_SUITES++))

    log_suite "$suite_name"

    local args=""
    [[ "$VERBOSE" == true ]] && args="$args --verbose"
    [[ "$FIX_ISSUES" == true ]] && args="$args --fix"

    if "$SCRIPT_DIR/verify-hook-integrity.sh" $args; then
        log_suite_pass "$suite_name"
        return 0
    else
        log_suite_fail "$suite_name"
        return 1
    fi
}

run_marketplace_tests() {
    local suite_name="Local Marketplace Setup"
    ((TOTAL_SUITES++))

    log_suite "$suite_name"

    # Test verification without install/uninstall
    if "$SCRIPT_DIR/setup-local-marketplace.sh" --test; then
        log_suite_pass "$suite_name"
        return 0
    else
        log_suite_fail "$suite_name"
        return 1
    fi
}

# Test execution with error handling
run_test_suite() {
    local suite_func="$1"
    local suite_name="${suite_func#run_}"
    suite_name="${suite_name//_/ }"

    # Check if this is a selected test
    if [[ -n "$ONLY_TESTS" ]]; then
        if ! echo "$ONLY_TESTS" | grep -qi "$suite_name"; then
            return 0
        fi
    fi

    # Run test suite
    "$@" 2>&1
    return $?
}

show_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    echo ""
    log_header "Test Results Summary"

    echo -e "Test Suites Run:     ${BLUE}$TOTAL_SUITES${NC}"
    echo -e "Passed:              ${GREEN}$PASSED_SUITES${NC}"
    echo -e "Failed:              ${RED}$FAILED_SUITES${NC}"
    echo -e "Duration:            ${BLUE}${minutes}m ${seconds}s${NC}"
    echo ""

    # Results by suite
    echo "Results by Suite:"
    for suite in "${!TEST_RESULTS[@]}"; do
        local status="${TEST_RESULTS[$suite]}"
        if [[ "$status" == "PASSED" ]]; then
            echo -e "  ${GREEN}✓${NC} $suite"
        else
            echo -e "  ${RED}✗${NC} $suite"
        fi
    done
    echo ""

    if [[ $FAILED_SUITES -eq 0 ]]; then
        echo -e "${GREEN}✓ All test suites PASSED${NC}"
        return 0
    else
        echo -e "${RED}✗ $FAILED_SUITES test suite(s) FAILED${NC}"
        return 1
    fi
}

show_usage() {
    cat << 'EOF'
CCPM Plugin Test Suite Runner

Usage: ./scripts/run-all-tests.sh [OPTIONS]

Options:
  --verbose              Show detailed output from all test suites
  --fix                  Auto-fix fixable issues (permissions, etc.)
  --ci                   CI/CD mode (exit codes, minimal formatting)
  --only SUITE_NAME      Run only specific test suite(s)
  --help                 Show this help message

Test Suites:
  - Plugin Validation    (commands, skills, hooks, files)
  - Skill Auto-Activation (skill structure, discovery, triggers)
  - Hook Integrity       (hook files, dependencies, syntax)
  - Local Marketplace    (marketplace registration, discovery)

Examples:
  # Run all tests
  ./scripts/run-all-tests.sh

  # Run with verbose output
  ./scripts/run-all-tests.sh --verbose

  # Auto-fix issues and run
  ./scripts/run-all-tests.sh --fix

  # CI/CD mode (clean output)
  ./scripts/run-all-tests.sh --ci

  # Run only specific suite
  ./scripts/run-all-tests.sh --only "Plugin Validation"

  # Run multiple suites
  ./scripts/run-all-tests.sh --only "Plugin|Skill|Hook"

Exit Codes:
  0  All tests passed
  1  One or more tests failed
  2  Invalid arguments

EOF
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_info "Tests exited with code: $exit_code"
    fi
    exit $exit_code
}

trap cleanup EXIT

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --fix)
            FIX_ISSUES=true
            shift
            ;;
        --ci)
            CI_MODE=true
            shift
            ;;
        --only)
            ONLY_TESTS="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 2
            ;;
    esac
done

# Main execution
if [[ "$CI_MODE" != true ]]; then
    log_header "CCPM Plugin Test Suite"
    log_info "Starting comprehensive plugin tests..."
    log_info "Mode: $([ "$VERBOSE" == true ] && echo "Verbose" || echo "Normal")"
    log_info "Fixes: $([ "$FIX_ISSUES" == true ] && echo "Enabled" || echo "Disabled")"
    echo ""
fi

# Run test suites in order
local_failed=false

run_test_suite run_plugin_validation || local_failed=true
run_test_suite run_skill_activation_tests || local_failed=true
run_test_suite run_hook_verification || local_failed=true
run_test_suite run_marketplace_tests || local_failed=true

# Show summary
if [[ "$CI_MODE" != true ]]; then
    show_summary || local_failed=true
fi

# Exit with appropriate code
if [[ "$local_failed" == true ]]; then
    exit 1
else
    exit 0
fi
