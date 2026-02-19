# Troubleshooting

## Upload / Installation Failures

| Symptom | Check | Fix |
|---------|-------|-----|
| Skill not recognized | `SKILL.md` filename exact and case-sensitive? | Rename to exactly `SKILL.md` |
| Parse error on load | YAML frontmatter has `---` delimiters on both sides? | Add missing `---` delimiter |
| Name rejected | Folder name is kebab-case (lowercase, hyphens, digits only)? | Rename folder |
| Name reserved | Name contains `claude` or `anthropic`? | Choose a different name |

## Skill Does Not Trigger

**Symptoms**: Skill is ignored for relevant tasks. User must explicitly invoke it.

**Diagnostic**: Ask Claude "When would you use the [skill name] skill?" If Claude can't answer clearly, the description needs work.

**Fixes**:
1. Add specific trigger phrases to description (exact words users say)
2. Include keyword variations and paraphrases
3. Add numbered trigger conditions: "Use when (1)..., (2)..., (3)..."
4. Verify description is under 1,024 characters (truncated descriptions lose triggers)

## Skill Triggers Too Often

**Symptoms**: Skill activates for unrelated tasks, interfering with other workflows.

**Fixes**:
1. Add negative triggers: "NOT for [scenario]", "Do not use when [condition]"
2. Narrow scope language — replace broad terms with specific ones
3. Remove generic keywords that overlap with other domains

## Instructions Are Ignored

**Symptoms**: Skill triggers but Claude skips steps, produces wrong format, or misses requirements.

**Fixes** (in priority order):
1. **Reduce verbosity** — shorter instructions are followed more reliably
2. **Move to top** — place critical instructions at the beginning of SKILL.md
3. **Remove ambiguity** — replace "consider doing X" with "always do X" or "do X when [condition]"
4. **Add examples** — show exact input/output pairs Claude can pattern-match
5. **Use scripts** — for critical validation, replace natural language with executable checks
6. **Split content** — move detailed reference material to `references/` files

## Context Overload

**Symptoms**: Skill works in isolation but degrades when combined with other skills or long conversations.

**Causes**:
- SKILL.md exceeds 5,000 words
- Too many skills enabled simultaneously (20-50+ degrades performance)
- Redundant content between SKILL.md and reference files

**Fixes**:
1. Audit SKILL.md word count — move excess to references
2. Eliminate duplication between SKILL.md and reference files
3. Ensure information lives in one place, not both
4. Consider splitting into multiple focused skills if scope is too broad

## Output Inconsistency

**Symptoms**: Skill produces different quality or format across sessions.

**Fixes**:
1. Add explicit output templates (exact structure Claude must follow)
2. Include input/output example pairs
3. Add verification steps ("After generating, check that [criteria]")
4. Replace flexible language ("you might want to") with specific instructions
