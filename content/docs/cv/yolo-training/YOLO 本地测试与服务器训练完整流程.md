# YOLO 本地测试与服务器训练完整流程

> 本文档用于记录 YOLO 项目从本地环境测试到服务器训练、TensorBoard 可视化、模型验证、推理预测以及结果回传本地的完整流程。  
>
> 适用场景：  
> - 本地电脑先完成环境验证与小规模测试  
> - 服务器进行正式训练  
> - 使用 TensorBoard 远程查看训练日志  
> - 训练完成后进行验证、推理和结果导出  
>
> 作者：姜树豪（JSH）  
> 更新时间：2026-03-09

---

## 目录

1. 工作流总览
2. 本地环境测试
3. 服务器环境配置
4. 服务器训练
5. TensorBoard 可视化
6. 在服务器上验证模型
7. 在服务器上执行预测
8. 将结果拷回本地
9. 常见注意事项

---

## 1. 工作流总览

整个流程建议按下面顺序执行：

1. 在本地检查显卡、创建环境、安装依赖
2. 在本地运行测试脚本，确认 GPU 和训练命令能正常工作
3. 在服务器上重新配置环境
4. 在服务器上拉取项目并正式训练
5. 通过 TensorBoard 远程查看训练日志
6. 训练完成后，在服务器上进行验证与预测
7. 将训练结果从服务器拷回本地保存

这条主线要记住：

> **本地负责测试，服务器负责正式训练。**

---

## 2. 本地环境测试

这一部分的目的不是正式训练，而是先确认：

- 显卡驱动正常
- Conda 环境可用
- PyTorch 能调用 GPU
- YOLO 命令可以正常运行

---

### 2.1 查看显卡驱动

在 PowerShell 中执行：

```powershell
nvidia-smi
```

如果能够正常显示显卡信息，说明当前机器的 NVIDIA 驱动工作正常。

------

### 2.2 创建 Conda 环境

```powershell
conda create -n yolo python=3.11 -y
conda activate yolo
```

> 注意：
> 开代理时有时会导致 Conda 或 pip 下载失败，如果遇到异常，可以先关闭代理再试。

------

### 2.3 安装依赖

先升级 `pip`：

```powershell
python -m pip install --upgrade pip
```

安装 TensorBoard：

```powershell
pip install tensorboard
```

安装 PyTorch：

```powershell
pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cu128
```

如果后续还需要 YOLO 命令，可以继续安装 Ultralytics：

```powershell
pip install -U ultralytics
```

------

### 2.4 测试 GPU 是否可用

建议准备一个简单的测试脚本，例如 `test_gpu.py`，用于确认当前环境是否能正常调用 CUDA。

测试通过后，再继续后面的训练操作。

------

### 2.5 查看图片尺寸

在训练前，先确认输入图像大小，例如：

```text
Image size: 1280 x 720
```

这一步的目的是帮助你后续合理设置 `imgsz`。

------

### 2.6 本地训练测试命令

本地测试可用如下命令：

```powershell
yolo task=detect mode=train data=D:\Documents\code\python\yolo\datasets.yaml epochs=20 batch=1 model=D:\Documents\code\python\yolo\runs\detect\train\weights\best.pt device=0 imgsz=640 workers=2
```

说明：

- `epochs=20`：本地测试训练轮数较少
- `batch=1`：本地显存有限时更稳
- `device=0`：使用第 0 张 GPU
- `workers=2`：减少数据加载线程数，避免本地机器过载

> 本地训练通常只用于“跑通流程”，不建议作为正式训练环境。

------

## 3. 服务器环境配置

正式训练建议放到服务器上执行。

------

### 3.1 查看 GPU 状态

登录服务器后，先检查显卡状态：

```bash
nvidia-smi
```

如果能看到服务器 GPU 信息，说明环境基础正常。

------

### 3.2 创建环境并安装依赖

```bash
conda create -n yolo python=3.11
conda activate yolo

pip3 install torch torchvision
pip install -U ultralytics
```

如果还要使用 TensorBoard，可提前安装：

```bash
pip install tensorboard
```

------

### 3.3 克隆项目

在服务器上将项目代码拉下来，或者把本地项目上传到服务器。

```bash
git clone <your-repo-url>
cd <your-project-dir>
```

如果不是 Git 仓库，也可以直接使用 `scp` 或其他方式上传项目目录。

------

## 4. 服务器训练

服务器训练命令如下：

```bash
yolo task=detect mode=train \
data=/home/jsh/yolo/datasets.yaml \
model=yolo11s.pt \
epochs=200 \
batch=32 \
imgsz=768 \
lr0=0.001 \
optimizer=adamw \
cos_lr=True \
device=0 \
patience=50 \
augment=True \
mosaic=1.0 mixup=0.2 \
workers=8
```

### 参数说明

- `data=/home/jsh/yolo/datasets.yaml`：数据集配置文件
- `model=yolo11s.pt`：预训练模型
- `epochs=200`：训练 200 个 epoch
- `batch=32`：批大小
- `imgsz=768`：输入分辨率
- `lr0=0.001`：初始学习率
- `optimizer=adamw`：优化器
- `cos_lr=True`：使用余弦学习率调度
- `patience=50`：早停耐心值
- `augment=True`：启用数据增强
- `mosaic=1.0 mixup=0.2`：增强策略
- `workers=8`：数据加载线程数

> 正式训练前，建议先确认：
>
> - 数据路径是否正确
> - 模型文件是否存在
> - 显存是否足够支持当前 `batch` 和 `imgsz`

------

## 5. TensorBoard 可视化

TensorBoard 的作用是远程查看训练日志，例如 loss、mAP、学习率变化等。

------

### 5.1 在服务器上安装 TensorBoard

