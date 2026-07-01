extends Node2D

# Тестовая сцена для Polygon2D + кости рта
# Кости: Mouth (центр), Mouth_L1, Mouth_L2, Mouth_R1, Mouth_R2
# Управление:
#   1 - поднять уголки (улыбка)
#   2 - опустить уголки (грусть)
#   R - сброс

@export var smile_amount: float = 12.0
@export var corner_spread: float = 5.0
@export var preserve_scene_polygon: bool = true

@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var mouth_bone: Bone2D = $Skeleton2D/Mouth
@onready var mouth_l1: Bone2D = $Skeleton2D/Mouth/Mouth_L1
@onready var mouth_l2: Bone2D = $Skeleton2D/Mouth/Mouth_L2
@onready var mouth_r1: Bone2D = $Skeleton2D/Mouth/Mouth_R1
@onready var mouth_r2: Bone2D = $Skeleton2D/Mouth/Mouth_R2
@onready var mouth_polygon: Polygon2D = $Skeleton2D/Mouth/MouthPolygon

var _base_l1_pos: Vector2
var _base_l2_pos: Vector2
var _base_r1_pos: Vector2
var _base_r2_pos: Vector2

var _expr: float = 0.0
var _expr_target: float = 0.0
var _smile_toggle: bool = false
var _key1_prev: bool = false

func _make_weights(vc: int) -> PackedFloat32Array:
    var a := PackedFloat32Array()
    a.resize(vc)
    for j in range(vc):
        a[j] = 0.0
    return a

func _ready() -> void:
    _sync_bone_rest(mouth_bone)
    _sync_bone_rest(mouth_l1)
    _sync_bone_rest(mouth_l2)
    _sync_bone_rest(mouth_r1)
    _sync_bone_rest(mouth_r2)

    _setup_polygon()
    _base_l1_pos = mouth_l1.position
    _base_l2_pos = mouth_l2.position
    _base_r1_pos = mouth_r1.position
    _base_r2_pos = mouth_r2.position

func _sync_bone_rest(b: Bone2D) -> void:
    if not b:
        return
    # Если rest не совпадает с текущей позой из сцены, при запуске Skeleton2D
    # может вернуть кость в rest и рот "улетит".
    if b.rest.origin != b.position:
        var t := Transform2D.IDENTITY
        t.origin = b.position
        b.rest = t

func _setup_polygon() -> void:
    var tex := mouth_polygon.texture
    if not tex:
        push_error("MouthPolygon has no texture!")
        return

    # Если ты уже руками задал polygon/uv в сцене, не перезаписываем.
    # Иначе при запуске рот поменяет форму/позицию и может исчезнуть.
    if preserve_scene_polygon and mouth_polygon.polygon.size() >= 3:
        if mouth_polygon.uv.size() != mouth_polygon.polygon.size():
            mouth_polygon.uv = mouth_polygon.polygon
        if mouth_polygon.get_bone_count() == 0:
            _setup_bone_weights()
        return
    
    var w := float(tex.get_width())
    var h := float(tex.get_height())
    
    # Создаём 10 точек: верхний ряд (5) + нижний ряд (5)
    # Порядок: по часовой стрелке, начиная с верхнего левого
    #
    #  0 ---- 1 ---- 2 ---- 3 ---- 4   (верх)
    #  |                            |
    #  9 ---- 8 ---- 7 ---- 6 ---- 5   (низ)
    #
    # Кости:
    #   L2 влияет на 0, 9
    #   L1 влияет на 1, 8
    #   Mouth влияет на 2, 7
    #   R1 влияет на 3, 6
    #   R2 влияет на 4, 5
    
    var hw := w * 0.5
    var hh := h * 0.5
    
    var pts: PackedVector2Array = PackedVector2Array()
    var uvs: PackedVector2Array = PackedVector2Array()
    
    # Верхний ряд (слева направо)
    pts.append(Vector2(-hw, -hh))       # 0 - top-left corner
    pts.append(Vector2(-hw * 0.5, -hh)) # 1 - top-left-mid
    pts.append(Vector2(0, -hh))         # 2 - top-center
    pts.append(Vector2(hw * 0.5, -hh))  # 3 - top-right-mid
    pts.append(Vector2(hw, -hh))        # 4 - top-right corner
    
    # Нижний ряд (справа налево для замыкания)
    pts.append(Vector2(hw, hh))         # 5 - bottom-right corner
    pts.append(Vector2(hw * 0.5, hh))   # 6 - bottom-right-mid
    pts.append(Vector2(0, hh))          # 7 - bottom-center
    pts.append(Vector2(-hw * 0.5, hh))  # 8 - bottom-left-mid
    pts.append(Vector2(-hw, hh))        # 9 - bottom-left corner
    
    # UV (нормализованные 0..1)
    uvs.append(Vector2(0.0, 0.0))    # 0
    uvs.append(Vector2(0.25, 0.0))   # 1
    uvs.append(Vector2(0.5, 0.0))    # 2
    uvs.append(Vector2(0.75, 0.0))   # 3
    uvs.append(Vector2(1.0, 0.0))    # 4
    uvs.append(Vector2(1.0, 1.0))    # 5
    uvs.append(Vector2(0.75, 1.0))   # 6
    uvs.append(Vector2(0.5, 1.0))    # 7
    uvs.append(Vector2(0.25, 1.0))   # 8
    uvs.append(Vector2(0.0, 1.0))    # 9
    
    mouth_polygon.polygon = pts
    mouth_polygon.uv = uvs
    mouth_polygon.position = Vector2.ZERO
    
    # Привязка к костям
    _setup_bone_weights()

