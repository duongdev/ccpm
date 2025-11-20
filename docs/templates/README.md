# CCPM Documentation Templates

This directory contains standardized templates for all CCPM documentation types.

**Purpose:** Ensure consistency, completeness, and maintainability across all documentation.

---

## Available Templates

### 1. Command Documentation Template

**File:** [`command-template.md`](./command-template.md)

**Use for:** All command files in `commands/`

**Sections included:**
- Front matter with metadata
- Overview and purpose
- Syntax and arguments
- Usage examples (multiple scenarios)
- Features and capabilities
- How it works (technical details)
- Interactive mode description
- Related commands
- Configuration options
- Error handling and troubleshooting
- Best practices
- Safety notes
- Performance metrics
- Technical details
- Advanced usage
- Version history
- Cross-references

**When to use:**
- Creating a new command
- Standardizing an existing command
- Updating command documentation

**Example:**
```bash
# Copy template
cp docs/templates/command-template.md commands/new-category:new-command.md

# Fill in all sections
# Update frontmatter
# Add examples
# Test all examples work
# Validate with scripts
```

### 2. Subagent Documentation Template

**File:** [`subagent-template.md`](./subagent-template.md)

**Use for:** All subagent files in `agents/`

**Sections included:**
- Front matter with capabilities and dependencies
- Purpose and problem statement
- Capabilities (can/cannot do)
- Architecture overview with flow diagrams
- Complete operation API reference
- Usage examples (basic + advanced)
- Performance metrics (tokens, timing, caching)
- Error handling with error codes
- Best practices and anti-patterns
- Integration patterns
- Testing guidelines
- Troubleshooting guide
- Development guide
- Version history

**When to use:**
- Creating a new subagent
- Documenting an existing subagent
- Updating subagent documentation

**Example:**
```bash
# Copy template
cp docs/templates/subagent-template.md agents/new-subagent.md

# Fill in all sections
# Document all operations
# Add performance metrics
# Include error codes
# Test all examples
```

### 3. Guide Documentation Template

