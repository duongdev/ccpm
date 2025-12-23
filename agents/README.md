# CCPM Agents

**Specialized subagents for CCPM operations**

## Overview

CCPM uses a set of specialized agents to handle different aspects of project management and development workflows. These agents work together to provide intelligent automation and context-aware operations.

## Available Agents

### Core Operations

| Agent | Purpose | Usage |
|-------|---------|-------|
| [linear-operations.md](./linear-operations.md) | Central handler for all Linear MCP operations (50-60% token reduction) | Automatic via commands |
| [pm-operations-orchestrator.md](./pm-operations-orchestrator.md) | Tool-agnostic PM routing (Jira, Confluence, Linear) | Automatic via commands |
| [jira-operations.md](./jira-operations.md) | Jira API operations with session-level caching | Automatic when Jira configured |
| [confluence-operations.md](./confluence-operations.md) | Confluence API operations with Markdown transformation | Automatic when Confluence configured |
| [project-detector.md](./project-detector.md) | Automatically detects project context | Automatic on command execution |
| [project-config-loader.md](./project-config-loader.md) | Loads and validates project configuration | Automatic via project operations |
| [project-context-manager.md](./project-context-manager.md) | Manages active project context | Automatic via project operations |

### Development Agents (New in v1.1)

| Agent | Purpose | Usage |
|-------|---------|-------|
| [frontend-developer.md](./frontend-developer.md) | React/UI implementation with design system integration | Via `/ccpm:work` for UI tasks |
| [backend-architect.md](./backend-architect.md) | APIs, databases, authentication, NestJS | Via `/ccpm:work` for backend tasks |
| [tdd-orchestrator.md](./tdd-orchestrator.md) | Test-driven development workflow | Via `/ccpm:work` for test tasks |
| [code-reviewer.md](./code-reviewer.md) | Automated code review and quality assessment | Via `/ccpm:review` |
| [debugger.md](./debugger.md) | Systematic debugging and issue investigation | Via `/ccpm:work` for bug fixes |
| [security-auditor.md](./security-auditor.md) | Security vulnerability assessment | Via `/ccpm:review --security` |

### Specialized Agents

| Agent | Purpose | Usage |
|-------|---------|-------|
| [pm:ui-designer.md](./pm:ui-designer.md) | UI design and wireframe generation | `/ccpm:planning:design-ui` |

## Agent Architecture

### Linear Operations Subagent

The Linear operations subagent is the central handler for all Linear MCP operations, providing:

- **50-60% token reduction** through optimized prompts
- **Session-level caching** (85-95% hit rates)
- **Performance**: <50ms for cached operations
- **Structured error handling** with actionable suggestions
- **Automatic parameter transformation** (issueId → id)
- **Background execution** for non-blocking operations

**Key Features:**
- Issue management (create, update, fetch)
- Label operations with smart caching
- State management with fuzzy matching
- Team and project operations
- Comment and document management

**⛔ CRITICAL: Exact Parameter Names**

```javascript
// GET/UPDATE ISSUE - uses "id" (NOT issueId)
{ tool: "get_issue", args: { id: "WORK-26" } }
{ tool: "update_issue", args: { id: "WORK-26", state: "In Progress" } }

// COMMENTS - uses "issueId"
{ tool: "create_comment", args: { issueId: "WORK-26", body: "..." } }
{ tool: "list_comments", args: { issueId: "WORK-26" } }
```

| Tool | Parameter | NOT This |
|------|-----------|----------|
| `get_issue` | **`id`** | ~~issueId~~ |
| `update_issue` | **`id`** | ~~issueId~~ |
| `create_comment` | **`issueId`** | ~~id~~ |
| `list_comments` | **`issueId`** | ~~id~~ |

**Background Execution (Non-Blocking):**

```bash
# For comments and status updates (fire-and-forget)
./scripts/linear-background-ops.sh comment ${issueId} "Progress update"
./scripts/linear-background-ops.sh update-status ${issueId} "In Progress"
```

Use blocking calls only when you need the result (get_issue, create_issue).

