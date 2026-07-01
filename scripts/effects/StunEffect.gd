extends Node2D
class_name StunEffect

## Visual stun effect attached to stunned units (spiral/stars animation)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _duration: float = 0.0
var _elapsed: float = 0.0

func _ready() -> void:
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("stun"):
		anim.play("stun")
	elif anim and anim.sprite_frames and anim.sprite_frames.has_animation("default"):
		anim.play("default")

func _process(delta: float) -> void:
	if _duration > 0.0:
		_elapsed += delta
		if _elapsed >= _duration:
			queue_free()

func setup(duration: float) -> void:
	_duration = duration
	_elapsed = 0.0

## Static helper to attach stun effect to a unit
static func attach_to(unit: Node2D, duration: float) -> StunEffect:
	var scene := preload("res://scenes/effects/StunEffect.tscn")
	var instance: StunEffect = scene.instantiate()
	unit.add_child(instance)
	instance.position = Vector2(0, -50)  # Above unit's head
	instance.setup(duration)
	return instance
