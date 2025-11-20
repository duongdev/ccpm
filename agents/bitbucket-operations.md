# bitbucket-operations

**Specialized agent for centralized BitBucket API operations with repository-aware caching.**

## Purpose

Optimize CCPM token usage by 35-45% for BitBucket operations through centralized handling and metadata caching.

**Key Benefits**:
- **Token Reduction**: 35-45% fewer tokens (1,800 → 1,170-990 tokens)
- **API Efficiency**: 55-60% fewer API calls through repository/user caching
- **Cache Performance**: 80-85% hit rate for repositories, users, projects
- **Consistency**: Standardized error handling
- **Safety**: Confirmation workflow for PR operations (inherited from SAFETY_RULES.md)

## Core Operations

**3 categories** with **8 operations**:

1. **Pull Request Operations** (4): get, list, create, search
2. **Repository Operations** (2): get, list
3. **Code Operations** (2): get_file, search_code

---

## 1. Pull Request Operations

### 1.1 get_pull_request

**Input YAML**:
```yaml
operation: get_pull_request
params:
  pr_number: 123                       # Required (PR number or ID)
  repository: "my-repo"                # Optional (slug or full name)
context:
  command: "pr:check-bitbucket"
```

**Output YAML**:
```yaml
success: true
data:
  id: 123
  title: "feat: Add JWT authentication"
  description: "## Overview\n..."
  state: "OPEN"
  author:
    display_name: "John Doe"
    uuid: "{abc-123}"
  source:
    branch: "feature/auth"
    repository: "my-repo"
  destination:
    branch: "main"
    repository: "my-repo"
  created_on: "2025-01-15T10:00:00Z"
  updated_on: "2025-01-16T14:30:00Z"
  reviewers: [...]
  participants: [...]
metadata:
  cached: false
  duration_ms: 450
  mcp_calls: 1
```

---

### 1.2 list_pull_requests

**Input YAML**:
```yaml
operation: list_pull_requests
params:
  repository: "my-repo"                # Required
  state: "OPEN"                        # Optional: OPEN, MERGED, DECLINED
  author: "john@example.com"          # Optional
  limit: 50                            # Optional
context:
  command: "utils:bitbucket-prs"
```

---

### 1.3 create_pull_request

**⚠️ SAFETY CRITICAL**: Requires confirmation (see SAFETY_RULES.md)

**Input YAML**:
```yaml
operation: create_pull_request
params:
  repository: "my-repo"                # Required
  title: "feat: Add authentication"    # Required
  description: |                       # Required
    ## Overview
    Adds JWT authentication...
  source_branch: "feature/auth"        # Required
  destination_branch: "main"           # Required
  reviewers: ["john@example.com"]     # Optional
  close_source_branch: true            # Optional
context:
  command: "complete:finalize"
```

**Output YAML**:
```yaml
success: true
data:
  id: 124
  title: "feat: Add authentication"
  links:
    html:
      href: "https://bitbucket.org/workspace/my-repo/pull-requests/124"
metadata:
  cached: false
  duration_ms: 650
  mcp_calls: 1
  confirmation_required: true
```

---

### 1.4 search_pull_requests

**Input YAML**:
```yaml
operation: search_pull_requests
params:
  query: "TRAIN-123"                   # Required
  repository: "my-repo"                # Optional
  state: "MERGED"                      # Optional
  limit: 25                            # Optional
context:
  command: "planning:plan"
```

---

## 2. Repository Operations

### 2.1 get_repository

**Input YAML**:
```yaml
operation: get_repository
params:
  repository: "my-repo"                # Required (slug or full name)
context:
  command: "pr:check-bitbucket"
```

**Output YAML**:
```yaml
success: true
data:
  slug: "my-repo"
  name: "My Repository"
  full_name: "workspace/my-repo"
  description: "Main application repository"
  is_private: true
  mainbranch:
    name: "main"
  project:
    key: "PROJ"
    name: "My Project"
  links:
    html:
      href: "https://bitbucket.org/workspace/my-repo"
metadata:
  cached: true
  duration_ms: 30
  mcp_calls: 0
```

