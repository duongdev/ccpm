# CCPM Skills Auto-Activation Testing Guide

**Purpose**: Validate that all 10 enhanced CCPM skills auto-activate correctly with new descriptions and trigger phrases.

**Test Date**: Post-deployment
**Target Users**: QA Team, Early Adopters, CCPM Plugin Users

---

## Test Structure

### Three Testing Levels

1. **Unit Tests** (per skill) - Isolated trigger testing
2. **Integration Tests** (skill pairs) - Multi-skill workflows
3. **End-to-End Tests** (full workflows) - Complete user journeys

---

## 1. Unit Tests (Individual Skills)

### 1.1 ccpm-code-review

**Objective**: Verify activation on completion-related phrases

#### Test Cases

```gherkin
Scenario: Activate on "done"
Given user completes implementation
When user says "I'm done with AUTH-123"
Then ccpm-code-review skill activates
And displays verification gates checklist
And shows four-step validation process

Scenario: Activate on "ready to merge"
When user says "This is ready to merge"
Then ccpm-code-review skill activates
And prompts for verification evidence

Scenario: Activate on /ccpm:verification:verify command
When user runs /ccpm:verification:verify AUTH-123
Then ccpm-code-review skill activates
And runs automated verification gates

Scenario: Do NOT activate on general code discussion
When user says "Let me look at this code"
Then ccpm-code-review skill does NOT activate
(Different context - review discussion, not completion)

Scenario: Activate on "ready to merge" variants
When user says any of:
  - "done"
  - "finished"
  - "complete"
  - "ready to ship"
Then ccpm-code-review skill activates
```

#### Test Execution

```bash
# Run interactively or via test harness
Test 1: "I'm done with AUTH-123, ready to ship!"
  Expected: ✅ Skill activates
  Actual:   [Record result]

Test 2: "/ccpm:verification:verify AUTH-123"
  Expected: ✅ Skill activates
  Actual:   [Record result]

Test 3: "Let me review the code quality"
  Expected: ❌ Skill does NOT activate
  Actual:   [Record result]

Test 4: "The feature is complete and tested"
  Expected: ✅ Skill activates
  Actual:   [Record result]

Test 5: "This PR is ready for merge"
  Expected: ✅ Skill activates
  Actual:   [Record result]
```

---

### 1.2 ccpm-debugging

**Objective**: Verify activation on error/issue keywords and commands

#### Test Cases

```gherkin
Scenario: Activate on "error"
When user says "I got an error in the login flow"
Then ccpm-debugging skill activates
And displays defense-in-depth debugging approach

Scenario: Activate on "failing tests"
When user says "The tests are failing in CI"
Then ccpm-debugging skill activates
And shows Observe-Hypothesize-Test workflow

Scenario: Activate on "broken"
When user says "The deployment is broken"
Then ccpm-debugging skill activates

Scenario: Activate on /ccpm:verification:fix
When user runs /ccpm:verification:fix AUTH-789
Then ccpm-debugging skill activates
And suggests systematic debugging workflow

Scenario: Activate on all error keywords
When user mentions any of: error, failing, broken, debug, bug, issue
Then ccpm-debugging skill activates

Scenario: Do NOT activate on general troubleshooting questions
When user says "How would I troubleshoot this?"
Then ccpm-debugging does NOT auto-activate
(Unless combined with problem statement)
```

#### Test Execution

```bash
Test 1: "Tests are failing"
  Expected: ✅ Activates
  Actual:   [Record]

Test 2: "There's a bug in user auth"
  Expected: ✅ Activates
  Actual:   [Record]

Test 3: "/ccpm:verification:fix WORK-123"
  Expected: ✅ Activates
  Actual:   [Record]

Test 4: "The server crashed"
  Expected: ✅ Activates (issue)
  Actual:   [Record]

Test 5: "How do I debug this?"
  Expected: ⚠️  Might activate (check behavior)
  Actual:   [Record]
```

---

### 1.3 ccpm-mcp-management

**Objective**: Verify activation on MCP-related questions

#### Test Cases

