# Changelog

## 2026-03-23

- Improved skill quality with progressive disclosure and convention fixes.
- Used uv run --script in SKILL.md invocation examples.
- Added real-time progress reporting to workflow.
## 2026-03-21

- Added type-system-audit skill and skill scoring script.
## 2026-03-10

- Added localize-ios skill. (#15)
- Added pr comments address skill. (#14)
## 2026-03-03

- Added tech-android skill with 28 rules. (#4)
- Added rewrite-commit-history skill. (#13)
## 2026-03-02

- Added figma-to-react-components skill. (#12)
## 2026-02-27

- Organized skills into category subdirectories (`skills/<category>/<name>/`) matching the five-tier hierarchy: universal, platform, framework, design, assistant. (#8)
- Added `agent-pr-creator` skill for automated PR creation. (#10)
- Added blog post on context switching done right. (#11)
- Added validation checklist reference to `agent-skill-creator`.

## 2026-02-16

- Removed project overrides system (SKILL.md sections, `add_project_overrides.rb` script, docs).
- Added CI release workflow (`skills-release.yml`) — skills are automatically bumped, tagged, and released on merge to main.
- Relaxed `metadata.version` audit requirement — CI bootstraps missing versions to build 1.

## 2026-02-13

- Switched to per-skill build IDs and removed global catalog versioning.
- Updated release flow to bump and tag a single skill build at a time.
