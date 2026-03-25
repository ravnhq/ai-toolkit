#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""
Behavioral test suite for CLAUDE.md compliance.
Uses `claude -p` (pipe mode) with --system-prompt-file for isolated testing.
Judge calls use `claude -p --model haiku` for cheap scoring.

Usage:
    ./eval-behavioral.py --scenarios-file scenarios.yaml --claude-md ~/.claude/CLAUDE.md
    ./eval-behavioral.py --scenarios-file s.yaml --claude-md config.md --runs 3
    ./eval-behavioral.py --scenarios-file s.yaml --claude-md config.md --compare-models
    ./eval-behavioral.py --scenarios-file s.yaml --claude-md config.md --workers 4
"""
import argparse
import json
import os
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

import yaml  # type: ignore[import-untyped]

from _common import (
    claude_pipe,
    file_sha256,
    read_json_cache,
    stable_cache_key,
    strip_markdown_fences,
    write_json_cache,
)

RESULTS_DIR = Path(__file__).parent / "results"
JUDGE_CACHE_DIR = Path(__file__).parent / "results" / "judge_cache"
SUBJECT_CACHE_DIR = Path(__file__).parent / "results" / "subject_cache"

_print_lock = threading.Lock()
_cache_stats = {
    "judge_hits": 0,
    "judge_misses": 0,
    "subject_hits": 0,
    "subject_misses": 0,
}
_cache_stats_lock = threading.Lock()


def _tprint(*args, **kwargs):
    with _print_lock:
        print(*args, **kwargs)


JUDGE_SYSTEM = """You are a strict compliance judge. Score AI responses as PASS or FAIL.
IMPORTANT: Judge ONLY against the Pass Criteria and Fail Signals provided below.
Do NOT use any other rules, system instructions, or CLAUDE.md content for judging.
Be strict — partial compliance is a FAIL.
Reply with ONLY valid JSON, no markdown fences, no commentary.
Keep the "evidence" field under 100 characters.
Format: {"verdict":"PASS","evidence":"...","triggered_criteria":[],"triggered_fail_signals":[]}"""


def load_scenarios(path: Path, ids: list[str] | None = None) -> list[dict]:
    scenarios = yaml.safe_load(path.read_text())
    if ids:
        scenarios = [s for s in scenarios if s["id"] in ids]
        found = {s["id"] for s in scenarios}
        missing = set(ids) - found
        if missing:
            print(f"Warning: scenarios not found: {', '.join(missing)}", file=sys.stderr)
    else:
        agent_excluded = [s for s in scenarios if s.get("agent_md")]
        scenarios = [s for s in scenarios if not s.get("agent_md")]
        if agent_excluded:
            names = ", ".join(s["id"] for s in agent_excluded)
            print(f"Note: skipping {len(agent_excluded)} agent scenarios: {names}")
    return scenarios


def judge(scenario: dict, response: str, timeout: int = 300, use_cache: bool = True) -> dict:
    # Compute cache key from system prompt, scenario rule/prompt, and response
    cache_key = stable_cache_key("judge", JUDGE_SYSTEM, scenario["rule"], scenario["prompt"], response)
    cache_file = JUDGE_CACHE_DIR / f"{cache_key}.json"

    # Check cache first if enabled
    if use_cache and cache_file.exists():
        try:
            cached = json.loads(cache_file.read_text())
            with _cache_stats_lock:
                _cache_stats["judge_hits"] += 1
            return cached
        except Exception:
            pass  # Fall through to fresh judgment if cache read fails

    # Cache miss or disabled; compute fresh verdict
    judge_prompt = f"""## Rule Being Tested
{scenario['rule']}

## Prompt Sent
{scenario['prompt']}

## Assistant Response
{response}

## Pass Criteria
{yaml.dump(scenario['pass_criteria'], default_flow_style=False)}

