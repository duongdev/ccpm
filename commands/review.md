---
description: Interactive AI-powered code review with Linear integration
allowed-tools: [Bash, Task, AskUserQuestion, Read, Grep, Glob]
argument-hint: "[--staged] [--branch=X] [--file=X] [--severity=X]"
---

# /ccpm:review - Interactive Code Review

AI-powered code review that analyzes changes and provides actionable feedback.

## Agents Used

This command uses specialized agents for comprehensive review:
- `ccpm:code-reviewer` - Primary review agent (quality, bugs, style)
- `ccpm:security-auditor` - Security vulnerability detection (with `--security` flag)
- `ccpm:linear-operations` - Post findings to Linear (with `--post-to-linear`)

## Usage

```bash
# Review staged changes
/ccpm:review --staged

# Review current branch against main
/ccpm:review

# Review specific branch
/ccpm:review --branch=feature/psn-29-auth

# Review specific file
/ccpm:review --file=src/auth/jwt.ts

# Set severity threshold (info, warning, error)
/ccpm:review --severity=warning

# Review and post to Linear
/ccpm:review --post-to-linear
```

## Implementation

### Step 1: Parse Arguments

```javascript
let options = {
  staged: false,
  branch: null,
  file: null,
  severity: 'info',  // info, warning, error
  postToLinear: false
};

for (const arg of args) {
  if (arg === '--staged') {
    options.staged = true;
  } else if (arg.startsWith('--branch=')) {
    options.branch = arg.replace('--branch=', '');
  } else if (arg.startsWith('--file=')) {
    options.file = arg.replace('--file=', '');
  } else if (arg.startsWith('--severity=')) {
    options.severity = arg.replace('--severity=', '');
  } else if (arg === '--post-to-linear') {
    options.postToLinear = true;
  }
}

// Default: review current branch against main
if (!options.staged && !options.branch && !options.file) {
  options.branch = await Bash('git rev-parse --abbrev-ref HEAD');
}
```

### Step 2: Gather Changes

```javascript
let changes = [];
let diffOutput = '';

if (options.staged) {
  // Staged changes only
  diffOutput = await Bash('git diff --cached --name-only');
} else if (options.file) {
  // Specific file
  diffOutput = options.file;
} else if (options.branch) {
  // Branch comparison
  const baseBranch = 'main';
  diffOutput = await Bash(`git diff --name-only ${baseBranch}...${options.branch.trim()}`);
}

const changedFiles = diffOutput.trim().split('\n').filter(f => f.length > 0);

if (changedFiles.length === 0) {
  console.log('✅ No changes to review.\n');
  console.log('💡 Try:');
  console.log('   /ccpm:review --staged  - Review staged changes');
  console.log('   /ccpm:review --file=path/to/file.ts');
  return;
}

console.log('═══════════════════════════════════════');
console.log('🔍 Code Review');
console.log('═══════════════════════════════════════\n');

console.log(`📁 ${changedFiles.length} file(s) to review:\n`);
changedFiles.forEach(f => console.log(`   • ${f}`));
console.log('');
```

### Step 3: Analyze Each File

```javascript
const findings = [];

for (const file of changedFiles.slice(0, 10)) {  // Limit to 10 files
  console.log(`\n🔍 Reviewing: ${file}...`);

  // Get file extension for language detection
  const ext = file.split('.').pop();
  const language = getLanguage(ext);

  // Get the diff for this file
  let diff;
  if (options.staged) {
    diff = await Bash(`git diff --cached -- "${file}"`);
  } else if (options.branch) {
    diff = await Bash(`git diff main...${options.branch.trim()} -- "${file}"`);
  } else {
    diff = await Bash(`git diff HEAD -- "${file}"`);
  }

  // Get full file content for context
  const content = await Read(file).catch(() => null);

  // Use code-reviewer agent for analysis
  const reviewResult = await Task({
    subagent_type: 'full-stack-orchestration:code-reviewer',
    prompt: `
## Code Review Request

**File**: ${file}
**Language**: ${language}

