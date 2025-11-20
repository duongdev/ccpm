#!/bin/bash
# install-hooks.sh - Install CCPM hooks into ~/.claude/settings.json
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
PLUGIN_ROOT="~/.claude/plugins/ccpm"
BACKUP_DIR=~/.claude/backups
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CCPM Hooks Installation"
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

# Verify hook files exist (using optimized versions from PSN-23)
HOOK_FILES=(
    "$PLUGIN_ROOT/hooks/smart-agent-selector-optimized.prompt"
    "$PLUGIN_ROOT/hooks/tdd-enforcer-optimized.prompt"
    "$PLUGIN_ROOT/hooks/quality-gate-optimized.prompt"
)

for hook_file in "${HOOK_FILES[@]}"; do
    if [ ! -f "$hook_file" ]; then
        echo -e "${RED}✗ Error: Hook file not found: $hook_file${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✓ All hook files verified${NC}"
echo ""

# Show what will be installed
echo "Installing the following hooks:"
echo ""
echo -e "${BLUE}1. UserPromptSubmit${NC} - Smart agent discovery & selection"
echo "   - Analyzes your requests"
echo "   - Discovers all available agents"
echo "   - Scores agents by relevance (0-100+)"
echo "   - Auto-invokes best agents"
echo ""
echo -e "${BLUE}2. PreToolUse${NC} - TDD enforcement"
echo "   - Checks for test files before writing code"
echo "   - Blocks production code if tests don't exist"
echo "   - Enforces Red-Green-Refactor workflow"
echo "   - Triggers: Write, Edit, NotebookEdit"
echo ""
echo -e "${BLUE}3. Stop${NC} - Quality gate"
echo "   - Auto code review after implementation"
echo "   - Security audit for sensitive changes"
echo "   - Architecture validation"
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

  # Add UserPromptSubmit hook (optimized version from PSN-23)
  .hooks.UserPromptSubmit = (
    (.hooks.UserPromptSubmit // []) + [{
      "hooks": [{
        "type": "prompt",
        "prompt": "\($pluginRoot)/hooks/smart-agent-selector-optimized.prompt",
        "timeout": 5000,
        "description": "CCPM: Smart agent selector (optimized: 81.7% token reduction, <1s with cache)"
      }]
    }]
  ) |

  # Add PreToolUse hook (optimized version from PSN-23)
  .hooks.PreToolUse = (
    (.hooks.PreToolUse // []) + [{
      "matcher": "Write|Edit|NotebookEdit",
      "hooks": [{
        "type": "prompt",
        "prompt": "\($pluginRoot)/hooks/tdd-enforcer-optimized.prompt",
        "timeout": 3000,
        "description": "CCPM: TDD enforcer (optimized: 49% token reduction, Red-Green-Refactor)"
      }]
    }]
  ) |

  # Add Stop hook (optimized version from PSN-23)
  .hooks.Stop = (
    (.hooks.Stop // []) + [{
      "hooks": [{
        "type": "prompt",
        "prompt": "\($pluginRoot)/hooks/quality-gate-optimized.prompt",
        "timeout": 5000,
        "description": "CCPM: Quality gate (optimized: 38.8% token reduction, auto code review)"
      }]
    }]
  )
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
echo "  • UserPromptSubmit (smart-agent-selector)"
echo "  • PreToolUse (tdd-enforcer)"
echo "  • Stop (quality-gate)"
echo ""
echo -e "${BLUE}📝 Configuration:${NC}"
echo "  Settings: $SETTINGS_FILE"
echo "  Backup:   $BACKUP_FILE"
echo "  Plugin:   $PLUGIN_ROOT"
echo ""
echo -e "${YELLOW}⚠ Important Notes:${NC}"
echo ""
echo "1. Optimized hooks are fast: <1s per trigger (with caching)"
echo "2. Performance improvements from PSN-23:"
echo "   • 49% average token reduction"
echo "   • 94% faster agent discovery"
echo ""
echo "3. Use verbose mode to see hooks in action:"
echo "   ${BLUE}claude --verbose${NC}"
echo ""
echo "4. Test agent discovery (with caching):"
echo "   ${BLUE}$PLUGIN_ROOT/scripts/discover-agents-cached.sh | jq 'length'${NC}"
echo "   (Should output: 24 or more)"
echo ""
echo "5. Try a test prompt:"
echo "   ${BLUE}\"Add user authentication\"${NC}"
echo "   You should see agent selection reasoning"
echo ""
echo "6. To uninstall hooks:"
echo "   ${BLUE}$PLUGIN_ROOT/scripts/uninstall-hooks.sh${NC}"
echo ""
echo -e "${GREEN}Ready to use! Start Claude Code and enjoy automated agent invocation! 🚀${NC}"
echo ""
