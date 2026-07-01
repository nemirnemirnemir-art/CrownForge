extends Control
class_name BossHpBar

@export var boss_name: String = "Homeseeker"
@export var fill_scale: Vector2 = Vector2(0.833914, 3.4636)
@export var fill_offset: Vector2 = Vector2(94.0, 27.0)
@export var fill_size: Vector2 = Vector2(250.0, 32.0)
@export var apply_fill_tweaks: bool = true
@export var fill_margin_x: float = 10.0

@export var slide_in_duration: float = 0.35
@export var slide_out_duration: float = 0.25
@export var slide_distance_px: float = 90.0

@export var show_delay_sec: float = 3.0

@export var shake_decay: float = 5.0
@export var shake_time_speed: float = 20.0
@export var noise_frequency: float = 2.0
@export var return_speed: float = 10.5
@export var offset_limit: float = 64.0

@onready var _bar: TextureProgressBar = get_node_or_null("Bar") as TextureProgressBar
@onready var _name_label: Label = get_node_or_null("Name") as Label
@onready var _hp_label: Label = get_node_or_null("Hp") as Label
@onready var _portrait: TextureRect = get_node_or_null("Portrait") as TextureRect

var _boss: Node2D = null
var _default_boss_name: String = ""
var _active_boss_name: String = ""
var _default_portrait: Texture2D = null
var _active_portrait: Texture2D = null

var _shown_pos: Vector2 = Vector2.ZERO
var _slide_pos: Vector2 = Vector2.ZERO
var _shake_offset: Vector2 = Vector2.ZERO
var _slide_tween: Tween = null
var _show_delay_timer: SceneTreeTimer = null

var _shake_intensity: float = 0.0
var _active_shake_time: float = 0.0
var _shake_time: float = 0.0
var _noise := FastNoiseLite.new()

func _ready() -> void:
    visible = false
    _apply_fill_tweaks()

    _default_boss_name = boss_name
    _active_boss_name = boss_name
    if _portrait:
        _default_portrait = _portrait.texture
        _active_portrait = _portrait.texture

    _shown_pos = position
    _slide_pos = _shown_pos + Vector2(slide_distance_px, 0.0)
    modulate.a = 0.0
    _apply_layout()

    _noise.frequency = noise_frequency
    _noise.seed = randi()

func set_boss(boss: Node2D, display_name: String = "", portrait: Texture2D = null) -> void:
    _active_boss_name = display_name if display_name != "" else _default_boss_name
    _active_portrait = portrait if portrait != null else _default_portrait

    _boss = boss
    var valid := _boss != null and is_instance_valid(_boss)
    if not valid:
        clear_boss()
        return

    if visible:
        _update_display()
        return

    _schedule_show_delay()

func clear_boss() -> void:
    _cancel_show_delay()
    _boss = null
    if not visible:
        return
    _animate_hide()

func _process(_delta: float) -> void:
    _update_shake(_delta)
    if _boss == null or not is_instance_valid(_boss):
        clear_boss()
        return
    if _boss is Mob:
        var m := _boss as Mob
        if m.is_dead:
            clear_boss()
            return
    _update_display()

func _update_display() -> void:
    if _name_label:
        _name_label.text = _active_boss_name
    if _portrait and _active_portrait:
        _portrait.texture = _active_portrait
    var cur: float = _extract_current_hp(_boss)
    var mx: float = _extract_max_hp(_boss)
    mx = max(1.0, mx)
    var pct: float = clampf(cur / mx, 0.0, 1.0)
    if _bar:
        _bar.max_value = 100.0
        _bar.value = pct * 100.0
    if _hp_label:
        _hp_label.text = "%d/%d" % [int(round(cur)), int(round(mx))]

func _extract_current_hp(target: Node) -> float:
    if target == null or not is_instance_valid(target):
        return 0.0
    if target.has_method("get_current_hp"):
        return maxf(0.0, float(target.call("get_current_hp")))
    if target.has_method("get_current_health"):
        return maxf(0.0, float(target.call("get_current_health")))
    if "health" in target and target.health != null and "current_health" in target.health:
        return maxf(0.0, float(target.health.current_health))
    if "current_health" in target:
        return maxf(0.0, float(target.current_health))
    return 0.0

func _extract_max_hp(target: Node) -> float:
    if target == null or not is_instance_valid(target):
        return 0.0
    if target.has_method("get_max_hp"):
        return maxf(0.0, float(target.call("get_max_hp")))
    if target.has_method("get_max_health"):
        return maxf(0.0, float(target.call("get_max_health")))
    if "health" in target and target.health != null and "max_health" in target.health:
        return maxf(0.0, float(target.health.max_health))
    if "max_health" in target:
        return maxf(0.0, float(target.max_health))
    return 0.0

