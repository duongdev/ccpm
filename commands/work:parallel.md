---
description: Parallel work mode - execute independent tasks simultaneously
allowed-tools: [Bash, Task, AskUserQuestion, Read]
argument-hint: "<issue-id>"
---

# /ccpm:work:parallel - Parallel Implementation Mode

Execute multiple independent checklist items simultaneously using parallel agent invocation.

## Helper Functions

This command uses:
- `helpers/parallel-execution.md` - Dependency graph and execution wave management
- `helpers/checklist.md` - Checklist parsing and progress tracking
- `helpers/agent-delegation.md` - Agent selection for tasks

## Usage

```bash
# Auto-detect parallel opportunities
/ccpm:work:parallel PSN-29

# With specific items to parallelize
/ccpm:work:parallel PSN-29 --items 1,2,3

# Maximum parallelism (up to 4 agents)
/ccpm:work:parallel PSN-29 --max 4
```

## Differences from /ccpm:work

| Aspect | /ccpm:work | /ccpm:work:parallel |
|--------|-----------|---------------------|
| Execution | Sequential | Parallel (2-4 agents) |
| Context usage | ~500 tokens | ~800 tokens |
| Speed | 1x | 2-4x faster |
| Best for | Dependent tasks | Independent tasks |

## Implementation

### Step 1: Fetch Issue & Parse Checklist

```javascript
const issueId = args[0];

if (!issueId || !/^[A-Z]+-\d+$/.test(issueId)) {
  return error('Usage: /ccpm:work:parallel <issue-id>');
}

console.log('⚡ Parallel Work Mode');
console.log(`📋 Issue: ${issueId}`);
console.log('');

// Fetch issue
const issue = await Task({
  subagent_type: 'ccpm:linear-operations',
  prompt: `operation: get_issue
params:
  issueId: "${issueId}"
context:
  cache: true
  command: "work:parallel"
`
});

// Parse checklist
const checklistMatch = issue.description.match(/## Implementation Checklist[\s\S]*?(?=\n##|$)/);
const items = [];
if (checklistMatch) {
  const lines = checklistMatch[0].split('\n');
  for (const line of lines) {
    const match = line.match(/^- \[([ x])\] (.+)$/);
    if (match) {
      items.push({
        checked: match[1] === 'x',
        content: match[2],
        index: items.length
      });
    }
  }
}

const uncheckedItems = items.filter(i => !i.checked);
console.log(`📝 Found ${uncheckedItems.length} uncompleted items`);
```

### Step 2: Analyze Dependencies

```javascript
// Identify which items can run in parallel
const analysisResult = await Task({
  subagent_type: 'Plan',
  model: 'haiku',
  prompt: `
Analyze these checklist items for parallel execution:

${uncheckedItems.map((item, i) => `${i+1}. ${item.content}`).join('\n')}

Identify:
1. Which items are INDEPENDENT (can run in parallel)?
2. Which items DEPEND on others (must be sequential)?

Return as JSON:
{
  "parallel": [1, 2, 3],  // item numbers that can run together
  "sequential": [4, 5],   // item numbers that must wait
  "dependencies": {
    "4": [1, 2],  // item 4 depends on items 1 and 2
    "5": [4]      // item 5 depends on item 4
  }
}
`
});

const { parallel, sequential, dependencies } = JSON.parse(analysisResult);
console.log(`⚡ Parallelizable: ${parallel.length} items`);
console.log(`🔗 Sequential: ${sequential.length} items`);
```

### Step 3: Select Agent Types (Dynamic)

