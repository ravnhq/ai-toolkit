---
name: grill-me
description: 'Interview the user relentlessly about a plan or design until reaching
  confidence through Socratic questioning. Use when: stress-testing a plan, probing
  design assumptions, validating feasibility. Triggers on: grill me, stress-test,
  interview me, validate plan, probe design.'
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
  - design
  - planning
  - questioning
  - decision-making
  - validation
  status: ready
  version: 5
---

# Grill Me

Interview the user relentlessly about a plan or design using structured Socratic questioning until reaching high confidence. Walk the decision tree systematically, uncover hidden assumptions, expose edge cases, and validate feasibility before implementation.

## Workflow

### Phase 1: Read Context and Scope

Before asking anything, gather the full context:

- Read any provided design documents, specs, or written plans
- Read relevant code if the user references existing systems
- Understand the scope: is this a new feature, refactor, infrastructure change, architecture shift?
- Identify the primary risk factors and dependencies

If the user hasn't provided context, ask them to share the plan first:

```
What's the design or plan you want me to grill you on? Please share:
- A brief description or goals
- Any relevant code or documentation
- Constraints or requirements
```

**Do not proceed until you have context to work with.**

### Phase 2: Identify Question Categories

Structure your questioning around these categories:

| Category | Focus | Example Questions |
|----------|-------|-------------------|
| **Requirements** | What is the user trying to solve? | "What problem does this solve?" "Who are the users?" "What success looks like?" |
| **Assumptions** | What is the user taking for granted? | "Why are you using technology X?" "What if that assumption is wrong?" "Have you validated this with users?" |
| **Constraints** | What are the boundaries? | "What are the hard constraints (time, budget, scale)?" "What are you not allowed to change?" "What's the deployment path?" |
| **Dependencies** | What else must be true? | "What other systems must exist?" "What's the critical path?" "What could block you?" |
| **Edge Cases** | What could break it? | "What happens at scale?" "What about error cases?" "What if X fails?" |
| **Validation** | How will you know it works? | "How will you measure success?" "What are your test criteria?" "How will you catch regressions?" |

### Phase 3: Build the Decision Tree

Map out the logical dependencies between decisions:

```
Primary decision
├── Sub-decision A
│   ├── Implementation choice A.1
│   └── Implementation choice A.2
├── Sub-decision B
│   ├── Validation approach B.1
│   └── Rollback plan B.2
└── Sub-decision C
```

Identify which decisions must be resolved first (blockers) and which can be explored in parallel.

**Important:** Ask about high-impact, high-uncertainty decisions first. Skip decisions that are already locked down (unless you spot contradictions).

### Phase 4: Ask Questions Sequentially

For each unresolved branch, ask exactly one focused question:

**Structure of each question:**

1. **Establish context** — briefly remind the user why this matters
2. **Ask the question** — specific, not open-ended
3. **Provide your recommended answer** — what you'd do or what you've seen work
4. **Flag risks** — what could go wrong if the opposite choice is made
5. **Pause for response** — wait for the user's answer before moving on

Example:

```
You're planning async message processing. The question is:
should messages be processed in order (FIFO) or can they be out of order?

My recommendation: enforce FIFO unless you have a specific reason not to.
Out-of-order processing complicates debugging and introduces race conditions.

Risk if you go out-of-order: state consistency bugs that are hard to reproduce.

What's your thinking here?
```

### Phase 5: Explore the Codebase When Applicable

If a question can be answered by reading code, do that instead of asking:

```bash
# Examples:
grep -r "MessageQueue" src/          # How are messages currently queued?
grep -r "error handling" src/        # What error patterns already exist?
find . -name "*.test.ts" | head -5   # What's the testing pattern?
```

Surface findings to the user:

```
I found that your existing API already has retry logic in [file:line].
Given that, my question becomes: should we reuse this pattern or replace it?
```

### Phase 6: Escalate on Conflicts

If the user's answer contradicts earlier statements or introduces new risks, surface this explicitly:

```
You said earlier that latency is critical, but now you're proposing a
synchronous validation step that could block for seconds.
How do you reconcile these constraints?
```

Do not accept contradictions silently. Push back gently but clearly.

### Phase 7: Recognize Completion Signals

Stop questioning when:

