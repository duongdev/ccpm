---
description: Quick planning - minimal research, fast task creation
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "<title> [project]"
---

# /ccpm:plan:quick - Quick Planning Mode

Fast task creation with minimal research. Use when you know what needs to be done.

## Usage

```bash
# Quick create a task
/ccpm:plan:quick "Fix login button alignment"

# With project
/ccpm:plan:quick "Add dark mode toggle" my-app
```

## Differences from /ccpm:plan

| Aspect | /ccpm:plan | /ccpm:plan:quick |
|--------|-----------|------------------|
| Codebase analysis | Deep (5-10 files) | Shallow (2-3 files) |
| External research | Yes (Jira, Confluence) | No |
| Checklist generation | Detailed (10+ items) | Brief (3-5 items) |
| Visual context | Full Figma extraction | Skip |
| Estimated time | 30-60 seconds | 5-10 seconds |

## Implementation

### Step 1: Parse Arguments

```javascript
const title = args[0];
const project = args[1];

if (!title) {
  return error('Usage: /ccpm:plan:quick "<title>" [project]');
}

console.log('⚡ Quick Planning Mode');
console.log(`📋 Task: ${title}`);
```

### Step 2: Quick Codebase Scan

```javascript
// Minimal codebase analysis - just get key files
const keywords = title.toLowerCase().split(/\s+/).filter(w => w.length > 3);

const result = await Task({
  subagent_type: 'Explore',
  model: 'haiku',  // Use fastest model
  prompt: `
Quick scan for: ${title}

Find ONLY:
1. 2-3 most relevant files
2. Main pattern to follow
3. Any obvious blockers

Keywords: ${keywords.join(', ')}

Return in <50 words.
`
});

console.log('✅ Quick scan complete');
```

### Step 3: Generate Brief Checklist

```javascript
const checklist = generateQuickChecklist(title, result);

// Simple heuristic-based checklist
function generateQuickChecklist(title, context) {
  const items = [];
  const titleLower = title.toLowerCase();

  // Always include
  items.push('Implement core functionality');
  items.push('Test changes locally');

  // Context-specific
  if (titleLower.includes('fix') || titleLower.includes('bug')) {
    items.unshift('Identify root cause');
    items.push('Add regression test');
  } else if (titleLower.includes('add') || titleLower.includes('create')) {
    items.unshift('Design approach');
    items.push('Update documentation');
  } else if (titleLower.includes('refactor') || titleLower.includes('improve')) {
    items.unshift('Identify affected areas');
    items.push('Verify no regressions');
  }

  items.push('Code review');

  return items;
}
```

### Step 4: Create Linear Issue

```javascript
const description = `
## Quick Task

${title}

## Context

${result.summary || 'Minimal analysis - created via quick planning mode.'}

## Implementation Checklist

${checklist.map(item => `- [ ] ${item}`).join('\n')}

---
*Created via /ccpm:plan:quick*
`;

// Use Linear subagent
const issueResult = await Task({
  subagent_type: 'ccpm:linear-operations',
  prompt: `operation: create_issue
params:
  team: "${project || 'Personal'}"
  title: "${title}"
  description: |
${description.split('\n').map(l => '    ' + l).join('\n')}
  labels: ["quick-plan"]
context:
  command: "plan:quick"
`
});

console.log(`✅ Created: ${issueResult.issue.identifier}`);
console.log(`🔗 ${issueResult.issue.url}`);
```

### Step 5: Suggest Next Action

```javascript
console.log('\n💡 Next: /ccpm:work ' + issueResult.issue.identifier);
console.log('   Or use /ccpm:plan ' + issueResult.issue.identifier + ' for deeper analysis');
```

## When to Use

✅ **Good for:**
- Small bug fixes
- Simple UI tweaks
- Quick experiments
- Well-understood tasks
- Familiar codebase areas

❌ **Use /ccpm:plan instead for:**
- New features
- Complex integrations
- Unknown codebase areas
- Tasks with dependencies
- External stakeholder requirements

## Example Output

```
⚡ Quick Planning Mode
📋 Task: Fix login button alignment

✅ Quick scan complete
   Files: src/components/LoginForm.tsx, src/styles/auth.css
   Pattern: Tailwind flexbox

✅ Created: PSN-42 - Fix login button alignment
🔗 https://linear.app/team/issue/PSN-42

💡 Next: /ccpm:work PSN-42
   Or use /ccpm:plan PSN-42 for deeper analysis
```
