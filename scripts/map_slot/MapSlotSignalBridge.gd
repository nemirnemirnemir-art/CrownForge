extends RefCounted
class_name MapSlotSignalBridge


func connect_hero_signals(hero_core: Node, on_hero_died_cb: Callable, on_hero_removed_cb: Callable) -> void:
	if hero_core == null:
		return
	if hero_core.has_signal("hero_died") and not hero_core.hero_died.is_connected(on_hero_died_cb):
		hero_core.hero_died.connect(on_hero_died_cb)
	if hero_core.has_signal("hero_removed") and not hero_core.hero_removed.is_connected(on_hero_removed_cb):
		hero_core.hero_removed.connect(on_hero_removed_cb)


func connect_upgrade_signals(upgrade_core: Node, on_upgrades_changed_cb: Callable) -> void:
	if upgrade_core == null:
		return
	if upgrade_core.has_signal("building_upgrades_changed") and not upgrade_core.building_upgrades_changed.is_connected(on_upgrades_changed_cb):
		upgrade_core.building_upgrades_changed.connect(on_upgrades_changed_cb)
