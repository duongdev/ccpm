#!/bin/bash
# Smart Agent Selector - Lightweight per-message hint
# Main context injected via SessionStart, this just adds task-specific hints
#
# NOTE: Full agent list and CCPM rules are injected once in SessionStart.
# This hook is now minimal to avoid context flooding.

set -euo pipefail

# Hook logging function
HOOK_LOG_FILE="/tmp/ccpm-hooks.log"
hook_log() {
    local hook_name="$1"
    local message="$2"
    local timestamp=$(date +"%H:%M:%S")
    echo "${timestamp} [${hook_name}] ${message}" >> "$HOOK_LOG_FILE"
    echo "${timestamp} [${hook_name}] ${message}" >&2
}

# Read input
INPUT=$(cat)
USER_MESSAGE=$(echo "$INPUT" | jq -r '.userMessage // ""' | tr '[:upper:]' '[:lower:]')

# Quick keyword detection for task-specific hints
HINT=""

# Explore agent (codebase analysis) - ALWAYS suggest first for exploration tasks
if echo "$USER_MESSAGE" | grep -qE '(find|search|where is|how does|what is|explore|understand|analyze|pattern|structure|architecture)'; then
    HINT="💡 Codebase analysis → use \`Explore\` agent (core, always available)"
fi

# Linear-related keywords
if echo "$USER_MESSAGE" | grep -qE '(issue|linear|status|sync|checklist|work-|psn-|rpt-)'; then
    HINT="💡 Linear task detected → use \`ccpm:linear-operations\` agent"
fi

# Implementation keywords
if echo "$USER_MESSAGE" | grep -qE '(implement|build|create|add|make|write)'; then
    if echo "$USER_MESSAGE" | grep -qE '(component|ui|react|frontend|css|page|screen|layout)'; then
        HINT="💡 Frontend task → use \`ccpm:frontend-developer\` agent"
    elif echo "$USER_MESSAGE" | grep -qE '(api|endpoint|backend|database|resolver|service|server)'; then
        HINT="💡 Backend task → use \`ccpm:backend-architect\` agent"
    fi
fi

# Debug keywords
if echo "$USER_MESSAGE" | grep -qE '(bug|error|fix|broken|not working|debug)'; then
    HINT="💡 Debug task → use \`ccpm:debugger\` agent"
fi

# Review keywords
if echo "$USER_MESSAGE" | grep -qE '(review|check.*(code|quality))'; then
    HINT="💡 Review task → use \`ccpm:code-reviewer\` agent"
fi

# Claude Code guide keywords
if echo "$USER_MESSAGE" | grep -qE '(how.*(hook|skill|mcp|claude code)|what is (mcp|hook)|claude code.*(setting|feature|config)|slash command)'; then
    HINT="💡 Claude Code question → use \`ccpm:claude-code-guide\` agent"
fi

# CCPM developer keywords
if echo "$USER_MESSAGE" | grep -qE '(create.*(command|agent|skill|hook)|add.*(ccpm|agent)|extend ccpm|new ccpm)'; then
    HINT="💡 CCPM extension → use \`ccpm:ccpm-developer\` agent"
fi

# CCPM troubleshooter keywords
if echo "$USER_MESSAGE" | grep -qE '(hook.*(not|fail|error)|agent.*(not|fail|error)|mcp.*(not|fail|error)|ccpm.*(broken|debug|issue))'; then
    HINT="💡 CCPM troubleshooting → use \`ccpm:ccpm-troubleshooter\` agent"
fi

# Output hint if detected (minimal context injection)
if [ -n "$HINT" ]; then
    echo "$HINT"
    hook_log "smart-agent-selector" "✓ Hint: ${HINT}"
fi

exit 0
