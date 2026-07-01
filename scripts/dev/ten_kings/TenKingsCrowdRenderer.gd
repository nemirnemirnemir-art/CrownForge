extends Node2D
## Pooled renderer that syncs soldier visuals to crowd battle data.
## Manages visual instances efficiently by pooling and reusing them.

## Maximum number of visual instances to create
@export var max_visuals: int = 300

## Scene to instantiate for each soldier visual
@export var visual_scene: PackedScene

## Pool of inactive visual instances
var _pool: Array[Node2D] = []

## Active visuals mapped by soldier_id
var _active: Dictionary = {}  # soldier_id (int) -> TenKingsSoldierVisual

## Reference to the crowd runtime that provides soldier data
var _crowd_runtime: Node = null


func _ready() -> void:
	if visual_scene == null:
		visual_scene = preload("res://scenes/dev/ten_kings/TenKingsSoldierVisual.tscn")


func setup(crowd_runtime: Node) -> void:
	_crowd_runtime = crowd_runtime
	
	# Connect to runtime signals if available
	if _crowd_runtime.has_signal("soldier_died"):
		_crowd_runtime.soldier_died.connect(_on_soldier_died)
	if _crowd_runtime.has_signal("soldier_spawned"):
		_crowd_runtime.soldier_spawned.connect(_on_soldier_spawned)


func _process(_delta: float) -> void:
	if _crowd_runtime:
		sync_to_soldiers()


func sync_to_soldiers() -> void:
	if _crowd_runtime == null:
		return
	
	# Get living soldiers from runtime
	var soldiers: Array = _get_soldiers_from_runtime()
	
	# Track which soldiers we've seen this frame
	var seen_ids: Dictionary = {}
	
	for soldier_data in soldiers:
		var soldier_id: int = soldier_data.get("id", -1)
		if soldier_id < 0:
			continue
		
		seen_ids[soldier_id] = true
		
		var visual: Node2D
		if _active.has(soldier_id):
			# Update existing visual
			visual = _active[soldier_id]
		else:
			# Acquire new visual for this soldier
			visual = _acquire_visual()
			if visual == null:
				continue  # Pool exhausted
			
			_active[soldier_id] = visual
			
			# Setup visual for this soldier type
			var unit_type: StringName = soldier_data.get("unit_type", &"soldier")
			var team: int = soldier_data.get("team", 0)
			
			if visual.has_method("setup"):
				visual.setup(unit_type)
			if visual.has_method("set_team"):
				visual.set_team(team)
		
		# Update position and state
		var pos: Vector2 = soldier_data.get("position", Vector2.ZERO)
		var state: String = _map_runtime_state_to_visual_state(String(soldier_data.get("state", "idle")))
		
		if visual.has_method("set_soldier_position"):
			visual.set_soldier_position(pos)
		if visual.has_method("set_state"):
			visual.set_state(state)
	
	# Release visuals for soldiers no longer present
	var to_release: Array[int] = []
	for soldier_id in _active.keys():
		if not seen_ids.has(soldier_id):
			to_release.append(soldier_id)
	
	for soldier_id in to_release:
		var visual: Node2D = _active[soldier_id]
		_release_visual(visual)
		_active.erase(soldier_id)


func _get_soldiers_from_runtime() -> Array:
	# Try getting all living soldiers
	if _crowd_runtime.has_method("get_all_living_soldiers"):
		return _crowd_runtime.get_all_living_soldiers()
	
	# Fallback: get soldiers by team
	if _crowd_runtime.has_method("get_living_soldiers"):
		var all_soldiers: Array = []
		all_soldiers.append_array(_crowd_runtime.get_living_soldiers(0))  # Player
		all_soldiers.append_array(_crowd_runtime.get_living_soldiers(1))  # Enemy
		return all_soldiers
	
	return []


func _map_runtime_state_to_visual_state(runtime_state: String) -> String:
	match runtime_state:
		"idle":
			return "idle"
		"walking":
			return "walk"
		"attacking":
			return "attack"
		"dying", "dead":
			return "death"
		_:
			return "idle"


func _acquire_visual() -> Node2D:
	var visual: Node2D
	
	if _pool.size() > 0:
		# Get from pool
		visual = _pool.pop_back()
	else:
		# Create new if under limit
		var total_count: int = _active.size() + _pool.size()
		if total_count >= max_visuals:
			push_warning("[CrowdRenderer] Max visuals reached: ", max_visuals)
			return null
		
		if visual_scene == null:
			push_error("[CrowdRenderer] visual_scene is null")
			return null
		
		visual = visual_scene.instantiate()
		add_child(visual)
	
	visual.visible = true
	visual.process_mode = Node.PROCESS_MODE_INHERIT
	return visual


func _release_visual(visual: Node2D) -> void:
	if visual == null:
		return
	
	visual.visible = false
	visual.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Reset state
	if visual.has_method("set_state"):
		visual.set_state("idle")
	
	_pool.append(visual)


func cleanup() -> void:
	# Release all active visuals
	for soldier_id in _active.keys():
		var visual: Node2D = _active[soldier_id]
		_release_visual(visual)
	_active.clear()
	
	# Disconnect signals
	if _crowd_runtime:
		if _crowd_runtime.has_signal("soldier_died") and _crowd_runtime.soldier_died.is_connected(_on_soldier_died):
			_crowd_runtime.soldier_died.disconnect(_on_soldier_died)
		if _crowd_runtime.has_signal("soldier_spawned") and _crowd_runtime.soldier_spawned.is_connected(_on_soldier_spawned):
			_crowd_runtime.soldier_spawned.disconnect(_on_soldier_spawned)


func _on_soldier_died(soldier_id: int, _team: int) -> void:
	if _active.has(soldier_id):
		var visual: Node2D = _active[soldier_id]
		# Play death animation briefly before releasing
		if visual.has_method("set_state"):
			visual.set_state("death")
		_release_visual(visual)
		_active.erase(soldier_id)


func _on_soldier_spawned(soldier_data: Dictionary) -> void:
	# Soldier will be picked up in next sync_to_soldiers() call
	pass


func get_active_count() -> int:
	return _active.size()


func get_pool_count() -> int:
	return _pool.size()
