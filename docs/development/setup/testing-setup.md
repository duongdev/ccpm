# CCPM Testing Infrastructure Setup Guide

Quick setup guide for running tests on the CCPM plugin.

## Installation

All test scripts are included in the repository and ready to use.

### Scripts Included

```
scripts/
├── validate-plugin.sh           # Validate plugin structure
├── test-skill-activation.sh     # Test skill auto-activation
├── verify-hook-integrity.sh     # Verify hook configuration
├── setup-local-marketplace.sh   # Test local marketplace setup
├── run-all-tests.sh             # Run all tests together
└── pre-commit-validate.sh       # Pre-commit validation hook
```

## Quick Start

### 1. Run All Tests
```bash
./scripts/run-all-tests.sh
```

### 2. Run Specific Test Suite
```bash
# Plugin validation only
./scripts/validate-plugin.sh

# Skill testing only
./scripts/test-skill-activation.sh

# Hook verification only
./scripts/verify-hook-integrity.sh

# Marketplace testing only
./scripts/setup-local-marketplace.sh --test
```

### 3. Detailed Output
```bash
./scripts/run-all-tests.sh --verbose
```

### 4. Auto-Fix Issues
```bash
./scripts/run-all-tests.sh --fix
```

### 5. CI/CD Mode
```bash
./scripts/run-all-tests.sh --ci
```

## Setup Pre-Commit Validation

Automatically validate commits before pushing:

```bash
# Create hooks directory
mkdir -p .git/hooks

# Install pre-commit hook
cp scripts/pre-commit-validate.sh .git/hooks/pre-commit

# Make it executable
chmod +x .git/hooks/pre-commit
```

Now tests will run automatically before each commit.

## Local Marketplace Testing

Test plugin registration as a local marketplace plugin:

```bash
# Test without installing
./scripts/setup-local-marketplace.sh --test

# Install as local plugin
./scripts/setup-local-marketplace.sh --install

# Verify installation
./scripts/setup-local-marketplace.sh --verify

# Show plugin info
./scripts/setup-local-marketplace.sh --info

# Uninstall when done
./scripts/setup-local-marketplace.sh --uninstall
```

## Test Results

### Success Output
```
╔══════════════════════════════════════════════════════════════╗
║                     Test Results Summary                     ║
╚══════════════════════════════════════════════════════════════╝

Test Suites Run:     4
Passed:              4
Failed:              0

✓ All test suites PASSED
```

### Failure Output
```
✗ Validation FAILED

Issues found:
- Command 'example.md' missing description field
- Hook 'setup' not found in hooks.json

Fix with: ./scripts/run-all-tests.sh --fix
```

## What Gets Tested

### Plugin Validation
- ✓ Command files have valid YAML frontmatter
- ✓ All required fields present (description, etc.)
- ✓ Markdown structure is correct
- ✓ Skill SKILL.md files exist and are valid
- ✓ Plugin JSON is valid
- ✓ No duplicate command names
- ✓ All referenced files exist
- ✓ Script permissions are correct

### Skill Testing
- ✓ All skills have SKILL.md files
- ✓ Skill frontmatter is valid
- ✓ Skill names match directory names
- ✓ Descriptions are substantial
- ✓ Content structure is valid
- ✓ Activation triggers documented
- ✓ Allowed-tools are declared

### Hook Verification
- ✓ hooks.json exists and is valid JSON
- ✓ All hook definitions are proper
- ✓ Hook files are readable
- ✓ Prompt files are not empty
- ✓ Shell scripts have valid syntax
- ✓ Scripts are executable
- ✓ Dependencies exist
- ✓ No performance issues

### Marketplace Testing
- ✓ Plugin structure is correct
- ✓ Plugin JSON is valid
- ✓ Commands are discoverable
- ✓ Component paths are accessible
- ✓ All components are countable

## Troubleshooting

### "Command missing description field"
Add to command's YAML frontmatter:
```yaml
---
description: Your description here
---
```

### "Script has syntax errors"
Check with:
```bash
bash -n scripts/your-script.sh
```

### "discover-agents.sh not found"
Ensure it exists:
```bash
ls -la scripts/discover-agents.sh
chmod +x scripts/discover-agents.sh
```

### "hooks.json invalid JSON"
Validate with:
```bash
jq empty hooks/hooks.json
```

## GitHub Actions

Tests run automatically on:
- Push to main/develop branches
- Pull requests to main/develop
- Changes to commands, skills, hooks, agents, or plugin config

View results in GitHub Actions tab.

## Best Practices

1. **Run tests before committing:**
   ```bash
   ./scripts/run-all-tests.sh
   ```

2. **Use pre-commit hook:**
   - Install once with instructions above
   - Automatic validation on every commit

3. **Fix issues early:**
   ```bash
   ./scripts/run-all-tests.sh --fix
   ```

4. **Review verbose output:**
   ```bash
   ./scripts/run-all-tests.sh --verbose
   ```

5. **Monitor GitHub Actions:**
   - Check test results on PRs
   - Fix failures before merging

## Performance

Total test execution time: **< 15 seconds**

- Plugin Validation: ~2-3s
- Skill Testing: ~1-2s
- Hook Verification: ~2-3s
- Marketplace: ~1s

Suitable for use in:
- Pre-commit hooks
- CI/CD pipelines
- Local development
- Release verification

## Documentation

For detailed information, see:
- `/docs/development/testing-infrastructure.md` - Complete guide
- `/TEST_INFRASTRUCTURE_SUMMARY.md` - Implementation summary

## Support

If tests fail:
1. Run with `--verbose` flag
2. Check output for specific errors
3. See `/docs/development/testing-infrastructure.md` troubleshooting section
4. Run auto-fix: `./scripts/run-all-tests.sh --fix`

## Next Steps

1. Run all tests:
   ```bash
   ./scripts/run-all-tests.sh --verbose
   ```

2. Fix any issues:
   ```bash
   ./scripts/run-all-tests.sh --fix
   ```

3. Install pre-commit hook:
   ```bash
   mkdir -p .git/hooks && cp scripts/pre-commit-validate.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
   ```

4. Verify everything works:
   ```bash
   ./scripts/setup-local-marketplace.sh --verify
   ```

All done! Tests are now integrated into your development workflow.
