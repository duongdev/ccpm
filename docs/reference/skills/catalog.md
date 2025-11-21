##CCPM Skills Catalog

**Complete reference for all CCPM skills - what they do, when they activate, and how they integrate.**

**Last Updated**: 2025-11-21
**Total Skills**: 16 (8 CCPM-original + 4 adapted + 2 as-is + 2 project-specific)

---

## Quick Reference

| # | Skill | Type | Auto-Activates When | Primary Use |
|---|-------|------|---------------------|-------------|
| 1 | **external-system-safety** | Safety | External system writes detected | Prevents accidental Jira/Confluence/Slack writes |
| 2 | **pm-workflow-guide** | Workflow | PM workflow questions | Suggests appropriate CCPM commands |
| 3 | **natural-workflow** | Workflow | Workflow questions | Complete 6-command workflow guide |
| 4 | **workflow-state-tracking** | Workflow | State/progress queries | State machine and transition validation |
| 5 | **figma-integration** | Design | Figma/design mentions | Design-to-code workflow |
| 6 | **sequential-thinking** | Problem-Solving | Complex problems mentioned | Structured reasoning for planning/specs |
| 7 | **docs-seeker** | Research | Documentation requests | Finds library/API documentation |
| 8 | **ccpm-code-review** | Quality | Completion claims | Enforces verification before "done" |
| 9 | **ccpm-debugging** | Quality | Errors/failures mentioned | Systematic debugging with Linear tracking |
| 10 | **ccpm-mcp-management** | Infrastructure | MCP issues | Troubleshoots MCP server connectivity |
| 11 | **hook-optimization** | Infrastructure | Hook performance questions | Hook optimization and benchmarking |
| 12 | **ccpm-skill-creator** | Meta | Skill creation requests | Creates custom CCPM skills |
| 13 | **project-detection** | Infrastructure | Project context detection | Auto-detects project in monorepos |
| 14 | **project-operations** | Infrastructure | Project setup/management | Project configuration and templates |
| 15 | **commit-assistant** | Development | Commit operations | Conventional commits guidance |
| 16 | **linear-subagent-guide** | Development | Linear operations | Linear API optimization patterns |

---

## Complete Skill Descriptions

### 1. external-system-safety

**Category**: Safety / Core PM
**Source**: CCPM-original
**Location**: `skills/external-system-safety/SKILL.md`

**Purpose**:
Prevents accidental writes to external project management systems (Jira, Confluence, BitBucket, Slack) by requiring explicit user confirmation before any write operation.

**Auto-Activates When**:
- Jira update detected (status, comments, assignments)
- Confluence edit detected (pages, spaces)
- BitBucket operation detected (PR creation, comments)
- Slack post detected (messages, notifications)

**Key Features**:
- Detects external system writes automatically
- Shows exact content before posting
- Requires explicit "yes" confirmation
- Blocks operation if not confirmed
- Works even when agents bypass commands

**Integration Points**:
- All `/ccpm:*` commands that write externally
- `/ccpm:complete:finalize` (PR, Jira, Slack)
- Works alongside all other skills

**Example**:
```
User: "Update Jira ABC-123 to Done"
       ↓
Skill activates: "⚠️ EXTERNAL WRITE: Update Jira ABC-123? (yes/no)"
       ↓
User: "yes"
       ↓
Operation proceeds
```

---

### 2. pm-workflow-guide

**Category**: Workflow / Core PM
**Source**: CCPM-original
**Location**: `skills/pm-workflow-guide/SKILL.md`

**Purpose**:
Context-aware command suggestions based on current workflow phase (planning, implementation, verification, completion).

**Auto-Activates When**:
- User asks "which command"
- Workflow phase detected (planning, implementing, verifying)
- User seems unsure about next step

**Key Features**:
- Detects workflow phase automatically
- Suggests 1-3 most appropriate commands
- Explains why each command fits
- Provides workflow state machine guidance
- Interactive next action suggestions

**Integration Points**:
- Works with all 37 CCPM commands
- Complements smart-agent-selector hook
- Suggests verification before completion

