# Branching Strategy Helper

Parse and apply branching strategies from multi-level CLAUDE.md files.

## Purpose

Extract type-based branch prefix mappings from CLAUDE.md hierarchy and suggest appropriate branch names based on Linear issue type/labels.

## CLAUDE.md Configuration Format

Users can define branching strategies in their CLAUDE.md files:

```markdown
## Branching Strategy

Branch prefixes by type:
- feature: feature/
- feat: feature/
- fix: fix/
- bug: bugfix/
- hotfix: hotfix/
- docs: docs/
- chore: chore/
- refactor: refactor/
- test: test/
- ci: ci/

Default prefix: feature/
Protected branches: main, master, develop, staging, production
```

Alternative format (YAML-like):

```markdown
## Git Workflow

branchPrefixes:
  feature: feature/
  fix: fix/
  bug: bugfix/
  docs: docs/
  chore: chore/

defaultPrefix: feature/
protectedBranches: main, master, develop
```

## Implementation

### Step 1: Multi-Level CLAUDE.md Collection

```javascript
/**
 * Collect all CLAUDE.md files in hierarchy (global → local)
 * Lower-level files override higher-level settings
 */
async function collectClaudeMdFiles() {
  const homeDir = process.env.HOME;
  const gitRoot = await Bash('git rev-parse --show-toplevel 2>/dev/null || echo ""');
  const cwd = process.cwd();

  const paths = [];

  // 1. Global user config (lowest priority)
  paths.push(`${homeDir}/.claude/CLAUDE.md`);

  // 2. Walk up from git root to find parent CLAUDE.md files
  let searchDir = gitRoot.trim() || cwd;
  let prevDir = '';
  while (searchDir !== prevDir && searchDir !== '/') {
    paths.push(`${searchDir}/CLAUDE.md`);
    paths.push(`${searchDir}/.claude/CLAUDE.md`);
    prevDir = searchDir;
    searchDir = require('path').dirname(searchDir);
  }

  // 3. Current working directory (highest priority)
  if (cwd !== gitRoot.trim()) {
    paths.push(`${cwd}/CLAUDE.md`);
    paths.push(`${cwd}/.claude/CLAUDE.md`);
  }

  return paths;
}
```

### Step 2: Parse Branching Strategy

```javascript
/**
 * Parse branching strategy from CLAUDE.md content
 * Returns type-to-prefix mappings and defaults
 */
function parseBranchingStrategy(content) {
  const strategy = {
    prefixes: {},
    defaultPrefix: null,
    protectedBranches: [],
    format: '{prefix}{issue-id}-{title-slug}'
  };

  // Pattern 1: List format "- type: prefix/"
  const listPattern = /^[\s-]*(\w+)[:\s]+([a-z\-_]+\/?)$/gim;
  let match;
  while ((match = listPattern.exec(content)) !== null) {
    const type = match[1].toLowerCase();
    let prefix = match[2].trim();
    // Ensure prefix ends with /
    if (!prefix.endsWith('/')) prefix += '/';
    strategy.prefixes[type] = prefix;
  }

  // Pattern 2: YAML-like format
  const yamlBlockPattern = /branchPrefixes:?\s*\n((?:[\s]+\w+:\s*[^\n]+\n?)+)/i;
  const yamlMatch = content.match(yamlBlockPattern);
  if (yamlMatch) {
    const yamlLines = yamlMatch[1].split('\n');
    for (const line of yamlLines) {
      const lineMatch = line.match(/^\s*(\w+):\s*([^\s]+)/);
      if (lineMatch) {
        const type = lineMatch[1].toLowerCase();
        let prefix = lineMatch[2].trim();
        if (!prefix.endsWith('/')) prefix += '/';
        strategy.prefixes[type] = prefix;
      }
    }
  }

  // Pattern 3: Simple single prefix (backward compatible)
  const simplePrefixMatch = content.match(/branch.*prefix[:\s]+([^\n\s]+)/i);
  if (simplePrefixMatch && Object.keys(strategy.prefixes).length === 0) {
    let prefix = simplePrefixMatch[1].trim();
    if (!prefix.endsWith('/')) prefix += '/';
    strategy.defaultPrefix = prefix;
  }

  // Extract default prefix
  const defaultMatch = content.match(/default.*prefix[:\s]+([^\n\s]+)/i);
  if (defaultMatch) {
    let prefix = defaultMatch[1].trim();
    if (!prefix.endsWith('/')) prefix += '/';
    strategy.defaultPrefix = prefix;
  }

  // Extract protected branches
  const protectedMatch = content.match(/protected.*branch(?:es)?[:\s]+([^\n]+)/i);
  if (protectedMatch) {
    strategy.protectedBranches = protectedMatch[1]
      .split(/[,\s]+/)
      .filter(b => b.length > 0 && !b.includes(':'));
  }

  // Extract branch format if specified
  const formatMatch = content.match(/branch.*format[:\s]+([^\n]+)/i);
  if (formatMatch) {
    strategy.format = formatMatch[1].trim();
  }

  return strategy;
}
```

