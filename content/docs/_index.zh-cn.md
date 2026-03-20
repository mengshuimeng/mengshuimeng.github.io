---
title: 技术文档
---

这里整理我在环境配置、设备调试、视觉算法、机器人系统、强化学习与工程实践中的技术文档。

## 文档分类

{{< cards cols="2" >}}
  {{< card link="/docs/environment" title="环境与部署" subtitle="WSL、Ubuntu、Docker、Conda、Git 等" icon="book-open" >}}
  {{< card link="/docs/robotics" title="机器人与设备调试" subtitle="ROS2、RealSense、Jetson、视觉系统" icon="collection" >}}
  {{< card link="/docs/cv" title="计算机视觉" subtitle="YOLO、ReID、数据集、训练流程" icon="sparkles" >}}
  {{< card link="/docs/rl-sim" title="强化学习与仿真" subtitle="Isaac Lab、仿真环境与基础实验" icon="academic-cap" >}}
{{< /cards >}}

## 推荐阅读

- [Windows + WSL2 + Ubuntu 22.04 + ROS 2 Humble 运行 Intel RealSense D435i 维护记录](/docs/robotics/realsense/wsl2-ros2-humble/)
- [Conda 使用指南](/docs/environment/conda-guide/)
- [YOLO 本地测试与服务器训练完整流程](/docs/cv/yolo-training/)