#!/usr/bin/env node
/**
 * SubagentStart Hook - Injects CCPM context to all subagents
 *
 * Fires: When any subagent (Task tool) is started
 * Purpose: Inject Linear issue, project config, and rules
 * Target: ~200 tokens
 *
 * Input (stdin): JSON with { agent_type, agent_id, cwd, ... }
 * Output (stdout): JSON with { hookSpecificOutput: { additionalContext } }
 *
 * Fail-open: If anything goes wrong, exits 0 with minimal context
 */

const fs = require('fs');
const path = require('path');

/**
 * Read session state from /tmp/ccpm-session-*.json
 * Returns: { issueId, issueTitle, projectName } or null
 */
function readSessionState() {
  try {
    const tmpDir = '/tmp';
    const files = fs.readdirSync(tmpDir);
    const sessionFiles = files.filter(f => f.startsWith('ccpm-session-') && f.endsWith('.json'));

    if (sessionFiles.length === 0) {
      return null;
    }

    // Use most recent session file
    const sessionFile = sessionFiles
      .map(f => ({
        name: f,
        path: path.join(tmpDir, f),
        mtime: fs.statSync(path.join(tmpDir, f)).mtime
      }))
      .sort((a, b) => b.mtime - a.mtime)[0];

    const content = fs.readFileSync(sessionFile.path, 'utf8');
    return JSON.parse(content);
  } catch (err) {
    // Fail-open: session state is optional
    return null;
  }
}

/**
 * Read environment variables for CCPM context
 * Returns: { issueId, projectName } or {}
 */
function readEnvironment() {
  return {
    issueId: process.env.CCPM_ACTIVE_ISSUE || null,
    projectName: process.env.CCPM_ACTIVE_PROJECT || null
  };
}

/**
 * Build context string to inject into subagent (~200 tokens)
 */
function buildContext(input, sessionState, envVars) {
  const issueId = sessionState?.issueId || envVars.issueId || null;
  const issueTitle = sessionState?.issueTitle || null;
  const projectName = sessionState?.projectName || envVars.projectName || 'default';
  const cwd = input?.cwd || process.cwd();

  let context = '## CCPM Context\n';

  if (issueId) {
    context += `- Issue: ${issueId}`;
    if (issueTitle) {
      context += ` (${issueTitle})`;
    }
    context += '\n';
  }

  context += `- Project: ${projectName}\n`;
  context += `- CWD: ${cwd}\n`;
  context += '\n';
  context += '## Rules\n';
  context += '- Linear operations: Use ccpm:linear-operations agent (NEVER direct MCP)\n';
  context += '- Git: NEVER auto-commit/push without user approval\n';
  context += '- Progress: Update Linear issue, not local files\n';
  context += '- Be concise, list unresolved questions at end\n';

  return context;
}

/**
 * Main function
 */
function main() {
  try {
    // Read input from stdin
    let inputData = '';
    const stdin = process.stdin;

    stdin.on('data', chunk => {
      inputData += chunk;
    });

    stdin.on('end', () => {
      let input = {};

      // Parse input JSON (optional - may be empty)
      if (inputData.trim()) {
        try {
          input = JSON.parse(inputData);
        } catch (err) {
          // Fail-open: input parsing is optional
          input = {};
        }
      }

      // Gather context from multiple sources
      const sessionState = readSessionState();
      const envVars = readEnvironment();

      // Build context string
      const contextString = buildContext(input, sessionState, envVars);

      // Output in required format for SubagentStart hook
      const output = {
        hookSpecificOutput: {
          hookEventName: 'SubagentStart',
          additionalContext: contextString
        }
      };

      console.log(JSON.stringify(output));
      process.exit(0);
    });

    // Handle stdin errors
    stdin.on('error', () => {
      // Fail-open with minimal context
      const output = {
        hookSpecificOutput: {
          hookEventName: 'SubagentStart',
          additionalContext: '## CCPM Context\n- Project: default\n\n## Rules\n- Linear operations: Use ccpm:linear-operations agent (NEVER direct MCP)\n- Git: NEVER auto-commit/push without user approval\n- Progress: Update Linear issue, not local files\n- Be concise, list unresolved questions at end\n'
        }
      };
      console.log(JSON.stringify(output));
      process.exit(0);
    });

  } catch (err) {
    // Fail-open: Always exit 0 with minimal context
    const output = {
      hookSpecificOutput: {
        hookEventName: 'SubagentStart',
        additionalContext: '## CCPM Context\n- Project: default\n\n## Rules\n- Linear operations: Use ccpm:linear-operations agent (NEVER direct MCP)\n- Git: NEVER auto-commit/push without user approval\n- Progress: Update Linear issue, not local files\n- Be concise, list unresolved questions at end\n'
      }
    };
    console.log(JSON.stringify(output));
    process.exit(0);
  }
}

main();
