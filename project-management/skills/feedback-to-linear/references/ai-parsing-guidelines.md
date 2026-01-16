# AI Parsing Guidelines for Feedback to Linear

This document provides detailed guidelines for parsing raw user feedback into structured Linear issue data.

## Overview

The parsing process extracts six key components from each feedback item:
1. Title
2. Description
3. Labels
4. Priority
5. Acceptance Criteria
6. Estimate

## 1. Title Extraction

### Rules
- **Format**: Imperative mood (e.g., "Fix crash on upload", not "The app crashes")
- **Length**: Maximum 80 characters
- **Specificity**: Include key details from feedback (device, size, action, context)
- **Clarity**: Should stand alone without reading description
- **Actionable**: Start with verb when possible

### Specificity Guidelines

**AVOID generic titles:**
- ❌ "Fix bug"
- ❌ "Add feature"
- ❌ "Improve performance"
- ❌ "Fix crash"

**INCLUDE relevant context from feedback:**
- ✅ "Fix crash when uploading large images on iPhone 14"
- ✅ "Add dark mode toggle in settings"
- ✅ "Improve image loading performance on slow connections"
- ✅ "Fix crash on login with SSO accounts"

### Context Extraction

Extract and include these details when present in feedback:
- **Device/Platform**: iPhone 14, Android 12, Chrome
- **Size/Scale**: large images, bulk operations, many items
- **Action/Trigger**: when uploading, on login, during save
- **Condition**: on slow connections, with SSO, when offline
- **Location**: in settings, on dashboard, in checkout

### Examples

| Raw Feedback | Generic (❌) | Specific (✅) |
|--------------|-------------|---------------|
| "The app crashes when I try to upload large images on my iPhone 14" | Fix crash on upload | Fix crash when uploading large images on iPhone 14 |
| "Would love to see dark mode support in the settings" | Add dark mode | Add dark mode toggle in settings |
| "Loading times are really slow on mobile when there are many items" | Improve loading | Improve loading times with many items on mobile |
| "Can't find the settings button, looked everywhere" | Fix settings | Make settings button more discoverable |

### Platform Prefix Convention

When a specific platform is selected during input collection:
- Prefix the title with `[Platform]`
- Specifics still go after the prefix

| Platform | Feedback | Final Title |
|----------|----------|-------------|
| iOS | "Crash when uploading large images" | [iOS] Fix crash when uploading large images |
| Android | "Need dark mode in settings" | [Android] Add dark mode toggle in settings |
| Web | "Slow loading with many items" | [Web] Improve loading with many items |
| Backend/API | "Query timeout on large datasets" | [Backend] Fix query timeout on large datasets |
| Multiple/All | "Auth fails sometimes" | Fix intermittent authentication failures (no prefix) |

### Edge Cases
- **Vague feedback**: "This is broken" → "Fix reported issue [?]" (LOW confidence, flagged)
- **Multiple issues in one**: Split into separate feedback items first
- **Feature requests without verbs**: Add appropriate verb (Add, Support, Enable, etc.)
- **Missing specifics**: Use what's available, mark as MEDIUM confidence if thin

---

## 2. Description Generation

### Structure
```markdown
[Original user feedback, quoted or paraphrased]

## Context
[Any inferred or explicit context]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

### Rules
- Preserve user's original wording when quoting feedback
- Add "Reported by: [source]" if source is known
- Include any environmental details mentioned (device, OS, version)
- Format code snippets with proper markdown
- Add links if URLs were mentioned

### Example
**Input:** "App crashes when uploading images over 10MB on iPhone 14"

**Output:**
```markdown
User reported: "App crashes when uploading images over 10MB on iPhone 14"

## Context
- Device: iPhone 14
- Issue occurs specifically with large images (>10MB)
- Crash happens during upload process

**Complexity Estimate:** M (Medium)

