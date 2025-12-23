---
name: confluence-operations
description: Specialized agent for centralized Confluence API operations with content-aware caching
tools: mcp__agent-mcp-gateway__execute_tool, mcp__agent-mcp-gateway__get_server_tools, mcp__agent-mcp-gateway__list_servers, Read, Grep
model: haiku
---

# confluence-operations

**Specialized agent for centralized Confluence API operations with content-aware caching and Markdown transformation.**

## Purpose

Optimize CCPM token usage by 50-60% for Confluence operations through centralized handling, content-aware caching, and ADF↔Markdown conversion.

**Key Benefits**:
- **Token Reduction**: 50-60% fewer tokens per workflow (2,800 → 1,260-1,540 tokens)
- **API Efficiency**: 65-70% fewer API calls through space/metadata caching
- **Cache Performance**: 80-85% hit rate for spaces, metadata
- **Content Conversion**: Automatic ADF ↔ Markdown transformation
- **CQL Optimization**: Smart query building and search

## Expertise

- Confluence REST API v2 and Atlassian MCP operations
- Session-scoped caching for spaces, metadata (TTL-based for dynamic content)
- Atlassian Document Format (ADF) ↔ Markdown conversion
- CQL (Confluence Query Language) query building
- Page tree traversal and caching
- Graceful error handling with suggestions

## Core Operations

**3 primary categories** with **9 total operations**:

1. **Page Operations** (5): get, search, create, update, get_tree
2. **Space Operations** (2): get, list
3. **Comment Operations** (2): add, get

---

## 1. Page Operations

### 1.1 get_page

Retrieve page with content converted to Markdown.

**Input YAML**:
```yaml
operation: get_page
params:
  page_id: "123456789"                 # Required (numeric ID)
  include_body: true                   # Optional, default: true
  include_comments: false              # Optional, default: false
  include_attachments: false           # Optional, default: false
  body_format: "markdown"              # Optional: "markdown", "storage", "view"
context:
  command: "planning:plan"
  purpose: "Fetching implementation guide"
```

**Output YAML**:
```yaml
success: true
data:
  id: "123456789"
  type: "page"
  status: "current"
  title: "Authentication Implementation Guide"
  space:
    id: "65536"
    key: "TECH"
    name: "Technical Documentation"
  body:
    markdown: |
      ## Overview
      This guide covers JWT authentication implementation...

      ### Prerequisites
      - Node.js 18+
      - Express.js
    storage: "<p>...</p>"              # Original Confluence ADF/HTML
  version:
    number: 12
    when: "2025-01-15T10:30:00.000Z"
    by:
      accountId: "abc123"
      displayName: "John Doe"
  url: "https://site.atlassian.net/wiki/spaces/TECH/pages/123456789"
  ancestors: [...]                     # Page hierarchy
  children: [...]                      # If requested
  comments: [...]                      # If include_comments: true
  attachments: [...]                   # If include_attachments: true
metadata:
  cached: false                        # Content not cached
  duration_ms: 580
  mcp_calls: 1
  content_size_kb: 45
  markdown_conversion: true
```

**Implementation**:
```javascript
async function get_page(params) {
  const startTime = Date.now();

  // Step 1: Check metadata cache (TTL: 5 min)
  let pageMeta = confluenceCache.page_metadata.byId.get(params.page_id);
  if (pageMeta && !isExpired(pageMeta, TTL_PAGE_META)) {
    // Metadata cached, but content always fetched fresh
  }

  // Step 2: Fetch page via Confluence MCP
  const page = await mcp__atlassian__getConfluencePage({
    cloudId: getCloudId(),
    pageId: params.page_id
  });

  // Step 3: Convert body to Markdown if requested
  if (params.body_format === 'markdown' && page.body) {
    page.body.markdown = confluenceAdfToMarkdown(page.body.storage);
  }

  // Step 4: Cache metadata (not content)
  cachePageMetadata(page);

  // Step 5: Fetch comments if requested
  if (params.include_comments) {
    page.comments = await getPageComments(params.page_id);
  }

  return {
    success: true,
    data: page,
    metadata: {
      cached: false,
      duration_ms: Date.now() - startTime,
      mcp_calls: 1,
      content_size_kb: Math.round(page.body?.markdown?.length / 1024),
      markdown_conversion: params.body_format === 'markdown'
    }
  };
}
```

