extends SpellEffect

## Wrath spell - +30% move speed and attack speed on allies for 6 seconds
## with status icon support via StatusIconService.

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")

const BUFF_DURATION: float = 6.0
const SPEED_MULTIPLIER: float = 1.3  # +30%
const ATTACK_SPEED_MULTIPLIER: float = 1.3  # +30%
const ICON_PATH: String = "res://assets/vfx/spells/Wrath.png"
const ICON_OFFSET_Y: float = -55.0
const DEFAULT_RADIUS: float = 80.0

# Dictionary mapping instance_id -> data dict:
# { "ally_ref": WeakRef, "icon_ref": WeakRef, "applied_speed_mult": float, "applied_atk_mult": float }
var _affected_allies: Dictionary = {}

func execute_effect() -> void:
	if not detection_area or not detection_shape:
		push_error("[WrathEffect] Missing required nodes")
		queue_free()
		return

	if config:
		var shape := CircleShape2D.new()
		shape.radius = config.target_radius if config.target_radius > 0 else 80.0
		detection_shape.shape = shape

	# Must detect heroes (layer 4)
	detection_area.collision_mask = 4  # Heroes

	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_apply_buff()

	var duration := BUFF_DURATION
	if config != null and config.duration > 0.0:
		duration = config.duration
	await get_tree().create_timer(duration).timeout

	_remove_buff()
	queue_free()

func _apply_buff() -> void:
	for body in _collect_targets():
		if not body.is_in_group("hero"):
			continue

		var id := body.get_instance_id()
		if _affected_allies.has(id):
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
			body, ICON_PATH, "WrathIcon", ICON_OFFSET_Y
		)

		_affected_allies[id] = {
			"ally_ref": weakref(body),
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
	for node in tree.get_nodes_in_group("hero"):
		if not (node is Node2D):
			continue
		var hero := node as Node2D
		if not is_instance_valid(hero):
			continue
		if hero.global_position.distance_to(global_position) > radius:
			continue
		dedupe[hero.get_instance_id()] = hero

	for key in dedupe.keys():
		result.append(dedupe[key])

	return result

func _get_base_radius() -> float:
	if config != null and config.target_radius > 0.0:
		return config.target_radius
	return DEFAULT_RADIUS

func _remove_buff() -> void:
	for id in _affected_allies.keys():
		var data: Dictionary = _affected_allies[id]
		var ally := _get_object_from_weakref(data.get("ally_ref"))
		if ally != null and is_instance_valid(ally) and ally is Node2D:
			var applied_speed_mult := float(data.get("applied_speed_mult", 1.0))
			var applied_atk_mult := float(data.get("applied_atk_mult", 1.0))

			if "speed_multiplier" in ally and applied_speed_mult > 0.001:
				ally.speed_multiplier = maxf(0.01, float(ally.speed_multiplier) / applied_speed_mult)
			if "attack_speed_multiplier" in ally and applied_atk_mult > 0.001:
				ally.attack_speed_multiplier = maxf(0.01, float(ally.attack_speed_multiplier) / applied_atk_mult)

			StatusIconServiceScript.remove_status_icon(ally as Node2D, data.get("icon_ref"))
		else:
			# Ally is gone; try to clean up the icon anyway
			var icon_obj := _get_object_from_weakref(data.get("icon_ref"))
			if icon_obj != null and is_instance_valid(icon_obj) and icon_obj is Node:
				(icon_obj as Node).queue_free()

	_affected_allies.clear()

func _get_object_from_weakref(value: Variant) -> Object:
	if value == null:
		return null
	if not (value is WeakRef):
		return null
	return (value as WeakRef).get_ref() as Object
