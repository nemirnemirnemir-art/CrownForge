extends PanelContainer

const EXCLUSIVE_TOOLTIP_GROUP := "exclusive_upgrade_tooltips"

@onready var current_label: Label = $HBox/CurrentLabel
@onready var max_label: Label = $HBox/MaxLabel
@onready var upgrade_button: Button = $HBox/UpgradeButton
@onready var icon_rect: TextureRect = $HBox/Icon
@onready var hover_region: Control = $HoverRegion
@onready var tooltip_panel: Control = $HoverRegion/GazeTooltip

var _gaze_core: Node = null
var _tooltip_hovered: bool = false
var _tooltip_panel_hovered: bool = false
var _pending_hide: bool = false
var _hide_timer: float = 0.0
var _show_timer: float = 0.0
var _pending_show: bool = false

const TOOLTIP_HIDE_DELAY := 0.15
const TOOLTIP_SHOW_DELAY := 0.5

func _resource_core() -> Node:
    return get_node_or_null("/root/ResourceCore")

func _event_bus() -> Node:
    return get_node_or_null("/root/EventBus")

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    add_to_group(EXCLUSIVE_TOOLTIP_GROUP)
    _gaze_core = get_node_or_null("/root/GazeCore")
    if _gaze_core and _gaze_core.has_signal("gaze_level_changed"):
        _gaze_core.gaze_level_changed.connect(_on_gaze_level_changed)
    var resource_core := _resource_core()
    if resource_core and resource_core.has_signal("resource_changed"):
        resource_core.resource_changed.connect(_on_resource_changed)
    var event_bus := _event_bus()
    if event_bus and event_bus.has_signal("gold_changed"):
        event_bus.gold_changed.connect(_on_gold_changed)

    upgrade_button.pressed.connect(_on_upgrade_pressed)
    upgrade_button.focus_mode = Control.FOCUS_NONE
    if upgrade_button:
        upgrade_button.mouse_entered.connect(_on_hover_entered)
        upgrade_button.mouse_exited.connect(_on_hover_exited)
    mouse_entered.connect(_on_hover_entered)
    mouse_exited.connect(_on_hover_exited)

    _update_display()
    if tooltip_panel:
        tooltip_panel.visible = false
        tooltip_panel.top_level = true
        tooltip_panel.z_index = 1000
        tooltip_panel.mouse_filter = Control.MOUSE_FILTER_PASS
        tooltip_panel.mouse_entered.connect(_on_tooltip_entered)
        tooltip_panel.mouse_exited.connect(_on_tooltip_exited)

func _set_tooltip_visible(visible: bool) -> void:
    if tooltip_panel == null:
        return
    if tooltip_panel.visible == visible:
        if visible:
            call_deferred("_position_tooltip")
        return
    tooltip_panel.visible = visible
    tooltip_panel.z_index = 1000 if visible else 0
    if visible:
        _close_other_upgrade_tooltips()
        if tooltip_panel.has_method("update_info"):
            tooltip_panel.update_info()
        call_deferred("_position_tooltip")

func _on_resource_changed(_resource_id: String, _amount: int) -> void:
    _update_display()
    if tooltip_panel and tooltip_panel.visible and tooltip_panel.has_method("update_info"):
        tooltip_panel.update_info()

func _on_gold_changed(_new_amount: float, _delta: float) -> void:
    _update_display()
    if tooltip_panel and tooltip_panel.visible and tooltip_panel.has_method("update_info"):
        tooltip_panel.update_info()

func _update_display() -> void:
    if _gaze_core == null:
        return
    if _gaze_core.has_method("get_current_tiles"):
        current_label.text = str(_gaze_core.call("get_current_tiles"))
    if _gaze_core.has_method("get_max_tiles"):
        max_label.text = str(_gaze_core.call("get_max_tiles"))
    if _gaze_core.has_method("can_upgrade"):
        upgrade_button.disabled = not bool(_gaze_core.call("can_upgrade"))

func _on_gaze_level_changed(_lvl: int) -> void:
    _update_display()
    if tooltip_panel and tooltip_panel.visible and tooltip_panel.has_method("update_info"):
        tooltip_panel.update_info()

func _on_upgrade_pressed() -> void:
    if _gaze_core and _gaze_core.has_method("try_upgrade") and bool(_gaze_core.call("try_upgrade")):
        _update_display()

