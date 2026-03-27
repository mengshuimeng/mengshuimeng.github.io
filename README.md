# Mengshuimeng.github.io

## Local Development

Pre-requisites: [Hugo](https://gohugo.io/getting-started/installing/), [Go](https://golang.org/doc/install) and [Git](https://git-scm.com)

This project expects Go 1.26 or newer. If you use the included devcontainer, rebuild the container after pulling changes so it picks up the newer Go and Hugo toolchain.

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
