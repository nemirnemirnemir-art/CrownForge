extends Control
class_name WaveTimerBar

## Visual wave timer bar - flags move from right to left
## When flag reaches castle (left edge), wave spawns

signal wave_triggered(wave_number: int)

const WaveTooltipScene: PackedScene = preload("res://scenes/ui/overlays/WaveTooltip.tscn")

@export var wave_interval: float = 30.0  # Seconds between waves
@export var flag_texture: Texture2D  # Placeholder flag icon
@export var castle_texture: Texture2D  # Placeholder castle icon
@export var visible_flag_target: int = 5

@onready var background: ColorRect = $Background
@onready var castle_icon: TextureRect = $CastleIcon
@onready var flags_container: Control = $FlagsContainer

var _flags: Array[Dictionary] = []  # {node: Control, wave: int, progress: float, label: Label, travel_interval: float}
var _next_wave_number: int = 0  # Start from 0 for first wave
var _bar_width: float = 0.0
var _flag_spawn_timer: float = 0.0
var _next_flag_wait: float = 0.0
var _tooltip: WaveTooltip = null
var _tooltip_target_flag: Control = null
var _wave_previews: Dictionary = {} # wave_number -> {"enemy_id": String, "enemy_count": int, "mob_counts": Dictionary}

var _wave_interval_provider: Callable = Callable()
var _is_paused: bool = false
var _travel_interval_base: float = 30.0
var _has_triggered_wave: bool = false
var _debug_last_signature: String = ""


func _debug_log(context: String, extra: Dictionary = {}) -> void:
    var tick_speed: Variant = null
    if is_inside_tree():
        var tick_manager := get_node_or_null("/root/TickManager")
        if tick_manager != null:
            tick_speed = tick_manager.get("speed_scale")
    print("[WaveTimerBar][DEBUG] %s | paused=%s tick_speed=%s flags=%d next_wave=%d spawn_timer=%.3f next_wait=%.3f extra=%s" % [
        context,
        str(_is_paused),
        str(tick_speed),
        _flags.size(),
        _next_wave_number,
        _flag_spawn_timer,
        _next_flag_wait,
        str(extra),
    ])

func _ready() -> void:
    _bar_width = maxf(0.0, size.x - 48.0)  # Subtract castle icon width
    _refresh_travel_interval_base()

    if not resized.is_connected(_on_resized):
        resized.connect(_on_resized)
    
    # Create tooltip instance
    _tooltip = WaveTooltipScene.instantiate() as WaveTooltip
    if _tooltip:
        add_child(_tooltip)
        _tooltip.top_level = true
        _tooltip.z_index = 1000
        _tooltip.hide()
    
    _reset_startup_timeline()
    call_deferred("_on_resized")

