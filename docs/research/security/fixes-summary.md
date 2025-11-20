# CCPM Security Audit - Implementation Guide

**Date**: 2025-11-20
**Related**: [SECURITY_AUDIT_REPORT.md](./SECURITY_AUDIT_REPORT.md)

This document provides actionable steps to implement the security recommendations from the comprehensive security audit.

---

## Quick Summary

**Overall Status**: ✅ **GOOD** - No critical vulnerabilities
**Priority Fixes**: 3 medium-severity issues
**Timeline**: 2-3 weeks for full implementation

---

## Implementation Priority

### Week 1: Critical Path (M1 + M2)

**Goal**: Address medium-severity security issues

1. **Verify Safety Rule Implementation (M1)** - 3 days
2. **Implement Markdown Sanitization (M2)** - 2 days

### Week 2: Security Infrastructure (M3 + L1-L5)

**Goal**: Add security monitoring and fix low-severity issues

3. **Implement Audit Logging (M3)** - 3 days
4. **Fix Low-Severity Issues (L1-L5)** - 2 days

### Week 3-4: Best Practices (R1-R12)

**Goal**: Implement security best practices

5. **Security Automation** - 3 days
6. **Documentation & Training** - 2 days

---

## Detailed Implementation Plans

### M1: Verify Safety Rule Implementation (3 days)

**Issue**: Only 2 of 49 commands verified for confirmation workflow

**Severity**: MEDIUM
**Effort**: 3 days
**Files**: All 49 command files

#### Steps:

**Day 1: Automated Validation**
```bash
# 1. Make validator executable
chmod +x scripts/validate-safety-rules.sh

# 2. Run validator
./scripts/validate-safety-rules.sh

# 3. Review violations
# Output will show commands missing confirmation workflow
```

**Day 2: Fix Violations**

For each command with violations:

1. Add SAFETY_RULES reference:
```markdown
## 🚨 CRITICAL: Safety Rules

**READ FIRST**: `/Users/duongdev/.claude/commands/pm/SAFETY_RULES.md`

**NEVER** submit, post, or update anything to external systems without explicit user confirmation.
```

2. Add confirmation workflow:
```markdown
### Step N: Preview Changes
```
🔄 Proposed [System] Update

[System]: [ID]
Current State: [current]
New State: [proposed]

Content to post:
---
[exact content]
---
```

### Step N+1: Ask Confirmation
Use **AskUserQuestion**:
{questions: [{
  question: "Proceed with this update?",
  header: "Confirm",
  multiSelect: false,
  options: [
    {label: "Yes, Proceed", description: "Execute the operation"},
    {label: "Edit First", description: "Let me modify the content"},
    {label: "Cancel", description: "Don't proceed"}
  ]
}]}

### Step N+2: Execute if Confirmed
- Only proceed if user selected "Yes, Proceed"
- Log the operation (see audit-log.sh)
- Show success confirmation
```

**Day 3: Verification**
```bash
# Re-run validator
./scripts/validate-safety-rules.sh

# Should show 100% compliance
# All commands with external writes have confirmation
```

#### Acceptance Criteria:
- ✅ Validator runs without errors
- ✅ 100% compliance rate
- ✅ All external write operations have AskUserQuestion
- ✅ All commands reference SAFETY_RULES.md

---

### M2: Implement Markdown Sanitization (2 days)

**Issue**: User input in markdown not sanitized, potential XSS

**Severity**: MEDIUM
**Effort**: 2 days
**Files**: Commands generating markdown

#### Steps:

**Day 1: Implement Sanitization**

1. Validation helpers already created:
```bash
# File: scripts/validation-helpers.sh
# Contains:
# - sanitize_markdown()
# - sanitize_markdown_link()
# - create_safe_markdown_link()
# - validate_ticket_id()
# - validate_url()
```

2. Make executable:
```bash
chmod +x scripts/validation-helpers.sh
```

3. Update commands to use sanitization:

**Before** (unsafe):
```bash
TICKET_ID="$2"
echo "**Jira Ticket**: [Jira $TICKET_ID](https://jira.company.com/browse/$TICKET_ID)"
```

**After** (safe):
```bash
# Source validation helpers
source "$SCRIPTS_DIR/validation-helpers.sh"

# Validate input
validate_ticket_id "$2" || exit 1
TICKET_ID="$2"

# Sanitize for link text
SAFE_LINK_TEXT=$(sanitize_markdown_link "Jira $TICKET_ID")

# Create safe link
JIRA_LINK=$(create_safe_markdown_link "$SAFE_LINK_TEXT" "https://jira.company.com/browse/$TICKET_ID")

echo "**Jira Ticket**: $JIRA_LINK"
```

