# CCPM User Guide

## Quick Start Guide for Using CCPM v1.0 in Your Projects

This guide is for developers using CCPM in their daily workflow. For plugin development, see [CLAUDE.md](./CLAUDE.md).

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Natural Workflow Commands](#natural-workflow-commands)
- [Visual Context (UI/UX Tasks)](#visual-context-uiux-tasks)
- [Project Configuration](#project-configuration)
- [Complete Workflow Examples](#complete-workflow-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Adding CCPM to Your Project](#adding-ccpm-to-your-project)

## Installation

CCPM is a Claude Code plugin. Install it once globally:

```bash
# Install from marketplace (when published)
/plugin install ccpm

# Or install from local directory
/plugin install /path/to/ccpm
```

**Required MCP Servers:**

- **Linear**: For task tracking
- **GitHub**: For PR creation

**Optional MCP Servers:**

- **Figma**: For design system extraction (UI/UX tasks)
- **Context7**: For latest library documentation
- **Jira/Confluence**: For external PM tool integration

## Quick Start

### 1. Configure Your Project

```bash
# Add your project
/ccpm:project:add my-app

# Set as active project
/ccpm:project:set my-app
```

### 2. Complete a Task

```bash
# Plan a new feature
/ccpm:plan "Add user authentication"

# Start working (creates branch automatically)
/ccpm:work

# Make changes, then save progress
/ccpm:sync "Implemented JWT token generation"

# Commit your changes
/ccpm:commit

# Verify quality
/ccpm:verify

# Create PR and finalize
/ccpm:done
```

That's it! CCPM handles the rest (Linear updates, git operations, PR creation).

## Natural Workflow Commands

CCPM provides 6 commands for the complete development lifecycle:

### `/ccpm:plan` - Plan Tasks

**Three modes:**

1. **Create new task:**

   ```bash
   /ccpm:plan "Add user authentication"
   ```

   - Creates Linear issue
   - Researches codebase/docs
   - Generates implementation plan
   - Updates Linear description

2. **Plan existing task:**

   ```bash
   /ccpm:plan PSN-123
   ```

   - Loads issue from Linear
   - Analyzes requirements
   - Generates implementation plan
   - Updates Linear description

3. **Update existing plan:**

   ```bash
   /ccpm:plan PSN-123 "Add OAuth2 support"
   ```

   - Updates existing plan
   - Adds new requirements
   - Updates Linear description

**Visual Context Detection:**

- Automatically detects images in Linear attachments
- Extracts Figma designs from descriptions
- Analyzes UI mockups for implementation details
- Achieves 95-100% design fidelity

**Example:**

```bash
# Plan UI task with Figma design
/ccpm:plan "Implement login screen"
# → Detects Figma link in Linear description
# → Extracts colors, typography, spacing
# → Maps to Tailwind classes (blue-500, font-sans, space-4)
# → Updates description with implementation guide
```

### `/ccpm:work` - Start or Resume Work

**Auto-detection:**

- Detects issue from git branch name
- Example: `feature/PSN-29-add-auth` → works on PSN-29
- Determines if starting new work or resuming

**Usage:**

```bash
# Auto-detect from branch
/ccpm:work

# Or specify issue explicitly
/ccpm:work PSN-123
```

**What it does:**

- Loads implementation plan from Linear
- Loads visual context (images, Figma designs)
- Passes to appropriate agents (frontend, backend, etc.)
- Updates Linear status to "In Progress"

**Pixel-Perfect Implementation:**
For UI tasks, agents see actual mockups:

```bash
/ccpm:work PSN-45  # UI task with attached screenshot
# → Agent sees the image directly
# → Implements with 95-100% accuracy
# → No lossy text interpretation
```

### `/ccpm:sync` - Save Progress

**Auto-detection:**

- Detects issue from git branch
- Shows git changes summary
- Updates Implementation Checklist in Linear

**Usage:**

```bash
# Auto-detect from branch
/ccpm:sync "Implemented JWT endpoints"

# Or specify issue explicitly
/ccpm:sync PSN-123 "Added refresh token logic"
```

**What it does:**

- Analyzes uncommitted changes
- Updates Linear comment (concise, 50-100 words)
- Checks off completed checklist items
- Timestamps progress

**Sync frequency:**

- Every 30-60 minutes during active work
- Before switching tasks
- At end of work session

### `/ccpm:commit` - Git Commit

**Auto-detection:**

- Detects issue from git branch
- Generates conventional commit message
- Links commit to Linear issue

**Usage:**

```bash
# Auto-detect from branch
/ccpm:commit

# Or specify custom message
/ccpm:commit "Custom commit message"
```

**Conventional Commits Format:**

```text
feat(auth): implement JWT token generation

- Add JWT utilities for token creation
- Implement refresh token rotation
- Add token validation middleware

Refs: PSN-123
```

**Commit types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Test additions/updates
- `chore`: Maintenance tasks

### `/ccpm:verify` - Quality Checks

**Two-phase verification:**

1. **Quality Checks:**
   - Runs tests (unit, integration, e2e)
   - Checks build success
   - Runs linters/formatters
   - Invokes code-reviewer agent

2. **Final Verification:**
   - Reviews Implementation Checklist
   - Checks for blockers
   - Confirms all tasks complete
   - Validates requirements met

**Usage:**

```bash
/ccpm:verify

# Or specify issue explicitly
/ccpm:verify PSN-123
```

**Fail-fast behavior:**

- Stops if quality checks fail
- Shows specific failures
- Suggests fixes
- Must pass before `/ccpm:done`

### `/ccpm:done` - Finalize Task

**Pre-flight checks:**

- Verification must pass first
- All changes committed
- Branch up to date with base

**Usage:**

```bash
# Auto-detect from branch
/ccpm:done

# Or specify issue explicitly
/ccpm:done PSN-123
```

**What it does:**

1. Creates GitHub pull request
2. Links PR to Linear issue
3. Updates Linear status to "Done"
4. Optional: Syncs with Jira/Slack (requires confirmation)

**PR format:**

```markdown
## Summary
- Added JWT authentication endpoints
- Implemented token refresh logic
- Added middleware for token validation

## Test Plan
- [x] Unit tests pass
- [x] Integration tests pass
- [x] Manual testing complete
- [x] Security review done

Closes PSN-123
```

## Visual Context (UI/UX Tasks)

CCPM v1.0 automatically detects and analyzes visual context for pixel-perfect UI implementation.

### Supported Formats

**Images:**

- PNG, JPG, GIF, WEBP, SVG
- UI mockups, wireframes, screenshots
- Architecture diagrams, flow charts

**Figma Designs:**

- Design files with frames/components
- Color palettes → Tailwind mappings
- Typography → Font family mappings
- Spacing → Tailwind scale mappings

### How It Works

1. **Detection Phase** (`/ccpm:plan`):
   - Scans Linear attachments for images
   - Detects markdown images in descriptions
   - Extracts Figma links from descriptions/comments

2. **Analysis Phase**:
   - Analyzes visual content with context-aware prompts
   - For images: Extracts layout, colors, typography, spacing
   - For Figma: Extracts design tokens and maps to Tailwind

3. **Implementation Phase** (`/ccpm:work`):
   - Loads images directly for agents to see
   - Passes visual references to frontend/mobile agents
   - Agents implement with 95-100% accuracy

### Example: Figma Design

```bash
# 1. Plan task (includes Figma link in description)
/ccpm:plan "Implement login screen"
# → Detects: https://www.figma.com/file/abc123/Login
# → Extracts design system
# → Updates Linear description:

## Design System (from Figma)
### Colors
- Primary: #3b82f6 → `bg-blue-500`
- Background: #ffffff → `bg-white`
- Text: #1f2937 → `text-gray-900`

### Typography
- Font: Inter → `font-sans`
- Heading: 24px/bold → `text-2xl font-bold`
- Body: 16px/normal → `text-base`

### Spacing
- Container padding: 24px → `p-6`
- Input spacing: 16px → `space-y-4`
```

```bash
# 2. Start implementation
/ccpm:work
# → Agent sees Figma design + Tailwind mappings
# → Implements with pixel-perfect accuracy
```

### Force Refresh Figma Cache

Designers update Figma frequently. Refresh cache when designs change:

```bash
/ccpm:figma-refresh PSN-123
```

**When to refresh:**

- Designer notifies of color changes
- Typography updates
- Spacing adjustments
- New components added

**What it does:**

- Fetches latest Figma data (bypasses cache)
- Re-extracts design tokens
- Detects changes (colors, typography, spacing)
- Updates Linear description with fresh mappings

**Performance:**

- First run: ~11-21 seconds
- Cached: ~2-3 seconds
- Cache TTL: 1 hour

## Project Configuration

CCPM supports multi-project and monorepo setups.

### List Projects

```bash
/ccpm:project:list
```

**Output:**

```text
Projects:
1. my-app (active)
2. api-service
3. mobile-app
```

### Add Project

```bash
# Basic project
/ccpm:project:add my-app

# With template (fullstack, mobile, monorepo)
/ccpm:project:add my-app --template fullstack-with-jira

# Monorepo subdirectory
/ccpm:project:add my-monorepo
# Then configure subdirectories in project settings
```

### Show Project

```bash
/ccpm:project:show my-app
```

**Output:**

```yaml
id: my-app
name: My Application
linear:
  teamId: TEAM-123
  projectId: PRJ-456
github:
  owner: my-org
  repo: my-app
```

### Set Active Project

```bash
/ccpm:project:set my-app
```

**Auto-detection:**

- Detects from git remote URL
- Detects from subdirectory patterns (monorepos)
- Falls back to manual setting

### Update Project

```bash
# Update specific field
/ccpm:project:update my-app --field linear.teamId

# Interactive update
/ccpm:project:update my-app
```

### Delete Project

```bash
# Safe delete (prompts for confirmation)
/ccpm:project:delete my-app

# Force delete (no confirmation)
/ccpm:project:delete my-app --force
```

## Complete Workflow Examples

### Example 1: Feature Development

```bash
# 1. Plan new feature
/ccpm:plan "Add user authentication with JWT"
# → Creates PSN-45 in Linear
# → Researches JWT best practices
# → Generates implementation plan
# → Updates Linear description

# 2. Start work
/ccpm:work
# → Creates branch: feature/PSN-45-add-user-auth
# → Switches to branch
# → Updates Linear status: "In Progress"

# 3. Implement (make changes)
# ... code, code, code ...

# 4. Save progress (every 30-60 min)
/ccpm:sync "Implemented JWT token generation"
# → Updates Linear comment
# → Checks off completed items

# 5. Continue work
# ... more coding ...

/ccpm:sync "Added refresh token rotation"
# → Another Linear update

# 6. Commit changes
/ccpm:commit
# → Generates conventional commit
# → Links to PSN-45

# 7. Verify quality
/ccpm:verify
# → Runs tests (unit, integration, e2e)
# → Checks build
# → Runs linters
# → Reviews checklist

# 8. Finalize
/ccpm:done
# → Creates GitHub PR
# → Links PR to PSN-45
# → Updates Linear status: "Done"
```

**Total time saved:** ~30-45 minutes per task (vs manual process)

### Example 2: Bug Fix

```bash
# 1. Plan bug fix (existing issue)
/ccpm:plan PSN-89
# → Loads bug report from Linear
# → Analyzes root cause
# → Generates fix plan
# → Updates Linear description

# 2. Start work
/ccpm:work PSN-89
# → Creates branch: fix/PSN-89-login-error
# → Updates status: "In Progress"

# 3. Implement fix
# ... fix the bug ...

# 4. Commit
/ccpm:commit
# → Auto-generates: "fix(auth): resolve login redirect error"

# 5. Verify
/ccpm:verify
# → Runs tests
# → Confirms fix works

# 6. Finalize
/ccpm:done
# → Creates PR
# → Closes PSN-89
```

### Example 3: UI Implementation (with Figma)

```bash
# 1. Plan UI task (with Figma design)
/ccpm:plan "Implement dashboard layout"
# → Creates PSN-67
# → Detects Figma link in description
# → Extracts design system (colors, fonts, spacing)
# → Maps to Tailwind classes
# → Updates Linear with mappings

# 2. Start work (pixel-perfect mode)
/ccpm:work
# → Loads Figma design for agent
# → Agent sees exact mockup
# → Implements with 95-100% accuracy

# 3. Designer updates Figma
# ... designer changes colors ...

# 4. Refresh cache
/ccpm:figma-refresh PSN-67
# → Fetches latest design
# → Detects color changes
# → Updates Tailwind mappings

# 5. Continue work with updated design
/ccpm:sync "Updated colors per latest Figma"

# 6. Commit, verify, finalize
/ccpm:commit
/ccpm:verify
/ccpm:done
```

## Best Practices Guide

### ✅ DO

**Workflow:**

- Use commands in sequence: `plan → work → sync → commit → verify → done`
- Let CCPM auto-detect issues from branch names
- Sync progress every 30-60 minutes
- Run `/ccpm:verify` before creating PRs

**Planning:**

- Use `/ccpm:plan` for all tasks (even small ones)
- Include visual context (images, Figma links) in Linear
- Review generated plan before starting work
- Update plans when requirements change

**Progress Tracking:**

- Use `/ccpm:sync` instead of manual Linear updates
- Write concise summaries (50-100 words)
- Sync before switching tasks
- Sync at end of work session

**Quality:**

- Always run `/ccpm:verify` before `/ccpm:done`
- Fix issues before finalizing
- Don't skip quality checks

### ❌ DON'T

**Workflow:**

- Don't manually update Linear descriptions (use `/ccpm:sync`)
- Don't skip planning phase (always use `/ccpm:plan` first)
- Don't commit without syncing (use `/ccpm:sync` before `/ccpm:commit`)
- Don't finalize without verification (use `/ccpm:verify` before `/ccpm:done`)

**Planning:**

- Don't start work without a plan
- Don't ignore visual context for UI tasks
- Don't forget to update plans when scope changes

**Progress Tracking:**

- Don't write progress to local markdown files (use Linear comments)
- Don't write overly detailed summaries (keep it concise)
- Don't forget to sync before long breaks

**Quality:**

- Don't bypass `/ccpm:verify` (always run it)
- Don't finalize with failing tests
- Don't skip code review

## Troubleshooting

### Issue Not Auto-Detected

**Problem:** CCPM can't detect issue from branch name

**Solution:**

```bash
# Check branch name format
git branch --show-current
# Should be: feature/PSN-123-description

# Or specify issue explicitly
/ccpm:work PSN-123
/ccpm:sync PSN-123 "Progress update"
```

### Figma Design Not Loading

**Problem:** Figma design not extracted during planning

**Solution:**

1. Verify Figma MCP server is running
2. Check Figma link format: `https://www.figma.com/file/...`
3. Ensure Figma file is accessible (not private)
4. Try force refresh: `/ccpm:figma-refresh PSN-123`

### Quality Checks Failing

**Problem:** `/ccpm:verify` fails with test errors

**Solution:**

1. Review test output
2. Fix failing tests
3. Re-run `/ccpm:verify`
4. Don't bypass verification

### PR Creation Fails

**Problem:** `/ccpm:done` can't create PR

**Solution:**

1. Ensure all changes committed: `git status`
2. Check branch pushed to remote: `git push`
3. Verify GitHub MCP server configured
4. Check GitHub permissions

### Project Not Detected

**Problem:** CCPM can't detect active project

**Solution:**

```bash
# List projects
/ccpm:project:list

# Set active project
/ccpm:project:set my-app

# Or add project if missing
/ccpm:project:add my-app
```

## Adding CCPM to Your Project

To help Claude Code understand CCPM usage in your project, add this snippet to your project's `CLAUDE.md`:

```markdown
## CCPM Workflow

This project uses CCPM v1.0 for development workflow.

### Quick Commands

```bash
/ccpm:plan [title]    # Create/plan tasks
/ccpm:work [issue]    # Start/resume work
/ccpm:sync [summary]  # Save progress
/ccpm:commit [msg]    # Git commit
/ccpm:verify          # Quality checks
/ccpm:done            # Finalize + PR
```

### Workflow

1. Plan: `/ccpm:plan "Feature name"`
2. Work: `/ccpm:work` (auto-detects from branch)
3. Progress: `/ccpm:sync "What I did"`
4. Commit: `/ccpm:commit`
5. Verify: `/ccpm:verify`
6. Finalize: `/ccpm:done`

### Visual Context (UI Tasks)

- Attach mockups to Linear issues
- Include Figma links in descriptions
- Force refresh: `/ccpm:figma-refresh <issue-id>`

### Best Practices

- Always plan before working (`/ccpm:plan` first)
- Sync progress every 30-60 minutes
- Verify before finalizing (`/ccpm:verify` before `/ccpm:done`)
- Let CCPM auto-detect issues from branch names

For details, see [CCPM User Guide](https://github.com/duongdev/ccpm/blob/main/USER_GUIDE.md).

```text
(End of template)
```

Copy this to `.claude/CLAUDE.md` or your project root's `CLAUDE.md`.

## Resources

- **Full Documentation:** [CLAUDE.md](./CLAUDE.md)
- **Command Reference:** [commands/README.md](./commands/README.md)
- **Skills Catalog:** [skills/README.md](./skills/README.md)
- **Safety Rules:** [commands/SAFETY_RULES.md](./commands/SAFETY_RULES.md)

## Support

**Issues:** <https://github.com/duongdev/ccpm/issues>

**Discussions:** <https://github.com/duongdev/ccpm/discussions>

---

Built with ❤️ for Claude Code users by the CCPM team.
