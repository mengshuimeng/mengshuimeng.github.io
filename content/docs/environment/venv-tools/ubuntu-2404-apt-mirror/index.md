---
title: "Ubuntu 24.04 APT 软件源备份与换源"
date: 2026-09-23
authors:
  - "萌睡梦"
tags:
  - "Ubuntu"
  - "软件源"
---

Ubuntu 24.04 用的是 .sources 格式，和老版本不一样。直接这样操作：

一键换源

## 1. 备份

sudo cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak

## 2. 替换为阿里源

sudo sed -i 's/http://ports.ubuntu.com/https://mirrors.aliyun.com/g' /etc/apt/sources.list.d/ubuntu.sources

## 3. 更新并安装

sudo apt update
sudo apt install firefox

恢复原源

sudo cp /etc/apt/sources.list.d/ubuntu.sources.bak /etc/apt/sources.list.d/ubuntu.sources
sudo apt update

就这三步，装完 Firefox 后如果想恢复也可以随时恢复。
