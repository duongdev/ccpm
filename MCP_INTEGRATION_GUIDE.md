# MCP Integration Guide for CCPM

This guide provides comprehensive documentation for integrating Model Context Protocol (MCP) servers with CCPM and best practices for their usage.

---

## 🎯 Overview

CCPM leverages three required MCP servers and several optional ones to provide a seamless development experience. This document covers setup, configuration, best practices, and troubleshooting for each MCP integration.

---

## 📋 Table of Contents

1. [Required MCP Servers](#required-mcp-servers)
   - [Linear MCP](#linear-mcp)
   - [GitHub MCP](#github-mcp)
   - [Context7 MCP](#context7-mcp)
2. [Optional MCP Servers](#optional-mcp-servers)
3. [Best Practices](#best-practices)
4. [Troubleshooting](#troubleshooting)

---

## Required MCP Servers

### Linear MCP

**Purpose:** Task tracking, spec management, and project organization

#### Installation

##### Option 1: NPX (Recommended)
```bash
# Add to Claude Code settings
LINEAR_API_KEY=your-api-key npx @lucitra/linear-mcp
```

##### Option 2: Manual Build
```bash
git clone https://github.com/ibraheem4/linear-mcp
cd linear-mcp
npm install
npm run build
```

#### Configuration

Add to your `~/.claude/settings.json` or Claude Desktop config:

```json
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "@lucitra/linear-mcp"],
      "env": {
        "LINEAR_API_KEY": "lin_api_xxxxxxxxxxxxx"
      },
      "disabled": false,
      "alwaysAllow": []
    }
  }
}
```

**Alternative (built from source):**
```json
{
  "mcpServers": {
    "linear": {
      "command": "node",
      "args": ["/path/to/linear-mcp/build/index.js"],
      "env": {
        "LINEAR_API_KEY": "lin_api_xxxxxxxxxxxxx"
      }
    }
  }
}
```

#### Getting Your API Key

1. Go to [Linear Settings](https://linear.app/settings) → API
2. Create a new API key
3. Copy and store securely
4. Set as environment variable or in config

#### Available Tools

The Linear MCP server provides the following capabilities:

| Tool | Description | Parameters |
|------|-------------|------------|
| `linear_create_issue` | Create new issues | `title`, `description?`, `teamId`, `assigneeId?`, `priority?`, `labels?`, `status?` |
| `linear_list_issues` | List/filter issues | `teamId?`, `assigneeId?`, `status?`, `first?` |
| `linear_update_issue` | Update existing issues | `issueId`, `title?`, `description?`, `status?`, `assigneeId?`, `priority?`, `labels?` |
| `linear_get_issue` | Get detailed issue info | `issueId` |
| `linear_list_teams` | Get all workspace teams | None |
| `linear_list_projects` | List projects | `teamId?`, `first?` |
| `linear_search_issues` | Text-based search | `query` |
| `linear_list_workflow_states` | Get workflow states | `teamId` |

#### Best Practices

**1. Always Query Teams First**
```bash
# Before creating issues, get team IDs
linear_list_teams
```

**2. Use Human-Readable Status Names**
```bash
# Status accepts names like "In Progress", "Done", "Canceled"
# No need to look up state IDs
```

**3. Pagination for Large Results**
```bash
# Default is 50 items, adjust as needed
linear_list_issues teamId="TEAM-123" first=100
```

**4. Error Handling**
- Always check for Linear API errors in responses
- Handle rate limiting gracefully
- Validate team/project IDs before operations

#### Common Patterns

**Create Epic/Feature with Linear Document:**
```typescript
// 1. Create Linear Issue (Epic or Feature)
const issue = await linear_create_issue({
  title: "User Authentication System",
  teamId: "TEAM-123",
  priority: 1
});

// 2. Create Linear Document
// 3. Link document to issue
// 4. Populate with template content
```

**Task Breakdown:**
```typescript
// 1. Query parent issue
const epic = await linear_get_issue({ issueId: "EPIC-1" });

// 2. Create child issues
await linear_create_issue({
  title: "Implement JWT auth",
  parentId: "EPIC-1",
  teamId: "TEAM-123"
});
```

---

### GitHub MCP

**Purpose:** PR creation, code hosting, repository operations, CI/CD visibility

#### Installation

##### Option 1: Remote Server (Recommended)
GitHub provides a managed MCP endpoint that eliminates infrastructure overhead.

**VS Code Setup:**
1. Run command: `> GitHub MCP: Install Remote Server`
2. Complete OAuth flow to connect your GitHub account
3. Restart server to finalize

**Other Clients:**
```json
{
  "mcpServers": {
    "github": {
      "command": "github-mcp",
      "args": ["--remote"],
      "env": {}
    }
  }
}
```

Server URL: `https://api.githubcopilot.com/mcp/`

##### Option 2: Local Server
```bash
npm install -g @modelcontextprotocol/server-github
```

#### Configuration

**Remote Server (Recommended):**
```json
{
  "mcpServers": {
    "github": {
      "command": "github-mcp",
      "args": ["--remote"],
      "disabled": false
    }
  }
}
```

**Local Server:**
```json
{
  "mcpServers": {
    "github": {
      "command": "mcp-server-github",
      "env": {
        "GITHUB_TOKEN": "ghp_xxxxxxxxxxxxx"
      }
    }
  }
}
```

#### Authentication

**Remote Server:**
- OAuth flow handles authentication automatically
- No personal access tokens needed
- Test: `curl -I https://api.githubcopilot.com/mcp/_ping` (expect HTTP 200)

**Local Server:**
1. Go to [GitHub Settings](https://github.com/settings/tokens) → Developer settings → Personal access tokens
2. Generate new token with required scopes:
   - `repo` - Full repository access
   - `workflow` - Update GitHub Actions workflows
   - `read:org` - Read organization data
3. Set as `GITHUB_TOKEN` environment variable

#### Available Toolsets

| Toolset | Capabilities |
|---------|-------------|
| **Repository Intelligence** | Code search, file streaming, PR access without local clones |
| **Issue/PR Automation** | Filing, triage, labeling, review, and merge operations |
| **CI/CD Visibility** | Workflow inspection, log retrieval, job re-runs |
| **Security Insights** | Code scanning and Dependabot alerts access |

#### Access Control

**Read-Only Mode:**
```json
{
  "mcpServers": {
    "github": {
      "command": "github-mcp",
      "args": ["--remote", "--readonly"]
    }
  }
}
```

Or add header: `"X-MCP-Readonly": "true"`

**Selective Toolsets:**
```json
{
  "mcpServers": {
    "github": {
      "command": "github-mcp",
      "args": ["--remote"],
      "config": {
        "toolsets": ["context", "issues", "pull_requests"]
      }
    }
  }
}
```

#### Best Practices

**1. Use Remote Server**
- Eliminates Docker maintenance
- No personal access token rotation
- Automatic updates
- OAuth security
- Cross-device accessibility

**2. Enable Read-Only for Demos**
Safe exploration in production or demo environments without risking changes.

**3. Selective Toolsets**
Limit agent capabilities to essential operations for focused development.

**4. PR Creation Workflow**
```bash
# 1. Create branch
# 2. Commit changes
# 3. Use GitHub MCP to create PR
# 4. Request reviews
# 5. Monitor CI/CD status
```

#### Common Patterns

**CODEOWNERS Automation:**
```typescript
// 1. Create CODEOWNERS file
// 2. Open PR
// 3. Assign reviewers based on CODEOWNERS
```

**CI/CD Debugging:**
```typescript
// 1. Retrieve workflow logs
// 2. Analyze failures
// 3. Re-run jobs if needed
```

**Security Triage:**
```typescript
// 1. List Dependabot alerts
// 2. Create focused issues
// 3. Track remediation
```

---

### Context7 MCP

**Purpose:** Fetch latest library documentation directly into prompts

#### Installation

```bash
# Add to Claude Code settings - Context7 is installed automatically
# No additional setup required
```

#### Configuration

Add to your `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "disabled": false
    }
  }
}
```

#### Usage Pattern

**Three-step workflow:**

1. **Write naturally** - Ask your question normally
2. **Invoke Context7** - Include "use context7" in your prompt
3. **Receive updated code** - Get responses based on official documentation

**Example Prompts:**
```bash
# ✅ Good
"How does the new Next.js `after()` function work? use context7"
"How do I invalidate a query in React Query? use context7"
"Protect this route with NextAuth, use context7"

# ❌ Avoid
"Explain sorting algorithms"  # General CS concepts don't need Context7
"What is a closure?"  # Language fundamentals
```

#### How It Works

When triggered, Context7:

1. **Identifies** the library or framework in your question
2. **Retrieves** current official documentation
3. **Filters** docs by relevant topic (routing, validation, middleware)
4. **Injects** documentation directly into the model's context window

#### Supported Libraries

Context7 works with fast-moving frameworks including:
- Next.js
- React Query (TanStack Query)
- Zod
- Tailwind CSS
- shadcn/ui
- Many more...

#### Best Practices

**1. Always Use Context7 for Library Questions**
```bash
# ✅ Always use Context7 for library/framework questions
"How do I use React Query mutations? use context7"

# ❌ Never rely on knowledge cutoff for libraries
"How do I use React Query mutations?"  # May return outdated info
```

**2. MANDATORY in CLAUDE.md**
The global `CLAUDE.md` enforces Context7 usage:
- All library/framework queries MUST use Context7
- No exceptions for external dependencies
- Always fetch latest documentation

**3. Version-Specific Queries**
```bash
"How do I use middleware in Next.js 15? use context7"
```

**4. Topic Filtering**
Be specific about what you're looking for:
```bash
# ✅ Specific
"How do I handle errors in React Query? use context7"

# ❌ Too broad
"Tell me about React Query. use context7"
```

#### Common Patterns

**Learning New APIs:**
```bash
"Show me how to use the new Next.js 15 `after()` function. use context7"
```

**Debugging Issues:**
```bash
"Why is my TanStack Query cache not invalidating? use context7"
```

**Migration Guides:**
```bash
"What changed in React Query v5? use context7"
```

#### Key Benefits

- **Free** - Built and maintained by Upstash at no cost
- **Current** - Always pulls latest documentation
- **Seamless** - Simple "use context7" command syntax
- **Intelligent filtering** - Contextually relevant information injection

---

## Optional MCP Servers

### Playwright MCP

**Purpose:** Browser automation for testing, PR checks, and visual validation

**Installation:**
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@microsoft/playwright-mcp"]
    }
  }
}
```

**Use Cases:**
- Automated browser testing
- Visual regression testing
- PR verification (load pages, check for errors)
- Screenshot capture

### Vercel MCP

**Purpose:** Deployment integration and preview environment management

**Installation:**
```json
{
  "mcpServers": {
    "vercel": {
      "command": "npx",
      "args": ["-y", "@vercel/mcp"],
      "env": {
        "VERCEL_TOKEN": "your-token"
      }
    }
  }
}
```

**Use Cases:**
- Deploy preview environments
- Monitor deployment status
- Access deployment logs
- Environment variable management

### Shadcn MCP

**Purpose:** UI component integration with shadcn/ui library

**Installation:**
```json
{
  "mcpServers": {
    "shadcn": {
      "command": "npx",
      "args": ["-y", "@shadcn/mcp"]
    }
  }
}
```

**Use Cases:**
- Install shadcn/ui components
- Browse component catalog
- Get component usage examples
- Customize component themes

---

## Best Practices

### Architecture Principles

**1. Single Responsibility**
Each MCP server should have one clear purpose. Don't overload a single server with multiple concerns.

**2. Defense in Depth Security**
Layer security controls throughout your architecture:
- Network isolation
- Authentication
- Authorization
- Input validation
- Output sanitization

**3. Fail-Safe Design**
Build systems that gracefully degrade:
- Circuit breakers
- Caching strategies
- Rate limiting
- Fallback mechanisms

### Configuration Management

**1. Environment Variables**
Always externalize configuration:
```bash
# ✅ Good
LINEAR_API_KEY=your-key
GITHUB_TOKEN=your-token

# ❌ Bad - Never hardcode
```

**2. Validation**
Use validation frameworks (like Pydantic) to ensure configuration correctness.

**3. Environment-Specific Overrides**
```json
{
  "mcpServers": {
    "linear": {
      "env": {
        "LINEAR_API_KEY": "${LINEAR_API_KEY}",
        "LINEAR_API_URL": "${LINEAR_API_URL:-https://api.linear.app}"
      }
    }
  }
}
```

### Error Handling

**1. Classify Errors**
- **Client errors** (4xx) - Invalid request, retry won't help
- **Server errors** (5xx) - Temporary, retry may help
- **Network errors** - Timeout, connection refused
- **External dependency failures** - Third-party service down

**2. Structured Error Responses**
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Issue WORK-123 not found",
    "retryable": false
  }
}
```

**3. Retry Guidance**
Include retry information in error responses:
- Retryable: Yes/No
- Retry-After: Seconds to wait
- Max-Retries: Maximum attempts

### Performance Optimization

**1. Connection Pooling**
Reuse connections instead of creating new ones for each request.

**2. Multi-Level Caching**
- In-memory cache (fast, volatile)
- Distributed cache (Redis, Memcached)
- Durable cache (Database, S3)

**3. Async Processing**
Use async/await patterns for heavy operations to avoid blocking.

**4. Rate Limiting**
Implement rate limits to protect against abuse:
- Per-user limits
- Per-endpoint limits
- Global limits

### Monitoring & Observability

**1. Metrics Collection**
- Request counts
- Response latencies
- Error rates
- Connection pool stats

**2. Structured Logging**
```json
{
  "timestamp": "2025-01-10T12:00:00Z",
  "level": "info",
  "message": "Issue created",
  "context": {
    "issueId": "WORK-123",
    "userId": "user-456",
    "duration_ms": 234
  }
}
```

**3. Health Checks**
Implement layered health monitoring:
- `/health` - Basic liveness
- `/health/ready` - Readiness for traffic
- `/health/detailed` - Component-level status

### Security Best Practices

**1. Credential Management**
- Use environment variables
- Never commit secrets
- Rotate tokens regularly
- Use separate tokens for dev/staging/prod

**2. Input Validation**
Validate all inputs before processing:
- Type checking
- Range validation
- Format validation
- Sanitization

**3. Output Sanitization**
Clean all outputs before returning:
- Remove sensitive data
- Escape special characters
- Limit response size

**4. Rate Limiting & DDoS Protection**
- Implement per-user rate limits
- Use exponential backoff
- Monitor for abuse patterns

---

## Troubleshooting

### Common Issues

#### MCP Server Not Found

**Symptoms:**
```
Error: MCP server 'linear' not found
```

**Solutions:**
1. Verify server is installed: `npx @lucitra/linear-mcp --version`
2. Check configuration in `~/.claude/settings.json`
3. Restart Claude Code: `claude --restart`

#### Authentication Failures

**Symptoms:**
```
Error: Unauthorized - Invalid API key
```

**Solutions:**
1. Verify API key is correct
2. Check environment variable is set: `echo $LINEAR_API_KEY`
3. Ensure key has required permissions
4. Regenerate key if expired

#### Connection Timeouts

**Symptoms:**
```
Error: Request timeout after 30000ms
```

**Solutions:**
1. Check network connectivity
2. Verify service is online (status pages)
3. Increase timeout in configuration
4. Check for rate limiting

#### Rate Limiting

**Symptoms:**
```
Error: Rate limit exceeded. Retry after 60s
```

**Solutions:**
1. Implement exponential backoff
2. Reduce request frequency
3. Use caching to minimize requests
4. Contact provider for rate limit increase

### Debug Mode

Enable verbose logging to diagnose issues:

```bash
# Enable debug mode
export CLAUDE_DEBUG=1
claude --verbose

# Check MCP server logs
tail -f ~/.claude/logs/mcp-*.log
```

### Validation Tests

**Test Linear MCP:**
```bash
# Test connection
linear_list_teams

# Expected: Array of teams
```

**Test GitHub MCP:**
```bash
# Test remote server
curl -I https://api.githubcopilot.com/mcp/_ping

# Expected: HTTP 200 OK
```

**Test Context7 MCP:**
```bash
# Test in Claude Code
"What's new in Next.js 15? use context7"

# Expected: Latest Next.js 15 documentation
```

---

## Performance Benchmarks

### Expected Latencies

| MCP Server | Operation | Expected Latency |
|------------|-----------|------------------|
| Linear | Create issue | 200-500ms |
| Linear | List issues | 100-300ms |
| GitHub | Search code | 500-1000ms |
| GitHub | Create PR | 1000-2000ms |
| Context7 | Fetch docs | 500-1500ms |

### Optimization Tips

**1. Batch Operations**
Group multiple operations into single requests when possible.

**2. Parallel Requests**
Execute independent requests in parallel:
```typescript
// ✅ Parallel
const [teams, projects] = await Promise.all([
  linear_list_teams(),
  linear_list_projects()
]);

// ❌ Sequential
const teams = await linear_list_teams();
const projects = await linear_list_projects();
```

**3. Caching**
Cache frequently accessed data:
- Team IDs
- Workflow states
- User IDs
- Project configurations

---

## Migration Guide

### Upgrading from Local to Remote GitHub MCP

**Before:**
```json
{
  "mcpServers": {
    "github": {
      "command": "mcp-server-github",
      "env": {
        "GITHUB_TOKEN": "ghp_xxxxxxxxxxxxx"
      }
    }
  }
}
```

**After:**
```json
{
  "mcpServers": {
    "github": {
      "command": "github-mcp",
      "args": ["--remote"]
    }
  }
}
```

**Benefits:**
- No token management
- Automatic updates
- OAuth security
- Cross-device access

---

## Additional Resources

- [Linear API Documentation](https://developers.linear.app/docs)
- [GitHub MCP Server Guide](https://github.blog/ai-and-ml/generative-ai/a-practical-guide-on-how-to-use-the-github-mcp-server/)
- [Context7 Documentation](https://upstash.com/blog/context7-mcp)
- [MCP Best Practices](https://modelcontextprotocol.info/docs/best-practices/)
- [Model Context Protocol Spec](https://modelcontextprotocol.io/)

---

## Support

- **Linear Issues:** Contact Linear support or check [status.linear.app](https://status.linear.app)
- **GitHub Issues:** GitHub support or [status.github.com](https://www.githubstatus.com)
- **Context7 Issues:** Email josh@upstash.com or GitHub issues
- **CCPM Issues:** [GitHub Issues](https://github.com/duongdev/ccpm/issues)

---

**Last Updated:** January 2025
