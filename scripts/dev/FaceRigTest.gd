@tool
extends Node2D

@export var move_speed: float = 220.0
@export var rotate_speed: float = 2.4
@export var auto_anim: bool = true
@export var embed_mode: bool = false
@export var embed_panel_position: Vector2 = Vector2(1035.0, 700.0)
@export var embed_panel_scale: Vector2 = Vector2(0.82, 0.82)

@export var idle_enabled: bool = true
@export var idle_breath_period: float = 3.6
@export var idle_breath_y: float = 4.0
@export var idle_sway_x: float = 1.5
@export var idle_rot_deg: float = 1.2
@export var idle_hair_lag: float = 0.12

@export var hair_gray_blend_speed: float = 6.0

@export var expr_blend_speed: float = 8.0
@export var smile_mouth_up: float = 5.0
@export var smile_mouth_squash: float = 0.99
@export var smile_brow_up: float = 6.0
@export var smile_eye_squint: float = 0.78

@export var smile_corner_out: float = 0.08
@export var smile_corner_up: float = 0.05
@export var smile_corner_rot_deg: float = 6.0

@export var mouth_smile_texture: Texture2D

@export var head_profiles_path: String = "res://assets/characters/character_faces/head_profiles.json"
@export var profile_edit_mode: bool = true
@export var profile_auto_apply: bool = true
@export var profile_debug_logs: bool = false
@export var enforce_hat_hair_restrictions: bool = true
@export var hat_blocked_hair_variants: Dictionary = {}

@export var editor_apply_profile_now: bool = false
@export var editor_save_profile_now: bool = false

@export_enum("Warp", "Scale", "Morph") var mouth_mode: int = 0

@export var nose_textures: Array[Texture2D] = []
@export var nose_index: int = 0
@export var eye_left_textures: Array[Texture2D] = []
@export var eye_right_textures: Array[Texture2D] = []
@export var eye_index: int = 0

@export var head_textures: Array[Texture2D] = []
@export var head_index: int = 0
@export var hair_textures: Array[Texture2D] = []
@export var hair_index: int = 0
@export var hat_textures: Array[Texture2D] = []
@export var hat_index: int = 0
@export var mouth_textures: Array[Texture2D] = []
@export var mouth_index: int = 0
@export var brow_textures: Array[Texture2D] = []
@export var brow_index: int = 0
@export var ear_left_textures: Array[Texture2D] = []
@export var ear_right_textures: Array[Texture2D] = []
@export var ear_index: int = 0

@onready var skeleton: Skeleton2D = $Skeleton2D
@onready var root: Bone2D = $Skeleton2D/Root
@onready var preview_camera: Camera2D = get_node_or_null("Camera2D") as Camera2D
@onready var face_gen_ui: CanvasLayer = get_node_or_null("UI") as CanvasLayer
@onready var face_gen_root: Control = get_node_or_null("UI/FaceGen") as Control
@onready var face_gen_panel: PanelContainer = get_node_or_null("UI/FaceGen/Panel") as PanelContainer

func _find_embed_anchor(anchor_name: String) -> Node2D:
    var current: Node = self
    while current:
        var parent := current.get_parent()
        if parent == null:
            break
        var candidate := parent.get_node_or_null(anchor_name) as Node2D
        if candidate:
            return candidate
        current = parent
    return null

@onready var face_base: Sprite2D = $FaceBase
@onready var hair_sprite: Sprite2D = $Skeleton2D/Root/Head/Hair
@onready var hat_sprite: Sprite2D = get_node_or_null("Skeleton2D/Root/Head/Hat") as Sprite2D

@onready var head: Bone2D = $Skeleton2D/Root/Head
@onready var eye_l: Bone2D = $Skeleton2D/Root/Head/Eye_L
@onready var eye_r: Bone2D = $Skeleton2D/Root/Head/Eye_R
@onready var mouth: Bone2D = $Skeleton2D/Root/Head/Mouth
@onready var nose: Bone2D = $Skeleton2D/Root/Head/Nose

@onready var ear_l: Bone2D = $Skeleton2D/Root/Head/Ear_L
@onready var ear_r: Bone2D = $Skeleton2D/Root/Head/Ear_R
@onready var brow_l: Bone2D = $Skeleton2D/Root/Head/Brow_L
@onready var brow_r: Bone2D = $Skeleton2D/Root/Head/Brow_R

@onready var sprite_eye_l: Sprite2D = $Skeleton2D/Root/Head/Eye_L/LeftEye
@onready var sprite_eye_r: Sprite2D = $Skeleton2D/Root/Head/Eye_R/RightEye
@onready var mouth_sprite: Sprite2D = $Skeleton2D/Root/Head/Mouth/MouthSprite
@onready var sprite_nose: Sprite2D = $Skeleton2D/Root/Head/Nose/Nose
@onready var sprite_ear_l: Sprite2D = $Skeleton2D/Root/Head/Ear_L/EarLeft
@onready var sprite_ear_r: Sprite2D = $Skeleton2D/Root/Head/Ear_R/EarRight
@onready var sprite_brow_l: Sprite2D = $Skeleton2D/Root/Head/Brow_L/BrowLeft
@onready var sprite_brow_r: Sprite2D = $Skeleton2D/Root/Head/Brow_R/BrowRight
@onready var sprite_pupil_l: Sprite2D = $Skeleton2D/Root/Head/Eye_L/LeftPupil
@onready var sprite_pupil_r: Sprite2D = $Skeleton2D/Root/Head/Eye_R/RightPupil

@onready var nose_slider := get_node_or_null("UI/FaceGen/Panel/Rows/NoseRow/NoseSlider") as HSlider
@onready var nose_prev_btn := get_node_or_null("UI/FaceGen/Panel/Rows/NoseRow/NosePrev") as Button
@onready var nose_next_btn := get_node_or_null("UI/FaceGen/Panel/Rows/NoseRow/NoseNext") as Button
@onready var eye_slider := get_node_or_null("UI/FaceGen/Panel/Rows/EyeRow/EyeSlider") as HSlider
@onready var eye_prev_btn := get_node_or_null("UI/FaceGen/Panel/Rows/EyeRow/EyePrev") as Button
@onready var eye_next_btn := get_node_or_null("UI/FaceGen/Panel/Rows/EyeRow/EyeNext") as Button

@onready var head_slider := get_node_or_null("UI/FaceGen/Panel/Rows/HeadRow/HeadSlider") as HSlider
@onready var head_prev_btn := get_node_or_null("UI/FaceGen/Panel/Rows/HeadRow/HeadPrev") as Button
@onready var head_next_btn := get_node_or_null("UI/FaceGen/Panel/Rows/HeadRow/HeadNext") as Button

@onready var hair_slider := get_node_or_null("UI/FaceGen/Panel/Rows/HairRow/HairSlider") as HSlider
@onready var hair_prev_btn := get_node_or_null("UI/FaceGen/Panel/Rows/HairRow/HairPrev") as Button
@onready var hair_next_btn := get_node_or_null("UI/FaceGen/Panel/Rows/HairRow/HairNext") as Button

@onready var hair_toggle := get_node_or_null("UI/FaceGen/Panel/Rows/ToggleRow/HairToggle") as CheckBox

@onready var hat_slider := get_node_or_null("UI/FaceGen/Panel/Rows/HatRow/HatSlider") as HSlider
@onready var hat_prev_btn := get_node_or_null("UI/FaceGen/Panel/Rows/HatRow/HatPrev") as Button
@onready var hat_next_btn := get_node_or_null("UI/FaceGen/Panel/Rows/HatRow/HatNext") as Button

@onready var hat_toggle := get_node_or_null("UI/FaceGen/Panel/Rows/ToggleRow/HatToggle") as CheckBox

@onready var mouth_slider := get_node_or_null("UI/FaceGen/Panel/Rows/MouthRow/MouthSlider") as HSlider
@onready var mouth_prev_btn := get_node_or_null("UI/FaceGen/Panel/Rows/MouthRow/MouthPrev") as Button
@onready var mouth_next_btn := get_node_or_null("UI/FaceGen/Panel/Rows/MouthRow/MouthNext") as Button

@onready var brow_slider := get_node_or_null("UI/FaceGen/Panel/Rows/BrowRow/BrowSlider") as HSlider
@onready var brow_prev_btn := get_node_or_null("UI/FaceGen/Panel/Rows/BrowRow/BrowPrev") as Button
@onready var brow_next_btn := get_node_or_null("UI/FaceGen/Panel/Rows/BrowRow/BrowNext") as Button

@onready var ear_slider := get_node_or_null("UI/FaceGen/Panel/Rows/EarRow/EarSlider") as HSlider
@onready var ear_prev_btn := get_node_or_null("UI/FaceGen/Panel/Rows/EarRow/EarPrev") as Button
@onready var ear_next_btn := get_node_or_null("UI/FaceGen/Panel/Rows/EarRow/EarNext") as Button

@onready var profile_apply_btn := get_node_or_null("UI/FaceGen/Panel/Rows/ProfileActionsRow/ApplyProfileButton") as Button
@onready var profile_save_btn := get_node_or_null("UI/FaceGen/Panel/Rows/ProfileActionsRow/SaveProfileButton") as Button
@onready var profile_edit_toggle := get_node_or_null("UI/FaceGen/Panel/Rows/ProfileModesRow/EditMode") as CheckBox
@onready var profile_auto_apply_toggle := get_node_or_null("UI/FaceGen/Panel/Rows/ProfileModesRow/AutoApply") as CheckBox
@onready var profile_status_label := get_node_or_null("UI/FaceGen/Panel/Rows/ProfileStatus") as Label

const MIN_SCALE_COMPONENT := 0.2

const TIP_DEFAULT_LENGTH := 12.0

const HEAD_PROFILE_VERSION := 2
const USER_HEAD_PROFILES_PATH := "user://head_profiles.json"

