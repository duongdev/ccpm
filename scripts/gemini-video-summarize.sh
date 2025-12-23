#!/bin/bash
# Summarize video demo for Linear issue
# Usage: ./scripts/gemini-video-summarize.sh <video-path> [model]

VIDEO="$1"
MODEL="${2:-gemini-2.5-flash}"

if [ -z "$VIDEO" ]; then
    echo "Usage: $0 <video-path> [model]"
    echo ""
    echo "Summarizes a video demo with structured output for Linear comments."
    echo ""
    echo "Models: gemini-2.5-flash (default), gemini-2.5-pro"
    echo ""
    echo "Example:"
    echo "  $0 demo.mp4"
    echo "  $0 bug-reproduction.mov gemini-2.5-pro"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/gemini-multimodal.sh" "$VIDEO" video "Analyze this video and provide:

## Summary
Brief description of what's shown.

## Steps Demonstrated
1. [Step 1]
2. [Step 2]
...

## Key Observations
- [Observation 1]
- [Observation 2]

## Potential Issues/Notes
- [Any issues or notes]

Format as markdown suitable for posting as a Linear comment." "$MODEL"
