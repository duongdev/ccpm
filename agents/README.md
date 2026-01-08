# CCPM Agents

Specialized subagents for CCPM operations and development workflows.

## Overview

CCPM agents are specialized components that handle specific domains of functionality. They are invoked automatically by commands, hooks, or explicitly via the Task tool, providing focused expertise and optimized token usage through caching and batching.

## Agent Categories

### Linear and PM Operations

These agents handle project management integrations and provide centralized API operations with caching.

| Agent | Purpose |
|-------|---------|
| [linear-operations](./linear-operations.md) | Central handler for all Linear API operations with session-level caching |
| [pm-operations-orchestrator](./pm-operations-orchestrator.md) | Lightweight coordinator for multi-PM system operations with lazy loading |
| [jira-operations](./jira-operations.md) | Jira API operations with caching and Markdown/ADF conversion |
| [confluence-operations](./confluence-operations.md) | Confluence API operations with content-aware caching |

### Project Management

These agents manage project detection, configuration, and context across CCPM workflows.

| Agent | Purpose |
|-------|---------|
| [project-detector](./project-detector.md) | Detects active project and subproject from git remote, working directory, or patterns |
| [project-config-loader](./project-config-loader.md) | Loads and validates project configuration from CCPM config file |
| [project-context-manager](./project-context-manager.md) | Manages active project context including setting, displaying, and switching projects |

### Development Agents

These agents handle implementation tasks across different technology domains.

| Agent | Purpose |
|-------|---------|
| [frontend-developer](./frontend-developer.md) | React/UI implementation with design system integration and Tailwind styling |
| [backend-architect](./backend-architect.md) | API design, NestJS implementation, database operations, and authentication |
| [tdd-orchestrator](./tdd-orchestrator.md) | Test-driven development workflow orchestration with coverage requirements |
| [code-reviewer](./code-reviewer.md) | Automated code review covering security, bugs, performance, and quality |
| [code-quality-enforcer](./code-quality-enforcer.md) | Automated quality validation running lint/type/test checks on changed files |
| [debugger](./debugger.md) | Systematic debugging and issue investigation with root cause analysis |
| [security-auditor](./security-auditor.md) | Security vulnerability assessment covering OWASP Top 10 and compliance |

### Design Agents

| Agent | Purpose |
|-------|---------|
| [pm:ui-designer](./pm:ui-designer.md) | UI/UX design with wireframes, design system analysis, and developer specifications |

### CCPM Support Agents

These agents help users work with Claude Code and extend CCPM functionality.

| Agent | Purpose |
|-------|---------|
| [claude-code-guide](./claude-code-guide.md) | Answers questions about Claude Code features, settings, hooks, skills, and MCP |
| [ccpm-developer](./ccpm-developer.md) | Creates and extends CCPM commands, agents, skills, and hooks |
| [ccpm-troubleshooter](./ccpm-troubleshooter.md) | Diagnoses and resolves Claude Code and CCPM configuration issues |

## Agent Selection

### Automatic Selection

The smart-agent-selector hook automatically scores and suggests agents based on:

- **Keyword matching**: +10 per matching keyword in user message
- **Task type alignment**: +20 for task type relevance
- **Tech stack relevance**: +15 for matching technologies
- **Plugin agent bonus**: +5 for CCPM agents
- **Project-specific bonus**: +25 for project-configured agents

Agents scoring above threshold are automatically invoked or suggested.

### Manual Invocation

Invoke agents explicitly using the Task tool:

```javascript
Task({
  subagent_type: 'ccpm:frontend-developer',
  prompt: `
## Task
Create login form component

## Context
- Issue: PSN-123
- Branch: feature/psn-123-auth

## Requirements
- TypeScript strict mode
- Tailwind styling
- Accessible (a11y)
`
});
```

### Command Delegation

Commands delegate to agents internally based on task type:

| Task Type | Agent |
|-----------|-------|
| UI/Frontend | frontend-developer |
| API/Backend | backend-architect |
| Testing | tdd-orchestrator |
| Code Review | code-reviewer |
| Quality Checks | code-quality-enforcer |
| Debugging | debugger |
| Security | security-auditor |
| Design | pm:ui-designer |

## Linear Operations

The linear-operations agent is the central handler for all Linear API interactions. It provides significant token reduction through caching and batching.

### Key Benefits

