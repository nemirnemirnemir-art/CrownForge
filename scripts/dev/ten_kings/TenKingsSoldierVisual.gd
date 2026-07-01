extends Node2D
## Minimal visual representation of a single soldier in crowd battles.
## Displays animated sprite scaled down for crowd rendering.

const ACTOR_SCENES: Dictionary = {
	&"soldier": "res://scenes/dev/ten_kings/actors/TenKingsSoldierActor.tscn",
	&"archer": "res://scenes/dev/ten_kings/actors/TenKingsArcherActor.tscn",
	&"paladin": "res://scenes/dev/ten_kings/actors/TenKingsPaladinActor.tscn",
}

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _walk_frames: SpriteFrames
var _attack_frames: SpriteFrames
var _current_state: String = "idle"
var _unit_type: StringName = &""
var _team: int = 0
var _base_scale: Vector2 = Vector2.ONE


func setup(unit_type: StringName) -> void:
	_unit_type = unit_type
	_base_scale = _extract_crowd_scale_from_actor_scene(unit_type)
	scale = _base_scale
	_load_sprite_frames(unit_type)


func _extract_crowd_scale_from_actor_scene(unit_type: StringName) -> Vector2:
	if not ACTOR_SCENES.has(unit_type):
		return Vector2(0.5, 0.5)
	var actor_scene: PackedScene = load(String(ACTOR_SCENES[unit_type]))
	if actor_scene == null:
		return Vector2(0.5, 0.5)
	var temp_actor: Node2D = actor_scene.instantiate()
	var actor_scale: Vector2 = temp_actor.scale
	var walk_sprite: AnimatedSprite2D = temp_actor.get_node_or_null("WalkSprite")
	var extracted_scale: Vector2 = actor_scale
	if walk_sprite != null:
		extracted_scale = Vector2(actor_scale.x * walk_sprite.scale.x, actor_scale.y * walk_sprite.scale.y)
	temp_actor.queue_free()
	if extracted_scale == Vector2.ZERO:
		return Vector2(0.5, 0.5)
	return extracted_scale


func _load_sprite_frames(unit_type: StringName) -> void:
	if not ACTOR_SCENES.has(unit_type):
		push_warning("[SoldierVisual] Unknown unit type: ", unit_type)
		return
	
	var scene_path: String = ACTOR_SCENES[unit_type]
	var actor_scene: PackedScene = load(scene_path)
	if actor_scene == null:
		push_warning("[SoldierVisual] Failed to load actor scene: ", scene_path)
		return
	
	# Instance temporarily to extract SpriteFrames
	var temp_actor := actor_scene.instantiate()
	
	var walk_sprite: AnimatedSprite2D = temp_actor.get_node_or_null("WalkSprite")
	var attack_sprite: AnimatedSprite2D = temp_actor.get_node_or_null("AttackSprite")
	
	if walk_sprite:
		_walk_frames = walk_sprite.sprite_frames
	if attack_sprite:
		_attack_frames = attack_sprite.sprite_frames
	
	temp_actor.queue_free()
	
	# Apply default walk frames
	if _walk_frames and _sprite:
		_sprite.sprite_frames = _walk_frames
		_sprite.play(&"default")


func set_state(state: String) -> void:
	if state == _current_state:
		return
	
	_current_state = state
	
	if not _sprite:
		return
	
	match state:
		"idle":
			if _walk_frames:
				_sprite.sprite_frames = _walk_frames
				_sprite.play(&"default")
				_sprite.stop()
				_sprite.frame = 0
			_sprite.visible = true
		"walk":
			if _walk_frames:
				_sprite.sprite_frames = _walk_frames
				_sprite.play(&"default")
			_sprite.visible = true
		"attack":
			if _attack_frames:
				_sprite.sprite_frames = _attack_frames
				_sprite.play(&"default")
			_sprite.visible = true
		"death":
			_sprite.visible = false
		_:
			if _walk_frames:
				_sprite.sprite_frames = _walk_frames
				_sprite.play(&"default")


func set_team(team: int) -> void:
	_team = team
	# Flip sprite horizontally for enemy team (team 1)
	if team == 1:
		scale = Vector2(-abs(_base_scale.x), abs(_base_scale.y))
	else:
		scale = Vector2(abs(_base_scale.x), abs(_base_scale.y))


func set_soldier_position(pos: Vector2) -> void:
	position = pos
