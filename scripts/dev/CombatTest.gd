extends Node2D

const HeroSceneRegistryScript = preload("res://scripts/hero/HeroSceneRegistry.gd")

const MobBat: PackedScene = preload("res://scenes/mobs/GoblinBatRider.tscn")
const MobMushroom: PackedScene = preload("res://scenes/mobs/GoblinBandit.tscn")
const MobGreenSlime: PackedScene = preload("res://scenes/mobs/BlueSlime.tscn")
const MobLizard: PackedScene = preload("res://scenes/mobs/GoblinLizard.tscn")
const MobMiniDrake: PackedScene = preload("res://scenes/mobs/GoblinFireMage.tscn")
const MobWoodenBoy: PackedScene = preload("res://scenes/mobs/StoneGolem.tscn")

@onready var world: Node2D = $World
@onready var heroes_container: Node2D = $World/Heroes
@onready var mob_container: Node2D = $World/Mobs
@onready var nav_region: NavigationRegion2D = $World/NavigationRegion2D
@onready var ui: CanvasLayer = $UI
@onready var camera: Camera2D = $Camera2D

@onready var hero_option: OptionButton = $UI/Panel/VBox/HeroRow/HeroOption
@onready var add_hero_btn: Button = $UI/Panel/VBox/HeroRow/AddHero
@onready var clear_btn: Button = $UI/Panel/VBox/ClearRow/ClearAll

@onready var bat_spin: SpinBox = $UI/Panel/VBox/MobRowBat/Count
@onready var bat_btn: Button = $UI/Panel/VBox/MobRowBat/Spawn
@onready var mush_spin: SpinBox = $UI/Panel/VBox/MobRowMushroom/Count
@onready var mush_btn: Button = $UI/Panel/VBox/MobRowMushroom/Spawn
@onready var slime_spin: SpinBox = $UI/Panel/VBox/MobRowGreenSlime/Count
@onready var slime_btn: Button = $UI/Panel/VBox/MobRowGreenSlime/Spawn
@onready var lizard_spin: SpinBox = $UI/Panel/VBox/MobRowLizard/Count
@onready var lizard_btn: Button = $UI/Panel/VBox/MobRowLizard/Spawn
@onready var drake_spin: SpinBox = $UI/Panel/VBox/MobRowMiniDrake/Count
@onready var drake_btn: Button = $UI/Panel/VBox/MobRowMiniDrake/Spawn
@onready var wooden_spin: SpinBox = $UI/Panel/VBox/MobRowWoodenBoy/Count
@onready var wooden_btn: Button = $UI/Panel/VBox/MobRowWoodenBoy/Spawn

var map_bounds: Rect2 = Rect2(-500, -300, 1000, 600)

func _ready() -> void:
	add_to_group("game_scene")
	_randomize_bounds_from_nav()
	_center_camera_on_bounds()
	_setup_ui()

func _randomize_bounds_from_nav() -> void:
	if not nav_region or not nav_region.navigation_polygon:
		return
	var verts: PackedVector2Array = nav_region.navigation_polygon.get_vertices()
	if verts.is_empty():
		return
	var min_x := verts[0].x
	var max_x := verts[0].x
	var min_y := verts[0].y
	var max_y := verts[0].y
	for v in verts:
		if v.x < min_x:
			min_x = v.x
		if v.x > max_x:
			max_x = v.x
		if v.y < min_y:
			min_y = v.y
		if v.y > max_y:
			max_y = v.y
	var size = Vector2(max_x - min_x, max_y - min_y)
	map_bounds = Rect2(nav_region.global_position + Vector2(min_x, min_y), size)

func _center_camera_on_bounds() -> void:
	if not camera:
		return
	var center := map_bounds.position + map_bounds.size * 0.5
	camera.position = center

func _setup_ui() -> void:
	hero_option.clear()
	var base_ids: Array[String] = []
	if HeroCore and HeroCore.query:
		for id in HeroCore.heroes.keys():
			base_ids.append(String(id))
	base_ids.sort()
	for id in base_ids:
		hero_option.add_item(id)
	if hero_option.item_count == 0:
		hero_option.add_item("slinger")

	add_hero_btn.pressed.connect(_on_add_hero)
	clear_btn.pressed.connect(_on_clear_all)

	bat_btn.pressed.connect(func(): _spawn_mobs(MobBat, int(bat_spin.value)))
	mush_btn.pressed.connect(func(): _spawn_mobs(MobMushroom, int(mush_spin.value)))
	slime_btn.pressed.connect(func(): _spawn_mobs(MobGreenSlime, int(slime_spin.value)))
	lizard_btn.pressed.connect(func(): _spawn_mobs(MobLizard, int(lizard_spin.value)))
	drake_btn.pressed.connect(func(): _spawn_mobs(MobMiniDrake, int(drake_spin.value)))
	wooden_btn.pressed.connect(func(): _spawn_mobs(MobWoodenBoy, int(wooden_spin.value)))

