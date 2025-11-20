##CCPM Skills Catalog

**Complete reference for all CCPM skills - what they do, when they activate, and how they integrate.**

**Last Updated**: 2025-11-19
**Total Skills**: 8 (2 CCPM-original + 4 adapted + 2 as-is)

---

## Quick Reference

| # | Skill | Type | Auto-Activates When | Primary Use |
|---|-------|------|---------------------|-------------|
| 1 | **external-system-safety** | Safety | External system writes detected | Prevents accidental Jira/Confluence/Slack writes |
| 2 | **pm-workflow-guide** | Workflow | PM workflow questions | Suggests appropriate CCPM commands |
| 3 | **sequential-thinking** | Problem-Solving | Complex problems mentioned | Structured reasoning for planning/specs |
| 4 | **docs-seeker** | Research | Documentation requests | Finds library/API documentation |
| 5 | **ccpm-code-review** | Quality | Completion claims | Enforces verification before "done" |
| 6 | **ccpm-debugging** | Quality | Errors/failures mentioned | Systematic debugging with Linear tracking |
| 7 | **ccpm-mcp-management** | Infrastructure | MCP issues | Troubleshoots MCP server connectivity |
| 8 | **ccpm-skill-creator** | Meta | Skill creation requests | Creates custom CCPM skills |

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

## Skill Combinations

### Combination 1: Planning Workflow

**Trigger**: User starts planning a complex feature

**Skills activate**:
1. **pm-workflow-guide** → Suggests `/ccpm:planning:create`
2. **sequential-thinking** → Structures task breakdown
3. **docs-seeker** → Finds relevant technical documentation

**Result**: Comprehensive, well-researched plan

---

### Combination 2: Verification Workflow

**Trigger**: User claims task is complete

**Skills activate**:
1. **ccpm-code-review** → Enforces verification checklist
2. **external-system-safety** → Confirms PR/Jira/Slack writes
3. **pm-workflow-guide** → Suggests next action after completion

**Result**: Quality-gated, safely completed task

---

### Combination 3: Debugging Workflow

**Trigger**: Tests failing

**Skills activate**:
1. **ccpm-debugging** → Systematic troubleshooting
2. **sequential-thinking** → Structures root-cause analysis
3. **docs-seeker** → Finds debugging guides
4. **ccpm-code-review** → Verifies fix before completion

**Result**: Properly diagnosed, fixed, and verified issue

---

### Combination 4: Setup/Troubleshooting

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
| `/ccpm:planning:create` | pm-workflow-guide, sequential-thinking, docs-seeker |
| `/ccpm:planning:plan` | pm-workflow-guide, sequential-thinking, docs-seeker |
| `/ccpm:spec:write` | sequential-thinking, docs-seeker |
| `/ccpm:spec:review` | ccpm-code-review (for spec quality) |
| `/ccpm:implementation:start` | pm-workflow-guide |
| `/ccpm:implementation:next` | pm-workflow-guide |
| `/ccpm:verification:check` | ccpm-debugging (if failures) |
| `/ccpm:verification:fix` | ccpm-debugging, sequential-thinking |
| `/ccpm:verification:verify` | ccpm-code-review |
| `/ccpm:complete:finalize` | ccpm-code-review, external-system-safety, pm-workflow-guide |
| `/ccpm:utils:help` | ccpm-mcp-management |
| `/ccpm:utils:insights` | sequential-thinking |

### By User Intent

| User Says | Skills Activate |
|-----------|----------------|
| "Plan this task" | pm-workflow-guide, sequential-thinking |
| "I'm done" | ccpm-code-review, external-system-safety |
| "Tests failing" | ccpm-debugging |
| "Find docs for X" | docs-seeker |
| "Linear not working" | ccpm-mcp-management |
| "Create custom skill" | ccpm-skill-creator |
| "Update Jira" | external-system-safety |

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

**Last Updated**: 2025-11-19
**Total Skills**: 8
**Status**: Phase 1 Complete ✅
**Next**: User feedback, Phase 2 conditional skills
