import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPTS_DIR = Path(__file__).resolve().parent


def load_script_module(name: str, filename: str):
    if str(SCRIPTS_DIR) not in sys.path:
        sys.path.insert(0, str(SCRIPTS_DIR))
    spec = importlib.util.spec_from_file_location(name, SCRIPTS_DIR / filename)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class EvalBehavioralTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.eval_behavioral = load_script_module("eval_behavioral", "eval-behavioral.py")

    def test_auto_workers_caps_high_resource_machine_at_two(self):
        with mock.patch.object(self.eval_behavioral.os, "cpu_count", return_value=32):
            workers = self.eval_behavioral._auto_workers()

        self.assertEqual(workers, 2)

    def test_parser_accepts_no_judge_cache_flag(self):
        parser = self.eval_behavioral.build_arg_parser()

        args = parser.parse_args(
            [
                "--claude-md", "config.md",
                "--scenarios-file", "scenarios.yaml",
                "--no-judge-cache",
            ]
        )

        self.assertTrue(args.no_judge_cache)

    def test_parser_keeps_no_cache_as_alias_for_no_judge_cache(self):
        parser = self.eval_behavioral.build_arg_parser()

        args = parser.parse_args(
            [
                "--claude-md", "config.md",
                "--scenarios-file", "scenarios.yaml",
                "--no-cache",
            ]
        )

        self.assertTrue(args.no_judge_cache)


class MutateLoopTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mutate_loop = load_script_module("mutate_loop", "mutate-loop.py")

    def test_scenario_pass_count_returns_zero_when_missing(self):
        results = {"scenarios": [{"id": "other", "passes": 1}]}

        count = self.mutate_loop.scenario_pass_count(results, "target")

        self.assertEqual(count, 0)

    def test_delta_for_scenario_compares_mutated_against_baseline(self):
        baseline = {"scenarios": [{"id": "target", "passes": 0}]}
        mutated = {"scenarios": [{"id": "target", "passes": 1}]}

        delta = self.mutate_loop.delta_for_scenario(baseline, mutated, "target")

        self.assertEqual(delta, 1)


class GenerateScenariosTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.generate_scenarios = load_script_module("generate_scenarios", "generate-scenarios.py")

    def test_parser_accepts_no_scenario_cache_flag(self):
        parser = self.generate_scenarios.build_arg_parser()

        args = parser.parse_args(["config.md", "--no-scenario-cache"])

        self.assertTrue(args.no_scenario_cache)


class CommonCacheTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.common = load_script_module("eval_common", "_common.py")

    def test_cache_key_changes_when_run_index_changes(self):
        key1 = self.common.stable_cache_key("config-hash", "scenario-a", "prompt", "sonnet", 1)
        key2 = self.common.stable_cache_key("config-hash", "scenario-a", "prompt", "sonnet", 2)

        self.assertNotEqual(key1, key2)

    def test_cache_round_trip_reads_same_payload(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            cache_file = Path(tmpdir) / "entry.json"
            payload = {"value": "cached-response"}

            self.common.write_json_cache(cache_file, payload)
            restored = self.common.read_json_cache(cache_file)

        self.assertEqual(restored, payload)


class MutateLoopBoundaryTests(unittest.TestCase):
    """Tests for safe modification boundaries and bounded mutations."""

    @classmethod
    def setUpClass(cls):
        cls.mutate_loop = load_script_module("mutate_loop_boundary", "mutate-loop.py")

    def test_is_frontmatter_safe_rejects_mutation_in_frontmatter(self):
        content = "---\nname: my-skill\nstatus: ready\n---\n\n# Rules\nDo stuff"
        old_text = "status: ready"

        result = self.mutate_loop.is_frontmatter_safe(old_text, content)

        self.assertFalse(result)

    def test_is_frontmatter_safe_allows_mutation_in_body(self):
        content = "---\nname: my-skill\n---\n\n# Rules\nDo stuff carefully"
        old_text = "Do stuff carefully"

        result = self.mutate_loop.is_frontmatter_safe(old_text, content)

        self.assertTrue(result)

    def test_is_frontmatter_safe_allows_mutation_when_no_frontmatter(self):
        content = "# Rules\nDo stuff carefully"
        old_text = "Do stuff carefully"

        result = self.mutate_loop.is_frontmatter_safe(old_text, content)

        self.assertTrue(result)

    def test_validate_post_mutation_accepts_valid_frontmatter(self):
        content = "---\nname: my-skill\nstatus: ready\n---\n\n# Body"

        result = self.mutate_loop.validate_post_mutation(content)

        self.assertTrue(result)

    def test_validate_post_mutation_rejects_broken_yaml(self):
        content = "---\nname: my-skill\n  bad indent:\n    - [unclosed\n---\n\n# Body"

        result = self.mutate_loop.validate_post_mutation(content)

        self.assertFalse(result)

    def test_validate_post_mutation_accepts_content_without_frontmatter(self):
        content = "# Just a plain markdown file\nWith some rules"

        result = self.mutate_loop.validate_post_mutation(content)

        self.assertTrue(result)

    def test_is_mutation_bounded_accepts_small_change(self):
        old_text = "Do stuff carefully"
        new_text = "Do stuff very carefully"

        result = self.mutate_loop.is_mutation_bounded(old_text, new_text)

        self.assertTrue(result)

    def test_is_mutation_bounded_rejects_complete_rewrite(self):
        old_text = "Do stuff carefully"
        new_text = "Completely different text that replaces everything with a totally new approach to the problem"

        result = self.mutate_loop.is_mutation_bounded(old_text, new_text)

        self.assertFalse(result)

    def test_is_mutation_bounded_respects_max_chars(self):
        old_text = "short"
        new_text = "a" * 300

        result = self.mutate_loop.is_mutation_bounded(old_text, new_text, max_chars=200)

        self.assertFalse(result)


class MutateLoopDecisionTests(unittest.TestCase):
    """Tests for tiebreak decision logic."""

    @classmethod
    def setUpClass(cls):
        cls.mutate_loop = load_script_module("mutate_loop_decision", "mutate-loop.py")

    def test_decide_mutation_keeps_positive_delta(self):
        result = self.mutate_loop.decide_mutation(delta=1, baseline_size=100, mutated_size=100, strategy="revert")

        self.assertEqual(result, "keep")

    def test_decide_mutation_reverts_negative_delta(self):
        result = self.mutate_loop.decide_mutation(delta=-1, baseline_size=100, mutated_size=50, strategy="revert")

        self.assertEqual(result, "revert")

    def test_decide_mutation_neutral_reverts_by_default(self):
        result = self.mutate_loop.decide_mutation(delta=0, baseline_size=100, mutated_size=100, strategy="revert")

        self.assertEqual(result, "neutral_revert")

    def test_decide_mutation_neutral_keeps_with_keep_strategy(self):
        result = self.mutate_loop.decide_mutation(delta=0, baseline_size=100, mutated_size=100, strategy="keep")

        self.assertEqual(result, "neutral_keep")

    def test_decide_mutation_neutral_keeps_smaller_response_with_size_strategy(self):
        result = self.mutate_loop.decide_mutation(delta=0, baseline_size=200, mutated_size=100, strategy="size")

        self.assertEqual(result, "neutral_keep")

    def test_decide_mutation_neutral_reverts_larger_response_with_size_strategy(self):
        result = self.mutate_loop.decide_mutation(delta=0, baseline_size=100, mutated_size=200, strategy="size")

        self.assertEqual(result, "neutral_revert")


class GenerateScenariosRuleExtractionTests(unittest.TestCase):
    """Tests for coverage reporting via rule extraction."""

    @classmethod
    def setUpClass(cls):
        cls.gen = load_script_module("generate_scenarios_rules", "generate-scenarios.py")

    def test_extract_rule_names_finds_h2_sections(self):
        content = "# Title\n\n## GATE-1 Think\nstuff\n\n## TDD\nmore stuff\n\n## SURGICAL\nother"

        rules = self.gen.extract_rule_names(content)

        self.assertIn("GATE-1 Think", rules)
        self.assertIn("TDD", rules)
        self.assertIn("SURGICAL", rules)

    def test_extract_rule_names_skips_non_rule_sections(self):
        content = "# Title\n\n## Examples\nstuff\n\n## Troubleshooting\nmore"

        rules = self.gen.extract_rule_names(content)

        self.assertEqual(rules, [])

    def test_compute_coverage_returns_full_coverage(self):
        rules = ["GATE-1", "TDD"]
        scenarios = [
            {"id": "gate1", "rule": "GATE-1", "rule_id": "gate_1"},
            {"id": "tdd", "rule": "TDD", "rule_id": "tdd"},
        ]

        result = self.gen.compute_coverage(rules, scenarios)

        self.assertEqual(result["coverage_pct"], 100.0)
        self.assertEqual(result["untested"], [])

    def test_compute_coverage_detects_untested_rules(self):
        rules = ["GATE-1", "TDD", "SURGICAL"]
        scenarios = [
            {"id": "gate1", "rule": "GATE-1", "rule_id": "gate_1"},
        ]

        result = self.gen.compute_coverage(rules, scenarios)

        self.assertIn("TDD", result["untested"])
        self.assertIn("SURGICAL", result["untested"])
        self.assertAlmostEqual(result["coverage_pct"], 33.3, places=0)


class GenerateScenariosCoverageMetadataTests(unittest.TestCase):
    """Tests for stable rule IDs and deterministic coverage reporting."""

    @classmethod
    def setUpClass(cls):
        cls.gen = load_script_module("generate_scenarios_coverage", "generate-scenarios.py")

    def test_extract_rules_returns_rule_ids(self):
        content = "# Title\n\n## GATE-1 Think\nstuff\n\n## TDD\nmore stuff"

        rules = self.gen.extract_rules(content)

        self.assertEqual(
            rules,
            [
                {"rule_id": "gate_1_think", "rule_name": "GATE-1 Think"},
                {"rule_id": "tdd", "rule_name": "TDD"},
            ],
        )

    def test_compute_coverage_tracks_structural_and_llm_only_rules(self):
        rules = [
            {"rule_id": "gate_1_think", "rule_name": "GATE-1 Think"},
            {"rule_id": "tdd", "rule_name": "TDD"},
            {"rule_id": "surgical", "rule_name": "SURGICAL"},
        ]
        scenarios = [
            {
                "id": "gate1",
                "rule": "GATE-1 Think",
                "rule_id": "gate_1_think",
                "structural_checks": [{"type": "starts_with", "pattern": "## Assumptions"}],
            },
            {
                "id": "integration_gate1_tdd",
                "type": "integration",
                "rule": "GATE-1 Think, TDD",
                "rule_ids_tested": ["gate_1_think", "tdd"],
            },
        ]

        result = self.gen.compute_coverage(rules, scenarios)

        self.assertEqual(result["rules_found"], 3)
        self.assertEqual(result["rules_tested"], 2)
        self.assertEqual(result["rules_with_structural_checks"], 1)
        self.assertEqual(result["coverage_pct"], 66.66666666666666)
        self.assertEqual(result["untested_rule_ids"], ["surgical"])
        self.assertEqual(result["llm_only_rule_ids"], ["tdd"])

    def test_compute_coverage_is_unavailable_when_no_rules_discovered(self):
        result = self.gen.compute_coverage([], [])

        self.assertIsNone(result["coverage_pct"])
        self.assertEqual(result["coverage_status"], "unavailable")

    def test_normalize_per_rule_scenario_derives_rule_id_from_catalog(self):
        rules = [
            {"rule_id": "gate_1_think", "rule_name": "GATE-1 Think"},
            {"rule_id": "tdd", "rule_name": "TDD"},
        ]
        scenario = {
            "id": "gate1",
            "rule": "GATE-1 Think",
            "prompt": "Add caching",
            "pass_criteria": ["Starts with assumptions"],
            "fail_signals": ["Jumps to code"],
        }

        normalized = self.gen.normalize_scenario(scenario, rules)

        self.assertEqual(normalized["rule_id"], "gate_1_think")

    def test_normalize_integration_scenario_derives_rule_ids_from_rule_names(self):
        rules = [
            {"rule_id": "gate_1_think", "rule_name": "GATE-1 Think"},
            {"rule_id": "tdd", "rule_name": "TDD"},
            {"rule_id": "rhythm", "rule_name": "Rhythm"},
        ]
        scenario = {
            "id": "integration_gate1_tdd",
            "type": "integration",
            "rules_tested": ["GATE-1 Think", "TDD"],
            "prompt": "Proceed",
            "pass_criteria": ["Keeps ordering"],
            "fail_signals": ["Drops a rule"],
        }

        normalized = self.gen.normalize_integration_scenario(scenario, rules)

        self.assertEqual(normalized["rule_ids_tested"], ["gate_1_think", "tdd"])


class EvalBehavioralMetricsTests(unittest.TestCase):
    """Tests for multi-dimensional metrics (response size)."""

    @classmethod
    def setUpClass(cls):
        cls.eval_behavioral = load_script_module("eval_behavioral_metrics", "eval-behavioral.py")

    def test_measure_response_size_counts_chars_and_words(self):
        response = "Hello world, this is a test response."

        result = self.eval_behavioral.measure_response_size(response)

        self.assertEqual(result["char_count"], len(response))
        self.assertEqual(result["word_count"], 7)

    def test_measure_response_size_handles_empty(self):
        result = self.eval_behavioral.measure_response_size("")

        self.assertEqual(result["char_count"], 0)
        self.assertEqual(result["word_count"], 0)


class EvalBehavioralErrorSeparationTests(unittest.TestCase):
    """Tests for ERROR vs FAIL distinction and retry logic."""

    @classmethod
    def setUpClass(cls):
        cls.eb = load_script_module("eval_behavioral_error", "eval-behavioral.py")

    def test_classify_verdict_returns_error_for_error_verdict(self):
        detail = {"verdict": "ERROR", "evidence": "timeout"}

        result = self.eb.classify_verdict(detail)

        self.assertEqual(result, "error")

    def test_classify_verdict_returns_pass_for_pass(self):
        detail = {"verdict": "PASS", "evidence": "all good"}

        result = self.eb.classify_verdict(detail)

        self.assertEqual(result, "pass")

    def test_classify_verdict_returns_fail_for_fail(self):
        detail = {"verdict": "FAIL", "evidence": "nope"}

        result = self.eb.classify_verdict(detail)

        self.assertEqual(result, "fail")

    def test_run_scenario_separates_errors_from_fails(self):
        """run_scenario result must have 'errors' count separate from 'fails'."""
        scenario = {
            "id": "test_err", "rule": "test", "prompt": "hello",
            "pass_criteria": ["responds"], "fail_signals": ["silent"],
        }
        # Mock get_subject_response to raise on first call (error), then succeed
        with mock.patch.object(self.eb, "get_subject_response",
                               side_effect=RuntimeError("timeout")):
            with mock.patch.object(self.eb, "judge", return_value={
                "verdict": "ERROR", "evidence": "timeout",
                "triggered_criteria": [], "triggered_fail_signals": [],
            }):
                result = self.eb.run_scenario("sonnet", Path("/tmp/fake.md"), scenario, runs=1)

        self.assertIn("errors", result)
        self.assertEqual(result["errors"], 1)
        # errors should NOT be counted as fails
        self.assertEqual(result["fails"], 0)

    def test_final_verdict_is_error_when_all_runs_error(self):
        """If every run errors, final_verdict should be ERROR, not FAIL."""
        scenario = {
            "id": "test_all_err", "rule": "test", "prompt": "hello",
            "pass_criteria": ["responds"], "fail_signals": ["silent"],
        }
        with mock.patch.object(self.eb, "get_subject_response",
                               side_effect=RuntimeError("timeout")):
            result = self.eb.run_scenario("sonnet", Path("/tmp/fake.md"), scenario, runs=2)

        self.assertEqual(result["final_verdict"], "ERROR")
        self.assertEqual(result["errors"], 2)
        self.assertEqual(result["fails"], 0)

    def test_summary_includes_errored_count(self):
        """save_results summary must include 'errored' alongside 'passed' and 'failed'."""
        results = [
            {"id": "a", "final_verdict": "PASS", "passes": 1, "fails": 0, "errors": 0, "runs": 1, "details": []},
            {"id": "b", "final_verdict": "FAIL", "passes": 0, "fails": 1, "errors": 0, "runs": 1, "details": []},
            {"id": "c", "final_verdict": "ERROR", "passes": 0, "fails": 0, "errors": 1, "runs": 1, "details": []},
        ]
        with tempfile.TemporaryDirectory() as tmpdir:
            with mock.patch.object(self.eb, "RESULTS_DIR", Path(tmpdir)):
                path = self.eb.save_results(results, "sonnet", "test")
                saved = __import__("json").loads(path.read_text())

        self.assertEqual(saved["summary"]["passed"], 1)
        self.assertEqual(saved["summary"]["failed"], 1)
        self.assertEqual(saved["summary"]["errored"], 1)

    def test_response_stored_in_full_not_truncated(self):
        """Verdict details should store full_response, not truncated response_preview."""
        long_response = "x" * 2000
        scenario = {
            "id": "test_full", "rule": "test", "prompt": "hello",
            "pass_criteria": ["responds"], "fail_signals": ["silent"],
        }
        with mock.patch.object(self.eb, "get_subject_response",
                               return_value=(long_response, False, 1.0)):
            with mock.patch.object(self.eb, "judge", return_value={
                "verdict": "PASS", "evidence": "ok",
                "triggered_criteria": [], "triggered_fail_signals": [],
            }):
                result = self.eb.run_scenario("sonnet", Path("/tmp/fake.md"), scenario, runs=1)

        detail = result["details"][0]
        self.assertIn("full_response", detail)
        self.assertEqual(len(detail["full_response"]), 2000)
        self.assertNotIn("response_preview", detail)


class EvalBehavioralRetryTests(unittest.TestCase):
    """Tests for retry-on-transient-error logic."""

    @classmethod
    def setUpClass(cls):
        cls.eb = load_script_module("eval_behavioral_retry", "eval-behavioral.py")

    def test_get_subject_response_retries_on_timeout(self):
        """Should retry transient errors before giving up."""
        call_count = 0

        def fake_claude_pipe(prompt, *, model=None, system_file=None, timeout=300):
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise RuntimeError("Request timed out")
            return "success response"

        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write("# test config")
            tmp_path = Path(f.name)
        try:
            with mock.patch.object(self.eb, "claude_pipe", side_effect=fake_claude_pipe):
                response, from_cache, elapsed = self.eb.get_subject_response(
                    scenario={"id": "retry_test", "prompt": "hello"},
                    model="sonnet",
                    system_file=tmp_path,
                    run_index=1,
                    timeout=240,
                    use_cache=False,
                    retries=3,
                )
        finally:
            tmp_path.unlink(missing_ok=True)

        self.assertEqual(response, "success response")
        self.assertEqual(call_count, 3)

    def test_get_subject_response_raises_after_max_retries(self):
        """Should raise after exhausting retries."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write("# test config")
            tmp_path = Path(f.name)
        try:
            with mock.patch.object(self.eb, "claude_pipe",
                                   side_effect=RuntimeError("Request timed out")):
                with self.assertRaises(RuntimeError):
                    self.eb.get_subject_response(
                        scenario={"id": "retry_fail", "prompt": "hello"},
                        model="sonnet",
                        system_file=tmp_path,
                        run_index=1,
                        timeout=240,
                        use_cache=False,
                        retries=2,
                    )
        finally:
            tmp_path.unlink(missing_ok=True)


class StructuralCheckTests(unittest.TestCase):
    """Tests for code-based structural pre-checks."""

    @classmethod
    def setUpClass(cls):
        cls.eb = load_script_module("eval_behavioral_structural", "eval-behavioral.py")

    def test_check_starts_with_heading_passes(self):
        response = "## Assumptions\n1. First assumption\n2. Second assumption"
        check = {"type": "starts_with", "pattern": "## Assumptions"}

        result = self.eb.structural_check(response, check)

        self.assertTrue(result["passed"])

    def test_check_starts_with_heading_fails_when_prose_first(self):
        response = "Sure, let me help.\n\n## Assumptions\n1. First"
        check = {"type": "starts_with", "pattern": "## Assumptions"}

        result = self.eb.structural_check(response, check)

        self.assertFalse(result["passed"])

    def test_check_contains_literal_passes(self):
        response = "I need zod for validation. May I add zod?"
        check = {"type": "contains", "pattern": "May I add"}

        result = self.eb.structural_check(response, check)

        self.assertTrue(result["passed"])

    def test_check_contains_literal_fails(self):
        response = "I'll use zod for validation.\nimport { z } from 'zod';"
        check = {"type": "contains", "pattern": "May I add"}

        result = self.eb.structural_check(response, check)

        self.assertFalse(result["passed"])

    def test_check_not_contains_passes(self):
        response = "Here is the stdlib solution using URL constructor."
        check = {"type": "not_contains", "pattern": "npm install"}

        result = self.eb.structural_check(response, check)

        self.assertTrue(result["passed"])

    def test_check_not_contains_fails(self):
        response = "Run npm install validator to get started."
        check = {"type": "not_contains", "pattern": "npm install"}

        result = self.eb.structural_check(response, check)

        self.assertFalse(result["passed"])

    def test_check_regex_match_passes(self):
        response = "1. Add guard clause → verify: unit test\n2. Update handler → verify: integration test"
        check = {"type": "regex", "pattern": r"^\d+\.\s.+→\s*verify:"}

        result = self.eb.structural_check(response, check)

        self.assertTrue(result["passed"])

    def test_check_regex_match_fails(self):
        response = "## Steps\n- Add guard clause\n- Update handler"
        check = {"type": "regex", "pattern": r"^\d+\.\s.+→\s*verify:"}

        result = self.eb.structural_check(response, check)

        self.assertFalse(result["passed"])

    def test_run_structural_checks_returns_list(self):
        response = "## Assumptions\n1. Thing"
        checks = [
            {"type": "starts_with", "pattern": "## Assumptions"},
            {"type": "contains", "pattern": "Thing"},
        ]

        results = self.eb.run_structural_checks(response, checks)

        self.assertEqual(len(results), 2)
        self.assertTrue(all(r["passed"] for r in results))

    def test_run_structural_checks_returns_empty_when_no_checks(self):
        results = self.eb.run_structural_checks("hello", [])

        self.assertEqual(results, [])


class StructuralCheckEvaluationTests(unittest.TestCase):
    """Tests that structural checks affect live evaluation."""

    @classmethod
    def setUpClass(cls):
        cls.eb = load_script_module("eval_behavioral_structural_eval", "eval-behavioral.py")

    def test_run_scenario_fails_before_judge_when_structural_check_fails(self):
        scenario = {
            "id": "gate1",
            "rule": "GATE-1 Think",
            "prompt": "Add caching",
            "pass_criteria": ["Starts with assumptions"],
            "fail_signals": ["Jumps straight to code"],
            "structural_checks": [{"type": "starts_with", "pattern": "## Assumptions"}],
        }

        with mock.patch.object(self.eb, "get_subject_response", return_value=("print('hi')", False, 0.5)):
            with mock.patch.object(self.eb, "judge") as judge:
                result = self.eb.run_scenario("sonnet", Path("/tmp/fake.md"), scenario, runs=1)

        self.assertEqual(result["final_verdict"], "FAIL")
        self.assertEqual(result["fails"], 1)
        self.assertEqual(result["errors"], 0)
        self.assertEqual(result["details"][0]["verdict"], "FAIL")
        self.assertEqual(result["details"][0]["source"], "structural")
        self.assertFalse(result["details"][0]["structural_checks"][0]["passed"])
        judge.assert_not_called()

    def test_run_scenario_passes_structural_results_to_judge_when_checks_pass(self):
        scenario = {
            "id": "rhythm",
            "rule": "Rhythm",
            "prompt": "Proceed",
            "pass_criteria": ["Starts with a numbered list"],
            "fail_signals": ["Starts with prose"],
            "structural_checks": [{"type": "regex", "pattern": r"^\d+\.\s.+→\s*verify:"}],
        }

        def fake_judge(scenario_arg, response, timeout=300, use_cache=True):
            self.assertIn("structural_check_summary", scenario_arg)
            self.assertEqual(scenario_arg["structural_check_summary"]["failed"], 0)
            return {
                "verdict": "PASS",
                "evidence": "format ok",
                "triggered_criteria": ["Starts with a numbered list"],
                "triggered_fail_signals": [],
            }

        response = "1. Add guard clause → verify: unit test"
        with mock.patch.object(self.eb, "get_subject_response", return_value=(response, False, 0.5)):
            with mock.patch.object(self.eb, "judge", side_effect=fake_judge) as judge:
                result = self.eb.run_scenario("sonnet", Path("/tmp/fake.md"), scenario, runs=1)

        self.assertEqual(result["final_verdict"], "PASS")
        self.assertEqual(result["details"][0]["source"], "judge")
        self.assertTrue(result["details"][0]["structural_checks"][0]["passed"])
        judge.assert_called_once()


if __name__ == "__main__":
    unittest.main()
