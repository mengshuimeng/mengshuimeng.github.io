---
title: "RoboCon 任务赛视觉识别方案"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "RoboCon"
  - "机器人视觉"
---

可以。下面我把**这整个对话里做过的所有任务**，按阶段、按主题，给你做一份**详细完整的任务总表**。你可以把它当成这段对话的“项目工作纪要 + 路线图总结”。

---

## 一、这段对话的总目标是什么

这整个对话，本质上一直在做一件事：

**把你们任务赛视觉系统，从“想法和零散链路”一步步整理成“可落地、可联调、可实物测试”的完整方案。**

核心对象一直是：

- **任务赛视觉**
- **不是障碍赛**
- 围绕：
  - 题目识别
  - 抓取识别
  - 放置识别
  - 中控状态机
  - 总控接口
  - 机械臂执行反馈
  - 固定俯视调参与验收

---

## 二、最开始做的任务：明确比赛任务与视觉总体方案

这一阶段主要解决的是：**你们到底要做什么、视觉链路怎么分。**

### 1. 阅读和理解比赛任务

你一开始让我基于比赛规则，只关注**任务赛**，不要关注障碍赛。
我们把任务拆成了这些核心动作：

- 识别题目，得到答案
- 根据答案确定高分区逻辑
- 识别箱子类别
- 到点后抓取箱子
- 抓取两个箱子
- 再到放置区执行放置

### 2. 设计视觉技术方案

这一阶段做过的任务包括：

- 梳理任务赛的完整视觉工作流
- 分析机械臂、吸盘、相机、底盘之间的配合关系
- 讨论 ROS2 架构下该如何拆功能包和节点职责
- 讨论消息、话题、状态机、链路顺序

### 3. 讨论相机方案

你问过“末端抓取要不要深度相机”，我们比较了：

- 方案一：D435i + USB 摄像头
- 方案二：只用 USB 摄像头

最后逐步收敛成：

- **USB 摄像头负责题目识别**
- **D435i 固定俯视负责抓取和放置**
- D435i 不再承担题目识别主职责
- D435i 也不作为“抬头/低头切换”的相机

---

## 三、任务分解阶段：把视觉拆成五条链路

这一阶段，你已经明确提出视觉侧有五条链路，我们一起把它们不断细化。

### 这五条链路是：

#### 1. 题目识别与表达式链路

负责：

- 读题目图像
- OCR / 表达式解析
- 计算答案
- 输出题目识别摘要

#### 2. 物品种类 YOLO 识别箱子链路

负责：

- 识别当前箱子类别
- 输出检测框、类别、置信度
- 给抓取链提供目标信息

#### 3. D435i 末端抓取反馈链路

负责：

- 用 D435i 的 RGB + 深度
- 计算目标中心
- 输出相机坐标系下抓取目标 `(x,y,z)`
- 为机械臂提供抓取点

#### 4. 放置区放置箱子链路

负责：

- 识别地面放置区
- 确定当前可见目标区
- 生成候选放置目标
- 生成放置建议计划

#### 5. 机械臂控制与气泵控制链路

负责：

- 接收抓取/放置执行指令
- 控制机械臂运动
- 控制吸盘、电磁阀
- 返回执行反馈

---

## 四、接口和状态机任务：统一总控与视觉的边界

这是整个对话里最重要的一大块。
因为你后面很明确地发现：**不是算法没写出来，而是总控和视觉之间没有统一协议。**

### 这一阶段做的任务包括：

#### 1. 定义总控状态

你们最终统一成总控有五个状态：

- `RECOGNIZE`
- `RUN_MAP`
- `STOP`
- `GRASP`
- `PLACE`

#### 2. 明确总控与视觉各自职责

后来收敛成：

##### 总控负责

- 发五个状态
- 发当前抓取槽位
- 发到位事件
- 发放置方向 `asc / desc`
- 发放置顺序 `FIRST_THEN_SECOND / SECOND_THEN_FIRST`

##### 视觉负责

- 题目识别
- 第一次抓取的箱子种类
- 第二次抓取的箱子种类
- 当前车上带着什么箱子
- 根据总控命令执行放置
- 返回抓取/放置结果

#### 3. 讨论谁来决定“先放哪个箱子”

这一块你和总控反复讨论过，经历了几个版本：

- 版本 A：视觉决定先放哪个
- 版本 B：总控根据视觉 `PlacePlan` 决定
- 版本 C：最终统一为**总控直接给视觉 `place_pick_order`**

最后定稿是：

- 总控说：先放第一个还是第二个
- 视觉按它给的顺序执行

#### 4. 降级 `/placement/current_place_plan`

这是后期一个重要收口任务：

把 `/placement/current_place_plan` 从：

- “总控最终放置决策依据”

降级成：

- **视觉内部规划 / 调试参考输出**

这个任务后来专门做了文档和注释收口。

---

