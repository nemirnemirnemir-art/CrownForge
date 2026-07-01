extends SpellEffect

## Armageddon - start cast VFX + impact explosions that deal damage

const PROJECTILE_COUNT: int = 9
const WAVE_SIZE: int = 3
const WAVE_INTERVAL: float = 0.45

const DEFAULT_DAMAGE: float = 200.0
const DEFAULT_TARGET_RADIUS: float = 300.0
const IMPACT_RADIUS: float = 80.0

const START_FRAMES_PATH: String = "res://assets/vfx/spells_visuals/Armageddon/ArmageddonStartFrames.tres"
const START_ANIM: StringName = &"start"

const IMPACT_FOLDER: String = "res://assets/vfx/Particle FX/Explosion3"
const IMPACT_ANIM: StringName = &"impact"
const IMPACT_FPS: float = 18.0

const METEOR_TEX_PATH: String = "res://assets/vfx/effects/fireball.png"
const METEOR_FALL_HEIGHT: float = 380.0
const METEOR_FALL_TIME: float = 0.3
const METEOR_SCALE: Vector2 = Vector2(0.5, 0.5)

static var _cached_start_frames: SpriteFrames = null
static var _cached_impact_frames: SpriteFrames = null
static var _cached_meteor_tex: Texture2D = null

var _spell_radius: float = DEFAULT_TARGET_RADIUS
var _impact_radius: float = IMPACT_RADIUS
var _damage: float = DEFAULT_DAMAGE
var _impact_seq: int = 0

func execute_effect() -> void:
    var base_radius := DEFAULT_TARGET_RADIUS
    if config != null and config.target_radius > 0.0:
        base_radius = config.target_radius
    _spell_radius = get_scaled_radius(base_radius)
    _impact_radius = get_scaled_radius(IMPACT_RADIUS)

    var base_damage := DEFAULT_DAMAGE
    if config != null and config.damage > 0.0:
        base_damage = config.damage
    _damage = get_scaled_damage(base_damage)

    var start_fx := _spawn_start_fx()
    await get_tree().create_timer(0.25).timeout

    var waves := int(ceil(float(PROJECTILE_COUNT) / float(WAVE_SIZE)))
    for wave_idx in range(waves):
        var wave_start := wave_idx * WAVE_SIZE
        var wave_count: int = min(WAVE_SIZE, PROJECTILE_COUNT - wave_start)
        for _i in range(wave_count):
            _launch_impact()
        if wave_idx < waves - 1:
            await get_tree().create_timer(WAVE_INTERVAL).timeout

    if start_fx != null and is_instance_valid(start_fx):
        start_fx.queue_free()

    await get_tree().create_timer(METEOR_FALL_TIME + 0.7).timeout
    queue_free()

func _spawn_start_fx() -> AnimatedSprite2D:
    var frames := _get_or_create_start_frames()
    if frames == null:
        return null

    var sprite := AnimatedSprite2D.new()
    sprite.sprite_frames = frames
    sprite.animation = START_ANIM
    sprite.z_index = 185
    sprite.global_position = target_position
    add_child(sprite)

    if sprite.sprite_frames.has_animation(START_ANIM):
        sprite.play(START_ANIM)

    return sprite

func _launch_impact() -> void:
    var target_pos := _get_random_target_point()
    _spawn_falling_meteor(target_pos)
    var timer := get_tree().create_timer(METEOR_FALL_TIME)
    timer.timeout.connect(_on_meteor_landed.bind(target_pos))

func _on_meteor_landed(target_pos: Vector2) -> void:
    _spawn_impact_fx(target_pos)
    _deal_damage_at(target_pos)

