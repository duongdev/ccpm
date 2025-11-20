---
description: Approve final UI design and generate comprehensive developer specifications
allowed-tools: [Task, LinearMCP, Context7MCP, Read, Grep, Glob, AskUserQuestion]
argument-hint: <issue-id> <option-number>
---

# Approving UI Design: $1 - Option $2

You are **approving the final UI design** and generating **comprehensive developer specifications** for Linear issue **$1**.

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

This command is **READ-ONLY** for external systems and **WRITE** to Linear (internal tracking).

## Arguments

- **$1**: Linear issue ID (e.g., WORK-123)
- **$2**: Option number to approve (1, 2, 3, or "refined")

## Workflow

### Step 1: Fetch Approved Design

Use **Linear MCP** to get issue details:

```javascript
linear_get_issue({ id: "$1" })
```

Extract:
- Approved design option (Option $2)
- Design wireframe and description
- Original requirements
- Any refinements made
- User feedback history

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Approving Design Option $2 for $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: [Title from Linear]
🎨 Approved Design: Option $2
🔗 URL: https://linear.app/workspace/issue/$1

**Selected Design**:
[Display the approved option's wireframe and description]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏳ Generating comprehensive UI specifications...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 2: Deep Dive into Design System

**Comprehensive codebase analysis** for specifications:

Use **Read** to extract full details:

```bash
# Tailwind configuration
tailwind.config.{js,ts}

# Theme configurations
**/theme/**/*
**/styles/**/*

# Component libraries
components.json (shadcn-ui)
components/ui/**/*.{tsx,ts}

# Global styles
globals.css
index.css
```

**Extract Complete Design Tokens**:
- **All colors** with hex values and Tailwind classes
- **Typography** (font families, sizes, weights, line heights)
- **Spacing scale** (complete px values for all Tailwind classes)
- **Border styles** (widths, colors, radius values)
- **Shadow definitions** (all shadow levels)
- **Breakpoint values** (exact px widths)
- **Animation/transition configs**
- **Z-index scale** (layering system)

**Component Library Audit**:
- List ALL available components with imports
- Document component props and variants
- Identify composition patterns
- Note any custom components to create

### Step 3: Research Latest Implementation Patterns

**Use Context7 MCP for developer-focused documentation**:

```javascript
// Get latest component implementation patterns
get-library-docs({
  context7CompatibleLibraryID: "/tailwindlabs/tailwindcss",
  topic: "component implementation patterns and best practices",
  tokens: 3000
})

get-library-docs({
  context7CompatibleLibraryID: "/shadcn-ui/ui",
  topic: "component composition and TypeScript patterns",
  tokens: 3000
})

// If React Native
get-library-docs({
  context7CompatibleLibraryID: "/nativewind/nativewind",
  topic: "React Native styling patterns and platform differences",
  tokens: 2000
})
```

**Research**:
- Latest TypeScript patterns for components
- Accessibility implementation (ARIA attributes)
- Responsive implementation strategies
- Dark mode implementation patterns
- Animation/transition best practices
- Performance optimization techniques

### Step 4: Invoke pm:ui-designer Agent for Specifications

**CRITICAL: Invoke the specialist agent to generate complete specs**:

```javascript
Task(pm:ui-designer): `
Generate comprehensive UI specifications for approved design (Option $2) for Linear issue $1.

**Approved Design**:
[Include the approved wireframe and full description]

**Complete Design System** (from codebase analysis):
- Colors: [All colors with hex and Tailwind classes]
- Typography: [All font configs with exact values]
- Spacing: [Complete spacing scale]
- Borders: [All border configs]
- Shadows: [All shadow definitions]
- Breakpoints: [Exact breakpoint values]
- Animations: [Transition/animation configs]

**Frontend Architecture Context** (from design-ui analysis):
- Component patterns used in project
- Existing reusable components (with file paths)
- State management approach
- Styling conventions
- Data flow patterns
- Performance patterns
- Technical constraints

**Available Components**:
[List all existing components with import paths]

**Latest Implementation Patterns** (from Context7):
[Summarize latest best practices from Context7]

**Original Requirements**:
[User requirements and goals from initial planning]

**CRITICAL REQUIREMENTS**:
- MAXIMIZE reuse of existing components
- FOLLOW project conventions from frontend analysis
- ENSURE technical feasibility based on architecture
- ALIGN with established patterns

**REQUIREMENTS**:
Generate a COMPREHENSIVE UI specification document that includes:

1. **Design System Reference**
   - All colors (name, hex, Tailwind class, usage)
   - All typography (size, weight, line height, usage)
   - Complete spacing scale
   - Border and shadow definitions
   - Breakpoint values

2. **Layout Structure**
   - Container specifications
   - Grid/Flex configurations
   - Responsive behavior at each breakpoint

3. **Component Breakdown**
   - Each component with:
     * Purpose and description
     * TypeScript interface for props
     * Complete JSX structure with Tailwind classes
     * All states (default, hover, active, disabled, focus)
     * All variants (primary, secondary, etc.)
     * Accessibility requirements (ARIA, semantic HTML)
     * Responsive behavior (mobile, tablet, desktop)

4. **Interactions & Animations**
   - Transition configurations
   - Hover effects with exact classes
   - Loading states
   - Micro-interactions

5. **Responsive Design**
   - Mobile-first implementation strategy
   - Breakpoint-specific styles
   - Examples with Tailwind responsive prefixes

6. **Dark Mode Support**
   - Color mappings for dark mode
   - Implementation strategy with dark: prefix
   - Examples

7. **Accessibility Checklist**
   - WCAG 2.1 AA requirements
   - Semantic HTML elements
   - ARIA attributes needed
   - Keyboard navigation requirements
   - Focus management

8. **Component Library Mapping**
   - Which existing components to reuse (with import paths)
   - Which new components to create (with file locations)
   - Component composition patterns

9. **Implementation Priority**
   - High/Medium/Low priority breakdown
   - Suggested implementation order

10. **Implementation Tips**
    - Step-by-step implementation guide
    - Common pitfalls to avoid
    - Performance considerations
    - Testing recommendations

**FORMAT**: Use the comprehensive markdown template with ALL sections filled in detail. Be extremely specific with Tailwind classes, TypeScript interfaces, and implementation examples.

**GOAL**: This specification should be so detailed that a developer can implement the UI accurately without needing to ask questions or make design decisions.
`
```

**Agent Output Expected**:
- 10+ page comprehensive specification document
- Complete design token reference
- Detailed component breakdown with code
- TypeScript interfaces for all components
- Accessibility guidelines
- Responsive implementation details
- Dark mode implementation
- Developer implementation guide

### Step 5: Create Linear Document for Specifications

Use **Linear MCP** to create a comprehensive document:

```javascript
// Create Linear Document
linear_create_document({
  title: "UI Specification: [Issue Title]",
  content: `
[Agent's comprehensive specification output]
  `,
  projectId: "[Project ID from issue]"
})

// Link document to issue
linear_update_issue({
  id: "$1",
  description: "[Existing description]\n\n---\n\n## ✅ Approved UI Design\n\n**Selected**: Option $2\n**Specifications**: [Link to Linear Document]\n\n[Approved wireframe]\n\n**Status**: Ready for implementation"
})
```

### Step 6: Update Issue Status and Labels

Use **Linear MCP** to mark as ready for development:

```javascript
linear_update_issue({
  id: "$1",
  state: "Todo", // or "Ready for Dev" if available
  labels: ["design-approved", "spec-complete", "ready-for-dev"]
})
```

### Step 7: Generate Implementation Tasks (Optional)

Use **AskUserQuestion** to offer task breakdown:

```javascript
{
  questions: [{
    question: "Would you like me to break this down into implementation tasks?",
    header: "Task Breakdown",
    multiSelect: false,
    options: [
      {
        label: "⭐ Yes, create tasks",
        description: "Create sub-tasks for each component/section"
      },
      {
        label: "No, I'll implement as one task",
        description: "Keep as single issue"
      },
      {
        label: "Let me review specs first",
        description: "I'll decide after reviewing the specifications"
      }
    ]
  }]
}
```

**If user wants task breakdown**:

Create sub-issues using **Linear MCP**:

```javascript
// Example sub-issues
linear_create_issue({
  title: "Implement [Component 1 Name]",
  description: "See UI Specification: [Link]\n\nComponent: [Component 1]\nPriority: High",
  parentId: "$1",
  labels: ["frontend", "ui-implementation"]
})

linear_create_issue({
  title: "Implement [Component 2 Name]",
  description: "See UI Specification: [Link]\n\nComponent: [Component 2]\nPriority: High",
  parentId: "$1",
  labels: ["frontend", "ui-implementation"]
})

// Continue for all major components
```

### Step 8: Display Final Summary

Show comprehensive output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ UI Design Approved & Specifications Generated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Issue: $1
🎨 Approved: Option $2
🔗 Linear: https://linear.app/workspace/issue/$1
📄 Specifications: [Linear Document URL]
🏷️  Status: Ready for Development

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Specification Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Design System**:
- Colors: [X] defined with Tailwind classes
- Typography: [Y] sizes documented
- Spacing: Complete 4px grid scale
- Components: [Z] to implement

**Components Breakdown**:
1. [Component 1] - [Complexity: Simple/Moderate/Complex]
2. [Component 2] - [Complexity]
3. [Component 3] - [Complexity]
[...]

**Accessibility**: WCAG 2.1 AA compliant
**Responsive**: Mobile-first, 3 breakpoints
**Dark Mode**: Full support with dark: variants
**Animations**: [X] micro-interactions defined

**Implementation Priority**:
- High: [X] components (core functionality)
- Medium: [Y] components (enhancements)
- Low: [Z] components (polish)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Developer Resources
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**What's Included**:
✅ Complete design token reference
✅ TypeScript interfaces for all components
✅ Tailwind class mappings for every element
✅ Accessibility implementation guide (ARIA, semantic HTML)
✅ Responsive behavior documentation (mobile/tablet/desktop)
✅ Dark mode implementation guide
✅ Animation and interaction specifications
✅ Component library mapping (reuse vs create new)
✅ Step-by-step implementation tips
✅ Performance and testing recommendations

**Documentation Location**:
📄 Linear Document: [URL]
📋 Issue: https://linear.app/workspace/issue/$1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Implementation Checklist
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For developers implementing this UI:

1. [ ] Read complete specification document
2. [ ] Review design system and available components
3. [ ] Set up component structure following specs
4. [ ] Implement base layout and structure
5. [ ] Add Tailwind styling per specifications
6. [ ] Implement interactive states (hover, focus, active)
7. [ ] Add responsive behavior for all breakpoints
8. [ ] Implement dark mode variants
9. [ ] Add accessibility features (ARIA, keyboard nav)
10. [ ] Test on mobile, tablet, and desktop
11. [ ] Test dark mode
12. [ ] Test keyboard navigation
13. [ ] Test with screen reader (if available)
14. [ ] Optimize performance (lazy loading, code splitting)
15. [ ] Review against original design wireframe

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Suggested Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use **AskUserQuestion** for next steps:

```javascript
{
  questions: [{
    question: "What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "⭐ Start Implementation",
        description: "Begin coding with agent coordination (/ccpm:implementation:start)"
      },
      {
        label: "Break into Sub-Tasks",
        description: "Create Linear sub-issues for each component"
      },
      {
        label: "Review Specifications",
        description: "View the Linear Document with full specs"
      },
      {
        label: "Assign to Developer",
        description: "Assign issue to a team member in Linear"
      },
      {
        label: "Continue Planning",
        description: "Return to planning workflow (/ccpm:planning:plan)"
      }
    ]
  }]
}
```

### Step 9: Execute Selected Next Action

**If "Start Implementation"**:
```bash
/ccpm:implementation:start $1
```

**If "Break into Sub-Tasks"**:
- Create Linear sub-issues for each major component
- Link all to parent issue
- Add priorities based on spec
- Display task breakdown

**If "Review Specifications"**:
- Display Linear Document URL
- Show table of contents from spec
- Suggest key sections to review

**If "Assign to Developer"**:
- Use Linear MCP to assign issue
- Add comment notifying assignee
- Link to specifications document

**If "Continue Planning"**:
```bash
/ccpm:planning:plan $1
```

### Step 10: Final Summary

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 UI Design Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your UI design has been approved and comprehensive specifications
have been generated. Developers now have everything they need to
implement this design accurately and consistently.

📄 **Specification Document**: [Linear Document URL]
📋 **Issue**: https://linear.app/workspace/issue/$1
🏷️  **Status**: Ready for Development

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Start Implementation:  /ccpm:implementation:start $1
View Status:           /ccpm:utils:status $1
Create Sub-Tasks:      /ccpm:spec:break-down $1
Review Spec:           [Linear Document URL]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Specification Quality Standards

The generated specifications MUST include:

### 1. Design System Reference (Complete)
- ✅ ALL colors with name, hex, Tailwind class, and usage context
- ✅ ALL typography styles with exact values
- ✅ Complete spacing scale (1-96 in Tailwind units)
- ✅ All border configurations
- ✅ All shadow definitions
- ✅ Exact breakpoint values

### 2. Component Specifications (Detailed)
For EACH component:
- ✅ Clear purpose statement
- ✅ TypeScript interface with all props
- ✅ Complete JSX structure with exact Tailwind classes
- ✅ All states (default, hover, active, disabled, focus) with classes
- ✅ All variants (primary, secondary, outline, etc.)
- ✅ Accessibility requirements (semantic HTML, ARIA attributes)
- ✅ Responsive behavior at each breakpoint
- ✅ Dark mode variant classes

### 3. Implementation Guidance (Actionable)
- ✅ Step-by-step implementation order
- ✅ Code examples for complex patterns
- ✅ Common pitfalls to avoid
- ✅ Performance optimization tips
- ✅ Testing recommendations

### 4. Accessibility (WCAG 2.1 AA)
- ✅ Color contrast requirements met
- ✅ Semantic HTML elements specified
- ✅ ARIA attributes documented
- ✅ Keyboard navigation flow defined
- ✅ Focus management strategy
- ✅ Screen reader considerations

### 5. Responsive Design (Mobile-First)
- ✅ Mobile layout (default)
- ✅ Tablet layout (sm: and md:)
- ✅ Desktop layout (lg: and xl:)
- ✅ Touch target sizes (44x44px minimum)
- ✅ Responsive typography scale

## Notes

### This Command Does

1. ✅ Fetches approved design from Linear
2. ✅ Deep analysis of design system (all tokens)
3. ✅ Research latest implementation patterns (Context7)
4. ✅ Invokes pm:ui-designer agent for comprehensive specs
5. ✅ Creates Linear Document with full specifications
6. ✅ Updates issue status to "Ready for Development"
7. ✅ Offers task breakdown into sub-issues
8. ✅ Provides developer handoff checklist
9. ✅ Suggests next actions (implementation, review, assignment)

### Usage Examples

**Basic usage**:
```bash
/ccpm:planning:design-approve WORK-123 1
```

**After refinement**:
```bash
# After running /ccpm:planning:design-refine WORK-123 2
/ccpm:planning:design-approve WORK-123 2
```

**Direct approval from design-ui**:
```bash
# After running /ccpm:planning:design-ui WORK-123
# User selected "Approve Option 2"
/ccpm:planning:design-approve WORK-123 2
```

### What Gets Generated

A comprehensive UI specification document (typically 3000-5000 words) that includes:

- **Complete Design Token Reference**: Every color, font, spacing, shadow
- **TypeScript Interfaces**: For every component with all props
- **Implementation Code**: JSX structures with exact Tailwind classes
- **State Management**: All states (hover, focus, active, disabled)
- **Responsive Patterns**: Mobile, tablet, desktop implementations
- **Accessibility Guide**: WCAG 2.1 AA compliance steps
- **Dark Mode Strategy**: Complete dark: variant mappings
- **Animation Specs**: Transitions and micro-interactions
- **Component Mapping**: What to reuse vs create new
- **Priority Breakdown**: High/Medium/Low implementation order
- **Implementation Tips**: Step-by-step guide for developers

### Benefits

- ✅ No ambiguity for developers
- ✅ Consistent implementation across team
- ✅ Accessibility built-in from start
- ✅ Responsive behavior clearly defined
- ✅ Dark mode fully specified
- ✅ Performance considerations included
- ✅ Reduces back-and-forth during development
- ✅ Enables parallel development of components
- ✅ Complete developer handoff documentation
- ✅ Linear Document for permanent reference

### Quality Assurance

The pm:ui-designer agent ensures:
- ✅ No missing information (if unclear, agent asks for clarification)
- ✅ All Tailwind classes are valid and current
- ✅ TypeScript interfaces are type-safe
- ✅ Accessibility standards are met
- ✅ Responsive breakpoints are logical
- ✅ Dark mode colors have sufficient contrast
- ✅ Component hierarchy makes sense
- ✅ Implementation is feasible with existing design system