## Acceptance Criteria
- [ ] Large images (>10MB) upload without crashing
- [ ] User receives clear feedback during upload
- [ ] Error handling prevents app crash
- [ ] Tested on iPhone 14 and similar devices
```

---

## 3. Label Semantic Matching

### Process
1. Receive list of available labels from Linear team
2. Analyze feedback using compound signal detection
3. Consider label descriptions (if available), not just names
4. Apply domain-aware matching based on repo context
5. Apply labels with >70% confidence match
6. Support multiple labels per issue (max 3-4)

### Compound Signal Detection

Instead of matching single keywords, detect compound patterns that indicate issue type with higher confidence.

#### Bug Compound Signals
**Strong signals (HIGH confidence):**
- "keeps crashing when [action]" → Bug
- "doesn't work anymore" → Bug (regression)
- "getting error [message]" → Bug
- "broken since [update/version]" → Bug
- "[feature] stopped working" → Bug

**Moderate signals (MEDIUM confidence):**
- "doesn't work" → Bug
- "not working properly" → Bug
- "something's wrong with" → Bug

**Examples:**
| Feedback | Label | Confidence |
|----------|-------|------------|
| "App keeps crashing when I upload photos" | Bug | HIGH |
| "Login doesn't work" | Bug | MEDIUM |
| "Getting 'network error' on save" | Bug | HIGH |

#### Feature Compound Signals
**Strong signals (HIGH confidence):**
- "would be great if we could [action]" → Feature
- "can you add [capability]" → Feature
- "need a way to [action]" → Feature
- "support for [thing]" → Feature
- "it would help if [capability]" → Feature

**Moderate signals (MEDIUM confidence):**
- "would love [thing]" → Feature
- "wish there was" → Feature
- "any plans to add" → Feature

**Examples:**
| Feedback | Label | Confidence |
|----------|-------|------------|
| "Would be great if we could export to PDF" | Feature | HIGH |
| "Would love dark mode" | Feature | MEDIUM |
| "Need a way to bulk delete items" | Feature | HIGH |

#### Improvement Compound Signals
**Strong signals (HIGH confidence):**
- "[action] is really slow / takes forever" → Performance
- "hard to find / can't find [thing]" → UX
- "confusing how to [action]" → UX
- "should be easier to [action]" → UX/Improvement
- "[thing] could be better" → Improvement

**Moderate signals (MEDIUM confidence):**
- "slow" (standalone) → Performance
- "improve [thing]" → Improvement
- "better [thing]" → Improvement

**Examples:**
| Feedback | Label | Confidence |
|----------|-------|------------|
| "Saving takes forever, especially with large files" | Performance | HIGH |
| "Hard to find the export button" | UX | HIGH |
| "Loading is slow" | Performance | MEDIUM |

### Domain-Aware Matching

Prioritize labels based on detected repo context:

| Repo Type | Prioritize Labels |
|-----------|-------------------|
| iOS app (`*.xcodeproj`, `ios/`) | iOS, Mobile, Swift |
| Android app (`android/`, `build.gradle`) | Android, Mobile, Kotlin |
| Web app (`package.json` + react/vue) | Web, Frontend |
| Backend (`Cargo.toml`, `go.mod`, API in name) | Backend, API, Server |

**Usage:**
- If repo is iOS and feedback mentions generic "mobile" → apply iOS label
- If repo is backend and feedback mentions "endpoint" → apply API/Backend label
- Cross-reference repo context with feedback content

### Platform Detection
**Keywords:** iOS, iPhone, iPad, Android, mobile, web, desktop, backend, API, server

**Match to labels like:** iOS, Android, Mobile, Web, Backend, API

**Example:**
- Feedback: "Crash on iPhone 14" → Labels: "Bug", "iOS"

### Domain-Specific Labels
Look for mentions of specific features or modules:
- "login", "auth", "signup", "password" → "Authentication"
- "payment", "checkout", "billing", "subscription" → "Payments"
- "notification", "push", "alert" → "Notifications"
- "profile", "account", "settings" → "Account"
- "search", "filter", "sort" → "Search"

### Multi-Label Strategy
Apply multiple labels when appropriate:
- Type label (Bug/Feature/Improvement) + Platform label (iOS/Android)
- Type label + Domain label (Bug + Authentication)
- Maximum 3-4 labels per issue for clarity

### No Match Handling
If no label achieves >70% confidence:
- Leave labels empty
- User can add manually during edit (if LOW confidence triggers prompt)
- Compound signal not found = safer to leave empty than guess

---

## 4. Priority Inference

### Priority Scale
- **1**: Urgent
- **2**: High
- **3**: Medium (default)
- **4**: Low

**Note:** Priority 0 (None) is avoided. Most feedback deserves attention, so default to 3 (Medium) rather than 0.

### Multi-Signal Detection

Priority is determined by combining multiple signals, not just keywords. Start at 3 (Medium) and adjust based on signals:

| Signal Type | +1 Priority (more urgent) | -1 Priority (less urgent) |
|-------------|---------------------------|---------------------------|
| **User Impact** | "many users", "everyone", "all users", "team can't" | "sometimes", "rarely", "edge case", "just me" |
| **Business** | "can't use app", "blocking work", "revenue", "deadline" | "cosmetic", "minor", "nice to have", "eventually" |
| **Severity** | crash, data loss, security, corruption | typo, color, alignment, spacing |
| **Tone** | ALL CAPS, multiple !!!, frustrated language | casual suggestion, "when you get a chance" |

### Detection Rules

#### Priority 1 (Urgent)
**Compound signals required** (not just single keywords):
- Crash + many users: "App crashes for everyone on login"
- Security issue: "Password visible in plain text"
- Data loss: "Lost all my saved data"
- Complete blocker: "Can't use the app at all"

**Confidence:** Only assign Priority 1 with HIGH confidence signals

**Examples:**
- "APP CRASHES IMMEDIATELY ON LAUNCH!!!" → P1 (crash + caps + urgency)
- "Everyone on the team can't access their accounts" → P1 (many users + blocker)

#### Priority 2 (High)
**Signals:**
- Blocking core functionality: "Login doesn't work"
- Explicit urgency: "Need this ASAP", "blocking our launch"
- Many users but not complete failure: "Lots of users reporting slow loads"

**Examples:**
- "Login doesn't work for new users - blocking onboarding" → P2
- "API returns 500 errors intermittently" → P2

#### Priority 3 (Medium) - DEFAULT
**Signals:**
- Standard bug reports without urgency modifiers
- Feature requests with clear value
- Improvements to existing functionality
- No strong urgency or triviality signals

**Examples:**
- "Would be nice to have better error messages" → P3
- "Add dark mode support" → P3
- "Upload sometimes fails on large files" → P3

#### Priority 4 (Low)
**Signals:**
- Explicit triviality: "minor", "small", "cosmetic", "polish"
- Non-functional: typos, colors, spacing, alignment
- Future/nice-to-have: "eventually", "when you get a chance", "no rush"

**Examples:**
- "Minor typo in the footer" → P4
- "Would be nice to have the button be slightly larger" → P4
- "No rush but could we change the icon color?" → P4

### Priority Confidence

| Confidence | When to apply |
|------------|---------------|
| HIGH | Multiple strong signals present, clear urgency/triviality |
| MEDIUM | Some signals, reasonable inference |
| LOW | Defaulted to 3, no clear signals either way |

---

## 5. Acceptance Criteria Generation

### Guidelines
- Generate 3-5 testable criteria per issue
- Use markdown checklist format: `- [ ] Criterion`
- Make criteria specific and measurable
- Cover functional requirements, edge cases, and UX

### Template by Issue Type

#### Bug Issues
```markdown
- [ ] Bug no longer reproduces in test environment
- [ ] Error handling prevents [specific failure mode]
- [ ] User receives clear feedback when [condition]
- [ ] Tested on [relevant platforms/devices]
- [ ] No regression in related functionality
```

#### Feature Issues
```markdown
- [ ] [Feature] works as described
- [ ] User can [specific action]
- [ ] Feature accessible from [location]
- [ ] Error states handled gracefully
- [ ] Documentation updated
```

#### Improvement Issues
```markdown
- [ ] [Metric] improved by [target amount]
- [ ] User experience validated with [method]
- [ ] No negative impact on [related feature]
- [ ] Performance benchmarks met
- [ ] Changes backward compatible
```

### Examples

**Feedback:** "App crashes when uploading large images"

**Description with AC:**
```markdown
User reported: "App crashes when uploading large images"

