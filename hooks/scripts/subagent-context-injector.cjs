#!/usr/bin/env node
/**
 * SubagentStart Hook - Injects comprehensive CCPM context to all subagents
 *
 * Fires: When any subagent (Task tool) is started
 * Purpose: Give subagents full context to work autonomously
 * Target: Up to 10k tokens for rich context
 *
 * Context Layers (in order of importance):
 * 1. CLAUDE.md files (~3-5k tokens) - Full project instructions
 * 2. Task context (~500 tokens) - Issue, branch, progress, checklist
 * 3. Agent-specific rules (~500 tokens) - Detailed agent guidance
 * 4. Session context (~500 tokens) - Recent decisions, completions
 * 5. Git state (~200 tokens) - Uncommitted files, recent commits
 * 6. Global rules (~200 tokens) - CCPM-wide rules
 *
 * Input (stdin): JSON with { subagent_type, agent_id, cwd, prompt, ... }
 * Output (stdout): JSON with { hookSpecificOutput: { additionalContext } }
 */

const fs = require('fs');
const path = require('path');
const { hookLog } = require('./lib/hook-logger.cjs');

// Token budget per section (approximate)
const TOKEN_BUDGET = {
  claudeMd: 5000,      // Full CLAUDE.md contents
  task: 500,           // Task context
  agentRules: 500,     // Agent-specific rules
  sessionContext: 500, // Recent activity
  gitState: 200,       // Git info
  globalRules: 200,    // CCPM rules
};

/**
 * Agent-specific rules configuration
 * Detailed instructions for each agent type
 */
