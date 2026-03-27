# Ubuntu 开发环境安装指南

> 本文档用于在 Ubuntu / WSL 中搭建基础 Python 开发环境，内容包括 Miniconda 安装、VS Code 安装，以及 OpenCV 环境配置。  
>
> 适用对象：需要进行 Python、计算机视觉、算法实验开发的同学  
> 作者：姜树豪（JSH）  
> 更新时间：2026-03-09

---

## 目录

1. 安装 Miniconda
2. 安装 VS Code
3. 使用 Conda 配置 OpenCV 环境
4. 常见问题
5. 常用命令速查表

---

## 1. 安装 Miniconda

Miniconda 是一个轻量级的 Python 环境管理工具，适合在 Ubuntu 中快速搭建独立开发环境。

### 1.1 先确认系统架构

```bash
uname -m
```

如果输出为：

- `x86_64`：使用 `Linux-x86_64` 安装包
- `aarch64`：使用 `Linux-aarch64` 安装包

### 1.2 安装 Miniconda（x86_64 示例）

```bash
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh
```

如果你的系统是 ARM64，请把安装包文件名改成对应架构版本。

### 1.3 激活 Conda

```bash
source ~/miniconda3/bin/activate
```

这一步很重要。
如果不执行，后面可能会出现：

```text
conda: command not found
```

### 1.4 初始化 Conda

```bash
conda init all
```

执行后重新打开终端，或者执行：

```bash
source ~/.bashrc
```

### 1.5 查看 Conda 版本

```bash
conda --version
```

------

## 2. 安装 VS Code

### 2.1 下载 VS Code 的 `.deb` 安装包

在浏览器中进入 VS Code 官网，下载 Ubuntu 对应的 `.deb` 安装包。

### 2.2 进入下载目录

例如：

```bash
cd ~/Downloads
ls
```

确认当前目录下确实存在下载好的 `.deb` 文件。

### 2.3 安装 VS Code

推荐使用：

```bash
sudo apt install ./code_*.deb
```

如果你知道具体文件名，也可以直接写完整名字：

```bash
sudo apt install ./code_x.x.x-xxxxxxxxxxxx_amd64.deb
```

### 2.4 如果依赖缺失

执行：

```bash
sudo apt --fix-broken install -y
```

------

## 3. 使用 Conda 配置 OpenCV 环境

建议优先使用 Conda 安装 OpenCV，并尽量不要在同一个环境中混用 `conda` 和 `pip`。

### 3.1 创建环境

```bash
conda create -n study python=3.10 -y
```

参数说明：

- `-n study`：环境名称为 `study`
- `python=3.10`：指定 Python 版本
- `-y`：自动确认安装过程中的提示

### 3.2 激活环境

```bash
conda activate study
```

如果忘记环境名称，可以查看：

```bash
conda env list
conda info --envs
```

### 3.3 安装 OpenCV

```bash
conda install -c conda-forge opencv=4.5.5
```

### 3.4 验证安装

```bash
python -c "import cv2; print(cv2.__version__)"
```

如果能够输出版本号，说明安装成功。

### 3.5 使用 pip 安装的写法

如果必须使用 `pip`，可以这样安装：

```bash
pip install opencv-python==4.5.5
```

如果网络较慢，也可以使用镜像源：

```bash
pip install opencv-python==4.5.5 -i https://pypi.tuna.tsinghua.edu.cn/simple/
```

### 3.6 退出环境

```bash
conda deactivate
```

------

## 4. 常见问题

### 4.1 为什么输入 `conda` 提示找不到命令

通常是因为你还没有执行：

```bash
source ~/miniconda3/bin/activate
```

或者还没有执行：

```bash
conda init all
source ~/.bashrc
```

### 4.2 为什么不建议在一个环境里混用 `conda` 和 `pip`

因为两者的依赖解析机制不同，混用后更容易出现版本冲突、包覆盖和环境异常。

### 4.3 为什么安装 OpenCV 前要先激活环境

因为你要确保 OpenCV 安装到指定虚拟环境里，而不是装到系统默认 Python 环境中。

------

## 5. 常用命令速查表

| 操作            | 命令                                                   |
| --------------- | ------------------------------------------------------ |
| 查看架构        | `uname -m`                                             |
| 安装 Miniconda  | `bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3` |
| 激活 Conda      | `source ~/miniconda3/bin/activate`                     |
| 初始化 Conda    | `conda init all`                                       |
| 查看 Conda 版本 | `conda --version`                                      |
| 创建环境        | `conda create -n study python=3.10 -y`                 |
| 激活环境        | `conda activate study`                                 |
| 查看环境        | `conda env list`                                       |
| 安装 OpenCV     | `conda install -c conda-forge opencv=4.5.5`            |
| 验证 OpenCV     | `python -c "import cv2; print(cv2.__version__)"`       |
| 退出环境        | `conda deactivate`                                     |

------

## 总结

这一篇的主线很简单：

1. 安装 Miniconda
2. 初始化 Conda
3. 安装 VS Code
4. 创建虚拟环境
5. 在虚拟环境中安装 OpenCV

只要顺着这条线做，Python 开发环境基本就搭好了。