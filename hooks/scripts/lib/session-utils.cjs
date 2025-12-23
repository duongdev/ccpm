/**
 * Session state utilities for CCPM hooks
 *
 * Provides functions to read/write/update session state stored in /tmp
 * Session state is used to cache context (project, issue, branch) for performance
 */

const fs = require('fs');

/**
 * Reads session state from temp file
 * @param {string} sessionId - Session identifier
 * @returns {object|null} Session state object or null if not found
 */
function readSessionState(sessionId) {
  if (!sessionId) return null;

  const sessionFile = `/tmp/ccpm-session-${sessionId}.json`;
  if (!fs.existsSync(sessionFile)) return null;

  try {
    return JSON.parse(fs.readFileSync(sessionFile, 'utf8'));
  } catch (e) {
    return null;
  }
}

/**
 * Writes complete session state to temp file
 * @param {string} sessionId - Session identifier
 * @param {object} state - Complete state object
 * @returns {boolean} True if successful
 */
function writeSessionState(sessionId, state) {
  if (!sessionId) return false;

  const sessionFile = `/tmp/ccpm-session-${sessionId}.json`;
  try {
    fs.writeFileSync(sessionFile, JSON.stringify(state, null, 2));
    return true;
  } catch (e) {
    return false;
  }
}

/**
 * Updates specific fields in session state
 * @param {string} sessionId - Session identifier
 * @param {object} updates - Fields to update
 * @returns {boolean} True if successful
 */
function updateSessionState(sessionId, updates) {
  const current = readSessionState(sessionId) || {};
  return writeSessionState(sessionId, { ...current, ...updates, timestamp: Date.now() });
}

module.exports = { readSessionState, writeSessionState, updateSessionState };
