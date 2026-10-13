---
title: "题目识别模块与 ROS 2 集成记录"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "ROS 2"
  - "OCR"
  - "机器人视觉"
---

这个聊天主要是在帮你把 **Rc-Vision 项目里的 `problem_recognition` 题目识别功能包** 从“本地 PyCharm 脚本”一步步改造成“能接入 ROS2 + D435i + 主控触发”的工程化功能模块。下面是详细总结。

---

## 1. 这个聊天的核心目标

你的目标是把一个已经写好的基于：

- `pix2text`
- `latex2sympy2`
- OpenCV ROI 提取
- HSV / RGB 调参
- 单张图 OCR
- 文件夹批量 OCR

的本地 Python 脚本体系，接入到当前 Rc-Vision 工程中，形成一个新的 ROS2 功能包：

```text
problem_recognition
```

它要实现的功能是：

> 当机器狗/主控准备好识别题目时，主控发一条“准备好了/开始识别”的消息；视觉侧从 D435i 当前画面中抓取一帧，提取题目 ROI，调用 Pix2Text 识别公式，再用 latex2sympy2 解析答案，最后通过 ROS2 话题发布 `ProblemResult` 给主控或其他节点。

---

## 2. 一开始的设计思路

你最开始的思路是：

1. 摄像头采集一会视频；
2. 从视频中转图片；
3. 对图片做 ROI 提取；
4. 调用 OCR；
5. 输出识别结果。

我一开始给出的建议是：
不要真的录完整视频再拆帧，而是在 ROS2 节点中直接订阅相机图像流，按时间间隔抽帧识别。

最初规划的结构是：

```text
/camera/camera/color/image_raw
        ↓
problem_detector_node
        ↓
ROI 提取
        ↓
Pix2Text OCR
        ↓
latex2sympy2 解析
        ↓
/problem/result
/problem/debug_image
```

并给你设计了一个标准 ROS2 Python 包结构：

```text
problem_recognition/
├── package.xml
├── setup.py
├── setup.cfg
├── resource/
│   └── problem_recognition
└── problem_recognition/
    ├── __init__.py
    ├── roi_utils.py
    ├── ocr_utils.py
    ├── problem_detector_node.py
    └── problem_debug_node.py
```

---

## 3. 你现有本地脚本的职责划分

我们把你已有的 PyCharm 脚本重新拆分理解了一遍：

### `figure_hsv_detect`

用于查看图像点位的 HSV / RGB 值，主要是调参工具。

### `FindROI3`

用于寻找白色题目区域、轮廓检测、透视变换、裁剪 ROI。

### `integrate3`

用于单张图片识别，包含：

- 读图
- 找 ROI
- 预处理
- 调用 `Pix2Text`
- 清洗 LaTeX
- 调用 `latex2sympy2`
- 输出结果

### `simultaneously2`

用于一个文件夹里的批量图片识别，更适合离线验证。

### `test_p2t`

用于检查 `Pix2Text` 模型是否下载完成、环境是否能运行。

---

## 4. 依赖环境问题：为什么不能直接装进 ROS2 主环境

后来进入了最复杂的一段：环境依赖。

你先查看了 WSL 主环境：

```text
Python: 3.10.12
Torch: 2.10.0+cu128
CUDA available: True
OpenCV: 4.8.1
```

后来发现你的原始 `requirements.txt` 是从 Windows/conda 环境导出的，里面有类似：

```text
/C:/miniconda3/conda-bld/...
```

这样的本地路径，导致在 WSL 中执行：

```bash
python3 -m pip install -r requirements.txt
```

直接失败。

于是我们决定不再使用原始 `requirements.txt` 整体安装，而是只安装 `problem_recognition` 必须的核心依赖。

---

## 5. `pix2text` 安装过程中遇到的问题

你安装 `latex2sympy2` 成功了：

```text
latex2sympy2==1.9.1
```

但是安装 `pix2text==1.1.6` 的时候，pip 拉取了大量依赖：

- `cnocr`
- `cnstd`
- `onnxruntime`
- `optimum`
- `optimum-onnx`
- `rapidocr`
- `doclayout-yolo`
- `PyMuPDF`
- `transformers`
- `torch`
- `torchvision`
- `opencv-python-headless`
- `numpy`
- `antlr4-python3-runtime`

然后出现了几类冲突：

### 5.1 NumPy 冲突

`pix2text` 依赖链把 NumPy 升到了：

```text
numpy==2.2.6
```

