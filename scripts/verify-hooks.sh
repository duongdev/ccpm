#!/bin/bash
# verify-hooks.sh - Verify CCPM hooks installation and functionality
# This script checks if hooks are properly installed and working

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SETTINGS_FILE=~/.claude/settings.json
PLUGIN_ROOT="~/.claude/plugins/ccpm"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CCPM Hooks Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Track overall status
ALL_CHECKS_PASSED=true

# Check 1: jq installation
echo -e "${CYAN}[1/8] Checking jq installation...${NC}"
if command -v jq &> /dev/null; then
    JQ_VERSION=$(jq --version 2>&1)
    echo -e "${GREEN}✓ jq is installed: $JQ_VERSION${NC}"
else
    echo -e "${RED}✗ jq is NOT installed${NC}"
    echo "  Install with: brew install jq"
    ALL_CHECKS_PASSED=false
fi
echo ""

# Check 2: Settings file exists
echo -e "${CYAN}[2/8] Checking settings.json...${NC}"
if [ -f "$SETTINGS_FILE" ]; then
    echo -e "${GREEN}✓ Settings file exists: $SETTINGS_FILE${NC}"

    # Verify it's valid JSON
    if jq empty "$SETTINGS_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓ Settings file is valid JSON${NC}"
    else
        echo -e "${RED}✗ Settings file is NOT valid JSON${NC}"
        ALL_CHECKS_PASSED=false
    fi
else
    echo -e "${RED}✗ Settings file does not exist: $SETTINGS_FILE${NC}"
    echo "  Run: $PLUGIN_ROOT/scripts/install-hooks.sh"
    ALL_CHECKS_PASSED=false
fi
echo ""

# Check 3: Plugin directory exists
echo -e "${CYAN}[3/8] Checking plugin installation...${NC}"
if [ -d "$PLUGIN_ROOT" ]; then
    echo -e "${GREEN}✓ Plugin directory exists: $PLUGIN_ROOT${NC}"
else
    echo -e "${RED}✗ Plugin directory NOT found: $PLUGIN_ROOT${NC}"
    ALL_CHECKS_PASSED=false
fi
echo ""

# Check 4: Hook files exist
echo -e "${CYAN}[4/8] Checking hook files...${NC}"
HOOK_FILES=(
    "$PLUGIN_ROOT/hooks/smart-agent-selector.prompt"
    "$PLUGIN_ROOT/hooks/tdd-enforcer.prompt"
    "$PLUGIN_ROOT/hooks/quality-gate.prompt"
)

HOOK_FILES_OK=true
for hook_file in "${HOOK_FILES[@]}"; do
    if [ -f "$hook_file" ]; then
        FILE_SIZE=$(wc -c < "$hook_file" | xargs)
        echo -e "${GREEN}✓ $(basename "$hook_file") (${FILE_SIZE} bytes)${NC}"
    else
        echo -e "${RED}✗ $(basename "$hook_file") NOT found${NC}"
        HOOK_FILES_OK=false
        ALL_CHECKS_PASSED=false
    fi
done

if [ "$HOOK_FILES_OK" = true ]; then
    echo -e "${GREEN}✓ All hook files present${NC}"
fi
echo ""

# Check 5: Scripts are executable
echo -e "${CYAN}[5/8] Checking script permissions...${NC}"
SCRIPT_FILES=(
    "$PLUGIN_ROOT/scripts/discover-agents.sh"
    "$PLUGIN_ROOT/scripts/install-hooks.sh"
    "$PLUGIN_ROOT/scripts/uninstall-hooks.sh"
    "$PLUGIN_ROOT/scripts/verify-hooks.sh"
)

SCRIPTS_OK=true
for script_file in "${SCRIPT_FILES[@]}"; do
    if [ -f "$script_file" ]; then
        if [ -x "$script_file" ]; then
            echo -e "${GREEN}✓ $(basename "$script_file") is executable${NC}"
        else
            echo -e "${YELLOW}⚠ $(basename "$script_file") is NOT executable${NC}"
            echo "  Fix with: chmod +x $script_file"
            SCRIPTS_OK=false
        fi
    else
        echo -e "${RED}✗ $(basename "$script_file") NOT found${NC}"
        SCRIPTS_OK=false
        ALL_CHECKS_PASSED=false
    fi
