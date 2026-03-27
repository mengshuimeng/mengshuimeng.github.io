# 🧭 Git 使用指南

> 本文档用于帮助你完成 Git 的常见操作，包括：连接远程仓库、拉取最新代码、提交并推送修改、配置代理、使用 GitHub Token，以及处理常见问题。
>
> 适用平台：**Windows PowerShell / Linux / macOS 终端**
> 作者：姜树豪（JSH）
> 更新时间：2026-03-08

------

## 📂 目录

1. Git 代理设置
2. 连接远程仓库
3. 从远程仓库拉取最新代码
4. 提交并推送本地修改
5. GitHub Token 配置
6. 常见问题
7. 常用命令速查表

------

## 1. Git 代理设置

在国内网络环境下，访问 GitHub 可能较慢。此时可以为 Git 配置 HTTP / HTTPS 代理。

### 设置代理

如果代理地址为 `127.0.0.1`，常见端口如下：

- Clash for Windows：`7890`
- Clash Verge：`7897`

```bash
# Clash for Windows
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# Clash Verge
git config --global http.proxy http://127.0.0.1:7897
git config --global https.proxy http://127.0.0.1:7897
```

### 查看当前代理配置

```bash
git config --global --get http.proxy
git config --global --get https.proxy
```

### 取消代理

```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
```

------

## 2. 连接远程仓库

### 初始化本地仓库

```bash
cd /path/to/your/project
git init
```

### 查看或配置远程仓库

```bash
# 查看远程仓库
git remote -v

# 删除旧的远程仓库（如需）
git remote remove origin

# 添加新的远程仓库
git remote add origin https://github.com/用户名/仓库名.git
```

### 查看当前分支

```bash
git branch
```

