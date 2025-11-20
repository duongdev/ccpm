---
name: sequential-thinking
description: Structured problem-solving through iterative reasoning with revision and branching capabilities for complex problems. Use when tackling multi-step problems with uncertain scope, design planning, architecture decisions, or systematic decomposition. Auto-activates when user asks about breaking down epics, designing systems, assessing complexity, or performing root-cause analysis. Uses 6-step process: Initial assessment (rough estimate) → Iterative reasoning (learn progressively) → Dynamic scope adjustment (refine as understanding deepens) → Revision mechanism (update when assumptions change) → Branching for alternatives (explore multiple approaches) → Conclusion (synthesize findings). Supports explicit uncertainty acknowledgment within thoughts. Adjusts total thought count dynamically (e.g., "Thought 3/8" when initially estimated 5). Recommends binary search for intermittent issues and five-whys technique for root causes.
---

# Sequential Thinking

Structured problem-solving through iterative reasoning with revision and branching capabilities.

## When to Use

This skill is ideal for:

- **Complex problem decomposition** - Breaking down multi-faceted challenges
- **Design planning** - Systematic approach to architecture decisions
- **Uncertain scope** - Tasks where the full scope emerges during analysis
- **Root-cause analysis** - Tracing issues through multiple layers
- **Epic breakdown** - Decomposing large features into manageable tasks
- **Spec writing** - Structuring complex technical specifications
- **Complexity assessment** - Evaluating task difficulty and risks

## How It Works

### Core Approach

1. **Start with initial thought** - Express your first understanding of the problem
2. **Iterate through reasoning** - Work through the problem step by step
3. **Adjust scope dynamically** - Update your estimate of total steps as understanding deepens
4. **Revise when needed** - Reconsider previous conclusions if assumptions change
5. **Branch for alternatives** - Explore different approaches when multiple paths exist
6. **Conclude** - Synthesize findings when sufficient analysis is complete

### Key Principles

**Progressive Refinement**: Start with rough estimates, refine as you go

**Explicit Uncertainty**: Acknowledge what you don't know within reasoning steps

**Revision Over Perfection**: Better to revise than get stuck on initial assumptions

**Branch When Valuable**: Explore alternatives when decision has significant impact

## Instructions

### Step-by-Step Process

**1. Initial Assessment**

Begin with your first understanding:
```
Thought 1/5 (rough estimate):
Understanding the problem - [describe what you see]
Key unknowns: [list what's unclear]
Initial approach: [high-level strategy]
```

**2. Iterative Reasoning**

Work through each step systematically:
```
Thought 2/7 (adjusted from 5):
[Current reasoning step]
- Key insight: [what you learned]
- Implication: [what this means]
- Next: [what to analyze next]
```

**3. Dynamic Scope Adjustment**

Update total thought count as understanding deepens:
- Initial: "Thought 1/5" (rough guess)
- Later: "Thought 3/8" (scope expanded)
- Further: "Thought 6/7" (nearly complete)

**4. Revision Mechanism**

When reconsidering previous conclusions:
```
Thought 5/8 (REVISION of Thought 3):
Original assumption: [what you thought before]
New evidence: [what changed]
Revised conclusion: [updated understanding]
Impact: [what else this affects]
```

**5. Branching for Alternatives**

When exploring different approaches:
```
Thought 6/10 (BRANCH A from Thought 4):
Approach A: [first option]
Pros: [advantages]
Cons: [disadvantages]

Thought 7/10 (BRANCH B from Thought 4):
Approach B: [alternative option]
Pros: [advantages]
Cons: [disadvantages]

Comparison: [which is better and why]
```

**6. Conclusion**

When sufficient analysis is complete:
```
Thought 8/8 (FINAL):
Summary: [key findings]
Decision: [recommended approach]
Next actions: [what to do]
Confidence: [how certain are you]
```

## Integration with CCPM

### Planning Phase

**Use with `/ccpm:planning:create`**:

When creating a new task plan, use sequential thinking to:
1. Decompose the feature into logical components
2. Identify dependencies and order
3. Assess complexity for each component
4. Estimate total effort
5. Structure implementation phases

