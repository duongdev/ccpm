# Gemini Large File Fallback

## Overview

Patterns for using Gemini CLI when Claude's Read tool fails due to token limits (>25K tokens). Gemini's 2M token context window handles large Linear issue descriptions, Confluence pages, config files, and logs.

## Prerequisites

**Gemini CLI Installation:**
```bash
# Option 1: NPM (recommended)
npm install -g @google/generative-ai

# Option 2: Python
pip install google-generativeai
```

**API Key Setup:**
```bash
# Get your key at: https://aistudio.google.com/apikey
export GEMINI_API_KEY="your-key-here"

# Add to shell profile for persistence
echo 'export GEMINI_API_KEY="your-key-here"' >> ~/.zshrc  # or ~/.bashrc
```

**Verify Installation:**
```bash
gemini --version
# Or for Python: python -m google.generativeai --version
```

## Detection Pattern

### When to Use Gemini Fallback

Gemini fallback activates when Claude's Read tool returns:
- `"exceeds maximum allowed tokens"`
- `"file too large"`
- Token limit errors (>25K tokens)

### Bash Fallback Commands

```bash
# For text files - analyze with question
echo "[Your question about the file]" | gemini -y -m gemini-2.0-flash-exp -f [file-path]

# For structured extraction
gemini -y -m gemini-2.0-flash-exp -f [file-path] "Extract the key points from this document"

# For code analysis
gemini -y -m gemini-2.0-flash-exp -f [file-path] "Summarize this code file's purpose and main functions"

# For specific data extraction
gemini -y -m gemini-2.0-flash-exp -f [file-path] "List all TODO items with their line numbers"
```

## Usage in Commands

When a command needs to read potentially large content:

1. **Try Claude Read first** (preferred for smaller files)
2. **On token limit error**, fall back to Gemini:

```markdown
### Reading Large Content

If Read tool fails with "exceeds maximum allowed tokens":

1. Use Gemini CLI fallback:
   ```bash
   gemini -y -m gemini-2.0-flash-exp -f [file-path] "[specific question]"
   ```

2. Process the Gemini response
3. Continue with workflow
```

### Helper Script Usage

```bash
# Using the utility script
./scripts/gemini-fallback.sh [file-path] "[question]" [model]

# Example: Extract checklist from large Linear issue
./scripts/gemini-fallback.sh /tmp/issue-PSN-123.md "Extract the implementation checklist items"

# Example: Analyze large config file
./scripts/gemini-fallback.sh /path/to/config.json "What are the database configuration settings?"

# Example: Use advanced model for complex analysis
./scripts/gemini-fallback.sh /path/to/spec.md "Analyze the architecture and identify potential bottlenecks" gemini-2.0-flash-thinking-exp
```

## Gemini CLI Options

| Option | Description | Example |
|--------|-------------|---------|
| `-y` | Auto-confirm prompts | Required for non-interactive use |
| `-m [model]` | Specify model | `-m gemini-2.0-flash-exp` |
| `-f [path]` | Read file inline | `-f /path/to/file.txt` |
| `--stdin` | Read from stdin | `echo "question" \| gemini --stdin` |
| `--json` | JSON output format | For structured data extraction |

## Available Models

| Model | Context | Speed | Use Case |
|-------|---------|-------|----------|
| `gemini-2.0-flash-exp` | 1M tokens | Fast | **Default** - Large files, quick analysis |
| `gemini-2.0-flash-thinking-exp` | 2M tokens | Medium | Complex reasoning, deep analysis |
| `gemini-1.5-pro` | 2M tokens | Slower | Legacy support, production stability |

**Recommendation:** Use `gemini-2.0-flash-exp` for most cases. It's fast, cost-effective, and handles 1M tokens.

## Example Use Cases

### Large Linear Issue Description

```bash
# Extract implementation checklist from large issue
gemini -y -m gemini-2.0-flash-exp -f /tmp/linear-issue-PSN-123.md \
  "Extract all checklist items from the Implementation Checklist section. Return as a numbered list."

# Find specific requirement
gemini -y -m gemini-2.0-flash-exp -f /tmp/linear-issue-PSN-123.md \
  "What are the authentication requirements mentioned in this issue?"

# Get project context
gemini -y -m gemini-2.0-flash-exp -f /tmp/linear-issue-PSN-123.md \
  "Summarize the project context and goals in 3-5 bullet points"
```

### Large Config File

