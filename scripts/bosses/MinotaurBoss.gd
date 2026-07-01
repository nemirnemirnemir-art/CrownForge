extends Mob
class_name MinotaurBoss
const GNOLL_SCENE: PackedScene = preload("res://scenes/mobs/Gnoll.tscn")

@export var charge_interval: float = 12.0
@export var charge_duration: float = 3.0
@export var point_interval: float = 10.0
@export var point_duration: float = 2.0
@export var point_spawn_count: int = 5
@export var point_spawn_jitter: float = 60.0
@export var start_idle_duration: float = 2.0

@export var invincible_float_amplitude: float = 10.0
@export var invincible_float_speed: float = 4.0

var _charge_cd_left: float = 0.0
var _point_cd_left: float = 0.0

var _initial_idle_pending: bool = true
var _idle_cycle_requested: bool = false

var _invincible_anim_t: float = 0.0
var _invincible_base_pos: Vector2 = Vector2.ZERO

@onready var _body: AnimatedSprite2D = get_node_or_null("AnimationSprite2D") as AnimatedSprite2D
@onready var _invincible_banner: Node2D = get_node_or_null("InvincibleBanner") as Node2D

func _ready() -> void:
    super()
    add_to_group("boss")

    var wall_layer_mask: int = 1 << (8 - 1)
    collision_mask |= wall_layer_mask

    _charge_cd_left = charge_interval
    _point_cd_left = point_interval

    if _invincible_banner:
        _invincible_base_pos = _invincible_banner.position
        _invincible_banner.visible = false

func _process(delta: float) -> void:
    super(delta)
    if is_dead:
        return

    _charge_cd_left = maxf(0.0, _charge_cd_left - delta)
    _point_cd_left = maxf(0.0, _point_cd_left - delta)
    _update_invincible_banner(delta)

func play_boss_anim(anim_name: String) -> void:
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

func set_facing_dir_x(dir_x: float) -> void:
    if _body == null:
        return
    if abs(dir_x) <= 0.001:
        return
    _body.flip_h = dir_x < 0.0

func get_facing_dir_x() -> float:
    if _body and _body.flip_h:
        return -1.0
    return 1.0

func get_wall_position() -> Vector2:
    var marker_service := _get_map_marker_service()
    return marker_service.get_wall_position() if marker_service else Vector2(600, 550)

func find_nearest_hero(max_range: float = -1.0) -> Node2D:
    var range_to_use := max_range
    if range_to_use <= 0.0:
        range_to_use = float(aggro_range)
    return CombatTargetFinder.find_nearest(self, "hero", range_to_use)

func is_charge_ready() -> bool:
    return _charge_cd_left <= 0.0

func is_point_ready() -> bool:
    return _point_cd_left <= 0.0

func reset_charge_cd() -> void:
    _charge_cd_left = charge_interval

func reset_point_cd() -> void:
    _point_cd_left = point_interval

func get_charge_duration() -> float:
    return maxf(0.1, charge_duration)

func get_point_duration() -> float:
    return maxf(0.1, point_duration)

func consume_initial_idle() -> bool:
    if _initial_idle_pending:
        _initial_idle_pending = false
        return true
    return false

func request_idle_cycle_after_kill() -> void:
    _idle_cycle_requested = true

func consume_idle_cycle_after_kill() -> bool:
    var requested := _idle_cycle_requested
    _idle_cycle_requested = false
    return requested

func get_idle_cycle_duration() -> float:
    if _body == null or _body.sprite_frames == null:
        return 1.6
    if not _body.sprite_frames.has_animation("idle"):
        return 1.6
    var frame_count := float(_body.sprite_frames.get_frame_count("idle"))
    var speed := float(_body.sprite_frames.get_animation_speed("idle"))
    if speed <= 0.01:
        speed = 10.0
    return maxf(0.2, frame_count / speed)

func set_invincible_active(active: bool) -> void:
    is_invincible = active
    if _invincible_banner:
        _invincible_banner.visible = active
        if active:
            _invincible_anim_t = 0.0
            _invincible_banner.position = _invincible_base_pos

func clear_hero_targets_for_charge() -> void:
    var tree := get_tree()
    if tree == null:
        return

    for hero in tree.get_nodes_in_group("hero"):
        if hero == null or not is_instance_valid(hero):
            continue

        if hero.has_method("set_current_target"):
            hero.set_current_target(null)
        elif "current_target" in hero:
            hero.current_target = null

        var sm := hero.get_node_or_null("HeroStateMachine")
        if sm and sm.has_method("change_state"):
            if "current_state" in sm and sm.current_state and String(sm.current_state.name) == "HeroDeathState":
                continue
            sm.change_state("HeroIdleState")

func spawn_gnoll_pack() -> void:
    if GNOLL_SCENE == null:
        return

    var container: Node = get_parent()
    if container == null:
        container = get_tree().current_scene
    if container == null:
        return

    # Get portal position as base spawn location (where boss came from)
    var base_spawn_pos := Vector2(1000, 300)
    var marker_service := _get_map_marker_service()
    if marker_service:
        base_spawn_pos = marker_service.get_portal_position()

    for i in range(maxi(1, point_spawn_count)):
        var gnoll := GNOLL_SCENE.instantiate()
        if gnoll == null:
            continue

        container.add_child(gnoll)
        if gnoll is Node2D:
            var g2d := gnoll as Node2D
            # Spawn near portal with jitter, NOT using get_random_spawn_position
            # which might return castle defense positions
            var jitter_x := randf_range(-point_spawn_jitter, point_spawn_jitter)
            var jitter_y := randf_range(-point_spawn_jitter * 0.5, point_spawn_jitter * 0.5)
            g2d.global_position = base_spawn_pos + Vector2(jitter_x, jitter_y)

        if "bridge_position" in gnoll and marker_service:
            gnoll.bridge_position = marker_service.get_bridge_position()
        if "portal_position" in gnoll and marker_service:
            gnoll.portal_position = marker_service.get_portal_position()
        if "center_position" in gnoll and marker_service:
            gnoll.center_position = (marker_service.get_bridge_position() + marker_service.get_portal_position()) / 2.0
        if "behavior_target_type" in gnoll:
            gnoll.behavior_target_type = "wall"

        var battle_core := _get_battle_core()
        if battle_core:
            battle_core.register_mob(gnoll)

func _get_map_marker_service() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("MapMarkerService")

func _get_battle_core() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("BattleCore")

func _update_invincible_banner(delta: float) -> void:
    if _invincible_banner == null:
        return
    if not _invincible_banner.visible:
        return

    _invincible_anim_t += delta
    var dy := sin(_invincible_anim_t * invincible_float_speed) * invincible_float_amplitude
    _invincible_banner.position = _invincible_base_pos + Vector2(0.0, dy)
