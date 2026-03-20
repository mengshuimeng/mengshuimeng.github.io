这是我现在的代码，思路为：

1.用户提供一段视频流

2.运行`save_crops_yolo_deepsort.py`代码，实现分类保存在一个文件夹中

3.用户再上传一张待识别的图片

4.运行`find_most.py`代码，实现将用户上传的图片和文件夹中的图片进行匹配，并将`aligned_distance`符合条件的保护到输出文件夹中。

我现在想做一个UI窗口，主要是将上述操作放在可视化界面里。一个按键让用户上传视频流，另一个按键用户上传待检测的图片，然后显示输出文件夹中的一张或者所有图片。



`项目结构`

```shell
卷 Data 的文件夹 PATH 列表
卷序列号为 6E0A-EB27
D:\CODE\PYTHON\REID
│  .gitignore
│  Alignedreid_demo.py
│  demo.py
│  find_most.py
│  gen_partial_dataset.py
│  LICENCE.md
│  LICENSE
│  README.md
│  reid_gui.py
│  structure.txt
│  test_pyqt.py
│  train_alignedreid.py
│  yolov8n.pt
│  
├─.idea
│  │  .gitignore
│  │  misc.xml
│  │  modules.xml
│  │  Reid.iml
│  │  vcs.xml
│  │  workspace.xml
│  │  
│  └─inspectionProfiles
│          profiles_settings.xml
│          Project_Default.xml
│          
├─aligned
│  │  HorizontalMaxPool2D.py
│  │  local_dist.py
│  │  __init__.py
│  │  
│  └─__pycache__
│          HorizontalMaxPool2D.cpython-311.pyc
│          __init__.cpython-311.pyc
│          
├─data
│  └─market1501
│              
├─imgs
│      Figure_0.png
│      Figure_1.png
│      
├─log
│  └─market1501
│      └─alignedreid
│              checkpoint_ep300.pth.tar
│              
├─models
│  │  DenseNet.py
│  │  InceptionV4.py
│  │  ResNet.py
│  │  ShuffleNet.py
│  │  __init__.py
│  │  
│  └─__pycache__
│          DenseNet.cpython-311.pyc
│          InceptionV4.cpython-311.pyc
│          ResNet.cpython-311.pyc
│          ResNet.cpython-36.pyc
│          ShuffleNet.cpython-311.pyc
│          __init__.cpython-311.pyc
│          __init__.cpython-36.pyc
│          
├─output
│  └─matched
├─output_similar_images
│  └─0929
├─util
│  │  dataset_loader.py
│  │  data_manager.py
│  │  data_manager.pyc
│  │  distance.py
│  │  eval_metrics.py
│  │  FeatureExtractor.py
│  │  losses.py
│  │  losses.pyc
│  │  optimizers.py
│  │  re_ranking.py
│  │  samplers.py
│  │  transforms.py
│  │  utils.py
│  │  yolov8n.pt
│  │  __init__.py
│  │  __init__.pyc
│  │  
│  └─__pycache__
│          FeatureExtractor.cpython-311.pyc
│          utils.cpython-311.pyc
│          __init__.cpython-311.pyc
│          
├─yolov8-deepsort-tracking
│  │  .gitignore
│  │  app.py
│  │  demo.png
│  │  main.py
│  │  README.md
│  │  requirements.txt
│  │  save_crops_yolo_deepsort.py
│  │  test.mp4
│  │  VID20250906201700(3).mp4
│  │  webui.png
│  │  yolov8n.pt
│  │  
│  ├─deep_sort
│  │  ├─configs
│  │  │      deep_sort.yaml
│  │  │      
│  │  ├─deep_sort
│  │  │  │  deep_sort.py
│  │  │  │  README.md
│  │  │  │  __init__.py
│  │  │  │  
│  │  │  ├─deep
│  │  │  │  │  evaluate.py
│  │  │  │  │  feature_extractor.py
│  │  │  │  │  model.py
│  │  │  │  │  original_model.py
│  │  │  │  │  prepare_car.py
│  │  │  │  │  prepare_person.py
│  │  │  │  │  test.py
│  │  │  │  │  train.jpg
│  │  │  │  │  train.py
│  │  │  │  │  __init__.py
│  │  │  │  │  
│  │  │  │  ├─checkpoint
│  │  │  │  │      ckpt.t7
│  │  │  │  │      
│  │  │  │  └─__pycache__
│  │  │  │          feature_extractor.cpython-311.pyc
│  │  │  │          model.cpython-311.pyc
│  │  │  │          __init__.cpython-311.pyc
│  │  │  │          
│  │  │  ├─sort
│  │  │  │  │  detection.py
│  │  │  │  │  iou_matching.py
│  │  │  │  │  kalman_filter.py
│  │  │  │  │  linear_assignment.py
│  │  │  │  │  nn_matching.py
│  │  │  │  │  preprocessing.py
│  │  │  │  │  track.py
│  │  │  │  │  tracker.py
│  │  │  │  │  __init__.py
│  │  │  │  │  
│  │  │  │  └─__pycache__
│  │  │  │          detection.cpython-311.pyc
│  │  │  │          iou_matching.cpython-311.pyc
│  │  │  │          kalman_filter.cpython-311.pyc
│  │  │  │          linear_assignment.cpython-311.pyc
│  │  │  │          nn_matching.cpython-311.pyc
│  │  │  │          preprocessing.cpython-311.pyc
│  │  │  │          track.cpython-311.pyc
│  │  │  │          tracker.cpython-311.pyc
│  │  │  │          __init__.cpython-311.pyc
│  │  │  │          
│  │  │  └─__pycache__
│  │  │          deep_sort.cpython-311.pyc
│  │  │          __init__.cpython-311.pyc
│  │  │          
│  │  └─utils
│  │          asserts.py
│  │          draw.py
│  │          evaluation.py
│  │          io.py
│  │          json_logger.py
│  │          log.py
│  │          parser.py
│  │          tools.py
│  │          __init__.py
│  │          
│  └─output
└─__pycache__
        find_most.cpython-311.pyc
```



