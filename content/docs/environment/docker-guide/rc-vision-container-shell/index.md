---
title: "RC Vision 容器启动与环境验证"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "Docker"
  - "ROS 2"
---

进入docker

```bash
docker compose \
  --env-file docker/.env.cpu.example \
  -f docker/docker-compose.yml \
  --profile shell \
  run --rm shell
```

```bash

Container rc-vision-shell-run-87f7268809e1 Creating
Container rc-vision-shell-run-87f7268809e1 Created
root@docker-desktop:/workspace/Rc-Vision# python3 -c "import torch; print(torch.__version__)"
test -x /workspace/Rc-Vision/.venv_problem/bin/python && echo ok
ros2 pkg list | grep -E 'grasp_vision|problem_recognition|vision_bringup'
2.6.0+cpu
ok
grasp_vision
problem_recognition
vision_bringup
root@docker-desktop:/workspace/Rc-Vision# docker compose --env-file docker/.env.cpu.example -f docker/docker-compose.yml up grasp
docker compose --env-file docker/.env.cpu.example -f docker/docker-compose.yml up problem
docker compose --env-file docker/.env.cpu.example -f docker/docker-compose.yml up robotarm
bash: docker: command not found
bash: docker: command not found
bash: docker: command not found
root@docker-desktop:/workspace/Rc-Vision# exit
exit

jj@Jiang:~/projects/tmp/Rc-Vision$ docker compose --env-file docker/.env.cpu.example -f docker/docker-compose.yml up grasp
[+] up 1/1
 ✔ Container rc-vision-grasp-1 Created                                                                                                          0.1s
Attaching to grasp-1
grasp-1  | [INFO] [1775139923.363719300] [target_selector_node]: target_selector_node is ready.
grasp-1  | [INFO] [1775139923.640122152] [depth_projector_node]: depth_projector_node is ready.
grasp-1  | WARNING ⚠️ user config directory '/root/.config/Ultralytics' is not writable, using '/tmp/Ultralytics'. Set YOLO_CONFIG_DIR to override.
grasp-1  | Creating new Ultralytics Settings v0.0.6 file ✅
grasp-1  | View Ultralytics Settings with 'yolo settings' or at '/tmp/Ultralytics/settings.json'
grasp-1  | Update Settings with 'yolo settings key=value', i.e. 'yolo settings runs_dir=path/to/dir'. For help see https://docs.ultralytics.com/quickstart/#ultralytics-settings.
grasp-1  | [INFO] [1775139925.905790999] [detector_node]: Loading YOLO model: /workspace/Rc-Vision/models/yolo/grasp_detector.pt
grasp-1  | [INFO] [1775139925.994765125] [detector_node]: Model names: {0: '0', 1: '1', 2: '2', 3: '3'}
grasp-1  | [INFO] [1775139925.995123233] [detector_node]: detector_node is ready. image_topic=/camera/camera/color/image_raw, debug_image_topic=/grasp/debug_image, debug_publish_hz=15.0
Gracefully Stopping... press Ctrl+C again to force
Container rc-vision-grasp-1 Stopping
Container rc-vision-grasp-1 Stopped
grasp-1 exited with code 143
jj@Jiang:~/projects/tmp/Rc-Vision$ docker compose --env-file docker/.env.cpu.example -f docker/docker-compose.yml up grasp
Attaching to grasp-1
grasp-1  | [INFO] [1775140012.340007970] [target_selector_node]: target_selector_node is ready.
grasp-1  | [INFO] [1775140012.665971737] [depth_projector_node]: depth_projector_node is ready.
grasp-1  | [INFO] [1775140015.716449654] [detector_node]: Loading YOLO model: /workspace/Rc-Vision/models/yolo/grasp_detector.pt
grasp-1  | [INFO] [1775140015.858588719] [detector_node]: Model names: {0: '0', 1: '1', 2: '2', 3: '3'}
grasp-1  | [INFO] [1775140015.858975645] [detector_node]: detector_node is ready. image_topic=/camera/camera/color/image_raw, debug_image_topic=/grasp/debug_image, debug_publish_hz=15.0
Gracefully Stopping... press Ctrl+C again to force
Container rc-vision-grasp-1 Stopping
Container rc-vision-grasp-1 Stopped
grasp-1 exited with code 143
jj@Jiang:~/projects/tmp/Rc-Vision$
```