```gherkin
Scenario: Activate on "MCP server"
When user asks "Is the MCP server running?"
Then ccpm-mcp-management skill activates

Scenario: Activate on "tools available"
When user asks "What MCP tools are available?"
Then ccpm-mcp-management skill activates
And lists all configured servers

Scenario: Activate on "Linear not working"
When user says "Linear tools are not responding"
Then ccpm-mcp-management skill activates
And provides diagnostic workflow

Scenario: Activate on /ccpm:utils:help
When user runs /ccpm:utils:help
Then ccpm-mcp-management skill activates
And shows MCP server status

Scenario: Show three-tier classification
When skill activates
Then it displays:
  - Required servers (Linear, GitHub, Context7)
  - Optional servers (Jira, Confluence, Slack, BitBucket)
  - Connection status for each
```

#### Test Execution

```bash
Test 1: "What MCP servers do I have?"
  Expected: ✅ Activates
  Actual:   [Record]

Test 2: "Linear MCP is not working"
  Expected: ✅ Activates + diagnoses
  Actual:   [Record]

Test 3: "/ccpm:utils:help"
  Expected: ✅ Activates + shows server status
  Actual:   [Record]

Test 4: "Show available tools"
  Expected: ✅ Activates
  Actual:   [Record]
```

---

### 1.4 ccpm-skill-creator

**Objective**: Verify activation on skill creation requests

#### Test Cases

```gherkin
Scenario: Activate on "create skill"
When user says "I want to create a custom skill"
Then ccpm-skill-creator skill activates

Scenario: Activate on "team specific"
When user says "We need a team-specific workflow"
Then ccpm-skill-creator skill activates

Scenario: Activate on "codify team practice"
When user says "Let's codify our deployment process"
Then ccpm-skill-creator skill activates

Scenario: Provide three templates
When skill activates
Then it shows:
  - Team Workflow template (for practices)
  - Safety Enforcement template (for checks)
  - Integration Skills template (for custom tools)
```

#### Test Execution

```bash
Test 1: "Create skill for our QA process"
  Expected: ✅ Activates + guides through creation
  Actual:   [Record]

Test 2: "Extend CCPM with custom tool"
  Expected: ✅ Activates
  Actual:   [Record]

Test 3: "Reusable deployment pattern"
  Expected: ✅ Activates
  Actual:   [Record]
```

---

### 1.5 docs-seeker

**Objective**: Verify activation on documentation requests

#### Test Cases

```gherkin
Scenario: Activate on "find documentation"
When user says "Find me React 19 documentation"
Then docs-seeker skill activates
And fetches latest from official sources

Scenario: Activate on "API docs"
When user says "Get the Stripe API docs"
Then docs-seeker skill activates

Scenario: Activate on "best practices"
When user says "What are best practices for authentication?"
Then docs-seeker skill activates

Scenario: Activate when running /ccpm:spec:write
When user runs /ccpm:spec:write DOC-123 architecture
Then docs-seeker activates automatically
And researches relevant documentation

Scenario: Show progressive discovery
When activated
Then it uses process:
  1. Overview (what is this?)
  2. API Reference (how do I use it?)
  3. Integration (how does it work with my stack?)
  4. Best Practices (how should I do this?)
```

#### Test Execution

```bash
Test 1: "Find React Server Components docs"
  Expected: ✅ Activates + fetches latest
  Actual:   [Record]

Test 2: "/ccpm:spec:write DOC-456 api-design"
  Expected: ✅ Activates + researches API design docs
  Actual:   [Record]

Test 3: "How do I implement OAuth?"
  Expected: ✅ Activates
  Actual:   [Record]
```

---

### 1.6 external-system-safety

**Objective**: Verify activation on potential external writes

#### Test Cases

```gherkin
Scenario: Activate when creating Jira issue
When code attempts to create Jira issue
Then external-system-safety skill activates
And displays operation preview
And requires explicit "yes" confirmation

Scenario: Activate when posting to Slack
When code attempts to post Slack message
Then external-system-safety skill activates
And shows exact message to be posted
And blocks until confirmed

Scenario: Do NOT activate on read operations
When code reads Jira issue
Then external-system-safety does NOT activate
(Read operations always allowed)

Scenario: Do NOT activate on Linear writes
When code updates Linear issue
Then external-system-safety does NOT activate
(Linear is internal, always allowed)

Scenario: Require explicit "yes"
When user confirmation is needed
And user responds: "ok", "sure", "maybe"
Then external-system-safety rejects response
And asks again for explicit "yes"
```

