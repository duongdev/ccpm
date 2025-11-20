# CCPM Skills Architecture

## Component Interaction Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER REQUEST                                 │
│                  "I need to plan this task"                          │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    CLAUDE CODE PROCESSING                            │
└─────┬───────────────────────┬───────────────────────┬───────────────┘
      │                       │                       │
      │                       │                       │
      ▼                       ▼                       ▼
┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│   SKILLS    │      │    HOOKS     │      │    COMMANDS     │
│ (Automatic) │      │ (Event-Based)│      │   (Explicit)    │
└──────┬──────┘      └──────┬───────┘      └────────┬────────┘
       │                    │                       │
       │ pm-workflow-guide  │ smart-agent-selector  │ /ccpm:planning:create
       │ external-system-   │ tdd-enforcer          │ /ccpm:spec:create
       │   safety           │ quality-gate          │ /ccpm:implementation:*
       │ spec-first-dev     │                       │ /ccpm:verification:*
       │ tdd-practices      │                       │ ... (27 total)
       │                    │                       │
       ▼                    ▼                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      CLAUDE'S RESPONSE                               │
│                                                                      │
│  Skills suggest:      Hooks inject:       Commands execute:         │
│  "Use /ccpm:         Auto-invoke          Fetch Jira context        │
│   planning:create"   backend-architect    Create Linear issue       │
│                      Require tests        Generate plan             │
│                      Run code review      Update checklist          │
│                                                                      │
│  Combined result: Intelligent guidance + Safety + Execution         │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
                      ┌─────────────┐
                      │   AGENTS    │
                      │ (Delegation)│
                      └──────┬──────┘
                             │
                             │ backend-architect
                             │ frontend-developer
                             │ tdd-orchestrator
                             │ code-reviewer
                             │ security-auditor
                             │ ... (many more)
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      TASK COMPLETION                                 │
└─────────────────────────────────────────────────────────────────────┘
```

## Skills Layer Detail

```
┌──────────────────────────────────────────────────────────────────┐
│                        SKILLS LAYER                               │
│                     (Background Knowledge)                        │
└───────┬──────────────────┬──────────────────┬────────────────────┘
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐  ┌─────────────────┐  ┌────────────────────┐
│   Workflow    │  │     Safety      │  │   Best Practices   │
│   Guidance    │  │   Enforcement   │  │    Education       │
└───────────────┘  └─────────────────┘  └────────────────────┘
        │                  │                  │
        │                  │                  │
   ┌────┴─────┐       ┌────┴────┐       ┌────┴─────┐
   │          │       │         │       │          │
   ▼          ▼       ▼         ▼       ▼          ▼
pm-workflow-  spec-  external- audit-  tdd-     coding-
guide         first- system-   trail   practices standards
              dev    safety
```

## Execution Flow Examples

### Example 1: Planning a New Task

```
User: "I need to plan the authentication feature"
   │
   ├─→ [SKILL: pm-workflow-guide] AUTO-ACTIVATES
   │   Detects: "plan" + "feature" → Planning phase
   │   Suggests: /ccpm:planning:create or /ccpm:spec:create
   │
   ├─→ [SKILL: spec-first-development] AUTO-ACTIVATES
   │   Detects: "authentication feature" → Complex feature
   │   Recommends: Create spec first
   │
   └─→ Claude's Response:
       "This is a complex feature. I recommend:
        1. /ccpm:spec:create epic 'Authentication'
        2. /ccpm:spec:write [doc-id] (architecture, security sections)
        3. /ccpm:planning:create after spec is complete

        Shall we start with the spec?"

User: "/ccpm:spec:create epic 'Authentication System'"
   │
   └─→ [COMMAND] EXECUTES
       1. Creates Linear epic
       2. Creates Linear document
       3. Links them together
       4. Populates template

       → Result: Spec ready for writing
```

### Example 2: Preventing Accidental External Write

```
User: "Update Jira ABC-123 to Done"
   │
   ├─→ [SKILL: external-system-safety] AUTO-ACTIVATES
   │   Detects: "Update Jira" → External system write
   │   Required: Confirmation workflow
   │
   └─→ Claude's Response:
       "⚠️ EXTERNAL SYSTEM WRITE DETECTED

       System: Jira
       Operation: Update Status
       Target: ABC-123
       Change: [Current] → Done

       Proceed? (yes/no)"

