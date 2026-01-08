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
 * Check if claude-mem plugin is available
 */
function isClaudeMemAvailable() {
  const homeDir = process.env.HOME || '/tmp';
  const pluginPaths = [
    path.join(homeDir, '.claude/plugins/claude-mem'),
    path.join(homeDir, '.claude-mem'),
  ];

  for (const pluginPath of pluginPaths) {
    if (fs.existsSync(pluginPath)) {
      return true;
    }
  }

  return false;
}

/**
 * Analyze git commit patterns for consistency
 * Returns detected patterns from recent commits
 */
function analyzeCommitPatterns(limit = 30) {
  const patterns = {
    format: 'unknown',
    usesScope: false,
    confidence: 0,
    topTypes: [],
    topScopes: []
  };

  const commits = execSafe(`git log --oneline -${limit} --format="%s"`);
  if (!commits) return patterns;

  const lines = commits.split('\n').filter(l => l.trim());
  if (lines.length === 0) return patterns;

  const conventionalRegex = /^(\w+)(?:\(([^)]+)\))?!?:\s*(.+)$/;
  let conventionalCount = 0;
  const types = {};
  const scopes = {};

  for (const line of lines) {
    const match = line.match(conventionalRegex);
    if (match) {
      conventionalCount++;
      const [, type, scope] = match;
      types[type] = (types[type] || 0) + 1;
      if (scope) {
        scopes[scope] = (scopes[scope] || 0) + 1;
      }
    }
  }

  const total = lines.length;
  const ratio = conventionalCount / total;

  if (ratio >= 0.5) {
    patterns.format = 'conventional';
    patterns.confidence = Math.round(ratio * 100);
    patterns.usesScope = Object.keys(scopes).length > total * 0.2;
    patterns.topTypes = Object.entries(types)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([t]) => t);
    patterns.topScopes = Object.entries(scopes)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([s]) => s);
  } else {
    patterns.format = 'simple';
    patterns.confidence = 60;
  }

  return patterns;
}

/**
 * Discover ALL CLAUDE.md files in the hierarchy from global to current directory
 *
 * Order (most general to most specific):
 * 1. ~/.claude/CLAUDE.md (global user instructions)
 * 2. ~/CLAUDE.md (home directory)
 * 3. ~/parent/CLAUDE.md (each parent directory)
 * 4. ~/parent/project/CLAUDE.md (current project)
 * 5. Nested CLAUDE.md within project (monorepo subprojects)
 *
 * Example for cwd=/Users/duongdev/repeat/repeat-web:
 *   ~/.claude/CLAUDE.md -> ~/CLAUDE.md -> ~/repeat/CLAUDE.md -> ~/repeat/repeat-web/CLAUDE.md
 */
function discoverClaudeMdFiles() {
  const claudeFiles = [];
  const seen = new Set();
  const cwd = process.cwd();
  const homeDir = process.env.HOME || '/tmp';

  // Helper to add file if exists and not seen
  const addIfExists = (filePath) => {
    if (seen.has(filePath)) return;
    seen.add(filePath);
    if (fs.existsSync(filePath)) {
      claudeFiles.push(filePath);
    }
  };

  // 1. Global CLAUDE.md first (user's global instructions)
  addIfExists(path.join(homeDir, '.claude', 'CLAUDE.md'));

  // 2. Walk from HOME to CWD, collecting CLAUDE.md at each level
  // This ensures we get: ~/CLAUDE.md -> ~/repeat/CLAUDE.md -> ~/repeat/repeat-web/CLAUDE.md
  if (cwd.startsWith(homeDir)) {
    const relativePath = cwd.slice(homeDir.length);
    const parts = relativePath.split(path.sep).filter(p => p);

    let currentPath = homeDir;
    addIfExists(path.join(currentPath, 'CLAUDE.md')); // ~/CLAUDE.md

    for (const part of parts) {
      currentPath = path.join(currentPath, part);
      addIfExists(path.join(currentPath, 'CLAUDE.md'));
      // Also check .claude subdirectory at each level
      addIfExists(path.join(currentPath, '.claude', 'CLAUDE.md'));
    }
  }

  // 3. Find git root for nested file discovery
  const gitRoot = execSafe('git rev-parse --show-toplevel');
  const searchRoot = gitRoot || cwd;

  // 4. Search monorepo patterns for nested CLAUDE.md files
  const monorepoPatterns = ['apps', 'packages', 'libs', 'services', 'modules'];
  for (const pattern of monorepoPatterns) {
    const dir = path.join(searchRoot, pattern);
    if (fs.existsSync(dir)) {
      try {
        const subdirs = fs.readdirSync(dir, { withFileTypes: true })
          .filter(d => d.isDirectory())
          .map(d => path.join(dir, d.name));
        for (const subdir of subdirs) {
          addIfExists(path.join(subdir, 'CLAUDE.md'));
        }
      } catch (e) {
        // Skip unreadable directories
      }
    }
  }

  // 5. Do a find for any other CLAUDE.md files we might have missed
  // (maxdepth 6 covers deep monorepo structures)
  const findResult = execSafe(`find "${searchRoot}" -maxdepth 6 -name "CLAUDE.md" -type f 2>/dev/null | head -30`);
  if (findResult) {
    for (const file of findResult.split('\n').filter(f => f.trim())) {
      addIfExists(file);
    }
  }

  // Files are already in correct order (global -> parent -> project -> nested)
  // because we added them in that order. Just limit to prevent token overflow.
  return claudeFiles.slice(0, 30);
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
    const claudeMemAvailable = isClaudeMemAvailable();
    const commitPatterns = analyzeCommitPatterns(30);

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
      claudeMemAvailable,
      commitPatterns,
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
    if (gitState.lastCommit) {
      gitSummary = ` | **Last commit:** "${gitState.lastCommit.message}" (${gitState.lastCommit.time})`;
    }

    // Build CLAUDE.md summary for output
    let claudeSummary = '';
    if (claudeMdFiles.length > 0) {
      claudeSummary = `\n**CLAUDE.md files:** ${claudeMdFiles.length} found`;
    }

    // Build integrations summary
    let integrationsSummary = '';
    if (claudeMemAvailable) {
      integrationsSummary += ' | claude-mem: ✓';
    }
    if (commitPatterns.format === 'conventional' && commitPatterns.confidence >= 70) {
      integrationsSummary += ` | Commits: ${commitPatterns.format} (${commitPatterns.confidence}%)`;
    }

    // Output CCPM context injection
    const output = `## CCPM Session Initialized

**Project:** ${project.name} | **Issue:** ${issueId || 'none'} | **Branch:** ${gitBranch || 'none'}${gitSummary}${claudeSummary}${integrationsSummary}

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
    const memStatus = claudeMemAvailable ? 'mem✓' : 'mem✗';
    hookLog('session-init', `✓ Project: ${project.name} | Branch: ${gitBranch || 'none'} | Issue: ${issueId || 'none'} | CLAUDE.md: ${claudeMdCount} | Uncommitted: ${uncommittedCount} | ${memStatus}`);

    process.exit(0);
  } catch (error) {
    hookLog('session-init', `✗ Error: ${error.message}`);
    process.exit(0);
  }
}

main();
