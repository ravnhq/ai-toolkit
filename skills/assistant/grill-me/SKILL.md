---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
metadata:
  category: assistant
  tags:
  - design
  - planning
  - questioning
  - decision-making
  status: ready
  version: 1
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

If a question can be answered by exploring the codebase, explore the codebase instead.

## Examples

### Positive Trigger

User: "Grill me on this auth system design."

Expected behavior: Ask probing questions one branch at a time, provide a recommended answer for each, and explore the codebase when a question can be answered by reading existing code.

### Non-Trigger

User: "Review this and fix the bugs."

Expected behavior: Do not enter grill mode — the user wants fixes, not an interview. Proceed with a standard code review.

## Troubleshooting

### Skill Does Not Trigger

- Error: Claude gives feedback or fixes instead of asking questions.
- Cause: Request was phrased as "review" or "fix" rather than "grill me" or "stress-test".
- Solution: Use explicit trigger words: "grill me", "stress-test this", "interview me about".

### Questions Feel Generic

- Error: Questions are not grounded in the specific plan or codebase.
- Cause: Skill was invoked without providing design context or code.
- Solution: Share the plan, design doc, or relevant code before invoking grill-me.

## Workflow

1. Read all provided context — design docs, code, or description — before asking anything.
2. Identify the first unresolved branch of the decision tree.
3. Ask one focused question about it and provide your recommended answer.
4. Incorporate the user's response and move to the next unresolved branch.
5. If a question can be answered by exploring the codebase, do that instead of asking.
6. Repeat until all branches are resolved or the user ends the session.
