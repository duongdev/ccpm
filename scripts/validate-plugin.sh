#!/bin/bash

#######################################
# CCPM Plugin Validation Script
#
# Comprehensive validation for:
# - Command structure and frontmatter
# - Skill definitions and SKILL.md format
# - Hook syntax and executability
# - File references and dependencies
#
# Usage: ./scripts/validate-plugin.sh [--verbose] [--fix]
#######################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMMANDS_DIR="$PROJECT_ROOT/commands"
SKILLS_DIR="$PROJECT_ROOT/skills"
HOOKS_DIR="$PROJECT_ROOT/hooks"
AGENTS_DIR="$PROJECT_ROOT/agents"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
validate_command_frontmatter() {
    local file="$1"
    local filename=$(basename "$file")

    # Check if file starts with YAML frontmatter
    if ! head -1 "$file" | grep -q "^---"; then
        log_fail "Command '$filename' missing YAML frontmatter start"
        return 1
    fi

    # Find closing ---
    local closing_line=$(tail -n +2 "$file" | grep -n "^---" | head -1 | cut -d: -f1)
    if [[ -z "$closing_line" ]]; then
        log_fail "Command '$filename' missing YAML frontmatter end"
        return 1
    fi

    # Extract frontmatter
    local frontmatter=$(head -n $((closing_line + 1)) "$file" | tail -n $((closing_line)))

    # Check required fields
    if ! echo "$frontmatter" | grep -q "^description:"; then
        log_fail "Command '$filename' missing 'description' field in frontmatter"
        return 1
    fi

    log_verbose "Frontmatter valid for $filename"
    return 0
}

validate_all_commands() {
    log_info "Validating command files..."

    local command_count=0
    local invalid_count=0

    while IFS= read -r -d '' file; do
        ((command_count++))
        ((TOTAL_CHECKS++))

        if ! validate_command_frontmatter "$file"; then
            ((invalid_count++))
        else
            log_pass "$(basename "$file")"
        fi
    done < <(find "$COMMANDS_DIR" -name "*.md" -type f -print0)

    log_info "Commands: $((command_count - invalid_count))/$command_count valid"

    if [[ $invalid_count -gt 0 ]]; then
        return 1
    fi
    return 0
}

validate_skill_frontmatter() {
    local file="$1"
    local skill_dir=$(dirname "$file")
    local skill_name=$(basename "$skill_dir")

    # Check if file starts with YAML frontmatter
    if ! head -1 "$file" | grep -q "^---"; then
        log_fail "Skill '$skill_name' missing YAML frontmatter start"
        return 1
    fi

    # Find closing ---
    local closing_line=$(tail -n +2 "$file" | grep -n "^---" | head -1 | cut -d: -f1)
    if [[ -z "$closing_line" ]]; then
        log_fail "Skill '$skill_name' missing YAML frontmatter end"
        return 1
    fi

    # Extract frontmatter
    local frontmatter=$(head -n $((closing_line + 1)) "$file" | tail -n $((closing_line)))

    # Check required fields
    if ! echo "$frontmatter" | grep -q "^name:"; then
        log_fail "Skill '$skill_name' missing 'name' field"
        return 1
    fi

    if ! echo "$frontmatter" | grep -q "^description:"; then
        log_fail "Skill '$skill_name' missing 'description' field"
        return 1
    fi

    # Check name matches directory
    local declared_name=$(echo "$frontmatter" | grep "^name:" | cut -d: -f2- | xargs)
    if [[ "$declared_name" != "$skill_name" ]]; then
        log_warn "Skill '$skill_name' name mismatch (declared: $declared_name)"
    fi

    log_verbose "Frontmatter valid for skill $skill_name"
    return 0
}

