# Mengshuimeng.github.io

## Local Development

Pre-requisites: [Hugo](https://gohugo.io/getting-started/installing/), [Go](https://golang.org/doc/install) and [Git](https://git-scm.com)

This project expects Go 1.26 or newer. If you use the included devcontainer, rebuild the container after pulling changes so it picks up the newer Go and Hugo toolchain.

### VS Code Dev Container

1. Start Docker Desktop.
2. Open this repository in VS Code.
3. Run `Dev Containers: Reopen in Container` from the Command Palette.

The container installs the required Hugo Extended, Go, and Node versions. It also starts the Hugo development server automatically and opens the forwarded preview at `http://localhost:1313/`.

If VS Code reports a missing WSL bind mount after a Docker or WSL change, run `Dev Containers: Rebuild Container` instead of reopening the old container.

```shell
hugo mod tidy
hugo server --logLevel debug --disableFastRender -p 1313
```

## Clean Rebuild

When you need to verify that old generated pages are gone, delete `public/` first and then rebuild:

```powershell
Remove-Item -LiteralPath .\public -Recurse -Force
hugo server --disableFastRender --renderStaticToDisk -p 1313
```

## Content Rules

- New docs, blog posts, and project pages should use lowercase English kebab-case filenames.
- Keep human-facing Chinese or English titles in front matter instead of in the filename.
- Do not place new article pages directly under `content/docs/rl-sim`; put them inside topic folders such as `isaac-lab/` or `simulation/`.
- New images should not go into the shared `content/docs/assets` bucket. Prefer a local `assets/` folder inside the relevant topic directory.
- The shared `content/docs/assets` directory remains for legacy content and should be reduced gradually as topics are updated.

## Theme Updates

```shell
hugo mod get -u
hugo mod tidy
```

## Weekly Markdown Publishing

The repository synchronizes approved documents from `D:\msm\Markdown` every
Sunday at 22:00. Only entries in `scripts/markdown-sync/manifest.json` are
published, and source documents are never modified.

Validate the whitelist and referenced local media without changing the site:

```powershell
pwsh -NoProfile -File .\scripts\markdown-sync\sync-markdown.ps1 `
  -SourceRoot 'D:\msm\Markdown' -RepositoryRoot $PWD -DryRun
```

Run the isolated build-and-publish workflow manually:

```powershell
pwsh -NoProfile -File .\scripts\markdown-sync\publish-markdown.ps1 `
  -SourceRoot 'D:\msm\Markdown' -RepositoryRoot $PWD
```

Install or update the current-user scheduled task:

```powershell
pwsh -NoProfile -File .\scripts\markdown-sync\install-scheduled-task.ps1 `
  -Install -SourceRoot 'D:\msm\Markdown' -RepositoryRoot $PWD
```

Inspect or remove the task:

```powershell
pwsh -NoProfile -File .\scripts\markdown-sync\install-scheduled-task.ps1 -Show
pwsh -NoProfile -File .\scripts\markdown-sync\install-scheduled-task.ps1 -Uninstall
```

Logs are stored at `%LOCALAPPDATA%\MengshuimengMarkdownSync\logs`; the latest
result is `%LOCALAPPDATA%\MengshuimengMarkdownSync\last-run.json`. A failed run
does not force-push or modify the active checkout. Correct the source/media,
Docker, build, or Git error in the log, then run the publisher again.

To publish another document, add one explicit manifest entry with a unique
source and a lowercase English kebab-case destination below `content/`. Run the
dry run and production build before committing the manifest change.