**Example**:
```
User: "I need to plan this authentication feature"
       ↓
Skill activates: "You're in planning phase. Recommended:
  - /ccpm:planning:create (new task with Jira)
  - /ccpm:spec:create (complex feature needing spec)
  - /ccpm:planning:quick-plan (quick internal task)"
```

---

### 3. sequential-thinking

**Category**: Problem-Solving
**Source**: ClaudeKit (as-is)
**Location**: `skills/sequential-thinking/SKILL.md`

**Purpose**:
Structured problem-solving through iterative reasoning with revision and branching capabilities.

**Auto-Activates When**:
- "complex", "break down", "analyze" mentioned
- Running `/ccpm:planning:create` (task decomposition)
- Running `/ccpm:spec:write` (architecture decisions)
- Running `/ccpm:utils:insights` (complexity assessment)

**Key Features**:
- Progressive refinement (rough → detailed)
- Dynamic scope adjustment
- Revision mechanism (reconsider conclusions)
- Branching for alternatives
- Explicit uncertainty handling

**Integration Points**:
- `/ccpm:planning:create` - Epic breakdown
- `/ccpm:spec:write` - Architecture sections
- `/ccpm:utils:insights` - Complexity analysis
- `/ccpm:verification:fix` - Root-cause analysis

**Example**:
```
User: "/ccpm:planning:create 'Payment Gateway' ..."
       ↓
Skill activates:
  Thought 1/6: Components needed...
  Thought 2/6: Dependencies...
  Thought 3/6: Sizing...
  Thought 4/6 (REVISION): Simplified scope...
  Thought 5/6: Task breakdown...
  Thought 6/6 (FINAL): Recommended structure...
```

---

### 4. docs-seeker

**Category**: Research
**Source**: ClaudeKit (as-is)
**Location**: `skills/docs-seeker/SKILL.md`

**Purpose**:
Discovers and researches documentation for libraries, frameworks, APIs, and technical concepts.

**Auto-Activates When**:
- "documentation", "API docs", "find guide" mentioned
- Running `/ccpm:spec:write` (needs library docs)
- Running `/ccpm:planning:plan` (technical research)
- Implementation questions about frameworks

**Key Features**:
- Official documentation first
- Version-specific search
- Context-aware (understands your stack)
- Integration with Context7 MCP
- Best practices from authoritative sources

**Integration Points**:
- `/ccpm:spec:write` - Research for spec sections
- `/ccpm:planning:plan` - Technical research phase
- Context7 MCP - Fetches latest documentation
- Works alongside sequential-thinking

**Example**:
```
User: "/ccpm:spec:write DOC-123 api-design"
       ↓
Skill activates: "Researching API design best practices...
  Found:
  - RESTful API guide (Microsoft)
  - GraphQL schema design (Apollo)
  - OpenAPI 3.1 spec
  Recommendations: [detailed guidance]"
```

---

### 5. ccpm-code-review

**Category**: Quality / Verification
**Source**: ClaudeKit (adapted)
**Location**: `skills/ccpm-code-review/SKILL.md`

**Purpose**:
Enforces verification gates before task completion. "No completion claims without evidence."

**Auto-Activates When**:
- "done", "complete", "ready to merge" mentioned
- Running `/ccpm:verification:verify`
- Running `/ccpm:complete:finalize`
- Before Linear status updates to "Done"

**Key Features**:
- Blocks completion without evidence
- Requires: tests passing, build successful, checklist complete
- Technical rigor over social comfort
- Linear verification status integration
- BitBucket PR quality enforcement

**Integration Points**:
- `/ccpm:verification:verify` - Pre-completion checks
- `/ccpm:complete:finalize` - Final gate before PR/Jira/Slack
- quality-gate hook - Post-implementation review
- external-system-safety - Confirmation for external writes

**Example**:
```
User: "I'm done with AUTH-123"
       ↓
Skill activates: "⚠️ VERIFICATION REQUIRED
  Need evidence:
  □ Tests passing?
  □ Build successful?
  □ Linear checklist complete?
  □ No blockers?

  Run /ccpm:verification:check first"
```

---

### 6. ccpm-debugging

**Category**: Quality / Troubleshooting
**Source**: ClaudeKit (adapted)
**Location**: `skills/ccpm-debugging/SKILL.md`

**Purpose**:
Systematic debugging with defense-in-depth approach and Linear integration.

