---
title: "GitHub CLI 安装与登录准备"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "Git"
  - "GitHub CLI"
---

这两个 skill 都和 GitHub PR / CI 有关，所以建议先装 `gh`。GitHub 官方文档也要求安装 GitHub CLI 后用 `gh auth login` 登录。

打开 **PowerShell**，输入：

```text
winget install --id GitHub.cli
```

装完后检查：

```text
gh --version
```

然后登录 GitHub：

```text
gh auth login
```

按提示选择：

```text
GitHub.com
HTTPS
Login with a web browser
```

登录完成后检查：

```text
gh auth status
```

GitHub CLI 默认会走浏览器登录流程，并把 token 存到系统凭据里。
