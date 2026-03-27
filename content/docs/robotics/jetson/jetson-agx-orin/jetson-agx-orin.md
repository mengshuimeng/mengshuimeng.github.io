# 🚀 一、Jetson AGX Orin 内核定制与烧录指南（基于 R36.4.3）

---

## 📚 开发手册链接

[NVIDIA 官方开发者手册（R36.4.3）](https://docs.nvidia.com/jetson/archives/r36.4.3/DeveloperGuide/index.html)


> ⚠️ **注意版本匹配！**  
> 如图所示，当前手册版本为 **36.4.3**，请务必使用对应版本的手册与工具包，不同版本间存在关键性操作差异，即便是相近版本也不可忽略。

![版本确认](assets/1.png)

---

## 📦 获取 SDK 与源码包

在手册多个位置均提供 SDK 下载链接。可通过如下方式跳转获取：

![跳转位置1](assets/2.png)  
![跳转位置2](assets/3.png)

请下载下图中圈选的 **三个软件包**：

![需下载的软件包](assets/4.png)

---

## 📁 解压预编译文件

依次执行以下命令完成预编译文件的准备：

```bash
tar xf ${L4T_RELEASE_PACKAGE}
sudo tar xpf ${SAMPLE_FS_PACKAGE} -C Linux_for_Tegra/rootfs/
cd Linux_for_Tegra/
sudo ./tools/l4t_flash_prerequisites.sh
sudo ./apply_binaries.sh
```

---

## 🔧 开始内核定制

> 按开发手册步骤操作，如下为关键命令汇总：

```bash
# 建议国内用户手动解压源码包
tar xf public_sources.tbz2 -C <install-path>/Linux_for_Tegra/..

cd <install-path>/Linux_for_Tegra/source
tar xf kernel_src.tbz2
tar xf kernel_oot_modules_src.tbz2
tar xf nvidia_kernel_display_driver_source.tbz2

# 编辑 defconfig 配置内核
vi <install-path>/Linux_for_Tegra/source/kernel/kernel-jammy-src/arch/arm64/configs/defconfig

cd <install-path>/Linux_for_Tegra/source/

# 启用实时配置（可选）
./generic_rt_build.sh "enable"

# 编译内核
export CROSS_COMPILE=<toolchain-path>/bin/aarch64-buildroot-linux-gnu-
make -C kernel

# 安装内核模块
export INSTALL_MOD_PATH=<install-path>/Linux_for_Tegra/rootfs/
sudo -E make install -C kernel

# 拷贝生成的 Image
cp kernel/kernel-jammy-src/arch/arm64/boot/Image \
  <install-path>/Linux_for_Tegra/kernel/Image

# 配置显示驱动与 RT 兼容性变量（如使用 RT 内核）
export IGNORE_PREEMPT_RT_PRESENCE=1

# 编译驱动模块
export KERNEL_HEADERS=$PWD/kernel/kernel-jammy-src
make modules

# 安装驱动模块
export INSTALL_MOD_PATH=<install-path>/Linux_for_Tegra/rootfs/
sudo -E make modules_install

# 更新 initrd
cd <install-path>/Linux_for_Tegra
sudo ./tools/l4t_update_initrd.sh

# 编译设备树
cd <install-path>/Linux_for_Tegra/source
make dtbs
cp kernel-devicetree/generic-dts/dtbs/* <install-path>/Linux_for_Tegra/kernel/dtb/
```

---

## 💾 烧录到 eMMC

> 请根据 Quick Start 指南中的指令操作。  
> 推荐使用以下方法进入 **Recovery 模式**：

![进入Recovery方式1](assets/5.png)  
![进入Recovery方式2](assets/6.png)

在 **R36.4.3** 版本下，执行以下命令进行烧录：

```bash
sudo ./flash.sh jetson-agx-orin-devkit internal
```

---

## 🚀 二、Jetson Orin AGX 上安装 GPU 加速的 PyTorch（JetPack 6.2）

SDK Manager给你装的torch是不可用的，所以还得自己装。以下是针对 Jetson Orin AGX 上安装支持 GPU 加速的 PyTorch（适用于 JetPack 6.2 和 CUDA 12.6）的详细指南。 ([PyTorch and TorchVision for Jetpack 6.2 - NVIDIA Developer Forums](https://forums.developer.nvidia.com/t/pytorch-and-torchvision-for-jetpack-6-2/325257?utm_source=chatgpt.com))

### 📋 系统要求

- **JetPack 版本**：6.2（L4T 36.4.3） 
- **CUDA 版本**：12.6
- **Python 版本**：3.10（建议）
- **cuDNN 版本**：9.3.0.75 ([Yolo incompatible with Jetpack 6.2(Jetson Orin Nano Super) #18829](https://github.com/ultralytics/ultralytics/issues/18829?utm_source=chatgpt.com))


我们的orin实际上装的是：
```bash
Package: nvidia-jetpack
Source: nvidia-jetpack (6.1)
Version: 6.1+b123
Architecture: arm64
Maintainer: NVIDIA Corporation
Installed-Size: 194
Depends: nvidia-jetpack-runtime (= 6.1+b123), nvidia-jetpack-dev (= 6.1+b123)
| NVIDIA-SMI 540.4.0                Driver Version: 540.4.0      CUDA Version: 12.6     |
```
---

### ✅ 安装步骤

#### 1. 安装系统依赖

```bash
sudo apt update
sudo apt install python3-pip libopenblas-base libopenmpi-dev libomp-dev
```


#### 2. 安装 cuSPARSELt（适用于 PyTorch 2.6.0 及以上版本） 可跳过



```bash
wget https://developer.download.nvidia.com/compute/cusparselt/redist/libcusparse_lt/linux-aarch64/libcusparse_lt-linux-aarch64-0.6.3.2-archive.tar.xz
tar xf libcusparse_lt-linux-aarch64-0.6.3.2-archive.tar.xz
cd libcusparse_lt-linux-aarch64-0.6.3.2-archive
sudo cp -a include/* /usr/local/cuda/include/
sudo cp -a lib/* /usr/local/cuda/lib64/
```


#### 3. 下载并安装 PyTorch、TorchVision 和 TorchAudio


建议到这个网站直接去下载:
```angular2
https://forums.developer.nvidia.com/t/pytorch-for-jetson/72048
```


```bash
# 安装 numpy（确保版本兼容）
pip3 install 'numpy<2' 我们实际使用时1.24.4 因为有别的依赖包

# 下载 PyTorch、TorchVision 和 TorchAudio 的 wheel 文件
wget https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/6cc/6ecfe8a5994fd/torch-2.6.0-cp310-cp310-linux_aarch64.whl
wget https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/aa2/2da8dcf4c4c8d/torchvision-0.21.0-cp310-cp310-linux_aarch64.whl
wget https://pypi.jetson-ai-lab.dev/jp6/cu126/+f/dda/ce98dc7d89263/torchaudio-2.6.0-cp310-cp310-linux_aarch64.whl

# 安装上述 wheel 文件
pip3 install --force --no-cache-dir torch-2.6.0-cp310-cp310-linux_aarch64.whl
pip3 install --force --no-cache-dir torchvision-0.21.0-cp310-cp310-linux_aarch64.whl
pip3 install --force --no-cache-dir torchaudio-2.6.0-cp310-cp310-linux_aarch64.whl
```


#### 4. 验证安装

```bash
python3
>>> import torch
>>> print(torch.__version__)  # 应输出 '2.3.0'
>>> print(torch.cuda.is_available())  # 应输出 True
>>> print(torch.cuda.get_device_name(0))  # 应输出 'Orin'
>>> import torchvision
>>> import torchaudio
```


---

### ⚠️ 常见问题及解决方案

#### 问题 1：`torch.cuda.is_available()` 返回 False

**可能原因**：

- CUDA 未正确安装或未配置环境变量
- 安装了不支持 CUDA 的 PyTorch 版本 ([[OLD JP5.*] 1. Installing Torch (with CUDA) on NVIDIA Jetson Orin ...](https://crankycyb.org/installing-torch-with-cuda-on-nvidia-jetson-orin-nano-50178bed7416?utm_source=chatgpt.com))

**解决方案**：

- 确保已安装 JetPack 6.2，并且 CUDA 12.6 正确配置
- 使用上述提供的 wheel 文件安装支持 CUDA 的 PyTorch 版本 ([Overview — Torch-TensorRT v2.8.0.dev0+3b30409 documentation](https://pytorch.org/TensorRT/getting_started/jetpack.html?utm_source=chatgpt.com), [Set Up Pytorch Environment on Nvidia Jetson Platform - Medium](https://medium.com/%40yixiaozengprc/set-up-pytorch-environment-on-nvidia-jetson-platform-9eda291db716?utm_source=chatgpt.com))

#### 问题 2：安装 TorchVision 后，`torch` 版本变为 CPU 版本

**可能原因**：

- TorchVision 的安装覆盖了之前的 PyTorch 安装

**解决方案**：

- 确保使用与 PyTorch 版本兼容的 TorchVision wheel 文件
- 重新安装支持 CUDA 的 PyTorch wheel 文件 ([Pytorch-CUDA 11.8 for Jetson Orin AGX](https://discuss.pytorch.org/t/pytorch-cuda-11-8-for-jetson-orin-agx/183688?utm_source=chatgpt.com))

#### 问题 3：`RuntimeError: operator torchvision::nms does not exist`

**可能原因**：

- TorchVision 安装不完整或版本不兼容

**解决方案**：

- 确保安装的 TorchVision 版本与 PyTorch 版本兼容
- 重新安装正确版本的 TorchVision wheel 文件

---

### 📌 附加建议

- 建议使用 Python 3.10，以确保与提供的 wheel 文件兼容
- 安装过程中使用 `--no-cache-dir` 选项，以避免使用缓存的旧版本
- 安装完成后，使用 `torch.cuda.is_available()` 验证 GPU 是否可用

---

如需进一步的帮助或有其他问题，欢迎查阅 [NVIDIA 官方文档](https://docs.nvidia.com/deeplearning/frameworks/install-pytorch-jetson-platform/index.html) 或在相关论坛中提问。 