**Auto-Activates When**:
- "error", "failing", "broken", "debug", "bug" mentioned
- Running `/ccpm:verification:fix`
- Tests failing during `/ccpm:verification:check`
- Build errors or runtime exceptions

**Key Features**:
- Defense-in-depth investigation (symptoms → root cause)
- Systematic process (observe, hypothesize, test, fix, verify)
- Updates Linear with findings automatically
- Blocker logging in Linear comments
- Root-cause tracing (not just symptoms)

**Integration Points**:
- `/ccpm:verification:fix` - Systematic debugging workflow
- `/ccpm:implementation:update` - Log findings to Linear
- ccpm-code-review - Verify fixes
- sequential-thinking - Structure complex debugging

**Example**:
```
User: "Tests are failing"
       ↓
Skill activates:
  Step 1: GATHER SYMPTOMS (3 failing tests)
  Step 2: ANALYZE FAILURES (pattern recognition)
  Step 3: FORM HYPOTHESES (4 possibilities)
  Step 4: TEST HYPOTHESES (systematic)
  Step 5: ROOT CAUSE (exact issue found)
  Step 6: FIX (applied)
  Step 7: VERIFY (tests passing)
  Step 8: UPDATE LINEAR (documented)
```

---

### 7. ccpm-mcp-management

**Category**: Infrastructure
**Source**: ClaudeKit (adapted)
**Location**: `skills/ccpm-mcp-management/SKILL.md`

**Purpose**:
Discovers, manages, and troubleshoots MCP servers required for CCPM.

**Auto-Activates When**:
- "MCP server", "tools available", "Linear not working" mentioned
- Running `/ccpm:utils:help`
- Plugin installation issues
- MCP connection failures

**Key Features**:
- Discovers all configured MCP servers
- Validates CCPM required servers (Linear, GitHub, Context7)
- Troubleshoots connection issues
- Configuration guidance
- Health monitoring

**Integration Points**:
- `/ccpm:utils:help` - Show available tools
- Plugin installation - Verify requirements
- All CCPM commands - Depend on MCP servers
- Troubleshooting - Fix connectivity issues

**Required Servers**:
- Linear MCP (task tracking)
- GitHub MCP (PR creation)
- Context7 MCP (documentation)

**Optional Servers**:
- Jira, Confluence, BitBucket, Slack (PM integrations)

**Example**:
```
User: "Linear tools not working"
       ↓
Skill activates:
  Step 1: CHECK CONNECTION (failed)
  Step 2: DIAGNOSE (missing API key)
  Step 3: VERIFY CONFIG (found config)
  Step 4: CHECK ENV (LINEAR_API_KEY not set)
  ROOT CAUSE: Missing environment variable
  FIX: Instructions to set API key
```

---

### 8. ccpm-skill-creator

**Category**: Meta / Development
**Source**: ClaudeKit (adapted)
**Location**: `skills/ccpm-skill-creator/SKILL.md`

**Purpose**:
Creates custom CCPM skills with proper templates and CCPM integration patterns.

**Auto-Activates When**:
- "create skill", "custom workflow", "team specific" mentioned
- User wants to codify team practices
- Building reusable PM patterns

**Key Features**:
- CCPM-specific skill templates
- Safety guardrails included
- Command/hook integration patterns
- Supporting documentation generation
- Team workflow codification

**Integration Points**:
- Skill development workflow
- Team customization
- Community contributions
- Plugin development

**Templates Provided**:
- Team workflow skill
- Safety enforcement skill
- Integration skill

**Example**:
```
User: "Create a skill for our deployment workflow"
       ↓
Skill activates:
  Questions about deployment process...
  Generates: skills/acme-deployment/SKILL.md
  Includes: Checklist, safety rules, Slack integration
  Tests activation
  Ready to use!
```

---

### 9. natural-workflow

**Category**: Workflow / Core PM
**Source**: CCPM-original (v2.3)
**Location**: `skills/natural-workflow/SKILL.md`

**Purpose**:
Comprehensive guide for CCPM's streamlined 6-command workflow (plan/work/sync/commit/verify/done). Provides step-by-step guidance for the complete development lifecycle from task creation to completion.

