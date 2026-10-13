---
title: "Ultralytics 网络模块源码阅读笔记"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "YOLO"
  - "代码阅读"
---

`ultralytics/nn/modules/block.py`

```python
# Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license
"""Block modules."""

from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F

from ultralytics.utils.torch_utils import fuse_conv_and_bn

from .conv import Conv, DWConv, GhostConv, LightConv, RepConv, autopad
from .transformer import TransformerBlock

__all__ = (
    "C1",
    "C2",
    "C2PSA",
    "C3",
    "C3TR",
    "CIB",
    "DFL",
    "ELAN1",
    "PSA",
    "SPP",
    "SPPELAN",
    "SPPF",
    "AConv",
    "ADown",
    "Attention",
    "BNContrastiveHead",
    "Bottleneck",
    "BottleneckCSP",
    "C2f",
    "C2fAttn",
    "C2fCIB",
    "C2fPSA",
    "SEBlock",
    "C3Ghost",
    "C3k2",
    "C3x",
    "CBFuse",
    "CBLinear",
    "ContrastiveHead",
    "GhostBottleneck",
    "HGBlock",
    "HGStem",
    "ImagePoolingAttn",
    "Proto",
    "RepC3",
    "RepNCSPELAN4",
    "RepVGGDW",
    "ResNetLayer",
    "SCDown",
    "TorchVision",
)


class DFL(nn.Module):
    """Integral module of Distribution Focal Loss (DFL).

    Proposed in Generalized Focal Loss https://ieeexplore.ieee.org/document/9792391
    """

    def __init__(self, c1: int = 16):
        """Initialize a convolutional layer with a given number of input channels.

        Args:
            c1 (int): Number of input channels.
        """
        super().__init__()
        self.conv = nn.Conv2d(c1, 1, 1, bias=False).requires_grad_(False)
        x = torch.arange(c1, dtype=torch.float)
        self.conv.weight.data[:] = nn.Parameter(x.view(1, c1, 1, 1))
        self.c1 = c1

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Apply the DFL module to input tensor and return transformed output."""
        b, _, a = x.shape  # batch, channels, anchors
        return self.conv(x.view(b, 4, self.c1, a).transpose(2, 1).softmax(1)).view(b, 4, a)
        # return self.conv(x.view(b, self.c1, 4, a).softmax(1)).view(b, 4, a)


class Proto(nn.Module):
    """Ultralytics YOLO models mask Proto module for segmentation models."""

    def __init__(self, c1: int, c_: int = 256, c2: int = 32):
        """Initialize the Ultralytics YOLO models mask Proto module with specified number of protos and masks.

        Args:
            c1 (int): Input channels.
            c_ (int): Intermediate channels.
            c2 (int): Output channels (number of protos).
        """
        super().__init__()
        self.cv1 = Conv(c1, c_, k=3)
        self.upsample = nn.ConvTranspose2d(c_, c_, 2, 2, 0, bias=True)  # nn.Upsample(scale_factor=2, mode='nearest')
        self.cv2 = Conv(c_, c_, k=3)
        self.cv3 = Conv(c_, c2)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Perform a forward pass through layers using an upsampled input image."""
        return self.cv3(self.cv2(self.upsample(self.cv1(x))))


class HGStem(nn.Module):
    """StemBlock of PPHGNetV2 with 5 convolutions and one maxpool2d.

    https://github.com/PaddlePaddle/PaddleDetection/blob/develop/ppdet/modeling/backbones/hgnet_v2.py
    """

    def __init__(self, c1: int, cm: int, c2: int):
        """Initialize the StemBlock of PPHGNetV2.

        Args:
            c1 (int): Input channels.
            cm (int): Middle channels.
            c2 (int): Output channels.
        """
        super().__init__()
        self.stem1 = Conv(c1, cm, 3, 2, act=nn.ReLU())
        self.stem2a = Conv(cm, cm // 2, 2, 1, 0, act=nn.ReLU())
        self.stem2b = Conv(cm // 2, cm, 2, 1, 0, act=nn.ReLU())
        self.stem3 = Conv(cm * 2, cm, 3, 2, act=nn.ReLU())
        self.stem4 = Conv(cm, c2, 1, 1, act=nn.ReLU())
        self.pool = nn.MaxPool2d(kernel_size=2, stride=1, padding=0, ceil_mode=True)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass of a PPHGNetV2 backbone layer."""
        x = self.stem1(x)
        x = F.pad(x, [0, 1, 0, 1])
        x2 = self.stem2a(x)
        x2 = F.pad(x2, [0, 1, 0, 1])
        x2 = self.stem2b(x2)
        x1 = self.pool(x)
        x = torch.cat([x1, x2], dim=1)
        x = self.stem3(x)
        x = self.stem4(x)
        return x


class HGBlock(nn.Module):
    """HG_Block of PPHGNetV2 with 2 convolutions and LightConv.

    https://github.com/PaddlePaddle/PaddleDetection/blob/develop/ppdet/modeling/backbones/hgnet_v2.py
    """

    def __init__(
        self,
        c1: int,
        cm: int,
        c2: int,
        k: int = 3,
        n: int = 6,
        lightconv: bool = False,
        shortcut: bool = False,
        act: nn.Module = nn.ReLU(),
    ):
        """Initialize HGBlock with specified parameters.

        Args:
            c1 (int): Input channels.
            cm (int): Middle channels.
            c2 (int): Output channels.
            k (int): Kernel size.
            n (int): Number of LightConv or Conv blocks.
            lightconv (bool): Whether to use LightConv.
            shortcut (bool): Whether to use shortcut connection.
            act (nn.Module): Activation function.
        """
        super().__init__()
        block = LightConv if lightconv else Conv
        self.m = nn.ModuleList(block(c1 if i == 0 else cm, cm, k=k, act=act) for i in range(n))
        self.sc = Conv(c1 + n * cm, c2 // 2, 1, 1, act=act)  # squeeze conv
        self.ec = Conv(c2 // 2, c2, 1, 1, act=act)  # excitation conv
        self.add = shortcut and c1 == c2

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass of a PPHGNetV2 backbone layer."""
        y = [x]
        y.extend(m(y[-1]) for m in self.m)
        y = self.ec(self.sc(torch.cat(y, 1)))
        return y + x if self.add else y


class SPP(nn.Module):
    """Spatial Pyramid Pooling (SPP) layer https://arxiv.org/abs/1406.4729."""

    def __init__(self, c1: int, c2: int, k: tuple[int, ...] = (5, 9, 13)):
        """Initialize the SPP layer with input/output channels and pooling kernel sizes.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            k (tuple): Kernel sizes for max pooling.
        """
        super().__init__()
        c_ = c1 // 2  # hidden channels
        self.cv1 = Conv(c1, c_, 1, 1)
        self.cv2 = Conv(c_ * (len(k) + 1), c2, 1, 1)
        self.m = nn.ModuleList([nn.MaxPool2d(kernel_size=x, stride=1, padding=x // 2) for x in k])

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass of the SPP layer, performing spatial pyramid pooling."""
        x = self.cv1(x)
        return self.cv2(torch.cat([x] + [m(x) for m in self.m], 1))


class SPPF(nn.Module):
    """Spatial Pyramid Pooling - Fast (SPPF) layer for YOLOv5 by Glenn Jocher."""

    def __init__(self, c1: int, c2: int, k: int = 5, n: int = 3, shortcut: bool = False):
        """Initialize the SPPF layer with given input/output channels and kernel size.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            k (int): Kernel size.
            n (int): Number of pooling iterations.
            shortcut (bool): Whether to use shortcut connection.

        Notes:
            This module is equivalent to SPP(k=(5, 9, 13)).
        """
        super().__init__()
        c_ = c1 // 2  # hidden channels
        self.cv1 = Conv(c1, c_, 1, 1, act=False)
        self.cv2 = Conv(c_ * (n + 1), c2, 1, 1)
        self.m = nn.MaxPool2d(kernel_size=k, stride=1, padding=k // 2)
        self.n = n
        self.add = shortcut and c1 == c2

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Apply sequential pooling operations to input and return concatenated feature maps."""
        y = [self.cv1(x)]
        y.extend(self.m(y[-1]) for _ in range(getattr(self, "n", 3)))
        y = self.cv2(torch.cat(y, 1))
        return y + x if getattr(self, "add", False) else y


class C1(nn.Module):
    """CSP Bottleneck with 1 convolution."""

    def __init__(self, c1: int, c2: int, n: int = 1):
        """Initialize the CSP Bottleneck with 1 convolution.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of convolutions.
        """
        super().__init__()
        self.cv1 = Conv(c1, c2, 1, 1)
        self.m = nn.Sequential(*(Conv(c2, c2, 3) for _ in range(n)))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Apply convolution and residual connection to input tensor."""
        y = self.cv1(x)
        return self.m(y) + y


class C2(nn.Module):
    """CSP Bottleneck with 2 convolutions."""

    def __init__(self, c1: int, c2: int, n: int = 1, shortcut: bool = True, g: int = 1, e: float = 0.5):
        """Initialize a CSP Bottleneck with 2 convolutions.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of Bottleneck blocks.
            shortcut (bool): Whether to use shortcut connections.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__()
        self.c = int(c2 * e)  # hidden channels
        self.cv1 = Conv(c1, 2 * self.c, 1, 1)
        self.cv2 = Conv(2 * self.c, c2, 1)  # optional act=FReLU(c2)
        # self.attention = ChannelAttention(2 * self.c)  # or SpatialAttention()
        self.m = nn.Sequential(*(Bottleneck(self.c, self.c, shortcut, g, k=((3, 3), (3, 3)), e=1.0) for _ in range(n)))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through the CSP bottleneck with 2 convolutions."""
        a, b = self.cv1(x).chunk(2, 1)
        return self.cv2(torch.cat((self.m(a), b), 1))


class C2f(nn.Module):
    """Faster Implementation of CSP Bottleneck with 2 convolutions."""

    def __init__(self, c1: int, c2: int, n: int = 1, shortcut: bool = False, g: int = 1, e: float = 0.5):
        """Initialize a CSP bottleneck with 2 convolutions.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of Bottleneck blocks.
            shortcut (bool): Whether to use shortcut connections.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__()
        self.c = int(c2 * e)  # hidden channels
        self.cv1 = Conv(c1, 2 * self.c, 1, 1)
        self.cv2 = Conv((2 + n) * self.c, c2, 1)  # optional act=FReLU(c2)
        self.m = nn.ModuleList(Bottleneck(self.c, self.c, shortcut, g, k=((3, 3), (3, 3)), e=1.0) for _ in range(n))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through C2f layer."""
        y = list(self.cv1(x).chunk(2, 1))
        y.extend(m(y[-1]) for m in self.m)
        return self.cv2(torch.cat(y, 1))

    def forward_split(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass using split() instead of chunk()."""
        y = self.cv1(x).split((self.c, self.c), 1)
        y = [y[0], y[1]]
        y.extend(m(y[-1]) for m in self.m)
        return self.cv2(torch.cat(y, 1))


class SEBlock(nn.Module):
    """Squeeze-and-Excitation block for paper reproduction."""

    def __init__(self, c1: int, c2: int | None = None, reduction: int = 4):
        """Initialize an SEBlock that preserves feature shape for paper reproduction."""
        super().__init__()
        c2 = c1 if c2 is None else c2
        if c1 != c2:
            raise ValueError("SEBlock requires matching input and output channels for paper reproduction.")

        c_ = max(c1 // reduction, 1)
        self.pool = nn.AdaptiveAvgPool2d(1)
        self.fc = nn.Sequential(
            nn.Conv2d(c1, c_, 1, 1, 0, bias=True),
            nn.SiLU(inplace=True),
            nn.Conv2d(c_, c1, 1, 1, 0, bias=True),
            nn.Sigmoid(),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Scale channels with squeeze-and-excitation weights."""
        return x * self.fc(self.pool(x))


class C3(nn.Module):
    """CSP Bottleneck with 3 convolutions."""

    def __init__(self, c1: int, c2: int, n: int = 1, shortcut: bool = True, g: int = 1, e: float = 0.5):
        """Initialize the CSP Bottleneck with 3 convolutions.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of Bottleneck blocks.
            shortcut (bool): Whether to use shortcut connections.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__()
        c_ = int(c2 * e)  # hidden channels
        self.cv1 = Conv(c1, c_, 1, 1)
        self.cv2 = Conv(c1, c_, 1, 1)
        self.cv3 = Conv(2 * c_, c2, 1)  # optional act=FReLU(c2)
        self.m = nn.Sequential(*(Bottleneck(c_, c_, shortcut, g, k=((1, 1), (3, 3)), e=1.0) for _ in range(n)))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through the CSP bottleneck with 3 convolutions."""
        return self.cv3(torch.cat((self.m(self.cv1(x)), self.cv2(x)), 1))


class C3x(C3):
    """C3 module with cross-convolutions."""

    def __init__(self, c1: int, c2: int, n: int = 1, shortcut: bool = True, g: int = 1, e: float = 0.5):
        """Initialize C3 module with cross-convolutions.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of Bottleneck blocks.
            shortcut (bool): Whether to use shortcut connections.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__(c1, c2, n, shortcut, g, e)
        self.c_ = int(c2 * e)
        self.m = nn.Sequential(*(Bottleneck(self.c_, self.c_, shortcut, g, k=((1, 3), (3, 1)), e=1) for _ in range(n)))


class RepC3(nn.Module):
    """Rep C3."""

    def __init__(self, c1: int, c2: int, n: int = 3, e: float = 1.0):
        """Initialize RepC3 module with RepConv blocks.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of RepConv blocks.
            e (float): Expansion ratio.
        """
        super().__init__()
        c_ = int(c2 * e)  # hidden channels
        self.cv1 = Conv(c1, c_, 1, 1)
        self.cv2 = Conv(c1, c_, 1, 1)
        self.m = nn.Sequential(*[RepConv(c_, c_) for _ in range(n)])
        self.cv3 = Conv(c_, c2, 1, 1) if c_ != c2 else nn.Identity()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass of RepC3 module."""
        return self.cv3(self.m(self.cv1(x)) + self.cv2(x))


class C3TR(C3):
    """C3 module with TransformerBlock()."""

    def __init__(self, c1: int, c2: int, n: int = 1, shortcut: bool = True, g: int = 1, e: float = 0.5):
        """Initialize C3 module with TransformerBlock.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of Transformer blocks.
            shortcut (bool): Whether to use shortcut connections.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__(c1, c2, n, shortcut, g, e)
        c_ = int(c2 * e)
        self.m = TransformerBlock(c_, c_, 4, n)


class C3Ghost(C3):
    """C3 module with GhostBottleneck()."""

    def __init__(self, c1: int, c2: int, n: int = 1, shortcut: bool = True, g: int = 1, e: float = 0.5):
        """Initialize C3 module with GhostBottleneck.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of Ghost bottleneck blocks.
            shortcut (bool): Whether to use shortcut connections.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__(c1, c2, n, shortcut, g, e)
        c_ = int(c2 * e)  # hidden channels
        self.m = nn.Sequential(*(GhostBottleneck(c_, c_) for _ in range(n)))


class GhostBottleneck(nn.Module):
    """Ghost Bottleneck https://github.com/huawei-noah/Efficient-AI-Backbones."""

    def __init__(self, c1: int, c2: int, k: int = 3, s: int = 1):
        """Initialize Ghost Bottleneck module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            k (int): Kernel size.
            s (int): Stride.
        """
        super().__init__()
        c_ = c2 // 2
        self.conv = nn.Sequential(
            GhostConv(c1, c_, 1, 1),  # pw
            DWConv(c_, c_, k, s, act=False) if s == 2 else nn.Identity(),  # dw
            GhostConv(c_, c2, 1, 1, act=False),  # pw-linear
        )
        self.shortcut = (
            nn.Sequential(DWConv(c1, c1, k, s, act=False), Conv(c1, c2, 1, 1, act=False)) if s == 2 else nn.Identity()
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Apply skip connection and addition to input tensor."""
        return self.conv(x) + self.shortcut(x)


class Bottleneck(nn.Module):
    """Standard bottleneck."""

    def __init__(
        self, c1: int, c2: int, shortcut: bool = True, g: int = 1, k: tuple[int, int] = (3, 3), e: float = 0.5
    ):
        """Initialize a standard bottleneck module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            shortcut (bool): Whether to use shortcut connection.
            g (int): Groups for convolutions.
            k (tuple): Kernel sizes for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__()
        c_ = int(c2 * e)  # hidden channels
        self.cv1 = Conv(c1, c_, k[0], 1)
        self.cv2 = Conv(c_, c2, k[1], 1, g=g)
        self.add = shortcut and c1 == c2

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Apply bottleneck with optional shortcut connection."""
        return x + self.cv2(self.cv1(x)) if self.add else self.cv2(self.cv1(x))


class BottleneckCSP(nn.Module):
    """CSP Bottleneck https://github.com/WongKinYiu/CrossStagePartialNetworks."""

    def __init__(self, c1: int, c2: int, n: int = 1, shortcut: bool = True, g: int = 1, e: float = 0.5):
        """Initialize CSP Bottleneck.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of Bottleneck blocks.
            shortcut (bool): Whether to use shortcut connections.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__()
        c_ = int(c2 * e)  # hidden channels
        self.cv1 = Conv(c1, c_, 1, 1)
        self.cv2 = nn.Conv2d(c1, c_, 1, 1, bias=False)
        self.cv3 = nn.Conv2d(c_, c_, 1, 1, bias=False)
        self.cv4 = Conv(2 * c_, c2, 1, 1)
        self.bn = nn.BatchNorm2d(2 * c_)  # applied to cat(cv2, cv3)
        self.act = nn.SiLU()
        self.m = nn.Sequential(*(Bottleneck(c_, c_, shortcut, g, e=1.0) for _ in range(n)))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Apply CSP bottleneck with 4 convolutions."""
        y1 = self.cv3(self.m(self.cv1(x)))
        y2 = self.cv2(x)
        return self.cv4(self.act(self.bn(torch.cat((y1, y2), 1))))


class ResNetBlock(nn.Module):
    """ResNet block with standard convolution layers."""

    def __init__(self, c1: int, c2: int, s: int = 1, e: int = 4):
        """Initialize ResNet block.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            s (int): Stride.
            e (int): Expansion ratio.
        """
        super().__init__()
        c3 = e * c2
        self.cv1 = Conv(c1, c2, k=1, s=1, act=True)
        self.cv2 = Conv(c2, c2, k=3, s=s, p=1, act=True)
        self.cv3 = Conv(c2, c3, k=1, act=False)
        self.shortcut = nn.Sequential(Conv(c1, c3, k=1, s=s, act=False)) if s != 1 or c1 != c3 else nn.Identity()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through the ResNet block."""
        return F.relu(self.cv3(self.cv2(self.cv1(x))) + self.shortcut(x))


class ResNetLayer(nn.Module):
    """ResNet layer with multiple ResNet blocks."""

    def __init__(self, c1: int, c2: int, s: int = 1, is_first: bool = False, n: int = 1, e: int = 4):
        """Initialize ResNet layer.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            s (int): Stride.
            is_first (bool): Whether this is the first layer.
            n (int): Number of ResNet blocks.
            e (int): Expansion ratio.
        """
        super().__init__()
        self.is_first = is_first

        if self.is_first:
            self.layer = nn.Sequential(
                Conv(c1, c2, k=7, s=2, p=3, act=True), nn.MaxPool2d(kernel_size=3, stride=2, padding=1)
            )
        else:
            blocks = [ResNetBlock(c1, c2, s, e=e)]
            blocks.extend([ResNetBlock(e * c2, c2, 1, e=e) for _ in range(n - 1)])
            self.layer = nn.Sequential(*blocks)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through the ResNet layer."""
        return self.layer(x)


class MaxSigmoidAttnBlock(nn.Module):
    """Max Sigmoid attention block."""

    def __init__(self, c1: int, c2: int, nh: int = 1, ec: int = 128, gc: int = 512, scale: bool = False):
        """Initialize MaxSigmoidAttnBlock.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            nh (int): Number of heads.
            ec (int): Embedding channels.
            gc (int): Guide channels.
            scale (bool): Whether to use learnable scale parameter.
        """
        super().__init__()
        self.nh = nh
        self.hc = c2 // nh
        self.ec = Conv(c1, ec, k=1, act=False) if c1 != ec else None
        self.gl = nn.Linear(gc, ec)
        self.bias = nn.Parameter(torch.zeros(nh))
        self.proj_conv = Conv(c1, c2, k=3, s=1, act=False)
        self.scale = nn.Parameter(torch.ones(1, nh, 1, 1)) if scale else 1.0

    def forward(self, x: torch.Tensor, guide: torch.Tensor) -> torch.Tensor:
        """Forward pass of MaxSigmoidAttnBlock.

        Args:
            x (torch.Tensor): Input tensor.
            guide (torch.Tensor): Guide tensor.

        Returns:
            (torch.Tensor): Output tensor after attention.
        """
        bs, _, h, w = x.shape

        guide = self.gl(guide)
        guide = guide.view(bs, guide.shape[1], self.nh, self.hc)
        embed = self.ec(x) if self.ec is not None else x
        embed = embed.view(bs, self.nh, self.hc, h, w)

        aw = torch.einsum("bmchw,bnmc->bmhwn", embed, guide)
        aw = aw.max(dim=-1)[0]
        aw = aw / (self.hc**0.5)
        aw = aw + self.bias[None, :, None, None]
        aw = aw.sigmoid() * self.scale

        x = self.proj_conv(x)
        x = x.view(bs, self.nh, -1, h, w)
        x = x * aw.unsqueeze(2)
        return x.view(bs, -1, h, w)


class C2fAttn(nn.Module):
    """C2f module with an additional attn module."""

    def __init__(
        self,
        c1: int,
        c2: int,
        n: int = 1,
        ec: int = 128,
        nh: int = 1,
        gc: int = 512,
        shortcut: bool = False,
        g: int = 1,
        e: float = 0.5,
    ):
        """Initialize C2f module with attention mechanism.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of Bottleneck blocks.
            ec (int): Embedding channels for attention.
            nh (int): Number of heads for attention.
            gc (int): Guide channels for attention.
            shortcut (bool): Whether to use shortcut connections.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__()
        self.c = int(c2 * e)  # hidden channels
        self.cv1 = Conv(c1, 2 * self.c, 1, 1)
        self.cv2 = Conv((3 + n) * self.c, c2, 1)  # optional act=FReLU(c2)
        self.m = nn.ModuleList(Bottleneck(self.c, self.c, shortcut, g, k=((3, 3), (3, 3)), e=1.0) for _ in range(n))
        self.attn = MaxSigmoidAttnBlock(self.c, self.c, gc=gc, ec=ec, nh=nh)

    def forward(self, x: torch.Tensor, guide: torch.Tensor) -> torch.Tensor:
        """Forward pass through C2f layer with attention.

        Args:
            x (torch.Tensor): Input tensor.
            guide (torch.Tensor): Guide tensor for attention.

        Returns:
            (torch.Tensor): Output tensor after processing.
        """
        y = list(self.cv1(x).chunk(2, 1))
        y.extend(m(y[-1]) for m in self.m)
        y.append(self.attn(y[-1], guide))
        return self.cv2(torch.cat(y, 1))

    def forward_split(self, x: torch.Tensor, guide: torch.Tensor) -> torch.Tensor:
        """Forward pass using split() instead of chunk().

        Args:
            x (torch.Tensor): Input tensor.
            guide (torch.Tensor): Guide tensor for attention.

        Returns:
            (torch.Tensor): Output tensor after processing.
        """
        y = list(self.cv1(x).split((self.c, self.c), 1))
        y.extend(m(y[-1]) for m in self.m)
        y.append(self.attn(y[-1], guide))
        return self.cv2(torch.cat(y, 1))


class ImagePoolingAttn(nn.Module):
    """ImagePoolingAttn: Enhance the text embeddings with image-aware information."""

    def __init__(
        self, ec: int = 256, ch: tuple[int, ...] = (), ct: int = 512, nh: int = 8, k: int = 3, scale: bool = False
    ):
        """Initialize ImagePoolingAttn module.

        Args:
            ec (int): Embedding channels.
            ch (tuple): Channel dimensions for feature maps.
            ct (int): Channel dimension for text embeddings.
            nh (int): Number of attention heads.
            k (int): Kernel size for pooling.
            scale (bool): Whether to use learnable scale parameter.
        """
        super().__init__()

        nf = len(ch)
        self.query = nn.Sequential(nn.LayerNorm(ct), nn.Linear(ct, ec))
        self.key = nn.Sequential(nn.LayerNorm(ec), nn.Linear(ec, ec))
        self.value = nn.Sequential(nn.LayerNorm(ec), nn.Linear(ec, ec))
        self.proj = nn.Linear(ec, ct)
        self.scale = nn.Parameter(torch.tensor([0.0]), requires_grad=True) if scale else 1.0
        self.projections = nn.ModuleList([nn.Conv2d(in_channels, ec, kernel_size=1) for in_channels in ch])
        self.im_pools = nn.ModuleList([nn.AdaptiveMaxPool2d((k, k)) for _ in range(nf)])
        self.ec = ec
        self.nh = nh
        self.nf = nf
        self.hc = ec // nh
        self.k = k

    def forward(self, x: list[torch.Tensor], text: torch.Tensor) -> torch.Tensor:
        """Forward pass of ImagePoolingAttn.

        Args:
            x (list[torch.Tensor]): List of input feature maps.
            text (torch.Tensor): Text embeddings.

        Returns:
            (torch.Tensor): Enhanced text embeddings.
        """
        bs = x[0].shape[0]
        assert len(x) == self.nf
        num_patches = self.k**2
        x = [pool(proj(x)).view(bs, -1, num_patches) for (x, proj, pool) in zip(x, self.projections, self.im_pools)]
        x = torch.cat(x, dim=-1).transpose(1, 2)
        q = self.query(text)
        k = self.key(x)
        v = self.value(x)

        # q = q.reshape(1, text.shape[1], self.nh, self.hc).repeat(bs, 1, 1, 1)
        q = q.reshape(bs, -1, self.nh, self.hc)
        k = k.reshape(bs, -1, self.nh, self.hc)
        v = v.reshape(bs, -1, self.nh, self.hc)

        aw = torch.einsum("bnmc,bkmc->bmnk", q, k)
        aw = aw / (self.hc**0.5)
        aw = F.softmax(aw, dim=-1)

        x = torch.einsum("bmnk,bkmc->bnmc", aw, v)
        x = self.proj(x.reshape(bs, -1, self.ec))
        return x * self.scale + text


class ContrastiveHead(nn.Module):
    """Implements contrastive learning head for region-text similarity in vision-language models."""

    def __init__(self):
        """Initialize ContrastiveHead with region-text similarity parameters."""
        super().__init__()
        # NOTE: use -10.0 to keep the init cls loss consistency with other losses
        self.bias = nn.Parameter(torch.tensor([-10.0]))
        self.logit_scale = nn.Parameter(torch.ones([]) * torch.tensor(1 / 0.07).log())

    def forward(self, x: torch.Tensor, w: torch.Tensor) -> torch.Tensor:
        """Forward function of contrastive learning.

        Args:
            x (torch.Tensor): Image features.
            w (torch.Tensor): Text features.

        Returns:
            (torch.Tensor): Similarity scores.
        """
        x = F.normalize(x, dim=1, p=2)
        w = F.normalize(w, dim=-1, p=2)
        x = torch.einsum("bchw,bkc->bkhw", x, w)
        return x * self.logit_scale.exp() + self.bias


class BNContrastiveHead(nn.Module):
    """Batch Norm Contrastive Head using batch norm instead of l2-normalization.

    Args:
        embed_dims (int): Embed dimensions of text and image features.
    """

    def __init__(self, embed_dims: int):
        """Initialize BNContrastiveHead.

        Args:
            embed_dims (int): Embedding dimensions for features.
        """
        super().__init__()
        self.norm = nn.BatchNorm2d(embed_dims)
        # NOTE: use -10.0 to keep the init cls loss consistency with other losses
        self.bias = nn.Parameter(torch.tensor([-10.0]))
        # use -1.0 is more stable
        self.logit_scale = nn.Parameter(-1.0 * torch.ones([]))

    def fuse(self):
        """Fuse the batch normalization layer in the BNContrastiveHead module."""
        del self.norm
        del self.bias
        del self.logit_scale
        self.forward = self.forward_fuse

    @staticmethod
    def forward_fuse(x: torch.Tensor, w: torch.Tensor) -> torch.Tensor:
        """Passes image features through unchanged after fusing."""
        return x

    def forward(self, x: torch.Tensor, w: torch.Tensor) -> torch.Tensor:
        """Forward function of contrastive learning with batch normalization.

        Args:
            x (torch.Tensor): Image features.
            w (torch.Tensor): Text features.

        Returns:
            (torch.Tensor): Similarity scores.
        """
        x = self.norm(x)
        w = F.normalize(w, dim=-1, p=2)

        x = torch.einsum("bchw,bkc->bkhw", x, w)
        return x * self.logit_scale.exp() + self.bias


class RepBottleneck(Bottleneck):
    """Rep bottleneck."""

    def __init__(
        self, c1: int, c2: int, shortcut: bool = True, g: int = 1, k: tuple[int, int] = (3, 3), e: float = 0.5
    ):
        """Initialize RepBottleneck.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            shortcut (bool): Whether to use shortcut connection.
            g (int): Groups for convolutions.
            k (tuple): Kernel sizes for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__(c1, c2, shortcut, g, k, e)
        c_ = int(c2 * e)  # hidden channels
        self.cv1 = RepConv(c1, c_, k[0], 1)


class RepCSP(C3):
    """Repeatable Cross Stage Partial Network (RepCSP) module for efficient feature extraction."""

    def __init__(self, c1: int, c2: int, n: int = 1, shortcut: bool = True, g: int = 1, e: float = 0.5):
        """Initialize RepCSP layer.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of RepBottleneck blocks.
            shortcut (bool): Whether to use shortcut connections.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__(c1, c2, n, shortcut, g, e)
        c_ = int(c2 * e)  # hidden channels
        self.m = nn.Sequential(*(RepBottleneck(c_, c_, shortcut, g, e=1.0) for _ in range(n)))


class RepNCSPELAN4(nn.Module):
    """CSP-ELAN."""

    def __init__(self, c1: int, c2: int, c3: int, c4: int, n: int = 1):
        """Initialize CSP-ELAN layer.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            c3 (int): Intermediate channels.
            c4 (int): Intermediate channels for RepCSP.
            n (int): Number of RepCSP blocks.
        """
        super().__init__()
        self.c = c3 // 2
        self.cv1 = Conv(c1, c3, 1, 1)
        self.cv2 = nn.Sequential(RepCSP(c3 // 2, c4, n), Conv(c4, c4, 3, 1))
        self.cv3 = nn.Sequential(RepCSP(c4, c4, n), Conv(c4, c4, 3, 1))
        self.cv4 = Conv(c3 + (2 * c4), c2, 1, 1)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through RepNCSPELAN4 layer."""
        y = list(self.cv1(x).chunk(2, 1))
        y.extend((m(y[-1])) for m in [self.cv2, self.cv3])
        return self.cv4(torch.cat(y, 1))

    def forward_split(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass using split() instead of chunk()."""
        y = list(self.cv1(x).split((self.c, self.c), 1))
        y.extend(m(y[-1]) for m in [self.cv2, self.cv3])
        return self.cv4(torch.cat(y, 1))


class ELAN1(RepNCSPELAN4):
    """ELAN1 module with 4 convolutions."""

    def __init__(self, c1: int, c2: int, c3: int, c4: int):
        """Initialize ELAN1 layer.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            c3 (int): Intermediate channels.
            c4 (int): Intermediate channels for convolutions.
        """
        super().__init__(c1, c2, c3, c4)
        self.c = c3 // 2
        self.cv1 = Conv(c1, c3, 1, 1)
        self.cv2 = Conv(c3 // 2, c4, 3, 1)
        self.cv3 = Conv(c4, c4, 3, 1)
        self.cv4 = Conv(c3 + (2 * c4), c2, 1, 1)


class AConv(nn.Module):
    """AConv."""

    def __init__(self, c1: int, c2: int):
        """Initialize AConv module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
        """
        super().__init__()
        self.cv1 = Conv(c1, c2, 3, 2, 1)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through AConv layer."""
        x = torch.nn.functional.avg_pool2d(x, 2, 1, 0, False, True)
        return self.cv1(x)


class ADown(nn.Module):
    """ADown."""

    def __init__(self, c1: int, c2: int):
        """Initialize ADown module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
        """
        super().__init__()
        self.c = c2 // 2
        self.cv1 = Conv(c1 // 2, self.c, 3, 2, 1)
        self.cv2 = Conv(c1 // 2, self.c, 1, 1, 0)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through ADown layer."""
        x = torch.nn.functional.avg_pool2d(x, 2, 1, 0, False, True)
        x1, x2 = x.chunk(2, 1)
        x1 = self.cv1(x1)
        x2 = torch.nn.functional.max_pool2d(x2, 3, 2, 1)
        x2 = self.cv2(x2)
        return torch.cat((x1, x2), 1)


class SPPELAN(nn.Module):
    """SPP-ELAN."""

    def __init__(self, c1: int, c2: int, c3: int, k: int = 5):
        """Initialize SPP-ELAN block.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            c3 (int): Intermediate channels.
            k (int): Kernel size for max pooling.
        """
        super().__init__()
        self.c = c3
        self.cv1 = Conv(c1, c3, 1, 1)
        self.cv2 = nn.MaxPool2d(kernel_size=k, stride=1, padding=k // 2)
        self.cv3 = nn.MaxPool2d(kernel_size=k, stride=1, padding=k // 2)
        self.cv4 = nn.MaxPool2d(kernel_size=k, stride=1, padding=k // 2)
        self.cv5 = Conv(4 * c3, c2, 1, 1)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through SPPELAN layer."""
        y = [self.cv1(x)]
        y.extend(m(y[-1]) for m in [self.cv2, self.cv3, self.cv4])
        return self.cv5(torch.cat(y, 1))


class CBLinear(nn.Module):
    """CBLinear."""

    def __init__(self, c1: int, c2s: list[int], k: int = 1, s: int = 1, p: int | None = None, g: int = 1):
        """Initialize CBLinear module.

        Args:
            c1 (int): Input channels.
            c2s (list[int]): List of output channel sizes.
            k (int): Kernel size.
            s (int): Stride.
            p (int | None): Padding.
            g (int): Groups.
        """
        super().__init__()
        self.c2s = c2s
        self.conv = nn.Conv2d(c1, sum(c2s), k, s, autopad(k, p), groups=g, bias=True)

    def forward(self, x: torch.Tensor) -> list[torch.Tensor]:
        """Forward pass through CBLinear layer."""
        return self.conv(x).split(self.c2s, dim=1)


class CBFuse(nn.Module):
    """CBFuse."""

    def __init__(self, idx: list[int]):
        """Initialize CBFuse module.

        Args:
            idx (list[int]): Indices for feature selection.
        """
        super().__init__()
        self.idx = idx

    def forward(self, xs: list[torch.Tensor]) -> torch.Tensor:
        """Forward pass through CBFuse layer.

        Args:
            xs (list[torch.Tensor]): List of input tensors.

        Returns:
            (torch.Tensor): Fused output tensor.
        """
        target_size = xs[-1].shape[2:]
        res = [F.interpolate(x[self.idx[i]], size=target_size, mode="nearest") for i, x in enumerate(xs[:-1])]
        return torch.sum(torch.stack(res + xs[-1:]), dim=0)


class C3f(nn.Module):
    """Faster Implementation of CSP Bottleneck with 3 convolutions."""

    def __init__(self, c1: int, c2: int, n: int = 1, shortcut: bool = False, g: int = 1, e: float = 0.5):
        """Initialize CSP bottleneck layer with three convolutions.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of Bottleneck blocks.
            shortcut (bool): Whether to use shortcut connections.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__()
        c_ = int(c2 * e)  # hidden channels
        self.cv1 = Conv(c1, c_, 1, 1)
        self.cv2 = Conv(c1, c_, 1, 1)
        self.cv3 = Conv((2 + n) * c_, c2, 1)  # optional act=FReLU(c2)
        self.m = nn.ModuleList(Bottleneck(c_, c_, shortcut, g, k=((3, 3), (3, 3)), e=1.0) for _ in range(n))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through C3f layer."""
        y = [self.cv2(x), self.cv1(x)]
        y.extend(m(y[-1]) for m in self.m)
        return self.cv3(torch.cat(y, 1))


class C3k2(C2f):
    """Faster Implementation of CSP Bottleneck with 2 convolutions."""

    def __init__(
        self,
        c1: int,
        c2: int,
        n: int = 1,
        c3k: bool = False,
        e: float = 0.5,
        attn: bool = False,
        g: int = 1,
        shortcut: bool = True,
    ):
        """Initialize C3k2 module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of blocks.
            c3k (bool): Whether to use C3k blocks.
            e (float): Expansion ratio.
            attn (bool): Whether to use attention blocks.
            g (int): Groups for convolutions.
            shortcut (bool): Whether to use shortcut connections.
        """
        super().__init__(c1, c2, n, shortcut, g, e)
        self.m = nn.ModuleList(
            nn.Sequential(
                Bottleneck(self.c, self.c, shortcut, g),
                PSABlock(self.c, attn_ratio=0.5, num_heads=max(self.c // 64, 1)),
            )
            if attn
            else C3k(self.c, self.c, 2, shortcut, g)
            if c3k
            else Bottleneck(self.c, self.c, shortcut, g)
            for _ in range(n)
        )


class C3k(C3):
    """C3k is a CSP bottleneck module with customizable kernel sizes for feature extraction in neural networks."""

    def __init__(self, c1: int, c2: int, n: int = 1, shortcut: bool = True, g: int = 1, e: float = 0.5, k: int = 3):
        """Initialize C3k module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of Bottleneck blocks.
            shortcut (bool): Whether to use shortcut connections.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
            k (int): Kernel size.
        """
        super().__init__(c1, c2, n, shortcut, g, e)
        c_ = int(c2 * e)  # hidden channels
        # self.m = nn.Sequential(*(RepBottleneck(c_, c_, shortcut, g, k=(k, k), e=1.0) for _ in range(n)))
        self.m = nn.Sequential(*(Bottleneck(c_, c_, shortcut, g, k=(k, k), e=1.0) for _ in range(n)))


class RepVGGDW(torch.nn.Module):
    """RepVGGDW is a class that represents a depth-wise convolutional block in RepVGG architecture."""

    def __init__(self, ed: int) -> None:
        """Initialize RepVGGDW module.

        Args:
            ed (int): Input and output channels.
        """
        super().__init__()
        self.conv = Conv(ed, ed, 7, 1, 3, g=ed, act=False)
        self.conv1 = Conv(ed, ed, 3, 1, 1, g=ed, act=False)
        self.dim = ed
        self.act = nn.SiLU()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Perform a forward pass of the RepVGGDW block.

        Args:
            x (torch.Tensor): Input tensor.

        Returns:
            (torch.Tensor): Output tensor after applying the depth-wise convolution.
        """
        return self.act(self.conv(x) + self.conv1(x))

    def forward_fuse(self, x: torch.Tensor) -> torch.Tensor:
        """Perform a forward pass of the fused RepVGGDW block.

        Args:
            x (torch.Tensor): Input tensor.

        Returns:
            (torch.Tensor): Output tensor after applying the depth-wise convolution.
        """
        return self.act(self.conv(x))

    @torch.no_grad()
    def fuse(self):
        """Fuse the convolutional layers in the RepVGGDW block.

        This method fuses the convolutional layers and updates the weights and biases accordingly.
        """
        if not hasattr(self, "conv1"):
            return  # already fused
        conv = fuse_conv_and_bn(self.conv.conv, self.conv.bn)
        conv1 = fuse_conv_and_bn(self.conv1.conv, self.conv1.bn)

        conv_w = conv.weight
        conv_b = conv.bias
        conv1_w = conv1.weight
        conv1_b = conv1.bias

        conv1_w = torch.nn.functional.pad(conv1_w, [2, 2, 2, 2])

        final_conv_w = conv_w + conv1_w
        final_conv_b = conv_b + conv1_b

        conv.weight.data.copy_(final_conv_w)
        conv.bias.data.copy_(final_conv_b)

        self.conv = conv
        del self.conv1


class CIB(nn.Module):
    """Compact Inverted Block (CIB) module.

    Args:
        c1 (int): Number of input channels.
        c2 (int): Number of output channels.
        shortcut (bool, optional): Whether to add a shortcut connection. Defaults to True.
        e (float, optional): Scaling factor for the hidden channels. Defaults to 0.5.
        lk (bool, optional): Whether to use RepVGGDW for the third convolutional layer. Defaults to False.
    """

    def __init__(self, c1: int, c2: int, shortcut: bool = True, e: float = 0.5, lk: bool = False):
        """Initialize the CIB module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            shortcut (bool): Whether to use shortcut connection.
            e (float): Expansion ratio.
            lk (bool): Whether to use RepVGGDW.
        """
        super().__init__()
        c_ = int(c2 * e)  # hidden channels
        self.cv1 = nn.Sequential(
            Conv(c1, c1, 3, g=c1),
            Conv(c1, 2 * c_, 1),
            RepVGGDW(2 * c_) if lk else Conv(2 * c_, 2 * c_, 3, g=2 * c_),
            Conv(2 * c_, c2, 1),
            Conv(c2, c2, 3, g=c2),
        )

        self.add = shortcut and c1 == c2

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass of the CIB module.

        Args:
            x (torch.Tensor): Input tensor.

        Returns:
            (torch.Tensor): Output tensor.
        """
        return x + self.cv1(x) if self.add else self.cv1(x)


class C2fCIB(C2f):
    """C2fCIB class represents a convolutional block with C2f and CIB modules.

    Args:
        c1 (int): Number of input channels.
        c2 (int): Number of output channels.
        n (int, optional): Number of CIB modules to stack. Defaults to 1.
        shortcut (bool, optional): Whether to use shortcut connection. Defaults to False.
        lk (bool, optional): Whether to use large kernel. Defaults to False.
        g (int, optional): Number of groups for grouped convolution. Defaults to 1.
        e (float, optional): Expansion ratio for CIB modules. Defaults to 0.5.
    """

    def __init__(
        self, c1: int, c2: int, n: int = 1, shortcut: bool = False, lk: bool = False, g: int = 1, e: float = 0.5
    ):
        """Initialize C2fCIB module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of CIB modules.
            shortcut (bool): Whether to use shortcut connection.
            lk (bool): Whether to use large kernel.
            g (int): Groups for convolutions.
            e (float): Expansion ratio.
        """
        super().__init__(c1, c2, n, shortcut, g, e)
        self.m = nn.ModuleList(CIB(self.c, self.c, shortcut, e=1.0, lk=lk) for _ in range(n))


class Attention(nn.Module):
    """Attention module that performs self-attention on the input tensor.

    Args:
        dim (int): The input tensor dimension.
        num_heads (int): The number of attention heads.
        attn_ratio (float): The ratio of the attention key dimension to the head dimension.

    Attributes:
        num_heads (int): The number of attention heads.
        head_dim (int): The dimension of each attention head.
        key_dim (int): The dimension of the attention key.
        scale (float): The scaling factor for the attention scores.
        qkv (Conv): Convolutional layer for computing the query, key, and value.
        proj (Conv): Convolutional layer for projecting the attended values.
        pe (Conv): Convolutional layer for positional encoding.
    """

    def __init__(self, dim: int, num_heads: int = 8, attn_ratio: float = 0.5):
        """Initialize multi-head attention module.

        Args:
            dim (int): Input dimension.
            num_heads (int): Number of attention heads.
            attn_ratio (float): Attention ratio for key dimension.
        """
        super().__init__()
        self.num_heads = num_heads
        self.head_dim = dim // num_heads
        self.key_dim = int(self.head_dim * attn_ratio)
        self.scale = self.key_dim**-0.5
        nh_kd = self.key_dim * num_heads
        h = dim + nh_kd * 2
        self.qkv = Conv(dim, h, 1, act=False)
        self.proj = Conv(dim, dim, 1, act=False)
        self.pe = Conv(dim, dim, 3, 1, g=dim, act=False)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass of the Attention module.

        Args:
            x (torch.Tensor): The input tensor.

        Returns:
            (torch.Tensor): The output tensor after self-attention.
        """
        B, C, H, W = x.shape
        N = H * W
        qkv = self.qkv(x)
        q, k, v = qkv.view(B, self.num_heads, self.key_dim * 2 + self.head_dim, N).split(
            [self.key_dim, self.key_dim, self.head_dim], dim=2
        )

        attn = (q.transpose(-2, -1) @ k) * self.scale
        attn = attn.softmax(dim=-1)
        x = (v @ attn.transpose(-2, -1)).view(B, C, H, W) + self.pe(v.reshape(B, C, H, W))
        x = self.proj(x)
        return x


class PSABlock(nn.Module):
    """PSABlock class implementing a Position-Sensitive Attention block for neural networks.

    This class encapsulates the functionality for applying multi-head attention and feed-forward neural network layers
    with optional shortcut connections.

    Attributes:
        attn (Attention): Multi-head attention module.
        ffn (nn.Sequential): Feed-forward neural network module.
        add (bool): Flag indicating whether to add shortcut connections.

    Methods:
        forward: Performs a forward pass through the PSABlock, applying attention and feed-forward layers.

    Examples:
        Create a PSABlock and perform a forward pass
        >>> psablock = PSABlock(c=128, attn_ratio=0.5, num_heads=4, shortcut=True)
        >>> input_tensor = torch.randn(1, 128, 32, 32)
        >>> output_tensor = psablock(input_tensor)
    """

    def __init__(self, c: int, attn_ratio: float = 0.5, num_heads: int = 4, shortcut: bool = True) -> None:
        """Initialize the PSABlock.

        Args:
            c (int): Input and output channels.
            attn_ratio (float): Attention ratio for key dimension.
            num_heads (int): Number of attention heads.
            shortcut (bool): Whether to use shortcut connections.
        """
        super().__init__()

        self.attn = Attention(c, attn_ratio=attn_ratio, num_heads=num_heads)
        self.ffn = nn.Sequential(Conv(c, c * 2, 1), Conv(c * 2, c, 1, act=False))
        self.add = shortcut

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Execute a forward pass through PSABlock.

        Args:
            x (torch.Tensor): Input tensor.

        Returns:
            (torch.Tensor): Output tensor after attention and feed-forward processing.
        """
        x = x + self.attn(x) if self.add else self.attn(x)
        x = x + self.ffn(x) if self.add else self.ffn(x)
        return x


class PSA(nn.Module):
    """PSA class for implementing Position-Sensitive Attention in neural networks.

    This class encapsulates the functionality for applying position-sensitive attention and feed-forward networks to
    input tensors, enhancing feature extraction and processing capabilities.

    Attributes:
        c (int): Number of hidden channels after applying the initial convolution.
        cv1 (Conv): 1x1 convolution layer to reduce the number of input channels to 2*c.
        cv2 (Conv): 1x1 convolution layer to reduce the number of output channels to c1.
        attn (Attention): Attention module for position-sensitive attention.
        ffn (nn.Sequential): Feed-forward network for further processing.

    Methods:
        forward: Applies position-sensitive attention and feed-forward network to the input tensor.

    Examples:
        Create a PSA module and apply it to an input tensor
        >>> psa = PSA(c1=128, c2=128, e=0.5)
        >>> input_tensor = torch.randn(1, 128, 64, 64)
        >>> output_tensor = psa.forward(input_tensor)
    """

    def __init__(self, c1: int, c2: int, e: float = 0.5):
        """Initialize PSA module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            e (float): Expansion ratio.
        """
        super().__init__()
        assert c1 == c2
        self.c = int(c1 * e)
        self.cv1 = Conv(c1, 2 * self.c, 1, 1)
        self.cv2 = Conv(2 * self.c, c1, 1)

        self.attn = Attention(self.c, attn_ratio=0.5, num_heads=max(self.c // 64, 1))
        self.ffn = nn.Sequential(Conv(self.c, self.c * 2, 1), Conv(self.c * 2, self.c, 1, act=False))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Execute forward pass in PSA module.

        Args:
            x (torch.Tensor): Input tensor.

        Returns:
            (torch.Tensor): Output tensor after attention and feed-forward processing.
        """
        a, b = self.cv1(x).split((self.c, self.c), dim=1)
        b = b + self.attn(b)
        b = b + self.ffn(b)
        return self.cv2(torch.cat((a, b), 1))


class C2PSA(nn.Module):
    """C2PSA module with attention mechanism for enhanced feature extraction and processing.

    This module implements a convolutional block with attention mechanisms to enhance feature extraction and processing
    capabilities. It includes a series of PSABlock modules for self-attention and feed-forward operations.

    Attributes:
        c (int): Number of hidden channels.
        cv1 (Conv): 1x1 convolution layer to reduce the number of input channels to 2*c.
        cv2 (Conv): 1x1 convolution layer to reduce the number of output channels to c1.
        m (nn.Sequential): Sequential container of PSABlock modules for attention and feed-forward operations.

    Methods:
        forward: Performs a forward pass through the C2PSA module, applying attention and feed-forward operations.

    Examples:
        >>> c2psa = C2PSA(c1=256, c2=256, n=3, e=0.5)
        >>> input_tensor = torch.randn(1, 256, 64, 64)
        >>> output_tensor = c2psa(input_tensor)

    Notes:
        This module essentially is the same as PSA module, but refactored to allow stacking more PSABlock modules.
    """

    def __init__(self, c1: int, c2: int, n: int = 1, e: float = 0.5):
        """Initialize C2PSA module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of PSABlock modules.
            e (float): Expansion ratio.
        """
        super().__init__()
        assert c1 == c2
        self.c = int(c1 * e)
        self.cv1 = Conv(c1, 2 * self.c, 1, 1)
        self.cv2 = Conv(2 * self.c, c1, 1)

        self.m = nn.Sequential(*(PSABlock(self.c, attn_ratio=0.5, num_heads=self.c // 64) for _ in range(n)))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Process the input tensor through a series of PSA blocks.

        Args:
            x (torch.Tensor): Input tensor.

        Returns:
            (torch.Tensor): Output tensor after processing.
        """
        a, b = self.cv1(x).split((self.c, self.c), dim=1)
        b = self.m(b)
        return self.cv2(torch.cat((a, b), 1))


class C2fPSA(C2f):
    """C2fPSA module with enhanced feature extraction using PSA blocks.

    This class extends the C2f module by incorporating PSA blocks for improved attention mechanisms and feature
    extraction.

    Attributes:
        c (int): Number of hidden channels.
        cv1 (Conv): 1x1 convolution layer to reduce the number of input channels to 2*c.
        cv2 (Conv): 1x1 convolution layer to reduce the number of output channels to c2.
        m (nn.ModuleList): List of PSABlock modules for feature extraction.

    Methods:
        forward: Performs a forward pass through the C2fPSA module.
        forward_split: Performs a forward pass using split() instead of chunk().

    Examples:
        >>> import torch
        >>> from ultralytics.nn.modules.block import C2fPSA
        >>> model = C2fPSA(c1=64, c2=64, n=3, e=0.5)
        >>> x = torch.randn(1, 64, 128, 128)
        >>> output = model(x)
        >>> print(output.shape)
    """

    def __init__(self, c1: int, c2: int, n: int = 1, e: float = 0.5):
        """Initialize C2fPSA module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            n (int): Number of PSABlock modules.
            e (float): Expansion ratio.
        """
        assert c1 == c2
        super().__init__(c1, c2, n=n, e=e)
        self.m = nn.ModuleList(PSABlock(self.c, attn_ratio=0.5, num_heads=max(self.c // 64, 1)) for _ in range(n))


class SCDown(nn.Module):
    """SCDown module for downsampling with separable convolutions.

    This module performs downsampling using a combination of pointwise and depthwise convolutions, which helps in
    efficiently reducing the spatial dimensions of the input tensor while maintaining the channel information.

    Attributes:
        cv1 (Conv): Pointwise convolution layer that reduces the number of channels.
        cv2 (Conv): Depthwise convolution layer that performs spatial downsampling.

    Methods:
        forward: Applies the SCDown module to the input tensor.

    Examples:
        >>> import torch
        >>> from ultralytics.nn.modules.block import SCDown
        >>> model = SCDown(c1=64, c2=128, k=3, s=2)
        >>> x = torch.randn(1, 64, 128, 128)
        >>> y = model(x)
        >>> print(y.shape)
        torch.Size([1, 128, 64, 64])
    """

    def __init__(self, c1: int, c2: int, k: int, s: int):
        """Initialize SCDown module.

        Args:
            c1 (int): Input channels.
            c2 (int): Output channels.
            k (int): Kernel size.
            s (int): Stride.
        """
        super().__init__()
        self.cv1 = Conv(c1, c2, 1, 1)
        self.cv2 = Conv(c2, c2, k=k, s=s, g=c2, act=False)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Apply convolution and downsampling to the input tensor.

        Args:
            x (torch.Tensor): Input tensor.

        Returns:
            (torch.Tensor): Downsampled output tensor.
        """
        return self.cv2(self.cv1(x))


class TorchVision(nn.Module):
    """TorchVision module to allow loading any torchvision model.

    This class provides a way to load a model from the torchvision library, optionally load pre-trained weights, and
    customize the model by truncating or unwrapping layers.

    Args:
        model (str): Name of the torchvision model to load.
        weights (str, optional): Pre-trained weights to load. Default is "DEFAULT".
        unwrap (bool, optional): Unwraps the model to a sequential containing all but the last `truncate` layers.
        truncate (int, optional): Number of layers to truncate from the end if `unwrap` is True. Default is 2.
        split (bool, optional): Returns output from intermediate child modules as list. Default is False.

    Attributes:
        m (nn.Module): The loaded torchvision model, possibly truncated and unwrapped.
    """

    def __init__(
        self, model: str, weights: str = "DEFAULT", unwrap: bool = True, truncate: int = 2, split: bool = False
    ):
        """Load the model and weights from torchvision.

        Args:
            model (str): Name of the torchvision model to load.
            weights (str): Pre-trained weights to load.
            unwrap (bool): Whether to unwrap the model.
            truncate (int): Number of layers to truncate.
            split (bool): Whether to split the output.
        """
        import torchvision  # scope for faster 'import ultralytics'

        super().__init__()
        if hasattr(torchvision.models, "get_model"):
            self.m = torchvision.models.get_model(model, weights=weights)
        else:
            self.m = torchvision.models.__dict__[model](pretrained=bool(weights))
        if unwrap:
            layers = list(self.m.children())
            if isinstance(layers[0], nn.Sequential):  # Second-level for some models like EfficientNet, Swin
                layers = [*list(layers[0].children()), *layers[1:]]
            self.m = nn.Sequential(*(layers[:-truncate] if truncate else layers))
            self.split = split
        else:
            self.split = False
            self.m.head = self.m.heads = nn.Identity()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through the model.

        Args:
            x (torch.Tensor): Input tensor.

        Returns:
            (torch.Tensor | list[torch.Tensor]): Output tensor or list of tensors.
        """
        if self.split:
            y = [x]
            y.extend(m(y[-1]) for m in self.m)
        else:
            y = self.m(x)
        return y


class AAttn(nn.Module):
    """Area-attention module for YOLO models, providing efficient attention mechanisms.

    This module implements an area-based attention mechanism that processes input features in a spatially-aware manner,
    making it particularly effective for object detection tasks.

    Attributes:
        area (int): Number of areas the feature map is divided into.
        num_heads (int): Number of heads into which the attention mechanism is divided.
        head_dim (int): Dimension of each attention head.
        qkv (Conv): Convolution layer for computing query, key and value tensors.
        proj (Conv): Projection convolution layer.
        pe (Conv): Position encoding convolution layer.

    Methods:
        forward: Applies area-attention to input tensor.

    Examples:
        >>> attn = AAttn(dim=256, num_heads=8, area=4)
        >>> x = torch.randn(1, 256, 32, 32)
        >>> output = attn(x)
        >>> print(output.shape)
        torch.Size([1, 256, 32, 32])
    """

    def __init__(self, dim: int, num_heads: int, area: int = 1):
        """Initialize an Area-attention module for YOLO models.

        Args:
            dim (int): Number of hidden channels.
            num_heads (int): Number of heads into which the attention mechanism is divided.
            area (int): Number of areas the feature map is divided into.
        """
        super().__init__()
        self.area = area

        self.num_heads = num_heads
        self.head_dim = head_dim = dim // num_heads
        all_head_dim = head_dim * self.num_heads

        self.qkv = Conv(dim, all_head_dim * 3, 1, act=False)
        self.proj = Conv(all_head_dim, dim, 1, act=False)
        self.pe = Conv(all_head_dim, dim, 7, 1, 3, g=dim, act=False)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Process the input tensor through the area-attention.

        Args:
            x (torch.Tensor): Input tensor.

        Returns:
            (torch.Tensor): Output tensor after area-attention.
        """
        B, C, H, W = x.shape
        N = H * W

        qkv = self.qkv(x).flatten(2).transpose(1, 2)
        if self.area > 1:
            qkv = qkv.reshape(B * self.area, N // self.area, C * 3)
            B, N, _ = qkv.shape
        q, k, v = (
            qkv.view(B, N, self.num_heads, self.head_dim * 3)
            .permute(0, 2, 3, 1)
            .split([self.head_dim, self.head_dim, self.head_dim], dim=2)
        )
        attn = (q.transpose(-2, -1) @ k) * (self.head_dim**-0.5)
        attn = attn.softmax(dim=-1)
        x = v @ attn.transpose(-2, -1)
        x = x.permute(0, 3, 1, 2)
        v = v.permute(0, 3, 1, 2)

        if self.area > 1:
            x = x.reshape(B // self.area, N * self.area, C)
            v = v.reshape(B // self.area, N * self.area, C)
            B, N, _ = x.shape

        x = x.reshape(B, H, W, C).permute(0, 3, 1, 2).contiguous()
        v = v.reshape(B, H, W, C).permute(0, 3, 1, 2).contiguous()

        x = x + self.pe(v)
        return self.proj(x)


class ABlock(nn.Module):
    """Area-attention block module for efficient feature extraction in YOLO models.

    This module implements an area-attention mechanism combined with a feed-forward network for processing feature maps.
    It uses a novel area-based attention approach that is more efficient than traditional self-attention while
    maintaining effectiveness.

    Attributes:
        attn (AAttn): Area-attention module for processing spatial features.
        mlp (nn.Sequential): Multi-layer perceptron for feature transformation.

    Methods:
        _init_weights: Initializes module weights using truncated normal distribution.
        forward: Applies area-attention and feed-forward processing to input tensor.

    Examples:
        >>> block = ABlock(dim=256, num_heads=8, mlp_ratio=1.2, area=1)
        >>> x = torch.randn(1, 256, 32, 32)
        >>> output = block(x)
        >>> print(output.shape)
        torch.Size([1, 256, 32, 32])
    """

    def __init__(self, dim: int, num_heads: int, mlp_ratio: float = 1.2, area: int = 1):
        """Initialize an Area-attention block module.

        Args:
            dim (int): Number of input channels.
            num_heads (int): Number of heads into which the attention mechanism is divided.
            mlp_ratio (float): Expansion ratio for MLP hidden dimension.
            area (int): Number of areas the feature map is divided into.
        """
        super().__init__()

        self.attn = AAttn(dim, num_heads=num_heads, area=area)
        mlp_hidden_dim = int(dim * mlp_ratio)
        self.mlp = nn.Sequential(Conv(dim, mlp_hidden_dim, 1), Conv(mlp_hidden_dim, dim, 1, act=False))

        self.apply(self._init_weights)

    @staticmethod
    def _init_weights(m: nn.Module):
        """Initialize weights using a truncated normal distribution.

        Args:
            m (nn.Module): Module to initialize.
        """
        if isinstance(m, nn.Conv2d):
            nn.init.trunc_normal_(m.weight, std=0.02)
            if m.bias is not None:
                nn.init.constant_(m.bias, 0)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through ABlock.

        Args:
            x (torch.Tensor): Input tensor.

        Returns:
            (torch.Tensor): Output tensor after area-attention and feed-forward processing.
        """
        x = x + self.attn(x)
        return x + self.mlp(x)


class A2C2f(nn.Module):
    """Area-Attention C2f module for enhanced feature extraction with area-based attention mechanisms.

    This module extends the C2f architecture by incorporating area-attention and ABlock layers for improved feature
    processing. It supports both area-attention and standard convolution modes.

    Attributes:
        cv1 (Conv): Initial 1x1 convolution layer that reduces input channels to hidden channels.
        cv2 (Conv): Final 1x1 convolution layer that processes concatenated features.
        gamma (nn.Parameter | None): Learnable parameter for residual scaling when using area attention.
        m (nn.ModuleList): List of either ABlock or C3k modules for feature processing.

    Methods:
        forward: Processes input through area-attention or standard convolution pathway.

    Examples:
        >>> m = A2C2f(512, 512, n=1, a2=True, area=1)
        >>> x = torch.randn(1, 512, 32, 32)
        >>> output = m(x)
        >>> print(output.shape)
        torch.Size([1, 512, 32, 32])
    """

    def __init__(
        self,
        c1: int,
        c2: int,
        n: int = 1,
        a2: bool = True,
        area: int = 1,
        residual: bool = False,
        mlp_ratio: float = 2.0,
        e: float = 0.5,
        g: int = 1,
        shortcut: bool = True,
    ):
        """Initialize Area-Attention C2f module.

        Args:
            c1 (int): Number of input channels.
            c2 (int): Number of output channels.
            n (int): Number of ABlock or C3k modules to stack.
            a2 (bool): Whether to use area attention blocks. If False, uses C3k blocks instead.
            area (int): Number of areas the feature map is divided into.
            residual (bool): Whether to use residual connections with learnable gamma parameter.
            mlp_ratio (float): Expansion ratio for MLP hidden dimension.
            e (float): Channel expansion ratio for hidden channels.
            g (int): Number of groups for grouped convolutions.
            shortcut (bool): Whether to use shortcut connections in C3k blocks.
        """
        super().__init__()
        c_ = int(c2 * e)  # hidden channels
        assert c_ % 32 == 0, "Dimension of ABlock must be a multiple of 32."

        self.cv1 = Conv(c1, c_, 1, 1)
        self.cv2 = Conv((1 + n) * c_, c2, 1)

        self.gamma = nn.Parameter(0.01 * torch.ones(c2), requires_grad=True) if a2 and residual else None
        self.m = nn.ModuleList(
            nn.Sequential(*(ABlock(c_, c_ // 32, mlp_ratio, area) for _ in range(2)))
            if a2
            else C3k(c_, c_, 2, shortcut, g)
            for _ in range(n)
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Forward pass through A2C2f layer.

        Args:
            x (torch.Tensor): Input tensor.

        Returns:
            (torch.Tensor): Output tensor after processing.
        """
        y = [self.cv1(x)]
        y.extend(m(y[-1]) for m in self.m)
        y = self.cv2(torch.cat(y, 1))
        if self.gamma is not None:
            return x + self.gamma.view(-1, self.gamma.shape[0], 1, 1) * y
        return y


class SwiGLUFFN(nn.Module):
    """SwiGLU Feed-Forward Network for transformer-based architectures."""

    def __init__(self, gc: int, ec: int, e: int = 4) -> None:
        """Initialize SwiGLU FFN with input dimension, output dimension, and expansion factor.

        Args:
            gc (int): Guide channels.
            ec (int): Embedding channels.
            e (int): Expansion factor.
        """
        super().__init__()
        self.w12 = nn.Linear(gc, e * ec)
        self.w3 = nn.Linear(e * ec // 2, ec)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Apply SwiGLU transformation to input features."""
        x12 = self.w12(x)
        x1, x2 = x12.chunk(2, dim=-1)
        hidden = F.silu(x1) * x2
        return self.w3(hidden)


class Residual(nn.Module):
    """Residual connection wrapper for neural network modules."""

    def __init__(self, m: nn.Module) -> None:
        """Initialize residual module with the wrapped module.

        Args:
            m (nn.Module): Module to wrap with residual connection.
        """
        super().__init__()
        self.m = m
        nn.init.zeros_(self.m.w3.bias)
        # For models with l scale, please change the initialization to
        # nn.init.constant_(self.m.w3.weight, 1e-6)
        nn.init.zeros_(self.m.w3.weight)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Apply residual connection to input features."""
        return x + self.m(x)


class SAVPE(nn.Module):
    """Spatial-Aware Visual Prompt Embedding module for feature enhancement."""

    def __init__(self, ch: list[int], c3: int, embed: int):
        """Initialize SAVPE module with channels, intermediate channels, and embedding dimension.

        Args:
            ch (list[int]): List of input channel dimensions.
            c3 (int): Intermediate channels.
            embed (int): Embedding dimension.
        """
        super().__init__()
        self.cv1 = nn.ModuleList(
            nn.Sequential(
                Conv(x, c3, 3), Conv(c3, c3, 3), nn.Upsample(scale_factor=i * 2) if i in {1, 2} else nn.Identity()
            )
            for i, x in enumerate(ch)
        )

        self.cv2 = nn.ModuleList(
            nn.Sequential(Conv(x, c3, 1), nn.Upsample(scale_factor=i * 2) if i in {1, 2} else nn.Identity())
            for i, x in enumerate(ch)
        )

        self.c = 16
        self.cv3 = nn.Conv2d(3 * c3, embed, 1)
        self.cv4 = nn.Conv2d(3 * c3, self.c, 3, padding=1)
        self.cv5 = nn.Conv2d(1, self.c, 3, padding=1)
        self.cv6 = nn.Sequential(Conv(2 * self.c, self.c, 3), nn.Conv2d(self.c, self.c, 3, padding=1))

    def forward(self, x: list[torch.Tensor], vp: torch.Tensor) -> torch.Tensor:
        """Process input features and visual prompts to generate enhanced embeddings."""
        y = [self.cv2[i](xi) for i, xi in enumerate(x)]
        y = self.cv4(torch.cat(y, dim=1))

        x = [self.cv1[i](xi) for i, xi in enumerate(x)]
        x = self.cv3(torch.cat(x, dim=1))

        B, C, H, W = x.shape

        Q = vp.shape[1]

        x = x.view(B, C, -1)

        y = y.reshape(B, 1, self.c, H, W).expand(-1, Q, -1, -1, -1).reshape(B * Q, self.c, H, W)
        vp = vp.reshape(B, Q, 1, H, W).reshape(B * Q, 1, H, W)

        y = self.cv6(torch.cat((y, self.cv5(vp)), dim=1))

        y = y.reshape(B, Q, self.c, -1)
        vp = vp.reshape(B, Q, 1, -1)

        score = y * vp + torch.logical_not(vp) * torch.finfo(y.dtype).min
        score = F.softmax(score, dim=-1).to(y.dtype)
        aggregated = score.transpose(-2, -3) @ x.reshape(B, self.c, C // self.c, -1).transpose(-1, -2)

        return F.normalize(aggregated.transpose(-2, -3).reshape(B, Q, -1), dim=-1, p=2)


class Proto26(Proto):
    """Ultralytics YOLO26 models mask Proto module for segmentation models."""

    def __init__(self, ch: tuple = (), c_: int = 256, c2: int = 32, nc: int = 80):
        """Initialize the Ultralytics YOLO models mask Proto module with specified number of protos and masks.

        Args:
            ch (tuple): Tuple of channel sizes from backbone feature maps.
            c_ (int): Intermediate channels.
            c2 (int): Output channels (number of protos).
            nc (int): Number of classes for semantic segmentation.
        """
        super().__init__(c_, c_, c2)
        self.feat_refine = nn.ModuleList(Conv(x, ch[0], k=1) for x in ch[1:])
        self.feat_fuse = Conv(ch[0], c_, k=3)
        self.semseg = nn.Sequential(Conv(ch[0], c_, k=3), Conv(c_, c_, k=3), nn.Conv2d(c_, nc, 1))

    def forward(self, x: torch.Tensor, return_semseg: bool = True) -> torch.Tensor:
        """Perform a forward pass by fusing multi-scale feature maps and generating proto masks."""
        feat = x[0]
        for i, f in enumerate(self.feat_refine):
            up_feat = f(x[i + 1])
            up_feat = F.interpolate(up_feat, size=feat.shape[2:], mode="nearest")
            feat = feat + up_feat
        p = super().forward(self.feat_fuse(feat))
        if self.training and return_semseg:
            semseg = self.semseg(feat)
            return (p, semseg)
        return p

    def fuse(self):
        """Fuse the model for inference by removing the semantic segmentation head."""
        self.semseg = None


class RealNVP(nn.Module):
    """RealNVP: a flow-based generative model.

    References:
        https://arxiv.org/abs/1605.08803
        https://github.com/open-mmlab/mmpose/blob/main/mmpose/models/utils/realnvp.py
    """

    @staticmethod
    def nets():
        """Get the scale model in a single invertible mapping."""
        return nn.Sequential(nn.Linear(2, 64), nn.SiLU(), nn.Linear(64, 64), nn.SiLU(), nn.Linear(64, 2), nn.Tanh())

    @staticmethod
    def nett():
        """Get the translation model in a single invertible mapping."""
        return nn.Sequential(nn.Linear(2, 64), nn.SiLU(), nn.Linear(64, 64), nn.SiLU(), nn.Linear(64, 2))

    @property
    def prior(self):
        """The prior distribution."""
        return torch.distributions.MultivariateNormal(self.loc, self.cov)

    def __init__(self):
        super().__init__()

        self.register_buffer("loc", torch.zeros(2))
        self.register_buffer("cov", torch.eye(2))
        self.register_buffer("mask", torch.tensor([[0, 1], [1, 0]] * 3, dtype=torch.float32))

        self.s = torch.nn.ModuleList([self.nets() for _ in range(len(self.mask))])
        self.t = torch.nn.ModuleList([self.nett() for _ in range(len(self.mask))])
        self.init_weights()

    def init_weights(self):
        """Initialize model weights."""
        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.xavier_uniform_(m.weight, gain=0.01)

    def backward_p(self, x):
        """Apply mapping from the data space to the latent space and calculate the log determinant of the Jacobian
        matrix.
        """
        log_det_jacob, z = x.new_zeros(x.shape[0]), x
        for i in reversed(range(len(self.t))):
            z_ = self.mask[i] * z
            s = self.s[i](z_) * (1 - self.mask[i])
            t = self.t[i](z_) * (1 - self.mask[i])
            z = (1 - self.mask[i]) * (z - t) * torch.exp(-s) + z_
            log_det_jacob -= s.sum(dim=1)
        return z, log_det_jacob

    def log_prob(self, x):
        """Calculate the log probability of given sample in data space."""
        if x.dtype == torch.float32 and self.s[0][0].weight.dtype != torch.float32:
            self.float()
        z, log_det = self.backward_p(x)
        return self.prior.log_prob(z) + log_det

```

