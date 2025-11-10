# Contributing to CCPM

Thank you for your interest in contributing to CCPM! This document provides guidelines and instructions for contributing.

## 🎯 Ways to Contribute

- **Report bugs** - Submit detailed bug reports with reproduction steps
- **Suggest features** - Propose new features or improvements
- **Improve documentation** - Fix typos, clarify instructions, add examples
- **Submit code** - Fix bugs, add features, improve performance
- **Share feedback** - Tell us about your experience using CCPM

## 🐛 Reporting Bugs

Before submitting a bug report:
1. Check existing [GitHub Issues](https://github.com/duongdev/ccpm/issues) to avoid duplicates
2. Test with the latest version of CCPM
3. Verify your MCP servers are configured correctly

When reporting a bug, include:
- **Description** - Clear and concise description of the bug
- **Steps to reproduce** - Minimal steps to reproduce the issue
- **Expected behavior** - What you expected to happen
- **Actual behavior** - What actually happened
- **Environment** - CCPM version, Claude Code version, OS
- **Logs** - Relevant error messages or logs (`claude --verbose`)

Use our [bug report template](.github/ISSUE_TEMPLATE/bug_report.md).

## 💡 Suggesting Features

Before suggesting a feature:
1. Check existing issues and discussions
2. Ensure it aligns with CCPM's goals (project management, automation, quality)
3. Consider if it could be implemented as a custom command or agent

When suggesting a feature, include:
- **Use case** - What problem does it solve?
- **Proposed solution** - How should it work?
- **Alternatives** - What alternatives have you considered?
- **Examples** - Show how it would be used

Use our [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

## 🔧 Development Setup

### Prerequisites

- Claude Code CLI installed
- Git installed
- Linear, GitHub, and Context7 MCP servers configured
- jq installed (`brew install jq` on macOS)

### Local Development

```bash
# 1. Fork the repository
# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/ccpm.git
cd ccpm

# 3. Create a feature branch
git checkout -b feature/your-feature-name

# 4. Install as local plugin
/plugin marketplace add ~/path/to/ccpm
/plugin install ccpm@~/path/to/ccpm

# 5. Test your changes
/pm:utils:help
```

### Testing Changes

```bash
# Test agent discovery
./scripts/discover-agents.sh | jq .

# Run plugin self-test
./scripts/test-plugin.sh

# Test specific command
/pm:utils:help

# Test with verbose logging
claude --verbose
```

### Making Changes

#### Adding a New Command

1. Create command file in `commands/` (flat structure):
   ```bash
   # File: commands/pm:category:command-name.md
   ---
   description: Brief description of what this command does
   ---

   # Command Implementation

   Your command markdown content here...
   ```

2. Follow the interactive mode pattern from `commands/pm:utils:help.md`

3. Test the command:
   ```bash
   /pm:category:command-name arg1 arg2
   ```

#### Modifying a Hook

1. Edit hook file in `hooks/`
2. Ensure timeout is reasonable (<5s preferred)
3. Test hook execution with `claude --verbose`
4. Update `hooks/hooks.json` if adding new hook

#### Updating Scripts

1. Edit script in `scripts/`
2. Ensure it's executable: `chmod +x scripts/your-script.sh`
3. Test script independently: `./scripts/your-script.sh`
4. Update documentation if behavior changes

## 📝 Code Style

### Markdown Files (Commands)

- Use YAML frontmatter with `description` field
- Include argument descriptions with examples
- Follow interactive mode pattern (status → suggestions → menu)
- Add safety checks for external system writes

### Shell Scripts

- Use `#!/usr/bin/env bash`
- Add comments explaining complex logic
- Check dependencies before using (e.g., jq)
- Return proper exit codes (0 = success)

### JSON Files

- Use 2-space indentation
- Validate with `jq` before committing
- Keep plugin.json minimal (only supported fields)

## 🔍 Pull Request Process

### Before Submitting

1. **Test thoroughly** - All affected commands and workflows
2. **Update documentation** - README.md, command docs, CHANGELOG.md
3. **Follow conventions** - Match existing patterns and style
4. **Commit messages** - Use [Conventional Commits](https://www.conventionalcommits.org/)

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `refactor` - Code refactoring
- `test` - Adding/updating tests
- `chore` - Maintenance tasks

**Examples:**
```
feat(commands): add pm:utils:export command for exporting task data

fix(hooks): prevent timeout in smart-agent-selector for large projects

docs(readme): clarify MCP server installation steps
```

### PR Checklist

- [ ] Branch is up to date with `main`
- [ ] All tests pass locally
- [ ] Documentation updated (README, CHANGELOG, command docs)
- [ ] Commit messages follow conventional format
- [ ] No breaking changes (or clearly documented)
- [ ] Scripts are executable and tested
- [ ] Hooks timeout in <5 seconds

### PR Template

Use our [pull request template](.github/PULL_REQUEST_TEMPLATE.md).

## 📚 Documentation

### What to Document

- **New commands** - Add to README.md command table and commands/README.md
- **New features** - Update CHANGELOG.md and feature documentation
- **Breaking changes** - Document migration path in MIGRATION.md
- **Configuration** - Update relevant config examples

### Documentation Style

- Use clear, concise language
- Provide examples and use cases
- Include expected output
- Add troubleshooting tips for common issues

## 🏗️ Architecture Guidelines

### Command Structure

Commands should:
- Load context efficiently (use existing issue data)
- Provide interactive prompts when helpful
- Show status and progress
- Suggest next actions
- Follow safety rules (confirm external writes)

### Hook Design

Hooks should:
- Execute quickly (<5 seconds preferred, <20 seconds max)
- Handle errors gracefully
- Return structured data (JSON when possible)
- Log to stderr for debugging

### Agent Integration

When invoking agents:
- Let smart-agent-selector choose the best agent
- Document when specific agent is required
- Use parallel invocation when independent
- Plan sequential execution for dependencies

## 🔒 Safety Rules

**ALWAYS follow these rules:**

1. **Never write to external systems without confirmation**
   - Jira, Confluence, BitBucket, Slack require explicit user approval
   - Show exact content before posting
   - Wait for confirmation before executing

2. **Read operations are always allowed**
   - Fetching, searching, viewing - no confirmation needed

3. **Linear operations are permitted**
   - Internal tracking system - no confirmation needed

4. **Document safety considerations**
   - Add comments explaining safety checks
   - Update SAFETY_RULES.md if adding new external integrations

## 🧪 Testing

### Manual Testing

Test these scenarios:
- Fresh installation on clean Claude Code instance
- Upgrading from previous version
- All commands execute without errors
- Hooks trigger correctly
- Agent discovery finds all agents
- External integrations work (with MCP servers configured)

### Automated Testing

While CCPM doesn't have automated tests yet, contributions to add testing infrastructure are welcome!

## 🎯 Release Process

(For maintainers)

1. Update version in `.claude-plugin/plugin.json`
2. Update CHANGELOG.md with release notes
3. Commit: `git commit -m "chore: bump version to X.Y.Z"`
4. Tag: `git tag vX.Y.Z`
5. Push: `git push origin main --tags`
6. Create GitHub release with notes from CHANGELOG

## 💬 Getting Help

- **Documentation** - Check README.md and command docs
- **Issues** - Search existing issues
- **Discussions** - Start a GitHub Discussion
- **Contact** - Email me@dustin.tv

## 📜 License

By contributing to CCPM, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to CCPM! 🎉
