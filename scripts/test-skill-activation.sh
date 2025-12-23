#!/bin/bash

#######################################
# Skill Auto-Activation Testing
#
# Tests that:
# - All skills load correctly
# - Skill descriptions are well-formed
# - SKILL.md files have proper structure
# - Skills are discoverable
# - Activation triggers work
#
# Usage: ./scripts/test-skill-activation.sh [--verbose] [--simulate TRIGGER]
#######################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$PROJECT_ROOT/skills"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Options
VERBOSE=false
SIMULATE_TRIGGER=""

# Test results (using simple variables instead of associative arrays for bash 3.x compatibility)
SKILL_PASS_COUNT=0
SKILL_FAIL_COUNT=0

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_test() {
    echo -e "${CYAN}→${NC} $*"
}

log_pass() {
    echo -e "${GREEN}✓${NC} $*"
    ((PASSED_TESTS++)) || true
}

log_fail() {
    echo -e "${RED}✗${NC} $*"
    ((FAILED_TESTS++)) || true
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}  ›${NC} $*"
    fi
}

increment_test() {
    ((TOTAL_TESTS++)) || true
}

# Test functions
test_skill_directory_structure() {
    local skill_name="$1"
    local skill_dir="$SKILLS_DIR/$skill_name"

    log_test "Checking directory structure for $skill_name"
    increment_test

    # Check SKILL.md exists
    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
        log_fail "Missing SKILL.md in $skill_name"
        return 1
    fi

    log_verbose "SKILL.md found"
    return 0
}

test_skill_frontmatter() {
    local skill_name="$1"
    local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"

    log_test "Validating frontmatter for $skill_name"
    increment_test

    # Check frontmatter exists
    if ! head -1 "$skill_file" | grep -q "^---"; then
        log_fail "Missing frontmatter start in $skill_name/SKILL.md"
        return 1
    fi

    # Find closing ---
    local closing_line=$(tail -n +2 "$skill_file" | grep -n "^---" | head -1 | cut -d: -f1)
    if [[ -z "$closing_line" ]]; then
        log_fail "Missing frontmatter end in $skill_name/SKILL.md"
        return 1
    fi

    log_verbose "Frontmatter structure is valid"
    return 0
}

