extends RefCounted
class_name LootGenerator

const DROP_CHANCE: float = 1.0
const RARE_DROP_CHANCE: float = 0.35

func try_drop_from_enemy(inventory_core: Node, mob_type: String, position: Vector2) -> void:
	try_drop_equipment(inventory_core)
	try_drop_ingredient(inventory_core, mob_type, position)

func try_drop_equipment(inventory_core: Node) -> void:
	if not _has_empty_slot(inventory_core):
		return
	
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var roll := rng.randf()
	
	var rarity := -1
	if roll < 0.01: rarity = ItemSystem.Rarity.COMMON
	elif roll < 0.06: rarity = ItemSystem.Rarity.UGLY
		
	if rarity != -1:
		var item = _generate_random_equipment(rarity)
		if not item.is_empty():
			inventory_core.add_item(item)

func _has_empty_slot(inventory_core: Node) -> bool:
	var items = inventory_core.items
	for i in range(items.size()):
		if items[i].is_empty():
			return true
	return false

func try_drop_ingredient(inventory_core: Node, mob_type: String, position: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	var chance := 0.1
	if mob_type == "Goblin": chance = 1.0
	
	if rng.randf() > chance: return
	
	var ingredient_id := ""
	var icon_path := ""
	
	match mob_type:
		"Goblin":
			ingredient_id = "ingredient_lizard_tail"
			icon_path = "res://assets/items/ingredients/lizard_tail.png"
		_: return
		
	var item = ItemSystem.create_item(
		ingredient_id,
		ItemSystem.ItemType.INGREDIENT,
		ItemSystem.Rarity.COMMON,
		icon_path
	)
	
	DropSpawner.new().spawn_drop(item, position, inventory_core.get_tree())
	print("[LootGenerator] Ingredient dropped: %s from %s" % [ingredient_id, mob_type])

func _generate_random_equipment(rarity: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var type = [
		ItemSystem.ItemType.HELMET,
		ItemSystem.ItemType.ARMOR,
		ItemSystem.ItemType.WEAPON,
		ItemSystem.ItemType.RING
	].pick_random()
	var template := ItemCatalog.get_random_template(type)
	if template.is_empty(): return {}
	var base_hp := 0
	var base_damage := 0
	if type == ItemSystem.ItemType.HELMET or type == ItemSystem.ItemType.ARMOR:
		base_hp = rng.randi_range(template.base_hp_min, template.base_hp_max)
	elif type == ItemSystem.ItemType.WEAPON or type == ItemSystem.ItemType.RING:
		base_damage = rng.randi_range(template.base_damage_min, template.base_damage_max)
	var multiplier := ItemSystem.get_rarity_multiplier(rarity)
	var hp_bonus := 0
	var damage_bonus := 0
	if base_hp > 0:     hp_bonus = int(base_hp * multiplier)
	if base_damage > 0: damage_bonus = int(base_damage * multiplier)
	var id := "item_%d_%d" % [Time.get_ticks_msec(), rng.randi()]
	var icon_path: String = template.get("icon_path", "res://icon.svg")
	return ItemSystem.create_item(id, type, rarity, icon_path, hp_bonus, damage_bonus)
