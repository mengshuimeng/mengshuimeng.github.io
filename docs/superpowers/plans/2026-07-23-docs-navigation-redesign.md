# Docs Navigation Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild `/docs/` as a polished bilingual hybrid-navigation knowledge hub and make every top-level category expose its real hierarchy without changing any existing document URL.

**Architecture:** Two Hugo shortcodes own the presentation layer. `docs-hub.html` renders a curated intent-first landing page plus a dynamic seven-domain map and recent-document list. `docs-section-overview.html` inspects the current section and renders its immediate child sections before direct articles. Markdown index files become thin localized content entry points, while all styling remains scoped below `.docs-hub` and `.docs-section-overview`.

**Tech Stack:** Hugo Extended 0.164.0, Go templates, Hextra 0.12.3, CSS, PowerShell/Pester 3.4, Docker, Chrome for Testing

## Global Constraints

- Preserve every current content path, published URL, page bundle, media asset, and Markdown synchronization manifest entry.
- Keep Chinese and English routes functional; where English translations are missing, allow Hugo's existing language fallback behavior rather than inventing new articles.
- Do not add JavaScript or a second navigation framework.
- Keep templates data-driven for section/article counts, child sections, and recent documents.
- Scope all new selectors to the two documentation components.
- Support keyboard focus, light/dark themes, reduced motion, 390 px mobile width, and wide desktop layouts.
- Commit after each green task so every step is independently reviewable.

---

### Task 1: Add source-level navigation contract tests

**Files:**
- Create: `tests/docs-navigation/DocsNavigation.Tests.ps1`

- [ ] **Step 1: Write the failing tests**

  Add Pester assertions that:

  1. `content/docs/_index.zh-cn.md` and `content/docs/_index.en.md` each invoke `{{< docs-hub >}}` exactly once.
  2. All fourteen top-level category indexes invoke `{{< docs-section-overview >}}` exactly once.
  3. Both shortcode files exist and contain their stable root class names.
  4. The hub template exposes the three intent routes and all seven domain keys.
  5. The section template sorts and renders immediate child sections before direct regular pages.
  6. CSS contains scoped responsive, dark-theme-compatible, focus-visible, and reduced-motion rules.

- [ ] **Step 2: Run the test and verify RED**

  Run:

  ```powershell
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '$result = Invoke-Pester -Script ".\tests\docs-navigation" -PassThru; if ($result.FailedCount -gt 0) { exit 1 }'
  ```

  Expected: failures because the shortcodes and CSS contracts do not yet exist.

- [ ] **Step 3: Commit the red tests**

  ```powershell
  git add tests/docs-navigation/DocsNavigation.Tests.ps1
  git commit -m "test: define docs navigation contracts"
  ```

---

### Task 2: Implement the hybrid documentation hub

**Files:**
- Create: `layouts/shortcodes/docs-hub.html`
- Modify: `content/docs/_index.zh-cn.md`
- Modify: `content/docs/_index.en.md`

- [ ] **Step 1: Create the data-driven hub shortcode**

  Implement:

  - localized Chinese/English labels selected from `.Page.Language.Lang`;
  - a header with `.Page.RegularPagesRecursive` document count and immediate section count;
  - three curated route cards for quick start, problem solving, and topic study;
  - seven curated domain definitions mapped to the existing `ai`, `environment`, `robotics`, `cv`, `fundamentals`, `rl-sim`, and `training` sections;
  - dynamic article counts and child-section preview chips for each domain;
  - a curated starter list plus four most recently modified regular pages;
  - `relLangURL` for all internal links.

  The stable structure must begin with:

  ```go-html-template
  <section class="docs-hub not-prose" aria-labelledby="docs-hub-title">
    <header class="docs-hub__hero">
      <p class="docs-hub__eyebrow">{{ $copy.eyebrow }}</p>
      <h2 id="docs-hub-title">{{ $copy.heading }}</h2>
    </header>
  </section>
  ```

- [ ] **Step 2: Replace the two root Markdown card grids**

  Keep front matter and a short localized introduction, then invoke:

  ```markdown
  {{< docs-hub >}}
  ```

- [ ] **Step 3: Run the navigation tests**

  Expected: hub-related tests pass; section/CSS tests remain red.

- [ ] **Step 4: Commit**

  ```powershell
  git add layouts/shortcodes/docs-hub.html content/docs/_index.zh-cn.md content/docs/_index.en.md
  git commit -m "feat: add hybrid docs navigation hub"
  ```

---

### Task 3: Implement consistent category hierarchy overviews

**Files:**
- Create: `layouts/shortcodes/docs-section-overview.html`
- Modify:
  - `content/docs/ai/_index.zh-cn.md`
  - `content/docs/ai/_index.en.md`
  - `content/docs/environment/_index.zh-cn.md`
  - `content/docs/environment/_index.en.md`
  - `content/docs/robotics/_index.zh-cn.md`
  - `content/docs/robotics/_index.en.md`
  - `content/docs/cv/_index.zh-cn.md`
  - `content/docs/cv/_index.en.md`
  - `content/docs/fundamentals/_index.zh-cn.md`
  - `content/docs/fundamentals/_index.en.md`
  - `content/docs/rl-sim/_index.zh-cn.md`
  - `content/docs/rl-sim/_index.en.md`
  - `content/docs/training/_index.zh-cn.md`
  - `content/docs/training/_index.en.md`

- [ ] **Step 1: Create the section overview shortcode**

  Use `.Page.Sections.ByTitle` for immediate child sections and `.Page.RegularPages.ByTitle` for direct articles. Render section cards first, including recursive article counts and a preview of up to three child titles. Then render direct articles with summary and last-modified date. Show a localized empty-state only when neither collection has entries.

  Stable root:

  ```go-html-template
  <section class="docs-section-overview not-prose" aria-label="{{ $copy.overview }}">
  ```

