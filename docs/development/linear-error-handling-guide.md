# Linear Integration Error Handling Guide

**Last Updated**: 2025-01-20
**Status**: Production Ready
**Applies To**: All CCPM commands using Linear MCP integration

---

## Table of Contents

1. [Overview](#overview)
2. [Error Categories](#error-categories)
3. [Standard Error Handling Pattern](#standard-error-handling-pattern)
4. [Error Handling by Category](#error-handling-by-category)
5. [User Messaging Guidelines](#user-messaging-guidelines)
6. [Recovery Strategies](#recovery-strategies)
7. [Code Examples](#code-examples)
8. [Testing Recommendations](#testing-recommendations)
9. [Current Gaps & Improvements](#current-gaps--improvements)

---

## Overview

This guide provides comprehensive error handling patterns for all Linear integration points in CCPM commands. It ensures consistent, user-friendly error messaging and graceful degradation when Linear operations fail.

### Key Principles

1. **Fail Fast**: Detect errors early and provide immediate feedback
2. **Be Helpful**: Error messages should guide users toward resolution
3. **Fail Gracefully**: Provide fallback options when possible
4. **Be Consistent**: Use the same patterns across all commands
5. **Log Context**: Include enough information for debugging without exposing sensitive data

### Helper Functions Available

All commands using Linear integration should load shared helpers:

```markdown
READ: commands/_shared-linear-helpers.md
```

Available functions:
- `getValidStateId(teamId, stateNameOrType)` - Resolves state names to valid IDs
- `ensureLabelsExist(teamId, labelNames, options)` - Creates labels if missing
- `getOrCreateLabel(teamId, labelName, options)` - Gets or creates single label
- `getDefaultColor(labelName)` - Standard CCPM color palette

---

## Error Categories

### 1. Linear API Errors

**Causes:**
- Network connectivity issues
- Linear API downtime
- Rate limiting
- Invalid API credentials
- Malformed requests

**Impact:** Command cannot proceed with Linear operations

### 2. State Validation Errors

**Causes:**
- Invalid state name provided
- State doesn't exist in team's workflow
- Team workflow was modified
- Typo in state name

**Impact:** Cannot create or update issues with correct status

### 3. Label Creation Errors

**Causes:**
- Insufficient permissions to create labels
- Label name conflicts
- Team configuration issues
- Network errors during label creation

**Impact:** Issues may be created without proper labels

### 4. Team/Project Resolution Errors

**Causes:**
- Invalid team ID in configuration
- Project doesn't exist
- User doesn't have access to team/project
- Configuration file corruption

**Impact:** Cannot create or query issues

### 5. Issue Creation/Update Errors

**Causes:**
- Missing required fields
- Invalid parent issue ID
- Workflow validation failures
- Duplicate issue detection

**Impact:** Issues not created or updated as expected

### 6. Document Operations Errors

**Causes:**
- Document doesn't exist
- Access permissions denied
- Document ID extraction failures
- Content format errors

**Impact:** Cannot read or write spec documents

---

## Standard Error Handling Pattern

### Template for All Linear Operations

```javascript
try {
  // 1. Validate inputs before API call
  if (!teamId || !issueId) {
    throw new Error('Missing required parameters: teamId and issueId are required');
  }

  // 2. Perform Linear operation
  const result = await mcp__linear__operation({ params });

  // 3. Validate response
  if (!result || !result.id) {
    throw new Error('Linear API returned unexpected response format');
  }

  // 4. Return success
  return result;

} catch (error) {
  // 5. Categorize error
  const errorType = categorizeError(error);

  // 6. Log with context
  console.error(`Linear operation failed: ${error.message}`);
  console.error(`Context: ${JSON.stringify({ teamId, issueId, operation: 'operation_name' })}`);

  // 7. Provide user-friendly message
  throw new Error(getUserFriendlyMessage(errorType, error));
}
```

### Error Categorization Helper

```javascript
function categorizeError(error) {
  const message = error.message.toLowerCase();

  if (message.includes('network') || message.includes('timeout')) {
    return 'NETWORK_ERROR';
  }
  if (message.includes('permission') || message.includes('unauthorized')) {
    return 'PERMISSION_ERROR';
  }
  if (message.includes('not found') || message.includes('invalid')) {
    return 'VALIDATION_ERROR';
  }
  if (message.includes('rate limit')) {
    return 'RATE_LIMIT_ERROR';
  }

  return 'UNKNOWN_ERROR';
}
```

---

## Error Handling by Category

### 1. Linear API Errors

#### Detection Pattern

```javascript
try {
  const issue = await mcp__linear__get_issue({ id: issueId });
} catch (error) {
  if (error.message.includes('network') || error.message.includes('ECONNREFUSED')) {
    // Network error
    handleNetworkError(error);
  } else if (error.message.includes('401') || error.message.includes('403')) {
    // Authentication/authorization error
    handlePermissionError(error);
  } else if (error.message.includes('429')) {
    // Rate limit error
    handleRateLimitError(error);
  } else if (error.message.includes('500') || error.message.includes('502')) {
    // Linear API error
    handleAPIError(error);
  } else {
    // Unknown error
    handleUnknownError(error);
  }
}
```

#### Recovery Strategy

```javascript
function handleNetworkError(error) {
  throw new Error(
    `❌ Linear Connection Error\n\n` +
    `Unable to connect to Linear API. This may indicate:\n` +
    `  • Network connectivity issues\n` +
    `  • Linear API downtime\n` +
    `  • Firewall blocking the connection\n\n` +
    `Recovery Steps:\n` +
    `  1. Check your internet connection\n` +
    `  2. Visit https://status.linear.app for service status\n` +
    `  3. Try again in a few moments\n` +
    `  4. If problem persists, check MCP configuration\n\n` +
    `Technical details: ${error.message}`
  );
}

function handleRateLimitError(error) {
  throw new Error(
    `⏱️  Linear Rate Limit Exceeded\n\n` +
    `You've made too many requests to Linear in a short period.\n\n` +
    `Recovery Steps:\n` +
    `  1. Wait 60 seconds before retrying\n` +
    `  2. Consider reducing command frequency\n` +
    `  3. Check if other processes are using Linear API\n\n` +
    `Rate limits reset every minute.`
  );
}
```

### 2. State Validation Errors

#### Current Implementation (from shared helpers)

The `getValidStateId()` function already provides excellent error handling:

```javascript
// Step 6: No match found - throw helpful error
const availableStates = states.map(s => `  - ${s.name} (type: ${s.type})`).join('\n');
throw new Error(
  `Invalid state: "${stateNameOrType}"\n\n` +
  `Available states for this team:\n${availableStates}\n\n` +
  `Tip: Use state name (e.g., "In Progress") or type (e.g., "started")`
);
```

#### Usage Pattern in Commands

```javascript
try {
  const stateId = await getValidStateId(teamId, "In Progress");
  // Proceed with issue creation/update
} catch (error) {
  // Error already includes helpful message with available states
  console.error("❌ State Resolution Failed");
  console.error(error.message);

  // Optionally add context
  console.log(`\n💡 Hint: Check your team's workflow in Linear Settings`);

  // Re-throw to halt command
  throw error;
}
```

#### Enhanced Error Handling

```javascript
async function getValidStateIdSafe(teamId, stateNameOrType, fallbackType = 'unstarted') {
  try {
    return await getValidStateId(teamId, stateNameOrType);
  } catch (error) {
    console.error(`⚠️  Warning: ${error.message}`);

    // Try fallback
    if (fallbackType) {
      console.log(`\n🔄 Attempting fallback to "${fallbackType}" state type...`);
      try {
        const fallbackStateId = await getValidStateId(teamId, fallbackType);
        console.log(`✅ Using fallback state: "${fallbackType}"`);
        return fallbackStateId;
      } catch (fallbackError) {
        console.error(`❌ Fallback also failed: ${fallbackError.message}`);
      }
    }

    // No fallback worked
    throw error;
  }
}
```

### 3. Label Creation Errors

#### Current Implementation (from shared helpers)

The `getOrCreateLabel()` function creates labels but lacks comprehensive error handling.

#### Enhanced Error Handling

```javascript
async function getOrCreateLabelSafe(teamId, labelName, options = {}) {
  try {
    const label = await getOrCreateLabel(teamId, labelName, options);
    return label;
  } catch (error) {
    const errorMsg = error.message.toLowerCase();

    if (errorMsg.includes('permission') || errorMsg.includes('unauthorized')) {
      throw new Error(
        `❌ Label Creation Failed: Permission Denied\n\n` +
        `You don't have permission to create labels in this team.\n\n` +
        `Recovery Options:\n` +
        `  1. Ask team admin to create "${labelName}" label\n` +
        `  2. Request label creation permissions\n` +
        `  3. Proceed without this label (may affect workflow)\n\n` +
        `Original error: ${error.message}`
      );
    }

    if (errorMsg.includes('already exists') || errorMsg.includes('duplicate')) {
      // This shouldn't happen with current implementation, but handle gracefully
      console.log(`ℹ️  Label "${labelName}" already exists, using existing label`);
      // Try to fetch the existing label
      const existingLabels = await mcp__linear__list_issue_labels({
        team: teamId,
        name: labelName
      });
      const existing = existingLabels.find(
        label => label.name.toLowerCase() === labelName.toLowerCase()
      );
      if (existing) return existing;
    }

    // Unknown error
    throw new Error(
      `❌ Label Operation Failed\n\n` +
      `Unable to create or retrieve label "${labelName}".\n\n` +
      `Error: ${error.message}\n\n` +
      `Recovery Steps:\n` +
      `  1. Verify team ID is correct\n` +
      `  2. Check Linear MCP connection\n` +
      `  3. Try creating label manually in Linear UI\n` +
      `  4. Contact support if issue persists`
    );
  }
}
```

#### Graceful Degradation Pattern

```javascript
async function ensureLabelsExistSafe(teamId, labelNames, options = {}) {
  const successfulLabels = [];
  const failedLabels = [];

  for (const labelName of labelNames) {
    try {
      const label = await getOrCreateLabelSafe(teamId, labelName, {
        color: options.colors?.[labelName],
        description: options.descriptions?.[labelName]
      });
      successfulLabels.push(label.name);
    } catch (error) {
      console.error(`⚠️  Failed to create label "${labelName}":`, error.message);
      failedLabels.push({ name: labelName, error: error.message });
    }
  }

  // Report results
  if (failedLabels.length > 0) {
    console.warn(`\n⚠️  Warning: ${failedLabels.length} label(s) could not be created:`);
    failedLabels.forEach(({ name, error }) => {
      console.warn(`  • ${name}: ${error}`);
    });

    // Ask user if they want to proceed
    console.log(`\n${successfulLabels.length} label(s) were created successfully.`);
    console.log(`\nOptions:`);
    console.log(`  1. Continue without failed labels (may affect workflow)`);
    console.log(`  2. Abort and fix label issues first`);

    // In interactive mode, use AskUserQuestion
    // For now, proceed with available labels
    console.log(`\n⚠️  Proceeding with available labels...`);
  }

  return successfulLabels;
}
```

### 4. Team/Project Resolution Errors

#### Detection and Handling

```javascript
async function validateTeamAccess(teamId) {
  try {
    // Try to list team's issues as a validation check
    const states = await mcp__linear__list_issue_statuses({
      team: teamId
    });

    if (!states || states.length === 0) {
      throw new Error(`No workflow states found for team ${teamId}`);
    }

    return true;
  } catch (error) {
    throw new Error(
      `❌ Team Access Validation Failed\n\n` +
      `Unable to access team "${teamId}". This may indicate:\n` +
      `  • Invalid team ID in configuration\n` +
      `  • You don't have access to this team\n` +
      `  • Team was deleted or archived\n\n` +
      `Recovery Steps:\n` +
      `  1. Verify team ID in ~/.claude/ccpm-config.yaml\n` +
      `  2. Check team access in Linear web UI\n` +
      `  3. Update project configuration: /ccpm:project:update [project-id]\n\n` +
      `Technical details: ${error.message}`
    );
  }
}
```

### 5. Issue Creation/Update Errors

#### Comprehensive Error Handling

```javascript
async function createIssueSafe(params) {
  try {
    // Validate required parameters
    const required = ['teamId', 'title'];
    const missing = required.filter(field => !params[field]);
    if (missing.length > 0) {
      throw new Error(`Missing required fields: ${missing.join(', ')}`);
    }

    // Validate state ID if provided
    if (params.stateId) {
      await validateStateId(params.teamId, params.stateId);
    }

    // Validate label IDs if provided
    if (params.labelIds && params.labelIds.length > 0) {
      await validateLabelIds(params.teamId, params.labelIds);
    }

    // Create issue
    const issue = await mcp__linear__create_issue(params);

    if (!issue || !issue.id) {
      throw new Error('Linear API returned invalid response');
    }

    console.log(`✅ Issue created: ${issue.identifier}`);
    return issue;

  } catch (error) {
    const errorMsg = error.message.toLowerCase();

    if (errorMsg.includes('parent')) {
      throw new Error(
        `❌ Issue Creation Failed: Invalid Parent\n\n` +
        `The parent issue ID provided doesn't exist or you don't have access.\n\n` +
        `Recovery Steps:\n` +
        `  1. Verify parent issue ID is correct\n` +
        `  2. Check parent issue still exists\n` +
        `  3. Try creating without parent issue\n\n` +
        `Original error: ${error.message}`
      );
    }

    if (errorMsg.includes('duplicate')) {
      throw new Error(
        `❌ Issue Creation Failed: Possible Duplicate\n\n` +
        `An issue with similar details may already exist.\n\n` +
        `Recovery Steps:\n` +
        `  1. Search for existing issue\n` +
        `  2. Modify issue title to be unique\n` +
        `  3. Check if issue was already created\n\n` +
        `Original error: ${error.message}`
      );
    }

    // Generic error
    throw new Error(
      `❌ Issue Creation Failed\n\n` +
      `Unable to create Linear issue.\n\n` +
      `Parameters:\n` +
      `  • Team: ${params.teamId}\n` +
      `  • Title: ${params.title}\n\n` +
      `Error: ${error.message}\n\n` +
      `Recovery Steps:\n` +
      `  1. Check Linear MCP connection\n` +
      `  2. Verify team ID and permissions\n` +
      `  3. Try creating issue manually in Linear UI\n` +
      `  4. Contact support if issue persists`
    );
  }
}
```

### 6. Document Operations Errors

#### Error Handling for Document Retrieval

```javascript
async function getLinearDocumentSafe(documentId) {
  try {
    const doc = await mcp__linear__get_document({ id: documentId });

    if (!doc || !doc.content) {
      throw new Error('Document exists but has no content');
    }

    return doc;
  } catch (error) {
    const errorMsg = error.message.toLowerCase();

    if (errorMsg.includes('not found') || errorMsg.includes('404')) {
      throw new Error(
        `❌ Document Not Found\n\n` +
        `Linear document "${documentId}" doesn't exist.\n\n` +
        `Recovery Options:\n` +
        `  1. Verify document ID is correct\n` +
        `  2. Check if document was deleted\n` +
        `  3. Create a new document: /ccpm:spec:create\n\n` +
        `Document ID: ${documentId}`
      );
    }

    if (errorMsg.includes('permission') || errorMsg.includes('access denied')) {
      throw new Error(
        `❌ Document Access Denied\n\n` +
        `You don't have permission to access this document.\n\n` +
        `Recovery Steps:\n` +
        `  1. Request access from document owner\n` +
        `  2. Check team membership\n` +
        `  3. Verify document sharing settings\n\n` +
        `Document ID: ${documentId}`
      );
    }

    // Generic error
    throw new Error(
      `❌ Document Retrieval Failed\n\n` +
      `Unable to retrieve Linear document.\n\n` +
      `Document ID: ${documentId}\n` +
      `Error: ${error.message}\n\n` +
      `Recovery Steps:\n` +
      `  1. Verify document ID\n` +
      `  2. Check Linear MCP connection\n` +
      `  3. Try accessing in Linear web UI\n` +
      `  4. Contact support if issue persists`
    );
  }
}
```

---

## User Messaging Guidelines

### Principles

1. **Start with emoji indicator**: ❌ for errors, ⚠️ for warnings, ℹ️ for info
2. **Clear headline**: State what failed in 1-2 words
3. **Explain the issue**: 1-2 sentences on what went wrong
4. **List recovery steps**: Numbered, actionable steps
5. **Include context**: Show relevant IDs, values
6. **Technical details last**: Original error at the end

### Message Template

```
[EMOJI] [OPERATION] Failed: [REASON]

[1-2 sentence explanation of what happened]

[Optional: What this means]
  • Point 1
  • Point 2

Recovery Steps:
  1. [Action user can take]
  2. [Alternative action]
  3. [Last resort]

[Optional: Additional context]
  • Field: Value
  • ID: abc123

[Optional: Technical details]
Technical details: [Original error message]
```

### Examples

#### Good Error Message

```
❌ Label Creation Failed: Permission Denied

You don't have permission to create labels in this team. Labels help
organize work, but the issue can still be created without them.

Recovery Options:
  1. Ask team admin to create "planning" label
  2. Request label creation permissions
  3. Proceed without this label (workflow may be affected)

Team: TEAM-abc123
Label: planning

Original error: User lacks permission to create labels
```

#### Bad Error Message

```
Error: Permission denied

Failed to create label
```

### Tone Guidelines

- **Be empathetic**: Acknowledge the frustration
- **Be helpful**: Provide clear next steps
- **Be honest**: Don't hide technical details, but put them last
- **Be concise**: Respect user's time
- **Be positive**: Frame recovery steps as opportunities

---

## Recovery Strategies

### 1. Retry with Exponential Backoff

For transient network errors:

```javascript
async function retryWithBackoff(operation, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }

      const isTransient = error.message.includes('network') ||
                         error.message.includes('timeout') ||
                         error.message.includes('503');

      if (!isTransient) {
        throw error;
      }

      const delay = Math.pow(2, attempt) * 1000; // 2s, 4s, 8s
      console.log(`⏳ Attempt ${attempt} failed. Retrying in ${delay/1000}s...`);
      await sleep(delay);
    }
  }
}

// Usage
const issue = await retryWithBackoff(() =>
  mcp__linear__create_issue(params)
);
```

### 2. Graceful Degradation

Continue with reduced functionality:

```javascript
// Try to add labels, but don't fail if it doesn't work
let labelIds = [];
try {
  labelIds = await ensureLabelsExist(teamId, ['planning', 'research']);
} catch (error) {
  console.warn(`⚠️  Could not create labels: ${error.message}`);
  console.log(`ℹ️  Continuing without labels...`);
}

// Create issue with or without labels
const issue = await mcp__linear__create_issue({
  ...params,
  labelIds: labelIds // Empty array if labels failed
});
```

### 3. Fallback to Default Values

Use safe defaults when validation fails:

```javascript
let stateId;
try {
  stateId = await getValidStateId(teamId, userProvidedState);
} catch (error) {
  console.warn(`⚠️  State "${userProvidedState}" not found`);
  console.log(`🔄 Using default "Backlog" state...`);

  try {
    stateId = await getValidStateId(teamId, 'backlog');
  } catch (fallbackError) {
    // If even backlog fails, try unstarted type
    stateId = await getValidStateId(teamId, 'unstarted');
  }
}
```

### 4. Interactive Recovery

Ask user how to proceed:

```javascript
try {
  await createLinearDocument(docParams);
} catch (error) {
  console.error(`❌ Document creation failed: ${error.message}`);

  const answer = await askUserQuestion({
    questions: [{
      question: "Document creation failed. How would you like to proceed?",
      header: "Recovery",
      multiSelect: false,
      options: [
        {
          label: "Retry",
          description: "Try creating the document again"
        },
        {
          label: "Skip Document",
          description: "Continue without creating document"
        },
        {
          label: "Manual Creation",
          description: "I'll create the document manually in Linear UI"
        },
        {
          label: "Abort",
          description: "Cancel the entire operation"
        }
      ]
    }]
  });

  // Handle based on user choice
  switch (answer) {
    case "Retry":
      return await createLinearDocument(docParams);
    case "Skip Document":
      console.log("ℹ️  Continuing without document...");
      return null;
    case "Manual Creation":
      console.log("📝 Create document manually, then continue");
      return null;
    case "Abort":
      throw new Error("Operation aborted by user");
  }
}
```

### 5. Cache and Resume

For multi-step operations:

```javascript
const progressFile = '.ccpm-progress.json';

async function createIssuesWithResume(issueParams) {
  // Load previous progress
  let progress = loadProgress(progressFile) || {
    completed: [],
    failed: [],
    remaining: issueParams
  };

  for (const params of progress.remaining) {
    try {
      const issue = await createIssueSafe(params);
      progress.completed.push(issue);
      saveProgress(progressFile, progress);
    } catch (error) {
      progress.failed.push({ params, error: error.message });
      saveProgress(progressFile, progress);

      console.error(`❌ Failed to create issue: ${params.title}`);
      console.log(`\nProgress saved. You can resume later with:`);
      console.log(`  /ccpm:spec:break-down --resume`);

      throw error;
    }
  }

  // Cleanup on success
  deleteProgress(progressFile);
  return progress.completed;
}
```

---

## Code Examples

### Example 1: Complete Command Error Handling

```javascript
// /ccpm:planning:create command with comprehensive error handling

async function createAndPlanTask(title, project, jiraTicketId) {
  let issue = null;
  let hasErrors = false;

  try {
    // Step 1: Load project configuration
    console.log("📦 Loading project configuration...");
    let projectConfig;
    try {
      projectConfig = await loadProjectConfig(project);
    } catch (error) {
      throw new Error(
        `❌ Project Configuration Error\n\n` +
        `Failed to load configuration for project "${project}".\n\n` +
        `Recovery Steps:\n` +
        `  1. Check project exists: /ccpm:project:list\n` +
        `  2. Verify project ID is correct\n` +
        `  3. Add project: /ccpm:project:add ${project}\n\n` +
        `Error: ${error.message}`
      );
    }

    const { LINEAR_TEAM, LINEAR_PROJECT } = projectConfig;

    // Step 2: Ensure labels exist
    console.log("🏷️  Ensuring workflow labels exist...");
    let labels = [];
    try {
      labels = await ensureLabelsExist(LINEAR_TEAM, [
        'planning',
        'research'
      ], {
        descriptions: {
          'planning': 'Task is in planning phase',
          'research': 'Research and discovery required'
        }
      });
    } catch (error) {
      console.warn(`⚠️  Label creation warning: ${error.message}`);
      console.log(`ℹ️  Continuing without labels...`);
      hasErrors = true;
      // Continue without labels
    }

    // Step 3: Get valid state ID
    console.log("🔄 Validating workflow state...");
    let stateId;
    try {
      stateId = await getValidStateId(LINEAR_TEAM, "Backlog");
    } catch (error) {
      console.error(`❌ State validation failed: ${error.message}`);
      console.log(`💡 Tip: Check team workflow in Linear Settings`);
      throw error; // Cannot proceed without valid state
    }

    // Step 4: Create Linear issue
    console.log("📝 Creating Linear issue...");
    try {
      issue = await mcp__linear__create_issue({
        title: title,
        teamId: LINEAR_TEAM,
        projectId: LINEAR_PROJECT,
        stateId: stateId,
        labelIds: labels,
        description: `## Task\n\n${title}\n\n**Jira Reference**: ${jiraTicketId || 'N/A'}\n\n---\n\n_Planning in progress..._`
      });

      console.log(`✅ Issue created: ${issue.identifier}`);
    } catch (error) {
      throw new Error(
        `❌ Issue Creation Failed\n\n` +
        `Unable to create Linear issue "${title}".\n\n` +
        `Configuration:\n` +
        `  • Team: ${LINEAR_TEAM}\n` +
        `  • Project: ${LINEAR_PROJECT}\n\n` +
        `Error: ${error.message}\n\n` +
        `Recovery Steps:\n` +
        `  1. Verify team and project IDs\n` +
        `  2. Check Linear MCP connection\n` +
        `  3. Try creating manually: /ccpm:planning:quick-plan\n` +
        `  4. Contact support if issue persists`
      );
    }

    // Step 5: Run planning workflow
    console.log("🔍 Starting planning workflow...");
    try {
      await runPlanningWorkflow(issue.id, jiraTicketId);
    } catch (error) {
      console.error(`⚠️  Planning workflow error: ${error.message}`);
      console.log(`\nℹ️  Issue was created but planning failed.`);
      console.log(`   You can run planning manually: /ccpm:planning:plan ${issue.identifier}`);
      hasErrors = true;
      // Continue to show success with warnings
    }

    // Step 6: Display results
    console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    if (hasErrors) {
      console.log(`⚠️  Task Created with Warnings`);
    } else {
      console.log(`✅ Task Created Successfully`);
    }
    console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`\n📋 Issue: ${issue.identifier}`);
    console.log(`🔗 URL: ${issue.url}`);
    console.log(`📝 Title: ${title}`);

    if (hasErrors) {
      console.log(`\n⚠️  Warnings occurred during creation:`);
      console.log(`   • Some labels may not have been applied`);
      console.log(`   • Planning workflow may be incomplete`);
      console.log(`\n💡 Run /ccpm:utils:status ${issue.identifier} to verify`);
    }

    return issue;

  } catch (error) {
    // Top-level error handler
    console.error(`\n❌ Command Failed\n`);
    console.error(error.message);

    if (issue) {
      console.log(`\nℹ️  Partial Progress:`);
      console.log(`   Issue created: ${issue.identifier}`);
      console.log(`   You can continue manually: /ccpm:planning:plan ${issue.identifier}`);
    }

    throw error;
  }
}
```

### Example 2: Batch Operations with Error Recovery

```javascript
// /ccpm:spec:break-down with comprehensive error handling

async function breakDownSpecIntoTasks(specId) {
  const results = {
    successful: [],
    failed: [],
    skipped: []
  };

  try {
    // Step 1: Fetch spec and parse tasks
    const tasks = await parseSpecTasks(specId);
    console.log(`📊 Found ${tasks.length} tasks to create\n`);

    // Step 2: Validate prerequisites once
    const teamId = tasks[0].teamId;

    // Ensure labels exist (once for all tasks)
    let labels = [];
    try {
      labels = await ensureLabelsExist(teamId, ['task', 'planning']);
    } catch (error) {
      console.warn(`⚠️  Label validation failed: ${error.message}`);
      console.log(`ℹ️  Tasks will be created without labels\n`);
    }

    // Step 3: Create tasks one by one with error handling
    for (let i = 0; i < tasks.length; i++) {
      const task = tasks[i];
      console.log(`[${i + 1}/${tasks.length}] Creating: ${task.title}`);

      try {
        const issue = await mcp__linear__create_issue({
          ...task,
          labelIds: labels
        });

        results.successful.push({
          index: i,
          identifier: issue.identifier,
          title: task.title
        });

        console.log(`  ✅ Created: ${issue.identifier}`);

        // Brief pause to avoid rate limits
        await sleep(500);

      } catch (error) {
        console.error(`  ❌ Failed: ${error.message}`);

        results.failed.push({
          index: i,
          title: task.title,
          error: error.message
        });

        // Ask user how to proceed
        if (i < tasks.length - 1) {
          const shouldContinue = await askContinue(
            `Failed to create task ${i + 1}/${tasks.length}. Continue with remaining tasks?`
          );

          if (!shouldContinue) {
            // Mark remaining as skipped
            for (let j = i + 1; j < tasks.length; j++) {
              results.skipped.push({
                index: j,
                title: tasks[j].title
              });
            }
            break;
          }
        }
      }
    }

    // Step 4: Display comprehensive results
    console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`📊 Breakdown Results`);
    console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`\n✅ Successful: ${results.successful.length}`);
    console.log(`❌ Failed: ${results.failed.length}`);
    console.log(`⏭️  Skipped: ${results.skipped.length}`);

    if (results.successful.length > 0) {
      console.log(`\n✅ Created Tasks:`);
      results.successful.forEach(({ identifier, title }) => {
        console.log(`   • ${identifier}: ${title}`);
      });
    }

    if (results.failed.length > 0) {
      console.log(`\n❌ Failed Tasks:`);
      results.failed.forEach(({ title, error }) => {
        console.log(`   • ${title}`);
        console.log(`     Error: ${error}`);
      });

      console.log(`\n💡 Recovery Options:`);
      console.log(`   1. Fix errors and retry: /ccpm:spec:break-down ${specId}`);
      console.log(`   2. Create failed tasks manually in Linear UI`);
      console.log(`   3. Update spec and try again`);
    }

    return results;

  } catch (error) {
    console.error(`\n❌ Breakdown Failed\n`);
    console.error(error.message);

    if (results.successful.length > 0) {
      console.log(`\nℹ️  Partial Success:`);
      console.log(`   ${results.successful.length} tasks were created successfully`);
      console.log(`   See above for created task IDs`);
    }

    throw error;
  }
}
```

---

## Testing Recommendations

### 1. Unit Tests for Helper Functions

```javascript
// Test state validation error handling
describe('getValidStateId', () => {
  it('should throw helpful error for invalid state', async () => {
    const teamId = 'TEST-TEAM';
    const invalidState = 'NonExistentState';

    await expect(
      getValidStateId(teamId, invalidState)
    ).rejects.toThrow(/Invalid state.*Available states/);
  });

  it('should suggest fallback states in error message', async () => {
    try {
      await getValidStateId('TEST-TEAM', 'invalid');
    } catch (error) {
      expect(error.message).toContain('Available states');
      expect(error.message).toContain('Tip: Use state name');
    }
  });
});
```

### 2. Integration Tests for Linear Operations

```javascript
describe('Label Creation Error Handling', () => {
  it('should handle permission errors gracefully', async () => {
    // Mock Linear MCP to return permission error
    mockLinearMCP.create_issue_label.mockRejectedValue(
      new Error('Permission denied')
    );

    await expect(
      getOrCreateLabel('TEAM-123', 'test-label')
    ).rejects.toThrow(/Permission Denied/);
  });

  it('should retry on network errors', async () => {
    mockLinearMCP.create_issue_label
      .mockRejectedValueOnce(new Error('Network timeout'))
      .mockResolvedValueOnce({ id: 'LABEL-123', name: 'test-label' });

    const label = await retryWithBackoff(() =>
      getOrCreateLabel('TEAM-123', 'test-label')
    );

    expect(label.id).toBe('LABEL-123');
  });
});
```

### 3. End-to-End Error Scenarios

```javascript
describe('Command Error Recovery', () => {
  it('should continue after label creation failure', async () => {
    // Simulate label creation failure
    mockLinearMCP.create_issue_label.mockRejectedValue(
      new Error('Permission denied')
    );

    // But issue creation should succeed
    mockLinearMCP.create_issue.mockResolvedValue({
      id: 'ISSUE-123',
      identifier: 'WORK-123'
    });

    const result = await createAndPlanTask('Test Task', 'test-project');

    // Should have warnings but succeed
    expect(result.hasWarnings).toBe(true);
    expect(result.issue.identifier).toBe('WORK-123');
  });
});
```

### 4. Error Message Quality Tests

```javascript
describe('Error Message Quality', () => {
  it('should include recovery steps in all errors', async () => {
    const errors = [
      'Network timeout',
      'Permission denied',
      'Invalid state',
      'Label creation failed'
    ];

    for (const errorMsg of errors) {
      const error = formatUserError('OPERATION', errorMsg);
      expect(error).toContain('Recovery Steps:');
      expect(error).toContain('1.');
    }
  });

  it('should not expose sensitive information', async () => {
    const error = formatUserError('OPERATION', 'API key abc123xyz invalid');
    expect(error).not.toContain('abc123xyz');
  });
});
```

### 5. Manual Testing Checklist

- [ ] Network disconnection during Linear API call
- [ ] Invalid state name provided by user
- [ ] Permission denied for label creation
- [ ] Team ID doesn't exist
- [ ] Project ID doesn't exist
- [ ] Parent issue ID invalid
- [ ] Rate limit exceeded
- [ ] Linear API timeout
- [ ] Malformed configuration file
- [ ] Missing required MCP server
- [ ] Document not found
- [ ] Document access denied
- [ ] Duplicate issue creation attempt
- [ ] Workflow validation failure
- [ ] Partial batch operation failure

---

## Current Gaps & Improvements

### Identified Gaps

#### 1. **Incomplete Try-Catch Coverage**

**Current State:**
- `_shared-linear-helpers.md` has NO try-catch blocks around Linear MCP calls
- Helper functions assume Linear operations always succeed
- Commands rely on helpers without additional error handling

**Impact:**
- Unhandled exceptions crash commands
- Users see cryptic error messages
- No graceful degradation

**Recommended Fix:**
```javascript
// Current (in shared helpers):
const newLabel = await mcp__linear__create_issue_label({
  name: labelName,
  teamId: teamId,
  color: color,
  description: description
});

// Should be:
let newLabel;
try {
  newLabel = await mcp__linear__create_issue_label({
    name: labelName,
    teamId: teamId,
    color: color,
    description: description
  });
} catch (error) {
  throw new Error(
    `Failed to create label "${labelName}": ${error.message}\n\n` +
    `This may indicate:\n` +
    `  • Insufficient permissions\n` +
    `  • Network connectivity issues\n` +
    `  • Invalid team ID\n\n` +
    `Please verify your Linear access and try again.`
  );
}
```

#### 2. **No Validation Before API Calls**

**Current State:**
- No input validation in helper functions
- No team ID validation
- No null/undefined checks

**Recommended Fix:**
```javascript
async function getValidStateId(teamId, stateNameOrType) {
  // ADD: Input validation
  if (!teamId) {
    throw new Error('Team ID is required');
  }
  if (!stateNameOrType) {
    throw new Error('State name or type is required');
  }

  // Existing code...
}
```

#### 3. **Limited Error Context**

**Current State:**
- Errors don't include operation context
- No debugging information
- Hard to troubleshoot

**Recommended Fix:**
```javascript
try {
  const issue = await mcp__linear__create_issue(params);
} catch (error) {
  // Current: Just re-throw
  throw error;

  // Should be:
  console.error('Linear operation failed:', {
    operation: 'create_issue',
    teamId: params.teamId,
    title: params.title,
    error: error.message
  });

  throw new Error(
    `Issue creation failed: ${error.message}\n\n` +
    `Context:\n` +
    `  • Team: ${params.teamId}\n` +
    `  • Title: ${params.title}\n` +
    `  • Project: ${params.projectId || 'N/A'}\n\n` +
    `Check Linear MCP connection and permissions.`
  );
}
```

#### 4. **No Retry Logic**

**Current State:**
- Network failures immediately fail
- No automatic retry for transient errors
- Users must manually retry entire command

**Recommended Addition:**
```javascript
// Add to shared helpers
async function withRetry(operation, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (error) {
      const isTransient = error.message.includes('network') ||
                         error.message.includes('timeout') ||
                         error.message.includes('503');

      if (!isTransient || i === maxRetries - 1) {
        throw error;
      }

      const delay = Math.pow(2, i) * 1000;
      console.log(`⏳ Retry ${i + 1}/${maxRetries} in ${delay/1000}s...`);
      await sleep(delay);
    }
  }
}
```

#### 5. **No Graceful Degradation**

**Current State:**
- Label creation failure crashes entire command
- State validation failure stops execution
- All-or-nothing approach

**Recommended Pattern:**
```javascript
// Labels are optional - continue without them
let labelIds = [];
try {
  labelIds = await ensureLabelsExist(teamId, labelNames);
} catch (error) {
  console.warn(`⚠️  Could not create labels: ${error.message}`);
  console.log(`ℹ️  Continuing without labels...`);
}

