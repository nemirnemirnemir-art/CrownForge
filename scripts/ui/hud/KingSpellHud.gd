extends Control

const SpellHudAssetsScript := preload("res://scripts/ui/spells/SpellHudAssets.gd")

const ACTIVE_SLOT_COUNT := 4
const PASSIVE_SLOT_COUNT := 9
const ACTIVE_SLOT_SIZE := Vector2(72.0, 72.0)
const PASSIVE_SLOT_SIZE := Vector2(96.0, 64.0)
const ACTIVE_ICON_SCALE := 1.5
const PASSIVE_ICON_SCALE := 1.0
const UPGRADE_TOOLTIP_TEXT := "Improves all king abilities (up to four times)."
const UPGRADE_BUTTON_TEXT_MAX := "MAX"

@onready var active_slots_container: HBoxContainer = $Panel/Margin/VBox/ActiveSection/ActiveSlots
@onready var passive_slots_container: GridContainer = $Panel/Margin/VBox/PassiveSection/PassiveSlots
@onready var active_section_label: Label = $Panel/Margin/VBox/ActiveSection/Label
@onready var passive_section_label: Label = $Panel/Margin/VBox/PassiveSection/Label
@onready var upgrade_button: TextureButton = $UpgradeAbilityButton
@onready var upgrade_button_label: Label = $UpgradeAbilityButton/Label
@onready var upgrade_tooltip: PanelContainer = $UpgradeTooltip
@onready var upgrade_tooltip_title: Label = $UpgradeTooltip/Margin/VBox/Title
@onready var upgrade_tooltip_summary: Label = $UpgradeTooltip/Margin/VBox/Summary
@onready var upgrade_tooltip_level: Label = $UpgradeTooltip/Margin/VBox/Level
@onready var upgrade_tooltip_cost: Label = $UpgradeTooltip/Margin/VBox/Cost
@onready var upgrade_tooltip_cost_rows: VBoxContainer = $UpgradeTooltip/Margin/VBox/CostRows
@onready var ability_tooltip: PanelContainer = $AbilityTooltip
@onready var ability_tooltip_title: Label = $AbilityTooltip/Margin/VBox/Title
@onready var ability_tooltip_type: Label = $AbilityTooltip/Margin/VBox/Type
@onready var ability_tooltip_description_body: RichTextLabel = $AbilityTooltip/Margin/VBox/DescriptionBody
@onready var ability_tooltip_effect_header: Label = $AbilityTooltip/Margin/VBox/EffectHeader
@onready var ability_tooltip_effect_body: Label = $AbilityTooltip/Margin/VBox/EffectBody
@onready var ability_tooltip_status_header: Label = $AbilityTooltip/Margin/VBox/StatusHeader
@onready var ability_tooltip_status_body: RichTextLabel = $AbilityTooltip/Margin/VBox/StatusBody

var _active_slots: Array[Control] = []
var _passive_slots: Array[Control] = []
var _hovered_slot_index: int = -1
var _hovered_passive_shape: bool = false

var _slots_helper: KingSpellHudSlots
var _upgrades_helper: KingSpellHudUpgrades
var _tooltips_helper: KingSpellHudTooltips
var _casting_helper: KingSpellHudCasting