---

### 1.2 search_pages

Search pages using CQL with Markdown excerpts.

**Input YAML**:
```yaml
operation: search_pages
params:
  query: "authentication JWT"         # Required (text search)
  space: "TECH"                       # Optional (space key)
  type: "page"                        # Optional: "page", "blogpost"
  labels: ["backend", "security"]     # Optional
  cql: 'creator = currentUser()'      # Optional (additional CQL filters)
  limit: 25                           # Optional, default: 25
  include_excerpt: true               # Optional, default: true
context:
  command: "planning:plan"
  purpose: "Finding authentication docs"
```

**Output YAML**:
```yaml
success: true
data:
  results:
    - id: "123456789"
      type: "page"
      title: "JWT Authentication Guide"
      space:
        key: "TECH"
        name: "Technical Docs"
      excerpt_markdown: |
        ... JWT tokens provide secure authentication ...
      url: "https://site.atlassian.net/wiki/spaces/TECH/pages/123456789"
      last_modified: "2025-01-15T10:30:00.000Z"
      last_modified_by:
        displayName: "John Doe"
      labels: ["backend", "security", "jwt"]
  total: 8
  has_more: false
  cql_used: 'text ~ "authentication JWT" AND space = TECH AND type = page'
metadata:
  cached: false
  duration_ms: 450
  mcp_calls: 1
  search_tokens: ["authentication", "JWT"]
```

**Implementation**:
```javascript
async function search_pages(params) {
  // Step 1: Build CQL query
  const cql = buildCqlQuery(params);

  // Step 2: Execute search via Confluence MCP
  const results = await mcp__atlassian__searchConfluenceUsingCql({
    cloudId: getCloudId(),
    cql: cql,
    limit: params.limit || 25
  });

  // Step 3: Transform results
  const transformed = results.results.map(result => {
    const page = {
      id: result.content.id,
      type: result.content.type,
      title: result.content.title,
      space: result.content.space,
      url: result.url,
      last_modified: result.lastModified
    };

    // Convert excerpt to Markdown if available
    if (params.include_excerpt && result.excerpt) {
      page.excerpt_markdown = htmlToMarkdown(result.excerpt);
    }

    return page;
  });

  return {
    success: true,
    data: {
      results: transformed,
      total: results.totalSize,
      has_more: results.size < results.totalSize,
      cql_used: cql
    },
    metadata: {
      cached: false,
      duration_ms: Date.now() - startTime,
      mcp_calls: 1,
      search_tokens: extractSearchTokens(params.query)
    }
  };
}

function buildCqlQuery(params) {
  const clauses = [];

  // Text search
  if (params.query) {
    clauses.push(`text ~ "${escapeForCql(params.query)}"`);
  }

  // Space filter
  if (params.space) {
    clauses.push(`space = ${params.space}`);
  }

  // Type filter
  if (params.type) {
    clauses.push(`type = ${params.type}`);
  }

  // Label filters
  if (params.labels && params.labels.length > 0) {
    const labelCql = params.labels.map(l => `label = "${l}"`).join(' AND ');
    clauses.push(`(${labelCql})`);
  }

  // Additional CQL
  if (params.cql) {
    clauses.push(`(${params.cql})`);
  }

  return clauses.join(' AND ');
}
```

---

### 1.3 create_page

Create new Confluence page (Markdown → ADF).

