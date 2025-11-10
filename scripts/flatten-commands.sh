#!/bin/bash

# Flatten command directory structure for Claude Code plugin discovery
# Converts: commands/spec/create.md → commands/pm:spec:create.md

set -e

cd "$(dirname "$0")/.."

echo "🔄 Flattening commands directory structure..."
echo ""

# Create temp directory for new structure
mkdir -p commands/.tmp

# Move all nested command files to flat structure with namespace prefixes
find commands -name "*.md" -type f ! -name "README.md" ! -name "SAFETY_RULES.md" ! -name "SPEC_MANAGEMENT_SUMMARY.md" ! -name "_*.md" | while read -r file; do
    # Get relative path from commands/
    rel_path="${file#commands/}"

    # Extract directory and filename
    dir=$(dirname "$rel_path")
    name=$(basename "$rel_path")

    # Skip if already in commands root
    if [ "$dir" == "." ]; then
        echo "⏭️  Skipping root-level: $name"
        continue
    fi

    # Create new filename with namespace
    new_name="pm:${dir}:${name}"

    echo "📝 Moving: $file → commands/$new_name"
    mv "$file" "commands/.tmp/$new_name"
done

echo ""
echo "🗑️  Removing empty subdirectories..."

# Remove now-empty subdirectories
find commands -mindepth 1 -type d ! -name ".tmp" -exec rm -rf {} + 2>/dev/null || true

echo ""
echo "✅ Moving flattened files back..."

# Move files from temp back to commands root
mv commands/.tmp/* commands/ 2>/dev/null || true
rmdir commands/.tmp

echo ""
echo "✅ Command structure flattened successfully!"
echo ""
echo "📊 New command list:"
find commands -name "pm:*.md" -type f | sort
