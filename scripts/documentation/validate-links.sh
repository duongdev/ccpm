#!/bin/bash
# validate-links.sh
# Comprehensive link validation for CCPM documentation

set -euo pipefail

# Dynamically resolve plugin directory (repository root)
if [ -z "${CCPM_PLUGIN_DIR:-}" ]; then
  # Try standard installation location
  if [ -d "$HOME/.claude/plugins/ccpm" ]; then
    CCPM_PLUGIN_DIR="$HOME/.claude/plugins/ccpm"
  # Try running from within plugin directory
  elif [ -d "$(dirname "$0")/../../.." ]; then
    CCPM_PLUGIN_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
  else
    echo "Error: CCPM plugin not found"
    exit 1
  fi
fi

REPO_ROOT="$CCPM_PLUGIN_DIR"
ERRORS=0
WARNINGS=0
CHECKED=0

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output helpers
error() { echo -e "${RED}❌ ERROR: $1${NC}" >&2; ((ERRORS++)); }
warn() { echo -e "${YELLOW}⚠️  WARNING: $1${NC}"; ((WARNINGS++)); }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }

echo "🔗 CCPM Link Validation"
echo "======================="
echo ""

# Extract all markdown links from a file
extract_links() {
    local file=$1
    # Match [text](url) format, extract URL
    grep -oP '\[([^\]]+)\]\(([^)]+)\)' "$file" 2>/dev/null | sed 's/.*](\(.*\))/\1/' || true
}

# Extract all headings from a file for anchor validation
extract_headings() {
    local file=$1
    # Match # Heading, ## Heading, etc.
    grep -oP '^#{1,6} .+' "$file" 2>/dev/null | sed 's/^#* //' || true
}

# Convert heading to anchor format
heading_to_anchor() {
    local heading=$1
    # Convert to lowercase, replace spaces with hyphens, remove special chars
    echo "$heading" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g'
}

# Check if heading anchor exists in file
check_anchor() {
    local file=$1
    local anchor=$2

    # Extract all headings and convert to anchors
    while IFS= read -r heading; do
        local heading_anchor=$(heading_to_anchor "$heading")
        if [[ "$heading_anchor" == "$anchor" ]]; then
            return 0
        fi
    done < <(extract_headings "$file")

    return 1
}

# Check internal link
check_internal_link() {
    local source_file=$1
    local link=$2
    local relative_source="${source_file#$REPO_ROOT/}"

    ((CHECKED++))

    # Handle anchor-only links (#section)
    if [[ "$link" == \#* ]]; then
        local anchor="${link#\#}"
        if check_anchor "$source_file" "$anchor"; then
            return 0
        else
            error "Broken anchor in $relative_source: $link (heading not found)"
            return 1
        fi
    fi

    # Split link into file path and anchor
    local file_part="${link%%#*}"
    local anchor_part=""
    if [[ "$link" == *#* ]]; then
        anchor_part="${link#*#}"
    fi

    # Resolve relative path
    local source_dir=$(dirname "$source_file")
    local target_file

    if [[ "$file_part" == /* ]]; then
        # Absolute path from repo root
        target_file="$REPO_ROOT${file_part}"
    else
        # Relative path
        target_file=$(cd "$source_dir" && realpath -m "$file_part" 2>/dev/null) || {
            error "Invalid link in $relative_source: $link (cannot resolve path)"
            return 1
        }
    fi

    # Check if target file exists
    if [[ ! -f "$target_file" ]]; then
        error "Broken link in $relative_source: $link → target file not found: ${target_file#$REPO_ROOT/}"
        return 1
    fi

    # If there's an anchor, check it exists in target file
    if [[ -n "$anchor_part" ]]; then
        if ! check_anchor "$target_file" "$anchor_part"; then
            error "Broken anchor in $relative_source: $link → anchor #$anchor_part not found in ${target_file#$REPO_ROOT/}"
            return 1
        fi
    fi

    return 0
}

# Check external link (optional, warns only)
check_external_link() {
    local source_file=$1
    local link=$2

    # Skip checking external links by default (can be slow)
    # Just count them
    return 0
}

# Check image link
check_image_link() {
    local source_file=$1
    local link=$2
    local relative_source="${source_file#$REPO_ROOT/}"

    ((CHECKED++))

    # Skip external images
    if [[ "$link" == http* ]]; then
        return 0
    fi

    # Resolve relative path
    local source_dir=$(dirname "$source_file")
    local target_file

    if [[ "$link" == /* ]]; then
        target_file="$REPO_ROOT${link}"
    else
        target_file=$(cd "$source_dir" && realpath -m "$link" 2>/dev/null) || {
            error "Invalid image link in $relative_source: $link (cannot resolve path)"
            return 1
        }
    fi

    # Check if image exists
    if [[ ! -f "$target_file" ]]; then
        error "Broken image link in $relative_source: $link → file not found: ${target_file#$REPO_ROOT/}"
        return 1
    fi

    return 0
}

# Main validation loop
info "Scanning markdown files..."
echo ""

find "$REPO_ROOT" -name "*.md" -type f \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/build/*" \
    ! -path "*/dist/*" \
    | sort | while read -r file; do

    relative_path="${file#$REPO_ROOT/}"
    echo "Checking: $relative_path"

    # Extract and check regular links [text](url)
    while IFS= read -r link; do
        # Skip empty links
        [[ -z "$link" ]] && continue

        # Categorize link
        if [[ "$link" == http://* ]] || [[ "$link" == https://* ]]; then
            # External link
            check_external_link "$file" "$link" || true
        elif [[ "$link" == mailto:* ]] || [[ "$link" == tel:* ]]; then
            # Special protocol
            ((CHECKED++))
        else
            # Internal link
            check_internal_link "$file" "$link" || true
        fi
    done < <(extract_links "$file")

    # Extract and check image links ![alt](url)
    while IFS= read -r img_line; do
        # Extract URL from ![alt](url)
        local img_url=$(echo "$img_line" | sed 's/.*!\\[.*\\](\(.*\))/\1/')
        [[ -z "$img_url" ]] && continue

        check_image_link "$file" "$img_url" || true
    done < <(grep -oP '!\[([^\]]*)\]\(([^)]+)\)' "$file" 2>/dev/null || true)
done

echo ""
echo "================================"
echo "Link Validation Summary"
echo "================================"
echo "Total links checked: $CHECKED"
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [[ $ERRORS -eq 0 ]]; then
    success "All links are valid!"
    exit 0
else
    error "Found $ERRORS broken links"
    exit 1
fi