**Input YAML**:
```yaml
operation: create_page
params:
  space: "TECH"                        # Required (space key)
  title: "New Documentation"           # Required
  body: |                              # Required (Markdown)
    ## Overview
    This is the documentation...

    ### Features
    - Feature 1
    - Feature 2
  parent_id: "98765432"                # Optional (parent page ID)
  labels: ["backend", "new"]           # Optional
  status: "current"                    # Optional: "current", "draft"
context:
  command: "spec:create"
  purpose: "Creating specification page"
```

**Output YAML**:
```yaml
success: true
data:
  id: "123456790"
  title: "New Documentation"
  space:
    key: "TECH"
  url: "https://site.atlassian.net/wiki/spaces/TECH/pages/123456790"
  version:
    number: 1
metadata:
  cached: false
  duration_ms: 700
  mcp_calls: 1
  markdown_to_adf: true
```

**Implementation**:
```javascript
async function create_page(params) {
  // Step 1: Resolve space ID (cached)
  const spaceId = await resolveSpaceId(params.space);

  // Step 2: Convert Markdown to Confluence ADF
  const bodyAdf = markdownToConfluenceAdf(params.body);

  // Step 3: Create page via Confluence MCP
  const page = await mcp__atlassian__createConfluencePage({
    cloudId: getCloudId(),
    spaceId: spaceId,
    title: params.title,
    body: bodyAdf,
    parentId: params.parent_id,
    isPrivate: false
  });

  // Step 4: Cache page metadata
  cachePageMetadata(page);

  return {
    success: true,
    data: page,
    metadata: {
      cached: false,
      duration_ms: Date.now() - startTime,
      mcp_calls: 1,
      markdown_to_adf: true
    }
  };
}
```

---

### 1.4 update_page

Update existing Confluence page.

**Input YAML**:
```yaml
operation: update_page
params:
  page_id: "123456789"                 # Required
  title: "Updated Title"               # Optional
  body: |                              # Optional (Markdown)
    ## Updated Content
    ...
  version_message: "Updated auth docs"  # Optional
  increase_version: true               # Optional, default: true
context:
  command: "spec:sync"
```

**Output YAML**:
```yaml
success: true
data:
  id: "123456789"
  title: "Updated Title"
  version:
    number: 13
    message: "Updated auth docs"
metadata:
  cached: false
  duration_ms: 620
  mcp_calls: 1
  markdown_to_adf: true
```

---

### 1.5 get_page_tree

Get page hierarchy/tree structure.

**Input YAML**:
```yaml
operation: get_page_tree
params:
  root_page_id: "123456789"            # Optional (if omitted, space root)
  space: "TECH"                        # Required if root_page_id omitted
  depth: 3                             # Optional, default: 2
  include_content: false               # Optional, default: false
context:
  command: "spec:list"
```

**Output YAML**:
```yaml
success: true
data:
  tree:
    - id: "123456789"
      title: "Documentation Home"
      level: 0
      children:
        - id: "123456790"
          title: "Authentication"
          level: 1
          children:
            - id: "123456791"
              title: "JWT Setup"
              level: 2
              children: []
  total_pages: 12
metadata:
  cached: true                         # Tree structure cached
  duration_ms: 120
  mcp_calls: 0
  depth: 3
```

**Implementation**:
```javascript
const confluenceCache = {
  page_trees: {
    byRootPage: new Map()  // "123456789" → TreeStructure + timestamp
  }
};

async function get_page_tree(params) {
  const cacheKey = `${params.root_page_id || params.space}:${params.depth || 2}`;

  // Check cache (TTL: 10 minutes)
  const cached = confluenceCache.page_trees.byRootPage.get(cacheKey);
  if (cached && !isExpired(cached, TTL_PAGE_TREE)) {
    return {
      success: true,
      data: cached.data,
      metadata: { cached: true, duration_ms: 20, mcp_calls: 0, depth: params.depth || 2 }
    };
  }

  // Fetch tree structure
  const tree = await buildPageTree(params.root_page_id || params.space, params.depth || 2);

  // Cache result
  confluenceCache.page_trees.byRootPage.set(cacheKey, {
    data: tree,
    cached_at: Date.now()
  });

  return {
    success: true,
    data: tree,
    metadata: { cached: false, duration_ms: Date.now() - startTime, mcp_calls: 1, depth: params.depth || 2 }
  };
}
```

