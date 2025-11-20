# UI Design Workflow with Frontend Collaboration

This document explains how CCPM's UI design planning works with automatic frontend agent collaboration to ensure technically feasible, architecture-aligned designs.

## 🎯 Core Concept

**UI designs must be informed by frontend architecture to be successful.**

When `pm:ui-designer` agent creates design options, it **automatically collaborates with frontend agents** to understand:
- Existing component patterns
- Reusable components available
- Project conventions and standards
- Technical constraints
- Performance patterns

This ensures designs are:
- ✅ **Technically feasible** - Can be implemented with current architecture
- ✅ **Component-efficient** - Reuse existing components > create new ones
- ✅ **Convention-aligned** - Follow established patterns
- ✅ **Implementation-ready** - No surprises during development

## 🔄 Automatic Agent Collaboration

### How It Works

The **smart-agent-selector hook** automatically detects UI design tasks and orchestrates frontend + design agent collaboration:

```
User: "Design a user profile screen"
     ↓
Smart Agent Selector detects: UI design task
     ↓
Auto-selects agents:
  1. frontend-mobile-development:frontend-developer (Step 1)
  2. pm:ui-designer (Step 2)
     ↓
Execution: SEQUENTIAL (frontend analysis → design generation)
```

### Keywords That Trigger Collaboration

- "design UI"
- "design screen"
- "design page"
- "design component visually"
- "wireframe"
- "mockup"
- "UI for [feature]"

## 📊 Complete Workflow

### Step 1: Frontend Architecture Analysis

**Frontend agent analyzes the codebase:**

```javascript
Task(frontend-mobile-development:frontend-developer): `
Analyze frontend architecture for designing [feature].

Provide:
1. Component patterns (atomic design, feature-based, etc.)
2. State management (TanStack Query, Context, Redux)
3. Styling approach (Tailwind, CSS-in-JS)
4. Existing components with file paths
5. Composition patterns
6. Data flow patterns
7. Routing/navigation conventions
8. Performance patterns
9. Accessibility patterns
10. Technical constraints
`
```

**Output:**
```markdown
## Frontend Architecture Context

**Component Patterns**: Feature-based organization, atomic design principles
**State Management**: TanStack Query for server state, Context for UI state
**Styling Approach**: Tailwind CSS with custom utilities
**Existing Components**:
- Button: components/ui/button.tsx (primary, secondary, outline variants)
- Card: components/ui/card.tsx (default, bordered, elevated variants)
- Input: components/ui/input.tsx (text, email, password types)
- Avatar: components/ui/avatar.tsx (sizes: sm, md, lg)

**Technical Constraints**:
- Bundle size target: <200KB per route
- Mobile-first responsive design required
- Dark mode support mandatory

**Conventions**:
- Component files use PascalCase.tsx
- Props interfaces named ComponentNameProps
- Variants handled via className prop
- Composition over prop explosion
```

### Step 2: UI Design Generation

**UI designer uses frontend context:**

```javascript
Task(pm:ui-designer): `
Design user profile screen using frontend architecture context.

Context:
- Frontend analysis: [from Step 1]
- Design system: [Tailwind config]
- User requirements: [from initial request]

Generate 2-3 options that:
- Reuse existing components (Button, Card, Avatar, Input)
- Follow component patterns (feature-based organization)
- Align with conventions (PascalCase, Props interfaces)
- Meet constraints (bundle size, mobile-first, dark mode)
`
```

**Output:**
```markdown
🎨 Design Option 1: Card-Based Profile

[ASCII Wireframe]

📝 Description:
Uses existing Card, Avatar, and Button components.
Organized in feature-based structure as: features/profile/ProfileCard.tsx

**Component Reuse**:
- Avatar (size: lg) - components/ui/avatar.tsx
- Card (variant: elevated) - components/ui/card.tsx
- Button (variant: primary, outline) - components/ui/button.tsx

**New Components**:
- ProfileStats.tsx (follows project conventions)
- ProfileHeader.tsx (composes Avatar + heading)

✅ Pros:
- 80% component reuse (only 2 new components)
- Follows established patterns
- Meets bundle size target (estimated 45KB)

❌ Cons:
- Less unique visual identity

🔧 Technical:
- Complexity: Simple
- Implementation time: 2-3 hours (mostly composition)
- Aligns with: Feature-based organization
- Mobile-first: Full support with Card responsive behavior
```

### Step 3: User Feedback & Refinement

User selects or refines design options. Designer maintains architecture alignment during refinement.

### Step 4: Comprehensive Specifications

**After approval, designer generates detailed specs:**

```javascript
Task(pm:ui-designer): `
Generate comprehensive UI specifications for approved design.

Include:
- Frontend architecture context (from Step 1)
- Component mapping (existing vs new)
- TypeScript interfaces following conventions
- Implementation order
- Performance considerations
`
```

**Output: Full UI Specification Document**