### Diff
\`\`\`diff
${diff}
\`\`\`

### Full File (for context)
\`\`\`${language}
${content?.substring(0, 5000) || 'File not readable'}
\`\`\`

### Review Criteria

Please analyze for:

1. **Security Issues** (severity: error)
   - SQL injection, XSS, command injection
   - Hardcoded secrets, insecure defaults
   - Missing input validation

2. **Bugs** (severity: error)
   - Logic errors, null pointer risks
   - Race conditions, memory leaks
   - Unhandled exceptions

3. **Code Quality** (severity: warning)
   - Code duplication
   - Complex functions (cyclomatic complexity)
   - Missing error handling
   - Unclear naming

4. **Best Practices** (severity: info)
   - TypeScript type safety
   - Missing documentation for public APIs
   - Deprecated APIs usage
   - Performance concerns

### Output Format

Return findings as JSON array:
\`\`\`json
[
  {
    "line": 42,
    "severity": "error|warning|info",
    "category": "security|bug|quality|practice",
    "message": "Description of the issue",
    "suggestion": "How to fix it"
  }
]
\`\`\`

If no issues found, return empty array: []
`
  });

  // Parse findings
  try {
    const fileFindings = JSON.parse(reviewResult.match(/\[[\s\S]*\]/)?.[0] || '[]');
    fileFindings.forEach(f => {
      f.file = file;
      findings.push(f);
    });
  } catch (e) {
    // Agent returned prose instead of JSON - extract key points
    console.log(`   ⚠️ Could not parse structured findings`);
  }
}
```

### Step 4: Filter and Group Findings

```javascript
// Filter by severity threshold
const severityOrder = { 'error': 3, 'warning': 2, 'info': 1 };
const thresholdLevel = severityOrder[options.severity] || 1;

const filteredFindings = findings.filter(f =>
  severityOrder[f.severity] >= thresholdLevel
);

// Group by file
const byFile = {};
filteredFindings.forEach(f => {
  if (!byFile[f.file]) byFile[f.file] = [];
  byFile[f.file].push(f);
});

// Count by severity
const counts = {
  error: filteredFindings.filter(f => f.severity === 'error').length,
  warning: filteredFindings.filter(f => f.severity === 'warning').length,
  info: filteredFindings.filter(f => f.severity === 'info').length
};
```

### Step 5: Display Results

```javascript
console.log('\n═══════════════════════════════════════');
console.log('📋 Review Summary');
console.log('═══════════════════════════════════════\n');

// Summary bar
if (counts.error > 0) {
  console.log(`🔴 ${counts.error} error(s)`);
}
if (counts.warning > 0) {
  console.log(`🟡 ${counts.warning} warning(s)`);
}
if (counts.info > 0) {
  console.log(`🔵 ${counts.info} info`);
}

if (filteredFindings.length === 0) {
  console.log('✅ No issues found!\n');
  console.log('Great job! Your code passes all checks.');
  return;
}

console.log('');

// Display findings by file
for (const [file, fileFindings] of Object.entries(byFile)) {
  console.log(`\n📁 ${file}`);
  console.log('───────────────────────────────────────');

  fileFindings.forEach(f => {
    const icon = f.severity === 'error' ? '🔴' : f.severity === 'warning' ? '🟡' : '🔵';
    const category = `[${f.category.toUpperCase()}]`;

    console.log(`\n${icon} Line ${f.line}: ${category}`);
    console.log(`   ${f.message}`);
    if (f.suggestion) {
      console.log(`   💡 ${f.suggestion}`);
    }
  });
}

// Overall assessment
console.log('\n═══════════════════════════════════════');
console.log('📊 Assessment');
console.log('═══════════════════════════════════════\n');

