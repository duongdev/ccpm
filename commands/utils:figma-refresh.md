---
description: Force refresh Figma design cache and update Linear with latest data
allowed-tools: [Bash, LinearMCP]
argument-hint: <linear-issue-id>
---

# Refresh Figma Cache: $1

Force refresh cached Figma design data for Linear issue **$1**.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

This command is **READ-ONLY** for external systems and **WRITE** to Linear (internal tracking).

## Workflow

### Step 1: Fetch Linear Issue

Use **Linear MCP** to get issue details for $1:

```javascript
linear_get_issue({ id: "$1" })
```

Extract:
- Issue description
- Comments (check for cached Figma data)
- Project ID

### Step 2: Detect Figma Links

**READ**: `commands/_shared-figma-detection.md`

Extract Figma links from Linear issue:

```bash
LINEAR_DESC=$(linear_get_issue "$1" | jq -r '.description')
LINEAR_COMMENTS=$(linear_get_issue "$1" | jq -r '.comments[]? | .body' || echo "")

FIGMA_LINKS=$(./scripts/figma-utils.sh extract-markdown "$LINEAR_DESC $LINEAR_COMMENTS")
FIGMA_COUNT=$(echo "$FIGMA_LINKS" | jq 'length')

if [ "$FIGMA_COUNT" -eq 0 ]; then
  echo "❌ No Figma links found in issue $1"
  exit 1
fi

echo "🔍 Found $FIGMA_COUNT Figma design(s)"
```

### Step 3: Check Existing Cache

For each Figma link, check if cached data exists:

```bash
echo "$FIGMA_LINKS" | jq -c '.[]' | while read -r link; do
  FILE_ID=$(echo "$link" | jq -r '.file_id')
  FILE_NAME=$(echo "$link" | jq -r '.file_name')

  CACHE_STATUS=$(./scripts/figma-cache-manager.sh status "$1" "$FILE_ID")
  
  if [ -n "$CACHE_STATUS" ]; then
    echo "  📦 Found cache for: $FILE_NAME"
    CACHE_AGE=$(echo "$CACHE_STATUS" | jq -r '.age_hours')
    echo "     Age: ${CACHE_AGE}h"
  else
    echo "  ⚠️  No cache for: $FILE_NAME"
  fi
done
```

### Step 4: Force Refresh from Figma

For each Figma link:

1. Select MCP server
2. Extract fresh data via MCP
3. Analyze design system
4. Update cache
5. Detect changes

```bash
PROJECT_ID=$(linear_get_issue "$1" | jq -r '.projectId')
FIGMA_SERVER=$(./scripts/figma-server-manager.sh select "$PROJECT_ID")

if [ -z "$FIGMA_SERVER" ]; then
  echo "❌ No Figma MCP server configured for project"
  exit 1
fi

echo ""
echo "🔄 Refreshing Figma data..."

echo "$FIGMA_LINKS" | jq -c '.[]' | while read -r link; do
  FILE_ID=$(echo "$link" | jq -r '.file_id')
  FILE_NAME=$(echo "$link" | jq -r '.file_name')
  FILE_URL=$(echo "$link" | jq -r '.url')

  echo ""
  echo "  📐 Refreshing: $FILE_NAME"

  # Get old cache for comparison
  OLD_CACHE=$(./scripts/figma-cache-manager.sh get "$1" "$FILE_ID" 2>/dev/null || echo "{}")

  # Generate MCP call
  MCP_INSTRUCTION=$(./scripts/figma-data-extractor.sh extract "$FILE_ID" "$FIGMA_SERVER")

  # Execute MCP call (Claude should do this)
  # FIGMA_DATA=$(execute MCP based on MCP_INSTRUCTION)

  # Analyze design system
  # DESIGN_SYSTEM=$(echo "$FIGMA_DATA" | ./scripts/figma-design-analyzer.sh generate -)

  # Update cache
  # ./scripts/figma-cache-manager.sh store "$1" "$FILE_ID" "$FILE_NAME" "$FILE_URL" "$FIGMA_SERVER" "$DESIGN_SYSTEM"

  echo "     ✅ Cache updated"

  # Detect changes
  if [ -n "$OLD_CACHE" ] && [ "$OLD_CACHE" != "{}" ]; then
    # Compare OLD_CACHE with new DESIGN_SYSTEM
    # Detect color changes, component changes, etc.
    echo "     🔍 Checking for design changes..."
    # TODO: Implement change detection
  fi
done
```

### Step 5: Update Linear Description

Update the "🎨 Design System Analysis" section in Linear description with refreshed data:

```javascript
// 1. Format new design system
const formattedDesignSystem = formatDesignSystemMarkdown(designSystem, fileName)

// 2. Update Linear description
const updatedDescription = issue.description.replace(
  /## 🎨 Design System Analysis:.*?(?=##|$)/s,
  formattedDesignSystem
)

// 3. Save to Linear
linear_update_issue({
  id: "$1",
  description: updatedDescription
})
```

### Step 6: Add Linear Comment

Add a comment documenting the refresh:

```markdown
## 🔄 Figma Design Refresh

**Refreshed**: [timestamp]
**Files updated**: [count]

### Changes Detected

- [File 1]: [change summary]
- [File 2]: No changes detected

### Updated Data

- Design tokens: ✅ Refreshed
- Component library: ✅ Refreshed
- Tailwind mappings: ✅ Refreshed

Cache will expire in 1 hour. Run `/ccpm:utils:figma-refresh $1` to refresh again.
```

Display final summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Figma Cache Refreshed: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Refreshed [X] Figma design(s)
Design System: Updated
Linear Description: Updated
Cache expires: [timestamp]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Usage

```bash
# Refresh Figma cache for a task
/ccpm:utils:figma-refresh WORK-123

# After designer updates Figma
/ccpm:utils:figma-refresh WORK-456
```

## Benefits

- **Fresh data**: Get latest design system updates
- **Change detection**: Know what changed since last cache
- **Implementation sync**: Keep implementation aligned with latest designs
- **Manual control**: Force refresh when needed (vs automatic 1hr expiry)
