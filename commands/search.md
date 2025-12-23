---
description: Search Linear issues by query, status, label, or assignee
allowed-tools: [Bash, Task, AskUserQuestion]
argument-hint: "[query] [--status=X] [--label=X] [--assignee=X]"
---

# /ccpm:search - Search Linear Issues

Search and filter Linear issues with flexible query options.

## Usage

```bash
# Search by text query
/ccpm:search authentication

# Search by status
/ccpm:search --status="In Progress"

# Search by label
/ccpm:search --label=frontend

# Search by assignee
/ccpm:search --assignee=me

# Combine filters
/ccpm:search auth --status="In Progress" --label=backend

# Recent issues (default: last 7 days)
/ccpm:search --recent

# My issues
/ccpm:search --mine
```

## Implementation

### Step 1: Parse Arguments

```javascript
const args = parseArgs(rawArgs);

let query = '';
let filters = {
  status: null,
  label: null,
  assignee: null,
  recent: false,
  mine: false
};

// Parse positional and flag arguments
for (const arg of args) {
  if (arg.startsWith('--status=')) {
    filters.status = arg.replace('--status=', '').replace(/"/g, '');
  } else if (arg.startsWith('--label=')) {
    filters.label = arg.replace('--label=', '');
  } else if (arg.startsWith('--assignee=')) {
    filters.assignee = arg.replace('--assignee=', '');
  } else if (arg === '--recent') {
    filters.recent = true;
  } else if (arg === '--mine') {
    filters.mine = true;
  } else if (!arg.startsWith('--')) {
    query = query ? `${query} ${arg}` : arg;
  }
}

// Default to recent if no filters
if (!query && !filters.status && !filters.label && !filters.assignee && !filters.mine) {
  filters.recent = true;
}
```

### Step 2: Build Search Query

```javascript
// Build filter string for Linear API
let filterParts = [];

if (query) {
  filterParts.push(`title: { contains: "${query}" }`);
}

if (filters.status) {
  filterParts.push(`state: { name: { eq: "${filters.status}" } }`);
}

if (filters.label) {
  filterParts.push(`labels: { name: { eq: "${filters.label}" } }`);
}

if (filters.assignee === 'me' || filters.mine) {
  filterParts.push('assignee: { isMe: { eq: true } }');
} else if (filters.assignee) {
  filterParts.push(`assignee: { name: { contains: "${filters.assignee}" } }`);
}

if (filters.recent) {
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
  filterParts.push(`updatedAt: { gte: "${sevenDaysAgo}" }`);
}

const filterString = filterParts.length > 0 ? filterParts.join(', ') : null;
```

### Step 3: Search via Linear Subagent

```javascript
const result = await Task({
  subagent_type: 'ccpm:linear-operations',
  prompt: `operation: search_issues
params:
  query: "${query}"
  filters: ${JSON.stringify(filters)}
  limit: 20
context:
  cache: true
  command: search`
});

if (result.error) {
  console.log(`❌ Search failed: ${result.error.message}`);
  return;
}

const issues = result.issues || [];
```

### Step 4: Display Results

```javascript
console.log('═══════════════════════════════════════');
console.log('🔍 Search Results');
console.log('═══════════════════════════════════════\n');

// Show active filters
const activeFilters = [];
if (query) activeFilters.push(`Query: "${query}"`);
if (filters.status) activeFilters.push(`Status: ${filters.status}`);
if (filters.label) activeFilters.push(`Label: ${filters.label}`);
if (filters.mine) activeFilters.push('Assignee: Me');
else if (filters.assignee) activeFilters.push(`Assignee: ${filters.assignee}`);
if (filters.recent) activeFilters.push('Recent (7 days)');

if (activeFilters.length > 0) {
  console.log(`📋 Filters: ${activeFilters.join(' | ')}`);
  console.log('');
}

if (issues.length === 0) {
  console.log('No issues found matching your criteria.\n');
  console.log('💡 Try:');
  console.log('   - Broader search terms');
  console.log('   - Different status filter');
  console.log('   - /ccpm:search --recent for recent activity');
  return;
}

console.log(`Found ${issues.length} issue(s):\n`);

// Group by status
const byStatus = {};
issues.forEach(issue => {
  const status = issue.state?.name || 'Unknown';
  if (!byStatus[status]) byStatus[status] = [];
  byStatus[status].push(issue);
});

// Display grouped
for (const [status, statusIssues] of Object.entries(byStatus)) {
  const statusIcon = getStatusIcon(status);
  console.log(`${statusIcon} ${status} (${statusIssues.length})`);

  statusIssues.forEach(issue => {
    const labels = issue.labels?.map(l => l.name).join(', ') || '';
    const assignee = issue.assignee?.name || 'Unassigned';
    const priority = getPriorityIcon(issue.priority);

    console.log(`   ${priority} ${issue.identifier} - ${issue.title}`);
    if (labels) console.log(`      🏷️  ${labels}`);
    console.log(`      👤 ${assignee}`);
  });
  console.log('');
}

// Quick actions
console.log('───────────────────────────────────────');
console.log('💡 Actions');
console.log('   /ccpm:work <issue-id>   - Start working on issue');
console.log('   /ccpm:status <issue-id> - View issue details');
```

### Helper Functions

```javascript
function getStatusIcon(status) {
  const icons = {
    'Backlog': '📋',
    'Todo': '📝',
    'In Progress': '🔄',
    'In Review': '👁️',
    'Done': '✅',
    'Cancelled': '❌'
  };
  return icons[status] || '⏳';
}

function getPriorityIcon(priority) {
  // Linear priority: 0=none, 1=urgent, 2=high, 3=medium, 4=low
  const icons = ['⬜', '🔴', '🟠', '🟡', '🟢'];
  return icons[priority] || '⬜';
}
```

## Example Output

```
═══════════════════════════════════════
🔍 Search Results
═══════════════════════════════════════

📋 Filters: Query: "auth" | Status: In Progress

Found 3 issue(s):

🔄 In Progress (2)
   🟠 PSN-29 - Add user authentication
      🏷️  backend, security
      👤 John Doe
   🟡 PSN-45 - OAuth integration
      🏷️  backend
      👤 Jane Smith

📝 Todo (1)
   🟢 PSN-52 - Add 2FA support
      🏷️  security, feature
      👤 Unassigned

───────────────────────────────────────
💡 Actions
   /ccpm:work <issue-id>   - Start working on issue
   /ccpm:status <issue-id> - View issue details
```

## Advanced Filters

### Status Options
- `Backlog`, `Todo`, `In Progress`, `In Review`, `Done`, `Cancelled`

### Label Examples
- `--label=frontend`, `--label=backend`, `--label=bug`, `--label=feature`

### Assignee Options
- `--assignee=me` or `--mine` - Your issues
- `--assignee="John Doe"` - Specific person

## Integration

- Uses `ccpm:linear-operations` subagent with caching
- Results cached for 5 minutes
- Quick transition to `/ccpm:work` or `/ccpm:status`
