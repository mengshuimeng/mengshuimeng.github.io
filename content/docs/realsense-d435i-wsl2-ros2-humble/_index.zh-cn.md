---
title: Windows + WSL2 + Ubuntu 22.04 + ROS 2 Humble 运行 Intel RealSense D435i 维护记录
date: 2026-03-15
description: 记录在 Windows + WSL2 + Ubuntu 22.04 + ROS 2 Humble 环境下运行 Intel RealSense D435i 的配置、调试与维护过程
---

> 适用对象：需要在 **Windows 主机 + WSL2 Ubuntu 22.04 + ROS 2 Humble** 环境中运行 **Intel RealSense D435i** 的开发者。
> 本文基于一次完整排障过程整理，重点记录：**遇到了什么问题、为什么会出问题、最后怎么解决**。
> 说明：你问题里写的是 **Ubuntu 22.05**，实际应为 **Ubuntu 22.04**，因为 ROS 2 Humble 的官方目标平台是 Ubuntu 22.04。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/connect-usb))

------

## 1. 目标与最终结论

### 1.1 目标

在如下环境中让 D435i 能正常发布 ROS 2 图像与相机内参话题：

- Windows
- WSL2
- Ubuntu 22.04
- ROS 2 Humble
- Intel RealSense D435i

### 1.2 最终结论

这套环境**可以跑通**，但不是走 apt 安装的默认链路，而是要走下面这条路线：

1. 用 `usbipd-win` 把 D435i 挂到 WSL2。微软官方说明，WSL 连接 USB 设备需要通过 `usbipd-win`，不是原生直通。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/connect-usb))
2. **不要依赖 apt 版 `ros-humble-librealsense2` / `ros-humble-realsense2-camera` 作为最终方案**。
3. 改为：
   - **源码编译 `librealsense`**
   - **源码编译 `realsense-ros`**
4. `realsense-ros` 构建时显式指向 `/usr/local/lib/cmake/realsense2`。
5. 启动时**不要使用 `initial_reset:=true`**，因为在 WSL2 + usbipd 下，设备 reset 后很容易从 WSL 中脱离。`realsense-ros` 文档说明 `initial_reset` 的作用是“设备使用前先 reset”，它不是必选项。([GitHub](https://github.com/realsenseai/realsense-ros/blob/ros2-master/README.md))

### 1.3 当前状态

最终已经做到：

- `realsense2_camera` 节点能启动
- 能发布：
  - `/camera/camera/color/image_raw`
  - `/camera/camera/color/camera_info`
  - `/camera/camera/aligned_depth_to_color/image_raw`
  - 其他 depth/extrinsics 相关话题
- `camera_info` 可正常读取

这意味着 **D435i 在 WSL2 + Ubuntu 22.04 + ROS 2 Humble 下已经跑通**。

------

## 2. 环境说明

### 2.1 主机环境

- Windows
- 使用 WSL2
- Ubuntu 22.04
- ROS 2 Humble

### 2.2 相机

- Intel RealSense D435i

### 2.3 关键依赖

- `usbipd-win`
- `librealsense`（源码编译）
- `realsense-ros`（源码编译）

微软官方说明，WSL 使用 USB 设备的标准方案是安装 `usbipd-win`，并通过 `usbipd bind` / `usbipd attach --wsl` 将设备接入 WSL。WSL 内核版本需不低于 `5.10.60.1`。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/connect-usb))

------

## 3. 我们遇到的问题总览

这次排障并不是“一步成功”，而是连续踩了几层坑。按实际顺序，主要有以下问题：

### 3.1 容器里 `docker` 命令不可用

现象：

- 在容器里执行 `docker compose ...`
- 返回 `docker: command not found`

原因：

- `docker compose` 必须在**宿主机/WSL 外层**执行，不是在已经进入的容器内部执行。

结论：

- **容器管理命令在宿主机执行**
- **ROS 2 / 相机命令在容器或 WSL 内执行**

