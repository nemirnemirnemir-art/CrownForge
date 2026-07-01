extends RefCounted
class_name KingSpellHudUpgrades

const CharacterCreationSpellCatalogScript := preload("res://scripts/ui/spells/CharacterCreationSpellCatalog.gd")

func update_upgrade_button_state(hud: Control) -> void:
    if hud.upgrade_button == null:
        return
        
    var eng := Engine.get_main_loop() as SceneTree
    var king_state = eng.root.get_node_or_null("/root/KingSpellState") if eng else null

    if king_state == null:
        hud.upgrade_button.disabled = true
        if hud.upgrade_button_label:
            hud.upgrade_button_label.text = "1/4"
        update_upgrade_tooltip_text(hud)
        return

    var can_upgrade: bool = king_state.can_upgrade_active_spells()
    hud.upgrade_button.disabled = not can_upgrade
    if hud.upgrade_button_label:
        if can_upgrade:
            hud.upgrade_button_label.text = "%d/4" % [int(king_state.active_upgrade_level + 1)]
        else:
            hud.upgrade_button_label.text = hud.UPGRADE_BUTTON_TEXT_MAX
    update_upgrade_tooltip_text(hud)

func sync_upgrade_button_size(hud: Control) -> void:
    if hud.upgrade_button == null or hud.upgrade_button.texture_normal == null:
        return
    var texture_size: Vector2 = hud.upgrade_button.texture_normal.get_size()
    hud.upgrade_button.ignore_texture_size = false
    hud.upgrade_button.custom_minimum_size = texture_size
    hud.upgrade_button.size = texture_size

func update_upgrade_tooltip_text(hud: Control) -> void:
    if hud.upgrade_tooltip_title == null or hud.upgrade_tooltip_summary == null or hud.upgrade_tooltip_level == null or hud.upgrade_tooltip_cost == null or hud.upgrade_tooltip_cost_rows == null:
        return
    hud.upgrade_tooltip_title.text = "Upgrade Active Abilities"
    hud.upgrade_tooltip_summary.text = hud.UPGRADE_TOOLTIP_TEXT
    for child in hud.upgrade_tooltip_cost_rows.get_children():
        child.queue_free()
    
    var eng := Engine.get_main_loop() as SceneTree
    var king_state = eng.root.get_node_or_null("/root/KingSpellState") if eng else null

    var current_level := 0
    var cost := {}
    var max_level := 4
    
    if king_state:
        current_level = int(king_state.active_upgrade_level)
        cost = king_state.get_next_upgrade_cost()
        max_level = int(king_state.MAX_ACTIVE_UPGRADE_LEVEL)
        
    hud.upgrade_tooltip_level.text = "Current Level: %d/%d" % [current_level, max_level]
    if cost.is_empty():
        hud.upgrade_tooltip_cost.text = "Next Cost: Max level reached."
        return
    hud.upgrade_tooltip_cost.text = "Next Cost:"
    var resource_ids: Array[String] = []
    for resource_id in cost.keys():
        resource_ids.append(String(resource_id))
    resource_ids.sort()
    for resource_id in resource_ids:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 6)
        row.mouse_filter = Control.MOUSE_FILTER_IGNORE

        var icon := TextureRect.new()
        icon.custom_minimum_size = Vector2(20, 20)
        icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var icon_path := CharacterCreationSpellCatalogScript.get_resource_icon_path(resource_id)
        if icon_path != "" and ResourceLoader.exists(icon_path):
            icon.texture = load(icon_path)
        row.add_child(icon)

        var label := Label.new()
        label.text = "%s %d" % [String(resource_id).capitalize().replace("_", " "), int(cost.get(resource_id, 0))]
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_child(label)
        hud.upgrade_tooltip_cost_rows.add_child(row)

func position_upgrade_tooltip(hud: Control) -> void:
    if hud.upgrade_button == null or hud.upgrade_tooltip == null:
        return
    hud.upgrade_tooltip.reset_size()
    var size_hint: Vector2 = hud.upgrade_tooltip.get_combined_minimum_size()
    if size_hint == Vector2.ZERO:
        size_hint = hud.upgrade_tooltip.size
    var pos := Vector2(
        hud.upgrade_button.global_position.x + hud.upgrade_button.size.x * 0.5 - size_hint.x * 0.5,
        hud.upgrade_button.global_position.y - size_hint.y - 8.0
    )
    var screen := hud.get_viewport_rect().size
    pos.x = clamp(pos.x, 5.0, max(5.0, screen.x - size_hint.x - 5.0))
    pos.y = clamp(pos.y, 5.0, max(5.0, screen.y - size_hint.y - 5.0))
    hud.upgrade_tooltip.global_position = pos

func try_purchase_upgrade() -> bool:
    var eng := Engine.get_main_loop() as SceneTree
    var king_state = eng.root.get_node_or_null("/root/KingSpellState") if eng else null
    if king_state and king_state.try_purchase_active_upgrade():
        return true
    return false
