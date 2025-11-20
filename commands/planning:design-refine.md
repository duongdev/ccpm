---
description: Refine a UI design option based on user feedback
allowed-tools: [Task, LinearMCP, Context7MCP, AskUserQuestion, Read]
argument-hint: <issue-id> [option-number] [feedback]
---

# Refining UI Design: $1 - Option $2

You are **refining a design option** for Linear issue **$1** based on user feedback.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

This command is **READ-ONLY** for external systems and **WRITE** to Linear (internal tracking).

## Arguments

- **$1**: Linear issue ID (e.g., WORK-123)
- **$2**: Option number to refine (1, 2, or 3) - OPTIONAL if feedback is clear
- **$3+**: User feedback describing what to change - OPTIONAL (will prompt if missing)

## Workflow

### Step 1: Fetch Current Design Options

Use **Linear MCP** to get issue details:

```javascript
linear_get_issue({ id: "$1" })
```

Extract:
- Previous design options from description
- Which option user selected for refinement (if $2 not provided)
- Any previous feedback or comments
- Original requirements

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Refining Design Option $2 for $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: [Title from Linear]
🎨 Refining: Option $2
🔗 URL: https://linear.app/workspace/issue/$1

**Current Design** (Option $2):
[Display the selected option's wireframe and description]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 2: Collect Refinement Feedback

**If $3 (feedback) not provided**, use **AskUserQuestion**:

```javascript
{
  questions: [
    {
      question: "What would you like to change about Option $2?",
      header: "Changes",
      multiSelect: true,
      options: [
        {
          label: "Layout/Structure",
          description: "Change how elements are arranged"
        },
        {
          label: "Visual Style",
          description: "Adjust colors, spacing, shadows"
        },
        {
          label: "Component Choice",
          description: "Use different components or patterns"
        },
        {
          label: "Responsive Behavior",
          description: "Change mobile/tablet/desktop layouts"
        },
        {
          label: "Interactions",
          description: "Modify hover, click, animation effects"
        },
        {
          label: "Content Priority",
          description: "Emphasize different information"
        }
      ]
    },
    {
      question: "Please describe the specific changes you want:",
      header: "Details",
      multiSelect: false,
      options: [
        {
          label: "Type custom feedback",
          description: "I'll describe exactly what I want"
        }
      ]
    }
  ]
}
```

**Get detailed feedback**:
- What user wants to change
- Why the current design doesn't work
- Any specific examples or references
- Priority of changes (must-have vs nice-to-have)

**Example feedback types**:
- "Make it more minimalist" → Reduce visual weight, increase whitespace
- "Add more color" → Introduce color accents, vibrant palette
- "Better hierarchy" → Adjust typography, spacing, contrast
- "Improve mobile" → Larger touch targets, better stacking
- "More modern" → Latest trends, animations, gradients
- "Simpler" → Remove complexity, fewer elements
- "More professional" → Conservative colors, clean lines

### Step 3: Analyze Feedback & Plan Changes

**Parse feedback to identify**:
1. **What stays** (elements user likes)
2. **What changes** (specific adjustments)
3. **What's added** (new elements)
4. **What's removed** (unnecessary elements)

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Change Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Feedback**: [User's feedback]

**Change Type**: [Layout / Visual Style / Component / Responsive / Interaction / Content]

**Interpretation**:
[Explain what changes are needed and why]

**Planned Adjustments**:
✅ Keep: [Elements that stay the same]
🔄 Change: [Elements to modify]
➕ Add: [New elements]
➖ Remove: [Elements to remove]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Research Context (if needed)

**If feedback requires new patterns**, use **Context7 MCP**:

```javascript
// Example: User wants "more modern card design"
get-library-docs({
  context7CompatibleLibraryID: "/shadcn-ui/ui",
  topic: "modern card component patterns and styles",
  tokens: 2000
})

// Example: User wants "better mobile navigation"
get-library-docs({
  context7CompatibleLibraryID: "/tailwindlabs/tailwindcss",
  topic: "mobile navigation patterns and responsive menus",
  tokens: 2000
})
```

### Step 5: Invoke pm:ui-designer Agent for Refinement

**CRITICAL: Invoke the specialist agent**:

```javascript
Task(pm:ui-designer): `
Refine design Option $2 for Linear issue $1 based on user feedback.

**Original Design (Option $2)**:
[Include the original wireframe and description]

**User Feedback**:
[User's feedback and requested changes]

**Change Analysis**:
- Keep: [What stays]
- Change: [What modifies]
- Add: [What's new]
- Remove: [What goes]

**Requirements**:
1. Generate refined design that addresses ALL feedback
2. Include ASCII wireframe showing the changes
3. Explain what changed and why
4. Show before/after comparison for major changes
5. Maintain consistency with design system
6. Preserve what user liked about original
7. Ensure changes improve the design, not just differ

**Additional Context**:
- **Frontend Architecture**: [From original design-ui analysis - component patterns, existing components, conventions]
- Design System: [From codebase]
- Original Requirements: [From issue]
- Latest Trends: [From Context7 if fetched]

**Constraints**:
- Must still reuse existing components where possible
- Must follow project conventions
- Must remain technically feasible
- Changes should not conflict with architecture

**Deliverable**:
Present refined design in structured markdown format with:
- Updated ASCII wireframe
- Description of changes made
- Explanation of how feedback was addressed
- Before/after comparison (if significant changes)
- Updated pros/cons
- Technical considerations
`
```

**Agent Output Expected**:
- Refined design wireframe
- Clear explanation of what changed
- Before/after comparison
- How feedback was addressed
- Updated pros/cons

### Step 6: Present Refined Design

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎨 Refined Design Option $2
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Agent's refined design output]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Changes Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Addressed Feedback**:
✅ [Feedback point 1]: [How it was addressed]
✅ [Feedback point 2]: [How it was addressed]
✅ [Feedback point 3]: [How it was addressed]

**What Changed**:
- [Change 1 with explanation]
- [Change 2 with explanation]
- [Change 3 with explanation]

**What Stayed the Same**:
- [Element 1 - kept because it worked]
- [Element 2 - user liked it]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 7: Collect User Feedback on Refinement

Use **AskUserQuestion**:

```javascript
{
  questions: [{
    question: "Does this refined design meet your needs?",
    header: "Approval",
    multiSelect: false,
    options: [
      {
        label: "⭐ Approve this design",
        description: "Perfect! Generate full UI specifications"
      },
      {
        label: "Needs further refinement",
        description: "Close, but I want more adjustments"
      },
      {
        label: "Go back to original",
        description: "The original Option $2 was better"
      },
      {
        label: "Try different approach",
        description: "Let's explore a completely different direction"
      }
    ]
  }]
}
```

### Step 8: Handle User Response

**If user approves**:
- Jump to `/ccpm:planning:design-approve $1 $2-refined`
- Generate full UI specifications

**If user wants further refinement**:
- Prompt: "What else would you like to adjust?"
- Store additional feedback
- Return to Step 5 with cumulative feedback

**If user wants original**:
- Restore original Option $2 design
- Ask: "What about the original did you prefer?"
- Consider showing both side-by-side

**If user wants different approach**:
- Jump back to `/ccpm:planning:design-ui $1`
- Start fresh with new direction

### Step 9: Update Linear Issue

Use **Linear MCP** to update with refinement progress:

```javascript
linear_update_issue({
  id: "$1",
  description: "[Existing description with design options]\n\n---\n\n## 🔄 Design Refinement (Option $2)\n\n**User Feedback**: [Feedback]\n\n**Refined Design**:\n[Refined wireframe and description]\n\n**Changes Made**: [List of changes]\n\n**Status**: [Awaiting approval / Approved / Needs more refinement]"
})

// If approved, add label
linear_update_issue({
  id: "$1",
  labels: ["design-approved"]
})
```

### Step 10: Show Status & Next Actions

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Design Refinement Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: $1
🎨 Refined: Option $2
🔗 Linear: https://linear.app/workspace/issue/$1
🏷️  Status: [design-approved / design-in-progress]

📝 Changes Made: [X] adjustments
✅ Feedback Addressed: [Y] points

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[If approved]:
Perfect! I'll now generate comprehensive UI specifications including:
- Component breakdown with TypeScript interfaces
- Tailwind class mappings
- Responsive behavior documentation
- Accessibility guidelines
- Dark mode implementation
- Animation and interaction specs

[If needs more refinement]:
I can refine further. Just describe what else needs adjusting.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Approve:      /ccpm:planning:design-approve $1 $2
Refine more:  /ccpm:planning:design-refine $1 $2 [new feedback]
Status:       /ccpm:utils:status $1
Start over:   /ccpm:planning:design-ui $1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Refinement Patterns

### Common Feedback Types

**"Make it more minimalist"**:
- Increase whitespace (gap-6 → gap-8)
- Reduce visual elements (remove borders, shadows)
- Simplify color palette (fewer accent colors)
- Use more subtle typography (lighter weights)

**"Add more color/personality"**:
- Introduce accent colors (primary, secondary)
- Add gradient backgrounds
- Use colorful icons or illustrations
- Implement subtle animations

**"Improve information hierarchy"**:
- Increase heading size/weight
- Add visual separators (borders, backgrounds)
- Use color to emphasize important elements
- Adjust spacing to group related items

**"Better mobile experience"**:
- Stack elements vertically
- Increase touch target sizes (min 44x44px)
- Simplify navigation (hamburger menu)
- Reduce content density

**"More modern/trendy"**:
- Use latest component patterns (from Context7)
- Add micro-interactions (hover effects, transitions)
- Implement glass-morphism or neumorphism
- Use modern typography (variable fonts)

**"Simpler/Less complex"**:
- Remove secondary features
- Combine similar elements
- Reduce the number of sections
- Use progressive disclosure (hide details)

**"More professional/corporate"**:
- Use conservative colors (blues, grays)
- Formal typography (sans-serif, medium weights)
- Grid-based layouts
- Subtle effects only

### Iteration Strategy

**First Refinement** (this command):
- Address primary feedback
- Make targeted changes
- Preserve what worked

**Second Refinement** (if needed):
- Fine-tune details
- Adjust based on cumulative feedback
- Consider showing multiple micro-variants

**Third+ Refinement** (rarely needed):
- If still not right, consider:
  - Going back to original options
  - Generating completely new options
  - Having a design discussion about requirements

## Notes

### This Command Does

1. ✅ Fetches current design options from Linear
2. ✅ Collects specific refinement feedback
3. ✅ Analyzes what needs to change vs what stays
4. ✅ Researches new patterns if needed (Context7)
5. ✅ Invokes pm:ui-designer agent for expert refinement
6. ✅ Presents refined design with before/after comparison
7. ✅ Explains how feedback was addressed
8. ✅ Handles approval or further iteration
9. ✅ Updates Linear with refinement progress

### Usage Examples

**Basic usage** (will prompt for feedback):
```bash
/ccpm:planning:design-refine WORK-123 2
```

**With inline feedback**:
```bash
/ccpm:planning:design-refine WORK-123 2 "Make it more minimalist with larger spacing"
```

**After design-ui command**:
```bash
# After running /ccpm:planning:design-ui WORK-123
# User selected "Refine Option 2"
/ccpm:planning:design-refine WORK-123 2
```

**Multiple refinements**:
```bash
# First refinement
/ccpm:planning:design-refine WORK-123 2 "Add more color"

# After reviewing, second refinement
/ccpm:planning:design-refine WORK-123 2 "Good but reduce the amount of purple"
```

### Benefits

- ✅ Targeted refinements without starting over
- ✅ Preserves what user liked
- ✅ Clear before/after comparison
- ✅ Explains how feedback was addressed
- ✅ Iterative improvement workflow
- ✅ Context-aware changes using Context7
- ✅ Expert refinement from pm:ui-designer agent
- ✅ Linear tracking of all refinements
