#!/bin/bash
# discover-agents.sh - Dynamically discover all available Claude Code agents
# This script scans global plugins, project-specific agents, and built-in agents

set -euo pipefail

# Output format: JSON array of agent objects
# Each object: {"name": "agent-name", "type": "plugin|global|project", "description": "...", "path": "..."}

agents="[]"

# Function to add agent to JSON array
add_agent() {
    local name="$1"
    local type="$2"
    local description="$3"
    local path="$4"

    agents=$(echo "$agents" | jq --arg name "$name" --arg type "$type" --arg desc "$description" --arg path "$path" \
        '. += [{"name": $name, "type": $type, "description": $desc, "path": $path}]')
}

# 1. Discover Plugin Agents from installed_plugins.json
if [ -f ~/.claude/plugins/installed_plugins.json ]; then
    while IFS= read -r plugin; do
        plugin_name=$(echo "$plugin" | cut -d'@' -f1)
        plugin_path=$(jq -r ".plugins.\"$plugin\"[0].installPath" ~/.claude/plugins/installed_plugins.json 2>/dev/null || echo "")

        if [ -n "$plugin_path" ] && [ -d "$plugin_path" ]; then
            # Read plugin manifest for agents
            if [ -f "$plugin_path/plugin.json" ]; then
                # Extract agents from plugin.json
                agent_count=$(jq '.agents | length' "$plugin_path/plugin.json" 2>/dev/null || echo "0")

                for ((i=0; i<agent_count; i++)); do
                    agent_name=$(jq -r ".agents[$i].name" "$plugin_path/plugin.json" 2>/dev/null || echo "")
                    agent_desc=$(jq -r ".agents[$i].description" "$plugin_path/plugin.json" 2>/dev/null || echo "No description")

                    if [ -n "$agent_name" ]; then
                        add_agent "${plugin_name}:${agent_name}" "plugin" "$agent_desc" "$plugin_path"
                    fi
                done
            fi

            # Also scan for agent markdown files
            if [ -d "$plugin_path/agents" ]; then
                for agent_file in "$plugin_path/agents"/*.md; do
                    if [ -f "$agent_file" ]; then
                        agent_name=$(basename "$agent_file" .md)
                        # Extract description from first line or frontmatter
                        agent_desc=$(head -n 20 "$agent_file" | grep -E "^description:|^# " | head -1 | sed 's/^description: //; s/^# //' || echo "No description")
                        add_agent "${plugin_name}:${agent_name}" "plugin" "$agent_desc" "$agent_file"
                    fi
                done
            fi
        fi
    done < <(jq -r '.plugins | keys[]' ~/.claude/plugins/installed_plugins.json)
fi

# 2. Discover Built-in/Global Agents
# These are the standard Claude Code agents available globally
built_in_agents=(
    "general-purpose:General-purpose agent for researching complex questions and multi-step tasks"
    "Explore:Fast agent for exploring codebases, finding files, and searching code"
    "Plan:Planning agent for breaking down tasks and creating execution plans"
)

for agent_info in "${built_in_agents[@]}"; do
    agent_name="${agent_info%%:*}"
    agent_desc="${agent_info#*:}"
    add_agent "$agent_name" "global" "$agent_desc" "built-in"
done

# 3. Discover Project-Specific Agents
if [ -f ".claude/agents.json" ]; then
    project_agent_count=$(jq 'length' .claude/agents.json 2>/dev/null || echo "0")

    for ((i=0; i<project_agent_count; i++)); do
        agent_name=$(jq -r ".[$i].name" .claude/agents.json 2>/dev/null || echo "")
        agent_desc=$(jq -r ".[$i].description" .claude/agents.json 2>/dev/null || echo "No description")

        if [ -n "$agent_name" ]; then
            add_agent "$agent_name" "project" "$agent_desc" ".claude/agents.json"
        fi
    done
fi

# 4. Discover Local Agent Files in Project
if [ -d ".claude/agents" ]; then
    for agent_file in .claude/agents/*.md; do
        if [ -f "$agent_file" ]; then
            agent_name=$(basename "$agent_file" .md)
            agent_desc=$(head -n 20 "$agent_file" | grep -E "^description:|^# " | head -1 | sed 's/^description: //; s/^# //' || echo "No description")
            add_agent "$agent_name" "project" "$agent_desc" "$agent_file"
        fi
    done
fi

# Output final JSON
echo "$agents" | jq -c '.'
