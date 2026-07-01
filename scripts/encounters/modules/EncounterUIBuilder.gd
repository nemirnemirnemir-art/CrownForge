extends RefCounted
class_name EncounterUIBuilder

const EncounterResourcesScript := preload("res://scripts/encounters/modules/EncounterResources.gd")
const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const RewardPresentationRegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")
const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")
const UnitFaceLibraryScript := preload("res://scripts/utils/UnitFaceLibrary.gd")

const _ACTION_TO_REWARD_TYPE := {
	"open_reward_menu_base_production": ProphecyPatternScript.RewardType.BASIC_PRODUCTION,
	"open_reward_menu_established_production": ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION,
	"open_reward_menu_advanced_production": ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION,
	"open_reward_menu_levy_barracks": ProphecyPatternScript.RewardType.LEVY_BARRACKS,
	"open_reward_menu_veteran_barracks": ProphecyPatternScript.RewardType.VETERAN_BARRACKS,
	"open_reward_menu_elite_barracks": ProphecyPatternScript.RewardType.ELITE_BARRACKS,
	"open_reward_menu_kingdom_infrastructure": ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE,
	"open_reward_menu_artifacts": ProphecyPatternScript.RewardType.ARTIFACT,
	"open_reward_menu_spells": ProphecyPatternScript.RewardType.SPELL,
	"open_reward_menu_legendary_spells": ProphecyPatternScript.RewardType.LEGENDARY_SPELL,
	"open_reward_menu_building_upgrades": ProphecyPatternScript.RewardType.BUILDING_UPGRADE,
	"open_reward_menu_troop_bonuses": ProphecyPatternScript.RewardType.TROOP_TRAINING,
}

func decorate_options_for_ui(options_var: Variant, resource_core: Node) -> Array:
	if not (options_var is Array):
		return []

	var result: Array = []
	for raw_option in options_var:
		if not (raw_option is Dictionary):
			continue
		var option: Dictionary = (raw_option as Dictionary).duplicate(true)
		var effects_rows: Array = build_effect_rows(option)
		var requirements_rows: Array = build_requirements_rows(option, resource_core)
		var enabled := _is_option_available(option, resource_core)

		option["enabled"] = enabled
		option["_is_available"] = enabled
		if not enabled:
			option["_unavailable_reason"] = join_requirement_texts(requirements_rows)
		option["effects_rows"] = effects_rows
		option["requirements_rows"] = requirements_rows
		option["effects_text"] = join_row_texts(effects_rows)
		option["requirements_text"] = join_requirement_texts(requirements_rows)
		result.append(option)
	return result

func _is_option_available(option: Dictionary, resource_core: Node) -> bool:
	return _has_required_resources(_build_required_resource_map(option), resource_core)

func _has_required_resources(resources: Dictionary, resource_core: Node) -> bool:
	if resources.is_empty():
		return true
	if resource_core == null:
		return false

	for raw_id in resources.keys():
		var resource_id := EncounterResourcesScript.normalize_resource_id(String(raw_id))
		var amount := int(resources.get(raw_id, 0))
		if int(resource_core.call("get_resource", resource_id)) < amount:
			return false
	return true

func _build_required_resource_map(option: Dictionary) -> Dictionary:
	var required: Dictionary = {}

	var req_var: Variant = option.get("requirements", {})
	if req_var is Dictionary:
		var resources_var: Variant = (req_var as Dictionary).get("resources", {})
		if resources_var is Dictionary:
			for raw_id in (resources_var as Dictionary).keys():
				var resource_id := EncounterResourcesScript.normalize_resource_id(String(raw_id))
				required[resource_id] = int(required.get(resource_id, 0)) + int((resources_var as Dictionary).get(raw_id, 0))

	var effects_var: Variant = option.get("effects", [])
	if effects_var is Array:
		for raw_effect in effects_var:
			if not (raw_effect is Dictionary):
				continue
			var effect: Dictionary = raw_effect
			var kind := String(effect.get("kind", ""))
			if kind != "resource_consume" and kind != "resource_lose":
				continue
			var resource_id := EncounterResourcesScript.normalize_resource_id(String(effect.get("resource_id", "")))
			var amount := int(effect.get("amount", 0))
			if resource_id == "" or amount <= 0:
				continue
			required[resource_id] = int(required.get(resource_id, 0)) + amount

	return required

