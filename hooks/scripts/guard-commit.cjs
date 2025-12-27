#!/usr/bin/env node
/**
 * Guard Commit Hook - Prevent Work Loss on Session End
 *
 * Inspired by CCharness (https://github.com/elct9620/ccharness)
 *
 * Purpose: Ensures uncommitted work is not lost when:
 * - Session ends (user exits)
 * - Claude gets throttled
 * - Context window fills up
 *
 * Fires: Stop hook (when Claude stops responding)
 *
 * Behavior:
 * - Checks for uncommitted changes
 * - If changes exceed thresholds, outputs reminder/warning
 * - Optionally suggests auto-commit
 *
 * Configuration (via env vars):
 * - CCPM_GUARD_COMMIT_MAX_FILES: Trigger if more than N files changed (default: 5)
 * - CCPM_GUARD_COMMIT_MAX_LINES: Trigger if more than N lines changed (default: 100)
 * - CCPM_GUARD_COMMIT_AUTO: If "true", suggest auto-commit (default: false)
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Import shared logger
let hookLog;
try {
  const logger = require('./lib/hook-logger.cjs');
  hookLog = logger.hookLog;
} catch (e) {
  // Fallback if logger not available
  hookLog = (name, msg) => console.error(`[${name}] ${msg}`);
}

// Configuration
const CONFIG = {
  maxFiles: parseInt(process.env.CCPM_GUARD_COMMIT_MAX_FILES || '5', 10),
  maxLines: parseInt(process.env.CCPM_GUARD_COMMIT_MAX_LINES || '100', 10),
  autoCommit: process.env.CCPM_GUARD_COMMIT_AUTO === 'true'
};

/**
 * Execute command safely
 */
function execSafe(cmd) {
  try {
    return execSync(cmd, { encoding: 'utf8', timeout: 5000 }).trim();
  } catch (e) {
    return null;
  }
}

/**
 * Check if we're in a git repository
 */
function isGitRepo() {
  return execSafe('git rev-parse --is-inside-work-tree') === 'true';
}

/**
 * Get uncommitted files
 */
function getUncommittedFiles() {
  const output = execSafe('git status --porcelain');
  if (!output) return [];

  return output.split('\n')
    .filter(line => line.trim())
    .map(line => ({
      status: line.substring(0, 2).trim(),
      file: line.substring(3).trim()
    }));
}

/**
 * Get changed lines count
 */
function getChangedLinesCount() {
  // Staged changes
  const stagedStats = execSafe('git diff --cached --stat | tail -1');
  // Unstaged changes
  const unstagedStats = execSafe('git diff --stat | tail -1');

  let totalLines = 0;

  // Parse "X files changed, Y insertions(+), Z deletions(-)"
  const parseStats = (stats) => {
    if (!stats) return 0;
    const insertions = stats.match(/(\d+) insertion/)?.[1] || 0;
    const deletions = stats.match(/(\d+) deletion/)?.[1] || 0;
    return parseInt(insertions, 10) + parseInt(deletions, 10);
  };

  totalLines += parseStats(stagedStats);
  totalLines += parseStats(unstagedStats);

  return totalLines;
}

/**
 * Get current branch name
 */
function getCurrentBranch() {
  return execSafe('git rev-parse --abbrev-ref HEAD') || 'unknown';
}

/**
 * Get issue ID from branch name
 */
function getIssueFromBranch(branch) {
  const match = branch.match(/([A-Z]+-\d+)/);
  return match ? match[1] : null;
}

/**
 * Generate commit message suggestion
 */
function suggestCommitMessage(files, issueId) {
  // Determine type based on files
  const hasTests = files.some(f => f.file.includes('test') || f.file.includes('spec'));
  const hasDocs = files.some(f => f.file.endsWith('.md'));
  const hasConfig = files.some(f =>
    f.file.includes('config') ||
    f.file.endsWith('.json') ||
    f.file.endsWith('.yaml')
  );

  let type = 'wip';
  if (hasTests && files.length <= 3) type = 'test';
  else if (hasDocs && files.length <= 3) type = 'docs';
  else if (hasConfig && files.length <= 3) type = 'chore';

  const scope = issueId ? `(${issueId.toLowerCase()})` : '';
  const message = `${type}${scope}: work in progress`;

  return message;
}

// Main execution
async function main() {
  // Only run in git repos
  if (!isGitRepo()) {
    hookLog('guard-commit', '⏭ Not a git repo, skipping');
    process.exit(0);
  }

  // Get uncommitted state
  const uncommittedFiles = getUncommittedFiles();
  const changedLines = getChangedLinesCount();
  const branch = getCurrentBranch();
  const issueId = getIssueFromBranch(branch);

  // Skip if no changes
  if (uncommittedFiles.length === 0) {
    hookLog('guard-commit', '✓ No uncommitted changes');
    process.exit(0);
  }

  // Check thresholds
  const exceedsFileThreshold = CONFIG.maxFiles > 0 && uncommittedFiles.length > CONFIG.maxFiles;
  const exceedsLineThreshold = CONFIG.maxLines > 0 && changedLines > CONFIG.maxLines;

  if (!exceedsFileThreshold && !exceedsLineThreshold) {
    hookLog('guard-commit', `✓ ${uncommittedFiles.length} files, ${changedLines} lines (below thresholds)`);
    process.exit(0);
  }

  // Thresholds exceeded - output warning
  hookLog('guard-commit', `⚠ ${uncommittedFiles.length} files, ${changedLines} lines UNCOMMITTED`);

  const suggestedMessage = suggestCommitMessage(uncommittedFiles, issueId);

  // Build output message
  let output = `
## ⚠️ Uncommitted Changes Detected

**Before ending this session**, consider committing your work to prevent loss:

| Metric | Value | Threshold |
|--------|-------|-----------|
| Files changed | **${uncommittedFiles.length}** | ${CONFIG.maxFiles} |
| Lines changed | **~${changedLines}** | ${CONFIG.maxLines} |

### Changed Files
${uncommittedFiles.slice(0, 10).map(f => `- \`${f.status}\` ${f.file}`).join('\n')}
${uncommittedFiles.length > 10 ? `\n... and ${uncommittedFiles.length - 10} more files` : ''}

### Suggested Commit
\`\`\`bash
git add . && git commit -m "${suggestedMessage}"
\`\`\`

Or use: \`/ccpm:commit\`
`;

  // Add auto-commit suggestion if enabled
  if (CONFIG.autoCommit) {
    output += `
### Auto-Commit Available

Run this command to save your work:
\`\`\`bash
git add . && git commit -m "${suggestedMessage}"
\`\`\`
`;
  }

  // Output to Claude's context
  console.log(output);

  // Log session state update
  try {
    const sessionFile = findLatestSessionFile();
    if (sessionFile) {
      const session = JSON.parse(fs.readFileSync(sessionFile, 'utf8'));
      session.guardCommitTriggered = true;
      session.uncommittedAtEnd = uncommittedFiles.length;
      fs.writeFileSync(sessionFile, JSON.stringify(session, null, 2));
    }
  } catch (e) {
    // Non-critical, continue
  }

  process.exit(0);
}

/**
 * Find latest session file
 */
function findLatestSessionFile() {
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

    return sessionFiles[0]?.path || null;
  } catch (e) {
    return null;
  }
}

main().catch(e => {
  hookLog('guard-commit', `✗ Error: ${e.message}`);
  process.exit(0);  // Don't block on errors
});
