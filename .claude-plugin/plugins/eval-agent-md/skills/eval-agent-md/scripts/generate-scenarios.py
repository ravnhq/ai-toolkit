#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""
Auto-generate behavioral test scenarios from any CLAUDE.md or agent .md file.
Uses `claude -p --model sonnet` to analyze rules and produce testable scenarios.

Usage:
    ./generate-scenarios.py ~/.claude/CLAUDE.md
    ./generate-scenarios.py ~/.claude/CLAUDE.md -o /tmp/scenarios.yaml
    ./generate-scenarios.py ~/.claude/agents/reviewer.md --agent
"""
import argparse
import re
import subprocess
import sys
import time
from pathlib import Path

import yaml  # type: ignore[import-untyped]

from _common import (
    claude_pipe,
    file_sha256,
    load_prompt,
    parse_json_response,
    read_json_cache,
    stable_cache_key,
    strip_markdown_fences,
    write_json_cache,
)

SYSTEM_PROMPT = load_prompt("system.md")
SYSTEM_PROMPT_INTEGRATION = load_prompt("system-integration.md")
EXAMPLES = load_prompt("examples.md")
AGENT_CONTEXT = load_prompt("context-agent.md")
SKILL_CONTEXT = load_prompt("context-skill.md")
RESULTS_DIR = Path(__file__).parent / "results"
SCENARIO_CACHE_DIR = RESULTS_DIR / "scenario_cache"

# Sections that are structural, not rules
_NON_RULE_SECTIONS = {
    "examples", "troubleshooting", "reference guides", "references",
    "arguments", "what this does", "workflow", "script execution",
    "progress reporting", "step 1", "step 2", "step 3", "step 4", "step 5",
    "positive trigger", "non-trigger", "more information",
}


def slugify_rule_name(name: str) -> str:
    """Convert a rule name into a stable snake_case identifier."""
    slug = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
    return slug or "rule"


def extract_rules(content: str) -> list[dict[str, str]]:
    """Extract rules from markdown H2 headings or YAML-like section labels.

    Supports two formats:
    - Standard markdown: ``## Rule Name``
    - Compact YAML-like: ``SECTION:\\n  key: value`` (all-caps label at line start)
    """
    rules = []
    seen: set[str] = set()

    # Standard: ## headings
    for match in re.finditer(r"^##\s+(.+)$", content, re.MULTILINE):
        name = match.group(1).strip()
        if name.lower() not in _NON_RULE_SECTIONS:
            rules.append({"rule_id": slugify_rule_name(name), "rule_name": name})
            seen.add(name)

    # Fallback: YAML-like all-caps section labels (e.g. "COMPLEXITY:")
    if not rules:
        for match in re.finditer(r"^([A-Z][A-Z_]+):\s*$", content, re.MULTILINE):
            name = match.group(1).strip()
            if name not in seen:
                rules.append({"rule_id": slugify_rule_name(name), "rule_name": name})
                seen.add(name)

    return rules


def extract_rule_names(content: str) -> list[str]:
    """Backward-compatible rule-name extraction helper."""
    return [rule["rule_name"] for rule in extract_rules(content)]


def _normalize_rules(rules: list[dict] | list[str]) -> list[dict[str, str]]:
    normalized = []
    for rule in rules:
        if isinstance(rule, str):
            normalized.append({"rule_id": slugify_rule_name(rule), "rule_name": rule})
        else:
            normalized.append({"rule_id": rule["rule_id"], "rule_name": rule["rule_name"]})
    return normalized


def _rule_catalog_map(rules: list[dict] | list[str]) -> dict[str, str]:
    normalized_rules = _normalize_rules(rules)
    return {rule["rule_name"]: rule["rule_id"] for rule in normalized_rules}


def _fuzzy_match_rule(rule_name: str, rules: list[dict] | list[str]) -> str | None:
    """Try exact match first, then slug-prefix match against the rule catalog."""
    rule_id_by_name = _rule_catalog_map(rules)

    # Exact match on rule_name
    if rule_name in rule_id_by_name:
        return rule_id_by_name[rule_name]

    # Slug-based: match if scenario rule slug starts with a catalog rule slug
    scenario_slug = slugify_rule_name(rule_name)
    for catalog_name, catalog_id in rule_id_by_name.items():
        if scenario_slug.startswith(catalog_id) or catalog_id.startswith(scenario_slug):
            return catalog_id

    return None


def normalize_scenario(scenario: dict, rules: list[dict] | list[str]) -> dict | None:
    """Derive and validate stable metadata for a per-rule scenario."""
    rule_name = scenario.get("rule")
    if not isinstance(rule_name, str):
        return None

    derived_rule_id = _fuzzy_match_rule(rule_name, rules)
    if not derived_rule_id:
        return None

    normalized = dict(scenario)
    normalized["rule_id"] = derived_rule_id
    return normalized


def normalize_integration_scenario(scenario: dict, rules: list[dict] | list[str]) -> dict | None:
    """Derive and validate stable metadata for an integration scenario."""
    rules_tested = scenario.get("rules_tested")
    if not isinstance(rules_tested, list) or not all(isinstance(rule, str) for rule in rules_tested):
        return None

    derived_rule_ids = []
    for rule_name in rules_tested:
        rule_id = _fuzzy_match_rule(rule_name, rules)
        if rule_id is None:
            return None
        derived_rule_ids.append(rule_id)

    normalized = dict(scenario)
    normalized["rule_ids_tested"] = derived_rule_ids
    normalized["type"] = "integration"
    normalized.setdefault("rule", ", ".join(rules_tested))
    return normalized


def compute_coverage(rules: list[dict] | list[str], scenarios: list[dict]) -> dict:
    """Compute scenario, deterministic, and LLM-only coverage for discovered rules."""
    normalized_rules = _normalize_rules(rules)
    if not normalized_rules:
        return {
            "coverage_status": "unavailable",
            "rules_found": 0,
            "rules_tested": 0,
            "rules_with_structural_checks": 0,
            "coverage_pct": None,
            "untested": [],
            "untested_rule_ids": [],
            "llm_only": [],
            "llm_only_rule_ids": [],
        }

    discovered = {rule["rule_id"]: rule["rule_name"] for rule in normalized_rules}
    tested_rule_ids = set()
    structural_rule_ids = set()
    for s in scenarios:
        scenario_rule_ids = []
        if isinstance(s.get("rule_id"), str):
            scenario_rule_ids.append(s["rule_id"])
        scenario_rule_ids.extend(
            rule_id for rule_id in s.get("rule_ids_tested", [])
            if isinstance(rule_id, str)
        )
        for rule_id in scenario_rule_ids:
            if rule_id in discovered:
                tested_rule_ids.add(rule_id)
                if s.get("structural_checks"):
                    structural_rule_ids.add(rule_id)

    ordered_rule_ids = [rule["rule_id"] for rule in normalized_rules]
    untested_rule_ids = [rule_id for rule_id in ordered_rule_ids if rule_id not in tested_rule_ids]
    llm_only_rule_ids = [
        rule_id for rule_id in ordered_rule_ids
        if rule_id in tested_rule_ids and rule_id not in structural_rule_ids
    ]
    coverage_pct = len(tested_rule_ids) / len(normalized_rules) * 100
    return {
        "coverage_status": "ok",
        "rules_found": len(normalized_rules),
        "rules_tested": len(tested_rule_ids),
        "rules_with_structural_checks": len(structural_rule_ids),
        "coverage_pct": coverage_pct,
        "untested": [discovered[rule_id] for rule_id in untested_rule_ids],
        "untested_rule_ids": untested_rule_ids,
        "llm_only": [discovered[rule_id] for rule_id in llm_only_rule_ids],
        "llm_only_rule_ids": llm_only_rule_ids,
    }


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate behavioral test scenarios from CLAUDE.md")
    parser.add_argument("config", nargs="?", type=Path, help="Path to CLAUDE.md or agent .md file")
    parser.add_argument("-o", "--output", type=Path, help="Output YAML file (default: /tmp/eval-agent-md-<repo>-scenarios.yaml)")
    parser.add_argument("--repo-name", default=None, help="Repository name for output filename (auto-detected from git)")
    parser.add_argument("--agent", action="store_true", help="Treat input as agent definition file")
    parser.add_argument("--skill", action="store_true", help="Treat input as skill definition file (SKILL.md)")
    parser.add_argument("--self", action="store_true", dest="self_test",
                        help="Auto-resolve to this skill's own SKILL.md (implies --skill)")
    parser.add_argument("--model", default="sonnet", help="Model for generation (default: sonnet)")
    parser.add_argument("--no-scenario-cache", action="store_true", help="Disable exact-input scenario cache")
    parser.add_argument("--no-cache", action="store_true", dest="no_scenario_cache",
                        help="Alias for --no-scenario-cache")
    parser.add_argument("--holistic", action="store_true",
                        help="Also generate integration scenarios that test multiple rules interacting")
    parser.add_argument("--coverage", action="store_true",
                        help="Report rule coverage after scenario generation")
    parser.add_argument("--save-reference", type=Path, default=None,
                        help="Save scenarios to a stable reference directory (for deterministic test suites)")
    return parser


def generate_scenarios(config_path: Path, is_agent: bool = False,
                       is_skill: bool = False, model: str = "sonnet",
                       use_cache: bool = True) -> tuple[list[dict], dict]:
    content = config_path.read_text()
    rules = extract_rules(content)

    if is_skill:
        file_type = 'skill definition'
    elif is_agent:
        file_type = 'agent definition'
    else:
        file_type = 'CLAUDE.md configuration'

    context_hints = ""
    if is_agent:
        context_hints += AGENT_CONTEXT
    if is_skill:
        context_hints += SKILL_CONTEXT

    cache_key = stable_cache_key(
        "scenario-generation",
        file_sha256(config_path),
        file_type,
        is_agent,
        is_skill,
        model,
        SYSTEM_PROMPT,
        EXAMPLES,
        context_hints,
    )
    cache_file = SCENARIO_CACHE_DIR / f"{cache_key}.json"
    if use_cache:
        cached = read_json_cache(cache_file)
        if isinstance(cached, dict) and isinstance(cached.get("scenarios"), list):
            return cached["scenarios"], {
                "cache": "hit",
                "cache_file": str(cache_file),
                "elapsed_seconds": 0.0,
                "model": model,
            }

    prompt = f"""Analyze this {file_type} file and generate behavioral test scenarios for each testable rule.

