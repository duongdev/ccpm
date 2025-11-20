# Testing Infrastructure Guide

Complete guide to testing the CCPM plugin locally and in CI/CD.

## Quick Start

```bash
# Run all tests
./scripts/run-all-tests.sh

# Run with detailed output
./scripts/run-all-tests.sh --verbose

# Auto-fix issues and run
./scripts/run-all-tests.sh --fix

# CI/CD mode
./scripts/run-all-tests.sh --ci
```

## Testing Components

### 1. Plugin Validation (`validate-plugin.sh`)

Comprehensive validation of plugin structure and integrity.

**What it checks:**
- Command files have valid YAML frontmatter
- All commands have required `description` field
- Command markdown structure is correct
- Skill SKILL.md files exist and are valid
- Plugin.json and hooks.json have valid JSON
- No duplicate command names
- Referenced files and paths exist
- Script permissions are correct

**Usage:**
```bash
./scripts/validate-plugin.sh                # Standard validation
./scripts/validate-plugin.sh --verbose      # Detailed output
./scripts/validate-plugin.sh --fix          # Auto-fix issues
```

**Output:**
- Detailed validation report for each component
- Summary with pass/fail counts
- Clear error messages for issues

### 2. Skill Auto-Activation Testing (`test-skill-activation.sh`)

Validates skill discovery and auto-activation mechanisms.

**What it checks:**
- All skills have SKILL.md files
- Skill frontmatter is valid (name, description fields)
- Skill names match directory names
- Descriptions are substantial (>20 chars)
- Content structure is valid
- Activation triggers are documented
- Allowed-tools declarations are present

**Usage:**
```bash
./scripts/test-skill-activation.sh                    # Standard tests
./scripts/test-skill-activation.sh --verbose          # Detailed output
./scripts/test-skill-activation.sh --simulate "done"  # Simulate trigger
```

**Simulating Triggers:**
```bash
# See which skills activate for specific keywords
./scripts/test-skill-activation.sh --simulate "done"
./scripts/test-skill-activation.sh --simulate "verification"
./scripts/test-skill-activation.sh --simulate "implementation"
```

### 3. Hook Integrity Verification (`verify-hook-integrity.sh`)

Ensures hooks are properly configured and executable.

**What it checks:**
- hooks.json exists and has valid JSON
- All hook types are properly defined
- Hook files exist and are readable
- Prompt files are not empty
- Shell scripts have valid bash syntax
- Script shebangs are present
- Scripts are executable (or warns)
- Dependencies like discover-agents.sh exist
- Hook references in JSON point to real files
- No potential performance issues

**Usage:**
```bash
./scripts/verify-hook-integrity.sh                # Standard verification
./scripts/verify-hook-integrity.sh --verbose      # Detailed output
./scripts/verify-hook-integrity.sh --fix          # Auto-fix (permissions, etc.)
```

**Auto-Fixable Issues:**
- Making shell scripts executable
- Ensuring discover-agents.sh is executable

### 4. Local Marketplace Setup (`setup-local-marketplace.sh`)

Tests plugin registration as a local marketplace plugin.

**What it tests:**
- Plugin structure is correct
- Plugin JSON is valid
- Symlink can be created
- Commands are discoverable
- Component paths are accessible

**Usage:**
```bash
./scripts/setup-local-marketplace.sh --test      # Test without install
./scripts/setup-local-marketplace.sh --install   # Install local plugin
./scripts/setup-local-marketplace.sh --verify    # Verify installation
./scripts/setup-local-marketplace.sh --info      # Show plugin info
./scripts/setup-local-marketplace.sh --uninstall # Remove local plugin
```

**Component Discovery:**
Tests that Claude Code can discover:
- Commands (`.claude/commands/` or configured path)
- Agents (`.claude/agents/` or configured path)
- Skills (`.claude/skills/` or configured path)
- Hooks (configured in plugin.json)

### 5. Comprehensive Test Suite (`run-all-tests.sh`)

Orchestrates all test suites with consistent reporting.

**Runs:**
1. Plugin Validation
2. Skill Auto-Activation Testing
3. Hook Integrity Verification
4. Local Marketplace Tests

