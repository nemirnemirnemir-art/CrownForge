## Pure data/utility script defining all 9 card types for the King of Nothing deck.
## Provides card definitions, stats per level (1-3), and deck-building helpers.
## No dependencies on other prototype scripts — this is a leaf node.
extends RefCounted


# ---------------------------------------------------------------------------
# Card ID constants
# ---------------------------------------------------------------------------
const CARD_CASTLE: StringName = &"castle"
const CARD_SOLDIER: StringName = &"soldier"
const CARD_PALADIN: StringName = &"paladin"
const CARD_ARCHER: StringName = &"archer"
const CARD_SCOUT_TOWER: StringName = &"scout_tower"
const CARD_FARM: StringName = &"farm"
const CARD_BLACKSMITH: StringName = &"blacksmith"
const CARD_WILDCARD: StringName = &"wildcard"
const CARD_STEEL_COAT: StringName = &"steel_coat"

const COPIES_PER_CARD: int = 3
const DECK_SIZE: int = 27  # 9 card types * 3 copies


# ---------------------------------------------------------------------------
# Card definitions — built once via static helper, then cached.
# ---------------------------------------------------------------------------
# GDScript does not allow complex expressions in `const`, so we build the
# dictionary on first access and cache it in a static variable.

static var _card_defs: Dictionary = {}


static func _ensure_defs() -> void:
	if not _card_defs.is_empty():
		return
	_card_defs = _build_card_defs()


static func _build_card_defs() -> Dictionary:
	var defs: Dictionary = {}

	# ---- Castle (Building) ------------------------------------------------
	defs[CARD_CASTLE] = {
		"id": CARD_CASTLE,
		"display_name": "Castle",
		"category": "building",
		"subcategory": "",
		"is_indestructible": true,
		"icon_path": "res://assets/dev/ten_kings/cards/castle.png",
		"stats": [
			{"dmg": 10.0},
			{"dmg": 12.5},
			{"dmg": 15.63},
		],
	}

	# ---- Soldier (Troop, Melee) -------------------------------------------
	defs[CARD_SOLDIER] = {
		"id": CARD_SOLDIER,
		"display_name": "Soldier",
		"category": "troop",
		"subcategory": "melee",
		"is_indestructible": false,
		"icon_path": "res://assets/dev/ten_kings/cards/soldier.png",
		"stats": [
			{"hp": 23.0,   "dmg": 3.0,  "hps": 0.5,  "cc": 0.05, "units": 9},
			{"hp": 28.75,  "dmg": 3.75, "hps": 0.63, "cc": 0.05, "units": 18},
			{"hp": 35.94,  "dmg": 4.69, "hps": 0.78, "cc": 0.05, "units": 27},
		],
	}

	# ---- Paladin (Troop, Melee) -------------------------------------------
	defs[CARD_PALADIN] = {
		"id": CARD_PALADIN,
		"display_name": "Paladin",
		"category": "troop",
		"subcategory": "melee",
		"is_indestructible": false,
		"icon_path": "res://assets/dev/ten_kings/units/paladin/run/1.png",
		"stats": [
			{"hp": 37.0,  "dmg": 8.0,  "hps": 0.25, "cc": 0.05, "units": 3},
			{"hp": 55.5,  "dmg": 12.0, "hps": 0.25, "cc": 0.05, "units": 6},
			{"hp": 83.25, "dmg": 18.0, "hps": 0.25, "cc": 0.05, "units": 9},
		],
	}

	# ---- Archer (Troop, Ranged) -------------------------------------------
	defs[CARD_ARCHER] = {
		"id": CARD_ARCHER,
		"display_name": "Archer",
		"category": "troop",
		"subcategory": "ranged",
		"is_indestructible": false,
		"icon_path": "res://assets/dev/ten_kings/cards/archer.png",
		"stats": [
			{"hp": 12.0,   "dmg": 2.3,  "hps": 0.58, "cc": 0.05, "units": 9},
			{"hp": 15.0,   "dmg": 2.88, "hps": 0.73, "cc": 0.06, "units": 18},
			{"hp": 18.75,  "dmg": 3.59, "hps": 0.91, "cc": 0.07, "units": 27},
		],
	}

	# ---- Scout Tower (Building) -------------------------------------------
	defs[CARD_SCOUT_TOWER] = {
		"id": CARD_SCOUT_TOWER,
		"display_name": "Scout Tower",
		"category": "building",
		"subcategory": "",
		"is_indestructible": true,
		"icon_path": "res://assets/dev/ten_kings/cards/scout_tower.png",
		"stats": [
			{"dmg": 25.0,  "hps": 0.5,  "cc": 0.20},
			{"dmg": 37.5,  "hps": 0.63, "cc": 0.20},
			{"dmg": 56.25, "hps": 0.78, "cc": 0.20},
		],
	}

	# ---- Farm (Building) --------------------------------------------------
	defs[CARD_FARM] = {
		"id": CARD_FARM,
		"display_name": "Farm",
		"category": "building",
		"subcategory": "",
		"is_indestructible": false,
		"icon_path": "res://assets/dev/ten_kings/cards/farm.png",
		"stats": [
			{"farm_bonus": 1},
			{"farm_bonus": 2},
			{"farm_bonus": 3},
		],
	}

	# ---- Blacksmith (Building) --------------------------------------------
	defs[CARD_BLACKSMITH] = {
		"id": CARD_BLACKSMITH,
		"display_name": "Blacksmith",
		"category": "building",
		"subcategory": "",
		"is_indestructible": false,
		"icon_path": "res://assets/dev/ten_kings/cards/blacksmith.png",
		"stats": [
			{"smith_bonus": 0.02},
			{"smith_bonus": 0.04},
			{"smith_bonus": 0.06},
		],
	}

	# ---- Wildcard / Tome --------------------------------------------------
	defs[CARD_WILDCARD] = {
		"id": CARD_WILDCARD,
		"display_name": "Wildcard",
		"category": "tome",
		"subcategory": "",
		"is_indestructible": false,
		"icon_path": "res://assets/dev/ten_kings/cards/wildcard.png",
		"stats": [
			{},
			{},
			{},
		],
	}

	# ---- Steel Coat (Enchantment) -----------------------------------------
	defs[CARD_STEEL_COAT] = {
		"id": CARD_STEEL_COAT,
		"display_name": "Steel Coat",
		"category": "enchantment",
		"subcategory": "",
		"is_indestructible": false,
		"icon_path": "res://assets/dev/ten_kings/cards/steel_coat.png",
		"stats": [
			{},
			{},
			{},
		],
	}

	return defs


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns the full card definition dictionary for the given card ID.
## Returns an empty dictionary if the card ID is unknown.
static func get_card_def(card_id: StringName) -> Dictionary:
	_ensure_defs()
	if _card_defs.has(card_id):
		return _card_defs[card_id]
	push_warning("TenKingsCardLibrary: unknown card_id '%s'" % str(card_id))
	return {}