`reid_gui.py`

```python
# reid_gui.py
"""
桌面 GUI：用于上传视频、上传 query 图片、运行检测/跟踪并展示裁剪结果与匹配结果。
依赖：PyQt5, Pillow
运行：python reid_gui.py
"""
import sys
import os
import subprocess
import threading
from pathlib import Path
from functools import partial

from PyQt5.QtWidgets import (
    QApplication, QWidget, QLabel, QPushButton, QFileDialog, QVBoxLayout, QHBoxLayout,
    QLineEdit, QTextEdit, QListWidget, QListWidgetItem, QScrollArea, QGridLayout,
    QMessageBox, QInputDialog
)
from PyQt5.QtGui import QPixmap, QImage
from PyQt5.QtCore import Qt, QSize

from PIL import Image

# ---------- 配置（默认路径、脚本名） ----------
SAVE_CROPS_SCRIPT = "yolov8-deepsort-tracking/save_crops_yolo_deepsort.py"
FIND_MOST_SCRIPT = "find_most.py"

# 当使用 subprocess 调用脚本时的 python 可执行路径（可改）
PYTHON_BIN = sys.executable

# ---------- GUI 主类 ----------
class ReidGUI(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("ReID 管线 GUI")
        self.resize(1100, 700)

        # 状态 / 参数
        self.video_path = ""
        self.query_image_path = ""
        self.output_root = Path.cwd() / "output"  # 默认输出根目录（save_crops 脚本输出）
        self.cam_id = 1
        self.seq_id = 1

        # UI 组件
        self.btn_select_video = QPushButton("上传视频（Select Video）")
        self.lbl_video = QLineEdit()
        self.lbl_video.setReadOnly(True)

        self.btn_select_query = QPushButton("上传待识别图片（Select Query Image）")
        self.lbl_query = QLineEdit()
        self.lbl_query.setReadOnly(True)

        self.btn_run_detection = QPushButton("运行检测并保存裁剪（Run Detection）")
        self.btn_run_matching = QPushButton("运行匹配（Run Matching）")

        self.btn_open_output_folder = QPushButton("打开输出文件夹")
        self.btn_refresh_thumbs = QPushButton("刷新输出缩略图")

        self.log_text = QTextEdit()
        self.log_text.setReadOnly(True)

        self.thumb_area = QScrollArea()
        self.thumb_widget = QWidget()
        self.thumb_layout = QGridLayout()
        self.thumb_widget.setLayout(self.thumb_layout)
        self.thumb_area.setWidgetResizable(True)
        self.thumb_area.setWidget(self.thumb_widget)

        # 摄像机/片段输入
        self.cam_input = QLineEdit(str(self.cam_id))
        self.seq_input = QLineEdit(str(self.seq_id))

        # 布局
        self._build_layout()
        self._connect_signals()

        self.log("GUI ready. Put scripts in same folder as this GUI or ensure importability.")

    def _build_layout(self):
        row1 = QHBoxLayout()
        row1.addWidget(self.btn_select_video)
        row1.addWidget(self.lbl_video)
        row1.addWidget(QLabel("Camera ID"))
        row1.addWidget(self.cam_input)
        row1.addWidget(QLabel("Sequence ID"))
        row1.addWidget(self.seq_input)

        row2 = QHBoxLayout()
        row2.addWidget(self.btn_select_query)
        row2.addWidget(self.lbl_query)
        row2.addWidget(self.btn_run_detection)
        row2.addWidget(self.btn_run_matching)

        row3 = QHBoxLayout()
        row3.addWidget(self.btn_open_output_folder)
        row3.addWidget(self.btn_refresh_thumbs)

        left_layout = QVBoxLayout()
        left_layout.addLayout(row1)
        left_layout.addLayout(row2)
        left_layout.addLayout(row3)
        left_layout.addWidget(QLabel("日志 / 进度 Log"))
        left_layout.addWidget(self.log_text)

        main_layout = QHBoxLayout()
        main_layout.addLayout(left_layout, 2)
        main_layout.addWidget(self.thumb_area, 3)

        self.setLayout(main_layout)

    def _connect_signals(self):
        self.btn_select_video.clicked.connect(self.select_video)
        self.btn_select_query.clicked.connect(self.select_query)
        self.btn_run_detection.clicked.connect(self.run_detection_clicked)
        self.btn_run_matching.clicked.connect(self.run_matching_clicked)
        self.btn_open_output_folder.clicked.connect(self.open_output_folder)
        self.btn_refresh_thumbs.clicked.connect(self.refresh_thumbnails)

    # ---------- 日志 ----------
    def log(self, text):
        self.log_text.append(text)
        print(text)

    # ---------- 交互动作 ----------
    def select_video(self):
        fp, _ = QFileDialog.getOpenFileName(self, "选择视频文件", str(Path.cwd()), "Video Files (*.mp4 *.avi *.mov *.mkv);;All Files (*)")
        if fp:
            self.video_path = fp
            self.lbl_video.setText(fp)
            self.log(f"selected video: {fp}")

    def select_query(self):
        fp, _ = QFileDialog.getOpenFileName(self, "选择查询图片", str(Path.cwd()), "Image Files (*.jpg *.png *.jpeg);;All Files (*)")
        if fp:
            self.query_image_path = fp
            self.lbl_query.setText(fp)
            self.log(f"selected query image: {fp}")

    def run_detection_clicked(self):
        if not self.video_path:
            QMessageBox.warning(self, "缺少视频", "请先选择视频后再运行检测。")
            return
        # 读取 cam/seq
        try:
            self.cam_id = int(self.cam_input.text())
            self.seq_id = int(self.seq_input.text())
        except:
            QMessageBox.warning(self, "参数错误", "Camera ID / Sequence ID 必须为整数。")
            return

        # 在单独线程运行检测（避免阻塞 UI）
        t = threading.Thread(target=self._run_detection_thread, daemon=True)
        t.start()

    def run_matching_clicked(self):
        if not self.query_image_path:
            QMessageBox.warning(self, "缺少查询图片", "请先选择查询图片再运行匹配。")
            return
        t = threading.Thread(target=self._run_matching_thread, daemon=True)
        t.start()

    def open_output_folder(self):
        out = str(self.output_root.resolve())
        if not Path(out).exists():
            QMessageBox.information(self, "提示", f"输出文件夹不存在：{out}")
            return
        if sys.platform.startswith("win"):
            os.startfile(out)
        elif sys.platform.startswith("darwin"):
            subprocess.Popen(["open", out])
        else:
            subprocess.Popen(["xdg-open", out])

    # ---------- 核心运行逻辑（尝试 import，否则 subprocess） ----------
    def _run_detection_thread(self):
        self.log("开始运行检测 (detect_and_track)...")
        # 尝试直接 import save_crops_yolo_deepsort.detect_and_track
        try:
            import importlib
            spec_mod = importlib.import_module("save_crops_yolo_deepsort")
            if hasattr(spec_mod, "detect_and_track"):
                self.log("模块导入成功：save_crops_yolo_deepsort.detect_and_track，开始调用...")
                # prepare args
                output_path = str(self.output_root)
                model_weights = getattr(spec_mod, "yolo_weights", None)  # optional
                # call function - many variants: detect_and_track(input_path, output_path, detect_class, model, tracker, camera_id, sequence_id, save_crops=True, label_map_path=None)
                # 你的脚本 defines model loading inside __main__; our GUI will try to call detect_and_track in a minimal way.
                # We'll look for a wrapper function `run_from_paths` else we try to call detect_and_track with the minimal set.
                if hasattr(spec_mod, "run_from_paths"):
                    # 如果脚本提供了方便的包装函数 run_from_paths(input_path, output_path, camera_id, sequence_id)
                    try:
                        spec_mod.run_from_paths(self.video_path, output_path, int(self.cam_id), int(self.seq_id))
                        self.log("run_from_paths 调用完成。")
                    except Exception as e:
                        self.log(f"调用 run_from_paths 出错: {e}")
                else:
                    # fallback: call detect_and_track in a subprocess because detect_and_track expects model/tracker objects
                    self.log("未找到 run_from_paths；使用 subprocess 调用脚本（推荐方式）。")
                    self._run_detection_subprocess()
            else:
                self.log("模块导入成功但未找到 detect_and_track，使用 subprocess。")
                self._run_detection_subprocess()
        except Exception as e:
            self.log(f"尝试 import save_crops 模块失败：{e}，改用 subprocess 调用脚本。")
            self._run_detection_subprocess()

        # 刷新缩略图
        self.refresh_thumbnails()

    def _run_detection_subprocess(self):
        # 以 subprocess 方式调用外部脚本，传递参数（video, output_dir, camera_id, sequence_id）
        cmd = [
            PYTHON_BIN, SAVE_CROPS_SCRIPT,
            "--input", self.video_path,
            "--output", str(self.output_root),
            "--camera_id", str(self.cam_id),
            "--sequence_id", str(self.seq_id)
        ]
        self.log("subprocess cmd: " + " ".join(cmd))
        try:
            p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
            for line in p.stdout:
                self.log(line.rstrip())
            p.wait()
            self.log(f"检测脚本退出，返回码 {p.returncode}")
        except Exception as e:
            self.log(f"运行脚本失败: {e}")

    def _run_matching_thread(self):
        self.log("开始运行匹配 (find_most)...")
        # 尝试直接 import find_most.run_find_most
        try:
            import importlib
            fm = importlib.import_module("find_most")
            if hasattr(fm, "run_find_most"):
                self.log("模块导入成功：find_most.run_find_most，开始调用...")
                # 假设 run_find_most(query_path, crops_folder, output_folder)
                crops_folder = str(self.output_root / "crops" / f"c{self.cam_id}s{self.seq_id}")
                out_folder = str(self.output_root / "matched")
                Path(out_folder).mkdir(parents=True, exist_ok=True)
                try:
                    fm.run_find_most(self.query_image_path, crops_folder, out_folder)
                    self.log("find_most.run_find_most 执行完成。")
                except Exception as e:
                    self.log(f"调用 run_find_most 出错: {e}")
            else:
                self.log("未找到 run_find_most，使用 subprocess 调用脚本。")
                self._run_matching_subprocess()
        except Exception as e:
            self.log(f"尝试 import find_most 模块失败：{e}，改用 subprocess 调用脚本。")
            self._run_matching_subprocess()

        # 刷新缩略图
        self.refresh_thumbnails()

    def _run_matching_subprocess(self):
        crops_folder = str(self.output_root / "crops" / f"c{self.cam_id}s{self.seq_id}")
        out_folder = str(self.output_root / "matched")
        Path(out_folder).mkdir(parents=True, exist_ok=True)
        # 调用 find_most.py，假定它接受命令行参数: --query, --crops, --out
        cmd = [
            PYTHON_BIN, FIND_MOST_SCRIPT,
            "--query", self.query_image_path,
            "--crops", crops_folder,
            "--out", out_folder
        ]
        self.log("subprocess cmd: " + " ".join(cmd))
        try:
            p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
            for line in p.stdout:
                self.log(line.rstrip())
            p.wait()
            self.log(f"匹配脚本退出，返回码 {p.returncode}")
        except Exception as e:
            self.log(f"运行匹配脚本失败: {e}")

    # ---------- 缩略图展示 ----------
    def refresh_thumbnails(self):
        # 清空布局
        for i in reversed(range(self.thumb_layout.count())):
            w = self.thumb_layout.itemAt(i).widget()
            if w:
                w.setParent(None)

        # 输出目录：默认 output/crops/c{cam} s{seq}
        crops_dir = Path(self.output_root) / "crops" / f"c{self.cam_id}s{self.seq_id}"
        if not crops_dir.exists():
            self.log(f"未找到裁剪目录: {crops_dir}")
            return

        img_paths = sorted([p for p in crops_dir.iterdir() if p.suffix.lower() in (".jpg", ".jpeg", ".png")])
        if not img_paths:
            self.log(f"裁剪目录中没有图片: {crops_dir}")
            return

        # 每行多少列
        cols = 4
        thumb_size = 200

        row = 0
        col = 0
        for p in img_paths:
            try:
                pil = Image.open(p)
                pil.thumbnail((thumb_size, thumb_size))
                data = pil.convert("RGBA").tobytes("raw", "RGBA")
                qimg = QImage(data, pil.width, pil.height, QImage.Format_RGBA8888)
                pix = QPixmap.fromImage(qimg)
                lbl = QLabel()
                lbl.setPixmap(pix)
                lbl.setScaledContents(True)
                lbl.setFixedSize(QSize(thumb_size, thumb_size))
                lbl.setToolTip(str(p.name))
                lbl.mousePressEvent = partial(self._on_thumb_click, str(p))
                self.thumb_layout.addWidget(lbl, row, col)
                col += 1
                if col >= cols:
                    col = 0
                    row += 1
            except Exception as e:
                self.log(f"加载缩略图失败 {p}: {e}")

        self.log(f"已加载 {len(img_paths)} 张缩略图。")

    def _on_thumb_click(self, img_path, event):
        # 显示大图在新窗口
        try:
            dlg = ImagePreviewDialog(img_path)
            dlg.exec_()
        except Exception as e:
            self.log(f"打开图片预览失败: {e}")

# ---------- 大图预览对话框 ----------
from PyQt5.QtWidgets import QDialog, QVBoxLayout, QPushButton
class ImagePreviewDialog(QDialog):
    def __init__(self, path):
        super().__init__()
        self.setWindowTitle(Path(path).name)
        self.resize(800, 800)
        v = QVBoxLayout()
        lbl = QLabel()
        pix = QPixmap(path)
        lbl.setPixmap(pix.scaled(self.size(), Qt.KeepAspectRatio, Qt.SmoothTransformation))
        v.addWidget(lbl)
        btn_open = QPushButton("在文件管理器中打开此文件")
        btn_open.clicked.connect(lambda: os.startfile(path) if sys.platform.startswith("win") else subprocess.Popen(["xdg-open", path]))
        v.addWidget(btn_open)
        self.setLayout(v)

# ---------- 启动 ----------
def main():
    app = QApplication(sys.argv)
    gui = ReidGUI()
    gui.show()
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()

```



