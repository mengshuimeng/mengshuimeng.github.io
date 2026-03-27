windows上

```
(base) PS C:\Users\32020> wsl --shutdown
(base) PS C:\Users\32020> usbipd list
Connected:
BUSID  VID:PID    DEVICE                                                        STATE
4-2    046d:c53f  LIGHTSPEED Receiver, USB 输入设备                             Not shared
4-3    0489:e0f6  MediaTek Bluetooth Adapter                                    Not shared
5-1    3277:0096  ASUS FHD webcam, ASUS IR camera, Camera DFU Device            Not shared
7-4    046d:c548  Logitech USB Input Device, USB 输入设备                       Not shared

Persisted:
GUID                                  DEVICE
beb64852-c032-424d-ab41-d3b1be8f86dc  Intel(R) RealSense(TM) Depth Camera 435i Depth, Intel(R) ...l

(base) PS C:\Users\32020> usbipd list
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
usbipd: info: Loading vhci_hcd module.
usbipd: info: Detected networking mode 'mirrored'.
usbipd: info: Using IP address 127.0.0.1 to reach the host.
(base) PS C:\Users\32020>
```

wsl上

```
jj@Jiang:~$ uname -r
6.6.87.2-microsoft-standard-WSL2
jj@Jiang:~$ lsusb
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 002: ID 8086:0b3a Intel Corp. Intel(R) RealSense(TM) Depth Camera 435i
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
jj@Jiang:~$ lsusb
ls /dev/video* 2>/dev/null
ls /dev/media* 2>/dev/null
ls /dev/hidraw* 2>/dev/null
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 002: ID 8086:0b3a Intel Corp. Intel(R) RealSense(TM) Depth Camera 435i
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
/dev/video0  /dev/video1  /dev/video2  /dev/video3  /dev/video4  /dev/video5
/dev/media0  /dev/media1
/dev/hidraw0
jj@Jiang:~$ sudo apt update
sudo apt install -y ros-humble-realsense2-camera ros-humble-realsense2-camera-msgs
[sudo] password for jj:
Hit:1 https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy InRelease
Get:2 https://mirrors.ustc.edu.cn/ros2/ubuntu jammy InRelease [4682 B]
Hit:3 https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy-updates InRelease
Hit:4 https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy-backports InRelease
Hit:5 https://mirrors.tuna.tsinghua.edu.cn/ubuntu jammy-security InRelease
Hit:6 https://librealsense.intel.com/Debian/apt-repo jammy InRelease
Fetched 4682 B in 1s (4436 B/s)
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
1 package can be upgraded. Run 'apt list --upgradable' to see it.
W: https://librealsense.intel.com/Debian/apt-repo/dists/jammy/InRelease: Key is stored in legacy trusted.gpg keyring (/etc/apt/trusted.gpg), see the DEPRECATION section in apt-key(8) for details.
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  ros-humble-diagnostic-updater ros-humble-librealsense2
The following NEW packages will be installed:
  ros-humble-diagnostic-updater ros-humble-librealsense2 ros-humble-realsense2-camera
  ros-humble-realsense2-camera-msgs
0 upgraded, 4 newly installed, 0 to remove and 1 not upgraded.
Need to get 7671 kB of archives.
After this operation, 36.8 MB of additional disk space will be used.
Get:1 https://mirrors.ustc.edu.cn/ros2/ubuntu jammy/main amd64 ros-humble-diagnostic-updater amd64 4.0.6-1jammy.20260217.053658 [100 kB]
Get:2 https://mirrors.ustc.edu.cn/ros2/ubuntu jammy/main amd64 ros-humble-librealsense2 amd64 2.56.4-1jammy.20260213.225907 [6955 kB]
Get:3 https://mirrors.ustc.edu.cn/ros2/ubuntu jammy/main amd64 ros-humble-realsense2-camera-msgs amd64 4.56.4-2jammy.20260217.041627 [146 kB]
Get:4 https://mirrors.ustc.edu.cn/ros2/ubuntu jammy/main amd64 ros-humble-realsense2-camera amd64 4.56.4-2jammy.20260219.024739 [469 kB]
Fetched 7671 kB in 1s (6906 kB/s)
Selecting previously unselected package ros-humble-diagnostic-updater.
(Reading database ... 157243 files and directories currently installed.)
Preparing to unpack .../ros-humble-diagnostic-updater_4.0.6-1jammy.20260217.053658_amd64.deb ...
Unpacking ros-humble-diagnostic-updater (4.0.6-1jammy.20260217.053658) ...
Selecting previously unselected package ros-humble-librealsense2.
Preparing to unpack .../ros-humble-librealsense2_2.56.4-1jammy.20260213.225907_amd64.deb ...
Unpacking ros-humble-librealsense2 (2.56.4-1jammy.20260213.225907) ...
Selecting previously unselected package ros-humble-realsense2-camera-msgs.
Preparing to unpack .../ros-humble-realsense2-camera-msgs_4.56.4-2jammy.20260217.041627_amd64.deb ...
Unpacking ros-humble-realsense2-camera-msgs (4.56.4-2jammy.20260217.041627) ...
Selecting previously unselected package ros-humble-realsense2-camera.
Preparing to unpack .../ros-humble-realsense2-camera_4.56.4-2jammy.20260219.024739_amd64.deb ...
Unpacking ros-humble-realsense2-camera (4.56.4-2jammy.20260219.024739) ...
Setting up ros-humble-realsense2-camera-msgs (4.56.4-2jammy.20260217.041627) ...
Setting up ros-humble-librealsense2 (2.56.4-1jammy.20260213.225907) ...
Setting up ros-humble-diagnostic-updater (4.0.6-1jammy.20260217.053658) ...
Setting up ros-humble-realsense2-camera (4.56.4-2jammy.20260219.024739) ...
Processing triggers for libc-bin (2.35-0ubuntu3.13) ...
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
[INFO] [launch]: All log files can be found below /home/jj/.ros/log/2026-03-14-21-55-23-674500-Jiang-1509
[INFO] [launch]: Default logging verbosity is set to INFO
[INFO] [launch.user]: 🚀 Launching as Normal ROS Node
[INFO] [realsense2_camera_node-1]: process started with pid [1510]
[realsense2_camera_node-1] [INFO] [1773496524.142079184] [camera.camera]: RealSense ROS v4.56.4
[realsense2_camera_node-1] [INFO] [1773496524.142268256] [camera.camera]: Built with LibRealSense v2.56.4
[realsense2_camera_node-1] [INFO] [1773496524.142296373] [camera.camera]: Running with LibRealSense v2.56.4
[realsense2_camera_node-1]  14/03 21:55:24,174 WARNING [138176231319104] (ds-motion-common.cpp:452) No HID info provided, IMU is disabled
[realsense2_camera_node-1]  14/03 21:55:24,175 ERROR [138176231319104] (rs.cpp:256) [rs2_create_device( info_list:0x7daba0019290, index:0 ) UNKNOWN] bad optional access
[realsense2_camera_node-1]  14/03 21:55:24,175 ERROR [138176231319104] (rs.cpp:256) [rs2_delete_device( device:nullptr ) UNKNOWN] null pointer passed for argument "device"
[realsense2_camera_node-1]  14/03 21:55:24,175 WARNING [138176231319104] (rs.cpp:392) null pointer passed for argument "device"
[realsense2_camera_node-1] [WARN] [1773496524.175174747] [camera.camera]: Device 1/1 failed with exception: bad optional access
[realsense2_camera_node-1] [ERROR] [1773496524.175261575] [camera.camera]: The requested device with  is NOT found. Will Try again.
[realsense2_camera_node-1]  14/03 21:55:30,261 WARNING [138176231319104] (ds-motion-common.cpp:452) No HID info provided, IMU is disabled
[realsense2_camera_node-1]  14/03 21:55:30,262 ERROR [138176231319104] (rs.cpp:256) [rs2_create_device( info_list:0x7daba00102a0, index:0 ) UNKNOWN] bad optional access
[realsense2_camera_node-1]  14/03 21:55:30,262 ERROR [138176231319104] (rs.cpp:256) [rs2_delete_device( device:nullptr ) UNKNOWN] null pointer passed for argument "device"
[realsense2_camera_node-1]  14/03 21:55:30,262 WARNING [138176231319104] (rs.cpp:392) null pointer passed for argument "device"
[realsense2_camera_node-1] [WARN] [1773496530.262716080] [camera.camera]: Device 1/1 failed with exception: bad optional access
[realsense2_camera_node-1] [ERROR] [1773496530.262816649] [camera.camera]: The requested device with  is NOT found. Will Try again.
^C[WARNING] [launch]: user interrupted with ctrl-c (SIGINT)
[realsense2_camera_node-1] [INFO] [1773496531.873766264] [rclcpp]: signal_handler(SIGINT/SIGTERM)
[ERROR] [realsense2_camera_node-1]: process[realsense2_camera_node-1] failed to terminate '5' seconds after receiving 'SIGINT', escalating to 'SIGTERM'
[INFO] [realsense2_camera_node-1]: sending signal 'SIGTERM' to process[realsense2_camera_node-1]
[realsense2_camera_node-1] [INFO] [1773496536.882273996] [rclcpp]: signal_handler(SIGINT/SIGTERM)
[INFO] [realsense2_camera_node-1]: process has finished cleanly [pid 1510]
jj@Jiang:~$
```





但是有一篇博客说可以解决，请你仔细看看，[Intel RealSense SDK+WSL2+ROS2兼容性问题_wsl realsense-CSDN博客](https://blog.csdn.net/qq_33173089/article/details/146930744)

