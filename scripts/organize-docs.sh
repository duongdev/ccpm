#!/bin/bash
# organize-docs.sh
# Reorganizes CCPM documentation according to proposed structure

set -e  # Exit on error

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "📊 Organizing CCPM Documentation..."
echo "Repository: $REPO_ROOT"
echo ""

# Phase 1: Create directory structure
echo "📁 Phase 1: Creating directory structure..."
mkdir -p docs/{guides,reference,architecture/decisions,development,research/{skills,hooks,planning}}
echo "✅ Directory structure created"
echo ""

# Phase 2: Move files
echo "📦 Phase 2: Moving files to new locations..."

# Guides
if [ -f "INSTALL_HOOKS.md" ]; then
  mv INSTALL_HOOKS.md docs/guides/hooks.md
  echo "  ✓ INSTALL_HOOKS.md → docs/guides/hooks.md"
fi

if [ -f "MCP_INTEGRATION_GUIDE.md" ]; then
  mv MCP_INTEGRATION_GUIDE.md docs/guides/mcp-integration.md
  echo "  ✓ MCP_INTEGRATION_GUIDE.md → docs/guides/mcp-integration.md"
fi

if [ -f "UI_DESIGN_WORKFLOW.md" ]; then
  mv UI_DESIGN_WORKFLOW.md docs/guides/ui-workflow.md
  echo "  ✓ UI_DESIGN_WORKFLOW.md → docs/guides/ui-workflow.md"
fi

# Reference
if [ -f "SKILLS_CATALOG.md" ]; then
  mv SKILLS_CATALOG.md docs/reference/skills.md
  echo "  ✓ SKILLS_CATALOG.md → docs/reference/skills.md"
fi

# Architecture
if [ -f "SKILLS_ARCHITECTURE.md" ]; then
  mv SKILLS_ARCHITECTURE.md docs/architecture/skills-system.md
  echo "  ✓ SKILLS_ARCHITECTURE.md → docs/architecture/skills-system.md"
fi

# Research - Skills
if [ -f "CLAUDEKIT_SKILLS_INTEGRATION_PLAN.md" ]; then
  mv CLAUDEKIT_SKILLS_INTEGRATION_PLAN.md docs/research/skills/integration-plan.md
  echo "  ✓ CLAUDEKIT_SKILLS_INTEGRATION_PLAN.md → docs/research/skills/integration-plan.md"
fi

if [ -f "SKILLS_COMPARISON_MATRIX.md" ]; then
  mv SKILLS_COMPARISON_MATRIX.md docs/research/skills/comparison-matrix.md
  echo "  ✓ SKILLS_COMPARISON_MATRIX.md → docs/research/skills/comparison-matrix.md"
fi

if [ -f "SKILLS_INTEGRATION_PROPOSAL.md" ]; then
  mv SKILLS_INTEGRATION_PROPOSAL.md docs/research/skills/integration-proposal.md
  echo "  ✓ SKILLS_INTEGRATION_PROPOSAL.md → docs/research/skills/integration-proposal.md"
fi

if [ -f "SKILLS_INTEGRATION_SUMMARY.md" ]; then
  mv SKILLS_INTEGRATION_SUMMARY.md docs/research/skills/integration-summary.md
  echo "  ✓ SKILLS_INTEGRATION_SUMMARY.md → docs/research/skills/integration-summary.md"
fi

if [ -f "SKILLS_RESEARCH_SUMMARY.md" ]; then
  mv SKILLS_RESEARCH_SUMMARY.md docs/research/skills/research-summary.md
  echo "  ✓ SKILLS_RESEARCH_SUMMARY.md → docs/research/skills/research-summary.md"
fi

if [ -f "SKILLS_QUICK_REFERENCE.md" ]; then
  mv SKILLS_QUICK_REFERENCE.md docs/research/skills/quick-reference.md
  echo "  ✓ SKILLS_QUICK_REFERENCE.md → docs/research/skills/quick-reference.md"
fi

if [ -f "SKILLS_IMPLEMENTATION_STATUS.md" ]; then
  mv SKILLS_IMPLEMENTATION_STATUS.md docs/research/skills/implementation-status.md
  echo "  ✓ SKILLS_IMPLEMENTATION_STATUS.md → docs/research/skills/implementation-status.md"
fi