done

if [ "$SCRIPTS_OK" = true ]; then
    echo -e "${GREEN}✓ All scripts are executable${NC}"
fi
echo ""

# Check 6: Hooks registered in settings.json
echo -e "${CYAN}[6/8] Checking hooks registration...${NC}"

if [ -f "$SETTINGS_FILE" ] && jq empty "$SETTINGS_FILE" 2>/dev/null; then
    # Check UserPromptSubmit
    USER_PROMPT_HOOKS=$(jq '[(.hooks.UserPromptSubmit // [])[] | select(.hooks[]?.description? // "" | contains("CCPM"))] | length' "$SETTINGS_FILE" 2>/dev/null || echo "0")
    if [ "$USER_PROMPT_HOOKS" -gt 0 ]; then
        echo -e "${GREEN}✓ UserPromptSubmit hook registered${NC}"
    else
        echo -e "${RED}✗ UserPromptSubmit hook NOT registered${NC}"
        ALL_CHECKS_PASSED=false
    fi

    # Check PreToolUse
    PRE_TOOL_HOOKS=$(jq '[(.hooks.PreToolUse // [])[] | select(.hooks[]?.description? // "" | contains("CCPM"))] | length' "$SETTINGS_FILE" 2>/dev/null || echo "0")
    if [ "$PRE_TOOL_HOOKS" -gt 0 ]; then
        echo -e "${GREEN}✓ PreToolUse hook registered${NC}"
    else
        echo -e "${RED}✗ PreToolUse hook NOT registered${NC}"
        ALL_CHECKS_PASSED=false
    fi

    # Check Stop
    STOP_HOOKS=$(jq '[(.hooks.Stop // [])[] | select(.hooks[]?.description? // "" | contains("CCPM"))] | length' "$SETTINGS_FILE" 2>/dev/null || echo "0")
    if [ "$STOP_HOOKS" -gt 0 ]; then
        echo -e "${GREEN}✓ Stop hook registered${NC}"
    else
        echo -e "${RED}✗ Stop hook NOT registered${NC}"
        ALL_CHECKS_PASSED=false
    fi

    TOTAL_HOOKS=$((USER_PROMPT_HOOKS + PRE_TOOL_HOOKS + STOP_HOOKS))
    if [ "$TOTAL_HOOKS" -eq 3 ]; then
        echo -e "${GREEN}✓ All 3 CCPM hooks are registered${NC}"
    elif [ "$TOTAL_HOOKS" -gt 0 ]; then
        echo -e "${YELLOW}⚠ Only $TOTAL_HOOKS of 3 hooks are registered${NC}"
        echo "  Run: $PLUGIN_ROOT/scripts/install-hooks.sh"
    else
        echo -e "${RED}✗ No CCPM hooks are registered${NC}"
        echo "  Run: $PLUGIN_ROOT/scripts/install-hooks.sh"
    fi
else
    echo -e "${RED}✗ Cannot check hooks registration (settings.json issue)${NC}"
    ALL_CHECKS_PASSED=false
fi
echo ""

