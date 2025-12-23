---
description: Deep planning - comprehensive research and analysis
allowed-tools: [Bash, Task, AskUserQuestion, WebFetch]
argument-hint: "<issue-id|title> [project]"
---

# /ccpm:plan:deep - Deep Planning Mode

Comprehensive planning with thorough research, stakeholder analysis, and detailed implementation strategy.

## Usage

```bash
# Deep plan existing issue
/ccpm:plan:deep PSN-29

# Deep plan new task
/ccpm:plan:deep "Implement OAuth2 with multiple providers"

# With project context
/ccpm:plan:deep "Build recommendation engine" ml-service
```

## Differences from /ccpm:plan

| Aspect | /ccpm:plan | /ccpm:plan:deep |
|--------|-----------|-----------------|
| Codebase analysis | Standard (5-10 files) | Comprehensive (20+ files) |
| External research | Basic (Jira, Confluence) | Extended (docs, APIs, libraries) |
| Dependency analysis | Simple | Full dependency graph |
| Risk assessment | Brief | Detailed with mitigations |
| Architecture review | Skip | Include |
| Estimated time | 30-60 seconds | 2-5 minutes |

## Implementation

### Step 1: Parse Arguments & Initialize

```javascript
const input = args[0];
const project = args[1];

if (!input) {
  return error('Usage: /ccpm:plan:deep "<issue-id|title>" [project]');
}

console.log('🔬 Deep Planning Mode');
console.log('   This may take 2-5 minutes for thorough analysis...');
console.log('');

const isExistingIssue = /^[A-Z]+-\d+$/.test(input);
let issueId = isExistingIssue ? input : null;
let title = isExistingIssue ? null : input;
```

### Step 2: Comprehensive Codebase Analysis

```javascript
// Phase 1: Architecture understanding
const archAnalysis = await Task({
  subagent_type: 'Explore',
  prompt: `
Deep architecture analysis for: ${title || issueId}

Analyze:
1. **Project Structure**: Identify all relevant modules, packages, layers
2. **Data Flow**: How data moves through the system
3. **Integration Points**: APIs, databases, external services
4. **Existing Patterns**: Design patterns, conventions, standards
5. **Test Coverage**: Testing approach, coverage areas

Explore at least 20 files. Return structured analysis.
`
});

console.log('✅ Architecture analysis complete');
```

### Step 3: Dependency Graph

```javascript
// Phase 2: Dependency analysis
const depAnalysis = await Task({
  subagent_type: 'Explore',
  prompt: `
Dependency analysis for: ${title || issueId}

Identify:
1. **Internal Dependencies**: Which modules depend on what
2. **External Dependencies**: npm/pip packages involved
3. **Circular Dependencies**: Any risky circular deps
4. **Version Constraints**: Package version requirements
5. **Breaking Changes**: Potential breaking change risks

Create a dependency graph summary.
`
});

console.log('✅ Dependency analysis complete');
```

### Step 4: External Research

```javascript
// Phase 3: External documentation research
const externalResearch = [];

// Check for relevant library docs
const libraries = extractLibraries(archAnalysis);
for (const lib of libraries.slice(0, 3)) {
  const docs = await Task({
    subagent_type: 'general-purpose',
    prompt: `
Research latest best practices for: ${lib}

Focus on:
1. Current recommended patterns
2. Common pitfalls to avoid
3. Performance considerations
4. Security best practices

Use Context7 MCP or web search. Return key findings.
`
  });
  externalResearch.push({ library: lib, findings: docs });
}

console.log('✅ External research complete');
```

### Step 5: Risk Assessment

```javascript
// Phase 4: Risk analysis
const riskAnalysis = await Task({
  subagent_type: 'Plan',
  prompt: `
Risk assessment for: ${title || issueId}

Context:
${archAnalysis.summary}
${depAnalysis.summary}

Identify:
1. **Technical Risks**: Complexity, performance, scalability
2. **Integration Risks**: Breaking changes, API compatibility
3. **Security Risks**: Auth, data exposure, injection
4. **Timeline Risks**: Scope creep, blockers, dependencies
5. **Resource Risks**: Skills, tooling, infrastructure

For each risk, provide:
- Likelihood (low/medium/high)
- Impact (low/medium/high)
- Mitigation strategy

