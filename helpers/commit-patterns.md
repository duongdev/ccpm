# Commit Pattern Analyzer Helper

This helper analyzes git history to detect project-specific commit patterns and conventions.

## Purpose

Automatically learn commit conventions from project history to:
- Suggest appropriate commit types, scopes, and formats
- Maintain consistency with existing commits
- Respect project-specific conventions beyond CLAUDE.md rules

## Usage

### In Commands

```javascript
// Analyze recent commits and get pattern recommendations
const patterns = analyzeCommitPatterns();

// Use patterns to suggest commit message
const suggestion = suggestCommitMessage(patterns, changes);
```

### Pattern Detection Algorithm

```javascript
/**
 * Analyze git history to detect commit patterns
 * @param {number} limit - Number of recent commits to analyze (default: 50)
 * @returns {CommitPatterns} Detected patterns
 */
async function analyzeCommitPatterns(limit = 50) {
  // Get recent commit messages
  const gitLog = await Bash(`git log --oneline -${limit} --format="%s"`);
  const commits = gitLog.split('\n').filter(c => c.trim());

  const patterns = {
    // Format detection
    format: 'unknown',           // 'conventional', 'angular', 'emoji', 'simple'
    usesScope: false,            // feat(scope): message
    usesEmoji: false,            // :emoji: or emoji prefix
    usesIssueRef: false,         // #123 or PROJ-123 in message

    // Type frequency (for conventional commits)
    types: {},                   // { feat: 15, fix: 10, docs: 5, ... }
    typeOrder: [],               // ['feat', 'fix', 'docs', ...] by frequency

    // Scope analysis
    scopes: {},                  // { hooks: 8, ci: 5, commands: 3, ... }
    scopeOrder: [],              // ['hooks', 'ci', ...] by frequency

    // Style patterns
    capitalization: 'lower',     // 'lower', 'upper', 'sentence'
    maxLength: 72,               // Detected max subject length
    usesBody: false,             // Multi-line commits detected

    // Issue reference patterns
    issuePatterns: [],           // ['WORK-', 'PSN-', '#']
    issuePosition: 'scope',      // 'scope', 'prefix', 'suffix', 'none'

    // Raw data for advanced analysis
    sampleCommits: [],           // Last 10 commits for reference
    confidence: 0                // 0-100 confidence in detection
  };

  // === CONVENTIONAL COMMIT DETECTION ===
  const conventionalRegex = /^(\w+)(?:\(([^)]+)\))?(!)?:\s*(.+)$/;
  const emojiRegex = /^(:[\w+-]+:|[\u{1F300}-\u{1F9FF}])/u;
  const issueRefRegex = /([A-Z]+-\d+|#\d+)/g;

  let conventionalCount = 0;
  let emojiCount = 0;
  let scopeCount = 0;
  let issueRefCount = 0;

  for (const commit of commits) {
    // Check for conventional commits
    const conventionalMatch = commit.match(conventionalRegex);
    if (conventionalMatch) {
      conventionalCount++;
      const [, type, scope, breaking, description] = conventionalMatch;

      // Track type frequency
      patterns.types[type] = (patterns.types[type] || 0) + 1;

      // Track scope frequency
      if (scope) {
        scopeCount++;
        patterns.scopes[scope] = (patterns.scopes[scope] || 0) + 1;
      }

      // Check capitalization of description
      if (description) {
        const firstChar = description.charAt(0);
        if (firstChar === firstChar.toUpperCase() && firstChar !== firstChar.toLowerCase()) {
          patterns.capitalization = 'sentence';
        }
      }
    }

    // Check for emoji
    if (emojiRegex.test(commit)) {
      emojiCount++;
    }

    // Check for issue references
    const issueMatches = commit.match(issueRefRegex);
    if (issueMatches) {
      issueRefCount++;
      for (const match of issueMatches) {
        if (match.startsWith('#')) {
          if (!patterns.issuePatterns.includes('#')) {
            patterns.issuePatterns.push('#');
          }
        } else {
          const prefix = match.replace(/\d+$/, '');
          if (!patterns.issuePatterns.includes(prefix)) {
            patterns.issuePatterns.push(prefix);
          }
        }
      }
    }
  }

  // === DETERMINE FORMAT ===
  const total = commits.length;
  if (total === 0) {
    patterns.format = 'conventional'; // Default for new repos
    patterns.confidence = 50;
    return patterns;
  }

  const conventionalRatio = conventionalCount / total;
  const emojiRatio = emojiCount / total;

  if (conventionalRatio >= 0.7) {
    patterns.format = 'conventional';
    patterns.confidence = Math.round(conventionalRatio * 100);
  } else if (emojiRatio >= 0.5) {
    patterns.format = 'emoji';
    patterns.usesEmoji = true;
    patterns.confidence = Math.round(emojiRatio * 100);
  } else if (conventionalRatio >= 0.3) {
    patterns.format = 'conventional';
    patterns.confidence = Math.round(conventionalRatio * 100);
  } else {
    patterns.format = 'simple';
    patterns.confidence = 60;
  }

  // === POPULATE DERIVED FIELDS ===
  patterns.usesScope = scopeCount / total >= 0.3;
  patterns.usesIssueRef = issueRefCount / total >= 0.2;

  // Sort types and scopes by frequency
  patterns.typeOrder = Object.entries(patterns.types)
    .sort((a, b) => b[1] - a[1])
    .map(([type]) => type);

  patterns.scopeOrder = Object.entries(patterns.scopes)
    .sort((a, b) => b[1] - a[1])
    .map(([scope]) => scope);

  // Determine issue position
  if (patterns.usesScope && patterns.usesIssueRef) {
    // Check if issues are typically in scope position
    const scopeIssueCount = Object.keys(patterns.scopes)
      .filter(s => /^[A-Z]+-\d+$/.test(s) || /^\d+$/.test(s))
      .reduce((sum, s) => sum + patterns.scopes[s], 0);

    if (scopeIssueCount > scopeCount * 0.3) {
      patterns.issuePosition = 'scope';
    } else {
      patterns.issuePosition = 'suffix';
    }
  }

  // Store sample commits
  patterns.sampleCommits = commits.slice(0, 10);

  return patterns;
}
```

