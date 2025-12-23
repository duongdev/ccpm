# Refactor Plan Template

## Refactor Summary
**Title**: {title}
**Type**: Refactor
**Scope**: {isolated|module|cross-cutting}
**Breaking Changes**: {yes|no}

## Motivation
Why is this refactor needed?

{motivation}

## Current State
Describe the current implementation and its problems.

{current_state}

## Target State
Describe the desired implementation after refactoring.

{target_state}

## Refactor Strategy
How will we approach this refactor?

{strategy}

## Implementation Checklist

### 1. Preparation
- [ ] Document current behavior with tests
- [ ] Identify all affected code paths
- [ ] Create backup/feature branch
- [ ] Set up metrics/monitoring

### 2. Incremental Changes
- [ ] {refactor_step_1}
- [ ] {refactor_step_2}
- [ ] {refactor_step_3}
- [ ] Verify tests pass after each step

### 3. Migration
- [ ] Update imports/exports
- [ ] Update dependent code
- [ ] Remove deprecated code
- [ ] Update documentation

### 4. Verification
- [ ] Run full test suite
- [ ] Performance comparison
- [ ] Code review
- [ ] Deploy to staging

### 5. Cleanup
- [ ] Remove old code
- [ ] Update type definitions
- [ ] Clean up comments
- [ ] Final documentation

## Breaking Changes
| Change | Migration Path |
|--------|----------------|
| {change_1} | {migration_1} |

## Metrics to Track
- Before: {metric_before}
- After: {metric_after}
- Improvement: {expected_improvement}

## Rollback Strategy
If issues occur:
{rollback_strategy}

## Dependencies
- Must complete first: {blockers}
- Can be parallelized: {parallel_work}

## References
- Architecture docs: {arch_docs}
- Related refactors: {related_refactors}
- Best practices: {best_practices}
