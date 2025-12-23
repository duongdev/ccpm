#!/bin/bash
# CCPM Gemini Fallback Utility
# Purpose: Read large files using Gemini CLI when Claude's Read tool fails
# Usage: ./scripts/gemini-fallback.sh <file-path> "<question>" [model]
#
# Examples:
#   ./scripts/gemini-fallback.sh /path/to/large-file.md "Extract checklist items"
#   ./scripts/gemini-fallback.sh /path/to/config.json "What is the database config?" gemini-2.0-flash-thinking-exp

set -e

# Configuration
FILE_PATH="$1"
QUESTION="$2"
MODEL="${3:-gemini-2.0-flash-exp}"  # Default to Flash Exp model
RETRY_MAX=3
RETRY_DELAY=2

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage message
usage() {
    cat << EOF
CCPM Gemini Fallback Utility
=============================

Usage: $0 <file-path> "<question>" [model]

Arguments:
  file-path   Path to the file to analyze
  question    Question to ask about the file
  model       (Optional) Gemini model to use

Available Models:
  gemini-2.0-flash-exp          Fast, 1M tokens (default)
  gemini-2.0-flash-thinking-exp Complex reasoning, 2M tokens
  gemini-1.5-pro                Legacy/production, 2M tokens

Examples:
  # Extract checklist from large Linear issue
  $0 /tmp/issue-PSN-123.md "Extract implementation checklist items"

  # Analyze large config file
  $0 /path/to/config.json "What are the database settings?"

  # Use advanced model for complex analysis
  $0 /path/to/spec.md "Analyze architecture" gemini-2.0-flash-thinking-exp

Environment Variables:
  GEMINI_API_KEY   Required. Get from https://aistudio.google.com/apikey

EOF
    exit 1
}

# Error handler
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Warning handler
warning() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

# Success handler
success() {
    echo -e "${GREEN}$1${NC}" >&2
}

# Validate arguments
if [ -z "$FILE_PATH" ] || [ -z "$QUESTION" ]; then
    usage
fi

# Validate file exists
if [ ! -f "$FILE_PATH" ]; then
    error "File not found: $FILE_PATH"
fi

# Check file size (warn if > 8MB)
file_size=$(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH" 2>/dev/null)
if [ "$file_size" -gt 8388608 ]; then  # 8MB in bytes
    warning "File size is $(($file_size / 1048576))MB. May exceed Gemini token limits."
fi

# Check if gemini CLI is available
if ! command -v gemini &> /dev/null; then
    error "Gemini CLI not found. Install with:\n  npm install -g @google/generative-ai\nOr:\n  pip install google-generativeai"
fi

# Check for API key
if [ -z "$GEMINI_API_KEY" ]; then
    error "GEMINI_API_KEY not set\nGet your key at: https://aistudio.google.com/apikey\nThen: export GEMINI_API_KEY=\"your-key\""
fi

# Validate model name
case "$MODEL" in
    gemini-2.0-flash-exp|gemini-2.0-flash-thinking-exp|gemini-1.5-pro)
        # Valid model
        ;;
    *)
        warning "Unknown model: $MODEL. Using default: gemini-2.0-flash-exp"
        MODEL="gemini-2.0-flash-exp"
        ;;
esac

# Retry logic with exponential backoff
retry_count=0
while [ $retry_count -lt $RETRY_MAX ]; do
    # Execute Gemini query
    result=$(echo "$QUESTION" | gemini -y -m "$MODEL" -f "$FILE_PATH" 2>&1)
    exit_code=$?

    # Check for rate limiting
    if echo "$result" | grep -qi "rate limit"; then
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $RETRY_MAX ]; then
            delay=$((RETRY_DELAY ** retry_count))
            warning "Rate limit hit. Retrying in ${delay}s (attempt $((retry_count + 1))/$RETRY_MAX)..."
            sleep "$delay"
            continue
        else
            error "Rate limit exceeded after $RETRY_MAX retries"
        fi
    fi

    # Check for other errors
    if [ $exit_code -ne 0 ]; then
        if echo "$result" | grep -qi "api key"; then
            error "Invalid API key. Get a new one at: https://aistudio.google.com/apikey"
        elif echo "$result" | grep -qi "model not found"; then
            error "Model not found: $MODEL"
        else
            error "Gemini query failed: $result"
        fi
    fi

    # Success - output result and exit
    echo "$result"
    success "Query completed using $MODEL (file: $(basename "$FILE_PATH"), size: $(($file_size / 1024))KB)" >&2
    exit 0
done

# Should never reach here
error "Unexpected error in retry loop"
