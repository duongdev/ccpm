#!/bin/bash

#######################################
# Pre-Commit Validation Hook
#
# Runs before git commit to ensure:
# - No invalid command files committed
# - No broken skill definitions
# - No hook syntax errors
# - plugin.json remains valid
#
# Installation:
#   mkdir -p .git/hooks
#   cp scripts/pre-commit-validate.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Usage: Can be run manually or automatically by git
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
NC='\033[0m'

# Counters
VIOLATIONS=0

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_pass() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
    ((VIOLATIONS++))
}

# Get list of staged files
get_staged_files() {
    git diff --cached --name-only --diff-filter=ACM 2>/dev/null || echo ""
}

check_command_files() {
    log_info "Checking staged command files..."

    local commands_to_check=$(get_staged_files | grep "^commands/.*\.md$" || true)

    if [[ -z "$commands_to_check" ]]; then
        log_pass "No command files staged"
        return 0
    fi

    local error_count=0

    while IFS= read -r file; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        # Check for frontmatter
        if ! head -1 "$file" | grep -q "^---"; then
            log_error "Command '$file' missing YAML frontmatter start"
            ((error_count++))
        fi

        # Check for description field
        if ! grep -q "^description:" "$file"; then
            log_error "Command '$file' missing description field"
            ((error_count++))
        fi

        # Check for valid markdown structure
        if ! grep -q "^# " "$file"; then
            log_error "Command '$file' missing markdown heading"
            ((error_count++))
        fi
    done <<< "$commands_to_check"

    if [[ $error_count -eq 0 ]]; then
        log_pass "All staged command files valid"
        return 0
    fi

    return 1
}

check_skill_files() {
    log_info "Checking staged skill files..."

    local skills_to_check=$(get_staged_files | grep "skills/.*SKILL\.md$" || true)

    if [[ -z "$skills_to_check" ]]; then
        log_pass "No skill files staged"
        return 0
    fi

    local error_count=0

    while IFS= read -r file; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        # Check for frontmatter
        if ! head -1 "$file" | grep -q "^---"; then
            log_error "Skill file '$file' missing YAML frontmatter start"
            ((error_count++))
        fi

        # Check for required fields
        for field in name description; do
            if ! grep -q "^$field:" "$file"; then
                log_error "Skill file '$file' missing $field field"
                ((error_count++))
            fi
        done
    done <<< "$skills_to_check"

    if [[ $error_count -eq 0 ]]; then
        log_pass "All staged skill files valid"
        return 0
    fi

    return 1
}

check_hooks_json() {
    log_info "Checking hooks.json..."

    if get_staged_files | grep -q "hooks/hooks\.json"; then
        if ! jq empty "$PROJECT_ROOT/hooks/hooks.json" 2>/dev/null; then
            log_error "hooks.json has invalid JSON syntax"
            return 1
        fi

        log_pass "hooks.json is valid JSON"
    else
        log_pass "hooks.json not staged"
    fi

    return 0
}

check_plugin_json() {
    log_info "Checking plugin.json..."

    if get_staged_files | grep -q "plugin\.json"; then
        if ! jq empty "$PROJECT_ROOT/.claude-plugin/plugin.json" 2>/dev/null; then
            log_error "plugin.json has invalid JSON syntax"
            return 1
        fi

        log_pass "plugin.json is valid JSON"
    else
        log_pass "plugin.json not staged"
    fi

    return 0
}

check_duplicate_commands() {
    log_info "Checking for duplicate command names..."

    local commands_to_check=$(get_staged_files | grep "^commands/.*\.md$" || true)

    if [[ -z "$commands_to_check" ]]; then
        log_pass "No command files to check"
        return 0
    fi

    local duplicates=$(echo "$commands_to_check" | xargs -I {} basename {} | sort | uniq -d)

    if [[ -n "$duplicates" ]]; then
        log_error "Duplicate commands found: $duplicates"
        return 1
    fi

    log_pass "No duplicate commands"
    return 0
}

check_no_large_files() {
    log_info "Checking for excessively large files..."

    local large_files=$(get_staged_files | while read -r file; do
        if [[ -f "$file" ]]; then
            local size=$(wc -c < "$file")
            # Warn if over 100KB
            if [[ $size -gt 102400 ]]; then
                echo "$file ($((size / 1024))KB)"
            fi
        fi
    done)

    if [[ -n "$large_files" ]]; then
        log_warn "Large files staged (consider splitting):"
        echo "$large_files" | sed 's/^/  /'
    else
        log_pass "File sizes are appropriate"
    fi

    return 0
}

check_bash_syntax() {
    log_info "Checking bash script syntax..."

    local scripts_to_check=$(get_staged_files | grep "scripts/.*\.sh$" || true)

    if [[ -z "$scripts_to_check" ]]; then
        log_pass "No script files staged"
        return 0
    fi

    local error_count=0

    while IFS= read -r file; do
        if [[ ! -f "$file" ]]; then
            continue
        fi

        if ! bash -n "$file" 2>/dev/null; then
            log_error "Script '$file' has syntax errors"
            bash -n "$file" 2>&1 | head -3 | sed 's/^/    /'
            ((error_count++))
        fi
    done <<< "$scripts_to_check"

    if [[ $error_count -eq 0 ]]; then
        log_pass "All script files have valid syntax"
        return 0
    fi

    return 1
}

check_file_permissions() {
    log_info "Checking file permissions..."

    # Scripts should be executable
    local staged_scripts=$(get_staged_files | grep "scripts/.*\.sh$" || true)

    if [[ -n "$staged_scripts" ]]; then
        log_warn "Script files staged - ensure they are executable"
    fi

    return 0
}

show_summary() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                  Pre-Commit Validation                       ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ $VIOLATIONS -eq 0 ]]; then
        echo -e "${GREEN}✓ All pre-commit checks passed${NC}"
        echo ""
        log_pass "Ready to commit"
        return 0
    else
        echo -e "${RED}✗ $VIOLATIONS validation violation(s) found${NC}"
        echo ""
        log_warn "Please fix the issues above before committing"
        return 1
    fi
}

# Main execution
main() {
    echo ""
    log_info "Running pre-commit validation..."
    echo ""

    local check_failed=false

    check_command_files || check_failed=true
    echo ""

    check_skill_files || check_failed=true
    echo ""

    check_hooks_json || check_failed=true
    echo ""

    check_plugin_json || check_failed=true
    echo ""

    check_duplicate_commands || check_failed=true
    echo ""

    check_bash_syntax || check_failed=true
    echo ""

    check_no_large_files || true  # Warnings only
    check_file_permissions || true  # Warnings only
    echo ""

    show_summary || check_failed=true

    if [[ "$check_failed" == true ]]; then
        exit 1
    else
        exit 0
    fi
}

main
