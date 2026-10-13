---
title: "数学建模论文 v2 图片体系总览"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "数学建模"
  - "论文写作"
---

• 可以。下面我只列 v2 版本，并按 题目 说明：

  - 要画哪些图
  - 这些图基于什么数据
  - 数据路径是什么
  - 还能加哪些图

  ———

## 总览：当前仓库里的 v2 图

### Q1 v2

  - figures/B/q1_alignment_v2.png
  - figures/B/q1_alignment_matlab_v2.png
  - figures/B/q1_alignment_matlab_v2.fig

### Q2 v2

  - figures/B/q2_fusion_v2.png
  - figures/B/q2_residual_v2.png
  - figures/B/q2_fusion_matlab_v2.png
  - figures/B/q2_fusion_matlab_v2.fig

### Q3 v2

  - figures/B/q3_model_compare_v2.png
  - figures/B/q3_actual_fusion_v2.png
  - figures/B/q3_actual_fusion_matlab_v2.png
  - figures/B/q3_actual_fusion_matlab_v2.fig

### Q4 v2

  - figures/B/q4_windows_v2.png
  - figures/B/q4_selected_tasks_v2.png
  - figures/B/q4_schedule_matlab_v2.png
  - figures/B/q4_schedule_matlab_v2.fig

  ———

## Q1 v2

### 1）应该画什么图

#### 主图

  - 方式1平滑轨迹
  - 时间对齐后的方式2平滑轨迹
  - 10Hz 等权融合重建轨迹
  - 残差距离随时间变化
  - x / y 残差分量
  - 时间偏移和对齐后 MSE / RMSE 标注

#### 当前对应图

  - figures/B/q1_alignment_v2.png
  - figures/B/q1_alignment_matlab_v2.png
  - figures/B/q1_alignment_matlab_v2.fig

### 2）数据来源和路径

#### 原始数据

  - data/raw/B/附件1.xlsx

#### 处理后数据

  - data_processed/B/q1_trajectory_10hz_v2.csv
  - tables/B/q1_time_offset_v2.csv
  - tables/B/q1_compare_baseline_v2.csv

### 3）每张图用哪些数据

  - 轨迹图：q1_trajectory_10hz_v2.csv
  - 残差图：q1_trajectory_10hz_v2.csv + q1_time_offset_v2.csv
  - 指标标注：q1_time_offset_v2.csv + q1_compare_baseline_v2.csv

### 4）还能加哪些图

  可以补这些图：

  - 时间偏移搜索曲线：时间偏移 vs 速度误差 / 位置误差
  - 残差直方图：看误差是否集中
  - x/y 残差箱线图：看残差分布
  - 方式1/方式2原始插值点对比图
  - 速度曲线 / 航向曲线对比图

  ———

## Q2 v2

### 1）应该画什么图

#### 主图

  - 方式1轨迹
  - 校正后的方式2轨迹
  - v2 融合轨迹
  - x / y 残差随时间变化
  - 残差距离随时间变化
  - M1 / M2 模型比较
  - v2 与 baseline 指标对比

#### 当前对应图

  - figures/B/q2_fusion_v2.png
  - figures/B/q2_residual_v2.png
  - figures/B/q2_fusion_matlab_v2.png
  - figures/B/q2_fusion_matlab_v2.fig

### 2）数据来源和路径

#### 原始数据

  - data/raw/B/附件2.xlsx

#### 处理后数据

  - data_processed/B/q2_fused_trajectory_10hz_v2.csv
  - tables/B/q2_model_compare_v2.csv
  - tables/B/q2_robust_params_v2.csv
  - tables/B/q2_compare_baseline_v2.csv

### 3）每张图用哪些数据

  - 轨迹图：q2_fused_trajectory_10hz_v2.csv
  - 残差图：q2_fused_trajectory_10hz_v2.csv
  - 模型对比图：q2_model_compare_v2.csv
  - 参数标注图：q2_robust_params_v2.csv
  - baseline 对比：q2_compare_baseline_v2.csv