**Complexity Estimate:** M (Medium)

## Acceptance Criteria
- [ ] Users can upload images >10MB without crashes
- [ ] Progress indicator shows during upload
- [ ] Clear error message if upload fails
- [ ] Tested on iOS and Android with 50MB+ images
- [ ] Memory usage optimized for large files
```

**Feedback:** "Add dark mode"

**Description with AC:**
```markdown
User requested: "Add dark mode"

**Complexity Estimate:** L (Large)

## Acceptance Criteria
- [ ] Dark mode toggle available in settings
- [ ] All screens support dark mode
- [ ] Mode preference persists across sessions
- [ ] System theme preference respected
- [ ] No color contrast accessibility issues
```

---

## 6. Estimate Inference

**Note:** Estimates are appended to the issue description as a note (e.g., "**Complexity Estimate:** M (Medium)"). They are NOT passed to the Linear API as a parameter, since Linear uses project-specific point systems rather than T-shirt sizes.

### T-Shirt Sizes
- **XS**: Trivial change, <1 hour
- **S**: Small task, 1-4 hours
- **M**: Medium task, 1-2 days
- **L**: Large task, 3-5 days
- **XL**: Very large, 1+ weeks

### Detection Heuristics

#### Scope Keywords
- "typo", "text change", "color" → XS
- "button", "simple form", "single field" → S
- "page", "flow", "integration" → M
- "feature", "system", "architecture" → L
- "redesign", "migration", "platform" → XL

#### Bug Complexity
- Cosmetic bugs → XS/S
- Logic bugs with known cause → S/M
- Crashes or data corruption → M/L
- Systemic issues → L/XL

#### Feature Scope
- UI-only changes → S/M
- Backend + Frontend → M/L
- Third-party integrations → L
- Multi-platform → L/XL

### Examples

| Feedback | Estimate | Reasoning |
|----------|----------|-----------|
| "Fix typo in welcome message" | XS | Text change only |
| "Add logout button to settings" | S | Simple UI addition |
| "Implement password reset flow" | M | Multi-step user flow |
| "Add OAuth authentication" | L | Third-party integration |
| "Migrate to new database" | XL | Major architectural change |

### When Uncertain
Default to **M** (Medium) if complexity is unclear. User can adjust in preview.

---

## 7. Platform-Specific Handling

### Upfront Platform Context

The platform is collected at the start of the workflow via `AskUserQuestion`. This context:
- Determines title prefix convention (see section 1)
- Guides automatic label matching
- Filters relevant acceptance criteria templates
- Influences complexity estimates

### Platform Labels

When platform is selected:
- **iOS** → Auto-add "iOS" label if available in team labels
- **Android** → Auto-add "Android" label if available
- **Web** → Auto-add "Web" label if available
- **Backend/API** → Auto-add "Backend" or "API" label if available
- **Multiple/All platforms** → User manually selects applicable labels in preview

### Platform-Aware Acceptance Criteria Templates

Adjust acceptance criteria based on platform:

**iOS-specific:**
```markdown
- [ ] Tested on iOS 15+
- [ ] No memory leaks in Instruments
- [ ] Supports light and dark mode
- [ ] VoiceOver accessibility verified
```

**Android-specific:**
```markdown
- [ ] Tested on API 26+ (Android 8.0+)
- [ ] No ANRs (Application Not Responding)
- [ ] Material Design guidelines followed
- [ ] TalkBack accessibility verified
```

**Web-specific:**
```markdown
- [ ] Cross-browser tested (Chrome, Firefox, Safari, Edge)
- [ ] Responsive design verified (mobile, tablet, desktop)
- [ ] WCAG 2.1 AA accessibility standards met
- [ ] Lighthouse score acceptable
```

**Backend/API-specific:**
```markdown
- [ ] API documentation updated
- [ ] Rate limiting considered
- [ ] Error responses follow standard format
- [ ] Database migrations tested
- [ ] Performance impact measured
```

### Platform Context in Descriptions

Include platform details in the Context section:
```markdown
## Context
- Platform: iOS
- Device: iPhone 14
- Issue occurs specifically with large images (>10MB)
```

---

## Advanced Patterns

### Batch Splitting
Split feedback into multiple issues when:
- Multiple distinct problems mentioned
- Feature request with multiple components
- Bug report with separate reproducible cases

**Example:**
Input: "The app crashes on login AND the upload button is missing"

Split into:
1. "Fix crash on login" (Bug, High)
2. "Restore missing upload button" (Bug, High)

### Context Enrichment
Add inferred context from:
- Platform mentions → Add to description
- User role/persona → Add to description
- Related issues mentioned → Add links
- Screenshots or logs → Request in AC

### Confidence Scoring
For ambiguous cases, note confidence in description:
```markdown
[Note: Auto-parsed as Feature with Medium confidence - please verify]
```

---

## Example: Complete Parsing

**Raw Feedback:**
```
The app crashes every time I try to upload a video on my iPhone 14.
This is super urgent as I can't use the app at all!
```

**Parsed Issue:**

```yaml
Title: Fix crash when uploading videos on iPhone
Team: Mobile
Project: Bug Fixes
Labels: [Bug, iOS]
Priority: 1 (Urgent)

