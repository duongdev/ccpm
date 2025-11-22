---
description: Force refresh Figma design cache and update Linear with latest data
allowed-tools: [Bash, Task]
argument-hint: "<issue-id>"
---

# /ccpm:figma-refresh - Refresh Figma Design Cache

Force refresh cached Figma design data for a Linear issue and update with latest design system.

## Purpose

When designers update Figma files, this command fetches the latest design system data and updates Linear descriptions with fresh Tailwind mappings.

## Usage

```bash
# Refresh Figma cache for a task
/ccpm:figma-refresh PSN-123

# After designer updates Figma
/ccpm:figma-refresh WORK-456
```

## Implementation

### Step 1: Fetch Linear Issue

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: get_issue
params:
  issueId: "{issue ID from argument}"
context:
  cache: false  # Always fresh for refresh operation
  command: "figma-refresh"
```

Extract:
- Issue description
- Issue comments (for cached Figma data)
- Project ID

### Step 2: Detect Figma Links

Use `helpers/figma-detection.md` logic to extract Figma links:

```bash
# Search issue description and comments for Figma URLs
FIGMA_LINKS=$(./scripts/figma-utils.sh extract-markdown "$LINEAR_DESC")

if [ -z "$FIGMA_LINKS" ] || [ "$(echo "$FIGMA_LINKS" | jq 'length')" -eq 0 ]; then
  echo "❌ No Figma links found in issue $1"
  echo ""
  echo "Add Figma links to issue description, then run this command again."
  exit 1
fi

FIGMA_COUNT=$(echo "$FIGMA_LINKS" | jq 'length')
echo "🔍 Found $FIGMA_COUNT Figma design(s)"
```

### Step 3: Check Existing Cache

For each Figma link, check if cached data exists:

```bash
echo ""
echo "📦 Checking cache status..."

echo "$FIGMA_LINKS" | jq -c '.[]' | while read -r link; do
  FILE_ID=$(echo "$link" | jq -r '.file_id')
  FILE_NAME=$(echo "$link" | jq -r '.file_name')

  CACHE_STATUS=$(./scripts/figma-cache-manager.sh status "$1" "$FILE_ID")

  if [ -n "$CACHE_STATUS" ]; then
    CACHE_AGE=$(echo "$CACHE_STATUS" | jq -r '.age_hours')
    echo "  ✅ Cached: $FILE_NAME (${CACHE_AGE}h old)"
  else
    echo "  ⚠️  Not cached: $FILE_NAME"
  fi
done
```

### Step 4: Force Refresh from Figma

For each Figma link:

1. Select appropriate MCP server for project
2. Extract fresh data via Figma MCP
3. Analyze design system (colors, typography, spacing)
4. Update cache with new data
5. Detect changes from previous version

```bash
# Get project ID from issue
PROJECT_ID=$(echo "$ISSUE_DATA" | jq -r '.project.id')

# Select Figma MCP server for this project
FIGMA_SERVER=$(./scripts/figma-server-manager.sh select "$PROJECT_ID")

if [ -z "$FIGMA_SERVER" ]; then
  echo "❌ No Figma MCP server configured for this project"
  echo ""
  echo "Configure Figma MCP server in ~/.config/agent-mcp-gateway/.mcp.json"
  exit 1
fi

echo ""
echo "🔄 Refreshing Figma data from server: $FIGMA_SERVER"

echo "$FIGMA_LINKS" | jq -c '.[]' | while read -r link; do
  FILE_ID=$(echo "$link" | jq -r '.file_id')
  FILE_NAME=$(echo "$link" | jq -r '.file_name')
  FILE_URL=$(echo "$link" | jq -r '.url')

  echo ""
  echo "  📐 Refreshing: $FILE_NAME"

  # Get old cache for change detection
  OLD_CACHE=$(./scripts/figma-cache-manager.sh get "$1" "$FILE_ID" 2>/dev/null || echo "{}")

  # Extract design data via Figma MCP
  echo "     🔌 Fetching from Figma MCP..."
  FIGMA_DATA=$(./scripts/figma-data-extractor.sh extract "$FIGMA_SERVER" "$FILE_URL")

  if [ -z "$FIGMA_DATA" ] || [ "$FIGMA_DATA" == "null" ]; then
    echo "     ❌ Failed to fetch design data"
    continue
  fi

  # Analyze design system
  echo "     🎨 Analyzing design system..."
  DESIGN_SYSTEM=$(echo "$FIGMA_DATA" | ./scripts/figma-design-analyzer.sh analyze -)

  # Update cache
  echo "     💾 Updating cache..."
  ./scripts/figma-cache-manager.sh set "$1" "$FILE_URL" "$DESIGN_SYSTEM"

  echo "     ✅ Cache updated successfully"

  # Detect changes from previous version
  if [ -n "$OLD_CACHE" ] && [ "$OLD_CACHE" != "{}" ]; then
    echo "     🔍 Detecting design changes..."

    # Compare color palettes
    OLD_COLORS=$(echo "$OLD_CACHE" | jq -r '.colors | length')
    NEW_COLORS=$(echo "$DESIGN_SYSTEM" | jq -r '.colors | length')

    if [ "$OLD_COLORS" != "$NEW_COLORS" ]; then
      echo "     ⚠️  Color palette changed: $OLD_COLORS → $NEW_COLORS colors"
    fi

    # Compare typography
    OLD_FONTS=$(echo "$OLD_CACHE" | jq -r '.typography | length')
    NEW_FONTS=$(echo "$DESIGN_SYSTEM" | jq -r '.typography | length')

    if [ "$OLD_FONTS" != "$NEW_FONTS" ]; then
      echo "     ⚠️  Typography changed: $OLD_FONTS → $NEW_FONTS font styles"
    fi
  fi