## 五、核心工程任务：补视觉中控层 `vision_coordinator`

这是整个对话里最关键的一项代码架构任务。

### 为什么要做这个任务

因为你已经有：

- 题目识别链
- 抓取视觉链
- 放置视觉链
- 机械臂链

但没有一个“总调度层”去统一：

- 接总控状态
- 开关各链路
- 决定什么时候能执行
- 汇总结果回给总控

### 于是做了这些任务

#### 1. 设计 `vision_coordinator` 的职责

它负责：

- 接收总控消息
- 管理题目识别 / 抓取 / 放置链的启停
- 管理状态机
- 把结果汇总给总控
- 作为机械臂执行的唯一放行入口

#### 2. 修改机械臂执行入口

把机械臂从直接订阅：

- `/grasp/target_3d_camera`

改成只订阅：

- `/vision/execute_grasp_target`

这样抓取视觉链不会绕过总控节拍。

#### 3. 定义中控的关键输出

包括：

- `/vision/problem_summary`
- `/vision/grasp_summary`
- `/vision/grasp_done`
- `/task/carried_boxes`
- `/vision/state`
- `/vision/execute_grasp_target`
- `/vision/execute_place_target`

---

## 六、反馈闭环任务：让 MATCH 模式真正“等反馈”

这是你们从“能联调”进化到“更像比赛系统”的关键阶段。

### 1. 先做 DEBUG / MATCH 模式区分

做了这些任务：

- 给 `vision_coordinator` 增加 `DEBUG` / `MATCH`
- DEBUG 下允许自动确认抓取/放置成功
- MATCH 下必须等待真实 feedback

### 2. 增加抓取 / 放置反馈入口

做了这些接口骨架任务：

- `/robotarm/grasp_feedback`
- `/robotarm/place_feedback`

当前先用：

- `std_msgs/String(JSON)`

### 3. 新增 RobotArm feedback bridge

你们后面又补了：

- `robotarm_feedback_bridge.py`

它负责：

- 订阅内部调试输入
- 统一发布正式 feedback
- 以后给真实气压传感器和执行完成状态接入口子

### 4. 增加 timeout / failed 处理

又继续做了：

- `grasp_feedback_timeout_sec`
- `place_feedback_timeout_sec`
- MATCH 下超时失败逻辑
- 失败不更新成功状态
- monitor 可见 `timeout / failed`

这一步让系统不再“无限等”。

---

## 七、联调工具任务：为了看清系统发生了什么

你们后面做了很多非常重要的“辅助工具任务”，这些不是主业务，但极其关键。

### 1. `master_mock_publisher`

作用：

- 没有真实总控时，模拟发：
  - `/master/state`
  - `/master/current_grasp_slot`
  - `/master/arrived`
  - `/master/place_order`
  - `/master/place_pick_order`

支持：

- CLI 单次发布
- 交互式菜单
- 一键最小流程

### 2. `vision_state_monitor`

作用：

- 集中订阅系统关键状态
- 显示：
  - 当前 `vision/state`
  - `problem_summary`
  - `grasp_summary`
  - `grasp_done`
  - `CarriedBoxState`
  - `PlacePlan`
  - `place_done`
- 后来又新增了：
  - `Recent Events`
  - pending / timeout / failure 状态
  - RobotArm feedback 事件

### 3. `robotarm_feedback_mock`

作用：

- 没有真实硬件时，手工模拟：
  - 抓取成功/失败
  - 放置成功/失败

### 4. 联合验收与隔离域验证

你们后面专门做了：

- `ROS_DOMAIN_ID` 隔离域联调
- 排查旧节点串台
- 用隔离域复核：
  - success
  - failed
  - timeout
  - late feedback ignored
  - bad JSON

---

## 八、相机与硬件架构收敛任务

这一块后来你明确指出了一个很关键的事实：

> D435i 一直固定朝下，不需要姿态切换。

于是这部分任务发生了收敛。

### 1. 之前做过的任务

- 补了 `camera_stepper_node.py`
- 增加 `/vision/camera_pose_cmd`
- 增加 `/vision/camera_pose_status`
- 让相机姿态跟中控状态联动

### 2. 后来发现不该进主线

因为你明确说：

- D435i 固定水平朝下
- 不用抬头/低头

于是又做了“主线去依赖”的任务：

- 移除主流程对 `camera_stepper` 的依赖
- 默认不开启 `VISION_ENABLE_CAMERA_POSE_CMD`
- monitor 里把它降级成 `optional/inactive`
- 文档里明确：`camera_stepper` 是可选备用模块，不是比赛主线

这是一次很重要的架构收口。

---

## 九、固定俯视调参与验收任务

当主架构稳定后，对话重点开始转到：

**如何在 D435i 固定俯视工况下，把抓取和放置参数调稳。**

### 1. 抓取调试能力增强

做了这些任务：

