extends SceneTree

const MainUIScene: PackedScene = preload("res://scenes/ui/hud/MainUI.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var ui := MainUIScene.instantiate()
	if ui == null:
		push_error("[test_mainui_spell_panel_layering] failed to instantiate MainUI")
		quit(1)
		return
	get_root().add_child(ui)

	var spell_panel := ui.get_node_or_null("SpellPanel") as Control
	if spell_panel == null:
		push_error("[test_mainui_spell_panel_layering] SpellPanel not found")
		quit(1)
		return
	if int(spell_panel.z_index) <= 100:
		push_error("[test_mainui_spell_panel_layering] SpellPanel must sit above HeroBar/WallHealthUI blocking layer")
		quit(1)
		return

	print("[test_mainui_spell_panel_layering] PASS")
	quit(0)
