# 设置全局镜像源（推荐方法）



## 推荐方法：使用`pip config`命令（最简单有效）

这是最现代、最推荐的方法，无需手动创建文件和文件夹，直接用命令修改配置：

```
# 设置默认镜像源（使用清华源）
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 添加信任主机（避免SSL验证问题）
pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn
```

## 验证配置是否生效

```
pip config list
```

应该显示类似以下内容：

```
global.index-url = 'https://pypi.tuna.tsinghua.edu.cn/simple'
global.trusted-host = 'pypi.tuna.tsinghua.edu.cn'
```





## 其他常用镜像源设置

如果您想使用其他镜像源，可以这样设置：

### 阿里云源

```
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/
pip config set global.trusted-host mirrors.aliyun.com
```

### 豆瓣源

```
pip config set global.index-url https://pypi.douban.com/simple/
pip config set global.trusted-host pypi.douban.com
```

### 中国科学技术大学源

```
pip config set global.index-url https://pypi.mirrors.ustc.edu.cn/simple/
pip config set global.trusted-host pypi.mirrors.ustc.edu.cn
```