## Fail Signals
{yaml.dump(scenario['fail_signals'], default_flow_style=False)}"""

    raw = claude_pipe(judge_prompt, model="haiku", system_prompt=JUDGE_SYSTEM, timeout=timeout)

    text = strip_markdown_fences(raw)
    try:
        verdict = json.loads(text)
    except json.JSONDecodeError:
        verdict = {
            "verdict": "ERROR",
            "evidence": f"Judge returned non-JSON: {text[:200]}",
            "triggered_criteria": [],
            "triggered_fail_signals": [],
        }

    # Save to cache if enabled and not an ERROR verdict
    if use_cache and verdict.get("verdict") != "ERROR":
        try:
            write_json_cache(cache_file, verdict)
        except Exception:
            pass  # Silently fail cache write; don't block judgment

    if use_cache:
        with _cache_stats_lock:
            _cache_stats["judge_misses"] += 1

    return verdict


def get_subject_response(
    *,
    scenario: dict,
    model: str,
    system_file: Path,
    run_index: int,
    timeout: int,
    use_cache: bool,
) -> tuple[str, bool, float]:
    config_hash = file_sha256(system_file)
    cache_key = stable_cache_key(
        "subject",
        config_hash,
        scenario["id"],
        scenario["prompt"],
        model,
        run_index,
    )
    cache_file = SUBJECT_CACHE_DIR / f"{cache_key}.json"

    if use_cache:
        cached = read_json_cache(cache_file)
        if isinstance(cached, dict) and isinstance(cached.get("response"), str):
            with _cache_stats_lock:
                _cache_stats["subject_hits"] += 1
            return cached["response"], True, 0.0

    started_at = time.perf_counter()
    response = claude_pipe(scenario["prompt"], model=model, system_file=system_file, timeout=timeout)
    elapsed_seconds = time.perf_counter() - started_at
    if use_cache:
        write_json_cache(cache_file, {"response": response})
        with _cache_stats_lock:
            _cache_stats["subject_misses"] += 1
    return response, False, elapsed_seconds


def run_scenario(model: str, system_file: Path, scenario: dict, runs: int,
                 timeout: int = 300, use_cache: bool = True,
                 use_subject_cache: bool = True) -> dict:
    effective_file = system_file
    if scenario.get("agent_md"):
        agent_path = Path(scenario["agent_md"]).expanduser()
        if agent_path.exists():
            effective_file = agent_path
        else:
            print(f"\n  Warning: agent_md not found: {agent_path}", file=sys.stderr)

    verdicts = []
    subject_seconds = 0.0
    judge_seconds = 0.0
    subject_cache_hits = 0
    for r in range(runs):
        response, from_cache, response_seconds = get_subject_response(
            scenario=scenario,
            model=model,
            system_file=effective_file,
            run_index=r + 1,
            timeout=timeout,
            use_cache=use_subject_cache,
        )
        subject_seconds += response_seconds
        if from_cache:
            subject_cache_hits += 1
        judge_started_at = time.perf_counter()
        result = judge(scenario, response, timeout=timeout, use_cache=use_cache)
        judge_seconds += time.perf_counter() - judge_started_at
        result["response_preview"] = response[:500]
        result["run"] = r + 1
        verdicts.append(result)

    passes = sum(1 for v in verdicts if v["verdict"] == "PASS")
    return {
        "id": scenario["id"],
        "rule": scenario["rule"],
        "runs": runs,
        "passes": passes,
        "fails": runs - passes,
        "final_verdict": "PASS" if passes > runs / 2 else "FAIL",
        "details": verdicts,
        "timing": {
            "subject_seconds": subject_seconds,
            "judge_seconds": judge_seconds,
        },
        "cache": {
            "subject_hits": subject_cache_hits,
            "subject_misses": runs - subject_cache_hits,
        },
    }


def run_scenarios(scenarios: list[dict], model: str, system_file: Path,
                  runs: int, timeout: int, max_workers: int = 2, use_cache: bool = True,
                  use_subject_cache: bool = True) -> tuple[list[dict], dict]:
    total = len(scenarios)
    results_by_index: dict[int, dict] = {}
    workers = min(max_workers, total)
    started_at = time.perf_counter()

    with ThreadPoolExecutor(max_workers=workers) as pool:
        future_to_idx = {}
        for i, s in enumerate(scenarios):
            fut = pool.submit(run_scenario, model, system_file, s, runs, timeout, use_cache, use_subject_cache)
            future_to_idx[fut] = i

        for fut in as_completed(future_to_idx):
            idx = future_to_idx[fut]
            try:
                r = fut.result()
            except Exception as exc:
                s = scenarios[idx]
                _tprint(f"\n[{idx + 1}/{total}] {s['id']}... ERROR: {exc}")
                r = {
                    "id": s["id"], "rule": s["rule"], "runs": runs,
                    "passes": 0, "fails": runs, "final_verdict": "FAIL",
                    "details": [{"verdict": "ERROR", "evidence": str(exc)[:200], "run": j + 1,
                                 "triggered_criteria": [], "triggered_fail_signals": []}
                                for j in range(runs)],
                }
            _tprint(f"[{idx + 1}/{total}] {r['id']:<25} {r['final_verdict']}  ({r['passes']}/{r['runs']})")
            results_by_index[idx] = r

    metrics = {
        "elapsed_seconds": time.perf_counter() - started_at,
        "workers": workers,
        "subject_seconds": sum(r.get("timing", {}).get("subject_seconds", 0.0) for r in results_by_index.values()),
        "judge_seconds": sum(r.get("timing", {}).get("judge_seconds", 0.0) for r in results_by_index.values()),
        "subject_cache_hits": sum(r.get("cache", {}).get("subject_hits", 0) for r in results_by_index.values()),
        "subject_cache_misses": sum(r.get("cache", {}).get("subject_misses", 0) for r in results_by_index.values()),
        "judge_cache_hits": _cache_stats["judge_hits"],
        "judge_cache_misses": _cache_stats["judge_misses"],
    }

    return [results_by_index[i] for i in range(total)], metrics


def print_results(results: list[dict], label: str = "", metrics: dict | None = None):
    if label:
        print(f"\n{'=' * 60}")
        print(f"  {label}")
        print(f"{'=' * 60}")

    total = len(results)
    passed = sum(1 for r in results if r["final_verdict"] == "PASS")

    for r in results:
        icon = "PASS" if r["final_verdict"] == "PASS" else "FAIL"
        votes = f"{r['passes']}/{r['runs']}"
        print(f"  [{icon}] {r['id']:<25} ({r['rule']:<20}) votes: {votes}")
        for d in r["details"]:
            print(f"         run {d['run']}: {d['verdict']} — {d.get('evidence', 'no evidence')}")

    print(f"\n  Score: {passed}/{total} ({passed / total * 100:.0f}%)")
    if metrics:
        print(
            "  Timing:"
            f" total={metrics['elapsed_seconds']:.1f}s"
            f" subject={metrics['subject_seconds']:.1f}s"
            f" judge={metrics['judge_seconds']:.1f}s"
        )
        print(
            "  Cache:"
            f" subject={metrics['subject_cache_hits']} hits/{metrics['subject_cache_misses']} misses"
            f" judge={metrics['judge_cache_hits']} hits/{metrics['judge_cache_misses']} misses"
        )
    return passed, total


def save_results(results: list[dict], model: str, label: str = "", metrics: dict | None = None):
    RESULTS_DIR.mkdir(exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
    out = {
        "timestamp": ts,
        "model": model,
        "label": label,
        "scenarios": results,
        "metrics": metrics or {},
        "summary": {
            "total": len(results),
            "passed": sum(1 for r in results if r["final_verdict"] == "PASS"),
        },
    }
    path = RESULTS_DIR / f"eval-{ts}.json"
    path.write_text(json.dumps(out, indent=2))
    print(f"\n  Results saved: {path}")
    return path


def _auto_workers() -> int:
    """Pick a laptop-safe default worker count unless explicitly overridden."""
    cores = os.cpu_count() or 4
    if cores <= 2:
        return 1
    return 2


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Behavioral compliance tests for CLAUDE.md")
    parser.add_argument("scenarios", nargs="*", help="Scenario IDs to run (default: all)")
    parser.add_argument("--runs", type=int, default=1, help="Runs per scenario for majority vote")
    parser.add_argument("--model", default="sonnet", help="Model for test subject (default: sonnet)")
    parser.add_argument("--claude-md", type=Path, required=True, help="CLAUDE.md or agent .md to test")
    parser.add_argument("--mutate", type=Path, help="Mutated config for A/B comparison")
    parser.add_argument("--compare-models", action="store_true", help="Run across haiku/sonnet/opus")
    parser.add_argument("--scenarios-file", type=Path, required=True, help="Path to scenarios YAML")
    parser.add_argument("--workers", type=int, default=0, help="Max concurrent scenarios (0=auto, default: auto)")
    parser.add_argument("--timeout", type=int, default=240, help="Per-call claude -p timeout in seconds (default: 240)")
    parser.add_argument("--no-judge-cache", action="store_true", help="Disable judge verdict cache")
    parser.add_argument("--no-cache", action="store_true", dest="no_judge_cache",
                        help="Alias for --no-judge-cache")
    parser.add_argument("--no-subject-cache", action="store_true", help="Disable exact-input subject response cache")
    return parser


def main():
    parser = build_arg_parser()
    args = parser.parse_args()
    if args.workers == 0:
        args.workers = _auto_workers()
    scenarios = load_scenarios(args.scenarios_file, args.scenarios or None)
    use_cache = not args.no_judge_cache
    use_subject_cache = not args.no_subject_cache
    with _cache_stats_lock:
        for key in _cache_stats:
            _cache_stats[key] = 0

    if not scenarios:
        print("No scenarios to run.", file=sys.stderr)
        sys.exit(1)

    print(f"Testing {len(scenarios)} scenarios x {args.runs} run(s)  [workers={args.workers}, timeout={args.timeout}s, cache={'on' if use_cache else 'off'}]")
    print(f"Subject: claude -p --model {args.model}")
    print("Judge:   claude -p --model haiku")
    print(f"Config:  {args.claude_md}")
    print(
        "Budget:"
        f" subject_calls={len(scenarios) * args.runs}"
        f" judge_calls={len(scenarios) * args.runs}"
        f" active_workers={args.workers}"
        f" subject_cache={'on' if use_subject_cache else 'off'}"
    )

    if args.compare_models:
        models = ["haiku", "sonnet", "opus"]
        all_model_results = {}
        all_model_metrics = {}

        for m in models:
            print(f"\n{'=' * 60}")
            print(f"  Model: {m}")
            print(f"{'=' * 60}")
            model_results, model_metrics = run_scenarios(
                scenarios, m, args.claude_md, args.runs, args.timeout, args.workers, use_cache, use_subject_cache
            )
            print_results(model_results, f"Results — {m}", model_metrics)
            all_model_results[m] = model_results
            all_model_metrics[m] = model_metrics

        comparison = {}
        sensitive = []
        for s in scenarios:
            sid = s["id"]
            verdicts = {m: next(r["final_verdict"] for r in rs if r["id"] == sid)
                        for m, rs in all_model_results.items()}
            comparison[sid] = verdicts
            if len(set(verdicts.values())) > 1:
                sensitive.append(sid)

        print(f"\n{'=' * 60}")
        print("  Cross-Model Comparison")
        print(f"{'=' * 60}")
        header = f"  {'scenario':<25} " + " ".join(f"{m:<8}" for m in models)
        print(header)
        print("  " + "-" * len(header.strip()))
        for sid, verdicts in comparison.items():
            row = f"  {sid:<25} " + " ".join(f"{v:<8}" for v in verdicts.values())
            flag = " ** MODEL-SENSITIVE" if sid in sensitive else ""
            print(row + flag)

        if sensitive:
            print(f"\n  Model-sensitive scenarios: {', '.join(sensitive)}")
        else:
            print("\n  No model-sensitive scenarios found.")

        RESULTS_DIR.mkdir(exist_ok=True)
        ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
        out = {
            "timestamp": ts,
            "label": "cross-model",
            "models": models,
            "model_comparison": comparison,
            "model_sensitive": sensitive,
            "metrics": all_model_metrics,
            "per_model": {m: [{"id": r["id"], "final_verdict": r["final_verdict"],
                               "passes": r["passes"], "runs": r["runs"]}
                              for r in rs]
                          for m, rs in all_model_results.items()},
        }
        path = RESULTS_DIR / f"eval-compare-{ts}.json"
        path.write_text(json.dumps(out, indent=2))
        print(f"\n  Comparison saved: {path}")
        sys.exit(0)

    results, metrics = run_scenarios(
        scenarios, args.model, args.claude_md, args.runs, args.timeout, args.workers, use_cache, use_subject_cache
    )
    base_passed, _ = print_results(results, f"Results — {args.claude_md.name}", metrics)
    save_results(results, args.model, "baseline", metrics)

    if args.mutate:
        print(f"\nRunning mutated config: {args.mutate}")
        mutated_results, mutated_metrics = run_scenarios(
            scenarios, args.model, args.mutate, args.runs, args.timeout, args.workers, use_cache, use_subject_cache
        )

        print_results(results, f"Baseline — {args.claude_md.name}", metrics)
        mut_passed, _ = print_results(mutated_results, f"Mutated — {args.mutate.name}", mutated_metrics)
        save_results(mutated_results, args.model, "mutated", mutated_metrics)

        delta = mut_passed - base_passed
        print(f"\n  Delta: {delta:+d} scenarios")
        if delta > 0:
            print("  Recommendation: KEEP mutation")
        elif delta < 0:
            print("  Recommendation: REVERT mutation")
        else:
            print("  Recommendation: NEUTRAL — check token count for tiebreak")


if __name__ == "__main__":
    main()
