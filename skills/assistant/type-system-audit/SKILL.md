---
name: type-system-audit
description: 'Audit a repository for type-system weaknesses using recent bug-fix commits
  as hard evidence. Produces prioritized findings tied to specific commits showing
  which types allowed real bugs. Use when: reviewing type safety, auditing types,
  analyzing type bugs. Triggers on: type audit, type system review, audit types, type
  safety audit.'
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
- Agent
metadata:
  category: assistant
  tags:
  - types
  - audit
  - static-analysis
  - code-quality
  status: ready
  version: 6
---

# Type-System Audit

Audit a repository for type-system weaknesses using bug-fix commits as hard evidence—not speculation. Identify which types allowed invalid states that caused real bugs, and recommend stricter types that would prevent entire defect classes. All findings are tied to specific commits for credibility.

## Workflow

### Phase 1: Identify Language and Type System

Determine the primary language(s) and type system in use. Use the table below to adapt the audit approach:

| Language | Nullability patterns | Sum types | Boundary validation | File extensions |
|----------|---------------------|-----------|--------------------|-----------------|
| TypeScript | `T \| null \| undefined`, optional chaining | Discriminated unions, literal types | `zod`, `io-ts`, `yup` | `.ts`, `.tsx` |
| Swift | `Optional<T>` / `?`, force-unwrap `!` | `enum` with associated values | `Codable`, custom `init` | `.swift` |
| Kotlin | `T?`, `!!`, null-safe operators | `sealed class` / `when` | `@Serializable`, `require()` | `.kt` |
| Python | `Optional[T]`, `None` checks | `Union`, `Literal`, `TypedDict` | `pydantic`, `attrs` | `.py`, `.pyi` |

### Phase 2: Commit Selection

Run Stage 1 first (high-signal conventional commits):

```bash
# Stage 1: conventional commits (high signal)
git log --oneline --since="90 days ago" | grep -iE "^[0-9a-f]+ (fix|bugfix|hotfix|patch)[\(:]"

# Stage 2: broader keyword sweep (fallback)
git log --oneline --since="90 days ago" | grep -iE "fix|bug|crash|error|null|undefined|invalid|wrong|closes|resolves|#[0-9]+"
```

Decision points:
- Prefer Stage 1 if 10+ results; fall back to Stage 2 only when Stage 1 yields fewer than 5.
- Expand to `--since="180 days ago"` if total candidates are still fewer than 5.
- For squash-merge repos: read commit bodies with `git log --format="%H %s%n%b" --since="90 days ago"` to surface original PR messages.

Select 10–20 candidates. Prefer commits touching domain logic, data models, or API boundaries.

### Phase 3: Per-Commit Inspection

For each candidate commit, inspect the diff:

```bash
git show {sha} --stat                 # Overview: which files changed
git show {sha} -- '*.ts'              # Scope to language-specific files
```

Large-diff guidance (>500 lines): use `--stat` to identify type-definition files, then read only those files. Skip auto-generated files (e.g., `*.generated.ts`, `schema.graphql.ts`).

Look for: type definitions and interfaces changed, added guards or normalization logic, null checks added, validation added at API boundaries, test changes that hint at a shape mismatch.

### Phase 4: Evidence Gathering

Apply the "What to Look For" patterns to each commit. Record every match as a candidate finding.

Discard criteria — skip a commit if:
- The fix is a pure logic error with no type involvement (e.g., off-by-one, wrong operator)
- The change is only to comments, docs, or non-typed configuration
- The fix is in test setup code with no production type implications

### Phase 5: Finding Generation

For each confirmed finding, fill out the per-finding template. Cite the specific commit SHA and the exact file and type involved.

To check if a weakness persists today:

```bash
git show HEAD:path/to/type.ts   # Read current version of the type file
```

Cross-validation gate — before finalizing a finding, answer:
- "Would a stricter type have prevented this at compile time?" — If **no**, discard. If **yes**, keep. If **partially**, mark `[partial]`.

