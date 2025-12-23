---
description: Initialize CCPM in a new project
allowed-tools: [Bash, Write, Read, AskUserQuestion]
argument-hint: "[project-name]"
---

# /ccpm:init - Initialize CCPM Project

Sets up CCPM configuration for a new project or directory.

## Usage

```bash
# Interactive setup
/ccpm:init

# With project name
/ccpm:init my-project

# In a subdirectory of a monorepo
/ccpm:init apps/web
```

## What It Does

1. **Detects project context**
   - Git remote URL → project name
   - Package.json → project metadata
   - Monorepo structure → subdirectory config

2. **Creates configuration**
   - `.ccpm.json` in project root
   - Adds project to global CCPM config

3. **Sets up integrations**
   - Linear team/project selection
   - Optional: Jira, Confluence, Figma
   - Git branch naming conventions

4. **Configures hooks**
   - Enables session management
   - Configures statusline
   - Sets up agent discovery

## Implementation

### Step 1: Detect Project Context

```javascript
// Get project info from git and package.json
const gitRemote = await Bash('git remote get-url origin 2>/dev/null || echo ""');
const packageJson = await Read('package.json').catch(() => null);
const cwd = process.cwd();

let projectName = args[0];

if (!projectName) {
  // Try to detect from git remote
  if (gitRemote.trim()) {
    const match = gitRemote.match(/[\/:]([^\/]+?)(\.git)?$/);
    projectName = match ? match[1].replace('.git', '') : null;
  }

  // Fallback to directory name
  if (!projectName) {
    projectName = path.basename(cwd);
  }
}

console.log(`📁 Detected project: ${projectName}`);
```

### Step 2: Interactive Configuration

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Which Linear team should this project use?",
      header: "Linear Team",
      multiSelect: false,
      options: [
        { label: "Personal", description: "Your personal workspace" },
        { label: "Engineering", description: "Main engineering team" },
        { label: "Product", description: "Product team" },
        { label: "Other", description: "I'll specify the team name" }
      ]
    },
    {
      question: "Enable Figma integration?",
      header: "Figma",
      multiSelect: false,
      options: [
        { label: "Yes", description: "Extract designs for pixel-perfect implementation" },
        { label: "No", description: "Skip Figma integration" }
      ]
    },
    {
      question: "Branch naming convention?",
      header: "Git Branches",
      multiSelect: false,
      options: [
        { label: "feature/{issue}-{slug}", description: "e.g., feature/PSN-29-add-auth (Recommended)" },
        { label: "{issue}/{slug}", description: "e.g., PSN-29/add-auth" },
        { label: "Custom", description: "I'll define my own pattern" }
      ]
    }
  ]
});
```

### Step 3: Create Configuration

```javascript
const config = {
  "$schema": "https://ccpm.dev/schemas/ccpm.json",
  "version": "1.1",
  "project": {
    "name": projectName,
    "root": cwd
  },
  "linear": {
    "team": linearTeam,
    "project": linearProject || null
  },
  "figma": figmaEnabled ? {
    "enabled": true,
    "server": "figma-${projectName}"
  } : {
    "enabled": false
  },
  "git": {
    "branchPattern": branchPattern,
    "protectedBranches": ["main", "master", "develop"]
  },
  "workflow": {
    "requirePlanBeforeWork": true,
    "autoSyncOnCommit": true,
    "verifyBeforeDone": true
  }
};

await Write('.ccpm.json', JSON.stringify(config, null, 2));
console.log('✅ Created .ccpm.json');
```

### Step 4: Add to Global Config

```javascript
// Add project to ~/.config/ccpm/projects.json
const globalConfigPath = path.join(process.env.HOME, '.config/ccpm/projects.json');

let globalConfig = { projects: [] };
try {
  globalConfig = JSON.parse(await Read(globalConfigPath));
} catch (e) {
  // Create new config
}

// Add or update project
const existingIndex = globalConfig.projects.findIndex(p => p.name === projectName);
if (existingIndex >= 0) {
  globalConfig.projects[existingIndex] = {
    name: projectName,
    path: cwd,
    config: '.ccpm.json'
  };
} else {
  globalConfig.projects.push({
    name: projectName,
    path: cwd,
    config: '.ccpm.json'
  });
}

await Write(globalConfigPath, JSON.stringify(globalConfig, null, 2));
console.log('✅ Added to global CCPM config');
```

### Step 5: Display Summary

```javascript
console.log('\n═══════════════════════════════════════');
console.log('🚀 CCPM Initialized');
console.log('═══════════════════════════════════════\n');
console.log(`📁 Project: ${projectName}`);
console.log(`📍 Location: ${cwd}`);
console.log(`🔗 Linear Team: ${linearTeam}`);
console.log(`🎨 Figma: ${figmaEnabled ? 'Enabled' : 'Disabled'}`);
console.log(`🌿 Branch Pattern: ${branchPattern}`);
console.log('\n📋 Configuration saved to .ccpm.json');
console.log('\n💡 Next steps:');
console.log('  1. /ccpm:plan "Your first task"');
console.log('  2. /ccpm:work');
console.log('  3. /ccpm:sync');
console.log('  4. /ccpm:done');
```

## Generated Files

### .ccpm.json

```json
{
  "$schema": "https://ccpm.dev/schemas/ccpm.json",
  "version": "1.1",
  "project": {
    "name": "my-project",
    "root": "/path/to/project"
  },
  "linear": {
    "team": "Personal",
    "project": null
  },
  "figma": {
    "enabled": true,
    "server": "figma-my-project"
  },
  "git": {
    "branchPattern": "feature/{issue}-{slug}",
    "protectedBranches": ["main", "master", "develop"]
  },
  "workflow": {
    "requirePlanBeforeWork": true,
    "autoSyncOnCommit": true,
    "verifyBeforeDone": true
  }
}
```

## Monorepo Support

For monorepos, run `/ccpm:init` in each subdirectory:

```bash
# Root level
/ccpm:init monorepo

# Apps
cd apps/web && /ccpm:init apps/web
cd apps/api && /ccpm:init apps/api

# Packages
cd packages/ui && /ccpm:init packages/ui
```

Each subdirectory gets its own `.ccpm.json` with inherited defaults from root.

## Integration Points

- **Session Management**: Project detected on session start
- **Branch Detection**: Issue ID extracted from branch name
- **Linear Sync**: Auto-associates issues with project
- **Figma**: Design extraction configured per project
