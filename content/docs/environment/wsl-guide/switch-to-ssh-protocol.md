### **切换到 SSH 协议**

HTTPS 推送大文件经常遇到 408/504 超时，而 SSH 通常不会。

1. **检查是否已有 SSH Key**：
   在终端输入：

   powershell

   

   ```
   cat ~/.ssh/id_rsa.pub
   ```

   - 如果有输出（以 `ssh-rsa` 开头的一长串字符），请复制它。

   - 如果没有（提示文件不存在），你需要生成一个：

     powershell

     

     ```
     ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
     # 一路回车即可
     cat ~/.ssh/id_rsa.pub
     # 复制输出的内容
     ```

2. **将 SSH Key 添加到 GitHub**：

   - 登录 GitHub -> 点击右上角头像 -> **Settings**。
   - 左侧菜单选择 **SSH and GPG keys**。
   - 点击 **New SSH key**，粘贴刚才复制的内容，保存。

3. **修改远程仓库地址为 SSH**：

   powershell

   

   ```
   git remote set-url origin git@github.com:mengshuimeng/msm.git
   ```

   *(验证一下：运行 `git remote -v`，确保地址变成了 `git@github.com:...`)*

4. **再次推送**：

   powershell

   

   ```
   git push -u origin main
   ```

   *第一次使用 SSH 推送时，可能会提示 `Are you sure you want to continue connecting (yes/no/[fingerprint])?`，输入 `yes` 回车即可。*