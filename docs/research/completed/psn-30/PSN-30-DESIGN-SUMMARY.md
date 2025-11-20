# PSN-30 Design Summary

**Issue**: PSN-30 - Eliminate double context loading in natural workflow commands
**Status**: Design Complete - Ready for Implementation
**Author**: Backend Architect Agent
**Date**: 2025-11-20

---

## Overview

This document summarizes the complete architectural design for PSN-30, which eliminates the routing pattern in natural workflow commands to achieve **67% combined token reduction** (PSN-29 + PSN-30).

---

## Problem Statement

Current natural workflow commands use a routing pattern that causes:

1. **Double context loading** - Both natural command and underlying command load full context
2. **Repeated argument parsing** - Parse arguments twice (router + underlying)
3. **Duplicate Linear fetches** - Fetch same issue data twice
4. **SlashCommand overhead** - 3,000-7,000 tokens per routing operation

**Example** (`/ccpm:work`):
```
User → Natural Command (7,000 tokens)
  ↓ SlashCommand routing (3,000 tokens)
  ↓ Underlying Command (8,000 tokens)
Total: 18,000 tokens
```

---

## Solution Architecture

Replace routing pattern with direct implementation:

```
User → Natural Command (5,000 tokens TOTAL)
  - Parse arguments ONCE
  - Fetch via Linear subagent (cached)
  - Execute logic DIRECTLY
  - Update via Linear subagent (batched)
  - Display results
Total: 5,000 tokens (72% reduction from routing pattern)
```

**Combined with PSN-29** (Linear subagent):
- PSN-29: 50-60% reduction (15,000 → 8,000 tokens)
- PSN-30: Additional 30-40% reduction (8,000 → 5,000 tokens)
- **Total**: 67% reduction (15,000 → 5,000 tokens)

---

## Key Design Principles

### 1. Single Context Load
- Load command context only once
- No routing to other commands
- All logic implemented inline

### 2. Linear Subagent Integration
- All Linear operations via subagent
- Enable caching for reads (`cache: true`)
- Batch updates into single calls
- Structured error handling

### 3. Smart Agent Selection
- Use `Task('linear-operations')` for Linear ops (explicit)
- Use `Task(...)` for technical analysis (smart selection)
- No agent for simple logic (inline)

### 4. Optimal Token Usage
- Conservative estimates with 15% buffer
- Track and validate actual usage
- Target: 60%+ reduction per command

---

## Command Structure Template

Every natural command follows this structure:

```markdown
---
description: [Brief description]
---

# /ccpm:[command] - [Title]

**Purpose**: [One-line purpose]
**Token Budget**: ~X tokens (vs ~Y baseline, Z% reduction)
**Dependencies**:
- Linear operations subagent
- Workflow state detection

## 🚨 CRITICAL: Safety Rules
[Safety rules reference]

## Command Flow
[5-step flow description]

## Implementation

### Step 1: Parse Arguments & Detect Context
[Standard argument parsing with git detection]

### Step 2: Fetch Current State (via Linear Subagent)
[Fetch issue with caching]

### Step 3: Execute Mode Logic
[Mode detection and execution]

### Step 4: Update Linear (via Linear Subagent - Batched)
[Batch updates and comments]

### Step 5: Display Results & Interactive Menu
[Results display and next actions]

## Examples
[3-5 usage examples]

## Benefits
[List of benefits]
```

---

## Token Reduction Summary

