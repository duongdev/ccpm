---
description: Start UI design process with multiple design options and wireframes
allowed-tools: [Task, LinearMCP, Context7MCP, AskUserQuestion, Read, Grep, Glob]
argument-hint: <issue-id>
---

# UI Design Planning: $1

You are initiating the **UI Design Planning Phase** for Linear issue **$1**.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

This command is **READ-ONLY** for external systems and **WRITE** to Linear (internal tracking).

## Workflow

### Step 1: Fetch Linear Issue Context

Use **Linear MCP** to get issue details:

```javascript
linear_get_issue({ id: "$1" })
```

Extract:
- Issue title and description
- Attachments (screenshots, references)
- Comments with design feedback
- Related issues
- Project and team context

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎨 Starting UI Design for $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: [Title from Linear]
📝 Description: [Brief summary]
🔗 URL: https://linear.app/workspace/issue/$1
📎 Attachments: [X] screenshot(s) found

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 1.5: Analyze Reference Mockups

**READ**: `commands/_shared-image-analysis.md`

If the user has attached reference mockups or screenshots, analyze them before generating design options:

```javascript
const images = detectImages(issue)
if (images.length > 0) {
  console.log("📎 Found " + images.length + " reference image(s)")
  
  // Analyze each reference
  const references = []
  for (const img of images) {
    const prompt = generateImagePrompt(img.title, "design reference")
    const analysis = fetchAndAnalyzeImage(img.url, prompt)
    references.push({ ...img, analysis })
  }
  
  // Use analysis to inform design options
  console.log("✅ Reference analysis complete")
  console.log("Using design patterns and elements from references...")
}
```

**Benefits**:
- Understand user's design preferences and expectations
- Identify design patterns and elements to incorporate
- Extract colors, typography, and layout preferences
- Ensure design options align with provided references

**Note**: If no references found, proceed with Step 1.6 to check for Figma designs.

### Step 1.6: Detect and Analyze Figma Designs

**READ**: `commands/_shared-figma-detection.md`

Before asking user requirements, check if there are Figma design links in the Linear issue:

```bash
# 1. Extract Linear description and comments
LINEAR_DESC=$(linear_get_issue "$1" | jq -r '.description')
LINEAR_COMMENTS=$(linear_get_issue "$1" | jq -r '.comments[]? | .body' | tr '\n' ' ' || echo "")

# 2. Detect Figma links
FIGMA_LINKS=$(./scripts/figma-utils.sh extract-markdown "$LINEAR_DESC $LINEAR_COMMENTS")
FIGMA_COUNT=$(echo "$FIGMA_LINKS" | jq 'length')

if [ "$FIGMA_COUNT" -gt 0 ]; then
  echo "🎨 Found $FIGMA_COUNT Figma design(s) - analyzing..."

  # 3. Select MCP server for project
  PROJECT_ID=$(linear_get_issue "$1" | jq -r '.projectId // ""')
  FIGMA_SERVER=$(./scripts/figma-server-manager.sh select "$PROJECT_ID")

  if [ -n "$FIGMA_SERVER" ]; then
    # 4. Extract and analyze each Figma design
    echo "$FIGMA_LINKS" | jq -c '.[]' | while read -r link; do
      FILE_ID=$(echo "$link" | jq -r '.file_id')
      FILE_NAME=$(echo "$link" | jq -r '.file_name')

      echo "  📐 Analyzing: $FILE_NAME"

      # Generate MCP call for data extraction
      MCP_INSTRUCTION=$(./scripts/figma-data-extractor.sh extract "$FILE_ID" "$FIGMA_SERVER")

      # Claude should execute the MCP call here
      # FIGMA_DATA=$(execute MCP call based on MCP_INSTRUCTION)

      # Then analyze the design data
      # DESIGN_SYSTEM=$(echo "$FIGMA_DATA" | ./scripts/figma-design-analyzer.sh generate -)

      # Cache in Linear for future use
      # ./scripts/figma-cache-manager.sh store "$1" "$FILE_ID" "$FILE_NAME" "$(echo "$link" | jq -r '.url')" "$FIGMA_SERVER" "$DESIGN_SYSTEM"
    done

    echo "  ✅ Figma design analysis complete"
    echo "  💡 Design system extracted - will inform UI design options"
  else
    echo "  ⚠️  No Figma MCP server configured - skipping automated extraction"
    echo "  ℹ️  You can still manually reference Figma links: $(echo "$FIGMA_LINKS" | jq -r '.[0].url')"
  fi
fi
```

