# CCPM Decisions Log Helper

This helper provides utilities for tracking architectural decisions, technical choices, and rationale during development. Inspired by [Claude-Code-Harness's SSOT pattern](https://github.com/Chachamaru127/claude-code-harness).

## Purpose

- **Track "Why"** - Document decision rationale for future reference
- **Cross-Session Memory** - Decisions persist across sessions via Linear/files
- **Prevent Re-Decisions** - Avoid re-debating settled decisions
- **Knowledge Transfer** - Help new team members understand choices

## Decision Categories

| Category | Examples | Storage |
|----------|----------|---------|
| **Architecture** | State management, API patterns, DB schema | Linear + `decisions.md` |
| **Technology** | Library choices, framework decisions | Linear comment |
| **Implementation** | Algorithm selection, data structures | Inline code comment |
| **Tradeoffs** | Performance vs maintainability | Linear comment |

---

## Core Functions

### 1. logDecision

Log an architectural or technical decision.

```javascript
/**
 * Log a decision to the appropriate storage
 * @param {Object} decision - Decision details
 * @param {string} decision.title - Short title (e.g., "Use React Query for server state")
 * @param {string} decision.category - Category: architecture|technology|implementation|tradeoff
 * @param {string} decision.context - What problem we're solving
 * @param {string} decision.decision - What we decided
 * @param {string} decision.reason - Why we chose this approach
 * @param {string[]} decision.alternatives - What else was considered
 * @param {string} decision.issueId - Optional Linear issue ID
 * @returns {Promise<void>}
 */
async function logDecision(decision) {
  const {
    title,
    category = 'architecture',
    context,
    decision: chosen,
    reason,
    alternatives = [],
    issueId
  } = decision;

  const timestamp = new Date().toISOString().substring(0, 10);  // YYYY-MM-DD

  // Format decision entry
  const entry = `
### ${title}

**Date**: ${timestamp}
**Category**: ${category}

**Context**: ${context}

**Decision**: ${chosen}

**Reason**: ${reason}

${alternatives.length > 0 ? `**Alternatives Considered**:\n${alternatives.map(a => `- ${a}`).join('\n')}` : ''}

---
`;

  // 1. Append to local decisions.md (if exists)
  const decisionsFile = await findDecisionsFile();
  if (decisionsFile) {
    await appendToFile(decisionsFile, entry);
    console.log(`📝 Decision logged to ${decisionsFile}`);
  }

  // 2. Post to Linear if issue provided
  if (issueId) {
    await Task({
      subagent_type: 'ccpm:linear-operations',
      prompt: `
operation: create_comment
params:
  issueId: ${issueId}
  body: |
    📋 **Decision: ${title}**

    **Context**: ${context}

    **Decision**: ${chosen}

    **Reason**: ${reason}

    ${alternatives.length > 0 ? `**Alternatives**: ${alternatives.join(', ')}` : ''}

    ---
    *Logged via CCPM decisions helper*
context:
  command: decisions-log
`
    });
    console.log(`📝 Decision posted to Linear ${issueId}`);
  }

  // 3. Log to context capture for subagent awareness
  const contextLog = process.env.CCPM_CONTEXT_LOG;
  if (contextLog) {
    const fs = require('fs');
    const shortEntry = `[decision] ${title}: ${chosen.substring(0, 50)}...`;
    fs.appendFileSync(contextLog, `${new Date().toISOString().substring(11, 19)} ${shortEntry}\n`);
  }
}

/**
 * Find decisions.md file in project
 */
async function findDecisionsFile() {
  const candidates = [
    'docs/decisions.md',
    'DECISIONS.md',
    '.claude/decisions.md',
    'docs/architecture/decisions.md'
  ];

  for (const candidate of candidates) {
    try {
      await Read(candidate);
      return candidate;
    } catch (e) {
      // File doesn't exist, continue
    }
  }

  return null;
}

/**
 * Append content to file
 */
async function appendToFile(filePath, content) {
  const existing = await Read(filePath).catch(() => '');
  await Write(filePath, existing + '\n' + content);
}
```

---

### 2. searchDecisions

Search past decisions for relevant context.

```javascript
/**
 * Search past decisions
 * @param {string} query - Search query
 * @param {Object} options - Search options
 * @returns {Promise<Array>} Matching decisions
 */
async function searchDecisions(query, options = {}) {
  const results = [];

  // 1. Search local decisions.md
  const decisionsFile = await findDecisionsFile();
  if (decisionsFile) {
    const content = await Read(decisionsFile);
    const sections = content.split('### ').filter(s => s.trim());

    for (const section of sections) {
      if (section.toLowerCase().includes(query.toLowerCase())) {
        const title = section.split('\n')[0].trim();
        results.push({
          source: 'local',
          title,
          snippet: section.substring(0, 200) + '...'
        });
      }
    }
  }

  // 2. Search Linear comments if issue context available
  const issueId = process.env.CCPM_ACTIVE_ISSUE;
  if (issueId && options.includeLinear) {
    const comments = await Task({
      subagent_type: 'ccpm:linear-operations',
      prompt: `
operation: list_comments
params:
  issueId: ${issueId}
context:
  command: decisions-log:search
`
    });

    // Filter comments containing "Decision:" marker
    const decisionComments = comments.filter(c =>
      c.body.includes('Decision:') || c.body.includes('📋 **Decision')
    );

    for (const comment of decisionComments) {
      if (comment.body.toLowerCase().includes(query.toLowerCase())) {
        results.push({
          source: 'linear',
          title: comment.body.match(/Decision[:\s]*([^\n]+)/)?.[1] || 'Unknown',
          snippet: comment.body.substring(0, 200) + '...',
          commentId: comment.id
        });
      }
    }
  }

  return results;
}
```

---

### 3. checkExistingDecision

Check if a decision already exists to avoid re-debating.

```javascript
/**
 * Check if a similar decision was already made
 * @param {string} topic - Topic to check (e.g., "state management", "auth library")
 * @returns {Promise<Object|null>} Existing decision or null
 */
async function checkExistingDecision(topic) {
  const results = await searchDecisions(topic, { includeLinear: true });

  if (results.length > 0) {
    console.log(`\n⚠️ Found existing decision for "${topic}":`);
    console.log(`   ${results[0].title}`);
    console.log(`   ${results[0].snippet}`);
    console.log('');

    return results[0];
  }

  return null;
}
```

---

### 4. promptForDecision

Interactive decision capture during implementation.

```javascript
/**
 * Prompt user for decision details
 * @param {string} topic - What decision is about
 * @param {string[]} options - Available options
 * @returns {Promise<Object>} Captured decision
 */
async function promptForDecision(topic, options = []) {
  // First check if decision already exists
  const existing = await checkExistingDecision(topic);
  if (existing) {
    const confirm = await AskUserQuestion({
      questions: [{
        question: `A decision about "${topic}" already exists. Use it or make a new decision?`,
        header: 'Decision',
        multiSelect: false,
        options: [
          { label: 'Use existing', description: `Keep: ${existing.title}` },
          { label: 'Make new decision', description: 'Override with new choice' }
        ]
      }]
    });

    if (confirm === 'Use existing') {
      return { useExisting: true, decision: existing };
    }
  }

  // Gather decision details
  let chosen = null;
  if (options.length > 0) {
    const answer = await AskUserQuestion({
      questions: [{
        question: `Which approach should we use for ${topic}?`,
        header: topic,
        multiSelect: false,
        options: options.map((opt, i) => ({
          label: opt,
          description: i === 0 ? 'Recommended' : ''
        }))
      }]
    });
    chosen = answer;
  }

  // Get reason
  const reason = await AskUserQuestion({
    questions: [{
      question: 'What is the main reason for this choice?',
      header: 'Reason',
      multiSelect: false,
      options: [
        { label: 'Performance', description: 'Speed/efficiency considerations' },
        { label: 'Maintainability', description: 'Code clarity and future changes' },
        { label: 'Team familiarity', description: 'Team already knows this approach' },
        { label: 'Project requirements', description: 'Specific feature needs' }
      ]
    }]
  });

  return {
    useExisting: false,
    decision: {
      title: `${topic}: ${chosen}`,
      category: 'architecture',
      context: `Making a decision about ${topic}`,
      decision: chosen,
      reason,
      alternatives: options.filter(o => o !== chosen)
    }
  };
}
```

---

## Integration with CCPM Workflow

### Auto-Capture in /ccpm:work

When significant implementation decisions are made, log them automatically:

```javascript
// During implementation, when choosing between approaches
if (makingArchitecturalChoice) {
  await logDecision({
    title: 'Authentication: Use NextAuth.js',
    category: 'technology',
    context: 'Need to implement user authentication for the app',
    decision: 'Use NextAuth.js with JWT sessions',
    reason: 'Built-in OAuth providers, good Next.js integration, team familiarity',
    alternatives: ['Custom JWT implementation', 'Clerk', 'Auth0'],
    issueId: currentIssueId
  });
}
```

### Pre-Implementation Check in /ccpm:plan

Before planning, check for existing decisions:

```javascript
// In /ccpm:plan before generating implementation plan
const existingDecisions = await searchDecisions(taskDescription);
if (existingDecisions.length > 0) {
  console.log('\n📋 Relevant Past Decisions:');
  existingDecisions.forEach(d => {
    console.log(`   • ${d.title}`);
  });
  console.log('\nThese decisions will be considered in the plan.\n');
}
```

---

## Decision Log File Format

Create a `docs/decisions.md` or `DECISIONS.md` file:

```markdown
# Architecture Decisions

This document tracks architectural and technical decisions made during development.

---

### Use React Query for Server State

**Date**: 2025-01-15
**Category**: technology

**Context**: Need to manage server state (API data) separately from UI state.

**Decision**: Use React Query (TanStack Query) for all server state management.

**Reason**: Automatic caching, background refetching, optimistic updates built-in.
Team already familiar with it from previous projects.

**Alternatives Considered**:
- SWR (simpler but less features)
- Redux Toolkit Query (more boilerplate)
- Custom fetch hooks (maintenance burden)

---

### API Authentication: JWT with Refresh Tokens

**Date**: 2025-01-14
**Category**: architecture

**Context**: Need secure API authentication that works with mobile and web clients.

**Decision**: Use JWT access tokens (15 min) with refresh tokens (7 days).

**Reason**: Stateless auth scales well, refresh tokens provide good UX without
compromising security significantly.

**Alternatives Considered**:
- Session-based auth (doesn't scale well)
- JWT only (security concern with long-lived tokens)
- OAuth-only (overkill for internal app)

---
```

---

## Best Practices

1. **Log decisions at decision time** - Don't wait until the end
2. **Include alternatives** - Future devs need to know what was considered
3. **Be specific** - "Use React Query" is better than "Use a data fetching library"
4. **Link to issue** - Post to Linear for searchability
5. **Review periodically** - Some decisions may need revisiting

---

## Usage Examples

### Example 1: During Implementation

```javascript
// When choosing a library
await logDecision({
  title: 'Form validation: Use Zod + React Hook Form',
  category: 'technology',
  context: 'Need form validation with TypeScript support',
  decision: 'Combine Zod for schema validation with React Hook Form for form state',
  reason: 'Type-safe, excellent DX, Zod schemas reusable for API validation',
  alternatives: ['Yup + Formik', 'Custom validation'],
  issueId: 'WORK-42'
});
```

### Example 2: Before Starting Work

```javascript
// Check for existing decisions
const authDecision = await checkExistingDecision('authentication');
if (authDecision) {
  // Use existing approach
  console.log(`Using existing auth approach: ${authDecision.title}`);
} else {
  // Need to make decision
  const decision = await promptForDecision('authentication', [
    'NextAuth.js',
    'Clerk',
    'Custom JWT',
    'Auth0'
  ]);
  await logDecision(decision.decision);
}
```

---

## Related Files

- `helpers/workflow.md` - Workflow state tracking
- `commands/plan.md` - Planning command that checks decisions
- `commands/work.md` - Work command that logs decisions
- `hooks/scripts/context-capture.cjs` - Captures decisions for subagents
