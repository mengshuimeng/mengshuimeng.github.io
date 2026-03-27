记得，你那个应该是 **DeepSeek-OCR-2**，不是 ORC。现在你已经在 **Jetson Orin Nano + Ubuntu 22.04** 上装好了系统，下一步最重要的不是急着跑项目，而是**先把机器的硬件、CUDA、GPU、JetPack 环境摸清楚**。这一步很关键，不然后面装 PyTorch、TensorRT、ONNX Runtime 时很容易踩坑。

你直接按下面查就行。

## 一、先看 CPU、架构、内存、系统版本

### 1）查看系统版本

```bash
lsb_release -a
```

或者：

```bash
cat /etc/os-release
```

### 2）查看 CPU 架构

```bash
uname -m
```

Jetson Orin Nano 正常应该看到：

```bash
aarch64
```

这说明你是 **ARM64 架构**，不是 x86_64。
这一点非常重要，因为很多 Python wheel、torch 包、onnxruntime 包都不能乱装。

### 3）查看更完整的内核和系统信息

```bash
uname -a
```

### 4）查看 CPU 详情

```bash
lscpu
```

重点看这些字段：

- Architecture
- CPU(s)
- Model name
- Thread(s) per core
- Core(s) per socket

### 5）查看内存

```bash
free -h
```

以及：

```bash
cat /proc/meminfo | head
```

------

## 二、查看 Jetson 设备型号、JetPack、L4T 信息

这个部分才是 Jetson 平台最关键的。

### 1）查看 NVIDIA L4T 版本

```bash
cat /etc/nv_tegra_release
```

你会看到类似：

```bash
# R36 (release), REVISION: ...
```

这个信息基本能判断你当前属于哪一代 JetPack。

### 2）查看 JetPack 版本

有时可以直接这样查：

```bash
dpkg-query --show nvidia-jetpack
```

如果装了，会显示类似：

```bash
nvidia-jetpack    6.x-bxx
```

### 3）查看所有 NVIDIA 相关包

```bash
dpkg -l | grep -i nvidia
```

### 4）查看设备树中的型号

```bash
cat /proc/device-tree/model
```

通常会输出类似：

```bash
NVIDIA Jetson Orin Nano Developer Kit
```

这个命令很直接，建议你先看它。

------

## 三、查看 GPU 信息

Jetson 不是独显机器，所以**不能用桌面端那套思路硬套**。
很多人第一反应是 `nvidia-smi`，但这个在 Jetson 上通常**不能像 PC 独显那样正常用**。

### 1）先试一下 nvidia-smi

```bash
nvidia-smi
```

如果报错，不奇怪，Jetson 上经常这样。

### 2）看 GPU 运行状态，最推荐用 `tegrastats`

```bash
tegrastats
```

它会持续输出 CPU、GPU、内存、功耗、温度等信息。

比如你会看到类似：

- RAM 使用
- CPU 各核心占用
- GPU 频率 / 利用率
- 温度
- 功耗

停止的话按：

```bash
Ctrl + C
```

这个工具在 Jetson 上非常实用，后面你跑 OCR 推理时也靠它看负载。

### 3）查看 GPU 设备信息

```bash
ls /dev | grep nv
```

以及：

```bash
sudo lshw -C display
```

如果没装 `lshw`：

```bash
sudo apt update
sudo apt install lshw -y
```

### 4）查看 OpenGL / 图形渲染信息

先装工具：

```bash
sudo apt install mesa-utils -y
```

然后执行：

```bash
glxinfo | grep -E "OpenGL vendor|OpenGL renderer|OpenGL version"
```

这能帮助你确认图形栈是不是正常。

------

## 四、查看 CUDA、cuDNN、TensorRT

你既然要复现 DeepSeek-OCR-2，这部分必须查。

### 1）查看 CUDA 是否安装

```bash
nvcc -V
```

如果提示找不到命令，再查：

```bash
which nvcc
```

Jetson 上有时 CUDA 装了，但环境变量没配好。

也可以看：

```bash
ls /usr/local/
```

