---
description: Sync spec document with implementation reality
allowed-tools: [LinearMCP, Read, Glob, Grep, AskUserQuestion]
argument-hint: <doc-id-or-issue-id>
---

# Sync Spec: $1

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: ``$CCPM_COMMANDS_DIR/SAFETY_RULES.md``

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

---

## Argument

- **$1** - Document ID or Issue ID (will find linked spec doc)

## Workflow

### Step 1: Fetch Spec and Related Issues

If `$1` is an issue ID:

```javascript
// 1. Get issue
const issue = await getLinearIssue($1)

// 2. Extract spec doc link from description
const docLinkPattern = /\[(?:Epic Spec|Feature Design): .+?\]\((.+?)\)/
const match = issue.description.match(docLinkPattern)

if (match) {
  const docUrl = match[1]
  const docId = extractDocId(docUrl)
}

// 3. Get all sub-issues (tasks)
const tasks = await getLinearSubIssues(issue.id)
```

If `$1` is a doc ID:

```javascript
// 1. Get document
const doc = await getLinearDocument($1)

// 2. Find linked issue from document content or metadata
// Look for "Linear Epic:" or "Linear Feature:" links
const issueLinkPattern = /\[WORK-\d+\]\((.+?)\)/
const match = doc.content.match(issueLinkPattern)

if (match) {
  const issueUrl = match[1]
  const issueId = extractIssueId(issueUrl)
  const issue = await getLinearIssue(issueId)
  const tasks = await getLinearSubIssues(issue.id)
}
```

### Step 2: Analyze Spec vs Reality

**Compare spec sections with actual implementation:**

#### 2.1: Requirements Drift

```javascript
function checkRequirementsDrift(specDoc, tasks) {
  const specRequirements = extractRequirements(specDoc)
  const implementedFeatures = extractImplementedFeatures(tasks)

  const drift = {
    missing: [],      // In spec but not implemented
    extra: [],        // Implemented but not in spec
    changed: []       // Different from spec
  }

  // Compare
  for (const req of specRequirements) {
    const implemented = implementedFeatures.find(f => matches(f, req))

    if (!implemented) {
      drift.missing.push(req)
    } else if (!exactMatch(implemented, req)) {
      drift.changed.push({ spec: req, actual: implemented })
    }
  }

  for (const feature of implementedFeatures) {
    if (!specRequirements.find(r => matches(feature, r))) {
      drift.extra.push(feature)
    }
  }

  return drift
}
```

#### 2.2: Implementation Tasks Drift

```javascript
function checkTasksDrift(specDoc, linearTasks) {
  const specTasks = extractTasksFromSpec(specDoc)
  // From "## Implementation Plan" or "## Task Breakdown"

  const drift = {
    inSpecNotLinear: [],   // Tasks in spec but no Linear issue
    inLinearNotSpec: [],   // Linear tasks not documented in spec
    statusMismatch: []     // Different completion status
  }

  // Compare task lists
  for (const specTask of specTasks) {
    const linearTask = linearTasks.find(lt => matches(lt, specTask))

    if (!linearTask) {
      drift.inSpecNotLinear.push(specTask)
    } else {
      // Check if status matches
      const specCompleted = specTask.checked
      const linearCompleted = linearTask.status === 'Done'

      if (specCompleted !== linearCompleted) {
        drift.statusMismatch.push({
          task: specTask,
          specStatus: specCompleted ? 'Done' : 'Pending',
          linearStatus: linearTask.status
        })
      }
    }
  }

  for (const linearTask of linearTasks) {
    if (!specTasks.find(st => matches(linearTask, st))) {
      drift.inLinearNotSpec.push(linearTask)
    }
  }

  return drift
}
```

#### 2.3: API Design Drift

```javascript
function checkApiDrift(specDoc, codebase) {
  const specApis = extractApiDesign(specDoc)
  const implementedApis = searchCodebaseForApis(codebase)

  const drift = {
    endpointsMissing: [],
    endpointsExtra: [],
    signatureChanged: []
  }

  // Compare endpoints
  for (const specApi of specApis) {
    const impl = implementedApis.find(api => api.path === specApi.path)

    if (!impl) {
      drift.endpointsMissing.push(specApi)
    } else if (!signaturesMatch(impl, specApi)) {
      drift.signatureChanged.push({
        spec: specApi,
        actual: impl,
        differences: compareSignatures(specApi, impl)
      })
    }
  }

  return drift
}
```