**Auto-Activates When**:
- "How do I start working on a task"
- "How do I commit my changes"
- "I'm done with my work"
- "What's the workflow"
- "Walk me through the process"
- "How do I use CCPM"

**Key Features**:
- Complete workflow lifecycle explanation (plan → work → sync → commit → verify → done)
- Auto-detection from git branch names
- Integrated examples for each command
- Token-optimized workflow (5-10 min, ~16k tokens vs 40-50 min, 50k+ tokens manual)
- Smart context fetching from Linear
- Progressive disclosure of complexity

**Integration Points**:
- All 6 natural workflow commands (`/ccpm:plan`, `/ccpm:work`, `/ccpm:sync`, `/ccpm:commit`, `/ccpm:verify`, `/ccpm:done`)
- Works with workflow-state-tracking for state validation
- Works with commit-assistant for conventional commits

**Example**:
```
User: "How do I start a new task?"
       ↓
Skill activates: "Use the natural workflow:
  1. /ccpm:plan 'Task description' - Create and plan
  2. /ccpm:work - Start implementation
  3. /ccpm:sync - Save progress
  4. /ccpm:commit - Create git commits
  5. /ccpm:verify - Quality checks
  6. /ccpm:done - Finalize and PR"
```

---

### 10. workflow-state-tracking

**Category**: Workflow / Core PM
**Source**: CCPM-original (v2.3)
**Location**: `skills/workflow-state-tracking/SKILL.md`

**Purpose**:
Tracks and visualizes CCPM workflow state transitions through 8-state machine (IDEA → PLANNED → IMPLEMENTING → VERIFYING → VERIFIED → COMPLETE). Prevents invalid state transitions and suggests appropriate next actions.

**Auto-Activates When**:
- "Where am I in the workflow"
- "What should I do next"
- "Can I do this now"
- "What's blocking me"
- "How much progress"
- "Show me the workflow"

**Key Features**:
- 8-state workflow state machine with validation
- Pre-condition checks for state transitions
- Confidence scoring (0-100) for transitions
- Invalid transition prevention with suggestions
- Progress visualization (0-100% completion)
- Blocker detection and resolution guidance

**Integration Points**:
- `/ccpm:utils:status` - Current state display
- `/ccpm:utils:dependencies` - Dependency visualization
- All natural workflow commands (validates state transitions)
- Linear custom fields for state persistence

**Example**:
```
User: "Can I mark this task as done?"
       ↓
Skill activates: "Current state: IMPLEMENTING (75% complete)
  ❌ Cannot transition to COMPLETE (invalid)

  Valid transitions:
  • VERIFYING (run /ccpm:verify first)
  • BLOCKED (if blocker found)

  Suggested: /ccpm:verify (85% confidence)"
```

---

### 11. commit-assistant

**Category**: Development
**Source**: CCPM-original (v2.3)
**Location**: `skills/commit-assistant/SKILL.md`

**Purpose**:
Provides conventional commits guidance and auto-generates commit messages from git changes. Integrates with `/ccpm:commit` for automated git commits linked to Linear issues.

**Auto-Activates When**:
- "Commit my changes"
- "Create a git commit"
- "How do I commit"
- "Conventional commits"
- "Commit message format"
- Running `/ccpm:commit`

**Key Features**:
- Conventional Commits format enforcement
- Auto-detects commit type (feat/fix/docs/refactor/test/chore/perf/style)
- Generates meaningful messages from code changes
- Links commits to Linear issues automatically
- Imperative mood validation
- Issue reference in commit footer

**Integration Points**:
- `/ccpm:commit` - Primary integration point
- `/ccpm:done` - Includes commit step
- natural-workflow - Part of workflow lifecycle
- Linear integration - Automatic issue linking

**Example**:
```
User: "/ccpm:commit"
       ↓
Skill activates:
  Branch: fix/PSN-123-jwt-expiration
  Files: src/auth/jwt.ts, test/auth/jwt.test.ts
  Type: fix (bug fix with tests)

  Generated commit:
  "fix(auth): prevent expired tokens from accessing API"

  Closes PSN-123
```

---

### 12. figma-integration

**Category**: Design / Core PM
**Source**: CCPM-original (v2.2)
**Location**: `skills/figma-integration/SKILL.md`

