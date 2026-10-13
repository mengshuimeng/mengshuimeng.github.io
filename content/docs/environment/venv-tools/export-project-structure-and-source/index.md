---
title: "导出项目目录结构与源码文本"
date: 2026-05-05
authors:
  - "萌睡梦"
tags:
  - "开发工具"
  - "项目整理"
---

## 1. structure.txt

##### **1. 将目录结构保存到文件**

如果你想把当前目录的结构保存到 `structure.txt` 文件中，请使用输出重定向符号 `>`：

bash

```text
tree > structure.txt
```

##### **2. 显示文件的完整路径**

如果你想显示每个文件的完整路径，并保存到文件，请使用 `-f` 参数：

bash

```text
tree -f > structure.txt
```

##### **3. 显示所有文件（包括隐藏文件）**

如果你想显示所有文件（包括以 `.` 开头的隐藏文件），请使用 `-a` 参数：

bash

```text
tree -a > structure.txt
```

执行以上任一命令后，你就可以在 `structure.txt` 文件中看到生成的目录树结构了。

## 2 msg_files_content.txt

我想要看到/home/jj/projects/tmp/Rc-Vision/ros2_ws/src/rc_interfaces/msg下的所有msg文件名和对应的内容，导出到一个txt里面

### **方法二：显示文件名和内容**

如果你想同时看到文件名和对应的内容，可以使用：

bash

```text
for file in /home/jj/projects/tmp/Rc-Vision/ros2_ws/src/rc_interfaces/msg/*.msg; do
    echo "=== $(basename $file) ===" >> msg_files_content.txt
    cat "$file" >> msg_files_content.txt
    echo "" >> msg_files_content.txt
done
```

## 3 src_all_files_export_no_realsense.txt

我想要看到/home/jj/projects/tmp/Rc-Vision/ros2_ws/src下的所有文件名和对应的内容，导出到一个txt里面，我刚刚生成的文件要排除这个文件夹./realsense-ros

```bash
cd /home/jj/projects/tmp/Rc-Vision/ros2_ws/src

# 定义输出文件路径（使用 $HOME 避免报错）
output_file="$HOME/src_all_files_export_no_realsense.txt"

echo "文件导出时间: $(date)" > "$output_file"
echo "========================================" >> "$output_file"

# 查找并导出所有文本文件
# 修改点：增加了 -not -path "./realsense-ros/*" 来排除该文件夹
find . -type f \
    -not -path "./realsense-ros/*" \
    -not -path "*/\.*" \
    -not -name "*.pyc" \
    -not -name "*.so" \
    | sort | while read filepath; do

    # 尝试判断文件类型，只处理文本文件
    if file "$filepath" | grep -q "text"; then
        echo -e "\n\n>>> 文件路径: $filepath <<<\n----------------------------------------" >> "$output_file"
        cat "$filepath" >> "$output_file"
    fi
done

echo -e "\n\n========================================" >> "$output_file"
echo "导出完成！文件已保存在: $output_file"
```

## 4 scripts_content_export.txt

单独一个txt，还有/home/jj/projects/tmp/Rc-Vision/scripts这个目录下的内容 忽略/home/jj/projects/tmp/Rc-Vision/scripts/__pycache__

```bash
cd /home/jj/projects/tmp/Rc-Vision/scripts

# 定义输出文件路径
output_file="$HOME/scripts_content_export.txt"

echo "文件导出时间: $(date)" > "$output_file"
echo "========================================" >> "$output_file"

# 查找并导出
# -not -path "*/__pycache__/*" 用于排除缓存文件夹
find . -type f \
    -not -path "*/__pycache__/*" \
    -not -name "*.pyc" \
    | sort | while read filepath; do

    # 只处理文本文件
    if file "$filepath" | grep -q "text"; then
        echo -e "\n\n>>> 文件路径: $filepath <<<\n----------------------------------------" >> "$output_file"
        cat "$filepath" >> "$output_file"
    fi
done

echo -e "\n\n========================================" >> "$output_file"
echo "导出完成！文件已保存在: $output_file"
```

## 5 docker_content_export.txt

```bash
cd /home/jj/projects/tmp/Rc-Vision/docker

# 定义输出文件路径
output_file="$HOME/docker_content_export.txt"

echo "文件导出时间: $(date)" > "$output_file"
echo "========================================" >> "$output_file"

# 查找并导出所有文本文件
find . -type f \
    -not -path "*/\.*" \
    -not -name "*.pyc" \
    -not -name "*.so" \
    | sort | while read filepath; do

    # 只处理文本文件
    if file "$filepath" | grep -q "text"; then
        echo -e "\n\n>>> 文件路径: $filepath <<<\n----------------------------------------" >> "$output_file"
        cat "$filepath" >> "$output_file"
    fi
done

echo -e "\n\n========================================" >> "$output_file"
echo "导出完成！文件已保存在: $output_file"
```

## 6 configs_content_export.txt

```bash
cd /home/jj/projects/tmp/Rc-Vision/configs

# 定义输出文件路径
output_file="$HOME/configs_content_export.txt"

echo "文件导出时间: $(date)" > "$output_file"
echo "========================================" >> "$output_file"

# 查找并导出所有文本文件
find . -type f \
    -not -path "*/\.*" \
    -not -name "*.pyc" \
    -not -name "*.so" \
    | sort | while read filepath; do

    # 只处理文本文件
    if file "$filepath" | grep -q "text"; then
        echo -e "\n\n>>> 文件路径: $filepath <<<\n----------------------------------------" >> "$output_file"
        cat "$filepath" >> "$output_file"
    fi
done

echo -e "\n\n========================================" >> "$output_file"
echo "导出完成！文件已保存在: $output_file"
```
