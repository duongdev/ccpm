#!/usr/bin/env node
/**
 * SessionStart Hook - Initializes CCPM session state
 *
 * Fires: Once per session (startup, resume, clear, compact)
 * Purpose: Detect project, cache state, export env vars
 *
 * Benefits:
 * - Detects project/issue context once instead of on every command
 * - Persists to /tmp for hooks to read
 * - Exports env vars for shell scripts
 * - Reduces token waste from repeated detection
 * - Discovers CLAUDE.md files for subagent context
 *
 * Session State Schema:
 * {
 *   sessionId: string,
 *   source: "startup" | "resume" | "clear" | "compact",
 *   issueId: string | null,
 *   project: { name: string, source: "git" | "directory" },
 *   gitBranch: string | null,
 *   gitState: { uncommitted: string[], lastCommit: { hash, message, time } },
 *   claudeMdFiles: string[],  // Paths to all CLAUDE.md files
 *   cwd: string,
 *   timestamp: number
 * }
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { hookLog, clearHookLog } = require('./lib/hook-logger.cjs');

/**
 * Safely execute shell command, returning null on error
 */
function execSafe(cmd) {
  try {
    return execSync(cmd, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
  } catch (e) {
    return null;
  }
}

/**
 * Detect Linear issue ID from git branch name
 */
function detectIssueFromBranch() {
  const branch = execSafe('git branch --show-current');
  if (!branch) return null;

  const match = branch.match(/([A-Z]+-\d+)/i);
  return match ? match[1].toUpperCase() : null;
}

/**
 * Detect project name from git remote or directory
 */
function detectProject() {
  const remote = execSafe('git config --get remote.origin.url');
  if (!remote) return { name: path.basename(process.cwd()), source: 'directory' };

  const repoMatch = remote.match(/\/([^\/]+?)(\.git)?$/);
  return { name: repoMatch ? repoMatch[1] : 'unknown', source: 'git' };
}

/**
 * Get git state: uncommitted files and last commit
 */
function getGitState() {
  const state = {
    uncommitted: [],
    lastCommit: null
  };

  // Get uncommitted/changed files
  const status = execSafe('git status --porcelain');
  if (status) {
    state.uncommitted = status.split('\n')
      .filter(line => line.trim())
      .map(line => line.substring(3).trim())
      .slice(0, 10); // Limit to 10 files
  }

  // Get last commit info
  const lastCommit = execSafe('git log -1 --format="%h|%s|%cr"');
  if (lastCommit) {
    const [hash, message, time] = lastCommit.split('|');
    state.lastCommit = { hash, message: message?.substring(0, 50), time };
  }

  return state;
}

/**
 * Discover all CLAUDE.md files in project hierarchy
 * Searches from cwd up to git root, plus common subdirectories
 */
function discoverClaudeMdFiles() {
  const claudeFiles = [];
  const cwd = process.cwd();

  // Find git root
  const gitRoot = execSafe('git rev-parse --show-toplevel');
  const searchRoot = gitRoot || cwd;

  // Search patterns for CLAUDE.md files
  const searchDirs = [
    searchRoot,                          // Project root
    path.join(searchRoot, '.claude'),    // .claude directory
  ];

  // Add common monorepo patterns
  const monorepoPatterns = ['apps', 'packages', 'libs', 'services'];
  for (const pattern of monorepoPatterns) {
    const dir = path.join(searchRoot, pattern);
    if (fs.existsSync(dir)) {
      try {
        const subdirs = fs.readdirSync(dir, { withFileTypes: true })
          .filter(d => d.isDirectory())
          .map(d => path.join(dir, d.name));
        searchDirs.push(...subdirs);
      } catch (e) {
        // Skip unreadable directories
      }
    }
  }

  // Also check current directory if different from git root
  if (cwd !== searchRoot) {
    searchDirs.push(cwd);
    // Check parent directories up to git root
    let current = cwd;
    while (current !== searchRoot && current !== path.dirname(current)) {
      searchDirs.push(current);
      current = path.dirname(current);
    }
  }

  // Search for CLAUDE.md in each directory
  const seen = new Set();
  for (const dir of searchDirs) {
    if (!fs.existsSync(dir) || seen.has(dir)) continue;
    seen.add(dir);

    const claudeMd = path.join(dir, 'CLAUDE.md');
    if (fs.existsSync(claudeMd)) {
      claudeFiles.push(claudeMd);
    }
  }

  // Also do a quick find for any CLAUDE.md files (limit depth for performance)
  const findResult = execSafe(`find "${searchRoot}" -maxdepth 4 -name "CLAUDE.md" -type f 2>/dev/null | head -20`);
  if (findResult) {
    for (const file of findResult.split('\n').filter(f => f.trim())) {
      if (!claudeFiles.includes(file)) {
        claudeFiles.push(file);
      }
    }
  }

  // Sort by path depth (shallowest first = most important)
  claudeFiles.sort((a, b) => a.split('/').length - b.split('/').length);

  return claudeFiles.slice(0, 10); // Limit to 10 files
}

/**
 * Extract key instructions from CLAUDE.md files
 * Returns a summary of each file (first ~500 chars of important sections)
 */
function summarizeClaudeMdFiles(files) {
  const summaries = [];

  for (const file of files.slice(0, 5)) { // Limit to 5 files for token efficiency
    try {
      const content = fs.readFileSync(file, 'utf8');
      const relativePath = path.relative(process.cwd(), file) || file;

      // Extract key sections
      const lines = content.split('\n');
      const keyLines = [];
      let inImportantSection = false;

      for (const line of lines) {
        // Track important sections
        if (line.match(/^#+\s*(critical|important|must|never|always|rule|convention)/i)) {
          inImportantSection = true;
        } else if (line.match(/^#+\s/)) {
          inImportantSection = false;
        }

        // Capture critical keywords
        if (line.match(/\b(NEVER|ALWAYS|MUST|CRITICAL|IMPORTANT|DO NOT|REQUIRED)\b/i) ||
            inImportantSection) {
          keyLines.push(line.trim());
        }

        // Stop if we have enough
        if (keyLines.length >= 15) break;
      }

      if (keyLines.length > 0) {
        summaries.push({
          path: relativePath,
          rules: keyLines.slice(0, 10).join('\n')
        });
      }
    } catch (e) {
      // Skip unreadable files
    }
  }

  return summaries;
}

/**
 * Initialize context log file for the session
 */
function initContextLog(sessionId, issueId) {
  const logFile = `/tmp/ccpm-context-${issueId || sessionId}.log`;

  // Create or clear the log file
  if (!fs.existsSync(logFile)) {
    fs.writeFileSync(logFile, `# CCPM Context Log - ${new Date().toISOString()}\n`);
  }

  return logFile;
}

async function main() {
  try {
    // Clear hook log at session start
    clearHookLog();

    // Read hook input from stdin
    const stdin = fs.readFileSync(0, 'utf-8').trim();
    const data = stdin ? JSON.parse(stdin) : {};
    const envFile = process.env.CLAUDE_ENV_FILE;
    const sessionId = data.session_id || `ccpm-${Date.now()}`;
    const source = data.source || 'unknown';

    // Detect context
    const issueId = detectIssueFromBranch();
    const project = detectProject();
    const gitBranch = execSafe('git branch --show-current');
    const gitState = getGitState();
    const claudeMdFiles = discoverClaudeMdFiles();
    const claudeMdSummaries = summarizeClaudeMdFiles(claudeMdFiles);

    // Initialize context log
    const contextLogFile = initContextLog(sessionId, issueId);

    // Build session state
    const sessionState = {
      sessionId,
      source,
      issueId,
      project,
      gitBranch,
      gitState,
      claudeMdFiles,
      claudeMdSummaries,
      contextLogFile,
      cwd: process.cwd(),
      timestamp: Date.now()
    };

    // Persist to temp file
    const sessionFile = `/tmp/ccpm-session-${sessionId}.json`;
    fs.writeFileSync(sessionFile, JSON.stringify(sessionState, null, 2));

    // Export env vars for other hooks
    if (envFile) {
      const envContent = [
        `CCPM_SESSION_ID=${sessionId}`,
        `CCPM_ACTIVE_ISSUE=${issueId || ''}`,
        `CCPM_ACTIVE_PROJECT=${project.name}`,
        `CCPM_GIT_BRANCH=${gitBranch || ''}`,
        `CCPM_SESSION_FILE=${sessionFile}`,
        `CCPM_CONTEXT_LOG=${contextLogFile}`
      ].join('\n') + '\n';

      fs.appendFileSync(envFile, envContent);
    }

    // Discover available agents
    const pluginRoot = path.resolve(__dirname, '../..');
    const discoverScript = path.join(pluginRoot, 'scripts/discover-agents-cached.sh');
    let agents = [];
    let agentCount = 0;

    try {
      const agentsJson = execSafe(`"${discoverScript}"`);
      if (agentsJson) {
        agents = JSON.parse(agentsJson);
        agentCount = agents.length;
      }
    } catch (e) {
      agents = [
        { name: 'general-purpose', type: 'global', description: 'General-purpose agent' },
        { name: 'Explore', type: 'global', description: 'Codebase exploration' },
        { name: 'Plan', type: 'global', description: 'Task planning' }
      ];
      agentCount = 3;
    }

    const agentNames = agents.map(a => a.name);

    // Build git state summary
    let gitSummary = '';
    if (gitState.uncommitted.length > 0) {
      gitSummary = `\n**Uncommitted:** ${gitState.uncommitted.length} files`;
    }
    if (gitState.lastCommit) {
      gitSummary += ` | **Last commit:** "${gitState.lastCommit.message}" (${gitState.lastCommit.time})`;
    }

    // Build CLAUDE.md summary for output
    let claudeSummary = '';
    if (claudeMdFiles.length > 0) {
      claudeSummary = `\n**CLAUDE.md files:** ${claudeMdFiles.length} found`;
    }

    // Output CCPM context injection
    const output = `## CCPM Session Initialized

**Project:** ${project.name} | **Issue:** ${issueId || 'none'} | **Branch:** ${gitBranch || 'none'}${gitSummary}${claudeSummary}

### Available Agents (${agentCount})
${agentNames.join(', ')}

### 🔴 Agent Invocation Rules (MANDATORY)

| Task Type | Agent | Triggers |
|-----------|-------|----------|
| Linear ops | \`ccpm:linear-operations\` | issue, linear, status, sync, checklist, WORK-, PSN- |
| Frontend | \`ccpm:frontend-developer\` | component, UI, React, CSS, layout |
| Backend | \`ccpm:backend-architect\` | API, endpoint, database, resolver |
| Debug | \`ccpm:debugger\` | bug, error, fix, broken, not working |
| Review | \`ccpm:code-reviewer\` | review, check code, quality |
| Security | \`ccpm:security-auditor\` | security, vulnerability, OWASP |
| TDD | \`ccpm:tdd-orchestrator\` | TDD, test first, write tests |
| Explore | \`Explore\` | find, search, where is, how does |

**⛔ NEVER make direct Linear MCP calls** - use \`ccpm:linear-operations\` agent

### 🔵 CCPM Commands (use Skill tool)

**Workflow:** \`/ccpm:plan\`, \`/ccpm:work\`, \`/ccpm:sync\`, \`/ccpm:commit\`, \`/ccpm:verify\`, \`/ccpm:done\`
**Utility:** \`/ccpm:search\`, \`/ccpm:branch\`, \`/ccpm:review\`, \`/ccpm:rollback\`

### Invocation Pattern
\`\`\`
Task(subagent_type="ccpm:<agent>", prompt="<details>")
Skill(skill="ccpm:<command>", args="<args>")
\`\`\`
`;

    console.log(output);

    // Log hook completion
    const claudeMdCount = claudeMdFiles.length;
    const uncommittedCount = gitState.uncommitted?.length || 0;
    hookLog('session-init', `✓ Project: ${project.name} | Branch: ${gitBranch || 'none'} | Issue: ${issueId || 'none'} | CLAUDE.md: ${claudeMdCount} | Uncommitted: ${uncommittedCount}`);

    process.exit(0);
  } catch (error) {
    hookLog('session-init', `✗ Error: ${error.message}`);
    process.exit(0);
  }
}

main();