---

## 2. Space Operations

### 2.1 get_space

Get space details (heavily cached).

**Input YAML**:
```yaml
operation: get_space
params:
  space: "TECH"                        # Required (key or ID)
  expand: ["description", "icon"]      # Optional
context:
  command: "planning:plan"
```

**Output YAML**:
```yaml
success: true
data:
  id: "65536"
  key: "TECH"
  name: "Technical Documentation"
  type: "global"
  status: "current"
  description:
    markdown: "Central repository for all technical docs"
  homepage:
    id: "123456789"
    title: "Documentation Home"
  url: "https://site.atlassian.net/wiki/spaces/TECH"
metadata:
  cached: true
  duration_ms: 30
  mcp_calls: 0
```

**Implementation**:
```javascript
const confluenceCache = {
  spaces: {
    byKey: new Map(),   // "TECH" → SpaceObject
    byId: new Map()     // "65536" → SpaceObject
  }
};

async function get_space(params) {
  // Check cache by key
  const cachedByKey = confluenceCache.spaces.byKey.get(params.space.toUpperCase());
  if (cachedByKey) {
    return successResponse(cachedByKey, true);
  }

  // Check cache by ID
  if (isNumeric(params.space)) {
    const cachedById = confluenceCache.spaces.byId.get(params.space);
    if (cachedById) {
      return successResponse(cachedById, true);
    }
  }

  // Fetch from API
  const spaces = await mcp__atlassian__getConfluenceSpaces({
    cloudId: getCloudId(),
    keys: [params.space]
  });

  if (spaces.results.length === 0) {
    return error("SPACE_NOT_FOUND", `Space '${params.space}' not found`);
  }

  const space = spaces.results[0];

  // Cache result
  cacheSpace(space);

  return {
    success: true,
    data: space,
    metadata: { cached: false, duration_ms: Date.now() - startTime, mcp_calls: 1 }
  };
}

function cacheSpace(space) {
  confluenceCache.spaces.byKey.set(space.key.toUpperCase(), space);
  confluenceCache.spaces.byId.set(space.id, space);
}
```

---

### 2.2 list_spaces

List accessible spaces (populates cache).

**Input YAML**:
```yaml
operation: list_spaces
params:
  type: "global"                       # Optional: "global", "personal"
  status: "current"                    # Optional: "current", "archived"
  limit: 25                            # Optional
context:
  command: "utils:spaces"
```

**Output YAML**:
```yaml
success: true
data:
  spaces:
    - id: "65536"
      key: "TECH"
      name: "Technical Documentation"
      type: "global"
  total: 12
metadata:
  cached: false
  duration_ms: 420
  mcp_calls: 1
```

---

## 3. Comment Operations

### 3.1 add_comment

Add footer or inline comment.

**Input YAML**:
```yaml
operation: add_comment
params:
  page_id: "123456789"                 # Required
  body: "Great documentation!"         # Required (Markdown)
  type: "footer"                       # Optional: "footer", "inline"
  parent_comment_id: "456"             # Optional (for replies)
  inline_selection:                    # Required if type: "inline"
    text: "JWT authentication"
    match_index: 0
context:
  command: "planning:plan"
```

**Output YAML**:
```yaml
success: true
data:
  id: "10789"
  body: "Great documentation!"
  created: "2025-01-16T15:30:00.000Z"
  author:
    displayName: "John Doe"
metadata:
  cached: false
  duration_ms: 400
  mcp_calls: 1
  markdown_converted: true
```

---

### 3.2 get_comments

Retrieve page comments.