`save_crops_yolo_deepsort.py`

```python
# save_crops_yolo_deepsort.py
import json
import os
from pathlib import Path
import tempfile
import numpy as np
import cv2  # opencv-python
from ultralytics import YOLO

import deep_sort.deep_sort.deep_sort as ds

def putTextWithBackground(img, text, origin, font=cv2.FONT_HERSHEY_SIMPLEX, font_scale=1, text_color=(255, 255, 255), bg_color=(0, 0, 0), thickness=1):
    """绘制带有背景的文本。"""
    (text_width, text_height), _ = cv2.getTextSize(text, font, font_scale, thickness)
    bottom_left = origin
    top_right = (origin[0] + text_width, origin[1] - text_height - 5)
    cv2.rectangle(img, bottom_left, top_right, bg_color, -1)
    text_origin = (origin[0], origin[1] - 5)
    cv2.putText(img, text, text_origin, font, font_scale, text_color, thickness, lineType=cv2.LINE_AA)

def extract_detections(results, detect_class):
    """
    从YOLOv8的results中提取检测框与置信度。
    注意：保持此函数与原来行为一致（避免改动你现在能跑通的流程）。
    返回:
      detections: numpy array (N,4)  —— 注意：格式与Tracker期望格式一致（你原本的实现可用）
      confarray: list of confidences
    """
    detections = np.empty((0, 4))
    confarray = []
    for r in results:
        for box in r.boxes:
            if box.cls[0].int() == detect_class:
                # 保持你原脚本的写法（可能返回xywh或者xyxy，视你的YOLO/DS对接而定）
                vals = box.xywh[0].int().tolist()  # 原脚本里这样写
                conf = round(box.conf[0].item(), 2)
                detections = np.vstack((detections, np.array(vals)))
                confarray.append(conf)
    return detections, confarray

def ensure_dir(path: Path):
    path.mkdir(parents=True, exist_ok=True)

def save_label_map(map_dict: dict, path: Path):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(map_dict, f, indent=2, ensure_ascii=False)

def load_label_map(path: Path):
    if path.exists():
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}

def clamp(val, lo, hi):
    return max(lo, min(val, hi))

def crop_and_save(frame, x1, y1, x2, y2, out_path: Path, filename: str):
    h, w = frame.shape[:2]
    # clamp coords
    x1c = clamp(int(round(x1)), 0, w - 1)
    y1c = clamp(int(round(y1)), 0, h - 1)
    x2c = clamp(int(round(x2)), 0, w - 1)
    y2c = clamp(int(round(y2)), 0, h - 1)

    if x2c <= x1c or y2c <= y1c:
        # 不合法 bbox，跳过保存
        return False

    crop = frame[y1c:y2c, x1c:x2c]
    cv2.imwrite(str(out_path / filename), crop)
    return True

def detect_and_track(input_path: str, output_path: str, detect_class: int, model, tracker,
                     camera_id: int = 1, sequence_id: int = 1,
                     save_crops: bool = True, label_map_path: str = None):
    """
    处理视频，检测并跟踪，同时将裁剪结果按命名规则保存：
      {person_label(4)}_c{camera}s{sequence}_{frame(6)}_{det_idx(2)}.jpg
    参数:
      camera_id, sequence_id: 摄像头与录像段编号（int），会形式化为 c1s1 嵌入文件名
      save_crops: 是否保存裁剪
      label_map_path: 可选，保存/加载 track_id -> label_no 的 JSON 文件路径，以便跨次运行保持 label 一致
    """

    input_path = Path(input_path)
    output_path = Path(output_path)
    ensure_dir(output_path)

    # crops目录放在 output_path/crops 下
    crops_root = output_path / "crops"
    ensure_dir(crops_root)

    # camera/sequence 子目录（便于管理）
    cam_seq_dir = crops_root / f"c{camera_id}s{sequence_id}"
    ensure_dir(cam_seq_dir)

    # label map: 把 tracker 的内部 ID 映射为连续的 label 编号（从1开始）
    label_map = {}
    if label_map_path:
        label_map_path = Path(label_map_path)
        if label_map_path.exists():
            label_map = load_label_map(label_map_path)
            # JSON 中的 keys 是字符串，转换回 int keys 较好，但为了简单，我们在内部使用 str(track_id)
    next_label = (max([int(v) for v in label_map.values()]) + 1) if label_map else 1

    cap = cv2.VideoCapture(str(input_path))
    if not cap.isOpened():
        print(f"Error opening video file {input_path}")
        return None

    fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
    size = (int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)), int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)))
    output_video_path = output_path / "output.avi"
    fourcc = cv2.VideoWriter_fourcc(*"XVID")
    output_video = cv2.VideoWriter(str(output_video_path), fourcc, fps, size, isColor=True)

    frame_idx = 0
    # 用于同一帧的检测计数（每帧重置）
    # label_map: track_id (string) -> label_no (int)

    while True:
        success, frame = cap.read()
        if not success:
            break
        frame_idx += 1
        det_idx_this_frame = 0  # 每帧检测框计数，从1开始

        # YOLO 预测
        results = model(frame, stream=True)

        # 提取检测框（保持原实现）
        detections, confarray = extract_detections(results, detect_class)

        # DeepSort 更新
        resultsTracker = tracker.update(detections, confarray, frame)

        # 如果 tracker 没有任何返回，仍然写入视频帧
        for trk in resultsTracker:
            # 请注意：不同的deep_sort实现返回格式不同，我们保持原始脚本对解包的兼容性
            # 期望 trk 可被解包为 (x1, y1, x2, y2, track_id)
            try:
                x1, y1, x2, y2, track_id = trk
            except Exception:
                # 如果返回的条目更长或不同，尝试取前5个元素
                x1, y1, x2, y2, track_id = trk[0], trk[1], trk[2], trk[3], trk[4]

            # 有些实现返回的是 cx,cy,w,h 而不是 x1,y1,x2,y2 —— 做个鲁棒判断
            x1_f, y1_f, x2_f, y2_f = float(x1), float(y1), float(x2), float(y2)
            w_check = x2_f - x1_f
            h_check = y2_f - y1_f
            if w_check <= 0 or h_check <= 0:
                # 视为 (cx, cy, w, h)
                cx, cy, w_box, h_box = x1_f, y1_f, x2_f, y2_f
                x1c = cx - w_box / 2.0
                y1c = cy - h_box / 2.0
                x2c = cx + w_box / 2.0
                y2c = cy + h_box / 2.0
            else:
                x1c, y1c, x2c, y2c = x1_f, y1_f, x2_f, y2_f

            # 转为整数并裁剪范围
            x1i, y1i, x2i, y2i = int(round(x1c)), int(round(y1c)), int(round(x2c)), int(round(y2c))

            # tracker 内部 ID 可能是 int 或者字符串
            track_id_str = str(int(track_id)) if isinstance(track_id, (int, np.integer, float)) or (isinstance(track_id, (np.ndarray,)) and track_id.size==1) else str(track_id)

            # 分配/获取 label 编号（连续编号）
            if track_id_str not in label_map:
                label_map[track_id_str] = next_label
                next_label += 1
            label_no = int(label_map[track_id_str])

            # 保存裁剪图片（按命名规则）
            if save_crops:
                det_idx_this_frame += 1
                # 格式化命名
                label_str = str(label_no).zfill(4)        # 0001
                camera_str = f"c{camera_id}"             # c1
                sequence_str = f"s{sequence_id}"         # s1
                frame_str = str(frame_idx).zfill(6)      # 000151
                det_str = str(det_idx_this_frame).zfill(2)  # 01
                filename = f"{label_str}_{camera_str}{sequence_str}_{frame_str}_{det_str}.jpg"
                saved = crop_and_save(frame, x1i, y1i, x2i, y2i, cam_seq_dir, filename)
                if not saved:
                    # 若裁剪失败，可记录或打印
                    print(f"[WARN] skip save invalid crop: frame {frame_idx}, track {track_id_str}, bbox {(x1i,y1i,x2i,y2i)}")

            # 绘制 bbox 和 ID（保持原来的展示）
            cv2.rectangle(frame, (x1i, y1i), (x2i, y2i), (255, 0, 255), 3)
            putTextWithBackground(frame, str(label_no).zfill(4), (max(-10, x1i), max(40, y1i)), font_scale=1.5, text_color=(255, 255, 255), bg_color=(255, 0, 255))

        # 写输出视频
        output_video.write(frame)

    output_video.release()
    cap.release()

    # 保存 label_map（如果指定了路径）
    if label_map_path:
        try:
            save_label_map(label_map, Path(label_map_path))
            print(f"label map saved to {label_map_path}")
        except Exception as e:
            print(f"failed to save label map: {e}")

    print(f'output video: {output_video_path}')
    print(f'crops saved to: {cam_seq_dir}')
    return output_video_path

if __name__ == "__main__":
    # —— 请按实际路径修改下面几项 —— #
    input_path = r"D:\code\python\Reid\yolov8-deepsort-tracking\VID20250906201700(3).mp4"
    output_path = r"D:\code\python\Reid\yolov8-deepsort-tracking\output"
    yolo_weights = "yolov8n.pt"  # 或你训练的权重
    deep_sort_ckpt = "deep_sort/deep_sort/deep/checkpoint/ckpt.t7"  # 保持你原来的路径
    camera_id = 1   # 设置为当前摄像头编号（1..6）
    sequence_id = 1 # 设置为当前录像段编号（1..N）
    label_map_json = str(Path(output_path) / "label_map_c1s1.json")  # 可选：保存track->label映射

    # 初始化模型与Tracker（与你的原始脚本相同）
    model = YOLO(yolo_weights)
    detect_class = 0  # person
    tracker = ds.DeepSort(deep_sort_ckpt)

    detect_and_track(input_path, output_path, detect_class, model, tracker,
                     camera_id=camera_id, sequence_id=sequence_id,
                     save_crops=True, label_map_path=label_map_json)
```



