extends SpellEffect

## Weakness spell - applies -30% move speed and attack speed debuff on enemies
## with status icon support via StatusIconService.

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")

const DEBUFF_DURATION: float = 6.0
const SPEED_MULTIPLIER: float = 0.7  # -30%
const ATTACK_SPEED_MULTIPLIER: float = 0.7  # -30%
const ICON_PATH: String = "res://assets/vfx/spells/Weakness.png"
const ICON_OFFSET_Y: float = -55.0
const DEFAULT_RADIUS: float = 80.0

# Dictionary mapping instance_id -> data dict:
# { "enemy_ref": WeakRef, "icon_ref": WeakRef, "applied_speed_mult": float, "applied_atk_mult": float }
var _affected_enemies: Dictionary = {}

func execute_effect() -> void:
	if not detection_area or not detection_shape:
		push_error("[WeaknessEffect] Missing required nodes")
		queue_free()
		return

	if config:
		var shape := CircleShape2D.new()
		shape.radius = config.target_radius if config.target_radius > 0 else 80.0
		detection_shape.shape = shape

	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_apply_debuff()

	var duration := DEBUFF_DURATION
	if config != null and config.duration > 0.0:
		duration = config.duration
	await get_tree().create_timer(duration).timeout

	_remove_debuff()
	queue_free()

func _apply_debuff() -> void:
	for body in _collect_targets():
		if not _is_enemy(body):
			continue
		if "is_dead" in body and bool(body.is_dead):
			continue

		var id := body.get_instance_id()
		if _affected_enemies.has(id):
			continue

		var applied_speed_mult: float = 1.0
		var applied_atk_mult: float = 1.0

		if "speed_multiplier" in body:
			body.speed_multiplier = float(body.speed_multiplier) * SPEED_MULTIPLIER
			applied_speed_mult = SPEED_MULTIPLIER

		if "attack_speed_multiplier" in body:
			body.attack_speed_multiplier = float(body.attack_speed_multiplier) * ATTACK_SPEED_MULTIPLIER
			applied_atk_mult = ATTACK_SPEED_MULTIPLIER

		var icon: Sprite2D = StatusIconServiceScript.add_status_icon(
			body, ICON_PATH, "WeaknessIcon", ICON_OFFSET_Y
		)

		_affected_enemies[id] = {
			"enemy_ref": weakref(body),
			"icon_ref": weakref(icon) if icon != null else null,
			"applied_speed_mult": applied_speed_mult,
			"applied_atk_mult": applied_atk_mult,
		}

func _collect_targets() -> Array[Node2D]:
	var result: Array[Node2D] = []
	var dedupe := {}

	if detection_area != null:
		for body_any in detection_area.get_overlapping_bodies():
			if body_any is Node2D:
				var body := body_any as Node2D
				dedupe[body.get_instance_id()] = body

	var tree := get_tree()
	if tree == null:
		for key in dedupe.keys():
			result.append(dedupe[key])
		return result

	var radius := get_scaled_radius(_get_base_radius())
	var candidates: Array = tree.get_nodes_in_group("enemy")
	candidates.append_array(tree.get_nodes_in_group("mobs"))
	candidates.append_array(tree.get_nodes_in_group("enemies"))

	for node in candidates:
		if not (node is Node2D):
			continue
		var enemy := node as Node2D
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(global_position) > radius:
			continue
		dedupe[enemy.get_instance_id()] = enemy

	for key in dedupe.keys():
		result.append(dedupe[key])

	return result

func _get_base_radius() -> float:
	if config != null and config.target_radius > 0.0:
		return config.target_radius
	return DEFAULT_RADIUS

func _is_enemy(node: Node2D) -> bool:
	return node.is_in_group("enemy") or node.is_in_group("mobs") or node.is_in_group("enemies")

func _remove_debuff() -> void:
	for id in _affected_enemies.keys():
		var data: Dictionary = _affected_enemies[id]
		var enemy := _get_object_from_weakref(data.get("enemy_ref"))
		if enemy != null and is_instance_valid(enemy) and enemy is Node2D:
			var applied_speed_mult := float(data.get("applied_speed_mult", 1.0))
			var applied_atk_mult := float(data.get("applied_atk_mult", 1.0))

			if "speed_multiplier" in enemy and applied_speed_mult > 0.001:
				enemy.speed_multiplier = maxf(0.01, float(enemy.speed_multiplier) / applied_speed_mult)
			if "attack_speed_multiplier" in enemy and applied_atk_mult > 0.001:
				enemy.attack_speed_multiplier = maxf(0.01, float(enemy.attack_speed_multiplier) / applied_atk_mult)

			StatusIconServiceScript.remove_status_icon(enemy as Node2D, data.get("icon_ref"))
		else:
			# Enemy is gone; try to clean up the icon anyway
			var icon_obj := _get_object_from_weakref(data.get("icon_ref"))
			if icon_obj != null and is_instance_valid(icon_obj) and icon_obj is Node:
				(icon_obj as Node).queue_free()

	_affected_enemies.clear()

func _get_object_from_weakref(value: Variant) -> Object:
	if value == null:
		return null
	if not (value is WeakRef):
		return null
	return (value as WeakRef).get_ref() as Object