### Commit Message Suggestion

```javascript
/**
 * Suggest a commit message based on detected patterns
 * @param {CommitPatterns} patterns - Detected patterns from analyzeCommitPatterns
 * @param {object} context - Current change context
 * @returns {string} Suggested commit message
 */
function suggestCommitMessage(patterns, context) {
  const { changedFiles, issueId, description, commitType } = context;

  // Determine type
  let type = commitType || suggestType(changedFiles, patterns);

  // Determine scope
  let scope = suggestScope(changedFiles, patterns);

  // Handle issue reference based on detected pattern
  if (issueId && patterns.issuePosition === 'scope') {
    scope = issueId;
  }

  // Build message based on format
  let message = '';

  switch (patterns.format) {
    case 'conventional':
      message = type;
      if (scope && patterns.usesScope) {
        message += `(${scope})`;
      }
      message += ': ';
      message += patterns.capitalization === 'sentence'
        ? capitalizeFirst(description)
        : description.toLowerCase();
      break;

    case 'emoji':
      const emoji = getEmojiForType(type);
      message = `${emoji} ${description}`;
      break;

    case 'simple':
    default:
      message = description;
      break;
  }

  // Add issue reference suffix if that's the pattern
  if (issueId && patterns.issuePosition === 'suffix') {
    message += ` (${issueId})`;
  }

  return message;
}

/**
 * Suggest commit type based on changed files
 */
function suggestType(changedFiles, patterns) {
  const files = changedFiles || [];

  // Check for specific patterns
  const hasTests = files.some(f => f.includes('test') || f.includes('spec'));
  const hasDocs = files.some(f => f.match(/\.(md|txt|rst)$/) || f.includes('docs/'));
  const hasConfig = files.some(f => f.match(/\.(json|yml|yaml|toml)$/) && !f.includes('package'));
  const hasSrc = files.some(f => f.includes('src/') || f.match(/\.(ts|js|tsx|jsx)$/));
  const hasCi = files.some(f => f.includes('.github/') || f.includes('ci'));

  // Prioritize based on what changed
  if (hasCi) return 'ci';
  if (hasTests && !hasSrc) return 'test';
  if (hasDocs && !hasSrc) return 'docs';
  if (hasConfig && !hasSrc) return 'chore';

  // Default to most common type in project, or 'feat'
  return patterns.typeOrder[0] || 'feat';
}

/**
 * Suggest scope based on changed files and project patterns
 */
function suggestScope(changedFiles, patterns) {
  const files = changedFiles || [];

  // Extract directory patterns
  const directories = files
    .map(f => f.split('/')[0])
    .filter(d => d && !d.startsWith('.'));

  // Count occurrences
  const dirCounts = {};
  for (const dir of directories) {
    dirCounts[dir] = (dirCounts[dir] || 0) + 1;
  }

  // Find most common directory
  const topDir = Object.entries(dirCounts)
    .sort((a, b) => b[1] - a[1])
    .map(([dir]) => dir)[0];

  // Check if it matches existing scopes
  if (topDir && patterns.scopeOrder.includes(topDir)) {
    return topDir;
  }

  // Check for common scope patterns
  const commonScopes = ['hooks', 'commands', 'agents', 'helpers', 'skills', 'scripts'];
  for (const scope of commonScopes) {
    if (files.some(f => f.includes(`${scope}/`))) {
      return scope;
    }
  }

  return topDir || null;
}

/**
 * Get emoji for commit type (gitmoji style)
 */
function getEmojiForType(type) {
  const emojiMap = {
    feat: '✨',
    fix: '🐛',
    docs: '📝',
    style: '💄',
    refactor: '♻️',
    test: '✅',
    chore: '🔧',
    ci: '👷',
    perf: '⚡',
    build: '📦',
    revert: '⏪'
  };
  return emojiMap[type] || '🔨';
}

function capitalizeFirst(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}
```

