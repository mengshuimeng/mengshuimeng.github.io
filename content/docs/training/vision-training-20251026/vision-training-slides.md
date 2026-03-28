---
title: 2025-10-26 视觉培训讲义
description: 视觉培训讲义，涵盖 AI 工具、Python 进阶与代码规范
slug: vision-training-slides
aliases:
  - /docs/training/vision-training-20251026/20251026视觉培训讲义/
---

你是计算机视觉组的学长，现在要给大一学弟学妹培训，主题是如何使用ai。我这有一些规划和安排，请你给出合理的流程和建议。请详细一些。

现在的一些问题

```
9.第三节和第五节里的实践项目不知道该怎么写
```



# AI

主讲人：姜树豪

- Ai大师课：Ai引擎选择，Ai类型，提示词优化，应该怎么用Ai，怎么发挥Ai的优势
- Python语法进阶：函数，类，模块
- 代码规范，模块化编程，代码编写美观与注释

tips ：可提醒购买摄像头，后续使用

作业：class 的应用

---

## 引言：市面上的AI

Deepseek  豆包P图 

**链接**：

[LLM Leaderboard](https://llm-stats.com/)



---

## 第1节：回顾Markdown语法

**目标**：学会用 Markdown 做笔记。
**内容**：

1. Markdown 基本语法（标题、列表、代码块、引用、表格、图片）——现场演示 Typora/GitHub README。

**资料**：

[简介 | MARKDOWN 中文](https://markdown.cn/docs/intro)

[Markdown 备忘单 ·adam-p/markdown-here 维基百科](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)

[Markdown 备忘单 ·adam-p/markdown-here 维基百科 ·GitHub](https://kkgithub.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)

------

## 第2节：AI 概念与 Prompt Engineering 入门

**目标**：理解 LLM、token、prompt 基本概念与使用技巧。
 **内容**：

1. 先介绍一些概念（见附1）

2. 交互演示：现场用 ChatGPT/其它模型修改 prompt，展示输出差异。

3. Prompt 优化套路：明确角色、明确输出格式、示例+约束、分步法（分解任务）。

   ```
   Prompt基础结构
     - 角色设定：让AI扮演特定角色
     - 任务描述：清晰明确地说明任务
     - 约束条件：输出格式、长度、风格等
     - 示例演示：现场对比优化前后的效果
   ```

4. **实战技巧**：每人做 3 个 Prompt，并按「原始→优化1→优化2」记录效果。

   ```
   实战技巧
     - 分步法：复杂任务分解
     - 示例法：提供输入输出样例
     - 迭代优化：根据结果调整Prompt
     - 常见陷阱：过于模糊、缺乏约束
   ```

   - 任务一：写一段文档摘要

   - 任务二：改写代码注释
   - 任务三：写一段代码

   

5. **作业**：整理 改进日志（Markdown）。

**链接**：

[提示工程指南 | Prompt Engineering Guide](https://www.promptingguide.ai/zh)

[dair-ai/Prompt-Engineering-Guide：🐙提示工程、上下文工程、RAG 和 AI 代理的指南、论文、课程、笔记本和资源。](https://github.com/dair-ai/Prompt-Engineering-Guide/)

------

## 第3节：API、Token、实战

**目标**：理解 API 概念、token 计费、如何在代码中调用模型。
**内容**：

1. 什么是 API、请求/响应 JSON、HTTP header（Authorization）、API Key 安全管理。
2. Token 是什么、如何估算 token（简要规则）、如何控制 token 成本（缩短上下文、限制 max_tokens）。
3. 为什么 AI 要收费（计算资源、存储、研发成本、维护与合规）。
4. 现场演示：用 Python 发起简单请求（伪代码 + 实战 demo，不用真实 Key 可用模拟或本地 mock）。
    **上机练习**：用 requests 或官方 SDK 写一个小脚本，发送 prompt（本地 mock 或演示）。

**链接**：

API 另一个markdown文件

OpenAI的Tokenizer工具 [Tokenizer - OpenAI API](https://platform.openai.com/tokenizer)

[推理时代](https://console.aihubmix.com/)

[Prompt-Engineering-Guide/notebooks/pe-lecture.ipynb at main · dair-ai/Prompt-Engineering-Guide](https://github.com/dair-ai/Prompt-Engineering-Guide/blob/main/notebooks/pe-lecture.ipynb)

---

## 第4节： AIGC

如何降低AIGC

查重网站



------

## 第5节：Prompt + 代码联动（AI 辅助编码、调试、测试）



## 

------

## 第6节：回顾上节课的一些软件

**目标**：知道上节课的各个软件是干什么的

**内容**：

1.Typora

2.PyCharm

3.conda

4.VScode

5.Python3.xx



**资料**：

---

## 第7节：Python 进阶（面向对象、模块化、代码规范）

**目标**：掌握类、模块、面向对象设计，写出结构清晰的代码。
 **内容**：

1. 类（class）、初始化（**init**）、方法、属性、继承与封装。
2. 模块化：如何拆分文件、包的组织、**main** 用法。
3. 代码规范：PEP8、注释（docstring）、类型提示（type hints）。

**面向对象的三大特性**

- 封装
  	封装就是把客观的事物封装成抽象的类，并且类可以把自己的数据和方法只让可信的类或者对象操作，对不可信的类进行信息的隐藏。简单的说就是：封装使对象的设计者与对象的使用者分开，使用者只要知道对象可以做什么就可以了，不需要知道具体是怎么实现的。封装可以有助于提高类和系统的安全性

- 继承
          当多个类中存在相同属性和行为时，将这些内容就可以抽取到一个单独的类中，使得多个类无需再定义这些属性和行为，只需继承那个类即可。通过继承创建的新类称为“子类”或“派生类”，被继承的类称为“基类”、“父类”或“超类”

- 多态
         多态同一个行为具有多个不同表现形式或形态的能力。是指一个类实例（对象）的相同方法在不同情形有不同表现形式。多态机制使具有不同内部结构的对象可以共享相同的外部接口。这意味着，虽然针对不同对象的具体操作不同，但通过一个公共的类，它们（那些操作）可以通过相同的方式予以调用。

**链接**

[9. 类 — Python 3.14.0 文档](https://docs.python.org/3/tutorial/classes.html)



------



## 作业一：面向对象计算器

- 文件名：`calculator.py`
- 要求：
  - 使用 `Calculator` 类并在 `__init__` 中设置状态（例如：历史记录列表、默认精度）。
  - 提供至少 `add, sub, mul, div, pow, history` 方法。
  - `div` 遇零要抛出自定义异常并在调用处捕获。
- 提交方式：
- 评分：功能完整 50 / 测试覆盖 30 / 代码风格 20



---

## 作业二：智能助手API调用

- 文件名：`bot.py`
- 要求：
  - 使用 `bot` 类并在 `__init__` 中设置状态。
  - 提供至少 方法。
- 提交方式：
- 评分：功能完整 50 / 测试覆盖 30 / 代码风格 20



------

## 附1：专有名词与概念速查

### LLM（Large Language Model）

大规模语言模型，基于 Transformer 架构训练，用来生成或理解文本。常见用途：写作、代码生成、对话。

### Transformer / Attention

Transformer 是一种网络结构，核心是注意力机制（attention），能让模型关注输入中最相关部分。Transformer 使大规模并行训练成为可能。

### Token

模型处理文本的最小单位。英文常见经验：1 token ≈ 4 个字符或 0.75 个单词（粗略）。中文的 token 划分不同于英文，通常更短一些。计费与上下文长度以 token 为单位。

### Prompt Engineering（提示词工程）

让模型给出更好输出的技巧与策略：明确角色、输出格式、示例、约束、分步指令、零/少/多样本学习。

### System / User / Assistant 消息

在多轮对话中，用来引导模型的三种消息类型。system 用于设置整体行为，user 提问，assistant 是模型回应。

### Temperature / top_p

控制生成多样性的参数。Temperature 越高输出越随机；top_p 控制采样的概率分布截断。

### Max_tokens / Stop sequences

max_tokens 限制生成长度；stop sequences 指定模型遇到某些字符串就停止生成。

### API（Application Programming Interface）

程序调用服务的接口（HTTP/JSON）。典型步骤：HTTP 请求（带 API Key）→ 服务返回 JSON。

### Rate limit / Quota

API 的调用速率限制和总调用额度，超过会被拒绝或计费。常见要理解每秒 QPS、并发限制。

### RAG（Retrieval-Augmented Generation）

检索增强生成：先检索相关文档，再把检索到的文档与 prompt 一起送入模型以生成更准确的答案。

### Fine-tuning / LoRA / PEFT

在特定小语料上继续训练模型以适配任务（全量微调或参数高效微调如 LoRA/PEFT）。

### RLHF（Reinforcement Learning from Human Feedback）

通过人类反馈训练模型，使生成结果更符合人类偏好。

### Hallucination（幻觉）

模型生成与事实不符的信息。应通过检索、事实核验或限制模型发言来控制。

### GPOA

模型生成与事实不符的信息。应通过检索、事实核验或限制模型发言来控制。



------

## 附2：Prompt 模板与示例

1. **代码修复（少样例）**

````
角色：你是一个资深 Python 开发者。
任务：请帮我找出下面函数的 bug 并修复，同时给出简短解释（两句以内）。
代码：
```python
def average(nums):
    return sum(nums)/len(nums)
```
要求：返回修复后的代码块并指出可能的异常情况。
````

2. **生成单元测试**  

```
角色：你是测试工程师。
任务：为下面函数生成 pytest 测试代码，包含正常用例与边界用例。
函数：<插入函数代码>
要求：3 个测试用例，使用 assert。
```

3. **文档生成**  

```
角色：技术文档撰写者。
任务：把下面的 README 转化为一段不超过 150 字的项目简介，并给出 3 点使用方法。
```



---

## 附3：如何避免常见错误
- **不要盲信 AI**：所有 AI 提供的代码/结论都要写单元测试或手动验证。  
- **控制上下文成本**：频繁发送长历史会增加 token 消耗。把不必要的历史截掉或只发必要片段。  
- **敏感信息不上云**：API Key、隐私数据不要在 prompt 里明文提交。  
- **分步验收**：项目按里程碑验收，每一阶段必须可运行可复现再进入下一步。



## 附4：如何避免常见错误

pip install requires



## 附5：换源

### 1、配置与更换镜像源

### 1.1、为什么要配置镜像源

​	由于Python在下载包时，容易出现超时等问题，主要是因为Python库的服务器都在国外，国内下载库的速度会很慢，所以需要配置国内镜像源来加快下载速度

- 官方镜像源（国外）：

  ```
  https://pypi.python.org/simple
  ```

- 国内常用镜像源

  ```
  清华：https://pypi.tuna.tsinghua.edu.cn/simple
  豆瓣：http://pypi.douban.com/simple
  阿里云：http://mirrors.aliyun.com/pypi/simple
  中国科技大学：https://pypi.mirrors.ustc.edu.cn/simple
  华中理工大学：http://pypi.hustunique.com
  山东理工大学：http://pypi.sdutlinux.org
  ```

### 1.2、单次使用镜像源下载第三方库

```
pip install  <第三方库名> -i <镜像源地址>
```

例如

```
pip install numpy -i https://pypi.tuna.tsinghua.edu.cn/simple
```



### 1.3、全局镜像源配置

目前国内使用最广泛的是清华的镜像源

全局镜像源配置，在终端依次执行如下命令：

```
pip install --upgrade pip
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```



###  1.4、安装库

在Windows PowerShell命令行执行安装第三方库的命令：

```
pip install <第三方库名>
```

例如安装NumPy：

```
pip install numpy
```

PS：补充其他常用命令：

```
# 1）升级库
pip install --upgrade <第三方库名>

# 2）卸载库
pip uninstall <第三方库名>

# 3）安装指定版本的库
pip install <第三方库名>==<版本号>
```

## 附5：相关链接

https://roadmap.sh/