done
```

### Step 5: Update Linear Issue Description

Update the design system section in Linear description:

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: update_issue_description
params:
  issueId: "{issue ID}"
  description: |
    {existing description with updated design system section}

    ## 🎨 Design System Analysis

    **Figma Files**: {count} file(s)
    **Last Refreshed**: {timestamp}

    {for each Figma file:}
    ### {file_name}

    **URL**: {figma_url}

    **Colors** (Tailwind mappings):
    {colors.map(c => `- ${c.hex} → \`${c.tailwind}\``).join('\n')}

    **Typography** (Tailwind mappings):
    {typography.map(t => `- ${t.family} → \`${t.tailwind}\``).join('\n')}

    **Spacing** (Tailwind scale):
    {spacing.map(s => `- ${s.value} → \`${s.tailwind}\``).join('\n')}

    ---

    *Refresh: `/ccpm:figma-refresh {issueId}` | Cache expires in 1 hour*
context:
  command: "figma-refresh"
```

### Step 6: Add Linear Comment

Add a comment documenting the refresh operation:

**Use the Task tool:**

Invoke `ccpm:linear-operations`:
```
operation: create_comment
params:
  issueId: "{issue ID}"
  body: |
    ## 🔄 Figma Design Refresh

    **Refreshed**: {timestamp}
    **Files updated**: {count}
    **Server**: {figma_server}

    ${changes.length > 0 ? `
    ### Changes Detected

    ${changes.map(c => `- ${c.file}: ${c.summary}`).join('\n')}
    ` : '### No changes detected since last refresh'}

    ### Updated Data

    - ✅ Design tokens refreshed
    - ✅ Tailwind mappings updated
    - ✅ Component library synced

    Cache will expire in 1 hour. Run `/ccpm:figma-refresh {issueId}` to refresh again.
context:
  command: "figma-refresh"
```

### Step 7: Display Summary

```javascript
console.log('\n═══════════════════════════════════════');
console.log('✅ Figma Cache Refreshed');
console.log('═══════════════════════════════════════\n');
console.log(`📋 Issue: ${issueId}`);
console.log(`🎨 Refreshed: ${figmaCount} Figma design(s)`);
console.log(`🔄 Changes: ${changesCount} change(s) detected`);
console.log(`\n💾 Cache Details:`);
console.log(`  • Design System: Updated`);
console.log(`  • Linear Description: Updated`);
console.log(`  • Expires: 1 hour`);
console.log('\n💡 Next: /ccpm:work {issueId}');
```

## Benefits

- **Fresh data**: Get latest design system updates from Figma
- **Change detection**: Know what changed since last cache
- **Implementation sync**: Keep implementation aligned with latest designs
- **Manual control**: Force refresh when needed (vs automatic 1hr expiry)
- **Design collaboration**: Designers can notify devs when designs are updated

## Error Handling

### No Figma Links

```
❌ No Figma links found in issue PSN-123

Add Figma links to issue description, then run this command again.
```

### No MCP Server Configured

```
❌ No Figma MCP server configured for this project

Configure Figma MCP server in ~/.config/agent-mcp-gateway/.mcp.json
```

### Figma API Failure

```
❌ Failed to fetch design data from Figma

Suggestions:
  - Check Figma MCP server is running
  - Verify FIGMA_PERSONAL_ACCESS_TOKEN is valid
  - Check Figma file permissions
```

## Notes

- Cache expires after 1 hour automatically
- Use this command when designers notify you of Figma updates
- All Figma files in the issue will be refreshed
- Design system changes are detected and highlighted
- Linear description is updated with fresh Tailwind mappings
