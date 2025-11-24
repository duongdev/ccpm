# Shared Smart Next-Action Suggestions

This file provides smart next-action suggestion logic used by the new natural workflow commands.

## Purpose

Automatically suggest the most appropriate next action based on:
- Current workflow stage
- Task status and progress
- Time since last action
- Blockers or dependencies

## Next Action Functions

### 1. Determine Next Action After Planning

```javascript
async function suggestAfterPlan(issueId) {
  const issue = await linear_get_issue(issueId)
  const status = issue.status
  const progress = calculateProgress(issue.description)

  // Just created/planned - ready to start
  return {
    primary: {
      action: 'work',
      command: `/ccpm:work ${issueId}`,
      label: 'Start Implementation',
      description: 'Begin working on this task',
      icon: '🚀'
    },
    alternatives: [
      {
        action: 'sync',
        command: `/ccpm:sync`,
        label: 'Save Progress',
        description: 'Sync progress to Linear'
      },
      {
        action: 'commit',
        command: `/ccpm:commit`,
        label: 'Commit Changes',
        description: 'Create git commit'
      }
    ]
  }
}
```

### 2. Determine Next Action After Work

```javascript
async function suggestAfterWork(issueId) {
  const issue = await linear_get_issue(issueId)
  const progress = calculateProgress(issue.description)
  const uncommitted = detectUncommittedChanges()

  // Has uncommitted changes - should commit or sync
  if (uncommitted.hasChanges) {
    return {
      primary: {
        action: 'commit',
        command: `/ccpm:commit ${issueId}`,
        label: 'Commit Changes',
        description: `Commit ${uncommitted.summary}`,
        icon: '💾'
      },
      alternatives: [
        {
          action: 'sync',
          command: `/ccpm:sync ${issueId}`,
          label: 'Sync Progress',
          description: 'Save progress to Linear without committing'
        },
        {
          action: 'work',
          command: `/ccpm:work ${issueId}`,
          label: 'Continue Working',
          description: 'Keep working on subtasks'
        }
      ]
    }
  }

  // No uncommitted changes, check if complete
  if (progress.isComplete) {
    return {
      primary: {
        action: 'verify',
        command: `/ccpm:verify ${issueId}`,
        label: 'Run Verification',
        description: 'All tasks complete, run quality checks',
        icon: '✅'
      },
      alternatives: [
        {
          action: 'work',
          command: `/ccpm:work ${issueId}`,
          label: 'Continue Working',
          description: 'Make more changes'
        }
      ]
    }
  }

  // In progress, not complete - continue working
  return {
    primary: {
      action: 'work',
      command: `/ccpm:work ${issueId}`,
      label: 'Continue Working',
      description: `${progress.remaining} tasks remaining`,
      icon: '⚡'
    },
    alternatives: [
      {
        action: 'sync',
        command: `/ccpm:sync ${issueId}`,
        label: 'Sync Progress',
        description: 'Save current progress'
      }
    ]
  }
}
```

### 3. Determine Next Action After Sync

```javascript
async function suggestAfterSync(issueId) {
  const issue = await linear_get_issue(issueId)
  const progress = calculateProgress(issue.description)
  const uncommitted = detectUncommittedChanges()

  // Has uncommitted changes - should commit
  if (uncommitted.hasChanges) {
    return {
      primary: {
        action: 'commit',
        command: `/ccpm:commit ${issueId}`,
        label: 'Commit Changes',
        description: 'Commit your work to git',
        icon: '💾'
      },
      alternatives: [
        {
          action: 'work',
          command: `/ccpm:work ${issueId}`,
          label: 'Continue Working',
          description: 'Keep making changes'
        }
      ]
    }
  }

  // All committed, check if complete
  if (progress.isComplete) {
    return {
      primary: {
        action: 'verify',
        command: `/ccpm:verify ${issueId}`,
        label: 'Run Verification',
        description: 'All tasks complete, verify quality',
        icon: '✅'
      },
      alternatives: []
    }
  }

  // Not complete - continue working
  return {
    primary: {
      action: 'work',
      command: `/ccpm:work ${issueId}`,
      label: 'Continue Working',
      description: `${progress.remaining} tasks remaining`,
      icon: '⚡'
    },
    alternatives: []
  }
}
```

### 4. Determine Next Action After Commit

