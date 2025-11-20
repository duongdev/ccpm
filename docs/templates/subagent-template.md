# Subagent Documentation Template

This template should be used for all subagent files in `agents/`.

---

```markdown
---
title: Subagent Name
type: [core|project-management|specialized]
version: X.Y
status: [stable|beta|experimental]
capabilities:
  - capability-1
  - capability-2
dependencies:
  - mcp-server-name
  - other-subagent (if any)
token_budget: X,XXX tokens (average)
---

# [Subagent Name]

**[One-line description of what this subagent does]**

## Purpose

[2-3 paragraphs explaining:
1. Primary purpose of this subagent
2. Problem it solves
3. When to use it vs alternatives]

## Capabilities

**This subagent can:**

- ✅ **Capability 1** - Description of what it can do
- ✅ **Capability 2** - Description of what it can do
- ✅ **Capability 3** - Description of what it can do
- ⚡ **Performance feature** - Special capability
- 🔒 **Safety feature** - Safety guarantee

**This subagent cannot:**

- ❌ Limitation 1
- ❌ Limitation 2

## Architecture

### Design Overview

[Explain the design of this subagent]

**Architecture Pattern:** [Pattern name - e.g., "Session-level caching with MCP delegation"]

**Flow Diagram:**
```
Caller → Subagent → [Processing] → MCP → External System
            ↓
       [Caching Layer] (if applicable)
            ↓
       [Error Handler]
            ↓
       [Response Formatter]
```

### Components

**1. Input Validator**
- Purpose: [What it validates]
- Rules: [Validation rules]

**2. Operation Router**
- Purpose: [How it routes requests]
- Operations: [List of supported operations]

**3. Caching Layer** (if applicable)
- Purpose: [What it caches and why]
- Strategy: [Caching strategy]
- Invalidation: [When cache is cleared]

**4. MCP Integration**
- Purpose: [How it integrates with MCP]
- Operations: [MCP operations used]

**5. Error Handler**
- Purpose: [How it handles errors]
- Strategy: [Error handling strategy]

**6. Response Formatter**
- Purpose: [How it formats responses]
- Format: [Response format]

## Operations

### Operation: `operation_name`

**Purpose:** [What this operation does]

**Parameters:**
```yaml
param1: string (required) - Description
param2: number (optional) - Description (default: 10)
```

**Returns:**
```yaml
result:
  field1: value_type - Description
  field2: value_type - Description
```

**Example:**
```markdown
Task(subagent-name): `
operation: operation_name
params:
  param1: "value"
  param2: 42
context:
  cache: true
  command: "calling-command"
`
```

**Response:**
```yaml
status: success
result:
  field1: "value"
  field2: 123
metadata:
  cached: true
  execution_time_ms: 45
```

### Operation: `another_operation`

[Repeat pattern for each operation]

## Usage

### Basic Usage

**From Commands:**
```markdown
Task(subagent-name): `
operation: operation_name
params:
  param1: "value"
`
```

**From Shared Helpers:**
```markdown
<!-- In shared helper -->
Task(subagent-name): `
operation: operation_name
params:
  param1: "${param}"
context:
  source: "shared-helper-name"
`
```

### Advanced Usage

**With Caching:**
```markdown
Task(subagent-name): `
operation: operation_name
params:
  param1: "value"
context:
  cache: true        # Enable caching
  cache_ttl: 300     # Cache for 5 minutes
`
```

**Batch Operations:**
```markdown
Task(subagent-name): `
operation: batch_operation
params:
  items:
    - item1
    - item2
    - item3
context:
  batch: true
`
```

**Error Handling:**
```markdown
Task(subagent-name): `
operation: operation_name
params:
  param1: "value"
context:
  on_error: continue   # Continue on error vs fail
  retry: true          # Retry on transient errors
`
```

## Performance

### Token Usage

**Average token consumption by operation:**

| Operation | Tokens | With Cache | Savings |
|-----------|--------|------------|---------|
| operation_1 | 2,500 | 800 | 68% |
| operation_2 | 1,200 | 300 | 75% |
| operation_3 | 3,000 | 1,000 | 67% |

**Total:**
- Average per command: X,XXX tokens
- With caching: Y,YYY tokens
- Overall savings: ZZ%

### Execution Time

**Average execution time:**

| Operation | Time (no cache) | Time (cached) | Improvement |
|-----------|----------------|---------------|-------------|
| operation_1 | 450ms | 50ms | 9x faster |
| operation_2 | 600ms | 40ms | 15x faster |
| operation_3 | 800ms | 60ms | 13x faster |

### Caching Strategy

**What is cached:**
- Data type 1 - TTL: X minutes
- Data type 2 - TTL: Y minutes
- Data type 3 - TTL: Z minutes

**Cache hit rates:**
- Average: XX%
- Peak: YY%
- Minimum: ZZ%

**Cache invalidation:**
- Automatic: After TTL expires
- Manual: On update operations
- Session: Cleared on session end

## Error Handling

### Error Format

```yaml
status: error
error:
  code: ERROR_CODE
  message: "Human-readable error message"
  suggestions:
    - "Suggestion 1 to fix the error"
    - "Suggestion 2 to fix the error"
  context:
    param1: "value that caused error"