但是 ROS2 Humble 的 `cv_bridge` 是按 NumPy 1.x 编译的。
于是 ROS2 主环境运行节点时爆出：

```text
A module that was compiled using NumPy 1.x cannot be run in NumPy 2.2.6
AttributeError: _ARRAY_API not found
```

这个问题后来通过卸载主环境里的用户态 NumPy 2.2.6，让系统回到：

```text
numpy==1.21.5
```

解决了，`cv_bridge` 恢复正常。

### 5.2 `antlr4-python3-runtime` 冲突

`latex2sympy2==1.9.1` 要求：

```text
antlr4-python3-runtime==4.7.2
```

但是 `pix2text` 依赖链会把它装成：

```text
antlr4-python3-runtime==4.9.3
```

于是出现：

```text
ANTLR runtime and generated code versions disagree: 4.9.3!=4.7.2
```

目前这个警告虽然存在，但 `latex2sympy2` 仍然能解析表达式，所以暂时作为非主矛盾处理。

### 5.3 `transformers` 冲突

你尝试过：

- `transformers==5.3.0`
- `transformers==4.57.2`
- `transformers==4.57.1`

在 WSL 主环境里，`pix2text` 曾经报：

```text
cannot import name 'Pix2StructForConditionalGeneration' from 'transformers'
```

后来你贴出了 PyCharm 成功环境的信息：

```text
D:\anaconda3\envs\new_p2t\python.exe
transformers: 4.57.1
numpy: 2.2.6
pix2text 能 import
```

这说明问题不是某个单独版本号，而是 Windows conda 环境和 WSL 系统 Python 环境的依赖树不同。

---

## 6. 为什么分出 `.venv_problem`

基于上面的依赖冲突，我们明确决定：

### 不把 `pix2text` 直接装进 ROS2 主环境

原因是：

- `pix2text` 会拉大量深度学习/OCR 依赖；
- 它会升级 NumPy；
- 它会改变 `antlr4`；
- 它可能影响 `transformers`、`optimum`；
- 它已经实际把 ROS2 的 `cv_bridge` 搞崩过。

所以我们新建了：

```text
~/projects/tmp/Rc-Vision/.venv_problem
```

专门用于 OCR。

它的职责是：

- 只运行 OCR worker；
- 只负责 `pix2text`、OpenCV、ONNX、OCR 模型；
- 不直接运行 ROS2 节点；
- 不 import `rclpy`；
- 不发布 ROS2 消息。

ROS2 主环境继续负责：

- D435i；
- `rclpy`；
- `cv_bridge`；
- `rc_interfaces`；
- ROS2 topic；
- `problem_detector_node`；
- `latex2sympy2` 解析；
- 发布 `/problem/result`。

---

## 7. 方案 B：ROS2 包装节点 + 独立 OCR worker

后来我们把架构改成了 **方案 B**：

```text
ROS2 主环境
  problem_detector_node
      ↓ subprocess / stdin-stdout
.venv_problem
  problem_ocr_worker.py / problem_ocr_worker_server.py
      ↓ JSON
ROS2 主环境
  发布 /problem/result
```

这样实现了环境隔离。

---

## 8. 第一版 worker：每次识别都重新启动

最开始的 worker 是：

```text
scripts/problem_ocr_worker.py
```

它是一个单次脚本：

```bash
python scripts/problem_ocr_worker.py image_path
```

输入一张图片路径，输出 JSON。

它能成功输出：

```json
{
  "valid": true,
  "latex_raw": "2 0 \\div1 \\ -1 4",
  "latex_clean": "20/1-14",
  "bbox": {
    "x_min": 880,
    "y_min": 148,
    "x_max": 1107,
    "y_max": 251
  },
  "remark": "ok"
}
```

这说明 OCR worker 本身跑通了。

但是问题是：

> 每次调用 worker 都要重新加载 `Pix2Text` 模型，太重，WSL 容易卡死。

---

## 9. 为什么改成触发式 + 常驻 worker

你反馈：
全链路启动时 WSL 崩溃，RViz2 卡，模型加载慢。

于是我们判断：

- 持续实时 OCR 不合理；
- 每次重新启动 OCR worker 不合理；
- RViz2 + D435i + OCR 对 WSL 压力太大；
- 更符合比赛流程的是主控触发式识别。

最终确定新流程：

```text
D435i 一直启动
problem_detector_node 一直缓存最新一帧
OCR worker 启动时预加载模型
主控发 /problem/trigger
problem_detector_node 取当前缓存帧
发送给常驻 worker
worker 返回 JSON
problem_detector_node 解析表达式
发布 /problem/result
```