const HEAD_PROFILE_PART_KEYS := ["eye", "mouth", "nose", "ear", "brow", "hair", "hat"]

const HEAD_PROFILE_PART_PATHS := {
    "eye": [
        NodePath("Skeleton2D/Root/Head/Eye_L"),
        NodePath("Skeleton2D/Root/Head/Eye_R"),
        NodePath("Skeleton2D/Root/Head/Eye_L/LeftEye"),
        NodePath("Skeleton2D/Root/Head/Eye_R/RightEye"),
    ],
    "mouth": [
        NodePath("Skeleton2D/Root/Head/Mouth"),
        NodePath("Skeleton2D/Root/Head/Mouth/MouthSprite"),
    ],
    "nose": [
        NodePath("Skeleton2D/Root/Head/Nose"),
        NodePath("Skeleton2D/Root/Head/Nose/Nose"),
    ],
    "ear": [
        NodePath("Skeleton2D/Root/Head/Ear_L"),
        NodePath("Skeleton2D/Root/Head/Ear_R"),
        NodePath("Skeleton2D/Root/Head/Ear_L/EarLeft"),
        NodePath("Skeleton2D/Root/Head/Ear_R/EarRight"),
    ],
    "brow": [
        NodePath("Skeleton2D/Root/Head/Brow_L"),
        NodePath("Skeleton2D/Root/Head/Brow_R"),
        NodePath("Skeleton2D/Root/Head/Brow_L/BrowLeft"),
        NodePath("Skeleton2D/Root/Head/Brow_R/BrowRight"),
    ],
    "hair": [
        NodePath("Skeleton2D/Root/Head/Hair"),
    ],
    "hat": [
        NodePath("Skeleton2D/Root/Head/Hat"),
    ],
}

const HEAD_PROFILE_TARGETS := [
    NodePath("Skeleton2D/Root/Head/Eye_L"),
    NodePath("Skeleton2D/Root/Head/Eye_R"),
    NodePath("Skeleton2D/Root/Head/Mouth"),
    NodePath("Skeleton2D/Root/Head/Nose"),
    NodePath("Skeleton2D/Root/Head/Ear_L"),
    NodePath("Skeleton2D/Root/Head/Ear_R"),
    NodePath("Skeleton2D/Root/Head/Brow_L"),
    NodePath("Skeleton2D/Root/Head/Brow_R"),
    NodePath("Skeleton2D/Root/Head/Eye_L/LeftEye"),
    NodePath("Skeleton2D/Root/Head/Eye_R/RightEye"),
    NodePath("Skeleton2D/Root/Head/Mouth/MouthSprite"),
    NodePath("Skeleton2D/Root/Head/Nose/Nose"),
    NodePath("Skeleton2D/Root/Head/Ear_L/EarLeft"),
    NodePath("Skeleton2D/Root/Head/Ear_R/EarRight"),
    NodePath("Skeleton2D/Root/Head/Brow_L/BrowLeft"),
    NodePath("Skeleton2D/Root/Head/Brow_R/BrowRight"),
    NodePath("Skeleton2D/Root/Head/Hair"),
    NodePath("Skeleton2D/Root/Head/Hat"),
]

var _reported_det_issue: bool = false

var _head_profiles: Dictionary = {}
var _default_profile: Dictionary = {}

var _selected_idx: int = 1
var _t: float = 0.0
var _blink_t: float = 0.0
var _blink_interval: float = 3.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pupil_state_center: bool = true
var _pupil_state_timer: float = 0.0
var _pupil_target_offset: Vector2 = Vector2.ZERO
var _pupil_base_l: Vector2
var _pupil_base_r: Vector2

var _base_skeleton_pos: Vector2
var _base_skeleton_rot: float
var _base_face_pos: Vector2
var _base_face_rot: float
var _base_hair_pos: Vector2
var _base_hair_rot: float
var _base_hat_pos: Vector2
var _base_hat_rot: float

var _base_mouth_pos: Vector2
var _base_mouth_rot: float
var _base_mouth_scale: Vector2
var _base_mouth_sprite_pos: Vector2
var _base_mouth_sprite_scale: Vector2
var _base_brow_l_pos: Vector2
var _base_brow_r_pos: Vector2
var _base_eye_sprite_scale_l: Vector2
var _base_eye_sprite_scale_r: Vector2

var _expr_target: float = 0.0
var _expr: float = 0.0
var _expr_targets := [0.0, 0.0, 0.0] # per-mouth-mode targets
var _expr_values := [0.0, 0.0, 0.0] # per-mouth-mode current values
var _smile_toggle_held: bool = false
var _smile2_toggle_held: bool = false
var _smile3_toggle_held: bool = false
var _hair_toggle_held: bool = false
var _profile_apply_shortcut_held: bool = false
var _profile_save_shortcut_held: bool = false

var _mouth_shader_mat: ShaderMaterial
var _mouth_morph_mat: ShaderMaterial
var _hair_shader_mat: ShaderMaterial

var _hair_gray: float = 0.0
var _hair_gray_target: float = 0.0
var _brow_single_texture: bool = false
var _brow_right_textures: Array[Texture2D] = []

func _ready() -> void:
    _apply_embed_mode()
    _load_head_profiles()
    _setup_profile_controls()
    if Engine.is_editor_hint():
        _setup_head_generator()
        _setup_hair_generator()
        _setup_hat_generator()
        _setup_mouth_generator()
        _setup_brow_generator()
        _setup_ear_generator()
        _setup_nose_generator()
        _setup_eye_generator()
        _capture_default_profile()
        if profile_auto_apply:
            _apply_head_profile(head_index)
        _refresh_profile_status()
        return

    _rng.randomize()
    _randomize_blink_interval()

    _sanitize_face_rig_transforms()
    _overwrite_skeleton_rest_pose_if_needed()
    _configure_leaf_bones()
    _capture_runtime_bases()

    _setup_mouth_shader()
    _setup_mouth_morph()
    _apply_mouth_mode()
    _setup_hair_shader()

    _setup_head_generator()
    _setup_hair_generator()
    _setup_hat_generator()
    _setup_mouth_generator()
    _setup_brow_generator()
    _setup_ear_generator()
    _setup_nose_generator()
    _setup_eye_generator()

    _sanitize_face_rig_transforms()
    _capture_default_profile()
    if profile_auto_apply:
        _apply_head_profile(head_index)
    if sprite_pupil_l and (sprite_pupil_l.texture == null):
        sprite_pupil_l.visible = false
    if sprite_pupil_r and (sprite_pupil_r.texture == null):
        sprite_pupil_r.visible = false
    _refresh_profile_status()

func _apply_embed_mode() -> void:
    if not embed_mode:
        return
    z_index = 50
    if preview_camera:
        preview_camera.enabled = false
        preview_camera.visible = false
    if face_gen_ui:
        face_gen_ui.visible = true
    if face_gen_root:
        face_gen_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
        face_gen_root.offset_left = 0.0
        face_gen_root.offset_top = 0.0
        face_gen_root.offset_right = 0.0
        face_gen_root.offset_bottom = 0.0
    if face_gen_panel:
        var settings_anchor := _find_embed_anchor("SettingsAnchor")
        if settings_anchor:
            face_gen_panel.position = settings_anchor.global_position
        else:
            face_gen_panel.position = embed_panel_position
        face_gen_panel.scale = embed_panel_scale

func _load_textures_numbered(dir_path: String) -> Array[Texture2D]:
    var out: Array[Texture2D] = []
    var dir := DirAccess.open(dir_path)
    if dir == null:
        return out
    var names: Array[String] = []
    dir.list_dir_begin()
    while true:
        var f := dir.get_next()
        if f == "":
            break
        if dir.current_is_dir():
            continue
        if not f.to_lower().ends_with(".png"):
            continue
        names.append(f)
    dir.list_dir_end()
    names.sort_custom(func(a: String, b: String) -> bool:
        return int(a.get_basename()) < int(b.get_basename())
    )
    for f in names:
        var t := load(dir_path.path_join(f)) as Texture2D
        if t:
            out.append(t)
    return out

func _load_paired_lr_textures(dir_path: String) -> Array:
    var left_map: Dictionary = {}
    var right_map: Dictionary = {}
    var dir := DirAccess.open(dir_path)
    if dir == null:
        return [[], []]
    dir.list_dir_begin()
    while true:
        var f := dir.get_next()
        if f == "":
            break
        if dir.current_is_dir():
            continue
        var fl := f.to_lower()
        if not fl.ends_with(".png"):
            continue
        if fl.ends_with("_left.png"):
            var k := fl.replace("_left.png", "")
            left_map[k] = f
        elif fl.ends_with("_right.png"):
            var k := fl.replace("_right.png", "")
            right_map[k] = f
    dir.list_dir_end()
    var keys: Array[String] = []
    for k in left_map.keys():
        if right_map.has(k):
            keys.append(String(k))
    keys.sort_custom(func(a: String, b: String) -> bool:
        return int(a) < int(b)
    )
    var left_out: Array[Texture2D] = []
    var right_out: Array[Texture2D] = []
    for k in keys:
        var t_l := load(dir_path.path_join(String(left_map[k]))) as Texture2D
        var t_r := load(dir_path.path_join(String(right_map[k]))) as Texture2D
        if t_l and t_r:
            left_out.append(t_l)
            right_out.append(t_r)
    return [left_out, right_out]

func _setup_head_generator() -> void:
    if not face_base:
        return
    if head_textures.is_empty():
        head_textures = _load_textures_numbered("res://assets/characters/character_faces/head")
    if head_textures.is_empty():
        return
    head_index = clampi(head_index, 0, head_textures.size() - 1)
    _apply_head_index(head_index)
    if head_slider:
        head_slider.min_value = 0.0
        head_slider.max_value = float(head_textures.size() - 1)
        head_slider.step = 1.0
        head_slider.value = float(head_index)
        if not head_slider.value_changed.is_connected(_on_head_slider_value_changed):
            head_slider.value_changed.connect(_on_head_slider_value_changed)
    if head_prev_btn and not head_prev_btn.pressed.is_connected(_on_head_prev_pressed):
        head_prev_btn.pressed.connect(_on_head_prev_pressed)
    if head_next_btn and not head_next_btn.pressed.is_connected(_on_head_next_pressed):
        head_next_btn.pressed.connect(_on_head_next_pressed)

