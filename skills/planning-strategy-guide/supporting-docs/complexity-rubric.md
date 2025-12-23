# Complexity Assessment Rubric

Quick reference for assessing task complexity in the planning-strategy-guide skill.

## Complexity Levels

### Simple (1-2 files, 1-4 hours)

**Characteristics**:
- ✅ Single component or module
- ✅ Well-defined requirements
- ✅ No external dependencies
- ✅ Minimal or no research needed
- ✅ Clear implementation path

**Examples**:
- Add a logout button
- Update button color
- Add validation to form field
- Display error message
- Simple UI component

**Planning approach**: Quick assessment (Phase 1 + estimate)

**Commands**: `/ccpm:plan "task"` (lightweight)

---

### Medium (3-8 files, 1-3 days)

**Characteristics**:
- ⚡ Multiple components or modules
- ⚡ Some unknowns or research needed
- ⚡ Few external dependencies
- ⚡ Some integration work
- ⚡ Multiple implementation options

**Examples**:
- Add search functionality
- Implement form with validation
- Create new API endpoint with tests
- Add pagination to list
- Update multiple related components

**Planning approach**: Moderate planning (Phases 1, 2, 5, 6)

**Commands**: `/ccpm:plan "task"` or `/ccpm:plan`

---

### Complex (9+ files, 4+ days)

**Characteristics**:
- 🔥 Cross-system or multi-module changes
- 🔥 Significant research required
- 🔥 Many external dependencies
- 🔥 Multiple integration points
- 🔥 High technical risk

**Examples**:
- Payment gateway integration
- Authentication system
- Real-time notification system
- Complex data migration
- Third-party API integration

**Planning approach**: Full planning (All 6 phases)

**Commands**: `/ccpm:plan` + `/ccpm:plan`

---

## Decision Tree

```
┌─────────────────────────────────────┐
│ How many files will be modified?    │
└───────────┬─────────────────────────┘
            │
    ┌───────┴──────┐
    │              │
  1-2            3-8           9+
    │              │            │
    ▼              ▼            ▼
┌────────┐    ┌────────┐   ┌────────┐
│ SIMPLE │    │ MEDIUM │   │COMPLEX │
└───┬────┘    └───┬────┘   └───┬────┘
    │             │            │
    ▼             ▼            ▼
Questions:        Questions:   Questions:

SIMPLE:           MEDIUM:       COMPLEX:
- Clear reqs?     - Research?   - External?
- No deps?        - Few deps?   - High risk?
                  - Options?    - Multi-sys?

If all YES:       If most YES:  If any YES:
→ SIMPLE          → MEDIUM      → COMPLEX
```

## Factors to Consider

### 1. File Count

- **1-2 files**: Likely simple
- **3-8 files**: Likely medium
- **9+ files**: Likely complex

### 2. Requirements Clarity

- **Crystal clear**: -1 complexity level
- **Some unknowns**: No change
- **Many unknowns**: +1 complexity level

### 3. External Dependencies

- **None**: -1 complexity level
- **Few (1-2)**: No change
- **Many (3+)**: +1 complexity level

### 4. Research Needed

- **Minimal (<1 hour)**: No change
- **Moderate (1-4 hours)**: +1 complexity level
- **Significant (4+ hours)**: +2 complexity levels

### 5. Technical Risk

- **Low**: Well-known tech, clear path
- **Medium**: Some new tech, multiple options
- **High**: Unfamiliar tech, many unknowns

## Complexity Adjustment Examples

### Example 1: File count suggests Simple, but high risk

**Task**: "Update database schema"
- Files: 1-2 (migration + model)
- But: High risk (data loss possible)
- **Result**: Upgrade to Medium complexity

### Example 2: File count suggests Complex, but clear requirements

**Task**: "Update 15 UI components to new design"
- Files: 15 files
- But: Simple, repetitive work, clear requirements
- **Result**: Downgrade to Medium complexity

### Example 3: Medium file count, but significant research

**Task**: "Implement GraphQL caching"
- Files: 5 files
- But: Unfamiliar tech, research needed
- **Result**: Upgrade to Complex

## Quick Reference Table

| Factor | Simple | Medium | Complex |
|--------|--------|--------|---------|
| **Files** | 1-2 | 3-8 | 9+ |
| **Time** | 1-4h | 1-3d | 4+d |
| **Research** | <1h | 1-4h | 4+h |
| **Dependencies** | 0 | 1-2 | 3+ |
| **Risk** | Low | Medium | High |
| **Story Points** | 1-2 | 3-5 | 8-13 |
| **T-Shirt** | XS-S | M | L-XL |

## Usage in Planning

When using planning-strategy-guide:

1. **Start with file count** (quick proxy)
2. **Adjust for risk factors** (deps, research, unknowns)
3. **Choose planning depth**:
   - Simple → Quick assessment
   - Medium → Moderate planning
   - Complex → Full 6-phase planning

## Common Pitfalls

### ❌ Underestimating Complexity

**Mistake**: "It's just adding a button" (but button needs API, state management, error handling)

**Fix**: Consider full scope, not just happy path

### ❌ Overestimating Complexity

**Mistake**: "This touches 10 files, must be complex" (but it's simple find-and-replace)

**Fix**: Consider nature of changes, not just file count

### ❌ Ignoring Risk

**Mistake**: "Only 3 files, should be simple" (but high data loss risk)

**Fix**: Always factor in risk level

---

**Remember**: Complexity assessment is a guide, not a rule. Use your judgment and adjust based on context.
