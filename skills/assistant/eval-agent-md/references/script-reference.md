# Script Reference — eval-agent-md

## Scripts Overview

All scripts use `uv run --script` — no pip install needed. Never invoke directly with `python`.

| Script | Purpose |
|--------|---------|
| `generate-scenarios.py` | Analyze a target file and auto-generate behavioral test scenarios |
| `eval-behavioral.py` | Run scenarios via `claude -p` with LLM-as-judge scoring |
| `mutate-loop.py` | Iteratively generate wording fixes for failing rules and A/B test them |

## Full Argument Reference

### generate-scenarios.py

```bash
uv run --script [SKILL_DIR]/scripts/generate-scenarios.py [OPTIONS] [TARGET_FILE]
```

| Argument | Description |
|----------|-------------|
| `[TARGET_FILE]` | Path to CLAUDE.md or agent .md file (positional) |
| `-o, --output PATH` | Output YAML file (default: `/tmp/eval-agent-md-<repo>-scenarios.yaml`) |
| `--repo-name NAME` | Repository name for output filename (auto-detected from git) |
| `--agent` | Treat input as agent definition file (adjusts generation for role-boundary scenarios) |
| `--skill` | Treat input as SKILL.md file (focuses on workflow order, argument contracts, progress reporting) |
| `--self` | Auto-resolve to this skill's own SKILL.md for dogfooding (implies `--skill`) |
| `--model MODEL` | Model for generation (default: sonnet) |
| `--no-scenario-cache` | Disable exact-input scenario generation cache |
| `--no-cache` | Compatibility alias for `--no-scenario-cache` |
| `--coverage` | Report discovered-rule coverage after scenario generation, including deterministic structural-check coverage vs LLM-only coverage |
| `--save-reference PATH` | Save scenarios to a stable reference directory for deterministic test suites |

### eval-behavioral.py

```bash
uv run --script [SKILL_DIR]/scripts/eval-behavioral.py \
  --scenarios-file SCENARIOS.yaml --claude-md TARGET.md [OPTIONS]
```

| Argument | Description |
|----------|-------------|
| `--scenarios-file PATH` | Path to scenarios YAML (required) |
| `--claude-md PATH` | CLAUDE.md or agent .md to test (required) |
| `[SCENARIO_IDS...]` | Run only these scenario IDs (positional, default: all) |
| `--runs N` | Runs per scenario for majority vote (default: 1, recommend 3 for reliability) |
| `--model MODEL` | Model for test subject (default: sonnet) |
| `--compare-models` | Run across haiku/sonnet/opus and show comparison matrix |
| `--workers N` | Max concurrent scenarios (0=auto, default: auto) |
| `--timeout N` | Per-call `claude -p` timeout in seconds (default: 240) |
| `--mutate PATH` | Mutated config for A/B comparison |
| `--no-judge-cache` | Disable exact-input judge verdict cache |
| `--no-subject-cache` | Disable exact-input subject response cache |
| `--no-cache` | Alias for `--no-judge-cache` |

### mutate-loop.py

```bash
uv run --script [SKILL_DIR]/scripts/mutate-loop.py \
  --target TARGET.md --scenarios-file SCENARIOS.yaml [OPTIONS]
```

| Argument | Description |
|----------|-------------|
| `--target PATH` | Config file to mutate (required) |
| `--scenarios-file PATH` | Path to scenarios YAML (required) |
| `--max-iterations N` | Max mutation attempts (default: 5) |
| `--runs N` | Runs per scenario for majority vote (default: 3) |
| `--model MODEL` | Model for behavioral tests (default: sonnet) |
| `--timeout N` | Per-call `claude -p` timeout in seconds (default: 240) |
| `--scenarios ID [ID...]` | Scenario IDs to focus on |
| `--apply` | Apply winning mutations to the target file (default: dry-run) |
| `--workers N` | Override worker count for behavioral eval |
| `--no-judge-cache` | Disable judge verdict cache during eval |
| `--no-subject-cache` | Disable exact-input subject response cache |
| `--no-cache` | Alias for `--no-judge-cache` |
| `--neutral-strategy CHOICE` | How to handle delta=0 mutations: `revert` (default), `keep`, or `size` (keep if response is smaller) |
| `--no-boundary-check` | Skip frontmatter protection, syntax validation, and mutation size checks |

## Caching Strategy

Three independent caches accelerate repeated runs:

| Cache | Scope | Key | Location |
|-------|-------|-----|----------|
| Scenario cache | `generate-scenarios.py` | SHA-256 of file content + generation parameters | `scripts/results/scenario_cache/` |
| Subject cache | `eval-behavioral.py` | SHA-256 of config hash + scenario ID + prompt + model + run index | `scripts/results/subject_cache/` |
| Judge cache | `eval-behavioral.py` | SHA-256 of system prompt + rule + scenario prompt + response | `scripts/results/judge_cache/` |

- All caches are exact-input: changing the target file or scenario invalidates the cache entry automatically
- Disable individually with `--no-scenario-cache`, `--no-subject-cache`, `--no-judge-cache`
- Cache files are stored as JSON for inspectability

## Mutation Safety

Three guardrails protect the target file during mutation (disable with `--no-boundary-check`):

| Check | What it does | Rejection reason |
|-------|-------------|------------------|
| Frontmatter protection | Rejects mutations targeting YAML frontmatter (between `---` markers) | `frontmatter_unsafe` |
| Syntax validation | Rejects mutations that would corrupt YAML frontmatter parsing | `syntax_invalid` |
| Bounded mutations | Rejects mutations where new text is >2x original length or >500 chars larger | `mutation_too_large` |

## Performance Notes

- The judge always uses haiku (cheap, fast, reliable for pass/fail scoring)
- Auto-workers default to a conservative laptop-safe cap of 2; opt into more with `--workers N`
- Generated scenarios are ephemeral (saved to `/tmp/`) — they adapt to the current file state
- Mutation-loop scoped checks reuse the already-known baseline and re-evaluate only the mutated candidate before full-suite validation
- For agent .md files, the generator creates role-boundary scenarios (e.g., "does the reviewer avoid writing code?")
- Script timeouts are computed dynamically from workload size — no manual timeout tuning needed
