---
title: "Windows + WSL2 使用 Codex CLI 与 Oh My Codex"
description: "在 Windows 与 WSL2 环境中安装、配置和使用 Codex CLI 与 Oh My Codex 的实践指南。"
---

---

## Windows + WSL2 使用 Codex CLI + Oh My Codex 指南

### 1. 这套工具是干什么的？

在 Windows + WSL2 环境下，推荐把 **Codex CLI** 和 **Oh My Codex（OMX）** 当成一套“本地项目开发助手”来用。

简单理解：

```text
Codex CLI = 原生代码助手
Oh My Codex / OMX = Codex 的增强工作流层
WSL2 = 推荐运行环境
Windows 磁盘 = 项目文件所在位置
```

Codex CLI 是 OpenAI 的本地终端编码助手，可以在你选定的目录中读取、修改和运行代码。([OpenAI开发者](https://developers.openai.com/codex/cli?utm_source=chatgpt.com))
OMX 则是在 Codex CLI 外面加了一层工作流能力，例如 prompts、skills、agent team、HUD、hooks、项目探索等。([GitHub](https://github.com/Yeachan-Heo/oh-my-codex?utm_source=chatgpt.com))

---

### 2. 推荐环境

本文默认环境如下：

```text
Windows 11
WSL2
Ubuntu 22.04.5 LTS
Node.js 20+
Codex CLI
Oh My Codex
Rust / Cargo
```

你当前环境已经验证通过：

```bash
node -v
# v22.22.1

codex --version
# codex-cli 0.125.0

omx --version
# oh-my-codex v0.15.1
```

你后面安装 Rust 后，`omx doctor` 已经显示：

```text
Results: 14 passed, 0 warnings, 0 failed

All checks passed! oh-my-codex is ready.
```

这说明你的 Codex CLI、OMX、skills、prompts、hooks、AGENTS.md、MCP servers、Explore Harness 都已经正常。

---

### 3. Windows 路径和 WSL 路径怎么对应？

在 WSL 中，Windows 磁盘会挂载到 `/mnt` 目录下。

常见对应关系：

```text
C:\Users\xxx        -> /mnt/c/Users/xxx
D:\Documents       -> /mnt/d/Documents
E:\project         -> /mnt/e/project
```

比如你的项目实际路径是：

```bash
/mnt/d/Documents/code/python/ProjectPilot
```

Windows 下对应大概是：

```text
D:\Documents\code\python\ProjectPilot
```

如果找不到项目，可以用：

```bash
ls /mnt
ls /mnt/d
ls /mnt/d/Documents
ls /mnt/d/Documents/code
```

或者直接搜索：

```bash
find /mnt/d -maxdepth 6 -type d -iname "ProjectPilot" 2>/dev/null
```

---

### 4. 安装 Node.js

Codex CLI 和 OMX 都依赖 Node.js。建议使用 Node.js 20 或更高版本。

检查：

```bash
node -v
npm -v
```

如果没有 Node.js，可以先安装。你现在已经有：

```bash
node -v
# v22.22.1
```

所以这一步不用再做。

---

### 5. 安装 Codex CLI

官方支持通过 npm 或 Homebrew 安装 Codex CLI；在 WSL2 中推荐用 npm。([GitHub](https://github.com/openai/codex?utm_source=chatgpt.com))

```bash
npm install -g @openai/codex
```

检查版本：

```bash
codex --version
```

登录状态检查：

```bash
codex login status
```

如果没有登录：

```bash
codex login
```

如果要退出登录：

```bash
codex logout
```

你的当前状态已经是：

```text
Logged in using ChatGPT
```

所以 Codex 登录正常。

---

### 6. 安装 Oh My Codex

安装或更新 OMX：

```bash
npm install -g @openai/codex oh-my-codex
```

检查版本：

```bash
omx --version
```

初始化 OMX：

```bash
omx setup --force
```

推荐选择：

```text
Select setup scope:
1) user

Select user-scope skill delivery mode:
1) legacy
```

也就是：

```text
scope = user
install mode = legacy
```

这样会把 OMX 的全局配置安装到：

```bash
~/.codex
```

包括：

```text
~/.codex/config.toml
~/.codex/hooks.json
~/.codex/AGENTS.md
~/.codex/skills/
~/.codex/prompts/
~/.codex/agents/
```

OMX 官方 README 也建议安装或版本更新后运行 `omx setup`，再用 `omx doctor` 检查。([GitHub](https://github.com/Yeachan-Heo/oh-my-codex?utm_source=chatgpt.com))

---

### 7. 安装 Rust / Cargo

如果 `omx doctor` 里出现：

```text
Explore Harness: Rust harness sources are packaged, but no compatible packaged prebuilt or cargo was found
```

说明 `omx explore` 还不能用。

安装依赖：

```bash
sudo apt update
sudo apt install -y build-essential pkg-config libssl-dev curl
```

安装 Rust：

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

安装过程中选择：

```text
1) Proceed with standard installation
```

加载环境变量：

```bash
source "$HOME/.cargo/env"
```

检查：

```bash
rustc --version
cargo --version
```

你当前已经安装成功：

```text
rustc 1.95.0
cargo 1.95.0
```

并且 `omx doctor` 已显示 Explore Harness ready。

---

### 8. 检查 OMX 是否安装完整

执行：

```bash
omx doctor
```

理想结果：

```text
Results: 14 passed, 0 warnings, 0 failed

All checks passed! oh-my-codex is ready.
```

如果看到：

```text
Prompts: 33 agent prompts installed
Skills: 30 skills installed
AGENTS.md: found
MCP Servers: 5 servers configured
Explore Harness: ready
```

说明 OMX 环境已经完整。

---

### 9. 做一次真实调用测试

执行：

```bash
omx exec --skip-git-repo-check -C . "Reply with exactly OMX-EXEC-OK"
```

正常输出应该包含：

```text
OMX-EXEC-OK
```

如果你看到末尾有类似：

```text
ERROR codex_core::session: failed to record rollout items
```

但前面已经输出了：

```text
OMX-EXEC-OK
```

通常说明模型调用成功，只是会话记录保存阶段有非致命问题。可以先不管。

---

### 10. Codex CLI 怎么用？

进入项目目录：

```bash
cd /mnt/d/Documents/code/python/ProjectPilot
```

启动 Codex：

```bash
codex
```

适合用 Codex CLI 的场景：

```text
解释代码
修改单个函数
修复一个报错
补充一个测试
修改 README 的一小段
运行项目命令
查看 Git diff
```

进入 Codex 后可以直接说：

```text
请阅读 README.md 和 main.py，告诉我这个项目怎么启动。
```

或者：

```text
帮我检查这个报错，并给出最小修改方案。
```

Codex CLI 支持 slash commands，你可以输入 `/` 查看命令，例如切换模型、调整权限、查看状态等。([OpenAI开发者](https://developers.openai.com/codex/cli/slash-commands?utm_source=chatgpt.com))

常用命令：

```text
/help
/status
/model
/permissions
/clear
/skills
```

---

### 11. Oh My Codex 怎么用？

进入项目目录：

```bash
cd /mnt/d/Documents/code/python/ProjectPilot
```

启动 OMX：

```bash
omx --madmax --high
```

OMX 官方 README 推荐的典型启动方式就是：

```bash
omx --madmax --high
```

并且建议安装后运行 `omx doctor` 和真实调用 smoke test。([GitHub](https://github.com/Yeachan-Heo/oh-my-codex?utm_source=chatgpt.com))

适合用 OMX 的场景：

```text
审查整个项目
多文件修改
重构项目结构
生成课程项目提交材料
检查 README、测试、CI、文档
让 AI 先规划再执行
复杂任务分角色执行
```

进入 OMX 后，先看 skills：

```text
/skills
```

常用工作流：

```text
$plan 请只读分析当前项目，不要修改文件，列出问题和修改计划。
$architect 请分析当前项目架构、模块边界和可优化点。
$executor 按照刚才的计划执行修改，并说明改了哪些文件。
```

---

### 12. omx explore 怎么用？

`omx explore` 是 OMX 的只读仓库探索能力，适合快速扫项目结构。OMX 文档说明，`omx explore` 使用 Rust native harness 做更快、更严格的只读仓库探索。([GitHub](https://github.com/Yeachan-Heo/oh-my-codex/blob/main/docs/readme/README.zh-TW.md?utm_source=chatgpt.com))

用法：

```bash
cd /mnt/d/Documents/code/python/ProjectPilot

omx explore --prompt "只读分析这个仓库结构，列出主要目录、运行入口、依赖文件、测试文件和明显问题。"
```

适合在正式让 OMX 修改项目之前先跑一遍。

推荐流程：

```bash
cd /mnt/d/Documents/code/python/ProjectPilot

omx explore --prompt "只读分析当前项目结构，告诉我入口文件、依赖文件、测试文件、文档文件和风险。"

omx --madmax --high
```

然后在 OMX 里：

```text
$plan 请基于刚才的项目结构，制定一个最小可行修改计划。先不要修改文件。
```

---

### 13. 权限模式怎么理解？

Codex / OMX 能不能修改文件、能不能执行命令，取决于权限和沙箱设置。

OpenAI 文档说明，sandbox 是让 Codex 在受限环境中执行命令，而不是默认拿到你机器的无限权限。([OpenAI开发者](https://developers.openai.com/codex/concepts/sandboxing?utm_source=chatgpt.com))

常见理解：

```text
read-only
只能读文件，适合第一次审查项目。

workspace-write
可以读写当前工作区，适合正常开发。

YOLO / danger-full-access
权限更激进，适合你非常信任任务、能回滚代码、知道它会做什么的时候。
```

进入 Codex 或 OMX 后可以输入：

```text
/permissions
```

调整权限。

我的建议：

```text
第一次看项目：read-only
正常改代码：workspace-write
确定能回滚时：YOLO
系统目录、隐私目录：不要给高权限
```

---

### 14. 推荐工作流

#### 14.1 只读分析项目

```bash
cd /mnt/d/Documents/code/python/ProjectPilot
omx explore --prompt "只读分析项目结构，列出入口、依赖、测试、文档和风险。"
```

然后：

```bash
omx --madmax --high
```

进入后：

```text
$plan 请只读分析当前项目，不要修改文件，按“必须修改 / 建议修改 / 可选优化”输出。
```

---

#### 14.2 修改 README

```text
$executor 请根据刚才的计划，只修改 README.md，补充项目简介、环境依赖、运行方式、测试方式和目录结构。修改前先说明计划。
```

修改后回到终端检查：

```bash
git diff README.md
```

---

#### 14.3 修复项目运行问题

```text
$plan 请检查项目运行入口和依赖，不要修改文件，先告诉我为什么运行失败。
```

确认后：

```text
$executor 按照你的分析修复最小问题，并运行必要测试。
```

---

#### 14.4 生成课程作业提交材料

```text
$architect 请分析这个项目是否适合作为课程作业提交，重点检查 README、功能闭环、截图说明、测试、CI、文档完整性。
$executor 请生成一份 docs/submission_checklist.md，列出提交材料、运行步骤和展示重点。
```

---

### 15. Git 配合使用

在让 Codex 或 OMX 修改项目前，先检查状态：

```bash
git status
```

查看修改：

```bash
git diff
```

修改满意后提交：

```bash
git add .
git commit -m "Update project documentation and setup"
```

不满意时恢复：

```bash
git restore 文件名
```

例如：

```bash
git restore README.md
```

如果还不熟悉 Git，不要乱用：

```bash
git reset --hard
```

这个命令会丢弃所有未提交修改。

---

### 16. 常见问题排查

#### 16.1 `cd` 项目路径失败

错误：

```bash
-bash: cd: /mnt/d/Documents/code/ProjectPilot: No such file or directory
```

说明路径不对。

解决：

```bash
ls /mnt
ls /mnt/d/Documents/code
find /mnt/d -maxdepth 6 -type d -iname "ProjectPilot" 2>/dev/null
```

你的真实路径是：

```bash
/mnt/d/Documents/code/python/ProjectPilot
```

---

#### 16.2 `python: command not found`

错误：

```text
python: command not found
```

解决：

```bash
sudo apt update
sudo apt install -y python-is-python3
```

检查：

```bash
python --version
python3 --version
```

---

#### 16.3 `omx explore` 报 cargo 不存在

错误：

```text
cargo was not found
```

解决：

```bash
sudo apt update
sudo apt install -y build-essential pkg-config libssl-dev curl

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

cargo --version
rustc --version

omx doctor
```

---

#### 16.4 `apt update` 出现 RealSense 公钥错误

你遇到过：

```text
NO_PUBKEY FB0B24895113F120
https://librealsense.intel.com/Debian/apt-repo
```

这是 Intel RealSense 软件源缺少 GPG 公钥，和 Codex / OMX 没关系。

如果你暂时不处理 RealSense，可以先忽略。
如果后面要继续做 D435i / ROS2 / RealSense，再单独修这个源。

---

#### 16.5 OMX 提示是否信任当前目录

你可能会看到：

```text
Do you trust the contents of this directory?
1. Yes, continue
2. No, quit
```

如果这是你自己的项目，可以选：

```text
1
```

如果是陌生仓库、网上下载的项目、别人发来的压缩包，建议先用低权限或只读模式。

---

### 17. Codex 和 OMX 怎么选择？

#### 小任务：用 Codex CLI

```bash
cd /mnt/d/Documents/code/python/ProjectPilot
codex
```

适合：

```text
解释代码
修一个函数
看一个报错
改一个文件
运行一个测试
```

---

#### 大任务：用 OMX

```bash
cd /mnt/d/Documents/code/python/ProjectPilot
omx --madmax --high
```

适合：

```text
多文件修改
项目整体审查
复杂重构
生成提交材料
先计划再执行
多角色分析
```

---

#### 只读探索：用 omx explore

```bash
cd /mnt/d/Documents/code/python/ProjectPilot
omx explore --prompt "只读分析当前项目。"
```

适合：

```text
先快速了解项目结构
不想让 AI 修改文件
检查入口、依赖、测试、文档
```

---

### 18. 推荐日常命令清单

#### 环境检查

```bash
node -v
npm -v
codex --version
omx --version
codex login status
omx doctor
```

#### 更新工具

```bash
npm install -g @openai/codex oh-my-codex
omx setup --force
omx doctor
```

#### 进入项目

```bash
cd /mnt/d/Documents/code/python/ProjectPilot
```

#### 只读探索

```bash
omx explore --prompt "只读分析项目结构，列出入口、依赖、测试、文档和风险。"
```

#### 启动 Codex

```bash
codex
```

#### 启动 OMX

```bash
omx --madmax --high
```

#### 查看 Git 状态

```bash
git status
git diff
```

---

### 19. 推荐提示词模板

#### 19.1 只读审查

```text
$plan 请只读审查当前项目，不要修改任何文件。重点检查 README、运行入口、依赖文件、测试、CI、文档和课程提交材料完整性。最后按“必须修改 / 建议修改 / 可选优化”输出。
```

#### 19.2 修改前规划

```text
$plan 请先制定最小修改计划，不要直接改文件。要求每一步都说明目标、涉及文件、验证方式和回滚方式。
```

#### 19.3 执行修改

```text
$executor 按照刚才的计划执行修改。每次修改后说明改了哪些文件、为什么改、如何验证。
```

#### 19.4 检查运行

```text
$executor 请运行项目的基础测试或 smoke test。如果失败，先解释失败原因，再给出最小修复方案。
```

#### 19.5 生成提交说明

```text
$executor 请根据当前项目生成一份课程提交说明，包含项目简介、环境依赖、运行步骤、功能展示、测试方式和注意事项。
```

---

### 20. 最稳的使用习惯

建议你养成这个顺序：

```text
1. cd 到项目目录
2. git status 看有没有未提交修改
3. omx explore 做只读探索
4. omx --madmax --high 启动 OMX
5. $plan 先规划
6. 确认计划
7. $executor 再修改
8. git diff 检查修改
9. 运行测试
10. commit 或 restore
```

不要一上来就：

```text
直接帮我改完整个项目
```

更稳的说法是：

```text
先只读分析，不要修改文件。
```

然后：

```text
给出最小修改计划。
```

最后：

```text
按计划执行，并说明每一步修改。
```

---

### 21. 我的建议

你现在这套环境已经完整可用了。

最实用的分工是：

```text
Codex CLI：日常小修小补
OMX：复杂项目工作流
omx explore：只读扫项目
skills：固定常用流程
AGENTS.md：全局行为规则
hooks：自动化辅助检查
Rust/Cargo：支撑 explore harness
```

以后你做课程项目、GitHub 项目、论文代码、比赛仓库，都可以用这套流程：

```bash
cd 项目目录
omx explore --prompt "只读分析当前项目结构和风险。"
omx --madmax --high
```

进入后：

```text
$plan 先规划，不要修改文件。
$executor 确认后再执行。
```

这就是 Windows + WSL2 下使用 Codex CLI + Oh My Codex 最稳的方式。