`find_most.py`

```python
# find_most.py
import matplotlib
matplotlib.use('TkAgg')  # 或者 'Qt5Agg'
from util.utils import *
from sklearn.preprocessing import normalize
import os
import shutil
import numpy as np
import torch
from torchvision import transforms
from IPython import embed
import models
from scipy.spatial.distance import euclidean
from util.utils import read_image, img_to_tensor  # 确保这些函数已正确导入
from util.FeatureExtractor import FeatureExtractor

# 设置输出文件夹路径
output_folder = "./output_similar_images/0929"  # 替换为您希望保存的文件夹路径
os.makedirs(output_folder, exist_ok=True)

# 固定需要查找的图像 img_path1
img_path1 = './yolov8-deepsort-tracking/output/crops/c1s1/0001_c1s1_000003_01.jpg'

# 遍历 query 文件夹中的所有图片
query_folder = './yolov8-deepsort-tracking/output/crops/c1s1'

def pool2d(tensor, type= 'max'):
    sz = tensor.size()
    if type == 'max':
        kernel_size = (int(sz[2] // 8), int(sz[3]))
        x = torch.nn.functional.max_pool2d(tensor, kernel_size=kernel_size)
    if type == 'mean':
        kernel_size = (int(sz[2] // 8), int(sz[3]))
        x = torch.nn.functional.mean_pool2d(tensor, kernel_size=kernel_size)
    x = x[0].cpu().data.numpy()
    x = np.transpose(x,(2,1,0))[0]
    return x

def main():
    os.environ['CUDA_VISIBLE_DEVICES'] = "0"
    use_gpu = torch.cuda.is_available()

    # 初始化模型
    model = models.init_model(name='resnet50', num_classes=751, loss={'softmax', 'metric'}, use_gpu=use_gpu, aligned=True)
    checkpoint = torch.load("./log/market1501/alignedreid/checkpoint_ep300.pth.tar", map_location="cpu", weights_only=False)
    model.load_state_dict(checkpoint['state_dict'])

    # 图像预处理
    img_transform = transforms.Compose([
        transforms.Resize((256, 128)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    # # 固定 img_path1
    # img_path1 = './data/market1501/query/0001_c1s1_001051_00.jpg'
    exact_list = ['7']
    myexactor = FeatureExtractor(model, exact_list)

    # 处理 img_path1 的特征（仅需一次）
    img1 = read_image(img_path1)
    img1_tensor = img_to_tensor(img1, img_transform)
    if use_gpu:
        model = model.cuda()
        img1_tensor = img1_tensor.cuda()
    model.eval()
    f1 = myexactor(img1_tensor)
    a1 = normalize(pool2d(f1[0], type='max'))  # 提取并归一化特征

    # # 遍历 query 文件夹中的所有图片
    # query_folder = './data/market1501/query'
    for img_name in os.listdir(query_folder):
        img_path2 = os.path.join(query_folder, img_name)


        # 跳过 img_path1 本身（可选）
        if img_path2 == img_path1:
            continue

        # 处理 img_path2 的特征
        img2 = read_image(img_path2)
        img2_tensor = img_to_tensor(img2, img_transform)
        if use_gpu:
            img2_tensor = img2_tensor.cuda()
        f2 = myexactor(img2_tensor)
        a2 = normalize(pool2d(f2[0], type='max'))

        # 计算对齐距离（取 8x8 距离矩阵的平均值）
        dist = np.zeros((8, 8))
        for i in range(8):
            temp_feat1 = a1[i]
            for j in range(8):
                temp_feat2 = a2[j]
                dist[i][j] = euclidean(temp_feat1, temp_feat2)
        aligned_distance = np.mean(dist)  # 使用平均距离作为判断依据

        print(f"img_path2 {img_path2}（距离: {aligned_distance:.4f}）")
        # 判断并复制符合条件的图片
        if aligned_distance < 0.8:
            output_path = os.path.join(output_folder, img_name)
            shutil.copy2(img_path2, output_path)
            print(f"已复制 {img_name}（距离: {aligned_distance:.4f}）")



if __name__ == '__main__':
    main()
```

1