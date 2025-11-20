# Global Documentation Pattern (CCPM Style)

This document defines a reusable documentation pattern that follows CCPM's organization principles and can be applied to any repository.

## Core Principles

1. **Root Minimalism** - Keep root directory clean (≤5 files)
2. **User-First** - Guides before reference, practical before theoretical
3. **Progressive Discovery** - Easy navigation with clear hierarchy
4. **Historical Context** - Preserve research but archive it
5. **AI-Friendly** - Clear structure for AI assistants to understand

## Universal Documentation Structure

```
<repository>/
├── README.md                    # Entry point (required)
├── CHANGELOG.md                 # Version history (optional)
├── CONTRIBUTING.md              # Contribution guide (optional)
├── LICENSE                      # License file (required for OSS)
├── CLAUDE.md                    # AI assistant instructions (if using Claude Code)
│
├── docs/                        # All documentation
│   ├── README.md                # Documentation index (navigation hub)
│   │
│   ├── guides/                  # 📘 User-facing How-To guides
│   │   ├── README.md            # Guides index
│   │   ├── quick-start.md       # 5-minute quickstart
│   │   ├── installation.md      # Detailed installation
│   │   └── [feature].md         # Feature-specific guides
│   │
│   ├── reference/               # 📖 API/Feature reference
│   │   ├── README.md            # Reference index
│   │   ├── api.md               # API reference (if applicable)
│   │   ├── cli.md               # CLI reference (if applicable)
│   │   ├── config.md            # Configuration reference
│   │   └── [component].md       # Component references
│   │
│   ├── architecture/            # 🏗️ Design & architecture
│   │   ├── README.md            # Architecture index
│   │   ├── overview.md          # High-level system architecture
│   │   ├── [system].md          # System-specific architecture
│   │   └── decisions/           # Architecture Decision Records
│   │       ├── README.md        # ADR index
│   │       └── XXX-[title].md   # Individual ADRs
│   │
│   ├── development/             # 🔧 Contributor documentation
│   │   ├── README.md            # Development index
│   │   ├── setup.md             # Dev environment setup
│   │   ├── testing.md           # Testing guide
│   │   ├── release.md           # Release process
│   │   └── roadmap.md           # Future plans
│   │
│   └── research/                # 📚 Historical planning (archived)
│       ├── README.md            # Research index (explains purpose)
│       └── [topic]/             # Organized by topic
│           └── *.md             # Research documents
│
├── src/                         # Source code
├── tests/                       # Tests
└── scripts/                     # Automation scripts
```

## File Naming Conventions

### Root Files (Keep Minimal)
- `README.md` - Project overview, badges, quick links
- `CHANGELOG.md` - Version history in Keep a Changelog format
- `CONTRIBUTING.md` - How to contribute
- `LICENSE` - License file
- `CLAUDE.md` - AI assistant instructions (if applicable)

### Documentation Files (In docs/)
- Use lowercase with hyphens: `quick-start.md`, `api-reference.md`
- Use descriptive names: `installation.md` not `install.md`
- Index files always named `README.md`

### Research Files (Archived)
- Use descriptive prefixes: `[TOPIC]_[TYPE].md`
- Example: `skills_integration-plan.md`, `hooks_research-summary.md`

## Content Templates

### docs/README.md (Navigation Hub)

```markdown
# [Project Name] Documentation

Brief description of the project.

## Quick Links

- **[Quick Start](guides/quick-start.md)** - Get started in 5 minutes
- **[Installation](guides/installation.md)** - Detailed setup
- **[API Reference](reference/api.md)** - Complete API docs

## Documentation Structure

### 📘 [Guides](guides/) - How-to guides
- [Quick Start](guides/quick-start.md)
- [Installation](guides/installation.md)
- [Configuration](guides/configuration.md)

### 📖 [Reference](reference/) - API & feature reference
- [API Reference](reference/api.md)
- [CLI Reference](reference/cli.md)
- [Configuration Options](reference/config.md)

### 🏗️ [Architecture](architecture/) - Design decisions
- [System Overview](architecture/overview.md)
- [Architecture Decisions](architecture/decisions/)

### 🔧 [Development](development/) - For contributors
- [Development Setup](development/setup.md)
- [Testing Guide](development/testing.md)
- [Release Process](development/release.md)

### 📚 [Research](research/) - Historical context
Archived research and planning documents.

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md).

## Need Help?

- 💬 [Open an issue](https://github.com/user/repo/issues)
- 📧 Contact: email@example.com
```

### docs/guides/quick-start.md

```markdown
# Quick Start Guide

Get started with [Project] in 5 minutes.

## Prerequisites

- Requirement 1
- Requirement 2

## Installation

[step-by-step installation]

## First Example

[minimal working example]

## Next Steps

- [Installation Guide](installation.md) - Detailed setup
- [Reference](../reference/) - Complete documentation
```

