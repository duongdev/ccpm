# Shared Planning Workflow

This module provides the common planning workflow logic used by the `/ccpm:plan` command.

## Prerequisites

Calling commands MUST provide these context variables before executing this workflow:

**Required Variables:**
- `LINEAR_ISSUE_ID` - Linear issue ID to plan (e.g., "PSN-25")
- `JIRA_TICKET_ID` - Optional Jira ticket ID (e.g., "TRAIN-123")
- `PROJECT_CONFIG` - Project configuration loaded from `~/.claude/ccpm-config.yaml`
- `EXTERNAL_PM_ENABLED` - Boolean flag for external PM integration
- `EXTERNAL_PM_TYPE` - Type of external PM (e.g., "jira")
- `JIRA_ENABLED`, `CONFLUENCE_ENABLED`, `SLACK_ENABLED` - Feature flags

**Optional context (if already loaded):**
- `FIGMA_LINKS` - Pre-detected Figma links
- `IMAGE_ANALYSES` - Pre-analyzed images

## Workflow Steps

### Step 0.5: Detect and Analyze Images

**READ**: `helpers/image-analysis.md`

Apply the image analysis workflow to detect and analyze any images attached to or referenced in the Linear issue:

1. **Detect images** from Linear issue using detectImages(issue):
   - Extracts image attachments from Linear issue
   - Detects inline markdown images in description
   - Returns: `[{ url, title, type }]`

2. **For each detected image** (limit to first 5):
   - Determine context type: generateImagePrompt(image.title, "planning")
   - Fetch and analyze: fetchAndAnalyzeImage(image.url, prompt)
   - Collect results: `{ url, title, type, analysis }`
   - Handle errors gracefully: If analysis starts with "⚠️", log warning and continue

3. **Format results**: formatImageContext(imageAnalyses)
   - Returns formatted markdown section ready for Linear
   - Includes section header and individual image analyses
   - Preserves image URLs for implementation phase

4. **Prepare for insertion**: Store formatted image context
   - Will be inserted into Linear description in Step 4
   - Inserted after checklist, before Context section
   - Provides visual context for planning and implementation

**Performance Note**: Image analysis adds ~2-5s per image. Limiting to 5 images max to avoid excessive processing.

**Error Handling**: Never fail the entire workflow if image analysis fails. Log warnings for failed images and continue with successful ones.

**Why This Matters**:
- UI mockups provide exact design specifications for implementation
- Architecture diagrams clarify system structure and relationships
- Screenshots document current state and issues to address
- All images preserved for direct visual reference during implementation phase

### Step 0.6: Detect and Extract Figma Designs

**READ**: `commands/_shared-figma-detection.md`

After analyzing static images, check for live Figma design links that provide authoritative design system information:

1. **Detect Figma links** from Linear issue (description + comments):
   ```bash
   LINEAR_DESC=$(linear_get_issue "$LINEAR_ISSUE_ID" | jq -r '.description')
   LINEAR_COMMENTS=$(linear_get_issue "$LINEAR_ISSUE_ID" | jq -r '.comments[]? | .body' || echo "")
   FIGMA_LINKS=$(./scripts/figma-utils.sh extract-markdown "$LINEAR_DESC $LINEAR_COMMENTS")
   FIGMA_COUNT=$(echo "$FIGMA_LINKS" | jq 'length')
   ```

2. **If Figma links found** (FIGMA_COUNT > 0):
   - Select appropriate MCP server: `./scripts/figma-server-manager.sh select "$PROJECT_ID"`
   - For each Figma link:
     - Extract file_id, file_name, node_id from parsed link
     - Check cache first: `./scripts/figma-cache-manager.sh get "$LINEAR_ISSUE_ID" "$file_id"`
     - If cache miss or expired:
       - Generate MCP extraction call: `./scripts/figma-data-extractor.sh extract "$file_id" "$server"`
       - Execute MCP call via mcp__agent-mcp-gateway__execute_tool
       - Analyze design data: `./scripts/figma-data-extractor.sh generate "$figma_data"`
       - Cache result: `./scripts/figma-cache-manager.sh store "$LINEAR_ISSUE_ID" "$file_id" ...`
     - Format design system as markdown: `./scripts/figma-design-analyzer.sh format "$design_system" "$file_name"`

