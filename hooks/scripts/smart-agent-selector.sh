#!/bin/bash
# Smart Agent Selector - Dynamic agent discovery with context-aware scoring
# This runs as a command-type hook on UserPromptSubmit

set -euo pipefail

# Get input from stdin (JSON with userMessage, conversationSummary, etc.)
INPUT=$(cat)

# Extract user message
USER_MESSAGE=$(echo "$INPUT" | jq -r '.userMessage // ""')

# Get plugin root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Discover all available agents (uses caching for speed)
if [ -f "$PLUGIN_ROOT/scripts/discover-agents-cached.sh" ]; then
    AVAILABLE_AGENTS=$("$PLUGIN_ROOT/scripts/discover-agents-cached.sh" 2>/dev/null || echo "[]")
else
    AVAILABLE_AGENTS=$("$PLUGIN_ROOT/scripts/discover-agents.sh" 2>/dev/null || echo "[]")
fi

# Count agents
AGENT_COUNT=$(echo "$AVAILABLE_AGENTS" | jq 'length')

# If no agents discovered, use static fallback
if [ "$AGENT_COUNT" -eq 0 ]; then
    AVAILABLE_AGENTS='[{"name":"general-purpose","type":"global","description":"General-purpose agent"}]'
    AGENT_COUNT=1
fi

# Output agent selection prompt with discovered agents
cat <<EOF
You are an intelligent agent selector for Claude Code with dynamic agent discovery.

## User Request
$USER_MESSAGE

## Available Agents (${AGENT_COUNT} discovered)
\`\`\`json
$AVAILABLE_AGENTS
\`\`\`

## Selection Strategy

### Task Classification
- **Planning/Design** → architect agents (backend-architect, frontend-developer)
- **Implementation** → TDD first (tdd-orchestrator), then dev agents
- **Bug Fix** → debugger
- **Review/Quality** → code-reviewer, security-auditor
- **Performance** → performance-engineer
- **Refactoring** → legacy-modernizer
- **Documentation** → skip agents (use Context7 MCP)

### Scoring Algorithm
Score each agent from the discovered list:
\`\`\`
score =
  + 10 * keyword_matches(user_request, agent.description)
  + 20 * task_type_match(task_type, agent.name)
  + 15 * tech_stack_match(context, agent.description)
  + 5  * (agent.type == 'plugin')
  + 25 * (agent.type == 'project')  // HIGHEST PRIORITY
\`\`\`

### Execution Planning
- **Sequential**: TDD → Implement → Review, Design → Implement
- **Parallel**: Independent work (frontend + backend), Final validation

### Selection Rules
1. Use EXACT agent names from the discovered list above
2. Prioritize: project agents (+25) > plugins (+5) > global (0)
3. Match tech stack to agent specialization
4. Limit to 1-3 agents (avoid over-invoking)
5. Skip agents for simple questions/documentation requests

## Decision

Analyze the request and respond with:

1. **Should agents be invoked?** (yes/no)
2. **If yes, which agents from the discovered list?**
3. **In what order?** (sequential or parallel)
4. **Why these agents?** (scoring reasoning)

Provide clear instructions on which agents to invoke and in what order.

For simple questions or documentation requests, respond that no agents are needed.
EOF

# Exit 0 to inject the prompt into Claude's context
exit 0
