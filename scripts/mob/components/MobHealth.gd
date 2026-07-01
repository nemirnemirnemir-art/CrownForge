extends Node
class_name MobHealth

signal died

@export_group("Health Config")
@export var base_max_health: float = 10.0
@export var scale_with_stage: bool = true
@export var stage_health_multiplier: float = 1.0
@export var fixed_max_health: float = 0.0

var current_health: float = 10.0
var max_health: float = 10.0
var is_dead: bool = false

var is_stunned: bool = false
var stun_timer: float = 0.0

var _mob: Node2D
var _health_bar: Control
var _health_bar_fill: ColorRect

func setup(mob: Node2D) -> void:
	_mob = mob
	_health_bar = mob.get_node_or_null("HealthBar")
	_health_bar_fill = mob.get_node_or_null("HealthBar/Fill")
	if _health_bar:
		_health_bar.visible = false
	_initialize_health()
	update_health_bar()

func _initialize_health() -> void:
	if fixed_max_health > 0.0:
		max_health = fixed_max_health
	else:
		var stage: int = 1
		var stage_core := _get_singleton("StageCore")
		if stage_core and stage_core.has_method("get_current_stage"):
			stage = stage_core.get_current_stage()
		
		if scale_with_stage:
			max_health = base_max_health + (float(stage - 1) * stage_health_multiplier)
		else:
			max_health = base_max_health
	
	current_health = max_health

func _process(delta: float) -> void:
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			_set_mob_speed_scale(1.0)
		else:
			_set_mob_speed_scale(0.0)

func take_damage(amount: float, is_crit: bool = false) -> void:
	if is_dead: return
	current_health -= amount
	update_health_bar()
	
	var damage_popup_pool := _get_singleton("DamagePopupPool")
	if damage_popup_pool != null and is_instance_valid(damage_popup_pool) and damage_popup_pool.has_method("show_damage"):
		damage_popup_pool.show_damage(_mob.global_position, int(amount), is_crit)
	
	UnitDamageFlash.flash_from_node(_mob)
	
	if current_health <= 0:
		die()

func apply_stun(duration: float) -> void:
	is_stunned = true
	stun_timer = duration
	_set_mob_speed_scale(0.0)

func _set_mob_speed_scale(scale_val: float) -> void:
	if _mob.has_node("AnimationSprite2D"):
		_mob.get_node("AnimationSprite2D").speed_scale = scale_val

func update_health_bar() -> void:
	if _health_bar_fill:
		var percent = clamp(current_health / max_health, 0.0, 1.0)
		_health_bar_fill.pivot_offset = Vector2.ZERO
		_health_bar_fill.scale = Vector2(percent, 1.0)

func die() -> void:
	if is_dead: return
	is_dead = true
	current_health = 0
	update_health_bar()
	if _health_bar: _health_bar.visible = false
	died.emit()

func _get_singleton(name: String) -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(name)