# Check 7: Agent discovery script works
echo -e "${CYAN}[7/8] Testing agent discovery...${NC}"
if [ -x "$PLUGIN_ROOT/scripts/discover-agents.sh" ]; then
    AGENT_COUNT=$("$PLUGIN_ROOT/scripts/discover-agents.sh" 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
    if [ "$AGENT_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Agent discovery works: Found $AGENT_COUNT agents${NC}"

        # Show agent breakdown
        PLUGIN_AGENTS=$("$PLUGIN_ROOT/scripts/discover-agents.sh" 2>/dev/null | jq '[.[] | select(.type == "plugin")] | length' 2>/dev/null || echo "0")
        GLOBAL_AGENTS=$("$PLUGIN_ROOT/scripts/discover-agents.sh" 2>/dev/null | jq '[.[] | select(.type == "global")] | length' 2>/dev/null || echo "0")
        PROJECT_AGENTS=$("$PLUGIN_ROOT/scripts/discover-agents.sh" 2>/dev/null | jq '[.[] | select(.type == "project")] | length' 2>/dev/null || echo "0")

        echo "  • Plugin agents: $PLUGIN_AGENTS"
        echo "  • Global agents: $GLOBAL_AGENTS"
        echo "  • Project agents: $PROJECT_AGENTS"
    else
        echo -e "${RED}✗ Agent discovery failed or returned no agents${NC}"
        echo "  Debug with: $PLUGIN_ROOT/scripts/discover-agents.sh"
        ALL_CHECKS_PASSED=false
    fi
else
    echo -e "${RED}✗ Agent discovery script not executable${NC}"
    ALL_CHECKS_PASSED=false
fi
echo ""

# Check 8: Hook file paths are correct in settings
echo -e "${CYAN}[8/8] Verifying hook file paths...${NC}"
if [ -f "$SETTINGS_FILE" ] && jq empty "$SETTINGS_FILE" 2>/dev/null; then
    PATHS_OK=true

    # Extract all promptFile paths from CCPM hooks
    PROMPT_FILES=$(jq -r '
        [
            (.hooks.UserPromptSubmit // [])[] | select(.hooks[]?.description? // "" | contains("CCPM")) | .hooks[].promptFile,
            (.hooks.PreToolUse // [])[] | select(.hooks[]?.description? // "" | contains("CCPM")) | .hooks[].promptFile,
            (.hooks.Stop // [])[] | select(.hooks[]?.description? // "" | contains("CCPM")) | .hooks[].promptFile
        ] | .[]
    ' "$SETTINGS_FILE" 2>/dev/null)

    if [ -n "$PROMPT_FILES" ]; then
        while IFS= read -r prompt_file; do
            if [ -f "$prompt_file" ]; then
                echo -e "${GREEN}✓ Path exists: $prompt_file${NC}"
            else
                echo -e "${RED}✗ Path NOT found: $prompt_file${NC}"
                PATHS_OK=false
                ALL_CHECKS_PASSED=false
            fi
        done <<< "$PROMPT_FILES"

        if [ "$PATHS_OK" = true ]; then
            echo -e "${GREEN}✓ All hook paths are valid${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ No CCPM hook paths found in settings${NC}"
    fi
else
    echo -e "${RED}✗ Cannot verify paths (settings.json issue)${NC}"
    ALL_CHECKS_PASSED=false
fi
echo ""

# Final summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Verification Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$ALL_CHECKS_PASSED" = true ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "CCPM hooks are properly installed and ready to use."
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Start Claude Code with verbose mode:"
    echo "   ${CYAN}claude --verbose${NC}"
    echo ""
    echo "2. Try a test prompt:"
    echo "   ${CYAN}\"Add user authentication\"${NC}"
    echo ""
    echo "3. Look for hook execution in the output"
    echo ""
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo ""
    echo "1. If hooks are not registered:"
    echo "   ${CYAN}$PLUGIN_ROOT/scripts/install-hooks.sh${NC}"
    echo ""
    echo "2. If scripts are not executable:"
    echo "   ${CYAN}chmod +x $PLUGIN_ROOT/scripts/*.sh${NC}"
    echo ""
    echo "3. If agent discovery fails:"
    echo "   ${CYAN}$PLUGIN_ROOT/scripts/discover-agents.sh${NC}"
    echo "   Check for error messages"
    echo ""
    echo "4. For more help, see:"
    echo "   ${CYAN}$PLUGIN_ROOT/INSTALLATION.md${NC}"
    echo ""
fi

exit $([ "$ALL_CHECKS_PASSED" = true ] && echo 0 || echo 1)
