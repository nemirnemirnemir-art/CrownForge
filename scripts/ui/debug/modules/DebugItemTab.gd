extends RefCounted
class_name DebugItemTab

const PathRegistryScript = preload("res://scripts/systems/PathRegistry.gd")
const ProphecyPatternScript = preload("res://scripts/resources/ProphecyPattern.gd")
const RewardPresentationRegistryScript = preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")

func build_ui(parent: Control, spell_configs: Array[String], add_spell_callback: Callable, open_base_production_callback: Callable, open_levy_barracks_callback: Callable, open_artifact_rewards_callback: Callable, open_artifact_debug_callback: Callable, open_troop_bonus_callback: Callable, open_building_upgrade_callback: Callable, open_resource_callback: Callable, open_spells_callback: Callable, open_legendary_spells_callback: Callable, add_troop_bonus_callback: Callable, add_all_resources_callback: Callable, add_denarii_callback: Callable, add_morale_callback: Callable, reset_morale_callback: Callable, get_unit_class_name_func: Callable) -> void:
    var spell_label := Label.new()
    spell_label.text = "SPELLS (%d)" % spell_configs.size()
    spell_label.add_theme_font_size_override("font_size", 14)
    parent.add_child(spell_label)
    build_spells_ui(parent, spell_configs, add_spell_callback)

    parent.add_child(HSeparator.new())

    var buildings_label := Label.new()
    buildings_label.text = "BUILDINGS"
    buildings_label.add_theme_font_size_override("font_size", 14)
    parent.add_child(buildings_label)
    build_buildings_ui(parent, open_base_production_callback, open_levy_barracks_callback, open_artifact_rewards_callback, open_artifact_debug_callback, open_troop_bonus_callback, open_building_upgrade_callback, open_resource_callback, open_spells_callback, open_legendary_spells_callback)

    parent.add_child(HSeparator.new())

    var troop_bonus_label := Label.new()
    troop_bonus_label.text = "TROOP BONUSES"
    troop_bonus_label.add_theme_font_size_override("font_size", 14)
    parent.add_child(troop_bonus_label)
    build_troop_bonuses_ui(parent, add_troop_bonus_callback, add_all_resources_callback, add_denarii_callback, add_morale_callback, reset_morale_callback, get_unit_class_name_func)

func build_spells_ui(parent: Control, spell_configs: Array[String], add_spell_callback: Callable) -> void:
    var spell_container := VBoxContainer.new()
    parent.add_child(spell_container)

    for spell_id in spell_configs:
        var hbox := HBoxContainer.new()
        hbox.custom_minimum_size = Vector2(0, 32)

        var config := PathRegistryScript.load_spell_config(spell_id) as SpellConfig

        var icon_texture_rect := TextureRect.new()
        icon_texture_rect.custom_minimum_size = Vector2(24, 24)
        icon_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
        icon_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

        if config and config.has_method("get_icon_or_placeholder"):
            icon_texture_rect.texture = config.get_icon_or_placeholder()
        elif config and config.icon != null:
            icon_texture_rect.texture = config.icon
        else:
            icon_texture_rect.texture = _create_placeholder_texture()

        hbox.add_child(icon_texture_rect)

        var btn := Button.new()
        if config and config.spell_name != "":
            btn.text = config.spell_name
        else:
            btn.text = spell_id.capitalize().replace("_", " ")
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn.pressed.connect(add_spell_callback.bind(spell_id))
        hbox.add_child(btn)

        spell_container.add_child(hbox)

