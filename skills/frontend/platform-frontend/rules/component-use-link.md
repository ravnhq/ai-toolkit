---
title: Use Link Component for Internal Navigation
impact: MEDIUM
tags: navigation, routing, spa
---

## Use Link Component for Internal Navigation

Always use your framework's Link component for internal navigation. Never use raw anchor tags for internal routes.

**Incorrect (raw anchor tag):**

```typescript
// Bad - bypasses client-side routing
<a href="/dashboard">Go to Dashboard</a>

// Causes:
// - Full page reload
// - Lost application state
// - Slower navigation
// - Flash of white screen
```

**Correct (Link component):**

```typescript
// Good - client-side navigation
import { Link } from '@tanstack/react-router'; // or your router

<Link to="/dashboard">Go to Dashboard</Link>

// Benefits:
// - Instant navigation
// - State preserved
// - Prefetching possible
// - Proper SPA behavior
```

**External links are different:**

```typescript
// External links DO use anchor tags
<a
  href="https://external-site.com"
  target="_blank"
  rel="noopener noreferrer"
>
  External Site
</a>

// Or with an ExternalLink component
<ExternalLink href="https://docs.example.com">
  Documentation
</ExternalLink>
```

**Why it matters:**
- Full page reloads break the SPA experience
- Application state (forms, scroll position) is lost
- Much slower than client-side routing
- Prefetching and caching don't work