**What this enables:**
- **Automatic Design System Detection**: Extract colors, fonts, spacing from Figma
- **Component Analysis**: Understand existing component library
- **Design Token Mapping**: Map Figma styles to Tailwind classes
- **Consistency**: Ensure generated designs match existing design system

**Fallback**: If no Figma MCP server or extraction fails, proceed with Step 2 user questions.

**Note**: Figma design data is cached in Linear comments for reuse during implementation.


### Step 2: Gather User Requirements

Use **AskUserQuestion** to collect design requirements:

```javascript
{
  questions: [
    {
      question: "What is the primary goal of this UI?",
      header: "Goal",
      multiSelect: false,
      options: [
        {
          label: "Display information",
          description: "Show data to users (dashboard, profile, list)"
        },
        {
          label: "Collect input",
          description: "Forms, settings, creation flows"
        },
        {
          label: "Enable actions",
          description: "Buttons, controls, interactive elements"
        },
        {
          label: "Navigate content",
          description: "Menus, tabs, navigation bars"
        }
      ]
    },
    {
      question: "What devices should this design prioritize?",
      header: "Devices",
      multiSelect: true,
      options: [
        {
          label: "Mobile (phones)",
          description: "320px-639px, touch-first"
        },
        {
          label: "Tablet",
          description: "640px-1023px, hybrid input"
        },
        {
          label: "Desktop",
          description: "1024px+, mouse/keyboard"
        },
        {
          label: "All equally",
          description: "Fully responsive across all devices"
        }
      ]
    },
    {
      question: "What aesthetic are you aiming for?",
      header: "Aesthetic",
      multiSelect: false,
      options: [
        {
          label: "Minimal & Clean",
          description: "Generous whitespace, subtle colors, simple"
        },
        {
          label: "Bold & Vibrant",
          description: "Strong colors, high contrast, energetic"
        },
        {
          label: "Professional",
          description: "Corporate, trustworthy, conventional"
        },
        {
          label: "Modern & Trendy",
          description: "Latest design trends, cutting-edge"
        }
      ]
    },
    {
      question: "Any specific design constraints or preferences?",
      header: "Constraints",
      multiSelect: true,
      options: [
        {
          label: "Must match existing pages",
          description: "Consistency with current design system"
        },
        {
          label: "Accessibility is critical",
          description: "WCAG AAA compliance, screen reader support"
        },
        {
          label: "Performance matters",
          description: "Fast loading, minimal animations"
        },
        {
          label: "Dark mode required",
          description: "Must support dark mode from start"
        }
      ]
    }
  ]
}
```

**Document Responses**:
- Store all answers for design generation
- Note any "Other" responses with custom text
- Identify priority constraints

### Step 3: Frontend Architecture Analysis (CRITICAL)

**ALWAYS collaborate with frontend agent FIRST** to understand:

**Invoke Frontend Agent**:

```javascript
// The smart-agent-selector will automatically choose the right frontend agent
Task(frontend-mobile-development:frontend-developer): `
Analyze the current frontend architecture and patterns to inform UI design for [feature name from Linear issue].

**Analysis Needed**:
1. Component architecture patterns (atomic design, feature-based, etc.)
2. State management approach (TanStack Query, Context, Redux, Zustand)
3. Styling patterns (Tailwind classes, CSS-in-JS, etc.)
4. Existing reusable components (list with file paths)
5. Component composition patterns
6. Data flow patterns (props, Context, state management)
7. Routing/navigation conventions
8. Performance patterns (lazy loading, memoization)
9. Accessibility patterns (existing implementations)
10. Technical constraints (platform limitations, performance budgets)

**Deliverable**:
Comprehensive frontend context document that covers:
- What component patterns are used
- Which components can be reused
- What conventions to follow
- What technical constraints exist
- What performance considerations apply
`

// OR if React Native/Mobile project
Task(frontend-mobile-development:mobile-developer): `
[Same analysis adapted for React Native/mobile patterns]
`
```

