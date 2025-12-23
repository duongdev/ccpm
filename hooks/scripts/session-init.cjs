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
 *
 * Session State Schema:
 * {
 *   sessionId: string,
 *   source: "startup" | "resume" | "clear" | "compact",
 *   issueId: string | null,  // From git branch (e.g., WORK-26)
 *   project: { name: string, source: "git" | "directory" },
 *   gitBranch: string | null,
 *   cwd: string,
 *   timestamp: number
 * }
 *
 * Environment Variables Exported:
 * - CCPM_SESSION_ID - Session identifier
 * - CCPM_ACTIVE_ISSUE - Detected Linear issue (e.g., WORK-26)
 * - CCPM_ACTIVE_PROJECT - Project name
 * - CCPM_GIT_BRANCH - Current git branch
 * - CCPM_SESSION_FILE - Path to session state file
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

/**
 * Safely execute shell command, returning null on error
 * @param {string} cmd - Command to execute
 * @returns {string|null} Command output or null
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
 * Supports patterns: WORK-123, PSN-456, RPT-789, etc.
 * @returns {string|null} Issue ID or null
 */
function detectIssueFromBranch() {
  const branch = execSafe('git branch --show-current');
  if (!branch) return null;

  // Match patterns: WORK-123, PSN-456, RPT-789
  const match = branch.match(/([A-Z]+-\d+)/i);
  return match ? match[1].toUpperCase() : null;
}

/**
 * Detect project name from git remote or directory
 * @returns {object} { name: string, source: "git" | "directory" }
 */
function detectProject() {
  const remote = execSafe('git config --get remote.origin.url');
  if (!remote) return { name: path.basename(process.cwd()), source: 'directory' };

  // Extract repo name from remote URL
  // Matches: git@github.com:user/repo.git or https://github.com/user/repo
  const repoMatch = remote.match(/\/([^\/]+?)(\.git)?$/);
  return { name: repoMatch ? repoMatch[1] : 'unknown', source: 'git' };
}

async function main() {
  try {
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

    // Build session state
    const sessionState = {
      sessionId,
      source,
      issueId,
      project,
      gitBranch,
      cwd: process.cwd(),
      timestamp: Date.now()
    };

    // Persist to temp file
    const sessionFile = `/tmp/ccpm-session-${sessionId}.json`;
    fs.writeFileSync(sessionFile, JSON.stringify(sessionState, null, 2));

    // Export env vars for other hooks (if env file available)
    if (envFile) {
      const envContent = [
        `CCPM_SESSION_ID=${sessionId}`,
        `CCPM_ACTIVE_ISSUE=${issueId || ''}`,
        `CCPM_ACTIVE_PROJECT=${project.name}`,
        `CCPM_GIT_BRANCH=${gitBranch || ''}`,
        `CCPM_SESSION_FILE=${sessionFile}`
      ].join('\n') + '\n';

      fs.appendFileSync(envFile, envContent);
    }

    // Output session info (visible to user)
    const lines = [
      `Session ${source}`,
      `Project: ${project.name}`,
      issueId ? `Issue: ${issueId}` : null,
      gitBranch ? `Branch: ${gitBranch}` : null
    ].filter(Boolean);

    console.log(lines.join(' | '));
    process.exit(0);
  } catch (error) {
    // Fail-open: Don't block session start on errors
    console.error(`SessionStart error: ${error.message}`);
    process.exit(0);
  }
}

main();
