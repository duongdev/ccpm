---
description: Organize repository documentation following CCPM pattern
allowed-tools: [Bash, Read, Write, Edit, Glob, AskUserQuestion]
argument-hint: [repo-path] [--dry-run] [--global]
---

# Organize Documentation

Reorganizes repository documentation following the CCPM documentation pattern for clean, navigable, and scalable documentation structure.

## Arguments

- **$1** - (Optional) Repository path (default: current directory)
- **$2** - (Optional) `--dry-run` to preview changes without applying
- **$3** - (Optional) `--global` to install pattern globally in `~/.claude/templates/`

## Workflow

### Step 1: Analyze Current Structure

```javascript
const repoPath = $1 || process.cwd()
const dryRun = args.includes('--dry-run')
const installGlobal = args.includes('--global')

// Analyze current documentation
const analysis = {
  rootMarkdownFiles: findMarkdownFiles(repoPath, { maxDepth: 1 }),
  existingDocsDir: dirExists(`${repoPath}/docs`),
  categories: {
    guides: [],
    reference: [],
    architecture: [],
    research: []
  }
}

// Categorize files
analysis.rootMarkdownFiles.forEach(file => {
  const category = categorizeFi le(file)
  if (category) {
    analysis.categories[category].push(file)
  }
})
```

Display analysis:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Documentation Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Repository: ${basename(repoPath)}
Path: ${repoPath}

📄 Found ${analysis.rootMarkdownFiles.length} markdown files in root