Description: |
  User reported: "The app crashes every time I try to upload a video on my iPhone 14. This is super urgent as I can't use the app at all!"

  ## Context
  - Device: iPhone 14
  - Issue: Consistent crash during video upload
  - Impact: User cannot use app (critical functionality blocked)

  **Complexity Estimate:** M (Medium)

  ## Acceptance Criteria
  - [ ] Video uploads work without crashes on iPhone 14
  - [ ] Tested with various video sizes and formats
  - [ ] Error handling prevents app crash if upload fails
  - [ ] User receives clear feedback during upload process
  - [ ] Memory management optimized for large video files
```

---

## Troubleshooting

### Low-Quality Feedback
When feedback is vague ("This is broken"):
- Extract what you can
- Add "[Needs clarification]" to title
- Generate AC that includes "Gather more details from reporter"

### Conflicting Signals
When feedback contains mixed signals:
- Prioritize explicit statements over tone
- Default to lower priority if ambiguous
- Note ambiguity in description

### Missing Information
When critical info is missing:
- Use sensible defaults
- Add AC item to gather missing info
- Flag in preview for user review

---

## 8. Media and Link Extraction

### URL Detection
Automatically extract http/https URLs from feedback text using regex pattern matching.

**URL Pattern Matching:**
- **Image files**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`
- **Video files**: `.mp4`, `.mov`, `.avi`, `.mkv`, `.webm`
- **Video platforms**: `.loom.com`, `.vimeo.com`, `.youtube.com`, `.youtu.be`
- **Screenshot services**: `d.pr`, `cloudapp`, `droplr`, `cl.ly`, `snagit.com`
- **Reference URLs**: docs, repos, related issues, any other http/https URLs

