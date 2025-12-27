# CCPM Skills

Skills extend Claude Code's capabilities with specialized knowledge, workflows, and domain expertise. They auto-activate based on context, providing intelligent guidance without requiring explicit invocation.

## What Are Skills?

Skills are markdown files that teach Claude specific patterns, workflows, and best practices. Unlike commands (which you invoke explicitly), skills activate automatically when Claude detects relevant context in your conversation.

**Key characteristics:**
- **Auto-activation**: Trigger based on keywords, commands, or context
- **Composable**: Multiple skills can activate together
- **Extensible**: Create custom skills for team-specific workflows
- **Token-efficient**: Load only when needed

## Available Skills

### Code Quality & Review

| Skill | Description | Auto-Activates When |
|-------|-------------|---------------------|
| **ccpm-code-review** | Enforces quality verification gates with four-step validation (tests pass, build succeeds, checklist complete, no blockers) | User says "done", "complete", "finished", or runs `/ccpm:verify` |
| **ccpm-debugging** | Systematic debugging with defense-in-depth approach (symptoms -> immediate cause -> root cause -> prevention) | User mentions "error", "failing", "broken", "debug", "bug" |

### Workflow & Navigation

| Skill | Description | Auto-Activates When |
|-------|-------------|---------------------|
| **natural-workflow** | Guides through the 6-command workflow (plan/work/sync/commit/verify/done) | User asks about starting tasks, committing, or completing work |
| **pm-workflow-guide** | Context-aware PM workflow guidance with automatic phase detection | User mentions planning, implementation, verification |
| **workflow-state-tracking** | Tracks workflow state transitions (IDEA -> PLANNED -> IMPLEMENTING -> VERIFYING -> VERIFIED -> COMPLETE) | User asks "where am I", "what should I do next" |

### Planning & Strategy

| Skill | Description | Auto-Activates When |
|-------|-------------|---------------------|
| **planning-strategy-guide** | Intelligent planning with 6 phases (complexity assessment, scope definition, dependency analysis, risk identification, task breakdown, effort estimation) | User mentions epic breakdown, scope estimation, complexity assessment |
| **sequential-thinking** | Structured problem-solving through iterative reasoning with revision and branching | Tackling multi-step problems, design planning, architecture decisions |

### Project Management

| Skill | Description | Auto-Activates When |
|-------|-------------|---------------------|
| **project-detection** | Automatic project context detection with priority-based resolution | Start of every CCPM command |
| **project-operations** | Project setup and management with agent-based architecture | User mentions "add project", "configure project", "monorepo" |

### Integration & Tools

| Skill | Description | Auto-Activates When |
|-------|-------------|---------------------|
| **linear-subagent-guide** | Guides optimal Linear operations with caching, performance patterns, and error handling | Implementing CCPM commands that interact with Linear |
| **ccpm-mcp-management** | Discovers, manages, and troubleshoots MCP servers | User asks "MCP server", "tools available", "Linear not working" |
| **figma-integration** | Guides design-to-code workflow using Figma integration | User mentions Figma URLs, design implementation |

### Development Practices

| Skill | Description | Auto-Activates When |
|-------|-------------|---------------------|
| **commit-assistant** | Conventional commits guidance with auto-generated messages | User asks about committing or commit message formats |
| **docs-seeker** | Discovers authoritative documentation with version-specific search | User asks "find documentation", "API docs", "how to use" |
| **external-system-safety** | Enforces confirmation workflow for external system writes (Jira, Confluence, Slack) | Detecting potential writes to external PM systems |

### Meta Skills

| Skill | Description | Auto-Activates When |
|-------|-------------|---------------------|
| **ccpm-skill-creator** | Creates custom CCPM skills with proper templates and safety guardrails | User mentions "create skill", "custom workflow", "extend CCPM" |
| **hook-optimization** | Guidance on optimizing hooks for performance and token efficiency | Developing, debugging, or benchmarking hooks |

## How Skills Work

### Auto-Activation

Skills define trigger conditions in their frontmatter:

```yaml
---
name: ccpm-debugging
description: Systematic debugging with defense-in-depth approach...
---
```

When Claude detects matching context (keywords, command execution, or workflow state), the skill activates and provides specialized guidance.

### Skill Composition

Multiple skills can activate simultaneously for complex scenarios:

```
User: "I'm done implementing AUTH-123, ready to ship"
       |
       v
[ccpm-code-review activates]     - Verification gates
[pm-workflow-guide activates]    - Suggests /ccpm:verify
[external-system-safety activates] - Confirms external writes
```

### Integration with Commands

Skills enhance CCPM commands with domain knowledge:

- `/ccpm:plan` -> `planning-strategy-guide` provides 6-phase planning
- `/ccpm:work` -> `workflow-state-tracking` shows progress
- `/ccpm:verify` -> `ccpm-code-review` enforces quality gates
- `/ccpm:commit` -> `commit-assistant` generates conventional messages
- `/ccpm:done` -> `external-system-safety` confirms external writes

