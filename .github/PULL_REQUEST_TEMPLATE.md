# Pull Request

## 📝 Description

Brief description of changes and why they're needed.

Fixes #(issue number)

## 🎯 Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] Performance improvement
- [ ] Other (please describe):

## 🧪 How Has This Been Tested?

Describe the tests you ran to verify your changes:

- [ ] Tested command execution: `/pm:...`
- [ ] Tested with verbose logging: `claude --verbose`
- [ ] Tested agent discovery: `./scripts/discover-agents.sh`
- [ ] Tested hooks (if applicable)
- [ ] Tested on fresh install
- [ ] Tested upgrade path (if applicable)

**Test Configuration:**
- CCPM Version:
- Claude Code Version:
- OS:

## 📋 Changes Made

List of specific changes:

- Added/Modified: `path/to/file.md`
  - Description of what changed
- Added/Modified: `path/to/other/file.sh`
  - Description of what changed

## 📚 Documentation

- [ ] Updated README.md (if adding new feature)
- [ ] Updated CHANGELOG.md
- [ ] Updated command documentation in `commands/README.md`
- [ ] Updated relevant guides (MCP_INTEGRATION_GUIDE.md, etc.)
- [ ] Added/updated code comments

## 🔒 Safety Checks

- [ ] External write operations require user confirmation
- [ ] No breaking changes to existing commands (or documented)
- [ ] Hooks timeout in reasonable time (<5s preferred)
- [ ] Scripts are executable (`chmod +x`)
- [ ] JSON files validated with `jq`

## ✅ Checklist

- [ ] My code follows the project's code style
- [ ] I've performed a self-review of my own code
- [ ] I've commented my code, particularly in hard-to-understand areas
- [ ] I've made corresponding changes to the documentation
- [ ] My changes generate no new warnings or errors
- [ ] I've updated the CHANGELOG.md
- [ ] My commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
- [ ] All scripts have proper permissions and run successfully
- [ ] Branch is up to date with `main`

## 🖼️ Screenshots (if applicable)

Add screenshots showing the new feature or fixed bug.

## 💬 Additional Notes

Any additional information reviewers should know:

- Known limitations:
- Future improvements:
- Dependencies:
