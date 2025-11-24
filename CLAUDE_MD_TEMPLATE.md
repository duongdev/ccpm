# CLAUDE.md Template for CCPM Users

Copy this snippet to your project's `CLAUDE.md` (or `.claude/CLAUDE.md`) to help Claude Code understand how to use CCPM in your project.

---

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

### Standard Workflow

1. **Plan**: `/ccpm:plan "Feature name"` - Creates task and generates implementation plan
2. **Work**: `/ccpm:work` - Starts work (auto-detects issue from branch name)
3. **Progress**: `/ccpm:sync "What I did"` - Saves progress to Linear every 30-60 min
4. **Commit**: `/ccpm:commit` - Creates conventional commit linked to Linear
5. **Verify**: `/ccpm:verify` - Runs quality checks (tests, build, linting, code review)
6. **Finalize**: `/ccpm:done` - Creates GitHub PR and marks task as Done

### Visual Context (UI/UX Tasks)

For pixel-perfect UI implementation:

- Attach UI mockups/screenshots to Linear issues
- Include Figma design links in issue descriptions
- CCPM automatically detects and analyzes visual context
- Achieves 95-100% design fidelity (vs 70-80% text-based)

Force refresh Figma cache after designer updates:

```bash
/ccpm:figma-refresh <issue-id>
```

### Best Practices

**✅ DO:**

- Always plan before working (`/ccpm:plan` first)
- Let CCPM auto-detect issues from branch names (format: `feature/PSN-123-description`)
- Sync progress every 30-60 minutes during active work
- Verify before finalizing (`/ccpm:verify` before `/ccpm:done`)
- Use visual context for UI tasks (attach mockups, include Figma links)

**❌ DON'T:**

- Don't manually update Linear descriptions (use `/ccpm:sync` instead)
- Don't skip planning phase (always use `/ccpm:plan` first)
- Don't commit without syncing (use `/ccpm:sync` before `/ccpm:commit`)
- Don't finalize without verification (use `/ccpm:verify` before `/ccpm:done`)
- Don't write progress to local markdown files (use Linear comments via `/ccpm:sync`)

### Project Configuration

This project uses CCPM project: `[PROJECT_ID]`

```bash
/ccpm:project:list           # List all projects
/ccpm:project:set [id]       # Switch active project
/ccpm:project:show [id]      # Show project config
```

### Example Complete Workflow

```bash
# 1. Plan new feature with visual context
/ccpm:plan "Implement user dashboard"
# → Creates Linear issue (e.g., PSN-45)
# → Detects Figma design link
# → Extracts colors, typography, spacing
# → Maps to Tailwind classes
# → Updates Linear with implementation plan

# 2. Start implementation (pixel-perfect mode)
/ccpm:work
# → Auto-detects PSN-45 from branch: feature/PSN-45-user-dashboard
# → Loads UI mockups for agent
# → Agent sees exact design (95-100% fidelity)
# → Updates Linear status: "In Progress"

# 3. Save progress periodically
/ccpm:sync "Implemented dashboard header and navigation"
# → Updates Linear Implementation Checklist
# → Adds concise comment (50-100 words)

# 4. Continue work
# ... make more changes ...

/ccpm:sync "Added data visualization components"

# 5. Commit changes
/ccpm:commit
# → Auto-generates: "feat(dashboard): implement user dashboard with data viz"
# → Links commit to PSN-45

# 6. Designer updates Figma → refresh cache
/ccpm:figma-refresh PSN-45
# → Fetches latest design
# → Detects color changes
# → Updates Linear with new mappings

# 7. Verify quality
/ccpm:verify
# → Runs tests, build, linting
# → Invokes code-reviewer agent
# → Updates Linear: "Ready for Review"

# 8. Finalize and create PR
/ccpm:done
# → Creates GitHub pull request
# → Links PR to Linear issue
# → Updates status: "Done"
```

### Safety Rules

CCPM follows strict safety rules:

- ✅ **Linear operations**: No confirmation needed (internal tracking)
- ⚠️ **External PM tools** (Jira, Confluence, Slack): Requires explicit confirmation before writes
- ⚠️ **Git commits/pushes**: Always asks for approval before executing

### Resources

- [CCPM User Guide](https://github.com/duongdev/ccpm/blob/main/USER_GUIDE.md)
- [Command Reference](https://github.com/duongdev/ccpm/blob/main/commands/README.md)
- [Safety Rules](https://github.com/duongdev/ccpm/blob/main/commands/SAFETY_RULES.md)

---

## Project-Specific Notes

[Add any project-specific CCPM configuration or notes here]

**Active Project:** `[PROJECT_ID]`
**Linear Team:** `[TEAM_NAME]`
**Default Branch:** `main`

[Optional: Add custom agents, hooks, or skills specific to this project]
