extends Node2D

@export var actor_id: StringName

@onready var _walk_sprite: AnimatedSprite2D = $WalkSprite
@onready var _attack_sprite: AnimatedSprite2D = $AttackSprite

var _base_scale: Vector2 = Vector2.ONE
var _is_ready: bool = false
var _pending_state: StringName = &""


func _ready() -> void:
	print("[BattleActor] _ready called for ", actor_id)
	_base_scale = scale
	_is_ready = true
	# Apply any pending state that was requested before _ready()
	if _pending_state != &"":
		print("[BattleActor] Applying pending state: ", _pending_state)
		_apply_pending_state()
	else:
		play_idle()
	print("[BattleActor] _ready complete - visible: ", visible, " scale: ", scale, " position: ", position)


func _apply_pending_state() -> void:
	match _pending_state:
		&"idle":
			play_idle()
		&"walk":
			play_walk()
		&"attack":
			play_attack()
		&"dead":
			play_dead()
		_:
			play_idle()


func setup_for_side(side: int) -> void:
	var x_scale: float = absf(_base_scale.x)
	if side == 1:
		x_scale *= -1.0
	scale = Vector2(x_scale, _base_scale.y)


func play_walk() -> void:
	print("[BattleActor] play_walk called for ", actor_id, " _is_ready: ", _is_ready)
	if not _is_ready:
		_pending_state = &"walk"
		return
	visible = true
	_walk_sprite.visible = true
	_attack_sprite.visible = false
	_attack_sprite.stop()
	_walk_sprite.play(&"default")
	print("[BattleActor] play_walk complete - visible: ", visible, " walk_sprite visible: ", _walk_sprite.visible)


func play_attack() -> void:
	if not _is_ready:
		_pending_state = &"attack"
		return
	visible = true
	_walk_sprite.visible = false
	_walk_sprite.stop()
	_attack_sprite.visible = true
	_attack_sprite.play(&"default")


func play_idle() -> void:
	if not _is_ready:
		_pending_state = &"idle"
		return
	visible = true
	_walk_sprite.visible = true
	_attack_sprite.visible = false
	_attack_sprite.stop()
	_walk_sprite.play(&"default")
	_walk_sprite.stop()
	_walk_sprite.frame = 0


func play_dead() -> void:
	if not _is_ready:
		_pending_state = &"dead"
		return
	_walk_sprite.stop()
	_attack_sprite.stop()
	visible = false
