#!/bin/bash
# Smart Agent Selector - Lightweight per-message hint
# Main context injected via SessionStart, this just adds task-specific hints
#
# NOTE: Full agent list and CCPM rules are injected once in SessionStart.
# This hook is now minimal to avoid context flooding.

set -euo pipefail

# Read input
INPUT=$(cat)
USER_MESSAGE=$(echo "$INPUT" | jq -r '.userMessage // ""' | tr '[:upper:]' '[:lower:]')

# Quick keyword detection for task-specific hints
HINT=""

# Linear-related keywords
if echo "$USER_MESSAGE" | grep -qE '(issue|linear|status|sync|checklist|work-|psn-|rpt-)'; then
    HINT="💡 Linear task detected → use \`ccpm:linear-operations\` agent"
fi

# Implementation keywords
if echo "$USER_MESSAGE" | grep -qE '(implement|build|create|add feature)'; then
    if echo "$USER_MESSAGE" | grep -qE '(component|ui|react|frontend|css)'; then
        HINT="💡 Frontend task → use \`ccpm:frontend-developer\` agent"
    elif echo "$USER_MESSAGE" | grep -qE '(api|endpoint|backend|database|resolver)'; then
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

# Output hint if detected (minimal context injection)
if [ -n "$HINT" ]; then
    echo "$HINT"
fi

exit 0