func _spawn_falling_meteor(target_pos: Vector2) -> void:
    var tex := _get_or_create_meteor_tex()
    if tex == null:
        return

    var meteor := Sprite2D.new()
    meteor.texture = tex
    meteor.scale = METEOR_SCALE
    meteor.global_position = target_pos + Vector2(0.0, -METEOR_FALL_HEIGHT)
    meteor.z_index = 194
    meteor.z_as_relative = false
    add_child(meteor)

    var tween := create_tween()
    tween.set_trans(Tween.TRANS_LINEAR)
    tween.set_ease(Tween.EASE_IN)
    tween.tween_property(meteor, "global_position", target_pos, METEOR_FALL_TIME)
    tween.finished.connect(_on_meteor_fall_finished.bind(meteor))

func _on_meteor_fall_finished(meteor: Sprite2D) -> void:
    if meteor != null and is_instance_valid(meteor):
        meteor.queue_free()

func _spawn_impact_fx(world_pos: Vector2) -> void:
    var frames := _get_or_create_impact_frames()
    if frames == null:
        return

    var sprite := AnimatedSprite2D.new()
    sprite.sprite_frames = frames
    sprite.animation = IMPACT_ANIM
    sprite.z_index = 195
    add_child(sprite)
    sprite.global_position = world_pos

    if sprite.sprite_frames.has_animation(IMPACT_ANIM):
        sprite.play(IMPACT_ANIM)

    if not sprite.animation_finished.is_connected(_on_fx_finished.bind(sprite)):
        sprite.animation_finished.connect(_on_fx_finished.bind(sprite))

func _on_fx_finished(sprite: AnimatedSprite2D) -> void:
    if sprite != null and is_instance_valid(sprite):
        sprite.queue_free()

func _deal_damage_at(center: Vector2) -> void:
    var candidates: Array = get_tree().get_nodes_in_group("enemy")
    candidates.append_array(get_tree().get_nodes_in_group("mobs"))
    candidates.append_array(get_tree().get_nodes_in_group("enemies"))

    var seen := {}
    _impact_seq += 1
    for node in candidates:
        if node == null or not is_instance_valid(node):
            continue
        if not (node is Node2D):
            continue

        var target := node as Node2D
        if target.global_position.distance_to(center) > _impact_radius:
            continue

        var key := target.get_instance_id()
        if seen.has(key):
            continue
        seen[key] = true

        var hurtbox := target.get_node_or_null("Hurtbox")
        if hurtbox != null and hurtbox.has_method("apply_hit"):
            var attack_id := (Time.get_ticks_msec() + get_instance_id() + _impact_seq + key)
            hurtbox.apply_hit(_damage, self, attack_id)
            continue
        if target.has_method("take_damage"):
            target.take_damage(_damage)

func _get_random_target_point() -> Vector2:
    var angle := randf() * TAU
    var dist := sqrt(randf()) * _spell_radius
    return target_position + Vector2(cos(angle), sin(angle)) * dist

func _get_or_create_start_frames() -> SpriteFrames:
    if _cached_start_frames != null:
        return _cached_start_frames
    if ResourceLoader.exists(START_FRAMES_PATH):
        _cached_start_frames = load(START_FRAMES_PATH) as SpriteFrames
    return _cached_start_frames

func _get_or_create_impact_frames() -> SpriteFrames:
    if _cached_impact_frames != null:
        return _cached_impact_frames

    var frames := SpriteFrames.new()
    if not frames.has_animation(IMPACT_ANIM):
        frames.add_animation(IMPACT_ANIM)
    frames.set_animation_loop(IMPACT_ANIM, false)
    frames.set_animation_speed(IMPACT_ANIM, IMPACT_FPS)

    for idx in range(1, 13):
        var path := "%s/explosion-b%d.png" % [IMPACT_FOLDER, idx]
        if not ResourceLoader.exists(path):
            continue
        var tex := load(path) as Texture2D
        if tex != null:
            frames.add_frame(IMPACT_ANIM, tex)

    _cached_impact_frames = frames
    return _cached_impact_frames

func _get_or_create_meteor_tex() -> Texture2D:
    if _cached_meteor_tex != null:
        return _cached_meteor_tex
    if ResourceLoader.exists(METEOR_TEX_PATH):
        _cached_meteor_tex = load(METEOR_TEX_PATH) as Texture2D
    return _cached_meteor_tex
