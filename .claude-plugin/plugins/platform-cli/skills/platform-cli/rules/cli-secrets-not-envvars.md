---
title: Never Read Secrets from Environment Variables
impact: CRITICAL
tags: security, secrets, credentials
---

## Never Read Secrets from Environment Variables

Never read passwords, tokens, API keys, or other secrets from environment variables. Use files with proper permissions, stdin, secret managers, or interactive prompts instead.

**Incorrect (secrets in env vars - visible to all processes):**

```bash
# Secrets visible in ps output to ALL users
export MYCLI_API_TOKEN=super-secret-token-12345
mycli deploy

# Any user on the system can see it
ps auxe | grep mycli
# Shows: MYCLI_API_TOKEN=super-secret-token-12345

# Secrets inherited by all child processes
export DATABASE_PASSWORD=hunter2
mycli run-script
# script.sh and all its children can now read DATABASE_PASSWORD

# Secrets in shell history forever
export API_KEY=abc123
# Now in ~/.bash_history, visible to anyone with file access

# Environment vars appear in error logs and crash dumps
export SECRET=sensitive
mycli deploy
# Error logs show full environment including SECRET
```

**Correct (secrets from files, stdin, or secret managers):**

```bash
# Read from file with proper permissions
echo "super-secret-token" > ~/.mycli/token
chmod 600 ~/.mycli/token  # Only owner can read
mycli deploy --token-file ~/.mycli/token

# Read from stdin
echo "super-secret-token" | mycli deploy --token-stdin
# Or
mycli deploy --token-stdin < ~/.mycli/token

# Read from secret manager
mycli deploy --token-from-vault secret/mycli/token
# Or from AWS Secrets Manager
mycli deploy --token-from-aws mycli/prod/token

# Prompt interactively (hidden input)
mycli deploy
# Enter API token: •••••••••••• (input hidden)

# Implementation example
if (flags.tokenFile) {
    const stats = fs.statSync(flags.tokenFile);
    if (stats.mode & 0o077) {
        // Warn if file is readable by group/others
        console.error('Warning: token file has overly permissive mode');
        console.error(`Run: chmod 600 ${flags.tokenFile}`);
    }
    token = fs.readFileSync(flags.tokenFile, 'utf8').trim();
} else if (flags.tokenStdin) {
    token = fs.readFileSync(0, 'utf8').trim(); // fd 0 = stdin
} else {
    // Prompt with hidden input
    token = await promptSecret('Enter API token:');
}
```

**Non-secret config can use env vars:**

```bash
# These are fine in environment variables (not sensitive)
export MYCLI_API_ENDPOINT=https://api.example.com
export MYCLI_LOG_LEVEL=debug
export MYCLI_TIMEOUT=30

# Rule: if it's okay in logs, it's okay in env vars
# Secrets should never appear in logs → never in env vars
```

**Why it matters:**

- **Visibility**: Environment variables are visible in `ps auxe` output to all users on the system
- **Inheritance**: Env vars are inherited by all child processes, expanding the attack surface
- **Logs**: They appear in error logs, crash dumps, and debug output
- **History**: Commands with env vars end up in shell history files
- **No protection**: Unlike files, env vars have no permission controls

Files with mode 600, secret managers, or interactive prompts provide actual security.

Reference: [OWASP - Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html), [clig.dev - Environment variables](https://clig.dev/#environment-variables)