## Installing Skills

### Global Installation

Skills in `~/.claude/skills/` are available across all projects:

```bash
# Copy skill to global location
cp -r skills/my-skill ~/.claude/skills/
```

### Project Installation

Skills in `.claude/skills/` are project-specific:

```bash
# Copy skill to project
cp -r skills/my-skill .claude/skills/
```

### Plugin Skills

CCPM includes 17 skills installed automatically with the plugin.

## Creating Custom Skills

Use the `ccpm-skill-creator` skill or follow this template:

```yaml
---
name: my-custom-skill
description: Brief description with trigger phrases (max 1024 chars)
allowed-tools: [optional-tools-if-restricted]
---

# Skill Display Name

Brief overview of what this skill does.

## When to Use

Auto-activates when:
- Trigger phrase 1
- Trigger phrase 2
- CCPM command execution

## Instructions

Step-by-step guidance for Claude.

## Examples

Concrete examples with CCPM context.
```

### Skill Templates

**Team Workflow Skill**: Codify team-specific practices

```yaml
---
name: team-deployment
description: Team-specific deployment workflow...
---
```

**Safety Enforcement Skill**: Add additional safety checks

```yaml
---
name: company-security
description: Enforces security rules for sensitive operations...
allowed-tools: [read-file, grep]
---
```

**Integration Skill**: Connect with custom tools

```yaml
---
name: internal-tool-integration
description: Integrates CCPM with internal systems...
---
```

## Skill Best Practices

### Do's

- Use clear, descriptive skill names
- Include comprehensive trigger phrases in description
- Reference CCPM commands explicitly
- Follow CCPM safety rules
- Add concrete examples
- Document external system interactions
- Test skill activation

### Don'ts

- Create overly broad skills
- Duplicate existing CCPM functionality
- Skip safety considerations
- Use vague descriptions
- Hardcode environment-specific values

## Skill Directory Structure

Each skill lives in its own directory:

```
skills/
├── ccpm-code-review/
│   └── SKILL.md
├── ccpm-debugging/
│   └── SKILL.md
├── planning-strategy-guide/
│   ├── SKILL.md
│   └── examples.md          # Optional supporting docs
└── ...
```

## Troubleshooting

### Skill Not Activating

1. Check trigger phrases match your context
2. Verify skill is in correct location (`~/.claude/skills/` or `.claude/skills/`)
3. Check skill frontmatter is valid YAML
4. Ensure description is under 1024 characters

### Multiple Skills Conflicting

1. Skills with overlapping triggers may both activate
2. Use more specific trigger phrases
3. Consider combining related skills

### Skill Performance

1. Keep skills focused and concise
2. Avoid large examples that bloat token usage
3. Reference external files instead of embedding large content

## Quick Reference

### Common Activation Patterns

| Context | Skills That Activate |
|---------|---------------------|
| Planning a task | `pm-workflow-guide`, `planning-strategy-guide` |
| Starting work | `workflow-state-tracking`, `natural-workflow` |
| Debugging issues | `ccpm-debugging`, `sequential-thinking` |
| Completing work | `ccpm-code-review`, `external-system-safety` |
| Git commits | `commit-assistant` |
| Linear operations | `linear-subagent-guide` |
| Project setup | `project-detection`, `project-operations` |

### Skill Categories

- **Quality**: `ccpm-code-review`, `ccpm-debugging`
- **Workflow**: `natural-workflow`, `pm-workflow-guide`, `workflow-state-tracking`
- **Planning**: `planning-strategy-guide`, `sequential-thinking`
- **Projects**: `project-detection`, `project-operations`
- **Integration**: `linear-subagent-guide`, `ccpm-mcp-management`, `figma-integration`
- **Development**: `commit-assistant`, `docs-seeker`, `external-system-safety`
- **Meta**: `ccpm-skill-creator`, `hook-optimization`

## Safety Rules

All CCPM skills must follow safety rules:

### Never Without Confirmation

- Jira: Creating issues, updating status, posting comments
- Confluence: Creating/editing pages
- Slack: Sending messages
- Other external PM systems

### Always Allowed

- Read operations from external systems
- Linear operations (internal tracking)
- Local file operations
- Git operations (with standard workflow)

The `external-system-safety` skill provides automatic enforcement.

## Contributing

To contribute a new skill:

1. Create skill directory: `skills/my-skill/`
2. Add `SKILL.md` following the template above
3. Test activation with relevant triggers
4. Submit PR with skill documentation

## Resources

- [Creating Custom Skills](./ccpm-skill-creator/SKILL.md)
- [CCPM Commands](../commands/README.md)
- [Hook System](../hooks/README.md)
- [Agent Architecture](../agents/README.md)
