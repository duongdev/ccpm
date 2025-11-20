# Linear Helpers Implementation Notes

**For**: Maintainers and contributors modifying _shared-linear-helpers.md
**Updated**: 2025-11-20
**Subject**: Implementation details of subagent delegation layer

---

## Architecture Overview

### Delegation Pattern

The _shared-linear-helpers.md file implements a **delegation layer** pattern:

```
┌─────────────────────────────────────────────┐
│         CCPM Commands (40+)                 │
│  Call: getOrCreateLabel(), getValidStateId()│
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│  Shared Linear Helpers (Delegation Layer)   │
│  ├─ getOrCreateLabel()                      │
│  ├─ getValidStateId()                       │
│  ├─ ensureLabelsExist()                     │
│  └─ getDefaultColor()                       │
└──────────────────┬──────────────────────────┘
                   │
        Task('linear-operations')
                   │
┌──────────────────▼──────────────────────────┐
│   Linear Operations Subagent                │
│  ├─ get_or_create_label                    │
│  ├─ get_valid_state_id                     │
│  ├─ ensure_labels_exist                    │
│  ├─ create_issue                           │
│  ├─ update_issue                           │
│  └─ ...18 total operations                 │
└──────────────────┬──────────────────────────┘
                   │
    MCP Linear API + Session Cache
                   │
┌──────────────────▼──────────────────────────┐
│      Linear MCP Server + Linear API         │
└─────────────────────────────────────────────┘
```

---

## Function Implementation Details

### 1. getOrCreateLabel Implementation

```javascript
async function getOrCreateLabel(teamId, labelName, options = {}) {
  // Step 1: Build YAML request
  const yamlRequest = `
operation: get_or_create_label
params:
  team: ${teamId}
  name: ${labelName}
  ${options.color ? `color: ${options.color}` : ''}
  ${options.description ? `description: ${options.description}` : ''}
context:
  command: "shared-helpers"
  purpose: "Ensuring label exists for workflow"
`;

  // Step 2: Invoke subagent via Task tool
  const result = await Task('linear-operations', yamlRequest);

  // Step 3: Check success flag
  if (!result.success) {
    throw new Error(
      `Failed to get/create label '${labelName}': ${result.error?.message || 'Unknown error'}`
    );
  }

  // Step 4: Parse result and return in original format
  return {
    id: result.data.id,
    name: result.data.name
  };
}
```

**Key Points**:
- YAML request must have exact operation name: `get_or_create_label`
- Parameters map to subagent schema
- Conditional parameters (color, description) only included if provided
- Result checking: Always check `result.success` before accessing data
- Return format must match original function signature

---

### 2. getValidStateId Implementation

```javascript
async function getValidStateId(teamId, stateNameOrType) {
  // Step 1: Build YAML request
  const yamlRequest = `
operation: get_valid_state_id
params:
  team: ${teamId}
  state: ${stateNameOrType}
context:
  command: "shared-helpers"
  purpose: "Resolving workflow state"
`;

  // Step 2: Invoke subagent
  const result = await Task('linear-operations', yamlRequest);

  // Step 3: Handle errors with enhanced messaging
  if (!result.success) {
    // Extract helpful error information from subagent response
    const suggestions = result.error?.suggestions || [];
    const availableStates = result.error?.details?.available_statuses || [];

    let errorMsg = `Invalid state: "${stateNameOrType}"\n\n`;

    if (availableStates.length > 0) {
      errorMsg += `Available states for this team:\n`;
      availableStates.forEach(s => {
        errorMsg += `  - ${s.name} (type: ${s.type})\n`;
      });
      errorMsg += '\n';
    }

    if (suggestions.length > 0) {
      errorMsg += `Suggestions:\n`;
      suggestions.forEach(s => {
        errorMsg += `  - ${s}\n`;
      });
    }

    throw new Error(errorMsg);
  }

  // Step 4: Return state ID only for backward compatibility
  return result.data.id;
}
```