- 给 `depth_projector_node.py` 新增 `/grasp/debug_status`
- 给 `detector_node.py` 增强 `/grasp/debug_image`
- 显示：
  - bbox center
  - project_u / project_v
  - ROI
  - depth_valid_count
  - median depth
  - x_cam / y_cam / z_cam
  - remark

### 2. 放置调试能力增强

做了这些任务：

- 给 `placement_zone_node.py` 新增 `/placement/debug_status`
- 增强 `/placement/debug_image`
- 高亮当前 `PlacePlan` 选中的区
- 显示：
  - visible_zone_count
  - selected_zone_visible
  - safe_center
  - current_target_zone_id
  - selected_target.valid

### 3. monitor 聚合调试状态

`vision_state_monitor` 新增：

- `Grasp Debug`
- `Placement Debug`

### 4. 固定俯视调试文档与运行脚本

新增了：

- `fixed_topdown_debug_run.sh`
- `fixed_topdown_debug.md`

目的是让你们可以现场拿着实物去调。

---

## 十、参数快照 / 对比 / 报告工具任务

这是后期非常有价值的一组任务。

### 为什么要做

因为你后面已经明确进入真实调参阶段，问题变成：

- 今天调的参数是什么
- 昨天调的和今天有啥区别
- 哪组更稳
- 比赛前到底选哪套基线

### 于是做了这些任务

#### 1. `fixed_topdown_snapshot.py`

支持：

- `export`
- `compare`
- `report`

#### 2. 快照导出

保存：

- `parameters.grasp`
- `parameters.placement`
- `observations.grasp`
- `observations.placement`
- `notes / ros_domain_id / created_at`

#### 3. 快照对比

输出：

- 参数差异
- 抓取观测差异
- 放置观测差异
- 自动结论

#### 4. 报告导出

能生成 Markdown 报告，方便你们做调参记录。

---

## 十一、接口文档与团队交付任务

这部分是最后做的“文档收口任务”，目的是让团队内部对口径完全一致。

### 1. 新增权威接口文档

做了：

- `docs/master_vision_interface.md`

用来明确：

- 总控给视觉什么
- 视觉给总控什么
- 谁负责什么
- `/placement/current_place_plan` 的定位

### 2. 文档统一修改

你们后面统一更新了很多文档和注释，包括：

- `README.md`
- `docs/debug.md`
- `docs/placement.md`
- `docs/fixed_topdown_debug.md`
- `docs/vision_coordinator.md`
- `docs/all_debug.md`
- `docs/new_machine_day1_checklist.md`
- `docs/new_machine_final_acceptance.md`

统一表达为：

- 总控负责状态、节拍、抓取槽位、放置方向、放置顺序
- 视觉负责识别、执行、回执、状态更新
- `current_place_plan` 只是视觉内部/调试参考

---

## 十二、对话最后收敛到什么阶段

到对话最后，你们已经正式进入了：

### **实物联调阶段**

不是继续做大代码重构，而是开始：

#### 1. 题目识别实物测试

- USB 摄像头是否对准
- OCR 是否稳定

#### 2. D435i 固定俯视抓取实物调参

- ROI
- depth range
- `depth_valid_count`
- `z_cam`
- `target_valid`

#### 3. D435i 固定俯视放置实物调参

- ROI
- HSV
- `safe_center`
- `selected_zone_visible`
- `selected_target.valid`

#### 4. 快照导出、对比、选基线

最后目标是：

- 选一套 baseline
- 选一套 backup

---

## 十三、如果把整个对话压缩成“任务清单”

我帮你压缩成一个最终版本：

### 已完成的大任务

1. 阅读并理解任务赛视觉需求
2. 明确任务赛视觉总体方案
3. 确定 USB + D435i 双相机职责分工
4. 拆分五条视觉链路
5. 定义总控五状态
6. 设计视觉中控 `vision_coordinator`
7. 规范抓取/放置 feedback 闭环
8. 区分 DEBUG / MATCH 模式
9. 新增总控 mock、monitor、feedback mock 工具
10. 新增 RobotArm feedback bridge
11. 增加 timeout / failed 处理
12. 降级 `camera_stepper` 为可选模块
13. 增强固定俯视抓取调试能力
14. 增强固定俯视放置调试能力
15. 增加固定俯视调试文档与运行脚本
16. 增加参数快照、对比、报告工具
17. 统一总控 ↔ 视觉接口文档
18. 正式收敛主流程架构
19. 进入实物联调阶段

### 当前待继续推进的大任务

1. 用真实硬件做题目识别实测
2. 用真实硬件做抓取调参
3. 用真实硬件做放置调参
4. 导出多组快照并 compare
5. 选定 baseline / backup 参数
6. 等同学完成气压传感器后，接入真实抓取 feedback

---

如果你愿意，我下一条可以继续帮你做一版：

**“把这整个对话整理成项目周报 / 阶段总结文档”**，那种你可以直接发给老师或队友的版本。
