# Weekly Markdown Sync Design

## Goal

Synchronize approved Markdown documents and their local images from
`D:\msm\Markdown` into the Hugo site once per week, validate the complete site,
and publish successful changes to `main` without touching the user's active
website checkout.

The Windows scheduled task runs every Sunday at 22:00. If the computer is off at
that time, Task Scheduler starts the missed run when the computer becomes
available.

## Scope

The workflow:

- processes only entries listed in a repository-owned publication manifest;
- creates or updates Hugo page bundles and their local `assets` directories;
- applies deterministic Markdown and front matter normalization;
- resolves images from the source document's directory, adjacent attachment
  directories, and `D:\msm\Markdown\assets`;
- blocks publication when a source document, image, target, or site build is
  invalid;
- commits and pushes only generated, manifest-owned paths;
- logs every run outside the repository.

It does not:

- modify files under `D:\msm\Markdown`;
- publish unlisted notes, copies, temporary files, or private drafts;
- delete a published page unless the manifest explicitly requests deletion;
- force-push, rewrite history, or include changes from the user's active
  checkout;
- use an AI model during scheduled execution.

## Architecture

### Publication manifest

`scripts/markdown-sync/manifest.json` is the authoritative whitelist. Each entry
contains:

- `source`: path relative to `D:\msm\Markdown`;
- `destination`: page bundle directory relative to the site repository;
- `title`: public page title;
- `date`: stable publication date;
- `authors`: public author list;
- `tags`: public tags;
- `enabled`: whether the entry is synchronized;
- `delete`: an explicit opt-in for removing a previously managed destination.

The manifest rejects absolute paths, parent-directory traversal, duplicate
sources, duplicate destinations, and destinations outside `content/`.

### Markdown transformer

`scripts/markdown-sync/SyncMarkdown.psm1` contains pure, testable functions for:

- manifest validation;
- source and destination path validation;
- deterministic front matter generation;
- removal of duplicate leading level-one headings when the same title is already
  represented in front matter;
- normalization of line endings and final newline;
- extraction, decoding, resolution, copying, and rewriting of local Markdown
  image references;
- rejection of unresolved local image references and unsupported absolute local
  paths;
- comparison and transactional replacement of generated page bundles.

The source Markdown remains unchanged. Mermaid fences, code fences, tables,
links, inline HTML, and prose are preserved.

Image names are normalized to lowercase ASCII slugs with stable collision
suffixes. Rewritten links use page-bundle-relative paths such as
`assets/training-curve.png`.

### Sync command

`scripts/markdown-sync/sync-markdown.ps1` loads the manifest and materializes all
enabled entries into a specified website checkout. It supports:

- normal execution;
- `-DryRun`, which validates and reports changes without replacing files;
- an explicit source root and repository root for tests;
- machine-readable exit codes and a concise summary.

The operation is idempotent: running it twice with unchanged source files
produces no second Git diff.

### Publishing command

`scripts/markdown-sync/publish-markdown.ps1` is the scheduled entrypoint. It:

1. acquires a named mutex so only one run can execute;
2. verifies Docker, Git, the source root, the manifest, and Git credentials;
3. fetches `origin/main`;
4. creates a disposable detached Git worktree from the current `origin/main`;
5. runs the sync command in that worktree;
6. validates generated image references and repository whitespace;
7. builds the complete site with Hugo Extended 0.164.0 in the official
   `ghcr.io/gohugoio/hugo:v0.164.0` container;
8. exits without a commit when the generated tree is unchanged;
9. stages only manifest-owned content plus workflow-owned metadata;
10. commits with `docs: weekly markdown sync YYYY-MM-DD`;
11. pushes the detached commit to `origin/main` as a normal fast-forward update;
12. removes the disposable worktree and releases the mutex.

If the remote changes after the initial fetch, the push is rejected normally.
The workflow never retries with force; the next scheduled or manual run starts
again from the new `origin/main`.

### Scheduler installer

`scripts/markdown-sync/install-scheduled-task.ps1` creates or updates the Windows
Task Scheduler task `Mengshuimeng Weekly Markdown Sync` with:

- weekly trigger: Sunday at 22:00 local time;
- run only for the current user;
- start when available after a missed trigger;
- no overlapping task instances;
- PowerShell 7 as the host;
- the repository publishing script as the action;
- the repository root and `D:\msm\Markdown` as explicit arguments.

The installer also supports uninstalling the task and printing its effective
configuration.

### Logging

Logs are written to:

`%LOCALAPPDATA%\MengshuimengMarkdownSync\logs`

Each run receives a timestamped log. The latest result is also written to
`last-run.json` with start time, finish time, result, changed entries, commit
hash, and error summary. Logs and credentials are never committed.

## Initial publication set

The first run adds these confirmed new page bundles under
`content/docs/rl-sim/locomotion/`:

- `anymal-c-locomotion-mechanics`;
- `anymal-c-environment-setup`;
- `anymal-c-training-debugging-reproduction`;
- `motrixarena-s1-obstacle-navigation`.

Their images are resolved from each document's adjacent `图片和附件` directory.
The existing `rl-sim` navigation remains intact, and a localized section index
is added only when required for Hugo navigation.

Previously migrated pages are registered in the manifest only when a reliable
source-to-destination mapping can be established. Ambiguous source files remain
unlisted and are reported rather than guessed.

## Failure handling

The entire run fails before commit and push when:

- the active website checkout contains no valid remote or `origin/main`;
- a manifest entry is malformed or conflicts with another entry;
- a source document or referenced local image cannot be found;
- generated output escapes its declared destination;
- the same destination is written by multiple entries;
- an absolute Windows image path remains in generated Markdown;
- Docker or the pinned Hugo image is unavailable;
- the Hugo production build fails;
- Git cannot create a commit or perform a normal fast-forward push.

Because all generated changes occur in a disposable worktree, failures do not
dirty the user's active checkout. Cleanup failures are logged and retried by the
installer's maintenance path without deleting any source documents.

## Testing

Pester tests under `tests/markdown-sync/` cover:

- valid and invalid manifest entries;
- path traversal and duplicate destination rejection;
- deterministic front matter;
- duplicate title-heading removal;
- Chinese, percent-encoded, spaced, and repeated image names;
- adjacent attachment and shared asset lookup precedence;
- missing image failure;
- code-fence preservation;
- idempotent second synchronization;
- dry-run behavior;
- manifest-owned staging scope;
- no-change publication behavior.

Integration verification uses temporary fixture directories, then runs:

- all Pester tests;
- a dry run against the real manifest;
- a real synchronization into a disposable worktree;
- the pinned Hugo production build;
- one manual invocation of the registered scheduled task;
- Git status and remote commit verification;
- an HTTP request to the published site after GitHub Pages succeeds.

## Security

The workflow uses the existing Windows Git credential manager. It stores no
tokens or passwords. It never executes content from Markdown files as shell
commands, never follows source paths outside the configured root, never uses
`git push --force`, and never stages files outside its declared ownership set.
