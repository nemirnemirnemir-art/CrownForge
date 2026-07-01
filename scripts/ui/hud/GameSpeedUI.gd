extends HBoxContainer
## GameSpeedUI - Speed control buttons (Pause, 1x, 2x, 3x)
## Uses game_speed_buttons atlas (4 buttons in a row)

const BUTTON_SIZE := Vector2(32, 32)
const ATLAS_BUTTON_WIDTH := 32
const SPEED_VALUES: Array[float] = [0.0, 1.0, 2.0, 3.0]

const OptionsMenuScene: PackedScene = preload("res://scenes/ui/settings/OptionsMenu.tscn")
const FPSOverlayScene: PackedScene = preload("res://scenes/ui/debug/FPSOverlay.tscn")

@export var settings_icon: Texture2D

var _buttons: Array[TextureButton] = []

var _settings_button: TextureButton
var _options_menu: OptionsMenu
var _fps_overlay: FPSOverlay
var _fps_enabled: bool = false
var _resume_speed_after_settings: float = 1.0

func _add_popup(node: Node) -> void:
    var tree := get_tree()
    if tree:
        var main_ui := tree.get_first_node_in_group("main_ui")
        if main_ui and main_ui.has_method("add_popup"):
            main_ui.call("add_popup", node)
            return
        var scene := tree.current_scene
        if scene:
            scene.add_child(node)

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _create_buttons()
    _connect_tick_manager()
    _update_button_states()
    _connect_viewport_resize_signal()
    _update_settings_button_position()
    _update_settings_button_visibility()

func _process(_delta: float) -> void:
    _update_settings_button_visibility()

func _create_buttons() -> void:
    var path_base := "res://assets/ui/game_speed_buttons/"
    for i in range(4):
        var btn := TextureButton.new()
        btn.custom_minimum_size = BUTTON_SIZE
        btn.ignore_texture_size = true
        btn.stretch_mode = TextureButton.STRETCH_SCALE
        
        # Load individual file (1.png, 2.png, etc.)
        var tex_path := path_base + str(i + 1) + ".png"
        var tex := load(tex_path) as Texture2D
        if tex:
            btn.texture_normal = tex
            # Use same for pressed state
            btn.texture_pressed = tex
        else:
            push_error("[GameSpeedUI] Failed to load speed button texture: %s" % tex_path)
        
        btn.pressed.connect(_on_button_pressed.bind(i))
        add_child(btn)
        _buttons.append(btn)

    _create_settings_button()

func _create_settings_button() -> void:
    var btn := TextureButton.new()
    btn.name = "SettingsButton"
    btn.custom_minimum_size = BUTTON_SIZE
    btn.ignore_texture_size = true
    btn.stretch_mode = TextureButton.STRETCH_SCALE
    if settings_icon:
        btn.texture_normal = settings_icon
        btn.texture_pressed = settings_icon
    btn.top_level = true
    btn.z_index = 500
    btn.focus_mode = Control.FOCUS_NONE
    btn.pressed.connect(_on_settings_pressed)
    add_child(btn)
    _settings_button = btn

func _connect_viewport_resize_signal() -> void:
    var vp := get_viewport()
    if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
        vp.size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
    _update_settings_button_position()

func _update_settings_button_position() -> void:
    if _settings_button == null or not is_instance_valid(_settings_button):
        return

    var btn_size := _settings_button.size
    if btn_size == Vector2.ZERO:
        btn_size = _settings_button.custom_minimum_size

    var control_height := size.y
    if control_height <= 0.0:
        control_height = BUTTON_SIZE.y

    var sep := float(get_theme_constant("separation"))
    var speed_buttons_width := float(_buttons.size()) * BUTTON_SIZE.x + maxf(0.0, float(_buttons.size() - 1)) * sep
    var margin_right := 10.0

    _settings_button.global_position = global_position + Vector2(
        speed_buttons_width + margin_right,
        (control_height - btn_size.y) * 0.5
    )

func _update_settings_button_visibility() -> void:
    if _settings_button == null or not is_instance_valid(_settings_button):
        return
    _settings_button.visible = not _is_reward_menu_active()

func _connect_tick_manager() -> void:
    if TickManager:
        TickManager.speed_changed.connect(_on_speed_changed)

