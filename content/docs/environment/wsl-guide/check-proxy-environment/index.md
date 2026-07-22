---
title: "检查 Ubuntu 与 WSL 的代理配置"
description: "从终端环境变量、系统配置和常用工具三个层面排查 Linux 代理设置。"
---

可以，分开看。你现在这台 Ubuntu 上，**代理可能配置在 4 个地方**：

## 1. 当前终端环境变量

先看你这个 shell 里有没有代理：

```bash
env | grep -i proxy
```

或者更直一点：

```bash
echo $HTTP_PROXY
echo $HTTPS_PROXY
echo $NO_PROXY
echo $ALL_PROXY
```

这只能说明**当前终端**有没有设置。

---

## 2. Docker daemon 代理

这是你现在最关键的。

### 看 systemd 里 Docker 服务吃到了什么环境变量

```bash
systemctl show --property=Environment docker
```

如果已经给 Docker daemon 配过代理，这里通常会看到：

- `HTTP_PROXY=...`
- `HTTPS_PROXY=...`
- `NO_PROXY=...`

### 看 Docker 的 systemd drop-in 配置文件

```bash
sudo cat /etc/systemd/system/docker.service.d/http-proxy.conf
```

如果你不确定文件名，也可以直接看整个目录：

```bash
ls -R /etc/systemd/system/docker.service.d
sudo grep -R -i proxy /etc/systemd/system/docker.service.d
```

---

## 3. Docker 客户端配置

Docker CLI 也可能单独配过代理。

看这个文件：

```bash
cat ~/.docker/config.json
```

或者专门搜一下：

```bash
grep -i proxy ~/.docker/config.json
```

如果配过，通常会在里面看到 `proxies` 字段。

---

## 4. 系统启动脚本里有没有写死代理

有些人会把代理写进 `~/.bashrc`、`~/.profile`、`/etc/environment`。

你可以一起搜：

```bash
grep -R -i proxy ~/.bashrc ~/.profile ~/.zshrc ~/.config/environment.d /etc/environment /etc/profile 2>/dev/null
```

---

## 我建议你现在直接跑这组

这组最实用：

```bash
env | grep -i proxy
systemctl show --property=Environment docker
sudo grep -R -i proxy /etc/systemd/system/docker.service.d 2>/dev/null
cat ~/.docker/config.json 2>/dev/null
grep -R -i proxy ~/.bashrc ~/.profile /etc/environment 2>/dev/null
```

---

## 怎么理解结果

你看到的代理大概会分成三类：

- **当前 shell 代理**：只影响你这个终端里的 `curl`、`pip`、`git`
- **Docker daemon 代理**：影响 `docker pull`
- **Docker CLI 配置代理**：影响 `docker build` / `docker run` 传给容器的环境变量

这三类经常不是同一个地方，所以别只看一个。

你把这组输出发我，我可以直接帮你判断：**哪些代理已经生效，哪些只是写了但没用上。*
