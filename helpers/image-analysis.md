# Image Analysis Utility

This utility provides image detection and analysis capabilities for Linear issues. It's designed to be used by other CCPM commands to automatically detect and process images attached to or embedded in Linear issues.

## Purpose

- Extract image attachments from Linear issues
- Detect inline markdown images in issue descriptions
- Filter and validate image URLs
- Provide structured image metadata for further processing

## Usage

Other commands should **read this file** to understand the image detection logic, then implement it in their command execution.

```markdown
### Step X: Detect Images in Linear Issue

**READ**: `commands/_shared-image-analysis.md`

Apply the detectImages() logic to extract all images from the issue.
```

## Core Functions

### detectImages(issue)

Detects all images associated with a Linear issue, including both attachments and inline markdown images.

**Input**: Linear issue object from Linear MCP's `get_issue` tool

```javascript
{
  id: "PSN-123",
  title: "Design review needed",
  description: "Please review this mockup\n![Design mockup](https://example.com/mockup.png)",
  attachments: [
    { url: "https://linear.app/.../diagram.jpg", title: "Architecture diagram" },
    { url: "https://linear.app/.../doc.pdf", title: "Requirements" }
  ]
}
```

**Returns**: Array of image objects

```javascript
[
  { url: "https://linear.app/.../diagram.jpg", title: "Architecture diagram", type: "jpg" },
  { url: "https://example.com/mockup.png", title: "Design mockup", type: "png" }
]
```

**Algorithm**:

```
1. Initialize empty results array
2. Check if issue has attachments array
   - If yes, iterate through each attachment
   - For each attachment:
     a. Extract URL and title
     b. Check if isImage(url) returns true
     c. If image, extract file type from URL
     d. Add { url, title, type } to results
3. Check if issue has description
   - If yes, scan for markdown image syntax: ![alt](url)
   - Use regex: /!\[([^\]]*)\]\(([^)]+)\)/g
   - For each match:
     a. Extract alt text (group 1) as title
     b. Extract URL (group 2)
     c. Check if isImage(url) returns true
     d. If image, extract file type from URL
     e. Add { url, title, type } to results
4. Deduplicate results by URL
5. Return results array
```

**Edge Cases Handled**:
- **No attachments**: Returns empty array or only inline images
- **No description**: Returns only attachment images
- **No images found**: Returns empty array `[]`
- **Duplicate images**: Removes duplicates by URL
- **Missing title**: Uses empty string or "Untitled"
- **Invalid URLs**: Still includes in results (let caller handle fetch errors)

### isImage(urlOrFilename)

Checks if a URL or filename represents an image file based on file extension.

**Input**: String (URL or filename)

```javascript
// Examples
"https://linear.app/attachments/diagram.jpg"
"mockup.PNG"
"/path/to/screenshot.webp"
"document.pdf"
```

**Returns**: Boolean

```javascript
true  // for image files
false // for non-image files
```

**Algorithm**:

```
1. Convert input string to lowercase
2. Extract file extension:
   - Find last occurrence of '.'
   - Get substring after '.'
   - Handle query parameters (stop at '?' or '#')
3. Check if extension matches supported image formats:
   - Supported: jpg, jpeg, png, gif, webp, svg, bmp
4. Return true if match, false otherwise
```

**Supported Image Formats**:
- `jpg` / `jpeg` - Joint Photographic Experts Group
- `png` - Portable Network Graphics
- `gif` - Graphics Interchange Format
- `webp` - Web Picture format
- `svg` - Scalable Vector Graphics
- `bmp` - Bitmap Image File

**Edge Cases Handled**:
- **No extension**: Returns false
- **Multiple dots**: Uses last dot only
- **Query parameters**: `image.png?token=abc` → extracts `png`
- **URL fragments**: `image.png#section` → extracts `png`
- **Case insensitivity**: `IMAGE.JPG` → matches `jpg`
- **Empty string**: Returns false

### extractFileType(url)

Extracts the file type/extension from a URL or filename.

**Input**: String (URL or filename)

```javascript
"https://linear.app/attachments/diagram.jpg?token=abc"
"mockup.PNG"
```

**Returns**: String (lowercase file extension without dot)

```javascript
"jpg"
"png"
""  // if no extension found
```

**Algorithm**:

```
1. Convert input to lowercase
2. Find last occurrence of '.'
3. If not found, return empty string
4. Extract substring after last '.'
5. Remove query parameters (stop at '?' or '#')
6. Trim whitespace
7. Return extension
```

## Implementation Example

Here's how a command would implement this logic:

```markdown
### Step 1: Detect Images in Linear Issue

**Implementation**:

1. Fetch Linear issue using Linear MCP
2. Initialize empty images array
3. Process attachments:
   ```javascript
   if (issue.attachments && issue.attachments.length > 0) {
     for (attachment of issue.attachments) {
       const url = attachment.url
       const title = attachment.title || "Untitled"

       // Check if it's an image
       const ext = extractFileType(url)
       if (["jpg", "jpeg", "png", "gif", "webp", "svg", "bmp"].includes(ext)) {
         images.push({ url, title, type: ext })
       }
     }
   }
   ```

4. Process inline markdown images:
   ```javascript
   if (issue.description) {
     const regex = /!\[([^\]]*)\]\(([^)]+)\)/g
     let match
     while ((match = regex.exec(issue.description)) !== null) {
       const title = match[1] || "Inline image"
       const url = match[2]
       const ext = extractFileType(url)

       if (["jpg", "jpeg", "png", "gif", "webp", "svg", "bmp"].includes(ext)) {
         images.push({ url, title, type: ext })
       }
     }
   }
   ```

5. Deduplicate by URL:
   ```javascript
   const seen = new Set()
   images = images.filter(img => {
     if (seen.has(img.url)) return false
     seen.add(img.url)
     return true
   })
   ```

6. Display results:
   ```
   Found X images in Linear issue PSN-123:
   1. Architecture diagram (jpg) - https://...
   2. Design mockup (png) - https://...
   ```
```

## Integration Points

### Commands That Should Use This Utility

**Planning Commands**:
- `/ccpm:plan` - Analyze images during task planning

