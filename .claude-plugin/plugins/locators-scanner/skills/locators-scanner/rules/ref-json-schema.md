---
title: JSON locator map schema and field definitions
impact: HIGH
tags:
  - locators
  - json
  - schema
  - output
---

## JSON Locator Map Schema

```json
{
  "metadata": {
    "url": "https://example.com/login",
    "pageName": "LoginPage",
    "framework": "playwright",
    "generatedAt": "2026-03-14T10:30:00Z",
    "totalElements": 24,
    "confidenceSummary": {
      "high": 10,
      "medium": 8,
      "low": 6
    }
  },
  "elements": [
    {
      "elementName": "usernameInput",
      "category": "interactive",
      "tagName": "input",
      "recommendedLocator": {
        "strategy": "getByLabel",
        "value": "Username",
        "code": "page.getByLabel('Username')",
        "reason": "Input has an associated <label> element with text 'Username'"
      },
      "fallbackLocator": {
        "strategy": "getByPlaceholder",
        "value": "Enter username",
        "code": "page.getByPlaceholder('Enter username')",
        "reason": "Input has a placeholder attribute as secondary identifier"
      },
      "confidence": "high",
      "attributes": {
        "id": "username",
        "name": "username",
        "type": "text",
        "placeholder": "Enter username",
        "ariaLabel": null,
        "dataTestid": null,
        "classes": ["form-control"],
        "textContent": null,
        "implicitRole": "textbox"
      },
      "warnings": []
    }
  ],
  "warnings": [
    "12 elements lack dedicated test attributes (data-testid, data-cy). Consider asking developers to add them for more resilient locators.",
    "2 elements have dynamic IDs that were skipped as unreliable."
  ]
}
```

## Field Definitions

| Field | Type | Description |
|---|---|---|
| `elementName` | string | camelCase descriptive name derived from element context |
| `category` | enum | `interactive` \| `form` \| `content` \| `structural` |
| `tagName` | string | HTML tag name |
| `recommendedLocator.strategy` | string | Framework-specific strategy name |
| `recommendedLocator.value` | string | The value passed to the strategy |
| `recommendedLocator.code` | string | Copy-pasteable code snippet |
| `recommendedLocator.reason` | string | Human-readable explanation of why this was selected |
| `fallbackLocator` | object | Same structure as recommendedLocator; second-best option |
| `confidence` | enum | `high` \| `medium` \| `low` — see `rules/ref-output-formats.md` for definitions |
| `attributes` | object | All harvested attributes for this element |
| `warnings` | string[] | Element-level warnings (dynamic ID, duplicate text, etc.) |