---

## 10. 当前最终设计的文件结构

现在 `problem_recognition` 分两部分。

### 10.1 ROS2 功能包部分

路径：

```text
~/projects/tmp/Rc-Vision/ros2_ws/src/problem_recognition
```

建议结构：

```text
problem_recognition/
├── package.xml
├── setup.py
├── setup.cfg
├── resource/
│   └── problem_recognition
└── problem_recognition/
    ├── __init__.py
    └── problem_detector_node.py
```

### 10.2 OCR worker 部分

路径：

```text
~/projects/tmp/Rc-Vision/scripts/problem_ocr_worker_server.py
```

它不属于 ROS2 包内部，是独立 Python worker。

---

## 11. `problem_detector_node.py` 当前职责

它现在应该是一个触发式 ROS2 节点，职责如下：

### 订阅

#### 相机图像

```text
/camera/camera/color/image_raw
```

注意它要用：

```python
qos_profile_sensor_data
```

否则可能出现相机话题看得到，但 `image_callback()` 收不到图像的问题。

#### 主控触发

```text
/problem/trigger
```

类型：

```text
std_msgs/msg/Bool
```

当收到：

```yaml
data: true
```

就识别一次。

### 发布

#### 题目识别结果

```text
/problem/result
```

类型：

```text
rc_interfaces/msg/ProblemResult
```

#### 调试图像

```text
/problem/debug_image
```

类型：

```text
sensor_msgs/msg/Image
```

---

## 12. `ProblemResult.msg` 当前建议字段

我们给出的消息结构是：

```text
std_msgs/Header header
bool valid

string latex_raw
string latex_clean
string expression
string answer

int32 roi_x_min
int32 roi_y_min
int32 roi_x_max
int32 roi_y_max

string frame_id
string remark
```

含义：

- `valid`：最终解析是否有效；
- `latex_raw`：Pix2Text 原始输出；
- `latex_clean`：清洗后的 LaTeX；
- `expression`：sympy 表达式；
- `answer`：最终答案；
- `roi_x_min/y_min/x_max/y_max`：题目区域 ROI；
- `frame_id`：图像坐标系；
- `remark`：状态说明，比如 `ok`、`roi_not_found`、`parse_failed`。

---

## 13. ROS2 图发现问题：为什么必须用 Cyclone DDS

你一度遇到：

- 节点明明在跑；
- heartbeat 一直输出；
- 但 `ros2 node list` 看不到；
- `ros2 topic list` 看不到 `/problem/result`。

后来我们排查了：

- `ROS_DOMAIN_ID`
- `ROS_LOCALHOST_ONLY`
- `RMW_IMPLEMENTATION`
- 多播测试

多播测试是通的：

```text
Received from 192.168.0.27:46230: 'Hello World!'
```

但是默认 RMW 下 ROS graph 发现仍然异常。

最终切换到：

```bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_LOCALHOST_ONLY=1
export ROS_DOMAIN_ID=0
```

之后问题解决，可以看到：

```text
/problem_detector_node
/problem/debug_image
/problem/result
/camera/camera
/camera/camera/color/image_raw
...
```

所以现在结论是：

> 在你这个 WSL 场景下，后续所有 ROS2 终端都建议统一使用 Cyclone DDS。

---

## 14. D435i 相关问题

你在本聊天之前已经把 D435i 基本跑通了，但这次联调中又遇到：

```text
control_transfer returned error
Depth stream start failure
Hardware Error
```

我们判断这更像是：

- WSL + USB/IP 下 D435i 不稳定；
- 同时开 RGB、Depth、IMU 时负载较高；
- WSL 崩溃或重启后相机 USB 状态不干净；
- RealSense 节点启动时序问题。

建议处理方式是：

- 先单独启动相机；
- 不要和 OCR / RViz2 一起全开；
- 必要时先关 IMU；
- 或把帧率降到 15fps；
- 必要时重新 attach USB；
- 优先确认 `RealSense Node Is Up!`。

---

## 15. 当前已经解决的问题

这个聊天中已经解决或明确的问题包括：

### 已解决

