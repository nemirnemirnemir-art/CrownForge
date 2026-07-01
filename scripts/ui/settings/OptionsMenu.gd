extends Control
class_name OptionsMenu

const LAYOUT_SCALE: Vector2 = Vector2(1.5, 1.5)

@onready var _center_root: Control = $CenterRoot
@onready var _main_panel: Control = $CenterRoot/MainPanel
@onready var _bottom_bar: Control = $CenterRoot/BottomBar
@onready var _music_slider: OptionsSlider = $CenterRoot/MainPanel/VBoxContainer/MusicSlider
@onready var _sfx_slider: OptionsSlider = $CenterRoot/MainPanel/VBoxContainer/SfxSlider
@onready var _resolution_slider: OptionsSlider = $CenterRoot/MainPanel/VBoxContainer/ResolutionSlider
@onready var _start_mode_button: Button = $CenterRoot/MainPanel/VBoxContainer/StartModeButton
@onready var _start_creation_check: CheckBox = $CenterRoot/MainPanel/VBoxContainer/StartWithCharacterCreationCheckBox
@onready var _return_to_main_menu_button: Button = $CenterRoot/MainPanel/VBoxContainer/ReturnToMainMenuButton

@onready var _fps_check: TextureRect = $CenterRoot/MainPanel/VBoxContainer/FpsToggle/Checkmark
@onready var _dmg_check: TextureRect = $CenterRoot/MainPanel/VBoxContainer/DmgToggle/Checkmark
@onready var _flash_check: TextureRect = $CenterRoot/MainPanel/VBoxContainer/DamageFlashToggle/Checkmark
@onready var _pause_after_prophecy_check: TextureRect = $CenterRoot/MainPanel/VBoxContainer/PauseAfterProphecyToggle/Checkmark

var _game_settings: Node = null

var _fps_enabled: bool = false
var _dmg_enabled: bool = false
var _damage_flash_enabled: bool = false
var _pause_after_prophecy_enabled: bool = true

func _ready() -> void:
    visible = false
    if _center_root:
        _center_root.scale = LAYOUT_SCALE
    if _bottom_bar and _bottom_bar is TextureRect:
        var bottom_rect := _bottom_bar as TextureRect
        if bottom_rect.texture:
            bottom_rect.custom_minimum_size = bottom_rect.texture.get_size()
    _game_settings = _resolve_game_settings()
    if get_viewport() and not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
        get_viewport().size_changed.connect(_on_viewport_size_changed)
    
    # Load settings if available, else set defaults
    if _game_settings and _game_settings.has_method("get_music_volume"):
        _music_slider.current_value = _game_settings.get_music_volume()
    else:
        _music_slider.current_value = 50
        
    if _game_settings and _game_settings.has_method("get_sfx_volume"):
        _sfx_slider.current_value = _game_settings.get_sfx_volume()
    else:
        _sfx_slider.current_value = 50

    if _game_settings and _game_settings.has_method("is_damage_numbers_enabled"):
        _dmg_enabled = bool(_game_settings.is_damage_numbers_enabled())
    if _game_settings and _game_settings.has_method("is_damage_flash_enabled"):
        _damage_flash_enabled = bool(_game_settings.is_damage_flash_enabled())
    if _game_settings and _game_settings.has_method("is_pause_after_prophecy_enabled"):
        _pause_after_prophecy_enabled = bool(_game_settings.is_pause_after_prophecy_enabled())

    if _resolution_slider:
        var win := get_window()
        var scale_factor := 0.75
        if win:
            scale_factor = clampf(win.content_scale_factor, 0.5, 1.5)
        _resolution_slider.current_value = clampi(int(round(scale_factor * 100.0)), _resolution_slider.min_value, _resolution_slider.max_value)

    if _start_creation_check:
        if GameStartSettings:
            _start_creation_check.button_pressed = bool(GameStartSettings.start_via_character_creation)
        if not _start_creation_check.toggled.is_connected(_on_start_with_character_creation_toggled):
            _start_creation_check.toggled.connect(_on_start_with_character_creation_toggled)

    if _start_mode_button and not _start_mode_button.pressed.is_connected(_on_start_mode_pressed):
        _start_mode_button.pressed.connect(_on_start_mode_pressed)

    if _return_to_main_menu_button and not _return_to_main_menu_button.pressed.is_connected(_on_return_to_main_menu_pressed):
        _return_to_main_menu_button.pressed.connect(_on_return_to_main_menu_pressed)
        
    _update_fps_visual()
    _update_dmg_visual()
    _update_damage_flash_visual()
    _update_pause_after_prophecy_visual()
    _sync_start_mode_button()
    call_deferred("_recenter_layout")

func show_menu() -> void:
    visible = true
    _recenter_layout()

func hide_menu() -> void:
    visible = false

func _on_music_value_changed(new_value: int) -> void:
    if _game_settings and _game_settings.has_method("set_music_volume"):
        _game_settings.set_music_volume(new_value)
    _apply_audio_bus_volume("Music", new_value)

