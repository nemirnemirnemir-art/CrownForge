extends SpellEffect

const SpellEnemyTrackerScript := preload("res://scripts/effects/shared/SpellEnemyTracker.gd")
const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")

@onready var cast_pulse: Sprite2D = $CastPulse
@onready var cast_ring: Sprite2D = $CastRing

const FULL_FREEZE_DURATION: float = 1.0
const THAW_SLOW_DURATION: float = 8.0
const SLOW_MULTIPLIER: float = 0.75
const DEFAULT_RADIUS: float = 100.0
const ICON_PATH: String = "res://assets/vfx/spells/freeze.png"
const ICON_NAME: String = "FreezeIcon"
const ICON_OFFSET_Y: float = -55.0
const FREEZE_TINT: Color = Color(0.45, 0.75, 1.0, 1.0)
const FREEZE_LOCK_META: StringName = &"freeze_effect_lock_count"
const FREEZE_MODE_META: StringName = &"freeze_effect_saved_process_mode"

var _enemy_tracker: RefCounted = SpellEnemyTrackerScript.new()
var _affected: Dictionary = {}
var _radius: float = DEFAULT_RADIUS


func execute_effect() -> void:
	_radius = get_scaled_radius(_get_base_radius())
	_play_cast_visuals()
	_apply_to_targets()
	set_process(true)


func _process(delta: float) -> void:
	var expired_ids: Array[int] = []
	for raw_id in _affected.keys():
		var target_id := int(raw_id)
		var data: Dictionary = _affected[raw_id]
		var enemy := _get_enemy_from_data(data)
		if enemy == null or not is_instance_valid(enemy):
			expired_ids.append(target_id)
			continue
		if "is_dead" in enemy and bool(enemy.is_dead):
			_cleanup_target(enemy, data)
			expired_ids.append(target_id)
			continue

		if float(data.get("freeze_remaining", 0.0)) > 0.0:
			var freeze_remaining: float = float(data.get("freeze_remaining", 0.0)) - delta
			data["freeze_remaining"] = freeze_remaining
			_apply_tint(enemy, data, 0.85)
			if freeze_remaining <= 0.0:
				_release_freeze_lock(enemy)
				_start_slow_phase(enemy, data)
			continue

		var slow_remaining: float = float(data.get("slow_remaining", 0.0)) - delta
		data["slow_remaining"] = slow_remaining
		_apply_tint(enemy, data, 0.55)
		if slow_remaining <= 0.0:
			_cleanup_target(enemy, data)
			expired_ids.append(target_id)

	for target_id in expired_ids:
		_affected.erase(target_id)

	if _affected.is_empty():
		set_process(false)
		queue_free()


func _get_base_radius() -> float:
	if config != null and config.target_radius > 0.0:
		return config.target_radius
	return DEFAULT_RADIUS


func _apply_to_targets() -> void:
	var tree := get_tree()
	if tree == null:
		queue_free()
		return

	for enemy in _enemy_tracker.collect_tree_enemies_in_radius(tree.root, global_position, _radius, true):
		_apply_to_enemy(enemy)


