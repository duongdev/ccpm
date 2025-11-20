# Skills Integration Proposal for CCPM

## Executive Summary

This document analyzes how Claude Code **skills** can complement CCPM's existing architecture (commands, hooks, agents) to provide better developer experience through automatic discovery and context-aware assistance.

**Key Finding**: Skills are **model-invoked** (automatic) capabilities that Claude discovers and uses autonomously, making them ideal for:
- Background knowledge and guidance
- Auto-detection of PM workflows
- Safety guardrails and best practices
- Context-aware assistance

They are **complementary** to CCPM's existing components, not replacements.

---

## Understanding Skills vs. Existing CCPM Components

### Component Comparison Matrix

| Feature | Skills | Commands | Hooks | Agents |
|---------|--------|----------|-------|--------|
| **Invocation** | Automatic (model-driven) | Manual (user types `/`) | Event-triggered | Explicit or proactive |
| **Discovery** | Claude recognizes need | User knows command name | System events | Agent description matching |
| **Structure** | SKILL.md + supporting files | Single .md file | Prompt/script files | YAML frontmatter + markdown |
| **User Control** | Background, automatic | Explicit, full control | Transparent automation | Delegated execution |
| **Use in CCPM** | Context & guidance | Workflow execution | Quality enforcement | Heavy lifting |

### Why CCPM Currently Uses Commands/Hooks/Agents

**Commands** (27 total):
- ✅ Explicit user control for safety-critical operations
- ✅ Interactive mode with smart next actions
- ✅ Confirmation gates for external system writes
- ✅ Clear workflow orchestration

**Hooks** (3 active):
- ✅ Automatic agent selection (`smart-agent-selector.prompt`)
- ✅ TDD enforcement (`tdd-enforcer.prompt`)
- ✅ Quality gates (`quality-gate.prompt`)
- ✅ Pre/post task automation

**Agents** (custom + plugin):
- ✅ Specialized task execution
- ✅ Complex multi-step workflows
- ✅ Domain expertise (backend, frontend, TDD, security)

---

## Skills Integration Opportunities

### 1. PM Workflow Context & Guidance (HIGH VALUE)

**Skill**: `pm-workflow-guide`

**Problem it solves**:
- Users forget which command to use for their current task
- New team members need onboarding to CCPM workflows
- Context switching between task phases (planning → implementation → verification)

**How it works**:
```yaml
---
name: pm-workflow-guide
description: Provides project management workflow guidance for Linear-based development. Auto-activates when discussing task planning, implementation tracking, spec management, or quality verification. Suggests appropriate CCPM commands based on current context.
---

# PM Workflow Guide

## Instructions

This skill helps Claude automatically recognize PM workflow phases and suggest appropriate CCPM commands.

### Phase Detection

**Planning Phase** (user mentions: "plan this task", "create epic", "write spec"):
- Suggest `/ccpm:planning:create` for new tasks
- Suggest `/ccpm:spec:create` for epics/features
- Suggest `/ccpm:planning:plan` for gathering context

**Implementation Phase** (user mentions: "start coding", "implement feature"):
- Suggest `/ccpm:implementation:start` to begin work
- Suggest `/ccpm:implementation:next` for smart next action
- Remind about TDD requirements

**Verification Phase** (user mentions: "done", "ready to test", "review"):
- Suggest `/ccpm:verification:check` for quality checks
- Suggest `/ccpm:verification:verify` for final review
- Remind about Jira sync requirements

**Completion Phase** (user mentions: "merge", "ship it", "deploy"):
- Suggest `/ccpm:complete:finalize` for PR creation
- Remind about Slack notifications
- Check for pending verifications

### Smart Suggestions

See [Workflow Decision Tree](./workflow-tree.md) for complete logic.
```

**Value**:
- ✅ Reduces cognitive load ("what command should I use?")
- ✅ Auto-suggests next actions without manual lookup
- ✅ Onboards new developers faster
- ✅ Keeps workflow context visible

