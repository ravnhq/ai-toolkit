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


if __name__ == "__main__":
    unittest.main()
