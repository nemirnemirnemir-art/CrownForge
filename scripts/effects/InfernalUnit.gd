extends CharacterBody2D

## Summoned infernal creature - temporary ally spawned by spell

@onready var unit_anim: AnimatedSprite2D = $UnitAnim
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var radial_timer: Sprite2D = get_node_or_null("RadialTimer")

const SpellDamageApplicatorScript := preload("res://scripts/effects/shared/SpellDamageApplicator.gd")
const SpellEnemyTrackerScript := preload("res://scripts/effects/shared/SpellEnemyTracker.gd")
const SpellVisualLifecycleScript := preload("res://scripts/effects/shared/SpellVisualLifecycle.gd")
const FriendlyDamageBlockHelperScript := preload("res://scripts/hero/shared/FriendlyDamageBlockHelper.gd")

const BASE_MOVE_SPEED: float = 80.0
const BASE_ATTACK_DAMAGE: float = 25.0
const BASE_ATTACK_COOLDOWN: float = 1.5
const DETECTION_RANGE: float = 240.0
const ATTACK_RANGE: float = 40.0
const DEFAULT_LIFETIME: float = 30.0

const RUN_FRAME_PATHS := [
	"res://assets/characters/nobody/run/1.png",
	"res://assets/characters/nobody/run/2.png",
	"res://assets/characters/nobody/run/3.png",
	"res://assets/characters/nobody/run/4.png",
	"res://assets/characters/nobody/run/5.png",
	"res://assets/characters/nobody/run/6.png",
]

const ATTACK_FRAME_PATHS := [
	"res://assets/characters/nobody/attack/1.png",
	"res://assets/characters/nobody/attack/2.png",
	"res://assets/characters/nobody/attack/3.png",
	"res://assets/characters/nobody/attack/4.png",
]

var _lifetime: float = DEFAULT_LIFETIME
var _elapsed: float = 0.0
var _attack_timer: float = 0.0
var _current_target: Node2D = null
var _is_despawning: bool = false
var _radial_textures: Array[Texture2D] = []
var _enemy_tracker: RefCounted = SpellEnemyTrackerScript.new()
var _damage_applicator: RefCounted = SpellDamageApplicatorScript.new()
var _visual_lifecycle: RefCounted = SpellVisualLifecycleScript.new()

var max_hp: float = 140.0
var current_hp: float = 140.0
var damage_taken_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var evasion_chance: float = 0.0
var is_invincible: bool = false
var is_dead: bool = false


func _ready() -> void:
	_configure_attack_shape()
	_ensure_nobody_animations()
	_load_radial_textures()
	_update_radial_timer()
	_play_run_animation()


func setup(duration_or_legacy_flag: Variant = DEFAULT_LIFETIME, maybe_duration: float = -1.0) -> void:
	_lifetime = _resolve_lifetime(duration_or_legacy_flag, maybe_duration)
	_elapsed = 0.0
	current_hp = max_hp
	is_dead = false
	_is_despawning = false

	add_to_group("hero")
	add_to_group("summon")

	collision_layer = 1
	collision_mask = 2

	_configure_attack_shape()
	_ensure_nobody_animations()
	_update_radial_timer()
	_play_run_animation()


func _physics_process(delta: float) -> void:
	if is_dead or _is_despawning:
		return

	_elapsed += delta
	_update_radial_timer()
	_attack_timer = maxf(0.0, _attack_timer - delta)

	if _elapsed >= _lifetime:
		_despawn()
		return

	if _current_target == null or not _is_valid_target(_current_target):
		_find_target()

	if _current_target != null and _is_valid_target(_current_target):
		var to_target := _current_target.global_position - global_position
		var distance := to_target.length()
		if distance > ATTACK_RANGE:
			var direction := to_target.normalized()
			velocity = direction * _get_move_speed()
			move_and_slide()
			if unit_anim != null and absf(direction.x) > 0.05:
				unit_anim.flip_h = direction.x < 0.0
			_play_run_animation()
		else:
			velocity = Vector2.ZERO
			_try_attack()
	else:
		velocity = Vector2.ZERO
		_play_run_animation()


func take_damage(amount: float, _is_crit: bool = false, block_roll_provider: Callable = Callable()) -> void:
	if is_dead or _is_despawning:
		return
	if is_invincible:
		return
	if evasion_chance > 0.0 and randf() < clampf(evasion_chance, 0.0, 1.0):
		if get_parent() and FloatingText:
			FloatingText.spawn_evade(get_parent(), global_position + Vector2(0, -30))
		return
	if FriendlyDamageBlockHelperScript.should_block_damage(self, block_roll_provider):
		if get_parent() and FloatingText:
			FloatingText.spawn_evade(get_parent(), global_position + Vector2(0, -30))
		return

	var adjusted := maxf(1.0, amount * maxf(0.0, damage_taken_multiplier))
	current_hp -= adjusted
	if current_hp <= 0.0:
		_die()