const AGENT_RULES = {
  'ccpm:frontend-developer': {
    focus: 'Frontend/UI Development',
    description: 'Expert React/UI developer focused on component architecture and user experience',
    rules: [
      'COMPONENT PATTERNS:',
      '  - Check existing components in src/components/ before creating new ones',
      '  - Follow the naming convention used in the project (PascalCase for components)',
      '  - Extract reusable logic into custom hooks in src/hooks/',
      '  - Keep components focused - one responsibility per component',
      '',
      'STYLING:',
      '  - Use the existing design system/Tailwind classes - check tailwind.config.js',
      '  - Follow spacing/color conventions from existing components',
      '  - Ensure responsive design (mobile-first approach)',
      '  - Check for existing utility classes before adding new styles',
      '',
      'ACCESSIBILITY:',
      '  - Add proper aria-labels to interactive elements',
      '  - Ensure keyboard navigation works (focus states, tab order)',
      '  - Use semantic HTML elements (button, nav, main, etc.)',
      '  - Test with screen reader in mind',
      '',
      'STATE MANAGEMENT:',
      '  - Check how state is managed in the project (Context, Redux, Zustand, etc.)',
      '  - Keep state as local as possible, lift only when needed',
      '  - Use the existing patterns for API calls (React Query, SWR, etc.)',
      '',
      'QUALITY:',
      '  - Add PropTypes or TypeScript types for all props',
      '  - Include loading and error states',
      '  - Handle edge cases (empty states, long text, etc.)',
    ]
  },
  'ccpm:backend-architect': {
    focus: 'Backend/API Development',
    description: 'Expert backend developer focused on APIs, databases, and system design',
    rules: [
      'API PATTERNS:',
      '  - Follow existing API patterns in the codebase (REST, GraphQL, etc.)',
      '  - Use consistent error response format',
      '  - Implement proper input validation at boundaries',
      '  - Add appropriate HTTP status codes',
      '',
      'DATABASE:',
      '  - Check existing schema before adding tables/columns',
      '  - Create migrations for schema changes (never modify directly)',
      '  - Add proper indexes for query patterns',
      '  - Use transactions for multi-step operations',
      '',
      'AUTHENTICATION/AUTHORIZATION:',
      '  - Follow existing auth patterns in the project',
      '  - Verify permissions at controller/resolver level',
      '  - Never expose sensitive data in responses',
      '  - Log auth-related events for auditing',
      '',
      'ERROR HANDLING:',
      '  - Use typed error classes for different error types',
      '  - Include actionable error messages',
      '  - Log errors with context for debugging',
      '  - Handle async errors properly (try/catch, .catch())',
      '',
      'PERFORMANCE:',
      '  - Avoid N+1 queries (use includes/joins)',
      '  - Add caching for frequently accessed data',
      '  - Consider pagination for list endpoints',
      '  - Use background jobs for slow operations',
    ]
  },
  'ccpm:debugger': {
    focus: 'Debugging & Troubleshooting',
    description: 'Systematic debugger focused on root cause analysis',
    rules: [
      'INVESTIGATION:',
      '  - Reproduce the issue first - understand exact steps',
      '  - Check error messages and stack traces carefully',
      '  - Look at recent changes (git log, git diff)',
      '  - Check logs (application logs, console, network)',
      '',
      'ROOT CAUSE:',
      '  - Ask "why" multiple times to find root cause',
      '  - Don\'t just fix symptoms - fix the underlying issue',
      '  - Consider if this bug could exist elsewhere',
      '  - Check for similar patterns in codebase',
      '',
      'FIXING:',
      '  - Make minimal changes to fix the issue',
      '  - Add a test that would have caught this bug',
      '  - Verify fix doesn\'t break other functionality',
      '  - Document what caused the issue and how it was fixed',
      '',
      'PREVENTION:',
      '  - Consider adding validation to prevent recurrence',
      '  - Update documentation if needed',
      '  - Add logging for similar issues in the future',
    ]
  },
  'ccpm:code-reviewer': {
    focus: 'Code Review & Quality',
    description: 'Thorough code reviewer focused on quality, security, and maintainability',
    rules: [
      'SECURITY (OWASP Top 10):',
      '  - Check for injection vulnerabilities (SQL, XSS, command)',
      '  - Verify authentication/authorization is properly implemented',
      '  - Look for sensitive data exposure (logs, responses, errors)',
      '  - Check for insecure dependencies',
      '',
      'CODE QUALITY:',
      '  - Verify code follows project conventions',
      '  - Check for code duplication - suggest abstractions',
      '  - Ensure proper error handling',
      '  - Look for potential null/undefined issues',
      '',
      'TESTING:',
      '  - Verify adequate test coverage for changes',
      '  - Check edge cases are covered',
      '  - Ensure tests are meaningful (not just for coverage)',
      '',
      'MAINTAINABILITY:',
      '  - Code should be self-documenting',
      '  - Complex logic should have comments explaining "why"',
      '  - Check for proper typing (TypeScript)',
      '  - Verify changes don\'t increase technical debt',
      '',
      'PERFORMANCE:',
      '  - Look for obvious performance issues',
      '  - Check for memory leaks (event listeners, subscriptions)',
      '  - Verify database queries are efficient',
    ]
  },
  'ccpm:security-auditor': {
    focus: 'Security Assessment',
    description: 'Security expert focused on vulnerability identification and remediation',
    rules: [
      'INJECTION ATTACKS:',
      '  - SQL Injection: Check all database queries use parameterized statements',
      '  - XSS: Verify output encoding and CSP headers',
      '  - Command Injection: Check shell commands use safe APIs',
      '  - Path Traversal: Verify file paths are validated',
      '',
      'AUTHENTICATION:',
      '  - Check password hashing (bcrypt, argon2)',
      '  - Verify session management (secure cookies, token expiry)',
      '  - Look for hardcoded credentials',
      '  - Check for brute force protection',
      '',
      'AUTHORIZATION:',
      '  - Verify access controls at each endpoint',
      '  - Check for IDOR vulnerabilities',
      '  - Ensure principle of least privilege',
      '  - Verify role-based access is consistent',
      '',
      'DATA PROTECTION:',
      '  - Check sensitive data encryption (at rest, in transit)',
      '  - Verify PII handling compliance',
      '  - Look for data leakage in logs/errors',
      '  - Check for proper secrets management',
      '',
      'DEPENDENCIES:',
      '  - Check for known vulnerabilities (npm audit, Snyk)',
      '  - Verify dependency versions are current',
      '  - Look for suspicious or unnecessary dependencies',
    ]
  },
  'ccpm:tdd-orchestrator': {
    focus: 'Test-Driven Development',
    description: 'TDD practitioner ensuring code quality through testing',
    rules: [
      'RED PHASE (Write failing test):',
      '  - Write the smallest test that fails for the right reason',
      '  - Test should clearly describe expected behavior',
      '  - Use descriptive test names (should_doX_when_Y)',
      '  - Consider edge cases upfront',
      '',
      'GREEN PHASE (Make it pass):',
      '  - Write minimal code to make test pass',
      '  - Don\'t over-engineer - just make it work',
      '  - It\'s okay if code is messy at this stage',
      '',
      'REFACTOR PHASE (Clean up):',
      '  - Improve code while keeping tests green',
      '  - Remove duplication',
      '  - Improve naming and structure',
      '  - Extract functions/methods as needed',
      '',
      'TEST QUALITY:',
      '  - Tests should be independent (no shared state)',
      '  - Tests should be fast (mock external dependencies)',
      '  - Tests should be readable (arrange-act-assert)',
      '  - Cover happy path, edge cases, and error cases',
    ]
  },
  'ccpm:linear-operations': {
    focus: 'Linear API Operations',
    description: 'Linear MCP specialist for issue tracking operations',
    rules: [
      'PARAMETER NAMES (CRITICAL):',
      '  - get_issue uses "id" NOT "issueId"',
      '  - update_issue uses "id" NOT "issueId"',
      '  - create_comment uses "issueId"',
      '  - list_comments uses "issueId"',
      '',
      'CACHING:',
      '  - Teams, labels, statuses rarely change - cache aggressively',
      '  - Issue data changes often - use shorter TTL',
      '  - Cache hit rate target: 85-95%',
      '',
      'BATCHING:',
      '  - Batch multiple updates into single calls when possible',
      '  - Use bulk operations for multiple issues',
      '',
      'ERROR HANDLING:',
      '  - Retry on rate limits with exponential backoff',
      '  - Provide actionable error messages',
      '  - Log failed operations for debugging',
    ]
  },
  'Explore': {
    focus: 'Codebase Exploration',
    description: 'Fast codebase navigator for finding files and understanding structure',
    rules: [
      'SEARCH STRATEGY:',
      '  - Use Glob for file patterns (e.g., "**/*.tsx")',
      '  - Use Grep for content search (e.g., function names)',
      '  - Start broad, then narrow down',
      '',
      'EFFICIENCY:',
      '  - Read file headers/exports first before full content',
      '  - Note file locations for the main agent',
      '  - Summarize findings concisely',
      '',
      'REPORTING:',
      '  - List relevant files with brief descriptions',
      '  - Note patterns and conventions observed',
      '  - Highlight important findings first',
    ]
  },
  'Plan': {
    focus: 'Task Planning',
    description: 'Strategic planner for breaking down complex tasks',
    rules: [
      'ANALYSIS:',
      '  - Understand the full scope before planning',
      '  - Identify dependencies between tasks',
      '  - Note potential blockers upfront',
      '',
      'TASK BREAKDOWN:',
      '  - Create specific, actionable steps',
      '  - Each step should be completable independently',
      '  - Order by dependencies (critical path first)',
      '',
      'ESTIMATION:',
      '  - Don\'t provide time estimates',
      '  - Focus on complexity and dependencies',
      '  - Note which tasks can be parallelized',
    ]
  },
  'default': {
    focus: 'General Purpose',
    description: 'Flexible agent for various tasks',
    rules: [
      'Follow existing patterns in the codebase',
      'Be concise in responses',
      'Ask for clarification if requirements are unclear',
      'Document any assumptions made',
    ]
  }
};

