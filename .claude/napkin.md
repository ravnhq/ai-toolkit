# Napkin

## Corrections
| Date | Source | What Went Wrong | What To Do Instead |
|------|--------|----------------|-------------------|
| 2026-02-13 | self | Ran ls before reading .claude/napkin.md at session start | Read .claude/napkin.md before any other command in this repo |
| 2026-02-13 | self | Tried running skill validator script directly; failed because `yaml` module is missing in this environment | Mirror validation logic with Ruby `YAML` for local audits when Python deps are unavailable |
| 2026-02-13 | self | Broke shell quoting while generating multiline file content with `ruby -e` | Prefer escaped `\\n` one-liner strings for reliable shell-safe file writes |
| 2026-02-13 | self | Local link checks flagged intentionally illustrative markdown links in sample code blocks | Use inline code filenames for illustrative docs in templates to avoid false broken-link signals |
| 2026-02-13 | self | Trigger harness regex used `$` in multiline mode and matched end-of-line too early | Use lookahead with `\\z` for section boundaries in multiline markdown parsing |

## User Preferences
-
- User said Python via `uv` is acceptable when needed.

## Patterns That Work
-
- Add Examples and Troubleshooting sections to skills to improve usability and reduce ambiguity.
- Normalize frontmatter safely by moving non-portable keys into `metadata` instead of deleting them.
- Batch edit all `skills/**/SKILL.md` with a single scripted pass to keep schema consistent.
- Generate reusable, skill-specific examples/troubleshooting blocks with a script to close repo-wide quality gaps quickly.
- Add a short 3-step workflow section when skills lack explicit execution steps.
- Keep harness section extraction regex anchored with lookaheads to avoid empty captures.
- When bumping `version` in SKILL.md frontmatter, always update `marketplace.json` in the same commit. The CI auditor (`scripts/skills_audit.rb`) checks for mismatches.
- The skills harness (`scripts/skills_harness.rb`) requires literal `- Error:` / `- Cause:` / `- Solution:` and `Expected behavior:` strings — bold markdown variants like `- **Error**:` will fail.

## Patterns That Do Not Work
-
- Assuming local Python packages exist for helper scripts in read-only sandbox sessions.

## Domain Notes
-
- agent-skill-creator v3: SKILL.md rewritten to 222 lines (was ~500). Content split into 5 reference files. Scripts kept as optional accelerators, not hard dependencies. Frontmatter follows Anthropic guide (name+description required, repo fields in metadata).
