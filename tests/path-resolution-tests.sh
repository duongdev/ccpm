#!/bin/bash
################################################################################
# CCPM Path Resolution Test Suite
#
# Purpose: Comprehensive testing of path resolution and standardization
# Usage:   ./path-resolution-tests.sh [--verbose] [--coverage]
#
# Test Categories:
#   1. Path Variable Resolution
#   2. Directory Existence
#   3. File Existence
#   4. Path Portability
#   5. Environment Detection
#   6. Error Handling
################################################################################

set -euo pipefail

# Test configuration
readonly TEST_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly REPO_ROOT="$(dirname "$TEST_SCRIPT_DIR")"
readonly RESOLVE_PATHS_SCRIPT="$REPO_ROOT/scripts/resolve-paths.sh"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly GRAY='\033[0;37m'
readonly NC='\033[0m'

# Flags
VERBOSE=0
COVERAGE=0

################################################################################
# Test Framework Functions
################################################################################

# Initialize test framework
init_tests() {
  echo ""
  echo "========================================================================"
  echo "CCPM Path Resolution Test Suite"
  echo "========================================================================"
  echo ""
  echo "Repository: $REPO_ROOT"
  echo "Test Suite: $TEST_SCRIPT_DIR"
  echo "Resolver: $RESOLVE_PATHS_SCRIPT"
  echo ""
}

# Print test header
test_group() {
  local group_name="$1"
  echo ""
  echo -e "${BLUE}## $group_name${NC}"
  echo ""
}

# Test assertion: passes
assert_pass() {
  local test_name="$1"
  ((TESTS_TOTAL++))
  ((TESTS_PASSED++))
  echo -e "${GREEN}✓${NC} $test_name"
  [ $VERBOSE -eq 1 ] && echo "  PASS"
}

# Test assertion: fails
assert_fail() {
  local test_name="$1"
  local reason="${2:-}"
  ((TESTS_TOTAL++))
  ((TESTS_FAILED++))
  echo -e "${RED}✗${NC} $test_name"
  [ -n "$reason" ] && echo "  Reason: $reason"
}

# Test assertion: skipped
assert_skip() {
  local test_name="$1"
  local reason="${2:-}"
  ((TESTS_TOTAL++))
  ((TESTS_SKIPPED++))
  echo -e "${YELLOW}⊘${NC} $test_name"
  [ -n "$reason" ] && echo "  Reason: $reason"
}

# Assert condition
assert_true() {
  local test_name="$1"
  local condition="$2"
  if eval "$condition"; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name" "Condition failed: $condition"
  fi
}

# Assert file exists
assert_file_exists() {
  local test_name="$1"
  local filepath="$2"
  if [ -f "$filepath" ]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name" "File not found: $filepath"
  fi
}

# Assert directory exists
assert_dir_exists() {
  local test_name="$1"
  local dirpath="$2"
  if [ -d "$dirpath" ]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name" "Directory not found: $dirpath"
  fi
}

# Assert variable is set
assert_var_set() {
  local test_name="$1"
  local var_name="$2"
  if [ -n "${!var_name:-}" ]; then
    assert_pass "$test_name"
  else
    assert_fail "$test_name" "Variable not set: $var_name"
  fi
}

# Print test summary
print_summary() {
  echo ""
  echo "========================================================================"
  echo "Test Summary"
  echo "========================================================================"
  echo ""
  echo -e "Total Tests:  $TESTS_TOTAL"
  echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
  [ $TESTS_FAILED -gt 0 ] && echo -e "${RED}Failed:       $TESTS_FAILED${NC}" || echo "Failed:       0"
  [ $TESTS_SKIPPED -gt 0 ] && echo -e "${YELLOW}Skipped:      $TESTS_SKIPPED${NC}" || echo "Skipped:      0"
  echo ""

  local pass_rate=0
  if [ $TESTS_TOTAL -gt 0 ]; then
    pass_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
  fi

  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}Result: ALL TESTS PASSED (${pass_rate}%)${NC}"
    return 0
  else
    echo -e "${RED}Result: SOME TESTS FAILED (${pass_rate}% pass rate)${NC}"
    return 1
  fi
}

################################################################################
# Test Cases
################################################################################

# Test 1: Script exists and is executable
test_resolver_exists() {
  test_group "Test 1: Resolver Script Availability"

  assert_file_exists "Resolver script exists" "$RESOLVE_PATHS_SCRIPT"
  assert_true "Resolver script is executable" "[ -x '$RESOLVE_PATHS_SCRIPT' ]"
}

