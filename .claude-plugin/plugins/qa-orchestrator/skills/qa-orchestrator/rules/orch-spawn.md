---
title: Use the best available parallelism strategy for agent spawning
impact: CRITICAL
tags:
  - qa
  - orchestration
  - parallelism
  - agents
---

## Rule

When spawning QA agents, use the best available parallelism option in this order: (1) Forge MCP for parallel terminals with live monitoring, (2) parallel Agent tool calls in a single message for concurrent execution with no extra deps, (3) sequential Agent calls as last resort.

## Incorrect

```
# Always spawns agents one at a time
1. Spawn qa-happy-path → wait for completion → collect results
2. Spawn qa-chaos-monkey → wait for completion → collect results
3. Spawn qa-custom-agent → wait for completion → collect results
# Total time: sum of all agents — slowest possible approach
```

- Error: Uses sequential execution without checking if parallel options are available.
- Cause: Agent defaulted to the simplest approach without considering parallelism.

## Correct

```
# Checks for parallel options in order
1. Check: is mcp__forge__spawn_claude available?
   → YES: spawn all agents in separate Forge terminals (Option 1)
   → NO: continue to Option 2

2. Spawn all agents as parallel Agent tool calls in a single message:
   - Agent call 1: qa-happy-path with UI flow context
   - Agent call 2: qa-chaos-monkey with API endpoint context
   - Agent call 3: qa-custom-agent with custom context
   All run concurrently → collect all results when done (Option 2)

3. Only if parallel calls fail: fall back to sequential (Option 3)
```

- Tries Forge first (parallel + monitoring), then parallel Agent calls (parallel, no deps), then sequential.
- Total time with Option 2: time of the slowest agent, not the sum of all.

## Why it matters

QA runs with 3+ agents take 3x longer sequentially than in parallel. Parallel Agent calls are a native Claude Code capability that requires no extra MCP — there is no reason to run sequentially unless parallelism is explicitly broken. The Forge option adds live terminal monitoring for debugging.