func _on_sfx_value_changed(new_value: int) -> void:
    if _game_settings and _game_settings.has_method("set_sfx_volume"):
        _game_settings.set_sfx_volume(new_value)
    _apply_audio_bus_volume("SFX", new_value)

func _on_resolution_value_changed(new_value: int) -> void:
    var scale_factor := clampf(float(new_value) / 100.0, 0.5, 1.5)
    _apply_resolution_scale(scale_factor)

func _apply_audio_bus_volume(bus_name: String, value: int) -> void:
    var bus_idx := AudioServer.get_bus_index(bus_name)
    if bus_idx >= 0:
        if value <= 0:
            AudioServer.set_bus_mute(bus_idx, true)
        else:
            AudioServer.set_bus_mute(bus_idx, false)
            # Convert 0-100 to db: 100 = 0db, 50 = -6db, 10 = -20db
            var db := linear_to_db(float(value) / 100.0)
            AudioServer.set_bus_volume_db(bus_idx, db)

func _apply_resolution_scale(scale_factor: float) -> void:
    var win := get_window()
    if win:
        win.content_scale_factor = scale_factor

    var scene := get_tree().get_first_node_in_group("game_scene")
    if scene and scene.has_method("set_runtime_content_scale_override"):
        scene.call("set_runtime_content_scale_override", scale_factor)

func _on_fps_toggle_pressed() -> void:
    _fps_enabled = !_fps_enabled
    _update_fps_visual()
    var fps_overlay := get_tree().get_first_node_in_group("fps_overlay")
    if fps_overlay:
        fps_overlay.visible = _fps_enabled

func _on_dmg_toggle_pressed() -> void:
    _dmg_enabled = !_dmg_enabled
    _update_dmg_visual()
    if _game_settings and _game_settings.has_method("set_damage_numbers_enabled"):
        _game_settings.set_damage_numbers_enabled(_dmg_enabled)

func _on_damage_flash_toggle_pressed() -> void:
    _damage_flash_enabled = !_damage_flash_enabled
    _update_damage_flash_visual()
    if _game_settings and _game_settings.has_method("set_damage_flash_enabled"):
        _game_settings.set_damage_flash_enabled(_damage_flash_enabled)

func _on_pause_after_prophecy_toggle_pressed() -> void:
    _pause_after_prophecy_enabled = !_pause_after_prophecy_enabled
    _update_pause_after_prophecy_visual()
    if _game_settings and _game_settings.has_method("set_pause_after_prophecy_enabled"):
        _game_settings.set_pause_after_prophecy_enabled(_pause_after_prophecy_enabled)

func _update_fps_visual() -> void:
    if _fps_check:
        _fps_check.visible = _fps_enabled

func _update_dmg_visual() -> void:
    if _dmg_check:
        _dmg_check.visible = _dmg_enabled

func _update_damage_flash_visual() -> void:
    if _flash_check:
        _flash_check.visible = _damage_flash_enabled

func _update_pause_after_prophecy_visual() -> void:
    if _pause_after_prophecy_check:
        _pause_after_prophecy_check.visible = _pause_after_prophecy_enabled

func _on_cancel_pressed() -> void:
    hide_menu()

func _on_continue_pressed() -> void:
    hide_menu()

func _on_reload_pressed() -> void:
    # Hard reset world
    get_tree().reload_current_scene()

func _on_start_with_character_creation_toggled(enabled: bool) -> void:
    if GameStartSettings:
        GameStartSettings.set_start_via_character_creation(enabled)
    _sync_start_mode_button()

func _on_start_mode_pressed() -> void:
    if _start_creation_check:
        _start_creation_check.button_pressed = not _start_creation_check.button_pressed
        _on_start_with_character_creation_toggled(_start_creation_check.button_pressed)

func _on_return_to_main_menu_pressed() -> void:
    if GameStartSettings:
        GameStartSettings.go_to_main_menu(get_tree())

func _sync_start_mode_button() -> void:
    if _start_mode_button == null:
        return
    var start_with_creation := _start_creation_check != null and _start_creation_check.button_pressed
    _start_mode_button.text = "Next Start: Character Creation" if start_with_creation else "Next Start: Direct Game"

func _on_viewport_size_changed() -> void:
    if visible:
        _recenter_layout()

func _recenter_layout() -> void:
    if _center_root:
        var desired_center := _get_desired_center_point()
        var rect_size := _center_root.size
        if rect_size == Vector2.ZERO:
            rect_size = _center_root.get_combined_minimum_size()
        rect_size *= _center_root.scale
        _center_root.position = desired_center - rect_size * 0.5

func _get_desired_center_point() -> Vector2:
    var marker := get_tree().get_first_node_in_group("center_marker")
    if marker == null:
        marker = get_tree().root.find_child("CenterMarker", true, false)
    if marker:
        if marker is Control:
            var ctrl := marker as Control
            return ctrl.get_global_rect().get_center()
        if marker is Node2D:
            return (marker as Node2D).global_position
    var vp := get_viewport()
    if vp:
        return vp.get_visible_rect().size * 0.5
    return Vector2.ZERO

func _resolve_game_settings() -> Node:
    var tree := get_tree()
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("GameSettings")
