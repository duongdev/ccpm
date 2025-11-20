# Troubleshooting Linear Integration

**Complete guide to diagnosing and fixing Linear integration issues in CCPM**

Last Updated: 2025-01-20
Applies To: CCPM v2.1+

---

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Common Issues](#common-issues)
3. [Error Messages Reference](#error-messages-reference)
4. [Recovery Procedures](#recovery-procedures)
5. [Prevention Best Practices](#prevention-best-practices)

---

## Quick Diagnostics

### Is Linear MCP Connected?

```bash
# Test Linear MCP connection
echo "List my Linear teams" | claude

# Expected: Returns your Linear teams
# If fails: See MCP Connection Issues below
```

### Are Shared Helpers Working?

```bash
# In Claude Code, test helper functions
READ: commands/_shared-linear-helpers.md

# Test color lookup (pure function - always works)
const color = getDefaultColor("planning");
console.log(color); // Should output: #f7c8c1
```

### Is Your Project Configured Correctly?

```bash
# Check project configuration
/ccpm:project:show your-project

# Verify:
# - linear.team matches your Linear team name (case-sensitive)
# - linear.project matches your Linear project name
```

---

## Common Issues

### 1. State Resolution Failures

**Symptoms:**
- Error: `Invalid state: "Backlog"`
- Commands fail when creating/updating issues
- State names don't match your workflow

**Causes:**
- Team uses custom workflow state names
- State name typo in command
- State doesn't exist in team's workflow

**Solution:**

```bash
# 1. Check your team's actual workflow states
# In Claude Code:
const states = await mcp__linear__list_issue_statuses({
  team: "YOUR-TEAM-ID"
});
console.log(states.map(s => `${s.name} (${s.type})`));

# 2. Use the correct state name or type
# Examples of what works:
# - Exact name: "In Progress"
# - State type: "started"
# - Common aliases: "todo", "done", "blocked"

# 3. Update commands to use getValidStateId()
# This helper provides fuzzy matching and helpful errors
```

**Prevention:**
- Always use `getValidStateId()` instead of hardcoded state IDs
- Use state types (`backlog`, `unstarted`, `started`, `completed`, `canceled`) instead of names
- Test state resolution before creating issues

**Related Documentation:**
- [Shared Linear Helpers - getValidStateId()](../../commands/_shared-linear-helpers.md#2-getvalidstateid)
- [Error Handling Guide - State Validation Errors](../development/linear-error-handling-guide.md#2-state-validation-errors)

---

### 2. Label Creation Failures

**Symptoms:**
- Error: `Permission denied`
- Labels not appearing on issues
- Commands complete but labels missing

**Causes:**
- Insufficient permissions to create labels
- Label name conflicts (rare)
- Team configuration issues

**Solution:**

```bash
# 1. Check your permissions
# You need "can manage labels" permission in Linear

# 2. Try creating label manually in Linear UI
# This confirms permission issue vs. API issue

# 3. Use getOrCreateLabel() which handles existing labels
# In command:
const label = await getOrCreateLabel(teamId, "planning");
# This will reuse existing labels instead of failing

# 4. If permissions are the issue:
# Option A: Request label creation permissions from team admin
# Option B: Have admin pre-create labels
# Option C: Commands can proceed without labels (graceful degradation)
```

**Prevention:**
- Use `ensureLabelsExist()` for batch label operations
- Implement graceful degradation (continue without labels)
- Pre-create common labels in team settings

**Related Documentation:**
- [Shared Linear Helpers - getOrCreateLabel()](../../commands/_shared-linear-helpers.md#1-getorcreat elabel)
- [Error Handling Guide - Label Creation Errors](../development/linear-error-handling-guide.md#3-label-creation-errors)

---

### 3. Team/Project Resolution Failures

**Symptoms:**
- Error: `Team not found`
- Error: `Project doesn't exist`
- Commands can't create issues

**Causes:**
- Invalid team ID in configuration
- Team ID doesn't match team key
- Project name typo (case-sensitive)
- No access to specified team

**Solution:**

```bash
# 1. List your accessible teams
# In Claude Code:
const teams = await mcp__linear__list_teams();
console.log(teams.map(t => `${t.name} (${t.key})`));

# 2. Use team KEY not ID for configuration
# Correct: team: "WORK" (the team key)
# Wrong: team: "abc123..." (the team ID)

# 3. List projects in the team
const projects = await mcp__linear__list_projects({
  team: "WORK"
});
console.log(projects.map(p => p.name));

# 4. Update your project configuration
/ccpm:project:update your-project --field linear

# Enter:
# - Team: WORK (exact match from Linear)
# - Project: My Application (exact match from Linear)
```

**Prevention:**
- Always use team keys (WORK, ENG, etc.) not team IDs
- Project names are case-sensitive - match exactly
- Verify access in Linear web UI first

**Related Documentation:**
- [Project Setup Guide](project-setup.md)
- [Error Handling Guide - Team/Project Resolution Errors](../development/linear-error-handling-guide.md#4-teamproject-resolution-errors)

---

### 4. Issue Creation Failures

**Symptoms:**
- Error: `Missing required fields`
- Error: `Invalid parent issue`
- Issues not appearing in Linear

**Causes:**
- Missing title or teamId
- Invalid parent issue ID (for subtasks)
- Workflow validation failures
- Duplicate issue detection

**Solution:**

```bash
# 1. Verify required fields
# Minimum required:
# - teamId (team key like "WORK")
# - title (non-empty string)

# 2. Check parent issue exists
# If creating subtask:
const parent = await mcp__linear__get_issue({ id: "WORK-123" });
console.log(parent.id); // Use this as parentId

# 3. Validate state and labels first
const stateId = await getValidStateId(teamId, "Backlog");
const labels = await ensureLabelsExist(teamId, ["planning"]);

# 4. Create with validated data
const issue = await mcp__linear__create_issue({
  teamId: teamId,
  title: "Your task title",
  stateId: stateId,
  labelIds: labels,
  description: "Task description"
});
```

**Prevention:**
- Always validate inputs before Linear API calls
- Use helper functions for state and label validation
- Check parent issues exist before creating subtasks
- Use try-catch for graceful error handling

**Related Documentation:**
- [Error Handling Guide - Issue Creation/Update Errors](../development/linear-error-handling-guide.md#5-issue-creationupdate-errors)
- [Shared Linear Helpers - Integration Examples](../../commands/_shared-linear-helpers.md#integration-examples)

---

### 5. Document Operations Failures

**Symptoms:**
- Error: `Document not found`
- Error: `Access denied`
- Can't read or update spec documents

**Causes:**
- Invalid document ID
- Document was deleted
- Insufficient permissions
- Document not shared with you

**Solution:**

```bash
# 1. Verify document ID
# Document IDs look like: DOC-abc123 or similar
# Check Linear UI for correct ID

# 2. Check document exists and you have access
# Try opening in Linear web UI first

# 3. Check document is linked to issue
const issue = await mcp__linear__get_issue({ id: "WORK-123" });
console.log(issue.documentId); // Should show linked document

# 4. Request access if needed
# Ask document owner to share with you
# Or request team-level access
```

**Prevention:**
- Verify document IDs before operations
- Check document permissions in Linear UI
- Use proper error handling for document operations
- Link documents to issues for easier reference

**Related Documentation:**
- [Spec Management Guide](../../commands/SPEC_MANAGEMENT_SUMMARY.md)
- [Error Handling Guide - Document Operations Errors](../development/linear-error-handling-guide.md#6-document-operations-errors)

---

### 6. MCP Connection Issues

**Symptoms:**
- Error: `Linear MCP server not found`
- Timeout errors
- Network connection errors

**Causes:**
- Linear MCP not configured
- Invalid API key
- Network connectivity issues
- Linear API downtime

**Solution:**

```bash
# 1. Check MCP configuration
cat ~/.claude/settings.json | grep -A 10 "linear"

# Should show:
# "linear": {
#   "command": "npx",
#   "args": ["-y", "@lucitra/linear-mcp"],
#   "env": {
#     "LINEAR_API_KEY": "lin_api_..."
#   }
# }

# 2. Verify API key is valid
# Get new key from: https://linear.app/settings/api

# 3. Test MCP connection
echo "List my Linear teams" | claude
# Should return teams without errors

# 4. Restart Claude Code
# Sometimes MCP servers need restart

# 5. Check Linear API status
# Visit: https://status.linear.app
```

**Prevention:**
- Keep API key in environment variable (more secure)
- Test MCP connection after configuration changes
- Monitor Linear API status for outages
- Implement retry logic for transient errors

**Related Documentation:**
- [MCP Integration Guide](mcp-integration.md)
- [Error Handling Guide - Linear API Errors](../development/linear-error-handling-guide.md#1-linear-api-errors)

---

## Error Messages Reference

### State-Related Errors

#### "Invalid state: 'Backlog'"

**Full Error:**
```
Invalid state: "Backlog"

Available states for this team:
  - Todo (type: unstarted)
  - In Progress (type: started)
  - Done (type: completed)
  - Canceled (type: canceled)

Tip: Use state name (e.g., "In Progress") or type (e.g., "started")
```

**What This Means:**
- The state name "Backlog" doesn't exist in your team's workflow
- Your team uses different state names

**How to Fix:**
1. Use one of the available state names shown in the error
2. Or use state type: `getValidStateId(teamId, "unstarted")`
3. Or update your command to use correct state name

**Prevention:**
- Use state types instead of names (more portable)
- Use `getValidStateId()` which provides fuzzy matching

---

#### "No workflow states found for team"

**What This Means:**
- Team ID is invalid or you don't have access
- Team workflow configuration is broken

**How to Fix:**
1. Verify team ID: `/ccpm:project:show your-project`
2. List accessible teams: `mcp__linear__list_teams()`
3. Update project configuration with correct team

---

### Label-Related Errors

#### "Permission denied: cannot create labels"

**What This Means:**
- Your Linear account doesn't have label creation permissions
- Team settings restrict label creation

**How to Fix:**
1. Request "can manage labels" permission from admin
2. Have admin pre-create needed labels
3. Use commands with graceful degradation (continue without labels)

**Prevention:**
- Pre-create common workflow labels
- Use `getOrCreateLabel()` which handles existing labels

---

#### "Label creation failed: network error"

**What This Means:**
- Temporary network connectivity issue
- Linear API timeout

**How to Fix:**
1. Retry the operation
2. Check internet connection
3. Wait a moment and try again

**Prevention:**
- Implement retry logic with exponential backoff
- Handle network errors gracefully

---

### Team/Project Errors

#### "Team not found: WORK"

**What This Means:**
- Team key "WORK" doesn't exist
- You don't have access to this team
- Team was deleted or archived

**How to Fix:**
1. List your teams: `mcp__linear__list_teams()`
2. Use correct team key from the list
3. Update project configuration: `/ccpm:project:update`

---

#### "Project not found in team"

**What This Means:**
- Project name doesn't match exactly (case-sensitive)
- Project was deleted or archived
- Project is in different team

**How to Fix:**
1. List team's projects: `mcp__linear__list_projects({ team: "WORK" })`
2. Use exact project name from the list
3. Update project configuration

---

### Issue Creation Errors

#### "Missing required fields: teamId and title are required"

**What This Means:**
- Issue creation called without required parameters

**How to Fix:**
```javascript
// Ensure both fields are provided:
await mcp__linear__create_issue({
  teamId: "WORK",  // Required
  title: "Task title",  // Required
  // ... other optional fields
});
```

---

#### "Invalid parent issue ID"

**What This Means:**
- Parent issue doesn't exist
- Parent issue ID is malformed
- No access to parent issue

**How to Fix:**
1. Verify parent exists: `mcp__linear__get_issue({ id: "WORK-123" })`
2. Use valid issue ID or identifier
3. Create without parent if not needed

---

### Document Errors

#### "Document not found: DOC-123"

**What This Means:**
- Document ID is incorrect
- Document was deleted
- You don't have access

**How to Fix:**
1. Check document ID in Linear UI
2. Verify document still exists
3. Request access if needed
4. Link new document to issue

---

## Recovery Procedures

### Procedure 1: Fix Failed Issue Creation

**Scenario:** Issue creation failed midway through planning

```bash
# 1. Check if issue was partially created
# Search Linear for issue title

# 2. If found, continue with existing issue
/ccpm:planning:plan WORK-123

# 3. If not found, retry creation
/ccpm:planning:create "Task title" your-project

# 4. If retry fails, create manually then run planning
# Create in Linear UI, then:
/ccpm:planning:plan WORK-123
```

---

### Procedure 2: Fix Missing Labels

**Scenario:** Labels didn't get created but issue exists

```bash
# 1. Create labels manually or via helper
const labels = await ensureLabelsExist(teamId, [
  "planning",
  "implementation",
  "verification"
]);

# 2. Add labels to existing issue
await mcp__linear__update_issue({
  id: "WORK-123",
  labelIds: labels
});

# 3. Verify labels appear
const issue = await mcp__linear__get_issue({ id: "WORK-123" });
console.log(issue.labels);
```

---

### Procedure 3: Fix State Mismatch

**Scenario:** Issue in wrong state after command execution

```bash
# 1. Get correct state ID
const correctStateId = await getValidStateId(teamId, "In Progress");

# 2. Update issue state
await mcp__linear__update_issue({
  id: "WORK-123",
  stateId: correctStateId
});

# 3. Verify state change
const issue = await mcp__linear__get_issue({ id: "WORK-123" });
console.log(issue.state.name);
```

---

### Procedure 4: Recover from Partial Batch Operation

**Scenario:** `spec:break-down` created 5/10 tasks before failing

```bash
# 1. List what was created
/ccpm:utils:report your-project

# 2. Identify missing tasks
# Compare with spec document

# 3. Create missing tasks manually
/ccpm:planning:create "Missing task 6" your-project
/ccpm:planning:create "Missing task 7" your-project
# ... etc

# 4. Link to parent Epic/Feature
# Update parentId in Linear UI or via API
```

---

### Procedure 5: Reset After Failed Planning

**Scenario:** Planning failed with incomplete data in Linear

```bash
# 1. Use rollback if available
/ccpm:utils:rollback WORK-123

# 2. Or manually reset issue
# In Linear UI:
# - Clear description
# - Remove labels
# - Reset to "Backlog" state

# 3. Re-run planning
/ccpm:planning:plan WORK-123
```

---

## Prevention Best Practices

### 1. Always Validate Before Creating

```javascript
// DON'T: Direct creation with assumptions
await mcp__linear__create_issue({
  teamId: "WORK",
  title: title,
  stateId: "state_12345",  // Hardcoded - breaks if workflow changes
  labelIds: ["label_67890"]  // Assumes label exists
});

// DO: Validate first
const stateId = await getValidStateId(teamId, "Backlog");
const labels = await ensureLabelsExist(teamId, ["planning"]);

await mcp__linear__create_issue({
  teamId: teamId,
  title: title,
  stateId: stateId,  // Validated
  labelIds: labels  // Guaranteed to exist
});
```

---

### 2. Implement Graceful Degradation

```javascript
// Labels are optional - don't fail entire operation
let labelIds = [];
try {
  labelIds = await ensureLabelsExist(teamId, ["planning", "research"]);
} catch (error) {
  console.warn(`⚠️  Could not create labels: ${error.message}`);
  console.log(`ℹ️  Continuing without labels...`);
  // Continue execution
}

// Create issue with or without labels
const issue = await mcp__linear__create_issue({
  ...params,
  labelIds: labelIds  // Empty if labels failed, populated if succeeded
});
```

---

### 3. Use Descriptive Error Messages

```javascript
try {
  const issue = await mcp__linear__create_issue(params);
} catch (error) {
  // DON'T: Generic error
  throw error;

  // DO: Contextual error
  throw new Error(
    `❌ Issue Creation Failed\n\n` +
    `Unable to create issue "${params.title}" in team ${params.teamId}.\n\n` +
    `Error: ${error.message}\n\n` +
    `Recovery Steps:\n` +
    `  1. Verify team ID is correct\n` +
    `  2. Check Linear MCP connection\n` +
    `  3. Try creating manually in Linear UI`
  );
}
```

---

### 4. Test Configuration Before First Use

```bash
# When setting up new project, test configuration:

# 1. Test team access
const teams = await mcp__linear__list_teams();
console.log("Accessible teams:", teams.map(t => t.key));

# 2. Test state resolution
const testState = await getValidStateId("WORK", "Backlog");
console.log("State validation works:", testState);

# 3. Test label creation
const testLabel = await getOrCreateLabel("WORK", "test-label");
console.log("Label creation works:", testLabel);

# 4. Clean up test data
await mcp__linear__delete_issue_label({ id: testLabel.id });
```

---

### 5. Keep Helper Functions Updated

```bash
# Always load latest helpers
READ: commands/_shared-linear-helpers.md

# Check for updates regularly
# Helpers may add new features or fix bugs
```

---

### 6. Monitor Linear API Status

```bash
# Before big operations, check Linear status:
# https://status.linear.app

# If degraded performance, consider:
# - Waiting for resolution
# - Reducing batch sizes
# - Adding retry logic
```

---

### 7. Use Team Test Environments

```bash
# For testing and development:
# 1. Create "Test" team in Linear
# 2. Configure separate project in CCPM
# 3. Test commands there first
# 4. Deploy to production team after validation

/ccpm:project:add my-app-test --template fullstack-with-jira
# Use test team for LINEAR_TEAM
```

---

## Getting Help

If issues persist after following this guide:

1. **Enable verbose logging**
   ```bash
   claude --verbose
   ```

2. **Collect diagnostic information**
   ```bash
   # Project configuration
   /ccpm:project:show your-project > project-config.txt

   # Linear connection test
   echo "List my Linear teams" | claude > linear-test.txt

   # Error logs from verbose mode
   ```

3. **Check related documentation**
   - [Linear Error Handling Guide](../development/linear-error-handling-guide.md)
   - [Shared Linear Helpers](../../commands/_shared-linear-helpers.md)
   - [MCP Integration Guide](mcp-integration.md)

4. **Report the issue**
   - GitHub Issues: Include diagnostic info (remove sensitive data)
   - Include steps to reproduce
   - Include error messages and logs

5. **Community support**
   - Check existing issues for similar problems
   - Ask in discussions for non-bug questions

---

## Quick Reference

### Helpful Commands

```bash
# Check project configuration
/ccpm:project:show your-project

# Test Linear connection
echo "List my Linear teams" | claude

# List available states
# In Claude Code:
const states = await mcp__linear__list_issue_statuses({ team: "WORK" });

# List available labels
const labels = await mcp__linear__list_issue_labels({ team: "WORK" });

# Validate state
const stateId = await getValidStateId("WORK", "Backlog");

# Create label
const label = await getOrCreateLabel("WORK", "planning");
```

### Common Fixes

| Issue | Quick Fix |
|-------|-----------|
| Invalid state | Use `getValidStateId(teamId, "backlog")` |
| Permission denied | Request admin permissions or pre-create labels |
| Team not found | Use team key (WORK) not team ID |
| MCP not connected | Check `~/.claude/settings.json` and restart |
| Labels missing | Use `ensureLabelsExist(teamId, ["label1"])` |
| Wrong state type | Use types: `backlog`, `unstarted`, `started`, `completed`, `canceled` |

---

**Document Version:** 1.0
**Last Updated:** 2025-01-20
**Maintained By:** CCPM Development Team
**Related Issue:** PSN-28
