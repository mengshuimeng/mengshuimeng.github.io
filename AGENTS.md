# AGENTS.md

## Project Shape
- This is a Hugo + Hextra static site, not an application with a package test suite.
- Source content lives in `content/`; generated output is `public/` and should not be hand-edited.
- The Hextra theme is vendored under `_vendor/` but imported through Hugo modules as `github.com/imfing/hextra v0.12.1`.
- Local theme customizations are small: `layouts/_partials/navbar-title.html` overrides the navbar title, and `assets/css/custom.css` styles the breathing-dot animation.

## Commands
- First-time or dependency-refresh setup: `hugo mod tidy`.
- Local dev server: `hugo server --logLevel debug --disableFastRender -p 1313`.
- CI-style production check: `hugo --gc --minify --baseURL "https://mengshuimeng.github.io/"`.
- Theme update flow: `hugo mod get -u` then `hugo mod tidy`.
- Required toolchain is Hugo extended `0.164.0` (tracked in `.hugo-version`) and Go `1.26`; the devcontainer installs these, but this workspace may not have `hugo` on PATH.

## Content Conventions
- Default language is `zh-cn`; English pages use `.en.md`, Chinese pages use `.zh-cn.md` or the unsuffixed default-language file pattern already present in a section.
- New docs, blog posts, and project pages should use lowercase English kebab-case filenames; keep human-facing Chinese titles in front matter.
- Do not create new article pages directly under `content/docs/rl-sim`; place them under topic folders such as `isaac-lab/` or `simulation/`.
- Put new images in a local `assets/` folder next to the relevant topic, not in the shared legacy `content/docs/assets` bucket.
- Keep Hugo front matter at the very start of Markdown files; a few legacy pages violate this, so do not copy their structure.
- Avoid introducing new case variants such as `AI` vs `ai`; prefer lowercase paths for new content and links.

## Navigation And Deployment
- Main navigation is defined per language in `hugo.yaml`; keep Chinese and English entries aligned when adding or reordering sections.
- GitHub Pages deploys from `.github/workflows/pages.yaml` on pushes to `main` using the Hugo version in `.hugo-version`, Go `1.26`, `--gc --minify`, and a Pages-provided base URL.
- Netlify uses `netlify.toml` with `hugo --gc --minify -b ${DEPLOY_PRIME_URL}` and publishes `public/`.

## Generated Or Ignored Files
- `.gitignore` excludes `public/`, `resources/`, `.hugo_build.lock`, and `.vscode/`; do not rely on changes there unless the user explicitly asks.
- `scripts/create-docs-structure.ps1` creates documentation directories and placeholder `_index.zh-cn.md` / `_index.en.md` files; inspect before running because it can add many TODO pages.
