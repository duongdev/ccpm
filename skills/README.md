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
2. **pm-workflow-guide** - Auto-suggests appropriate CCPM commands based on workflow phase (prioritizes natural commands)
3. **natural-workflow** - Complete guide for 6-command workflow (plan/work/sync/commit/verify/done)
4. **workflow-state-tracking** - State machine visualization and transition validation
5. **figma-integration** - Guides design-to-code workflow using Figma designs

### Problem-Solving Skills

6. **sequential-thinking** - Structured problem-solving through iterative reasoning
7. **docs-seeker** - Documentation discovery and research
8. **planning-strategy-guide** - Intelligent planning with 6 phases (complexity, scope, dependencies, risks, breakdown, estimation)

### Quality & Verification Skills

9. **ccpm-code-review** - Verification enforcement before completion (updated for /ccpm:verify and /ccpm:done)
10. **ccpm-debugging** - Systematic debugging with Linear tracking (adapted from claudekit-skills)

### Infrastructure Skills

11. **ccpm-mcp-management** - MCP server discovery and troubleshooting (adapted from claudekit-skills)
12. **hook-optimization** - Hook performance guidance and benchmarking

### Development Skills

13. **ccpm-skill-creator** - Create custom CCPM skills with templates (adapted from claudekit-skills)
14. **project-detection** - Automatic project context detection in monorepos
15. **project-operations** - Project setup and management with monorepo best practices
16. **commit-assistant** - Conventional commits guidance and auto-generation
17. **linear-subagent-guide** - Linear operations optimization patterns

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
pm-workflow-guide activates → Suggests /ccpm:plan
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
| natural-workflow | `/ccpm:plan`<br>`/ccpm:work`<br>`/ccpm:sync`<br>`/ccpm:commit`<br>`/ccpm:verify`<br>`/ccpm:done` | "how do I start", "workflow", "walk me through" |
| pm-workflow-guide | All commands | "which command should I use" |
| workflow-state-tracking | `/ccpm:work`<br>`/ccpm:work` | "where am I", "what should I do next" |
| sequential-thinking | `/ccpm:plan`<br>`/ccpm:plan` | "break down", "analyze" |
| docs-seeker | `/ccpm:plan` | "documentation", "API docs" |
| figma-integration | `/ccpm:plan`<br>`/ccpm:plan`<br>`/ccpm:plan`<br>`/ccpm:figma-refresh` | "Figma", "design-to-code", "component" |
| commit-assistant | `/ccpm:commit` | "commit changes", "conventional commits" |
| ccpm-code-review | `/ccpm:verify`<br>`/ccpm:done` | "done", "ready to merge" |
| ccpm-debugging | `/ccpm:verify` | "error", "failing", "broken" |
| linear-subagent-guide | All Linear operations | When implementing commands with Linear |
| hook-optimization | Hook development | "optimize hook", "benchmark hook" |

### Skills Work With Hooks

| Skill | CCPM Hook | Relationship |
|-------|-----------|--------------|
| external-system-safety | - | Independent safety layer |
| ccpm-code-review | `quality-gate` | Complements verification |
| pm-workflow-guide | `smart-agent-selector` | Different phases (command vs agent) |

### Skills Work Together

| Skill A | Skill B | Synergy |
|---------|---------|---------|
| natural-workflow | workflow-state-tracking | Complete workflow + State validation |
| natural-workflow | commit-assistant | Workflow steps + Git commits |
| sequential-thinking | pm-workflow-guide | Reasoning + Command suggestions |
| figma-integration | sequential-thinking | Design analysis + Task decomposition |
| docs-seeker | figma-integration | Documentation + Design specs |
| ccpm-code-review | external-system-safety | Verification + Confirmation |
| ccpm-debugging | ccpm-code-review | Fix issues → Verify fixes |
| linear-subagent-guide | pm-workflow-guide | Linear optimization + Command workflow |
| hook-optimization | ccpm-skill-creator | Hook development + Skill creation |
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
✓ pm-workflow-guide → Suggests /ccpm:plan
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

### CCPM-Original Skills (8)

Created specifically for CCPM:
- `external-system-safety` (v2.0)
- `pm-workflow-guide` (v2.0, updated v2.2)
- `figma-integration` (v2.2)
- `natural-workflow` (v2.3)
- `workflow-state-tracking` (v2.3)
- `commit-assistant` (v2.3)
- `linear-subagent-guide` (v2.3)
- `hook-optimization` (v2.3)

### ClaudeKit-Skills Adaptations (4)

Adapted from [claudekit-skills](https://github.com/mrgoonie/claudekit-skills):
- `ccpm-code-review` (from `code-review`, updated v2.3)
- `ccpm-debugging` (from `debugging`)
- `ccpm-mcp-management` (from `mcp-management`)
- `ccpm-skill-creator` (from `skill-creator`)

### ClaudeKit-Skills As-Is (2)

Copied directly without modification:
- `sequential-thinking`
- `docs-seeker`

### Project-Specific Skills (2)

CCPM infrastructure skills:
- `project-detection` (v2.0)
- `project-operations` (v2.0, updated v2.3)

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

**Total Skills**: 17 (8 CCPM-original + 4 adapted + 3 as-is + 2 project-specific)
**Philosophy**: Automatic activation, complementary design, safety-first
**Version**: CCPM v2.3 (PSN-34: Phase 2 & 3 Complete)
**Next**: See individual skill SKILL.md files for details
