# CCPM Documentation

Welcome to the CCPM (Claude Code Project Management) documentation hub. This is your central navigation point for all CCPM documentation.

## 🚀 Quick Start

**New to CCPM?**
1. [Installation Guide](guides/getting-started/installation.md) - Set up CCPM and dependencies
2. [Project Setup](guides/getting-started/project-setup.md) - Configure your first project
3. [Quick Start Tutorial](../README.md#-quick-start) - Learn the 6 essential commands

**Want to explore features?**
- [Natural Workflow Commands](../README.md#1-natural-workflow-commands-new) - Master the 6-command workflow
- [Project Management](guides/getting-started/project-setup.md) - Multi-project configuration
- [Hooks & Automation](guides/features/hooks-setup.md) - Smart agent selection
- [MCP Integration](guides/features/mcp-integration.md) - Connect Linear, GitHub, Context7

## 📚 Documentation Structure

### 📘 [Guides](guides/) - How-to Documentation

User-facing guides for getting started and using CCPM effectively.

**Getting Started:**
- [Installation](guides/getting-started/installation.md) - Install CCPM and dependencies
- [Project Setup](guides/getting-started/project-setup.md) - Configure your projects

**Features:**
- [Hooks Setup](guides/features/hooks-setup.md) - Enable smart automation
- [MCP Integration](guides/features/mcp-integration.md) - Connect external services
- [Figma Integration](guides/features/figma-integration.md) - Design-to-code workflow
- [Image Analysis](guides/features/image-analysis.md) - Visual context for tasks

**Workflows:**
- [Monorepo Workflow](guides/workflows/monorepo-workflow.md) - Multi-project repositories
- [UI Design Workflow](guides/workflows/ui-design-workflow.md) - Design system integration

**Troubleshooting:**
- [Linear Integration](guides/troubleshooting/linear-integration.md) - Fix Linear connection issues

**Migration:**
- [Linear Subagent Migration](guides/migration/linear-subagent-migration.md) - Migrate to v2.3+
- [PSN-30 Migration](guides/migration/psn-30-migration.md) - Natural commands migration

### 📖 [Reference](reference/) - Technical Reference

Complete reference documentation for lookup and detailed information.

**Commands:**
- [Complete Command List](../commands/README.md) - All 49+ commands
- [Safety Rules](../commands/SAFETY_RULES.md) - External system safety guidelines
- [Spec Management](../commands/SPEC_MANAGEMENT_SUMMARY.md) - Spec-first development guide

**Skills:**
- [Skills Catalog](reference/skills/catalog.md) - All 10 installable skills
- [Quick Reference](reference/skills/quick-reference.md) - Skill activation triggers

**Agents:**
- [Usage Patterns](reference/agents/usage-patterns.md) - Best practices for agent usage
- [Agent Catalog](../agents/README.md) - Available subagents

**API:**
- [Linear Subagent API](reference/api/linear-subagent-quick-reference.md) - Linear operations reference

**Configuration:**
- [Project Configuration](reference/configuration/project-config.md) - ccpm-config.yaml reference

### 🏗️ [Architecture](architecture/) - Design Decisions

Architecture Decision Records (ADRs), system diagrams, and design patterns.

**Architecture Decision Records:**
- [ADR-001: Skills System](architecture/decisions/001-skills-system.md)
- [ADR-002: Linear Subagent](architecture/decisions/002-linear-subagent.md)
- [ADR-003: Natural Commands](architecture/decisions/003-natural-commands.md)
- [ADR-005: Documentation Structure](architecture/decisions/005-documentation-structure.md)

**System Diagrams:**
- [PSN-30 Architecture](architecture/diagrams/psn-30-architecture-diagrams.md)

**Design Patterns:**
- [Dynamic Configuration](architecture/patterns/dynamic-configuration.md) - Multi-project setup
- [Workflow State Tracking](architecture/patterns/workflow-state-tracking.md)

### 🔧 [Development](development/) - Contributor Documentation

Documentation for CCPM contributors and developers.

**Setup:**
- [Testing Setup](development/setup/testing-setup.md) - Test infrastructure setup

**Reference:**
- [Testing Infrastructure](development/reference/testing-infrastructure.md) - Test framework details
- [Linear Error Handling](development/reference/linear-error-handling.md) - Error patterns
- [Test Framework Architecture](development/reference/test-framework-architecture.md)

**Optimization:**
- [Hook Performance](development/optimization/hook-performance-optimization.md) - Optimize hooks
- [Performance Metrics](development/optimization/performance-metrics.md) - Benchmarks
- [Optimization Files Index](development/optimization/optimization-files-index.md)

### 📚 [Research](research/) - Historical Context

**⚠️ Note:** Research directory contains **archived** documentation showing how decisions were made. For current documentation, refer to main sections above.

**Completed Features:**
- [PSN-29](research/completed/psn-29/) - Linear subagent integration
- [PSN-30](research/completed/psn-30/) - Natural command optimization
- [PSN-31](research/completed/psn-31/) - Documentation reorganization (this project)

**Historical Research:**
- [Skills Research](research/skills/) - Skills system development
- [Hooks Research](research/hooks/) - Hook system design
- [Documentation Research](research/documentation/) - Documentation patterns

## 🎯 Common Tasks

### I want to...

**Get Started:**
- [Install CCPM](guides/getting-started/installation.md)
- [Set up my first project](guides/getting-started/project-setup.md)
- [Learn the workflow](../README.md#-quick-start)

**Use Features:**
- [Run the natural workflow](../README.md#1-natural-workflow-commands-new)
- [Enable automation](guides/features/hooks-setup.md)
- [Work with multiple projects](guides/getting-started/project-setup.md)
- [Integrate with Figma](guides/features/figma-integration.md)

**Troubleshoot:**
- [Fix Linear integration](guides/troubleshooting/linear-integration.md)
- [Debug MCP servers](guides/features/mcp-integration.md)

**Contribute:**
- [Set up dev environment](development/setup/testing-setup.md)
- [Read architecture decisions](architecture/decisions/)

**Understand Design:**
- [Browse ADRs](architecture/decisions/)
- [View system diagrams](architecture/diagrams/)
- [Learn design patterns](architecture/patterns/)

## 📞 Need Help?

- **Main README**: [Project overview](../README.md)
- **CLAUDE.md**: [AI assistant instructions](../CLAUDE.md)
- **Contributing**: [Contribution guidelines](../CONTRIBUTING.md)
- **Command Help**: `/ccpm:utils:help`
- **Cheatsheet**: `/ccpm:utils:cheatsheet`

## 📋 Documentation Guidelines

When creating or updating documentation:

1. **Categorize properly**: Place docs in the correct directory
2. **Use templates**: Follow templates in [docs/templates/](templates/)
3. **Update indexes**: Add entries to relevant README files
4. **Validate links**: Run `./scripts/documentation/validate-links.sh`
5. **Follow patterns**: Maintain consistency with existing docs

See [Documentation Structure ADR](architecture/decisions/005-documentation-structure.md) for detailed guidelines.

---

**Last updated:** 2025-11-21
**Documentation version:** 2.3 (PSN-31 reorganization)
**Total documents:** 120+ files across all categories
