extends SceneTree


class ReplacementHost:
	extends RefCounted

	var spawn_calls: Array[Dictionary] = []
	var effect_calls: Array[Vector2] = []
	var replacement_exists: bool = true
	var live_position: Vector2 = Vector2.INF
	var stored_position: Vector2 = Vector2.INF

	func on_hero_auto_replaced(_dead_id: String, new_id: String) -> void:
		if not replacement_exists:
			return
		var death_pos: Vector2 = live_position
		if death_pos == Vector2.INF:
			death_pos = stored_position
		if death_pos != Vector2.INF:
			_spawn_rider_transform_effect(death_pos)
			spawn_hero_on_field(new_id, death_pos)
		else:
			spawn_hero_on_field(new_id)

	func spawn_hero_on_field(hero_id: String, override_position: Vector2 = Vector2.INF) -> void:
		spawn_calls.append({
			"hero_id": hero_id,
			"position": override_position,
		})

	func _spawn_rider_transform_effect(pos: Vector2) -> void:
		effect_calls.append(pos)


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	push_error("[test_rider_replacement_position_fallback] %s" % message)
	quit(1)


func _run_test() -> void:
	var host := ReplacementHost.new()
	host.live_position = Vector2.INF
	host.stored_position = Vector2(321.0, 654.0)

	host.on_hero_auto_replaced("dead_horseman", "rider_copy")

	if host.spawn_calls.size() != 1:
		_fail("replacement hero must be spawned exactly once")
		return

	var spawn_call: Dictionary = host.spawn_calls[0]
	if spawn_call.get("hero_id", "") != "rider_copy":
		_fail("replacement hero id mismatch")
		return
	if spawn_call.get("position", Vector2.INF) != host.stored_position:
		_fail("replacement hero must use stored death position when live position is unavailable")
		return
	if host.effect_calls != [host.stored_position]:
		_fail("transform effect must use the same fallback death position")
		return

	print("[test_rider_replacement_position_fallback] PASS")
	quit(0)
