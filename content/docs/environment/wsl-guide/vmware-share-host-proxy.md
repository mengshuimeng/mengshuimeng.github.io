# VMware 虚拟机复用 Windows 宿主机代理教程

> 本文档用于说明如何让 **VMware 中的 Ubuntu 虚拟机** 复用 **Windows 宿主机上的代理软件**，从而访问 GitHub 等默认无法直接访问的网站。  
>
> 适用场景：  
> - Windows 宿主机已经可以正常使用代理  
> - VMware 虚拟机中的 Ubuntu 不能访问外网或访问 GitHub 很慢  
> - 希望虚拟机直接复用宿主机代理，而不是在虚拟机里单独再装一套代理工具  
>
> 作者：姜树豪（JSH）  
> 更新时间：2026-03-09

---

## 参考链接

[网络地址转换（NAT）](https://zh.wikipedia.org/wiki/网络地址转换)

[Clash for Windows 手动安装 Service Mode - ArnoのSite](https://blog.arnozeng.com/archives/service-mode-setup-manually.html#:~:text=输入 service.exe install 和 service.exe start,以安装Service并启动。 重启Clash for Windows，检查Service Mode旁的小地球图标，变绿表示Service Mode已经安装成功。 Issue当我们希望Clash接管我们电脑的全局流量，而不是只作为浏览器的代理时，我们则需用到Clash中的TUN模式。)

## 目录

1. 问题背景
2. 核心思路
3. 前提条件
4. 检查 VMware 的 NAT 虚拟网络
5. 将虚拟机连接到 NAT 网络
6. 获取宿主机在 VMnet8 上的地址
7. 配置宿主机代理软件
8. 在 Ubuntu 中配置代理
9. 验证代理是否生效
10. 常见问题与注意事项

---

## 1. 问题背景

一个很常见的情况是：

- **Windows 宿主机**可以正常访问 GitHub 等网站
- **VMware 虚拟机里的 Ubuntu** 却不能访问，或者速度很慢

这通常不是因为虚拟机“坏了”，而是因为：

- 宿主机的代理只监听在本机
- 虚拟机没有接入正确的虚拟网络
- Ubuntu 里没有配置代理地址和端口

在这种情况下，最省事的做法往往不是在虚拟机里再装一套代理，而是让虚拟机直接复用宿主机已经能用的代理。

---

## 2. 核心思路

VMware Workstation 提供了虚拟网络功能，其中 **NAT 网络默认连接到 VMnet8**。你可以把这个 NAT 网络粗略理解成一个“虚拟路由器”：宿主机和虚拟机如果都连在它下面，就可以互相通信。VMware 官方文档明确写到：默认情况下，NAT 设备连接到 **VMnet8**，并且一个 VMware 只能有一个 NAT 虚拟网络。:contentReference[oaicite:2]{index=2}

因此，整个思路就是：

1. 让虚拟机接入 VMware 的 NAT 网络（通常是 `VMnet8`）
2. 找到宿主机在 `VMnet8` 上的 IP 地址
3. 在宿主机的代理软件中开启“允许局域网连接”
4. 在 Ubuntu 中把代理地址设置为：  
   **宿主机 VMnet8 IP + 代理端口**

一句话概括就是：

> **虚拟机通过 VMnet8 去访问宿主机代理。**

---

## 3. 前提条件

在开始之前，建议先确认以下几点：

- 宿主机上的代理软件已经能正常工作
- 代理软件支持 **HTTP** 或 **SOCKS5**
- 代理软件已经开启 **允许局域网连接**
- VMware 虚拟机使用的是 **NAT** 网络，或自定义连接到 `VMnet8`
- Ubuntu 虚拟机能正常联网

> 注意：  
> 如果代理软件只监听 `127.0.0.1`，但没有开启局域网连接，那么虚拟机通常无法直接使用它。

---

## 4. 检查 VMware 的 NAT 虚拟网络

### 4.1 打开虚拟网络编辑器

在 VMware 中打开 **虚拟网络编辑器（Virtual Network Editor）**，点击“更改设置”以查看完整内容。

### 4.2 确认 NAT 网络存在

通常你会看到一个 **NAT 类型的虚拟网络**，默认名称是：

```text
VMnet8
```

VMware 官方文档说明，默认 NAT 网络就是连接到 **VMnet8**。([techdocs.broadcom.com](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/workstation-pro/17-0/using-vmware-workstation-pro/configuring-network-connections/configuring-network-address-translation-1/change-nat-settings.html?utm_source=chatgpt.com))

### 4.3 这一步的作用

这一步一般主要是**确认**：

- NAT 网络是否存在
- NAT 网络名字是不是 `VMnet8`

通常不需要改太多设置，只要确认 VMware 已经创建了 NAT 虚拟网络即可。

------

## 5. 将虚拟机连接到 NAT 网络

### 5.1 打开虚拟机设置

在 VMware 中选中目标虚拟机，进入：

- 顶栏 **虚拟机**
- 或者右键虚拟机 → **设置**

找到：

```text
网络适配器（Network Adapter）
```

### 5.2 选择网络连接方式

这里推荐两种清晰写法：

- 直接选 **NAT**
- 或者选 **自定义（Custom）** 并明确指定到 `VMnet8`

为了避免歧义，更推荐第二种：

```text
自定义：指定特定虚拟网络 → VMnet8
```

这样逻辑最清楚：
你明确知道虚拟机接入的是哪个虚拟网络。

------

## 6. 获取宿主机在 VMnet8 上的地址

虚拟机接入 `VMnet8` 后，下一步要知道：

> **宿主机在这个虚拟网络中的 IP 地址是多少**

### 常见查看方法

在 Windows 中，可以通过以下方式查看 VMware 的虚拟网卡地址：

- 任务管理器
- 控制面板 → 网络连接
- 命令行执行 `ipconfig`

更推荐直接在 PowerShell 或 CMD 中执行：

```bat
ipconfig
```

然后找到类似：

```text
VMware Network Adapter VMnet8
```

对应的 IPv4 地址，例如：

```text
192.168.x.x
```

这个地址就是：

> **宿主机在 VMnet8 虚拟网络里的地址**

后面 Ubuntu 里的代理地址就要填这个 IP，而不是 `127.0.0.1`。

------

## 7. 配置宿主机代理软件

以 Clash 类代理软件为例，通常需要确认以下几点：

### 7.1 开启允许局域网连接

必须开启：

```text
允许来自局域网的连接
```

否则来自虚拟机的连接请求可能会被宿主机代理直接拒绝。

### 7.2 记录代理端口

通常代理软件会显示：

- HTTP 代理端口
- SOCKS5 代理端口

例如：

- HTTP：`7890`
- SOCKS5：`7891`

你真正需要记录的是：

- **协议类型**
- **端口号**

而不是前面的：

```text
127.0.0.1
```

因为：

- `127.0.0.1` 在宿主机中指向宿主机自己
- `127.0.0.1` 在虚拟机中则指向虚拟机自己

所以虚拟机里不能把宿主机代理地址写成 `127.0.0.1`。

------

## 8. 在 Ubuntu 中配置代理

### 8.1 图形界面设置方法

在 Ubuntu 中打开：

```text
设置 → 网络 → 网络代理
```

将代理模式改成：

```text
手动
```

然后填入前面记录的内容：

- 代理主机：**宿主机在 VMnet8 上的 IP**
- 代理端口：**宿主机代理软件对应端口**

例如：

- HTTP 代理：`192.168.x.x:7890`
- SOCKS 代理：`192.168.x.x:7891`

这样 Ubuntu 中很多遵守系统代理设置的软件就能使用代理。

### 8.2 本质上是什么

Ubuntu 中这类代理设置，本质上通常会让系统或会话环境使用类似下面的代理变量：

- `http_proxy`
- `https_proxy`
- `all_proxy`

Git 官方文档明确提到，Git 支持标准的 `http_proxy`、`https_proxy`、`no_proxy` 环境变量，也支持通过 `git config http.proxy` 单独设置。([Git](https://git-scm.com/docs/git-config?utm_source=chatgpt.com))

因此你要知道：

> 这类系统代理设置对很多命令行工具有效，但不是对所有程序都自动生效。

------

## 9. 验证代理是否生效

配置完成后，建议分层验证，而不是一上来就直接说“能不能翻 GitHub”。

### 9.1 先测试基本网络连通

在 Ubuntu 中先测试能否访问宿主机代理地址，例如使用浏览器或网络工具测试。

### 9.2 测试命令行工具

例如可以尝试：

```bash
curl https://github.com
```

或者：

```bash
wget https://github.com
```

如果这些工具能成功访问，说明系统代理大概率已经生效。

### 9.3 测试 Git

如果你使用的是 Git 的 HTTP / HTTPS 模式，Git 一般可以继承标准代理环境变量；Git 官方文档明确说明，Git 支持代理环境变量以及 `http.proxy` 配置项。([Git](https://git-scm.com/docs/git-config?utm_source=chatgpt.com))

如果仍然不生效，可以额外手动配置：

```bash
git config --global http.proxy http://宿主机IP:端口
git config --global https.proxy http://宿主机IP:端口
```

------

## 10. 常见问题与注意事项

### 10.1 为什么不能直接写 `127.0.0.1:端口`？

因为 `127.0.0.1` 永远指向“当前这台机器自己”。

也就是说：

- 在 Windows 宿主机里，`127.0.0.1` 指向宿主机
- 在 Ubuntu 虚拟机里，`127.0.0.1` 指向虚拟机

所以虚拟机里写 `127.0.0.1`，不会访问到宿主机代理。

------

### 10.2 NAT 模式和 VMnet8 是什么关系？

VMware 官方文档说明，默认情况下 NAT 设备连接到 **VMnet8**。([techdocs.broadcom.com](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/workstation-pro/17-0/using-vmware-workstation-pro/configuring-network-connections/configuring-network-address-translation-1/change-nat-settings.html?utm_source=chatgpt.com))

所以通常可以这样理解：

- **NAT**：网络工作模式
- **VMnet8**：这个 NAT 网络对应的虚拟交换网络名称

------

### 10.3 Ubuntu 设置里的代理为什么有时不生效？

因为不是所有程序都会自动读取系统代理。

例如：

- 很多命令行工具会读取 `http_proxy` / `https_proxy`
- Git 既支持环境变量，也支持单独配置
- 某些程序可能完全不理系统代理，需要自己单独设置。([Git](https://git-scm.com/docs/git-config?utm_source=chatgpt.com))

------

### 10.4 为什么推荐“共享宿主机梯子”而不是在虚拟机里再装一套？

因为这种方式通常更省事：

- 不需要在虚拟机里重复登录代理软件
- 不需要维护两套代理配置
- 只要宿主机代理正常，虚拟机也能一起复用

但它的前提是：

- 宿主机代理允许局域网访问
- 宿主机和虚拟机确实能通过 `VMnet8` 通信

------

### 10.5 “NAT 默认也是指向 VMnet8” 这句话对吗？

对，但写文档时最好不要只写“默认也是”，而要直接说明：

> VMware 的 NAT 虚拟网络默认连接到 `VMnet8`。([techdocs.broadcom.com](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/workstation-pro/17-0/using-vmware-workstation-pro/configuring-network-connections/configuring-network-address-translation-1/change-nat-settings.html?utm_source=chatgpt.com))

这样更准确，也更不容易让读者误会。

------

## 总结

这篇教程的核心逻辑其实只有四步：

1. 确认 VMware 的 NAT 网络是 `VMnet8`
2. 让 Ubuntu 虚拟机接入 `VMnet8`
3. 找到宿主机在 `VMnet8` 上的 IP 地址
4. 在 Ubuntu 中把代理地址填成：
   **宿主机 VMnet8 IP + 代理端口**

记住一句话就够了：

> **虚拟机不能用宿主机的 `127.0.0.1`，只能用宿主机在 VMnet8 上的真实地址。**