---
title: 进入虚拟机与端口转发记录
description: 使用 SSH 和端口转发进入虚拟机的简短命令记录
---

```bash
powellshell

ssh -L 3390:192.168.122.95:3389 jackson@172.20.10.4

计算机：127.0.0.1:3390
用户名：jsh
```