**Usage:**
```bash
./scripts/run-all-tests.sh                       # Run all tests
./scripts/run-all-tests.sh --verbose             # Detailed output
./scripts/run-all-tests.sh --fix                 # Auto-fix issues
./scripts/run-all-tests.sh --ci                  # CI/CD mode
./scripts/run-all-tests.sh --only "Plugin"       # Run specific suite
./scripts/run-all-tests.sh --only "Plugin|Skill" # Run multiple suites
```

**Test Suite Selection:**
Use regex patterns to run specific suites:
```bash
./scripts/run-all-tests.sh --only "Plugin Validation"
./scripts/run-all-tests.sh --only "Skill"
./scripts/run-all-tests.sh --only "Hook"
./scripts/run-all-tests.sh --only "Marketplace"
```

### 6. Pre-Commit Validation (`pre-commit-validate.sh`)

Runs automatically (or manually) before git commits.

**What it checks:**
- Staged command files have valid frontmatter
- Staged skill files are properly formatted
- hooks.json is valid JSON
- plugin.json is valid JSON
- No duplicate command names
- Script syntax is valid (bash -n)
- File sizes are reasonable
- File permissions are correct

**Installation as git hook:**
```bash
mkdir -p .git/hooks
cp scripts/pre-commit-validate.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Manual usage:**
```bash
./scripts/pre-commit-validate.sh
```

## GitHub Actions Workflow

Automated testing on every push and pull request.

**File:** `.github/workflows/test-plugin.yml`

**Triggers:**
- Push to main/develop branches (changes to commands, skills, hooks, agents, etc.)
- Pull requests to main/develop
- Manual workflow dispatch

**Jobs:**
1. **Plugin Validation** - Validates all components
2. **Skill Auto-Activation** - Tests skill structure and discovery
3. **Hook Verification** - Verifies hook integrity
4. **Marketplace Tests** - Tests local marketplace setup
5. **Comprehensive Test** - Runs all tests together
6. **Syntax Validation** - Validates YAML and bash syntax
7. **Dependency Check** - Verifies all dependencies exist

**Test Report:**
- Generates GitHub Summary with component counts
- Shows pass/fail status for each job
- Fails workflow if any tests fail

## Running Tests in Different Contexts

### Local Development
```bash
# Quick check before committing
./scripts/run-all-tests.sh

# Detailed investigation
./scripts/run-all-tests.sh --verbose

# Fix issues automatically
./scripts/run-all-tests.sh --fix
```

### Pre-Commit Verification
```bash
# Set up git hook
mkdir -p .git/hooks
cp scripts/pre-commit-validate.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Run manually if needed
./scripts/pre-commit-validate.sh
```

### CI/CD Pipeline
```bash
# Clean output for CI systems
./scripts/run-all-tests.sh --ci

# Exit code 0: All tests passed
# Exit code 1: Tests failed
```

### Targeted Testing
```bash
# Test only command changes
./scripts/validate-plugin.sh

# Test only skill changes
./scripts/test-skill-activation.sh

# Test only hook changes
./scripts/verify-hook-integrity.sh

# Test marketplace integration
./scripts/setup-local-marketplace.sh --verify
```

## Test Output Examples

### Successful Validation
```
ℹ Validating command files...
✓ planning:create.md
✓ planning:plan.md
✓ implementation:start.md
[...]
Commands: 45/45 valid

✓ Validation PASSED
```

### Failed Validation
```
ℹ Validating command files...
✓ planning:create.md
✗ planning:plan.md missing description field
[...]
Commands: 44/45 valid

✗ Validation FAILED
```

### Skill Activation Test
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Testing Skill: ccpm-code-review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Directory structure valid
✓ Frontmatter structure valid
✓ All required fields present
✓ Skill name is valid
✓ Description length valid
✓ Content structure valid
✓ Skill 'ccpm-code-review' passed all tests
```

### Comprehensive Test Report
```
╔══════════════════════════════════════════════════════════════╗
║                     Test Results Summary                     ║
╚══════════════════════════════════════════════════════════════╝

Test Suites Run:     4
Passed:              4
Failed:              0
Duration:           12s

✓ All test suites PASSED
```

## Troubleshooting

### "Command XXX missing YAML frontmatter"
**Issue:** Command file doesn't start with `---`

**Fix:**
```yaml
---
description: Your command description
---
# Command Name
...
```

