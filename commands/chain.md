---
description: Execute chained CCPM commands with conditional logic
allowed-tools: [Bash, Task, AskUserQuestion, Skill]
argument-hint: "<template|chain> [args...]"
---

# /ccpm:chain - Execute Command Chain

Execute multiple CCPM commands in sequence with conditional logic and data passing.

## Usage

```bash
# Use a workflow template
/ccpm:chain full PSN-123
/ccpm:chain bugfix PSN-456 "null pointer fix"
/ccpm:chain ship

# Custom chain
/ccpm:chain "/ccpm:work && /ccpm:verify"
/ccpm:chain "/ccpm:verify || /ccpm:sync 'Issues found'"

# List available templates
/ccpm:chain --list
```

## Available Templates

| Template | Commands | Use Case |
|----------|----------|----------|
| `full` | plan → work → verify → commit → done | Complete feature development |
| `iterate` | sync → commit | Quick save and commit |
| `quality` | review → verify | Quality checks before merge |
| `morning` | status ; search --mine | Start of day overview |
| `eod` | sync → status | End of day wrap-up |
| `bugfix` | work → commit → verify | Quick bug fix |
| `ship` | verify → done | Final verification and PR |

## Chain Operators

| Operator | Meaning |
|----------|---------|
| `&&` | Run next command only if previous succeeds |
| `\|\|` | Run next command only if previous fails |
| `;` | Always run next command |
| `\|` | Pipe output to next command |

## Implementation

### Step 1: Parse Arguments

```javascript
const rawArgs = args.join(' ');

// Check for --list flag
if (rawArgs === '--list') {
  console.log('═══════════════════════════════════════');
  console.log('📋 Available Chain Templates');
  console.log('═══════════════════════════════════════\n');

  const templates = {
    'full': {
      chain: '/ccpm:plan {issue} && /ccpm:work && /ccpm:verify && /ccpm:commit && /ccpm:done',
      usage: '/ccpm:chain full PSN-123',
      description: 'Complete feature development cycle'
    },
    'iterate': {
      chain: '/ccpm:sync && /ccpm:commit',
      usage: '/ccpm:chain iterate',
      description: 'Quick save and commit'
    },
    'quality': {
      chain: '/ccpm:review && /ccpm:verify',
      usage: '/ccpm:chain quality',
      description: 'Quality checks before merge'
    },
    'morning': {
      chain: '/ccpm:status ; /ccpm:search --mine',
      usage: '/ccpm:chain morning',
      description: 'Start of day overview'
    },
    'eod': {
      chain: '/ccpm:sync "End of day progress" && /ccpm:status',
      usage: '/ccpm:chain eod',
      description: 'End of day wrap-up'
    },
    'bugfix': {
      chain: '/ccpm:work {issue} && /ccpm:commit "{message}" && /ccpm:verify',
      usage: '/ccpm:chain bugfix PSN-456 "fix null pointer"',
      description: 'Quick bug fix workflow'
    },
    'ship': {
      chain: '/ccpm:verify && /ccpm:done',
      usage: '/ccpm:chain ship',
      description: 'Final verification and PR creation'
    }
  };

  for (const [name, template] of Object.entries(templates)) {
    console.log(`📦 ${name}`);
    console.log(`   ${template.description}`);
    console.log(`   Chain: ${template.chain}`);
    console.log(`   Usage: ${template.usage}`);
    console.log('');
  }

  return;
}
```

### Step 2: Resolve Template or Custom Chain

```javascript
const TEMPLATES = {
  'full': '/ccpm:plan {issue} && /ccpm:work && /ccpm:verify && /ccpm:commit && /ccpm:done',
  'iterate': '/ccpm:sync && /ccpm:commit',
  'quality': '/ccpm:review && /ccpm:verify',
  'morning': '/ccpm:status ; /ccpm:search --mine',
  'eod': '/ccpm:sync "End of day progress" && /ccpm:status',
  'bugfix': '/ccpm:work {issue} && /ccpm:commit "{message}" && /ccpm:verify',
  'ship': '/ccpm:verify && /ccpm:done',
};

let chainString;
let variables = {};

// Check if first arg is a template name
const firstArg = args[0];
if (TEMPLATES[firstArg]) {
  chainString = TEMPLATES[firstArg];

  // Parse remaining args as variables
  // Format: /ccpm:chain bugfix PSN-123 "fix message"
  const varArgs = args.slice(1);

  // Common variable mapping
  if (varArgs[0]?.match(/^[A-Z]+-\d+$/)) {
    variables.issue = varArgs[0];
  }
  if (varArgs[1]) {
    variables.message = varArgs[1];
  }

  console.log(`📦 Using template: ${firstArg}`);
} else if (firstArg?.startsWith('/ccpm:')) {
  // Custom chain string
  chainString = rawArgs;
  console.log('📝 Using custom chain');
} else {
  console.log('❌ Invalid chain. Use a template name or start with /ccpm:');
  console.log('   Run /ccpm:chain --list to see available templates');
  return;
}
```

### Step 3: Interpolate Variables

```javascript
// Replace {variable} placeholders
let interpolatedChain = chainString;
for (const [key, value] of Object.entries(variables)) {
  interpolatedChain = interpolatedChain.replace(
    new RegExp(`\\{${key}\\}`, 'g'),
    value
  );
}

// Check for unresolved variables
const unresolvedMatch = interpolatedChain.match(/\{(\w+)\}/);
if (unresolvedMatch) {
  console.log(`❌ Missing variable: ${unresolvedMatch[1]}`);
  console.log(`   Provide it as an argument`);
  return;
}

console.log(`\n⛓️  Chain: ${interpolatedChain}\n`);
```

