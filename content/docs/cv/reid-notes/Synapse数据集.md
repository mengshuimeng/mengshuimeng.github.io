## 1. 数据集预处理

思路是仿照一个结构和`Synapse`相似的数据集。

如果我的数据集是这样的

```
D:/compare/US30K0817/BUSIS/
├── images/             # 原始图像 (PNG格式)
│   ├── case0001.png
│   ├── case0002.png
│   └── ...
└── labels/             # 分割标签 (PNG格式)
    ├── case0001.png
    ├── case0002.png
    └── ...
```



运行`preprocess/data_process.py`

修改三个参数

```
parser.add_argument('--src_path', type=str, default='D:/compare/US30K0817/BUSIS',
                    help='Path to the root directory containing "images" and "labels" folders')
parser.add_argument('--dst_path', type=str, default='D:/compare/0816/train_npz_BUSI2',
                    help='Output directory for processed files')
parser.add_argument('--use_normalize', action='store_true', default=True,
                    help='Normalize image pixel values to [0,1]')
```



在`dst_path`输出路径下有三个文件夹

```
D:\COMPARE\0816\TRAIN_NPZ_BUSI2
├─lists
│  └─lists_custom
├─test_vol_h5
└─train_npz
```

- `train_npz`**中输出的 `.npz` 文件是二维的**，每个文件对应一个二维切片，是`train.py`中的`root_path`参数。
- `test_vol_h5`**中验证集的 `.h5` 文件是三维的**，保存了完整的3D体积数据，没有用到。
- `lists\lists_custom`**中有 `train.txt` `test.txt` **，需要将整个`lists_custom`文件夹复制到项目文件夹`D:\compare\H-SAM-main\lists`中。



---

## 2. 调整参数并运行

```
CUDA_VISIBLE_DEVICES="0" python train.py \
  --root_path "自定义数据集/train_npz" \
  --output "./results/custom/" \
  --split "train" \
  --batch_size 8 \
  --base_lr 0.0026 \
  --img_size 512 \
  --warmup \
  --AdamW \
  --max_epochs 300 \
  --stop_epoch 300 \
  --num_classes <您的类别数> \  #二分为2
  --dataset "custom" \
  --list_dir "./lists/lists_custom" \
  --ckpt "checkpoints/sam_vit_b_01ec64.pth"
```

我是手动在`train.py`文件中修改参数的

```
parser.add_argument('--root_path', type=str,
                    default='D:/compare/0816/train_npz_BUSI2/train_npz', help='root dir for data')
parser.add_argument('--output', type=str, default='./results/custom/')
parser.add_argument('--dataset', type=str,
                    default='Synapse', help='experiment_name')
parser.add_argument('--list_dir', type=str,
                    default='./lists/lists_custom', help='list dir')
parser.add_argument('--split', type=str,
                    default='train', help='list dir')
parser.add_argument('--num_classes', type=int,
                    default=2, help='output channel of network')
parser.add_argument('--max_iterations', type=int,
                    default=30000, help='maximum epoch number to train')
parser.add_argument('--max_epochs', type=int,
                    default=30, help='maximum epoch number to train')
parser.add_argument('--stop_epoch', type=int,
                    default=30, help='maximum epoch number to train')
parser.add_argument('--batch_size', type=int,
                    default=24, help='batch_size per gpu')
parser.add_argument('--n_gpu', type=int, default=2, help='total gpu')
parser.add_argument('--deterministic', type=int, default=1,
                    help='whether use deterministic training')
parser.add_argument('--base_lr', type=float, default=0.005,
                    help='segmentation network learning rate')
parser.add_argument('--img_size', type=int,
                    default=224, help='input patch size of network input')
parser.add_argument('--seed', type=int,
                    default=2345, help='random seed')
parser.add_argument('--vit_name', type=str,
                    default='vit_b', help='select one vit model')
parser.add_argument('--ckpt', type=str, default='checkpoints/sam_vit_b_01ec64.pth',
                    help='Pretrained checkpoint')
parser.add_argument('--lora_ckpt', type=str, default=None, help='Finetuned lora checkpoint')
parser.add_argument('--rank', type=int, default=5, help='Rank for LoRA adaptation')
parser.add_argument('--warmup', action='store_true', help='If activated, warp up the learning from a lower lr to the base_lr')
parser.add_argument('--warmup_period', type=int, default=250,
                    help='Warp up iterations, only valid when warmup is activated')
parser.add_argument('--AdamW', action='store_true', help='If activated, use AdamW to finetune SAM model')
parser.add_argument('--module', type=str, default='sam_lora_image_encoder')
parser.add_argument('--dice_param', type=float, default=0.9)
```

