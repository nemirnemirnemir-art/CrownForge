extends Node2D
## FireDotEffect - Visual burn effect spawned when fire DoT is applied

@export var tick_count: int = 3
@export var tick_interval: float = 1.0

@onready var anim: AnimatedSprite2D = $AnimFire

var _ticks_remaining: int = 0
var _target: Node2D = null

func _ready() -> void:
	_ticks_remaining = tick_count
	if anim and anim.sprite_frames:
		if anim.sprite_frames.has_animation("burn"):
			anim.play("burn")
		elif anim.sprite_frames.has_animation("default"):
			anim.play("default")
	_start_tick_timer()

func attach_to_target(target: Node2D) -> void:
	_target = target
	if _target and is_instance_valid(_target):
		# Position at target center
		global_position = _target.global_position

func _process(_delta: float) -> void:
	# Follow target if attached
	if _target and is_instance_valid(_target):
		global_position = _target.global_position
	elif _target:
		# Target died, remove effect
		queue_free()

func _start_tick_timer() -> void:
	var tree := get_tree()
	if tree == null:
		queue_free()
		return
	
	await tree.create_timer(tick_interval).timeout
	_ticks_remaining -= 1
	
	if _ticks_remaining <= 0:
		# Fade out and destroy
		_fade_out()
	else:
		_start_tick_timer()

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.finished.connect(queue_free)