- [ ] **Step 2: Simplify all fourteen category indexes**

  Preserve front matter and localized introductory text. Remove the manually maintained Hextra card grids and append exactly one:

  ```markdown
  {{< docs-section-overview >}}
  ```

- [ ] **Step 3: Run navigation tests**

  Expected: content/template contracts pass; only CSS contracts remain red.

- [ ] **Step 4: Commit**

  ```powershell
  git add layouts/shortcodes/docs-section-overview.html content/docs/*/_index.zh-cn.md content/docs/*/_index.en.md
  git commit -m "feat: expose docs category hierarchy"
  ```

---

### Task 4: Add the polished responsive visual system

**Files:**
- Modify: `assets/css/custom.css`

- [ ] **Step 1: Add component-scoped styles**

  Add shared tokens and styles for:

  - a soft gradient hero panel with a compact count strip;
  - three-column intent cards with icon markers and clear hierarchy;
  - two-column domain cards with accent rails, counts, and child chips;
  - a two-column reading area;
  - category section and article cards;
  - hover elevation that does not shift layout;
  - `:focus-visible` outlines;
  - responsive breakpoints at 860 px and 640 px;
  - `@media (prefers-reduced-motion: reduce)`.

  Use existing Hextra dark-mode ancestry (`html.dark`) and CSS custom properties, without unscoped element rules.

- [ ] **Step 2: Run navigation tests and verify GREEN**

  Expected: all documentation navigation tests pass.

- [ ] **Step 3: Commit**

  ```powershell
  git add assets/css/custom.css
  git commit -m "style: polish docs navigation hierarchy"
  ```

---

### Task 5: Run functional and regression verification

**Files:**
- Verify only

- [ ] **Step 1: Run the full Pester suite outside the restricted sandbox**

  ```powershell
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '$result = Invoke-Pester -Script ".\tests" -PassThru; if ($result.FailedCount -gt 0) { exit 1 }'
  ```

- [ ] **Step 2: Verify the real Markdown source remains synchronized**

  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/markdown-sync/sync-markdown.ps1 -SourceRoot D:\msm\Markdown -RepositoryRoot . -ManifestPath scripts/markdown-sync/manifest.json -DryRun
  ```

  Expected: `Changed=False` and no writes.

- [ ] **Step 3: Build in a disposable normal clone**

  A linked Windows worktree cannot expose its `.git` pointer to Linux while `enableGitInfo` is enabled. Clone the feature worktree into a temporary directory, then run:

  ```powershell
  docker run --rm --user root --mount "type=bind,source=<temporary-clone>,target=/project" --workdir /project ghcr.io/gohugoio/hugo:v0.164.0 --gc --minify --baseURL https://mengshuimeng.github.io/ --destination /tmp/site
  ```

  Expected: exit 0 with no template errors.

- [ ] **Step 4: Check generated internal documentation links**

  Parse every `/docs/` `href` in generated HTML, normalize query strings/fragments/trailing slashes, and assert that the corresponding output file exists.

- [ ] **Step 5: Confirm URL and manifest preservation**

  ```powershell
  git diff --name-status 74d34ca...HEAD
  git diff --exit-code 74d34ca...HEAD -- scripts/markdown-sync/manifest.json content/docs -- . ':(exclude)content/docs/_index.zh-cn.md' ':(exclude)content/docs/_index.en.md' ':(exclude)content/docs/*/_index.zh-cn.md' ':(exclude)content/docs/*/_index.en.md'
  ```

  Expected: only the intended root/category indexes, templates, CSS, tests, and plan changed.

---

### Task 6: Perform real-browser visual and accessibility smoke checks

**Files:**
- Verify only; screenshots go to the Codex visualization directory, not the repository

- [ ] **Step 1: Start a local Hugo server from the disposable clone**

  Use the pinned Hugo Docker image and bind port 1313.

- [ ] **Step 2: Capture desktop and mobile screenshots**

  Use Chrome for Testing at 1440×1100 and 390×844 for:

  - `/docs/`
  - `/docs/environment/`
  - `/en/docs/`

- [ ] **Step 3: Inspect light and dark rendering**

  Confirm readable contrast, no clipped content, no horizontal overflow, clear three-stage navigation, and correct hierarchy ordering.

- [ ] **Step 4: Validate semantic hooks from the rendered DOM**

  Confirm one main hub region, route/domain link accessibility names, category headings, and keyboard-focusable anchors.

---

### Task 7: Complete the branch, publish, and verify production

**Files:**
- No new source files

- [ ] **Step 1: Re-run the final verification commands**

  Follow `superpowers:verification-before-completion`; do not rely on earlier output.

- [ ] **Step 2: Complete the feature branch**

  Follow `superpowers:finishing-a-development-branch`. The user has explicitly requested a direct end-to-end release, so merge the verified feature branch into `main`.

- [ ] **Step 3: Push main**

  ```powershell
  git push origin main
  ```

- [ ] **Step 4: Verify GitHub Actions**

  Inspect the workflow run associated with the final commit until it reaches a terminal successful state.

- [ ] **Step 5: Verify the live pages**

  Confirm HTTP 200 and the new rendered component markers on:

  - `https://mengshuimeng.github.io/docs/`
  - `https://mengshuimeng.github.io/docs/environment/`
  - `https://mengshuimeng.github.io/en/docs/`

- [ ] **Step 6: Report**

  Provide the final commit, test/build evidence, deployment result, live URLs, and before/after screenshot links.
