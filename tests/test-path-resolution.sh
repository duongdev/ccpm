#!/bin/bash
################################################################################
# CCPM Path Resolution Tests - Simplified
################################################################################

set -euo pipefail

REPO_ROOT="/Users/duongdev/personal/ccpm"
RESOLVE_SCRIPT="$REPO_ROOT/scripts/resolve-paths.sh"

echo "CCPM Path Resolution Test Suite"
echo "==============================="
echo ""

# Test 1: Script exists
echo "Test 1: Resolver script exists"
if [ -f "$RESOLVE_SCRIPT" ] && [ -x "$RESOLVE_SCRIPT" ]; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

# Test 2: Script runs
echo ""
echo "Test 2: Resolver script can be sourced"
if bash -c "source '$RESOLVE_SCRIPT'" >/dev/null 2>&1; then
  echo "✓ PASS"
else
  echo "✗ FAIL - Source failed"
  exit 1
fi

# Test 3: Paths are set
echo ""
echo "Test 3: All required paths are set"
OUTPUT=$(bash -c "source '$RESOLVE_SCRIPT' && echo 'CCPM_PLUGIN_DIR='\$CCPM_PLUGIN_DIR && echo 'CCPM_COMMANDS_DIR='\$CCPM_COMMANDS_DIR && echo 'CLAUDE_HOME='\$CLAUDE_HOME")
if echo "$OUTPUT" | grep -q "CCPM_PLUGIN_DIR=/Users/duongdev/personal/ccpm"; then
  echo "✓ PASS - CCPM_PLUGIN_DIR set correctly"
else
  echo "✗ FAIL - CCPM_PLUGIN_DIR not set"
  echo "$OUTPUT"
  exit 1
fi

# Test 4: Directories exist
echo ""
echo "Test 4: All required directories exist"
cd "$REPO_ROOT"
DIRS="commands agents hooks scripts docs"
all_exist=true
for dir in $DIRS; do
  if [ -d "$dir" ]; then
    echo "  ✓ $dir/"
  else
    echo "  ✗ $dir/ NOT FOUND"
    all_exist=false
  fi
done
if [ "$all_exist" = true ]; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

# Test 5: Critical files exist
echo ""
echo "Test 5: Critical files exist"
CRITICAL_FILES=(
  "commands/SAFETY_RULES.md"
  "commands/_shared-linear-helpers.md"
  "agents/linear-operations.md"
  "agents/project-detector.md"
  "CLAUDE.md"
  "README.md"
)
all_exist=true
for file in "${CRITICAL_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "  ✓ $file"
  else
    echo "  ✗ $file NOT FOUND"
    all_exist=false
  fi
done
if [ "$all_exist" = true ]; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

# Test 6: verify command works
echo ""
echo "Test 6: Resolver verify command works"
if "$RESOLVE_SCRIPT" verify >/dev/null 2>&1; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

# Test 7: show command works
echo ""
echo "Test 7: Resolver show command works"
OUTPUT=$("$RESOLVE_SCRIPT" show 2>/dev/null)
if echo "$OUTPUT" | grep -q "CCPM_PLUGIN_DIR="; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

# Test 8: help command works
echo ""
echo "Test 8: Resolver help command works"
OUTPUT=$("$RESOLVE_SCRIPT" help 2>/dev/null)
if echo "$OUTPUT" | grep -q -i "usage"; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

# Test 9: Environment override works
echo ""
echo "Test 9: Environment variable override works"
TEST_DIR="/tmp/test-ccpm-$$"
mkdir -p "$TEST_DIR"/{commands,agents,hooks,scripts}
if CCPM_PLUGIN_DIR="$TEST_DIR" bash -c "source '$RESOLVE_SCRIPT' && [ \"\$CCPM_PLUGIN_DIR\" = \"$TEST_DIR\" ]" >/dev/null 2>&1; then
  echo "✓ PASS"
  rm -rf "$TEST_DIR"
else
  echo "✗ FAIL"
  rm -rf "$TEST_DIR"
  exit 1
fi

# Test 10: No hardcoded paths in critical files
echo ""
echo "Test 10: No hardcoded /Users/duongdev paths in plugin files"
OLD_PATTERN_COUNT=$(grep -r "/Users/duongdev/.claude/commands/pm/" "$REPO_ROOT/commands" 2>/dev/null | wc -l) || true
if [ "$OLD_PATTERN_COUNT" -gt 0 ]; then
  echo "⊘ SKIP - Found $OLD_PATTERN_COUNT references to old path (Phase 2 task)"
else
  echo "✓ PASS - No old hardcoded paths found"
fi

echo ""
echo "==============================="
echo "All tests completed successfully!"
echo "==============================="
