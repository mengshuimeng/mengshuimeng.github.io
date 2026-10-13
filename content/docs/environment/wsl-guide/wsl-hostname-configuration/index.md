---
title: "WSL 主机名修改记录"
date: 2026-09-15
authors:
  - "萌睡梦"
tags:
  - "WSL"
  - "Linux"
---

## 1. 修改目标

原始终端提示符：

```bash
jj@Jiang:~$
```

希望修改为：

```bash
jj@JiangShuhao:~$
```

最终决定：

- **保留 Linux 用户名：`jj`**
- **保留用户主目录：`/home/jj`**
- **仅修改 WSL 主机名 hostname：`Jiang` → `JiangShuhao`**

这样对现有项目、开发环境、Python、Node.js、Codex、OMX 等配置影响最小。

---

## 2. 原始 `/etc/wsl.conf`

修改前：

```ini
[boot]
systemd=true

[user]
default=jj
```

---

## 3. 修改 `/etc/wsl.conf`

在 WSL 中执行：

```bash
sudo nano /etc/wsl.conf
```

将内容修改为：

```ini
[boot]
systemd=true

[user]
default=jj

[network]
hostname=JiangShuhao
```

其中：

```ini
[user]
default=jj
```

保证 WSL 默认仍然使用原来的 `jj` 用户。

新增的：

```ini
[network]
hostname=JiangShuhao
```

用于设置新的主机名。

---

## 4. Nano 保存方法

在 `nano` 编辑器中：

```text
Ctrl + O
Enter
Ctrl + X
```

说明：

- `Ctrl + O`：保存文件
- `Enter`：确认文件名
- `Ctrl + X`：退出 nano

---

## 5. 检查配置

保存之后可以执行：

```bash
cat /etc/wsl.conf
```

预期内容：

```ini
[boot]
systemd=true

[user]
default=jj

[network]
hostname=JiangShuhao
```

---

## 6. 重启 WSL

先退出当前 WSL：

```bash
exit
```

然后在 Windows PowerShell 中执行：

```powershell
wsl --shutdown
```

重新进入：

```powershell
wsl
```

---

## 7. 修改结果

重新进入 WSL 后，终端提示符由：

```bash
jj@Jiang:~$
```

成功变为：

```bash
jj@JiangShuhao:~$
```

---

## 8. 验证

执行：

```bash
whoami
hostname
echo $HOME
```

实际结果：

```text
jj
JiangShuhao
/home/jj
```

说明：

| 检查项 | 修改前 | 修改后 |
|---|---|---|
| Linux 用户名 | `jj` | `jj` |
| hostname | `Jiang` | `JiangShuhao` |
| HOME | `/home/jj` | `/home/jj` |
| Shell 提示符 | `jj@Jiang:~$` | `jj@JiangShuhao:~$` |

最终状态正确。

---

## 9. 为什么不修改用户名

原本也考虑过：

```bash
jsh@JiangShuhao:~$
```

这需要将 Linux 用户从：

```text
jj
```

修改为：

```text
jsh
```

同时通常还需要修改：

```text
/home/jj
```

为：

```text
/home/jsh
```

这可能影响：

- shell 配置
- Python 虚拟环境
- npm / Node.js 配置
- Codex 配置
- OMX session
- 软件缓存
- 写死 `/home/jj/...` 的脚本
- PATH 环境变量
- SSH / Git 等本地配置

因此为了保证现有项目和开发环境稳定，最终选择：

> **只修改 hostname，不修改 Linux 用户名。**

---

## 10. 最终配置摘要

最终 `/etc/wsl.conf`：

```ini
[boot]
systemd=true

[user]
default=jj

[network]
hostname=JiangShuhao
```

最终终端：

```bash
jj@JiangShuhao:~$
```

最终环境：

```text
USER = jj
HOSTNAME = JiangShuhao
HOME = /home/jj
```

---

## 11. 恢复原主机名

如果以后想恢复成：

```bash
jj@Jiang:~$
```

只需要再次编辑：

```bash
sudo nano /etc/wsl.conf
```

将：

```ini
hostname=JiangShuhao
```

改回：

```ini
hostname=Jiang
```

然后执行：

```powershell
wsl --shutdown
```

重新进入 WSL 即可。

---

## 12. 结论

本次修改采用低风险方案：

```text
jj@Jiang
    ↓
jj@JiangShuhao
```

仅修改 WSL 主机名，不修改 Linux 用户、HOME 路径以及现有项目目录。

修改验证成功。
