# CCPM Skills

This directory contains all CCPM skills - modular capabilities that Claude automatically discovers and uses based on context.

## What Are Skills?

Skills are **model-invoked** capabilities that Claude activates automatically when relevant to your task. Unlike slash commands (which you explicitly invoke), skills work in the background to provide:

- Context-aware guidance
- Workflow automation
- Safety enforcement
- Best practices

## Available Skills

### Core PM Skills (CCPM-Specific)

1. **external-system-safety** - Prevents accidental writes to Jira/Confluence/BitBucket/Slack
2. **pm-workflow-guide** - Auto-suggests appropriate CCPM commands based on workflow phase

### Problem-Solving Skills

3. **sequential-thinking** - Structured problem-solving through iterative reasoning
4. **docs-seeker** - Documentation discovery and research

### Quality & Verification Skills

5. **ccpm-code-review** - Verification enforcement before completion (adapted from claudekit-skills)
6. **ccpm-debugging** - Systematic debugging with Linear tracking (adapted from claudekit-skills)

### Infrastructure Skills

7. **ccpm-mcp-management** - MCP server discovery and troubleshooting (adapted from claudekit-skills)

### Development Skills

8. **ccpm-skill-creator** - Create custom CCPM skills with templates (adapted from claudekit-skills)

## Skill Structure

Every skill is a directory containing:

```
skill-name/
├── SKILL.md              # Required: Skill definition with frontmatter
└── supporting-docs/      # Optional: Referenced documentation
```

### SKILL.md Format

```yaml
---
name: skill-name-lowercase
description: What the skill does and when Claude should use it (max 1024 chars)
allowed-tools: optional, comma-separated, tool-list
---

# Skill Display Name

## Instructions

Step-by-step guidance for Claude on how to use this skill.

## Examples

Concrete usage scenarios.
```

## How Skills Activate

Skills activate automatically based on:

1. **Trigger phrases** in user messages
2. **CCPM command execution**
3. **Workflow phase detection**

### Example: Planning Phase

```
User: "I need to plan the authentication feature"
       ↓
pm-workflow-guide activates → Suggests /ccpm:planning:create
sequential-thinking activates → Guides task decomposition
       ↓
Claude suggests optimal workflow
```

## Skill Categories

### Safety Skills

Prevent accidental mistakes:
- **external-system-safety** - Blocks unconfirmed external writes

### Workflow Skills

Guide optimal workflows:
- **pm-workflow-guide** - Command suggestions
- **sequential-thinking** - Problem decomposition

### Quality Skills

Enforce best practices:
- **ccpm-code-review** - Verification gates
- **ccpm-debugging** - Systematic troubleshooting

### Infrastructure Skills

Help with setup:
- **ccpm-mcp-management** - MCP troubleshooting

### Meta Skills

Create more skills:
- **ccpm-skill-creator** - Skill development templates

## Creating Custom Skills

Use the `ccpm-skill-creator` skill to create team-specific or project-specific skills.

### Quick Start

1. Ask Claude: "Create a custom skill for [your workflow]"
2. `ccpm-skill-creator` activates and guides you
3. Customize the template
4. Test activation

### Skill Naming Conventions

- **CCPM-specific skills**: Prefix with `ccpm-` (e.g., `ccpm-code-review`)
- **General skills**: No prefix (e.g., `sequential-thinking`)
- **Team skills**: Prefix with team name (e.g., `acme-deployment`)
- **Project skills**: Store in `.claude/skills/` (project-local)

## Skill Integration with CCPM

### Skills Work With Commands

| Skill | CCPM Commands | When Activated |
|-------|---------------|----------------|
| pm-workflow-guide | All commands | "which command should I use" |
| sequential-thinking | `/ccpm:planning:create`<br>`/ccpm:spec:write` | "break down", "analyze" |
| docs-seeker | `/ccpm:spec:write` | "documentation", "API docs" |
| ccpm-code-review | `/ccpm:verification:verify`<br>`/ccpm:complete:finalize` | "done", "ready to merge" |
| ccpm-debugging | `/ccpm:verification:fix` | "error", "failing", "broken" |

### Skills Work With Hooks

| Skill | CCPM Hook | Relationship |
|-------|-----------|--------------|
| external-system-safety | - | Independent safety layer |
| ccpm-code-review | `quality-gate` | Complements verification |
| pm-workflow-guide | `smart-agent-selector` | Different phases (command vs agent) |

