/**
 * Shared hook logging utility
 * Writes to /tmp/ccpm-hooks.log for visibility
 *
 * Usage in hooks:
 *   const { hookLog } = require('./lib/hook-logger.cjs');
 *   hookLog('my-hook', '✓ Did something');
 *
 * Watch logs:
 *   tail -f /tmp/ccpm-hooks.log
 */

const fs = require('fs');

const HOOK_LOG_FILE = '/tmp/ccpm-hooks.log';

/**
 * Log a hook event to file only (NOT stderr - Claude Code treats stderr as error)
 * @param {string} hookName - Name of the hook (e.g., 'session-init')
 * @param {string} message - Log message
 */
function hookLog(hookName, message) {
  const timestamp = new Date().toISOString().substring(11, 19); // HH:MM:SS
  const entry = `${timestamp} [${hookName}] ${message}\n`;

  try {
    fs.appendFileSync(HOOK_LOG_FILE, entry);
  } catch (e) {
    // Fail silently - logging should never break hooks
  }
  // NOTE: Do NOT write to stderr - Claude Code interprets any stderr as hook error
}

/**
 * Clear the hook log file (useful at session start)
 */
function clearHookLog() {
  try {
    fs.writeFileSync(HOOK_LOG_FILE, `# CCPM Hook Log - ${new Date().toISOString()}\n`);
  } catch (e) {
    // Fail silently
  }
}

module.exports = { hookLog, clearHookLog, HOOK_LOG_FILE };
