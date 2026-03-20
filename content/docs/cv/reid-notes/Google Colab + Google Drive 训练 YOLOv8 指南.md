# Google Colab + Google Drive 训练 YOLOv8 指南

> 本文档用于说明如何在 **Google Colab** 中挂载 **Google Drive**、解压项目、配置环境、训练 YOLOv8 模型，并通过 TensorBoard 查看训练日志，最后导出训练得到的 `best.pt`。  
>
> 适用场景：  
> - 本地电脑算力不足  
> - 希望使用 Colab GPU 完成 YOLOv8 训练  
> - 希望将数据集、项目和训练结果保存在 Google Drive 中  
>
> 作者：姜树豪（JSH）  
> 更新时间：2026-03-09

---

## 参考链接 

哔哩哔哩

## 目录

1. 工作流总览
2. 挂载 Google Drive
3. 检查 Colab GPU
4. 解压项目到工作目录
5. 进入项目目录
6. 安装依赖
7. 启动 TensorBoard
8. 开始训练
9. 查看并导出 `best.pt`
10. 常见问题与注意事项

---

## 1. 工作流总览

在 Colab 中训练 YOLOv8，推荐按下面顺序执行：

1. 挂载 Google Drive  
2. 检查 GPU 是否可用  
3. 解压项目到 Colab 或 Drive  
4. 进入项目目录  
5. 安装依赖  
6. 启动 TensorBoard  
7. 执行训练  
8. 查看并保存权重文件  

Google 官方说明，Colab 可以挂载 Google Drive，让运行时直接访问 Drive 中的文件；每次连接新运行时通常都需要重新授权挂载。:contentReference[oaicite:1]{index=1}

---

## 2. 挂载 Google Drive

在 Colab 中执行：

```python
from google.colab import drive
drive.mount('/content/drive')
```

挂载成功后，Google Drive 中的文件会出现在：

```text
/content/drive/MyDrive/
```

