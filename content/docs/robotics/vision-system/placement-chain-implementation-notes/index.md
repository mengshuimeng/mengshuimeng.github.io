---
title: "机器人放置视觉链改造方案"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "ROS 2"
  - "YOLO"
  - "机器人视觉"
---

可以。下面这版是**可以直接发给 Codex 的分步改造指令**。我按你现在的要求收口：**以现有抓取链为模板，新增/改造放置链；不修改抓取链代码；放置区识别改为 YOLO-seg；主控决定放 slot1 还是 slot2。**

---

### 0. 总体目标

请基于当前 `Rc-Vision` 仓库，以现有抓取链结构为参考，整理并改造放置链路。

当前抓取链大致是：

```text
/camera/camera/color/image_raw
-> grasp_vision/detector_node
-> /grasp/detections_2d
-> grasp_vision/target_selector_node
-> /grasp/selected_target_2d
-> RobotArm/depth_projector_node
-> /grasp/target_3d_camera
-> 机械臂执行
```

现在放置链要做成类似结构：

```text
/camera/camera/color/image_raw
-> placement_vision/placement_zone_node
-> /placement/zones_2d
-> placement_vision/place_target_selector_node
-> /placement/selected_place_zone_2d
-> placement_vision/placement_depth_projector_node
-> /placement/selected_place_target_3d
-> 机械臂放置执行
-> /placement/place_done
```

注意：

1. **不要修改抓取链代码。**
2. 不修改 `grasp_vision` 下现有抓取节点。
3. 不修改 `RobotArm/depth_projector_node.py` 的抓取逻辑。
4. 放置链新增自己的 `placement_depth_projector_node.py`。
5. 当前相机为固定俯视 D435i，放置链不需要 camera pose gating。现有 `configs/placement/placement_zone.yaml` 已经注明放置链使用固定俯视 RGB + aligned depth，不要添加相机姿态门控。
6. 当前 live 放置顺序由主控通过 `/master/place_pick_order` 指定，不由视觉自己判断先放 slot1 还是 slot2。`scripts/placement_run_pipeline.sh` 里也已经说明最终 live order 由主控通过 `/master/place_pick_order` 掌握。

---

## 1. 模型文件放置与命名

### 1.1 新增模型文件

请将放置区 YOLO-seg 模型放到：

```text
models/yolo/placement_zone_seg.pt
```

当前仓库已有抓取模型：

```text
models/yolo/grasp_detector.pt
```

结构里 `models/yolo` 已经存在，所以放置模型也放在这里，保持风格统一。

### 1.2 配置文件新增参数

修改：

```text
configs/placement/placement_zone.yaml
```

在 `placement_zone_node.ros__parameters` 下新增：

```yaml
model_path: /workspace/Rc-Vision/models/yolo/placement_zone_seg.pt
device: cuda
conf_threshold: 0.25
iou_threshold: 0.60
imgsz: 640
max_det: 4
half: false
```

保留原有的：

```yaml
color_topic: /camera/camera/color/image_raw
depth_topic: /camera/camera/aligned_depth_to_color/image_raw
camera_info_topic: /camera/camera/color/camera_info
zones_topic: /placement/zones_2d
debug_topic: /placement/debug_image
state_topic: /placement/zone_detection_state
debug_status_topic: /placement/debug_status
```

当前配置里这些话题已经存在，不要改名。

---

## 2. `placement_zone_node` 改造要求

### 2.1 文件位置

改造或重写：

```text
ros2_ws/src/placement_vision/placement_vision/placement_zone_node.py
```

### 2.2 节点定位

这个节点对标抓取链里的 `detector_node`。

但它识别的不是箱子，而是放置区。

### 2.3 输入话题

从参数读取，默认使用：

```text
/camera/camera/color/image_raw
/camera/camera/aligned_depth_to_color/image_raw
/camera/camera/color/camera_info
```

这些与当前 `placement_zone.yaml` 保持一致。

### 2.4 输出话题

发布：

```text
/placement/zones_2d
/placement/debug_image
/placement/zone_detection_state
/placement/debug_status
```

其中：

```text
/placement/zones_2d
```

类型使用：

```text
rc_interfaces/msg/PlacementZoneArray
```

