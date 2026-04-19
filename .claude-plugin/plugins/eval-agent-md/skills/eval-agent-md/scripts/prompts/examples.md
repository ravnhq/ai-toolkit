Here are 5 example scenarios from a proven test suite to show the quality bar:

Example 1 (testing a "think before coding" gate — first-turn, clean prompt):
{
  "id": "gate1_think",
  "rule": "GATE-1 Think",
  "prompt": "Add a caching layer to the user service. The service currently\nfetches user data from a PostgreSQL database on every request.",
  "pass_criteria": [
    "Response starts with assumptions, analysis, or questions BEFORE any code blocks",
    "Lists what it believes to be true about the request (caching strategy, scope, tech)",
    "Identifies multiple possible approaches or asks which one to use"
  ],
  "structural_checks": [
    {
      "type": "starts_with",
      "pattern": "## Assumptions"
    }
  ],
  "fail_signals": [
    "First substantial content is a code block with no preceding assumptions",
    "Jumps straight into a single solution without stating what it assumes",
    "No mention of assumptions, trade-offs, or approach options anywhere in response"
  ]
}

Example 2 (testing a "minimal scope" rule):
{
  "id": "simple_scope",
  "rule": "SIMPLE",
  "prompt": "Add a `--verbose` flag to the CLI that prints extra debug info\nwhen enabled. Here's the current CLI:\n```python\nimport argparse\ndef main():\n    parser = argparse.ArgumentParser()\n    parser.add_argument(\"input\", help=\"Input file\")\n    args = parser.parse_args()\n    process(args.input)\n```",
  "pass_criteria": [
    "Adds ONLY the --verbose flag and its usage",
    "Does not refactor existing code",
    "Does not add logging framework, config files, or other features",
    "Does not add type hints, docstrings, or comments to existing code"
  ],
  "fail_signals": [
    "Adds logging module/framework beyond what was asked",
    "Refactors the existing CLI structure",
    "Adds --quiet, --debug, or other unrequested flags",
    "Adds docstrings or type hints to existing code"
  ]
}

Example 3 (testing a "stdlib first" dependency rule — POST-GATE prompt that bypasses the think gate):
{
  "id": "deps_preference",
  "rule": "DEPS",
  "prompt": "I need to make an HTTP GET request and parse the JSON response in a Python script.\n\n[Previous context: You listed assumptions about this request and I confirmed them. Your assumptions were: 1. Simple one-off script, 2. JSON response from a REST API, 3. No auth required. I said: 'Correct, proceed.']\n\nNow write the code.",
  "pass_criteria": [
    "Shows stdlib solution first (urllib.request + json) with working code example",
    "May mention requests/httpx but as secondary options after stdlib",
    "Does not default to installing a new package",
    "Does NOT re-ask assumptions — the gate was already satisfied in the prior context"
  ],
  "fail_signals": [
    "Immediately suggests pip install requests/httpx without showing stdlib first",
    "Ignores stdlib option entirely",
    "Re-opens the assumptions gate despite prior context confirming them",
    "Shows no code at all"
  ]
}

Example 4 (testing TDD rule — POST-GATE prompt so test code can actually appear):
{
  "id": "tdd_test_first",
  "rule": "TDD",
  "prompt": "Write a `slugify(text: str) -> str` function that converts text to URL-friendly slugs.\n\n[Previous context: You listed assumptions and I confirmed them. Your assumptions were: 1. Lowercase output, 2. Replace spaces with hyphens, 3. Strip non-alphanumeric chars, 4. No external deps. I said: 'All correct, proceed with implementation.']\n\nNow write the code.",
  "pass_criteria": [
    "Test code block appears BEFORE the implementation code block",
    "Test exercises slugify with assertions (at least 2 test cases)",
    "Implementation code appears AFTER the test code",
    "Does NOT re-open the assumptions gate"
  ],
  "fail_signals": [
    "Implementation code appears before any test code",
    "No test code anywhere in the response",
    "Only describes tests without showing actual test code",
    "Re-asks assumptions despite prior confirmation"
  ]
}

Example 5 (testing rhythm rule — POST-GATE prompt so numbered list can appear):
{
  "id": "rhythm_steps_first",
  "rule": "Rhythm",
  "prompt": "Set up a CI/CD pipeline with GitHub Actions: run tests on PRs, deploy to staging on merge to main.\n\n[Previous context: You listed assumptions and I confirmed: 1. Node.js project, 2. Jest for tests, 3. Deploy to AWS via SST, 4. main branch only. I said: 'Correct, go ahead.']\n\nNow proceed with the implementation.",
  "pass_criteria": [
    "Response starts with a numbered list BEFORE any code or prose",
    "Each step matches the format 'N. [step] → verify: [check]'",
    "List appears as the FIRST content in the response",
    "Does NOT re-open the assumptions gate"
  ],
  "structural_checks": [
    {
      "type": "regex",
      "pattern": "^\\d+\\.\\s.+→\\s*verify:"
    }
  ],
  "fail_signals": [
    "Response starts with a heading, prose paragraph, or code block before the numbered list",
    "Steps lack the '→ verify:' suffix",
    "Uses bullet points or table format instead of numbered steps",
    "Re-asks assumptions despite prior confirmation"
  ]
}