````bash
很明确了。
**新电脑现在最大的阻塞不是 GPU、不是 Ubuntu 20.04、也不是 Docker 版本，而是：当前用户没有权限访问 Docker daemon。**

你这里的关键信息是：

```bash
docker info
...
permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
```

以及：

```bash
docker ps
permission denied ...
```

这说明两件事：

1. **Docker 客户端已经装好了**

   * `docker --version` 正常
   * `docker compose version` 正常

2. **但是当前用户 `abc` 还不能访问 Docker 服务端**

   * 常见原因就是：**没有加入 `docker` 用户组**
   * 或者 Docker 服务没起来
   * 但从你这个报错看，**更像是权限问题，不像 daemon 根本没启动**

---

## 先说结论

你这台新电脑当前状态其实挺好：

* Ubuntu 20.04.6 正常
* RTX 4060 正常
* 驱动 570 正常
* 内存够
* 磁盘够
* Docker / Compose 都装好了

**唯一卡点是 Docker 权限。**

这个问题修完，你就可以继续走：

* `docker info`
* `docker ps`
* `docker run --rm --gpus all ... nvidia-smi`
* `docker compose ... build shell-gpu`

---

## 你现在先按这个顺序做

### 第一步：看 Docker 服务是否在运行

先执行：

```bash
sudo systemctl status docker --no-pager
```

你重点看有没有类似：

```bash
Active: active (running)
```

如果没启动，就先启动：

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

---

### 第二步：检查当前用户是否在 docker 组里

执行：

```bash
groups
```

看输出里有没有 `docker`。

如果**没有**，就执行：

```bash
sudo usermod -aG docker $USER
```

然后**必须重新登录一次**，或者至少执行：

```bash
newgrp docker
```

更稳的是：**退出当前终端，重新登录系统再开终端。**

---

### 第三步：重新验证

重新登录后执行：

```bash
docker info
docker ps
```

如果这时不再报 `permission denied`，说明权限已经通了。

---

## 我对你当前环境的判断

### 已经确认没问题的部分

* 系统：Ubuntu 20.04.6
* 显卡：RTX 4060 Laptop 8GB
* 驱动：570.133.20
* 驱动侧 CUDA：12.8
* Docker：28.1.1
* Compose：v2.35.1
* 内存：15Gi
* swap：17Gi
* 磁盘：足够

这些都说明：
**这台机器做你那个 Docker + Ubuntu22.04 + ROS2 Humble 封装，硬件和基础软件层面是够的。**

---

## 但我还是要提醒你一个点

你当前提示符还是：

```bash
(base) abc@abc-MIX:~/Rc-Vision$
```

说明你还在 conda base 环境里。
虽然 Docker 命令通常不太受这个影响，但从工程习惯上，我建议你后面跑 Docker / ROS2 / 系统级命令时，尽量先退出 base：

```bash
conda deactivate
```

因为你这台机器的 `python3` 还是：

```bash
Python 3.13.9
```

这说明系统环境确实被 conda 或别的路径覆盖过。
而你现在的目标是“宿主少动，主要靠容器”，那宿主机命令行最好尽量干净一点，别让 base 环境继续搅局。

---

## 最小修复方案

你现在就直接执行下面这组：

```bash
sudo systemctl status docker --no-pager
groups
sudo usermod -aG docker $USER
newgrp docker
docker info
docker ps
```

---

## 你要怎么理解这一步

这不是“大问题”，就是 Linux 上 Docker 很常见的首轮权限问题。
说白了就是：

> Docker 装上了，但当前普通用户还没拿到操作 `/var/run/docker.sock` 的权限。

修复成本不高，但**不修这个，后面所有 compose/build/gpu 测试都做不了**。

你把下面三条的输出发我：

```bash
sudo systemctl status docker --no-pager
groups
docker info
```

我就能继续往下判断你是不是已经可以做 **GPU 透传验证** 了。

````