### docs/guides/README.md

```markdown
# User Guides

How-to guides for using [Project].

## Getting Started

- [Quick Start](quick-start.md) - 5-minute introduction
- [Installation](installation.md) - Detailed installation
- [Configuration](configuration.md) - Configuration guide

## Features

- [Feature 1](feature1.md)
- [Feature 2](feature2.md)

## Need Help?

See the main [Documentation Index](../README.md).
```

### docs/architecture/decisions/README.md

```markdown
# Architecture Decision Records (ADRs)

Architecture Decision Records for [Project].

## Format

Each ADR follows this format:

```markdown
# ADR-XXX: Title

**Status**: Accepted | Proposed | Deprecated

**Date**: YYYY-MM-DD

## Context
[Background and problem]

## Decision
[What we decided]

## Consequences
[Positive and negative outcomes]

## Alternatives Considered
[Other options considered]
```

## Index

- [ADR-001: Title](001-title.md)
```

### docs/research/README.md

```markdown
# Research & Planning Documents

**Archived historical documents** - For current docs, see main [Documentation](../README.md).

## Purpose

These documents explain:
- Why decisions were made
- How features were researched
- Implementation journeys

**Note**: May be outdated - refer to main docs for current state.

## Contents

### [Topic 1](topic1/)
- [Planning Document](topic1/planning.md)
- [Research Summary](topic1/research.md)

## Using Research Documents

Useful for:
- Understanding past decisions
- Learning from implementation
- Onboarding contributors
```

## Migration Script Template

Create this as `scripts/organize-docs.sh` in every repo:

```bash
#!/bin/bash
# organize-docs.sh - Organize documentation following CCPM pattern

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "📊 Organizing documentation..."

# Create structure
mkdir -p docs/{guides,reference,architecture/decisions,development,research}

# Create index files
cat > docs/README.md << 'EOF'
# [Project] Documentation
[Your content here - use template above]
EOF

cat > docs/guides/README.md << 'EOF'
# User Guides
[Your content here - use template above]
EOF

# [Add more index files following templates]

echo "✅ Documentation structure created!"
echo "⚠️  Next: Move existing files to appropriate locations"
```

## Applying to Different Project Types

### Web Applications

```
docs/
├── guides/
│   ├── quick-start.md
│   ├── deployment.md
│   ├── configuration.md
│   └── troubleshooting.md
├── reference/
│   ├── api.md              # REST/GraphQL API
│   ├── components.md        # UI components
│   └── database.md          # Database schema
└── architecture/
    ├── overview.md          # System architecture
    ├── frontend.md          # Frontend architecture
    └── backend.md           # Backend architecture
```

### Libraries/Frameworks

```
docs/
├── guides/
│   ├── quick-start.md
│   ├── installation.md
│   └── migration.md         # Migration guides
├── reference/
│   ├── api.md               # Complete API reference
│   ├── types.md             # TypeScript types
│   └── examples.md          # Code examples
└── development/
    ├── contributing.md
    └── architecture.md
```

### CLI Tools

```
docs/
├── guides/
│   ├── quick-start.md
│   ├── installation.md
│   └── workflows.md         # Common workflows
├── reference/
│   ├── commands.md          # All commands
│   ├── config.md            # Configuration
│   └── plugins.md           # Plugin system
└── development/
    ├── plugin-dev.md        # Creating plugins
    └── testing.md
```

### Claude Code Plugins (CCPM Pattern)

```
docs/
├── guides/
│   ├── quick-start.md
│   ├── installation.md
│   ├── hooks.md             # Hook setup
│   └── [feature].md         # Feature guides
├── reference/
│   ├── commands.md          # Slash commands
│   ├── skills.md            # Skills catalog
│   ├── hooks.md             # Hooks reference
│   ├── agents.md            # Agents reference
│   └── safety-rules.md      # Safety guardrails
├── architecture/
│   ├── overview.md
│   ├── hooks-system.md
│   ├── agent-selection.md
│   └── decisions/           # ADRs
└── research/
    ├── [feature]/           # Feature research
    └── [planning]/          # Planning docs
```

## Repository Template Structure

Create a template repository with this structure:

```bash
# Create template
mkdir -p ~/.claude/templates/repo-structure
cd ~/.claude/templates/repo-structure

# Copy structure
mkdir -p docs/{guides,reference,architecture/decisions,development,research}

# Create template files (use content templates above)
# ... create all template files ...

# Usage: Copy template to new project
cp -r ~/.claude/templates/repo-structure/* /path/to/new/project/
```

## Global Script: Auto-organize Any Repo

Create `~/.claude/scripts/auto-organize-docs.sh`:

```bash
#!/bin/bash
# auto-organize-docs.sh - Automatically organize any repository

REPO_PATH="${1:-.}"
cd "$REPO_PATH" || exit 1

echo "📊 Analyzing $(basename "$PWD")..."

# Count root markdown files
ROOT_MD_COUNT=$(find . -maxdepth 1 -name "*.md" | wc -l)
echo "📄 Found $ROOT_MD_COUNT markdown files in root"

if [ "$ROOT_MD_COUNT" -le 5 ]; then
  echo "✅ Repository is well-organized"
  exit 0
fi

echo ""
echo "⚠️  Too many files in root ($ROOT_MD_COUNT > 5)"
echo ""
echo "🗂️ Suggested organization:"
echo ""

# Analyze and suggest
echo "Keep in root:"
ls -1 README.md CHANGELOG.md CONTRIBUTING.md LICENSE* CLAUDE.md 2>/dev/null

echo ""
echo "Move to docs/guides/:"
ls -1 *GUIDE*.md *INSTALL*.md *SETUP*.md *WORKFLOW*.md 2>/dev/null

echo ""
echo "Move to docs/research/:"
ls -1 *RESEARCH*.md *PLAN*.md *PROPOSAL*.md *STATUS*.md *SUMMARY*.md 2>/dev/null

echo ""
echo "Move to docs/reference/:"
ls -1 *CATALOG*.md *REFERENCE*.md *API*.md 2>/dev/null

echo ""
echo "Move to docs/architecture/:"
ls -1 *ARCHITECTURE*.md *DESIGN*.md 2>/dev/null

echo ""
echo "💡 Apply CCPM pattern? (y/n)"
read -r APPLY

if [ "$APPLY" = "y" ]; then
  # Create structure
  mkdir -p docs/{guides,reference,architecture/decisions,development,research}

  # Move files automatically based on patterns
  [[ -f *GUIDE*.md ]] && mv *GUIDE*.md docs/guides/ 2>/dev/null
  [[ -f *RESEARCH*.md ]] && mv *RESEARCH*.md docs/research/ 2>/dev/null
  # ... more patterns ...

  echo "✅ Documentation organized!"
  echo "⚠️  Review changes and update links"
fi
```

## Installation: Global Pattern

1. **Create template directory**:
```bash
mkdir -p ~/.claude/templates/ccpm-docs-pattern
mkdir -p ~/.claude/scripts
```

2. **Copy templates**:
```bash
# Copy this file and script to template directory
cp GLOBAL_DOCS_PATTERN.md ~/.claude/templates/ccpm-docs-pattern/
cp scripts/organize-docs.sh ~/.claude/templates/ccpm-docs-pattern/
```

3. **Create global script**:
```bash
# Save auto-organize script
cp auto-organize-docs.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/auto-organize-docs.sh

# Add to PATH (in ~/.zshrc or ~/.bashrc)
export PATH="$HOME/.claude/scripts:$PATH"
```

4. **Usage in any repo**:
```bash
# Navigate to any repository
cd ~/projects/my-project

# Auto-analyze and organize
auto-organize-docs.sh

# Or manually copy template
cp -r ~/.claude/templates/ccpm-docs-pattern/docs ./
```

## Best Practices

1. **Always create index README.md files** - They serve as navigation hubs
2. **Keep root clean** - Maximum 5 markdown files
3. **Archive research** - Don't delete, move to docs/research/
4. **Update links** - When moving files, update all internal links
5. **Progressive disclosure** - Guides → Reference → Architecture → Research
6. **AI-friendly** - Clear structure helps AI assistants understand context
7. **Consistent naming** - Use lowercase-with-hyphens for files
8. **Template reuse** - Use the same templates across projects

## Success Metrics

- ✅ Root directory has ≤5 markdown files
- ✅ All docs reachable within 2 clicks from docs/README.md
- ✅ Clear separation: guides/reference/architecture/research
- ✅ Index files guide navigation
- ✅ Historical context preserved in research/
- ✅ Reusable pattern across projects
- ✅ AI assistants can navigate structure

## Examples of Well-Organized Repositories

- **CCPM** - Claude Code plugin with comprehensive docs structure
- **Next.js** - docs/ with guides, API reference, architecture
- **React** - Separate docs site but follows similar pattern
- **Rust** - The Rust Book (guides), API docs (reference), RFCs (research)

## Adapting the Pattern

**For small projects (<10 files):**
```
docs/
├── README.md           # Navigation
├── guide.md            # Combined guide
└── reference.md        # API reference
```

**For medium projects (10-50 files):**
```
docs/
├── guides/
├── reference/
└── README.md
```

**For large projects (50+ files) - Full CCPM pattern:**
```
docs/
├── guides/
├── reference/
├── architecture/
├── development/
└── research/
```

## Conclusion

This pattern provides:
- **Scalability** - Grows with your project
- **Clarity** - Easy to find documentation
- **Reusability** - Apply to any repository
- **Maintainability** - Clear ownership of docs
- **AI-Friendly** - Structured for AI assistants

Apply this pattern to create consistent, navigable documentation across all your repositories.
