#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""
Automated CLAUDE.md mutation loop.
Iteratively generates targeted wording changes, runs A/B behavioral tests,
and keeps improvements (delta > 0).

Usage:
    ./mutate-loop.py --target ~/.claude/CLAUDE.md --scenarios-file /tmp/scenarios.yaml
    ./mutate-loop.py --target config.md --scenarios-file s.yaml --max-iterations 3
    ./mutate-loop.py --target config.md --scenarios-file s.yaml --apply
"""
import argparse
import json
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path

import yaml  # type: ignore[import-untyped]

from _common import claude_pipe, strip_markdown_fences

SKILL_DIR = Path(__file__).parent
EVAL_SCRIPT = SKILL_DIR / "eval-behavioral.py"
RESULTS_DIR = SKILL_DIR / "results"

MUTATION_PROMPT_TEMPLATE = """You are a prompt engineer specializing in AI instruction tuning.

## Current Config File
```
{config_content}
```

## Failing Scenario
- ID: {scenario_id}
- Rule: {scenario_rule}
- Prompt sent to AI: {scenario_prompt}
- Pass criteria: {pass_criteria}
- Fail signals: {fail_signals}
- Recent failure evidence: {failure_evidence}

## Task
Suggest a MINIMAL, TARGETED wording change to the config file that would make the AI pass this scenario without breaking other rules.

## Constraints
- Change as few words as possible — surgical edits only
- Do NOT restructure the file or add new sections
- Do NOT remove existing rules — only refine wording
- The change must be specific to this failure, not a general rewrite
- Consider interactions with other rules that might break

