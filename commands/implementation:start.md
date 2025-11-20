---
description: Start implementation - fetch task, list agents, assign subtasks, coordinate parallel work
allowed-tools: [Bash, LinearMCP]
argument-hint: <linear-issue-id>
---

# Starting Implementation: $1

You are beginning the **Implementation Phase** for Linear issue **$1**.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

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

### Step 1.5: Prepare Visual Context for UI/Design Tasks

**READ**: `commands/_shared-image-analysis.md`

Detect UI/design subtasks and prepare visual references for pixel-perfect implementation:

```javascript
// 1. Extract all subtasks from checklist
const subtasks = extractChecklistItems(issue.description)

// 2. Detect UI/design work using keywords
const uiKeywords = /\b(UI|design|mockup|screen|component|layout|interface|visual|frontend|styling|theme)\b/i

const uiTasks = []
for (const [index, subtask] of subtasks.entries()) {
  if (uiKeywords.test(subtask.description)) {
    uiTasks.push({ index, description: subtask.description })
  }
}

// 3. If UI tasks found, detect and prepare images
if (uiTasks.length > 0) {
  console.log(`🎨 Detected ${uiTasks.length} UI/design subtask(s)`)
  
  const images = detectImages(issue)
  if (images.length > 0) {
    console.log(`📎 Found ${images.length} image(s) for visual reference`)
    
    // Map images to relevant subtasks
    const visualContext = {}
    for (const task of uiTasks) {
      // Match images to subtasks by keyword overlap
      const relevantImages = images.filter(img => 
        // Check if image title/description relates to subtask
        task.description.toLowerCase().includes(img.title.toLowerCase().split('.')[0]) ||
        img.title.toLowerCase().includes('mockup') ||
        img.title.toLowerCase().includes('design') ||
        img.title.toLowerCase().includes('wireframe')
      )
      
      if (relevantImages.length > 0) {
        visualContext[task.index] = relevantImages
      } else {
        // If no specific match, use all UI-related images
        visualContext[task.index] = images.filter(img => 
          /(mockup|design|wireframe|ui|screen|interface)/i.test(img.title)
        )
      }
    }
    
    console.log("✅ Visual context prepared for UI tasks")
    // Store visualContext for use in Step 5
  } else {
    console.log("⚠️ No images found - will implement from text descriptions")
  }
}
```

**Why This Matters**:
- **Pixel-perfect implementation**: Frontend/mobile agents see the exact design mockup
- **No information loss**: Direct visual reference vs. lossy text translation
- **Design fidelity**: ~95-100% accuracy (vs. ~70-80% from text descriptions)
- **Faster implementation**: No interpretation needed, implement directly from mockup

**Note**: Images were preserved in planning phase (Subtask 4) specifically for this step.

### Step 1.6: Load Figma Design Context

**READ**: `commands/_shared-figma-detection.md`

For UI/design tasks, check if Figma design system was extracted during planning phase:

```javascript
// 1. Check Linear description for Figma design system section
const hasFigmaContext = issue.description.includes("## 🎨 Design System Analysis")

if (hasFigmaContext && uiTasks.length > 0) {
  console.log("🎨 Figma design system found in planning")

  // 2. Extract design system data from Linear description
  // The design system includes:
  // - Color palette with Tailwind mappings
  // - Typography with font families
  // - Spacing scale with Tailwind utilities
  // - Component library
  // - Layout patterns

  // 3. Also check for cached design data in Linear comments
  const designSystemComment = issue.comments?.find(c =>
    c.body.includes("🎨 Figma Design Context") ||
    c.body.includes("Design System Analysis")
  )

  if (designSystemComment) {
    console.log("  ✓ Design tokens extracted")
    console.log("  ✓ Tailwind class mappings available")
    console.log("  ✓ Component patterns documented")
    console.log("")
    console.log("💡 Frontend agents will receive:")
    console.log("  • Exact color hex codes → Tailwind classes")
    console.log("  • Font family mappings")
    console.log("  • Spacing values → Tailwind scale")
    console.log("  • Layout patterns (flex, grid, auto-layout)")
    console.log("  • Component structure and hierarchy")
  }

  // 4. Store for passing to frontend/mobile agents
  const figmaContext = {
    hasDesignSystem: true,
    designSystemMarkdown: extractFigmaSection(issue.description),
    cacheComment: designSystemComment?.body
  }

  console.log("✅ Figma design context loaded for implementation")
} else if (uiTasks.length > 0) {
  console.log("ℹ️  No Figma design system - using static images only")
}
```

**What agents receive**:
- **Frontend Developer**: Figma design tokens + Tailwind mappings + component structure
- **Mobile Developer**: Same design system adapted for React Native
- **UI Designer**: Component library and pattern documentation

**Benefits**:
- **Consistency**: Exact color/font/spacing values from design system
- **Efficiency**: No manual color picking or spacing guessing
- **Quality**: Design system compliance guaranteed
- **Speed**: Pre-mapped Tailwind classes ready to use

**Fallback**: If no Figma context, agents use static images + text descriptions.


