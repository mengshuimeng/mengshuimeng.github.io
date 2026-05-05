---
title: 论文写作备忘
description: LaTeX、论文排版和写作格式的轻量备忘
---

## 页面用途

这里记录论文写作、LaTeX 排版和材料整理中容易忘记的小技巧，作为写作时的快速备忘。

## 跨双栏图片

在双栏论文模板中，如果图片需要横跨两栏，可以使用 `figure*`：

```latex
\begin{figure*}[!t]
\centering
\includegraphics[width=0.9\textwidth]{system_architecture.png}
\caption{系统总体架构图}
\label{fig:system_architecture}
\end{figure*}
```

说明：

- `figure*` 表示跨双栏浮动体。
- `[!t]` 表示优先放在页面顶部。
- `width=0.9\textwidth` 表示图片宽度占整页正文宽度的 90%。

## 后续补充方向

- 常用 LaTeX 表格模板。
- 公式、图片、表格的引用规范。
- 论文标题、摘要、方法和实验部分的写作检查清单。
