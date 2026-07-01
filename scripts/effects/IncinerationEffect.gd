extends SpellEffect

const SpellEnemyTrackerScript := preload("res://scripts/effects/shared/SpellEnemyTracker.gd")
const SpellDamageApplicatorScript := preload("res://scripts/effects/shared/SpellDamageApplicator.gd")

@onready var core_flash: Sprite2D = $CoreFlash
@onready var flame_north: Sprite2D = $FlameNorth
@onready var flame_east: Sprite2D = $FlameEast
@onready var flame_south: Sprite2D = $FlameSouth
@onready var flame_west: Sprite2D = $FlameWest

const DEFAULT_RADIUS: float = 80.0
const DEFAULT_DAMAGE: float = 600.0
const VISUAL_DURATION: float = 0.28

var _enemy_tracker: RefCounted = SpellEnemyTrackerScript.new()
var _damage_applicator: RefCounted = SpellDamageApplicatorScript.new()


func execute_effect() -> void:
	var radius := get_scaled_radius(_get_base_radius())
	var damage := get_scaled_damage(_get_base_damage())
	_deal_damage(radius, damage)
	_play_visuals(radius)
	_finish_after_visuals()


func _get_base_radius() -> float:
	if config != null and config.target_radius > 0.0:
		return config.target_radius
	return DEFAULT_RADIUS


func _get_base_damage() -> float:
	if config != null and config.damage > 0.0:
		return config.damage
	return DEFAULT_DAMAGE


func _deal_damage(radius: float, damage: float) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for enemy in _enemy_tracker.collect_tree_enemies_in_radius(tree.root, global_position, radius, true):
		var attack_id: int = Time.get_ticks_msec() + get_instance_id() + enemy.get_instance_id()
		_damage_applicator.apply_damage(enemy, damage, self, attack_id)


func _play_visuals(radius: float) -> void:
	var offset := maxf(24.0, radius * 0.55)
	var base_scale := maxf(0.75, radius / 64.0)
	var flame_scale := maxf(0.55, radius / 105.0)

	if core_flash != null:
		core_flash.scale = Vector2.ONE * base_scale * 0.75
		core_flash.modulate = Color(1.0, 0.95, 0.65, 0.92)
		var core_tween := create_tween()
		core_tween.parallel().tween_property(core_flash, "scale", Vector2.ONE * base_scale * 1.9, VISUAL_DURATION)
		core_tween.parallel().tween_property(core_flash, "modulate:a", 0.0, VISUAL_DURATION)

	_animate_flame(flame_north, Vector2(0.0, -offset), flame_scale, 0.0)
	_animate_flame(flame_east, Vector2(offset, 0.0), flame_scale, PI * 0.5)
	_animate_flame(flame_south, Vector2(0.0, offset), flame_scale, PI)
	_animate_flame(flame_west, Vector2(-offset, 0.0), flame_scale, PI * 1.5)


func _animate_flame(flame: Sprite2D, target_offset: Vector2, scale_factor: float, rotation_value: float) -> void:
	if flame == null:
		return
	flame.position = Vector2.ZERO
	flame.rotation = rotation_value
	flame.scale = Vector2.ONE * scale_factor * 0.55
	flame.modulate = Color(1.0, 0.48, 0.12, 0.88)
	var tween := create_tween()
	tween.parallel().tween_property(flame, "position", target_offset, VISUAL_DURATION)
	tween.parallel().tween_property(flame, "scale", Vector2.ONE * scale_factor * 1.35, VISUAL_DURATION)
	tween.parallel().tween_property(flame, "modulate:a", 0.0, VISUAL_DURATION)


func _finish_after_visuals() -> void:
	await get_tree().create_timer(VISUAL_DURATION + 0.02).timeout
	queue_free()
