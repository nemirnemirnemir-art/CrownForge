extends Mob
class_name HomeseekerBoss

const TEX_IDLE: Texture2D = preload("res://assets/characters/bosses/homeseeker/Troll_Idle.png")
const TEX_WALK: Texture2D = preload("res://assets/characters/bosses/homeseeker/Troll_Walk.png")
const TEX_RECOVERY: Texture2D = preload("res://assets/characters/bosses/homeseeker/Troll_Recovery.png")
const TEX_DEAD: Texture2D = preload("res://assets/characters/bosses/homeseeker/Troll_Dead.png")

const ATTACK_FRAMES: Array[String] = [
    "res://assets/characters/bosses/homeseeker/troll_attack/Troll_Windup1.png",
    "res://assets/characters/bosses/homeseeker/troll_attack/Troll_Windup2.png",
    "res://assets/characters/bosses/homeseeker/troll_attack/Troll_Windup3.png",
    "res://assets/characters/bosses/homeseeker/troll_attack/Troll_Windup4.png",
    "res://assets/characters/bosses/homeseeker/troll_attack/Troll_Windup5.png",
    "res://assets/characters/bosses/homeseeker/troll_attack/Troll_Windup6.png",
    "res://assets/characters/bosses/homeseeker/troll_attack/Troll_Windup7.png",
]

const COMBO_FRAMES: Array[String] = [
    "res://assets/characters/bosses/homeseeker/troll_combo/Troll_Attack1.png",
    "res://assets/characters/bosses/homeseeker/troll_combo/Troll_Attack2.png",
    "res://assets/characters/bosses/homeseeker/troll_combo/Troll_Attack3.png",
    "res://assets/characters/bosses/homeseeker/troll_combo/Troll_Attack4.png",
    "res://assets/characters/bosses/homeseeker/troll_combo/Troll_Attack5.png",
    "res://assets/characters/bosses/homeseeker/troll_combo/Troll_Attack6.png",
]

@export var combo_interval: float = 13.0
@export var combo_shift_px: float = 25.0
@export var combo_shift_multiplier: float = 1.0
@export var combo_shift_frame_from: int = 2
@export var combo_shift_frame_to: int = 5
@export var combo_step_move_count: int = 6
@export var combo_step_frame_span: int = 3
@export var combo_anim_target_frames: int = 30
@export var combo_debug_enabled: bool = true
@export var combo_debug_timers: bool = true

@export var walk_shake_amplitude: float = 2.0
@export var walk_shake_duration: float = 0.08

@export var combo_shake_amplitude: float = 6.0
@export var combo_shake_duration: float = 0.12
@export var combo_shake_multiplier: float = 1.0

var combo_cd_left: float = 0.0
var _next_combo_dir_x: float = 1.0

@onready var _body: AnimatedSprite2D = get_node_or_null("AnimationSprite2D") as AnimatedSprite2D

var _world_shake: WorldShake = null
var _camera_shake: CameraShake2D = null
var _boss_hp_bar: Node = null

var _warned_no_shake: bool = false

func _ready() -> void:
    super()
    add_to_group("boss")
    if combo_debug_enabled:
        print("[HomeseekerBoss] _ready combo_interval=", combo_interval, " shift_px=", combo_shift_px, " frame_from=", combo_shift_frame_from, " frame_to=", combo_shift_frame_to, " step_move_count=", combo_step_move_count, " step_frame_span=", combo_step_frame_span)
    var wall_layer_mask: int = 1 << (8 - 1)  # Wall Solid bodies live on physics layer 8
    collision_mask |= wall_layer_mask
    if combo_debug_enabled:
        print("[HomeseekerBoss] physics collision_layer=", collision_layer, " collision_mask=", collision_mask, " (expects walls bit=", wall_layer_mask, ")")
    combo_cd_left = combo_interval
    if _body and _body.sprite_frames:
        var sf_existing := _body.sprite_frames
        _ensure_anim_loops(sf_existing)
        _ensure_combo_animation(sf_existing)
        if _body.animation == "" or not sf_existing.has_animation(_body.animation):
            if sf_existing.has_animation("idle"):
                _body.animation = "idle"
                _body.play("idle")

    _world_shake = _find_world_shake()
    _camera_shake = _find_camera_shake()
    _boss_hp_bar = _find_boss_hp_bar()
    if _world_shake == null:
        push_warning("[HomeseekerBoss] WorldShake not found (node 'WorldShake' under GameScene)")
    if _camera_shake == null:
        push_warning("[HomeseekerBoss] CameraShake not found (node 'CameraShake' under GameScene)")

func _process(delta: float) -> void:
    super(delta)
    if is_dead:
        return
    combo_cd_left = maxf(0.0, combo_cd_left - delta)

func is_combo_ready() -> bool:
    return combo_cd_left <= 0.0

func reset_combo_cd() -> void:
    combo_cd_left = combo_interval

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

func consume_combo_dir_x() -> float:
    _next_combo_dir_x *= -1.0
    return _next_combo_dir_x

func get_facing_dir_x() -> float:
    if _body and _body.flip_h:
        return -1.0
    return 1.0

func get_wall_position() -> Vector2:
    var marker_service := _get_map_marker_service()
    return marker_service.get_wall_position() if marker_service else Vector2(600, 550)

func _get_map_marker_service() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("MapMarkerService")

