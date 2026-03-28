---
title: Ubuntu On WSL
description: A concise guide to running Ubuntu on WSL and using it as a practical development environment on Windows.
slug: ubuntu-on-wsl
---

# Ubuntu On WSL

WSL is a practical bridge between Windows and a Linux development workflow. It is especially useful when you want Linux tools, shell commands, package managers, or ROS and Python tooling without leaving your Windows laptop.

## What WSL Is Good For

- Linux command-line development on Windows
- Python and package management
- Git, SSH, and remote workflows
- Robotics, ROS-related tools, and server-like development habits

## A Stable Setup Path

1. Install WSL and Ubuntu.
2. Update the Ubuntu system packages.
3. Install the tools you need, such as Git, Python, or build tools.
4. Use a project-specific environment manager like Conda or `venv`.
5. Connect from VS Code or use SSH-based workflows when needed.

## Useful Commands

```bash
wsl --install
wsl -l -v
sudo apt update && sudo apt upgrade -y
```

## Practical Advice

- Keep Windows paths and Linux paths clearly separated in your mind.
- Use WSL for development logic and Windows for files or apps only when needed.
- Verify USB, camera, or GPU passthrough early if your project depends on hardware.
- Prefer reproducible setup notes over one-off terminal history.