**Example**:
```
User: "/ccpm:planning:create 'Authentication System' my-project JIRA-123"

Claude: [sequential-thinking activates]

Thought 1/6:
Breaking down authentication system into components:
- User registration
- Login/logout
- Password reset
- Session management
- JWT token handling
- OAuth integration (if needed)

Thought 2/6:
Analyzing dependencies:
- Database schema must come first (user table)
- JWT infrastructure needed before login
- Session management depends on JWT
- OAuth can be added later

Thought 3/6:
Assessing complexity:
- User registration: Medium (validation, email)
- Login: Medium (JWT generation)
- Password reset: High (email flow, tokens)
- Session management: Medium
- OAuth: High (third-party integration)

Thought 4/6:
Estimating effort:
- Total: ~40 hours
- Phase 1 (core): Registration + Login (16h)
- Phase 2 (security): Password reset (12h)
- Phase 3 (sessions): Session management (8h)
- Phase 4 (optional): OAuth (12h)

Thought 5/6 (REVISION of Thought 4):
Realized password reset should be in Phase 1 for MVP.
Revised phases:
- Phase 1: Registration + Login + Password reset (24h)
- Phase 2: Session management (8h)
- Phase 3: OAuth (12h, optional)

Thought 6/6 (FINAL):
Recommended task breakdown:
1. Database schema (2h)
2. User registration endpoint (6h)
3. Login endpoint + JWT (6h)
4. Password reset flow (8h)
5. Session management (8h)
6. OAuth integration (12h, optional)

Next: Create Linear tasks with this structure
```

### Spec Writing Phase

**Use with `/ccpm:spec:write architecture`**:

When writing complex spec sections, use sequential thinking to:
1. Outline section structure
2. Analyze technical requirements
3. Explore alternative architectures
4. Document trade-offs
5. Recommend final approach

**Example**:
```
User: "/ccpm:spec:write DOC-456 architecture"

Claude: [sequential-thinking activates]

Thought 1/8:
Architecture requirements for payment gateway:
- Must handle multiple payment providers (Stripe, PayPal)
- Need robust error handling and retries
- Must be secure (PCI compliance)
- Should support webhooks
- Need to track transaction status

Thought 2/8:
Potential architectures:
A. Monolithic - All payment logic in main service
B. Microservice - Dedicated payment service
C. Adapter pattern - Pluggable payment providers

Thought 3/8 (BRANCH A):
Monolithic approach:
Pros: Simple, fewer moving parts, easier to debug
Cons: Hard to scale, tight coupling, harder to add providers
Verdict: Good for MVP, not long-term

Thought 4/8 (BRANCH B):
Microservice approach:
Pros: Independent scaling, isolation, tech flexibility
Cons: Distributed complexity, network overhead, harder local dev
Verdict: Good for scale, overkill for current size

Thought 5/8 (BRANCH C):
Adapter pattern approach:
Pros: Pluggable providers, testable, maintainable
Cons: More upfront design, abstraction overhead
Verdict: Best balance for current + future needs

Thought 6/8:
Adapter pattern details:
- PaymentProvider interface
- StripeAdapter, PayPalAdapter implementations
- PaymentService orchestrates
- Database tracks transactions
- Webhook handler per provider

Thought 7/8:
Security considerations:
- Never log full card numbers
- Use provider SDKs (not raw API)
- Encrypt sensitive data at rest
- TLS for all communication
- Webhook signature verification

Thought 8/8 (FINAL):
Recommended architecture: Adapter pattern
- Interfaces: PaymentProvider, WebhookHandler
- Implementations: Per provider
- Orchestration: PaymentService
- Storage: TransactionRepository
- Security: Encryption + TLS + SDK usage

Next: Document this in architecture section with diagrams
```

### Complexity Analysis

**Use with `/ccpm:utils:insights`**:

When assessing task complexity, use sequential thinking to:
1. Identify all dimensions of complexity
2. Analyze each dimension
3. Assess risks
4. Provide concrete complexity rating

