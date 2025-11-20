# Shared: Figma Link Detection and Context Extraction

This shared module detects and processes Figma links from Linear issues, external PM systems, and related documentation.

## When to Use

Include this step in any command that needs to extract Figma design specifications:
- `/ccpm:planning:plan` - Extract Figma links during planning phase
- `/ccpm:planning:design-ui` - Replace ASCII wireframes with Figma designs
- `/ccpm:implementation:start` - Load Figma context for implementation
- `/ccpm:utils:context` - Include Figma designs in task context

## Workflow

### 1. Detect Figma Links

Use `scripts/figma-utils.sh` to extract Figma URLs from text sources:

```bash
# From Linear issue description/comments
FIGMA_LINKS=$(./scripts/figma-utils.sh extract-markdown "$LINEAR_DESCRIPTION")

# From plain text (Jira, Confluence, Slack)
FIGMA_LINKS=$(./scripts/figma-utils.sh detect "$EXTERNAL_PM_CONTENT")
```

**Sources to search:**
- Linear issue description and comments
- Jira ticket description, comments, and attachments
- Confluence pages linked to the task
- Slack thread discussions
- PRD and design documents

### 2. Select Appropriate MCP Server

Determine which Figma MCP server to use for this project:

```bash
# Auto-select based on project configuration
FIGMA_SERVER=$(./scripts/figma-server-manager.sh select "$PROJECT_ID")

# Or use project-specific server
FIGMA_SERVER=$(./scripts/figma-server-manager.sh detect "$PROJECT_ID" | jq -r '.server')
```

**Available servers:**
- `figma-repeat` - For "repeat" project
- `figma-trainer-guru` - For "trainer-guru" project
- Auto-detect - Falls back to first available server

### 3. Extract Design Data

For each detected Figma link, extract design specifications via MCP:

```javascript
// Parse the Figma URL
const parsed = parseFigmaUrl(figmaUrl)
// {url, type, file_id, file_name, node_id, is_valid}

// Fetch design data via MCP (use appropriate server)
// This requires implementing MCP call - placeholder for now
const designData = {
  file_id: parsed.file_id,
  file_name: parsed.file_name,
  node_id: parsed.node_id || null,
  url: parsed.url,
  canonical_url: getCanonicalUrl(parsed.url),
  server: figmaServer
}
```

### 4. Cache in Linear Comments

Store extracted Figma context in Linear issue comments for future reference:

```markdown
## 🎨 Figma Design Context

**Detected**: {count} Figma link(s)

### Design: {file_name}
- **URL**: {canonical_url}
- **Node**: {node_id || "Full file"}
- **MCP Server**: {server}
- **Cached**: {timestamp}

---
*Figma context extracted automatically by CCPM (PSN-25)*
*Refresh with: `/ccpm:utils:figma-refresh {linear-issue-id}`*
```

### 5. Return Structured Data

Provide formatted output for use in planning/implementation:

```json
{
  "figma_links": [
    {
      "url": "https://www.figma.com/file/ABC123/Project",
      "canonical_url": "https://www.figma.com/file/ABC123",
      "file_id": "ABC123",
      "file_name": "Project",
      "node_id": null,
      "server": "figma-repeat"
    }
  ],
  "count": 1,
  "cached": true,
  "cache_timestamp": "2025-11-20T16:00:00Z"
}
```

## Helper Functions

### detectFigmaLinks(text)
```bash
./scripts/figma-utils.sh detect "$text"
# Returns: JSON array of URLs
```

### parseFigmaUrl(url)
```bash
./scripts/figma-utils.sh parse "$url"
# Returns: JSON object with file_id, node_id, type, etc.
```

### selectFigmaServer(project_id)
```bash
./scripts/figma-server-manager.sh select "$project_id"
# Returns: Server name (e.g., "figma-repeat")
```

### getCanonicalUrl(url)
```bash
./scripts/figma-utils.sh canonical "$url"
# Returns: Canonical URL without query params
```

## Error Handling

**Graceful degradation:**
- If no Figma links found → Continue without Figma context
- If MCP server not configured → Log warning, continue
- If MCP fetch fails → Use cached data from Linear comments
- If cache expired → Try refresh, fallback to stale cache

**Never fail the entire workflow due to Figma issues.**

## Performance Considerations

