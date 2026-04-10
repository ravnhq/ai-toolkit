---
title: Adapt interview depth and explanation to the user's experience level
impact: MEDIUM
tags:
  - test-plan
  - ux
  - interview
  - standards
---

## Rule

The interview process must adapt to the user's apparent QA experience level. Provide more explanation and examples for junior QA engineers; be concise and skip explanations for senior QA engineers.

## Incorrect

```
[For a user who said "I've been doing QA for 8 years and need to document this sprint"]

"The Introduction section is the first part of your test plan. It tells readers what the document is about.
Here's an example of what an introduction might look like: [3-paragraph explanation of what introductions are]
Now, what is the official name of your project? Make sure it's the full name as it appears in your project management tool."
```

- Error: Lengthy explanation of basic QA concepts to an experienced professional. Wastes time and signals that the tool doesn't understand its audience.
- Cause: Using the same script regardless of user context.

## Correct

```
[For a senior QA engineer]
"Project name and 2-3 sentence overview?"

[For a junior QA engineer]
"Let's start with the Introduction. What's the official project name? Then give me 2-3 sentences describing
what the project does — think of it as explaining to someone new on the team what they'd be testing."
```

- Senior path: direct, minimal scaffolding.
- Junior path: explains the purpose of the question and provides guidance on what a good answer looks like.

## Why it matters

Over-explaining to experts is condescending and slow. Under-explaining to juniors produces incomplete answers that require multiple follow-up rounds. Adapting to user level produces higher-quality output faster.