`ultralytics/nn/modules/__init__.py`

```python
# Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license
"""
Ultralytics neural network modules.

This module provides access to various neural network components used in Ultralytics models, including convolution
blocks, attention mechanisms, transformer components, and detection/segmentation heads.

Examples:
    Visualize a module with Netron
    >>> from ultralytics.nn.modules import Conv
    >>> import torch
    >>> import subprocess
    >>> x = torch.ones(1, 128, 40, 40)
    >>> m = Conv(128, 128)
    >>> f = f"{m._get_name()}.onnx"
    >>> torch.onnx.export(m, x, f)
    >>> subprocess.run(f"onnxslim {f} {f} && open {f}", shell=True, check=True)  # pip install onnxslim
"""

from .block import (
    C1,
    C2,
    C2PSA,
    C3,
    C3TR,
    CIB,
    DFL,
    ELAN1,
    PSA,
    SPP,
    SPPELAN,
    SPPF,
    A2C2f,
    AConv,
    ADown,
    Attention,
    BNContrastiveHead,
    Bottleneck,
    BottleneckCSP,
    C2f,
    C2fAttn,
    C2fCIB,
    C2fPSA,
    SEBlock,
    C3Ghost,
    C3k2,
    C3x,
    CBFuse,
    CBLinear,
    ContrastiveHead,
    GhostBottleneck,
    HGBlock,
    HGStem,
    ImagePoolingAttn,
    MaxSigmoidAttnBlock,
    Proto,
    RepC3,
    RepNCSPELAN4,
    RepVGGDW,
    ResNetLayer,
    SCDown,
    TorchVision,
)
from .conv import (
    CBAM,
    ChannelAttention,
    Concat,
    Conv,
    Conv2,
    ConvTranspose,
    DWConv,
    DWConvTranspose2d,
    Focus,
    GhostConv,
    Index,
    LightConv,
    RepConv,
    SpatialAttention,
)
from .head import (
    OBB,
    OBB26,
    Classify,
    Detect,
    LRPCHead,
    Pose,
    Pose26,
    RTDETRDecoder,
    Segment,
    Segment26,
    WorldDetect,
    YOLOEDetect,
    YOLOESegment,
    YOLOESegment26,
    v10Detect,
)
from .transformer import (
    AIFI,
    MLP,
    DeformableTransformerDecoder,
    DeformableTransformerDecoderLayer,
    LayerNorm2d,
    MLPBlock,
    MSDeformAttn,
    TransformerBlock,
    TransformerEncoderLayer,
    TransformerLayer,
)

__all__ = (
    "AIFI",
    "C1",
    "C2",
    "C2PSA",
    "C3",
    "C3TR",
    "CBAM",
    "CIB",
    "DFL",
    "ELAN1",
    "MLP",
    "OBB",
    "OBB26",
    "PSA",
    "SPP",
    "SPPELAN",
    "SPPF",
    "A2C2f",
    "AConv",
    "ADown",
    "Attention",
    "BNContrastiveHead",
    "Bottleneck",
    "BottleneckCSP",
    "C2f",
    "C2fAttn",
    "C2fCIB",
    "C2fPSA",
    "SEBlock",
    "C3Ghost",
    "C3k2",
    "C3x",
    "CBFuse",
    "CBLinear",
    "ChannelAttention",
    "Classify",
    "Concat",
    "ContrastiveHead",
    "Conv",
    "Conv2",
    "ConvTranspose",
    "DWConv",
    "DWConvTranspose2d",
    "DeformableTransformerDecoder",
    "DeformableTransformerDecoderLayer",
    "Detect",
    "Focus",
    "GhostBottleneck",
    "GhostConv",
    "HGBlock",
    "HGStem",
    "ImagePoolingAttn",
    "Index",
    "LRPCHead",
    "LayerNorm2d",
    "LightConv",
    "MLPBlock",
    "MSDeformAttn",
    "MaxSigmoidAttnBlock",
    "Pose",
    "Pose26",
    "Proto",
    "RTDETRDecoder",
    "RepC3",
    "RepConv",
    "RepNCSPELAN4",
    "RepVGGDW",
    "ResNetLayer",
    "SCDown",
    "Segment",
    "Segment26",
    "SpatialAttention",
    "TorchVision",
    "TransformerBlock",
    "TransformerEncoderLayer",
    "TransformerLayer",
    "WorldDetect",
    "YOLOEDetect",
    "YOLOESegment",
    "YOLOESegment26",
    "v10Detect",
)

```