func _ready() -> void:
    _slots_helper = KingSpellHudSlots.new()
    _upgrades_helper = KingSpellHudUpgrades.new()
    _tooltips_helper = KingSpellHudTooltips.new()
    _casting_helper = KingSpellHudCasting.new()

    SpellHudAssetsScript.ensure_placeholders()
    _slots_helper.build_slots(active_slots_container, _active_slots, ACTIVE_SLOT_COUNT, ACTIVE_SLOT_SIZE, ACTIVE_ICON_SCALE, SpellHudAssetsScript.get_active_placeholder(), false, self)
    _slots_helper.build_slots(passive_slots_container, _passive_slots, PASSIVE_SLOT_COUNT, PASSIVE_SLOT_SIZE, PASSIVE_ICON_SCALE, SpellHudAssetsScript.get_passive_placeholder(), true, self)
    if active_section_label:
        active_section_label.text = "King Active Abilities"
    if passive_section_label:
        passive_section_label.text = "King Passive Abilities"
    _slots_helper.refresh_selected_spells(_active_slots, _passive_slots)
    _update_runtime_state()
    _upgrades_helper.sync_upgrade_button_size(self)
    if upgrade_button and not upgrade_button.pressed.is_connected(_on_upgrade_button_pressed):
        upgrade_button.tooltip_text = ""
        upgrade_button.pressed.connect(_on_upgrade_button_pressed)
        upgrade_button.mouse_entered.connect(_on_upgrade_button_mouse_entered)
        upgrade_button.mouse_exited.connect(_on_upgrade_button_mouse_exited)
    if upgrade_tooltip:
        upgrade_tooltip.custom_minimum_size = Vector2(480.0, 0.0)
        upgrade_tooltip.visible = false
        upgrade_tooltip.top_level = true
    if ability_tooltip:
        ability_tooltip.custom_minimum_size = Vector2(570.0, 0.0)
        ability_tooltip.visible = false
        ability_tooltip.top_level = true
    if ability_tooltip_description_body:
        ability_tooltip_description_body.scroll_active = false
        ability_tooltip_description_body.fit_content = true
        ability_tooltip_description_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        ability_tooltip_description_body.add_theme_color_override("default_color", Color(0.88, 0.88, 0.93, 1))
        ability_tooltip_description_body.add_theme_font_size_override("normal_font_size", 18)
    if ability_tooltip_status_body:
        ability_tooltip_status_body.scroll_active = false
        ability_tooltip_status_body.fit_content = true
        ability_tooltip_status_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        ability_tooltip_status_body.add_theme_color_override("default_color", Color(0.88, 0.88, 0.93, 1))
        ability_tooltip_status_body.add_theme_font_size_override("normal_font_size", 18)

func _process(delta: float) -> void:
    if KingSpellState:
        KingSpellState.tick_cooldowns(delta)
    _update_runtime_state()

func _update_runtime_state() -> void:
    _slots_helper.update_runtime_state(_active_slots, _passive_slots)
    _upgrades_helper.update_upgrade_button_state(self)
    _tooltips_helper.refresh_hover_tooltip(self)


func refresh_selected_spell_slots() -> void:
    if _slots_helper == null:
        return
    _slots_helper.refresh_selected_spells(_active_slots, _passive_slots)
    _update_runtime_state()

func _on_upgrade_button_pressed() -> void:
    if _upgrades_helper.try_purchase_upgrade():
        _update_runtime_state()

func _on_upgrade_button_mouse_entered() -> void:
    if upgrade_tooltip:
        _upgrades_helper.update_upgrade_tooltip_text(self)
        _upgrades_helper.position_upgrade_tooltip(self)
        upgrade_tooltip.visible = true

func _on_upgrade_button_mouse_exited() -> void:
    if upgrade_tooltip:
        upgrade_tooltip.visible = false

func _on_slot_pressed(slot_index: int, passive_shape: bool) -> void:
    var slots := _passive_slots if passive_shape else _active_slots
    if slot_index < 0 or slot_index >= slots.size():
        return
    var slot := slots[slot_index]
    if slot == null or not slot.has_method("get_spell_config"):
        return
    var config = slot.call("get_spell_config")
    if config == null:
        return
    if passive_shape:
        var spell_id = String(config.get("spell_id") if config.get("spell_id") else "")
        _casting_helper.try_activate_passive(self, spell_id)
    else:
        _casting_helper.try_cast_active(self, config)
    _update_runtime_state()

func _on_slot_hover_started(slot_index: int, passive_shape: bool) -> void:
    _hovered_slot_index = slot_index
    _hovered_passive_shape = passive_shape
    _tooltips_helper.refresh_hover_tooltip(self)

func _on_slot_hover_ended(_slot_index: int, _passive_shape: bool) -> void:
    _hovered_slot_index = -1
    if ability_tooltip:
        ability_tooltip.visible = false

func _get_slot(slot_index: int, passive_shape: bool) -> Control:
    var slots := _passive_slots if passive_shape else _active_slots
    if slot_index < 0 or slot_index >= slots.size():
        return null
    return slots[slot_index]

func _get_game_scene() -> Node:
    var tree := get_tree()
    if tree == null:
        return null
    if tree.current_scene and tree.current_scene.is_in_group("game_scene"):
        return tree.current_scene
    var scenes := tree.get_nodes_in_group("game_scene")
    if scenes.is_empty():
        return null
    return scenes[0]
