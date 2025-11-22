# Shared Checklist Utilities (Unified Parsing & Update Logic)

This file provides reusable utility functions for checklist management across CCPM commands. **These functions implement robust parsing, updating, and progress calculation for Implementation Checklists in Linear issue descriptions.**

## Overview

All CCPM commands that interact with checklists should use these utilities to ensure consistent behavior:

- `parseChecklist()` - Extracts checklist from description (marker comments or header-based)
- `updateChecklistItems()` - Updates checkbox states and recalculates progress
- `calculateProgress()` - Computes completion percentage
- `formatProgressLine()` - Generates standardized progress line
- `validateChecklistStructure()` - Checks checklist integrity

**Key Benefits**:
- **Consistent parsing** - Handles both marker comments and header-based formats
- **Robust updates** - Atomic checkbox state changes with progress calculation
- **Error resilience** - Graceful handling of malformed or missing checklists
- **Maintainability** - Single source of truth for checklist logic

**Usage in commands:** Reference this file at the start of command execution:
```markdown
READ: commands/_shared-checklist-helpers.md
```

Then use the functions as described below.

---

## Functions

### 1. parseChecklist

Extracts checklist items from a Linear issue description, supporting both marker comment and header-based formats.

```javascript
/**
 * Parse checklist from Linear issue description
 * @param {string} description - Full issue description (markdown)
 * @returns {Object|null} Parsed checklist or null if not found
 * @returns {Array<Object>} items - Parsed checklist items
 * @returns {number} items[].index - 0-based index
 * @returns {boolean} items[].checked - Checkbox state
 * @returns {string} items[].content - Item text (without checkbox)
 * @returns {string} format - 'marker' or 'header'
 * @returns {number} startLine - Line number where checklist starts
 * @returns {number} endLine - Line number where checklist ends
 * @returns {string|null} progressLine - Existing progress line text
 * @returns {number|null} progressLineNumber - Line number of progress line
 */
function parseChecklist(description) {
  if (!description || typeof description !== 'string') {
    return null;
  }

  const lines = description.split('\n');
  let format = null;
  let startLine = -1;
  let endLine = -1;
  let progressLine = null;
  let progressLineNumber = null;

  // Strategy 1: Try marker comment detection (preferred)
  const startMarkerIndex = lines.findIndex(
    line => line.trim() === '<!-- ccpm-checklist-start -->'
  );

  if (startMarkerIndex !== -1) {
    // Found start marker, look for end marker
    const endMarkerIndex = lines.findIndex(
      (line, idx) => idx > startMarkerIndex && line.trim() === '<!-- ccpm-checklist-end -->'
    );

    if (endMarkerIndex !== -1) {
      format = 'marker';
      startLine = startMarkerIndex + 1; // First line after marker
      endLine = endMarkerIndex - 1; // Last line before marker

      // Look for progress line after end marker (within 3 lines)
      for (let i = endMarkerIndex + 1; i < Math.min(endMarkerIndex + 4, lines.length); i++) {
        if (lines[i].match(/^Progress: \d+% \(\d+\/\d+ completed\)/)) {
          progressLine = lines[i];
          progressLineNumber = i;
          break;
        }
      }
    }
  }

  // Strategy 2: Fallback to header-based detection
  if (format === null) {
    const headerPatterns = [
      /^## ✅ Implementation Checklist/,
      /^## Implementation Checklist/,
      /^## ✅ Checklist/,
      /^## Checklist/
    ];

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (headerPatterns.some(pattern => pattern.test(line))) {
        format = 'header';
        startLine = i + 1;

        // Find end: next ## header or end of description
        endLine = lines.length - 1;
        for (let j = i + 1; j < lines.length; j++) {
          if (lines[j].match(/^##\s+/)) {
            endLine = j - 1;
            break;
          }
        }

        // Look for progress line before next header
        for (let j = i + 1; j <= endLine; j++) {
          if (lines[j].match(/^Progress: \d+% \(\d+\/\d+ completed\)/)) {
            progressLine = lines[j];
            progressLineNumber = j;
            // Exclude progress line from checklist items
            if (endLine >= j) {
              endLine = j - 1;
            }
            break;
          }
        }

        break;
      }
    }
  }

  // No checklist found
  if (format === null || startLine === -1) {
    return null;
  }

  // Extract checklist items
  const items = [];
  const checkboxPattern = /^- \[([ x])\] (.+)$/;

  for (let i = startLine; i <= endLine; i++) {
    const line = lines[i].trim();
    const match = line.match(checkboxPattern);

    if (match) {
      items.push({
        index: items.length, // 0-based index
        checked: match[1] === 'x',
        content: match[2].trim(),
        originalLine: i
      });
    }
  }

  // Return null if no items found
  if (items.length === 0) {
    return null;
  }

  return {
    items,
    format,
    startLine,
    endLine,
    progressLine,
    progressLineNumber
  };
}
```