| Command | Baseline | PSN-29 | PSN-30 | Combined | Reduction |
|---------|----------|--------|--------|----------|-----------|
| `/ccpm:work` (start) | 15,000 | 8,000 | 5,000 | 5,000 | **67%** |
| `/ccpm:work` (resume) | 13,000 | 7,500 | 4,500 | 4,500 | **65%** |
| `/ccpm:sync` | 12,000 | 7,000 | 4,500 | 4,500 | **63%** |
| `/ccpm:plan` (create) | 20,000 | 11,000 | 7,000 | 7,000 | **65%** |
| `/ccpm:plan` (plan) | 18,000 | 10,000 | 6,500 | 6,500 | **64%** |
| `/ccpm:plan` (update) | 16,000 | 9,000 | 5,500 | 5,500 | **66%** |
| `/ccpm:verify` | 14,000 | 8,500 | 5,500 | 5,500 | **61%** |
| `/ccpm:done` | 13,000 | 7,500 | 4,800 | 4,800 | **63%** |
| **Average** | **15,125** | **8,563** | **5,413** | **5,413** | **64%** |

---

## Expected Impact

### Token Savings (per user)

**Per Day** (10 commands/day):
- Baseline: 151,250 tokens
- With PSN-30: 54,130 tokens
- **Savings**: 97,120 tokens/day (64%)

**Per Month** (20 working days):
- **Savings**: 1,942,400 tokens/month per user

**Team of 10**:
- **Savings**: 19,424,000 tokens/month

### Performance Improvements

- **Execution time**: <5s (95th percentile)
- **Linear operations**: <50ms (cached), <500ms (uncached)
- **Cache hit rate**: 85-95% (Linear subagent)

### User Experience

- Faster responses (perceived performance)
- Reduced waiting time
- Maintained or improved ease of use
- No breaking changes for users

---

## Implementation Phases

### Phase 1: High-Impact Commands (Week 1)

**Commands**:
1. `/ccpm:work` - Start or resume work (67% reduction)
2. `/ccpm:sync` - Save progress (63% reduction)
3. `/ccpm:done` - Finalize task (63% reduction)

**Success Criteria**:
- Token reduction ≥60%
- No functionality regressions
- Positive user feedback

### Phase 2: Planning Commands (Week 2)

**Commands**:
1. `/ccpm:plan` (CREATE mode) - 65% reduction
2. `/ccpm:plan` (PLAN mode) - 64% reduction
3. `/ccpm:plan` (UPDATE mode) - 66% reduction

**Success Criteria**:
- All modes working correctly
- Mode detection 100% accurate
- External integrations functional

### Phase 3: Verification Commands (Week 3)

**Commands**:
1. `/ccpm:verify` - 61% reduction
2. `/ccpm:commit` - Verify consistency (already optimized)

**Success Criteria**:
- Sequential flow correct
- Quality checks accurate
- Verification agents invoked properly

---

## Linear Subagent Integration

All commands use the Linear operations subagent for optimal token usage:

### Common Patterns

**Get Issue (Cached)**:
```yaml
Task(linear-operations): `
operation: get_issue
params:
  issue_id: "${issueId}"
context:
  cache: true
  command: "${COMMAND_NAME}"
`
```

**Create Issue**:
```yaml
Task(linear-operations): `
operation: create_issue
params:
  team: "${TEAM}"
  title: "${TITLE}"
  state: "${STATE}"
  labels:
    - "${LABEL1}"
    - "${LABEL2}"
`
```

**Update Issue (Batched)**:
```yaml
Task(linear-operations): `
operation: update_issue
params:
  issue_id: "${issueId}"
  state: "${STATE}"
  labels:
    - "${LABEL1}"
`
```

**Create Comment**:
```yaml
Task(linear-operations): `
operation: create_comment
params:
  issue_id: "${issueId}"
  body: |
    ## ${TITLE}
    ${CONTENT}
`
```

---

## Testing Strategy

### Per Command

**Functionality Testing**:
- Argument parsing (valid, invalid, edge cases)
- Git detection (success, failure, not git repo)
- Mode detection (all status combinations)
- Linear operations (success, failure, network errors)
- Interactive menu (all options)

**Token Budget Testing**:
- Measure actual usage vs estimates
- Track cache hit rates
- Compare with baseline
- Validate reduction percentages