```

### Common Errors

#### ERROR_CODE_1: "Error message"

**Cause:** [What causes this error]

**Example:**
```markdown
# Problematic usage
Task(subagent-name): `
operation: operation_name
params:
  param1: "invalid-value"
`
```

**Response:**
```yaml
status: error
error:
  code: ERROR_CODE_1
  message: "Detailed error message"
  suggestions:
    - "Use valid value instead"
    - "Check documentation"
```

**How to fix:**
1. Step 1
2. Step 2

#### ERROR_CODE_2: "Another error"

[Repeat pattern for common errors]

### Error Recovery

**Retry Strategy:**
- Transient errors: Retry 3 times with exponential backoff
- Permanent errors: Fail immediately with suggestions
- Rate limit errors: Wait and retry after cooldown

**Graceful Degradation:**
- If cache unavailable: Fall back to direct MCP calls
- If MCP unavailable: Return cached data (if available)
- If both unavailable: Return error with clear message

## Best Practices

### When to Use This Subagent

**✅ Use when:**
- You need operation 1
- You need operation 2
- You want caching benefits
- You need structured error handling

**❌ Don't use when:**
- Direct MCP call is simpler
- No caching needed
- One-off operation
- Alternative subagent is better fit

### Calling Patterns

**✅ Good:**
```markdown
<!-- Enable caching for read operations -->
Task(subagent-name): `
operation: get_data
params:
  id: "${id}"
context:
  cache: true
`
```

**❌ Bad:**
```markdown
<!-- Don't bypass caching for reads -->
Task(subagent-name): `
operation: get_data
params:
  id: "${id}"
context:
  cache: false  # Wastes tokens!
`
```

**✅ Good:**
```markdown
<!-- Batch similar operations -->
Task(subagent-name): `
operation: batch_update
params:
  items: [id1, id2, id3]
`
```

**❌ Bad:**
```markdown
<!-- Don't call multiple times in loop -->
Task(subagent-name): `operation: update params: id: id1`
Task(subagent-name): `operation: update params: id: id2`
Task(subagent-name): `operation: update params: id: id3`
```

### Performance Tips

1. **Enable caching** for read operations
2. **Batch operations** when possible
3. **Provide context** for better error messages
4. **Reuse results** within same command execution
5. **Monitor token usage** and optimize

## Integration

### With Commands

**Commands using this subagent:**
- `/ccpm:command1` - How it's used
- `/ccpm:command2` - How it's used
- `/ccpm:command3` - How it's used

**Integration pattern:**
```markdown
<!-- In command file -->
## Step: Perform Action

Task(subagent-name): `
operation: operation_name
params:
  param1: "${userInput}"
context:
  command: "command-name"
  cache: true
`
```

### With Shared Helpers

**Shared helpers using this subagent:**
- `_shared-helper1.md` - How it's used
- `_shared-helper2.md` - How it's used

**Example helper function:**
```markdown
<!-- In _shared-helper.md -->
### Function: helperFunction

Task(subagent-name): `
operation: operation_name
params:
  param1: "${param}"
context:
  source: "shared-helper-name"
`
```

### With Other Subagents

**Dependencies:**
- `other-subagent` - How they interact
- `another-subagent` - How they interact

**Coordination pattern:**
```markdown
<!-- Sequential coordination -->
1. Task(subagent1): `operation: prepare_data`
2. Task(subagent-name): `operation: process_data`
3. Task(subagent3): `operation: finalize_data`
```

## Testing

### Unit Tests

**Location:** `tests/agents/subagent-name/`

**Test cases:**
- `test_operation1.md` - Tests operation 1
- `test_operation2.md` - Tests operation 2
- `test_error_handling.md` - Tests error scenarios
- `test_caching.md` - Tests caching behavior

**Running tests:**
```bash
# Run all tests for this subagent
./scripts/test-subagent.sh subagent-name