登录服务器后执行：

```bash
conda activate yolo
conda install -n yolo -c conda-forge tensorboard -y
```

或者使用 pip：

```bash
pip install tensorboard
```

------

### 5.2 检查是否有事件文件

```bash
ls -lh /home/jsh/yolo/runs/detect/train9
```

如果目录中存在 `events.*` 文件，说明 TensorBoard 日志已经生成。

如果没有事件文件，可能是训练时环境中还没有安装 TensorBoard。
此时可以触发一次验证或短训练来重新生成日志：

```bash
yolo task=detect mode=val data=/home/jsh/yolo/datasets.yaml model=/home/jsh/yolo/runs/detect/train9/weights/best.pt
```

------

### 5.3 在服务器上启动 TensorBoard

推荐使用 `tmux` 后台运行：

```bash
sudo apt install tmux
tmux new -s tb
```

在 `tmux` 会话中执行：

```bash
conda activate yolo
tensorboard --logdir /home/jsh/yolo/runs/detect/train9 --port 6006 --bind_all
```

然后按：

```text
Ctrl-b d
```

将会话挂到后台。

------

### 5.4 检查 TensorBoard 是否已启动

```bash
ps aux | grep tensorboard
ss -lntp | grep 6006
```

如果要停止 TensorBoard：

```bash
pkill -f tensorboard
```

------

### 5.5 在本地创建 SSH 隧道

在本地电脑执行：

```powershell
ssh -L 6006:localhost:6006 jsh@192.168.0.214
```

保持这个终端不要关闭，然后在本地浏览器打开：

```text
http://localhost:6006
```

这样就可以查看服务器上的 TensorBoard 页面。

------

### 5.6 一键启动方案

#### 服务器端

```bash
conda activate yolo
nohup tensorboard --logdir /home/jsh/yolo/runs/detect/train9 --port 6006 --bind_all > /home/jsh/tensorboard.log 2>&1 &
```

#### 本地端

```powershell
ssh -f -N -L 6006:localhost:6006 jsh@192.168.0.214
```

然后浏览器访问：

```text
http://localhost:6006
```

------

## 6. 在服务器上验证模型

训练完成后，可以在服务器上执行验证命令：

```bash
yolo task=detect mode=val data=/home/jsh/yolo/datasets.yaml model=/home/jsh/yolo/runs/detect/train10/weights/best.pt imgsz=768 batch=8
```

### 验证结果示例

```text
Ultralytics 8.3.230 🚀 Python-3.11.14 torch-2.9.1+cu128 CUDA:0 (NVIDIA GeForce RTX 3090 Ti, 24110MiB)
YOLO11s summary (fused): 100 layers, 9,414,348 parameters, 0 gradients, 21.3 GFLOPs
val: Fast image access ✅
...
all        449        722      0.983      0.988      0.993      0.972
...
Results saved to /home/jsh/yolo/runs/detect/val2
```

从结果中可以重点关注：

- `P`：Precision
- `R`：Recall
- `mAP50`
- `mAP50-95`

如果这些指标满足预期，说明模型效果较好。

------

## 7. 在服务器上执行预测

训练完成后，也可以对指定目录进行推理预测：

```bash
yolo task=detect mode=predict \
  model=/home/jsh/yolo/runs/detect/train10/weights/best.pt \
  source=/home/jsh/yolo/val \
  imgsz=1280 \
  conf=0.25 \
  device=0 \
  save=True
```

说明：

- `model`：训练完成后的权重文件
- `source`：待预测图片或目录
- `imgsz=1280`：推理分辨率
- `conf=0.25`：置信度阈值
- `save=True`：保存推理结果

------

## 8. 将结果拷回本地

如果要把服务器上的训练结果下载到本地，可以使用：

```bash
scp -r jsh@192.168.0.214:/home/jsh/yolo/runs /mnt/d/Desktop/
```

说明：

- `scp -r`：递归复制目录
- `/home/jsh/yolo/runs`：服务器上的结果目录
- `/mnt/d/Desktop/`：本地目标路径

如果是在 Windows PowerShell 中执行，建议确认目标路径写法是否与当前终端环境匹配。

------

## 9. 常见注意事项

### 9.1 本地和服务器不要混淆

这是最常见的问题。
建议始终明确：

- `D:\...` 这类路径一般是本地 Windows 路径
- `/home/jsh/...` 这类路径一般是服务器 Linux 路径

### 9.2 本地主要用于测试

本地环境更适合：

- 测 GPU 是否可用
- 测训练命令是否能跑通
- 测数据集路径和配置文件是否正确

正式训练还是建议放到服务器上。

### 9.3 TensorBoard 需要事件文件

如果训练目录没有 `events.*` 文件，即使启动了 TensorBoard，页面里也不会有曲线。

### 9.4 端口转发终端不要随便关

如果你是通过：

```powershell
ssh -L 6006:localhost:6006 jsh@192.168.0.214
```

建立端口转发，那么这个终端窗口关闭后，本地浏览器也就无法继续访问 TensorBoard。

### 9.5 验证和预测是两回事

- `mode=val`：看模型在验证集上的指标
- `mode=predict`：看模型对新图片或目录的实际推理效果

两者用途不同，不要混用。

------

## 总结

这篇文档的核心主线只有一句话：

> **本地负责环境验证，服务器负责正式训练，TensorBoard 负责远程可视化，训练完成后再做验证、预测和结果回传。**

如果按这个顺序走，整个 YOLO 工作流会非常清楚：

1. 本地测试
2. 服务器训练
3. TensorBoard 监控
4. 模型验证
5. 推理预测
6. 下载结果

这样比把所有命令堆在一起更适合长期维护，也更适合发给别人直接照着做。