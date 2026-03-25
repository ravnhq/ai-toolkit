---
name: transcript-notes
description: 'Convert meeting transcript .txt files into structured .md notes with
  metadata, TL;DR, key topics, action items, and quotes. Use when processing raw
  transcripts into formatted notes. Triggers on: "process transcript", "generate
  notes from transcript", "transcript to notes", "/transcript-notes".'
metadata:
  category: assistant
  tags:
  - transcript
  - notes
  - meeting
  - documentation
  - action-items
  - summary
  status: ready
  version: 1
---

# Transcript Notes

Convert a raw meeting transcript `.txt` file into a structured `.md` notes file.

## Prerequisites

- Raw transcript `.txt` file — supports speaker-turn format (speaker name on its own line, dialogue as paragraph) and timestamped formats (e.g., `[00:01:23] Speaker: text`)
- Target notes directory exists or will be created

## Workflow

### 1. Read & Analyze Transcript

- Read the transcript file
- Identify: participants, series name, episode number, date, duration (estimate from content length if not stated)
- Map the conversation flow: what topics were discussed, in what order, by whom

### 2. Extract & Structure

- **Meeting Metadata:** Series, Episode, Date (if inferable), Duration (if inferable), Participants
- **TL;DR:** Single paragraph, 2-4 sentences, captures the meeting's purpose and key outcomes
- **Key Topics:** Each topic gets a `**bold title** -- one-line summary` bullet, then a `###` subsection with 2-5 sentences or bullets expanding it
- **Action Items:** `**Person/Group:** action description` format
- **Quotes:** 3-5 notable quotes using `> "quote" -- Speaker Name (context)` format — prioritize quotes that capture decisions, insights, or strong positions over casual remarks

### 3. Write & Verify

- Create the notes directory if it doesn't exist: `notes/{series-slug}/`
- Write the `.md` file mirroring the transcript filename (e.g., `001.txt` → `001.md`, `kickoff-meeting.txt` → `kickoff-meeting.md`)
- Verify: all template sections present, Key Topics list matches subsections 1:1, quotes are verbatim from transcript

## Output Template

```markdown
# {Series Name} - {Episode NNN or Date}

## Meeting Metadata
- **Series:** {series name}
- **Episode:** {NNN, if applicable}
- **Date:** {date, if inferable}
- **Duration:** {duration, if inferable}
- **Participants:** {comma-separated full names}

## TL;DR
{Single paragraph, 2-4 sentences}

## Key Topics
- **{Topic}** -- {One-line summary}
- **{Topic}** -- {One-line summary}
...

### {Topic Heading}
{2-5 sentences or bullet points}

### {Topic Heading}
...

## Action Items
- **{Person/Group}:** {Action description}
...

## Quotes
> "{Quote}" -- {Speaker Name} ({optional context})
...
```

## Quality Rules

- TL;DR must be a single paragraph — no bullets, no multiple paragraphs
- Key Topics bullet list and `###` subsections must correspond 1:1 and appear in the same order
- Action items must name a specific person or group
- Quotes must be actual words from the transcript, not paraphrased
- Use `--` (double dash) not `—` (em dash) for separators in topic summaries and quotes
- Series slug for directory: kebab-case version of series name
- Optional metadata fields (Date, Duration) — include only when inferable from transcript content
- Long transcripts (>5000 words) — process in sections, then merge; do not truncate or skip content
- Preserve speaker terminology — keep acronyms, jargon, and domain-specific terms as spoken; do not rephrase or "clean up" technical language
- TL;DR must focus on outcomes and decisions, not just list what was discussed — "The team decided X" not "The team discussed X"
- Action items must include deadlines or timeframes when mentioned in the transcript — "by Friday" or "next sprint", not just the task
- Key Topics must appear in chronological order as discussed in the transcript, not reordered by importance

## Examples

### Positive Trigger

User: "Process the meeting transcript at transcripts/ai-platform-sync/003.txt — generate formatted notes with metadata, key topics, action items, and quotes"

Expected behavior: Reads the transcript file, extracts participants, topics, action items, and quotes, then writes a structured `.md` notes file.

### Non-Trigger

User: "Create a template agenda for our weekly sync meeting"

Expected behavior: This is meeting agenda creation, not transcript processing. The user wants to plan a future meeting, not convert an existing recording.

## Troubleshooting

- Error: Cannot determine series name
  - Cause: Transcript has no meeting context or header identifying the series.
  - Solution: Ask user for the series name before proceeding.

- Error: No clear action items found
  - Cause: Meeting was informational only with no commitments or next steps.
  - Solution: Write "No action items identified" in the Action Items section, or extract implicit next steps.

- Error: Cannot estimate duration
  - Cause: No timing cues, timestamps, or length indicators in transcript.
  - Solution: Omit Duration from the Meeting Metadata section.

- Error: Transcript has overlapping or unclear speaker labels
  - Cause: Multiple speakers share similar names or labels are inconsistent (e.g., "John" vs "John S." vs "JS").
  - Solution: Normalize speaker names to full names where identifiable; ask user for disambiguation if ambiguous.

- Error: Transcript has no speaker labels
  - Cause: Raw transcript is a continuous text block without speaker attribution (e.g., auto-generated without diarization).
  - Solution: Ask user if speaker info is available separately; otherwise attribute all content to "Unknown Speaker" and note the limitation in metadata.

- Error: Transcript is in a non-English language
  - Cause: Meeting was conducted in another language.
  - Solution: Write notes in the same language as the transcript unless user requests translation. Keep all quotes in the original language.

- Error: Multiple transcript files for one meeting (Part 1, Part 2)
  - Cause: Recording was split into segments.
  - Solution: Read all parts in order and produce a single unified notes file. De-duplicate topics that span the split point.