Includes:
- ✅ Component breakdown with import paths
- ✅ TypeScript interfaces (following naming conventions)
- ✅ Tailwind classes for every element
- ✅ Component composition examples
- ✅ State management integration points
- ✅ Routing/navigation implementation
- ✅ Performance optimization tips
- ✅ Testing approach

## 🛠️ Commands

### `/ccpm:planning:design-ui [issue-id]`

**Main UI design command** - Initiates full workflow:

1. Fetches Linear issue
2. Gathers user requirements
3. **Invokes frontend agent for architecture analysis** ← CRITICAL
4. Analyzes design system
5. Researches latest trends (Context7)
6. Invokes UI designer with frontend context
7. Presents 2-3 design options
8. Collects feedback

```bash
/ccpm:planning:design-ui WORK-123
```

### `/ccpm:planning:design-refine [issue-id] [option] [feedback]`

**Refine a design option** - Maintains architecture alignment:

```bash
/ccpm:planning:design-refine WORK-123 2 "Make it more minimalist"
```

Designer refines while ensuring:
- Still reuses existing components
- Follows project conventions
- Remains technically feasible

### `/ccpm:planning:design-approve [issue-id] [option]`

**Approve final design** - Generates comprehensive specs:

```bash
/ccpm:planning:design-approve WORK-123 2
```

Creates Linear Document with:
- Complete component breakdown
- Frontend architecture integration
- Implementation guidance
- Component reuse strategy

## 🎓 Agent Responsibilities

### `pm:ui-designer` Agent

**Core responsibilities:**

1. **Frontend Collaboration** (Step 1 - ALWAYS FIRST)
   - Invoke frontend agent to analyze architecture
   - Document component patterns, existing components, conventions
   - Understand technical constraints

2. **Design Generation** (Step 2)
   - Create 2-3 design options using frontend context
   - Maximize reuse of existing components
   - Follow project conventions
   - Ensure technical feasibility

3. **Specification Generation** (Step 3)
   - Detailed component breakdown
   - TypeScript interfaces (following conventions)
   - Component mapping (existing vs new)
   - Implementation guidance

**Always includes:**
- Component reuse strategy
- Architecture alignment notes
- Technical feasibility assessment

### Frontend Agents

**`frontend-mobile-development:frontend-developer`** or **`frontend-mobile-development:mobile-developer`**

**Provides to UI designer:**

1. **Component Architecture**
   - What patterns are used (atomic, feature-based, etc.)
   - File organization conventions
   - Naming conventions

2. **Existing Components**
   - List with file paths
   - Available variants
   - Composition patterns

3. **Technical Context**
   - State management approach
   - Styling conventions
   - Data flow patterns
   - Performance patterns
   - Constraints (bundle size, platform limitations)

## 🚀 Benefits

### For Designers

- ✅ **Context-aware designs** - Know what components exist before designing
- ✅ **Realistic options** - All options are technically feasible
- ✅ **Less rework** - Designs align with architecture from the start
- ✅ **Better estimates** - Know implementation complexity upfront

### For Developers

- ✅ **Clear specifications** - Know exactly what to implement
- ✅ **Component reuse** - Maximize use of existing components
- ✅ **Convention-aligned** - Designs follow established patterns
- ✅ **Reduced questions** - All technical details documented
- ✅ **Faster implementation** - Less back-and-forth, clearer path

### For Project

- ✅ **Faster delivery** - Less rework, smoother implementation
- ✅ **Consistent UX** - Reuse of components = consistent experience
- ✅ **Maintainable code** - Follows established patterns
- ✅ **Lower bundle size** - Component reuse > duplication

## 📋 Example: Profile Screen Design

### Initial Request

```
User: "Design a user profile screen with avatar, bio, stats, and recent posts"
```

### Step 1: Frontend Analysis

```markdown
Frontend Agent Output:

**Existing Components**:
- Avatar: components/ui/avatar.tsx (sm, md, lg, xl sizes)
- Card: components/ui/card.tsx (default, bordered, elevated)
- Button: components/ui/button.tsx (primary, secondary, outline, ghost)
- Tabs: components/ui/tabs.tsx (default, pills, underlined)

**Component Patterns**:
- Feature-based: features/[feature]/components/
- Composition: Compound components preferred
- Variants: Via className prop, not separate components

**State Management**:
- TanStack Query for data fetching
- Context for UI state (theme, modals)

**Conventions**:
- Props: ComponentNameProps interface
- Files: PascalCase.tsx
- Exports: Named exports for components
```

### Step 2: Design Options (with frontend context)

```markdown
🎨 Design Option 1: Tabbed Layout

[Wireframe]

**Component Reuse** (90%):
- Avatar (xl) - existing
- Card (elevated) - existing
- Button (primary, outline) - existing
- Tabs (underlined) - existing

**New Components** (10%):
- ProfileHeader.tsx - Composes Avatar + heading
- StatsGrid.tsx - Simple grid of stat items

**Architecture Alignment**:
- Location: features/profile/components/
- Composition: ProfileHeader composes Avatar
- State: TanStack Query for profile data
- Convention: ProfileHeaderProps interface

**Implementation Estimate**: 3-4 hours
- 2 hours: New components (following patterns)
- 1 hour: Composition and integration
- 1 hour: Testing and refinement
```

