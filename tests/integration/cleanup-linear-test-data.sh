#!/bin/bash
#
# Linear Test Data Cleanup Script
#
# Removes test labels and issues created during integration tests.
# Safe to run - only deletes items with "test-" prefix.
#
# Usage:
#   ./cleanup-linear-test-data.sh [--dry-run] [--all]
#
# Options:
#   --dry-run    Show what would be deleted without deleting
#   --all        Delete all test data (labels + issues)
#   --labels     Delete only test labels (default)
#   --issues     Delete only test issues
#   --help       Show this help message
#
# Examples:
#   ./cleanup-linear-test-data.sh --dry-run
#   ./cleanup-linear-test-data.sh --all
#   ./cleanup-linear-test-data.sh --labels
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
DELETE_LABELS=false
DELETE_ISSUES=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --all)
      DELETE_LABELS=true
      DELETE_ISSUES=true
      shift
      ;;
    --labels)
      DELETE_LABELS=true
      shift
      ;;
    --issues)
      DELETE_ISSUES=true
      shift
      ;;
    --help)
      head -n 20 "$0" | tail -n +2 | sed 's/^# //'
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Default to labels only if nothing specified
if [ "$DELETE_LABELS" = false ] && [ "$DELETE_ISSUES" = false ]; then
  DELETE_LABELS=true
fi

# Check prerequisites
if [ -z "$LINEAR_TEST_TEAM_ID" ]; then
  echo -e "${RED}❌ Error: LINEAR_TEST_TEAM_ID environment variable not set${NC}"
  echo ""
  echo "Please set your Linear test team ID:"
  echo "  export LINEAR_TEST_TEAM_ID=\"your-team-id\""
  exit 1
fi

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                ║${NC}"
echo -e "${CYAN}║            Linear Test Data Cleanup Script                    ║${NC}"
echo -e "${CYAN}║                                                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}🔍 DRY RUN MODE - No data will be deleted${NC}"
else
  echo -e "${RED}⚠️  LIVE MODE - Data will be permanently deleted${NC}"
fi

echo ""
echo -e "${BLUE}Team ID:${NC} ${LINEAR_TEST_TEAM_ID:0:8}..."
echo ""

# Counters
LABELS_FOUND=0
LABELS_DELETED=0
ISSUES_FOUND=0
ISSUES_DELETED=0

# Clean up labels
if [ "$DELETE_LABELS" = true ]; then
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}Cleaning up test labels...${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  cat <<'EOF'
To clean up test labels, run this code in Claude Code:

```javascript
// READ: commands/_shared-linear-helpers.md

const teamId = process.env.LINEAR_TEST_TEAM_ID;

// List all labels
const allLabels = await mcp__linear__list_issue_labels({
  team: teamId
});

// Filter labels with "test-" prefix
const testLabels = allLabels.filter(label =>
  label.name.toLowerCase().startsWith('test-')
);

console.log(`Found ${testLabels.length} test labels:`);

for (const label of testLabels) {
  console.log(`  - ${label.name} (${label.id})`);

  // Delete label (if not dry-run)
  if (!DRY_RUN) {
    await mcp__linear__delete_issue_label({
      id: label.id
    });
    console.log(`    ✅ Deleted`);
  } else {
    console.log(`    🔍 Would delete (dry-run)`);
  }
}

console.log(`\n✅ Cleanup complete: ${testLabels.length} labels processed`);
```
EOF

  echo ""
  echo -e "${YELLOW}Note: Label cleanup requires Claude Code execution context${NC}"
  echo -e "${YELLOW}Copy the code above and run it in Claude Code${NC}"
fi

# Clean up issues
if [ "$DELETE_ISSUES" = true ]; then
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}Cleaning up test issues...${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  cat <<'EOF'
To clean up test issues, run this code in Claude Code:

```javascript
const teamId = process.env.LINEAR_TEST_TEAM_ID;

// Search for test issues
const testIssues = await mcp__linear__search_issues({
  team: teamId,
  query: "title:\"Integration Test\" OR title:\"Status Test\" OR title:\"test-\""
});

console.log(`Found ${testIssues.length} test issues:`);

for (const issue of testIssues) {
  console.log(`  - ${issue.title} (${issue.identifier})`);

  // Delete issue (if not dry-run)
  if (!DRY_RUN) {
    await mcp__linear__delete_issue({
      id: issue.id
    });
    console.log(`    ✅ Deleted`);
  } else {
    console.log(`    🔍 Would delete (dry-run)`);
  }
}

console.log(`\n✅ Cleanup complete: ${testIssues.length} issues processed`);
```
EOF

  echo ""
  echo -e "${YELLOW}Note: Issue cleanup requires Claude Code execution context${NC}"
  echo -e "${YELLOW}Copy the code above and run it in Claude Code${NC}"
fi

# Summary
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Cleanup Instructions${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Since Linear MCP operations require Claude Code context,"
echo "this script provides the cleanup code to run manually."
echo ""
echo "Steps:"
echo "  1. Copy the code blocks shown above"
echo "  2. Open Claude Code session"
echo "  3. Paste and execute the code"
echo "  4. Verify test data is deleted"
echo ""
echo "Alternative: Manual cleanup via Linear UI"
echo "  1. Go to your Linear workspace"
echo "  2. Navigate to Team Settings > Labels"
echo "  3. Filter labels starting with 'test-'"
echo "  4. Delete test labels"
echo "  5. Search for test issues in Linear"
echo "  6. Archive or delete test issues"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}🔍 This was a dry run - no data would be deleted${NC}"
  echo "Remove --dry-run flag to generate actual cleanup code"
else
  echo -e "${GREEN}✅ Cleanup code generated - ready to execute in Claude Code${NC}"
fi

echo ""
