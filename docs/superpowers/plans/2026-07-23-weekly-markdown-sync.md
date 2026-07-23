# Weekly Markdown Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and install a safe Windows weekly workflow that synchronizes whitelisted Markdown documents and images into the Hugo site, validates the site, and publishes successful changes to `main`.

**Architecture:** Pure PowerShell transformation functions are tested with Pester and used by a deterministic sync command. A publishing wrapper works in an isolated detached Git worktree, builds with the pinned official Hugo container, and performs a fast-forward push. A separate installer registers the Sunday 22:00 Windows scheduled task.

**Tech Stack:** PowerShell 7, Pester 3.4-compatible tests, Git, Docker Desktop, Hugo Extended 0.164.0, Windows Task Scheduler, Hugo/Hextra.

## Global Constraints

- Source root is `D:\msm\Markdown` and must remain read-only.
- Website repository is `D:\Documents\code\html\mengshuimeng.github.io`.
- Scheduled execution is every Sunday at 22:00 Asia/Shanghai and starts when available after a missed run.
- Only manifest-whitelisted documents may be published.
- Missing sources or images, invalid paths, failed tests, or failed Hugo builds block commit and push.
- Publishing uses ordinary fast-forward Git push only; force push is forbidden.
- Scheduled execution stores no credentials and uses the existing Windows Git credential manager.
- Hugo build version is exactly `0.164.0`.
- Generated article paths use lowercase English kebab-case page bundles and local `assets/` directories.

---

### Task 1: Manifest validation module

**Files:**
- Create: `scripts/markdown-sync/SyncMarkdown.psm1`
- Create: `tests/markdown-sync/Manifest.Tests.ps1`

**Interfaces:**
- Produces: `Read-SyncManifest -Path <string> -SourceRoot <string> -RepositoryRoot <string> -> PSCustomObject[]`
- Produces: `Resolve-SafeChildPath -Root <string> -RelativePath <string> -> string`

- [ ] **Step 1: Write failing manifest tests**

Create fixtures in `$TestDrive` and assert that valid relative paths load while
absolute paths, `..`, duplicate sources, duplicate destinations, and
destinations outside `content/` throw.