```bash
# Find specific configuration
gemini -y -m gemini-2.0-flash-exp -f /path/to/config.json \
  "What is the database connection string and retry configuration?"

# Extract environment variables
gemini -y -m gemini-2.0-flash-exp -f /path/to/.env.example \
  "List all required environment variables with their descriptions"

# Analyze configuration structure
gemini -y -m gemini-2.0-flash-exp -f /path/to/turborepo.json \
  "Explain the pipeline configuration and task dependencies"
```

### Large Log File

```bash
# Find errors in large log
gemini -y -m gemini-2.0-flash-exp -f /var/log/application.log \
  "List all ERROR level messages with timestamps in the last 100 entries"

# Analyze error patterns
gemini -y -m gemini-2.0-flash-exp -f /var/log/application.log \
  "Identify the most common error patterns and their frequency"

# Extract stack traces
gemini -y -m gemini-2.0-flash-exp -f /var/log/application.log \
  "Extract all stack traces for database connection errors"
```

### Large Documentation File

```bash
# Extract API endpoints
gemini -y -m gemini-2.0-flash-exp -f /path/to/api-docs.md \
  "List all REST API endpoints with their HTTP methods and descriptions"

# Find migration steps
gemini -y -m gemini-2.0-flash-exp -f /path/to/MIGRATION.md \
  "Extract the step-by-step migration instructions for version 2.0"

# Summarize breaking changes
gemini -y -m gemini-2.0-flash-exp -f /path/to/CHANGELOG.md \
  "List all breaking changes in the last 3 releases"
```

### Large Code File

```bash
# Summarize code structure
gemini -y -m gemini-2.0-flash-exp -f /path/to/large-service.ts \
  "Summarize this file's purpose, main classes, and public API"

# Find specific functions
gemini -y -m gemini-2.0-flash-exp -f /path/to/large-service.ts \
  "List all exported functions with their parameters and return types"

# Identify dependencies
gemini -y -m gemini-2.0-flash-exp -f /path/to/large-service.ts \
  "What external dependencies does this file import and how are they used?"
```

## Token Limits Reference

| Tool | Limit | When to Use |
|------|-------|-------------|
| **Claude Read** | ~25K tokens | **Default** - Preferred for all files |
| **Gemini Flash** | 1M tokens | Fallback when Claude Read fails |
| **Gemini Thinking** | 2M tokens | Very large files with complex analysis |
| **Gemini Pro 1.5** | 2M tokens | Legacy/production stability needs |

**File Size Estimates:**
- ~25K tokens ≈ 100KB text file
- ~1M tokens ≈ 4MB text file
- ~2M tokens ≈ 8MB text file

## Best Practices

### 1. Always Try Claude Read First

Claude Read is faster, integrated, and preferred:
```bash
# Step 1: Try Claude Read
Read(file_path="/path/to/file.md")

# Step 2: On token limit error, fall back to Gemini
./scripts/gemini-fallback.sh /path/to/file.md "Extract checklist items"
```

### 2. Use Specific Questions

Gemini works better with focused queries:

❌ **Avoid vague questions:**
```bash
gemini -f large-file.md "Tell me about this file"
```

✅ **Use specific questions:**
```bash
gemini -f large-file.md "Extract all action items with owners and deadlines"
```

### 3. Prefer Flash Model

Use `gemini-2.0-flash-exp` for most cases:
- Faster response time
- Lower cost
- Sufficient for 95% of use cases

Only use `gemini-2.0-flash-thinking-exp` for:
- Complex architectural analysis
- Multi-step reasoning
- Deep code analysis

### 4. Extract Only What You Need

Don't ask for full file summaries:

❌ **Avoid full summaries:**
```bash
gemini -f large-file.md "Summarize the entire file"
```

✅ **Extract specific data:**
```bash
gemini -f large-file.md "List the API endpoints defined in the 'Routes' section"
```

### 5. Handle Errors Gracefully

Always check for Gemini CLI availability:
```bash
if ! command -v gemini &> /dev/null; then
    echo "Gemini CLI not found. Falling back to manual file inspection."
    exit 1
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo "GEMINI_API_KEY not set. Cannot use Gemini fallback."
    exit 1
fi
```

### 6. Cache Results When Possible

For repeated queries on the same large file:
```bash
# First query - extract and cache
gemini -f large-file.md "Extract all checklist items" > /tmp/checklist.txt

# Use cached result for subsequent operations
cat /tmp/checklist.txt
```

## Integration with CCPM Commands

### /ccpm:plan Integration

When reading large Linear issue descriptions:

```bash
# In plan.md command
# Step 1: Try to read issue description
read_result=$(Read issue-description.md 2>&1)

# Step 2: Check for token limit error
if echo "$read_result" | grep -q "exceeds maximum allowed tokens"; then
    # Step 3: Fall back to Gemini
    checklist=$(./scripts/gemini-fallback.sh issue-description.md \
        "Extract the Implementation Checklist section and return it as a numbered list")
fi
```

### /ccpm:work Integration

When loading large spec documents:

```bash
# In work.md command
# Try to read spec document
spec_content=$(Read /path/to/spec.md 2>&1)

# On token limit, use Gemini for specific extraction
if echo "$spec_content" | grep -q "exceeds maximum allowed tokens"; then
    requirements=$(./scripts/gemini-fallback.sh /path/to/spec.md \
        "List all functional requirements in bullet points")
fi
```

### /ccpm:sync Integration

When analyzing large git diffs:

```bash
# In sync.md command
# Generate diff
git diff > /tmp/changes.diff

# If diff is large, use Gemini to summarize
if [ $(wc -c < /tmp/changes.diff) -gt 100000 ]; then
    summary=$(./scripts/gemini-fallback.sh /tmp/changes.diff \
        "Summarize the key changes in 3-5 bullet points")
fi
```

## Error Handling

### Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `gemini: command not found` | CLI not installed | Install with `npm install -g @google/generative-ai` |
| `API key not set` | Missing `GEMINI_API_KEY` | Set environment variable |
| `Rate limit exceeded` | Too many requests | Add retry logic with exponential backoff |
| `File not found` | Invalid file path | Verify file path exists |
| `Model not found` | Invalid model name | Use `gemini-2.0-flash-exp` or `gemini-2.0-flash-thinking-exp` |

### Retry Logic Pattern

```bash
# Retry with exponential backoff
max_retries=3
retry_count=0
delay=2

while [ $retry_count -lt $max_retries ]; do
    result=$(gemini -y -m gemini-2.0-flash-exp -f "$file" "$question" 2>&1)

    if echo "$result" | grep -q "rate limit"; then
        retry_count=$((retry_count + 1))
        sleep $((delay ** retry_count))
    else
        echo "$result"
        break
    fi
done
```

## Performance Considerations

### Response Time

| Model | Avg Response Time | Use Case |
|-------|------------------|----------|
| Flash Exp | 2-5 seconds | Quick queries, data extraction |
| Thinking Exp | 5-15 seconds | Complex analysis, reasoning |
| Pro 1.5 | 10-30 seconds | Production stability |

### Cost Optimization

- **Use Flash for most queries** - 10x cheaper than Pro
- **Extract only needed data** - Reduce output tokens
- **Cache results** - Avoid repeated queries
- **Batch questions** - Ask multiple things in one query

## Troubleshooting

### Gemini CLI Not Working

```bash
# Check installation
which gemini

# Check Python version (if using Python install)
python --version  # Should be 3.8+

# Reinstall if needed
npm uninstall -g @google/generative-ai
npm install -g @google/generative-ai
```

### API Key Issues

```bash
# Verify API key is set
echo $GEMINI_API_KEY

# Test API key with simple query
echo "Hello" | gemini -y -m gemini-2.0-flash-exp

# Get new API key
open https://aistudio.google.com/apikey
```

### File Reading Issues

```bash
# Check file size
ls -lh /path/to/file.md

# Check file permissions
ls -l /path/to/file.md

# Test with smaller portion
head -n 1000 /path/to/file.md | gemini -y -m gemini-2.0-flash-exp "Summarize"
```

## Security Considerations

1. **API Key Protection**: Never commit `GEMINI_API_KEY` to git
2. **Sensitive Data**: Gemini processes data on Google's servers
3. **File Permissions**: Ensure Gemini CLI can only read intended files
4. **Rate Limiting**: Implement backoff to avoid account suspension

## Future Enhancements

Potential improvements for Gemini fallback:

- [ ] Automatic file size detection (skip Claude Read if >100KB)
- [ ] Response caching layer for repeated queries
- [ ] Batch query optimization for multiple files
- [ ] Integration with CCPM's Linear subagent caching
- [ ] Structured JSON output parsing
- [ ] Fallback chain: Claude → Gemini Flash → Gemini Thinking

## Resources

- [Gemini API Documentation](https://ai.google.dev/docs)
- [Gemini CLI GitHub](https://github.com/google/generative-ai-js)
- [Gemini Models Overview](https://ai.google.dev/models/gemini)
- [API Key Management](https://aistudio.google.com/apikey)

---

**Last Updated:** 2025-12-23
**CCPM Version:** 1.0.0
**Maintainer:** CCPM Team
