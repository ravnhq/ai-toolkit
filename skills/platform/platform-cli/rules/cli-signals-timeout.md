---
title: Handle Ctrl-C with Timeout and Force Option
impact: HIGH
tags: signals, interrupts, cleanup
---

## Handle Ctrl-C with Timeout and Force Option

Always respond to Ctrl-C (SIGINT) immediately, perform quick cleanup with timeout (5-10 seconds max), and support double Ctrl-C to force exit. Never block Ctrl-C for "safety".

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
# Still waiting... eventually kills process with -9
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
# [Exits immediately with code 130]
```

**Implementation pattern:**

```javascript
// Track if we've seen first Ctrl-C
let stopping = false;

process.on('SIGINT', async () => {
    if (stopping) {
        // Second Ctrl-C - force exit immediately
        console.error('^C Forcing exit.');
        process.exit(130); // 128 + 2 (SIGINT)
    }

    stopping = true;
    console.error('\n^C Stopping gracefully... (Ctrl-C again to force)');

    // Cleanup with timeout
    try {
        await Promise.race([
            performCleanup(),
            new Promise((_, reject) =>
                setTimeout(() => reject(new Error('Cleanup timeout')), 5000)
            )
        ]);
        console.error('Cleanup complete.');
    } catch (err) {
        console.error('Cleanup timed out or failed.');
    }

    process.exit(130); // 128 + 2 (SIGINT)
});

async function performCleanup() {
    // Close connections, flush buffers, etc.
    // Must complete quickly (< 5 seconds)
}
```

**Cleanup requirements:**

- **Timeout**: 5-10 seconds maximum, no exceptions
- **Idempotent**: Safe to run multiple times or not at all
- **Crash-only design**: Program should work correctly even if cleanup never ran
- **No critical operations**: Don't wait for in-flight operations to complete

**Crash-only design:**

```bash
# Bad - broken if cleanup doesn't run
mycli start-server
# Creates lock file: /tmp/mycli.lock
# User kills with Ctrl-C, lock not cleaned up
# Next run: "Error: Lock file exists"

# Good - check lock validity
mycli start-server
# Creates lock with PID: /tmp/mycli.lock contains "12345"
# On startup: check if PID 12345 exists
# If not, stale lock - safe to overwrite
```

**Exit codes:**

- Normal exit: `0`
- Interrupted by Ctrl-C: `130` (128 + 2 for SIGINT)
- This lets scripts distinguish intentional interruption from errors

**Why it matters:**

Users expect Ctrl-C to work immediately. Blocking it causes frustration and forces users to `kill -9`, which causes worse state corruption than graceful cleanup. Double Ctrl-C provides an escape hatch for stuck cleanup. Timeouts prevent cleanup from blocking indefinitely.

Reference: [clig.dev - Signals and control characters](https://clig.dev/#signals-and-control-characters)