```javascript
// Map items to appropriate agents using hook hints or fallback
// Agent names are project-specific - ccpm:* for CCPM, or check hook hints

function selectAgent(itemContent) {
  const content = itemContent.toLowerCase();

  // Check for hook hint patterns (injected by smart-agent-selector)
  // Use ccpm:* namespace for CCPM agents

  if (content.match(/\b(ui|component|react|css|tailwind|frontend|page|screen|layout)\b/)) {
    return 'ccpm:frontend-developer';
  }
  if (content.match(/\b(api|endpoint|database|auth|backend|graphql|rest|service|server)\b/)) {
    return 'ccpm:backend-architect';
  }
  if (content.match(/\b(test|spec|jest|vitest|cypress|playwright)\b/)) {
    return 'ccpm:tdd-orchestrator';
  }
  if (content.match(/\b(security|vulnerability|auth|oauth)\b/)) {
    return 'ccpm:security-auditor';
  }

  return 'general-purpose';
}

const parallelTasks = parallel.map(idx => ({
  index: idx,
  item: uncheckedItems[idx - 1],
  agent: selectAgent(uncheckedItems[idx - 1].content)
}));

// NOTE: For other projects, use hook hints to determine agent names:
// const hookHint = context.systemMessages.find(m => m.includes('💡'));
// const suggestedAgent = hookHint?.match(/use `([^`]+)` agent/)?.[1] || 'general-purpose';
```

### Step 4: Execute in Parallel

```javascript
console.log('\n🚀 Starting parallel execution...');
console.log('');

// Invoke multiple Task tools in a SINGLE message
// This is critical for true parallelism

const taskPromises = parallelTasks.slice(0, 4).map(task => {
  console.log(`   ⏳ ${task.index}. ${task.item.content} → ${task.agent}`);

  return Task({
    subagent_type: task.agent,
    prompt: `
## Task
${task.item.content}

## Issue Context
- Issue: ${issueId} - ${issue.title}
- Checklist Item: ${task.item.content}

## Quality Requirements
- Follow existing code patterns
- Use TypeScript strict mode if applicable
- Add necessary imports
- Handle edge cases and errors
- NO placeholder code - implement fully

## Expected Output
After making changes, return ONLY:
1. Files modified (list)
2. Summary of changes (2-3 sentences)
3. Any blockers encountered
`
  });
});

// Wait for all to complete
const results = await Promise.all(taskPromises);

console.log('');
console.log('✅ Parallel execution complete');
```

### Step 5: Process Results

```javascript
const completedIndices = [];
const blockers = [];

for (let i = 0; i < results.length; i++) {
  const task = parallelTasks[i];
  const result = results[i];

  console.log('');
  console.log(`📦 ${task.index}. ${task.item.content}`);
  console.log(`   Agent: ${task.agent}`);
  console.log(`   Files: ${result.files?.join(', ') || 'None'}`);
  console.log(`   Status: ${result.blocker ? '⚠️ Blocked' : '✅ Complete'}`);

  if (result.blocker) {
    blockers.push({
      item: task.item.content,
      blocker: result.blocker
    });
  } else {
    completedIndices.push(task.index);
  }
}
```

### Step 6: Update Checklist

```javascript
if (completedIndices.length > 0) {
  await Task({
    subagent_type: 'ccpm:linear-operations',
    prompt: `operation: update_checklist_items
params:
  issueId: "${issueId}"
  indices: [${completedIndices.join(', ')}]
  mark_complete: true
  add_comment: false
context:
  command: "work:parallel"
`
  });

  console.log(`\n✅ Updated ${completedIndices.length} checklist items`);
}
```

### Step 7: Post Progress Comment

```javascript
const gitChanges = await Bash('git diff --stat HEAD');

await Task({
  subagent_type: 'ccpm:linear-operations',
  prompt: `operation: create_comment
params:
  issueId: "${issueId}"
  body: |
    ⚡ **Parallel Implementation** | ${await Bash('git rev-parse --abbrev-ref HEAD')}

    **Completed**: ${completedIndices.length} items in parallel
    **Agents**: ${[...new Set(parallelTasks.map(t => t.agent))].join(', ')}
    ${blockers.length > 0 ? `**Blockers**: ${blockers.length}` : ''}

    +++ 📋 Details

    **Parallel Items Completed**:
    ${completedIndices.map(i => `- ✅ ${uncheckedItems[i-1].content}`).join('\n')}

    ${blockers.length > 0 ? `**Blockers**:\n${blockers.map(b => `- ⚠️ ${b.item}: ${b.blocker}`).join('\n')}` : ''}

    **Git Changes**:
    \`\`\`
    ${gitChanges.trim()}
    \`\`\`

    +++
context:
  command: "work:parallel"
`
});

console.log('✅ Progress synced to Linear');
```

### Step 8: Handle Sequential Items

```javascript
if (sequential.length > 0) {
  console.log('\n📋 Remaining sequential items:');
  for (const idx of sequential) {
    const item = uncheckedItems[idx - 1];
    const deps = dependencies[idx];
    console.log(`   ${idx}. ${item.content}`);
    if (deps) {
      console.log(`      ⮡ Depends on: ${deps.join(', ')}`);
    }
  }
  console.log('\n💡 Run /ccpm:work:parallel again after parallel items are done');
}
```

### Step 9: Summary

```javascript
console.log('\n═══════════════════════════════════════');
console.log('⚡ Parallel Implementation Complete');
console.log('═══════════════════════════════════════\n');
console.log(`✅ Completed: ${completedIndices.length} items`);
console.log(`⚠️  Blockers: ${blockers.length}`);
console.log(`⏳ Remaining: ${sequential.length} sequential`);
console.log('');
console.log('💡 Next Steps:');
if (blockers.length > 0) {
  console.log('   1. Resolve blockers listed above');
}
if (sequential.length > 0) {
  console.log('   2. /ccpm:work:parallel to continue');
} else {
  console.log('   2. /ccpm:commit to commit changes');
  console.log('   3. /ccpm:verify to run quality checks');
}
```

## When to Use

✅ **Good for:**
- UI component + API endpoint (independent)
- Multiple test files
- Config + code changes
- Documentation + implementation
- Cleanup across multiple modules

❌ **Use /ccpm:work instead for:**
- Tasks with dependencies
- Sequential database migrations
- Ordered refactoring steps
- Careful incremental changes

## Performance

| Items | /ccpm:work | /ccpm:work:parallel |
|-------|-----------|---------------------|
| 2 items | ~4 min | ~2 min (2x faster) |
| 4 items | ~8 min | ~2-3 min (3x faster) |
| 6 items | ~12 min | ~4-5 min (2.5x faster) |

## Limitations

- Maximum 4 parallel agents (context constraints)
- Some tasks may have hidden dependencies
- Merge conflicts possible if agents modify same files
- Blockers in one task don't stop others

## Example Output

```
⚡ Parallel Work Mode
📋 Issue: PSN-29

📝 Found 6 uncompleted items
⚡ Parallelizable: 4 items
🔗 Sequential: 2 items

🚀 Starting parallel execution...

   ⏳ 1. Create auth endpoints → ccpm:backend-architect
   ⏳ 2. Build login form → ccpm:frontend-developer
   ⏳ 3. Add JWT middleware → ccpm:backend-architect
   ⏳ 4. Create test suite → ccpm:tdd-orchestrator

✅ Parallel execution complete

📦 1. Create auth endpoints
   Agent: ccpm:backend-architect
   Files: src/api/auth.ts, src/routes/auth.ts
   Status: ✅ Complete

📦 2. Build login form
   Agent: ccpm:frontend-developer
   Files: src/components/LoginForm.tsx
   Status: ✅ Complete

...

═══════════════════════════════════════
⚡ Parallel Implementation Complete
═══════════════════════════════════════

✅ Completed: 4 items
⚠️  Blockers: 0
⏳ Remaining: 2 sequential

💡 Next Steps:
   1. /ccpm:work:parallel to continue
   2. /ccpm:commit to commit changes
```
