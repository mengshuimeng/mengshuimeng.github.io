---
title: "GitHub CLI 安装与登录准备"
description: "整理 GitHub CLI 的安装、登录和常用操作准备流程。"
---

## 一、先准备 GitHub CLI

这两个 skill 都和 GitHub PR / CI 有关，所以建议先装 `gh`。GitHub 官方文档也要求安装 GitHub CLI 后用 `gh auth login` 登录。

打开 **PowerShell**，输入：

```
winget install --id GitHub.cli
```

装完后检查：

```
gh --version
```

然后登录 GitHub：

```
gh auth login
```

按提示选择：

```
GitHub.com
HTTPS
Login with a web browser
```

登录完成后检查：

```
gh auth status
```

GitHub CLI 默认会走浏览器登录流程，并把 token 存到系统凭据里。
