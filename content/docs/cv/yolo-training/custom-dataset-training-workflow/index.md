---
title: "自定义 YOLO 数据集与服务器训练流程"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "YOLO"
  - "数据集"
---

训练yolo模型

### 采集视频

- `capture_videos.py`摄像头录像程序，用于录制视频并保存到本地。

- `video_to_frames_numbered.py` 将视频文件拆分成连续的图片帧，并按数字顺序命名保存。
- `rename_picture.py`  将文件夹中的图片按顺序批量重命名为连续数字编号。
- `distubute.py` 将一个文件夹里的图片按照输入的人数平均分配为多个文件夹
- `data_organize.py` 将图片和标注数据按比例切分为 训练集和测试集

## 2.到服务器跑模型

- ssh远程

```text
scp -r <本地源路径> <用户名>@<远程IP>:<远程目标路径>
scp -r "D:\Documents\code\python\all_of_all\data_produce\datasets0321" jsh@192.168.0.214:/home/jsh/yolo/
```

```bash
(yolo) jsh@hurricane-X99:~/yolo$ yolo task=detect mode=train data=/home/jsh/yolo/box_datasets0321.yaml model=yolo11s.pt epochs=200 batch=16 imgsz=768 lr0=0.001 optimizer=AdamW cos_lr=True device=0 patien
ce=50 mosaic=0.5 mixup=0.1 workers=8 cache=True plots=True
```
