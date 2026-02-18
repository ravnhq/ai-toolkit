---
title: Prefer Composition Over Configuration
impact: HIGH
tags: component, design, flexibility
---

## Prefer Composition Over Configuration

Build flexible components through composition (children, slots) rather than excessive props.

**Incorrect (prop explosion):**

```typescript
// Bad - too many props, inflexible
<Card
  title="Post Details"
  subtitle="Conference Room A"
  icon={<Calendar />}
  headerAction={<Button>Edit</Button>}
  content={<PostInfo post={post} />}
  footer={<Actions />}
  footerAlign="right"
  bordered
  elevated
  size="large"
/>
```

**Correct (composable):**

```typescript
// Good - flexible composition
<Card>
  <CardHeader>
    <CardIcon><Calendar /></CardIcon>
    <CardTitle>Post Details</CardTitle>
    <CardDescription>Conference Room A</CardDescription>
    <CardAction><Button>Edit</Button></CardAction>
  </CardHeader>
  <CardContent>
    <PostInfo post={post} />
  </CardContent>
  <CardFooter className="justify-end">
    <Actions />
  </CardFooter>
</Card>
```

**Benefits of composition:**

- Consumers control layout and structure
- Easy to add/remove sections
- No "prop for every use case" bloat
- Components remain simple internally

**When props are better:**

- Boolean variants (`disabled`, `loading`)
- Size/style variants (`size="lg"`, `variant="primary"`)
- Data that the component needs internally

**Why it matters:**
- Prop-heavy components become hard to maintain
- Every new use case requires new props
- Composable components are more reusable
- Consumers have control without forking
