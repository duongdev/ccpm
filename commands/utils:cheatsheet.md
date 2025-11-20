---
description: Visual workflow cheatsheet - Quick reference for all CCPM commands
allowed-tools: []
---

# CCPM Workflow Cheatsheet

**Quick visual reference for CCPM commands and workflows.**

```assistant
I'll show you a comprehensive CCPM workflow cheatsheet with visual diagrams.

---

# 🗺️ CCPM Workflow Cheatsheet

## 📊 Quick Command Finder

**What do you want to do?**

```
┌─────────────────────────────────────────────────────────────┐
│  Starting a new project/feature?                             │
│  → Spec-First Workflow (Section 1)                          │
├─────────────────────────────────────────────────────────────┤
│  Working on a small task?                                    │
│  → Task-First Workflow (Section 2)                          │
├─────────────────────────────────────────────────────────────┤
│  Have existing markdown specs?                               │
│  → /ccpm:spec:migrate                                       │
├─────────────────────────────────────────────────────────────┤
│  Resuming work on a task?                                    │
│  → /ccpm:utils:context <issue-id>                           │
├─────────────────────────────────────────────────────────────┤
│  Need project overview?                                      │
│  → /ccpm:utils:report <project>                             │
├─────────────────────────────────────────────────────────────┤
│  Stuck or need help?                                         │
│  → /ccpm:utils:help [issue-id]                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 1️⃣ Spec-First Workflow (Recommended for Features)

**Use when:** Building new features, major projects, or anything requiring detailed planning

```
START
  │
  ├─► 📋 Create Epic/Feature
  │   /ccpm:spec:create epic "User Authentication"
  │   /ccpm:spec:create feature "JWT Auth" EPIC-123
  │
  ├─► ✍️  Write Comprehensive Spec
  │   /ccpm:spec:write DOC-123 all
  │   OR write section by section:
  │   /ccpm:spec:write DOC-123 requirements
  │   /ccpm:spec:write DOC-123 architecture
  │   /ccpm:spec:write DOC-123 api-design
  │   /ccpm:spec:write DOC-123 data-model
  │   /ccpm:spec:write DOC-123 testing
  │   /ccpm:spec:write DOC-123 security
  │
  ├─► 🔍 Review & Validate Spec
  │   /ccpm:spec:review DOC-123
  │   (AI grades A-F, suggests improvements)
  │
  ├─► 📦 Break Down into Tasks
  │   /ccpm:spec:break-down WORK-100
  │   (Creates Features from Epic, or Tasks from Feature)
  │
  ├─► 🚀 Implementation Phase
  │   [Continue with Task-First Workflow below]
  │
  └─► 🔄 Keep Spec in Sync
      /ccpm:spec:sync WORK-100
      (Run periodically during implementation)
```

**Spec Sections Available:**
- `requirements` - Functional, non-functional, acceptance criteria
- `architecture` - System design, component breakdown
- `api-design` - Endpoints, request/response schemas
- `data-model` - Database schema, TypeScript types
- `testing` - Test strategies (unit, integration, E2E)
- `security` - Auth, validation, rate limiting
- `user-flow` - User journeys, wireframes
- `timeline` - Task breakdown, estimates
- `all` - Write all sections sequentially

---

## 2️⃣ Task-First Workflow (Quick Implementation)

**Use when:** Small tasks, bug fixes, or quick features

```
START
  │
  ├─► 📝 Create Task + Plan
  │   /ccpm:planning:create "Add dark mode" my-project JIRA-123
  │   OR (without external PM):
  │   /ccpm:planning:quick-plan "Add dark mode" my-project
  │
  ├─► 🎯 Get AI Insights (Optional)
  │   /ccpm:utils:insights WORK-200
  │   (Complexity scoring, risk analysis)
  │
  ├─► 🤖 Auto-Assign Agents (Optional)
  │   /ccpm:utils:auto-assign WORK-200
  │   (AI suggests optimal agent for each subtask)
  │
  ├─► 🚀 Start Implementation
  │   /ccpm:implementation:start WORK-200
  │   (Agent coordination begins)
  │
  ├─► 🔄 Work on Subtasks
  │   /ccpm:implementation:next WORK-200
  │   (AI suggests optimal next subtask)
  │
  │   Update progress:
  │   /ccpm:implementation:update WORK-200 0 completed "Done"
  │
  │   Save progress & findings:
  │   /ccpm:implementation:sync WORK-200
  │
  ├─► ✅ Quality Checks
  │   /ccpm:verification:check WORK-200
  │   (Lint, tests, IDE warnings)
  │
  ├─► 🔍 Final Verification
  │   /ccpm:verification:verify WORK-200
  │   (Comprehensive review by verification-agent)
  │
  │   If failures:
  │   /ccpm:verification:fix WORK-200
  │
  └─► 🎉 Finalize & Complete
      /ccpm:complete:finalize WORK-200
      (PR creation, Jira sync, Slack notification)
```

