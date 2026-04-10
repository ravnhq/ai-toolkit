# Test Plan Template

Copy this to `.qa/test-plan.md` in your project root.

```markdown
# QA Test Plan

## Scope
**Feature/PR**:
**Date**:

## UI Flows (for qa-happy-path)

### Flow 1 — [Flow Name]
- **Type**: ui
- **Description**: [What this flow tests]
- **Steps**:
  1. Navigate to [page]
  2. [Action]
  3. [Action]
- **Expected**: [What should happen]
- **Verify**: [How to confirm]

## API Endpoints (for qa-chaos-monkey)

### Endpoint 1 — [Method] [Path]
- **Auth**: [required | optional | none]
- **Required fields**: [field1, field2]
- **Constraints**: [max length, valid values]
- **Expected success**: [status code + response shape]

## Webhook Flows (for custom personalities)

### Webhook 1 — [Event Type]
- **Endpoint**: [POST path]
- **Signing**: [HMAC-SHA256 | Stripe signature | none]
- **Signing secret env var**: [QA_SLACK_SIGNING_SECRET, etc.]
- **Expected**: [What state change should occur]
- **Verify**: [API call to confirm]

## Acceptance Criteria
- [ ] All UI flows pass
- [ ] No 500 errors on any endpoint
- [ ] Auth boundaries enforced
- [ ] No data integrity issues
```