## Returns an array of all 9 card StringName IDs.
static func get_all_card_ids() -> Array[StringName]:
	var ids: Array[StringName] = [
		CARD_CASTLE,
		CARD_SOLDIER,
		CARD_PALADIN,
		CARD_ARCHER,
		CARD_SCOUT_TOWER,
		CARD_FARM,
		CARD_BLACKSMITH,
		CARD_WILDCARD,
		CARD_STEEL_COAT,
	]
	return ids


## Returns the stats dictionary for a specific card at a given level (1-3).
## Returns an empty dictionary on invalid input.
static func get_stats_for_level(card_id: StringName, level: int) -> Dictionary:
	var card_def: Dictionary = get_card_def(card_id)
	if card_def.is_empty():
		return {}
	if level < 1 or level > 3:
		push_warning("TenKingsCardLibrary: level %d out of range [1-3] for '%s'" % [level, str(card_id)])
		return {}
	var stats_array: Array = card_def["stats"]
	return stats_array[level - 1]


## Builds and returns a shuffled deck of 27 cards (3 copies of each of the 9 types).
static func build_deck() -> Array[StringName]:
	var deck: Array[StringName] = []
	var all_ids: Array[StringName] = get_all_card_ids()
	for card_id: StringName in all_ids:
		for _i: int in range(COPIES_PER_CARD):
			deck.append(card_id)
	deck.shuffle()
	return deck


## Returns true if the card is a troop (melee or ranged).
static func is_troop(card_id: StringName) -> bool:
	var card_def: Dictionary = get_card_def(card_id)
	if card_def.is_empty():
		return false
	return card_def["category"] == "troop"


## Returns true if the card is a building.
static func is_building(card_id: StringName) -> bool:
	var card_def: Dictionary = get_card_def(card_id)
	if card_def.is_empty():
		return false
	return card_def["category"] == "building"


## Returns true if the card is a melee troop.
static func is_melee(card_id: StringName) -> bool:
	var card_def: Dictionary = get_card_def(card_id)
	if card_def.is_empty():
		return false
	return card_def["category"] == "troop" and card_def["subcategory"] == "melee"


## Returns true if the card is a ranged troop.
static func is_ranged(card_id: StringName) -> bool:
	var card_def: Dictionary = get_card_def(card_id)
	if card_def.is_empty():
		return false
	return card_def["category"] == "troop" and card_def["subcategory"] == "ranged"


## Returns true if this card spawns as a mobile unit in the battle arena.
static func spawns_in_arena(card_id: StringName) -> bool:
	return is_troop(card_id)  # Only troops spawn and move


## Returns true if this card is a stationary combat structure (attacks from fixed position).
static func is_stationary_combat(card_id: StringName) -> bool:
	return card_id == CARD_CASTLE or card_id == CARD_SCOUT_TOWER


## Returns true if this card is support-only (never participates in battle runtime).
static func is_support_only(card_id: StringName) -> bool:
	return card_id == CARD_FARM or card_id == CARD_BLACKSMITH or card_id == CARD_WILDCARD or card_id == CARD_STEEL_COAT