**Documentation:**
- [Linear Subagent Architecture](../docs/architecture/decisions/002-linear-subagent.md)
- [API Reference](../docs/reference/api/linear-subagent-quick-reference.md)
- [Usage Patterns](../docs/reference/agents/usage-patterns.md)

### Project Management Agents

The project management agents work together to provide seamless multi-project support:

1. **Project Detector**: Automatically identifies which project you're working on
2. **Config Loader**: Loads project-specific configuration with validation
3. **Context Manager**: Maintains active project state across command executions

**Benefits:**
- Automatic project switching based on working directory
- Support for monorepo subdirectory detection
- Manual override capability
- Configuration validation and error reporting

**Documentation:**
- [Dynamic Project Configuration](../docs/architecture/patterns/dynamic-configuration.md)
- [Project Setup Guide](../docs/guides/getting-started/project-setup.md)
- [Monorepo Workflow](../docs/guides/workflows/monorepo-workflow.md)

### UI Designer Agent

The UI designer agent provides intelligent design assistance:

- Generates multiple design options from requirements
- Creates ASCII wireframes for visualization
- Integrates with Figma for design handoff
- Produces comprehensive developer specifications

**Usage:**
```bash
/ccpm:planning:design-ui PSN-123
```

**Documentation:**
- [UI Design Workflow](../docs/guides/workflows/ui-design-workflow.md)
- [Design Commands](../docs/reference/commands/planning.md#design-commands)

## How Agents Work

### Invocation Methods

**1. Automatic Invocation** (via hooks)
- Smart agent selector hook analyzes context
- Scores agents based on relevance
- Automatically invokes best-fit agents

**2. Explicit Invocation** (via Task tool)
```typescript
Task('linear-operations', 'operation: get_issue, params: {...}')
```

**3. Command Delegation** (internal)
- Commands delegate to appropriate agents
- Agents handle specialized operations
- Results returned to command

### Agent Communication

Agents communicate via:
- **Direct invocation**: Commands → Agents
- **Subagent delegation**: Agents → Sub-agents
- **Shared helpers**: Common utilities in `commands/_shared-*.md`
- **Linear subagent**: Centralized Linear operations

### Caching Strategy

Agents use multi-level caching:
- **Session cache**: In-memory for current session (85-95% hit rate)
- **Operation cache**: Results cached by operation type
- **Invalidation**: Smart cache invalidation on writes

## Adding New Agents

To add a new agent:

1. **Create agent file**: `agents/your-agent.md`
2. **Define capabilities**: Clear description of what the agent does
3. **Implement logic**: Step-by-step instructions for the agent
4. **Add to catalog**: Update this README
5. **Test thoroughly**: Ensure agent works in isolation and with others

**Template:**
See [Subagent Template](../docs/templates/subagent-template.md) for standard structure.

**Documentation:**
- [Creating Agents Guide](../docs/development/guides/subagent-integration.md)
- [Agent Patterns](../docs/architecture/patterns/agent-patterns.md)

## Best Practices

### For Agent Developers

- ✅ Keep agents focused on single responsibility
- ✅ Use Linear subagent for all Linear operations
- ✅ Implement proper error handling
- ✅ Document all parameters and return values
- ✅ Provide usage examples
- ✅ Use shared helpers when appropriate

### For Command Developers

- ✅ Delegate to agents rather than direct MCP calls
- ✅ Use Linear subagent for caching benefits
- ✅ Handle agent errors gracefully
- ✅ Provide context in agent invocations
- ✅ Test agent integration thoroughly

## Related Documentation

- [Agent Catalog](../docs/reference/agents/catalog.md) - Complete agent reference
- [Usage Patterns](../docs/reference/agents/usage-patterns.md) - Common patterns
- [Smart Agent Selection](../hooks/SMART_AGENT_SELECTION.md) - Automatic selection
- [Architecture Decisions](../docs/architecture/decisions/) - Design rationale

---

**Last updated:** 2025-12-23
**Agent count:** 14 agents (7 core + 6 development + 1 specialized)
**Documentation version:** 1.1.0