------

### 3.2 `realsense2_camera` 节点存在，但没有任何图像话题发布

现象：

- `ros2 node list` 能看到 `/camera/camera`
- 但 `/camera/camera/color/image_raw` 不发布

原因：

- 当时 WSL/容器里实际上还**没有真正拿到 D435i 设备**

------

### 3.3 容器和 WSL 里 `lsusb` 最初只能看到 root hub，看不到 D435i

现象：

- `lsusb` 只有 Linux Foundation root hub
- 没有 Intel RealSense 设备

原因：

- D435i 还没有通过 `usbipd-win` attach 到 WSL2

微软官方明确说明，WSL 默认不直接支持 USB，需要使用 `usbipd-win`。标准步骤是：

1. `usbipd list`
2. `usbipd bind --busid <BUSID>`
3. `usbipd attach --wsl --busid <BUSID>`
4. 在 WSL 中用 `lsusb` 验证([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/connect-usb))

------

### 3.4 设备接入 WSL 后，`realsense2_camera` 仍然报 `bad optional access`

现象：

- `lsusb` 已经能看到 `8086:0b3a`
- `/dev/video*`、`/dev/media*`、`/dev/hidraw*` 也都存在
- 但启动 `realsense2_camera` 报：
  - `bad optional access`
  - `The requested device ... is NOT found`

进一步验证时发现：

- 连 `rs-fw-update -l` 都同样报 `rs2_create_device(...) bad optional access`

结论：

- 这时已经能判断：**问题不在 ROS 2 launch 参数，而在底层 SDK / 运行库链路**

------

### 3.5 apt 版 RealSense 库链在 WSL2 下不稳定

现象：

- 使用 apt 安装的：
  - `ros-humble-librealsense2`
  - `ros-humble-realsense2-camera`
- 始终报 `bad optional access`

但改为源码编译后：

- `rs-enumerate-devices` 正常工作
- 能完整打印 D435i 的设备信息、流格式和固件版本

结论：

- 对当前这台机器而言，**apt 版 RealSense 链路不稳定**
- **源码编译 `librealsense` 才是有效方案**

------

### 3.6 `librealsense` 编译过程中 `cc1plus` 被 kill

现象：

- 编译到十几百分比时出现：
  - `c++: fatal error: Killed signal terminated program cc1plus`

原因：

- 开了太多构建项：
  - `BUILD_EXAMPLES=true`
  - `BUILD_GRAPHICAL_EXAMPLES=true`
- 并且使用了：
  - `make -j$(nproc)`
- WSL 分配内存有限，C++ 并行编译峰值内存冲高，导致编译器被系统杀掉

解决：

- 关闭不必要选项
- 改用最小构建
- 并行数降到 `-j2`

------

### 3.7 ROS 2 工作区构建时混入了 conda Python

现象：

- `colcon build` 日志里调用的是：
  - `/home/jj/miniconda3/envs/.../python3`
- 结果缺少 `em` 模块，`rosidl_adapter` 失败

原因：

- 终端虽然 `which python3` 显示 `/usr/bin/python3`
- 但构建环境仍受 conda 污染

解决：

- `conda deactivate`
- 清理 `PYTHONPATH` 等环境变量
- 安装系统包 `python3-empy`
- 用系统 Python 重新构建

------

### 3.8 `realsense2_camera` 找不到 `realsense2Config.cmake`

现象：

- `colcon build` 报：
  - `Could not find a package configuration file provided by "realsense2"`

原因：

- 虽然源码已经 `make` 完成，但 CMake 还不知道 SDK 的安装位置
- 需要让 `realsense-ros` 找到 `/usr/local/lib/cmake/realsense2/realsense2Config.cmake`

`librealsense` 的安装脚本明确会在 `make install` 时把：

