extends SceneTree

const HeroIdleStateScript := preload("res://scripts/hero/states/HeroIdleState.gd")


class FakeMapMarkerService:
	extends Node

	var wall_position: Vector2 = Vector2.ZERO

	func get_wall_position() -> Vector2:
		return wall_position


class FakeWall:
	extends Node2D

	func get_world_rect() -> Rect2:
		return Rect2(Vector2(60.0, -200.0), Vector2(80.0, 400.0))


class FakeStateMachine:
	extends Node

	var changed: Array[String] = []

	func change_state(name: String) -> void:
		changed.append(name)


class FakeHero:
	extends Node2D

	var is_dead: bool = false
	var velocity: Vector2 = Vector2.ZERO
	var move_speed: float = 40.0
	var speed_multiplier: float = 1.0
	var patrol_center: Vector2 = Vector2.ZERO
	var patrol_box_size: Vector2 = Vector2(20.0, 20.0)
	var animation_sprite: AnimatedSprite2D = null
	var blocked: bool = false
	var _last_direction: Vector2 = Vector2.ZERO

	func _init() -> void:
		var collision_shape := CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = 15.0
		collision_shape.shape = shape
		add_child(collision_shape)

	func move_and_slide() -> bool:
		if not blocked:
			global_position += velocity * (1.0 / 60.0)
		return false

	func enforce_battlefield_bounds(desired_direction: Vector2 = Vector2.ZERO) -> Vector2:
		_last_direction = desired_direction
		return desired_direction

	func _update_animation(_name: String) -> void:
		pass


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var marker_service := FakeMapMarkerService.new()
	marker_service.name = "MapMarkerService"
	marker_service.wall_position = Vector2(100.0, 50.0)
	get_root().add_child(marker_service)

	var wall := FakeWall.new()
	wall.name = "Wall"
	wall.add_to_group("wall")
	get_root().add_child(wall)

	var host := Node.new()
	get_root().add_child(host)

	var hero := FakeHero.new()
	hero.global_position = Vector2(110.0, 50.0)
	hero.patrol_center = Vector2(110.0, 50.0)
	hero.patrol_box_size = Vector2(20.0, 20.0)
	host.add_child(hero)

	var state_machine := FakeStateMachine.new()
	host.add_child(state_machine)

	var state := HeroIdleStateScript.new()
	host.add_child(state)
	state.set_hero(hero)
	state.set_state_machine(state_machine)
	state.enter()
	state.update(1.1)

	var wander_target: Vector2 = state.get("_wander_target")
	if wander_target.x < 160.0:
		push_error("[test_hero_idle_state_wall_guard] wander target should stay clear of wall, got x=%.2f" % wander_target.x)
		quit(1)
		return

	wall.queue_free()
	marker_service.wall_position = Vector2.ZERO

	var marker_only_hero := FakeHero.new()
	marker_only_hero.global_position = Vector2(10.0, 0.0)
	marker_only_hero.patrol_center = Vector2(10.0, 0.0)
	marker_only_hero.patrol_box_size = Vector2(20.0, 20.0)
	host.add_child(marker_only_hero)

	var marker_only_state_machine := FakeStateMachine.new()
	host.add_child(marker_only_state_machine)

	var marker_only_state := HeroIdleStateScript.new()
	host.add_child(marker_only_state)
	marker_only_state.set_hero(marker_only_hero)
	marker_only_state.set_state_machine(marker_only_state_machine)
	marker_only_state.enter()
	marker_only_state.update(1.1)

	var marker_only_target: Vector2 = marker_only_state.get("_wander_target")
	if marker_only_target.x < 55.0:
		push_error("[test_hero_idle_state_wall_guard] marker fallback should allow wall at origin, got x=%.2f" % marker_only_target.x)
		quit(1)
		return

	marker_service.wall_position = Vector2(100.0, 50.0)
	var progress_hero := FakeHero.new()
	progress_hero.global_position = Vector2(170.0, 50.0)
	host.add_child(progress_hero)

	var progress_state_machine := FakeStateMachine.new()
	host.add_child(progress_state_machine)

	var progress_state := HeroIdleStateScript.new()
	host.add_child(progress_state)
	progress_state.set_hero(progress_hero)
	progress_state.set_state_machine(progress_state_machine)
	progress_state.enter()
	progress_state.set("_is_wandering", true)
	progress_state.set("_wander_target", Vector2(240.0, 50.0))
	for i in range(50):
		progress_state.physics_update(1.0 / 60.0)

	if not progress_state_machine.changed.is_empty():
		push_error("[test_hero_idle_state_wall_guard] valid wander progress should not trigger HeroSaveFromStackState")
		quit(1)
		return

	var blocked_hero := FakeHero.new()
	blocked_hero.global_position = Vector2(170.0, 50.0)
	blocked_hero.blocked = true
	host.add_child(blocked_hero)

	var blocked_state_machine := FakeStateMachine.new()
	host.add_child(blocked_state_machine)

	var blocked_state := HeroIdleStateScript.new()
	host.add_child(blocked_state)
	blocked_state.set_hero(blocked_hero)
	blocked_state.set_state_machine(blocked_state_machine)
	blocked_state.enter()
	blocked_state.set("_is_wandering", true)
	blocked_state.set("_wander_target", Vector2(240.0, 50.0))
	for i in range(4):
		blocked_state.physics_update(0.25)

	if blocked_state_machine.changed.is_empty() or blocked_state_machine.changed[-1] != "HeroSaveFromStackState":
		push_error("[test_hero_idle_state_wall_guard] blocked idle wandering should fall back to HeroSaveFromStackState")
		quit(1)
		return

	print("[test_hero_idle_state_wall_guard] PASS")
	quit(0)