**Usage Example:**
```javascript
const description = `
## ✅ Implementation Checklist

<!-- ccpm-checklist-start -->
- [ ] Task 1: First task
- [x] Task 2: Second task
- [ ] Task 3: Third task
<!-- ccpm-checklist-end -->

Progress: 33% (1/3 completed)
Last updated: 2025-11-22 14:30 UTC
`;

const checklist = parseChecklist(description);

if (!checklist) {
  console.log("No checklist found");
} else {
  console.log(`Found ${checklist.items.length} items`);
  console.log(`Format: ${checklist.format}`);
  console.log(`Progress: ${checklist.progressLine}`);

  checklist.items.forEach(item => {
    console.log(`[${item.checked ? 'x' : ' '}] ${item.content}`);
  });
}
```

**Edge Cases Handled:**
- **No checklist** → Returns `null`
- **Marker comments only** → Prefers marker-based parsing
- **Header only** → Falls back to header detection
- **Empty checklist** → Returns `null` (no items)
- **Malformed items** → Skips lines that don't match pattern
- **Multiple checklists** → Uses first one found (marker takes precedence)
- **Progress line** → Detected and excluded from items

---

### 2. updateChecklistItems

Updates checkbox states for specific items and recalculates progress.

```javascript
/**
 * Update checklist item states and recalculate progress
 * @param {string} description - Original issue description
 * @param {number[]} indices - Array of item indices to update (0-based)
 * @param {boolean} markComplete - true = check boxes, false = uncheck boxes
 * @param {Object} options - Optional configuration
 * @param {boolean} options.addTimestamp - Add/update timestamp (default: true)
 * @returns {Object} Update result
 * @returns {string} updatedDescription - Modified description
 * @returns {number} changedCount - Number of items actually changed
 * @returns {Object} progress - New progress metrics
 * @returns {Array<string>} changedItems - Text of changed items (for logging)
 */
function updateChecklistItems(description, indices, markComplete, options = {}) {
  const addTimestamp = options.addTimestamp !== false;

  // Parse existing checklist
  const checklist = parseChecklist(description);

  if (!checklist) {
    throw new Error('No checklist found in description');
  }

  if (indices.length === 0) {
    throw new Error('No indices provided for update');
  }

  // Validate indices
  const invalidIndices = indices.filter(idx => idx < 0 || idx >= checklist.items.length);
  if (invalidIndices.length > 0) {
    throw new Error(`Invalid indices: ${invalidIndices.join(', ')}. Valid range: 0-${checklist.items.length - 1}`);
  }

  // Split description into lines for modification
  const lines = description.split('\n');

  // Track changes
  const changedItems = [];
  let changedCount = 0;

  // Update checkbox states
  indices.forEach(idx => {
    const item = checklist.items[idx];
    const targetState = markComplete;

    // Skip if already in target state
    if (item.checked === targetState) {
      return;
    }

    // Find and update the line
    const lineIdx = item.originalLine;
    const currentLine = lines[lineIdx];

    const newLine = markComplete
      ? currentLine.replace('- [ ]', '- [x]')
      : currentLine.replace('- [x]', '- [ ]');

    if (newLine !== currentLine) {
      lines[lineIdx] = newLine;
      changedItems.push(item.content);
      changedCount++;
    }
  });

  // Recalculate progress
  const updatedChecklist = parseChecklist(lines.join('\n'));
  if (!updatedChecklist) {
    throw new Error('Failed to parse updated checklist');
  }

  const progress = calculateProgress(updatedChecklist.items);

  // Update or insert progress line
  const newProgressLine = formatProgressLine(progress.completed, progress.total, addTimestamp);

  if (updatedChecklist.progressLineNumber !== null) {
    // Replace existing progress line
    lines[updatedChecklist.progressLineNumber] = newProgressLine;
  } else {
    // Insert after checklist end (or after end marker if using markers)
    const insertPosition = checklist.format === 'marker'
      ? checklist.endLine + 2 // After <!-- ccpm-checklist-end -->
      : checklist.endLine + 1; // After last checklist item

    // Ensure we have a blank line before progress
    if (lines[insertPosition] && lines[insertPosition].trim() !== '') {
      lines.splice(insertPosition, 0, '', newProgressLine);
    } else {
      lines.splice(insertPosition, 0, newProgressLine);
    }
  }

  return {
    updatedDescription: lines.join('\n'),
    changedCount,
    progress,
    changedItems
  };
}
```

