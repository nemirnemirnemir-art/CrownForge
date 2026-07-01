extends RefCounted
class_name HeroCardDisplay

## Отображение данных героя
## Обновление лейблов (HP, damage, level, XP, name)

var _hero_card: Control
var _name_label: Label
var _hp_label: Label
var _damage_label: Label
var _level_label: Label
var _xp_label: Label

func initialize(hero_card: Control, name_label: Label, hp_label: Label, damage_label: Label, level_label: Label, xp_label: Label) -> void:
	_hero_card = hero_card
	_name_label = name_label
	_hp_label = hp_label
	_damage_label = damage_label
	_level_label = level_label
	_xp_label = xp_label

func update_display(selected_hero_id: String) -> void:
	if HeroCore == null:
		return
	
	if selected_hero_id == "" or not HeroCore.heroes.has(selected_hero_id):
		clear_display()
		return
	
	var hero: Dictionary = HeroCore.heroes[selected_hero_id]
	var total_stats: Dictionary = HeroCore.get_hero_total_stats(selected_hero_id)
	
	if _name_label != null:
		_name_label.text = hero.get("name", "Unknown")
	
	var current_hp: float = hero.get("hp", 0.0)
	var max_hp: float = total_stats.get("maxHp", hero.get("maxHp", 0.0))
	if _hp_label != null:
		_hp_label.text = "HP: %.1f / %.1f" % [current_hp, max_hp]
	
	if _damage_label != null:
		_damage_label.text = "Damage: %.1f" % total_stats.get("damage", hero.get("damage", 0.0))
	
	if _level_label != null:
		_level_label.text = "Level: %d" % hero.get("level", 1)
	
	if _xp_label != null:
		_xp_label.text = "XP: %d / %d" % [hero.get("xp", 0), hero.get("xpToNext", 10)]

func clear_display() -> void:
	if _name_label != null:
		_name_label.text = "No hero selected"
	if _hp_label != null:
		_hp_label.text = "HP: 0 / 0"
	if _damage_label != null:
		_damage_label.text = "Damage: 0"
	if _level_label != null:
		_level_label.text = "Level: 1"
	if _xp_label != null:
		_xp_label.text = "XP: 0 / 5"

