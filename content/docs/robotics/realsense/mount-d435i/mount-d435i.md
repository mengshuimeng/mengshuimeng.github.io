### 挂载摄像头D435i

[Intel RealSense SDK+WSL2+ROS2兼容性问题_wsl realsense-CSDN博客](https://blog.csdn.net/qq_33173089/article/details/146930744)

[elias-utf8/YOLOvsCustomCNN: Comparison of YOLOv11 and a custom CNN for 3D object detection and localization (orange cube, blue cylinder) with an Intel RealSense D435i camera.](https://github.com/elias-utf8/YOLOvsCustomCNN/tree/main)

[在Docker容器中的ROS 2环境中使用RealSense D435 - Blog - Silicon Cloud](https://www.silicloud.com/zh/blog/在docker容器中的ros-2环境中使用realsense-d435。/)

[format37/rover: Jetson nano ROS stepper 3d printed rover with servo head and realsence d435i camera](https://github.com/format37/rover)

[Ubuntu 22.04/ROS2 Humble下使用Intel RealSense D435i相机_ubuntu22.04安装realsense-CSDN博客](https://blog.csdn.net/m0_55260921/article/details/156764405)

Windows 宿主 -> WSL2 虚拟机 -> Docker 容器 的三层穿透。
#### 第一步：在 WSL2 中确认摄像头已识别

首先确保 WSL2 本身能看到摄像头。

1. 打开 WSL2 终端 (Ubuntu 22.04)。

2. 运行 `lsusb` 查看是否有 Intel 设备：

   ```bash
   lsusb
   ```

   - **如果有** `Intel Corp. RealSense...`：说明 WSL2 已经自动识别（较新版本的 WSL2 内核支持部分 UVC 设备直通）。继续下一步。
   - **如果没有**：说明 Windows 独占或 WSL2 未挂载。你需要安装 **USBIPD** (见下方的“特殊情况处理”)。

3. 检查 USB 总线设备节点：

   ```
   ls -l /dev/bus/usb
   ```

   如果这里有内容，说明底层驱动已加载。

##### **⚠️ 特殊情况处理：如果** `lsusb` **在 WSL2 里看不到摄像头**

#### **1. 在 Windows PowerShell (管理员) 中操作**

1. **安装 usbipd** (如果没装):

   ```
   winget install usbipd
   ```

   安装之后重新打开Windows PowerShell

2. **查找摄像头 BusID**:

   ```
   usbipd list
   ```

   找到 Intel RealSense D435I，记下它的 

   ```
   BUSID
   ```

   ```
   (base) PS C:\Users\32020> usbipd list
   Connected:
   BUSID  VID:PID    DEVICE                                                        STATE
   2-1    8086:0b3a  Intel(R) RealSense(TM) Depth Camera 435i Depth, Intel(R) ...  Not shared
   4-3    0489:e0f6  MediaTek Bluetooth Adapter                                    Not shared
   5-1    3277:0096  ASUS FHD webcam, ASUS IR camera, Camera DFU Device            Not shared
   7-2    046d:c53f  LIGHTSPEED Receiver, USB 输入设备                             Not shared
   7-4    046d:c548  Logitech USB Input Device, USB 输入设备                       Not shared
   
   Persisted:
   GUID                                  DEVICE
   
   ```

   

3. **绑定设备到 WSL**:

   ```
   usbipd bind --busid <BUSID>
   # 例如: usbipd bind --busid 2-1
   ```

4. **附加设备到 WSL**:

   ```
   usbipd attach --wsl --busid <BUSID>
   # 例如: usbipd attach --wsl --busid 2-1
   ```

#### **2. 回到 WSL2 终端**

再次运行 `lsusb`，现在应该能看到摄像头了。

```
jj@Jiang:~$ lsusb
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 002: ID 8086:0b3a Intel Corp. Intel(R) RealSense(TM) Depth Camera 435i
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

然后按照**第二步**重启 Docker 容器即可。





`docker/Dockerfile`

```
FROM ros:humble-ros-base

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    python3-opencv \
    python3-numpy \
    git \
    curl \
    wget \
    vim \
    nano \
    tree \
    usbutils \
    udev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    ros-humble-realsense2-camera \
    ros-humble-image-transport \
    ros-humble-image-view \
    ros-humble-cv-bridge \
    usbutils \
    v4l-utils \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc && \
echo 'if [ -f /workspaces/Rc-Vision/ros2_ws/install/setup.bash ]; then source /workspaces/Rc-Vision/ros2_ws/install/setup.bash; fi' >> /root/.bashrc


WORKDIR /workspaces/Rc-Vision

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash", "-lc", "sleep infinity"]

```

`docker/entrypoint.sh`

```
#!/usr/bin/env bash
set -e

source /opt/ros/humble/setup.bash

if [ -f /workspace/Rc-Vision/ros2_ws/install/setup.bash ]; then
    source /workspace/Rc-Vision/ros2_ws/install/setup.bash
fi

exec "$@"
```

`docker/docker-compose.yml`

```
services:
  rc_vision_dev:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    container_name: rc_vision_dev
    network_mode: host
    ipc: host
    privileged: true
    stdin_open: true
    tty: true
    working_dir: /workspaces/Rc-Vision
    volumes:
      - ..:/workspaces/Rc-Vision:cached
      - /dev:/dev
      - /dev/bus/usb:/dev/bus/usb
    tty: true
    stdin_open: true
    network_mode: host
    environment:
      - ROS_DOMAIN_ID=30
      - DISPLAY=${DISPLAY}
    command: /bin/bash -lc "sleep infinity"

```

`configs/realsense/d435i.yaml`

```
camera_namespace: camera
camera_name: camera

enable_color: true
enable_depth: true
enable_sync: true
align_depth.enable: true

rgb_camera.color_profile: 640x480x30
depth_module.depth_profile: 640x480x30

pointcloud.enable: false
enable_accel: false
enable_gyro: false
```

1







```bash
jj@Jiang:~$ docker compose -f docker/docker-compose.yml down
docker compose -f docker/docker-compose.yml up --build -d
open /home/jj/docker/docker-compose.yml: no such file or directory
open /home/jj/docker/docker-compose.yml: no such file or directory
jj@Jiang:~$ docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED          STATUS          PORTS     NAMES
63f4d166c7e2   docker-rc_vision_dev   "/entrypoint.sh /bin…"   18 minutes ago   Up 18 minutes             rc_vision_dev
jj@Jiang:~$ docker exec -it rc_vision_dev bash
root@docker-desktop:/workspaces/Rc-Vision# lsusb
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 003: ID 8086:0b3a Intel Corp. Intel(R) RealSense(TM) Depth Camera 435i
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
root@docker-desktop:/workspaces/Rc-Vision# source /opt/ros/humble/setup.bash

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
[INFO] [launch]: All log files can be found below /root/.ros/log/2026-03-14-11-11-42-505512-docker-desktop-6865
[INFO] [launch]: Default logging verbosity is set to INFO
[INFO] [launch.user]: 🚀 Launching as Normal ROS Node
[INFO] [realsense2_camera_node-1]: process started with pid [6866]
[realsense2_camera_node-1] [INFO] [1773486703.138654966] [camera.camera]: RealSense ROS v4.56.4
[realsense2_camera_node-1] [INFO] [1773486703.138894540] [camera.camera]: Built with LibRealSense v2.56.4
[realsense2_camera_node-1] [INFO] [1773486703.138926659] [camera.camera]: Running with LibRealSense v2.56.4
[realsense2_camera_node-1]  14/03 11:11:43,174 WARNING [136987428247104] (ds-motion-common.cpp:452) No HID info provided, IMU is disabled
[realsense2_camera_node-1]  14/03 11:11:43,178 ERROR [136987428247104] (rs.cpp:256) [rs2_create_device( info_list:0x7c96d80146a0, index:0 ) UNKNOWN] bad optional access
[realsense2_camera_node-1]  14/03 11:11:43,178 ERROR [136987428247104] (rs.cpp:256) [rs2_delete_device( device:nullptr ) UNKNOWN] null pointer passed for argument "device"
[realsense2_camera_node-1]  14/03 11:11:43,178 WARNING [136987428247104] (rs.cpp:392) null pointer passed for argument "device"
[realsense2_camera_node-1] [WARN] [1773486703.178464345] [camera.camera]: Device 1/1 failed with exception: bad optional access
[realsense2_camera_node-1] [ERROR] [1773486703.178550458] [camera.camera]: The requested device with  is NOT found. Will Try again.
```



```
```(base) PS C:\Users\32020> usbipd list
Connected:
BUSID  VID:PID    DEVICE                                                        STATE
2-1    8086:0b3a  Intel(R) RealSense(TM) Depth Camera 435i Depth, Intel(R) ...  Shared
4-2    046d:c53f  LIGHTSPEED Receiver, USB 输入设备                             Not shared
4-3    0489:e0f6  MediaTek Bluetooth Adapter                                    Not shared
5-1    3277:0096  ASUS FHD webcam, ASUS IR camera, Camera DFU Device            Not shared
7-4    046d:c548  Logitech USB Input Device, USB 输入设备                       Not shared

Persisted:
GUID                                  DEVICE

(base) PS C:\Users\32020> usbipd bind --busid 2-1
usbipd: info: Device with busid '2-1' was already shared.
(base) PS C:\Users\32020> usbipd attach --wsl --busid 2-1
usbipd: info: Using WSL distribution 'Ubuntu' to attach; the device will be available in all WSL 2 distributions.
usbipd: info: Detected networking mode 'mirrored'.
usbipd: info: Using IP address 127.0.0.1 to reach the host.
(base) PS C:\Users\32020>```     ```jj@Jiang:~$ lsusb
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 003: ID 8086:0b3a Intel Corp. Intel(R) RealSense(TM) Depth Camera 435i
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
jj@Jiang:~$ ```
```



```bash
jj@Jiang:~$ ls /dev/video* 2>/dev/null
ls /dev/media* 2>/dev/null
ls /dev/hidraw* 2>/dev/null
/dev/video0  /dev/video1  /dev/video2  /dev/video3  /dev/video4  /dev/video5
/dev/media0  /dev/media1
/dev/hidraw0
jj@Jiang:~$
```

```bash
在wsl里```jj@Jiang:~$ source /opt/ros/humble/setup.bash
ros2 pkg list | grep realsense
realsense2_camera
realsense2_camera_msgs
jj@Jiang:~$ source /opt/ros/humble/setup.bash

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
[INFO] [launch]: All log files can be found below /home/jj/.ros/log/2026-03-14-19-22-22-071705-Jiang-33905
[INFO] [launch]: Default logging verbosity is set to INFO
[INFO] [launch.user]: 🚀 Launching as Normal ROS Node
[INFO] [realsense2_camera_node-1]: process started with pid [33906]
[realsense2_camera_node-1] [INFO] [1773487342.675974311] [camera.camera]: RealSense ROS v4.56.4
[realsense2_camera_node-1] [INFO] [1773487342.676149500] [camera.camera]: Built with LibRealSense v2.56.4
[realsense2_camera_node-1] [INFO] [1773487342.676183738] [camera.camera]: Running with LibRealSense v2.56.4
[realsense2_camera_node-1]  14/03 19:22:22,701 WARNING [134319293093440] (ds-motion-common.cpp:452) No HID info provided, IMU is disabled
[realsense2_camera_node-1]  14/03 19:22:22,702 ERROR [134319293093440] (rs.cpp:256) [rs2_create_device( info_list:0x7a299c014780, index:0 ) UNKNOWN] bad optional access
[realsense2_camera_node-1]  14/03 19:22:22,702 ERROR [134319293093440] (rs.cpp:256) [rs2_delete_device( device:nullptr ) UNKNOWN] null pointer passed for argument "device"
[realsense2_camera_node-1]  14/03 19:22:22,702 WARNING [134319293093440] (rs.cpp:392) null pointer passed for argument "device"
[realsense2_camera_node-1] [WARN] [1773487342.702661532] [camera.camera]: Device 1/1 failed with exception: bad optional access
[realsense2_camera_node-1] [ERROR] [1773487342.702749782] [camera.camera]: The requested device with  is NOT found. Will Try again.```
```