**Expected Output**:
- Component architecture documentation
- List of reusable components with paths
- Project conventions and patterns
- Technical constraints
- Performance considerations

Display summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏗️ Frontend Architecture Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Component Patterns**: [Description from frontend agent]
**State Management**: [Approach]
**Styling**: [Method]
**Existing Components**: [X] reusable components found
- [Component 1] at [path]
- [Component 2] at [path]
- [...]

**Technical Constraints**:
- [Constraint 1]
- [Constraint 2]

**Conventions to Follow**:
- [Convention 1]
- [Convention 2]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Why This Matters**:
- Ensures designs fit existing technical patterns
- Maximizes component reuse (saves development time)
- Avoids proposing infeasible implementations
- Maintains consistency with current architecture
- Reduces back-and-forth during implementation

### Step 4: Analyze Existing Design System

**Scan codebase for design configurations**:

Use **Glob** and **Read** to find:

```bash
# Tailwind configuration
tailwind.config.{js,ts}

# NativeWind configuration
nativewind.config.js

# shadcn-ui configuration
components.json

# Global styles
globals.css
index.css
app.css

# Theme files
**/theme/**/*.{ts,js}
**/styles/**/*.{ts,js}
```

**Extract Design Tokens**:
- **Colors**: Primary, secondary, accent, semantic colors
- **Typography**: Font families, sizes, weights
- **Spacing**: Padding/margin scale
- **Borders**: Radius, widths
- **Shadows**: Box shadow configurations
- **Breakpoints**: Mobile, tablet, desktop

**Find Existing Components**:

```bash
# Search for component directories
components/ui/*.{tsx,ts}
components/primitives/*.{tsx,ts}
src/components/**/*.{tsx,ts}
```

Document:
- Available shadcn-ui components
- Custom components
- Reusable primitives
- Component patterns used

Display summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Design System Detected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Framework**: [Tailwind CSS / NativeWind]
**Components**: [shadcn-ui / reactreusables / Custom]

**Colors**:
- Primary: #2563eb (blue-600)
- Secondary: #4b5563 (gray-600)
- Accent: #a855f7 (purple-500)
[...]

**Typography**:
- Font: Inter
- Base: 16px (text-base)
- Scale: 12px, 14px, 16px, 20px, 24px, 30px, 36px

**Spacing**: 4px grid (Tailwind default)

