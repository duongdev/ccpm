# Confluence Operations Subagent - Implementation Plan

**Part of**: PSN-31 - Phase 3: Token Efficiency
**Author**: Backend Architect Agent
**Date**: 2025-11-21
**Status**: Implementation Plan
**Version**: 1.0

---

## 1. Overview

The Confluence Operations Subagent provides centralized, optimized access to all Confluence operations with content-aware caching and Markdown transformation.

**Expected Impact**:
- **Token reduction**: 50-60% for Confluence-heavy operations
- **API call reduction**: 65-70%
- **Cache hit rate**: 80-85% for metadata
- **Performance**: <100ms cached, <600ms uncached

**Key Features**:
- Automatic Confluence ADF → Markdown conversion
- Page tree traversal and caching
- CQL search optimization
- Space-scoped caching

---

## 2. Operation Catalog

### 2.1 Page Operations (5 operations)

#### get_page
**Purpose**: Fetch page with content converted to Markdown

**Input Contract**:
```yaml
operation: get_page
params:
  page_id: "123456789"             # Required (numeric ID)
  include_body: true               # Optional, default: true
  include_comments: false          # Optional, default: false
  include_attachments: false       # Optional, default: false
  body_format: "markdown"          # Optional: "markdown", "storage", "view"
context:
  command: "planning:plan"
  purpose: "Fetching implementation guide"
```

**Output Contract**:
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

      ## Implementation Steps
      ...
    storage: "<p>...</p>"  # Original Confluence ADF/HTML
  version:
    number: 12
    when: "2025-01-15T10:30:00.000Z"
    by:
      accountId: "abc123"
      displayName: "John Doe"
  url: "https://site.atlassian.net/wiki/spaces/TECH/pages/123456789"
  ancestors: [...]         # Page hierarchy
  children: [...]          # If requested
  comments: [...]          # If include_comments: true
  attachments: [...]       # If include_attachments: true
metadata:
  cached: false
  duration_ms: 580
  mcp_calls: 1
  content_size_kb: 45
  markdown_conversion: true
```

**Implementation Logic**:
```javascript
async function get_page(params) {
  const startTime = Date.now();

  // Step 1: Check metadata cache
  let pageMeta = cache.confluence.page_metadata.get(params.page_id);
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
      cached: false,  // Content not cached
      duration_ms: Date.now() - startTime,
      mcp_calls: 1,
      content_size_kb: Math.round(page.body?.markdown?.length / 1024),
      markdown_conversion: params.body_format === 'markdown'
    }
  };
}
```

---

#### search_pages
**Purpose**: Search pages using CQL with Markdown snippets

**Input Contract**:
```yaml
operation: search_pages
params:
  query: "authentication JWT"     # Required (text search)
  space: "TECH"                   # Optional (space key)
  type: "page"                    # Optional: "page", "blogpost"
  labels: ["backend", "security"] # Optional
  cql: 'creator = currentUser()'  # Optional (additional CQL filters)
  limit: 25                       # Optional, default: 25
  include_excerpt: true           # Optional, default: true
context:
  command: "planning:plan"
  purpose: "Finding authentication docs"
```

**Output Contract**:
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
    # ... more results
  total: 8
  has_more: false
  cql_used: 'text ~ "authentication JWT" AND space = TECH AND type = page'
metadata:
  cached: false
  duration_ms: 450
  mcp_calls: 1
  search_tokens: ["authentication", "JWT"]
```

**Implementation Logic**:
```javascript
async function search_pages(params) {
  // Step 1: Build CQL query
  let cql = buildCqlQuery(params);

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

#### create_page
**Purpose**: Create new Confluence page (Markdown → ADF)

**Input Contract**:
```yaml
operation: create_page
params:
  space: "TECH"                    # Required (space key)
  title: "New Documentation"       # Required
  body: |                          # Required (Markdown)
    ## Overview
    This is the documentation...
  parent_id: "98765432"            # Optional (parent page ID)
  labels: ["backend", "new"]       # Optional
  status: "current"                # Optional: "current", "draft"
context:
  command: "spec:create"
  purpose: "Creating specification page"