if (counts.error > 0) {
  console.log('❌ Review Status: NEEDS WORK');
  console.log('   Errors must be fixed before merging.');
} else if (counts.warning > 5) {
  console.log('⚠️ Review Status: NEEDS ATTENTION');
  console.log('   Consider addressing warnings before merging.');
} else {
  console.log('✅ Review Status: APPROVED');
  console.log('   Minor suggestions can be addressed if time permits.');
}
```

### Step 6: Post to Linear (Optional)

```javascript
if (options.postToLinear && filteredFindings.length > 0) {
  // Detect issue from branch
  const branch = options.branch || await Bash('git rev-parse --abbrev-ref HEAD');
  const issueMatch = branch.match(/([A-Z]+-\d+)/);

  if (issueMatch) {
    const issueId = issueMatch[1];

    console.log(`\n📤 Posting review to Linear issue ${issueId}...`);

    // Format findings for Linear
    const findingsMarkdown = Object.entries(byFile).map(([file, fileFindings]) => {
      const items = fileFindings.map(f => {
        const icon = f.severity === 'error' ? '🔴' : f.severity === 'warning' ? '🟡' : '🔵';
        return `- ${icon} Line ${f.line}: ${f.message}`;
      }).join('\n');

      return `**${file}**\n${items}`;
    }).join('\n\n');

    await Task({
      subagent_type: 'ccpm:linear-operations',
      prompt: `operation: create_comment
params:
  issueId: ${issueId}
  body: |
    🔍 **Code Review** | ${changedFiles.length} files

    **Summary**: ${counts.error} errors, ${counts.warning} warnings, ${counts.info} info

    +++ 📋 Detailed Findings

    ${findingsMarkdown}

    +++
context:
  command: review`
    });

    console.log(`✅ Review posted to ${issueId}`);
  } else {
    console.log('\n⚠️ Could not detect issue ID from branch. Use --post-to-linear with an issue branch.');
  }
}
```

### Step 7: Interactive Fix Suggestions

```javascript
if (counts.error > 0) {
  const answer = await AskUserQuestion({
    questions: [{
      question: "Would you like AI to help fix the errors?",
      header: "Fix Errors",
      multiSelect: false,
      options: [
        { label: "Yes, fix all errors", description: "AI will apply fixes automatically" },
        { label: "Fix one at a time", description: "Review each fix before applying" },
        { label: "No, I'll fix manually", description: "Just show the issues" }
      ]
    }]
  });

  if (answer === "Yes, fix all errors" || answer === "Fix one at a time") {
    const errorFindings = filteredFindings.filter(f => f.severity === 'error');
    const fixOneAtATime = (answer === "Fix one at a time");

    for (const finding of errorFindings) {
      console.log(`\n🔧 Fixing: ${finding.file}:${finding.line}`);
      console.log(`   ${finding.message}`);

      if (fixOneAtATime) {
        const confirm = await AskUserQuestion({
          questions: [{
            question: `Apply fix: ${finding.suggestion}?`,
            header: "Confirm Fix",
            multiSelect: false,
            options: [
              { label: "Apply", description: "Apply this fix" },
              { label: "Skip", description: "Skip this fix" }
            ]
          }]
        });

        if (confirm === "Skip") continue;
      }

      // Apply fix via specialized agent
      await Task({
        subagent_type: 'general-purpose',
        prompt: `
Fix this code issue in ${finding.file} at line ${finding.line}:

Issue: ${finding.message}
Suggestion: ${finding.suggestion}

Apply the fix directly using the Edit tool.
`
      });

      console.log(`   ✅ Fixed`);
    }

    console.log('\n✅ All selected fixes applied.');
    console.log('💡 Run /ccpm:review again to verify.');
  }
}
```

### Helper Functions

```javascript
function getLanguage(ext) {
  const map = {
    'ts': 'typescript',
    'tsx': 'typescript',
    'js': 'javascript',
    'jsx': 'javascript',
    'py': 'python',
    'rb': 'ruby',
    'go': 'go',
    'rs': 'rust',
    'java': 'java',
    'kt': 'kotlin',
    'swift': 'swift',
    'php': 'php',
    'cs': 'csharp',
    'cpp': 'cpp',
    'c': 'c',
    'md': 'markdown',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml'
  };
  return map[ext] || 'text';
}
```

## Example Output

```
═══════════════════════════════════════
🔍 Code Review
═══════════════════════════════════════

📁 3 file(s) to review:

   • src/auth/jwt.ts
   • src/auth/middleware.ts
   • src/routes/auth.ts

🔍 Reviewing: src/auth/jwt.ts...
🔍 Reviewing: src/auth/middleware.ts...
🔍 Reviewing: src/routes/auth.ts...

═══════════════════════════════════════
📋 Review Summary
═══════════════════════════════════════

🔴 2 error(s)
🟡 3 warning(s)
🔵 5 info

📁 src/auth/jwt.ts
───────────────────────────────────────

🔴 Line 42: [SECURITY]
   JWT secret is hardcoded in source code
   💡 Use environment variable: process.env.JWT_SECRET

🟡 Line 58: [QUALITY]
   Token expiry is very short (5 minutes)
   💡 Consider 15-30 minutes for better UX

📁 src/routes/auth.ts
───────────────────────────────────────

🔴 Line 23: [BUG]
   Missing null check on user.email
   💡 Add: if (!user?.email) return res.status(400)...

═══════════════════════════════════════
📊 Assessment
═══════════════════════════════════════

❌ Review Status: NEEDS WORK
   Errors must be fixed before merging.

Would you like AI to help fix the errors?
  > Yes, fix all errors
    Fix one at a time
    No, I'll fix manually
```

## Review Categories

| Category | Severity | Examples |
|----------|----------|----------|
| Security | error | SQL injection, XSS, hardcoded secrets |
| Bug | error | Null pointer, logic error, race condition |
| Quality | warning | Duplication, complexity, missing error handling |
| Practice | info | Type safety, documentation, deprecation |

## Integration

- Uses `code-reviewer` agent for deep analysis
- Posts findings to Linear with `+++ collapsible` syntax
- Integrates with `/ccpm:verify` workflow
- Supports auto-fix via specialized agents
