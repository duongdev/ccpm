# Documentation Structure Proposal

## Problem Analysis

The CCPM repository currently has **22 markdown files in the root directory**, making it:
- Hard to navigate and find relevant documentation
- Unclear what's user-facing vs internal planning
- Difficult to distinguish between current status and historical research
- Challenging to maintain as the project grows

## Proposed Structure

```
ccpm/
├── README.md                    # Main entry point (keep)
├── CHANGELOG.md                 # Version history (keep)
├── CONTRIBUTING.md              # Contribution guide (keep)
├── MIGRATION.md                 # Migration guide (keep)
├── CLAUDE.md                    # AI assistant instructions (keep)
│
├── docs/                        # All documentation
│   ├── guides/                  # User-facing guides
│   │   ├── installation.md      # How to install CCPM
│   │   ├── hooks.md             # Hook installation & usage (INSTALL_HOOKS.md)
│   │   ├── mcp-integration.md   # MCP setup (MCP_INTEGRATION_GUIDE.md)
│   │   ├── ui-workflow.md       # UI design workflow (UI_DESIGN_WORKFLOW.md)
│   │   └── quick-start.md       # Quick start guide (new)
│   │
│   ├── reference/               # Reference documentation
│   │   ├── commands.md          # All commands reference
│   │   ├── skills.md            # Skills catalog (SKILLS_CATALOG.md)
│   │   ├── hooks.md             # Hooks reference
│   │   ├── agents.md            # Agents reference
│   │   └── safety-rules.md      # Safety rules reference
│   │
│   ├── architecture/            # Architecture & design decisions
│   │   ├── overview.md          # High-level architecture
│   │   ├── hooks-system.md      # Hooks architecture
│   │   ├── skills-system.md     # Skills architecture (SKILLS_ARCHITECTURE.md)
│   │   ├── agent-selection.md   # Smart agent selection
│   │   └── decisions/           # Architecture Decision Records (ADRs)
│   │       ├── 001-hooks-implementation.md
│   │       ├── 002-skills-integration.md
│   │       └── 003-agent-scoring.md
│   │
│   ├── development/             # For contributors/developers
│   │   ├── setup.md             # Development environment setup
│   │   ├── testing.md           # Testing guide
│   │   ├── release-process.md   # How to release
│   │   └── roadmap.md           # Future plans
│   │
│   └── research/                # Historical research & planning (archived)
│       ├── README.md            # Index of research documents
│       ├── skills/
│       │   ├── integration-plan.md      # CLAUDEKIT_SKILLS_INTEGRATION_PLAN.md
│       │   ├── comparison-matrix.md     # SKILLS_COMPARISON_MATRIX.md
│       │   ├── integration-proposal.md  # SKILLS_INTEGRATION_PROPOSAL.md
│       │   ├── integration-summary.md   # SKILLS_INTEGRATION_SUMMARY.md
│       │   ├── research-summary.md      # SKILLS_RESEARCH_SUMMARY.md
│       │   ├── quick-reference.md       # SKILLS_QUICK_REFERENCE.md
│       │   └── implementation-status.md # SKILLS_IMPLEMENTATION_STATUS.md
│       │
│       ├── hooks/
│       │   ├── implementation-summary.md # HOOKS_IMPLEMENTATION_SUMMARY.md
│       │   ├── research-summary.md       # HOOKS_RESEARCH_SUMMARY.md
│       │   └── limitations.md            # HOOKS_LIMITATION.md
│       │
│       └── planning/
│           ├── agent-enhancement.md      # PLANNING_AGENT_ENHANCEMENT.md
│           └── verification-report.md    # VERIFICATION_REPORT.md
│
├── .claude-plugin/              # Plugin configuration
├── commands/                    # Slash commands
├── hooks/                       # Hook implementations
├── agents/                      # Custom agents
├── skills/                      # Skills
└── scripts/                     # Automation scripts
```

## Rationale

### Keep in Root (5 files)
1. **README.md** - Entry point, must be in root
2. **CHANGELOG.md** - Standard location for version history
3. **CONTRIBUTING.md** - Standard location for contribution guide
4. **MIGRATION.md** - Important for users upgrading
5. **CLAUDE.md** - AI assistant instructions (Claude Code convention)