**Purpose**:
Guides design-to-code workflow using Figma integration. Extracts designs, analyzes components, and generates implementation specs from Figma files.

**Auto-Activates When**:
- "Figma" or "design" mentioned
- "Component", "design system", "design tokens"
- Running `/ccpm:planning:design-ui`
- Running `/ccpm:planning:design-refine`
- Running `/ccpm:planning:design-approve`
- Running `/ccpm:utils:figma-refresh`

**Key Features**:
- Automatic Figma link detection from Linear issues
- Component structure extraction
- Design token analysis (colors, typography, spacing)
- Implementation spec generation
- Design iteration workflow (design → refine → approve)
- 5-minute design cache with TTL
- Responsive design specifications

**Integration Points**:
- `/ccpm:planning:design-ui` - Start design process
- `/ccpm:planning:design-refine` - Iterate on designs
- `/ccpm:planning:design-approve` - Generate specs
- `/ccpm:utils:figma-refresh` - Refresh cache
- Linear Documents - Stores generated specs

**Example**:
```
User: "/ccpm:planning:design-ui PSN-100"
       ↓
Skill activates:
  ✅ Detected Figma link
  📦 Design Analysis:
     - 12 frames, 15 components
     - Color palette: 8 colors
     - Typography: 4 font families

  Generated specs → Linear Document
  Ready for implementation!
```

---

### 13. linear-subagent-guide

**Category**: Development
**Source**: CCPM-original (v2.3)
**Location**: `skills/linear-subagent-guide/SKILL.md`

**Purpose**:
Guides optimal Linear operations usage with caching, performance patterns, and error handling. Prevents usage of non-existent Linear MCP tools and provides 50-60% token reduction.

**Auto-Activates When**:
- Implementing CCPM commands that interact with Linear
- Linear operation errors occur
- Performance optimization needed for Linear calls
- Caching strategy questions

**Key Features**:
- Complete list of 23 validated Linear MCP tools
- Tool validation before usage
- Session-level caching (85-95% hit rates)
- Performance optimization (<50ms cached, vs 400-600ms direct)
- Structured error handling with suggestions
- Shared helper functions (getOrCreateLabel, getValidStateId, ensureLabelsExist)

**Integration Points**:
- `agents/linear-operations.md` - Linear subagent
- `agents/_shared-linear-helpers.md` - Helper functions
- All CCPM commands using Linear
- Linear MCP server

**Example**:
```
Command implementing Linear operation:
  ❌ DON'T: Direct MCP call
  Task(linear-operations): "Get issue PSN-29"

  ✅ DO: Via subagent with caching
  Task(ccpm:linear-operations): `
    operation: get_issue
    params:
      issueId: PSN-29
    context:
      cache: true
      command: "planning:plan"
  `

  Result: 50ms (cached) vs 400ms (direct)
```

---

### 14. hook-optimization

**Category**: Infrastructure
**Source**: CCPM-original (v2.3)
**Location**: `skills/hook-optimization/SKILL.md`

**Purpose**:
Provides guidance on optimizing CCPM hooks for performance and token efficiency. Includes caching strategies, token budgets, performance benchmarking, and best practices for sub-5-second hook execution.

**Auto-Activates When**:
- "Optimize hook"
- "Hook performance"
- "Benchmark hook"
- "Hook slow"
- "Debug hook"
- "Cache agent"
- "Hook tokens"

**Key Features**:
- Performance targets (UserPromptSubmit <5s, PreToolUse <1s, Stop <5s)
- Token budget guidance (<5,000 per hook)
- Cached agent discovery (96% faster with cache)
- Progressive disclosure patterns
- Benchmarking tools and metrics
- Hook development workflow
- Token optimization techniques (60-80% reduction)

**Integration Points**:
- `/scripts/benchmark-hooks.sh` - Performance testing
- `/scripts/discover-agents-cached.sh` - Cached discovery
- `/hooks/*-optimized.prompt` - Optimized hook files
- ccpm-skill-creator - For creating new hooks

