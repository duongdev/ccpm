#!/bin/bash
# test-figma-phase2.sh - Test Phase 2 Figma data extraction
# Demonstrates MCP integration workflow

set -euo pipefail

echo "=========================================="
echo "Phase 2: Figma Data Extraction Demo"
echo "=========================================="
echo ""

# Test file ID (example from Figma Community)
FILE_ID="ABC123XYZ456"
FILE_NAME="Design System"
SERVER_NAME="figma-repeat"  # Example server

echo "📋 Test Configuration:"
echo "  File ID: $FILE_ID"
echo "  File Name: $FILE_NAME"
echo "  MCP Server: $SERVER_NAME"
echo ""

echo "Step 1: Detect server type"
echo "------------------------------------------"
SERVER_TYPE=$(./scripts/figma-data-extractor.sh detect-server "$SERVER_NAME")
echo "Server type: $SERVER_TYPE"
echo ""

echo "Step 2: Generate MCP call instructions"
echo "------------------------------------------"
MCP_CALL=$(./scripts/figma-data-extractor.sh extract "$FILE_ID" "$SERVER_NAME")
echo "$MCP_CALL" | jq '.'
echo ""

echo "Step 3: Simulate design analysis"
echo "------------------------------------------"

# Sample Figma file data (simplified structure)
SAMPLE_FIGMA_DATA='{
  "name": "Design System",
  "lastModified": "2025-11-20T10:00:00Z",
  "version": "1.0",
  "document": {
    "id": "0:0",
    "name": "Page 1",
    "type": "CANVAS",
    "children": [
      {
        "id": "1:1",
        "name": "Primary Button",
        "type": "COMPONENT",
        "absoluteBoundingBox": {"x": 0, "y": 0, "width": 120, "height": 40},
        "fills": [{"type": "SOLID", "color": {"r": 0.24, "g": 0.51, "b": 0.96, "a": 1}}],
        "children": [
          {
            "id": "1:2",
            "name": "Label",
            "type": "TEXT",
            "characters": "Click me",
            "style": {
              "fontFamily": "Inter",
              "fontSize": 16,
              "fontWeight": 500,
              "lineHeightPx": 24
            }
          }
        ]
      },
      {
        "id": "2:1",
        "name": "Card",
        "type": "COMPONENT",
        "layoutMode": "VERTICAL",
        "itemSpacing": 16,
        "paddingLeft": 24,
        "paddingRight": 24,
        "paddingTop": 20,
        "paddingBottom": 20,
        "absoluteBoundingBox": {"x": 200, "y": 0, "width": 300, "height": 200},
        "fills": [{"type": "SOLID", "color": {"r": 1, "g": 1, "b": 1, "a": 1}}]
      }
    ]
  }
}'

echo "Design file structure:"
echo "$SAMPLE_FIGMA_DATA" | jq '{name, version, components: [.document.children[] | {id, name, type}]}'
echo ""

echo "Step 4: Extract design tokens"
echo "------------------------------------------"
TOKENS=$(echo "$SAMPLE_FIGMA_DATA" | ./scripts/figma-design-analyzer.sh extract-tokens -)
echo "$TOKENS" | jq '.'
echo ""

echo "Step 5: Analyze components"
echo "------------------------------------------"
COMPONENTS=$(echo "$SAMPLE_FIGMA_DATA" | ./scripts/figma-design-analyzer.sh analyze-components -)
echo "$COMPONENTS" | jq '.'
echo ""

echo "Step 6: Generate full design system"
echo "------------------------------------------"
DESIGN_SYSTEM=$(echo "$SAMPLE_FIGMA_DATA" | ./scripts/figma-design-analyzer.sh generate -)
echo "Design system generated with:"
echo "$DESIGN_SYSTEM" | jq '{
  colorCount: (.designTokens.colors | length),
  fontCount: (.designTokens.fonts | length),
  spacingCount: (.designTokens.spacing | length),
  componentCount: (.components | length)
}'
echo ""

echo "Step 7: Format as markdown for Linear"
echo "------------------------------------------"
MARKDOWN=$(echo "$DESIGN_SYSTEM" | ./scripts/figma-design-analyzer.sh format - "$FILE_NAME")
echo "$MARKDOWN"
echo ""

echo "=========================================="
echo "✅ Phase 2 Demo Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ MCP server detection working"
echo "  ✓ MCP call generation working"
echo "  ✓ Design token extraction working"
echo "  ✓ Component analysis working"
echo "  ✓ Design system generation working"
echo "  ✓ Markdown formatting working"
echo ""
echo "Next steps:"
echo "  1. Configure Figma MCP server in agent-mcp-gateway"
echo "  2. Test with real Figma file"
echo "  3. Integrate into /ccpm:planning:plan command"