User: "yes"
   │
   └─→ [MCP TOOL] EXECUTES
       jira_update_issue(ABC-123, status: Done)

       → Result: Jira updated with user consent
```

### Example 3: TDD Workflow with Dual Enforcement

```
User: "Let's implement the login function"
   │
   ├─→ [SKILL: tdd-practices] AUTO-ACTIVATES
   │   Detects: "implement" → Implementation phase
   │   Reminds: TDD workflow (Red-Green-Refactor)
   │
   └─→ Claude's Response:
       "Following TDD, I'll:
        1. Write failing test first
        2. Implement minimal code to pass
        3. Refactor

        Starting with tests..."

Claude: [Attempts to write src/auth/login.ts]
   │
   └─→ [HOOK: tdd-enforcer] TRIGGERS (PreToolUse)
       Checks: Does src/auth/login.test.ts exist?
       Result: NO

       → BLOCKS Write operation
       → Auto-invokes tdd-orchestrator agent
       → Agent creates test file first

Agent: [Creates src/auth/login.test.ts with failing test]
   │
   └─→ [HOOK] ALLOWS Write now
       Tests exist ✓

       → Proceeds with implementation

Result: Tests created first (enforced), developer educated (skill)
```

### Example 4: Complete Workflow with All Components

```
User: "I need to build a payment gateway integration"
   │
   │ ┌─────────────────── SKILLS ACTIVATE ───────────────────┐
   │ │                                                        │
   │ ├─→ pm-workflow-guide: Suggests /ccpm:spec:create       │
   │ ├─→ spec-first-development: Complex feature needs spec  │
   │ └─→ tdd-practices: Reminds about test-first approach   │
   │                                                          │
   └─→ Claude: "Complex feature detected. Let's start with spec..."

User: "/ccpm:spec:create epic 'Payment Gateway Integration'"
   │
   │ ┌─────────────────── HOOK ACTIVATES ────────────────────┐
   │ │                                                        │
   │ └─→ smart-agent-selector: Scores agents                 │
   │     backend-architect: 85 (payment systems expertise)   │
   │     security-auditor: 90 (payment security critical)    │
   │                                                          │
   └─→ COMMAND EXECUTES
       1. Creates Linear epic
       2. Creates document
       3. Invokes recommended agents

       Result: Epic + Document created

User: "Write the architecture section"
   │
   └─→ COMMAND: /ccpm:spec:write [doc-id] architecture
       │
       ├─→ Fetches latest Stripe docs (Context7)
       ├─→ Invokes backend-architect agent
       └─→ Writes comprehensive architecture section

User: "Now let's implement it"
   │
   │ ┌─────────────────── SKILLS ACTIVATE ───────────────────┐
   │ │                                                        │
   │ ├─→ spec-first-development: ✓ Spec exists              │
   │ ├─→ pm-workflow-guide: Suggests /ccpm:implementation:   │
   │ │                         start                         │
   │ └─→ tdd-practices: Reminds about tests                  │
   │                                                          │
   └─→ COMMAND: /ccpm:implementation:start [issue-id]
       │
       ├─→ Loads task context
       ├─→ Identifies subtasks
       ├─→ Assigns agents
       │   - backend-architect → API design
       │   - security-auditor → Payment security
       │   - tdd-orchestrator → Test strategy
       │
       └─→ Starts implementation

Claude: [Writes production code]
   │
   │ ┌─────────────────── HOOK ACTIVATES ────────────────────┐
   │ │                                                        │
   │ └─→ tdd-enforcer (PreToolUse): Checks for tests         │
   │     → BLOCKS if tests missing                           │
   │     → Auto-invokes tdd-orchestrator                     │
   │                                                          │
   └─→ Tests created first, then production code

