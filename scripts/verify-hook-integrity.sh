#!/bin/bash

#######################################
# Hook Integrity Verification
#
# Verifies that:
# - All hooks have valid syntax
# - Hooks register correctly
# - Scripts are executable
# - Dependencies exist
# - hooks.json is properly configured
#
# Usage: ./scripts/verify-hook-integrity.sh [--verbose] [--fix]
#######################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/hooks"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Options
VERBOSE=false
FIX_ISSUES=false

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_pass() {
    echo -e "${GREEN}✓${NC} $*"
    ((PASSED_CHECKS++))
}

log_fail() {
    echo -e "${RED}✗${NC} $*"
    ((FAILED_CHECKS++))
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
    ((WARNINGS++))
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}→${NC} $*"
    fi
}

increment_check() {
    ((TOTAL_CHECKS++))
}

# Validation functions
check_hooks_json_exists() {
    log_info "Checking hooks.json exists..."
    ((TOTAL_CHECKS++))

    if [[ ! -f "$HOOKS_DIR/hooks.json" ]]; then
        log_fail "hooks.json not found at $HOOKS_DIR/hooks.json"
        return 1
    fi

    log_pass "hooks.json found"
    return 0
}

check_hooks_json_valid() {
    log_info "Validating hooks.json JSON syntax..."
    ((TOTAL_CHECKS++))

    if ! jq empty "$HOOKS_DIR/hooks.json" 2>/dev/null; then
        log_fail "hooks.json has invalid JSON syntax"
        return 1
    fi

    log_pass "hooks.json is valid JSON"
    return 0
}

check_hook_definitions() {
    log_info "Checking hook definitions in hooks.json..."

    local hooks_json="$HOOKS_DIR/hooks.json"
    local defined_hooks=$(jq 'keys[]' "$hooks_json" 2>/dev/null)

    if [[ -z "$defined_hooks" ]]; then
        log_warn "No hooks defined in hooks.json"
        return 0
    fi

    local hook_count=0
    while IFS= read -r hook_type; do
        ((TOTAL_CHECKS++))
        ((hook_count++))

        hook_type="${hook_type//\"/}"  # Remove quotes
        log_verbose "Hook type: $hook_type"

        # Check that hook has required properties
        if ! jq -e ".\"$hook_type\".description" "$hooks_json" >/dev/null 2>&1; then
            log_warn "Hook '$hook_type' missing description"
        fi

        if ! jq -e ".\"$hook_type\".file" "$hooks_json" >/dev/null 2>&1; then
            log_warn "Hook '$hook_type' missing file reference"
        else
            local hook_file=$(jq -r ".\"$hook_type\".file" "$hooks_json")
            if [[ ! -f "$HOOKS_DIR/$hook_file" ]]; then
                log_fail "Hook '$hook_type' references missing file: $hook_file"
                return 1
            fi
        fi

        log_pass "Hook '$hook_type' is properly defined"
    done <<< "$defined_hooks"

    log_verbose "Found $hook_count hook definitions"
    return 0
}

