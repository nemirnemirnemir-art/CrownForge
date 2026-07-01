extends Area2D
class_name AggroArea

signal target_entered(target: Node2D)
signal target_exited(target: Node2D)

@export var max_targets: int = 8
@export var required_group: String = ""
@export var target_root_mode: int = 1 # 0=area_owner, 1=area_parent

var _targets: Array[Node2D] = []

func _ready() -> void:
	monitoring = true
	monitorable = false

	# Force correct collision_mask based on required_group
	# This overrides any scene configuration to ensure proper detection
	if required_group != "":
		if required_group == "hero":
			collision_mask = 1
			# print("[AggroArea] %s: collision_mask=1 (detecting heroes)" % get_parent().name)
		elif required_group == "enemy":
			collision_mask = 2
			# print("[AggroArea] %s: collision_mask=2 (detecting enemies)" % get_parent().name)

	# Ensure CollisionShape2D exists for Area2D to function
	_ensure_collision_shape()

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _ensure_collision_shape() -> void:
	# Check if any CollisionShape2D child exists
	for child in get_children():
		if child is CollisionShape2D:
			return
	
	# Create default detection shape
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 180.0
	cs.shape = shape
	add_child(cs)
	# print("[AggroArea] %s: Created default CircleShape2D (radius=180)" % get_parent().name)

func get_targets() -> Array[Node2D]:
	_cleanup()
	return _targets.duplicate()

func has_targets() -> bool:
	_cleanup()
	return not _targets.is_empty()

func get_best_target(from_pos: Vector2) -> Node2D:
	_cleanup()
	var best: Node2D = null
	var best_d := INF
	for t in _targets:
		if t == null or not is_instance_valid(t):
			continue
		var d := from_pos.distance_squared_to(t.global_position)
		if d < best_d:
			best_d = d
			best = t
	return best

func clear() -> void:
	_targets.clear()

func _cleanup() -> void:
	for i in range(_targets.size() - 1, -1, -1):
		var t := _targets[i]
		if t == null or not is_instance_valid(t):
			_targets.remove_at(i)
			continue
		if "is_dead" in t and bool(t.is_dead):
			_targets.remove_at(i)

func _area_to_target(area: Area2D) -> Node2D:
	if area == null:
		return null
	var n: Node = area
	if target_root_mode == 1:
		n = area.get_parent()
	if n is Node2D:
		return n
	return null

func _on_area_entered(area: Area2D) -> void:
	if not monitoring: return
	var t := _area_to_target(area)
	if t == null:
		return
	if required_group != "" and not t.is_in_group(required_group):
		return
	if _targets.has(t):
		return
	# Check if target is dead
	if "is_dead" in t and bool(t.is_dead):
		return
	if _targets.size() >= max_targets:
		return
	_targets.append(t)
	# print("[AggroArea] %s: DETECTED target %s (group=%s)" % [get_parent().name, t.name, required_group])
	target_entered.emit(t)

func _on_area_exited(area: Area2D) -> void:
	var t := _area_to_target(area)
	if t == null:
		return
	var idx := _targets.find(t)
	if idx != -1:
		_targets.remove_at(idx)
		target_exited.emit(t)
