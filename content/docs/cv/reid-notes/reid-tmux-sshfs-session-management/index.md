---
title: "ReID 服务器训练与 tmux、SSHFS 会话维护"
date: 2026-10-01
authors:
  - "萌睡梦"
tags:
  - "ReID"
  - "tmux"
  - "SSHFS"
---

可以。你一会儿**直接关闭本地终端也没关系**，因为当前 P5 已经在服务器 `tmux` 里运行，本地 WSL/Codex 只是控制端。

1. 然后检查 SSHFS 是否还在：

```bash
findmnt -T /home/jj/remote/Reid
findmnt -T /mnt/d/Documents/code/python/Reid
```

正常应该看到：

```text
reid-server:/data/jsh/Reid/repo
fuse.sshfs
```

如果又变成：

```text
/home/jj/remote/Reid -> /
/mnt/d/...          -> D:\ 9p
```

就说明 SSHFS/bind 没了，重新挂：

```bash
cd ~

mkdir -p /home/jj/remote/Reid

sshfs reid-server:/data/jsh/Reid/repo \
  /home/jj/remote/Reid \
  -o reconnect \
  -o idmap=user \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3
```

然后：

```bash
sudo mount --bind \
  /home/jj/remote/Reid \
  /mnt/d/Documents/code/python/Reid
```

验证：

```bash
findmnt -T /mnt/d/Documents/code/python/Reid
git -C /mnt/d/Documents/code/python/Reid rev-parse --short HEAD
ls /mnt/d/Documents/code/python/Reid/AGENTS.md
```

1. 挂载正常以后重新启动 Codex：

```bash
cd /mnt/d/Documents/code/python/Reid
cd /mnt/d/Documents/code/latex/ChineseResearchLaTeX
codex
```

然后直接给它这段恢复指令：

```text
恢复自主实验。

先读取：
- AGENTS.md
- docs/order32-autonomous-experiment-state.md

然后通过 ssh reid-server 核验真实服务器状态：
- tmux
- 当前训练/评测进程
- 最新日志
- completion marker
- nvidia-smi
- Git HEAD
- git status
- 当前 output directory

不要重复已经完成的实验。
不要因为 tmux 不存在就直接判断任务失败；
先检查日志、输出、COMPLETED/FAILED/EXIT_CODE。

如果当前长任务仍在运行：
继续监控，不启动重复实例。

如果当前任务已经正常完成：
执行对应 Gate 验证，然后从状态文件记录的下一阶段继续。

当前总体路线：
P1 PASS
P2 PASS
P3 PASS
P4 PASS
P5 当前阶段
之后继续 P6 → P7。

所有实际 Python/Git/pytest/GPU/训练/评测仍必须通过 ssh reid-server 执行。
正式 Python：
/data/jsh/conda-envs/reid-p1p8/bin/python

以服务器真实状态为准。
```

你甚至不用恢复之前那个 Codex session。因为现在已经有：

```text
docs/order32-autonomous-experiment-state.md
```

作为恢复点，**新开一个 Codex 会话也能接着干**。

最重要的原则只有两个：

```text
关终端前：
长任务必须已经在服务器 tmux 中

重新打开后：
先查服务器真实状态，再启动 Codex
```

所以你现在 P5 在 `tmux` 中，**可以放心关闭终端**。本地终端关闭、Codex退出、WSL窗口关闭，都不会影响服务器上的 P5。

等以后 P5/P6/P7 都稳定后，我建议再给你做一个 `reid-codex` 一键恢复脚本，以后重新打开 WSL 只需要输入一条命令，就自动检查 SSH、恢复 SSHFS+bind、验证服务器和启动 Codex。