### Step 3: Merge Strategies from Multiple Files

```javascript
/**
 * Load and merge branching strategies from all CLAUDE.md files
 * Later files override earlier ones (local > global)
 */
async function loadBranchingStrategy() {
  const paths = await collectClaudeMdFiles();

  // Default strategy
  const merged = {
    prefixes: {
      feature: 'feature/',
      feat: 'feature/',
      fix: 'fix/',
      bug: 'bugfix/',
      hotfix: 'hotfix/',
      docs: 'docs/',
      chore: 'chore/',
      refactor: 'refactor/',
      test: 'test/',
      ci: 'ci/',
      perf: 'perf/',
      style: 'style/'
    },
    defaultPrefix: 'feature/',
    protectedBranches: ['main', 'master', 'develop', 'staging', 'production'],
    format: '{prefix}{issue-id}-{title-slug}',
    sources: []
  };

  for (const path of paths) {
    try {
      const content = await Read(path);
      if (!content) continue;

      // Check if file has branching-related content
      if (!content.match(/branch|protect|workflow|prefix/i)) continue;

      const strategy = parseBranchingStrategy(content);

      // Merge prefixes (later overrides)
      if (Object.keys(strategy.prefixes).length > 0) {
        merged.prefixes = { ...merged.prefixes, ...strategy.prefixes };
      }

      // Override defaults if specified
      if (strategy.defaultPrefix) {
        merged.defaultPrefix = strategy.defaultPrefix;
      }

      if (strategy.protectedBranches.length > 0) {
        // Union of all protected branches
        merged.protectedBranches = [...new Set([
          ...merged.protectedBranches,
          ...strategy.protectedBranches
        ])];
      }

      if (strategy.format !== '{prefix}{issue-id}-{title-slug}') {
        merged.format = strategy.format;
      }

      merged.sources.push(path);
    } catch (e) {
      // File doesn't exist or can't be read, continue
    }
  }

  return merged;
}
```

### Step 4: Determine Branch Prefix from Linear Issue

```javascript
/**
 * Determine the appropriate branch prefix based on Linear issue type/labels
 *
 * @param issue - Linear issue object with labels, type, etc.
 * @param strategy - Branching strategy from loadBranchingStrategy()
 * @returns Appropriate branch prefix
 */
function determineBranchPrefix(issue, strategy) {
  // Priority order for determining type:
  // 1. Issue labels (most specific)
  // 2. Issue type field (if available)
  // 3. Title prefix detection
  // 4. Default prefix

  const prefixes = strategy.prefixes;
  const defaultPrefix = strategy.defaultPrefix || 'feature/';

  // 1. Check labels first (case-insensitive)
  if (issue.labels && issue.labels.length > 0) {
    for (const label of issue.labels) {
      const labelName = (label.name || label).toLowerCase();

      // Direct match
      if (prefixes[labelName]) {
        return prefixes[labelName];
      }

      // Partial matches for common patterns
      if (labelName.includes('bug') || labelName.includes('defect')) {
        return prefixes.bug || prefixes.fix || 'bugfix/';
      }
      if (labelName.includes('feature') || labelName.includes('enhancement')) {
        return prefixes.feature || 'feature/';
      }
      if (labelName.includes('doc')) {
        return prefixes.docs || 'docs/';
      }
      if (labelName.includes('chore') || labelName.includes('maintenance')) {
        return prefixes.chore || 'chore/';
      }
      if (labelName.includes('refactor')) {
        return prefixes.refactor || 'refactor/';
      }
      if (labelName.includes('test')) {
        return prefixes.test || 'test/';
      }
      if (labelName.includes('hotfix') || labelName.includes('urgent')) {
        return prefixes.hotfix || 'hotfix/';
      }
      if (labelName.includes('perf') || labelName.includes('performance')) {
        return prefixes.perf || 'perf/';
      }
    }
  }

  // 2. Check issue type (Linear-specific)
  if (issue.type) {
    const typeName = issue.type.toLowerCase();
    if (prefixes[typeName]) {
      return prefixes[typeName];
    }
  }

  // 3. Detect from title prefix (e.g., "fix: something" or "[BUG] something")
  const title = (issue.title || '').toLowerCase();

  // Conventional commit style prefix in title
  const conventionalMatch = title.match(/^(feat|fix|docs|chore|refactor|test|ci|perf|style|build)[\s:(\[]/);
  if (conventionalMatch) {
    const type = conventionalMatch[1];
    if (prefixes[type]) {
      return prefixes[type];
    }
  }

  // Bracket style [TYPE]
  const bracketMatch = title.match(/^\[(bug|feature|fix|docs|chore|refactor)\]/i);
  if (bracketMatch) {
    const type = bracketMatch[1].toLowerCase();
    if (prefixes[type]) {
      return prefixes[type];
    }
  }

  // Keywords in title
  if (title.includes('fix') || title.includes('bug') || title.includes('broken')) {
    return prefixes.fix || prefixes.bug || 'fix/';
  }
  if (title.includes('document') || title.includes('readme')) {
    return prefixes.docs || 'docs/';
  }
  if (title.includes('refactor') || title.includes('cleanup')) {
    return prefixes.refactor || 'refactor/';
  }
  if (title.includes('test') || title.includes('spec')) {
    return prefixes.test || 'test/';
  }

  // 4. Default
  return defaultPrefix;
}
```