#### 2.4: Data Model Drift

```javascript
function checkDataModelDrift(specDoc, codebase) {
  const specModels = extractDataModel(specDoc)
  const implementedModels = searchCodebaseForModels(codebase)

  const drift = {
    tablesMissing: [],
    tablesExtra: [],
    fieldsMissing: [],
    fieldsChanged: []
  }

  // Compare schemas
  for (const specModel of specModels) {
    const impl = implementedModels.find(m => m.name === specModel.name)

    if (!impl) {
      drift.tablesMissing.push(specModel)
    } else {
      // Compare fields
      for (const specField of specModel.fields) {
        const implField = impl.fields.find(f => f.name === specField.name)

        if (!implField) {
          drift.fieldsMissing.push({
            table: specModel.name,
            field: specField
          })
        } else if (specField.type !== implField.type) {
          drift.fieldsChanged.push({
            table: specModel.name,
            field: specField.name,
            specType: specField.type,
            actualType: implField.type
          })
        }
      }
    }
  }

  return drift
}
```

### Step 3: Search Codebase for Implementation

Use **Glob** and **Grep** to find implemented code:

```javascript
async function searchCodebaseForApis(projectPath) {
  // Search for API route files
  const apiFiles = await glob(`${projectPath}/**/api/**/*.{ts,js}`)

  const apis = []

  for (const file of apiFiles) {
    const content = await read(file)

    // Extract API endpoints
    // Look for: app.post('/api/endpoint', ...) or export async function POST(...)
    const endpointPattern = /(?:app\.(get|post|put|delete|patch)|export async function (GET|POST|PUT|DELETE|PATCH))\s*\(\s*['"`](.+?)['"`]/g

    let match
    while ((match = endpointPattern.exec(content)) !== null) {
      const method = match[1] || match[2]
      const path = match[3]

      apis.push({
        method: method.toUpperCase(),
        path: path,
        file: file,
        // Could extract request/response types if TypeScript
      })
    }
  }

  return apis
}