1. `pix2text` 不适合装进 ROS2 主环境；
2. 创建 `.venv_problem` 隔离 OCR 依赖；
3. 单次 OCR worker 能识别图片并输出 JSON；
4. ROS2 主环境 `cv_bridge` 因 NumPy 2 崩溃的问题已恢复；
5. `problem_detector_node` 可以启动；
6. `/problem/result` 和 `/problem/debug_image` 可以在 Cyclone DDS 下被发现；
7. 明确了需要触发式识别，而不是持续实时识别；
8. 明确了主控触发话题 `/problem/trigger`；
9. 明确了图像订阅需要使用 `qos_profile_sensor_data`；
10. 明确了 `.venv_problem` 不能用于直接运行 ROS2 主节点。

---

## 16. 当前还在处理/未完全收尾的问题

### 16.1 `problem_recognition` 包注册偶尔异常

你遇到过：

```bash
ros2 pkg list | grep problem_recognition
```

为空，但之前又能 `ros2 run problem_recognition problem_detector_node`。

这说明包结构、build/install/source 状态需要继续稳定。

重点检查：

```text
resource/problem_recognition
setup.py
package.xml
setup.cfg
```

尤其是 `resource/problem_recognition` 必须存在，`setup.py` 必须安装它。

### 16.2 `No cached frame available yet`

你触发识别时出现：

```text
No cached frame available yet.
```

这说明 `problem_detector_node` 收到了 trigger，但还没有收到相机图像。
最可能原因是图像订阅 QoS 不匹配，需要改成：

```python
from rclpy.qos import qos_profile_sensor_data
```

然后：

```python
self.subscription = self.create_subscription(
    Image,
    self.image_topic,
    self.image_callback,
    qos_profile_sensor_data
)
```

同时建议在 `image_callback()` 里加日志：

```text
cached image #1: 640x480, frame_id=...
```

确认是否真正收到图像。

### 16.3 OCR 识别精度还没调优

当前 OCR 能输出结果，但不一定准。
之前单图输出：

```text
latex_raw = "2 0 \div1 \ -1 4"
latex_clean = "20/1-14"
```

说明：

- ROI 提取有效；
- OCR 能运行；
- 但清洗规则和识别精度还需要后续调。

### 16.4 `ANTLR runtime ...` 警告仍存在

现在这不是主矛盾。
功能可以跑，但环境不够干净。后续如果要彻底收尾，需要进一步处理。

---

## 17. 当前推荐的启动流程

### 终端 1：启动 D435i

```bash
cd ~/projects/tmp/Rc-Vision/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=/usr/local:$CMAKE_PREFIX_PATH
export realsense2_DIR=/usr/local/lib/cmake/realsense2

export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=1
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

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
  enable_accel:=true \
  enable_gyro:=true \
  unite_imu_method:=2
```

### 终端 2：启动 `problem_detector_node`

```bash
cd ~/projects/tmp/Rc-Vision/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash

export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=1
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

ros2 run problem_recognition problem_detector_node
```

预期日志：

```text
OCR worker preloaded and ready.
problem_detector_node is ready.
image_topic=/camera/camera/color/image_raw
trigger_topic=/problem/trigger
```

如果加了图像缓存日志，还应看到：

```text
cached image #1: 640x480, frame_id=camera_color_optical_frame
```

### 终端 3：触发识别

```bash
cd ~/projects/tmp/Rc-Vision/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash

export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=1
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

ros2 topic pub --once /problem/trigger std_msgs/msg/Bool "{data: true}"
```

### 终端 4：查看结果

```bash
cd ~/projects/tmp/Rc-Vision/ros2_ws
source /opt/ros/humble/setup.bash
source install/setup.bash

export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=1
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

ros2 topic echo /problem/result
```

---

## 18. 这个聊天目前做到的阶段

这个聊天已经完成了从：

> “我有一个本地 PyCharm 里的 OCR 脚本，不知道怎么接进 ROS2”

到：

> “设计出了独立 OCR 虚拟环境 + ROS2 包装节点 + 主控触发式题目识别流程”

的完整工程迁移方案。

目前最接近完成的版本是：

```text
D435i 持续启动
        ↓
problem_detector_node 缓存最新图像
        ↓
/problem/trigger 触发一次识别
        ↓
常驻 OCR worker 识别图片
        ↓
problem_detector_node 解析表达式
        ↓
/problem/result 发布结果
```

---

## 19. 最后一句话总结

这个聊天本质上是在帮你把 `problem_recognition` 从“离线脚本”改造成“ROS2 触发式题目识别功能包”，并且在过程中解决了依赖冲突、虚拟环境隔离、D435i 图像接入、ROS2 DDS 发现、相机 QoS、OCR worker 常驻化、主控触发机制、`ProblemResult` 消息设计等一整套工程问题。
