extends SpellEffect

## Shields Up spell - reduces damage taken and slightly reduces movement speed
## for nearby allied heroes, with status icon support via StatusIconService.

const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")

const DEFENSE_MULTIPLIER: float = 0.7
const SPEED_MULTIPLIER: float = 0.85
const DEFAULT_DURATION: float = 8.0
const DEFAULT_RADIUS: float = 90.0
const ICON_PATH: String = "res://assets/vfx/spells/shields up.png"
const ICON_OFFSET_Y: float = -55.0

var _affected_units: Array[Dictionary] = []


func execute_effect() -> void:
	var radius: float = get_scaled_radius(_get_radius())
	var duration: float = _get_duration()

	_apply_buff(radius)

	await get_tree().create_timer(duration).timeout

	_remove_buff()
	queue_free()


func _get_radius() -> float:
	if config != null and config.target_radius > 0.0:
		return config.target_radius
	return DEFAULT_RADIUS


func _get_duration() -> float:
	if config != null and config.duration > 0.0:
		return config.duration
	return DEFAULT_DURATION


func _apply_buff(radius: float) -> void:
	var tree := get_tree()
	if tree == null:
		return

	var allies: Array = tree.get_nodes_in_group("hero")
	for ally_node in allies:
		if not (ally_node is Node2D):
			continue

		var ally := ally_node as Node2D
		if ally == null or not is_instance_valid(ally):
			continue
		if ally.global_position.distance_to(target_position) > radius:
			continue

		var snapshot := {}

		var old_damage_taken_variant: Variant = ally.get("damage_taken_multiplier")
		if old_damage_taken_variant != null:
			var old_damage_taken := float(old_damage_taken_variant)
			snapshot["damage_taken_multiplier"] = old_damage_taken
			ally.set("damage_taken_multiplier", old_damage_taken * DEFENSE_MULTIPLIER)

		var old_speed_variant: Variant = ally.get("speed_multiplier")
		if old_speed_variant != null:
			var old_speed := float(old_speed_variant)
			snapshot["speed_multiplier"] = old_speed
			ally.set("speed_multiplier", old_speed * SPEED_MULTIPLIER)

		if snapshot.is_empty():
			continue

		# Add status icon above the ally
		var icon: Sprite2D = StatusIconServiceScript.add_status_icon(
			ally, ICON_PATH, "ShieldsUpIcon", ICON_OFFSET_Y
		)

		_affected_units.append({
			"node": ally,
			"snapshot": snapshot,
			"icon_ref": weakref(icon) if icon != null else null,
		})


func _remove_buff() -> void:
	for entry in _affected_units:
		var ally := entry.get("node") as Node2D
		if ally == null or not is_instance_valid(ally):
			# Ally is gone; try to clean up the icon anyway
			var icon_obj := _resolve_icon_ref(entry.get("icon_ref"))
			if icon_obj != null and is_instance_valid(icon_obj):
				icon_obj.queue_free()
			continue

		# Remove the status icon and schedule deferred reflow
		StatusIconServiceScript.remove_status_icon(ally, entry.get("icon_ref"))

		# Restore snapshotted modifier values
		var snapshot: Dictionary = entry.get("snapshot", {}) as Dictionary

		if snapshot.has("damage_taken_multiplier"):
			ally.set("damage_taken_multiplier", float(snapshot["damage_taken_multiplier"]))

		if snapshot.has("speed_multiplier"):
			ally.set("speed_multiplier", float(snapshot["speed_multiplier"]))

	_affected_units.clear()


## Resolves a weakref to its underlying Node, or returns null.
func _resolve_icon_ref(value: Variant) -> Node:
	if value == null:
		return null
	if not (value is WeakRef):
		return null
	var obj: Object = (value as WeakRef).get_ref()
	if obj != null and obj is Node:
		return obj as Node
	return null