```

**Output Contract**:
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

**Implementation Logic**:
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

  // Step 4: Add labels if specified
  if (params.labels && params.labels.length > 0) {
    await addPageLabels(page.id, params.labels);
  }

  // Step 5: Cache page metadata
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

#### update_page
**Purpose**: Update existing Confluence page

**Input Contract**:
```yaml
operation: update_page
params:
  page_id: "123456789"             # Required
  title: "Updated Title"           # Optional
  body: |                          # Optional (Markdown)
    ## Updated Content
    ...
  version_message: "Updated auth docs"  # Optional
  increase_version: true           # Optional, default: true
context:
  command: "spec:sync"
```

---

#### get_page_tree
**Purpose**: Get page hierarchy/tree structure

**Input Contract**:
```yaml
operation: get_page_tree
params:
  root_page_id: "123456789"        # Optional (if omitted, space root)
  space: "TECH"                    # Required if root_page_id omitted
  depth: 3                         # Optional, default: 2
  include_content: false           # Optional, default: false
context:
  command: "spec:list"
```

**Output Contract**:
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
        - id: "123456792"
          title: "API Reference"
          level: 1
          children: []
  total_pages: 12
metadata:
  cached: true   # Tree structure cached
  duration_ms: 120
  mcp_calls: 0
  depth: 3
```

---

### 2.2 Space Operations (2 operations)

#### get_space
**Purpose**: Get space details (heavily cached)

**Input Contract**:
```yaml
operation: get_space
params:
  space: "TECH"                    # Required (key or ID)
  expand: ["description", "icon"]  # Optional
context:
  command: "planning:plan"
```

**Output Contract**:
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

---

#### list_spaces
**Purpose**: List accessible spaces (populates cache)

**Input Contract**:
```yaml
operation: list_spaces
params:
  type: "global"                   # Optional: "global", "personal"
  status: "current"                # Optional: "current", "archived"
  limit: 25                        # Optional
context:
  command: "utils:spaces"
```

---

### 2.3 Comment Operations (2 operations)

#### add_comment
**Purpose**: Add footer or inline comment

**Input Contract**:
```yaml
operation: add_comment
params:
  page_id: "123456789"             # Required
  body: "Great documentation!"     # Required (Markdown)
  type: "footer"                   # Optional: "footer", "inline"
  parent_comment_id: "456"         # Optional (for replies)
  inline_selection:                # Required if type: "inline"
    text: "JWT authentication"
    match_index: 0
context:
  command: "planning:plan"
```

---

#### get_comments
**Purpose**: Retrieve page comments

**Input Contract**:
```yaml
operation: get_comments
params:
  page_id: "123456789"             # Required
  type: "footer"                   # Optional: "footer", "inline"
  status: "current"                # Optional: "current", "resolved"
  limit: 50                        # Optional
context:
  command: "planning:plan"
```

---

## 3. Caching Implementation

### 3.1 Cache Structure

```javascript
const confluenceCache = {
  // Spaces (by key and ID)
  spaces: {
    byKey: new Map(),      // "TECH" → SpaceObject
    byId: new Map()        // "65536" → SpaceObject
  },

  // Page metadata (NOT content) - TTL: 5 minutes
  page_metadata: {
    byId: new Map()        // "123456789" → PageMetadata + timestamp
  },

  // Page tree structures - TTL: 10 minutes
  page_trees: {
    byRootPage: new Map()  // "123456789" → TreeStructure + timestamp
  },

  // Space permissions (by space key)
  permissions: {
    bySpace: new Map()     // "TECH" → PermissionsObject
  }
};
```

### 3.2 TTL-Based Caching

**Page Metadata** (5 minute TTL):
```javascript
function cachePageMetadata(page) {
  const metadata = {
    id: page.id,
    title: page.title,
    space: page.space,
    url: page.url,
    version: page.version,
    last_modified: page.version.when,
    cached_at: Date.now()
  };

  confluenceCache.page_metadata.byId.set(page.id, metadata);
}

function getPageMetadataFromCache(pageId) {
  const cached = confluenceCache.page_metadata.byId.get(pageId);
  if (!cached) return null;

  const age = Date.now() - cached.cached_at;
  const TTL = 5 * 60 * 1000;  // 5 minutes

  if (age > TTL) {
    confluenceCache.page_metadata.byId.delete(pageId);
    return null;
  }

  return cached;
}
```

**Page Trees** (10 minute TTL):
```javascript
function cachePageTree(rootPageId, tree) {
  confluenceCache.page_trees.byRootPage.set(rootPageId, {
    tree: tree,
    cached_at: Date.now()
  });
}
```

