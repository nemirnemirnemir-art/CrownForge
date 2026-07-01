extends RefCounted
class_name MainUITooltipFacadeBridge

func show_hero_hp_tooltip(tooltips, hero: Node) -> void:
	if tooltips != null and tooltips.has_method("show_hero_hp_tooltip"):
		tooltips.show_hero_hp_tooltip(hero)

func hide_hero_hp_tooltip(tooltips, hero: Node) -> void:
	if tooltips != null and tooltips.has_method("hide_hero_hp_tooltip"):
		tooltips.hide_hero_hp_tooltip(hero)

func show_enemy_hp_tooltip(tooltips, mob: Node) -> void:
	if tooltips != null and tooltips.has_method("show_enemy_hp_tooltip"):
		tooltips.show_enemy_hp_tooltip(mob)

func hide_enemy_hp_tooltip(tooltips, mob: Node) -> void:
	if tooltips != null and tooltips.has_method("hide_enemy_hp_tooltip"):
		tooltips.hide_enemy_hp_tooltip(mob)
