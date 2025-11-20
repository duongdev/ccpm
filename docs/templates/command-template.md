# Command Documentation Template

This template should be used for all command files in `commands/`.

---

```markdown
---
title: Command Name
category: [spec|planning|implementation|verification|completion|utils|project]
description: One-line description (under 100 chars)
syntax: /ccpm:category:command-name [args]
added: v2.X
updated: v2.Y
status: stable|beta|deprecated
related_commands:
  - /ccpm:other:command
  - /ccpm:another:command
---

# /ccpm:category:command-name

**[One-line purpose statement - what this command does and when to use it]**

## Overview

[2-3 paragraphs explaining:
1. What this command does
2. When to use it (use cases)
3. Why it exists (problem it solves)]

## Syntax

```bash
/ccpm:category:command-name <required-arg> [optional-arg]
```

### Arguments

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `required-arg` | string | ✅ Yes | Clear description of what this argument is |
| `optional-arg` | string | ❌ No | Description (default: `default-value`) |

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--flag-name` | Flag description | `false` |

## Usage Examples

### Example 1: [Common Use Case Name]

```bash
/ccpm:category:command-name arg1 arg2
```

**What happens:**
1. System performs action 1
2. System performs action 2
3. Result/outcome

**Expected output:**
```
[Show actual output]
```

### Example 2: [Advanced Use Case Name]

```bash
/ccpm:category:command-name arg1 --flag
```

**What this does:**
[Explain the advanced usage]

**Output:**
```
[Expected output]
```

### Example 3: [Edge Case or Special Scenario]

```bash
/ccpm:category:command-name special-arg
```

[Explanation of special case]

## Features

**What this command provides:**

- ✅ Feature 1 - Brief description
- ✅ Feature 2 - Brief description
- ✅ Feature 3 - Brief description
- ⚡ Performance feature (if applicable)
- 🔒 Safety feature (if applicable)

## How It Works

[Technical explanation for understanding the internals]

**Process flow:**
1. Command receives arguments
2. Validates input
3. Calls X subagent/MCP
4. Processes response
5. Returns result

**Behind the scenes:**
- Uses [subagent-name] subagent
- Calls [MCP operation]
- Implements [pattern-name] pattern
- Caches [what is cached]

## Interactive Mode

[If applicable] After execution, this command presents an interactive menu:

**Status Display:**
- ✅ Shows completion status
- 📊 Displays progress percentage
- 📝 Lists pending actions

**Next Action Suggestions:**
```
💡 What would you like to do next?
  1. [Most Common Next Action] ⭐
  2. [Alternative Action]
  3. [Another Alternative]
  4. Review Status
```

**Command Chaining:**
You can directly chain to the next command by selecting an option.

## Related Commands

**Similar functionality:**
- [`/ccpm:other:command`](./other:command.md) - Alternative approach
- [`/ccpm:related:command`](./related:command.md) - Related functionality

**Workflow commands:**
- **Before this:** [`/ccpm:previous:command`](./previous:command.md)
- **After this:** [`/ccpm:next:command`](./next:command.md)

**See also:**
- [Command Category Reference](../docs/reference/commands/category.md)
- [Workflow Guide](../docs/guides/workflows/workflow-name.md)

## Configuration

[If applicable] This command can be configured via:

**Project Configuration:**
```yaml
# ~/.claude/ccpm-config.yaml
projects:
  my-project:
    setting_name: value
```

**Command-Line Flags:**
```bash
/ccpm:category:command-name --flag value
```

**Environment Variables:**
```bash
export CCPM_SETTING=value
```

## Error Handling

### Common Errors

#### Error: "Error message here"

**Cause:** Explanation of what causes this error

**Solution:**
1. Step to resolve
2. Another step
3. Verification step

**Example:**
```bash
# Fix command
```

#### Error: "Another error message"

**Cause:** [Explanation]

**Solution:** [Steps to resolve]

