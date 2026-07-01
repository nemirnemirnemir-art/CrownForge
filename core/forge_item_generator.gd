## Handles item generation and rarity rolling for ForgeCore.

const RANDOM_CRAFT_COST: int = 50

var _forge: Node
var _slots

func init(forge_core_ref: Node, slots_ref) -> void:
	_forge = forge_core_ref
	_slots = slots_ref

func create_crafted_item(item_type: ItemSystem.ItemType, rarity: ItemSystem.Rarity) -> Dictionary:
	var template = ItemCatalog.get_random_template(item_type)
	if template.is_empty():
		return {}

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var mult = ItemSystem.get_rarity_multiplier(rarity)
	var level = _forge._forge_level()
	var forge_bonus = 1.0 + (level * 0.05)

	var hp_bonus = 0
	var damage_bonus = 0

	if template.has("base_hp_min"):
		var hp_min = int(template.get("base_hp_min", 0) * forge_bonus * mult)
		var hp_max = int(template.get("base_hp_max", hp_min) * forge_bonus * mult)
		hp_bonus = rng.randi_range(hp_min, max(hp_min, hp_max))
	elif template.has("base_damage_min"):
		var dmg_min = int(template.get("base_damage_min", 0) * forge_bonus * mult)
		var dmg_max = int(template.get("base_damage_max", dmg_min) * forge_bonus * mult)
		damage_bonus = rng.randi_range(dmg_min, max(dmg_min, dmg_max))

	var id = "%s%d" % [_forge.CRAFT_ID_PREFIX, Time.get_ticks_msec()]
	var icon_path = template.get("icon_path", "res://icon.svg")
	return ItemSystem.create_item(id, item_type, rarity, icon_path, hp_bonus, damage_bonus)

## Calculate rarity chances based on forge level (1-100).
func calculate_rarity_chances(forge_level: int) -> Dictionary:
	var chances = {}

	# GOD: L0=20, P0=1%, P100=5%
	if forge_level >= 20:
		chances[ItemSystem.Rarity.GOD] = 1.0 + (5.0 - 1.0) * (forge_level - 20) / 80.0
	else:
		chances[ItemSystem.Rarity.GOD] = 0.0

	# COSMIC: L0=15, P0=1%, P100=10%
	if forge_level >= 15:
		chances[ItemSystem.Rarity.COSMIC] = 1.0 + (10.0 - 1.0) * (forge_level - 15) / 85.0
	else:
		chances[ItemSystem.Rarity.COSMIC] = 0.0

	# LEGENDARY: L0=10, P0=2%, P100=15%
	if forge_level >= 10:
		chances[ItemSystem.Rarity.LEGENDARY] = 2.0 + (15.0 - 2.0) * (forge_level - 10) / 90.0
	else:
		chances[ItemSystem.Rarity.LEGENDARY] = 0.0

	# EPIC: L0=5, P0=5%, P100=20%
	if forge_level >= 5:
		chances[ItemSystem.Rarity.EPIC] = 5.0 + (20.0 - 5.0) * (forge_level - 5) / 95.0
	else:
		chances[ItemSystem.Rarity.EPIC] = 0.0

	# NORMAL: L0=1, P0=5%, P100=25%
	chances[ItemSystem.Rarity.NORMAL] = 5.0 + (25.0 - 5.0) * (forge_level - 1) / 99.0

	# COMMON: L0=1, P0=15%, P100=25%
	chances[ItemSystem.Rarity.COMMON] = 15.0 + (25.0 - 15.0) * (forge_level - 1) / 99.0

	# UGLY: remainder
	var total = 0.0
	for rarity in chances.values():
		total += rarity
	chances[ItemSystem.Rarity.UGLY] = max(0.0, 100.0 - total)

	return chances

## Select random rarity based on weighted chances.
func select_random_rarity(chances: Dictionary) -> ItemSystem.Rarity:
	var rand = randf() * 100.0
	var cumulative = 0.0
	for rarity in [ItemSystem.Rarity.GOD, ItemSystem.Rarity.COSMIC, ItemSystem.Rarity.LEGENDARY,
					ItemSystem.Rarity.EPIC, ItemSystem.Rarity.NORMAL, ItemSystem.Rarity.COMMON,
					ItemSystem.Rarity.UGLY]:
		cumulative += chances.get(rarity, 0.0)
		if rand <= cumulative:
			return rarity
	return ItemSystem.Rarity.UGLY

## Start crafting with random rarity based on forge level.
func start_random_rarity_crafting(item_type: ItemSystem.ItemType) -> int:
	if not EconomyCore.can_afford_forge_cores(RANDOM_CRAFT_COST):
		print("[ForgeItemGenerator] Not enough forge cores (need %d)" % RANDOM_CRAFT_COST)
		return -1

	if _slots.find_free_slot() == -1:
		print("[ForgeItemGenerator] No free crafting slots.")
		return -1

	var forge_level = _forge._forge_level()
	var chances = calculate_rarity_chances(forge_level)
	var rarity = select_random_rarity(chances)
	print("[ForgeItemGenerator] Random craft: level=%d, rarity=%s" % [forge_level, ItemSystem.get_rarity_name(rarity)])

	if not EconomyCore.spend_forge_cores(RANDOM_CRAFT_COST):
		return -1

	return _slots.start_crafting_preapproved(item_type, rarity)

## Get rarity chances for current forge level (for UI display).
func get_rarity_chances() -> Dictionary:
	return calculate_rarity_chances(_forge._forge_level())
