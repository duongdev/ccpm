---
description: AI-assisted spec document writing
allowed-tools: [LinearMCP, Read, Glob, Grep, Context7MCP, AskUserQuestion]
argument-hint: <doc-id> <section>
---

# Write Spec Section: $1 → $2

## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to Jira, Confluence, BitBucket, or Slack without explicit user confirmation, even in bypass permission mode.

---

## Arguments

- **$1** - Document ID (e.g., `DOC-456` or document title/slug)
- **$2** - Section to write: `requirements`, `architecture`, `api-design`, `data-model`, `testing`, `security`, `user-flow`, `timeline`, `all`

## Workflow

### Step 1: Fetch Document

Use **Linear MCP** `get_document` with ID `$1`:

- Get current document content
- Parse document structure
- Identify document type (Epic Spec vs Feature Design)
- Extract existing sections

### Step 2: Analyze Context

**For ALL sections**, gather context:

1. **Read related Linear issue/initiative** (extract from doc or ask)
2. **Search codebase** for similar features:
   - Use **Glob** to find related files
   - Use **Grep** to search for patterns
   - Read existing implementations

3. **Check for documentation** in project:
   - Look in `.claude/docs/`
   - Look in `.claude/plans/`
   - Look in `.claude/enhancements/`
   - Look in project README, docs folders

4. **Fetch library docs** if technical section:
   - Use **Context7 MCP** for frameworks/libraries
   - Get latest API documentation

### Step 3: Write Section Content

Based on `$2` parameter:

#### `requirements` Section

**For Features:**
```markdown
## 📋 Requirements

### Functional Requirements

[AI analyzes feature title and existing context to generate:]

- **FR1**: [Specific, testable requirement]
  - Input: [What user provides]
  - Output: [What system produces]
  - Business Rule: [Logic/validation]

- **FR2**: [Next requirement]
  - ...

### Non-Functional Requirements

- **NFR1: Performance**: [Specific metric, e.g., "API response < 200ms for 95th percentile"]
- **NFR2: Scalability**: [Capacity requirement, e.g., "Handle 1000 concurrent users"]
- **NFR3: Availability**: [Uptime requirement, e.g., "99.9% uptime"]
- **NFR4: Security**: [Security requirement, e.g., "All data encrypted at rest"]

### Acceptance Criteria

**Must Have:**
- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]

**Nice to Have:**
- [ ] [Optional criterion 1]

### User Acceptance Testing

**Test Scenarios:**
1. **Scenario**: [Description]
   - **Given**: [Initial state]
   - **When**: [Action]
   - **Then**: [Expected outcome]
```

**AI Instructions:**
- Analyze feature title and description
- Search codebase for similar features
- Generate specific, testable requirements
- Include edge cases and error handling
- Make acceptance criteria SMART (Specific, Measurable, Achievable, Relevant, Time-bound)

#### `architecture` Section

```markdown
## 🏗️ Architecture

### System Overview

[AI generates based on feature scope:]

```
┌─────────────────┐
│   Mobile App    │
│  (React Native) │
└────────┬────────┘
         │ HTTPS
         ▼
┌─────────────────┐
│   API Gateway   │
│  (Next.js API)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Database     │
│   (Postgres)    │
└─────────────────┘
```

### Component Breakdown

**Frontend Components:**
- **Component1**: [Purpose, props, state]
- **Component2**: [Purpose, props, state]

**Backend Services:**
- **Service1**: [Responsibility, endpoints]
- **Service2**: [Responsibility, endpoints]

**Data Layer:**
- **Model1**: [Fields, relationships]

### Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Frontend | [e.g., React Native] | [Why this choice] |
| Backend | [e.g., Next.js API Routes] | [Why this choice] |
| Database | [e.g., Postgres] | [Why this choice] |
| State Management | [e.g., TanStack Query] | [Why this choice] |

### Design Patterns

- **Pattern 1**: [e.g., Repository Pattern for data access]
- **Pattern 2**: [e.g., Factory Pattern for object creation]
```

