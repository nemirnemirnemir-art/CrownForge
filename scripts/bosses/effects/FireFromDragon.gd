extends Node2D

@export_group("Timing")
@export var effect_duration_sec: float = 0.35

@export_group("Shape")
@export var local_cast_offset: Vector2 = Vector2.ZERO
@export var collision_size: Vector2 = Vector2(360.0, 220.0)

@export_group("Visual")
@export var visual_scale: Vector2 = Vector2.ONE
@export var z_index_value: int = 180

@onready var _fire_anim: AnimatedSprite2D = $FireAnim
@onready var _damage_area: Area2D = $DamageArea
@onready var _damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

var _caster: Node = null
var _flight_id: int = -1
var _time_left: float = 0.0
var _persistent_mode: bool = false

func setup_from_dragon(caster: Node, flight_id: int) -> void:
    _caster = caster
    _flight_id = flight_id

func set_persistent_mode(active: bool) -> void:
    _persistent_mode = active

func _ready() -> void:
    _time_left = maxf(0.05, effect_duration_sec)
    _setup_shape()
    _setup_visuals()
    set_process(true)

func _process(delta: float) -> void:
    if not _persistent_mode:
        _time_left -= delta
    _apply_hits()
    if not _persistent_mode and _time_left <= 0.0:
        queue_free()

func _setup_shape() -> void:
    if _damage_area:
        _damage_area.position = local_cast_offset
        _damage_area.monitoring = true
        _damage_area.monitorable = true

    if _damage_shape == null:
        return

    var rect := _damage_shape.shape as RectangleShape2D
    if rect == null:
        rect = RectangleShape2D.new()
        _damage_shape.shape = rect
    rect.size = collision_size

func _setup_visuals() -> void:
    if _fire_anim == null:
        return

    _fire_anim.position = local_cast_offset
    _fire_anim.scale = visual_scale
    _fire_anim.z_index = z_index_value

    if _fire_anim.sprite_frames == null:
        return

    if _fire_anim.sprite_frames.has_animation("fire_from_dragon"):
        _fire_anim.play("fire_from_dragon")
        return

    var names := _fire_anim.sprite_frames.get_animation_names()
    if names.size() > 0:
        _fire_anim.play(names[0])

func _apply_hits() -> void:
    if _caster == null or not is_instance_valid(_caster):
        return
    if not _caster.has_method("try_apply_flight_fire_hit"):
        return

    var overlaps: Array = []
    if _damage_area:
        overlaps.append_array(_damage_area.get_overlapping_areas())
        overlaps.append_array(_damage_area.get_overlapping_bodies())

    var seen: Dictionary = {}
    for obj in overlaps:
        var target := _resolve_target(obj)
        if target == null:
            continue
        var id := target.get_instance_id()
        if seen.has(id):
            continue
        seen[id] = true
        _caster.call("try_apply_flight_fire_hit", target, _flight_id)

func _resolve_target(obj: Variant) -> Node2D:
    if obj is Hurtbox:
        var hb := obj as Hurtbox
        var owner_node := hb.get_parent()
        if owner_node is Node2D and (owner_node as Node2D).is_in_group("hero"):
            return owner_node as Node2D
        return null

    if obj is Node2D:
        var node := obj as Node2D
        if node.is_in_group("hero"):
            return node
        var parent := node.get_parent()
        if parent is Node2D and (parent as Node2D).is_in_group("hero"):
            return parent as Node2D

    return null
