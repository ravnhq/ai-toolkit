# Workflow Patterns

## Pattern 1: Sequential Orchestration

For tasks with strict step ordering, dependencies, and validation gates.

```markdown
Process a document:

1. Analyze the input (run analyze.py)
   - Verify: output contains expected fields
2. Transform content (run transform.py)
   - Verify: no data loss, format correct
3. Validate output (run validate.py)
   - Verify: all checks pass
4. Generate final artifact
   - Verify: output matches template

If any step fails, stop and report the error with context.
```

**When to use**: Multi-step processes where each step depends on the previous one. Include per-step validation and rollback paths.

## Pattern 2: Conditional Workflows

For tasks with branching logic based on input type or context.

```markdown
1. Determine the task type:
   **Creating new content?** → Follow "Creation workflow" below
   **Editing existing content?** → Follow "Editing workflow" below

2. Creation workflow:
   a. Gather requirements
   b. Generate from template
   c. Validate output

3. Editing workflow:
   a. Read existing content
   b. Apply modifications
   c. Verify changes preserved original structure
```

**When to use**: Tasks where the approach varies based on input characteristics.

## Pattern 3: Multi-Service Coordination

For workflows orchestrating multiple tools or APIs in phases.

```markdown
Phase 1: Data gathering
- Query service A for user data
- Query service B for configuration
- Gate: verify both responses are valid before proceeding

Phase 2: Processing
- Combine data from Phase 1
- Apply business logic
- Gate: validate output schema

Phase 3: Output
- Write results to target system
- Verify write succeeded
```

**When to use**: Workflows spanning multiple external services. Use validation gates between phases to prevent cascading failures.

## Pattern 4: Iterative Refinement

For tasks requiring draft-review-improve cycles.

```markdown
1. Generate initial draft
2. Quality check against criteria:
   - [ ] Criterion A met?
   - [ ] Criterion B met?
   - [ ] Criterion C met?
3. If any criterion fails:
   - Identify specific deficiency
   - Apply targeted fix
   - Return to step 2
4. Stop when: all criteria pass OR 3 iterations completed
5. Finalize output
```

**When to use**: Creative or analytical tasks where first output rarely meets quality bar. Always include explicit stop criteria to prevent infinite loops.

## Pattern 5: Context-Aware Tool Selection

For skills that choose between tools or approaches based on context.

```markdown
Select approach based on input:

- **Small file (<1MB)**: Process in memory
  - Rationale: fast, no temp files
- **Large file (1-100MB)**: Stream processing
  - Rationale: memory-safe, handles most cases
- **Very large file (>100MB)**: Chunked processing with progress
  - Rationale: prevents timeout, shows progress
- **Fallback**: If format is unrecognized, ask user for clarification

Always state which approach was chosen and why.
```

**When to use**: Skills where the optimal approach depends on input characteristics. Include explicit decision criteria, fallback paths, and transparent rationale.

## Pattern 6: Domain-Specific Intelligence

For skills embedding compliance rules, business logic, or domain knowledge.

```markdown
Before executing any database operation:

1. Check against access policy:
   - Production tables: read-only, no DELETE/UPDATE without approval
   - Staging tables: full access
   - PII columns: mask in all output

2. Validate query:
   - Must include WHERE clause for UPDATE/DELETE
   - Must use parameterized queries (no string interpolation)
   - Must respect rate limits (max 10 queries/minute)

3. Execute and audit:
   - Log query, timestamp, and result count
   - Flag any anomalies (empty results, unexpected row counts)
```

**When to use**: Skills where domain rules, compliance requirements, or business logic must be enforced before tool calls.

## Choosing a Structure for SKILL.md

| Skill Type | Recommended Structure |
|-----------|----------------------|
| Sequential processes | Pattern 1: step-by-step with validation gates |
| Tool collections | Task-based: Quick Start → Task 1 → Task 2 |
| Standards/guidelines | Reference: Guidelines → Specifications |
| Multi-capability systems | Capabilities: Core Capabilities → Feature 1 → Feature 2 |

Patterns can be mixed. Most skills combine 2-3 patterns.
