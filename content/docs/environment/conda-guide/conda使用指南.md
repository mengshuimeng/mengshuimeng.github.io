# Conda 基础使用指南

> 本文档用于介绍 Conda 的基础使用方法，包括换源、创建环境、激活环境、安装依赖、验证安装、退出环境和删除环境。
>
> 适用对象：初次使用 Conda 的同学，或需要快速搭建 Python 独立环境的用户
> 更新时间：2026-03-09

------

## 目录

1. 为什么要使用 Conda
2. 换源
3. 创建环境
4. 激活环境
5. 安装依赖
6. 验证安装
7. 退出环境
8. 删除环境
9. 常用命令速查
10. 注意事项

------

## 1. 为什么要使用 Conda

Conda 是一个常用的环境管理与包管理工具，适合用于：

- 为不同项目创建独立的 Python 环境
- 避免不同项目之间的依赖冲突
- 管理 Python 版本及常见第三方库

对于需要频繁切换项目、安装不同依赖版本的场景，使用 Conda 通常比直接在系统 Python 环境中安装更稳妥。

------

## 2. 换源

在国内网络环境下，直接访问官方源可能较慢，甚至出现下载失败的情况。因此，通常会将 Conda 源切换为国内镜像源，以提高下载速度和稳定性。

这里以 **清华源** 为例。清华镜像站当前推荐通过修改 `.condarc` 文件来配置默认频道和第三方频道，例如 `conda-forge`。([清华大学开源软件镜像站](https://mirrors.tuna.tsinghua.edu.cn/help/anaconda/))

### 方法一：使用命令添加频道

```bash
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
conda config --set show_channel_urls yes
```

### 方法二：直接修改 `.condarc`

Linux / macOS 路径：

```bash
~/.condarc
```

Windows 路径：

```bash
C:\Users\你的用户名\.condarc
```

参考配置如下：

```yaml
channels:
  - defaults
show_channel_urls: true

default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2

custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
```

配置完成后，建议清理索引缓存：

```bash
conda clean -i
```

------

## 3. 创建环境

建议为不同项目创建独立环境，以避免依赖冲突。

推荐命令如下：

```bash
conda create -n study python=3.10 -y
```

如果你希望安装时手动确认提示，也可以去掉 `-y`：

```bash
conda create -n study python=3.10
```

含义如下：

- `conda create`：创建新的虚拟环境
- `-n study`：指定环境名称为 `study`
- `python=3.10`：指定环境中的 Python 版本为 `3.10`
- `-y`：自动确认安装过程中的提示，无需手动输入 `y`

------

## 4. 激活环境

创建完成后，使用以下命令激活环境：

```bash
conda activate study
```

如果忘记了环境名称，可以查看已有环境：

```bash
conda env list
conda info --envs
```

------

## 5. 安装依赖

激活环境后，就可以在该环境中安装所需依赖。

这里以安装 OpenCV 为例。

### 使用 Conda 安装

```bash
conda install -c conda-forge opencv=4.5.5
```

### 使用 pip 安装

```bash
pip install opencv-python==4.5.5
```

如果下载较慢，也可以指定清华 PyPI 镜像：

```bash
pip install opencv-python==4.5.5 -i https://pypi.tuna.tsinghua.edu.cn/simple/
```

> 说明：
> `opencv=4.5.5` 属于较早但相对常见的版本；如果项目没有强依赖旧版本，也可以安装更新版本。conda-forge 上的 OpenCV 包目前仍在持续维护更新。([Anaconda](https://anaconda.org/conda-forge/opencv?utm_source=chatgpt.com))

> 建议：
> 在同一个环境中，尽量优先选择一种安装方式。若无特殊需求，最好不要频繁混用 `conda` 和 `pip`，以减少依赖冲突风险。

------

## 6. 验证安装

安装完成后，可以通过以下命令检查 OpenCV 是否安装成功：

```bash
python -c "import cv2; print(cv2.__version__)"
```

如果终端能够正确输出版本号，说明安装成功。

------

## 7. 退出环境

使用以下命令退出当前环境：

```bash
conda deactivate
```

------

## 8. 删除环境

例如，删除名为 `myenv` 的环境：

```bash
conda remove --name myenv --all
```

执行前建议先确认该环境中没有重要内容。

------

## 9. 常用命令速查

```bash
# 创建环境
conda create -n study python=3.10 -y

# 激活环境
conda activate study

# 查看所有环境
conda env list

# 安装 OpenCV
conda install -c conda-forge opencv=4.5.5

# 验证安装
python -c "import cv2; print(cv2.__version__)"

# 退出环境
conda deactivate

# 删除环境
conda remove --name myenv --all
```

------

## 10. 注意事项

### 10.1 换源后如果仍然很慢

如果使用镜像源后仍出现依赖解析慢、冲突多或安装失败的问题，优先检查以下几点：

- 当前环境是否过于复杂
- 所需包是否支持你的操作系统或平台
- 所加镜像是否已同步目标频道

清华镜像站也明确提醒，需要确认对应仓库是否同步并支持你的平台。([清华大学开源软件镜像站](https://mirrors.tuna.tsinghua.edu.cn/help/anaconda/))

### 10.2 尽量为不同项目使用不同环境

不要把所有项目都装在同一个 Conda 环境中。
更稳妥的做法是：

- 一个项目一个环境
- 一个主要依赖组合一个环境

这样后续排查问题会轻松很多。

### 10.3 换源配置属于长期生效设置

一旦完成 Conda 换源，后续大多数 Conda 操作都会默认使用该配置。
因此，换源前最好确认你使用的镜像地址是当前可用的。

------

## 总结

Conda 的基础使用流程可以概括为：

1. 换源
2. 创建环境
3. 激活环境
4. 安装依赖
5. 验证安装
6. 退出或删除环境

如果只是日常项目开发，记住下面这几条命令通常就够用了：

```bash
conda create -n study python=3.10 -y
conda activate study
conda deactivate
```

