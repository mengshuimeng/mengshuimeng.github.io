---
title: "Codex 实验会话恢复与状态交接记录"
date: 2026-10-13
authors:
  - "萌睡梦"
tags:
  - "Codex"
  - "实验管理"
---

可以，但要区分两种情况：

- **普通 Codex 会话**：可以用 `codex resume` 继续之前的 session，对话上下文会继承。
- 你最近 Phase 7.2 用的 `codex exec --ephemeral`：这是临时 session，**不能靠 resume 继承**；不过实验状态已经写进 `AGENTS.md`、Recovery Audit、Remote Preflight 等文件，所以新会话仍然能无缝继续。

以后电脑重启后，你只需要记下面这套最简单流程。

### 实验 Codex

打开 WSL：

```bash
cd ~/work/iet-cvi-phase72
```

确认服务器正常：

```bash
ssh reid-server 'cd /data/jsh/Reid/repo && hostname && git rev-parse --short HEAD'
```

正常应看到：

```text
hurricane-X99
9d27f6e
```

然后：

```text
codex resume
```

如果列表里有你之前的实验 session，就选它继续。

如果没有，直接：

```text
codex
```

然后第一句话告诉它：

```text
先读取 AGENTS.md，并读取 Phase 7.2 已有恢复审计和远端预检报告，
从当前状态继续，不重复已完成工作。
```

实验环境**不要再 SSHFS、不要 bind mount**。

---

### 论文 Codex

打开另一个 WSL 终端：

```bash
cd /mnt/d/Documents/code/latex/ChineseResearchLaTeX
```

然后：

```text
codex resume
```

选择之前 IET-CVI 的论文 session 即可继续之前的对话和上下文。

如果找不到旧 session，就：

```text
codex
```

然后告诉它：

```bash
这是论文 Codex。先读取仓库 AGENTS.md 和当前 IET-CVI 项目状态，
继续现有论文工作，不运行实验、不 SSH 服务器。
```

### 所以你以后只需要记这四行

```bash
# 实验
cd ~/work/iet-cvi-phase72
codex resume

# 论文
cd /mnt/d/Documents/code/latex/ChineseResearchLaTeX
codex resume
```

如果 `resume` 找不到 session，就把 `codex resume` 换成：

```text
codex
```

即可。

而且现在两套环境的关系固定为：

```text
实验 Codex
~/work/iet-cvi-phase72
       ↓ 普通 SSH
reid-server:/data/jsh/Reid/repo

论文 Codex
/mnt/d/Documents/code/latex/ChineseResearchLaTeX
```

**重启后两边都不需要重新挂载任何东西。**

另外，之前普通 Codex session 能保留“对话记忆”，但真正重要的实验状态还是应该以文件和服务器真实状态为准；这样即使 session 丢了，也不会丢研究进度。

我们接着昨天的 IET Computer Vision 论文投稿工作。现在不需要重新投稿，也不用重新上传论文。

今天的任务很明确：重新启动 Windows Edge 的远程调试连接 → 恢复 WSL 论文 Codex → 让 Codex 尝试重新生成 ScholarOne PDF Proof。

按照下面的顺序操作即可。

## 第一步：在 Windows 中重新启动专用 Edge

先打开 Windows PowerShell，注意不是 WSL 终端。

复制并执行：

```text
$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"

if (-not (Test-Path $edge)) {
    $edge = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
}

Start-Process -FilePath $edge -ArgumentList @(
    "--remote-debugging-port=9222"
    "--remote-debugging-address=127.0.0.1"
    "--user-data-dir=`"$env:LOCALAPPDATA\IET-CVI-Edge-Automation`""
    "https://mc.manuscriptcentral.com/theiet-cvi"
)
```

运行后，应该出现一个独立的 Microsoft Edge 窗口。

这个窗口使用我们之前建立的专用配置文件：

```text
IET-CVI-Edge-Automation
```

如果 ScholarOne 需要重新登录，正常登录即可。

注意：保持这个专用 Edge 窗口打开，今天暂时不要关闭。

## 第二步：检查 Edge 调试接口

打开 WSL Ubuntu 终端，执行：

```text
curl --noproxy '*' -fsS http://127.0.0.1:9222/json/version
```

正常情况下，你会看到类似：

```text
{
  "Browser": "Edg/154.0.4258.62",
  "Protocol-Version": "1.3",
  "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/browser/..."
}
```

版本号和 WebSocket ID 可能不同，这是正常的。

只要成功返回 `Browser`、`Protocol-Version` 和 `webSocketDebuggerUrl`，就说明连接已经准备好。

## 第三步：检查 Codex MCP

继续在 WSL 中执行：

```text
codex mcp list
```

我们昨天已经配置了两个 MCP：

| MCP               | 今天是否使用           |
| ----------------- | ---------------------- |
| `edge-devtools`   | 使用                   |
| `playwright-edge` | 不使用，之前初始化超时 |

确保 `edge-devtools` 仍处于 enabled 状态。

如果它不存在，再执行：

```text
codex mcp add edge-devtools -- \
  npx -y chrome-devtools-mcp@latest \
  --browser-url=http://127.0.0.1:9222
