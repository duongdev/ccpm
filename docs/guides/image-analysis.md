# Image Analysis Feature Guide

Learn how CCPM automatically analyzes images in Linear issues to enhance planning and enable pixel-perfect UI implementation.

## Overview

CCPM automatically detects and analyzes images attached to Linear issues, providing:
- **Visual context** in planning workflows
- **Direct mockup loading** for pixel-perfect UI implementation
- **~95-100% design fidelity** vs. ~70-80% from text descriptions

## Supported Image Types

1. **UI Mockups** - Design specifications for interfaces
2. **Architecture Diagrams** - System structure and relationships
3. **Screenshots** - Current state documentation
4. **Wireframes** - Low-fidelity design concepts

## How It Works

### Planning Phase

When you run `/ccpm:planning:plan`, CCPM automatically:

1. Detects images in Linear attachments and markdown
2. Analyzes each image with context-aware prompts
3. Formats results into markdown
4. Inserts into Linear description
5. Preserves image URLs for implementation phase

**Example**:
```bash
/ccpm:planning:plan WORK-123 JIRA-456

# Result: Linear description includes:
## 🖼️ Visual Context Analysis

**Image: login-mockup.png**
- Layout: Centered login form with email/password fields
- Components: Input fields, submit button, "Forgot password" link
- Colors: Primary blue (#2563eb), neutral grays
- Implementation Notes: Use Card, Input, Button components

**Mockup URL**: https://linear.app/attachments/login-mockup.png
```

### Implementation Phase

When you run `/ccpm:implementation:start`, CCPM automatically:

1. Detects UI/design subtasks
2. Extracts relevant mockups
3. Passes images to frontend/mobile agents via WebFetch
4. Instructs for pixel-perfect implementation

**Example**:
```bash
/ccpm:implementation:start WORK-123

# Agent receives:
Design Mockup: https://linear.app/attachments/login-mockup.png
[WebFetch loads mockup]

Match EXACT: layout, spacing, colors, typography from mockup above.
```

## Configuration

Configure image analysis in `~/.claude/ccpm-config.yaml`:

```yaml
projects:
  - id: my-project
    image_analysis:
      enabled: true              # Enable/disable feature
      max_images: 5              # Max images per issue
      timeout_ms: 10000          # Timeout per image (10s)
      implementation_mode: direct_visual  # or "text_only"
      formats:
        - jpg
        - png
        - gif
        - webp
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `enabled` | `true` | Enable/disable image analysis |
| `max_images` | `5` | Maximum images to analyze per issue |
| `timeout_ms` | `10000` | Timeout per image (milliseconds) |
| `implementation_mode` | `direct_visual` | Pass images to agents (`direct_visual`) or text only (`text_only`) |
| `formats` | `["jpg", "jpeg", "png", "gif", "webp"]` | Supported image formats |

## Best Practices

### Attaching Images to Linear Issues

1. **Name images descriptively**: `login-mockup.png` not `image1.png`
2. **Use standard formats**: PNG, JPG, GIF, WEBP
3. **Keep images focused**: One concept per image
4. **Limit quantity**: 3-5 images per issue (performance)

### UI Mockups

- Include exact colors and typography
- Show spacing and layout clearly
- Indicate responsive breakpoints
- Label components if complex

### Architecture Diagrams

- Show components and relationships
- Indicate data flow direction
- Label technologies/frameworks
- Include scaling considerations

## Examples

### Example 1: UI Feature with Mockup

**Linear Issue**: "Add user profile screen"
**Attached**: `profile-mockup.png`

**Planning Output**:
```markdown
## 🖼️ Visual Context Analysis

**Image: profile-mockup.png**
- Layout: Centered card with avatar, name, bio
- Components: Avatar (circular, 120px), Text fields, Edit button
- Colors: Primary green (#10b981), white background
- Typography: Headings 24px bold, body 16px regular
- Accessibility: High contrast, proper heading hierarchy
- Implementation Notes: Use Card, Avatar, Button, Input components

**Mockup URL**: https://linear.app/...
```

**Implementation**:
- Frontend agent receives mockup directly
- Implements with ~95-100% fidelity
- Extracts exact colors (#10b981)
- Matches spacing and typography

### Example 2: Architecture Diagram

**Linear Issue**: "Implement authentication system"
**Attached**: `auth-architecture.png`

**Planning Output**:
```markdown
## 🖼️ Visual Context Analysis

**Image: auth-architecture.png**
- Components: Client → API Gateway → Auth Service → Database
- Data Flow: JWT tokens, refresh tokens, session management
- Technologies: Express.js, PostgreSQL, Redis cache
- Patterns: Token rotation, secure cookie storage
- Scaling: Stateless design, horizontal scaling ready
- Implementation: Follow microservices pattern

**Diagram URL**: https://linear.app/...
```

## Troubleshooting

### Images Not Being Detected

**Problem**: Planning command doesn't show image analysis

**Solutions**:
1. Check configuration: `image_analysis.enabled: true`
2. Verify image format is supported (PNG, JPG, GIF, WEBP)
3. Ensure images are attached to Linear issue or inline markdown
4. Check image URLs are accessible (not private/broken)

### Slow Image Analysis

**Problem**: Planning takes too long

**Solutions**:
1. Reduce `max_images` to 3 or less
2. Decrease `timeout_ms` to 5000 (5 seconds)
3. Attach smaller image files (<2MB)
4. Use PNG/JPG instead of large GIF files

### Image Analysis Errors

**Problem**: Warnings like "⚠️ Image not accessible"

**Solutions**:
- Check image URL is publicly accessible
- Verify Linear attachment permissions
- Try re-uploading the image
- Check network connectivity

**Note**: Failed images don't block workflows - they show warnings and continue.

## Performance Impact

- **Per image**: ~2-5 seconds for fetch and analysis
- **Default limit**: 5 images = ~10-25 seconds added to planning
- **Implementation phase**: ~2-3 seconds per mockup loaded

**Optimization Tips**:
- Attach only necessary images
- Use smaller file sizes
- Consider `max_images: 3` for faster planning

## Benefits

### Planning Phase
- ✅ Automatic visual context extraction
- ✅ No manual image description needed
- ✅ Improved planning accuracy
- ✅ Better understanding of requirements

### Implementation Phase
- ✅ Pixel-perfect UI implementation
- ✅ ~95-100% design fidelity
- ✅ Faster implementation (no interpretation)
- ✅ Reduced back-and-forth

## Related Commands

- `/ccpm:planning:plan` - Main planning with image analysis
- `/ccpm:planning:create` - Create + plan with images
- `/ccpm:utils:context` - View images in task context
- `/ccpm:planning:design-ui` - Analyze design references
- `/ccpm:implementation:start` - Load mockups for implementation

## Further Reading

- [Image Analysis Utility Reference](../reference/image-analysis-utility.md)
- [Configuration Guide](./project-setup.md)
- [Planning Workflow](./planning-workflow.md)
