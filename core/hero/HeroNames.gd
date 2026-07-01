extends RefCounted
class_name HeroNames

## Hero Name Generator
## Manages lists of names and generation logic with roman numerals for duplicates.

# Female names for Slinger and Archer
const FEMALE_NAMES: Array[String] = [
	"Aria", "Luna", "Evelyn", "Scarlett", "Nova", "Isla", "Freya", "Willow", "Aurora", "Mira",
	"Elara", "Lyra", "Hazel", "Ruby", "Ivy", "Stella", "Naomi", "Clara", "Maeve", "Zoe",
	"Raven", "Celeste", "Serena", "Talia", "Iris", "Ada", "Elena", "Quinn", "Phoebe", "Dahlia",
	"Nyx", "Kaela", "Selene", "Rowan", "Lilith", "Ember", "Amara", "Jade", "Morrigan", "Keira",
	"Siena", "Elowen", "Brynn", "Talindra", "Velora", "Maris", "Yara", "Cassia", "Nerissa", "Skye"
]

# Male names for other classes
const MALE_NAMES: Array[String] = [
	"Aiden", "Liam", "Ethan", "Noah", "Caleb", "Logan", "Mason", "Wyatt", "Hunter", "Griffin",
	"Jaxon", "Finn", "Rowan", "Asher", "Leo", "Dylan", "Miles", "Owen", "Connor", "Zane",
	"Ryder", "Blake", "Cole", "Jude", "Nolan", "Kieran", "Silas", "Felix", "Gavin", "Ezra",
	"Draven", "Theron", "Darius", "Kael", "Lucian", "Garrett", "Ronan", "Cassian", "Talon", "Orion",
	"Jarek", "Corvin", "Brennan", "Tyrion", "Alaric", "Damien", "Galen", "Ryker", "Soren", "Vale"
]

# Roman numerals for suffixes up to 3999, though we likely only need a few.
const ROMAN_NUMERALS: Array[String] = [
	"", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
	"XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"
]

# Tracks usage count of each name base
# Format: { "Name": count }
var _used_names_counter: Dictionary = {}

func _init() -> void:
	_used_names_counter.clear()

## Generates a name based on hero class (icon_id)
## If name exists, appends roman numeral (e.g., "Aria II")
func generate_name(hero_class: String) -> String:
	var is_female = _is_female_class(hero_class)
	var name_list = FEMALE_NAMES if is_female else MALE_NAMES
	
	# Pick a random name base
	var base_name = name_list.pick_random()
	
	# Increment usage count
	if not _used_names_counter.has(base_name):
		_used_names_counter[base_name] = 1
		return base_name
	else:
		_used_names_counter[base_name] += 1
		var count = _used_names_counter[base_name]
		var suffix = _get_roman_suffix(count)
		return "%s %s" % [base_name, suffix]

## Registers an existing name (e.g. from loaded save) to ensure correct counting
func register_existing_name(full_name: String) -> void:
	# Split name and suffix
	var parts = full_name.split(" ")
	var base_name = parts[0]
	
	# Simple check if base name is in our lists (optional validation)
	# If it's a custom name, we track it anyway to avoid duplicates if it happens to match
	
	var count = 1
	if parts.size() > 1:
		# Try to parse roman numeral
		var suffix = parts[parts.size() - 1]
		var numeral_val = _parse_roman(suffix)
		if numeral_val > 0:
			count = numeral_val
			# Reconstruct base name without suffix
			if parts.size() > 2:
				base_name = ""
				for i in range(parts.size() - 1):
					base_name += parts[i] + (" " if i < parts.size() - 2 else "")
	
	if not _used_names_counter.has(base_name) or _used_names_counter[base_name] < count:
		_used_names_counter[base_name] = count

func _is_female_class(hero_class: String) -> bool:
	var lower_class = hero_class.to_lower()
	return lower_class.contains("slinger") or lower_class.contains("archer")

func _get_roman_suffix(number: int) -> String:
	if number <= 0: return ""
	if number < ROMAN_NUMERALS.size():
		return ROMAN_NUMERALS[number - 1] # Index 0 is "", 1 is "I" which is what we want for 2nd instance?
		# Wait, usually: Name (1st), Name II (2nd).
		# So count=1 -> "", count=2 -> "II"
	
	# Fallback for large numbers (simple)
	return str(number)

func _parse_roman(roman: String) -> int:
	var idx = ROMAN_NUMERALS.find(roman)
	if idx > 0:
		return idx + 1 # ROMAN_NUMERALS[1] is "I" which usually means 1, but in suffix logic "Name II" is 2nd.
	return 0

## Reset state (e.g. for new game)
func reset() -> void:
	_used_names_counter.clear()
