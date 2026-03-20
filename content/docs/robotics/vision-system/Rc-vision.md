# 工程名统一为：**`Rc-Vision`**

目标默认按你现在这条路线设计：

- 一个 Docker 容器
- 多个 ROS2 package
- 支持后续三类任务
  1. D435i 末端抓取视觉
  2. 题目识别
  3. YOLO 图形/箱体检测

------

# 一、完整目录结构

```shell
Rc-Vision/
├── README.md
├── .gitignore
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── entrypoint.sh
├── scripts/
│   ├── init_project.sh
│   ├── build_ws.sh
│   ├── source_ws.sh
│   └── run_container.sh
├── data/
│   ├── images/
│   ├── videos/
│   ├── outputs/
│   ├── calibration/
│   └── logs/
├── models/
│   ├── yolo/
│   ├── ocr/
│   └── grasp/
├── configs/
│   ├── realsense/
│   │   └── d435i.yaml
│   ├── yolo/
│   │   └── detector.yaml
│   ├── problem/
│   │   └── ocr.yaml
│   └── system/
│       └── pipeline.yaml
├── docs/
│   ├── architecture.md
│   ├── topics.md
│   └── deployment.md
└── ros2_ws/
    ├── src/
    │   ├── rc_interfaces/
    │   │   ├── CMakeLists.txt
    │   │   ├── package.xml
    │   │   └── msg/
    │   │       ├── Detection2D.msg
    │   │       ├── Detection2DArray.msg
    │   │       ├── GraspTarget.msg
    │   │       ├── ProblemResult.msg
    │   │       ├── SceneObject.msg
    │   │       └── SceneObjectArray.msg
    │   ├── grasp_vision/
    │   │   ├── package.xml
    │   │   ├── setup.py
    │   │   ├── setup.cfg
    │   │   ├── resource/
    │   │   │   └── grasp_vision
    │   │   └── grasp_vision/
    │   │       ├── __init__.py
    │   │       ├── detector_node.py
    │   │       ├── target_selector_node.py
    │   │       ├── depth_projector_node.py
    │   │       ├── grasp_pose_node.py
    │   │       └── debug_overlay_node.py
    │   ├── problem_recognition/
    │   │   ├── package.xml
    │   │   ├── setup.py
    │   │   ├── setup.cfg
    │   │   ├── resource/
    │   │   │   └── problem_recognition
    │   │   └── problem_recognition/
    │   │       ├── __init__.py
    │   │       ├── problem_detector_node.py
    │   │       ├── ocr_node.py
    │   │       ├── expression_parser_node.py
    │   │       └── problem_debug_node.py
    │   ├── scene_detection/
    │   │   ├── package.xml
    │   │   ├── setup.py
    │   │   ├── setup.cfg
    │   │   ├── resource/
    │   │   │   └── scene_detection
    │   │   └── scene_detection/
    │   │       ├── __init__.py
    │   │       ├── scene_detector_node.py
    │   │       ├── box_classifier_node.py
    │   │       └── scene_debug_node.py
    │   ├── vision_bringup/
    │   │   ├── package.xml
    │   │   ├── setup.py
    │   │   ├── setup.cfg
    │   │   ├── resource/
    │   │   │   └── vision_bringup
    │   │   ├── launch/
    │   │   │   ├── d435i_grasp.launch.py
    │   │   │   ├── problem_only.launch.py
    │   │   │   ├── scene_only.launch.py
    │   │   │   └── full_pipeline.launch.py
    │   │   └── vision_bringup/
    │   │       └── __init__.py
    │   └── robot_bridge/
    │       ├── package.xml
    │       ├── setup.py
    │       ├── setup.cfg
    │       ├── resource/
    │       │   └── robot_bridge
    │       └── robot_bridge/
    │           ├── __init__.py
    │           ├── grasp_target_bridge_node.py
    │           ├── problem_result_bridge_node.py
    │           └── scene_result_bridge_node.py
    └── src.repos
```



```shell
ros2_ws/src/
├── rc_interfaces/         # 接口
├── grasp_vision/          # 末端抓取相关：选目标、深度投影、抓取点输出
├── problem_recognition/   # 题目识别：OCR、表达式解析、答案输出
├── scene_detection/       # YOLO图形/箱体检测：全局识别、类别输出
├── vision_bringup/        # 总 launch 和模式切换
└── robot_bridge/          # 与电控交互
```

---

# grasp_vision
识别当前末端视野中的目标物体，结合深度图计算目标 3D 坐标，并发布给机械臂/电控。
