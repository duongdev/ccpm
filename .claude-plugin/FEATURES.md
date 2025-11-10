# CCPM Plugin Features Documentation

This file documents the features that were removed from `plugin.json` due to Claude Code schema validation. These are preserved here for documentation purposes.

## Feature Categories

### 1. Spec Management
**Commands:**
- `/pm:spec:create` - Create Epic/Feature/Initiative with Linear Document
- `/pm:spec:write` - AI-assisted spec writing
- `/pm:spec:review` - Validate spec completeness & quality (A-F grade)
- `/pm:spec:break-down` - Epic → Features or Feature → Tasks
- `/pm:spec:migrate` - Migrate .claude/ markdown specs to Linear
- `/pm:spec:sync` - Sync spec with implementation (detect drift)

### 2. Planning
**Commands:**
- `/pm:planning:create` - Create + plan Linear issue in one step
- `/pm:planning:plan` - Populate existing issue with research
- `/pm:planning:quick-plan` - Quick planning (no Jira)

### 3. Implementation
**Commands:**
- `/pm:implementation:start` - Start with agent coordination
- `/pm:implementation:next` - Smart next action detection
- `/pm:implementation:update` - Update subtask status

### 4. Verification
**Commands:**
- `/pm:verification:check` - Run quality checks (IDE, linting, tests)
- `/pm:verification:verify` - Final verification with verification-agent
- `/pm:verification:fix` - Fix verification failures

### 5. Completion
**Commands:**
- `/pm:complete:finalize` - Post-completion (PR + Jira sync + Slack)

### 6. Utilities
**Commands:**
- `/pm:utils:status` - Show detailed task status
- `/pm:utils:context` - Fast task context loading
- `/pm:utils:report` - Project-wide progress report
- `/pm:utils:insights` - AI complexity & risk analysis
- `/pm:utils:auto-assign` - AI-powered agent assignment
- `/pm:utils:sync-status` - Sync Linear → Jira (with confirmation)
- `/pm:utils:rollback` - Rollback planning changes
- `/pm:utils:dependencies` - Visualize task dependencies
- `/pm:utils:agents` - List available subagents
- `/pm:utils:help` - Context-aware help

### 7. Smart Agent Selection
**Hook:** UserPromptSubmit
**Description:** Dynamic agent discovery with context-aware scoring (0-100+) and intelligent execution planning

### 8. TDD Enforcement
**Hook:** PreToolUse
**Description:** Enforces test-driven development by blocking production code without tests

### 9. Quality Gates
**Hook:** Stop
**Description:** Automatic code review and security audits after implementation

## Requirements

### Required MCP Servers
- `linear` - Task tracking and spec management
- `github` - PR creation and repository operations
- `context7` - Latest library documentation

### Optional MCP Servers
- `playwright` - Browser automation for PR checks
- `vercel` - Deployment integration
- `shadcn` - UI component integration

## Safety Rules

The following safety rules apply to external system writes:

- **External writes** - Require user confirmation
- **Jira writes** - Require user confirmation
- **Confluence writes** - Require user confirmation
- **BitBucket writes** - Require user confirmation
- **Slack writes** - Require user confirmation
- **Linear writes** - Allowed (internal tracking)
- **Local writes** - Allowed

See `commands/SAFETY_RULES.md` for complete safety documentation.