3. **Prepare Figma context** for Linear description:
   - Store formatted Figma analysis separately from image analysis
   - Will be inserted into Linear description in Step 4
   - Provides design tokens, component library, layout patterns

**Benefits over static images**:
- **Live data**: Always up-to-date with latest Figma changes
- **Design system**: Automatic extraction of colors, fonts, spacing
- **Tailwind mapping**: Direct mapping from Figma styles to Tailwind classes
- **Component library**: Understanding of existing design components
- **Structured data**: Machine-readable design tokens vs. visual interpretation

**Graceful Degradation**:
- If no MCP server configured → Log warning, use static images only
- If MCP call fails → Use cached data (even if stale)
- If cache miss and MCP fails → Continue without Figma context
- Never fail planning workflow due to Figma extraction issues

**Performance**: Figma extraction adds ~2-5s per file (with caching) or ~10-20s (first time).

**Integration with Images**:
- Figma designs = **authoritative** (design system, tokens, components)
- Static images = **supplementary** (specific screens, states, flows)
- Both included in Linear description, Figma prioritized for implementation

### Step 1: Gather All Context from External PM Systems

**Only if Jira ticket ID is available** (from parameter or Linear description):

1. **Use Atlassian MCP** to:
   - Fetch Jira ticket: $JIRA_TICKET_ID (or extracted from Linear)
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

Use **Linear operations subagent** to update issue $LINEAR_ISSUE_ID with comprehensive research:

**Update Status**: Planning (if not already)
**Add Labels**: planning, research-complete

**Subagent Invocation**:
```markdown
Task(linear-operations): `
operation: update_issue
params:
  issue_id: ${LINEAR_ISSUE_ID}
  state: "Planning"
  labels:
    - "planning"
    - "research-complete"
context:
  command: "planning:plan"
  purpose: "Updating issue with planning phase research"
`
```

After the subagent updates the issue, proceed to update the description with research content (see below).

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

**Update Description with Subagent**:

After formatting the comprehensive research content below, use the linear-operations subagent to update the description:

```markdown
Task(linear-operations): `
operation: update_issue
params:
  issue_id: ${LINEAR_ISSUE_ID}
  description: |
    ${FORMATTED_RESEARCH_DESCRIPTION}
context:
  command: "planning:plan"
  purpose: "Updating issue description with research findings"
`
```

**Description** structure (to be included in the subagent description update):

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

## 🖼️ Visual Context Analysis

[If images were analyzed, insert formatted image context here]

[If Figma designs extracted, insert formatted Figma context here]

## 📋 Context

