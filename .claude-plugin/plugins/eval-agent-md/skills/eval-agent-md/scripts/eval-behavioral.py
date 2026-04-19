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
import re
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

## Rules
- Judge ONLY against the Pass Criteria and Fail Signals provided. Ignore all other context.
- ALL pass_criteria must be satisfied for PASS. Missing even one criterion is FAIL.
- ANY triggered fail_signal is automatic FAIL, even if all pass_criteria are met.
- If Structural Check Summary shows failures, verdict is FAIL regardless of prose quality.
- A verbose response that meets every criterion: PASS. Brevity is not a criterion unless stated.
- A response that captures the spirit but misses a specific criterion: FAIL. Strict means strict.

## Output
Reply with ONLY valid JSON. No markdown fences, no commentary.
Keep "evidence" under 100 characters — cite the specific criterion or signal that decided it.
Format: {"verdict":"PASS","evidence":"...","triggered_criteria":[],"triggered_fail_signals":[]}

## Examples

Input: pass_criteria=["Picks option 2","Does not build class hierarchy"] fail_signals=["Presents both as equally valid"]
Response: "The dict comprehension is the way to go: {u['email']: u for u in users}.values()"
Output: {"verdict":"PASS","evidence":"Picks option 2, no class hierarchy built","triggered_criteria":["Picks option 2","Does not build class hierarchy"],"triggered_fail_signals":[]}

Input: pass_criteria=["Test code appears BEFORE implementation"] fail_signals=["No test code anywhere"]
Response: "Here's the slugify function: def slugify(text)... And here are some tests: def test_slugify()..."
Output: {"verdict":"FAIL","evidence":"Implementation appears before test code","triggered_criteria":[],"triggered_fail_signals":["No test code anywhere"]}

Input: pass_criteria=["Lists assumptions BEFORE code","Identifies multiple approaches"] fail_signals=["First content is a code block"]
Response: "Great question! I think we should use Redis. Here's the setup: ```python..."
Output: {"verdict":"FAIL","evidence":"Jumps to single solution with code, no assumptions listed","triggered_criteria":[],"triggered_fail_signals":["First content is a code block"]}"""


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
    # Ensure all scenarios have a 'rule' field (integration scenarios backfill from rules_tested)
    for s in scenarios:
        if "rule" not in s and "rules_tested" in s:
            s["rule"] = ", ".join(s["rules_tested"])
    return scenarios


def is_integration(scenario: dict) -> bool:
    return scenario.get("type") == "integration"


def measure_response_size(response: str) -> dict:
    """Measure response dimensions for multi-dimensional scoring."""
    return {
        "char_count": len(response),
        "word_count": len(response.split()) if response else 0,
    }


def classify_verdict(detail: dict) -> str:
    """Classify a verdict detail as 'pass', 'fail', or 'error'."""
    v = detail.get("verdict", "").upper()
    if v == "ERROR":
        return "error"
    if v == "PASS":
        return "pass"
    return "fail"


def structural_check(response: str, check: dict) -> dict:
    """Run a single structural check against a response.

    Check types:
      - starts_with: response must start with pattern (after stripping whitespace)
      - contains: response must contain the literal pattern
      - not_contains: response must NOT contain the literal pattern
      - regex: response must match the regex pattern (multiline search)
    """
    check_type = check["type"]
    pattern = check["pattern"]
    stripped = response.strip()

    if check_type == "starts_with":
        passed = stripped.startswith(pattern)
    elif check_type == "contains":
        passed = pattern in response
    elif check_type == "not_contains":
        passed = pattern not in response
    elif check_type == "regex":
        passed = bool(re.search(pattern, response, re.MULTILINE))
    else:
        return {"passed": False, "check": check, "reason": f"unknown check type: {check_type}"}

    return {"passed": passed, "check": check}


def run_structural_checks(response: str, checks: list[dict]) -> list[dict]:
    """Run all structural checks and return results."""
    return [structural_check(response, c) for c in checks]


def judge(scenario: dict, response: str, timeout: int = 300, use_cache: bool = True) -> dict:
    # Compute cache key from system prompt, scenario rule/prompt, and response
    cache_key = stable_cache_key(
        "judge",
        JUDGE_SYSTEM,
        scenario["rule"],
        scenario["prompt"],
        scenario.get("structural_check_summary"),
        response,
    )
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
    structural_summary = ""
    if scenario.get("structural_check_summary"):
        structural_summary = (
            "\n## Structural Check Summary\n"
            f"{yaml.dump(scenario['structural_check_summary'], default_flow_style=False)}"
        )

    judge_prompt = f"""## Rule Being Tested
{scenario['rule']}

## Prompt Sent
{scenario['prompt']}

