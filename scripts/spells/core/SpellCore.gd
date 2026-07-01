extends Node

## Singleton for managing spells, inventory, and global spell logic
## Autoload name: SpellCore

# Spell inventory: { "spell_id": count }
var spell_inventory: Dictionary = {}

# Signal when spell is cast
signal spell_cast_initiated(spell_id: String)
signal spell_inventory_changed()

func add_spell(spell_id: String, amount: int = 1) -> void:
	if spell_id in spell_inventory:
		spell_inventory[spell_id] += amount
	else:
		spell_inventory[spell_id] = amount
	
	emit_signal("spell_inventory_changed")
	print("[SpellCore] Added %d of %s. Total: %d" % [amount, spell_id, spell_inventory[spell_id]])

func remove_spell(spell_id: String, amount: int = 1) -> bool:
	if not spell_inventory.has(spell_id) or spell_inventory[spell_id] < amount:
		return false
	
	spell_inventory[spell_id] -= amount
	if spell_inventory[spell_id] <= 0:
		spell_inventory.erase(spell_id)
	
	emit_signal("spell_inventory_changed")
	return true

func get_spell_count(spell_id: String) -> int:
	return spell_inventory.get(spell_id, 0)
