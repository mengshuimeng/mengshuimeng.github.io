# 🐧 WSL 使用与环境配置指南

> 本文档用于说明 WSL 的安装、基本使用、路径机制、发行版迁移、多版本 Ubuntu 共存、默认用户设置、代理问题。
>
> 适用平台：**Windows 10 / Windows 11**
> 更新时间：2026-03-08

------

## 📂 目录

1. 安装与更新 WSL
2. 进入 WSL 与查看发行版
3. WSL 的路径机制
4. 导出、注销与导入发行版
5. 设置默认用户
6. 安装 Ubuntu 22.04 并与 24.04 共存
7. 代理问题说明
8. 安装 Miniconda
9. 下载文件示例
10. 常见误区与结论

------

## 参考链接

- [超详细Windows子系统（Wsl2）下安装Ubuntu22.04（cuda11.8）-MambaVision框架使用（自用版）_wsl安装ubuntu22.04-CSDN博客](https://blog.csdn.net/weixin_51949030/article/details/144729352)

- [安装WSL |Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install)

---

## 0.开启所需的Windows功能

使用”**Windows+R**“快捷键，在打开的「运行」窗口中输入"**`optionalfeatures`**"打开「Windows 功能」

启用windows功能中的"**虚拟机平台"**和"**适用于Linux的Windows子系统"。**

然后根据提升重启电脑。

## 1. 安装与更新 WSL

微软官方推荐使用 `wsl --install` 安装 WSL，并建议保持 WSL 组件为较新版本。常用命令如下：([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com))

```powershell
wsl.exe --update
wsl --set-default-version 2
```

查找 Ubuntu 发行版

```
wsl --list --online
```

安装指定发行版 Ubuntu 22.04

```
wsl --install -d Ubuntu-22.04 
# wsl --install
```

设定用户名和密码

说明：

- `wsl.exe --update`：更新 WSL 组件
- `wsl --install`：安装 WSL 及默认 Linux 发行版
- 新安装的 Linux 发行版默认会使用 **WSL 2**。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com))

------

## 2. 进入 WSL 与查看发行版

### 2.1 进入默认发行版

```powershell
wsl
```

### 2.2 进入指定发行版

```powershell
wsl -d Ubuntu
```

### 2.3

启动时Ubuntu22.04 LTS时，设定用户名和密码

### 2.4查看当前已安装的发行版

```powershell
wsl -l -v
```

示例输出：

```text
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

其中：

- `NAME`：发行版名称
- `STATE`：当前状态
- `VERSION`：WSL 版本，通常为 1 或 2。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/basic-commands?utm_source=chatgpt.com))

------

## 3. 位置迁移（默认在c盘，建议迁移，最低需要50GB空间）

WSL 支持导出和导入发行版，这适合迁移系统、改变安装位置或备份环境。微软官方将 `--export`、`--import` 列为标准命令。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/basic-commands?utm_source=chatgpt.com))

### 3.1 查看已安装的 Linux 发行版本

```sql
wsl -l --all -v
```

### 3.2 导出发行版

导出分发版为 tar 文件到 E盘上并注销原tar，需要等待一段时间，并且当前 Ubuntu 会退出

```powershell
# 导出发行版本为文件
wsl --export Ubuntu-22.04 E:\ubuntu22.04.tar
```

### 3.3 注销原发行版

注销此发行版本，完成此操作后，可以看到对应的 C 盘空间减少了许多

`--unregister` 会删除该发行版实例，请确认已经完成备份。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/basic-commands?utm_source=chatgpt.com))

```powershell
wsl --unregister Ubuntu
```

### 3.4 导入发行版到新位置

```powershell
wsl --import <子系统名称> <迁移到哪一个文件下> <要导入的包路径> --version 2
# 示例如下
# wsl --import Ubuntu-22.04 E:\wsl-ubuntu22.04 E:\ubuntu22.04.tar --version 2
```

含义如下：

- `Ubuntu`：导入后的发行版名称
- `E:\wsl-ubuntu22.04`：安装位置
- `E:\ubuntu22.04.tar`：导出的 tar 包
- `--version 2`：指定使用 WSL 2

------

## 4. 设置默认用户

设置默认用户为之前安装时的用户，不然默认是 root 身份，使用不方便

### 方法一

```
ubuntu2204.exe config --default-user username  # ubuntu22为用户名
```

### 方法二

首先打开 PowerShell，输入 `wsl` 进入默认的 Linux 环境（此时你应该是 root 或默认用户）。

```powershell
wsl -u root -d ubuntu22.04
```

在 WSL 终端中运行以下命令，使用 `nano` 编辑器创建/修改 `/etc/wsl.conf`：

```bash
sudo nano /etc/wsl.conf
```

写入以下内容（将 `jiang` 替换为你的实际用户名）：：

```ini
[user]
default=jiang
```

> [!NOTE]
>
> **注意**：
>
> 1. `[user]` 和 `default=jj` 之间不要有空行。
> 2. 确保用户名 `jj` 拼写正确（区分大小写）。
> 3. 如果文件中已有其他内容，请确保这段代码放在合适的位置，不要破坏原有结构。

保存并退出

1. 按 `Ctrl + O` 然后按 `Enter` 键（保存文件）。
2. 按 `Ctrl + X` 键（退出编辑器）。

在 Windows 侧执行：

```powershell
wsl --shutdown
wsl -d ubuntu22.04
```

这样再次进入时，默认用户就会变成 `jiang`。微软 FAQ 和配置文档都明确说明了 `wsl.conf` 可以用来设置 `user.default`。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/wsl-config?utm_source=chatgpt.com))

验证是否成功

重新打开 WSL 后，观察命令行提示符：

- **失败前**：提示符通常是 `#` (root) 或其他默认用户。
- **成功后**：提示符应该变成 `jj@你的主机名:~$`。

你可以运行 `whoami` 确认：

```bash
whoami
# 输出应该是：jj
```

------

### **⚠️ 常见问题排查**

------

## 5. 安装 Ubuntu 22.04 并与 24.04 共存

WSL 支持安装多个不同的 Linux 发行版，也支持同一家族的多个版本并存，比如 Ubuntu 22.04 和 Ubuntu 24.04。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com))

### 5.1 查看可安装的发行版

```powershell
wsl --list --online
```

### 5.2 安装 Ubuntu 22.04

```powershell
wsl --install -d Ubuntu-22.04
```

### 5.3 查看当前发行版列表

```powershell
wsl -l -v
```

示例：

```text
  NAME              STATE           VERSION
* Ubuntu-24.04      Running         2
  Ubuntu-22.04      Running         2
```

### 5.4 启动指定版本

启动 Ubuntu 22.04：

```powershell
wsl -d Ubuntu-22.04
```

启动 Ubuntu 24.04：

```powershell
wsl -d Ubuntu-24.04
```

### 5.5 设置默认发行版

如果你希望直接输入 `wsl` 时进入 Ubuntu 22.04，可以执行：

```powershell
wsl --set-default Ubuntu-22.04
```

这也是官方支持的标准做法。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/install?utm_source=chatgpt.com))

------

## 6. 代理问题说明