func build_buildings_ui(parent: Control, open_base_production_callback: Callable, open_levy_barracks_callback: Callable, open_artifact_rewards_callback: Callable, open_artifact_debug_callback: Callable, open_troop_bonus_callback: Callable, open_building_upgrade_callback: Callable, open_resource_callback: Callable, open_spells_callback: Callable, open_legendary_spells_callback: Callable) -> void:
    _add_icon_button_row(
        parent,
        RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.BASIC_PRODUCTION),
        "Base Production Reward Menu",
        open_base_production_callback
    )
    _add_icon_button_row(
        parent,
        RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.LEVY_BARRACKS),
        "Levy Barracks Reward Menu",
        open_levy_barracks_callback
    )
    _add_icon_button_row(
        parent,
        RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.ARTIFACT),
        "Artifacts Reward Menu",
        open_artifact_rewards_callback
    )
    _add_icon_button_row(
        parent,
        RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.ARTIFACT),
        "Artifacts Debug Grid",
        open_artifact_debug_callback
    )
    _add_icon_button_row(
        parent,
        RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.TROOP_TRAINING),
        "Troop Bonuses Reward Menu",
        open_troop_bonus_callback
    )
    _add_icon_button_row(
        parent,
        RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.BUILDING_UPGRADE),
        "Building Upgrades Reward Menu",
        open_building_upgrade_callback
    )
    _add_icon_button_row(
        parent,
        RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.RESOURCE),
        "Resource Reward Menu",
        open_resource_callback
    )
    _add_icon_button_row(
        parent,
        RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.SPELL),
        "Spells Reward Menu",
        open_spells_callback
    )
    _add_icon_button_row(
        parent,
        RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.LEGENDARY_SPELL),
        "Legendary Spells Reward Menu",
        open_legendary_spells_callback
    )

func build_troop_bonuses_ui(parent: Control, add_troop_bonus_callback: Callable, add_all_resources_callback: Callable, add_denarii_callback: Callable, add_morale_callback: Callable, reset_morale_callback: Callable, get_unit_class_name_func: Callable) -> void:
    for class_id in range(8):
        var hbox := HBoxContainer.new()
        hbox.custom_minimum_size = Vector2(0, 32)

        var hp_btn := Button.new()
        hp_btn.text = "+15%% HP %s" % get_unit_class_name_func.call(class_id)
        hp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hp_btn.pressed.connect(add_troop_bonus_callback.bind(class_id, 0))
        hbox.add_child(hp_btn)

        var dmg_btn := Button.new()
        dmg_btn.text = "+15%% DMG %s" % get_unit_class_name_func.call(class_id)
        dmg_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        dmg_btn.pressed.connect(add_troop_bonus_callback.bind(class_id, 1))
        hbox.add_child(dmg_btn)

        parent.add_child(hbox)

    var add_res_btn := Button.new()
    add_res_btn.text = "Add resources (+1000)"
    add_res_btn.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
    add_res_btn.pressed.connect(add_all_resources_callback)
    parent.add_child(add_res_btn)

    var add_denarii_btn := Button.new()
    add_denarii_btn.text = "Denarii +100"
    add_denarii_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
    add_denarii_btn.pressed.connect(add_denarii_callback)
    parent.add_child(add_denarii_btn)

    var add_morale_btn := Button.new()
    add_morale_btn.text = "Add morale (+20)"
    add_morale_btn.add_theme_color_override("font_color", Color(1.0, 0.6, 0.8))
    add_morale_btn.pressed.connect(add_morale_callback)
    parent.add_child(add_morale_btn)

    var reset_morale_btn := Button.new()
    reset_morale_btn.text = "Reset morale"
    reset_morale_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
    reset_morale_btn.pressed.connect(reset_morale_callback)
    parent.add_child(reset_morale_btn)

func _add_icon_button_row(parent: Control, icon: Texture2D, button_text: String, callback: Callable) -> void:
    # Skip row if callback is null/invalid
    if callback.is_null():
        return
    
    var hbox := HBoxContainer.new()
    hbox.custom_minimum_size = Vector2(0, 32)

    var icon_rect := TextureRect.new()
    icon_rect.custom_minimum_size = Vector2(24, 24)
    icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon_rect.texture = icon if icon else _create_placeholder_texture()
    hbox.add_child(icon_rect)

    var btn := Button.new()
    btn.text = button_text
    btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn.pressed.connect(callback)
    hbox.add_child(btn)

    parent.add_child(hbox)

func _create_placeholder_texture() -> GradientTexture2D:
    var placeholder := GradientTexture2D.new()
    placeholder.width = 24
    placeholder.height = 24
    var gradient := Gradient.new()
    gradient.set_color(0, Color(0.3, 0.3, 0.4))
    gradient.set_color(1, Color(0.2, 0.2, 0.3))
    placeholder.gradient = gradient
    placeholder.fill = GradientTexture2D.FILL_RADIAL
    return placeholder
