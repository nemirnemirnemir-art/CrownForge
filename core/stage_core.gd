extends Node
## StageCore - Autoload singleton (no class_name needed)

const API_VERSION := 1

## State
var _current_stage: int = 1
var _max_stage_reached: int = 1
var _resetting: bool = false  # ✅ Flag to block advance_stage during reset

func _ready() -> void:
	# Subscribe to wave_completed event to advance stages
	EventBus.wave_completed.connect(_on_wave_completed)

func _on_wave_completed(_wave_number: int) -> void:
	advance_stage()

## === PUBLIC API ===

func get_current_stage() -> int:
	return _current_stage

func get_max_stage_reached() -> int:
	return _max_stage_reached

func is_milestone_stage(stage: int = -1) -> bool:
	if stage == -1:
		stage = _current_stage
	return stage % 10 == 0

func get_biome_name(stage: int = -1) -> String:
	if stage == -1:
		stage = _current_stage
	# ✅ All stages are named Forest 1, Forest 2, Forest 3, etc.
	return "Forest %d" % stage

func advance_stage() -> void:
	# ✅ Block during reset so mobs cannot call advance_stage
	if _resetting:
		# print("[StageCore] ⚠️ advance_stage blocked during reset")
		return
	
	_current_stage += 1
	if _current_stage > _max_stage_reached:
		_max_stage_reached = _current_stage
	EventBus.stage_changed.emit(_current_stage)
	# ✅ Auto-save on stage transition
	if SaveCore:
		SaveCore.request_save()

func set_stage(stage: int) -> void:
	stage = max(1, stage)
	if stage > _max_stage_reached:
		# Should we allow setting stage beyond max? Usually no, unless debugging.
		# For now, clamp it.
		stage = _max_stage_reached
	
	_current_stage = stage
	EventBus.stage_changed.emit(_current_stage)
	# ✅ Auto-save when stage changes
	if SaveCore:
		SaveCore.request_save()

func reset_progress() -> void:
	_resetting = true
	_max_stage_reached = 1
	_current_stage = 1
	EventBus.stage_changed.emit(_current_stage)
	_resetting = false

## === SAVE/LOAD ===

func get_save_data() -> Dictionary:
	return {
		"current_stage": _current_stage,
		"max_stage_reached": _max_stage_reached
	}

func load_save_data(data: Dictionary) -> void:
	var saved_stage = data.get("current_stage", 1)
	_max_stage_reached = data.get("max_stage_reached", 1)
	
	# ✅ Load at previous stage (safe zone) to avoid bugs/immediate difficult fights
	# As requested by user: load the previous zone after restarting the game
	_current_stage = max(1, int(saved_stage))
	
	# print("[StageCore] 🔄 Loading game. Saved stage: %d, Loaded stage: %d (Max reached: %d)" % [saved_stage, _current_stage, _max_stage_reached])
	
	# Safety check: ensure we don't exceed max reached
	# HARD: Ensure max_stage_reached is at least current_stage (sync fix)
	if _max_stage_reached < _current_stage:
		_max_stage_reached = _current_stage
		
	if _current_stage > _max_stage_reached:
		_current_stage = _max_stage_reached
		
	# Emit update
	EventBus.stage_changed.emit(_current_stage)

# === DEFORESTATION PERSISTENCE ===
# Dictionary[BiomeName, Array[Vector2]]
var _chopped_trees: Dictionary = {}

func mark_tree_chopped(biome_name: String, tree_pos: Vector2) -> void:
	if not _chopped_trees.has(biome_name):
		_chopped_trees[biome_name] = []
	
	# Store precise position (snapped to avoid float errors)
	var snapped_pos = tree_pos.snapped(Vector2(1, 1))
	if not snapped_pos in _chopped_trees[biome_name]:
		_chopped_trees[biome_name].append(snapped_pos)

func is_tree_chopped(biome_name: String, tree_pos: Vector2) -> bool:
	if not _chopped_trees.has(biome_name):
		return false
	var snapped_pos = tree_pos.snapped(Vector2(1, 1))
	return snapped_pos in _chopped_trees[biome_name]

# Override save data to include chopped trees
func get_save_data_full() -> Dictionary:
	var data = get_save_data()
	data["chopped_trees"] = _chopped_trees
	return data

func load_save_data_full(data: Dictionary) -> void:
	load_save_data(data)
	if data.has("chopped_trees"):
		_chopped_trees = data["chopped_trees"]