### Skills Work Together

| Skill A | Skill B | Synergy |
|---------|---------|---------|
| sequential-thinking | pm-workflow-guide | Reasoning + Command suggestions |
| ccpm-code-review | external-system-safety | Verification + Confirmation |
| ccpm-debugging | ccpm-code-review | Fix issues → Verify fixes |
| docs-seeker | Context7 MCP | Search + Fetch documentation |

## Troubleshooting

### Skill Not Activating

**Check**:
1. Is the skill description clear with trigger phrases?
2. Does your request match the skill's purpose?
3. Try verbose mode: `claude --verbose`

**Example**:
```bash
# Vague (skill might not activate)
"Help me with this"

# Specific (skill will activate)
"Break down this complex epic into tasks" → sequential-thinking
"Find React documentation" → docs-seeker
"I'm done, ready to merge" → ccpm-code-review
```

### Multiple Skills Activating

This is **expected and good**! Skills are designed to work together.

**Example**:
```
User: "Plan this complex feature"
       ↓
✓ pm-workflow-guide → Suggests /ccpm:planning:create
✓ sequential-thinking → Guides decomposition
✓ docs-seeker → Finds relevant docs
       ↓
Combined: Comprehensive planning workflow
```

### Skill Conflicts

Skills are designed to be **complementary**, not conflicting. If you notice conflicts:

1. Review skill descriptions for overlapping triggers
2. Check `SKILLS_COMPARISON_MATRIX.md` for documented interactions
3. Report issue with specific scenario

## Skill Sources

### CCPM-Original Skills (2)

Created specifically for CCPM:
- `external-system-safety`
- `pm-workflow-guide`

### ClaudeKit-Skills Adaptations (4)

Adapted from [claudekit-skills](https://github.com/mrgoonie/claudekit-skills):
- `ccpm-code-review` (from `code-review`)
- `ccpm-debugging` (from `debugging`)
- `ccpm-mcp-management` (from `mcp-management`)
- `ccpm-skill-creator` (from `skill-creator`)

### ClaudeKit-Skills As-Is (2)

Copied directly without modification:
- `sequential-thinking`
- `docs-seeker`

## Best Practices

### For Skill Users

1. **Trust skill suggestions** - They activate based on context
2. **Use specific language** - Clear requests activate right skills
3. **Combine with commands** - Skills enhance, don't replace commands
4. **Learn trigger phrases** - See individual SKILL.md files

### For Skill Creators

1. **Clear descriptions** - Include trigger phrases and use cases
2. **CCPM integration** - Reference commands, hooks, Linear workflows
3. **Safety first** - Add confirmation for external writes
4. **Progressive disclosure** - Reference docs, don't inline everything
5. **Test thoroughly** - Validate activation and integration

## Safety Rules

All CCPM skills must follow safety rules from `../commands/SAFETY_RULES.md`:

### ⛔ NEVER Without Confirmation

- Jira: Creating issues, updating status, posting comments
- Confluence: Creating/editing pages
- BitBucket: Creating PRs, posting comments
- Slack: Sending messages

### ✅ Always Allowed

- Read operations from external systems
- Linear operations (internal tracking)
- Local file operations

### Enforcement

The `external-system-safety` skill provides automatic enforcement even when other skills or agents are invoked.

## References

- **Comprehensive Integration Plan**: `../CLAUDEKIT_SKILLS_INTEGRATION_PLAN.md`
- **Skills Comparison**: `../SKILLS_COMPARISON_MATRIX.md`
- **Quick Reference**: `../SKILLS_QUICK_REFERENCE.md`
- **Safety Rules**: `../commands/SAFETY_RULES.md`
- **Plugin Config**: `../.claude-plugin/plugin.json`

## Contributing

To contribute a new skill:

1. Use `ccpm-skill-creator` to generate template
2. Follow CCPM skill conventions (this README)
3. Test activation and integration
4. Submit PR with:
   - Skill directory with SKILL.md
   - Update to this README
   - Test scenarios
   - Integration documentation

---

**Total Skills**: 8 (2 CCPM-original + 4 adapted + 2 as-is)
**Philosophy**: Automatic activation, complementary design, safety-first
**Next**: See individual skill SKILL.md files for details
