extends Node
class_name AttackComponent

const ProjectileSpawnHelperScript := preload("res://scripts/combat/ProjectileSpawnHelper.gd")

signal hit_landed(amount: float)

@export var use_animation_hit_window: bool = false
@export var damage: float = 1.0
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
@export var projectile_type: String = "default"
@export var projectile_spin_speed_deg: float = 0.0

var _timing: AttackTiming = AttackTiming.new()
var _hitbox_binder: AttackHitboxBinder = AttackHitboxBinder.new()

var _attack_damage: float = 1.0
var _current_target: Node2D = null
var _last_dir: Vector2 = Vector2.RIGHT
var _projectile_dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_hitbox_binder.init(self)
	_timing.hit_window_opened.connect(_on_hit_window_opened)
	_timing.hit_window_closed.connect(_on_hit_window_closed)
	_timing.attack_finished.connect(_on_attack_finished)
	set_process(true)

func _process(delta: float) -> void:
	_timing.tick_cooldown(delta)
	if not use_animation_hit_window:
		_timing.tick_attack(delta)

# --- Public API ---

func start_attack(target: Node2D, override_damage: float = -1.0) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not _timing.can_start_attack():
		return false

	_current_target = target
	_timing.start()

	var p_node := get_parent() as Node2D
	var local_target_pos := p_node.to_local(target.global_position)
	_last_dir = _choose_cardinal_dir(local_target_pos)
	_projectile_dir = (target.global_position - p_node.global_position).normalized()
	if _projectile_dir == Vector2.ZERO:
		_projectile_dir = _last_dir

	if not projectile_scene:
		_hitbox_binder.update_hitbox_transform(_last_dir)
	_play_attack_animation(_last_dir)

	var dmg := damage
	if override_damage >= 0.0:
		dmg = override_damage
	else:
		var p := get_parent()
		if p and p.has_method("get_attack_damage"):
			dmg = float(p.get_attack_damage())
	_attack_damage = dmg
	return true

func cancel_attack() -> void:
	if not _timing.is_attacking():
		return
	_hitbox_binder.disable_hitbox()
	_timing.cancel()

func begin_hit_window() -> void:
	_timing.begin_hit_window()

func end_hit_window() -> void:
	_timing.end_hit_window()

func finish_from_animation() -> void:
	_timing.finish_from_animation()

func can_start_attack() -> bool:
	return _timing.can_start_attack()

func is_attacking() -> bool:
	return _timing.is_attacking()

func consume_cooldown() -> void:
	_timing.consume_cooldown()

func has_target_in_shapecast() -> bool:
	var sc := _hitbox_binder.get_shapecast()
	if not sc:
		return false
	sc.force_shapecast_update()
	return sc.is_colliding()

# --- Signal handlers from AttackTiming ---

func _on_hit_window_opened() -> void:
	if projectile_scene:
		_spawn_projectile()
	else:
		_hitbox_binder.enable_hitbox(_timing.attack_id, _attack_damage, _current_target, _on_hitbox_hit_landed)

func _on_hit_window_closed() -> void:
	_hitbox_binder.disable_hitbox()

func _on_attack_finished() -> void:
	_hitbox_binder.disable_hitbox()

# --- Projectile ---

func _spawn_projectile() -> void:
	if not projectile_scene:
		return
	var p_node := get_parent() as Node2D
	if p_node == null or _current_target == null or not is_instance_valid(_current_target):
		return
	ProjectileSpawnHelperScript.spawn(projectile_scene, p_node, _current_target, _attack_damage, projectile_speed, projectile_spin_speed_deg, Vector2.ZERO, projectile_type)

func _on_hitbox_hit_landed(amount: float) -> void:
	hit_landed.emit(amount)

# --- Animation ---

func _play_attack_animation(dir: Vector2) -> void:
	var anim := _hitbox_binder.get_anim()
	if anim == null or anim.sprite_frames == null:
		return
	var p = get_parent()
	if p and p.has_method("set_attack_animation_playing"):
		p.set_attack_animation_playing(true)
	var anim_name := _dir_to_anim(dir)
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	elif anim.sprite_frames.has_animation("attack"):
		anim.play("attack")

func _dir_to_anim(dir: Vector2) -> String:
	if dir == Vector2.UP:
		return "attack_up"
	if dir == Vector2.DOWN:
		return "attack_down"
	if dir == Vector2.LEFT:
		return "attack_left"
	return "attack_right"

func _choose_cardinal_dir(v: Vector2) -> Vector2:
	if v == Vector2.ZERO:
		return _last_dir
	if abs(v.x) > abs(v.y):
		return Vector2.RIGHT if v.x >= 0 else Vector2.LEFT
	return Vector2.DOWN if v.y >= 0 else Vector2.UP