**Day 2: Test & Verify**

1. Create test script:
```bash
#!/bin/bash
# tests/test-sanitization.sh

source scripts/validation-helpers.sh

# Test XSS payloads
PAYLOADS=(
    'PROJ-123](javascript:alert(1))<!--'
    'PROJ-123<script>alert(1)</script>'
    'PROJ-123[bad](evil)'
)

for payload in "${PAYLOADS[@]}"; do
    echo "Testing: $payload"
    result=$(sanitize_markdown_link "$payload")
    echo "Result: $result"

    # Verify no dangerous characters remain
    if [[ "$result" =~ [\[\]\(\)\<\>] ]]; then
        echo "FAILED: Dangerous characters present"
        exit 1
    fi
done

echo "All tests passed!"
```

2. Run tests:
```bash
chmod +x tests/test-sanitization.sh
./tests/test-sanitization.sh
```

#### Acceptance Criteria:
- ✅ All markdown generation uses sanitization
- ✅ Ticket IDs validated with regex
- ✅ URLs validated before use
- ✅ Tests pass with XSS payloads
- ✅ No markdown-breaking characters in output

#### Commands to Update:
- `planning:plan.md` - Line 289, 320-560
- `planning:create.md` - Jira link generation
- `utils:sync-status.md` - Comment generation
- `complete:finalize.md` - PR description
- Any command generating markdown with user input

---

### M3: Implement Audit Logging (3 days)

**Issue**: No security logging for forensics and compliance

**Severity**: MEDIUM
**Effort**: 3 days
**Files**: Commands with external operations

#### Steps:

**Day 1: Setup Infrastructure**

1. Audit logging script already created:
```bash
# File: scripts/audit-log.sh
chmod +x scripts/audit-log.sh
```

2. Test audit logging:
```bash
source scripts/audit-log.sh

# Test logging
audit_log_action "TEST_ACTION" "test-target" "SUCCESS" "Test message"

# Check log
cat ~/.claude/ccpm-logs/audit.log
```

**Day 2: Integrate into Commands**

Add logging to external operations:

**Example: Jira Update**
```bash
# Source audit logging
source "$SCRIPTS_DIR/audit-log.sh"

# Before asking confirmation
audit_log_confirmation "JIRA_UPDATE" "$TICKET_ID" "pending" "User asked for confirmation"

# After user response
if [[ "$USER_RESPONSE" == "Yes, Proceed" ]]; then
    audit_log_confirmation "JIRA_UPDATE" "$TICKET_ID" "true" "User approved update"

    # Perform operation
    # ... jira update ...

    audit_log_external "JIRA" "UPDATE" "$TICKET_ID" "SUCCESS" "Updated status to Done"
else
    audit_log_confirmation "JIRA_UPDATE" "$TICKET_ID" "false" "User cancelled"
fi
```

**Log Categories to Implement**:
1. External operations (JIRA, Confluence, Slack, BitBucket)
2. User confirmations (approved/denied)
3. Safety rule checks
4. Configuration changes
5. Failed operations

**Day 3: Create Audit Review Command**

Create `/ccpm:utils:audit-log` command:

```markdown
---
description: View audit log and security events
argument-hint: [--filter type] [--since date] [--stats]
---

# Audit Log Viewer

Source audit logging functions:
```bash
source "$SCRIPTS_DIR/audit-log.sh"
```

## Options

### Show Recent Entries
```bash
audit_log_recent 50
```

### Filter by Action Type
```bash
audit_log_by_action "JIRA_UPDATE"
```

### Show Statistics
```bash
audit_log_stats
audit_log_external_stats
```

### Search Logs
```bash
audit_log_search "TRAIN-123"
```

### Export
```bash
audit_log_export_json ~/audit-export.json
audit_log_export_csv ~/audit-export.csv
```
```

#### Acceptance Criteria:
- ✅ All external operations logged
- ✅ User confirmations logged (approved/denied)
- ✅ Logs include timestamp, user, action, result
- ✅ JSON and text logs created
- ✅ Log rotation working (10MB limit)
- ✅ Audit review command functional
- ✅ Export to CSV/JSON working

---

### L1-L5: Fix Low-Severity Issues (2 days)

**Day 1: Quick Fixes**