# Research - Hooks
if [ -f "HOOKS_IMPLEMENTATION_SUMMARY.md" ]; then
  mv HOOKS_IMPLEMENTATION_SUMMARY.md docs/research/hooks/implementation-summary.md
  echo "  ✓ HOOKS_IMPLEMENTATION_SUMMARY.md → docs/research/hooks/implementation-summary.md"
fi

if [ -f "HOOKS_RESEARCH_SUMMARY.md" ]; then
  mv HOOKS_RESEARCH_SUMMARY.md docs/research/hooks/research-summary.md
  echo "  ✓ HOOKS_RESEARCH_SUMMARY.md → docs/research/hooks/research-summary.md"
fi

if [ -f "HOOKS_LIMITATION.md" ]; then
  mv HOOKS_LIMITATION.md docs/research/hooks/limitations.md
  echo "  ✓ HOOKS_LIMITATION.md → docs/research/hooks/limitations.md"
fi

# Research - Planning
if [ -f "PLANNING_AGENT_ENHANCEMENT.md" ]; then
  mv PLANNING_AGENT_ENHANCEMENT.md docs/research/planning/agent-enhancement.md
  echo "  ✓ PLANNING_AGENT_ENHANCEMENT.md → docs/research/planning/agent-enhancement.md"
fi

if [ -f "VERIFICATION_REPORT.md" ]; then
  mv VERIFICATION_REPORT.md docs/research/planning/verification-report.md
  echo "  ✓ VERIFICATION_REPORT.md → docs/research/planning/verification-report.md"
fi

echo "✅ Files moved successfully"
echo ""

# Phase 3: Create index files
echo "📄 Phase 3: Creating index files..."

# docs/README.md
cat > docs/README.md << 'EOF'
# CCPM Documentation

Welcome to the CCPM (Claude Code Project Management) documentation.

## Quick Links

- **[Quick Start Guide](guides/quick-start.md)** - Get started with CCPM in 5 minutes
- **[Installation Guide](guides/installation.md)** - Detailed installation instructions
- **[Commands Reference](reference/commands.md)** - All available commands
- **[Skills Catalog](reference/skills.md)** - All CCPM skills

## Documentation Structure

### 📘 [Guides](guides/) - User-facing documentation
How to install, configure, and use CCPM features:
- [Hooks Setup](guides/hooks.md) - Hook installation and configuration
- [MCP Integration](guides/mcp-integration.md) - MCP server setup
- [UI Workflow](guides/ui-workflow.md) - UI design workflow

### 📖 [Reference](reference/) - API and feature reference
Comprehensive reference for all CCPM features:
- [Commands](reference/commands.md) - All 37 commands
- [Skills](reference/skills.md) - All 8 skills
- [Hooks](reference/hooks.md) - All hooks
- [Agents](reference/agents.md) - All agents
- [Safety Rules](reference/safety-rules.md) - External system safety

### 🏗️ [Architecture](architecture/) - Design decisions
High-level architecture and design documentation:
- [Overview](architecture/overview.md) - System architecture
- [Hooks System](architecture/hooks-system.md) - How hooks work
- [Skills System](architecture/skills-system.md) - How skills work
- [Agent Selection](architecture/agent-selection.md) - Smart agent scoring
- [Decisions](architecture/decisions/) - Architecture Decision Records (ADRs)

### 🔧 [Development](development/) - Contributor documentation
For contributors and maintainers:
- [Setup](development/setup.md) - Development environment
- [Testing](development/testing.md) - Testing guide
- [Release Process](development/release-process.md) - How to release
- [Roadmap](development/roadmap.md) - Future plans

### 📚 [Research](research/) - Historical context
Research and planning documents (archived):
- [Skills Integration Journey](research/skills/) - How skills were integrated
- [Hooks Implementation Journey](research/hooks/) - How hooks were implemented
- [Planning Enhancements](research/planning/) - Agent and planning improvements

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for documentation standards and contribution guidelines.

## Need Help?