**Components Found**: [X] components
- Button, Card, Input, Dialog, [...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5: Research Current Design Trends

**CRITICAL: Use Context7 MCP for latest documentation**:

```javascript
// Resolve library IDs first
resolve-library-id({ libraryName: "tailwind" })
resolve-library-id({ libraryName: "shadcn-ui" })
resolve-library-id({ libraryName: "nativewind" })

// Fetch current best practices
get-library-docs({
  context7CompatibleLibraryID: "/tailwindlabs/tailwindcss",
  topic: "modern UI design patterns and components",
  tokens: 3000
})

get-library-docs({
  context7CompatibleLibraryID: "/shadcn-ui/ui",
  topic: "component composition and design patterns",
  tokens: 2000
})
```

**Research Topics**:
- Latest component patterns (cards, navigation, forms)
- Modern color trends and dark mode strategies
- Typography best practices
- Accessibility guidelines (ARIA, semantic HTML)
- Mobile-first design patterns
- Animation and transition trends

**Summarize Findings**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Current Design Trends (from Context7)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Layout Trends**:
- Card-based layouts with subtle shadows
- Generous whitespace (8px grid)
- Bento-style grids (Pinterest-like)

**Color Trends**:
- Neutral-based palettes with vibrant accents
- Dark mode as default consideration
- 60-30-10 rule (60% neutral, 30% secondary, 10% accent)

**Typography**:
- Large, bold headings (36px+)
- Readable body text (16px minimum)
- Variable fonts for performance

**Interactions**:
- Micro-animations (scale, fade)
- Hover lift effects (translate-y)
- Smooth transitions (200-300ms)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 6: Invoke pm:ui-designer Agent

**CRITICAL: Invoke the specialist agent to generate design options**:

```javascript
Task(pm:ui-designer): `
Generate UI design options for Linear issue $1.

**Context**:
- Issue: [Title and description]
- User Requirements: [From AskUserQuestion responses]
- Design System: [Detected design tokens and components]
- Design Trends: [From Context7 research]
- Screenshot References: [Describe any attachments found]

**Requirements**:
1. Generate 2-3 design options
2. Include ASCII wireframes for each option
3. Provide detailed descriptions with pros/cons
4. Consider responsive behavior (mobile, tablet, desktop)
5. Ensure accessibility (WCAG 2.1 AA minimum)
6. Map to existing component library where possible
7. Follow detected design system strictly

**Deliverable**:
Present design options in structured markdown format with:
- ASCII wireframes
- Design descriptions
- Pros and cons
- Technical considerations
- Component mapping
`
```

**Agent Output Expected**:
- 2-3 design options with wireframes
- Detailed pros/cons for each
- Technical complexity assessment
- Component breakdown (including reuse of existing components)
- Accessibility considerations
- Architecture alignment notes

### Step 7: Present Design Options to User

**Display agent output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎨 Design Options Generated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Agent's design options output here]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 8: Collect User Feedback

Use **AskUserQuestion** for design selection:

```javascript
{
  questions: [{
    question: "Which design option do you prefer?",
    header: "Design Choice",
    multiSelect: false,
    options: [
      {
        label: "⭐ Option 1: [Name]",
        description: "[Brief summary from agent output]"
      },
      {
        label: "Option 2: [Name]",
        description: "[Brief summary from agent output]"
      },
      {
        label: "Option 3: [Name]",
        description: "[Brief summary from agent output]"
      },
      {
        label: "Refine Option 1",
        description: "I like Option 1 but want to make changes"
      },
      {
        label: "Refine Option 2",
        description: "I like Option 2 but want to make changes"
      },
      {
        label: "Refine Option 3",
        description: "I like Option 3 but want to make changes"
      },
      {
        label: "Need different options",
        description: "Show me completely different approaches"
      }
    ]
  }]
}
```

### Step 9: Handle User Selection

**If user approves an option** (Option 1, 2, or 3):
- Jump to `/ccpm:planning:design-approve $1 [option-number]`
- This will generate full UI specifications

**If user wants refinement**:
- Prompt for feedback: "What would you like to change about [Option X]?"
- Store feedback
- Jump to `/ccpm:planning:design-refine $1 [option-number] [feedback]`

**If user wants different options**:
- Ask: "What kind of approach are you looking for?"
- Restart from Step 6 with new direction

### Step 10: Update Linear Issue

Use **Linear MCP** to update issue with design progress:

```javascript
linear_update_issue({
  id: "$1",
  labels: ["design-in-progress"], // Add label
  description: "[Existing description]\n\n---\n\n## 🎨 UI Design Options\n\n[Design options generated by agent]\n\n**User Feedback**: [Awaiting selection / Selected Option X / Requested refinement]"
})
```

### Step 11: Show Status & Next Actions

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ UI Design Options Presented
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: $1
🎨 Design Options: [X] generated
🔗 Linear: https://linear.app/workspace/issue/$1
🏷️  Status: design-in-progress

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Once you've selected a design option above, I'll:
1. Generate comprehensive UI specifications
2. Create component breakdown with TypeScript interfaces
3. Document Tailwind classes and responsive behavior
4. Add accessibility and dark mode guidelines
5. Prepare developer handoff documentation

Or you can:
- Refine an option (select "Refine Option X" above)
- Request different approaches (select "Need different options")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Refine:       /ccpm:planning:design-refine $1 [option-number]
Approve:      /ccpm:planning:design-approve $1 [option-number]
Status:       /ccpm:utils:status $1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

### This Command Does

1. ✅ Fetches Linear issue context and attachments
2. ✅ Gathers user requirements interactively
3. ✅ **Invokes frontend agent to analyze architecture and patterns** (CRITICAL)
4. ✅ Analyzes existing design system automatically
5. ✅ Researches latest design trends via Context7
6. ✅ Invokes pm:ui-designer agent with frontend context for expert design options
7. ✅ Ensures designs reuse existing components and follow project conventions
8. ✅ Presents 2-3 design options with wireframes
9. ✅ Collects user feedback interactively
10. ✅ Updates Linear with design progress
11. ✅ Suggests next actions

### Usage Examples

**Basic usage**:
```bash
/ccpm:planning:design-ui WORK-123
```

**With existing Linear issue**:
```bash
# Issue already has description and requirements
/ccpm:planning:design-ui WORK-456
```

**After spec is written**:
```bash
# Use after /ccpm:spec:write to design the UI
/ccpm:planning:design-ui WORK-789
```

### Benefits

- ✅ Interactive requirements gathering
- ✅ **Frontend architecture analysis ensures technical feasibility**
- ✅ **Maximizes reuse of existing components**
- ✅ **Designs follow project conventions automatically**
- ✅ Automatic design system detection
- ✅ Latest design trends via Context7
- ✅ Expert design options from pm:ui-designer agent
- ✅ Visual wireframes (ASCII art)
- ✅ Comprehensive pros/cons analysis
- ✅ Seamless flow to refinement or approval
- ✅ Linear integration for tracking
- ✅ **Reduces implementation time and back-and-forth**

### Step 1.6: Detect Figma Design Links

**READ**: `commands/_shared-figma-detection.md`

Check if the Linear issue or related documentation contains Figma design links:

```bash
# Detect Figma links from Linear issue
LINEAR_DESC=$(linear_get_issue "$1" | jq -r '.description')
LINEAR_COMMENTS=$(linear_get_issue "$1" | jq -r '.comments[] | .body')
FIGMA_LINKS=$(./scripts/figma-utils.sh extract-markdown "$LINEAR_DESC $LINEAR_COMMENTS")
FIGMA_COUNT=$(echo "$FIGMA_LINKS" | jq 'length')

if [ "$FIGMA_COUNT" -gt 0 ]; then
  echo "✅ Found $FIGMA_COUNT Figma design(s) - will use as authoritative source"
  FIGMA_AVAILABLE=true
  
  # Display detected Figma links
  echo "🎨 Figma Designs:"
  echo "$FIGMA_LINKS" | jq -r '.[] | "  - \(.file_name): \(.canonical_url)"'
  
  # Determine workflow mode
  DESIGN_MODE="figma-based"  # Use Figma as primary source
else
  echo "ℹ️  No Figma links found - will generate design options from requirements"
  FIGMA_AVAILABLE=false
  DESIGN_MODE="generative"    # Generate design options
fi
```

**Workflow Decision Tree**

Based on Figma availability, choose the appropriate workflow:

```javascript
if (figmaAvailable) {
  // MODE: Figma-Based Design
  // Skip Step 2 (user requirements) - extract from Figma instead
  // Modify Step 6 to use Figma data instead of generating wireframes
  
  console.log("📋 Workflow: Figma-Based Design")
  console.log("  ✓ Skip requirements gathering (extract from Figma)")
  console.log("  ✓ Load Figma designs via MCP (Phase 2)")
  console.log("  ✓ Generate specifications from Figma data")
  console.log("  ✓ Create developer-ready component breakdown")
  
} else {
  // MODE: Generative Design  
  // Continue with Step 2 (gather requirements)
  // Continue with Step 6 (generate ASCII wireframes)
  
  console.log("📋 Workflow: Generative Design")
  console.log("  ✓ Gather user requirements")
  console.log("  ✓ Analyze existing codebase patterns")
  console.log("  ✓ Generate multiple design options")
  console.log("  ✓ Create ASCII wireframes for approval")
}
```

**Modified Step 2 (Conditional)**

```javascript
if (designMode === "figma-based") {
  console.log("⏭️  Skipping requirements gathering - using Figma as source")
  // Jump to Step 3: Analyze Frontend Architecture
} else {
  // Execute original Step 2: Gather User Requirements
  // (AskUserQuestion for goal, devices, aesthetic, constraints)
}
```

**Why This Matters**:
- **Design Authority**: If Figma exists, it's the authoritative design specification
- **Efficiency**: Skip manual requirements gathering when design already exists
- **Accuracy**: Extract actual design data instead of making assumptions
- **Consistency**: Ensure implementation matches approved designs

**Phase 1 vs Phase 2**:
- **Phase 1 (Current)**: Detect Figma links, skip ASCII wireframes if Figma found
- **Phase 2 (Future)**: Extract design data from Figma via MCP, generate component specs

