extends SceneTree

const KingSpellHudScene := preload("res://scenes/ui/hud/KingSpellHud.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var hud := KingSpellHudScene.instantiate() as Control
	if hud == null:
		push_error("[test_king_spell_upgrade_button_uses_texture_size] failed to instantiate KingSpellHud")
		quit(1)
		return

	get_root().add_child(hud)
	await process_frame

	var button := hud.get_node_or_null("UpgradeAbilityButton") as TextureButton
	if button == null:
		push_error("[test_king_spell_upgrade_button_uses_texture_size] UpgradeAbilityButton missing")
		quit(1)
		return

	if button.texture_normal == null:
		push_error("[test_king_spell_upgrade_button_uses_texture_size] UpgradeAbilityButton texture missing")
		quit(1)
		return

	var texture_size := button.texture_normal.get_size()
	if button.ignore_texture_size:
		push_error("[test_king_spell_upgrade_button_uses_texture_size] UpgradeAbilityButton must use the original texture size")
		quit(1)
		return

	if button.custom_minimum_size.distance_to(texture_size) > 0.01:
		push_error("[test_king_spell_upgrade_button_uses_texture_size] expected custom minimum size %s, got %s" % [texture_size, button.custom_minimum_size])
		quit(1)
		return

	print("[test_king_spell_upgrade_button_uses_texture_size] PASS")
	quit(0)
