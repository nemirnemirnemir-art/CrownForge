extends RefCounted
class_name HeroOnFieldBootstrap


func setup(hero_ref) -> void:
	setup_watchdog(hero_ref)


func setup_watchdog(hero) -> void:
	var watchdog_timer := hero.get_node_or_null("WatchdogTimer") as Timer
	if watchdog_timer == null:
		watchdog_timer = Timer.new()
		watchdog_timer.name = "WatchdogTimer"
		hero.add_child(watchdog_timer)
	watchdog_timer.wait_time = 1.0
	watchdog_timer.autostart = true
	var timeout_callback := Callable(self, "_on_watchdog_timeout").bind(hero)
	if not watchdog_timer.timeout.is_connected(timeout_callback):
		watchdog_timer.timeout.connect(timeout_callback)


func _on_watchdog_timeout(hero) -> void:
	if hero == null:
		return
	var debug_helper = hero.get("_debug")
	if debug_helper != null and debug_helper.has_method("check_stuck"):
		debug_helper.check_stuck()


func setup_visual_nodes(hero) -> void:
	hero.animation_sprite = hero.get_node_or_null("AnimationSprite2D")
	if not hero.animation_sprite:
		hero.animation_sprite = hero.get_node_or_null("AnimWalk")
	if not hero.animation_sprite:
		hero.animation_sprite = hero.get_node_or_null("AnimatedSprite2D")
	hero.health_bar = hero.get_node_or_null("HealthBar")
	if hero.health_bar:
		hero.health_bar.visible = false
	if hero.animation_sprite:
		hero.animation_sprite.visible = true


func setup_physics(hero) -> void:
	hero.collision_layer = 1
	var wall_layer_mask: int = 1 << (8 - 1)
	hero.collision_mask = 2 | wall_layer_mask


func setup_state_machine(hero):
	if hero._state_machine:
		return hero._state_machine
	var sm_node = hero.get_node_or_null("HeroStateMachine")
	if sm_node:
		hero._state_machine = sm_node
	return hero._state_machine


func initialize_runtime(hero, stats, movement, visuals, animations, combat_ai, health, state_machine) -> void:
	if String(hero.hero_id) == "":
		return
	visuals.hero_id = hero.hero_id
	if hero.patrol_center == Vector2.ZERO:
		hero.patrol_center = hero.global_position
	stats.determine_combat_type(hero.hero_id)
	if "default_projectile_scene" in hero and hero.default_projectile_scene != null:
		stats.projectile_scene = hero.default_projectile_scene
	movement.apply_speed_modifiers(stats, stats.is_melee if stats else true, hero.override_move_speed)
	_apply_intrinsic_speed_multiplier(hero, movement)
	if hero._projectile_scene_override != null:
		stats.projectile_scene = hero._projectile_scene_override
	animations.setup(hero, hero.animation_sprite, hero.hero_id, state_machine)
	combat_ai.setup(hero, stats)
	health.initialize(hero, hero.hero_id, hero.health_bar)
	var ac = hero.get_node_or_null("AttackComponent")
	if ac and ac.has_signal("hit_landed"):
		if not ac.hit_landed.is_connected(Callable(hero, "_on_hit_landed")):
			ac.hit_landed.connect(Callable(hero, "_on_hit_landed"))
	animations.start_initial_animation()
	_apply_overrides(hero, stats)
	_apply_building_upgrade_spawn_modifiers(hero, stats)
	var dog = hero.get_node_or_null("DogComponent")
	if dog and dog.has_method("check_and_spawn_dog"):
		dog.check_and_spawn_dog()


func _apply_overrides(hero, stats) -> void:
	if stats == null:
		return
	if hero.override_attack_range > 0:
		stats.attack_range = hero.override_attack_range
		stats.preferred_range = lerpf(stats.attack_range, stats.max_range, 0.7)
		stats.min_range = minf(stats.attack_range, maxf(20.0, stats.max_range * 0.5))
	if hero.override_projectile_speed > 0:
		stats.projectile_speed = hero.override_projectile_speed
	if hero.override_projectile_type != "":
		stats.projectile_type = hero.override_projectile_type
	if hero.override_move_speed > 0:
		hero.move_speed = hero.override_move_speed
	if "default_projectile_scene" in hero and hero.default_projectile_scene != null:
		stats.projectile_scene = hero.default_projectile_scene
		stats.is_melee = false
	elif "projectile_scene" in hero and hero.projectile_scene != null:
		stats.projectile_scene = hero.projectile_scene
		stats.is_melee = false


func _apply_building_upgrade_spawn_modifiers(hero, stats) -> void:
	## Apply building upgrade evasion chance and attack range modifiers at hero spawn.
	if stats == null:
		return
	var hero_id: String = String(hero.hero_id) if "hero_id" in hero else ""
	if hero_id == "":
		return
	var unit_id := _resolve_spawn_unit_id(hero_id)
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var upgrade_core := tree.root.get_node_or_null("BuildingUpgradeCore")
	if upgrade_core == null:
		return
	# Apply evasion chance from building upgrades (madman:0.35, pangolin:0.25)
	if upgrade_core.has_method("get_unit_stat_evasion_chance"):
		var evasion: float = float(upgrade_core.call("get_unit_stat_evasion_chance", unit_id))
		if evasion > 0.0:
			hero.evasion_chance = maxf(hero.evasion_chance, evasion)
	# Apply attack range multiplier from building upgrades (black_swordsman: x2.0)
	if upgrade_core.has_method("get_unit_stat_attack_range_multiplier"):
		var range_mult: float = float(upgrade_core.call("get_unit_stat_attack_range_multiplier", unit_id))
		if range_mult > 1.0:
			stats.attack_range *= range_mult
			stats.preferred_range = lerpf(stats.attack_range, stats.max_range, 0.7)
			stats.min_range = minf(stats.attack_range, maxf(20.0, stats.max_range * 0.5))


func _resolve_spawn_unit_id(hero_id: String) -> String:
	## Resolves base unit_id from hero_id (strips trailing _N instance suffixes).
	var id := hero_id.to_lower()
	if id.contains("_"):
		var parts := id.rsplit("_", true, 1)
		if parts.size() == 2 and String(parts[1]).is_valid_int():
			return String(parts[0])
	return id


func _apply_intrinsic_speed_multiplier(hero, movement) -> void:
	if hero == null or movement == null:
		return
	if not ("move_speed" in movement):
		return
	var multiplier := _get_intrinsic_speed_multiplier(String(hero.hero_id))
	if absf(multiplier - 1.0) <= 0.001:
		return
	movement.move_speed *= multiplier


func _get_intrinsic_speed_multiplier(hero_id: String) -> float:
	if hero_id == "":
		return 1.0
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return 1.0
	var hero_core := tree.root.get_node_or_null("HeroCore")
	if hero_core == null or not hero_core.has_method("get_hero"):
		return 1.0
	var hero_data: Variant = hero_core.call("get_hero", hero_id)
	if not (hero_data is Dictionary):
		return 1.0
	return float((hero_data as Dictionary).get("intrinsic_speed_multiplier", 1.0))