**AI Instructions:**
- Detect tech stack from codebase (read package.json, check imports)
- Use **Context7 MCP** to get latest docs for detected libraries
- Generate architecture diagram in ASCII
- Recommend patterns based on feature complexity
- Ensure consistency with existing codebase architecture

#### `api-design` Section

```markdown
## 🔌 API Design

### Endpoints

#### [Method] [Path]

**Description**: [What this endpoint does]

**Request:**
```typescript
// Headers
Authorization: Bearer <token>
Content-Type: application/json

// Body (if POST/PUT/PATCH)
{
  field1: type,  // Description
  field2: type   // Description
}
```

**Response:**
```typescript
// Success (200)
{
  data: {
    id: string,
    field1: type,
    field2: type
  }
}

// Error (400/500)
{
  error: {
    code: string,
    message: string
  }
}
```

**Validation:**
- `field1`: Required, must be [constraint]
- `field2`: Optional, defaults to [value]

**Business Logic:**
1. Validate input
2. Check permissions
3. Process request
4. Return response

**Error Codes:**
- `INVALID_INPUT`: Input validation failed
- `UNAUTHORIZED`: User not authenticated
- `FORBIDDEN`: User lacks permission

---

### API Contract

**Base URL**: `[e.g., /api/v1]`

**Authentication**: Bearer token (Clerk JWT)

**Rate Limiting**: [e.g., 100 requests/minute per user]

**Pagination**:
```typescript
{
  data: T[],
  pagination: {
    page: number,
    limit: number,
    total: number,
    hasMore: boolean
  }
}
```
```

**AI Instructions:**
- Analyze feature requirements
- Generate RESTful endpoints following project conventions
- Search codebase for existing API patterns (use Grep)
- Include proper TypeScript types
- Add validation rules
- Document error handling

#### `data-model` Section

```markdown
## 🗄️ Data Model

### Database Schema

#### Table: [table_name]

```sql
CREATE TABLE [table_name] (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  field1 VARCHAR(255) NOT NULL,
  field2 INTEGER,
  field3 TIMESTAMP,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  FOREIGN KEY (field2) REFERENCES other_table(id)
);

CREATE INDEX idx_[table_name]_field1 ON [table_name](field1);
```

**Fields:**
- `id`: Primary key (UUID)
- `field1`: [Description, constraints, purpose]
- `field2`: [Description, constraints, purpose]

**Indexes:**
- `idx_[table_name]_field1`: For fast lookup by field1

**Relationships:**
- Belongs to: `other_table` (many-to-one)
- Has many: `child_table` (one-to-many)

### TypeScript Types

```typescript
// Database model
interface [ModelName] {
  id: string
  field1: string
  field2: number | null
  field3: Date | null
  createdAt: Date
  updatedAt: Date
}

// API DTO (Data Transfer Object)
interface [ModelName]DTO {
  id: string
  field1: string
  field2?: number
  // Omit internal fields like createdAt if not needed in API
}

// Create input
interface Create[ModelName]Input {
  field1: string
  field2?: number
}

// Update input
interface Update[ModelName]Input {
  field1?: string
  field2?: number
}
```

### Migrations

**Migration File**: `YYYYMMDD-HHmmss-add-[table_name].sql`

```sql
-- Up
CREATE TABLE [table_name] (...);

-- Down
DROP TABLE [table_name];
```
```

**AI Instructions:**
- Search codebase for existing schema files (Drizzle, Prisma, raw SQL)
- Follow existing naming conventions
- Generate indexes for foreign keys and frequently queried fields
- Include soft delete if project uses it
- Add TypeScript types matching database schema

#### `testing` Section

