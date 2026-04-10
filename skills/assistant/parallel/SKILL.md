---
name: parallel
description: Run a task in a background sub-agent so you can continue working on other
  things. Use when explicitly invoked via the '/parallel' slash command. Never auto-triggers
  from natural language.
metadata:
  disable-model-invocation: true
  category: assistant
  tags:
  - agent
  - parallel
  - background
  - sub-agent
  - workflow
  status: ready
  version: 2
  triggers:
    positive:
    - "/parallel refactor the auth module"
    - "/parallel /promptify audit all skills against our findings doc"
    negative:
    - run this in the background and fix all lint errors in src/
    - spawn an agent to update the changelog
    - Fix the bug in the checkout flow.
    - Review this pull request.
    guidance: |-
      `parallel` is a slash-command-only skill. It MUST be invoked explicitly via `/parallel`.
      Never auto-trigger from natural language like "in the background" or "spawn an agent".
      Only the `/parallel` slash command activates this skill.
---

# Parallel

Run the given task in a background sub-agent so you can continue working on other things.

## Workflow

### 1. Parse input

The user's input is:

$ARGUMENTS

Determine whether it is a **skill invocation** or a **plain text task**.

### 2. Detect skill invocations

If the input starts with `/` (e.g., `/promptify`, `/review-pr`, `/pr-comments-address TICKET-123`), it is a skill invocation:

1. Extract the skill name (the word after `/`) and any remaining text as the skill arguments.
2. In the Agent tool prompt, instruct the sub-agent to use the **Skill tool** with the extracted skill name and arguments. For example, if the input is `/cc fix auth bug`, tell the agent: "Use the Skill tool with skill 'cc' and args 'fix auth bug'."

### 3. Build plain text tasks

If the input does NOT start with `/`, pass it directly as the Agent tool prompt.

### 4. Execute

Use the Agent tool with `run_in_background: true`. Do NOT block on the agent's result. Continue responding to the user immediately after launching it. When the agent completes, report the result.

## Examples

### Positive Trigger

User: "/parallel /promptify audit all skills against our findings doc."

Expected behavior: Launch a background agent that invokes the `promptify` skill with args "audit all skills against our findings doc."

### Non-Trigger

User: "Fix the bug in the checkout flow."

Expected behavior: Do not use `parallel`; execute the task directly in the foreground.

## Troubleshooting

### Agent Does Not Start

- Error: The background agent fails to launch.
- Cause: Missing or malformed Agent tool parameters.
- Solution: Ensure `run_in_background: true` is set and the prompt is a non-empty string.

### Skill Not Found in Sub-Agent

- Error: The sub-agent reports the skill does not exist.
- Cause: The skill name extracted from the `/` prefix does not match any available skill.
- Solution: Verify the skill name matches an installed skill. Check available skills with `/help`.