- **All high-impact decisions are resolved** — the user has clear answers to every critical question
- **All branches of the decision tree are explored** — you've walked the full dependency graph
- **Validation plan is solid** — the user knows how to measure success and catch failures
- **Risk mitigation is addressed** — for each major risk, there's a mitigation or acceptance
- **The user signals confidence** — they say "I'm confident now" or "This is locked"
- **You've reached a decision impasse** — the user is unwilling to change their mind despite contradictions (note this in your closing)

### Phase 8: Summarize and Confirm

When you've finished questioning, provide a brief summary:

```
## Summary

### Decisions Locked
- Message processing: FIFO with retry logic (max 3 retries)
- Deployment: Blue-green with health checks
- Monitoring: Custom metrics on latency percentiles

### Remaining Risks
- Database scaling: you identified this but haven't validated with ops yet
- Failover time: depends on network convergence (currently untested)

### Next Steps
1. Validate with ops team on database capacity
2. Run failover simulation to measure real time
3. Build monitoring dashboard before launch

Confidence level: High on architecture, Medium on operational readiness.
Ready to design in detail?
```

## Question Categories Reference

### Requirements Questions
- "Who are the end users of this feature?"
- "What's the primary problem this solves?"
- "What's the definition of success?"
- "What's the deadline, and is it flexible?"
- "What's the budget or resource constraint?"

### Assumptions Questions
- "Why did you choose technology/pattern X?"
- "What are you assuming about user behavior?"
- "What if that assumption is wrong?"
- "Have you validated this with real users/data?"
- "Are there alternatives you considered and rejected?"

### Constraints Questions
- "What can't you change about the existing system?"
- "What are the hard limits (performance, cost, security)?"
- "What dependencies do you have on other teams?"
- "What's your deployment window?"
- "What's the rollback plan if things go wrong?"

### Dependencies Questions
- "What has to be true for this to work?"
- "What systems must integrate with yours?"
- "What's the critical path?"
- "What could cause cascading failures?"
- "How do you handle partial failures?"

### Edge Cases Questions
- "What happens when X fails?"
- "How do you handle malformed input?"
- "What's your load limit, and what happens beyond it?"
- "How do you prevent race conditions?"
- "What about old API clients or legacy data?"

### Validation Questions
- "How will you know this is working?"
- "What metrics matter most?"
- "How will you catch regressions?"
- "What's your monitoring strategy?"
- "What's your testing approach—unit, integration, e2e, load?"

## Examples

### Positive Trigger

User: "Grill me on this auth system design."

Expected behavior: Read the design, identify key decisions, ask probing questions about assumptions and edge cases, validate feasibility, and push back on contradictions.

---

User: "Stress-test my plan for migrating to a new database."

Expected behavior: Map out the migration steps, probe assumptions about downtime and rollback, identify risks around data consistency, ask validation questions.

---

User: "Interview me on this feature proposal before I write code."

Expected behavior: Understand the requirements, validate the approach against constraints, uncover hidden dependencies, ensure the user is thinking through edge cases.

### Non-Trigger

User: "Review this code and fix the bugs."

Expected behavior: Do not use grill-me. The user wants code review and fixes, not an interview. Use a code review skill instead.

---

User: "What do you think of this design?"

Expected behavior: Do not use grill-me unless the user explicitly asks to be grilled. Provide direct feedback or a review instead.

## Troubleshooting

### Skill Does Not Trigger

- Error: Claude gives feedback or suggestions instead of asking questions.
- Cause: User said "review" or "give feedback" instead of "grill me" or "stress-test".
- Solution: Explicitly ask to be grilled: "Grill me on this plan", "Stress-test my design", "Interview me about this architecture".

### Questions Feel Generic or Repetitive

- Error: Questions don't reflect the specific plan or codebase context.
- Cause: Insufficient context provided, or questions asked too quickly before analysis.
- Solution: Share the plan, design doc, or code first. Spend Phase 1 understanding the context thoroughly before asking.

### User Feels Defensive

- Error: User pushes back on the questioning style or says "I know this already".
- Cause: Questions felt accusatory or didn't acknowledge the user's expertise.
- Solution: Reframe as collaborative: "Let me make sure I understand your thinking..." instead of "Have you considered...?"

### No Clear Direction Emerges

- Error: After many questions, the plan is still unclear or contradictory.
- Cause: Too many parallel branches explored at once, or user is uncertain about goals.
- Solution: Zoom out. Ask: "What's the ONE most important constraint for this design?" and rebuild the decision tree from there.
