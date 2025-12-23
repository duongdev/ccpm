# Command Chaining Helper

**Chain multiple CCPM commands with conditional logic and data passing**

## Purpose

Enables chaining multiple CCPM commands together with support for:
- Sequential execution with data passing
- Conditional branching based on results
- Error handling and recovery
- Workflow templates for common patterns

## Syntax

### Basic Chaining

```bash
# Sequential execution (run next only if previous succeeds)
/ccpm:plan PSN-123 && /ccpm:work && /ccpm:verify

# Always run (regardless of previous result)
/ccpm:work ; /ccpm:sync

# Run on failure
/ccpm:verify || /ccpm:sync "Verification failed, saving progress"
```

### Chain Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `&&` | Run next if success | `/ccpm:verify && /ccpm:done` |
| `||` | Run next if failure | `/ccpm:verify \|\| /ccpm:sync` |
| `;` | Always run next | `/ccpm:work ; /ccpm:status` |
| `\|` | Pipe output | `/ccpm:search \| /ccpm:work` |

## Data Structures

### Chain Definition

```typescript
interface CommandChain {
  commands: ChainedCommand[];
  variables: Map<string, any>;  // Shared context
  results: CommandResult[];
}

interface ChainedCommand {
  command: string;
  args: string[];
  condition: 'always' | 'on_success' | 'on_failure';
  inputFrom?: string;  // Variable name to read input from
  outputTo?: string;   // Variable name to store output
}

interface CommandResult {
  command: string;
  success: boolean;
  output: any;
  duration: number;
  skipped: boolean;
}
```

## Implementation

### Parse Chain Syntax

```typescript
function parseChain(input: string): CommandChain {
  const chain: CommandChain = {
    commands: [],
    variables: new Map(),
    results: [],
  };

  // Tokenize by operators while preserving quoted strings
  const tokens = tokenize(input);
  let currentCondition: 'always' | 'on_success' | 'on_failure' = 'always';

  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];

    if (token === '&&') {
      currentCondition = 'on_success';
    } else if (token === '||') {
      currentCondition = 'on_failure';
    } else if (token === ';') {
      currentCondition = 'always';
    } else if (token === '|') {
      // Pipe: output of previous goes to input of next
      if (chain.commands.length > 0) {
        const prev = chain.commands[chain.commands.length - 1];
        prev.outputTo = `_pipe_${chain.commands.length}`;
      }
      currentCondition = 'on_success';
    } else if (token.startsWith('/ccpm:')) {
      // Parse command and args
      const parts = parseCommandParts(token);
      const cmd: ChainedCommand = {
        command: parts.command,
        args: parts.args,
        condition: currentCondition,
      };

      // Check for pipe input
      if (currentCondition === 'on_success' && chain.commands.length > 0) {
        const prev = chain.commands[chain.commands.length - 1];
        if (prev.outputTo?.startsWith('_pipe_')) {
          cmd.inputFrom = prev.outputTo;
        }
      }

      chain.commands.push(cmd);
      currentCondition = 'always';  // Reset for next
    }
  }

  return chain;
}
```

### Execute Chain

