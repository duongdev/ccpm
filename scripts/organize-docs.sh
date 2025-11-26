#!/bin/bash
# organize-docs.sh
# Generic documentation organizer following CCPM pattern
# Works with any repository

set -e  # Exit on error

# Configuration
REPO_PATH="."
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      REPO_PATH="$1"
      shift
      ;;
  esac
done

# Resolve absolute path
REPO_PATH="$(cd "$REPO_PATH" && pwd)"
cd "$REPO_PATH"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Documentation Analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Repository: $(basename "$REPO_PATH")"
echo "Path: $REPO_PATH"
echo ""

# Find markdown files in root
shopt -s nullglob
MD_FILES=(*.md)
shopt -u nullglob
ROOT_COUNT=${#MD_FILES[@]}

echo "📄 Found $ROOT_COUNT markdown files in root"
echo ""

if [ $ROOT_COUNT -le 5 ]; then
  echo "✅ Root is clean (≤5 files)"
else
  echo "⚠️  Too many files in root (>$ROOT_COUNT)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Categorization function
categorize_file() {
  local file="$1"
  local filename=$(basename "$file")

  # Keep in root
  case "$filename" in
    README.md|CHANGELOG.md|CONTRIBUTING.md|LICENSE|LICENSE.md|CLAUDE.md|MIGRATION.md)
      echo "root"
      return
      ;;
  esac

  # Guides (user-facing how-to)
  if [[ "$filename" =~ (GUIDE|INSTALL|SETUP|WORKFLOW|TUTORIAL) ]]; then
    echo "guides"
    return
  fi

  # Reference (API, catalog, reference)
  if [[ "$filename" =~ (CATALOG|REFERENCE|API|COMMANDS) ]]; then
    echo "reference"
    return
  fi

  # Architecture
  if [[ "$filename" =~ (ARCHITECTURE|DESIGN) ]]; then
    echo "architecture"
    return
  fi

  # Research (historical planning)
  if [[ "$filename" =~ (RESEARCH|PLAN|PROPOSAL|STATUS|SUMMARY|COMPARISON|MATRIX|QUICK.*REFERENCE) ]]; then
    echo "research"
    return
  fi

  echo "unknown"
}

# Convert filename to kebab-case
to_kebab() {
  echo "$1" | sed 's/\.md$//' | tr '[:upper:]' '[:lower:]' | sed 's/[_\ ]/-/g'
}

# Categorize all files
ROOT_FILES=""
GUIDE_FILES=""
REF_FILES=""
ARCH_FILES=""
RESEARCH_FILES=""
UNKNOWN_FILES=""

for file in "${MD_FILES[@]}"; do
  if [ -f "$file" ]; then
    category=$(categorize_file "$file")
    case "$category" in
      root)
        ROOT_FILES="$ROOT_FILES,$file"
        ;;
      guides)
        GUIDE_FILES="$GUIDE_FILES,$file"
        ;;
      reference)
        REF_FILES="$REF_FILES,$file"
        ;;
      architecture)
        ARCH_FILES="$ARCH_FILES,$file"
        ;;
      research)
        RESEARCH_FILES="$RESEARCH_FILES,$file"
        ;;
      *)
        UNKNOWN_FILES="$UNKNOWN_FILES,$file"
        ;;
    esac
  fi
done

# Remove leading commas
ROOT_FILES="${ROOT_FILES#,}"
GUIDE_FILES="${GUIDE_FILES#,}"
REF_FILES="${REF_FILES#,}"
ARCH_FILES="${ARCH_FILES#,}"
RESEARCH_FILES="${RESEARCH_FILES#,}"
UNKNOWN_FILES="${UNKNOWN_FILES#,}"

# Display categorization
echo "📦 Proposed File Organization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$ROOT_FILES" ]; then
  echo "✅ Keep in Root:"
  IFS=',' read -ra files <<< "$ROOT_FILES"
  for file in "${files[@]}"; do
    echo "  - $file"
  done
  echo ""
fi

if [ -n "$GUIDE_FILES" ]; then
  echo "📘 Move to docs/guides/:"
  IFS=',' read -ra files <<< "$GUIDE_FILES"
  for file in "${files[@]}"; do
    target=$(to_kebab "$file")
    echo "  - $file → docs/guides/${target}.md"
  done
  echo ""
fi

if [ -n "$REF_FILES" ]; then
  echo "📖 Move to docs/reference/:"
  IFS=',' read -ra files <<< "$REF_FILES"
  for file in "${files[@]}"; do
    target=$(to_kebab "$file")
    echo "  - $file → docs/reference/${target}.md"
  done
  echo ""
fi

if [ -n "$ARCH_FILES" ]; then
  echo "🏗️ Move to docs/architecture/:"
  IFS=',' read -ra files <<< "$ARCH_FILES"
  for file in "${files[@]}"; do
    target=$(to_kebab "$file")
    echo "  - $file → docs/architecture/${target}.md"
  done
  echo ""
fi

if [ -n "$RESEARCH_FILES" ]; then
  echo "📚 Move to docs/research/:"
  IFS=',' read -ra files <<< "$RESEARCH_FILES"
  for file in "${files[@]}"; do
    target=$(to_kebab "$file")
    echo "  - $file → docs/research/${target}.md"
  done
  echo ""
