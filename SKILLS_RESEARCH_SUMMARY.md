# Claude Code Skills Research Summary

## Research Completed: 2025-11-19

This document summarizes research into Claude Code **skills** and how they can enhance the CCPM plugin.

---

## What Are Skills?

**Skills** are modular, auto-discovered capabilities that Claude uses automatically based on context. They differ fundamentally from other Claude Code components:

| Component | Invocation | Purpose | Control Level |
|-----------|-----------|---------|---------------|
| **Skills** | Automatic (model-driven) | Background knowledge & guidance | Claude decides |
| **Commands** | Manual (user types `/`) | Explicit workflow execution | User decides |
| **Hooks** | Event-triggered | System automation | System decides |
| **Agents** | Explicit or proactive | Specialized task delegation | Mixed |

---

## Key Findings

### 1. Skills Are Model-Invoked (Automatic)

Unlike slash commands that require explicit user invocation, skills are **automatically discovered and activated** by Claude when:
- Keywords in the skill description match the user's request
- The task context aligns with the skill's purpose
- The skill provides relevant knowledge for the current problem

**Example**:
```
User: "Update Jira ticket ABC-123 to Done"
       ↓
Claude recognizes "Jira" and "update" (external system write)
       ↓
external-system-safety skill auto-activates
       ↓
Claude requires confirmation before proceeding
```

### 2. Skills Complement Existing CCPM Components

Skills are **additive**, not replacements:

- ✅ **Skills** provide background knowledge and auto-detection
- ✅ **Commands** remain for explicit workflow execution
- ✅ **Hooks** continue handling event-based automation
- ✅ **Agents** still do the heavy lifting

**Why this matters**: CCPM requires explicit user control for safety-critical operations (external system writes). Skills can provide **guidance and detection** while commands maintain **control and execution**.

### 3. File Structure Is Simple

Every skill is a directory with a `SKILL.md` file:

```
skills/
├── external-system-safety/
│   ├── SKILL.md              # Required: skill definition
│   └── safety-checklist.md   # Optional: supporting docs
│
└── pm-workflow-guide/
    └── SKILL.md              # Required: skill definition
```

**SKILL.md format**:
```yaml
---
name: skill-name-lowercase
description: What this skill does and when Claude should use it (max 1024 chars)
allowed-tools: optional, comma-separated, tool-restrictions
---

# Skill Display Name

## Instructions
[Step-by-step guidance for Claude]

## Examples
[Concrete usage scenarios]
```

### 4. Discovery Is Automatic

Once skills are in the `skills/` directory:
1. Claude Code scans on startup
2. Skills become immediately available
3. No additional configuration needed (beyond `plugin.json`)

**Priority order**:
1. Plugin skills (highest priority for specialized capabilities)
2. Project skills (`.claude/skills/`)
3. Personal skills (`~/.claude/skills/`)

### 5. Tool Restrictions Enhance Safety

The `allowed-tools` field limits what a skill can access:

```yaml
---
name: external-system-safety
description: Enforces safety rules for external PM system writes
allowed-tools: read-file, grep, browser  # Cannot write, edit, or execute
---
```

This is perfect for **read-only safety checking** without allowing the skill to accidentally bypass its own rules.

---

## Recommended Skills for CCPM

### Priority 1: Critical Safety ⭐⭐⭐

**Skill**: `external-system-safety`
- **Purpose**: Automatically detects and prevents accidental writes to Jira/Confluence/BitBucket/Slack
- **Value**: Works even when agents bypass command safety checks
- **Status**: ✅ Implemented in `skills/external-system-safety/SKILL.md`

### Priority 2: Developer Experience ⭐⭐⭐

**Skill**: `pm-workflow-guide`
- **Purpose**: Auto-suggests appropriate CCPM commands based on workflow phase
- **Value**: Reduces cognitive load ("which command should I use?")
- **Status**: ✅ Implemented in `skills/pm-workflow-guide/SKILL.md`

### Priority 3: Best Practices ⭐⭐

**Skill**: `spec-first-development`
- **Purpose**: Encourages spec creation before implementation
- **Value**: Prevents scope creep and improves documentation
- **Status**: 🔄 Planned (proposal in SKILLS_INTEGRATION_PROPOSAL.md)

**Skill**: `tdd-practices`
- **Purpose**: Provides TDD workflow guidance
- **Value**: Complements `tdd-enforcer.prompt` hook with education
- **Status**: 🔄 Planned (proposal in SKILLS_INTEGRATION_PROPOSAL.md)

