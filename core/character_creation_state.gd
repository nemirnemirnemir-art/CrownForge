extends Node

var selected_class_id: String = ""
var selected_active_spell_id: String = ""
var selected_passive_spell_id: String = ""
var selected_age: int = 16
var selected_name: String = ""

func apply_selection(class_id: String, active_spell_id: String, passive_spell_id: String, age: int, player_name: String) -> void:
	selected_class_id = class_id
	selected_active_spell_id = active_spell_id
	selected_passive_spell_id = passive_spell_id
	selected_age = age
	selected_name = player_name

func clear() -> void:
	selected_class_id = ""
	selected_active_spell_id = ""
	selected_passive_spell_id = ""
	selected_age = 16
	selected_name = ""
