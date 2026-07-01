extends SpellEffect

## Quicksand spell - creates a persistent area that slows all enemies inside
## by 2x (speed_multiplier *= 0.5) for the duration (default 10s).
## Modeled after PoisonPuddleEffect: persistent zone with continuous tracking.
## Uses divide-out pattern for safe modifier removal (no hardcoded resets).

const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")

@onready var quicksand_anim: AnimatedSprite2D = $QuicksandAnim
@onready var slow_area: Area2D = $SlowArea
@onready var slow_shape: CollisionShape2D = $SlowArea/CollisionShape2D

const DEFAULT_DURATION: float = 10.0
const DEFAULT_RADIUS: float = 80.0
const SPEED_DEBUFF: float = 0.5  # 2x slow (multiply speed by 0.5)
const ICON_PATH: String = "res://assets/vfx/spells/Quicksand.png"
const ICON_NAME: String = "QuicksandIcon"
const ICON_OFFSET_Y: float = -55.0
const FADE_OUT_TIME: float = 0.5
const CHECK_INTERVAL: float = 0.2  # How often to scan for new/leaving enemies

var _duration_remaining: float = DEFAULT_DURATION
var _check_timer: float = 0.0
## Maps instance_id -> { "enemy_ref": WeakRef, "icon_ref": WeakRef, "applied_mult": float }
var _affected: Dictionary = {}


func execute_effect() -> void:
	if not slow_area or not slow_shape:
		push_error("[QuicksandEffect] Missing required nodes")
		queue_free()
		return

	# Configure collision radius from spell config
	if config:
		_duration_remaining = config.duration if config.duration > 0.0 else DEFAULT_DURATION
		var shape := CircleShape2D.new()
		shape.radius = _get_base_radius()
		slow_shape.shape = shape
	else:
		var default_shape := CircleShape2D.new()
		default_shape.radius = DEFAULT_RADIUS
		slow_shape.shape = default_shape

	slow_area.monitoring = true
	slow_area.monitorable = true

	# Play quicksand animation
	if quicksand_anim and quicksand_anim.sprite_frames:
		if quicksand_anim.sprite_frames.has_animation("quicksand"):
			quicksand_anim.play("quicksand")
		elif quicksand_anim.sprite_frames.has_animation("default"):
			quicksand_anim.play("default")

	await get_tree().process_frame
	await get_tree().physics_frame
	_update_affected_enemies()

	set_process(true)


func _process(delta: float) -> void:
	_duration_remaining -= delta
	_check_timer += delta

	# Periodically check for entering/leaving enemies
	if _check_timer >= CHECK_INTERVAL:
		_check_timer = 0.0
		_update_affected_enemies()

	# When duration expires, clean up
	if _duration_remaining <= 0.0:
		set_process(false)
		_remove_all_debuffs()
		_fade_and_destroy()


func _update_affected_enemies() -> void:
	if not slow_area:
		return

	var current_enemies := _collect_current_enemies()

	# Apply debuff to newly entered enemies
	for id in current_enemies.keys():
		if not _affected.has(id):
			_apply_debuff(current_enemies[id])

	# Remove debuff from enemies that left the zone
	var left_ids: Array[int] = []
	for id in _affected.keys():
		if not current_enemies.has(id):
			left_ids.append(int(id))

	for id in left_ids:
		_remove_debuff_from(id)


func _apply_debuff(enemy: Node2D) -> void:
	var id := enemy.get_instance_id()
	if _affected.has(id):
		return
	if enemy.get("speed_multiplier") == null:
		return

	# Multiply current speed_multiplier (divide-out safe)
	enemy.speed_multiplier = float(enemy.speed_multiplier) * SPEED_DEBUFF

	# Add status icon
	var icon: Sprite2D = StatusIconServiceScript.add_status_icon(
		enemy, ICON_PATH, ICON_NAME, ICON_OFFSET_Y
	)

	_affected[id] = {
		"enemy_ref": weakref(enemy),
		"icon_ref": weakref(icon) if icon != null else null,
		"applied_mult": SPEED_DEBUFF,
	}