**Implementation**:
```bash
mkdir -p skills/pm-workflow-guide
touch skills/pm-workflow-guide/SKILL.md
touch skills/pm-workflow-guide/workflow-tree.md
```

---

### 2. Safety Guardrails Skill (CRITICAL VALUE)

**Skill**: `external-system-safety`

**Problem it solves**:
- Prevents accidental writes to Jira/Confluence/Slack/BitBucket
- Enforces confirmation workflow automatically
- Provides safety context even when using agents

**How it works**:
```yaml
---
name: external-system-safety
description: Enforces safety rules for external PM system writes (Jira, Confluence, BitBucket, Slack). Auto-activates when Claude detects potential writes to external systems. Requires explicit user confirmation before any write operation.
allowed-tools: read-file
---

# External System Safety Guardrails

## Instructions

**⛔ ABSOLUTE RULES - NEVER VIOLATED**

### Before ANY write to external systems:

1. **Detect the Operation**
   - Jira: Creating issues, updating status, posting comments
   - Confluence: Creating/editing pages
   - BitBucket: Creating PRs, posting comments
   - Slack: Sending messages, posting notifications

2. **STOP and Confirm**
   - Display exactly what will be written
   - Show target system and location
   - Wait for explicit user confirmation ("yes", "confirm", "proceed")
   - NEVER assume approval

3. **Only Then Execute**
   - After receiving explicit "yes"
   - Log the operation
   - Provide confirmation of success

### Always Allowed (No confirmation needed)

✅ Read operations: Fetching, searching, viewing
✅ Linear operations: Internal tracking only
✅ Local file operations: .claude/ directory, codebase files

### Example Confirmation Flow

```
Claude: I need to update Jira ticket ABC-123 with the following:
---
Status: In Progress → Done
Comment: "Implementation complete. Tests passing."
---
Proceed? (yes/no)

User: yes

Claude: ✅ Updated Jira ABC-123
```

## Reference

See [SAFETY_RULES.md](../../commands/SAFETY_RULES.md) for complete rules.
```

**Value**:
- ✅ Prevents accidental external writes
- ✅ Works even when agents are invoked
- ✅ Provides consistent safety layer
- ✅ Reduces risk of unintended side effects

**Integration with existing**:
- Complements `commands/SAFETY_RULES.md`
- Works alongside command-level safety checks
- Provides additional layer when agents bypass commands

---

### 3. Spec-First Development Guide (MEDIUM VALUE)

**Skill**: `spec-first-development`

**Problem it solves**:
- Developers skip spec creation
- Spec documents drift from implementation
- Missing required spec sections

**How it works**:
```yaml
---
name: spec-first-development
description: Guides spec-first development workflow using Linear Documents. Auto-activates when creating epics/features or when implementation lacks spec. Ensures comprehensive specs before implementation.
---

# Spec-First Development Guide

## Instructions

Enforces spec-first workflow for all non-trivial features.

### When to Activate

**Trigger phrases**:
- "Create epic/feature for..."
- "Let's implement [complex feature]"
- User starts implementation without mentioning spec

### Workflow Enforcement

1. **Check for Spec**
   - Does Linear issue have attached document?
   - Is spec comprehensive (all required sections)?
   - Is spec up-to-date with implementation?

2. **If Missing, Suggest**:
   ```
   ⚠️ This feature needs a spec document first.

   Recommended workflow:
   1. /ccpm:spec:create epic "Feature Name"
   2. /ccpm:spec:write [doc-id] (all sections)
   3. /ccpm:spec:review [doc-id] (ensure A/B grade)
   4. /ccpm:spec:break-down [doc-id]
   5. Then start implementation
   ```

3. **If Exists, Verify Completeness**:
   - Requirements ✓
   - Architecture ✓
   - API Design ✓
   - Data Model ✓
   - Testing Strategy ✓
   - Security Considerations ✓

### Required Spec Sections

See [Spec Template](./spec-template.md) for details.

## Benefits

- Prevents scope creep
- Ensures alignment before coding
- Documents decisions
- Facilitates code review
```