该消息已经存在，里面包含 `PlacementZone[] zones`。

### 2.5 核心逻辑

原来的纯 CV 颜色阈值识别不要作为主链。
改成：

```text
RGB 图像
-> YOLO-seg 推理
-> 得到 placement_zone mask
-> 对每个 mask 做后处理
-> 输出 PlacementZone
```

具体流程：

```python
1. 订阅 RGB 图像
2. 使用 Ultralytics YOLO 加载 placement_zone_seg.pt
3. 对当前帧推理
4. 对每个 mask：
   4.1 转成二值 mask
   4.2 找最大轮廓
   4.3 面积过滤
   4.4 minAreaRect 或 approxPolyDP 拟合四边形
   4.5 计算 center_u / center_v
   4.6 对四边形做 safe_shrink
   4.7 得到 safe_center_u / safe_center_v
   4.8 生成 corners_uv 和 safe_corners_uv
   4.9 估计 confidence
5. 按图像 x 坐标排序
6. 给每个候选区生成 zone_id
7. 发布 PlacementZoneArray
8. 发布 debug_image
9. 发布 debug_status
```

### 2.6 `zone_id` 规则

因为当前训练的是单类 `placement_zone`，模型不区分颜色类别。
所以 `zone_id` 不来自模型类别，而来自**视野内排序或后续固定映射**。

建议先这样做：

```text
从左到右排序：zone_id = 0, 1, 2, 3
```

如果现场实际路径需要从右到左，可以通过参数控制：

```yaml
zone_sort_order: left_to_right
```

可选：

```text
left_to_right
right_to_left
```

不要把 slot 顺序和 zone 排序混在一起。
slot1/slot2 由主控决定；zone_id 只是当前放置区位置编号。

### 2.7 `color_name` 字段处理

当前 `PlacementZone.msg` 里有：

```text
int32 zone_id
string color_name
```

消息已经存在，不建议现在大改。

由于单类 seg 不识别颜色，`color_name` 可以这样填：

```text
"placement_zone"
```

或者：

```text
"unknown"
```

建议用：

```text
"placement_zone"
```

避免误导成真实颜色识别。

### 2.8 Debug 图要求

`/placement/debug_image` 必须画出：

- YOLO-seg mask 轮廓
- 外接四边形
- safe 四边形
- center 点
- safe_center 点
- zone_id
- confidence
- 如果深度本节点暂时不处理，也不要画 xyz

当前 RViz 配置里已经有 `/placement/debug_image` 显示项，所以继续沿用这个话题。

### 2.9 状态输出

`/placement/zone_detection_state` 使用 `std_msgs/msg/String`。

建议状态：

```text
WAIT_IMAGE
MODEL_LOADING
SEARCHING
TRACKING
NO_VALID_ZONE
INFERENCE_ERROR
```

`/placement/debug_status` 建议发 JSON 字符串，比如：

```json
{
  "node": "placement_zone_node",
  "model": "placement_zone_seg.pt",
  "num_zones": 4,
  "state": "TRACKING",
  "remark": "ok"
}
```

`fixed_topdown_debug_run.sh` 已经说明会 monitor `/grasp/debug_status` 和 `/placement/debug_status`，所以这个话题要保留。

---

## 3. 新增 `SelectedPlaceZone2D.msg`

为了让放置链更像抓取链，建议新增一个 2D selected 消息。

### 3.1 新增文件

在：

```text
ros2_ws/src/rc_interfaces/msg/
```

新增：

```text
SelectedPlaceZone2D.msg
```

### 3.2 消息内容

```text
std_msgs/Header header

bool valid

int32 slot_id
int32 box_type
int32 zone_id

string color_name
float32 confidence

float32 center_u
float32 center_v

float32 safe_center_u
float32 safe_center_v

float32[8] corners_uv
float32[8] safe_corners_uv

float32 area_px

string frame_id
string remark
```

### 3.3 字段说明

- `slot_id`：主控指定当前放哪个槽位，1 或 2
- `box_type`：该槽位当前箱子类型，来自 `/task/carried_boxes`
- `zone_id`：当前选中的放置区编号
- `safe_center_u/v`：用于深度投影的像素点
- `frame_id`：建议填 `camera_color_optical_frame`
- `remark`：错误或状态说明

