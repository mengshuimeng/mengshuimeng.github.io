---
title: "Ubuntu 软件安装与 APT 排障记录"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "Ubuntu"
  - "APT"
---

```bash
(base) abc@abc-MIX:~$ sudo apt update
[sudo] abc 的密码：
对不起，请重试。
[sudo] abc 的密码：
命中:1 http://mirrors.aliyun.com/ubuntu focal InRelease
获取:2 https://mirrors.aliyun.com/docker-ce/linux/ubuntu focal InRelease [57.7 kB]
命中:3 http://mirrors.tuna.tsinghua.edu.cn/ubuntu focal InRelease
命中:4 http://mirrors.tuna.tsinghua.edu.cn/ubuntu focal-updates InRelease
命中:5 http://mirrors.tuna.tsinghua.edu.cn/ubuntu focal-backports InRelease
命中:6 http://mirrors.tuna.tsinghua.edu.cn/ubuntu focal-security InRelease
命中:7 https://nvidia.github.io/libnvidia-container/stable/deb/amd64  InRelease
命中:8 https://mirrors.ustc.edu.cn/ros/ubuntu focal InRelease
命中:9 https://mirrors.ustc.edu.cn/ros2/ubuntu focal InRelease
已下载 57.7 kB，耗时 6秒 (10.2 kB/s)
正在读取软件包列表... 完成
正在分析软件包的依赖关系树
正在读取状态信息... 完成
有 8 个软件包可以升级。请执行 ‘apt list --upgradable’ 来查看它们。
(base) abc@abc-MIX:~$ sudo apt install lshw -y
正在读取软件包列表... 完成
正在分析软件包的依赖关系树
正在读取状态信息... 完成
lshw 已经是最新版 (02.18.85-0.3ubuntu2.20.04.1)。
lshw 已设置为手动安装。
升级了 0 个软件包，新安装了 0 个软件包，要卸载 0 个软件包，有 8 个软件包未被升级。
(base) abc@abc-MIX:~$ sudo lshw
abc-mix
    description: Desktop Computer
    product: MIX (G1362H026LD)
    vendor: THUNDEROBOT
    version: V4.0
    serial: JT00E000K003SQ8KCXZN
    width: 64 bits
    capabilities: smbios-3.5.0 dmi-3.5.0 smp vsyscall32
    configuration: boot=normal chassis=desktop family=THUNDEROBOT MIX G Series sku=G1362H026LD uuid=36613731-3033-3765-3364-616634383065
  *-core
       description: Motherboard
       product: MIX
       vendor: THUNDEROBOT
       physical id: 0
       version: V4.0
     *-firmware
          description: BIOS
          vendor: AMI
          physical id: 0
          version: 1.06
          date: 06/07/2024
          size: 64KiB
          capacity: 16MiB
          capabilities: pci upgrade shadowing cdboot bootselect socketedrom edd int13floppynec int13floppytoshiba int13floppy360 int13floppy1200 int13floppy720 int13floppy2880 int5printscreen int14serial int17printer int10video acpi usb biosbootspecification uefi
     *-memory
          description: System Memory
          physical id: 24
          slot: System board or motherboard
          size: 16GiB
        *-bank:0
             description: Row of chips Synchronous 6400 MHz (0.2 ns)
             product: K3KL8L80CM-MGCT
             vendor: Samsung
             physical id: 0
             serial: 00000000
             slot: Controller0-ChannelA
             size: 2GiB
             width: 16 bits
             clock: 2105MHz (0.5ns)
        *-bank:1
             description: Row of chips Synchronous 6400 MHz (0.2 ns)
             product: K3KL8L80CM-MGCT
             vendor: Samsung
             physical id: 1
             serial: 00000000
             slot: Controller0-ChannelB
             size: 2GiB
             width: 16 bits
             clock: 2105MHz (0.5ns)
        *-bank:2
             description: Row of chips Synchronous 6400 MHz (0.2 ns)
             product: K3KL8L80CM-MGCT
             vendor: Samsung
             physical id: 2
             serial: 00000000
             slot: Controller0-ChannelC
             size: 2GiB
             width: 16 bits
             clock: 2105MHz (0.5ns)
        *-bank:3
             description: Row of chips Synchronous 6400 MHz (0.2 ns)
             product: K3KL8L80CM-MGCT
             vendor: Samsung
             physical id: 3
             serial: 00000000
             slot: Controller0-ChannelD
             size: 2GiB
             width: 16 bits
             clock: 2105MHz (0.5ns)
        *-bank:4
             description: Row of chips Synchronous 6400 MHz (0.2 ns)
             product: K3KL8L80CM-MGCT
             vendor: Samsung
             physical id: 4
             serial: 00000000
             slot: Controller1-ChannelA
             size: 2GiB
             width: 16 bits
             clock: 2105MHz (0.5ns)
        *-bank:5
             description: Row of chips Synchronous 6400 MHz (0.2 ns)
             product: K3KL8L80CM-MGCT
             vendor: Samsung
             physical id: 5
             serial: 00000000
             slot: Controller1-ChannelB
             size: 2GiB
             width: 16 bits
             clock: 2105MHz (0.5ns)
        *-bank:6
             description: Row of chips Synchronous 6400 MHz (0.2 ns)
             product: K3KL8L80CM-MGCT
             vendor: Samsung
             physical id: 6
             serial: 00000000
             slot: Controller1-ChannelC
             size: 2GiB
             width: 16 bits
             clock: 2105MHz (0.5ns)
        *-bank:7
             description: Row of chips Synchronous 6400 MHz (0.2 ns)
             product: K3KL8L80CM-MGCT
             vendor: Samsung
             physical id: 7
             serial: 00000000
             slot: Controller1-ChannelD
             size: 2GiB
             width: 16 bits
             clock: 2105MHz (0.5ns)
     *-cache:0
          description: L1 cache
          physical id: 3e
          slot: L1 Cache
          size: 288KiB
          capacity: 288KiB
          capabilities: synchronous internal write-back data
          configuration: level=1
     *-cache:1
          description: L1 cache
          physical id: 3f
          slot: L1 Cache
          size: 192KiB
          capacity: 192KiB
          capabilities: synchronous internal write-back instruction
          configuration: level=1
     *-cache:2
          description: L2 cache
          physical id: 40
          slot: L2 Cache
          size: 7680KiB
          capacity: 7680KiB
          capabilities: synchronous internal write-back unified
          configuration: level=2
     *-cache:3
          description: L3 cache
          physical id: 41
          slot: L3 Cache
          size: 24MiB
          capacity: 24MiB
          capabilities: synchronous internal write-back unified
          configuration: level=3
     *-cache:4
          description: L1 cache
          physical id: 42
          slot: L1 Cache
          size: 128KiB
          capacity: 128KiB
          capabilities: synchronous internal write-back data
          configuration: level=1
     *-cache:5
          description: L1 cache
          physical id: 43
          slot: L1 Cache
          size: 256KiB
          capacity: 256KiB
          capabilities: synchronous internal write-back instruction
          configuration: level=1
     *-cache:6
          description: L2 cache
          physical id: 44
          slot: L2 Cache
          size: 2MiB
          capacity: 2MiB
          capabilities: synchronous internal write-back unified
          configuration: level=2
     *-cache:7
          description: L3 cache
          physical id: 45
          slot: L3 Cache
          size: 24MiB
          capacity: 24MiB
          capabilities: synchronous internal write-back unified
          configuration: level=3
     *-cpu
          description: CPU
          product: 13th Gen Intel(R) Core(TM) i7-13620H
          vendor: Intel Corp.
          physical id: 46
          bus info: cpu@0
          version: 13th Gen Intel(R) Core(TM) i7-13620H
          slot: U3E1
          size: 428MHz
          capacity: 4700MHz
          width: 64 bits
          clock: 100MHz
          capabilities: lm fpu fpu_exception wp vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp x86-64 constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperfmperf tsc_known_freq pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fma cx16 xtpr pdcm sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm 3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow vnmi flexpriority ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid rdseed adx smap clflushopt clwb intel_pt sha_ni xsaveopt xsavec xgetbv1 xsaves split_lock_detect avx_vnni dtherm ida arat pln pts hwp hwp_notify hwp_act_window hwp_epp hwp_pkg_req umip pku ospke waitpkg gfni vaes vpclmulqdq rdpid movdiri movdir64b fsrm md_clear serialize arch_lbr flush_l1d arch_capabilities cpufreq
          configuration: cores=10 enabledcores=10 threads=16
     *-pci
          description: Host bridge
          product: Intel Corporation
          vendor: Intel Corporation
          physical id: 100
          bus info: pci@0000:00:00.0
          version: 00
          width: 32 bits
          clock: 33MHz
        *-pci:0
             description: PCI bridge
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 1
             bus info: pci@0000:00:01.0
             version: 00
             width: 32 bits
             clock: 33MHz
             capabilities: pci pciexpress msi pm normal_decode bus_master cap_list
             configuration: driver=pcieport
             resources: irq:121 ioport:5000(size=4096) memory:81000000-820fffff ioport:4000000000(size=8623489024)
           *-display
                description: VGA compatible controller
                product: NVIDIA Corporation
                vendor: NVIDIA Corporation
                physical id: 0
                bus info: pci@0000:01:00.0
                version: a1
                width: 64 bits
                clock: 33MHz
                capabilities: pm msi pciexpress vga_controller bus_master cap_list rom
                configuration: driver=nvidia latency=0
                resources: iomemory:400-3ff iomemory:420-41f irq:155 memory:81000000-81ffffff memory:4000000000-41ffffffff memory:4200000000-4201ffffff ioport:5000(size=128) memory:82000000-8207ffff
           *-multimedia
                description: Audio device
                product: NVIDIA Corporation
                vendor: NVIDIA Corporation
                physical id: 0.1
                bus info: pci@0000:01:00.1
                version: a1
                width: 32 bits
                clock: 33MHz
                capabilities: pm msi pciexpress bus_master cap_list
                configuration: driver=snd_hda_intel latency=0
                resources: irq:17 memory:82080000-82083fff
        *-generic:0 UNCLAIMED
             description: Signal processing controller
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 4
             bus info: pci@0000:00:04.0
             version: 00
             width: 64 bits
             clock: 33MHz
             capabilities: msi pm cap_list
             configuration: latency=0
             resources: iomemory:420-41f memory:4202100000-420211ffff
        *-pci:1
             description: PCI bridge
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 6
             bus info: pci@0000:00:06.0
             version: 00
             width: 32 bits
             clock: 33MHz
             capabilities: pci pciexpress msi pm normal_decode bus_master cap_list
             configuration: driver=pcieport
             resources: irq:122 memory:82d00000-82dfffff
           *-storage
                description: Non-Volatile memory controller
                product: Yangtze Memory Technologies Co.,Ltd
                vendor: Yangtze Memory Technologies Co.,Ltd
                physical id: 0
                bus info: pci@0000:02:00.0
                version: 03
                width: 64 bits
                clock: 33MHz
                capabilities: storage pm msi pciexpress msix nvm_express bus_master cap_list
                configuration: driver=nvme latency=0
                resources: irq:16 memory:82d00000-82d03fff
              *-nvme0
                   description: NVMe device
                   product: YMTC PC300-512GB-B
                   physical id: 0
                   logical name: /dev/nvme0
                   version: YM0500C6
                   serial: YMA2512KA234840G93
                   configuration: nqn=nqn.2014.08.org.nvmexpress:1e491e49YMA2512KA234840G93  YMTC PC300-512GB-B state=live
                 *-namespace
                      description: NVMe namespace
                      physical id: 1
                      logical name: /dev/nvme0n1
                      size: 476GiB (512GB)
                      capabilities: gpt-1.00 partitioned partitioned:gpt
                      configuration: guid=2ec0d63c-0b61-493f-ad04-a9ca33b65a82 logicalsectorsize=512 sectorsize=512
                    *-volume:0
                         description: Windows FAT volume
                         vendor: mkfs.fat
                         physical id: 1
                         logical name: /dev/nvme0n1p1
                         logical name: /boot/efi
                         version: FAT32
                         serial: 833d-e855
                         size: 951MiB
                         capacity: 952MiB
                         capabilities: boot fat initialized
                         configuration: FATs=2 filesystem=fat mount.fstype=vfat mount.options=rw,relatime,fmask=0077,dmask=0077,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro state=mounted
                    *-volume:1
                         description: Linux swap volume
                         vendor: Linux
                         physical id: 2
                         logical name: /dev/nvme0n1p2
                         version: 1
                         serial: 46390d56-53af-411a-a96c-a40d954362cf
                         size: 17GiB
                         capacity: 17GiB
                         capabilities: nofs swap initialized
                         configuration: filesystem=swap pagesize=4095
                    *-volume:2
                         description: EXT4 volume
                         vendor: Linux
                         physical id: 3
                         logical name: /dev/nvme0n1p3
                         logical name: /
                         version: 1.0
                         serial: 41467cf0-89fa-4b87-996b-f501410f4db5
                         size: 186GiB
                         capabilities: journaled extended_attributes large_files huge_files dir_nlink recover 64bit extents ext4 ext2 initialized
                         configuration: created=2025-10-31 14:27:00 filesystem=ext4 lastmountpoint=/ modified=2026-03-31 18:58:59 mount.fstype=ext4 mount.options=rw,relatime,errors=remount-ro mounted=2026-03-31 18:59:00 state=mounted
                    *-volume:3
                         description: EXT4 volume
                         vendor: Linux
                         physical id: 4
                         logical name: /dev/nvme0n1p4
                         logical name: /home
                         version: 1.0
                         serial: 5c506cae-809a-41b8-aea8-27ed0bd4e649
                         size: 271GiB
                         capabilities: journaled extended_attributes large_files huge_files dir_nlink recover 64bit extents ext4 ext2 initialized
                         configuration: created=2025-10-31 14:28:11 filesystem=ext4 lastmountpoint=/home modified=2026-03-31 18:59:02 mount.fstype=ext4 mount.options=rw,relatime mounted=2026-03-31 18:59:02 state=mounted
        *-generic:1 UNCLAIMED
             description: System peripheral
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 8
             bus info: pci@0000:00:08.0
             version: 00
             width: 64 bits
             clock: 33MHz
             capabilities: msi pm cap_list
             configuration: latency=0
             resources: iomemory:420-41f memory:4202160000-4202160fff
        *-generic:2 UNCLAIMED
             description: Signal processing controller
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: a
             bus info: pci@0000:00:0a.0
             version: 01
             width: 64 bits
             clock: 33MHz
             capabilities: pciexpress pm cap_list
             configuration: latency=0
             resources: iomemory:420-41f memory:4202140000-4202147fff
        *-usb:0
             description: USB controller
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: d
             bus info: pci@0000:00:0d.0
             version: 00
             width: 64 bits
             clock: 33MHz
             capabilities: pm msi xhci bus_master cap_list
             configuration: driver=xhci_hcd latency=0
             resources: iomemory:420-41f irq:125 memory:4202130000-420213ffff
           *-usbhost:0
                product: xHCI Host Controller
                vendor: Linux 5.15.0-139-generic xhci-hcd
                physical id: 0
                bus info: usb@1
                logical name: usb1
                version: 5.15
                capabilities: usb-2.00
                configuration: driver=hub slots=1 speed=480Mbit/s
           *-usbhost:1
                product: xHCI Host Controller
                vendor: Linux 5.15.0-139-generic xhci-hcd
                physical id: 1
                bus info: usb@2
                logical name: usb2
                version: 5.15
                capabilities: usb-3.10
                configuration: driver=hub slots=3 speed=10000Mbit/s
        *-usb:1
             description: USB controller
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 14
             bus info: pci@0000:00:14.0
             version: 01
             width: 64 bits
             clock: 33MHz
             capabilities: pm msi xhci bus_master cap_list
             configuration: driver=xhci_hcd latency=0
             resources: iomemory:420-41f irq:127 memory:4202120000-420212ffff
           *-usbhost:0
                product: xHCI Host Controller
                vendor: Linux 5.15.0-139-generic xhci-hcd
                physical id: 0
                bus info: usb@3
                logical name: usb3
                version: 5.15
                capabilities: usb-2.00
                configuration: driver=hub slots=12 speed=480Mbit/s
              *-usb:0
                   description: Mouse
                   product: Lenovo USB Optical Mouse
                   vendor: PixArt
                   physical id: 8
                   bus info: usb@3:8
                   version: 1.00
                   capabilities: usb-2.00
                   configuration: driver=usbhid maxpower=100mA speed=2Mbit/s
              *-usb:1
                   description: Bluetooth wireless interface
                   vendor: Intel Corp.
                   physical id: a
                   bus info: usb@3:a
                   version: 0.02
                   capabilities: bluetooth usb-2.01
                   configuration: driver=btusb maxpower=100mA speed=12Mbit/s
           *-usbhost:1
                product: xHCI Host Controller
                vendor: Linux 5.15.0-139-generic xhci-hcd
                physical id: 1
                bus info: usb@4
                logical name: usb4
                version: 5.15
                capabilities: usb-3.10
                configuration: driver=hub slots=4 speed=10000Mbit/s
        *-memory UNCLAIMED
             description: RAM memory
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 14.2
             bus info: pci@0000:00:14.2
             version: 01
             width: 64 bits
             clock: 33MHz (30.3ns)
             capabilities: pm cap_list
             configuration: latency=0
             resources: iomemory:420-41f iomemory:420-41f memory:4202158000-420215bfff memory:420215f000-420215ffff
        *-network
             description: Ethernet interface
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 14.3
             bus info: pci@0000:00:14.3
             logical name: wlo1
             version: 01
             serial: 68:34:21:c9:dd:f8
             width: 64 bits
             clock: 33MHz
             capabilities: pm msi pciexpress msix bus_master cap_list ethernet physical
             configuration: broadcast=yes driver=iwlwifi driverversion=5.15.0-139-generic firmware=71.058653f6.0 so-a0-hr-b0-71.uc ip=192.168.0.172 latency=0 link=yes multicast=yes
             resources: iomemory:420-41f irq:16 memory:4202154000-4202157fff
        *-serial:0
             description: Serial bus controller
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 15
             bus info: pci@0000:00:15.0
             version: 01
             width: 64 bits
             clock: 33MHz
             capabilities: pm bus_master cap_list
             configuration: driver=intel-lpss latency=0
             resources: irq:27 memory:4202148000-4202148fff
        *-communication
             description: Communication controller
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 16
             bus info: pci@0000:00:16.0
             version: 01
             width: 64 bits
             clock: 33MHz
             capabilities: pm msi bus_master cap_list
             configuration: driver=mei_me latency=0
             resources: iomemory:420-41f irq:137 memory:420215d000-420215dfff
        *-pci:2
             description: PCI bridge
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 1d
             bus info: pci@0000:00:1d.0
             version: 01
             width: 32 bits
             clock: 33MHz
             capabilities: pci pciexpress msi pm normal_decode bus_master cap_list
             configuration: driver=pcieport
             resources: irq:123 ioport:4000(size=4096) memory:82200000-82bfffff ioport:4202200000(size=2097152)
        *-pci:3
             description: PCI bridge
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 1d.3
             bus info: pci@0000:00:1d.3
             version: 01
             width: 32 bits
             clock: 33MHz
             capabilities: pci pciexpress msi pm normal_decode bus_master cap_list
             configuration: driver=pcieport
             resources: irq:124 ioport:3000(size=4096) memory:82c00000-82cfffff
           *-network
                description: Ethernet interface
                product: RTL8111/8168/8411 PCI Express Gigabit Ethernet Controller
                vendor: Realtek Semiconductor Co., Ltd.
                physical id: 0
                bus info: pci@0000:04:00.0
                logical name: enp4s0
                version: 15
                serial: 98:bb:1e:85:ff:23
                capacity: 1Gbit/s
                width: 64 bits
                clock: 33MHz
                capabilities: pm msi pciexpress msix bus_master cap_list ethernet physical tp mii 10bt 10bt-fd 100bt 100bt-fd 1000bt-fd autonegotiation
                configuration: autonegotiation=on broadcast=yes driver=r8169 driverversion=5.15.0-139-generic firmware=rtl8168h-2_0.0.2 02/26/15 latency=0 link=no multicast=yes port=twisted pair
                resources: irq:19 ioport:3000(size=256) memory:82c04000-82c04fff memory:82c00000-82c03fff
        *-isa
             description: ISA bridge
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 1f
             bus info: pci@0000:00:1f.0
             version: 01
             width: 32 bits
             clock: 33MHz
             capabilities: isa bus_master
             configuration: latency=0
        *-multimedia
             description: Multimedia audio controller
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 1f.3
             bus info: pci@0000:00:1f.3
             version: 01
             width: 64 bits
             clock: 33MHz
             capabilities: pm msi bus_master cap_list
             configuration: driver=snd_hda_intel latency=32
             resources: iomemory:420-41f iomemory:420-41f irq:154 memory:4202150000-4202153fff memory:4202000000-42020fffff
        *-serial:1
             description: SMBus
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 1f.4
             bus info: pci@0000:00:1f.4
             version: 01
             width: 64 bits
             clock: 33MHz
             configuration: driver=i801_smbus latency=0
             resources: iomemory:420-41f irq:16 memory:420215c000-420215c0ff ioport:efa0(size=32)
        *-serial:2 UNCLAIMED
             description: Serial bus controller
             product: Intel Corporation
             vendor: Intel Corporation
             physical id: 1f.5
             bus info: pci@0000:00:1f.5
             version: 01
             width: 32 bits
             clock: 33MHz
             configuration: latency=0
             resources: memory:80400000-80400fff
     *-pnp00:00
          product: PnP device PNP0c02
          physical id: 1
          capabilities: pnp
          configuration: driver=system
     *-pnp00:01
          product: PnP device PNP0c02
          physical id: 2
          capabilities: pnp
          configuration: driver=system
     *-pnp00:02
          product: PnP device PNP0c02
          physical id: 3
          capabilities: pnp
          configuration: driver=system
     *-pnp00:03
          product: PnP device PNP0c02
          physical id: 4
          capabilities: pnp
          configuration: driver=system
     *-pnp00:04
          product: PnP device PNP0c02
          physical id: 5
          capabilities: pnp
          configuration: driver=system
  *-power UNCLAIMED
       physical id: 1
(base) abc@abc-MIX:~$
```