**Example**:
```
User: "/ccpm:utils:insights AUTH-789"

Claude: [sequential-thinking activates]

Thought 1/5:
Analyzing complexity dimensions:
- Technical complexity
- Integration complexity
- Testing complexity
- Deployment complexity
- Domain complexity

Thought 2/5:
Technical complexity: HIGH
- New OAuth2 flow (unfamiliar)
- Token rotation logic (security critical)
- Multi-tenancy support (complex state)

Thought 3/5:
Integration complexity: MEDIUM
- Integrates with existing user service (stable API)
- Needs new Redis for tokens (new infra)
- Affects login UI (coordinated deployment)

Thought 4/5:
Risks identified:
- Security vulnerabilities (HIGH impact, MEDIUM likelihood)
- Token collision in multi-tenant (MEDIUM impact, LOW likelihood)
- Performance degradation (LOW impact, MEDIUM likelihood)

Thought 5/5 (FINAL):
Overall complexity: HIGH
Factors:
- Unfamiliar OAuth2 flow
- Security-critical functionality
- Multi-tenancy state management
- New infrastructure (Redis)

Recommendation:
- Allocate senior developer
- Add security review checkpoint
- Plan thorough testing (unit + integration + security)
- Consider spike/POC first (4h) before full implementation
- Estimate: 32h (vs initial 16h guess)
```

### Debugging/Root-Cause Analysis

**Use with `/ccpm:verification:fix`**:

When debugging complex issues, use sequential thinking to:
1. Gather symptoms
2. Form hypotheses
3. Test each hypothesis
4. Trace root cause
5. Identify fix

**Example**:
```
User: "Tests are failing intermittently in CI"

Claude: [sequential-thinking activates]

Thought 1/7:
Symptoms:
- Tests pass locally (always)
- Tests fail in CI (30% of the time)
- No recent code changes
- Error: "Connection timeout to database"

Thought 2/7:
Hypotheses:
A. Database not ready when tests start
B. Race condition in test setup
C. Resource limits in CI environment
D. Network issues in CI infrastructure

Thought 3/7 (Testing Hypothesis A):
Check: Database startup time
Finding: Docker Compose has no health check
Likelihood: HIGH - explains intermittent failures

Thought 4/7 (Testing Hypothesis B):
Check: Test execution order
Finding: Tests run in parallel, no shared state
Likelihood: LOW - tests are independent

Thought 5/7 (Testing Hypothesis C):
Check: CI resource allocation
Finding: Memory/CPU usage normal
Likelihood: LOW - resources sufficient

Thought 6/7 (REVISION of Thought 3):
Root cause confirmed: Database not ready
- CI starts tests immediately after docker-compose up
- Database takes 2-5 seconds to accept connections
- Tests timeout if database not ready
- Explains 30% failure rate (timing dependent)

Thought 7/7 (FINAL):
Root cause: Missing database readiness check
Fix: Add health check to docker-compose.yml
```yaml
services:
  database:
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres"]
      interval: 1s
      timeout: 5s
      retries: 10
```
Wait for healthy before running tests:
```bash
docker-compose up -d database
docker-compose wait database
npm test
```

Update Linear: Document fix and close blocker
```

## Examples

### Example 1: Epic Breakdown

**Problem**: Break down "User Dashboard" epic

```
Thought 1/6:
Components needed:
- Dashboard layout
- Widget system
- User preferences
- Data visualization
- Real-time updates

Thought 2/6:
Dependencies:
- Layout first (foundation)
- Widget system needs layout
- Preferences can be parallel
- Visualization uses widget system
- Real-time updates overlay on all

Thought 3/6:
Sizing each component:
- Layout: 8h (responsive, nav, sidebar)
- Widget system: 16h (drag-drop, resize, save layout)
- Preferences: 6h (settings page, API, storage)
- Visualization: 12h (charts, graphs, data fetching)
- Real-time: 10h (WebSocket, updates, reconnection)

Thought 4/6 (REVISION of Thought 3):
Widget system too complex for first iteration.
MVP: Static widget positions, customization later.
Revised: Widget system → 6h (static layout)
Future: Drag-drop enhancement → 10h (Phase 2)

Thought 5/6:
Task breakdown:
1. Dashboard layout (8h)
2. Static widget system (6h)
3. User preferences (6h)
4. Data visualization (12h)
5. Real-time updates (10h)
Total: 42h (Phase 1), +10h (Phase 2 for drag-drop)

Thought 6/6 (FINAL):
Create 5 Linear tasks with dependencies:
- Task 1 blocks Task 2
- Task 2 blocks Tasks 4,5
- Task 3 parallel to all
```

### Example 2: Architecture Decision

**Problem**: Choose database for analytics feature