## Pattern Output Example

```javascript
// Example output from analyzeCommitPatterns()
{
  format: 'conventional',
  usesScope: true,
  usesEmoji: false,
  usesIssueRef: true,
  types: { feat: 15, fix: 10, docs: 8, chore: 5, ci: 4, test: 2 },
  typeOrder: ['feat', 'fix', 'docs', 'chore', 'ci', 'test'],
  scopes: { hooks: 8, commands: 6, ci: 4, skills: 3, agents: 2 },
  scopeOrder: ['hooks', 'commands', 'ci', 'skills', 'agents'],
  capitalization: 'lower',
  maxLength: 72,
  issuePatterns: ['PSN-', 'WORK-'],
  issuePosition: 'scope',
  sampleCommits: [
    'docs: bump version to 1.2.0 and update documentation',
    'feat(hooks): add harness patterns from Claude ecosystem',
    'docs(hooks): update documentation for v1.1 two-phase hook system',
    'fix(hooks): optimize context injection and agent discovery',
    // ...
  ],
  confidence: 85
}
```

## Integration with /ccpm:commit

The commit command should:

1. **Analyze patterns** at the start of the command
2. **Merge with CLAUDE.md rules** (CLAUDE.md takes precedence)
3. **Generate suggestions** based on combined rules
4. **Display confidence** so user knows how certain the suggestion is

```javascript
// In commit.md implementation:

// Step 0.5: Analyze git history patterns
const patterns = await analyzeCommitPatterns(50);

// Merge with CLAUDE.md rules (CLAUDE.md wins on conflicts)
const mergedRules = {
  ...patterns,
  // CLAUDE.md overrides
  format: commitRules.customFormat || patterns.format,
  additionalFlags: commitRules.additionalFlags,
  requireSignoff: commitRules.requireSignoff,
};

// Use merged rules for suggestion
const suggestedMessage = suggestCommitMessage(mergedRules, {
  changedFiles: changes.all,
  issueId: issueId,
  description: userMessage || issue?.title || 'update',
  commitType: null // auto-detect
});

// Display with confidence
console.log(`💬 Suggested: ${suggestedMessage}`);
console.log(`📊 Pattern confidence: ${patterns.confidence}%`);
if (patterns.confidence < 70) {
  console.log(`⚠️  Low confidence - few commits match detected pattern`);
}
```

## claude-mem Integration

When claude-mem is available, query for past commit decisions:

```javascript
// Query claude-mem for relevant commit context
const memContext = await queryClaudeMem({
  query: 'commit message conventions decisions',
  types: ['decision', 'change'],
  limit: 5
});

// Incorporate any explicit decisions
if (memContext.decisions) {
  for (const decision of memContext.decisions) {
    if (decision.title.includes('commit') || decision.title.includes('conventional')) {
      // Apply decision to patterns
      console.log(`📚 Found past decision: ${decision.title}`);
    }
  }
}
```

## Shell Script Implementation

For use in hooks (faster than Node.js parsing):

```bash
#!/bin/bash
# commit-patterns.sh - Quick pattern detection

analyze_commit_patterns() {
  local limit=${1:-50}

  # Get commits
  local commits=$(git log --oneline -"$limit" --format="%s" 2>/dev/null)
  if [ -z "$commits" ]; then
    echo '{"format":"conventional","confidence":50}'
    return
  fi

  # Count conventional commits
  local total=$(echo "$commits" | wc -l | tr -d ' ')
  local conventional=$(echo "$commits" | grep -cE '^[a-z]+(\([^)]+\))?!?:' || echo 0)

  # Count scopes
  local with_scope=$(echo "$commits" | grep -cE '^[a-z]+\([^)]+\):' || echo 0)

  # Extract common scopes
  local scopes=$(echo "$commits" | grep -oE '^\w+\(([^)]+)\)' | sed 's/.*(\(.*\))/\1/' | sort | uniq -c | sort -rn | head -5)

  # Calculate confidence
  local confidence=$((conventional * 100 / total))

  # Output JSON
  cat << EOF
{
  "format": "conventional",
  "usesScope": $([ "$with_scope" -gt $((total / 3)) ] && echo "true" || echo "false"),
  "confidence": $confidence,
  "topScopes": "$(echo "$scopes" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')"
}
EOF
}

# Export for use in other scripts
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  analyze_commit_patterns "$@"
fi
```

## Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Gitmoji](https://gitmoji.dev/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)