- `realsense2Config.cmake`
- `realsense2Targets.cmake`
- `realsense2ConfigVersion.cmake`
  安装到 `${CMAKE_INSTALL_LIBDIR}/cmake/${LRS_TARGET}`，即典型的 `/usr/local/lib/cmake/realsense2`。([GitHub](https://github.com/IntelRealSense/librealsense/blob/master/CMake/install_config.cmake))

解决：

- 设置：
  - `export CMAKE_PREFIX_PATH=/usr/local:$CMAKE_PREFIX_PATH`
  - `export realsense2_DIR=/usr/local/lib/cmake/realsense2`
- 再用 `colcon` 构建 `realsense2_camera`

------

### 3.9 `realsense2_camera` 单独构建失败，缺少 `realsense2_camera_msgs`

现象：

- 单独 `--packages-select realsense2_camera` 时报缺少 `realsense2_camera_msgs/package.sh`

原因：

- 依赖包未构建到 install 空间

解决：

- 使用：
  - `colcon build --packages-up-to realsense2_camera`
- 连带依赖一起编译

------

### 3.10 `initial_reset:=true` 导致设备从 WSL 中掉线

现象：

- 日志中先显示找到了设备
- 然后执行 `Resetting device...`
- 紧接着变成 `No RealSense devices were found!`

原因：

- 在 WSL2 + usbipd 下，相机 reset 等同于一次断开重连
- 设备 reset 后会从 WSL 脱离，需要重新 attach

`realsense-ros` README 说明 `initial_reset` 只是“设备之前未正确关闭时可尝试”，并非必须参数。([GitHub](https://github.com/realsenseai/realsense-ros/blob/ros2-master/README.md))

解决：

- 启动时**去掉 `initial_reset:=true`**

------

### 3.11 ROS 2 CLI daemon 卡住，`ros2 node list` 超时

现象：

- `ros2 launch` 那边显示 `RealSense Node Is Up!`
- 但另一个终端里：
  - `ros2 node list`
  - `ros2 topic list`
    可能卡住或超时

原因：

- ROS 2 CLI daemon 状态异常

解决：

- `ros2 daemon stop`
- `ros2 daemon start`
- 必要时改用不依赖 daemon 的验证方式

------

### 3.12 深度图在 WSL 中看起来和 Windows 原生 Viewer 不一样

现象：

- 主观感觉 WSL 中深度图和 Windows 原生下不一致

原因判断：

1. 当前链路被识别为 **USB 2.1**，日志已明确提示 `Reduced performance is expected`
2. ROS 2 中启用了：
   - `enable_sync`
   - `align_depth.enable`
   - 对齐后的 topic 与 Windows Viewer 展示可能并非同一配置
3. WSL2 + usbipd 不是 RealSense 的最佳运行环境

`realsense-ros` README 明确说明：

- `align_depth.enable` 用于对齐 depth 到 color
- `enable_sync` 用于让 librealsense 同步帧
- 同时启用 color 和 depth 才能得到 RGBD 对齐输出。([GitHub](https://github.com/realsenseai/realsense-ros/blob/ros2-master/README.md))

结论：

- 当前环境已经**可用**
- 但不建议把它当成最终深度质量的评估基准
- 最终比赛/部署环境仍推荐原生 Ubuntu 或 Jetson

------

## 4. 最终有效的解决方案

下面是最终验证有效的流程。

------

## 5. 可复用完整步骤

### 5.1 Windows 侧：安装并使用 `usbipd-win`

#### 1）安装

管理员 PowerShell：

```powershell
winget install --interactive --exact dorssel.usbipd-win
```

微软官方文档给出了这套安装方式。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/connect-usb))

#### 2）查看设备

```powershell
usbipd list
```

#### 3）共享设备

```powershell
usbipd bind --busid <BUSID>
```

#### 4）附加到 WSL

```powershell
usbipd attach --wsl --busid <BUSID>
```

#### 5）WSL 中验证

```bash
lsusb
```

------

### 5.2 WSL 侧基础检查

#### 1）检查内核版本

```bash
uname -r
```

微软要求 WSL 内核至少为 `5.10.60.1`。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/connect-usb))

#### 2）检查设备节点

```bash
ls /dev/video* 2>/dev/null
ls /dev/media* 2>/dev/null
ls /dev/hidraw* 2>/dev/null
```

#### 3）确认 D435i 已进入 WSL

```bash
lsusb
```

应能看到类似：

```text
Intel Corp. Intel(R) RealSense(TM) Depth Camera 435i
```

------

### 5.3 不再使用 apt 版 RealSense ROS 链路

先移除 apt 版相关包：

```bash
sudo apt remove -y 'ros-humble-realsense2-*' 'ros-humble-librealsense2*'
sudo apt purge -y 'ros-humble-realsense2-*' 'ros-humble-librealsense2*'
sudo apt autoremove -y
```

原因：

- 这套链路在当前 WSL2 环境下会触发 `bad optional access`

------

### 5.4 源码编译 `librealsense`

#### 1）安装依赖

```bash
sudo apt update
sudo apt install -y \
  git cmake build-essential pkg-config \
  libusb-1.0-0-dev libglfw3-dev libgtk-3-dev \
  libgl1-mesa-dev libglu1-mesa-dev \
  python3-dev python3-pip
```

#### 2）拉源码

```bash
cd ~
git clone https://github.com/IntelRealSense/librealsense.git
cd librealsense
```

#### 3）最小化构建

这里不要开 examples 和 graphical examples，减少编译压力。

```bash
sudo rm -rf build
mkdir build
cd build

cmake .. \
  -DFORCE_RSUSB_BACKEND=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_EXAMPLES=false \
  -DBUILD_GRAPHICAL_EXAMPLES=false
```

Intel 官方构建文档支持 `FORCE_RSUSB_BACKEND`。这一步的意义是让当前 WSL2 场景优先走源码 SDK 路线。([RealSense Developer Documentation](https://dev.realsenseai.com/docs/build-configuration))

#### 4）编译

```bash
make -j2
```

建议：

- 先用 `-j2`
- 不要直接 `-j$(nproc)`

#### 5）安装

```bash
sudo make install
sudo ldconfig
```

#### 6）验证 cmake config 已安装

```bash
find /usr/local -name 'realsense2Config.cmake' -o -name 'realsense2-config.cmake'
find /usr/local -name 'realsense2Targets.cmake'
```

`librealsense` 安装脚本会把这些文件安装到 `/usr/local/lib/cmake/realsense2` 一类路径。([GitHub](https://github.com/IntelRealSense/librealsense/blob/master/CMake/install_config.cmake))

#### 7）验证 SDK 已可正常访问设备

```bash
rs-enumerate-devices
```

如果能正常输出设备信息、固件版本和流配置，说明 SDK 层已经打通。

------

### 5.5 环境变量设置

把以下内容加入 `~/.bashrc`：

```bash
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=/usr/local:$CMAKE_PREFIX_PATH
export realsense2_DIR=/usr/local/lib/cmake/realsense2
```

然后：

```bash
source ~/.bashrc
```

作用：

- 让运行时优先找到 `/usr/local/lib` 中的源码版 `librealsense`
- 让 `realsense-ros` 的 CMake 能找到 `realsense2Config.cmake`

------

### 5.6 处理 ROS 2 工作区中的 Python/conda 污染

如果机器装了 conda，建议在构建前执行：

```bash
conda deactivate 2>/dev/null || true
unset PYTHONPATH
unset AMENT_PYTHON_EXECUTABLE
unset COLCON_PYTHON_EXECUTABLE
hash -r
```

再确认：

```bash
which python3
python3 --version
```

目标应为：

```text
/usr/bin/python3
Python 3.10.x
```

------

### 5.7 初始化 rosdep

```bash
sudo rosdep init
rosdep update
```

如果已经初始化过，继续 `rosdep update` 即可。

------

### 5.8 安装 ROS 2 构建依赖

```bash
sudo apt update
sudo apt install -y \
  python3-empy \
  python3-colcon-common-extensions \
  python3-rosdep \
  python3-vcstool \
  python3-pip \
  python3-setuptools \
  python3-colcon-python-setup-py
```

------

### 5.9 源码编译 `realsense-ros`

#### 1）拉源码

```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src
git clone https://github.com/realsenseai/realsense-ros.git -b ros2-master
```

#### 2）安装依赖

`realsense-ros` 官方 README 说明，源码构建时可以跳过 `librealsense2`。([GitHub](https://github.com/realsenseai/realsense-ros/blob/ros2-master/README.md))

```bash
cd ~/ros2_ws
source /opt/ros/humble/setup.bash
rosdep install -i --from-path src --rosdistro humble --skip-keys=librealsense2 -y
```

#### 3）构建到 `realsense2_camera`

```bash
colcon build --symlink-install --packages-up-to realsense2_camera \
  --cmake-args -Drealsense2_DIR=/usr/local/lib/cmake/realsense2
```

这样会把依赖包如 `realsense2_camera_msgs` 一并构建。

------

### 5.10 启动相机节点

```bash
source /opt/ros/humble/setup.bash
source ~/ros2_ws/install/setup.bash

ros2 launch realsense2_camera rs_launch.py \
  camera_namespace:=camera \
  camera_name:=camera \
  enable_color:=true \
  enable_depth:=true \
  enable_sync:=true \
  align_depth.enable:=true \
  rgb_camera.color_profile:=640x480x30 \
  depth_module.depth_profile:=640x480x30 \
  pointcloud.enable:=false \
  enable_accel:=false \
  enable_gyro:=false
```

说明：

- `align_depth.enable`：对齐 depth 到 RGB。([GitHub](https://github.com/realsenseai/realsense-ros/blob/ros2-master/README.md))
- `enable_sync`：让 librealsense 同步 color/depth 帧。([GitHub](https://github.com/realsenseai/realsense-ros/blob/ros2-master/README.md))
- `enable_color` + `enable_depth`：同时启用两个传感器。([GitHub](https://github.com/realsenseai/realsense-ros/blob/ros2-master/README.md))
- **不要加 `initial_reset:=true`**，否则在 WSL2/usbipd 下可能让设备 reset 后脱离 WSL。([GitHub](https://github.com/realsenseai/realsense-ros/blob/ros2-master/README.md))

------

## 6. 验收方法

另开一个 WSL 终端：

```bash
source /opt/ros/humble/setup.bash
source ~/ros2_ws/install/setup.bash
```

### 6.1 查看节点

```bash
ros2 node list --no-daemon
```

应出现：

```text
/camera/camera
```

### 6.2 查看话题

```bash
ros2 topic list --no-daemon | grep camera
```

至少应看到：

```text
/camera/camera/color/image_raw
/camera/camera/color/camera_info
/camera/camera/aligned_depth_to_color/image_raw
/camera/camera/depth/image_rect_raw
```

### 6.3 查看内参

```bash
ros2 topic echo /camera/camera/color/camera_info --once
```

如果能拿到 `k`、`p`、`width`、`height` 等参数，说明相机内参发布正常。

------

## 7. 这次排障里最重要的经验

### 7.1 不要被“设备能被 `lsusb` 看到”迷惑

`lsusb` 能看到设备，只说明 USB 枚举成功。
不等于：

- SDK 一定能创建设备对象
- `realsense2_camera` 一定能正常启动

这次最大的坑就是：
**设备看得见，但 apt 版 SDK 仍然 `bad optional access`。**

------

### 7.2 在 WSL2 上，源码版 `librealsense` 比 apt 版更可靠

这次真正让系统跑通的关键，不是换 launch 参数，而是：

- 放弃 apt 版 RealSense ROS 链
- 改为源码编译 `librealsense`
- 再源码编译 `realsense-ros`

------

### 7.3 `initial_reset` 在 WSL2 里风险很大

在原生 Linux 上它可能只是 reset。
但在 WSL2 + usbipd 下，它可能直接让设备掉线。

------

### 7.4 如果日志显示 `Device USB type: 2.1`

就要默认认为当前不是理想状态。
即便能跑，也不建议把它当成最终深度质量基准。

------

### 7.5 Docker 不是这次的关键矛盾

这次已经证明：

- WSL 裸跑时也会复现底层 SDK 问题
- 所以 Docker 不是根因

对于 D435i 这种设备：

- **先在宿主环境打通**
- 再考虑容器化
  这是更务实的顺序。

------

## 8. 当前已知限制

### 8.1 USB 链路仍显示为 USB 2.1

日志提示：

- `Device USB type: 2.1`
- `Reduced performance is expected`

所以当前环境的深度流虽然可用，但并非最佳状态。

### 8.2 WSL2 更适合开发验证，不适合作为最终部署基准

如果项目后续进入：

- 抓取精度验证
- 比赛部署
- 长时间稳定运行

仍建议切换到：

- 原生 Ubuntu
- Jetson
- 机器人板载 Linux

------

## 9. 推荐的后续使用方式

### 日常启动命令

```bash
source /opt/ros/humble/setup.bash
source ~/ros2_ws/install/setup.bash

ros2 launch realsense2_camera rs_launch.py \
  camera_namespace:=camera \
  camera_name:=camera \
  enable_color:=true \
  enable_depth:=true \
  enable_sync:=true \
  align_depth.enable:=true \
  rgb_camera.color_profile:=640x480x30 \
  depth_module.depth_profile:=640x480x30 \
  pointcloud.enable:=false \
  enable_accel:=false \
  enable_gyro:=false
```

### 日常检查命令

```bash
ros2 node list --no-daemon
ros2 topic list --no-daemon | grep camera
ros2 topic echo /camera/camera/color/camera_info --once
```

------

## 10. 相关链接

### 官方文档

- Microsoft：WSL 连接 USB 设备
  https://learn.microsoft.com/en-us/windows/wsl/connect-usb ([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/connect-usb))
- Intel RealSense `realsense-ros` README
  https://github.com/realsenseai/realsense-ros/blob/ros2-master/README.md ([GitHub](https://github.com/realsenseai/realsense-ros/blob/ros2-master/README.md))
- Intel RealSense `librealsense` 安装配置脚本
  https://github.com/realsenseai/librealsense/blob/master/CMake/install_config.cmake ([GitHub](https://github.com/IntelRealSense/librealsense/blob/master/CMake/install_config.cmake))
- Intel RealSense 构建配置说明
  https://dev.realsenseai.com/docs/build-configuration ([RealSense Developer Documentation](https://dev.realsenseai.com/docs/build-configuration))
- Docker Desktop USB/IP 文档
  https://docs.docker.com/desktop/features/usbip/ ([Docker Documentation](https://docs.docker.com/desktop/features/usbip/))

### 相关项目

- YOLOvsCustomCNN
  https://github.com/elias-utf8/YOLOvsCustomCNN/tree/main

------

## 11. 一句话总结

这次真正有效的路线不是“apt 装完就跑”，而是：

**Windows 用 `usbipd-win` 把 D435i 接进 WSL2，WSL 里用源码版 `librealsense` 打通 SDK，再用源码版 `realsense-ros` 接到 ROS 2 Humble，启动时不要用 `initial_reset:=true`。**

------

如果你愿意，我下一步可以把这份内容再整理成**更正式的项目文档版**，比如：

- `docs/d435i_wsl2_setup.md`
- 带目录
- 带常见故障排查表
- 更适合直接放进 `Rc-Vision` 仓库。