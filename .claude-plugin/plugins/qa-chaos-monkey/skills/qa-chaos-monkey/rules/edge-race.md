---
title: Test race conditions with rapid conflicting operations
impact: MEDIUM
tags:
  - qa
  - edge-case
  - race-condition
  - concurrency
---

## Rule

For operations that can conflict (create/delete, enable/disable, add/remove), perform both operations within 1 second and verify the final state is consistent. Also test rapid duplicate form submissions.

## Incorrect

```
# Tests operations with comfortable delays
1. Add reaction to post → 200 ✓
2. Wait 5 seconds
3. Remove reaction from post → 200 ✓
4. Verify: no reaction ✓
# This works but doesn't test real-world timing
```

- Error: Operations spaced too far apart — race condition window is not tested.
- Cause: Agent did not simulate real-world rapid user interactions.

## Correct

```
# Tests conflicting operations within 1 second
1. Add reaction to post → 200 ✓
2. Remove reaction immediately (< 1 second) → 200 ✓
3. Verify final state: no reaction ✓ (consistent)
4. Submit form → 200 ✓
5. Submit same form immediately again → 200 or 409 ✓
6. Verify: only 1 record created ✓ (no duplicate)
```

- Operations happen within the race window (< 1 second).
- Final state is verified for consistency — the system shouldn't have orphaned or duplicate records.

## Why it matters

Race conditions cause data inconsistency — orphaned records, duplicate entries, or stale state. They are notoriously hard to reproduce in manual testing but trivially triggered by automated rapid-fire requests. Finding them before production prevents data corruption.
