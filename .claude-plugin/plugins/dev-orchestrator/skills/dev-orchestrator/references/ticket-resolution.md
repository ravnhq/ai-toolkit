# Ticket Resolution — Phase 0 Deep Dive

Authoritative reference for `dev-orchestrator`'s opt-in **ticket resolution phase**. Load this when SKILL.md's Phase 0 detects an issue-tracker reference in the user prompt (Linear, Jira, GitHub Issues, or Notion). It documents every detail SKILL.md only summarizes: the detection regex per tracker, the disambiguation rules when patterns collide, the MCP-based fetch contract, the context-extraction shape, how the result is handed off to Phase 1, and the failure modes.

Phase 0 is **purely additive** — when no ticket reference is detected, it is a no-op and the existing Phase 1 → 5 flow runs unchanged. dev-orchestrator stays project-agnostic; this reference lists Linear as the first fully-specified integration and treats the other trackers as stub points keyed by MCP tool name.

## When this phase fires

Phase 0 activates when **either** of these holds:

1. The prompt contains at least one ticket reference matching a known detection pattern (see "Detection patterns" below).
2. The user explicitly passed `--ticket <id>` as a flag (forces resolution even if the pattern matcher missed it).

When neither holds, Phase 0 returns immediately with no side effects and the orchestrator proceeds straight to Phase 1.

## Detection patterns

The orchestrator scans the prompt once for each pattern below. **Order matters** when patterns collide — apply the first that produces a clean match.

| Tracker | Pattern (Ruby/JS regex) | Example matches | Notes |
| --- | --- | --- | --- |
| Linear | `\b([A-Z][A-Z0-9_]+)-(\d+)\b` | `ABC-42`, `XYZ-123`, `DEV_V2-7` | Linear team prefix uppercase. Same shape as Jira — see disambiguation below. |
| Jira | `\b([A-Z][A-Z0-9_]+)-(\d+)\b` | `PROJ-456`, `INFRA-12` | Identical regex to Linear. Disambiguated by project config. |
| GitHub Issues (short) | `(?<![\w/])#(\d+)\b` | `#123` | Only matches when the repo context is unambiguous (current repo). |
| GitHub Issues (full) | `\b([\w.-]+)/([\w.-]+)#(\d+)\b` | `acme/web#456` | Use this when the prompt references a different repo. |
| Notion page | `https?://(?:www\.)?notion\.so/[\w-]+/[\w-]+-([0-9a-f]{32})` | `https://notion.so/team/Spec-…-abc123…` | Match by the 32-char hex page id. |

Strip captured tokens from the prompt body **before** Phase 1 sees it, the same way Phase 1's worktree flags are stripped, so they do not leak into subtask descriptions.

### Tracker disambiguation (Linear vs Jira)

Linear and Jira share the `PREFIX-N` shape. Choose between them with this priority cascade:

1. **Explicit per-prompt override**: `--tracker linear` or `--tracker jira` always wins.
2. **Project config** at `<repo>/.dev-orchestrator.yml`:

   ```yaml
   ticket-resolution:
     default-tracker: linear   # or jira | github | notion
     prefixes:
       ABC: linear             # explicit prefix → tracker mapping
       PROJ: jira
   ```

3. **MCP availability**: if only one of `mcp__linear__get_issue` / `mcp__jira__get_issue` is registered in the current host, pick the one that exists.
4. **Fallback**: ask the user *one* clarifying question (`Is ABC-42 a Linear or Jira ticket?`) and persist the answer to `.dev-orchestrator.yml` so future runs do not prompt again.

When the prompt contains tickets from **multiple trackers** (e.g., `ABC-42` and `acme/web#7`), resolve each independently and concatenate their contexts in the order they appeared in the prompt.

## Fetch contract (MCP)

Phase 0 uses **MCP only** — no CLI shells, no API tokens stored in the skill. For each resolved tracker, call the corresponding MCP tool:

| Tracker | MCP tool | Arguments |
| --- | --- | --- |
| Linear | `mcp__linear__get_issue` | `{ "id": "<TICKET-ID>" }` |
| Jira | `mcp__jira__get_issue` | `{ "key": "<TICKET-KEY>" }` *(stub — implement per project's Jira MCP server)* |
| GitHub Issues | `mcp__github__get_issue` | `{ "owner": "...", "repo": "...", "issue_number": N }` *(stub — implement per project's GitHub MCP server)* |
| Notion | `mcp__notion__get_page` | `{ "page_id": "<32-hex-id>" }` *(stub — implement per project's Notion MCP server)* |

**Discovery rule:** before invoking, the orchestrator must confirm the tool is registered in the MCP file system (`mcps/<server>/tools/<tool>.json`). If the tool is absent, surface a clear error (see Failure modes) and either degrade to a no-op Phase 0 (continue without ticket context) or stop entirely, depending on the `--ticket` flag presence:

- `--ticket` was **explicit**: stop with an error. The user asked for resolution and it cannot proceed.
- Ticket was **only inferred from pattern detection**: degrade — log a one-line warning and continue with the raw prompt as Phase 1 input.

**Read the MCP tool's descriptor before calling**, as required by `mcp_file_system` guidance — check the JSON schema for the exact argument shape since vendor MCPs occasionally rename fields between versions.

## Context extraction

Once the MCP tool returns the ticket payload, extract a normalized context envelope. The envelope shape is the **same across trackers** so Phase 1 downstream consumers do not need to care which tracker the data came from:

```yaml
ticket:
  id: ABC-42                          # canonical id as appeared in the prompt
  tracker: linear                       # linear | jira | github | notion
  title: "Recognition overhaul"         # short summary
  state: "In Progress"                  # ticket state at fetch time
  assignee: "user@example.com"          # optional
  description: |                        # full description / acceptance criteria
    ...
  acceptance_criteria: |                # parsed from description if structured
    - [ ] criterion 1
    - [ ] criterion 2
  labels: ["api", "high-priority"]      # optional
  url: "https://linear.app/team/issue/ABC-42"
```

Extraction rules per tracker:

- **Linear** → fields map 1:1 (`identifier` → `id`, `title`, `state.name` → `state`, `description`, `assignee.email`, `labels[].name`). The `description` is markdown; if it contains a `## Acceptance Criteria` section, parse that into `acceptance_criteria` as a checklist. The `url` is `https://linear.app/{teamKey}/issue/{identifier}`.
- **Jira** → `fields.summary` → `title`, `fields.status.name` → `state`, `fields.description` → `description`, `fields.assignee.emailAddress` → `assignee`. Jira descriptions are ADF (Atlassian Document Format); flatten to markdown before storing.
- **GitHub Issues** → `title`, `state`, `body` → `description`, `assignees[0].login` → `assignee`, `labels[].name` → `labels`, `html_url` → `url`. No native acceptance-criteria field; parse from body if a checklist exists.
- **Notion pages** → `properties.title` → `title`, `properties.Status` → `state`, page body blocks flattened to markdown → `description`. No native assignee unless a `Person` property exists.

If extraction fails for any reason (malformed payload, missing required field), treat it the same as an MCP fetch failure (see Failure modes).

## Phase 1 hand-off

The extracted envelope is **prepended** to the original prompt (minus the stripped ticket id) before Phase 1 runs its classification. The combined input to Phase 1 looks like:

```text
[ticket:ABC-42 / Linear / state=In Progress / assignee=user@example.com]
Title: Refactor authentication module
Acceptance criteria:
  - [ ] session model with rotation-safe refresh tokens
  - [ ] OAuth callback scoped to organization context
  - [ ] new endpoints under /v1/auth with rate limiting
URL: https://linear.app/team/issue/ABC-42

Original user prompt:
<original prompt text with the bare "ABC-42" reference stripped>
```

This gives Phase 1 strictly more information than the raw prompt would have provided, so the classification heuristics improve naturally:

- The acceptance-criteria checklist often **decomposes into separable tasks**, so Phase 1's split-along-natural-boundaries rule has cleaner anchors.
- The `labels` array can inform dependency classification (e.g., `api` + `web` labels strongly imply at least two task groups).
- The `state` field can short-circuit the run when the ticket is already `Done` or `Cancelled` — print a warning and ask the user to confirm before proceeding.

## Worktree-mode synergy

When Phase 0 resolved a ticket **and** Phase 1 sets the worktree flag, the resolved ticket id drives the **integration branch** name in Phase 3 — not the per-task worktree names. The orchestrator passes `--ticket <id>` (and an optional `--slug` derived from the prompt) into `setup-integration-branch.sh`:

```bash
bash skills/assistant/dev-orchestrator/scripts/setup-integration-branch.sh \
  --ticket "ABC-42" \
  --slug "auth-refactor"
# emits, e.g.:
# INTEGRATION_BRANCH=ticket/ABC-42-auth-refactor
# BASE_BRANCH=develop
```

By default the integration branch is `ticket/<TICKET-ID>` (e.g. `ticket/ABC-42`). With a `--slug`, the name becomes `ticket/<TICKET-ID>-<slug>` so the branch communicates both the ticket and the high-level intent. A `--prefix <p>` flag substitutes the leading `ticket/` segment when the project uses a different naming convention (`agent/ABC-42`, `linear/ABC-42`, etc.).

Each per-task worktree (provisioned later in Phase 3 via `setup-worktree.sh --base "$INTEGRATION_BRANCH"`) keeps its own auto-derived task-level branch name — typically `agent/<task-slug>-<unix>`. This means the ticket id appears once on the long-lived integration branch and the eventual PR title, while individual task branches stay short and disposable.

When Phase 4.5 hands the integration branch off to `agent-pr-creator`, the orchestrator passes the resolved ticket URL so the PR body includes a back-link. Linear's GitHub integration (and the equivalent Jira / Notion automations) then auto-attach the PR to the source ticket without manual stitching.

A worked end-to-end pass that starts from `/orchestrate --worktree implement ABC-42` is covered below.

## Failure modes

| Failure | Cause | Action |
| --- | --- | --- |
| MCP tool not registered | Linear (or matching tracker) MCP server is not installed in the host. | If `--ticket` was explicit: stop with `Ticket resolution requested but no <tracker> MCP is available. Install <server> or remove --ticket.` If pattern-only: warn `Could not resolve <id> — no <tracker> MCP available. Continuing without ticket context.` and proceed to Phase 1 with the raw prompt. |
| MCP tool returned 404 / not found | Ticket id is wrong, or the user lacks read access. | Stop. Surface the tracker's error message verbatim. Do not silently continue — the user expected the ticket to exist. |
| MCP tool returned permission denied | OAuth scopes or workspace access too narrow. | Stop. Print: `<tracker> denied access to <id>. Check the MCP server's auth scopes.` Do not retry. |
| MCP tool timed out / network failure | Transient. | Retry once after 2 s. On second failure, degrade as for "tool not registered" — warn and continue without ticket context. |
| Ticket state is `Done` / `Cancelled` / `Closed` | Likely a stale reference. | Surface `<id> is in state '<state>' — proceed anyway?` and **stop until the user confirms**. Do not assume the user wants to re-run completed work. |
| Multiple tickets resolved, one fails | Mixed batch. | Resolve the rest, drop the failing one from the context envelope, warn the user, and proceed. Do not let one bad id block the whole run. |
| Acceptance-criteria parsing failed | Description format doesn't match expected markdown structure. | Set `acceptance_criteria: null` and keep `description` intact. Phase 1 still sees the full description text. |

## Worked example

**User prompt:**

> `/orchestrate --worktree implement ABC-42 end-to-end and merge to main when green`

**Phase 0 trace:**

1. Detect pattern `ABC-42` → matches Linear regex `[A-Z][A-Z0-9_]+-\d+`.
2. Disambiguate: `.dev-orchestrator.yml` has `prefixes.ABC: linear` → use Linear.
3. Confirm MCP tool `mcp__linear__get_issue` is registered. (If absent, since `--ticket` was *inferred* not explicit, warn and continue with raw prompt.)
4. Call `mcp__linear__get_issue` with `{"id": "ABC-42"}`.
5. Parse the response into the context envelope:

   ```yaml
   ticket:
     id: ABC-42
     tracker: linear
     title: "Refactor authentication module"
     state: "In Progress"
     assignee: "kv@example.com"
     description: |
       Consolidate the authentication flow. Touches the API, the web app, and the shared SDK.
     acceptance_criteria: |
       - [ ] Session model added with rotation-safe refresh tokens
       - [ ] OAuth callback flow scoped to organization context
       - [ ] /v1/auth endpoints added with rate limiting
     labels: ["api", "web", "sdk", "high-priority"]
     url: "https://linear.app/team/issue/ABC-42"
   ```

6. Strip `ABC-42` from the original prompt body.
7. Hand the combined envelope + remaining prompt to Phase 1.

**Phase 1 sees** three distinct acceptance criteria + three tracker labels → classifies as **three soft-sequenced tasks** with the worktree flag still on (carried over from `--worktree` in the original prompt). Each acceptance criterion becomes one task; the labels (`api`, `web`, `sdk`) inform the wave grouping.

**Phase 2 — Layout C** is presented with two waves (session model first, then OAuth callback + endpoints in parallel) and the ticket id in the options echo: `Worktree options: integration=ticket/ABC-42-auth-refactor, base=develop (auto: develop/dev preferred; else newer of main/master), validate=on, merge=on, keep-branch=off`.

**Phase 3 Mode 3** provisions the integration branch `ticket/ABC-42-auth-refactor` off `origin/develop`. Wave 1 provisions one per-task worktree (the session model) and runs it; on success it merges into the integration branch. Wave 2 then provisions two per-task worktrees off the wave-1-merged tip and dispatches them in parallel; each merges into the integration branch sequentially after returning. Every task branch name stays short (`agent/<slug>-<unix>`), but the integration branch carries the ticket id.

**Phase 4.5** validates the integration branch, pushes it, and hands off to `agent-pr-creator`. The PR body includes the ticket URL `https://linear.app/team/issue/ABC-42`, so Linear's GitHub integration auto-attaches the PR to ticket ABC-42.

**Phase 5** hands off to `qa-orchestrator` with the new PR number as the scope. The QA report quotes the verdict back to the user; the PR (still linked to ABC-42) is now ready for human review.

## Configuration reference

`<repo>/.dev-orchestrator.yml` (optional, project-local):

```yaml
ticket-resolution:
  # Default tracker when the regex is ambiguous (Linear vs Jira).
  default-tracker: linear

  # Explicit prefix → tracker overrides.
  prefixes:
    ABC: linear
    PROJ: jira
    OPS: linear

  # Optional per-tracker overrides.
  linear:
    team_default: ABC           # used when prompt has a bare "#123" GitHub-style reference but linear is the project's tracker
  github:
    default_repo: acme/web      # owner/repo to resolve bare "#N" against

  # Behavior when the matching MCP server is unavailable.
  on-missing-mcp: warn          # warn | error — defaults to warn for pattern-detected, error for --ticket explicit
```

When `.dev-orchestrator.yml` is absent, every option falls back to the safe default documented in the table above (`default-tracker: linear`, `on-missing-mcp: warn` for inferred / `error` for explicit).

## See also

- [`SKILL.md`](../SKILL.md) — Phase 0 stub that points here.
- [`dispatch-contract.md`](dispatch-contract.md) — the four-part isolated-agent contract every dispatch follows; ticket-derived integration-branch names flow through to the agents dispatched in Phase 3 + Phase 4.5.
- [`worktree-mode.md`](worktree-mode.md) — branch-naming integration when worktree mode is on.
- [`workflow.md`](workflow.md) — end-to-end scenarios; ticket resolution appears at the top of any scenario that starts with a ticket id.