### 3.3 Cache Invalidation

**Automatic**:
- TTL expiry (5-10 minutes)
- Session end (all caches cleared)

**Manual**:
- `refresh_cache: true` parameter
- After page create/update (invalidate tree)

---

## 4. Markdown Conversion

### 4.1 Confluence ADF → Markdown

```javascript
function confluenceAdfToMarkdown(adf) {
  // Parse Confluence ADF (Atlassian Document Format)
  const doc = JSON.parse(adf);

  // Convert to Markdown AST
  const markdownAst = convertAdfNode(doc);

  // Render Markdown
  return renderMarkdown(markdownAst);
}

function convertAdfNode(node) {
  switch (node.type) {
    case 'heading':
      return `${'#'.repeat(node.attrs.level)} ${extractText(node.content)}\n\n`;

    case 'paragraph':
      return `${extractText(node.content)}\n\n`;

    case 'bulletList':
      return node.content.map(item =>
        `- ${extractText(item.content)}\n`
      ).join('');

    case 'orderedList':
      return node.content.map((item, i) =>
        `${i + 1}. ${extractText(item.content)}\n`
      ).join('');

    case 'codeBlock':
      const lang = node.attrs?.language || '';
      return `\`\`\`${lang}\n${extractText(node.content)}\n\`\`\`\n\n`;

    case 'table':
      return convertTableToMarkdown(node);

    default:
      return '';
  }
}
```

### 4.2 Markdown → Confluence ADF

```javascript
function markdownToConfluenceAdf(markdown) {
  // Parse Markdown to AST
  const ast = parseMarkdown(markdown);

  // Convert to Confluence ADF
  const adf = {
    version: 1,
    type: 'doc',
    content: ast.map(convertMarkdownNode)
  };

  return JSON.stringify(adf);
}

function convertMarkdownNode(node) {
  switch (node.type) {
    case 'heading':
      return {
        type: 'heading',
        attrs: { level: node.depth },
        content: [{ type: 'text', text: node.text }]
      };

    case 'paragraph':
      return {
        type: 'paragraph',
        content: [{ type: 'text', text: node.text }]
      };

    case 'code':
      return {
        type: 'codeBlock',
        attrs: { language: node.lang || 'text' },
        content: [{ type: 'text', text: node.value }]
      };

    // ... more node types
  }
}
```

---

## 5. Error Handling

### 5.1 Error Codes

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

### 5.2 Error Response Example

**PAGE_NOT_FOUND**:
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

## 6. Performance Targets

| Operation | Cached | Uncached | Target Hit Rate |
|-----------|--------|----------|-----------------|
| Space lookup | <50ms | 400ms | 90% |
| Page metadata | <80ms | 500ms | 70% |
| Page content | N/A | 580ms | N/A (not cached) |
| Search pages | N/A | 450ms | N/A |
| Page tree | <120ms | 600ms | 60% |
| Create page | N/A | 700ms | N/A |

---

## 7. Testing Strategy

### 7.1 Unit Tests

```javascript
// Test: Markdown to ADF conversion
test('markdownToConfluenceAdf converts correctly', () => {
  const markdown = '## Heading\nParagraph\n- List item';
  const adf = markdownToConfluenceAdf(markdown);
  const parsed = JSON.parse(adf);

  expect(parsed.type).toBe('doc');
  expect(parsed.content[0].type).toBe('heading');
  expect(parsed.content[0].attrs.level).toBe(2);
});

// Test: Page search with CQL
test('search_pages builds correct CQL', async () => {
  const result = await search_pages({
    query: 'authentication',
    space: 'TECH',
    labels: ['backend']
  });

  expect(result.success).toBe(true);
  expect(result.data.cql_used).toContain('text ~ "authentication"');
  expect(result.data.cql_used).toContain('space = TECH');
  expect(result.data.cql_used).toContain('label = "backend"');
});
```

---

## 8. Migration Checklist

- [ ] Create `agents/confluence-operations.md`
- [ ] Implement cache with TTL
- [ ] Implement Markdown conversion (ADF ↔ Markdown)
- [ ] Implement all 9 operations
- [ ] Add CQL query builder
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Migrate planning commands
- [ ] Document all operations

---

**Document Version**: 1.0
**Last Updated**: 2025-11-21
**Ready for**: Implementation
