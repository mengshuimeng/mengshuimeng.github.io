这个是在openmv的代码，请帮我修改为使用USB摄像头连接运行在pycharm中的py代码。

```python
import time, os, sys
import math
from media.sensor import *
from media.display import *
from media.media import *

# 自定义 hypot 函数
def hypot(x, y):
    return math.sqrt(x**2 + y**2)

# 角度计算函数
def calculate_angle(p1, p2, p3):
    a2 = (p2[0] - p3[0])**2 + (p2[1] - p3[1])** 2
    b2 = (p1[0] - p3[0])**2 + (p1[1] - p3[1])** 2
    c2 = (p1[0] - p2[0])**2 + (p1[1] - p2[1])** 2

    if a2 == 0 or c2 == 0:
        return 0
    cos_angle = (a2 + c2 - b2) / (2 * (a2**0.5) * (c2**0.5))
    cos_angle = max(-1.0, min(1.0, cos_angle))
    return math.degrees(math.acos(cos_angle))

# 点是否在多边形内（射线法）
def point_in_polygon(point, polygon):
    x, y = point
    n = len(polygon)
    inside = False
    for i in range(n):
        j = (i + 1) % n
        xi, yi = polygon[i]
        xj, yj = polygon[j]
        if ((yi > y) != (yj > y)):
            t = (y - yi) / (yj - yi) if (yj - yi) != 0 else 0
            x_intersect = xi + t * (xj - xi)
            if x < x_intersect:
                inside = not inside
    return inside

# 计算点到线段的距离
def point_to_line_distance(point, line_start, line_end):
    x, y = point
    x1, y1 = line_start
    x2, y2 = line_end

    # 线段长度的平方
    line_len_sq = (x2 - x1)**2 + (y2 - y1)**2

    # 如果线段实际上是一个点，则返回点之间的距离
    if line_len_sq == 0:
        return hypot(x - x1, y - y1)

    # 考虑线段参数化表示：0 <= t <= 1
    t = ((x - x1) * (x2 - x1) + (y - y1) * (y2 - y1)) / line_len_sq

    if t < 0:
        return hypot(x - x1, y - y1)  # 投影在起点之前
    elif t > 1:
        return hypot(x - x2, y - y2)  # 投影在终点之后
    else:
        # 投影在线段上
        proj_x = x1 + t * (x2 - x1)
        proj_y = y1 + t * (y2 - y1)
        return hypot(x - proj_x, y - proj_y)

# 判断两个矩形是否嵌套且满足最小间隔要求
def is_nested_with_min_distance(rect1, rect2, min_distance=10):
    # 检查是否嵌套
    rect1_in_rect2 = all(point_in_polygon(p, rect2) for p in rect1)
    rect2_in_rect1 = all(point_in_polygon(p, rect1) for p in rect2)

    if not (rect1_in_rect2 or rect2_in_rect1):
        return False

    # 确定内外矩形
    outer_rect = rect2 if rect1_in_rect2 else rect1
    inner_rect = rect1 if rect1_in_rect2 else rect2

    # 计算所有边之间的最小距离
    min_dist = float('inf')

    # 对于内矩形的每条边
    for i in range(4):
        inner_start = inner_rect[i]
        inner_end = inner_rect[(i+1)%4]

        # 对于外矩形的每条边
        for j in range(4):
            outer_start = outer_rect[j]
            outer_end = outer_rect[(j+1)%4]

            # 计算内矩形边的两个端点到外矩形边的距离
            d1 = point_to_line_distance(inner_start, outer_start, outer_end)
            d2 = point_to_line_distance(inner_end, outer_start, outer_end)

            # 计算外矩形边的两个端点到内矩形边的距离
            d3 = point_to_line_distance(outer_start, inner_start, inner_end)
            d4 = point_to_line_distance(outer_end, inner_start, inner_end)

            # 更新最小距离
            current_min = min(d1, d2, d3, d4)
            if current_min < min_dist:
                min_dist = current_min

    # 检查是否满足最小距离要求
    return min_dist >= min_distance

# 计算多边形的像素面积（鞋带公式）
def calculate_pixel_area(rect):
    area = 0
    n = len(rect)
    for i in range(n):
        x_i, y_i = rect[i]
        x_j, y_j = rect[(i + 1) % n]
        area += (x_i * y_j - x_j * y_i)
    return abs(area) / 2

# 判断矩形是否为正方形（四边长度相近且四角为直角）
def is_square(rect, angle_threshold=15, side_threshold=0.1):
    if len(rect) != 4:
        return False

    # 计算四条边的长度
    sides = []
    for i in range(4):
        p1, p2 = rect[i], rect[(i+1)%4]
        side_length = hypot(p2[0] - p1[0], p2[1] - p1[1])
        sides.append(side_length)

    # 检查四边是否相近（误差不超过10%）
    max_side = max(sides)
    min_side = min(sides)
    if min_side / max_side < (1 - side_threshold):
        return False

    # 检查四个角是否为直角
    for i in range(4):
        p1, p2, p3 = rect[i], rect[(i+1)%4], rect[(i+2)%4]
        angle = calculate_angle(p1, p2, p3)
        if abs(angle - 90) > angle_threshold:
            return False

    return True

sensor_id = 2
sensor = None

picture_width = 800
picture_height = 480
ANGLE_THRESHOLD = 15  # 矩形角度阈值
A4_WIDTH = 210  # 最外圈矩形实际宽度(mm)
A4_HEIGHT = 297  # 最外圈矩形实际高度(mm)
A4_ACTUAL_AREA = A4_WIDTH * A4_HEIGHT  # 最外圈矩形实际面积：62370 mm²
roi=(300, 50, 200, 380)  # ROI区域：(x, y, width, height)
# 显示模式选择
DISPLAY_MODE = "LCD"
# 嵌套矩形最小间隔(像素)
MIN_RECT_DISTANCE = 8  # 可根据实际情况调整

# 显示宽高配置
if DISPLAY_MODE == "VIRT":
    DISPLAY_WIDTH = ALIGN_UP(1920, 16)
    DISPLAY_HEIGHT = 1080
elif DISPLAY_MODE == "LCD":
    DISPLAY_WIDTH = 800
    DISPLAY_HEIGHT = 480
elif DISPLAY_MODE == "HDMI":
    DISPLAY_WIDTH = 1920
    DISPLAY_HEIGHT = 1080
else:
    raise ValueError("未知的 DISPLAY_MODE，请选择 'VIRT', 'LCD' 或 'HDMI'")

try:
    # 初始化摄像头
    sensor = Sensor(id=sensor_id)
    sensor.reset()
    sensor.set_hmirror(False)
    sensor.set_vflip(False)
    sensor.set_framesize(width=picture_width, height=picture_height, chn=CAM_CHN_ID_0)
    sensor.set_pixformat(Sensor.GRAYSCALE, chn=CAM_CHN_ID_0)

    # 初始化显示器
    if DISPLAY_MODE == "VIRT":
        Display.init(Display.VIRT, width=DISPLAY_WIDTH, height=DISPLAY_HEIGHT, fps=60)
    elif DISPLAY_MODE == "LCD":
        Display.init(Display.ST7701, width=DISPLAY_WIDTH, height=DISPLAY_HEIGHT, to_ide=True)
    elif DISPLAY_MODE == "HDMI":
        Display.init(Display.LT9611, width=DISPLAY_WIDTH, height=DISPLAY_HEIGHT, to_ide=True)

    MediaManager.init()
    sensor.run()
    fps = time.clock()

    while True:
        fps.tick()
        os.exitpoint()

        # 捕获图像并二值化
        src_img = sensor.snapshot(chn=CAM_CHN_ID_0)
        src_img.binary([(120, 255)], invert=False)

        # 将ROI区域外的部分涂成黑色
        src_img.draw_rectangle(0, 0, picture_width, roi[1], color=0, fill=True)
        src_img.draw_rectangle(0, roi[1]+roi[3], picture_width, picture_height - (roi[1]+roi[3]), color=0, fill=True)
        src_img.draw_rectangle(0, roi[1], roi[0], roi[3], color=0, fill=True)
        src_img.draw_rectangle(roi[0]+roi[2], roi[1], picture_width - (roi[0]+roi[2]), roi[3], color=0, fill=True)

        # 查找符合条件的矩形
        rects = src_img.find_rects(threshold=3500)
        rectangle_corners_list = []  # 存储所有矩形

        for rect in rects:
            corners = rect.corners()
            if len(corners) != 4:
                continue

            # 过滤过小矩形
            length1 = hypot(corners[1][0]-corners[0][0], corners[1][1]-corners[0][1])
            length2 = hypot(corners[2][0]-corners[1][0], corners[2][1]-corners[1][1])
            if length1 < 20 or length2 < 20:
                continue

            # 验证直角
            is_rectangle = True
            for i in range(4):
                p1, p2, p3 = corners[i], corners[(i+1)%4], corners[(i+2)%4]
                angle = calculate_angle(p1, p2, p3)
                if abs(angle - 90) > ANGLE_THRESHOLD:
                    is_rectangle = False
                    break
            if is_rectangle:
                rectangle_corners_list.append(corners)

        # 检测嵌套矩形并判断内圈是否为正方形
        nested_count = 0
        nested_pairs = []  # 存储嵌套矩形对

        m = len(rectangle_corners_list)
        for i in range(m):
            for j in range(i + 1, m):
                rect_a, rect_b = rectangle_corners_list[i], rectangle_corners_list[j]
                # 使用新的嵌套检测函数，加入最小间隔判断
                if is_nested_with_min_distance(rect_a, rect_b, MIN_RECT_DISTANCE):
                    nested_count += 1
                    nested_pairs.append((rect_a, rect_b))

        # 仅在恰好检测到一组嵌套矩形且内圈为正方形时输出
        if nested_count == 1:
            rect_a, rect_b = nested_pairs[0]
            # 区分内外圈（按面积）
            a_area = calculate_pixel_area(rect_a)
            b_area = calculate_pixel_area(rect_b)
            outer_rect = rect_a if a_area > b_area else rect_b
            inner_rect = rect_b if a_area > b_area else rect_a

            # 判断内圈是否为正方形
            if is_square(inner_rect):
                # 计算转换系数（最外圈实际面积 / 最外圈像素面积）
                outer_pixel_area = calculate_pixel_area(outer_rect)
                if outer_pixel_area == 0:
                    continue
                conversion_factor = A4_ACTUAL_AREA / outer_pixel_area

                # 计算正方形的实际面积
                square_pixel_area = calculate_pixel_area(inner_rect)
                square_actual_area = square_pixel_area * conversion_factor

                # 输出结果
                print("检测到嵌套矩形内有正方形：")
                print(f"  最外圈矩形像素面积：{outer_pixel_area:.1f} 像素")
                print(f"  正方形像素面积：{square_pixel_area:.1f} 像素")
                print(f"  正方形实际面积：{square_actual_area:.1f} mm²")
                print(f"  内外矩形最小间隔：{MIN_RECT_DISTANCE} 像素")
                print("------------------------")

        # 显示图像
        Display.show_image(src_img, x=0, y=0, layer=Display.LAYER_OSD1)

except KeyboardInterrupt as e:
    print("用户停止: ", e)
except BaseException as e:
    print(f"异常: {e}")
finally:
    if isinstance(sensor, Sensor):
        sensor.stop()
    Display.deinit()
    os.exitpoint(os.EXITPOINT_ENABLE_SLEEP)
    time.sleep_ms(100)
    MediaManager.deinit()
```