**Key Points**:
- Error response includes structured error information
- Suggestions array comes directly from subagent
- Available states extracted from error.details.available_statuses
- Only return the ID, not full state object (backward compatibility)

---

### 3. ensureLabelsExist Implementation

```javascript
async function ensureLabelsExist(teamId, labelNames, options = {}) {
  const colors = options.colors || {};
  const descriptions = options.descriptions || {};

  // Step 1: Build label definition array
  const labelDefs = labelNames.map(name => {
    const def = { name };
    if (colors[name]) def.color = colors[name];
    // Note: subagent auto-assigns color from getDefaultColor if not provided
    return def;
  });

  // Step 2: Build YAML request with label array
  const yamlRequest = `
operation: ensure_labels_exist
params:
  team: ${teamId}
  labels:
    ${labelDefs.map(l => `- name: ${l.name}${l.color ? `\n      color: ${l.color}` : ''}`).join('\n    ')}
context:
  command: "shared-helpers"
  purpose: "Ensuring workflow labels exist"
`;

  // Step 3: Invoke subagent
  const result = await Task('linear-operations', yamlRequest);

  // Step 4: Error handling
  if (!result.success) {
    throw new Error(
      `Failed to ensure labels exist: ${result.error?.message || 'Unknown error'}`
    );
  }

  // Step 5: Return label names in original format
  return result.data.labels.map(l => l.name);
}
```

**Key Points**:
- Constructs YAML array of label definitions
- Colors are optional - subagent uses getDefaultColor() if missing
- Response contains labels array with creation status
- Return type: string[] (matches original function)

---

### 4. getDefaultColor Implementation

```javascript
function getDefaultColor(labelName) {
  const colorMap = {
    // CCPM Workflow stages
    'planning': '#f7c8c1',           // Light coral
    'implementation': '#26b5ce',      // Cyan
    'verification': '#f2c94c',        // Yellow
    'pr-review': '#5e6ad2',          // Indigo
    'done': '#4cb782',               // Green
    // ... 20+ more colors
  };

  const normalized = labelName.toLowerCase().trim();
  return colorMap[normalized] || '#95a2b3'; // Default gray
}
```