check_prompt_files() {
    log_info "Verifying prompt files..."

    local error_count=0

    for prompt_file in "$HOOKS_DIR"/*.prompt; do
        if [[ -f "$prompt_file" ]]; then
            ((TOTAL_CHECKS++))

            local filename=$(basename "$prompt_file")

            # Check file is not empty
            if [[ ! -s "$prompt_file" ]]; then
                log_fail "Prompt file '$filename' is empty"
                ((error_count++))
                continue
            fi

            # Check file is readable
            if [[ ! -r "$prompt_file" ]]; then
                log_fail "Prompt file '$filename' is not readable"
                ((error_count++))
                continue
            fi

            log_verbose "Validating $filename"

            # Check for common issues
            local line_count=$(wc -l < "$prompt_file")
            if [[ $line_count -lt 3 ]]; then
                log_warn "Prompt file '$filename' is very short ($line_count lines)"
            fi

            # Check for unmatched braces or quotes (basic check)
            local open_braces=$(grep -o '{' "$prompt_file" | wc -l)
            local close_braces=$(grep -o '}' "$prompt_file" | wc -l)
            if [[ $open_braces -ne $close_braces ]]; then
                log_warn "Prompt file '$filename' may have unmatched braces"
            fi

            # Check for variable placeholders
            if grep -q '{{.*}}' "$prompt_file"; then
                log_verbose "Prompt file '$filename' uses template variables"
            fi

            log_pass "$filename"
        fi
    done

    return $([[ $error_count -eq 0 ]] && echo 0 || echo 1)
}

check_shell_scripts() {
    log_info "Verifying shell script hooks..."

    local error_count=0

    for shell_script in "$HOOKS_DIR"/*.sh; do
        if [[ -f "$shell_script" ]]; then
            ((TOTAL_CHECKS++))

            local filename=$(basename "$shell_script")

            # Check file is readable
            if [[ ! -r "$shell_script" ]]; then
                log_fail "Script '$filename' is not readable"
                ((error_count++))
                continue
            fi

            # Check shebang
            if ! head -1 "$shell_script" | grep -q '^#!'; then
                log_warn "Script '$filename' missing shebang"
            else
                log_verbose "Script '$filename' has valid shebang"
            fi

            # Check if executable
            if [[ ! -x "$shell_script" ]]; then
                if [[ "$FIX_ISSUES" == true ]]; then
                    log_warn "Fixing: Making $filename executable"
                    chmod +x "$shell_script"
                else
                    log_warn "Script '$filename' is not executable (run with --fix to repair)"
                fi
            else
                log_pass "$filename is executable"
            fi

            # Check for syntax errors (if bash-compatible)
            if head -1 "$shell_script" | grep -q 'bash\|sh'; then
                log_verbose "Checking bash syntax for $filename"
                if ! bash -n "$shell_script" 2>/dev/null; then
                    log_fail "Script '$filename' has syntax errors"
                    ((error_count++))
                    bash -n "$shell_script" 2>&1 | head -5 | while read -r line; do
                        log_verbose "  Error: $line"
                    done
                fi
            fi
        fi
    done

    return $([[ $error_count -eq 0 ]] && echo 0 || echo 1)
}

check_dependencies() {
    log_info "Checking hook dependencies..."

    # Check for discover-agents.sh references
    if grep -r "discover-agents.sh" "$HOOKS_DIR" >/dev/null 2>&1; then
        ((TOTAL_CHECKS++))

        if [[ ! -f "$SCRIPTS_DIR/discover-agents.sh" ]]; then
            log_fail "discover-agents.sh referenced but not found"
            return 1
        fi

        if [[ ! -x "$SCRIPTS_DIR/discover-agents.sh" ]]; then
            if [[ "$FIX_ISSUES" == true ]]; then
                log_warn "Fixing: Making discover-agents.sh executable"
                chmod +x "$SCRIPTS_DIR/discover-agents.sh"
            else
                log_warn "discover-agents.sh is not executable"
            fi
        fi

        log_pass "discover-agents.sh found and accessible"
    fi

    # Check for other script dependencies
    local required_scripts=("verify-hooks.sh" "install-hooks.sh")
    for script in "${required_scripts[@]}"; do
        ((TOTAL_CHECKS++))

        if [[ ! -f "$SCRIPTS_DIR/$script" ]]; then
            log_warn "Script dependency missing: $script"
        else
            log_pass "$script exists"
        fi
    done

    return 0
}

check_hook_references() {
    log_info "Checking hook file references..."

    local error_count=0

    # Get all hooks defined in hooks.json
    local hooks_json="$HOOKS_DIR/hooks.json"
    if [[ -f "$hooks_json" ]]; then
        local hook_files=$(jq -r '.[] | .file' "$hooks_json" 2>/dev/null | sort -u)

        while IFS= read -r hook_file; do
            ((TOTAL_CHECKS++))

            if [[ -z "$hook_file" ]]; then
                continue
            fi

            local full_path="$HOOKS_DIR/$hook_file"
            if [[ ! -f "$full_path" ]]; then
                log_fail "Referenced hook file not found: $hook_file"
                ((error_count++))
            else
                log_pass "Hook file accessible: $hook_file"
            fi
        done <<< "$hook_files"
    fi

    return $([[ $error_count -eq 0 ]] && echo 0 || echo 1)
}

check_hook_performance() {
    log_info "Checking hook performance assumptions..."

    # Check for potentially slow patterns
    for hook_file in "$HOOKS_DIR"/*.prompt; do
        if [[ -f "$hook_file" ]]; then
            ((TOTAL_CHECKS++))

            local filename=$(basename "$hook_file")

            # Warn about shell command execution in hooks
            if grep -q 'bash\|sh\|execute\|system' "$hook_file"; then
                log_verbose "Hook '$filename' may execute shell commands (ensure fast execution)"
            fi

            # Check for potential infinite loops or recursion
            if grep -q 'while\|loop\|recursiv' "$hook_file"; then
                log_warn "Hook '$filename' mentions loops/recursion (ensure termination)"
            fi

            log_pass "$filename performance check"
        fi
    done

    return 0
}

run_all_checks() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              Hook Integrity Verification                     ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local verification_failed=false

    check_hooks_json_exists || verification_failed=true
    echo ""

    check_hooks_json_valid || verification_failed=true
    echo ""

    check_hook_definitions || verification_failed=true
    echo ""

    check_prompt_files || verification_failed=true
    echo ""

    check_shell_scripts || verification_failed=true
    echo ""

    check_dependencies || verification_failed=true
    echo ""

    check_hook_references || verification_failed=true
    echo ""

    check_hook_performance || true  # Don't fail on performance warnings
    echo ""

    # Summary
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                     Verification Summary                     ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Total Checks:    ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "Passed:          ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed:          ${RED}$FAILED_CHECKS${NC}"
    echo -e "Warnings:        ${YELLOW}$WARNINGS${NC}"
    echo ""

    if [[ "$verification_failed" == true ]]; then
        echo -e "${RED}✗ Verification FAILED${NC}"
        return 1
    elif [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠ Verification PASSED with warnings${NC}"
        return 0
    else
        echo -e "${GREEN}✓ Verification PASSED${NC}"
        return 0
    fi
}

show_usage() {
    cat << 'EOF'
Hook Integrity Verification

Usage: ./scripts/verify-hook-integrity.sh [OPTIONS]

Options:
  --verbose    Show detailed verification information
  --fix        Automatically fix fixable issues (permissions, etc.)
  --help       Show this help message

Examples:
  # Run verification
  ./scripts/verify-hook-integrity.sh

  # Run with detailed output
  ./scripts/verify-hook-integrity.sh --verbose

  # Fix issues automatically
  ./scripts/verify-hook-integrity.sh --fix

Checked Components:
  - hooks.json configuration file
  - JSON syntax validation
  - Hook definitions and properties
  - Prompt files (.prompt) integrity
  - Shell scripts (.sh) syntax and permissions
  - File references and dependencies
  - Hook execution assumptions

EOF
}

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

# Run checks
run_all_checks
exit $?