func _process(delta: float) -> void:
    if _is_paused:
        var paused_signature := "paused"
        if _debug_last_signature != paused_signature:
            _debug_last_signature = paused_signature
            _debug_log("process:early_return_paused")
        return

    var tick_manager := get_node_or_null("/root/TickManager")
    if tick_manager == null:
        var missing_tick_signature := "missing_tick"
        if _debug_last_signature != missing_tick_signature:
            _debug_last_signature = missing_tick_signature
            _debug_log("process:early_return_missing_tick")
        return

    var active_signature := "%s|%s|%d|%d" % [str(_is_paused), str(tick_manager.get("speed_scale")), _flags.size(), _next_wave_number]
    if _debug_last_signature != active_signature:
        _debug_last_signature = active_signature
        _debug_log("process:active")
    
    var scaled_delta: float = float(tick_manager.get_scaled_delta(delta))
    _flag_spawn_timer += scaled_delta
    
    # Spawn new flag every wave_interval seconds
    if _flag_spawn_timer >= _next_flag_wait:
        _flag_spawn_timer = 0.0
        _spawn_flag(0.0)
        _next_flag_wait = _get_interval_for_wave(_next_wave_number)
    
    # Move all flags
    for i in range(_flags.size() - 1, -1, -1):
        var flag_data = _flags[i]
        var flag_node: Control = flag_data.node
        
        if not is_instance_valid(flag_node):
            _flags.remove_at(i)
            continue
        
        # Progress: 0 = right edge, 1 = castle (left)
        var travel_interval: float = float(flag_data.get("travel_interval", _get_travel_time_for_wave(int(flag_data.get("wave", 0)))))
        travel_interval = maxf(0.001, travel_interval)
        flag_data.progress += scaled_delta / travel_interval
        _flags[i] = flag_data
        
        # Calculate position (right to left)
        var x_pos = _bar_width * (1.0 - flag_data.progress) + 48.0  # 48 = castle offset
        flag_node.position.x = x_pos - flag_node.size.x / 2
        
        # Flag reached castle?
        if flag_data.progress >= 1.0:
            var wave_num: int = flag_data.wave
            _debug_log("process:wave_triggered", {"wave_num": wave_num})
            # print("[WaveTimerBar] Wave %d triggered! (progress=%.2f)" % [wave_num, flag_data.progress])
            _has_triggered_wave = true
            wave_triggered.emit(wave_num)
            
            # Hide tooltip if it's showing for this flag
            if _tooltip_target_flag == flag_node:
                _hide_tooltip()
            
            flag_node.queue_free()
            _flags.remove_at(i)
    
    # Update tooltip position if visible
    if _tooltip and _tooltip.visible and is_instance_valid(_tooltip_target_flag):
        _position_tooltip(_tooltip_target_flag)

func _prefill_flags() -> void:
    var travel_time: float = maxf(0.001, _get_travel_time_for_wave(0))
    var cumulative_trigger_time: float = 0.0
    var guard: int = 0

    while guard < 128:
        var wave_num := _next_wave_number
        cumulative_trigger_time += maxf(0.001, _get_interval_for_wave(wave_num))
        if cumulative_trigger_time > travel_time:
            break

        var initial_progress := clampf(1.0 - (cumulative_trigger_time / travel_time), 0.0, 1.0)
        _spawn_flag(initial_progress)
        guard += 1

func _reset_startup_timeline() -> void:
    print("[WaveTimerBar] _reset_startup_timeline called. Old flags: %d, next_wave: %d" % [_flags.size(), _next_wave_number])
    # Immediately remove old flags from container to prevent visual overlap with new flags
    for flag_data in _flags:
        var flag_node: Control = flag_data.get("node", null)
        if is_instance_valid(flag_node) and flag_node.get_parent() == flags_container:
            flags_container.remove_child(flag_node)
            flag_node.queue_free()
    
    _flags.clear()
    _next_wave_number = 0
    _flag_spawn_timer = 0.0
    _has_triggered_wave = false
    _debug_last_signature = ""

    _prefill_flags()
    _next_flag_wait = _get_interval_for_wave(_next_wave_number)
    
    print("[WaveTimerBar] After reset: flags=%d, next_wave=%d, spawn_timer=%.3f, next_wait=%.3f" % [_flags.size(), _next_wave_number, _flag_spawn_timer, _next_flag_wait])

    if _next_wave_number <= 0:
        return

    var next_wave_trigger_time := _get_absolute_wave_trigger_time(_next_wave_number)
    var travel_time := maxf(0.001, _get_travel_time_for_wave(_next_wave_number))
    var desired_spawn_time := maxf(0.0, next_wave_trigger_time - travel_time)
    _flag_spawn_timer = clampf(_next_flag_wait - desired_spawn_time, 0.0, _next_flag_wait)

func _get_absolute_wave_trigger_time(wave_number: int) -> float:
    if wave_number < 0:
        return 0.0

    var total: float = 0.0
    for w in range(wave_number + 1):
        total += maxf(0.001, _get_interval_for_wave(w))
    return total

func _on_resized() -> void:
    _bar_width = maxf(0.0, size.x - 48.0)

    for i in range(_flags.size()):
        var flag_data = _flags[i]
        var flag_node: Control = flag_data.node
        if not is_instance_valid(flag_node):
            continue

        var x_pos = _bar_width * (1.0 - float(flag_data.get("progress", 0.0))) + 48.0
        flag_node.position.x = x_pos - flag_node.size.x / 2

