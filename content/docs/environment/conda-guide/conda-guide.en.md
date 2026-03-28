---
title: Conda Quick Start
description: A practical Conda starter guide for creating environments, installing dependencies, and keeping projects isolated.
slug: conda-guide
---

# Conda Quick Start

This note is for beginners who need a stable Python environment quickly. The main idea is simple: create one environment per project, install only what the project needs, and verify the setup before doing real work.

## Why Use Conda

- It isolates project dependencies.
- It lets you manage Python versions cleanly.
- It reduces conflicts between different experiments or courses.

## Recommended Workflow

1. Create a new environment.
2. Activate it before installing anything.
3. Install the required packages.
4. Verify the installation with a small import test.
5. Deactivate the environment when you are done.

## Basic Commands

```bash
conda create -n study python=3.10 -y
conda activate study
conda env list
conda deactivate
conda remove --name study --all
```

## Installing Dependencies

If a package is available through Conda, install it there first. If a project explicitly uses `pip`, keep that choice consistent inside the same environment.

```bash
conda install -c conda-forge opencv
python -c "import cv2; print(cv2.__version__)"
```

## Practical Advice

- Keep environments small and focused.
- Do not mix too many unrelated libraries in one environment.
- If downloads are slow, configure a local mirror before installing large packages.
- Always verify GPU or framework availability with a one-line test before training.
