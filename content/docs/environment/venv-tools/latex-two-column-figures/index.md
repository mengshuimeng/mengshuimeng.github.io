---
title: "LaTeX 跨双栏图片排版"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "LaTeX"
  - "论文排版"
---

直接这样写：

```text
\begin{figure*}[!t]
\centering
\includegraphics[width=0.9\textwidth]{system_architecture.png}
\caption{系统总体架构图}
\label{fig:system_architecture}
\end{figure*}
```

---

## 这段的作用

- `figure*`：让图片跨双栏
- `[!t]`：优先放在页顶
- `width=0.9\textwidth`：图片宽度占整页正文宽度的 90%
