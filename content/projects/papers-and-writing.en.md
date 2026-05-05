---
title: Papers and Writing Notes
description: Lightweight notes for LaTeX, paper formatting, and academic writing
---

## Purpose

This page keeps small but useful notes for paper writing, LaTeX formatting, and manuscript preparation.

## Two-column Wide Figures

In a two-column paper template, use `figure*` when a figure needs to span both columns:

```latex
\begin{figure*}[!t]
\centering
\includegraphics[width=0.9\textwidth]{system_architecture.png}
\caption{System architecture.}
\label{fig:system_architecture}
\end{figure*}
```

Notes:

- `figure*` creates a two-column floating figure.
- `[!t]` asks LaTeX to place the figure near the top of a page.
- `width=0.9\textwidth` sets the figure width to 90% of the full text width.

## Future Additions

- Common LaTeX table templates.
- Figure, table, and equation reference conventions.
- Writing checklists for titles, abstracts, methods, and experiments.
