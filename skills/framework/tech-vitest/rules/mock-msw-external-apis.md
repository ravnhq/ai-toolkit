---
title: Mock External APIs with MSW
impact: HIGH
tags: mocking, msw, http, external-apis
---

## Mock External APIs with MSW

Use [MSW (Mock Service Worker)](https://mswjs.io/) to intercept HTTP requests at the network level instead of mocking HTTP clients directly. MSW intercepts at the network level, so tests exercise real fetch/axios code paths without coupling to a specific HTTP client.

**Setup MSW server with default handlers:**

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

**Why it matters:**
- Tests real HTTP behavior (headers, status codes, network errors)
- No coupling to implementation (switching from axios to fetch does not break tests)
- `onUnhandledRequest: "error"` catches missing mocks and prevents accidental real API calls
- Handlers are reusable across tests and reset automatically in `afterEach`

Reference: [MSW Documentation](https://mswjs.io/docs)
