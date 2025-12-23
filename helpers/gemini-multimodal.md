# Gemini Multimodal Processing

## Overview
Process video, audio, and document attachments from Linear issues using Gemini's multimodal capabilities.

## Prerequisites
- Gemini CLI: `pip install google-generativeai`
- API key: `export GEMINI_API_KEY="your-key"`

## Supported Formats

| Type | Formats | Max Duration/Size |
|------|---------|-------------------|
| Video | MP4, MOV, WebM | 6 hours |
| Audio | WAV, MP3, AAC, FLAC | 9.5 hours |
| Documents | PDF | 1000 pages |
| Images | PNG, JPG, WebP, GIF | 3600px |

## Processing Patterns

### Video Demo Analysis
```bash
# Summarize user flow in video
gemini -y -m gemini-2.5-flash --video demo.mp4 "Summarize the user flow demonstrated in this video. List each step the user takes."

# Extract bug reproduction steps
gemini -y -m gemini-2.5-flash --video bug-report.mp4 "List the exact steps to reproduce this bug based on the video."

# Generate test cases from demo
gemini -y -m gemini-2.5-flash --video feature-demo.mp4 "Generate test cases based on the functionality shown in this video."
```

### Audio Transcription
```bash
# Transcribe meeting recording
gemini -y -m gemini-2.5-flash --audio meeting.mp3 "Transcribe this audio and list action items discussed."

# Extract requirements from voice memo
gemini -y -m gemini-2.5-flash --audio requirements.wav "Extract all technical requirements mentioned in this recording."

# Summarize with timestamps
gemini -y -m gemini-2.5-flash --audio podcast.mp3 "Summarize the key points with timestamps."
```

### Document Processing
```bash
# Extract spec requirements
gemini -y -m gemini-2.5-flash --pdf spec.pdf "Extract all functional requirements from this specification document."

# Summarize large documentation
gemini -y -m gemini-2.5-flash --pdf documentation.pdf "Summarize the main sections and key concepts."

# Extract tables and data
gemini -y -m gemini-2.5-flash --pdf report.pdf "Extract all tables and format as markdown."
```

## Integration with Linear Workflow

### Processing Attachments from Linear Issue

1. **Fetch issue with attachments**:
   ```bash
   # Get attachment URLs from Linear issue
   # (via ccpm:linear-operations agent)
   ```

2. **Download attachment**:
   ```bash
   curl -o attachment.mp4 "<attachment-url>"
   ```

3. **Process with Gemini**:
   ```bash
   ./scripts/gemini-multimodal.sh attachment.mp4 video "Summarize the demo"
   ```

4. **Add summary to Linear comment**:
   ```bash
   # (via ccpm:linear-operations agent)
   ```

### Use Cases by Linear Issue Type

| Issue Type | Attachment | Gemini Task |
|------------|------------|-------------|
| Bug Report | Video | Extract reproduction steps |
| Feature Request | Audio | Transcribe requirements |
| Spec Review | PDF | Summarize key points |
| Design Task | Video | Document interactions |
| Meeting Follow-up | Audio | Extract action items |

## Batch Processing

For issues with multiple attachments:

```bash
# Process all videos in directory
for video in attachments/*.mp4; do
    echo "Processing: $video"
    ./scripts/gemini-multimodal.sh "$video" video "Summarize this content"
    echo "---"
done
```

## Output Formatting

Request structured output for easier processing:

```bash
# JSON output for programmatic use
gemini -y -m gemini-2.5-flash --video demo.mp4 "List user actions as JSON array: [{action, timestamp, details}]"

# Markdown for Linear comments
gemini -y -m gemini-2.5-flash --audio meeting.mp3 "Format as markdown with ## sections for Topics, Decisions, Action Items"
```

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| File too large | >2GB | Compress or split file |
| Unsupported format | Wrong codec | Convert to supported format |
| Rate limit | Too many requests | Add delay between calls |
| Context overflow | Very long content | Ask specific questions |

## Best Practices

