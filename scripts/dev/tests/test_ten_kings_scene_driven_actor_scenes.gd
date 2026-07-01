extends SceneTree

const UnitScript := preload("res://scripts/dev/ten_kings/TenKingsUnit.gd")
const CardLib := preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_ten_kings_scene_driven_actor_scenes] %s" % message)
	_failed = true
	return false


func _run_test() -> void:
	await _test_actor_scenes_keep_their_own_sprite_frames()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_scene_driven_actor_scenes] PASS")
	quit(0)


func _test_actor_scenes_keep_their_own_sprite_frames() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	await _assert_actor_frames(root, CardLib.CARD_SOLDIER, 6, 8, 7.0, 8.0)
	await _assert_actor_frames(root, CardLib.CARD_ARCHER, 4, 8, 5.0, 8.0)
	await _assert_actor_frames(root, CardLib.CARD_PALADIN, 6, 6, 6.0, 7.0)

	root.queue_free()
	await process_frame


func _assert_actor_frames(root: Node2D, card_id: StringName, walk_frames: int, attack_frames: int, walk_speed: float, attack_speed: float) -> void:
	var unit := UnitScript.new()
	root.add_child(unit)
	unit.setup(card_id, 1, 0, 0, 0.0, 0)
	await process_frame

	var actor := unit.get_node_or_null("Actor") as Node2D
	if not _assert_true(actor != null, "%s must instantiate an Actor child" % card_id):
		return

	var walk_sprite := actor.get_node_or_null("WalkSprite") as AnimatedSprite2D
	var attack_sprite := actor.get_node_or_null("AttackSprite") as AnimatedSprite2D
	if not _assert_true(walk_sprite != null, "%s actor must provide WalkSprite" % card_id):
		return
	if not _assert_true(attack_sprite != null, "%s actor must provide AttackSprite" % card_id):
		return

	var walk_resource := walk_sprite.sprite_frames
	var attack_resource := attack_sprite.sprite_frames
	if not _assert_true(walk_resource != null, "%s WalkSprite must keep scene SpriteFrames" % card_id):
		return
	if not _assert_true(attack_resource != null, "%s AttackSprite must keep scene SpriteFrames" % card_id):
		return

	_assert_true(walk_resource.get_frame_count(&"default") == walk_frames, "%s walk frame count must come from the scene" % card_id)
	_assert_true(attack_resource.get_frame_count(&"default") == attack_frames, "%s attack frame count must come from the scene" % card_id)
	_assert_true(is_equal_approx(walk_resource.get_animation_speed(&"default"), walk_speed), "%s walk speed must come from the scene" % card_id)
	_assert_true(is_equal_approx(attack_resource.get_animation_speed(&"default"), attack_speed), "%s attack speed must come from the scene" % card_id)