func build_effect_rows(option: Dictionary) -> Array:
	var effects_var: Variant = option.get("effects", [])
	if not (effects_var is Array):
		return []

	var rows: Array = []
	for raw_effect in effects_var:
		if not (raw_effect is Dictionary):
			continue
		var effect: Dictionary = raw_effect
		var kind := String(effect.get("kind", ""))

		if kind == "resource_add":
			_add_resource_add_row(rows, effect)
		elif kind == "denarii_add":
			_add_denarii_add_row(rows, effect)
		elif kind == "all_resources_add":
			_add_all_resources_row(rows, effect)
		elif kind == "resource_consume":
			_add_resource_consume_row(rows, effect)
		elif kind == "resource_lose":
			_add_resource_consume_row(rows, effect)
		elif kind == "spell_add":
			_add_spell_add_row(rows, effect)
		elif kind == "ui_action":
			_add_ui_action_row(rows, effect)
		elif kind == "troops_add":
			_add_troops_add_row(rows, effect)
		elif kind == "building_add":
			_add_building_add_row(rows, effect)
		elif kind == "morale_add":
			_add_morale_add_row(rows, effect)
		elif kind == "spawn_enemy":
			_add_spawn_enemy_row(rows, effect)
		elif kind == "lose_troops":
			_add_lose_troops_row(rows, effect)
		elif kind == "max_hp_add":
			_add_max_hp_row(rows, effect)
		elif kind == "transmute":
			_add_transmute_row(rows, effect)
		elif kind == "gaze_upgrade":
			_add_gaze_upgrade_row(rows, effect)

	return rows

func _add_resource_add_row(rows: Array, effect: Dictionary) -> void:
	var resource_id := EncounterResourcesScript.normalize_resource_id(String(effect.get("resource_id", "")))
	var amount := int(effect.get("amount", 0))
	if amount > 0 and resource_id != "":
		rows.append({
			"icon_path": _resource_icon_path(resource_id),
			"text": "+%d %s" % [amount, EncounterResourcesScript.display_name(resource_id)],
			"tone": "positive",
		})

func _add_denarii_add_row(rows: Array, effect: Dictionary) -> void:
	var amount := int(effect.get("amount", 0))
	if amount > 0:
		rows.append({
			"icon_texture": RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.DENARII),
			"text": "+%d Denarii" % amount,
			"tone": "positive",
		})

func _add_all_resources_row(rows: Array, effect: Dictionary) -> void:
	var amount := int(effect.get("amount", 0))
	if amount > 0:
		rows.append({
			"icon_texture": RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.RESOURCE),
			"text": "+%d Each Resource" % amount,
			"tone": "positive",
		})

func _add_resource_consume_row(rows: Array, effect: Dictionary) -> void:
	var resource_id := EncounterResourcesScript.normalize_resource_id(String(effect.get("resource_id", "")))
	var amount := int(effect.get("amount", 0))
	if amount > 0 and resource_id != "":
		rows.append({
			"icon_path": _resource_icon_path(resource_id),
			"text": "-%d %s" % [amount, EncounterResourcesScript.display_name(resource_id)],
			"tone": "negative",
		})

func _add_spell_add_row(rows: Array, effect: Dictionary) -> void:
	var spell_id := String(effect.get("spell_id", ""))
	var amount := int(effect.get("amount", 0))
	if spell_id != "" and amount > 0:
		var row := {
			"text": "Spell: %s x%d" % [EncounterResourcesScript.display_name(spell_id), amount],
			"tone": "positive",
		}
		var icon := _resolve_spell_icon(spell_id)
		if icon != null:
			row["icon_texture"] = icon
		rows.append(row)

func _add_ui_action_row(rows: Array, effect: Dictionary) -> void:
	var action_id := String(effect.get("action_id", ""))
	var reward_type := int(_ACTION_TO_REWARD_TYPE.get(action_id, -1))
	if reward_type == -1:
		return

	var count := maxi(1, int(effect.get("count", 1)))
	var chance_percent := clampi(int(effect.get("chance_percent", 100)), 1, 100)
	var reward_name := RewardPresentationRegistryScript.get_reward_display_name(reward_type)
	var text := reward_name
	if count > 1:
		text += " x%d" % count
	if chance_percent < 100:
		text += " (%d%%)" % chance_percent

	rows.append({
		"icon_texture": RewardPresentationRegistryScript.get_reward_icon(reward_type),
		"text": text,
		"tone": "positive",
	})

	if chance_percent < 100:
		rows.append({
			"text": "Nothing (%d%%)" % (100 - chance_percent),
			"tone": "negative",
		})

func _add_troops_add_row(rows: Array, effect: Dictionary) -> void:
	var troop_id := String(effect.get("troop_id", ""))
	var amount := int(effect.get("amount", 0))
	var cfg := PathRegistryScript.load_unit_config(troop_id) as UnitConfig
	var display_name := EncounterResourcesScript.display_name(troop_id)
	if cfg != null and cfg.display_name != "":
		display_name = cfg.display_name
	var row := {
		"text": "+%d %s" % [amount, display_name],
		"tone": "positive",
	}
	var face := UnitFaceLibraryScript.get_face_texture(troop_id, display_name)
	if face != null:
		row["icon_texture"] = face
	else:
		row["icon_path"] = "res://assets/ui/class_ui/barrack.png"
	rows.append({
		"icon_texture": row.get("icon_texture", null),
		"icon_path": row.get("icon_path", ""),
		"text": row.get("text", ""),
		"tone": row.get("tone", "positive"),
	})