- 💬 Open an issue on [GitHub](https://github.com/duongdev/ccpm/issues)
- 📧 Contact maintainers
- 📖 Read the [FAQ](guides/faq.md)
EOF
echo "  ✓ docs/README.md created"

# docs/guides/README.md
cat > docs/guides/README.md << 'EOF'
# CCPM User Guides

User-facing guides for installing, configuring, and using CCPM.

## Getting Started

- **[Quick Start](quick-start.md)** - Get started with CCPM in 5 minutes
- **[Installation](installation.md)** - Detailed installation instructions

## Configuration

- **[Hooks Setup](hooks.md)** - Install and configure hooks
- **[MCP Integration](mcp-integration.md)** - Set up MCP servers

## Workflows

- **[UI Design Workflow](ui-workflow.md)** - Design UI with CCPM

## Need Help?

See the main [Documentation Index](../README.md) or open an issue on GitHub.
EOF
echo "  ✓ docs/guides/README.md created"

# docs/reference/README.md
cat > docs/reference/README.md << 'EOF'
# CCPM Reference Documentation

Comprehensive reference for all CCPM features.

## Available References

- **[Commands](commands.md)** - All 37 CCPM commands
- **[Skills](skills.md)** - All 8 CCPM skills
- **[Hooks](hooks.md)** - All CCPM hooks
- **[Agents](agents.md)** - All CCPM agents
- **[Safety Rules](safety-rules.md)** - External system safety rules

## Quick Navigation

### By Category
- **Spec Management**: 6 commands
- **Planning**: 4 commands
- **Implementation**: 3 commands
- **Verification**: 3 commands
- **Completion**: 1 command
- **Utilities**: 20+ commands

### By Feature
- Linear integration
- Jira/Confluence/BitBucket integration
- Slack notifications
- Smart agent selection
- TDD enforcement
- Quality gates

See the main [Documentation Index](../README.md) for more resources.
EOF
echo "  ✓ docs/reference/README.md created"

# docs/architecture/README.md
cat > docs/architecture/README.md << 'EOF'
# CCPM Architecture Documentation

High-level architecture and design documentation for CCPM.

## Architecture Overview

- **[System Overview](overview.md)** - High-level system architecture
- **[Hooks System](hooks-system.md)** - How hooks work in CCPM
- **[Skills System](skills-system.md)** - How skills work in CCPM
- **[Agent Selection](agent-selection.md)** - Smart agent scoring algorithm

## Architecture Decision Records (ADRs)

See [decisions/](decisions/) for all architecture decisions:

- [ADR-001: Hooks Implementation](decisions/001-hooks-implementation.md)
- [ADR-002: Skills Integration](decisions/002-skills-integration.md)
- [ADR-003: Agent Scoring](decisions/003-agent-scoring.md)

## Design Principles

1. **Safety First** - Always require confirmation for external writes
2. **Progressive Disclosure** - Load information as needed
3. **Context-Aware** - Smart suggestions based on workflow state
4. **Automation** - Reduce manual steps through hooks and agents
5. **Extensible** - Plugin architecture for customization

See the main [Documentation Index](../README.md) for more resources.
EOF
echo "  ✓ docs/architecture/README.md created"

# docs/architecture/decisions/README.md
cat > docs/architecture/decisions/README.md << 'EOF'
# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records (ADRs) documenting significant architectural decisions made in CCPM.

## What is an ADR?

An Architecture Decision Record (ADR) is a document that captures an important architectural decision made along with its context and consequences.

## Format

Each ADR follows this format:

```markdown
# ADR-XXX: Title

**Status**: Accepted | Proposed | Deprecated | Superseded

**Date**: YYYY-MM-DD

## Context

What is the issue we're facing?

## Decision

What did we decide?

## Consequences

What are the positive and negative consequences?

## Alternatives Considered

What other options were considered?
```

## Index

- [ADR-001: Hooks Implementation](001-hooks-implementation.md) - Decision to implement custom hooks system
- [ADR-002: Skills Integration](002-skills-integration.md) - Decision to adopt ClaudeKit skills
- [ADR-003: Agent Scoring](003-agent-scoring.md) - Decision on agent scoring algorithm

## Creating a New ADR

1. Create a new file: `XXX-title.md` (use next available number)
2. Follow the template format above
3. Update this README.md index
4. Reference the ADR in relevant documentation
EOF
echo "  ✓ docs/architecture/decisions/README.md created"

# docs/development/README.md
cat > docs/development/README.md << 'EOF'
# CCPM Development Documentation

Documentation for contributors and maintainers.

## Getting Started

- **[Development Setup](setup.md)** - Set up development environment
- **[Testing Guide](testing.md)** - How to test CCPM

## Contributing

- **[Release Process](release-process.md)** - How to release new versions
- **[Roadmap](roadmap.md)** - Future plans and features

## Development Standards

- Follow documentation structure in `docs/`
- Write tests for new features
- Update CHANGELOG.md
- Follow safety rules for external writes

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for full contribution guidelines.
EOF
echo "  ✓ docs/development/README.md created"

# docs/research/README.md
cat > docs/research/README.md << 'EOF'
# CCPM Research & Planning Documents

This directory contains historical research and planning documents that led to current CCPM implementation.

## Purpose

These documents are **archived for historical context**. They explain:
- Why certain decisions were made
- How features were researched and planned
- Implementation journeys and learnings

**Note**: These documents may be outdated. Refer to main documentation for current state.

## Contents

### [Skills Integration Journey](skills/)
Research and planning documents for integrating ClaudeKit skills:
- [Integration Plan](skills/integration-plan.md) - Comprehensive integration strategy
- [Comparison Matrix](skills/comparison-matrix.md) - Analysis of all 27 skills
- [Research Summary](skills/research-summary.md) - Research findings
- [Implementation Status](skills/implementation-status.md) - Implementation progress

### [Hooks Implementation Journey](hooks/)
Research and implementation of custom hooks system:
- [Implementation Summary](hooks/implementation-summary.md) - How hooks were implemented
- [Research Summary](hooks/research-summary.md) - Research on hooks system
- [Limitations](hooks/limitations.md) - Known limitations

### [Planning Enhancements](planning/)
Agent and planning system improvements:
- [Agent Enhancement](planning/agent-enhancement.md) - Planning agent improvements
- [Verification Report](planning/verification-report.md) - Quality verification

## Using Research Documents

These documents are useful for:
- Understanding why decisions were made
- Learning from implementation journeys
- Avoiding repeating past mistakes
- Onboarding new contributors

For current documentation, see the main [Documentation Index](../README.md).
EOF
echo "  ✓ docs/research/README.md created"

echo "✅ Index files created"
echo ""

# Phase 4: Create placeholder files for missing documentation
echo "📝 Phase 4: Creating placeholder documentation..."

# Quick start guide
cat > docs/guides/quick-start.md << 'EOF'
# CCPM Quick Start Guide

Get started with CCPM in 5 minutes.

## Prerequisites

- Claude Code installed
- Node.js 18+ installed
- Linear account (for task tracking)

## Installation

1. Install CCPM plugin:
```bash
# Install via Claude Code CLI
claude plugin install ccpm
```

2. Configure MCP servers in `~/.claude/mcp.json`:
```json
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-linear"],
      "env": {
        "LINEAR_API_KEY": "${LINEAR_API_KEY}"
      }
    }
  }
}
```

3. Set environment variables:
```bash
export LINEAR_API_KEY="your_linear_api_key"
```

## First Task

Create your first task with CCPM:

```bash
# Start a conversation with Claude Code
claude

# Create a new task
/pm:planning:create "Add user authentication" my-project
```

CCPM will:
1. Create a Linear issue
2. Generate a comprehensive plan
3. Suggest next actions

## Next Steps

- Read the [Installation Guide](installation.md) for detailed setup
- Explore [Commands Reference](../reference/commands.md) for all commands
- Check out [Skills Catalog](../reference/skills.md) for available skills

## Need Help?

- Check the [FAQ](faq.md)
- Open an issue on [GitHub](https://github.com/duongdev/ccpm/issues)
EOF
echo "  ✓ docs/guides/quick-start.md created"

echo "✅ Placeholder documentation created"
echo ""

# Summary
echo "🎉 Documentation organization complete!"
echo ""
echo "📊 Summary:"
echo "  ✓ Created docs/ directory structure"
echo "  ✓ Moved 16 files from root to organized locations"
echo "  ✓ Created 6 index README.md files"
echo "  ✓ Created quick-start guide"
echo ""
echo "📁 Root directory now contains only:"
ls -1 *.md 2>/dev/null | wc -l | xargs echo "   " "markdown files"
echo ""
echo "📚 New documentation structure:"
echo "   docs/"
echo "   ├── guides/          (4 files)"
echo "   ├── reference/       (1 file)"
echo "   ├── architecture/    (1 file)"
echo "   ├── development/     (0 files - to be created)"
echo "   └── research/        (14 files - archived)"
echo ""
echo "⚠️  Next steps:"
echo "   1. Review moved files and update internal links"
echo "   2. Update README.md with new documentation structure"
echo "   3. Update CLAUDE.md with new file paths"
echo "   4. Create missing documentation files as needed"
echo "   5. Test all documentation links"
echo ""
echo "💡 Run 'git status' to see all changes"