---

## 3️⃣ Planning Phase Commands

```
┌──────────────────────────────────────────────────────────────┐
│ Create new task + plan in one step                           │
│ /ccpm:planning:create "<title>" <project> [jira-id]         │
│                                                               │
│ Plan existing Linear issue                                   │
│ /ccpm:planning:plan <issue-id> [jira-id]                    │
│                                                               │
│ Quick planning (no external PM)                              │
│ /ccpm:planning:quick-plan "<desc>" <project>                │
│                                                               │
│ Update existing plan (interactive clarification)             │
│ /ccpm:planning:update <issue-id> "<update-request>"         │
└──────────────────────────────────────────────────────────────┘
```

**Update Plan Examples:**
```bash
/ccpm:planning:update WORK-123 "Also add email notifications"
/ccpm:planning:update WORK-456 "Use Redis instead of cache"
/ccpm:planning:update WORK-789 "Remove admin panel"
```

---

## 4️⃣ Implementation Phase Commands

```
┌──────────────────────────────────────────────────────────────┐
│ Start implementation with agent coordination                 │
│ /ccpm:implementation:start <issue-id>                        │
│                                                               │
│ Smart next action detection                                  │
│ /ccpm:implementation:next <issue-id>                         │
│                                                               │
│ Update subtask progress                                      │
│ /ccpm:implementation:update <id> <idx> <status> "<msg>"     │
│                                                               │
│ Sync progress & findings to Linear                           │
│ /ccpm:implementation:sync <issue-id> [summary]              │
└──────────────────────────────────────────────────────────────┘
```

**Status values:** `pending` | `in_progress` | `completed` | `blocked`

---

## 5️⃣ Verification Phase Commands

```
┌──────────────────────────────────────────────────────────────┐
│ Run quality checks (lint, tests, IDE warnings)               │
│ /ccpm:verification:check <issue-id>                          │
│                                                               │
│ Final comprehensive verification                             │
│ /ccpm:verification:verify <issue-id>                         │
│                                                               │
│ Fix verification failures                                    │
│ /ccpm:verification:fix <issue-id>                            │
└──────────────────────────────────────────────────────────────┘
```

---

## 6️⃣ Completion Phase Commands

```
┌──────────────────────────────────────────────────────────────┐
│ Post-completion workflow (PR, Jira sync, Slack)              │
│ /ccpm:complete:finalize <issue-id>                           │
│                                                               │
│ Final spec sync (recommended)                                │
│ /ccpm:spec:sync <issue-id>                                   │
└──────────────────────────────────────────────────────────────┘
```

---

## 7️⃣ Utility Commands (Available Anytime)

```
┌──────────────────────────────────────────────────────────────┐
│ 📊 Status & Context                                          │
│ /ccpm:utils:status <issue-id>     - Detailed task status    │
│ /ccpm:utils:context <issue-id>    - Load full context       │
│ /ccpm:utils:report <project>      - Project-wide report     │
│                                                               │
│ 🤖 AI-Powered Analysis                                       │
│ /ccpm:utils:insights <issue-id>   - Complexity & risk       │
│ /ccpm:utils:auto-assign <id>      - Optimal agent assign    │
│                                                               │
│ 🔗 Dependencies & Structure                                  │
│ /ccpm:utils:dependencies <id>     - Visualize dependencies  │
│ /ccpm:utils:agents                - List available agents   │
│                                                               │
│ 🔄 Sync & History                                            │
│ /ccpm:utils:sync-status <id>      - Sync to Jira           │
│ /ccpm:utils:rollback <issue-id>   - Rollback to previous   │
│                                                               │
│ ❓ Help                                                       │
│ /ccpm:utils:help                   - General help           │
│ /ccpm:utils:help <issue-id>       - Context-aware help     │
└──────────────────────────────────────────────────────────────┘
```

---

## 8️⃣ Spec Management Commands

