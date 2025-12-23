#!/usr/bin/env node
/**
 * CCPM Custom Statusline
 *
 * Displays: Project | Issue | Progress | Branch
 * Colors: cyan (project), green (issue), yellow (progress), magenta (branch)
 */

'use strict';

const { stdin, stdout, env } = require('process');
const fs = require('fs');

// Configuration
const USE_COLOR = !env.NO_COLOR && stdout.isTTY;

// Color helpers
const color = (code) => USE_COLOR ? `\x1b[${code}m` : '';
const reset = () => USE_COLOR ? '\x1b[0m' : '';

// Color definitions
const ProjectColor = color('1;36');   // cyan bold
const IssueColor = color('1;32');     // green bold
const ProgressColor = color('1;33'); // yellow bold
const BranchColor = color('1;35');   // magenta bold
const DimColor = color('2');          // dim
const Reset = reset();

/**
 * Read session state from temp file
 */
function readSessionState() {
  const sessionId = env.CCPM_SESSION_ID;
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
 * Format progress percentage with color
 */
function formatProgress(percent) {
  if (percent === null || percent === undefined) return null;

  let progressColor = ProgressColor;
  if (percent >= 80) progressColor = color('1;32'); // green
  else if (percent >= 50) progressColor = color('1;33'); // yellow
  else progressColor = color('1;31'); // red

  return `${progressColor}${percent}%${Reset}`;
}

/**
 * Truncate string with ellipsis
 */
function truncate(str, maxLen) {
  if (!str || str.length <= maxLen) return str;
  return str.substring(0, maxLen - 1) + '…';
}

/**
 * Build statusline segments
 */
function buildStatusline(sessionState, stdinData) {
  const segments = [];

  // Project segment
  const project = sessionState?.project?.name || env.CCPM_ACTIVE_PROJECT;
  if (project) {
    segments.push(`${ProjectColor}${truncate(project, 15)}${Reset}`);
  }

  // Issue segment
  const issueId = sessionState?.issueId || env.CCPM_ACTIVE_ISSUE;
  if (issueId) {
    segments.push(`${IssueColor}${issueId}${Reset}`);
  }

  // Progress segment (from session state if available)
  const progress = sessionState?.checklistProgress;
  if (progress !== undefined && progress !== null) {
    segments.push(formatProgress(progress));
  }

  // Branch segment (shortened)
  const branch = sessionState?.gitBranch || env.CCPM_GIT_BRANCH;
  if (branch) {
    const shortBranch = branch.replace(/^(feature|fix|chore|refactor)\//, '');
    segments.push(`${BranchColor}${truncate(shortBranch, 20)}${Reset}`);
  }

  // Fallback if no CCPM context
  if (segments.length === 0) {
    segments.push(`${DimColor}CCPM${Reset}`);
  }

  return segments.join(` ${DimColor}│${Reset} `);
}

/**
 * Read stdin and output statusline
 */
async function main() {
  try {
    // Read stdin (Claude Code sends JSON with session info)
    let stdinData = {};
    try {
      const input = fs.readFileSync(0, 'utf-8').trim();
      if (input) stdinData = JSON.parse(input);
    } catch (e) {
      // Ignore stdin errors
    }

    const sessionState = readSessionState();
    const statusline = buildStatusline(sessionState, stdinData);

    console.log(statusline);
    process.exit(0);
  } catch (error) {
    console.log('CCPM');
    process.exit(0);
  }
}

main();