func _remove_debuff_from(id: int) -> void:
	if not _affected.has(id):
		return

	var data: Dictionary = _affected[id]
	var enemy_obj := _get_object_from_weakref(data.get("enemy_ref"))

	if enemy_obj != null and is_instance_valid(enemy_obj) and enemy_obj is Node2D:
		var enemy := enemy_obj as Node2D
		if "speed_multiplier" in enemy:
			var applied_mult := float(data.get("applied_mult", 1.0))
			if applied_mult > 0.001:
				enemy.speed_multiplier = maxf(0.01, float(enemy.speed_multiplier) / applied_mult)

		# Remove icon
		StatusIconServiceScript.remove_status_icon(enemy, data.get("icon_ref"))

	_affected.erase(id)


func _remove_all_debuffs() -> void:
	for id in _affected.keys():
		var data: Dictionary = _affected[id]
		var enemy_obj := _get_object_from_weakref(data.get("enemy_ref"))

		if enemy_obj != null and is_instance_valid(enemy_obj) and enemy_obj is Node2D:
			var enemy := enemy_obj as Node2D
			if "speed_multiplier" in enemy:
				var applied_mult := float(data.get("applied_mult", 1.0))
				if applied_mult > 0.001:
					enemy.speed_multiplier = maxf(0.01, float(enemy.speed_multiplier) / applied_mult)

			# Remove icon and reflow
			var icon_node := _resolve_node_from_weakref(data.get("icon_ref"))
			if icon_node != null and is_instance_valid(icon_node):
				icon_node.queue_free()

			StatusIconServiceScript.schedule_deferred_reflow(enemy)

	_affected.clear()


func _fade_and_destroy() -> void:
	if quicksand_anim:
		var tween := create_tween()
		tween.tween_property(quicksand_anim, "modulate:a", 0.0, FADE_OUT_TIME)
		await tween.finished

	queue_free()


func _is_enemy(node: Node2D) -> bool:
	return node.is_in_group("enemy") or node.is_in_group("mobs") or node.is_in_group("enemies")


func _collect_current_enemies() -> Dictionary:
	var current_enemies: Dictionary = {}
	var overlaps: Array = []
	overlaps.append_array(slow_area.get_overlapping_bodies())

	for obj in overlaps:
		if not (obj is Node2D):
			continue
		var body := obj as Node2D
		if not _can_slow_enemy(body):
			continue
		current_enemies[body.get_instance_id()] = body

	var tree := get_tree()
	if tree == null:
		return current_enemies

	var radius := get_scaled_radius(_get_base_radius())
	var candidates: Array = tree.get_nodes_in_group("enemy")
	candidates.append_array(tree.get_nodes_in_group("mobs"))
	candidates.append_array(tree.get_nodes_in_group("enemies"))

	for node in candidates:
		if not (node is Node2D):
			continue
		var enemy := node as Node2D
		if not _can_slow_enemy(enemy):
			continue
		if enemy.global_position.distance_to(global_position) > radius:
			continue
		current_enemies[enemy.get_instance_id()] = enemy

	return current_enemies


func _can_slow_enemy(node: Node2D) -> bool:
	if not _is_enemy(node):
		return false
	if "is_dead" in node and bool(node.is_dead):
		return false
	return node.get("speed_multiplier") != null


func _get_base_radius() -> float:
	if config != null and config.target_radius > 0.0:
		return config.target_radius
	return DEFAULT_RADIUS




func _get_object_from_weakref(value: Variant) -> Object:
	if value == null:
		return null
	if not (value is WeakRef):
		return null
	return (value as WeakRef).get_ref() as Object


func _resolve_node_from_weakref(value: Variant) -> Node:
	var obj := _get_object_from_weakref(value)
	if obj != null and obj is Node:
		return obj as Node
	return null