```
┌──────────────────────────────────────────────────────────────┐
│ 📋 Create & Structure                                        │
│ /ccpm:spec:create epic "<title>"                            │
│ /ccpm:spec:create feature "<title>" [parent-id]             │
│                                                               │
│ ✍️  Write Spec Content                                       │
│ /ccpm:spec:write <doc-id> <section>                         │
│ Sections: requirements, architecture, api-design,            │
│           data-model, testing, security, user-flow,          │
│           timeline, all                                      │
│                                                               │
│ 🔍 Review & Break Down                                       │
│ /ccpm:spec:review <doc-id>        - AI validation          │
│ /ccpm:spec:break-down <id>        - Generate tasks         │
│                                                               │
│ 🔄 Sync & Migration                                          │
│ /ccpm:spec:sync <id>              - Sync with code          │
│ /ccpm:spec:migrate <path>         - Migrate from markdown   │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎨 UI Design Workflow (New)

**Use when:** Designing user interfaces

```
START
  │
  ├─► 🎨 Design UI
  │   /ccpm:planning:design-ui WORK-300
  │   (AI generates comprehensive UI design)
  │
  ├─► 🔄 Refine Design (if needed)
  │   /ccpm:planning:design-refine WORK-300 "<refinement>"
  │
  ├─► ✅ Approve Design
  │   /ccpm:planning:design-approve WORK-300
  │   (Marks design as approved, ready for implementation)
  │
  └─► 🚀 Continue with Implementation
      /ccpm:implementation:start WORK-300
```

---

## 🔄 Common Workflow Patterns

### Pattern A: Feature Development (Complete)
```bash
# 1. Create epic with spec
/ccpm:spec:create epic "User Authentication System"

# 2. Write comprehensive spec
/ccpm:spec:write DOC-100 all

# 3. Review spec
/ccpm:spec:review DOC-100

# 4. Break down into features
/ccpm:spec:break-down WORK-100

# 5. For each feature, write detailed spec
/ccpm:spec:write DOC-101 all

# 6. Break feature into tasks
/ccpm:spec:break-down WORK-101

# 7. Implement each task
/ccpm:implementation:start WORK-201
/ccpm:verification:check WORK-201
/ccpm:verification:verify WORK-201
/ccpm:complete:finalize WORK-201

# 8. Keep spec in sync throughout
/ccpm:spec:sync WORK-101
```

### Pattern B: Quick Task (Express)
```bash
# 1. Create + plan
/ccpm:planning:create "Add dark mode" my-project

# 2. Implement
/ccpm:implementation:start WORK-300

# 3. Verify & complete
/ccpm:verification:check WORK-300
/ccpm:verification:verify WORK-300
/ccpm:complete:finalize WORK-300
```

### Pattern C: Resume Work
```bash
# Morning: Check project status
/ccpm:utils:report my-project

# Load task context
/ccpm:utils:context WORK-150

# Continue where you left off
/ccpm:implementation:next WORK-150

# End of day: Save progress
/ccpm:implementation:sync WORK-150
```

### Pattern D: Migration + Spec Workflow
```bash
# 1. Migrate existing specs
/ccpm:spec:migrate ~/personal/my-project

# 2. Review migrated items
/ccpm:utils:report my-project

# 3. Sync with codebase
/ccpm:spec:sync WORK-102

# 4. Continue with spec workflow
/ccpm:spec:break-down WORK-102
/ccpm:implementation:start WORK-201
```

---

## 🎯 Decision Trees

### "I'm starting something new..."

```
Are you building a major feature or project?
├─ YES → Use Spec-First Workflow
│        1. /ccpm:spec:create
│        2. /ccpm:spec:write
│        3. /ccpm:spec:review
│        4. /ccpm:spec:break-down
│
└─ NO → Use Task-First Workflow
         1. /ccpm:planning:create
         2. /ccpm:implementation:start
```

### "I have existing markdown specs..."

```
Do you have markdown files in .claude/?
└─ YES → Migrate first
         1. /ccpm:spec:migrate <path>
         2. /ccpm:utils:report <project>
         3. Continue with spec workflow
```

### "I'm stuck on a task..."

```
What's the issue?
├─ Don't know what to do next
│  → /ccpm:implementation:next <issue-id>
│
├─ Task seems too complex
│  → /ccpm:utils:insights <issue-id>
│
├─ Not sure which agent to use
│  → /ccpm:utils:auto-assign <issue-id>
│
├─ Need to understand dependencies
│  → /ccpm:utils:dependencies <issue-id>
│
└─ Need context refresh
   → /ccpm:utils:context <issue-id>
