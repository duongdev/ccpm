# Agent Delegation Helper

This helper provides patterns for delegating implementation work to specialized agents, protecting the main context window from token bloat.

## The Problem

**Without agent delegation:**
```
Main Context (200k limit)
├── Issue description (~500 tokens)
├── Codebase analysis (~2000 tokens)    ← PROBLEM: Fills main context
├── Implementation plan (~1000 tokens)   ← PROBLEM: Stays in context
├── Code changes (~5000 tokens)          ← PROBLEM: Every line visible
├── More code changes (~5000 tokens)     ← PROBLEM: Context full
└── Error: Context limit reached         ← FAILURE
```

**With agent delegation:**
```
Main Context (~500 tokens total)
├── Task(Explore): "analyze codebase"    ← ~50 tokens
│   └── Returns: {files, approach}       ← ~100 tokens summary
├── Task(frontend-developer): "implement"← ~50 tokens
│   └── Returns: "completed X"           ← ~50 tokens summary
└── Background: update Linear            ← ~20 tokens

Agent contexts (separate, isolated):
├── Explore context: 2000 tokens (discarded after)
├── Frontend context: 5000 tokens (discarded after)
└── Linear context: 1000 tokens (discarded after)
```

## Agent Selection Strategy

### Available Specialized Agents

| Agent Type | Use For | Subagent Name |
|------------|---------|---------------|
| Codebase exploration | Finding files, patterns | `Explore` |
| Frontend/UI | React, CSS, components | `frontend-mobile-development:frontend-developer` |
| Backend/API | APIs, databases, auth | `backend-development:backend-architect` |
| Mobile | React Native, Flutter | `frontend-mobile-development:mobile-developer` |
| Testing | Unit tests, E2E | `full-stack-orchestration:test-automator` |
| Code review | Quality checks | `code-documentation:code-reviewer` |

### Detection Logic

```javascript
function selectAgent(task, techStack) {
  const taskLower = task.toLowerCase();

  // Frontend signals
  if (taskLower.match(/\b(ui|component|react|css|tailwind|frontend|page|screen|layout)\b/)) {
    return 'frontend-mobile-development:frontend-developer';
  }

  // Backend signals
  if (taskLower.match(/\b(api|endpoint|database|auth|backend|server|graphql|rest)\b/)) {
    return 'backend-development:backend-architect';
  }

  // Mobile signals
  if (taskLower.match(/\b(mobile|react native|flutter|ios|android|app)\b/)) {
    return 'frontend-mobile-development:mobile-developer';
  }

  // Testing signals
  if (taskLower.match(/\b(test|spec|jest|vitest|cypress|playwright)\b/)) {
    return 'full-stack-orchestration:test-automator';
  }

  // Default to general purpose
  return 'general-purpose';
}
```

## Delegation Patterns

### Pattern 1: Codebase Analysis (Use Explore Agent)

**ALWAYS use Explore agent for codebase analysis** - never do it in main context:

```markdown
## Step: Analyze Codebase

**Use Task tool with Explore agent:**

Task(subagent_type="Explore", model="haiku"): `
Find files and patterns for implementing: ${task.title}

Focus on:
1. Files that need modification
2. Similar patterns in codebase
3. Dependencies needed

Return ONLY:
- file_paths: [list of relevant files]
- patterns: [existing patterns to follow]
- dependencies: [imports needed]
`

**Main context receives:** ~100 tokens (just the summary)
**Explore context used:** ~2000 tokens (discarded)
```

### Pattern 2: Chunked Implementation (One Agent Per Checklist Item)

**Break implementation into chunks** - one agent call per logical unit:

```markdown
## Step: Implement Checklist Items

For each checklist item, invoke specialized agent:

### Item 1: "Create login component"

Task(subagent_type="frontend-mobile-development:frontend-developer"): `
Implement: Create login component

Files to modify: ${explorationResult.file_paths}
Patterns to follow: ${explorationResult.patterns}

Requirements:
- ${checklistItem.content}

Make actual file changes. Return summary of changes made.
`

### Item 2: "Add authentication endpoint"

Task(subagent_type="backend-development:backend-architect"): `
Implement: Add authentication endpoint

Files to modify: ${explorationResult.file_paths}
Patterns to follow: ${explorationResult.patterns}

Requirements:
- ${checklistItem.content}

Make actual file changes. Return summary of changes made.
`

**Each call:** ~50 tokens in main context
**Total for 5 items:** ~250 tokens (vs ~10,000 without delegation)
```