**Value**:
- ✅ Encourages spec-first culture
- ✅ Auto-detects missing specs
- ✅ Reduces implementation rework
- ✅ Improves documentation quality

---

### 4. TDD Best Practices Skill (MEDIUM VALUE)

**Skill**: `tdd-practices`

**Problem it solves**:
- Developers forget TDD workflow
- Test files not created properly
- Red-Green-Refactor cycle not followed

**How it works**:
```yaml
---
name: tdd-practices
description: Enforces Test-Driven Development best practices and Red-Green-Refactor workflow. Auto-activates when writing production code. Ensures tests exist before implementation.
---

# TDD Best Practices

## Instructions

Complements `tdd-enforcer.prompt` hook by providing guidance.

### Red-Green-Refactor Cycle

1. **RED**: Write failing test first
   - Test should fail for the right reason
   - Verify test actually runs and fails

2. **GREEN**: Write minimal code to pass
   - Only enough to make test pass
   - No premature optimization

3. **REFACTOR**: Clean up code
   - Remove duplication
   - Improve clarity
   - Maintain passing tests

### Test File Conventions

**File naming**:
- `src/utils/helper.ts` → `src/utils/helper.test.ts`
- `src/components/Button.tsx` → `src/components/Button.test.tsx`

**Test structure**:
```typescript
describe('ComponentOrFunction', () => {
  describe('specificBehavior', () => {
    it('should do expected thing', () => {
      // Arrange
      // Act
      // Assert
    })
  })
})
```

### Integration with Hook

This skill provides guidance. The `tdd-enforcer.prompt` hook provides enforcement:
- Hook blocks Write/Edit if tests missing
- Skill explains WHY and HOW to write tests
- Hook auto-invokes tdd-orchestrator
- Skill provides test structure guidance

## Common Patterns

See [TDD Patterns](./patterns.md) for examples.
```

**Value**:
- ✅ Reinforces TDD culture
- ✅ Educates developers on TDD workflow
- ✅ Complements existing hook enforcement
- ✅ Reduces "why is this blocked?" confusion

---

### 5. Agent Selection Context (LOW VALUE - Already handled by hook)

**Assessment**: The existing `smart-agent-selector.prompt` hook already handles agent selection through scoring algorithm. A skill would be redundant here.

**Keep using hook because**:
- Hooks trigger on `UserPromptSubmit` event (perfect timing)
- Hook runs `discover-agents.sh` for dynamic agent discovery
- Hook injects agent invocation instructions
- Skills can't execute shell scripts or modify prompt context

**Conclusion**: ❌ Don't create agent-selection skill. Hook is superior for this use case.

---

## Recommended Implementation Roadmap

### Phase 1: Critical Safety (Week 1)

1. **Create `external-system-safety` skill**
   - Highest priority for preventing accidents
   - Complements existing SAFETY_RULES.md
   - Provides automatic enforcement layer

**Files to create**:
```
skills/external-system-safety/
├── SKILL.md
└── safety-checklist.md (reference from commands/SAFETY_RULES.md)
```

**Testing**:
```bash
# Test skill discovery
claude --verbose
# Should show "external-system-safety" in loaded skills

# Test auto-activation
# Try: "Update Jira ticket ABC-123 with status Done"
# Claude should auto-detect and require confirmation
```

### Phase 2: Workflow Guidance (Week 2)

2. **Create `pm-workflow-guide` skill**
   - Helps with command discovery
   - Reduces cognitive load
   - Improves onboarding experience

**Files to create**:
```
skills/pm-workflow-guide/
├── SKILL.md
├── workflow-tree.md (decision tree for command selection)
└── phase-detection.md (how to detect current workflow phase)
```

3. **Create `spec-first-development` skill**
   - Encourages spec creation
   - Auto-detects missing specs
   - Provides workflow guidance