```markdown
## 🧪 Testing Strategy

### Unit Tests

**Backend API Tests:**

```typescript
describe('[Feature Name] API', () => {
  describe('POST /api/endpoint', () => {
    it('should create [entity] successfully', async () => {
      // Arrange
      const input = { ... }

      // Act
      const response = await request(app)
        .post('/api/endpoint')
        .send(input)

      // Assert
      expect(response.status).toBe(201)
      expect(response.body.data.field1).toBe(input.field1)
    })

    it('should return 400 for invalid input', async () => {
      // Test validation
    })

    it('should return 401 for unauthenticated request', async () => {
      // Test auth
    })
  })
})
```

**Frontend Component Tests:**

```typescript
describe('[ComponentName]', () => {
  it('should render correctly', () => {
    render(<ComponentName />)
    expect(screen.getByText('Expected Text')).toBeInTheDocument()
  })

  it('should handle user interaction', async () => {
    const mockFn = jest.fn()
    render(<ComponentName onAction={mockFn} />)

    fireEvent.press(screen.getByTestId('action-button'))
    await waitFor(() => expect(mockFn).toHaveBeenCalled())
  })
})
```

### Integration Tests

**Test Scenarios:**

1. **End-to-End Flow**:
   - User performs action A
   - System processes B
   - User sees result C

2. **Error Handling**:
   - Network failure during request
   - Invalid server response
   - User sees error message

### Manual Testing Checklist

- [ ] Happy path works
- [ ] Error states handled
- [ ] Loading states shown
- [ ] Accessibility (screen reader)
- [ ] Performance (no lag)

### Test Data

**Fixtures:**
```typescript
const mockData = {
  valid: { ... },
  invalid: { ... }
}
```
```

**AI Instructions:**
- Generate tests for all requirements and acceptance criteria
- Use project's testing framework (detect from package.json)
- Follow existing test patterns (search with Grep)
- Include edge cases

#### `security` Section

```markdown
## 🔒 Security Considerations

### Authentication & Authorization

**Authentication:**
- [e.g., Clerk JWT tokens]
- Token expiration: [e.g., 1 hour]
- Refresh token flow: [e.g., sliding window]

**Authorization:**
- **Role-Based Access Control (RBAC)**:
  - Admin: Full access
  - User: Limited access

**Permission Checks:**
```typescript
if (!user.hasPermission('feature.action')) {
  throw new ForbiddenError('Insufficient permissions')
}
```

### Input Validation

**Server-Side Validation:**
- All user inputs validated with [e.g., Zod]
- SQL injection prevention: Parameterized queries
- XSS prevention: HTML escaping on output

**Example:**
```typescript
const schema = z.object({
  field1: z.string().min(1).max(255),
  field2: z.number().positive()
})

const validated = schema.parse(input) // Throws if invalid
```

### Data Protection

**Encryption:**
- At rest: [e.g., Database-level encryption]
- In transit: HTTPS only

**Sensitive Data:**
- Passwords: Hashed with bcrypt (12 rounds)
- API keys: Stored in environment variables
- PII: [e.g., Encrypted at field level]

### Rate Limiting

**API Rate Limits:**
- 100 requests/minute per user
- 1000 requests/hour per IP

**Implementation:**
```typescript
const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100
})
```

### Security Headers

```typescript
// Content Security Policy
'Content-Security-Policy': "default-src 'self'"

// Prevent clickjacking
'X-Frame-Options': 'DENY'

// XSS Protection
'X-Content-Type-Options': 'nosniff'
```

### Audit Logging

**Log Security Events:**
- Failed login attempts
- Permission changes
- Data access (for sensitive data)

**Log Format:**
```typescript
{
  timestamp: '2025-01-01T00:00:00Z',
  event: 'AUTH_FAILED',
  userId: 'user_123',
  ip: '1.2.3.4',
  metadata: { reason: 'invalid_password' }
}
```
```

**AI Instructions:**
- Detect auth system from codebase (Clerk, NextAuth, etc.)
- Use **Context7 MCP** for security best practices
- Check for existing security middleware
- Reference OWASP Top 10

#### `user-flow` Section

```markdown
## 🎨 User Experience & Flows

### Primary User Flow

```
1. User lands on [screen]
   ↓
2. User taps [action button]
   ↓
3. System shows [loading state]
   ↓
4. System validates [input]
   ↓
5. System processes [action]
   ↓
