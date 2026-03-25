---
title: Write Actionable Error Messages
impact: CRITICAL
tags: errors, usability, ux
---

## Write Actionable Error Messages

Error messages must explain what went wrong, why it happened, and how to fix it. Avoid raw exceptions and stack traces in user-facing output.

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
#   mycli --config path/to/config.yaml deploy

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

**Error message checklist:**

- Start with what went wrong (not how)
- Include specific details (file names, URLs, line numbers)
- Suggest exact fix commands (not vague advice like "check your config")
- Group similar errors (don't repeat the same message 1000 times)
- Write debug details to log files, not the terminal
- Place most important info at the end where the eye lands

**Why it matters:**

Users encounter errors when they're already frustrated. Cryptic errors increase friction and support burden. Clear, actionable errors guide users to solutions, building trust and reducing abandonment. Stack traces belong in debug logs (`--debug`), not default output.

Reference: [clig.dev - Errors](https://clig.dev/#errors)
