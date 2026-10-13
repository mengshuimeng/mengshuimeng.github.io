---
title: "抖音聊天记录导出工具启动与关闭指南"
date: 2026-09-21
authors:
  - "萌睡梦"
tags:
  - "Docker"
  - "工具使用"
---

本文档适用于当前本机部署方式：

- 系统：Windows 11
- Docker：Docker Desktop
- 项目目录：`D:\Docker\douyin-chat-export`
- 控制面板：`http://localhost:8000/panel`
- 聊天浏览页面：`http://localhost:8000`

---

## 一、打开工具

### 1. 启动 Docker Desktop

先打开 **Docker Desktop**，等待 Docker Engine 启动完成。

可以在 PowerShell 中检查：

```powershell
docker info
```

如果能正常显示 `Server:` 信息，说明 Docker 已经启动。

---

### 2. 进入项目目录

打开 **Windows PowerShell**，执行：

```powershell
cd D:\Docker\douyin-chat-export
```

---

### 3. 启动抖音聊天导出工具

执行：

```powershell
docker compose up -d
```

其中：

- `up`：启动容器
- `-d`：后台运行，不占用当前 PowerShell 窗口

正常情况下会看到类似：

```text
Container douyin-chat-export Started
```

---

### 4. 检查运行状态

执行：

```powershell
docker compose ps
```

如果看到：

```text
STATUS
Up ...
```

并且端口类似：

```text
127.0.0.1:8000->8000/tcp
```

说明工具已经正常运行。

---

### 5. 打开网页

控制面板：

```text
http://localhost:8000/panel
```

聊天记录浏览页面：

```text
http://localhost:8000
```

---

## 二、关闭工具

### 方法 1：完整关闭（推荐）

先进入项目目录：

```powershell
cd D:\Docker\douyin-chat-export
```

然后执行：

```powershell
docker compose down
```

这会：

- 停止 `douyin-chat-export` 容器
- 删除本次 Compose 创建的容器
- 删除本次 Compose 创建的默认网络
- **不会删除聊天数据**

你的聊天数据仍然保存在：

```text
D:\Docker\douyin-chat-export\data
```

所以下次重新执行：

```powershell
docker compose up -d
```

即可恢复使用。

---

## 三、临时停止与恢复

如果只是暂时不用，不想删除容器，可以使用：

### 临时停止

```powershell
cd D:\Docker\douyin-chat-export
docker compose stop
```

### 恢复运行

```powershell
cd D:\Docker\douyin-chat-export
docker compose start
```

这种方式不会重新创建容器，启动速度通常更快。

---

## 四、重启工具

如果页面异常、采集卡住或修改了部分配置，可以执行：

```powershell
cd D:\Docker\douyin-chat-export
docker compose restart
```

然后检查：

```powershell
docker compose ps
```

---

## 五、查看运行状态

执行：

```powershell
cd D:\Docker\douyin-chat-export
docker compose ps
```

常见状态：

```text
Up
```

表示正在运行。

如果没有任何容器显示，通常说明已经执行过：

```powershell
docker compose down
```

---

## 六、查看日志

如果网页打不开、登录失败、采集失败，可以查看日志。

查看最近日志：

```powershell
cd D:\Docker\douyin-chat-export
docker compose logs --tail=100
```

实时查看日志：

```powershell
docker compose logs -f
```

退出实时日志：

```text
Ctrl + C
```

注意：

`Ctrl + C` 只是退出日志查看，不会停止后台运行的容器。

---

## 七、最常用命令速查

| 操作 | 命令 |
|---|---|
| 进入项目目录 | `cd D:\Docker\douyin-chat-export` |
| 启动 | `docker compose up -d` |
| 完整关闭 | `docker compose down` |
| 临时停止 | `docker compose stop` |
| 恢复运行 | `docker compose start` |
| 重启 | `docker compose restart` |
| 查看状态 | `docker compose ps` |
| 查看日志 | `docker compose logs --tail=100` |
| 实时日志 | `docker compose logs -f` |

---

## 八、日常推荐用法

### 每次打开

```powershell
cd D:\Docker\douyin-chat-export
docker compose up -d
docker compose ps
```

然后浏览器访问：

```text
http://localhost:8000/panel
```

---

### 每次关闭

```powershell
cd D:\Docker\douyin-chat-export
docker compose down
```

---

## 九、数据安全说明

当前 Docker Compose 使用的是：

```yaml
volumes:
  - ./data:/app/data
```

因此容器内的数据会映射到 Windows：

```text
D:\Docker\douyin-chat-export\data
```

正常执行下面这些命令：

```powershell
docker compose stop
docker compose down
docker compose restart
```

**都不会删除 `data` 目录中的聊天记录。**

不过仍建议定期备份：

```text
D:\Docker\douyin-chat-export\data
```

尤其是其中的：

```text
browser_profile
media
数据库文件
```

不要随意上传 `data` 目录到 GitHub、Gitee 或网盘公开分享，因为其中可能包含：

- 抖音登录状态
- Cookie / 会话信息
- 私信聊天记录
- 图片、语音、视频等媒体文件

---

## 十、如果 Docker Desktop 重启了怎么办

当前 `docker-compose.yml` 中配置了：

```yaml
restart: unless-stopped
```

因此在多数情况下，Docker Desktop 重新启动后，容器会自动恢复运行。

可以用下面的命令确认：

```powershell
cd D:\Docker\douyin-chat-export
docker compose ps
```

如果没有运行，再执行：

```powershell
docker compose up -d
```

即可。

---

## 十一、网页打不开时的快速排查

依次执行：

```powershell
cd D:\Docker\douyin-chat-export

docker compose ps

docker compose logs --tail=100
```

如果容器状态正常，再检查：

```text
http://127.0.0.1:8000/panel
```

如果仍然无法访问，可以重启：

```powershell
docker compose restart
```

然后重新访问：

```text
http://localhost:8000/panel
```

---

## 最简记忆版

### 打开

```powershell
cd D:\Docker\douyin-chat-export
docker compose up -d
```

访问：

```text
http://localhost:8000/panel
```

### 关闭

```powershell
cd D:\Docker\douyin-chat-export
docker compose down
```

聊天数据保存在：

```text
D:\Docker\douyin-chat-export\data
```

不会因为正常关闭容器而删除。
