---
title: "机器人放置区视觉识别流程"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "YOLO"
  - "ROS 2"
---

这段聊天主要是在帮你把**任务赛“放置区视觉链路”从想法变成可交给 Codex 改造的工程方案**。核心目标一直很明确：在不破坏现有抓取链的前提下，基于你们现在的 Rc-Vision 目录和 ROS2 架构，新增一条和抓取链结构类似的放置链。

下面我按时间顺序和技术主题详细总结。

---

## 1. 一开始我们明确了放置区任务到底要解决什么

你最初提出的问题是：放置区有 4 个颜色块，地面是黄色，总共五种颜色，视觉怎么区别，以及该用什么模型。

我一开始的判断是：

**放置区任务不是单纯颜色分类，而是“识别放置区 + 输出中心点/安全点 + 给机械臂执行”。**

所以我把它拆成两个任务：

1. **放置区种类/位置识别**
   - 看见哪个放置区
   - 得到放置区中心点
   - 得到边界和安全放置区域
2. **放置目标输出**
   - 把 2D 像素点通过深度相机转成 `(x, y, z)`
   - 传给机械臂

当时我建议过传统 CV 方案：HSV/Lab 颜色分割、轮廓筛选、四边形拟合、安全内缩中心。但你后来反馈纯 CV 受光照影响较大，容易调参数，这就推动了后面的模型方案切换。

---

## 2. 然后我们根据你们比赛策略重新定义了放置流程

你说明了你们的真实比赛策略：

- 机器马/机器狗路径由激光雷达走点位，路径写死
- 先到第一个箱子点位，识别箱子种类和位置，机械臂吸起来
- 再到第二个箱子点位，识别第二个箱子并拿起
- 后面一次经过放置区，顺路放两个箱子
- 摄像头一直朝下，看放置区
- 视觉要识别放置区并输出 `(x, y, z)`
- 后来你又更新：**到底先放 slot1 还是 slot2，不由视觉判断，而由主控发消息决定**

这个更新非常关键。我们因此把放置链的职责重新收缩成：

**主控决定“当前放哪个槽位”，视觉只负责“把这个槽位对应的放置目标找出来”。**

也就是说，视觉不再做“先放第一个箱子还是第二个箱子”的策略判断。

---

## 3. 我们先设计了传统版放置链节点

在你还没决定换模型之前，我们设计过两个节点：

### `placement_zone_node`

负责：

- 识别四个放置区
- 输出每个区的：
  - `zone_id`
  - `color_name`
  - `center_uv`
  - `corners_uv`
  - `safe_center_uv`
  - `confidence`
- 发布：
  - `/placement/zones_2d`
  - `/placement/debug_image`
  - `/placement/candidate_targets_3d`

### `place_target_selector_node`

负责：

- 读取两个已抓箱子的类别
- 结合放置区结果
- 原本根据路径方向 `asc/desc` 决定先放哪个
- 后来根据你的更新，改为**只读取主控命令，不做先后决策**

这个阶段我们还定义了很多消息字段，比如 `PlacementZone`、`PlacementTarget`、`CarriedBoxState`、`PlacePlan`、`PlaceExecutionResult`。

---

## 4. 后来你们决定训练 YOLO-seg，我帮你把方向从纯 CV 改成模型主识别

你说纯 CV 容易受光照影响，想换成 YOLO 或别的模型。

我的判断是：

**不要在纯 CV 和纯 YOLO 检测之间二选一，最适合的是 YOLO-seg 主识别 + CV 几何后处理。**

原因是：

- 你们要识别的是黄色背景上的放置区区域
- 不一定要识别颜色种类
- 最终目的是拿到稳定的中心点/安全中心点
- YOLO-seg 可以输出 mask，比普通检测框更适合后续四边形拟合和 safe center

所以我建议你们训练**单类 YOLO-seg**：

```text
placement_zone
```

而不是四类：

```text
green_zone
gray_zone
blue_zone
red_zone
```

原因是你们后面不一定依靠颜色语义，而是依靠固定位置、排序和主控逻辑。单类 seg 更简单、更稳、更少数据需求。

---

## 5. 我们详细讨论了 YOLO11 检测和 YOLO-seg 训练的区别

你问过：训练 YOLO11n 和训练 YOLO-seg 的过程是不是一样。

我解释了：

### 相同点

- 都是准备数据集
- 都写 `data.yaml`
- 都用 Ultralytics 训练
- 都看 `runs/` 结果
- 都导出 `.pt`

### 不同点

关键区别在标注：

#### YOLO 检测

标签是框：

```text
class_id x_center y_center width height
```

#### YOLO-seg

标签是多边形点：

```text
class_id x1 y1 x2 y2 x3 y3 ...
```

训练命令上则主要是：

```bash
yolo task=detect mode=train model=yolo11n.pt ...
```

和：

```bash
yolo task=segment mode=train model=yolo11n-seg.pt ...
```

的区别。

---

## 6. 我们制定了单类 YOLO-seg 的标注规范

