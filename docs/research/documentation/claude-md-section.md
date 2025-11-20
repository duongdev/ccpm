# CLAUDE.md Documentation Section

This is the section that will be automatically added to CLAUDE.md by the `/ccpm:utils:organize-docs` command.

---

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

---

## Why This Section Matters

By adding this section to CLAUDE.md, you ensure that:

1. **AI assistants always follow the pattern** - Claude and other AI tools will read CLAUDE.md and understand the documentation structure

2. **New documentation goes in the right place** - When creating docs, AI will automatically place them in the correct directory

3. **Root stays clean** - AI won't create new markdown files in root

4. **Links are correct** - AI understands the structure and creates proper relative links

5. **Pattern is self-documenting** - Anyone reading CLAUDE.md understands the documentation organization

6. **Consistency across projects** - Same pattern applies to any repository

## How It's Applied

The `/ccpm:utils:organize-docs` command will:

1. **Detect CLAUDE.md** - Check if the file exists
2. **Check for existing section** - Look for "## Documentation Structure" or "## Documentation Pattern"
3. **Add or update** - Append the section if missing, or update if exists
4. **Preserve other content** - Only modifies the documentation section

This ensures that every time documentation is reorganized, CLAUDE.md stays in sync with the actual structure.