**Detection Process:**
1. Scan feedback text for http/https URL patterns
2. Categorize each URL by type (image, video, screenshot service, reference)
3. Extract surrounding context (up to 50 chars before/after) for title generation
4. Store with detected type and context

### Link Title Generation
Generate descriptive titles based on URL type and surrounding context.

**Title Templates by Type:**

| URL Type | Title Pattern | Examples |
|----------|--------------|----------|
| Screenshot service | "Screenshot showing [context]" | "Screenshot showing crash on login", "Screenshot of error message" |
| Image file | "Image: [filename or context]" | "Image: broken_ui.png", "Image of layout issue" |
| Video platform | "Video reproduction of [issue]" | "Video reproduction of upload bug", "Video: steps to reproduce" |
| Video file | "Video: [filename or context]" | "Video: crash_recording.mov" |
| Documentation | "Reference: [doc name]" | "Reference: Linear API docs", "Reference: authentication guide" |
| GitHub/Repo | "Reference: [repo/path]" | "Reference: repo/issue/123", "Reference: main/docs/api.md" |
| Generic/Other | "Attachment" or use URL filename | "Attachment", "screenshot-2024.png" |

**Context-Based Title Enhancement:**
- Extract keywords from surrounding text: "crash", "error", "bug", "issue", "broken"
- Combine with URL type for descriptive titles
- Example: "See https://d.pr/abc where app crashes" → "Screenshot showing crash"

### User-Provided URL Parsing
When user explicitly provides URLs in Phase 1 step 9:

**Input Formats Supported:**
```
# One per line
https://d.pr/abc123
https://loom.com/share/xyz: Video of bug
https://docs.example.com (API documentation)

# Comma-separated
https://d.pr/abc123, https://loom.com/share/xyz

# With titles (colon or parentheses)
https://example.com/image.png: Screenshot of issue
https://example.com/video.mov (Video reproduction)
```

**Parsing Rules:**
- Split on commas or newlines
- Extract title from:
  - Text after colon: `URL: Title`
  - Text in parentheses: `URL (Title)`
- If no title provided, generate based on URL type
- Trim whitespace from URLs and titles

### Link Deduplication
Merge auto-detected URLs with user-provided URLs:

**Deduplication Process:**
1. Normalize URLs (trim whitespace, lowercase)
2. Compare auto-detected vs user-provided
3. Remove duplicates (same URL)
4. For duplicates: preserve user-provided title over auto-generated
5. Maintain order: user-provided first, then auto-detected