**Example**:
```
User: "My hook is slow"
       ↓
Skill activates:
  Benchmarking your hook...

  Current: 8,200ms, 6,200 tokens
  Target:  <5,000ms, <5,000 tokens

  Issues detected:
  • No caching (use discover-agents-cached.sh)
  • Verbose comments (reduce by 70%)
  • Full examples (reference instead)

  Run: ./scripts/benchmark-hooks.sh
```

---

### 15. project-detection

**Category**: Infrastructure / Project-Specific
**Source**: CCPM-infrastructure (v2.0)
**Location**: `skills/project-detection/SKILL.md`

**Purpose**:
Automatic project context detection with priority-based resolution for monorepos. Detects project from git remote, subdirectory patterns, or manual settings.

**Auto-Activates When**:
- CCPM commands need project context
- Ambiguous project detection
- Monorepo navigation
- Project switching

**Key Features**:
- Priority-based resolution (Manual > Git remote > Subdirectory > Local path)
- Monorepo support with glob patterns
- Cache detection result for session
- Ambiguous detection handling (user clarification)
- Performance: <100ms auto-detection, 0ms manual

**Integration Points**:
- All CCPM commands (automatic project context)
- project-operations - Project management
- Linear integration - Project-specific issues

**Example**:
```
User: "/ccpm:plan 'Add feature'"
       ↓
Skill activates: Auto-detect project...
  Git remote: github.com/org/monorepo
  Current dir: /monorepo/frontend
  Pattern match: frontend/** → Frontend Project

  Context: 📂 Monorepo › Frontend
```

---

### 16. project-operations

**Category**: Infrastructure / Project-Specific
**Source**: CCPM-infrastructure (v2.0, updated v2.3)
**Location**: `skills/project-operations/SKILL.md`

**Purpose**:
Intelligent project setup and management with agent-based architecture. Provides templates for common project types and handles monorepo configuration.

**Auto-Activates When**:
- "Add project"
- "Configure project"
- "Monorepo"
- "Switch project"
- "Project info"

**Key Features**:
- Four project workflows (Add, Configure Monorepo, Switch, View Info)
- Templates for common architectures (fullstack-with-jira, linear-only, mobile-app, monorepo)
- Three specialized agents (project-detector, project-config-loader, project-context-manager)
- Configuration validation with fix suggestions
- Subdirectory support for monorepos with priority weighting

**Integration Points**:
- `/ccpm:project:add` - Add new project
- `/ccpm:project:set` - Switch active project
- `/ccpm:project:show` - View configuration
- `/ccpm:project:subdir:*` - Monorepo management
- project-detection - Auto-detection logic

**Example**:
```
User: "/ccpm:project:add my-app"
       ↓
Skill activates:
  Template: fullstack-with-jira

  Configuration created:
  • Linear team: MY-APP
  • Jira project: MYAPP
  • GitHub repo: org/my-app
  • Subdirectories: frontend/, backend/

  Project ready! Use: /ccpm:project:set my-app
```

---

## Skill Combinations

### Combination 1: Natural Workflow (NEW)

**Trigger**: User starting complete task workflow

**Skills activate**:
1. **natural-workflow** → Guides 6-command lifecycle
2. **workflow-state-tracking** → Validates state transitions
3. **commit-assistant** → Creates conventional commits
4. **pm-workflow-guide** → Suggests optimal next actions

**Result**: Smooth task completion from plan to PR with state validation

---

### Combination 2: Planning Workflow

**Trigger**: User starts planning a complex feature

**Skills activate**:
1. **pm-workflow-guide** → Suggests `/ccpm:planning:create`
2. **sequential-thinking** → Structures task breakdown
3. **docs-seeker** → Finds relevant technical documentation

**Result**: Comprehensive, well-researched plan

---

### Combination 3: Design-to-Code Workflow (NEW)

**Trigger**: User implementing from Figma designs

**Skills activate**:
1. **figma-integration** → Extracts design specs
2. **sequential-thinking** → Structures component breakdown
3. **natural-workflow** → Guides implementation process
4. **commit-assistant** → Creates design implementation commits

**Result**: Design-accurate implementation with proper workflow

---

### Combination 4: Verification Workflow

**Trigger**: User claims task is complete

**Skills activate**:
1. **ccpm-code-review** → Enforces verification checklist
2. **workflow-state-tracking** → Validates VERIFIED state
3. **external-system-safety** → Confirms PR/Jira/Slack writes
4. **pm-workflow-guide** → Suggests next action after completion