func _on_hover_entered() -> void:
    _tooltip_hovered = true
    _pending_hide = false
    _hide_timer = 0.0
    _pending_show = true
    _show_timer = TOOLTIP_SHOW_DELAY

func _on_hover_exited() -> void:
    _tooltip_hovered = false
    _pending_show = false
    _show_timer = 0.0
    if tooltip_panel and tooltip_panel.visible:
        _pending_hide = true
        _hide_timer = TOOLTIP_HIDE_DELAY

func _on_tooltip_entered() -> void:
    _tooltip_panel_hovered = true
    _pending_hide = false
    _hide_timer = 0.0

func _on_tooltip_exited() -> void:
    _tooltip_panel_hovered = false
    _pending_hide = true
    _hide_timer = TOOLTIP_HIDE_DELAY

func _position_tooltip() -> void:
    if tooltip_panel == null or not is_instance_valid(tooltip_panel):
        return
    if upgrade_button == null or not is_instance_valid(upgrade_button):
        return
    if not tooltip_panel.visible:
        return

    tooltip_panel.reset_size()
    var sz := tooltip_panel.get_combined_minimum_size()
    if sz == Vector2.ZERO:
        sz = tooltip_panel.size

    var margin := 8.0
    var anchor_pos := upgrade_button.global_position
    var pos := Vector2(
        anchor_pos.x + upgrade_button.size.x * 0.5 - sz.x * 0.5,
        anchor_pos.y - sz.y - margin
    )

    var screen := get_viewport_rect().size
    pos.x = clamp(pos.x, 5.0, max(5.0, screen.x - sz.x - 5.0))
    pos.y = clamp(pos.y, 5.0, max(5.0, screen.y - sz.y - 5.0))
    tooltip_panel.global_position = pos

func _process(delta: float) -> void:
    if upgrade_button and _gaze_core and _gaze_core.has_method("can_upgrade"):
        var can_up: bool = bool(_gaze_core.call("can_upgrade"))
        if upgrade_button.disabled == can_up:
            upgrade_button.disabled = not can_up
    _tooltip_hovered = _is_mouse_over_host_area()
    _tooltip_panel_hovered = _is_mouse_over_tooltip_panel()

    if _pending_show:
        if not _tooltip_hovered and not _tooltip_panel_hovered:
            _pending_show = false
            _show_timer = 0.0
        else:
            _show_timer -= delta
            if _show_timer <= 0.0:
                _pending_show = false
                _set_tooltip_visible(true)

    if tooltip_panel and tooltip_panel.visible and not _tooltip_hovered and not _tooltip_panel_hovered and not _pending_hide:
        _pending_hide = true
        _hide_timer = TOOLTIP_HIDE_DELAY
    if _pending_hide and not _tooltip_hovered and not _tooltip_panel_hovered:
        _hide_timer -= delta
        if _hide_timer <= 0.0:
            _pending_hide = false
            _set_tooltip_visible(false)
            return
    if (_tooltip_hovered or _tooltip_panel_hovered) and tooltip_panel and tooltip_panel.visible:
        _position_tooltip()


func _is_mouse_over_host_area() -> bool:
    var mouse_pos := get_viewport().get_mouse_position()
    var host_rect := Rect2(global_position, size)
    if host_rect.has_point(mouse_pos):
        return true
    if upgrade_button != null and is_instance_valid(upgrade_button):
        var button_rect := Rect2(upgrade_button.global_position, upgrade_button.size)
        if button_rect.has_point(mouse_pos):
            return true
    return false


func _is_mouse_over_tooltip_panel() -> bool:
    if tooltip_panel == null or not is_instance_valid(tooltip_panel) or not tooltip_panel.visible:
        return false
    var mouse_pos := get_viewport().get_mouse_position()
    var tooltip_rect := Rect2(tooltip_panel.global_position, tooltip_panel.size)
    return tooltip_rect.has_point(mouse_pos)


func _close_other_upgrade_tooltips() -> void:
    var tree := get_tree()
    if tree == null:
        return
    for node in tree.get_nodes_in_group(EXCLUSIVE_TOOLTIP_GROUP):
        if node == self:
            continue
        if node != null and node.has_method("_force_hide_tooltip"):
            node.call("_force_hide_tooltip")


func _force_hide_tooltip() -> void:
    _tooltip_hovered = false
    _tooltip_panel_hovered = false
    _pending_hide = false
    _hide_timer = 0.0
    _pending_show = false
    _show_timer = 0.0
    _set_tooltip_visible(false)
