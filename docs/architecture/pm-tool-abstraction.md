# PM Tool Abstraction Layer Architecture

## Overview

CCPM uses a **tool-agnostic abstraction layer** to support ANY external PM/collaboration tool via MCP servers. This architecture preserves extensibility while keeping the core CCPM workflow commands lean and focused.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    CCPM Commands Layer                       │
│  (/ccpm:plan, /ccpm:work, /ccpm:sync, /ccpm:commit, etc.)   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              pm-operations-orchestrator Agent                │
│         (Tool-agnostic operation routing & safety)          │
└──────────────────────┬──────────────────────────────────────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
    ┌─────────┐  ┌─────────┐  ┌──────────┐
    │ Linear  │  │  Jira   │  │Confluence│
    │Operations│ │Operations│ │Operations│
    │ Subagent│  │ Subagent│  │ Subagent │
    └────┬────┘  └────┬────┘  └────┬─────┘
         │            │            │
         ▼            ▼            ▼
    ┌─────────┐  ┌─────────┐  ┌──────────┐
    │ Linear  │  │  Jira   │  │Confluence│
    │   MCP   │  │   MCP   │  │   MCP    │
    └─────────┘  └─────────┘  └──────────┘
```

## Core Components

### 1. CCPM Commands Layer

**Purpose**: User-facing workflow commands that orchestrate the complete development lifecycle.

**Core Commands** (11 total):
- `/ccpm:plan` - Create and plan tasks
- `/ccpm:work` - Start or resume work
- `/ccpm:sync` - Save progress to Linear
- `/ccpm:commit` - Git commit with Linear integration
- `/ccpm:verify` - Quality checks and verification
- `/ccpm:done` - Finalize task and create PR
- `/ccpm:project:*` - Project configuration (5 commands)

**Characteristics**:
- Tool-agnostic interface
- Focus on developer workflow
- Delegate to orchestrator for external integrations

### 2. pm-operations-orchestrator Agent

**Location**: `agents/pm-operations-orchestrator.md`

**Purpose**: Central routing and safety layer for all external PM operations.

**Key Responsibilities**:

1. **Tool Detection**
   - Reads project configuration (`~/.claude/ccpm-config.yaml`)
   - Determines which external tools are configured
   - Routes operations to appropriate tool-specific subagents

2. **Safety Enforcement**
   - Applies SAFETY_RULES.md universally
   - Blocks external writes without confirmation
   - Allows all read operations
   - Manages Linear operations (internal tracking)

3. **Generic Operation Interface**
   - `create_issue(project, title, description)` → Routes to configured tool
   - `update_issue(issueId, changes)` → Routes to configured tool
   - `add_comment(issueId, body)` → Routes to configured tool
   - `fetch_issue(issueId)` → Routes to configured tool
   - And more...

4. **Error Handling & Fallbacks**
   - Graceful degradation if tool unavailable
   - Standardized error messages
   - Suggestions for missing MCP servers

**Example Flow**:
```yaml
Command: /ccpm:plan "Add auth" my-app
   ↓
pm-operations-orchestrator:
  - Reads ~/.claude/ccpm-config.yaml
  - Finds: my-app uses Jira + Confluence
  - Routes to: jira-operations.create_issue()
  - Safety check: External write → requires confirmation
  - User confirms → Proceeds
   ↓
jira-operations subagent:
  - Formats request for Jira MCP
  - Calls: jira-mcp.create_issue()
  - Returns: Jira ticket ID
   ↓
pm-operations-orchestrator:
  - Creates corresponding Linear issue
  - Links Jira ticket in description
  - Returns: Both Jira + Linear IDs
```

### 3. Tool-Specific Subagents

**Current Implementations**:
- `agents/linear-operations.md` - Linear API via MCP (50-60% token reduction)
- `agents/jira-operations.md` - Jira API via MCP
- `agents/confluence-operations.md` - Confluence API via MCP

**Removed** (v1.0 simplification):
- `agents/bitbucket-operations.md` - BitBucket integration (removed)
- `agents/slack-operations.md` - Slack integration (removed)

**Pattern for New Tools**:

Each subagent provides:

1. **Standard Operations**
   - create_issue
   - update_issue
   - get_issue
   - add_comment
   - list_issues
   - search_issues

2. **Tool-Specific Operations**
   - Jira: transition_issue, link_issues, add_attachment
   - Confluence: create_page, update_page, get_page
   - Linear: update_checklist_items, get_or_create_label

3. **Session-Level Caching** (like Linear subagent)
   - Cache team/project/label metadata
   - 85-95% cache hit rate
   - 50-60% token reduction

4. **Structured Error Handling**
   - Standardized error codes
   - Actionable suggestions
   - Graceful degradation

**Creating a New Tool Integration**:

```markdown
# agents/[tool]-operations.md

## Purpose
Handle all [Tool] operations via [Tool] MCP server.

## Operations

### create_issue
... standard interface ...

### update_issue
... standard interface ...

## Caching Strategy
... tool-specific caching ...

## Error Handling
... tool-specific errors ...
```

Then add to project config:
```yaml
projects:
  my-app:
    external_pm:
      issue_tracking: [tool]
