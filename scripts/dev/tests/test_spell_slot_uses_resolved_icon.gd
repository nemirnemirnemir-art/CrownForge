extends SceneTree

const SpellSlotScene := preload("res://scenes/ui/spells/SpellSlot.tscn")


func _init() -> void:
	var slot := SpellSlotScene.instantiate() as Control
	if slot == null:
		push_error("[test_spell_slot_uses_resolved_icon] failed to instantiate SpellSlot")
		quit(1)
		return

	get_root().add_child(slot)
	call_deferred("_run_test", slot)


func _run_test(slot: Control) -> void:
	var cfg := SpellConfig.new()
	cfg.spell_id = "summon_infernals"
	cfg.spell_name = "Summon Infernals"
	cfg.icon = null

	if not slot.has_method("add_spell"):
		push_error("[test_spell_slot_uses_resolved_icon] SpellSlot missing add_spell()")
		quit(1)
		return

	if not bool(slot.call("add_spell", cfg)):
		push_error("[test_spell_slot_uses_resolved_icon] add_spell() returned false")
		quit(1)
		return

	await process_frame

	var icon_rect := slot.get_node_or_null("Panel/IconRect") as TextureRect
	if icon_rect == null:
		push_error("[test_spell_slot_uses_resolved_icon] IconRect node not found")
		quit(1)
		return

	if icon_rect.texture == null:
		push_error("[test_spell_slot_uses_resolved_icon] slot icon is null for summon_infernals")
		quit(1)
		return

	if icon_rect.texture is GradientTexture2D:
		push_error("[test_spell_slot_uses_resolved_icon] slot icon resolved to gradient placeholder instead of spell image")
		quit(1)
		return

	if icon_rect.texture.get_width() <= 64 or icon_rect.texture.get_height() <= 64:
		push_error("[test_spell_slot_uses_resolved_icon] slot icon size looks like placeholder (%dx%d)" % [icon_rect.texture.get_width(), icon_rect.texture.get_height()])
		quit(1)
		return

	print("[test_spell_slot_uses_resolved_icon] PASS")
	quit(0)