`	ultralytics/nn/tasks.py`

```python
# Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import contextlib
import pickle
import re
import types
from copy import deepcopy
from pathlib import Path

import torch
import torch.nn as nn

from ultralytics.nn.autobackend import check_class_names
from ultralytics.nn.modules import (
    AIFI,
    C1,
    C2,
    C2PSA,
    C3,
    C3TR,
    ELAN1,
    OBB,
    OBB26,
    PSA,
    SPP,
    SPPELAN,
    SPPF,
    A2C2f,
    AConv,
    ADown,
    Bottleneck,
    BottleneckCSP,
    C2f,
    C2fAttn,
    C2fCIB,
    C2fPSA,
    SEBlock,
    C3Ghost,
    C3k2,
    C3x,
    CBFuse,
    CBLinear,
    Classify,
    Concat,
    Conv,
    Conv2,
    ConvTranspose,
    Detect,
    DWConv,
    DWConvTranspose2d,
    Focus,
    GhostBottleneck,
    GhostConv,
    HGBlock,
    HGStem,
    ImagePoolingAttn,
    Index,
    LRPCHead,
    Pose,
    Pose26,
    RepC3,
    RepConv,
    RepNCSPELAN4,
    RepVGGDW,
    ResNetLayer,
    RTDETRDecoder,
    SCDown,
    Segment,
    Segment26,
    TorchVision,
    WorldDetect,
    YOLOEDetect,
    YOLOESegment,
    YOLOESegment26,
    v10Detect,
)
from ultralytics.utils import DEFAULT_CFG_DICT, LOGGER, WINDOWS, YAML, colorstr, emojis
from ultralytics.utils.checks import check_requirements, check_suffix, check_yaml
from ultralytics.utils.loss import (
    E2ELoss,
    PoseLoss26,
    v8ClassificationLoss,
    v8DetectionLoss,
    v8OBBLoss,
    v8PoseLoss,
    v8SegmentationLoss,
)
from ultralytics.utils.ops import make_divisible
from ultralytics.utils.patches import torch_load
from ultralytics.utils.plotting import feature_visualization
from ultralytics.utils.torch_utils import (
    fuse_conv_and_bn,
    fuse_deconv_and_bn,
    initialize_weights,
    intersect_dicts,
    model_info,
    scale_img,
    smart_inference_mode,
    time_sync,
)


class BaseModel(torch.nn.Module):
    """Base class for all YOLO models in the Ultralytics family.

    This class provides common functionality for YOLO models including forward pass handling, model fusion, information
    display, and weight loading capabilities.

    Attributes:
        model (torch.nn.Sequential): The neural network model.
        save (list): List of layer indices to save outputs from.
        stride (torch.Tensor): Model stride values.

    Methods:
        forward: Perform forward pass for training or inference.
        predict: Perform inference on input tensor.
        fuse: Fuse Conv/BatchNorm layers and reparameterize for optimization.
        info: Print model information.
        load: Load weights into the model.
        loss: Compute loss for training.

    Examples:
        Create a BaseModel instance
        >>> model = BaseModel()
        >>> model.info()  # Display model information
    """

    def forward(self, x, *args, **kwargs):
        """Perform forward pass of the model for either training or inference.

        If x is a dict, calculates and returns the loss for training. Otherwise, returns predictions for inference.

        Args:
            x (torch.Tensor | dict): Input tensor for inference, or dict with image tensor and labels for training.
            *args (Any): Variable length argument list.
            **kwargs (Any): Arbitrary keyword arguments.

        Returns:
            (torch.Tensor): Loss if x is a dict (training), or network predictions (inference).
        """
        if isinstance(x, dict):  # for cases of training and validating while training.
            return self.loss(x, *args, **kwargs)
        return self.predict(x, *args, **kwargs)

    def predict(self, x, profile=False, visualize=False, augment=False, embed=None):
        """Perform a forward pass through the network.

        Args:
            x (torch.Tensor): The input tensor to the model.
            profile (bool): Print the computation time of each layer if True.
            visualize (bool): Save the feature maps of the model if True.
            augment (bool): Augment image during prediction.
            embed (list, optional): A list of layer indices to return embeddings from.

        Returns:
            (torch.Tensor): The last output of the model.
        """
        if augment:
            return self._predict_augment(x)
        return self._predict_once(x, profile, visualize, embed)

    def _predict_once(self, x, profile=False, visualize=False, embed=None):
        """Perform a forward pass through the network.

        Args:
            x (torch.Tensor): The input tensor to the model.
            profile (bool): Print the computation time of each layer if True.
            visualize (bool): Save the feature maps of the model if True.
            embed (list, optional): A list of layer indices to return embeddings from.

        Returns:
            (torch.Tensor): The last output of the model.
        """
        y, dt, embeddings = [], [], []  # outputs
        embed = frozenset(embed) if embed is not None else {-1}
        max_idx = max(embed)
        for m in self.model:
            if m.f != -1:  # if not from previous layer
                x = y[m.f] if isinstance(m.f, int) else [x if j == -1 else y[j] for j in m.f]  # from earlier layers
            if profile:
                self._profile_one_layer(m, x, dt)
            x = m(x)  # run
            y.append(x if m.i in self.save else None)  # save output
            if visualize:
                feature_visualization(x, m.type, m.i, save_dir=visualize)
            if m.i in embed:
                embeddings.append(torch.nn.functional.adaptive_avg_pool2d(x, (1, 1)).squeeze(-1).squeeze(-1))  # flatten
                if m.i == max_idx:
                    return torch.unbind(torch.cat(embeddings, 1), dim=0)
        return x

    def _predict_augment(self, x):
        """Perform augmentations on input image x and return augmented inference."""
        LOGGER.warning(
            f"{self.__class__.__name__} does not support 'augment=True' prediction. "
            f"Reverting to single-scale prediction."
        )
        return self._predict_once(x)

    def _profile_one_layer(self, m, x, dt):
        """Profile the computation time and FLOPs of a single layer of the model on a given input.

        Args:
            m (torch.nn.Module): The layer to be profiled.
            x (torch.Tensor): The input data to the layer.
            dt (list): A list to store the computation time of the layer.
        """
        try:
            import thop
        except ImportError:
            thop = None  # conda support without 'ultralytics-thop' installed

        c = m == self.model[-1] and isinstance(x, list)  # is final layer list, copy input as inplace fix
        flops = thop.profile(m, inputs=[x.copy() if c else x], verbose=False)[0] / 1e9 * 2 if thop else 0  # GFLOPs
        t = time_sync()
        for _ in range(10):
            m(x.copy() if c else x)
        dt.append((time_sync() - t) * 100)
        if m == self.model[0]:
            LOGGER.info(f"{'time (ms)':>10s} {'GFLOPs':>10s} {'params':>10s}  module")
        LOGGER.info(f"{dt[-1]:10.2f} {flops:10.2f} {m.np:10.0f}  {m.type}")
        if c:
            LOGGER.info(f"{sum(dt):10.2f} {'-':>10s} {'-':>10s}  Total")

    def fuse(self, verbose=True):
        """Fuse Conv/ConvTranspose and BatchNorm layers, and reparameterize RepConv/RepVGGDW for improved efficiency.

        Args:
            verbose (bool): Whether to print model information after fusion.

        Returns:
            (torch.nn.Module): The fused model is returned.
        """
        if not self.is_fused():
            for m in self.model.modules():
                if isinstance(m, (Conv, Conv2, DWConv)) and hasattr(m, "bn"):
                    if isinstance(m, Conv2):
                        m.fuse_convs()
                    m.conv = fuse_conv_and_bn(m.conv, m.bn)  # update conv
                    delattr(m, "bn")  # remove batchnorm
                    m.forward = m.forward_fuse  # update forward
                if isinstance(m, ConvTranspose) and hasattr(m, "bn"):
                    m.conv_transpose = fuse_deconv_and_bn(m.conv_transpose, m.bn)
                    delattr(m, "bn")  # remove batchnorm
                    m.forward = m.forward_fuse  # update forward
                if isinstance(m, RepConv):
                    m.fuse_convs()
                    m.forward = m.forward_fuse  # update forward
                if isinstance(m, RepVGGDW):
                    m.fuse()
                    m.forward = m.forward_fuse
                if isinstance(m, Detect) and getattr(m, "end2end", False):
                    m.fuse()  # remove one2many head
            self.info(verbose=verbose)

        return self

    def is_fused(self, thresh=10):
        """Check if the model has less than a certain threshold of normalization layers.

        Args:
            thresh (int, optional): The threshold number of normalization layers.

        Returns:
            (bool): True if the number of normalization layers in the model is less than the threshold, False otherwise.
        """
        bn = tuple(v for k, v in torch.nn.__dict__.items() if "Norm" in k)  # normalization layers, i.e. BatchNorm2d()
        return sum(isinstance(v, bn) for v in self.modules()) < thresh  # True if < 'thresh' BatchNorm layers in model

    def info(self, detailed=False, verbose=True, imgsz=640):
        """Print model information.

        Args:
            detailed (bool): If True, prints out detailed information about the model.
            verbose (bool): If True, prints out the model information.
            imgsz (int): The size of the image used for computing model information.
        """
        return model_info(self, detailed=detailed, verbose=verbose, imgsz=imgsz)

    def _apply(self, fn):
        """Apply a function to all tensors in the model, including Detect head attributes like stride and anchors.

        Args:
            fn (function): The function to apply to the model.

        Returns:
            (BaseModel): An updated BaseModel object.
        """
        self = super()._apply(fn)
        m = self.model[-1]  # Detect()
        if isinstance(
            m, Detect
        ):  # includes all Detect subclasses like Segment, Pose, OBB, WorldDetect, YOLOEDetect, YOLOESegment
            m.stride = fn(m.stride)
            m.anchors = fn(m.anchors)
            m.strides = fn(m.strides)
        return self

    def load(self, weights, verbose=True):
        """Load weights into the model.

        Args:
            weights (dict | torch.nn.Module): The pre-trained weights to be loaded.
            verbose (bool, optional): Whether to log the transfer progress.
        """
        model = weights["model"] if isinstance(weights, dict) else weights  # torchvision models are not dicts
        csd = model.float().state_dict()  # checkpoint state_dict as FP32
        updated_csd = intersect_dicts(csd, self.state_dict())  # intersect
        self.load_state_dict(updated_csd, strict=False)  # load
        len_updated_csd = len(updated_csd)
        first_conv = "model.0.conv.weight"  # hard-coded to yolo models for now
        # mostly used to boost multi-channel training
        state_dict = self.state_dict()
        if first_conv not in updated_csd and first_conv in state_dict:
            c1, c2, h, w = state_dict[first_conv].shape
            cc1, cc2, ch, cw = csd[first_conv].shape
            if ch == h and cw == w:
                c1, c2 = min(c1, cc1), min(c2, cc2)
                state_dict[first_conv][:c1, :c2] = csd[first_conv][:c1, :c2]
                len_updated_csd += 1
        if verbose:
            LOGGER.info(f"Transferred {len_updated_csd}/{len(self.model.state_dict())} items from pretrained weights")

    def loss(self, batch, preds=None):
        """Compute loss.

        Args:
            batch (dict): Batch to compute loss on.
            preds (torch.Tensor | list[torch.Tensor], optional): Predictions.
        """
        if getattr(self, "criterion", None) is None:
            self.criterion = self.init_criterion()

        if preds is None:
            preds = self.forward(batch["img"])
        return self.criterion(preds, batch)

    def init_criterion(self):
        """Initialize the loss criterion for the BaseModel."""
        raise NotImplementedError("compute_loss() needs to be implemented by task heads")


class DetectionModel(BaseModel):
    """YOLO detection model.

    This class implements the YOLO detection architecture, handling model initialization, forward pass, augmented
    inference, and loss computation for object detection tasks.

    Attributes:
        yaml (dict): Model configuration dictionary.
        model (torch.nn.Sequential): The neural network model.
        save (list): List of layer indices to save outputs from.
        names (dict): Class names dictionary.
        inplace (bool): Whether to use inplace operations.
        end2end (bool): Whether the model uses end-to-end detection.
        stride (torch.Tensor): Model stride values.

    Methods:
        __init__: Initialize the YOLO detection model.
        _predict_augment: Perform augmented inference.
        _descale_pred: De-scale predictions following augmented inference.
        _clip_augmented: Clip YOLO augmented inference tails.
        init_criterion: Initialize the loss criterion.

    Examples:
        Initialize a detection model
        >>> model = DetectionModel("yolo26n.yaml", ch=3, nc=80)
        >>> results = model.predict(image_tensor)
    """

    def __init__(self, cfg="yolo26n.yaml", ch=3, nc=None, verbose=True):
        """Initialize the YOLO detection model with the given config and parameters.

        Args:
            cfg (str | dict): Model configuration file path or dictionary.
            ch (int): Number of input channels.
            nc (int, optional): Number of classes.
            verbose (bool): Whether to display model information.
        """
        super().__init__()
        self.yaml = cfg if isinstance(cfg, dict) else yaml_model_load(cfg)  # cfg dict
        if self.yaml["backbone"][0][2] == "Silence":
            LOGGER.warning(
                "YOLOv9 `Silence` module is deprecated in favor of torch.nn.Identity. "
                "Please delete local *.pt file and re-download the latest model checkpoint."
            )
            self.yaml["backbone"][0][2] = "nn.Identity"

        # Define model
        self.yaml["channels"] = ch  # save channels
        if nc and nc != self.yaml["nc"]:
            LOGGER.info(f"Overriding model.yaml nc={self.yaml['nc']} with nc={nc}")
            self.yaml["nc"] = nc  # override YAML value
        self.model, self.save = parse_model(deepcopy(self.yaml), ch=ch, verbose=verbose)  # model, savelist
        self.names = {i: f"{i}" for i in range(self.yaml["nc"])}  # default names dict
        self.inplace = self.yaml.get("inplace", True)

        # Build strides
        m = self.model[-1]  # Detect()
        if isinstance(m, Detect):  # includes all Detect subclasses like Segment, Pose, OBB, YOLOEDetect, YOLOESegment
            s = 256  # 2x min stride
            m.inplace = self.inplace

            def _forward(x):
                """Perform a forward pass through the model, handling different Detect subclass types accordingly."""
                output = self.forward(x)
                if self.end2end:
                    output = output["one2many"]
                return output["feats"]

            self.model.eval()  # Avoid changing batch statistics until training begins
            m.training = True  # Setting it to True to properly return strides
            m.stride = torch.tensor([s / x.shape[-2] for x in _forward(torch.zeros(1, ch, s, s))])  # forward
            self.stride = m.stride
            self.model.train()  # Set model back to training(default) mode
            m.bias_init()  # only run once
        else:
            self.stride = torch.Tensor([32])  # default stride, e.g., RTDETR

        # Init weights, biases
        initialize_weights(self)
        if verbose:
            self.info()
            LOGGER.info("")

    @property
    def end2end(self):
        """Return whether the model uses end-to-end NMS-free detection."""
        return getattr(self.model[-1], "end2end", False)

    @end2end.setter
    def end2end(self, value):
        """Override the end-to-end detection mode."""
        self.set_head_attr(end2end=value)

    def set_head_attr(self, **kwargs):
        """Set attributes of the model head (last layer).

        Args:
            **kwargs (Any): Arbitrary keyword arguments representing attributes to set.
        """
        head = self.model[-1]
        for k, v in kwargs.items():
            if not hasattr(head, k):
                LOGGER.warning(f"Head has no attribute '{k}'.")
                continue
            setattr(head, k, v)

    def _predict_augment(self, x):
        """Perform augmentations on input image x and return augmented inference and train outputs.

        Args:
            x (torch.Tensor): Input image tensor.

        Returns:
            (tuple[torch.Tensor, None]): Augmented inference output and None for train output.
        """
        if getattr(self, "end2end", False) or self.__class__.__name__ != "DetectionModel":
            LOGGER.warning("Model does not support 'augment=True', reverting to single-scale prediction.")
            return self._predict_once(x)
        img_size = x.shape[-2:]  # height, width
        s = [1, 0.83, 0.67]  # scales
        f = [None, 3, None]  # flips (2-ud, 3-lr)
        y = []  # outputs
        for si, fi in zip(s, f):
            xi = scale_img(x.flip(fi) if fi else x, si, gs=int(self.stride.max()))
            yi = super().predict(xi)[0]  # forward
            yi = self._descale_pred(yi, fi, si, img_size)
            y.append(yi)
        y = self._clip_augmented(y)  # clip augmented tails
        return torch.cat(y, -1), None  # augmented inference, train

    @staticmethod
    def _descale_pred(p, flips, scale, img_size, dim=1):
        """De-scale predictions following augmented inference (inverse operation).

        Args:
            p (torch.Tensor): Predictions tensor.
            flips (int | None): Flip type (None=none, 2=ud, 3=lr).
            scale (float): Scale factor.
            img_size (tuple): Original image size (height, width).
            dim (int): Dimension to split at.

        Returns:
            (torch.Tensor): De-scaled predictions.
        """
        p[:, :4] /= scale  # de-scale
        x, y, wh, cls = p.split((1, 1, 2, p.shape[dim] - 4), dim)
        if flips == 2:
            y = img_size[0] - y  # de-flip ud
        elif flips == 3:
            x = img_size[1] - x  # de-flip lr
        return torch.cat((x, y, wh, cls), dim)

    def _clip_augmented(self, y):
        """Clip YOLO augmented inference tails.

        Args:
            y (list[torch.Tensor]): List of detection tensors.

        Returns:
            (list[torch.Tensor]): Clipped detection tensors.
        """
        nl = self.model[-1].nl  # number of detection layers (P3-P5)
        g = sum(4**x for x in range(nl))  # grid points
        e = 1  # exclude layer count
        i = (y[0].shape[-1] // g) * sum(4**x for x in range(e))  # indices
        y[0] = y[0][..., :-i]  # large
        i = (y[-1].shape[-1] // g) * sum(4 ** (nl - 1 - x) for x in range(e))  # indices
        y[-1] = y[-1][..., i:]  # small
        return y

    def init_criterion(self):
        """Initialize the loss criterion for the DetectionModel."""
        return E2ELoss(self) if getattr(self, "end2end", False) else v8DetectionLoss(self)


class OBBModel(DetectionModel):
    """YOLO Oriented Bounding Box (OBB) model.

    This class extends DetectionModel to handle oriented bounding box detection tasks, providing specialized loss
    computation for rotated object detection.

    Methods:
        __init__: Initialize YOLO OBB model.
        init_criterion: Initialize the loss criterion for OBB detection.

    Examples:
        Initialize an OBB model
        >>> model = OBBModel("yolo26n-obb.yaml", ch=3, nc=80)
        >>> results = model.predict(image_tensor)
    """

    def __init__(self, cfg="yolo26n-obb.yaml", ch=3, nc=None, verbose=True):
        """Initialize YOLO OBB model with given config and parameters.

        Args:
            cfg (str | dict): Model configuration file path or dictionary.
            ch (int): Number of input channels.
            nc (int, optional): Number of classes.
            verbose (bool): Whether to display model information.
        """
        super().__init__(cfg=cfg, ch=ch, nc=nc, verbose=verbose)

    def init_criterion(self):
        """Initialize the loss criterion for the model."""
        return E2ELoss(self, v8OBBLoss) if getattr(self, "end2end", False) else v8OBBLoss(self)


class SegmentationModel(DetectionModel):
    """YOLO segmentation model.

    This class extends DetectionModel to handle instance segmentation tasks, providing specialized loss computation for
    pixel-level object detection and segmentation.

    Methods:
        __init__: Initialize YOLO segmentation model.
        init_criterion: Initialize the loss criterion for segmentation.

    Examples:
        Initialize a segmentation model
        >>> model = SegmentationModel("yolo26n-seg.yaml", ch=3, nc=80)
        >>> results = model.predict(image_tensor)
    """

    def __init__(self, cfg="yolo26n-seg.yaml", ch=3, nc=None, verbose=True):
        """Initialize Ultralytics YOLO segmentation model with given config and parameters.

        Args:
            cfg (str | dict): Model configuration file path or dictionary.
            ch (int): Number of input channels.
            nc (int, optional): Number of classes.
            verbose (bool): Whether to display model information.
        """
        super().__init__(cfg=cfg, ch=ch, nc=nc, verbose=verbose)

    def init_criterion(self):
        """Initialize the loss criterion for the SegmentationModel."""
        return E2ELoss(self, v8SegmentationLoss) if getattr(self, "end2end", False) else v8SegmentationLoss(self)


class PoseModel(DetectionModel):
    """YOLO pose model.

    This class extends DetectionModel to handle human pose estimation tasks, providing specialized loss computation for
    keypoint detection and pose estimation.

    Attributes:
        kpt_shape (tuple): Shape of keypoints data (num_keypoints, num_dimensions).

    Methods:
        __init__: Initialize YOLO pose model.
        init_criterion: Initialize the loss criterion for pose estimation.

    Examples:
        Initialize a pose model
        >>> model = PoseModel("yolo26n-pose.yaml", ch=3, nc=1, data_kpt_shape=(17, 3))
        >>> results = model.predict(image_tensor)
    """

    def __init__(self, cfg="yolo26n-pose.yaml", ch=3, nc=None, data_kpt_shape=(None, None), verbose=True):
        """Initialize Ultralytics YOLO Pose model.

        Args:
            cfg (str | dict): Model configuration file path or dictionary.
            ch (int): Number of input channels.
            nc (int, optional): Number of classes.
            data_kpt_shape (tuple): Shape of keypoints data.
            verbose (bool): Whether to display model information.
        """
        if not isinstance(cfg, dict):
            cfg = yaml_model_load(cfg)  # load model YAML
        if any(data_kpt_shape) and list(data_kpt_shape) != list(cfg["kpt_shape"]):
            LOGGER.info(f"Overriding model.yaml kpt_shape={cfg['kpt_shape']} with kpt_shape={data_kpt_shape}")
            cfg["kpt_shape"] = data_kpt_shape
        super().__init__(cfg=cfg, ch=ch, nc=nc, verbose=verbose)

    def init_criterion(self):
        """Initialize the loss criterion for the PoseModel."""
        return E2ELoss(self, PoseLoss26) if getattr(self, "end2end", False) else v8PoseLoss(self)


class ClassificationModel(BaseModel):
    """YOLO classification model.

    This class implements the YOLO classification architecture for image classification tasks, providing model
    initialization, configuration, and output reshaping capabilities.

    Attributes:
        yaml (dict): Model configuration dictionary.
        model (torch.nn.Sequential): The neural network model.
        stride (torch.Tensor): Model stride values.
        names (dict): Class names dictionary.

    Methods:
        __init__: Initialize ClassificationModel.
        _from_yaml: Set model configurations and define architecture.
        reshape_outputs: Update model to specified class count.
        init_criterion: Initialize the loss criterion.

    Examples:
        Initialize a classification model
        >>> model = ClassificationModel("yolo26n-cls.yaml", ch=3, nc=1000)
        >>> results = model.predict(image_tensor)
    """

    def __init__(self, cfg="yolo26n-cls.yaml", ch=3, nc=None, verbose=True):
        """Initialize ClassificationModel with YAML, channels, number of classes, verbose flag.

        Args:
            cfg (str | dict): Model configuration file path or dictionary.
            ch (int): Number of input channels.
            nc (int, optional): Number of classes.
            verbose (bool): Whether to display model information.
        """
        super().__init__()
        self._from_yaml(cfg, ch, nc, verbose)

    def _from_yaml(self, cfg, ch, nc, verbose):
        """Set Ultralytics YOLO model configurations and define the model architecture.

        Args:
            cfg (str | dict): Model configuration file path or dictionary.
            ch (int): Number of input channels.
            nc (int, optional): Number of classes.
            verbose (bool): Whether to display model information.
        """
        self.yaml = cfg if isinstance(cfg, dict) else yaml_model_load(cfg)  # cfg dict

        # Define model
        ch = self.yaml["channels"] = self.yaml.get("channels", ch)  # input channels
        if nc and nc != self.yaml["nc"]:
            LOGGER.info(f"Overriding model.yaml nc={self.yaml['nc']} with nc={nc}")
            self.yaml["nc"] = nc  # override YAML value
        elif not nc and not self.yaml.get("nc", None):
            raise ValueError("nc not specified. Must specify nc in model.yaml or function arguments.")
        self.model, self.save = parse_model(deepcopy(self.yaml), ch=ch, verbose=verbose)  # model, savelist
        self.stride = torch.Tensor([1])  # no stride constraints
        self.names = {i: f"{i}" for i in range(self.yaml["nc"])}  # default names dict
        self.info()

    @staticmethod
    def reshape_outputs(model, nc):
        """Update a TorchVision classification model to class count 'nc' if required.

        Args:
            model (torch.nn.Module): Model to update.
            nc (int): New number of classes.
        """
        name, m = list((model.model if hasattr(model, "model") else model).named_children())[-1]  # last module
        if isinstance(m, Classify):  # YOLO Classify() head
            if m.linear.out_features != nc:
                m.linear = torch.nn.Linear(m.linear.in_features, nc)
        elif isinstance(m, torch.nn.Linear):  # ResNet, EfficientNet
            if m.out_features != nc:
                setattr(model, name, torch.nn.Linear(m.in_features, nc))
        elif isinstance(m, torch.nn.Sequential):
            types = [type(x) for x in m]
            if torch.nn.Linear in types:
                i = len(types) - 1 - types[::-1].index(torch.nn.Linear)  # last torch.nn.Linear index
                if m[i].out_features != nc:
                    m[i] = torch.nn.Linear(m[i].in_features, nc)
            elif torch.nn.Conv2d in types:
                i = len(types) - 1 - types[::-1].index(torch.nn.Conv2d)  # last torch.nn.Conv2d index
                if m[i].out_channels != nc:
                    m[i] = torch.nn.Conv2d(
                        m[i].in_channels, nc, m[i].kernel_size, m[i].stride, bias=m[i].bias is not None
                    )

    def init_criterion(self):
        """Initialize the loss criterion for the ClassificationModel."""
        return v8ClassificationLoss()


class RTDETRDetectionModel(DetectionModel):
    """RTDETR (Real-time DEtection and Tracking using Transformers) Detection Model class.

    This class is responsible for constructing the RTDETR architecture, defining loss functions, and facilitating both
    the training and inference processes. RTDETR is an object detection and tracking model that extends from the
    DetectionModel base class.

    Attributes:
        nc (int): Number of classes for detection.
        criterion (RTDETRDetectionLoss): Loss function for training.

    Methods:
        __init__: Initialize the RTDETRDetectionModel.
        init_criterion: Initialize the loss criterion.
        loss: Compute loss for training.
        predict: Perform forward pass through the model.

    Examples:
        Initialize an RTDETR model
        >>> model = RTDETRDetectionModel("rtdetr-l.yaml", ch=3, nc=80)
        >>> results = model.predict(image_tensor)
    """

    def __init__(self, cfg="rtdetr-l.yaml", ch=3, nc=None, verbose=True):
        """Initialize the RTDETRDetectionModel.

        Args:
            cfg (str | dict): Configuration file name or path.
            ch (int): Number of input channels.
            nc (int, optional): Number of classes.
            verbose (bool): Print additional information during initialization.
        """
        super().__init__(cfg=cfg, ch=ch, nc=nc, verbose=verbose)

    def _apply(self, fn):
        """Apply a function to all tensors in the model, including decoder anchors and valid mask.

        Args:
            fn (function): The function to apply to the model.

        Returns:
            (RTDETRDetectionModel): An updated RTDETRDetectionModel object.
        """
        self = super()._apply(fn)
        m = self.model[-1]
        m.anchors = fn(m.anchors)
        m.valid_mask = fn(m.valid_mask)
        return self

    def init_criterion(self):
        """Initialize the loss criterion for the RTDETRDetectionModel."""
        from ultralytics.models.utils.loss import RTDETRDetectionLoss

        return RTDETRDetectionLoss(nc=self.nc, use_vfl=True)

    def loss(self, batch, preds=None):
        """Compute the loss for the given batch of data.

        Args:
            batch (dict): Dictionary containing image and label data.
            preds (tuple, optional): Precomputed model predictions.

        Returns:
            (torch.Tensor): Total loss value.
            (torch.Tensor): Main three losses in a tensor.
        """
        if not hasattr(self, "criterion"):
            self.criterion = self.init_criterion()

        img = batch["img"]
        # NOTE: preprocess gt_bbox and gt_labels to list.
        bs = img.shape[0]
        batch_idx = batch["batch_idx"]
        gt_groups = [(batch_idx == i).sum().item() for i in range(bs)]
        targets = {
            "cls": batch["cls"].to(img.device, dtype=torch.long).view(-1),
            "bboxes": batch["bboxes"].to(device=img.device),
            "batch_idx": batch_idx.to(img.device, dtype=torch.long).view(-1),
            "gt_groups": gt_groups,
        }

        if preds is None:
            preds = self.predict(img, batch=targets)
        dec_bboxes, dec_scores, enc_bboxes, enc_scores, dn_meta = preds if self.training else preds[1]
        if dn_meta is None:
            dn_bboxes, dn_scores = None, None
        else:
            dn_bboxes, dec_bboxes = torch.split(dec_bboxes, dn_meta["dn_num_split"], dim=2)
            dn_scores, dec_scores = torch.split(dec_scores, dn_meta["dn_num_split"], dim=2)

        dec_bboxes = torch.cat([enc_bboxes.unsqueeze(0), dec_bboxes])  # (7, bs, 300, 4)
        dec_scores = torch.cat([enc_scores.unsqueeze(0), dec_scores])

        loss = self.criterion(
            (dec_bboxes, dec_scores), targets, dn_bboxes=dn_bboxes, dn_scores=dn_scores, dn_meta=dn_meta
        )
        # NOTE: There are like 12 losses in RTDETR, backward with all losses but only show the main three losses.
        return sum(loss.values()), torch.as_tensor(
            [loss[k].detach() for k in ["loss_giou", "loss_class", "loss_bbox"]], device=img.device
        )

    def predict(self, x, profile=False, visualize=False, batch=None, augment=False, embed=None):
        """Perform a forward pass through the model.

        Args:
            x (torch.Tensor): The input tensor.
            profile (bool): If True, profile the computation time for each layer.
            visualize (bool): If True, save feature maps for visualization.
            batch (dict, optional): Ground truth data for evaluation.
            augment (bool): If True, perform data augmentation during inference.
            embed (list, optional): A list of layer indices to return embeddings from.

        Returns:
            (torch.Tensor): Model's output tensor.
        """
        y, dt, embeddings = [], [], []  # outputs
        embed = frozenset(embed) if embed is not None else {-1}
        max_idx = max(embed)
        for m in self.model[:-1]:  # except the head part
            if m.f != -1:  # if not from previous layer
                x = y[m.f] if isinstance(m.f, int) else [x if j == -1 else y[j] for j in m.f]  # from earlier layers
            if profile:
                self._profile_one_layer(m, x, dt)
            x = m(x)  # run
            y.append(x if m.i in self.save else None)  # save output
            if visualize:
                feature_visualization(x, m.type, m.i, save_dir=visualize)
            if m.i in embed:
                embeddings.append(torch.nn.functional.adaptive_avg_pool2d(x, (1, 1)).squeeze(-1).squeeze(-1))  # flatten
                if m.i == max_idx:
                    return torch.unbind(torch.cat(embeddings, 1), dim=0)
        head = self.model[-1]
        x = head([y[j] for j in head.f], batch)  # head inference
        return x


class WorldModel(DetectionModel):
    """YOLOv8 World Model.

    This class implements the YOLOv8 World model for open-vocabulary object detection, supporting text-based class
    specification and CLIP model integration for zero-shot detection capabilities.

    Attributes:
        txt_feats (torch.Tensor): Text feature embeddings for classes.
        clip_model (torch.nn.Module): CLIP model for text encoding.

    Methods:
        __init__: Initialize YOLOv8 world model.
        set_classes: Set classes for offline inference.
        get_text_pe: Get text positional embeddings.
        predict: Perform forward pass with text features.
        loss: Compute loss with text features.

    Examples:
        Initialize a world model
        >>> model = WorldModel("yolov8s-world.yaml", ch=3, nc=80)
        >>> model.set_classes(["person", "car", "bicycle"])
        >>> results = model.predict(image_tensor)
    """

    def __init__(self, cfg="yolov8s-world.yaml", ch=3, nc=None, verbose=True):
        """Initialize YOLOv8 world model with given config and parameters.

        Args:
            cfg (str | dict): Model configuration file path or dictionary.
            ch (int): Number of input channels.
            nc (int, optional): Number of classes.
            verbose (bool): Whether to display model information.
        """
        self.txt_feats = torch.randn(1, nc or 80, 512)  # features placeholder
        self.clip_model = None  # CLIP model placeholder
        super().__init__(cfg=cfg, ch=ch, nc=nc, verbose=verbose)

    def set_classes(self, text, batch=80, cache_clip_model=True):
        """Set classes in advance so that model could do offline-inference without clip model.

        Args:
            text (list[str]): List of class names.
            batch (int): Batch size for processing text tokens.
            cache_clip_model (bool): Whether to cache the CLIP model.
        """
        self.txt_feats = self.get_text_pe(text, batch=batch, cache_clip_model=cache_clip_model)
        self.model[-1].nc = len(text)

    def get_text_pe(self, text, batch=80, cache_clip_model=True):
        """Get text positional embeddings using the CLIP model.

        Args:
            text (list[str]): List of class names.
            batch (int): Batch size for processing text tokens.
            cache_clip_model (bool): Whether to cache the CLIP model.

        Returns:
            (torch.Tensor): Text positional embeddings.
        """
        from ultralytics.nn.text_model import build_text_model

        device = next(self.model.parameters()).device
        if not getattr(self, "clip_model", None) and cache_clip_model:
            # For backwards compatibility of models lacking clip_model attribute
            self.clip_model = build_text_model("clip:ViT-B/32", device=device)
        model = self.clip_model if cache_clip_model else build_text_model("clip:ViT-B/32", device=device)
        text_token = model.tokenize(text)
        txt_feats = [model.encode_text(token).detach() for token in text_token.split(batch)]
        txt_feats = txt_feats[0] if len(txt_feats) == 1 else torch.cat(txt_feats, dim=0)
        return txt_feats.reshape(-1, len(text), txt_feats.shape[-1])

    def predict(self, x, profile=False, visualize=False, txt_feats=None, augment=False, embed=None):
        """Perform a forward pass through the model.

        Args:
            x (torch.Tensor): The input tensor.
            profile (bool): If True, profile the computation time for each layer.
            visualize (bool): If True, save feature maps for visualization.
            txt_feats (torch.Tensor, optional): The text features, use it if it's given.
            augment (bool): If True, perform data augmentation during inference.
            embed (list, optional): A list of layer indices to return embeddings from.

        Returns:
            (torch.Tensor): Model's output tensor.
        """
        txt_feats = (self.txt_feats if txt_feats is None else txt_feats).to(device=x.device, dtype=x.dtype)
        if txt_feats.shape[0] != x.shape[0] or self.model[-1].export:
            txt_feats = txt_feats.expand(x.shape[0], -1, -1)
        ori_txt_feats = txt_feats.clone()
        y, dt, embeddings = [], [], []  # outputs
        embed = frozenset(embed) if embed is not None else {-1}
        max_idx = max(embed)
        for m in self.model:  # except the head part
            if m.f != -1:  # if not from previous layer
                x = y[m.f] if isinstance(m.f, int) else [x if j == -1 else y[j] for j in m.f]  # from earlier layers
            if profile:
                self._profile_one_layer(m, x, dt)
            if isinstance(m, C2fAttn):
                x = m(x, txt_feats)
            elif isinstance(m, WorldDetect):
                x = m(x, ori_txt_feats)
            elif isinstance(m, ImagePoolingAttn):
                txt_feats = m(x, txt_feats)
            else:
                x = m(x)  # run

            y.append(x if m.i in self.save else None)  # save output
            if visualize:
                feature_visualization(x, m.type, m.i, save_dir=visualize)
            if m.i in embed:
                embeddings.append(torch.nn.functional.adaptive_avg_pool2d(x, (1, 1)).squeeze(-1).squeeze(-1))  # flatten
                if m.i == max_idx:
                    return torch.unbind(torch.cat(embeddings, 1), dim=0)
        return x

    def loss(self, batch, preds=None):
        """Compute loss.

        Args:
            batch (dict): Batch to compute loss on.
            preds (torch.Tensor | list[torch.Tensor], optional): Predictions.
        """
        if not hasattr(self, "criterion"):
            self.criterion = self.init_criterion()

        if preds is None:
            preds = self.forward(batch["img"], txt_feats=batch["txt_feats"])
        return self.criterion(preds, batch)


class YOLOEModel(DetectionModel):
    """YOLOE detection model.

    This class implements the YOLOE architecture for efficient object detection with text and visual prompts, supporting
    both prompt-based and prompt-free inference modes.

    Attributes:
        pe (torch.Tensor): Prompt embeddings for classes.
        clip_model (torch.nn.Module): CLIP model for text encoding.

    Methods:
        __init__: Initialize YOLOE model.
        get_text_pe: Get text positional embeddings.
        get_visual_pe: Get visual embeddings.
        set_vocab: Set vocabulary for prompt-free model.
        get_vocab: Get fused vocabulary layer.
        set_classes: Set classes for offline inference.
        get_cls_pe: Get class positional embeddings.
        predict: Perform forward pass with prompts.
        loss: Compute loss with prompts.

    Examples:
        Initialize a YOLOE model
        >>> model = YOLOEModel("yoloe-v8s.yaml", ch=3, nc=80)
        >>> results = model.predict(image_tensor, tpe=text_embeddings)
    """

    def __init__(self, cfg="yoloe-v8s.yaml", ch=3, nc=None, verbose=True):
        """Initialize YOLOE model with given config and parameters.

        Args:
            cfg (str | dict): Model configuration file path or dictionary.
            ch (int): Number of input channels.
            nc (int, optional): Number of classes.
            verbose (bool): Whether to display model information.
        """
        super().__init__(cfg=cfg, ch=ch, nc=nc, verbose=verbose)
        self.text_model = self.yaml.get("text_model", "mobileclip:blt")

    @smart_inference_mode()
    def get_text_pe(self, text, batch=80, cache_clip_model=False, without_reprta=False):
        """Get text positional embeddings using the CLIP model.

        Args:
            text (list[str]): List of class names.
            batch (int): Batch size for processing text tokens.
            cache_clip_model (bool): Whether to cache the CLIP model.
            without_reprta (bool): Whether to return text embeddings without reprta module processing.

        Returns:
            (torch.Tensor): Text positional embeddings.
        """
        from ultralytics.nn.text_model import build_text_model

        device = next(self.model.parameters()).device
        if not getattr(self, "clip_model", None) and cache_clip_model:
            # For backwards compatibility of models lacking clip_model attribute
            self.clip_model = build_text_model(getattr(self, "text_model", "mobileclip:blt"), device=device)

        model = (
            self.clip_model
            if cache_clip_model
            else build_text_model(getattr(self, "text_model", "mobileclip:blt"), device=device)
        )
        text_token = model.tokenize(text)
        txt_feats = [model.encode_text(token).detach() for token in text_token.split(batch)]
        txt_feats = txt_feats[0] if len(txt_feats) == 1 else torch.cat(txt_feats, dim=0)
        txt_feats = txt_feats.reshape(-1, len(text), txt_feats.shape[-1])
        if without_reprta:
            return txt_feats

        head = self.model[-1]
        assert isinstance(head, YOLOEDetect)
        return head.get_tpe(txt_feats)  # run auxiliary text head

    @smart_inference_mode()
    def get_visual_pe(self, img, visual):
        """Get visual positional embeddings.

        Args:
            img (torch.Tensor): Input image tensor.
            visual (torch.Tensor): Visual features.

        Returns:
            (torch.Tensor): Visual positional embeddings.
        """
        return self(img, vpe=visual, return_vpe=True)

    def set_vocab(self, vocab, names):
        """Set vocabulary for the prompt-free model.

        Args:
            vocab (nn.ModuleList): List of vocabulary items.
            names (list[str]): List of class names.
        """
        assert not self.training
        head = self.model[-1]
        assert isinstance(head, YOLOEDetect)

        # Cache anchors for head
        device = next(self.parameters()).device
        self(torch.empty(1, 3, self.args["imgsz"], self.args["imgsz"]).to(device))  # warmup

        cv3 = getattr(head, "one2one_cv3", head.cv3)
        cv2 = getattr(head, "one2one_cv2", head.cv2)

        # re-parameterization for prompt-free model
        self.model[-1].lrpc = nn.ModuleList(
            LRPCHead(cls, pf[-1], loc[-1], enabled=i != 2) for i, (cls, pf, loc) in enumerate(zip(vocab, cv3, cv2))
        )
        for loc_head, cls_head in zip(head.cv2, head.cv3):
            assert isinstance(loc_head, nn.Sequential)
            assert isinstance(cls_head, nn.Sequential)
            del loc_head[-1]
            del cls_head[-1]
        self.model[-1].nc = len(names)
        self.names = check_class_names(names)

    def get_vocab(self, names):
        """Get fused vocabulary layer from the model.

        Args:
            names (list[str]): List of class names.

        Returns:
            (nn.ModuleList): List of vocabulary modules.
        """
        assert not self.training
        head = self.model[-1]
        assert isinstance(head, YOLOEDetect)
        assert not head.is_fused

        tpe = self.get_text_pe(names)
        self.set_classes(names, tpe)
        device = next(self.model.parameters()).device
        head.fuse(self.pe.to(device))  # fuse prompt embeddings to classify head

        cv3 = getattr(head, "one2one_cv3", head.cv3)
        vocab = nn.ModuleList()
        for cls_head in cv3:
            assert isinstance(cls_head, nn.Sequential)
            vocab.append(cls_head[-1])
        return vocab

    def set_classes(self, names, embeddings):
        """Set classes in advance so that model could do offline-inference without clip model.

        Args:
            names (list[str]): List of class names.
            embeddings (torch.Tensor): Embeddings tensor.
        """
        assert not hasattr(self.model[-1], "lrpc"), (
            "Prompt-free model does not support setting classes. Please try with Text/Visual prompt models."
        )
        assert embeddings.ndim == 3
        self.pe = embeddings
        self.model[-1].nc = len(names)
        self.names = check_class_names(names)

    def get_cls_pe(self, tpe, vpe):
        """Get class positional embeddings.

        Args:
            tpe (torch.Tensor | None): Text positional embeddings.
            vpe (torch.Tensor | None): Visual positional embeddings.

        Returns:
            (torch.Tensor): Class positional embeddings.
        """
        all_pe = []
        if tpe is not None:
            assert tpe.ndim == 3
            all_pe.append(tpe)
        if vpe is not None:
            assert vpe.ndim == 3
            all_pe.append(vpe)
        if not all_pe:
            all_pe.append(getattr(self, "pe", torch.zeros(1, 80, 512)))
        return torch.cat(all_pe, dim=1)

    def predict(
        self, x, profile=False, visualize=False, tpe=None, augment=False, embed=None, vpe=None, return_vpe=False
    ):
        """Perform a forward pass through the model.

        Args:
            x (torch.Tensor): The input tensor.
            profile (bool): If True, profile the computation time for each layer.
            visualize (bool): If True, save feature maps for visualization.
            tpe (torch.Tensor, optional): Text positional embeddings.
            augment (bool): If True, perform data augmentation during inference.
            embed (list, optional): A list of layer indices to return embeddings from.
            vpe (torch.Tensor, optional): Visual positional embeddings.
            return_vpe (bool): If True, return visual positional embeddings.

        Returns:
            (torch.Tensor): Model's output tensor.
        """
        y, dt, embeddings = [], [], []  # outputs
        b = x.shape[0]
        embed = frozenset(embed) if embed is not None else {-1}
        max_idx = max(embed)
        for m in self.model:  # except the head part
            if m.f != -1:  # if not from previous layer
                x = y[m.f] if isinstance(m.f, int) else [x if j == -1 else y[j] for j in m.f]  # from earlier layers
            if profile:
                self._profile_one_layer(m, x, dt)
            if isinstance(m, YOLOEDetect):
                vpe = m.get_vpe(x, vpe) if vpe is not None else None
                if return_vpe:
                    assert vpe is not None
                    assert not self.training
                    return vpe
                cls_pe = self.get_cls_pe(m.get_tpe(tpe), vpe).to(device=x[0].device, dtype=x[0].dtype)
                if cls_pe.shape[0] != b or m.export:
                    cls_pe = cls_pe.expand(b, -1, -1)
                x.append(cls_pe)  # adding cls embedding
            x = m(x)  # run

            y.append(x if m.i in self.save else None)  # save output
            if visualize:
                feature_visualization(x, m.type, m.i, save_dir=visualize)
            if m.i in embed:
                embeddings.append(torch.nn.functional.adaptive_avg_pool2d(x, (1, 1)).squeeze(-1).squeeze(-1))  # flatten
                if m.i == max_idx:
                    return torch.unbind(torch.cat(embeddings, 1), dim=0)
        return x

    def loss(self, batch, preds=None):
        """Compute loss.

        Args:
            batch (dict): Batch to compute loss on.
            preds (torch.Tensor | list[torch.Tensor], optional): Predictions.
        """
        if not hasattr(self, "criterion"):
            from ultralytics.utils.loss import TVPDetectLoss

            visual_prompt = batch.get("visuals", None) is not None  # TODO
            self.criterion = (
                (E2ELoss(self, TVPDetectLoss) if getattr(self, "end2end", False) else TVPDetectLoss(self))
                if visual_prompt
                else self.init_criterion()
            )
        if preds is None:
            preds = self.forward(
                batch["img"],
                tpe=None if "visuals" in batch else batch.get("txt_feats", None),
                vpe=batch.get("visuals", None),
            )
        return self.criterion(preds, batch)


class YOLOESegModel(YOLOEModel, SegmentationModel):
    """YOLOE segmentation model.

    This class extends YOLOEModel to handle instance segmentation tasks with text and visual prompts, providing
    specialized loss computation for pixel-level object detection and segmentation.

    Methods:
        __init__: Initialize YOLOE segmentation model.
        loss: Compute loss with prompts for segmentation.

    Examples:
        Initialize a YOLOE segmentation model
        >>> model = YOLOESegModel("yoloe-v8s-seg.yaml", ch=3, nc=80)
        >>> results = model.predict(image_tensor, tpe=text_embeddings)
    """

    def __init__(self, cfg="yoloe-v8s-seg.yaml", ch=3, nc=None, verbose=True):
        """Initialize YOLOE segmentation model with given config and parameters.

        Args:
            cfg (str | dict): Model configuration file path or dictionary.
            ch (int): Number of input channels.
            nc (int, optional): Number of classes.
            verbose (bool): Whether to display model information.
        """
        super().__init__(cfg=cfg, ch=ch, nc=nc, verbose=verbose)

    def loss(self, batch, preds=None):
        """Compute loss.

        Args:
            batch (dict): Batch to compute loss on.
            preds (torch.Tensor | list[torch.Tensor], optional): Predictions.
        """
        if not hasattr(self, "criterion"):
            from ultralytics.utils.loss import TVPSegmentLoss

            visual_prompt = batch.get("visuals", None) is not None  # TODO
            self.criterion = (
                (E2ELoss(self, TVPSegmentLoss) if getattr(self, "end2end", False) else TVPSegmentLoss(self))
                if visual_prompt
                else self.init_criterion()
            )

        if preds is None:
            preds = self.forward(batch["img"], tpe=batch.get("txt_feats", None), vpe=batch.get("visuals", None))
        return self.criterion(preds, batch)


class Ensemble(torch.nn.ModuleList):
    """Ensemble of models.

    This class allows combining multiple YOLO models into an ensemble for improved performance through model averaging
    or other ensemble techniques.

    Methods:
        __init__: Initialize an ensemble of models.
        forward: Generate predictions from all models in the ensemble.

    Examples:
        Create an ensemble of models
        >>> ensemble = Ensemble()
        >>> ensemble.append(model1)
        >>> ensemble.append(model2)
        >>> results = ensemble(image_tensor)
    """

    def __init__(self):
        """Initialize an ensemble of models."""
        super().__init__()

    def forward(self, x, augment=False, profile=False, visualize=False):
        """Run ensemble forward pass and concatenate predictions from all models.

        Args:
            x (torch.Tensor): Input tensor.
            augment (bool): Whether to augment the input.
            profile (bool): Whether to profile the model.
            visualize (bool): Whether to visualize the features.

        Returns:
            (torch.Tensor): Concatenated predictions from all models.
            (None): Always None for ensemble inference.
        """
        y = [module(x, augment, profile, visualize)[0] for module in self]
        # y = torch.stack(y).max(0)[0]  # max ensemble
        # y = torch.stack(y).mean(0)  # mean ensemble
        y = torch.cat(y, 2)  # nms ensemble, y shape(B, HW, C*num_models)
        return y, None  # inference, train output


# Functions ------------------------------------------------------------------------------------------------------------


@contextlib.contextmanager
def temporary_modules(modules=None, attributes=None):
    """Context manager for temporarily adding or modifying modules in Python's module cache (`sys.modules`).

    This function can be used to change the module paths during runtime. It's useful when refactoring code, where you've
    moved a module from one location to another, but you still want to support the old import paths for backwards
    compatibility.

    Args:
        modules (dict, optional): A dictionary mapping old module paths to new module paths.
        attributes (dict, optional): A dictionary mapping old module attributes to new module attributes.

    Examples:
        >>> with temporary_modules({"old.module": "new.module"}, {"old.module.attribute": "new.module.attribute"}):
        >>> import old.module  # this will now import new.module
        >>> from old.module import attribute  # this will now import new.module.attribute

    Notes:
        The changes are only in effect inside the context manager and are undone once the context manager exits.
        Be aware that directly manipulating `sys.modules` can lead to unpredictable results, especially in larger
        applications or libraries. Use this function with caution.
    """
    if modules is None:
        modules = {}
    if attributes is None:
        attributes = {}
    import sys
    from importlib import import_module

    try:
        # Set attributes in sys.modules under their old name
        for old, new in attributes.items():
            old_module, old_attr = old.rsplit(".", 1)
            new_module, new_attr = new.rsplit(".", 1)
            setattr(import_module(old_module), old_attr, getattr(import_module(new_module), new_attr))

        # Set modules in sys.modules under their old name
        for old, new in modules.items():
            sys.modules[old] = import_module(new)

        yield
    finally:
        # Remove the temporary module paths
        for old in modules:
            if old in sys.modules:
                del sys.modules[old]


class SafeClass:
    """A placeholder class to replace unknown classes during unpickling."""

    def __init__(self, *args, **kwargs):
        """Initialize SafeClass instance, ignoring all arguments."""
        pass

    def __call__(self, *args, **kwargs):
        """Run SafeClass instance, ignoring all arguments."""
        pass


class SafeUnpickler(pickle.Unpickler):
    """Custom Unpickler that replaces unknown classes with SafeClass."""

    def find_class(self, module, name):
        """Attempt to find a class, returning SafeClass if not among safe modules.

        Args:
            module (str): Module name.
            name (str): Class name.

        Returns:
            (type): Found class or SafeClass.
        """
        safe_modules = (
            "torch",
            "collections",
            "collections.abc",
            "builtins",
            "math",
            "numpy",
            # Add other modules considered safe
        )
        if module in safe_modules:
            return super().find_class(module, name)
        else:
            return SafeClass


def torch_safe_load(weight, safe_only=False):
    """Attempt to load a PyTorch model with the torch.load() function. If a ModuleNotFoundError is raised, it catches
    the error, logs a warning message, and attempts to install the missing module via the check_requirements()
    function. After installation, the function again attempts to load the model using torch.load().

    Args:
        weight (str | Path): The file path of the PyTorch model.
        safe_only (bool): If True, replace unknown classes with SafeClass during loading.

    Returns:
        (dict): The loaded model checkpoint.
        (str): The loaded filename.

    Examples:
        >>> from ultralytics.nn.tasks import torch_safe_load
        >>> ckpt, file = torch_safe_load("path/to/best.pt", safe_only=True)
    """
    from ultralytics.utils.downloads import attempt_download_asset

    check_suffix(file=weight, suffix=".pt")
    file = attempt_download_asset(weight)  # search online if missing locally
    try:
        with temporary_modules(
            modules={
                "ultralytics.yolo.utils": "ultralytics.utils",
                "ultralytics.yolo.v8": "ultralytics.models.yolo",
                "ultralytics.yolo.data": "ultralytics.data",
            },
            attributes={
                "ultralytics.nn.modules.block.Silence": "torch.nn.Identity",  # YOLOv9e
                "ultralytics.nn.tasks.YOLOv10DetectionModel": "ultralytics.nn.tasks.DetectionModel",  # YOLOv10
                "ultralytics.utils.loss.v10DetectLoss": "ultralytics.utils.loss.E2EDetectLoss",  # YOLOv10
                # resolve cross-platform pathlib pickle incompatibility
                **(
                    {"pathlib.PosixPath": "pathlib.WindowsPath"}
                    if WINDOWS
                    else {"pathlib.WindowsPath": "pathlib.PosixPath"}
                ),
            },
        ):
            if safe_only:
                # Load via custom pickle module
                safe_pickle = types.ModuleType("safe_pickle")
                safe_pickle.Unpickler = SafeUnpickler
                safe_pickle.load = lambda file_obj: SafeUnpickler(file_obj).load()
                with open(file, "rb") as f:
                    ckpt = torch_load(f, pickle_module=safe_pickle)
            else:
                ckpt = torch_load(file, map_location="cpu")

    except ModuleNotFoundError as e:  # e.name is missing module name
        if e.name == "models":
            raise TypeError(
                emojis(
                    f"ERROR ❌️ {weight} appears to be an Ultralytics YOLOv5 model originally trained "
                    f"with https://github.com/ultralytics/yolov5.\nThis model is NOT forwards compatible with "
                    f"YOLOv8 at https://github.com/ultralytics/ultralytics."
                    f"\nRecommend fixes are to train a new model using the latest 'ultralytics' package or to "
                    f"run a command with an official Ultralytics model, i.e. 'yolo predict model=yolo26n.pt'"
                )
            ) from e
        elif e.name == "numpy._core":
            raise ModuleNotFoundError(
                emojis(
                    f"ERROR ❌️ {weight} requires numpy>=1.26.1, however numpy=={__import__('numpy').__version__} is installed."
                )
            ) from e
        LOGGER.warning(
            f"{weight} appears to require '{e.name}', which is not in Ultralytics requirements."
            f"\nAutoInstall will run now for '{e.name}' but this feature will be removed in the future."
            f"\nRecommend fixes are to train a new model using the latest 'ultralytics' package or to "
            f"run a command with an official Ultralytics model, i.e. 'yolo predict model=yolo26n.pt'"
        )
        check_requirements(e.name)  # install missing module
        ckpt = torch_load(file, map_location="cpu")

    if not isinstance(ckpt, dict):
        # File is likely a YOLO instance saved with i.e. torch.save(model, "saved_model.pt")
        LOGGER.warning(
            f"The file '{weight}' appears to be improperly saved or formatted. "
            f"For optimal results, use model.save('filename.pt') to correctly save YOLO models."
        )
        ckpt = {"model": ckpt.model}

    return ckpt, file


def load_checkpoint(weight, device=None, inplace=True, fuse=False):
    """Load single model weights.

    Args:
        weight (str | Path): Model weight path.
        device (torch.device, optional): Device to load model to.
        inplace (bool): Whether to do inplace operations.
        fuse (bool): Whether to fuse model.

    Returns:
        (torch.nn.Module): Loaded model.
        (dict): Model checkpoint dictionary.
    """
    ckpt, weight = torch_safe_load(weight)  # load ckpt
    args = {**DEFAULT_CFG_DICT, **(ckpt.get("train_args", {}))}  # combine model and default args, preferring model args
    model = (ckpt.get("ema") or ckpt["model"]).float()  # FP32 model

    # Model compatibility updates
    model.args = args  # attach args to model
    model.pt_path = str(weight)  # attach *.pt file path to model as string (avoids WindowsPath pickle issues)
    model.task = getattr(model, "task", guess_model_task(model))
    if not hasattr(model, "stride"):
        model.stride = torch.tensor([32.0])

    model = (model.fuse() if fuse and hasattr(model, "fuse") else model).eval().to(device)  # model in eval mode

    # Module updates
    for m in model.modules():
        if hasattr(m, "inplace"):
            m.inplace = inplace
        elif isinstance(m, torch.nn.Upsample) and not hasattr(m, "recompute_scale_factor"):
            m.recompute_scale_factor = None  # torch 1.11.0 compatibility

    # Return model and ckpt
    return model, ckpt


def parse_model(d, ch, verbose=True):
    """Parse a YOLO model.yaml dictionary into a PyTorch model.

    Args:
        d (dict): Model dictionary.
        ch (int): Input channels.
        verbose (bool): Whether to print model details.

    Returns:
        (torch.nn.Sequential): PyTorch model.
        (list): Sorted list of layer indices whose outputs need to be saved.
    """
    import ast

    # Args
    legacy = True  # backward compatibility for v3/v5/v8/v9 models
    max_channels = float("inf")
    nc, act, scales, end2end = (d.get(x) for x in ("nc", "activation", "scales", "end2end"))
    reg_max = d.get("reg_max", 16)
    depth, width, kpt_shape = (d.get(x, 1.0) for x in ("depth_multiple", "width_multiple", "kpt_shape"))
    scale = d.get("scale")
    if scales:
        if not scale:
            scale = next(iter(scales.keys()))
            LOGGER.warning(f"no model scale passed. Assuming scale='{scale}'.")
        depth, width, max_channels = scales[scale]

    if act:
        Conv.default_act = eval(act)  # redefine default activation, i.e. Conv.default_act = torch.nn.SiLU()
        if verbose:
            LOGGER.info(f"{colorstr('activation:')} {act}")  # print

    if verbose:
        LOGGER.info(f"\n{'':>3}{'from':>20}{'n':>3}{'params':>10}  {'module':<45}{'arguments':<30}")
    ch = [ch]
    layers, save, c2 = [], [], ch[-1]  # layers, savelist, ch out
    base_modules = frozenset(
        {
            Classify,
            Conv,
            ConvTranspose,
            GhostConv,
            Bottleneck,
            GhostBottleneck,
            SPP,
            SPPF,
            C2fPSA,
            C2PSA,
            DWConv,
            Focus,
            BottleneckCSP,
            C1,
            C2,
            C2f,
            C3k2,
            RepNCSPELAN4,
            ELAN1,
            ADown,
            AConv,
            SPPELAN,
            C2fAttn,
            C3,
            C3TR,
            C3Ghost,
            torch.nn.ConvTranspose2d,
            DWConvTranspose2d,
            C3x,
            RepC3,
            PSA,
            SCDown,
            C2fCIB,
            A2C2f,
            SEBlock,  # for YOLOv8n+SE paper reproduction
        }
    )
    repeat_modules = frozenset(  # modules with 'repeat' arguments
        {
            BottleneckCSP,
            C1,
            C2,
            C2f,
            C3k2,
            C2fAttn,
            C3,
            C3TR,
            C3Ghost,
            C3x,
            RepC3,
            C2fPSA,
            C2fCIB,
            C2PSA,
            A2C2f,
        }
    )
    for i, (f, n, m, args) in enumerate(d["backbone"] + d["head"]):  # from, number, module, args
        m = (
            getattr(torch.nn, m[3:])
            if "nn." in m
            else getattr(__import__("torchvision").ops, m[16:])
            if "torchvision.ops." in m
            else globals()[m]
        )  # get module
        for j, a in enumerate(args):
            if isinstance(a, str):
                with contextlib.suppress(ValueError):
                    args[j] = locals()[a] if a in locals() else ast.literal_eval(a)
        n = n_ = max(round(n * depth), 1) if n > 1 else n  # depth gain
        if m in base_modules:
            c1, c2 = ch[f], args[0]
            if c2 != nc:  # if c2 != nc (e.g., Classify() output)
                c2 = make_divisible(min(c2, max_channels) * width, 8)
            if m is C2fAttn:  # set 1) embed channels and 2) num heads
                args[1] = make_divisible(min(args[1], max_channels // 2) * width, 8)
                args[2] = int(max(round(min(args[2], max_channels // 2 // 32)) * width, 1) if args[2] > 1 else args[2])

            args = [c1, c2, *args[1:]]
            if m in repeat_modules:
                args.insert(2, n)  # number of repeats
                n = 1
            if m is C3k2:  # for M/L/X sizes
                legacy = False
                if scale in "mlx":
                    args[3] = True
            if m is A2C2f:
                legacy = False
                if scale in "lx":  # for L/X sizes
                    args.extend((True, 1.2))
            if m is C2fCIB:
                legacy = False
        elif m is AIFI:
            args = [ch[f], *args]
        elif m in frozenset({HGStem, HGBlock}):
            c1, cm, c2 = ch[f], args[0], args[1]
            args = [c1, cm, c2, *args[2:]]
            if m is HGBlock:
                args.insert(4, n)  # number of repeats
                n = 1
        elif m is ResNetLayer:
            c2 = args[1] if args[3] else args[1] * 4
        elif m is torch.nn.BatchNorm2d:
            args = [ch[f]]
        elif m is Concat:
            c2 = sum(ch[x] for x in f)
        elif m in frozenset(
            {
                Detect,
                WorldDetect,
                YOLOEDetect,
                Segment,
                Segment26,
                YOLOESegment,
                YOLOESegment26,
                Pose,
                Pose26,
                OBB,
                OBB26,
            }
        ):
            args.extend([reg_max, end2end, [ch[x] for x in f]])
            if m is Segment or m is YOLOESegment or m is Segment26 or m is YOLOESegment26:
                args[2] = make_divisible(min(args[2], max_channels) * width, 8)
            if m in {Detect, YOLOEDetect, Segment, Segment26, YOLOESegment, YOLOESegment26, Pose, Pose26, OBB, OBB26}:
                m.legacy = legacy
        elif m is v10Detect:
            args.append([ch[x] for x in f])
        elif m is ImagePoolingAttn:
            args.insert(1, [ch[x] for x in f])  # channels as second arg
        elif m is RTDETRDecoder:  # special case, channels arg must be passed in index 1
            args.insert(1, [ch[x] for x in f])
        elif m is CBLinear:
            c2 = args[0]
            c1 = ch[f]
            args = [c1, c2, *args[1:]]
        elif m is CBFuse:
            c2 = ch[f[-1]]
        elif m in frozenset({TorchVision, Index}):
            c2 = args[0]
            c1 = ch[f]
            args = [*args[1:]]
        else:
            c2 = ch[f]

        m_ = torch.nn.Sequential(*(m(*args) for _ in range(n))) if n > 1 else m(*args)  # module
        t = str(m)[8:-2].replace("__main__.", "")  # module type
        m_.np = sum(x.numel() for x in m_.parameters())  # number params
        m_.i, m_.f, m_.type = i, f, t  # attach index, 'from' index, type
        if verbose:
            LOGGER.info(f"{i:>3}{f!s:>20}{n_:>3}{m_.np:10.0f}  {t:<45}{args!s:<30}")  # print
        save.extend(x % i for x in ([f] if isinstance(f, int) else f) if x != -1)  # append to savelist
        layers.append(m_)
        if i == 0:
            ch = []
        ch.append(c2)
    return torch.nn.Sequential(*layers), sorted(save)


def yaml_model_load(path):
    """Load a YOLO model from a YAML file.

    Args:
        path (str | Path): Path to the YAML file.

    Returns:
        (dict): Model dictionary.
    """
    path = Path(path)
    if path.stem in (f"yolov{d}{x}6" for x in "nsmlx" for d in (5, 8)):
        new_stem = re.sub(r"(\d+)([nslmx])6(.+)?$", r"\1\2-p6\3", path.stem)
        LOGGER.warning(f"Ultralytics YOLO P6 models now use -p6 suffix. Renaming {path.stem} to {new_stem}.")
        path = path.with_name(new_stem + path.suffix)

    unified_path = re.sub(r"(\d+)([nslmx])(.+)?$", r"\1\3", str(path))  # i.e. yolov8x.yaml -> yolov8.yaml
    yaml_file = check_yaml(unified_path, hard=False) or check_yaml(path)
    d = YAML.load(yaml_file)  # model dict
    d["scale"] = guess_model_scale(path)
    d["yaml_file"] = str(path)
    return d


def guess_model_scale(model_path):
    """Extract the size character n, s, m, l, or x of the model's scale from the model path.

    Args:
        model_path (str | Path): The path to the YOLO model's YAML file.

    Returns:
        (str): The size character of the model's scale (n, s, m, l, or x), or empty string if not found.
    """
    try:
        return re.search(r"yolo(e-)?[v]?\d+([nslmx])", Path(model_path).stem).group(2)
    except AttributeError:
        return ""


def guess_model_task(model):
    """Guess the task of a PyTorch model from its architecture or configuration.

    Args:
        model (torch.nn.Module | dict | str | Path): PyTorch model, model configuration dict, or model file path.

    Returns:
        (str): Task of the model ('detect', 'segment', 'classify', 'pose', 'obb').
    """

    def cfg2task(cfg):
        """Guess from YAML dictionary."""
        m = cfg["head"][-1][-2].lower()  # output module name
        if m in {"classify", "classifier", "cls", "fc"}:
            return "classify"
        if "detect" in m:
            return "detect"
        if "segment" in m:
            return "segment"
        if "pose" in m:
            return "pose"
        if "obb" in m:
            return "obb"

    # Guess from model cfg
    if isinstance(model, dict):
        with contextlib.suppress(Exception):
            return cfg2task(model)
    # Guess from PyTorch model
    if isinstance(model, torch.nn.Module):  # PyTorch model
        for x in "model.args", "model.model.args", "model.model.model.args":
            with contextlib.suppress(Exception):
                return eval(x)["task"]  # nosec B307: safe eval of known attribute paths
        for x in "model.yaml", "model.model.yaml", "model.model.model.yaml":
            with contextlib.suppress(Exception):
                return cfg2task(eval(x))  # nosec B307: safe eval of known attribute paths
        for m in model.modules():
            if isinstance(m, (Segment, YOLOESegment)):
                return "segment"
            elif isinstance(m, Classify):
                return "classify"
            elif isinstance(m, Pose):
                return "pose"
            elif isinstance(m, OBB):
                return "obb"
            elif isinstance(m, (Detect, WorldDetect, YOLOEDetect, v10Detect)):
                return "detect"

    # Guess from model filename
    if isinstance(model, (str, Path)):
        model = Path(model)
        if "-seg" in model.stem or "segment" in model.parts:
            return "segment"
        elif "-cls" in model.stem or "classify" in model.parts:
            return "classify"
        elif "-pose" in model.stem or "pose" in model.parts:
            return "pose"
        elif "-obb" in model.stem or "obb" in model.parts:
            return "obb"
        elif "detect" in model.parts:
            return "detect"

    # Unable to determine task from model
    LOGGER.warning(
        "Unable to automatically guess model task, assuming 'task=detect'. "
        "Explicitly define task for your model, i.e. 'task=detect', 'segment', 'classify','pose' or 'obb'."
    )
    return "detect"  # assume detect

```