func _spawn_flag(initial_progress: float = 0.0) -> void:
    print("[WaveTimerBar] Spawning flag for wave %d" % _next_wave_number)
    var this_travel_interval: float = maxf(0.001, _get_travel_time_for_wave(_next_wave_number))
    var flag = ColorRect.new() # Use ColorRect for guaranteed visibility
    flag.name = "Flag_%d" % _next_wave_number
    flag.mouse_filter = Control.MOUSE_FILTER_STOP # Ensure mouse events are captured
    
    if flag_texture:
        var sprite = TextureRect.new()
        sprite.texture = flag_texture
        sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
        flag.add_child(sprite)
    
    # Visual style for the flag block
    flag.color = Color(0.9, 0.7, 0.2, 0.8) # Golden rectangle
    flag.custom_minimum_size = Vector2(32, 32)
    flag.size = Vector2(32, 32)
    
    # Add wave number label
    var label := Label.new()
    label.text = str(_next_wave_number)
    label.add_theme_font_size_override("font_size", 20)
    label.add_theme_color_override("font_color", Color.BLACK)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    flag.add_child(label)
    
    # Connect hover signals
    flag.mouse_entered.connect(_on_flag_mouse_entered.bind(flag, _next_wave_number))
    flag.mouse_exited.connect(_on_flag_mouse_exited.bind(flag))
    
    # Vertical centering
    var start_progress := clampf(initial_progress, 0.0, 1.0)
    var x_pos = _bar_width * (1.0 - start_progress) + 48.0
    flag.position = Vector2(x_pos - flag.size.x / 2, (size.y - flag.size.y) / 2)
    
    flags_container.add_child(flag)
    
    _flags.append({
        "node": flag,
        "wave": _next_wave_number,
        "progress": start_progress,
        "label": label,
        "travel_interval": this_travel_interval,
    })

    _update_flag_label(_next_wave_number, _wave_previews.get(_next_wave_number, {}))
    
    _next_wave_number += 1

func _on_flag_mouse_entered(flag: Control, wave_num: int) -> void:
    if not _tooltip:
        return
    
    _tooltip_target_flag = flag
    
    var preview: Dictionary = _wave_previews.get(wave_num, {})
    var tooltip_payload: Dictionary = _get_default_preview(wave_num)
    if preview and not preview.is_empty():
        tooltip_payload = preview
    _tooltip.setup_wave(wave_num, tooltip_payload)
    
    _position_tooltip(flag)
    _tooltip.show()

func _on_flag_mouse_exited(flag: Control) -> void:
    # Don't hide immediately - check if mouse is over tooltip
    if _tooltip_target_flag == flag:
        # Use process_always timer to work during pause
        var timer := get_tree().create_timer(0.1, true, false, true)
        await timer.timeout
        if _tooltip_target_flag == flag:
            _hide_tooltip()

func _position_tooltip(flag: Control) -> void:
    if not _tooltip or not is_instance_valid(flag):
        return
    
    var flag_global_pos := flag.global_position
    # Show tooltip BELOW the flag instead of above (since flags are at top of screen)
    var tooltip_pos := Vector2(
        flag_global_pos.x + flag.size.x / 2 - _tooltip.size.x / 2,
        flag_global_pos.y + flag.size.y + 10
    )
    _tooltip.global_position = tooltip_pos

func _hide_tooltip() -> void:
    if _tooltip:
        _tooltip.hide()
    _tooltip_target_flag = null

func set_wave_interval(interval: float) -> void:
    wave_interval = interval
    _refresh_travel_interval_base()

    if _has_triggered_wave:
        _retime_existing_flags()
        _next_flag_wait = _get_interval_for_wave(_next_wave_number)
    else:
        _reset_startup_timeline()

func set_paused(paused: bool) -> void:
    _is_paused = paused
    _debug_log("set_paused", {"paused": paused})

