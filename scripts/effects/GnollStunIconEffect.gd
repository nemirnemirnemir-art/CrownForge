extends Node2D
class_name GnollStunIconEffect

@export var float_amplitude: float = 6.0
@export var float_speed: float = 5.0

const ICON_SIZE: float = 37.5

@onready var _icon: Sprite2D = $Icon

var _duration: float = 0.0
var _elapsed: float = 0.0
var _base_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	if _icon and _icon.texture:
		var tex_size := _icon.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			_icon.scale = Vector2(ICON_SIZE / tex_size.x, ICON_SIZE / tex_size.y)
	_base_pos = position

func setup(duration: float) -> void:
	_duration = maxf(0.01, duration)
	_elapsed = 0.0
	_base_pos = position

func _process(delta: float) -> void:
	_elapsed += delta
	position = _base_pos + Vector2(0.0, sin(_elapsed * float_speed) * float_amplitude)
	if _duration > 0.0 and _elapsed >= _duration:
		queue_free()

static func attach_to(unit: Node2D, duration: float) -> GnollStunIconEffect:
	if unit == null or not is_instance_valid(unit):
		return null

	var existing := unit.get_node_or_null("GnollStunIconEffect")
	if existing and is_instance_valid(existing):
		existing.queue_free()

	var scene := preload("res://scenes/effects/GnollStunIconEffect.tscn")
	var instance: GnollStunIconEffect = scene.instantiate()
	unit.add_child(instance)
	instance.position = Vector2(0.0, -76.0)
	instance.setup(duration)
	return instance