### 4）还能加哪些图

  可以补这些图：

  - 残差直方图
  - 局部自适应权重曲线
  - 残差方差随时间变化图
  - M1/M2 参数敏感性图
  - 融合前后轨迹局部放大图
  - RMSE / BIC 柱状图

  ———

## Q3 v2

### 1）应该画什么图

#### 主图

  - 实际方式1轨迹
  - 校正/使用后的方式2轨迹
  - v2 融合轨迹
  - x / y 残差随时间变化
  - 残差距离随时间变化
  - M0 / M1 / M2 的 RMSE 与 BIC 对比
  - Bootstrap 置信区间 / 显著性判断
  - v2 与 baseline 关键指标对比

#### 当前对应图

  - figures/B/q3_model_compare_v2.png
  - figures/B/q3_actual_fusion_v2.png
  - figures/B/q3_actual_fusion_matlab_v2.png
  - figures/B/q3_actual_fusion_matlab_v2.fig

### 2）数据来源和路径

#### 原始数据

  - data/raw/B/附件3.xlsx

#### 处理后数据

  - data_processed/B/q3_actual_fused_trajectory_10hz_v2.csv
  - tables/B/q3_model_selection_v2.csv
  - tables/B/q3_bootstrap_test_v2.csv
  - tables/B/q3_compare_baseline_v2.csv

### 3）每张图用哪些数据

  - 轨迹图：q3_actual_fused_trajectory_10hz_v2.csv
  - 残差图：q3_actual_fused_trajectory_10hz_v2.csv
  - 模型比较图：q3_model_selection_v2.csv
  - Bootstrap 图：q3_bootstrap_test_v2.csv
  - baseline 对比图：q3_compare_baseline_v2.csv

### 4）还能加哪些图

  可以补这些图：

  - Bootstrap 95% CI 横向误差棒图
  - bootstrap 分布直方图
  - M0/M1/M2 的 BIC 柱状图
  - 残差距离分布图
  - 对齐前后局部轨迹放大图
  - 模型残差箱线图

  ———

## Q4 v2

### 1）应该画什么图

#### 主图

  - 目标分布与任务窗口分布图
  - 最终选中任务的时间轴 / Gantt 图
  - 最终选中任务的空间分布图
  - strict baseline 与 v2 的对比摘要图

#### 当前对应图

  - figures/B/q4_windows_v2.png
  - figures/B/q4_selected_tasks_v2.png
  - figures/B/q4_schedule_matlab_v2.png
  - figures/B/q4_schedule_matlab_v2.fig

### 2）数据来源和路径

#### 上游轨迹数据

  - data_processed/B/q3_actual_fused_trajectory_10hz_v2.csv

#### 原始任务目标数据

  - data/raw/B/附件4.xlsx

#### 处理后数据

  - tables/B/q4_task_windows_v2.csv
  - tables/B/q4_selected_tasks_v2.csv
  - tables/B/q4_task_summary_v2.csv

#### strict 对比数据

  - tables/B/q4_selected_tasks_strict.csv
  - tables/B/q4_task_summary_strict.csv

### 3）每张图用哪些数据

  - 任务窗口图：q4_task_windows_v2.csv + q3_actual_fused_trajectory_10hz_v2.csv + 附件4.xlsx
  - 选中任务图：q4_selected_tasks_v2.csv
  - 摘要对比图：q4_task_summary_v2.csv + strict 基线表
  - MATLAB 论文图：q4_task_windows_v2.csv + q4_selected_tasks_v2.csv + q4_task_summary_v2.csv + strict 基线表

### 4）还能加哪些图

  可以补这些图：

  - 每个目标的可行窗口数柱状图
  - 任务窗口长度分布直方图
  - 射击 / 拍照任务的质量分数分布
  - 拍照角区占用统计图
  - 目标覆盖热力图
  - 任务冲突图 / 可行性网络图
  - v2 vs strict 的 Pareto 对比图

  ———

