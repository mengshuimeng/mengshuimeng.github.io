# VS Code 配置 C/C++ 开发环境（Windows + MinGW-w64）

> 本文档用于在 Windows 上使用 **VS Code + MinGW-w64** 搭建 C/C++ 开发环境，并解决常见的中文乱码问题。  
>
> 适用对象：使用 Windows 进行 C / C++ 学习与开发的同学  
> 作者：姜树豪（JSH）  
> 更新时间：2026-03-09

---

## 参考链接

[VsCode-配置C/C++开发环境1.VS Code 配置 C/C++ 开发环境 ; 2. VS Code安装 GCC - 掘金](https://juejin.cn/post/7493749701780242486#T_lable2)

[Pre-built Toolchains - mingw-w64](https://www.mingw-w64.org/downloads/)

[Releases · niXman/mingw-builds-binaries](https://github.com/niXman/mingw-builds-binaries/releases)

 `[x86_64-15.2.0-release-posix-seh-msvcrt-rt_v13-rev0.7z](https://github.com/niXman/mingw-builds-binaries/releases/download/15.2.0-rt_v13-rev0/x86_64-15.2.0-release-posix-seh-msvcrt-rt_v13-rev0.7z)`



## 目录

1. 环境说明
2. 安装 VS Code
3. 安装 C/C++ 扩展
4. 安装 MinGW-w64
5. 配置环境变量
6. 验证 GCC / G++
7. 在 VS Code 中编译运行 C/C++
8. 中文乱码的常见原因与解决方法
9. 常用命令速查表

---

## 1. 环境说明

在 Windows 下使用 VS Code 编写 C/C++ 程序，通常需要三部分：

1. **VS Code 编辑器**
2. **C/C++ 扩展**
3. **C/C++ 编译器工具链**

VS Code 官方说明中，Windows 下可以使用 **MSVC** 或 **MinGW-w64 的 GCC/G++** 作为编译器；如果你走 GCC 路线，官方就有一套基于 MinGW-w64 的配置流程。:contentReference[oaicite:1]{index=1}

本文采用的是：

- 编辑器：VS Code
- 编译器：MinGW-w64（GCC / G++）
- 调试器：GDB

---

## 2. 安装 VS Code

前往 VS Code 官网下载安装包并完成安装。VS Code 官方提供 Windows 安装包和相关文档。:contentReference[oaicite:2]{index=2}

安装完成后，建议先确认以下两点：

- VS Code 可以正常打开
- 可以打开内置终端

VS Code 内置终端可通过以下快捷键打开：

```text
Ctrl + `
```

VS Code 官方文档也说明了可以在编辑器中直接使用集成终端。([Visual Studio Code](https://code.visualstudio.com/docs/getstarted/getting-started?utm_source=chatgpt.com))

------

## 3. 安装 C/C++ 扩展

打开 VS Code 后：

1. 点击左侧 **扩展（Extensions）**
2. 搜索 `C/C++`
3. 安装 Microsoft 发布的 **C/C++ 扩展**

VS Code 官方说明里，C/C++ 语言支持由 Microsoft 的 C/C++ 扩展提供，包括语法高亮、补全、错误检查、调试支持等。([Visual Studio Code](https://code.visualstudio.com/docs/languages/cpp?utm_source=chatgpt.com))

------

## 4. 安装 MinGW-w64

### 4.1 为什么要安装 MinGW-w64

VS Code 本身只是编辑器，不自带 GCC / G++。
如果你想在 Windows 下使用 GCC 编译 C/C++ 程序，就需要额外安装 MinGW-w64 工具链。VS Code 官方的 MinGW 教程也是基于这一思路。([Visual Studio Code](https://code.visualstudio.com/docs/cpp/config-mingw?utm_source=chatgpt.com))

### 4.2 下载来源

可以从以下来源获取 MinGW-w64：

- **mingw-w64 官方下载页**
- **niXman 维护的预构建二进制发布页**

MinGW-w64 官方下载页本身就提供了预构建工具链入口；niXman 的 `mingw-builds-binaries` 仓库则提供可直接下载的 Windows 预编译版本。([GitHub](https://github.com/niXman/mingw-builds-binaries?utm_source=chatgpt.com))

### 4.3 推荐下载包

对于大多数 64 位 Windows 用户，可以使用类似下面这一类包：

```text
x86_64-15.2.0-release-posix-seh-msvcrt-rt_v13-rev0.7z
```

这个命名可以拆开理解：

- `x86_64`：适用于 64 位 Windows
- `release`：发布版
- `posix`：线程模型
- `seh`：64 位 Windows 常见异常处理模型
- `msvcrt`：使用微软 C 运行时
- `15.2.0`：GCC 版本

niXman 当前发布页中可以看到对应的 15.2.0 系列发行版，并包含 GDB、binutils、MinGW-w64 v13 等更新。([GitHub](https://github.com/niXman/mingw-builds-binaries/releases?utm_source=chatgpt.com))

### 4.4 解压安装

下载完成后：

1. 将压缩包解压到一个固定目录，例如：

```text
C:\mingw64
```

1. 确认下面这个目录存在：

```text
C:\mingw64\bin
```

这个目录里通常会有：

- `gcc.exe`
- `g++.exe`
- `gdb.exe`

------

## 5. 配置环境变量

为了在终端中直接使用 `gcc`、`g++`、`gdb`，需要把 `bin` 目录加入系统环境变量 `Path`。

### 操作步骤

1. 打开 Windows 的“环境变量”设置
2. 找到系统变量或用户变量中的 `Path`
3. 新增一项：

```text
C:\mingw64\bin
```

1. 保存后，**重新打开终端** 或重启 VS Code

------

## 6. 验证 GCC / G++

打开 PowerShell、CMD 或 VS Code 内置终端，执行：

```bash
gcc --version
g++ --version
gdb --version
```

如果能够正常输出版本信息，说明编译器和调试器已经配置成功。VS Code 官方 MinGW 教程同样要求先确认 `g++` 与 `gdb` 在 PATH 中可用。([Visual Studio Code](https://code.visualstudio.com/docs/cpp/config-mingw?utm_source=chatgpt.com))

------

## 7. 在 VS Code 中编译运行 C/C++

### 7.1 新建测试文件

新建一个 `hello.cpp` 文件：

```cpp
#include <iostream>
using namespace std;

int main() {
    cout << "Hello, C++!" << endl;
    return 0;
}
```

### 7.2 手动编译

在终端执行：

```bash
g++ hello.cpp -o hello.exe
```

### 7.3 运行程序

```bash
./hello.exe
```

或者在 Windows 终端中执行：

```bash
hello.exe
```

### 7.4 关于 VS Code 的自动配置

VS Code 官方教程中，第一次运行或调试 C/C++ 程序时，通常会自动生成：

- `tasks.json`
- `launch.json`

分别用于：

- 定义编译任务
- 定义调试配置。([Visual Studio Code](https://code.visualstudio.com/docs/cpp/config-mingw?utm_source=chatgpt.com))

------

## 8. 中文乱码的常见原因与解决方法

这一部分你原稿只写了两条，但实际上 Windows 下 C/C++ 中文乱码通常有三层原因：

1. **源文件编码不对**
2. **终端代码页不对**
3. **编译器字符集处理不一致**

所以不能只靠改一个 VS Code 设置就断定能解决全部乱码问题。

------

### 8.1 方法一：确保源文件编码为 UTF-8

先确认你的 `.c` / `.cpp` 文件本身就是 UTF-8 编码。

操作方法：

1. 打开 C/C++ 源文件
2. 点击 VS Code 右下角状态栏中的编码格式
3. 如果不是 UTF-8，选择 **“重新打开带编码”**
4. 选择 **UTF-8**
5. 再保存文件

这一步的目的，是确保源文件本身不是 GBK、ANSI 或其他本地编码格式。

------

### 8.2 方法二：让终端使用 UTF-8 代码页

Windows 控制台的代码页会影响输出显示。微软官方 `chcp` 文档说明，`chcp` 用来修改当前控制台代码页；其中 `65001` 表示 UTF-8。([Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/chcp?utm_source=chatgpt.com))

可以在终端里执行：

```bat
chcp 65001
```

查看当前代码页：

```bat
chcp
```

如果输出为：

```text
Active code page: 65001
```

说明当前终端已切换为 UTF-8。([Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/chcp?utm_source=chatgpt.com))

------

### 8.3 方法三：在 VS Code 终端中设置环境变量

VS Code 官方文档确实支持通过设置项配置终端环境与终端 profile，但 Windows 终端显示是否正常，往往还会同时受控制台代码页和程序输出编码影响。([Visual Studio Code](https://code.visualstudio.com/docs/terminal/profiles?utm_source=chatgpt.com))

如果你想保留这项配置，可以在 `settings.json` 中添加：

```json
{
  "terminal.integrated.env.windows": {
    "LANG": "zh_CN.UTF-8"
  }
}
```

但要知道：
**这更像辅助设置，不是万能修复。**

------

### 8.4 方法四：给 GCC 显式指定字符集

GCC 官方文档明确提供了这些选项：

- `-finput-charset=charset`
- `-fexec-charset=charset`

其中：

- `-finput-charset`：指定源文件输入字符集
- `-fexec-charset`：指定程序运行时字符串/字符常量的执行字符集。([GCC](https://gcc.gnu.org/onlinedocs/gcc/Preprocessor-Options.html?utm_source=chatgpt.com))

如果你确定源文件是 UTF-8，可以尝试这样编译：

```bash
g++ hello.cpp -o hello.exe -finput-charset=UTF-8 -fexec-charset=UTF-8
```

这对于“源文件看起来没问题，但输出仍乱码”的情况，往往比只改 VS Code 设置更直接。

------

### 8.5 中文乱码排查顺序

建议按下面顺序排查：

1. **先看源文件是不是 UTF-8**
2. **再看终端是不是 UTF-8 代码页**
3. **最后看编译参数是不是需要显式指定字符集**

也就是说：

- 文件没保存成 UTF-8，先改文件编码
- 文件没问题但终端乱码，先试 `chcp 65001`
- 终端也正常但程序输出仍乱码，再试 GCC 的字符集参数

------

## 9. 常用命令速查表

| 操作                | 命令                                                         |
| ------------------- | ------------------------------------------------------------ |
| 查看 GCC 版本       | `gcc --version`                                              |
| 查看 G++ 版本       | `g++ --version`                                              |
| 查看 GDB 版本       | `gdb --version`                                              |
| 编译 C++ 程序       | `g++ hello.cpp -o hello.exe`                                 |
| 运行程序            | `hello.exe`                                                  |
| 切换终端为 UTF-8    | `chcp 65001`                                                 |
| 查看当前代码页      | `chcp`                                                       |
| 显式指定 UTF-8 编译 | `g++ hello.cpp -o hello.exe -finput-charset=UTF-8 -fexec-charset=UTF-8` |

------

## 总结

Windows 下用 VS Code 配置 C/C++ 环境，主线很简单：

1. 安装 VS Code
2. 安装 Microsoft C/C++ 扩展
3. 安装 MinGW-w64
4. 配置 `Path`
5. 验证 `gcc` / `g++` / `gdb`
6. 编译运行测试程序

而“中文乱码”不要只记一个设置。
更稳的理解方式是：

- **源文件编码**
- **终端代码页**
- **编译器字符集**

这三层只要有一层不一致，就可能出问题。