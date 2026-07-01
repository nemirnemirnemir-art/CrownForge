extends Mob
class_name DragonBoss

const FireFromDragonScene: PackedScene = preload("res://scenes/mobs/effects/FireFromDragon.tscn")

@export_group("Dragon Flight")
@export var flight_interval_sec: float = 16.0
@export var max_flights: int = 3
@export var takeoff_height_px: float = 300.0
@export var takeoff_speed_px_per_sec: float = 280.0
@export var fly_speed_px_per_sec: float = 360.0
@export var descent_speed_px_per_sec: float = 260.0
@export var return_delay_sec: float = 5.0
@export var flight_offscreen_margin: float = 220.0

@export_group("Dragon Fire")
@export var fire_cast_interval_sec: float = 0.35
@export var fire_spawn_offset: Vector2 = Vector2(-120.0, 100.0)
@export var fire_start_damage: float = 50.0
@export var burn_tick_count: int = 3
@export var burn_tick_percent_max_hp: float = 0.05
@export var burn_tick_interval_sec: float = 1.0

var flights_used: int = 0

var _flight_cd_left: float = 0.0
var _current_flight_id: int = 0
var _flight_takeoff_origin: Vector2 = Vector2.ZERO
var _flight_targets_hit: Dictionary = {}
var _flight_in_progress: bool = false

var _saved_collision_layer: int = 0
var _saved_collision_mask: int = 0
var _active_flight_fire: Node2D = null

@onready var _anim_up: AnimatedSprite2D = get_node_or_null("AnimUp") as AnimatedSprite2D
@onready var _anim_fly: AnimatedSprite2D = get_node_or_null("AnimFly") as AnimatedSprite2D

func _ready() -> void:
    super()
    add_to_group("boss")
    _saved_collision_layer = collision_layer
    _saved_collision_mask = collision_mask
    _flight_cd_left = maxf(0.1, flight_interval_sec)
    _hide_special_flight_anims()

func _process(delta: float) -> void:
    super(delta)
    if is_dead:
        return
    if _flight_in_progress:
        return
    if flights_used >= maxi(0, max_flights):
        return

    _flight_cd_left = maxf(0.0, _flight_cd_left - delta)
    if _flight_cd_left > 0.0:
        return

    if not _can_enter_flight_from_current_state():
        return

    _flight_cd_left = maxf(0.1, flight_interval_sec)
    if _state_machine and _state_machine.has_method("change_state"):
        _state_machine.change_state("DragonFlyUpState")

func play_anim(anim_name: String) -> void:
    if anim_name == "walk":
        play_walk()
        return
    if anim_name == "attack":
        play_attack()
        return
    super(anim_name)

func play_walk() -> void:
    _hide_special_flight_anims()
    super()

func play_attack() -> void:
    _hide_special_flight_anims()
    super()

func play_dragon_up_anim() -> void:
    _show_only_special_anim(_anim_up, &"dragon_up")

func play_dragon_fly_anim() -> void:
    _show_only_special_anim(_anim_fly, &"dragon_fly")

func face_target_x(target_x: float) -> void:
    set_facing_dir_x(target_x - global_position.x)

func set_facing_dir_x(dir_x: float) -> void:
    if absf(dir_x) <= 0.001:
        return
    var should_flip: bool = dir_x < 0.0
    if movement and movement.has_method("get_should_flip_for_direction"):
        should_flip = movement.get_should_flip_for_direction(dir_x, invert_visual_facing)
    elif invert_visual_facing:
        should_flip = not should_flip
    if anim_walk:
        anim_walk.flip_h = should_flip
    if anim_attack:
        anim_attack.flip_h = should_flip
    if _anim_up:
        _anim_up.flip_h = should_flip
    if _anim_fly:
        _anim_fly.flip_h = should_flip

func get_facing_dir_x() -> float:
    if anim_walk and anim_walk.flip_h:
        return -1.0
    if _anim_fly and _anim_fly.flip_h:
        return -1.0
    return 1.0

