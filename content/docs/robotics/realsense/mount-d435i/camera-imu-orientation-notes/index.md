---
title: "RealSense 镜头姿态与 IMU 数据记录"
description: "对比镜头水平向前和竖直向下时的加速度、滚转角与俯仰角数据。"
---

镜头水平向前

```
[INFO] [1774099293.518115982] [imu_tilt_node]: opt_accel=(-0.3669, -9.2331, 0.8955) m/s^2 | body_accel=(0.8955, -0.3669, -9.2331) m/s^2 | |a|=9.2837 | roll=-177.72 deg | pitch=-5.54 deg | gyro=(-0.0021, 0.0021, 0.0011) rad/s
[INFO] [1774099293.565467710] [imu_tilt_node]: opt_accel=(-0.3729, -9.2115, 0.8927) m/s^2 | body_accel=(0.8927, -0.3729, -9.2115) m/s^2 | |a|=9.2621 | roll=-177.68 deg | pitch=-5.53 deg | gyro=(0.0000, 0.0064, 0.0021) rad/s
[INFO] [1774099293.614062856] [imu_tilt_node]: opt_accel=(-0.3600, -9.2203, 0.8944) m/s^2 | body_accel=(0.8944, -0.3600, -9.2203) m/s^2 | |a|=9.2706 | roll=-177.76 deg | pitch=-5.54 deg | gyro=(0.0011, 0.0032, -0.0011) rad/s
```

镜头竖直向下

```
[INFO] [1774099399.604053775] [imu_tilt_node]: opt_accel=(0.1353, 0.6175, -9.3770) m/s^2 | body_accel=(-9.3770, 0.1353, 0.6175) m/s^2 | |a|=9.3982 | roll=12.36 deg | pitch=86.14 deg | gyro=(0.0021, 0.0053, 0.0053) rad/s
[INFO] [1774099399.657815004] [imu_tilt_node]: opt_accel=(0.1380, 0.6070, -9.3743) m/s^2 | body_accel=(-9.3743, 0.1380, 0.6070) m/s^2 | |a|=9.3949 | roll=12.81 deg | pitch=86.20 deg | gyro=(0.0000, -0.0053, 0.0000) rad/s
[INFO] [1774099399.706942709] [imu_tilt_node]: opt_accel=(0.1402, 0.6156, -9.3818) m/s^2 | body_accel=(-9.3818, 0.1402, 0.6156) m/s^2 | |a|=9.4030 | roll=12.83 deg | pitch=86.15 deg | gyro=(-0.0011, 0.0043, 0.0000) rad/s
[INFO] [1774099399.751151115] [imu_tilt_node]: opt_accel=(0.1300, 0.6051, -9.3834) m/s^2 | body_accel=(-9.3834, 0.1300, 0.6051) m/s^2 | |a|=9.4038 | roll=12.13 deg | pitch=86.23 deg | gyro=(-0.0021, 0.0011, -0.0043) rad/s
[INFO] [1774099399.798605373] [imu_tilt_node]: opt_accel=(0.1309, 0.6130, -9.3746) m/s^2 | body_accel=(-9.3746, 0.1309, 0.6130) m/s^2 | |a|=9.3955 | roll=12.05 deg | pitch=86.17 deg | gyro=(-0.0021, 0.0053, 0.0000) rad/s
[INFO] [1774099399.847276224] [imu_tilt_node]: opt_accel=(0.1349, 0.6159, -9.3817) m/s^2 | body_accel=(-9.3817, 0.1349, 0.6159) m/s^2 | |a|=9.4029 | roll=12.36 deg | pitch=86.16 deg | gyro=(0.0000, -0.0032, 0.0000) rad/s
```

镜头面向天空

```
[INFO] [1774099488.899211606] [imu_tilt_node]: opt_accel=(-0.0718, 0.4075, 9.9437) m/s^2 | body_accel=(9.9437, -0.0718, 0.4075) m/s^2 | |a|=9.9523 | roll=-9.99 deg | pitch=-87.62 deg | gyro=(-0.0053, 0.0032, -0.0053) rad/s
[INFO] [1774099488.957735254] [imu_tilt_node]: opt_accel=(-0.0782, 0.4057, 9.9527) m/s^2 | body_accel=(9.9527, -0.0782, 0.4057) m/s^2 | |a|=9.9612 | roll=-10.92 deg | pitch=-87.62 deg | gyro=(0.0000, 0.0032, -0.0011) rad/s
[INFO] [1774099488.995842775] [imu_tilt_node]: opt_accel=(-0.0697, 0.4074, 9.9390) m/s^2 | body_accel=(9.9390, -0.0697, 0.4074) m/s^2 | |a|=9.9476 | roll=-9.70 deg | pitch=-87.62 deg | gyro=(0.0021, 0.0011, -0.0032) rad/s
[INFO] [1774099489.050162169] [imu_tilt_node]: opt_accel=(-0.0808, 0.4064, 9.9321) m/s^2 | body_accel=(9.9321, -0.0808, 0.4064) m/s^2 | |a|=9.9408 | roll=-11.25 deg | pitch=-87.61 deg | gyro=(-0.0021, 0.0032, 0.0021) rad/s
[INFO] [1774099489.100983534] [imu_tilt_node]: opt_accel=(-0.0803, 0.4206, 9.9290) m/s^2 | body_accel=(9.9290, -0.0803, 0.4206) m/s^2 | |a|=9.9383 | roll=-10.81 deg | pitch=-87.53 deg | gyro=(-0.0021, 0.0021, 0.0021) rad/s
```