```

No changes needed to CCPM commands!

## Configuration-Driven Tool Selection

**Project Configuration** (`~/.claude/ccpm-config.yaml`):

```yaml
projects:
  acme-platform:
    name: "Acme Platform"
    external_pm:
      issue_tracking: jira
      documentation: confluence
      # code_hosting: bitbucket  # Removed in v1.0
      # team_chat: slack         # Removed in v1.0
    jira:
      project_key: "ACME"
      base_url: "https://acme.atlassian.net"
    confluence:
      space_key: "ACME"

  open-source-lib:
    name: "Open Source Library"
    external_pm:
      issue_tracking: github
      # No external documentation or chat
    github:
      repo: "user/repo"
```

**Tool Detection Logic** (in pm-operations-orchestrator):

```javascript
const projectConfig = loadProjectConfig(projectId);

const issueTracker = projectConfig.external_pm?.issue_tracking || 'none';

if (issueTracker === 'jira') {
  // Route to jira-operations subagent
  await invokeSubagent('jira-operations', operation, params);
} else if (issueTracker === 'github') {
  // Route to github-operations subagent
  await invokeSubagent('github-operations', operation, params);
} else if (issueTracker === 'linear') {
  // Route to linear-operations subagent (default)
  await invokeSubagent('linear-operations', operation, params);
} else {
  // No external tracker configured
  console.log('No external issue tracker configured. Using Linear only.');
  await invokeSubagent('linear-operations', operation, params);
}
```

## Safety Rules Application

**Universal Principles** (from `commands/SAFETY_RULES.md`):

1. **All external writes require confirmation**
   - Issue trackers (Jira, GitHub Issues, Azure DevOps, etc.)
   - Documentation systems (Confluence, Notion, SharePoint, etc.)
   - Team communication (Slack, Teams, Discord, etc.)
   - Code hosting writes (BitBucket, GitLab, etc.)

2. **All reads are allowed**
   - Fetching tickets/issues
   - Searching documentation
   - Viewing PRs and commits
   - Searching messages

3. **Linear is internal**
   - Linear operations are always allowed
   - Confirm only for bulk operations

**Implementation** (in pm-operations-orchestrator):

```javascript
function enforceConfirmation(operation, tool) {
  // Linear is internal - no confirmation needed (except bulk)
  if (tool === 'linear') {
    if (operation.isBulk) return confirmRequired;
    return allowWithoutConfirmation;
  }

  // All external tools follow same rules
  if (operation.isWrite) {
    return confirmRequired;
  }

  return allowWithoutConfirmation;
}
```

## Benefits of This Architecture

### 1. Extensibility

- **Add new tools** without modifying core commands
- **Configure per project** which tools to use
- **Dynamic MCP server** detection and routing

### 2. Maintainability

- **Centralized safety** logic in orchestrator
- **Tool-specific complexity** isolated in subagents
- **Clear boundaries** between layers

### 3. Performance

- **Session-level caching** in subagents (like Linear)
- **Batch operations** when possible
- **50-60% token reduction** with proper caching

### 4. Developer Experience

- **Consistent interface** across all tools
- **Graceful fallbacks** if tools unavailable
- **Clear error messages** with actionable suggestions

## Migration Path

### From Hardcoded to Abstracted

**Before (v0.x)**:
```javascript
// Command directly calls Jira MCP
const jiraIssue = await jira_mcp.create_issue({
  project: 'PROJ',
  summary: title
});
```

**After (v1.0+)**:
```javascript
// Command delegates to orchestrator
const issue = await pmOrchestrator.create_issue({
  projectId: 'my-app',
  title: title,
  description: description
});

// Orchestrator routes based on config:
// - If my-app uses Jira → jira-operations subagent
// - If my-app uses GitHub → github-operations subagent
// - Otherwise → linear-operations subagent (default)
```

### Adding a New Tool

1. **Create subagent**: `agents/[tool]-operations.md`
2. **Implement standard operations**: create_issue, update_issue, etc.
3. **Add to project config**: Update `~/.claude/ccpm-config.yaml`
4. **Update orchestrator routing**: Add tool detection logic
5. **Test with existing commands**: All commands work automatically!

## Future Enhancements

### Dynamic MCP Server Discovery

**Current**: Hardcoded routing in orchestrator

**Future**: Auto-discover MCP servers and capabilities

```javascript
const availableServers = await mcp.listServers();
const jiraServer = availableServers.find(s => s.name === 'jira');

if (jiraServer && jiraServer.capabilities.includes('create_issue')) {
  // Use this server
}
```

### Tool-Agnostic Commands

**Vision**: Commands that work with ANY PM tool

```javascript
/ccpm:plan "Add feature" my-app
// Works with Jira, GitHub, Azure DevOps, Linear, or any other tool
// Orchestrator handles all routing and formatting
```

### Community Tool Integrations

**Enable users to**:
- Create custom tool integrations
- Share via marketplace
- Install via `/ccpm:tools:install [tool]`

## Summary

CCPM's abstraction layer architecture provides:

✅ **Tool-agnostic** workflow commands
✅ **Extensible** integration pattern
✅ **Safe** external operations
✅ **Fast** with session-level caching
✅ **Maintainable** clear separation of concerns

This design allows CCPM to support ANY external PM tool while keeping the core workflow lean, fast, and focused on developer productivity.
