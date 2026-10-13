---
title: "What Is Broadcasting"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "PyTorch"
  - "张量"
---

Broadcasting is the rule that allows tensors with different shapes to participate in the same operation without manually copying data.

## The Core Idea

When one dimension is `1` and the other side has a larger compatible size, the smaller side is expanded logically during computation.

For example:

```text
(N, 1) - (N, M) -> (N, M)
```

The `(N, 1)` tensor behaves as if its second dimension were repeated across `M` columns.

## Why It Is Useful

- It makes tensor code shorter.
- It avoids unnecessary manual reshaping.
- It keeps math expressions close to the actual idea.

## One Important Rule

Shapes are compared from the last dimension backward. Two dimensions are compatible if:

- they are equal, or
- one of them is `1`

Otherwise, the operation fails.
