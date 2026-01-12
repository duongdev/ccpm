# Work Loop State Helper

Helper functions for managing work loop state in the ralph-wiggum pattern implementation.

## State File Location

```
.claude/ccpm-work-loop.local.md
```

**Note**: This file is in `.claude/` directory to keep it separate from project files and is `.local.md` to indicate it's machine-specific state (like `.env.local`).

## State File Format

```yaml
---
issue_id: "WORK-26"
current_item_index: 0
total_items: 5
iteration: 1
max_iterations: 30
completion_promise: "ALL_ITEMS_COMPLETE"
started_at: "2026-01-12T10:00:00Z"
last_sync_at: "2026-01-12T10:15:00Z"
items_completed: []
blockers: []
branch: "feature/work-26-auth"
---

## Work Loop State
[Human-readable notes about current state]
```

## Helper Functions

### Check if Loop is Active

```javascript
function isWorkLoopActive() {
  const fs = require('fs');
  return fs.existsSync('.claude/ccpm-work-loop.local.md');
}
```

### Read State File

```javascript
function readWorkLoopState() {
  const fs = require('fs');
  const stateFile = '.claude/ccpm-work-loop.local.md';

  if (!fs.existsSync(stateFile)) {
    return null;
  }

  const content = fs.readFileSync(stateFile, 'utf-8');

  // Parse YAML frontmatter
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
  if (!frontmatterMatch) {
    return null;
  }

  const frontmatter = frontmatterMatch[1];
  const state = {};

  // Parse each field
  frontmatter.split('\n').forEach(line => {
    const match = line.match(/^(\w+):\s*"?([^"]*)"?$/);
    if (match) {
      const [, key, value] = match;
      // Convert numeric values
      if (/^\d+$/.test(value)) {
        state[key] = parseInt(value);
      } else if (value.startsWith('[')) {
        // Parse arrays
        try {
          state[key] = JSON.parse(value);
        } catch {
          state[key] = value;
        }
      } else {
        state[key] = value;
      }
    }
  });

  return state;
}
```

### Update State Field

```javascript
function updateWorkLoopState(field, value) {
  const fs = require('fs');
  const stateFile = '.claude/ccpm-work-loop.local.md';

  if (!fs.existsSync(stateFile)) {
    return false;
  }

  let content = fs.readFileSync(stateFile, 'utf-8');

  // Format value based on type
  let formattedValue;
  if (typeof value === 'string') {
    formattedValue = `"${value}"`;
  } else if (Array.isArray(value)) {
    formattedValue = JSON.stringify(value);
  } else {
    formattedValue = String(value);
  }

  // Replace field in frontmatter
  const regex = new RegExp(`^${field}:.*$`, 'm');
  if (content.match(regex)) {
    content = content.replace(regex, `${field}: ${formattedValue}`);
  }

  fs.writeFileSync(stateFile, content);
  return true;
}
```

### Increment Iteration

```javascript
function incrementIteration() {
  const state = readWorkLoopState();
  if (!state) return null;

  const newIteration = (state.iteration || 1) + 1;
  updateWorkLoopState('iteration', newIteration);
  updateWorkLoopState('last_sync_at', new Date().toISOString());

  return newIteration;
}
```

### Add Completed Item

```javascript
function addCompletedItem(itemIndex) {
  const state = readWorkLoopState();
  if (!state) return false;

  const completed = state.items_completed || [];
  if (!completed.includes(itemIndex)) {
    completed.push(itemIndex);
    updateWorkLoopState('items_completed', completed);
  }

  return true;
}
```

### Add Blocker

```javascript
function addBlocker(description) {
  const state = readWorkLoopState();
  if (!state) return false;

  const blockers = state.blockers || [];
  blockers.push({
    description,
    timestamp: new Date().toISOString()
  });
  updateWorkLoopState('blockers', blockers);

  return true;
}
```

### Clean Up State

```javascript
function cleanupWorkLoopState() {
  const fs = require('fs');
  const stateFile = '.claude/ccpm-work-loop.local.md';

  if (fs.existsSync(stateFile)) {
    fs.unlinkSync(stateFile);
    return true;
  }
  return false;
}
```

## Bash Helpers

### Check Loop Active

```bash
is_work_loop_active() {
  [[ -f ".claude/ccpm-work-loop.local.md" ]]
}
```

### Get State Field

```bash
get_work_loop_field() {
  local field="$1"
  local state_file=".claude/ccpm-work-loop.local.md"

  if [[ ! -f "$state_file" ]]; then
    echo ""
    return 1
  fi

  # Extract field value (handles both quoted and unquoted)
  sed -n "s/^${field}: \"\{0,1\}\([^\"]*\)\"\{0,1\}$/\1/p" "$state_file" | head -1
}
```

### Update State Field

```bash
update_work_loop_field() {
  local field="$1"
  local value="$2"
  local state_file=".claude/ccpm-work-loop.local.md"

  if [[ ! -f "$state_file" ]]; then
    return 1
  fi

  # Portable sed (macOS vs Linux)
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/^${field}: .*/${field}: ${value}/" "$state_file"
  else
    sed -i "s/^${field}: .*/${field}: ${value}/" "$state_file"
  fi
}
```

### Increment Iteration

```bash
increment_work_loop_iteration() {
  local current=$(get_work_loop_field "iteration")
  local new_iteration=$((current + 1))
  update_work_loop_field "iteration" "$new_iteration"
  echo "$new_iteration"
}
```

## Usage in Stop Hook

The stop hook uses these helpers to manage state:

```bash
#!/bin/bash
# In work-loop-stop-hook.sh

source "${CLAUDE_PLUGIN_ROOT}/helpers/work-loop-state.sh"

# Check if loop active
if ! is_work_loop_active; then
  echo '{"decision": "allow"}'
  exit 0
fi

# Get current state
ISSUE_ID=$(get_work_loop_field "issue_id")
ITERATION=$(get_work_loop_field "iteration")
MAX_ITERATIONS=$(get_work_loop_field "max_iterations")

# Check max iterations
if [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  cleanup_work_loop_state
  echo '{"decision": "allow"}'
  exit 0
fi

# Increment and continue
new_iteration=$(increment_work_loop_iteration)
# ... build and return continuation prompt
```

## Integration Points

### With /ccpm:work:loop Command

1. Command calls `setup-work-loop.sh` to create initial state
2. State tracks progress through checklist items
3. Each iteration updates `iteration` and `last_sync_at`

### With Stop Hook

1. Hook reads state to determine if loop active
2. Checks completion/blocker signals
3. Updates iteration count on continue
4. Removes state file on completion

### With /ccpm:cancel-work-loop Command

1. Reads state for summary display
2. Removes state file to stop loop
