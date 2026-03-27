---
title: 论文写作备忘
---

# 一、跨双栏图片的标准写法

直接这样写：

```
\begin{figure*}[!t]
\centering
\includegraphics[width=0.9\textwidth]{system_architecture.png}
\caption{系统总体架构图}
\label{fig:system_architecture}
\end{figure*}
```

------

## 这段的作用

- `figure*`：让图片跨双栏
- `[!t]`：优先放在页顶
- `width=0.9\textwidth`：图片宽度占整页正文宽度的 90%