1. **Be specific** - Ask targeted questions, not "analyze this"
2. **Use Flash model** - Faster and cheaper for most tasks
3. **Cache results** - Store summaries in Linear comments
4. **Compress first** - Reduce file size before processing
5. **Request structured output** - JSON/Markdown for easier parsing

## Integration with CCPM Commands

### `/ccpm:plan` Integration

When planning issues with video/audio attachments:

```bash
# 1. Detect attachments (via helpers/image-analysis.md pattern)
# 2. Download video/audio files
# 3. Process with Gemini
./scripts/gemini-video-summarize.sh demo.mp4
# 4. Add summary to Linear issue description
```

### `/ccpm:work` Integration

When working on issues with multimodal context:

```bash
# 1. Load issue with ccpm:linear-operations
# 2. Download attachments
# 3. Process with Gemini for context
./scripts/gemini-multimodal.sh spec.pdf pdf "Extract technical requirements"
# 4. Provide context to implementation agents
```

### Recommended Script Wrappers

Create specialized scripts for common CCPM workflows:

- `scripts/gemini-video-summarize.sh` - Summarize video demos
- `scripts/gemini-audio-transcribe.sh` - Transcribe meetings with action items
- `scripts/gemini-pdf-requirements.sh` - Extract requirements from specs

## Performance Considerations

| Content Type | Processing Time | Cost (Flash) |
|--------------|----------------|--------------|
| 5min video | 30-60s | ~$0.01 |
| 30min audio | 1-2min | ~$0.05 |
| 100-page PDF | 20-40s | ~$0.10 |
| Image | 2-5s | <$0.01 |

Use Flash model for most tasks. Pro model only for complex reasoning.

## Security Considerations

1. **Sensitive content** - Review before sending to external API
2. **Rate limits** - Implement delays for batch processing
3. **API keys** - Use environment variables, never commit keys
4. **File cleanup** - Delete downloaded attachments after processing

## Example: Full Video Processing Workflow

```bash
# 1. Get Linear issue with video attachment
Task(subagent_type="ccpm:linear-operations"): `
operation: get_issue
params:
  issueId: WORK-123
context:
  cache: false
  include_attachments: true
`

# 2. Download video attachment
curl -o /tmp/demo.mp4 "<attachment-url>"

# 3. Process with Gemini
./scripts/gemini-video-summarize.sh /tmp/demo.mp4

# 4. Post summary to Linear
Task(subagent_type="ccpm:linear-operations"): `
operation: create_comment
params:
  issueId: WORK-123
  body: |
    ## Video Summary (Gemini Analysis)

    [Paste Gemini output here]
context:
  cache: false
`

# 5. Cleanup
rm /tmp/demo.mp4
```

## Troubleshooting

### Gemini CLI not found
```bash
pip install google-generativeai
# or
pip3 install google-generativeai
```

### API key issues
```bash
# Get key at: https://aistudio.google.com/apikey
export GEMINI_API_KEY="your-key-here"

# Persist in shell profile
echo 'export GEMINI_API_KEY="your-key"' >> ~/.zshrc
source ~/.zshrc
```

### File format errors
```bash
# Convert video to MP4
ffmpeg -i input.avi -c:v libx264 output.mp4

# Convert audio to MP3
ffmpeg -i input.wav -codec:a libmp3lame output.mp3

# Compress large files
ffmpeg -i large.mp4 -vcodec h264 -acodec mp2 compressed.mp4
```

### Rate limiting
```bash
# Add delays between requests
for file in *.mp4; do
    ./scripts/gemini-multimodal.sh "$file" video "Summarize"
    sleep 5  # Wait 5 seconds between files
done
```

## Future Enhancements

1. **Automatic attachment detection** - Scan Linear issues for videos/audio
2. **Batch processing command** - `/ccpm:gemini-process <issue-id>`
3. **Summary caching** - Store processed results to avoid re-processing
4. **Progress tracking** - Show processing status for long videos
5. **Multi-language support** - Transcribe and translate audio content
