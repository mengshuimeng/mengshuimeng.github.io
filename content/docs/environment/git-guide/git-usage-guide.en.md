---
title: Git Usage Guide
description: A practical Git reference for daily pull, commit, push, branch, and remote operations.
slug: git-usage-guide
---

# Git Usage Guide

This page focuses on the Git workflow most students and project teammates actually use: clone a repo, pull updates, commit clean changes, and push them back safely.

## Core Workflow

1. Pull the latest remote changes.
2. Make your edits locally.
3. Check what changed.
4. Commit with a clear message.
5. Push the branch.

```bash
git pull --rebase origin main
git status
git add .
git commit -m "feat: update training notes"
git push
```

## Commands You Will Use Often

```bash
git branch
git remote -v
git log --oneline --graph --decorate
git stash
git stash pop
```

## Good Habits

- Pull before you start editing.
- Keep commits focused on one change set.
- Use `git status` frequently.
- Prefer `git pull --rebase` for a cleaner history when working alone or on personal branches.

## Common Problems

- Push rejected: pull remote changes first, then push again.
- Wrong branch: check `git branch` before committing.
- Repeated credential prompts: use a credential manager.
- Large files: keep them out of the repository or move them to Git LFS.
