---
title: DeepSeek OCR 2 运行记录
description: DeepSeek OCR 2 的运行过程与命令记录
slug: deepseek-ocr2-runtime-notes
aliases:
  - /docs/ai/deepseekorc1/
  - /docs/AI/deepseekORC1/
  - /docs/AI/DeepseekORC11/
---

 **DeepSeek-OCR-2**

```shell
root@Jiang:/home/jj/DeepSeek-OCR-2# su - jj
(base) jj@Jiang:~$ conda env liost
usage: conda env [-h] command ...
conda env: error: argument command: invalid choice: 'liost' (choose from config, create, export, list, remove, update)
(base) jj@Jiang:~$ conda env list

# conda environments:
#
# * -> active
# + -> frozen
base                 *   /home/jj/miniconda3
deepseek-ocr2            /home/jj/miniconda3/envs/deepseek-ocr2
deepseek-stable          /home/jj/miniconda3/envs/deepseek-stable
math-video               /home/jj/miniconda3/envs/math-video

(base) jj@Jiang:~$ conda activate deepseek-stable
(deepseek-stable) jj@Jiang:~$ ls
DeepSeek-OCR-2  RL  math_video_solver  miniconda3  openclaw
(deepseek-stable) jj@Jiang:~$ cd DeepSeek-OCR-2/
(deepseek-stable) jj@Jiang:~/DeepSeek-OCR-2$ ls
DeepSeek-OCR2-master     README.md                   data              testtransfer.py
DeepSeek_OCR2_paper.pdf  assets                      requirements.txt  vllm-0.8.5+cu118-cp38-abi3-manylinux1_x86_64.whl
LICENSE.txt              cuda-keyring_1.1-1_all.deb  test.py           vllm-0.8.5+cu121-cp38-abi3-manylinux1_x86_64.whl
(deepseek-stable) jj@Jiang:~/DeepSeek-OCR-2$ python video_math_solver_final.py videos/4.mp
 *  History restored 

root@Jiang:/home/jj/DeepSeek-OCR-2# *
DeepSeek-OCR2-master: command not found
root@Jiang:/home/jj/DeepSeek-OCR-2# 
```









> Our environment is cuda11.8+torch2.6.0.

1. Clone this repository and navigate to the DeepSeek-OCR-2 folder

```
git clone https://github.com/deepseek-ai/DeepSeek-OCR-2.git
```



1. Conda

```
conda create -n deepseek-ocr2 python=3.12.9 -y
conda activate deepseek-ocr2
```



1. Packages