## 💡 Hint: Try the New Natural Command

For a simpler workflow, consider using:

```bash
/ccpm:work [issue-id]
```

**Benefits:**
- Auto-detects issue from git branch if not provided
- Auto-detects mode (start vs resume)
- Part of the 6-command natural workflow
- See: [Quick Start Guide](./README.md#quick-start)

This command still works perfectly! The hint is just a suggestion.

---

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

**READ**: `commands/_shared-linear-helpers.md`

Use **Linear MCP** to update issue status and labels:

```javascript
try {
  // Get team ID from issue
  const teamId = issue.team.id;

  // Step 4a: Get valid "In Progress" state ID
  const inProgressStateId = await getValidStateId(teamId, "In Progress");

  // Step 4b: Get or create "implementation" label
  const implementationLabel = await getOrCreateLabel(teamId, "implementation", {
    color: "#26b5ce",
    description: "CCPM: Task in implementation phase"
  });

  // Step 4c: Get current labels and remove "planning" if present
  const currentLabels = issue.labels || [];
  const currentLabelIds = currentLabels.map(l => l.id);

  // Find planning label ID to remove
  const planningLabel = currentLabels.find(l =>
    l.name.toLowerCase() === "planning"
  );

  // Build new label list: remove planning, add implementation
  let newLabelIds = currentLabelIds.filter(id =>
    id !== planningLabel?.id
  );

  // Add implementation label if not already present
  if (!currentLabels.some(l => l.name.toLowerCase() === "implementation")) {
    newLabelIds.push(implementationLabel.id);
  }

  // Step 4d: Update issue with new status and labels
  await mcp__agent-mcp-gateway__execute_tool({
    server: "linear",
    tool: "update_issue",
    args: {
      id: issue.id,
      stateId: inProgressStateId,
      labelIds: newLabelIds
    }
  });

  console.log("✅ Linear issue updated:");
  console.log("   Status: In Progress");
  console.log("   Labels: implementation (planning removed)");

} catch (error) {
  console.error("⚠️ Failed to update Linear issue:", error.message);
  console.warn("⚠️ Continuing with implementation, but status/labels may not be updated.");
  console.log("   You can manually update status in Linear if needed.");
}
```

**Step 4e: Add comment with assignment plan**:

```javascript
const commentBody = `## 🚀 Implementation Started

### Agent Assignments:
${assignmentPlan.map(group =>
  group.subtasks.map(st =>
    `- ${st.description} → ${st.agent}`
  ).join('\n')
).join('\n\n')}

### Execution Strategy:
${assignmentPlan.map((group, idx) =>
  `- Group ${idx + 1}: ${group.parallel ? 'Parallel execution' : 'Sequential execution'}`
).join('\n')}
`;

try {
  await mcp__agent-mcp-gateway__execute_tool({
    server: "linear",
    tool: "create_comment",
    args: {
      issueId: issue.id,
      body: commentBody
    }
  });

  console.log("✅ Implementation plan added to Linear comments");
} catch (error) {
  console.error("⚠️ Failed to add comment:", error.message);
  // Not critical, continue
}
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

### Invoking Frontend/Mobile Agents with Visual References

**CRITICAL for UI/Design Tasks**: When invoking frontend-developer or mobile-developer agents for UI/design subtasks:

**If visual context exists** (from Step 1.5):
```
Invoke frontend-developer to implement [UI component]:

**Design Mockup** (view directly):
- mockup-name.png: https://linear.app/attachments/[url]

Load the mockup using WebFetch:
[Agent will automatically see the image via WebFetch tool]

**Implementation Requirements**:
- Match EXACT layout and spacing from mockup above
- Extract and use exact colors (hex values from mockup)
- Match typography: font sizes, weights, line heights from mockup
- Implement component hierarchy shown in mockup
- Responsive breakpoints visible in mockup

**Available Components** (from codebase):
[List reusable components found during planning]

**Success Criteria**:
- Pixel-perfect match to mockup (~95-100% fidelity)
- All colors extracted from mockup and used correctly
- Spacing and layout matches mockup measurements
- Component structure follows mockup hierarchy
- Works on all target devices shown in mockup

**DO NOT** rely on text descriptions. Implement directly from the visual mockup loaded above.
```

**Example invocation with mockup**:
```
Invoke frontend-developer to implement login screen UI:

Context:
- Linear issue: WORK-123
- Subtask: "Implement login screen UI component"
- Files to create/modify: src/components/Auth/LoginScreen.tsx

**Design Mockup** (view directly):
- login-mockup.png: https://linear.app/attachments/abc123/login-mockup.png

Use WebFetch to load and view the mockup above. Implement the login screen to match the mockup exactly.

Implementation Requirements:
- Extract exact colors from mockup (primary blue, backgrounds, text colors)
- Match spacing and padding shown in mockup
- Implement form layout as shown (centered card, input fields, button)
- Typography: Match font sizes and weights from mockup
- Use available components: Card, Input, Button, Link

Success Criteria:
- Pixel-perfect implementation matching mockup
- All interactive elements functional
- Responsive design matches mockup behavior
- Accessibility: proper labels, keyboard navigation
- Tests pass for all functionality

DO NOT interpret or guess the design. Implement directly from the visual mockup above.
```

**Benefits of Direct Visual Reference**:
- **Eliminates translation loss**: No text interpretation needed
- **Exact design fidelity**: ~95-100% accuracy vs. ~70-80% from text
- **Faster implementation**: No back-and-forth clarifications
- **Pixel-perfect results**: Agents measure directly from mockup
- **Color accuracy**: Extract exact hex values from image
- **Layout precision**: Measure spacing and dimensions from mockup

**Fallback**: If no mockups available, proceed with text description as before.


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
### Step 1.6: Load Figma Design Context

**READ**: `commands/_shared-figma-detection.md`

If Figma links were detected during planning, load them for implementation:

```bash
# Check if Figma context exists from planning phase
FIGMA_CONTEXT_FILE="/tmp/figma-context-${1}.json"

if [ -f "$FIGMA_CONTEXT_FILE" ]; then
  FIGMA_LINKS=$(cat "$FIGMA_CONTEXT_FILE")
  FIGMA_COUNT=$(echo "$FIGMA_LINKS" | jq 'length')
  
  if [ "$FIGMA_COUNT" -gt 0 ]; then
    echo "🎨 Loaded $FIGMA_COUNT Figma design(s) from planning phase"
    
    # Display Figma context
    echo "$FIGMA_LINKS" | jq -r '.[] | "  - \(.file_name): \(.canonical_url)"'
    
    # Store for agent context
    FIGMA_AVAILABLE=true
  fi
else
  # Try to detect from Linear issue directly
  echo "ℹ️  No cached Figma context - checking Linear issue..."
  LINEAR_DESC=$(linear_get_issue "$1" | jq -r '.description')
  FIGMA_LINKS=$(./scripts/figma-utils.sh extract-markdown "$LINEAR_DESC")
  FIGMA_COUNT=$(echo "$FIGMA_LINKS" | jq 'length')
  
  if [ "$FIGMA_COUNT" -gt 0 ]; then
    echo "✅ Detected $FIGMA_COUNT Figma link(s) from Linear"
    FIGMA_AVAILABLE=true
  else
    echo "ℹ️  No Figma designs found"
    FIGMA_AVAILABLE=false
  fi
fi
```

**Map Figma Designs to UI Subtasks**

For UI/design subtasks identified in Step 1.5, map relevant Figma links:

```javascript
if (figmaAvailable && uiTasks.length > 0) {
  console.log("🎨 Mapping Figma designs to UI subtasks...")
  
  const figmaContext = {}
  for (const task of uiTasks) {
    // Match Figma designs to subtasks by keyword overlap
    const relevantDesigns = figmaLinks.filter(design => 
      task.description.toLowerCase().includes(design.file_name.toLowerCase()) ||
      design.file_name.toLowerCase().includes('ui') ||
      design.file_name.toLowerCase().includes('design') ||
      design.file_name.toLowerCase().includes('mockup')
    )
    
    if (relevantDesigns.length > 0) {
      figmaContext[task.index] = relevantDesigns
      console.log(`  ✅ Subtask ${task.index + 1}: ${relevantDesigns.length} Figma design(s)`)
    } else {
      // Use all Figma links as fallback
      figmaContext[task.index] = figmaLinks
      console.log(`  ℹ️ Subtask ${task.index + 1}: Using all Figma designs`)
    }
  }
  
  console.log("✅ Figma context mapped for pixel-perfect implementation")
  // Store figmaContext for use in Step 5 (agent invocation)
}
```

**Agent Context Enhancement**

When invoking frontend/mobile agents for UI tasks:

```javascript
// In Step 5: Assign Subtasks to Agents
if (subtask.hasVisualContext) {
  const images = visualContext[subtask.index] || []
  const figma = figmaContext[subtask.index] || []
  
  agentPrompt += `

**Visual References**:
- Images: ${images.length} screenshot(s)/mockup(s) attached
${images.map((img, i) => `  ${i+1}. ${img.title}: ${img.url}`).join('\n')}

- Figma Designs: ${figma.length} live design(s) available
${figma.map((design, i) => `  ${i+1}. ${design.file_name}: ${design.canonical_url}`).join('\n')}

**Implementation Priority**:
1. Use Figma as authoritative design source (live, up-to-date)
2. Use images for quick visual reference
3. Implement pixel-perfect from Figma specifications
`
}
```

**Why This Matters**:
- **Authoritative Source**: Figma is the live design specification
- **Always Current**: Unlike static images, Figma shows latest design iterations
- **Precise Specifications**: Access to exact measurements, colors, spacing
- **Component Mapping**: Direct reference for component implementation
- **Design Fidelity**: ~98-100% accuracy (vs. ~95% from images, ~70% from text)

**Performance**: Loading Figma context adds <100ms (file read). Phase 2 will enable on-demand MCP extraction (~1-3s per design).

**Error Handling**: If Figma links unavailable, fall back to images → text descriptions (graceful degradation).

