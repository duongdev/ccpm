---
description: Plan a task - gather context from Jira/Confluence/Slack, analyze codebase, update Linear issue with research and checklist
allowed-tools: [Bash, LinearMCP, AtlassianMCP, SlackMCP, PlaywrightMCP, Context7MCP]
argument-hint: <linear-issue-id> <jira-ticket-id>
---

# Planning Task: Linear $1 (Jira: $2)

You are starting the **Planning Phase** for Linear issue **$1** based on Jira ticket **$2**.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

- ✅ **READ-ONLY** operations are permitted (fetch, search, view)
- ⛔ **WRITE operations** require user confirmation
- ✅ **Linear** operations are permitted (our internal tracking)

When in doubt, ASK before posting anything externally.

## Project Configuration

**IMPORTANT**: This command uses dynamic project configuration from `~/.claude/ccpm-config.yaml`.

## Planning Workflow

### Step 0: Fetch Existing Linear Issue & Load Project Config

Use **Linear MCP** to:

1. Get issue details for: $1
2. Read current title, description, and any existing context
3. **Determine the project from the Linear issue** (team/project mapping)
4. Extract any existing Jira ticket reference (if not provided as $2)

**Load Project Configuration:**

```bash
# Get project ID from Linear issue's team/project
# Map Linear team+project to project ID in config

# Example: If Linear shows "Work / My App"
# Search config for matching linear.team="Work" and linear.project="My App"

# Load project config
PROJECT_ARG=$(determine_project_from_linear_issue "$1")
```

**LOAD PROJECT CONFIG**: Follow instructions in `commands/_shared-project-config-loader.md`

After loading, you'll have:
- `${EXTERNAL_PM_ENABLED}` - Whether to query Jira/Confluence/Slack
- `${EXTERNAL_PM_TYPE}` - Type of external PM
- `${JIRA_ENABLED}`, `${CONFLUENCE_ENABLED}`, `${SLACK_ENABLED}`
- All other project settings

If $2 (Jira ticket ID) is not provided:

- Check Linear description for Jira ticket reference
- If no Jira ticket found, ask user for Jira ticket ID or proceed without external PM research

### Step 1: Gather All Context from External PM Systems

**Only if Jira ticket ID is available** (from $2 or Linear description):

1. **Use Atlassian MCP** to:
   - Fetch Jira ticket: $2 (or extracted from Linear)
   - Get all linked issues
   - Read issue description, comments, attachments

2. **Search Confluence** for:
   - Related documentation
   - PRD (Product Requirements Document)
   - Design documents
   - Architecture decisions
   - Technical specifications
   - **SAVE all page URLs** for linking in description

3. **Use Slack MCP** to:
   - Search relevant channels for discussions about this ticket
   - Find context from team conversations
   - Identify any blockers or decisions made
   - **SAVE thread URLs** for linking in description

4. **Use Playwright MCP** to:
   - Open BitBucket for related pull requests
   - Check commit history for related changes
   - Review code review comments if applicable
   - **SAVE PR URLs** for linking in description

5. **Extract and store all URLs**:
   - From Jira API responses (issue URLs, attachment URLs)
   - From Confluence API responses (page URLs)
   - From Slack API responses (thread/message URLs)
   - From BitBucket/browser (PR URLs, commit URLs)
   - From Linear API responses (related issue URLs)

6. **Use Context7 MCP** to:
   - Search for latest best practices related to this task
   - **IMPORTANT**: Do NOT trust knowledge cutoff - always search for current best practices
   - Find recommended approaches and patterns

### Step 2: Analyze Codebase

1. **Read relevant repository files**:
   - Identify files that need to be modified
   - Understand current implementation patterns
   - Find similar features for reference

2. **Identify patterns and conventions**:
   - Code structure and organization
   - Naming conventions
   - Testing patterns
   - API design patterns
   - Error handling approaches

3. **Map dependencies**:
   - Which repositories need changes
   - Dependencies between components
   - External service integrations
   - Database schema impacts

### Step 2.5: Invoke Engineer Agents for Deep Technical Analysis

**CRITICAL**: After gathering all context and analyzing the codebase, invoke specialized engineer agents to provide deeper insights and validate the approach.

**Determine which agents to invoke based on the task type:**