---

## Implementation Status

### Completed ✅

1. **Research Phase**
   - ✅ Gathered comprehensive Claude Code skills documentation
   - ✅ Analyzed how skills differ from commands/hooks/agents
   - ✅ Identified integration opportunities

2. **Documentation**
   - ✅ Created `SKILLS_INTEGRATION_PROPOSAL.md` (comprehensive analysis)
   - ✅ Created `SKILLS_RESEARCH_SUMMARY.md` (this document)

3. **Implementation**
   - ✅ Created `skills/external-system-safety/SKILL.md`
   - ✅ Created `skills/pm-workflow-guide/SKILL.md`
   - ✅ Updated `.claude-plugin/plugin.json` with skills configuration

### Pending 🔄

4. **Remaining Skills**
   - 🔄 `spec-first-development` skill
   - 🔄 `tdd-practices` skill

5. **Integration**
   - 🔄 Update `CLAUDE.md` with skills section
   - 🔄 Update `README.md` with skills feature
   - 🔄 Test skill auto-activation
   - 🔄 Gather user feedback

---

## How Skills Enhance CCPM Workflows

### Before Skills

```
Developer: "I need to plan this task"
Claude: "You can use /ccpm:planning:create or /ccpm:planning:plan"
Developer: "Which one do I need?"
Claude: "Depends if you have a Linear issue already"
Developer: "Let me check the docs..."
```

### After Skills (with pm-workflow-guide)

```
Developer: "I need to plan this task"
Claude: [pm-workflow-guide auto-activates]
       "Starting fresh? → /ccpm:planning:create
        Have Linear issue? → /ccpm:planning:plan
        Quick internal task? → /ccpm:planning:quick-plan

        Which matches your situation?"
```

### Before Skills (Safety)

```
Developer: "Update Jira to Done"
[Command might execute if confirmation logic missed]
```

### After Skills (with external-system-safety)

```
Developer: "Update Jira to Done"
Claude: [external-system-safety auto-activates]
       "⚠️ EXTERNAL SYSTEM WRITE DETECTED

       System: Jira
       Operation: Update Status
       Target: ABC-123

       Proceed? (yes/no)"
```

---

## Skills vs. Hooks: When to Use Each

Both skills and hooks provide automation, but they work differently:

### Use Hooks When:
- ✅ Automation must trigger at specific system events (UserPromptSubmit, PreToolUse, Stop)
- ✅ You need to modify Claude's context before execution
- ✅ You need to run shell scripts or external tools
- ✅ Enforcement must be 100% guaranteed

**Example**: `tdd-enforcer.prompt` hook
- Triggers on `PreToolUse` (before Write/Edit)
- Blocks the operation if tests missing
- Cannot be bypassed

### Use Skills When:
- ✅ You want Claude to provide guidance automatically
- ✅ Detection is based on natural language context
- ✅ Providing knowledge rather than enforcement
- ✅ You want progressive disclosure of information

**Example**: `tdd-practices` skill
- Activates when user starts coding
- Explains TDD workflow and best practices
- Complements hook enforcement with education

### Why Not Replace Hooks with Skills?

**Hooks are superior for enforcement**:
- Hook can BLOCK an operation (PreToolUse blocks Write)
- Skill can only GUIDE (provides context, but cannot prevent)
- Hook triggers at precise system events
- Skill triggers based on Claude's interpretation

**Skills are superior for guidance**:
- Skill provides context-aware suggestions
- Hook runs the same logic every time
- Skill can reference extensive documentation
- Hook should be fast (<5s to avoid latency)

**Best approach**: Use BOTH
- Hook enforces the rule
- Skill explains WHY and HOW

---

## Integration with Existing CCPM Architecture

### Current Architecture

```
CCPM Plugin
├── Commands (27)          → Explicit workflow execution
├── Hooks (3)              → Event-based automation
├── Agents (custom)        → Specialized task delegation
├── Scripts (discover)     → Utility automation
└── [NEW] Skills (4)       → Background knowledge & guidance
```

### How Skills Fit

```
User Request
     │
     ├─→ Skills auto-activate (guidance & detection)
     │        │
     │        ├─→ pm-workflow-guide suggests command
     │        └─→ external-system-safety checks for writes
     │
     ├─→ Hooks trigger on events (enforcement)
     │        │
     │        ├─→ smart-agent-selector scores agents
     │        ├─→ tdd-enforcer blocks writes without tests
     │        └─→ quality-gate runs code review
     │
     ├─→ User invokes Command (execution)
     │        │
     │        └─→ Command orchestrates workflow
     │
     └─→ Command invokes Agents (delegation)
              │
              └─→ Agents do heavy lifting
```