#### Test Execution

```bash
Test 1: Attempt to create BitBucket PR
  Expected: ⚠️  Skill blocks + shows preview
  Actual:   [Record]

Test 2: User responds "yes"
  Expected: ✅ Operation proceeds
  Actual:   [Record]

Test 3: User responds "ok"
  Expected: ❌ Rejected + asks for "yes"
  Actual:   [Record]

Test 4: Read Jira issue
  Expected: ✅ No confirmation needed
  Actual:   [Record]
```

---

### 1.7 pm-workflow-guide

**Objective**: Verify phase detection and command suggestions

#### Test Cases

```gherkin
Scenario: Detect planning phase
When user says "I need to plan this feature"
Then pm-workflow-guide activates
And suggests /ccpm:planning:create or /ccpm:planning:quick-plan

Scenario: Detect implementation phase
When user says "I'm ready to start coding"
Then pm-workflow-guide activates
And suggests /ccpm:implementation:start

Scenario: Detect verification phase
When user says "I'm done coding, ready to test"
Then pm-workflow-guide activates
And suggests /ccpm:verification:check

Scenario: Prevent common mistakes
When user attempts to implement without planning
Then pm-workflow-guide suggests planning first
And shows error: "Run planning first"

Scenario: Provide next action
When user asks "What should I work on next?"
Then pm-workflow-guide activates
And suggests /ccpm:implementation:next
```

#### Test Execution

```bash
Test 1: "Let's plan the payment feature"
  Expected: ✅ Activates + suggests planning command
  Actual:   [Record]

Test 2: "I'm ready to implement"
  Expected: ✅ Activates + suggests /ccpm:implementation:start
  Actual:   [Record]

Test 3: "What's the next step?"
  Expected: ✅ Suggests /ccpm:implementation:next
  Actual:   [Record]

Test 4: "Let's code the feature" (without plan)
  Expected: ✅ Suggests planning first
  Actual:   [Record]
```

---

### 1.8 project-detection

**Objective**: Verify automatic project context detection

#### Test Cases

```gherkin
Scenario: Detect from Git remote
Given repository with configured git remote
When user runs any CCPM command
Then project-detection activates
And detects correct project

Scenario: Detect from subdirectory
Given monorepo with subdirectory patterns
When user cd to /path/to/monorepo/apps/frontend
And runs CCPM command
Then project-detection detects:
  - project: my-monorepo
  - subproject: frontend

Scenario: Handle ambiguous detection
Given multiple projects could match
When detection is ambiguous
Then project-detection asks user to clarify
And suggests /ccpm:project:set

Scenario: Display project context
When project detected
Then command header shows:
  📋 Project: My Monorepo › frontend

Scenario: Support manual override
When user runs /ccpm:project:set my-project
Then all subsequent commands use that project
(Regardless of directory)
```

#### Test Execution

```bash
Test 1: Run command in configured project repo
  Expected: ✅ Auto-detects project
  Actual:   [Record]

Test 2: Run command in monorepo subdirectory
  Expected: ✅ Detects correct subproject
  Actual:   [Record]

Test 3: Run command in unconfigured directory
  Expected: ⚠️  Shows error + suggests /ccpm:project:set
  Actual:   [Record]

Test 4: Set project manually
  Expected: ✅ All commands use manual setting
  Actual:   [Record]
```

---

### 1.9 project-operations

**Objective**: Verify project setup and management workflows

#### Test Cases

```gherkin
Scenario: Guide through project setup
When user runs /ccpm:project:add my-app
Then project-operations activates
And guides through:
  1. Purpose definition
  2. Template selection
  3. Configuration
  4. Validation

Scenario: Provide templates
When setting up new project
Then shows options:
  - fullstack-with-jira
  - fullstack-linear-only
  - mobile-app
  - monorepo

Scenario: Configure monorepo
When user wants to configure subdirectories
Then guides through:
  1. Pattern matching setup
  2. Priority weighting
  3. Subproject metadata
  4. Validation

Scenario: Use agents internally
When performing operations
Then uses agents:
  - project-detector (detect)
  - project-config-loader (validate)
  - project-context-manager (manage)
```