**User Acceptance Testing**:
- Run through common workflows
- Collect feedback on UX
- Verify no regressions
- Measure perceived performance

---

## Migration Strategy

### Backward Compatibility

Old commands remain functional with migration hints:

```markdown
ℹ️  **Pro Tip**: This command has been optimized!

Use the natural workflow command instead:
  /ccpm:work (replaces implementation:start + implementation:next)

Benefits:
  • 67% fewer tokens (faster responses)
  • Auto-detection from git branch
  • Simpler syntax

The old command still works, but the new one is recommended.
```

### Gradual Rollout

1. **Phase 1**: Deploy high-impact commands
2. **Monitor**: Track metrics for 3 days
3. **Iterate**: Fix any issues
4. **Phase 2-3**: Deploy remaining commands

### Rollback Plan

If critical issues arise:
1. Revert new command files
2. Restore old routing pattern
3. Analyze failures
4. Re-deploy with fixes

**Rollback Criteria**:
- Error rate >5% for 24h
- User complaints >10
- Token reduction <40%
- Critical bug

---

## Success Criteria

### Technical Success

✅ **Token Reduction**:
- Average ≥60% across all commands
- Individual commands meet targets
- Cache hit rate ≥85%

✅ **Performance**:
- Execution time <5s (95th percentile)
- Linear ops <500ms (uncached), <50ms (cached)

✅ **Quality**:
- Zero critical bugs
- Error rate <2%
- All tests passing

### User Success

✅ **Adoption**:
- >80% of users adopt within 2 weeks
- <5 support tickets
- Positive feedback

✅ **Experience**:
- Faster perceived responses
- Maintained/improved ease of use
- No workflow disruptions

---

## Documentation Deliverables

### Architecture (docs/architecture/)
- ✅ **psn-30-natural-command-direct-implementation.md**
  - Complete architectural specification
  - 12 sections covering all aspects
  - Command-by-command implementation details
  - Token budget analysis
  - Risk analysis and mitigation
  - ~20,000 words

### Development (docs/development/)
- ✅ **psn-30-implementation-guide.md**
  - Step-by-step conversion guide
  - Code patterns and examples
  - Testing checklist
  - Common pitfalls and solutions
  - ~8,000 words

### Reference (docs/reference/)
- ✅ **psn-30-quick-reference.md**
  - Quick lookup card
  - Token costs table
  - Code snippets
  - Common operations
  - Testing checklist
  - ~2,000 words

### Summary (docs/)
- ✅ **PSN-30-DESIGN-SUMMARY.md** (this document)
  - Executive summary
  - Key design decisions
  - Implementation roadmap
  - Success criteria
  - ~2,500 words

**Total Documentation**: ~32,500 words across 4 comprehensive documents

---

## Key Decisions

### Decision 1: Direct Implementation vs Improved Routing

**Chosen**: Direct Implementation

**Rationale**:
- Eliminates SlashCommand overhead completely (3,000-7,000 tokens)
- Avoids double context loading
- Simpler code paths (easier to maintain)
- Better token efficiency (64% reduction vs ~40% with improved routing)

### Decision 2: Linear Subagent for All Linear Operations

**Chosen**: Always use Linear subagent

**Rationale**:
- Consistent caching (85-95% hit rate)
- Structured error handling
- Batch operations optimization
- Single source of truth
- Already proven in PSN-29 (50-60% reduction)

### Decision 3: Phased Rollout vs Big Bang

**Chosen**: Phased Rollout (3 weeks)

**Rationale**:
- Lower risk (can rollback per phase)
- Faster iteration on learnings
- User feedback incorporated early
- Better monitoring and validation

### Decision 4: Backward Compatibility

**Chosen**: Keep old commands with hints

**Rationale**:
- No breaking changes for users
- Smooth migration path
- Users can adopt at their pace
- Easy rollback if needed

---

## Monitoring & Metrics

### KPIs to Track