async function searchCodebaseForModels(projectPath) {
  // Search for database schema files
  const schemaPattern = `${projectPath}/**/schema/**/*.{ts,js,sql}`
  const schemaFiles = await glob(schemaPattern)

  const models = []

  for (const file of schemaFiles) {
    const content = await read(file)

    // Extract table definitions
    // Drizzle: pgTable('table_name', { ... })
    // Prisma: model TableName { ... }
    // SQL: CREATE TABLE table_name ( ... )

    // Parse and extract models
    // This is simplified - actual implementation would parse properly
    models.push(...parseSchema(content))
  }

  return models
}
```

### Step 4: Generate Sync Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Spec Sync Report: [Document Title]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 Spec Doc: [DOC-456](link)
🎯 Issue: [WORK-123 - Feature Title](link)
📅 Last Synced: [Never / Date]
📊 Drift Score: [XX]% ([Grade])

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Overall Drift Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Drift Score**: 85% ← Lower is better (0% = perfect sync)

Legend: ✅ In Sync | ⚠️  Minor Drift | ❌ Major Drift

✅ Requirements: 2 missing, 1 extra (10% drift)
⚠️  Implementation Tasks: 3 status mismatches (25% drift)
❌ API Design: 2 endpoints differ (40% drift)
✅ Data Model: All tables match (0% drift)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Requirements Drift
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**In Spec, Not Implemented:**
1. FR3: Password reset via email
   - Spec says: "Users can reset password via email link"
   - Reality: No implementation found
   - Action: Implement or remove from spec

2. NFR2: Response time < 200ms
   - Spec says: "95th percentile response time under 200ms"
   - Reality: Not measured/verified
   - Action: Add performance monitoring

**Implemented, Not in Spec:**
1. Social Login (Google OAuth)
   - Found: POST /api/auth/google endpoint
   - Not documented in spec
   - Action: Add to spec or mark as scope creep

**Changed from Spec:**
1. Login Rate Limiting
   - Spec: "10 attempts per hour"
   - Actual: 5 attempts per 15 minutes (stricter)
   - Action: Update spec to reflect current implementation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Implementation Tasks Drift
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Status Mismatches:**
1. Task 2: API endpoints
   - Spec Checklist: ✅ Marked complete
   - Linear Status: In Progress
   - Action: Update spec checklist or complete Linear task

2. Task 4: Testing
   - Spec Checklist: ⏳ Not checked
   - Linear Status: Done
   - Action: Check off in spec

3. Task 5: Documentation
   - Spec Checklist: ⏳ Not checked
   - Linear Status: Done
   - Action: Check off in spec

**In Spec, No Linear Task:**
1. Task 6: Performance optimization
   - Missing Linear task
   - Action: Create Linear task or remove from spec

**In Linear, Not in Spec:**
1. WORK-125: Fix login bug (subtask)
   - Unplanned task added during implementation
   - Action: Add to spec as "Bug Fixes" section

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔌 API Design Drift
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Signature Changed:**
1. POST /api/auth/login
   - Spec Request:
     ```typescript
     { email: string, password: string }
     ```
   - Actual Request:
     ```typescript
     { email: string, password: string, rememberMe?: boolean }
     ```
   - Change: Added optional `rememberMe` field
   - Action: Update spec with new signature

2. POST /api/auth/refresh
   - Spec Response:
     ```typescript
     { token: string }
     ```
   - Actual Response:
     ```typescript
     { accessToken: string, refreshToken: string, expiresIn: number }
     ```
   - Change: More detailed response
   - Action: Update spec to match implementation

**Endpoints Missing:**
- None ✅

**Extra Endpoints (Not in Spec):**
1. GET /api/auth/session
   - Found in code but not documented
   - Action: Add to spec

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗄️ Data Model Drift
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ All tables and fields match spec! No drift detected.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Recommended Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Critical (Fix Immediately):**
1. Update API signatures in spec (2 endpoints changed)
2. Implement missing requirements or remove from spec (2 items)

**Important (Fix Soon):**
1. Sync task statuses between spec checklist and Linear (3 mismatches)
2. Document unplanned features added during implementation (1 endpoint)

**Nice to Have:**
1. Add performance monitoring for NFR validation
2. Create missing Linear tasks for spec items

**Estimated Time to Sync**: 2-3 hours

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5: Ask User How to Resolve Drift

Use **AskUserQuestion**:

```javascript
{
  questions: [{
    question: "Drift detected! How would you like to resolve it?",
    header: "Sync Action",
    multiSelect: false,
    options: [
      {
        label: "Update Spec to Match Reality",
        description: "Modify spec doc to reflect current implementation (recommended)"
      },
      {
        label: "Update Implementation to Match Spec",
        description: "Modify code to match original spec design"
      },
      {
        label: "Hybrid Approach",
        description: "Update spec for some items, code for others (I'll choose)"
      },
      {
        label: "Review Only",
        description: "Just show the report, I'll fix manually"
      }
    ]
  }]
}
```

### Step 6: Apply Sync Changes

#### If "Update Spec to Match Reality":

```javascript
// Update spec document with actual implementation

// 1. Update Requirements section
updateSpecSection(doc, 'requirements', {
  add: drift.requirements.extra,
  remove: drift.requirements.missing,
  modify: drift.requirements.changed
})

// 2. Update API Design section
updateSpecSection(doc, 'api-design', {
  updateSignatures: drift.api.signatureChanged,
  addEndpoints: drift.api.endpointsExtra
})

// 3. Update Task Checklist
updateSpecChecklist(doc, {
  check: drift.tasks.statusMismatch.filter(t => t.linearStatus === 'Done'),
  uncheck: drift.tasks.statusMismatch.filter(t => t.linearStatus !== 'Done'),
  add: drift.tasks.inLinearNotSpec
})

// 4. Add "Change Log" entry
appendToChangeLog(doc, {
  date: new Date().toISOString().split('T')[0],
  change: 'Synced spec with implementation reality',
  details: `Updated ${changesCount} sections to match current implementation`,
  author: currentUser
})

// 5. Update "Last Synced" timestamp in spec
updateMetadata(doc, {
  lastSynced: new Date().toISOString()
})
```

#### If "Update Implementation to Match Spec":

```javascript
// Show what needs to be implemented to match spec

