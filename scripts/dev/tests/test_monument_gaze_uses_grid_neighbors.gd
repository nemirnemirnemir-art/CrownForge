extends SceneTree

const MonumentScript := preload("res://core/buildings/special/MonumentToKingsGaze.gd")
const MonumentConfig := preload("res://data/buildings/kingdom_infrastructure/monument_to_the_kings_gaze.tres")

var _failed: bool = false

class FakeSlot:
	extends Node2D

	var slot_index: int = -1
	var current_building_id: String = ""
	var external_calls: Array[String] = []
	var tick_calls: int = 0

	func _init(new_slot_index: int, pos: Vector2, building_id: String = "") -> void:
		slot_index = new_slot_index
		position = pos
		current_building_id = building_id

	func set_external_vzor_active(source_id: String, active: bool) -> void:
		external_calls.append("%s:%s" % [source_id, "on" if active else "off"])

	func tick_production(_delta: float) -> void:
		tick_calls += 1

class FakeMapLayout:
	extends Node

	var slots: Array = []

class FakeGameScene:
	extends Node

	var map_layout_node: Node = null

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_monument_gaze_uses_grid_neighbors] %s" % message)
	quit(1)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	if MonumentConfig == null:
		_fail("Monument config must load")
		return

	var center := FakeSlot.new(6, Vector2(420.0, 420.0), "monument_to_the_kings_gaze")
	var left := FakeSlot.new(5, Vector2(210.0, 420.0))
	var right := FakeSlot.new(7, Vector2(690.0, 420.0))
	var up := FakeSlot.new(1, Vector2(420.0, 180.0))
	var down := FakeSlot.new(11, Vector2(420.0, 730.0))
	var late_left := FakeSlot.new(15, Vector2(210.0, 420.0))
	var late_right := FakeSlot.new(16, Vector2(690.0, 420.0))
	var late_up := FakeSlot.new(17, Vector2(420.0, 180.0))
	var late_down := FakeSlot.new(18, Vector2(420.0, 730.0))
	var diagonal := FakeSlot.new(0, Vector2(200.0, 170.0))

	var map_layout := FakeMapLayout.new()
	map_layout.slots = [diagonal, up, left, center, right, down]

	var game_scene := FakeGameScene.new()
	game_scene.map_layout_node = map_layout
	game_scene.add_to_group("game_scene")
	get_root().add_child(game_scene)
	await process_frame

	var monument = MonumentScript.new()
	if monument == null:
		_fail("Monument special must instantiate")
		return
	monument.initialize(center, MonumentConfig)
	monument.set_vzor_active(true)
	await process_frame
	monument.tick(1.0)
	await process_frame

	for slot in [left, right, up, down]:
		if slot.external_calls.is_empty():
			_fail("Monument must activate all 4 orthogonal neighbors even on wider grid spacing")
			return

	if not diagonal.external_calls.is_empty():
		_fail("Monument must not activate diagonal neighbors")
		return

	var late_map_layout := FakeMapLayout.new()
	late_map_layout.slots = [center]
	game_scene.map_layout_node = late_map_layout
	await process_frame

	monument.set_vzor_active(false)
	monument.set_vzor_active(true)
	await process_frame

	late_map_layout.slots = [late_up, late_left, center, late_right, late_down]
	monument.tick(0.1)
	await process_frame

	for slot in [late_left, late_right, late_up, late_down]:
		if slot.external_calls.is_empty():
			_fail("Monument must refresh and activate orthogonal neighbors added after it is already active")
			return

	print("[test_monument_gaze_uses_grid_neighbors] PASS")
	quit(0)