func _on_button_pressed(index: int) -> void:
    if _is_reward_menu_active():
        return
    if TickManager and index < SPEED_VALUES.size():
        TickManager.set_speed(SPEED_VALUES[index])

func _on_settings_pressed() -> void:
    if _options_menu and is_instance_valid(_options_menu) and _options_menu.visible:
        _close_settings()
        return
    _open_settings()

func _open_settings() -> void:
    if TickManager:
        _resume_speed_after_settings = TickManager.speed_scale
        TickManager.pause()

    if not _options_menu:
        if OptionsMenuScene:
            _options_menu = OptionsMenuScene.instantiate() as OptionsMenu
            if _options_menu:
                add_child(_options_menu)
                _options_menu.show_menu()
                _options_menu.hidden.connect(_on_options_menu_hidden)
    else:
        _options_menu.show_menu()

func _on_options_menu_hidden() -> void:
    _close_settings()

func _close_settings() -> void:
    if _options_menu and is_instance_valid(_options_menu):
        _options_menu.visible = false

    if TickManager:
        if _resume_speed_after_settings <= 0.0:
            _resume_speed_after_settings = 1.0
        TickManager.set_speed(_resume_speed_after_settings)

func _on_show_fps_changed(enabled: bool) -> void:
    _fps_enabled = enabled
    if _fps_enabled:
        _ensure_fps_overlay()
        if _fps_overlay:
            _fps_overlay.visible = true
    else:
        if _fps_overlay and is_instance_valid(_fps_overlay):
            _fps_overlay.visible = false

func _ensure_fps_overlay() -> void:
    if _fps_overlay and is_instance_valid(_fps_overlay):
        return
    if FPSOverlayScene == null:
        return
    _fps_overlay = FPSOverlayScene.instantiate() as FPSOverlay
    _add_popup(_fps_overlay)
    _fps_overlay.visible = true
    _fps_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_speed_changed(_new_speed: float) -> void:
    _update_button_states()

func _input(event: InputEvent) -> void:
    if not event.is_pressed():
        return
    
    if event is InputEventKey:
        if event.keycode == KEY_ESCAPE:
            if _options_menu and is_instance_valid(_options_menu) and _options_menu.visible:
                _close_settings()
                get_viewport().set_input_as_handled()
                return
        if event.keycode == KEY_SPACE:
            if _is_reward_menu_active():
                get_viewport().set_input_as_handled()
                return
            if TickManager:
                TickManager.toggle_pause()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_1:
            if _is_reward_menu_active():
                get_viewport().set_input_as_handled()
                return
            if TickManager: TickManager.set_speed(1.0)
        elif event.keycode == KEY_2:
            if _is_reward_menu_active():
                get_viewport().set_input_as_handled()
                return
            if TickManager: TickManager.set_speed(2.0)
        elif event.keycode == KEY_3:
            if _is_reward_menu_active():
                get_viewport().set_input_as_handled()
                return
            if TickManager: TickManager.set_speed(3.0)

func _is_reward_menu_active() -> bool:
    if not is_inside_tree():
        return false
    var tree := get_tree()
    if tree == null or tree.current_scene == null:
        return false

    var reward_menu_paths: Array[String] = [
        "UILayer/WaveRewardMenu",
        "UILayer/ProphecyMenu",
        "UILayer/RewardMenuLevyBarracks",
        "UILayer/RewardMenuBaseProduction",
        "UILayer/RewardMenuResources",
        "UILayer/RewardMenuTrader",
        "UILayer/RewardMenuSpells",
        "UILayer/RewardMenuLegendarySpells",
    ]

    for p in reward_menu_paths:
        var node := tree.current_scene.get_node_or_null(p)
        var canvas := node as CanvasItem
        if canvas and canvas.visible:
            return true

    return false

func _update_button_states() -> void:
    if not TickManager:
        return
    
    var current_index := TickManager.get_speed_index()
    
    for i in range(_buttons.size()):
        var btn := _buttons[i]
        if i == current_index:
            btn.modulate = Color(1.0, 1.0, 0.5, 1.0)  # Highlight active
        else:
            btn.modulate = Color(1.0, 1.0, 1.0, 0.7)  # Dim inactive

    if _settings_button:
        _update_settings_button_visibility()
        _settings_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