/**
 * Read session state from /tmp/ccpm-session-*.json
 */
function readSessionState() {
  try {
    const tmpDir = '/tmp';
    const files = fs.readdirSync(tmpDir);
    const sessionFiles = files
      .filter(f => f.startsWith('ccpm-session-') && f.endsWith('.json'))
      .map(f => ({
        name: f,
        path: path.join(tmpDir, f),
        mtime: fs.statSync(path.join(tmpDir, f)).mtime
      }))
      .sort((a, b) => b.mtime - a.mtime);

    if (sessionFiles.length === 0) return null;

    const content = fs.readFileSync(sessionFiles[0].path, 'utf8');
    return JSON.parse(content);
  } catch (err) {
    return null;
  }
}

/**
 * Read environment variables for CCPM context
 */
function readEnvironment() {
  return {
    issueId: process.env.CCPM_ACTIVE_ISSUE || null,
    projectName: process.env.CCPM_ACTIVE_PROJECT || null,
    contextLogFile: process.env.CCPM_CONTEXT_LOG || null
  };
}

/**
 * Read full CLAUDE.md file contents (up to token limit)
 */
function readClaudeMdFiles(files, maxChars = 15000) {
  const contents = [];
  let totalChars = 0;

  for (const file of files || []) {
    if (totalChars >= maxChars) break;

    try {
      const content = fs.readFileSync(file, 'utf8');
      const relativePath = path.relative(process.cwd(), file) || file;

      // Calculate remaining budget
      const remaining = maxChars - totalChars;
      const truncated = content.length > remaining
        ? content.substring(0, remaining) + '\n\n[... truncated for length ...]'
        : content;

      contents.push({
        path: relativePath,
        content: truncated
      });

      totalChars += truncated.length;
    } catch (e) {
      // Skip unreadable files
    }
  }

  return contents;
}