# Test 2: Path resolution basic functionality
test_path_resolution() {
  test_group "Test 2: Path Resolution Functionality"

  # Source the script and resolve paths in a subshell
  (
    source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null
    if [ -z "${CCPM_PLUGIN_DIR:-}" ]; then
      exit 1
    fi
  ) || {
    assert_fail "Path resolution initializes" "Script failed to source"
    return 1
  }

  # Now actually test the variables
  (
    source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null
    [ -n "${CCPM_PLUGIN_DIR:-}" ]
  ) && assert_pass "CCPM_PLUGIN_DIR is set" || assert_fail "CCPM_PLUGIN_DIR is set"

  (
    source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null
    [ -n "${CCPM_COMMANDS_DIR:-}" ]
  ) && assert_pass "CCPM_COMMANDS_DIR is set" || assert_fail "CCPM_COMMANDS_DIR is set"

  (
    source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null
    [ -n "${CCPM_AGENTS_DIR:-}" ]
  ) && assert_pass "CCPM_AGENTS_DIR is set" || assert_fail "CCPM_AGENTS_DIR is set"

  (
    source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null
    [ -n "${CCPM_HOOKS_DIR:-}" ]
  ) && assert_pass "CCPM_HOOKS_DIR is set" || assert_fail "CCPM_HOOKS_DIR is set"

  (
    source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null
    [ -n "${CCPM_SCRIPTS_DIR:-}" ]
  ) && assert_pass "CCPM_SCRIPTS_DIR is set" || assert_fail "CCPM_SCRIPTS_DIR is set"

  (
    source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null
    [ -n "${CCPM_DOCS_DIR:-}" ]
  ) && assert_pass "CCPM_DOCS_DIR is set" || assert_fail "CCPM_DOCS_DIR is set"

  (
    source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null
    [ -n "${CLAUDE_HOME:-}" ]
  ) && assert_pass "CLAUDE_HOME is set" || assert_fail "CLAUDE_HOME is set"
}

# Test 3: Directory existence
test_directory_existence() {
  test_group "Test 3: Required Directories Exist"

  # Source script to get paths
  source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null || return 1

  assert_dir_exists "Plugin root exists" "$CCPM_PLUGIN_DIR"
  assert_dir_exists "Commands directory exists" "$CCPM_COMMANDS_DIR"
  assert_dir_exists "Agents directory exists" "$CCPM_AGENTS_DIR"
  assert_dir_exists "Hooks directory exists" "$CCPM_HOOKS_DIR"
  assert_dir_exists "Scripts directory exists" "$CCPM_SCRIPTS_DIR"
  assert_dir_exists "Docs directory exists" "$CCPM_DOCS_DIR"
  assert_dir_exists "Claude home exists" "$CLAUDE_HOME"
}

# Test 4: Critical files exist
test_critical_files() {
  test_group "Test 4: Critical Files Exist"

  source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null || return 1

  # CCPM critical files
  assert_file_exists "SAFETY_RULES exists" "$CCPM_COMMANDS_DIR/SAFETY_RULES.md"
  assert_file_exists "_shared-linear-helpers exists" "$CCPM_COMMANDS_DIR/_shared-linear-helpers.md"
  assert_file_exists "README exists" "$CCPM_COMMANDS_DIR/README.md"

  # Agent files
  assert_file_exists "project-detector agent exists" "$CCPM_AGENTS_DIR/project-detector.md"
  assert_file_exists "linear-operations agent exists" "$CCPM_AGENTS_DIR/linear-operations.md"

  # Documentation
  assert_file_exists "Main CLAUDE.md exists" "$REPO_ROOT/CLAUDE.md"
  assert_file_exists "Main README exists" "$REPO_ROOT/README.md"
}

# Test 5: Path consistency
test_path_consistency() {
  test_group "Test 5: Path Consistency"

  source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null || return 1

  # Test parent-child relationships
  assert_true "COMMANDS_DIR is child of PLUGIN_DIR" \
    "[ \"\${CCPM_COMMANDS_DIR#\$CCPM_PLUGIN_DIR}\" != \"\$CCPM_COMMANDS_DIR\" ]"

  assert_true "AGENTS_DIR is child of PLUGIN_DIR" \
    "[ \"\${CCPM_AGENTS_DIR#\$CCPM_PLUGIN_DIR}\" != \"\$CCPM_AGENTS_DIR\" ]"

  assert_true "HOOKS_DIR is child of PLUGIN_DIR" \
    "[ \"\${CCPM_HOOKS_DIR#\$CCPM_PLUGIN_DIR}\" != \"\$CCPM_HOOKS_DIR\" ]"

  # Test named paths match directory names
  assert_true "COMMANDS_DIR ends with /commands" \
    "[ \"\${CCPM_COMMANDS_DIR}\" = \"*/commands\" ] || [ \"\${CCPM_COMMANDS_DIR##*/}\" = \"commands\" ]"
}

# Test 6: Verification command
test_verification() {
  test_group "Test 6: Verification Command"

  # Run verification
  if $RESOLVE_PATHS_SCRIPT verify >/dev/null 2>&1; then
    assert_pass "Verification command succeeds"
  else
    assert_fail "Verification command succeeds" "Exit code: $?"
  fi
}

