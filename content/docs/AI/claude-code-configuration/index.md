---
title: "Claude Code 安装与模型服务配置"
description: "整理 Claude Code 的安装目录、环境变量和第三方模型服务配置方式。"
---

下面是一套 **Windows 原生安装方案**，适合新电脑用于 **文档、论文、PPT、Java、前端、普通 Python、Node.js/Vue/React、一般项目开发**。整体顺序建议是：

```text
Git / Node.js 基础环境
↓
Claude Code Windows 版
↓
ccSwitch Windows 版
↓
通过 ccSwitch 配置 GLM / DeepSeek / OpenAI 等 provider
↓
安装 ECC Windows 插件
↓
复制 ECC rules
↓
测试
```

Claude Code 官方说明，它是一个能读取代码库、编辑文件、运行命令并集成开发工具的 agentic coding tool；Terminal CLI 和 VS Code 也支持第三方 provider，所以你这种 ccSwitch + GLM/DeepSeek/OpenAI 的路线是合理的。([Claude](https://code.claude.com/docs/en/overview))

------

## 一、推荐安装目录和配置目录

Windows 原生版会主要使用这些路径：

```text
C:\Users\你的用户名\.claude
C:\Users\你的用户名\.claude.json
C:\Users\你的用户名\.cc-switch
C:\Users\你的用户名\.agents
```

对应 PowerShell 里的写法是：

```powershell
$HOME\.claude
$HOME\.claude.json
$HOME\.cc-switch
$HOME\.agents
```

以后不要把 WSL 的：

```bash
/home/<username>/.claude
```

和 Windows 的：

```powershell
C:\Users\<username>\.claude
```

混在一起。它们是两套环境。

------

## 二、安装基础环境

## 1. 安装 Git for Windows

Claude Code 官方建议 Windows 原生环境安装 Git for Windows；如果没有 Git for Windows，Claude Code 会退回使用 PowerShell 作为 shell tool。官方也说明，Windows 上安装 Git Bash 后，Claude Code 会优先用 Git Bash 执行命令。([Claude](https://code.claude.com/docs/en/quickstart))

推荐使用 PowerShell 执行：

```powershell
winget install --id Git.Git -e
```

安装后关闭 PowerShell，重新打开，检查：

```powershell
git --version
```

如果显示版本号，说明 Git 安装成功。

## 2. 安装 Node.js LTS

ECC 复制 rules 不一定强制需要 Node.js，但它的依赖安装、脚本、hooks、包管理器检测等都和 Node.js / npm 有关系；ECC 文档里的安装步骤也包含 `npm install`，并说明插件支持 npm、pnpm、yarn、bun 等包管理器检测。([GitHub](https://github.com/affaan-m/everything-claude-code/blob/main/README.zh-CN.md))

推荐：

```powershell
winget install --id OpenJS.NodeJS.LTS -e
```

检查：

```powershell
node -v
npm -v
```

## 3. 安装 VS Code，可选但推荐

```powershell
winget install --id Microsoft.VisualStudioCode -e
```

------

## 三、安装 Claude Code Windows 版

## 方式 A：PowerShell 安装，推荐

打开 **PowerShell**，不要用管理员权限也可以。官方快速开始给出的 Windows PowerShell 安装命令是：([Claude](https://code.claude.com/docs/en/quickstart))

```powershell
irm https://claude.ai/install.ps1 | iex
```

安装完成后，关闭 PowerShell，重新打开，然后检查：

```powershell
claude --version
```

再运行诊断：

```powershell
claude doctor
```

## 方式 B：WinGet 安装

官方也提供 WinGet 安装方式，但说明 WinGet 安装不会自动更新，需要之后手动运行升级命令。([Claude](https://code.claude.com/docs/en/quickstart))

```powershell
winget install Anthropic.ClaudeCode
```

升级：

```powershell
winget upgrade Anthropic.ClaudeCode
```

## 方式 C：CMD 安装，不推荐但可用

CMD 不是 PowerShell。官方给出的 CMD 命令是：([Claude](https://code.claude.com/docs/en/quickstart))

```cmd
curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd
```

------

## 四、首次启动 Claude Code

进入你的项目目录，比如：

```powershell
cd D:\Documents\code
claude
```

第一次打开可能出现登录选项。官方 Claude Code 支持 Claude Pro/Max/Team/Enterprise、Anthropic Console/API，以及 Amazon Bedrock、Google Vertex AI、Microsoft Foundry 等方式登录。([Claude](https://code.claude.com/docs/en/quickstart))

但你如果主要用 **ccSwitch + GLM / DeepSeek / OpenAI-compatible provider**，可以先退出 Claude Code：

```text
Ctrl + C
```

然后先配置 ccSwitch。

------

## 五、安装 ccSwitch Windows 版

ccSwitch 是一个跨平台桌面管理器，用来管理 Claude Code、Codex、Gemini CLI、OpenCode、OpenClaw 等 CLI 工具的 provider、MCP、prompts、skills 和 sessions。它的 README 明确写了支持 Windows 10+，Windows 用户可以下载 `.msi` 安装包或 portable zip。([GitHub](https://github.com/farion1231/cc-switch))

## 1. 下载 Windows 安装包

进入 GitHub Releases 页面，下载最新的：

```text
CC-Switch-v{version}-Windows.msi
```

或者便携版：

```text
CC-Switch-v{version}-Windows-Portable.zip
```

我建议普通用户选：

```text
Windows.msi
```

便携版适合不想安装、想放在 U 盘或单独目录的人。

## 2. 安装并启动

安装 `.msi` 后，在开始菜单搜索：

```text
CC Switch
```

打开即可。

如果是 portable zip，解压后运行：

```text
CC-Switch.exe
```

## 3. 第一次打开后做什么

ccSwitch 的基本流程是：添加 provider，选择预设或自定义配置；然后选择 provider 并点 Enable；大多数工具需要重启 terminal 或 CLI，但 Claude Code 目前支持 provider 数据热切换。([GitHub](https://github.com/farion1231/cc-switch))

建议你按这个顺序：

```text
Add Provider
↓
选择 Claude Code
↓
选择 GLM / DeepSeek / OpenAI-compatible / Anthropic 官方 provider
↓
填写 API Key、Base URL、模型名
↓
Enable
```

------

## 六、ccSwitch Provider 配置建议

## 1. 如果你用 GLM / 智谱

大概这样填：

```text
Tool: Claude Code
Provider Type: Anthropic-compatible
Base URL: https://open.bigmodel.cn/api/anthropic
Auth Token: 你的智谱 API Key
Model: glm-4.6 / glm-5.1 / 你账号支持的模型
```

## 2. 如果你用 DeepSeek

大概这样填：

```text
Tool: Claude Code
Provider Type: Anthropic-compatible
Base URL: https://api.deepseek.com/anthropic
Auth Token: 你的 DeepSeek API Key
Model: 你账号支持的 DeepSeek 模型
```

## 3. 如果你用 OpenAI / ChatGPT 模型

更推荐配置到 **Codex**，不是硬塞给 Claude Code：

```text
Tool: Codex
Provider: OpenAI
Base URL: https://api.openai.com/v1
API Key: 你的 OpenAI API Key
Model: 你的 GPT 模型
```

如果 ccSwitch 里有 OpenAI-compatible 转 Claude Code 的预设，也可以测试，但主线建议仍然是：

```text
Claude Code → Claude / GLM / DeepSeek Anthropic-compatible
Codex → OpenAI / ChatGPT 模型
OpenCode → 多 provider 混合
```

## 4. 配置后测试

重新打开 PowerShell：

```powershell
claude
```

进入后输入：

```text
/status
```

如果能看到你配置的 GLM / DeepSeek / API Usage Billing 等信息，说明 ccSwitch 已经生效。

------

## 七、安装 ECC Windows 插件

ECC 是一个完整的 Claude Code 配置集合，包含 agents、skills、commands、hooks、rules、MCP 配置等。它的中文 README 说明，ECC 支持 Windows、macOS、Linux，并且 hooks 与脚本已用 Node.js 重写以增强跨平台兼容性。([GitHub](https://github.com/affaan-m/everything-claude-code/blob/main/README.zh-CN.md))

ECC 官方推荐插件安装方式。它要求 Claude Code CLI 版本至少为 **v2.1.0+**，因为插件系统 hooks 加载行为发生了变化。([GitHub](https://github.com/affaan-m/everything-claude-code))

## 1. 检查 Claude Code 版本

PowerShell 执行：

```powershell
claude --version
```

如果版本低于 2.1.0，先更新 Claude Code。

## 2. 备份 Claude 配置

```powershell
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if (Test-Path "$HOME\.claude") {
  Copy-Item "$HOME\.claude" "$HOME\.claude.backup.ecc.$timestamp" -Recurse -Force
}

if (Test-Path "$HOME\.claude.json") {
  Copy-Item "$HOME\.claude.json" "$HOME\.claude.json.backup.ecc.$timestamp" -Force
}
```

## 3. 进入 Claude Code

```powershell
claude
```

然后在 Claude Code 里输入：

```text
/plugin marketplace add https://github.com/affaan-m/everything-claude-code
```

再输入：

```text
/plugin install ecc@ecc
```

安装后输入：

```text
/reload-plugins
```

再查看：

```text
/plugin list ecc@ecc
```

ECC 官方文档给出的插件安装命令就是添加 marketplace 后安装 `ecc@ecc`；插件安装会让你获得 commands、agents、skills 和 hooks。([GitHub](https://github.com/affaan-m/everything-claude-code))

------

## 八、复制 ECC rules，Windows PowerShell 版

重点：**插件安装不会自动分发 rules**。ECC 文档明确提醒，如果已经通过 `/plugin install` 安装 ECC，不要再运行 `install.ps1 --profile full`、`install.sh --profile full` 或 `npx ecc-install --profile full`，否则会把同一批内容再次复制到用户目录，导致技能和运行时行为重复。([GitHub](https://github.com/affaan-m/everything-claude-code/blob/main/README.zh-CN.md))

## 1. 克隆 ECC 仓库

退出 Claude Code，回到 PowerShell：

```powershell
mkdir $HOME\tools -Force
cd $HOME\tools

git clone https://github.com/affaan-m/everything-claude-code.git
cd everything-claude-code
npm install
```

## 2. 复制推荐 rules

ECC 官方 Windows 示例只复制了 `common` 和 `typescript`。结合你的用途，我建议先复制这几个：

```powershell
New-Item -ItemType Directory -Force -Path "$HOME\.claude\rules" | Out-Null

Copy-Item -Recurse rules\common "$HOME\.claude\rules\" -Force
Copy-Item -Recurse rules\typescript "$HOME\.claude\rules\" -Force
Copy-Item -Recurse rules\web "$HOME\.claude\rules\" -Force
Copy-Item -Recurse rules\python "$HOME\.claude\rules\" -Force
Copy-Item -Recurse rules\java "$HOME\.claude\rules\" -Force
```

适配你的用途：

```text
common：通用行为规则
typescript：前端 / Node.js / TS 项目
web：网页和前端项目
python：普通 Python / AI 脚本
java：课程作业 / Java 项目
```

ECC 文档也提醒，手动复制 rules 时应该复制整个语言目录，而不是只复制目录里的单个文件，避免相对路径引用异常和文件名冲突。([GitHub](https://github.com/affaan-m/everything-claude-code/blob/main/README.zh-CN.md))

## 3. 不要执行 full install

不要执行：

```powershell
.\install.ps1 --profile full
npx ecc-install --profile full
```

你现在走的是 **Plugin + 手动 rules** 路线，这条线最稳。

------

## 九、测试 ECC 是否可用

打开你的项目目录，比如：

```powershell
cd D:\Documents\code\你的项目
claude
```

进入后：

```text
/reload-plugins
```

测试 ECC：

```text
/ecc:plan "先阅读当前项目结构，给我一份修改计划，不要直接修改文件"
```

再测试文档场景：

```text
/ecc:plan "帮我规划一篇课程论文的大纲，要求先给章节结构，不要直接写正文"
```

ECC 文档说明，插件安装路径使用命名空间命令，比如 `/ecc:plan`；手动安装路径才使用短命令形式，比如 `/plan`。([GitHub](https://github.com/affaan-m/everything-claude-code/blob/main/README.zh-CN.md))

------

## 十、推荐的全局中文规则

你可以给 Claude Code 加一个全局中文规则文件。PowerShell 执行：

```powershell
New-Item -ItemType Directory -Force -Path "$HOME\.claude" | Out-Null

@'
# User Preferences

- 默认使用简体中文回答。
- 只有在代码、命令、路径、错误信息、API 名称、函数名、变量名中保留英文。
- 写论文、PPT、项目申报书、课程心得时，语言要正式、自然，不要堆砌空话。
- 不要编造参考文献、实验数据、政策文件、导师意见或项目成果。
- 修改代码前先说明计划，除非用户明确要求直接修改。
- 对不确定的信息要明确说明不确定，不要编造。
'@ | Add-Content "$HOME\.claude\CLAUDE.md"
```

之后重新打开 Claude Code：

```powershell
claude
```

可以输入：

```text
/memory
```

检查是否加载了你的规则。

------

## 十一、推荐目录结构

建议你在 Windows 上这样组织：

```text
D:\Documents\code\       一般开发项目
D:\Documents\paper\      论文和课程材料
D:\Documents\ppt\        答辩和展示材料
D:\Documents\tools\      可选工具
```

进入项目时：

```powershell
cd D:\Documents\code\my-project
claude
```

不要长期在：

```powershell
C:\Users\你的用户名
```

里直接启动 Claude Code。Claude Code 在项目目录中运行效果最好，因为它能直接读取当前项目文件。

------

## 十二、常见问题处理

## 1. `claude` 不是内部或外部命令

关闭 PowerShell，重新打开。还不行就检查：

```powershell
where claude
```

如果找不到，重新运行安装：

```powershell
irm https://claude.ai/install.ps1 | iex
```

## 2. Git Bash 找不到

检查 Git：

```powershell
git --version
where bash
```

如果 Claude Code 找不到 Git Bash，可以在：

```powershell
notepad $HOME\.claude\settings.json
```

写入：

```json
{
  "env": {
    "CLAUDE_CODE_GIT_BASH_PATH": "C:\\Program Files\\Git\\bin\\bash.exe"
  }
}
```

官方文档也给出了通过 `CLAUDE_CODE_GIT_BASH_PATH` 指定 Git Bash 路径的方法。([Claude](https://code.claude.com/docs/en/setup))

## 3. ECC 安装后 `/plugin list ecc@ecc` 没内容

先执行：

```text
/reload-plugins
```

然后直接测试：

```text
/ecc:plan "测试 ECC 是否可用"
```

只要 `/reload-plugins` 显示加载了 plugin、skills、agents、hooks，通常就说明插件已经生效。

## 4. ccSwitch 切换 provider 后 Claude Code 没变

ccSwitch 文档说明，大多数工具切换后需要重启 terminal 或 CLI，Claude Code 当前支持 provider 数据热切换，但实际排错时仍建议重开 PowerShell。([GitHub](https://github.com/farion1231/cc-switch))

操作：

```text
关闭 Claude Code
关闭 PowerShell
重新打开 PowerShell
claude
/status
```

## 5. 配置乱了怎么恢复

看备份：

```powershell
dir $HOME | findstr ".claude.backup"
```

恢复时先关闭 Claude Code，然后把当前配置改名：

```powershell
Rename-Item "$HOME\.claude" ".claude.broken"
```

再把备份复制回来：

```powershell
Copy-Item "$HOME\.claude.backup.ecc.你的时间戳" "$HOME\.claude" -Recurse
```

------

## 十三、最终推荐安装顺序汇总

## PowerShell 执行

```powershell
winget install --id Git.Git -e
winget install --id OpenJS.NodeJS.LTS -e
winget install --id Microsoft.VisualStudioCode -e

irm https://claude.ai/install.ps1 | iex

claude --version
claude doctor
```

## 安装 ccSwitch

下载并安装：

```text
CC-Switch-v{version}-Windows.msi
```

然后：

```text
Add Provider → Claude Code → 填 GLM/DeepSeek/OpenAI-compatible → Enable
```

## Claude Code 内执行

```text
/plugin marketplace add https://github.com/affaan-m/everything-claude-code
/plugin install ecc@ecc
/reload-plugins
/plugin list ecc@ecc
```

## PowerShell 复制 ECC rules

```powershell
mkdir $HOME\tools -Force
cd $HOME\tools

git clone https://github.com/affaan-m/everything-claude-code.git
cd everything-claude-code
npm install

New-Item -ItemType Directory -Force -Path "$HOME\.claude\rules" | Out-Null

Copy-Item -Recurse rules\common "$HOME\.claude\rules\" -Force
Copy-Item -Recurse rules\typescript "$HOME\.claude\rules\" -Force
Copy-Item -Recurse rules\web "$HOME\.claude\rules\" -Force
Copy-Item -Recurse rules\python "$HOME\.claude\rules\" -Force
Copy-Item -Recurse rules\java "$HOME\.claude\rules\" -Force
```

## 最后测试

```powershell
cd D:\Documents\code\你的项目
claude
```

Claude Code 里输入：

```text
/status
/ecc:plan "先阅读当前项目结构，给我一份修改计划，不要直接修改文件"
```

这套方案就是：**Windows 原生 Claude Code + Windows 原生 ccSwitch + ECC Plugin + 精选 rules**。对文档和一般开发来说，这是最省事、路径最清晰、后期最不容易乱的方案。
