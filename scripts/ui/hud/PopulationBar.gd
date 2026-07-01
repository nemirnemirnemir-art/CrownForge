extends PanelContainer

const EXCLUSIVE_TOOLTIP_GROUP := "exclusive_upgrade_tooltips"
const TOOLTIP_HIDE_DELAY := 0.15
const TOOLTIP_SHOW_DELAY := 0.5

@onready var current_label: Label = $HBox/CurrentLabel
@onready var max_label: Label = $HBox/MaxLabel
@onready var upgrade_button: Button = $HBox/UpgradeButton
@onready var icon_rect: TextureRect = $HBox/Icon
@onready var hover_region: Control = $HoverRegion
@onready var tooltip_panel: Control = $HoverRegion/PopulationTooltip

var _tooltip_hovered: bool = false
var _tooltip_panel_hovered: bool = false
var _hide_timer: float = 0.0
var _pending_hide: bool = false
var _show_timer: float = 0.0
var _pending_show: bool = false

func _population_core() -> Node:
    return get_node_or_null("/root/PopulationCore")

func _resource_core() -> Node:
    return get_node_or_null("/root/ResourceCore")

func _hero_core() -> Node:
    return get_node_or_null("/root/HeroCore")

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    add_to_group(EXCLUSIVE_TOOLTIP_GROUP)
    var population_core := _population_core()
    if population_core:
        population_core.population_limit_changed.connect(_on_population_limit_changed)
    var resource_core := _resource_core()
    if resource_core and not resource_core.resource_changed.is_connected(_on_resource_changed):
        resource_core.resource_changed.connect(_on_resource_changed)
    
    var hero_core := _hero_core()
    if hero_core:
        hero_core.squad_changed.connect(_update_display)
        hero_core.hero_created.connect(func(_id, _data): _update_display())
        if hero_core.has_signal("hero_removed"):
            hero_core.hero_removed.connect(func(_id): _update_display())
        hero_core.hero_updated.connect(func(_id, _data): _update_display())
        
    upgrade_button.pressed.connect(_on_upgrade_pressed)
    upgrade_button.focus_mode = Control.FOCUS_NONE
    
    # Connect button hover signals so tooltip works when hovering the button
    upgrade_button.mouse_entered.connect(_on_hover_entered)
    upgrade_button.mouse_exited.connect(_on_hover_exited)

    if hover_region:
        hover_region.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

func _update_display() -> void:
    var population_core := _population_core()
    if population_core:
        current_label.text = str(population_core.get_current_population())
        max_label.text = str(population_core.get_max_population())
        _update_upgrade_button_state()
    elif upgrade_button:
        upgrade_button.disabled = true

func _on_population_limit_changed(_new_limit: int) -> void:
    _update_display()

func _on_upgrade_pressed() -> void:
    var population_core := _population_core()
    if population_core != null and population_core.try_upgrade():
        _update_display()
    else:
        _update_upgrade_button_state()

func _on_resource_changed(resource_id: String, _amount: int) -> void:
    var population_core := _population_core()
    if population_core == null:
        return
    if resource_id != population_core.RESOURCE_WOOD:
        return
    _update_upgrade_button_state()

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

    # Ensure layout is up to date before computing size.
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

func _update_upgrade_button_state() -> void:
    if upgrade_button == null:
        return
    var population_core := _population_core()
    if population_core == null:
        upgrade_button.disabled = true
        return
    var can_up: bool = bool(population_core.call("can_upgrade"))
    upgrade_button.disabled = not can_up
    if tooltip_panel and tooltip_panel.visible and tooltip_panel.has_method("update_info"):
        tooltip_panel.update_info()

func _process(delta: float) -> void:
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

    if _pending_hide:
        if _tooltip_hovered or _tooltip_panel_hovered:
            _pending_hide = false
            _hide_timer = 0.0
        else:
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