func _add_building_add_row(rows: Array, effect: Dictionary) -> void:
	rows.append({
		"icon_path": "res://assets/ui/population_ui_icon.png",
		"text": "Building: %s x%d" % [EncounterResourcesScript.display_name(String(effect.get("building_id", ""))), effect.get("amount", 0)],
		"tone": "positive",
	})

func _add_morale_add_row(rows: Array, effect: Dictionary) -> void:
	var amount := int(effect.get("amount", 0))
	rows.append({
		"icon_path": "res://assets/ui/morale/m80-100.png",
		"text": "%s%d Morale" % ["+" if amount > 0 else "", amount],
		"tone": "positive" if amount > 0 else "negative",
	})

func _add_spawn_enemy_row(rows: Array, effect: Dictionary) -> void:
	rows.append({
		"icon_path": "res://assets/ui/class_ui/main_screen_under_enemy_face.png",
		"text": "Spawn %d %s" % [effect.get("amount", 0), EncounterResourcesScript.display_name(String(effect.get("enemy_id", "")))],
		"tone": "negative",
	})

func _add_lose_troops_row(rows: Array, effect: Dictionary) -> void:
	rows.append({
		"icon_path": "res://assets/ui/class_ui/barrack.png",
		"text": "-%d Random Troops" % effect.get("amount", 0),
		"tone": "negative",
	})

func _add_max_hp_row(rows: Array, effect: Dictionary) -> void:
	var amount := int(effect.get("amount", 0))
	rows.append({
		"icon_path": "res://assets/ui/status_icons/heart.png",
		"text": "%s%d Castle Max HP" % ["+" if amount > 0 else "", amount],
		"tone": "positive" if amount > 0 else "negative",
	})

func _add_transmute_row(rows: Array, effect: Dictionary) -> void:
	rows.append({
		"icon_texture": RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.SPELL),
		"text": "Transmute all resources to %s" % EncounterResourcesScript.display_name(String(effect.get("target_resource", ""))),
		"tone": "neutral",
	})

func _add_gaze_upgrade_row(rows: Array, _effect: Dictionary) -> void:
	rows.append({
		"icon_texture": RewardPresentationRegistryScript.get_reward_icon(ProphecyPatternScript.RewardType.SPELL),
		"text": "Upgrade Gaze",
		"tone": "positive",
	})

func build_requirements_rows(option: Dictionary, resource_core: Node) -> Array:
	var resource_map := _build_required_resource_map(option)
	if resource_map.is_empty():
		return []

	var rows: Array = []
	var raw_keys: Array[String] = []
	for raw_key in resource_map.keys():
		raw_keys.append(String(raw_key))
	raw_keys.sort()

	for raw_key in raw_keys:
		var amount := int(resource_map.get(raw_key, 0))
		if amount <= 0:
			continue
		var resource_id := EncounterResourcesScript.normalize_resource_id(raw_key)
		var owned := 0
		if resource_core != null:
			owned = int(resource_core.call("get_resource", resource_id))
		rows.append({
			"icon_path": _resource_icon_path(resource_id),
			"text": "%d %s" % [amount, EncounterResourcesScript.display_name(resource_id)],
			"met": owned >= amount,
			"required": amount,
			"owned": owned,
			"tone": "neutral" if owned >= amount else "negative",
		})

	return rows

func join_row_texts(rows: Array) -> String:
	if rows.is_empty():
		return ""
	var parts: Array[String] = []
	for raw_row in rows:
		if not (raw_row is Dictionary):
			continue
		var text := String((raw_row as Dictionary).get("text", "")).strip_edges()
		if text != "":
			parts.append(text)
	return ", ".join(parts)

func join_requirement_texts(rows: Array) -> String:
	if rows.is_empty():
		return ""
	var parts: Array[String] = []
	for raw_row in rows:
		if not (raw_row is Dictionary):
			continue
		var text := String((raw_row as Dictionary).get("text", "")).strip_edges()
		if text != "":
			parts.append(text)
	if parts.is_empty():
		return ""
	return "Need: %s" % ", ".join(parts)

func _resource_icon_path(resource_id: String) -> String:
	var normalized_id := EncounterResourcesScript.normalize_resource_id(resource_id)
	return PathRegistryScript.resolve_resource_icon_path(normalized_id, EncounterResourcesScript.RESOURCE_ICON_FILE_MAP)

func _resolve_spell_icon(spell_id: String) -> Texture2D:
	if spell_id == "":
		return null

	var spell_config: Variant = PathRegistryScript.load_spell_config(spell_id)
	if spell_config == null:
		return null
	if not spell_config.has_method("get_icon_or_placeholder"):
		return null

	var icon: Variant = spell_config.call("get_icon_or_placeholder")
	if icon is Texture2D:
		return icon
	return null