- **50-60% token reduction** compared to direct MCP calls
- **85-95% cache hit rate** for teams, labels, statuses
- **Automatic parameter transformation** (handles issueId vs id)
- **Structured error handling** with suggestions

### Critical: Parameter Names

The Linear MCP uses specific parameter names that differ between operations:

| Tool | Parameter | Example |
|------|-----------|---------|
| `get_issue` | `id` | `{ id: "WORK-26" }` |
| `update_issue` | `id` | `{ id: "WORK-26", state: "..." }` |
| `create_comment` | `issueId` | `{ issueId: "WORK-26", body: "..." }` |
| `list_comments` | `issueId` | `{ issueId: "WORK-26" }` |
| `create_issue` | `team`, `title` | `{ team: "Engineering", title: "..." }` |

### Background Operations

For non-blocking updates, use background execution:

```bash
# Post comment (fire-and-forget)
./scripts/linear-background-ops.sh comment PSN-123 "Progress update"

# Update status (fire-and-forget)
./scripts/linear-background-ops.sh update-status PSN-123 "In Progress"
```

Use blocking calls only when you need the result:
- `get_issue` - Need the data to continue
- `create_issue` - Need the issue ID
- `update_checklist_items` - Need progress for display

## PM Operations Orchestrator

The pm-operations-orchestrator provides multi-PM system coordination with:

- **Lazy loading**: 89% token reduction vs eager loading
- **Parallel execution**: 50%+ speedup for independent operations
- **Dependency management**: Correct ordering of dependent operations
- **Unified caching**: Coordinated cache across all PM systems

### Operations

| Operation | Purpose |
|-----------|---------|
| `lazy_gather_context` | Gather context from multiple PM systems |
| `smart_delegate` | Route single operation to appropriate subagent |
| `batch_parallel_execute` | Execute multiple operations with dependencies |
| `cache_status` | Report unified cache metrics |

## Creating Agents

### Agent Structure

```markdown
# Agent Name

**Specialized agent for [specific domain]**

## Purpose

What this agent does and why.

## Capabilities

- Capability 1
- Capability 2

## Input Contract

```yaml
task:
  type: string
  description: string
context:
  issueId: string?
```

## Output Contract

```yaml
result:
  status: "success" | "partial" | "blocked"
  filesModified: string[]
  summary: string
```

## Implementation Patterns

Code examples and patterns.

## Integration with CCPM

How commands invoke this agent.

## Examples

Concrete usage examples.
```

### Registration

1. Create agent file in `agents/` directory
2. Add to `.claude-plugin/plugin.json` agents array:
   ```json
   {
     "agents": [
       "./agents/existing-agent.md",
       "./agents/new-agent.md"
     ]
   }
   ```
3. Optionally add to smart-agent-selector for auto-invocation

## Best Practices

### For Agent Design

- **Single responsibility**: Each agent handles one domain
- **Clear contracts**: Define explicit input/output YAML schemas
- **Implementation patterns**: Include code examples agents can follow
- **Error handling**: Return structured errors with suggestions
- **Examples**: Provide concrete usage examples

### For Agent Usage

- **Use Linear subagent**: Route all Linear operations through linear-operations
- **Delegate to specialists**: Use domain-specific agents rather than doing everything in main context
- **Provide context**: Include issue ID, branch, and relevant technical context
- **Handle errors**: Check result status and handle failures gracefully

### For Performance

- **Cache operations**: Leverage agent caching for repeated lookups
- **Background execution**: Use fire-and-forget for non-critical operations
- **Parallel tasks**: Use parallel Task calls for independent operations
- **Minimal context**: Keep prompts focused to reduce token usage

## Agent Communication

```
Commands
    │
    ├─> linear-operations (Linear API)
    │
    ├─> pm-operations-orchestrator
    │       ├─> linear-operations
    │       ├─> jira-operations
    │       └─> confluence-operations
    │
    ├─> Development Agents
    │       ├─> frontend-developer
    │       ├─> backend-architect
    │       ├─> tdd-orchestrator
    │       └─> ...
    │
    └─> Project Agents
            ├─> project-detector
            ├─> project-config-loader
            └─> project-context-manager
```

## Summary

| Category | Agent Count | Purpose |
|----------|-------------|---------|
| Linear/PM Operations | 4 | API operations with caching |
| Project Management | 3 | Project detection and context |
| Development | 7 | Implementation across domains |
| Design | 1 | UI/UX design assistance |
| CCPM Support | 3 | Claude Code and CCPM help |
| **Total** | **18** | |
