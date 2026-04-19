# Sections

This file defines all sections, their ordering, impact levels, and descriptions for CLI design rules.

---

## 1. Commands & Naming (cli-commands)

**Impact:** MEDIUM
**Description:** Command naming and structure conventions that make CLIs intuitive, typeable, and memorable.

## 2. Flags & Arguments (cli-flags)

**Impact:** HIGH
**Description:** Standard flag conventions that enable users to transfer knowledge between tools and build muscle memory.

## 3. Configuration (cli-config)

**Impact:** MEDIUM
**Description:** Configuration precedence and file location patterns that make CLIs predictable and scriptable.

## 4. Output & Streams (cli-output)

**Impact:** HIGH
**Description:** Proper output stream separation (stdout/stderr) that enables command composition and piping.

## 5. Error Handling (cli-errors)

**Impact:** CRITICAL
**Description:** Clear, actionable error messages that guide users to solutions instead of frustrating them.

## 6. Signals & Lifecycle (cli-signals)

**Impact:** HIGH
**Description:** Proper signal handling (Ctrl-C) with timeout and force options for responsive, trustworthy tools.

## 7. Security (cli-secrets)

**Impact:** CRITICAL
**Description:** Secure handling of credentials and secrets, avoiding environment variables and other insecure patterns.

## 8. Distribution (cli-distribution)

**Impact:** LOW
**Description:** Packaging and distribution patterns that simplify installation, updates, and uninstallation.
