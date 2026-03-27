---
title: 即梦 API 需求整理
description: 即梦 API 的调用需求与封装要求记录
slug: jimeng-api-notes
aliases:
  - /docs/fundamentals/api/即梦api/
---

请你帮我用这个即梦api写一段python代码。

要求

1. 输入两张图片路径，人的图像路径1.jpg，衣服的路径2.jpg
2. 将两张图片传入api接受返回的图片
3. 并将返回的图片保存在指定目录
4. 要有良好的封装性，支持函数调用。
5. 利用python实现

```
接口简介
图片换装：基于用户输入的衣服图片，更换到指定的模特图上。即输入模特图A + 服装图B，输出A穿着指定服装B的照片
限制条件

名称

内容

输入图要求

图片格式：JPG(JPEG), PNG, JFIF 等常见格式, 建议使用JPG格式
图片要求：小于5 MB，小于4096*4096
建议使用人物主体清晰的模特图与服装主体清晰的服装图，否则会导致出图效果不佳

请求说明

名称

内容

接口地址

https://visual.volcengineapi.com

请求方式

POST

Content-Type

application/json

提交任务
提交任务请求参数
Header参数
注意
本服务固定值：Region为cn-north-1，Service为cv
主要用于鉴权，详见 公共参数 - 签名参数 - 在Header中的场景部分
Query参数
拼接到url后的参数，示例：https://visual.volcengineapi.com?Action=CVSubmitTask&Version=2022-08-31

参数

可选/必选

类型

说明

Action

必选

String

接口名，取值：CVSubmitTask

Version

必选

String

版本号，取值：2022-08-31

Body参数
注意
业务请求参数，放到request.body中，MIME-Type为application/json

名称

类型

必选

描述

备注

req_key

String

是

服务标识
取固定值: dressing_diffusionV2

model

Model

否

模特配置
当以base64形式传入模特图时，可不传该参数

garment

Garment

是

服装配置

inference_config

InferenceConfig

否

推理配置

req_image_store_type

int

否

模特图与服装图传入方式：
0：图片通过binary_data_base64参数传入，格式为：["模特图base64字符串", "服装图一base64字符串", "服装图二base64字符串"]。若为多件服装图，服装图顺序和 garment.data 顺序一致。
1：图片通过model和garment中的url参数传入
默认值：1

binary_data_base64

Array of string

否

以base64形式传入模特图与服装图
如需使用该参数，请先将req_image_store_type设置为0。
当以base64形式传入模特图时，model参数可不传，但garment.data中的type参数仍需传入。

Model
模特配置相关参数

名称

必选

类型

描述

备注

url

否

String

模特图URL

protect_mask_url

否

String

模特保护区域图URL

输入格式：PNG格式，保护区域为255，非保护区域为0
上传时需要同步修改keep_head/keep_hand/keep_foot参数
若同时上传protect_mask_url和keep_head/keep_hand/keep_foot字段，则取并集

Garment
服装配置相关参数

名称

必选

类型

描述

备注

data

是

Array of Data

服装图详细信息

当前最多仅支持配置2件服装，可以是上衣和下衣

Data
服装图相关参数

名称

必选

类型

描述

备注

url

否

String

服装图URL

type

是

String

服装图的分类，取值如下：
上衣："upper"
下衣："bottom"
上衣+下衣："full"
默认值："full"

InferenceConfig
推理配置相关参数

名称

必选

类型

描述

备注

do_sr

否

bool

是否对结果进行超分处理
默认值：false

seed

否

int

随机种子参数，默认为-1，表示系统随机生成seed
默认值：-1

keep_head

否

bool

是否保持模特原图的头（包括发型）
默认值：true

keep_hand

否

bool

是否保持模特原图的手
默认值：false

keep_foot

否

bool

是否保持模特原图的足
默认值：false

num_steps

否

int

模型推理步数，和算法效果、处理时间相关，使用非默认值时可能会影响性能
默认值：16
取值范围： [8, 50]

keep_upper

否

bool

是否保持模特原图的上装
默认值：false

keep_lower

否

bool

是否保持模特原图的下装
默认值：false

tight_mask

否

String

模特图遮挡区域范围
默认值："loose"
支持类型：["tight", "loose", "bbox"]
取值说明：
  "tight": 上窄下窄
  "loose": 上窄下宽（默认）
  "bbox": 上宽下宽
默认值："loose"

p_bbox_iou_ratio

否

float

当画面有多个人时，每个人的bbox与主体相交的比例
默认值：0.3
取值范围：[0, 1.0]

p_bbox_expand_ratio

否

float

bbox在inference时扩大的比例
默认值：1.1
取值范围：[1.0, 1.5]

max_process_side_length

否

int

当输入图像时，最大的边长若超过该数值，会先resize到图像到该最大边长
默认值：1920
取值范围：[1080, 4096]

提交任务返回参数
通用返回参数
请参考通用返回字段及错误码
业务返回参数
重点关注data中以下字段，其他字段为公共返回(可忽略或不做解析)

字段

类型

说明

task_id

string

任务ID，用于查询结果

提交任务请求&返回完整示例
请求示例：
方式一：使用url参数传入模特图和服装图

JSON
复制
{
    "req_key": "dressing_diffusionV2",
    "model": {
        "url": "https://xxx"
    },
    "garment": {
        "data": [
            {
                "type": "upper",
                "url": "https://xxx"
            },
            {
                "type": "bottom",
                "url": "https://xxx"
            }
        ]
    }
}

方式二：使用binary_data_base64参数传入模特图和服装图

JSON
复制
{
    "req_key": "dressing_diffusionV2",
    "binary_data_base64": ["模特图base64字符串", "服装图一base64字符串", "服装图二base64字符串"],
    "req_image_store_type": 0,
    "garment": {
        "data": [
            {
                "type": "upper"
            },
            {
                "type": "bottom"
            }
        ]
    }
}

返回示例：

JSON
复制
{
    "code": 10000, //状态码，判断状态，code!=10000的情况下，不会返回task_id
    "data": {
        "task_id": "7392616336519610409" //任务ID，查询接口使用
    },
    "message": "Success",
    "request_id": "20240720103939AF0029465CF6A74E51EC", //排查错误的关键信息
    "time_elapsed": "104.852309ms" //链路耗时
}

查询任务
查询任务请求参数
Header参数
注意
本服务固定值：Region为cn-north-1，Service为cv
主要用于鉴权，详见 公共参数 - 签名参数 - 在Header中的场景部分
Query参数
拼接到url后的参数，示例：https://visual.volcengineapi.com?Action=CVGetResult&Version=2022-08-31

参数

可选/必选

类型

说明

Action

必选

String

接口名，固定值：CVGetResult

Version

必选

String

版本号，固定值：2022-08-31

Body参数
注意
业务请求参数，放到request.body中，MIME-Type为application/json

参数

可选/必选

类型

说明

示例

req_key

必选

String

服务标识
取固定值: dressing_diffusionV2

task_id

必选

String

任务ID，此字段的取值为提交任务接口的返回

req_json

可选

JSON String

json序列化后的字符串
目前支持水印配置和是否以图片链接形式返回，可在返回结果中添加

"{\"logo_info\":{\"add_logo\":true,\"position\":0,\"language\":0,\"opacity\":0.3,\"logo_text_content\":\"这里是明水印内容\"},\"return_url\":true}"

ReqJson(序列化后的结果再赋值给req_json)
配置信息

参数

可选/必选

类型

说明

return_url

可选

bool

输出是否返回图片链接 （链接有效期为24小时）

logo_info

可选

LogoInfo

水印信息

aigc_meta

可选

AIGCMeta

隐式标识

隐式标识验证方式：
查看【png】或【mp4】格式，人工智能生成合成内容表示服务平台（后续预计增加jpg）
https://www.gcmark.com/web/index.html#/mark/check/image
查看【jpg】格式，使用app11 segment查看aigc元数据内容
如 https://cyber.meme.tips/jpdump/#

LogoInfo
水印相关信息

名称

类型

必选

描述

add_logo

Boolean

否

是否添加水印。True为添加，False不添加。默认不添加

position

Int

否

水印的位置，取值如下：
0-右下角
1-左下角
2-左上角
3-右上角
默认0

language

Int

否

水印的语言，取值如下：
0-中文（AI生成）
1-英文（Generated by AI）
默认0

opacity

Float

否

水印的不透明度，取值范围0-1，1表示完全不透明，默认1

logo_text_content

String

否

明水印自定义内容

AIGCMeta
隐式标识，依据《人工智能生成合成内容标识办法》&《网络安全技术人工智能生成合成内容标识方法》

名称

类型

可选/必选

描述

content_producer

string

可选

内容生成服务ID

producer_id

string

必选

内容生成服务商给此图片数据的唯一ID

content_propagator

string

可选

内容传播服务商ID

propagate_id

string

可选

传播服务商给此图片数据的唯一ID

查询任务返回参数
通用返回参数
请参考通用返回字段及错误码
业务返回参数
说明
重点关注data中以下字段，其他字段为公共返回(可忽略或不做解析)

字段

类型

说明

binary_data_base64

Array of string

返回图片的base64数组

image_urls

Array of string

返回图片的url数组（有效期为 24 小时）
输出图片格式为png格式

resp_data

String

算法返回的一些信息，可忽略，是json序列化字符串

status

String

in_queue：任务已提交
generating：任务已被消费，处理中
done：处理完成，成功或者失败，可根据外层code&message进行判断
not_found：任务未找到，可能原因是无此任务或任务已过期(12小时)
expired：任务已过期，请尝试重新提交任务请求

查询任务请求&返回完整示例
请求示例：

JSON
复制
{
    "req_key": "dressing_diffusionV2",
    "task_id": "<任务提交接口返回task_id>",
    "req_json": "{\"logo_info\":{\"add_logo\":false,\"position\":0,\"language\":0,\"opacity\":1,\"logo_text_content\":\"这里是明水印内容\"},\"return_url\":true,\"aigc_meta\":{\"content_producer\":\"xxx\",\"producer_id\":\"xxx\",\"content_propagator\":\"xxx\",\"propagate_id\":\"xxx\"}}"
    }

返回示例：

JSON
复制
{
    "code": 10000, //状态码，优先判断 code=10000, 然后再判断data.status，否则解析有可能会panic
    "data": {
        "binary_data_base64": [],
        "image_urls": [
            "https://xxx",
        ],
        "resp_data": "{\"progress\": 100, \"received_at\": 1747915233.5144498, \"processed_at\": 1747915233, \"finished_at\": 1747915311, \"binary_data_url_list\": [], \"binary_data_info_list\": [], \"code\": 0, \"message\": \"success\", \"results\": [{\"uri\": \"tos://image_tryon/temp/result/870a3566-3704-11f0-8154-024240456e81.png\", \"url\": \"https://tosv.byted.org/obj/ic-cv-digital-human-test/image_tryon/temp/result/870a3566-3704-11f0-8154-024240456e81.png\", \"inference_config\": {\"seed\": 2636286795}, \"score\": 7, \"reason\": \"The garment fits well and the model's body is displayed properly. The pose and background match the model photo. However, the texture of the sweater looks a bit unnatural.\"}, {\"uri\": \"tos://image_tryon/temp/result/8720103e-3704-11f0-8154-024240456e81.png\", \"url\": \"https://tosv.byted.org/obj/ic-cv-digital-human-test/image_tryon/temp/result/8720103e-3704-11f0-8154-024240456e81.png\", \"inference_config\": {\"seed\": 1048212177}, \"score\": 8, \"reason\": \"The garment fits well, the model's body is well - displayed, and the pose and background correspond accurately. The details of the dog and the bow are more natural compared to Image 1.\"}, {\"uri\": \"tos://image_tryon/temp/result/87389348-3704-11f0-8154-024240456e81.png\", \"url\": \"https://tosv.byted.org/obj/ic-cv-digital-human-test/image_tryon/temp/result/87389348-3704-11f0-8154-024240456e81.png\", \"inference_config\": {\"seed\": 3299657535}, \"score\": 6, \"reason\": \"The garment fits, but the position of the dog on the sweater seems slightly off compared to the original garment photo. Also, the overall look is less natural than Image 2.\"}], \"debug_info\": {\"processor\": {\"preprocess\": {\"time_cost\": 12.185985565185547}, \"inference\": {\"time_cost\": 57.61434316635132}, \"post_process\": {\"time_cost\": 7.532143831253052}}}}",
        "status": "done" //任务状态
    },
    "message": "Success",
    "status": 10000,  //无需关注，请忽略
    "request_id": "2025061718460554C9B78D23B0BAB45B2A",  //排查错误的关键信息
    "time_elapsed": "508.312154ms" //链路耗时
}

返回报错示例：

JSON
复制
{
    "code": 50413, //状态码，优先判断 code=10000, 然后再判断data.status，否则解析有可能会panic
    "data": null, //code!=10000的情况下，该字段返回为null
    "message": "Post Text Risk Not Pass", //错误信息
    "request_id": "202511281418218670D408837A9B0EB58F", //排查错误的关键信息
    "status": 50413, //无需关注，请忽略
    "time_elapsed": "36.799829ms" //链路耗时
}

错误码
通用错误码
请参考通用返回字段及错误码
业务错误码

HttpCode

错误码

错误消息

描述

200

10000

无

请求成功

400

50411

Pre Img Risk Not Pass

输入图片前审核未通过

400

50511

Post Img Risk Not Pass

输出图片后审核未通过

400

50412

Text Risk Not Pass

输入文本前审核未通过

400

50512

Post Text Risk Not Pass

输出文本后审核未通过

400

50413

Post Text Risk Not Pass

输入文本NER、IP、Blocklist等拦截

接入说明
SDK使用说明
请参考SDK使用说明
HTTP方式接入说明
请参考HTTP请求示例

```