// Create issue with or without labels
const issue = await mcp__linear__create_issue({
  ...params,
  labelIds: labelIds // Empty if labels failed
});
```

#### 6. **Inconsistent Error Messages**

**Current State:**
- Some commands have detailed errors, others generic
- No standard error message template
- Inconsistent formatting

**Recommended Standard:**
```javascript
function formatLinearError(operation, error, context = {}) {
  return (
    `❌ Linear ${operation} Failed\n\n` +
    `${error.message}\n\n` +
    (Object.keys(context).length > 0
      ? `Context:\n${Object.entries(context).map(([k, v]) => `  • ${k}: ${v}`).join('\n')}\n\n`
      : '') +
    `Recovery Steps:\n` +
    `  1. Check Linear MCP connection\n` +
    `  2. Verify permissions and access\n` +
    `  3. Try again or contact support\n`
  );
}
```

#### 7. **No Logging Strategy**

**Current State:**
- Inconsistent console.log usage
- No log levels (debug, info, warn, error)
- Hard to troubleshoot production issues

**Recommended Addition:**
```javascript
const LOG_LEVEL = process.env.CCPM_LOG_LEVEL || 'info';

function log(level, message, context = {}) {
  const levels = ['debug', 'info', 'warn', 'error'];
  if (levels.indexOf(level) < levels.indexOf(LOG_LEVEL)) {
    return;
  }

  const timestamp = new Date().toISOString();
  const contextStr = Object.keys(context).length > 0
    ? `\n${JSON.stringify(context, null, 2)}`
    : '';

  console.log(`[${timestamp}] [${level.toUpperCase()}] ${message}${contextStr}`);
}