### docs/guides/ - User-facing documentation
- Installation and setup guides
- How-to guides for specific features
- Workflow documentation
- Target audience: End users and plugin users

### docs/reference/ - API/Feature reference
- Comprehensive reference for all features
- Skills catalog, commands list, hooks reference
- Target audience: Users looking up specific features

### docs/architecture/ - Design documentation
- High-level architecture overview
- System design decisions
- Architecture Decision Records (ADRs)
- Target audience: Contributors, maintainers, architects

### docs/development/ - Contributor documentation
- Development environment setup
- Testing strategies
- Release process
- Roadmap and future plans
- Target audience: Contributors and maintainers

### docs/research/ - Historical context (archived)
- Research documents that led to current implementation
- Planning documents for completed features
- Status reports from implementation phases
- **These are historical and can be archived**
- Target audience: Anyone wanting to understand "why" decisions were made

## Migration Plan

### Phase 1: Create Structure
```bash
mkdir -p docs/{guides,reference,architecture/decisions,development,research/{skills,hooks,planning}}
```

### Phase 2: Move Files
```bash
# Guides
mv INSTALL_HOOKS.md docs/guides/hooks.md
mv MCP_INTEGRATION_GUIDE.md docs/guides/mcp-integration.md
mv UI_DESIGN_WORKFLOW.md docs/guides/ui-workflow.md

# Reference
mv SKILLS_CATALOG.md docs/reference/skills.md

# Architecture
mv SKILLS_ARCHITECTURE.md docs/architecture/skills-system.md

# Research - Skills
mv CLAUDEKIT_SKILLS_INTEGRATION_PLAN.md docs/research/skills/integration-plan.md
mv SKILLS_COMPARISON_MATRIX.md docs/research/skills/comparison-matrix.md
mv SKILLS_INTEGRATION_PROPOSAL.md docs/research/skills/integration-proposal.md
mv SKILLS_INTEGRATION_SUMMARY.md docs/research/skills/integration-summary.md
mv SKILLS_RESEARCH_SUMMARY.md docs/research/skills/research-summary.md
mv SKILLS_QUICK_REFERENCE.md docs/research/skills/quick-reference.md
mv SKILLS_IMPLEMENTATION_STATUS.md docs/research/skills/implementation-status.md

# Research - Hooks
mv HOOKS_IMPLEMENTATION_SUMMARY.md docs/research/hooks/implementation-summary.md
mv HOOKS_RESEARCH_SUMMARY.md docs/research/hooks/research-summary.md
mv HOOKS_LIMITATION.md docs/research/hooks/limitations.md

# Research - Planning
mv PLANNING_AGENT_ENHANCEMENT.md docs/research/planning/agent-enhancement.md
mv VERIFICATION_REPORT.md docs/research/planning/verification-report.md
```

### Phase 3: Create Index Files
Create README.md files in each docs/ subdirectory to guide navigation.

### Phase 4: Update Links
- Update all internal links in moved files
- Update README.md to point to new locations
- Update CLAUDE.md references

### Phase 5: Create Missing Documentation
- docs/guides/quick-start.md
- docs/guides/installation.md
- docs/reference/commands.md
- docs/reference/hooks.md
- docs/reference/agents.md
- docs/architecture/overview.md
- docs/architecture/hooks-system.md
- docs/architecture/agent-selection.md
- docs/development/setup.md
- docs/development/testing.md
- docs/development/release-process.md
- docs/development/roadmap.md
- docs/research/README.md

## Review: Files to Remove or Rewrite

### Potential Removals (Duplicates or Outdated)
1. **SKILLS_INTEGRATION_PROPOSAL.md** - Might be superseded by INTEGRATION_PLAN.md
2. **SKILLS_QUICK_REFERENCE.md** - Might be superseded by SKILLS_CATALOG.md
3. **VERIFICATION_REPORT.md** - Historical, can archive

### Files to Consolidate
1. **Skills research docs (7 files)** - Consider creating single "Skills Integration Journey" document
2. **Hooks research docs (3 files)** - Consider consolidating into "Hooks Implementation Journey"

### Files to Rewrite/Improve
1. **README.md** - Update with new doc structure, add clear navigation
2. **CLAUDE.md** - Update file references to new locations
3. Create **docs/guides/quick-start.md** - Many guides exist but no quick start