```

如果已经存在，不要重复添加。

## 第四步：恢复昨天的论文 Codex 会话

在 WSL 里执行：

```bash
cd /mnt/d/Documents/code/latex/ChineseResearchLaTeX
codex resume
```

进入会话选择界面后，选择昨天负责 IET-CVI / ScholarOne 投稿 的会话，而不是以前运行实验的 Codex 会话。

## 第五步：让 Codex 继续昨天尚未完成的工作

把下面的内容直接发送给论文 Codex：

今天已重新开机，准备继续昨天的投稿工作。

## 一、恢复上下文

期刊：IET Computer Vision

投稿系统：
https://mc.manuscriptcentral.com/theiet-cvi

唯一正式投稿包：
`/mnt/d/Documents/code/latex/IET-CVI-submission-20261011-FINAL/`

昨日最终核验报告：
`/mnt/d/documents/code/latex/chineseresearchlatex/.bensz-api/taREDACTED/shared/SCHOLARONE-FINAL-PRE-SUBMISSION-CHECK-20261012.md`

请先阅读报告，恢复昨天的工作状态。

## 二、浏览器连接

仅使用 `edge-devtools` MCP。

Windows Edge 已通过 CDP 9222 端口启动。

首先调用：

1. `list_pages`
2. `take_snapshot`

确认已连接 ScholarOne 的同一篇未提交草稿。

如果登录失效，请暂停，让我本人登录。

禁止使用 `playwright-edge`。

## 三、已完成事项

- Steps 1–5 均 Complete。
- 当前处于 Step 6: Review & Submit。
- 尚未正式提交。
- 七位作者顺序正确。
- 第一作者 Shuhao Jiang 邮箱为 [mengshuimeng@gmail.com](mailto:mengshuimeng@gmail.com)。
- Xiao Yang 是第三作者及唯一通讯作者。
- Main Document 和 SI 的 SHA256 已核验正确。
- LaTeX 源文件 designation 符合 ScholarOne 门户说明。
- Cover Letter 网页字段中的两个 Unicode 引号已成功替换为 ASCII 双引号并保存。

上述事项无须重复修改。

## 四、今天的主要任务

通过 ScholarOne 正常网页操作，重新尝试生成最新 PDF Proof。

昨天遇到的问题：

Cover Letter 网页字段已保存为：

"Detector-Generated Galleries in Person Search: A Controlled Cross-Representation Evaluation"

但下载的 PDF Proof 仍是修改前的旧版本，乱码没有消失。

旧 PDF SHA256：

```text
543dc419b689b3228cae1e50267b880ce233c85751e958c65c4425cdf373e63c
```

请按顺序：

1. 确认当前 ScholarOne 草稿存在，且没有发生重复投稿。
2. 进入 Step 5，只读确认 Cover Letter 的 ASCII 引号仍正确。
3. 检查 Step 2、Step 6 是否有正式的重新生成或更新 PDF Proof 操作。
4. 如果存在明确的 Generate / Build / Rebuild PDF 操作，正常执行。
5. 如果没有，通过正常导航返回 Author Dashboard。
6. 从 Unsubmitted Manuscripts 中使用 Continue Submission 重新打开同一篇草稿。
7. 分别检查 View HTML Proof 与 View PDF Proof。
8. 下载最新 PDF，比较 SHA256、Cover Letter 引号及页码。
9. 如果 PDF 更新成功，核验八页正文、七位作者、Cover Sheet、Graphical TOC 和 SI 状态。
10. 如果仍然返回旧文件，记录详细结果后停止，不反复执行相同操作。

## 五、重要限制

禁止：

- 点击最终 Submit / Confirm Submission。
- 删除或重新上传附件。
- 创建新投稿。
- 修改论文科学内容、图表、数据或源码。
- 修改最终投稿包。
- 改动作者信息。
- 通过猜测的隐藏接口强制生成 PDF。
- 进行付款或版权协议确认。

如遇需要人工确认的操作，请暂停。

## 六、最终报告

在任务 shared 工作区生成本次续办报告，记录：

- ScholarOne 登录及草稿状态
- HTML Proof 是否更新
- PDF Proof 是否更新
- 新旧文件 SHA256
- Cover Letter 乱码是否消失
- 空白页及自动页码是否仍异常
- SI 和源码文件状态是否保持不变
- 剩余需要人工处理的问题

最终返回：

```text
PROOF_REFRESH_SUCCESS
```

或

```text
PROOF_REFRESH_STILL_STALE
```

无论结果如何，禁止点击最终 Submit。

## 第六步：完成后把结果发给我

目前需要关注的只有以下几个状态：

论文及正式附件

 已核验

作者与通讯作者信息

 已核验

Cover Letter 网页内容

 已保存

PDF Proof 最新版本

 待重新生成

最终 Submit

尚未执行

现在先完成第一步和第二步。

也就是打开 PowerShell 启动专用 Edge，再在 WSL 执行：

```text
curl --noproxy '*' -fsS http://127.0.0.1:9222/json/version
```

如果正常返回，就继续恢复 Codex。如果报错，把终端输出发给我，我们先解决连接问题，再继续投稿。
