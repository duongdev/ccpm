---
description: List available subagents and their capabilities from CLAUDE.md
allowed-tools: []
---

# Available Subagents

Reading subagent definitions from **CLAUDE.md** in project root...

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

- ✅ **READ-ONLY** operations are permitted
- ⛔ **WRITE operations** require user confirmation
- ✅ **Linear** operations are permitted (our internal tracking)

## Subagents Overview

Display all subagents defined in CLAUDE.md with their:
- Name
- Role/Purpose
- Capabilities
- Best use cases
- Example invocation patterns

## Expected Format

```
🤖 Available Subagents
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 1. frontend-agent

**Role**: Frontend development specialist

**Capabilities**:
- React/Vue/Angular component development
- UI/UX implementation
- CSS/Tailwind/styled-components styling
- State management
- Component architecture
- Frontend testing

**Use For**:
- UI components and features
- Styling and layout tasks
- Client-side logic
- Form handling

**Example Invocation**:
"Invoke frontend-agent to implement the login form with email/password inputs, validation, and error handling. Follow patterns in /src/components."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 2. backend-agent

**Role**: Backend development specialist

**Capabilities**:
- RESTful/GraphQL API development
- Database operations
- Authentication/Authorization
- Server-side business logic
- API integrations
- Backend testing

**Use For**:
- API endpoints
- Database logic
- Authentication
- Server middleware
- Background jobs

**Example Invocation**:
"Invoke backend-agent to implement JWT authentication endpoints: POST /api/auth/login, /logout, /refresh. Include rate limiting and follow patterns in /src/api."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 3. mobile-agent

**Role**: Mobile development specialist

**Capabilities**:
- React Native development
- iOS-specific features
- Android-specific features
- Mobile UI patterns
- Device-specific functionality
- Mobile testing

**Use For**:
- React Native components
- Platform-specific code
- Native module integration
- Mobile app configuration

**Example Invocation**:
"Invoke mobile-agent to implement push notifications with Firebase Cloud Messaging. Handle permissions for both iOS and Android."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 4. integration-agent

**Role**: System integration specialist

**Capabilities**:
- Third-party API integration
- Webhook implementation
- Data synchronization
- API client implementation
- OAuth flows
- Integration testing

**Use For**:
- External service connections
- API clients
- Data sync logic
- Webhook handlers

**Example Invocation**:
"Invoke integration-agent to integrate Stripe payments. Implement checkout flow, webhook handlers for payment events, and refund functionality."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 5. verification-agent

**Role**: Quality assurance specialist

**Capabilities**:
- Code review
- Comprehensive testing
- Regression testing
- Requirements validation
- Security audit
- Performance testing

**Use For**:
- Final verification
- Requirements validation
- Regression checking
- Quality gates

**Example Invocation**:
"Invoke verification-agent to verify authentication implementation. Review against requirements, run all tests, check for security issues and regressions."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 6. devops-agent

**Role**: DevOps specialist

**Capabilities**:
- CI/CD configuration
- Deployment automation
- Docker containerization
- Environment configuration
- Build optimization
- Infrastructure as Code

**Use For**:
- CI/CD tasks
- Deployment scripts
- Environment setup
- Infrastructure changes

**Example Invocation**:
"Invoke devops-agent to set up staging deployment with Docker compose, environment variables, and CI/CD pipeline for auto-deploy."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### 7. database-agent

**Role**: Database specialist

**Capabilities**:
- Database schema design
- Query optimization
- Migration management
- Index optimization
- Database performance tuning
- Data modeling

**Use For**:
- Schema changes
- Complex queries
- Migration scripts
- Performance optimization

**Example Invocation**:
"Invoke database-agent to optimize user queries. Analyze slow queries, add indexes, rewrite N+1 queries, and create migration."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

- Agent definitions should be in **CLAUDE.md** in project root
- Customize agents based on your tech stack
- Add more specialized agents as needed (e.g., ml-agent, data-agent)
- Keep CLAUDE.md updated with project patterns

## If CLAUDE.md Doesn't Exist

If CLAUDE.md is not found, display:

```
⚠️  CLAUDE.md not found in project root!

Create a CLAUDE.md file to define your subagents.

Example structure:

# CLAUDE.md

## Subagent Definitions

### frontend-agent
**Role**: Frontend development
**Capabilities**: React, UI/UX, styling
**Use for**: UI components, frontend features

### backend-agent
**Role**: Backend development
**Capabilities**: APIs, database, auth
**Use for**: Server logic, endpoints

[Add more agents as needed]
```

## Using Agents

When you know which agent you need:

1. **Invoke with full context**:
   - Task description
   - Specific requirements
   - Files to modify
   - Patterns to follow

2. **Provide clear success criteria**:
   - What "done" looks like
   - Testing requirements
   - Quality standards

3. **Update after completion**:
   - Use `/update` command
   - Add summary of work

## Agent Selection Tips

**Question yourself**:
- What type of work needs to be done?
- Which domain does it fall under?
- Are there dependencies between tasks?
- Can tasks run in parallel?

**Match task to agent**:
- UI work → frontend-agent
- API work → backend-agent
- Integration → integration-agent
- Testing → verification-agent
- Deployment → devops-agent
- Database → database-agent