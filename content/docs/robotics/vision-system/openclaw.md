以后你就把它当成一个 **WSL 里的后台服务** 用，思路很简单：

### 开启

进 WSL 的 Ubuntu，然后执行：

```
wsl -d Ubuntu
openclaw gateway start
```

或者你已经装了 systemd user service，也可以直接用：

```
wsl -d Ubuntu
systemctl --user start openclaw-gateway.service
```

OpenClaw 官方 CLI 里就有 `gateway start|stop|restart|status` 这些命令。

### 关闭

```
wsl -d Ubuntu
openclaw gateway stop
```

或者：

```
wsl -d Ubuntu
systemctl --user stop openclaw-gateway.service
```

### 重启

```
wsl -d Ubuntu
openclaw gateway restart
```

官方 FAQ 也专门提到，**Windows 用 WSL2 时**，关闭终端后要重新进 WSL，再执行 `openclaw gateway status` / `openclaw gateway restart`。

### 查看是否正在运行

```
wsl -d Ubuntu
openclaw gateway status
```

健康状态的关键是看到：

- `Runtime: running`
- `RPC probe: ok` 

### 打开控制台

```
wsl -d Ubuntu
openclaw dashboard
```

或者直接浏览器打开：

```
http://127.0.0.1:18789/
```

这是官方推荐的本地 Control UI 打开方式。

------

### 你这个环境下，最实用的日常用法

因为你已经把 service 装好了，平时基本只记这 4 条就够了：

```
wsl -d Ubuntu
openclaw gateway start
openclaw gateway stop
openclaw gateway restart
openclaw gateway status
```



### 启动

```
wsl -d Ubuntu
openclaw gateway start
```

### 查看状态

```
openclaw gateway status
```

### 打开面板

浏览器开：

```
http://127.0.0.1:18789/
```

或者：

```
openclaw dashboard
```

### 关闭

```
openclaw gateway stop
```

你现在已经不是“安装阶段”了，已经进入“使用阶段”。