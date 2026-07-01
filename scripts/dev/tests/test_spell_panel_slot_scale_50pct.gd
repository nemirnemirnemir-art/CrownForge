extends SceneTree

const SpellPanelScene := preload("res://scenes/ui/spells/SpellPanel.tscn")
const EXPECTED_SLOT_SIZE: float = 76.5


func _init() -> void:
    var panel := SpellPanelScene.instantiate() as Control
    if panel == null:
        push_error("[test_spell_panel_slot_scale_50pct] failed to instantiate SpellPanel")
        quit(1)
        return

    get_root().add_child(panel)
    call_deferred("_run_test", panel)


func _run_test(panel: Control) -> void:
    await process_frame

    var slot := panel.get_node_or_null("GridContainer/SpellSlot1") as Control
    if slot == null:
        push_error("[test_spell_panel_slot_scale_50pct] SpellSlot1 not found")
        quit(1)
        return

    var actual := slot.custom_minimum_size.x
    if absf(actual - EXPECTED_SLOT_SIZE) > 0.1:
        push_error("[test_spell_panel_slot_scale_50pct] expected slot size %.1f, got %.1f" % [EXPECTED_SLOT_SIZE, actual])
        quit(1)
        return

    print("[test_spell_panel_slot_scale_50pct] PASS")
    quit(0)