## 如果你只想保留“论文主图”，我建议这样选

### Q1

  - 1 张主图：q1_alignment_matlab_v2.png

### Q2

  - 1 张主图：q2_fusion_matlab_v2.png
  - 1 张补图：q2_residual_v2.png

### Q3

  - 1 张主图：q3_actual_fusion_matlab_v2.png
  - 1 张补图：q3_model_compare_v2.png

### Q4

  - 1 张主图：q4_schedule_matlab_v2.png
  - 1 张补图：q4_windows_v2.png 或 q4_selected_tasks_v2.png

  ———

  如果你愿意，我下一条可以直接给你整理成一个 “v2 图表清单表格”，我会按：

  题号｜图文件名｜数据输入｜图内容｜建议是否保留

  这种格式列出来，方便你们直接改图。

› 整理一个v2图表清单表格

• 下面给你整理成一个 v2 图表清单表格，只包含 v2 版本。

  > 说明：
  >
  > - “数据来源”写的是图背后依赖的处理后数据 / 原始附件
  > - “数据路径”写的是你在仓库里直接可读的文件
  > - “可加图”是你后续可以扩展的图类型

  ———

### B题 v2 图表清单表

| 题目                                                   | 图文件                                             | 数据来源                           | 数据路径                                                     | 图内容                               | 可加图                          |
| ------------------------------------------------------ | -------------------------------------------------- | ---------------------------------- | ------------------------------------------------------------ | ------------------------------------ | ------------------------------- |
| Q1 v2                                                  | figures/B/q1_alignment_v2.png                      | 附件1 + v2 对齐结果                | data/raw/B/附件1.xlsx；data_processed/B/q1_trajectory_10hz_v2.csv；tables/B/q1_time_offset_v2.csv | 方式1/方式2对齐轨迹、10Hz            |                                 |
| 重建、残差变化                                         | 时间偏移搜索曲线、残差直方图、x/y残差箱线图        |                                    |                                                              |                                      |                                 |
| Q1 v2                                                  | figures/B/q1_alignment_matlab_v2.png               | 同上                               | 同上                                                         | 论文级综合图，含轨迹、残差、指标标注 | 同上                            |
| Q1 v2                                                  | figures/B/q1_alignment_matlab_v2.fig               | 同上                               | 同上                                                         | MATLAB 可编辑图窗                    | 同上                            |
| Q2 v2                                                  | figures/B/q2_fusion_v2.png                         | 附件2 + v2 融合结果                | data/raw/B/附件2.xlsx；data_processed/B/q2_fused_trajectory_10hz_v2.csv；tables/B/q2_model_compare_v2.csv | 方式1/校正后方式2/v2                 |                                 |
| 融合轨迹                                               | 残差直方图、融合前后局部放大图、权重曲线           |                                    |                                                              |                                      |                                 |
| Q2 v2                                                  | figures/B/q2_residual_v2.png                       | 同上                               | 同上                                                         | 残差分析图                           | 残差方差随时间、RMSE/BIC 柱状图 |
| Q2 v2                                                  | figures/B/q2_fusion_matlab_v2.png                  | 同上                               | data_processed/B/q2_fused_trajectory_10hz_v2.csv；tables/B/q2_model_compare_v2.csv；tables/B/q2_robust_params_v2.csv | 论文级综合图，含                     |                                 |
| 轨迹、残差、模型比较                                   | 同上                                               |                                    |                                                              |                                      |                                 |
| Q2 v2                                                  | figures/B/q2_fusion_matlab_v2.fig                  | 同上                               | 同上                                                         | MATLAB 可编辑图窗                    | 同上                            |
| Q3 v2                                                  | figures/B/q3_model_compare_v2.png                  | 附件3 + 模型选择/Bootstrap         | data/raw/B/附件3.xlsx；tables/B/q3_model_selection_v2.csv；tables/B/q3_bootstrap_test_v2.csv | M0/M1/M2 的 RMSE、                   |                                 |
| BIC、Bootstrap 显著性                                  | Bootstrap 分布图、CI 误差棒图                      |                                    |                                                              |                                      |                                 |
| Q3 v2                                                  | figures/B/q3_actual_fusion_v2.png                  | 附件3 + v2 融合轨迹                | data/raw/B/附件3.xlsx；data_processed/B/q3_actual_fused_trajectory_10hz_v2.csv；tables/B/q3_compare_baseline_v2.csv | 实                                   |                                 |
| 际方式1、校正后方式2、v2融合轨迹、残差、baseline 对比  | 残差分布、局部放大图、模型残差箱线图               |                                    |                                                              |                                      |                                 |
| Q3 v2                                                  | figures/B/q3_actual_fusion_matlab_v2.png           | 同上                               | data_processed/B/q3_actual_fused_trajectory_10hz_v2.csv；tables/B/q3_model_selection_v2.csv；tables/B/q3_bootstrap_test_v2.csv |                                      |                                 |
| MATLAB 论文级综合图，含轨迹、残差、模型对比、Bootstrap | 同上                                               |                                    |                                                              |                                      |                                 |
| Q3 v2                                                  | figures/B/q3_actual_fusion_matlab_v2.fig           | 同上                               | 同上                                                         | MATLAB 可编辑图窗                    | 同上                            |
| Q4 v2                                                  | figures/B/q4_windows_v2.png                        | Q3 v2 轨迹 + 附件4 + 窗口生成结果  | data_processed/B/q3_actual_fused_trajectory_10hz_v2.csv；data/raw/B/附件4.xlsx；tables/B/q4_task_windows_v2.csv |                                      |                                 |
| 目标分布、任务窗口分布、时间窗分布                     | 窗口长度分布、目标可行窗口数柱状图、任务窗口热力图 |                                    |                                                              |                                      |                                 |
| Q4 v2                                                  | figures/B/q4_selected_tasks_v2.png                 | 选中任务 + strict 基线             | tables/B/q4_selected_tasks_v2.csv；tables/B/q4_task_summary_v2.csv；tables/B/q4_selected_tasks_strict.csv；tables/B/ |                                      |                                 |
| q4_task_summary_strict.csv                             | Gantt 图、空间分布、v2 vs strict 对比              | 任务冲突图、目标覆盖图、角区占用图 |                                                              |                                      |                                 |
| Q4 v2                                                  | figures/B/q4_schedule_matlab_v2.png                | 同上                               | tables/B/q4_task_windows_v2.csv；tables/B/q4_selected_tasks_v2.csv；tables/B/q4_task_summary_v2.csv；strict 对比表 | MATLAB 论文级综合                    |                                 |
| 图：窗口、Gantt、空间分布、baseline 对比               | 同上                                               |                                    |                                                              |                                      |                                 |
| Q4 v2                                                  | figures/B/q4_schedule_matlab_v2.fig                | 同上                               | 同上                                                         | MATLAB 可编辑图窗                    | 同上                            |

  ———

### 如果你想按“每题必须保留的主图”来收缩

  我建议 v2 最少保留这 4 张主图：

| 题目  | 建议主图                                 |
| ----- | ---------------------------------------- |
| Q1 v2 | figures/B/q1_alignment_matlab_v2.png     |
| Q2 v2 | figures/B/q2_fusion_matlab_v2.png        |
| Q3 v2 | figures/B/q3_actual_fusion_matlab_v2.png |
| Q4 v2 | figures/B/q4_schedule_matlab_v2.png      |

  ———

### 如果你要，我下一步可以继续给你整理成：

  1. “图表清单 + 推荐标题”
  2. “图表清单 + 论文中对应小节”
  3. “图表清单 + 哪些图可以删、哪些必须留”