```typescript
async function executeChain(
  chain: CommandChain,
  executor: (cmd: string, args: string[], input?: any) => Promise<any>
): Promise<ChainResult> {
  const startTime = Date.now();
  let lastSuccess = true;
  let lastOutput: any = null;

  console.log('═══════════════════════════════════════');
  console.log('⛓️  Command Chain');
  console.log('═══════════════════════════════════════\n');

  console.log(`📋 ${chain.commands.length} command(s) to execute\n`);

  for (let i = 0; i < chain.commands.length; i++) {
    const cmd = chain.commands[i];

    // Check condition
    const shouldRun =
      cmd.condition === 'always' ||
      (cmd.condition === 'on_success' && lastSuccess) ||
      (cmd.condition === 'on_failure' && !lastSuccess);

    if (!shouldRun) {
      console.log(`⏭️  ${cmd.command} (skipped - condition not met)`);
      chain.results.push({
        command: cmd.command,
        success: false,
        output: null,
        duration: 0,
        skipped: true,
      });
      continue;
    }

    // Get piped input if available
    const input = cmd.inputFrom
      ? chain.variables.get(cmd.inputFrom)
      : undefined;

    console.log(`🔄 ${cmd.command} ${cmd.args.join(' ')}...`);
    const cmdStart = Date.now();

    try {
      const output = await executor(cmd.command, cmd.args, input);
      const duration = Date.now() - cmdStart;

      lastSuccess = true;
      lastOutput = output;

      // Store output if specified
      if (cmd.outputTo) {
        chain.variables.set(cmd.outputTo, output);
      }

      console.log(`✅ ${cmd.command} (${duration}ms)`);

      chain.results.push({
        command: cmd.command,
        success: true,
        output,
        duration,
        skipped: false,
      });
    } catch (error) {
      const duration = Date.now() - cmdStart;
      lastSuccess = false;
      lastOutput = error;

      console.log(`❌ ${cmd.command} (${error.message})`);

      chain.results.push({
        command: cmd.command,
        success: false,
        output: error.message,
        duration,
        skipped: false,
      });
    }
  }

  const totalDuration = Date.now() - startTime;
  const successful = chain.results.filter(r => r.success && !r.skipped).length;
  const failed = chain.results.filter(r => !r.success && !r.skipped).length;
  const skipped = chain.results.filter(r => r.skipped).length;

  console.log('\n═══════════════════════════════════════');
  console.log('📊 Chain Complete');
  console.log('═══════════════════════════════════════');
  console.log(`   ✅ Successful: ${successful}`);
  console.log(`   ❌ Failed: ${failed}`);
  console.log(`   ⏭️  Skipped: ${skipped}`);
  console.log(`   ⏱️  Duration: ${totalDuration}ms`);

  return {
    success: failed === 0,
    results: chain.results,
    duration: totalDuration,
  };
}
```

## Workflow Templates

### Complete Feature Workflow

```typescript
const FEATURE_WORKFLOW = `
/ccpm:plan {issueId}
&& /ccpm:work
&& /ccpm:verify
&& /ccpm:commit
&& /ccpm:done
`;

// Usage
await executeTemplate('feature', { issueId: 'PSN-123' });
```

### Quick Fix Workflow

```typescript
const QUICKFIX_WORKFLOW = `
/ccpm:work {issueId}
&& /ccpm:commit "{message}"
&& /ccpm:done
`;

// Usage
await executeTemplate('quickfix', {
  issueId: 'PSN-456',
  message: 'fix: resolve null pointer'
});
```

### Review and Merge Workflow

```typescript
const REVIEW_WORKFLOW = `
/ccpm:review --staged
&& /ccpm:verify
|| /ccpm:sync "Review found issues"
`;
```

### Search and Work Workflow

```typescript
const SEARCH_WORK_WORKFLOW = `
/ccpm:search --mine --status="Todo"
| /ccpm:work
`;

// Pipe: search results are passed to work command
// User selects which issue to work on
```

## Built-in Workflow Templates

```typescript
const WORKFLOW_TEMPLATES = {
  // Full development cycle
  'full': '/ccpm:plan {issue} && /ccpm:work && /ccpm:verify && /ccpm:commit && /ccpm:done',

  // Quick iteration
  'iterate': '/ccpm:sync && /ccpm:commit',

  // Quality check
  'quality': '/ccpm:review && /ccpm:verify',

  // Start of day
  'morning': '/ccpm:status ; /ccpm:search --mine',

  // End of day
  'eod': '/ccpm:sync "End of day progress" && /ccpm:status',

  // Bug fix
  'bugfix': '/ccpm:work {issue} && /ccpm:commit "fix: {message}" && /ccpm:verify',

  // Feature complete
  'ship': '/ccpm:verify && /ccpm:done',
};
```

## Integration with CCPM

### Command: /ccpm:chain

```bash
# Run a template
/ccpm:chain full PSN-123

# Run a custom chain
/ccpm:chain "/ccpm:work && /ccpm:sync && /ccpm:commit"

# List available templates
/ccpm:chain --list
```

### Implementation in commands/chain.md

```markdown
---
description: Execute chained CCPM commands
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "<template|chain> [args...]"
---

# /ccpm:chain - Execute Command Chain

Execute multiple CCPM commands in sequence with conditional logic.

## Usage

```bash
# Use a workflow template
/ccpm:chain full PSN-123
/ccpm:chain bugfix PSN-456 "null pointer in login"

# Custom chain
/ccpm:chain "/ccpm:work && /ccpm:verify"

# List templates
/ccpm:chain --list
```

## Implementation

### Step 1: Parse Arguments

```javascript
const args = parseArgs(rawArgs);