1. **For Backend/API tasks** → Invoke `backend-architect`:
   ```
   Task(backend-architect): "Analyze the implementation approach for [task description].

   Context:
   - Jira requirements: [key requirements from Step 1]
   - Current architecture: [findings from Step 2]
   - Best practices: [Context7 findings]

   Please provide:
   1. Recommended architecture approach
   2. API design considerations
   3. Database schema changes (if any)
   4. Performance implications
   5. Security considerations
   6. Potential pitfalls to avoid
   7. Testing strategy recommendations"
   ```

2. **For Frontend/UI tasks** → Invoke `frontend-developer`:
   ```
   Task(frontend-developer): "Analyze the implementation approach for [task description].

   Context:
   - Requirements: [key requirements from Step 1]
   - Current component structure: [findings from Step 2]
   - UI patterns used: [patterns found in codebase]

   Please provide:
   1. Component architecture recommendations
   2. State management approach
   3. Reusable components to leverage
   4. Styling approach (Tailwind/NativeWind patterns)
   5. Accessibility considerations
   6. Performance optimizations
   7. Testing strategy for components"
   ```

3. **For Mobile-specific tasks** → Invoke `mobile-developer`:
   ```
   Task(mobile-developer): "Analyze the implementation approach for [task description].

   Context:
   - Requirements: [key requirements from Step 1]
   - React Native version and constraints: [from package.json]
   - Current navigation patterns: [findings from Step 2]

   Please provide:
   1. Platform-specific considerations (iOS/Android)
   2. Navigation flow recommendations
   3. Offline sync strategy (if applicable)
   4. Native module requirements (if any)
   5. Performance optimizations for mobile
   6. Cross-platform compatibility notes
   7. Testing on different devices"
   ```

4. **For Full-Stack tasks** → Invoke both `backend-architect` AND `frontend-developer` **in parallel**:
   ```
   # Use single message with multiple Task calls
   Task(backend-architect): "[backend-specific analysis as above]"
   Task(frontend-developer): "[frontend-specific analysis as above]"
   ```

5. **For Database/Data modeling tasks** → Invoke `backend-architect` (data modeling skill):
   ```
   Task(backend-architect): "Design the data model for [task description].

   Context:
   - Current schema: [existing tables/models]
   - Requirements: [data requirements from Step 1]
   - Access patterns: [how data will be queried]

   Please provide:
   1. Schema design recommendations
   2. Indexing strategy
   3. Migration approach
   4. Data validation rules
   5. Relationships and constraints
   6. Performance considerations
   7. Backward compatibility plan"
   ```

6. **For Security-critical tasks** → Invoke `security-auditor` (in addition to primary agent):
   ```
   Task(security-auditor): "Review the security implications of [task description].

   Context:
   - Proposed approach: [from primary agent analysis]
   - Authentication/authorization requirements: [from Step 1]

   Please provide:
   1. Security vulnerabilities to address
   2. OWASP compliance checklist
   3. Authentication/authorization recommendations
   4. Data protection requirements
   5. Input validation strategy
   6. Secure coding practices to follow"
   ```

**Agent Invocation Strategy:**

- **Invoke agents sequentially** when one depends on another (e.g., backend design → security review)
- **Invoke agents in parallel** when they analyze independent aspects (e.g., backend + frontend for full-stack tasks)
- **ALWAYS wait for agent responses** before proceeding to Step 3
- **Incorporate agent insights** into the Linear issue description

**Capture Agent Insights:**

After agents respond, extract and organize their insights:

1. **Architecture recommendations** → Use in "Implementation Plan" section
2. **Technical considerations** → Add to "Technical Constraints" section
3. **Security/Performance notes** → Include in "Best Practices" section
4. **Testing strategy** → Inform checklist subtasks
5. **Pitfalls to avoid** → Document in "Considerations" section

**Example Agent Output Integration:**

```markdown
## 🤖 Engineer Agent Analysis

### Backend Architecture (backend-architect)
- **Recommended Approach**: [Agent's recommendation]
- **API Design**: [Agent's API design suggestions]
- **Database Changes**: [Agent's schema recommendations]
- **Performance**: [Agent's performance notes]
- **Security**: [Agent's security considerations]

### Frontend Architecture (frontend-developer)
- **Component Strategy**: [Agent's component recommendations]
- **State Management**: [Agent's state management approach]
- **Reusable Components**: [Components agent identified]
- **Styling Approach**: [Agent's styling recommendations]

### Security Review (security-auditor)
- **Vulnerabilities**: [Agent's identified risks]
- **Mitigation Strategy**: [Agent's recommendations]
- **Compliance**: [Agent's compliance notes]
```