6. User sees [success state]
```

### Wireframes / UI Mockups

**Screen 1: [Screen Name]**

```
┌─────────────────────────┐
│  ◀  [Screen Title]    ⋮ │
├─────────────────────────┤
│                         │
│  [Main Content Area]    │
│                         │
│  [Interactive Element]  │
│                         │
│  [Action Button]        │
│                         │
└─────────────────────────┘
```

### Edge Cases & Error States

**Error Case 1: Network Failure**
- Show: "Unable to connect. Please try again."
- Action: Retry button

**Error Case 2: Invalid Input**
- Show: Inline validation error
- Action: Highlight field, show help text

### Loading States

- Initial load: Skeleton screen
- Pull-to-refresh: Pull indicator
- Button action: Button shows spinner

### Accessibility

- Screen reader labels for all interactive elements
- Minimum touch target size: 44x44 points
- Color contrast ratio: 4.5:1 minimum
```

**AI Instructions:**
- Create step-by-step flows for all user journeys
- Draw ASCII wireframes for key screens
- Include error handling UX
- Reference accessibility guidelines (WCAG)

#### `timeline` Section

```markdown
## 📅 Timeline & Estimation

### Task Breakdown with Estimates

| Task | Description | Est. Time | Dependencies |
|------|-------------|-----------|--------------|
| 1. Database Schema | Create tables and migrations | 2h | None |
| 2. API Endpoints | Implement backend logic | 4h | Task 1 |
| 3. Frontend UI | Build components | 6h | Task 2 |
| 4. Integration | Connect frontend to backend | 2h | Task 3 |
| 5. Testing | Write and run tests | 4h | Task 4 |
| 6. Review & Polish | Code review, bug fixes | 2h | Task 5 |

**Total Estimate**: 20 hours (~2-3 days)

### Milestones

| Milestone | Date | Deliverable |
|-----------|------|-------------|
| Spec Complete | [+1 day] | This document approved |
| Development Start | [+2 days] | Tasks 1-2 complete |
| Alpha Ready | [+4 days] | Tasks 1-4 complete |
| Testing Complete | [+6 days] | All tasks done |
| Production Release | [+7 days] | Feature live |

### Risk Buffer

- Add 20% buffer for unforeseen issues: **+4 hours**
- **Total with buffer**: 24 hours (~3 days)

### Critical Path

```
Database → API → Frontend → Integration → Testing
```

Tasks 1-2-3-4 are sequential (critical path).
Task 5 (Testing) can partially overlap with Task 4.
```

**AI Instructions:**
- Break down requirements into tasks
- Estimate based on similar features (search codebase)
- Identify dependencies
- Add realistic buffer
- Create Gantt-style timeline

#### `all` Section

**If user requests `all`:**

1. Show progress indicator
2. Write each section sequentially:
   - requirements → architecture → api-design → data-model → testing → security → user-flow → timeline
3. After each section, update document
4. Show final summary

### Step 4: Update Linear Document

Use **Linear MCP** `update_document`:

- Append or replace section in document
- Update "Last Updated" timestamp
- Preserve existing content in other sections

### Step 5: Display Result

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Spec Section Written: $2
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 Document: [DOC-456](https://linear.app/workspace/document/DOC-456)
✏️  Section: [$2]
📝 Content: [X] lines added

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Suggested Next Actions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 6: Interactive Next Actions

Use **AskUserQuestion**:

```javascript
{
  questions: [{
    question: "Section written! What would you like to do next?",
    header: "Next Step",
    multiSelect: false,
    options: [
      {
        label: "Write Another Section",
        description: "Continue writing other sections"
      },
      {
        label: "Review Spec",
        description: "Run AI review for completeness (/ccpm:spec:review)"
      },
      {
        label: "View in Linear",
        description: "Open document in Linear"
      },
      {
        label: "Done",
        description: "Finish for now"
      }
    ]
  }]
}
```

## Notes

- AI generates content based on codebase analysis
- Uses **Context7 MCP** for library documentation
- Searches existing files for patterns and conventions
- All generated content follows project style
- User can edit in Linear after generation