## Config File: {config_path.name}
```
{content}
```

## Rule Catalog
{yaml.dump(rules, default_flow_style=False, sort_keys=False)}

{context_hints}

## Example Scenarios (for quality reference)
{EXAMPLES}

## Instructions
1. Read every rule, gate, and constraint in the file
2. For each testable rule, generate ONE scenario
3. Use the exact human-readable `rule_name` from the rule catalog in the `rule` field
4. Make prompts realistic — they should sound like real user requests
5. Make pass_criteria observable in text output (no tool checks)
6. Make fail_signals specific enough to avoid false positives
7. Include code snippets inline in prompts when needed to test code-related rules
8. Skip rules that can only be tested via multi-turn interaction or tool usage
9. When a rule has deterministic text structure (exact heading, literal phrase, forbidden phrase, regex shape),
   include `structural_checks` using only these check types: `starts_with`, `contains`, `not_contains`, `regex`

Generate the JSON array now."""

    line_count = len(content.splitlines())
    timeout = max(600, line_count * 2)
    started_at = time.perf_counter()
    raw = claude_pipe(prompt, model=model, system_prompt=SYSTEM_PROMPT, timeout=timeout)
    elapsed_seconds = time.perf_counter() - started_at

    text = strip_markdown_fences(raw)
    scenarios = parse_json_response(text, expect_type=list)

    # Validate each scenario has required fields
    required = {"id", "rule", "prompt", "pass_criteria", "fail_signals"}
    valid = []
    for s in scenarios:
        missing = required - set(s.keys())
        if missing:
            print(f"  Warning: scenario '{s.get('id', '?')}' missing {missing}, skipping", file=sys.stderr)
            continue
        normalized = normalize_scenario(s, rules)
        if normalized is None:
            print(
                f"  Warning: scenario '{s.get('id', '?')}' rule could not be normalized from catalog, skipping",
                file=sys.stderr,
            )
            continue
        valid.append(normalized)

    metadata = {
        "cache": "miss",
        "cache_file": str(cache_file),
        "elapsed_seconds": elapsed_seconds,
        "model": model,
    }
    if use_cache:
        write_json_cache(cache_file, {"metadata": metadata, "scenarios": valid})
    return valid, metadata


def generate_integration_scenarios(config_path: Path, is_agent: bool = False,
                                    is_skill: bool = False, model: str = "sonnet",
                                    use_cache: bool = True) -> tuple[list[dict], dict]:
    """Generate integration scenarios that test multiple rules interacting."""
    content = config_path.read_text()
    rules = extract_rules(content)

    if is_skill:
        file_type = 'skill definition'
    elif is_agent:
        file_type = 'agent definition'
    else:
        file_type = 'CLAUDE.md configuration'

    context_hints = ""
    if is_agent:
        context_hints += AGENT_CONTEXT
    if is_skill:
        context_hints += SKILL_CONTEXT

    cache_key = stable_cache_key(
        "integration-scenario-generation",
        file_sha256(config_path),
        file_type,
        is_agent,
        is_skill,
        model,
        SYSTEM_PROMPT_INTEGRATION,
        context_hints,
    )
    cache_file = SCENARIO_CACHE_DIR / f"{cache_key}.json"
    if use_cache:
        cached = read_json_cache(cache_file)
        if isinstance(cached, dict) and isinstance(cached.get("scenarios"), list):
            return cached["scenarios"], {
                "cache": "hit",
                "cache_file": str(cache_file),
                "elapsed_seconds": 0.0,
                "model": model,
            }

    prompt = f"""Analyze this {file_type} file and generate integration test scenarios that exercise multiple rules simultaneously.

