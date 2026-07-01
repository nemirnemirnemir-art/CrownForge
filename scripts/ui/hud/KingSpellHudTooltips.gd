extends RefCounted
class_name KingSpellHudTooltips

const CharacterCreationSpellCatalogScript := preload("res://scripts/ui/spells/CharacterCreationSpellCatalog.gd")
const UnitFaceLibraryScript := preload("res://scripts/utils/UnitFaceLibrary.gd")

const INLINE_ICON_SIZE := 20

func refresh_hover_tooltip(hud: Control) -> void:
    if hud.ability_tooltip == null:
        return
    if hud._hovered_slot_index < 0:
        hud.ability_tooltip.visible = false
        return
    var slot: Control = hud._get_slot(hud._hovered_slot_index, hud._hovered_passive_shape)
    if slot == null or not slot.has_method("get_spell_config"):
        hud.ability_tooltip.visible = false
        return
    var config = slot.call("get_spell_config")
    if config == null:
        hud.ability_tooltip.visible = false
        return
    if hud.ability_tooltip_title:
        hud.ability_tooltip_title.text = String(config.spell_name)
    if hud.ability_tooltip_type:
        hud.ability_tooltip_type.text = _get_ability_type_text(hud._hovered_passive_shape)
    if hud.ability_tooltip_description_body:
        _render_description_body(hud.ability_tooltip_description_body, String(config.spell_id), String(config.description))
    if hud.ability_tooltip_effect_header:
        hud.ability_tooltip_effect_header.visible = true
    if hud.ability_tooltip_effect_body:
        hud.ability_tooltip_effect_body.text = _get_ability_effect_text(String(config.spell_id), hud._hovered_passive_shape)
        hud.ability_tooltip_effect_body.visible = hud.ability_tooltip_effect_body.text != ""
    if hud.ability_tooltip_status_header:
        hud.ability_tooltip_status_header.visible = true
    if hud.ability_tooltip_status_body:
        hud.ability_tooltip_status_body.visible = _render_status_body(hud.ability_tooltip_status_body, String(config.spell_id), hud._hovered_passive_shape)
    position_ability_tooltip(hud, slot)
    hud.ability_tooltip.visible = true

func _render_description_body(body: RichTextLabel, spell_id: String, fallback_text: String) -> void:
    if body == null:
        return
    body.clear()
    var segments := CharacterCreationSpellCatalogScript.get_spell_description_segments(spell_id)
    if segments.is_empty():
        body.add_text(fallback_text)
        return
    for segment_variant in segments:
        var segment := segment_variant as Dictionary
        if segment.has("unit_face_id"):
            var unit_face_id := String(segment.get("unit_face_id", ""))
            var unit_face := UnitFaceLibraryScript.get_face_texture(unit_face_id, unit_face_id.capitalize())
            if unit_face != null:
                body.add_image(unit_face, INLINE_ICON_SIZE, INLINE_ICON_SIZE)
        if segment.has("icon_path"):
            var icon_path := String(segment.get("icon_path", ""))
            if icon_path != "" and ResourceLoader.exists(icon_path):
                var texture := load(icon_path) as Texture2D
                if texture != null:
                    body.add_image(texture, INLINE_ICON_SIZE, INLINE_ICON_SIZE)
        if segment.has("text"):
            body.add_text(String(segment.get("text", "")))

func _render_status_body(body: RichTextLabel, ability_id: String, passive_shape: bool) -> bool:
    if body == null:
        return false
    body.clear()
    if passive_shape:
        var passive_text := _get_ability_status_text(ability_id, true)
        if passive_text == "":
            return false
        body.add_text(passive_text)
        return true

    var eng := Engine.get_main_loop() as SceneTree
    var king_state = eng.root.get_node_or_null("/root/KingSpellState") if eng else null
    if king_state == null or ability_id == "":
        return false

    var has_content := false
    var cooldown_total := int(round(CharacterCreationSpellCatalogScript.get_spell_effective_cooldown(ability_id, int(king_state.active_upgrade_level))))
    if cooldown_total > 0:
        body.add_text("⌛ %d sec" % cooldown_total)
        has_content = true

    var cost_status: Dictionary = king_state.get_active_ability_resource_status(ability_id)
    if not cost_status.is_empty():
        if has_content:
            body.add_text("\n")
        var resource_id := String(cost_status.get("resource_id", "")).strip_edges().to_lower()
        var icon_path := CharacterCreationSpellCatalogScript.get_resource_icon_path(resource_id)
        if icon_path != "" and ResourceLoader.exists(icon_path):
            var resource_texture := load(icon_path) as Texture2D
            if resource_texture != null:
                body.add_image(resource_texture, INLINE_ICON_SIZE, INLINE_ICON_SIZE)
        else:
            body.add_text(resource_id.replace("_", " ").capitalize())
        body.add_text(" %d/%d" % [
            int(cost_status.get("owned", 0)),
            int(cost_status.get("required", 0))
        ])
        has_content = true

    var active_reason: String = king_state.get_active_ability_unavailability_reason(ability_id)
    if active_reason != "":
        if has_content:
            body.add_text("\n")
        body.add_text(active_reason)
        return true

    if has_content:
        body.add_text("\n")
    if king_state.get_active_cooldown(ability_id) > 0.0:
        body.add_text("On cooldown.")
    else:
        body.add_text("Ready to cast.")
    return true