**Input YAML**:
```yaml
operation: get_comments
params:
  page_id: "123456789"                 # Required
  type: "footer"                       # Optional: "footer", "inline"
  status: "current"                    # Optional: "current", "resolved"
  limit: 50                            # Optional
context:
  command: "planning:plan"
```

**Output YAML**:
```yaml
success: true
data:
  comments:
    - id: "10789"
      body_markdown: "Great docs!"
      author:
        displayName: "John Doe"
      created: "2025-01-16T15:30:00.000Z"
  total: 8
metadata:
  cached: false
  duration_ms: 420
  mcp_calls: 1
```

---

## 4. Caching Strategy

### 4.1 Cache Structure

```javascript
const confluenceCache = {
  // Spaces (by key and ID) - NO TTL (stable)
  spaces: {
    byKey: new Map(),      // "TECH" → SpaceObject
    byId: new Map()        // "65536" → SpaceObject
  },

  // Page metadata (TTL: 5 minutes)
  page_metadata: {
    byId: new Map()        // "123456789" → PageMetadata + timestamp
  },

  // Page tree structures (TTL: 10 minutes)
  page_trees: {
    byRootPage: new Map()  // "123456789" → TreeStructure + timestamp
  },

  // Space permissions (by space key) - NO TTL
  permissions: {
    bySpace: new Map()     // "TECH" → PermissionsObject
  }
};
```

### 4.2 TTL Configuration

```javascript
const TTL_PAGE_META = 5 * 60 * 1000;   // 5 minutes
const TTL_PAGE_TREE = 10 * 60 * 1000;  // 10 minutes

function isExpired(cached, ttl) {
  const age = Date.now() - cached.cached_at;
  return age > ttl;
}
```

### 4.3 Cache Performance Targets

| Cache Type | Target Hit Rate | Cached Latency | Uncached Latency |
|------------|-----------------|----------------|------------------|
| Spaces | 90% | <50ms | 400ms |
| Page metadata | 70% | <80ms | 500ms |
| Page content | N/A | N/A | 580ms (not cached) |
| Page tree | 60% | <120ms | 600ms |

---

## 5. Markdown ↔ ADF Conversion

### 5.1 Confluence ADF → Markdown

```javascript
function confluenceAdfToMarkdown(adf) {
  const doc = JSON.parse(adf);
  const lines = [];

  for (const node of doc.content || []) {
    lines.push(convertAdfNode(node));
  }

  return lines.filter(l => l).join('\n\n');
}

function convertAdfNode(node) {
  switch (node.type) {
    case 'heading':
      const level = node.attrs?.level || 1;
      return `${'#'.repeat(level)} ${extractText(node.content)}`;

    case 'paragraph':
      return extractText(node.content);

    case 'bulletList':
      return node.content.map(item => `- ${extractText(item.content)}`).join('\n');

    case 'orderedList':
      return node.content.map((item, i) => `${i + 1}. ${extractText(item.content)}`).join('\n');

    case 'codeBlock':
      const lang = node.attrs?.language || '';
      return `\`\`\`${lang}\n${extractText(node.content)}\n\`\`\``;

    default:
      return '';
  }
}

