#!/bin/bash
# Transcribe audio with action items
# Usage: ./scripts/gemini-audio-transcribe.sh <audio-path> [model]

AUDIO="$1"
MODEL="${2:-gemini-2.5-flash}"

if [ -z "$AUDIO" ]; then
    echo "Usage: $0 <audio-path> [model]"
    echo ""
    echo "Transcribes audio and extracts action items for Linear comments."
    echo ""
    echo "Models: gemini-2.5-flash (default), gemini-2.5-pro"
    echo ""
    echo "Example:"
    echo "  $0 meeting.mp3"
    echo "  $0 requirements-discussion.wav gemini-2.5-pro"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/gemini-multimodal.sh" "$AUDIO" audio "Transcribe this audio and provide:

## Summary
Brief summary of the discussion.

## Key Points
- [Point 1]
- [Point 2]

## Action Items
- [ ] [Action 1] - @assignee
- [ ] [Action 2] - @assignee

## Decisions Made
- [Decision 1]

Format as markdown suitable for posting as a Linear comment." "$MODEL"