## Troubleshooting

### Issue: [Common Problem]

**Symptoms:**
- Symptom 1
- Symptom 2

**Diagnosis:**
```bash
# Command to diagnose
```

**Fix:**
1. Step 1
2. Step 2

**Prevention:**
[How to avoid this issue]

### Issue: [Performance Problem]

**Symptoms:** [Slow execution, timeouts, etc.]

**Solutions:**
- Solution 1
- Solution 2

## Best Practices

**✅ Do:**
- Best practice 1 with explanation
- Best practice 2 with explanation
- Best practice 3 with explanation

**❌ Don't:**
- Anti-pattern 1 with explanation
- Anti-pattern 2 with explanation

**💡 Tips:**
- Pro tip 1
- Pro tip 2

## Safety Notes

[If applicable - especially for commands that write to external systems]

**Safety Level:** [Read-Only | Internal-Write-Only | External-Write-Requires-Confirmation | Destructive]

**What this command does:**
- ✅ Safe operation 1
- ⚠️ Warning about operation 2
- ⛔ Requires confirmation for operation 3

**Confirmation workflow:**
[If external writes] Before writing to [external system], this command:
1. Shows exactly what will be written
2. Asks for explicit confirmation
3. Only proceeds after receiving "yes"

**See:** [SAFETY_RULES.md](./SAFETY_RULES.md) for complete safety guidelines.

## Performance

[If applicable]

**Speed:** [Fast | Medium | Slow] - [Typical execution time]

**Token Usage:** [Token count] tokens (average)

**Optimization:**
- Uses caching: [Yes/No] - [What is cached]
- Batch operations: [Yes/No]
- Background execution: [Yes/No]

**Benchmarks:**
| Operation | Time | Tokens |
|-----------|------|--------|
| Example 1 | 1.2s | 2,450 |
| Example 2 | 0.3s | 800 |

## Technical Details

[For complex commands - deep dive into implementation]

**Architecture:**
```
User → Command → [Subagent] → [MCP] → [External System]
                      ↓
                 [Caching Layer]
```

**Subagents Used:**
- `subagent-name` - Purpose

**MCP Operations:**
- `mcp_operation_name` - Purpose

**Caching Strategy:**
- What: [What is cached]
- Duration: [How long]
- Invalidation: [When cache is cleared]

**Dependencies:**
- Depends on: [Other commands/subagents]
- Required MCP: [MCP servers required]

## Advanced Usage

[For power users]

### Combining with Other Commands

```bash
# Example of command chaining or advanced workflow
/ccpm:category:command-name arg1
# Then...
/ccpm:other:command arg2
```

### Scripting

[If applicable]
```bash
# Example of using in scripts
for item in $(list); do
  /ccpm:category:command-name "$item"
done
```

### Integration

[If applicable - how this integrates with external tools]

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v2.Y | 2025-11-XX | [Recent changes] |
| v2.X | 2025-10-XX | [Previous changes] |
| v2.0 | 2025-09-XX | Initial release |

### Migration Notes

[If there were breaking changes]

**From v2.X to v2.Y:**
- **Breaking:** [What changed]
- **Migration:** [How to update usage]

## See Also

**Documentation:**
- [User Guide](../docs/guides/category/guide-name.md) - How-to guide
- [Reference](../docs/reference/commands/category.md) - Complete reference
- [Architecture](../docs/architecture/decisions/00X-topic.md) - Design decision

**Related Commands:**
- [`/ccpm:related:cmd1`](./related:cmd1.md) - Related command 1
- [`/ccpm:related:cmd2`](./related:cmd2.md) - Related command 2

**External Resources:**
- [Linear API Docs](https://developers.linear.app) (if applicable)
- [GitHub API Docs](https://docs.github.com) (if applicable)

---

**Command:** `/ccpm:category:command-name`
**Category:** category
**Status:** stable
**Last Updated:** 2025-11-21
```
