---
layout: post
title: "Context Switching Done Right"
date: 2026-02-20
author: "Afonso Ferrer"
author_github: "fonzie42"
excerpt: "Stashes, WIP commits, branch juggling. There's a better way to handle context switching, and it pairs surprisingly well with AI coding tools."
---

Here's a scenario you probably know too well.

You're mid-refactor. You've added a couple of libraries, ripped out some old code, and half your files have red squiggly lines because you haven't finished rewiring things yet. Then a coworker pings you. "Hey, can you check if this bug is happening on dev?" Or maybe you just hit a wall and want to work on something else for a bit.

So what do you do? If you're like me, you `git stash` or throw everything into a WIP commit. Then you switch branches, run `npm install` (or `bun`, or `pnpm`, or whichever your project uses), wait for dependencies to sort themselves out, and finally get to the thing you actually wanted to do.

Then you go back. Was it a stash or a WIP commit? Which branch? Did you `stash pop` already or is it still in there somewhere? If you stashed, did you remember to include untracked files?

Do this three or four times in a week and it gets messy fast. I've lost work to forgotten stashes. I've pushed WIP commits by accident. I've run `git stash pop` on the wrong branch and spent precious time untangling the result.

It's not a big problem. Nobody's losing sleep over it. But it's one of those small, constant friction points that can slowly drain your energy throughout the day.

## Then I found worktrees

I stumbled on `git worktree` by accident. I was reading a Medium article about something else entirely, and the author mentioned worktrees in passing. I'd never heard of them, so I looked it up.

The idea is simple: instead of having one working directory for your repo and switching branches inside it, you create additional working directories that each point to a different branch of the same repo. They all share the same `.git` data, so there's no cloning involved. It's fast, it's lightweight, and each worktree is fully independent.

Here's what it looks like in practice:

```bash
# You're on your feature branch, mid-refactor
# Someone asks you to check something on dev

git worktree add ../my-project-dev dev
cd ../my-project-dev
npm install

# Do your thing, check the bug, whatever you need
# When you're done:

cd ../my-project
git worktree remove ../my-project-dev
```

That's it. Your original working directory stays exactly as you left it. No stashing, no WIP commits, no trying to remember where you put things. You just open another directory.

You can have as many worktrees as you want. I usually keep two or three around: one for my current feature, one for `dev` or `main` so I can quickly check how things look there, and sometimes one for a hotfix or a code review.

## What's actually good about them

The obvious win is that you stop juggling stashes and WIP commits. But there are a few things I didn't expect.

**Your node_modules stay put.** Each worktree has its own `node_modules`, so you're not reinstalling dependencies every time you switch context. The first setup takes a moment, but after that it's instant.

**You can have different editor windows open.** I keep my main feature worktree in one VS Code window and `dev` in another. Comparing behavior between branches becomes trivial. No more "let me switch branches real quick" during a call.

**It's just directories.** There's no new mental model to learn. It's a folder on your filesystem. `cd` into it, do your work, `cd` out. Your tools, your editor, your terminal, everything works exactly the same.

## The pitfalls

Worktrees aren't perfect. A few things to watch out for.

**You can't check out the same branch in two worktrees.** Git locks a branch to one worktree at a time. This makes sense (two worktrees writing to the same branch would be chaos), but it can be surprising the first time you hit it. If you need to look at code on a branch that's already checked out elsewhere, you can create a temporary branch or use `git worktree add --detach`.

**Each worktree needs its own dependency install.** That first `npm install` per worktree is unavoidable. If your project has heavy dependencies, this can eat some disk space. I haven't found it to be a problem in practice, but it's worth knowing.

**They can pile up.** If you forget to clean up old worktrees, you'll end up with a bunch of stale directories. `git worktree list` shows you what's active, and `git worktree prune` cleans up references to deleted directories. I run these occasionally to keep things tidy.

**Gitignored files don't come along.** Worktrees only contain tracked files. Your `.env`, local config files, anything in `.gitignore` won't be there. You'll need to copy those over manually. It's easy to forget this, spin up a worktree, run the project, and wonder why nothing works until you realize there's no `.env`.

**Some tools get confused.** Most editors handle worktrees fine since they're just regular directories. But I've seen the occasional git GUI get confused about which worktree it's looking at. If you live in the terminal for git operations, you won't notice this.

## Where it really clicked: Claude Code

Here's where things got interesting for me.

I've been using Claude Code for a while now. It works directly in your project directory, reading files, running commands, making changes. The problem is, if Claude is working on something in your project directory and you also want to work there, you're going to collide. Maybe it's modifying a file you're also editing. Maybe it's running tests while you're in the middle of changing something that'll break them.

Worktrees solve this completely.

I can spin up a worktree for Claude to audit the codebase while I keep developing in the main directory. Or I can have Claude writing tests in one worktree while I'm implementing a feature in another. Claude Code even has a built-in `-w` flag that creates a worktree for you automatically (`claude -w feature-name`), gives it its own branch, and cleans up after itself when you're done.

The real unlock is running multiple Claude instances at once. One worktree has Claude running through test coverage. Another has it doing a code review. And I'm coding in my main directory without any of us stepping on each other's toes. Three parallel workstreams from one repo, no conflicts, no coordination needed.

But it goes beyond just avoiding collisions. Worktrees make longer, more ambitious Claude workflows practical. If you've ever had Claude working on a big refactor or writing a whole test suite, you know it can take a while. Without worktrees, you're basically locked out of your project until it finishes. You sit there watching, or you interrupt it, or you context-switch away (and we're back to the stash/WIP problem). With worktrees, you just let Claude keep going in its own directory. You don't need to watch it. You don't need to wait. You open your main worktree and keep working on whatever you want. When Claude's done, the changes are sitting in its worktree branch, ready for you to review and merge on your own time.

This also changes how you think about delegating work to Claude. Instead of giving it small, quick tasks because you need your project back, you can hand it something bigger. "Go through this module and add missing error handling." "Write integration tests for the API layer." Things that would take thirty minutes or more. You're not blocked, so the task size stops mattering as much.

Before worktrees, my workflow for any of this wasn't practical. I'd need separate clones, which means separate git histories to manage, separate remotes to configure, separate everything. Or I'd have to constantly switch branches, reinstall dependencies, and keep track of what state everything was in. Even without Claude Code, that was hard to manage. With it, it was impossible.

## Should you bother?

If you're someone who rarely switches context, probably not. Worktrees solve a specific problem, and if you don't have that problem, they'll just be one more thing to know about.

But if you find yourself stashing and un-stashing multiple times a day, or if you're juggling WIP commits across branches, or if you're running AI coding tools alongside your own work: give worktrees a try. The learning curve is about fifteen minutes and the payoff is immediate.

My stash list has never been this clean. Seriously, just try it.
