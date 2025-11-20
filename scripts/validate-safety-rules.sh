#!/bin/bash
# validate-safety-rules.sh
# Validates that all commands with external writes implement confirmation workflow
# Part of CCPM security audit recommendations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_DIR="$SCRIPT_DIR/../commands"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}CCPM Safety Rules Validator${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Keywords indicating external write operations
EXTERNAL_WRITES_JIRA="jira.*update|jira.*create|jira.*comment|jira.*transition|atlassian.*update"
EXTERNAL_WRITES_CONFLUENCE="confluence.*create|confluence.*update|confluence.*edit|atlassian.*create.*page"
EXTERNAL_WRITES_BITBUCKET="bitbucket.*create|bitbucket.*comment|bitbucket.*merge|bitbucket.*pr.*create"
EXTERNAL_WRITES_SLACK="slack.*post|slack.*send|slack.*message|slack.*notification"

# Confirmation patterns to look for
CONFIRMATION_PATTERNS=(
    "AskUserQuestion"
    "confirmation"
    "CONFIRMATION REQUIRED"
    "Ask Confirmation"
    "Wait.*confirmation"
)

# Counters
TOTAL_COMMANDS=0
COMMANDS_WITH_WRITES=0
COMMANDS_WITH_CONFIRMATION=0
VIOLATIONS=()
WARNINGS=()

echo -e "${BLUE}[1/4] Scanning commands directory...${NC}"

# Scan all markdown files in commands directory
while IFS= read -r cmd_file; do
    TOTAL_COMMANDS=$((TOTAL_COMMANDS + 1))

    cmd_name=$(basename "$cmd_file")
    has_external_write=false
    has_confirmation=false
    write_type=""

    # Read file content
    content=$(cat "$cmd_file")

    # Check for external write operations
    if echo "$content" | grep -qiE "$EXTERNAL_WRITES_JIRA"; then
        has_external_write=true
        write_type="jira"
        COMMANDS_WITH_WRITES=$((COMMANDS_WITH_WRITES + 1))
    elif echo "$content" | grep -qiE "$EXTERNAL_WRITES_CONFLUENCE"; then
        has_external_write=true
        write_type="confluence"
        COMMANDS_WITH_WRITES=$((COMMANDS_WITH_WRITES + 1))
    elif echo "$content" | grep -qiE "$EXTERNAL_WRITES_BITBUCKET"; then
        has_external_write=true
        write_type="bitbucket"
        COMMANDS_WITH_WRITES=$((COMMANDS_WITH_WRITES + 1))
    elif echo "$content" | grep -qiE "$EXTERNAL_WRITES_SLACK"; then
        has_external_write=true
        write_type="slack"
        COMMANDS_WITH_WRITES=$((COMMANDS_WITH_WRITES + 1))
    fi

    # If command has external writes, check for confirmation
    if [ "$has_external_write" = true ]; then
        for conf_pattern in "${CONFIRMATION_PATTERNS[@]}"; do
            if echo "$content" | grep -qiE "$conf_pattern"; then
                has_confirmation=true
                COMMANDS_WITH_CONFIRMATION=$((COMMANDS_WITH_CONFIRMATION + 1))
                break
            fi
        done

        # Report violation if no confirmation found
        if [ "$has_confirmation" = false ]; then
            VIOLATIONS+=("$cmd_name:$write_type")
        fi
    fi

    # Check if command references SAFETY_RULES.md
    if [ "$has_external_write" = true ]; then
        if ! echo "$content" | grep -q "SAFETY_RULES"; then
            WARNINGS+=("$cmd_name:Missing SAFETY_RULES.md reference")
        fi
    fi

done < <(find "$COMMANDS_DIR" -name "*.md" -type f ! -name "README.md" ! -name "SPEC_MANAGEMENT_SUMMARY.md" ! -name "SAFETY_RULES.md")

echo -e "${GREEN}✓ Scanned $TOTAL_COMMANDS commands${NC}"
echo ""

echo -e "${BLUE}[2/4] Analyzing external write operations...${NC}"
echo -e "   Found $COMMANDS_WITH_WRITES commands with external writes"
echo -e "   Found $COMMANDS_WITH_CONFIRMATION with confirmation workflows"
echo ""

echo -e "${BLUE}[3/4] Checking for violations...${NC}"

if [ ${#VIOLATIONS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ No violations found!${NC}"
    echo -e "${GREEN}  All commands with external writes have confirmation workflows${NC}"
else
    echo -e "${RED}✖ Found ${#VIOLATIONS[@]} violation(s):${NC}"
    echo ""
    for violation in "${VIOLATIONS[@]}"; do
        cmd="${violation%%:*}"
        system="${violation##*:}"
        echo -e "${RED}  ✖ $cmd${NC}"
        echo -e "    ${YELLOW}External system: $system${NC}"
        echo -e "    ${YELLOW}Missing: AskUserQuestion or confirmation workflow${NC}"
        echo ""
    done
fi

echo -e "${BLUE}[4/4] Checking for warnings...${NC}"

if [ ${#WARNINGS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ No warnings${NC}"
else
    echo -e "${YELLOW}⚠ Found ${#WARNINGS[@]} warning(s):${NC}"
    echo ""
    for warning in "${WARNINGS[@]}"; do
        cmd="${warning%%:*}"
        issue="${warning##*:}"
        echo -e "${YELLOW}  ⚠ $cmd${NC}"
        echo -e "    $issue"
        echo ""
    done
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Total Commands:           $TOTAL_COMMANDS"
echo "  Commands with Writes:     $COMMANDS_WITH_WRITES"
echo "  Commands with Confirm:    $COMMANDS_WITH_CONFIRMATION"
echo "  Violations:               ${#VIOLATIONS[@]}"
echo "  Warnings:                 ${#WARNINGS[@]}"
echo ""

# Calculate compliance percentage
if [ $COMMANDS_WITH_WRITES -gt 0 ]; then
    COMPLIANCE=$((COMMANDS_WITH_CONFIRMATION * 100 / COMMANDS_WITH_WRITES))
    echo -e "  Compliance Rate:          ${COMPLIANCE}%"
    echo ""

    if [ $COMPLIANCE -eq 100 ]; then
        echo -e "${GREEN}✓ PASSED: 100% compliance with safety rules${NC}"
    elif [ $COMPLIANCE -ge 80 ]; then
        echo -e "${YELLOW}⚠ PASSED WITH WARNINGS: ${COMPLIANCE}% compliance${NC}"
        echo -e "${YELLOW}  Please fix violations to reach 100%${NC}"
    else
        echo -e "${RED}✖ FAILED: Only ${COMPLIANCE}% compliance${NC}"
        echo -e "${RED}  Required: 80% minimum, 100% recommended${NC}"
    fi
else
    echo -e "${GREEN}✓ PASSED: No external write operations found${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Exit with error if violations found
if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}To fix violations:${NC}"
    echo ""
    echo "1. Add AskUserQuestion workflow before external writes"
    echo "2. Add SAFETY_RULES.md reference at top of command"
    echo "3. Preview content before posting"
    echo "4. Wait for explicit user confirmation"
    echo ""
    echo "See: commands/utils:sync-status.md for example"
    echo ""
    exit 1
fi

exit 0
