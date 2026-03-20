# Ubuntu 22.04 Docker 安装与代理配置指南

> 本文档用于在 Ubuntu 22.04 / WSL Ubuntu 中安装 Docker，并完成基础验证、非 root 用户使用配置，以及代理设置。  
>
> 适用对象：需要使用容器环境进行开发、部署、实验的同学  
> 作者：姜树豪（JSH）  
> 更新时间：2026-03-09

---

## 目录

1. 安装前说明
2. 卸载旧版本 Docker
3. 安装 Docker
4. 验证安装
5. 配置非 root 用户使用 Docker
6. 配置 Docker 代理
7. 常用命令速查表

---

参考链接：[WSL 上的 Docker 容器入门 | Microsoft Learn](https://learn.microsoft.com/zh-cn/windows/wsl/tutorials/wsl-containers#install-docker-desktop)

## 1. 安装前说明

一般不需要在 WSL 里再单独下载一套 Docker Engine。通常做法是**Windows 装 Docker Desktop**，**WSL 里启用 Docker 集成**，然后直接在 WSL 终端里用 `docker` 命令。

你该怎么判断自己现在需不需要再装

在 **WSL 的 Ubuntu 终端** 里依次执行：

```shell
docker --version
docker info
docker run hello-world
```

如果这三步都正常，说明：

- Docker Desktop 已经接管了
- WSL 集成是通的
- **不需要**再在 WSL 里单独安装 Docker

---

## 2. 先决条件

- WSL 版本 1.1.3.0 或更高版本。

- Windows 11 [家庭版和专业](https://learn.microsoft.com/zh-cn/lifecycle/products/windows-11-home-and-pro)版、 [企业和教育](https://learn.microsoft.com/zh-cn/lifecycle/products/windows-11-enterprise-and-education)版、Windows 10 22H2（内部版本 19045）64 位 [家庭版和专业](https://learn.microsoft.com/zh-cn/lifecycle/products/windows-10-home-and-pro)版，或 [企业和教育](https://learn.microsoft.com/zh-cn/lifecycle/products/windows-10-enterprise-and-education) 版（推荐）。

  Windows 10 21H2（内部版本 19044）64 位 [家庭版和专业](https://learn.microsoft.com/zh-cn/lifecycle/products/windows-10-home-and-pro)版，或 [企业和教育](https://learn.microsoft.com/zh-cn/lifecycle/products/windows-10-enterprise-and-education) 版（最低）。 [更新 Windows](ms-settings:windowsupdate)

- 具有 [二级地址转换（SLAT）](https://en.wikipedia.org/wiki/Second_Level_Address_Translation)的 64 位处理器。

- 4GB 系统 RAM 或更高版本。

- 在 BIOS 中启用硬件虚拟化。

- [安装 WSL 并为在 WSL 2 中运行的 Linux 分发设置用户名和密码](https://learn.microsoft.com/zh-cn/windows/wsl/install)。

- [安装 Visual Studio Code](https://code.visualstudio.com/download)*（可选）。* 这将提供最佳体验，包括能够在远程 Docker 容器内编码和调试并连接到 Linux 分发版。

- [安装 Windows 终端](https://learn.microsoft.com/zh-cn/windows/terminal/get-started)*（可选）。* 这将提供最佳体验，包括在同一接口中自定义和打开多个终端（包括 Ubuntu、Debian、PowerShell、Azure CLI 或喜欢使用的任何终端）。

- [在 Docker 中心注册 Docker ID](https://hub.docker.com/signup)*（可选）。*

- 有关使用条款的更新，请参阅 [Docker Desktop 许可协议](https://docs.docker.com/subscription/#docker-desktop-license-agreement) 。

有关详细信息，请参阅 [在 Windows 上安装 Docker Desktop 的 Docker 文档系统要求](https://docs.docker.com/desktop/install/windows-install/)。

若要了解如何在 Windows Server 上安装 Docker，请参阅 [入门：为容器准备 Windows](https://learn.microsoft.com/zh-cn/virtualization/windowscontainers/quick-start/set-up-environment)。

------

## 3. 安装 Docker Desktop

使用适用于 Windows 的 Docker Desktop 支持的 WSL 2 后端，可以在基于 Linux 的开发环境中工作并生成基于 Linux 的容器，同时使用 Visual Studio Code 进行代码编辑和调试，并在 Windows 上的 Microsoft Edge 浏览器中运行容器。

若要安装 Docker（安装 [WSL](https://learn.microsoft.com/zh-cn/windows/wsl/install) 后）：

1. 下载 [Docker Desktop](https://docs.docker.com/desktop/features/wsl/#turn-on-docker-desktop-wsl-2) 并按照安装说明进行操作。

2. 安装后，启动 Docker Desktop，然后从任务栏的隐藏图标菜单中选择 Docker 图标。 右键单击图标以显示 Docker 命令菜单，然后选择“设置”。![image-20260313233749676](./assets/image-20260313233749676.png)

3. 确保在**“设置**>”中选中“使用基于 WSL 2 的引擎”。![image-20260313233811795](./assets/image-20260313233811795.png)

4. 通过转到 **“设置**>**资源**>**WSL 集成**”，从要启用 Docker 集成的已安装 WSL 2 分发版中进行选择。![image-20260313234030203](./assets/image-20260313234030203.png)

5. 在 Windows 里把 WSL 关掉再进

   设置完以后，不要直接回 WSL 试。先在 **Windows PowerShell** 执行：

   ```
   wsl --shutdown
   ```

   然后重新打开你的 Ubuntu，再执行：

   ```
   docker --version
   docker info
   docker run hello-world
   ```

------

## 4. 验证安装

### 4.1 查看 Docker 版本

```bash
sudo docker --version
docker info
```

### 4.2 查看 Docker 服务状态

```bash
sudo systemctl status docker
```

### 4.3 运行测试镜像

```bash
sudo docker run hello-world
```

如果看到：

```text
Hello from Docker!
```

如果这三步都正常，说明：

- Docker Desktop 已经接管了
- WSL 集成是通的

------

## 5. 配置非 root 用户使用 Docker

默认情况下，Docker 命令通常需要加 `sudo`。
如果你希望当前用户直接执行 Docker 命令，可以这样配置：

### 5.1 创建 Docker 用户组

```bash
sudo groupadd docker
```

### 5.2 把当前用户加入 docker 组

```bash
sudo usermod -aG docker $USER
```

执行完后，再跑一次：

```
grep "^docker:" /etc/group
```

你应该能看到 `docker:` 那一行里有 `jj`。

### 5.3 让权限立即生效

做法 1：彻底一点

在 Windows 终端执行：

```
wsl --shutdown
```

然后重新打开 Ubuntu。

### 5.4 测试

```bash
groups
docker ps -a
docker info
docker run hello-world
```

### 注意

不要把下面这种命令写进 `~/.bashrc`：

```bash
groupadd -f docker
```

这不是正常的 shell 初始化操作，没有必要每次开终端都执行。

------

## 6. 配置 Docker 代理

如果你在国内网络环境下拉取镜像较慢，或者必须通过代理访问网络，可以配置 Docker 服务代理。

### 6.1 创建代理配置目录

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
```

### 6.2 编辑代理配置文件

```bash
sudo nano /etc/systemd/system/docker.service.d/http-proxy.conf
```

写入：

```ini
[Service]
Environment="HTTP_PROXY=http://宿主机IP:代理端口"
Environment="HTTPS_PROXY=http://宿主机IP:代理端口"
Environment="NO_PROXY=localhost,127.0.0.1"
```

保存并退出：

```text
Ctrl + O → Enter → Ctrl + X
```

### 6.3 重载并重启 Docker

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 6.4 验证代理是否生效

```bash
systemctl show --property=Environment docker
```

如果配置成功，你应该能看到类似输出：

```text
Environment=HTTP_PROXY=http://宿主机IP:代理端口 ...
```

### 6.5 测试拉取镜像

```bash
sudo docker pull hello-world
```

------

## 7. 常用命令速查表

| 操作             | 命令                      |
| ---------------- | ------------------------- |
| 查看 Docker 版本 | `docker version`          |
| 查看镜像         | `docker images`           |
| 查看运行中的容器 | `docker ps`               |
| 查看所有容器     | `docker ps -a`            |
| 停止容器         | `docker stop <container>` |
| 删除容器         | `docker rm <container>`   |
| 删除镜像         | `docker rmi <image>`      |
| 测试镜像运行     | `docker run hello-world`  |

------

## 总结

这一篇主要解决三件事：

1. 正确安装 Docker
2. 让普通用户可以直接执行 Docker 命令
3. 在需要时配置 Docker 代理

如果你只是想先把 Docker 装好，做到下面三步就够了：

1. 安装 Docker
2. 运行 `hello-world`
3. 把当前用户加入 `docker` 组







```shell
(base) jj@Jiang:~$ whoami
jj
(base) jj@Jiang:~$ ls -l /var/run/docker.sock
groups
srw-rw---- 1 root docker 0 Mar 13 23:20 /var/run/docker.sock
jj adm dialout cdrom floppy sudo audio dip video plugdev netdev
(base) jj@Jiang:~$ sudo usermod -aG docker $USER
[sudo] password for jj:
(base) jj@Jiang:~$ grep "^docker:" /etc/group
docker:x:1001:root,jj
(base) jj@Jiang:~$
[已退出进程，代码为 1 (0x00000001)]
现在可以使用Ctrl+D关闭此终端，或按 Enter 重新启动。
(base) jj@Jiang:~$ groups
docker info
docker run hello-world
jj adm dialout cdrom floppy sudo audio dip video plugdev netdev docker
Client:
 Version:    29.0.1
 Context:    default
 Debug Mode: false
 Plugins:
  ai: Docker AI Agent - Ask Gordon (Docker Inc.)
    Version:  v1.9.11
    Path:     /usr/local/lib/docker/cli-plugins/docker-ai
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.29.1-desktop.1
    Path:     /usr/local/lib/docker/cli-plugins/docker-buildx
  compose: Docker Compose (Docker Inc.)
    Version:  v2.40.3-desktop.1
    Path:     /usr/local/lib/docker/cli-plugins/docker-compose
  debug: Get a shell into any image or container (Docker Inc.)
    Version:  0.0.45
    Path:     /usr/local/lib/docker/cli-plugins/docker-debug
  desktop: Docker Desktop commands (Docker Inc.)
    Version:  v0.2.0
    Path:     /usr/local/lib/docker/cli-plugins/docker-desktop
  extension: Manages Docker extensions (Docker Inc.)
    Version:  v0.2.31
    Path:     /usr/local/lib/docker/cli-plugins/docker-extension
  init: Creates Docker-related starter files for your project (Docker Inc.)
    Version:  v1.4.0
    Path:     /usr/local/lib/docker/cli-plugins/docker-init
  mcp: Docker MCP Plugin (Docker Inc.)
    Version:  v0.28.0
    Path:     /usr/local/lib/docker/cli-plugins/docker-mcp
  model: Docker Model Runner (Docker Inc.)
    Version:  v1.0.0
    Path:     /usr/local/lib/docker/cli-plugins/docker-model
  offload: Docker Offload (Docker Inc.)
    Version:  v0.5.20
    Path:     /usr/local/lib/docker/cli-plugins/docker-offload
  pass: Docker Pass Secrets Manager Plugin (beta) (Docker Inc.)
    Version:  v0.0.11
    Path:     /usr/local/lib/docker/cli-plugins/docker-pass
  sandbox: Docker Sandbox (Docker Inc.)
    Version:  v0.6.0
    Path:     /usr/local/lib/docker/cli-plugins/docker-sandbox
  sbom: View the packaged-based Software Bill Of Materials (SBOM) for an image (Anchore Inc.)
    Version:  0.6.0
    Path:     /usr/local/lib/docker/cli-plugins/docker-sbom
  scout: Docker Scout (Docker Inc.)
    Version:  v1.18.3
    Path:     /usr/local/lib/docker/cli-plugins/docker-scout

Server:
 Containers: 4
  Running: 0
  Paused: 0
  Stopped: 4
 Images: 3
 Server Version: 29.0.1
 Storage Driver: overlayfs
  driver-type: io.containerd.snapshotter.v1
 Logging Driver: json-file
 Cgroup Driver: cgroupfs
 Cgroup Version: 2
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
 CDI spec directories:
  /etc/cdi
  /var/run/cdi
 Discovered Devices:
  cdi: docker.com/gpu=webgpu
 Swarm: inactive
 Runtimes: io.containerd.runc.v2 nvidia runc
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: fcd43222d6b07379a4be9786bda52438f0dd16a1
 runc version: v1.3.3-0-gd842d771
 init version: de40ad0
 Security Options:
  seccomp
   Profile: builtin
  cgroupns
 Kernel Version: 6.6.87.2-microsoft-standard-WSL2
 Operating System: Docker Desktop
 OSType: linux
 Architecture: x86_64
 CPUs: 32
 Total Memory: 7.363GiB
 Name: docker-desktop
 ID: a2f972f9-fe1a-43d1-95f7-c0aaffb99bfa
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 HTTP Proxy: http.docker.internal:3128
 HTTPS Proxy: http.docker.internal:3128
 No Proxy: hubproxy.docker.internal
 Labels:
  com.docker.desktop.address=unix:///var/run/docker-cli.sock
 Experimental: false
 Insecure Registries:
  hubproxy.docker.internal:5555
  ::1/128
  127.0.0.0/8
 Live Restore Enabled: false
 Firewall Backend: iptables


Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/

(base) jj@Jiang:~$
```

