# ClaudeKit Skills Integration - Quick Reference

## At a Glance

```
ClaudeKit Skills (27 total) → CCPM Integration
│
├─ ✅ ADOPT (6 skills)
│   ├─ 📋 sequential-thinking (copy as-is)
│   ├─ 🔍 docs-seeker (copy as-is)
│   ├─ ✓ code-review → ccpm-code-review (adapt)
│   ├─ 🐛 debugging → ccpm-debugging (adapt)
│   ├─ 🔌 mcp-management → ccpm-mcp-management (adapt)
│   └─ 🛠️ skill-creator → ccpm-skill-creator (adapt)
│
├─ ⚠️ CONSIDER (5 skills - Phase 2)
│   ├─ 📄 document-skills (if user demand)
│   ├─ 📦 repomix (if needed)
│   ├─ 🧩 problem-solving (evaluate)
│   ├─ 🎨 UI skills (merge)
│   └─ 🔧 mcp-builder (advanced)
│
└─ ❌ SKIP (16 skills)
    └─ Duplicates agents or not PM-relevant
```

---

## 6 Skills to Adopt

### Tier: Copy As-Is (No Adaptation)

#### 1. 📋 sequential-thinking

**What**: Structured problem-solving through iterative reasoning

**When activated**: "complex", "break down", "analyze", "multiple steps"

**Use in CCPM**:
- `/ccpm:planning:create` - Task decomposition
- `/ccpm:spec:write architecture` - Complex spec sections
- `/ccpm:utils:insights` - Complexity analysis

**Effort**: 2 hours (copy directory, test, document)

---

#### 2. 🔍 docs-seeker

**What**: Documentation discovery

**When activated**: "documentation", "API docs", "find guide", "how to use"

**Use in CCPM**:
- `/ccpm:spec:write` - Research for spec writing
- `/ccpm:planning:plan` - Technical research
- Works with Context7 MCP

**Effort**: 2 hours (copy directory, test, document)

---

### Tier: Adapt for CCPM

#### 3. ✓ ccpm-code-review (from code-review)

**What**: Verification enforcement before completion

**When activated**: "done", "complete", "ready to merge", "verification"

**Use in CCPM**:
- `/ccpm:verification:verify` - Pre-completion checks
- `/ccpm:complete:finalize` - Enforce verification before PR/Jira/Slack
- Works with `quality-gate` hook

**Key changes**:
- Link to Linear verification status
- BitBucket PR workflow integration
- Jira sync confirmation
- Reference SAFETY_RULES.md

**Effort**: 8 hours (adapt SKILL.md, add Linear integration, test)

---

#### 4. 🐛 ccpm-debugging (from debugging)

**What**: Systematic debugging with defense-in-depth

**When activated**: "error", "failing", "broken", "debug", "issue"

**Use in CCPM**:
- `/ccpm:verification:fix` - Systematic issue resolution
- `/ccpm:implementation:update` - Log blockers
- Update Linear with findings

**Key changes**:
- Update Linear task with debugging progress
- Log blocker details in Linear comments
- Link to `/ccpm:planning:update` for scope changes

**Effort**: 8 hours (adapt SKILL.md, add Linear tracking, test)

---

#### 5. 🔌 ccpm-mcp-management (from mcp-management)

**What**: MCP server discovery and troubleshooting

**When activated**: "MCP server", "tools available", "Linear not working"

**Use in CCPM**:
- `/ccpm:utils:help` - Show available tools
- Plugin installation - Verify required servers
- Troubleshooting - Check connectivity

**Key changes**:
- Focus on CCPM-required servers (Linear, GitHub, Context7)
- Add Jira, Confluence, BitBucket, Slack discovery
- Document required vs optional servers

**Effort**: 8 hours (adapt for CCPM servers, create server docs, test)

---

#### 6. 🛠️ ccpm-skill-creator (from skill-creator)

**What**: Create custom CCPM skills with templates

**When activated**: "create skill", "custom workflow", "team specific"

**Use in CCPM**:
- Community contributions
- Team-specific workflows
- Plugin development

**Key changes**:
- CCPM-specific skill template
- Include safety guardrails
- Reference CCPM commands/hooks
- Example CCPM skill patterns

**Effort**: 8 hours (adapt template, add CCPM examples, test)

---

## Adaptation Checklist

When adapting a skill:

- [ ] Update frontmatter name: `ccpm-{original-name}`
- [ ] Update description: Add CCPM-specific triggers (Linear, Jira, planning, etc.)
- [ ] Add CCPM context in instructions
- [ ] Reference relevant CCPM commands
- [ ] Include safety guardrails for external writes
- [ ] Link to Linear workflow states
- [ ] Update examples with CCPM scenarios
- [ ] Create supporting docs if needed
- [ ] Test auto-activation
- [ ] Verify integration with commands/hooks
- [ ] Update CLAUDE.md and README.md

---

## Integration Matrix

