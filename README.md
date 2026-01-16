# Ravn Claude Plugins

Claude Code skills organized as plugins for the Ravn team.

## Plugins

| Plugin | Description | For |
|--------|-------------|-----|
| `core` | Universal design patterns | All teams |
| `apple-dev` | Swift concurrency, Liquid Glass, app icons | iOS/Swift |
| `ui-design` | UI/UX design principles | Frontend |
| `project-management` | Linear integration | All teams |

## Installation

### 1. Add the marketplace (once)

```
/plugin marketplace add git@github.com:ravnhq/ai-toolkit.git
```

### 2. Install plugins

```
/plugin install core@ravn-plugins
/plugin install apple-dev@ravn-plugins
/plugin install ui-design@ravn-plugins
/plugin install project-management@ravn-plugins
```

## Team Recommendations

| Team | Install |
|------|---------|
| iOS/Swift | `core` + `apple-dev` |
| Web/Frontend | `core` + `ui-design` |
| Full-stack | `core` + pick what fits |
| All | `+ project-management` for Linear |

## Skills Reference

### core
- **design-patterns** - Creational, structural, and behavioral patterns

### apple-dev
- **swift-concurrency** - async/await, actors, Sendable, tasks
- **liquid-glass** - Apple's Liquid Glass design (iOS 26+)
- **app-icon-generator** - iOS/Android icon specs and guidelines

### ui-design
- **design-principles** - Minimal design system (Linear/Notion/Stripe inspired)

### project-management
- **feedback-to-linear** - Transform user feedback into Linear issues