### Phase 6: Output Assembly

Produce all required output sections. Prioritize findings by blast radius: how many call sites or bugs would a stricter type prevent?

Quality gate before finalizing: verify all 7 template fields are filled for every finding. A finding with empty fields is not ready.

## What to Look For

Refer to `references/common-type-weakness-patterns.md` for detailed explanations and examples of each weakness type. Core patterns to recognize:

- **Nullable/optional values modeled too loosely** — fields that can be `null` or absent but aren't encoded in the type
- **Sentinel values masking missing data** — `""`, `"null"`, `-1`, `0` used where `null | T` would be correct
- **External API shapes drifting from domain types** — raw API responses accepted as-is instead of mapped at the boundary
- **Unions or enums that are too broad** — accepting a wider value set than the domain allows
- **Invalid states representable as valid objects** — field combinations encoding impossible domain states (e.g., `status: "complete"` with `completedAt: null`)
- **Guard or normalization logic compensating for permissive types** — runtime checks that exist only because the type is too wide
- **Function signatures accepting impossible data** — parameters the function will immediately reject at runtime
- **Async/Promise violations** — uncaught promise rejections, missing awaits, lost type information in chains
- **Missing type narrowing after checks** — redundant null checks after guards that should narrow types
- **Using `any` as a workaround** — type issues solved with `any` instead of fixing the underlying type

## Per-Finding Template

| Field | Content |
|-------|---------|
| **Commit** | SHA and one-line message |
| **Bug fixed** | What the bug was and how it manifested |
| **Invalid state allowed** | The exact invalid value or combination the type permitted |
| **Type weakness** | Which type, field, or signature was too permissive |
| **Stricter design** | The proposed type that would make the invalid state unrepresentable |
| **Fix location** | File and line range (type definition or function signature) |
| **Benefit** | What defects or guards the stricter type eliminates |

## Rules

1. **Cite commits.** Every finding must reference a specific commit SHA. No commit, no finding.
2. **Prefer 5–8 findings.** Depth over breadth. Five well-evidenced findings beat twenty shallow ones.
3. **No generic advice.** Do not recommend "add more type annotations" unless tied to a specific bug and commit.
4. **No stylistic cleanup.** Do not flag naming or formatting issues unless they directly enabled a type bug.
5. **Flag inferences.** If you infer a bug's cause from the diff rather than reading the original report, mark it `[inferred]`.
6. **Deduplicate recurring defects.** If multiple commits fix the same type weakness (same type, same field), merge into one finding listing all SHAs. Increase priority — recurring defects are higher blast radius.

## Required Output Sections

````markdown
## Commits Reviewed

| SHA | Date | Message |
|-----|------|---------|
| {sha1} | {date1} | {message1} |
| {sha2} | {date2} | {message2} |

## Strongest Findings

### Finding 1

| Field | Content |
|-------|---------|
| **Commit** | {sha} — {one-line message} |
| **Bug fixed** | {what the bug was and how it manifested} |
| **Invalid state allowed** | {exact invalid value or combination the type permitted} |
| **Type weakness** | {which type, field, or signature was too permissive} |
| **Stricter design** | {proposed type that makes the invalid state unrepresentable} |
| **Fix location** | `{file}:{line-range}` |
| **Benefit** | {defects or guards the stricter type eliminates} |

### Finding 2

| Field | Content |
|-------|---------|
| **Commit** | {sha} — {one-line message} |
| **Bug fixed** | {what the bug was and how it manifested} |
| **Invalid state allowed** | {exact invalid value or combination the type permitted} |
| **Type weakness** | {which type, field, or signature was too permissive} |
| **Stricter design** | {proposed type that makes the invalid state unrepresentable} |
| **Fix location** | `{file}:{line-range}` |
| **Benefit** | {defects or guards the stricter type eliminates} |

<!-- Repeat Finding N block for each finding (target 5–8 total) -->

## Bugs Better Types Would Have Prevented