- Link detection: <100ms (regex-based)
- Server selection: <50ms (config lookup)
- MCP fetch: 1-3s per file (network + processing)
- Caching: Reduces repeated fetches to <100ms

**Optimization:**
- Cache design data in Linear comments (1 hour TTL)
- Only fetch if cache miss or expired
- Deduplicate URLs before fetching
- Limit to first 5 Figma links to avoid rate limits

## Integration Example

```bash
# Step 0.6: Detect Figma Links (in planning:plan.md)

# 1. Extract Linear description/comments
LINEAR_DESC=$(linear_get_issue "$1" | jq -r '.description')

# 2. Detect Figma links
FIGMA_LINKS=$(./scripts/figma-utils.sh extract-markdown "$LINEAR_DESC")
FIGMA_COUNT=$(echo "$FIGMA_LINKS" | jq 'length')

if [ "$FIGMA_COUNT" -gt 0 ]; then
  echo "✅ Detected $FIGMA_COUNT Figma link(s)"
  
  # 3. Select MCP server
  FIGMA_SERVER=$(./scripts/figma-server-manager.sh select "$PROJECT_ID")
  
  # 4. Format for Linear comment
  # (MCP fetch implementation pending - Phase 2)
  
  # 5. Add to planning context
  echo "$FIGMA_LINKS" > /tmp/figma-context.json
else
  echo "ℹ️  No Figma links detected"
fi
```

## Phase 1 Status ✅ COMPLETE

**Completed:**
- ✅ Link detection utilities (`scripts/figma-utils.sh`)
- ✅ MCP server manager (`scripts/figma-server-manager.sh`)
- ✅ Configuration schema
- ✅ Integration in planning workflow (detection only)

## Phase 2 Status ✅ COMPLETE

**Completed:**
- ✅ MCP data extraction implementation (`scripts/figma-data-extractor.sh`)
- ✅ Design analysis and token extraction (colors, fonts, spacing, frames)
- ✅ Linear comment caching (`scripts/figma-cache-manager.sh`)
- ✅ Rate limit tracking (`scripts/figma-rate-limiter.sh`)
- ✅ Enhanced planning workflow integration (full extraction)

**Phase 2 Capabilities:**

1. **Data Extraction** (`figma-data-extractor.sh`)
   - MCP gateway integration for all three server types
   - Retry logic with exponential backoff
   - Response normalization across different servers
   - Comprehensive design analysis

2. **Caching** (`figma-cache-manager.sh`)
   - Linear comment-based cache storage
   - Configurable TTL (default: 1 hour)
   - Cache validation and expiry checking
   - Stale cache fallback for rate-limited scenarios

3. **Rate Limiting** (`figma-rate-limiter.sh`)
   - Per-server rate limit tracking
   - Official server: 6 calls/month (free tier)
   - Community servers: 60 calls/hour
   - Real-time status reporting

4. **Design Analysis**
   - Frame metadata extraction
   - Text content analysis
   - Color palette extraction (RGB, hex)
   - Font family and style detection
   - Spacing pattern identification
   - Component hierarchy mapping

**Usage:**

```bash
# Extract design data
./scripts/figma-data-extractor.sh extract "file_id" "server_name" ["node_id"]

# Analyze extracted data
./scripts/figma-data-extractor.sh analyze "$raw_data"

# Cache in Linear
./scripts/figma-cache-manager.sh store "issue_id" "file_id" "name" "url" "server" "$data"

# Check rate limit
./scripts/figma-rate-limiter.sh status "server_name"

# View all rate limits
./scripts/figma-rate-limiter.sh report
```

**Integration with Planning:**

Phase 2 extraction is automatically triggered during `/ccpm:planning:plan` when:
1. Figma links are detected
2. MCP server is configured
3. Rate limit allows extraction

If rate limit is reached, cached data is used (even if stale) to avoid blocking the workflow.

**Pending (Phase 3 - Future):**
- ⏳ Design token mapping to Tailwind classes
- ⏳ Component-to-code generation
- ⏳ Multi-frame comparison and variant detection
- ⏳ Change detection and design drift alerts
- ⏳ Accessibility analysis (color contrast, ARIA labels)

Phase 2 provides **full design extraction and caching** - Phase 3 will add advanced analysis and code generation.