func _apply_head_index(idx: int) -> void:
    if head_textures.is_empty() or not face_base:
        return
    var previous_index := head_index
    var next_index := wrapi(idx, 0, head_textures.size())
    if profile_edit_mode and next_index != previous_index:
        _save_head_profile(previous_index)
    head_index = next_index
    face_base.texture = head_textures[head_index]
    if profile_auto_apply:
        _apply_head_profile(head_index)
    if head_slider:
        head_slider.value = float(head_index)
    _capture_runtime_bases()
    _refresh_profile_status()

func _exit_tree() -> void:
    if profile_edit_mode and not Engine.is_editor_hint():
        _profile_debug("Exit-tree autosave head=%d" % head_index)
        _save_head_profile(head_index)

func _capture_runtime_bases() -> void:
    if skeleton:
        _base_skeleton_pos = skeleton.position
        _base_skeleton_rot = skeleton.rotation
    if face_base:
        _base_face_pos = face_base.position
        _base_face_rot = face_base.rotation
    if hair_sprite:
        _base_hair_pos = hair_sprite.position
        _base_hair_rot = hair_sprite.rotation
    if hat_sprite:
        _base_hat_pos = hat_sprite.position
        _base_hat_rot = hat_sprite.rotation

    if mouth:
        _base_mouth_pos = mouth.position
        _base_mouth_rot = mouth.rotation
        _base_mouth_scale = mouth.scale
    if brow_l:
        _base_brow_l_pos = brow_l.position
    if brow_r:
        _base_brow_r_pos = brow_r.position

    if mouth_sprite:
        _base_mouth_sprite_pos = mouth_sprite.position
        _base_mouth_sprite_scale = mouth_sprite.scale
    if sprite_eye_l:
        _base_eye_sprite_scale_l = sprite_eye_l.scale
    if sprite_eye_r:
        _base_eye_sprite_scale_r = sprite_eye_r.scale
    if sprite_pupil_l:
        _pupil_base_l = sprite_pupil_l.position
    if sprite_pupil_r:
        _pupil_base_r = sprite_pupil_r.position

func _capture_default_profile() -> void:
    _default_profile = {}
    for path in HEAD_PROFILE_TARGETS:
        var n := get_node_or_null(path)
        if n is Node2D:
            _default_profile[String(path)] = _capture_node2d_state(n as Node2D)

func _apply_default_profile() -> void:
    if _default_profile.is_empty():
        return
    for k in _default_profile.keys():
        var path := NodePath(String(k))
        var n := get_node_or_null(path)
        if n is Node2D:
            var st_v: Variant = _default_profile[k]
            if typeof(st_v) == TYPE_DICTIONARY:
                _apply_node2d_state(n as Node2D, st_v as Dictionary)
    _sanitize_face_rig_transforms()
    _capture_runtime_bases()

func _get_profile_part_paths(part_key: String) -> Array:
    if not HEAD_PROFILE_PART_PATHS.has(part_key):
        return []
    var paths_v: Variant = HEAD_PROFILE_PART_PATHS[part_key]
    if typeof(paths_v) != TYPE_ARRAY:
        return []
    return paths_v as Array

func _get_profile_part_index(part_key: String) -> int:
    match part_key:
        "eye":
            return eye_index
        "mouth":
            return mouth_index
        "nose":
            return nose_index
        "ear":
            return ear_index
        "brow":
            return brow_index
        "hair":
            return hair_index
        "hat":
            return hat_index
        _:
            return -1

func _capture_profile_part_state(part_key: String) -> Dictionary:
    var out: Dictionary = {}
    for path in _get_profile_part_paths(part_key):
        var n := get_node_or_null(path)
        if n is Node2D:
            out[String(path)] = _capture_node2d_state(n as Node2D)
    return out

func _apply_default_profile_part(part_key: String) -> void:
    if _default_profile.is_empty():
        return
    for path in _get_profile_part_paths(part_key):
        var key := String(path)
        if not _default_profile.has(key):
            continue
        var n := get_node_or_null(path)
        if n is Node2D:
            var st_v: Variant = _default_profile[key]
            if typeof(st_v) == TYPE_DICTIONARY:
                _apply_node2d_state(n as Node2D, st_v as Dictionary)

func _extract_head_parts_data(head_entry: Dictionary) -> Dictionary:
    if not head_entry.has("parts"):
        return {}
    var parts_v: Variant = head_entry["parts"]
    if typeof(parts_v) != TYPE_DICTIONARY:
        return {}
    return parts_v as Dictionary

func _extract_head_profile_entry(idx: int) -> Dictionary:
    var head_key := str(idx)
    if not _head_profiles.has(head_key):
        return {}
    var head_entry_v: Variant = _head_profiles[head_key]
    if typeof(head_entry_v) != TYPE_DICTIONARY:
        return {}
    var head_entry := head_entry_v as Dictionary
    if _extract_head_parts_data(head_entry).is_empty():
        return {}
    return head_entry

func _extract_part_variants(parts_data: Dictionary, part_key: String) -> Dictionary:
    if not parts_data.has(part_key):
        return {}
    var variants_v: Variant = parts_data[part_key]
    if typeof(variants_v) != TYPE_DICTIONARY:
        return {}
    return variants_v as Dictionary

func _apply_profile_state_dict(prof: Dictionary) -> void:
    for k in prof.keys():
        var path := NodePath(String(k))
        var n := get_node_or_null(path)
        if n is Node2D:
            var st_v: Variant = prof[k]
            if typeof(st_v) == TYPE_DICTIONARY:
                _apply_node2d_state(n as Node2D, st_v as Dictionary)

func _apply_part_profile_variant(head_entry: Dictionary, part_key: String) -> bool:
    var part_idx := _get_profile_part_index(part_key)
    if part_idx < 0:
        return false

    var parts_data := _extract_head_parts_data(head_entry)
    if parts_data.is_empty():
        return false

    var variants := _extract_part_variants(parts_data, part_key)
    if variants.is_empty():
        return false

    var variant_key := str(part_idx)
    if not variants.has(variant_key):
        return false

    var prof_v: Variant = variants[variant_key]
    if typeof(prof_v) != TYPE_DICTIONARY:
        return false

    _apply_profile_state_dict(prof_v as Dictionary)
    return true

func _apply_current_part_profile(part_key: String) -> void:
    _apply_default_profile_part(part_key)

    var head_entry := _extract_head_profile_entry(head_index)
    if not head_entry.is_empty():
        _apply_part_profile_variant(head_entry, part_key)

    _sanitize_face_rig_transforms()
    _capture_runtime_bases()

func _on_head_slider_value_changed(v: float) -> void:
    _apply_head_index(int(round(v)))

func _on_head_prev_pressed() -> void:
    _apply_head_index(head_index - 1)

func _on_head_next_pressed() -> void:
    _apply_head_index(head_index + 1)

func _is_hat_hair_restriction_active() -> bool:
    if not enforce_hat_hair_restrictions:
        return false
    if not hat_sprite:
        return false
    if not hat_sprite.visible:
        return false
    if hair_textures.is_empty():
        return false
    return true

func _get_blocked_hair_for_hat_idx(hat_idx_value: int) -> Dictionary:
    var out: Dictionary = {}
    if not enforce_hat_hair_restrictions:
        return out

    var raw_v: Variant = null
    if hat_blocked_hair_variants.has(hat_idx_value):
        raw_v = hat_blocked_hair_variants[hat_idx_value]
    elif hat_blocked_hair_variants.has(str(hat_idx_value)):
        raw_v = hat_blocked_hair_variants[str(hat_idx_value)]
    else:
        return out

    if typeof(raw_v) == TYPE_ARRAY:
        var arr := raw_v as Array
        for v in arr:
            out[int(v)] = true
        return out

    if typeof(raw_v) == TYPE_PACKED_INT32_ARRAY:
        var packed := raw_v as PackedInt32Array
        for v in packed:
            out[int(v)] = true
        return out

    if typeof(raw_v) == TYPE_DICTIONARY:
        var dict := raw_v as Dictionary
        for k in dict.keys():
            var is_blocked := bool(dict[k])
            if is_blocked:
                out[int(k)] = true

    return out

func _is_hair_allowed_for_current_hat(candidate_idx: int) -> bool:
    if not _is_hat_hair_restriction_active():
        return true
    var blocked := _get_blocked_hair_for_hat_idx(hat_index)
    if blocked.is_empty():
        return true
    return not blocked.has(candidate_idx)

func _find_next_allowed_hair_idx(start_idx: int, step: int) -> int:
    if hair_textures.is_empty():
        return -1
    var dir := 1 if step >= 0 else -1
    var count := hair_textures.size()
    for offset in range(count):
        var candidate := wrapi(start_idx + offset * dir, 0, count)
        if _is_hair_allowed_for_current_hat(candidate):
            return candidate
    return -1

func _enforce_hat_hair_restriction(step: int = 1, report_status: bool = true) -> bool:
    if not _is_hat_hair_restriction_active():
        return false
    if _is_hair_allowed_for_current_hat(hair_index):
        return false

    var count := hair_textures.size()
    if count == 0:
        return false

    var dir := 1 if step >= 0 else -1
    var search_start := wrapi(hair_index + dir, 0, count)
    var fallback := _find_next_allowed_hair_idx(search_start, dir)
    if fallback < 0:
        _profile_debug("Hair restriction: no allowed variants for hat=%d" % hat_index)
        if report_status:
            _refresh_profile_status("Hat %d blocks all hair" % [hat_index + 1])
        return false

    var blocked_idx := hair_index
    hair_index = fallback
    if hair_sprite:
        hair_sprite.texture = hair_textures[hair_index]
    if hair_slider:
        hair_slider.value = float(hair_index)

    _profile_debug("Hair restriction: hat=%d blocked_hair=%d fallback_hair=%d" % [
        hat_index,
        blocked_idx,
        hair_index,
    ])
    if report_status:
        _refresh_profile_status("Hair %d blocked by Hat %d -> Hair %d" % [
            blocked_idx + 1,
            hat_index + 1,
            hair_index + 1,
        ])
    return true