#### Test Execution

```bash
Test 1: "/ccpm:project:add new-app"
  Expected: ✅ Guides through setup
  Actual:   [Record]

Test 2: Select fullstack-jira template
  Expected: ✅ Creates configured project
  Actual:   [Record]

Test 3: Configure monorepo with 3 subprojects
  Expected: ✅ Sets up subdirectory detection
  Actual:   [Record]
```

---

### 1.10 sequential-thinking

**Objective**: Verify activation on complex problem-solving

#### Test Cases

```gherkin
Scenario: Activate on "break down epic"
When user says "Help me break down this large epic"
Then sequential-thinking skill activates
And shows 6-step structured approach

Scenario: Activate on architecture decision
When user says "How should I design this system?"
Then sequential-thinking skill activates
And uses branching (explore options A, B, C)

Scenario: Activate on complexity assessment
When user asks "How hard is this task?"
Then sequential-thinking skill activates
And assesses complexity with multiple dimensions

Scenario: Show 6-step process
When activated
Then explains:
  1. Initial Assessment (rough estimate)
  2. Iterative Reasoning (learn progressively)
  3. Dynamic Scope Adjustment (refine)
  4. Revision Mechanism (reconsider)
  5. Branching for Alternatives (explore options)
  6. Conclusion (synthesize)

Scenario: Adjust thought count dynamically
When understanding deepens
Then updates: "Thought 3/8" (was initially 5)
And shows learning progression
```

#### Test Execution

```bash
Test 1: "Break down user dashboard epic"
  Expected: ✅ Activates + structures breakdown
  Actual:   [Record]

Test 2: "Design the payment system architecture"
  Expected: ✅ Activates + explores approaches
  Actual:   [Record]

Test 3: "Assess complexity of auth system"
  Expected: ✅ Activates + analyzes dimensions
  Actual:   [Record]

Test 4: Dynamic scope adjustment observed
  Expected: ✅ Shows "Thought 3/8" progression
  Actual:   [Record]
```

---

## 2. Integration Tests

### 2.1 Verification Workflow

**Objective**: Test ccpm-code-review + ccpm-debugging together

```
Scenario: Complete Verification Flow

Step 1: User says "I'm done"
  ✓ ccpm-code-review activates
  ✓ Shows verification gates

Step 2: Verification fails (tests failing)
  ✓ ccpm-code-review detects failure
  ✓ Suggests /ccpm:verification:fix
  ✓ ccpm-debugging activates
  ✓ Shows debug workflow

Step 3: Debugging completes fixes
  ✓ User re-runs verification
  ✓ All gates pass
  ✓ ccpm-code-review confirms ready

Step 4: Ready to finalize
  ✓ external-system-safety activates
  ✓ Asks for confirmation before PR/Jira/Slack
  ✓ User confirms "yes"
  ✓ Operations proceed
```

#### Test Execution

```bash
Test Case: Complete feature → verify → debug → finalize

1. User: "I'm done with AUTH-123"
   Check: ccpm-code-review activates
   Check: Shows 4-step validation process

2. Tests fail (3 failures)
   Check: ccpm-code-review detects failure
   Check: Suggests /ccpm:verification:fix
   Check: ccpm-debugging activates

3. User: "Fix the issues"
   Check: Debugs using systematic approach
   Check: Applies fixes

4. Tests re-run
   Check: All pass
   Check: Build succeeds
   Check: Checklist complete

5. User: "Ready to ship"
   Check: external-system-safety activates
   Check: Shows what will be posted

6. User: "yes"
   Check: PR created
   Check: Jira updated
   Check: Slack notified
```

---

### 2.2 Planning → Implementation → Verification

**Objective**: Test pm-workflow-guide coordinating with other skills

