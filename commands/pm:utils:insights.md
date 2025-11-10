---
description: AI-powered insights on complexity, risks, and timeline
allowed-tools: [LinearMCP, Read, Glob, Context7MCP]
argument-hint: <linear-issue-id>
---

# AI Insights for: $1

## Workflow

### Step 1: Gather Data
- Fetch Linear issue details
- Read mentioned files in description
- Analyze checklist complexity
- Check codebase for similar features

### Step 2: Analyze Complexity
```javascript
const complexity = {
  filesImpacted: countFiles(description),
  linesEstimate: estimateLines(checklist),
  techStackComplexity: analyzeStack(files),
  integrationPoints: countIntegrations(description),
  score: calculateComplexityScore(), // 1-10
  level: score < 4 ? 'Low' : score < 7 ? 'Medium' : 'High'
}
```

### Step 3: Identify Risks
```javascript
const risks = [
  checkBreakingChanges(description),
  checkSecurityConcerns(description),
  checkPerformanceImpact(files),
  checkDependencyRisks(checklist),
  checkTestingGaps(checklist)
].filter(r => r.severity > 0)
```

### Step 4: Estimate Timeline
```javascript
const timeline = {
  optimistic: estimateMin(checklist, complexity),
  realistic: estimateRealistic(checklist, complexity, risks),
  pessimistic: estimateMax(checklist, complexity, risks),
  confidence: calculateConfidence(similarFeatures)
}
```

### Step 5: Display Insights
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 AI Insights for: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Complexity Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overall: [High/Medium/Low] (Score: [X]/10)

Factors:
- Files Impacted: [N] files across [M] directories
- Estimated Lines: ~[X] lines of code
- Tech Stack: [complexity assessment]
- Integration Points: [N] external systems
- Similar Features: [Found X similar implementations]

🚨 Identified Risks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[High Priority]
⚠️  Breaking Changes: [description]
    Mitigation: [suggestion]

⚠️  Security Concern: [description]
    Mitigation: [suggestion]

[Medium Priority]
⚡ Performance Impact: [description]
    Mitigation: [suggestion]

[Low Priority]
📋 Testing Gap: [description]
    Mitigation: [suggestion]

⏰ Timeline Estimate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Optimistic:  [X] hours ([Y] days)
Realistic:   [X] hours ([Y] days) ⭐ Recommended
Pessimistic: [X] hours ([Y] days)

Confidence: [High/Medium/Low] based on [N] similar features

💡 Recommendations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. [Recommendation 1 based on complexity]
2. [Recommendation 2 based on risks]
3. [Recommendation 3 based on timeline]

✨ Optimization Opportunities
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- [Opportunity 1: parallel execution, etc.]
- [Opportunity 2: reuse existing code]
- [Opportunity 3: leverage patterns]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 6: Interactive Next Actions
Suggest actions based on insights:
- If High complexity → Suggest breaking into smaller tasks
- If High risk → Suggest additional planning/review
- If Timeline long → Suggest parallelization opportunities

## Notes
- AI-powered analysis
- Based on codebase patterns
- Provides actionable recommendations
- Helps with planning accuracy
