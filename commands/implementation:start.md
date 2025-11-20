---
description: Start implementation - fetch task, list agents, assign subtasks, coordinate parallel work
allowed-tools: [Bash, LinearMCP]
argument-hint: <linear-issue-id>
---

# Starting Implementation: $1

You are beginning the **Implementation Phase** for Linear issue **$1**.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

- ✅ **Linear** operations are permitted (our internal tracking)
- ⛔ **External PM systems** require user confirmation for write operations

## Implementation Workflow

### Step 1: Fetch Task Details from Linear

Use **Linear MCP** to:
1. Get issue details for: $1
2. Read the full description
3. Extract the checklist
4. Understand all requirements

Display the task summary:
```
📋 Task: [Title]
Project: [Project name]
Status: [Current status]

Checklist Items:
- [ ] Item 1
- [ ] Item 2
...
```

### Step 2: List Available Subagents

Read the **CLAUDE.md** file in the project root to get subagent definitions.

Display available agents:
```
🤖 Available Subagents:

1. frontend-agent
   - Capabilities: React/Vue, UI/UX, styling
   - Use for: UI components, frontend features

2. backend-agent
   - Capabilities: APIs, database, auth
   - Use for: Server logic, endpoints

3. mobile-agent
   - Capabilities: React Native, iOS/Android
   - Use for: Mobile development

4. integration-agent
   - Capabilities: API integration, third-party services
   - Use for: Connecting systems

5. verification-agent
   - Capabilities: Testing, QA, code review
   - Use for: Final verification

6. devops-agent
   - Capabilities: CI/CD, deployment
   - Use for: Infrastructure tasks

[Add more agents as defined in CLAUDE.md]
```

### Step 3: Create Assignment Plan

For each checklist item, determine:
1. **Which agent** is best suited for the task
2. **Dependencies** between subtasks
3. **Parallel execution** opportunities

Create an assignment map:
```
📝 Assignment Plan:

✅ Group 1 (Run First):
- [ ] Subtask 1 → database-agent

✅ Group 2 (After Group 1):
- [ ] Subtask 2 → backend-agent

✅ Group 3 (Parallel, after Group 2):
- [ ] Subtask 3 → frontend-agent (parallel)
- [ ] Subtask 4 → mobile-agent (parallel)

✅ Group 4 (After Group 3):
- [ ] Subtask 5 → integration-agent

✅ Group 5 (Final):
- [ ] Subtask 6 → verification-agent
```

### Step 4: Update Linear

Use **Linear MCP** to:
1. Update issue status to: **In Progress**
2. Remove label: **planning**
3. Add label: **implementation**
4. Add comment with assignment plan:

```markdown
## 🚀 Implementation Started

### Agent Assignments:
- Subtask 1 → database-agent
- Subtask 2 → backend-agent
- Subtask 3 → frontend-agent (parallel with 4)
- Subtask 4 → mobile-agent (parallel with 3)
- Subtask 5 → integration-agent
- Subtask 6 → verification-agent

### Execution Strategy:
- Groups 3 can execute in parallel
- Other groups must run sequentially
```

### Step 5: Begin Execution

Now you're ready to invoke subagents! 

**For each subtask**:
1. Invoke the assigned agent with full context
2. Provide clear success criteria
3. After completion, use `/update` command

## Execution Guidelines

### Invoking Subagents

When invoking a subagent, always provide:

**Context**:
- Full task description from Linear
- Specific subtask requirements
- Related code files to modify
- Patterns to follow (from CLAUDE.md)

**Success Criteria**:
- What "done" looks like
- Testing requirements
- Performance/security considerations

**Example invocation**:
```
Invoke backend-agent to implement authentication endpoints:

Context:
- Linear issue: $1
- Subtask: "Implement JWT authentication endpoints"
- Files to modify: src/api/auth.ts, src/middleware/auth.ts

Requirements:
- POST /api/auth/login - JWT authentication
- POST /api/auth/logout - Token invalidation
- POST /api/auth/refresh - Token refresh
- Rate limiting: 5 requests/minute
- Follow patterns in src/api/users.ts

Success Criteria:
- All endpoints functional
- Tests pass
- No linting errors
- Security best practices followed
```

### Parallel Execution

For subtasks that can run in parallel:
1. Invoke all agents simultaneously
2. Each works independently
3. Wait for all to complete before moving to next group

### Status Updates

After EACH subtask completion:
```
/update $1 <subtask-index> completed "<summary of what was done>"
```

## Next Steps

After displaying the assignment plan:

1. **Start with Group 1** - Invoke first agent(s)
2. **Update after each subtask** - Use `/update` command
3. **Move through groups sequentially** (except parallel groups)
4. **After all subtasks done** - Run `/check $1`

## Output Format

```
✅ Implementation Started!

📋 Task: [Title]
🔗 Linear: https://linear.app/workspace/issue/$1

🤖 Agent Assignments Created
📝 Execution plan in Linear comments

⚡ Ready to Execute!

Next: Invoking [first-agent] for Subtask 1...
[Then actually invoke the agent]
```

## Remember

- Provide full context to each subagent
- Update Linear after each subtask
- Execute parallel tasks simultaneously when possible
- Follow patterns defined in CLAUDE.md
- Run quality checks before verification