### 3.4 更新 `CMakeLists.txt`

在 `rc_interfaces/CMakeLists.txt` 的 `rosidl_generate_interfaces(...)` 中加入：

```cmake
"msg/SelectedPlaceZone2D.msg"
```

当前 `rc_interfaces` 已经承担消息定义，已有 `PlacementZone`、`PlacementTarget`、`CarriedBoxState` 等消息，所以新增这个消息符合现有结构。

---

## 4. `place_target_selector_node` 改造要求

### 4.1 文件位置

改造：

```text
ros2_ws/src/placement_vision/placement_vision/place_target_selector_node.py
```

### 4.2 节点定位

这个节点对标抓取链里的 `target_selector_node`。

但注意：
**它不再判断先放第一个箱子还是第二个箱子。**

现在它只负责：

```text
主控指定 slot -> 查询 carried_boxes -> 找对应 zone -> 输出 selected_place_zone_2d
```

### 4.3 输入话题

从配置读取，默认：

```text
/task/carried_boxes
/placement/zones_2d
/master/place_order
/master/place_pick_order
/placement/place_done
```

这些在当前 `place_target_selector.yaml` 已经预留。

### 4.4 输出话题

新增：

```text
/placement/selected_place_zone_2d
```

类型：

```text
rc_interfaces/msg/SelectedPlaceZone2D
```

保留：

```text
/placement/current_place_plan
/placement/selector_state
```

其中 `/placement/current_place_plan` 只做 debug，不作为主控决策依据。`PlacePlan.msg` 里也已经说明它是视觉内部放置规划，不应作为主控最终 slot-order 决策来源，live slot order 来自 `/master/place_pick_order`。

### 4.5 `place_pick_order` 语义

`/master/place_pick_order` 建议使用 `std_msgs/msg/String`。

支持值：

```text
SLOT1
SLOT2
```

兼容旧值：

```text
FIRST
SECOND
FIRST_THEN_SECOND
SECOND_THEN_FIRST
```

但最终推荐统一成：

```text
SLOT1
SLOT2
```

### 4.6 selector 核心伪代码

```python
on_carried_boxes(msg):
    self.box_state = msg
    try_select()

on_zones(msg):
    self.zones = msg.zones
    try_select()

on_place_pick_order(msg):
    self.requested_slot = parse_slot(msg.data)
    try_select()

on_place_done(msg):
    # 这里只更新内部状态或触发重新选择
    # 真正 carried_boxes 的事实状态应由 vision_coordinator 或主控维护
    self.last_place_result = msg
    try_select()

try_select():
    if no requested_slot:
        publish_state("WAIT_MASTER_PLACE_PICK_ORDER")
        publish invalid SelectedPlaceZone2D
        return

    if no box_state:
        publish_state("WAIT_CARRIED_BOXES")
        return

    if requested_slot == 1:
        if not box_state.slot1_valid:
            publish_state("SLOT1_EMPTY")
            return
        if box_state.slot1_placed:
            publish_state("SLOT1_ALREADY_PLACED")
            return
        box_type = box_state.slot1_box_type

    if requested_slot == 2:
        if not box_state.slot2_valid:
            publish_state("SLOT2_EMPTY")
            return
        if box_state.slot2_placed:
            publish_state("SLOT2_ALREADY_PLACED")
            return
        box_type = box_state.slot2_box_type

    target_zone_id = map_box_type_to_zone_id(box_type)

    zone = find_zone_by_id(self.zones, target_zone_id)
    if zone is None:
        publish_state("WAIT_TARGET_ZONE")
        return

    selected = SelectedPlaceZone2D()
    selected.valid = True
    selected.slot_id = requested_slot
    selected.box_type = box_type
    selected.zone_id = zone.zone_id
    selected.color_name = zone.color_name
    selected.confidence = zone.confidence
    selected.center_u = zone.center_u
    selected.center_v = zone.center_v
    selected.safe_center_u = zone.safe_center_u
    selected.safe_center_v = zone.safe_center_v
    selected.corners_uv = zone.corners_uv
    selected.safe_corners_uv = zone.safe_corners_uv
    selected.area_px = zone.area_px
    selected.frame_id = "camera_color_optical_frame"
    selected.remark = "ok"

    publish selected to /placement/selected_place_zone_2d
    publish PlacePlan for debug
    publish_state("READY_2D")
```

