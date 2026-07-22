---
title: "末端 RealSense 抓取视觉链路整理"
description: "梳理 WSL、Docker、ROS 2 与 RealSense 组成的末端抓取视觉开发链路。"
---

这段聊天本质上一直在做一件事：

**把你的 `Rc-Vision` 项目，从一个“还没真正落地的想法”，一步一步收拢成一个可以在 WSL + Docker + ROS2 里正式开发的工程骨架，服务于你当前的末端 D435i 抓取验证方案。**

我按阶段给你详细总结。

---

## 1. 先定开发路线，不让你一开始选错战场

一开始你在问的是：
你现在到底应该在

- Windows 原生写，
- WSL 里用 Docker 写验证方案，
- 还是直接在小电脑上写。

这个聊天先做的第一件事，就是帮你把**开发平台路线**定下来。

最后定的结论很明确：

- **主开发环境**：WSL + Docker
- **真机联调环境**：小电脑
- **Windows 原生**：只做辅助，不做主线

这个判断背后的核心逻辑是：

- 你现在首先要验证的是**视觉链路和工程结构**，不是最终部署
- Windows 原生环境不适合 ROS2 + RealSense + Docker 这套组合当主战场
- 直接在小电脑上写，会把“方案验证”和“硬件/环境踩坑”混在一起，调试成本太高
- WSL + Docker 最适合做第一阶段的软件架构验证

换句话说，这段聊天先帮你把**开发顺序**理清了：
**先把脑子写清楚，再去验证身体。**

---

## 2. 再定视觉方案，不让系统一上来就过度设计

你给出的比赛阶段方案是：

- D435i 装末端
- 举高识别题目
- 举高识别箱体
- 俯视做抓取
- 先验证这条链路是否够稳，不急着定终版

围绕这个目标，这段聊天又帮你做了第二件事：

**把末端 D435i 的角色重新讲清楚。**

不是一句“用 D435i 做末端识别”就完了，而是把它拆成一条真正能落地的链路：

**RGB 图像 → 检测目标 → 从深度图取深度 → 反投影成相机坐标系 3D 点 → 输出抓取目标消息**

同时明确区分了三类任务：

1. **末端抓取视觉**：重点是抓取点和三维定位
2. **题目识别**：重点是 OCR / 表达式识别和计算
3. **场景/箱体检测**：重点是类别识别和目标框输出

这个阶段里还做了一个非常关键的取舍：

- 第一阶段**不追求统一大模型**
- 也**不追求一上来做 6D 抓取**
- 而是坚持先做：
  - 2D 检测
  - 对齐深度取点
  - 反投影
  - 固定抓取姿态

也就是：
**先证明能稳定输出可用抓取点，再谈更聪明的系统。**

---

## 3. 然后开始搭开发环境，先把 Docker 跑通

你后面转到一个很具体的问题：

**Windows 上已经装了 Docker，WSL 里还要不要再装？**

这个阶段主要做的是**环境接入和权限修复**。

先判断出：

- 你不需要在 WSL 里再单独装一套 Docker Engine
- 你应该复用 **Docker Desktop + WSL Integration**

接着一步步排查：

1. 先看 WSL 里 `docker` 命令是否存在
2. 发现一开始命令不存在
3. 判断问题不是没装，而是 **Docker Desktop 没正确集成到 WSL**
4. 你修正设置后，WSL 里 `docker` 命令出现了
5. 接着出现 `permission denied while trying to connect to the docker API at unix:///var/run/docker.sock`

然后继续定位到：

- `/var/run/docker.sock` 属于 `docker` 组
- 但当前用户 `jj` 不在 `docker` 组里

于是又完成了这几步：

- 用 `sudo usermod -aG docker $USER` 把用户加入 docker 组
- 重新进入 shell / WSL
- 再次测试 `docker info`
- 最终跑通 `docker run hello-world`

也就是说，这一段聊天把你的 **WSL + Docker 基础环境**真正打通了。

---

## 4. 再处理代理、Conda 这些会影响开发体验但不是主线的问题

在 Docker 跑通后，你又问了两个很实际的问题：

### 4.1 Docker 要不要走 Clash 代理

这里主要做的是把代理层次拆清楚，不让你乱改：

- Docker Desktop 自己的代理
- WSL shell 自己的代理
- 容器内部命令的代理

通过你给出的信息，判断出：

- Docker Desktop 已经在走代理
- WSL shell 也有 `HTTP_PROXY/HTTPS_PROXY`
- 问题不是“有没有代理”，而是“已经有代理，但速度可能一般”

也提醒了你后面要注意：
容器内部不一定自动继承宿主机的代理环境。

### 4.2 Conda 的 `base` 会不会影响

这里给你的结论是：

