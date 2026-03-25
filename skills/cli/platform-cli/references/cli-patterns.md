# CLI Design Patterns Reference

This document consolidates all CLI design patterns and best practices from the platform-cli plugin. These patterns are based on industry standards from [clig.dev](https://clig.dev/), POSIX conventions, and battle-tested CLI tools.

## Table of Contents

- [Design & Naming](#design--naming)
- [Flags & Arguments](#flags--arguments)
- [Output & Formatting](#output--formatting)
- [Error Handling](#error-handling)
- [Signals & Lifecycle](#signals--lifecycle)
- [Environment & Config](#environment--config)
- [Distribution & Packaging](#distribution--packaging)
- [Security & Privacy](#security--privacy)

---

## Design & Naming

### Use Lowercase, Short, Typeable Command Names

Command names should be lowercase, short (4-8 characters ideal), easy to type with alternating hands, and memorable without being generic.

**Incorrect (hard to type, too long, or uses wrong case):**

```bash
# Too long
download-url-from-internet

# Wrong case (causes issues on case-insensitive systems)
DownloadURL
MyTool

# Hard to type (awkward one-hand typing)
plum

# Too generic (collides with existing commands)
convert
```

**Correct (lowercase, short, alternating-hand typing):**

```bash
# Good examples
curl    # 4 chars, alternating hands
git     # 3 chars, easy to type
docker  # 6 chars, memorable
kubectl # 7 chars, specific to Kubernetes
jq      # 2 chars, minimal but clear in context

# Multi-word commands use dashes
docker-compose
gh-cli
```

**Why it matters:** Users type your command name dozens or hundreds of times per day. Long or awkward names slow down workflows, mixed-case names cause confusion on case-insensitive filesystems, and generic names create conflicts with existing tools.

Reference: [clig.dev - Naming](https://clig.dev/#naming)

---

### Use Noun-Verb Pattern for Subcommands

Organize subcommands using a consistent noun-verb pattern where the noun identifies the resource and the verb identifies the action.

**Incorrect (inconsistent verb-noun mixing, ambiguous structure):**

```bash
# Inconsistent patterns
mycli start-container
mycli container-stop
mycli deleteImage
mycli network list

# Ambiguous structure
mycli run container prod
mycli container run prod
```

**Correct (consistent noun-verb pattern):**

```bash
# Docker-style noun-verb pattern
docker container start
docker container stop
docker image delete
docker network list

# Alternative: kubectl-style verb-noun pattern (pick one and be consistent)
kubectl get pods
kubectl delete service
kubectl create deployment
kubectl describe node

# Simple tools can use direct verbs
git commit
git push
npm install
```

**Why it matters:** Consistent subcommand structure makes commands predictable and easier to remember. Users can guess the correct command based on the pattern. Mixing patterns (noun-verb and verb-noun) creates cognitive overhead and increases errors.

Reference: [clig.dev - Subcommands](https://clig.dev/#subcommands)

---

### Avoid Catch-All Subcommands and Abbreviation Inference

Never implement catch-all subcommand matching or automatic abbreviation inference. These patterns prevent adding new subcommands in the future without breaking existing usage.

**Incorrect (blocks future subcommands):**

```bash
# Catch-all: "mycmd echo" works if no 'echo' subcommand exists
# Problem: Can't add 'echo' subcommand later without breaking scripts
mycmd echo "hello"  # Falls through to generic handler

# Abbreviation inference: guesses subcommand from prefix
# Problem: "mycmd i" means "install" now, but adding "init" breaks it
mycmd i package-name  # Infers "install"
# Later add "init" subcommand → "mycmd i" becomes ambiguous
```

**Correct (explicit subcommands and aliases only):**

```bash
# Require explicit subcommands always
mycmd install package-name  # Full name required
mycmd init                  # Full name required

# If abbreviations needed, define explicit aliases
mycmd i package-name  # 'i' is explicit alias for 'install', never inferred
# Can still add 'init' later because 'i' is hardcoded to 'install'

# Show helpful error for unknown subcommands
mycmd ech "hello"
# Error: Unknown subcommand 'ech'. Did you mean 'echo'?
```

**Why it matters:** Your CLI interface is a contract. Once released, changing how commands are resolved breaks user scripts and automation. Catch-all patterns and inference make it impossible to add new subcommands without potentially breaking existing usage. Explicit aliases provide convenience without blocking evolution.

Reference: [clig.dev - Future-proofing](https://clig.dev/#future-proofing)

---

### Deprecate Features with Clear Migration Path

When changing or removing features, announce deprecation at least 6 months before removal, show warnings on every use, provide exact replacement commands, and support both old and new simultaneously.

**Incorrect (breaks users without warning):**

```bash
# Version 1.0: Has --target flag
mycmd deploy --target prod

# Version 2.0: Removes flag with no warning
mycmd deploy --target prod
# Error: Unknown flag --target
# No guidance on what to use instead
```

**Correct (gradual deprecation with migration path):**

```bash
# Version 1.0: Original behavior
mycmd deploy --target prod

# Version 2.0: Deprecation warning (6+ months before removal)
mycmd deploy --target prod
# ⚠️  Warning: --target is deprecated. Use --environment instead.
#    The --target flag will be removed in v3.0.
#    Update your command to: mycmd deploy --environment prod

# Version 2.x: Support both (no warning if new flag used)
mycmd deploy --environment prod  # ✅ No warning

# Version 3.0: Remove old flag with helpful error
mycmd deploy --target prod
# ❌ Error: Flag --target was removed in v3.0.
#    Use --environment instead: mycmd deploy --environment prod
```

**Why it matters:** Breaking changes without migration paths destroy user trust and create emergency firefighting for teams using your tool. Gradual deprecation with clear warnings gives users time to update scripts and automation at their own pace. Providing exact replacement commands reduces friction and support burden.

Reference: [clig.dev - Robustness](https://clig.dev/#robustness)

---

## Flags & Arguments

### Use Standard Flag Names for Common Operations

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
mycli --verbose --debug --force
```

**Correct (standard flag names with short forms):**

```bash
# Universal flags (provide in every CLI)
mycli -h, --help        # Help text
mycli -V, --version     # Show version (capital V, not -v)

# Common operation flags
mycli -v, --verbose     # More detailed output
mycli -q, --quiet       # Suppress non-essential output
mycli -d, --debug       # Debug-level output
mycli -f, --force       # Skip confirmations, override safety
mycli -n, --dry-run     # Simulate without changes
mycli -a, --all         # Include all items
mycli -o, --output FILE # Output file path

# Modern flags (no short form needed)
mycli --json            # JSON output format
mycli --plain           # Plain text (script-friendly)
mycli --no-color        # Disable color output
mycli --no-input        # Non-interactive mode
```

**Why it matters:** Users expect `-h` for help and `-v` for verbose across all tools. Non-standard names increase cognitive load and slow down adoption. Providing both short and long forms serves both interactive users (who prefer brevity) and scripts (which prefer clarity).

Reference: [clig.dev - Arguments and flags](https://clig.dev/#arguments-and-flags)

---

### Provide Short Flags Only for Top 3-5 Most Common Operations

Reserve short flags (-f, -v, -d) for the most frequently used operations. Too many short flags create confusion and naming conflicts.

**Incorrect (too many short flags, causing conflicts):**

```bash
# Every flag has a short form, creating a confusing alphabet soup
mycli -h --help
mycli -v --version
mycli -V --verbose      # Conflict: -V already used for --version
mycli -d --debug
mycli -o --output
mycli -i --input
mycli -f --format
mycli -F --force        # Conflict: case-sensitive flags are error-prone
mycli -t --timeout
mycli -r --retry
mycli -c --config
mycli -p --port
# ... users can't remember what each short flag means
```

**Correct (short flags for top operations only):**

```bash
# Universal short flags
-h, --help           # Always provide
-V, --version        # Always provide

# Top 3-5 most used flags get short forms
-v, --verbose        # Used frequently for debugging
-q, --quiet          # Used frequently in scripts
-f, --force          # Used frequently for automation
-o, --output FILE    # Used frequently for saving results

# Less common flags: long form only
--json               # Used occasionally
--no-color           # Used occasionally
--timeout SECONDS    # Used occasionally
--retry COUNT        # Used occasionally
--config FILE        # Used occasionally
```

**Why it matters:** Short flags are harder to remember and easier to confuse. Limiting them to frequently-used operations makes CLIs more learnable. Users will remember -v for verbose, but won't remember if -t means --timeout or --target. Long-only flags are self-documenting and shell completion makes them easy to use.

Reference: [clig.dev - Arguments and flags](https://clig.dev/#arguments-and-flags)

---

### Keep Flag Names Consistent Across All Subcommands

The same flag should mean the same thing across all subcommands. Reusing flag names with different meanings breaks user expectations.

**Incorrect (same flag means different things):**

```bash
# -f means different things in different subcommands
mycli deploy -f           # -f means --force (skip confirmation)
mycli build -f Dockerfile # -f means --file (specify file)
mycli logs -f             # -f means --follow (tail logs)

# Users can't build muscle memory - have to check help for each subcommand
```

**Correct (consistent flag meanings across subcommands):**

```bash
# -f always means --force
mycli deploy -f              # --force: skip confirmation
mycli delete -f              # --force: skip confirmation
mycli update -f              # --force: skip confirmation

# Use different flags for different meanings
mycli build --file Dockerfile    # -f not used, avoiding confusion
mycli logs --follow              # -f not used, avoiding confusion

# Or use -f consistently for one meaning if that's the primary use
git commit -f        # --force
git push -f          # --force
git clean -f         # --force
# Git never reuses -f for --file or --follow
```

**Why it matters:** Users learn your CLI by building muscle memory. When the same flag means different things in different contexts, users must constantly check help text and make more mistakes. Consistency enables users to work faster and with more confidence.

Reference: [clig.dev - Consistency](https://clig.dev/#consistency)

---

### Use --no- Prefix for Boolean Flag Negation

Boolean flags should support negation using the --no- prefix pattern. This makes the default behavior explicit and scriptable.

**Incorrect (can't override defaults or config file settings):**

```bash
# No way to disable color if config file enables it
mycli --color  # Enables color
# No --no-color flag exists

# Using separate flags creates confusion
mycli --color          # Enable color
mycli --disable-color  # Disable color (inconsistent naming)

# Using flag values is verbose
mycli --color=true
mycli --color=false
```

**Correct (--no- prefix for negation):**

```bash
# Standard pattern: flag enables, --no-flag disables
mycli --color          # Enable color
mycli --no-color       # Disable color

# More examples
mycli --interactive    # Enable prompts
mycli --no-interactive # Disable prompts (same as --no-input)

mycli --progress       # Show progress bars
mycli --no-progress    # Hide progress bars

# Respects precedence: flag > env var > config > default
# Can override config file setting:
mycli --no-color  # Disables color even if config.yaml has color: true
```

**Why it matters:** Configuration files and environment variables might enable features by default. Without negation flags, users can't override these defaults from the command line. The --no- prefix is a widely-recognized pattern that makes behavior explicit and predictable.

Reference: [clig.dev - Arguments and flags](https://clig.dev/#arguments-and-flags)

---

## Output & Formatting

### Send Primary Output to stdout, Logs and Errors to stderr

Primary command output goes to stdout, while logs, progress, and errors go to stderr. This enables proper command composition and piping.

**Incorrect (mixes output and logs, breaks piping):**

```bash
# Everything to stdout - can't separate output from logs
mycli fetch-data > output.txt
# File contains mix of data and log messages:
# Connecting to API...
# {"user": "alice"}
# {"user": "bob"}
# Fetched 2 records
# Done

# Or everything to stderr - breaks piping
mycli fetch-data | jq '.user'
# Nothing in pipe because output went to stderr
```

**Correct (stdout for data, stderr for logs):**

```bash
# Primary output to stdout
mycli fetch-data > output.txt
# File contains only data:
# {"user": "alice"}
# {"user": "bob"}

# Logs and progress to stderr (visible on terminal, not in pipe)
mycli fetch-data | jq '.user'
# Terminal shows: Connecting to API... Fetched 2 records
# Pipe receives: {"user": "alice"}\n{"user": "bob"}
# jq output: "alice"\n"bob"

# Errors to stderr
mycli fetch-data 2> errors.txt
# errors.txt contains only error messages
```

**Why it matters:** Standard Unix philosophy relies on stdout carrying only primary output so commands can be chained. Mixing logs with output breaks pipes, grep, and other composition patterns. Users expect to redirect output (>) without capturing logs, and redirect errors (2>) without capturing data.

Reference: [clig.dev - Output](https://clig.dev/#output)

---

### Respect NO_COLOR, Support --no-color, Detect TERM=dumb

Disable colors when NO_COLOR environment variable is set, when --no-color flag is used, when TERM=dumb, or when output is not a TTY.

**Incorrect (ignores color preferences, accessibility barriers):**

```bash
# Always shows colors regardless of environment
NO_COLOR=1 mycli status
# Still shows colors (ignores NO_COLOR)

# No way to disable colors
mycli status --no-color
# Error: unknown flag --no-color

# Shows colors in dumb terminals
TERM=dumb mycli status
# ANSI codes shown as garbage: ^[[32mOK^[[0m
```

**Correct (respects all color preferences):**

```bash
# Respects NO_COLOR environment variable
NO_COLOR=1 mycli status
# Plain output: Status: OK

# Supports --no-color flag
mycli status --no-color
# Plain output: Status: OK

# Detects dumb terminals
TERM=dumb mycli status
# Plain output: Status: OK

# Detects non-TTY
mycli status > log.txt
# log.txt contains plain text, no ANSI codes

# Color decision order (first match wins):
# 1. --no-color flag → disable
# 2. --color flag → enable
# 3. NO_COLOR env var → disable
# 4. TERM=dumb → disable
# 5. !isTTY → disable
# 6. Default → enable
```

**Why it matters:** Not everyone can perceive colors. Some terminals don't support ANSI codes. The NO_COLOR standard (no-color.org) is widely adopted. Ignoring these preferences creates accessibility barriers and broken output in certain environments.

Reference: [NO_COLOR standard](https://no-color.org/) and [clig.dev - Output](https://clig.dev/#output)

---

### Detect TTY and Adjust Output for Interactive vs Scripted Usage

Check if stdout is a TTY to determine whether to use colors, progress bars, and interactive features. Non-TTY output should be plain and script-friendly.

**Incorrect (always shows rich output, breaks pipes and redirects):**

```bash
# Always shows colors and progress, even when piped
mycli deploy | tee log.txt
# log.txt contains ANSI color codes: \x1b[32mSuccess\x1b[0m

# Always shows progress bars, even when not TTY
mycli sync > output.txt
# output.txt contains: [████████░░] 80%\r[█████████░] 90%\r...
```

**Correct (adapts to TTY vs non-TTY):**

```bash
# Interactive TTY: rich output
mycli deploy
# Terminal shows: 🚀 Deploying... [████████████████] 100% ✅ Success

# Piped or redirected: plain output
mycli deploy | tee log.txt
# Terminal shows: Deploying... Deployed successfully
# log.txt contains: Deploying... Deployed successfully

# Detection in code (Node.js example)
if (process.stdout.isTTY) {
    // Use colors, spinners, progress bars
    showProgressBar();
} else {
    // Plain text output
    console.log('Deploying...');
}

# Can override with flags
mycli deploy --no-color     # Force plain even in TTY
mycli deploy --color        # Force color even in non-TTY (for CI logs)
```

**Why it matters:** ANSI color codes and progress bars create garbage in log files and piped output. Users redirect output to files or pipe to other commands frequently. Detecting TTY makes your CLI well-behaved in both interactive and automated contexts.

Reference: [clig.dev - Output](https://clig.dev/#output)

---

### Provide Machine-Readable Output Format (--json or --plain)

Provide a stable, machine-readable output format via --json or --plain flags. Human-readable output can change freely, but machine formats must be stable.

**Incorrect (only human output, forces brittle parsing):**

```bash
# Only pretty human output available
mycli list-users
# Name          Email              Status
# ──────────────────────────────────────────
# Alice Smith   alice@example.com  active
# Bob Jones     bob@example.com    inactive

# Scripts forced to parse pretty output (fragile)
mycli list-users | awk '{print $3}'  # Breaks if column order changes
```

**Correct (provide machine-readable format):**

```bash
# Human output (default, can change between versions)
mycli list-users
# Name          Email              Status
# ──────────────────────────────────────────
# Alice Smith   alice@example.com  active
# Bob Jones     bob@example.com    inactive

# Machine output (stable, versioned schema)
mycli list-users --json
# [
#   {"name": "Alice Smith", "email": "alice@example.com", "status": "active"},
#   {"name": "Bob Jones", "email": "bob@example.com", "status": "inactive"}
# ]

# Scripts can reliably parse JSON
mycli list-users --json | jq '.[].email'

# Alternative: --plain for simple formats (TSV, CSV)
mycli list-users --plain
# Alice Smith\talice@example.com\tactive
# Bob Jones\tbob@example.com\tinactive
```

**Why it matters:** Human-readable output should evolve to improve UX, but every change breaks scripts that parse it. Providing a stable machine format lets you improve the human experience without breaking automation. Scripts become more reliable and maintainable.

Reference: [clig.dev - Output](https://clig.dev/#output)

---

## Error Handling

### Use Meaningful Exit Codes with 0 for Success

Always exit with 0 for success and non-zero for failures. For complex tools, map exit codes to error categories and document them.

**Incorrect (wrong or meaningless exit codes):**

```bash
# Always exits 0, even on error
mycli deploy
# Error: deployment failed
echo $?
# 0  ← Wrong! Should be non-zero

# Random exit codes with no meaning
mycli build
echo $?
# 37  ← What does 37 mean? Undocumented
```

**Correct (meaningful, documented exit codes):**

```bash
# Standard exit codes (minimum)
mycli deploy           # Success
echo $?               # 0

mycli deploy --invalid # Invalid arguments
echo $?               # 2

# Extended exit codes for complex tools (document these)
mycli deploy
echo $?
# Exit codes:
#   0   - Success
#   1   - General error
#   2   - Invalid arguments
#   10  - Configuration error
#   20  - Network error
#   30  - Authentication error
#   40  - Validation error
#   50  - Resource not found
#   130 - Terminated by Ctrl-C (128 + 2)

# Use in scripts
mycli deploy
if [ $? -eq 0 ]; then
    echo "Success"
elif [ $? -eq 20 ]; then
    echo "Network error - retry later"
else
    echo "Failed with code $?"
fi

# Document in help text
mycli --help
# EXIT CODES
#   0   Success
#   1   General error
#   2   Invalid arguments/usage
#   10  Configuration error
#   20  Network error
```

**Why it matters:** Scripts and CI/CD pipelines rely on exit codes to determine success or failure. Exit code 0 means success across all Unix tools. Meaningful exit codes enable precise error handling in automation without parsing error messages.

Reference: [POSIX Exit Codes](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_08_02) and [clig.dev - Robustness](https://clig.dev/#robustness)

---

### Write Human-Friendly Error Messages with Clear Structure

Error messages should explain what went wrong, why it happened, and how to fix it. Avoid raw exceptions and stack traces in user-facing output.

**Incorrect (cryptic errors, no guidance):**

```bash
mycli deploy
# Error: ENOENT
#     at Object.openSync (fs.js:476:3)
#     at Object.readFileSync (fs.js:377:35)
#     at readConfig (/app/config.js:12:8)
#     ...

# Problems:
# - Cryptic error code (ENOENT)
# - Stack trace not helpful to users
# - No guidance on how to fix
# - Appears broken, not helpful
```

**Correct (structured, actionable error messages):**

```bash
mycli deploy
# Could not read configuration file: config.yaml
#
# The file doesn't exist in the current directory.
#
# Create it with:
#   mycli init
#
# Or specify a different config:
#   mycli --config path/to/config.yaml

# Structure:
# 1. What went wrong (one line, specific)
# 2. Why it happened (if not obvious)
# 3. How to fix it (exact command or action)
# 4. Where to get help (if complex)

# Place important info at the end (where eye lands)
mycli connect api.example.com
# Connection failed: Could not reach api.example.com:443
#
# Possible causes:
# - Server is down
# - Network connectivity issue
# - Firewall blocking port 443
#
# Verify server is running: curl https://api.example.com/health
# Check firewall: sudo ufw status
#
# Server address: api.example.com:443  ← Most important info last
```

**Why it matters:** Users encounter errors when they're already frustrated. Cryptic errors increase friction and support burden. Clear, actionable errors guide users to solutions, building trust and reducing abandonment.

Reference: [clig.dev - Errors](https://clig.dev/#errors)

---

### Reduce Error Noise by Grouping and Limiting Output

Group similar errors, limit repeated messages, and write debug logs to files instead of the terminal. Avoid overwhelming users with verbose error output.

**Incorrect (error spam overwhelms the user):**

```bash
# Prints the same error 1000 times
mycli validate-files **/*.json
# Error: Invalid JSON in file1.json: Unexpected token
# Error: Invalid JSON in file2.json: Unexpected token
# Error: Invalid JSON in file3.json: Unexpected token
# ... (997 more identical lines)
#
# Stack trace:
#     at JSON.parse (native)
#     at validate (/app/validator.js:45:18)
#     ... (50 more stack trace lines)
```

**Correct (grouped, summarized errors):**

```bash
# Group and summarize similar errors
mycli validate-files **/*.json
# Found 1000 files with invalid JSON:
#
#   file1.json:12 - Unexpected token
#   file2.json:8  - Unexpected token
#   file3.json:15 - Unexpected token
#   ... (7 more shown)
#
# 990 more files with similar errors (use --verbose to see all)
#
# To see detailed error information:
#   mycli validate-files --verbose
#
# Debug log written to: /tmp/mycli-debug-20260127.log

# Highlighting strategy
# ✅ Use color sparingly (only for key error line)
# ❌ Don't make everything red
# ✅ Keep total error output under one screen when possible
# ❌ Don't dump entire stack traces to terminal

# Write verbose logs to file
mycli deploy --debug
# Debug log written to: ~/.mycli/logs/deploy-20260127-143022.log
# Run 'tail -f ~/.mycli/logs/deploy-20260127-143022.log' to follow
```

**Why it matters:** Verbose errors create cognitive overload and hide important information. Users scan for actionable info, not stack traces. Grouping similar errors and writing debug output to files keeps the terminal clean while preserving detail for debugging.

Reference: [clig.dev - Errors](https://clig.dev/#errors)

---

## Signals & Lifecycle

### Handle Ctrl-C Gracefully with Immediate Acknowledgment

Always respond to Ctrl-C (SIGINT) immediately, perform quick cleanup with timeout, and support double Ctrl-C to force exit. Never block Ctrl-C for "safety".

**Incorrect (blocks Ctrl-C or ignores it):**

```bash
# Ignores Ctrl-C completely
mycli long-running-task
# User hits Ctrl-C → nothing happens
# User hits Ctrl-C again → still nothing
# User forced to kill -9 (causes worse state corruption)

# Blocks Ctrl-C with long cleanup
mycli sync-data
# User hits Ctrl-C
# [30 seconds of silence while cleanup runs]
# User has no idea if it worked, hits Ctrl-C again
# Still waiting... eventually kills process
```

**Correct (immediate acknowledgment, quick cleanup, force option):**

```bash
# Immediate acknowledgment
mycli long-running-task
# User hits Ctrl-C
# ^C Stopping gracefully... (Ctrl-C again to force)
#
# [Cleanup runs with 5-10 second timeout]
# Cleanup complete. Safe to exit.

# Double Ctrl-C skips cleanup
mycli sync-data
# User hits Ctrl-C
# ^C Stopping gracefully... (Ctrl-C again to force)
# User hits Ctrl-C again
# ^C Forcing exit. Skipping cleanup.
# [Exits immediately]

# Example implementation pattern
process.on('SIGINT', async () => {
    console.error('\n^C Stopping gracefully... (Ctrl-C again to force)');

    const forceExit = false;
    process.on('SIGINT', () => {
        console.error('^C Forcing exit.');
        process.exit(130); // 128 + 2 (SIGINT)
    });

    // Cleanup with timeout
    await Promise.race([
        cleanup(),
        new Promise(resolve => setTimeout(resolve, 5000))
    ]);

    process.exit(130);
});
```

**Why it matters:** Users expect Ctrl-C to work immediately. Blocking it causes frustration and forces users to kill -9, which causes worse state corruption than graceful cleanup. Double Ctrl-C provides an escape hatch for stuck cleanup.

Reference: [clig.dev - Signals](https://clig.dev/#signals-and-control-characters)

---

### Implement Cleanup with Timeout and Crash-Only Design

Cleanup operations must have timeouts (5-10 seconds max) and programs should work correctly even if cleanup never ran (crash-only design).

**Incorrect (unbounded cleanup, broken state if skipped):**

```bash
# Cleanup blocks indefinitely
mycli process-data
# User hits Ctrl-C
# [Cleanup tries to finish all in-flight operations]
# [User waits 60 seconds, gets frustrated, kills process]

# Program broken if cleanup doesn't run
mycli start-server
# Creates lock file: /tmp/mycli.lock
# User kills with Ctrl-C
# Lock file not cleaned up
# Next run:
mycli start-server
# Error: Lock file exists. Another instance running?
# (No instance running - previous cleanup failed)
```

**Correct (timeout + crash-only design):**

```bash
# Cleanup with timeout
mycli process-data
# User hits Ctrl-C
# ^C Stopping gracefully... (timeout: 5s)
# [Cleanup runs for max 5 seconds]
# [After 5s, exits regardless of completion]

# Crash-only design: program works even if cleanup didn't run
mycli start-server
# Creates lock file with PID: /tmp/mycli.lock (PID: 12345)
# User kills with Ctrl-C
# Lock file not cleaned up
# Next run:
mycli start-server
# Checks if PID 12345 is still running
# PID not found → removes stale lock file
# Starts normally

# Example: Cleanup with timeout
async function cleanup() {
    const timeout = 5000; // 5 seconds max

    try {
        await Promise.race([
            closeConnections(),
            new Promise((_, reject) =>
                setTimeout(() => reject(new Error('Cleanup timeout')), timeout)
            )
        ]);
    } catch (err) {
        console.error('Cleanup incomplete:', err.message);
        // Exit anyway - crash-only design
    }
}

# Example: Stale lock detection
function acquireLock() {
    if (fs.existsSync('/tmp/mycli.lock')) {
        const pid = fs.readFileSync('/tmp/mycli.lock', 'utf8');
        if (isProcessRunning(pid)) {
            throw new Error('Another instance is running');
        } else {
            // Stale lock - remove it
            fs.unlinkSync('/tmp/mycli.lock');
        }
    }
    fs.writeFileSync('/tmp/mycli.lock', process.pid.toString());
}
```

**Why it matters:** Users will eventually kill your process (Ctrl-C, kill -9, system crash). Unbounded cleanup blocks users and gets force-killed anyway. Crash-only design ensures your program recovers gracefully from unexpected termination.

Reference: [Crash-only software](https://www.usenix.org/legacy/events/hotos03/tech/full_papers/candea/candea.pdf) and [clig.dev - Robustness](https://clig.dev/#robustness)

---

## Environment & Config

### Use UPPERCASE_WITH_UNDERSCORES and App Prefix for Environment Variables

Environment variable names should be UPPERCASE with underscores, prefixed with your app name to avoid collisions.

**Incorrect (wrong case, no prefix, potential collisions):**

```bash
# Wrong case (lowercase/mixed)
export debug=1              # Should be uppercase
export MyApp_Setting=value  # Mixed case

# No app prefix (collides with other tools)
export DEBUG=1              # Too generic
export HOST=api.example.com # Too generic
export PORT=3000            # Too generic

# Using dashes instead of underscores
export MY-APP-API-URL=...   # Invalid in some shells
```

**Correct (uppercase, underscores, prefixed):**

```bash
# Proper format: APPNAME_COMPONENT_SETTING
export MYCLI_DEBUG=1
export MYCLI_API_URL=https://api.example.com
export MYCLI_API_TOKEN=...
export MYCLI_NO_COLOR=1
export MYCLI_CONFIG_DIR=~/.config/mycli

# Multi-word apps use underscores
export DOCKER_COMPOSE_FILE=docker-compose.yml
export GIT_EDITOR=vim

# Examples from real tools
DOCKER_HOST=unix:///var/run/docker.sock
NPM_TOKEN=...
AWS_REGION=us-east-1
GITHUB_TOKEN=...
```

**Why it matters:** Environment variables are global and shared across all processes. Without prefixes, generic names like DEBUG or PORT collide with other tools. Lowercase names aren't valid in some shells. The APPNAME_SETTING pattern is a widely-recognized convention that prevents collisions.

Reference: [clig.dev - Environment variables](https://clig.dev/#environment-variables)

---

### Check Standard Environment Variables Before Defining Custom Ones

Always check for standard environment variables (NO_COLOR, EDITOR, HTTP_PROXY, etc.) before creating custom equivalents.

**Incorrect (ignores standard env vars, defines custom ones):**

```bash
# Ignores NO_COLOR, defines custom var
export MYCLI_DISABLE_COLOR=1  # Should use NO_COLOR
mycli status

# Ignores EDITOR, defines custom var
export MYCLI_EDITOR=vim       # Should use EDITOR
mycli edit-config

# Ignores HTTP_PROXY
# User has export HTTP_PROXY=http://proxy:8080
mycli fetch-data              # Doesn't use proxy, request fails
```

**Correct (respects standard env vars):**

```bash
# Check NO_COLOR before showing colors
NO_COLOR=1 mycli status       # Disables colors (standard)
# Also support custom flag for override
mycli status --color          # Enables colors even with NO_COLOR

# Use EDITOR for interactive editing
EDITOR=nano mycli edit-config # Opens nano (standard)
# Fallback: MYCLI_EDITOR, then vim

# Respect proxy settings
HTTP_PROXY=http://proxy:8080 mycli fetch-data
HTTPS_PROXY=http://proxy:8080 mycli fetch-data
NO_PROXY=localhost,127.0.0.1 mycli fetch-data

# Standard environment variables to check
NO_COLOR          # Disable color output
FORCE_COLOR       # Force color (override detection)
DEBUG             # Verbose debug output
EDITOR            # User's preferred editor
VISUAL            # Alternative to EDITOR (check both)
PAGER             # User's pager (less, more, etc.)
SHELL             # User's shell
HOME              # User home directory
TMPDIR            # Temp directory
TERM              # Terminal type
HTTP_PROXY        # HTTP proxy server
HTTPS_PROXY       # HTTPS proxy server
NO_PROXY          # Bypass proxy for these hosts

# Example implementation
function shouldUseColor() {
    // Check in precedence order
    if (flags.color !== undefined) return flags.color;
    if (flags.noColor) return false;
    if (process.env.NO_COLOR) return false;
    if (process.env.TERM === 'dumb') return false;
    if (!process.stdout.isTTY) return false;
    return true; // Default: use color
}
```

**Why it matters:** Standard environment variables work across all tools. Defining custom equivalents fragments the ecosystem and increases cognitive load. Users expect NO_COLOR to disable colors everywhere, EDITOR to work with all tools, and proxy settings to be respected.

Reference: [NO_COLOR](https://no-color.org/), [EDITOR](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap08.html), and [clig.dev - Environment variables](https://clig.dev/#environment-variables)

---

### Follow Precedence Order: Flags > Env Vars > Config Files > Defaults

Configuration should follow a clear precedence order: command-line flags override environment variables, which override config files, which override built-in defaults.

**Incorrect (unclear or inconsistent precedence):**

```bash
# Config file overrides flag (backwards!)
mycli deploy --environment staging
# Uses 'production' from config file, ignoring flag

# No way to override config file
# Config: api_url: https://prod.example.com
mycli deploy --api-url https://dev.example.com
# Error: --api-url not supported (must edit config file)

# Environment variable ignored
MYCLI_TIMEOUT=30 mycli run
# Uses 10s from config, ignoring env var
```

**Correct (clear precedence order):**

```bash
# Precedence order (highest to lowest):
# 1. Command-line flags
# 2. Environment variables
# 3. Project config file (.mycli.yaml in current dir)
# 4. User config file (~/.config/mycli/config.yaml)
# 5. System config file (/etc/mycli/config.yaml)
# 6. Built-in defaults

# Example: Flag overrides everything
mycli deploy --environment staging
# Uses 'staging' (from flag)
# Ignores MYCLI_ENVIRONMENT env var
# Ignores environment: production in config

# Example: Env var overrides config
MYCLI_ENVIRONMENT=staging mycli deploy
# Uses 'staging' (from env var)
# Ignores environment: production in config

# Example: Config overrides defaults
# Config: timeout: 30
mycli run
# Uses 30s (from config)
# Ignores built-in default of 10s

# Example: Show effective configuration
mycli config show
# environment: staging (from flag --environment)
# timeout: 30 (from config file ~/.config/mycli/config.yaml)
# verbose: false (default)
```

**Why it matters:** Users need predictable configuration resolution. Flags should always win (for quick overrides), env vars enable per-session config (CI/CD), and config files provide stable defaults. Unclear precedence causes confusion and makes debugging difficult.

Reference: [clig.dev - Configuration](https://clig.dev/#configuration)

---

## Distribution & Packaging

### Distribute as Single Binary When Possible

Compile to a single binary when the language supports it (Go, Rust). This simplifies installation, updates, and uninstallation.

**Incorrect (scattered files, complex installation):**

```bash
# Multiple files scattered across system
mycli install
# Installing to:
#   /usr/local/bin/mycli
#   /usr/local/lib/mycli/core.so
#   /usr/local/lib/mycli/plugins/
#   /usr/local/share/mycli/templates/
#   /etc/mycli/config.yaml
#   ~/.mycli/cache/
# Installation complete

# Uninstall is manual and error-prone
# Which files do I remove? Easy to leave behind debris
```

**Correct (single binary, clean installation):**

```bash
# Single binary (Go, Rust)
curl -L https://github.com/user/mycli/releases/latest/download/mycli-linux-amd64 -o mycli
chmod +x mycli
sudo mv mycli /usr/local/bin/
# Done - one file

# Uninstall is trivial
sudo rm /usr/local/bin/mycli
# Config cleanup (optional)
rm -rf ~/.config/mycli

# Distribution by language
# Go: Single binary (best option)
go build -o mycli main.go

# Rust: Single binary (best option)
cargo build --release

# Python: pipx (isolated environment)
pipx install mycli
# Or single file with PyInstaller
pyinstaller --onefile mycli.py

# Node.js: npm global install
npm install -g mycli
# Or npx (no install)
npx mycli

# Ruby: gem install
gem install mycli
```

**Why it matters:** Single binaries eliminate dependency hell, version conflicts, and incomplete installations. Users can download and run immediately. Uninstallation is one command. Updates are atomic (replace file). This reduces support burden significantly.

Reference: [clig.dev - Distribution](https://clig.dev/#distribution)

---

### Include Uninstall Instructions in README Immediately After Install

Always provide clear uninstall instructions in your README, placed immediately after installation instructions. Include config file cleanup steps.

**Incorrect (no uninstall instructions):**

```markdown
# Installation

## Homebrew
brew install mycli

## npm
npm install -g mycli

## Manual
curl -L https://example.com/mycli -o /usr/local/bin/mycli

# Usage
...
```

**Correct (uninstall instructions right after install):**

```markdown
# Installation

## Homebrew
```bash
brew install mycli
```

## npm
```bash
npm install -g mycli
```

## Manual
```bash
curl -L https://example.com/mycli -o /usr/local/bin/mycli
chmod +x /usr/local/bin/mycli
```

# Uninstallation

## If installed via Homebrew
```bash
brew uninstall mycli
```

## If installed via npm
```bash
npm uninstall -g mycli
```

## If installed manually
```bash
sudo rm /usr/local/bin/mycli
```

## Clean up configuration files (optional)
```bash
# Remove user config
rm -rf ~/.config/mycli

# Remove cache
rm -rf ~/.cache/mycli

# List all mycli files
find ~ -name "*mycli*" 2>/dev/null
```

# Usage
...
```

**Why it matters:** Users evaluate tools by how easy they are to remove. Hidden or missing uninstall instructions create friction and reduce trust. Placing uninstall steps near install steps makes them discoverable when users need them most.

Reference: [clig.dev - Distribution](https://clig.dev/#distribution)

---

## Security & Privacy

### Never Read Secrets from Environment Variables

Never read passwords, tokens, or other secrets from environment variables. Use files, stdin, or secret managers instead.

**Incorrect (secrets in env vars - visible to all processes):**

```bash
# Secrets visible in ps output
export MYCLI_API_TOKEN=super-secret-token-12345
mycli deploy

# User runs ps
ps auxe | grep mycli
# Shows: MYCLI_API_TOKEN=super-secret-token-12345

# Secrets inherited by all child processes
export DATABASE_PASSWORD=hunter2
mycli run-script
# script.sh and all its children can see DATABASE_PASSWORD

# Secrets in shell history
export API_KEY=abc123
# Now in ~/.bash_history forever
```

**Correct (secrets from files, stdin, or secret managers):**

```bash
# Read from file
echo "super-secret-token" > ~/.mycli/token
chmod 600 ~/.mycli/token
mycli deploy --token-file ~/.mycli/token

# Read from stdin
echo "super-secret-token" | mycli deploy --token-stdin
# Or
mycli deploy --token-stdin < ~/.mycli/token

# Read from secret manager
mycli deploy --token-from-vault secret/mycli/token

# Prompt interactively (hidden input)
mycli deploy
# Enter API token: ••••••••••••

# Implementation example
if (flags.tokenFile) {
    token = fs.readFileSync(flags.tokenFile, 'utf8').trim();
    fs.chmodSync(flags.tokenFile, 0o600); // Warn if too permissive
} else if (flags.tokenStdin) {
    token = fs.readFileSync(0, 'utf8').trim(); // fd 0 = stdin
} else {
    // Prompt with hidden input
    token = await promptSecret('Enter API token:');
}
```

**Why it matters:** Environment variables are visible in `ps` output to all users, inherited by all child processes, appear in error logs and crash dumps, and often get exported globally in shell profiles. This makes them unsuitable for secrets. Files with proper permissions (600) or secret managers provide actual security.

Reference: [OWASP - Secrets in Environment Variables](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html) and [clig.dev - Environment variables](https://clig.dev/#environment-variables)

---

### Make Telemetry Opt-In with Clear Privacy Policy

If collecting usage data, make it opt-in by default, show exactly what's collected, link to privacy policy, and provide easy opt-out.

**Incorrect (silent telemetry, unclear data collection):**

```bash
# Starts collecting data without asking
mycli init
# [Silently sends: commands used, file paths, error messages, IP address]

# No way to see what's collected
mycli status
# Is this sending data? What data?

# No way to opt out
mycli --no-telemetry
# Error: unknown flag

# Vague privacy policy
# "We may collect usage data to improve the product"
# What data? For how long? Can it identify me?
```

**Correct (opt-in, transparent, controllable):**

```bash
# First run: clear opt-in prompt
mycli init
# Would you like to help improve mycli by sending anonymous usage data?
# This helps us prioritize features. You can change this anytime.
#
# We collect:
#   - Commands used (not argument values)
#   - Success/error status (not error messages)
#   - OS and architecture
#   - Tool version
#
# We do NOT collect:
#   - File paths or names
#   - Error messages or stack traces
#   - Environment variables
#   - IP addresses (stored after geolocation)
#
# Privacy policy: https://example.com/privacy
# Data retention: 90 days
#
# Send anonymous usage data? [y/N]: _

# Easy opt-out anytime
mycli telemetry disable
# Telemetry disabled. No data will be sent.

# Check status
mycli telemetry status
# Telemetry: enabled
# Last sent: 2026-01-27 14:30:22
# Data: https://example.com/privacy

# Minimal data collection
# ✅ Safe to collect:
#   - Command names (not values)
#   - Flag names (not values)
#   - Success/error boolean
#   - OS, architecture, version
#   - Country (via IP, then discard IP)
#
# ❌ Never collect:
#   - Argument/flag values
#   - Error messages
#   - File paths
#   - Environment variables
#   - IP addresses (retain after geo)
```

**Why it matters:** Silent telemetry violates user trust and privacy. Developers deserve to know what's being collected and have control over it. Opt-in (not opt-out) respects privacy by default. Clear disclosure of exactly what's collected and retained builds trust.

Reference: [clig.dev - Analytics](https://clig.dev/#analytics) and [GDPR Principles](https://gdpr-info.eu/art-5-gdpr/)

---

## Summary

These CLI design patterns represent industry best practices for building developer tools. They prioritize:

- **Consistency**: Users should be able to transfer knowledge between tools
- **Composability**: Tools should work well with pipes and other Unix utilities
- **Clarity**: Errors and outputs should be actionable and understandable
- **Resilience**: Tools should handle unexpected situations gracefully
- **Privacy**: User data and secrets should be protected by default
- **Evolution**: Tools should be able to grow without breaking existing usage

For more details on any pattern, see the original rule files in `/Users/pedro/Development/ravn/ai-toolkit/plugins/platform-cli/skills/cli-patterns/rules/`.
