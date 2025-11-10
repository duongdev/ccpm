---
description: Quick planning for NV Internal tasks without external PM systems
allowed-tools: [Bash, LinearMCP, Context7MCP]
argument-hint: "<task-description>" <project>
---

# Quick Planning: $ARGUMENTS

You are doing **Quick Planning** for: **$1** in project **$2**.

This command is for **NV Internal** or other projects without external PM systems (no Jira/Confluence).

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to external PM systems without explicit user confirmation.

- ✅ **Linear** operations are permitted (our internal tracking)
- ⛔ **External systems** require user confirmation for write operations

## Quick Planning Workflow

### Step 1: Understand the Task

Task Description: $1  
Project: $2

### Step 2: Analyze Codebase

1. **Read relevant files**:
   - Identify what needs to be implemented
   - Find similar patterns in existing code
   - Understand current architecture

2. **Identify conventions**:
   - Code organization
   - Naming patterns
   - Testing approach

### Step 3: Search for Best Practices

**Use Context7 MCP** to:
- Search for latest recommendations for this type of task
- Find modern approaches and patterns
- **CRITICAL**: Do NOT rely on knowledge cutoff - always search

### Step 4: Create Linear Issue

Use **Linear MCP** to create issue:

**Team & Project**: 
- NV Internal → Team: "Personal", Project: "NV Internal"

**Title**: $1  
**Status**: Planning  
**Labels**: $2, planning

**Description**:

```markdown
## Task Description
$1

## Codebase Analysis

**Current State**:
- [How things work now]
- [Relevant files]

**Patterns to Follow**:
- [Code patterns found]
- [Conventions used in project]

## Best Practices (from Context7)
- [Latest recommended approach]
- [Modern patterns to use]
- [Performance/security considerations]

## Implementation Plan

**Approach**:
[How to implement this]

**Technical Details**:
- [Specific implementation notes]
- [Edge cases to handle]

**Testing Strategy**:
- [How to test this]

## Checklist

- [ ] **Subtask 1**: [Specific task]
- [ ] **Subtask 2**: [Specific task]
- [ ] **Subtask 3**: [Specific task]
```

### Step 5: Confirm

Display:
```
✅ Quick Planning Complete!

📋 Linear Issue: [PROJECT-123]
🔗 URL: https://linear.app/workspace/issue/[PROJECT-123]

📊 Summary:
- Analyzed codebase patterns
- Found [X] relevant files
- Researched best practices

✅ Checklist: [X] subtasks created

🚀 Run: /start [PROJECT-123]
```

## Notes

- Focus on practical, actionable subtasks
- Keep descriptions concise but clear
- Always check Context7 for latest approaches
- Reference existing code patterns when possible