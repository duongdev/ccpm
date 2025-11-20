# Changelog

All notable changes to the CCPM plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Shared Linear Integration Helpers** (PSN-28)
  - `getOrCreateLabel()` - Auto-creates missing labels with standardized CCPM colors
  - `getValidStateId()` - Validates state names with fuzzy matching and fallback mappings
  - `ensureLabelsExist()` - Batch label processing with sequential execution
  - `getDefaultColor()` - Standardized CCPM color palette for consistent visual identity
  - Comprehensive documentation in `commands/_shared-linear-helpers.md`

- **Comprehensive Error Handling for Linear Operations** (PSN-28)
  - Detailed error handling patterns for 6 error categories
  - User-friendly error messages with recovery steps
  - 9 major error handling sections covering all Linear integration points
  - 15+ code examples demonstrating best practices
  - 5 recovery strategies for common failure scenarios
  - Documentation in `docs/development/linear-error-handling-guide.md`

- **Integration Testing Infrastructure** (PSN-28)
  - 42 comprehensive test cases covering all helper functions
  - Test runner script with category selection and verbose mode
  - Automated cleanup utility for test data
  - Complete testing guide with setup instructions
  - Example test runs with expected outputs
  - Documentation in `tests/integration/` directory

- **Troubleshooting Documentation** (PSN-28)
  - Complete troubleshooting guide for Linear integration issues
  - Quick diagnostics section for immediate problem identification
  - 6 common issue categories with detailed solutions
  - Error messages reference with explanations and fixes
  - 5 recovery procedures for common failure scenarios
  - Prevention best practices with code examples
  - Documentation in `docs/guides/troubleshooting-linear.md`

### Changed

- **Updated 6 Commands to Use Shared Linear Helpers** (PSN-28)
  - `/ccpm:planning:create` - Fixed "Backlog" state and label validation
  - `/ccpm:planning:design-approve` - Fixed "Todo" state and label validation
  - `/ccpm:spec:create` - Added label validation for epic/feature labels
  - `/ccpm:spec:break-down` - Ensured feature/task labels exist before use
  - `/ccpm:implementation:update` - Fixed "blocked" label assumption
  - `/ccpm:pr:check-bitbucket` - Fixed "In Review" state and pr-review label
  - All commands now use validated state IDs instead of hardcoded assumptions
  - All commands ensure labels exist before referencing them

### Fixed

- **State Resolution Issues** (PSN-28)
  - Commands no longer fail when workflow states have custom names
  - Fuzzy matching handles state name variations (e.g., "todo" → "unstarted" type)
  - Fallback mappings for common state aliases ("In Progress" → "started" type)
  - Clear error messages with available states when validation fails
  - State type matching works across all Linear team workflows

- **Label Management Issues** (PSN-28)
  - Missing labels are automatically created instead of causing silent failures
  - Label creation uses standardized CCPM color palette
  - Case-insensitive label matching prevents duplicate labels
  - Labels are reused if they already exist (idempotent operations)
  - Better error messages when label operations fail

- **Error Handling Gaps** (PSN-28)
  - All Linear MCP operations now have proper error handling
  - Network errors provide actionable recovery steps
  - Permission errors explain how to request access
  - Team/project errors guide users to correct configuration
  - Issue creation errors include context for debugging

### Documentation

- **Linear Integration Documentation** (PSN-28)
  - Added comprehensive troubleshooting guide
  - Created error handling guide for developers
  - Documented all shared helper functions
  - Created testing guide with 42 test cases
  - Added integration examples for common patterns
  - Updated CLAUDE.md with helper usage patterns

### Performance

- **Linear Helper Functions** (PSN-28)
  - Sequential label processing to respect rate limits
  - Efficient state validation with early exit on exact match
  - Cached color lookup via in-memory map
  - Minimal API calls through label reuse
  - Fast fuzzy matching with progressive fallback

## [2.2.0] - 2025-11-20

### Added

- **Automatic Image Analysis** for Linear issues
  - Detects images in Linear attachments and inline markdown
  - Analyzes UI mockups, architecture diagrams, screenshots
  - Formats visual context for inclusion in Linear descriptions
  - Image URLs preserved for implementation phase
  
- **Direct Visual Reference in Implementation Phase**
  - Frontend/mobile agents receive mockups directly via WebFetch
  - Pixel-perfect UI implementation (~95-100% fidelity)
  - Eliminates translation loss from text descriptions
  - Automatic UI task detection and image mapping

- **Configuration Options** for image analysis
  - `image_analysis.enabled` - Enable/disable feature (default: true)
  - `image_analysis.max_images` - Limit images per issue (default: 5)
  - `image_analysis.timeout_ms` - Timeout per image (default: 10000ms)
  - `image_analysis.implementation_mode` - Direct visual vs text-only
  - `image_analysis.formats` - Supported image formats

### Enhanced

- `/ccpm:planning:plan` - Now detects and analyzes images automatically
- `/ccpm:planning:create` - Inherits image analysis from planning:plan
- `/ccpm:utils:context` - Shows image preview with counts and URLs
- `/ccpm:planning:design-ui` - Analyzes reference mockups
- `/ccpm:implementation:start` - Prepares visual context for UI tasks

### Performance

- Image analysis adds ~2-5s per image
- Limited to 5 images by default to prevent excessive processing
- Graceful error handling - failed images don't block workflows

### Files Added

- `commands/_shared-image-analysis.md` - Image analysis utility (988 lines)

### Files Modified

- `commands/planning:plan.md` - Added Step 0.5: Detect and Analyze Images
- `commands/utils:context.md` - Added Step 1.5: Display Attached Images
- `commands/planning:design-ui.md` - Added Step 1.5: Analyze Reference Mockups
- `commands/implementation:start.md` - Added visual context and invocation patterns

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