## Config File: {config_path.name}
```
{content}
```

## Rule Catalog
{yaml.dump(rules, default_flow_style=False, sort_keys=False)}

{context_hints}

## Instructions
1. Identify rules that can realistically co-occur in a single user request
2. Focus on combinations where priority, ordering, or potential conflicts matter
3. Generate 3-5 integration scenarios, each testing 2-4 rules
4. Use exact human-readable rule names from the rule catalog in `rules_tested`
5. Make prompts realistic and complex enough that multiple rules naturally apply
6. Pass criteria MUST check rule interactions (ordering, priority, conflict resolution), not just individual presence
7. Include code snippets inline in prompts when needed
8. Add `structural_checks` when the interaction includes deterministic output structure

Generate the JSON array now."""

    line_count = len(content.splitlines())
    # Integration scenarios require more reasoning time than per-rule (analyzing interactions)
    timeout = max(720, line_count * 3)
    started_at = time.perf_counter()
    raw = claude_pipe(prompt, model=model, system_prompt=SYSTEM_PROMPT_INTEGRATION, timeout=timeout)
    elapsed_seconds = time.perf_counter() - started_at

    text = strip_markdown_fences(raw)
    scenarios = parse_json_response(text, expect_type=list)

    required = {"id", "type", "rules_tested", "prompt", "pass_criteria", "fail_signals"}
    valid = []
    for s in scenarios:
        missing = required - set(s.keys())
        if missing:
            print(f"  Warning: integration scenario '{s.get('id', '?')}' missing {missing}, skipping", file=sys.stderr)
            continue
        normalized = normalize_integration_scenario(s, rules)
        if normalized is None:
            print(
                f"  Warning: integration scenario '{s.get('id', '?')}' rules could not be normalized from catalog, skipping",
                file=sys.stderr,
            )
            continue
        valid.append(normalized)

    metadata = {
        "cache": "miss",
        "cache_file": str(cache_file),
        "elapsed_seconds": elapsed_seconds,
        "model": model,
    }
    if use_cache:
        write_json_cache(cache_file, {"metadata": metadata, "scenarios": valid})
    return valid, metadata


def get_repo_name() -> str:
    """Detect repository name from git, fall back to current directory name."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=5,
        )
        if result.returncode == 0:
            return Path(result.stdout.strip()).name
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return Path.cwd().name


