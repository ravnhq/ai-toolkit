---
title: Vertical Slice Architecture
impact: CRITICAL
tags: architecture, organization, features
---

## Vertical Slice Architecture

Organize by feature, not by technical layer. Each slice owns its entire stack: procedure, schemas, repository, and tests.

**Incorrect (layered architecture):**

```
src/
  controllers/
    invitations.controller.ts
    members.controller.ts
  services/
    invitations.service.ts
    members.service.ts
  repositories/
    invitations.repository.ts  # 50 methods for all invitation operations
    members.repository.ts
  schemas/
    invitations.schema.ts
    members.schema.ts
```

**Correct (vertical slices):**

```
src/
  features/
    invitations/
      create/
        create.procedure.ts
        create.schema.ts
        create.repository.ts    # Only queries for create
        create.test.ts
      accept/
        accept.procedure.ts
        accept.schema.ts
        accept.repository.ts
      list/
        ...
      router.ts                 # Combines all invitation procedures
    members/
      ...
  shared/
    procedures.ts               # Base procedures
    context.ts
  router.ts                     # Root router
```

**Why it matters:** Vertical slices are self-contained and easy to understand. Changes to one feature don't affect others. Testing is simpler because each slice is isolated.

Reference: [Vertical Slice Architecture](https://www.jimmybogard.com/vertical-slice-architecture/)
