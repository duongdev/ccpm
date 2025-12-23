#!/bin/bash
# CCPM Gemini Figma Analyzer
# Usage: ./scripts/gemini-figma-analyze.sh <image-path> [analysis-type] [model]
#
# Analysis Types:
#   - full (default): Complete design system extraction
#   - colors: Color palette only
#   - typography: Font and text styles
#   - spacing: Padding, margins, gaps
#   - components: UI component inventory
#
# Models:
#   - gemini-2.5-flash (default): Fast, cheap, good for most cases
#   - gemini-2.5-pro: More accurate for complex designs
#   - gemini-2.5-pro-exp: Experimental, highest accuracy

set -e

# ============================================================================
# Configuration
# ============================================================================

IMAGE_PATH="$1"
ANALYSIS_TYPE="${2:-full}"
MODEL="${3:-gemini-2.5-flash}"

# Timeout for Gemini API calls (30 seconds)
TIMEOUT=30

# Output format
OUTPUT_FORMAT="markdown"  # or "json"

# ============================================================================
# Validation
# ============================================================================

if [ -z "$IMAGE_PATH" ]; then
    echo "Usage: $0 <image-path> [analysis-type] [model]"
    echo ""
    echo "Analysis types:"
    echo "  full        - Complete design system (default)"
    echo "  colors      - Color palette extraction"
    echo "  typography  - Font and text styles"
    echo "  spacing     - Padding, margins, gaps"
    echo "  components  - UI component inventory"
    echo ""
    echo "Models:"
    echo "  gemini-2.5-flash     - Fast, cheap (default)"
    echo "  gemini-2.5-pro       - More accurate"
    echo "  gemini-2.5-pro-exp   - Experimental"
    echo ""
    echo "Example:"
    echo "  $0 /tmp/figma-export.png full gemini-2.5-flash"
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found: $IMAGE_PATH" >&2
    exit 1
fi

# Check if gemini CLI is available
if ! command -v gemini &> /dev/null; then
    echo "Error: Gemini CLI not found" >&2
    echo "Install: npm install -g @google/generative-ai" >&2
    exit 1
fi

# Check API key
if [ -z "$GEMINI_API_KEY" ]; then
    echo "Error: GEMINI_API_KEY environment variable not set" >&2
    echo "Set with: export GEMINI_API_KEY='your-api-key'" >&2
    exit 1
fi

# Validate image format
IMAGE_EXT="${IMAGE_PATH##*.}"
case "$IMAGE_EXT" in
    png|jpg|jpeg|webp|gif)
        # Valid format
        ;;
    *)
        echo "Error: Unsupported image format: $IMAGE_EXT" >&2
        echo "Supported: png, jpg, jpeg, webp, gif" >&2
        exit 1
        ;;
esac

# ============================================================================
# Analysis Prompts
# ============================================================================

get_prompt() {
    local type="$1"

    case "$type" in
        "colors")
            cat <<'EOF'
Extract all colors from this UI design. Analyze the design systematically and provide:

For each color:
- Hex code (e.g., #3b82f6)
- RGB values (e.g., 59, 130, 246)
- Usage context (e.g., primary button background, text color, border)
- Closest Tailwind CSS class (e.g., bg-blue-500, text-slate-700)

Format as a markdown table:
| Hex Code | RGB | Usage | Tailwind Class |
|----------|-----|-------|----------------|
| #3b82f6 | 59, 130, 246 | Primary buttons, links | bg-blue-500 |

Include all unique colors you find, organized by usage type (backgrounds, text, accents, borders).
EOF
            ;;
        "typography")
            cat <<'EOF'
Analyze typography in this design systematically. Identify:

1. **Headings** (H1-H6):
   - Font family
   - Size in pixels
   - Font weight (e.g., 400, 500, 700)
   - Line height in pixels
   - Color (hex)
   - Equivalent Tailwind classes

2. **Body Text**:
   - Font family
   - Size in pixels
   - Font weight
   - Line height
   - Color (hex)
   - Tailwind classes

3. **UI Text** (buttons, labels, captions):
   - Specifications for each element type
   - Tailwind class mappings

Format as structured markdown with sections for each text style. Example:

## Typography Analysis

### Headings
- **H1**: Inter 32px bold #1e293b → `text-4xl font-bold text-slate-900`
- **H2**: Inter 24px semibold #334155 → `text-2xl font-semibold text-slate-700`

### Body
- **Body**: Inter 16px regular #475569 → `text-base text-slate-600`

Include all text styles you observe in the design.
EOF
            ;;
        "spacing")
            cat <<'EOF'
Measure all spacing in this design. Analyze systematically:

1. **Container Spacing**:
   - Page/section padding (in pixels)
   - Container max-width (if applicable)

2. **Component Spacing**:
   - Card padding
   - Button padding (horizontal and vertical)
   - Input field padding
   - List item padding

3. **Layout Gaps**:
   - Gaps between sections
   - Gaps between components
   - Grid gutters
   - Column gaps