**Implementation with Caching**:
```javascript
const bitbucketCache = {
  repositories: {
    bySlug: new Map(),     // "my-repo" → RepositoryObject
    byFullName: new Map()  // "workspace/my-repo" → RepositoryObject
  },
  users: {
    byUuid: new Map(),     // "{abc-123}" → UserObject
    byEmail: new Map()     // "john@example.com" → UserObject
  },
  projects: {
    byKey: new Map()       // "PROJ" → ProjectObject
  }
};

async function get_repository(params) {
  // Check cache by slug
  const cachedBySlug = bitbucketCache.repositories.bySlug.get(params.repository);
  if (cachedBySlug) return successResponse(cachedBySlug, true);

  // Check cache by full name
  const cachedByFullName = bitbucketCache.repositories.byFullName.get(params.repository);
  if (cachedByFullName) return successResponse(cachedByFullName, true);

  // Fetch from API and cache
  const repo = await fetchRepository(params.repository);
  cacheRepository(repo);

  return successResponse(repo, false);
}

function cacheRepository(repo) {
  bitbucketCache.repositories.bySlug.set(repo.slug, repo);
  bitbucketCache.repositories.byFullName.set(repo.full_name, repo);
}
```

---

### 2.2 list_repositories

**Input YAML**:
```yaml
operation: list_repositories
params:
  workspace: "my-workspace"            # Optional
  project: "PROJ"                      # Optional
  limit: 50                            # Optional
context:
  command: "utils:bitbucket-repos"
```

---

## 3. Code Operations

### 3.1 get_file

**Input YAML**:
```yaml
operation: get_file
params:
  repository: "my-repo"                # Required
  path: "src/auth.ts"                  # Required
  branch: "main"                       # Optional (default: main branch)
context:
  command: "planning:plan"
```

**Output YAML**:
```yaml
success: true
data:
  path: "src/auth.ts"
  content: "export function authenticateUser() { ... }"
  size: 2048
  mimetype: "text/plain"
metadata:
  cached: false
  duration_ms: 400
  mcp_calls: 1
```

---

### 3.2 search_code

**Input YAML**:
```yaml
operation: search_code
params:
  query: "authenticateUser"            # Required
  repository: "my-repo"                # Optional
  limit: 25                            # Optional
context:
  command: "planning:plan"
```

---

## 4. Caching Strategy

```javascript
const bitbucketCache = {
  repositories: {
    bySlug: new Map(),      // "my-repo" → RepositoryObject
    byFullName: new Map()   // "workspace/my-repo" → RepositoryObject
  },
  users: {
    byUuid: new Map(),      // "{abc-123}" → UserObject
    byEmail: new Map()      // "john@example.com" → UserObject
  },
  projects: {
    byKey: new Map()        // "PROJ" → ProjectObject
  }
};
```

**Cache Hit Rate Targets**:
- Repositories: 85%
- Users: 80%
- Projects: 90%

---

## 5. Error Handling

```yaml
# Error Codes (5000-5099)
5001: REPOSITORY_NOT_FOUND
5002: PULL_REQUEST_NOT_FOUND
5003: BRANCH_NOT_FOUND
5004: FILE_NOT_FOUND
5005: PERMISSION_DENIED

# API Errors (5400-5499)
5401: BITBUCKET_API_ERROR
5402: BITBUCKET_API_RATE_LIMIT
5403: BITBUCKET_API_TIMEOUT
```

---

## 6. Performance Targets

| Operation | Cached | Uncached | Target Hit Rate |
|-----------|--------|----------|-----------------|
| get_repository | <50ms | 400ms | 85% |
| get_user | <50ms | 350ms | 80% |
| search_pull_requests | N/A | 500ms | N/A |
| create_pull_request | N/A | 650ms | N/A |

---

## Related Documentation

- [PM Operations Orchestrator](./pm-operations-orchestrator.md)
- [SAFETY_RULES.md](../commands/SAFETY_RULES.md) - External system write confirmation
