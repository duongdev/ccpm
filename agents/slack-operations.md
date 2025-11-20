# slack-operations

**Specialized agent for centralized Slack API operations with conversation-aware caching.**

## Purpose

Optimize CCPM token usage by 40-50% for Slack operations through centralized handling and metadata caching.

**Key Benefits**:
- **Token Reduction**: 40-50% fewer tokens (2,200 → 1,100-1,320 tokens)
- **API Efficiency**: 60-65% fewer API calls through channel/user caching
- **Cache Performance**: 85-95% hit rate for channels, users
- **Consistency**: Standardized error handling
- **Safety**: Confirmation workflow for message posting (inherited from SAFETY_RULES.md)

## Core Operations

**3 categories** with **8 operations**:

1. **Channel Operations** (3): get, list, search_messages
2. **Message Operations** (3): post, get_thread, get_history
3. **User Operations** (2): get, list

---

## 1. Channel Operations

### 1.1 get_channel

**Input YAML**:
```yaml
operation: get_channel
params:
  channel: "C12345678"                 # Required (ID or name)
context:
  command: "complete:finalize"
```

**Output YAML**:
```yaml
success: true
data:
  id: "C12345678"
  name: "engineering"
  is_channel: true
  is_archived: false
  is_member: true
metadata:
  cached: true
  duration_ms: 30
  mcp_calls: 0
```

---

### 1.2 list_channels

**Input YAML**:
```yaml
operation: list_channels
params:
  exclude_archived: true               # Optional
  types: ["public_channel"]            # Optional
context:
  command: "utils:slack-channels"
```

---

### 1.3 search_messages

**Input YAML**:
```yaml
operation: search_messages
params:
  query: "authentication bug"          # Required
  channel: "engineering"               # Optional (name or ID)
  from_user: "john@example.com"       # Optional
  after: "2025-01-01"                  # Optional (ISO date)
  limit: 50                            # Optional
context:
  command: "planning:plan"
```

**Output YAML**:
```yaml
success: true
data:
  messages:
    - ts: "1705320000.123456"
      user:
        id: "U12345"
        name: "John Doe"
        email: "john@example.com"
      text: "We found a bug in JWT validation..."
      channel:
        id: "C12345678"
        name: "engineering"
      thread_ts: "1705320000.123456"
      replies: 5
      permalink: "https://workspace.slack.com/archives/..."
  total: 12
  has_more: false
metadata:
  cached: false
  duration_ms: 500
  mcp_calls: 1
```

---

## 2. Message Operations

### 2.1 post_message

**⚠️ SAFETY CRITICAL**: Requires confirmation (see SAFETY_RULES.md)

**Input YAML**:
```yaml
operation: post_message
params:
  channel: "engineering"               # Required (name or ID)
  text: "🎉 PSN-124 complete!"         # Required
  thread_ts: "1705320000.123456"      # Optional (reply to thread)
  blocks: [...]                        # Optional (rich formatting)
context:
  command: "complete:finalize"
  purpose: "Notifying team of completion"
```

**Output YAML**:
```yaml
success: true
data:
  ts: "1705330000.654321"
  channel: "C12345678"
  message:
    text: "🎉 PSN-124 complete!"
    user: "U67890"
metadata:
  cached: false
  duration_ms: 350
  mcp_calls: 1
  confirmation_required: true          # Indicates user must confirm
```

---

### 2.2 get_thread

**Input YAML**:
```yaml
operation: get_thread
params:
  channel: "engineering"               # Required
  thread_ts: "1705320000.123456"      # Required
  limit: 50                            # Optional
context:
  command: "planning:plan"
```

---

### 2.3 get_message_history

**Input YAML**:
```yaml
operation: get_message_history
params:
  channel: "engineering"               # Required
  oldest: "2025-01-01"                 # Optional (ISO date)
  latest: "2025-01-31"                 # Optional
  limit: 100                           # Optional
context:
  command: "planning:plan"
```

---

## 3. User Operations

### 3.1 get_user

**Input YAML**:
```yaml
operation: get_user
params:
  user: "john@example.com"            # Required (email, name, or ID)
context:
  command: "complete:finalize"
```

**Output YAML**:
```yaml
success: true
data:
  id: "U12345"
  name: "John Doe"
  real_name: "John Doe"
  email: "john@example.com"
  is_admin: false
  is_bot: false
metadata:
  cached: true
  duration_ms: 25
  mcp_calls: 0
```

**Implementation with Caching**:
```javascript
const slackCache = {
  users: {
    byId: new Map(),
    byEmail: new Map(),
    byName: new Map()
  },
  channels: {
    byId: new Map(),
    byName: new Map()
  }
};

async function get_user(params) {
  // Check cache by email
  if (params.user.includes('@')) {
    const cached = slackCache.users.byEmail.get(params.user.toLowerCase());
    if (cached) return successResponse(cached, true);
  }

  // Check cache by ID
  const cachedById = slackCache.users.byId.get(params.user);
  if (cachedById) return successResponse(cachedById, true);

  // Fetch from API and cache
  const user = await fetchUser(params.user);
  cacheUser(user);

  return successResponse(user, false);
}

function cacheUser(user) {
  slackCache.users.byId.set(user.id, user);
  if (user.email) slackCache.users.byEmail.set(user.email.toLowerCase(), user);
  if (user.name) slackCache.users.byName.set(user.name.toLowerCase(), user);
}
```

---

### 3.2 list_users

**Input YAML**:
```yaml
operation: list_users
params:
  limit: 100                           # Optional
context:
  command: "utils:slack-users"
```

---

## 4. Caching Strategy

```javascript
const slackCache = {
  channels: {
    byId: new Map(),    // "C12345678" → ChannelObject
    byName: new Map()   // "engineering" → ChannelObject
  },
  users: {
    byId: new Map(),    // "U12345" → UserObject
    byEmail: new Map(), // "john@example.com" → UserObject
    byName: new Map()   // "John Doe" → UserObject
  },
  workspace: null       // WorkspaceMetadata
};
```

**Cache Hit Rate Targets**:
- Channels: 90%
- Users: 90%

---

## 5. Error Handling

```yaml
# Error Codes (4000-4099)
4001: CHANNEL_NOT_FOUND
4002: USER_NOT_FOUND
4003: MESSAGE_NOT_FOUND
4004: PERMISSION_DENIED
4005: CHANNEL_ARCHIVED

# API Errors (4400-4499)
4401: SLACK_API_ERROR
4402: SLACK_API_RATE_LIMIT
4403: SLACK_API_TIMEOUT
```

---

## 6. Performance Targets

| Operation | Cached | Uncached | Target Hit Rate |
|-----------|--------|----------|-----------------|
| get_channel | <50ms | 350ms | 90% |
| get_user | <50ms | 350ms | 90% |
| search_messages | N/A | 500ms | N/A |
| post_message | N/A | 350ms | N/A |

---

## Related Documentation

- [PM Operations Orchestrator](./pm-operations-orchestrator.md)
- [SAFETY_RULES.md](../commands/SAFETY_RULES.md) - External system write confirmation