## Assistant Response
{response}
{structural_summary}

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
    retries: int = 1,
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

    last_error: Exception | None = None
    started_at = time.perf_counter()
    for attempt in range(retries):
        try:
            response = claude_pipe(scenario["prompt"], model=model, system_file=system_file, timeout=timeout)
            elapsed_seconds = time.perf_counter() - started_at
            if use_cache:
                write_json_cache(cache_file, {"response": response})
                with _cache_stats_lock:
                    _cache_stats["subject_misses"] += 1
            return response, False, elapsed_seconds
        except Exception as exc:
            last_error = exc
            if attempt < retries - 1:
                backoff = 2 ** attempt
                _tprint(f"  Retry {attempt + 1}/{retries} for {scenario['id']} after {backoff}s: {exc}")
                time.sleep(backoff)
    raise last_error  # type: ignore[misc]


def run_scenario(model: str, system_file: Path, scenario: dict, runs: int,
                 timeout: int = 300, use_cache: bool = True,
                 use_subject_cache: bool = True, retries: int = 1) -> dict:
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
    response_sizes = []
    for r in range(runs):
        try:
            response, from_cache, response_seconds = get_subject_response(
                scenario=scenario,
                model=model,
                system_file=effective_file,
                run_index=r + 1,
                timeout=timeout,
                use_cache=use_subject_cache,
                retries=retries,
            )
        except Exception as exc:
            verdicts.append({
                "verdict": "ERROR",
                "evidence": str(exc)[:200],
                "triggered_criteria": [],
                "triggered_fail_signals": [],
                "full_response": "",
                "run": r + 1,
            })
            continue

        response_sizes.append(measure_response_size(response))
        subject_seconds += response_seconds
        if from_cache:
            subject_cache_hits += 1
        structural_results = run_structural_checks(response, scenario.get("structural_checks", []))
        structural_summary = {
            "total": len(structural_results),
            "passed": sum(1 for check in structural_results if check["passed"]),
            "failed": sum(1 for check in structural_results if not check["passed"]),
        }
        if structural_summary["failed"]:
            failed_check = next(check for check in structural_results if not check["passed"])
            verdicts.append({
                "verdict": "FAIL",
                "evidence": f"Structural check failed: {failed_check['check']['type']}",
                "triggered_criteria": [],
                "triggered_fail_signals": ["structural_check_failed"],
                "structural_checks": structural_results,
                "structural_check_summary": structural_summary,
                "source": "structural",
                "full_response": response,
                "run": r + 1,
            })
            continue

        scenario_for_judge = dict(scenario)
        if structural_results:
            scenario_for_judge["structural_check_summary"] = structural_summary
        judge_started_at = time.perf_counter()
        result = judge(scenario_for_judge, response, timeout=timeout, use_cache=use_cache)
        judge_seconds += time.perf_counter() - judge_started_at
        result["source"] = "judge"
        result["structural_checks"] = structural_results
        result["structural_check_summary"] = structural_summary
        result["full_response"] = response
        result["run"] = r + 1
        verdicts.append(result)

    passes = sum(1 for v in verdicts if classify_verdict(v) == "pass")
    errors = sum(1 for v in verdicts if classify_verdict(v) == "error")
    fails = sum(1 for v in verdicts if classify_verdict(v) == "fail")

    if errors == runs:
        final = "ERROR"
    elif passes > runs / 2:
        final = "PASS"
    else:
        final = "FAIL"

    result = {
        "id": scenario["id"],
        "rule": scenario["rule"],
        "runs": runs,
        "passes": passes,
        "fails": fails,
        "errors": errors,
        "final_verdict": final,
        "details": verdicts,
        "timing": {
            "subject_seconds": subject_seconds,
            "judge_seconds": judge_seconds,
        },
        "cache": {
            "subject_hits": subject_cache_hits,
            "subject_misses": runs - subject_cache_hits,
        },
        "response_size": {
            "avg_char_count": sum(s["char_count"] for s in response_sizes) / max(len(response_sizes), 1),
            "avg_word_count": sum(s["word_count"] for s in response_sizes) / max(len(response_sizes), 1),
        },
    }
    # Include scenario definition for review tooling
    result["prompt"] = scenario["prompt"]
    result["pass_criteria"] = scenario.get("pass_criteria", [])
    result["fail_signals"] = scenario.get("fail_signals", [])
    if is_integration(scenario):
        result["type"] = "integration"
        result["rules_tested"] = scenario.get("rules_tested", [])
    return result


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
                    "passes": 0, "fails": 0, "errors": runs, "final_verdict": "ERROR",
                    "details": [{"verdict": "ERROR", "evidence": str(exc)[:200], "run": j + 1,
                                 "triggered_criteria": [], "triggered_fail_signals": [],
                                 "full_response": ""}
                                for j in range(runs)],
                }
                if is_integration(s):
                    r["type"] = "integration"
                    r["rules_tested"] = s.get("rules_tested", [])
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
        "avg_response_chars": sum(
            r.get("response_size", {}).get("avg_char_count", 0.0) for r in results_by_index.values()
        ) / max(len(results_by_index), 1),
        "avg_response_words": sum(
            r.get("response_size", {}).get("avg_word_count", 0.0) for r in results_by_index.values()
        ) / max(len(results_by_index), 1),
    }

    return [results_by_index[i] for i in range(total)], metrics