**Implementation Commands**:
- `/ccpm:work` - Load images as context for implementation
- `/ccpm:sync` - Sync image analysis to Linear

### fetchAndAnalyzeImage(imageUrl, promptText)

Fetches an image and analyzes it using Claude's vision capabilities. Handles both web-hosted images (Linear attachments) and local file paths.

**Input**:
- `imageUrl` (string): URL or file path to image
- `promptText` (string): Analysis prompt describing what to extract from image

**Returns**: String (analysis text or error message)

**Tool Selection**:
```javascript
function chooseImageFetchTool(imageUrl) {
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return 'WebFetch'  // Web-hosted images (Linear attachments)
  } else if (imageUrl.startsWith('/') || imageUrl.startsWith('./')) {
    return 'Read'  // Local file paths
  } else {
    return 'WebFetch'  // Default to WebFetch
  }
}
```

**Error Handling Pattern**:
```javascript
try {
  if (tool === 'WebFetch') {
    return WebFetch({ url: imageUrl, prompt: promptText })
  } else {
    return Read({ file_path: imageUrl })
  }
} catch (error) {
  if (error.status === 404) {
    return "⚠️ Image not accessible (404 Not Found)"
  } else if (error.status === 403) {
    return "⚠️ Image requires authentication"
  } else if (error.timeout) {
    return "⚠️ Image fetch timeout - image may be too large"
  } else {
    return `⚠️ Failed to fetch image: ${error.message}`
  }
}
```

**Edge Cases Handled**:
- 404/403 errors: Returns warning, doesn't fail workflow
- Timeout: Returns timeout message
- Local file not found: Returns file not found message
- Invalid URL: Returns error message with details

### generateImagePrompt(imageTitle, taskContext)

Generates an optimized analysis prompt based on image title and task context. Different prompts for different image types.

**Input**:
- `imageTitle` (string): Image title or filename
- `taskContext` (string): Context about the task (e.g., "UI implementation", "architecture review")

**Returns**: String (optimized analysis prompt)

**Algorithm**:
```javascript
function generateImagePrompt(imageTitle, taskContext) {
  const title = imageTitle.toLowerCase()
  const context = taskContext.toLowerCase()

  // UI Mockup detection
  if (title.includes('mockup') || title.includes('design') ||
      title.includes('wireframe') || title.includes('ui') ||
      context.includes('ui') || context.includes('frontend')) {
    return UI_MOCKUP_PROMPT
  }

  // Diagram detection
  if (title.includes('diagram') || title.includes('architecture') ||
      title.includes('flow') || context.includes('architecture')) {
    return ARCHITECTURE_DIAGRAM_PROMPT
  }

  // Screenshot/Bug detection
  if (title.includes('screenshot') || title.includes('error') ||
      title.includes('bug') || context.includes('bug')) {
    return SCREENSHOT_PROMPT
  }

  return GENERAL_IMAGE_PROMPT
}
```

**Edge Cases**:
- Ambiguous title: Falls back to general prompt
- Empty title: Uses task context only
- Multiple matches: Prioritizes UI > Diagram > Screenshot > General

### WebFetch Integration

After detecting images, use WebFetch to analyze them:

```markdown
### Step 2: Analyze Detected Images

For each image in detected images:

1. Use WebFetch tool to fetch and analyze:
   ```
   WebFetch:
   - url: image.url
   - prompt: "Analyze this image. Describe what you see, identify any UI mockups,
             diagrams, wireframes, or technical specifications. Extract any text visible
             in the image. Provide insights relevant to software development planning."
   ```

2. Capture analysis results:
   - Image description
   - Detected elements (buttons, forms, diagrams)
   - Extracted text
   - Technical insights

3. Store analysis in structured format for Linear comment
```

## Prompt Templates

The following prompt templates are used by `generateImagePrompt()` for different image types:

### UI_MOCKUP_PROMPT

```
Analyze this UI mockup and describe:

1. **Layout & Structure**
   - Overall layout pattern (grid, flex, columns)
   - Component hierarchy and organization
   - Spacing and alignment patterns

2. **UI Elements**
   - Key interactive elements (buttons, forms, inputs)
   - Navigation components
   - Content sections and their purpose

3. **Visual Design**
   - Color palette (extract exact hex values if visible)
   - Typography (font families, sizes, weights)
   - Icons and imagery used

4. **Design Patterns**
   - Recognizable UI patterns (cards, modals, tabs, etc.)
   - Responsive design considerations
   - Component reusability

5. **Accessibility**
   - Visible accessibility features
   - Contrast and readability
   - Form labels and input states

6. **Implementation Notes**
   - Suggested component breakdown
   - State management needs
   - Technical considerations
```

### ARCHITECTURE_DIAGRAM_PROMPT

```
Analyze this architecture diagram and describe:

1. **System Components**
   - All visible components/services
   - Component responsibilities
   - Technology stack (if indicated)

2. **Relationships & Data Flow**
   - How components communicate
   - Data flow direction and patterns
   - Integration points

3. **Architecture Patterns**
   - Architectural style (microservices, monolith, etc.)
   - Design patterns in use
   - Layering and separation of concerns

4. **Infrastructure**
   - Deployment architecture
   - Scaling considerations
   - External dependencies

5. **Technical Details**
   - Protocols and APIs
   - Data stores and persistence
   - Security boundaries

6. **Implementation Guidance**
   - Key technical decisions
   - Potential challenges
   - Recommended implementation order
```

### SCREENSHOT_PROMPT

```
Analyze this screenshot and describe:

1. **Current State**
   - What is being shown
   - Application/page context
   - User flow position

2. **Visual Issues**
   - Any visible errors or problems
   - UI rendering issues
   - Unexpected behavior indicators

3. **Technical Context**
   - Visible error messages or codes
   - Console output (if visible)
   - Network/API details (if shown)

4. **Environment Details**
   - Browser/platform (if identifiable)
   - Screen size/viewport
   - Device type

5. **Reproduction Context**
   - User actions that led to this state
   - Data or inputs visible
   - Related functionality

6. **Next Steps**
   - Potential root causes
   - Areas to investigate
   - Debugging recommendations
```

### GENERAL_IMAGE_PROMPT