```bash
uname -a
lsb_release -a
nvidia-smi
nvcc -V
python3 --version
conda --version
df -h
free -h
lsusb
ros2 --help | head
lscpu
sudo lshw -C display
ubuntu-drivers devices
dpkg -l | grep -E 'nvidia|cuda|cudnn'
```

```text
(base) abc@abc-MIX:~$ uname -a
Linux abc-MIX 5.15.0-139-generic #149~20.04.1-Ubuntu SMP Wed Apr 16 08:29:56 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
(base) abc@abc-MIX:~$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 20.04.6 LTS
Release:        20.04
Codename:       focal
(base) abc@abc-MIX:~$ nvidia-smi
Tue Mar 31 21:18:17 2026
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 570.133.20             Driver Version: 570.133.20     CUDA Version: 12.8     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 4060 ...    Off |   00000000:01:00.0  On |                  N/A |
| N/A   33C    P8              2W /   80W |     376MiB /   8188MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A            1012      G   /usr/lib/xorg/Xorg                       53MiB |
|    0   N/A  N/A            1781      G   /usr/lib/xorg/Xorg                      104MiB |
|    0   N/A  N/A            1908      G   /usr/bin/gnome-shell                     33MiB |
|    0   N/A  N/A            2460      G   /usr/lib/firefox/firefox                117MiB |
+-----------------------------------------------------------------------------------------+
(base) abc@abc-MIX:~$ nvcc -V
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2022 NVIDIA Corporation
Built on Wed_Sep_21_10:33:58_PDT_2022
Cuda compilation tools, release 11.8, V11.8.89
Build cuda_11.8.r11.8/compiler.31833905_0
(base) abc@abc-MIX:~$ python3 --version
Python 3.13.9
(base) abc@abc-MIX:~$ conda --version
conda 25.9.1
(base) abc@abc-MIX:~$ df -h
文件系统        容量  已用  可用 已用% 挂载点
udev            7.6G     0  7.6G    0% /dev
tmpfs           1.6G  2.3M  1.6G    1% /run
/dev/nvme0n1p3  183G   46G  127G   27% /
tmpfs           7.7G     0  7.7G    0% /dev/shm
tmpfs           5.0M  4.0K  5.0M    1% /run/lock
tmpfs           7.7G     0  7.7G    0% /sys/fs/cgroup
/dev/loop0      128K  128K     0  100% /snap/bare/5
/dev/loop3       63M   63M     0  100% /snap/gtk-common-themes/1506
/dev/loop2       74M   74M     0  100% /snap/core22/2139
/dev/loop1       56M   56M     0  100% /snap/core18/2959
/dev/loop4       51M   51M     0  100% /snap/snapd/25577
/dev/loop5      219M  219M     0  100% /snap/gnome-3-34-1804/93
/dev/loop6      241M  241M     0  100% /snap/gnome-3-34-1804/24
/dev/loop7       56M   56M     0  100% /snap/core18/2952
/dev/loop10      50M   50M     0  100% /snap/snap-store/433
/dev/loop8      517M  517M     0  100% /snap/gnome-42-2204/226
/dev/loop9       13M   13M     0  100% /snap/snap-store/1216
/dev/loop11      92M   92M     0  100% /snap/gtk-common-themes/1535
/dev/nvme0n1p1  952M  6.1M  946M    1% /boot/efi
/dev/nvme0n1p4  267G   28G  226G   11% /home
tmpfs           1.6G   24K  1.6G    1% /run/user/125
tmpfs           1.6G   36K  1.6G    1% /run/user/1000
(base) abc@abc-MIX:~$ free -h
              总计         已用        空闲      共享    缓冲/缓存    可用
内存：        15Gi       2.8Gi       9.8Gi        11Mi       2.7Gi        12Gi
交换：        17Gi          0B        17Gi
(base) abc@abc-MIX:~$ lsusb
Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 003 Device 002: ID 17ef:6019 Lenovo Lenovo USB Optical Mouse
Bus 003 Device 003: ID 8087:0026 Intel Corp.
Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
(base) abc@abc-MIX:~$ ros2 --help | head
ros2：未找到命令
(base) abc@abc-MIX:~$ ros1 --help | head

找不到命令“ros1”，您的意思是：

  command 'rso1' from snap rso1 (1.0)

See 'snap info <snapname>' for additional versions.

(base) abc@abc-MIX:~$ lscpu
架构：                                x86_64
CPU 运行模式：                        32-bit, 64-bit
字节序：                              Little Endian
Address sizes:                        39 bits physical, 48 bits virtual
CPU:                                  16
在线 CPU 列表：                       0-15
每个核的线程数：                      1
每个座的核数：                        10
座：                                  1
NUMA 节点：                           1
厂商 ID：                             GenuineIntel
CPU 系列：                            6
型号：                                186
型号名称：                            13th Gen Intel(R) Core(TM) i7-13620H
步进：                                2
CPU MHz：                             2900.000
CPU 最大 MHz：                        4900.0000
CPU 最小 MHz：                        400.0000
BogoMIPS：                            5836.80
虚拟化：                              VT-x
L1d 缓存：                            240 KiB
L1i 缓存：                            160 KiB
L2 缓存：                             6.3 MiB
NUMA 节点0 CPU：                      0-15
Vulnerability Gather data sampling:   Not affected
Vulnerability Itlb multihit:          Not affected
Vulnerability L1tf:                   Not affected
Vulnerability Mds:                    Not affected
Vulnerability Meltdown:               Not affected
Vulnerability Mmio stale data:        Not affected
Vulnerability Reg file data sampling: Mitigation; Clear Register File
Vulnerability Retbleed:               Not affected
Vulnerability Spec rstack overflow:   Not affected
Vulnerability Spec store bypass:      Mitigation; Speculative Store Bypass disabled via prctl and seccomp
Vulnerability Spectre v1:             Mitigation; usercopy/swapgs barriers and __user pointer sanitization
Vulnerability Spectre v2:             Mitigation; Enhanced / Automatic IBRS; IBPB conditional; RSB filling; PBRSB-eIBRS SW sequence; BHI BHI_DIS_
                                      S
Vulnerability Srbds:                  Not affected
Vulnerability Tsx async abort:        Not affected
标记：                                fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2
                                      ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc art arch_perfmon pebs bts rep_good nopl xtopology no
                                      nstop_tsc cpuid aperfmperf tsc_known_freq pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 sdbg fm
                                      a cx16 xtpr pdcm sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm
                                       3dnowprefetch cpuid_fault epb ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow vnmi flexpriority ept vpid ept
                                      _ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid rdseed adx smap clflushopt clwb intel_pt sha_ni xs
                                      aveopt xsavec xgetbv1 xsaves split_lock_detect avx_vnni dtherm ida arat pln pts hwp hwp_notify hwp_act_wind
                                      ow hwp_epp hwp_pkg_req umip pku ospke waitpkg gfni vaes vpclmulqdq rdpid movdiri movdir64b fsrm md_clear se
                                      rialize arch_lbr flush_l1d arch_capabilities
(base) abc@abc-MIX:~$ sudo lshw -C display
  *-display
       description: VGA compatible controller
       product: NVIDIA Corporation
       vendor: NVIDIA Corporation
       physical id: 0
       bus info: pci@0000:01:00.0
       version: a1
       width: 64 bits
       clock: 33MHz
       capabilities: pm msi pciexpress vga_controller bus_master cap_list rom
       configuration: driver=nvidia latency=0
       resources: iomemory:400-3ff iomemory:420-41f irq:155 memory:81000000-81ffffff memory:4000000000-41ffffffff memory:4200000000-4201ffffff ioport:5000(size=128) memory:82000000-8207ffff
(base) abc@abc-MIX:~$ ubuntu-drivers devices
== /sys/devices/pci0000:00/0000:00:01.0/0000:01:00.0 ==
modalias : pci:v000010DEd000028A0sv00001B61sd00008004bc03sc00i00
vendor   : NVIDIA Corporation
driver   : nvidia-driver-570 - distro non-free recommended
driver   : nvidia-driver-570-server-open - distro non-free
driver   : nvidia-driver-535-open - distro non-free
driver   : nvidia-driver-570-server - distro non-free
driver   : nvidia-driver-535-server-open - distro non-free
driver   : nvidia-driver-535 - distro non-free
driver   : nvidia-driver-535-server - distro non-free
driver   : nvidia-driver-570-open - distro non-free
driver   : xserver-xorg-video-nouveau - distro free builtin

(base) abc@abc-MIX:~$ dpkg -l | grep -E 'nvidia|cuda|cudnn'
ii  libnvidia-cfg1-570-server:amd64             570.133.20-0ubuntu0.20.04.1          amd64        NVIDIA binary OpenGL/GLX configuration library
ii  libnvidia-common-570-server                 570.133.20-0ubuntu0.20.04.1          all          Shared files used by the NVIDIA libraries
ii  libnvidia-compute-570-server:amd64          570.133.20-0ubuntu0.20.04.1          amd64        NVIDIA libcompute package
ii  libnvidia-compute-570-server:i386           570.133.20-0ubuntu0.20.04.1          i386         NVIDIA libcompute package
ii  libnvidia-container-tools                   1.19.0-1                             amd64        NVIDIA container runtime library (command-line tools)
ii  libnvidia-container1:amd64                  1.19.0-1                             amd64        NVIDIA container runtime library
ii  libnvidia-decode-570-server:amd64           570.133.20-0ubuntu0.20.04.1          amd64        NVIDIA Video Decoding runtime libraries
ii  libnvidia-decode-570-server:i386            570.133.20-0ubuntu0.20.04.1          i386         NVIDIA Video Decoding runtime libraries
ii  libnvidia-egl-wayland1:amd64                1:1.1.3-1ubuntu1                     amd64        Wayland EGL External Platform library -- shared library
ii  libnvidia-encode-570-server:amd64           570.133.20-0ubuntu0.20.04.1          amd64        NVENC Video Encoding runtime library
ii  libnvidia-encode-570-server:i386            570.133.20-0ubuntu0.20.04.1          i386         NVENC Video Encoding runtime library
ii  libnvidia-extra-570-server:amd64            570.133.20-0ubuntu0.20.04.1          amd64        Extra libraries for the NVIDIA Server Driver
ii  libnvidia-fbc1-570-server:amd64             570.133.20-0ubuntu0.20.04.1          amd64        NVIDIA OpenGL-based Framebuffer Capture runtime library
ii  libnvidia-fbc1-570-server:i386              570.133.20-0ubuntu0.20.04.1          i386         NVIDIA OpenGL-based Framebuffer Capture runtime library
ii  libnvidia-gl-570-server:amd64               570.133.20-0ubuntu0.20.04.1          amd64        NVIDIA OpenGL/GLX/EGL/GLES GLVND libraries and Vulkan ICD
ii  nvidia-compute-utils-570-server             570.133.20-0ubuntu0.20.04.1          amd64        NVIDIA compute utilities
ii  nvidia-container-toolkit                    1.19.0-1                             amd64        NVIDIA Container toolkit
ii  nvidia-container-toolkit-base               1.19.0-1                             amd64        NVIDIA Container Toolkit Base
ii  nvidia-dkms-570-server                      570.133.20-0ubuntu0.20.04.1          amd64        NVIDIA DKMS package
ii  nvidia-driver-570-server                    570.133.20-0ubuntu0.20.04.1          amd64        NVIDIA Server Driver metapackage
ii  nvidia-firmware-570-server-570.133.20       570.133.20-0ubuntu0.20.04.1          amd64        Firmware files used by the kernel module
ii  nvidia-kernel-common-570-server             570.133.20-0ubuntu0.20.04.1          amd64        Shared files used with the kernel module
ii  nvidia-kernel-source-570-server             570.133.20-0ubuntu0.20.04.1          amd64        NVIDIA kernel source package
ii  nvidia-utils-570-server                     570.133.20-0ubuntu0.20.04.1          amd64        NVIDIA Server Driver support binaries
ii  xserver-xorg-video-nvidia-570-server        570.133.20-0ubuntu0.20.04.1          amd64        NVIDIA binary Xorg driver
(base) abc@abc-MIX:~$
```

## 后续补充

- 补充截图对应的操作步骤、问题现象和最终结论。
- 如果截图中的本机路径失效，建议把图片移动到 `assets/` 后改为相对路径。
