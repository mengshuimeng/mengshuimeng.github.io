---
title: "OpenClaw 登录会话与令牌续期检查"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "OpenClaw"
  - "会话管理"
---

openclaw

```text
第一，expires in 6h 不是永久稳定

它说明当前 access token 有效 6 小时，理论上后面 refresh token 会自动续。
但你之前已经碰到过 refresh token 失效，所以别默认它永远稳。

你后面如果又突然不能用，先查这两个：

openclaw models
openclaw status
openclaw models auth login --provider qwen-portal
```