func _setup_bone_weights() -> void:
    # Получаем индексы костей в Skeleton2D
    var bone_count := skeleton.get_bone_count()
    print("Skeleton has ", bone_count, " bones")
    
    # Находим индексы наших костей
    var idx_mouth := -1
    var idx_l1 := -1
    var idx_l2 := -1
    var idx_r1 := -1
    var idx_r2 := -1
    
    for i in range(bone_count):
        var bone := skeleton.get_bone(i)
        match bone.name:
            "Mouth":
                idx_mouth = i
            "Mouth_L1":
                idx_l1 = i
            "Mouth_L2":
                idx_l2 = i
            "Mouth_R1":
                idx_r1 = i
            "Mouth_R2":
                idx_r2 = i
    
    print("Bone indices: Mouth=", idx_mouth, " L1=", idx_l1, " L2=", idx_l2, " R1=", idx_r1, " R2=", idx_r2)
    
    if idx_mouth < 0 or idx_l1 < 0 or idx_l2 < 0 or idx_r1 < 0 or idx_r2 < 0:
        push_error("Could not find all mouth bones!")
        return
    
    # Настраиваем internal_vertex_count = 0 (нет внутренних вершин)
    mouth_polygon.internal_vertex_count = 0

    # Godot 4.x: веса задаются через bones API (add_bone / set_bone_weights),
    # а не через прямое присваивание mouth_polygon.weights.
    mouth_polygon.clear_bones()

    var vc := mouth_polygon.polygon.size()
    if vc <= 0:
        push_error("Polygon has no vertices, cannot assign bone weights")
        return

    var w_mouth := _make_weights(vc)
    var w_l1 := _make_weights(vc)
    var w_l2 := _make_weights(vc)
    var w_r1 := _make_weights(vc)
    var w_r2 := _make_weights(vc)

    # Вершины (см. _setup_polygon):
    # 0 TL, 1 TLM, 2 TC, 3 TRM, 4 TR, 5 BR, 6 BRM, 7 BC, 8 BLM, 9 BL
    # L2 влияет на 0, 9
    w_l2[0] = 1.0
    w_l2[9] = 1.0

    # L1 влияет на 1, 8 (и чуть L2)
    w_l1[1] = 0.8
    w_l2[1] = 0.2
    w_l1[8] = 0.8
    w_l2[8] = 0.2

    # Mouth влияет на 2, 7
    w_mouth[2] = 1.0
    w_mouth[7] = 1.0

    # R1 влияет на 3, 6 (и чуть R2)
    w_r1[3] = 0.8
    w_r2[3] = 0.2
    w_r1[6] = 0.8
    w_r2[6] = 0.2

    # R2 влияет на 4, 5
    w_r2[4] = 1.0
    w_r2[5] = 1.0

    # Добавляем кости по NodePath относительно Polygon2D
    mouth_polygon.add_bone(NodePath(".."), w_mouth)         # Mouth
    mouth_polygon.add_bone(NodePath("../Mouth_L1"), w_l1)   # Mouth_L1
    mouth_polygon.add_bone(NodePath("../Mouth_L2"), w_l2)   # Mouth_L2
    mouth_polygon.add_bone(NodePath("../Mouth_R1"), w_r1)   # Mouth_R1
    mouth_polygon.add_bone(NodePath("../Mouth_R2"), w_r2)   # Mouth_R2

    print("Polygon2D bones configured: ", mouth_polygon.get_bone_count(), " bones")

func _process(delta: float) -> void:
    # Управление
    var key1_pressed := Input.is_key_pressed(KEY_1)
    if key1_pressed and not _key1_prev:
        _smile_toggle = not _smile_toggle
        _expr_target = 1.0 if _smile_toggle else 0.0
    elif Input.is_key_pressed(KEY_2):
        _smile_toggle = false
        _expr_target = -1.0
    elif Input.is_key_pressed(KEY_R):
        _smile_toggle = false
        _expr_target = 0.0
    _key1_prev = key1_pressed
    
    # Плавная интерполяция
    _expr = lerpf(_expr, _expr_target, clampf(delta * 8.0, 0.0, 1.0))
    
    # Двигаем кости уголков
    var outer_up := smile_amount * 2.2
    var inner_up := smile_amount * 1.4
    var outer_spread := corner_spread * 1.4
    var inner_spread := corner_spread * 0.7

    # L2 - внешний левый угол: сильно вверх + наружу
    mouth_l2.position = _base_l2_pos + Vector2(-outer_spread * _expr, -outer_up * _expr)
    # L1 - внутренний левый
    mouth_l1.position = _base_l1_pos + Vector2(-inner_spread * _expr, -inner_up * _expr)

    # R2 - внешний правый угол
    mouth_r2.position = _base_r2_pos + Vector2(outer_spread * _expr, -outer_up * _expr)
    # R1 - внутренний правый
    mouth_r1.position = _base_r1_pos + Vector2(inner_spread * _expr, -inner_up * _expr)
