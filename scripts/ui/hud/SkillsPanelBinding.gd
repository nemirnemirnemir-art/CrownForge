class_name SkillsPanelBinding

## Reads SkillCore / TownCore state and produces per-slot UI state dictionaries
## that SkillsPanel can apply directly to its nodes.

const ACTIVE_COLOR   := Color(0.4, 1.0, 0.4, 1.0)
const READY_COLOR    := Color(1, 1, 1, 1)
const LOCKED_COLOR   := Color(0.25, 0.25, 0.25, 1)
const COOLDOWN_COLOR := Color(0.65, 0.65, 0.65, 1)

var _skill_core
var _town_core

func _init(skill_core, town_core) -> void:
	_skill_core = skill_core
	_town_core  = town_core

## Returns one state dict per slot index (size == slot_count).
## Slots that should be skipped (null buttons) are still included but marked disabled.
func build_states(slot_count: int) -> Array:
	var states := []
	for i in range(slot_count):
		states.append(_build_slot_state(i))
	return states

func _build_slot_state(skill_index: int) -> Dictionary:
	var state := {
		"disabled":     false,
		"modulate":     READY_COLOR,
		"tooltip":      "",
		"timer_text":   "",
		"cd_visible":   false,
		"cd_remaining": 0.0,
		"cd_total":     0.0,
	}

	var purchased := false
	if _town_core and _town_core.has_method("is_mage_tower_skill_purchased"):
		purchased = _town_core.is_mage_tower_skill_purchased(skill_index)

	if not purchased:
		state["disabled"] = true
		state["modulate"]  = LOCKED_COLOR
		state["tooltip"]   = "Buy in Mage Tower"
		return state

	var tooltip := _build_tooltip(skill_index)

	var active := false
	if _skill_core and _skill_core.has_method("is_skill_active"):
		active = bool(_skill_core.is_skill_active(skill_index))

	var active_remaining := 0.0
	if active and _skill_core and _skill_core.has_method("get_skill_active_remaining"):
		active_remaining = float(_skill_core.get_skill_active_remaining(skill_index))

	var cd_remaining := 0
	if _skill_core and _skill_core.has_method("get_skill_cooldown_remaining"):
		cd_remaining = int(_skill_core.get_skill_cooldown_remaining(skill_index))

	if cd_remaining > 0:
		var cd_total := 0
		if _skill_core and _skill_core.has_method("get_skill_cooldown_total"):
			cd_total = int(_skill_core.get_skill_cooldown_total(skill_index))
		state["disabled"]   = true
		state["modulate"]   = COOLDOWN_COLOR
		state["timer_text"] = _format_time(cd_remaining)
		state["tooltip"]    = tooltip + "\nStatus: Cooldown (%s)" % _format_time(cd_remaining)
		if cd_total > 0:
			state["cd_visible"]   = true
			state["cd_remaining"] = float(cd_remaining)
			state["cd_total"]     = float(cd_total)
		return state

	if active:
		var dur := 0.0
		if _skill_core and _skill_core.has_method("get_skill_duration_seconds"):
			dur = float(_skill_core.get_skill_duration_seconds(skill_index))
		state["disabled"]   = true
		state["modulate"]   = ACTIVE_COLOR
		state["timer_text"] = "%d" % int(ceil(active_remaining))
		state["tooltip"]    = tooltip + "\nStatus: Active (%ds)" % int(ceil(active_remaining))
		if dur > 0.0:
			state["cd_visible"]   = true
			state["cd_remaining"] = active_remaining
			state["cd_total"]     = dur
		return state

	state["disabled"] = false
	state["tooltip"]  = tooltip
	return state

func _build_tooltip(skill_index: int) -> String:
	var data     := _get_skill_ui_data(skill_index)
	var duration := 0.0
	if _skill_core and _skill_core.has_method("get_skill_duration_seconds"):
		duration = float(_skill_core.get_skill_duration_seconds(skill_index))
	var cd_total := 0
	if _skill_core and _skill_core.has_method("get_skill_cooldown_total"):
		cd_total = int(_skill_core.get_skill_cooldown_total(skill_index))

	var cd_text := "None"
	if cd_total > 0:
		cd_text = _format_time(cd_total)

	return "%s\nEffect: %s\nDuration: %.0fs\nCooldown: %s" % [
		str(data.get("name", "Skill")),
		str(data.get("desc", "")),
		duration,
		cd_text,
	]

func _get_skill_ui_data(skill_index: int) -> Dictionary:
	match skill_index:
		1:  return {"name": "Auto Clicker",    "desc": "Auto-clicks enemies"}
		2:  return {"name": "Double Damage",   "desc": "+25% all damage"}
		3:  return {"name": "Crit Roulette",   "desc": "+25% crit chance (clicks)"}
		4:  return {"name": "Gold Digger",     "desc": "Each click drops 10% mob gold"}
		5:  return {"name": "Heavy Pockets",   "desc": "+100% gold from mobs"}
		6:  return {"name": "Heal Supply",     "desc": "Heals heroes 10% max HP/sec"}
		7:  return {"name": "",                "desc": ""}
		8:  return {"name": "Mega Clicks",     "desc": "+200% click damage"}
		9:  return {"name": "Double Effect",   "desc": "Next skill effect x2"}
		10: return {"name": "Reload",          "desc": "Refresh last used skill"}
		_:  return {"name": "Skill",           "desc": ""}

func _format_time(seconds: int) -> String:
	if seconds < 0:
		seconds = 0
	var h := int(float(seconds) / 3600.0)
	var m := int(float(seconds) / 60.0) % 60
	var s := int(seconds) % 60
	if h > 0:
		return "%02d:%02d:%02d" % [h, m, s]
	return "%02d:%02d" % [m, s]