你说数据采集好了，让我提出标注要求。

我建议：

### 类别只用一个

```text
placement_zone
```

### 标注要求

- 每个可见放置区单独标一个 polygon
- 贴真实外边界
- 4~8 个点即可
- 不要标黄色背景
- 不要故意往外扩
- 轻微遮挡可以标实际可见区域
- 严重模糊、过曝、边界不可辨的图不要进训练集
- 多人标注时标准必须统一

你还发了一条 YOLO-seg txt：

```text
0 0.2820060483870968 0.018369175627240115 ...
```

我判断它格式是对的：第一个 `0` 是类别，后面是四个归一化点。

你又发了标注截图，我指出：那张图 polygon 标得偏外，尤其上边和右边包进了背景，建议贴真实色块边缘，不要让模型学到“外面一圈也算目标”。

---

## 7. 你训练出 seg 模型后，我们评估了训练结果

你发了训练曲线图，我判断：

**训练结果很好，已经可以进入工程联调阶段。**

原因包括：

- train loss 和 val loss 都正常下降
- box、seg、cls、dfl 曲线健康
- mAP 很高
- Precision / Recall 都在高位
- 没看到明显过拟合

但我也提醒：
训练指标好，不代表比赛闭环已经完成。下一步应该重点看：

- 真实 D435i 朝下图像推理
- mask 是否贴边
- safe center 是否稳定
- 深度投影 `(x,y,z)` 是否抖动
- 机械臂落点是否压线

---

## 8. 我们讨论了最终落点应该用框中心、质心还是 safe center

你问：模型训练好了，应该用框中心还是质心？

我的结论是：

**不要直接用框中心。也不要直接用原始 mask 质心作为最终落点。最推荐：mask → 轮廓 → 四边形拟合 → safe shrink → safe 区域中心。**

原因：

- 框中心容易被外接矩形和背景拖偏
- 原始 mask 质心会受 mask 毛刺、缺角、边缘不稳定影响
- 放置任务怕压线，所以应该使用内缩后的安全中心

最终推荐下发给机械臂的是：

```text
safe_center_uv -> depth -> x,y,z
```

同时 debug 图里可以画：

- 框中心
- mask 质心
- 四边形中心
- safe center

方便对比。

---

## 9. 我们把放置链改造成“抓取链的镜像版”

你后来意识到：这其实和抓取链差不多，就是换了一个模型。

我确认了这个判断，并进一步整理：

### 抓取链抽象

```text
图像输入
-> 2D目标识别
-> 当前目标选择
-> 深度投影
-> 3D目标输出
-> 机械臂执行
```

### 放置链也一样

```text
图像输入
-> 2D放置区识别
-> 当前放置目标选择
-> 深度投影
-> 3D放置点输出
-> 机械臂执行
```

区别主要是：

1. 抓取链模型是箱子检测模型
2. 放置链模型是 YOLO-seg 放置区模型
3. 抓取链选择目标是抓取逻辑
4. 放置链当前放哪个槽位由主控 `/master/place_pick_order` 决定

所以我们把放置链规划成：

```text
/camera/camera/color/image_raw
-> placement_zone_node
-> /placement/zones_2d
-> place_target_selector_node
-> /placement/selected_place_zone_2d
-> placement_depth_projector_node
-> /placement/selected_place_target_3d
-> 机械臂放置
-> /placement/place_done
```

并强调：**不修改抓取链代码。**

---

## 10. 你上传了当前目录和文件，我结合实际仓库重新整理了方案

你上传了：

- `structure.txt`
- `src_all_files_export_no_realsense.txt`
- `scripts_content_export.txt`
- `msg_files_content.txt`
- `docker_content_export.txt`
- `configs_content_export.txt`

我结合这些文件确认了你们当前仓库状态：

### 已有目录和配置

- `configs/placement/placement_zone.yaml`
- `configs/placement/place_target_selector.yaml`
- `scripts/placement_run_pipeline.sh`
- `models/yolo/grasp_detector.pt`
- `ros2_ws/src/placement_vision`
- `ros2_ws/src/rc_interfaces/msg`

### 已有消息

包括：

- `PlacementZone.msg`
- `PlacementZoneArray.msg`
- `PlacementTarget.msg`
- `PlacementTargetArray.msg`
- `CarriedBoxState.msg`
- `PlacePlan.msg`
- `PlaceExecutionResult.msg`

### 抓取链参考

你们已有：

- `Detection2D`
- `Detection2DArray`
- `GraspTarget`
- `RobotArm/depth_projector_node.py`

我因此建议：
放置链不要复用抓取的 depth_projector，而是新增自己的：

```text
placement_depth_projector_node.py
```

这样抓取链完全不动，放置链独立发展。

---

## 11. 我们讨论并确定了放置区模型命名

你问放置区 `.pt` 文件叫什么好。

我建议：

```text
models/yolo/placement_zone_seg.pt
```

原因：