### Complementary Design

- **Skills** detect and suggest ("You might want to use /ccpm:planning:create")
- **User** decides and invokes ("/ccpm:planning:create ...")
- **Hooks** enforce safety ("Tests must exist before writing code")
- **Commands** orchestrate workflow (Jira → Context7 → Linear → Agents)
- **Agents** execute specialized tasks (backend-architect, tdd-orchestrator, etc.)

**Result**: Skills enhance UX without disrupting existing workflows.

---

## Testing Skills

### Manual Testing

1. **Start Claude Code with verbose mode**:
   ```bash
   claude --verbose
   ```

2. **Verify skills are loaded**:
   Look for log entries showing discovered skills:
   ```
   [Skills] Loaded: external-system-safety
   [Skills] Loaded: pm-workflow-guide
   ```

3. **Test auto-activation**:

   **Test 1: PM Workflow Guide**
   ```bash
   # Input
   "I need to plan a new authentication feature"

   # Expected
   Claude should suggest:
   - /ccpm:planning:create (if you have Jira)
   - /ccpm:planning:quick-plan (if internal)
   - /ccpm:spec:create (if complex enough for spec)
   ```

   **Test 2: External System Safety**
   ```bash
   # Input
   "Update Jira ticket ABC-123 to Done"

   # Expected
   Claude should show:
   ⚠️ EXTERNAL SYSTEM WRITE DETECTED
   System: Jira
   Operation: Update Status
   Proceed? (yes/no)
   ```

### Automated Testing

Create test cases in `.claude/tests/skills/`:

```yaml
# test-pm-workflow-guide.yaml
skill: pm-workflow-guide
tests:
  - input: "I need to plan a task"
    expect_activation: true
    expect_suggestions:
      - "/ccpm:planning:create"
      - "/ccpm:planning:quick-plan"

  - input: "What's 2+2?"  # Unrelated
    expect_activation: false
```

---

## Next Steps

### Immediate (This Week)

1. **Test implemented skills**
   - [ ] Verify auto-activation in real scenarios
   - [ ] Test with various command invocations
   - [ ] Check tool restriction enforcement

2. **Gather feedback**
   - [ ] Test with CCPM users
   - [ ] Identify false positives/negatives
   - [ ] Refine skill descriptions for better matching

### Short Term (Next 2 Weeks)

3. **Implement remaining skills**
   - [ ] Create `spec-first-development` skill
   - [ ] Create `tdd-practices` skill
   - [ ] Test integration with existing hooks

4. **Documentation updates**
   - [ ] Add skills section to CLAUDE.md
   - [ ] Update README.md feature list
   - [ ] Create skills usage guide

### Long Term (Next Month)

5. **Advanced features**
   - [ ] Add skill analytics (activation frequency)
   - [ ] Create skill debugging tools
   - [ ] Implement skill A/B testing
   - [ ] Gather community contributions

---

## Key Takeaways

1. **Skills are automatic, commands are explicit** → Use both for best UX
2. **Skills provide guidance, hooks provide enforcement** → Complementary design
3. **Skills enhance safety without blocking workflow** → Defense in depth
4. **Skills reduce cognitive load** → Developers focus on coding, not memorizing commands
5. **Skills are additive** → No breaking changes to existing CCPM workflows

---

## Resources

- **Detailed Proposal**: `SKILLS_INTEGRATION_PROPOSAL.md`
- **Implemented Skills**:
  - `skills/external-system-safety/SKILL.md`
  - `skills/pm-workflow-guide/SKILL.md`
- **Plugin Config**: `.claude-plugin/plugin.json`
- **Official Docs**: [Claude Code Documentation](https://claude.ai/code/docs)

---

## Questions & Feedback

If you have questions or feedback about skills integration:

1. Open an issue: https://github.com/duongdev/ccpm/issues
2. Review proposal: `SKILLS_INTEGRATION_PROPOSAL.md`
3. Check implementation: `skills/*/SKILL.md`

---

**Last Updated**: 2025-11-19
**Status**: Phase 1 Complete ✅ (2 of 4 skills implemented)
**Next**: Testing & feedback gathering