### Pattern 3: Parallel Agent Calls

**When tasks are independent, invoke multiple agents in parallel:**

```markdown
## Step: Parallel Implementation

Independent tasks detected - invoking agents in parallel:

Task(subagent_type="frontend-mobile-development:frontend-developer"): `
Implement frontend component for: ${task1}
`

Task(subagent_type="backend-development:backend-architect"): `
Implement API endpoint for: ${task2}
`

Task(subagent_type="full-stack-orchestration:test-automator"): `
Write tests for: ${task3}
`

**All three run simultaneously - total time reduced by ~60%**
```

### Pattern 4: Visual Context Delegation

**For UI tasks, pass visual context to frontend agent:**

```markdown
## Step: Pixel-Perfect UI Implementation

Task(subagent_type="frontend-mobile-development:frontend-developer"): `
Implement UI component with pixel-perfect accuracy.

**Visual References:**
- Mockup: ${mockupUrl}
- Figma design system:
  - Colors: ${figmaColors}
  - Typography: ${figmaFonts}
  - Spacing: ${figmaSpacing}

**Requirements:**
${checklistItem.content}

Target: 95-100% design fidelity
Make actual file changes.
`

**Visual context stays in agent context, not main**
```

## Implementation Flow for /ccpm:work

### Optimized Flow

```
1. Get Issue (blocking, via linear-operations subagent)
   └── Main context: ~150 tokens

2. Explore Codebase (via Explore agent)
   └── Main context: ~100 tokens (summary only)

3. Ask User: AI implement or manual?
   └── Main context: ~50 tokens

4. If AI implement, for each checklist item:
   │
   ├── Select agent based on task type
   │   └── Use selectAgent() function
   │
   ├── Invoke agent with minimal context
   │   └── Only: task, files, patterns
   │
   └── Receive summary (~50 tokens)

5. Update Linear (background, ~20 tokens)

6. Display summary to user

TOTAL: ~500 tokens vs ~15,000 without delegation
```

### Example: Implementing Auth Feature

```markdown
## Checklist Items:
1. [ ] Create login UI component
2. [ ] Add authentication API endpoint
3. [ ] Write unit tests
4. [ ] Update documentation

## Optimized Agent Delegation:

### Step 1: Explore (haiku model, fast)
Task(Explore): "Find auth patterns and relevant files"
Result: {files: [...], patterns: [...]}

### Step 2: UI Component (frontend agent)
Task(frontend-developer): "Create login component using ${patterns}"
Result: "Created src/components/Login.tsx"

### Step 3: API Endpoint (backend agent)
Task(backend-architect): "Add /auth/login endpoint"
Result: "Created src/api/auth.ts"

### Step 4: Tests (test agent) - can run parallel with Step 3
Task(test-automator): "Write tests for login flow"
Result: "Created 5 test cases"

### Step 5: Update Linear (background)
Background: comment + checklist update

Total main context: ~400 tokens
Total time: ~3 min (parallel) vs ~6 min (sequential)
```

## Key Principles

1. **Never analyze codebase in main context** - Use Explore agent
2. **Never implement in main context** - Use specialized agents
3. **Use haiku for exploration** - Faster and cheaper
4. **Use sonnet for implementation** - Better quality
5. **One agent per logical task** - Don't combine unrelated work
6. **Parallel when independent** - Multiple Task calls in one message
7. **Background for Linear updates** - Zero context usage

## Agent Prompt Templates

### Exploration Template
```
Find files and patterns for: ${task}

Return:
- file_paths: relevant files
- patterns: existing patterns
- dependencies: needed imports
```

### Implementation Template
```
Implement: ${checklistItem}

Context:
- Files: ${files}
- Patterns: ${patterns}

Make actual changes. Return summary.
```

### Testing Template
```
Write tests for: ${component}

Test types: unit, integration
Coverage target: 80%

Make actual changes. Return test count.
```

## Integration with Work Command

The `/ccpm:work` command should:

1. **Use Explore for analysis** (not inline codebase search)
2. **Break checklist into agent calls** (not one big implementation)
3. **Select agent by task type** (not generic Task)
4. **Use parallel calls** (when tasks independent)
5. **Use background for Linear** (as documented in linear-background.md)

## Notes

- Smart-agent-selector hook runs on every message, suggesting agents
- This helper provides explicit patterns when hook suggestions aren't specific enough
- Agent context is isolated - doesn't fill main context
- Model can be specified: haiku (fast), sonnet (quality), opus (complex)