| Skill | CCPM Commands | CCPM Hooks | Other Skills | CCPM Agents |
|-------|---------------|------------|--------------|-------------|
| **sequential-thinking** | `/ccpm:planning:create`<br>`/ccpm:spec:write`<br>`/ccpm:utils:insights` | - | `pm-workflow-guide` | All planning agents |
| **docs-seeker** | `/ccpm:spec:write`<br>`/ccpm:planning:plan` | - | - | All agents (research) |
| **ccpm-code-review** | `/ccpm:verification:verify`<br>`/ccpm:complete:finalize` | `quality-gate` | `external-system-safety`<br>`pm-workflow-guide` | `code-reviewer` |
| **ccpm-debugging** | `/ccpm:verification:fix`<br>`/ccpm:implementation:update` | - | `ccpm-code-review` | `debugger` |
| **ccpm-mcp-management** | `/ccpm:utils:help` | - | All skills | - |
| **ccpm-skill-creator** | - | - | All skills | - |

---

## Timeline

### Week 1
- [x] Research complete
- [ ] Copy `sequential-thinking`
- [ ] Copy `docs-seeker`
- [ ] Adapt `code-review` → `ccpm-code-review`

### Week 2
- [ ] Adapt `debugging` → `ccpm-debugging`
- [ ] Adapt `mcp-management` → `ccpm-mcp-management`
- [ ] Adapt `skill-creator` → `ccpm-skill-creator`
- [ ] Update documentation

### Week 3-4 (Phase 2)
- [ ] Gather feedback
- [ ] Evaluate Tier 2 skills
- [ ] Optimize existing skills

---

## File Structure After Integration

```
ccpm/skills/
├── README.md                       # CCPM skill conventions
│
├── external-system-safety/         # Existing
│   └── SKILL.md
│
├── pm-workflow-guide/              # Existing
│   └── SKILL.md
│
├── sequential-thinking/            # NEW - Copy as-is
│   └── SKILL.md
│
├── docs-seeker/                    # NEW - Copy as-is
│   └── SKILL.md
│
├── ccpm-code-review/               # NEW - Adapted
│   ├── SKILL.md
│   └── verification-checklist.md
│
├── ccpm-debugging/                 # NEW - Adapted
│   ├── SKILL.md
│   ├── defense-in-depth.md
│   └── root-cause-analysis.md
│
├── ccpm-mcp-management/            # NEW - Adapted
│   ├── SKILL.md
│   └── required-servers.md
│
└── ccpm-skill-creator/             # NEW - Adapted
    ├── SKILL.md
    ├── ccpm-skill-template.md
    └── examples/
```

---

## Testing Checklist

### Per Skill Tests

- [ ] Skill auto-activates with trigger phrases
- [ ] Integration with CCPM commands works
- [ ] No conflicts with other skills
- [ ] No conflicts with hooks
- [ ] Linear integration works (for adapted skills)
- [ ] Safety rules respected (for adapted skills)

### Integration Tests

- [ ] Planning workflow (sequential-thinking + pm-workflow-guide)
- [ ] Spec writing (sequential-thinking + docs-seeker)
- [ ] Verification workflow (ccpm-code-review + external-system-safety)
- [ ] Debugging workflow (ccpm-debugging + pm-workflow-guide)
- [ ] MCP troubleshooting (ccpm-mcp-management)

---

## Expected Outcomes

### Immediate (Phase 1)

- ✅ 8 total skills (2 existing + 6 new)
- ✅ Better planning with sequential-thinking
- ✅ Enhanced research with docs-seeker
- ✅ Stronger verification with ccpm-code-review
- ✅ Faster debugging with ccpm-debugging
- ✅ Easier MCP setup with ccpm-mcp-management
- ✅ Community skills with ccpm-skill-creator

### Long Term (Phase 2-3)

- ✅ 10-13 total skills (conditional adoptions)
- ✅ Community-contributed skills
- ✅ Team-specific customizations
- ✅ Analytics on skill effectiveness

---

## Decision Points

### ✅ Confirmed

- Adopt 6 ClaudeKit skills (2 as-is, 4 adapted)
- Skip 16 skills (not PM-relevant or duplicate agents)
- Progressive enhancement approach

### ⏳ Pending

- Tier 2 skills (Phase 2 based on feedback)
  - document-skills
  - repomix
  - problem-solving
  - UI skills merge
  - mcp-builder

### ❓ Questions

1. Priority order for Tier 2 skills?
2. Frequency of skill activation analytics?
3. Community contribution process?

---

## Resources

- **Comprehensive Plan**: `CLAUDEKIT_SKILLS_INTEGRATION_PLAN.md` (23KB)
- **Comparison Matrix**: `SKILLS_COMPARISON_MATRIX.md` (18KB)
- **Summary**: `SKILLS_INTEGRATION_SUMMARY.md` (8KB)
- **This Guide**: `SKILLS_QUICK_REFERENCE.md` (You are here)

- **ClaudeKit Repo**: https://github.com/mrgoonie/claudekit-skills
- **CCPM Current**: `/Users/duongdev/personal/ccpm/`

---

**Status**: 📋 Ready for Phase 1 implementation
**Next**: Copy `sequential-thinking` and test activation
