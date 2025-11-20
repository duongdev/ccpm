# Changelog

All notable changes to the CCPM plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-01-10

### 🎉 Initial Plugin Release

This is the first release of CCPM as a standalone Claude Code plugin, migrated from the original PM commands implementation.

### Added

#### Spec Management (6 commands)
- `/ccpm:spec:create` - Create Epic/Feature with Linear Document
- `/ccpm:spec:write` - AI-assisted spec writing with codebase analysis
- `/ccpm:spec:review` - Spec validation and grading (A-F)
- `/ccpm:spec:break-down` - Break Epic into Features or Feature into Tasks
- `/ccpm:spec:migrate` - Migrate existing `.claude/` specs to Linear Documents
- `/ccpm:spec:sync` - Sync spec with implementation reality

#### Planning Commands (3 commands)
- `/ccpm:planning:create` - Create Linear issue + full planning in one step
- `/ccpm:planning:plan` - Populate existing issue with comprehensive research
- `/ccpm:planning:quick-plan` - Quick planning for internal projects (no external PM)

#### Implementation Commands (3 commands)
- `/ccpm:implementation:start` - Start implementation with agent coordination
- `/ccpm:implementation:next` - Smart next action detection based on dependencies
- `/ccpm:implementation:update` - Update subtask progress

#### Verification Commands (3 commands)
- `/ccpm:verification:check` - Run quality checks (IDE, lint, tests)
- `/ccpm:verification:verify` - Final verification with verification agent
- `/ccpm:verification:fix` - Fix verification failures with agent coordination

#### Completion Commands (1 command)
- `/ccpm:complete:finalize` - Post-completion workflow (PR + Jira + Slack + cleanup)

#### Utility Commands (10+ commands)
- `/ccpm:utils:status` - Show detailed task status
- `/ccpm:utils:context` - Fast task context loading for quick resume
- `/ccpm:utils:report` - Project-wide progress reporting
- `/ccpm:utils:insights` - AI-powered complexity & risk analysis
- `/ccpm:utils:auto-assign` - AI-powered agent assignment
- `/ccpm:utils:sync-status` - Sync Linear status to Jira
- `/ccpm:utils:rollback` - Undo planning changes
- `/ccpm:utils:dependencies` - Visualize task dependencies
- `/ccpm:utils:agents` - List all available subagents
- `/ccpm:utils:help` - Context-aware help and command suggestions

#### Project-Specific Commands
- `/ccpm:repeat:check-pr` - Comprehensive BitBucket PR analysis for Repeat project

#### Smart Agent Auto-Invocation
- **Dynamic Agent Discovery** - Automatically discovers all agents (global, plugins, project-specific)
- **Context-Aware Scoring** - Intelligent agent selection using 0-100+ scoring algorithm
- **Execution Planning** - Sequential vs parallel agent invocation with dependency handling
- **Project Priority** - Custom project agents score +25 (highest priority)
- **Tech Stack Detection** - Automatic tech stack detection from package.json, requirements.txt, etc.

#### TDD Enforcement
- **PreToolUse Hook** - Blocks Write/Edit/NotebookEdit if tests don't exist
- **Automatic TDD Agent Invocation** - Invokes tdd-orchestrator when tests are missing
- **Red-Green-Refactor Workflow** - Enforces test-first development

#### Quality Gates
- **Stop Hook** - Automatically runs quality checks after implementation
- **Code Review** - Invokes code-reviewer for all code changes
- **Security Audit** - Invokes security-auditor for security-critical changes
- **Architecture Review** - Validates architecture integrity for significant changes

#### Interactive Mode
- **Status After Execution** - Shows current status after every command
- **Progress Calculation** - Displays completion percentage
- **Smart Next Actions** - Suggests intelligent next steps
- **Command Chaining** - Can chain directly to next command without context switching

### Features

- **Linear Integration** - Complete Linear API integration for issues, documents, comments, status updates
- **Jira Integration** - Read-only Jira integration with confirmation for writes
- **Confluence Integration** - Documentation and spec management
- **BitBucket Integration** - PR analysis and review
- **Slack Integration** - Notifications and updates (with confirmation)
- **Context7 MCP** - Latest library documentation for AI-assisted spec writing
- **GitHub MCP** - PR creation and code hosting
- **Safety Rules** - Strict safety enforcement to prevent accidental external modifications

### Documentation

- Complete README with quick start guide
- Command reference documentation
- Spec management guide
- Safety rules documentation
- Hook system documentation
- Troubleshooting guide

### Technical

- Plugin manifest with metadata and keywords
- Marketplace manifest for distribution
- Executable scripts for agent discovery
- Hook configuration with all trigger points
- MIT License

---

## [1.0.0] - 2024-12-01 (Pre-Plugin)

### Added
- Initial PM commands implementation (not as plugin)
- Basic Linear integration
- Planning and implementation commands

---

**Note:** Versions prior to 2.0.0 were implemented as standalone commands in `~/.claude/commands/pm/` before being migrated to a plugin structure.