> GitHub 新建仓库的默认分支通常为 `main`。如果你的仓库仍使用 `master`，请以实际分支名为准。([GitHub Docs](https://docs.github.com/articles/about-branches?utm_source=chatgpt.com))

### 创建并切换到新分支

例如，新建个人开发分支 `jsh`：

```bash
git checkout -b jsh
```

如果远程已存在该分支：

```bash
git fetch origin jsh
git checkout -b jsh origin/jsh
```

### 分支重命名：`master` 改为 `main`

如果本地主分支名仍为 `master`，可以重命名：

```bash
# 查看当前分支
git branch

# 将 master 重命名为 main
git branch -m master main

# 推送到远程
git push -u origin main
```

> 如果仓库默认分支需要同步修改，可以在 GitHub 仓库设置中更改默认分支。([GitHub Docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/changing-the-default-branch?utm_source=chatgpt.com))

------

## 3. 从远程仓库拉取最新代码

### 仅同步远程信息

```bash
git fetch origin
```

该命令只会更新远程分支信息，不会直接修改本地文件。

### 保留本地提交并更新代码

推荐使用：

```bash
git pull --rebase origin main
```

如果你当前使用的不是 `main`，请将其替换为实际分支名。

### 强制让本地分支与远程一致

```bash
git reset --hard origin/main
```

> ⚠️ 该操作会丢弃本地未提交的修改。执行前建议先暂存：

```bash
git stash
```

### 检查当前状态

```bash
git status
```

------

## 4. 提交并推送本地修改

这是最常用的一套 Git 工作流：

### 第一步：先拉取远程更新

```bash
git pull --rebase origin main
```

### 第二步：添加修改

```bash
git add .gitignore
git add .
```

如果只想提交某个文件：

```bash
git add core/features/url_extractor.py
```

### 第三步：提交

```bash
git commit -m "feat: update url extractor"
```

### 第四步：推送到远程仓库

```bash
git push
```

如果是第一次推送当前分支：

```bash
git push -u origin main
```

或者推送个人分支：

```bash
git push -u origin jsh
```





### **选项 B：如果你想合并远程的代码（安全，保留远程文件如 README）**

先拉取并合并，再推送：

```
# 1. 拉取远程代码并尝试合并
git pull --rebase origin main

# 2. 如果上面成功（没有冲突），再推送
git push -u origin main
```

------

## 5. GitHub Token 配置

如果你通过 HTTPS 方式访问 GitHub 仓库，推送时通常需要使用 Personal Access Token（PAT）进行身份验证。GitHub 官方建议：**优先使用 fine-grained personal access token**；classic token 仅在某些旧流程或特殊场景下使用。([GitHub Docs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-authentication-to-github?utm_source=chatgpt.com))

### 查看 GitHub 用户名

1. 登录 GitHub
2. 点击右上角头像 → **Your profile**
3. 浏览器地址栏通常形如：

```text
https://github.com/你的用户名
```

### 创建 Token

1. 打开 GitHub 的 Token 管理页面
2. 选择创建新的 Personal Access Token
3. 优先选择 **Fine-grained token**
4. 根据需要选择仓库访问范围与权限
5. 设置合适的有效期
6. 生成后立即复制保存

> Token 只会完整显示一次，丢失后通常需要重新生成。([GitHub Docs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens?utm_source=chatgpt.com))

### 推送时使用 Token

执行推送命令：

```bash
git push -u origin main
```

Git 可能会提示输入账号和凭证：

- **Username**：你的 GitHub 用户名
- **Password**：粘贴 Personal Access Token

### 避免反复输入凭证

GitHub 官方建议在 HTTPS 场景下使用 **Git Credential Manager** 或其他凭证缓存方式保存认证信息。这样后续 `pull` / `push` 时无需每次重新输入 Token。([GitHub Docs](https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git?utm_source=chatgpt.com))

------

## 6. 常见问题

### 1）推送被拒绝：远程分支有新提交

推荐先拉取再推送：

```bash
git pull --rebase origin main
git push
```

### 2）强制覆盖远程分支

仅在你确认远程内容不重要时使用：

```bash
git push --force
```

> ⚠️ 该操作可能覆盖他人的提交，风险很高。

### 3）仓库中存在大文件，推送失败

GitHub 对单个 Git 对象的大小限制为 **100MB**，单次 push 大小限制为 **2GB**。官方建议仓库尽量保持较小，理想状态低于 **1GB**，强烈建议低于 **5GB**。超出限制或过大时，建议使用 **Git LFS** 管理大文件。([GitHub Docs](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits?utm_source=chatgpt.com))

### 4）为什么每次都要输入用户名和 Token

通常是因为本地没有启用凭证缓存。可以改用 Git Credential Manager 或系统凭证管理方式。([GitHub Docs](https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git?utm_source=chatgpt.com))

------

## 7. 常用命令速查表

| 操作               | 命令                                             |
| ------------------ | ------------------------------------------------ |
| 查看当前分支       | `git branch`                                     |
| 查看远程仓库       | `git remote -v`                                  |
| 查看状态           | `git status`                                     |
| 查看提交日志       | `git log --oneline --graph --decorate`           |
| 拉取远程更新       | `git pull --rebase origin main`                  |
| 暂存全部修改       | `git add .`                                      |
| 提交修改           | `git commit -m "message"`                        |
| 推送当前分支       | `git push`                                       |
| 首次推送并绑定分支 | `git push -u origin main`                        |
| 暂存工作区         | `git stash`                                      |
| 恢复暂存           | `git stash pop`                                  |
| 删除分支           | `git branch -d branch_name`                      |
| 强制删除分支       | `git branch -D branch_name`                      |
| 克隆仓库           | `git clone https://github.com/用户名/仓库名.git` |

------

## 🧠 使用建议

> 最稳妥的 Git 操作原则是：**先拉后改，再提再推。**

推荐记忆顺序：

1. `git pull --rebase`
2. `git add`
3. `git commit`
4. `git push`





```bash
jj@Jiang:~/projects/Rc-Vision$ git init
Reinitialized existing Git repository in /home/jj/projects/Rc-Vision/.git/
jj@Jiang:~/projects/Rc-Vision$ git remote -v
origin  https://github.com/mengshuimeng/Rc-Vision.git (fetch)
origin  https://github.com/mengshuimeng/Rc-Vision.git (push)
jj@Jiang:~/projects/Rc-Vision$ git add .
jj@Jiang:~/projects/Rc-Vision$ git commit -m "first"
On branch master
nothing to commit, working tree clean
jj@Jiang:~/projects/Rc-Vision$ git push
fatal: The current branch master has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin master

jj@Jiang:~/projects/Rc-Vision$ git status
On branch master
nothing to commit, working tree clean
jj@Jiang:~/projects/Rc-Vision$ git push -u origin master
Enumerating objects: 31, done.
Counting objects: 100% (31/31), done.
Delta compression using up to 32 threads
Compressing objects: 100% (20/20), done.
Writing objects: 100% (31/31), 2.91 KiB | 994.00 KiB/s, done.
Total 31 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (2/2), done.
To https://github.com/mengshuimeng/Rc-Vision.git
 * [new branch]      master -> master
Branch 'master' set up to track remote branch 'master' from 'origin'.
jj@Jiang:~/projects/Rc-Vision$ 
```



```
# 设置编码环境，确保中文路径不乱码
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$gitignorePath = ".gitignore"
$sizeThresholdMB = 50
$sizeThresholdBytes = $sizeThresholdMB * 1MB

Write-Host "🔍 正在扫描大于 ${sizeThresholdMB}MB 的文件..." -ForegroundColor Cyan

# 获取所有大于指定大小的文件 (排除 .git 目录)
# -File 确保只获取文件，不获取文件夹
$largeFiles = Get-ChildItem -Recurse -File | 
    Where-Object { 
        $_.Length -gt $sizeThresholdBytes -and 
        $_.FullName -notlike "*\.git\*" 
    } |
    Sort-Object Length -Descending # 按大小排序，大的在前

if ($largeFiles.Count -eq 0) {
    Write-Host "✅ 未找到大于 ${sizeThresholdMB}MB 的文件。无需更新 .gitignore" -ForegroundColor Green
    return
}

Write-Host "📂 找到 $($largeFiles.Count) 个大文件：" -ForegroundColor Yellow

# 构建新的 .gitignore 内容
$newContent = @()
$newContent += "# === Auto-generated: Files larger than ${sizeThresholdMB}MB ==="
$newContent += "# Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$newContent += "# DO NOT EDIT MANUALLY (Run script again to update)"
$newContent += ""

foreach ($file in $largeFiles) {
    # 计算相对路径
    $currentDir = (Get-Location).Path
    # 处理路径分隔符，确保相对路径计算正确
    $fullPath = $file.FullName
    
    # 移除当前目录前缀，得到相对路径
    if ($fullPath.StartsWith($currentDir)) {
        $relativePath = $fullPath.Substring($currentDir.Length + 1)
    } else {
        $relativePath = $fullPath
    }
    
    # 将反斜杠 \ 替换为 Git 标准的正斜杠 /
    $relativePath = $relativePath -replace '\\', '/'
    
    $newContent += $relativePath
    
    # 显示进度 (格式：大小(MB)  路径)
    $sizeMB = [math]::Round($file.Length / 1MB, 2)
    Write-Host "  [$sizeMB MB] $relativePath" -ForegroundColor Gray
}

# 询问是否覆盖原有的大文件列表部分 (可选：如果你想保留手动添加的其他规则)
# 这里为了简单直接重写，如果你需要合并逻辑，可以改为追加模式
Write-Host "`n⚠️ 即将覆盖 $gitignorePath 文件内容..." -ForegroundColor Yellow
Write-Host "   (如果文件中有其他手动规则，请先备份！)" -ForegroundColor Yellow

# 写入文件 (强制 UTF-8 无 BOM)
$newContent | Set-Content -Path $gitignorePath -Encoding UTF8

Write-Host "------------------------------------------------" -ForegroundColor Green
Write-Host "🎉 完成！已生成 $($largeFiles.Count) 条具体路径规则。" -ForegroundColor Green
Write-Host "📄 文件已保存为: $gitignorePath (UTF-8 编码，中文正常)" -ForegroundColor Green
Write-Host "💡 提示：下次有新的大文件产生时，请重新运行此脚本更新列表。" -ForegroundColor Green
```

