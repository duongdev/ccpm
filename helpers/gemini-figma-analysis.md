# Gemini-Enhanced Figma Analysis

## Overview

Use Gemini's superior vision capabilities for detailed design system extraction from Figma exports.

This helper enhances CCPM's existing Figma integration (`helpers/figma-detection.md`) with advanced image analysis capabilities. While Claude's vision is excellent for general UI understanding, Gemini excels at precise extraction of design tokens, measurements, and systematic component analysis.

## Prerequisites

- Gemini CLI installed: `npm install -g @google/generative-ai`
- API key: `export GEMINI_API_KEY="your-key"`
- Figma export (PNG/JPG) from Figma MCP or manual download

**Installation Check:**
```bash
# Check if Gemini CLI is available
which gemini || echo "Install: npm install -g @google/generative-ai"

# Verify API key
[ -n "$GEMINI_API_KEY" ] && echo "✅ API key configured" || echo "❌ Set GEMINI_API_KEY"
```

## When to Use

### Use Gemini Analysis For:

- **Complex UI designs** with many components
- **Precise color/typography extraction** requiring exact hex values
- **Pixel-perfect implementation** requirements
- **Design system documentation** generation
- **Component variant detection** (primary, secondary, disabled states)
- **Spacing/layout measurements** in pixels
- **Design token generation** for Tailwind/CSS variables

### Use Claude's Built-in Vision For:

- Simple wireframes and sketches
- Quick layout understanding
- Basic component identification
- Architecture diagram interpretation
- Screenshot context understanding

**Decision Rule**: If you need exact values (hex colors, pixel measurements, font sizes), use Gemini. If you need conceptual understanding, use Claude.

## Design Extraction Patterns

### Full Design System Extraction

Extract complete design tokens in one pass:

```bash
gemini -y -m gemini-2.5-flash --image design.png "Extract the complete design system:

1. **Colors**: All colors as hex codes with usage context
2. **Typography**: Font families, sizes in px, weights, line heights
3. **Spacing**: Padding, margins, gaps with values in px
4. **Border Radius**: Values in px
5. **Shadows**: Box shadow specifications
6. **Components**: List with variants and states

Format as JSON."
```

**Output Format:**
```json
{
  "colors": {
    "primary": {"hex": "#3b82f6", "rgb": "59, 130, 246", "usage": "buttons, links"},
    "secondary": {"hex": "#64748b", "rgb": "100, 116, 139", "usage": "text, borders"}
  },
  "typography": {
    "heading": {"font": "Inter", "size": 32, "weight": 700, "lineHeight": 40},
    "body": {"font": "Inter", "size": 16, "weight": 400, "lineHeight": 24}
  },
  "spacing": {
    "container": 24,
    "card": 16,
    "gap": 12
  }
}
```

### Color Palette Only

Fast extraction for color schemes:

```bash
gemini -y -m gemini-2.5-flash --image design.png "Extract all colors used in this design.
For each color provide:
- Hex code
- RGB values
- Usage (background, text, accent, border, etc.)
- Suggested Tailwind class

Format as a markdown table."
```

**Output Format:**
```markdown
| Hex Code | RGB | Usage | Tailwind Class |
|----------|-----|-------|----------------|
| #3b82f6 | 59, 130, 246 | Primary buttons, links | bg-blue-500 |
| #64748b | 100, 116, 139 | Secondary text | text-slate-500 |
| #f8fafc | 248, 250, 252 | Background | bg-slate-50 |
```

### Typography Extraction

Systematic font analysis:

```bash
gemini -y -m gemini-2.5-flash --image design.png "Analyze typography in this design:
- Heading styles (H1-H6) with font, size, weight, color
- Body text styles
- Button text styles
- Caption/label styles

Map each to Tailwind classes."
```

**Output Format:**
```markdown
## Typography Analysis

### Headings
- **H1**: Inter 32px bold #1e293b → `text-4xl font-bold text-slate-900`
- **H2**: Inter 24px semibold #334155 → `text-2xl font-semibold text-slate-700`

### Body
- **Body**: Inter 16px regular #475569 → `text-base text-slate-600`
- **Small**: Inter 14px regular #64748b → `text-sm text-slate-500`

### Buttons
- **Primary**: Inter 16px medium #ffffff → `text-base font-medium text-white`
```

### Spacing Analysis

Precise measurement extraction:

```bash
gemini -y -m gemini-2.5-flash --image design.png "Measure all spacing in this design:
- Container padding
- Component gaps
- Section margins
- Grid gutters

Map to Tailwind spacing scale (space-1 through space-96)."
```

**Output Format:**
```markdown
## Spacing Analysis

| Element | Pixels | Tailwind Class |
|---------|--------|----------------|
| Container padding | 24px | p-6 |
| Card padding | 16px | p-4 |
| Button padding | 12px 24px | px-6 py-3 |
| Section gap | 32px | gap-8 |
| Grid gutter | 16px | gap-4 |
```

### Component Detection

Identify UI components and variants:

```bash
gemini -y -m gemini-2.5-flash --image design.png "Identify all UI components:
- Component type (button, card, input, etc.)
- Variants (primary, secondary, disabled)
- States (hover, active, focus)
- Suggested implementation approach (shadcn, custom)

Format as structured markdown."
```

**Output Format:**
```markdown
## Component Inventory

### Buttons
- **Primary Button**: Blue background (#3b82f6), white text, rounded corners (6px)
  - States: default, hover (darker blue), active, disabled (gray)
  - Implementation: shadcn/ui Button component with variant="default"

### Cards
- **Content Card**: White background, subtle shadow, 16px padding, 8px border radius
  - Implementation: shadcn/ui Card component
```

## Integration with Existing Figma Workflow

### Enhanced `/ccpm:plan` Flow

When planning a UI task with Figma design:

1. **Detect Figma link** (existing `helpers/figma-detection.md`)
2. **Export design** via Figma MCP
3. **Run Gemini analysis**:
   ```bash
   ./scripts/gemini-figma-analyze.sh figma-export.png
   ```
4. **Cache results** in Linear issue comment
5. **Pass to implementation agent** with design tokens

**Example Integration:**
```bash
# After Figma link detection (from helpers/figma-detection.md)
if [ "$FIGMA_COUNT" -gt 0 ]; then
  # Download image via Figma MCP
  EXPORT_PATH="/tmp/figma-export-${FILE_ID}.png"
  # ... MCP download logic ...

  # Run Gemini analysis
  DESIGN_TOKENS=$(./scripts/gemini-figma-analyze.sh "$EXPORT_PATH" "full")

  # Cache in Linear comment
  ./scripts/figma-cache-manager.sh store "$ISSUE_ID" "$FILE_ID" \
    "Design Tokens" "$FIGMA_URL" "$FIGMA_SERVER" "$DESIGN_TOKENS"
fi
```

### Enhanced `/ccpm:work` Flow

When implementing with visual context:

1. **Load Figma export** (cached or fresh)
2. **Run targeted Gemini analysis** for current component:
   ```bash
   gemini -y -m gemini-2.5-flash --image component.png "How should I implement this button component? Include exact Tailwind classes for colors, padding, font, and border radius."
   ```
3. **Implement with pixel-perfect accuracy**

**Example Usage in Work Command:**
```bash
# Load cached Figma context
FIGMA_CACHE=$(./scripts/figma-cache-manager.sh get "$ISSUE_ID")
EXPORT_PATH=$(echo "$FIGMA_CACHE" | jq -r '.export_path')

# Run component-specific analysis
COMPONENT_SPEC=$(./scripts/gemini-figma-analyze.sh "$EXPORT_PATH" "components")

# Pass to frontend agent
Task(subagent_type="frontend-developer"): "
Implement the login form using these exact specifications:

$COMPONENT_SPEC

Use shadcn/ui components and match the design pixel-perfect.
"
```

## Output Format Templates

### JSON Design Tokens

Structured output for programmatic use:

```json
{
  "colors": {
    "primary": {
      "hex": "#3b82f6",
      "rgb": "59, 130, 246",
      "tailwind": "blue-500",
      "usage": "Primary buttons, active states"
    },
    "secondary": {
      "hex": "#64748b",
      "rgb": "100, 116, 139",
      "tailwind": "slate-500",
      "usage": "Secondary text, borders"
    }
  },
  "typography": {
    "heading": {
      "font": "Inter",
      "fallback": "system-ui, sans-serif",
      "tailwind": "font-sans"
    },
    "sizes": {
      "h1": {"px": 32, "tailwind": "text-4xl"},
      "h2": {"px": 24, "tailwind": "text-2xl"},
      "body": {"px": 16, "tailwind": "text-base"}
    }
  },
  "spacing": {
    "container": {"px": 24, "tailwind": "px-6 py-4"},
    "card": {"px": 16, "tailwind": "p-4"},
    "gap": {"px": 12, "tailwind": "gap-3"}
  },
  "borderRadius": {
    "sm": {"px": 4, "tailwind": "rounded"},
    "md": {"px": 6, "tailwind": "rounded-md"},
    "lg": {"px": 8, "tailwind": "rounded-lg"}
  }
}
```