**Linear Issue**: [$LINEAR_ISSUE_ID](https://linear.app/workspace/issue/$LINEAR_ISSUE_ID)
**Original Jira Ticket**: [$JIRA_TICKET_ID](https://jira.company.com/browse/$JIRA_TICKET_ID) (if available)
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

- **Linear Issue**: [$LINEAR_ISSUE_ID](https://linear.app/workspace/issue/$LINEAR_ISSUE_ID)
- **Original Jira**: [$JIRA_TICKET_ID](https://jira.company.com/browse/$JIRA_TICKET_ID) (if available)
- **Related PRD**: [Title](link to Confluence page) (if found)
- **Design Doc**: [Title](link to Confluence page) (if found)
- **Related PRs**: [PR #XXX](link to BitBucket) (if found)
- **Similar Implementation**: [file.ts:123](link to code) (if found)
```

### Step 4: Confirm Completion

After all Linear updates via subagent are complete:

1. **Fetch final issue state** using subagent:
```markdown
Task(linear-operations): `
operation: get_issue
params:
  issue_id: ${LINEAR_ISSUE_ID}
context:
  command: "planning:plan"
  purpose: "Fetching updated issue for confirmation display"
`
```

2. Display the Linear issue ID and current status
3. Show a summary of the research findings added
4. Confirm checklist has been created/updated
5. Provide the Linear issue URL
6. Show confirmation that all Linear operations completed successfully

## Output Format

Provide a summary like:

```
✅ Planning Complete!

📋 Linear Issue Updated: $LINEAR_ISSUE_ID
🔗 URL: https://linear.app/workspace/issue/$LINEAR_ISSUE_ID
📝 Jira Reference: $JIRA_TICKET_ID (if available)

📊 Research Summary Added:
- Gathered context from [X] Jira tickets
- Found [Y] relevant Confluence docs
- Analyzed [Z] related Slack discussions
- Identified [N] files to modify
- Researched best practices from Context7

✅ Checklist: [X] subtasks created/updated

🚀 Ready for implementation! Run: /ccpm:implementation:start $LINEAR_ISSUE_ID
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

## Linear Subagent Integration

This workflow uses the **linear-operations subagent** for all Linear API operations. This provides:

### Benefits

- **Token Reduction**: 50-60% fewer tokens per operation through caching and batching
- **Performance**: <50ms for cached operations, <500ms for uncached
- **Consistency**: Centralized Linear operation logic with standardized error handling
- **Maintainability**: Single source of truth for Linear operations

### Subagent Invocations in This Workflow

**Step 3.1 - Update Issue Status & Labels**:
- Operation: `update_issue`
- Sets issue to "Planning" state
- Adds labels: "planning", "research-complete"
- Uses cached team/state/label lookups

**Step 3.2 - Update Issue Description**:
- Operation: `update_issue`
- Sets comprehensive description with research findings
- Includes all linked resources (Jira, Confluence, Slack, etc.)
- Preserves markdown formatting and structure

**Step 4.1 - Fetch Final Issue State**:
- Operation: `get_issue`
- Retrieves updated issue for confirmation display
- Shows final state, labels, and status

### Caching Benefits

The subagent caches:
- Team lookups (first request populates cache, subsequent requests <50ms)
- Label existence checks (batch operation reduces MCP calls)
- State/status validation (fuzzy matching cached per team)
- Project lookups (if specified)

### Error Handling

If a subagent operation fails:

1. Check the error response for the `error.code` and `error.suggestions`
2. Most errors include available values (e.g., valid states for a team)
3. The workflow can continue partially if non-critical operations fail
4. Always re-raise errors that prevent issue creation/update

### Example Subagent Responses

**Successful State/Label Update**:
```yaml
success: true
data:
  id: "abc-123"
  identifier: "PSN-25"
  state:
    id: "state-planning"
    name: "Planning"
  labels:
    - id: "label-1"
      name: "planning"
    - id: "label-2"
      name: "research-complete"
metadata:
  cached: true
  duration_ms: 95
  mcp_calls: 1
```

**Error Response (State Not Found)**:
```yaml
success: false
error:
  code: STATUS_NOT_FOUND
  message: "Status 'InvalidState' not found for team 'Engineering'"
  suggestions:
    - "Use exact status name: 'In Progress', 'Done', etc."
    - "Use status type: 'started', 'completed', etc."
suggestions:
  - "Run /ccpm:utils:statuses to list available statuses"
```

### Migration Notes

This refactoring replaces all direct Linear MCP calls with subagent invocations:

**Before**:
```markdown
Use Linear MCP to update issue:
await mcp__linear__update_issue({
  id: issueId,
  state: "Planning",
  labels: ["planning", "research-complete"]
});
```

**After**:
```markdown
Task(linear-operations): `
operation: update_issue
params:
  issue_id: ${issueId}
  state: "Planning"
  labels: ["planning", "research-complete"]
context:
  command: "planning:plan"
`
```

### Performance Impact

Expected token reduction for this workflow:
- **Before**: ~15,000-20,000 tokens (heavy Linear MCP usage)
- **After**: ~6,000-8,000 tokens (subagent with caching)
- **Reduction**: ~55-60% fewer tokens

## Related Documentation

- **Linear Subagent**: `agents/linear-operations.md` (comprehensive operation reference)
- **Image Analysis**: `commands/_shared-image-analysis.md`
- **Figma Detection**: `commands/_shared-figma-detection.md`
- **Project Configuration**: `commands/_shared-project-config-loader.md`
- **Planning Command**: `commands/planning:plan.md`
- **Create & Plan Command**: `commands/planning:create.md`
- **CCPM Architecture**: `docs/architecture/linear-subagent-architecture.md`
