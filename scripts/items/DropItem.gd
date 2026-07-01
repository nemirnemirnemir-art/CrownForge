extends Node2D
class_name DropItem

var item_data: Dictionary = {}
var is_collecting: bool = false
var can_collect: bool = false
const MIN_PICKUP_DELAY: float = 0.35
var _pickup_delay_done: bool = false
var _drop_anim_done: bool = false

@onready var drop_animation: AnimatedSprite2D = $DropAnimation
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D

var _mouse_over: bool = false

const HERO_PICKUP_RADIUS_PX: float = 26.0

func setup(data: Dictionary) -> void:
	item_data = data
	can_collect = false
	_pickup_delay_done = false
	_drop_anim_done = false
	var icon_path = data.get("icon_path", "")
	if icon_path != "":
		var tex: Texture2D = load(icon_path)
		if tex != null:
			sprite_2d.texture = tex
			sprite_2d.scale = Vector2(0.75, 0.75)
	
	# Setup Drop Animation
	drop_animation.visible = true
	sprite_2d.visible = false
	
	# Try to play animation matching the item ID (e.g. "ingredient_bat_wing").
	# If not present, fall back to any available animation; if none, skip animation.
	var anim_name := str(item_data.get("id", ""))
	var played_anim := false
	if drop_animation.sprite_frames:
		if anim_name != "" and drop_animation.sprite_frames.has_animation(anim_name):
			drop_animation.play(anim_name)
			played_anim = true
		elif drop_animation.sprite_frames.has_animation("default"):
			drop_animation.play("default")
			played_anim = true
		else:
			var names: PackedStringArray = drop_animation.sprite_frames.get_animation_names()
			if not names.is_empty():
				drop_animation.play(names[0])
				played_anim = true

	if not played_anim:
		drop_animation.visible = false
		sprite_2d.visible = true
		_drop_anim_done = true
		if area_2d:
			if not area_2d.mouse_entered.is_connected(_on_mouse_entered):
				area_2d.mouse_entered.connect(_on_mouse_entered)
			if not area_2d.mouse_exited.is_connected(_on_mouse_exited):
				area_2d.mouse_exited.connect(_on_mouse_exited)
		_update_can_collect()
		_start_pickup_delay()
		return
	
	# Randomize position slightly
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	position += Vector2(rng.randf_range(-10, 10), rng.randf_range(-10, 10))
	
	# Connect animation finished signal
	if not drop_animation.animation_finished.is_connected(_on_animation_finished):
		drop_animation.animation_finished.connect(_on_animation_finished)

	if area_2d:
		if not area_2d.mouse_entered.is_connected(_on_mouse_entered):
			area_2d.mouse_entered.connect(_on_mouse_entered)
		if not area_2d.mouse_exited.is_connected(_on_mouse_exited):
			area_2d.mouse_exited.connect(_on_mouse_exited)

	_start_pickup_delay()

func _start_pickup_delay() -> void:
	await get_tree().create_timer(MIN_PICKUP_DELAY).timeout
	_pickup_delay_done = true
	_update_can_collect()

func _update_can_collect() -> void:
	var was_collectable := can_collect
	can_collect = _pickup_delay_done and _drop_anim_done

	if not was_collectable and can_collect and not is_collecting and area_2d:
		for body in area_2d.get_overlapping_bodies():
			if body is Node2D and (body as Node2D).is_in_group("hero"):
				collect()
				break

func _on_animation_finished() -> void:
	# When drop animation finishes, switch to static sprite
	drop_animation.visible = false
	sprite_2d.visible = true
	_drop_anim_done = true
	_update_can_collect()

func _process(_delta: float) -> void:
	if is_collecting:
		return
	if not can_collect:
		return

	if _mouse_over and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		collect()
		return

	var tree := get_tree()
	if tree == null:
		return

	var heroes := tree.get_nodes_in_group("hero")
	if heroes.is_empty():
		return

	for h in heroes:
		if not is_instance_valid(h):
			continue
		if h is Node2D:
			if (h as Node2D).global_position.distance_to(global_position) <= HERO_PICKUP_RADIUS_PX:
				collect()
				return

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_collecting: return
	if not can_collect: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		collect()

func _on_mouse_entered() -> void:
	_mouse_over = true

func _on_mouse_exited() -> void:
	_mouse_over = false

func _on_body_entered(body: Node2D) -> void:
	if is_collecting: return
	if not can_collect: return
	
	# Check if body is a hero
	if body.is_in_group("hero"):
		collect()

func collect() -> void:
	if is_collecting: return
	is_collecting = true
	
	if PlayerInventory:
		if PlayerInventory.add_item(item_data):
			# Ensure static sprite is visible for the collect animation
			# (In case it was picked up before drop animation finished)
			drop_animation.visible = false
			sprite_2d.visible = true
			
			# Reset scale for the pop effect
			# Note: Sprite2D was hidden and maybe had scale 0.1 from scene, but we want to animate it.
			# We animate 'self' (the whole root) or just the sprite? 
			# If we animate self, it affects everything.
			# User wants: "increase then quickly shrink"
			
			# Let's ensure the sprite is at normal size relative to the node first
			sprite_2d.scale = Vector2(0.75, 0.75) 
			scale = Vector2(1, 1) # Ensure root is 1
			
			var tween = create_tween()
			# 1. Increase slightly (Pop up)
			tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			# 2. Shrink to 0 (Disappear into inventory)
			tween.tween_property(self, "scale", Vector2(0, 0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_callback(queue_free)
		else:
			# Inventory full
			is_collecting = false