fi

if [ -n "$UNKNOWN_FILES" ]; then
  echo "❓ Unknown (will skip):"
  IFS=',' read -ra files <<< "$UNKNOWN_FILES"
  for file in "${files[@]}"; do
    echo "  - $file"
  done
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "🔍 DRY RUN - No changes will be made"
  echo ""
  echo "Run without --dry-run to apply changes."
  exit 0
fi

# Ask for confirmation
read -p "Proceed with reorganization? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

echo ""
echo "📁 Creating directory structure..."
mkdir -p docs/{guides,reference,architecture/decisions,development,research}
echo "✅ Directory structure created"
echo ""

# Move files
echo "📦 Moving files..."
MOVED_COUNT=0

move_file() {
  local file="$1"
  local target="$2"

  if [ -f "$file" ]; then
    mv "$file" "$target"
    echo "  ✓ $file → $target"
    ((MOVED_COUNT++))
  fi
}

if [ -n "$GUIDE_FILES" ]; then
  IFS=',' read -ra files <<< "$GUIDE_FILES"
  for file in "${files[@]}"; do
    target=$(to_kebab "$file")
    move_file "$file" "docs/guides/${target}.md"
  done
fi

if [ -n "$REF_FILES" ]; then
  IFS=',' read -ra files <<< "$REF_FILES"
  for file in "${files[@]}"; do
    target=$(to_kebab "$file")
    move_file "$file" "docs/reference/${target}.md"
  done
fi

if [ -n "$ARCH_FILES" ]; then
  IFS=',' read -ra files <<< "$ARCH_FILES"
  for file in "${files[@]}"; do
    target=$(to_kebab "$file")
    move_file "$file" "docs/architecture/${target}.md"
  done
fi

if [ -n "$RESEARCH_FILES" ]; then
  IFS=',' read -ra files <<< "$RESEARCH_FILES"
  for file in "${files[@]}"; do
    target=$(to_kebab "$file")
    move_file "$file" "docs/research/${target}.md"
  done
fi

echo "✅ Moved $MOVED_COUNT files"
echo ""

# Create index files
echo "📄 Creating index files..."

# docs/README.md
cat > docs/README.md << 'EOF'
# Documentation

Welcome to the documentation.

## Quick Links

- **[Guides](guides/)** - How-to guides and tutorials
- **[Reference](reference/)** - API and feature reference
- **[Architecture](architecture/)** - Design decisions and ADRs
- **[Development](development/)** - Contributor documentation
- **[Research](research/)** - Historical context (archived)

## Documentation Structure

### 📘 [Guides](guides/)
User-facing how-to guides, installation instructions, and tutorials.

### 📖 [Reference](reference/)
Comprehensive reference for APIs, commands, and features.

### 🏗️ [Architecture](architecture/)
Architecture overviews and decision records (ADRs).

### 🔧 [Development](development/)
Documentation for contributors and maintainers.

### 📚 [Research](research/)
Historical research and planning documents (archived).

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.
EOF

# docs/guides/README.md
cat > docs/guides/README.md << 'EOF'
# User Guides

How-to guides and tutorials.

## Getting Started

Browse the guides in this directory for detailed instructions.

## Need Help?

See the main [Documentation Index](../README.md).
EOF

# docs/reference/README.md
cat > docs/reference/README.md << 'EOF'
# Reference Documentation

Comprehensive reference for APIs, commands, and features.

Browse the reference documentation in this directory.

See the main [Documentation Index](../README.md) for more resources.
EOF

# docs/architecture/README.md
cat > docs/architecture/README.md << 'EOF'
# Architecture Documentation

Architecture overviews and design decisions.

## Architecture Decision Records (ADRs)

See [decisions/](decisions/) for all architecture decisions.

See the main [Documentation Index](../README.md) for more resources.
EOF

# docs/development/README.md
cat > docs/development/README.md << 'EOF'
# Development Documentation

Documentation for contributors and maintainers.

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for full contribution guidelines.
EOF

# docs/research/README.md
cat > docs/research/README.md << 'EOF'
# Research & Planning Documents

**Archived historical documents** - For current docs, see main [Documentation](../README.md).

## Purpose

These documents explain why decisions were made and how features were researched.

**Note**: May be outdated - refer to main docs for current state.
EOF

echo "  ✓ Created 6 index files"
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Documentation Reorganization Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Summary:"
echo "  ✓ Files moved: $MOVED_COUNT"
echo "  ✓ Index files created: 6"
echo "  ✓ Directory structure: docs/{guides,reference,architecture,development,research}"
echo ""

# Count current root files
FINAL_COUNT=$(ls -1 *.md 2>/dev/null | wc -l | tr -d ' ')
echo "📁 Root directory:"
echo "  Before: $ROOT_COUNT markdown files"
echo "  After: $FINAL_COUNT markdown files"
echo ""

echo "📝 Next Steps:"
echo "  1. Review changes: git status"
echo "  2. Update internal links in moved files"
echo "  3. Update README.md with new structure"
echo "  4. Commit changes: git add . && git commit -m 'docs: reorganize documentation'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