**Usage Example:**
```javascript
const description = `
## ✅ Implementation Checklist

<!-- ccpm-checklist-start -->
- [ ] Task 1: First task
- [ ] Task 2: Second task
- [ ] Task 3: Third task
<!-- ccpm-checklist-end -->

Progress: 0% (0/3 completed)
`;

// Mark items 0 and 2 as complete
const result = updateChecklistItems(description, [0, 2], true);

console.log(`Changed ${result.changedCount} items`);
console.log(`New progress: ${result.progress.percentage}%`);
console.log(`Changed items: ${result.changedItems.join(', ')}`);
console.log(result.updatedDescription);

// Output:
// Changed 2 items
// New progress: 67%
// Changed items: Task 1: First task, Task 3: Third task
// [Updated description with items 0 and 2 checked]
```

**Edge Cases Handled:**
- **Invalid indices** → Throws error with details
- **Already in target state** → Skips update (idempotent)
- **No progress line** → Inserts new one
- **Existing progress line** → Updates in place
- **Empty indices array** → Throws error

---

### 3. calculateProgress

Computes completion percentage and counts from checklist items.

```javascript
/**
 * Calculate completion progress from checklist items
 * @param {Array<Object>} items - Checklist items from parseChecklist()
 * @returns {Object} Progress metrics
 * @returns {number} completed - Number of checked items
 * @returns {number} total - Total number of items
 * @returns {number} percentage - Completion percentage (0-100, rounded)
 */
function calculateProgress(items) {
  if (!items || items.length === 0) {
    return {
      completed: 0,
      total: 0,
      percentage: 0
    };
  }

  const total = items.length;
  const completed = items.filter(item => item.checked).length;
  const percentage = Math.round((completed / total) * 100);

  return {
    completed,
    total,
    percentage
  };
}
```

**Usage Example:**
```javascript
const items = [
  { index: 0, checked: true, content: 'Task 1' },
  { index: 1, checked: false, content: 'Task 2' },
  { index: 2, checked: true, content: 'Task 3' }
];

const progress = calculateProgress(items);
console.log(`${progress.percentage}% (${progress.completed}/${progress.total})`);
// Output: 67% (2/3)
```

**Edge Cases Handled:**
- **Empty array** → Returns 0% (0/0)
- **Null items** → Returns 0% (0/0)
- **All complete** → Returns 100%
- **None complete** → Returns 0%
- **Fractional percentages** → Rounds to nearest integer

---

### 4. formatProgressLine

Generates standardized progress line with optional timestamp.

```javascript
/**
 * Format progress line for checklist
 * @param {number} completed - Number of completed items
 * @param {number} total - Total number of items
 * @param {boolean} includeTimestamp - Add timestamp (default: true)
 * @returns {string} Formatted progress line
 */
function formatProgressLine(completed, total, includeTimestamp = true) {
  const percentage = total === 0 ? 0 : Math.round((completed / total) * 100);
  let line = `Progress: ${percentage}% (${completed}/${total} completed)`;

  if (includeTimestamp) {
    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 16);
    line += `\nLast updated: ${timestamp} UTC`;
  }

  return line;
}
```

**Usage Example:**
```javascript
// With timestamp
const line1 = formatProgressLine(2, 5);
console.log(line1);
// Output:
// Progress: 40% (2/5 completed)
// Last updated: 2025-11-22 14:30 UTC

// Without timestamp
const line2 = formatProgressLine(3, 3, false);
console.log(line2);
// Output:
// Progress: 100% (3/3 completed)
```

---

### 5. validateChecklistStructure

Validates checklist structure and returns warnings for issues.

