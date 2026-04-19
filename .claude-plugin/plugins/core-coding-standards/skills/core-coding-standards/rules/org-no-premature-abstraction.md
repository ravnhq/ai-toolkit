---
title: No Premature Abstraction
impact: MEDIUM
tags: organization, design, abstraction
---

## No Premature Abstraction

Don't create abstractions until you need them. Concrete code that works beats elegant abstractions that don't.

**Incorrect (abstracting before needed):**

```typescript
// Created "just in case" we need different notification providers
interface NotificationProvider {
  send(message: Message): Promise<void>;
}

class EmailNotificationProvider implements NotificationProvider { ... }
class SMSNotificationProvider implements NotificationProvider { ... }
class PushNotificationProvider implements NotificationProvider { ... }

class NotificationService {
  constructor(private providers: NotificationProvider[]) {}
  // Complex routing logic for something used once
}

// Reality: We only use email and it's the same for 2 years
```

**Correct (start concrete):**

```typescript
// Just send the email
async function sendWelcomeEmail(user: User) {
  await resend.emails.send({
    to: user.email,
    subject: 'Welcome!',
    template: 'welcome',
  });
}

// Later, IF we add SMS, then consider an abstraction
```

**Rule of Three:** Wait until you have three concrete examples before creating an abstraction. This gives you enough information to design a useful abstraction.

**Why it matters:** Premature abstractions guess at future requirements. They're usually wrong, and wrong abstractions are harder to change than no abstraction.