### Step 3: Update Linear Issue with Research

Use **Linear MCP** to update issue $1 with comprehensive research:

**Update Status**: Planning (if not already)
**Add Labels**: planning, research-complete

**IMPORTANT - Linking Format**:

When mentioning Jira tickets, Confluence pages, or related issues, create proper markdown links:

1. **Extract URLs from MCP responses** - When fetching from Atlassian MCP, Linear MCP, or Playwright:
   - Capture full URLs from API responses
   - Save them for linking in the description

2. **Link Format Examples**:
   - **Jira tickets**: `[TRAIN-123](https://jira.company.com/browse/TRAIN-123)`
   - **Confluence pages**: `[PRD: Authentication Flow](https://confluence.company.com/display/DOCS/Authentication)`
   - **Linear issues**: `[WORK-456](https://linear.app/workspace/issue/WORK-456)`
   - **BitBucket PRs**: `[PR #123: Add JWT auth](https://bitbucket.org/company/repo/pull-requests/123)`
   - **Slack threads**: `[Discussion about auth](https://company.slack.com/archives/C123/p456789)`

3. **Link Storage**:
   - Store all discovered URLs in a map/object as you research
   - Use them when writing the description
   - Example:
     ```javascript
     const links = {
       jira: "https://jira.company.com/browse/TRAIN-123",
       confluence: {
         prd: "https://confluence.company.com/display/DOCS/PRD",
         design: "https://confluence.company.com/display/DOCS/Design"
       },
       relatedTickets: [
         { id: "TRAIN-100", url: "https://jira.company.com/browse/TRAIN-100" },
         { id: "TRAIN-101", url: "https://jira.company.com/browse/TRAIN-101" }
       ]
     }
     ```

4. **Every mention MUST be a link**:
   - ✅ `See [TRAIN-123](https://jira.company.com/browse/TRAIN-123) for details`
   - ❌ `See TRAIN-123 for details` (no link)
   - ✅ `Based on [PRD](https://confluence.company.com/display/DOCS/PRD)`
   - ❌ `Based on PRD` (no link)

**Update Description** with this structure (replace existing content):

