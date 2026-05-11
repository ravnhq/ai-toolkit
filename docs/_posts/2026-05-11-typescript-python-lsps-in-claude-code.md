---
layout: post
title: "TypeScript and Python LSPs in Claude Code, the working way"
date: 2026-05-11
author: "Pedro Guimarães"
author_github: "0x7067"
excerpt: "The official TypeScript and Python LSP plugins for Claude Code often register zero servers (bug #15148, still open). Two setups that work today: the Piebald community plugins, and the official one for projects that can tolerate the bug."
---

## Piebald-AI (recommended)

```bash
npm install -g typescript @vtsls/language-server
brew install basedpyright
```

```
/plugin marketplace add Piebald-AI/claude-code-lsps
/plugin install typescript@claude-code-lsps
/plugin install basedpyright@claude-code-lsps
/reload-plugins
```

## Official

```bash
npm install -g typescript typescript-language-server
```

```
/plugin install typescript-lsp@claude-plugins-official
/reload-plugins
```

## Verify

Most status lines do not surface LSP state. The unambiguous check is the debug log. Restart with:

```bash
claude --debug
```

Look for this line in the startup output:

```
LSP notification handlers registered successfully for all N server(s)
```

`N ≥ 1` means at least one server registered. `N = 0` is [#15148](https://github.com/anthropics/claude-code/issues/15148) — switch to Piebald. Inside a running session, `/doctor` is the quicker sanity check; it reports install and settings issues with status icons and lets you press `f` to fix them.
