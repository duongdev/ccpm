#!/bin/bash
# figma-design-analyzer.sh - Analyze Figma design data and extract tokens/components
# Part of CCPM Figma MCP integration (PSN-25) - Phase 3

set -euo pipefail

# Constants
readonly COLOR_TAILWIND_MAP='{"#000000": "black", "#ffffff": "white", "#ef4444": "red-500", "#f97316": "orange-500", "#f59e0b": "amber-500", "#eab308": "yellow-500", "#84cc16": "lime-500", "#22c55e": "green-500", "#10b981": "emerald-500", "#14b8a6": "teal-500", "#06b6d4": "cyan-500", "#0ea5e9": "sky-500", "#3b82f6": "blue-500", "#6366f1": "indigo-500", "#8b5cf6": "violet-500", "#a855f7": "purple-500", "#d946ef": "fuchsia-500", "#ec4899": "pink-500", "#f43f5e": "rose-500"}'

# Function: extract_design_tokens
# Extract design tokens (colors, fonts, spacing) from Figma data
extract_design_tokens() {
    local figma_data="$1"

    local colors=$(echo "$figma_data" | jq -r '
        [.document // {} | .. | .fills? // [] | .[] | .color? // {} |
         select(. != {}) |
         {r: .r, g: .g, b: .b, a: (.a // 1)} |
         "rgba(\(.r * 255 | floor),\(.g * 255 | floor),\(.b * 255 | floor),\(.a))"
        ] | unique
    ' 2>/dev/null || echo "[]")

    local fonts=$(echo "$figma_data" | jq -r '
        [.document // {} | .. | .style? // {} | .fontFamily? // empty] |
        unique
    ' 2>/dev/null || echo "[]")

    local spacing=$(echo "$figma_data" | jq -r '
        [.document // {} | .. |
         (.paddingLeft // .paddingRight // .paddingTop // .paddingBottom //
          .itemSpacing // .counterAxisSpacing // empty)
        ] | unique | sort | map(tostring)
    ' 2>/dev/null || echo "[]")

    jq -n \
        --argjson colors "$colors" \
        --argjson fonts "$fonts" \
        --argjson spacing "$spacing" \
        '{
            colors: $colors,
            fonts: $fonts,
            spacing: $spacing
        }'
}

# Function: rgb_to_hex
# Convert RGB to hex color
rgb_to_hex() {
    local r="$1"
    local g="$2"
    local b="$3"

    printf "#%02x%02x%02x\n" "$r" "$g" "$b"
}

# Function: find_closest_tailwind_color
# Find closest Tailwind color for a hex value
find_closest_tailwind_color() {
    local hex="$1"
    local hex_lower=$(echo "$hex" | tr '[:upper:]' '[:lower:]')

    # Check for exact match
    local exact=$(echo "$COLOR_TAILWIND_MAP" | jq -r --arg hex "$hex_lower" '.[$hex] // empty')
    if [ -n "$exact" ]; then
        echo "$exact"
        return 0
    fi

    # For now, return hex if no exact match
    # TODO: Implement color distance calculation for closest match
    echo "$hex_lower"
}

# Function: map_colors_to_tailwind
# Map extracted colors to Tailwind classes
map_colors_to_tailwind() {
    local colors="$1"

    echo "$colors" | jq -r '.[] |
        capture("rgba\\((?<r>[0-9]+),(?<g>[0-9]+),(?<b>[0-9]+),(?<a>[0-9.]+)\\)") |
        {r: (.r | tonumber), g: (.g | tonumber), b: (.b | tonumber), a: (.a | tonumber)}
    ' | while read -r color_obj; do
        local r=$(echo "$color_obj" | jq -r '.r')
        local g=$(echo "$color_obj" | jq -r '.g')
        local b=$(echo "$color_obj" | jq -r '.b')
        local a=$(echo "$color_obj" | jq -r '.a')

        local hex=$(rgb_to_hex "$r" "$g" "$b")
        local tailwind=$(find_closest_tailwind_color "$hex")

        jq -n \
            --arg hex "$hex" \
            --arg tw "$tailwind" \
            --arg opacity "$a" \
            '{hex: $hex, tailwind: $tw, opacity: ($opacity | tonumber)}'
    done | jq -s '.'
}

# Function: map_fonts_to_project
# Map Figma fonts to project font classes
map_fonts_to_project() {
    local fonts="$1"
    local project_fonts="${2:-{\"Inter\": \"font-sans\", \"Roboto\": \"font-sans\", \"SF Pro\": \"font-sans\", \"Helvetica\": \"font-sans\", \"Arial\": \"font-sans\"}}"

    echo "$fonts" | jq -r --argjson map "$project_fonts" '
        map({
            figma: .,
            project: ($map[.] // "font-sans")
        })
    '
}

# Function: map_spacing_to_tailwind
# Map spacing values to Tailwind spacing scale
map_spacing_to_tailwind() {
    local spacing="$1"

    echo "$spacing" | jq -r '.[] | tonumber' | while read -r px; do
        local rem=$(echo "scale=2; $px / 16" | bc)

        # Map to Tailwind scale (4px = 1 unit)
        local tw_unit=$(echo "scale=0; $px / 4" | bc)

        jq -n \
            --arg px "${px}px" \
            --arg rem "${rem}rem" \
            --arg tw "$tw_unit" \
            '{px: $px, rem: $rem, tailwind: $tw}'
    done | jq -s '.'
}

# Function: analyze_components
# Analyze component structure from Figma data
analyze_components() {
    local figma_data="$1"

    echo "$figma_data" | jq '
        [.document // {} | .. |
         select(.type? == "COMPONENT" or .type? == "INSTANCE") |
         {
             id: .id,
             name: .name,
             type: .type,
             width: .absoluteBoundingBox?.width,
             height: .absoluteBoundingBox?.height,
             children: [.children? // [] | .[] | .name] | unique
         }
        ]
    ' 2>/dev/null || echo "[]"
}

# Function: detect_layout_patterns
# Detect layout patterns (grid, flex, etc.)
detect_layout_patterns() {
    local figma_data="$1"

    echo "$figma_data" | jq '
        [.document // {} | .. |
         select(.layoutMode? != null) |
         {
             name: .name,
             layoutMode: .layoutMode,
             primaryAxisAlignItems: .primaryAxisAlignItems,
             counterAxisAlignItems: .counterAxisAlignItems,
             itemSpacing: .itemSpacing,
             paddingLeft: .paddingLeft,
             paddingRight: .paddingRight,
             paddingTop: .paddingTop,
             paddingBottom: .paddingBottom
         }
        ]
    ' 2>/dev/null || echo "[]"
}

# Function: extract_text_styles
# Extract text styles (font sizes, weights, line heights)
extract_text_styles() {
    local figma_data="$1"

    echo "$figma_data" | jq '
        [.document // {} | .. |
         select(.type? == "TEXT") |
         {
             text: .characters,
             fontFamily: .style?.fontFamily,
             fontSize: .style?.fontSize,
             fontWeight: .style?.fontWeight,
             lineHeight: .style?.lineHeightPx,
             letterSpacing: .style?.letterSpacing,
             textAlignHorizontal: .style?.textAlignHorizontal
         }
        ] |
        group_by(.fontSize) |
        map({
            fontSize: .[0].fontSize,
            examples: map({fontFamily, fontWeight, lineHeight})
        })
    ' 2>/dev/null || echo "[]"
}

# Function: generate_design_system
# Generate complete design system documentation
generate_design_system() {
    local figma_data="$1"
    local project_id="${2:-}"

    local tokens=$(extract_design_tokens "$figma_data")
    local colors=$(echo "$tokens" | jq -r '.colors')
    local fonts=$(echo "$tokens" | jq -r '.fonts')
    local spacing=$(echo "$tokens" | jq -r '.spacing')

    local color_map=$(map_colors_to_tailwind "$colors")
    local font_map=$(map_fonts_to_project "$fonts")
    local spacing_map=$(map_spacing_to_tailwind "$spacing")

    local components=$(analyze_components "$figma_data")
    local layouts=$(detect_layout_patterns "$figma_data")
    local text_styles=$(extract_text_styles "$figma_data")

    jq -n \
        --argjson tokens "$tokens" \
        --argjson color_map "$color_map" \
        --argjson font_map "$font_map" \
        --argjson spacing_map "$spacing_map" \
        --argjson components "$components" \
        --argjson layouts "$layouts" \
        --argjson text_styles "$text_styles" \
        '{
            designTokens: {
                colors: $tokens.colors,
                fonts: $tokens.fonts,
                spacing: $tokens.spacing
            },
            tailwindMappings: {
                colors: $color_map,
                fonts: $font_map,
                spacing: $spacing_map
            },
            components: $components,
            layoutPatterns: $layouts,
            textStyles: $text_styles
        }'
}

# Function: format_design_system_markdown
# Format design system as markdown for Linear comments
format_design_system_markdown() {
    local design_system="$1"
    local file_name="${2:-Design}"

    cat <<EOF
## 🎨 Design System Analysis: $file_name

### Color Palette

$(echo "$design_system" | jq -r '.tailwindMappings.colors[] | "- **\(.hex)** → `\(.tailwind)`" + (if .opacity < 1 then " (opacity: \(.opacity))" else "" end)')

### Typography

$(echo "$design_system" | jq -r '.tailwindMappings.fonts[] | "- **\(.figma)** → `\(.project)`"')

### Spacing Scale

$(echo "$design_system" | jq -r '.tailwindMappings.spacing[] | "- **\(.px)** (\(.rem)) → `space-\(.tailwind)`"')

### Components

$(echo "$design_system" | jq -r '.components[] | "- **\(.name)** (\(.type)) - \(.width)×\(.height)"')

### Layout Patterns

$(echo "$design_system" | jq -r '.layoutPatterns[] | "- **\(.name)** - \(.layoutMode) (spacing: \(.itemSpacing))"')

### Text Styles

$(echo "$design_system" | jq -r '.textStyles[] | "- **\(.fontSize)px** - \(.examples | length) variation(s)"')

---
*Auto-generated design system analysis (CCPM Figma Integration)*
EOF
}

# Main CLI
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    command="${1:-help}"

    case "$command" in
        extract-tokens)
            figma_data="${2:-}"
            if [ -z "$figma_data" ]; then
                echo "Usage: $0 extract-tokens <figma-data-json>" >&2
                exit 1
            fi
            extract_design_tokens "$figma_data"
            ;;

        analyze-components)
            figma_data="${2:-}"
            if [ -z "$figma_data" ]; then
                echo "Usage: $0 analyze-components <figma-data-json>" >&2
                exit 1
            fi
            analyze_components "$figma_data"
            ;;

        map-colors)
            colors="${2:-[]}"
            map_colors_to_tailwind "$colors"
            ;;

        map-fonts)
            fonts="${2:-[]}"
            project_fonts="${3:-{}}"
            map_fonts_to_project "$fonts" "$project_fonts"
            ;;

        map-spacing)
            spacing="${2:-[]}"
            map_spacing_to_tailwind "$spacing"
            ;;

        generate)
            figma_data="${2:-}"
            project_id="${3:-}"
            if [ -z "$figma_data" ]; then
                echo "Usage: $0 generate <figma-data-json> [project-id]" >&2
                exit 1
            fi
            generate_design_system "$figma_data" "$project_id"
            ;;

        format)
            design_system="${2:-}"
            file_name="${3:-Design}"
            if [ -z "$design_system" ]; then
                echo "Usage: $0 format <design-system-json> [file-name]" >&2
                exit 1
            fi
            format_design_system_markdown "$design_system" "$file_name"
            ;;

        *)
            cat <<EOF
figma-design-analyzer.sh - Analyze Figma design data

Usage:
  $0 extract-tokens <figma-data>      Extract design tokens (colors, fonts, spacing)
  $0 analyze-components <figma-data>  Analyze component structure
  $0 map-colors <colors-json>         Map colors to Tailwind classes
  $0 map-fonts <fonts-json>           Map fonts to project font classes
  $0 map-spacing <spacing-json>       Map spacing to Tailwind scale
  $0 generate <figma-data> [project]  Generate complete design system
  $0 format <design-system> [name]    Format design system as markdown

Examples:
  $0 extract-tokens "\$(cat figma-file.json)"
  $0 generate "\$(cat figma-file.json)" "my-project"
  $0 format "\$(cat design-system.json)" "Login Screen"
EOF
            ;;
    esac
fi