**Result**: Quality-gated, safely completed task

---

### Combination 5: Debugging Workflow

**Trigger**: Tests failing

**Skills activate**:
1. **ccpm-debugging** → Systematic troubleshooting
2. **sequential-thinking** → Structures root-cause analysis
3. **docs-seeker** → Finds debugging guides
4. **ccpm-code-review** → Verifies fix before completion

**Result**: Properly diagnosed, fixed, and verified issue

---

### Combination 6: Linear Operations Optimization (NEW)

**Trigger**: Implementing commands with Linear integration

**Skills activate**:
1. **linear-subagent-guide** → Optimizes Linear API calls
2. **pm-workflow-guide** → Suggests command workflow
3. **workflow-state-tracking** → Manages Linear custom fields

**Result**: 50-60% token reduction, <50ms cached operations

---

### Combination 7: Hook Development (NEW)

**Trigger**: Developer optimizing CCPM hooks

**Skills activate**:
1. **hook-optimization** → Performance guidance
2. **ccpm-skill-creator** → Create new hooks
3. **sequential-thinking** → Optimize complex logic

**Result**: Sub-5s hooks with 60-80% token reduction

---

### Combination 8: Setup/Troubleshooting

**Trigger**: CCPM not working properly

**Skills activate**:
1. **ccpm-mcp-management** → Diagnoses MCP issues
2. **pm-workflow-guide** → Suggests `/ccpm:utils:help`

**Result**: Working CCPM installation

---

## Skill Activation Map

### By CCPM Command

| Command | Auto-Activated Skills |
|---------|----------------------|
| `/ccpm:plan` | pm-workflow-guide, natural-workflow, sequential-thinking, docs-seeker |
| `/ccpm:work` | pm-workflow-guide, natural-workflow, workflow-state-tracking |
| `/ccpm:sync` | natural-workflow, linear-subagent-guide |
| `/ccpm:commit` | commit-assistant, natural-workflow |
| `/ccpm:verify` | ccpm-code-review, workflow-state-tracking, natural-workflow |
| `/ccpm:done` | ccpm-code-review, external-system-safety, workflow-state-tracking, natural-workflow |
| `/ccpm:planning:create` | pm-workflow-guide, sequential-thinking, docs-seeker |
| `/ccpm:planning:plan` | pm-workflow-guide, sequential-thinking, docs-seeker, linear-subagent-guide |
| `/ccpm:planning:design-ui` | figma-integration |
| `/ccpm:planning:design-refine` | figma-integration |
| `/ccpm:planning:design-approve` | figma-integration |
| `/ccpm:spec:write` | sequential-thinking, docs-seeker |
| `/ccpm:spec:review` | ccpm-code-review (for spec quality) |
| `/ccpm:implementation:start` | pm-workflow-guide, linear-subagent-guide |
| `/ccpm:implementation:next` | pm-workflow-guide, workflow-state-tracking |
| `/ccpm:implementation:sync` | linear-subagent-guide |
| `/ccpm:verification:check` | ccpm-debugging (if failures) |
| `/ccpm:verification:fix` | ccpm-debugging, sequential-thinking |
| `/ccpm:verification:verify` | ccpm-code-review, workflow-state-tracking |
| `/ccpm:complete:finalize` | ccpm-code-review, external-system-safety, pm-workflow-guide |
| `/ccpm:utils:help` | ccpm-mcp-management, pm-workflow-guide |
| `/ccpm:utils:insights` | sequential-thinking |
| `/ccpm:utils:status` | workflow-state-tracking |
| `/ccpm:utils:dependencies` | workflow-state-tracking |
| `/ccpm:utils:figma-refresh` | figma-integration |
| `/ccpm:project:*` | project-operations, project-detection |

### By User Intent