**Files to create**:
```
skills/spec-first-development/
├── SKILL.md
├── spec-template.md (Linear Document template)
└── section-checklist.md (required spec sections)
```

### Phase 3: Development Best Practices (Week 3)

4. **Create `tdd-practices` skill**
   - Complements tdd-enforcer.prompt hook
   - Provides educational context
   - Explains TDD workflow

**Files to create**:
```
skills/tdd-practices/
├── SKILL.md
├── patterns.md (common TDD patterns)
└── test-structure.md (test organization guidance)
```

### Phase 4: Documentation & Updates

5. **Update plugin.json**:
```json
{
  "components": {
    "commands": "./commands",
    "agents": "./agents",
    "hooks": "./hooks",
    "scripts": "./scripts",
    "skills": "./skills"  // Add this
  },
  "features": [
    // ... existing features ...
    "Skill: PM workflow guidance",
    "Skill: External system safety guardrails",
    "Skill: Spec-first development enforcement",
    "Skill: TDD best practices"
  ]
}
```

6. **Update CLAUDE.md**:
Add skills section explaining:
- What skills are
- How they complement commands/hooks/agents
- When skills auto-activate
- List of available skills

7. **Update README.md**:
Add skills to feature list and architecture diagram.

---

## Skills vs. Commands Decision Matrix

When designing new capabilities, use this matrix to decide between skill, command, hook, or agent:

| Criterion | Use Skill | Use Command | Use Hook | Use Agent |
|-----------|-----------|-------------|----------|-----------|
| **Invocation** | Automatic, context-driven | Explicit, user-initiated | Event-triggered | Proactive or explicit |
| **Complexity** | Simple guidance/context | Multi-step workflow | Simple automation | Complex delegation |
| **User control** | Background, optional | Full control, interactive | Transparent enforcement | Delegated autonomy |
| **External writes** | Never (read-only) | Yes (with confirmation) | No | Yes (through commands) |
| **Examples** | Safety rules, workflow tips | /ccpm:planning:create | TDD enforcer, quality gate | backend-architect |

**Rule of thumb**:
- **Skills**: "Claude should know this automatically"
- **Commands**: "User explicitly wants to do this"
- **Hooks**: "This must happen at a specific system event"
- **Agents**: "This requires specialized expertise and autonomy"

---

## Expected Benefits

### Developer Experience

**Before skills**:
```
Developer: "I need to plan this task"
Claude: "You can use /ccpm:planning:create or /ccpm:planning:plan"
Developer: "Which one?"
Claude: "It depends on whether you already have a Linear issue"
Developer: "Ugh, let me look at the docs..."
```

**After skills** (with `pm-workflow-guide`):
```
Developer: "I need to plan this task"
Claude: [pm-workflow-guide skill auto-activates]
       "Since you're starting fresh, I recommend:
        1. /ccpm:planning:create to create Linear issue and plan
        OR
        2. /ccpm:planning:quick-plan for quick internal tasks

        Which approach fits your needs?"
```

### Safety Improvements

**Before skills**:
```
Developer: "Update the Jira ticket to Done"
Agent: [Might update without confirmation if safety check missed]
Developer: "Wait, I didn't mean right now!"
```

**After skills** (with `external-system-safety`):
```
Developer: "Update the Jira ticket to Done"
Claude: [external-system-safety skill auto-activates]
       "⚠️ This will write to external system (Jira).

       I will update:
       - Ticket: ABC-123
       - Status: In Progress → Done

       Proceed? (yes/no)"
Developer: "no, not yet"
Claude: "Understood. I'll wait for your confirmation."
```

### Workflow Adherence

**Before skills**:
```
Developer: "Let's implement the new payment gateway"
Claude: [Starts implementing]
```