# 使用方式

把代码放在同级目录

很好！代码已经可以正常工作了。我来给你展示几种调用方式：

即梦API图片换装工具

我已经添加了6个详细的使用示例！你可以根据需求选择：

## 📝 调用方式说明

### **方式1：简单调用（推荐）**

python

```python
def my_function():
    results = process_dressing(
        model_image_path="1.jpg",
        garment_image_path="2.jpg",
        output_dir="./output",
        access_key="YOUR_KEY",
        secret_key="YOUR_SECRET"
    )
    return results
```

### **方式2：使用类（更灵活）**

python

```python
def my_function():
    api = JiMengDressingAPI("YOUR_KEY", "YOUR_SECRET")
    task_id = api.submit_task("1.jpg", "2.jpg")
    result = api.query_result(task_id)
    paths = api.save_result_images(result, "./output")
    return paths
```

### **方式3：批量处理**

python

```python
def process_multiple():
    for model, clothes in image_pairs:
        process_dressing(model, clothes, "./output", ak, sk)
```

## 🎯 快速开始

在你的任何Python文件中：

python

```python
from change_clothes import process_dressing  # 导入函数

def my_app():
    results = process_dressing(
        "model.jpg", 
        "clothes.jpg", 
        "./results",
        "your_ak",
        "your_sk"
    )
    print(f"生成了 {len(results)} 张图片")
```