func begin_flight_cycle() -> bool:
    if _flight_in_progress:
        return true
    if flights_used >= maxi(0, max_flights):
        return false

    _flight_in_progress = true
    flights_used += 1
    _current_flight_id += 1
    _flight_takeoff_origin = global_position
    _flight_targets_hit.clear()
    _enable_flight_mode(true)
    set_facing_dir_x(-1.0)
    play_dragon_up_anim()
    return true

func finish_flight_cycle() -> void:
    _flight_in_progress = false
    stop_continuous_flight_fire()
    _enable_flight_mode(false)
    _hide_special_flight_anims()
    _flight_cd_left = maxf(0.1, flight_interval_sec)
    play_walk()

func hide_for_flight_return() -> void:
    visible = false

func show_for_flight_return() -> void:
    visible = true
    global_position = get_flight_peak_position()
    set_facing_dir_x(-1.0)
    play_dragon_fly_anim()

func get_flight_takeoff_origin() -> Vector2:
    return _flight_takeoff_origin

func get_flight_peak_position() -> Vector2:
    return _flight_takeoff_origin + Vector2(0.0, -maxf(1.0, takeoff_height_px))

func get_takeoff_speed() -> float:
    return maxf(1.0, takeoff_speed_px_per_sec)

func get_fly_speed() -> float:
    return maxf(1.0, fly_speed_px_per_sec)

func get_descent_speed() -> float:
    return maxf(1.0, descent_speed_px_per_sec)

func get_return_delay() -> float:
    return maxf(0.0, return_delay_sec)

func get_fire_cast_interval() -> float:
    return maxf(0.05, fire_cast_interval_sec)

func get_current_flight_id() -> int:
    return _current_flight_id

func is_outside_left_map_for_flight() -> bool:
    var bounds: Rect2 = Rect2(-1000.0, -1000.0, 2000.0, 2000.0)
    if movement and "map_bounds" in movement:
        var mv_bounds: Rect2 = movement.map_bounds
        if mv_bounds.size.x > 0.0:
            bounds = mv_bounds
    var left_x: float = bounds.position.x - maxf(0.0, flight_offscreen_margin)
    return global_position.x <= left_x

func spawn_fire_from_dragon() -> void:
    if FireFromDragonScene == null:
        return

    var inst := FireFromDragonScene.instantiate()
    if inst == null:
        return

    var parent_node: Node = get_parent()
    if parent_node == null:
        parent_node = get_tree().current_scene
    if parent_node == null:
        return

    parent_node.add_child(inst)

    if inst is Node2D:
        var fire2d := inst as Node2D
        fire2d.global_position = global_position + fire_spawn_offset

    if inst.has_method("setup_from_dragon"):
        inst.call("setup_from_dragon", self, _current_flight_id)

func start_continuous_flight_fire() -> void:
    if _active_flight_fire != null and is_instance_valid(_active_flight_fire):
        return
    if FireFromDragonScene == null:
        return

    var inst := FireFromDragonScene.instantiate()
    if inst == null:
        return

    add_child(inst)

    if inst is Node2D:
        _active_flight_fire = inst as Node2D
        _active_flight_fire.position = fire_spawn_offset

    if inst.has_method("setup_from_dragon"):
        inst.call("setup_from_dragon", self, _current_flight_id)
    if inst.has_method("set_persistent_mode"):
        inst.call("set_persistent_mode", true)

func stop_continuous_flight_fire() -> void:
    if _active_flight_fire == null:
        return
    if is_instance_valid(_active_flight_fire):
        _active_flight_fire.queue_free()
    _active_flight_fire = null

func try_apply_flight_fire_hit(target: Node2D, flight_id: int) -> void:
    if target == null or not is_instance_valid(target):
        return
    if "is_dead" in target and bool(target.is_dead):
        return
    if flight_id != _current_flight_id:
        return

    var target_id := target.get_instance_id()
    if _flight_targets_hit.has(target_id):
        return
    _flight_targets_hit[target_id] = true

    _apply_damage_to_target(target, fire_start_damage, _make_attack_id(flight_id, target_id, 0))
    _run_burn_ticks(target, flight_id, target_id)