| User Says | Skills Activate |
|-----------|----------------|
| "How do I start a task" | natural-workflow, pm-workflow-guide |
| "Walk me through the workflow" | natural-workflow |
| "Where am I in the workflow" | workflow-state-tracking |
| "What should I do next" | workflow-state-tracking, pm-workflow-guide |
| "Plan this task" | pm-workflow-guide, sequential-thinking |
| "Commit my changes" | commit-assistant |
| "I'm done" | ccpm-code-review, external-system-safety, workflow-state-tracking |
| "Tests failing" | ccpm-debugging |
| "Find docs for X" | docs-seeker |
| "Figma design" | figma-integration |
| "Linear not working" | ccpm-mcp-management |
| "Optimize Linear calls" | linear-subagent-guide |
| "Hook is slow" | hook-optimization |
| "Create custom skill" | ccpm-skill-creator |
| "Update Jira" | external-system-safety |
| "Add project" | project-operations, project-detection |

---

## Skill Interaction Matrix

| Skill A | Skill B | Relationship | Example |
|---------|---------|--------------|---------|
| ccpm-code-review | external-system-safety | Sequential | Verify → Confirm → Complete |
| sequential-thinking | pm-workflow-guide | Complementary | Structure thinking → Suggest command |
| ccpm-debugging | ccpm-code-review | Sequential | Fix issue → Verify fix |
| docs-seeker | sequential-thinking | Complementary | Research → Structure knowledge |
| docs-seeker | Context7 MCP | Integration | Find docs → Fetch content |
| ccpm-mcp-management | All skills | Foundation | MCP works → All skills work |

---

## Usage Tips

### For New Users

1. **Start with pm-workflow-guide**: Ask "what command should I use?"
2. **Trust skill suggestions**: Skills activate based on context
3. **Learn trigger phrases**: See "Auto-Activates When" for each skill
4. **Combine with commands**: Skills enhance, don't replace commands

### For Power Users

1. **Create custom skills**: Use ccpm-skill-creator for team workflows
2. **Understand skill combos**: Multiple skills work together
3. **Leverage sequential-thinking**: For complex planning/debugging
4. **Use docs-seeker proactively**: Research before implementing

### For Teams

1. **Standardize workflows**: Create team-specific skills
2. **Share skills**: Commit to `.claude/skills/` in git
3. **Document practices**: Skills codify tribal knowledge
4. **Review skill activations**: Ensure skills help, not hinder

---

## Troubleshooting

### Skill Not Activating

**Check**:
1. Are you using trigger phrases? (See "Auto-Activates When")
2. Is skill description clear? (See SKILL.md frontmatter)
3. Try verbose mode: `claude --verbose`

**Example**:
```
❌ Vague: "Help me"
✅ Specific: "I'm done with this task" → ccpm-code-review activates
```

### Too Many Skills Activating

**This is normal!** Skills are designed to work together.

**Example**:
```
"Plan complex feature"
  → pm-workflow-guide (command suggestion)
  → sequential-thinking (structure breakdown)
  → docs-seeker (research)

All three help create better plan.
```

### Skill Conflicts

Skills are designed to be complementary, but if you notice conflicts:
1. Review individual SKILL.md files
2. Check trigger phrases overlap
3. Report issue with specific scenario

---

## Extending CCPM Skills

### Create Team Skill

```bash
# Ask Claude
"Create a skill for our [workflow]"

# ccpm-skill-creator generates
skills/[team]-[workflow]/SKILL.md

# Commit to project
git add skills/[team]-[workflow]/
git commit -m "Add team skill"

# Team gets skill
git pull
```

### Create Company Skill

```bash
# Create in personal skills
mkdir ~/.claude/skills/company-[name]/

# Or create shared repo
# company-claude-skills/
# Team members symlink/copy
```

### Contribute to CCPM

```bash
# Create skill following CCPM conventions
# Open PR to CCPM repository
# Skill reviewed and merged
# Available to all CCPM users
```

---

## Resources

- **Skills Guide**: `skills/README.md`
- **Integration Plan**: `CLAUDEKIT_SKILLS_INTEGRATION_PLAN.md`
- **Comparison Matrix**: `SKILLS_COMPARISON_MATRIX.md`
- **Quick Reference**: `SKILLS_QUICK_REFERENCE.md`
- **Individual Skills**: `skills/*/SKILL.md`

---

**Last Updated**: 2025-11-21
**Total Skills**: 16
**Status**: Phase 2 & 3 Complete ✅ (PSN-34)
**Version**: CCPM v2.3
**Next**: User feedback, additional skill refinements
