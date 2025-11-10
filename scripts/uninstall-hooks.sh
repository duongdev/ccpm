#!/bin/bash
# uninstall-hooks.sh - Remove CCPM hooks from ~/.claude/settings.json
# This script safely removes CCPM hooks while preserving other settings

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SETTINGS_FILE=~/.claude/settings.json
BACKUP_DIR=~/.claude/backups
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CCPM Hooks Uninstallation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}✗ Error: jq is not installed${NC}"
    echo ""
    echo "jq is required for this script to work."
    exit 1
fi

# Check if settings.json exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}⚠ Warning: $SETTINGS_FILE does not exist${NC}"
    echo "Nothing to uninstall."
    exit 0
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup existing settings
BACKUP_FILE="$BACKUP_DIR/settings-$TIMESTAMP.json"
cp "$SETTINGS_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup created:${NC} $BACKUP_FILE"
echo ""

# Check if CCPM hooks are present
CCPM_HOOKS_COUNT=$(jq '[
  (.hooks.UserPromptSubmit // [])[] |
  select(.hooks[]?.description? // "" | contains("CCPM")),
  (.hooks.PreToolUse // [])[] |
  select(.hooks[]?.description? // "" | contains("CCPM")),
  (.hooks.Stop // [])[] |
  select(.hooks[]?.description? // "" | contains("CCPM"))
] | length' "$SETTINGS_FILE")

if [ "$CCPM_HOOKS_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠ No CCPM hooks found in $SETTINGS_FILE${NC}"
    echo ""
    echo "Nothing to uninstall."
    exit 0
fi

echo "Found $CCPM_HOOKS_COUNT CCPM hook(s) to remove:"
echo ""

# Show which hooks will be removed
jq -r '
  [
    (.hooks.UserPromptSubmit // [])[] |
    select(.hooks[]?.description? // "" | contains("CCPM")) |
    "  • UserPromptSubmit: " + (.hooks[0].description // "CCPM hook"),
    (.hooks.PreToolUse // [])[] |
    select(.hooks[]?.description? // "" | contains("CCPM")) |
    "  • PreToolUse: " + (.hooks[0].description // "CCPM hook"),
    (.hooks.Stop // [])[] |
    select(.hooks[]?.description? // "" | contains("CCPM")) |
    "  • Stop: " + (.hooks[0].description // "CCPM hook")
  ] | .[]
' "$SETTINGS_FILE" || echo "  (Could not parse hook descriptions)"

echo ""

# Ask for confirmation
read -p "Do you want to proceed with uninstallation? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Uninstallation cancelled${NC}"
    exit 0
fi

echo ""
echo "Removing CCPM hooks..."

# Use jq to remove CCPM hooks from settings.json
jq '
  # Remove CCPM hooks from UserPromptSubmit
  .hooks.UserPromptSubmit = (
    (.hooks.UserPromptSubmit // []) |
    map(select(.hooks[]?.description? // "" | contains("CCPM") | not))
  ) |

  # Remove CCPM hooks from PreToolUse
  .hooks.PreToolUse = (
    (.hooks.PreToolUse // []) |
    map(select(.hooks[]?.description? // "" | contains("CCPM") | not))
  ) |

  # Remove CCPM hooks from Stop
  .hooks.Stop = (
    (.hooks.Stop // []) |
    map(select(.hooks[]?.description? // "" | contains("CCPM") | not))
  ) |

  # Clean up empty arrays
  .hooks.UserPromptSubmit = (if .hooks.UserPromptSubmit == [] then null else .hooks.UserPromptSubmit end) |
  .hooks.PreToolUse = (if .hooks.PreToolUse == [] then null else .hooks.PreToolUse end) |
  .hooks.Stop = (if .hooks.Stop == [] then null else .hooks.Stop end) |

  # Remove null entries
  .hooks |= with_entries(select(.value != null))
' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"

# Verify the output is valid JSON
if jq empty "$SETTINGS_FILE.tmp" 2>/dev/null; then
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Hooks removed successfully!${NC}"
else
    echo -e "${RED}✗ Error: Generated invalid JSON${NC}"
    echo "Restoring backup..."
    cp "$BACKUP_FILE" "$SETTINGS_FILE"
    rm -f "$SETTINGS_FILE.tmp"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Uninstallation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✓ CCPM hooks removed${NC}"
echo ""
echo -e "${BLUE}📝 Configuration:${NC}"
echo "  Settings: $SETTINGS_FILE"
echo "  Backup:   $BACKUP_FILE"
echo ""
echo -e "${YELLOW}📋 Note:${NC}"
echo "  Your other hooks (if any) have been preserved."
echo ""
echo -e "${BLUE}To reinstall hooks:${NC}"
echo "  $PLUGIN_ROOT/scripts/install-hooks.sh"
echo ""
echo -e "${GREEN}Done! CCPM hooks are now disabled.${NC}"
echo ""