# Test 7: Show command
test_show_command() {
  test_group "Test 7: Show Command"

  local output
  if output=$($RESOLVE_PATHS_SCRIPT show 2>/dev/null); then
    assert_pass "Show command executes"
    assert_true "Show output contains CCPM_PLUGIN_DIR" \
      "echo \"$output\" | grep -q 'CCPM_PLUGIN_DIR'"
  else
    assert_fail "Show command executes"
  fi
}

# Test 8: Help command
test_help_command() {
  test_group "Test 8: Help Command"

  local output
  if output=$($RESOLVE_PATHS_SCRIPT help 2>/dev/null); then
    assert_pass "Help command executes"
    assert_true "Help output contains usage info" \
      "echo \"$output\" | grep -q -i 'usage'"
  else
    assert_fail "Help command executes"
  fi
}

# Test 9: Environment variable override
test_env_override() {
  test_group "Test 9: Environment Variable Override"

  # Test with custom CCPM_PLUGIN_DIR
  local test_dir="/tmp/test-ccpm-dir"
  mkdir -p "$test_dir"/{commands,agents,hooks,scripts}

  # Create minimal structure
  touch "$test_dir/commands/.gitkeep"
  touch "$test_dir/agents/.gitkeep"

  if CCPM_PLUGIN_DIR="$test_dir" bash -c "source $RESOLVE_PATHS_SCRIPT 2>/dev/null && [ \"\$CCPM_PLUGIN_DIR\" = \"$test_dir\" ]"; then
    assert_pass "Custom CCPM_PLUGIN_DIR is respected"
  else
    assert_fail "Custom CCPM_PLUGIN_DIR is respected"
  fi

  # Cleanup
  rm -rf "$test_dir"
}

# Test 10: No absolute paths in commands
test_no_hardcoded_paths_in_commands() {
  test_group "Test 10: Command Files Hardcoded Paths (Phase 2 Check)"

  local found_absolute=0
  local examples=""

  # Check for /Users/duongdev/.claude/commands/pm/ references (should be updated in Phase 2)
  local old_pattern_count
  old_pattern_count=$(grep -r "/Users/duongdev/.claude/commands/pm/" "$CCPM_COMMANDS_DIR" 2>/dev/null | wc -l) || old_pattern_count=0

  if [ "$old_pattern_count" -gt 0 ]; then
    assert_skip "Commands use relative path references" \
      "Found $old_pattern_count references to old path (Phase 2 task)"
  else
    assert_pass "Commands use relative path references"
  fi
}

# Test 11: Path portability
test_path_portability() {
  test_group "Test 11: Path Portability"

  source "$RESOLVE_PATHS_SCRIPT" 2>/dev/null || return 1

  # Paths should not contain hardcoded usernames (except in examples)
  assert_true "CCPM_PLUGIN_DIR doesn't hardcode paths" \
    "! echo \"$CCPM_PLUGIN_DIR\" | grep -q 'duongdev'"

  assert_true "CLAUDE_HOME uses home variable pattern" \
    "! echo \"$CLAUDE_HOME\" | grep -q 'duongdev'"
}

# Test 12: Error handling
test_error_handling() {
  test_group "Test 12: Error Handling"

  # Test with missing plugin directory
  if CCPM_PLUGIN_DIR="/nonexistent/path" $RESOLVE_PATHS_SCRIPT verify >/dev/null 2>&1; then
    assert_fail "Invalid path is rejected"
  else
    assert_pass "Invalid path is rejected"
  fi
}

################################################################################
# Coverage Analysis
################################################################################

analyze_coverage() {
  if [ $COVERAGE -eq 0 ]; then
    return
  fi

  echo ""
  echo "========================================================================"
  echo "Coverage Analysis"
  echo "========================================================================"
  echo ""

  local total_tests=12
  local tests_run=$((TESTS_TOTAL))
  local coverage=$((tests_run * 100 / total_tests))

  echo "Test Coverage: $coverage% ($tests_run/$total_tests)"

  if [ $coverage -eq 100 ]; then
    echo -e "${GREEN}Full coverage achieved${NC}"
  else
    echo -e "${YELLOW}Partial coverage${NC}"
  fi

  echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
  # Parse arguments
  while [ $# -gt 0 ]; do
    case "$1" in
      --verbose) VERBOSE=1 ;;
      --coverage) COVERAGE=1 ;;
      --help)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --verbose   Show detailed test output"
        echo "  --coverage  Show coverage analysis"
        echo "  --help      Show this help message"
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
    shift
  done

  # Run tests
  init_tests

  test_resolver_exists
  test_path_resolution
  test_directory_existence
  test_critical_files
  test_path_consistency
  test_verification
  test_show_command
  test_help_command
  test_env_override
  test_no_hardcoded_paths_in_commands
  test_path_portability
  test_error_handling

  # Print results
  analyze_coverage
  print_summary
}

# Run main
main "$@"