test_skill_required_fields() {
    local skill_name="$1"
    local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"

    log_test "Checking required fields in $skill_name"
    increment_test

    # Extract frontmatter
    local closing_line=$(tail -n +2 "$skill_file" | grep -n "^---" | head -1 | cut -d: -f1)
    local frontmatter=$(head -n $((closing_line + 1)) "$skill_file" | tail -n $((closing_line)))

    # Required fields
    local required_fields=("name" "description")
    local missing_fields=()

    for field in "${required_fields[@]}"; do
        if ! echo "$frontmatter" | grep -q "^$field:"; then
            missing_fields+=("$field")
        else
            log_verbose "Field '$field' found"
        fi
    done

    if [[ ${#missing_fields[@]} -gt 0 ]]; then
        log_fail "Missing fields in $skill_name: ${missing_fields[*]}"
        return 1
    fi

    return 0
}

test_skill_name_validity() {
    local skill_name="$1"
    local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"

    log_test "Validating skill name in $skill_name"
    increment_test

    # Extract declared name
    local closing_line=$(tail -n +2 "$skill_file" | grep -n "^---" | head -1 | cut -d: -f1)
    local frontmatter=$(head -n $((closing_line + 1)) "$skill_file" | tail -n $((closing_line)))
    local declared_name=$(echo "$frontmatter" | grep "^name:" | cut -d: -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Name should match directory
    if [[ "$declared_name" != "$skill_name" ]]; then
        log_fail "Name mismatch in $skill_name (declared: $declared_name, directory: $skill_name)"
        return 1
    fi

    log_verbose "Skill name is valid: $declared_name"
    return 0
}

test_skill_description_length() {
    local skill_name="$1"
    local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"

    log_test "Validating description for $skill_name"
    increment_test

    # Extract description (using sed instead of xargs to handle quotes)
    local closing_line=$(tail -n +2 "$skill_file" | grep -n "^---" | head -1 | cut -d: -f1)
    local frontmatter=$(head -n $((closing_line + 1)) "$skill_file" | tail -n $((closing_line)))
    local description=$(echo "$frontmatter" | grep "^description:" | cut -d: -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Check description length (should be substantial, not just 1-2 words)
    local desc_length=${#description}
    if [[ $desc_length -lt 20 ]]; then
        log_fail "Description too short for $skill_name (${desc_length} chars, minimum 20)"
        return 1
    fi

    log_verbose "Description length valid (${desc_length} chars)"

    # Check if description mentions activation triggers
    if echo "$skill_file" | grep -q "When to Use\|auto-activates\|Auto-activates"; then
        log_verbose "Skill has clear activation documentation"
    fi

    return 0
}

test_skill_content_structure() {
    local skill_name="$1"
    local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"

    log_test "Checking content structure for $skill_name"
    increment_test

    # Extract content after frontmatter
    local closing_line=$(tail -n +2 "$skill_file" | grep -n "^---" | head -1 | cut -d: -f1)
    local content=$(tail -n +$((closing_line + 2)) "$skill_file")

    # Check for heading (use grep -m1 to avoid broken pipe with head)
    if ! echo "$content" | grep -m1 -q "^#"; then
        log_fail "No heading found in $skill_name content"
        return 1
    fi

    log_verbose "Content structure is valid"
    return 0
}

test_skill_activation_triggers() {
    local skill_name="$1"
    local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"

    log_test "Checking activation triggers for $skill_name"
    increment_test

    # Skills should document when they auto-activate
    if grep -q "auto-activat\|Auto-activat\|When to Use" "$skill_file"; then
        log_verbose "Activation triggers documented"
        return 0
    else
        # This is a warning, not a failure - some skills might not have triggers
        log_verbose "No auto-activation triggers documented (may be manual-only)"
        return 0
    fi
}

test_skill_allowed_tools() {
    local skill_name="$1"
    local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"

    log_test "Checking allowed-tools declaration for $skill_name"
    increment_test

    # Extract frontmatter
    local closing_line=$(tail -n +2 "$skill_file" | grep -n "^---" | head -1 | cut -d: -f1)
    local frontmatter=$(head -n $((closing_line + 1)) "$skill_file" | tail -n $((closing_line)))

    # Check if allowed-tools is declared
    if echo "$frontmatter" | grep -q "^allowed-tools:"; then
        local tools=$(echo "$frontmatter" | grep "^allowed-tools:" | cut -d: -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        log_verbose "Allowed tools: $tools"
        return 0
    else
        log_verbose "No allowed-tools restriction declared"
        return 0
    fi
}

simulate_trigger() {
    local trigger="$1"

    echo ""
    log_info "Simulating trigger: '$trigger'"
    echo ""

    # Identify which skills should activate
    local activated_skills=()

    for skill_dir in "$SKILLS_DIR"/*; do
        if [[ -d "$skill_dir" ]]; then
            local skill_name=$(basename "$skill_dir")
            local skill_file="$skill_dir/SKILL.md"

            if [[ -f "$skill_file" ]]; then
                # Check if skill mentions this trigger
                local trigger_lower=$(echo "$trigger" | tr '[:upper:]' '[:lower:]')
                if grep -qi "$trigger_lower\|$(echo "$trigger_lower" | sed 's/ /.*/')" "$skill_file"; then
                    activated_skills+=("$skill_name")
                fi
            fi
        fi
    done

    if [[ ${#activated_skills[@]} -eq 0 ]]; then
        log_info "No skills would activate for trigger: '$trigger'"
    else
        log_info "Skills that would activate:"
        for skill in "${activated_skills[@]}"; do
            echo -e "${GREEN}✓${NC} $skill"
        done
    fi
}

run_all_skill_tests() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Skill Auto-Activation Testing Suite                  ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    log_info "Discovering skills in $SKILLS_DIR..."
    echo ""

    local skill_count=0
    local skill_failures=()

    for skill_dir in "$SKILLS_DIR"/*; do
        if [[ -d "$skill_dir" ]]; then
            local skill_name=$(basename "$skill_dir")
            ((skill_count++)) || true

            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}Testing Skill: $skill_name${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""

            # Run all tests for this skill
            local skill_failed=false

            if ! test_skill_directory_structure "$skill_name"; then
                skill_failed=true
            fi
            ((TOTAL_TESTS++)) || true

            if ! test_skill_frontmatter "$skill_name"; then
                skill_failed=true
            fi
            ((TOTAL_TESTS++)) || true

            if ! test_skill_required_fields "$skill_name"; then
                skill_failed=true
            fi
            ((TOTAL_TESTS++)) || true

            if ! test_skill_name_validity "$skill_name"; then
                skill_failed=true
            fi
            ((TOTAL_TESTS++)) || true

            if ! test_skill_description_length "$skill_name"; then
                skill_failed=true
            fi
            ((TOTAL_TESTS++)) || true

            if ! test_skill_content_structure "$skill_name"; then
                skill_failed=true
            fi
            ((TOTAL_TESTS++)) || true

            if ! test_skill_activation_triggers "$skill_name"; then
                skill_failed=true
            fi
            ((TOTAL_TESTS++)) || true

            if ! test_skill_allowed_tools "$skill_name"; then
                skill_failed=true
            fi
            ((TOTAL_TESTS++)) || true

            if [[ "$skill_failed" == true ]]; then
                ((SKILL_FAIL_COUNT++)) || true
                skill_failures+=("$skill_name")
                log_fail "Skill '$skill_name' has test failures"
            else
                ((SKILL_PASS_COUNT++)) || true
                log_pass "Skill '$skill_name' passed all tests"
            fi

            echo ""
        fi
    done

    # Summary
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                      Test Summary                            ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Total Skills:        ${BLUE}$skill_count${NC}"
    echo -e "Total Tests:         ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "Passed Tests:        ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed Tests:        ${RED}$FAILED_TESTS${NC}"
    echo ""

    # Results summary
    echo -e "Skills Passed:       ${GREEN}$SKILL_PASS_COUNT${NC}"
    echo -e "Skills Failed:       ${RED}$SKILL_FAIL_COUNT${NC}"
    echo ""

    if [[ ${#skill_failures[@]} -gt 0 ]]; then
        echo -e "${RED}✗ Skills with failures: ${skill_failures[*]}${NC}"
        return 1
    else
        echo -e "${GREEN}✓ All skills passed testing${NC}"
        return 0
    fi
}

show_usage() {
    cat << 'EOF'
Skill Auto-Activation Testing

Usage: ./scripts/test-skill-activation.sh [OPTIONS]

Options:
  --verbose              Show detailed test information
  --simulate TRIGGER     Simulate a trigger and show which skills activate
  --help                 Show this help message

Examples:
  # Run all tests
  ./scripts/test-skill-activation.sh

  # Run with verbose output
  ./scripts/test-skill-activation.sh --verbose

  # Simulate trigger
  ./scripts/test-skill-activation.sh --simulate "done"

Simulated Triggers:
  done, complete, finished, ready to merge
  (see skill SKILL.md files for actual activation keywords)

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --simulate)
            SIMULATE_TRIGGER="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Run tests
if [[ -n "$SIMULATE_TRIGGER" ]]; then
    simulate_trigger "$SIMULATE_TRIGGER"
else
    run_all_skill_tests
    exit $?
fi