if (args[0] === '--list') {
  // Show available templates
  showTemplates();
  return;
}

// Check if first arg is a template name
let chain;
if (WORKFLOW_TEMPLATES[args[0]]) {
  const template = WORKFLOW_TEMPLATES[args[0]];
  const variables = extractVariables(args.slice(1));
  chain = parseChain(interpolate(template, variables));
} else {
  // Custom chain string
  chain = parseChain(args[0]);
}
```

### Step 2: Execute Chain

```javascript
const result = await executeChain(chain, async (cmd, cmdArgs, input) => {
  // Execute the CCPM command
  return await invokeCommand(cmd, cmdArgs, { pipeInput: input });
});

// Display results
displayChainResults(result);
```
```

## Variable Interpolation

```typescript
// Template with variables
const template = '/ccpm:work {issue} && /ccpm:commit "{message}"';

// Variables
const vars = {
  issue: 'PSN-123',
  message: 'feat: add login',
};

// Interpolated
const chain = '/ccpm:work PSN-123 && /ccpm:commit "feat: add login"';
```

## Conditional Branching

### Success/Failure Branching

```typescript
// Try verify, if fails do sync with message
'/ccpm:verify || /ccpm:sync "Verification failed"'

// Try work, if succeeds do verify
'/ccpm:work && /ccpm:verify'

// Try work, always show status after
'/ccpm:work ; /ccpm:status'
```

### Complex Conditions

```typescript
// Full workflow with error handling
`
/ccpm:plan {issue}
&& /ccpm:work
&& /ccpm:verify
|| /ccpm:sync "Issues found during verification"
; /ccpm:status
`

// Execution:
// 1. plan runs
// 2. if plan succeeds, work runs
// 3. if work succeeds, verify runs
// 4. if verify FAILS, sync runs with message
// 5. status ALWAYS runs at the end
```

## Examples

### Example 1: Complete Feature

```bash
/ccpm:chain full PSN-123

# Output:
# ═══════════════════════════════════════
# ⛓️  Command Chain
# ═══════════════════════════════════════
#
# 📋 5 command(s) to execute
#
# 🔄 /ccpm:plan PSN-123...
# ✅ /ccpm:plan (2345ms)
# 🔄 /ccpm:work...
# ✅ /ccpm:work (12345ms)
# 🔄 /ccpm:verify...
# ✅ /ccpm:verify (5678ms)
# 🔄 /ccpm:commit...
# ✅ /ccpm:commit (1234ms)
# 🔄 /ccpm:done...
# ✅ /ccpm:done (3456ms)
#
# ═══════════════════════════════════════
# 📊 Chain Complete
# ═══════════════════════════════════════
#    ✅ Successful: 5
#    ❌ Failed: 0
#    ⏭️  Skipped: 0
#    ⏱️  Duration: 25058ms
```

### Example 2: With Failure Handling

```bash
/ccpm:chain "/ccpm:verify || /ccpm:sync 'Fix needed' ; /ccpm:status"

# Output:
# ═══════════════════════════════════════
# ⛓️  Command Chain
# ═══════════════════════════════════════
#
# 📋 3 command(s) to execute
#
# 🔄 /ccpm:verify...
# ❌ /ccpm:verify (tests failed)
# 🔄 /ccpm:sync "Fix needed"...
# ✅ /ccpm:sync (1234ms)
# 🔄 /ccpm:status...
# ✅ /ccpm:status (567ms)
#
# ═══════════════════════════════════════
# 📊 Chain Complete
# ═══════════════════════════════════════
#    ✅ Successful: 2
#    ❌ Failed: 1
#    ⏭️  Skipped: 0
#    ⏱️  Duration: 3456ms
```

### Example 3: Pipe Workflow

```bash
/ccpm:chain "/ccpm:search --mine | /ccpm:work"

# Output:
# Search finds issues, pipes to work
# Work receives list and prompts user to select
```

## Error Recovery

```typescript
// Retry on failure
'/ccpm:verify || /ccpm:verify || /ccpm:sync "Failed twice"'

// Cleanup on failure
'/ccpm:work && /ccpm:commit || /ccpm:rollback --git'
```

## Related Helpers

- `helpers/parallel-execution.md` - Run tasks in parallel
- `helpers/workflow.md` - Workflow state detection
- `commands/*.md` - Individual commands

---

**Version:** 1.0.0
**Last updated:** 2025-12-23