## Global Application Strategy

### For This Repo (CCPM)
1. Implement proposed structure
2. Create automation script: `scripts/organize-docs.sh`
3. Add to CONTRIBUTING.md as documentation standard
4. Use as template for future docs

### For Other Repos on Machine
Create a reusable documentation template:

```bash
# Create global template
~/.claude/templates/docs-structure/
├── README-template.md
├── CONTRIBUTING-template.md
├── CHANGELOG-template.md
├── docs/
│   ├── guides/
│   │   └── README.md
│   ├── reference/
│   │   └── README.md
│   ├── architecture/
│   │   ├── README.md
│   │   └── decisions/
│   │       └── README.md
│   ├── development/
│   │   └── README.md
│   └── research/
│       └── README.md
└── scripts/
    └── organize-docs.sh
```

### Create Global Organization Script

```bash
#!/bin/bash
# ~/.claude/scripts/organize-docs.sh
# Analyzes a repo and suggests documentation organization

REPO_ROOT="$1"
if [ -z "$REPO_ROOT" ]; then
  echo "Usage: organize-docs.sh <repo-path>"
  exit 1
fi

cd "$REPO_ROOT" || exit 1

echo "📊 Analyzing documentation in $(basename "$PWD")..."
echo ""

# Find all markdown files in root
ROOT_DOCS=$(find . -maxdepth 1 -name "*.md" | wc -l)
echo "📄 Found $ROOT_DOCS markdown files in root"

# Categorize files
echo ""
echo "🗂️ Suggested categorization:"
echo ""

echo "Keep in root:"
find . -maxdepth 1 -name "README.md" -o -name "CHANGELOG.md" -o -name "CONTRIBUTING.md" -o -name "LICENSE.md" -o -name "CLAUDE.md"

echo ""
echo "Move to docs/guides/:"
find . -maxdepth 1 -name "*GUIDE*.md" -o -name "*INSTALL*.md" -o -name "*SETUP*.md" -o -name "*WORKFLOW*.md"

echo ""
echo "Move to docs/research/:"
find . -maxdepth 1 -name "*RESEARCH*.md" -o -name "*PLAN*.md" -o -name "*PROPOSAL*.md" -o -name "*STATUS*.md"

echo ""
echo "Move to docs/reference/:"
find . -maxdepth 1 -name "*CATALOG*.md" -o -name "*REFERENCE*.md" -o -name "*API*.md"

echo ""
echo "Move to docs/architecture/:"
find . -maxdepth 1 -name "*ARCHITECTURE*.md" -o -name "*DESIGN*.md" -o -name "*SUMMARY*.md"

echo ""
echo "💡 Run 'scripts/apply-doc-structure.sh' to automatically organize"
```

## Benefits of This Structure

1. **Clear Navigation** - Easy to find user guides vs reference vs research
2. **Scalable** - Can grow without cluttering root
3. **Standard** - Follows common documentation patterns
4. **Historical Context** - Research docs preserved but archived
5. **Contributor Friendly** - Clear where to add new documentation
6. **AI Assistant Friendly** - Clear structure for Claude to understand
7. **Discovery** - Index files guide users through documentation

## Implementation Checklist

- [ ] Create docs/ directory structure
- [ ] Move existing files to appropriate locations
- [ ] Create index README.md files
- [ ] Update internal links
- [ ] Update README.md with new structure
- [ ] Update CLAUDE.md with new file locations
- [ ] Create missing documentation (quick-start, etc.)
- [ ] Create scripts/organize-docs.sh automation
- [ ] Create global template in ~/.claude/templates/
- [ ] Test all documentation links
- [ ] Update CONTRIBUTING.md with doc standards
- [ ] Archive truly obsolete files (or delete if no value)

## Success Metrics

- Root directory has ≤5 markdown files
- All documentation findable within 2 clicks
- Clear distinction between user docs and research docs
- Reusable pattern for other repositories
- Faster onboarding for new contributors

---

**Recommendation**: Implement this structure in phases:
1. Phase 1-3: Move and organize existing files (1-2 hours)
2. Phase 4: Fix links (30 minutes)
3. Phase 5: Create missing docs (ongoing, as needed)

This creates immediate improvement while allowing gradual enhancement.