- 对 Docker daemon 本身影响不大
- 但对后续 ROS2 / Python / shell PATH 有潜在污染

于是建议你关闭 `base` 自动激活：

```bash
conda config --set auto_activate_base false
```

这一步的目标很简单：

**让你的 WSL shell 尽量干净，不要让 Conda 干扰 ROS2 和 Docker 开发。**

---

## 5. 然后开始从“想法”切到“工程骨架”

接下来，聊天开始正式从“讨论方案”进入“搭工程”。

这里做了几件关键决策。

### 5.1 先不要上多容器

你问过一个很重要的问题：

- 三个任务是放一个 Docker 里，还是多个 Docker？

最后明确建议是：

- **第一阶段：一个 Docker 容器**
- **多个 ROS2 节点**
- 先别拆成多个容器

原因很务实：

- 你现在主要目标是把链路和接口跑通
- 多容器会立刻增加 DDS/ROS2 发现、网络、Compose、环境变量管理的复杂度
- 当前阶段收益远小于成本

也就是说，这里实际上帮你把**容器粒度**定下来了。

---

### 5.2 不再用随意的 Python 目录，而是转成 ROS2 工作空间

一开始你的目录是比较偏 Python 小工程的，比如：

- `app/`
- `data/`
- `docker/`
- `scripts/`

这段聊天明确指出：

**如果你要真正接 D435i、ROS2、抓取链路，这种目录不够了。**

于是开始给你设计 ROS2 工作空间骨架：

- `ros2_ws/src`
- `grasp_interfaces`
- `grasp_vision`
- `vision_bringup`

后来又扩展成：

- `rc_interfaces`
- `grasp_vision`
- `problem_recognition`
- `scene_detection`
- `vision_bringup`
- `robot_bridge`

也就是说，这段聊天把你的工程从“脚本堆”转向了**按职责拆分的 ROS2 package 工程**。

---

## 6. 再把“未来会做的任务”也预留到统一工程里

你后面又明确提出：

- 后面还要加入题目识别
- 还要加入 YOLO 图形/箱体检测
- 希望最终整合到同一个 Docker 里

这里做的事情，不是急着把功能写出来，而是先把**包划分原则**定下来。

最后形成的结构思想是：

- **`rc_interfaces`**：只放消息定义
- **`grasp_vision`**：只放末端抓取相关节点
- **`problem_recognition`**：只放题目识别相关节点
- **`scene_detection`**：只放场景 YOLO 检测节点
- **`vision_bringup`**：只放统一 launch
- **`robot_bridge`**：预留和电控/机械臂的桥接层

同时明确告诉你：

- 不要把题目识别和 YOLO 检测硬塞进 `grasp_vision`
- 一个 Docker ≠ 一个 package
- 正确做法是：**一个容器里可以有多个 ROS2 package 和多个 ROS2 node**

这一步非常重要，因为它决定了你后面工程会不会越来越乱。

---

## 7. 接着从零生成了完整项目目录：`Rc-Vision`

你后面明确说了：

**忘掉之前的目录结构，我现在什么都没有，请重新生成。**

于是这段聊天又给你重新生成了一份完整的新项目骨架，工程名统一为：

**`Rc-Vision`**

包含了：

- `docker/`
- `scripts/`
- `data/`
- `models/`
- `configs/`
- `docs/`
- `ros2_ws/src/...`

并且还给了你一整套 Bash 命令，让你可以在 WSL 里直接创建这整套目录和空文件。

这一步的本质，是把前面所有讨论过的架构决策，真正落成了一个**可执行的工程目录方案**。

---

## 8. 然后开始配置开发容器（Dev Container）

在工程目录确定之后，你又转到新的问题：

**因为现在是在 WSL 里开发，需要配开发容器配置文件，应该怎么配？**

这一阶段做的是：

- 明确推荐使用
  - `Dockerfile`
  - `docker-compose.yml`
  - `.devcontainer/devcontainer.json`
- 不推荐用乱七八糟的通用模板
- 对于 VS Code 里的模板选择，明确建议你选：
  - **`Existing Docker Compose (Extend)`**

随后又进一步帮你理解：

- 你不需要把 GitHub 上的 devcontainer 模板仓库整个搬进项目
- 你只需要在自己项目里新增 `.devcontainer/devcontainer.json`
- 然后让它指向你自己的 `docker/docker-compose.yml`

也就是说，这一段聊天把**开发容器如何和你自己的工程结合**说清楚了。

---

## 9. 再把开发容器从报错修到真正能用

你实际去用 VS Code Dev Containers 的时候，又遇到了几轮很关键的真实报错。

### 9.1 第一次失败：Dockerfile 空的

日志报错：

