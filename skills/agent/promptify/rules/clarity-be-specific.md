---
title: Be Specific
impact: HIGH
tags: clarity, precision, measurable
---

## Be Specific

Replace vague qualifiers ("good", "clear", "concise", "detailed") with measurable requirements.

**Incorrect (vague qualifiers):**

```markdown
Write a good, detailed explanation of Kubernetes that's clear and concise.
```

**Correct (measurable requirements):**

```markdown
Explain Kubernetes to a developer who has used Docker but never orchestrated containers.

- Cover: pods, services, deployments, and namespaces
- Skip: Helm, Istio, and custom operators
- Length: 400-600 words
- Include one YAML example for a deployment with 3 replicas
- Define each term on first use
```

**Why it matters:** "Good" and "clear" mean different things to different people. The AI cannot optimise for a target it cannot measure. Specific requirements ("400-600 words", "define each term on first use") produce consistent results. Vague qualifiers produce inconsistent results that need rework.