/**
 * Read recent context from log file
 */
function readContextLog(logFile, limit = 20) {
  if (!logFile) return [];

  try {
    if (!fs.existsSync(logFile)) return [];

    const content = fs.readFileSync(logFile, 'utf8');
    const lines = content.split('\n')
      .filter(line => line.trim() && !line.startsWith('#'))
      .slice(-limit);

    return lines;
  } catch (err) {
    return [];
  }
}

/**
 * Get agent-specific rules
 */
function getAgentRules(agentType) {
  const normalized = agentType?.toLowerCase() || 'default';

  for (const [key, value] of Object.entries(AGENT_RULES)) {
    if (normalized.includes(key.toLowerCase().replace('ccpm:', ''))) {
      return value;
    }
  }

  return AGENT_RULES.default;
}

/**
 * Build comprehensive context string
 */
function buildContext(input, sessionState, envVars) {
  const issueId = sessionState?.issueId || envVars.issueId || null;
  const projectName = sessionState?.project?.name || envVars.projectName || 'default';
  const gitBranch = sessionState?.gitBranch || null;
  const gitState = sessionState?.gitState || {};
  const claudeMdFiles = sessionState?.claudeMdFiles || [];
  const contextLogFile = sessionState?.contextLogFile || envVars.contextLogFile;
  const agentType = input?.subagent_type || input?.agent_type || 'default';
  const cwd = input?.cwd || sessionState?.cwd || process.cwd();
  const taskPrompt = input?.prompt || '';

  // Get agent-specific rules
  const agentRules = getAgentRules(agentType);

  // Read full CLAUDE.md contents
  const claudeMdContents = readClaudeMdFiles(claudeMdFiles);

  // Read recent context
  const recentContext = readContextLog(contextLogFile);

  // Build context string
  let context = '';

  // ============================================================
  // SECTION 1: CLAUDE.md Files (Project Instructions) - HIGHEST PRIORITY
  // ============================================================
  if (claudeMdContents.length > 0) {
    context += '# 📋 PROJECT INSTRUCTIONS (CLAUDE.md)\n\n';
    context += '> **IMPORTANT:** These are the project-specific instructions you MUST follow.\n';
    context += '> They override any default behavior.\n\n';

    for (const file of claudeMdContents) {
      context += `## 📁 ${file.path}\n\n`;
      context += file.content;
      context += '\n\n---\n\n';
    }
  }

  // ============================================================
  // SECTION 2: Task Context
  // ============================================================
  context += '# 🎯 CURRENT TASK CONTEXT\n\n';

  if (issueId) {
    context += `**Active Issue:** ${issueId}\n`;
  }
  if (gitBranch) {
    context += `**Git Branch:** ${gitBranch}\n`;
  }
  context += `**Project:** ${projectName}\n`;
  context += `**Working Directory:** ${cwd}\n`;

  if (gitState.uncommitted?.length > 0) {
    context += `\n**Uncommitted Files (${gitState.uncommitted.length}):**\n`;
    for (const file of gitState.uncommitted.slice(0, 10)) {
      context += `  - ${file}\n`;
    }
    if (gitState.uncommitted.length > 10) {
      context += `  - ... and ${gitState.uncommitted.length - 10} more\n`;
    }
  }

  if (gitState.lastCommit) {
    context += `\n**Last Commit:** ${gitState.lastCommit.hash} - "${gitState.lastCommit.message}" (${gitState.lastCommit.time})\n`;
  }

  context += '\n';

  // ============================================================
  // SECTION 3: Agent-Specific Rules
  // ============================================================
  context += `# 🤖 AGENT INSTRUCTIONS (${agentRules.focus})\n\n`;
  context += `> ${agentRules.description}\n\n`;

  for (const rule of agentRules.rules) {
    if (rule === '') {
      context += '\n';
    } else {
      context += `${rule}\n`;
    }
  }
  context += '\n';

  // ============================================================
  // SECTION 4: Recent Session Activity
  // ============================================================
  if (recentContext.length > 0) {
    context += '# 📝 RECENT SESSION ACTIVITY\n\n';
    context += '> These are recent actions in this session. Use for context.\n\n';
    for (const line of recentContext) {
      context += `- ${line}\n`;
    }
    context += '\n';
  }

  // ============================================================
  // SECTION 5: Global CCPM Rules
  // ============================================================
  context += '# ⚠️ GLOBAL RULES (MANDATORY)\n\n';
  context += '**Linear Operations:**\n';
  context += '- Use `ccpm:linear-operations` agent for ALL Linear API calls\n';
  context += '- NEVER make direct Linear MCP calls\n';
  context += '- Parameter names: get_issue uses `id`, create_comment uses `issueId`\n\n';

  context += '**Git Operations:**\n';
  context += '- NEVER auto-commit or auto-push without explicit user approval\n';
  context += '- Always show what will be committed before committing\n\n';

  context += '**Progress Tracking:**\n';
  context += '- Update Linear issue comments for progress (not local files)\n';
  context += '- Keep responses concise\n';
  context += '- List unresolved questions at the end of your response\n\n';

  context += '**Code Quality:**\n';
  context += '- Follow existing patterns in the codebase\n';
  context += '- Don\'t over-engineer - make minimal changes needed\n';
  context += '- Check for security issues (injection, XSS, etc.)\n';

  return context;
}

