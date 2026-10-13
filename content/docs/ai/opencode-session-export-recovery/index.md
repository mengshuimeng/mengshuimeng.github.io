---
title: "OpenCode 会话导出与恢复记录"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "OpenCode"
  - "会话管理"
---

安装后输入 `ultrawork` 或 `ulw`。

找 OpenCode 会话 ID 主要用这条命令：

```bash
opencode session list
```

```bash
cd ~/projects/tmp/Rc-Vision
mkdir -p docs/session_recovery

opencode export ses_211f69b07ffe9Myv1EU0XVdKVt > docs/session_recovery/broken_opencode_session.json


opencode export ses_210f6b1f0ffeAa3znNc4TGplus > docs/session_recovery/broken_opencode_session2.json

ses_210f6b1f0ffeAa3znNc4TGplus
```

```text
请停止继续执行任务。

现在做阶段性收尾：
1. 总结本阶段做了什么
2. 列出修改过的文件
3. 列出还没完成的任务
4. 列出当前风险
5. 列出下一步建议
6. 把以上内容写入 docs/WORKLOG.md
7. 然后压缩当前上下文，保留关键决策、接口约束、文件路径和下一步任务

不要继续修改业务代码。
```

## 每个新工程建议做的三件事

### 1. 先检查项目状态

```bash
git status
```

如果看到有未提交修改，先别让 OpenCode 直接改代码。

### 2. 建立项目规则

```text
opencode
```

然后：

```text
/init
```

之后你可以手动编辑：

```text
nano AGENTS.md
```

写清楚：

```text
# Project Rules

## Project Background
这是一个什么项目。

## Important Constraints
- 不要随便删除文件。
- 不要大范围重构。
- 修改前先说明计划。
- 涉及接口变化时先解释影响。

## Build and Test
- 如何运行项目。
- 如何测试项目。
- 常见命令是什么。
```

### 3. 给项目单独建 `opencode.json`

```text
nano opencode.json
```

可以先用这个通用模板：

```text
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "plan",
  "share": "manual",
  "permission": {
    "edit": "ask",
    "bash": "ask"
  },
  "watcher": {
    "ignore": [
      ".git/**",
      "node_modules/**",
      "dist/**",
      "build/**",
      "install/**",
      "log/**",
      "__pycache__/**",
      ".venv/**",
      "venv/**"
    ]
  }
}
```

这里我建议你把默认代理先设成 `"plan"`，因为官方配置里支持 `default_agent`，没有明确指定代理时会使用它；对新项目来说，先让它分析和规划，比直接改代码更安全。

---

## 你每次进入新项目的固定口诀

```bash
cd 项目根目录
git status
opencode
```

第一次进这个项目：

```text
/init
```

然后先问它：

```text
先阅读项目结构和 AGENTS.md，不要修改文件。请总结这个项目的目录结构、运行方式和主要模块。
```

确认它理解正确后，再让它做事：

```text
先制定修改计划，不要改文件。我要实现 xxx 功能，请说明需要修改哪些文件、为什么修改、风险是什么。
```

我的建议很明确：**一个工程一个 `AGENTS.md`，一个工程一个 `opencode.json`，每次都在项目根目录启动 `opencode`。** 这样最稳。