${analysis.rootMarkdownFiles.length > 5 ? '⚠️  Too many files in root (>5)' : '✅ Root is clean (≤5 files)'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 2: Categorize Files

Categorization rules:

```javascript
function categorizeFile(filename) {
  // Keep in root
  const keepInRoot = [
    'README.md',
    'CHANGELOG.md',
    'CONTRIBUTING.md',
    'LICENSE.md',
    'LICENSE',
    'CLAUDE.md',
    'MIGRATION.md'
  ]

  if (keepInRoot.includes(filename)) {
    return 'root'
  }

  // Guides (user-facing how-to)
  if (filename.match(/GUIDE|INSTALL|SETUP|WORKFLOW|TUTORIAL/i)) {
    return 'guides'
  }

  // Reference (API, catalog, reference)
  if (filename.match(/CATALOG|REFERENCE|API|COMMANDS/i)) {
    return 'reference'
  }

  // Architecture
  if (filename.match(/ARCHITECTURE|DESIGN/i)) {
    return 'architecture'
  }

  // Research (historical planning)
  if (filename.match(/RESEARCH|PLAN|PROPOSAL|STATUS|SUMMARY|COMPARISON|MATRIX|QUICK.?REFERENCE/i)) {
    return 'research'
  }

  return null // Unknown, ask user
}
```

Display categorization:

```
📦 Proposed File Organization
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Keep in Root (${analysis.categories.root?.length || 0}):
${analysis.categories.root?.map(f => `  - ${f}`).join('\n') || '  (none)'}

📘 Move to docs/guides/ (${analysis.categories.guides.length}):
${analysis.categories.guides.map(f => `  - ${f} → docs/guides/${kebabCase(f)}`).join('\n') || '  (none)'}

📖 Move to docs/reference/ (${analysis.categories.reference.length}):
${analysis.categories.reference.map(f => `  - ${f} → docs/reference/${kebabCase(f)}`).join('\n') || '  (none)'}

🏗️ Move to docs/architecture/ (${analysis.categories.architecture.length}):
${analysis.categories.architecture.map(f => `  - ${f} → docs/architecture/${kebabCase(f)}`).join('\n') || '  (none)'}

📚 Move to docs/research/ (${analysis.categories.research.length}):
${analysis.categories.research.map(f => `  - ${f} → docs/research/${categorizeTopic(f)}/${kebabCase(f)}`).join('\n') || '  (none)'}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 3: Ask for Confirmation

Use AskUserQuestion for files with unclear categorization:

```javascript
{
  questions: [{
    question: "Some files need categorization. Where should these go?",
    header: "Categorize",
    multiSelect: false,
    options: [
      {
        label: "Apply Auto-Categorization",
        description: "Use CCPM pattern rules for all files"
      },
      {
        label: "Review Each File",
        description: "I'll categorize unclear files manually"
      },
      {
        label: "Cancel",
        description: "Don't reorganize"
      }
    ]
  }]
}
```

If "Review Each File" selected, ask for each unclear file:

```javascript
{
  questions: [{
    question: `Where should ${filename} go?`,
    header: "Categorize File",
    multiSelect: false,
    options: [
      { label: "Keep in Root", description: "Important user-facing file" },
      { label: "docs/guides/", description: "User how-to guide" },
      { label: "docs/reference/", description: "API or feature reference" },
      { label: "docs/architecture/", description: "Design decision" },
      { label: "docs/research/", description: "Historical planning (archive)" },
      { label: "Skip", description: "Don't move this file" }
    ]
  }]
}
```

### Step 4: Apply Changes

If `--dry-run`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 DRY RUN - No changes will be made
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Would perform these operations:

📁 Create directories:
  ✓ docs/guides/
  ✓ docs/reference/
  ✓ docs/architecture/decisions/
  ✓ docs/development/
  ✓ docs/research/

📦 Move files (${totalMoves}):
  ${moves.map(m => `  ${m.from} → ${m.to}`).join('\n')}

📄 Create index files (6):
  ✓ docs/README.md
  ✓ docs/guides/README.md
  ✓ docs/reference/README.md
  ✓ docs/architecture/README.md
  ✓ docs/development/README.md
  ✓ docs/research/README.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run without --dry-run to apply changes.
```

If not dry-run, execute:

```bash
#!/bin/bash
set -e

cd "${repoPath}"

# Phase 1: Create directory structure
echo "📁 Creating directory structure..."
mkdir -p docs/{guides,reference,architecture/decisions,development,research}

# Phase 2: Move files
echo "📦 Moving files..."
${moves.map(m => `
if [ -f "${m.from}" ]; then
  mv "${m.from}" "${m.to}"
  echo "  ✓ ${m.from} → ${m.to}"
fi`).join('\n')}

# Phase 3: Create index files
echo "📄 Creating index files..."
# [Generate index file content using templates]

echo "✅ Documentation reorganization complete!"
```

### Step 5: Create Index Files

Use CCPM templates for all index files:

**docs/README.md**:
```markdown
# [Project] Documentation

Welcome to the [Project] documentation.

## Quick Links

- **[Quick Start](guides/quick-start.md)** - Get started in 5 minutes
- **[Installation](guides/installation.md)** - Detailed setup
- **[Reference](reference/)** - Complete documentation

## Documentation Structure

### 📘 [Guides](guides/) - How-to guides
- [Quick Start](guides/quick-start.md)
- [Installation](guides/installation.md)

### 📖 [Reference](reference/) - API & feature reference
- [API](reference/api.md)
- [Configuration](reference/config.md)

### 🏗️ [Architecture](architecture/) - Design decisions
- [Overview](architecture/overview.md)
- [Decisions](architecture/decisions/)

### 🔧 [Development](development/) - For contributors
- [Setup](development/setup.md)
- [Testing](development/testing.md)

### 📚 [Research](research/) - Historical context
Archived research and planning documents.

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md).
```

**docs/guides/README.md**:
```markdown
# User Guides

How-to guides for using [Project].

## Getting Started

- [Quick Start](quick-start.md) - 5-minute introduction
- [Installation](installation.md) - Detailed installation

## Features

[Auto-generated list of guides]

## Need Help?

See the main [Documentation Index](../README.md).
```

**docs/research/README.md**:
```markdown
# Research & Planning Documents

**Archived historical documents** - For current docs, see main [Documentation](../README.md).

## Purpose

These documents explain why decisions were made and how features were researched.

**Note**: May be outdated - refer to main docs for current state.

## Contents

[Auto-generated list of research topics]
```

### Step 6: Update Links

Scan all moved files for internal links and update them:

```javascript
// Find all markdown links
const linkPattern = /\[([^\]]+)\]\(([^)]+)\)/g

movedFiles.forEach(file => {
  let content = readFile(file.newPath)
  let updated = false

  content = content.replace(linkPattern, (match, text, url) => {
    if (url.startsWith('http')) return match // External link

    // Calculate new relative path
    const oldPath = resolvePath(file.oldPath, url)
    const newPath = calculateRelativePath(file.newPath, oldPath)

    if (newPath !== url) {
      updated = true
      return `[${text}](${newPath})`
    }

    return match
  })

  if (updated) {
    writeFile(file.newPath, content)
  }
})
```

Display link updates:

```
🔗 Updating Internal Links
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Updated links in ${updatedFiles.length} files:
${updatedFiles.map(f => `  ✓ ${f.path} (${f.linksUpdated} links)`).join('\n')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 7: Update CLAUDE.md

If CLAUDE.md exists, add documentation pattern section:

```javascript
const claudeMdPath = `${repoPath}/CLAUDE.md`

if (fileExists(claudeMdPath)) {
  const claudeMd = readFile(claudeMdPath)

  // Check if documentation section already exists
  if (!claudeMd.includes('## Documentation Structure') && !claudeMd.includes('## Documentation Pattern')) {
    const documentationSection = generateDocumentationSection(analysis)

    // Append to CLAUDE.md
    appendToFile(claudeMdPath, `\n\n${documentationSection}`)
  } else {
    // Update existing section
    updateDocumentationSection(claudeMdPath, analysis)
  }
}
```

Documentation section template:

```markdown
## Documentation Structure

This repository follows the CCPM documentation pattern for clean, navigable, and scalable documentation.

### Pattern Overview

```
docs/
├── README.md               # Documentation navigation hub
├── guides/                 # 📘 User how-to guides
├── reference/              # 📖 API & feature reference
├── architecture/           # 🏗️ Design decisions & ADRs
├── development/            # 🔧 Contributor documentation
└── research/               # 📚 Historical context (archived)
```

### Documentation Guidelines

**When creating new documentation:**

1. **User guides** → `docs/guides/`
   - Installation, setup, configuration
   - Feature walkthroughs and tutorials
   - Troubleshooting guides
   - Use descriptive filenames: `installation.md`, `quick-start.md`

2. **Reference documentation** → `docs/reference/`
   - API documentation
   - Command/feature catalogs
   - Configuration references
   - Technical specifications

3. **Architecture documentation** → `docs/architecture/`
   - System architecture overviews
   - Component designs
   - Architecture Decision Records (ADRs) in `decisions/`
   - Use ADR template for decisions

4. **Development documentation** → `docs/development/`
   - Development environment setup
   - Testing guides
   - Release processes
   - Contribution workflows

5. **Research/Planning documents** → `docs/research/`
   - Historical planning documents
   - Research findings
   - Implementation journeys
   - **Note**: These are archived - current docs go elsewhere

### Root Directory Rules

**Keep ONLY these files in root:**
- `README.md` - Main entry point
- `CHANGELOG.md` - Version history
- `CONTRIBUTING.md` - Contribution guide
- `LICENSE` - License file
- `CLAUDE.md` - This file
- `MIGRATION.md` - Migration guide (if applicable)

**All other documentation goes in `docs/`**

### Index Files

Each documentation directory has a `README.md` that:
- Explains what the directory contains
- Links to all documents in that directory
- Provides navigation back to main docs

### Maintaining Documentation

**When you create or move documentation:**

1. Place it in the appropriate `docs/` subdirectory
2. Update the relevant index `README.md`
3. Update internal links to use correct relative paths
4. Keep root directory clean (≤5 markdown files)

**When you reference documentation:**

1. Use relative links from current location
2. Link to `docs/README.md` for main navigation
3. Link to specific guides/references as needed

### Auto-Organization

To reorganize documentation automatically:

```bash
/ccpm:utils:organize-docs [repo-path] [--dry-run] [--global]
```

This command:
- Analyzes current documentation structure
- Categorizes files using CCPM pattern rules
- Moves files to appropriate locations
- Creates index files
- Updates internal links
- Can be installed globally for use in any repository

### Navigation

All documentation is accessible from `docs/README.md`:
- **Quick Start**: `docs/guides/quick-start.md`
- **Full Documentation**: Browse by category in `docs/`
- **Contributing**: `CONTRIBUTING.md`

### Pattern Benefits

- ✅ Clean root directory
- ✅ Clear separation of concerns
- ✅ Easy to find documentation
- ✅ Scales with project growth
- ✅ Historical context preserved
- ✅ AI assistant friendly
- ✅ Consistent across projects
```

Display update confirmation:

```
📝 Updating CLAUDE.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

${exists ? '✓ Updated documentation structure section' : '✓ Added documentation structure section'}

CLAUDE.md now includes:
  - Documentation pattern overview
  - Guidelines for new documentation
  - Root directory rules
  - Index file conventions
  - Auto-organization instructions
  - Navigation guidelines

This ensures AI assistants always follow the pattern.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 8: Global Installation (if --global)

If `--global` flag is set:

```bash
#!/bin/bash
set -e

echo "🌍 Installing CCPM docs pattern globally..."

# Create global template directory
mkdir -p ~/.claude/templates/ccpm-docs-pattern
mkdir -p ~/.claude/scripts

# Copy pattern documentation
cp GLOBAL_DOCS_PATTERN.md ~/.claude/templates/ccpm-docs-pattern/

# Copy organize script
cp scripts/organize-docs.sh ~/.claude/templates/ccpm-docs-pattern/

# Create global auto-organize script
cat > ~/.claude/scripts/organize-docs << 'SCRIPT'
#!/bin/bash
# Auto-organize documentation for any repository

REPO_PATH="${1:-.}"
cd "$REPO_PATH" || exit 1

# Use CCPM organize command
claude /ccpm:utils:organize-docs "$REPO_PATH"
SCRIPT

chmod +x ~/.claude/scripts/organize-docs

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.claude/scripts:"* ]]; then
  echo ""
  echo "Add to your shell profile (~/.zshrc or ~/.bashrc):"
  echo "  export PATH=\"\$HOME/.claude/scripts:\$PATH\""
fi

echo "✅ Global installation complete!"
echo ""
echo "Usage in any repository:"
echo "  organize-docs"
echo "  organize-docs /path/to/repo"
echo "  organize-docs --dry-run"
```

### Step 9: Summary

Display completion summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Documentation Reorganization Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Summary:
  ✓ Root files: ${before} → ${after} (-${reduction}%)
  ✓ Files moved: ${movedCount}
  ✓ Index files created: 6
  ✓ Links updated: ${linksUpdated}

📁 New Structure:
  docs/
  ├── guides/          (${guidesCount} files)
  ├── reference/       (${referenceCount} files)
  ├── architecture/    (${architectureCount} files)
  ├── development/     (${developmentCount} files)
  └── research/        (${researchCount} files, archived)

📝 Next Steps:
  1. Review changes: git status
  2. Test documentation links
  3. Update README.md with new structure
  ${hasClaude ? '4. ✅ CLAUDE.md updated with documentation pattern' : ''}
  5. Commit changes: git add . && git commit -m "docs: reorganize documentation"

${installGlobal ? `
🌍 Global Pattern Installed:
  Pattern available at: ~/.claude/templates/ccpm-docs-pattern/
  Command available: organize-docs

  Use in any repository:
    cd ~/projects/any-repo
    organize-docs
` : `
💡 Install Globally:
  Run: /ccpm:utils:organize-docs . --global
  Then use 'organize-docs' in any repository
`}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Examples

### Example 1: Analyze Current Repository

```bash
/ccpm:utils:organize-docs --dry-run
```

Output:
- Analysis of current structure
- Proposed changes
- No files moved

### Example 2: Reorganize Current Repository

```bash
/ccpm:utils:organize-docs
```

Performs:
1. Analyzes documentation
2. Shows categorization
3. Asks for confirmation
4. Creates docs/ structure
5. Moves files
6. Creates index files
7. Updates links
8. Shows summary

### Example 3: Reorganize Different Repository

```bash
/ccpm:utils:organize-docs ~/projects/my-app
```

Same as Example 2 but for different repository.

### Example 4: Install Global Pattern

```bash
/ccpm:utils:organize-docs . --global
```

Performs:
1. Reorganizes current repository
2. Installs pattern to ~/.claude/templates/
3. Creates global organize-docs script
4. Adds to PATH

Then can use in any repo:
```bash
cd ~/projects/any-repo
organize-docs
```

## File Categorization Rules

### Keep in Root
- README.md - Entry point
- CHANGELOG.md - Version history
- CONTRIBUTING.md - Contribution guide
- LICENSE/LICENSE.md - License
- CLAUDE.md - AI assistant instructions
- MIGRATION.md - Migration guide

### docs/guides/
Files matching: `*GUIDE*`, `*INSTALL*`, `*SETUP*`, `*WORKFLOW*`, `*TUTORIAL*`

Examples:
- INSTALL_HOOKS.md → docs/guides/hooks.md
- MCP_INTEGRATION_GUIDE.md → docs/guides/mcp-integration.md
- UI_WORKFLOW.md → docs/guides/ui-workflow.md

### docs/reference/
Files matching: `*CATALOG*`, `*REFERENCE*`, `*API*`, `*COMMANDS*`

Examples:
- SKILLS_CATALOG.md → docs/reference/skills.md
- API_REFERENCE.md → docs/reference/api.md

### docs/architecture/
Files matching: `*ARCHITECTURE*`, `*DESIGN*`

Examples:
- SKILLS_ARCHITECTURE.md → docs/architecture/skills-system.md
- SYSTEM_DESIGN.md → docs/architecture/overview.md

### docs/research/
Files matching: `*RESEARCH*`, `*PLAN*`, `*PROPOSAL*`, `*STATUS*`, `*SUMMARY*`, `*COMPARISON*`, `*MATRIX*`

Examples:
- SKILLS_INTEGRATION_PLAN.md → docs/research/skills/integration-plan.md
- HOOKS_RESEARCH_SUMMARY.md → docs/research/hooks/research-summary.md

## Notes

- Always creates backup before moving files (git makes this easy)
- Preserves git history for moved files
- Updates internal markdown links automatically
- Creates index files for easy navigation
- **Updates CLAUDE.md** with documentation pattern instructions
- Ensures AI assistants always follow the pattern
- Follows CCPM documentation pattern globally
- Can be used on any repository, not just CCPM
- Dry-run mode for safe preview
- Global installation for reuse across all projects

## Success Metrics

After running this command:
- ✅ Root directory has ≤5 markdown files
- ✅ All docs reachable within 2 clicks from docs/README.md
- ✅ Clear separation: guides/reference/architecture/research
- ✅ Index files guide navigation
- ✅ Historical context preserved in research/
- ✅ Pattern reusable across projects