func _apply_fill_tweaks() -> void:
    if not _bar:
        return
    if not apply_fill_tweaks:
        return
    _bar.scale = fill_scale
    _bar.offset_left = fill_offset.x + fill_margin_x
    _bar.offset_top = fill_offset.y
    _bar.offset_right = fill_offset.x + fill_size.x - fill_margin_x
    _bar.offset_bottom = fill_offset.y + fill_size.y

func _apply_layout() -> void:
    position = _slide_pos + _shake_offset

func _animate_show() -> void:
    if _slide_tween and _slide_tween.is_valid():
        _slide_tween.kill()
    _slide_pos = _shown_pos + Vector2(slide_distance_px, 0.0)
    _shake_offset = Vector2.ZERO
    _apply_layout()
    modulate.a = 0.0
    visible = true

    _slide_tween = create_tween()
    _slide_tween.set_trans(Tween.TRANS_CUBIC)
    _slide_tween.set_ease(Tween.EASE_OUT)
    _slide_tween.set_parallel(true)
    _slide_tween.tween_property(self, "_slide_pos", _shown_pos, maxf(0.01, slide_in_duration))
    _slide_tween.tween_property(self, "modulate:a", 1.0, maxf(0.01, slide_in_duration))
    _slide_tween.set_parallel(false)
    _slide_tween.finished.connect(func():
        _slide_tween = null
    )

func _animate_hide() -> void:
    if _slide_tween and _slide_tween.is_valid():
        _slide_tween.kill()
    var target := _shown_pos + Vector2(slide_distance_px, 0.0)
    _slide_tween = create_tween()
    _slide_tween.set_trans(Tween.TRANS_CUBIC)
    _slide_tween.set_ease(Tween.EASE_IN)
    _slide_tween.set_parallel(true)
    _slide_tween.tween_property(self, "_slide_pos", target, maxf(0.01, slide_out_duration))
    _slide_tween.tween_property(self, "modulate:a", 0.0, maxf(0.01, slide_out_duration))
    _slide_tween.set_parallel(false)
    _slide_tween.finished.connect(_on_hide_finished, CONNECT_ONE_SHOT)

func _on_hide_finished() -> void:
    visible = false
    _slide_tween = null
    # Reset state for next boss
    _shake_offset = Vector2.ZERO
    _shake_intensity = 0.0
    _active_shake_time = 0.0

func screen_shake(intensity: float, duration: float) -> void:
    if intensity <= 0.0 or duration <= 0.0:
        return
    _noise.seed = randi()
    _noise.frequency = noise_frequency
    _shake_intensity = maxf(_shake_intensity, intensity)
    _active_shake_time = maxf(_active_shake_time, duration)
    _shake_time = 0.0

func _update_shake(delta: float) -> void:
    if not visible:
        return

    if _active_shake_time > 0.0:
        _shake_time += delta * shake_time_speed
        _active_shake_time = maxf(0.0, _active_shake_time - delta)
        var offset_vec := _sample_noise() * _shake_intensity
        if offset_limit > 0.0:
            offset_vec = offset_vec.limit_length(offset_limit)
        _shake_offset = offset_vec
        _shake_intensity = maxf(_shake_intensity - shake_decay * delta, 0.0)
        _apply_layout()
        return

    if _shake_offset.length() > 0.01:
        _shake_offset = _shake_offset.lerp(Vector2.ZERO, minf(1.0, return_speed * delta))
        _apply_layout()

func _sample_noise() -> Vector2:
    return Vector2(
        _noise.get_noise_2d(_shake_time, 0.0),
        _noise.get_noise_2d(0.0, _shake_time)
    )

func _schedule_show_delay() -> void:
    _cancel_show_delay()
    var delay := maxf(0.0, show_delay_sec)
    if delay <= 0.01:
        visible = true
        _animate_show()
        _update_display()
        return

    visible = false
    var tree := get_tree()
    if tree == null:
        return
    _show_delay_timer = tree.create_timer(delay)
    _show_delay_timer.timeout.connect(_on_show_delay_timeout, CONNECT_ONE_SHOT)

func _cancel_show_delay() -> void:
    if _show_delay_timer:
        if _show_delay_timer.timeout.is_connected(_on_show_delay_timeout):
            _show_delay_timer.timeout.disconnect(_on_show_delay_timeout)
        _show_delay_timer = null

func _on_show_delay_timeout() -> void:
    _show_delay_timer = null
    if _boss and is_instance_valid(_boss):
        visible = true
        _animate_show()
        _update_display()
