#!/bin/bash
# CCPM Gemini Multimodal Processor
# Usage: ./scripts/gemini-multimodal.sh <file-path> <type> "<prompt>" [model]

set -e

FILE_PATH="$1"
FILE_TYPE="$2"  # video, audio, pdf, image
PROMPT="$3"
MODEL="${4:-gemini-2.5-flash}"

if [ -z "$FILE_PATH" ] || [ -z "$FILE_TYPE" ] || [ -z "$PROMPT" ]; then
    echo "Usage: $0 <file-path> <type> \"<prompt>\" [model]"
    echo ""
    echo "Types: video, audio, pdf, image"
    echo "Models: gemini-2.5-flash (default), gemini-2.5-pro"
    echo ""
    echo "Examples:"
    echo "  $0 demo.mp4 video \"Summarize the user flow\""
    echo "  $0 meeting.mp3 audio \"Extract action items\""
    echo "  $0 spec.pdf pdf \"List requirements\" gemini-2.5-pro"
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH"
    exit 1
fi

# Check gemini CLI
if ! command -v gemini &> /dev/null; then
    echo "Error: Gemini CLI not found"
    echo "Install: pip install google-generativeai"
    echo ""
    echo "After installing, set your API key:"
    echo "  export GEMINI_API_KEY=\"your-key\""
    echo "  Get key at: https://aistudio.google.com/apikey"
    exit 1
fi

# Check API key
if [ -z "$GEMINI_API_KEY" ]; then
    echo "Error: GEMINI_API_KEY not set"
    echo ""
    echo "Get your API key at: https://aistudio.google.com/apikey"
    echo "Then set it:"
    echo "  export GEMINI_API_KEY=\"your-key\""
    echo ""
    echo "To persist across sessions, add to your shell profile:"
    echo "  echo 'export GEMINI_API_KEY=\"your-key\"' >> ~/.zshrc"
    exit 1
fi

# Get file size for info
FILE_SIZE=$(du -h "$FILE_PATH" | cut -f1)
echo "Processing $FILE_TYPE file: $FILE_PATH ($FILE_SIZE)"

# Determine the correct flag based on file type
case "$FILE_TYPE" in
    "video")
        FLAG="--video"
        ;;
    "audio")
        FLAG="--audio"
        ;;
    "pdf")
        FLAG="--pdf"
        ;;
    "image")
        FLAG="--image"
        ;;
    *)
        echo "Error: Unknown type '$FILE_TYPE'. Use: video, audio, pdf, image"
        exit 1
        ;;
esac

# Execute Gemini processing
echo "Analyzing with Gemini $MODEL..."
echo "---"
gemini -y -m "$MODEL" $FLAG "$FILE_PATH" "$PROMPT"