**Key Points**:
- Pure function - no delegation or async calls
- Case-insensitive lookup
- Returns default gray (#95a2b3) for unknown labels
- Used by getOrCreateLabel when color not specified

---

## YAML Contract Details

### Operation Names

These must match exactly what the subagent expects:

- `get_or_create_label` (not getOrCreateLabel or create_label)
- `get_valid_state_id` (not getValidStateId or validate_state)
- `ensure_labels_exist` (not ensureLabels or batch_labels)

### Parameter Mapping

**getOrCreateLabel**:
```yaml
params:
  team: string              # Team name, key, or ID
  name: string              # Label name
  color: string (optional)  # Hex color code
  description: string (optional)
```

**getValidStateId**:
```yaml
params:
  team: string              # Team name, key, or ID
  state: string             # State name, type, or alias
```

**ensureLabelsExist**:
```yaml
params:
  team: string              # Team name, key, or ID
  labels: array            # Array of {name, color?}
    - name: string
      color: string (optional)
```

### Context Field

All operations should include context:
```yaml
context:
  command: "shared-helpers"     # Identifies caller
  purpose: "Human-readable purpose"
```

---

## Error Handling Patterns

### Success Path

```javascript
const result = await Task('linear-operations', yamlRequest);

if (!result.success) {
  // Handle error (see below)
  throw new Error(...);
}

// Access data safely
const { id, name } = result.data;
```

### Error Path

```javascript
const result = await Task('linear-operations', yamlRequest);

if (!result.success) {
  // result.error structure:
  // {
  //   code: "ERROR_CODE",
  //   message: "Human readable message",
  //   details: { /* operation-specific details */ },
  //   suggestions: [/* helpful suggestions */]
  // }

  const errorMsg = result.error?.message || 'Unknown error';
  const suggestions = result.error?.suggestions || [];

  // Format error message with suggestions
  let fullMsg = `Operation failed: ${errorMsg}`;
  if (suggestions.length > 0) {
    fullMsg += `\n\nSuggestions:\n${suggestions.map(s => `  - ${s}`).join('\n')}`;
  }

  throw new Error(fullMsg);
}
```

### Metadata

All responses include metadata:
```yaml
metadata:
  cached: boolean           # true if result came from cache
  duration_ms: number       # Total execution time
  mcp_calls: number         # Number of Linear MCP calls made
  operations: string[]      # Detailed operation log (optional)
```

---

## Testing Strategies

### Unit Test Pattern

```javascript
// Test getOrCreateLabel
const result = await getOrCreateLabel("TEAM-123", "test-label");
assert.equal(result.id, "label-456");
assert.equal(result.name, "test-label");

// Test getValidStateId
const stateId = await getValidStateId("TEAM-123", "In Progress");
assert.equal(stateId, "state-789");

// Test ensureLabelsExist
const labels = await ensureLabelsExist("TEAM-123", ["label1", "label2"]);
assert.deepEqual(labels, ["label1", "label2"]);

// Test getDefaultColor
const color = getDefaultColor("planning");
assert.equal(color, "#f7c8c1");
```

### Error Test Pattern

```javascript
// Test invalid state error
try {
  await getValidStateId("TEAM-123", "invalid-state");
  assert.fail("Should have thrown");
} catch (error) {
  assert(error.message.includes("Invalid state"));
  assert(error.message.includes("Available states"));
}

// Test with suggestions
try {
  await getOrCreateLabel("INVALID-TEAM", "label");
  assert.fail("Should have thrown");
} catch (error) {
  assert(error.message.includes("Failed"));
}
```

### Integration Test Pattern

```javascript
// Test with real team/labels
const teamId = "engineering-team-id";

// Should create new label
const newLabel = await getOrCreateLabel(teamId, "unique-test-label-" + Date.now());
assert(newLabel.id);

// Should reuse existing label
const existingLabel = await getOrCreateLabel(teamId, newLabel.name);
assert.equal(existingLabel.id, newLabel.id);

// Should validate real states
const stateId = await getValidStateId(teamId, "In Progress");
assert(stateId);
```

---

## Performance Considerations

### Caching Benefits

When calling same operation twice in a command:

```javascript
// First call: ~400-500ms (API call)
const label1 = await getOrCreateLabel(teamId, "planning");

// Second call: ~25-50ms (cache hit)
const label2 = await getOrCreateLabel(teamId, "planning");

// Combined with other ops: 85%+ cache hit rate
const state = await getValidStateId(teamId, "done");  // Cache hit
const labels = await ensureLabelsExist(teamId, [...]);  // 2-3 cache hits
```

### Optimization Tips

1. **Reuse team identifiers**: Same team name = better cache hit
2. **Batch operations**: Use ensureLabelsExist instead of loop of getOrCreateLabel
3. **Group by team**: Process all operations for one team before another
4. **Check metadata.cached**: Verify caching is working as expected

---

## Maintenance Procedures

### When Subagent API Changes

1. **Check subagent definition** at `/agents/linear-operations.md`
2. **Update YAML contracts** in function implementations
3. **Update parameter documentation** in code comments
4. **Test with subagent changes** before deploying
5. **Update documentation** if behavior changes

### When Adding New Functions

```javascript
async function newHelper(teamId, param) {
  const yamlRequest = `
operation: subagent_operation_name
params:
  team: ${teamId}
  param: ${param}
context:
  command: "shared-helpers"
  purpose: "Description of what this does"
`;

  const result = await Task('linear-operations', yamlRequest);

  if (!result.success) {
    throw new Error(`Operation failed: ${result.error?.message}`);
  }

  // Transform result to match expected return type
  return transformResult(result.data);
}
```

**Checklist**:
- [ ] Function signature follows existing patterns
- [ ] YAML request well-formed
- [ ] Success check before accessing data
- [ ] Error handling with helpful messages
- [ ] Return value matches documented type
- [ ] Usage examples provided
- [ ] Documented in "Functions" section

### When Updating Existing Functions

1. **Preserve function signature** - No breaking changes
2. **Update YAML contracts only** - Don't change logic
3. **Test backward compatibility** - Existing calls must work
4. **Update examples** if behavior changes
5. **Document changes** in function JSDoc

---

## Debug Tips

### Problem: Response parsing fails

**Solution**: Check YAML formatting
```javascript
// Good: Well-formed YAML
const yaml = `
operation: get_or_create_label
params:
  team: ${teamId}
  name: ${labelName}
context:
  command: "shared-helpers"
`;

// Bad: Malformed YAML
const yaml = `operation: get_or_create_label, params: ...`;
```

### Problem: Cache not working

**Solution**: Check cache metadata
```javascript
const result = await Task('linear-operations', yaml);
console.log(result.metadata.cached);  // Should be true
console.log(result.metadata.mcp_calls);  // Should be 0 if cached
```

### Problem: Error not formatted correctly

**Solution**: Check error structure
```javascript
if (!result.success) {
  // Correct error checking
  const suggestions = result.error?.suggestions || [];
  const message = result.error?.message || 'Unknown error';

  // Don't assume fields exist - use optional chaining
  const details = result.error?.details?.available_statuses || [];
}
```

### Problem: State not found

**Solution**: Check fuzzy matching
```javascript
// These all should work (subagent handles fuzzy matching):
await getValidStateId(teamId, "In Progress");  // Exact name match
await getValidStateId(teamId, "started");      // Type match
await getValidStateId(teamId, "todo");         // Alias match
await getValidStateId(teamId, "in progress");  // Case-insensitive match
```

---

## Backward Compatibility Guarantees

### Maintained

- [ ] Function names: getOrCreateLabel, getValidStateId, ensureLabelsExist, getDefaultColor
- [ ] Function signatures: Parameters and order unchanged
- [ ] Return types: Same as before refactoring
- [ ] Error types: Still throws Error on failure
- [ ] Behavior: Same functionality, same results
- [ ] Side effects: Same logging and tracing

### Not Maintained

- Implementation details (direct MCP calls now delegated)
- Internal timing (may be slightly different due to caching)
- Error message wording (now includes subagent suggestions)
- Metadata format (now includes subagent metadata)

---

## Known Limitations

1. **Session-scoped caching**: Cache cleared between command executions
2. **No cross-command cache**: Can't leverage cache from previous commands
3. **Async only**: All functions must be awaited
4. **Task tool required**: Depends on Claude Code Task tool availability
5. **Subagent must be available**: Requires linear-operations subagent to be registered

---

## Future Improvements

1. **Extended caching**: Consider cross-session caching if performance needed
2. **Metrics tracking**: Log cache hit rates for monitoring
3. **Prefetching**: Proactively fetch common label/state combinations
4. **Compression**: Reduce YAML payload size for very long label lists
5. **Batch operations**: Consider allowing multiple operations in single request

---

## Related Files

- **Helper Functions**: `/commands/_shared-linear-helpers.md`
- **Subagent Definition**: `/agents/linear-operations.md`
- **Migration Guide**: `/docs/guides/LINEAR_SUBAGENT_MIGRATION.md`
- **Refactoring Summary**: `/docs/development/REFACTORING_SUMMARY_PSN29_GROUP3.md`

---

**Last Updated**: 2025-11-20
**Maintainer**: CCPM Development Team
**Status**: Active - Subagent delegation layer fully operational