```javascript
/**
 * Validate checklist structure and return warnings
 * @param {string} description - Issue description to validate
 * @returns {Object} Validation result
 * @returns {boolean} valid - Overall validity
 * @returns {Array<string>} warnings - List of warnings
 * @returns {Array<string>} suggestions - Suggestions to fix issues
 * @returns {Object|null} checklist - Parsed checklist (if valid)
 */
function validateChecklistStructure(description) {
  const warnings = [];
  const suggestions = [];

  // Try to parse
  const checklist = parseChecklist(description);

  if (!checklist) {
    return {
      valid: false,
      warnings: ['No checklist found in description'],
      suggestions: [
        'Add a checklist using marker comments:',
        '  <!-- ccpm-checklist-start -->',
        '  - [ ] Task 1',
        '  - [ ] Task 2',
        '  <!-- ccpm-checklist-end -->',
        '',
        'Or use a header:',
        '  ## ✅ Implementation Checklist',
        '  - [ ] Task 1',
        '  - [ ] Task 2'
      ],
      checklist: null
    };
  }

  // Check for marker comments (preferred)
  if (checklist.format === 'header') {
    warnings.push('Using header-based format (marker comments preferred)');
    suggestions.push(
      'Consider adding marker comments for more reliable parsing:',
      '  <!-- ccpm-checklist-start -->',
      '  ... existing checklist items ...',
      '  <!-- ccpm-checklist-end -->'
    );
  }

  // Check for progress line
  if (!checklist.progressLine) {
    warnings.push('No progress line found');
    suggestions.push(
      'Add a progress line after the checklist:',
      '  Progress: 0% (0/N completed)',
      '  Last updated: YYYY-MM-DD HH:MM UTC'
    );
  }

  // Check for empty checklist
  if (checklist.items.length === 0) {
    warnings.push('Checklist is empty (no items)');
    suggestions.push('Add checklist items using the format: - [ ] Task description');
  }

  // Check for very long items (>200 chars)
  const longItems = checklist.items.filter(item => item.content.length > 200);
  if (longItems.length > 0) {
    warnings.push(`${longItems.length} item(s) exceed 200 characters`);
    suggestions.push('Consider breaking long items into smaller tasks');
  }

  // Check for duplicate content
  const contentMap = new Map();
  checklist.items.forEach(item => {
    const normalized = item.content.toLowerCase().trim();
    if (contentMap.has(normalized)) {
      contentMap.set(normalized, contentMap.get(normalized) + 1);
    } else {
      contentMap.set(normalized, 1);
    }
  });

  const duplicates = Array.from(contentMap.entries()).filter(([_, count]) => count > 1);
  if (duplicates.length > 0) {
    warnings.push(`${duplicates.length} duplicate item(s) found`);
    suggestions.push('Review checklist for duplicate tasks');
  }

  return {
    valid: warnings.length === 0,
    warnings,
    suggestions,
    checklist
  };
}
```

**Usage Example:**
```javascript
const description = `
## Implementation Checklist
- [ ] Task 1
- [ ] Task 1
`;

const validation = validateChecklistStructure(description);

console.log(`Valid: ${validation.valid}`);
console.log('Warnings:');
validation.warnings.forEach(w => console.log(`  - ${w}`));
console.log('Suggestions:');
validation.suggestions.forEach(s => console.log(`  ${s}`));

// Output:
// Valid: false
// Warnings:
//   - Using header-based format (marker comments preferred)
//   - No progress line found
//   - 1 duplicate item(s) found
// Suggestions:
//   Consider adding marker comments for more reliable parsing:
//     <!-- ccpm-checklist-start -->
//     ... existing checklist items ...
//     <!-- ccpm-checklist-end -->
//   Add a progress line after the checklist:
//     Progress: 0% (0/N completed)
//     Last updated: YYYY-MM-DD HH:MM UTC
//   Review checklist for duplicate tasks
```

---

## Integration Patterns

### Pattern 1: Simple Checklist Update

Used by: `/ccpm:sync`, `/ccpm:verify`, `/ccpm:done`

```javascript
// 1. Fetch issue
const issue = await getIssue(issueId);

// 2. Parse checklist
const checklist = parseChecklist(issue.description);
if (!checklist) {
  console.log('No checklist to update');
  return;
}

// 3. Determine which items to update (e.g., from user selection)
const indicesToComplete = [0, 2, 5];

// 4. Update checklist
const result = updateChecklistItems(
  issue.description,
  indicesToComplete,
  true // mark complete
);

// 5. Update Linear
await updateIssueDescription(issueId, result.updatedDescription);

// 6. Log progress
console.log(`✅ Updated ${result.changedCount} items`);
console.log(`Progress: ${result.progress.percentage}%`);
```

### Pattern 2: Validation Before Update

