# Testing and Iteration

## Success Criteria

### Quantitative

- ~90% triggering success on 10-20 relevant prompts
- Reduced tool-call count versus no-skill baseline
- Zero failed API calls per workflow run

### Qualitative

- User does not need to prompt for next steps
- Workflow completes without user correction
- Consistent outputs across sessions

## Testing Areas

### 1. Triggering Tests

Verify the skill activates (and doesn't activate) correctly.

**Positive prompts** — should trigger the skill:
- Direct requests using trigger keywords
- Paraphrased versions of the same intent
- Partial or implicit references to the skill's domain

**Negative prompts** — should NOT trigger the skill:
- Requests in adjacent but different domains
- Generic requests that don't match the skill's scope
- Requests that match keywords but not intent

**Debug question**: Ask Claude "When would you use the [skill name] skill?" to verify understanding.

### 2. Functional Tests

Verify the skill produces correct output.

- Valid output format and structure
- Successful API/tool calls (no errors)
- Correct handling of edge cases
- Proper error messages for invalid input

### 3. Performance Comparison

Compare with and without the skill:

| Metric | Without Skill | With Skill |
|--------|--------------|------------|
| Messages to complete task | | |
| Tool calls | | |
| Failure rate | | |
| User corrections needed | | |

## Iteration Diagnostics

### Undertriggering

**Symptoms**: User explicitly invokes the skill or skill is ignored for relevant tasks.

**Fixes**:
- Add more specific trigger phrases to description
- Include keyword variations users actually use
- Broaden scope language if too narrow

### Overtriggering

**Symptoms**: Skill activates for unrelated tasks, interfering with other workflows.

**Fixes**:
- Add negative triggers ("NOT for...", "Do not use when...")
- Tighten scope language in description
- Make trigger conditions more specific

### Execution Failures

**Symptoms**: Incorrect results, skipped steps, inconsistent quality.

**Fixes** (in priority order):
1. Replace ambiguous instructions with explicit checks
2. Add concrete examples of expected output
3. Move critical instructions to the top of SKILL.md
4. Replace verbose explanations with concise examples
5. Use scripts for validation instead of natural language instructions
6. Keep SKILL.md under 5,000 words — move detail to references