// Usage
log('debug', 'Fetching Linear states', { teamId });
log('error', 'State validation failed', { teamId, stateName, error: err.message });
```

### Priority Improvements

#### High Priority (Implement Immediately)

1. **Add try-catch to all helper functions** (1-2 hours)
   - Update `_shared-linear-helpers.md`
   - Wrap all Linear MCP calls
   - Add helpful error messages

2. **Add input validation** (30 minutes)
   - Validate required parameters
   - Add null/undefined checks
   - Validate parameter types

3. **Standardize error messages** (1 hour)
   - Create error message template
   - Update all commands to use template
   - Include recovery steps in all errors

#### Medium Priority (Next Sprint)

4. **Implement graceful degradation** (2-3 hours)
   - Make labels optional
   - Provide fallback states
   - Continue on non-critical failures

5. **Add retry logic** (1-2 hours)
   - Implement exponential backoff
   - Auto-retry on network errors
   - Make retry count configurable

6. **Improve error context** (1 hour)
   - Log operation context
   - Include relevant IDs and values
   - Add debugging information

#### Low Priority (Future Enhancement)

7. **Structured logging** (2-3 hours)
   - Implement log levels
   - Add timestamp and context
   - Make logs searchable

8. **Error analytics** (3-4 hours)
   - Track error frequency
   - Identify common failure patterns
   - Generate error reports

9. **Error recovery automation** (4-5 hours)
   - Auto-fix common errors
   - Suggest fixes based on error type
   - Learn from past recoveries

### Implementation Checklist

**Phase 1: Critical Fixes (Week 1)**
- [ ] Add try-catch to `getOrCreateLabel()`
- [ ] Add try-catch to `getValidStateId()`
- [ ] Add try-catch to `ensureLabelsExist()`
- [ ] Add input validation to all helpers
- [ ] Create error message template
- [ ] Update 2-3 high-traffic commands as examples

**Phase 2: Consistency (Week 2)**
- [ ] Update all 6 commands in PSN-28
- [ ] Update remaining planning commands
- [ ] Update spec commands
- [ ] Update implementation commands
- [ ] Update verification commands

**Phase 3: Enhancements (Week 3)**
- [ ] Implement retry logic
- [ ] Add graceful degradation patterns
- [ ] Improve error logging
- [ ] Add error recovery helpers

**Phase 4: Testing & Documentation (Week 4)**
- [ ] Write unit tests for error scenarios
- [ ] Write integration tests
- [ ] Test all error paths manually
- [ ] Update command documentation
- [ ] Create troubleshooting guide

---

## Conclusion

This guide provides a comprehensive framework for handling Linear integration errors across all CCPM commands. By following these patterns, we ensure:

1. **Consistent UX**: Users always know what went wrong and how to fix it
2. **Graceful Degradation**: Commands continue with reduced functionality when possible
3. **Clear Recovery**: Users have actionable steps for every error
4. **Debuggability**: Errors include enough context for troubleshooting
5. **Reliability**: Retry logic handles transient failures automatically

### Next Steps

1. **Update shared helpers** (`_shared-linear-helpers.md`) with try-catch blocks
2. **Create error message template** file for reuse
3. **Update each command** in PSN-28 to use enhanced error handling
4. **Add tests** for error scenarios
5. **Document common errors** in troubleshooting guide

### Maintenance

- Review error logs monthly for new patterns
- Update recovery strategies based on user feedback
- Keep error messages current with Linear API changes
- Add new error categories as they emerge

---

**Document Version**: 1.0
**Last Review**: 2025-01-20
**Next Review**: 2025-02-20
**Owner**: CCPM Development Team
