extends SceneTree

const CharacterCreationSpellCatalogScript := preload("res://scripts/ui/spells/CharacterCreationSpellCatalog.gd")
const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var spell_def := CharacterCreationSpellCatalogScript.get_spell_def("pocket_demons")
	if spell_def.is_empty():
		push_error("[test_king_spell_familiar_metadata] missing pocket_demons spell def")
		quit(1)
		return

	if String(spell_def.get("display_name", "")) != "Demonology":
		push_error("[test_king_spell_familiar_metadata] pocket_demons display name must be Demonology")
		quit(1)
		return

	if CharacterCreationSpellCatalogScript.get_spell_cost("pocket_demons", 0) != 100:
		push_error("[test_king_spell_familiar_metadata] Demonology base cost must be 100")
		quit(1)
		return

	if int(round(CharacterCreationSpellCatalogScript.get_spell_effective_cooldown("pocket_demons", 0))) != 150:
		push_error("[test_king_spell_familiar_metadata] Demonology cooldown must be 150 sec")
		quit(1)
		return

	var cfg := PathRegistryScript.load_unit_config("familiar")
	if cfg == null:
		push_error("[test_king_spell_familiar_metadata] familiar unit config must exist")
		quit(1)
		return

	if int(cfg.hp) != 120:
		push_error("[test_king_spell_familiar_metadata] familiar HP must be 120")
		quit(1)
		return

	if int(cfg.dps) != 20:
		push_error("[test_king_spell_familiar_metadata] familiar DPS must be 20")
		quit(1)
		return

	if float(cfg.attack_range) > 40.0:
		push_error("[test_king_spell_familiar_metadata] familiar must be melee-range")
		quit(1)
		return

	print("[test_king_spell_familiar_metadata] PASS")
	quit(0)