```
Thought 1/7:
Requirements:
- Store user event data (high write volume)
- Support aggregation queries (hourly/daily rollups)
- Fast reads for dashboards
- Retain 90 days of data

Thought 2/7 (BRANCH A):
Option A: PostgreSQL (current database)
Pros: Already in stack, familiar, ACID guarantees
Cons: May struggle with high write volume, expensive aggregations
Analysis: Feasible but may need optimizations

Thought 3/7 (BRANCH B):
Option B: ClickHouse (OLAP database)
Pros: Built for analytics, fast aggregations, compression
Cons: New tech to learn, operational overhead, eventual consistency
Analysis: Best for analytics, but higher complexity

Thought 4/7 (BRANCH C):
Option C: TimescaleDB (PostgreSQL extension)
Pros: Combines PostgreSQL familiarity + time-series optimization
Cons: Still PostgreSQL under the hood, some limitations
Analysis: Good middle ground

Thought 5/7:
Scale analysis:
- Expected: 1M events/day
- PostgreSQL: Can handle with partitioning + indexes
- ClickHouse: Overkill for current scale
- TimescaleDB: Perfect fit

Thought 6/7:
Decision factors:
- Current scale: Small (PostgreSQL handles)
- Team expertise: Strong PostgreSQL
- Operational complexity: Minimize
- Future scale: Can re-evaluate at 10M events/day

Thought 7/7 (FINAL):
Recommendation: Start with PostgreSQL + optimizations
- Partitioning by date
- Materialized views for aggregations
- Indexes on query patterns
- Re-evaluate if hits performance limits
Reasoning: Simplest solution that works, avoid premature optimization
```

## Tips

### Estimating Total Thoughts

**Start rough, refine progressively:**

- Simple problem: 3-5 thoughts
- Medium problem: 5-8 thoughts
- Complex problem: 8-15 thoughts
- Very complex: 15+ thoughts (consider breaking down)

**Adjust as you go:**
- Thought 1/5 → Thought 3/7 (discovered more complexity)
- Thought 5/8 → Thought 5/6 (found shortcut)

### When to Revise

**Trigger revision when:**
- New evidence contradicts assumption
- Discovered missing requirement
- Found simpler approach
- Identified blocker

**Revision format:**
```
Thought X (REVISION of Thought Y):
Original: [what you thought]
New: [what changed]
Impact: [ripple effects]
```

### When to Branch

**Branch when:**
- Multiple viable approaches exist
- Decision has significant impact
- Trade-offs need explicit comparison
- Team needs to choose between options

**Branch format:**
```
Thought X (BRANCH A from Thought Y):
Approach: [option A]
Analysis: [pros/cons]

Thought X+1 (BRANCH B from Thought Y):
Approach: [option B]
Analysis: [pros/cons]

Conclusion: [comparison and recommendation]
```

### When to Stop

**Conclude when:**
- Sufficient analysis completed
- Clear recommendation formed
- Diminishing returns on further thought
- Ready for action

**Conclusion format:**
```
Thought X/X (FINAL):
Summary: [key findings]
Decision: [what to do]
Rationale: [why]
Next: [action items]
```

## Common Patterns

### Pattern 1: Decomposition

```
1. List all components
2. Identify dependencies
3. Size each component
4. Revise based on constraints
5. Create task breakdown
6. Document in Linear
```

### Pattern 2: Decision-Making

```
1. Define criteria
2. List options
3. Branch per option
4. Analyze trade-offs
5. Compare
6. Recommend with rationale
```

### Pattern 3: Root-Cause Analysis

```
1. Gather symptoms
2. Form hypotheses
3. Test each hypothesis
4. Trace to root cause
5. Verify fix
6. Document for future
```

## Conclusion

Sequential thinking is ideal for:
- ✅ Complex multi-step problems
- ✅ Uncertain scope that emerges during analysis
- ✅ Design decisions requiring trade-off analysis
- ✅ Root-cause analysis through multiple layers
- ✅ Epic breakdown into manageable tasks

It integrates seamlessly with CCPM workflows:
- Planning: `/ccpm:planning:create`, `/ccpm:spec:write`
- Analysis: `/ccpm:utils:insights`
- Debugging: `/ccpm:verification:fix`

**Philosophy**: Progressive refinement over premature perfection. Start with rough estimates, iterate, revise when needed, and branch when valuable.

---

**Source**: Adapted from [claudekit-skills/sequential-thinking](https://github.com/mrgoonie/claudekit-skills)
**License**: MIT
**CCPM Integration**: Planning, spec writing, complexity analysis, debugging