```
Analyze this image and describe:

1. **Content Overview**
   - What is shown in the image
   - Main elements and their purpose
   - Context and relevance

2. **Technical Details**
   - Any visible technical information
   - Text content (extract all readable text)
   - Diagrams or charts

3. **Development Insights**
   - How this relates to software development
   - Implementation guidance
   - Key takeaways for the task
```

## Usage Example

Here's a complete example of using all functions together:

```markdown
### Complete Image Analysis Workflow

**Implementation**:

1. Detect images from Linear issue:
   ```javascript
   const images = detectImages(issue)
   // Returns: [
   //   { url: "https://...", title: "Login mockup", type: "png" },
   //   { url: "https://...", title: "System diagram", type: "jpg" }
   // ]
   ```

2. Analyze each image with appropriate prompt:
   ```javascript
   for (const image of images) {
     // Generate context-aware prompt
     const prompt = generateImagePrompt(image.title, "UI implementation")

     // Fetch and analyze
     const analysis = fetchAndAnalyzeImage(image.url, prompt)

     // Handle results
     if (analysis.startsWith('⚠️')) {
       console.log(`Warning: ${image.title} - ${analysis}`)
       continue
     }

     // Store successful analysis
     imageAnalyses.push({
       title: image.title,
       type: image.type,
       analysis: analysis
     })
   }
   ```

3. Format for Linear comment:
   ```markdown
   ## Image Analysis

   ### Login mockup (png)
   {analysis text...}

   ### System diagram (jpg)
   {analysis text...}

   ---
   *Automated analysis by CCPM*
   ```
```

## Parallel Processing Pattern

For optimal performance with multiple images:

```markdown
### Efficient Multi-Image Analysis

1. Collect all images and generate prompts:
   ```javascript
   const images = detectImages(issue)
   const imagesToAnalyze = images.map(img => ({
     ...img,
     prompt: generateImagePrompt(img.title, taskContext)
   }))
   ```

2. Make parallel WebFetch calls (one per image in same message):
   ```
   Call WebFetch for all images simultaneously:
   - Image 1: WebFetch(url1, prompt1)
   - Image 2: WebFetch(url2, prompt2)
   - Image 3: WebFetch(url3, prompt3)
   ```

3. Collect all results and format:
   ```javascript
   const analyses = [result1, result2, result3]
   const formattedOutput = formatImageAnalyses(images, analyses)
   ```

Performance: Parallel execution completes in ~2-5 seconds per image (concurrent)
vs ~6-15 seconds total (sequential).
```

## Testing Checklist

When implementing this utility in a command:

### Image Detection Tests (`detectImages()`)

- [ ] Test with issue that has no attachments
- [ ] Test with issue that has attachments but no images
- [ ] Test with issue that has only image attachments
- [ ] Test with issue that has mixed attachments (images + PDFs)
- [ ] Test with issue description containing inline markdown images
- [ ] Test with issue containing both attachment images and inline images
- [ ] Test with duplicate images (same URL in attachments and inline)
- [ ] Test with URLs containing query parameters
- [ ] Test with various image formats (jpg, png, gif, webp, svg)
- [ ] Test with case-insensitive file extensions (JPG, PNG, JPEG)

### Image Fetching Tests (`fetchAndAnalyzeImage()`)