func _on_add_hero() -> void:
	var hero_id := hero_option.get_item_text(hero_option.selected)
	_ensure_hero_exists(hero_id)

	# IMPORTANT: If we spawn multiple nodes with the same hero_id, they will share the same
	# entry in HeroCore.heroes -> looks like "one mob hit damages all".
	# In the real game flow this is avoided by hiring unique copies.
	var spawn_id := _ensure_unique_spawn_id(hero_id)

	if HeroCore:
		if spawn_id != hero_id and HeroCore.has_method("create_hero"):
			# Create a lightweight copy for testing purposes.
			# Keep icon_id as base hero_id so visuals/combat type detection remain correct.
			if not (HeroCore.query and HeroCore.query.has_hero(spawn_id)):
				HeroCore.create_hero(spawn_id, hero_id.capitalize(), hero_id, 0.0)

		if HeroCore.has_method("add_to_squad"):
			HeroCore.add_to_squad(spawn_id)

	_spawn_hero(spawn_id)

func _ensure_unique_spawn_id(base_id: String) -> String:
	var id_l := base_id.to_lower()
	# If this base_id is already present in the current test scene, create a unique id.
	for child in heroes_container.get_children():
		if child and is_instance_valid(child) and child.has_method("get"):
			var child_id = str(child.get("hero_id"))
			if child_id.to_lower() == id_l:
				return _make_unique_test_id(base_id)
	return base_id

func _make_unique_test_id(base_id: String) -> String:
	var attempt := 0
	while attempt < 50:
		var new_id := "%s_test_%d" % [base_id.to_lower(), int(Time.get_unix_time_from_system() * 1000) + randi() % 1000]
		if not HeroCore or not (HeroCore.query and HeroCore.query.has_hero(new_id)):
			return new_id
		attempt += 1
	return "%s_test_%d" % [base_id.to_lower(), int(Time.get_unix_time_from_system() * 1000)]

func _ensure_hero_exists(hero_id: String) -> void:
	if not HeroCore:
		return
	if HeroCore.query and HeroCore.query.has_hero(hero_id):
		return
	if HeroCore.has_method("create_hero"):
		HeroCore.create_hero(hero_id, hero_id.capitalize(), hero_id, 0.0)

func _spawn_hero(hero_id: String) -> void:
	var scene_to_use: PackedScene = HeroSceneRegistryScript.load_scene(hero_id)

	if not scene_to_use:
		var resolved_id := HeroSceneRegistryScript.resolve_unit_id(hero_id)
		push_error("[CombatTest] Unknown hero_id for spawning: %s (resolved unit: %s)" % [hero_id, resolved_id])
		return

	var h: Node2D = scene_to_use.instantiate()
	heroes_container.add_child(h)
	if h.has_method("initialize"):
		h.initialize(hero_id)
	if h.has_method("set"):
		h.set("bridge_position", _get_bridge_pos())
	h.global_position = _get_hero_spawn_pos()

func _get_bridge_pos() -> Vector2:
	return world.global_position + Vector2(-250, 0)

func _get_hero_spawn_pos() -> Vector2:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var base = _get_bridge_pos()
	return base + Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20))

func _spawn_mobs(scene: PackedScene, count: int) -> void:
	if not scene or count <= 0:
		return
	for i in count:
		var m: Node = scene.instantiate()
		mob_container.add_child(m)
		if m.has_method("set_map_bounds"):
			m.set_map_bounds(_local_bounds_to_world())
		if m.has_method("set_behavior_target"):
			m.set_behavior_target("portal")
		if m is Node2D:
			(m as Node2D).global_position = _get_mob_spawn_pos(i)

func _get_mob_spawn_pos(i: int) -> Vector2:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var base = world.global_position + Vector2(250, 0)
	return base + Vector2(rng.randf_range(-60, 60), rng.randf_range(-60, 60)) + Vector2(0, float(i) * 10.0)

func _local_bounds_to_world() -> Rect2:
	return map_bounds

func _on_clear_all() -> void:
	for container in [heroes_container, mob_container]:
		for child in container.get_children():
			child.queue_free()

# === GameScene compatibility helpers ===

func get_alive_mobs() -> Array:
	# Minimal registry so HeroIdleState can find nearby enemies without real GameScene.
	var mobs: Array = []
	for child in mob_container.get_children():
		if child is Mob and not child.is_dead:
			mobs.append(child)
	return mobs

func get_bridge_position() -> Vector2:
	return world.to_global(Vector2(-250, 0))

func get_portal_spawn_position() -> Vector2:
	# Stub: тестовая арена не имеет реального портала, возвращаем правую сторону площадки.
	return world.to_global(Vector2(250, 0))
