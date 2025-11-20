# Figma MCP Integration Guide

Complete guide to CCPM's Figma MCP integration for automated design system extraction.

## Overview

CCPM integrates with Figma via MCP (Model Context Protocol) servers to automatically:
- Detect Figma links in Linear issues
- Extract design data (colors, fonts, spacing, components)
- Generate Tailwind class mappings
- Cache design systems for fast access
- Provide visual context during implementation

## Architecture

```
Linear Issue (with Figma links)
  ↓
[Figma Link Detection] (figma-utils.sh)
  ↓
[MCP Server Selection] (figma-server-manager.sh)
  ↓
[Data Extraction via MCP] (figma-data-extractor.sh)
  ↓
[Design Analysis] (figma-design-analyzer.sh)
  ↓
[Cache in Linear Comments] (figma-cache-manager.sh)
  ↓
Linear Description + Implementation Context
```

## Setup

### 1. Install Figma MCP Server

**Recommended**: GLips Community Server (no Dev Mode required)

```bash
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP
npm install && npm run build
```

Configure in `~/.config/agent-mcp-gateway/.mcp.json`:

```json
{
  "mcpServers": {
    "figma-glips": {
      "command": "node",
      "args": ["./dist/index.js"],
      "env": {
        "FIGMA_PERSONAL_ACCESS_TOKEN": "${FIGMA_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
}
```

### 2. Get Figma Personal Access Token

1. Go to Figma → Settings → Personal Access Tokens
2. Create new token with read scope
3. Add to environment: `export FIGMA_PERSONAL_ACCESS_TOKEN="your-token"`

### 3. Configure CCPM Project

Add Figma configuration to `~/.claude/ccpm-config.yaml`:

```yaml
projects:
  - id: my-project
    figma:
      enabled: true
      mcp_server: "figma-glips"  # Or "auto" for auto-detection
      cache:
        enabled: true
        ttl: 3600  # 1 hour
```

## Usage

### During Planning

When running `/ccpm:planning:plan`, Figma links are automatically:
1. Detected from Linear description and comments
2. Extracted via configured MCP server
3. Analyzed for design tokens and components
4. Cached in Linear comments (1 hour TTL)
5. Inserted into Linear description as "🎨 Design System Analysis"

### During UI Design

When running `/ccpm:planning:design-ui`, Figma design system:
- Informs color palette choices
- Guides typography decisions
- Ensures spacing consistency
- Provides component patterns

### During Implementation

When running `/ccpm:implementation:start`, agents receive:
- Figma design tokens (colors, fonts, spacing)
- Tailwind class mappings (e.g., `#3b82f6` → `blue-500`)
- Component library structure
- Layout patterns (flex, grid, auto-layout)

Frontend/mobile agents use this data for pixel-perfect implementation.

### Manual Cache Refresh

Force refresh when designs change:

```bash
/ccpm:utils:figma-refresh WORK-123
```

## Features

### Phase 1: Foundation ✅

- Figma link detection from Linear issues
- URL parsing (file ID, node ID, file name)
- MCP server management and auto-selection
- Project configuration

### Phase 2: Data Extraction ✅

- MCP gateway integration
- Multi-server support (Official, GLips, TimHolden)
- Design data extraction
- Linear comment caching
- Rate limit tracking

### Phase 3: Design Analysis ✅

- Color palette extraction → Tailwind mappings
- Typography analysis → Font family mappings
- Spacing detection → Tailwind scale
- Component analysis (structure, hierarchy)
- Layout pattern detection (flex, grid)
- Text style extraction

### Phase 4: Workflow Integration ✅

- `/ccpm:planning:plan` - Auto-detect and extract during planning
- `/ccpm:planning:design-ui` - Inform UI design with Figma data
- `/ccpm:implementation:start` - Provide design context to agents
- `/ccpm:utils:context` - Display Figma designs in task context

### Phase 5: Advanced Features ✅

- `/ccpm:utils:figma-refresh` - Manual cache refresh
- Multi-frame support (planned)
- Design change detection (planned)
- Code generation from components (planned)

## Supported MCP Servers

| Server | Dev Mode Required | Features | Rate Limit |
|--------|------------------|----------|------------|
| **Official Figma** | Yes ($15/seat/month) | Full API, variables, components | 6/month (free), unlimited (paid) |
| **GLips Community** | No (recommended) | AI-optimized, good features | 60 calls/hour |
| **TimHolden** | No | Read-only, simple | 60 calls/hour |

## Rate Limits

- **Official (free)**: 6 calls/month → Use sparingly
- **Official (paid)**: Unlimited → Best for teams with Dev Mode
- **Community servers**: 60 calls/hour → Sufficient for most workflows

CCPM caches design data for 1 hour to avoid hitting rate limits.

## Troubleshooting

### "No Figma MCP server configured"

**Solution**: Add Figma MCP server to agent-mcp-gateway config and specify in `ccpm-config.yaml`

### "Rate limit exceeded"

**Solution**: 
1. Use cached data (CCPM automatically falls back to stale cache)
2. Wait for rate limit reset (hourly or monthly depending on server)
3. Consider upgrading to paid Figma plan

### "Failed to extract design data"

**Solution**:
1. Check Figma file permissions (ensure token has read access)
2. Verify MCP server is running (check agent-mcp-gateway logs)
3. Test MCP connection: `./scripts/figma-server-manager.sh test <server-name>`

### "Design system not showing in Linear"

**Solution**:
1. Run `/ccpm:planning:plan` to trigger extraction
2. Check Linear description for "🎨 Design System Analysis" section
3. Check Linear comments for cached Figma data
4. Force refresh: `/ccpm:utils:figma-refresh <issue-id>`

## Best Practices

1. **Link Figma files in Linear descriptions** - Automatic detection
2. **Use canonical URLs** - Avoid query parameters
3. **Refresh cache after design changes** - Keep implementation aligned
4. **Monitor rate limits** - Check `/scripts/figma-rate-limiter.sh report`
5. **Configure per-project servers** - Different projects, different servers

## Performance

| Operation | Time (cached) | Time (first run) |
|-----------|--------------|------------------|
| Link detection | <100ms | <100ms |
| MCP server selection | <50ms | <50ms |
| Data extraction | 1-2s | 10-20s |
| Design analysis | <500ms | <500ms |
| Total (single file) | ~2-3s | ~11-21s |

With caching, subsequent planning runs are ~95% faster.

## Security

- **Tokens**: Store in environment variables, not config files
- **Permissions**: Use read-only Figma tokens
- **Caching**: Linear comments are team-accessible (ensure team trust)
- **MCP servers**: Community servers process data externally (use official for sensitive designs)

## Roadmap

- [x] Phase 1: Foundation (link detection, MCP setup)
- [x] Phase 2: Data extraction (MCP integration, caching)
- [x] Phase 3: Design analysis (tokens, components, mappings)
- [x] Phase 4: Workflow integration (planning, implementation, context)
- [x] Phase 5: Advanced features (cache refresh, multi-frame)
- [ ] Future: Change detection with diffs
- [ ] Future: Code generation from components
- [ ] Future: Accessibility analysis (WCAG compliance)

## Related Documentation

- [Image Analysis](./image-analysis.md) - Static image analysis
- [CCPM Configuration](../reference/ccpm-config.md) - Project configuration
- [MCP Server Management](../reference/mcp-servers.md) - MCP setup
- [Linear Integration](../reference/linear-integration.md) - Linear MCP tools