def main():
    parser = build_arg_parser()
    args = parser.parse_args()

    if args.self_test:
        args.config = Path(__file__).resolve().parent.parent / "SKILL.md"
        args.skill = True
        if not args.config.exists():
            print(f"Self-test SKILL.md not found: {args.config}", file=sys.stderr)
            sys.exit(1)
    elif args.config is None:
        parser.error("Either provide a config path or use --self")

    if not args.config.exists():
        print(f"File not found: {args.config}", file=sys.stderr)
        sys.exit(1)

    print(f"Analyzing {args.config.name}...", file=sys.stderr, end="", flush=True)
    scenarios, metadata = generate_scenarios(
        args.config,
        is_agent=args.agent,
        is_skill=args.skill,
        model=args.model,
        use_cache=not args.no_scenario_cache,
    )
    print(
        f" generated {len(scenarios)} per-rule scenarios "
        f"[cache={metadata['cache']}, model={metadata['model']}, elapsed={metadata['elapsed_seconds']:.1f}s]",
        file=sys.stderr,
    )

    if args.holistic:
        print("Generating integration scenarios...", file=sys.stderr, end="", flush=True)
        integration, int_metadata = generate_integration_scenarios(
            args.config,
            is_agent=args.agent,
            is_skill=args.skill,
            model=args.model,
            use_cache=not args.no_scenario_cache,
        )
        print(
            f" generated {len(integration)} integration scenarios "
            f"[cache={int_metadata['cache']}, model={int_metadata['model']}, elapsed={int_metadata['elapsed_seconds']:.1f}s]",
            file=sys.stderr,
        )
        scenarios.extend(integration)

    if args.coverage:
        content = args.config.read_text()
        rules = extract_rules(content)
        cov = compute_coverage(rules, scenarios)
        if cov["coverage_status"] == "unavailable":
            print("Coverage: unavailable (no rule sections discovered)", file=sys.stderr)
        else:
            print(f"Coverage: {cov['rules_tested']}/{cov['rules_found']} rules ({cov['coverage_pct']:.0f}%)", file=sys.stderr)
            print(
                f"  Deterministic checks: {cov['rules_with_structural_checks']}/{cov['rules_tested']} tested rules",
                file=sys.stderr,
            )
        if cov["untested"]:
            print(f"  Untested: {', '.join(cov['untested'])}", file=sys.stderr)
        if cov["llm_only"]:
            print(f"  LLM-only: {', '.join(cov['llm_only'])}", file=sys.stderr)

    chunks = []
    for s in scenarios:
        chunks.append(yaml.dump([s], default_flow_style=False, allow_unicode=True, sort_keys=False).rstrip())
    output = "\n\n".join(chunks) + "\n"

    if args.output:
        out_path = args.output
    else:
        repo_name = args.repo_name or get_repo_name()
        out_path = Path(f"/tmp/eval-agent-md-{repo_name}-scenarios.yaml")

    out_path.write_text(output)
    print(f"Saved to {out_path}", file=sys.stderr)

    if args.save_reference:
        args.save_reference.mkdir(parents=True, exist_ok=True)
        ref_path = args.save_reference / out_path.name
        ref_path.write_text(output)
        print(f"Reference saved to {ref_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