```powershell
Describe 'Read-SyncManifest' {
    It 'rejects duplicate destinations' {
        { Read-SyncManifest -Path $manifest -SourceRoot $source -RepositoryRoot $repo } |
            Should Throw '*duplicate destination*'
    }
}
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```powershell
powershell.exe -NoProfile -Command "Invoke-Pester tests/markdown-sync/Manifest.Tests.ps1"
```

Expected: FAIL because `SyncMarkdown.psm1` and `Read-SyncManifest` do not exist.

- [ ] **Step 3: Implement safe path and manifest validation**

Implement canonical root-prefix checks using `[IO.Path]::GetFullPath`, normalized
case-insensitive duplicate sets, required property validation, and `content/`
destination enforcement. Export the two public functions.

- [ ] **Step 4: Run tests and verify GREEN**

Expected: all manifest tests pass with `FailedCount: 0`.

- [ ] **Step 5: Commit**

```powershell
git add scripts/markdown-sync/SyncMarkdown.psm1 tests/markdown-sync/Manifest.Tests.ps1
git commit -m "test: validate markdown sync manifest"
```

### Task 2: Markdown and image transformation

**Files:**
- Modify: `scripts/markdown-sync/SyncMarkdown.psm1`
- Create: `tests/markdown-sync/Transform.Tests.ps1`

**Interfaces:**
- Consumes: `Resolve-SafeChildPath`
- Produces: `Convert-SyncDocument -Entry <object> -SourceRoot <string> -OutputRoot <string> -SharedAssetsRoot <string> -> object`
- Produces: page bundle `index.md` and referenced files under `assets/`

- [ ] **Step 1: Write failing transformation tests**

Cover deterministic YAML front matter, duplicate leading H1 removal, preserved
code fences and Mermaid, percent-decoded paths, Chinese and spaced image names,
shared asset fallback, stable collision suffixes, and missing-image failure.

```powershell
It 'rewrites a percent-encoded adjacent image' {
    $result.Markdown | Should Match '!\[曲线\]\(assets/training-curve.png\)'
    Test-Path (Join-Path $bundle 'assets/training-curve.png') | Should Be $true
}
```

- [ ] **Step 2: Run tests and verify RED**

Expected: FAIL because `Convert-SyncDocument` is not exported.

- [ ] **Step 3: Implement minimal transformer**

Generate front matter in fixed key order, normalize LF, remove only a matching
first H1, parse Markdown image targets outside remote/data URLs, search the
source directory then `图片和附件` then the shared assets root, copy files with
ASCII slugs, and rewrite paths. Write to a temporary bundle and atomically
replace the destination only after all references resolve.

- [ ] **Step 4: Run tests and verify GREEN**

Expected: all transformation tests pass.

- [ ] **Step 5: Commit**

```powershell
git add scripts/markdown-sync/SyncMarkdown.psm1 tests/markdown-sync/Transform.Tests.ps1
git commit -m "feat: transform markdown page bundles"
```

### Task 3: Idempotent synchronization command

**Files:**
- Create: `scripts/markdown-sync/sync-markdown.ps1`
- Create: `tests/markdown-sync/Sync.Tests.ps1`

**Interfaces:**
- Consumes: `Read-SyncManifest`, `Convert-SyncDocument`
- Produces: exit code `0` for success/no change and nonzero for invalid input
- Produces: JSON-compatible summary with `Changed`, `Entries`, and `ManagedPaths`

- [ ] **Step 1: Write failing sync tests**

Test dry-run non-mutation, first-run generation, unchanged second run, disabled
entries, explicit deletion, and rejection of deletion without `delete: true`.

- [ ] **Step 2: Run tests and verify RED**

Expected: FAIL because `sync-markdown.ps1` does not exist.

- [ ] **Step 3: Implement sync orchestration**

Load the module and manifest, render each entry into a temporary staging root,
compare hashes to destination bundles, replace only changed bundles, and print a
single compressed JSON summary when `-PassThru` is supplied. `-DryRun` performs
all validation without copying into the repository.

- [ ] **Step 4: Run tests and verify GREEN**

Expected: all sync tests pass and a second fixture run reports `Changed=false`.

- [ ] **Step 5: Commit**

```powershell
git add scripts/markdown-sync/sync-markdown.ps1 tests/markdown-sync/Sync.Tests.ps1
git commit -m "feat: add idempotent markdown sync"
```

### Task 4: Isolated publishing workflow

**Files:**
- Create: `scripts/markdown-sync/publish-markdown.ps1`
- Create: `tests/markdown-sync/Publish.Tests.ps1`

**Interfaces:**
- Consumes: `sync-markdown.ps1`, `manifest.json`, Docker, Git
- Produces: timestamped log and `%LOCALAPPDATA%\MengshuimengMarkdownSync\last-run.json`
- Produces: optional fast-forward commit on `origin/main`

- [ ] **Step 1: Write failing publisher policy tests**

Test command construction and policy helpers: no force push, detached worktree
starts at `origin/main`, only managed paths are staged, no-change exits before
commit, and failures write `last-run.json`.

- [ ] **Step 2: Run tests and verify RED**

Expected: FAIL because publisher helpers do not exist.

- [ ] **Step 3: Implement publisher**

Acquire `Global\MengshuimengMarkdownSync`, fetch `origin main`, create a
temporary detached worktree, invoke sync, run `git diff --check`, build with:

```powershell
docker run --rm --user root `
  --mount "type=bind,source=$worktree,target=/project" `
  --workdir /project `
  ghcr.io/gohugoio/hugo:v0.164.0 `
  --gc --minify --baseURL https://mengshuimeng.github.io/ --destination /tmp/site
