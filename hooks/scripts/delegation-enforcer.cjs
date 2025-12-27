#!/usr/bin/env node
/**
 * Delegation Enforcer Hook - Light reminder about agent delegation
 *
 * Fires: PreToolUse (Edit, Write)
 * Purpose: Gentle reminder that agents are preferred for implementation
 *
 * This is advisory only - does not block, just suggests alternatives.
 * The main enforcement is through explicit option labels in /ccpm:work.
 */

const fs = require('fs');
const path = require('path');

// Hook logging
const HOOK_LOG_FILE = '/tmp/ccpm-hooks.log';
function hookLog(hookName, message) {
  const timestamp = new Date().toISOString().substr(11, 8);
  const logLine = `${timestamp} [${hookName}] ${message}\n`;
  try {
    fs.appendFileSync(HOOK_LOG_FILE, logLine);
  } catch (e) {
    // Ignore log errors
  }
}

// Read tool context from environment
const toolName = process.env.CLAUDE_TOOL_NAME || '';
const toolInput = process.env.CLAUDE_TOOL_INPUT || '{}';

let input;
try {
  input = JSON.parse(toolInput);
} catch (e) {
  process.exit(0);
}

/**
 * Get file path from tool input
 */
function getFilePath() {
  if (toolName === 'Edit' || toolName === 'Write') {
    return input.file_path || input.path || '';
  }
  return '';
}

/**
 * Check if file is likely implementation code (not config/docs)
 */
function isImplementationFile(filePath) {
  if (!filePath) return false;

  // Skip config and doc files
  const skipPatterns = [
    /\.(md|txt|json|yaml|yml|toml|ini|env)$/i,
    /README/i,
    /CHANGELOG/i,
    /LICENSE/i,
    /\.config\./,
    /package\.json/,
    /tsconfig/,
    /\.eslint/,
    /\.prettier/
  ];

  for (const pattern of skipPatterns) {
    if (pattern.test(filePath)) {
      return false;
    }
  }

  // Check for code files
  const codePatterns = [
    /\.(ts|tsx|js|jsx|py|rb|go|rs|java|kt|swift|vue|svelte)$/i,
    /src\//,
    /lib\//,
    /components\//,
    /pages\//,
    /api\//
  ];

  for (const pattern of codePatterns) {
    if (pattern.test(filePath)) {
      return true;
    }
  }

  return false;
}

/**
 * Suggest appropriate agent based on file type
 */
function suggestAgent(filePath) {
  // Frontend indicators
  if (filePath.match(/\.(tsx?|jsx?|css|scss|vue|svelte)$/i) &&
      (filePath.includes('component') || filePath.includes('page') || filePath.includes('screen'))) {
    return 'ccpm:frontend-developer';
  }

  // Backend indicators
  if (filePath.includes('api/') || filePath.includes('server/') ||
      filePath.includes('resolver') || filePath.includes('service')) {
    return 'ccpm:backend-architect';
  }

  // Test files
  if (filePath.includes('test') || filePath.includes('spec')) {
    return 'ccpm:tdd-orchestrator';
  }

  return 'general-purpose';
}

// Main execution
function main() {
  // Only check Edit and Write tools
  if (!['Edit', 'Write'].includes(toolName)) {
    process.exit(0);
  }

  const filePath = getFilePath();

  // Only remind for implementation files
  if (!isImplementationFile(filePath)) {
    hookLog('delegation-enforcer', `${toolName} on ${filePath} - non-implementation file, skipping`);
    process.exit(0);
  }

  const suggestedAgent = suggestAgent(filePath);

  hookLog('delegation-enforcer', `💡 ${toolName} on implementation file: ${filePath}`);

  // Output a brief reminder (not a warning block)
  console.log(`💡 Tip: For multi-file changes, consider using Task(subagent_type="${suggestedAgent}") to protect main context.`);

  // Always allow through
  process.exit(0);
}

main();