**File:** See Section 4.2 in [`documentation-reorganization-plan.md`](../architecture/documentation-reorganization-plan.md#42-guide-documentation-template)

**Use for:** User-facing how-to guides in `docs/guides/`

**Sections included:**
- Front matter (title, category, audience, difficulty, prerequisites)
- What you'll learn
- Prerequisites checklist
- Overview
- Step-by-step instructions
- Verification
- Next steps
- Troubleshooting
- Additional resources

**When to use:**
- Writing a tutorial
- Creating a how-to guide
- Documenting a workflow

### 4. Reference Documentation Template

**File:** See Section 4.3 in [`documentation-reorganization-plan.md`](../architecture/documentation-reorganization-plan.md#43-reference-documentation-template)

**Use for:** Technical reference docs in `docs/reference/`

**Sections included:**
- Quick navigation
- Introduction
- Detailed sections with syntax/parameters/examples
- Complete index
- Cross-references

**When to use:**
- Creating API documentation
- Documenting configuration options
- Building comprehensive reference

### 5. Architecture Decision Record (ADR) Template

**File:** See Section 4.4 in [`documentation-reorganization-plan.md`](../architecture/documentation-reorganization-plan.md#44-architecture-decision-record-adr-template)

**Use for:** Design decisions in `docs/architecture/decisions/`

**Sections included:**
- Status
- Context and problem statement
- Decision drivers
- Considered options
- Decision outcome with justification
- Consequences
- Implementation details
- Validation criteria
- References

**When to use:**
- Documenting a significant design decision
- Recording architectural choices
- Explaining trade-offs

### 6. Development Guide Template

**File:** See Section 4.5 in [`documentation-reorganization-plan.md`](../architecture/documentation-reorganization-plan.md#45-development-guide-template)

**Use for:** Contributor guides in `docs/development/guides/`

**Sections included:**
- Audience and prerequisites
- Overview
- Architecture overview
- Step-by-step guide
- Best practices
- Testing
- Common pitfalls
- Advanced topics

**When to use:**
- Creating contributor documentation
- Writing developer guides
- Documenting development workflows

### 7. README.md Index Template

**File:** See Section 4.6 in [`documentation-reorganization-plan.md`](../architecture/documentation-reorganization-plan.md#46-readmemd-index-template)

**Use for:** All directory index files

**Sections included:**
- Directory purpose
- Overview
- Contents table
- Quick start
- Navigation links
- Contributing notes

**When to use:**
- Creating a new documentation directory
- Updating an existing index
- Organizing directory contents

---

## Quick Start

### For New Commands

1. **Copy template:**
   ```bash
   cp docs/templates/command-template.md commands/category:new-command.md
   ```

2. **Fill in frontmatter:**
   ```markdown
   ---
   title: Your Command Name
   category: [spec|planning|implementation|verification|completion|utils|project]
   description: One-line description
   syntax: /ccpm:category:command-name [args]
   added: v2.X
   updated: v2.X
   status: stable
   ---
   ```

3. **Replace placeholders:**
   - `[One-line purpose statement]`
   - `<required-arg>`
   - `[optional-arg]`
   - All `[Description]` fields
   - All example sections

4. **Add real examples:**
   ```bash
   # Test your examples work
   /ccpm:category:command-name actual-arg
   ```

5. **Validate:**
   ```bash
   # Check links
   ./scripts/documentation/validate-links.sh

   # Check template compliance
   ./scripts/documentation/validate-templates.sh
   ```

6. **Update indexes:**
   - Add to `commands/README.md`
   - Add to `docs/reference/commands/category.md`

### For New Subagents

1. **Copy template:**
   ```bash
   cp docs/templates/subagent-template.md agents/new-subagent.md
   ```

2. **Fill in frontmatter:**
   ```markdown
   ---
   title: Subagent Name
   type: [core|project-management|specialized]
   version: 1.0
   status: stable
   capabilities:
     - capability-1
     - capability-2
   dependencies:
     - mcp-server-name
   token_budget: X,XXX
   ---
   ```

3. **Document all operations:**
   - Operation name
   - Parameters (with types)
   - Returns (with structure)
   - Examples (tested)
   - Error codes

4. **Add performance metrics:**
   - Token usage per operation
   - Execution time
   - Cache hit rates
   - Savings percentages

5. **Test examples:**
   ```markdown
   Task(new-subagent): `
   operation: test_operation
   params:
     param1: "test"
   `
   ```

6. **Update indexes:**
   - Add to `agents/README.md`
   - Add to `docs/reference/agents/catalog.md`

### For New Guides

1. **Choose location:**
   ```bash
   # Getting started guide
   docs/guides/getting-started/

   # Feature guide
   docs/guides/features/

   # Workflow guide
   docs/guides/workflows/

   # Troubleshooting guide
   docs/guides/troubleshooting/
   ```

2. **Use template structure** (see master plan Section 4.2)

3. **Write step-by-step instructions:**
   - Clear numbered steps
   - Code examples for each step
   - Expected results
   - Verification steps

4. **Add troubleshooting:**
   - Common issues
   - Solutions
   - Prevention tips

5. **Update indexes:**
   - Add to subdirectory README.md
   - Add to `docs/guides/README.md`
   - Add to `docs/README.md` if major guide

---

## Validation

### Before Committing

**Run validation scripts:**
```bash
# Validate links
./scripts/documentation/validate-links.sh
# Should show: ✅ All links are valid!

# Validate structure
./scripts/documentation/validate-structure.sh
# Should show: ✅ Structure validation passed

# Validate templates
./scripts/documentation/validate-templates.sh
# Should show: ✅ Template compliance: 100%
```

### Checklist

**For all documentation:**
- [ ] Front matter complete
- [ ] All sections filled (not left as `[Placeholder]`)
- [ ] Examples tested and work
- [ ] Links valid (internal and external)
- [ ] Code blocks have language specifiers
- [ ] Tables properly formatted
- [ ] "Last updated" date set to today
- [ ] Listed in appropriate index files

**For commands specifically:**
- [ ] Syntax examples correct
- [ ] Arguments table complete
- [ ] Usage examples tested
- [ ] Interactive mode documented
- [ ] Related commands linked
- [ ] Safety notes added (if external writes)

**For subagents specifically:**
- [ ] All operations documented
- [ ] Performance metrics included
- [ ] Error codes documented
- [ ] Caching strategy explained
- [ ] Integration examples provided
- [ ] Tests written

---

## Best Practices

### Writing Style

**✅ Do:**
- Use clear, concise language
- Provide concrete examples
- Explain the "why" not just the "what"
- Use consistent terminology
- Add code blocks for all commands
- Include expected outputs
- Link to related documentation

**❌ Don't:**
- Leave placeholder text
- Use vague descriptions
- Assume prior knowledge
- Copy-paste without adapting
- Forget to test examples
- Skip troubleshooting sections

### Example Quality

**✅ Good example:**
```markdown
### Example 1: Create a Task with External PM

```bash
/ccpm:planning:create "Add user authentication" my-app JIRA-123
```

**What happens:**
1. Creates Linear issue (e.g., WORK-456)
2. Fetches context from JIRA-123
3. Populates Linear with research
4. Displays status and next actions

**Expected output:**
```
✅ Issue Created: WORK-456
📋 Planning Complete!

💡 What would you like to do next?
  1. Start Implementation ⭐
  2. Get AI Insights
  3. Auto-Assign Agents
```
```

**❌ Bad example:**
```markdown
### Example: Create a task

```bash
/ccpm:planning:create "task" project
```

[Creates a task]
```

### Maintenance

**Regular updates:**
- Review documentation quarterly
- Update examples for new versions
- Fix broken links immediately
- Refresh screenshots/diagrams annually
- Mark outdated docs as archived

**Version changes:**
- Update "Last updated" date
- Add to Version History section
- Document breaking changes
- Provide migration notes

---

## Contributing

### Adding New Templates

**Process:**
1. Identify need for new template
2. Draft template structure
3. Get review from maintainers
4. Add to this directory
5. Update this README
6. Document usage guidelines

**Template requirements:**
- Clear purpose statement
- Complete section list
- Example of filled template
- Usage guidelines
- Validation criteria

### Improving Existing Templates

**Process:**
1. Identify improvement opportunity
2. Discuss with maintainers
3. Update template
4. Update this README
5. Notify users via changelog
6. Provide migration guidance if needed

**Backward compatibility:**
- Don't remove required sections
- Mark deprecated sections
- Provide transition period
- Document changes clearly

---

## Support

**Questions about templates:**
- Review the master plan: [`docs/architecture/documentation-reorganization-plan.md`](../architecture/documentation-reorganization-plan.md)
- Check examples in existing documentation
- Ask in GitHub discussions
- Open an issue for template improvements

**Template issues:**
- Missing sections
- Unclear guidelines
- Validation failures
- Suggestions for improvement

Report via: [GitHub Issues](https://github.com/duongdev/ccpm/issues)

---

## See Also

- [Documentation Reorganization Plan](../architecture/documentation-reorganization-plan.md) - Master plan
- [Documentation Structure ADR](../architecture/decisions/005-documentation-structure.md) - Design decision
- [Contributing Guidelines](../../CONTRIBUTING.md) - General contribution guide
- [CLAUDE.md](../../CLAUDE.md) - AI assistant instructions

---

**Last Updated:** 2025-11-21
**Templates Version:** 1.0
**Status:** Ready for use