### Markdown Table

Human-readable format for Linear comments:

```markdown
## 🎨 Design System Analysis

### Colors
| Element | Value | Tailwind |
|---------|-------|----------|
| Primary Color | #3b82f6 | bg-blue-500 |
| Text Primary | #1e293b | text-slate-900 |
| Background | #f8fafc | bg-slate-50 |

### Typography
| Element | Value | Tailwind |
|---------|-------|----------|
| Heading Font | Inter 32px bold | text-4xl font-bold font-sans |
| Body Text | Inter 16px regular | text-base font-sans |

### Spacing
| Element | Value | Tailwind |
|---------|-------|----------|
| Card Padding | 24px | p-6 |
| Button Padding | 12px 24px | px-6 py-3 |
| Section Gap | 32px | gap-8 |

---
*Generated by Gemini 2.5 Flash via CCPM*
```

## Best Practices

### 1. Export at 2x Resolution

Higher resolution = better detail extraction:

```bash
# When exporting from Figma MCP
# Request @2x scale for better accuracy
scale: 2.0
```

### 2. Crop to Relevant Section

Focus analysis on specific components:

```bash
# Analyze specific component instead of entire page
gemini -y -m gemini-2.5-flash --image button-component.png "..."
```

### 3. Ask Specific Questions

Generic prompts = generic results:

```bash
# ❌ Bad: "Analyze this design"
# ✅ Good: "Extract all button styles with exact Tailwind classes"
```

### 4. Request Tailwind Mappings

Get implementation-ready output:

```bash
gemini -y -m gemini-2.5-flash --image design.png "...
Map each value to the closest Tailwind CSS class."
```

### 5. Cache Results

Avoid repeated analysis costs:

```bash
# Store in Linear comment with timestamp
./scripts/figma-cache-manager.sh store "$ISSUE_ID" "$FILE_ID" \
  "Gemini Design Analysis" "$URL" "$SERVER" "$ANALYSIS_RESULT"
```

### 6. Use Appropriate Model

Balance cost vs accuracy:

- `gemini-2.5-flash` - Fast, cheap, good for most cases
- `gemini-2.5-pro` - More accurate, better for complex designs
- `gemini-2.5-pro-exp` - Experimental, highest accuracy

## Performance Characteristics

| Operation | Time | Tokens | Cost |
|-----------|------|--------|------|
| Color extraction | ~2-3s | ~500 | $0.001 |
| Typography analysis | ~3-4s | ~800 | $0.002 |
| Full design system | ~5-7s | ~1500 | $0.003 |
| Component detection | ~4-5s | ~1000 | $0.002 |

**Optimization Tips:**
- Cache aggressively (design tokens rarely change)
- Use flash model for most tasks
- Batch similar analysis requests
- Crop images to relevant sections

## Error Handling

### Graceful Degradation

1. **Gemini CLI not installed** → Fall back to Claude vision
2. **API key missing** → Skip enhanced analysis, use basic extraction
3. **Rate limit reached** → Use cached results (even if stale)
4. **Analysis fails** → Continue with text-based design specs

**Never block workflow due to Gemini analysis failures.**

### Error Recovery Pattern

```bash
# Try Gemini analysis with fallback
if command -v gemini &> /dev/null && [ -n "$GEMINI_API_KEY" ]; then
  DESIGN_TOKENS=$(./scripts/gemini-figma-analyze.sh "$IMAGE" "full" 2>/dev/null) || {
    echo "⚠️ Gemini analysis failed, using cached data"
    DESIGN_TOKENS=$(./scripts/figma-cache-manager.sh get "$ISSUE_ID")
  }
else
  echo "ℹ️ Gemini not configured, using basic extraction"
  # Fall back to Claude vision or basic extraction
fi
```

## Integration Points

### Commands That Use Gemini Analysis

1. **`/ccpm:plan`** - Extract design tokens during planning
2. **`/ccpm:work`** - Load design specs for implementation
3. **`/ccpm:figma-refresh`** - Re-analyze updated designs

### Helper Dependencies

- `helpers/figma-detection.md` - Figma link detection (prerequisite)
- `helpers/image-analysis.md` - Image handling utilities
- `scripts/figma-cache-manager.sh` - Cache storage/retrieval
- `scripts/gemini-figma-analyze.sh` - Analysis execution

## Example Workflows

### Workflow 1: Planning UI Task with Gemini

```bash
# 1. User creates task with Figma link
/ccpm:plan "Implement login screen" my-app

# 2. Command detects Figma link
FIGMA_LINKS=$(./scripts/figma-utils.sh extract-markdown "$LINEAR_DESC")

# 3. Download design export
# ... Figma MCP download ...

# 4. Run Gemini analysis
DESIGN_SYSTEM=$(./scripts/gemini-figma-analyze.sh /tmp/export.png full)

# 5. Cache in Linear
./scripts/figma-cache-manager.sh store "$ISSUE_ID" "$FILE_ID" \
  "Design System" "$URL" "$SERVER" "$DESIGN_SYSTEM"

# 6. Update issue description with design tokens
# ... Linear update with Tailwind mappings ...
```

### Workflow 2: Implementing with Pixel-Perfect Specs

```bash
# 1. Start work
/ccpm:work

# 2. Load cached design tokens
DESIGN_TOKENS=$(./scripts/figma-cache-manager.sh get "$ISSUE_ID" | jq -r '.data')

# 3. Extract component-specific specs
BUTTON_SPEC=$(echo "$DESIGN_TOKENS" | jq -r '.components.button')

# 4. Implement with exact specs
Task(subagent_type="frontend-developer"): "
Implement the button component:
$BUTTON_SPEC

Requirements:
- Match colors exactly
- Use specified Tailwind classes
- Support all variants (primary, secondary, disabled)
"
```

### Workflow 3: Refreshing Design After Updates

```bash
# Designer updates Figma → trigger refresh
/ccpm:figma-refresh PSN-123

# 1. Clear cache
./scripts/figma-cache-manager.sh clear "$ISSUE_ID"

# 2. Re-download export
# ... Figma MCP download ...

# 3. Re-run Gemini analysis
NEW_TOKENS=$(./scripts/gemini-figma-analyze.sh /tmp/export.png full)

# 4. Detect changes
CHANGES=$(diff <(echo "$OLD_TOKENS") <(echo "$NEW_TOKENS"))

# 5. Update Linear with change summary
# ... Post comment with what changed ...
```

## Cost Estimation

### Gemini API Pricing (2025)

- **Flash Model**: ~$0.002 per analysis
- **Pro Model**: ~$0.01 per analysis
- **Free Tier**: 15 requests/minute

### Typical Project Costs

| Project Size | Analyses | Cost (Flash) | Cost (Pro) |
|-------------|----------|--------------|------------|
| Small (5 screens) | 5-10 | $0.01-0.02 | $0.05-0.10 |
| Medium (20 screens) | 20-40 | $0.04-0.08 | $0.20-0.40 |
| Large (50 screens) | 50-100 | $0.10-0.20 | $0.50-1.00 |

**Optimization**: Cache aggressively. Most designs don't change daily.

## Future Enhancements

### Planned Features

1. **Diff Detection** - Compare design versions and highlight changes
2. **Component Matching** - Map Figma components to shadcn/ui equivalents
3. **Accessibility Analysis** - Color contrast, text legibility checks
4. **Responsive Breakpoints** - Detect mobile/tablet/desktop variants
5. **Design Linting** - Flag inconsistent spacing, colors, fonts

### Experimental

- **Component Code Generation** - Auto-generate React components from specs
- **Design Token Export** - Generate CSS variables or Tailwind config
- **Multi-frame Comparison** - Analyze component variants side-by-side

---

## Summary

Gemini-enhanced Figma analysis provides **pixel-perfect design extraction** for CCPM's implementation workflows:

- ✅ **Precise extraction** - Exact hex colors, pixel measurements, font specs
- ✅ **Tailwind mappings** - Implementation-ready class names
- ✅ **Component inventory** - Systematic variant detection
- ✅ **Cached results** - Fast retrieval, low cost
- ✅ **Graceful fallbacks** - Never blocks workflow

**Use when**: You need exact design specs for pixel-perfect implementation.
**Skip when**: You just need conceptual understanding or rough layout.

**Integration**: Works seamlessly with existing `helpers/figma-detection.md` workflow.