func _run_burn_ticks(target: Node2D, flight_id: int, target_id: int) -> void:
    var ticks := maxi(0, burn_tick_count)
    if ticks <= 0:
        return

    var tree := get_tree()
    if tree == null:
        return

    var tick_interval := maxf(0.05, burn_tick_interval_sec)
    for tick in range(ticks):
        await tree.create_timer(tick_interval).timeout
        if target == null or not is_instance_valid(target):
            return
        if "is_dead" in target and bool(target.is_dead):
            return
        var burn_damage := _compute_burn_tick_damage(target)
        _apply_damage_to_target(target, burn_damage, _make_attack_id(flight_id, target_id, tick + 1))

func _compute_burn_tick_damage(target: Node2D) -> float:
    var max_hp := _extract_target_max_hp(target)
    if max_hp <= 0.0:
        return 1.0
    return maxf(1.0, round(max_hp * maxf(0.0, burn_tick_percent_max_hp)))

func _extract_target_max_hp(target: Node2D) -> float:
    if target.has_method("get_max_hp"):
        return maxf(0.0, float(target.call("get_max_hp")))
    if "max_health" in target:
        return maxf(0.0, float(target.max_health))
    if target.has_method("get_max_health"):
        return maxf(0.0, float(target.call("get_max_health")))
    return 0.0

func _apply_damage_to_target(target: Node2D, amount: float, attack_id: int) -> void:
    var dmg := maxf(1.0, amount)

    var hurtbox := target.get_node_or_null("Hurtbox")
    if hurtbox and hurtbox.has_method("apply_hit"):
        hurtbox.call("apply_hit", dmg, self, attack_id)
        return

    if target.has_method("take_damage"):
        target.call("take_damage", int(round(dmg)))
        return

    if target.has_method("apply_damage"):
        target.call("apply_damage", dmg, self)

func _make_attack_id(flight_id: int, target_id: int, tick: int) -> int:
    var t := Time.get_ticks_msec() % 100000
    return int(t + flight_id * 1000000 + (target_id % 997) * 10 + tick)

func _enable_flight_mode(active: bool) -> void:
    is_invincible = active

    if active:
        stop_continuous_flight_fire()
        _saved_collision_layer = collision_layer
        _saved_collision_mask = collision_mask
        collision_layer = 0
        collision_mask = 0
        velocity = Vector2.ZERO
        if combat:
            combat.clear_combat_target()
        if _attack_component and _attack_component.has_method("cancel_attack"):
            _attack_component.cancel_attack()
    else:
        stop_continuous_flight_fire()
        collision_layer = _saved_collision_layer
        collision_mask = _saved_collision_mask

    if _aggro_area:
        _aggro_area.monitoring = not active
    if _hurtbox:
        _hurtbox.monitoring = not active
    if _hitbox:
        _hitbox.monitoring = not active

func _can_enter_flight_from_current_state() -> bool:
    if _state_machine == null:
        return false
    if not ("current_state" in _state_machine):
        return false
    var cs = _state_machine.current_state
    if cs == null:
        return false
    var state_name := String(cs.name).to_lower()
    if state_name == "mobdeathstate":
        return false
    if state_name.begins_with("dragonfly"):
        return false
    return true

func _hide_special_flight_anims() -> void:
    if _anim_up:
        _anim_up.visible = false
    if _anim_fly:
        _anim_fly.visible = false

func _show_only_special_anim(node: AnimatedSprite2D, anim_name: StringName) -> void:
    if anim_walk:
        anim_walk.visible = false
    if anim_attack:
        anim_attack.visible = false
    if _anim_up:
        _anim_up.visible = false
    if _anim_fly:
        _anim_fly.visible = false

    if node == null:
        return

    node.visible = true
    if node.sprite_frames and node.sprite_frames.has_animation(anim_name):
        node.play(anim_name)