```

### "I'm ready to finish..."

```
Are all subtasks complete?
├─ YES → Run quality checks
│        1. /ccpm:verification:check <issue-id>
│        2. /ccpm:verification:verify <issue-id>
│        3. /ccpm:complete:finalize <issue-id>
│
└─ NO → Find next action
         /ccpm:implementation:next <issue-id>
```

---

## 📋 Command Syntax Quick Reference

### Spec Management
```bash
/ccpm:spec:create epic|feature "<title>" [parent-id]
/ccpm:spec:write <doc-id> requirements|architecture|api-design|data-model|testing|security|user-flow|timeline|all
/ccpm:spec:review <doc-id>
/ccpm:spec:break-down <epic-or-feature-id>
/ccpm:spec:migrate <project-path> [category]
/ccpm:spec:sync <doc-id-or-issue-id>
```

### Planning
```bash
/ccpm:planning:create "<title>" <project> [jira-id]
/ccpm:planning:plan <issue-id> [jira-id]
/ccpm:planning:quick-plan "<description>" <project>
/ccpm:planning:update <issue-id> "<update-request>"
/ccpm:planning:design-ui <issue-id>
/ccpm:planning:design-refine <issue-id> "<refinement>"
/ccpm:planning:design-approve <issue-id>
```

### Implementation
```bash
/ccpm:implementation:start <issue-id>
/ccpm:implementation:next <issue-id>
/ccpm:implementation:update <issue-id> <idx> <status> "<message>"
/ccpm:implementation:sync <issue-id> [summary]
```

### Verification
```bash
/ccpm:verification:check <issue-id>
/ccpm:verification:verify <issue-id>
/ccpm:verification:fix <issue-id>
```

### Completion
```bash
/ccpm:complete:finalize <issue-id>
```

### Utilities
```bash
/ccpm:utils:status <issue-id>
/ccpm:utils:context <issue-id>
/ccpm:utils:report <project>
/ccpm:utils:insights <issue-id>
/ccpm:utils:auto-assign <issue-id>
/ccpm:utils:sync-status <issue-id>
/ccpm:utils:rollback <issue-id>
/ccpm:utils:dependencies <issue-id>
/ccpm:utils:agents
/ccpm:utils:help [issue-id]
/ccpm:utils:cheatsheet
```

### Project-Specific
```bash
/ccpm:repeat:check-pr <pr-number-or-url>
```

---

## 💡 Pro Tips

### Workflow Tips
- **Interactive Mode**: Every command suggests next actions - trust the flow!
- **Context Loading**: Use `/ccpm:utils:context` when resuming work
- **Daily Standup**: Start with `/ccpm:utils:report <project>`
- **Spec Sync**: Run `/ccpm:spec:sync` periodically during implementation
- **Get Help**: Use `/ccpm:utils:help <issue-id>` for context-aware suggestions

### Efficiency Tips
- **Parallel Work**: Use `/ccpm:utils:auto-assign` to identify parallel tasks
- **Dependencies**: Check `/ccpm:utils:dependencies` before starting
- **Insights Early**: Run `/ccpm:utils:insights` for complex tasks upfront
- **Rollback**: Made a mistake? Use `/ccpm:utils:rollback`

### Quality Tips
- **Always check before verify**: `/ccpm:verification:check` catches issues early
- **Spec-First for features**: Better estimates, fewer surprises
- **Review specs**: `/ccpm:spec:review` ensures completeness before coding
- **Keep specs synced**: Drift reports help maintain documentation

---

## 🚨 Safety Reminders

⛔ **Never writes to external systems without confirmation:**
- Jira (issues, comments, status changes)
- Confluence (pages, edits)
- BitBucket (pull requests, comments)
- Slack (messages, posts)

✅ **Always allowed:**
- Read operations from external systems
- Linear operations (internal tracking)
- Local file operations

📖 Full details: See `SAFETY_RULES.md`

---

## 📚 More Help

- **Comprehensive Guide**: See `README.md` in commands directory
- **Context-Aware Help**: `/ccpm:utils:help <issue-id>`
- **General Help**: `/ccpm:utils:help`
- **Available Agents**: `/ccpm:utils:agents`

---

💡 **What would you like to do next?**

1. ⭐ Start with Pattern A, B, C, or D above
2. 🔍 Get help for specific task → `/ccpm:utils:help <issue-id>`
3. 📊 Check project status → `/ccpm:utils:report <project>`
4. 📋 Load task context → `/ccpm:utils:context <issue-id>`
5. 🎯 Find next action → `/ccpm:implementation:next <issue-id>`
6. ❓ Ask me anything about CCPM workflow

```
