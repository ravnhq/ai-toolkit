---
title: Follow Configuration Precedence Order
impact: MEDIUM
tags: config, flags, environment
---

## Follow Configuration Precedence Order

Configuration should follow a clear precedence order: command-line flags override environment variables, which override config files, which override built-in defaults.

**Incorrect (unclear or inconsistent precedence):**

```bash
# Config file overrides flag (backwards!)
mycli deploy --environment staging
# Uses 'production' from config file, ignoring --environment flag
# User has no way to override config without editing the file

# No way to override config file settings
# Config file has: api_url: https://prod.example.com
mycli deploy --api-url https://dev.example.com
# Error: --api-url flag not supported
# Must edit config file to change (not scriptable)

# Environment variable ignored
MYCLI_TIMEOUT=30 mycli run
# Uses 10s timeout from config file, ignoring MYCLI_TIMEOUT
```

**Correct (clear precedence order):**

```bash
# Standard precedence (highest to lowest):
# 1. Command-line flags
# 2. Environment variables
# 3. Project config file (.mycli.yaml in current directory)
# 4. User config file (~/.config/mycli/config.yaml)
# 5. System config file (/etc/mycli/config.yaml)
# 6. Built-in defaults

# Example: Flag overrides everything
mycli deploy --environment staging
# Uses 'staging' from --environment flag
# Ignores MYCLI_ENVIRONMENT=production env var
# Ignores environment: production in config file

# Example: Env var overrides config files
MYCLI_ENVIRONMENT=staging mycli deploy
# Uses 'staging' from MYCLI_ENVIRONMENT env var
# Ignores environment: production in ~/.config/mycli/config.yaml

# Example: Project config overrides user config
# Project .mycli.yaml: timeout: 60
# User ~/.config/mycli/config.yaml: timeout: 30
mycli run
# Uses 60s from project config (more specific wins)

# Example: User config overrides system config
# User ~/.config/mycli/config.yaml: log_level: debug
# System /etc/mycli/config.yaml: log_level: info
mycli status
# Uses 'debug' from user config

# Show effective configuration
mycli config show
# environment: staging (from flag --environment)
# timeout: 60 (from project config .mycli.yaml)
# api_url: https://api.example.com (from user config)
# verbose: false (default)
```

**Implementation pattern:**

```javascript
function resolveConfig() {
    const config = {
        // 6. Built-in defaults (lowest priority)
        timeout: 10,
        verbose: false,
        environment: 'development',
    };

    // 5. System config
    const systemConfig = readConfig('/etc/mycli/config.yaml');
    Object.assign(config, systemConfig);

    // 4. User config
    const userConfig = readConfig('~/.config/mycli/config.yaml');
    Object.assign(config, userConfig);

    // 3. Project config (highest specificity for files)
    const projectConfig = readConfig('.mycli.yaml');
    Object.assign(config, projectConfig);

    // 2. Environment variables
    if (process.env.MYCLI_TIMEOUT) {
        config.timeout = parseInt(process.env.MYCLI_TIMEOUT);
    }
    if (process.env.MYCLI_ENVIRONMENT) {
        config.environment = process.env.MYCLI_ENVIRONMENT;
    }

    // 1. Command-line flags (highest priority)
    if (flags.timeout !== undefined) {
        config.timeout = flags.timeout;
    }
    if (flags.environment !== undefined) {
        config.environment = flags.environment;
    }

    return config;
}
```

**Config file locations:**

Follow XDG Base Directory specification on Linux/macOS:
- **Project config**: `.mycli.yaml` or `.mycli/config.yaml` in current directory
- **User config**: `~/.config/mycli/config.yaml` (preferred) or `~/.mycli.yaml` (legacy)
- **System config**: `/etc/mycli/config.yaml`

On Windows:
- **User config**: `%APPDATA%\mycli\config.yaml`
- **System config**: `C:\ProgramData\mycli\config.yaml`

**Why it matters:**

Users expect flags to override everything (scriptability). Environment variables enable per-session customization. Config files provide persistent preferences. Defaults catch everything else. Unclear precedence causes user frustration when flags get ignored or config can't be overridden.

Reference: [clig.dev - Configuration](https://clig.dev/#configuration), [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