### Step 4: Parse Chain into Commands

```javascript
// Tokenize the chain
function tokenize(input) {
  const tokens = [];
  let current = '';
  let inQuotes = false;
  let quoteChar = '';

  for (let i = 0; i < input.length; i++) {
    const char = input[i];

    if ((char === '"' || char === "'") && !inQuotes) {
      inQuotes = true;
      quoteChar = char;
      current += char;
    } else if (char === quoteChar && inQuotes) {
      inQuotes = false;
      current += char;
    } else if (!inQuotes && (char === '&' || char === '|' || char === ';')) {
      if (current.trim()) {
        tokens.push(current.trim());
      }

      // Handle && and ||
      if (char === '&' && input[i + 1] === '&') {
        tokens.push('&&');
        i++;
      } else if (char === '|' && input[i + 1] === '|') {
        tokens.push('||');
        i++;
      } else {
        tokens.push(char);
      }
      current = '';
    } else {
      current += char;
    }
  }

  if (current.trim()) {
    tokens.push(current.trim());
  }

  return tokens;
}

const tokens = tokenize(interpolatedChain);

// Build command list with conditions
const commands = [];
let currentCondition = 'always'; // always, on_success, on_failure

for (const token of tokens) {
  if (token === '&&') {
    currentCondition = 'on_success';
  } else if (token === '||') {
    currentCondition = 'on_failure';
  } else if (token === ';') {
    currentCondition = 'always';
  } else if (token === '|') {
    // Pipe - treat as on_success but mark for piping
    currentCondition = 'pipe';
  } else if (token.startsWith('/ccpm:')) {
    commands.push({
      full: token,
      condition: currentCondition,
    });
    currentCondition = 'always';
  }
}
```

### Step 5: Execute Chain

```javascript
console.log('═══════════════════════════════════════');
console.log('⛓️  Executing Chain');
console.log('═══════════════════════════════════════\n');

console.log(`📋 ${commands.length} command(s) to execute\n`);

let lastSuccess = true;
let lastOutput = null;
const results = [];

for (let i = 0; i < commands.length; i++) {
  const cmd = commands[i];

  // Check condition
  const shouldRun =
    cmd.condition === 'always' ||
    cmd.condition === 'pipe' ||
    (cmd.condition === 'on_success' && lastSuccess) ||
    (cmd.condition === 'on_failure' && !lastSuccess);

  if (!shouldRun) {
    console.log(`⏭️  ${cmd.full} (skipped)`);
    results.push({ command: cmd.full, skipped: true });
    continue;
  }

  console.log(`🔄 ${cmd.full}...`);
  const startTime = Date.now();

  try {
    // Extract command name and invoke via Skill tool
    const cmdMatch = cmd.full.match(/\/ccpm:(\S+)\s*(.*)/);
    if (cmdMatch) {
      const [, skillName, skillArgs] = cmdMatch;

      // Invoke the skill
      await Skill({
        skill: `ccpm:${skillName}`,
        args: skillArgs || undefined
      });

      lastSuccess = true;
      console.log(`✅ ${cmd.full} (${Date.now() - startTime}ms)`);
      results.push({ command: cmd.full, success: true, duration: Date.now() - startTime });
    }
  } catch (error) {
    lastSuccess = false;
    console.log(`❌ ${cmd.full} (${error.message})`);
    results.push({ command: cmd.full, success: false, error: error.message });
  }
}
```

### Step 6: Display Summary

```javascript
console.log('\n═══════════════════════════════════════');
console.log('📊 Chain Complete');
console.log('═══════════════════════════════════════');

const successful = results.filter(r => r.success).length;
const failed = results.filter(r => r.success === false).length;
const skipped = results.filter(r => r.skipped).length;

console.log(`   ✅ Successful: ${successful}`);
console.log(`   ❌ Failed: ${failed}`);
console.log(`   ⏭️  Skipped: ${skipped}`);

if (failed > 0) {
  console.log('\n⚠️  Some commands failed. Check output above for details.');
}
```

## Examples

### Example 1: Full Feature Workflow

```bash
/ccpm:chain full PSN-123

# Output:
# 📦 Using template: full
#
# ⛓️  Chain: /ccpm:plan PSN-123 && /ccpm:work && /ccpm:verify && /ccpm:commit && /ccpm:done
#
# ═══════════════════════════════════════
# ⛓️  Executing Chain
# ═══════════════════════════════════════
#
# 📋 5 command(s) to execute
#
# 🔄 /ccpm:plan PSN-123...
# ✅ /ccpm:plan PSN-123 (2345ms)
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
```

### Example 2: Quick Bug Fix

```bash
/ccpm:chain bugfix PSN-456 "fix null pointer in auth"

# Chain: /ccpm:work PSN-456 && /ccpm:commit "fix null pointer in auth" && /ccpm:verify
```

### Example 3: Custom Chain with Error Handling

```bash
/ccpm:chain "/ccpm:verify || /ccpm:sync 'Tests failed' ; /ccpm:status"

# If verify fails, sync with message
# Status always runs at end
```

### Example 4: End of Day

```bash
/ccpm:chain eod

# Chain: /ccpm:sync "End of day progress" && /ccpm:status
# Saves progress and shows current status
```

## Notes

- Commands execute sequentially (no parallel chains yet)
- Variables use `{name}` syntax: `{issue}`, `{message}`
- First positional arg after template is `{issue}`
- Second positional arg after template is `{message}`
- Custom chains must start with `/ccpm:`
- Use `--list` to see all available templates

## Related

- `helpers/command-chaining.md` - Implementation details
- `helpers/parallel-execution.md` - Parallel task execution
- All CCPM commands can be chained
