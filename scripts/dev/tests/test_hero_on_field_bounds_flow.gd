extends SceneTree

const BoundsFlowScript := preload("res://scripts/hero/modules/HeroOnFieldBoundsFlow.gd")


class FakeMovement:
	extends RefCounted

	var map_bounds: Rect2 = Rect2()
	var bounced: Vector2 = Vector2.LEFT

	func set_map_bounds(bounds: Rect2) -> void:
		map_bounds = bounds

	func get_bounce_direction(_clamped: Vector2, _desired: Vector2) -> Vector2:
		return bounced


class FakeStateMachine:
	extends RefCounted

	var changed: Array[String] = []

	func change_state(name: String) -> void:
		changed.append(name)


class FakeHero:
	extends RefCounted

	var global_position: Vector2 = Vector2(120, 50)
	var velocity: Vector2 = Vector2.RIGHT
	var _bounds_hit_count: int = 0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = BoundsFlowScript.new()
	if flow == null:
		push_error("[test_hero_on_field_bounds_flow] failed to instantiate helper")
		quit(1)
		return

	var hero := FakeHero.new()
	var movement := FakeMovement.new()
	var state_machine := FakeStateMachine.new()
	flow.setup(hero)

	flow.set_map_bounds(movement, Rect2(0, 0, 100, 100))
	if flow.get_map_bounds(movement).size != Vector2(100, 100):
		push_error("[test_hero_on_field_bounds_flow] map bounds not stored")
		quit(1)
		return

	var bounced: Vector2 = flow.enforce_battlefield_bounds(movement, state_machine, Vector2.RIGHT, 3)
	if hero.global_position.x != 100.0:
		push_error("[test_hero_on_field_bounds_flow] hero must be clamped to map bounds")
		quit(1)
		return
	if bounced != Vector2.LEFT:
		push_error("[test_hero_on_field_bounds_flow] bounce direction mismatch")
		quit(1)
		return

	hero.global_position = Vector2(130, 50)
	hero._bounds_hit_count = 2
	bounced = flow.enforce_battlefield_bounds(movement, state_machine, Vector2.RIGHT, 3)
	if state_machine.changed.is_empty() or state_machine.changed[-1] != "HeroBoundsRetreatState":
		push_error("[test_hero_on_field_bounds_flow] repeated bounds hits must trigger retreat")
		quit(1)
		return
	if bounced != Vector2.ZERO:
		push_error("[test_hero_on_field_bounds_flow] retreat path must zero direction")
		quit(1)
		return

	print("[test_hero_on_field_bounds_flow] PASS")
	quit(0)