- `{sha1}` — {description of the bug}. A stricter type (`{proposed type}`) would have {caught this at compile time / made this state unrepresentable / forced callers to handle the missing case explicitly}.
- `{sha2}` — {description of the bug}. {How the stricter type catches it at compile time}.

## Tests / Guards Better Types Could Replace

| File | Guard / Test | Type Weakness It Compensates | Replacement |
|------|-------------|------------------------------|-------------|
| `{file}` | `{guard or test description}` | `{type}` is too permissive — allows `{invalid value}` | Narrow to `{proposed type}`; remove guard |
| `{file}` | `{guard or test description}` | `{type}` is too permissive — allows `{invalid value}` | Narrow to `{proposed type}`; remove guard |

## Priority Type Refactors

1. **`{TypeName}`** — `{file}` — Change `{current type}` to `{proposed type}`. Addresses commits: {sha1}, {sha2}.
2. **`{TypeName}`** — `{file}` — Change `{current type}` to `{proposed type}`. Addresses commits: {sha1}.
3. **`{TypeName}`** — `{file}` — Change `{current type}` to `{proposed type}`. Addresses commits: {sha1}, {sha2}, {sha3}.
````

## Examples

### Positive Trigger

User: "audit the type system in this repo for weaknesses in recent bug-fix commits"

Expected behavior: Use `type-system-audit` to run `git log` for recent fix commits, inspect each for type-related weaknesses, generate findings using the per-finding template, and produce all required output sections.

---

User: "review type safety — we've been having a lot of null crashes"

Expected behavior: Use `type-system-audit` to mine bug-fix commits for evidence of null/optional type weaknesses, produce findings tied to specific commits, and recommend priority refactors.

### Non-Trigger

User: "enable strict mode in tsconfig.json"

Expected behavior: Do not use `type-system-audit`. The user wants a configuration change, not a commit-based audit. Apply the change directly.

---

User: "what types does this module export?"

Expected behavior: Do not use `type-system-audit`. The user wants to understand the existing API surface, not audit it for weaknesses.

## Troubleshooting

### No Fix Commits Found

- Error: No fix commits found in the last 90 days.
- Cause: The repo is new, uses a different commit message convention, or the grep pattern is too narrow.
- Solution: Expand the `--since` window or adjust the grep pattern to match the project's commit style (e.g., `closes`, `resolves`, `patch`).

### No Type-Related Findings

- Error: All commits reviewed but no type-related findings produced.
- Cause: Fixes were logic errors or configuration issues unrelated to type permissiveness.
- Solution: Report that no strong evidence was found in the sampled commits. Suggest expanding the commit window or targeting a specific subsystem known to have bugs.

### No Static Type System

- Error: Language has no static type system (e.g., plain JavaScript, Python without annotations).
- Cause: Project does not use a type checker.
- Solution: Audit runtime validation patterns instead — look for missing schema validation at boundaries, missing null checks, and data shape assumptions baked into code. Note this adaptation in the output.

### Squash-Merge History

- Error: Commits are squash-merged; individual fix commits aren't visible in `git log --oneline`.
- Cause: The repo uses a squash-merge workflow, collapsing PR commits into one.
- Solution: Read commit bodies with `git log --format="%H %s%n%b" --since="90 days ago"` to surface original PR messages. Use `--stat` to scope large squash diffs to type-definition files before reading.

### Monorepo With Multiple Languages

- Error: `git log` returns commits spanning many packages and languages, making signal extraction hard.
- Cause: A monorepo with unrelated packages mixed in commit history.
- Solution: Ask the user which package or path to target. Then use path-scoped log: `git log --oneline --since="90 days ago" -- packages/my-service/`.

### Diffs Too Large for Context

- Error: A candidate commit diff exceeds available context; full inspection isn't feasible.
- Cause: Large refactor or migration commit bundled with the fix.
- Solution: Use `git show {sha} --stat` to identify type-definition files, then read only those with `git show {sha} -- path/to/types.ts`. Skip auto-generated files (e.g., `*.generated.ts`).