有没有：

```bash
cuda
cuda-12.x
```

### 2）查看 CUDA 版本文件

```bash
cat /usr/local/cuda/version.json
```

或者：

```bash
cat /usr/local/cuda/version.txt
```

### 3）查看 cuDNN

```bash
dpkg -l | grep cudnn
```

### 4）查看 TensorRT

```bash
dpkg -l | grep TensorRT
```

或者：

```bash
dpkg -l | grep tensorrt
```

### 5）查看 Python 里 CUDA 是否可用

如果你后面装了 torch，可以这样测：

```bash
python3 -c "import torch; print(torch.__version__); print(torch.cuda.is_available()); print(torch.cuda.device_count()); print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'No CUDA')"
```

注意：
Jetson 上 **PyTorch 不能随便 pip install 官方 x86 轮子**，很多情况要装 NVIDIA 提供的 ARM 版本，不然你会白折腾半天。

------

## 五、查看存储空间和磁盘情况

OCR 模型、依赖、缓存都挺占空间，这个也要看。

```bash
df -h
```

查看块设备：

```bash
lsblk
```

查看当前目录占用：

```bash
du -sh ~
```

------

## 六、查看摄像头、USB、PCIe 设备

如果你项目后面还要接相机，这部分可以顺手查。

### 1）USB 设备

```bash
lsusb
```

### 2）PCI 设备

```bash
lspci
```

如果没装：

```bash
sudo apt install pciutils -y
```

### 3）视频设备

```bash
ls /dev/video*
```

### 4）查看摄像头信息

```bash
v4l2-ctl --list-devices
```

如果没装：

```bash
sudo apt install v4l-utils -y
```

------

## 七、我建议你直接跑这一套“环境排查清单”

你可以按顺序执行这些命令：

```bash
echo "==== 系统版本 ===="
lsb_release -a

echo "==== 架构 ===="
uname -m

echo "==== 内核 ===="
uname -a

echo "==== CPU ===="
lscpu

echo "==== 内存 ===="
free -h

echo "==== 设备型号 ===="
cat /proc/device-tree/model

echo "==== L4T版本 ===="
cat /etc/nv_tegra_release

echo "==== JetPack版本 ===="
dpkg-query --show nvidia-jetpack

echo "==== CUDA版本 ===="
nvcc -V

echo "==== cuDNN ===="
dpkg -l | grep cudnn

echo "==== TensorRT ===="
dpkg -l | grep -i tensorrt

echo "==== 磁盘 ===="
df -h
```

然后再单独运行：

```bash
tegrastats
```

看实时 GPU 和整机资源。

------

## 八、如果你只是想快速确认“这台机器到底能不能跑我的 OCR 项目”

你最少确认这 6 件事：

1. `uname -m` 是不是 `aarch64`
2. `cat /proc/device-tree/model` 能不能确认是 Orin Nano
3. `dpkg-query --show nvidia-jetpack` 有没有 JetPack
4. `nvcc -V` 有没有 CUDA
5. `tegrastats` 能不能正常看到 GPU 状态
6. Python 里 `torch.cuda.is_available()` 是不是 True

只要这几项大体正常，后面就可以进入 **DeepSeek-OCR-2 在 Jetson 上的依赖适配** 阶段了。

## 九、我对你这个阶段的判断

现在别急着装一堆包。
**先做环境画像，再做依赖适配。**
因为 Jetson 最大的问题从来不是“代码不会写”，而是：

- ARM 架构包不兼容
- CUDA / torch 版本不匹配
- JetPack 版本和第三方库冲突
- 模型太重导致显存或内存不够
- x86 教程照搬到 Jetson 直接翻车

你现在做得对，先查清机器底子。

把你执行下面这几条命令的结果发我：

```bash
uname -m
cat /proc/device-tree/model
cat /etc/nv_tegra_release
dpkg-query --show nvidia-jetpack
nvcc -V
free -h
```

我可以直接帮你判断这台 Jetson Orin Nano 适合怎么配 DeepSeek-OCR-2 环境。