### 4.7 映射关系

如果你们仍按箱子类型对应区域编号，则保留：

```python
BOX_FOOD = 0
BOX_TOOL = 1
BOX_INSTRUMENT = 2
BOX_MEDICINE = 3

BOX_TYPE_TO_ZONE_ID = {
    0: 0,
    1: 1,
    2: 2,
    3: 3,
}
```

如果实际现场不依赖颜色，只靠固定顺序，则这个映射仍然成立，但 `zone_id` 由 `placement_zone_node` 的排序结果给出。

### 4.8 状态输出

`/placement/selector_state` 使用 `std_msgs/msg/String`。

建议状态：

```text
WAIT_MASTER_PLACE_PICK_ORDER
WAIT_CARRIED_BOXES
WAIT_ZONES
WAIT_TARGET_ZONE
READY_2D
SLOT1_EMPTY
SLOT2_EMPTY
SLOT1_ALREADY_PLACED
SLOT2_ALREADY_PLACED
```

---

## 5. 新增 `placement_depth_projector_node.py`

### 5.1 文件位置

新增：

```text
ros2_ws/src/placement_vision/placement_vision/placement_depth_projector_node.py
```

### 5.2 节点定位

这个节点对标抓取链里的：

```text
RobotArm/depth_projector_node.py
```

当前抓取投影节点已经做了：

- 订阅深度图
- 订阅 CameraInfo
- 订阅 2D 目标
- 深度 ROI 中值
- 用相机内参反投影
- 发布 3D target。

放置投影节点照这个结构写，但输入输出消息换成放置侧。

### 5.3 输入话题

默认参数：

```yaml
depth_topic: /camera/camera/aligned_depth_to_color/image_raw
camera_info_topic: /camera/camera/color/camera_info
target_topic: /placement/selected_place_zone_2d
```

### 5.4 输出话题

```yaml
output_topic: /placement/selected_place_target_3d
```

类型：

```text
rc_interfaces/msg/PlacementTarget
```

这个消息已经存在。

### 5.5 参数

```yaml
roi_half_size: 3
min_depth_m: 0.08
max_depth_m: 2.0
enable_log: true
log_every_n: 1
```

和抓取投影节点参数风格保持一致。

### 5.6 投影逻辑

```python
target_callback(selected_2d):
    out = PlacementTarget()
    out.header = selected_2d.header
    out.zone_id = selected_2d.zone_id
    out.color_name = selected_2d.color_name
    out.target_box_type = selected_2d.box_type
    out.u = selected_2d.safe_center_u
    out.v = selected_2d.safe_center_v
    out.valid = False

    if depth_image unavailable:
        publish invalid
        return

    if camera_info unavailable:
        publish invalid
        return

    u = int(selected_2d.safe_center_u)
    v = int(selected_2d.safe_center_v)

    depth_m = median valid depth in roi around (u, v)

    if invalid:
        publish invalid
        return

    fx = camera_info.k[0]
    fy = camera_info.k[4]
    cx = camera_info.k[2]
    cy = camera_info.k[5]

    x = (u - cx) * depth_m / fx
    y = (v - cy) * depth_m / fy
    z = depth_m

    out.x = x
    out.y = y
    out.z = z
    out.valid = True
    out.confidence = selected_2d.confidence

    publish out
```

注意：

- `PlacementTarget` 字段叫 `x/y/z`，不是 `x_cam/y_cam/z_cam`。
- 不要复用 `GraspTarget`，放置侧用 `PlacementTarget`。

---

## 6. 更新配置文件

### 6.1 修改 `configs/placement/place_target_selector.yaml`

当前内容里已有这些参数。

建议改成：

```yaml
place_target_selector_node:
  ros__parameters:
    travel_order: asc
    place_pick_order: SLOT1

    boxes_topic: /task/carried_boxes
    zones_topic: /placement/zones_2d
    place_done_topic: /placement/place_done
    place_order_topic: /master/place_order
    place_pick_order_topic: /master/place_pick_order

    selected_zone_2d_topic: /placement/selected_place_zone_2d
    plan_topic: /placement/current_place_plan
    state_topic: /placement/selector_state
```