- download the vllm-0.8.5 [whl](https://github.com/vllm-project/vllm/releases/tag/v0.8.5)

```
wget https://github.com/vllm-project/vllm/releases/download/v0.8.5/vllm-0.8.5+cu118-cp38-abi3-manylinux1_x86_64.whl
```

cu118

cu1215060





cu

```
# The current PyTorch install supports CUDA capabilities sm_50 sm_60 sm_70 sm_75 sm_80 sm_86 sm_37 sm_90.

pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu118
pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://mirrors.tuna.tsinghua.edu.cn/simple
pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://mirror.sjtu.edu.cn/pytorch-wheels/cu118
pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://mirrors.aliyun.com/pypi/simple/

pip install vllm-0.8.5+cu118-cp38-abi3-manylinux1_x86_64.whl
pip install -r requirements.txt --index-url https://mirrors.aliyun.com/pypi/simple/

#如果没有whl 要安装这个
#pip install psutil
#pip install cmake 
#sudo apt-get install -y build-essential cmake ninja-build
pip install flash-attn==2.7.3 --no-build-isolation
```

**Note:** if you want vLLM and transformers codes to run in the same environment, you don't need to worry about this installation error like: vllm 0.8.5+cu118 requires transformers>=4.51.1







**第二步：确认系统级 CUDA 开发工具（重要）**

```
nvcc --version
gcc --version
nvidia-smi
```



1. **添加 NVIDIA 仓库密钥和源** (如果之前没加过)：

   ```
   wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
   sudo dpkg -i cuda-keyring_1.1-1_all.deb
   sudo apt-get update
   ```

   *(注：如果你用的是 Ubuntu 20.04，将上面的 `ubuntu2204` 改为 `ubuntu2004`)*

2. **安装 CUDA 11.8 Toolkit**：
   我们只需要安装 `cuda-toolkit-11-8`，不需要安装巨大的驱动包（WSL 通常共用 Windows 的驱动）。

   ```
   sudo apt-get install -y cuda-toolkit-11-8
   sudo apt-get install -y cuda-toolkit-12-4
   ```

   *这一步可能需要几分钟，它会安装 `nvcc` 编译器。*




   如果输出了版本号（例如 `Cuda compilation tools, release 11.8...`），说明成功了。

### **第二步：设置环境变量**

即使安装了工具，Python 编译脚本有时也找不到路径，需要手动指定 `CUDA_HOME`。

1. **临时设置（当前终端有效）**：

   ```
   export CUDA_HOME=/usr/local/cuda-11.8
   export PATH=$CUDA_HOME/bin:$PATH
   
   export CUDA_HOME=/usr/local/cuda-12.4
   export PATH=$CUDA_HOME/bin:$PATH
   ```

   *(如果 `/usr/local/cuda-11.8` 不存在，尝试 `ls /usr/local/` 看看 cuda 具体安装在哪个文件夹，通常是 `cuda-11.8` 或 `cuda`)*

2. **永久设置（推荐）**：
   为了避免每次打开终端都要输入，将其写入 `~/.bashrc`：

   ```
   echo 'export CUDA_HOME=/usr/local/cuda-11.8' >> ~/.bashrc
   echo 'export PATH=$CUDA_HOME/bin:$PATH' >> ~/.bashrc
   source ~/.bashrc
   
   echo 'export CUDA_HOME=/usr/local/cuda-12.4' >> ~/.bashrc
   echo 'export PATH=$CUDA_HOME/bin:$PATH' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **验证安装**：
   安装完成后，检查 `nvcc` 是否可用：

   ```
   nvcc --version
   gcc --version
   nvidia-smi
   ```

修改`config.py`

(deepseek-ocr2) gpu@9gpu-com:~/Downloads/DeepSeek-OCR-2$ python3 -c "import torch; print(f'PyTorch Version: {torch.__version__}'); print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'GPU Name: {torch.cuda.get_device_name(0)}')"
PyTorch Version: 2.6.0+cu124
CUDA Available: True
GPU Name: NVIDIA GeForce RTX 3090


## vLLM-Inference



- VLLM:

> **Note:** change the INPUT_PATH/OUTPUT_PATH and other settings in the DeepSeek-OCR2-master/DeepSeek-OCR2-vllm/config.py

```
cd DeepSeek-OCR2-master/DeepSeek-OCR2-vllm
```



1. image: streaming output

```
python run_dpsk_ocr2_image.py
```



1. pdf: concurrency (on-par speed with DeepSeek-OCR)

```
python run_dpsk_ocr2_pdf.py
```



1. batch eval for benchmarks (i.e., OmniDocBench v1.5)

```
python run_dpsk_ocr2_eval_batch.py
```





XAIZAI DEB
sudo apt install -y ./Clash.Verge_2.4.6_amd64.deb 


XIAZAIGIT
sudo apt install git

conda 
1. 下载最新版的 Miniconda 安装脚本
我们使用清华大学的镜像源，速度快且稳定。
(注：以下命令会下载最新的 Python 3.x 版本 Miniconda)
bash

cd ~

# 使用 wget 下载 (如果 wget 不可用，请先尝试 apt install wget，若 apt 仍报错则用 curl)

wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh -O Miniconda3-latest-Linux-x86_64.sh


# 如果 wget 也报错，请改用 curl:

# curl -O https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh

2. 验证文件完整性（可选但推荐）
确保下载的文件没有损坏：
bash

sha256sum Miniconda3-latest-Linux-x86_64.sh

(您可以去清华源网页核对一下输出的哈希值，通常只要下载过程没报错，大概率是好的)
3. 运行安装脚本
bash

bash Miniconda3-latest-Linux-x86_64.sh

安装过程中的交互提示：

    许可协议：出现 Do you accept the license terms? [yes|no] 时，输入 yes 并回车。
    安装路径：出现 Installation path [/home/gpu/miniconda3] 时：
        直接回车使用默认路径（推荐：/home/gpu/miniconda3）。
        或者输入自定义路径（确保该用户有写入权限）。
    初始化 Conda：出现 Do you wish the installer to initialize Miniconda3 by running conda init? [yes|no] 时，务必输入 yes 并回车。
        这一步会自动修改您的 ~/.bashrc 文件，让您在任何终端都能使用 conda 命令。

4. 激活环境
安装完成后，让配置立即生效：
bash

source ~/.bashrc

5. 验证安装
输入以下命令，如果出现版本号且没有报错，说明安装成功：
bash

conda --version

输出示例：conda 24.x.x
⚙️ 后续优化：配置 Conda 使用清华源
为了避免以后 conda install 包时速度慢或连接超时，建议将 conda 的默认源也改为清华镜像：
bash

# 添加清华源

conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main

conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r

conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge


# 显示源地址（确认是否添加成功）

conda config --show channels

💡 常见问题排查


conda --version




