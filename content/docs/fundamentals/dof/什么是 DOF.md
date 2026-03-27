---
title: 什么是 DOF
description: 机器人自由度与相关变量的基础解释
slug: what-is-dof
aliases:
  - /docs/fundamentals/dof/什么是-dof/
---

DOF = **Degree Of Freedom（自由度）**，在机器人/仿真中是一个非常基础的概念。下面用中文把它从概念、种类、在这段代码中的具体含义和常见表示方式都讲清楚，带几点例子和注意事项，方便你理解代码里跟 `dof` 有关的变量（`dof_pos`、`dof_vel`、`dof_state`、`num_dof`、`torque_limits` 等）。

------

# 一、概念（什么是 DOF）

- 自由度（DOF）指机器人能独立运动的坐标数。每一个可独立控制的关节或移动方向就算一个自由度。
   例：单关节电机（绕某轴旋转）→ 1 DOF；线性滑轨（沿 x 轴移动）→ 1 DOF；一个 6-轴机械臂通常有 6 DOF（6 个转动关节）。
- 对于整台机器人，总 DOF = 所有关节的 DOF 总和（不包括通常把“浮动基座”或“根节点”单独看待的时候的基座自由度，视实现而定）。

------

# 二、常见 DOF 类型

- **Revolute（旋转关节）**：角度表示（单位：rad）。最常见。
- **Prismatic（直线关节）**：位置表示（单位：m）。
- **Continuous（连续旋转）**：角度不限范围（wheel）。
- **Floating base（浮动基座）**：机器人在世界中的平移＋旋转（通常是 6 DOF：x,y,z + 四元数或欧拉角），但在仿真里往往单独用 `root_states` 表示，不计入 `num_dof`（depends on engine/config）。

------

# 三、在这段代码中 DOF 的具体含义

- `self.num_dof` / `self.num_dofs`：关节自由度的数量（等于机器人关节数量，代码中用于构造和索引张量）。
- `self.dof_names`：每个 DOF 的名字（读自 asset / URDF），方便按名称匹配 gain、初始角度等。
- `self.dof_state`：从 Isaac Gym 获取的原始张量，通常含 position 和 velocity 两个分量；代码里 `dof_state.view(self.num_envs, self.num_dof, 2)` 表示每个 env、每个 DOF 有两个数：`[..., 0]` 是 position，`[..., 1]` 是 velocity。
  - 例：`self.dof_pos = self.dof_state.view(...)[..., 0]`，`self.dof_vel = self.dof_state.view(...)[..., 1]`
- `self.default_dof_pos`：动作为 0 时的目标/偏置角度（在 P 控制时用到）。
- `self.p_gains`, `self.d_gains`：每个 DOF 的 PD 增益（影响 PD 控制输出扭矩）。
- `self.torque_limits`：每个 DOF 的最大扭矩（从 URDF/asset 中读取，用于 `torch.clip` 限制扭矩）。
- `self.actions`：策略输出的动作向量，长度通常等于 `num_actions`，通常 `num_actions == num_dof` 或者某些 DOF 不被控制时小于 `num_dof`（但代码注释说：**torques 必须和 DOF 数一致**，即即便某些 DOF不被驱动也要提供形状匹配的张量）。
- `default_dof_pos.unsqueeze(0)`：把 (num_dof,) 变成 (1, num_dof) 方便与 (num_envs, num_dof) 广播相加。

------

# 四、在仿真/代码层面的数据表示（举例与形状）

假设 `num_envs = 1024`，`num_dof = 12`：

- `dof_state`（从 gym 获取）形状可能是 `(num_envs * num_dof * 2,)`（一维连续内存），代码用 `view` 把它解析为 `(num_envs, num_dof, 2)`。
  - `dof_state[i, j, 0]` = 第 i 个环境，第 j 个关节的位置（angle）。
  - `dof_state[i, j, 1]` = 第 i 环境，第 j 关节的速度。
- `dof_pos`：形状 `(num_envs, num_dof)`，等于 `dof_state[..., 0]`。
- `dof_vel`：形状 `(num_envs, num_dof)`，等于 `dof_state[..., 1]`。
- `actions`：通常是 `(num_envs, num_actions)`，若 `num_actions == num_dof`，就可以一一对应每个关节。
- `torques`：代码中 `self.torques = torch.zeros(self.num_envs, self.num_actions, ...)`，也形状 `(num_envs, num_dof)`，最终被 `set_dof_actuation_force_tensor` 发送给仿真。

------

# 五、DOF 与“actuation drive mode”（驱动模式）的关系

- 仿真中的每个 DOF 在 asset/URDF 里常有 `drive_mode`（例如 position target, velocity target, effort/torque），代码里 `asset_options.default_dof_drive_mode` 也能设置缺省驱动类型。
- 在高层控制器（如本代码）：
  - `'P'` 和 `'V'` 模式都把动作映射到**目标位置或目标速度**，然后通过 `set_actor_dof_properties`/驱动模式让仿真以位置/速度驱动形式执行（或通过 PD 计算扭矩再以 effort 模式发送）。
  - `'T'` 模式直接发送扭矩（effort）。

------

# 六、举个直观例子（四条腿机器人）

- 四足机器人，每条腿 3 个转动关节 → `num_dof = 12`。
- 如果策略的 `num_actions=12`，每个 action 控制一个关节：action[0] -> 左前髋关节, action[1] -> 左前膝, ...
- `default_dof_pos` 存的是“站立/初始角度”，当动作为 0 时机器人会保持这些角度（在 P 控制下）。

------

# 七、为什么 DOF 很重要（在 RL/仿真中的影响）

- **动作维度**：策略的输出维度通常与 DOF 紧密相关。 DOF 多 → 动作空间大，训练更难。
- **物理限制**：每个 DOF 的角度/速度/扭矩上限影响学习与安全（需要 clip）。
- **观测设计**：观测中通常包含 `dof_pos`、`dof_vel`，用于策略决策。如何归一化（obs_scales）也受 DOF 个数影响。
- **控制模式选择**：想简化学习可选择 P/V（高层目标），想更真实或更灵活则用 T（低层扭矩控制）。

------

# 八、常见问题（FAQ）

- **“所有 DOF 都被驱动吗？”** 不一定。有些 DOF 可能是被动连接（fixed）或不在动作空间内，但仿真仍有它们的 `dof_state`。代码里通常要求 torques 张量与 num_dof 形状一致，即便某些关节 torque 为 0。
- **“DOF 和 root_states 的区别？”** `root_states` 是浮动基座（base）在世界坐标中的位置/朝向/速度等（通常包含 6 个自由度的位置项和速度项），而 `dof_*` 是每个关节的内部自由度（相对于基座或父链接）。
- **“如何知道某个 name 对应哪一维 DOF？”** 通过 `self.dof_names`（由 gym 从 asset 读取）对应索引；这就是代码里用名字匹配 gains、默认角度等的原因。

------

# 九、总结（一句话）

DOF 就是“每个关节（或可独立运动方向）算一个自由度”，在代码中对应一系列张量（位置、速度、扭矩、限制、增益等），这些张量的维度与 `num_dof` 密切相关，是理解机器人控制与仿真数据流的关键。

------

如果你想，我可以把你代码里与 DOF 有关的变量（`dof_state`、`dof_pos`、`dof_vel`、`p_gains`、`d_gains`、`torque_limits`、`default_dof_pos`）做一个对照表，写出每个变量的形状、来源和用途 —— 要我生成这样的表吗？
