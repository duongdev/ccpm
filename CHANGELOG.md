# Changelog

All notable changes to the CCPM plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-12-28

### Added

- **Multi-Perspective Code Review** (`/ccpm:review --multi`)
  - Parallel analysis from 4 expert viewpoints: Code Quality, Security, Architecture, UX/Accessibility
  - Uses `ccpm:code-reviewer`, `ccpm:security-auditor`, `ccpm:backend-architect`, `ccpm:frontend-developer` agents
  - Consolidated findings with perspective tags
  - Catches more issues through diverse expertise

- **Decisions Log Helper** (`helpers/decisions-log.md`)
  - Track architectural and technical decisions with rationale
  - `logDecision()` - Log to file + Linear comments
  - `searchDecisions()` - Search past decisions
  - `checkExistingDecision()` - Prevent re-debating settled decisions

- **Guard Commit Hook** (Stop hook)
  - Prevents work loss when session ends unexpectedly
  - Warns if uncommitted changes exceed thresholds (>5 files or >100 lines)
  - Suggests commit message with issue scope
  - Configurable via `CCPM_GUARD_COMMIT_MAX_FILES`, `CCPM_GUARD_COMMIT_MAX_LINES`

- **Claude-Mem Integration Guide** (`helpers/claude-mem-integration.md`)
  - Documentation for integrating claude-mem with CCPM
  - Complementary features: CCPM for workflow, claude-mem for memory
  - Installation and configuration instructions
  - Usage patterns for semantic search and cross-session context

- **Enhanced Hook Logging**
  - All hooks now log to `/tmp/ccpm-hooks.log`
  - Shared logger utility (`hooks/scripts/lib/hook-logger.cjs`)
  - Timestamped entries with hook name and status
  - Session log cleared on SessionStart

- **New Utility Commands**
  - `/ccpm:search` - Search Linear issues by query, status, label, assignee
  - `/ccpm:history` - Activity timeline combining git + Linear events
  - `/ccpm:branch` - Smart git branch management with Linear linking
  - `/ccpm:review` - AI-powered code review with interactive fixes
  - `/ccpm:rollback` - Safe undo for git commits, files, Linear status
  - `/ccpm:chain` - Execute chained commands with conditional logic

- **Command Variants**
  - `/ccpm:plan:quick` - Fast planning for simple tasks
  - `/ccpm:plan:deep` - Thorough research-based planning
  - `/ccpm:work:parallel` - Parallel execution of independent tasks

- **Development Agents** (6 new agents)
  - `frontend-developer` - React/UI with design system integration
  - `backend-architect` - APIs, NestJS, databases, authentication
  - `tdd-orchestrator` - Test-driven development workflow
  - `code-reviewer` - Automated code review and quality
  - `debugger` - Systematic debugging investigation
  - `security-auditor` - OWASP Top 10, security assessment

- **New Helpers**
  - `helpers/parallel-execution.md` - DAG-based dependency graphs
  - `helpers/command-chaining.md` - Chain operators and workflow templates

### Changed

- Hook system now has 6 phases: SessionStart, UserPromptSubmit, PreToolUse, SubagentStart, Stop
- Updated plugin description for v1.2 features
- Command count: 13 → 19 commands
- Agent count: 8 → 14 agents
- Helper count: 10 → 12 helpers

---

## [1.1.0] - 2025-12-20

### Added

- **Shared Linear Integration Helpers**
  - `getOrCreateLabel()` - Auto-creates missing labels with standardized CCPM colors
  - `getValidStateId()` - Validates state names with fuzzy matching and fallback mappings
  - `ensureLabelsExist()` - Batch label processing with sequential execution
  - `getDefaultColor()` - Standardized CCPM color palette for consistent visual identity

- **Comprehensive Error Handling for Linear Operations**
  - Detailed error handling patterns for 6 error categories
  - User-friendly error messages with recovery steps
  - 9 major error handling sections covering all Linear integration points

- **Integration Testing Infrastructure**
  - 42 comprehensive test cases covering all helper functions
  - Test runner script with category selection and verbose mode
  - Automated cleanup utility for test data

### Changed

- All commands now use validated state IDs instead of hardcoded assumptions
- All commands ensure labels exist before referencing them
- State type matching works across all Linear team workflows

### Fixed

- State resolution issues with custom workflow names
- Label management issues with case-insensitive matching
- Error handling gaps in Linear MCP operations

---

## [1.0.0] - 2025-12-15

### 🎉 Initial Release

Complete plugin with lean architecture and powerful features.

### Added

- **6 Natural Workflow Commands**
  - `/ccpm:plan` - Create or plan tasks (3 modes: new, existing, update)
  - `/ccpm:work` - Start or resume work (auto-detects from branch)
  - `/ccpm:sync` - Save progress to Linear with concise updates
  - `/ccpm:commit` - Git commit with conventional format + Linear linking
  - `/ccpm:verify` - Quality checks + code review
  - `/ccpm:done` - Create PR + sync status + complete task

- **6 Project Configuration Commands**
  - `/ccpm:project:add`, `list`, `show`, `set`, `update`, `delete`

- **Visual Context Integration**
  - `/ccpm:figma-refresh` - Force refresh Figma design cache
  - Automatic image detection and analysis in Linear issues
  - Figma design extraction with Tailwind class mappings
  - Pixel-perfect UI implementation (95-100% fidelity)

- **Linear Operations Subagent**
  - Centralized handler for all Linear MCP operations
  - 50-60% token reduction through session-level caching
  - 85-95% cache hit rate for teams, projects, labels
  - Structured error handling with actionable suggestions

- **Background Linear Operations**
  - Non-blocking execution for comments and status updates
  - `scripts/linear-background-ops.sh` for fire-and-forget operations
  - `scripts/linear-retry-wrapper.sh` for exponential backoff

- **Agent Delegation Pattern** (Context Protection)
  - Mandatory agent delegation for all implementation
  - Explore agent for codebase analysis
  - Specialized agents for frontend/backend/mobile
  - ~50 tokens per task (vs ~2000-5000 inline)

- **Smart Agent Auto-Invocation**
  - Dynamic agent discovery (global, plugin, project-specific)
  - Context-aware scoring algorithm (0-100+)
  - 81.7% token reduction with caching
  - <1s execution with 85-95% cache hit rate

- **10 Reusable Helper Modules**
  - `image-analysis.md` - Image detection and visual context
  - `figma-detection.md` - Figma link detection and MCP integration
  - `checklist.md`, `decision-helpers.md`, `linear.md`, and more

### Features

- **Linear Integration** - Complete Linear API integration for issues, documents, comments
- **Tool-Agnostic Architecture** - Jira, Confluence, BitBucket via abstraction layer
- **Safety Rules** - Explicit confirmation for external PM writes
- **User-Controlled Quality** - You decide when to verify and commit

### Performance

- **Token Reduction**: 50-60% via Linear subagent caching
- **Cache Hit Rate**: 85-95% for Linear operations
- **Latency**: <50ms for cached operations
- **Visual Analysis**: ~2-5s per image, ~10-25s total for UI tasks

---

**CCPM** - Lean, powerful project management with visual context for pixel-perfect implementation.