/**
 * Main function
 */
function main() {
  try {
    let inputData = '';
    const stdin = process.stdin;

    stdin.on('data', chunk => {
      inputData += chunk;
    });

    stdin.on('end', () => {
      let input = {};

      if (inputData.trim()) {
        try {
          input = JSON.parse(inputData);
        } catch (err) {
          input = {};
        }
      }

      const sessionState = readSessionState();
      const envVars = readEnvironment();
      const contextString = buildContext(input, sessionState, envVars);

      const output = {
        hookSpecificOutput: {
          hookEventName: 'SubagentStart',
          additionalContext: contextString
        }
      };

      console.log(JSON.stringify(output));

      // Log hook completion
      const agentType = input?.subagent_type || input?.agent_type || 'unknown';
      const tokenEstimate = (contextString.length / 4 / 1000).toFixed(1); // ~4 chars per token, convert to k
      const claudeMdCount = sessionState?.claudeMdFiles?.length || 0;
      hookLog('subagent-context-injector', `✓ Injected ~${tokenEstimate}k tokens to ${agentType} | CLAUDE.md: ${claudeMdCount}`);

      process.exit(0);
    });

    stdin.on('error', () => {
      const fallbackContext = `# CCPM Context

**Project:** default

## Global Rules
- Linear: Use ccpm:linear-operations agent (NEVER direct MCP)
- Git: NEVER auto-commit/push without user approval
- Progress: Update Linear issue, not local files
- Style: Be concise, list unresolved questions at end
`;
      const output = {
        hookSpecificOutput: {
          hookEventName: 'SubagentStart',
          additionalContext: fallbackContext
        }
      };
      console.log(JSON.stringify(output));
      process.exit(0);
    });

  } catch (err) {
    const fallbackContext = `# CCPM Context

**Project:** default

## Global Rules
- Linear: Use ccpm:linear-operations agent (NEVER direct MCP)
- Git: NEVER auto-commit/push without user approval
- Progress: Update Linear issue, not local files
- Style: Be concise, list unresolved questions at end
`;
    const output = {
      hookSpecificOutput: {
        hookEventName: 'SubagentStart',
        additionalContext: fallbackContext
      }
    };
    console.log(JSON.stringify(output));
    process.exit(0);
  }
}

main();