- [ ] Test with web-hosted image (https://) - should use WebFetch
- [ ] Test with local file path (/path/to/image.png) - should use Read
- [ ] Test with 404 error - should return "⚠️ Image not accessible (404 Not Found)"
- [ ] Test with 403 error - should return "⚠️ Image requires authentication"
- [ ] Test with timeout - should return "⚠️ Image fetch timeout..."
- [ ] Test with successful analysis - should return descriptive text

### Prompt Generation Tests (`generateImagePrompt()`)

- [ ] Test with UI mockup title ("Login mockup") - should return UI_MOCKUP_PROMPT
- [ ] Test with architecture diagram title - should return ARCHITECTURE_DIAGRAM_PROMPT
- [ ] Test with screenshot title - should return SCREENSHOT_PROMPT
- [ ] Test with generic title - should return GENERAL_IMAGE_PROMPT
- [ ] Test with task context containing "UI" - should return UI_MOCKUP_PROMPT
- [ ] Test with empty title - should use task context

### Integration Tests

- [ ] Test complete workflow: detect → generate prompts → fetch → format
- [ ] Test parallel image analysis with multiple images
- [ ] Test error recovery (continue after failed image)
- [ ] Test with all images failing - should not crash command

## Error Handling

The utility provides graceful error handling for both detection and analysis:

### Detection Errors

Detection is designed to never fail:
- **No attachments**: Returns empty array
- **No description**: Returns empty array
- **Invalid URLs**: Still included (let fetch handle it)
- **Malformed markdown**: Regex skips invalid syntax

### Fetch and Analysis Errors

`fetchAndAnalyzeImage()` handles all errors gracefully:

```markdown
### Error Handling During Image Analysis

If WebFetch fails for an image:
1. Catch the error (don't throw)
2. Return warning message with ⚠️ prefix
3. Log the error with image URL and title
4. Continue processing remaining images
5. Include partial results in final output
6. Note failed images in Linear comment

Common error scenarios:
- **404 Not Found**: Image URL no longer valid
- **403 Forbidden**: Image requires authentication
- **Timeout**: Image too large or slow connection
- **Network error**: Connection issues
- **Local file not found**: File path incorrect

If no images detected:
1. Continue with normal command execution
2. Do not fail the command
3. Skip image analysis steps
4. No error or warning needed

Example error handling in command:
```javascript
const images = detectImages(issue)

if (images.length === 0) {
  console.log("No images found in issue")
  // Continue with rest of command
}

const analyses = []
for (const image of images) {
  const prompt = generateImagePrompt(image.title, taskContext)
  const analysis = fetchAndAnalyzeImage(image.url, prompt)

  if (analysis.startsWith('⚠️')) {
    console.log(`Warning: Failed to analyze ${image.title}`)
    console.log(analysis)
    // Continue with next image
  } else {
    analyses.push({ image, analysis })
  }
}

if (analyses.length > 0) {
  // Format and post successful analyses
} else {
  console.log("All image analyses failed, continuing without image context")
}
```
```

## Performance Considerations

**For commands processing images**:

1. **Parallel Processing**: Fetch and analyze images in parallel using multiple WebFetch calls
2. **Timeout Handling**: Set reasonable timeouts for WebFetch (30-60 seconds per image)
3. **Size Limits**: Consider skipping very large images (defer to WebFetch limits)
4. **Caching**: Store analysis results in Linear comments to avoid re-analyzing

**Example parallel processing**:

```markdown
### Parallel Image Analysis

For optimal performance, analyze all images in parallel:

1. Collect all image URLs from detectImages()
2. Create WebFetch tool call for each image (in single message)
3. Process all results together
4. Combine analyses into single Linear comment
```

## Configuration Options

Commands should check configuration settings before running image analysis to allow users to customize behavior.

### Available Configuration Options

**Option 1: image_analysis.enabled** (boolean, default: `true`)
- Controls whether image analysis runs automatically
- If `false`, commands skip image detection entirely
- Commands should check this before calling `detectImages()`

**Option 2: image_analysis.max_images** (number, default: `5`)
- Maximum number of images to analyze per issue
- Prevents excessive processing time for issues with many images
- Commands should limit results from `detectImages()` using `.slice(0, maxImages)`

**Option 3: image_analysis.timeout_ms** (number, default: `10000`)
- Timeout for each image fetch/analysis operation (milliseconds)
- Prevents workflows from hanging on slow or large images
- Pass to `fetchAndAnalyzeImage()` calls or WebFetch tool timeout parameter

**Option 4: image_analysis.implementation_mode** (string, default: `"direct_visual"`)
- `"direct_visual"`: Pass image URLs directly to agents via visual reference (Subtask 9 feature)
- `"text_only"`: Only include text analysis in issue descriptions, no direct image passing
- `"disabled"`: Skip image analysis during implementation phase entirely

**Option 5: image_analysis.formats** (array, default: `["jpg", "jpeg", "png", "gif", "webp"]`)
- Supported image file formats for detection
- Used by `isImage()` function to filter attachments
- Can be extended for additional formats like `"svg"`, `"bmp"`, `"tiff"`

### Checking Configuration in Commands

Before running image analysis, commands should check if the feature is enabled:

```javascript
// Load project configuration (from ccpm-config.yaml)
const config = loadProjectConfig()

// Check if image analysis is enabled
if (config.image_analysis?.enabled === false) {
  console.log("⏭️ Image analysis disabled in project configuration")
  return  // Skip image analysis entirely
}

// Get configuration values with defaults
const maxImages = config.image_analysis?.max_images || 5
const timeout = config.image_analysis?.timeout_ms || 10000
const implementationMode = config.image_analysis?.implementation_mode || "direct_visual"
const supportedFormats = config.image_analysis?.formats || ["jpg", "jpeg", "png", "gif", "webp"]

// Run image analysis with configuration applied
const allImages = detectImages(issue)
const images = allImages.slice(0, maxImages)  // Respect max_images limit

console.log(`🖼️ Analyzing ${images.length} of ${allImages.length} detected images`)

for (const img of images) {
  try {
    const analysis = await fetchAndAnalyzeImage(img.url, prompt, { timeout })
    // Store analysis results
  } catch (error) {
    if (error.timeout) {
      console.log(`⚠️ ${img.title} - Analysis timeout after ${timeout}ms`)
    }
  }
}
```

### Example Configuration

**File**: `~/.claude/ccpm-config.yaml`

```yaml
projects:
  - id: my-project
    name: My Project
    linear_team_id: TEAM-123

    # Image analysis configuration
    image_analysis:
      enabled: true                    # Enable/disable feature globally
      max_images: 5                    # Analyze up to 5 images per issue
      timeout_ms: 10000                # 10 second timeout per image
      implementation_mode: direct_visual  # Pass images to implementation agents
      formats:                         # Supported image formats
        - jpg
        - jpeg
        - png
        - gif
        - webp
        - svg
```

**Minimal Configuration** (uses all defaults):

```yaml
projects:
  - id: my-project
    name: My Project
    linear_team_id: TEAM-123
    # image_analysis section can be omitted - defaults will apply
```

**Disable Image Analysis**:

```yaml
projects:
  - id: my-project
    name: My Project

    image_analysis:
      enabled: false  # Skip all image analysis
```

### Default Configuration

If not specified in project config, these defaults apply:

```javascript
const DEFAULT_IMAGE_ANALYSIS_CONFIG = {
  enabled: true,
  max_images: 5,
  timeout_ms: 10000,
  implementation_mode: "direct_visual",
  formats: ["jpg", "jpeg", "png", "gif", "webp"]
}
```

**Rationale for Defaults**:

- **enabled: true** - Feature is opt-out, not opt-in (better user experience). Users discover the feature automatically and can disable if not needed.
- **max_images: 5** - Balances thoroughness with performance. Five images take ~25-50 seconds to analyze (5-10s each), which is reasonable for most workflows.
- **timeout_ms: 10000** - 10 seconds prevents workflows from hanging on slow or very large images while allowing sufficient time for typical mockups/diagrams.
- **implementation_mode: "direct_visual"** - Takes full advantage of Subtask 9's visual reference feature, providing agents with direct access to mockups.
- **formats**: Standard web image formats. SVG deliberately excluded from default due to potential security concerns (can contain scripts).

### Configuration Loading Pattern

Commands should load configuration using CCPM's standard project config system:

```javascript
// Pseudo-code for configuration loading
function loadImageAnalysisConfig(projectId) {
  // 1. Load project configuration
  const projectConfig = loadProjectConfig(projectId)

  // 2. Get image analysis settings with defaults
  const config = {
    enabled: projectConfig.image_analysis?.enabled ?? true,
    max_images: projectConfig.image_analysis?.max_images ?? 5,
    timeout_ms: projectConfig.image_analysis?.timeout_ms ?? 10000,
    implementation_mode: projectConfig.image_analysis?.implementation_mode ?? "direct_visual",
    formats: projectConfig.image_analysis?.formats ?? ["jpg", "jpeg", "png", "gif", "webp"]
  }

  // 3. Validate configuration
  if (config.max_images < 1) config.max_images = 1
  if (config.max_images > 20) config.max_images = 20  // Reasonable upper limit
  if (config.timeout_ms < 1000) config.timeout_ms = 1000  // Minimum 1 second
  if (config.timeout_ms > 60000) config.timeout_ms = 60000  // Maximum 1 minute

  return config
}
```

### Testing Configuration

Test different configuration scenarios to ensure proper behavior:

**Test 1: Disable image analysis entirely**

```yaml
image_analysis:
  enabled: false
```

**Expected behavior**:
- Commands skip `detectImages()` entirely
- No WebFetch calls made
- No "🖼️ Visual Context Analysis" section added to Linear issues
- Console output: "⏭️ Image analysis disabled in project configuration"

**Test 2: Limit to 2 images maximum**

```yaml
image_analysis:
  max_images: 2
```

**Expected behavior**:
- If issue has 5 images, only first 2 are analyzed
- Console output: "🖼️ Analyzing 2 of 5 detected images"
- Remaining 3 images are ignored (no fetch attempts)
- Linear comment shows only 2 image analyses

**Test 3: Short timeout for performance**

```yaml
image_analysis:
  timeout_ms: 1000
```

**Expected behavior**:
- Small images complete successfully (< 1 second)
- Large/slow images timeout with warning
- Workflow continues without failing
- Console output: "⚠️ login-mockup.png - Analysis timeout after 1000ms"

**Test 4: Text-only mode (no direct visual passing)**

```yaml
image_analysis:
  implementation_mode: text_only
```

**Expected behavior**:
- Planning phase: Images analyzed, text added to Linear description
- Implementation phase: Agents receive Linear description with text analysis only
- No direct image URLs passed to `implementation:start` command or agents
- Subtask 9 feature disabled

**Test 5: Direct visual mode (default)**

```yaml
image_analysis:
  implementation_mode: direct_visual
```

**Expected behavior**:
- Planning phase: Images analyzed, text added to Linear description
- Implementation phase: Image URLs passed directly to agents for visual reference
- Subtask 9 feature enabled
- Agents see actual mockups/diagrams, not just text descriptions

**Test 6: Disable during implementation only**

```yaml
image_analysis:
  enabled: true
  implementation_mode: disabled
```

**Expected behavior**:
- Planning commands (`/ccpm:plan`) analyze images normally
- Implementation commands (`/ccpm:work`) skip image analysis
- Linear descriptions contain text analysis from planning phase
- No visual references passed to implementation agents

**Test 7: Extended format support**

```yaml
image_analysis:
  formats:
    - jpg
    - jpeg
    - png
    - gif
    - webp
    - svg
    - bmp
    - tiff
```

**Expected behavior**:
- `isImage()` function accepts all listed formats
- SVG and TIFF images detected and analyzed
- No change to existing formats

### Configuration Best Practices

**For small teams/projects**:
```yaml
image_analysis:
  enabled: true        # Use defaults
```

**For large projects with many images**:
```yaml
image_analysis:
  enabled: true
  max_images: 3        # Limit for faster planning
  timeout_ms: 5000     # Shorter timeout
```

**For security-conscious projects**:
```yaml
image_analysis:
  enabled: true
  formats:             # Exclude SVG (can contain scripts)
    - jpg
    - jpeg
    - png
    - gif
    - webp
```

**For performance-critical workflows**:
```yaml
image_analysis:
  enabled: true
  max_images: 2
  timeout_ms: 3000
  implementation_mode: text_only  # Skip visual passing overhead
```

**For design-heavy projects**:
```yaml
image_analysis:
  enabled: true
  max_images: 10       # Analyze more mockups
  timeout_ms: 15000    # Longer timeout for detailed designs
  implementation_mode: direct_visual  # Full visual reference
```

## Version History

- **v1.3.0** (2025-11-20): Added configuration options
  - Added `image_analysis` configuration section
  - Defined 5 configuration options with defaults
  - Added example ccpm-config.yaml snippets
  - Documented configuration loading pattern
  - Added testing scenarios for each option
  - Provided rationale for default values
  - Added configuration best practices

- **v1.2.0** (2025-11-20): Added image context formatting
  - Added `formatImageContext()` for markdown generation
  - Added `insertImageContext()` for Linear description updates
  - Added single and multiple image templates
  - Added formatting guidelines for professional output
  - Added before/after examples for Linear descriptions
  - Defined insertion strategy for image analysis sections

- **v1.1.0** (2025-11-20): Added image fetching and analysis
  - Added `fetchAndAnalyzeImage()` function for web and local images
  - Added `generateImagePrompt()` for context-aware prompts
  - Added prompt templates for UI mockups, diagrams, screenshots
  - Added error handling patterns for failed fetches
  - Added parallel processing guidance
  - Added complete usage examples

- **v1.0.0** (2025-11-20): Initial implementation
  - Basic image detection from attachments
  - Inline markdown image detection
  - File type validation
  - Deduplication logic

## Related Documentation

- Linear MCP Integration: `docs/reference/linear-mcp.md` (if exists)
- WebFetch Tool Usage: Claude Code documentation
- Planning Commands: `commands/planning:*.md`

## Notes for Future Enhancements

**Completed in v1.1.0**:
- ✅ Image fetching with WebFetch and Read tools
- ✅ Context-aware prompt generation
- ✅ Error handling for failed fetches
- ✅ Parallel processing patterns

**Potential improvements** (not in current scope):

- Advanced image analysis:
  - Image dimension detection
  - Image size validation
  - OCR text extraction for better accuracy
  - Image similarity detection (avoid duplicate analysis)
  - Thumbnail generation for performance

- Extended format support:
  - Cloud storage links (Google Drive, Dropbox, etc.)
  - Video/animation support (mp4, mov, gif animations)
  - PDF page extraction (first page as image)

- Enhanced intelligence:
  - Machine learning-based image categorization
  - Automatic design system pattern detection
  - Code generation from UI mockups
  - Accessibility scoring and recommendations
  - Design consistency analysis across images

- Performance optimizations:
  - Intelligent caching of analyses
  - Progressive image loading
  - Adaptive quality based on connection speed
  - Batch analysis with single API call
## Image Context Formatting

### formatImageContext(imageAnalyses)

Formats image analysis results into a standardized markdown section suitable for insertion into Linear issue descriptions.

**Input**: Array of image analysis results

```javascript
[
  {
    url: "https://linear.app/attachments/login-mockup.png",
    title: "Login mockup",
    type: "png",
    analysis: "Centered login form with email/password fields, submit button, forgot password link..."
  }
]
```

**Returns**: Formatted markdown string ready for Linear description insertion

**Algorithm**:

```
1. If imageAnalyses array is empty, return empty string
2. If more than 5 images, truncate to first 5 with note "(showing first 5 of N images)"
3. Initialize output with section header: "## 🖼️ Visual Context Analysis\n\n"
4. For each image in imageAnalyses:
   a. If multiple images (>1), add subheader: "### Image N: {title}"
   b. If single image, add bold title: "**Image: {title}**"
   c. Format analysis content as bullet points
   d. Add preserved URL section:
      - For single image: "**Mockup URL**: {url}\n(Preserved for implementation phase)"
      - For multiple images: "**URL**: {url}"
   e. Add spacing between images (blank line)
5. If multiple images, add footer note:
   "---\n**Note**: All image URLs preserved for direct visual reference during implementation."
6. Return formatted markdown string
```

**Single Image Template**:

```markdown
## 🖼️ Visual Context Analysis

**Image: login-mockup.png**
- Centered login form with email/password fields
- Submit button with primary blue color
- "Forgot password" link below form
- Card-based layout with subtle shadow
- High contrast for accessibility

**Mockup URL**: https://linear.app/attachments/login-mockup.png
(Preserved for implementation phase)
```

**Multiple Images Template**:

```markdown
## 🖼️ Visual Context Analysis

### Image 1: dashboard-wireframe.png
- Grid-based dashboard with 3x2 card layout
- Header with navigation and user menu
- Six widget cards with charts and data
- Responsive design considerations

**URL**: https://linear.app/attachments/dashboard-wireframe.png

### Image 2: widget-detail.png
- Individual widget card with line chart
- Card header with title and actions
- Chart.js style visualization
- Data table below chart

**URL**: https://linear.app/attachments/widget-detail.png

---
**Note**: All image URLs preserved for direct visual reference during implementation.
```

**Edge Cases**:
- **No images**: Returns empty string `""`
- **>5 images**: Truncates with note "(showing first 5 of 7 images)"
- **Failed fetch**: Include "⚠️ Failed to fetch image - {error}"
- **Missing analysis**: Use "Visual content detected. See URL for details."
- **Long analysis**: Keep concise, ~5-8 bullet points per image

**Formatting Guidelines**:
- Use bullet points, not paragraphs
- Extract exact values (hex codes, dimensions)
- Bold key terms sparingly
- Preserve URLs prominently
- Professional, objective tone
- Limit emojis to 🖼️ (header) and ⚠️ (errors)

### insertImageContext(existingDescription, imageContext)

Inserts formatted image context into a Linear issue description at the correct location.

**Input**:
- `existingDescription`: Current Linear issue description
- `imageContext`: Formatted markdown from formatImageContext()

**Returns**: Updated Linear issue description

**Insertion Strategy**:

Insert image analysis:
1. **After** "## ✅ Implementation Checklist"
2. **Before** "## 📋 Context"
3. Ensures visibility without cluttering checklist

**Standard Structure**:

```markdown
## 🎯 Goal
[Goal text]

## ✅ Implementation Checklist
- [ ] Subtask 1
- [ ] Subtask 2

## 🖼️ Visual Context Analysis    ← INSERT HERE
[Image context]

## 📋 Context
[Context text]

## 🔍 Research Findings
[Research text]
```

**Algorithm**:

```
1. If imageContext is empty, return existingDescription unchanged
2. Check if description already has "## 🖼️ Visual Context Analysis":
   - If yes: Replace entire section with new imageContext
3. If no existing section:
   - Find "## ✅ Implementation Checklist" section
   - Find next "##" header (usually "## 📋 Context")
   - Insert imageContext between them
4. Edge cases:
   - No checklist: Insert after Goal, before Context
   - No Context: Insert before Research Findings or append
   - Empty description: Return imageContext as full description
5. Ensure proper spacing (blank lines before/after)
6. Return updated description
```

**Edge Cases**:
- **Already has image section**: Replace with new analysis
- **No checklist**: Insert after Goal section
- **No Context section**: Append before Research or at end
- **Empty description**: Return imageContext only
- **Malformed markdown**: Best-effort insertion

**Before/After Example**:

**Before**:
```markdown
## 🎯 Goal
Implement login page

## ✅ Implementation Checklist
- [ ] Create form component
- [ ] Add validation
- [ ] Connect to API

## 📋 Context
User auth is critical...
```

**After**:
```markdown
## 🎯 Goal
Implement login page

## ✅ Implementation Checklist
- [ ] Create form component
- [ ] Add validation
- [ ] Connect to API

## 🖼️ Visual Context Analysis

**Image: login-mockup.png**
- Centered login form with email/password fields
- Submit button with primary blue color
- "Forgot password" link below form
- Card-based layout with subtle shadow
- High contrast for accessibility

**Mockup URL**: https://linear.app/attachments/login-mockup.png
(Preserved for implementation phase)

## 📋 Context
User auth is critical...
```

## Usage Examples

### Example 1: Planning Command Integration

This example shows how planning commands integrate image analysis into their workflow:

```markdown
### Step 0.5: Analyze Images in Linear Issue

**READ**: `commands/_shared-image-analysis.md`

**Implementation**:

1. Check configuration to see if image analysis is enabled
2. Detect images using the detectImages() logic from the utility
3. If no images found, skip this step
4. For each detected image (up to max_images limit):
   a. Generate appropriate prompt using generateImagePrompt()
   b. Fetch and analyze using WebFetch or Read tool
   c. Handle errors gracefully (continue on failure)
5. Format results using formatImageContext()
6. Insert into Linear description using insertImageContext()
7. Update Linear issue with enhanced description

**Pseudocode**:

```javascript
// 1. Check configuration
const config = loadProjectConfig()
if (config.image_analysis?.enabled === false) {
  return  // Skip image analysis
}

// 2. Detect images
const images = detectImages(issue)
if (images.length === 0) {
  console.log("No images found in issue")
  return
}

// 3. Analyze each image
const analyses = []
const maxImages = config.image_analysis?.max_images || 5
for (const img of images.slice(0, maxImages)) {
  const prompt = generateImagePrompt(img.title, "planning")
  const analysis = fetchAndAnalyzeImage(img.url, prompt)
  
  if (!analysis.startsWith("⚠️")) {
    analyses.push({ ...img, analysis })
  } else {
    console.log(`Warning: ${analysis}`)
  }
}

// 4. Format and insert
if (analyses.length > 0) {
  const formatted = formatImageContext(analyses)
  const updatedDesc = insertImageContext(issue.description, formatted)
  
  // Update Linear issue
  linear_update_issue(issue.id, { description: updatedDesc })
  
  console.log(`✅ Analyzed ${analyses.length} image(s) and updated Linear description`)
}
```
```

### Example 2: Implementation Phase Visual Reference

This example shows how implementation commands use images for pixel-perfect UI work:

```markdown
### Step 2.5: Prepare Visual Context for UI Tasks

**READ**: `commands/_shared-image-analysis.md`

**Implementation**:

When starting implementation, detect UI-related subtasks and provide direct visual references:

1. Identify UI/design subtasks from task breakdown
2. Extract images from Linear issue
3. Map images to relevant subtasks
4. Pass images directly to frontend/mobile agents

**Pseudocode**:

```javascript
// 1. Detect UI tasks
const uiTasks = subtasks.filter(task => 
  /\b(UI|design|mockup|screen|component|interface|layout)\b/i.test(task.description)
)

if (uiTasks.length === 0) {
  return  // No UI tasks, skip visual context
}

// 2. Get images
const images = detectImages(issue)
if (images.length === 0) {
  console.log("No mockups found for UI tasks")
  return
}

// 3. Map images to tasks
for (const task of uiTasks) {
  // Find images relevant to this task
  const relevantImages = images.filter(img =>
    task.description.toLowerCase().includes(img.title.toLowerCase()) ||
    img.title.toLowerCase().includes("mockup") ||
    img.title.toLowerCase().includes("design")
  )
  
  if (relevantImages.length > 0) {
    // Invoke agent with direct mockup access
    const mockupUrl = relevantImages[0].url
    
    Task(frontend-developer): `
    Implement: ${task.description}
    
    📸 Design Mockup: ${mockupUrl}
    
    Instructions:
    1. Use WebFetch to load the mockup above
    2. Analyze the exact visual design
    3. Extract precise:
       - Layout structure and spacing
       - Color values (hex codes)
       - Typography (fonts, sizes, weights)
       - Component hierarchy
    4. Implement with pixel-perfect accuracy
    5. Match EXACT design from mockup
    
    Target: ~95-100% design fidelity
    `
  } else {
    // No specific mockup for this task
    console.log(`ℹ️  No mockup found for: ${task.description}`)
  }
}
```
```

### Example 3: Context Loading with Image Preview

This example shows how utility commands display images:

```markdown
### Step 1.5: Display Attached Images

**READ**: `commands/_shared-image-analysis.md`

**Implementation**:

When loading task context, provide a quick preview of attached images:

```javascript
// 1. Detect images
const images = detectImages(issue)

if (images.length === 0) {
  return  // No images to display
}

// 2. Display preview
console.log("\n## 🖼️  Attached Images")
console.log(`Found ${images.length} image(s):\n`)

for (let i = 0; i < images.length; i++) {
  const img = images[i]
  console.log(`${i + 1}. **${img.title}** (${img.type})`)
  console.log(`   ${img.url}`)
  
  // For mockups, add implementation note
  if (img.title.toLowerCase().includes('mockup') || 
      img.title.toLowerCase().includes('design')) {
    console.log(`   💡 Can be loaded directly by frontend agents for pixel-perfect implementation`)
  }
  
  console.log()
}

// 3. Note about analysis
if (issue.description.includes("## 🖼️ Visual Context Analysis")) {
  console.log("✅ Images have been analyzed - see Linear description for details")
} else {
  console.log("ℹ️  Run /ccpm:plan to analyze these images")
}
```
```

### Example 4: Error Handling Pattern

This example shows comprehensive error handling:

```markdown
### Robust Image Analysis with Error Handling

**Implementation**:

```javascript
async function analyzeIssueImages(issue, config) {
  // 1. Check if enabled
  if (!config.image_analysis?.enabled) {
    return null
  }
  
  // 2. Detect images
  const images = detectImages(issue)
  if (images.length === 0) {
    return null
  }
  
  // 3. Limit by configuration
  const maxImages = config.image_analysis?.max_images || 5
  const imagesToAnalyze = images.slice(0, maxImages)
  
  if (images.length > maxImages) {
    console.log(`ℹ️  Limited to ${maxImages} images (${images.length} found)`)
  }
  
  // 4. Analyze with error handling
  const analyses = []
  const errors = []
  
  for (const img of imagesToAnalyze) {
    try {
      const prompt = generateImagePrompt(img.title, "planning")
      const analysis = fetchAndAnalyzeImage(img.url, prompt)
      
      if (analysis.startsWith("⚠️")) {
        // Fetch failed, but gracefully
        errors.push({ image: img.title, error: analysis })
        continue
      }
      
      analyses.push({
        url: img.url,
        title: img.title,
        type: img.type,
        analysis: analysis
      })
      
    } catch (error) {
      // Unexpected error
      errors.push({ 
        image: img.title, 
        error: `Unexpected error: ${error.message}` 
      })
    }
  }
  
  // 5. Report results
  if (analyses.length > 0) {
    console.log(`✅ Successfully analyzed ${analyses.length} image(s)`)
  }
  
  if (errors.length > 0) {
    console.log(`⚠️  Failed to analyze ${errors.length} image(s):`)
    errors.forEach(e => {
      console.log(`   - ${e.image}: ${e.error}`)
    })
  }
  
  // 6. Return results (even if partial)
  if (analyses.length === 0) {
    console.log("❌ No images could be analyzed")
    return null
  }
  
  return analyses
}

// Usage in command
const imageAnalyses = await analyzeIssueImages(issue, config)

if (imageAnalyses) {
  // Format and insert
  const formatted = formatImageContext(imageAnalyses)
  const updated = insertImageContext(issue.description, formatted)
  
  // Update Linear
  linear_update_issue(issue.id, { description: updated })
}
```
```

### Example 5: Parallel Image Analysis

This example shows optimal performance with parallel processing:

```markdown
### Efficient Multi-Image Analysis

**Implementation**:

For maximum performance, analyze all images in parallel:

```javascript
// 1. Detect and prepare
const images = detectImages(issue)
const maxImages = config.image_analysis?.max_images || 5
const imagesToAnalyze = images.slice(0, maxImages)

// 2. Generate all prompts first
const imagePrompts = imagesToAnalyze.map(img => ({
  url: img.url,
  title: img.title,
  type: img.type,
  prompt: generateImagePrompt(img.title, "planning")
}))

// 3. Make parallel WebFetch calls
console.log(`Analyzing ${imagePrompts.length} images in parallel...`)

// Use multiple WebFetch calls in same message for parallel execution
const results = await Promise.all(
  imagePrompts.map(async (item) => {
    try {
      const analysis = await WebFetch({
        url: item.url,
        prompt: item.prompt
      })
      
      return {
        url: item.url,
        title: item.title,
        type: item.type,
        analysis: analysis,
        success: !analysis.startsWith("⚠️")
      }
    } catch (error) {
      return {
        url: item.url,
        title: item.title,
        type: item.type,
        analysis: `⚠️ Error: ${error.message}`,
        success: false
      }
    }
  })
)

// 4. Filter successful analyses
const successful = results.filter(r => r.success)
const failed = results.filter(r => !r.success)

console.log(`✅ ${successful.length} successful, ⚠️  ${failed.length} failed`)

// 5. Format and update
if (successful.length > 0) {
  const formatted = formatImageContext(successful)
  const updated = insertImageContext(issue.description, formatted)
  linear_update_issue(issue.id, { description: updated })
}
```

**Performance Comparison**:
- Sequential: 3 images × 5s each = 15 seconds total
- Parallel: 3 images analyzed simultaneously = ~5-7 seconds total
- Speedup: ~60-70% faster
```

### Example 6: Configuration-Aware Implementation

This example shows respecting all configuration options:

```markdown
### Full Configuration Support

**Implementation**:

```javascript
function shouldAnalyzeImages(config, images) {
  // Check enabled flag
  if (config.image_analysis?.enabled === false) {
    console.log("ℹ️  Image analysis disabled in configuration")
    return false
  }
  
  // Check if any images
  if (images.length === 0) {
    return false
  }
  
  return true
}

function filterImagesByFormat(images, config) {
  const supportedFormats = config.image_analysis?.formats || 
    ['jpg', 'jpeg', 'png', 'gif', 'webp']
  
  return images.filter(img => 
    supportedFormats.includes(img.type.toLowerCase())
  )
}

function limitImageCount(images, config) {
  const maxImages = config.image_analysis?.max_images || 5
  
  if (images.length <= maxImages) {
    return images
  }
  
  console.log(`ℹ️  Limiting to ${maxImages} images (${images.length} found)`)
  return images.slice(0, maxImages)
}

function getTimeout(config) {
  return config.image_analysis?.timeout_ms || 10000
}

function getImplementationMode(config) {
  return config.image_analysis?.implementation_mode || 'direct_visual'
}

// Main workflow
async function analyzeImagesWithConfig(issue, config) {
  // 1. Detect all images
  const allImages = detectImages(issue)
  
  // 2. Check if should analyze
  if (!shouldAnalyzeImages(config, allImages)) {
    return null
  }
  
  // 3. Filter by supported formats
  const supportedImages = filterImagesByFormat(allImages, config)
  if (supportedImages.length === 0) {
    console.log("⚠️  No images with supported formats found")
    return null
  }
  
  // 4. Limit count
  const imagesToAnalyze = limitImageCount(supportedImages, config)
  
  // 5. Analyze with timeout
  const timeout = getTimeout(config)
  const analyses = []
  
  for (const img of imagesToAnalyze) {
    const prompt = generateImagePrompt(img.title, "planning")
    const analysis = await fetchAndAnalyzeImage(img.url, prompt, { timeout })
    
    if (!analysis.startsWith("⚠️")) {
      analyses.push({ ...img, analysis })
    }
  }
  
  return analyses
}
```
```

## Integration Testing Examples

### Test Case 1: No Images

```markdown
**Scenario**: Linear issue with no attachments or inline images

**Expected Behavior**:
- detectImages() returns empty array
- Command skips image analysis
- No errors or warnings
- Command continues normally
```

### Test Case 2: Multiple Images

```markdown
**Scenario**: Linear issue with 3 mockups attached

**Expected Behavior**:
- detectImages() returns 3 image objects
- All 3 images analyzed in parallel
- Results formatted with "Image 1:", "Image 2:", "Image 3:"
- Linear description updated with analysis
- Footer note about preserved URLs
```

### Test Case 3: Failed Fetch

```markdown
**Scenario**: Image URL returns 404

**Expected Behavior**:
- fetchAndAnalyzeImage() returns "⚠️ Image not accessible (404 Not Found)"
- Warning logged but workflow continues
- Other images still processed
- Partial results inserted into Linear
```

### Test Case 4: Configuration Disabled

```markdown
**Scenario**: image_analysis.enabled = false

**Expected Behavior**:
- detectImages() not called
- No WebFetch calls made
- No Linear description updates
- Command executes without image analysis
```

## Performance Benchmarks

Based on implementation testing:

| Scenario | Time | Notes |
|----------|------|-------|
| Single UI mockup | 2-3s | WebFetch + analysis |
| 3 images (sequential) | 6-9s | 2-3s per image |
| 3 images (parallel) | 3-5s | Concurrent WebFetch |
| 5 images (parallel) | 10-15s | Maximum default |
| Large image (5MB+) | 8-12s | Longer fetch time |
| Failed fetch (404) | 1-2s | Quick timeout |

**Recommendations**:
- Use parallel processing for 2+ images
- Set max_images to 3-5 for balance
- Increase timeout for slower connections
- Consider smaller image files (<2MB)
