## 3. WSL 的路径机制

这一部分是最容易混乱的。

### 3.1 Linux 根目录只有一个：`/`

在 WSL 中，Linux 文件系统的根目录始终是：

```bash
/
```

你在终端里看到 `/home/jiang`、`/mnt/c/Users/32020`、`/etc`，它们都只是同一个根目录下的不同路径，不存在“两个根目录”。这是理解 WSL 路径的前提。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/setup/environment?utm_source=chatgpt.com))

### 3.2 Windows 磁盘会挂载到 `/mnt/` 下

WSL 会将 Windows 的磁盘自动挂载到 Linux 文件系统中。默认情况下：

- `C:` 会挂载到 `/mnt/c`
- `D:` 会挂载到 `/mnt/d`
- 其他盘符也类似。([Microsoft Learn](https://learn.microsoft.com/en-us/windows/wsl/wsl-config?utm_source=chatgpt.com))

例如：

```text
C:\Users\32020
```

在 WSL 中通常对应：

```text
/mnt/c/Users/32020
```

### 3.3 为什么有时进入后在 `/home/jiang`，有时在 `/mnt/c/Users/32020`

根本原因不是根目录变了，而是**当前工作目录不同**。

你的两种情况分别是：

- 在 WSL 里手动执行了 `cd /`，所以当前目录变成了 Linux 根目录 `/`
- 从 Windows PowerShell 某个目录直接启动 `wsl` 时，WSL 可能把当前 Windows 目录映射为 WSL 中的对应路径，因此一进来就在 `/mnt/c/Users/32020`

所以：

- `/` 是 Linux 根目录
- `/mnt/c/Users/32020` 是 Windows 用户目录在 WSL 中的挂载路径
- 它们不冲突，只是你“当前站的位置”不同

### 3.4 如何验证当前所在位置

```bash
pwd
```

常见结果：

```bash
/home/jiang
/
 /mnt/c/Users/32020
```

这些都只是在说明“你当前在哪个目录”，而不是说明“系统根目录变了”。

### 3.5 一个更直观的结构图

```text
/
├── bin
├── etc
├── home
│   └── jiang
├── mnt
│   ├── c
│   │   └── Users
│   │       └── 32020
│   ├── d
│   └── f
├── usr
└── var
```

### **方法一：使用** `cp` **命令（最常用）**

WSL 会自动将 Windows 的驱动器挂载到 `/mnt/` 目录下。例如，C 盘对应 `/mnt/c/`，D 盘对应 `/mnt/d/`。

**语法：**

bash



```
cp <源文件路径> /mnt/c/<目标文件夹路径>
```

**示例：**
假设你要将当前目录下的 `test.txt` 复制到 Windows C 盘的 `Users\YourName\Documents` 文件夹中：

1. 首先，确认 Windows 路径在 WSL 中的写法（将 `\` 改为 `/`，去掉盘符冒号，前缀加 `/mnt/`）：

   - Windows: `C:\Users\YourName\Documents`
   - WSL: `/mnt/c/Users/YourName/Documents`

2. 执行复制命令：

   bash

   

   ```
   cp test.txt /mnt/c/Users/YourName/Documents/
   ```

3. 如果要复制整个文件夹（递归复制），加上 `-r` 参数：

   bash

   

   ```
   cp -r my_project_folder /mnt/c/Users/YourName/Documents/
   ```

------

## 