**`Dockerfile contains no FROM instructions`**

这里马上判断出：

- 不是 VS Code 插件坏了
- 不是 Docker 坏了
- 而是你项目里的 `docker/Dockerfile` 还没有写有效内容

于是我给了你一套最小可用版本：

- `docker/Dockerfile`
- `docker/docker-compose.yml`
- `docker/entrypoint.sh`
- `.devcontainer/devcontainer.json`

你按这个配置后，手动执行：

```bash
docker compose -f docker/docker-compose.yml build
```

成功 build 出镜像。

这一步说明：
**开发容器的构建问题解决了。**

---

### 9.2 第二次问题：容器能进，但 `ros2` 找不到

进容器后你验证到：

- `pwd` 正常
- Python 正常
- `ROS_DOMAIN_ID` 正常
- 但是 `ros2 --help` 报：
  - `bash: ros2: command not found`

这时又继续定位问题：

- 容器基础镜像明明是 `ros:humble-ros-base`
- ROS2 不可能真的没装
- 更可能是：`/opt/ros/humble/setup.bash` 没有自动 source 到交互 shell

你验证后果然发现：

```bash
source /opt/ros/humble/setup.bash && ros2 --help
```

是能用的。

于是又继续修：

- 在 `docker/Dockerfile` 中追加：
  - `source /opt/ros/humble/setup.bash`
  - 如果存在工作区 install 目录，也自动 source overlay

也就是把这些写进了 `/root/.bashrc`

然后重新 build、重新 Reopen in Container。

最后再验证：

```bash
which ros2
ros2 --help | head
```

看到：

- `which ros2` 指向 `/opt/ros/humble/bin/ros2`
- `ros2 --help` 正常输出

这一步意味着：
**你的 Dev Container 已经从“能进”变成了“真的能开发 ROS2”。**

---

## 10. 最后，开始真正进入工程主线：先做 `rc_interfaces`

到这里，整个聊天终于从“环境搭建”正式转向“开始写项目”。

我明确建议你的第一步不是先写检测节点，而是先写：

**`rc_interfaces`**

原因是：

- `grasp_vision`
- `problem_recognition`
- `scene_detection`
- `robot_bridge`

这几条线后面都会依赖统一消息格式
如果接口不先定下来，后面所有节点都会来回改，效率很低

于是给你设计了第一版接口文件：

- `Detection2D.msg`
- `Detection2DArray.msg`
- `GraspTarget.msg`
- `ProblemResult.msg`
- `SceneObject.msg`
- `SceneObjectArray.msg`

同时给了你：

- `package.xml`
- `CMakeLists.txt`

以及后续验证方法：

```bash
colcon build --symlink-install
source install/setup.bash
ros2 interface list | grep rc_interfaces
```

这一步其实就是把你从“环境搭建阶段”正式推进到了“ROS2 工程开发阶段”。

---

## 11. 这整段聊天最终完成了什么

如果要非常具体地总结，这段聊天完成了下面这些实事：

### 环境层面

- 选定了 WSL + Docker 作为第一阶段主开发环境
- 打通了 Docker Desktop 与 WSL 的集成
- 修复了 Docker socket 权限问题
- 排查并澄清了代理层配置情况
- 关闭了 Conda `base` 自动激活，避免污染开发环境
- 搭好了 VS Code Dev Container 所需的核心文件
- 修复了 Dockerfile 缺失、ROS2 未自动 source 等问题
- 最终让你在容器内成功拥有可用的 ROS2 Humble 环境

### 架构层面

- 明确了当前阶段用**单 Docker 容器 + 多 ROS2 节点**
- 不建议现在拆多容器
- 定下了按职责拆 package 的原则
- 区分了抓取视觉、题目识别、场景检测三类功能线
- 预留了 `robot_bridge` 作为对接机械臂/主控的桥接层

### 工程层面

- 从零生成了 `Rc-Vision` 的完整目录结构
- 给出了一键创建目录和空文件的 Bash 命令
- 明确了 `ros2_ws/src` 下各 package 的位置和职责
- 开始推进 `rc_interfaces` 作为整个项目的通信基础

---

## 12. 现在这段聊天进行到哪一步了

如果用一句话概括当前进度，就是：

**你已经完成了 `Rc-Vision` 的开发容器环境搭建，下一步应该正式开始写 `rc_interfaces`，再进入 `grasp_vision` 的最小节点骨架开发。**

也就是说，现在已经不是“该怎么配环境”阶段了，而是：

**可以开始真正写 ROS2 工程了。**

---

如果你愿意，我下一条可以继续把这个总结再进一步整理成一份：

**“Rc-Vision 当前阶段开发进度报告”**

格式会更像你能直接发给队友或自己留档的项目纪要。
