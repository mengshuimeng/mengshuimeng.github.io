---
title: "从当前环境生成 requirements.txt"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "Python"
  - "依赖管理"
---

## 202

## 1. **生成 `requirements.txt`（从当前环境）**

如果你已经安装了所需包，可以用以下命令导出：

```bash
pip freeze > requirements.txt
```

> ⚠️ 注意：这会导出**所有已安装的包**（包括间接依赖）。如果只想导出项目直接依赖，建议用 `pip-tools` 或手动维护。

---

3.

```bash
pip install pip-tools
```

## 2. **根据 `requirements.txt` 安装依赖**

在新环境（如虚拟环境、服务器、同事电脑）中，运行：

```bash
pip install -r requirements.txt
```

> `-r` 表示 “read from file”。
