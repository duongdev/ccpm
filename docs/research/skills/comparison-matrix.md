# ClaudeKit Skills vs CCPM Skills - Detailed Comparison Matrix

## Overview

This matrix provides a detailed comparison of all ClaudeKit skills against CCPM's existing capabilities to identify gaps, overlaps, and integration opportunities.

---

## Legend

**Adoption Decision**:
- ✅ **ADOPT** - High value, integrate into CCPM
- 🔄 **ADAPT** - Modify for CCPM context before adoption
- ⚠️ **CONSIDER** - Evaluate based on user feedback
- ❌ **SKIP** - No value or duplicates existing functionality
- 🔀 **MERGE** - Combine with existing CCPM feature

**Value Indicators**:
- 🟢 High value for PM workflows
- 🟡 Medium value or conditional
- 🔴 Low value or not PM-relevant

**Integration Complexity**:
- 🟢 Easy (copy as-is or minimal changes)
- 🟡 Medium (adaptation required)
- 🔴 Complex (significant rework needed)

---

## Complete Skills Matrix

| # | ClaudeKit Skill | Value | Adoption | Complexity | CCPM Mapping | Rationale | Integration Points |
|---|-----------------|-------|----------|------------|--------------|-----------|-------------------|
| 1 | **code-review** | 🟢 | 🔄 ADAPT | 🟡 Medium | `/ccpm:verification:verify`<br>`quality-gate` hook | Enforces verification gates before completion. Complements existing quality workflow. | • `/ccpm:verification:verify`<br>• `/ccpm:complete:finalize`<br>• `quality-gate.prompt` hook<br>• BitBucket PR workflow |
| 2 | **sequential-thinking** | 🟢 | ✅ ADOPT | 🟢 Easy | `/ccpm:planning:create`<br>`/ccpm:spec:write`<br>`/ccpm:utils:insights` | Perfect for complex planning and spec writing. No CCPM adaptation needed. | • Task decomposition<br>• Spec architecture sections<br>• Complexity analysis<br>• Blocker root-cause analysis |
| 3 | **debugging/** | 🟢 | 🔄 ADAPT | 🟡 Medium | `/ccpm:verification:fix`<br>`/ccpm:implementation:update` | Systematic debugging complements verification workflow. Needs Linear integration. | • `/ccpm:verification:fix`<br>• Update Linear with findings<br>• Log blockers<br>• Root-cause documentation |
| 4 | **mcp-management** | 🟢 | 🔄 ADAPT | 🟡 Medium | Plugin requirements<br>`/ccpm:utils:help` | CCPM requires specific MCP servers. Adapt to focus on Linear, GitHub, Context7, Jira, etc. | • Plugin installation<br>• MCP server discovery<br>• Tool availability checking<br>• Troubleshooting |
| 5 | **docs-seeker** | 🟢 | ✅ ADOPT | 🟢 Easy | `/ccpm:spec:write`<br>Context7 integration | Enhances documentation discovery for spec writing. Works with Context7. | • Spec writing research<br>• Library documentation<br>• API design patterns<br>• Technical research |
| 6 | **skill-creator** | 🟢 | 🔄 ADAPT | 🟡 Medium | Community contributions | Enables users to create CCPM-specific skills. Needs CCPM template. | • Custom skill creation<br>• Team-specific workflows<br>• Plugin extensions<br>• Community ecosystem |
| 7 | **document-skills/** | 🟡 | ⚠️ CONSIDER | 🟡 Medium | `/ccpm:spec:migrate`<br>Attachment processing | Useful if teams work with PM docs. Consider based on demand. | • Parse requirements from DOCX<br>• Export specs to PDF<br>• Process Jira attachments<br>• Confluence doc conversion |
| 8 | **repomix** | 🟡 | ⚠️ CONSIDER | 🟡 Medium | `/ccpm:spec:write architecture` | Could enhance codebase analysis for specs. Not urgent. | • Spec generation from code<br>• Architecture documentation<br>• Legacy code analysis |
| 9 | **problem-solving/** | 🟡 | ⚠️ CONSIDER | 🟡 Medium | `/ccpm:planning:create`<br>`/ccpm:utils:insights` | May overlap with sequential-thinking. Evaluate specific frameworks. | • Creative problem-solving<br>• Alternative approaches<br>• Risk analysis |
| 10 | **frontend-design** | 🟡 | 🔀 MERGE | 🟡 Medium | `pm:ui-designer` agent | Merge into existing UI designer. Enhance with claudekit patterns. | • UI design workflow<br>• `/ccpm:planning:design-ui`<br>• Wireframe generation |
| 11 | **ui-styling** | 🟡 | 🔀 MERGE | 🟡 Medium | `pm:ui-designer` agent | Combine with frontend-design into enhanced UI skill. | • shadcn/ui integration<br>• Tailwind guidance<br>• Component design |
| 12 | **mcp-builder** | 🟡 | ⚠️ CONSIDER | 🔴 Complex | Plugin development | Advanced feature. Only for power users building custom MCP servers. | • Custom MCP server creation<br>• CCPM plugin development<br>• Tool integration |
| 13 | **backend-development** | 🔴 | ❌ SKIP | - | Existing agents:<br>• backend-architect<br>• backend-engineer | Duplicates existing CCPM agents. Better handled by specialized agents. | N/A - Use agents instead |
| 14 | **frontend-development** | 🔴 | ❌ SKIP | - | Existing agents:<br>• frontend-developer<br>• frontend-engineer | Duplicates existing agents. | N/A - Use agents instead |
| 15 | **web-frameworks** | 🔴 | ❌ SKIP | - | Existing agents | Framework-specific guidance better in agents, not skills. | N/A - Use agents |
| 16 | **devops** | 🔴 | ❌ SKIP | - | Existing agents:<br>• deployment-engineer<br>• performance-engineer | DevOps workflows handled by specialized agents. | N/A - Use agents |
| 17 | **databases** | 🔴 | ❌ SKIP | - | Existing agents:<br>• backend-architect | Database guidance in backend agents. | N/A - Use agents |
| 18 | **shopify** | 🔴 | ❌ SKIP | - | - | E-commerce specific, not PM-relevant. | N/A |
| 19 | **chrome-devtools** | 🔴 | ❌ SKIP | - | Repeat project<br>PR checker | Browser automation for Repeat project already exists. | N/A - Use `/ccpm:repeat:check-pr` |
| 20 | **ai-multimodal** | 🔴 | ❌ SKIP | - | - | Gemini API integration not PM-focused. | N/A |
| 21 | **google-adk-python** | 🔴 | ❌ SKIP | - | - | Python agent development not PM workflow. | N/A |
| 22 | **better-auth** | 🔴 | ❌ SKIP | - | - | Specific auth framework, not general PM tool. | N/A |
| 23 | **media-processing** | 🔴 | ❌ SKIP | - | - | FFmpeg/ImageMagick not PM-relevant. | N/A |
| 24 | **aesthetic** | 🔴 | ❌ SKIP | - | `pm:ui-designer` | Too broad. Merge useful parts into UI skills. | N/A - Merge into UI skill |
| 25 | **common/** | 🔴 | ❌ SKIP | - | - | Shared utilities, not standalone skill. | N/A |
| 26 | **template-skill** | 🔴 | ❌ SKIP | - | `ccpm-skill-creator` | Use adapted skill-creator instead. | N/A |
| 27 | **claude-code** | 🔴 | ❌ SKIP | - | CLAUDE.md | CCPM already documents Claude Code integration. | N/A - Already covered |

---

## Adoption Summary

### Tier 1: High-Value Immediate Adoption (6 skills)

| Skill | Action | Priority | Timeline |
|-------|--------|----------|----------|
| **sequential-thinking** | ✅ ADOPT as-is | P0 | Week 1 |
| **docs-seeker** | ✅ ADOPT as-is | P0 | Week 1 |
| **code-review** | 🔄 ADAPT to ccpm-code-review | P1 | Week 1-2 |
| **debugging** | 🔄 ADAPT to ccpm-debugging | P1 | Week 1-2 |
| **mcp-management** | 🔄 ADAPT to ccpm-mcp-management | P1 | Week 2 |
| **skill-creator** | 🔄 ADAPT to ccpm-skill-creator | P2 | Week 2 |

**Total**: 6 skills → 8 total skills (2 existing + 6 new)

### Tier 2: Conditional Adoption (5 skills)

| Skill | Action | Condition | Timeline |
|-------|--------|-----------|----------|
| **document-skills** | ⚠️ CONSIDER | User demand for PM doc processing | Phase 2 |
| **repomix** | ⚠️ CONSIDER | Spec generation needs enhancement | Phase 2 |
| **problem-solving** | ⚠️ CONSIDER | Distinct value vs sequential-thinking | Phase 2 |
| **frontend-design + ui-styling** | 🔀 MERGE into ccpm-ui-design | Enhance UI designer | Phase 2 |
| **mcp-builder** | ⚠️ CONSIDER | Advanced user demand | Phase 3 |

**Total**: 0-5 skills (based on feedback)

### Tier 3: Skip (16 skills)

**Reason: Duplicates existing agents/features or not PM-relevant**

- Backend/frontend/devops/database skills → Use specialized agents
- Shopify, media-processing, ai-multimodal → Not PM workflows
- Chrome-devtools → Repeat project already has PR checker
- Common, template-skill, aesthetic → Merged or redundant
- Claude-code → Already documented in CCPM

---

## Gap Analysis

### Gaps Filled by ClaudeKit Skills

| Gap | Current CCPM | ClaudeKit Skill | Impact |
|-----|--------------|----------------|--------|
| **Structured reasoning** | Ad-hoc problem solving | `sequential-thinking` | 🟢 High - Better planning and spec writing |
| **Verification enforcement** | Quality-gate hook (post-work) | `code-review` (pre-completion) | 🟢 High - Prevents false completion claims |
| **Documentation discovery** | Context7 only | `docs-seeker` | 🟡 Medium - Enhanced research capabilities |
| **Systematic debugging** | Ad-hoc debugging | `debugging` frameworks | 🟡 Medium - Faster issue resolution |
| **MCP management** | Manual troubleshooting | `mcp-management` | 🟡 Medium - Better plugin UX |
| **Skill creation** | Manual skill writing | `skill-creator` templates | 🟡 Medium - Community growth |

### Remaining Gaps (Not Addressed)

| Gap | Potential Solution | Priority |
|-----|-------------------|----------|
| **Test automation** | Create `ccpm-testing` skill | Low - `tdd-enforcer` hook sufficient |
| **Deployment verification** | Create `ccpm-deployment` skill | Low - Use deployment-engineer agent |
| **Performance monitoring** | Create `ccpm-performance` skill | Low - Use performance-engineer agent |
| **Security scanning** | Create `ccpm-security` skill | Medium - Could complement security-auditor |

---

## Integration Complexity Analysis

### Easy Integration (2 skills - Copy as-is)

**Skills**:
1. `sequential-thinking`
2. `docs-seeker`

**Effort**: 1-2 hours each
**Tasks**:
- Copy directory to `skills/`
- Test auto-activation
- Update documentation

**No adaptation needed** - These skills are general-purpose and work in any context.

---

### Medium Integration (4 skills - Adaptation required)

**Skills**:
1. `code-review` → `ccpm-code-review`
2. `debugging` → `ccpm-debugging`
3. `mcp-management` → `ccpm-mcp-management`
4. `skill-creator` → `ccpm-skill-creator`

**Effort**: 4-8 hours each
**Tasks**:
- Copy base skill structure
- Update frontmatter with CCPM triggers
- Add CCPM-specific instructions:
  - Linear integration
  - Command references
  - Safety guardrails
  - Example workflows
- Create supporting documentation
- Test integration with commands/hooks
- Validate safety rules

**Key Adaptation Points**:
- **code-review**: Link to Linear verification status, BitBucket PR workflow, safety confirmations
- **debugging**: Update Linear with findings, log blockers, systematic troubleshooting
- **mcp-management**: Focus on CCPM-required servers (Linear, GitHub, Context7, Jira, etc.)
- **skill-creator**: CCPM skill template, safety guardrails, command integration patterns

---

### Complex Integration (0 skills in Phase 1)

Phase 2 conditional skills may require complex integration:
- **document-skills**: Multiple file formats, conversion logic
- **repomix**: Repository analysis, spec generation
- **UI skills merge**: Combine multiple skills + existing agent

---

## Skill Activation Patterns

### When Each Skill Auto-Activates

| Skill | Trigger Phrases | CCPM Commands | User Intent |
|-------|----------------|---------------|-------------|
| **sequential-thinking** | "complex", "break down", "analyze", "multiple steps" | `/ccpm:planning:create`<br>`/ccpm:spec:write`<br>`/ccpm:utils:insights` | Systematic problem-solving |
| **docs-seeker** | "documentation", "API docs", "find guide", "how to use" | `/ccpm:spec:write`<br>`/ccpm:planning:plan` | Research and discovery |
| **ccpm-code-review** | "done", "complete", "ready to merge", "verification" | `/ccpm:verification:verify`<br>`/ccpm:complete:finalize` | Pre-completion verification |
| **ccpm-debugging** | "error", "failing", "broken", "debug", "issue" | `/ccpm:verification:fix`<br>`/ccpm:implementation:update` | Troubleshooting |
| **ccpm-mcp-management** | "MCP server", "tools available", "Linear not working" | `/ccpm:utils:help`<br>Plugin installation | MCP troubleshooting |
| **ccpm-skill-creator** | "create skill", "custom workflow", "team specific" | Community contributions | Skill development |

---

## Conflict Prevention Matrix

### Potential Conflicts

| Skill A | Skill B | Conflict Type | Resolution |
|---------|---------|---------------|------------|
| **ccpm-code-review** | **external-system-safety** | Both check external writes | ✅ Complementary - code-review checks verification, safety checks confirmation |
| **sequential-thinking** | **pm-workflow-guide** | Both suggest workflows | ✅ Different - sequential for reasoning, pm-workflow for commands |
| **ccpm-debugging** | **ccpm-code-review** | Both activate on failures | ✅ Sequential - debugging fixes, code-review verifies |
| **docs-seeker** | Context7 MCP | Both fetch documentation | ✅ Complementary - docs-seeker guides what to search, Context7 executes |

**Result**: No conflicts identified. Skills are complementary.

---

## Progressive Disclosure Strategy

### Context Size Optimization

| Skill | Main SKILL.md Size | Supporting Docs | Total Context | Strategy |
|-------|-------------------|-----------------|---------------|----------|
| **sequential-thinking** | ~2KB | None needed | ~2KB | ✅ Small, inline all |
| **docs-seeker** | ~1.5KB | None needed | ~1.5KB | ✅ Small, inline all |
| **ccpm-code-review** | ~3KB | verification-checklist.md (1KB) | 4KB | 🟡 Reference checklist |
| **ccpm-debugging** | ~3KB | defense-in-depth.md (2KB)<br>root-cause.md (2KB) | 7KB | 🟡 Reference frameworks |
| **ccpm-mcp-management** | ~2.5KB | required-servers.md (1.5KB) | 4KB | 🟡 Reference server list |
| **ccpm-skill-creator** | ~2KB | template.md (3KB)<br>examples/ (5KB) | 10KB | 🔴 Heavy progressive disclosure |

**Optimization**:
- SKILL.md: Core instructions only (2-3KB max)
- Supporting docs: Referenced when needed
- Examples: Load on demand

**Total Context Budget**: ~15KB for 6 skills (reasonable)

---

## Testing Matrix

### Skill Activation Tests

| Skill | Test Scenario | Expected Behavior | Integration Check |
|-------|--------------|-------------------|-------------------|
| **sequential-thinking** | "Break down this complex epic" | Activates, guides decomposition | Works with `/ccpm:planning:create` |
| **docs-seeker** | "Find React documentation" | Activates, searches docs | Works with `/ccpm:spec:write` |
| **ccpm-code-review** | "I'm done with AUTH-123" | Blocks without verification | Requires `/ccpm:verification:verify` first |
| **ccpm-debugging** | "Tests are failing" | Activates, systematic approach | Updates Linear with findings |
| **ccpm-mcp-management** | "Linear tools not showing" | Activates, checks MCP config | Helps troubleshoot plugin |
| **ccpm-skill-creator** | "Create custom PM skill" | Activates, provides template | Follows CCPM conventions |

### Integration Tests

| Test | Commands Involved | Expected Workflow |
|------|------------------|-------------------|
| **Planning workflow** | `/ccpm:planning:create` | sequential-thinking + pm-workflow-guide activate |
| **Verification workflow** | `/ccpm:verification:verify` | ccpm-code-review enforces evidence |
| **Completion workflow** | `/ccpm:complete:finalize` | ccpm-code-review + external-system-safety activate |
| **Spec writing** | `/ccpm:spec:write architecture` | sequential-thinking + docs-seeker activate |
| **Debugging workflow** | `/ccpm:verification:fix` | ccpm-debugging + pm-workflow-guide activate |

---

## Migration Path from ClaudeKit to CCPM

### For ClaudeKit Users Switching to CCPM

**What you keep**:
- ✅ `sequential-thinking` - Works identically
- ✅ `docs-seeker` - Works identically
- ✅ `code-review` → `ccpm-code-review` - Enhanced with Linear integration
- ✅ `debugging` → `ccpm-debugging` - Enhanced with Linear tracking
- ✅ `mcp-management` → `ccpm-mcp-management` - Adapted to CCPM servers

**What changes**:
- ⚠️ Backend/frontend/devops skills → Use CCPM agents instead
- ⚠️ Claude-code skill → Use CCPM's CLAUDE.md
- ⚠️ Skill-creator → Use `ccpm-skill-creator` with CCPM template

**New capabilities in CCPM**:
- ✅ PM workflow automation (27 commands)
- ✅ Linear integration for task tracking
- ✅ Jira/Confluence/BitBucket/Slack workflows
- ✅ Interactive mode with smart next actions
- ✅ TDD enforcement hooks
- ✅ Quality gates
- ✅ Spec management with Linear Documents

---

## Conclusion

### Final Recommendation

**Adopt**: 6 skills from ClaudeKit (2 as-is, 4 adapted)
**Skip**: 16 skills (duplicates or not PM-relevant)
**Consider**: 5 skills (conditional based on feedback)

**Expected Outcome**:
- 8 total skills in CCPM (2 existing + 6 new)
- Enhanced PM workflows
- No conflicts or duplicates
- Reasonable context size (~15KB)
- Smooth migration for ClaudeKit users

**Next Step**: Begin Phase 1 implementation with `sequential-thinking` and `ccpm-code-review` as proof of concept.