所有示例都在代码中，取消注释即可运行！



# 代码文件

`change_clothes.py`

```bash
# change_clothes.py
import base64
import json
import time
import requests
from typing import Optional, Dict, List
from pathlib import Path

try:
    from volcengine.visual.VisualService import VisualService

    USE_SDK = True
except ImportError:
    USE_SDK = False
    print("警告: 未安装volcengine SDK，将使用基础HTTP请求")
    print("建议安装: pip install volcengine")


class JiMengDressingAPI:
    """即梦图片换装API封装类"""

    def __init__(self, access_key: str, secret_key: str):
        """
        初始化API客户端

        Args:
            access_key: 火山引擎访问密钥ID
            secret_key: 火山引擎访问密钥
        """
        self.access_key = access_key
        self.secret_key = secret_key

        if USE_SDK:
            # 使用官方SDK
            self.visual_service = VisualService()
            self.visual_service.set_ak(access_key)
            self.visual_service.set_sk(secret_key)
        else:
            self.base_url = "https://visual.volcengineapi.com"
            self.region = "cn-north-1"
            self.service = "cv"

    def _encode_image_to_base64(self, image_path: str) -> str:
        """
        将图片编码为base64字符串

        Args:
            image_path: 图片文件路径

        Returns:
            base64编码的字符串
        """
        with open(image_path, 'rb') as f:
            image_data = f.read()
            base64_str = base64.b64encode(image_data).decode('utf-8')
        return base64_str

    def submit_task(
            self,
            model_image_path: str,
            garment_image_path: str,
            garment_type: str = "full",
            inference_config: Optional[Dict] = None
    ) -> str:
        """
        提交换装任务

        Args:
            model_image_path: 模特图片路径
            garment_image_path: 服装图片路径
            garment_type: 服装类型 ("upper"上衣, "bottom"下衣, "full"上衣+下衣)
            inference_config: 推理配置参数

        Returns:
            任务ID (task_id)
        """
        # 将图片转换为base64
        model_base64 = self._encode_image_to_base64(model_image_path)
        garment_base64 = self._encode_image_to_base64(garment_image_path)

        # 构建请求体
        request_body = {
            "req_key": "dressing_diffusionV2",
            "binary_data_base64": [model_base64, garment_base64],
            "req_image_store_type": 0,
            "garment": {
                "data": [
                    {
                        "type": garment_type
                    }
                ]
            }
        }

        # 添加推理配置
        if inference_config:
            request_body["inference_config"] = inference_config

        if USE_SDK:
            # 使用官方SDK
            try:
                response = self.visual_service.cv_submit_task(request_body)
                result = response
            except Exception as e:
                raise Exception(f"SDK调用失败: {str(e)}")
        else:
            # 使用基础HTTP请求（需要手动签名，此方法可能不work）
            url = f"{self.base_url}?Action=CVSubmitTask&Version=2022-08-31"
            headers = {'Content-Type': 'application/json'}

            try:
                response = requests.post(url, headers=headers, json=request_body, timeout=30)
                result = response.json()
            except Exception as e:
                raise Exception(f"HTTP请求失败: {str(e)}")

        print(f"API响应: {json.dumps(result, ensure_ascii=False, indent=2)}")

        if result.get('code') != 10000:
            error_msg = result.get('message', '未知错误')
            raise Exception(f"提交任务失败 (code: {result.get('code')}): {error_msg}")

        task_id = result['data']['task_id']
        print(f"任务提交成功，任务ID: {task_id}")
        return task_id

    def query_result(
            self,
            task_id: str,
            return_url: bool = True,
            max_retries: int = 30,
            retry_interval: int = 2
    ) -> Dict:
        """
        查询任务结果

        Args:
            task_id: 任务ID
            return_url: 是否返回图片URL
            max_retries: 最大重试次数
            retry_interval: 重试间隔（秒）

        Returns:
            包含图片数据的字典
        """
        req_json = {
            "return_url": return_url,
            "logo_info": {
                "add_logo": False
            }
        }

        request_body = {
            "req_key": "dressing_diffusionV2",
            "task_id": task_id,
            "req_json": json.dumps(req_json)
        }

        # 轮询查询结果
        for i in range(max_retries):
            if USE_SDK:
                try:
                    response = self.visual_service.cv_get_result(request_body)
                    result = response
                except Exception as e:
                    raise Exception(f"SDK查询失败: {str(e)}")
            else:
                url = f"{self.base_url}?Action=CVGetResult&Version=2022-08-31"
                headers = {'Content-Type': 'application/json'}

                try:
                    response = requests.post(url, headers=headers, json=request_body, timeout=30)
                    result = response.json()
                except Exception as e:
                    raise Exception(f"HTTP查询失败: {str(e)}")

            if result.get('code') != 10000:
                error_msg = result.get('message', '未知错误')
                raise Exception(f"查询任务失败 (code: {result.get('code')}): {error_msg}")

            status = result['data']['status']

            if status == 'done':
                print("任务处理完成")
                return result['data']
            elif status == 'not_found':
                raise Exception("任务未找到")
            elif status == 'expired':
                raise Exception("任务已过期")
            elif status in ['in_queue', 'generating']:
                print(f"任务处理中... ({status}) [{i + 1}/{max_retries}]")
                time.sleep(retry_interval)
            else:
                raise Exception(f"未知状态: {status}")

        raise Exception("查询超时")

    def save_result_images(
            self,
            result_data: Dict,
            output_dir: str = "./output"
    ) -> List[str]:
        """
        保存结果图片

        Args:
            result_data: 查询结果返回的数据
            output_dir: 输出目录

        Returns:
            保存的图片路径列表
        """
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        saved_paths = []

        # 保存base64格式的图片
        if result_data.get('binary_data_base64'):
            for idx, base64_str in enumerate(result_data['binary_data_base64']):
                image_data = base64.b64decode(base64_str)
                file_path = output_path / f"result_{idx + 1}.png"

                with open(file_path, 'wb') as f:
                    f.write(image_data)

                saved_paths.append(str(file_path))
                print(f"图片已保存: {file_path}")

        # 如果有URL，也可以下载
        if result_data.get('image_urls'):
            for idx, url in enumerate(result_data['image_urls']):
                response = requests.get(url)
                file_path = output_path / f"result_from_url_{idx + 1}.png"

                with open(file_path, 'wb') as f:
                    f.write(response.content)

                saved_paths.append(str(file_path))
                print(f"图片已保存: {file_path}")

        return saved_paths


def process_dressing(
        model_image_path: str,
        garment_image_path: str,
        output_dir: str = "./output",
        access_key: str = "YOUR_ACCESS_KEY",
        secret_key: str = "YOUR_SECRET_KEY",
        garment_type: str = "full",
        inference_config: Optional[Dict] = None
) -> List[str]:
    """
    图片换装处理函数

    Args:
        model_image_path: 模特图片路径（如: 1.jpg）
        garment_image_path: 服装图片路径（如: 2.jpg）
        output_dir: 输出目录
        access_key: 火山引擎访问密钥ID
        secret_key: 火山引擎访问密钥
        garment_type: 服装类型 ("upper", "bottom", "full")
        inference_config: 推理配置

    Returns:
        保存的图片路径列表
    """
    # 创建API客户端
    api = JiMengDressingAPI(access_key, secret_key)

    # 提交任务
    print(f"正在提交换装任务...")
    print(f"模特图片: {model_image_path}")
    print(f"服装图片: {garment_image_path}")

    task_id = api.submit_task(
        model_image_path=model_image_path,
        garment_image_path=garment_image_path,
        garment_type=garment_type,
        inference_config=inference_config
    )

    # 查询结果
    print(f"正在查询任务结果...")
    result_data = api.query_result(task_id)

    # 保存图片
    print(f"正在保存结果图片到: {output_dir}")
    saved_paths = api.save_result_images(result_data, output_dir)

    print(f"\n处理完成！共保存 {len(saved_paths)} 张图片")
    return saved_paths


# 使用示例
if __name__ == "__main__":
    # 配置你的密钥
    ACCESS_KEY = <YOUR_ACCESS_KEY>  # 替换为你的access_key
    SECRET_KEY =  <YOUR_ACCESS_KEY>  # 替换为你的secret_key

    # 调用换装函数
    try:
        result_paths = process_dressing(
            model_image_path="1.jpg",  # 模特图片
            garment_image_path="2.jpg",  # 服装图片
            output_dir="./output",  # 输出目录
            access_key=ACCESS_KEY,
            secret_key=SECRET_KEY,
            garment_type="full",  # 服装类型
            inference_config={  # 可选的推理配置
                "do_sr": False,  # 是否超分
                "keep_head": True,  # 保持头部
                "keep_hand": False,  # 保持手部
                "num_steps": 16  # 推理步数
            }
        )

        print("\n保存的图片路径:")
        for path in result_paths:
            print(f"  - {path}")

    except Exception as e:
        print(f"错误: {e}")
```