### Step 3: Approved Specifications

```markdown
## Component: ProfileHeader

**File**: features/profile/components/ProfileHeader.tsx

**Props Interface**:
```typescript
interface ProfileHeaderProps {
  user: {
    name: string
    username: string
    avatar: string
    bio?: string
  }
  onEdit?: () => void
}
```

**Component Structure**:
```tsx
import { Avatar } from '@/components/ui/avatar'
import { Button } from '@/components/ui/button'

export function ProfileHeader({ user, onEdit }: ProfileHeaderProps) {
  return (
    <div className="flex items-center gap-4 p-6">
      <Avatar
        src={user.avatar}
        alt={user.name}
        size="xl"
        className="ring-2 ring-primary"
      />
      <div className="flex-1">
        <h1 className="text-2xl font-bold">{user.name}</h1>
        <p className="text-muted-foreground">@{user.username}</p>
        {user.bio && <p className="mt-2 text-sm">{user.bio}</p>}
      </div>
      {onEdit && (
        <Button variant="outline" onClick={onEdit}>
          Edit Profile
        </Button>
      )}
    </div>
  )
}
```

**Testing**:
- Test file: ProfileHeader.test.tsx
- Test avatar rendering
- Test edit button callback
- Test optional bio
```

## 🔧 Configuration

### Design System Support

CCPM supports these design systems out of the box:

1. **Tailwind CSS** - Most popular utility-first CSS
2. **NativeWind** - Tailwind for React Native
3. **shadcn-ui** - Component collection for Tailwind
4. **reactreusables** - Community components

### Agent Detection

The `discover-agents.sh` script automatically finds:
- `pm:ui-designer` (project agent)
- `frontend-mobile-development:frontend-developer` (plugin)
- `frontend-mobile-development:mobile-developer` (plugin)

### Smart Agent Selector

Automatically pairs frontend + design agents for UI tasks based on keywords in `hooks/smart-agent-selector.prompt`.

## 🎯 Best Practices

### For UI Design Tasks

1. **Always start with frontend analysis**
   - Run frontend agent first
   - Document existing components
   - Understand conventions

2. **Maximize component reuse**
   - Prefer existing components > new ones
   - Compose existing components when possible
   - Only create new components when necessary

3. **Follow project conventions**
   - Naming conventions from frontend analysis
   - File organization patterns
   - Props interface patterns

4. **Consider technical constraints**
   - Bundle size targets
   - Performance requirements
   - Platform limitations

5. **Document architecture alignment**
   - How design fits current patterns
   - Which components are reused
   - Why new components are needed

### For Developers Implementing Designs

1. **Review frontend context section**
   - Understand which components to reuse
   - Follow documented conventions
   - Check technical constraints

2. **Start with component mapping**
   - Import existing components first
   - Compose before creating
   - Follow file organization

3. **Validate against specifications**
   - Match Tailwind classes exactly
   - Implement all states (hover, focus, etc.)
   - Follow TypeScript interfaces

4. **Test architecture alignment**
   - Components in correct locations
   - Props follow conventions
   - State management integrated properly

## 🔍 Troubleshooting

### Design doesn't align with frontend

**Symptom**: Design proposes patterns that don't match codebase

**Solution**:
- Ensure frontend agent ran FIRST
- Verify frontend analysis was passed to designer
- Check that designer followed architecture context

### Too many new components proposed

**Symptom**: Design creates many new components instead of reusing

**Solution**:
- Frontend agent may not have found existing components
- Designer may not have emphasized reuse
- Review component library completeness

### Implementation differs from specs

**Symptom**: Developer asks questions not covered in specs

**Solution**:
- Specifications may be missing frontend context
- Ensure design-approve ran with full context
- Designer should include implementation examples

## 📚 Related Documentation

- [CLAUDE.md](./CLAUDE.md) - Full CCPM documentation
- [Commands README](./commands/README.md) - All command reference
- [Hooks Implementation](./HOOKS_IMPLEMENTATION_SUMMARY.md) - How hooks work
- [Smart Agent Selection](./hooks/SMART_AGENT_SELECTION.md) - Agent selection logic

## 🎉 Summary

**CCPM's UI design workflow is unique because:**

1. **Automatic frontend collaboration** - No manual coordination needed
2. **Architecture-first design** - Designs fit existing patterns
3. **Component reuse maximized** - Saves time and maintains consistency
4. **Comprehensive specifications** - Developers have everything needed
5. **Seamless integration** - Works with existing CCPM workflows

**Result**: Faster, more consistent UI implementation with less back-and-forth.
