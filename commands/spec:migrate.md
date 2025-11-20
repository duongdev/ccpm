---
description: Migrate existing markdown specs from .claude/ to Linear Documents
allowed-tools: [LinearMCP, Read, Glob, Bash, AskUserQuestion]
argument-hint: <project-path> [category]
---

# Migrate Specs to Linear: $1

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

---

## Arguments

- **$1** - Project path:
  - `.` - Use current directory
  - Absolute path (e.g., `~/projects/my-app`)
  - Relative path (e.g., `../other-project`)
- **$2** - (Optional) Category to migrate: `docs`, `plans`, `enhancements`, `tasks`, `all`

Default category: `all`

**Note**: Using `.` will scan current working directory for `.claude/` folder.

## Workflow

### Step 1: Resolve Project Path

```javascript
// Resolve project path
let projectPath = $1

if (projectPath === '.') {
  // Use current working directory
  projectPath = process.cwd()
}

// Resolve to absolute path
projectPath = path.resolve(projectPath)

// Check if .claude/ exists
const claudePath = path.join(projectPath, '.claude')
if (!fs.existsSync(claudePath)) {
  // Error: No .claude/ directory found
  // Suggest: Check path or create .claude/ first
}
```

### Step 2: Discover Existing Specs

Scan project `.claude/` directory for markdown files:

```javascript
const categories = {
  docs: '.claude/docs/',
  plans: '.claude/plans/',
  enhancements: '.claude/enhancements/',
  tasks: '.claude/tasks/',
  research: '.claude/research/',
  analysis: '.claude/analysis/',
  qa: '.claude/qa/',
  security: '.claude/security/'
}

// Use Glob to find all .md files in each category
const files = {}

for (const [category, path] of Object.entries(categories)) {
  const pattern = `${projectPath}/${path}**/*.md`
  files[category] = await glob(pattern)
}
```

**Filter by category** if `$2` provided.

### Step 2: Categorize Files by Type

**Analyze each file to determine type:**

```javascript
function categorizeFile(filePath, content) {
  // Check filename patterns
  const fileName = path.basename(filePath)

  // Plans with checklists → Features
  if (fileName.includes('plan') && hasChecklist(content)) {
    return { type: 'feature', confidence: 'high' }
  }

  // Enhancements → Features
  if (filePath.includes('/enhancements/')) {
    return { type: 'feature', confidence: 'high' }
  }

  // Tasks → Tasks
  if (filePath.includes('/tasks/') && hasImplementationDetails(content)) {
    return { type: 'task', confidence: 'high' }
  }

  // Docs/guides → Documentation (not migrated, or linked)
  if (filePath.includes('/docs/') || fileName.includes('guide')) {
    return { type: 'documentation', confidence: 'high' }
  }

  // Research → Link as reference
  if (filePath.includes('/research/')) {
    return { type: 'reference', confidence: 'high' }
  }

  // Large multi-section files → Epics
  if (hasSections(content) > 5 && hasFeatureBreakdown(content)) {
    return { type: 'epic', confidence: 'medium' }
  }

  // Default: Feature
  return { type: 'feature', confidence: 'low' }
}

function hasChecklist(content) {
  return /- \[ \]/.test(content)
}

function hasImplementationDetails(content) {
  return content.includes('## What Was Implemented') ||
         content.includes('## Implementation') ||
         content.includes('Status:** ✅')
}

function hasFeatureBreakdown(content) {
  return /## Features/i.test(content) ||
         /## Phases/i.test(content)
}
```

### Step 3: Ask What to Migrate

**FIRST: Let user select which categories to migrate.**

Use **AskUserQuestion**:

```javascript
{
  questions: [{
    question: "Which categories would you like to migrate?",
    header: "Select Categories",
    multiSelect: true,  // Allow multiple selections
    options: [
      {
        label: "Epics (2 files)",
        description: `${epics.length} epic specs found in plans/`
      },
      {
        label: "Features (12 files)",
        description: `${features.length} features found in enhancements/`
      },
      {
        label: "Tasks (25 files)",
        description: `${tasks.length} tasks found in tasks/`
      },
      {
        label: "Documentation (6 files)",
        description: `${docs.length} docs/guides found in docs/`
      },
      {
        label: "Research (8 files)",
        description: `${research.length} research docs found in research/`
      }
    ]
  }]
}
```

**User can select**:
- Single category (e.g., only "Features")
- Multiple categories (e.g., "Epics" + "Features")
- All categories (select all)

**After selection**, filter files to only selected categories.

### Step 4: Show Migration Preview for Selected Categories

Display categorized files to user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Migration Preview: $1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 Category: ${$2 || 'all'}
📁 Project Path: $1/.claude/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Discovered Files
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 EPICS (Will create Initiatives + Spec Docs):
  1. production-deployment-plan.md → Epic: "Production Deployment Plan"
  2. [...]

🎨 FEATURES (Will create Features + Design Docs):
  1. 20251031-posthog-observability-implementation.md → Feature: "PostHog Observability"
  2. 20251024-120100-search-and-filter-system.md → Feature: "Search & Filter System"
  3. [...]

✅ TASKS (Will create Tasks):
  1. 20251030-130330-implement-task-comments-phase2.md → Task: "Task Comments Phase 2"
  2. 20251107-095033-fix-posthog-provider-crash.md → Task: "Fix PostHog Provider Crash"
  3. [...]

📖 DOCUMENTATION (Will link as references):
  1. feature-flags-guide.md
  2. ota-updates-guide.md
  3. [...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📈 Migration Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Files: 45
- Epics: 2
- Features: 12
- Tasks: 25
- Documentation: 6

Estimated Time: ~15 minutes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Migration Rules
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Original .md files will NOT be deleted (safe migration)
✅ Files will be moved to .claude/migrated/ after successful migration
✅ Linear issues will include link to original file
✅ You can review and edit in Linear after migration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Show Detailed Preview (MANDATORY)

**CRITICAL: ALWAYS show full preview before ANY migration.**

For EACH file, display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📄 File #1: production-deployment-plan.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Original Path: .claude/plans/production-deployment-plan.md
📊 Type: Epic (detected)
📝 Size: 57KB

Will Create in Linear:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Epic/Initiative:
   - Title: "Production Deployment Plan"
   - Team: Personal
   - Project: Personal Project
   - Labels: ["epic", "migrated", "spec:draft"]
   - Status: Planned

2. Linear Document:
   - Title: "Epic Spec: Production Deployment Plan"
   - Content: Full markdown (57KB)
   - Linked to Epic above

3. Extracted Metadata:
   - Created: 2025-11-01
   - Status: Planning
   - Version: v1.0.0

4. Post-Migration:
   - Original file moved to: .claude/migrated/plans/
   - Breadcrumb created: .claude/plans/production-deployment-plan.md.migrated.txt

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📄 File #2: 20251031-posthog-observability-implementation.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Original Path: .claude/enhancements/20251031-posthog-observability-implementation.md
📊 Type: Feature (detected)
📝 Size: 35KB
📋 Checklist Found: 3 subtasks detected

Will Create in Linear:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Feature (Parent Issue):
   - Title: "PostHog Observability Implementation"
   - Team: Personal
   - Project: Personal Project
   - Labels: ["feature", "migrated", "spec:draft"]
   - Priority: High (detected)

2. Linear Document:
   - Title: "Feature Design: PostHog Observability Implementation"
   - Content: Full markdown (35KB)
   - Linked to Feature above

3. Sub-Tasks (from checklist):
   - Task 1: "Setup PostHog Integration" (Est: 2h)
   - Task 2: "Configure Event Tracking" (Est: 4h)
   - Task 3: "Add Custom Properties" (Est: 3h)

4. Post-Migration:
   - Original file moved to: .claude/migrated/enhancements/
   - Breadcrumb created with Linear links

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[... show ALL files ...]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5: Confirm Migration (REQUIRED)

**NEVER migrate without explicit confirmation.**

Use **AskUserQuestion**:

```javascript
{
  questions: [{
    question: "⚠️  REVIEW COMPLETE. Proceed with creating these items in Linear?",
    header: "Confirm",
    multiSelect: false,
    options: [
      {
        label: "✅ Yes, Migrate All",
        description: "Create all items in Linear as shown above"
      },
      {
        label: "🔍 Select Specific Files",
        description: "I want to choose which files to migrate"
      },
      {
        label: "❌ Cancel",
        description: "Don't migrate anything"
      }
    ]
  }]
}
```

**If "Select Specific Files":**

- Show numbered list of all files
- Ask user to specify indices (e.g., "1,3,5-8,12")
- Show preview AGAIN for selected files only
- Ask confirmation AGAIN before migrating

### Step 5: Migrate Each File

For each file:

#### Step 5.1: Read and Parse File

```javascript
const content = await readFile(filePath)

const metadata = extractMetadata(content)
// Extracts:
// - Title (from # heading or filename)
// - Created date (from file or "Created:" field)
// - Status (from "Status:" field)
// - Related docs (from "Related:" or links)
```

#### Step 5.2: Transform Content for Linear

**Keep most content as-is, but:**

1. **Remove file-specific headers:**
   ```markdown
   # Task Comments Phase 2: Photo Attachments Implementation

   **Date:** 2025-10-30 - 2025-10-31
   **Status:** ✅ COMPLETED
   **Related Task:** `.claude/tasks/20251030-130330-implement-task-comments.md`
   ```

   Becomes Linear issue fields:
   - Title: "Task Comments Phase 2: Photo Attachments"
   - Status: "Done"
   - Description: (rest of content)

2. **Convert local file links to references:**
   ```markdown
   **Related Task:** `.claude/tasks/20251030-130330-implement-task-comments.md`
   ```

   Becomes:
   ```markdown
   **Related Task:** [Will be migrated as WORK-XXX] or [Original file: `.claude/tasks/...`]
   ```

3. **Preserve all other content:**
   - Code blocks → Keep as-is
   - Tables → Keep as-is
   - Images → Keep as-is (if hosted)
   - Checklists → Keep as-is
   - Headers, formatting → Keep as-is

#### Step 5.3: Create Linear Entities

**For Epic:**

```javascript
// 1. Create Initiative in Linear
const epic = await createLinearInitiative({
  name: metadata.title,
  description: `Original file: \`${relativePath}\`\n\nMigrated from: ${filePath}`,
  team: detectTeam(projectPath),
  targetDate: metadata.targetDate
})

// 2. Create Linear Document for Epic Spec
const doc = await createLinearDocument({
  title: `Epic Spec: ${metadata.title}`,
  content: transformedContent,  // Full markdown content
  projectId: epic.id
})

// 3. Update Initiative description to link to spec doc
await updateLinearInitiative(epic.id, {
  description: `
## 📄 Specification

**Spec Document**: [Epic Spec: ${metadata.title}](${doc.url})

**Original File**: \`${relativePath}\`
**Migrated**: ${new Date().toISOString().split('T')[0]}

---

${epic.description}
  `
})
```

**For Feature:**

```javascript
// 1. Create Feature (Parent Issue)
const feature = await createLinearIssue({
  title: metadata.title,
  team: detectTeam(projectPath),
  project: detectProject(projectPath),
  labels: ['feature', 'migrated', metadata.status ? `status:${metadata.status}` : 'spec:draft'],
  priority: metadata.priority || 0,
  description: `Original file: \`${relativePath}\`\n\nMigrated from: ${filePath}`
})

// 2. Create Linear Document for Feature Design
const doc = await createLinearDocument({
  title: `Feature Design: ${metadata.title}`,
  content: transformedContent,
  projectId: feature.projectId
})

// 3. Link doc to feature
await updateLinearIssue(feature.id, {
  description: `
## 📄 Specification

**Design Doc**: [Feature Design: ${metadata.title}](${doc.url})

**Original File**: \`${relativePath}\`
**Migrated**: ${new Date().toISOString().split('T')[0]}
**Original Status**: ${metadata.status || 'N/A'}

---

${feature.description}
  `
})

// 4. If file has checklist, extract and add as sub-tasks
if (hasChecklist(content)) {
  const tasks = extractChecklist(content)
  for (const task of tasks) {
    await createLinearIssue({
      title: task.title,
      team: feature.team,
      project: feature.project,
      parent: feature.id,  // Sub-issue
      labels: ['task', 'migrated'],
      description: task.description || ''
    })
  }
}
```

**For Task:**

```javascript
// Create Task (regular issue, may or may not be sub-issue)
const task = await createLinearIssue({
  title: metadata.title,
  team: detectTeam(projectPath),
  project: detectProject(projectPath),
  labels: ['task', 'migrated', metadata.status === '✅ COMPLETED' ? 'status:done' : 'planning'],
  status: metadata.status === '✅ COMPLETED' ? 'Done' : 'Planning',
  description: `
## 📄 Original Implementation Notes

**Original File**: \`${relativePath}\`
**Migrated**: ${new Date().toISOString().split('T')[0]}
**Original Status**: ${metadata.status || 'N/A'}

---

${transformedContent}
  `
})
```

**For Documentation:**

```javascript
// Don't create Linear issue, just create reference document
const doc = await createLinearDocument({
  title: `Reference: ${metadata.title}`,
  content: `
# ${metadata.title}

**Source**: \`${relativePath}\`
**Type**: Documentation/Guide

---

${content}
  `
})

// Optionally create "Documentation" parent issue to group all docs
```

#### Step 5.4: Move Original File

After successful migration:

```bash
# Create migrated directory
mkdir -p ${projectPath}/.claude/migrated/${category}

# Move original file
mv ${filePath} ${projectPath}/.claude/migrated/${category}/

# Create breadcrumb file
echo "Migrated to Linear: [WORK-123](url)" > ${filePath}.migrated.txt
```

### Step 6: Track Progress

Show progress during migration:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Migration in Progress...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[████████████░░░░░░░░] 12/45 (26%)

Current: 20251031-posthog-observability-implementation.md
Status: Creating feature... ✅
       Creating design doc... ✅
       Extracting subtasks... ✅ (3 tasks created)
       Moving to migrated/... ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 7: Generate Migration Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Migration Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Migration Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Files Migrated: 45
- Epics Created: 2
- Features Created: 12
- Tasks Created: 25
- Documentation: 6

Total Linear Issues Created: 39
Total Linear Documents Created: 14
Total Sub-Tasks Created: 18

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Created Items Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Epics:
✅ WORK-100: Production Deployment Plan
✅ WORK-101: Feature Roadmap V1

Features:
✅ WORK-102: PostHog Observability (+ 3 subtasks)
✅ WORK-103: Search & Filter System (+ 4 subtasks)
✅ WORK-104: Task Comment Enhancements (+ 2 subtasks)
... [show first 10, then "and X more"]

Tasks:
✅ WORK-120: Fix PostHog Provider Crash
✅ WORK-121: Implement Additional Task Flags
... [show first 10, then "and X more"]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 Original Files
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Original files moved to:
${projectPath}/.claude/migrated/

Breadcrumb files created with Linear links.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Next Steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Review migrated items in Linear
2. Update status labels if needed
3. Link related features/tasks
4. Run /ccpm:utils:report to see project overview

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 8: Create Migration Log

Create a migration log file:

```markdown
# Migration Log - ${new Date().toISOString().split('T')[0]}

## Summary

- Total Files: 45
- Epics: 2
- Features: 12
- Tasks: 25
- Documentation: 6

## Migrated Files

| Original File | Type | Linear ID | Linear URL | Status |
|---------------|------|-----------|------------|--------|
| production-deployment-plan.md | Epic | WORK-100 | [Link](url) | ✅ |
| 20251031-posthog-observability-implementation.md | Feature | WORK-102 | [Link](url) | ✅ |
| ... | ... | ... | ... | ... |

## Errors

[None / List any files that failed to migrate]

## Notes

- Original files moved to `.claude/migrated/`
- All Linear issues labeled with `migrated`
- Spec documents created for Epics and Features
- Subtasks extracted from checklists
```

Save to: `${projectPath}/.claude/migration-log-${timestamp}.md`

### Step 9: Interactive Next Actions

```javascript
{
  questions: [{
    question: "Migration complete! What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "View Project Report",
        description: "See all migrated items organized (/ccpm:utils:report)"
      },
      {
        label: "Review in Linear",
        description: "Open Linear to review migrated items"
      },
      {
        label: "View Migration Log",
        description: "Open detailed migration log file"
      },
      {
        label: "Done",
        description: "Finish migration"
      }
    ]
  }]
}
```

## Helper Functions

```javascript
function detectTeamAndProject(projectPath) {
  // Load CCPM configuration
  const config = loadCCPMConfig() // from ~/.claude/ccpm-config.yaml

  // Try auto-detection from config patterns
  for (const [projectId, projectConfig] of Object.entries(config.projects)) {
    const patterns = config.context.detection.patterns || []

    // Check if path matches any detection pattern
    for (const pattern of patterns) {
      if (pattern.project === projectId) {
        const regex = new RegExp(pattern.pattern.replace('*', '.*'))
        if (regex.test(projectPath)) {
          return {
            team: projectConfig.linear.team,
            project: projectConfig.linear.project,
            projectId: projectId
          }
        }
      }
    }

    // Also check repository URL match
    if (projectConfig.repository?.url && projectPath.includes(projectConfig.repository.url)) {
      return {
        team: projectConfig.linear.team,
        project: projectConfig.linear.project,
        projectId: projectId
      }
    }
  }

  // If no match, use active project or prompt
  const activeProject = config.context.current_project
  if (activeProject && config.projects[activeProject]) {
    return {
      team: config.projects[activeProject].linear.team,
      project: config.projects[activeProject].linear.project,
      projectId: activeProject
    }
  }

  // Last resort: prompt user to select from available projects
  return promptForProject(config.projects)
}

function loadCCPMConfig() {
  // Load from ~/.claude/ccpm-config.yaml
  const configPath = path.join(process.env.HOME, '.claude', 'ccpm-config.yaml')
  return yaml.parse(fs.readFileSync(configPath, 'utf8'))
}

function extractMetadata(content) {
  const metadata = {}

  // Extract title (first # heading)
  const titleMatch = content.match(/^#\s+(.+)$/m)
  metadata.title = titleMatch ? titleMatch[1] : 'Untitled'

  // Extract created date
  const createdMatch = content.match(/\*\*Created[:\s]+\*\*\s*(\d{4}-\d{2}-\d{2})/i)
  metadata.created = createdMatch ? createdMatch[1] : null

  // Extract status
  const statusMatch = content.match(/\*\*Status[:\s]+\*\*\s*(.+?)(?:\n|$)/i)
  metadata.status = statusMatch ? statusMatch[1].trim() : null

  // Extract priority
  const priorityMatch = content.match(/\*\*Priority[:\s]+\*\*\s*(.+?)(?:\n|$)/i)
  metadata.priority = priorityMatch ? mapPriority(priorityMatch[1].trim()) : null

  return metadata
}

function extractChecklist(content) {
  const tasks = []
  const checklistRegex = /- \[ \] \*\*(.+?)\*\*[:\s]+(.+?)(?:\(Est: (.+?)\))?$/gm

  let match
  while ((match = checklistRegex.exec(content)) !== null) {
    tasks.push({
      title: match[1].trim(),
      description: match[2].trim(),
      estimate: match[3] ? match[3].trim() : null
    })
  }

  return tasks
}
```

## Notes

- **Safe Migration**: Original files are moved, not deleted
- **Preserves History**: Original file path saved in Linear description
- **Full Content**: Entire markdown content migrated to Linear Documents
- **Relationships**: Checklists → Sub-tasks automatically
- **Status Mapping**: Original status preserved as label
- **Breadcrumbs**: .migrated.txt files created with Linear links
- **Rollback**: Can restore from `.claude/migrated/` if needed
