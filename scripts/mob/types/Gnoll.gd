extends Mob
class_name Gnoll
const BONE_PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/GnollBoneProjectile.tscn")

@export var post_throw_idle_chance: float = 0.5
@export var walk_idle_break_chance: float = 0.25
@export var throw_duration: float = 1.0
@export var throw_hit_delay: float = 0.45

var _idle_request_duration: float = 0.0
var _has_idle_request: bool = false
var _pending_hit_reaction: bool = false

@onready var _body: AnimatedSprite2D = get_node_or_null("AnimationSprite2D") as AnimatedSprite2D

func _ready() -> void:
    super()
    if projectile_scene == null:
        projectile_scene = BONE_PROJECTILE_SCENE
    
    if _body and _body.sprite_frames:
        if _body.animation == "" or not _body.sprite_frames.has_animation(_body.animation):
            _body.animation = "idle"
            _body.play("idle")

func get_attack_state_name() -> String:
    return "GnollThrowState"

func play_gnoll_anim(anim_name: String) -> void:
    if _body == null:
        return
    if _body.sprite_frames and _body.sprite_frames.has_animation(anim_name):
        _body.play(anim_name)

func face_target_x(target_x: float) -> void:
    if _body == null:
        return
    var direction_x := target_x - global_position.x
    if abs(direction_x) <= 0.3:
        return
    _body.flip_h = direction_x < 0.0

func find_nearest_hero(max_range: float = -1.0) -> Node2D:
    var range_to_use := max_range
    if range_to_use <= 0.0:
        range_to_use = float(aggro_range)
    return CombatTargetFinder.find_nearest(self, "hero", range_to_use)

func roll_post_throw_idle() -> bool:
    return randf() < clampf(post_throw_idle_chance, 0.0, 1.0)

func roll_walk_idle_break() -> bool:
    return randf() < clampf(walk_idle_break_chance, 0.0, 1.0)

func get_throw_duration() -> float:
    return maxf(0.2, throw_duration)

func get_throw_hit_delay() -> float:
    return clampf(throw_hit_delay, 0.05, get_throw_duration())

func set_idle_request(duration: float) -> void:
    _idle_request_duration = maxf(0.01, duration)
    _has_idle_request = true

func consume_idle_request(default_duration: float) -> float:
    if _has_idle_request:
        _has_idle_request = false
        return _idle_request_duration
    return default_duration

func has_pending_hit_reaction() -> bool:
    return _pending_hit_reaction

func consume_hit_reaction() -> bool:
    var pending := _pending_hit_reaction
    _pending_hit_reaction = false
    return pending

func request_hit_reaction() -> void:
    _pending_hit_reaction = true

func take_damage(amount: float, is_crit: bool = false) -> void:
    var hp_before := current_health
    super.take_damage(amount, is_crit)
    if is_dead:
        return
    if current_health < hp_before:
        request_hit_reaction()