## Output Format
Reply with ONLY a JSON object (no markdown fences):
{{"section": "which rule/gate", "change_description": "what to change and why", "old_text": "exact text to find in the file", "new_text": "replacement text"}}"""


MUTATION_SYSTEM = "You are a prompt engineering assistant. Reply with only the requested JSON."


def _count_scenarios(scenarios_file: Path, scenario_ids: list[str] | None) -> int:
    scenarios = yaml.safe_load(scenarios_file.read_text())
    if scenario_ids:
        return len([s for s in scenarios if s["id"] in scenario_ids])
    return len(scenarios)


def run_eval(target: Path, scenarios_file: Path, scenario_ids: list[str] | None,
             runs: int, model: str, per_call_timeout: int = 240, workers: int = 0,
             no_judge_cache: bool = False, no_subject_cache: bool = False) -> dict:
    cmd = [str(EVAL_SCRIPT), "--runs", str(runs), "--model", model,
           "--claude-md", str(target), "--scenarios-file", str(scenarios_file),
           "--timeout", str(per_call_timeout)]
    if workers:
        cmd.extend(["--workers", str(workers)])
    if no_judge_cache:
        cmd.append("--no-judge-cache")
    if no_subject_cache:
        cmd.append("--no-subject-cache")
    if scenario_ids:
        cmd.extend(scenario_ids)
    n = _count_scenarios(scenarios_file, scenario_ids)
    timeout = max(300, n * runs * 90 + 60)
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    if result.returncode != 0:
        print(f"  Eval stderr: {result.stderr[:300]}", file=sys.stderr)
    results_dir = SKILL_DIR / "results"
    files = sorted(results_dir.glob("eval-*.json"), key=lambda p: p.name, reverse=True)
    if not files:
        raise RuntimeError("No results file found after eval run")
    return json.loads(files[0].read_text())


def find_failing_scenarios(results: dict) -> list[dict]:
    return [s for s in results.get("scenarios", []) if s["final_verdict"] == "FAIL"]


def scenario_pass_count(results: dict, scenario_id: str) -> int:
    for scenario in results.get("scenarios", []):
        if scenario.get("id") == scenario_id:
            return int(scenario.get("passes", 0))
    return 0


def delta_for_scenario(baseline_results: dict, mutated_results: dict, scenario_id: str) -> int:
    return scenario_pass_count(mutated_results, scenario_id) - scenario_pass_count(baseline_results, scenario_id)


def generate_mutation(config_content: str, scenario: dict, scenarios_file: Path) -> dict | None:
    evidence = "No evidence available"
    for detail in scenario.get("details", []):
        if detail.get("verdict") == "FAIL":
            evidence = detail.get("evidence", evidence)
            break

    all_scenarios = yaml.safe_load(scenarios_file.read_text())
    scenario_def = next((s for s in all_scenarios if s["id"] == scenario["id"]), None)
    if not scenario_def:
        return None

    prompt = MUTATION_PROMPT_TEMPLATE.format(
        config_content=config_content,
        scenario_id=scenario["id"],
        scenario_rule=scenario["rule"],
        scenario_prompt=scenario_def["prompt"],
        pass_criteria=yaml.dump(scenario_def["pass_criteria"], default_flow_style=False),
        fail_signals=yaml.dump(scenario_def["fail_signals"], default_flow_style=False),
        failure_evidence=evidence,
    )

    line_count = len(config_content.splitlines())
    timeout = max(60, line_count)
    raw = claude_pipe(prompt, model="sonnet", system_prompt=MUTATION_SYSTEM, timeout=timeout)
    text = strip_markdown_fences(raw)
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        print(f"  Mutation generation returned non-JSON: {text[:200]}", file=sys.stderr)
        return None


def _fmt_elapsed(start: float) -> str:
    s = int(time.time() - start)
    if s < 60:
        return f"{s}s"
    return f"{s // 60}m{s % 60:02d}s"


def _progress(iteration: int, max_iter: int, scenario_id: str, phase: str,
              start: float, stats: dict[str, int]) -> None:
    elapsed = _fmt_elapsed(start)
    kept, reverted, neutral = stats["kept"], stats["reverted"], stats["neutral"]
    print(f"  [{iteration}/{max_iter}] {scenario_id} | {phase} | "
          f"{elapsed} | kept:{kept} reverted:{reverted} neutral:{neutral}")


def _print_summary_table(iteration_log: list[dict]) -> None:
    if not iteration_log:
        return
    hdr = f"  {'Iter':>4}  {'Scenario':<24} {'Delta':>6}  {'Result':<10} Description"
    print(f"\n{'=' * 60}")
    print("  Iteration Summary")
    print(f"{'=' * 60}")
    print(hdr)
    print(f"  {'-' * 4}  {'-' * 24} {'-' * 6}  {'-' * 10} {'-' * 30}")
    for e in iteration_log:
        delta_str = f"{e.get('delta', '-'):>+d}" if isinstance(e.get("delta"), int) else "  -"
        desc = e.get("mutation", {}).get("change_description", "-") if isinstance(e.get("mutation"), dict) else "-"
        desc = (desc[:40] + "...") if len(desc) > 43 else desc
        print(f"  {e['iteration']:>4}  {e['target']:<24} {delta_str:>6}  {e['result']:<10} {desc}")


def is_frontmatter_safe(old_text: str, content: str) -> bool:
    """Return False if old_text falls within YAML frontmatter."""
    if not content.startswith("---"):
        return True
    end = content.find("\n---", 3)
    if end == -1:
        return True
    frontmatter_end = end + 4  # include the closing ---\n
    pos = content.find(old_text)
    if pos == -1:
        return True
    return pos >= frontmatter_end


def validate_post_mutation(content: str) -> bool:
    """Validate YAML frontmatter is still parseable after mutation."""
    if not content.startswith("---"):
        return True
    end = content.find("\n---", 3)
    if end == -1:
        return True
    frontmatter = content[4:end]  # skip opening ---\n
    try:
        yaml.safe_load(frontmatter)
        return True
    except yaml.YAMLError:
        return False


def is_mutation_bounded(old_text: str, new_text: str, max_pct: float = 2.0, max_chars: int = 500) -> bool:
    """Return True if mutation is bounded (not a complete rewrite)."""
    if not old_text:
        return len(new_text) <= max_chars
    size_ratio = len(new_text) / len(old_text)
    abs_change = abs(len(new_text) - len(old_text))
    return size_ratio <= max_pct and abs_change <= max_chars


def decide_mutation(delta: int, baseline_size: int, mutated_size: int, strategy: str) -> str:
    """Decide mutation outcome with configurable neutral tiebreak.

    strategy: 'revert' (default), 'keep', or 'size' (keep if smaller response)
    Returns: 'keep', 'revert', 'neutral_keep', or 'neutral_revert'
    """
    if delta > 0:
        return "keep"
    if delta < 0:
        return "revert"
    # delta == 0: neutral
    if strategy == "keep":
        return "neutral_keep"
    if strategy == "size":
        return "neutral_keep" if mutated_size < baseline_size else "neutral_revert"
    return "neutral_revert"


def apply_mutation(config_content: str, mutation: dict) -> str | None:
    old_text = mutation.get("old_text", "")
    new_text = mutation.get("new_text", "")
    if not old_text or old_text not in config_content:
        return None
    return config_content.replace(old_text, new_text, 1)


def main():
    parser = argparse.ArgumentParser(description="Automated CLAUDE.md mutation loop")
    parser.add_argument("--target", type=Path, required=True, help="Config file to mutate")
    parser.add_argument("--scenarios-file", type=Path, required=True, help="Path to scenarios YAML")
    parser.add_argument("--max-iterations", type=int, default=5, help="Max mutation attempts")
    parser.add_argument("--runs", type=int, default=3, help="Runs per scenario for majority vote")
    parser.add_argument("--model", default="sonnet", help="Model for behavioral tests")
    parser.add_argument("--timeout", type=int, default=240, help="Per-call claude -p timeout in seconds (default: 240)")
    parser.add_argument("--scenarios", nargs="*", help="Scenario IDs to focus on")
    parser.add_argument("--apply", action="store_true", help="Apply winning mutations (default: dry-run)")
    parser.add_argument("--workers", type=int, default=0, help="Override worker count for behavioral eval")
    parser.add_argument("--no-judge-cache", action="store_true", help="Disable judge verdict cache during eval")
    parser.add_argument("--no-cache", action="store_true", dest="no_judge_cache",
                        help="Alias for --no-judge-cache")
    parser.add_argument("--no-subject-cache", action="store_true", help="Disable exact-input subject response cache")
    parser.add_argument("--neutral-strategy", choices=["revert", "keep", "size"],
                        default="revert", help="How to handle neutral (delta=0) mutations: revert (default), keep, or size (keep if response is smaller)")
    parser.add_argument("--no-boundary-check", action="store_true",
                        help="Skip frontmatter and mutation size validation")

    args = parser.parse_args()
    RESULTS_DIR.mkdir(exist_ok=True)

    mode = "APPLY" if args.apply else "DRY-RUN"
    backup_path = None
    if args.apply:
        backup_path = args.target.with_suffix(args.target.suffix + ".bak")
        shutil.copy2(args.target, backup_path)

    print(f"Mutation loop — {mode} mode")
    if backup_path:
        print(f"Backup: {backup_path}")
    print(f"Target: {args.target}")
    print(f"Scenarios: {args.scenarios_file}")
    print(f"Max iterations: {args.max_iterations}")
    print(f"Runs per scenario: {args.runs}")
    print(f"Model: {args.model}")

    t_start = time.time()
    stats = {"kept": 0, "reverted": 0, "neutral": 0, "failed": 0}

    print(f"\n{'=' * 60}")
    print("  Baseline evaluation")
    print(f"{'=' * 60}")
    baseline_results = run_eval(
        args.target,
        args.scenarios_file,
        args.scenarios,
        args.runs,
        args.model,
        args.timeout,
        args.workers,
        args.no_judge_cache,
        args.no_subject_cache,
    )
    baseline_passed = baseline_results["summary"]["passed"]
    baseline_total = baseline_results["summary"]["total"]
    print(f"  Baseline: {baseline_passed}/{baseline_total} ({_fmt_elapsed(t_start)})")

    failing = find_failing_scenarios(baseline_results)
    if not failing:
        print("\n  All scenarios passing — nothing to mutate.")
        return

    print(f"  Failing: {', '.join(s['id'] for s in failing)}")

    iteration_log = []
    current_content = args.target.read_text()
    any_mutations_kept = False

    for i in range(1, args.max_iterations + 1):
        if not failing:
            print(f"\n  All scenarios passing after {i - 1} iterations.")
            break

        target_scenario = failing[0]
        print(f"\n{'=' * 60}")
        print(f"  Iteration {i}/{args.max_iterations} — targeting: {target_scenario['id']} ({_fmt_elapsed(t_start)})")
        print(f"{'=' * 60}")

        _progress(i, args.max_iterations, target_scenario["id"], "generating", t_start, stats)
        print("  Generating mutation...", end="", flush=True)
        t0 = time.time()
        mutation = generate_mutation(current_content, target_scenario, args.scenarios_file)
        elapsed = time.time() - t0
        print(f" done ({elapsed:.1f}s)")

        if not mutation:
            print("  Failed to generate valid mutation. Skipping.")
            stats["failed"] += 1
            iteration_log.append({"iteration": i, "target": target_scenario["id"],
                                  "result": "generation_failed"})
            failing = failing[1:]
            continue

        print(f"  Section: {mutation.get('section', 'unknown')}")
        print(f"  Change: {mutation.get('change_description', 'no description')}")

        mutated_content = apply_mutation(current_content, mutation)
        if mutated_content is None:
            print("  old_text not found in config. Skipping.")
            stats["failed"] += 1
            iteration_log.append({"iteration": i, "target": target_scenario["id"],
                                  "result": "text_not_found", "mutation": mutation})
            failing = failing[1:]
            continue

        if not args.no_boundary_check:
            if not is_frontmatter_safe(mutation.get("old_text", ""), current_content):
                print("  Mutation targets frontmatter — rejecting for safety.")
                stats["failed"] += 1
                iteration_log.append({"iteration": i, "target": target_scenario["id"],
                                      "result": "frontmatter_unsafe", "mutation": mutation})
                failing = failing[1:]
                continue
            if not validate_post_mutation(mutated_content):
                print("  Mutation would corrupt YAML frontmatter — rejecting.")
                stats["failed"] += 1
                iteration_log.append({"iteration": i, "target": target_scenario["id"],
                                      "result": "syntax_invalid", "mutation": mutation})
                failing = failing[1:]
                continue
            if not is_mutation_bounded(mutation.get("old_text", ""), mutation.get("new_text", "")):
                print(f"  Mutation too large ({len(mutation.get('new_text', ''))} chars) — rejecting.")
                stats["failed"] += 1
                iteration_log.append({"iteration": i, "target": target_scenario["id"],
                                      "result": "mutation_too_large", "mutation": mutation})
                failing = failing[1:]
                continue

        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write(mutated_content)
            mutated_path = Path(f.name)

        try:
            _progress(i, args.max_iterations, target_scenario["id"], "A/B test", t_start, stats)
            scoped_scenario_ids = [target_scenario["id"]]
            print(f"  Scoped eval (mutated only: {target_scenario['id']})...", flush=True)
            mutated_results = run_eval(
                mutated_path,
                args.scenarios_file,
                scoped_scenario_ids,
                args.runs,
                args.model,
                args.timeout,
                args.workers,
                args.no_judge_cache,
                args.no_subject_cache,
            )
            delta = delta_for_scenario(baseline_results, mutated_results, target_scenario["id"])
            print(f"  Delta: {delta:+d}")

            decision = decide_mutation(delta, baseline_size=0, mutated_size=0, strategy=args.neutral_strategy)

            # Map decision to result for logging
            result_map = {
                "keep": "keep",
                "neutral_keep": "neutral",
                "revert": "revert",
                "neutral_revert": "neutral",
            }
            entry = {
                "iteration": i,
                "target": target_scenario["id"],
                "mutation": mutation,
                "delta": delta,
                "result": result_map.get(decision, "unknown"),
            }
            iteration_log.append(entry)

            if decision in ("keep", "neutral_keep"):
                if decision == "keep":
                    stats["kept"] += 1
                else:
                    stats["neutral"] += 1
                any_mutations_kept = True
                print(f"  KEEP — delta: {delta:+d} ({decision})")
                if args.apply:
                    args.target.write_text(mutated_content)
                    current_content = mutated_content
                    print(f"  Applied mutation to {args.target}")
                else:
                    print("  (dry-run — mutation NOT applied)")
                    current_content = mutated_content
                for updated_scenario in mutated_results.get("scenarios", []):
                    for idx, existing in enumerate(baseline_results.get("scenarios", [])):
                        if existing.get("id") == updated_scenario.get("id"):
                            baseline_results["scenarios"][idx] = updated_scenario
                            break
            else:
                if decision == "neutral_revert":
                    stats["neutral"] += 1
                    print("  NEUTRAL — delta: 0 (not keeping)")
                else:
                    stats["reverted"] += 1
                    print(f"  REVERT — delta: {delta:+d}")
            _progress(i, args.max_iterations, target_scenario["id"], "done", t_start, stats)
        finally:
            mutated_path.unlink(missing_ok=True)

        if args.apply and decision in ("keep", "neutral_keep"):
            _progress(i, args.max_iterations, target_scenario["id"], "full-suite validation", t_start, stats)
            print("  Full-suite validation (catch regressions)...", flush=True)
            reeval = run_eval(
                args.target,
                args.scenarios_file,
                args.scenarios,
                args.runs,
                args.model,
                args.timeout,
                args.workers,
                args.no_judge_cache,
                args.no_subject_cache,
            )
            baseline_results = reeval
            failing = find_failing_scenarios(reeval)
        else:
            failing = failing[1:]

    # Final full-suite validation if mutations were kept and not already done
    if args.apply and any_mutations_kept and failing is not None:
        print(f"\n{'=' * 60}")
        print("  Final full-suite validation")
        print(f"{'=' * 60}")
        print("  Running full-suite validation (catch regressions)...", flush=True)
        final_results = run_eval(
            args.target,
            args.scenarios_file,
            args.scenarios,
            args.runs,
            args.model,
            args.timeout,
            args.workers,
            args.no_judge_cache,
            args.no_subject_cache,
        )
        final_passed = final_results["summary"]["passed"]
        final_total = final_results["summary"]["total"]
        print(f"  Final score: {final_passed}/{final_total} ({_fmt_elapsed(t_start)})")
        failing = find_failing_scenarios(final_results)

    _print_summary_table(iteration_log)
    print(f"\n  Total elapsed: {_fmt_elapsed(t_start)}")

    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
    log_path = RESULTS_DIR / f"mutation-log-{ts}.json"
    log_data = {
        "timestamp": ts,
        "target": str(args.target),
        "model": args.model,
        "mode": mode,
        "iterations": iteration_log,
        "summary": {
            "total_iterations": len(iteration_log),
            "kept": sum(1 for e in iteration_log if e["result"] == "keep"),
            "reverted": sum(1 for e in iteration_log if e["result"] == "revert"),
            "neutral": sum(1 for e in iteration_log if e["result"] == "neutral"),
            "failed": sum(1 for e in iteration_log if e["result"] in ("generation_failed", "text_not_found")),
        },
    }
    log_path.write_text(json.dumps(log_data, indent=2))
    print(f"\n  Mutation log saved: {log_path}")
    print(f"  Summary: {log_data['summary']}")


if __name__ == "__main__":
    main()
