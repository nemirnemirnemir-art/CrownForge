class_name SpellEffect
extends Node2D

## Base class for all spell effects - must be overridden by specific implementations

var config: SpellConfig = null
var target_position: Vector2 = Vector2.ZERO

var damage_multiplier: float = 1.0
var radius_multiplier: float = 1.0

var _initialized: bool = false
var _executed: bool = false

func initialize(spell_config: SpellConfig, target_pos: Vector2) -> void:
	config = spell_config
	target_position = target_pos
	global_position = target_pos
	_initialized = true
	call_deferred("_try_execute")

func _ready() -> void:
	call_deferred("_try_execute")

func _try_execute() -> void:
	if _executed:
		return
	if not _initialized:
		return
	_executed = true
	execute_effect()

func get_scaled_damage(base_damage: float) -> float:
	return base_damage * damage_multiplier

func get_scaled_radius(base_radius: float) -> float:
	return base_radius * radius_multiplier

## Override this in child classes to implement spell behavior
func execute_effect() -> void:
	push_error("[SpellEffect] execute_effect() must be overridden in child class")
	queue_free()
