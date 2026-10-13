---
title: "进入虚拟机与端口转发记录"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "SSH"
  - "虚拟机"
---

```bash
powellshell

ssh -L 3390:192.168.122.95:3389 jackson@172.20.10.4

计算机：127.0.0.1:3390
用户名：jsh
```

## ** 第一步：在远程 Ubuntu (192.168.0.172) 上操作**

你需要先在 Ubuntu 上安装并开启 SSH 服务。

1. **打开终端**
   在 Ubuntu 桌面上右键选择“打开终端”，或者按 `Ctrl+Alt+T`。

2. **更新软件源并安装 SSH 服务**
   依次输入以下命令（输入密码时屏幕不会显示字符，输完回车即可）：

   bash

```text
   sudo apt update
   sudo apt install openssh-server -y
   ```

3. **检查服务状态**
   安装完成后，检查 SSH 是否正在运行：

   bash

```text
   sudo systemctl status ssh
   ```

   - **成功标志**：看到绿色的 **`active (running)`** 字样。
   - 如果显示 `inactive` 或 `failed`，请输入 `sudo systemctl start ssh` 手动启动。

4. **确认 IP 地址**
   虽然你已知 IP 是 `192.168.0.172`，但建议确认一下网卡状态，确保它是固定在这个网段的：

   bash

```text
   ip a
   ```

   找到类似 `ens33` 或 `eth0` 的网卡，确认 `inet` 后面是 `192.168.0.172`。

5. **配置防火墙（如果开启了 UFW）**
   Ubuntu 20 默认可能未开启防火墙，但如果开启过，需要放行 SSH 端口（默认 22）：

   bash

```text
   sudo ufw allow ssh
   ```

---

## ** 第二步：在本地电脑上连接**

回到你正在使用的本地电脑（Windows 或 Mac），发起连接。

1. **获取 Ubuntu 的用户名**
   你需要知道 Ubuntu 的登录用户名。如果不确定，可以在 Ubuntu 终端输入 `whoami` 查看。

   - 假设用户名是：`ubuntu_user`

2. **发起 SSH 连接**
   打开本地电脑的终端（Windows 下按 `Win+R` 输入 `cmd` 或 `powershell`）：

   bash

```text
   ssh ubuntu_user@192.168.0.172
   ```

3. **确认连接**

   - **第一次连接提示**：系统会提示 `Are you sure you want to continue connecting (yes/no/[fingerprint])?`
     - 输入 `yes` 并回车。
   - **输入密码**：提示 `password:` 时，输入 Ubuntu 用户的**登录密码**。
     - *注意：输入密码时屏幕上不会显示任何星号或字符，输完直接回车。*

---

## ** 常见问题排查**

如果连接失败，请检查以下几点：

表格

| 现象                     | 可能原因       | 解决方法                                                     |
| :----------------------- | :------------- | :----------------------------------------------------------- |
| **Connection refused**   | SSH 服务没启动 | 在 Ubuntu 上执行 `sudo systemctl start ssh`                  |
| **Connection timed out** | 防火墙拦截     | 检查 Ubuntu 的 `sudo ufw status`，确保允许了 SSH；或检查 Windows 防火墙是否阻止了局域网通信。 |
| **Permission denied**    | 密码或用户名错 | 确认用户名拼写正确，且密码是 Ubuntu 的**用户密码**（不是 sudo 密码，通常是一样的）。 |

## ** 进阶建议：配置免密登录**
