---
title: Use Lowercase, Short, Typeable Command Names
impact: MEDIUM
tags: naming, ux, commands
---

## Use Lowercase, Short, Typeable Command Names

Command names should be lowercase, short (4-8 characters ideal), easy to type with alternating hands, and memorable without being generic.

**Incorrect (hard to type, too long, or uses wrong case):**

```bash
# Too long
download-url-from-internet
generate-configuration-file

# Wrong case (causes issues on case-insensitive filesystems)
DownloadURL
MyTool
GenerateConfig

# Hard to type (awkward one-hand typing)
plum    # All left hand keys
polk    # All left hand keys

# Too generic (collides with existing commands)
convert  # Conflicts with ImageMagick's convert
sync     # Conflicts with Unix sync
test     # Conflicts with shell test command
```

**Correct (lowercase, short, alternating-hand typing):**

```bash
# Good examples from popular tools
curl     # 4 chars, alternating hands
git      # 3 chars, easy to type
docker   # 6 chars, memorable
kubectl  # 7 chars, specific to domain
jq       # 2 chars, minimal but clear in context
gh       # 2 chars, clear (GitHub CLI)

# Multi-word commands use dashes
docker-compose   # Not dockerCompose or docker_compose
gh-cli           # Not ghCli
```

**Noun-verb pattern for subcommands:**

```bash
# Docker-style: noun verb (resource first, action second)
docker container start
docker container stop
docker image delete
docker network list

# kubectl-style: verb noun (action first, resource second)
kubectl get pods
kubectl delete service
kubectl create deployment
kubectl describe node

# Pick one pattern and stay consistent
# Don't mix: docker start container AND docker container stop
```

**Test your command name:**

1. **Typability**: Can you type it with alternating hands? (curl, docker = good; plum = bad)
2. **Length**: Is it under 8 characters? Longer names slow users down
3. **Memorability**: Is it distinctive and easy to remember?
4. **Conflict check**: Does it exist in common $PATH? (`which <name>`)
5. **Case**: Is it all lowercase? Mixed case breaks on case-insensitive systems

**Why it matters:**

Users type your command name dozens or hundreds of times per day. Long or awkward names slow down workflows. Mixed-case names cause confusion on case-insensitive filesystems (macOS, Windows). Generic names create conflicts with existing tools, causing user frustration.

Reference: [clig.dev - Naming](https://clig.dev/#naming)
