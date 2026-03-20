# Ubuntu 基础命令与终端使用

> 本文档用于介绍 Ubuntu / WSL 中最常用的基础操作，包括系统架构判断、系统更新、终端快捷键、`nano` 编辑器使用等内容。  
>
> 适用对象：初学者、第一次使用 Ubuntu / WSL 的同学  
> 作者：姜树豪（JSH）  
> 更新时间：2026-03-09

---

## 目录

1. 判断系统架构
2. 更新系统
3. 终端常用快捷键
4. `nano` 的保存与退出
5. 常用基础命令速查表

---

## 1. 判断系统架构

在 Ubuntu 中判断系统是 **x64（x86_64）** 还是 **ARM（aarch64 / arm64）**，最常用的方法是：

```bash
uname -m
```

常见输出含义如下：

- `x86_64`：表示 64 位 x86 架构，也就是常说的 **x64**
- `aarch64`：表示 **ARM64**
- `armv7l`：表示较老的 32 位 ARM

这个步骤很重要，因为后续安装 Miniconda、某些 `.deb` 安装包或 Python wheel 文件时，都需要先确认架构。

------

## 2. 更新系统

安装软件前，建议先更新软件包索引，并升级现有软件：

```bash
sudo apt update && sudo apt upgrade -y
```

说明：

- `apt update`：更新软件包索引
- `apt upgrade -y`：升级已安装软件，并自动确认

如果你只想刷新软件源，不想马上升级系统，也可以只执行：

```bash
sudo apt update
```

------

## 3. 终端常用快捷键

在 Ubuntu 终端中，常用快捷键如下：

```text
复制：Ctrl + Shift + C
粘贴：Ctrl + Shift + V
打开终端：Ctrl + Alt + T
```

如果你使用的是 Windows Terminal + WSL，通常也支持这些快捷键。

------

## 4. `nano` 的保存与退出

`nano` 是 Ubuntu 中很常用的终端文本编辑器。

### 打开文件

例如编辑 `.bashrc`：

```bash
nano ~/.bashrc
```

### 保存文件

按下：

```text
Ctrl + O
```

然后按：

```text
Enter
```

### 退出编辑器

按下：

```text
Ctrl + X
```

### 完整操作流程

```text
打开文件 → 修改内容 → Ctrl + O → Enter → Ctrl + X
```

------

## 5. 常用基础命令速查表

| 操作             | 命令                  |
| ---------------- | --------------------- |
| 查看当前路径     | `pwd`                 |
| 查看当前目录内容 | `ls`                  |
| 切换到根目录     | `cd /`                |
| 切换到家目录     | `cd ~`                |
| 查看系统架构     | `uname -m`            |
| 更新软件源       | `sudo apt update`     |
| 升级系统         | `sudo apt upgrade -y` |
| 编辑 `.bashrc`   | `nano ~/.bashrc`      |

------

## 总结

这一篇主要解决三个基础问题：

1. 你的 Ubuntu 到底是什么架构
2. 安装软件前应该先做什么
3. 终端和 `nano` 最基本怎么用

如果这几个基础动作不熟，后面装 Miniconda、VS Code、Docker 都很容易卡住。