### Step 5: Generate Branch Name

```javascript
/**
 * Generate full branch name from issue and strategy
 *
 * @param issue - Linear issue object
 * @param strategy - Branching strategy
 * @param customSuffix - Optional custom suffix to use instead of title slug
 * @returns Generated branch name
 */
function generateBranchName(issue, strategy, customSuffix = null) {
  const prefix = determineBranchPrefix(issue, strategy);
  const issueId = issue.identifier.toLowerCase();

  // Generate slug from title or use custom suffix
  let slug;
  if (customSuffix) {
    slug = customSuffix.toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');
  } else {
    slug = issue.title.toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '')
      .substring(0, 30)
      .replace(/-$/, '');
  }

  // Apply format template
  let branchName = strategy.format
    .replace('{prefix}', prefix)
    .replace('{issue-id}', issueId)
    .replace('{issueId}', issueId)
    .replace('{title-slug}', slug)
    .replace('{slug}', slug);

  return branchName;
}
```

## Usage in Commands

### In /ccpm:work

```javascript
// Load branching strategy from CLAUDE.md hierarchy
const strategy = await loadBranchingStrategy();

// Get Linear issue
const issue = await getLinearIssue(issueId);

// Check if on protected branch
const currentBranch = await Bash('git rev-parse --abbrev-ref HEAD');
if (strategy.protectedBranches.includes(currentBranch.trim())) {
  // Generate type-appropriate branch name
  const suggestedBranch = generateBranchName(issue, strategy);

  console.log(`⚠️  You are on protected branch: ${currentBranch}`);
  console.log(`\nSuggested branch: ${suggestedBranch}`);

  // Show what determined the prefix
  const prefix = determineBranchPrefix(issue, strategy);
  if (issue.labels?.length > 0) {
    console.log(`   (Prefix '${prefix}' based on label: ${issue.labels[0].name})`);
  } else if (issue.title.match(/^(feat|fix|docs)/)) {
    console.log(`   (Prefix '${prefix}' based on title convention)`);
  }

  // Ask user
  AskUserQuestion(/* ... */);
}
```

### In /ccpm:branch

```javascript
// Load branching strategy
const strategy = await loadBranchingStrategy();

// Display active configuration
if (strategy.sources.length > 0) {
  console.log('📋 Branching strategy loaded from:');
  strategy.sources.forEach(src => console.log(`   • ${src}`));
}

// Generate branch name with type-appropriate prefix
const branchName = generateBranchName(issue, strategy, options.suffix);
console.log(`\n🌿 Creating branch: ${branchName}`);
```

## Label-to-Prefix Mapping Reference

| Linear Label | Common Aliases | Suggested Prefix |
|--------------|---------------|------------------|
| bug | defect, issue, broken | `bugfix/` or `fix/` |
| feature | enhancement, new | `feature/` |
| fix | bugfix, patch | `fix/` |
| documentation | docs | `docs/` |
| chore | maintenance, cleanup | `chore/` |
| refactor | refactoring | `refactor/` |
| test | testing, spec | `test/` |
| hotfix | urgent, critical | `hotfix/` |
| performance | perf, optimization | `perf/` |

## Debugging

Display loaded strategy for debugging:

```javascript
const strategy = await loadBranchingStrategy();

console.log('═══════════════════════════════════════');
console.log('🌿 Branching Strategy');
console.log('═══════════════════════════════════════');
console.log(`Default prefix: ${strategy.defaultPrefix}`);
console.log(`Protected: ${strategy.protectedBranches.join(', ')}`);
console.log(`Format: ${strategy.format}`);
console.log('\nType prefixes:');
Object.entries(strategy.prefixes).forEach(([type, prefix]) => {
  console.log(`  ${type}: ${prefix}`);
});
if (strategy.sources.length > 0) {
  console.log('\nLoaded from:');
  strategy.sources.forEach(src => console.log(`  • ${src}`));
}
console.log('═══════════════════════════════════════');
```
