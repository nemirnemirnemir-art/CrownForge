## Test: TenKingsPrototype exposes arena anchors and TenKingsBattleManager can consume them.
extends SceneTree


func _init() -> void:
	print("Running TenKingsPrototype arena anchor contract tests...")
	var passed: int = 0
	var failed: int = 0

	# Test 1: Scene exposes arena anchor container
	if _test_scene_has_anchor_container():
		print("  PASS: test_scene_has_anchor_container")
		passed += 1
	else:
		print("  FAIL: test_scene_has_anchor_container")
		failed += 1

	# Test 2: Arena anchors include player front/ranged/back
	if _test_player_anchors_exist():
		print("  PASS: test_player_anchors_exist")
		passed += 1
	else:
		print("  FAIL: test_player_anchors_exist")
		failed += 1

	# Test 3: Arena anchors include AI front/ranged/back
	if _test_ai_anchors_exist():
		print("  PASS: test_ai_anchors_exist")
		passed += 1
	else:
		print("  FAIL: test_ai_anchors_exist")
		failed += 1

	# Test 4: Castle contact anchors exist
	if _test_castle_contact_anchors_exist():
		print("  PASS: test_castle_contact_anchors_exist")
		passed += 1
	else:
		print("  FAIL: test_castle_contact_anchors_exist")
		failed += 1

	# Test 5: Prototype can resolve anchors to positions
	if _test_prototype_resolves_anchors():
		print("  PASS: test_prototype_resolves_anchors")
		passed += 1
	else:
		print("  FAIL: test_prototype_resolves_anchors")
		failed += 1

	# Test 6: Battle manager can accept anchor positions
	if _test_battle_manager_accepts_anchors():
		print("  PASS: test_battle_manager_accepts_anchors")
		passed += 1
	else:
		print("  FAIL: test_battle_manager_accepts_anchors")
		failed += 1

	# Test 7: Anchors are inside the corridor (between board edges)
	if _test_anchors_inside_corridor():
		print("  PASS: test_anchors_inside_corridor")
		passed += 1
	else:
		print("  FAIL: test_anchors_inside_corridor")
		failed += 1

	print("")
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(failed)


func _load_scene() -> Node:
	var scene: PackedScene = load("res://scenes/dev/TenKingsPrototype.tscn")
	if scene == null:
		return null
	return scene.instantiate()


func _test_scene_has_anchor_container() -> bool:
	var proto := _load_scene()
	if proto == null:
		return false

	var battle_layer: Node2D = proto.get_node_or_null("BattleLayer")
	if battle_layer == null:
		proto.free()
		return false

	var anchors: Node = battle_layer.get_node_or_null("ArenaAnchors")
	var result: bool = anchors != null
	proto.free()
	return result


func _test_player_anchors_exist() -> bool:
	var proto := _load_scene()
	if proto == null:
		return false

	var anchors: Node = proto.get_node_or_null("BattleLayer/ArenaAnchors")
	if anchors == null:
		proto.free()
		return false

	var front: Node2D = anchors.get_node_or_null("PlayerFrontAnchor")
	var ranged: Node2D = anchors.get_node_or_null("PlayerRangedAnchor")
	var back: Node2D = anchors.get_node_or_null("PlayerBackAnchor")

	var result: bool = front != null and ranged != null and back != null
	proto.free()
	return result


func _test_ai_anchors_exist() -> bool:
	var proto := _load_scene()
	if proto == null:
		return false

	var anchors: Node = proto.get_node_or_null("BattleLayer/ArenaAnchors")
	if anchors == null:
		proto.free()
		return false

	var front: Node2D = anchors.get_node_or_null("AiFrontAnchor")
	var ranged: Node2D = anchors.get_node_or_null("AiRangedAnchor")
	var back: Node2D = anchors.get_node_or_null("AiBackAnchor")

	var result: bool = front != null and ranged != null and back != null
	proto.free()
	return result


func _test_castle_contact_anchors_exist() -> bool:
	var proto := _load_scene()
	if proto == null:
		return false

	var anchors: Node = proto.get_node_or_null("BattleLayer/ArenaAnchors")
	if anchors == null:
		proto.free()
		return false

	var player_castle: Node2D = anchors.get_node_or_null("PlayerCastleContactAnchor")
	var ai_castle: Node2D = anchors.get_node_or_null("AiCastleContactAnchor")

	var result: bool = player_castle != null and ai_castle != null
	proto.free()
	return result


func _test_prototype_resolves_anchors() -> bool:
	var proto := _load_scene()
	if proto == null:
		return false

	# Prototype should have a method to get arena anchor positions
	if not proto.has_method("get_arena_anchors"):
		proto.free()
		return false

	var anchors: Dictionary = proto.call("get_arena_anchors")
	proto.free()

	# Should have player and AI formation anchor positions
	if not anchors.has("player_front") or not anchors.has("ai_front"):
		return false
	if not anchors.has("player_castle_contact") or not anchors.has("ai_castle_contact"):
		return false

	return true


func _test_battle_manager_accepts_anchors() -> bool:
	var BattleManager = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
	var manager := BattleManager.new()

	# Manager should have a method to set arena anchors
	var has_method: bool = manager.has_method("set_arena_anchors")
	manager.free()
	return has_method


func _test_anchors_inside_corridor() -> bool:
	var proto := _load_scene()
	if proto == null:
		return false

	if not proto.has_method("get_arena_anchors"):
		proto.free()
		return false

	var anchors: Dictionary = proto.call("get_arena_anchors")
	proto.free()

	# Player board ends at x=430, AI board starts at x=610 (in UI space)
	# In BattleLayer (world space), the corridor center is around x=520
	# Player front should be negative x (left side), AI front should be positive x (right side)

	var player_front: Variant = anchors.get("player_front")
	var ai_front: Variant = anchors.get("ai_front")

	if not (player_front is Vector2) or not (ai_front is Vector2):
		return false

	# Player anchors should have negative x (left of center)
	# AI anchors should have positive x (right of center)
	return player_front.x < 0 and ai_front.x > 0
