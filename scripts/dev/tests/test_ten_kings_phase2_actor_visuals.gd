extends SceneTree

const UnitScript := preload("res://scripts/dev/ten_kings/TenKingsUnit.gd")
const CardLib := preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_ten_kings_phase2_actor_visuals] %s" % message)
	_failed = true
	return false


func _run_test() -> void:
	await _test_troops_use_local_actor_scenes()
	await _test_buildings_keep_icon_visuals()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_phase2_actor_visuals] PASS")
	quit(0)


func _test_troops_use_local_actor_scenes() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var soldier := UnitScript.new()
	root.add_child(soldier)
	soldier.setup(CardLib.CARD_SOLDIER, 1, 0, 0, 0.0, 0)
	await process_frame

	var soldier_actor := soldier.get_node_or_null("Actor") as Node2D
	if not _assert_true(soldier_actor != null, "soldier must attach a prototype-local actor child"):
		root.queue_free()
		await process_frame
		return

	var soldier_walk := soldier_actor.get_node_or_null("WalkSprite") as AnimatedSprite2D
	var soldier_attack := soldier_actor.get_node_or_null("AttackSprite") as AnimatedSprite2D
	_assert_true(soldier_walk != null, "soldier actor must have a walk AnimatedSprite2D")
	_assert_true(soldier_attack != null, "soldier actor must have an attack AnimatedSprite2D")

	soldier.start_advancing()
	await process_frame
	_assert_true(soldier_walk.visible, "advancing soldier must show walk visual")
	_assert_true(soldier_walk.is_playing(), "advancing soldier walk visual must animate")
	_assert_true(not soldier_attack.visible, "advancing soldier must hide attack visual")

	soldier.start_fighting()
	await process_frame
	_assert_true(soldier_attack.visible, "fighting soldier must show attack visual")
	_assert_true(soldier_attack.is_playing(), "fighting soldier attack visual must animate")
	_assert_true(not soldier_walk.visible, "fighting soldier must hide walk visual")

	soldier.start_chasing_castle(Vector2(100.0, 0.0))
	await process_frame
	_assert_true(soldier_walk.visible, "chasing castle soldier must return to walk visual")

	soldier.take_damage(99999.0)
	await process_frame
	_assert_true(not soldier_actor.visible, "dead soldier actor must hide")

	var paladin := UnitScript.new()
	root.add_child(paladin)
	paladin.setup(CardLib.CARD_PALADIN, 1, 1, 0, 0.0, 0)
	await process_frame
	var paladin_actor := paladin.get_node_or_null("Actor") as Node2D
	_assert_true(paladin_actor != null, "paladin must attach a prototype-local actor child")
	if paladin_actor != null:
		_assert_true(paladin_actor.scale.x < 0.0, "AI troop actors must mirror horizontally")

	root.queue_free()
	await process_frame


func _test_buildings_keep_icon_visuals() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var farm := UnitScript.new()
	root.add_child(farm)
	farm.setup(CardLib.CARD_FARM, 1, 0, 0, 0.0, 0)
	await process_frame

	var building_actor := farm.get_node_or_null("Actor")
	var building_sprite := farm.get_node_or_null("IconSprite") as Sprite2D
	_assert_true(building_actor == null, "buildings must stay on the simple icon path")
	_assert_true(building_sprite != null, "buildings must keep their icon sprite")

	root.queue_free()
	await process_frame