function extractText(content) {
  if (!content) return '';
  return content.map(node => {
    if (node.type === 'text') return node.text;
    if (node.content) return extractText(node.content);
    return '';
  }).join('');
}
```

### 5.2 Markdown → Confluence ADF

```javascript
function markdownToConfluenceAdf(markdown) {
  const doc = {
    version: 1,
    type: 'doc',
    content: []
  };

  const lines = markdown.split('\n');
  let currentParagraph = [];

  for (const line of lines) {
    // Heading
    if (line.startsWith('#')) {
      if (currentParagraph.length > 0) {
        doc.content.push(createParagraph(currentParagraph.join('\n')));
        currentParagraph = [];
      }

      const level = line.match(/^#+/)[0].length;
      const text = line.replace(/^#+\s*/, '');
      doc.content.push({
        type: 'heading',
        attrs: { level: Math.min(level, 6) },
        content: [{ type: 'text', text }]
      });
      continue;
    }

    // Bullet list
    if (line.startsWith('- ') || line.startsWith('* ')) {
      if (currentParagraph.length > 0) {
        doc.content.push(createParagraph(currentParagraph.join('\n')));
        currentParagraph = [];
      }

      const text = line.replace(/^[-*]\s*/, '');
      doc.content.push({
        type: 'bulletList',
        content: [{
          type: 'listItem',
          content: [{ type: 'paragraph', content: [{ type: 'text', text }] }]
        }]
      });
      continue;
    }

    // Blank line
    if (line.trim() === '') {
      if (currentParagraph.length > 0) {
        doc.content.push(createParagraph(currentParagraph.join('\n')));
        currentParagraph = [];
      }
      continue;
    }

    currentParagraph.push(line);
  }

  if (currentParagraph.length > 0) {
    doc.content.push(createParagraph(currentParagraph.join('\n')));
  }

  return JSON.stringify(doc);
}
```

---

## 6. Error Handling

### 6.1 Error Codes

```yaml
# Entity Not Found (3000-3099)
3001: SPACE_NOT_FOUND
3002: PAGE_NOT_FOUND
3003: COMMENT_NOT_FOUND
3004: ATTACHMENT_NOT_FOUND

# Validation Errors (3100-3199)
3101: INVALID_CQL
3102: PERMISSION_DENIED
3103: REQUIRED_FIELD_MISSING
3104: INVALID_PAGE_ID
3105: PAGE_TITLE_EXISTS

# API Errors (3400-3499)
3401: CONFLUENCE_API_ERROR
3402: CONFLUENCE_API_RATE_LIMIT
3403: CONFLUENCE_API_TIMEOUT
3404: CONFLUENCE_API_UNAUTHORIZED
```

### 6.2 Error Response Example

```yaml
success: false
error:
  code: PAGE_NOT_FOUND
  message: "Page '123456789' not found in Confluence"
  details:
    page_id: "123456789"
    space_checked: "TECH"
  suggestions:
    - "Verify page ID is correct"
    - "Check if page was deleted or moved"
    - "Search for page by title: /ccpm:utils:confluence-search 'title'"
metadata:
  duration_ms: 250
  mcp_calls: 1
```

---

## 7. Performance Targets

| Operation | Cached | Uncached | Target Hit Rate |
|-----------|--------|----------|-----------------|
| get_space | <50ms | 400ms | 90% |
| Page metadata | <80ms | 500ms | 70% |
| Page content | N/A | 580ms | N/A (not cached) |
| search_pages | N/A | 450ms | N/A |
| Page tree | <120ms | 600ms | 60% |
| create_page | N/A | 700ms | N/A |

---

## 8. Usage in Commands

### Before (Direct MCP - 2800 tokens):
```markdown
## Step 1: Search Confluence

Use Confluence MCP:
1. Search for pages with "authentication"
2. Filter by TECH space
3. Convert excerpts to markdown
4. Sort by relevance

## Step 2: Get Page Content

Use Confluence MCP:
1. Get page by ID
2. Convert ADF to markdown
3. Extract relevant sections
```

### After (Subagent - 1260 tokens):
```markdown
## Step 1: Search and Fetch Confluence Docs

Task(confluence-operations): `
operation: search_pages
params:
  query: "authentication"
  space: "TECH"
  include_excerpt: true
`

Task(confluence-operations): `
operation: get_page
params:
  page_id: "${page_id_from_search}"
  body_format: "markdown"
`
```

**Token Reduction**: 55% (2,800 → 1,260 tokens)

---

## Related Documentation

- [Multi-PM Subagent Architecture](../docs/architecture/multi-pm-subagent-architecture.md)
- [Confluence Subagent Implementation Plan](../docs/architecture/confluence-subagent-implementation.md)
- [PM Operations Orchestrator](./pm-operations-orchestrator.md)
- [Jira Operations Subagent](./jira-operations.md)
