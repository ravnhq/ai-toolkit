---
title: Mock Boundaries, Not Your Own Code
impact: MEDIUM
tags: mocking, integration, boundaries
---

## Mock Boundaries, Not Your Own Code

Only mock at system boundaries (external APIs, time, randomness). Don't mock your own code.

**Incorrect (mocking internal code):**

```typescript
// Bad - mocks your own repository
test('creates invitation', async () => {
  const mockRepo = {
    findExisting: jest.fn().mockResolvedValue(null),
    insert: jest.fn().mockResolvedValue({ id: '1', status: 'PENDING' }),
  };

  const result = await createInvitation(
    { email: 'test@test.com' },
    mockRepo
  );

  expect(mockRepo.insert).toHaveBeenCalled();
  // Passes even if actual DB integration is broken!
});
```

**Correct (mock only external boundaries):**

```typescript
// Good - real database, mock only external services
test('creates invitation and sends email', async () => {
  // Mock external email API
  server.use(
    http.post('https://api.resend.com/emails', () => {
      return HttpResponse.json({ id: 'email_123' });
    })
  );

  // Real database, real business logic
  const result = await createInvitation({
    email: 'test@test.com',
    orgId: testOrg.id,
  });

  // Verify real database state
  const stored = await db.query.invitations.findFirst({
    where: eq(invitations.id, result.id),
  });
  expect(stored).toBeDefined();
});
```

**What to mock:**

- External HTTP APIs (Stripe, SendGrid, Twilio)
- System time (`vi.useFakeTimers()`)
- Randomness (UUIDs, crypto)
- File system in some cases

**What NOT to mock:**

- Your own repositories/services
- Database queries
- Internal function calls
- Modules you control

**Why it matters:**
- Mocking internals gives false confidence
- Integration bugs slip through
- Refactoring internal structure breaks all tests
- Tests become coupled to implementation