func _setup_hair_generator() -> void:
    if not hair_sprite:
        return
    if hair_textures.is_empty():
        hair_textures = _load_textures_numbered("res://assets/characters/character_faces/hair")
    if hair_textures.is_empty():
        return
    hair_index = clampi(hair_index, 0, hair_textures.size() - 1)
    _apply_hair_index(hair_index)
    if hair_slider:
        hair_slider.min_value = 0.0
        hair_slider.max_value = float(hair_textures.size() - 1)
        hair_slider.step = 1.0
        hair_slider.value = float(hair_index)
        if not hair_slider.value_changed.is_connected(_on_hair_slider_value_changed):
            hair_slider.value_changed.connect(_on_hair_slider_value_changed)
    if hair_prev_btn and not hair_prev_btn.pressed.is_connected(_on_hair_prev_pressed):
        hair_prev_btn.pressed.connect(_on_hair_prev_pressed)
    if hair_next_btn and not hair_next_btn.pressed.is_connected(_on_hair_next_pressed):
        hair_next_btn.pressed.connect(_on_hair_next_pressed)
    if hair_toggle and not hair_toggle.toggled.is_connected(_on_hair_toggle_toggled):
        hair_toggle.toggled.connect(_on_hair_toggle_toggled)
        hair_toggle.button_pressed = hair_sprite.visible

func _apply_hair_index(idx: int, preferred_step: int = 1) -> void:
    if hair_textures.is_empty() or not hair_sprite:
        return
    hair_index = wrapi(idx, 0, hair_textures.size())
    hair_sprite.texture = hair_textures[hair_index]

    _enforce_hat_hair_restriction(preferred_step, true)

    if hair_slider:
        hair_slider.value = float(hair_index)
    if profile_auto_apply:
        _apply_current_part_profile("hair")

func _on_hair_slider_value_changed(v: float) -> void:
    _apply_hair_index(int(round(v)))

func _on_hair_prev_pressed() -> void:
    _apply_hair_index(hair_index - 1, -1)

func _on_hair_next_pressed() -> void:
    _apply_hair_index(hair_index + 1, 1)

func _on_hair_toggle_toggled(pressed: bool) -> void:
    if hair_sprite:
        hair_sprite.visible = pressed

func _setup_hat_generator() -> void:
    if not hat_sprite:
        return
    if hat_textures.is_empty():
        hat_textures = _load_textures_numbered("res://assets/characters/character_faces/hat")
    if hat_textures.is_empty():
        return
    hat_index = clampi(hat_index, 0, hat_textures.size() - 1)
    _apply_hat_index(hat_index)
    if hat_slider:
        hat_slider.min_value = 0.0
        hat_slider.max_value = float(hat_textures.size() - 1)
        hat_slider.step = 1.0
        hat_slider.value = float(hat_index)
        if not hat_slider.value_changed.is_connected(_on_hat_slider_value_changed):
            hat_slider.value_changed.connect(_on_hat_slider_value_changed)
    if hat_prev_btn and not hat_prev_btn.pressed.is_connected(_on_hat_prev_pressed):
        hat_prev_btn.pressed.connect(_on_hat_prev_pressed)
    if hat_next_btn and not hat_next_btn.pressed.is_connected(_on_hat_next_pressed):
        hat_next_btn.pressed.connect(_on_hat_next_pressed)
    if hat_toggle and not hat_toggle.toggled.is_connected(_on_hat_toggle_toggled):
        hat_toggle.toggled.connect(_on_hat_toggle_toggled)
        hat_toggle.button_pressed = hat_sprite.visible

func _apply_hat_index(idx: int) -> void:
    if hat_textures.is_empty() or not hat_sprite:
        return
    hat_index = wrapi(idx, 0, hat_textures.size())
    hat_sprite.texture = hat_textures[hat_index]

    var hair_switched := _enforce_hat_hair_restriction(1, true)

    if hat_slider:
        hat_slider.value = float(hat_index)
    if profile_auto_apply:
        _apply_current_part_profile("hat")
        if hair_switched:
            _apply_current_part_profile("hair")

func _on_hat_slider_value_changed(v: float) -> void:
    _apply_hat_index(int(round(v)))

func _on_hat_prev_pressed() -> void:
    _apply_hat_index(hat_index - 1)

func _on_hat_next_pressed() -> void:
    _apply_hat_index(hat_index + 1)

func _on_hat_toggle_toggled(pressed: bool) -> void:
    if hat_sprite:
        hat_sprite.visible = pressed

    var hair_switched := _enforce_hat_hair_restriction(1, true)
    if profile_auto_apply and hair_switched:
        _apply_current_part_profile("hair")

func _setup_mouth_generator() -> void:
    if not mouth_sprite:
        return
    if mouth_textures.is_empty():
        mouth_textures = _load_textures_numbered("res://assets/characters/character_faces/mouth")
    if mouth_textures.is_empty():
        return
    mouth_index = clampi(mouth_index, 0, mouth_textures.size() - 1)
    _apply_mouth_index(mouth_index)
    if mouth_slider:
        mouth_slider.min_value = 0.0
        mouth_slider.max_value = float(mouth_textures.size() - 1)
        mouth_slider.step = 1.0
        mouth_slider.value = float(mouth_index)
        if not mouth_slider.value_changed.is_connected(_on_mouth_slider_value_changed):
            mouth_slider.value_changed.connect(_on_mouth_slider_value_changed)
    if mouth_prev_btn and not mouth_prev_btn.pressed.is_connected(_on_mouth_prev_pressed):
        mouth_prev_btn.pressed.connect(_on_mouth_prev_pressed)
    if mouth_next_btn and not mouth_next_btn.pressed.is_connected(_on_mouth_next_pressed):
        mouth_next_btn.pressed.connect(_on_mouth_next_pressed)

func _apply_mouth_index(idx: int) -> void:
    if mouth_textures.is_empty() or not mouth_sprite:
        return
    mouth_index = wrapi(idx, 0, mouth_textures.size())
    set_mouth_texture(mouth_textures[mouth_index])
    if mouth_slider:
        mouth_slider.value = float(mouth_index)
    if profile_auto_apply:
        _apply_current_part_profile("mouth")

func _on_mouth_slider_value_changed(v: float) -> void:
    _apply_mouth_index(int(round(v)))

func _on_mouth_prev_pressed() -> void:
    _apply_mouth_index(mouth_index - 1)

func _on_mouth_next_pressed() -> void:
    _apply_mouth_index(mouth_index + 1)

func _setup_brow_generator() -> void:
    if not sprite_brow_l or not sprite_brow_r:
        return
    if brow_textures.is_empty():
        var pair := _load_paired_lr_textures("res://assets/characters/character_faces/brown")
        if pair[0].size() > 0 and pair[1].size() > 0:
            _brow_single_texture = false
            brow_textures = pair[0]
            _brow_right_textures = pair[1]
        else:
            _brow_single_texture = true
            brow_textures = _load_textures_numbered("res://assets/characters/character_faces/brown")
    if brow_textures.is_empty():
        return
    brow_index = clampi(brow_index, 0, brow_textures.size() - 1)
    _apply_brow_index(brow_index)
    if brow_slider:
        brow_slider.min_value = 0.0
        brow_slider.max_value = float(brow_textures.size() - 1)
        brow_slider.step = 1.0
        brow_slider.value = float(brow_index)
        if not brow_slider.value_changed.is_connected(_on_brow_slider_value_changed):
            brow_slider.value_changed.connect(_on_brow_slider_value_changed)
    if brow_prev_btn and not brow_prev_btn.pressed.is_connected(_on_brow_prev_pressed):
        brow_prev_btn.pressed.connect(_on_brow_prev_pressed)
    if brow_next_btn and not brow_next_btn.pressed.is_connected(_on_brow_next_pressed):
        brow_next_btn.pressed.connect(_on_brow_next_pressed)

func _apply_brow_index(idx: int) -> void:
    if brow_textures.is_empty() or not sprite_brow_l or not sprite_brow_r:
        return
    brow_index = wrapi(idx, 0, brow_textures.size())
    if _brow_single_texture:
        sprite_brow_l.texture = brow_textures[brow_index]
        sprite_brow_r.texture = null
        sprite_brow_r.visible = false
    else:
        if brow_index < _brow_right_textures.size():
            sprite_brow_l.texture = brow_textures[brow_index]
            sprite_brow_r.texture = _brow_right_textures[brow_index]
            sprite_brow_r.visible = true
        else:
            sprite_brow_l.texture = brow_textures[brow_index]
            sprite_brow_r.texture = brow_textures[brow_index]
            sprite_brow_r.visible = true
    if brow_slider:
        brow_slider.value = float(brow_index)
    if profile_auto_apply:
        _apply_current_part_profile("brow")

func _on_brow_slider_value_changed(v: float) -> void:
    _apply_brow_index(int(round(v)))

func _on_brow_prev_pressed() -> void:
    _apply_brow_index(brow_index - 1)

func _on_brow_next_pressed() -> void:
    _apply_brow_index(brow_index + 1)