4. **Margins**:
   - Spacing between major sections
   - Component bottom margins

For each measurement, provide:
- Element type
- Value in pixels
- Closest Tailwind spacing class (e.g., p-6 for 24px, gap-4 for 16px)

Format as a markdown table:
| Element | Pixels | Tailwind Class |
|---------|--------|----------------|
| Container padding | 24px | p-6 |
| Button padding | 12px 24px | px-6 py-3 |

Focus on consistent spacing patterns and the spacing scale used.
EOF
            ;;
        "components")
            cat <<'EOF'
Identify all UI components in this design. For each component:

1. **Component Type**: button, card, input, select, modal, etc.
2. **Variants**: Different versions (primary, secondary, tertiary)
3. **States**: Default, hover, active, disabled, focus
4. **Specifications**:
   - Colors (background, text, border)
   - Padding and spacing
   - Border radius
   - Typography
   - Icons (if present)
5. **Implementation Suggestion**: Which shadcn/ui component or custom approach

Format as structured markdown with sections for each component type:

## Component Inventory

### Buttons
- **Primary Button**:
  - Background: #3b82f6 (blue-500)
  - Text: #ffffff (white)
  - Padding: 12px 24px (px-6 py-3)
  - Border radius: 6px (rounded-md)
  - States: default, hover (darker), disabled (gray)
  - Implementation: shadcn/ui Button with variant="default"

### Cards
- **Content Card**:
  - Background: #ffffff
  - Padding: 16px (p-4)
  - Border: 1px #e2e8f0
  - Border radius: 8px (rounded-lg)
  - Shadow: subtle
  - Implementation: shadcn/ui Card component

Analyze all distinct components and their variations.
EOF
            ;;
        "full"|*)
            cat <<'EOF'
Extract the complete design system from this UI design. Analyze systematically and provide:

## 1. Color Palette
List all unique colors with:
- Hex code and RGB values
- Usage context (backgrounds, text, accents, borders)
- Suggested Tailwind class

## 2. Typography
For each text style:
- Font family
- Size in pixels
- Font weight
- Line height
- Color
- Tailwind class mapping

## 3. Spacing Scale
Identify the spacing pattern:
- Container padding
- Component padding
- Gaps between elements
- Margins
- Map to Tailwind spacing (p-*, gap-*, etc.)

## 4. Border Radius
List border radius values:
- In pixels
- Where used (cards, buttons, inputs)
- Tailwind class (rounded-*, rounded-md, etc.)

## 5. Shadows
Document shadow specifications:
- Box shadow values
- Where applied
- Tailwind class (shadow-sm, shadow-md, etc.)

## 6. Components
List all UI components with:
- Component type
- Variants and states
- Key specifications
- Implementation notes

Format as structured markdown with tables for easy reference. Be thorough but concise. Focus on extracting exact values that can be directly used in implementation.
EOF
            ;;
    esac
}

# ============================================================================
# Analysis Execution
# ============================================================================

echo "🔍 Analyzing design with Gemini ($ANALYSIS_TYPE mode)..." >&2
echo "   Model: $MODEL" >&2
echo "   Image: $IMAGE_PATH" >&2
echo "" >&2

# Get the appropriate prompt
PROMPT=$(get_prompt "$ANALYSIS_TYPE")

# Execute Gemini analysis with timeout
# Note: The actual gemini CLI command may differ based on the package
# This is a placeholder - adjust based on actual Gemini CLI API

# Attempt to run Gemini CLI
# Using timeout to prevent hanging
if timeout "$TIMEOUT" gemini -y -m "$MODEL" --image "$IMAGE_PATH" "$PROMPT" 2>/dev/null; then
    # Success
    echo "" >&2
    echo "✅ Analysis complete" >&2
    exit 0
else
    EXIT_CODE=$?

    # Handle different failure modes
    if [ $EXIT_CODE -eq 124 ]; then
        echo "❌ Error: Gemini analysis timed out after ${TIMEOUT}s" >&2
    else
        echo "❌ Error: Gemini analysis failed (exit code: $EXIT_CODE)" >&2
        echo "" >&2
        echo "Troubleshooting:" >&2
        echo "  1. Check API key: echo \$GEMINI_API_KEY" >&2
        echo "  2. Verify image format and size" >&2
        echo "  3. Check Gemini API status" >&2
        echo "  4. Try with a different model" >&2
    fi

    exit $EXIT_CODE
fi

# ============================================================================
# Notes
# ============================================================================

# The Gemini CLI command structure may vary depending on the package.
# Common patterns:
#
# Official Google package:
#   gemini -m <model> --image <path> "<prompt>"
#
# Alternative packages:
#   gemini-cli --model <model> --image <path> --prompt "<prompt>"
#
# Adjust the command based on the actual package installed.
#
# For production use, consider:
# 1. Adding retry logic with exponential backoff
# 2. Caching results to avoid repeated API calls
# 3. Rate limiting to respect API quotas
# 4. Structured JSON output parsing
# 5. Error classification and handling