**Example:**
```
Auto-detected: [{url: "https://d.pr/abc", title: "Screenshot"}]
User-provided: [{url: "https://d.pr/abc", title: "Crash screenshot"}]

Result: [{url: "https://d.pr/abc", title: "Crash screenshot"}]
```

### Auto-Detection Examples

**Example 1: Screenshot with context**
```
Input: "App crashes when I tap the button. See https://d.pr/abc123 for screenshot"

Extracted:
- url: https://d.pr/abc123
- title: "Screenshot showing button crash"
- type: screenshot_service
```

**Example 2: Video link**
```
Input: "Here's a loom showing the bug: https://loom.com/share/xyz789"

Extracted:
- url: https://loom.com/share/xyz789
- title: "Video reproduction of bug"
- type: video_platform
```

**Example 3: Multiple URLs**
```
Input: "Issue described in https://docs.example.com/auth. Also see https://github.com/repo/issues/42"

Extracted:
- url: https://docs.example.com/auth
  title: "Reference: auth documentation"
- url: https://github.com/repo/issues/42
  title: "Reference: repo/issues/42"
```

**Example 4: Image file**
```
Input: "UI looks broken, check /uploads/broken_layout.png"

Extracted:
- url: /uploads/broken_layout.png
- title: "Image: broken_layout.png"
- type: image_file
```

### Link Array Structure
Final output format for Linear API:

```javascript
[
  {
    url: "https://d.pr/abc123",
    title: "Screenshot showing crash on login"
  },
  {
    url: "https://loom.com/share/xyz",
    title: "Video reproduction of upload bug"
  },
  {
    url: "https://docs.example.com/api",
    title: "Reference: API documentation"
  }
]
```

### Edge Cases

**URLs within code blocks:**
- Skip URLs within ```code blocks``` or `inline code`
- Only extract from prose text

