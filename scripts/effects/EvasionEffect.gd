extends SpellEffect

## Evasion spell - grants allies 35% evasion chance for 8 seconds

@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

const DEFAULT_DURATION: float = 8.0
const EVASION_CHANCE: float = 0.35  # 35%
const ICON_PATH: String = "res://assets/vfx/spells/Evasion.png"
const ICON_OFFSET: Vector2 = Vector2(0.0, -60.0)
const ICON_SIZE: float = 37.5
const BOB_AMPLITUDE: float = 6.0
const BOB_SPEED: float = 2.8
const StatusIconServiceScript := preload("res://scripts/effects/shared/StatusIconService.gd")

var _affected: Dictionary = {}

func execute_effect() -> void:
	if not detection_area or not detection_shape:
		push_error("[EvasionEffect] Missing required nodes")
		queue_free()
		return
	
	if config:
		var shape := CircleShape2D.new()
		shape.radius = config.target_radius if config.target_radius > 0 else 80.0
		detection_shape.shape = shape
	
	# Target heroes (layer 1)
	detection_area.collision_mask = 1
	
	var duration := DEFAULT_DURATION
	if config != null and config.duration > 0.0:
		duration = config.duration
	var radius := get_scaled_radius(config.target_radius if config and config.target_radius > 0.0 else 80.0)

	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	_apply_buff(radius)
	set_process(true)

	await get_tree().create_timer(duration).timeout
	_remove_buff()
	queue_free()

func _apply_buff(radius: float) -> void:
	var heroes: Array[Node] = get_tree().get_nodes_in_group("hero")
	for hero_node in heroes:
		if hero_node == null or not is_instance_valid(hero_node):
			continue
		if not (hero_node is Node2D):
			continue
		var hero := hero_node as Node2D
		if hero.global_position.distance_to(global_position) > radius:
			continue
		if not ("evasion_chance" in hero):
			continue

		var hero_id := hero.get_instance_id()
		if _affected.has(hero_id):
			continue

		var prev_evasion := float(hero.evasion_chance)
		hero.evasion_chance = maxf(prev_evasion, EVASION_CHANCE)

		var icon := Sprite2D.new()
		var tex := load(ICON_PATH) as Texture2D
		icon.texture = tex
		icon.position = ICON_OFFSET
		icon.z_index = 200
		icon.name = "EvasionIcon"
		
		if tex:
			var size := tex.get_size()
			if size.x > 0 and size.y > 0:
				icon.scale = Vector2(ICON_SIZE / size.x, ICON_SIZE / size.y)
				
		icon.set_meta("status_icon", true)
		icon.set_meta("status_icon_offset_y", ICON_OFFSET.y)
		hero.add_child(icon)
		StatusIconServiceScript.reflow_status_icons(hero)

		_affected[hero_id] = {
			"hero_ref": weakref(hero),
			"prev_evasion": prev_evasion,
			"icon": icon,
			"base_y": icon.position.y,
			"phase": randf_range(0.0, TAU),
		}

func _remove_buff() -> void:
	for key in _affected.keys():
		var data: Dictionary = _affected[key]
		var hero_obj: Object = null
		if data.get("hero_ref") != null:
			hero_obj = (data.get("hero_ref") as WeakRef).get_ref()
		var hero_valid := hero_obj != null and is_instance_valid(hero_obj) and hero_obj is Node2D
		if hero_valid:
			var hero := hero_obj as Node2D
			if "evasion_chance" in hero:
				hero.evasion_chance = float(data.get("prev_evasion", 0.0))

		var icon_obj: Object = data.get("icon")
		if icon_obj != null and is_instance_valid(icon_obj) and icon_obj is Node:
			(icon_obj as Node).queue_free()

		# Schedule reflow after icon removal so remaining icons re-center
		if hero_valid:
			StatusIconServiceScript.schedule_deferred_reflow(hero_obj as Node2D)

	_affected.clear()

func _process(_delta: float) -> void:
	if _affected.is_empty():
		return
	var t := Time.get_ticks_msec() * 0.001
	var to_remove: Array[int] = []
	for key in _affected.keys():
		var data: Dictionary = _affected[key]
		var hero_obj: Object = null
		if data.get("hero_ref") != null:
			hero_obj = (data.get("hero_ref") as WeakRef).get_ref()
		if hero_obj == null or not is_instance_valid(hero_obj):
			to_remove.append(int(key))
			continue

		var icon_obj: Object = data.get("icon")
		if icon_obj == null or not is_instance_valid(icon_obj) or not (icon_obj is Sprite2D):
			continue
		var icon := icon_obj as Sprite2D
		var base_y := float(data.get("base_y", ICON_OFFSET.y))
		var phase := float(data.get("phase", 0.0))
		icon.position.y = base_y + sin(t * BOB_SPEED + phase) * BOB_AMPLITUDE
	for key in to_remove:
		_affected.erase(key)