```markdown
## ✅ Implementation Checklist

> **Status**: Planning
> **Complexity**: [Low/Medium/High]

- [ ] **Subtask 1**: [Specific, actionable description]
- [ ] **Subtask 2**: [Specific, actionable description]
- [ ] **Subtask 3**: [Specific, actionable description]
- [ ] **Subtask 4**: [Specific, actionable description]
- [ ] **Subtask 5**: [Specific, actionable description]

---

## 📋 Context

**Linear Issue**: [$1](https://linear.app/workspace/issue/$1)
**Original Jira Ticket**: [Jira $2](https://jira.company.com/browse/$2) (if available)
**Summary**: [Brief description from Jira/Linear]

## 🔍 Research Findings

### Jira/Documentation Analysis

**Key Requirements**:

- [Key requirement 1 from Jira]
- [Key requirement 2 from Jira]

**Related Tickets**:

- [TRAIN-XXX](link) - [Brief description and outcome]
- [TRAIN-YYY](link) - [Brief description and outcome]

**Design Decisions** (from PRD/Confluence):

- [Decision 1 with link to [Confluence page](link)]
- [Decision 2 with link to [Confluence page](link)]

### Codebase Analysis

**Current Architecture**:

- [How feature currently works]
- [Relevant files and their purposes]

**Patterns Used**:

- [Code patterns found in similar features]
- [Conventions to follow]

**Technical Constraints**:

- [Any limitations or considerations]

### Best Practices (from Context7)

- [Latest recommended approach 1]
- [Latest recommended approach 2]
- [Performance considerations]
- [Security considerations]

## 🤖 Engineer Agent Analysis

### Backend Architecture (backend-architect)

**Recommended Approach**:
- [Agent's recommended architecture approach]

**API Design Considerations**:
- [Agent's API design suggestions]
- [Endpoint structure recommendations]

**Database Changes**:
- [Agent's schema recommendations]
- [Migration strategy]

**Performance Implications**:
- [Agent's performance analysis]
- [Optimization opportunities]

**Security Considerations**:
- [Agent's security recommendations]
- [OWASP compliance notes]

**Potential Pitfalls**:
- [Agent's warnings about common mistakes]
- [Edge cases to handle]

**Testing Strategy**:
- [Agent's recommended testing approach]
- [Key test scenarios]

### Frontend Architecture (frontend-developer)

*(Include only if frontend work is involved)*

**Component Architecture**:
- [Agent's component structure recommendations]
- [Component breakdown]

**State Management**:
- [Agent's state management approach]
- [Data flow patterns]

**Reusable Components**:
- [Existing components to leverage]
- [New reusable components to create]

**Styling Approach**:
- [Tailwind/NativeWind patterns to use]
- [Design system integration]

**Accessibility**:
- [A11y requirements]
- [WCAG compliance notes]

**Performance**:
- [Rendering optimizations]
- [Memoization strategies]

### Mobile-Specific Considerations (mobile-developer)

*(Include only if React Native work is involved)*

**Platform Differences**:
- **iOS**: [iOS-specific considerations]
- **Android**: [Android-specific considerations]

**Navigation**:
- [Navigation flow recommendations]
- [Screen transition patterns]

**Offline Sync**:
- [Offline data strategy if applicable]

**Native Modules**:
- [Required native modules if any]

**Performance**:
- [Mobile performance optimizations]

**Testing**:
- [Device-specific testing requirements]

### Security Review (security-auditor)

*(Include only if security-critical)*

**Identified Risks**:
- [Agent's security vulnerability analysis]

**Mitigation Strategy**:
- [Recommended security controls]

**Compliance Requirements**:
- [OWASP, GDPR, or other compliance notes]

**Secure Coding Practices**:
- [Agent's secure coding recommendations]

### Cross-Repository Dependencies

[If applicable]:

- **Repository 1**: [What needs to change]
- **Repository 2**: [What needs to change]
- **Database**: [Schema changes if needed]

## 📝 Implementation Plan

**Approach**:
[Detailed explanation of how to implement this]

**Considerations**:

- [Edge cases to handle]
- [Backward compatibility]
- [Testing strategy]
- [Rollout plan if needed]

## 🔗 References

- **Linear Issue**: [$1](https://linear.app/workspace/issue/$1)
- **Original Jira**: [$2](https://jira.company.com/browse/$2) (if available)
- **Related PRD**: [Title](link to Confluence page) (if found)
- **Design Doc**: [Title](link to Confluence page) (if found)
- **Related PRs**: [PR #XXX](link to BitBucket) (if found)
- **Similar Implementation**: [file.ts:123](link to code) (if found)
```

### Step 4: Confirm Completion

After updating the Linear issue:

1. Display the Linear issue ID and current status
2. Show a summary of the research findings added
3. Confirm checklist has been created/updated
4. Provide the Linear issue URL

## Output Format

Provide a summary like:

```
✅ Planning Complete!

📋 Linear Issue Updated: $1
🔗 URL: https://linear.app/workspace/issue/$1
📝 Jira Reference: $2 (if available)

📊 Research Summary Added:
- Gathered context from [X] Jira tickets
- Found [Y] relevant Confluence docs
- Analyzed [Z] related Slack discussions
- Identified [N] files to modify
- Researched best practices from Context7

✅ Checklist: [X] subtasks created/updated

🚀 Ready for implementation! Run: /ccpm:implementation:start $1
```

## Notes

### Checklist Positioning

- **ALWAYS place checklist at the TOP** of the description
- This makes it immediately visible when opening the ticket
- Use blockquote for status and complexity metadata
- Separate checklist from detailed research with `---` horizontal rule

### Linking Best Practices

- **Every ticket/page mention MUST be a clickable link**
- Extract URLs from MCP API responses, not manual construction
- Store URLs as you research, use when writing description
- Link text should be descriptive (not just ticket ID)
- Example: `[TRAIN-123: Add JWT auth](url)` not just `[TRAIN-123](url)`

### Research Quality

- Be thorough in research - this is the foundation for successful implementation
- Always search Context7 for latest best practices
- Cross-reference multiple sources to validate approach
- If information is missing, document what's unknown in the Linear issue
- Create specific, actionable subtasks in the checklist
- Include links to ALL referenced materials (Jira, Confluence, Slack, PRs)