```
Scenario: Complete Task Workflow

Step 1: Plan phase
  ✓ pm-workflow-guide activates
  ✓ Suggests /ccpm:planning:create
  ✓ docs-seeker activates (researches requirements)

Step 2: Implementation phase
  ✓ pm-workflow-guide suggests /ccpm:implementation:start
  ✓ project-detection activates (detects correct project)
  ✓ Tasks created with correct context

Step 3: Verification phase
  ✓ pm-workflow-guide suggests /ccpm:verification:check
  ✓ Tests run, checks pass
  ✓ ccpm-code-review confirms ready

Step 4: Completion phase
  ✓ pm-workflow-guide suggests /ccpm:complete:finalize
  ✓ external-system-safety activates
  ✓ Confirms broadcast to external systems
```

---

### 2.3 Monorepo Project Detection

**Objective**: Test project-detection + project-operations

```
Scenario: Monorepo with 3 subprojects

Setup:
  /Users/dev/monorepo/apps/web
  /Users/dev/monorepo/apps/mobile
  /Users/dev/monorepo/services/api

Step 1: Configure monorepo
  ✓ project-operations activates
  ✓ User creates configuration with 3 subprojects
  ✓ Sets glob patterns for each

Step 2: Switch to web app directory
  ✓ cd /Users/dev/monorepo/apps/web
  ✓ Run /ccpm:planning:create "Add dark mode"
  ✓ project-detection activates
  ✓ Detects: project=monorepo, subproject=web-app
  ✓ Shows: "📋 Project: Monorepo › web-app"

Step 3: Switch to API directory
  ✓ cd /Users/dev/monorepo/services/api
  ✓ Run /ccpm:planning:create "Add caching"
  ✓ project-detection activates
  ✓ Detects: project=monorepo, subproject=api
  ✓ Shows: "📋 Project: Monorepo › api"

Result: Correct context maintained per directory
```

---

## 3. End-to-End Workflow Tests

### 3.1 Complete Feature Delivery

**Objective**: Full workflow from requirements to ship

```bash
SCENARIO: Build user authentication feature

Timeline:
1. Day 1 - Plan
   Command: /ccpm:planning:create "User authentication" my-project JIRA-456
   Expected:
     ✓ pm-workflow-guide activates
     ✓ docs-seeker researches auth best practices
     ✓ sequential-thinking structures plan
     ✓ Linear issue created with checklist

2. Day 2-3 - Implement
   Command: /ccpm:implementation:start AUTH-123
   Expected:
     ✓ project-detection ensures correct project
     ✓ ccpm-skill-creator could guide on custom needs
     ✓ Code written, tests added

3. Day 4 - Verify
   Command: /ccpm:verification:check AUTH-123
   Expected:
     ✓ Tests run: 52 pass, 0 fail
     ✓ Build succeeds
     ✓ Linting clean

4. Code Review Feedback
   Comment: "Add error handling to login"
   Expected:
     ✓ ccpm-code-review verifies feedback is valid
     ✓ Creates fix PR
     ✓ Tests re-run

5. Final Verification
   Command: /ccpm:verification:verify AUTH-123
   Expected:
     ✓ Code review: passed
     ✓ Security: passed
     ✓ Performance: acceptable

6. Ship
   User: "Ready to deploy!"
   Expected:
     ✓ ccpm-code-review confirms all gates pass
     ✓ external-system-safety blocks for confirmation
     ✓ Shows: "Create PR #234? Update Jira? Post Slack?"
     ✓ User: "yes"
     ✓ Operations complete

Result: Complete workflow executed with all skills activating at right time
```

---

## 4. Test Data & Environments

### Test Projects

```yaml
Projects:
  - my-project
    Repo: github.com/org/my-project
    Type: Single repo
    Status: Configured

  - multi-stack-monorepo
    Repo: github.com/org/monorepo
    Subprojects:
      - web-app (apps/web)
      - mobile-app (apps/mobile)
      - api-server (services/api)
    Status: Configured for testing

  - unconfigured-project
    Location: /Users/test/random-project
    Status: NOT configured (for error testing)
```

### Test Tasks

```yaml
Tasks:
  - AUTH-123: Simple auth feature
  - WORK-456: Complex distributed system
  - BUG-789: Critical production issue
  - SPIKE-101: Research task
```

---

## 5. Test Execution Checklist

### Pre-Test Setup

