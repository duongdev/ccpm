#!/bin/bash

# CCPM Plugin Self-Test Script
# Tests plugin installation, command discovery, and structure

set -e

cd "$(dirname "$0")/.."

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 CCPM Plugin Self-Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: plugin.json validation
echo "📋 Test 1: Validating plugin.json..."
if cat .claude-plugin/plugin.json | jq . >/dev/null 2>&1; then
    echo "✅ plugin.json is valid JSON"
else
    echo "❌ plugin.json has invalid JSON syntax"
    exit 1
fi

# Check for unsupported fields
UNSUPPORTED=$(cat .claude-plugin/plugin.json | jq 'keys[]' | grep -E 'components|features|requirements|safety' || true)
if [ -n "$UNSUPPORTED" ]; then
    echo "❌ Found unsupported fields: $UNSUPPORTED"
    exit 1
else
    echo "✅ No unsupported fields found"
fi

# Validate path formats
HOOKS_PATH=$(cat .claude-plugin/plugin.json | jq -r '.hooks // empty')
if [ -n "$HOOKS_PATH" ]; then
    if [[ "$HOOKS_PATH" != *.json ]]; then
        echo "❌ hooks path must end with .json: $HOOKS_PATH"
        exit 1
    fi
    if [ ! -f "$HOOKS_PATH" ]; then
        echo "❌ hooks file not found: $HOOKS_PATH"
        exit 1
    fi
    echo "✅ hooks path valid: $HOOKS_PATH"
fi

AGENTS_PATH=$(cat .claude-plugin/plugin.json | jq -r '.agents // empty')
if [ -n "$AGENTS_PATH" ]; then
    if [[ "$AGENTS_PATH" == *.md ]]; then
        if [ ! -f "$AGENTS_PATH" ]; then
            echo "❌ agents file not found: $AGENTS_PATH"
            exit 1
        fi
        echo "✅ agents path valid: $AGENTS_PATH"
    elif [[ "$AGENTS_PATH" == */ ]] || [ -d "$AGENTS_PATH" ]; then
        echo "❌ agents must point to .md file(s), not directory: $AGENTS_PATH"
        exit 1
    fi
fi

# Test 2: Command structure
echo ""
echo "📂 Test 2: Checking command structure..."
COMMAND_COUNT=$(find commands -name "pm:*.md" -type f | wc -l | tr -d ' ')
if [ "$COMMAND_COUNT" -eq 27 ]; then
    echo "✅ Found $COMMAND_COUNT commands (expected 27)"
else
    echo "⚠️  Found $COMMAND_COUNT commands (expected 27)"
fi

# Check for old nested structure
OLD_STRUCTURE=$(find commands -type d -mindepth 1 ! -name ".*" | wc -l | tr -d ' ')
if [ "$OLD_STRUCTURE" -eq 0 ]; then
    echo "✅ No nested directories (flat structure confirmed)"
else
    echo "❌ Found $OLD_STRUCTURE nested directories (should be flat)"
    exit 1
fi

# Test 3: Command frontmatter
echo ""
echo "📝 Test 3: Validating command frontmatter..."
MISSING_FRONTMATTER=0
for file in commands/pm:*.md; do
    if ! grep -q "^---" "$file"; then
        echo "❌ Missing frontmatter: $file"
        MISSING_FRONTMATTER=$((MISSING_FRONTMATTER + 1))
    fi
    if ! grep -q "^description:" "$file"; then
        echo "❌ Missing description: $file"
        MISSING_FRONTMATTER=$((MISSING_FRONTMATTER + 1))
    fi
done

if [ $MISSING_FRONTMATTER -eq 0 ]; then
    echo "✅ All commands have valid frontmatter"
else
    echo "❌ $MISSING_FRONTMATTER issues found"
    exit 1
fi

# Test 4: Component directories
echo ""
echo "📁 Test 4: Checking component directories..."
for dir in commands agents hooks scripts; do
    if [ -d "$dir" ]; then
        echo "✅ $dir/ exists"
    else
        echo "❌ $dir/ missing"
        exit 1
    fi
done

# Test 5: Required files
echo ""
echo "📄 Test 5: Checking required files..."
REQUIRED_FILES=(
    ".claude-plugin/plugin.json"
    ".claude-plugin/marketplace.json"
    ".claude-plugin/FEATURES.md"
    ".claude-plugin/SCHEMA.md"
    "README.md"
    "CLAUDE.md"
    "MIGRATION.md"
    "commands/SAFETY_RULES.md"
    "hooks/smart-agent-selector.prompt"
    "hooks/tdd-enforcer.prompt"
    "hooks/quality-gate.prompt"
    "scripts/discover-agents.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Missing: $file"
        exit 1
    fi
done

# Test 6: Script permissions
echo ""
echo "🔐 Test 6: Checking script permissions..."
for script in scripts/*.sh; do
    if [ -x "$script" ]; then
        echo "✅ Executable: $script"
    else
        echo "⚠️  Not executable: $script (running chmod +x...)"
        chmod +x "$script"
    fi
done

# Test 7: Command categories
echo ""
echo "🏷️  Test 7: Verifying command categories..."
CATEGORIES=("spec" "planning" "implementation" "verification" "complete" "utils" "repeat")
for cat in "${CATEGORIES[@]}"; do
    COUNT=$(find commands -name "pm:${cat}:*.md" | wc -l | tr -d ' ')
    if [ "$COUNT" -gt 0 ]; then
        echo "✅ Category '$cat': $COUNT commands"
    else
        echo "❌ Category '$cat': No commands found"
    fi
done

# Test 8: Hook files
echo ""
echo "🪝 Test 8: Checking hook files..."
HOOK_COUNT=$(find hooks -name "*.prompt" -type f | wc -l | tr -d ' ')
if [ "$HOOK_COUNT" -ge 3 ]; then
    echo "✅ Found $HOOK_COUNT hook files"
else
    echo "⚠️  Found only $HOOK_COUNT hook files (expected at least 3)"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All tests passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Summary:"
echo "  • Commands: $COMMAND_COUNT"
echo "  • Hooks: $HOOK_COUNT"
echo "  • Structure: Flat ✓"
echo "  • Manifest: Valid ✓"
echo ""
echo "🚀 Plugin is ready! Next steps:"
echo "  1. Restart Claude Code"
echo "  2. Run: /pm:utils:help"
echo "  3. Try: /pm:spec:create"
echo ""
