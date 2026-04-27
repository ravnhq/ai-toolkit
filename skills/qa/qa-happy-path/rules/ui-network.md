---
title: Verify network requests after form submits
impact: HIGH
tags:
  - qa
  - playwright
  - network
  - verification
---

## Rule

After any action that triggers an API call (form submission, button click that mutates data, navigation that loads data), check the network requests to confirm the API call succeeded. A UI that looks correct but received an error response is a bug.

## Incorrect

```
1. Fill in gift form and click "Send"
2. See "Gift sent!" toast message
3. Mark as PASS
# Never checked if the API actually returned 200 — the toast might fire on submit, not on success
```

- Error: Relied solely on UI feedback without verifying the API response.
- Cause: Agent assumed the UI toast means the backend operation succeeded.

## Correct

```
1. Fill in gift form and click "Send"
2. Check network requests:
   - POST /api/gifts → 201 Created ✓
   - Response body contains gift ID ✓
3. See "Gift sent!" toast message ✓
4. Mark as PASS
```

- Both UI state and API response are verified — the test confirms end-to-end success.
- If the API returned 500 but the UI showed success, this would correctly be flagged as a bug.

## Why it matters

Optimistic UIs can show success messages before the server responds or regardless of the response status. Without network verification, tests pass while the backend silently fails — bugs ship to production undetected.