Used by: `/ccpm:utils:update-checklist`, `/ccpm:planning:update`

```javascript
// 1. Validate checklist structure
const validation = validateChecklistStructure(description);

if (!validation.valid) {
  console.log('⚠️  Checklist has issues:');
  validation.warnings.forEach(w => console.log(`  - ${w}`));
  console.log('\nSuggestions:');
  validation.suggestions.forEach(s => console.log(`  ${s}`));

  // Ask user if they want to continue
  const proceed = await askUserQuestion('Continue anyway?');
  if (!proceed) return;
}

// 2. Proceed with update...
```

### Pattern 3: AI-Powered Suggestion

Used by: `/ccpm:sync` (smart checklist analysis)

```javascript
// 1. Parse checklist
const checklist = parseChecklist(issue.description);
if (!checklist) return;

// 2. Analyze git changes and score items
const uncheckedItems = checklist.items.filter(item => !item.checked);
const scoredItems = scoreChecklistItems(uncheckedItems, gitChanges);

// 3. Present suggestions to user
const highConfidence = scoredItems.filter(item => item.score >= 50);
console.log('🤖 AI Suggestions (high confidence):');
highConfidence.forEach(item => {
  console.log(`  [${item.index}] ${item.content}`);
});

// 4. Get user confirmation via interactive selection
const selectedIndices = await askUserQuestion(/* ... */);

// 5. Update selected items
const result = updateChecklistItems(
  issue.description,
  selectedIndices,
  true
);
```

---

## Error Handling

All functions throw descriptive errors for invalid inputs:

```javascript
try {
  const result = updateChecklistItems(description, [0, 1], true);
  console.log('Update successful');
} catch (error) {
  if (error.message.includes('No checklist found')) {
    console.error('❌ No checklist to update');
    // Suggest adding a checklist
  } else if (error.message.includes('Invalid indices')) {
    console.error('❌ Invalid item indices:', error.message);
    // Show valid range
  } else {
    console.error('❌ Update failed:', error.message);
    throw error;
  }
}
```

---

## Best Practices

1. **Always validate inputs** - Use `parseChecklist()` before updates
2. **Handle null gracefully** - Check if checklist exists before operations
3. **Preserve user data** - Never modify items outside checklist section
4. **Update atomically** - Use `updateChecklistItems()` for batch updates
5. **Track changes** - Log `changedItems` and `changedCount` for audit trail
6. **Prefer marker comments** - Encourage migration to marker-based format
7. **Validate structure** - Use `validateChecklistStructure()` for quality checks
8. **Add timestamps** - Include update timestamps for transparency

---

## Testing Helpers

Test these functions in isolation:

```javascript
// Test parsing
const testDescription = `
## ✅ Implementation Checklist

<!-- ccpm-checklist-start -->
- [ ] Task 1
- [x] Task 2
- [ ] Task 3
<!-- ccpm-checklist-end -->

Progress: 33% (1/3 completed)
`;

const checklist = parseChecklist(testDescription);
console.log('Parsed items:', checklist.items.length);

// Test update
const result = updateChecklistItems(testDescription, [0, 2], true);
console.log('Updated description:', result.updatedDescription);
console.log('Progress:', result.progress);

// Test validation
const validation = validateChecklistStructure(testDescription);
console.log('Valid:', validation.valid);
console.log('Warnings:', validation.warnings);
```

---

## Maintenance

### When to Update This File

1. **New checklist format** - Add support for new parsing patterns
2. **Progress calculation changes** - Modify `calculateProgress()` logic
3. **Timestamp format changes** - Update `formatProgressLine()` format
4. **Validation rules** - Add new checks to `validateChecklistStructure()`

### Finding Usages

To find all commands using these helpers:

```bash
grep -r "parseChecklist\|updateChecklistItems\|calculateProgress" commands/ | grep -v "_shared-checklist"
```

### Version History

- **v1.0.0** - Initial implementation (Phase 1 of PSN-37)
  - Core parsing functions
  - Update logic with progress calculation
  - Validation utilities
  - Support for both marker and header formats

---

## Related Files

- `commands/_shared-linear-helpers.md` - Linear API delegation utilities
- `commands/utils:update-checklist.md` - Interactive checklist update command
- `commands/sync.md` - Natural sync command with AI checklist analysis
- `agents/linear-operations.md` - Linear operations subagent

---

**This file is part of CCPM's unified checklist management system (PSN-37).**