User: "I'm done coding"
   │
   │ ┌─────────────────── SKILL ACTIVATES ───────────────────┐
   │ │                                                        │
   │ └─→ pm-workflow-guide: Suggests verification workflow   │
   │                                                          │
   └─→ COMMAND: /ccpm:verification:check [issue-id]
       Runs linting, tests, build

User: "All checks passed, ready to ship"
   │
   │ ┌─────────────────── SKILL ACTIVATES ───────────────────┐
   │ │                                                        │
   │ └─→ external-system-safety: Detects PR + Jira + Slack   │
   │                             write operations            │
   │                                                          │
   └─→ COMMAND: /ccpm:complete:finalize [issue-id]
       │
       │ Step 1: Create BitBucket PR
       │ ┌────────────────────────────────────────┐
       │ │ external-system-safety ACTIVATES       │
       │ │ "Create PR on BitBucket? (yes/no)"     │
       │ └────────────────────────────────────────┘
       User: "yes"
       │
       │ Step 2: Update Jira status
       │ ┌────────────────────────────────────────┐
       │ │ external-system-safety ACTIVATES       │
       │ │ "Update Jira ABC-123 to Done? (yes/no)"│
       │ └────────────────────────────────────────┘
       User: "yes"
       │
       │ Step 3: Send Slack notification
       │ ┌────────────────────────────────────────┐
       │ │ external-system-safety ACTIVATES       │
       │ │ "Post to #engineering? (yes/no)"       │
       │ └────────────────────────────────────────┘
       User: "yes"
       │
       └─→ All steps completed with user consent

   │ ┌─────────────────── HOOK ACTIVATES ────────────────────┐
   │ │                                                        │
   │ └─→ quality-gate (Stop): Runs final code review         │
   │     Auto-invokes code-reviewer agent                    │
   │                                                          │
   └─→ Final review complete, task shipped! 🚀
```

## Component Comparison Matrix

| Aspect | Skills | Commands | Hooks | Agents |
|--------|--------|----------|-------|--------|
| **Trigger** | Context keywords | User types `/` | System events | Explicit or proactive |
| **Timing** | During request processing | After user input | Pre/Post/Submit events | During command execution |
| **Purpose** | Guidance & detection | Workflow orchestration | Enforcement & automation | Specialized execution |
| **User Awareness** | Background | Fully visible | Mostly transparent | Delegated work |
| **Can Block?** | ❌ No | ✅ Yes (interactive) | ✅ Yes (PreToolUse) | ❌ No |
| **Can Execute Tools?** | ✅ Yes (if allowed) | ✅ Yes | ⚠️ Limited | ✅ Yes |
| **Bypassed by Agents?** | ❌ No (always active) | ✅ Yes | ❌ No | N/A |
| **Response Time** | Immediate | User-paced | Fast (<5s) | Variable |
| **Configuration** | SKILL.md | command.md | hooks.json | YAML frontmatter |

## Layered Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                    EXTERNAL SYSTEM WRITE                     │
│                                                              │
│  Example: Update Jira ticket status                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
         ┌───────────────────────────────┐
         │   Layer 1: SKILL DETECTION    │
         │   external-system-safety      │
         │   Detects intent, shows       │
         │   preview, asks confirmation  │
         └───────────────┬───────────────┘
                         │ User: "yes"
                         ▼
         ┌───────────────────────────────┐
         │   Layer 2: COMMAND SAFETY     │
         │   /ccpm:utils:sync-status     │
         │   Built-in confirmation       │
         │   checks per SAFETY_RULES.md  │
         └───────────────┬───────────────┘
                         │ Confirmed
                         ▼
         ┌───────────────────────────────┐
         │   Layer 3: MCP TOOL EXECUTION │
         │   jira_update_issue()         │
         │   Actual external API call    │
         └───────────────┬───────────────┘
                         │
                         ▼
         ┌───────────────────────────────┐
         │   Layer 4: AUDIT LOG          │
         │   Log operation to            │
         │   .claude/audit-log.json      │
         └───────────────────────────────┘

Result: Defense in depth - multiple layers of protection
```

## Skills + Hooks Synergy

### Synergy Pattern: Education + Enforcement

