# Planning Commands - Engineer Agent Enhancement

## Overview

Enhanced CCPM planning commands now automatically invoke specialized engineer agents to provide deeper technical insights and validation during the planning phase.

## Changes Summary

### Commands Enhanced

1. **`/ccpm:planning:plan`** - Full planning workflow
2. **`/ccpm:planning:create`** - Create + plan in one step (inherits from plan workflow)
3. **`/ccpm:planning:update`** - Update existing plans with validation

### New Planning Flow

#### Before (Manual)
```
1. Gather context from Jira/Confluence/Slack
2. Analyze codebase
3. Update Linear issue with findings
4. User manually decides if they need expert input
```

#### After (Automated Agent Invocation)
```
1. Gather context from Jira/Confluence/Slack
2. Analyze codebase
3. 🆕 **Invoke engineer agents for deep analysis**
4. Integrate agent insights into plan
5. Update Linear issue with comprehensive findings
```

## Agent Invocation Strategy

### Step 2.5: Invoke Engineer Agents (planning:plan & planning:create)

Added between codebase analysis and Linear update.

**Decision Tree:**

| Task Type | Primary Agent | Secondary Agent | Execution |
|-----------|---------------|-----------------|-----------|
| Backend/API | `backend-architect` | `security-auditor` (if security-critical) | Sequential |
| Frontend/UI | `frontend-developer` | - | Single |
| Mobile | `mobile-developer` | - | Single |
| Full-Stack | `backend-architect` + `frontend-developer` | - | **Parallel** |
| Database/Data | `backend-architect` (data modeling skill) | - | Single |
| Security-Critical | Primary agent | `security-auditor` | Sequential |

**Agent Prompts Include:**

1. **Context**: Requirements, current architecture, best practices
2. **Specific Questions**:
   - Architecture recommendations
   - API/Component design
   - Database schema (if applicable)
   - Performance implications
   - Security considerations
   - Potential pitfalls
   - Testing strategy

**Output Integration:**

Agent responses are captured in a new section of the Linear description:

```markdown
## 🤖 Engineer Agent Analysis

### Backend Architecture (backend-architect)
- Recommended Approach: [...]
- API Design: [...]
- Database Changes: [...]
- Performance: [...]
- Security: [...]
- Pitfalls: [...]
- Testing: [...]

### Frontend Architecture (frontend-developer)
- Component Architecture: [...]
- State Management: [...]
- Reusable Components: [...]
- Styling: [...]
- Accessibility: [...]
- Performance: [...]

### Security Review (security-auditor)
- Risks: [...]
- Mitigation: [...]
- Compliance: [...]
```

### Step 4.5: Invoke Agents for Validation (planning:update)

Added between gathering additional context and generating updated plan.

**Decision Tree:**

| Change Type | Agent(s) | Purpose |
|-------------|----------|---------|
| Scope/Approach Change | `backend-architect` OR `frontend-developer` | Validate technical soundness |
| Architecture Change | `backend-architect` + `security-auditor` | Validate + security review |
| Technical Blocker | `debugger` → relevant architect | Root cause → solution |
| Simplification | Relevant architect | Validate safe removal |

**Validation Questions:**

1. Is the new approach technically sound?
2. What are the implications?
3. Are there better alternatives?
4. What new risks are introduced?
5. What additional subtasks are needed?
6. Updated complexity estimate?

**Output Integration:**

```markdown
## 🔄 Plan Update Analysis

### Change Requested
[User's update request]

### Engineer Agent Validation
**[Agent Name] Review**:
- ✅ Technically sound / ⚠️ Concerns
- Identified: [new considerations]
- Recommended: [additional subtasks]
- Complexity: [before] → [after]

### Updated Approach
[Incorporate agent recommendations]
```

## Benefits

### 1. Deeper Technical Insights

**Before**:
- Basic codebase analysis
- Manual pattern identification
- User's own technical judgment

**After**:
- Expert architecture recommendations
- Automated best practice validation
- Specialized insights (backend, frontend, mobile, security)
- Proactive risk identification

### 2. Better Planning Quality

- **More accurate complexity estimates** - Agents validate feasibility
- **Earlier risk detection** - Identify pitfalls before implementation
- **Comprehensive testing strategy** - Agents suggest test scenarios
- **Architecture alignment** - Ensure consistency with codebase patterns

### 3. Automated Expertise

- **No manual agent invocation needed** - Automatic based on task type
- **Parallel execution** - Backend + frontend run simultaneously for full-stack
- **Sequential chaining** - Architecture → security for critical tasks
- **Context-aware** - Agents receive all gathered context

### 4. Enhanced Linear Documentation

Linear issues now contain:
- ✅ Original research findings
- 🤖 **NEW: Engineer agent analysis**
- 📊 Architecture recommendations
- ⚠️ Identified risks and pitfalls
- 💡 Best practice guidance
- 🔒 Security considerations

## Examples

### Example 1: Backend API Task

**Command**: `/ccpm:planning:plan WORK-123 JIRA-456`