#### L1: Configuration File Permissions
```bash
# In installation script (scripts/install-hooks.sh)
if [[ -f "$HOME/.claude/ccpm-config.yaml" ]]; then
    chmod 600 "$HOME/.claude/ccpm-config.yaml"
    echo "✓ Secured config file permissions"
fi

# Add to validation
if [[ $(stat -f "%OLp" "$CONFIG_FILE") != "600" ]]; then
    echo "⚠️  Warning: Config file permissions too open"
    echo "   Run: chmod 600 $CONFIG_FILE"
fi
```

#### L2: Dependency Version Validation
```bash
# In scripts/verify-hooks.sh
check_jq_version() {
    if command -v jq &> /dev/null; then
        JQ_VERSION=$(jq --version | grep -oE '[0-9]+\.[0-9]+')
        if [[ "$(echo "$JQ_VERSION < 1.6" | bc)" -eq 1 ]]; then
            echo "⚠️  jq version too old: $JQ_VERSION (required: >= 1.6)"
        fi
    fi
}

check_yq_version() {
    if command -v yq &> /dev/null; then
        YQ_VERSION=$(yq --version | grep -oE '[0-9]+\.[0-9]+')
        if [[ "$(echo "$YQ_VERSION < 4.0" | bc)" -eq 1 ]]; then
            echo "⚠️  yq version too old: $YQ_VERSION (required: >= 4.0)"
        fi
    fi
}
```

#### L3: Unsafe rm -rf Usage
```bash
# In scripts/flatten-commands.sh (line 42)
# Add safety check before rm -rf

# Verify we're in the correct directory
if [[ "$PWD" != *"/ccpm" ]]; then
    echo "❌ Safety check failed: Not in CCPM directory"
    exit 1
fi

# Verify commands directory exists
if [[ ! -d "commands" ]]; then
    echo "❌ Safety check failed: commands/ not found"
    exit 1
fi

# Safe deletion
find commands -mindepth 1 -type d ! -name ".tmp" -exec rm -rf {} + 2>/dev/null || true
```

**Day 2: Documentation & Testing**

#### L4: Plugin Integrity Verification
```bash
# Generate checksums
sha256sum .claude-plugin/plugin.json > .claude-plugin/plugin.json.sha256
sha256sum .claude-plugin/marketplace.json > .claude-plugin/marketplace.json.sha256
```

Add to README.md:
```markdown
## Verify Plugin Integrity

```bash
cd ~/.claude/plugins/ccpm
sha256sum -c .claude-plugin/plugin.json.sha256
sha256sum -c .claude-plugin/marketplace.json.sha256
```
```

#### L5: Rate Limiting
```bash
# Add to commands that do bulk operations
rate_limit_sleep() {
    local delay="${1:-1}"  # Default 1 second
    sleep "$delay"
}

# Use in loops
for issue in "${ISSUES[@]}"; do
    # Process issue
    rate_limit_sleep 0.5  # 500ms between operations
done
```

---

## Security Testing

### Test Suite

Create `tests/security-tests.sh`:

```bash
#!/bin/bash
# Comprehensive security test suite

set -euo pipefail

TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_command="$2"

    echo "Running: $test_name"

    if eval "$test_command"; then
        echo "✓ PASSED: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAILED: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

# Test 1: Safety rules validator
run_test "Safety Rules Validation" \
    "./scripts/validate-safety-rules.sh"

# Test 2: Markdown sanitization
run_test "Markdown Sanitization" \
    "./tests/test-sanitization.sh"

# Test 3: Configuration permissions
run_test "Config File Permissions" \
    "[[ \$(stat -f '%OLp' ~/.claude/ccpm-config.yaml 2>/dev/null || echo 600) == '600' ]]"

# Test 4: Audit logging
run_test "Audit Logging" \
    "source scripts/audit-log.sh && audit_log_action 'TEST' 'test' 'SUCCESS' 'test'"

# Test 5: Input validation
run_test "Input Validation" \
    "source scripts/validation-helpers.sh && validate_ticket_id 'WORK-123'"

# Test 6: Shell script security
run_test "ShellCheck" \
    "shellcheck scripts/*.sh || true"  # Non-blocking

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Security Tests Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✓ All security tests passed!"
    exit 0
else
    echo "✗ Some tests failed. Please review."
    exit 1
fi
```

Make executable and run:
```bash
chmod +x tests/security-tests.sh
./tests/security-tests.sh
```

---

## CI/CD Integration

Add to `.github/workflows/security.yml`:

```yaml
name: Security Checks

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  security:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq
          sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
          sudo chmod +x /usr/local/bin/yq

      - name: Install shellcheck
        run: sudo apt-get install -y shellcheck

      - name: Run ShellCheck
        run: shellcheck scripts/*.sh

      - name: Validate Safety Rules
        run: |
          chmod +x scripts/validate-safety-rules.sh
          ./scripts/validate-safety-rules.sh

      - name: Run Security Tests
        run: |
          chmod +x tests/security-tests.sh
          ./tests/security-tests.sh

      - name: Detect Secrets
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
```

---

## Documentation Updates

### 1. Add SECURITY.md

```markdown
# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in CCPM, please report it via:

- **Email**: security@example.com
- **GitHub**: Private security advisory

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x     | :white_check_mark: |
| < 2.0   | :x:                |

## Security Features

- Confirmation workflow for external writes
- Audit logging for all operations
- Input validation and sanitization
- No credential storage
- Secure defaults

## Security Best Practices

1. **Protect configuration**:
   ```bash
   chmod 600 ~/.claude/ccpm-config.yaml
   ```

2. **Review audit logs**:
   ```bash
   /ccpm:utils:audit-log --stats
   ```

3. **Keep dependencies updated**:
   ```bash
   brew upgrade jq yq
   ```

4. **Never commit secrets**:
   - Use `.gitignore`
   - Use environment variables
   - Use MCP server configs

## Security Updates

Security updates are released as patch versions and announced via:
- GitHub Security Advisories
- Release notes
- CHANGELOG.md
```

### 2. Update CONTRIBUTING.md

Add section:

```markdown
## Security Guidelines

When contributing to CCPM, follow these security guidelines:

### External Write Operations

All commands that write to external systems (Jira, Confluence, etc.) MUST:

1. Reference SAFETY_RULES.md
2. Use AskUserQuestion for confirmation
3. Preview content before posting
4. Log operations with audit-log.sh
5. Sanitize user input

Example:
```markdown
## 🚨 CRITICAL: Safety Rules
**READ FIRST**: `SAFETY_RULES.md`

### Step 1: Preview
[Show what will be posted]

### Step 2: Confirm
Use AskUserQuestion

### Step 3: Execute
Log with audit_log_external()
```

### Input Validation

Always validate and sanitize input:

```bash
source scripts/validation-helpers.sh

validate_ticket_id "$TICKET_ID" || exit 1
SAFE_TEXT=$(sanitize_markdown "$USER_INPUT")
```

### Testing

Run security tests before submitting PR:

```bash
./tests/security-tests.sh
./scripts/validate-safety-rules.sh
```
```

---

## Verification Checklist

After implementing all fixes, verify:

### M1: Safety Rules
- [ ] Validator runs successfully
- [ ] 100% compliance rate
- [ ] All external writes have confirmation
- [ ] All commands reference SAFETY_RULES.md

### M2: Sanitization
- [ ] Validation helpers implemented
- [ ] All markdown generation sanitized
- [ ] Tests pass with XSS payloads
- [ ] Ticket IDs validated

### M3: Audit Logging
- [ ] Audit logging script functional
- [ ] External operations logged
- [ ] Confirmations logged
- [ ] Audit review command works
- [ ] Log rotation working

### L1-L5: Low-Severity
- [ ] Config permissions secured
- [ ] Dependency versions checked
- [ ] rm -rf usage safe
- [ ] Plugin integrity verification
- [ ] Rate limiting implemented

### Testing
- [ ] All security tests pass
- [ ] CI/CD pipeline configured
- [ ] No shellcheck errors
- [ ] No secrets detected

### Documentation
- [ ] SECURITY.md created
- [ ] CONTRIBUTING.md updated
- [ ] README.md updated
- [ ] Security training documented

---

## Timeline Summary

| Week | Tasks | Effort | Deliverables |
|------|-------|--------|--------------|
| 1 | M1, M2 | 5 days | Safety validation, Sanitization |
| 2 | M3, L1-L5 | 5 days | Audit logging, Low-severity fixes |
| 3-4 | R1-R12 | 5 days | Best practices, Documentation |
| **Total** | | **15 days** | **Production-ready security** |

---

## Support

For questions about security implementation:

1. Review [SECURITY_AUDIT_REPORT.md](./SECURITY_AUDIT_REPORT.md)
2. Check [SAFETY_RULES.md](./commands/SAFETY_RULES.md)
3. Open GitHub issue with `security` label

---

**Last Updated**: 2025-11-20
**Status**: Implementation Guide Ready