func _setup_ear_generator() -> void:
    if not sprite_ear_l or not sprite_ear_r:
        return
    if ear_left_textures.is_empty() or ear_right_textures.is_empty():
        var pair := _load_paired_lr_textures("res://assets/characters/character_faces/ears")
        ear_left_textures = pair[0]
        ear_right_textures = pair[1]
    var variant_count: int = min(ear_left_textures.size(), ear_right_textures.size())
    if variant_count == 0:
        return
    ear_index = clampi(ear_index, 0, variant_count - 1)
    _apply_ear_index(ear_index)
    if ear_slider:
        ear_slider.min_value = 0.0
        ear_slider.max_value = float(variant_count - 1)
        ear_slider.step = 1.0
        ear_slider.value = float(ear_index)
        if not ear_slider.value_changed.is_connected(_on_ear_slider_value_changed):
            ear_slider.value_changed.connect(_on_ear_slider_value_changed)
    if ear_prev_btn and not ear_prev_btn.pressed.is_connected(_on_ear_prev_pressed):
        ear_prev_btn.pressed.connect(_on_ear_prev_pressed)
    if ear_next_btn and not ear_next_btn.pressed.is_connected(_on_ear_next_pressed):
        ear_next_btn.pressed.connect(_on_ear_next_pressed)

func _apply_ear_index(idx: int) -> void:
    var variant_count: int = min(ear_left_textures.size(), ear_right_textures.size())
    if variant_count == 0 or not sprite_ear_l or not sprite_ear_r:
        return
    ear_index = wrapi(idx, 0, variant_count)
    sprite_ear_l.texture = ear_left_textures[ear_index]
    sprite_ear_r.texture = ear_right_textures[ear_index]
    if ear_slider:
        ear_slider.value = float(ear_index)
    if profile_auto_apply:
        _apply_current_part_profile("ear")

func _on_ear_slider_value_changed(v: float) -> void:
    _apply_ear_index(int(round(v)))

func _on_ear_prev_pressed() -> void:
    _apply_ear_index(ear_index - 1)

func _on_ear_next_pressed() -> void:
    _apply_ear_index(ear_index + 1)

func _setup_nose_generator() -> void:
    if not sprite_nose:
        return

    if nose_textures.is_empty():
        nose_textures = _load_textures_numbered("res://assets/characters/character_faces/nose")

    if nose_textures.is_empty():
        return

    nose_index = clampi(nose_index, 0, nose_textures.size() - 1)
    _apply_nose_index(nose_index)

    if nose_slider:
        nose_slider.min_value = 0.0
        nose_slider.max_value = float(nose_textures.size() - 1)
        nose_slider.step = 1.0
        nose_slider.value = float(nose_index)
        if not nose_slider.value_changed.is_connected(_on_nose_slider_value_changed):
            nose_slider.value_changed.connect(_on_nose_slider_value_changed)

    if nose_prev_btn:
        if not nose_prev_btn.pressed.is_connected(_on_nose_prev_pressed):
            nose_prev_btn.pressed.connect(_on_nose_prev_pressed)
    if nose_next_btn:
        if not nose_next_btn.pressed.is_connected(_on_nose_next_pressed):
            nose_next_btn.pressed.connect(_on_nose_next_pressed)

func _apply_nose_index(idx: int) -> void:
    if nose_textures.is_empty() or not sprite_nose:
        return
    nose_index = wrapi(idx, 0, nose_textures.size())
    sprite_nose.texture = nose_textures[nose_index]
    if nose_slider:
        nose_slider.value = float(nose_index)
    if profile_auto_apply:
        _apply_current_part_profile("nose")

func _on_nose_slider_value_changed(v: float) -> void:
    _apply_nose_index(int(round(v)))

func _on_nose_prev_pressed() -> void:
    _apply_nose_index(nose_index - 1)

func _on_nose_next_pressed() -> void:
    _apply_nose_index(nose_index + 1)

func _setup_eye_generator() -> void:
    if not sprite_eye_l or not sprite_eye_r:
        return

    if eye_left_textures.is_empty() or eye_right_textures.is_empty():
        var pair := _load_paired_lr_textures("res://assets/characters/character_faces/eyes")
        eye_left_textures = pair[0]
        eye_right_textures = pair[1]

    var variant_count: int = min(eye_left_textures.size(), eye_right_textures.size())
    if variant_count == 0:
        return

    eye_index = clampi(eye_index, 0, variant_count - 1)
    _apply_eye_index(eye_index)

    if eye_slider:
        eye_slider.min_value = 0.0
        eye_slider.max_value = float(variant_count - 1)
        eye_slider.step = 1.0
        eye_slider.value = float(eye_index)
        if not eye_slider.value_changed.is_connected(_on_eye_slider_value_changed):
            eye_slider.value_changed.connect(_on_eye_slider_value_changed)

    if eye_prev_btn and not eye_prev_btn.pressed.is_connected(_on_eye_prev_pressed):
        eye_prev_btn.pressed.connect(_on_eye_prev_pressed)
    if eye_next_btn and not eye_next_btn.pressed.is_connected(_on_eye_next_pressed):
        eye_next_btn.pressed.connect(_on_eye_next_pressed)

func _apply_eye_index(idx: int) -> void:
    var variant_count: int = min(eye_left_textures.size(), eye_right_textures.size())
    if variant_count == 0 or not sprite_eye_l or not sprite_eye_r:
        return

    eye_index = wrapi(idx, 0, variant_count)
    sprite_eye_l.texture = eye_left_textures[eye_index]
    sprite_eye_r.texture = eye_right_textures[eye_index]
    if eye_slider:
        eye_slider.value = float(eye_index)
    if profile_auto_apply:
        _apply_current_part_profile("eye")

func _on_eye_slider_value_changed(v: float) -> void:
    _apply_eye_index(int(round(v)))

func _on_eye_prev_pressed() -> void:
    _apply_eye_index(eye_index - 1)

func _on_eye_next_pressed() -> void:
    _apply_eye_index(eye_index + 1)

func _setup_mouth_shader() -> void:
    var sh := Shader.new()
    sh.code = """
shader_type canvas_item;
uniform float smile = 0.0;
uniform float corner_lift = 0.55;
uniform float corner_spread = 0.25;
uniform float lower_tuck = 0.2;

void fragment() {
    vec2 uv = UV;
    float s = clamp(smile, 0.0, 1.0);

    float x = uv.x - 0.5;
    float ax = abs(x) * 2.0;

    // чуть-чуть раздвигаем уголки по горизонтали
    uv.x += x * s * corner_spread * ax;

    // поднимаем только края
    float edge = smoothstep(0.4, 1.0, ax);
    uv.y -= s * corner_lift * edge;

    // удерживаем середину, чтобы не спадала
    float mid = 1.0 - edge;
    uv.y = mix(uv.y, UV.y, mid * 0.6);

    // нижняя губа чуть подтягивается вверх
    if (uv.y > 0.7) {
        float ly = smoothstep(0.7, 1.0, uv.y);
        uv.y -= s * lower_tuck * ly;
    }

    uv = clamp(uv, vec2(0.001), vec2(0.999));

    COLOR = texture(TEXTURE, uv) * COLOR;
}
"""
    _mouth_shader_mat = ShaderMaterial.new()
    _mouth_shader_mat.shader = sh
    mouth_sprite.material = _mouth_shader_mat

func _setup_mouth_morph() -> void:
    var sh := Shader.new()
    sh.code = """
shader_type canvas_item;
uniform sampler2D smile_tex;
uniform float blend = 0.0;

void fragment() {
    vec4 a = texture(TEXTURE, UV);
    vec4 b = texture(smile_tex, UV);
    COLOR = mix(a, b, clamp(blend, 0.0, 1.0)) * COLOR;
}
"""
    _mouth_morph_mat = ShaderMaterial.new()
    _mouth_morph_mat.shader = sh
    if mouth_smile_texture:
        _mouth_morph_mat.set_shader_parameter("smile_tex", mouth_smile_texture)
    else:
        _mouth_morph_mat.set_shader_parameter("smile_tex", mouth_sprite.texture)
    _mouth_morph_mat.set_shader_parameter("blend", 0.0)

func _setup_hair_shader() -> void:
    if not hair_sprite:
        return
    var sh := Shader.new()
    sh.code = """
shader_type canvas_item;
uniform float gray_amount = 0.0;
uniform float highlight = 0.94;

vec3 to_gray(vec3 c) {
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    return vec3(l);
}

void fragment() {
    vec4 col = texture(TEXTURE, UV) * COLOR;
    float g = clamp(gray_amount, 0.0, 1.0);
    vec3 rgb = col.rgb;
    if (g > 0.0001) {
        vec3 gray = to_gray(col.rgb);
        vec3 desat = mix(col.rgb, gray, 0.55);
        vec3 silver = mix(desat, vec3(highlight), 0.18);
        float fade = g * 0.8;
        rgb = mix(col.rgb, silver, fade);
    }
    COLOR = vec4(rgb, col.a);
}
"""
    _hair_shader_mat = ShaderMaterial.new()
    _hair_shader_mat.shader = sh
    _hair_shader_mat.set_shader_parameter("gray_amount", _hair_gray)
    hair_sprite.material = _hair_shader_mat

func _apply_mouth_mode() -> void:
    if not mouth_sprite:
        return
    mouth_sprite.visible = true
    if mouth_mode == 0:
        mouth_sprite.material = _mouth_shader_mat
    elif mouth_mode == 1:
        mouth_sprite.material = null
    else:
        mouth_sprite.material = _mouth_morph_mat

    mouth_sprite.position = _base_mouth_sprite_pos
    mouth_sprite.scale = _base_mouth_sprite_scale

    _expr_target = _expr_targets[mouth_mode]
    _expr = _expr_values[mouth_mode]