- [ ] All 10 skills deployed
- [ ] Test projects configured
- [ ] MCP servers running (Linear, GitHub, Context7)
- [ ] Optional servers available (Jira, Confluence, Slack)
- [ ] Test environment clean

### Per-Skill Testing

- [ ] ccpm-code-review: 5 test cases
- [ ] ccpm-debugging: 5 test cases
- [ ] ccpm-mcp-management: 4 test cases
- [ ] ccpm-skill-creator: 3 test cases
- [ ] docs-seeker: 3 test cases
- [ ] external-system-safety: 4 test cases
- [ ] pm-workflow-guide: 4 test cases
- [ ] project-detection: 4 test cases
- [ ] project-operations: 3 test cases
- [ ] sequential-thinking: 3 test cases

### Integration Testing

- [ ] Verification workflow (3 phases)
- [ ] Planning → Implementation → Verification (4 phases)
- [ ] Monorepo subdirectory detection (3 paths)

### End-to-End Testing

- [ ] Complete feature delivery workflow (6 steps)
- [ ] Record all activation points
- [ ] Verify integration between skills

---

## 6. Pass/Fail Criteria

### Success Criteria

✅ **Pass if**:
- All activation triggers fire as documented
- Skills provide expected guidance
- No false positives (skills activate when not needed)
- Integration between skills works smoothly
- Error messages are clear and actionable
- Performance is acceptable (<1s per activation)

❌ **Fail if**:
- Skill doesn't activate on documented trigger
- Wrong skill activates instead
- Integration breaks workflow
- Confusing error messages
- Performance degrades significantly

---

## 7. Test Report Template

```markdown
# CCPM Skills Auto-Activation Test Report

Date: [date]
Tester: [name]
Environment: [dev/staging/production]

## Summary
- Total tests: 40
- Passed: __
- Failed: __
- Blocked: __
- Pass rate: ___%

## By Skill

### ccpm-code-review
- [ ] Test 1: Activate on "done" - PASS/FAIL
- [ ] Test 2: Activate on "ready to merge" - PASS/FAIL
- [ ] Test 3: Activate on /ccpm:verification:verify - PASS/FAIL
- [ ] Test 4: Don't activate on code discussion - PASS/FAIL
- [ ] Test 5: Activate on variants - PASS/FAIL

[... similar for other 9 skills]

## Integration Tests

### Verification Workflow
- [ ] PASS/FAIL - Code review + debugging integration
- Notes: [any observations]

### Planning → Implementation → Verification
- [ ] PASS/FAIL - Full workflow coordination
- Notes: [any observations]

### Monorepo Detection
- [ ] PASS/FAIL - Correct subproject detection
- Notes: [any observations]

## End-to-End Tests

### Complete Feature Delivery
- [ ] PASS/FAIL - Full workflow execution
- Notes: [any observations]

## Issues Found

| ID | Skill | Issue | Severity | Status |
|----|-------|-------|----------|--------|
| 1 | ccpm-code-review | [description] | High/Med/Low | Open/Fixed |

## Recommendations

1. [Recommendation 1]
2. [Recommendation 2]

## Sign-Off

Tester: _________________ Date: _________
```

---

## 8. Automation Considerations

### Automatable Tests

These tests could be automated:
- Activation trigger recognition
- Integration between specific skill pairs
- Performance metrics
- Error handling

### Manual Tests

These require human judgment:
- Guidance quality
- Workflow effectiveness
- User experience
- Learning curve for new users

---

## 9. Known Limitations

1. **AI Model Variations**: Claude may respond differently based on context
2. **Phrase Variations**: Users may phrase things differently than documented triggers
3. **Integration Timing**: Skill activation timing may vary
4. **External Services**: MCP server availability affects testing
5. **User Context**: Individual users may have different project setups

---

## 10. Feedback Loop

After testing:
1. Document any trigger phrases that don't work
2. Collect new user feedback on skill clarity
3. Identify missing auto-activation scenarios
4. Update descriptions based on findings
5. Plan for continuous improvement

---

*See SKILL_ENHANCEMENT_REPORT.md for detailed enhancements*
*See SKILL_ENHANCEMENT_EXAMPLES.md for before/after comparisons*