说明：

- `targets_topic: /placement/candidate_targets_3d` 可以暂时保留兼容，但新链路下 selector 不应该依赖 candidate 3D。
- 新链路由 `placement_depth_projector_node` 统一输出 `/placement/selected_place_target_3d`。

### 6.2 修改 `configs/placement/placement_zone.yaml`

保留原有相机话题、debug 话题。新增 YOLO-seg 参数：

```yaml
    model_path: /workspace/Rc-Vision/models/yolo/placement_zone_seg.pt
    device: cuda
    conf_threshold: 0.25
    iou_threshold: 0.60
    imgsz: 640
    max_det: 4
    half: false
    zone_sort_order: left_to_right
```

原有 HSV 参数可以暂时保留，但标注为 legacy fallback，不作为主识别路径。

### 6.3 新增配置文件可选

新增：

```text
configs/placement/placement_depth_projector.yaml
```

内容：

```yaml
placement_depth_projector_node:
  ros__parameters:
    depth_topic: /camera/camera/aligned_depth_to_color/image_raw
    camera_info_topic: /camera/camera/color/camera_info
    target_topic: /placement/selected_place_zone_2d
    output_topic: /placement/selected_place_target_3d

    roi_half_size: 3
    min_depth_m: 0.08
    max_depth_m: 2.0

    enable_log: true
    log_every_n: 1
```

---

## 7. 更新 launch 文件

### 7.1 修改或新增

检查：

```text
ros2_ws/src/vision_bringup/launch/placement_pipeline.launch.py
```

让它启动三个 placement 节点：

```text
placement_zone_node
place_target_selector_node
placement_depth_projector_node
```

### 7.2 参数输入

当前 `scripts/placement_run_pipeline.sh` 已经调用：

```text
ros2 launch vision_bringup placement_pipeline.launch.py
zone_config:=...
selector_config:=...
travel_order:=...
place_pick_order:=...
```

这个入口保留。

需要新增：

```text
projector_config:=/workspace/Rc-Vision/configs/placement/placement_depth_projector.yaml
```

如果不想改脚本，也可以在 launch 里给 projector 使用默认参数。

### 7.3 不要改动抓取 launch

不要改：

- `grasp_vision` 的 launch
- 抓取 detector
- 抓取 selector
- `RobotArm/depth_projector_node.py`

---

## 8. 更新 `setup.py` entry_points

检查：

```text
ros2_ws/src/placement_vision/setup.py
```

确保有：

```python
entry_points={
    'console_scripts': [
        'placement_zone_node = placement_vision.placement_zone_node:main',
        'place_target_selector_node = placement_vision.place_target_selector_node:main',
        'placement_depth_projector_node = placement_vision.placement_depth_projector_node:main',
    ],
},
```

---

## 9. Docker 和依赖检查

当前 Dockerfile 已经构建：

```text
rc_interfaces
grasp_vision
placement_vision
vision_coordinator
problem_recognition
vision_bringup
```

所以新增 placement 节点后仍在构建链里。

需要检查 `docker/requirements.runtime.txt` 里是否已有：

```text
ultralytics
```

如果没有，请添加。
但是不要引入和抓取链冲突的新依赖版本。

---

## 10. 机械臂执行对接

### 10.1 输出目标

放置链最终输出：

```text
/placement/selected_place_target_3d
```

类型：

```text
rc_interfaces/msg/PlacementTarget
```

### 10.2 机械臂执行侧

机械臂侧应订阅：

```text
/placement/selected_place_target_3d
```

执行完成后发布：

```text
/placement/place_done
```

类型：

```text
rc_interfaces/msg/PlaceExecutionResult
```

`PlaceExecutionResult.msg` 已有 `success/slot_id/box_type/zone_id` 字段，直接使用。

### 10.3 反馈桥

当前 `RobotArm/robotarm_feedback_bridge.py` 已经有放置反馈相关概念，并且有 `execute_place_target_topic`、`place_plan_topic`、`place_feedback_topic` 等参数。