func _setup_profile_controls() -> void:
    if profile_apply_btn and not profile_apply_btn.pressed.is_connected(_on_profile_apply_pressed):
        profile_apply_btn.pressed.connect(_on_profile_apply_pressed)
    if profile_save_btn and not profile_save_btn.pressed.is_connected(_on_profile_save_pressed):
        profile_save_btn.pressed.connect(_on_profile_save_pressed)

    if profile_edit_toggle:
        if not profile_edit_toggle.toggled.is_connected(_on_profile_edit_mode_toggled):
            profile_edit_toggle.toggled.connect(_on_profile_edit_mode_toggled)
        profile_edit_toggle.set_pressed_no_signal(profile_edit_mode)

    if profile_auto_apply_toggle:
        if not profile_auto_apply_toggle.toggled.is_connected(_on_profile_auto_apply_toggled):
            profile_auto_apply_toggle.toggled.connect(_on_profile_auto_apply_toggled)
        profile_auto_apply_toggle.set_pressed_no_signal(profile_auto_apply)

func _refresh_profile_status(extra: String = "") -> void:
    if not profile_status_label:
        return
    var base := "Head %d | %s | %s" % [
        head_index + 1,
        "Edit ON" if profile_edit_mode else "Edit OFF",
        "Auto ON" if profile_auto_apply else "Auto OFF"
    ]
    if extra != "":
        base = "%s | %s" % [base, extra]
    profile_status_label.text = base

func _on_profile_apply_pressed() -> void:
    if _extract_head_profile_entry(head_index).is_empty():
        _apply_default_profile()
        _refresh_profile_status("No saved profile")
    else:
        _apply_head_profile(head_index)
        _refresh_profile_status("Applied")

func _on_profile_save_pressed() -> void:
    _save_head_profile(head_index)
    _refresh_profile_status("Saved")

func _on_profile_edit_mode_toggled(pressed: bool) -> void:
    profile_edit_mode = pressed
    _capture_runtime_bases()
    _refresh_profile_status()

func _on_profile_auto_apply_toggled(pressed: bool) -> void:
    profile_auto_apply = pressed
    if profile_auto_apply:
        _on_profile_apply_pressed()
        return
    _refresh_profile_status()

func _handle_profile_shortcuts() -> void:
    var ctrl_pressed := Input.is_key_pressed(KEY_CTRL)

    var apply_pressed := ctrl_pressed and Input.is_key_pressed(KEY_ENTER)
    if apply_pressed:
        if not _profile_apply_shortcut_held:
            _profile_apply_shortcut_held = true
            _on_profile_apply_pressed()
    else:
        _profile_apply_shortcut_held = false

    var save_pressed := ctrl_pressed and Input.is_key_pressed(KEY_S)
    if save_pressed:
        if not _profile_save_shortcut_held:
            _profile_save_shortcut_held = true
            _on_profile_save_pressed()
    else:
        _profile_save_shortcut_held = false

func _profile_debug(msg: String) -> void:
    if not profile_debug_logs:
        return
    var mode := "editor" if Engine.is_editor_hint() else "runtime"
    print("[FaceRigProfileDebug][%s] %s" % [mode, msg])

func _get_head_hair_variant_keys(heads: Dictionary, idx: int) -> Array[String]:
    var head_key := str(idx)
    if not heads.has(head_key):
        return []
    var head_v: Variant = heads[head_key]
    if typeof(head_v) != TYPE_DICTIONARY:
        return []
    var parts := _extract_head_parts_data(head_v as Dictionary)
    if parts.is_empty():
        return []
    var hair := _extract_part_variants(parts, "hair")
    if hair.is_empty():
        return []
    var keys: Array[String] = []
    for k in hair.keys():
        keys.append(String(k))
    keys.sort_custom(func(a: String, b: String) -> bool:
        return int(a) < int(b)
    )
    return keys

func _collect_merged_profiles_from_disk(loaded_paths: Array[String]) -> Dictionary:
    var merged_heads: Dictionary = {}
    var read_candidates := _get_profile_read_candidates()
    read_candidates.sort_custom(func(a: String, b: String) -> bool:
        var a_is_user := a.begins_with("user://")
        var b_is_user := b.begins_with("user://")
        if a_is_user == b_is_user:
            return a < b
        return not a_is_user and b_is_user
    )

    for path in read_candidates:
        var heads := _read_profiles_heads(path)
        if heads.is_empty():
            continue
        var normalized_heads := _normalize_head_profiles(heads)
        if normalized_heads.is_empty():
            continue
        _merge_head_profiles(merged_heads, normalized_heads)
        loaded_paths.append(path)

    return merged_heads

func _load_head_profiles() -> void:
    _head_profiles = {}
    var loaded_paths: Array[String] = []
    var merged_heads := _collect_merged_profiles_from_disk(loaded_paths)

    if merged_heads.is_empty():
        _profile_debug("Load: no profiles found")
        return

    _head_profiles = merged_heads
    _profile_debug("Load: head=%d hair_keys=%s from=%s" % [
        head_index,
        _get_head_hair_variant_keys(_head_profiles, head_index),
        ", ".join(loaded_paths),
    ])
    print("[FaceRigTest] Head profiles loaded from:", ", ".join(loaded_paths))

func _write_head_profiles() -> void:
    var payload := {
        "version": HEAD_PROFILE_VERSION,
        "heads": _head_profiles,
    }
    var primary_path := ""
    for path in _get_profile_write_candidates():
        if _write_profiles_payload(path, payload):
            if primary_path == "":
                primary_path = path
    if primary_path == "":
        push_error("[FaceRigTest] Cannot write head profiles to res:// or user://")
        return
    head_profiles_path = primary_path
    _profile_debug("Write: head=%d hair_keys=%s primary=%s" % [
        head_index,
        _get_head_hair_variant_keys(_head_profiles, head_index),
        primary_path,
    ])
    print("[FaceRigTest] Head profiles saved to:", primary_path)

func _get_profile_read_candidates() -> Array[String]:
    var out: Array[String] = []
    if Engine.is_editor_hint():
        _append_unique_profile_path(out, head_profiles_path)
        _append_unique_profile_path(out, USER_HEAD_PROFILES_PATH)
    else:
        _append_unique_profile_path(out, USER_HEAD_PROFILES_PATH)
        _append_unique_profile_path(out, head_profiles_path)
    return out

func _get_profile_write_candidates() -> Array[String]:
    var out: Array[String] = []
    if Engine.is_editor_hint():
        _append_unique_profile_path(out, head_profiles_path)
        _append_unique_profile_path(out, USER_HEAD_PROFILES_PATH)
    else:
        _append_unique_profile_path(out, USER_HEAD_PROFILES_PATH)
        _append_unique_profile_path(out, head_profiles_path)
    return out

func _append_unique_profile_path(paths: Array[String], raw_path: String) -> void:
    var path := raw_path.strip_edges()
    if path == "":
        return
    if paths.has(path):
        return
    paths.append(path)

func _normalize_head_profiles(raw_heads: Dictionary) -> Dictionary:
    var out: Dictionary = {}
    for head_key_v in raw_heads.keys():
        var head_key := String(head_key_v)
        var head_entry_v: Variant = raw_heads[head_key_v]
        if typeof(head_entry_v) != TYPE_DICTIONARY:
            continue
        var normalized_head := _normalize_head_profile_entry(head_entry_v as Dictionary)
        if not normalized_head.is_empty():
            out[head_key] = normalized_head
    return out

func _normalize_head_profile_entry(head_entry: Dictionary) -> Dictionary:
    if not head_entry.has("parts"):
        return {}
    var parts_v: Variant = head_entry["parts"]
    if typeof(parts_v) != TYPE_DICTIONARY:
        return {}

    var raw_parts := parts_v as Dictionary
    var normalized_parts: Dictionary = {}
    for part_key_v in raw_parts.keys():
        var part_key := String(part_key_v)
        if not HEAD_PROFILE_PART_PATHS.has(part_key):
            continue
        var variants_v: Variant = raw_parts[part_key_v]
        if typeof(variants_v) != TYPE_DICTIONARY:
            continue
        var normalized_variants := _normalize_profile_part_variants(part_key, variants_v as Dictionary)
        if not normalized_variants.is_empty():
            normalized_parts[part_key] = normalized_variants

    if normalized_parts.is_empty():
        return {}
    return {
        "parts": normalized_parts,
    }

func _normalize_profile_part_variants(part_key: String, variants: Dictionary) -> Dictionary:
    var out: Dictionary = {}
    var allowed_paths: Dictionary = {}
    for path in _get_profile_part_paths(part_key):
        allowed_paths[String(path)] = true

    for variant_key_v in variants.keys():
        var variant_key := String(variant_key_v)
        var prof_v: Variant = variants[variant_key_v]
        if typeof(prof_v) != TYPE_DICTIONARY:
            continue

        var prof := prof_v as Dictionary
        var normalized_prof: Dictionary = {}
        for path_key_v in prof.keys():
            var path_key := String(path_key_v)
            if not allowed_paths.has(path_key):
                continue
            var st_v: Variant = prof[path_key_v]
            if typeof(st_v) != TYPE_DICTIONARY:
                continue
            normalized_prof[path_key] = st_v

        if not normalized_prof.is_empty():
            out[variant_key] = normalized_prof

    return out

func _merge_head_profiles(target: Dictionary, incoming: Dictionary) -> void:
    for head_key_v in incoming.keys():
        var head_key := String(head_key_v)
        var src_head_v: Variant = incoming[head_key_v]
        if typeof(src_head_v) != TYPE_DICTIONARY:
            continue
        var src_head := src_head_v as Dictionary
        var src_parts := _extract_head_parts_data(src_head)
        if src_parts.is_empty():
            continue

        var dst_head: Dictionary = {}
        if target.has(head_key):
            var dst_head_v: Variant = target[head_key]
            if typeof(dst_head_v) == TYPE_DICTIONARY:
                dst_head = (dst_head_v as Dictionary).duplicate(true)

        var dst_parts := _extract_head_parts_data(dst_head)
        if not dst_parts.is_empty():
            dst_parts = dst_parts.duplicate(true)

        for part_key_v in src_parts.keys():
            var part_key := String(part_key_v)
            if not HEAD_PROFILE_PART_PATHS.has(part_key):
                continue

            var src_variants := _extract_part_variants(src_parts, part_key)
            if src_variants.is_empty():
                continue

            var dst_variants := _extract_part_variants(dst_parts, part_key)
            if not dst_variants.is_empty():
                dst_variants = dst_variants.duplicate(true)

            for variant_key_v in src_variants.keys():
                var variant_key := String(variant_key_v)
                var prof_v: Variant = src_variants[variant_key_v]
                if typeof(prof_v) != TYPE_DICTIONARY:
                    continue
                dst_variants[variant_key] = (prof_v as Dictionary).duplicate(true)

            if not dst_variants.is_empty():
                dst_parts[part_key] = dst_variants

        if dst_parts.is_empty():
            continue

        dst_head["parts"] = dst_parts
        target[head_key] = dst_head

