---
title: "Mounting RealSense D435i"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "RealSense"
  - "WSL"
  - "ROS 2"
---

This page records the practical side of using a RealSense D435i in a robotics setup: hardware mounting, USB visibility, WSL or Docker passthrough, and ROS 2 bring-up.

## Main Problem Space

The camera may be visible at the USB layer but still fail when ROS 2 tries to create the device. That usually means the issue is not simple power or cable detection, but the path between host, WSL, container, and middleware.

## What To Verify First

1. The device appears in Windows.
2. The device is attached into WSL with `usbipd` when needed.
3. The device appears in `lsusb` inside WSL.
4. The required `/dev/video*`, `/dev/media*`, or `/dev/hidraw*` nodes exist.
5. The ROS 2 package and launch files are installed correctly.

## Typical Stack

- Windows host
- WSL2
- Optional Docker container
- ROS 2 Humble
- `realsense2_camera`

## Practical Advice

- Debug each layer separately instead of changing everything at once.
- Confirm the camera in WSL before diagnosing Docker.
- Keep launch commands and device checks in the same note so the workflow is reproducible.