func _get_ability_type_text(passive_shape: bool) -> String:
    return "Passive Ability" if passive_shape else "Active Ability"

func _get_ability_effect_text(ability_id: String, passive_shape: bool) -> String:
    if ability_id == "":
        return ""
    if passive_shape:
        match ability_id:
            "lumberjack":
                return "One-time reward: gain 300 wood after meeting the tree-cutting requirement."
            "reward":
                return "One-time reward: open an Established Production building blueprint reward."
            "good_reward":
                return "One-time reward: open a Legendary Artifact reward."
            "last_chance":
                return "One-time effect: summon 10 Militia when the castle is in critical condition."
            "spells_for_work":
                return "One-time reward: open a spell reward with 3 choices."
            "spicy_boys":
                return "One-time effect: summon 10 Bumblebees once morale is high enough."
        return "One-time passive ability."
        
    var eng := Engine.get_main_loop() as SceneTree
    var king_state = eng.root.get_node_or_null("/root/KingSpellState") if eng else null
    var level := 0
    if king_state:
        level = int(king_state.active_upgrade_level)
        
    match ability_id:
        "tough_guys":
            return "Summons %d Peasants right now. Upgrade scaling: +1 Peasant per upgrade." % [3 + level]
        "resurrection":
            return "Resurrects up to %d dead bodies in an area. Upgrade scaling: +1 resurrected body per upgrade." % [2 + level]
        "pocket_demons":
            return "Summons 1 Familiar. Current scaling: +%d%% base stats from upgrades." % [25 * level]
        "fast_production":
            return "Applies +%d%% building production for 25 seconds." % [int(round((0.32 + 0.08 * float(level)) * 100.0))]
        "forced_tax":
            return "Opens a reward for 100 resources of your choice. Current cooldown reduction from upgrades: %d sec." % [10 * level]
        "frenzy":
            return "Applies Wrath to all allied units for 6 seconds."
        "boys_at_work":
            return "Makes all buildings work for 15 seconds regardless of current gaze position."
        "training":
            return "Adds %d HP to each allied unit currently on the battlefield." % [100 + 25 * level]
    return ""

func _get_ability_status_text(ability_id: String, passive_shape: bool) -> String:
    var eng := Engine.get_main_loop() as SceneTree
    var king_state = eng.root.get_node_or_null("/root/KingSpellState") if eng else null

    if king_state == null or ability_id == "":
        return ""
    if passive_shape:
        if king_state.is_passive_used(ability_id):
            return "Already used this run."
        var passive_reason: String = king_state.get_passive_ability_unavailability_reason(ability_id)
        if passive_reason != "":
            return passive_reason
        return "Ready to activate."

    var lines: Array[String] = []
    var cooldown_total := int(round(CharacterCreationSpellCatalogScript.get_spell_effective_cooldown(ability_id, int(king_state.active_upgrade_level))))
    if cooldown_total > 0:
        lines.append("⌛ %d sec" % cooldown_total)

    var cost_status: Dictionary = king_state.get_active_ability_resource_status(ability_id)
    if not cost_status.is_empty():
        var resource_id := String(cost_status.get("resource_id", "")).replace("_", " ")
        lines.append("%d/%d %s" % [
            int(cost_status.get("owned", 0)),
            int(cost_status.get("required", 0)),
            resource_id
        ])

    var active_reason: String = king_state.get_active_ability_unavailability_reason(ability_id)
    if active_reason != "":
        lines.append(active_reason)
        return "\n".join(lines)

    if king_state.get_active_cooldown(ability_id) > 0.0:
        lines.append("On cooldown.")
    else:
        lines.append("Ready to cast.")
    return "\n".join(lines)

func position_ability_tooltip(hud: Control, slot: Control) -> void:
    if hud.ability_tooltip == null or slot == null:
        return
    hud.ability_tooltip.reset_size()
    var size_hint: Vector2 = hud.ability_tooltip.get_combined_minimum_size()
    if size_hint == Vector2.ZERO:
        size_hint = hud.ability_tooltip.size
    var pos := Vector2(
        slot.global_position.x + slot.size.x * 0.5 - size_hint.x * 0.5,
        slot.global_position.y - size_hint.y - 8.0
    )
    var screen := hud.get_viewport_rect().size
    pos.x = clamp(pos.x, 5.0, max(5.0, screen.x - size_hint.x - 5.0))
    pos.y = clamp(pos.y, 5.0, max(5.0, screen.y - size_hint.y - 5.0))
    hud.ability_tooltip.global_position = pos