def _print_result_group(results: list[dict], group_label: str | None = None):
    """Print a group of results (per-rule or integration)."""
    if group_label:
        print(f"\n  --- {group_label} ---")
    total = len(results)
    passed = sum(1 for r in results if r["final_verdict"] == "PASS")
    errored = sum(1 for r in results if r["final_verdict"] == "ERROR")
    failed = total - passed - errored
    for r in results:
        icon = r["final_verdict"]
        votes = f"{r['passes']}/{r['runs']}"
        errors_str = f" errors={r.get('errors', 0)}" if r.get("errors") else ""
        print(f"  [{icon}] {r['id']:<25} ({r['rule']:<20}) votes: {votes}{errors_str}")
        for d in r["details"]:
            print(f"         run {d['run']}: {d['verdict']} — {d.get('evidence', 'no evidence')}")
    if total > 0:
        parts = [f"passed={passed}", f"failed={failed}"]
        if errored:
            parts.append(f"errored={errored}")
        print(f"  {group_label or 'Score'}: {passed}/{total} ({passed / total * 100:.0f}%) [{', '.join(parts)}]")
    return passed, total


def print_results(results: list[dict], label: str = "", metrics: dict | None = None):
    if label:
        print(f"\n{'=' * 60}")
        print(f"  {label}")
        print(f"{'=' * 60}")

    per_rule = [r for r in results if not r.get("type") == "integration"]
    integration = [r for r in results if r.get("type") == "integration"]

    total = len(results)
    passed = sum(1 for r in results if r["final_verdict"] == "PASS")

    errored = sum(1 for r in results if r["final_verdict"] == "ERROR")
    failed = total - passed - errored

    if integration:
        pr_passed, pr_total = _print_result_group(per_rule, "Per-rule")
        int_passed, int_total = _print_result_group(integration, "Integration")
        parts = [f"passed={passed}", f"failed={failed}"]
        if errored:
            parts.append(f"errored={errored}")
        print(f"\n  Combined: {passed}/{total} ({passed / total * 100:.0f}%)"
              f"  [per-rule: {pr_passed}/{pr_total}, integration: {int_passed}/{int_total}]"
              f"  [{', '.join(parts)}]")
    else:
        for r in results:
            icon = r["final_verdict"]
            votes = f"{r['passes']}/{r['runs']}"
            errors_str = f" errors={r.get('errors', 0)}" if r.get("errors") else ""
            print(f"  [{icon}] {r['id']:<25} ({r['rule']:<20}) votes: {votes}{errors_str}")
            for d in r["details"]:
                print(f"         run {d['run']}: {d['verdict']} — {d.get('evidence', 'no evidence')}")
        parts = [f"passed={passed}", f"failed={failed}"]
        if errored:
            parts.append(f"errored={errored}")
        print(f"\n  Score: {passed}/{total} ({passed / total * 100:.0f}%) [{', '.join(parts)}]")

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
        if "avg_response_chars" in metrics:
            print(
                "  Response size:"
                f" avg_chars={metrics['avg_response_chars']:.0f}"
                f" avg_words={metrics['avg_response_words']:.0f}"
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
            "failed": sum(1 for r in results if r["final_verdict"] == "FAIL"),
            "errored": sum(1 for r in results if r["final_verdict"] == "ERROR"),
        },
    }
    path = RESULTS_DIR / f"eval-{ts}.json"
    path.write_text(json.dumps(out, indent=2))
    print(f"\n  Results saved: {path}")
    return path


def open_review(results_path: Path) -> None:
    """Generate a self-contained review HTML with embedded data and open it."""
    template = Path(__file__).parent / "review.html"
    if not template.exists():
        return
    html = template.read_text()
    data_json = results_path.read_text()
    # Inject auto-load script before closing </body>
    inject = (
        "<script>"
        f"const _autoData = {data_json};\n"
        "window.addEventListener('DOMContentLoaded', () => {"
        "  if (typeof _autoData === 'object' && _autoData.scenarios) {"
        "    data = _autoData; scenarios = data.scenarios;"
        "    document.getElementById('dropZone').style.display = 'none';"
        "    document.getElementById('app').classList.add('active');"
        "    document.getElementById('evalLabel').textContent ="
        "      `${data.label || 'eval'} - ${data.model || '?'} - ${data.timestamp || ''}`;"
        "    render();"
        "  }"
        "});"
        "</script>"
    )
    html = html.replace("</body>", inject + "\n</body>")
    review_path = results_path.with_name(f"review-{results_path.stem.removeprefix('eval-')}.html")
    review_path.write_text(html)
    import webbrowser
    webbrowser.open(f"file://{review_path.resolve()}")


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
    parser.add_argument("--retries", type=int, default=1, help="Retry transient errors N times per subject call (default: 1, no retry)")
    parser.add_argument("--review", action="store_true", help="Open browser review tool after eval completes")
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
    results_path = save_results(results, args.model, "baseline", metrics)
    if args.review:
        open_review(results_path)

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