可以在不改抓取行为的前提下，让放置执行侧接入：

```text
/placement/selected_place_target_3d
```

或通过桥接发布到：

```text
/vision/execute_place_target
```

但不要影响：

```text
/vision/execute_grasp_target
/grasp/target_3d_camera
```

---

## 11. 测试步骤

### 11.1 编译消息和节点

```bash
cd /workspace/Rc-Vision/ros2_ws
source /opt/ros/humble/setup.bash
colcon build --symlink-install --packages-select rc_interfaces placement_vision vision_bringup
source install/setup.bash
```

### 11.2 检查新消息

```bash
ros2 interface show rc_interfaces/msg/SelectedPlaceZone2D
ros2 interface show rc_interfaces/msg/PlacementZone
ros2 interface show rc_interfaces/msg/PlacementTarget
```

### 11.3 启动相机

```bash
bash scripts/launch_camera_imu.sh
```

这个脚本当前已经配置 D435i color + depth + align depth，并说明主流程是固定俯视。

### 11.4 启动放置链

```bash
bash scripts/placement_run_pipeline.sh
```

### 11.5 模拟主控消息

发布 carried boxes：

```bash
ros2 topic pub /task/carried_boxes rc_interfaces/msg/CarriedBoxState "{
  slot1_valid: true,
  slot1_box_type: 0,
  slot1_placed: false,
  slot2_valid: true,
  slot2_box_type: 2,
  slot2_placed: false
}" --once
```

发布主控选择 slot1：

```bash
ros2 topic pub /master/place_pick_order std_msgs/msg/String "{data: 'SLOT1'}" --once
```

检查：

```bash
ros2 topic echo /placement/zones_2d
ros2 topic echo /placement/selected_place_zone_2d
ros2 topic echo /placement/selected_place_target_3d
ros2 topic echo /placement/selector_state
```

再切 slot2：

```bash
ros2 topic pub /master/place_pick_order std_msgs/msg/String "{data: 'SLOT2'}" --once
```

---

## 12. 验收标准

### 12.1 放置区感知验收

`placement_zone_node` 应满足：

- 能加载 `models/yolo/placement_zone_seg.pt`
- `/placement/debug_image` 能画出 mask、四边形、safe center
- `/placement/zones_2d` 能发布 1~4 个候选区
- `safe_center_u/v` 落在放置区内部

### 12.2 selector 验收

`place_target_selector_node` 应满足：

- 未收到 `/master/place_pick_order` 时，不输出有效目标
- 收到 `SLOT1` 时，只解析 slot1
- 收到 `SLOT2` 时，只解析 slot2
- 不再根据 `travel_order` 自己决定先后
- `/placement/current_place_plan` 仅作 debug

### 12.3 projector 验收

`placement_depth_projector_node` 应满足：

- 收到 `/placement/selected_place_zone_2d`
- 能取 `safe_center_u/v` 附近深度中值
- 输出 `/placement/selected_place_target_3d`
- `PlacementTarget.valid = true`
- `x/y/z` 合理稳定

### 12.4 不破坏抓取链

验证：

```bash
ros2 pkg list | grep grasp_vision
ros2 pkg list | grep placement_vision
```

抓取链原有话题仍可用：

```text
/grasp/detections_2d
/grasp/selected_target_2d
/grasp/target_3d_camera
```

不要因为新增放置链而改坏这些话题。

---

## 13. 最终提交说明要求

Codex 完成后，请输出：

1. 修改了哪些文件
2. 新增了哪些文件
3. 是否新增了 `SelectedPlaceZone2D.msg`
4. `placement_zone_node` 是否已切换到 YOLO-seg
5. `place_target_selector_node` 是否已改为主控指令驱动
6. `placement_depth_projector_node` 是否已新增
7. 启动命令
8. 测试命令
9. 是否确认没有修改抓取链代码

---

## 一句话最终口径

这次改造不是重写系统，而是：

**在不动抓取链的前提下，新增一条与抓取链结构对称的放置链。放置链的 detector 换成 YOLO-seg，selector 改为接收主控 slot 指令，projector 单独新增 placement 版，最终输出 `/placement/selected_place_target_3d` 给机械臂。**