- `placement` 表示放置链
- `zone` 表示识别对象是放置区
- `seg` 表示这是分割模型
- 和已有 `grasp_detector.pt` 对应清楚

建议配置里增加：

```yaml
model_path: /workspace/Rc-Vision/models/yolo/placement_zone_seg.pt
device: cuda
conf_threshold: 0.25
iou_threshold: 0.60
imgsz: 640
```

---

## 12. 我最后给出了一版详细的 Codex 分步改造指令

你要求我给 Codex 详细分步改造指令，我给了一版很完整的实施清单。

核心内容包括：

### 0. 总目标

不改抓取链，新增放置链镜像结构。

### 1. 模型文件

新增：

```text
models/yolo/placement_zone_seg.pt
```

并在 `configs/placement/placement_zone.yaml` 加模型参数。

### 2. 改造 `placement_zone_node`

从纯 CV 改成：

```text
YOLO-seg 推理
-> mask
-> 轮廓
-> 四边形拟合
-> safe center
-> /placement/zones_2d
```

### 3. 新增 `SelectedPlaceZone2D.msg`

为了让放置链和抓取链一样有一层 selected 2D 目标：

```text
/placement/selected_place_zone_2d
```

字段包括：

- `slot_id`
- `box_type`
- `zone_id`
- `safe_center_u/v`
- `corners_uv`
- `safe_corners_uv`
- `confidence`
- `remark`

### 4. 改造 `place_target_selector_node`

改成主控驱动：

- 订阅 `/master/place_pick_order`
- 订阅 `/task/carried_boxes`
- 订阅 `/placement/zones_2d`
- 输出 `/placement/selected_place_zone_2d`

不再自己判断先放 slot1 还是 slot2。

### 5. 新增 `placement_depth_projector_node`

参考 `RobotArm/depth_projector_node.py`，但输入输出换成：

输入：

```text
/placement/selected_place_zone_2d
/camera/camera/aligned_depth_to_color/image_raw
/camera/camera/color/camera_info
```

输出：

```text
/placement/selected_place_target_3d
```

类型为 `PlacementTarget`。

### 6. 更新配置

- `placement_zone.yaml`
- `place_target_selector.yaml`
- 可新增 `placement_depth_projector.yaml`

### 7. 更新 launch

让 `vision_bringup/placement_pipeline.launch.py` 启动：

- `placement_zone_node`
- `place_target_selector_node`
- `placement_depth_projector_node`

### 8. 更新 setup.py

给 `placement_vision` 增加 entry point。

### 9. 检查 Docker 依赖

确认 `ultralytics` 在运行依赖中。

### 10. 测试流程

包括：

- build
- interface show
- 启动相机
- 启动放置链
- 模拟 `/task/carried_boxes`
- 模拟 `/master/place_pick_order`
- echo 相关话题

### 11. 验收标准

明确：

- 放置区识别能画 debug 图
- selector 等待主控指令
- projector 输出有效 3D
- 不破坏抓取链

---

## 13. 这段聊天最终形成的工程结论

现在整个方向已经很清楚了：

### 你们要做的不是重写系统

而是在现有 Rc-Vision 上新增一条独立放置链。

### 抓取链不动

已有抓取链继续保持：

```text
detector_node
-> target_selector_node
-> depth_projector_node
-> /grasp/target_3d_camera
```

### 放置链按镜像结构新增

```text
placement_zone_node
-> place_target_selector_node
-> placement_depth_projector_node
-> /placement/selected_place_target_3d
```

### 视觉职责更新

视觉不决定先放哪个箱子。
主控通过：

```text
/master/place_pick_order
```

告诉视觉当前放 `SLOT1` 还是 `SLOT2`。

### 放置区模型更新

放置区识别用：

```text
models/yolo/placement_zone_seg.pt
```

模型类别是单类：

```text
placement_zone
```

### 最终落点

不建议用框中心。
最终使用：

```text
YOLO-seg mask
-> 四边形拟合
-> safe shrink
-> safe_center
-> depth
-> x,y,z
```

---

## 14. 这段聊天的实际产出

到目前为止，这个聊天已经帮你产出了这些东西：

1. 放置区任务分析
2. 纯 CV 方案设计
3. 放置链 ROS2 节点设计
4. 7 个 `.msg` 初始模板
5. 主控决定 slot 的策略更新
6. YOLO-seg 方案切换建议
7. 单类 segmentation 数据集标注规范
8. 标注 txt 格式判断
9. 标注截图质量判断
10. 训练结果评估
11. 框中心/质心/safe center 选择建议
12. 放置链与抓取链同构分析
13. 结合当前仓库目录的节点职责和话题整理
14. 放置区模型命名建议
15. 可直接发给 Codex 的分步改造指令

一句话总结：

**这段聊天一直在围绕“把任务赛放箱子的视觉链路工程化”推进，从最初的颜色块识别方案，逐步收敛到现在的 YOLO-seg 放置区识别 + 主控 slot 指令 + 2D/3D 分离投影 + 机械臂执行的 ROS2 放置链设计。**