func request_walk_shake() -> void:
    if _world_shake:
        _world_shake.shake(walk_shake_amplitude, walk_shake_duration)
    if _camera_shake:
        _camera_shake.screen_shake(walk_shake_amplitude, walk_shake_duration)
    if _boss_hp_bar and _boss_hp_bar.has_method("screen_shake"):
        _boss_hp_bar.call("screen_shake", walk_shake_amplitude, walk_shake_duration)
    else:
        if not _warned_no_shake:
            _warned_no_shake = true
            push_warning("[HomeseekerBoss] request_walk_shake() but WorldShake is null")

func request_combo_shake() -> void:
    var amp := combo_shake_amplitude * combo_shake_multiplier
    var dur := combo_shake_duration
    var used := false
    if _camera_shake:
        _camera_shake.screen_shake(amp, dur)
        used = true
    if _world_shake:
        _world_shake.shake(amp, dur)
        used = true
    if _boss_hp_bar and _boss_hp_bar.has_method("screen_shake"):
        _boss_hp_bar.call("screen_shake", amp, dur)
        used = true
    if combo_debug_enabled:
        print("[HomeseekerBoss] request_combo_shake amp=", amp, " dur=", dur, " (base_amp=", combo_shake_amplitude, " mult=", combo_shake_multiplier, ", used_camera=", _camera_shake != null, ", used_world=", _world_shake != null, ")")
    if not used and not _warned_no_shake:
        _warned_no_shake = true
        push_warning("[HomeseekerBoss] request_combo_shake() but neither CameraShake nor WorldShake is available")

func apply_combo_shift(dx: float) -> void:
    velocity = Vector2.ZERO
    var col := move_and_collide(Vector2(dx, 0.0))
    if combo_debug_enabled:
        if col != null:
            var c := col.get_collider()
            var cname: String = "<null>"
            if c is Node:
                cname = (c as Node).name
            print("[HomeseekerBoss] combo shift BLOCKED dx=", dx, " collider=", c, " name=", cname, " normal=", col.get_normal(), " remainder=", col.get_remainder())
        else:
            print("[HomeseekerBoss] combo shift OK dx=", dx, " pos=", global_position)

func _find_world_shake() -> WorldShake:
    var gs := get_tree().get_first_node_in_group("game_scene")
    if gs:
        var ws := gs.get_node_or_null("WorldShake")
        if ws and ws is WorldShake:
            return ws as WorldShake
    return null

func _find_camera_shake() -> CameraShake2D:
    var gs := get_tree().get_first_node_in_group("game_scene")
    if gs:
        var cam := gs.get_node_or_null("CameraShake")
        if cam and cam is CameraShake2D:
            return cam as CameraShake2D
    return null

func _find_boss_hp_bar() -> Node:
    var gs := get_tree().get_first_node_in_group("game_scene")
    if gs:
        return gs.get_node_or_null("UILayer/BossHpBar")
    return null

func _make_combo_paths_for_target_frames() -> Array[String]:
    var target_fc: int = maxi(1, int(combo_anim_target_frames))
    var base_fc: int = COMBO_FRAMES.size()
    if base_fc <= 0:
        return []
    var out: Array[String] = []
    out.resize(0)
    for i in range(target_fc):
        out.append(COMBO_FRAMES[i % base_fc])
    return out

func _ensure_combo_animation(sf: SpriteFrames) -> void:
    if sf == null:
        return
    if not sf.has_animation("combo"):
        return

    var target_fc: int = maxi(1, int(combo_anim_target_frames))
    var fc: int = int(sf.get_frame_count("combo"))
    if fc <= 0:
        return

    # Важно: не перезаписываем кадры руками, только дополняем, если combo слишком короткая.
    if fc < target_fc:
        for i in range(target_fc - fc):
            var src_i: int = (fc + i) % fc
            var tex := sf.get_frame_texture("combo", src_i)
            if tex:
                sf.add_frame("combo", tex)
        fc = int(sf.get_frame_count("combo"))
        if combo_debug_enabled:
            print("[HomeseekerBoss] extended combo frames: ", fc, " (target=", target_fc, ")")

    # На всякий случай фиксируем speed/loop.
    if sf.has_method("set_animation_loop"):
        sf.set_animation_loop("combo", false)
    if sf.has_method("set_animation_speed"):
        sf.set_animation_speed("combo", 10.0)

func _ensure_anim_loops(sf: SpriteFrames) -> void:
    if sf == null:
        return
    if sf.has_method("set_animation_loop"):
        if sf.has_animation("idle"):
            sf.set_animation_loop("idle", true)
        if sf.has_animation("walk"):
            sf.set_animation_loop("walk", true)
        for n in ["attack", "combo", "recovery", "dead"]:
            if sf.has_animation(n):
                sf.set_animation_loop(n, false)

func _ensure_anim_dead() -> void:
    var dead_node := get_node_or_null("AnimDead") as AnimatedSprite2D
    if dead_node:
        return
    dead_node = AnimatedSprite2D.new()
    dead_node.name = "AnimDead"
    dead_node.visible = false
    if _body:
        dead_node.position = _body.position
        dead_node.scale = _body.scale
        dead_node.offset = _body.offset
        dead_node.flip_h = _body.flip_h
    
    # We must rely on existing generic frames from Mob instead of runtime generation here
    if MobDeathAnimSetup._cached_generic_death_frames:
        dead_node.sprite_frames = MobDeathAnimSetup._cached_generic_death_frames
        if dead_node.sprite_frames.has_animation("default"):
            dead_node.animation = "default"
    
    add_child(dead_node)