func _apply_to_enemy(enemy: Node2D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var id := enemy.get_instance_id()
	if _affected.has(id):
		return

	_acquire_freeze_lock(enemy)
	var icon: Sprite2D = StatusIconServiceScript.add_status_icon(enemy, ICON_PATH, ICON_NAME, ICON_OFFSET_Y)
	_affected[id] = {
		"enemy_ref": weakref(enemy),
		"icon_ref": weakref(icon) if icon != null else null,
		"base_modulate": enemy.modulate,
		"freeze_remaining": FULL_FREEZE_DURATION,
		"slow_remaining": THAW_SLOW_DURATION,
		"slow_started": false,
		"applied_speed_mult": 1.0,
		"applied_attack_speed_mult": 1.0,
	}
	_apply_tint(enemy, _affected[id], 0.85)


func _start_slow_phase(enemy: Node2D, data: Dictionary) -> void:
	if bool(data.get("slow_started", false)):
		return
	data["slow_started"] = true
	if "speed_multiplier" in enemy:
		enemy.speed_multiplier = float(enemy.speed_multiplier) * SLOW_MULTIPLIER
		data["applied_speed_mult"] = SLOW_MULTIPLIER
	if "attack_speed_multiplier" in enemy:
		enemy.attack_speed_multiplier = float(enemy.attack_speed_multiplier) * SLOW_MULTIPLIER
		data["applied_attack_speed_mult"] = SLOW_MULTIPLIER
	_apply_tint(enemy, data, 0.55)


func _cleanup_target(enemy: Node2D, data: Dictionary) -> void:
	_release_freeze_lock(enemy)
	var applied_speed_mult := float(data.get("applied_speed_mult", 1.0))
	if applied_speed_mult > 0.001 and "speed_multiplier" in enemy:
		enemy.speed_multiplier = maxf(0.01, float(enemy.speed_multiplier) / applied_speed_mult)
	var applied_attack_speed_mult := float(data.get("applied_attack_speed_mult", 1.0))
	if applied_attack_speed_mult > 0.001 and "attack_speed_multiplier" in enemy:
		enemy.attack_speed_multiplier = maxf(0.01, float(enemy.attack_speed_multiplier) / applied_attack_speed_mult)

	var base_modulate: Variant = data.get("base_modulate", Color.WHITE)
	if base_modulate is Color:
		enemy.modulate = base_modulate as Color
	StatusIconServiceScript.remove_status_icon(enemy, data.get("icon_ref"))


func _play_cast_visuals() -> void:
	var visual_scale := maxf(0.8, _radius / 72.0)
	if cast_pulse != null:
		cast_pulse.scale = Vector2.ONE * visual_scale * 0.75
		cast_pulse.modulate = Color(0.62, 0.88, 1.0, 0.92)
		var pulse_tween := create_tween()
		pulse_tween.parallel().tween_property(cast_pulse, "scale", Vector2.ONE * visual_scale * 1.5, 0.35)
		pulse_tween.parallel().tween_property(cast_pulse, "modulate:a", 0.0, 0.35)
	if cast_ring != null:
		cast_ring.scale = Vector2.ONE * visual_scale
		cast_ring.modulate = Color(0.35, 0.72, 1.0, 0.5)
		var ring_tween := create_tween()
		ring_tween.parallel().tween_property(cast_ring, "scale", Vector2.ONE * visual_scale * 1.9, 0.45)
		ring_tween.parallel().tween_property(cast_ring, "modulate:a", 0.0, 0.45)


func _apply_tint(enemy: Node2D, data: Dictionary, amount: float) -> void:
	var base_modulate: Variant = data.get("base_modulate", Color.WHITE)
	if base_modulate is Color:
		enemy.modulate = (base_modulate as Color).lerp(FREEZE_TINT, amount)


func _acquire_freeze_lock(enemy: Node2D) -> void:
	var lock_count: int = 0
	if enemy.has_meta(FREEZE_LOCK_META):
		lock_count = int(enemy.get_meta(FREEZE_LOCK_META))
	if lock_count <= 0:
		enemy.set_meta(FREEZE_MODE_META, int(enemy.process_mode))
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.set_meta(FREEZE_LOCK_META, lock_count + 1)


func _release_freeze_lock(enemy: Node2D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if not enemy.has_meta(FREEZE_LOCK_META):
		return
	var lock_count: int = max(0, int(enemy.get_meta(FREEZE_LOCK_META)) - 1)
	if lock_count > 0:
		enemy.set_meta(FREEZE_LOCK_META, lock_count)
		return
	enemy.remove_meta(FREEZE_LOCK_META)
	if enemy.has_meta(FREEZE_MODE_META):
		var saved_mode: int = int(enemy.get_meta(FREEZE_MODE_META))
		enemy.process_mode = saved_mode
		enemy.remove_meta(FREEZE_MODE_META)


func _get_enemy_from_data(data: Dictionary) -> Node2D:
	var enemy_ref: Variant = data.get("enemy_ref")
	if not (enemy_ref is WeakRef):
		return null
	var obj: Object = (enemy_ref as WeakRef).get_ref()
	if obj == null or not (obj is Node2D):
		return null
	return obj as Node2D
