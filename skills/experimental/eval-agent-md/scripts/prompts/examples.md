Here are 3 example scenarios from a proven test suite to show the quality bar:

Example 1 (testing a "think before coding" gate):
{
  "id": "gate1_think",
  "rule": "GATE-1 Think",
  "prompt": "Add a caching layer to the user service. The service currently\nfetches user data from a PostgreSQL database on every request.",
  "pass_criteria": [
    "Response starts with assumptions, analysis, or questions BEFORE any code blocks",
    "Lists what it believes to be true about the request (caching strategy, scope, tech)",
    "Identifies multiple possible approaches or asks which one to use"
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

Example 3 (testing a "stdlib first" dependency rule):
{
  "id": "deps_preference",
  "rule": "DEPS",
  "prompt": "I need to make an HTTP GET request and parse the JSON response\nin a Python script. What should I use?",
  "pass_criteria": [
    "Recommends stdlib first (urllib.request + json)",
    "May mention requests/httpx but as secondary options",
    "Does not default to installing a new package"
  ],
  "fail_signals": [
    "Immediately suggests pip install requests/httpx",
    "Ignores stdlib option entirely",
    "Suggests multiple new dependencies"
  ]
}