**Malformed URLs:**
- Attempt to fix common issues (missing http://, spaces)
- If unfixable, skip and note in description

**Duplicate detection case-sensitivity:**
- Compare URLs case-insensitively
- Preserve original URL casing in output

**Empty or missing titles:**
- Auto-generate based on URL type
- Fallback to "Attachment" or URL filename

---

## 9. Confidence Scoring

### Overview

Assign a confidence level (HIGH/MEDIUM/LOW) to each parsed field to indicate parsing quality and help users identify items needing review.

### Confidence Levels

| Field | HIGH | MEDIUM | LOW |
|-------|------|--------|-----|
| **Title** | Clear action verb + specific issue | Transformed from description | Very vague, generic |
| **Labels** | Exact keyword match | Semantic similarity | Weak inference |
| **Priority** | Explicit urgency keyword | Contextual signals | Defaulted to 0 |
| **Estimate** | N/A | Always MEDIUM (heuristic) | N/A |

### Detailed Criteria

#### Title Confidence

**HIGH Confidence:**
- Feedback contains clear action: "Fix crash on login"
- Imperative verb present: fix, add, improve, update
- Specific and unambiguous
- Example: "The login button is broken" → "Fix broken login button" (HIGH)

**MEDIUM Confidence:**
- Requires significant transformation
- Some ambiguity but main action is clear
- Example: "Users can't seem to log in sometimes" → "Fix intermittent login failures" (MEDIUM)

**LOW Confidence:**
- Very vague feedback: "This is broken", "Doesn't work"
- No clear action or subject
- Multiple possible interpretations
- Example: "The app isn't great" → "Improve app [?]" (LOW)
- Add `[?]` suffix to LOW confidence titles

#### Label Confidence

**HIGH Confidence:**
- Exact keyword match in feedback
- Example: Feedback contains "crash" → "Bug" label (HIGH)
- Example: Feedback contains "add dark mode" → "Feature" label (HIGH)

**MEDIUM Confidence:**
- Semantic similarity to label
- Inferred from context
- Example: "doesn't work properly" → "Bug" label (MEDIUM)
- Example: "would love to see" → "Feature" label (MEDIUM)

**LOW Confidence:**
- Weak or uncertain match
- No clear type indicators
- Example: "Make it better" → uncertain type (LOW)
- Consider leaving labels empty if <50% confident

#### Priority Confidence

**HIGH Confidence:**
- Multiple strong signals present
- Clear urgency compound patterns (crash + many users, security + data)
- Explicit urgency keywords with context
- Example: "URGENT: App crashes for everyone on login!" → Priority 1 (HIGH)

**MEDIUM Confidence:**
- Some signals present, reasonable inference
- Single strong signal or multiple weak signals
- Example: "Login not working for many users" → Priority 2 (MEDIUM)

**LOW Confidence:**
- No clear signals, defaulted to Priority 3
- Ambiguous feedback with no urgency or triviality indicators
- Example: "The settings could be better" → Priority 3 (LOW confidence)

#### Estimate Confidence

All estimates are **MEDIUM** confidence since they're heuristic-based rather than explicitly stated.

### Confidence Output Format

When parsing, store confidence for each field:

```json
{
  "title": "Fix crash when uploading images",
  "title_confidence": "HIGH",
  "labels": ["Bug", "iOS"],
  "labels_confidence": "HIGH",
  "priority": 1,
  "priority_confidence": "HIGH",
  "estimate": "M",
  "estimate_confidence": "MEDIUM"
}
```

### Preview Table Format

Display confidence in preview:

```
| Title                    | Labels      | Pri | Est | Confidence |
|--------------------------|-------------|-----|-----|------------|
| Fix crash on upload      | Bug, iOS    | 1   | M   | HIGH       |
| Improve settings [?]     | Enhancement | 0   | M   | LOW ⚠️     |
| Add dark mode            | Feature     | 2   | L   | HIGH       |
```

- Show overall confidence (lowest among all fields)
- Add warning icon (⚠️) for LOW confidence items
- Prompt user to review LOW confidence items before creation

### User Communication

When presenting LOW confidence items:
- "These 2 items have LOW confidence and may need review"
- Highlight them in the preview table
- Suggest editing before creation

---

## 10. Repo Context Integration

### Overview

When the user opts in to using repository context (runs the skill from a project directory and answers "Yes"), enrich issue descriptions with project information and file path links.

### Context Detection

Early in Phase 1, ask: "Use context from current repository?"

If **Yes**, detect:

#### Project Identity

**Sources (in priority order):**
1. `package.json` → `name` field (Node.js/JavaScript)
2. `Cargo.toml` → `[package] name` (Rust)
3. `pyproject.toml` → `[project] name` (Python)
4. `composer.json` → `name` field (PHP)
5. `go.mod` → module path (Go)
6. Git remote URL: `git config --get remote.origin.url`
7. Directory name as fallback

**Example Outputs:**
- `@company/mobile-app`
- `my-rust-project`
- `github.com/user/repo`

#### Platform Detection

**Detection Rules:**

| Check | Platform |
|-------|----------|
| `package.json` contains `"react-native"` | Mobile (iOS + Android) |
| `ios/` directory OR `*.xcodeproj` exists | iOS |
| `android/` directory OR `build.gradle` exists | Android |
| `package.json` contains `next`, `vite`, `react`, `vue` | Web |
| `Cargo.toml`, `go.mod`, `requirements.txt` exists | Backend/API |

**Multi-Platform:**
- If both `ios/` and `android/` exist → Mobile
- If `package.json` has react-native → Mobile
- Otherwise, detect all applicable platforms

#### Repository URL

**Extract from:**
```bash
git config --get remote.origin.url
```

**Formats:**
- GitHub: `https://github.com/user/repo`
- GitLab: `https://gitlab.com/user/repo`
- SSH: Convert `git@github.com:user/repo.git` → `https://github.com/user/repo`

### Context Usage

#### 1. Pre-fill Platform Selection

In Phase 1 when asking "What platform(s) does this feedback relate to?":
- If single platform detected → Set as default selection
- If multiple platforms → Suggest "Multiple/All platforms"
- User can still override

**Example:**
```
Detected platform: iOS

Question: "What platform(s) does this feedback relate to?"
Options:
  • iOS ← (suggested based on repo)
  • Android
  • Web
  • Backend/API
  • Multiple/All platforms
```

#### 2. Highlight Matching Linear Project

In Phase 1 when listing Linear projects:
- Compare project names to detected repo name
- Fuzzy match (case-insensitive, ignore special chars)
- Highlight matching project

**Example:**
```
Detected repo: @company/mobile-app

Which project should these issues go to?
  • mobile-app ← (matches repo name)
  • web-dashboard
  • backend-api
  • None/Backlog
```

#### 3. Enrich Descriptions

Add repo info to the Context section:

```markdown
## Context
[Inferred context from feedback]

**Source repo:** @company/mobile-app (https://github.com/company/mobile-app)
```

**Format:**
- Project name on same line as repo URL if available
- Only project name if no URL detected

**Examples:**

With URL:
```markdown
**Source repo:** my-project (https://github.com/user/my-project)
```

Without URL:
```markdown
**Source repo:** my-local-project
```

#### 4. File Path Detection and Linking

**Detection:**
Scan feedback text for file path patterns:
- Relative paths: `src/components/Header.tsx`
- Absolute paths: `/app/src/main.rs`
- Common patterns: `*.js`, `*.ts`, `*.swift`, `*.kt`, `*.py`, `*.rs`

**Validation:**
- Check if file exists in current directory
- Skip non-existent paths

**Link Generation:**

If repo URL is available, generate GitHub/GitLab links:

**GitHub:**
```
https://github.com/{owner}/{repo}/blob/main/{file_path}
```

**GitLab:**
```
https://gitlab.com/{owner}/{repo}/-/blob/main/{file_path}
```

**Add to description:**
```markdown
## Links
- [Screenshot](https://d.pr/abc)
- [src/components/Header.tsx](https://github.com/user/repo/blob/main/src/components/Header.tsx)
- [app/src/main.rs](https://github.com/user/repo/blob/main/app/src/main.rs)
```

If no URL (local-only repo):
```markdown
## Links
- `src/components/Header.tsx` (local file)
```

### Examples

#### Example 1: iOS Project with File Paths

**Detected Context:**
- Project: `@company/ios-app`
- Platform: iOS
- URL: `https://github.com/company/ios-app`

**Feedback:**
```
The app crashes in ProfileViewController.swift when tapping the logout button
```

**Description:**
```markdown
User reported: "The app crashes in ProfileViewController.swift when tapping the logout button"

## Context
- Platform: iOS
- File mentioned: ProfileViewController.swift

**Source repo:** @company/ios-app (https://github.com/company/ios-app)

**Complexity Estimate:** M (Medium)

## Links
- [ProfileViewController.swift](https://github.com/company/ios-app/blob/main/ProfileViewController.swift)

## Acceptance Criteria
- [ ] Fix crash in ProfileViewController logout action
- [ ] Add error handling for logout process
- [ ] Test on iOS 15+
```

#### Example 2: Web Project, No URL

**Detected Context:**
- Project: `my-web-app`
- Platform: Web
- URL: None (local repo)

**Feedback:**
```
The header component in src/Header.tsx is misaligned on mobile
```

**Description:**
```markdown
User reported: "The header component in src/Header.tsx is misaligned on mobile"

## Context
- Platform: Web
- File mentioned: src/Header.tsx

**Source repo:** my-web-app

**Complexity Estimate:** S (Small)

## Links
- `src/Header.tsx` (local file)

## Acceptance Criteria
- [ ] Fix header alignment on mobile screens
- [ ] Test responsive design (320px - 768px)
- [ ] Verify cross-browser compatibility
```

#### Example 3: Backend Project, Platform Pre-fill

**Detected Context:**
- Project: `api-server`
- Platform: Backend/API
- URL: `https://github.com/company/api-server`

**Workflow:**
1. User runs skill from `/projects/api-server`
2. Skill asks: "Use context from current repository?" → User: "Yes"
3. Detects: Rust project (Cargo.toml), Backend platform
4. Phase 1 platform question → Backend/API pre-selected
5. Phase 1 project question → "api-server" highlighted (if exists in Linear)

### Edge Cases

**No Git Repo:**
- Skip repo context detection entirely
- Don't ask "Use context from current repository?"
- Proceed normally

**Invalid File Paths:**
- If mentioned path doesn't exist, don't create link
- Note in description: `src/missing.tsx` (file not found)

**Multiple Projects in Mono-repo:**
- Use root package name or directory name
- User can manually edit during preview if needed

**Private Repos:**
- Generate links normally
- Linear users will need repo access to view

### Benefits

✅ **Faster workflow** - Pre-filled platform and project selections
✅ **Better traceability** - Direct links from issues to source code
✅ **Context preservation** - Repo name helps future maintainers
✅ **File validation** - Catches typos in file paths
✅ **Team alignment** - Everyone knows which codebase the issue relates to


