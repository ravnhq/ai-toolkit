---
title: Separate Output and Logs (stdout vs stderr)
impact: HIGH
tags: output, streams, composition
---

## Separate Output and Logs (stdout vs stderr)

Primary command output goes to stdout, while logs, progress, warnings, and errors go to stderr. This enables proper command composition and piping.

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

# User wanted just the JSON, now has to manually clean the file

# Or everything to stderr - breaks piping
mycli fetch-data | jq '.user'
# Nothing in pipe because output went to stderr instead of stdout
```

**Correct (stdout for data, stderr for logs):**

```bash
# Primary output to stdout only
mycli fetch-data > output.txt
# File contains ONLY the data:
# {"user": "alice"}
# {"user": "bob"}

# Logs and progress to stderr (visible on terminal, not captured)
mycli fetch-data | jq '.user'
# Terminal shows: Connecting to API... Fetched 2 records
# Pipe receives only: {"user": "alice"}\n{"user": "bob"}
# jq output: "alice"\n"bob"

# Errors to stderr
mycli fetch-data 2> errors.txt
# errors.txt contains only error messages
# stdout still has the data

# Separate both
mycli fetch-data > data.json 2> errors.txt
# data.json has output, errors.txt has logs/errors
```

**What goes where:**

**stdout (file descriptor 1):**
- Primary command output (JSON, CSV, text data)
- Results of a query or operation
- Anything the user wants to pipe to another command

**stderr (file descriptor 2):**
- Log messages (info, warning, error)
- Progress indicators and status updates
- Interactive prompts
- Diagnostic information
- Stack traces and debug output

**Implementation example:**

```javascript
// Correct
console.log(JSON.stringify(data));      // Data → stdout
console.error('Connecting to API...');   // Log → stderr
console.error(`✓ Fetched ${count} records`); // Progress → stderr

// Wrong
console.log('Connecting to API...');     // Log should be stderr
console.log(JSON.stringify(data));       // Mixed output breaks pipes
console.log('Done');                     // Log should be stderr
```

**Piping patterns this enables:**

```bash
# Extract data, transform, and save
mycli fetch-users | jq '.email' | sort | uniq > emails.txt

# Count results
mycli search query | wc -l

# Chain multiple commands
mycli export-data | gzip > backup.json.gz

# Filter and process
mycli list-files | grep '\.js$' | xargs wc -l

# All while seeing progress on terminal (from stderr)
```

**Why it matters:**

Standard Unix philosophy relies on stdout carrying only primary output so commands can be chained. Mixing logs with output breaks pipes, grep, and other composition patterns. Users expect to redirect output (>) without capturing logs, and redirect errors (2>) without capturing data.

Reference: [clig.dev - Output](https://clig.dev/#output)