Return structured risk matrix.
`
});

console.log('✅ Risk assessment complete');
```

### Step 6: Generate Detailed Plan

```javascript
// Phase 5: Comprehensive plan generation
const plan = await Task({
  subagent_type: 'Plan',
  prompt: `
Generate comprehensive implementation plan for: ${title || issueId}

Context:
- Architecture: ${archAnalysis.summary}
- Dependencies: ${depAnalysis.summary}
- Research: ${externalResearch.map(r => r.findings).join('\n')}
- Risks: ${riskAnalysis.summary}

Create:
1. **Executive Summary** (1 paragraph)
2. **Technical Approach** (detailed strategy)
3. **Implementation Phases** (with milestones)
4. **Detailed Checklist** (15-25 items, grouped by phase)
5. **Testing Strategy** (unit, integration, e2e)
6. **Rollout Plan** (staging, canary, production)
7. **Success Metrics** (how we know it's done)

Return as structured markdown.
`
});

console.log('✅ Plan generation complete');
```

### Step 7: Create/Update Linear Issue

```javascript
const description = `
## Deep Planning Summary

${plan.executiveSummary}

## Technical Approach

${plan.technicalApproach}

## Architecture Impact

${archAnalysis.impactedAreas}

## Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
${riskAnalysis.risks.map(r => `| ${r.name} | ${r.likelihood} | ${r.impact} | ${r.mitigation} |`).join('\n')}

## Implementation Checklist

${plan.checklist.map(item => `- [ ] ${item}`).join('\n')}

## Testing Strategy

${plan.testingStrategy}

## Dependencies

${depAnalysis.externalDeps.join(', ')}

## External Research Notes

${externalResearch.map(r => `### ${r.library}\n${r.findings}`).join('\n\n')}

## Success Metrics

${plan.successMetrics}

---
*Created via /ccpm:plan:deep - Comprehensive planning mode*
`;

// Update or create issue
if (issueId) {
  await Task({
    subagent_type: 'ccpm:linear-operations',
    prompt: `operation: update_issue
params:
  issueId: "${issueId}"
  description: |
${description.split('\n').map(l => '    ' + l).join('\n')}
context:
  command: "plan:deep"
`
  });
} else {
  // Create new issue
  const result = await Task({
    subagent_type: 'ccpm:linear-operations',
    prompt: `operation: create_issue
params:
  team: "${project || 'Personal'}"
  title: "${title}"
  description: |
${description.split('\n').map(l => '    ' + l).join('\n')}
  labels: ["deep-plan"]
context:
  command: "plan:deep"
`
  });
  issueId = result.issue.identifier;
}
```

### Step 8: Display Summary

```javascript
console.log('\n═══════════════════════════════════════');
console.log('🔬 Deep Planning Complete');
console.log('═══════════════════════════════════════\n');
console.log(`📋 Issue: ${issueId}`);
console.log(`📊 Checklist: ${plan.checklist.length} items`);
console.log(`⚠️  Risks: ${riskAnalysis.risks.length} identified`);
console.log(`📚 Research: ${externalResearch.length} libraries analyzed`);
console.log('');
console.log('💡 Next: /ccpm:work ' + issueId);
console.log('   Review the full plan in Linear before starting');
```

## When to Use

✅ **Good for:**
- Complex new features
- Major refactoring efforts
- Security-critical changes
- Cross-team dependencies
- Production-impacting work
- Architecture changes
- Unknown/legacy codebases

❌ **Use /ccpm:plan instead for:**
- Standard features
- Routine bug fixes
- Well-understood changes
- Time-sensitive tasks

## Example Output

```
🔬 Deep Planning Mode
   This may take 2-5 minutes for thorough analysis...

✅ Architecture analysis complete
✅ Dependency analysis complete
✅ External research complete
✅ Risk assessment complete
✅ Plan generation complete

═══════════════════════════════════════
🔬 Deep Planning Complete
═══════════════════════════════════════

📋 Issue: PSN-43
📊 Checklist: 22 items
⚠️  Risks: 5 identified
📚 Research: 3 libraries analyzed

💡 Next: /ccpm:work PSN-43
   Review the full plan in Linear before starting
```
