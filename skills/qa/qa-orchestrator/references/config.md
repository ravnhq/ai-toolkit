# .qa/config.yml Template

Copy this to `.qa/config.yml` in your project root. This file SHOULD be committed.

```yaml
issue_tracker:
  provider: auto        # auto | linear | github | jira | none
  detected: none        # filled by installer or manually

  linear:
    team_id: ""
    label_names: ["Bug", "QA"]

  github:
    repo: ""            # owner/repo format
    labels: ["bug", "qa"]

  jira:
    project_key: ""
    issue_type: "Bug"

playwright:
  available: false

personalities:
  builtin:
    - qa-happy-path
    - qa-chaos-monkey
    - qa-bug-fixer
  custom: []

severity_map:
  BLOCKER: 1
  HIGH: 2
  MEDIUM: 3
  LOW: 4
```
