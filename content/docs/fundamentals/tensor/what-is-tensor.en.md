---
title: What Is Tensor
description: A short beginner-oriented explanation of tensors and why they matter in PyTorch and machine learning workflows.
slug: what-is-tensor
---

# What Is Tensor

A tensor is a data container used in frameworks such as PyTorch. You can think of it as a generalized form of numbers, vectors, and matrices:

- A single number is a 0D tensor.
- A list of numbers is a 1D tensor.
- A table of numbers is a 2D tensor.
- Higher-dimensional arrays are also tensors.

## Why Tensors Matter

Tensors are the standard way to represent model inputs, outputs, parameters, and intermediate computation results in deep learning.

## Where You See Them

- Images stored as width, height, and channel values
- Batches of training data
- Robot observations and actions
- Neural network weights and activations

## A Practical Mental Model

If you already understand arrays in NumPy, a tensor is very similar, but with better support for GPU computation, automatic differentiation, and deep learning pipelines.
