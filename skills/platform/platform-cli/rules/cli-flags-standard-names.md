---
title: Use Standard Flag Names
impact: HIGH
tags: flags, ux, conventions
---

## Use Standard Flag Names

Use conventional flag names for common operations so users can transfer knowledge between tools. Always provide both short and long forms for frequently-used flags.

**Incorrect (non-standard flag names confuse users):**

```bash
# Non-standard names
mycli --showhelp        # Should be --help
mycli --show-version    # Should be --version
mycli --loud            # Should be --verbose
mycli --silent          # Should be --quiet
mycli --no-confirm      # Should be --force
mycli --simulate        # Should be --dry-run

# Missing short forms for common flags
mycli --verbose --debug --force  # No -v, -d, -f shortcuts
```

**Correct (standard flag names with short forms):**

```bash
# Universal flags (provide in EVERY CLI)
mycli -h, --help        # Help text (always provide)
mycli -V, --version     # Show version (capital V, not lowercase -v)

# Common operation flags (top 3-5 only get short forms)
mycli -v, --verbose     # More detailed output
mycli -q, --quiet       # Suppress non-essential output
mycli -d, --debug       # Debug-level output with stack traces
mycli -f, --force       # Skip confirmations, override safety checks
mycli -n, --dry-run     # Simulate without making changes
mycli -o, --output FILE # Output file path

# Modern flags (long form only - shell completion makes them easy)
mycli --json            # JSON output format
mycli --plain           # Plain text (script-friendly, no formatting)
mycli --no-color        # Disable color output
mycli --no-input        # Non-interactive mode (fail instead of prompt)
```

**Short flag guidelines:**

Only provide short flags (-v, -f, etc.) for the 3-5 most frequently used operations:
- Users can't remember more than 5 short flags
- Long flags are self-documenting
- Shell completion makes long flags easy to type
- Reserve short flags for commands users type dozens of times per day

**Consistency across subcommands:**

```bash
# Good - -f always means --force
mycli deploy -f      # --force: skip confirmation
mycli delete -f      # --force: skip confirmation
mycli update -f      # --force: skip confirmation

# Bad - -f means different things
mycli deploy -f           # --force
mycli build -f Dockerfile # --file (WRONG - conflicts with --force)
mycli logs -f             # --follow (WRONG - conflicts with --force)
```

**Standard flag reference:**

```
-h, --help       Help text
-V, --version    Version (capital V to avoid conflict with --verbose)
-v, --verbose    Verbose output
-q, --quiet      Quiet mode
-d, --debug      Debug output
-f, --force      Force/skip confirmations
-n, --dry-run    Simulate only
-a, --all        Include all items
-o, --output     Output file
--json           JSON output
--plain          Plain output
--no-color       Disable colors
--no-input       Non-interactive
```

**Why it matters:**

Users expect `-h` for help and `-v` for verbose across all tools. Non-standard names increase cognitive load and slow down adoption. Providing both short and long forms serves both interactive users (who prefer brevity) and scripts (which prefer clarity).

Reference: [clig.dev - Arguments and flags](https://clig.dev/#arguments-and-flags)