```
┌─────────────────────────────────────────────────────────┐
│  SKILL: tdd-practices                                   │
│  Purpose: Educates developer on TDD workflow            │
│  Provides: Red-Green-Refactor guidance                  │
│  Explains: Why tests first, how to structure tests      │
└────────────────────┬────────────────────────────────────┘
                     │ Works with
                     ▼
┌─────────────────────────────────────────────────────────┐
│  HOOK: tdd-enforcer                                     │
│  Purpose: Enforces test-first development               │
│  Blocks: Write/Edit without corresponding tests         │
│  Auto-invokes: tdd-orchestrator agent                   │
└─────────────────────────────────────────────────────────┘

Combined Effect:
✅ Developer understands WHY (skill education)
✅ Developer prevented from mistakes (hook enforcement)
✅ Developer learns correct pattern (skill examples)
✅ Developer cannot bypass rule (hook blocking)

= Better developer experience + Guaranteed compliance
```

### Synergy Pattern: Detection + Selection

```
┌─────────────────────────────────────────────────────────┐
│  SKILL: pm-workflow-guide                               │
│  Purpose: Detects workflow phase                        │
│  Suggests: Appropriate commands                         │
│  Context: User's natural language request               │
└────────────────────┬────────────────────────────────────┘
                     │ Complements
                     ▼
┌─────────────────────────────────────────────────────────┐
│  HOOK: smart-agent-selector                             │
│  Purpose: Scores and selects best agents                │
│  Injects: Agent invocation instructions                 │
│  Context: Command execution phase                       │
└─────────────────────────────────────────────────────────┘

Combined Effect:
✅ User gets command suggestions (skill)
✅ User invokes suggested command
✅ Hook selects best agents for command (hook)
✅ Optimal agent auto-invoked

= Seamless workflow from request to execution
```

## Skills Directory Structure

```
ccpm/
├── skills/                           ← NEW: Skills directory
│   │
│   ├── external-system-safety/       ← Priority 1: Critical safety
│   │   ├── SKILL.md                 (Auto-detects external writes)
│   │   └── safety-checklist.md      (Reference doc)
│   │
│   ├── pm-workflow-guide/            ← Priority 2: Developer experience
│   │   └── SKILL.md                 (Context-aware command suggestions)
│   │
│   ├── spec-first-development/       ← Priority 3: Best practices
│   │   ├── SKILL.md                 (Encourages spec creation)
│   │   ├── spec-template.md         (Linear document template)
│   │   └── section-checklist.md     (Required sections)
│   │
│   └── tdd-practices/                ← Priority 4: Education
│       ├── SKILL.md                 (TDD workflow guidance)
│       ├── patterns.md              (Common TDD patterns)
│       └── test-structure.md        (Test organization)
│
├── commands/                         ← Existing: 27 slash commands
├── hooks/                            ← Existing: Event-based automation
├── agents/                           ← Existing: Specialized assistants
├── scripts/                          ← Existing: Utilities
└── .claude-plugin/
    └── plugin.json                   ← Updated: Includes skills config
```

## Summary: Why Skills Matter for CCPM

### Problems Solved

1. **Command Discovery** → pm-workflow-guide auto-suggests commands
2. **Accidental External Writes** → external-system-safety provides safety net
3. **Workflow Adherence** → spec-first-development encourages best practices
4. **TDD Compliance** → tdd-practices educates while hook enforces

### Architecture Benefits

- ✅ **Additive**: No breaking changes to existing workflows
- ✅ **Complementary**: Skills + Hooks + Commands work together
- ✅ **Scalable**: Easy to add new skills as needs emerge
- ✅ **Maintainable**: Skills reference existing docs (DRY principle)
- ✅ **User-Friendly**: Reduces cognitive load and learning curve

### Implementation Status

- ✅ Phase 1 Complete: 2 high-priority skills implemented
- 🔄 Phase 2 Pending: 2 additional skills planned
- 🔄 Testing: Manual and automated testing in progress
- 🔄 Documentation: README and CLAUDE.md updates pending

---

**Next Steps**: Test implemented skills → Gather feedback → Implement remaining skills → Update documentation → Release to users