**Agent Flow**:
```
1. Gather Jira/Confluence context
2. Analyze codebase (find existing API patterns)
3. Invoke backend-architect:
   - Analyze proposed API design
   - Recommend endpoints structure
   - Suggest database schema
   - Validate performance approach
   - Identify security requirements
4. Invoke security-auditor (if auth/sensitive data):
   - OWASP compliance check
   - Authentication recommendations
   - Data protection requirements
5. Update Linear with comprehensive plan + agent insights
```

### Example 2: Full-Stack Feature

**Command**: `/ccpm:planning:plan WORK-789 JIRA-999`

**Agent Flow**:
```
1. Gather context
2. Analyze codebase
3. Invoke backend-architect + frontend-developer IN PARALLEL:

   backend-architect:
   - API endpoint design
   - Data model recommendations
   - Backend logic architecture

   frontend-developer:
   - Component architecture
   - State management approach
   - UI/UX patterns
   - Accessibility considerations

4. Update Linear with both insights integrated
```

### Example 3: Plan Update with Blocker

**Command**: `/ccpm:planning:update WORK-456 "Library X doesn't work with Node 20"`

**Agent Flow**:
```
1. Fetch current plan
2. Detect change type: Blocker
3. Ask clarifying questions
4. Invoke debugger:
   - Analyze compatibility issue
   - Identify root cause
   - Suggest workarounds/alternatives
5. Invoke backend-architect:
   - Validate debugger's solution
   - Recommend implementation approach
   - Estimate new complexity
6. Update plan with solution + adjusted subtasks
```

## Usage Guide

### For Users

**No change required!** Agent invocation is automatic.

Just use planning commands as before:
```bash
# Create and plan
/ccpm:planning:create "Add user notifications" trainer-guru JIRA-123

# Plan existing issue
/ccpm:planning:plan WORK-456 JIRA-789

# Update plan
/ccpm:planning:update WORK-123 "Use Postgre SQL instead of MongoDB"
```

The system will:
1. Detect task type automatically
2. Invoke appropriate agents
3. Integrate insights into Linear
4. Provide comprehensive plan

### For Developers

**Agent Selection Logic** (in commands):

```markdown
Determine task type:
- Backend keywords: "API", "endpoint", "database", "schema", "service"
- Frontend keywords: "component", "UI", "screen", "form", "navigation"
- Mobile keywords: "React Native", "iOS", "Android", "mobile"
- Security keywords: "auth", "login", "password", "token", "encryption"

Invoke agents based on keywords + project context.
```

**Execution Strategy**:

```markdown
Sequential (one after another):
- Architecture design → Security review
- Problem debugging → Solution design

Parallel (simultaneously):
- Backend + Frontend for full-stack tasks
- Independent analysis tasks
```

## Migration Notes

### Backward Compatibility

✅ **Fully backward compatible**

- Existing Linear issues work unchanged
- Old command format still supported
- No breaking changes to workflows

### Gradual Rollout

**Phase 1** (Current):
- Agent invocation in planning commands only
- Manual invocation still available via Task tool
- Users can see agent integration in action

**Phase 2** (Future):
- Extend to implementation commands
- Add to verification commands
- Hook-based automation (when size limits resolved)

## Performance Considerations

### Agent Response Time

- **Single agent**: ~10-30 seconds
- **Parallel agents**: ~10-30 seconds (not additive!)
- **Sequential agents**: ~20-60 seconds (additive)

### Optimization

1. **Parallel when possible**: Full-stack tasks run backend + frontend simultaneously
2. **Conditional invocation**: Security auditor only for security-critical tasks
3. **Smart prompts**: Agents receive focused, specific questions
4. **Caching context**: All gathered context reused across agents

## Troubleshooting

### Agent Not Invoked

**Check**:
1. Task type keywords present?
2. Context gathered successfully?
3. Agent available in system?

**Solution**: Manually invoke with Task tool if needed

### Unexpected Agent Choice

**Issue**: Wrong agent type selected

**Solution**:
- Review task description keywords
- Manually specify in update request
- Example: "Use frontend approach for..."

### Missing Agent Insights

**Issue**: Linear description missing agent section

**Possible Causes**:
1. Agent invocation failed
2. Agent response not captured
3. Linear update error

**Solution**: Check command output for error messages

## Future Enhancements

### Planned Features

1. **Agent Confidence Scores**: Agents rate their confidence in recommendations
2. **Alternative Solutions**: Agents propose multiple approaches with pros/cons
3. **Cost Estimation**: Agents estimate implementation time
4. **Dependency Mapping**: Auto-detect cross-repository impacts
5. **Risk Scoring**: Automated risk assessment (Low/Medium/High)

### Hook Integration

When hook size limitations are resolved:
- **Pre-planning hook**: Auto-invoke agents before planning starts
- **Planning validation hook**: Validate plan completeness
- **Agent chaining hook**: Automatically chain dependent agents

## Summary

✅ **Planning commands now auto-invoke engineer agents**
✅ **Deeper technical insights in Linear issues**
✅ **Better architecture recommendations**
✅ **Proactive risk identification**
✅ **No user workflow changes required**
✅ **Backward compatible**

**Result**: Higher quality plans with expert validation built-in!