```javascript
async function suggestAfterCommit(issueId) {
  const issue = await linear_get_issue(issueId)
  const progress = calculateProgress(issue.description)
  const pushed = isBranchPushed()

  // Not pushed - should sync and maybe push
  if (!pushed.isPushed) {
    return {
      primary: {
        action: 'sync',
        command: `/ccpm:sync ${issueId}`,
        label: 'Sync to Linear',
        description: 'Update Linear with progress',
        icon: '🔄'
      },
      alternatives: [
        {
          action: 'push',
          command: `git push -u origin ${pushed.branch}`,
          label: 'Push to Remote',
          description: 'Push commits to GitHub'
        },
        {
          action: 'work',
          command: `/ccpm:work ${issueId}`,
          label: 'Continue Working',
          description: 'Keep making changes'
        }
      ]
    }
  }

  // Pushed, check if complete
  if (progress.isComplete) {
    return {
      primary: {
        action: 'verify',
        command: `/ccpm:verify ${issueId}`,
        label: 'Run Verification',
        description: 'All done, verify quality',
        icon: '✅'
      },
      alternatives: []
    }
  }

  // Not complete - work or sync
  return {
    primary: {
      action: 'work',
      command: `/ccpm:work ${issueId}`,
      label: 'Continue Working',
      description: `${progress.remaining} tasks remaining`,
      icon: '⚡'
    },
    alternatives: [
      {
        action: 'sync',
        command: `/ccpm:sync ${issueId}`,
        label: 'Sync Progress',
        description: 'Update Linear'
      }
    ]
  }
}
```

### 5. Determine Next Action After Verify

```javascript
async function suggestAfterVerify(issueId, verificationPassed) {
  if (!verificationPassed) {
    // Verification failed - fix issues
    return {
      primary: {
        action: 'fix',
        command: `/ccpm:verification:fix ${issueId}`,
        label: 'Fix Issues',
        description: 'Debug and fix verification failures',
        icon: '🔧'
      },
      alternatives: [
        {
          action: 'work',
          command: `/ccpm:work ${issueId}`,
          label: 'Make Changes',
          description: 'Continue implementation'
        }
      ]
    }
  }

  // Verification passed - ready to finalize
  return {
    primary: {
      action: 'done',
      command: `/ccpm:done ${issueId}`,
      label: 'Finalize Task',
      description: 'Create PR and mark complete',
      icon: '🎉'
    },
    alternatives: [
      {
        action: 'work',
        command: `/ccpm:work ${issueId}`,
        label: 'Make More Changes',
        description: 'Continue working'
      }
    ]
  }
}
```

## Display Template

### Standard Next Action Prompt

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 What's Next?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⭐ Recommended: ${primary.label}
   ${primary.description}

   ${primary.command}

${alternatives.length > 0 ? `
Or:
${alternatives.map((alt, i) => `
  ${i+1}. ${alt.label}
     ${alt.description}
     ${alt.command}
`).join('\n')}
` : ''}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Interactive Prompt with AskUserQuestion

```javascript
function createNextActionQuestion(suggestions) {
  const options = [
    {
      label: suggestions.primary.label,
      description: suggestions.primary.description
    }
  ]

  suggestions.alternatives.forEach(alt => {
    options.push({
      label: alt.label,
      description: alt.description
    })
  })

  return {
    questions: [{
      question: "What would you like to do next?",
      header: "Next Step",
      multiSelect: false,
      options
    }]
  }
}
```

## Context-Aware Suggestions

### Time-Based Suggestions

```javascript
function adjustForTime(suggestions, hoursSinceLastAction) {
  // If been >4 hours, suggest sync first
  if (hoursSinceLastAction > 4) {
    return {
      primary: {
        action: 'sync',
        command: `/ccpm:sync ${issueId}`,
        label: 'Sync Progress',
        description: 'It\'s been a while, sync your progress first',
        icon: '🔄'
      },
      alternatives: [suggestions.primary, ...suggestions.alternatives]
    }
  }

  return suggestions
}
```

### Status-Based Suggestions

```javascript
function adjustForStatus(suggestions, status) {
  // If status is "Blocked", prioritize fixing
  if (status === 'Blocked') {
    return {
      primary: {
        action: 'fix',
        command: `/ccpm:verification:fix ${issueId}`,
        label: 'Fix Blockers',
        description: 'Task is blocked, resolve issues first',
        icon: '🔧'
      },
      alternatives: [suggestions.primary, ...suggestions.alternatives]
    }
  }

  return suggestions
}
```

## Usage in Commands

Each command should call the appropriate suggestion function at the end:

```javascript
// In /ccpm:plan
const suggestions = await suggestAfterPlan(issueId)
displayNextActions(suggestions)

// In /ccpm:work
const suggestions = await suggestAfterWork(issueId)
displayNextActions(suggestions)

// In /ccpm:sync
const suggestions = await suggestAfterSync(issueId)
displayNextActions(suggestions)

// In /ccpm:commit
const suggestions = await suggestAfterCommit(issueId)
displayNextActions(suggestions)

// In /ccpm:verify
const suggestions = await suggestAfterVerify(issueId, verificationPassed)
displayNextActions(suggestions)
```

## Benefits

✅ **Context-Aware**: Different suggestions based on workflow stage
✅ **Time-Sensitive**: Adjusts based on time since last action
✅ **Status-Aware**: Considers blockers and task status
✅ **Progressive**: Guides users through complete workflow
✅ **Flexible**: Users can choose alternatives if primary doesn't fit
