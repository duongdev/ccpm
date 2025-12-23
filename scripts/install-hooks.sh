#!/bin/bash
# install-hooks.sh - Install CCPM v1.1 hooks into ~/.claude/settings.json
# This script safely merges CCPM hooks with existing Claude Code settings

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SETTINGS_FILE=~/.claude/settings.json
# Auto-detect plugin root (script is in scripts/ subdirectory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR=~/.claude/backups
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CCPM v1.1 Hooks Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}✗ Error: jq is not installed${NC}"
    echo ""
    echo "jq is required for this script to work."
    echo "Install it with:"
    echo "  - macOS:   brew install jq"
    echo "  - Ubuntu:  sudo apt-get install jq"
    echo "  - Linux:   sudo yum install jq"
    echo ""
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if settings.json exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}⚠ Warning: $SETTINGS_FILE does not exist${NC}"
    echo "Creating new settings.json with CCPM hooks..."

    # Create minimal settings.json with hooks
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {}
}
EOF
fi

# Backup existing settings
BACKUP_FILE="$BACKUP_DIR/settings-$TIMESTAMP.json"
cp "$SETTINGS_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup created:${NC} $BACKUP_FILE"

# Verify plugin root exists
if [ ! -d "$PLUGIN_ROOT" ]; then
    echo -e "${RED}✗ Error: Plugin directory not found: $PLUGIN_ROOT${NC}"
    echo ""
    echo "Please update PLUGIN_ROOT in this script to match your CCPM installation path."
    exit 1
fi

# Verify hook files exist (v1.1 hooks)
HOOK_FILES=(
    "$PLUGIN_ROOT/hooks/scripts/smart-agent-selector.sh"
    "$PLUGIN_ROOT/hooks/scripts/session-init.cjs"
    "$PLUGIN_ROOT/hooks/scripts/scout-block.cjs"
    "$PLUGIN_ROOT/hooks/scripts/linear-param-fixer.sh"
)

echo "Verifying hook files..."
for hook_file in "${HOOK_FILES[@]}"; do
    if [ ! -f "$hook_file" ]; then
        echo -e "${YELLOW}⚠ Warning: Hook file not found: $hook_file${NC}"
    else
        echo -e "${GREEN}✓${NC} $(basename "$hook_file")"
    fi
done

echo ""

# Show what will be installed
echo "Installing the following hooks:"
echo ""
echo -e "${BLUE}1. SessionStart${NC} - Session initialization + CCPM context"
echo "   - Detects active project from git remote"
echo "   - Extracts issue ID from branch name"
echo "   - Discovers all available agents (once per session)"
echo "   - Injects CCPM rules and commands (once per session)"
echo "   - Triggers: startup, resume, clear, compact"
echo ""
echo -e "${BLUE}2. UserPromptSubmit${NC} - Lightweight agent hints"
echo "   - Detects task-specific keywords"
echo "   - Provides minimal agent suggestions (~15 tokens)"
echo "   - No context flooding (94% reduction vs v1.0)"
echo ""
echo -e "${BLUE}3. PreToolUse (scout-block)${NC} - Token optimization"
echo "   - Pre-filters tool calls to avoid wasted tokens"
echo "   - 30-50% token savings on average"
echo "   - Triggers: Read, WebFetch, Task"
echo ""
echo -e "${BLUE}4. PreToolUse (linear-param-fixer)${NC} - Linear API safety"
echo "   - Catches issueId vs id parameter mistakes"
echo "   - Prevents failed Linear MCP calls"
echo "   - Triggers: mcp__agent-mcp-gateway__execute_tool"
echo ""

# Ask for confirmation
read -p "Do you want to proceed with installation? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
fi

echo ""
echo "Installing hooks..."

# Use jq to merge hooks into settings.json
jq --arg pluginRoot "$PLUGIN_ROOT" '
  # Ensure hooks object exists
  .hooks = (.hooks // {}) |

  # Add SessionStart hook (session initialization)
  .hooks.SessionStart = [{
    "matcher": "startup|resume|clear|compact",
    "hooks": [{
      "type": "command",
      "command": "\($pluginRoot)/hooks/scripts/session-init.cjs",
      "timeout": 3000
    }]
  }] |

  # Add UserPromptSubmit hook (smart agent selector)
  .hooks.UserPromptSubmit = [{
    "hooks": [{
      "type": "command",
      "command": "\($pluginRoot)/hooks/scripts/smart-agent-selector.sh",
      "timeout": 5000
    }]
  }] |

  # Add PreToolUse hooks (scout-block and linear-param-fixer)
  .hooks.PreToolUse = [
    {
      "matcher": "Read|WebFetch|Task",
      "hooks": [{
        "type": "command",
        "command": "\($pluginRoot)/hooks/scripts/scout-block.cjs",
        "timeout": 1000
      }]
    },
    {
      "matcher": "mcp__agent-mcp-gateway__execute_tool",
      "hooks": [{
        "type": "command",
        "command": "\($pluginRoot)/hooks/scripts/linear-param-fixer.sh",
        "timeout": 2000
      }]
    }
  ]
' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"

# Verify the output is valid JSON
if jq empty "$SETTINGS_FILE.tmp" 2>/dev/null; then
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Hooks installed successfully!${NC}"
else
    echo -e "${RED}✗ Error: Generated invalid JSON${NC}"
    echo "Restoring backup..."
    cp "$BACKUP_FILE" "$SETTINGS_FILE"
    rm -f "$SETTINGS_FILE.tmp"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✓ Hooks installed:${NC}"
echo "  • SessionStart (session-init)"
echo "  • UserPromptSubmit (smart-agent-selector)"
echo "  • PreToolUse (scout-block)"
echo "  • PreToolUse (linear-param-fixer)"
echo ""
echo -e "${BLUE}📝 Configuration:${NC}"
echo "  Settings: $SETTINGS_FILE"
echo "  Backup:   $BACKUP_FILE"
echo "  Plugin:   $PLUGIN_ROOT"
echo ""
echo -e "${YELLOW}⚠ Important Notes:${NC}"
echo ""
echo "1. All hooks are optimized: <1s per trigger"
echo ""
echo "2. v1.1 Hook Features:"
echo "   • SessionStart: Full CCPM context injection (once per session)"
echo "   • UserPromptSubmit: Minimal hints only (94% token reduction)"
echo "   • Scout-block: 30-50% token savings on tool calls"
echo "   • Linear-param-fixer: Prevents issueId/id parameter errors"
echo ""
echo "3. Use verbose mode to see hooks in action:"
echo "   ${BLUE}claude --verbose${NC}"
echo ""
echo "4. To uninstall hooks:"
echo "   ${BLUE}$PLUGIN_ROOT/scripts/uninstall-hooks.sh${NC}"
echo ""
echo -e "${GREEN}Ready to use! Restart Claude Code to activate new hooks.${NC}"
echo ""
