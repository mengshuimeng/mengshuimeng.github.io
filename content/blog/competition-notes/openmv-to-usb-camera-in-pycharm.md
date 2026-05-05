---
title: OpenMV 代码改为 PyCharm + USB 摄像头方案
description: 将 OpenMV/K230 风格视觉代码迁移到电脑端 Python + OpenCV 的思路
---

## 背景

原始代码运行在 OpenMV/K230 类设备环境中，依赖 `media.sensor`、`media.display`、`media.media` 等板端模块。要在电脑上用 PyCharm 和 USB 摄像头运行，需要把采集、显示和图像处理接口替换为普通 Python 环境可用的库。

## 迁移思路

- 用 `cv2.VideoCapture(0)` 代替板端 `Sensor`。
- 用 OpenCV 的灰度、阈值和轮廓检测代替板端 `binary()`、`find_rects()`。
- 用 `cv2.imshow()` 代替板端 `Display.show_image()`。
- 保留几何计算函数，例如角度计算、点到线段距离、多边形面积和正方形判断。
- 用 `KeyboardInterrupt` 或按键 `q` 退出程序。

## 最小可运行框架

```python
import cv2
import math


def calculate_angle(p1, p2, p3):
    a2 = (p2[0] - p3[0]) ** 2 + (p2[1] - p3[1]) ** 2
    b2 = (p1[0] - p3[0]) ** 2 + (p1[1] - p3[1]) ** 2
    c2 = (p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2
    if a2 == 0 or c2 == 0:
        return 0
    cos_angle = (a2 + c2 - b2) / (2 * math.sqrt(a2) * math.sqrt(c2))
    cos_angle = max(-1.0, min(1.0, cos_angle))
    return math.degrees(math.acos(cos_angle))


cap = cv2.VideoCapture(0)
if not cap.isOpened():
    raise RuntimeError("无法打开 USB 摄像头")

while True:
    ok, frame = cap.read()
    if not ok:
        break

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    _, binary = cv2.threshold(gray, 120, 255, cv2.THRESH_BINARY)

    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    for contour in contours:
        epsilon = 0.02 * cv2.arcLength(contour, True)
        approx = cv2.approxPolyDP(contour, epsilon, True)
        if len(approx) == 4 and cv2.contourArea(approx) > 3500:
            cv2.drawContours(frame, [approx], -1, (0, 255, 0), 2)

    cv2.imshow("USB Camera", frame)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()
```

## 调试建议

- 如果摄像头打不开，尝试把 `VideoCapture(0)` 改为 `VideoCapture(1)`。
- 如果二值化效果不好，先用 `cv2.imshow("binary", binary)` 单独观察阈值结果。
- 如果矩形误检太多，增加面积阈值、角度约束和 ROI 区域裁剪。
- 如果需要沿用原始面积换算逻辑，应先保证外框和内框检测稳定，再计算实际面积。
