---
title: Mock External APIs with MSW
impact: HIGH
tags: mocking, msw, http, external-apis
---

## Mock External APIs with MSW

Use [MSW (Mock Service Worker)](https://mswjs.io/) to intercept HTTP requests at the network level instead of mocking HTTP clients directly. MSW intercepts at the network level, so tests exercise real fetch/axios code paths without coupling to a specific HTTP client. MSW v2+ uses `http` and `HttpResponse` from the `msw` package.

**Setup MSW server with default handlers (v2+):**

```typescript
// test/mocks/handlers.ts
import { HttpResponse, http } from "msw";

export const handlers = [
  http.post("https://api.resend.com/emails", () => {
    return HttpResponse.json({ id: "email_123" });
  }),

  http.post("https://api.stripe.com/v1/payment_intents", () => {
    return HttpResponse.json({
      id: "pi_123",
      status: "succeeded",
      amount: 5000,
    });
  }),
];
```

```typescript
// test/setup.ts
import { setupServer } from "msw/node";
import { handlers } from "./mocks/handlers";

export const server = setupServer(...handlers);

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

**Per-test overrides with `server.use()`:**

```typescript
import { HttpResponse, http } from "msw";
import { server } from "@/test/setup";

it("handles payment failure", async () => {
  server.use(
    http.post("https://api.stripe.com/v1/payment_intents", () => {
      return HttpResponse.json(
        { error: { message: "Card declined" } },
        { status: 402 },
      );
    }),
  );

  // Test error handling...
});
```

**Mock GraphQL queries with MSW:**

```typescript
import { graphql, HttpResponse } from "msw";
import { server } from "@/test/setup";

const graphqlHandlers = [
  graphql.query("GetUser", ({ variables }) => {
    return HttpResponse.json({
      data: {
        user: { id: variables.id, name: "Test User" },
      },
    });
  }),

  graphql.mutation("CreatePost", () => {
    return HttpResponse.json({
      data: { post: { id: "post_123", title: "New Post" } },
    });
  }),
];

export const server = setupServer(...graphqlHandlers);
```

**Bad -- mocking the HTTP client directly:**

```typescript
// Couples tests to implementation detail (axios vs fetch)
vi.mock("axios");
const mockAxios = vi.mocked(axios);

mockAxios.post.mockResolvedValue({
  data: { id: "pi_123", status: "succeeded" },
});

const result = await processPayment(amount);
expect(mockAxios.post).toHaveBeenCalledWith(
  "https://api.stripe.com/v1/payment_intents",
  expect.any(Object),
);
```

**Good -- using MSW handlers:**

```typescript
import { HttpResponse, http } from "msw";
import { server } from "@/test/setup";

it("processes payment successfully", async () => {
  server.use(
    http.post("https://api.stripe.com/v1/payment_intents", () => {
      return HttpResponse.json({
        id: "pi_123",
        status: "succeeded",
        amount: 5000,
      });
    }),
  );

  const result = await processPayment(5000);
  expect(result.status).toBe("succeeded");
});
```

**Edge case: catch unhandled requests in tests**

```typescript
beforeAll(() => {
  server.listen({
    onUnhandledRequest: "error", // Fail test if request not mocked
  });
});

afterEach(() => {
  server.resetHandlers(); // Clear per-test overrides
});

// ✅ This test will fail if fetch() or axios() calls an unmocked URL
test('must mock all external requests', async () => {
  // Will throw if we forgot to add a handler for this endpoint
  await callSomeAPI();
});
```

**Why it matters:**
- Tests real HTTP behavior (headers, status codes, network errors)
- No coupling to implementation (switching from axios to fetch does not break tests)
- `onUnhandledRequest: "error"` catches missing mocks and prevents accidental real API calls
- Handlers are reusable across tests and reset automatically in `afterEach`
- MSW v2+ API changed from `rest.post()` to `http.post()`; both `http` and `graphql` are available
- Works with any HTTP client (fetch, axios, node-fetch, undici)

Reference: [MSW Documentation](https://mswjs.io/docs)