**Token Usage**:
- Tokens per command execution
- Tokens saved vs baseline
- Cache hit rate (Linear subagent)

**Performance**:
- Execution time per command
- Linear operation latency
- Git operation latency

**Quality**:
- Error rate per command
- User retry rate
- Success rate per workflow

### Target KPIs

| Metric | Target | Measurement |
|--------|--------|-------------|
| Token reduction | ≥60% | Per command vs baseline |
| Cache hit rate | ≥85% | Linear subagent ops |
| Execution time | <5s | 95th percentile |
| Error rate | <2% | Per command |
| User satisfaction | ≥8/10 | Survey after migration |

---

## Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Token budget exceeded | High | Low | Conservative estimates, monitoring |
| Functionality regression | High | Medium | Comprehensive testing, gradual rollout |
| User confusion | Medium | Low | Clear hints, documentation |
| Subagent issues | Medium | Low | Fallback to direct MCP, monitoring |
| Git detection failures | Low | Medium | Clear error messages, manual fallback |

---

## Next Steps

### Immediate (This Week)

1. ✅ **Architecture Design Complete** (this document)
2. ⏳ **Review & Approve** architecture with team
3. ⏳ **Create Implementation Issues** for Phase 1-3
4. ⏳ **Set Up Monitoring** for token tracking

### Phase 1 (Week 1)

1. Implement `/ccpm:work`
2. Implement `/ccpm:sync`
3. Implement `/ccpm:done`
4. Test thoroughly, measure metrics
5. Deploy to production

### Phase 2-3 (Weeks 2-3)

1. Implement planning commands
2. Implement verification commands
3. Update documentation
4. Collect user feedback
5. Iterate based on learnings

---

## Questions & Answers

### Q: Why not just improve the routing pattern?

**A**: Direct implementation eliminates SlashCommand overhead completely (3,000-7,000 tokens), avoids double context loading, and results in simpler code. Improved routing would only save ~40% vs 64% with direct implementation.

### Q: What if a command needs to delegate to another command?

**A**: Commands can still use `Task(...)` for smart agent selection or delegate specific operations to subagents. The key is eliminating the routing layer, not preventing all delegation.

### Q: How do we ensure token budgets are met?

**A**: Conservative estimates with 15% buffer, continuous monitoring, and validation during testing. If a command exceeds budget, we refactor to optimize further.

### Q: What happens to old commands?

**A**: They remain functional with migration hints. Users can adopt new commands at their own pace. After 2-3 months, we can deprecate if adoption is high.

### Q: How do we handle errors from Linear subagent?

**A**: Subagent returns structured errors with suggestions. Commands display these to users with actionable guidance. Non-critical errors (comments, etc.) are warnings, not blockers.

---

## Conclusion

PSN-30 provides a comprehensive architectural pattern for optimizing natural workflow commands through direct implementation and Linear subagent integration. The design achieves:

- **64% average token reduction** across all commands
- **Faster execution** (<5s, 95th percentile)
- **Better user experience** (perceived performance)
- **Lower costs** (1.9M tokens/month saved per user)
- **Maintainable codebase** (simpler code paths)

The phased rollout strategy minimizes risk while maximizing learning and iteration opportunities. With comprehensive documentation, testing strategies, and monitoring in place, this design is ready for implementation.

---

## Related Documents

- **Full Architecture**: `docs/architecture/psn-30-natural-command-direct-implementation.md`
- **Implementation Guide**: `docs/development/psn-30-implementation-guide.md`
- **Quick Reference**: `docs/reference/psn-30-quick-reference.md`
- **Linear Subagent Architecture** (PSN-29): `docs/architecture/linear-subagent-architecture.md`

---

**Design Status**: ✅ Complete - Ready for Implementation

**Approval Required**: Team review and sign-off

**Target Start Date**: Week of 2025-11-25

**Estimated Completion**: 3 weeks (by 2025-12-16)

---

**End of Design Summary**