func _read_profiles_heads(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var text := file.get_as_text()
    file.close()

    var parsed: Variant = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    var root := parsed as Dictionary

    if not root.has("version"):
        return {}
    if int(root["version"]) != HEAD_PROFILE_VERSION:
        return {}
    if not root.has("heads"):
        return {}
    if typeof(root["heads"]) != TYPE_DICTIONARY:
        return {}

    return (root["heads"] as Dictionary).duplicate(true)

func _write_profiles_payload(path: String, payload: Dictionary) -> bool:
    var text := JSON.stringify(payload, "\t")
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(text)
    file.close()
    return true

func _capture_node2d_state(n2: Node2D) -> Dictionary:
    return {
        "pos": [n2.position.x, n2.position.y],
        "rot": n2.rotation,
        "scale": [n2.scale.x, n2.scale.y],
    }

func _apply_node2d_state(n2: Node2D, st: Dictionary) -> void:
    if st.has("pos") and typeof(st["pos"]) == TYPE_ARRAY and (st["pos"] as Array).size() >= 2:
        var a := st["pos"] as Array
        n2.position = Vector2(float(a[0]), float(a[1]))
    if st.has("rot"):
        n2.rotation = float(st["rot"])
    if st.has("scale") and typeof(st["scale"]) == TYPE_ARRAY and (st["scale"] as Array).size() >= 2:
        var s := st["scale"] as Array
        n2.scale = Vector2(float(s[0]), float(s[1]))

func _save_head_profile(idx: int) -> void:
    var head_key := str(idx)

    var disk_paths: Array[String] = []
    var disk_heads := _collect_merged_profiles_from_disk(disk_paths)
    if not disk_heads.is_empty():
        _merge_head_profiles(_head_profiles, disk_heads)

    _profile_debug("Save begin: head=%d hair_idx=%d mem_hair_keys=%s disk_hair_keys=%s disk_paths=%s" % [
        idx,
        hair_index,
        _get_head_hair_variant_keys(_head_profiles, idx),
        _get_head_hair_variant_keys(disk_heads, idx),
        ", ".join(disk_paths),
    ])

    var head_entry: Dictionary = {}
    if _head_profiles.has(head_key):
        var existing_head_v: Variant = _head_profiles[head_key]
        if typeof(existing_head_v) == TYPE_DICTIONARY:
            head_entry = (existing_head_v as Dictionary).duplicate(true)

    var parts_data := _extract_head_parts_data(head_entry)
    if not parts_data.is_empty():
        parts_data = parts_data.duplicate(true)

    for part_key_v in HEAD_PROFILE_PART_KEYS:
        var part_key := String(part_key_v)
        var part_idx := _get_profile_part_index(part_key)
        if part_idx < 0:
            continue

        var part_state := _capture_profile_part_state(part_key)
        if part_state.is_empty():
            continue

        var variants := _extract_part_variants(parts_data, part_key)
        if not variants.is_empty():
            variants = variants.duplicate(true)
        variants[str(part_idx)] = part_state
        parts_data[part_key] = variants

    if parts_data.is_empty():
        return

    head_entry["parts"] = parts_data
    _head_profiles[head_key] = head_entry
    _profile_debug("Save end: head=%d hair_idx=%d mem_hair_keys=%s" % [
        idx,
        hair_index,
        _get_head_hair_variant_keys(_head_profiles, idx),
    ])
    _write_head_profiles()

func _apply_head_profile(idx: int) -> void:
    _apply_default_profile()

    var head_entry := _extract_head_profile_entry(idx)
    if head_entry.is_empty():
        return

    for part_key_v in HEAD_PROFILE_PART_KEYS:
        _apply_part_profile_variant(head_entry, String(part_key_v))

    _sanitize_face_rig_transforms()
    _capture_runtime_bases()

func _process(delta: float) -> void:
    if editor_apply_profile_now:
        editor_apply_profile_now = false
        _on_profile_apply_pressed()
    if editor_save_profile_now:
        editor_save_profile_now = false
        _on_profile_save_pressed()
    _handle_profile_shortcuts()
    if Engine.is_editor_hint():
        return

    _t += delta
    if _hair_shader_mat:
        var hk := clampf(delta * hair_gray_blend_speed, 0.0, 1.0)
        _hair_gray = lerpf(_hair_gray, _hair_gray_target, hk)
        _hair_shader_mat.set_shader_parameter("gray_amount", _hair_gray)
    _sanitize_face_rig_transforms()
    _handle_selection()
    _handle_manual(delta)
    if auto_anim and not profile_edit_mode:
        _handle_auto(delta)

func _handle_selection() -> void:
    # Manual selection moved to F-keys so KEY_1 can be used for expressions.
    if Input.is_key_pressed(KEY_F1):
        _selected_idx = 1
    elif Input.is_key_pressed(KEY_F2):
        _selected_idx = 2
    elif Input.is_key_pressed(KEY_F3):
        _selected_idx = 3
    elif Input.is_key_pressed(KEY_F4):
        _selected_idx = 4
    elif Input.is_key_pressed(KEY_F5):
        _selected_idx = 5
    elif Input.is_key_pressed(KEY_F6):
        _selected_idx = 6
    elif Input.is_key_pressed(KEY_F7):
        _selected_idx = 7
    elif Input.is_key_pressed(KEY_F8):
        _selected_idx = 8
    elif Input.is_key_pressed(KEY_F9):
        _selected_idx = 9

    if Input.is_key_pressed(KEY_SPACE):
        auto_anim = false

    if Input.is_key_pressed(KEY_ENTER):
        auto_anim = true

    # Mode 0 (shader) on KEY_1.
    if Input.is_key_pressed(KEY_1):
        if not _smile_toggle_held:
            _smile_toggle_held = true
            mouth_mode = 0
            _apply_mouth_mode()
            _expr_targets[0] = 0.0 if _expr_targets[0] >= 0.5 else 1.0
            _expr_target = _expr_targets[mouth_mode]
            _expr = _expr_values[mouth_mode]
    else:
        _smile_toggle_held = false

    # Mode 1 (scale) on KEY_2.
    if Input.is_key_pressed(KEY_2):
        if not _smile2_toggle_held:
            _smile2_toggle_held = true
            mouth_mode = 1
            _apply_mouth_mode()
            _expr_targets[1] = 0.0 if _expr_targets[1] >= 0.5 else 1.0
            _expr_target = _expr_targets[mouth_mode]
            _expr = _expr_values[mouth_mode]
    else:
        _smile2_toggle_held = false

    # Mode 2 (segment smile) on KEY_3.
    if Input.is_key_pressed(KEY_3):
        if not _smile3_toggle_held:
            _smile3_toggle_held = true
            mouth_mode = 2
            _apply_mouth_mode()
            _expr_targets[2] = 0.0 if _expr_targets[2] >= 0.5 else 1.0
            _expr_target = _expr_targets[mouth_mode]
            _expr = _expr_values[mouth_mode]
    else:
        _smile3_toggle_held = false

    # Hair aging toggle on KEY_5.
    if Input.is_key_pressed(KEY_5):
        if not _hair_toggle_held:
            _hair_toggle_held = true
            _hair_gray_target = 0.0 if _hair_gray_target >= 0.5 else 1.0
    else:
        _hair_toggle_held = false

func _get_selected_bone() -> Bone2D:
    match _selected_idx:
        1:
            return head
        2:
            return eye_l
        3:
            return eye_r
        4:
            return mouth
        5:
            return nose
        6:
            return ear_l
        7:
            return ear_r
        8:
            return brow_l
        9:
            return brow_r
        _:
            return head

func _handle_manual(delta: float) -> void:
    var b := _get_selected_bone()
    var v := Vector2.ZERO
    if Input.is_key_pressed(KEY_LEFT):
        v.x -= 1.0
    if Input.is_key_pressed(KEY_RIGHT):
        v.x += 1.0
    if Input.is_key_pressed(KEY_UP):
        v.y -= 1.0
    if Input.is_key_pressed(KEY_DOWN):
        v.y += 1.0
    if v != Vector2.ZERO:
        b.position += v.normalized() * move_speed * delta

    var r := 0.0
    if Input.is_key_pressed(KEY_Q):
        r -= 1.0
    if Input.is_key_pressed(KEY_E):
        r += 1.0
    if r != 0.0:
        b.rotation += r * rotate_speed * delta

    if Input.is_key_pressed(KEY_R):
        b.rotation = 0.0
        b.scale = Vector2.ONE
        _ensure_non_zero_scale(b)

    if Input.is_key_pressed(KEY_Z):
        _scale_bone(b, 0.92, delta)
    if Input.is_key_pressed(KEY_X):
        _scale_bone(b, 1.08, delta)
    _ensure_non_zero_scale(b)

func _scale_bone(b: Bone2D, factor_y: float, delta: float) -> void:
    var new_scale := b.scale
    new_scale.y = clampf(new_scale.y * pow(factor_y, delta * 5.0), 0.15, 4.0)
    b.scale = new_scale

func _ensure_non_zero_scale(b: Bone2D) -> void:
    var s := b.scale
    if absf(s.x) < MIN_SCALE_COMPONENT:
        var sign_x := 1.0 if s.x >= 0.0 else -1.0
        if s.x == 0.0:
            sign_x = 1.0
        s.x = MIN_SCALE_COMPONENT * sign_x
    if absf(s.y) < MIN_SCALE_COMPONENT:
        var sign_y := 1.0 if s.y >= 0.0 else -1.0
        if s.y == 0.0:
            sign_y = 1.0
        s.y = MIN_SCALE_COMPONENT * sign_y
    b.scale = s

func _sanitize_face_rig_transforms() -> void:
    _sanitize_node_tree(self)

func _sanitize_node_tree(n: Node) -> void:
    _sanitize_node_transform(n)
    for c in n.get_children():
        _sanitize_node_tree(c)

func _sanitize_node_transform(n: Node) -> void:
    if n is Node2D:
        _sanitize_node2d(n as Node2D)
    elif n is Control:
        _sanitize_control(n as Control)
    if n is Bone2D:
        _sanitize_bone2d(n as Bone2D)

func _sanitize_node2d(n2: Node2D) -> void:
    var s := n2.scale
    if is_nan(s.x) or is_nan(s.y) or is_inf(s.x) or is_inf(s.y):
        s = Vector2.ONE
    if absf(s.x) < MIN_SCALE_COMPONENT:
        s.x = MIN_SCALE_COMPONENT if s.x >= 0.0 else -MIN_SCALE_COMPONENT
    if absf(s.y) < MIN_SCALE_COMPONENT:
        s.y = MIN_SCALE_COMPONENT if s.y >= 0.0 else -MIN_SCALE_COMPONENT
    if s != n2.scale:
        n2.scale = s
        if not _reported_det_issue:
            _reported_det_issue = true
            print("[FaceRigTest] Fixed degenerate scale on node:", n2.get_path(), " scale=", s)
    if absf(n2.transform.determinant()) <= 0.000001:
        n2.scale = s

func _sanitize_control(c: Control) -> void:
    var s := c.scale
    if is_nan(s.x) or is_nan(s.y) or is_inf(s.x) or is_inf(s.y):
        s = Vector2.ONE
    if absf(s.x) < MIN_SCALE_COMPONENT:
        s.x = MIN_SCALE_COMPONENT if s.x >= 0.0 else -MIN_SCALE_COMPONENT
    if absf(s.y) < MIN_SCALE_COMPONENT:
        s.y = MIN_SCALE_COMPONENT if s.y >= 0.0 else -MIN_SCALE_COMPONENT
    if s != c.scale:
        c.scale = s
        if not _reported_det_issue:
            _reported_det_issue = true
            print("[FaceRigTest] Fixed degenerate scale on node:", c.get_path(), " scale=", s)

func _sanitize_bone2d(b: Bone2D) -> void:
    if absf(b.rest.determinant()) <= 0.000001:
        b.rest = Transform2D(0.0, b.rest.origin)

func _overwrite_skeleton_rest_pose_if_needed() -> void:
    if not skeleton:
        return
    var roots := skeleton.get_children()
    for n in roots:
        if n is Bone2D:
            _overwrite_bone_rest_pose_recursive(n as Bone2D)

func _overwrite_bone_rest_pose_recursive(b: Bone2D) -> void:
    if absf(b.rest.determinant()) <= 0.000001:
        b.rest = b.transform
    for c in b.get_children():
        if c is Bone2D:
            _overwrite_bone_rest_pose_recursive(c as Bone2D)

func _configure_leaf_bones() -> void:
    if not skeleton:
        return
    for n in skeleton.get_children():
        if n is Bone2D:
            _configure_leaf_bones_recursive(n as Bone2D)

func _configure_leaf_bones_recursive(b: Bone2D) -> void:
    var has_bone_child := false
    for c in b.get_children():
        if c is Bone2D:
            has_bone_child = true
            _configure_leaf_bones_recursive(c as Bone2D)
    if not has_bone_child:
        b.set_autocalculate_length_and_angle(false)
        if b.get_length() <= 0.0:
            b.set_length(TIP_DEFAULT_LENGTH)

func _handle_auto(delta: float) -> void:
    if idle_enabled:
        _update_idle_motion(delta)

    _update_expression(delta)

    _blink_t += delta
    if _blink_t >= _blink_interval:
        _blink_t = 0.0
        _randomize_blink_interval()

    var blink_phase: float = clampf((_blink_t / 0.18), 0.0, 1.0)
    var blink_amount: float = 0.0
    if blink_phase <= 0.5:
        blink_amount = blink_phase * 2.0
    else:
        blink_amount = (1.0 - blink_phase) * 2.0

    var eye_y: float = lerpf(1.0, 0.7, blink_amount)
    var squint := lerpf(1.0, smile_eye_squint, _expr)
    var blink_scale := clampf(eye_y * squint, MIN_SCALE_COMPONENT, 5.0)
    var blink_vec := Vector2(1.0, blink_scale)
    sprite_eye_l.scale = _base_eye_sprite_scale_l * blink_vec
    sprite_eye_r.scale = _base_eye_sprite_scale_r * blink_vec

    var mouth_y := 1.0 + sin(_t * 2.0) * 0.08
    var smile_mouth_scale_y := lerpf(1.0, smile_mouth_squash, _expr)
    mouth.scale.y = clampf(mouth_y * smile_mouth_scale_y, MIN_SCALE_COMPONENT, 5.0)
    _ensure_non_zero_scale(mouth)
    _update_pupil_motion(delta)

func _update_expression(delta: float) -> void:
    var k := clampf(delta * expr_blend_speed, 0.0, 1.0)
    _expr = lerpf(_expr, _expr_target, k)
    _expr_values[mouth_mode] = _expr

    mouth.position = _base_mouth_pos
    mouth.rotation = _base_mouth_rot
    mouth.scale.x = _base_mouth_scale.x

    var mouth_vertical_offset := clampf(smile_mouth_up, -1.0, 1.0) * _expr

    if mouth_mode == 0:
        if _mouth_shader_mat:
            _mouth_shader_mat.set_shader_parameter("smile", _expr)
    elif mouth_mode == 1:
        var stretch_x := 1.0 + _expr * 0.05
        var stretch_y := 1.0 - _expr * 0.03
        mouth_sprite.scale = _base_mouth_sprite_scale * Vector2(stretch_x, stretch_y)
        var mode1_offset := Vector2(-_expr * smile_corner_out * 0.8, -_expr * smile_corner_up * 1.2 - mouth_vertical_offset)
        mouth_sprite.position = _base_mouth_sprite_pos + mode1_offset
    else:
        if _mouth_morph_mat:
            _mouth_morph_mat.set_shader_parameter("blend", _expr)
        mouth_sprite.position = _base_mouth_sprite_pos + Vector2(0.0, -mouth_vertical_offset)

    if mouth_mode != 1:
        mouth_sprite.scale = _base_mouth_sprite_scale

    brow_l.position = _base_brow_l_pos + Vector2(0.0, -smile_brow_up * _expr)
    brow_r.position = _base_brow_r_pos + Vector2(0.0, -smile_brow_up * _expr)

func _update_idle_motion(delta: float) -> void:
    var period := maxf(0.1, idle_breath_period)
    var w := TAU / period

    # 0..1
    var breath := (sin(_t * w) + 1.0) * 0.5
    # -1..1 sway
    var sway := sin(_t * w * 0.5 + 1.3)

    var offset := Vector2(sway * idle_sway_x, -breath * idle_breath_y)
    var rot := deg_to_rad(idle_rot_deg) * sin(_t * w * 0.5)

    skeleton.position = _base_skeleton_pos + offset
    skeleton.rotation = _base_skeleton_rot + rot

    face_base.position = _base_face_pos + offset
    face_base.rotation = _base_face_rot + rot

    var hair_target_pos := _base_hair_pos + offset + Vector2(0.0, -breath * idle_hair_lag * 10.0)
    var hair_target_rot := _base_hair_rot + rot * 1.1
    var k := clampf(delta * 8.0, 0.0, 1.0)
    hair_sprite.position = hair_sprite.position.lerp(hair_target_pos, k)
    hair_sprite.rotation = lerpf(hair_sprite.rotation, hair_target_rot, k)
    if hat_sprite:
        hat_sprite.position = _base_hat_pos + offset
        hat_sprite.rotation = _base_hat_rot + rot

func _update_pupil_motion(delta: float) -> void:
    _pupil_state_timer += delta
    if _pupil_state_center:
        if _pupil_state_timer >= 2.5:
            _pupil_state_center = false
            _pupil_state_timer = 0.0
            _pupil_target_offset = Vector2(-10, 0)
    else:
        if _pupil_state_timer >= 3.0:
            _pupil_state_center = true
            _pupil_state_timer = 0.0
            _pupil_target_offset = Vector2.ZERO

    var lerp_speed := clampf(delta * 5.0, 0.0, 1.0)
    var target_l := _pupil_base_l + _pupil_target_offset
    var target_r := _pupil_base_r + _pupil_target_offset
    sprite_pupil_l.position = sprite_pupil_l.position.lerp(target_l, lerp_speed)
    sprite_pupil_r.position = sprite_pupil_r.position.lerp(target_r, lerp_speed)

func _randomize_blink_interval() -> void:
    _blink_interval = _rng.randf_range(2.2, 4.2)

func set_left_eye_texture(tex: Texture2D) -> void:
    sprite_eye_l.texture = tex

func set_right_eye_texture(tex: Texture2D) -> void:
    sprite_eye_r.texture = tex

func set_mouth_texture(tex: Texture2D) -> void:
    if mouth_sprite:
        mouth_sprite.texture = tex
    if _mouth_morph_mat and not mouth_smile_texture:
        _mouth_morph_mat.set_shader_parameter("smile_tex", tex)