const implementationPlan = {
  missingRequirements: drift.requirements.missing,
  missingEndpoints: drift.api.endpointsMissing,
  changedSignatures: drift.api.signatureChanged,
  missingTasks: drift.tasks.inSpecNotLinear
}

// Show plan and ask if user wants to create Linear tasks for fixes
const tasks = generateFixTasks(implementationPlan)

// Offer to create tasks via /ccpm:spec:break-down or manually
```

#### If "Hybrid Approach":

```javascript
// Show each drift item and ask user decision

for (const item of allDriftItems) {
  const choice = await askUserQuestion({
    question: `Drift: ${item.description}. How to resolve?`,
    options: [
      "Update Spec",
      "Update Code",
      "Keep As Is"
    ]
  })

  if (choice === "Update Spec") {
    updateSpec(item)
  } else if (choice === "Update Code") {
    addToImplementationBacklog(item)
  }
  // else: skip
}
```

### Step 7: Display Sync Results

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Spec Synced Successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 Document: [DOC-456](link)
🔄 Sync Method: [Update Spec to Match Reality]
📊 Changes Applied: 12

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Changes Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Requirements Section:**
- ✅ Added: 1 new requirement (Social Login)
- ✅ Removed: 2 unimplemented requirements
- ✅ Updated: 1 changed requirement (Rate Limiting)

**API Design Section:**
- ✅ Updated: 2 endpoint signatures
- ✅ Added: 1 undocumented endpoint (GET /api/auth/session)

**Task Checklist:**
- ✅ Checked: 2 completed tasks
- ✅ Added: 1 new task (Bug Fixes)

**Metadata:**
- ✅ Last Synced: ${new Date().toISOString().split('T')[0]}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 New Drift Score: 5% (was 85%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 8: Interactive Next Actions

```javascript
{
  questions: [{
    question: "Sync complete! What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "Review Updated Spec",
        description: "Open spec document in Linear to review changes"
      },
      {
        label: "Review Spec",
        description: "Run /ccpm:spec:review to validate updated spec"
      },
      {
        label: "View Project Status",
        description: "Check overall project status (/ccpm:utils:status)"
      },
      {
        label: "Done",
        description: "Finish for now"
      }
    ]
  }]
}
```

## Drift Score Calculation

```javascript
function calculateDriftScore(drift) {
  let totalItems = 0
  let driftItems = 0

  // Requirements
  totalItems += drift.requirements.total
  driftItems += drift.requirements.missing.length +
                drift.requirements.extra.length +
                drift.requirements.changed.length

  // Tasks
  totalItems += drift.tasks.total
  driftItems += drift.tasks.statusMismatch.length +
                drift.tasks.inSpecNotLinear.length +
                drift.tasks.inLinearNotSpec.length

  // API
  totalItems += drift.api.total
  driftItems += drift.api.endpointsMissing.length +
                drift.api.endpointsExtra.length +
                drift.api.signatureChanged.length

  // Data Model
  totalItems += drift.dataModel.total
  driftItems += drift.dataModel.tablesMissing.length +
                drift.dataModel.tablesExtra.length +
                drift.dataModel.fieldsMissing.length +
                drift.dataModel.fieldsChanged.length

  // Calculate percentage
  if (totalItems === 0) return 0

  const driftPercentage = Math.round((driftItems / totalItems) * 100)

  return driftPercentage
}

function getDriftGrade(score) {
  if (score <= 10) return { grade: 'A', label: 'Excellent Sync' }
  if (score <= 25) return { grade: 'B', label: 'Minor Drift' }
  if (score <= 50) return { grade: 'C', label: 'Moderate Drift' }
  if (score <= 75) return { grade: 'D', label: 'Major Drift' }
  return { grade: 'F', label: 'Significant Drift' }
}
```

## Notes

- Non-destructive: Always creates backups before updating
- Bidirectional: Can sync spec → code or code → spec
- Smart Detection: Uses codebase analysis to find actual implementation
- Preserves Intent: Asks user before resolving ambiguous drift
- Change Log: Tracks all sync operations in spec document
- Drift Score: Quantifies how much spec diverged from reality
