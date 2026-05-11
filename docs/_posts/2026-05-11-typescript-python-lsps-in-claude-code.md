---
layout: post
title: "TypeScript and Python LSPs in Claude Code, the working way"
date: 2026-05-11
author: "Pedro Guimarães"
author_github: "0x7067"
excerpt: "The official TypeScript and Python LSP plugins for Claude Code often register zero servers (bug #15148, still open). Two setups that work today: the Piebald community plugins, and the official ones when the bug doesn't bite."
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
npm install -g typescript typescript-language-server pyright
```

```
/plugin install typescript-lsp@claude-plugins-official
/plugin install pyright-lsp@claude-plugins-official
/reload-plugins
```

## Verify

`/reload-plugins` reports an LSP server count when it finishes. Look for `1 plugin LSP server` (or `2` if you installed both). A `0` means the plugin loaded but registered nothing: that's [#15148](https://github.com/anthropics/claude-code/issues/15148). Switch to Piebald.