**After skills** (with `spec-first-development`):
```
Developer: "Let's implement the new payment gateway"
Claude: [spec-first-development skill auto-activates]
       "⚠️ This is a complex feature that needs a spec first.

       I recommend:
       1. /ccpm:spec:create epic 'Payment Gateway Integration'
       2. /ccpm:spec:write [doc-id] (Architecture, Security, API Design)
       3. /ccpm:spec:review [doc-id]
       4. Then start implementation

       Or do you have an existing spec I should reference?"
```

---

## Migration Strategy

### 1. No Breaking Changes

Skills are **additive**:
- ✅ Existing commands continue working
- ✅ Existing hooks remain active
- ✅ Existing agents unaffected
- ✅ All current workflows preserved

### 2. Gradual Adoption

Users can adopt skills incrementally:
- Install plugin update with skills
- Skills auto-activate for new workflows
- Users still have full control via commands
- Can disable skills if desired

### 3. Team Rollout

For teams using CCPM:
```bash
# Pull latest version
git pull origin main

# Skills automatically available
# No configuration needed

# Team can customize project-specific skills
mkdir -p .claude/skills/
cp -r skills/pm-workflow-guide .claude/skills/custom-workflow
# Edit .claude/skills/custom-workflow/SKILL.md
```

---

## Potential Drawbacks & Mitigations

### Drawback 1: Over-Activation

**Risk**: Skills activate too frequently, becoming noise

**Mitigation**:
- Write precise skill descriptions with clear trigger phrases
- Use `allowed-tools` to limit skill scope
- Monitor skill activation logs
- Iterate on description wording based on feedback

### Drawback 2: Context Size

**Risk**: Loading too many skills increases context size

**Mitigation**:
- Keep SKILL.md files concise (< 2KB each)
- Use progressive disclosure (reference supporting files)
- Load supporting files only when needed
- Limit to 4-5 high-value skills initially

### Drawback 3: Confusion with Commands

**Risk**: Users confused about when to use skills vs. commands

**Mitigation**:
- Clear documentation in CLAUDE.md
- Skills provide guidance, commands execute workflows
- Skills suggest commands to use
- Interactive mode remains in commands

### Drawback 4: Maintenance Burden

**Risk**: More components to maintain

**Mitigation**:
- Skills reference existing docs (SAFETY_RULES.md, etc.)
- Minimize duplication between skills and commands
- Use skills for "what" guidance, commands for "how" execution
- Automate skill testing in CI/CD

---

## Success Metrics

### Quantitative

1. **Reduced command lookup time**
   - Measure: Time from user question to command execution
   - Target: 30% reduction with `pm-workflow-guide` skill

2. **Prevented accidental external writes**
   - Measure: Number of confirmation prompts shown
   - Target: 0 unconfirmed external writes

3. **Increased spec creation rate**
   - Measure: Percentage of features with specs
   - Target: 80% of features have specs (up from ~50%)

4. **TDD compliance rate**
   - Measure: Percentage of production code with tests
   - Target: 95% test coverage maintained

### Qualitative

1. **Developer feedback**
   - "Skills help me remember the workflow"
   - "I don't need to look up commands as often"
   - "Safety confirmations caught my mistakes"

2. **Onboarding time**
   - New developers productive faster
   - Less confusion about which command to use
   - Better adherence to team practices

---

## Conclusion

Skills are a **complementary enhancement** to CCPM's existing architecture:

**High-value skills to implement**:
1. ✅ `external-system-safety` - Critical for preventing accidents
2. ✅ `pm-workflow-guide` - Improves developer experience
3. ✅ `spec-first-development` - Enforces best practices
4. ✅ `tdd-practices` - Educational reinforcement

**Keep using existing components**:
- Commands for explicit workflow execution
- Hooks for event-based automation
- Agents for specialized task delegation

**Expected outcome**:
- Better developer experience through automatic guidance
- Stronger safety guardrails
- Improved workflow adherence
- Faster onboarding for new team members
- No disruption to existing workflows

**Recommended next step**: Implement Phase 1 (`external-system-safety` skill) as proof of concept, gather feedback, then proceed with Phase 2-3 based on results.