validate_all_skills() {
    log_info "Validating skill definitions..."

    local skill_count=0
    local invalid_count=0

    for skill_dir in "$SKILLS_DIR"/*; do
        if [[ -d "$skill_dir" ]]; then
            local skill_file="$skill_dir/SKILL.md"
            if [[ ! -f "$skill_file" ]]; then
                log_fail "Skill '$(basename "$skill_dir")' missing SKILL.md file"
                ((invalid_count++))
                ((TOTAL_CHECKS++))
            else
                ((TOTAL_CHECKS++))
                ((skill_count++))
                if validate_skill_frontmatter "$skill_file"; then
                    log_pass "$(basename "$skill_dir")"
                else
                    ((invalid_count++))
                fi
            fi
        fi
    done

    log_info "Skills: $((skill_count - invalid_count))/$skill_count valid"

    if [[ $invalid_count -gt 0 ]]; then
        return 1
    fi
    return 0
}

validate_hook_files() {
    log_info "Validating hook files..."

    local hook_count=0
    local invalid_count=0

    find "$HOOKS_DIR" -maxdepth 1 \( -name "*.prompt" -o -name "*.sh" \) -type f 2>/dev/null | while read -r hook_file; do
        if [[ -f "$hook_file" ]]; then
            ((hook_count++))
            ((TOTAL_CHECKS++))

            local hook_name=$(basename "$hook_file")

            # Check if file is readable
            if ! [[ -r "$hook_file" ]]; then
                log_fail "Hook '$hook_name' is not readable"
                ((invalid_count++))
                continue
            fi

            # Check if shell scripts are executable
            if [[ "$hook_file" == *.sh ]]; then
                if ! [[ -x "$hook_file" ]]; then
                    log_warn "Hook '$hook_name' is not executable (chmod +x recommended)"
                fi
            fi

            # Check for syntax errors in prompt files
            if [[ "$hook_file" == *.prompt ]]; then
                # Basic check: file should not be empty
                if [[ ! -s "$hook_file" ]]; then
                    log_fail "Hook '$hook_name' is empty"
                    ((invalid_count++))
                    continue
                fi

                # Check if it references discover-agents.sh
                if grep -q "discover-agents.sh" "$hook_file"; then
                    log_verbose "Hook '$hook_name' uses discover-agents.sh"
                fi
            fi

            log_pass "$hook_name"
        fi
    done

    log_info "Hooks: $((hook_count - invalid_count))/$hook_count valid"

    if [[ $invalid_count -gt 0 ]]; then
        return 1
    fi
    return 0
}

validate_hook_json_config() {
    log_info "Validating hooks.json configuration..."
    ((TOTAL_CHECKS++))

    local hooks_json="$HOOKS_DIR/hooks.json"
    if [[ ! -f "$hooks_json" ]]; then
        log_fail "Missing hooks.json"
        return 1
    fi

    # Check JSON validity
    if ! jq empty "$hooks_json" 2>/dev/null; then
        log_fail "hooks.json has invalid JSON"
        return 1
    fi

    log_pass "hooks.json is valid JSON"

    # Check for required hook definitions
    local required_hooks=("UserPromptSubmit" "PreToolUse" "Stop")
    for hook_type in "${required_hooks[@]}"; do
        ((TOTAL_CHECKS++))
        if jq -e ".\"$hook_type\"" "$hooks_json" >/dev/null 2>&1; then
            log_pass "Hook type '$hook_type' defined"
        else
            log_warn "Hook type '$hook_type' not found in hooks.json"
        fi
    done

    return 0
}

validate_plugin_json() {
    log_info "Validating plugin.json..."
    ((TOTAL_CHECKS++))

    local plugin_json="$PROJECT_ROOT/.claude-plugin/plugin.json"
    if [[ ! -f "$plugin_json" ]]; then
        log_fail "Missing .claude-plugin/plugin.json"
        return 1
    fi

    # Check JSON validity
    if ! jq empty "$plugin_json" 2>/dev/null; then
        log_fail "plugin.json has invalid JSON"
        return 1
    fi

    log_pass "plugin.json is valid JSON"

    # Check required fields
    local required_fields=("name" "version" "description" "commands")
    ((TOTAL_CHECKS++))
    for field in "${required_fields[@]}"; do
        if jq -e ".$field" "$plugin_json" >/dev/null 2>&1; then
            log_verbose "Field '$field' found in plugin.json"
        else
            log_fail "Missing required field '$field' in plugin.json"
            return 1
        fi
    done

    log_pass "All required fields present in plugin.json"
    return 0
}

validate_no_duplicate_commands() {
    log_info "Checking for duplicate command names..."
    ((TOTAL_CHECKS++))

    local duplicates=$(find "$COMMANDS_DIR" -name "*.md" -type f | xargs -I {} basename {} | sort | uniq -d)

    if [[ -n "$duplicates" ]]; then
        log_fail "Duplicate commands found: $duplicates"
        return 1
    fi

    log_pass "No duplicate commands"
    return 0
}

validate_referenced_files() {
    log_info "Validating file references..."

    local invalid_count=0

    # Check discover-agents.sh is referenced and exists
    ((TOTAL_CHECKS++))
    if grep -r "discover-agents.sh" "$HOOKS_DIR" >/dev/null 2>&1; then
        if [[ ! -f "$SCRIPTS_DIR/discover-agents.sh" ]]; then
            log_fail "discover-agents.sh referenced but not found"
            ((invalid_count++))
        else
            log_pass "discover-agents.sh exists and is referenced"
        fi
    fi

    return $([[ $invalid_count -eq 0 ]] && echo 0 || echo 1)
}

validate_script_permissions() {
    log_info "Validating script permissions..."

    local invalid_count=0

    while IFS= read -r -d '' script; do
        ((TOTAL_CHECKS++))
        if [[ ! -x "$script" ]]; then
            log_warn "Script '$(basename "$script")' is not executable"
            ((invalid_count++))
        else
            log_pass "$(basename "$script") is executable"
        fi
    done < <(find "$SCRIPTS_DIR" -name "*.sh" -type f -print0)

    return 0
}

# Main validation flow
run_all_validations() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       CCPM Plugin Comprehensive Validation                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local validation_failed=false

    validate_plugin_json || validation_failed=true
    echo ""

    validate_all_commands || validation_failed=true
    echo ""

    validate_all_skills || validation_failed=true
    echo ""

    validate_hook_files || validation_failed=true
    echo ""

    validate_hook_json_config || validation_failed=true
    echo ""

    validate_no_duplicate_commands || validation_failed=true
    echo ""

    validate_referenced_files || validation_failed=true
    echo ""

    validate_script_permissions || true  # Don't fail on permissions
    echo ""

    # Summary
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                     Validation Summary                        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Total Checks:    ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "Passed:          ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed:          ${RED}$FAILED_CHECKS${NC}"
    echo -e "Warnings:        ${YELLOW}$WARNINGS${NC}"
    echo ""

    if [[ "$validation_failed" == true ]]; then
        echo -e "${RED}✗ Validation FAILED${NC}"
        return 1
    elif [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠ Validation PASSED with warnings${NC}"
        return 0
    else
        echo -e "${GREEN}✓ Validation PASSED${NC}"
        return 0
    fi
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
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run validations
run_all_validations
exit $?
