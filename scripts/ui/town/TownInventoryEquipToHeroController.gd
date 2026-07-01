extends RefCounted
class_name TownInventoryEquipToHeroController

## Handles the hero equip popup launch and hero selection confirmation flow
## for the Town Inventory panel.

var _panel: Node = null

func initialize(panel: Node) -> void:
	_panel = panel

func try_equip_selected(selected_slot: InventorySlot, selected_context: String) -> void:
	if not selected_slot or selected_context != "player":
		return
	var item: Dictionary = selected_slot.item_data
	if item.is_empty():
		return

	var popup_path := "res://scenes/ui/HeroSelectionPopup.tscn"
	if ResourceLoader.exists(popup_path):
		var popup = load(popup_path).instantiate()
		_panel.add_child(popup)
		if popup.has_signal("hero_selected"):
			popup.hero_selected.connect(
				Callable(self, "_on_hero_selected").bind(selected_slot.slot_index)
			)
		popup.open()
	else:
		var heroes: Array = HeroCore.heroes.keys()
		if heroes.size() > 0:
			_do_equip(str(heroes[0]), selected_slot.slot_index)

func _on_hero_selected(hero_id: String, slot_index: int) -> void:
	_do_equip(hero_id, slot_index)

func _do_equip(hero_id: String, slot_index: int) -> void:
	var item: Dictionary = PlayerInventory.get_item_at_index(slot_index)
	if item.is_empty():
		return
	if HeroCore == null or HeroCore.query == null or not HeroCore.query.has_hero(hero_id):
		return
	var slot_name := _get_equip_slot_name(int(item.get("item_type", -1)))
	if slot_name == "":
		return
	HeroCore.equip_item_to_hero(hero_id, item, slot_name)
	PlayerInventory.remove_item_at_index(slot_index)
	if _panel and _panel.has_method("_select_slot"):
		_panel._select_slot(null, "")

func _get_equip_slot_name(item_type: int) -> String:
	match item_type:
		ItemSystem.ItemType.HELMET:
			return "helmet"
		ItemSystem.ItemType.ARMOR:
			return "armor"
		ItemSystem.ItemType.WEAPON:
			return "weapon"
		ItemSystem.ItemType.RING, ItemSystem.ItemType.ACCESSORY:
			return "ring"
		_:
			return ""