这也是后面保存数据集、压缩包、训练结果最常用的位置。Google Colab 官方示例同样展示了这种挂载方式。([colab.research.google.com](https://colab.research.google.com/notebooks/io.ipynb?utm_source=chatgpt.com))

------

## 3. 检查 Colab GPU

先检查当前运行时是否分配了 GPU：

```python
!/opt/bin/nvidia-smi
!nvidia-smi

import torch
print('CUDA available:', torch.cuda.is_available(), 'GPU count:', torch.cuda.device_count())
```

如果输出中：

- `CUDA available: True`
- `GPU count` 大于 0

说明当前 Colab 会话已经有可用 GPU。

------

## 4. 解压项目到工作目录

### 推荐做法一：解压到 Colab 本地工作目录

这种方式训练和读写通常更快：

```python
!unzip -q "/content/drive/MyDrive/Colab Notebooks/yolov8_train.zip" -d /content/
```

如果压缩包内部本身已经包含顶层文件夹 `yolov8_train`，那么解压后目录通常会变成：

```text
/content/yolov8_train
```

### 推荐做法二：解压到 Google Drive

如果你希望项目始终保存在 Drive 里，也可以这样：

```python
!unzip -q "/content/drive/MyDrive/Colab Notebooks/yolov8_train.zip" -d "/content/drive/MyDrive/Colab Notebooks/"
```

这样解压后的目录通常会是：

```text
/content/drive/MyDrive/Colab Notebooks/yolov8_train
```

> 建议：
> **训练时优先在 `/content/` 下运行，结果再拷回 Drive。**
> 因为 Colab 本地运行目录的读写速度通常比直接在 Drive 中训练更稳。

------

## 5. 进入项目目录

这一部分必须和上一步解压路径保持一致。

### 如果你解压到 `/content/`

```python
%cd /content/yolov8_train
```

### 如果你解压到 Drive

```python
%cd "/content/drive/MyDrive/Colab Notebooks/yolov8_train"
```

进入目录后，建议先确认文件是否存在：

```python
!ls
```

------

## 6. 安装依赖

Ultralytics 官方说明，最常见的安装方式是直接用 `pip install ultralytics`，也可以通过 Git 克隆源码安装。([Ultralytics Docs](https://docs.ultralytics.com/quickstart/?utm_source=chatgpt.com))

你原稿中的安装步骤是：

```python
!pip uninstall -y ultralytics
!pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
!pip install ultralytics
!pip install -r requirements.txt --no-deps
```

这套命令不是不能用，但在 Colab 中通常**不够稳**，因为：

- Colab 运行时本身往往已经带有 PyTorch
- 强行重装 `torch` 可能和当前运行时环境不匹配
- 多次卸载 / 重装更容易引入版本冲突。([PyTorch](https://pytorch.org/get-started/previous-versions/?utm_source=chatgpt.com))

### 更稳妥的推荐写法

```python
!pip install -U ultralytics
!pip install -r requirements.txt --no-deps
```

然后验证：

```python
import torch
print('CUDA:', torch.cuda.is_available(), 'GPUs:', torch.cuda.device_count())
```

### 如果你确实需要手动装 PyTorch

只有在当前环境里的 PyTorch 明显不可用或版本不匹配时，再考虑手动安装。PyTorch 官方提供了不同 CUDA 版本的安装入口和旧版本说明。([PyTorch](https://pytorch.org/get-started/previous-versions/?utm_source=chatgpt.com))

------

## 7. 启动 TensorBoard

如果你想在 Colab 中直接查看训练曲线，可以使用 TensorBoard。

```python
%load_ext tensorboard
# %tensorboard --logdir runs/train
%tensorboard --logdir runs/detect
```

Ultralytics 的训练结果通常会保存在 `runs/detect/<实验名>` 下，所以这里写 `runs/detect` 更稳。Ultralytics 文档也说明训练结果会按任务与运行名保存在 `runs` 目录中。([Ultralytics Docs](https://docs.ultralytics.com/quickstart/?utm_source=chatgpt.com))

------

## 8. 开始训练

### 推荐写法

如果 `mydatas.yaml` 在项目根目录下：

```python
!yolo task=detect mode=train \
  data=/content/yolov8_train/mydatas.yaml \
  model=yolov8n.pt \
  epochs=300 \
  imgsz=640 \
  batch=8 \
  workers=2 \
  device=0 \
  name=colab_train
```

如果你的项目在 Drive 中，就把路径换成 Drive 对应路径。

### 参数说明

- `task=detect`：目标检测任务
- `mode=train`：训练模式
- `data=...`：数据集配置文件
- `model=yolov8n.pt`：预训练模型
- `epochs=300`：训练轮数
- `imgsz=640`：输入分辨率
- `batch=8`：批大小
- `workers=2`：数据加载线程数
- `device=0`：使用第 0 张 GPU
- `name=colab_train`：本次实验名称

------

## 9. 查看并导出 `best.pt`

训练完成后，权重文件通常会出现在：

```text
runs/detect/colab_train/weights/
```

可以查看目录内容：

```python
!ls runs/detect/colab_train/weights
```

如果一切正常，你应该会看到类似：

```text
best.pt
last.pt
```

### 拷贝到 Google Drive 保存

为了避免 Colab 断开后文件丢失，建议把权重拷贝到 Drive：

```python
!cp runs/detect/colab_train/weights/best.pt "/content/drive/MyDrive/Colab Notebooks/best.pt"
```

如果想把整个实验目录保存到 Drive：

```python
!cp -r runs/detect/colab_train "/content/drive/MyDrive/Colab Notebooks/"
```

------

## 10. 常见问题与注意事项

### 10.1 为什么挂载了 Drive 还要把项目解压到 `/content/`？

因为 `/content/` 是 Colab 当前运行时的本地工作目录，读写一般更快；
而 Google Drive 更适合用来长期保存：

- 数据集压缩包
- 训练结果
- 最终模型权重

### 10.2 为什么不建议一上来就重装 `torch`？

因为 Colab 环境本身经常已经带了可用的 PyTorch。
如果你没有先确认当前环境是否真的有问题，就直接卸载重装，反而更容易造成依赖冲突。PyTorch 社区里也多次提到，多个安装残留或反复覆盖会让 CUDA 识别异常。([PyTorch Forums](https://discuss.pytorch.org/t/cuda-version-is-always-10-2/152876?utm_source=chatgpt.com))

### 10.3 TensorBoard 没有曲线怎么办？

优先检查：

1. 训练是否真的开始了
2. 日志目录是否写对了
3. `runs/detect/colab_train` 下是否生成了事件文件

### 10.4 为什么 `best.pt` 找不到？

通常有几种原因：

- 训练还没结束
- 训练报错提前中断
- `name` 不是 `colab_train`
- 实际输出目录不是你以为的那个路径

建议先执行：

```python
!find runs -name best.pt
```

直接搜索。

### 10.5 Colab 断开后文件会不会丢？

如果文件只保存在 `/content/` 下，运行时断开后通常会丢失。
所以训练完成后，建议立刻把：

- `best.pt`
- `last.pt`
- `runs/detect/colab_train`

拷贝回 Google Drive。Google Colab 官方也明确说明 Drive 挂载后可用于读写持久化文件。([colab.research.google.com](https://colab.research.google.com/notebooks/io.ipynb?utm_source=chatgpt.com))

------

## 总结

这篇文档的主线可以浓缩成一句话：

> **Google Drive 负责存储，Colab 负责训练，训练完成后再把结果拷回 Drive。**

推荐的稳定流程是：

1. 挂载 Drive
2. 检查 GPU
3. 把项目解压到 `/content/`
4. 进入项目目录
5. 安装 `ultralytics` 和项目依赖
6. 启动 TensorBoard
7. 训练模型
8. 将 `best.pt` 拷回 Drive

这样比直接把所有东西都堆在 Drive 里训练更稳，也更容易排错。
