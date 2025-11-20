#!/bin/bash
# validation-helpers.sh
# Input validation and sanitization helpers for CCPM commands
# Part of CCPM security audit recommendations
#
# Usage:
#   source "$SCRIPTS_DIR/validation-helpers.sh"
#   validate_ticket_id "$TICKET_ID" || exit 1
#   PROJECT_NAME=$(sanitize_markdown "$PROJECT_NAME")

set -euo pipefail

# ============================================================================
# Input Validation Functions
# ============================================================================

# Validate Jira ticket ID format
# Format: PROJECT-123, WORK-456, etc.
# Returns: 0 if valid, 1 if invalid
validate_ticket_id() {
    local id="$1"

    # Allow empty (optional ticket ID)
    if [[ -z "$id" ]]; then
        return 0
    fi

    # Format: 2-10 uppercase letters, dash, one or more digits
    if [[ ! "$id" =~ ^[A-Z]{2,10}-[0-9]+$ ]]; then
        echo "❌ Invalid ticket ID format: $id" >&2
        echo "   Expected format: PROJECT-123" >&2
        return 1
    fi

    return 0
}

# Validate project ID format
# Format: lowercase alphanumeric with hyphens
# Returns: 0 if valid, 1 if invalid
validate_project_id() {
    local id="$1"

    if [[ -z "$id" ]]; then
        echo "❌ Project ID cannot be empty" >&2
        return 1
    fi

    # Format: lowercase letters, numbers, hyphens (no spaces or special chars)
    if [[ ! "$id" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
        echo "❌ Invalid project ID format: $id" >&2
        echo "   Expected format: my-project, app-123, etc." >&2
        echo "   Rules: lowercase, alphanumeric, hyphens only" >&2
        return 1
    fi

    # Check length (2-50 characters)
    if [[ ${#id} -lt 2 ]] || [[ ${#id} -gt 50 ]]; then
        echo "❌ Project ID must be 2-50 characters: $id" >&2
        return 1
    fi

    return 0
}

# Validate Linear issue ID format
# Format: WORK-123, PROJ-456, etc.
# Returns: 0 if valid, 1 if invalid
validate_linear_issue_id() {
    local id="$1"

    if [[ -z "$id" ]]; then
        echo "❌ Linear issue ID cannot be empty" >&2
        return 1
    fi

    # Format: 2-10 uppercase letters, dash, one or more digits
    if [[ ! "$id" =~ ^[A-Z]{2,10}-[0-9]+$ ]]; then
        echo "❌ Invalid Linear issue ID format: $id" >&2
        echo "   Expected format: WORK-123" >&2
        return 1
    fi

    return 0
}

# Validate URL format
# Returns: 0 if valid, 1 if invalid
validate_url() {
    local url="$1"

    if [[ -z "$url" ]]; then
        return 0  # Empty URLs are allowed (optional)
    fi

    # Basic URL validation (http/https)
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo "❌ Invalid URL format: $url" >&2
        echo "   Expected format: https://example.com" >&2
        return 1
    fi

    # Check for suspicious patterns
    if [[ "$url" =~ javascript:|data:|file:|vbscript: ]]; then
        echo "❌ Suspicious URL protocol detected: $url" >&2
        return 1
    fi

    return 0
}

# Validate email format
# Returns: 0 if valid, 1 if invalid
validate_email() {
    local email="$1"

    if [[ -z "$email" ]]; then
        return 0  # Empty emails are allowed (optional)
    fi

    # Basic email validation
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "❌ Invalid email format: $email" >&2
        return 1
    fi

    return 0
}

# ============================================================================
# Sanitization Functions
# ============================================================================

# Sanitize markdown text to prevent injection
# Removes/escapes characters that could break markdown formatting
sanitize_markdown() {
    local text="$1"

    # Remove markdown-breaking characters
    # Keep alphanumeric, spaces, basic punctuation
    # Remove: [](){}
    echo "$text" | sed 's/[]\[(){}]//g'
}

# Sanitize markdown for link text
# More aggressive - only allows safe characters
sanitize_markdown_link() {
    local text="$1"

    # Only allow: alphanumeric, spaces, hyphens, underscores, basic punctuation
    echo "$text" | sed 's/[^a-zA-Z0-9 ._-]//g'
}

# HTML encode text
# Converts special characters to HTML entities
html_encode() {
    local text="$1"

    echo "$text" | sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e "s/'/\&apos;/g"
}

# URL encode text
# Encodes special characters for use in URLs
url_encode() {
    local string="$1"

    # Use jq if available (most accurate)
    if command -v jq &> /dev/null; then
        echo "$string" | jq -sRr @uri
    else
        # Fallback: basic URL encoding
        echo "$string" | sed \
            -e 's/ /%20/g' \
            -e 's/!/%21/g' \
            -e 's/"/%22/g' \
            -e 's/#/%23/g' \
            -e 's/\$/%24/g' \
            -e 's/\&/%26/g' \
            -e "s/'/%27/g" \
            -e 's/(/%28/g' \
            -e 's/)/%29/g' \
            -e 's/\*/%2A/g' \
            -e 's/+/%2B/g' \
            -e 's/,/%2C/g' \
            -e 's/\//%2F/g' \
            -e 's/:/%3A/g' \
            -e 's/;/%3B/g' \
            -e 's/=/%3D/g' \
            -e 's/?/%3F/g' \
            -e 's/@/%40/g' \
            -e 's/\[/%5B/g' \
            -e 's/\]/%5D/g'
    fi
}

# Create safe markdown link
# Sanitizes both link text and URL
create_safe_markdown_link() {
    local text="$1"
    local url="$2"

    # Validate URL
    if ! validate_url "$url"; then
        echo "[Invalid URL]" >&2
        return 1
    fi

    # Sanitize link text
    local safe_text
    safe_text=$(sanitize_markdown_link "$text")

    # Create link
    echo "[$safe_text]($url)"
}

# ============================================================================
# Length Validation
# ============================================================================

# Validate string length
# Args: text, min_length, max_length, field_name
validate_length() {
    local text="$1"
    local min_length="$2"
    local max_length="$3"
    local field_name="${4:-Text}"

    local length=${#text}

    if [[ $length -lt $min_length ]]; then
        echo "❌ $field_name too short: $length characters (min: $min_length)" >&2
        return 1
    fi

    if [[ $length -gt $max_length ]]; then
        echo "❌ $field_name too long: $length characters (max: $max_length)" >&2
        return 1
    fi

    return 0
}

# ============================================================================
# Path Validation
# ============================================================================

# Validate file path (prevent path traversal)
validate_file_path() {
    local path="$1"
    local base_dir="${2:-.}"

    # Resolve absolute path
    local abs_path
    abs_path=$(cd "$base_dir" && realpath "$path" 2>/dev/null || echo "")

    if [[ -z "$abs_path" ]]; then
        echo "❌ Invalid file path: $path" >&2
        return 1
    fi

    # Check for path traversal (must be within base_dir)
    local abs_base_dir
    abs_base_dir=$(cd "$base_dir" && pwd)

    if [[ ! "$abs_path" == "$abs_base_dir"* ]]; then
        echo "❌ Path traversal detected: $path" >&2
        echo "   Path must be within: $abs_base_dir" >&2
        return 1
    fi

    return 0
}

# ============================================================================
# Numeric Validation
# ============================================================================

# Validate integer
validate_integer() {
    local value="$1"
    local field_name="${2:-Number}"

    if [[ ! "$value" =~ ^-?[0-9]+$ ]]; then
        echo "❌ $field_name must be an integer: $value" >&2
        return 1
    fi

    return 0
}

# Validate positive integer
validate_positive_integer() {
    local value="$1"
    local field_name="${2:-Number}"

    if ! validate_integer "$value" "$field_name"; then
        return 1
    fi

    if [[ $value -le 0 ]]; then
        echo "❌ $field_name must be positive: $value" >&2
        return 1
    fi

    return 0
}

# Validate integer range
validate_integer_range() {
    local value="$1"
    local min="$2"
    local max="$3"
    local field_name="${4:-Number}"

    if ! validate_integer "$value" "$field_name"; then
        return 1
    fi

    if [[ $value -lt $min ]] || [[ $value -gt $max ]]; then
        echo "❌ $field_name out of range: $value (must be $min-$max)" >&2
        return 1
    fi

    return 0
}

# ============================================================================
# Example Usage
# ============================================================================

# Uncomment to test:
# validate_ticket_id "WORK-123" && echo "✓ Valid"
# validate_ticket_id "invalid" && echo "✓ Valid" || echo "✗ Invalid"
# sanitize_markdown "Hello [World]()" && echo "Done"
# create_safe_markdown_link "My Link" "https://example.com"