func set_wave_interval_provider(provider: Callable) -> void:
    _wave_interval_provider = provider
    _refresh_travel_interval_base()

    if _has_triggered_wave:
        _retime_existing_flags()
        _next_flag_wait = _get_interval_for_wave(_next_wave_number)
    else:
        _reset_startup_timeline()

func _refresh_travel_interval_base() -> void:
    var representative_wave: int = maxi(1, _next_wave_number)
    _travel_interval_base = maxf(0.001, _get_interval_for_wave(representative_wave))

func _retime_existing_flags() -> void:
    for i in range(_flags.size()):
        var flag_data = _flags[i]
        var wave_num: int = int(flag_data.get("wave", -1))
        if wave_num < 0:
            continue

        var old_travel_interval: float = maxf(0.001, float(flag_data.get("travel_interval", _get_travel_time_for_wave(wave_num))))
        var new_travel_interval: float = maxf(0.001, _get_travel_time_for_wave(wave_num))
        var elapsed_time: float = float(flag_data.get("progress", 0.0)) * old_travel_interval
        flag_data["travel_interval"] = new_travel_interval
        flag_data["progress"] = clamp(elapsed_time / new_travel_interval, 0.0, 1.0)
        _flags[i] = flag_data

func _get_travel_time_for_wave(_wave_number: int) -> float:
    var spawn_interval: float = maxf(0.001, _travel_interval_base)
    var spacing_slots: int = maxi(1, visible_flag_target - 1)
    return spawn_interval * float(spacing_slots)

func _get_interval_for_wave(wave_number: int) -> float:
    if _wave_interval_provider.is_valid():
        var v = _wave_interval_provider.call(wave_number)
        return float(v)
    return wave_interval

func set_wave_preview(wave_number: int, preview: Dictionary) -> void:
    print("[WaveTimerBar] set_wave_preview: wave=%d, title=%s, flag=%s" % [wave_number, preview.get("wave_title", ""), preview.get("flag_label", "")])
    _wave_previews[wave_number] = preview
    _update_flag_label(wave_number, preview)

func clear_wave_preview(wave_number: int) -> void:
    if _wave_previews.has(wave_number):
        _wave_previews.erase(wave_number)
    _update_flag_label(wave_number, {})

func clear_all_wave_previews() -> void:
    _wave_previews.clear()

func reset_wave_timeline() -> void:
    _reset_startup_timeline()

func remove_flags_from_wave(min_wave: int) -> void:
    for i in range(_flags.size() - 1, -1, -1):
        var flag_data = _flags[i]
        if int(flag_data.get("wave", -1)) >= min_wave:
            var flag_node: Control = flag_data.get("node", null)
            if is_instance_valid(flag_node) and flag_node.get_parent() == flags_container:
                flags_container.remove_child(flag_node)
                flag_node.queue_free()
            _flags.remove_at(i)

func remove_flag_by_wave_number(wave_number: int) -> void:
    for i in range(_flags.size() - 1, -1, -1):
        var flag_data = _flags[i]
        if int(flag_data.get("wave", -1)) == wave_number:
            var flag_node: Control = flag_data.get("node", null)
            if is_instance_valid(flag_node) and flag_node.get_parent() == flags_container:
                flags_container.remove_child(flag_node)
                flag_node.queue_free()
            _flags.remove_at(i)
            break

func _update_flag_label(wave_number: int, preview: Dictionary) -> void:
    for flag_data in _flags:
        if int(flag_data.wave) == wave_number:
            var label: Label = flag_data.label
            if not label:
                continue
            if preview:
                if preview.has("flag_label"):
                    label.text = str(preview["flag_label"])
                elif preview.has("display_wave_number"):
                    label.text = "%d" % int(preview["display_wave_number"])
                else:
                    label.text = str(wave_number)
            else:
                label.text = str(wave_number)

func _get_default_preview(wave_number: int) -> Dictionary:
    var fallback_count: int = max(1, wave_number)
    return {
        "wave_title": "Wave %d" % wave_number,
        "mob_counts": {
            "goblin_bandit": fallback_count,
        },
        "enemy_id": "goblin_bandit",
        "enemy_count": fallback_count,
    }