func apply_damage(amount: float, _source: Node = null) -> void:
	take_damage(amount)


func _resolve_lifetime(duration_or_legacy_flag: Variant, maybe_duration: float) -> float:
	if typeof(duration_or_legacy_flag) == TYPE_BOOL:
		if maybe_duration > 0.0:
			return maybe_duration
		return DEFAULT_LIFETIME

	if duration_or_legacy_flag is float or duration_or_legacy_flag is int:
		var value := float(duration_or_legacy_flag)
		if value > 0.0:
			return value

	return DEFAULT_LIFETIME


func _find_target() -> void:
	var tree := get_tree()
	if tree == null:
		return
	_current_target = _enemy_tracker.find_nearest_enemy_in_groups(tree.root, global_position, DETECTION_RANGE, ["enemy"], ATTACK_RANGE)
	if _current_target == null:
		_current_target = _enemy_tracker.find_nearest_enemy_in_groups(tree.root, global_position, INF, ["mobs", "enemies"], ATTACK_RANGE)


func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	if _current_target == null or not _is_valid_target(_current_target):
		return

	_attack_timer = _get_attack_cooldown()
	_play_attack_animation()

	var attack_damage := _get_attack_damage()
	var attack_id: int = Time.get_ticks_msec() + get_instance_id()
	_damage_applicator.apply_damage(_current_target, attack_damage, self, attack_id, true)


func _get_move_speed() -> float:
	return BASE_MOVE_SPEED * maxf(0.0, speed_multiplier)


func _get_attack_damage() -> float:
	return BASE_ATTACK_DAMAGE


func _get_attack_cooldown() -> float:
	var speed_mult := maxf(0.05, attack_speed_multiplier)
	return BASE_ATTACK_COOLDOWN / speed_mult


func _is_valid_target(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if "is_dead" in target and bool(target.get("is_dead")):
		return false
	return true


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	_despawn()


func _despawn() -> void:
	if _is_despawning:
		return
	_is_despawning = true
	velocity = Vector2.ZERO
	var tween: Tween = _visual_lifecycle.fade_out_nodes(self, [self], 0.35)
	await tween.finished
	queue_free()


func _configure_attack_shape() -> void:
	if attack_shape == null:
		return
	var shape := CircleShape2D.new()
	shape.radius = ATTACK_RANGE
	attack_shape.shape = shape


func _ensure_nobody_animations() -> void:
	if unit_anim == null:
		return
	if unit_anim.sprite_frames == null:
		unit_anim.sprite_frames = SpriteFrames.new()

	_ensure_animation("run", RUN_FRAME_PATHS, 9.0, true)
	_ensure_animation("attack", ATTACK_FRAME_PATHS, 11.0, true)


func _ensure_animation(anim_name: String, frame_paths: Array, speed: float, looped: bool) -> void:
	if unit_anim == null or unit_anim.sprite_frames == null:
		return
	var frames := unit_anim.sprite_frames
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	if frames.get_frame_count(anim_name) > 0:
		return

	for path_variant in frame_paths:
		var path := String(path_variant)
		var tex := load(path) as Texture2D
		if tex != null:
			frames.add_frame(anim_name, tex)

	if frames.get_frame_count(anim_name) > 0:
		frames.set_animation_speed(anim_name, speed)
		frames.set_animation_loop(anim_name, looped)


func _play_run_animation() -> void:
	if unit_anim == null or unit_anim.sprite_frames == null:
		return
	if not unit_anim.sprite_frames.has_animation("run"):
		return
	if unit_anim.animation != &"run":
		unit_anim.play("run")


func _play_attack_animation() -> void:
	if unit_anim == null or unit_anim.sprite_frames == null:
		return
	if not unit_anim.sprite_frames.has_animation("attack"):
		return
	unit_anim.play("attack")


func _load_radial_textures() -> void:
	_radial_textures.clear()
	for i in range(1, 21):
		var path := "res://assets/ui/radialProgressBar/%d.png" % i
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex != null:
			_radial_textures.append(tex)


func _update_radial_timer() -> void:
	if radial_timer == null:
		return
	if _radial_textures.is_empty():
		radial_timer.visible = false
		return
	if _lifetime <= 0.001:
		radial_timer.visible = false
		return

	radial_timer.visible = true
	var progress: float = clampf(_elapsed / _lifetime, 0.0, 1.0)
	var tex_idx: int = int(progress * float(_radial_textures.size() - 1))
	tex_idx = clampi(tex_idx, 0, _radial_textures.size() - 1)
	radial_timer.texture = _radial_textures[tex_idx]