```

Stage explicit managed paths, commit, and push `HEAD:main` without force. Always
remove the temporary worktree in `finally`, release the mutex, and write the run
result.

- [ ] **Step 4: Run tests and verify GREEN**

Expected: policy tests pass without contacting the remote.

- [ ] **Step 5: Commit**

```powershell
git add scripts/markdown-sync/publish-markdown.ps1 tests/markdown-sync/Publish.Tests.ps1
git commit -m "feat: publish markdown from isolated worktree"
```

### Task 5: Windows scheduler installer

**Files:**
- Create: `scripts/markdown-sync/install-scheduled-task.ps1`
- Create: `tests/markdown-sync/Scheduler.Tests.ps1`

**Interfaces:**
- Produces: task `Mengshuimeng Weekly Markdown Sync`
- Supports: `-Install`, `-Uninstall`, `-Show`, and `-WhatIf`

- [ ] **Step 1: Write failing scheduler tests**

Assert Sunday, 22:00, `StartWhenAvailable=true`, one-instance policy, PowerShell
7 executable, quoted repository/source arguments, and no stored credentials.

- [ ] **Step 2: Run tests and verify RED**

Expected: FAIL because installer does not exist.

- [ ] **Step 3: Implement installer**

Use `New-ScheduledTaskAction`, `New-ScheduledTaskTrigger -Weekly -DaysOfWeek
Sunday -At 22:00`, `New-ScheduledTaskSettingsSet -StartWhenAvailable
-MultipleInstances IgnoreNew`, and `Register-ScheduledTask` for the current
interactive user.

- [ ] **Step 4: Run tests and verify GREEN**

Expected: scheduler construction tests pass without registering a real task.

- [ ] **Step 5: Commit**

```powershell
git add scripts/markdown-sync/install-scheduled-task.ps1 tests/markdown-sync/Scheduler.Tests.ps1
git commit -m "feat: install weekly markdown sync task"
```

### Task 6: Real manifest and initial four articles

**Files:**
- Create: `scripts/markdown-sync/manifest.json`
- Create: `content/docs/rl-sim/locomotion/_index.zh-cn.md`
- Generate: `content/docs/rl-sim/locomotion/anymal-c-locomotion-mechanics/index.md`
- Generate: `content/docs/rl-sim/locomotion/anymal-c-environment-setup/index.md`
- Generate: `content/docs/rl-sim/locomotion/anymal-c-training-debugging-reproduction/index.md`
- Generate: `content/docs/rl-sim/locomotion/motrixarena-s1-obstacle-navigation/index.md`
- Generate: each article's referenced `assets/*`

**Interfaces:**
- Consumes: four source documents and adjacent `图片和附件` directories
- Produces: four Hugo page bundles

- [ ] **Step 1: Add four approved whitelist entries**

Use stable 2026-07-23 publication dates, author `梦水盟`, destination paths from
the design, and tags `强化学习`, `机器人`, `ANYmal C`, or `MotrixArena` as
appropriate.

- [ ] **Step 2: Run real dry run**

```powershell
pwsh -NoProfile -File scripts/markdown-sync/sync-markdown.ps1 `
  -SourceRoot 'D:\msm\Markdown' -RepositoryRoot $PWD -DryRun
```

Expected: four valid entries and no unresolved images.

- [ ] **Step 3: Run real synchronization**

Expected: four page bundles and all referenced images are generated.

- [ ] **Step 4: Verify idempotency**

Run synchronization again.

Expected: no Git diff after the second run.

- [ ] **Step 5: Commit**

```powershell
git add scripts/markdown-sync/manifest.json content/docs/rl-sim/locomotion
git commit -m "docs: publish new locomotion reports"
```

### Task 7: Documentation and full verification

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `.gitignore`
- Modify: `docs/superpowers/plans/2026-07-23-weekly-markdown-sync.md`

- [ ] **Step 1: Document maintenance commands**

Document dry run, manual publish, whitelist registration, scheduler install,
status/log locations, task removal, and recovery from a failed run. Add generated
temporary/log paths to `.gitignore` where repository-local.

- [ ] **Step 2: Run the complete Pester suite**

```powershell
powershell.exe -NoProfile -Command "Invoke-Pester tests/markdown-sync"
```

Expected: `FailedCount: 0`.

- [ ] **Step 3: Run repository checks**

```powershell
git diff --check
pwsh -NoProfile -File scripts/markdown-sync/sync-markdown.ps1 -SourceRoot 'D:\msm\Markdown' -RepositoryRoot $PWD -DryRun
```

Expected: no whitespace errors and dry run success.

- [ ] **Step 4: Run pinned Hugo production build**

Use the official Hugo container command from Task 4.

Expected: exit code 0 and all Chinese/English pages build successfully.

- [ ] **Step 5: Commit**

```powershell
git add README.md AGENTS.md .gitignore docs/superpowers/plans/2026-07-23-weekly-markdown-sync.md
git commit -m "docs: explain weekly markdown publishing"
```

### Task 8: Integrate, install, and publish

**Files:**
- No additional source files expected

- [ ] **Step 1: Review branch scope**

Run `git status --short`, `git diff main...HEAD --stat`, and inspect every
workflow-owned file.

- [ ] **Step 2: Merge into local main**

Fast-forward or merge the implementation branch into `main` without discarding
unrelated user changes.

- [ ] **Step 3: Install scheduled task**

```powershell
pwsh -NoProfile -File scripts/markdown-sync/install-scheduled-task.ps1 `
  -Install -RepositoryRoot 'D:\Documents\code\html\mengshuimeng.github.io' `
  -SourceRoot 'D:\msm\Markdown'
```

Expected: task trigger is Sunday 22:00 and `StartWhenAvailable` is true.

- [ ] **Step 4: Run the task once manually**

Start the registered task, wait for completion, inspect `last-run.json`, and
confirm the active checkout remains clean.

- [ ] **Step 5: Push main**

```powershell
git push origin main
```

- [ ] **Step 6: Verify GitHub Pages and live HTTP**

Wait for the workflow run for the pushed commit to conclude `success`, then
request `https://mengshuimeng.github.io/` and each new article URL. Expected:
HTTP 200.