### "Skill file missing required field"
**Issue:** SKILL.md missing `name` or `description`

**Fix:** Add to SKILL.md frontmatter:
```yaml
---
name: skill-name
description: Full description of skill
---
```

### "hooks.json has invalid JSON"
**Issue:** JSON syntax error in hooks.json

**Fix:** Validate with jq:
```bash
jq empty hooks/hooks.json
```

### "Script has syntax errors"
**Issue:** Bash script has syntax problems

**Fix:** Check with bash:
```bash
bash -n scripts/your-script.sh
```

### "discover-agents.sh referenced but not found"
**Issue:** Hook references missing dependency

**Fix:** Ensure script exists and is executable:
```bash
ls -la scripts/discover-agents.sh
chmod +x scripts/discover-agents.sh
```

### "Plugin structure is invalid"
**Issue:** Plugin directory/file structure doesn't match plugin.json

**Fix:** Verify paths in plugin.json match actual structure:
```bash
jq '.commands, .agents' .claude-plugin/plugin.json
```

## Performance Notes

### Test Execution Times
- **Plugin Validation:** ~2-3 seconds
- **Skill Auto-Activation:** ~1-2 seconds
- **Hook Integrity:** ~2-3 seconds
- **Marketplace Tests:** ~1 second
- **Comprehensive Suite:** ~6-10 seconds

Total execution time: < 15 seconds (well within CI/CD limits)

### Optimization Tips
- Run tests in parallel on CI (GitHub Actions does this)
- Use `--only` flag to test specific components
- Cache jq and bash installations in CI
- Skip tests for documentation-only changes

## Best Practices

### 1. Run Tests Before Committing
```bash
# Before pushing
./scripts/run-all-tests.sh --verbose
```

### 2. Fix Issues Early
```bash
# Auto-fix what can be fixed
./scripts/run-all-tests.sh --fix

# Then address remaining issues
```

### 3. Use Pre-Commit Hooks
```bash
# Automatic validation on every commit
mkdir -p .git/hooks
cp scripts/pre-commit-validate.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### 4. Review Test Output
- Check for warnings, not just errors
- Fix warnings before they become errors
- Keep components well-structured

### 5. CI/CD Integration
- Tests run on every push
- Pull requests must pass all tests
- Review test report in GitHub Actions

## Adding New Tests

To add a new test:

1. **Create test script:** `scripts/test-new-component.sh`
2. **Implement validation functions**
3. **Add to `run-all-tests.sh`:**
   ```bash
   run_test_suite run_new_component_tests || local_failed=true
   ```
4. **Add to GitHub Actions:** `.github/workflows/test-plugin.yml`
5. **Document in this guide**

## Integration with Development Workflow

### Pull Request Workflow
1. Create feature branch
2. Make changes to commands/skills/hooks
3. Tests run automatically on PR
4. Review test results
5. Merge only if tests pass

### Release Workflow
1. All tests must pass
2. Comprehensive test suite runs
3. Generate test report
4. Update CHANGELOG.md
5. Tag release

### Pre-Deployment
```bash
# Run full validation
./scripts/run-all-tests.sh --verbose

# Verify local marketplace setup
./scripts/setup-local-marketplace.sh --verify

# Check for blockers
# (all tests should pass)
```

## Reference

### Test Script Locations
- Validation: `/scripts/validate-plugin.sh`
- Skills: `/scripts/test-skill-activation.sh`
- Hooks: `/scripts/verify-hook-integrity.sh`
- Marketplace: `/scripts/setup-local-marketplace.sh`
- All tests: `/scripts/run-all-tests.sh`
- Pre-commit: `/scripts/pre-commit-validate.sh`
- CI/CD: `/.github/workflows/test-plugin.yml`

### Configuration
- Plugin: `/.claude-plugin/plugin.json`
- Hooks: `/hooks/hooks.json`
- Commands: `/commands/`
- Skills: `/skills/*/SKILL.md`
- Agents: `/agents/`

### Environment Variables
```bash
CLAUDE_HOME=.claude              # Claude Code config location
VERBOSE=true                      # Enable verbose output
```

## Support

For issues with tests:
1. Run with `--verbose` flag
2. Check output for specific error
3. See Troubleshooting section
4. Review test script source code
5. Check GitHub Issues