`ultralytics/cfg/models/v8/yolov8n_se.yaml`

```text
# Ultralytics AGPL-3.0 License - https://ultralytics.com/license

# YOLOv8n + SE object detection model for paper reproduction with P3/8 - P5/32 outputs

# Parameters
nc: 80 # number of classes
scales: # model compound scaling constants, i.e. 'model=yolov8n_se.yaml' will call this file with scale 'n'
  # [depth, width, max_channels]
  n: [0.33, 0.25, 1024]

# YOLOv8n backbone with SE blocks
backbone:
  # [from, repeats, module, args]
  - [-1, 1, Conv, [64, 3, 2]] # 0-P1/2
  - [-1, 1, Conv, [128, 3, 2]] # 1-P2/4
  - [-1, 3, C2f, [128, True]]
  - [-1, 1, Conv, [256, 3, 2]] # 3-P3/8
  - [-1, 6, C2f, [256, True]]
  - [-1, 1, Conv, [512, 3, 2]] # 5-P4/16
  - [-1, 6, C2f, [512, True]]
  - [-1, 1, SEBlock, [512]]
  - [-1, 1, Conv, [1024, 3, 2]] # 8-P5/32
  - [-1, 3, C2f, [1024, True]]
  - [-1, 1, SEBlock, [1024]]
  - [-1, 1, SPPF, [1024, 5]] # 11

# YOLOv8n head with SE blocks on PAN-FPN fusion C2f modules
head:
  - [-1, 1, nn.Upsample, [None, 2, "nearest"]]
  - [[-1, 7], 1, Concat, [1]] # cat backbone P4
  - [-1, 3, C2f, [512]] # 14
  - [-1, 1, SEBlock, [512]]

  - [-1, 1, nn.Upsample, [None, 2, "nearest"]]
  - [[-1, 4], 1, Concat, [1]] # cat backbone P3
  - [-1, 3, C2f, [256]] # 18 (P3/8-small)
  - [-1, 1, SEBlock, [256]]

  - [-1, 1, Conv, [256, 3, 2]]
  - [[-1, 14], 1, Concat, [1]] # cat head P4
  - [-1, 3, C2f, [512]] # 22 (P4/16-medium)
  - [-1, 1, SEBlock, [512]]

  - [-1, 1, Conv, [512, 3, 2]]
  - [[-1, 11], 1, Concat, [1]] # cat head P5
  - [-1, 3, C2f, [1024]] # 26 (P5/32-large)
  - [-1, 1, SEBlock, [1024]]

  - [[18, 22, 26], 1, Detect, [nc]] # Detect(P3, P4, P5)

```
