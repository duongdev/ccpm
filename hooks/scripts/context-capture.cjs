#!/usr/bin/env node
/**
 * Context Capture Hook - Auto-captures session context from tool calls
 *
 * Fires: PreToolUse (Write, Edit, Task)
 * Purpose: Automatically log key events to context file for subagent injection
 *
 * What it captures:
 * - File creations (Write tool) → "[auto] created: path/to/file.ts"
 * - File edits (Edit tool) → "[auto] modified: path/to/file.ts"
 * - Task completions (Task tool) → "[auto] task: agent-name completed"
 * - Patterns indicating decisions → "[auto] decision: ..."
 *
 * Output: Appends to /tmp/ccpm-context-{issueId}.log
 * Token cost to main agent: 0 (purely observational)
 */

const fs = require('fs');
const path = require('path');
const { hookLog } = require('./lib/hook-logger.cjs');

// Read tool context from environment
const toolName = process.env.CLAUDE_TOOL_NAME || '';
const toolInput = process.env.CLAUDE_TOOL_INPUT || '{}';

let input;
try {
  input = JSON.parse(toolInput);
} catch (e) {
  // Can't parse, exit silently
  process.exit(0);
}

/**
 * Find the most recent session file
 */
function findSessionFile() {
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

/**
 * Get the context log file path from session state
 */
function getContextLogFile() {
  // Try environment variable first
  if (process.env.CCPM_CONTEXT_LOG) {
    return process.env.CCPM_CONTEXT_LOG;
  }

  // Fall back to session file
  const sessionFile = findSessionFile();
  if (!sessionFile) return null;

  try {
    const session = JSON.parse(fs.readFileSync(sessionFile, 'utf8'));
    return session.contextLogFile || `/tmp/ccpm-context-${session.issueId || session.sessionId}.log`;
  } catch (e) {
    return null;
  }
}

/**
 * Append entry to context log
 */
let capturedEntries = [];

function logContext(entry) {
  const logFile = getContextLogFile();
  capturedEntries.push(entry);

  if (!logFile) return;

  try {
    const timestamp = new Date().toISOString().substring(11, 19); // HH:MM:SS
    fs.appendFileSync(logFile, `${timestamp} ${entry}\n`);
  } catch (e) {
    // Fail silently - this is non-critical
  }
}

/**
 * Extract filename from path for compact logging
 */
function shortPath(filePath) {
  if (!filePath) return 'unknown';
  const parts = filePath.split('/');
  // Return last 2-3 parts for context
  return parts.slice(-3).join('/');
}

/**
 * Detect if content contains decision-like patterns
 */
function extractDecision(content) {
  if (!content) return null;

  const patterns = [
    /(?:decided|choosing|using|going with|picked|selected)\s+([^.!?\n]{10,60})/i,
    /(?:will use|let's use|we'll use)\s+([^.!?\n]{10,60})/i,
  ];

  for (const pattern of patterns) {
    const match = content.match(pattern);
    if (match) return match[1].trim();
  }

  return null;
}

// Main logic - capture based on tool type
switch (toolName) {
  case 'Write': {
    const filePath = input.file_path;
    if (filePath) {
      logContext(`[auto] created: ${shortPath(filePath)}`);
    }
    break;
  }

  case 'Edit': {
    const filePath = input.file_path;
    if (filePath) {
      logContext(`[auto] modified: ${shortPath(filePath)}`);
    }
    break;
  }

  case 'Task': {
    const agentType = input.subagent_type;
    const prompt = input.prompt || '';

    if (agentType) {
      // Log task start
      const shortPrompt = prompt.substring(0, 50).replace(/\n/g, ' ');
      logContext(`[auto] task-start: ${agentType} - "${shortPrompt}..."`);
    }

    // Check for decisions in prompt
    const decision = extractDecision(prompt);
    if (decision) {
      logContext(`[auto] decision: ${decision}`);
    }
    break;
  }

  case 'Bash': {
    const command = input.command || '';

    // Capture test runs
    if (command.match(/\b(jest|vitest|pytest|phpunit|npm test|pnpm test)\b/i)) {
      logContext(`[auto] test-run: ${command.substring(0, 40)}`);
    }

    // Capture builds
    if (command.match(/\b(npm run build|pnpm build|tsc|webpack|vite build)\b/i)) {
      logContext(`[auto] build: ${command.substring(0, 40)}`);
    }

    // Capture git commits (but not the actual commit - just that it happened)
    if (command.match(/git commit/i)) {
      logContext(`[auto] git-commit`);
    }
    break;
  }
}

// Log what was captured (if anything)
if (capturedEntries.length > 0) {
  hookLog('context-capture', `✓ ${toolName}: ${capturedEntries.join(' | ')}`);
}

// Always exit 0 - this hook should never block
process.exit(0);