# Run specific test
./scripts/test-subagent.sh subagent-name test_operation1
```

### Integration Tests

**Location:** `tests/integration/subagent-name/`

**Scenarios:**
- End-to-end workflow tests
- Cross-subagent integration tests
- Performance benchmarks

### Manual Testing

**Test command:**
```bash
# In Claude Code, test directly:
Task(subagent-name): `
operation: operation_name
params:
  param1: "test-value"
context:
  debug: true
`
```

**Expected result:**
```yaml
[Expected output]
```

## Troubleshooting

### Issue: Slow Performance

**Symptoms:**
- Operations take >2 seconds
- High token usage
- Timeout errors

**Diagnosis:**
```markdown
Task(subagent-name): `
operation: operation_name
params:
  param1: "value"
context:
  debug: true  # Enable debug mode
`
```

**Solutions:**
1. Enable caching if not already enabled
2. Use batch operations
3. Check MCP server health
4. Review debug output for bottlenecks

### Issue: Cache Not Working

**Symptoms:**
- Token usage higher than expected
- Operations slower than expected
- Cache hit rate low

**Diagnosis:**
1. Check cache configuration
2. Verify TTL settings
3. Check cache invalidation logic

**Solutions:**
1. Enable cache explicitly in context
2. Increase TTL if appropriate
3. Review cache invalidation triggers

### Issue: Unexpected Errors

**Symptoms:**
- Operations fail with unclear errors
- Inconsistent behavior
- Missing data

**Diagnosis:**
```markdown
Task(subagent-name): `
operation: operation_name
params:
  param1: "value"
context:
  debug: true
  verbose: true
`
```

**Solutions:**
1. Check error message and suggestions
2. Verify parameter formats
3. Ensure MCP server is accessible
4. Review operation documentation

## Development

### Adding New Operations

**Process:**
1. Define operation in subagent file
2. Implement operation logic
3. Add error handling
4. Add caching (if applicable)
5. Document in this file
6. Add tests
7. Update integration docs

**Template:**
```markdown
<!-- In subagent file -->
### Operation: new_operation

**Purpose:** [What it does]

**Parameters:**
- param1: type - Description

**Logic:**
1. Validate parameters
2. Process request
3. Call MCP if needed
4. Format response
5. Return result
```

### Modifying Existing Operations

**Process:**
1. Update operation logic
2. Update error handling
3. Update caching strategy (if needed)
4. Update documentation
5. Update tests
6. Test backward compatibility
7. Document breaking changes

**Backward Compatibility:**
- Maintain existing parameter names
- Add new parameters as optional
- Deprecate before removing
- Provide migration guide

### Deprecation

**Process:**
1. Mark operation as deprecated
2. Add deprecation warning in response
3. Document alternative
4. Set removal timeline
5. Notify users (via changelog)
6. Remove after timeline

**Deprecation warning format:**
```yaml
status: success
result: [...]
warnings:
  - type: deprecation
    message: "operation_name is deprecated"
    alternative: "Use new_operation instead"
    removal_date: "2025-12-31"
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| X.Y | 2025-11-XX | [Recent changes] |
| X.0 | 2025-10-XX | Initial release |

### Breaking Changes

**From vX.0 to vX.Y:**
- **Breaking:** [What changed]
- **Migration:** [How to update calls]
- **Impact:** [Commands/helpers affected]

## See Also

**Documentation:**
- [Agent Catalog](../../docs/reference/agents/catalog.md) - All subagents
- [Usage Patterns](../../docs/reference/agents/usage-patterns.md) - Best practices
- [API Reference](../../docs/reference/api/subagent-name-api.md) - Complete API

**Related Subagents:**
- [`other-subagent`](./other-subagent.md) - Related functionality
- [`another-subagent`](./another-subagent.md) - Alternative approach

**Commands:**
- [Commands using this subagent](../../docs/reference/commands/) - Integration examples

---

**Subagent:** `subagent-name`
**Type:** [core|project-management|specialized]
**Status:** [stable|beta|experimental]
**Version:** X.Y
**Last Updated:** 2025-11-21
```

---

## Usage Guidelines

### For Subagent Authors

**When creating a new subagent:**
1. Copy this template to `agents/subagent-name.md`
2. Fill in all sections
3. Add to `agents/README.md`
4. Create tests
5. Update integration documentation

**Required sections:**
- Purpose (why it exists)
- Capabilities (what it can/can't do)
- Architecture (how it works)
- Operations (complete API)
- Usage (examples)
- Performance (metrics)
- Error Handling (error codes and recovery)
- Best Practices (dos and don'ts)

**Optional sections** (add if applicable):
- Advanced Usage
- Integration patterns
- Troubleshooting
- Development guide

### For Subagent Users

**When using a subagent:**
1. Read Purpose section first
2. Check Capabilities to ensure it fits your need
3. Review Operations for the specific operation
4. Follow Usage examples
5. Enable caching when appropriate
6. Follow Best Practices

**When debugging:**
1. Check Common Errors section
2. Enable debug mode
3. Review error suggestions
4. Check Troubleshooting section

### For Maintainers

**When reviewing subagent docs:**
- [ ] All required sections present
- [ ] Examples are correct and up-to-date
- [ ] Error handling documented
- [ ] Performance metrics included
- [ ] Best practices clear
- [ ] Version history maintained
- [ ] Links to related docs work

**When updating subagent:**
- [ ] Update Operations section
- [ ] Update Performance metrics
- [ ] Update Version History
- [ ] Update Examples if API changed
- [ ] Add deprecation warnings if needed
- [ ] Update related documentation
